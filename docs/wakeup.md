# Incant — Status & Handoff (2026-06-25, PM: Phase 2 JIT)
*Written by Clod for a fresh Clay/Clod tomorrow. Assumes no memory of today. Self-contained.*

## What this is
**Phase 2 JIT = control flow (`gIF`).** Phase 1 (straight-line: arithmetic, compare, assign,
unary, division, string `+=`) is complete — 25 POPs green. Today did the Phase 2 **prerequisites**
and **chose the architecture**, but did *not* yet land a working `gIF`: (1) implemented **unary
minus** (the negative-value prerequisite), (2) wired **mem2reg/PromotePass** (the SSA foundation
control flow needs), (3) probed how to *drive* `gIF` emission, reversed two wrong turns, and
decided on a **parallel, JIT-owned walk**. All committed/pushed to `main`; tree is green.

## The lens (hold these to reason about the JIT)
- **Two independent lowerings of the same parsed tree.** Bytecode (`generateCode` → `generatE`
  walk → `gIF`/`gXpress` handlers emit bytecode) and JIT (LLVM IR) are *parallel*, not a pipeline.
  Keep them separate.
- **How JIT runs today:** `testing(action)` → `jitRunAction` (`jitEmitters.rtn`) sets `jitting=1`,
  calls `processCode` which **parses the action body and emits LLVM IR *during the parse*** —
  each opMethod (`opPlus`/`opLT`/`opAssign`/…) has an `if jitting { … }` gate that emits straight
  into `gJitBuilder`. Then it caps with `CreateRet(gJitResult)`, ORC-compiles, runs, returns the
  native int. This **emit-during-parse** model is proven for straight-line and is the path we do
  NOT touch.
- **Why control flow is different:** an `if` is a **deferred** statement. Under JIT today it never
  reaches a handler that could place its arms in basic blocks — so it can't get a `CreateCondBr`.
  Control flow needs a **walk** (like the bytecode `generatE`), not emit-during-parse.
- **PromotePass is wired** (`jitRunAction` runs `llvm::PromotePass` over the function before
  `addIRModule`). So gIF arms just `CreateStore` to field-slot allocas and LLVM inserts the merge
  phis — **never hand-write a phi**. (No-op on today's alloca-free straight-line IR; verified non-
  destructive.)

## Current state — commits on `main` (`33c07be..31c007a`)
- `7f3367e` — **Unary minus** (`opUnaryMinus`): negative literals + field negate.
- `cb1918c` — **mem2reg/PromotePass** into the JIT pass pipeline.
- `13e322e` — gIF JIT recon brief (the design seed).
- `31c007a` — gIF **drive findings + the parallel-JIT-walk decision** (`docs/gif-jit-recon.md`).

## DONE — bones-confirmed (actual run output, not shape-read)
- **Unary minus, both paths.** Interpret (`Tests/`-style probe): `-7`→**-7**, `-righty`→**-13**,
  `righty - righty`→**0**, `20 - righty`→**7** (binary subtraction preserved). JIT: `jitNeg` POP →
  `jitRunAction result = -13` (`CreateNeg`). Grammar: `-` in the `UnaryOPS` bin; `TokenXP
  UnaryOPS? ANYorNum^ InvokeArg?` (`ANYorNum` = `NumbeR｜ANYtoken` so the operand can be literal
  *or* field; the `^` no-skip adjacency on the operand is the steal-guard — spaced ` - ` falls to
  binary `opMinus`). Op: named `negate unary ruleMethod=opUnaryMinus` in `Operators`; `handleUnary`
  swaps prefix `-`→`opFields["negate"]`, binary `-` slot untouched.
- **PromotePass non-destructive:** full 25-POP `jitscratch` battery green, `oneTest`→**26**,
  `jsonTest`→ok.

## OPEN — root-caused; the Phase 2 frontier
**`gIF` has no JIT drive yet. Decision made: build a parallel JIT walk.** Root causes found
(empirical, via a diagnostic `printf`, binary verified fresh):
- `aCTionIF` is **NOT** on the JIT path — it never fires under `jitting`. (So a jitting gate in
  `aCTionIF` is the wrong layer; that wrong turn was reversed.)
- The deferred `IF`→`gIF` dispatch lives in **`runGenerated`** (`incant/generate:46`), driven only
  by **`generateCode`**'s `generatE` walk. `jitRunAction` does `processCode`-only and never invokes
  that walk — so control flow has no JIT dispatch.
- **Decision (Tony + Clay + Fearless):** a **parallel, JIT-owned walk** — `jitGeneratE` /
  `jitRunGenerated` modeled on `generatE`/`runGenerated` (`incant/generate:46,233`) but **LLVM-
  native handlers from day one**. Bytecode pipeline stays pure (no dual-mode). `jitRunAction`
  drives the JIT walk for deferred/control-flow nodes; straight-line stays emit-during-parse.
  Full findings + the validated `jitEmitGIF` emitter sketch (three-block topology, runtime
  `CreateCondBr`, both arms emitted) are in **`docs/gif-jit-recon.md`** (Session 2026-06-25 PM
  section).

## DEFERRED — not this arc; whose call
- **GUI content dispatch** (text/image/cell/path off `Layout.drawRect`) — the other big active
  thread. Platform is solid (window envelope + stable painting, see git `767d16c` era); content
  handlers are **Clay's design conversation** (`docs/gui-brief.md`, `docs/font-recon.md`). Also
  parked there: drop the diagnostic `printf` in `guiHost.mm`; `viewDidEndLiveResize` re-layout.
- **gIF beyond the first POP:** else-arm, nesting, compound conditions (`a<0 and b>0` is the
  chained-operand bear in `jit.md`). First POP is single-compare + one then-arm + no else.
- **Full frame model / slot-array calling convention, return-real-GroupItem epilogue** (`jit.md`).

## Run recipe (verify green before starting)
```
~/bin/incant incant/oneTest     # bytecode battery -> "maximus = 26"
~/bin/incant incant/jsonTest    # -> ok : {"a":[]} / ok : {"a":["x","y"]}
~/bin/incant incant/jitscratch  # 25 JIT POPs: results + readbacks, incl. jitNeg -> -13
```
(Boot noise `getRStuff:` / `aCTionDefinE:` is normal. For a crash backtrace run under
`script -q /dev/null …` — segfaults otherwise lose buffered stdout.)

## To resume — next actions in order
1. Read `runGenerated` + `generatE` (`incant/generate:46,233`) and `gBlocK` (`:55`) carefully —
   understand the dispatch shape (`generator[node]` → handler).
2. Build **`jitRunGenerated`** as a clean parallel — a JIT-owned dispatch (LLVM-native handlers),
   **cloning** the pattern, not bending the original.
3. Wire the **`gIF` handler first** (single compare, one then-arm, no else — prove `entry →
   header → thenBB → endBB`) using the preserved `jitEmitGIF` emitter sketch in
   `docs/gif-jit-recon.md`.
4. Make `jitRunAction` invoke the JIT walk for deferred/control-flow nodes; leave straight-line on
   emit-during-parse.
5. Verify by running, not shape-reading: a `jitGIF code={ if righty < 0; maximus = 99; }` fixture
   must branch at **runtime** (righty<0 → maximus=99; righty≥0 → maximus unchanged), and the 25
   straight-line POPs must stay green.

For Clay: the design inputs are `docs/gif-jit-recon.md` (full), `docs/jit.md` (Phase 2 section),
`docs/jit-design.md` (frame/SSA model). Source to have in hand: `incant/generate` (the walk +
handlers), `jitEmitters.rtn` (`jitRunAction` + emitters).

## Gotchas (durable — will bite again)
- **`ruleActions.rtn` / `Instruct.rtn` / `jitEmitters.rtn` are `include`d INTO `GroupRules.twk`**
  (L290/292/294) and tok-processed into `GroupRules.mm`. Editing them needs **`tok GroupRules.twk`
  THEN `xcodebuild`** — `xcodebuild` alone silently recompiles the stale `.mm` (symptom: your edit
  isn't in `GroupRules.mm`; `grep` it to confirm). Cost real time today.
- **`groups.ext` is the prototype home and lives OUTSIDE the repo**
  (`~/Dropbox/data/InProcess/Include/groups.ext`). Any extern called from tok-parsed `.rtn` code
  (outside `-% %-`) needs its prototype there for tok to parse the call. Not git-tracked here.
- **`gMethod` is a function pointer on `groupBody`** — call it `x->groupBody->gMethod(x)` in raw
  C++ (`-% %-` blocks, where tok does NOT translate `.gMethod`). It can be null — guard it.
- **`nm`, not `strings`**, to check a symbol compiled in; binary mtime is unreliable; interpreted
  `incant/*` runs fresh regardless. `~/bin/incant` symlinks to the DerivedData `Groups` product
  (build the **Groups** scheme of `../TOK/TOK.xcodeproj`).
- The pre-existing modifieds in `git status` (`GroupItem.mm`, `IncantForms/Windows/tabs`,
  `incant/utilities`) are Tony's in-flight work — leave them alone; don't bundle into commits.
