# The for cursor recognised -- branch jit-for-cursor (SEQ 390 R2)

Ruled (Tony, 2026-10-21, SEQ 390 R2): the for cursor is taught now -- with a second writer it earns a slot and the
epilogue clobbers it. The `:x` hoist and `++One` stay refused and docketed. Recon: docs/jitter.md, "SEQ 390" (trunk
647a32e7).

## The cure, as designed (written before the build)

- **One new extern, `jitNoteFor(input)`** (jitEmitters.rtn), asked at aCTionFOR's jitting gate (ruleActions.rtn:496),
  BEFORE the hand-over. It records:
  - **the cursor** -- `input["Looper"]` followed to the local -- through jitNoteWriter with op null: a holder (GROUP), as
    an iterate cursor already is (SEQ 388);
  - **the body's writes** -- a static scan of `input["StatemenT"]`, which is already built (R1 (a)): it descends into
    instruction nodes (instructType set) and through an ExpressioN's gGroup, never into a field that is an action, a
    rule or coded, and never into a local. At a node whose children are target, assign-tier op, value, with a local
    target: `:=` / `<-` -> GROUP; a value of known kind (a literal, a field with a kind) -> that kind; **a value of no
    known kind -> no scalar slot** (the body runs INTERPRETED, so nothing the jit seeds or carries makes it a scalar --
    the conservative half of "a non-scalar never gets a scalar slot"); a nested FOR -> its own cursor and body.
  A local found non-scalar while it holds a slot restarts the build, exactly as jitNoteWriter does (the restart bound
  already counts kind discoveries).
- Nothing else moves: the prologue skip, jitKindUncarried and the net are SEQ 388's. No groups.ext change.

## Pre-registered movers

1. **jitForCursorT** (carries epilogueWriteBack) and **jitForBodyT** (new, born red at the branch point): jitted exit
   139 -> 0 and SENTINEL 0 -> 1 on each; FC-0 and the twins unmoved. **incant/fixits/epilogueWriteBack is retired by
   mapping** to incant/attic in the certificate commit, its attempt log ending at the certifying rows.
2. **SEQ 388's for-cursor refusals** (baselineTestsNew, gen26): ifTest and printDefinition stop refusing on `grup` --
   each then compiles, or refuses for a named second reason (measured, named). testInterpret's `grup` goes from SLOT to
   NOSLOT; testInterpret stays refused on `Saw`.
3. **gen26 agreement stays at least 14 / 26.**
4. **pop.sh** otherwise row for row with the branch-point run; **jitLadder** row for row. The census found no other for
   statement in a compiled action, so nothing else is predicted to move.
5. **canary 364 -> 365** (jitNoteFor). Generated diff: the extern and its one call.

## H7 (cure committed first)

- **Recognition removed** (jitNoteFor returns at its top): jitForCursorT and jitForBodyT back to exit 139.
- Then SEQ 388's R3 classification rerun after the cure, the cursor locals included.
