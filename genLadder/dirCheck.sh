#!/bin/bash
#  dirCheck.sh -- EVERY DIRECTIVE MUST STILL INJECT (Tony, SEQ 304 R1, standing; on the seal checklist).
#
#  tok matches a directive's anchor as a PREFIX of a statement's source text and drops a miss at exit 0 with no
#  word -- so a respell of the anchored statement (or moving it into a -% %- passthrough, which tok cannot anchor
#  on) silently orphans the directive. Three were dark from 1.2c/1.2d until SEQ 303's verify step found them.
#
#  For each directive in the directive file(s), alone: write it into a scratch file under its own section header,
#  ARMED (a parked `ctive` entry is armed in the scratch copy, never in the real file), tok its target with it, and
#  count the lines it added to the generated .mm against a bare build. 0 lines = DARK, named. #globals entries are
#  tried against GroupRules.twk first, then every other top-level .twk until tok finds the method.
#
#  The tree is retokked BARE before and after, and the after must be byte-identical to the before (the instrument
#  leaves no trace). Exit 1 on: an ARMED directive dark, zero directives injecting (a vacuous run), a bare
#  mismatch, or a missing directive file. A PARKED directive that is dark is named but does not fail the run.
#  H1: the tok binary is echoed first. H2: the last line is the sentinel, reached only through the summary.

cd "$(dirname "$0")/.." || exit 2
TOKBIN=$(command -v tok)
if [ -z "$TOKBIN" ]; then echo "FAIL dirCheck: no tok on PATH"; exit 1; fi
echo "tok: $TOKBIN  $(stat -f '%z bytes  %Sm' "$TOKBIN")"
DIRFILES="groupDirectives"
for f in $DIRFILES; do
    if [ ! -f "$f" ]; then echo "FAIL dirCheck: directive file MISSING: $f"; exit 1; fi
done

W=$(mktemp -d "${TMPDIR:-/tmp}/dirCheck.XXXXXX")
trap 'rm -rf "$W"' EXIT

#  bare, and the snapshot the per-directive runs restore from
for t in *.twk; do tok "$t" > /dev/null 2>&1 || { echo "FAIL dirCheck: bare tok of $t failed"; exit 1; }; done
mkdir -p "$W/bare"; cp *.mm *.h "$W/bare/"

python3 - "$W" $DIRFILES <<'PY'
import os, re, subprocess, sys, glob, shutil
W = sys.argv[1]; files = sys.argv[2:]
SECTION_FILE = {'GroupItem': ['GroupItem.twk'], 'GroupMain': ['GroupMain.twk'],
                'GroupRules': ['GroupRules.twk'], 'RuleStuff': ['RuleStuff.twk']}
twks = sorted(glob.glob('*.twk'))
HEAD = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*) (.*?)\s*\b(a?ctive)\s*$')
def restore():
    for p in glob.glob(os.path.join(W, 'bare', '*')):
        shutil.copyfile(p, os.path.basename(p))
def mm_of(twk): return twk[:-4] + '.mm'
def added(mm):
    a = open(os.path.join(W, 'bare', mm), errors='replace').read().split('\n')
    b = open(mm, errors='replace').read().split('\n')
    out = subprocess.run(['diff', os.path.join(W, 'bare', mm), mm], capture_output=True, text=True).stdout
    return sum(1 for l in out.split('\n') if l.startswith('>'))
total = inject = 0; dark = []
for df in files:
    lines = open(df, errors='replace').read().split('\n')
    section = None; i = 0
    while i < len(lines):
        L = lines[i]
        m = re.match(r'^#([A-Za-z]+)\s*$', L)
        if m: section = m.group(1); i += 1; continue
        h = HEAD.match(L) if section else None
        if not h: i += 1; continue
        method, anchor, state = h.group(1), h.group(2), h.group(3)
        j = i + 1
        while j < len(lines) and not lines[j].startswith('#;'): j += 1
        body = lines[i+1:j]
        armedHead = L[:L.rstrip().rfind(state)] + 'active'
        scratch = os.path.join(W, 'one')
        open(scratch, 'w').write('#' + section + '\n' + armedHead + '\n' + '\n'.join(body) + '\n#;\n')
        cands = SECTION_FILE.get(section, ['GroupRules.twk'] + [t for t in twks if t != 'GroupRules.twk'])
        n = 0; where = None; why = 'method not found in any candidate file'
        for twk in cands:
            r = subprocess.run(['tok', twk, scratch], capture_output=True, text=True)
            outp = r.stdout + r.stderr
            if 'Could not find directive method' in outp:
                restore(); continue
            if 'ERROR' in outp:
                why = 'tok could not parse the directive (ERROR ... in %s)' % twk
                restore(); where = twk; break
            n = added(mm_of(twk)) if os.path.exists(mm_of(twk)) else 0
            where = twk; restore()
            if n == 0: why = 'tok found %s in %s but injected NOTHING -- the anchor matches no statement' % (method, twk)
            break
        total += 1
        tag = '%s %s (%s, line %d of %s)' % (method, anchor, 'armed' if state == 'active' else 'parked', i + 1, df)
        if n > 0:
            inject += 1; print('  ok    INJECTS %s -> %s +%d' % (tag, where, n))
        else:
            dark.append((state, tag))
            #  F-141 dirCheckFlicker (SEQ 307 R1): which DISARMED directives read dark varies run to run on one tree,
            #  so a dark disarmed directive is a WARNING until that is fixed; an ARMED dark one still fails.
            print('  %s  %s -- %s' % ('DARK' if state == 'active' else 'WARN dark', tag, why))
        i = j + 1
armedDark = [t for s, t in dark if s == 'active']
print('DIRCHECK: %d directives -- %d inject, %d dark (%d armed, %d parked)' % (total, inject, len(dark), len(armedDark), len(dark) - len(armedDark)))
open(os.path.join(W, 'verdict'), 'w').write('%d %d %d\n' % (total, inject, len(armedDark)))
PY

read TOTAL INJECT ARMEDDARK < "$W/verdict"
fail=0
#  the instrument leaves no trace: a bare retok must reproduce the snapshot byte for byte
for t in *.twk; do tok "$t" > /dev/null 2>&1; done
for p in "$W"/bare/*; do
    b=$(basename "$p")
    cmp -s "$p" "$b" || { echo "  FAIL  bare mismatch after the run: $b"; fail=1; }
done
[ "$fail" = 0 ] && echo "  ok    tree retokked bare and byte-identical to the bare snapshot"
if [ "$INJECT" -eq 0 ]; then echo "  FAIL  vacuous: no directive injected anything"; fail=1; fi
if [ "$ARMEDDARK" -gt 0 ]; then echo "  FAIL  $ARMEDDARK ARMED directive(s) dark -- named above"; fail=1; fi
if [ "$fail" = 0 ]; then echo "DIRCHECK PASSED ($INJECT of $TOTAL inject; parked dark named above, not a failure)"
else echo "DIRCHECK FAILED"; fi
#  the WARN lines above are disarmed directives: a warning, not a fail (F-141 dirCheckFlicker, SEQ 307 R1)
echo "DIRCHECK SENTINEL -- reached the foot"
exit $fail
