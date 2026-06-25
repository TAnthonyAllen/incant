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
