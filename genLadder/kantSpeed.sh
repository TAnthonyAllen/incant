#!/bin/bash
export INCANT_NOVIEW=1   # SEQ 686: show never opens a viewer from a script of Clod's
#  kantSpeed.sh -- SEQ 675 (step 4 of the kant jitter): THE FIRST SPEED MEASUREMENT. Not a seal instrument and on no checklist:
#  it prints times, and a time is not a row (rule H3). Two loops (SEQ 682: the second added), four ways:
#      sum   i and s counts, s = s + i: about a nanosecond a pass natively, so it reads near zero at 600000 passes. It is NOT
#            folded (measured SEQ 682: compileIR and the C++ walk run mem2reg only, and native time grows with the passes).
#      mix   a number x = x / 3 + i: a division each pass, the chain cannot be computed ahead.
#      interpreted   the new-road action, nothing compiled
#      step 2c       kwCompile with no kind pass: one testOP call per top-level statement, so the loop is one call
#      native        krResolve then kwCompile: the kind pass, native compare/if/while (step 4), slot locals (step 5)
#      C++ walk      the frozen C++ new-road walk, switched on by `jitter;`
#  Each way is one process. Its time is the best of RUNS wall-clock runs, less the best of the same file with the loop
#  bound at 0 (start-up, the build and the compile are in both). Every run must print the same sum or the script fails.
#  usage: genLadder/kantSpeed.sh [passes, default 60000] [runs, default 5]; WAYS="native walk" and LOOPS="mix" choose a subset
cd "$(dirname "$0")/.." || exit 1
B="${INCANT:-$HOME/bin/incant}"
N="${1:-60000}"; RUNS="${2:-5}"
T=$(mktemp -d)
echo "  bin   $B"; echo "  bin   $(stat -L -f '%z bytes  %Sm' "$B")"
mk () {  # $1 way  $2 bound  -> file
    {
    cat <<HEAD
Start();
include(utilities);
include(unitTests);
registry(fILEs);
define
    kantGrammar File='incant/kantGrammar';
    kantJitter File='incant/kantJitter';
    ;
include(kantGrammar);
include(kantJitter);
search reset stack KantGrammar Grokking;
search Utilities UnitTests KantJitter;
registry(KantSpeed);
define
    njReq owner source result rule;
    njNew code={
        njSrc := argument.CodE;
        njReq.owner  := argument;
        njReq.source := njSrc;
        njReq.rule   := KantGrammar["STARt"];
        if compileIn(njReq);
            njBlock = njReq.result;
            *njBlock :. noPrinT;
            argument :. isActioN;
            argument +< *njBlock;
        };
    spSum code={
        i = 0;
        s = 0;
        while i < $2;
            s = s + i;
            i = i + 1;
        print "SUM" s:;
        };
    spMix code={
        i = 0;
        x = 1.5;
        while i < $2;
            x = x / 3 + i;
            i = i + 1;
        print "SUM" x:;
        };
    ;
search KantSpeed;
njNew($3);
HEAD
    case $1 in
        interp) ;;
        step2c) echo "kwCompile($3);" ;;
        native) echo "krResolve($3);"; echo "kwCompile($3);" ;;
        walk)   echo "jitter;" ;;
    esac
    echo "$3();"; echo 'cerr "KANTSPEED SENTINEL":;'; echo "stop();"
    } > "$T/$1.$2"
}
best () {  # $1 file -> best wall ms over RUNS; the sum line is left in $T/sum
    perl -MTime::HiRes=time -e '
        my ($b,$f,$runs,$out)=@ARGV; my $best=1e9;
        for (1..$runs) { my $t=time; system("$b $f > $out.o 2> $out.e"); my $x=$?>>8; my $d=(time-$t)*1000;
            die "exit $x on $f\n" if $x; $best=$d if $d<$best; }
        printf "%.1f\n",$best;' "$B" "$1" "$RUNS" "$T/run" || return 1
    grep -q '^KANTSPEED SENTINEL' "$T/run.e" || { echo "no sentinel on $1" >&2; return 1; }
    grep '^SUM' "$T/run.o" | tr -d ' ' > "$T/sum"
}
fail=0
for lp in ${LOOPS:-sum mix}; do
want=""; act=spSum; [ "$lp" = mix ] && act=spMix
echo "  loop $lp ($act)"
printf "  %-12s %10s %10s %10s   %s\n" way "ms" "ms at 0" "net ms" "sum"
for w in ${WAYS:-interp step2c native walk}; do
    mk $w "$N" $act; mk $w 0 $act
    full=$(best "$T/$w.$N") || { echo "  FAIL  $w did not run"; fail=1; continue; }
    sum=$(cat "$T/sum")
    zero=$(best "$T/$w.0") || { echo "  FAIL  $w at 0 did not run"; fail=1; continue; }
    [ -z "$want" ] && want="$sum"
    [ "$sum" = "$want" ] || { echo "  FAIL  $w printed $sum, the first way printed $want"; fail=1; }
    printf "  %-12s %10s %10s %10s   %s\n" $w "$full" "$zero" "$(echo "$full - $zero" | bc)" "$sum"
done
[ -z "$want" ] && { echo "  FAIL  nothing ran"; fail=1; }
done
rm -rf "$T"
echo "  passes $N, best of $RUNS runs each"
exit $fail
