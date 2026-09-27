#!/usr/bin/env python3
"""oldRoadOracle.py <corpus> <mode> <fixture> <keys>

Writes one column of sweepT's OLD-ROAD ORACLE (SEQ 211): every unique root|input in the corpus,
driven through tell in corpus order, one `ORC` verdict line per input. mode:
    old  -- no parser(): the old (interpretive) road
    do   -- parser(DO), as sweepT generates
    se   -- parser(StatemenT); parser(ExpressioN): the second generation order
The probe action is CALLED ONCE BEFORE any parser() -- an action compiled after parser() takes
SEQ 202's compile refusal on its first call, which is how a first oracle mis-read the DO input.
A drive that refuses ends the probe's activation, so it prints no ORC line: the harness reads a
missing line as REFUSED. Inputs carry no `#)` (checked by the harness).
"""
import sys
corpus, mode, fixture, keys = sys.argv[1:5]
seen = []
for l in open(corpus):
    l = l.rstrip('\n')
    if l and l not in seen: seen.append(l)
out = ['Start();', 'include(unitTests);', 'include(utilities);', 'search reset stack Grokking;', 'define',
       '    s2N=0;', '    s2Y=0;', '    s2C=0;', '    s2L aa bb cc;',
       '    orSay code={', '        v := tell(argument);', '        m := *v["matched"]; c := *v["consumed"];',
       '        cerr "ORC m= " m " c= " c:;', '        };']
for i, l in enumerate(seen):
    root, msg = l.split('|', 1)
    out.append('    or%03d=(%s %s#);' % (i, root, msg))
out += ['    ;', 'cerr "KEY warm":;', 'orSay(or000);']
out += {'old': [], 'do': ['parser(DO);'], 'se': ['parser(StatemenT);', 'parser(ExpressioN);']}[mode]
for i in range(len(seen)):
    out += ['cerr "KEY %03d":;' % i, 'orSay(or%03d);' % i]
out += ['cerr "ORACLE SENTINEL":;', 'stop();']
open(fixture, 'w').write('\n'.join(out) + '\n')
open(keys, 'w').write('\n'.join('%03d|%s' % (i, l) for i, l in enumerate(seen)) + '\n')
