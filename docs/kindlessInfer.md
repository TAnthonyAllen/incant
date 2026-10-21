# The kindless gap, reach (b) + (c) -- branch jit-kindless-infer (SEQ 388 R2)

Ruled (Tony, 2026-10-21): R1 a kindless-at-build local takes its kind from its build-visible writer; a non-scalar never
gets a scalar slot. R2 a kindless local with no inferable writer is NOT JITTABLE -- refused by name, runs interpreted; a
net, expected 0 today. R3 reach (a) is not adopted. Recon: docs/jitter.md, "SEQ 388" (trunk 85031dc3).

## The cure, as designed (written before the build)

- **Record the writer.** `jitNoteWriter(op, target, arg)` -- one new extern in jitEmitters.rtn -- is asked at runOPdirect's
  top for every assign-tier op under jitting (GroupActions.rtn, above the handedOverEmitsNothing return, so a writer in a
  handed-over statement counts), and at aCTionIterate's jitting gate for the cursor (op null). For a target that is a
  local (isLocal, not isArgument, not noPrint) with no kind at build, it records a kind in `gJitLocalKind` (jitContext.h,
  keyed on the GroupBody): `:=` / `<-` / a cursor -> GROUP; `=` / a compound whose argument has a known non-scalar kind
  (a STRING literal, or a local already recorded non-scalar) -> that kind; any other argument the jit seeds or carries ->
  scalar. `=` with no argument in hand records nothing. A non-scalar outranks a scalar.
- **No scalar slot for a non-scalar.** The frame prologue (jitEmitters.rtn:343-368) skips a local recorded non-scalar.
  The prologue runs before the walk that sees the writer, so a local found non-scalar while it holds a slot sets
  gJitRestartNeeded, and the build loop starts over knowing it (the restart bound counts these discoveries too).
- **Its reads go to run time.** jitKindUncarried (jitEmitters.rtn:582) answers 1 for an unseeded, kindless operand
  recorded non-scalar, so runOPdirect (:1292) and jitEmitBareRead (:1303) hand the statement over -- the existing road
  for a string or a group with a kind at build.
- **The net.** After the emit walk (and only on a walk that is not about to restart), a slotted local still kindless and
  with no recorded writer refuses the compile: `NOT JITTABLE -- <action>'s local <x> is kindless and has no writer the
  build can see`, return -8. Under the jitter that is `=== jitter: <action> NOT JITTABLE (compile returned -8)`.
- `gJitLocalKind` is cleared at jitRunAction's entry; it survives the restarts of one compile. No groups.ext change
  (the extern is called inside GroupRules.mm's own include chain).

## Pre-registered movers (from R1)

1. **kindlessNetT** (new, born red at the branch point -- rows in pop.sh): KN-2 `0` -> `knLoc`; its witness
   `knRead NOT JITTABLE (compile returned -8)` 0 -> 1. KN-1 (7, knCtl built 1 called 1) unmoved.
2. **The generator** (`jitLadder/jitterCensus/gen26.sh`, 26 files, `jitter;` after Start()): the conjunct `0` -> `&&` /
   `||` in the generated bodies. Agreement with the plain twins **0 / 26 -> at least 5 / 26** -- deferNatT, definerT,
   nestNatT, quoteNatT, unaryNatT, whose only difference today is the connective. The other 21 are measured, not
   predicted. **leafClassT and zeroWidthT** (jittered exit 139 today): watched by name, not predicted.
3. **pop.sh** otherwise row for row with the branch-point run. Named unmoved: JK-1, JK-2, JOF-2, JOF-4 (and ladder JS).
   The GROUP holders lose their slots, but R1 measured no value read of any of them (the cursors' loads are `++g`'s dead
   seed), so no value is predicted to move.
4. **jitLadder** row for row (PASSED).
5. **canary 363 -> 364** (jitNoteWriter). Generated diff: the extern, its two calls, the prologue skip, the
   jitKindUncarried arm, the net, the restart bound.
6. **Not measured by R1, named in advance:** an INLINED callee's locals have no frame slot (tap E saw slots only), so a
   non-scalar local of an inlined callee now has its reads handed over too. Any mover from that is named with its action.

## H7, one per half (cure committed first)

- **Inference removed** -- jitNoteWriter records every writer as scalar (the non-scalar classification gone, the
  recording kept, so the net does not refuse generateParse and mask the control): the generator's bodies read `0`
  again (deferNatT disagrees).
- **Net disabled** -- the refusal skipped: kindlessNetT KN-2 back to `0`, its witness gone. Nothing in the fleet reaches
  the net (R1), so the constructed fixture is the pin.

## The certificate (branch: eaedef71 pre-registration, 126f2659 cure; clone, 2026-10-21)

Built bare in the clone (live paths rewritten, bare tokall = committed before the cure, build log names 0 live Groups
paths). Canary **363 -> 364**; the generated diff is the cure's lines only (GroupRules.mm: the extern, its two calls, the
prologue skip, the jitKindUncarried arm, the net, the record's clear, the restart bound; GroupRules.h: the one prototype).
One build fix on the way: jitContext.h needed `class GroupBody;` ahead of the map (the file's own idiom) and `<map>`.

| pre-registered | measured |
|---|---|
| kindlessNetT KN-2 `0` -> `knLoc`, witness 0 -> 1; KN-1 unmoved | **as registered** (KN-1 7, knCtl built 1 called 1) |
| pop.sh otherwise row for row; JK-1 JK-2 JOF-2 JOF-4 unmoved | **1579 -> 1581 green; the only moved rows are KN-2's two.** The rest of the diff is the clone's tree line, one address (acceptStartT, H3) and PIDs |
| jitLadder row for row | **identical** but the bin line (PASSED) |
| gen26: connective `0` -> `&&` / `||` | **1302 connective-`0` lines -> 0** (the plain twins: 0) |
| gen26 agreement 0 / 26 -> at least 5 | **14 / 26** -- the five predicted, plus adoptT, doWhileNameT, driveCompileT, driveLeakT, f122NatT, leafClassT, ownerT, probeFrameT, stmtRejT |
| leafClassT, zeroWidthT jittered exit 139: watched | **both exit 0.** leafClassT agrees; zeroWidthT disagrees (11,718 masked lines) |
| inlined callees' non-scalar locals: any mover named | none in pop.sh or jitLadder |

The 12 still disagreeing (baselineTestsNew 36, halfLessT 4, opLenT 6, paReachT 10,666, parserTest 2,658, probeDoorT 36,
ruleOfT 4, site1RoadsT 48, sweepT 282, termCountT 712, tokJitT 6, zeroWidthT 11,718) are other classes, not chased: e.g.
halfLessT's `0.5<1` (the halfLessFalse fixit), opLenT / tokJitT's degrade counters, printTest's `lefty`, ruleOfT's node
count.

**THE NET IS NOT 0 IN THE GENERATOR RUNS, and it is named here, not hidden:** in baselineTestsNew under `jitter;` it
refuses **9 actions** by name -- accessTest (`across`), ifTest (`grup`), printDefinition (`grup`), stringTest (`what`),
testGet (`width`), testIndentBlock (`One`), testInterpret (`Saw`), testOR (`Saw`), testUnitTests (`This`). Eight were
NEVER REACHED before the cure (the file now runs further, on a correct parser); testUnitTests was reached and refused
already (-2, nothing emitted) and is now refused earlier (-8). None ran compiled before. Two kinds of local:
- **no writer at all** -- `Saw`, `This`, `what`, `across`: a bare name printed as its own tag (bear-trap 26). Compiled,
  the print reads the slot as a count (`0`, KN-2's shape). The refusal is the ruling's case exactly.
- **a writer the recogniser does not know** -- `for grup in ...` (a for cursor), `:argument width height;` (a scope
  hoist), `++One` (a unary). The refusal is safe (the action runs interpreted), and the reach could shrink if those
  writer kinds were added. Tony's call; not built.
In the ruling's population (pop.sh, jitLadder) the net's reach is **0**, as expected; kindlessNetT is its pin.

**H7 (cure committed first, each built in the clone, each restored md5 = the cure):**
- **Inference removed** (jitNoteWriter records every writer as a scalar; the recording kept): gen26 connective-`0` lines
  back to **1302**, agreement **0 / 26**, deferNatT disagrees. kindlessNetT stays refused -- the net does not mask it.
- **Net disabled** (the refusal skipped): KN-2 back to **`0`**, the NOT JITTABLE witness gone. gen26 unchanged (14 / 26).

**R3, the census after the cure** (tapKindless.py + tapInfer.py on the cure, clone, reverted md5 = cure; pop.sh 1581,
jitLadder PASSED, gen26 14 / 26 under the taps; `results/kindlessInfer.raw` / `.table`). Every one of the pre-cure census's
**239** locals (53 distinct, 54 files):

| class | rows | distinct | files |
|---|---|---|---|
| inferred scalar -- still slotted, holds count / number | 84 | 26 | 45 |
| inferred non-scalar -- no slot, holds a non-scalar | 155 | 27 | 36 |
| refused by the net | 0 | 0 | 0 |
| wrong (slotted holding a non-scalar, or unslotted holding a scalar) | **0** | 0 | 0 |

(The table prints 81 + 3 "UNSEEN": testRecurF r, t and testRecurG r in baselineTestsNew's plain run, which the old
census tagged `.gplain` and gen26.sh tags `.plain`; the same three rows are slotted scalars holding COUNT.) The four
locals the old census never saw interpreted are classified too (their interpreted copies ran under the taps).
Newly reached since the cure, 23 locals: each refused by the net, slotted holding a scalar, or unslotted holding a group
(lcClass r) -- testInterpret's `grup` holds a GROUP while slotted, in an action the net refuses on `Saw`, so never compiled.

**Observed, not registered:** `incant/fixits/epilogueWriteBack` (Clod's lane, item 4) exits **0 with its sentinel** on
the cure (139 at the branch point): its `ewL` has a `:=` writer, so it gets no slot and the epilogue writes nothing over its
pointer. The fixit is not retired here; the buy is Tony's.
