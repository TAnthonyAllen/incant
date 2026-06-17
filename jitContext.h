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

namespace llvm { namespace orc { class LLJIT; } }

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

// One-time LLVM process setup (InitializeNativeTarget etc.). Idempotent.
void jitInitOnce();

// The process-wide ORCv2 JIT engine (created once). nullptr if creation failed.
llvm::orc::LLJIT *jitEngine();

#endif // JITCONTEXT_H
