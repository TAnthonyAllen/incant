def rep(p, old, new):
    s=open(p).read(); assert s.count(old)==1,(p,old[:50],s.count(old)); open(p,'w').write(s.replace(old,new))
# helpers, before jitOpEmits
rep('jitEmitters.rtn','/*  jitOpEmits -- WILL THIS DISPATCH','''// jitTapBX SEQ 384 census TAP (clone only, reverted)
extern void jitTapBX(String kind, String a, String b)
{
    -%
    static const char *f = ::getenv("INCANT_BUILDEXEC");
    if ( !f ) return;
    GroupRules *r = GroupControl::groupController->groupRules;
    if ( !r->jitting || !gJitEmitWalk ) return;
    FILE *t = fopen(f,"a");
    if ( !t ) return;
    fprintf(t,"%s %s %s stmt=%p action=%s\\n", kind, a ? a : "-", b ? b : "-", (void*)gJitStmt,
            gJitCurrentAction ? gJitCurrentAction->groupBody->tag : "-");
    fclose(t);
    %-
}

extern int jitTapInsts()
{
    -%
    if ( !GroupControl::groupController->groupRules->jitting || !gJitEmitWalk ) return 0;
    if ( !gJitBuilder || !gJitBuilder->GetInsertBlock() || !gJitBuilder->GetInsertBlock()->getParent() ) return 0;
    return (int)gJitBuilder->GetInsertBlock()->getParent()->getInstructionCount();
    %-
}

/*  jitOpEmits -- WILL THIS DISPATCH''')
p='ruleActions.rtn'; s=open(p).read()
import re
for kind,frag in [('cerr','cerr under jit -- no emitter, it runs'),('cout','cout under jit -- no emitter, it runs'),('stringXP','string expression under jit'),('FOR','FOR under jit'),('search','search under jit')]:
    i=s.index('jitHandOver("'+frag); j=s.index('return null; }\n',i)+len('return null; }\n')
    s=s[:j]+'    -% ::jitTapBX("sink","'+kind+'",0); %-\n'+s[j:]
open(p,'w').write(s)
rep('GroupActions.rtn','''    // dispatchSeat which node the name reached, and which arm the fork will take
    measureRuleDispatch(op,target,arg);
    // callExecutor an operator fires as itself; anything else whose target is callable is a CALL, and opCall is its one executor (SEQ 318 c2)
    if op.isOperator                result = op.operat(arg,target);
    or op.isMethod                  result = op.method(target);
    or isCallable(target)           result = opCall(target,arg);
    else    result = refuseUnknownOperator(op,target);
    return result;''','''    // dispatchSeat which node the name reached, and which arm the fork will take
    measureRuleDispatch(op,target,arg);
    -% int bxBefore = ::jitTapInsts(); if ( target && !isOperator(op->groupBody->flags.instructType) && isMethod(target->groupBody->flags.instructType) && !target->groupBody->flags.actionType && (void*)target->groupBody->gMethod != (void*)&jitTrace ) ::jitTapBX("cmd", target->groupBody->tag, 0); %-
    // callExecutor an operator fires as itself; anything else whose target is callable is a CALL, and opCall is its one executor (SEQ 318 c2)
    if op.isOperator                result = op.operat(arg,target);
    or op.isMethod                  result = op.method(target);
    or isCallable(target)           result = opCall(target,arg);
    else    result = refuseUnknownOperator(op,target);
    -% if ( ::jitTapInsts() == bxBefore && !(result && result->jitData && result->jitData->jitValue && llvm::isa<llvm::Constant>(result->jitData->jitValue)) ) ::jitTapBX("op", op ? op->groupBody->tag : 0, target ? target->groupBody->tag : 0); %-
    return result;''')
print('tap3 ok')
