# SEQ 392 R0: every jitDegrade that promises a run that never happens. Gated by INCANT_DGTAP=<file>; INCANT_KLFILE names
# the fixture (the wrapper sets it). A degrade that passes jitDegrade's own early return (it is counted and printed) is held
# against the innermost statement mark (jitStmtBegin / jitStmtEnd). At that statement's end:
#   handed  -- the statement (or an enclosing one, by propagation) was handed to run time: the promised run happens
#   FALSE   -- the OUTERMOST statement ended without a hand-over: "running INTERPRETED" never happened
#   nostmt  -- raised with no statement mark open (left at the end of jitBuildFunction)
# Each line: class, file, the caller's symbol (dladdr of the return address), the action under build, and the message.
# Lines are deduplicated per process with a count. Run ONLY in a branch-build clone; revert with git checkout, compare md5s.
def patch(p, old, new):
    s = open(p).read()
    assert s.count(old) == 1, (p, old[:60])
    open(p, 'w').write(s.replace(old, new))
    print('tapDegrade', p)

patch('jitContext.h', 'inline bool gJitHandOver = false;\n', '''inline bool gJitHandOver = false;
inline std::vector<std::pair<size_t, std::string>> gDgPend;
inline void dgEmit(const char *cls, const std::string &key) {
    static std::map<std::string, int> *seen = new std::map<std::string, int>();
    const char *f = ::getenv("INCANT_DGTAP"); if ( !f ) return;
    const char *k = ::getenv("INCANT_KLFILE");
    std::string line = std::string(cls) + "\\t" + (k ? k : "?") + "\\t" + key;
    (*seen)[line]++;
    FILE *fp = ::fopen(f, "a"); if ( fp ) { ::fprintf(fp, "%s\\n", line.c_str()); ::fclose(fp); } }
''')

patch('jitEmitters.rtn', '''    if ( gJitHandOver ) return gJitDegradeCount;
    ++gJitDegradeCount;''', '''    if ( gJitHandOver ) return gJitDegradeCount;
    ++gJitDegradeCount;
    if ( ::getenv("INCANT_DGTAP") ) {
        Dl_info dgI; const char *dgW = "?";
        if ( ::dladdr(__builtin_return_address(0), &dgI) && dgI.dli_sname ) dgW = dgI.dli_sname;
        std::string dgK = std::string(dgW) + "\\t" + (gJitCurrentAction && gJitCurrentAction->groupBody->tag ? gJitCurrentAction->groupBody->tag : "?")
                        + "\\t" + std::string(what ? what : "(unnamed)").substr(0, 70);
        gDgPend.push_back({gJitStmtMarks.size(), dgK}); }''')

patch('jitEmitters.rtn', '''    bool handed = gJitHandOver;
    gJitHandOver = m.outer;''', '''    bool handed = gJitHandOver;
    if ( ::getenv("INCANT_DGTAP") ) {
        size_t dgD = gJitStmtMarks.size() + 1;
        for ( auto it = gDgPend.begin(); it != gDgPend.end(); ) {
            if ( it->first < dgD ) { ++it; continue; }
            if ( handed )                 { ::dgEmit("handed", it->second); it = gDgPend.erase(it); }
            else if ( dgD == 1 )          { ::dgEmit("FALSE", it->second); it = gDgPend.erase(it); }
            else                          { it->first = dgD - 1; ++it; } } }
    gJitHandOver = m.outer;''')

patch('jitEmitters.rtn', '''    if (llvm::verifyFunction(*fn, &llvm::errs())) {
        fprintf(stderr,
            "=== jitRunAction: INVALID IR for %s -- REFUSING to run it ===\\n",''', '''    if ( ::getenv("INCANT_DGTAP") ) { for ( auto &dg : gDgPend ) ::dgEmit(dg.first ? "open" : "nostmt", dg.second); gDgPend.clear(); }
    if (llvm::verifyFunction(*fn, &llvm::errs())) {
        fprintf(stderr,
            "=== jitRunAction: INVALID IR for %s -- REFUSING to run it ===\\n",''')
