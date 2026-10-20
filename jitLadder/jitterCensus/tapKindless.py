# The kindless-local census (2026-10-20, after jit-kind-handover). Gated by INCANT_KLTAP=<file>; INCANT_KLFILE names the
# fixture (set by a wrapper, since pop.sh and the ladder call the binary directly). Three taps, lines deduplicated per
# process:
#   A  SLOT    -- the frame prologue (jitEmitters.rtn, the locals walk): every local it slots, with its kind AT BUILD.
#   B  HOLDS   -- aCTionBlocK, after each INTERPRETED statement: every local of the current action, with its kind NOW.
#                 A kind held only inside one statement and overwritten in the same statement is not seen.
#   C  ASSIGN  -- runOPdirect under jitting, at its TOP (before the handed-over early return): an assign-tier op whose
#                 target is a local kindless at build, with the op, the right side's kind at build (-1: none in hand),
#                 whether it is a literal, whether it already carries a jit value, and whether a node is in flight.
#   D  ITER    -- aCTionIterate under jitting: the iterator local (a cursor is a GROUP holder by construction).
# C and D carry the local's BODY pointer, joined to A's within one run: an inlined callee's local is compiled under the
# caller's currentMETHOD, and an assign's target is a reference node inside the statement, so neither names the owner.
# Kinds are flags.data: 0 none, 1 ANY, 2 CHAR, 3 SET, 4 BUFFER, 5 COUNT, 6 GROUP, 7 ITEM, 8 MAP, 9 NUMBER, 10 OBJECT,
# 11 REGEX, 12 STAK, 13 STRING, 14 TOKEN. Run ONLY in a branch-build clone; revert with git checkout, compare md5s.
EMIT = '''{ static std::set<std::string> *klSeen = new std::set<std::string>();
          const char *klF = ::getenv("INCANT_KLFILE"); char klLine[1024];
          ::snprintf(klLine, sizeof klLine, FMT, klF ? klF : "?", ARGS);
          if ( klSeen->insert(klLine).second ) { FILE *kf = ::fopen(::getenv("INCANT_KLTAP"),"a"); if ( kf ) { ::fputs(klLine,kf); ::fclose(kf); } } }'''
def emit(fmt, args):
    return EMIT.replace('FMT', fmt).replace('ARGS', args)

def patch(p, old, new):
    s = open(p).read()
    assert s.count(old) == 1, (p, old[:60])
    open(p, 'w').write(s.replace(old, new))
    print('tapKindless', p)

# A -- the prologue
old = '''            if (jitFrameFind(addr)) continue;    // one slot per field, not per node
'''
patch('jitEmitters.rtn', old, old + '''            if ( ::getenv("INCANT_KLTAP") ) ''' + emit('"SLOT %s %s %s %d %p\\n"',
    'action->groupBody->tag ? action->groupBody->tag : "?", fb->tag ? fb->tag : "?", (int)fb->flags.data, (void*)fb') + '\n')

# B -- after each interpreted statement
old = '''        if grup.isMethod    result = grup.gMethod(grup);
        else                result = grup;
'''
patch('ruleActions.rtn', old, old + '''        -%
        if ( !GroupControl::groupController->groupRules->jitting && ::getenv("INCANT_KLTAP") ) {
            GroupItem *klAct = GroupControl::groupController->groupRules->currentMETHOD ? GroupControl::groupController->groupRules->currentMETHOD->getGroup() : 0;
            GroupItem *klFld = 0;
            if ( klAct ) while ( (klFld = klAct->next(klFld)) ) {
                GroupBody *kb = klFld->groupBody;
                if ( !kb->flags.isLocal || kb->flags.isArgument || kb->flags.noPrint ) continue;
                ''' + emit('"HOLDS %s %s %s %d\\n"',
                    'klAct->groupBody->tag ? klAct->groupBody->tag : "?", kb->tag ? kb->tag : "?", (int)kb->flags.data') + '''
                } }
        %-
''')

# C -- assignments into kindless locals, at build
old = '''    // handedOverEmitsNothing a statement already handed'''
patch('GroupActions.rtn', old, '''    -%
    if ( ruler->jitting && ::getenv("INCANT_KLTAP") && target && op && ::opIsAssignTier(op)
         && target->groupBody->flags.isLocal && !target->groupBody->flags.isArgument && !target->groupBody->flags.data ) {
        GroupItem *klAct = GroupControl::groupController->groupRules->currentMETHOD ? GroupControl::groupController->groupRules->currentMETHOD->getGroup() : 0;
        ''' + emit('"ASSIGN %s %p %s %s argKind=%d lit=%d jit=%d node=%d\\n"',
            '(void*)target->groupBody, target->groupBody->tag ? target->groupBody->tag : "?", op->groupBody->tag ? op->groupBody->tag : "?", arg ? (int)arg->groupBody->flags.data : -1, arg ? (int)arg->groupBody->flags.isLiteral : 0, (arg && arg->jitData) ? 1 : 0, gJitLastIsNode ? 1 : 0') + '''
        }
    %-
''' + old)

# D -- iterate cursors, at build
old = '''    if jitting {
        // emitThenFallThru -- the only gate in the tree that does not return, and deliberately so.
'''
patch('ruleActions.rtn', old, '''    -%
    if ( GroupControl::groupController->groupRules->jitting && ::getenv("INCANT_KLTAP") && iterator ) {
        GroupItem *klAct = GroupControl::groupController->groupRules->currentMETHOD ? GroupControl::groupController->groupRules->currentMETHOD->getGroup() : 0;
        ''' + emit('"ITER %s %p %s %d\\n"',
            '(void*)iterator->groupBody, iterator->groupBody->tag ? iterator->groupBody->tag : "?", (int)iterator->groupBody->flags.data') + '''
        }
    %-
''' + old)
