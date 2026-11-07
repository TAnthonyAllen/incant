#!/bin/bash
# setFrame second-run recon probe (2026-11-07, docs/setFrameSecondRun.md). Run from Groups: docs/setFrameProbes/secondRun.sh
# Each shape once, twice, and after a resize to 400, each in its own process; then a layout of a copy. Prints frames only.
B=${INCANT:-$HOME/bin/incant}; T=$(mktemp -d); echo "bin $B $(stat -f '%z %Sm' $B)"
cat > $T/pre <<'PRE'
Start();
include(unitTests);
include(utilities);
search reset stack Grokking;
register(ProbeR);
define
    pSimple across x=100 y=100 width=250 height=212
        quinto width=150;
        sexto height=12;
        fifth;
    pSumple="long string" height=200 width=250 x=100 y=100 down=* across=2
        crossing height=50;
    pPct across x=0 y=0 width=200 height=100
        half width=50%;
        rest;
    pTri x=0 y=0 width=90 height=90 down=3
        tA;
        tB;
    pStar x=0 y=0 width=200 height=100 down=*
        row height=50;
    pNest x=0 y=0 width=100 height=90 down=3
        cell across
            lA;
            lB;
    pResize code={
        =:argument width;
        width = 400;
        argument :% copyOf(width);
        };
    pStamp code={
        pc := copyOf(argument);
        setFrame(*pc);
        print "COPY" :;
        tsfLine(*pc);
        print "ORIG" :;
        tsfLine(argument);
        };
    ;
search ProbeR UnitTests Utilities list;
PRE
run() { n=$1; shift; { cat $T/pre; printf '%s\n' "$@"; echo 'print "RECON SENTINEL":;'; echo 'stop();'; } > $T/$n.in
  perl -e 'alarm 20; exec @ARGV' "$B" $T/$n.in > $T/$n.out 2>&1 </dev/null; x=$?
  echo "--- $n exit $x sentinel $(grep -c 'RECON SENTINEL' $T/$n.out)"
  grep -E '^(RUN|COPY|ORIG)|x=[^ ]+ y=[^ ]+ w=[^ ]+ h=|can only have|needs one|^REFUSED|^ERROR|RunRulE' $T/$n.out | cut -c1-100; }
for f in pSimple pSumple pPct pTri pStar pNest; do
  run $f.once "setFrame($f);" 'print "RUN 1":;' "tsfLine($f);"
  run $f.twice "setFrame($f);" "setFrame($f);" 'print "RUN 2":;' "tsfLine($f);"
  run $f.resize "setFrame($f);" "pResize($f);" "setFrame($f);" 'print "RUN after resize to 400":;' "tsfLine($f);"
done
run stamp 'pStamp(pNest);'
run stampSumple 'pStamp(pSumple);'
run stampTwice 'pStamp(pPct);' 'pResize(pPct);' 'print "RUN after resize, second stamp":;' 'pStamp(pPct);'
rm -rf $T
