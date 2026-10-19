#!/bin/bash
# forced-jit census (SEQ 383 R2b): every fixture, tap off vs tap on, split streams, 60s cap. Measure only.
C=${CLONE:?set CLONE to the clone root (holds InProcess/Groups and dd)}
S=${OUT:?set OUT to a results directory}
B=$C/dd/Build/Products/Debug/Groups
road=$1   # old | new
O=$S/cen.$road.gx; rm -rf $O; mkdir -p $O
cd $C/InProcess/Groups
mask () { sed -e 's/0x[0-9a-fA-F]*/0x/g' -e 's/i64 [0-9][0-9]*/i64 N/g'; }
for f in $(for x in $(cat $S/genlist2); do ls incant/pop/$x incant/pop/jit/$x 2>/dev/null; done); do
  [ -f "$f" ] || continue
  n=$(basename $f)
  src=$f
  if [ $road = new ]; then
    ln=$(awk '/^stop\(\);|^bail\(\);/{exit} /^search /{l=NR} END{print l}' "$f")
    [ -n "$ln" ] || { echo "$n SKIP-nosearch"; continue; }
    awk -v L=$ln '{print} NR==L{print "parser(Start);"}' "$f" > $O/$n.src; src=$O/$n.src
    after="INCANT_JIT_ALL_AFTER=parser"
  else after="INCANT_JIT_ALL_AFTER=parser"; fi
  perl -e 'alarm 60; exec @ARGV' $B $src > $O/$n.o0 2> $O/$n.e0; x0=$?
  perl -e 'alarm 60; exec @ARGV' $B $src > $O/$n.o0b 2> $O/$n.e0b; x0b=$?
  env INCANT_JIT_ALL=$O/$n.tally $after perl -e 'alarm 60; exec @ARGV' $B $src > $O/$n.o1 2> $O/$n.e1; x1=$?
  noisy=0; cmp -s <(mask < $O/$n.o0) <(mask < $O/$n.o0b) && cmp -s <(mask < $O/$n.e0) <(mask < $O/$n.e0b) || noisy=1
  if cmp -s <(mask < $O/$n.o0) <(mask < $O/$n.o1) && cmp -s <(mask < $O/$n.e0) <(mask < $O/$n.e1); then v=agree; else v=DISAGREE; fi
  comp=0; ref=0; deg=0; fires=0; open=0
  if [ -f $O/$n.tally ]; then
    comp=$(grep -c '^compile' $O/$n.tally); ref=$(grep -c '^compile .* rc=-' $O/$n.tally)
    deg=$(grep '^compile' $O/$n.tally | grep -vc 'degrade=0$'); fires=$(grep -c '^fire' $O/$n.tally)
    open=$(( $(grep -c '^begin' $O/$n.tally) - comp ))
  fi
  echo "$n x0=$x0 x1=$x1 $v noisy=$noisy compiles=$comp refused=$ref degraded=$deg fires=$fires begunNotDone=$open"
done
