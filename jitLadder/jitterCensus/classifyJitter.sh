#!/bin/bash
# one class per fixture; hang and crash are read from the exit status FIRST, because a run that dies prints no exit tally
grep -E '^[A-Za-z0-9_.]+ x0=' $1 | while read n x0 x1 v nz b r ru f d c; do
  x0=${x0#x0=}; x1=${x1#x1=}; nz=${nz#noisy=}; c=${c#touched=}; ru=${ru#reused=}
  if [ "$x1" = 142 ] && [ "$x0" != 142 ]; then cls=HANG
  elif [ "$x1" -ge 128 ] && [ "$x0" -lt 128 ]; then cls=CRASH
  elif [ "$c" = 0 ]; then cls="untouched-$v"
  elif [ "$v" = agree ]; then cls=agree
  else cls=DISAGREE; fi
  [ "$nz" = 1 ] && [ "$cls" = DISAGREE ] && cls=DISAGREE-noisy
  echo "$cls $n $b $r reused=$ru $f $d touched=$c"
done
