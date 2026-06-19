# Incant — Status & Handoff (2026-06-19)
*Written by Clay for a fresh Clay/Clod. Assumes no memory of today. Self-contained.*

## Headline
**Phase JIT Phase 1 complete — 15 POPs green.** Arithmetic, compare, and assign
emitters all proven. Unary skeleton in and committed, dispatch not yet wired. JSON
parser autopsied — offline work in progress. IncantForms conversion complete. Font
architecture designed and partially implemented.

## Verify it still works (do this first on wake)
```
cd <repo>/../TOK
xcodebuild -project TOK.xcodeproj -scheme Groups -configuration Debug build
~/bin/incant incant/jitscratch   # expect 15 POPs green
~/bin/incant incant/oneTest      # expect maximus = 11
```

---

## Active threads

### JIT — immediate next (top priority)
**Unary dispatch wiring is the first order of business.** The skeleton
(`jitEmitUnary`, `enum jitUnary`, gates on `opPlusPlus`/`opMinusMinus`) is committed
and baseline-green. The dispatch is **not** wired — unary expressions flow through
`aCTionTokenXP` → `uxp` node → `runOP`, bypassing `aCTionExpressioN`'s jitting branch
entirely.

Concrete plan:
1. Instrument `aCTionExpressioN`'s jitting branch to see what `righty++` looks like
   in `xpList`.
2. Add unary case: unwrap `uxp`, extract op+operand, `jitSeedField` the operand,
   invoke unary opMethod under jitting.
3. Fixtures `jitInc` (`righty++` → 14) / `jitDec` (`righty--` → 12) + readback.

After unary is green → **Phase 2 probe** (control flow design). Five probe questions
are documented in the parked JIT instructions — gIF/gFOR bytecode pattern, LLVM basic
blocks, `gJitResult` as i1 input to `CreateCondBr`, `JitContext` wiring question, and
the `tempField` chaining guard.

### JSON parser — Tony offline work
Test fixtures: `incant/json1` (single case, edit to switch) and `incant/jsonTest`
(full suite, run individually).

Two independent bugs, both understood:
- **Bug 1 — value extraction:** `setLabel` can't cleanly extract the string value
  from the `JSONvalue` wrapper node. `JSONvalue.text` returns a pointer/number, not
  the string. The value lives *inside* the wrapper — need to dig into `JSONvalue.group`
  or find the right child node. `JSONtoken` holds the key; `JSONvalue` holds the value
  but as a wrapped node, not a bare string.
- **Bug 2 — attachment:** Even when `setLabel` returns a correctly built node, it never
  lands in the enclosing `JSONlist`. The `JSONfield*` repetition doesn't collect
  `code={ return … }` results into the parent. Likely needs either parent-clearing
  before return or a fix in the collection mechanism.

Fix ladder (do in order):
1. **Rung 1:** get `{"a":"b"}` to produce a populated field with `a="b"`.
2. **Rung 2:** accumulate two members `{"a":"b","c":"d"}`.
3. **Rung 3:** nested object `{"a":{"b":"c"}}`.
4. **Rung 4:** array value `{"a":["x","y"]}`.

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
