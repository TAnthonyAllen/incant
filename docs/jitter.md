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

## Docket item 1 -- the datA misread, named (2026-10-20, kant, trunk c975df9, read-only; no engine source changed)

**R0, the reproducer:** `incant/pop/jitterDatAT`, pinned in pop.sh at today's values (12 rows; the intended values are
the interpreted twin's, asserted by their own row). DA-1 and DA-2 take a data arm they should not; DA-3 never takes one it
should; DA-C (kop has data) is the non-zero control.

**R1 (a), the mechanism, from the IR (INCANT_JIT_DUMP=2 under testing()).** The compare is a run-time LOAD, but not of
the dot's value. `jitEmitDot` computes `%dotVal` correctly and seeds it on `ruler->tempField` (Instruct.rtn:309,
jitEmitters.rtn:1568). Then `runAccCompare`'s copy-out (GroupActions.rtn:1065-1068) sees `left == tempField` and replaces
it with a fresh `acRun` built by `setContent`, which carries no jitData. `runOPdirect` -> `jitSeedOperands`
(GroupActions.rtn:1275, :406) finds the copy unseeded and calls `jitSeedField`, which bakes a load of the copy's own
count -- a copy of whatever tempField held AT BUILD. `%dotVal` is dead:

    %dotVal = call i32 jitUnboxCount(%dotRes)
    %unbox2 = load i32, ptr inttoptr (<acRun's count>)
    %cmp    = icmp ne i32 %unbox2, 0

`runAccFold`'s copy-out (GroupActions.rtn:1091-1094) is the same: `yy = kres.datA + 1` emits `add %unbox2, 1`.
So it is not a constant folded at build, and not jitEmitDot's seeded value: it is a run-time read of a build-time
snapshot. Docket item 3's class (a build-time read of a run-time value) by effect, but at a site the 13-site census did
not search: the copy-out is not gated on `jitting`, and that census's population was the `jitting` sites.

**R1 (b), history, measured both ways.** The answer follows the LAST INTERPRETED write to tempField before the compile:
`zz = 5 - 2` before -> wrong, `zz = 3 - 3` (or `1 - 1`) before -> right, same action, same binary. One unrelated compile
in between (by `jitter;` or `testing()`) moves nothing: compiled arithmetic does not write tempField at build. And the
read is frozen: compiled at tempField 0, `kres = 5` afterwards, the compiled call still skips the arm (the twin takes it).
This is why the R2 (b) scratch probes "agreed in every shape": their history left tempField at 0.

**Why the one-line form agreed:** `if c;  s;` on one line is handed to run time whole (a `stmtRT` call; its IR holds no
compare). Only an arm on its own indented line compiles the condition. Graded: measured in the IR, cause of the hand-over
not traced.

**Shared?** foldAndT: YES -- its crash follows the same history (tempField 0 before K1's compile -> exit 0, the body
skipped; 3 -> exit 139). The generator: its exit is `if datA != 0;` with an indented arm (IncantForms/WorkingOn/parser:18),
which DA-2 reproduces; that the 26 / 26 crash is ONLY this is a prediction, not measured. Item 3 (starIdiom): the same
class, a different site. Item 2 (the second inline, -5): NOT shown -- the crossing state here is the interpreter's
tempField, not anything a compile leaves behind.

**Found on the way, context (no row red):** in `yy = kres.datA + 1;` the jitted store is `assignNode(%dotRes, yy)` --
the assign writes the DOT's product into yy, not `%add`; yy reads 0 whatever the history (twin 1). The dot's
`gJitDotSeeded` / `gJitDotProduct` channel (jitEmitters.rtn:1571-1573) answering for a step that came after it: one
channel, two meanings. Not chased; unpinned.

**Proposed cure (R2, not built):** the copy-out keeps the jit value. Under jitting, at both sites, give `keep` its OWN
JitData carrying `left`'s value (`keep->jitData = new JitData(); keep->jitData->setJitter(left->jitData->getJitter());
gJitSeeded.push_back(keep);`) -- a fresh JitData, never the shared pointer, because a second dot re-seeds tempField's
(SEQ 376 R2's rule). One helper beside jitSeedOperands, called from :1065 and :1091. Dropping the copy-out under jitting
instead is wrong: `a.datA != b.datA` would read the right side's dot on both sides.
**Certificate:** jitterDatAT DA-1 1 -> 0, DA-2 1 -> 0, DA-3 0 -> 1 (pre-registered); pop.sh otherwise row for row,
jitLadder row for row; foldAndT under `jitter;` exits 0 with the body skipped; then the generator census (26 files,
jitter before parser()) re-run, with its outcome a measurement, not a promise.
**H7:** the cure committed, the carry removed at :1065 -> DA-1, DA-2, DA-3 back to 1 1 0; restored md5 = the cure.

### The cure's dispatch (2026-10-20) -- R0 census and R1 rows, on trunk

**R0, the copy census** (`jitLadder/jitterCensus/tapCopies.py`, clone at trunk 796008b; tap reverted md5-identical, no tap
string in the rebuilt binary). Population: every node copy made while `jitting` whose source carries JitData, on all three
copy roads -- `setContent` (GroupItem.twk:1724), the copy constructor (GroupItem.twk:43, which zeroes jitData), and
`copyOf` (Commands.rtn:106). A `*x = *y` GroupItem copy keeps the jitData pointer, so it cannot lose the value and is not
in the population. Validated before the fleet (H16): jitterDatAT logs runAccCompare, a fold probe logs runAccFold too,
and the interpreted twin logs nothing.

| run | copies | site |
|---|---|---|
| pop.sh (1561 green in the tapped clone) | 4 | setContent from runAccCompare (GroupActions.rtn:1065), all jitterDatAT |
| jitLadder (PASSED) | 0 | -- its fixtures carry no compiled accessor compare; the env reached the binary (bin line names the clone) |
| 26 generator files, `jitter;` after Start() (26 / 26 exit 139, reproduced) | 598 | setContent from runAccCompare, all |
| a fold probe (`kres.datA + 1`) | 1 + 1 | runAccCompare and runAccFold (GroupActions.rtn:1091) |

**No site beyond :1065 / :1091.** runAccFold's is reached by no fleet fixture, so R1 gives it a row of its own (DA-F).
runAction's copy-out (:1155) sits on the interpreted arm, past the `jitting` exit; 0 in every run.

**R1:** jitterDatAT gains DA-F (`kres.datA + 0 != 0`, runAccFold's copy-out alone; intended 0, today 1) and DA-Y
(`yy = kres.datA + 1`; intended 1, today 0 -- the dot's product stored for the sum; pinned, not cured). pop.sh 1563.

### The cure (branch jit-datA-carry) -- pre-registered movers, written before the build

The ruling: the copy-out carries the compiled value onto the copy -- a FRESH JitData holding left's value, under
jitting; not a shared pointer, not skipping the copy. At both R0 sites, GroupActions.rtn:1065 and :1091.
- jitterDatAT DA-1 1 -> 0, DA-2 1 -> 0, DA-F 1 -> 0, DA-3 0 -> 1. Nothing else in jitterDatAT moves; DA-Y (0) is
  not cured, and if it moves it is named.
- canary 361 -> 362 (one helper extern). No groups.ext change (called inside GroupRules.mm's own include chain).
- foldAndT under `jitter;` exits 0 with the body skipped (a probe, not a fleet row: foldAndT's rows run it plain).
- pop.sh and jitLadder otherwise row for row with the branch-point run in the clone (1563 green; PASSED).
- H7, the carry removed at :1065 alone: DA-1, DA-2, DA-3 back to 1 1 0, DA-F stays 0. A second H7 at :1091 alone:
  DA-F back to 1, the others stay cured.
- Measurement, not certificate: the 26-file generator census, `jitter;` after Start(). Today 26 / 26 exit 139.

### The cure -- certificate (branch 1779ceb, clone; 2026-10-20)

- **jitterDatAT:** DA-1 1 -> 0, DA-2 1 -> 0, DA-F 1 -> 0, DA-3 0 -> 1, as pre-registered; DA-C 1 and DA-Y 0 unmoved
  (DA-Y named: it does not move -- the dot's product stored for the sum is a different channel). Rows re-pinned at
  the twin's values, "green since jit-datA-carry".
- **pop.sh** row for row with the branch-point run but those four (1563 green, FAIL set identical); **jitLadder**
  identical (PASSED). Canary 362; the generated diff is additions only (the helper and its two calls).
- **foldAndT** under `jitter;`: exit 0, the body skipped, compiled -- under both histories (was 139).
- **H7 (cure committed first):** the carry removed at :1065 alone -> DA-1 DA-2 DA-F DA-3 = 1 1 0 0; at :1091 alone ->
  0 0 1 1. Each restored md5 = the cure; rebuilt and cured again.

**Measurement -- the 26-file generator census, `jitter;` after Start():** 26 / 26 exit 0 (was 26 / 26 exit 139), the
plain runs 26 / 26 exit 0. generateParse runs COMPILED in every file (built 1, called 156-164); parser and walkRules
are NOT JITTABLE (-5) and run interpreted. **Nothing crashes. All 26 DISAGREE with their plain twins** (336 to 29,981
masked lines): every generated rule is filed with an empty CodE (`StatemenT = CodE CodE`, bear-trap #26's tag echo).
**Mechanism, measured in a probe and its IR, not traced inside generateParse:** docket item 3's class -- a part's kind
read at build. `print "abc":;` into a buffer compiles to `printVal(i32 <load>)`, the literal printed as its count (3);
`pbX = pbBuf;` compiles to an assign of an i32 load of the buffer (a garbage number). Census rows jitPrintList
(jitEmitters.rtn:3139) and jitEmitAssign (:926). generateParse builds CodE from exactly these two shapes
(`print openBrace:;` / `print $taG "()";` into codeBuffer, then `CodE = codeBuffer;`). The -5 refusals of parser and
walkRules are item 2's signature, not chased.

## Docket item 3 -- a value's KIND read at build (2026-10-20)

Ruled: an emitter's choice of a value's kind is a run-time fact; read at build, it is item 3's class. R0 is
`incant/pop/jitterKindT` (born red on trunk 3d3d7f5). The cure and its certificate are on branch `jit-kind-handover`,
in docs/kindHandover.md.

### R1 census -- every emitter that picks a load, store or call by an operand's kind at build (trunk 3d3d7f5, read)

Population: every read of `flags.data` / `isNUMBER` / `isCOUNT` / `isSTRING` / `isTOKEN` / `isGROUP` in jitEmitters.rtn
(grep, then each hit read), plus aCTionPrinT's emit arm (ruleActions.rtn:722-770), which picks a road without reading a
kind. The run-time helpers at jitEmitters.rtn:2269-2294 read kinds AT RUN TIME and are out of class. The 13-site census
(docs/noSideEffects.md, SEQ 385 R2) covered the `jitting` sites in Instruct / ruleActions / GroupActions; those were not
re-read except where they reach an emitter below.

| site | the kind it assumes at build | the IR it decides | can a run-time setter change it? | in the 13? |
|---|---|---|---|---|
| jitSeedField :4024, :4035 | NUMBER -> double from gNumber; ANY other kind (string, token, buffer, group, kindless) -> i32 from gCount | the load | yes: `=`, `:=`, `<-` | yes (old :3931 / :3942) |
| jitSeedLiteral :4065 | NUMBER -> ConstantFP; any other -> ConstantInt(getCount()) -- a STRING literal becomes its count | the constant | no (a literal) -- but the kind it ignores is the text | **no -- new** |
| aCTionPrinT single-part arm, ruleActions.rtn:752 | a bare operand is a scalar: jitEmitBareRead -> jitSeedField -> printVal(i32) | the print call | yes | **no -- new** (JK-1: `print "abc";` printed 3; jitSelfFn's PREAMBLE row pinned the same) |
| jitPrintList :3139 | literal / STRING / TOKEN -> the baked node through appendGroup; else a bare read as above | pointer vs value | yes, for the else arm | yes |
| jitEmitAssign :926, :932 | the TARGET's kind: kindless or STRING -> a cast helper (jitFlush*RT); NUMBER -> double store; else i32 store | the store | yes | yes |
| frame prologue :359 | each local: NUMBER -> double slot, else i32 slot (kindless -> i32) | alloca and home | yes: the first `=` at run time | yes |
| argument slot :374-377 | the bound argument's kind: an i32 argSlot only for a scalar count | whether a slot exists | yes: the caller's argument | yes |
| jitEmitAdd :800 (opPlus) | target STRING / TOKEN -> concat call, else integer add | call vs add | yes | yes |
| jitEmitSelfCall :2179-2182 | the argument's kind: box an i32 or pass the node | the call's operand | yes | yes |
| jitEmitBareRead :1271-1288 | the argument follow (isGROUP), then groupList -> degrade | which node is loaded | yes | yes |
| :143, :706, :1274 | isArgument && isGROUP -> follow to the held node | which node | yes | yes (followArgument's row) |

Downstream only (no read of their own; they take the seeded value's LLVM type): jitEmitBinary, jitEmitCompare,
jitEmitUnary, jitStoreResult. **Overlap with the 13:** nine of the eleven rows; the two new are jitSeedLiteral and
aCTionPrinT's single-part arm. **The generator's two shapes are jitSeedField reached two ways:** the single-part print
(no constant arm) and `=`'s source (jitSeedOperands -> jitSeedField), JK-1 and JK-2.

**The kindless gap, measured on the branch:** with string / token / buffer / group operands handed over, the generator
still files `return a() 0 b();` -- `conjunct` is an undeclared local, kindless at build, given a string at run time; the
prologue made its slot i32 (:359). A kindless operand's kind is unknown at build, and handing over every kindless read
is a different blast (counters and locals across the fleet are kindless at build). Tony's to rule.

### Rider -- pop.sh's STALE check compares content (Tony, 2026-10-20)

`genLadder/.binRecord` (gitignored) holds the binary's md5 and the md5 of every top-level `.rtn` / `.twk` / `.h`. A new
binary md5 re-records with a plain `bin` line; same binary with any source changed prints STALE naming the files;
otherwise nothing. CERTIFICATE: recorded, dirCheck's bare retok (every .h rewritten, 11:05), pop.sh -> no STALE line,
1572 green. H7: `// jitSeedOperands seed` -> `Seed` in GroupActions.rtn, no rebuild -> `STALE source changed since this
binary was recorded: GroupActions.rtn`; restored md5-identical -> silent. **A first version used `diff <(...)`, which is a
syntax error under pop.sh's `/bin/sh`; it left the changed-list empty and the check SILENT -- caught on reading the run's
stderr, rewritten with temp files.** Like the mtime check, it assumes a rebuild used the current tree.

## The kindless-local census (2026-10-20, read-only, after the buy of jit-kind-handover, merge 9b526e1)

Ruled: no ruling on kindless operands yet; Premise 1 stands until the number is in. Tooling:
`jitLadder/jitterCensus/tapKindless.py` (four taps, clone only, reverted md5-identical, no tap string in the rebuilt
binary) and `kindlessTable.py`; raw lines and the table in `jitLadder/jitterCensus/results/kindless.raw` / `.table`.

**R0, the taps.** A: the frame prologue (jitEmitters.rtn, the locals walk at :359) -- every local it slots, with its
kind AT BUILD and its body. B: aCTionBlocK after each INTERPRETED statement -- every local of the running action and its
kind NOW (a kind held only inside one statement is not seen). C: runOPdirect's top under jitting -- each assign-tier op
into a local kindless at build, with its right side's kind at build. D: aCTionIterate under jitting -- the cursor.
C and D join to A on the BODY pointer (an inlined callee's local compiles under the caller's currentMETHOD, and an
assign's target is a reference node). Validated before the fleet (H16) on probeFrameT: conjunct slotted 0, holds STRING,
assigned `= "&&"`. Fleet: pop.sh (1572 green in the tapped clone), jitLadder (PASSED), the 26 generator files under
`jitter;` and plain, every run tagged by a wrapper with its fixture name.

**R1, the table.**

| | rows (fixture x action x local) | distinct (action, local) | files |
|---|---|---|---|
| locals the prologue slots | 239 | 53 | 54 |
| of which kindless at build | **239 -- every one** | 53 | 54 |
| hold only count / number at run time | 81 | 23 | -- |
| hold something else -- inferable at build | 153 | 26 | 34 |
| hold something else -- NOT inferable | **0** | **0** | 0 |
| never seen running interpreted | 5 | 4 | 4 (jitSelfFn sfLoc; kindJ1T, kindLiftT kjWalk g; kindSRT srE, srL) |

The 26 non-scalar, by what they hold and how the build can know it: **25 GROUP** -- holders made by `:=` (generateParse
codeCopy / bprCopy, the `v` `m` `c` `n` of exSay / lcSay / zwSay / roParse, BJ code / block / nm, scDriver scH), by `<-`
(roParse roCp), or iterate cursors (generateParse and walkRules grup, displayForm grup, itWalk g, jdRun jdCur, jitJUi g,
tcWalk tcR); **1 STRING** -- generateParse's `conjunct`, assigned from a string literal. Run-time kinds were found in the
same fixture for 87 rows and in another fixture (a jitted fixture's interpreted twin is pop.sh's sed copy) for 147; no
(action, local) holds different kinds in different files, so the join conflates nothing.

**R2, three candidate rules, reach measured (no build):**
- **(a) every kindless read hands over.** Reach: all 239 / 53 / 54 -- every local read in every compiled action, because
  no local has a kind at build. The 23 scalar locals (counters, lengths) lose the jit with the rest.
- **(b) infer a local's kind from its build-visible writer** (`:=` / `<-` -> holder, iterate -> cursor, `=` of a known
  kind -> that kind) and give an inferably non-scalar local no scalar slot. Reach: 153 / 26 / 34; covers every
  non-scalar local measured. Of the 26, ONE is a value kind read as a value (conjunct -- the generator's remaining
  disagreement); the 25 GROUP holders are reached through `*`, iterate and `:=`, and whether any is ever read through
  its i32 slot is NOT measured.
- **(c) an action with an uninferable non-scalar local is NOT JITTABLE.** Reach today: 0 -- a net that costs the fleet
  nothing and catches the case (b) cannot see.
STOP for the ruling.

## SEQ 388 -- the kindless gap, reach (b) + (c) (2026-10-21)

Ruled (Tony, 2026-10-21): R1 a kindless-at-build local takes its kind from its build-visible writer, and a non-scalar
never gets a scalar slot. R2 a kindless local with no inferable writer is NOT JITTABLE (refused by name, runs
interpreted) -- a net, expected 0 today. R3 reach (a), handing over every kindless read, is not adopted.

**R0 (trunk e6d01d07).** testOP and tester were already committed (3e43f71f, Tony's name); the one dirty file,
IncantForms/WorkingOn/macros, committed. Bare tokall = HEAD byte for byte (canary 363); the generated diff since seal 186
is testOP's hunk only (GroupRules.mm, 12 lines: argument = field[2], target = field[3], recursion on tag `instruct`, a
null-guarded target, the unary applied to argument, a `testOP:` trace line). ~/bin/incant rebuilt Oct 21 09:40. pop.sh
1572 and jitLadder PASSED, row for row with a seal-186 clone binary (53868dab) run against the same tree, but the bin
line, one address (acceptStartT, H3) and PIDs. testOP has no fleet rows of its own; nothing moved.

**R1, recon (clone at e6d01d07; tapKindless.py + a fifth tap, tapKindlessRead.py; reverted md5-identical, the
untapped binary carries no tap string).** Tap E reads the emitter's own IR just before the verifier -- after every
handed-over statement has been rolled back (jitStmtEnd), so it is what the compiled code reads -- and logs every load of
a frame slot with its users. A `frame` load is jitSeedField's: the slot read AS A VALUE. rtFlush / rtOld / opFire* go
through the kind-checked helpers; `epilog` is the raw store back to gCount (item 4). Validated (H16) on probeFrameT: the
conjunct load feeds appendGroupValue, walkRules' length feeds icmp. Fleet: pop.sh (1572 in the tapped clone), jitLadder
(PASSED), the 26 generator files `jitter;` after Start() and plain (`jitLadder/jitterCensus/gen26.sh`: 24 exit 0,
leafClassT and zeroWidthT 139, 0 / 26 agree -- seal 185's numbers). Taps A-D reproduced the earlier census line for line
(SLOT 250, ASSIGN 281, ITER 61, HOLDS 3155). Raw and table: `results/kread.raw` (bookkeeping loads trimmed),
`results/kread.table`, `results/gen26.trunk.txt`.

(a) **No GROUP holder is read as a value through its i32 slot.** Per local, value reads (`frame` loads) in compiled code:

| GROUP holders, by writer | value reads | users |
|---|---|---|
| `:=` / `<-`: generateParse codeCopy, bprCopy; exSay, lcSay c m v; zwSay c m n v; roParse roCp, v; BJ code block nm; scDriver scH | **0** | -- |
| iterate cursors: walkRules grup 208, generateParse grup 26, displayForm grup 3, itWalk g 3, kjWalk g 4, jdRun jdCur 2, tcWalk tcR 2, jitJUi g 1 | 249 | **none -- every one is a dead load** |

The cursor loads are `++g`'s seed (jitSeedOperands on the unary; its isIterator arm then emits a pointer step through
jitEmitIterStep and never touches the value; jitIterTwice's IR shows `%frame` with no use beside `%iterNext`). Every GROUP
holder still gets an `epilog` raw store per compile -- item 4's hazard, unreached in the fleet by construction.

(b) **Where the build sees each writer, and where the inference is asked.** The writers, all in the emit walk:
`:=` (opSetGroup), `<-` (opRebind), `=` / compound of a known kind (`= "&&"`, a STRING literal) -- runOPdirect's top,
GroupActions.rtn:1278, ABOVE the handedOverEmitsNothing return at :1280 (a writer in an already handed-over statement is
seen only there; tap C sat there and saw all 281); the iterate cursor -- aCTionIterate's jitting gate, ruleActions.rtn:612.
The inference is ASKED in two places: the frame prologue, jitEmitters.rtn:343-368 (whether the local gets a slot), and
jitKindUncarried, jitEmitters.rtn:582 (whether a read hands over; asked by runOPdirect :1292 and jitEmitBareRead :1303).
The prologue runs BEFORE the walk that sees the writers, so the fact must come from an earlier walk: the build loop's
restart (gJitRestartNeeded, jitEmitters.rtn:3642 / :3658 -- "start over knowing one more thing") carries it.

(c) **conjunct is the only non-scalar value read.** Its one `frame` load per compile feeds appendGroupValue (26 / 26
generator files) -- the generator's `0`. No other of the 26 non-scalar locals has a value read with a user.

**The STOP check -- writer against run-time kind, every row: no disagreement.** `:=` / `<-` / iterate -> GROUP and all 25
hold GROUP (roCp `<- COUNT-source` and BJ code `:= STRING-source` included -- `:=` / `<-` make a holder whatever the
source); `= STRING` -> conjunct holds STRING; every other writer is `=` / `+=` of a count, a number, or a value the jit
carries, and those locals hold COUNT / NUMBER (nmF t NUMBER). The four never seen interpreted were run interpreted under
the tap in copies of their fixtures: sfLoc COUNT (`= sfDepth`, a kindless global the jit seeds as i32), srE, srL COUNT,
kjWalk g GROUP -- each agrees.

**Found for R2, measured, not predicted:** of the 26 generator disagreements, the connective alone explains **5**
(deferNatT, definerT, nestNatT, quoteNatT, unaryNatT -- `&&` / `||` mapped to `0` in the plain run makes the two equal);
21 have further differences, possibly downstream of the wrong parsers.
