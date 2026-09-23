# compare.py <certres file> -- one verdict line for one rule's certificate.
# Every jitted row must equal its interpreted twin (same root, input, fire) on ALL of
# verdict, consumed, term calls, the rule's fires and its successes. The term count is
# the short-circuit witness: values can agree while a right operand runs anyway.
# UNCERTIFIED when there is no accepting input, or no rejecting input, or no row.
import re, sys
f = sys.argv[1]; txt = open(f).read()
tag = (re.search(r'PICK \d+ "([^"]*)"', txt) or [None, '?'])[1]
rows = re.findall(r'ROW ([JI]) (\w+\|"(?:[^"\\]|\\.)*") (fire\d) (v=\S+ c=\S+ t=\S+ fires=\S+ true=\S+)', txt)
J = {(k, fi): v for s, k, fi, v in rows if s == 'J'}; I = {(k, fi): v for s, k, fi, v in rows if s == 'I'}
crash = re.findall(r'ROW CRASH .*', txt)
picks = [l.rstrip('\n') for l in open(sys.argv[2])] if len(sys.argv) > 2 else []
nacc = sum(1 for k in I if re.search(r'fires=([1-9]\d*) true=\1\b', I[k]))
nrej = sum(1 for k in I if re.search(r'fires=[1-9]\d* true=0\b', I[k]))
bad = [(k, J.get(k), I.get(k)) for k in sorted(set(J) | set(I)) if J.get(k) != I.get(k)]
if crash:                           verdict = 'CRASH ' + crash[0][:120]
elif 'CERTDONE' not in txt:         verdict = 'INCOMPLETE'
elif bad:                           verdict = 'DISAGREE %d rows' % len(bad)
elif nacc == 0 or nrej == 0:        verdict = 'UNCERTIFIED (accepts %d, rejects %d)' % (nacc // 2, nrej // 2)
else:                               verdict = 'AGREE (%d rows; accepts %d, rejects %d)' % (len(J), nacc // 2, nrej // 2)
print('%-13s %s' % (tag, verdict))
for k, j, i in bad[:4]: print('     %s %s\n       J %s\n       I %s' % (k[0], k[1], j, i))
