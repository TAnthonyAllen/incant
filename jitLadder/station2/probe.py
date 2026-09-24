# lldb module: jitter station 2's sweep. Stops after parser(DO) (the lldb script
# ⚠ DEBUGGING ONLY since 2026-09-24: measurements use the native probeDrive command (incant/pop/probeDoorT).
# sets that breakpoint), walks the carriers reachable from DO exactly as
# carrierRecon/walk.py does, then CALIBRATES (interpreted only) or CERTIFIES
# (jitted first, then the oracle) one carrier.
#   env PICK=<index>  MODE=cal|cert  INPUTS=<file>
#   cal : INPUTS lines are  <root>|<input>  (jitLadder/station2/pairs).
#   cert: INPUTS lines are  <root>|<input>.
# THE RULE UNDER TEST IS WATCHED, NOT DRIVEN. A top-level drive of a member rule
# refuses on the interpreted road ("no enclosing activation to take the label"),
# so every drive starts at a ROOT -- StatemenT or ExpressioN, the two that drive
# cleanly -- and the door in parseRule watches this carrier wherever it fires.
import lldb, os
ROOTS = ('StatemenT', 'ExpressioN')
def ev(f, e, t=None):
    o = lldb.SBExpressionOptions()
    o.SetIgnoreBreakpoints(True); o.SetUnwindOnError(True)
    if t: o.SetTimeoutInMicroSeconds(t)
    return f.EvaluateExpression(e, o)
def cstr(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'
def carriers(f):
    root = ev(f, 'GroupControl::groupController->getRegistry((char*)"Grokking")->get((char*)"DO")').GetValueAsUnsigned()
    seen=set(); out=[]; cseen=set(); stack=[root]
    while stack:
        n=stack.pop()
        if n in seen: continue
        seen.add(n)
        c = ev(f, '((GroupItem*)%d)->get((char*)"builtinParseR")'%n).GetValueAsUnsigned()
        if c and c not in cseen:
            cseen.add(c); out.append((c, n))
        kids=[]; k=0
        while True:
            k = ev(f, '((GroupItem*)%d)->next((GroupItem*)%d)'%(n,k)).GetValueAsUnsigned()
            if not k: break
            if ev(f, '(int)((GroupItem*)%d)->groupBody->flags.noPrint'%k).GetValueAsSigned(): continue
            if not ev(f, '(int)((GroupItem*)%d)->groupBody->flags.isRule'%k).GetValueAsSigned(): continue
            kids.append(k)
        stack.extend(reversed(kids))
    return out
def rootNode(f, name):
    return ev(f, 'GroupControl::groupController->getRegistry((char*)"Grokking")->get((char*)"%s")' % name).GetValueAsUnsigned()
def one(f, root, armed, s, jitted):
    r = ev(f, '(int)jitProbeDrive((GroupItem*)%d, (GroupItem*)%d, (char*)%s, %d)' % (root, armed, cstr(s), jitted), 20*1000*1000)
    if not r.GetError().Success():
        return ('ERR', r.GetError().GetCString().strip().splitlines()[0][:90])
    g = lambda n: ev(f, '(int)'+n).GetValueAsSigned()
    return (g('gProbeVerdict'), g('gProbeConsumed'), g('gProbeTerms'), g('gProbeFires'), g('gProbeTrue'))
def fmt(v): return 'v=%d c=%d t=%d fires=%d true=%d' % v
def run(debugger, command, result, d):
    t = debugger.GetSelectedTarget()
    t.DisableAllBreakpoints()
    f = t.GetProcess().GetSelectedThread().GetSelectedFrame()
    cs = carriers(f)
    i = int(os.environ['PICK']); mode = os.environ['MODE']
    c, walked = cs[i]
    tag = ev(f, '((GroupItem*)%d)->groupBody->tag'%walked).GetSummary()
    roots = dict((r, rootNode(f, r)) for r in ROOTS)
    print('CARRIERS %d PICK %d %s' % (len(cs), i, tag))
    lines = [l.rstrip('\n') for l in open(os.environ['INPUTS']) if l.strip()]
    if mode == 'cal':
        #  cal INPUTS are <root>|<input> pairs: the pairs that crash the INTERPRETED road
        #  do so whichever rule is watched, so they are measured once (crashpairs) and
        #  left out, rather than relaunching lldb for every rule that meets them.
        for k, l in enumerate(lines):
            r, s = l.split('|', 1); s = s.replace('\\n', '\n')
            v = one(f, roots[r], walked, s, 0)
            if v[0] == 'ERR':
                print('ROW CRASH %d %s|%s %s' % (k, r, cstr(s), v[1])); return
            print('ROW CAL %d %s|%s %s' % (k, r, cstr(s), fmt(v)))
        print('ROW CALDONE')
    else:
        for jitted in (1, 0):
            for l in lines:
                r, s = l.split('|', 1); s = s.replace('\\n', '\n')
                for fire in (1, 2):
                    v = one(f, roots[r], walked, s, jitted)
                    if v[0] == 'ERR':
                        print('ROW CRASH %s %s|%s fire%d %s' % ('J' if jitted else 'I', r, cstr(s), fire, v[1])); return
                    print('ROW %s %s|%s fire%d %s' % ('J' if jitted else 'I', r, cstr(s), fire, fmt(v)))
        print('ROW CERTDONE')
def __lldb_init_module(debugger, d):
    debugger.HandleCommand('command script add -f probe.run probe')
