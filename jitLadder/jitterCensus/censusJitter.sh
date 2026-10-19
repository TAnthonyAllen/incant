#!/bin/bash
# the jitter census (SEQ 386): every fixture, plain twice, with jitter; once -- no tap. Measure only.
# Both copies carry ONE inserted line at the same place (plain: the do-nothing bare name jitterOff;) and share a
# basename in sibling directories, so line numbers and file names in the output cannot differ between them.
C=${CLONE:?}; S=${OUT:?}; B=$C/dd/Build/Products/Debug/Groups; G=${GENLIST:?}
road=$1; O=$S/cen.$road; rm -rf $O; mkdir -p $O/plain $O/jit
cd $C/InProcess/Groups
mask () { sed -e "s#$O/plain/#X/#g" -e "s#$O/jit/#X/#g" -e 's/0x[0-9a-fA-F]*/0x/g' -e 's/i64 [0-9][0-9]*/i64 N/g'; }
for f in incant/pop/* incant/pop/jit/*; do
  [ -f "$f" ] || continue
  n=$(basename $f)
  if [ $road = new ]; then
    at=$(awk '/^stop\(\);|^bail\(\);/{exit} /^search /{l=NR} END{print l}' "$f")
    [ -n "$at" ] || { echo "$n SKIP-nosearch"; continue; }
    awk -v L=$at '{print} NR==L{print "parser(Start);"; print "jitterOff;"}' "$f" > $O/plain/$n
    awk -v L=$at '{print} NR==L{print "parser(Start);"; print "jitter;"}' "$f" > $O/jit/$n
  else
    if grep -qx "$n" $G; then at=$(awk '/^stop\(\);|^bail\(\);/{exit} /^parser\(/{print NR; exit}' "$f")
    else at=$(awk '/^stop\(\);|^bail\(\);/{exit} /^Start\(\);/{print NR; exit}' "$f"); fi
    awk -v L=${at:-0} 'L==0 && NR==1{print "jitterOff;"} {print} L>0 && NR==L{print "jitterOff;"}' "$f" > $O/plain/$n
    awk -v L=${at:-0} 'L==0 && NR==1{print "jitter;"} {print} L>0 && NR==L{print "jitter;"}' "$f" > $O/jit/$n
  fi
  perl -e 'alarm 60; exec @ARGV' $B $O/plain/$n > $O/$n.o0 2> $O/$n.e0; x0=$?
  perl -e 'alarm 60; exec @ARGV' $B $O/plain/$n > $O/$n.o0b 2> $O/$n.e0b; x0b=$?
  INCANT_JITTER_ERR=$O/$n.cerr perl -e 'alarm 60; exec @ARGV' $B $O/jit/$n > $O/$n.o1 2> $O/$n.e1raw; x1=$?
  # the jitter's own lines are its witness, not the program's output: split them out before comparing
  grep '^=== jitter: ' $O/$n.e1raw > $O/$n.jit; grep -v '^=== jitter: ' $O/$n.e1raw > $O/$n.e1
  noisy=0; cmp -s <(mask < $O/$n.o0) <(mask < $O/$n.o0b) && cmp -s <(mask < $O/$n.e0) <(mask < $O/$n.e0b) || noisy=1
  if cmp -s <(mask < $O/$n.o0) <(mask < $O/$n.o1) && cmp -s <(mask < $O/$n.e0) <(mask < $O/$n.e1); then v=agree; else v=DISAGREE; fi
  built=$(grep -c ' built [1-9]' $O/$n.jit); ref=$(grep -c ' NOT JITTABLE' $O/$n.jit)
  reused=$(grep -c ' built 0 ' $O/$n.jit); fires=$(grep ' built ' $O/$n.jit | awk '{s+=$7} END{print s+0}')
  deg=$(grep -c 'JIT DEGRADE' $O/$n.cerr 2>/dev/null); [ -n "$deg" ] || deg=0
  #  touched: a compile BEGAN (the jitter opens the compile log only then) or a cached body fired. NOT a count of
  #  "entering on" lines -- jitRunAction prints those to stdout, which the jitter silences (measured: it read 0 always)
  touched=0; [ -e $O/$n.cerr ] && touched=1; [ -s $O/$n.jit ] && touched=1
  echo "$n x0=$x0 x1=$x1 $v noisy=$noisy builtAtExit=$built refusedAtExit=$ref reused=$reused fires=$fires degrades=$deg touched=$touched"
done
