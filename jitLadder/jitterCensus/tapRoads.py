# SEQ 386 R2(a): name every caller of processAction (dladdr of the return address). Gated by INCANT_ROADTAP=<file>.
p='GroupActions.rtn'; s=open(p).read()
old='''    if isLabel      action = field.labelOf;
    currentMETHOD.group = action;
'''
new=old+'''    -%
    { static const char *rt = ::getenv("INCANT_ROADTAP");
      if ( rt ) { Dl_info di; const char *who = "?";
        if ( ::dladdr(__builtin_return_address(0), &di) && di.dli_sname ) who = di.dli_sname;
        FILE *rf = ::fopen(rt,"a"); if ( rf ) { ::fprintf(rf,"%s %s label=%d jitting=%d\\n", who, action->groupBody->tag, (int)field->groupBody->flags.isLabel, GroupControl::groupController->groupRules->jitting); ::fclose(rf); } } }
    %-
'''
assert s.count(old)==1; open(p,'w').write(s.replace(old,new)); print('tapRoads ok')
