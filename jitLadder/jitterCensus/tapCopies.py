# Docket item 1 R0 (2026-10-20): every node copy made WHILE JITTING whose source carries JitData. Three copy roads,
# each drops the jit value: setContent, the GroupItem copy constructor, copyOf. Gated by INCANT_COPYTAP=<file>; a
# line per copy: road, caller (dladdr), return-address offset into the image (for atos -> .mm line), source tag.
# Run ONLY in a branch-build clone; revert with git checkout and compare md5s.
TAP = '''    -%
    { static const char *ct = ::getenv("INCANT_COPYTAP");
      if ( ct && SRC && SRC->jitData && GroupControl::groupController && GroupControl::groupController->groupRules
           && GroupControl::groupController->groupRules->jitting ) {
        Dl_info di; const char *who = "?"; long off = 0; void *ra = __builtin_return_address(0);
        if ( ::dladdr(ra, &di) ) { if ( di.dli_sname ) who = di.dli_sname; off = (char*)ra - (char*)di.dli_fbase; }
        FILE *cf = ::fopen(ct,"a");
        if ( cf ) { ::fprintf(cf,"ROAD %s 0x%lx %s\\n", who, off, SRC->groupBody && SRC->groupBody->tag ? SRC->groupBody->tag : "?"); ::fclose(cf); } } }
    %-
'''
def patch(p, old, road, src):
    s = open(p).read()
    assert s.count(old) == 1, (p, road)
    tap = TAP.replace('ROAD', road).replace('SRC', src)
    open(p, 'w').write(s.replace(old, old + tap))
    print('tapCopies', p, road)

patch('GroupItem.twk', 'void setContent(GroupItem item)\n{\n', 'setContent', 'item')
patch('GroupItem.twk', 'GroupItem(GroupItem grup)\n{\n    groupBody   = grup.groupBody;\n', 'copyCtor', 'grup')
patch('Commands.rtn', 'extern GroupItem copyOf(GroupItem grup)\n{\nGroupItem block = new;\n', 'copyOf', 'grup')
