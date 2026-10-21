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

## The certificate (branch: 83f5da78 pre-registration, 071afb50 cure; clone, 2026-10-21)

Built bare in the clone. Canary **364 -> 365**; the generated diff is additions only (jitNoteFor and its one call at
aCTionFOR's gate). The branch-point run was first taken on a stale clone binary (pre-SEQ 388); it was re-taken on the
right one (the SEQ 388 cure build, the engine trunk carries) before any comparison -- 1600 green, jitLadder PASSED, gen26
14 / 26.

| pre-registered | measured |
|---|---|
| jitForCursorT, jitForBodyT: exit 139 -> 0, SENTINEL 0 -> 1 | **as registered** -- fcL dumps as a group (`fifth`, `sample`) |
| epilogueWriteBack retired by mapping | **retired** to incant/attic, its attempt log ending at the certifying rows; fixitNag 8 -> 7 |
| ifTest and printDefinition stop refusing on grup | **both compile** (built 1, called 1 and 16); **no second refusal**. testInterpret still refused on `Saw`, its grup now NOSLOT |
| gen26 >= 14 / 26 | **14 / 26**. One file moved inside its disagreement: baselineTestsNew 36 -> 40 lines -- the newly compiled printDefinition prints `sumple=` and `wrap=` empty where the twin prints their text. **Named:** its first statement is `print ~$taG "=" argument$;`, the `argument` print item -- testARG's mechanism (the argument node baked at build), the build-time-read class, next on the docket; not a new find |
| pop.sh otherwise row for row; jitLadder row for row | **1600 -> 1604, only the four rows moved; jitLadder identical** |
| canary 365 | 365 |

**H7 (cure committed first):** jitNoteFor returning at its top -> jitForCursorT and jitForBodyT both back to **exit 139**;
restored md5 = the cure, both 0 again.

**SEQ 388's R3 rerun, the cursor locals included** (tapKindless + tapInfer + tapFor on the cure, clone, reverted md5 = cure;
pop.sh 1604, jitLadder PASSED, gen26 14 / 26 under the taps; `results/forCure.raw` / `.table`). The 239: 84 inferred
scalar (81 + the 3 `.plain`-tagged rows), 155 inferred non-scalar, **0 refused, 0 wrong** -- unchanged. The cursor locals:
ifTest, printDefinition and testInterpret `grup`, and fcL in both fixtures -- all **NOSLOT**; every cursor holds GROUP
at run (10 / 10); fcL and testInterpret's grup also hold COUNT (their `= 7` / `= 0`), which with no slot lives in the
field. The for-body write (fcL `:=` in jitForBodyT) is recorded, NOSLOT. A first tapped run was VOID -- tapFor's gate
anchor no longer matched after the cure, so nothing was built and its rows came from a missing binary; tapFor now anchors
on the hand-over line alone, and the run above is the re-take.
