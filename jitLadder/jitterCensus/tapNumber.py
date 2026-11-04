# SEQ 524 R0: the writer census -- count, number or both -- for every kindless local (branch-build clone only). Apply ON TOP of
# tapKindless.py (same gate INCANT_KLTAP, same INCANT_KLFILE); tapKindless's A still logs every local the prologue slots and its B
# what each holds running interpreted. One more:
#   W  WRITER -- jitNoteWriter past its gate (a kindless local, no argument, no noPrint): body, tag, op, and the writer's class:
#      cursor | holder | none (no argument in hand) | vdouble / vint (a computed value and its IR type) | kind=<n> (a known kind)
#      | local=<body>:<tag> (a kindless operand; numberTable.py closes over these).
#   FW -- the same, from jitNoteFor's scan of a for body (never walked at build): kind of the value, or none.
def patch(p, old, new):
    s = open(p).read()
    assert s.count(old) == 1, (p, old[:60])
    open(p, 'w').write(s.replace(old, new))
    print('tapNumber', p)
EMIT = '''{ static std::set<std::string> *klSeen = new std::set<std::string>();
          const char *klF = ::getenv("INCANT_KLFILE"); char klLine[1024];
          ::snprintf(klLine, sizeof klLine, FMT, klF ? klF : "?", ARGS);
          if ( klSeen->insert(klLine).second ) { FILE *kf = ::fopen(::getenv("INCANT_KLTAP"),"a"); if ( kf ) { ::fputs(klLine,kf); ::fclose(kf); } } }'''
def emit(fmt, args): return EMIT.replace('FMT', fmt).replace('ARGS', args)

old = '''    int kind = 5;
    if ( !op ) kind = 6;
'''
patch('jitEmitters.rtn', old, '''    if ( ::getenv("INCANT_KLTAP") ) {
        char wc[128];
        if ( !op ) ::strcpy(wc, "cursor");
        else if ( (void*)op->groupBody->gOp == (void*)&opSetGroup || (void*)op->groupBody->gOp == (void*)&opRebind ) ::strcpy(wc, "holder");
        else if ( !arg ) ::strcpy(wc, "none");
        else if ( arg->jitData && arg->jitData->jitValue ) ::strcpy(wc, arg->jitData->jitValue->getType()->isDoubleTy() ? "vdouble" : "vint");
        else if ( arg->jitData ) ::strcpy(wc, "vnull");
        else if ( arg->groupBody->flags.data ) ::snprintf(wc, sizeof wc, "kind=%d", (int)arg->groupBody->flags.data);
        else ::snprintf(wc, sizeof wc, "local=%p:%s", (void*)arg->groupBody, arg->groupBody->tag ? arg->groupBody->tag : "?");
        ''' + emit('"WRITER %s %p %s %s %s\\n"', '(void*)tb, tb->tag ? tb->tag : "?", op && op->groupBody->tag ? op->groupBody->tag : "-", wc') + '''
        }
''' + old)

old = '''                GroupBody *tb = t->groupBody;
                int kind = 1;
'''
patch('jitEmitters.rtn', old, old + '''                if ( ::getenv("INCANT_KLTAP") ) ''' + emit('"FWRITER %s %p %s %s %d\\n"',
    '(void*)tb, tb->tag ? tb->tag : "?", op->groupBody->tag ? op->groupBody->tag : "-", v ? (int)v->groupBody->flags.data : -1') + '\n')
