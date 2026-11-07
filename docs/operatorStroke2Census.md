# Operator rung, stroke 2: a census of what moves (SEQ 560, 2026-11-07)

**3 rows move, from 3 fixtures: 1 bookkeeping (a), 2 value (b), both defects, 0 crashes or hangs (c). Five more fixtures change only their degrade counts and four actions become jittable, with no row pinning either.**

Read only. The dispatch's SEQ was blank; this calls it 560. Road: **emitted**.

## How it was measured

**The base is `rule-operators`, not trunk.** `gJitRuleOperators` existed only on that branch, so that is the only place it could be removed. Tony had bought it at 10:38; word had not reached this seat, and nothing was merged for the census. Base and scratch are both that commit.

**The scratch build,** uncommitted, unpushed and discarded with `git checkout -- <files>`; trunk then rebuilt, canary 444, `pop.sh` 2966, tree clean:

- the flag out, so the three emitters serve every compile;
- `jitRuleOperator`'s own-statements guard out, so inlined bodies are served too, with a refusal leaving to the inline frame's exit;
- `copyOf` flushing a slotted operand, instead of handing over;
- `jitWalkEligible` admitting `deref`, `:=`, `+%` and a `copyOf` call.

**The trace.** `INCANT` pointed at a shim that runs every input a second time, keeping its combined output and exit, then runs it for real. So it saw what pop.sh generates, not only what is on disk: **1315 inputs, the same 1315 on both builds.** The witness file was left out of the second pass, so unlike the census tap it doubled nothing.

**Positive control, because a small mover count is the result this project trusts least:** on the scratch binary an ordinary action, `h := pa; pl +% *h; m := copyOf(*h); print *m:;` under `testing`, reads degrade 0 and prints 4. The emitters were firing.

| instrument | moved |
|---|---|
| pop.sh | 3 rows; 2976 -> 2973 green; the same 7 segfaults, in the same places |
| jitLadder | 0 lines, 224 / 0 |
| printPop, decodePop, ddPop, frontier | 0 lines |
| 1315 traced inputs | 16 outputs differ, 0 exit codes differ |

## Every row that moves

| fixture | row | before | after | class |
|---|---|---|---|---|
| newJitPrintT | the walk's witness per action | `pc 2 2 0` | `pc 2 0 2` | **(a)** two statements handed over go native; the action's value row is unmoved |
| newReturnKindT | under jitter; = plain | `nh 7:6` | `nh 7:5` | **(b) defect.** Value 7 is the same; its KIND no longer matches the interpreted twin. Row pinned at 6 |
| jitterT | JTT jitted: jtTrue after jtBad's inlined jtResult | `2` | `1` | **(b) defect.** Interpreted twin reads 2 (row "JTT the interpreted twin", unmoved). Also on `jtN.src`, the parser-road copy of the same fixture |

## The two defects, by name, not chased

**1. `nh` loses its holder's kind.** `nh code={ h := 7; return h; }`. Before, `nh` was NOT JITTABLE and ran interpreted, so it read right by not being compiled. Now it compiles (`built 1 called 1`) and its return hands back a box of the count. **Pointing at a mechanism, not measured:** `jitStmtRTValueRT` follows a holder and boxes it if it holds a count, the exception already written down in F-146. So this looks like F-146's, reached by a road that did not exist before. Its old-road twin `oh` reads 7:5 on both builds.

**2. `jtTrue` counts one too few in an inlined callee.** In jitterT, `jtBad` writes `jtRead := jtZ` then calls `jtResult(zeroBump=1)`, which inlines and does `if *jtRead == argument; *jtSlot = 1; if *jtSlot == 1; jtTrue = jtTrue + 1;`. The row's own name is "the star's node on a foreign assignment", so it guards a repair already made once (M2, SEQ 423), and it is what caught this. **Silent:** exit 0, no refusal, no degrade. **Cause not looked for.** `jtRead :=` and `*jtRead` going native together is what changed; this is the row to read first.

## Moved with no row pinning it: all class (a), values equal

Reported because the certificate cannot see them.

| fixture | what moved |
|---|---|
| jitBlockCallT | degrade 2 -> 0 |
| jitBlockCtlT | degrade 6 -> 4 |
| jitBlockNameT | degrade 4 -> 0 |
| jitScCountT | degrade 6 -> 4 |
| jitStarIdiomT | degrade 2 -> 0 |
| the fixture behind `arj.k`, incant/pop/argRoadsT | nMid, oStarSrc, nStarSrc, nStar go from NOT JITTABLE to built, values unchanged |
| newJitPrintT | `pc` goes from NOT JITTABLE to built (the row above) |

The five degrade rows moved with "a value moved: no" by a full diff of each: only `JIT DEGRADE` and `jitDegrade` lines differ. **Six actions start compiling that did not compile before,** nh among them, and that is where defect 1 came from: a NOT JITTABLE action reads right by running interpreted, so each flip to `built` is a new exposure no row was written for.

## What this census does not show

- **The fleet barely exercises the walk on these operators.** Of the walk's witness rows, only `pc` moved. newJitT, newJitIfT, newJitLoopT and newJitCallT have no `:=`, `+%`, star or copyOf in their actions, so **a small mover count here is partly thin coverage, not safety.** Stroke 2 owes rows for those shapes on the walk: `x := *y`, `x := copyOf(y)`, `l +% *y`, in a loop and an if arm, with a slotted operand.
- **The scratch build is one reading of "as the recon describes".** Serving inlined bodies and flushing `copyOf`'s operand were my calls, the second because the recon said so. Defect 2 is in an inlined body. A stroke 2 that kept inlined bodies handed over might not have it, and would move other rows.
- **Correcting the recon:** section 7's "30 fixtures" and "93 lines" read as a large blast radius. That count was lexical and mostly top-level `:=` outside any jitted body. Measured, it is 3 rows.

**Ruled since (Tony, via Clay, 2026-11-07):** jitterT is cured first. Stroke 2 follows, keeping `nh`'s shape handed over until F-146, with the owed rows registered before the build, plus rows for argRoadsT's four newly compiling actions. F-146 then cures `nh`.

## The movers to register, if stroke 2 is built

| row | register as |
|---|---|
| newJitPrintT witness: `pc 2 0 2` | re-pin; two statements went native |
| newReturnKindT: `nh` | not a re-pin: needs a ruling. Hold until F-146, or keep `nh`'s shape handed over |
| jitterT JTT | not a re-pin: a defect to cure first |
