#!/bin/bash
# gen26.sh -- the 26 generator files (results/genlist2), `jitter;` after the first top-level Start(); against a plain twin
# carrying the do-nothing `jitterOff;` on the same line, sibling directories, same basename (censusJitter.sh's masking).
# Run from a Groups tree (the fixtures are read from incant/pop). B = the binary (or a wrapper), OUT = a scratch dir.
# Prints one line per file: exits, agree / DISAGREE, masked diff size, and how many lines each named mask (W1-W3,
# below) touched on each road; then a tally.
B=${B:?}; O=${OUT:?}; L=$(dirname $0)/results/genlist2
rm -rf $O; mkdir -p $O/plain $O/jit
mask () { sed -e "s#$O/plain/#X/#g" -e "s#$O/jit/#X/#g" -e 's/0x[0-9a-fA-F]*/0x/g' -e 's/i64 [0-9][0-9]*/i64 N/g'; }
# named masks (SEQ 418 R1) -- each is an exact pattern for one class of INSTRUMENT text that docs/gen26Recon.md measured
# moving for a reason that is not a value (SEQ 416). nmask <in> <out> <counts>: writes "W1 W2 W3" line counts.
#   W1  the process-wide jit counters, which the jitter's own compiles inflate: the NUMBER in the degrade / compile / slot
#       count lines, and built / REUSED in a jitRunAction callee line. The line stays; only the number or word goes.
#   W2  trace callouts on the interpreter road (parseTrace / measure.twk): the jitted road never passes their seats, or
#       its silenced first-call compile writes them to .cerr. Deleted by exact leading token. NOT masked: any other
#       CAPTURE verdict (DIVERGE-*), and "runRule:" refusals -- only the "runRule DOOR" trace.
#   W3  ruleOfCensus counting the JiT= IR record a jitted action carries: nodes= on RULEOF nodes lines, terms= on
#       RULEOF XREG lines. The other census fields stay compared.
nmask () {
  awk -v cf="$3" '
  /^=== (jitDegrade|jitCompile|jitSlot) count = [0-9]+ ===$/ { sub(/= [0-9]+ ===$/, "= N ==="); w1++; print; next }
  /^=== jitRunAction: callee [^ ]+ (built|REUSED) as jit_[^ ]+ ===$/ { sub(/ (built|REUSED) as /, " built-or-REUSED as "); w1++; print; next }
  /^ *(RULEDISPATCH|PPWRITE|DEFERABOVE|OLDFIREFLAG|fireLabelMethod|CAPFIRE|BLOCKRESULT|attachLabel|fireLabel|LABELKIDS|ACTFIRE|DOTOPERANDS|ATTACHREPEAT|MARKPT|MARKARM|FRAMEPROBE) / { w2++; next }
  /^ *CAPTURE ORACLE-ABSENT / || /^ *runRule DOOR / { w2++; next }
  /^RULEOF nodes=[0-9]+ / { sub(/nodes=[0-9]+/, "nodes=N"); w3++; print; next }
  /^ *RULEOF XREG .* terms=[0-9]+ / { sub(/terms=[0-9]+/, "terms=N"); w3++; print; next }
  { print }
  END { printf "%d %d %d\n", w1, w2, w3 > cf }' "$1" > "$2"
}
agree=0; dis=0
for n in $(cat $L); do
  f=incant/pop/$n
  at=$(awk '/^stop\(\);|^bail\(\);/{exit} /^Start\(\);/{print NR; exit}' "$f")
  awk -v L=${at:-0} 'L==0 && NR==1{print "jitterOff;"} {print} L>0 && NR==L{print "jitterOff;"}' "$f" > $O/plain/$n
  awk -v L=${at:-0} 'L==0 && NR==1{print "jitter;"} {print} L>0 && NR==L{print "jitter;"}' "$f" > $O/jit/$n
  INCANT_KLFILE=$n.plain perl -e 'alarm 60; exec @ARGV' $B $O/plain/$n > $O/$n.o0 2> $O/$n.e0; x0=$?
  INCANT_KLFILE=$n.gjit INCANT_JITTER_ERR=$O/$n.cerr perl -e 'alarm 60; exec @ARGV' $B $O/jit/$n > $O/$n.o1 2> $O/$n.e1raw; x1=$?
  grep '^=== jitter: ' $O/$n.e1raw > $O/$n.jit; grep -v '^=== jitter: ' $O/$n.e1raw > $O/$n.e1
  mask < $O/$n.o0 > $O/$n.a0; mask < $O/$n.o1 > $O/$n.a1; mask < $O/$n.e0 > $O/$n.b0; mask < $O/$n.e1 > $O/$n.b1
  nmask $O/$n.a0 $O/$n.m0 $O/$n.c0o; nmask $O/$n.a1 $O/$n.m1 $O/$n.c1o
  nmask $O/$n.b0 $O/$n.n0 $O/$n.c0e; nmask $O/$n.b1 $O/$n.n1 $O/$n.c1e
  read p1 p2 p3 < <(paste -d' ' $O/$n.c0o $O/$n.c0e | awk '{print $1+$4, $2+$5, $3+$6}')
  read j1 j2 j3 < <(paste -d' ' $O/$n.c1o $O/$n.c1e | awk '{print $1+$4, $2+$5, $3+$6}')
  d=$(( $(diff $O/$n.m0 $O/$n.m1 | grep -c '^[<>]') + $(diff $O/$n.n0 $O/$n.n1 | grep -c '^[<>]') ))
  if [ $d = 0 ]; then v=agree; agree=$((agree+1)); else v=DISAGREE; dis=$((dis+1)); fi
  echo "$n at=${at:-0} x0=$x0 x1=$x1 $v diff=$d masked plain/jit W1 $p1/$j1 W2 $p2/$j2 W3 $p3/$j3"
done
echo "gen26: agree $agree / DISAGREE $dis"
