# Phase JIT — the Phase-1 wiring walk (the desert crossing)

*Clod, 2026-06-17, for Clay. Narrative + findings from getting the LLVM 22 /
tok-native foundation green. Companion to `jit-design.md` and `jit.md`. Ends at
commit `c15a50f` (JIT Phase 1 foundation, building green) — emitters next.*

## Where we landed (green, committed)
- **Toolchain**: stale x86_64 LLVMs removed; **LLVM 22.1.7 arm64** at
  `/opt/homebrew/opt/llvm`. Groups target wired (pbxproj, outside the repo):
  `gnu++17` + `libc++`, `-isystem …/llvm/include`, `-lLLVM-22` + rpath. Proven by
  a standalone LLJIT smoke test (compiles, links, runs).
- **`jitExterns`**: the LLVM 22 API as tok externals (modernized port of the old
  `Include/jit`). Emitters get written tok-native against it.
- **`jitContext.h`**: `class JitData` (qualified `llvm::` fields + get/set,
  faithful to the old `Tokf/JitData.h`), `JitContext`, init/engine decls.
- **GroupItem** carries `JitData *jitData` — per-wrapper, forward-declared in the
  header, auto-nulled by BDWGC on construct *and* copy (no ctor surgery).
- Builds clean against LLVM 22. `target.jitData.jitValue = CreateAdd(...)` is now
  expressible tok-native.

## The design refinement that stuck
`jit-design.md` originally specced a C++ `std::unordered_map<GroupItem*,…>` side
table for transient jit state. The build proved that fights tok two ways (forces
passthrough for state access; and llvm-typed signatures poison the header — see
below). **Adopted instead: JitData hung on the node** (Emitter.twk's pattern) —
tok-native emit bodies, llvm-clean header. Clay updated the doc's "Transient JIT
State" section accordingly. Same fields, better home.

## The walk — false starts, each a real finding
1. **Whole-file `-% %-` passthrough is a dead end.** Top-level passthrough is
   **dropped**; `-% %-` only emits *inside a method body* (GroupItem.twk:1254 is
   the working example). So LLVM C++ can't just be poured into a `.rtn` as one
   passthrough block.
2. **Tony's steer → the externals approach.** Declare the LLVM API as tok
   externals (the old `jit` file's job); write emitters tok-native (Emitter.twk's
   job); reserve `-% %-` for the genuinely awkward bits (one-time ORCv2 engine).
3. **tok emits clean per-op C++** once the externals exist — `b->CreateAdd(l,r,
   "add")` with correct `llvm::` on the return type. The **`external IRBuilder`
   dummy** (alongside `external IRBuilder<>`) was required for the template —
   straight from the old `jit` file's comment.
4. **`.h` poisoning (bear trap).** An `extern` whose *signature* uses `llvm::`
   types makes tok emit a prototype into `GroupRules.h`, which only
   forward-declares classes and drops includes on regen → `undeclared identifier
   'llvm'`. **Rule: keep `llvm::` types out of tok-extern signatures.** Emitters
   take/return plain types (`GroupItem*`/void) and carry `llvm::Value` in JitData.
5. **The JitData "ERROR Inheritance" red herring.** Declaring `external JitData`
   threw `ERROR Inheritance` (mislocated onto the *next file's comment*). It
   *looked* like the JitData decl was at fault (removing it → green). It wasn't.
6. **The actual cause — tok has no lexer.** PLG + the parse do everything in one
   grammar-driven pass (this is why incant has `checkSkip`). So `/* … */` comment
   interiors are **not inert**: the grammar still sees `-% %-` passthrough markers
   and *declared* type-name tokens inside them. `jitEmitters.rtn`'s comment
   contained both `-% %-` and `llvm::Value`/`JitData` — harmless until those types
   were *declared*, at which point the grammar parsed the comment text as code and
   threw. Removing **either** the decls **or** the comment tokens cleared it,
   which is what made the decl look guilty. Fix: token-free comments → green with
   JitData fully declared.
7. **The old files closed it.** `OLDtawkDoNotTouch/Frame/llvm.h` = the umbrella
   (real LLVM includes + `using namespace llvm;`) — pattern transfers, LLVM-3.x
   include list does not. `OLDtawkDoNotTouch/Tokf/JitData.h` = the **hand-written**
   JitData (forward-decl `namespace llvm{ class Value; class Type; }` then global
   `class JitData` with qualified fields + get/set). JitData was never
   tok-generated; the `external JitData {…}` is just tok's *view* of that header.

## Durable bear traps minted on this walk (for the bible/CLAUDE.md)
- **No separate lexer.** tok/incant parse single-pass (PLG + parse). Comments are
  not lexically stripped first.
- **`/* … */` comments are not inert** — extends the existing `//`-comment trap.
  Keep `-% %-` and known type-names out of tok comments entirely.
- **Top-level `-% %-` passthrough is dropped** — only works inside method bodies.
- **No `llvm::` types in tok-extern signatures** — poisons the generated `.h`.
- **`external IRBuilder` dummy** is required beside `external IRBuilder<>`.

## Next (unblocked)
Engine (`jitInitOnce`/`jitEngine` via in-body `-% %-`) → `emitPlus`/`emitRem`
tok-native → `isJittable` gate + prologue/epilogue (unbox `gCount`/`gNumber` →
alloca; rebox → return `GroupItem*`) → the `jitting` branch in `aCTionExpressioN`
+ the `JiT` field on the action + firing → `Operators` `jitMethod=` attrs and the
`%`→`opRem` rename → `addTwo`→8 against the `testing()` harness.
