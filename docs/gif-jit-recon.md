# gIF JIT — Recon Brief (2026-06-25)

*Read-only seed for the Clay/Tony gIF design conversation. No code touched. Written
right after unary minus landed (commit `7f3367e`), which cleared the negative-value
prerequisite. The three items Fearless asked for: bytecode block topology, nesting
wrinkles, drafted gIF instructions.*

---

## 1. Bytecode block topology — the proven model to mirror

The gIF **bytecode** emitter is live and correct (`incant/generate`, `gIF` handler
~L121–163). Its block/label shape is exactly what the LLVM then/else/end basic blocks
should map onto:

```
gXpress(condition)                       ; push condition, leave i1/flag on the path
bcBRZ -> elseLabel   (if else present)   ; false -> jump to else
bcBRZ -> endLabel    (if no else)        ; false -> jump past the if
<then arm>                               ; gXpress(st.revisedList) | runGenerated(st)
bcBR  -> endLabel    (if else present)   ; then done -> skip else
elseLabel:           (if else present)
<else arm>                               ; gXpress(el.revisedList) | runGenerated(el)
endLabel:
```

- **Labels are uniquely minted**: `++labelIndex; labelName = string $"bcLabel" labelIndex;`
  then `endLabel := new(labelName)`. The `:=` is load-bearing (keeps the `bcLabelN` tag;
  a plain `=` would re-tag to "endLabel" — bear-trap #1).
- **No shared `dst` variable** — labels are emitted directly; an earlier indirection
  through one `:=`-bound dst clobbered prior labels (`:=` aliases).
- **LLVM mapping**: `bcBRZ` → `CreateCondBr(cond, contBB, elseBB/endBB)`; `bcBR` →
  `CreateBr(endBB)`; each `bcLabelN` → a `BasicBlock`. The condition i1 already exists —
  `jitEmitCompare` produces it today (proven Phase 1).

## 2. Nesting wrinkles — what CreateCondBr must account for

- **`aCTionIF` is dispatch-by-gMethod** (`ruleActions.rtn:499`): condition → `ExpressioN.gMethod`,
  then-arm → `StatemenT.gMethod`, else-arm → `ElsE.gMethod`. Nesting is *structural* —
  a nested `if` in a then/else arm is just another `StatemenT` whose gMethod is gIF again.
- **The emitter already recurses**: then/else arms descend via `st["revisedList"]` →
  `gXpress` for simple expressions, **falling back to `runGenerated(st)` for compound /
  nested arms** (block or inner if). So nesting "just works" in bytecode because labels
  are globally unique.
- **`labelIndex` is a single global monotonic counter** (`incant/setup:174`, in `pROPERTIEs`),
  shared across *all* ifs/fors/whiles in an action and across nesting depth. That's why
  inner-if labels never collide with outer-if labels.
- **The wrinkle for LLVM**: block *termination + continuation threading*. In bytecode a
  label is just a jump target; fall-through is implicit and a block can be "re-entered" by
  position. In LLVM every BasicBlock **must have exactly one terminator**, and an inner if's
  `endBB` must be wired to flow into the **outer** arm's continuation — there is no implicit
  fall-through across the recursion boundary. The emit-side question: who owns the "current
  continuation block" so a nested gIF knows where its `endBB` branches to. (The bytecode
  model hides this; the LLVM model forces it explicit.)

## 3. Drafted gIF instructions — the real state + the key simplifier

**Reality check:** jit.md says "the gIF instructions are drafted and ready to hand off,"
but there is **no concrete code draft** in `jitEmitters.rtn` — the "draft" is design-doc
guidance (`jit-design.md`, `docs/llvm-jit-recon.md`). What exists in code:

- **The driver is single-block today** (`jitEmitters.rtn:320–352`, `jitRunAction`): one
  `"entry"` BasicBlock, `SetInsertPoint` once, ops emit into it via `gJitBuilder`, then
  `CreateRet(gJitResult)`. gIF is the **first multi-block emit** — it must `BasicBlock::Create`
  then/else/end blocks and `SetInsertPoint` to steer subsequent ops into the right block.
  The gate-emit model already keys off "current insert point," so gIF *moves the insert point*;
  it doesn't need a new dispatch mechanism.
- **THE KEY SIMPLIFIER — no manual phi nodes.** `jit-design.md:45` is explicit: *"SSA via
  alloca/load/store + PromotePass. Never write a phi node."* Mutable fields are `alloca`
  slots (the frame model); each arm `CreateStore`s into the field's slot; after the whole
  function is built, `PromotePass` (mem2reg) inserts all phi nodes at merge points
  automatically. This **sidesteps the historically hard part** of control-flow SSA. The old
  tok JIT carried **manual `jitPhi`/`ignorePhi` machinery** (`llvm-jit-recon.md:111–123`) —
  that path is **deliberately NOT ported**; alloca+PromotePass replaces it. *Open verify
  (recon flagged): confirm PromotePass is actually wired into the pass pipeline before
  relying on it — the old code hand-managed phis because no mem2reg call appeared.*
- **Reference prior art**: `llvm-jit-recon.md:212–220` — control flow "cannot take a path
  in emit mode; it must emit **both arms** into separate basic blocks and emit each body
  once," fundamentally inverting the runtime handler's behavior (execute one path → emit all
  paths). The old `emitIf`/`emitSelect` + `CreateCondBr`/`BasicBlock` decls are the reference.

---

## Suggested design questions for the conversation
1. **Continuation ownership** (the nesting wrinkle): how does a nested gIF learn its `endBB`'s
   successor — a JIT-context "current continuation" stack, or pass-down? Bytecode dodges this;
   LLVM forces it.
2. **PromotePass wiring**: confirm mem2reg runs, so arms can just `CreateStore` to field
   slots and let LLVM build phis — vs any need to retain hand-phi for a case.
3. **Where the condition i1 comes from in nested/compound conditions**: `jitEmitCompare`
   handles a single compare; a boolean-composite condition (`a < 0 and b > 0`) is the
   chained-operand gate guard (still a Phase-1 latent bear, jit.md). Does gIF's first cut
   restrict to single-compare conditions?
4. **Emit-both-arms vs the gate model**: the per-op gates emit into the current block; gIF is
   a *statement-level* handler (`gIF`, not an opMethod) that must create blocks and re-point
   the builder. Confirm gIF lives at the statement-generator layer (like the bytecode `gIF`),
   not as an opMethod gate.

## Files (read-only references)
- `incant/generate` — `gIF` bytecode emitter (~L121), `gFOR`/`gWhilE` (same label pattern).
- `ruleActions.rtn:499` — `aCTionIF` (the runtime handler gIF inverts).
- `jitEmitters.rtn:320` — `jitRunAction` driver (single-block today; gIF extends it).
- `jit-design.md:45,232` — alloca/PromotePass SSA model; frame prologue.
- `llvm-jit-recon.md:111,212` — old manual-phi machinery (not ported) + control-flow reference.
- `docs/jit.md` — Phase 2 section (blocker now cleared); `jitEmitCompare` i1 (proven).

---

# Session 2026-06-25 PM — gIF drive findings + DECISION: parallel JIT walk

This session probed how to actually *drive* gIF emission and reversed two wrong turns.
Recorded so the fresh session starts from the conclusion, not the dead ends.

## What we learned (empirical, via `testing(jitGIF)` → `jitRunAction`)
- **`aCTionIF` is NOT on the JIT path.** A diagnostic `printf` at its top never fired under
  jitting (binary verified fresh). The deferred `IF` does not dispatch to `aCTionIF` in
  generate/JIT mode — the parse labels the node and the *generator* handles it. So the
  "Option A — gate in `aCTionIF`" idea was wrong; the single-arm test that seemed to confirm it
  was a half-wired-state artifact.
- **Deferred → `gIF` dispatch lives in `runGenerated`** (`incant/generate:46`), driven only by
  **`generateCode`** → `runAction(BlocK, generatE)` → `gBlocK` → `runGenerated`. The **bytecode**
  path. `jitRunAction` does **only `processCode`** (straight-line emit-during-parse) and never
  reaches `runGenerated`/`gIF`. So control flow has no JIT dispatch today.
- The `jitGIF` test's TRUE→99 / FALSE→"no result" was a `processCode`-parse artifact, **not** a
  working branch (no `CreateCondBr`). Declared a red herring; not chased.

## DECISION (Tony + Clay + Fearless): a PARALLEL, JIT-OWNED walk
Do **not** dual-mode the bytecode generator. Build a parallel walk:
- **`jitGeneratE` / `jitRunGenerated`** — modeled on `generatE`/`runGenerated`
  (`incant/generate:46,233`) but JIT-owned, with **LLVM-native handlers from day one**. The
  bytecode pipeline stays pure (no `if jitting` contamination, no inherited bytecode assumptions).
- **`jitRunAction` drives the JIT walk** for deferred / control-flow nodes; **straight-line ops
  stay on the emit-during-parse path** (the proven 25-POP path, untouched). The walk picks up the
  deferred nodes `processCode` leaves on the table.
- The bytecode work was the education: `jitRunGenerated` *clones the pattern* — don't bend the
  original. `gIF`'s bytecode topology (bcBRZ/bcBR/label, §1 above) is the structural template;
  the JIT handler emits BasicBlocks + `CreateCondBr` instead.

## First step next session
Read `runGenerated`/`generatE` carefully, understand the dispatch shape, then build
`jitRunGenerated` as a clean parallel (JIT-owned dispatch table → LLVM-native handlers).
`jitRunAction` invokes it for control-flow nodes. Then wire the `gIF` handler first (single
compare, one then-arm, no else — prove `entry → header → thenBB → endBB`), using the emitter
sketch below.

## Reusable: the `jitEmitGIF` emitter sketch (validated shape, reverted from the tree)
The LLVM emission is drive-independent — `jitRunGenerated`'s gIF handler can call this. It
*compiled and ran*; only its *drive* (the `aCTionIF` gate) was wrong. PromotePass is already
wired (`jitRunAction`), so field-slot stores in the arms become phis automatically. Three-block
topology, both arms emitted unconditionally, runtime `CreateCondBr`:

```c
// extern GroupItem jitEmitGIF(GroupItem condition, GroupItem thenArm, GroupItem elseArm)
llvm::IRBuilder<> *b = gJitBuilder;
llvm::LLVMContext &ctx = b->getContext();
llvm::Function *fn = b->GetInsertBlock()->getParent();
// 1. condition into current (header) block -> i1 left in gJitResult; capture it now
if (condition->groupBody->gMethod) condition->groupBody->gMethod(condition);
llvm::Value *cond = gJitResult;
if (cond && !cond->getType()->isIntegerTy(1))
    cond = b->CreateICmpNE(cond, llvm::ConstantInt::get(cond->getType(),0), "ifcond");
// 2. blocks (no else in first POP)
llvm::BasicBlock *thenBB = llvm::BasicBlock::Create(ctx, "then", fn);
llvm::BasicBlock *endBB  = llvm::BasicBlock::Create(ctx, "ifend", fn);
// 3. RUNTIME branch — both arms emitted regardless of emit-time condition value
b->CreateCondBr(cond, thenBB, endBB);
// 4. then-arm into thenBB; unconditional back-edge
b->SetInsertPoint(thenBB);
if (thenArm->groupBody->gMethod) thenArm->groupBody->gMethod(thenArm);
b->CreateBr(endBB);
// 5. continuation = endBB (pass-down model; nested gIF mints its own fresh endBB)
b->SetInsertPoint(endBB);
// 6. cap gJitResult with the header-dominating i1 so the driver's CreateRet is valid
gJitResult = cond;
```
Key gotcha banked: `gMethod` is a function pointer on `groupBody` (`x->groupBody->gMethod(x)`),
not a direct GroupItem member — matters inside raw-C++ `-% %-` blocks (tok doesn't translate there).

## Tree state at handoff
Exploratory code reverted to the committed green baseline (`13e322e`): unary minus + PromotePass
in place, 25-POP battery + oneTest(26) + jsonTest green. `jitEmitGIF`, its `groups.ext` prototype,
the `aCTionIF` gate, and the `jitGIF` fixture/driver were all reverted — preserved here for
resurrection. Nothing gIF-specific is wired in the tree.
