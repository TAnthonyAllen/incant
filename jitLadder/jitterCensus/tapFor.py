# SEQ 390 R1: the for statement's writers. Apply ON TOP of tapKindless.py + tapInfer.py (same gate INCANT_KLTAP, same
# INCANT_KLFILE, same dedup). Three taps:
#   FORGATE  -- aCTionFOR's jitting gate, before the hand-over: the cursor local the build holds (Looper, followed), with
#               its kind AT BUILD and its body.
#   FORCUR   -- the interpreted loop, after `Looper.group = grup`: the cursor's kind NOW.
#   FORBODY  -- runOPdirect's top, interpreted, while a FOR body runs (gKlForDepth > 0): every assign-tier write into a
#               local, with the op and the local's kind before the write.
# Owners are currentMETHOD's (a FOR inside a compiled action runs through jitEmitStmtRT, whose owner is the action).
def patch(p, old, new):
    s = open(p).read()
    assert s.count(old) == 1, (p, old[:60])
    open(p, 'w').write(s.replace(old, new))
    print('tapFor', p)
EMIT = '''{ static std::set<std::string> *klSeen = new std::set<std::string>();
          const char *klF = ::getenv("INCANT_KLFILE"); char klLine[1024];
          ::snprintf(klLine, sizeof klLine, FMT, klF ? klF : "?", ARGS);
          if ( klSeen->insert(klLine).second ) { FILE *kf = ::fopen(::getenv("INCANT_KLTAP"),"a"); if ( kf ) { ::fputs(klLine,kf); ::fclose(kf); } } }'''
def emit(fmt, args): return EMIT.replace('FMT', fmt).replace('ARGS', args)
OWN = 'GroupItem *klAct = GroupControl::groupController->groupRules->currentMETHOD ? GroupControl::groupController->groupRules->currentMETHOD->getGroup() : 0;'
OT = 'klAct && klAct->groupBody->tag ? klAct->groupBody->tag : "?"'

patch('jitContext.h', 'inline int gJitKindRestarts = 0;\n', 'inline int gJitKindRestarts = 0;\ninline int gKlForDepth = 0;\n')

old = '''    if jitting {
        jitHandOver("FOR under jit'''
patch('ruleActions.rtn', old, '''    -%
    if ( GroupControl::groupController->groupRules->jitting && ::getenv("INCANT_KLTAP") && Looper ) {
        GroupItem *klC = isGROUP(Looper->groupBody->flags.data) && Looper->getGroup() ? Looper->getGroup() : Looper;
        ''' + OWN + '''
        ''' + emit('"FORGATE %s %s %s %p %d\\n"', OT + ', klC->groupBody->tag ? klC->groupBody->tag : "?", (void*)klC->groupBody, (int)klC->groupBody->flags.data') + '''
        }
    %-
''' + old)

old = '''            lastREF.gGroup  = grup;
            lastREF.isGROUP = true; }
        branchKind = 0;
        result = StatemenT.gMethod(StatemenT);'''
patch('ruleActions.rtn', old, '''            lastREF.gGroup  = grup;
            lastREF.isGROUP = true; }
        -%
        if ( ::getenv("INCANT_KLTAP") ) {
            ''' + OWN + '''
            ''' + emit('"FORCUR %s %s %s %p %d\\n"', OT + ', Looper->groupBody->tag ? Looper->groupBody->tag : "?", (void*)Looper->groupBody, (int)Looper->groupBody->flags.data') + '''
            }
        gKlForDepth++;
        %-
        branchKind = 0;
        result = StatemenT.gMethod(StatemenT);
        -% gKlForDepth--; %-''')

old = '''    // kindlessWriter a kindless local's writer is recorded before anything else'''
patch('GroupActions.rtn', old, '''    -%
    if ( !ruler->jitting && gKlForDepth > 0 && ::getenv("INCANT_KLTAP") && target && op && ::opIsAssignTier(op)
         && target->groupBody->flags.isLocal && !target->groupBody->flags.isArgument ) {
        ''' + OWN + '''
        ''' + emit('"FORBODY %s %s %s %p %s %d\\n"', OT + ', target->groupBody->tag ? target->groupBody->tag : "?", (void*)target->groupBody, op->groupBody->tag ? op->groupBody->tag : "?", (int)target->groupBody->flags.data') + '''
        }
    %-
''' + old)
