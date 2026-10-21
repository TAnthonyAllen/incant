# SEQ 388 R3: the census after the cure (branch jit-kindless-infer). Apply ON TOP of tapKindless.py (same gate INCANT_KLTAP,
# same INCANT_KLFILE); tapKindless's tap A still logs every local the prologue SLOTS. Two more:
#   F  NOSLOT  -- the prologue's nonScalarNoSlot skip: a local its writer made non-scalar, with the recorded kind.
#   G  NET     -- the kindlessNet refusal: the action and the local it names.
# kindlessInferTable.py joins them to the pre-cure census (results/kindless.raw) and to tap B's run-time kinds.
def patch(p, old, new):
    s = open(p).read()
    assert s.count(old) == 1, (p, old[:60])
    open(p, 'w').write(s.replace(old, new))
    print('tapInfer', p)
EMIT = '''{ static std::set<std::string> *klSeen = new std::set<std::string>();
          const char *klF = ::getenv("INCANT_KLFILE"); char klLine[1024];
          ::snprintf(klLine, sizeof klLine, FMT, klF ? klF : "?", ARGS);
          if ( klSeen->insert(klLine).second ) { FILE *kf = ::fopen(::getenv("INCANT_KLTAP"),"a"); if ( kf ) { ::fputs(klLine,kf); ::fclose(kf); } } }'''
def emit(fmt, args): return EMIT.replace('FMT', fmt).replace('ARGS', args)

old = '''            if (::jitLocalNonScalar(fb)) continue;
'''
patch('jitEmitters.rtn', old, '''            if ( ::jitLocalNonScalar(fb) && ::getenv("INCANT_KLTAP") ) ''' + emit('"NOSLOT %s %s %s %d %p\\n"',
    'action->groupBody->tag ? action->groupBody->tag : "?", fb->tag ? fb->tag : "?", gJitLocalKind[fb], (void*)fb') + '\n' + old)

old = '''        fflush(stderr);
        gJitBuilder = nullptr;
        gJitResult  = nullptr;
        gJitResultSlot = nullptr;
        return -8; }'''
patch('jitEmitters.rtn', old, '''        if ( ::getenv("INCANT_KLTAP") ) ''' + emit('"NET %s %s %s %p\\n"',
    'action->groupBody->tag ? action->groupBody->tag : "?", lb->tag ? lb->tag : "?", (void*)lb') + '\n' + old)
