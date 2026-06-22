# Incant — JSON & Input Diversion (one-stop)
*Started 2026-06-22 by Clod. Self-contained wake-up for the JSON / font-loading track.
Keep current on shutdown — same discipline as jit.md.*

## Headline
**The JSON parser is green end-to-end.** baseline strings, arrays (empty / string /
number elements), nested objects, and the full Google-Fonts shape all parse `ok` with
no spiral and no segfault. Tony's offline work fixed value extraction/attachment
(`aCTionNamE` rewrite + `processAction` local-field handling for rule actions). The
last blocker — an **infinite spiral on the 2nd diverted string** — was a push/pop
input-diversion bug, fixed 2026-06-22 (below).

## Verify it still works
```
cd ../TOK && xcodebuild -project TOK.xcodeproj -scheme Groups -configuration Debug build
~/bin/incant incant/jsonTest        # 2 array tests → both "ok", reaches stop()
~/bin/incant Tests/jsonFull         # full battery (gitignored): baseline/arrays/nested/combined all "ok"
```
(`Tests/jsonFull` is a gitignored scratch fixture covering every case past jsonTest's early `stop()`.)

---

## How JSON invocation works (the divert mechanism)
`JSONblock` is a **rule**, not an action (`incant/utilities`). Calling
`JSONblock("…json…")` routes through `runRule(field, rule)` (GroupRules.mm /
GroupActions.rtn): if the argument carries data, it `pushInput`s the argument so the
parser **diverts** its input stream to the string, runs `rule.parse(0)`, then pops back.

`pushInput`/`popInput` (GroupRules.twk / .mm) maintain `inputSTAK` (a stack of saved
*parent* sources), `sourceFILE` (current source), `atRuleMark` (live cursor), and
`inputDiverted`. Two save/restore modes per source:
- **buffer-backed** (files, includes): position saved/restored via `buffer->current`.
- **naked string** (no buffer): position saved/restored via an `atMARK` attribute on the source.

End-of-input is the `'\0'` terminator in both modes (`checkSkip`/`checkInput` stop on it).
`parse()` has its own EOF handler (GroupItem.twk:966-970): when a diverted source is
exhausted it auto-pops and may `goto continueHere` to continue a rule across sources
(this is what lets `include` files work).

**Normal baseline:** the main file is always pushed over the bootstrap `setup` file, so
`inputDiverted` is **true** through the whole run and `stop()` prints
`"stop: ending input divert"` as it pops that last entry. This is NOT a symptom — a
trivial no-divert file does it too.

---

## The 2026-06-22 fix (the spiral)
Symptom: `jsonTest`'s **2nd** diverted string spun forever (parser ended up parsing the
literal text `"atMARK"`); never reached `stop()`. Root cause was two entangled bugs that
only bit when two string-diverts ran in sequence:

1. **`popInput` shadowed `sourceFILE`** (GroupRules.twk / .mm). It declared a *local*
   `GroupItem sourceFILE = inputSTAK.pop()`, so the **member** `sourceFILE` was never
   restored — it stayed pointing at the just-finished string. Fix: assign the member
   (drop the local declaration).
2. **`runRule` double-popped** (GroupRules.mm:3975 / GroupActions.rtn). It always called
   `popInput()` after `parse(0)` — but when the rule consumes the whole string to `'\0'`,
   `parse()`'s own EOF handler already popped it. The extra pop drained the stack past
   the parent file. Fix: guard the pop — capture `inputSTAK.length` before the push and
   `while … inputSTAK.length > baseStak: popInput()` (pops only what `parse` left, 0 or 1).

Chain: the double-pop (#2) left `sourceFILE` stale (worsened by #1); the next push then
saved that stale **string** as the parent via the `atMARK` path, whose restore returned
the literal tag `"atMARK"` instead of the saved position → parser parsed "atMARK…" forever.

Verified by stack-trace instrumentation (push/pop printing `stak`/`div`/`head`): pre-fix
the 2-string run did **2 pushes / 3 pops** and restored `head=[atMARK]`; post-fix every
divert is balanced and all cases parse `ok`. JIT POP battery + oneTest unaffected.

> NB Tony's hypothesis was "wrap the naked string in a Buffer." That would have dodged
> the broken `atMARK` restore path, but the actual root causes are the shadow + double-pop
> — wrapping alone wouldn't have stopped the double-pop. Left the dual buffer/atMARK paths
> in place; they're correct once the stale-parent situation is removed.

---

## Sequential-parse rule-clobber (resolved offline) — the `isRule` semantic
*Folded in 2026-06-22 from the retired `docs/json-clobber-findings.md` (2026-06-21 probe).
The bug itself is fixed; the load-bearing language semantic below is the durable keep.*

Before Tony's offline fix, repeated `testJSON()` calls corrupted the grammar: rule
`listLength`s mutated *between* parses (`JSONfield` 7→8, `JSONitem` 2→0), and the 2nd
parse of a non-empty array crashed. Two faces:
- **Destructive clobber:** `clear(grup)` inside `JSONarray`'s `code={}` reached nodes
  sharing identity with the **`JSONitem` rule definition** and emptied it.
- **Cumulative accretion:** the `JSONfield*`/`JSONitem+` repetition left matched residue
  on the rule-definition node each parse.

**The `isRule` tell (the durable semantic):** `JSONitem` was the only rule *not* declared
`isRule`. Adding `isRule` isolated the match from the definition node — i.e.
**`isRule` ⇒ match against a fresh copy, not the live definition.** A non-`isRule` rule
shares identity with its definition, so code that mutates a match (`clear`, repetition
append) reaches back and corrupts the grammar. This is the same **"no in-place
modification"** invariant `jit-design.md` leans on for schema-closure.

**Fixes applied (now live in `incant/utilities`):** `JSONitem isRule …` added; the
`clear(grup)` line removed from `JSONarray`. Sequential parses are clean (`Tests/jsonFull`
runs 10 cases in a row, no growth, no crash).

---

## Open / latent findings (not chased)
- **`processCode` has the same double-pop shape** (GroupRules.mm:3635/3648, push code →
  parse → unconditional `popInput`). It's currently balanced because a `{…}` code block
  isn't consumed to `'\0'` (parse doesn't auto-pop it), so its explicit pop is the only
  pop. Latent: if a code body is ever fully consumed to `'\0'` it would double-pop too.
  Same `baseStak` guard would harden it — left untouched (runs on every action body,
  high blast radius; verified balanced in trace).
- **`atMARK` get/getLabelGroup asymmetry.** `pushInput` saves via `get("atMARK")` +
  `addString`; `popInput` restores via `getLabelGroup("atMARK")`. When the attribute
  already exists these can disagree (the "atMARK" literal came back here). No longer hit
  in the JSON flow after the fix, but worth making the two accessors consistent.
- **Stray `CodE` artifact in array dumps.** `dumpContents(JSONblock('{"a":["x","y"]}'))`
  shows a top-level `CodE` node (the `JSONarray` `code={…}` block) beside the real
  `JSONblock`. Parses `ok` and doesn't spiral; cosmetic/structural — JSON-grammar
  territory (Tony's offline agenda), not push/pop.

---

## Next: Google Fonts two-step
With JSON green, the intended path (Tony's note):
```
jsonFontSource = getFile(googleFontURL);   // getURLintoBuffer exists in the binary;
googleFonts    = JSONblock(jsonFontSource); // needs a one-line extern decl in groups.ext
```
- `getURLintoBuffer` needs an `extern` decl in `groups.ext` to be callable (see wakeup.md
  "Fonts & colors").
- Google Fonts API key in `~/data/support/incantConfig.json`.
- After a full fonts load, Tony wants GC statistics for the wiki GC page.

## Key files
- `GroupRules.twk` / `.mm` — `pushInput`/`popInput` (input diversion).
- `GroupActions.rtn` / `GroupRules.mm` — `runRule` (rule-divert entry), `processCode`.
- `GroupItem.twk:912` — `parse()`, EOF-pop handler at :966.
- `incant/utilities` — JSON grammar (`JSONblock`/`JSONfield`/`JSONvalue`/`JSONarray`/`JSONtoken`).
- `incant/jsonTest` — tracked fixture (early `stop()`; edit to switch cases).
- `Tests/jsonFull` — gitignored full-battery scratch.
