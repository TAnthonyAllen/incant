p='GroupActions.rtn'; s=open(p).read()
old='''    -%
    GroupControl::groupController->groupRules->chanBinds++;
    if ( ruleArg->groupBody->gGroup == argument ) GroupControl::groupController->groupRules->chanSame++;
    %-
    result = processAction(field);
'''
new='''    -%
    GroupControl::groupController->groupRules->chanBinds++;
    if ( ruleArg->groupBody->gGroup == argument ) GroupControl::groupController->groupRules->chanSame++;
    {
    static const char *tapFile = ::getenv("INCANT_JIT_ALL");
    static std::map<GroupBody*, int(*)(GroupItem*)> tapFn;
    static std::set<GroupBody*> tapNo;
    static int tapBusy = 0;
    static const char *tapAfter = ::getenv("INCANT_JIT_ALL_AFTER");
    static int tapArmed = tapAfter ? 0 : 1;
    bool tapRan = false;
    if ( tapFile && tapArmed && !tapBusy && !GroupControl::groupController->groupRules->jitting ) {
        GroupBody *tb = field->groupBody;
        int (*fn)(GroupItem*) = nullptr;
        auto it = tapFn.find(tb);
        if ( it != tapFn.end() ) fn = it->second;
        else if ( !tapNo.count(tb) ) {
            tapBusy = 1;
            { FILE *tf0 = fopen(tapFile,"a"); if ( tf0 ) { fprintf(tf0,"begin %s\\n", tb->tag); fclose(tf0); } }
            int (*saveFn)(GroupItem*) = gJitLastFn; GroupItem *saveAct = gJitLastAction;
            int deg0 = gJitDegradeCount;
            fflush(stdout); fflush(stderr);
            std::string tapErr = std::string(tapFile) + ".err";
            int so = dup(1), se = dup(2), dn = open("/dev/null", O_WRONLY);
            int de = open(tapErr.c_str(), O_WRONLY | O_CREAT | O_APPEND, 0644);
            dup2(dn,1); dup2(de,2); close(de);
            gJitCompileOnly = 1;
            int rc = ::jitRunAction(field);
            gJitCompileOnly = 0;
            fflush(stdout); fflush(stderr);
            dup2(so,1); dup2(se,2); close(so); close(se); close(dn);
            if ( rc >= 0 && gJitLastAction == field ) fn = gJitLastFn;
            gJitLastFn = saveFn; gJitLastAction = saveAct;
            if ( fn ) tapFn[tb] = fn; else tapNo.insert(tb);
            FILE *tf = fopen(tapFile,"a");
            if ( tf ) { fprintf(tf,"compile %s rc=%d degrade=%d\\n", tb->tag, rc, gJitDegradeCount - deg0); fclose(tf); }
            GroupControl::groupController->groupRules->refused = 0;
            tapBusy = 0; }
        if ( fn ) {
            { FILE *tf1 = fopen(tapFile,"a"); if ( tf1 ) { fprintf(tf1,"fire %s\\n", tb->tag); fclose(tf1); } }
            int r = fn(::jitBodyField(field));
            result = ::jitBoxCountRT(r);
            tapRan = true; } }
    if ( !tapRan ) result = ::processAction(field);
    if ( !tapArmed && tapAfter && !::strcmp(field->groupBody->tag, tapAfter) ) tapArmed = 1;
    }
    %-
'''
assert s.count(old)==1; open(p,'w').write(s.replace(old,new)); print('tap383 ok')
