# The kindless-local census table (2026-10-20) -- reads tapKindless.py's output (one file, every run appended).
# usage: python3 kindlessTable.py <kl.all>
# A local is KINDLESS when the frame prologue slots it with kind 0 (SLOT ... 0). Its run-time kinds come from HOLDS lines
# (interpreted statements), joined on (owner action, local name): first in the same fixture, else in any fixture (a
# jitted fixture's interpreted twin is often another file -- pop.sh's sed copy -- so the name differs).
# INFERABLE (a non-scalar kind whose right side IS known at build): an iterate cursor (ITER), a `:=` / `<-` (a holder by
# the operator), or an assign whose right side's kind at build is known and non-scalar.
import sys, collections
SCALAR = {5, 9}; NAMES = {0:'none',1:'ANY',2:'CHAR',3:'SET',4:'BUFFER',5:'COUNT',6:'GROUP',7:'ITEM',8:'MAP',9:'NUMBER',
         10:'OBJECT',11:'REGEX',12:'STAK',13:'STRING',14:'TOKEN'}
slot, holds, assigns, iters = {}, collections.defaultdict(set), collections.defaultdict(list), set()
lines = open(sys.argv[1]).read().split('\n')
for l in lines:
    w = l.split()
    if not w: continue
    if w[0] == 'SLOT':   slot[(w[1], w[5])] = (w[2], w[3], int(w[4]))           # (file, body) -> owner, local, kind
for l in lines:
    w = l.split()
    if not w: continue
    if w[0] == 'HOLDS':  holds[(w[2], w[3])].add((w[1], int(w[4])))           # (owner, local) -> {(file, kind)}
    elif w[0] == 'ASSIGN':
        o = slot.get((w[1], w[2]))
        if o: assigns[(w[1], o[0], o[1])].append((w[4], int(w[5].split('=')[1]), w[8]))  # op, argKind, node
    elif w[0] == 'ITER':
        o = slot.get((w[1], w[2]))
        if o: iters.add((w[1], o[0], o[1]))
kindless = sorted({(f, o, n) for (f, b), (o, n, k) in slot.items() if k == 0})
slotted  = sorted({(f, o, n) for (f, b), (o, n, k) in slot.items()})
rows = []
for (f, o, n) in kindless:
    h = holds.get((o, n), set())
    same = {k for (hf, k) in h if hf == f}
    kinds = (same if same else {k for (hf, k) in h}) - {0}
    where = 'same' if same else ('other' if h else 'none')
    if not kinds:                     cls = 'unobserved'
    elif kinds <= SCALAR:             cls = 'scalar'
    else:
        a = assigns.get((f, o, n), [])
        inf = (f, o, n) in iters or any(op in (':=', '<-') for op, ak, nd in a) \
              or any(ak not in (0, -1, 5, 9) for op, ak, nd in a)
        cls = 'nonscalar-inferable' if inf else 'nonscalar-UNINFERABLE'
    rows.append((cls, f, o, n, '/'.join(NAMES[k] for k in sorted(kinds)) or '-', where,
                 ';'.join(sorted({f'{op}{NAMES.get(ak, ak) if ak >= 0 else "?"}' for op, ak, nd in assigns.get((f, o, n), [])}))
                 + (' iterate' if (f, o, n) in iters else '')))
print(f'locals slotted by the prologue: {len(slotted)}   kindless at build: {len(kindless)}')
c = collections.Counter(r[0] for r in rows)
for k in ('scalar', 'nonscalar-inferable', 'nonscalar-UNINFERABLE', 'unobserved'): print(f'  {k:24s} {c[k]}')
print('  run-time kinds found in: same fixture', sum(r[5] == 'same' for r in rows), '/ another fixture',
      sum(r[5] == 'other' for r in rows), '/ none', sum(r[5] == 'none' for r in rows))
print('\nNON-SCALAR, by class, file and action:')
for r in sorted(rows):
    if r[0].startswith('nonscalar'): print(f'  {r[0]:22s} {r[1]:28s} {r[2]:22s} {r[3]:18s} holds {r[4]:14s} written by: {r[6] or "(no assign seen at build)"}')
def reach(sel):
    s = [r for r in rows if sel(r)]
    return len(s), len({(r[1], r[2]) for r in s}), len({r[1] for r in s})
print('\nREACH (locals, actions as file+action, files):')
print('  (a) every kindless read hands over        ', reach(lambda r: True))
print('  (b) inferably non-scalar: no scalar slot   ', reach(lambda r: r[0] == 'nonscalar-inferable'))
print('  (c) uninferable non-scalar: NOT JITTABLE   ', reach(lambda r: r[0] == 'nonscalar-UNINFERABLE'))
print('  unobserved (no interpreted run seen)       ', reach(lambda r: r[0] == 'unobserved'))
