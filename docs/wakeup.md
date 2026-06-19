# Incant — Status & Handoff (2026-06-19)
*Written by Clod for a fresh Clay/Clod. Assumes no memory of today. Self-contained.*
*(Prior handoff (2026-06-16, IncantForms conversion) is in git history — see Parked threads.)*

## Headline
**Phase JIT, Phase 1 straight-line lowering is COMPLETE across arithmetic, compare, and
assign — 15 POPs green in one pass.** The jitting gate is rolled onto every straight-line
opMethod (`+ - *`; `> < >= <= == !=`; `= += *=`); assign **writes through** to real
GroupItem storage (readback-proven). Bytecode path untouched. The active thread to resume
is **unary (`++`/`--`)**, then **Phase 2 (control flow)**. Full POP table in `jit.md` Status.

## Verify it still works (do this first on wake)
```
# build:
cd <repo>/../TOK   # /Users/anthony/.../InProcess/TOK
# (after editing .twk/.rtn:)  tok GroupRules.twk   [and tok GroupMain.twk if it changed]
xcodebuild -project TOK.xcodeproj -scheme Groups -configuration Debug build
# run JIT POPs (expect 8, 8, 8, 18):
~/bin/incant incant/jitscratch
# bytecode regression (expect maximus = 11):
~/bin/incant incant/oneTest
```
`~/bin/incant` is the TOK-built `Groups` binary (symlink). Edit `.twk`/`.rtn`, run `tok`,
then `xcodebuild` — Xcode does NOT auto-tok.

## The design (locked, in place)
**Plan A — the jitting gate lives INSIDE the opMethod.** `opPlus` (Instruct.rtn) has
`if jitting { return jitEmitBinary(argument, target, jitAdd); }` above its interpret body.
`aCTionExpressioN`'s jitting branch (ruleActions.rtn) dispatches the operator's own
`operat` (no `jit` child) — it self-gates. At endgame the interpret body + gate strip out
and the opMethod *is* the emitter. (Plan B — emitter on a `jit` child — was built then
stripped; don't resurrect it.)

`jitEmitBinary` (jitEmitters.rtn; `enum jitOp` in jitContext.h) is the shared binary-arith
emitter: one line per op, int/float variant + numeric promotion centralized. Header-clean
signature (`GroupItem,GroupItem,int`), LLVM in the `-% %-` body.

Proven POPs (fixtures in `incant/generate`, driven by `testing(<fixture>)` in
`incant/jitscratch`): `jitAdd` 3+5→8 (CreateAdd), `jitAddF` 3.0+5.0→8 (CreateFAdd),
`jitMix` 3+5.0→8 (count SIToFP-promoted→FAdd), `jitFieldAdd` righty+5→18 (jitSeedField
unboxes the real field via CreateLoad of gCount).

## ROLLOUT — DONE (2026-06-19): arithmetic + compare + assign all WIRED & GREEN
15 JIT POPs proven end-to-end (see `jit.md` Status for the full table). Next pickup is
**unary** then Phase 2 (control flow). History below kept as the trail.
1. **opMinus, opMultiply — WIRED.** `jitEmitBinary(jitSub/jitMul)`. Fixtures `jitSub`
   (8-3→5), `jitMul` (3*5→15) green. (commit `05195da`)
2. **divide/remainder — GLYPHS RESOLVED.** `%`=`opRem`, `/`=`opDiv`, `/=`=`opDivEQ`
   (was `%`=`opDiv`, `/`=`opSlash`, `/=`=`opSlashEQ`). `jitEmitBinary` carries `jitSDiv`
   for `/`; a `jitRem` case awaits wiring `%`. See `jit-design.md` §1d.
3. **Comparisons (`> < >= <= == !=`) — WIRED.** Six `opMethod` gates → `jitEmitCompare`
   (`CreateICmp*` matrix, `enum jitCmp`), i1 `ZExt`'d to i32. Fixtures green (0/1/1/0/1/1).
   Promotion block RETAINED (mixed `count < number` must SIToFP — no cross-type compare).
   (commit `736b25e`)
4. **assign (`= += *=`) — WIRED.** `opAssign` → `jitEmitAssign` (pure store); `opPlusEQ`/
   `opMultiplyEQ` compose `jitEmitBinary` then `jitEmitAssign(target,target)`. Store
   **writes through** to the GroupItem — proven by reading `maximus` back (8 / 15 / 12).
   `jitSeedField` now stashes the field address into `jitSlot`. (commit `d4964d4`)
5. **NEXT: unary (`++`/`--` → `jitEmitUnary`)** — the last straight-line family, then
   Phase 2 (control flow: branches/blocks) and Phase 3 (strings, runtime callbacks).

## Authority + watch-items
- `docs/jit.md` "Status (2026-06-18)" section is the authoritative Phase-1 status.
- `docs/jit-design.md` (codegen design, Phase 1/2/3) and `docs/jit.md` (frame/calling
  convention) are the design pair.
- **CLAUDE.md bear trap #9:** the gate's `else jitSeedField` treats any non-literal operand
  as a real field. Single-op POPs hide it; **chaining `a+b+c` mis-routes the inner result**
  to jitSeedField. Guard on "operand already carries jitData" when chaining lands.
- **Deferred (per jit.md Status):** rebox/return `GroupItem*` epilogue; slot-array calling
  convention; cached-function refire (makes load-vs-fold observable — the next *real* proof
  that JIT isn't a constant folder); the chaining guard.

## Commits today
`cc2fd2d` Plan B → `a3498f4` Plan A → `e85c32d` strip → `a8a25ce` typed arithmetic + field
unbox. First three are pushed to `main`; **`a8a25ce` is held LOCAL** pending Tony's "push".

## Key files
- `Instruct.rtn` — the opMethods (opPlus done; opMinus/opMultiply/opSlash next).
- `jitEmitters.rtn` — jitEmitBinary, jitSeedLiteral, jitSeedField, jitRunAction (driver).
- `jitContext.h` — `enum jitOp`, gJitBuilder/gJitResult globals, JitData (hand-written, not tok'd).
- `ruleActions.rtn` — aCTionExpressioN jitting branch (the gate).
- `incant/generate` — fixtures; `incant/jitscratch` — POP driver.
- `Include/groups.ext` (OUTSIDE the repo) — jit extern decls; cross-TU handlers need a decl
  here or tok emits the name-as-string-literal-fnptr → SIGBUS.

## Parked threads (NOT today's work)
- **IncantForms conversion** — in-flight bulk XML→incant `define` rewrite; uncommitted edits
  sit in the working tree (`git status`: `IncantForms/Windows/*`, `XML/WorkingOn/parser`).
  Full detail in the prior wakeup (this file's 2026-06-16 version in git history).
- **GUI redesign** — Layout recon done (`docs/layout-recon.md`, untracked/local by Tony's
  call); incant→HTML-transpiler-bridge direction captured there + in project memory. Parked
  behind JIT.
