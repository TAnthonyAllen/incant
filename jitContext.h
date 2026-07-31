// jitContext.h — Phase JIT codegen state (LLVM 22). Hand-written C++ — NOT tok-processed.
// JitData mirrors OLDtawkDoNotTouch/Tokf/JitData.h (the proven pattern): a global
// struct with fully-qualified llvm:: pointer fields + get/set methods. See
// docs/jitDesign.md (codegen) and docs/jit.md (frame/calling convention).
#ifndef JITCONTEXT_H
#define JITCONTEXT_H

#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/ExecutionEngine/Orc/LLJIT.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Transforms/Utils/Mem2Reg.h"
#include <memory>
#include <vector>

// The builder the emitters write into. Set by the compile driver before walking
// an action body; grabbed by each emitter in a one-line -% %- (the only passthrough
// the otherwise tok-native emitters need). C++17 inline var → one definition across
// TUs, header-defined so it never reaches GroupRules.h.
inline llvm::IRBuilder<> *gJitBuilder = nullptr;

// The SSA value the action body last produced. The jitting gate (aCTionExpressioN)
// emits into gJitBuilder and leaves the running result here; the compile driver
// (jitRunAction) reads it after the body walk to emit the function's CreateRet.
// Single-result for the Phase-1 straight-line proof; widens to per-field rebox later.
inline llvm::Value *gJitResult = nullptr;

// Stack of pending "endif" merge blocks for the gIF emitter. jitIfBegin pushes
// the endif block (after emitting the CreateCondBr that splits to the then
// block); jitIfEnd branches the finished then block to it and resumes insertion
// there, popping. A stack (not a scalar) so nested ifs nest correctly. Header-
// inline like gJitBuilder so it never reaches GroupRules.h.
inline std::vector<llvm::BasicBlock*> gIfEndBlocks;

// Stack of pending "else" blocks, parallel to gIfEndBlocks and pushed/popped in
// lockstep with it (2026-07-31, the else arm). jitIfBegin now ALWAYS creates
// three blocks -- then, else, endif -- and branches the condition to then/else.
// jitIfElse closes the then arm and resumes in the else block; jitIfEnd closes
// whichever arm is current and resumes at endif.
//
// ALWAYS three, even when the source has no `else`, and that is deliberate: an
// if-without-else then emits an EMPTY else block that branches straight to
// endif. That is valid IR, it costs one branch that LLVM folds, and it means
// there is exactly ONE block topology instead of two -- so the no-else case
// cannot drift away from the with-else case, which is precisely how the else arm
// came to be missing in the first place.
inline std::vector<llvm::BasicBlock*> gIfElseBlocks;

// THE RESULT SLOT (2026-07-31, Tony's ruling). An i32 alloca in the function's
// entry block holding the action's value. Every statement stores to it; the cap
// loads it and rets. gJitResult-as-last-value retires.
//
// WHY A SLOT AND NOT A PHI: the ruling is that the compiled action returns what
// the interpreted action returns, and the interpreted rule is "the value of the
// LAST EXECUTED STATEMENT" -- so on a two-armed if the answer differs per path
// and has to be merged. RESULTS ARE MEMORY, exactly as fields are: each arm
// STORES and the exit LOADS, and the merge is the memory location. No phi is
// written, and unlike the field slots this one IS an alloca, so mem2reg can
// promote it and insert the phi itself if it wants to.
//
// ⚠ It is the FIRST alloca this emitter has ever produced. The standing note
// that "mem2reg has nothing to promote" was true of field slots (baked absolute
// addresses) and is no longer true of the function as a whole.
inline llvm::Value *gJitResultSlot;

// Did ANY statement commit a value this run? Set by jitStoreResult, reset by
// jitRunAction. This replaces the old "is gJitResult non-null at the end" test,
// which the result slot falsified: a bracketing emitter (gIF, and later the
// loops) COMMITS its arms and then clears gJitResult on purpose, so a null
// in-flight value at the end became the NORMAL case for any action ending in
// control flow -- and the old guard read it as "the gate never fired" and
// bailed before emitting the return.
inline bool gJitEmitted;

// THE COMPILED FUNCTION, kept so it can be FIRED AGAIN without recompiling
// (2026-07-31, the jitLadder). Every rung must compile ONCE and fire TWICE at
// different inputs, because a right answer is not proof the COMPILED code
// produced it: under jitting the interpreter executes the body for real at emit
// time, so a naive end-to-end POP can go green on an emit-time side effect with
// the compiled function returning a baked constant -- right answer, wrong
// universe, exit 0 throughout. If the second fire tracks an input changed AFTER
// emission, the computation happened at RUN time. Nothing else proves it.
inline int (*gJitLastFn)() = nullptr;

// Degrade count as a readable global rather than a function-local static, so a
// rung can ASSERT it. Zero is the claim "this rung's constructs are all covered
// -- nothing silently fell through to emit-time interpretation". Still a C++
// static and not a node slot, for CLAIM KANT-4's reason: GroupBody's value slots
// are one union and a counter parked in gCount destroys whatever shares it.
inline int gJitDegradeCount = 0;

// Nodes seeded with JitData during the current compile. JitData is transient (one
// compile, into a per-run LLVMContext that jitRunAction destroys), but the field/
// literal GroupItems that carry it persist (BDWGC). The runOP seeding gate skips a
// node that already has jitData (bear-trap #9: never re-seed an inner op-result),
// and that same guard would make a STALE jitData from a PRIOR run look "already
// seeded" — so the driver must null these between runs, else run 2 reads a Value*
// from run 1's freed context. Recorded by jitSeedField/jitSeedLiteral; reset at the
// top of jitRunAction. (The old jitXpress re-seeded unconditionally, so it never
// needed this; the #9 guard makes it necessary.)
class GroupItem;
inline std::vector<GroupItem*> gJitSeeded;

// Binary-op selector for jitEmitBinary — readable names, not magic ints. Each
// arithmetic opMethod's jitting gate passes one of these; the int/float variant
// of the actual LLVM instruction is picked inside jitEmitBinary from operand type.
enum jitOp { jitAdd, jitSub, jitMul, jitSDiv };

// Compare-op selector for jitEmitCompare — the relational sibling of jitOp,
// same style and same home. jitEQ/jitNE are sign-agnostic (ICmp EQ/NE, FCmp
// OEQ/ONE); the ordered four resolve to signed-int (ICmp SLT/SLE/SGT/SGE) on
// the integer path and ordered-float (FCmp OLT/OLE/OGT/OGE) on the double path.
// The emitter yields an i1, distinct from jitOp's operand-typed result.
enum jitCmp { jitEQ, jitNE, jitLT, jitLE, jitGT, jitGE };

// Unary-op selector for jitEmitUnary — ++/-- write back in place; jitNeg
// (unary minus) is value-producing: negate the operand, NO store-back.
enum jitUnary { jitInc, jitDec, jitNeg };

// Per-field JIT state, hung on the GroupItem node during emission (the Emitter.twk
// JitData pattern). Transient: meaningful only while an action is being compiled.
class JitData {
public:
    llvm::Value *jitSlot;    // the alloca for this field (set in prologue)
    llvm::Value *jitValue;   // current SSA value (load/store traffic)
    llvm::Type  *jitType;    // LLVM type for this field (set at gate check)
    llvm::Value *getJitter()              { return jitValue; }
    void         setJitter(llvm::Value *v){ jitValue = v; }
    JitData() : jitSlot(0), jitValue(0), jitType(0) {}
};

// Per-action emission context. C++-internal — never appears in a tok-extern
// signature (that would poison the generated header). Reached from emitters via a
// file-static current-context pointer, not passed as a parameter.
class JitContext {
public:
    llvm::LLVMContext &ctx;
    llvm::IRBuilder<> &builder;
    llvm::Function    *fn;        // the function being built
    llvm::BasicBlock  *entryBB;   // entry block (allocas live here)
    bool               ok;        // cleared on any emit error → fall back

    JitContext(llvm::LLVMContext &c, llvm::IRBuilder<> &b)
        : ctx(c), builder(b), fn(0), entryBB(0), ok(true) {}
};

// jitInitOnce() / jitEngine() are emitted by jitEmitters.rtn as extern "C"
// (tok generates their prototypes in GroupRules.h). jitEngine() returns the
// llvm::orc::LLJIT* as void* to keep its tok-extern signature header-clean.

#endif // JITCONTEXT_H
