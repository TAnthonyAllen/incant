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
