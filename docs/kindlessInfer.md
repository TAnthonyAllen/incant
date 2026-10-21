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
