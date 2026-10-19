#!/bin/bash
# classify census lines: one class per fixture
S=${OUT:?set OUT to a results directory}
road=$1; D=$S/cen.$road.gx
grep -E '^[A-Za-z0-9_.]+ x0=' $S/census.${road}gx.txt | while read n x0 x1 v noisy comp ref deg fires open; do
  x0=${x0#x0=}; x1=${x1#x1=}; c=${comp#compiles=}; o=${open#begunNotDone=}; r=${ref#refused=}; d=${deg#degraded=}; nz=${noisy#noisy=}
  if [ "$c" = 0 ] && [ "$o" = 0 ]; then cls="untouched-$v"
  elif [ "$x1" = 142 ]; then cls=HANG
  elif [ "$x1" -ge 128 ] && [ "$x0" -lt 128 ]; then
     if [ "$o" -gt 0 ]; then cls=CRASH-at-compile; else cls=CRASH-at-run; fi
  elif [ "$o" -gt 0 ]; then cls=EXIT-during-compile
  elif [ "$v" = agree ]; then cls=agree
  else cls=DISAGREE; fi
  [ "$nz" = 1 ] && [ "$cls" = DISAGREE ] && cls=DISAGREE-noisy
  echo "$cls $n compiles=$c refused=$r degraded=$d"
done
