// jitContext.h — Phase JIT codegen state (LLVM 22). Hand-written C++ — NOT tok-processed.
// JitData mirrors OLDtawkDoNotTouch/Tokf/JitData.h (the proven pattern): a global
// struct with fully-qualified llvm:: pointer fields + get/set methods. See
// docs/jit-design.md (codegen) and docs/jit.md (frame/calling convention).
#ifndef JITCONTEXT_H
#define JITCONTEXT_H

#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"
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
