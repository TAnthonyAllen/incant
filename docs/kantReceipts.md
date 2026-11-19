# kant receipts

One line per measured result, dated, newest last. Two kinds: **lines** (a kant rewrite, before -> after) and **speed**
(`genLadder/kantSpeed.sh`: net ms for the loop, best of N runs, less the same file with the loop at 0 passes; interpreted /
step 2c / native kant jitter / the frozen C++ walk). Every rewrite and every speed measurement adds its line (Tony,
2026-11-19). A speed line names the passes, the runs and the binary; a time is not a fleet row (rule H3).

## Lines

- 2026-11-19  resolveLook (incant/utilities) rewritten with the census spellings (continue, && ||, if / or / else): **32 -> 19
  lines** (30 without its two comments); 9 names -> 7 (msPh, msDone gone). Specimen IncantForms/WorkingOn/ergoSpecimen,
  byte-identical output to the original, each arm taken. Not landed in utilities. (docs/ergoCensus.md)

## Speed (net ms)

- 2026-11-17  SEQ 675, step 4 (native compare, if, while), sum loop, best of 5:
  600000 passes: interpreted 178.6 / step 2c 177.5 / native 153.4 / C++ walk 0.3.
  60000 passes: 21.2 / 17.5 / 17.8 / -0.4 (below what the script reads).
- 2026-11-17  seal 497, step 5 (slot locals): the sum loop reads at the floor, native and C++ walk alike (no table kept).
- 2026-11-19  trunk f2b818b7 (binary 2190624 bytes, Nov 19 09:42), 600000 passes, best of 3:
  sum loop: interpreted 179.0 / step 2c 180.9 / native -0.5 / C++ walk 0.1.
  mix loop (a division a pass): interpreted 215.7 / step 2c 214.6 / native 2.4 / C++ walk 3.1.
  Every way printed the same sums. At 60000 passes: sum 17.3 / 18.8 / -0.9 / 0.2, mix 22.0 / 22.6 / 0 / -1.0.
