import re
def patch(p, old, new, count=1):
    s=open(p).read(); assert s.count(old)==count, (p, old[:60], s.count(old)); open(p,'w').write(s.replace(old,new))
TAP='''extern void jitSiteTap(int site,GroupItem node)
{
    -%
    static const char *tf = ::getenv("INCANT_SITETAP");
    if ( !tf ) return;
    GroupRules *r = GroupControl::groupController->groupRules;
    if ( !r->jitting ) return;
    GroupBody *b = node ? node->groupBody : 0;
    const char *act = gJitCurrentAction ? gJitCurrentAction->groupBody->tag : "?";
    FILE *f = ::fopen(tf,"a");
    if ( f ) { ::fprintf(f,"S%d %s %s data=%d grp=%d iter=%d null=%d\\n", site, act, b ? b->tag : "NULL", b ? (int)b->flags.data : -1,
                         b ? (int)isGROUP(b->flags.data) : 0, b ? (int)b->flags.isIterator : 0, node ? 0 : 1); ::fclose(f); }
    %-
}

/*******************************************************************************
    jitBuildFunction -- ONE FUNCTION, START TO FINISH.'''
patch('jitEmitters.rtn','''/*******************************************************************************
    jitBuildFunction -- ONE FUNCTION, START TO FINISH.''', TAP)
# S1 aCTionIterate: source null / pointer refusal / no list
patch('ruleActions.rtn','''    if !source {
        // nullAfterStar''','''    -% ::jitSiteTap(1, source); %-
    if !source {
        // nullAfterStar''')
# S2 opPlusPlus / opMinusMinus at entry
s=open('Instruct.rtn').read()
s=s.replace('''    measurePlusPlusWrite(result);
''','''    measurePlusPlusWrite(result);
    -% ::jitSiteTap(2, result); %-
''',1)
open('Instruct.rtn','w').write(s)
patch('Instruct.rtn','''extern GroupItem opMinusMinus(GroupItem result)
{
GroupRules  ruler = groupRules;
''','''extern GroupItem opMinusMinus(GroupItem result)
{
GroupRules  ruler = groupRules;
    -% ::jitSiteTap(2, result); %-
''')
# S3 opDeref
patch('Instruct.rtn','''    if jitting {
        -% if (!::jitEmitDeref(result))''','''    -% ::jitSiteTap(3, result); %-
    if jitting {
        -% if (!::jitEmitDeref(result))''')
# S4 jitEmitDot target
patch('jitEmitters.rtn','''extern GroupItem jitEmitDot(GroupItem argument,GroupItem target,GroupItem resultNode)
{
    -%''','''extern GroupItem jitEmitDot(GroupItem argument,GroupItem target,GroupItem resultNode)
{
    -%
    ::jitSiteTap(4, target);''')
# S5 followArgument: slot read null, argument holder
patch('GroupActions.rtn','''        GroupItem *slotRead = ::jitArgSlotRead(operand);
        if ( slotRead ) return slotRead; }''','''        GroupItem *slotRead = ::jitArgSlotRead(operand);
        if ( slotRead ) return slotRead;
        if ( operand && operand->groupBody->flags.isArgument ) ::jitSiteTap(5, isGROUP(operand->groupBody->flags.data) ? operand->getGroup() : 0); }''')
# S6 jitEmitBareRead
patch('jitEmitters.rtn','''        GroupItem *slotRead = jitArgSlotRead(token);
        if (slotRead)   token = slotRead;
        else if ( token->groupBody->flags.isArgument && isGROUP(token->groupBody->flags.data) )
            token = token->getGroup();''','''        GroupItem *slotRead = jitArgSlotRead(token);
        if (slotRead)   token = slotRead;
        else if ( token->groupBody->flags.isArgument && isGROUP(token->groupBody->flags.data) )
            token = token->getGroup();
        ::jitSiteTap(6, token);''')
# S7 jitSeedField entry
s=open('jitEmitters.rtn').read()
i=s.index('extern GroupItem jitSeedField(GroupItem token)'); j=s.index('-%',i)+2
s=s[:j]+'\n    ::jitSiteTap(7, token);'+s[j:]; open('jitEmitters.rtn','w').write(s)
# S8 prologue
patch('jitEmitters.rtn','''            if (isNUMBER(fb->flags.data)) { ty = llvm::Type::getDoubleTy(C); addr = &(fb->gNumber); }''','''            ::jitSiteTap(8, fld);
            if (isNUMBER(fb->flags.data)) { ty = llvm::Type::getDoubleTy(C); addr = &(fb->gNumber); }''')
# S9 arg slot
patch('jitEmitters.rtn','''        int bd = bound ? bound->groupBody->flags.data : 0;
''','''        int bd = bound ? bound->groupBody->flags.data : 0;
        if (af) ::jitSiteTap(9, bound);
''')
# S10 jitEmitAssign, S11 jitEmitAdd, S12 jitEmitSelfCall entries
for site,head in ((10,'extern GroupItem jitEmitAssign(GroupItem argument,GroupItem target)'),(11,'extern GroupItem jitEmitAdd(GroupItem argument,GroupItem target)'),(12,'extern GroupItem jitEmitSelfCall(GroupItem argument,GroupItem action)')):
    s=open('jitEmitters.rtn').read(); i=s.index(head); j=s.index('-%',i)+2
    var='argument' if site==12 else 'target'
    s=s[:j]+f'\n    ::jitSiteTap({site}, {var});'+s[j:]; open('jitEmitters.rtn','w').write(s)
# S13 jitPrintList parts
patch('jitEmitters.rtn','''        GroupBody *pb = part->groupBody;
        if (pb->flags.isLiteral || isSTRING(pb->flags.data) || isTOKEN(pb->flags.data)) {''','''        GroupBody *pb = part->groupBody;
        ::jitSiteTap(13, part);
        if (pb->flags.isLiteral || isSTRING(pb->flags.data) || isTOKEN(pb->flags.data)) {''')
print('sitetap ok')
