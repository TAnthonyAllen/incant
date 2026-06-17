# Recon — the old tok LLVM JIT (`OLDtawkDoNotTouch`)

*Tonto recon by Clod, 2026-06-17, for the Phase-JIT design hand-off to Clay.*
*Read-only archaeology of two files Tony pointed at. Nothing edited; these live*
*under `OLDtawkDoNotTouch/` (do-not-touch reference).*

## Scope
Two files examined:
- `OLDtawkDoNotTouch/Include/jit` (10 KB, dated 2017) — the TAWK **external
  declaration** file that wraps the LLVM C++ API so tok code can call it.
- `OLDtawkDoNotTouch/Tokf/Emitter.twk` (26 KB, 748 lines, dated Sep 2017) — a
  complete LLVM **IR emitter**: the half of tok that turned parsed expressions
  into LLVM IR and JIT-compiled them.

Third file (examined 2026-06-17, see its own section below):
`Include/UIjit.ext` (17 KB, 2018) — the **runtime environment surface** the JIT'd
code is allowed to call into.

## Headline
**This is not greenfield.** Every pillar of the design we sketched in the
chat — (1) op/target/argument → one typed LLVM instruction, (2) mutable
variables via `alloca`/`load`/`store`, (3) static type-driven instruction
selection, (4) operator-verbs each carrying an emit method — is **already
built and working** in `Emitter.twk`, circa LLVM ~3.8 (2017). Clay's job is a
**port + modernization of a proven reference**, not an invention. Clay's
earlier read ("a lot is probably still current") is correct, and the split is
clean — see "What rotted" vs "What's still current" below.

## What the old emitter already does (the proven design)

### 1. Mutable variables via memory — the alloca/load/store idiom
- `emitDeclare`: `pointer = CreateAlloca(jitType, jitter, "at"+name)` — one
  stack slot per local.
- `emitAssign`: `CreateStore(object.jitter, subject.pointer)` on write, then
  `jitter = CreateLoad(subject.pointer, name)` to read the value back.

This is exactly the "route mutables through memory" technique from Kaleidoscope
Ch. 7 that we discussed. Tony was already doing the **memory** side.

### 2. Static, type-driven instruction selection — the `opPlus` pattern, on the emit side
Every arithmetic emitter branches on `instance.getType()` and picks the typed op:
- `emitPlus`:  `float||double → CreateFAdd` else `CreateAdd`
- `emitMinus`/`emitMul`/`emitDiv`/`emitRem`: same float-vs-int fork
- `emitCompare`: full matrix — float (`CreateFCmpU*`) vs int (`CreateICmp*`),
  and **signed/unsigned aware** via `type.noSign` (`...SLT` vs `...ULT`).

This *is* the "read the field's type at emit time, emit the one matching arm"
plan. The `opPlus` runtime type-switch in `Instruct.rtn` and these `emit*`
methods are the same shape on two sides of the fence.

### 3. Operators carry an emit method — identical to incant's `Operators`/`gOp` model
`setEmitters()` binds each operator verb to its emitter:
```
verbs["+"].method = emitPlus;   verbs["<"].method = emitCompare;
verbs["="].method = emitAssign; verbs["?"].method = emitSelect;  ...
```
This is structurally **the same dispatch** incant uses today (an operator field
carries its method). So the LLVM tier's `emit*` methods are the natural
**`gOp`-analog**: where today an operator's method *runs* the op, the JIT tier's
method *emits* the op. The mapping from incant's `Operators` registry to a set
of emitters is a near-direct re-binding.

### 4. Casts — the count/double mixing we set aside is already solved
`emitCast` has the **full** conversion matrix, signed/unsigned- and size-aware:
`FPToSI/FPToUI`, `SIToFP/UIToFP`, `ZExt/Trunc`, `FPExt/FPTrunc`,
`IntToPtr/PtrToInt`. Tony said "no need to mix count and double" — fine, but if
that ever changes, the lowering already exists and is correct.

### 5. Control flow + string/pointer arithmetic
- Branch machinery present: `CreateCondBr`/`CreateBr`, `BasicBlock.Create`,
  `emitSelect` (ternary via `CreateSelect`). The branch problem the Bytecode arc
  fought through (`bcBR`/`bcBRZ`) has a worked LLVM analog here.
- **Pointer/string arithmetic is done as int math on `i8*`**, not GEP:
  `emitPlus`/`emitMinus` comment "assumes pointer arithmetic … jitter types set
  at i8*", and `emitQualify` does `PtrToInt → CreateAdd offset → IntToPtr` for
  field-offset addressing. This matches the string arm of `opPlus`
  (`gText + count` = pointer advance).

## What rotted — the modernization deltas (LLVM ~3.8 → current)
The damage is concentrated at the **engine/context/pointer seam**, exactly the
seam we identified in the design chat. The IR-construction logic is fine.

1. **Execution engine — biggest change.** Uses the legacy MCJIT-era
   `EngineBuilder` / `ExecutionEngine` / `getPointerToFunction(Function)` (see
   the `Emitter()` constructor and the `jit` ext). → Must move to **ORCv2
   `LLJIT`**: `LLJITBuilder().create()`, `addIRModule(ThreadSafeModule(M, Ctx))`,
   `lookup("name")`, `ExecutorAddr::toPtr<fn>()`. `getPointerToFunction` → `lookup`.

2. **Context.** `getGlobalContext()` (aliased as `getContext`) was **removed**
   in LLVM 4.0. → Own an `LLVMContext` and thread it through.

3. **Opaque pointers (default LLVM 15+) — touches several decls:**
   - Typed-pointer Type getters `getInt8PtrTy`/`getDoublePtrTy`/`getInt32PtrTy`…
     are gone. → everything is `ptr` (`PointerType::get` / `getUnqual`).
   - `CreateLoad(Value, name)` → now **`CreateLoad(Type, Value, name)`** — must
     pass the loaded type. The `jit` ext's `CreateLoad(Value l, String s)` is
     the old form; concrete update point.
   - `CreateCall(Value, …)` → now **`CreateCall(FunctionType, Value, args, name)`**
     — call needs the function type (opaque ptr can't carry it). Concrete update.
   - GEP (if introduced) needs an explicit element type.

4. **Pass manager.** Legacy `FunctionPassManager` (declared in `jit`, with
   `run(Function)`) → the **new PassManager + PassBuilder**. And mem2reg is now
   **`PromotePass`** — see the SSA finding below.

The `IRBuilder` `Create*` method *names* (CreateAdd, CreateFAdd, CreateICmp*,
CreateAlloca, CreateStore, CreateCondBr, CreatePHI, …) are **stable** across
versions — the bulk of `Emitter.twk` ports as-is once the seam above is fixed.

## The SSA finding — and it explains Tony's 7-years-ago memory
The code carries a **manual PHI machinery**: `JitData` has `jitPhi`/`ignorePhi`,
`CreatePHI`/`PHINode.addIncoming` are declared, and the `EQ` emitters all do
`if jitPhi ignorePhi = true;`. **No call to a mem2reg/PromotePass appears** in
the emitter (the `FunctionPassManager` is declared but I found no `.run` that
promotes allocas).

Reading: the old emitter used `alloca`/`load`/`store` for declared locals **but
hand-managed PHI nodes** for some merge points rather than running mem2reg. That
is almost certainly the source of Tony's recollection that *"LLVM didn't do SSA
for you"* — in this codebase he was placing phis by hand.

**Modernization opportunity:** add `PromotePass`/mem2reg to the pipeline and the
manual `jitPhi`/`ignorePhi` path can largely be **deleted**. The SSA pain in the
memory is real but self-inflicted-by-vintage, not a standing LLVM limitation.

## The one genuinely new translation (not just version-updating)
`Emitter.twk` emits from **tok's** AST — `Instance` / `Symbol` / `SymbolType`
(the C-like TAWK language). Incant's Phase-JIT must emit from **GroupItem**
op/target/argument IR instead. So the port has two axes:
- **LLVM-facing half** (the `Create*` calls, type selection, cast matrix,
  alloca/load/store) — reusable, just version-updated.
- **Frontend-facing half** (`instance.getType()`, `subject`/`object`,
  `symbol.jitter`, `getJITtype()`) — must be re-pointed from `Instance`/`Symbol`
  onto GroupItem fields and their type tags (count/double/string/op).

The monomorphic-by-enforcement decision from the chat makes the second axis
tractable: `getJITtype()` on a GroupItem field becomes a fixed lookup, and the
type-driven `emit*` selection works unchanged.

## Tar babies (flagged, not chased)
- **`emitIf` does `CreateXor(subject, object)`** — an XOR for an "if" condition
  is peculiar; looks like it handles only a narrow sub-case (maybe equality-ish
  test folding). Worth Clay's eye when control-flow emit is revisited.
- **Why both `alloca` *and* manual PHI?** (the SSA finding above) — confirm
  whether phis were only for loop/merge constructs the alloca path didn't cover,
  before deleting the `jitPhi` machinery.
- **`UIjit.ext` (17 KB)** — unexamined adjacent jit surface; characterize before
  assuming the GUI jit is unrelated.
- **`getDirect()` / `symbolJitStuff` / `jitStuff` (`JitData`)** — a parallel
  per-instance jit-state struct. Its role (and whether incant needs an analog
  hung off GroupItem) is unmapped.

## Bottom line for Clay
You're modernizing a working LLVM JIT, not designing one. The arithmetic/
compare/cast/alloca emit logic and the verb→emitter dispatch are sound and
~portable. The work is: (a) swap the legacy `ExecutionEngine`/`EngineBuilder`
JIT for **ORCv2 LLJIT**; (b) own an `LLVMContext` (no `getGlobalContext`);
(c) absorb **opaque-pointer** fallout (`CreateLoad`/`CreateCall` gain type args,
typed-ptr getters gone); (d) add **mem2reg/PromotePass** and retire the manual
`jitPhi` path; (e) re-point the emitters from tok `Instance`/`Symbol` onto
incant **GroupItem** op/target/argument IR.

---

## ADDENDUM (2026-06-17) — chosen direction supersedes "port Emitter.twk"
Tony's call after the recon: **do NOT port `Emitter.twk` wholesale — that's
Plan B.** Plan A is to make **the incant ops themselves emit LLVM IR**, routed
through a *generating-like gate*, instead of routing through a separate
AST-walking emitter or through bytecode.

Two corrections/decisions that reshape the recon:

1. **`&target` is gone.** Incant ops no longer take `&target` by reference — they
   take `target` by value (changed ~2026-06-10). This kills the mem2reg-aliasing
   worry: no address-taken alloca, so slots promote cleanly. The "which fields
   reach register SSA" caveat from the design chat is moot.

2. **No bytecode on the JIT path.** This **supersedes CLAUDE.md's** "LLVM IR
   (Phase JIT) will be generated *from* bytecode." IR now comes **straight from
   the ops/BlocK**, not from the `bcLIST`. Bytecode and JIT become *parallel,
   independent* lowerings of the same cached BlocK — not a pipeline. (Flag the
   CLAUDE.md line for revision.)

### What Plan A makes of this recon
`Emitter.twk` stops being a port target and becomes a **lookup table**: "given
this op + these operand types, call this `IRBuilder` method." That content
(arithmetic float/int fork, the `emitCompare` signed/unsigned matrix, the
`emitCast` conversions, the `emitDeclare`/`emitAssign` alloca/store/load shapes)
gets **transplanted into the incant ops** (or their emit sub-attribute), not
linked in as a separate module. The recon still pays off — just as a reference,
not a build dependency.

### The shape of Plan A (Kaleidoscope's `codegen()` pattern)
"Run the action to emit IR" is abstract interpretation: `processCode` walks the
action's BlocK in **jit mode**, and each node, instead of *computing* a value,
*emits an instruction and yields the resulting LLVM `Value`*. The data flowing
through evaluation becomes LLVM `Value` handles instead of concrete data. This is
exactly Kaleidoscope's `codegen()` ("execute the AST; each node returns an
`llvm::Value*`"). First run compiles → caches the jitted function pointer on the
action (alongside the already-cached BlocK); later runs fire native code.

### Design chunks Clay can chomp on
- **It's not only the operators — the leaves invert too.** Under jit mode a
  literal must emit `ConstantInt`/`ConstantFP`, a field-read must emit `CreateLoad`
  (or yield the field's current SSA value), an assignment must emit `CreateStore`.
  The "emit half" extends *below* the arithmetic ops — `emitDeclare`/`emitAssign`/
  `emitQualify` in this file are precisely that leaf layer.
- **Each field needs a transient jit-Value slot during emission** — "the LLVM
  `Value` representing this field right now." That is the **GroupItem analog of
  `JitData`** (jitter/pointer/jitType), the struct this recon flagged as unmapped.
  Now it has a home: a transient field on GroupItem live only during emission.
- **Control flow is the hard part — "not much change" breaks down here.**
  Straight-line arithmetic is a clean mode-switch. But `if`/`for`/`while` *cannot
  take a path* in emit mode — they must emit **both arms into separate basic
  blocks** with `CreateCondBr`/`CreateBr` and emit each body once. So the
  control-flow handlers need a jit mode that fundamentally inverts their runtime
  behavior (execute one path → emit all paths). The conceptual work from the
  Bytecode branch arc (`bcBR`/`bcBRZ`, block/label structure) **transfers** even
  though the bytecode itself doesn't; `emitIf`/`emitSelect` + the `CreateCondBr`/
  `BasicBlock` decls here are the reference.
- **The gate: sub-attribute vs parallel registry.** Two homes for the emit
  behavior: (a) hang it off each op as a **sub-attribute** (the incant
  "second invokable behavior" idiom — most homoiconic), or (b) a **parallel
  emitter registry** keyed by op, mirroring the existing `generator` registry
  (`generatE`/`runGenerated`). Tony leans toward the gate/registry framing
  ("a generating-like gate"). Clay's call.
- **Wiring the jitted method back into the runtime** (so incant fires native code
  when the action runs next) — Tony explicitly leaves this for Clay.

## `UIjit.ext` — the third leg: the runtime surface the JIT can call
The two files above answer "how do I *build* IR" (`jit` = LLVM API wrapper) and
"what IR does each op emit" (`Emitter.twk`). `UIjit.ext` answers the **third**
question, and it's the one the design chat kept circling as the *substantive*
work: **what host functions/methods may the jitted code call, and with what
types?** Its own header says it: *"This provides the external environment visible
to the jit. Only selected global methods and GroupItem methods are visible."*

That is the **symbol-resolution / runtime-interface contract** in 2017 form. In
ORCv2 terms this list becomes the `absoluteSymbols` / `DynamicLibrarySearchGenerator`
allow-list — the set of host symbols the JIT resolves IR `call`s against. The
op-as-method-pointer Tier-3 fallback we discussed needs exactly this: the *types*
of the runtime functions an emitted `CreateCall` targets.

### The high-value extracts (these survive; most of the file doesn't)
- **The GroupItem data union + type-tag enum** (lines ~244–263): the union
  `gCount`(int) / `gNumber`(double) / `gText`(String) / `gGroup` / `gPointer` /
  `gItem` / `gMap` / `gRegex`, gated by `data:4[isCount isGroup isItem hasMap
  isNumber isString isDate isPointer isRegex]`. **This enum is the monomorphic
  gate's type vocabulary, already enumerated** — the count/double/string the JIT
  targets are right here, plus the wider set the gate must reject as not-jittable.
- **The `op` type's concrete signatures** (lines ~253–256): GroupItem carries a
  method-pointer union — `void &method(GroupItem)` *or* `GroupItem &methodRG(GroupItem)`
  — selected by the `methodType:3[returnsVoid returnsGroupItem]` flag. This **is**
  the "op = pointer to an incant method, signature in GroupBody" type Tony named:
  two signatures (void-returning, GroupItem-returning), already nailed down. The
  Tier-3 `CreateCall` through an op pointer uses one of these two function types.
- **The GroupItem method ABI** (the `get`/`getAttribute`/`setText`/`setNumber`/
  `addGroup`/`locate`/… surface + the `[]` `+=` `/` `%` operator overloads): the
  catalogue of runtime entry points jitted code would call. The *list* is the
  reference; the *signatures* need re-checking (see stale notes).

### Caveats — it's GUI-vintage and partly stale
- **It's the *GUI* jit surface.** It imports the whole window/draw world —
  `Layout`, `Details`, `Stylish`, `ParseXML`, `BitMAP`, `Source`, `KeyTable`,
  `Frame`, `Font`. For incant *action* jitting, the relevant subset is just
  **GroupItem + GroupRegistry + StringRoutines + the global GroupItem helpers**;
  the GUI classes are noise to prune.
- **Stale against current incant:** the `new → itemFactory` alias (line ~450)
  contradicts CLAUDE.md's "itemFactory path is gone; constructors are the only
  path"; and the by-ref `&` method sigs (`nextAttribute(GroupItem *&group)`,
  `setMethod(void &m(GroupItem))`) predate the `&target`-removal change. So like
  `jit`, this is a reference for the *idea and the GroupItem ABI*, not a file to
  relink.
- **`Bwana` is a real class here** (lines ~103–120) — a GUI-era controller/
  environment object (actions, controller, fontManager, window, the
  descriptions/properties/types registries, the windows KeyTable). Worth noting
  given Tony's "the bwana decides type stability" framing: the authority object
  has precedent in the architecture, though this incarnation is GUI-bound.

### What `UIjit.ext` tells the design
The "runtime-interface contract" I flagged as the real remaining work **already
has a 2017 draft**. For Plan A, the analog is: the set of GroupItem methods /
runtime helpers the emitting ops may `CreateCall`, registered with ORC so the
calls resolve. `UIjit.ext` is the precedent for *what goes in that set and its
type shapes* — pruned to the non-GUI subset and refreshed for the current
GroupItem ABI (constructors-not-itemFactory, by-value targets).

### When Plan B (port Emitter.twk) comes back
If folding emit-mode into the live ops proves to entangle the interpreter path
badly (e.g. control-flow inversion can't co-exist cleanly with the executing
handlers), fall back to a separate emitter that walks the same BlocK — i.e.
`Emitter.twk` modernized per the deltas above, re-pointed onto GroupItems.
