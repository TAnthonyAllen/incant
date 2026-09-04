import sys
#  ⚠ THE OUTPUT PATH IS AN ARGUMENT SO THE FLEET DOES NOT DIRTY A TRACKED FILE.
#  countPop.sh regenerates this probe once per rule, and while it wrote to
#  minionWork/probeOne every fleet run left the tree modified -- which breaks the
#  clean-kitchen check and makes `git status` permanently noisy, so real dirt
#  would hide among the noise. Defaults to the old path for any hand invocation.
rule=sys.argv[1]
out=sys.argv[2] if len(sys.argv)>2 else 'minionWork/probeOne'
#  ⚠ THIS IS A VERBATIM TEXT MATCH AGAINST incant/f31's SOURCE, so it is COUPLED
#  TO THAT FILE'S EXACT SPELLING and breaks SILENTLY when the source is respelled:
#  .replace() that matches nothing returns the original, the probe loses its
#  TARGETDONE line, and countPop reports every rule TRUNC. Measured 2026-09-04
#  (C-162): a cursor-respell of `compile(fbC)` -> `compile(*fbC)` took countPop
#  from 40/40 clean to 0/40 with no error anywhere. A census scoped to incant
#  files cannot see this coupling -- .py is not incant. If you respell f31, grep
#  this file for the block first.
src=open('incant/f31').read()
src=src.replace('    fbLimit=42;','    fbLimit=999;').replace('    f31Arm=1;','    f31Arm=0;')
src=src.replace('''        cerr "== compiling the FIRST body, the one known good alone ==":;
        iterate fbC on fbFirst;
        while ++fbC;
            cerr "COMPILING " ~taG:;
            compile(*fbC);''','''        cerr "== ONE TARGET ==":;
        cerr "COMPILING %s":;
        compile(Grokking["%s"]);
        cerr "TARGETDONE %s":;''' % (rule,rule,rule))
open(out,'w').write(src)
