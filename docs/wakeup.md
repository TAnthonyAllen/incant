# Incant — Status & Handoff (2026-06-18)
*Written by Clod for a fresh Clay/Clod. Assumes no memory of today. Self-contained.*
*(Prior handoff (2026-06-16, IncantForms conversion) is in git history — see Parked threads.)*

## Headline
**Phase JIT, Phase 1 (straight-line arithmetic) is substantially proven and committed.**
Today's roll: Plan B → Plan A → strip → typed arithmetic → real field unbox. Four POPs
green in one pass; bytecode path untouched. The active thread to resume is **rolling the
jitting gate onto the remaining opMethods.**

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

## IMMEDIATE NEXT — the rollout (this is where we pick up)
Difficulty gradient, do in order:
1. **opMinus, opMultiply (Instruct.rtn) — mechanical one-liners.** `jitEmitBinary` already
   has the `jitSub`/`jitMul` cases. Each gate is just
   `if jitting { return jitEmitBinary(argument, target, jitSub); }` (resp. `jitMul`). Add
   `jitSub`/`jitMul` fixtures, prove. Near-zero risk; cashes in "one line per op."
2. **divide/remainder — GLYPHS RESOLVED (2026-06-19).** Renamed cleanly:
   `%`=`opRem`, `/`=`opDiv`, `/=`=`opDivEQ` (was `%`=`opDiv`, `/`=`opSlash`,
   `/=`=`opSlashEQ`). `jitEmitBinary` carries `jitSDiv` for `/`; a `jitRem` case
   awaits wiring `%`. See `jit-design.md` §1d.
3. **Comparisons (`> < >= <= == !=`).** Do NOT fit `jitEmitBinary` — they yield an `i1`
   and the result feeds a branch, not a store-back. **`jitEmitCompare` SKELETON DRAFTED
   (2026-06-19)** in `jitEmitters.rtn` — `CreateICmp*`/`CreateFCmp*` matrix, `enum jitCmp`
   in `jitContext.h`, plus the i1→i32 ZExt cap in `jitRunAction`. Not wired (no gate, no
   fixtures). NB: promotion block is RETAINED (mixed `count < number` must SIToFP — LLVM
   has no cross-type compare).
4. **unary (`++`/`--` → `jitEmitUnary`), assign (`=`, its own shape).** `jitEmitAssign`
   SKELETON DRAFTED (2026-06-19) — store-only, plain `=`. Both findings now resolved:
   `jitSeedField` stashes the baked field address into `jitSlot` (field targets have a
   store destination; literals correctly get none); compound `+=` is gate-level
   composition (`jitEmitBinary` then store), store-only emitter by design. Remaining for
   wiring: the opMethod gates + fixtures.

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
