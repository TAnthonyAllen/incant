# Incant Phase JIT — Implementation Design
*Clay, 2026-06-17. For Clod implementation. Self-contained brief.*

---

## What This Is

A phased implementation plan for the incant Phase JIT. The goal is a working
end-to-end JIT pipeline for straight-line arithmetic actions first, then control
flow, then the full runtime surface. GUI work and multi-processing inherit this
as foundation.

This document is the codegen-backend design. The calling-convention and frame
model are fully specified in `jit.md` — read that first. This document does not
repeat what `jit.md` says; it extends it with the LLVM machinery and incant
wiring.

Reference archaeology: `OLDtawkDoNotTouch/Tokf/Emitter.twk` (2017 tok LLVM
emitter) and `OLDtawkDoNotTouch/Include/UIjit.ext` (2017 runtime surface).
Do not port these — treat them as a lookup table for `IRBuilder` call shapes
and the runtime ABI precedent. The recon doc (`llvm-jit-recon.md`) is the
guide to what's current vs. rotted.

---

## Architectural Decisions (Locked)

**1. Emit behavior hangs off `Operators` as a `jitMethod` attribute.**
Same pattern as `operateMethod` (runtime) and `interpretMethod` (bytecode).
`jitMethod=emitPlus` alongside `operateMethod=opPlus interpretMethod=runPlus`.
Operators not yet jit-capable simply have no `jitMethod` — the gate falls back
to interpreter for those ops. No parallel registry needed.

**2. Action handlers get a `jitting` gate, same idiom as `generating`.**
`aCTionExpressioN`, `aCTionIF`, `aCTionFOR`, `aCTionWHILE` each grow an
`if jitting { ... }` branch. Straight-line arithmetic goes via the expression
handler; control flow goes via its own handler. The walk is the same BlocK
walk; what flows through it changes.

**3. Slot allocation: heap via BDWGC.** Per `jit.md` open-question resolution:
heap-allocate slot arrays from BDWGC (Boehm GC, already in the runtime). Stack
is the later optimization earned by non-escape analysis. Don't implement stack
allocation now.

**4. SSA via alloca/load/store + PromotePass.** Never write a phi node.
Every mutable field gets one `alloca` in the function entry block. Reads →
`CreateLoad`, writes → `CreateStore`. Run `PromotePass` (mem2reg) after the
function body is complete. LLVM places all phi nodes. The old manual
`jitPhi`/`ignorePhi` machinery from `Emitter.twk` is not ported — it's
replaced entirely by this.

**5. Monomorphic-by-enforcement gate.** Before emitting an action, walk its
field list. Every field must have a determinate, stable type (count/number/
string — the jittable set). Any field with an unjittable or indeterminate type
→ the whole action falls back to the interpreter. This is a per-action yes/no
check, not a per-op fallback. The interpreter is the fallback granularity.

**6. No bytecode on the JIT path.** IR comes straight from the BlocK/ops,
not from `bcLIST`. Bytecode and JIT are parallel independent lowerings of the
same cached BlocK. `jit.md`'s statement "body translation is a remapping of
bytecode operations" describes the *conceptual* relationship — the slot-indexed
field references parallel what bytecode does — not a pipeline dependency.
**Flag in `CLAUDE.md`:** the line "LLVM IR generated from bytecode" is
superseded and should be updated.

---

## LLVM Version and API Shape

**Locked: LLVM 22.1.7**, arm64, installed at `/opt/homebrew/Cellar/llvm/22.1.7_1`
via arm64 Homebrew (`/opt/homebrew`). Link with `-lLLVM-22` (one monolithic
shared lib). All API assumptions in this document are correct for this version.

### Build flags (from `llvm-config --cxxflags / --ldflags / --libs`)

```
Headers:   -I/opt/homebrew/Cellar/llvm/22.1.7_1/include
Lib path:  -L/opt/homebrew/Cellar/llvm/22.1.7_1/lib
Link:      -lLLVM-22
LD flags:  -Wl,-search_paths_first -Wl,-headerpad_max_install_names
CXX flags: -std=c++17 -stdlib=libc++
           -D__STDC_CONSTANT_MACROS -D__STDC_FORMAT_MACROS
           -D__STDC_LIMIT_MACROS -fno-exceptions
```

### Xcode pbxproj wiring required (Phase 1 task — do this before any LLVM C++)

The current project has C++ standard mismatches that will hard-fail against
LLVM 22 headers:

- Two configs have `CLANG_CXX_LANGUAGE_STANDARD = "c++0x"` (C++11 alias) —
  **must change to `c++17`**. LLVM 22 headers will not compile under C++11.
- Remaining configs are `"compiler-default"` — set explicitly to `c++17`.
- `CLANG_CXX_LIBRARY = "compiler-default"` everywhere — pin to `libc++`
  (LLVM 22 was built with libc++; macOS default is libc++ so likely fine, but
  explicit is better).
- `OTHER_CPLUSPLUSFLAGS` already carries `-D__STDC_LIMIT_MACROS
  -D__STDC_CONSTANT_MACROS` but is missing `-D__STDC_FORMAT_MACROS` — add it.
- `-fno-exceptions`: LLVM 22 libs were built without exceptions. Flag for
  Tony's decision — match it on LLVM-including TUs, or confirm incant's
  exception usage doesn't clash. Not a blocker for Phase 1 if incant TUs don't
  throw through LLVM code.
- Remove all stale `~/Web/llvm9.0` paths (already shitcanned from disk;
  remove from pbxproj too).

### API surface (LLVM 22 — these forms are correct, use them verbatim)

- **Execution engine**: ORCv2 `LLJITBuilder().create()` /
  `addIRModule(ThreadSafeModule(std::move(M), std::move(Ctx)))` /
  `lookup("name")` / `sym->getAddress().toPtr<FnType>()`.
- **Context**: own a `LLVMContext` per action; no `getGlobalContext()`.
- **Pointers**: opaque — no `getInt8PtrTy` etc. Use
  `PointerType::getUnqual(Ctx)` for `ptr`. `CreateLoad(Type, Value, name)` —
  type arg is mandatory. `CreateCall(FunctionType, Value, args, name)` —
  function type arg is mandatory.
- **Pass manager**: new `PassManager` + `PassBuilder`. mem2reg = `PromotePass`.
  Run after body emission, before `verifyFunction`.

`IRBuilder` `Create*` method names (CreateAdd, CreateFAdd, CreateICmp*,
CreateAlloca, CreateStore, CreateCondBr, CreateBr, CreateRet, …) are stable —
the bulk of `Emitter.twk`'s arithmetic logic ports as-is.

---

## The Transient JIT State

During emission of a single action, each participating GroupItem field needs a
small amount of JIT-specific state:

```
jitSlot:    llvm::Value*   // the alloca for this field (set in prologue)
jitValue:   llvm::Value*   // the current SSA value (updated by loads/stores)
jitType:    llvm::Type*    // the LLVM type for this field (set at gate check)
```

**Where it lives:** A side table (e.g. `std::unordered_map<GroupItem*, JitFieldState>`)
keyed by GroupItem pointer, allocated for the duration of one action's emission
and discarded after. This keeps GroupItem clean — no permanent JIT pollution.
The side table is passed through the emission context (see JitContext below).

This is the GroupItem analog of `JitData` / `jitStuff` from `Emitter.twk`.
Same idea, cleaner location.

---

## The JIT Context Object

A `JitContext` struct (C++ side, threaded through all emit calls) carries
everything needed during one action's emission:

```cpp
struct JitContext {
    llvm::LLVMContext&              ctx;
    llvm::IRBuilder<>&              builder;
    llvm::Function*                 fn;          // the function being built
    llvm::BasicBlock*               entryBB;     // entry block (for allocas)
    std::unordered_map<GroupItem*,
        JitFieldState>              fields;      // transient per-field state
    GroupItem*                      argument;    // the action's argument handle
    bool                            ok;          // set false on any emit error
};
```

`LLVMContext` and `Module` are **per-action**: allocated fresh for each action
compilation, then moved into `ThreadSafeModule` and handed to ORC
(`addIRModule(ThreadSafeModule(std::move(M), std::move(Ctx)))`). The context
moves into the TSM and is owned by ORC thereafter. A new context is created for
the next action. The `LLJITBuilder` instance itself is long-lived (per-runtime,
created once at startup).

---

## Type Mapping (the Monomorphic Gate's Vocabulary)

From `UIjit.ext` lines ~244–263, confirmed against current GroupItem:

| incant type flag | C++ data member | LLVM type          | Jittable |
|------------------|-----------------|--------------------|----------|
| `isCOUNT`        | `gCount` (int)  | `i32`              | yes      |
| `isNUMBER`       | `gNumber` (double) | `double`        | yes      |
| `isSTRING`/`isTOKEN` | `gText` (String) | `ptr` (i8*)   | yes, with caveats (see below) |
| `isGROUP`/`isOP`/`isITEM`/etc. | — | — | no — interpreter fallback |

String arithmetic (`gText + count` = pointer advance) emits as int math on
`ptr` cast to integer — the `emitPlus` pattern from `Emitter.twk` (PtrToInt →
CreateAdd → IntToPtr). String ops with bounds guards emit control flow (a
compare + conditional branch to an error block). String jitting is Phase 3;
for Phase 1 and 2, `isSTRING` fields cause the gate to fall back.

**Unary ops**: `opPlusPlus` etc. take `result` (the target itself, no separate
argument). The emit shape is: load the slot, emit the typed increment (add i32
1 or fadd double 1.0), store back. Same alloca/load/op/store pattern.

---

## Phase 1 — Straight-Line Arithmetic (The Pipeline Proof)

Goal: one trivially-simple action with count/number fields and arithmetic ops
compiles, runs, and produces the right answer. No control flow. No string ops.
No callbacks into the runtime beyond field reads and writes.

### 1a. One-time LLVM process setup (call once at incant startup)

```cpp
llvm::InitializeNativeTarget();
llvm::InitializeNativeTargetAsmPrinter();
llvm::InitializeNativeTargetAsmParser();
```

### 1b. The monomorphic gate

New function: `bool isJittable(GroupItem* action)`

Walk `action`'s field list. For each field:
- If `isCOUNT` or `isNUMBER` → ok (Phase 1 jittable set).
- Anything else → return false (interpreter fallback).

Returns true only if every field in the schema is in the jittable set.
This is the entire gate for Phase 1. String and op-pointer fields expand
the gate in later phases.

### 1c. Frame prologue

Two levels operate here — keep them distinct:

**C++ level (call-site, before entering the jitted function):**
Allocate a `GroupItem*` slot array from BDWGC heap — one slot per field list
entry. Walk the field list, copy each GroupItem pointer into its slot. This
array is passed as the first argument to the jitted function. It is the calling
convention per `jit.md`.

**LLVM level (emitted IR, function entry block `entryBB`):**
For each field in the schema, emit one `CreateAlloca` of the field's native
LLVM type (`i32` for `isCOUNT`, `double` for `isNUMBER`). Store as `jitSlot`
in the side table.

Then emit the **unboxing prologue** — for each field, emit IR that:
1. Loads the `GroupItem*` for that field from the incoming slot array argument
   (a `CreateLoad` of `ptr` type at the appropriate index offset).
2. Reads the native value from the GroupItem's typed data member — `gCount` or
   `gNumber` at its known struct offset — via a `CreateLoad` of the native type.
3. Stores that native value into the field's `alloca` slot via `CreateStore`.

After `PromotePass` these entry-block stores become the initial values feeding
SSA register names. The function body then operates entirely on native values
— no GroupItem pointer indirection during arithmetic.

### 1d. Operator emit methods — the `jitMethod` attribute

Add `jitMethod` to the Operators define. Initially just arithmetic:

```
'+'    operateMethod=opPlus  interpretMethod=runPlus  jitMethod=emitPlus;
'-'    operateMethod=opMinus interpretMethod=runMinus jitMethod=emitMinus;
'*'    operateMethod=opMultiply interpretMethod=runMultiply jitMethod=emitMultiply;
'='    assign operateMethod=opAssign jitMethod=emitAssign;
```

**NOTE — divide/remainder glyphs TBD:** The Operators define shows `%` mapped
to `opDiv`. This is either (a) incant's deliberate choice of `%` for divide
(non-standard but valid — confirm with Tony), or (b) a misassignment. The
standard `/` glyph for divide is absent from the Operators define entirely.
Clod: before adding `jitMethod` to divide/remainder ops, confirm with Tony
which glyphs are actually in use and what `opDiv` does. Do not assume `%` =
remainder (it may be divide). Add the correct `jitMethod=emitDiv` /
`jitMethod=emitRem` once the glyphs are confirmed.

Each `emitX` is a C++ extern function with signature:
```cpp
extern llvm::Value* emitPlus(GroupItem op, GroupItem target,
                              GroupItem argument, JitContext& jc);
```

`emitPlus` implementation (the `opPlus` pattern, emit side):
```cpp
llvm::Value* emitPlus(GroupItem op, GroupItem target,
                       GroupItem argument, JitContext& jc) {
    auto& tState = jc.fields[&target];
    auto& aState = jc.fields[&argument];
    llvm::Value* tVal = jc.builder.CreateLoad(tState.jitType,
                                               tState.jitSlot, "t");
    llvm::Value* aVal = jc.builder.CreateLoad(aState.jitType,
                                               aState.jitSlot, "a");
    llvm::Value* result;
    if (tState.jitType == llvm::Type::getDoubleTy(jc.ctx))
        result = jc.builder.CreateFAdd(tVal, aVal, "add");
    else
        result = jc.builder.CreateAdd(tVal, aVal, "add");
    // Store result back to target slot
    jc.builder.CreateStore(result, tState.jitSlot);
    return result;
}
```

`emitAssign` stores `aVal` into `tState.jitSlot` directly (no arithmetic).

Unary `emitPlusPlus`:
```cpp
llvm::Value* emitPlusPlus(GroupItem op, GroupItem target,
                            JitContext& jc) {
    auto& tState = jc.fields[&target];
    llvm::Value* tVal = jc.builder.CreateLoad(tState.jitType,
                                               tState.jitSlot, "t");
    llvm::Value* one;
    llvm::Value* result;
    if (tState.jitType == llvm::Type::getDoubleTy(jc.ctx)) {
        one    = llvm::ConstantFP::get(jc.ctx, llvm::APFloat(1.0));
        result = jc.builder.CreateFAdd(tVal, one, "inc");
    } else {
        one    = llvm::ConstantInt::get(tState.jitType, 1);
        result = jc.builder.CreateAdd(tVal, one, "inc");
    }
    jc.builder.CreateStore(result, tState.jitSlot);
    return result;
}
```

### 1e. `aCTionExpressioN` jitting gate

The generating gate in `aCTionExpressioN` is the model. Add:

```
if jitting {
    // Walk xpList right-to-left (same state machine as generating path).
    // For each completed op/target/arg triple:
    //   - look up op.jitMethod
    //   - if found: call emitX(op, target, arg, jc) → Value*
    //   - if not found: set jc.ok = false → whole action falls back
    // Literals: emit ConstantInt/ConstantFP directly.
    // Field reads: emit CreateLoad from the field's jitSlot.
    return xpList;  // result is in LLVM IR; xpList itself is consumed
}
```

The `if jitting` branch mirrors the `if generating` branch structurally: same
walk direction, same op/target/arg identification. What differs is the output —
instead of appending to a `revisedList`, we emit LLVM instructions and advance
`JitContext`.

### 1f. Literals in emit mode

A bare literal (count value, number value) in the expression must emit a
constant, not load from a slot. In the jitting walk, when a token is a literal
(not a field reference):

```cpp
if (token.isCOUNT)
    result = llvm::ConstantInt::get(llvm::Type::getInt32Ty(jc.ctx),
                                     token.count);
else if (token.isNUMBER)
    result = llvm::ConstantFP::get(jc.ctx, llvm::APFloat(token.number));
```

Push this `result` value as the "current value" of that token position in the
emission walk (the analog of the stack value in a bytecode evaluator).

### 1g. Function epilogue and compilation

After the body is emitted:

1. **Emit the in-IR rebox epilogue.** For each field, load the final native
   value from its `alloca` slot and store it back to the GroupItem's typed data
   member (`gCount`/`gNumber` at the known struct offset) via `CreateStore`
   through the GroupItem pointer. This is the reverse of the unboxing prologue
   in §1c. Globals get their writeback here — deferred to epilogue as documented
   in `jit.md`.

2. **Emit the return.** The function returns a `GroupItem*` — not a raw native
   value. Load the result field's GroupItem pointer from the slot array, store
   the reboxed native value into it (already done in step 1), then
   `CreateRet` of that `GroupItem*`. For void-style actions, `CreateRet` of
   the argument GroupItem pointer per `jit.md`'s method signature.

3. `verifyFunction(*fn)` — catch IR errors before JIT.

4. Run `PromotePass` (mem2reg) on the function.

5. `JIT->addIRModule(ThreadSafeModule(std::move(M), std::move(Ctx)))`.
   Context and Module are moved into the TSM; ORC owns them from here.

6. `auto sym = JIT->lookup("actionName")`.

7. Cast and cache: `action.jittedFn = sym->getAddress().toPtr<JittedFnType>()`.

`JittedFnType` is the C++ function pointer type matching the action method
signature from `jit.md`: `GroupItem* (*)(GroupItem* slotArray, GroupItem* argument)`.

### 1h. Firing the jitted function

At call time, when `action.jittedFn` is non-null:
1. Allocate slot array (BDWGC heap), populate from field list — one GroupItem*
   per slot (the C++ calling convention per `jit.md`).
2. Call `action.jittedFn(slotArray, argument)` → returns a `GroupItem*`.
3. The returned GroupItem* is the result. No further readback needed — rebox
   of all fields back into their GroupItems happened inside the jitted function
   (§1g step 1). The slot array can be discarded.
4. Return the result GroupItem* to the caller.

If `jittedFn` is null (not yet compiled, or gate rejected): fall through to
interpreter as today.

### Phase 1 stop condition

A single incant action like:
```
extern GroupItem addTwo(GroupItem arg)
{
    count x, y, result;
    x = 3;
    y = 5;
    result = x + y;
    return result;
}
```
…compiles via the jitting gate, runs via `jittedFn`, and returns 8. Verify
with `testing()` harness against interpreter result.

---

## Phase 2 — Control Flow

**Prerequisite:** Phase 1 pipeline proven end-to-end.

### The fundamental inversion

In execute mode, `aCTionIF` evaluates the condition and runs *one* branch.
In emit mode, `aCTionIF` must emit *both* branches as separate basic blocks,
connected by `CreateCondBr`. It cannot take a path.

```
if jitting {
    // 1. Emit condition expression → condVal (i1)
    BasicBlock* thenBB = BasicBlock::Create(jc.ctx, "then", jc.fn);
    BasicBlock* elseBB = BasicBlock::Create(jc.ctx, "else", jc.fn);
    BasicBlock* mergeBB = BasicBlock::Create(jc.ctx, "merge", jc.fn);
    jc.builder.CreateCondBr(condVal, thenBB, elseBB);

    // 2. Emit then-body into thenBB
    jc.builder.SetInsertPoint(thenBB);
    emitBody(thenBody, jc);
    jc.builder.CreateBr(mergeBB);

    // 3. Emit else-body into elseBB (or just branch to merge if no else)
    jc.builder.SetInsertPoint(elseBB);
    if (hasElse) emitBody(elseBody, jc);
    jc.builder.CreateBr(mergeBB);

    // 4. Continue after merge
    jc.builder.SetInsertPoint(mergeBB);
}
```

`PromotePass` handles the phi nodes at the merge point — the alloca/load/store
discipline means the then and else paths write to the same slots, and mem2reg
inserts the right phis. No manual phi management.

### `aCTionFOR` and `aCTionWHILE`

Same inversion: emit header block (condition), body block, latch block (back
edge to header), exit block. Standard LLVM loop structure. The bytecode arc's
`bcBR`/`bcBRZ`/label concept transfers directly as the block structure here.

```
loopHeader:
    condVal = (condition)
    CreateCondBr(condVal, loopBody, loopExit)
loopBody:
    (body)
    CreateBr(loopHeader)     // back edge
loopExit:
    (continue)
```

`aCTionFOR`'s `bcForNext`-equivalent (self-cleaning on exhaustion) maps to:
advance the iterator in the latch before the back edge; on exhaustion, branch
to loopExit instead of loopHeader.

### Comparison operators in emit mode

Add `jitMethod` to comparison operators:
```
'>='   operateMethod=opGE  interpretMethod=runGE  jitMethod=emitGE;
'>'    operateMethod=opGT  interpretMethod=runGT  jitMethod=emitGT;
'=='   operateMethod=opEQ  interpretMethod=runEQ  jitMethod=emitEQ;
'<='   operateMethod=opLE  interpretMethod=runLE  jitMethod=emitLE;
'<'    operateMethod=opLT  interpretMethod=runLT  jitMethod=emitLT;
'!='   operateMethod=opNotEQ interpretMethod=runNotEQ jitMethod=emitNotEQ;
```

Each `emitXX` uses the signed/unsigned-aware `CreateICmp*` or `CreateFCmpU*`
matrix from `Emitter.twk`'s `emitCompare` — that logic ports as-is.

### Phase 2 stop condition

An action with `if`/`while`/`for` containing count/number arithmetic compiles
and produces correct results. Verify several cases against interpreter.

---

## Phase 3 — Runtime Surface (Callbacks and String Ops)

**Prerequisite:** Phase 2 proven.

This is the "substantive remaining work" the design chat identified. Jitted
code that calls back into the runtime (locate, registry lookup, GroupItem
methods, print, string ops) needs ORC symbol resolution.

### The allow-list (derived from `UIjit.ext`, pruned to non-GUI)

The jitted-code → runtime surface for action jitting (not GUI jitting):
- GroupItem core methods: `locate`, `copyData`, `addGroup`, `getAttribute`,
  `setText`, `setNumber`, the `+=`/`/`/`%` operator overloads.
- StringRoutines globals.
- GroupRegistry lookup.
- Global GroupItem helpers.

For each entry, register with ORC:
```cpp
JD.define(absoluteSymbols(SymbolMap({
    {Mangle("locate"),
     {ExecutorAddr::fromPtr(&GroupItem::locate), JITSymbolFlags::Callable}},
    // ... etc
})));
```

The `extern "C"` alignment: `UIjit.ext` precedent and the existing
`.rtn`/hand-written `extern` pattern in incant both lean on `extern "C"` for
the runtime entry points the jitted code calls. Use `extern "C"` wrappers for
any C++ method that gets name-mangled, so ORC symbol names are predictable.

### String ops in emit mode

With the runtime surface in place, string `+` can emit as a `CreateCall` to an
`extern "C" GroupItem* stringAdvance(GroupItem* t, int count)` wrapper (the
bounds-guarded pointer-advance from `opPlus`'s string arm) rather than being
inlined. This is the "dispatch-free typed call" path — no type-switch at
runtime, just a direct call to the right helper.

Expand the monomorphic gate to admit `isSTRING`/`isTOKEN` fields once the
runtime surface is wired and the string helpers are registered with ORC.

### The op-pointer Tier-3 fallback

For ops that have no `jitMethod` but are type-stable, emit a `CreateCall`
through the op's method pointer. The two signatures from `UIjit.ext`:
- `void (*method)(GroupItem)` → `methodType == returnsVoid`
- `GroupItem (*methodRG)(GroupItem)` → `methodType == returnsGroupItem`

Emit the appropriate `FunctionType` and `CreateCall`. This is the safety net
for ops not yet given a `jitMethod` — they run via the existing C++ path rather
than causing the whole action to fall back to the interpreter.

### Phase 3 stop condition

Actions that call `locate`, use string fields, and/or invoke ops without
`jitMethod` compile and run correctly. The gate now admits the full common
action vocabulary.

---

## What Stays Deferred

- **`modedOP.boundTo` interaction with JIT dispatch.** Per `jit.md`.
- **Stack allocation optimization** (non-escape analysis). BDWGC heap is
  correct; stack is the earned optimization.
- **Recompile on structural edit.** The action wrapper seam is the right place;
  deferred per `jit.md`.
- **Type specialization / hot-path tightening.** The conservative JIT still
  goes through GroupItem pointer indirection for complex cases. True native
  tight-loop arithmetic is Phase 3+.
- **`emitIf` `CreateXor` tar baby** from `Emitter.twk` — investigate before
  porting that specific shape; it may be a narrow sub-case artifact.

---

## Files to Create / Modify

### New C++ files (via tok where appropriate)
- `jitContext.h` — `JitContext` and `JitFieldState` structs; the one-time
  LLVM init function.
- `jitEmitters.rtn` — the `emitPlus`, `emitMinus`, `emitAssign`, `emitGE`,
  etc. extern functions; `isJittable` gate; frame prologue/epilogue.
- `jitRuntime.rtn` — the `extern "C"` wrapper functions for ORC registration
  (Phase 3).

### Modified incant source
- `Operators` define block — add `jitMethod=emitX` attributes (Phase 1: `+`,
  `-`, `*`, `%`, `=`; Phase 2: comparisons; Phase 3: remainder).
- `ruleActions.rtn` — add `if jitting { ... }` to `aCTionExpressioN`,
  `aCTionIF`, `aCTionFOR`, `aCTionWHILE`.
- `GroupRules.twk` — wherever the action method pointer is cached, add the
  `jittedFn` pointer slot.

### Docs to update
- `CLAUDE.md` — remove/replace "LLVM IR generated from bytecode" line.
- `jit.md` — note that the codegen design is in this file (cross-reference).

---

## Stop-and-Ask Conditions for Clod

1. LLVM version not determinable from the build environment — ask Tony before
   writing any LLVM C++ (API shapes differ).
2. `GroupRules.twk` has no obvious slot for `jittedFn` on an action GroupItem —
   flag before inventing a location.
3. The `jitting` flag's home is not yet decided — it may be a global mode flag
   (like `generating`), a field on `JitContext` threaded through, or both. Ask
   before assuming.
4. Any op whose `jitMethod` emit shape is non-obvious from `opPlus` / `emitPlus`
   analogy — flag rather than guess.
5. On Phase 3, the ORC symbol registration point (startup vs. first JIT
   compile) — ask Tony.
