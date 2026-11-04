#!/usr/bin/env python3
# SEQ 524 R0: reads the tapped raw log; one row per (run, slotted-or-written local), classed by its writers, with kindless operands closed over.
import sys, re, collections
runs = collections.defaultdict(lambda: {'slot': {}, 'w': collections.defaultdict(set), 'holds': collections.defaultdict(set)})
for l in open(sys.argv[1], errors='replace'):
    p = l.split()
    if len(p) < 4: continue
    if p[0] == 'SLOT' and len(p) >= 6:
        runs[p[1]]['slot'][p[5]] = (p[2], p[3], p[4])
    elif p[0] == 'WRITER' and len(p) >= 6:
        runs[p[1]]['w'][p[2]].add(('W', p[3], p[4], p[5]))
    elif p[0] == 'FWRITER' and len(p) >= 6:
        runs[p[1]]['w'][p[2]].add(('F', p[3], p[4], 'kind=' + p[5]))
    elif p[0] == 'HOLDS' and len(p) >= 5:
        runs[p[1]]['holds'][(p[2], p[3])].add(p[4])
def cls(c):
    if c in ('vdouble', 'kind=9'): return 'number'
    if c in ('vint', 'kind=5'): return 'count'
    if c in ('cursor', 'holder'): return 'holder'
    if c in ('none', 'vnull', 'kind=-1'): return 'silent'
    if c.startswith('local='): return 'local'
    return 'nonscalar'
tot = collections.Counter(); rows = []
for run, r in runs.items():
    kinds = {b: {cls(w[3]) for w in ws} for b, ws in r['w'].items()}
    edges = {b: {w[3][6:].split(':')[0] for w in ws if cls(w[3]) == 'local'} for b, ws in r['w'].items()}
    ch = True
    while ch:
        ch = False
        for b, es in edges.items():
            for e in es:
                add = kinds.get(e, set()) & {'number', 'count', 'holder', 'nonscalar'}
                if add - kinds[b]: kinds[b] |= add; ch = True
    bodies = set(r['slot']) | set(kinds)
    for b in bodies:
        k = kinds.get(b, set())
        s = r['slot'].get(b)
        tag = s[1] if s else next(iter(r['w'][b]))[1]
        act = s[0] if s else '?'
        n, c = 'number' in k, 'count' in k
        klass = 'both' if n and c else 'number only' if n else 'count only' if c else 'neither:' + ('+'.join(sorted(k)) or 'no writer')
        slotted = bool(s)
        tot[(klass, slotted)] += 1
        rows.append((klass, slotted, run, act, tag, sorted(w[3] for w in r['w'][b]) if b in r['w'] else [], sorted(r['holds'].get((act, tag), []))))
print('class | slotted rows | unslotted rows')
for k in sorted({x[0] for x in tot}):
    print(k, '|', tot[(k, True)], '|', tot[(k, False)])
print('slotted total', sum(v for (k, s), v in tot.items() if s), 'runs', len(runs))
for r in sorted(rows, key=lambda x: (x[0], x[2], x[3], x[4])):
    if r[0] in ('both', 'number only'): print(r)
print('--- HOLDS: a local holding NUMBER (9) in an interpreted run')
for run, r in sorted(runs.items()):
    for (a, t), ks in sorted(r['holds'].items()):
        if '9' in ks: print(run, a, t, sorted(ks))
print('--- writers classed silent or local-with-no-kind, slotted')
for r in rows:
    if r[1] and r[0].startswith('neither'): print(r[0], r[2], r[3], r[4], r[5], r[6])
