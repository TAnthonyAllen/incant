import lldb, os
def ev(f, e):
    v = f.EvaluateExpression(e)
    return v
def carriers(debugger, command, result, d):
    f = debugger.GetSelectedTarget().GetProcess().GetSelectedThread().GetSelectedFrame()
    root = ev(f, 'GroupControl::groupController->getRegistry((char*)"Grokking")->get((char*)"DO")').GetValueAsUnsigned()
    seen=set(); out=[]; cseen=set()
    stack=[root]
    while stack:
        n=stack.pop()
        if n in seen: continue
        seen.add(n)
        tag = ev(f, '((GroupItem*)%d)->groupBody->tag'%n).GetSummary()
        c = ev(f, '((GroupItem*)%d)->get((char*)"builtinParseR")'%n).GetValueAsUnsigned()
        if c and c not in cseen:
            cseen.add(c); out.append((c,tag))
        kids=[]; k=0
        while True:
            k = ev(f, '((GroupItem*)%d)->next((GroupItem*)%d)'%(n,k)).GetValueAsUnsigned()
            if not k: break
            np = ev(f, '(int)((GroupItem*)%d)->groupBody->flags.noPrint'%k).GetValueAsSigned()
            ir = ev(f, '(int)((GroupItem*)%d)->groupBody->flags.isRule'%k).GetValueAsSigned()
            if np or not ir: continue
            kids.append(k)
        stack.extend(reversed(kids))
    idx = int(os.environ.get('JIT_PICK','-1'))
    if os.environ.get('JIT_ALL'):
        for i,(c,t) in enumerate(out):
            r = ev(f, '(int)jitRunAction((GroupItem*)%d)'%c)
            print("ALLRESULT %d %s %s"%(i,t,r.GetValueAsSigned()))
        return
    if idx < 0:
        for i,(c,t) in enumerate(out): print("CARRIER %d %s"%(i,t))
        print("CARRIERS %d"%len(out))
    else:
        c,t = out[idx]
        print("PICK %d %s"%(idx,t))
        r = ev(f, '(int)jitRunAction((GroupItem*)%d)'%c)
        print("PICKRESULT %d %s %s"%(idx,t,r.GetValueAsSigned()))
def __lldb_init_module(debugger, d):
    debugger.HandleCommand('command script add -f walk.carriers carriers')
