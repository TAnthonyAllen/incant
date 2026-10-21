#!/bin/bash
# gen26.sh -- the 26 generator files (results/genlist2), `jitter;` after the first top-level Start(); against a plain twin
# carrying the do-nothing `jitterOff;` on the same line, sibling directories, same basename (censusJitter.sh's masking).
# Run from a Groups tree (the fixtures are read from incant/pop). B = the binary (or a wrapper), OUT = a scratch dir.
# Prints one line per file: exits, agree / DISAGREE, masked diff size; then a tally.
B=${B:?}; O=${OUT:?}; L=$(dirname $0)/results/genlist2
rm -rf $O; mkdir -p $O/plain $O/jit
mask () { sed -e "s#$O/plain/#X/#g" -e "s#$O/jit/#X/#g" -e 's/0x[0-9a-fA-F]*/0x/g' -e 's/i64 [0-9][0-9]*/i64 N/g'; }
agree=0; dis=0
for n in $(cat $L); do
  f=incant/pop/$n
  at=$(awk '/^stop\(\);|^bail\(\);/{exit} /^Start\(\);/{print NR; exit}' "$f")
  awk -v L=${at:-0} 'L==0 && NR==1{print "jitterOff;"} {print} L>0 && NR==L{print "jitterOff;"}' "$f" > $O/plain/$n
  awk -v L=${at:-0} 'L==0 && NR==1{print "jitter;"} {print} L>0 && NR==L{print "jitter;"}' "$f" > $O/jit/$n
  INCANT_KLFILE=$n.plain perl -e 'alarm 60; exec @ARGV' $B $O/plain/$n > $O/$n.o0 2> $O/$n.e0; x0=$?
  INCANT_KLFILE=$n.gjit INCANT_JITTER_ERR=$O/$n.cerr perl -e 'alarm 60; exec @ARGV' $B $O/jit/$n > $O/$n.o1 2> $O/$n.e1raw; x1=$?
  grep '^=== jitter: ' $O/$n.e1raw > $O/$n.jit; grep -v '^=== jitter: ' $O/$n.e1raw > $O/$n.e1
  mask < $O/$n.o0 > $O/$n.m0; mask < $O/$n.o1 > $O/$n.m1; mask < $O/$n.e0 > $O/$n.n0; mask < $O/$n.e1 > $O/$n.n1
  d=$(( $(diff $O/$n.m0 $O/$n.m1 | grep -c '^[<>]') + $(diff $O/$n.n0 $O/$n.n1 | grep -c '^[<>]') ))
  if [ $d = 0 ]; then v=agree; agree=$((agree+1)); else v=DISAGREE; dis=$((dis+1)); fi
  echo "$n at=${at:-0} x0=$x0 x1=$x1 $v diff=$d"
done
echo "gen26: agree $agree / DISAGREE $dis"
