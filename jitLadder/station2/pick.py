# pick.py <calres file> -- choose certificate inputs from one rule's calibration rows.
# The rule is judged by ITS OWN FIRES, not the root's verdict:
#   ACCEPT = the rule fired and every fire succeeded;  REJECT = it fired and none did.
# Up to two accepts (different consumed preferred, so a folded value cannot pass) and
# up to two rejects (most term calls first). Prints <root>|<input> per line.
import re, sys
rows = []
for l in open(sys.argv[1]):
    m = re.search(r'ROW CAL \d+ (\w+)\|"((?:[^"\\]|\\.)*)" v=(-?\d+) c=(-?\d+) t=(-?\d+) fires=(-?\d+) true=(-?\d+)', l)
    if m:
        s = m.group(2).replace('\\"', '"').replace('\\\\', '\\')
        rows.append((m.group(1), s, int(m.group(3)), int(m.group(4)), int(m.group(5)), int(m.group(6)), int(m.group(7))))
acc = [r for r in rows if r[5] > 0 and r[6] == r[5]]
rej = [r for r in rows if r[5] > 0 and r[6] == 0]
out = []
acc.sort(key=lambda r: (-r[3], -r[4]))
if acc:
    out.append(acc[0])
    other = [r for r in acc[1:] if r[3] != acc[0][3]]
    if other: out.append(other[-1])
rej.sort(key=lambda r: -r[4])
out += rej[:2]
for r in out: print('%s|%s' % (r[0], r[1].replace('\n', '\\n')))
