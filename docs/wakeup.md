# Incant — Status & Handoff (2026-06-20, + 2026-06-22 update on top)
*Written by Clay/Clod for a fresh Clay/Clod. Assumes no memory of today. Self-contained.*

## ⚠️ 2026-06-22 update — READ FIRST, then VERIFY (state was mid-flight at shutdown)

**Pushed & done:** md-cleanup commit `253dd39` on `incant.git` main (retired stale docs,
repointed bible jit.md→docs/jit.md, merged WhatIsIncant Appendix A, fixed bootstrap 28→32,
added `docs/json.md`). Wiki pages pushed to `incant.wiki.git` (`b93858c`): Memory Management
+ Directives added, Home indexes all pages. CLAUDE.md gained a **Standing Permissions**
section (file/bash ops in InProcess pre-authorized; pause only on errors/grind/summary/direction).

**pushInput/JSON-divert fix landed in SOURCE** (so retok-proof): `GroupRules.twk` popInput
member-restore (drop the `GroupItem` local that shadowed the member `sourceFILE`); `GroupActions.rtn`
runRule `baseStak` guard (don't double-pop after parse's EOF auto-pop). Full tape: `docs/json.md`.

**⚠️ JSON REGRESSED and was under debug at shutdown — DO NOT trust the "JSON GREEN" section
below; VERIFY EMPIRICALLY.** After Tony retok'd (and a full `tokall`), `JSONblock('{"a":"b"}')`
**fails to match right out of the gate** (returns null; no spiral — reaches `stop()`). JIT (~20
POPs) and bytecode (`oneTest`→26) stayed **green** throughout. Confirmed NOT the cause: my
push/pop fixes (in source, survived tokall); not a dropped extern (`resetField` present);
`aCTionNamE`/`processAction` generate correctly with the local-field fix. Since a full `tokall`
from current source is red but earlier-this-session was green, the gap is in **source or a
directive**, not `.mm` (Tony never hand-edits `.mm` — all `.mm` is tok-output). **Tony was
fixing it in Xcode at shutdown.** FIRST on wake: run the battery (jsonTest/jsonFull) to see
the *current* JSON state — Tony may have fixed it. If still red, hunt the source/directive
delta vs the green build; the green binary's behavior is the spec.

**Offline bucket NOT committed** (correctly gated on a green JSON build): working tree holds the
offline `.mm`/`.twk`/`.rtn` + `docs/jit.md` + `docs/wakeup.md` + the source-synced pushInput/JIT
work. When JSON is green again → rebuild, run full battery, then commit the offline bucket
**separate from Tony's never-commit directive dev material**.

---

## Headline
**Phase JIT Phase 1 straight-line essentially complete — 18 POPs green.** Arithmetic,
all six compares, assign (`=` `+=` `*=` `−=`), AND unary (`++` `−−`) all proven end-to-end.
The **only** straight-line op left is **division** — and it has a real int-vs-float
semantics fork that needs a decision before wiring (the "division tape" parked below).
Next frontier after that is **Phase 2: control flow (IF/FOR)** — on Clay's design plate.
JSON parser autopsied — offline work ongoing (the JSON bear hunt is Tony's offline agenda).
IncantForms conversion complete. Font architecture designed and partially implemented.

## Verify it still works (do this first on wake)
```
cd <repo>/../TOK
xcodebuild -project TOK.xcodeproj -scheme Groups -configuration Debug build
~/bin/incant incant/jitscratch   # expect 18 POPs green (incl. jitInc 14, jitDec 12, jitMinusEQ 25)
~/bin/incant incant/oneTest      # 5-action battery; testByteCode→11 then testIfElse→26 (final print = 26)
```
NOTE: the old "expect maximus = 11" line was from when oneTest ran only testByteCode. It now
runs a 5-action battery (testByteCode→11, testIfElse→26, then whilE/do/for which leave 26).

---

## Active threads

### JIT — what got done 2026-06-20 (unary + −=)
**Unary dispatch: DONE, green** (`jitInc`→14, `jitDec`→12, write-through verified).
Wiring lives in `aCTionExpressioN`'s jitting branch (`ruleActions.rtn`): for a single-
element xpList whose unwrapped element is a `uxp` (the node `aCTionTokenXP.handleUnary`
builds for a prefix unary), it `jitSeedField`s the operand (`arg[2]`), sets `arg.invoke`,
and fires `arg.method(arg)` → `runOP` → the operator's own `opPlusPlus`/`opMinusMinus`
`if jitting` gate → `jitEmitUnary`. The gate was already in those opMethods; the only new
code is the `uxp` dispatch branch. Two hard-won gotchas from that session:
- **incant unary is PREFIX-only** (`++righty`, not `righty++`). Postfix silently doesn't
  parse as a unary op (baselineTests even prints "Unary operators must preceed their argument").
  My first fixtures were postfix → nothing fired. One-char fix.
- **`.taG` (capital G) trips `ERROR Inheritance` in tok `.rtn` source** — use lowercase
  `.tag`. It silently drops the *next* extern from the `.mm`. (Three languages share the
  tree — tok/C++/incant — and syntax bleeds; see the new memory notes.)

**`opMinusEQ` (`−=`): DONE, green** (`jitMinusEQ`→25). Pure copy of `opPlusEQ`'s gate with
`jitSub`: `jitEmitBinary(arg,target,jitSub); return jitEmitAssign(target,target)`. No new
machinery — `+=`/`*=` already proved the compound = binary-then-store-back composition.

**Commit status:** all of the above is UNCOMMITTED and tangled into the offline-dirty
`ruleActions.rtn`/`Instruct.rtn` (Clay's "hold the commit" on offline buckets still stands).
Tease the JIT diff apart from the rStuff-chokepoint edits when the commit verdict comes.

### JIT — division tape (PARKED, needs a decision before wiring)
Division (`opDiv` `/`, `opDivEQ` `/=`) is the last straight-line op. Wiring is trivial
(same gate pattern as `−=`), but there's a real **int-vs-float semantics fork**:

- **Interpret** (`Instruct.rtn:69,85`): `tempField.count = (int)lround(number / argument.number)`
  — counts are divided as *doubles then `lround`'d*, so incant integer division **rounds to
  nearest**: `7/2 = 4`. (Float operands: plain FDiv, no issue.)
- **`jitEmitBinary` jitSDiv path** (`jitEmitters.rtn:124`): two i32 operands → `CreateSDiv`
  = **truncating** integer division: `7/2 = 3`.
- **They disagree on count÷count.** Pointing `opDiv` at `jitSDiv` as-is yields a *green-but-
  wrong* POP (JIT says 3, incant says 4).

The fork:
1. **Faithful (recommended):** make the count path match interpret — `SIToFP` both → `FDiv`
   → `llvm.round` intrinsic (half-away-from-zero == `lround`) → `FPToSI` → i32. ~6 lines of
   new emit in `jitEmitBinary`'s div case (branch on operand type) + the two gate wirings +
   a `jitDiv`/`jitDivEQ` POP. The only new gadget is the round intrinsic. ~2-3 build cycles,
   no expected grind. Keeps JIT == interpret.
2. **Truncate (C semantics):** accept JIT count division truncates (`7/2=3`), diverging from
   interpret. One-line-copy quick win, but plants a semantic divergence and every count-div
   test must be written to the truncated value.

`jitSDiv` already exists in `enum jitOp` but is unused; `opDiv`/`opDivEQ` carry NO jit gate yet.

### JIT — Phase 2 (control flow, IF/FOR) — Clay's design plate
After division, the frontier. Tony's read: should be easier than feared — the rule actions
(`aCTionIF`/`aCTionFOR`) already do most of the work; JIT just needs the branching emit calls.
Five probe questions are in the parked JIT instructions — gIF/gFOR pattern, LLVM basic blocks,
`gJitResult` as i1 into `CreateCondBr`, `JitContext` wiring, and the `tempField` chaining guard.

### JSON parser — GREEN (2026-06-22). See `docs/json.md` for the one-stop.
Value extraction/attachment fixed offline (Tony: `aCTionNamE` rewrite + `processAction`
local-field handling). The last blocker — an infinite spiral on the 2nd diverted string —
was an input-diversion bug, fixed 2026-06-22:
- **`popInput` shadowed the member `sourceFILE`** with a local → never restored.
- **`runRule` double-popped** (its `popInput` ran after `parse()`'s EOF handler already
  popped a fully-consumed string) → drained the stack past the parent; next push saved a
  stale string-parent via the `atMARK` path whose restore returned the literal `"atMARK"`.
Fix: assign the member in `popInput`; guard `runRule`'s pop with a `baseStak` length check.
Now baseline / arrays / nested / combined Google-Fonts shape all parse `ok`
(`incant/jsonTest`, `Tests/jsonFull`). Full tape + latent findings in `docs/json.md`.
**Next:** Google Fonts two-step (`getFile` → `JSONblock`); `getURLintoBuffer` needs a
`groups.ext` extern decl.

### IncantForms — conversion complete
11 files converted by `convert_all.py`, 11 skipped (already hand-converted). Scripts
in `XML/WorkingOn/`. One pending cleanup: the `#search` rule is in `convert_form.py`
and the walker has been re-run. `#print` left as `# TODO` for manual review. Converted
forms are uncommitted pending Tony's eyeball.

### Fonts & colors — partially implemented
- Font registry format consolidated onto `family=`/`size=`/`bold`/`italic` across
  three files (committed).
- `setFont` and `setColor` fixes in `Stylish.twk` — parked; `Stylish.twk` not in
  active use yet (GUI-build only, not in the command-line `Groups` target).
- Google Fonts API key in `~/data/support/incantConfig.json`.
- `getURLintoBuffer` exists in the binary, needs a one-line `extern` decl in
  `groups.ext` to be callable from incant.
- Fetch/cache implementation is greenfield — design documented, not yet built.
- **The JSON parser must be fixed before `loadGoogleFonts` can be implemented.**

### GroupUI recon — parked, needs Tony guidance
Tonto recon into `OLDtawkDoNotTouch/Groups/GUI/GroupUI` needed before drawRules
conversion and GUI work can proceed. Tony needs to provide guidance on what to look
for vs ignore — old class structure is mostly obsolete. Priority rising as JIT
velocity increases.

---

## Key files
- `Instruct.rtn` — opMethod gates (opPlus/Minus/Multiply done; opPlusPlus/opMinusMinus
  gated but dispatch unwired).
- `jitEmitters.rtn` — all emitters: `jitEmitBinary`, `jitEmitCompare`, `jitEmitAssign`,
  `jitEmitUnary`.
- `jitContext.h` — `enum jitOp`/`jitCmp`/`jitUnary`, `JitData`, globals, `JitContext`
  (scaffolding).
- `ruleActions.rtn` — `aCTionExpressioN` jitting branch (needs unary case).
- `incant/jitscratch` — JIT POP driver.
- `incant/json1` / `incant/jsonTest` — JSON parser test fixtures (uncommitted).
- `XML/WorkingOn/convert_form.py` / `convert_all.py` — IncantForms conversion scripts.

## Parked
- `IncantForms/Windows/*` converted forms — uncommitted, pending Tony eyeball.
- drawRules conversion — gated on GroupUI recon.
- GUI redesign / HTML transpiler — parked behind JIT.
