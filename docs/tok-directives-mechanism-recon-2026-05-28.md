# tok directives mechanism — Tokf recon, 2026-05-28

*Tonto. Goal: build a durable model of how tok directives are actually handled in the tok source. Triggered by Tony's tip that directive rule(s) hide in the `.g` files. Findings, not fixes; tar babies surfaced.*

---

## Quick map: where does the work live

| Layer | File | What it does |
|---|---|---|
| Grammar | `parts.g:104-117` | `Directive`, `DebugDirective`, `CodeMatch` rules |
| Grammar | `parts.g:174-184` | `PoundCommand` routes `#` prefix to `Directive` |
| Grammar | `keywords.g:85-90` | `Directives` keyword set: `before / ending / starting / within` |
| Grammar | `Tawk.g:122-124` | `Directivise` — the rule that parses a directive's *code body* |
| Callback | `parts.act:275-317` | `DebugDirective!` — parses one directive, finds target method, builds the runtime object |
| Callback | `parts.act:319-325` | `Directive!` — pushes the parsed directive set into the active type's directive list |
| Callback | `Tawk.act:1-31` | `Block!` — fires `parseDirective()` for positional directives at block close |
| Callback | `Tawk.act:267-280` | Per-statement scan: fires `emitDirective()` when codeMatch text-matches |
| Runtime | `Directive.twk` | The Directive class — holds `type`, `method`, `codeMatch`, `codeToAdd`, four positional flags |
| Emit | `FormatC.twk:1533-1563` | The matcher loop — strncmp prefix-test against `pointInCode.itemStart` |
| Emit | `FormatC.twk:1330-1356` | End-of-block / RETURN firing for `atEnd` directives |
| Emit | `FormatC.twk:1609-1614` | `within` flag — fire inside next control-flow block |

---

## The Directive runtime object

From `Directive.twk`:

```
class Directive {
    SymbolType  type        // the target class (or globalType)
    Symbol      method      // the target method (resolved at parse time)
    String      codeMatch   // hook-site string for prefix-match (or empty for purely positional)
    String      codeToAdd   // the source text of the directive's code to splice
    PLGitem     line        // the parsed AST of codeToAdd, built lazily by parseDirective()
    boolean     atEnd       // fire at end of method body
    boolean     atStart     // fire at start of method body
    boolean     comesBefore // fire BEFORE the matched statement (default: AFTER)
    boolean     within      // fire inside the next control-flow block
    boolean     isDirected  // already-fired flag (prevents double-injection)
}
```

Two methods: `parseDirective()` divert-parses `codeToAdd` through the `Directivise` rule into `line`; `emitDirective()` writes those parsed statements out through the formatter.

---

## Lifecycle, end-to-end

### Phase 1 — directive file parse (`tok target.twk directivesFile`)

When tok parses the directive file, every `#methodName ... #;` block fires the `DebugDirective!` callback (`parts.act:275`). Steps:

1. **Activation gate** — `if active` at line 280. The literal token `active` after the directive body is what enables it. **Directives without the `active` keyword are silently dropped.** No diagnostic.
2. **Location sanity check** — if `body` is empty AND `locate` is neither `ending`/`starting`, error "missing location" (line 284). A directive needs either a codeMatch or a positional keyword.
3. **Method resolution** — `currentType.getMethod(text)` looks up the target method by name. If not found AND `currentType.isGlobal`, falls back to `findGlobalMethod(text)`.
4. **Drop-with-cerr on miss** — if method still not found, `cerr "Could not find directive method: X in type: Y"` and **silently drop the directive**. Parsing continues. The directive is gone; no `directives` entry created.
5. **Build the Directive object** — type, method, codeMatch (from body.toString()), codeToAdd (from code.toString()), and one of four positional flags from the `locate` keyword switch.
6. **Append** — `directives += directive` (a Stak or list on the parse state).

After Phase 1: `directives` is a collection of fully-resolved directive objects, each pointing at a specific method symbol in a specific class.

### Phase 2 — target file parse

At target-file parse time, the directives list is already populated from Phase 1. The target-file parse walks the source and at certain hook points checks for directives that should fire.

For directives that are *purely positional* (codeMatch empty, atEnd/atStart only) — `Block!` callback at end-of-block fires `parseDirective()` to build the `line` AST from `codeToAdd` (Tawk.act:20-27).

For directives with codeMatch — `parseDirective()` is deferred until the matcher actually finds a hit at emit time. (Looking at `Tawk.act:275-278`: when a per-statement scan matches codeMatch via strncmp, it calls `parseDirective()` then fires.)

### Phase 3 — code emit

This is where the directive actually lands in the output. `FormatC.twk:1533-1563` is the per-statement matching loop:

```
if !noLoop && enclosingMethod && directives
    if pointInCode {
        // pre-statement: fire startDirective if pending (atStart)
        // mid-loop: scan directives, find one whose codeMatch
        //   is a strncmp prefix of pointInCode.itemStart
        // if match found: emitDirective() to splice
        // comesBefore directives fire BEFORE the statement is written
        // others fire AFTER (the default)
    }
```

End-of-block path (`FormatC.twk:1330-1356`) fires `endDirective` (the directive tagged `atEnd`) just before the closing brace.

`within` path (`FormatC.twk:1609-1614`) — when an IF has a block body, a directive tagged `within` becomes a `pendingDirective` to fire when the inner block emits.

---

## The matching mechanism — and what it actually is

The match at `FormatC.twk:1552`:

```c
or isDirected || strncmp(codeMatch, pointInCode.itemStart, strlen(codeMatch)) != 0
    directive = null;
```

**`pointInCode.itemStart` is a `char *` into the original parsed source.** Each Statement / Line / forStatement / wile / ifStatement carries a `pointInCode = iTEM` set during parse (see Tawk.twk:2986, 3140, 3474, 4087, 4123, 4247, 4370, 4980, 5200, 5231, 5636, 6366). That `iTEM` is the PLGitem node holding the source text position.

So a directive's codeMatch matches via **literal text-prefix comparison against the original source**, at each statement boundary, during emit.

### Implication for the bible's "hook site = goto label" framing

Bible #13 calls hook sites "tok-recognizable goto labels." The actual mechanism is more general: codeMatch is just a literal string, and strncmp matches it as a prefix at each statement's source position. Goto labels work as hook sites because:

1. They're tokenized as statements (so they're statement boundaries — `pointInCode` lands on them).
2. They're typically unique text (so the strncmp prefix is unambiguous).
3. They have no runtime cost in C++ (the compiler discards unreferenced labels).

But the mechanism doesn't *recognize* labels specifically — it could match any unique-text statement, like `// HOOK_FOO`. The label convention is the cleanest way to plant an anchor, not a requirement of the machinery.

This isn't wrong in the bible — it's the *recommended* idiom. Worth knowing it's idiom, not engine.

---

## Insert-only — confirmed by code reading

The `emitDirective()` path (FormatC.twk:1334, 1348, 1542, 1559, 1710) writes additional statements via `formatter.write(statement)`. After emitDirective returns, control returns to the regular statement-write loop, and the ORIGINAL statement at pointInCode is written normally (FormatC.twk:1565+ continues into the statementType switch).

There is no replace path. There is no skip-original path. There is no delete path. The original source statement always emits; the directive's statements are added before or after.

**Where the limit lives.** The codeMatch-strncmp mechanism is a single-point match. To implement replace, you'd need a *span* — a start point AND an end point — and machinery to suppress the regular statement-write loop while the span is in effect. That's a structurally different matching loop, not an extension of this one.

This is the architectural fact behind the bible's new "tok directives are insert-only" entry: the matching mechanism is point-addressing all the way down.

---

## Tar babies surfaced (findings, not fixes)

1. **Silent drop on missing-method.** parts.act:313 — `cerr` and continue. A typo in the directive's method name doesn't fail the parse; it just disables the directive without surfacing it in a way a build script would catch. Cousin of bible #12 (positional second-arg silent staleness). Not necessarily worth fixing, but worth knowing for resurrection-reader awareness.

2. **`active` keyword is the on/off switch and it's REQUIRED.** Directives without `active` (parts.act:280) are silently parsed-and-dropped. That's why `groupDirectives` and `plgDirectives` have `active` markers on each block — without it, the block parses but nothing happens. Resurrection-reader gotcha.

3. **The two-form CodeMatch grammar.** `parts.g:97-102`:
   ```
   CodeMatch :  body = Quote
             |  Directives!  body = space{
             ;
   ```
   First form (most directive files use this): `body` is a quoted literal string for prefix-match. Second form: `Directives!` keyword (`before`/`ending`/`starting`/`within`) followed by a `space{` block — and `body` gets the space-bounded content. I didn't trace what the second form is FOR. Plausible: the keyword acts as a within-style positional anchor while the body still gives text content. Possible tar baby for grammar-archeology pass.

4. **`pendingDirective` is single-slot.** `FormatC.twk:1611-1613` stashes a `within` directive into the (singular) `pendingDirective`. If two directives both have `within` on the same control-flow site, the second would clobber the first. Probably never tested in anger because users don't write competing `within` directives. Tar baby.

5. **Parse-time method resolution = early binding.** Directives bind to method symbols at directive-file parse time (parts.act:286 `getMethod`). If the target method gets renamed in source between directive-write and target-parse, the directive silently misses. Strong-but-fragile coupling.

6. **`Block!` callback fires `parseDirective()` only for codeMatch-less directives** (Tawk.act:25 `if !codeMatch parseDirective()`). For codeMatch directives, `parseDirective()` runs at strncmp-match time (Tawk.act:278). So the timing of `codeToAdd → line` AST build differs by directive shape. Pure detail, but worth knowing if anyone debugs why a directive's `line` is null at moment X.

7. **`isDirected` flag prevents re-fire but is per-directive, not per-site.** Once a directive fires, it never fires again in this run. If you want a directive that fires at *every* matching site, the current mechanism doesn't support it. (Probably intentional — directives are scoped to a single anchor per declaration.)

---

## What this means for the held arc

The held arc ("development directives need replace/delete — buffer span vocabulary is the substrate") names the architectural gap between tok directives and the directives incant will need. This recon makes the gap concrete:

- **Tok directives match by text prefix into source.** Source-text point-addressing. Adding span-addressing means a different matching loop AND a way to suppress original-statement emit between the two anchors. Not extendable in place.

- **The new incant directives infrastructure (applyDirectives + spliceDirectives + opPlusEQ DiR hook, landed today) does NOT use text matching.** It operates on the target action's already-parsed BlocK GroupItem and splices into its Lines member-list. That's structure-addressing at the AST level, not text-prefix matching.

- **Replace/delete on incant directives is therefore not "extend the matching loop" — it's "extend spliceDirectives to also remove members."** Two new operations on the BlocK Lines list:
  - `removeMembers(span)` — remove members in some range
  - `replaceMembers(span, newLines)` — remove + insert at the same anchor
  
  The span vocabulary Tony's morning buffer-pass is designing IS structurally what spliceDirectives v2 will need, but applied to GroupItem list ranges rather than buffer character ranges. Different substrate (list nodes vs char positions), same conceptual operation set (mark start, mark end, insert/remove/replace between).

- **`pointInCode` has a structural analog in the incant world**: the GroupItem statement node in the BlocK Lines list. Span = (start-member, end-member). Mark = a reference to a member. Replace = drop the slice, splice new at that slot.

So the buffer-span work IS the substrate, but it's substrate-for-the-pattern, not substrate-for-the-implementation. The implementation lives in incant's GroupItem list operations, not in Buffer methods. The same span-vocabulary thinking applies in two places.

---

## What I'd hand a fresh-Claude tomorrow

If you needed to teach a fresh agent how tok directives work, the two-line summary is:

> **Tok directives are insert-only text-prefix splices.** A directive declares a target method, a hook-site string, and code to add. At target-parse, each statement carries a `pointInCode` source-char-pointer; the matcher strncmps each directive's codeMatch against that pointer. On match, the directive's code is parsed and written into the output stream before or after the matched statement. The original statement always emits. Position keywords (`before`/`ending`/`starting`/`within`) anchor non-text-match directives at structural boundaries.

The "tar babies" section above is what stops a fresh agent from being confidently wrong about edge cases.
