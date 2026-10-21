# SEQ 388 R1 (a)/(c): which frame-slot loads survive into a COMPILED function, and what consumes them. Apply ON TOP of
# tapKindless.py (same gate INCANT_KLTAP, same INCANT_KLFILE, same dedup). One tap:
#   E  KREAD -- jitBuildFunction, just before the verifier (the emitter's own IR, pre-mem2reg; a handed-over statement's
#               loads are already gone, so this is what the compiled code reads). Every load from a frame slot, with the
#               slot's body, the load's name (frame = a VALUE read, from jitSeedField; epilog / rtFlush / rtOld /
#               opFireFlush* / opFireOld = bookkeeping), and its users -- opcode, and for a call the helper's symbol.
#               A compile serial keeps two compiles of one action apart under the per-process dedup.
# Join KREAD's body to tap A's SLOT line (same file, same body pointer) for the owner and the local's name.
def patch(p, old, new):
    s = open(p).read()
    assert s.count(old) == 1, (p, old[:60])
    open(p, 'w').write(s.replace(old, new))
    print('tapKindlessRead', p)

old = '''    if (llvm::verifyFunction(*fn, &llvm::errs())) {
        fprintf(stderr,
            "=== jitRunAction: INVALID IR for %s -- REFUSING to run it ===\\n",'''
patch('jitEmitters.rtn', old, '''    if ( ::getenv("INCANT_KLTAP") ) {
        static int klSerial = 0; klSerial++;
        static std::set<std::string> *krSeen = new std::set<std::string>();
        const char *klF = ::getenv("INCANT_KLFILE");
        int kix = 0;
        for (llvm::BasicBlock &kbb : *fn) for (llvm::Instruction &kin : kbb) {
            kix++;
            llvm::LoadInst *kld = llvm::dyn_cast<llvm::LoadInst>(&kin);
            if (!kld) continue;
            for (JitFrameSlot &kf : gJitFrame) {
                if (kf.slot != kld->getPointerOperand()) continue;
                GroupBody *kb = kf.ty->isDoubleTy() ? (GroupBody*)((char*)kf.home - offsetof(GroupBody, gNumber))
                                                    : (GroupBody*)((char*)kf.home - offsetof(GroupBody, gCount));
                std::string kus;
                for (llvm::User *ku : kld->users()) {
                    llvm::Instruction *kui = llvm::dyn_cast<llvm::Instruction>(ku);
                    if (!kui) { kus += "?,"; continue; }
                    kus += kui->getOpcodeName();
                    if (llvm::CallInst *kci = llvm::dyn_cast<llvm::CallInst>(kui)) {
                        const char *who = "?";
                        llvm::Value *kco = kci->getCalledOperand();
                        if (llvm::ConstantExpr *kce = llvm::dyn_cast<llvm::ConstantExpr>(kco))
                            if (kce->getOpcode() == llvm::Instruction::IntToPtr)
                                if (llvm::ConstantInt *kci2 = llvm::dyn_cast<llvm::ConstantInt>(kce->getOperand(0))) {
                                    Dl_info kdi; if (::dladdr((void*)kci2->getZExtValue(), &kdi) && kdi.dli_sname) who = kdi.dli_sname; }
                        if (llvm::Function *kcf = kci->getCalledFunction()) who = kcf->getName().data();
                        kus += ":"; kus += who; }
                    kus += ","; }
                char klLine[1024];
                ::snprintf(klLine, sizeof klLine, "KREAD %s %d.%d %s %p %s %s %s %s\\n", klF ? klF : "?", klSerial, kix, fnName,
                           (void*)kb, kb->tag ? kb->tag : "?", kf.ty->isDoubleTy() ? "f64" : "i32",
                           kld->getName().str().c_str(), kus.empty() ? "-" : kus.c_str());
                if ( krSeen->insert(klLine).second ) { FILE *kfp = ::fopen(::getenv("INCANT_KLTAP"),"a"); if ( kfp ) { ::fputs(klLine,kfp); ::fclose(kfp); } }
            }
        }
    }
''' + old)
