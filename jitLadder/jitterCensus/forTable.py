# SEQ 390 R1 (b), (c): the for statement's writers, from a tapKindless + tapInfer + tapFor run.
# usage: python3 forTable.py <kl.all>
# Cursor locals come from FORGATE (the build) and FORCUR (the run); body writes from FORBODY (the run). Each is joined to the
# build's view of the same local -- SLOT (slotted, kindless), NOSLOT (a recorded non-scalar), NET (refused) -- in the same
# file by body pointer (FORGATE) or by owner and name (FORBODY, FORCUR), and to its run-time kinds (HOLDS, FORCUR).
import sys, collections
N = {0:'none',1:'ANY',2:'CHAR',3:'SET',4:'BUFFER',5:'COUNT',6:'GROUP',7:'ITEM',8:'MAP',9:'NUMBER',10:'OBJECT',11:'REGEX',
     12:'STAK',13:'STRING',14:'TOKEN'}
slotB, slotN, noslotN, netN = {}, set(), set(), set()
holds = collections.defaultdict(set); curRT = collections.defaultdict(set)
gate = []; body = collections.defaultdict(lambda: collections.Counter())
for l in open(sys.argv[1]):
    w = l.split()
    if not w: continue
    t = w[0]
    if t == 'SLOT':    slotB[(w[1], w[5])] = (w[2], w[3]); slotN.add((w[1], w[2], w[3]))
    elif t == 'NOSLOT': noslotN.add((w[1], w[2], w[3]))
    elif t == 'NET':   netN.add((w[1], w[2], w[3]))
    elif t == 'HOLDS': holds[(w[2], w[3])].add(int(w[4]))
    elif t == 'FORGATE': gate.append((w[1], w[3], w[4], int(w[5])))
    elif t == 'FORCUR':  curRT[(w[2], w[3])].add(int(w[5]))
    elif t == 'FORBODY': body[(w[1], w[2], w[3])][w[5]] += 1
def build(f, o, n):
    if (f, o, n) in netN: return 'NET'
    if (f, o, n) in noslotN: return 'NOSLOT'
    if (f, o, n) in slotN: return 'SLOT'
    return '-'
def kinds(s): return '/'.join(N[k] for k in sorted(s - {0})) or '-'
print('(b) FOR CURSORS AT BUILD (FORGATE), joined to the build view and to the run-time kinds')
rows = collections.defaultdict(lambda: [set(), set(), set()])
for f, tag, b, kd in gate:
    o, n = slotB.get((f, b), ('?', tag))
    r = rows[(o, n)]; r[0].add(f); r[1].add(build(f, o, n)); r[2].add(kd)
for (o, n), (fs, bs, kds) in sorted(rows.items()):
    print(f'  {o:18s} {n:12s} files {len(fs):2d}  build {"/".join(sorted(bs)):12s} kind at build {kinds(kds) if kds - {0} else "none":6s}'
          f'  cursor at run {kinds(curRT.get((o, n), set())):8s} holds {kinds(holds.get((o, n), set()))}')
print('\n    every cursor kind at run (FORCUR, all files):', dict(collections.Counter(N[k] for s in curRT.values() for k in s)))
bad = [(k, v) for k, v in curRT.items() if v - {6}]
print('    cursors holding anything but GROUP at run:', bad or 'none')
print('\n(c) LOCALS WRITTEN INSIDE A FOR BODY (FORBODY), by file -- build view in that file, run-time kinds')
agg = collections.defaultdict(lambda: [set(), collections.Counter(), set()])
for (f, o, n), ops in body.items():
    a = agg[(o, n)]; a[0].add(f); a[1].update(ops); a[2].add(build(f.replace('.plain', '.gjit'), o, n) if f.endswith('.plain') else build(f, o, n))
for (o, n), (fs, ops, bs) in sorted(agg.items()):
    print(f'  {o:18s} {n:14s} files {len(fs):2d}  ops {dict(ops)}  build {"/".join(sorted(bs)):14s} holds {kinds(holds.get((o, n), set()))}')
