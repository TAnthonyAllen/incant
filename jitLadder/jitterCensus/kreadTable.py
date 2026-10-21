# SEQ 388 R1: summarise tapKindlessRead.py's KREAD lines against tapKindless.py's SLOT / HOLDS lines.
# usage: python3 kreadTable.py <kl.all>
# Per (owner action, local): the kinds it HOLDS at run time, and the loads of its frame slot in compiled code, split into
# VALUE reads (`frame`, jitSeedField's load -- the slot read AS A VALUE, with its users) and bookkeeping (rtFlush / rtOld /
# opFire* -- through the kind-checked helpers; epilog -- the raw store back to gCount, item 4's clobber).
import sys, re, collections
NAMES = {0:'none',1:'ANY',2:'CHAR',3:'SET',4:'BUFFER',5:'COUNT',6:'GROUP',7:'ITEM',8:'MAP',9:'NUMBER',10:'OBJECT',
         11:'REGEX',12:'STAK',13:'STRING',14:'TOKEN'}
slot, holds = {}, collections.defaultdict(set)
val = collections.defaultdict(lambda: collections.Counter()); book = collections.defaultdict(collections.Counter)
files = collections.defaultdict(set); unjoined = 0
L = open(sys.argv[1]).read().split('\n')
for l in L:
    w = l.split()
    if w and w[0] == 'SLOT': slot[(w[1], w[5])] = (w[2], w[3], int(w[4]))
for l in L:
    w = l.split()
    if not w: continue
    if w[0] == 'HOLDS': holds[(w[2], w[3])].add(int(w[4]))
    elif w[0] == 'KREAD':
        f, fn, body, tag, ty, nm, us = w[1], w[3], w[4], w[5], w[6], re.sub(r'\d+$', '', w[7]), w[8]
        o = slot.get((f, body))
        key = (o[0], o[1]) if o else ('?' + fn[4:], tag)
        if not o: unjoined += 1
        files[key].add(f.split('.')[0])
        if nm == 'frame': val[key][us.rstrip(',')] += 1
        else: book[key][nm] += 1
keys = sorted(set(val) | set(book))
print(f'{"action":16s} {"local":16s} {"holds":12s} {"files":>5s} {"VALUE reads (frame) by use":50s} bookkeeping')
for k in keys:
    h = '/'.join(NAMES[x] for x in sorted(holds.get(k, set()) - {0})) or '-'
    v = ' '.join(f'{u}x{n}' for u, n in sorted(val[k].items())) or '0'
    b = ' '.join(f'{u}x{n}' for u, n in sorted(book[k].items()))
    print(f'{k[0]:16s} {k[1]:16s} {h:12s} {len(files[k]):5d} {sum(val[k].values()):3d} {v:46s} {b}')
print('unjoined KREAD lines:', unjoined)
