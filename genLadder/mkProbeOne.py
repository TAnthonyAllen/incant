import sys
#  ⚠ THE OUTPUT PATH IS AN ARGUMENT SO THE FLEET DOES NOT DIRTY A TRACKED FILE.
#  countPop.sh regenerates this probe once per rule, and while it wrote to
#  minionWork/probeOne every fleet run left the tree modified -- which breaks the
#  clean-kitchen check and makes `git status` permanently noisy, so real dirt
#  would hide among the noise. Defaults to the old path for any hand invocation.
rule=sys.argv[1]
out=sys.argv[2] if len(sys.argv)>2 else 'minionWork/probeOne'
src=open('incant/f31').read()
src=src.replace('    fbLimit=42;','    fbLimit=999;').replace('    f31Arm=1;','    f31Arm=0;')
src=src.replace('''        cerr "== compiling the FIRST body, the one known good alone ==":;
        iterate fbC on fbFirst;
        while ++fbC;
            cerr "COMPILING " ~taG:;
            compile(fbC);''','''        cerr "== ONE TARGET ==":;
        cerr "COMPILING %s":;
        compile(Grokking["%s"]);
        cerr "TARGETDONE %s":;''' % (rule,rule,rule))
open(out,'w').write(src)
