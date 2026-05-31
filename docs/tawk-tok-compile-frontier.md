# Tawk → tok-compile frontier — Handoff (2026-05-31, late)

*Where the `plg Tawk.g → Tawk.twk → tok → Tawk.C` arc stands mid-grind. Written so a fresh
Clod/Clay can resume cold. Companion to `plg-wakeup.md` (plg internals) and `wakeup.md`.*

## One-line status
`plg Tawk.g` → **`Tawk.twk` clean (exit 0)**. `tok Tawk.twk` → **does NOT complete `Tawk.C`
yet** — it crashes/FAILs partway through the stale Tawk *action bodies*. It has produced a
real `Tawk.h` (156 lines) when the parse was clean up to the crash. The remaining work is a
**method-by-method reconciliation of the action bodies to the new PLGitem surface** — a long
but mechanical grind.

## The big achievement this session: named options (per-alternative actions)
The architectural blocker is **solved and committed-worthy**. An action belongs to one
*alternative* (option) of a rule, not the whole rule:
- **`Alternative`** (Alternative.twk) now carries `immediateAction`/`deferAction` (the body),
  `actionName` (emitted method base name), and `immediate`/`defer` function pointers; it has
  its own `generate`/`writeActions`/`writeCaptures`.
- **`PLGparse::generateRules`** distributes the `.act`-attached numbered-rule shells (`Foo`,
  `Foo2`, `Foo3`) onto the base rule's alternatives by index, sets `actionName`, and emits one
  method per alternative-with-an-action.
- **`PLGrule::match`** fires the matched alternative's `immediate` directly and records
  `result.deferAlt = alt` for the deferred case; **`PLGitem.runDeferred`** prefers `deferAlt`
  over the rule-level `deferRule`. (`PLGitem` gained a `deferAlt` field.)
- **`PLGrevision`**: `external Alternative` gained the action fields/methods; `external PLGitem`
  gained `deferAlt`.

Verified: FieldBody / FieldBody2 / FieldBody3 parse with the *correct per-alternative captures*
(`FieldBody2TawkAct` gets `PLGitem name = iTEM.children["name"]` from alternative 2) and the
wiring (`currentAlt.defer = FieldBody2TawkAct`). Parse was 100% clean (0 FAILs, 0 ERROR
Inheritance) up to the codegen crash.

## The grind: removed old-PLGitem (PLGtester) fields in the action bodies
With the parse clean, tok now crashes/FAILs one stale construct at a time. **Mappings already
applied** (in the 5 Tokf `.act` files):
- `iTEM.testParser` → bare `X` (actions are methods on the parser; for an explicit handle use
  `Tok::testParser` or `this`)
- `iTEM.test.*` → gone (removed; one site commented/removed)
- `X.amount` (read) → `X.getAmount()`; `X.amount` (write) → the real settable `amount` field
  (added to PLGitem)
- `X.run()` → `X.runDeferred(this)`
- `plgStart` → `cursor` (they're the same — the parse cursor; the `plgStart` field was dropped)
- `X.get("L")` → `X.get("L")` works again via `alias get getLabel` on PLGitem (PLGrevision);
  `X["L"]` works via `overload [] getLabel`
- `hash[PLGitem]` (BaseHash keyed by a PLGitem) → **tok codegen SEGFAULTS** on it; fix is
  `hash[plgitem.toString()]` (text key). Done for `macroList`/`macroHash` in generate.act.
- **`.`-separated options**: the old `.act` format separated options with a bare newline-`.`
  (the old `ActionEnd` terminated on `\n.`), not only `|`. The migration only split on `|`/`|.`,
  so it left a stray `.` mid-body. Only **one** survived — `MethodType` (Tawk.act) — now split
  into `MethodType defer` + `MethodType` (one alternative, both immediate+defer bodies).

**Next / needs Tony's mapping (he's listing these offline):**
- `type.flag4` (in `Parameter`) — a removed old-PLGitem/PLGtester field. Restore it, or map to
  what? Likely sibling `flagN` fields too.
- Watch for: `currentTest`, `saveTest`, `guardSet`, `processUpTo`, `leftBalance`/`rightBalance`,
  `skipOverMatch`, `isIgnored`, `errorMessage` — these showed up as 121 unresolved fields when
  the **old tool-source** `Tokf/Tawk.C` was (re)generated. The Tawk *bodies* may hit a subset.

## Two distinct crash classes (diagnosing which is which)
1. **Parse FAILs** (`FAIL Body3/Block/ClassBlock …`): a stale field/method or a migration edge
   case (stray `.`). tok reports them, then a malformed method cascades into `ERROR Inheritance`
   (field decls appearing outside the class). Fix the construct.
2. **Codegen SEGFAULT** (exit 139, often no FAILs): tok dies generating C++ for a construct it
   can't resolve (e.g. `hash[PLGitem]`) instead of erroring. Isolate the method (it usually
   crashes alone too), find the construct, fix.

## How to resume (the loop)
```bash
cd …/InProcess/Tokf/Tests
plg Tawk.g                       # regenerate Tawk.twk (clean)
tok Tawk.twk                     # find the first FAIL / segfault
# bisect to the crashing method: { head -N Tawk.twk; echo '}'; } > t.twk ; tok t.twk
#   (exit 139 = crash at/before N ; exit 0 = crash after N)
# isolate a method's body in a minimal `class Tawk extends PLGparse { <body> }` + `include
#   includes` to confirm the exact crashing construct, fix it in the .act, repeat.
```
Build gotchas (from `plg-wakeup.md`): plg **Debug only**; always `tok X.twk plgDirectives` for
plg's own `.twk`; `~/bin/plg` → `Parse/build/Debug/plg`. **lldb can't open files in this
sandbox** — debug tok in Xcode if a backtrace is needed (but the tool-source `Tokf/Tawk.C` has
121 stale-field errors, so a debug-tok build is itself blocked — that's why we grind the bodies
instead).

## Repo / commit state
Committed this session: the named-options runtime (Alternative/PLGrule/PLGitem/PLGparse + .C/.h),
PLGrevision externs, and the `.act` body progress. **`Parse/PLG.twk` (+ PLG.C) left uncommitted
on purpose** — the `IncludeplgNow` stopgap that routes `.act` → `attachActions`; the durable
version belongs in `plg.g`/`action.g` (named-options design pass, still pending — see
`plg-wakeup.md §11`).
