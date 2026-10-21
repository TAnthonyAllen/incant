# S6 hands over -- branch jit-list-handover (SEQ 392 R1)

Ruled (Tony, 2026-10-21, SEQ 392): R1 the build-time-read class in three strokes -- S6, then termCountT's argument, then
PI-1's print buffer. R2 S6's list arm hands its statement to run time through SEQ 384's machinery (jitHandOver, the
rollback, the jitStmtRT call) rather than degrading to nothing: a degrade that says "running INTERPRETED" must be true.
Recon: docs/jitter.md, "SEQ 391" and "SEQ 392".

## The cure, as designed (written before the build)

jitEmitBareRead's list arm (jitEmitters.rtn, the `token->groupBody->groupList` guard) calls `jitHandOver` instead of
`jitDegrade` and returns 0. The statement is marked handed: jitStmtEnd rolls back what it emitted and emits one jitStmtRT
call, which flushes the frame, runs the statement interpreted as its owner's, and reloads the frame (SEQ 384). The
follow-on degrades in the same statement (jitPrintList's "print operand part", aCTionBrancH's "return operand produced no
value") then fold into the hand-over -- jitDegrade returns early once gJitHandOver is set. Nothing else changes; no extern
added (canary 365 stays); no groups.ext change.

## Pre-registered movers (all under `jitter;`)

1. **jitArgListT** (new, born red at the branch point): the three calls `[ ] [ ] [ ]` -> `hasGroup 35 57` = the twin.
2. **jitPrintInlineT PI-0**: empty -> 46 (its row, pinned at today's empty, re-pinned with its sentence). **PI-1 unmoved**
   (the print buffer is a separate mechanism, stroke 3): still 0 lines.
3. **gen26 baselineTestsNew** (the generator files, `jitter;` after Start()): testARG prints its argument (three calls);
   printDefinition prints its argument (`sumple=...`, `wrap=...`); printTest's lefty `0` -> `46` -- so the 40-line diff
   SHRINKS (what remains is named). Agreement stays at least 14 / 26; any file that moves is named.
4. **pop.sh** otherwise row for row with the branch-point run; **jitLadder** row for row. Degrade counts: a statement that
   degraded twice (the bare read, then the part) now hands over once -- any row that prints a degrade count where a list
   read occurs is named if it moves.
5. **SEQ 388's 239-local classification**, rerun on the cure: predicted unchanged.

## H7 (cure committed first)

The degrade-only arm back: jitArgListT, PI-0, testARG, printDefinition and lefty return to their old values; restored
md5 = the cure.

## The certificate (branch: b7d376fe pre-registration, f299e40a cure; clone, 2026-10-21)

Built bare in the clone. Canary **365, unchanged**; the generated diff is the one call (jitDegrade -> jitHandOver) and its
comment. Branch-point binary: ~/bin/incant (the branch point's engine; the clone's own older builds predate SEQ 391).

| pre-registered | measured |
|---|---|
| jitArgListT `[ ] [ ] [ ]` -> `hasGroup 35 57` | **as registered** |
| PI-0 empty -> 46; PI-1 unmoved | **as registered** (PI-0's row re-pinned at 46 with its sentence; PI-1 still 0 lines) |
| pop.sh otherwise row for row; jitLadder row for row | **1611 green, only those two rows moved; jitLadder identical** |
| testARG and printDefinition print their argument | **true where they run** -- the W1 and W5 witnesses (printDefinition(sample) = the twin). In baselineTestsNew they are **never reached** (below) |
| **lefty 0 -> 46** | **FALSIFIED: still 0.** The list read now hands over, and `return lefty` runs interpreted -- but the compiled function's value is its result slot, which the interpreted return does not write |
| **baselineTestsNew's 40-line diff shrinks** | **FALSIFIED: 40 -> 94 lines.** The jitted run's stdout stops after printTest's line: testUnitTests (refused by the net, interpreted) **runs no statement after printTest()** -- simpleIF, testOR, testARG, ... printDefinition never run. Exit 0, its SENTINEL printed |
| gen26 >= 14 / 26 | **14 / 26**; baselineTestsNew is the only file that moved (above) |
| the 239-local classification unchanged | **unchanged** (84 / 155 / 0 / 0; `results/listHandover.raw` / `.table`) |

**THE UNFORESEEN MECHANISM, pinned on trunk as incant/pop/jitReturnListT (717c72f3) -- lefty's shape under an INTERPRETED
caller.** rlOuter (interpreted) calls the compiled rlT, which calls the compiled rlY, whose `return rlY` is a bare read of
a field carrying a list. **Trunk: exit 139** after "RL outer before". **This branch: exit 0, but rlOuter's block stops
after rlT() -- no RL-2 line -- and RL-1 is absent**; RL-3 (top level) prints. Twin: RL-1 46, both RL-2, RL-3. So S6's
hand-over turns a crash into a SILENT TRUNCATION of the interpreted caller: once the `return` statement is handed to run
time, its interpreted run (inferred, NOT traced) leaves the return's branch signal set past the compiled call -- the
interpreted block above it then stops as though it had returned -- and delivers no value into the result slot. **A
handed-over `return` is a statement SEQ 384's road does not carry yet.** This is the reason the branch should not be
bought as it stands, and it is named for Tony rather than chased (R3).

**H7 (cure committed first):** the degrade-only arm back -> jitArgListT empty on all three calls, PI-0 empty,
printDefinition(sample)'s `wrap=` empty, jitReturnListT exit 139 -- every witness back; restored md5 = the cure.
