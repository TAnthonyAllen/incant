# The `jitter;` command, first cut -- SEQ 386 (2026-10-19), branch jit-jitter

**The rulings** are in `docs/jit.md` §0 (SEQ 386 R1): `jitter;` turns on jit at first call from that point in the run
onward; actions only; no off switch, no `jitter(name)`, no `if jitter;`; a compile that fails, refuses or is
verifier-rejected marks the action NOT JITTABLE (announced once, by name, interpreted from then on, never retried);
top-level statements stay interpreted; parse bodies keep their road (`probeDrive`); an action already compiled is reused
from the cache (SEQ 385).

## R2 recon (trunk 3edc07f; taps in the clone only, each reverted md5-identical)

### (a) The call roads

Measured, not read alone: a tap in `processAction` naming its caller (`dladdr` of the return address) across every
`incant/pop` and `incant/pop/jit` fixture.

| caller of processAction | calls | what it is |
|---|---|---|
| `runAction`, interpreted arm (`GroupActions.rtn:1165`) | 8,915 | every action call by name -- `opCall`'s action case (`:596`), from both the accumulator road (`runOPaccum`, `:1240`) and the slot road (`runOPslots`, `:1290`); `opCallTest` (`Instruct.rtn:206`); and a statement a compiled body handed to run time (`jitStmtRT` runs it interpreted, so its calls arrive here too) |
| `runAction`, jitting arm (`:1149`) | 113 | an INLINED callee walked at emit time -- it never runs as a call; its code is baked into its caller |
| `GroupItem::fireLabelMethod` (`GroupItem.twk:711`) | 74 | RULE actions fired on a label during an old-road parse (JSONfield 42, JSONarray 9, list 7, ...) -- not action calls; outside R1's scope |

The roads that do not reach processAction at all: a compiled body's **call-through** (`jitEmitSelfCall` emits a direct
call to the callee's own function), **`jitRefire`** (`gJitLastFn`), **`jitFieldMethod`** (`gJitMethod`), and the probe
door. **So the one intercept is runAction's interpreted arm**, inside its save / bind / restore bracket: every first
call by name passes it, wherever it comes from. The emit-time arm must NOT be intercepted (it is a build).

### (b) The parse generator crash

Measured on the 26 files that call `parser()` (`results/genlist2`), jit at first call from the process start (the SEQ 383
tap): **26 / 26 exit 139, every one at the first fire of `generateParse`.** Not a compile crash: a stack overflow
(`EXC_BAD_ACCESS` code 2 at a stack address, in `cout`'s `__sfvwrite`), after the generator regenerates
BlocK -> leftCurly -> StatemenT -> SemI -> BlocK without end.

The mechanism, as far as it is measured:
- the compiled generateParse leaves through its **data exit** (`if datA != 0; ... uncompiled +% argument; return;`,
  `IncantForms/WorkingOn/parser:17-21`) for rules that have NO data. lldb on `opAddAttribute` with target `uncompiled`:
  interpreted, it files only data-kind rules (followedBy 3, SemI 13, leftCurly 13, ...); jitted it also files DO, do,
  StatemenT, BlocK -- all data kind 0. Warnings: interpreted 1 in 156 generations; jitted 7,061 in 14,027.
- so the generator never reaches `argument +< *bprCopy` (lldb: `opAddProperty` is not called once in the jitted run;
  interpreted it is called for every generated rule), no rule gets its `pendingParseR` carrier, and walkRules' cycle
  guard (`if *grup["pendingParseR"]; continue;`) never fires. walkRules itself is verifier-refused and runs interpreted.
- **What makes the compiled `datA != 0` read true is NOT isolated.** The same compare in a scratch action agreed on both
  roads in every shape tried (a count and a field; grammar rules as the argument; after cout / reset / printTO / print /
  dupTermRefusal; called from an iterate walk). A copy of the real generateParse did not reproduce its interpreted end
  (H16) and was discarded. It is the symptom foldAndT already pins (a jitted `x.datA != 0` reads true).

**Not cheap and local** -- the misread is not found. **The proposed predicate**, on a property of the action rather than
a list of names: *an action whose body reads a GroupFields accessor (`datA`, `listLengtH`, `hasTraitS`, ... -- the
accessor road) in a condition is not jittable* until the misread is understood. It keeps generateParse interpreted, and
foldAndT's action with it. Graded a GUESS: it is the spelling both failures share, not a measured mechanism, and its
cost (how many actions it would exclude) is unmeasured. Not built.

### (c) The switch

**A global, `gJitter`, in `jitContext.h`, beside the cache.** Its single writer is the `jitter` command
(`jitEmitters.rtn`); its single reader is the intercept, in passthrough. A ruler slot would be a field tok source
references, which owes a `.twk` declaration and a `groups.ext` mirror (SEQ 218 R1) for a value no incant code reads.
Precedent: `gJitCompileOnly`, `gJitLastFn`.

### (d) The 13 build-time-read sites against the forced census (context only)

A tap at each site (clone, reverted md5-identical) logged, per compile, every time the site read its value AT BUILD in
the class's signature: a node with no kind (data 0), no group, or not an iterator where the site decides on it. Classes
are SEQ 385's. **These are co-occurrences, not attribution** -- a site can hit its signature in a fixture that agrees,
and one disagreeing fixture usually hits several sites. The agree column is the anti-vacuity side.

| site | old road: DISAGREE / agree fixtures hit | new road |
|---|---|---|
| S1 aCTionIterate's source (`ruleActions.rtn:593-611`) | 3 / 0 | 2 / 0 |
| S2 `++` / `--` isIterator (`Instruct.rtn:904`, `:634`) | 30 / 5 | 51 / 5 |
| S3 opDeref's fall-through (`Instruct.rtn:258`) | 44 / 14 | 63 / 13 |
| S4 jitEmitDot's target | 23 / 9 | 19 / 9 |
| S5 followArgument, no slot and no group (`GroupActions.rtn:328-333`) | 20 / 0 | 44 / 0 |
| S6 jitEmitBareRead, kindless token | 43 / 13 | 61 / 13 |
| S7 jitSeedField, kindless (i32 by default) | 75 / 57 | 88 / 54 |
| S8 the frame prologue, kindless local | 62 / 47 | 77 / 44 |
| S9 the argument slot, nothing bound at build | 55 / 47 | 53 / 43 |
| S10 jitEmitAssign, kindless target | 58 / 33 | 75 / 32 |
| S11 jitEmitAdd string-or-int | 0 / 0 | 0 / 0 |
| S12 jitEmitSelfCall's argument | 33 / 10 | 55 / 10 |
| S13 jitPrintList, kindless part | 44 / 6 | 62 / 6 |

DISAGREE fixtures with no site signature at all: 1 on each road (jitCmpOperandT). DISAGREE fixtures whose only
signature is one site: S9 only (6 old, 5 new). **S1 and S5 are the only sites that never hit an agreeing fixture**; S7,
S8, S9 hit nearly as many agreeing fixtures as disagreeing ones, so their columns say little. S11 never fires.

## Pre-registered movers (written before the build)

- pop.sh: the new `jitterT` rows (born red on trunk: `jitter;` is not a command there, so the file truncates at it).
  H3: an address, the fixture-name count. Nothing else -- no fixture counts or prints `cOMMANDs` (five register into it).
- jitLadder: none.

## The build (branch f1a3aa3)

`jitter` (`incant/setup`, cOMMANDs, `immediateAction=jitter`) sets `gJitter`. runAction's interpreted arm, inside its
save / bind / restore bracket, asks `jitterReady`: a first call compiles through `jitRunAction` (stdout silenced, stderr
to `INCANT_JITTER_ERR` if set, else silenced) into SEQ 385's cache and fires; every later call fires the cached
function (`jitBoxCountRT` of its i32, as the census tap did); a refused compile (any negative code, or nothing cached)
is NOT JITTABLE -- announced once on stderr by name, interpreted from then on, never retried; a body already in the
cache (compiled by `testing()`) is reused, built 0. At exit one line per body met: `built <n> called <m>`, or
`not jittable, called <m> interpreted`. **No frame-model or signature change**; canary 359 -> 361; no groups.ext line.

## Certificate

- **jitterT** (born red on trunk 0607559 / 2a82f77 -- values agree there, the 5 witness rows absent): JT-0 1, JT-1 9,
  JT-3 2, JT-4 3 = the interpreted twin = the new-road twin. Witness: `jtAdd built 1 called 3`; `jtBad NOT JITTABLE`
  once and `jtBad not jittable, called 2 interpreted`; `jtPreA built 0 called 2` (testing()'s compile reused; one
  `entering on jtPreA` in the run); new road `jtAdd built 1 called 3`.
- **A normal run is untouched:** pop.sh 1549 branch / 1544 trunk, row for row but the 5 pre-registered witness rows
  and H3; jitLadder row for row.
- **H7** (cure committed, fixture alone under alarm): the intercept removed, so `jitter;` sets the switch and nothing
  reads it -> all four witness lines absent, values still right. Restored, md5 = the cure, rebuilt, green.
- **The jitter's refused row taught one thing worth keeping:** the second action to INLINE a helper is verifier-refused
  (-5, "Instruction does not dominate all uses") although it compiles alone -- some build state crosses from one compile
  into the next. testPrecedence's 33 refusals are this (tpAssignBare then tpAssignArg). Not chased.

## The census, for real -- no tap (`jitLadder/jitterCensus/censusJitter.sh`)

`jitter;` written into a scratch copy of each fixture, placed where SEQ 385's tap armed (old road: after `Start();`, or
after the first top-level `parser(` in the 26 generator files; new road: after the inserted `parser(Start);`). Against
SEQ 385's tap-driven table, cluster by cluster:

| class | SEQ 385 tap, old / new | SEQ 386 jitter, old / new |
|---|---|---|
| agree | 102 / 97 | 102 / 97 |
| DISAGREE | 84 / 96 | 85 / 102 |
| crash | 2 / 1 (foldAndT; parserTest old) | 2 / 1 -- the same files |
| hang | 1 / 1 (starIdiomT) | 1 / 1 -- the same |
| untouched-agree | 48 / 37 | 46 / 33 |
| untouched-DISAGREE | 0 / 0 | 3 / 0 |

(+jitterT and jitStarIdiomT, new since SEQ 385.) **Every difference, by mechanism:**
- **old, 3 untouched-agree -> untouched-DISAGREE -- the census's own control, not the JIT.** bailInc and
  baselineTests.golden have no `Start();`, and there the plain twin's do-nothing `jitterOff;` is a parse failure
  ("RunRulE: expected a method not jitterOff"); paReachT's drive trace echoes the next statement's source text.
- **new, 5 untouched-agree -> DISAGREE (andProbe, bindSeamA, opPrefixT, orProbe, parseClass) -- the TAP never armed
  there.** It armed when an action named `parser` returned; these files do not include utilities, so `parser(Start)`
  resolves to nothing and the tap stayed off. The jitter arms by position and measures them for the first time:
  value disagreements (andProbe's compiled body loses its `print +` arm markers; parseClass loses two PC / PA lines).
- **jitterT DISAGREE** -- it says `jitter;` itself, so both runs jitter; the plain run's lines are not split out.
- Bodies the jitter marked NOT JITTABLE: 71 in 24 files (old), 119 in 47 (new) -- parser / walkRules and testPrecedence
  among them. Bodies reused from a `testing()` compile: 111 on each road.

## The four structural items, ranked for the next SEQs

1. **The parse generator** -- jitter before `parser()`: **26 / 26 generator files exit 139** (measured, real command;
   the census keeps the generator interpreted by placement). The compiled generateParse takes its data exit for
   data-less rules, files no `pendingParseR`, and walkRules regenerates until the stack overflows. The misread of
   `datA != 0` is NOT isolated (R2 (b)). Highest blast, and the likeliest shared cause with item 3.
2. **foldAndT's crash** (1 / 1) -- the same symptom by its own pin: a jitted `x.datA != 0` reads true, the arm runs, and
   its `+% *kop` hands opAddAttribute a null. Do it WITH item 1: one reproducer of the misread probably settles both.
3. **The starIdiom build-time-read class** (starIdiomT hang 1 / 1; jitStarIdiomT pins it). 13 sites censused (R2 (d));
   S1 (aCTionIterate) and S5 (followArgument) are the only sites that hit their signature in disagreeing fixtures and
   never in agreeing ones, so they are the measurable start.
4. **The epilogue pointer clobber** (fixit epilogueWriteBack) -- **0 in the census by construction**: the jitter fires
   inside runAction's save / restore bracket, whose restore covers it. Reachable only through `testing()` / `jitRefire`.

The rest is the plain value disagreements: 85 / 102 fixtures, no one mechanism (cluster G).
