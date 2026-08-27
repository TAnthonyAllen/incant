import sys
rule=sys.argv[1]
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
open('minionWork/probeOne','w').write(src)
