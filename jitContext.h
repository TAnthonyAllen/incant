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
#include "llvm/Support/raw_ostream.h"
#include <memory>
#include <vector>
#include <string>

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

// LOOP BLOCK TOPOLOGY (2026-07-31, rung J3). The loop analog of gIfElseBlocks
// /gIfEndBlocks, pushed and popped in lockstep so nested loops nest.
//
//   preheader -> br cond
//   cond:  <condition sub-walk emits HERE>  ; br i1 %c, body, exit
//   body:  <body sub-walk emits HERE>       ; br cond      <-- back edge
//   exit:  (emission continues here)
//
// ⚠ THE CONDITION IS EMITTED INSIDE `cond`, WHICH IS WHY jitLoopBegin RUNS
// BEFORE THE CONDITION WALK -- the opposite order from gIF, where the condition
// is emitted into the CURRENT block and jitIfBegin then splits. A loop's
// condition must re-execute every iteration, so it has to live in a block the
// back edge returns to. Get this backwards and the condition is evaluated once,
// before the loop, and the loop is infinite or never runs.
inline std::vector<llvm::BasicBlock*> gLoopCondBlocks;
inline std::vector<llvm::BasicBlock*> gLoopExitBlocks;

// The loop BODY block, needed only by `do` -- a while's back edge targets cond,
// a do's targets body. Pushed/popped in lockstep with the other two.
inline std::vector<llvm::BasicBlock*> gLoopBodyBlocks;

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

// THE COMPILE COUNTER (Clay SEQ 27 v2, 2026-08-04). Compile-on-first-fire is the
// ruling, so "did the second fire recompile?" is the POP's central question and
// it needs an instrument rather than an inference. Incremented ONCE per
// jitRunAction compile and printed with its VALUE on every fire (H4:
// presence-with-value, never absence-of-message). A check that asserted "no
// second compile happened" by the absence of a message would go green the day
// the message was deleted; asserting `count == 1` across two fires cannot.
inline int gJitCompileCount = 0;

// THE EMITTED IR, captured as TEXT for the `JiT` attribute. Captured in
// jitRunAction immediately BEFORE addIRModule, and that placement is forced, not
// stylistic: addIRModule std::move()s the module and the context into the JIT, so
// after that line there is no module left to print. Post-mem2reg, matching the
// INCANT_JIT_DUMP=1 dump, because what is recorded should be what RUNS.
// ⚠ RECORD, NOT DISPATCH. Nothing reconstructs a function pointer from this
// string. It exists for persistence and inspection, and Clay SEQ 27 v2 rules that
// boundary explicitly: dispatch is only ever through rStuff.jitMethod.
inline std::string gJitLastIR;

// THE PRINT BUFFER IN FLIGHT (2026-08-04). jitEmitPrint brackets a print
// statement: one emitted call to jitPrintBegin acquires the buffer, one emitted
// call per item appends into it, one emitted call to opPrint sinks it. The
// buffer is an SSA value produced by the first call and consumed by the rest, so
// it has to survive between the emitter's own statements -- exactly the job
// gJitBuilder and the block stacks already do. A C++ local could not, because
// the walk between them is tok code, not one passthrough block.
// Cleared by jitEmitPrint on the way out (E1: nothing left in flight).
inline llvm::Value *gJitPrintBuf = nullptr;

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

// THE FRAME (Increment 1, 2026-08-01). The action's own field list IS the frame
// schema -- (isArgument || isLocal) && !noPrint -- which is not a new invention:
// it is the exact predicate saveLocalFields/restoreLocalFields have walked in the
// interpreter since the beginning (GroupActions.rtn). INHERIT THE SCHEMA, NOT THE
// BUG: the enumeration is taken, the save/restore discipline is not.
//
// Holds the nodes given a frame alloca by this compile's prologue, in walk order,
// so the epilogue can store them back. A subset of gJitSeeded -- every frame local
// is seeded (the prologue IS its seed), but literals and globals are not framed.
// Cleared at the top of jitRunAction alongside gJitSeeded.
//
// ⚠ INCREMENT 1 IS NOT INDEPENDENTLY PROVABLE, and the rung says so itself.
// Without recursion, allocas-for-locals is BEHAVIOUR-NEUTRAL -- the same answers
// come out, because one activation's alloca and one field's storage hold the same
// value at every observable point. What a structure rung can assert is that the
// allocas EXIST and that no local kept a baked address, plus a value-regression
// net. THE PROOF IS J-R: per-call storage only becomes observable when two calls
// are live at once, and depth-1 passes on aliased slots where depth-N cannot.
// ⚠ KEYED ON THE FIELD'S STORAGE ADDRESS, NOT ON THE NODE, AND THAT IS THE
// FINDING OF INCREMENT 1. The first cut keyed on GroupItem* and pre-seeded each
// framed node's jitData. It framed nothing: MEASURED with a node-identity trace,
// the action's field-list entry for a local is a DIFFERENT NODE from the ones the
// runOP tree references, and each OCCURRENCE in the body is its own node again --
// `jfTmp` framed at 0x10243e080, then baked twice at 0x102452540 and 0x102453780.
// All three resolve to the same storage, which is exactly why the baked-address
// model never had to care about node identity.
//
// So the frame cannot be keyed on identity the emitter does not preserve. It is
// keyed on `home` -- the address of the field's gCount/gNumber -- which is the
// one thing every occurrence agrees on.
struct JitFrameSlot {
    void        *home;   // &gCount or &gNumber -- the identity that survives
    llvm::Value *slot;   // the alloca
    llvm::Type  *ty;
};
inline std::vector<JitFrameSlot> gJitFrame;

// THE FUNCTION AND ACTION CURRENTLY BEING COMPILED. Needed so a SELF-CALL can be
// emitted as a real `call` instead of being inlined by emit-on-walk.
// ⚠ WHY A CALL IS MANDATORY HERE AND OPTIONAL EVERYWHERE ELSE: a non-recursive
// call INLINES correctly today (measured, incant/jitJC -- fire 2 tracks the
// input and there is no `call` in the IR). A SELF-call cannot, and not merely
// because it would not terminate: the re-walk reuses nodes that already carry
// jitData from the enclosing pass, and jitEmitCompare has written its i1 RESULT
// into the target node's jitValue. Measured -- the second pass sees
// `jrN type=[i1]` against a literal i32 and LLVM asserts. That is one channel
// carrying two meanings (the field's value and the last op's result), and the
// cure is a second channel, not a cleverer test: emit a CALL and stop re-walking.
class GroupItem;
inline GroupItem       *gJitCurrentAction = nullptr;
inline llvm::Function  *gJitCurrentFn     = nullptr;

// Look a field's storage up in the current frame. Returns null when the field is
// a GLOBAL, which is the common case and the correct one -- globals keep baked
// addresses and immediate store-through (Part III's phase scope).
inline JitFrameSlot *jitFrameFind(void *home) {
    for (JitFrameSlot &f : gJitFrame) if (f.home == home) return &f;
    return nullptr;
}

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
