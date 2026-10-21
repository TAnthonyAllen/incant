# SEQ 388 R3: every local of the pre-cure census (results/kindless.raw: slotted, kindless at build), classified after the
# cure from a tapInfer.py run. usage: python3 kindlessInferTable.py <pre-cure kindless.raw> <post-cure kl.all>
# Per (file, owner action, local):
#   inferred-scalar     still SLOTTED, and it holds only count / number at run time
#   inferred-nonscalar  NOSLOT (its writer made it non-scalar), and it holds a non-scalar at run time
#   refused             the net named it (NET) -- its action runs interpreted
#   WRONG               slotted but holds a non-scalar, or NOSLOT but holds only scalars
#   unobserved          classified at build, no run-time kind in any fixture (the same 4 actions as before the cure)
#   UNSEEN              not in the post-cure run at all
import sys, collections
SCALAR = {5, 9}
def load(path):
    slot, noslot, net, holds = {}, {}, set(), collections.defaultdict(set)
    for l in open(path).read().split('\n'):
        w = l.split()
        if not w: continue
        if w[0] == 'SLOT':   slot[(w[1], w[2], w[3])] = int(w[4])
        elif w[0] == 'NOSLOT': noslot[(w[1], w[2], w[3])] = int(w[4])
        elif w[0] == 'NET':  net.add((w[1], w[2], w[3]))
        elif w[0] == 'HOLDS': holds[(w[2], w[3])].add((w[1], int(w[4])))
    return slot, noslot, net, holds
pre_slot, _, _, pre_holds = load(sys.argv[1])
slot, noslot, net, holds = load(sys.argv[2])
pop = sorted(k for k, kd in pre_slot.items() if kd == 0)
rows = []
for (f, o, n) in pop:
    h = holds.get((o, n), set()) | pre_holds.get((o, n), set())
    same = {k for (hf, k) in h if hf == f}
    kinds = (same if same else {k for (hf, k) in h}) - {0}
    if (f, o, n) in net:          cls = 'refused'
    elif (f, o, n) in noslot:     cls = 'unobserved' if not kinds else ('inferred-nonscalar' if not kinds <= SCALAR else 'WRONG')
    elif (f, o, n) in slot:       cls = 'unobserved' if not kinds else ('inferred-scalar' if kinds <= SCALAR else 'WRONG')
    else:                         cls = 'UNSEEN'
    rows.append((cls, f, o, n, sorted(kinds), noslot.get((f, o, n))))
c = collections.Counter(r[0] for r in rows)
print(f'pre-cure census: {len(pop)} locals (file x action x local), {len({(r[2], r[3]) for r in rows})} distinct, {len({r[1] for r in rows})} files')
for k in ('inferred-scalar', 'inferred-nonscalar', 'refused', 'unobserved', 'WRONG', 'UNSEEN'):
    s = [r for r in rows if r[0] == k]
    print(f'  {k:20s} {len(s):4d}   distinct {len({(r[2], r[3]) for r in s}):3d}   files {len({r[1] for r in s}):3d}')
print('\nby (action, local):')
agg = collections.defaultdict(lambda: [collections.Counter(), set(), set()])
for r in rows:
    a = agg[(r[2], r[3])]; a[0][r[0]] += 1; a[1].update(r[4]); a[2].add(r[5])
for (o, n), (cc, ks, nk) in sorted(agg.items()):
    print(f'  {o:16s} {n:18s} {" ".join(f"{k}x{v}" for k, v in sorted(cc.items())):40s} holds {"/".join(map(str, sorted(ks))) or "-":8s} recorded {"/".join(str(x) for x in sorted(x for x in nk if x is not None)) or "-"}')
print('\nnew in the post-cure run (slotted kindless or NOSLOT, not in the pre-cure census):')
for k in sorted((set(k for k, kd in slot.items() if kd == 0) | set(noslot)) - set(pop)): print('  ', *k)
