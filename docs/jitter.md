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

**R2 and R3 are on branch jit-kindless-infer** (eaedef71 pre-registration, 126f2659 cure, 80e4998d certificate), in
docs/kindlessInfer.md there. Not merged; the buy is Tony's.

## SEQ 389 -- the buy; epilogueWriteBack's reach; the 12 generator disagreements classified (2026-10-21)

Ruled (Tony, 2026-10-21): R1 jit-kindless-infer BOUGHT. R2 the unknown-writer refusals (for cursor, `:argument` hoist,
`++One`) stay refused -- one TODO docket line, the for cursor first; nothing built. R3 the no-writer refusals (Saw, This,
what, across) are the net working as ruled. R4 epilogueWriteBack retires only by construction, with its sentence, or is
re-aimed.

**R0, the buy (merge e339214f).** No groups.ext change on the branch. Bare tokall = branch (tree clean, canary 364).
~/bin/incant rebuilt Oct 21 10:08. pop.sh 1581 green and jitLadder PASSED, row for row with the clone's branch run but
H3 (one address; fixture-name count 272 vs 265) and PIDs. dirCheck = capture; decodePop = capture but its binary line
(refreshed). jit-kindless-infer deleted locally, on GitHub, and in the clone. TODO: "The kindless net's unknown writers".

### R1 -- can a slotted local still become non-scalar at run time? (trunk e339214f; probes are scratch copies of the fixit
### run on the trunk binary, no engine tap; each with `ewL = 7` beside the write under test)

| road | can it write a non-scalar into a slotted local? | how known | probe |
|---|---|---|---|
| jitEmitStmtRT -- a handed-over statement (`ewL := copyOf(sample)`, the fixit's own shape) | **no** -- its assign still dispatches through runOPdirect's top, where jitNoteWriter sits above the hand-over return, so the holder is recorded and the local never slotted | **construction** | exit 0 |
| a handed-over operand (jitKindUncarried at runOPdirect :1292, jitEmitBareRead) | **no** -- the hand-over is decided inside runOPdirect, after jitNoteWriter has run | **construction** | (the same) |
| jitIfRT -- a one-line `if c;  ewL := copyOf(sample);` | **no** -- the governed `:=` is still recorded | **measurement** (mechanism not traced) | exit 0 |
| `<-` (`ewL <- sample`) | **no** -- recorded as a holder | construction | exit 0 |
| `=` from a node in flight (`ewL = copyOf(sample)`, jitAssignNodeRT) | **no** -- `=` copies content and never makes the target a group holder (ewL dumps `7 int`, length 8) | measurement | exit 0 |
| **the `for` cursor** (`for ewL in sample;`) -- R2's class | **YES.** The whole FOR runs at run time ("FOR under jit -- no emitter"), its cursor write is never recorded, ewL keeps the slot `ewL = 7` earned, and the raw epilogue writes 7 over the group pointer | **measurement** | **exit 139**; lldb at GroupItem::getText (GroupItem.mm:1405): ewL gGroup = `0x0000000100000007`, `0x0000000100000001` with `ewL = 1`. Interpreted twin 0; without `ewL = 7` the net refuses ewAct and the run exits 0 |
| the `:x a b` scope hoist (`:ewArg ewL;`) -- R2's class | **undetermined** -- the run dies EARLIER, in aCTionBlocK (GroupRules.mm:107, `result = 0x1`), with or without the scalar writer, so the epilogue is never reached. A separate jit defect, found, not chased | measurement | exit 139 elsewhere; interpreted twin 0 |
| `++x` -- R2's class | **no** -- a unary step writes a count (on a cursor it is the iterate step, and iterate records the cursor) | construction | -- |

**A road exists, so (b): the fixit is RE-AIMED, not retired.** `incant/fixits/epilogueWriteBack` now drives `ewL = 7;
for ewL in sample;` -- exit 139 on trunk, gGroup `0x0000000100000007`, interpreted twin 0. NEXT: BEST GUESS -- teach
jitNoteWriter the for cursor (the TODO line); promote = this file exits 0 with both EWB lines and the SENTINEL.
**Found on the way:** a for body is itself an unseen writer -- an undeclared local written only inside it (`ewSeen = 1`)
has no writer the build can see, so the net refuses the action (measured: that variant exits 0 for that reason). The
fixit therefore writes a DECLARED field in its loop body, and says why.

### R2 -- the 12 generator files still disagreeing (cure binary = trunk's engine; gen26.sh, `jitter;` after Start())

Every file: parser and walkRules NOT JITTABLE -5 with the verifier's "does not dominate" (26 / 26, item 2's signature);
both then run interpreted, and the 14 agreeing files carry the same refusals, so **item 2 accounts for no disagreement**.

| file | first disagreeing line (plain / jitter) | compiled action | cause | class |
|---|---|---|---|---|
| opLenT, probeDoorT, site1RoadsT, sweepT, tokJitT | `=== jitDegrade count = 0 ===` / a count (and jitCompile / jitSlot counts) | -- | the jitter's own compiles move the global counters testing() prints | **counter only** (residual after the counter lines: 0) |
| parserTest | `RULEDISPATCH parseRefused ... arm=operator` (stderr) | generateParse, compileRules | measure callouts that interpreted statements pass and compiled ones do not | **expected: interpreter witness trace** (residual: 0) |
| paReachT | `CAPFIRE fireLabelMethod SemI` (stderr, traceParse) | generateParse, compileRules | the witness trace as above, plus generateParse's body-parse trace, which runs inside the jitter's silenced compile and lands in its compile log (residual after both: 3 input-divert MARKPT lines, the same parses) | **expected: witness trace + compile-log routing**; stdout agrees |
| zeroWidthT | `BLOCKRESULT items=5 ... result=true` (stderr) | generateParse, compileRules, zwSay | as paReachT (residual 3 MARKPT lines); exit 0 (was 139 before SEQ 388) | **expected: witness trace + compile-log routing**; stdout agrees |
| ruleOfT | `RULEOF nodes=1055` / `1056`, later `2079` / `2083` | roParse, generateParse, compileRules, roSink | the census agrees before any compile (1030), then reads +1 after one compile and +4 after four: each compiled action gains the `JiT` record jitRunAction mints (jitEmitters.rtn:3800), one node each (by count match, not tapped) | **other, named: an instrument counting the JiT record** -- expected by design |
| halfLessT | `HL old  0.5<1  0 ... 1.5<2  0` / `0.5<1  1 ... 1.5<2  1` (both HL old and HL new) | the compares | the interpreted twin answers 0.5<1 false; the jitted compare answers it right | **halfLessFalse** (the plain road is the wrong one) |
| termCountT | `TCC  NumbeR` / `REFUSED argument -- iterate: the source has no list [line 17]` | tcWalk (tcRule inlined) | tcRule's `iterate tcCur on argument` resolves its source AT BUILD -- aCTionIterate (S1) through the argument follow (S5) -- so every call refuses on the build-time holder instead of walking the rule's children | **build-time-read class** (S1 / S5, starIdiomT's family) |
| baselineTestsNew | `testARG: Argument is: hasGroup` / `testARG: Argument is:` (empty, all three calls) | testARG | `print ... argument` compiles the argument item as a BAKED node chosen at build (jitPrintList's pointer-or-value arm via the argument follow), not the per-call `%field` -- probe + IR: `printTok(<constant>)` | **build-time-read class** (jitPrintList / the argument follow) |
| baselineTestsNew | `printTest: ... It returns 46` / `It returns 0` | lefty (its own function), printTest | `return lefty` is a bare read of a field carrying a LIST (its code); jitEmitBareRead degrades at build ("bare read of a LIST", then "return operand produced no value") and the compiled return yields 0 | **build-time-read class** (jitEmitBareRead's list arm, a degrade that is not sound) |

(baselineTestsNew's other differing lines are compile narration -- testRecurF / testRecurG "built" vs "REUSED", because the
jitter compiled them before testing() asked -- expected by design.) **Expected-only files: opLenT, probeDoorT, site1RoadsT,
sweepT, tokJitT (counters); parserTest, paReachT, zeroWidthT (trace); ruleOfT (the JiT record).** That is 9 of 12; the
value disagreements are baselineTestsNew, termCountT (build-time read) and halfLessT (halfLessFalse).

**Found on the way, not chased:** a print inside an inlined callee, called from inside a print line, drops the CALLER's
line under the jitter (`pbL=3 code={ pbL += 43; print ...; return pbL; }` printed from `print "PB-1 [" pbL() "]":;` --
the PB-1 line is missing; without the callee's print it is 46 = the twin).

**Recommendation: the build-time-read class next -- docket item 3's remainder, starting at the ARGUMENT FOLLOW.** It is
the only class left carrying wrong values in the generator files (3 mechanisms, 2 files), and two of the three go through
the same site: the argument followed to its held node at build (testARG's print item, tcRule's iterate source; S5, with S1
for the iterate). jitEmitBareRead's list degrade (lefty) is the third. Item 2 decides only whether parser / walkRules
compile at all; it moves no value in these 26, so it is second. halfLessFalse is an interpreter defect (the jitted road is
right) and is not a jit docket item.

## SEQ 390 -- two finds pinned; the for cursor recognised (2026-10-21)

Ruled (Tony, 2026-10-21): R1 the docket order -- the for cursor (this SEQ); the build-time-read class (the argument
follow first, then lefty's list read, then the rest of the 13 sites); item 2; halfLessFalse. R2 SEQ 389 R2 amended: the
for cursor is taught now (with a second writer it earns a slot and the epilogue clobbers it); the `:x` hoist and `++One`
stay refused and docketed. R3 a new wrong-value or crash find is pinned before it is chased.

**R0 (trunk bc7b23d4): two finds pinned at today's values, fixtures only.** `incant/pop/jitPrintInlineT` -- piCall
compiled, piL inlined: the caller's PI-1 line is DROPPED WHOLE (no fragment of it), and the callee's own PI-0 print of piL
(a field carrying its code) prints EMPTY (intended 46); PI-2, a callee that does not print, agrees. `incant/pop/jitHoistT`
-- the smallest shape is one statement, `:hzArg hzL;`, in a jittered body: the BUILD crashes (jitterReady -> jitRunAction
-> jitBuildFunction -> jitExecBlock -> aCTionBlocK at ruleActions.rtn:67, GroupRules.mm:107, `result = 0x1`), exit 139,
nothing printed; twin exit 0. By inspection: aCTionScopeXP (ruleActions.rtn:837) is `extern void`. Fleet rows hold both
(an exit under an alarm, as jitStarIdiomT), so no fixit. pop.sh 1581 -> 1595 (the 14 new rows), FAIL set unchanged.

**R1 (a) -- where the build sees a for statement's writes.** aCTionFOR's jitting gate, ruleActions.rtn:496-498, hands
the whole statement to run time and returns -- the body is never walked. Before it: the cursor is `input["Looper"]`
(:485), a carrier whose group is the local; the body is `input["StatemenT"]` (:489). Nothing records either today (SEQ
388's seats are runOPdirect:1278 and ruleActions.rtn:612; neither is reached for a FOR). **The body is already BUILT**
(measured, a tree tap at the gate): StatemenT -> StatemenT -> ExpressioN, whose gGroup is the instruction -- for
`ewL := copyOf(sample)` an `acA` node with children `ewL` (isLocal), `:=` (assign tier), `acC` (the value). So the gate
can read the body's writers by a static scan of that tree, emitting and running nothing.

(b) **The cursor's kind is a GROUP holder by construction**: the interpreted loop writes it only through `Looper.group =
grup` (ruleActions.rtn:509). Measured (tapFor.py, clone, reverted md5-identical): every FORCUR observation is GROUP (8 of
8); at build the cursor is kindless (none). No cursor whose kind differs. No STOP.

(c) **Census** (tapKindless + tapInfer + tapFor; pop.sh 1595, jitLadder PASSED, gen26 14 / 26 in the tapped clone;
`results/forCensus.raw` / `.table`). FOR statements inside compiled actions: **3 cursors, all in baselineTestsNew's
jittered run** -- ifTest `grup` and printDefinition `grup` (cursor only; the net refuses both today), testInterpret
`grup` (cursor + `grup = 0;` after the loop -- SLOTTED, the clobber shape; its action is refused on `Saw`, so it never
runs compiled). All hold GROUP at run (testInterpret's also COUNT, from the `= 0`). **For-body writes into a local: 0** in
the whole population. Constructed, both roads clobber on trunk: the re-aimed fixit (cursor; exit 139, gGroup
0x0000000100000007) and a for-BODY road -- `ewL = 7; for ewOn in sample; ewL := copyOf(sample);` -- exit 139, gGroup
0x0000000100000007, twin 0 (the cursor must be a declared field, or the net refuses the action on it first).

**SEQ 390 R2 is on branch jit-for-cursor** (83f5da78 pre-registration, 071afb50 cure, 5b752e41 certificate), in
docs/forCursor.md there. Not merged; the buy is Tony's.

## SEQ 391 -- jit-for-cursor bought; aCTionScopeXP returns a GroupItem; the build-time-read recon (2026-10-21)

Ruled (Tony, 2026-10-21): R1 jit-for-cursor BOUGHT (merge ac4963c9, with the ruled sentence). R2 aCTionScopeXP is a rule
action like every other -- extern GroupItem, returning its argument unless it computes a result. R3 the build-time-read
class is recon first; a proposed cure STOPs for Tony's ruling.

**R0, the buy.** No groups.ext change on the branch. Bare tokall = branch (canary 365); ~/bin/incant rebuilt Oct 21 10:49;
pop.sh 1604 / jitLadder row for row with the clone's branch run but H3 (an address; fixture names 275 vs 269); dirCheck =
capture; decodePop's binary line refreshed; branch deleted (live, GitHub, clone); fixit queue 7.

**R1, aCTionScopeXP (trunk 595bd822, support cc9e163).** (a) Declared `void` in groups.ext:484 and defined `extern void`
at ruleActions.rtn:839 -- both since the initial commits (Groups 9db8ca6f 2026-04-09, support 674d82d 2026-05-02; nothing
older is in git). The definition returned nothing (a bare `return;` in its jitting arm, none at its foot). **It is the only
one**: of 33 aCTion externs in the .rtn / .twk files and 29 in groups.ext, every other is GroupItem, and the grammar's and
setup's named bindings add none. So no STOP. (b) Both declarations now `extern GroupItem`; the definition returns its
ARGUMENT (`input`) -- it computes no result of its own -- from the jitting arm and at its foot. One stroke, full bare tokall:
the generated diff is the GroupRules.h prototype, the signature and the two returns; no other .mm / .h moved. (c) jitHoistT
exit 139 -> 0, its output = the twin's (HZ-1, the SENTINEL); hzAct is then refused by the net on hzL (the hoist is an
unknown writer, SEQ 389 R2) and runs interpreted. pop.sh 1604 -> 1606: the two pinned rows re-pinned at the twin's values
with their sentence, two rows added (output = twin; the refusal witness); everything else row for row; jitLadder identical;
canary 365. (d) H7: both declarations void again, rebuilt -> jitHoistT exit 139, HZ-1 absent; restored md5 = the cure,
rebuilt, exit 0. **A first H7 attempt was VOID** -- the support repo's file path was wrong (`git show` needs
`./groups.ext` there), so only the .rtn went back, the build failed, and the run measured the old binary; it left two tok
debris files (GroupStak.C, groups.C, written 10:53 by that tokall), which were removed. The H7 above is the re-take.

### R2 -- the build-time-read witnesses (trunk 595bd822; probes in scratch, INCANT_PRINT_PROBE and the pre-mem2reg IR; one tap
### in the clone at aCTionIterate's no-list refusal, reverted md5-identical)

| witness | emitter, file:line | what it reads at build | what run time would give | through the argument follow? |
|---|---|---|---|---|
| **testARG** (`print ... argument`) | jitPrintList (jitEmitters.rtn:3234) -> jitEmitBareRead (:1273) | jitEmitBareRead follows `argument` to its BUILD-TIME node (the first call's `hasGroup`); that node carries a list, so it degrades "bare read of a LIST", and jitPrintList degrades the part and `continue`s -- **the item is emitted as nothing** (the degrade says "running INTERPRETED"; nothing is) | each call's own argument, through appendGroup (`hasGroup`, 35, 57) | **yes** -- jitEmitBareRead's own follow (noSideEffects.md's :1271-1288 row) |
| **printDefinition** (newly compiled) | the same, on `print ~$taG "=" argument$;` | the recursive call's build-time argument (`wrap`, which has data AND a child) -> list -> part dropped (`wrap=`); members without a list print right | the member's text | **yes** |
| **lefty** (`return lefty;`, lefty compiled as its own function) | jitEmitBareRead's list arm, then the return emitter | `lefty` carries a list (its code) -> "bare read of a LIST", then "return operand produced no value" -> the function returns its result slot, 0 | the field's value, 46 | no -- a global field read directly |
| **jitPrintInlineT PI-0** (the callee's own `print ... piL`) | jitPrintList -> jitEmitBareRead's list arm | `piL` carries a list -> the part is dropped (degrades on piL, measured) | 46 | no |
| **jitPrintInlineT PI-1** (the caller's line) | jitPrintOpen (:3342) / jitPrintClose (:3107) -- **gJitPrintBuf, ONE global slot** | not a read: the inlined callee's print opens `%printBuf1` over the caller's `%printBuf` and its close nulls the slot, so the caller's remaining items and its sink return early -- the IR has the caller's first token written into `%printBuf` and **no sink for it** | the caller's line | no |
| **termCountT** (tcRule's `iterate tcCur on argument`, tcRule inlined into tcWalk) | aCTionIterate (ruleActions.rtn:593-611, S1) via the argument's follow (S5) | at BUILD the inlined callee's `argument` is unbound (data 0, no group) -> refused, the statement handed to run time (tap: 10 build refusals, inline depth 1 and 2). **And at RUN TIME the handed-over iterate reads the field `argument`, still unbound: 170 refusals, jitting 0** -- the inlined call binds the callee's argument nowhere the interpreted statement reads it (why: not traced) | the rule's children (TCC NumbeR ...); the twin refuses only on members with no list | **yes**, both halves |

**jitPrintInlineT's two wrong values are TWO mechanisms.** PI-0 is lefty's (jitEmitBareRead's list arm, the part dropped);
PI-1 is the single print-buffer slot -- build state crossing two prints in one compile, not a read at build. (Measured on
the way: the PI-2 control's callee piQ also degrades its return, yet prints 46 -- an inlined call's value reaches the print
as a node; lefty's 0 needs lefty built as its own function, whose i32 result slot is what comes back.)

**Mapped to docs/noSideEffects.md's 13 sites:**

| site | witness |
|---|---|
| S1 aCTionIterate's source | termCountT (build half) |
| S5 followArgument | termCountT |
| S6 jitEmitBareRead (the argument follow, then `groupList`) | testARG, printDefinition (through the follow); lefty, PI-0 (the list arm alone) |
| S13 jitPrintList's part | carries S6's drop for testARG, printDefinition, PI-0 (its degrade-and-`continue`) |
| S2 `++`/`--` isIterator, S3 opDeref's fall-through, S4 jitEmitDot's target, S7 jitSeedField kindless, S8 the frame prologue, S9 the argument slot, S10 jitEmitAssign kindless target, S11 jitEmitAdd, S12 jitEmitSelfCall's argument | **no witness here** (S8's kindless locals were SEQ 388's cure; S11 never fires) |
| **no site** | **PI-1** (jitPrintOpen / jitPrintClose's single gJitPrintBuf); **termCountT's run half** (an inlined callee's handed-over statement reading an unbound `argument`) -- neither is a read at build |

### The proposed cure shape -- NOT BUILT; STOP for Tony's ruling (R3)

1. **S6, the list read: a HAND-OVER, not a degrade.** jitEmitBareRead's `groupList` arm calls jitHandOver (as its
   kindUncarried arm already does) instead of jitDegrade, so the statement runs interpreted rather than emitting a print
   with a hole or a return of 0. Covers testARG, printDefinition, lefty, PI-0. *Movers:* jitPrintInlineT PI-0 empty -> 46
   (re-pinned); gen26 baselineTestsNew's testARG / printTest / printDefinition lines agree (whether the file agrees
   whole is measured -- its compile narration differs by design); any row printing a degrade count where a list read
   occurs, named (a hand-over announces once per statement, the degrade did twice per part). *H7:* the degrade back ->
   PI-0 empty again.
2. **The inlined callee's `argument` at run time: a RUN-TIME READ.** When jitEmitStmtRT runs a statement owned by an
   inlined callee, the callee's `argument` field is bound to that call's run-time argument for the call, as the frame slots
   are flushed and reloaded around it (restored after). Covers termCountT's run half; S1's build half then hands the
   iterate over exactly as now. *Movers:* termCountT agrees (gen26 14 -> 15 if nothing else differs there), its 170
   refusals -> the twin's. *H7:* the bind removed -> the 170 refusals return. ⚠ The mechanism of the missing bind is not
   traced; a recon step (where an inlined call binds `argument` today) comes first inside the stroke.
3. **PI-1, the print buffer: a STACK, not a slot** -- jitPrintOpen pushes, jitPrintClose sinks and pops -- or, the smaller
   shape, a REFUSAL: a print whose part inlines a callee that prints is handed over. Not this class (it is build state
   within one compile), named so it is not lost. *Mover:* PI-1 0 -> 1 line. *H7:* the slot back -> the line dropped.
Order proposed: 1 (four witnesses, one site), then 2 (needs its recon), then 3.

## SEQ 392 -- S6 hands over (built); the inlined-callee argument (recon); shutdown (2026-10-21)

Ruled (Tony, 2026-10-21): R1 the build-time-read class in three strokes, in order: S6, termCountT's argument, PI-1's print
buffer. R2 S6's list arm hands its statement to run time through SEQ 384's machinery; a degrade that says "running
INTERPRETED" must be true. R3 PI-1's cure is a stack mirroring the interpreted nested-print discipline, not a refusal
(STOP if it changes the frame layout); not built this SEQ. R4 a TODO line for the 33-vs-29 aCTion externs (in). R5 this
SEQ ends the session.

**R0, the false-promise census** (tapDegrade.py, clone, reverted md5-identical; pop.sh 1606, jitLadder PASSED, gen26 14 / 26;
`results/degradeFalse.raw` / `.table`). Of 9,131 counted degrades, **36 promise a run that never happens** (their
outermost statement ends with no hand-over):

| site (the degrade's caller) | message | calls | where |
|---|---|---|---|
| jitEmitBareRead (S6) | bare read of a LIST | 15 | lefty, testARG, printDefinition, testUnitTests (8; refused by the net anyway) in baselineTestsNew; piCall, piCtl in jitPrintInlineT |
| jitPrintList | print operand part: not a constant and not a scalar read | 12 | the same statements -- S6's follow-on |
| aCTionBrancH | return operand produced no value | 3 | lefty, piCall, piCtl -- S6's follow-on |
| jitEmitShortCircuitSlots | AND/OR LEFT / RIGHT operand produced no value | 6 | jitScCountT, jitXscRT -- **NOT a false promise**: the operand runs as one run-time call (jitScOperandRT); JXD-4's values = the oracle on both fires. The tap knows statement-level hand-overs only -- a classification gap, named |

**So S6 is the only site that breaks its promise, and no other site makes a fleet row wrong: no STOP.** The rest (9,095)
were in statements handed to run time.

**R1, S6 on branch jit-list-handover** (b7d376fe pre-registration, f299e40a cure, 7493608f certificate; docs/listHandover.md
there): the print witnesses are cured (jitArgListT, PI-0, W1, printDefinition(sample)); **lefty and baselineTestsNew's
predictions are FALSIFIED** by a mechanism the pre-registration did not foresee -- a handed-over `return`. Pinned on trunk as
`incant/pop/jitReturnListT` (717c72f3): trunk exit 139; the branch exit 0 with the interpreted caller's block truncated and
no value delivered.

### R2 -- termCountT's unbound argument (trunk 717c72f3; one IR dump, one tap in the clone reverted md5-identical)

(a) **Traced.** The 170 run-time refusals are aCTionIterate's no-list arm (ruleActions.rtn, `iterate: the source has no
list`), reached from the handed-over statement's jitStmtRT run, reading tcRule's `argument` field with no group (data 0).
**The field is never bound at run time.** runAction's jitting arm (GroupActions.rtn:1160, "jitBind an INLINED callee is
walked here at emit time") binds the callee's argument AT EMIT ONLY -- `ruleArg.group = argument` -- and emits no run-time
bind. For tcWalk's `tcRule(*tcR)` the argument is a run-time deref with no node at emit time (tap: `argument=NULL
lastIsNode=1 resultNode=1`, twice), so the emit-time bind is to null, and **tcWalk's IR has 0 bindArg calls against 12
stmtRT calls**. jitEmitSelfCall has this very case handled ("A RUN-TIME ARGUMENT IS BOUND TOO", jitEmitters.rtn:2259-2299:
the published node bound through jitBindArgRT); the inline arm has no such line.

(b) **The candidate is FALSIFIED as stated.** jitStmtRT does not run the statement as the caller: it sets
`currentMETHOD.group = owner`, and jitEmitStmtRT bakes as owner the activation processAction made current at build -- for an
inlined callee, the callee's. The statement runs as tcRule; tcRule's `argument` is what was never bound.
**Found on the way:** generateParse inlines a callee with a run-time argument too (`argument=NULL`, 8 inlines in termCountT's
run) -- the same missing bind, inside the generator.

(c) **Proposed cure shape -- NOT BUILT; STOP for Tony's ruling.** The inline arm binds the callee's argument AT RUN TIME
exactly as the self-call does: lift jitEmitSelfCall's argument block (the published node, a boxed count, or the baked
operand, through jitBindArgRT) into one helper, and call it from both -- from runAction's jitting arm before
jitInlinePush, so the inlined body's run-time statements read the call's own argument. The emit-time bind stays (the walk
needs it). *Pre-registered movers:* termCountT agrees (its 170 refusals -> the twin's; gen26 14 -> 15 if nothing else
differs there); any generator file whose generateParse inlines a callee with a run-time argument -- measured, named; pop.sh
and jitLadder otherwise row for row. *H7, per half:* (1) the run-time bind removed -> termCountT's 170 refusals return;
(2) the build half is left as it is -- at emit the argument is still null, so aCTionIterate's build-time refusal still hands
the iterate to run time -- and is certified by its count staying at 10, so the cure cannot pass by silencing the build half.
A recon line inside the stroke first: whether the inline bind needs jitSaveFrameRT / jitRestoreFrameRT's pending-channel
bracket, as the self-call's does (jitBindArgRT writes gChanPend*).

## SEQ 395 -- jit-list-handover bought; Stroke B's B0 STOPS (2026-10-22)

Ruled (Tony, SEQ 395): R0 the buy; R1 Stroke B as SEQ 393 wrote it, B0 first; R2 F-129 pinned, not cured.

**R0, the buy:** merge 1b94af00 (pop.sh's jitReturnListT block and the fixture from the branch, trunk's xpLocT beside);
bare tokall = the merged tree (canary 366, +jitStmtRTValueRT; no groups.ext change); ~/bin/incant rebuilt; pop.sh 1632 =
the clone's ddA1 run row for row but xpLocT's four rows and the fixture-name count; jitLadder identical; dirCheck =
capture; the branch deleted (live, GitHub, clone).

**B0, the pending-channel bracket -- the run-time bind WOULD cross it. STOP.** Read from the source, not inferred:
- jitBindArgRT (jitEmitters.rtn, the bind both roads would share) records the callee `argument`'s PRE-BIND binding (body,
  gGroup, data) in the pending slot gChanPend* before it binds. That slot is consumed only by jitSaveFrameRT (push) and
  jitRestoreFrameRT (pop, and the old binding written back) -- the emitted self-call's bind -> save -> call -> restore,
  runAction's interpreted saveLocalFields -> bind -> body -> restoreLocalFields in emitted form. The pending entry IS
  how an emitted call un-binds its callee's argument afterwards.
- runAction's inline arm (GroupActions.rtn, jitInlinePush / processAction / jitInlinePop) emits no frame pair. A
  run-time jitBindArgRT there would (1) never restore the inlined callee's binding after the region -- the interpreted road
  does -- and (2) leave the pending entry live: the next emitted self-call WITHOUT an argument pushes it in its
  jitSaveFrameRT and its restore then rewrites the inlined callee's binding at that call's return; a next call WITH one
  overwrites it. Either way the bind reaches into another call's bracket.

**Options for Tony (none built):**
- **(a)** the inline arm emits the full bracket around the inlined region -- bind, jitSaveFrameRT(callee), body,
  jitRestoreFrameRT(callee) at the inline exit -- runAction's own order. Cost: saveLocalFields / restoreLocalFields on the
  callee at run time for every such inline, which touches the callee's node-resident locals mid-function (the frame
  slots' flush / reload is the open question).
- **(b)** a bind for the inline arm that does NOT touch the pending slot: the argument stays bound after the region,
  as the emit-time bind already leaves it. Divergence from the interpreted road (no un-bind), measurable only where a
  later read of the callee's `argument` follows the inline.
- **(c)** a channel-only pair around the inlined region: the bind records pending, a push at entry and a pop-and-restore
  at the inline exit (the frame's exitBB join, which returns and refusals already reach) -- the binding is un-done as
  the interpreted road does, and no locals are touched. Two small helpers. **Recommended**: it restores exactly what the
  pending slot exists to restore, and nothing else.

The SEQ 393 helper ("one helper for both") survives under (a) and (c): the argument block (published node / boxed count /
baked operand) is lifted as ruled; what differs is the bracket each caller emits around it.

## SEQ 404 -- docket item 2, build state crossing between builds (2026-10-23; recon, nothing built)

Ruled: none. R3's locality rule is the dispatch's: a clear at a build or compile boundary, no frame-model, signature or
groups.ext change.

### R0 -- the census (docs/jitBuildState.md; read-only, trunk 61fb455c)

Every jitContext.h global (79 lines), every `static` in the .rtn files, every ruler slot the emitters write, the callee
map, every jitData writer. **Per function build** (jitBuildFunction's head, J:175): gJitComputedVal and gJitRTCursors
(J:189-191), the builder / current function / result slot reassigned (J:265-278), then jitFlushTransient (J:299; body
J:2825) -- every gJitSeeded node's jitData nulled, the frame, arg slot, if / loop stacks, statement marks, gJitResult,
gJitResultNode, gJitPrintBuf, gJitEpilogueBB. **Per compile** (jitRunAction): gJitFnMap, gJitNeedOwnFn, gJitLocalKind
(J:3812-3815, J:4011-4016). **Holding an IR value and NOT cleared per build:** the dot triplet (H:272-274), gJitInlineFrames,
gScSlots / gScEndBlocks, gJitBoundArg; reassigned-not-nulled: gJitResultSlot, gJitBuilder, gJitCurrentFn, gJitBuiltFn.
Non-IR survivors: gJitLastIsNode, gJitStmtCanRefuse, gJitFieldResident. jitContext.h:313's comment says gJitSeeded resets
"at the top of jitRunAction"; the code does it per function build.

### R1 -- the witnesses (trunk 61fb455c's binary; taps in the clone, reverted md5-identical)

**One family, two shapes, and none of it crosses a build.** Every verifier refusal measured is "Instruction does not
dominate all uses" -- 416 messages in gen26's 26 files (parser 26 refusals, walkRules 78), 46 in testPrecedence (27
bodies refused), 2 in jitterT (jtBad, then jtResult compiled alone). LLVM reports a value from ANOTHER function as
"Referring to an instruction in another function", never as "does not dominate", so every one of them is a value made
and read inside ONE function. And seeded jitData is already cleared per function build: jitFlushTransient
(jitEmitters.rtn:2825) nulls every gJitSeeded node and is called at jitBuildFunction's head (:299) and on a discard
(:829). **The docket's premise -- build state crossing between builds -- is not what these witnesses show.**

**The mechanism: a node's jitData outlives the INLINED REGION that seeded it.** jitSeedField (:4229) hangs a fresh load on
the node; jitEmitUnary (:2666) writes its `inc` back into the same node's jitData; jitSeedOperands
(GroupActions.rtn:406) skips any operand that already carries jitData. Nothing clears a node's jitData at an inlined
region's exit (jitInlinePop, jitEmitters.rtn:2963), and the region's early exits (refusal, handed-over return) mean its
blocks do not dominate the code after the join. Taps (SEED / REUSE / INC with node, tag, value name, owning action):

| shape | witness | the stale value | made in | read in |
|---|---|---|---|---|
| **A1: copy to copy, a load** | parser, walkRules (gen26, every file) | `%unbox`, the load of **parseRefused** (node 0x103afac30) | generateParse's 1st inlined copy | its 2nd and 3rd copies' `parseRefused == 1` |
| **A2: copy to copy, an increment** | parser, walkRules | `%inc` -> `%inc581` -> `%inc1002` on **notFirstTimeThru** (node 0x103b0e6e0) | each copy's `++notFirstTimeThru` | the next copy's `++` builds on it |
| **B: callee region to caller** | jitterT JT-3 (jtBad; then jtResult alone); testPrecedence's 27 | `%unbox31`, the load of **jtMintRow's argument** node (0x1014b6500); in testPrecedence the slug-tagged argument of tpMintRow | jtMintRow / tpMintRow's `*jtMark = 0` | jtResult / tpTestResult's `*jtSlot = 1` and `if *jtSlot == 1` |

A is one source occurrence emitted N times (generateParse is inlined three times into walkRules): copy k+1 finds copy
k's jitData on the same parse node. B is different underneath: at BUILD, `*jtMark` and `*jtSlot` both resolve to
jtMintRow's argument node, because `jtMark := new(argument)` is handed over and points nowhere real yet -- so the
caller's `*jtSlot` reads the CALLEE's node. That is docket item 3's class (a build-time read of a run-time value), and
the dominance failure is only what makes it visible.

⚠ **The -5 is the lucky case in both shapes.** Where the seeding block does dominate the read (no early exit between
them), the same reuse verifies and runs: A reads copy k's parseRefused / notFirstTimeThru instead of loading copy k+1's,
and B compares the callee's argument instead of the slot. jtGood does not reach the compare (every statement in its
region is handed over), which is why it compiles.

### R2 -- the plan

**No census row that carries state across builds has a witness.** Every refusal measured is R1's mechanism -- jitData on
a node outliving an inlined REGION, inside one function -- and jitData is already flushed per function build. So, by the
relevance gate, the cross-build rows are CONTEXT, not cured:

| row (docs/jitBuildState.md) | carries across builds? | witness among the 464 messages? | disposition |
|---|---|---|---|
| gJitDotSeeded / gJitDotSeededVal / gJitDotProduct (jitContext.h:272-274) | yes -- cleared only when an `=` consumes it (J:927) or a rolled-back statement drops it (J:749) | **none** (no message involves a dot call); its re-match at J:924 needs a freed Value's address reused | context; its seat would be jitBuildFunction's head, beside gJitComputedVal (SEQ 365's same address-reuse hazard) |
| gJitInlineFrames (exitBB) | never cleared; jitFlushTransient clears its twin gJitInlining (J:2840) | none | context; safe while push / pop balance |
| gScSlots / gScEndBlocks | never cleared | none | context; safe while jitScBegin / jitScEnd balance |
| gJitLastIsNode, gJitStmtCanRefuse (bools) | survive a build | none measured | context |
| gJitResultSlot, gJitBuilder, gJitCurrentFn, gJitBuiltFn | reassigned per build, not nulled after a good one | none; no reader before reassignment found | context |

**The witnessed mechanism's seat is the inlined region's exit, not a build or compile boundary.** Pre-registered for
whichever option Tony rules (nothing built):
- parser and walkRules: no -5 in any of the 26 gen26 files (today parser 26, walkRules 78).
- testPrecedence: its 27 refused bodies (46 messages, all shape B) compile -- **only with option (c)**; a reset alone
  must leave them refused or it has made them silently wrong (below).
- jitterT JT-3: jtBad and jtResult built (today NOT JITTABLE, -5) with JT-3 still 2 -- again only with (c).
- gen26: today agree 15 / 26; a new count is a prediction to be measured, not written here.
- every other row unmoved or named.
H7 per cure: (a) the region-exit clear removed -> walkRules' -5 back; (c) the deref hand-over removed -> JT-3's -5 back.

### R3 -- STOPPED before building: neither cure is local

Local was defined as a clear at a build or compile boundary. R1's mechanism has no such seat: every stale value is made
and read inside one function build, between which jitFlushTransient already clears everything that matters. The options:

- **(a) A region-exit clear, for shape A.** jitInlinePush records gJitSeeded's size in its JitInlineFrame; jitInlinePop,
  after the join, nulls jitData on the nodes seeded since (the inline result node excepted), so the next copy re-seeds.
  Touches a C++ struct in jitContext.h (JitInlineFrame gains a field) -- no GroupBody layout, no groups.ext, no
  signature. **Not local by the definition**: a region boundary, not a build boundary.
- **(b) A per-statement clear of reused seeds.** Broader than (a); it changes what bear-trap #9's "already seeded" guard
  means across statements, and every rung reads through that guard. Not recommended.
- **(c) For shape B, the build-time deref.** `*jtSlot` / `*tpSlot` resolve AT BUILD to the callee's argument node because
  their holder's writer (`jtMark := new(argument)`) was handed over. The cure is docket item 3's: a deref whose holder
  was last written by a handed-over statement is itself handed over (or refused), never resolved at build.
  ⚠ **Order matters: (a) alone turns shape B from a refusal into a silent wrong value.** Cleared at the region exit,
  the callee's argument node is re-seeded in the caller with a fresh, dominating load -- of the WRONG node -- and it
  verifies. The -5 is currently the only thing between testPrecedence / jitterT and that answer. So (c) lands before
  or with (a), or (a) is scoped so B still refuses.

**Recommendation:** (c) first, as a build-time-read stroke under docket item 3, then (a) as a region-boundary stroke
with its own certificate; Tony's ruling on whether (a)'s seat counts as local.

## SEQ 405 -- seeded values outliving their source: (c), then (a), on jit-seed-scope

Ruled (Tony): (a) counts as local -- a field on JitInlineFrame is emitter bookkeeping. Order (c) then (a), one branch,
bought together; (a) is never bought alone. (b) is not taken.

### R0 -- the silent-reuse census (clone at trunk a120cb81; tap reverted md5-identical)

The tap gave each inlined region an instance id (pushed in jitInlinePush, popped in jitInlinePop), stamped every jitData
write with the region active at the time (JitData::setJitter and its constructor), and at every value read of a seeded
node -- argV, argV2, assignRes, bareRead, binL / binR, unary, callArg, carryCopy -- logged a read whose seeding region is
no longer active. Shape A: an instance of the same callee is active (copy to copy). Shape B: the reader is in an ancestor of
the seeding region (callee to caller). Other: neither. Each read is folded into the build that ends it: END rc 0 =
silent, -5 = refused, -8 = the net, DISCARD = an attempt thrown away for a restart. The tap wrote to a file only; pop.sh
read row for row under it (an address, the fixture-name count).

| instrument | A refused | A discarded (rc -5) | A discarded (rc 0) | A net-8 | B refused | silent (ran) |
|---|---|---|---|---|---|---|
| pop.sh | 32 (tcJ.src: walkRules) | 32 (tcJ.src: parser, walkRules) | 0 | 0 | 4 (jitterT, jtN.src: jtBad, jtResult) | **0** |
| jitLadder | 0 | 0 | 0 | 0 | 0 | **0** |
| gen26 | 832 (26 files: walkRules) | 832 (parser, walkRules) | 2 (baselineTestsNew: testUnitTests) | 2 (the same, rebuilt) | 0 | **0** |

The nodes: walkRules / parser -- generateParse's `Token` (argV, assignRes, binR), `notFirstTimeThru` (unary),
`parseRefused` (binL), each read in a later inlined copy of generateParse; jitterT -- jtMintRow's `argument` read in
jtResult (binL). **No read fits neither shape. No silent case ran in the fleet.** The one would-be-silent read: baselineTestsNew's
testUnitTests, printDefinition's `Token` (shape A) in a build that verified and was discarded for a restart; the rebuild
was refused by the net (-8), so it never ran. ⚠ So the fleet carries the shapes only where the verifier catches them.

### R1 -- the silent fixtures (trunk, born red)

Both are constructed, since R0's one silent case never runs:
- **seedScopeAT (shape A):** saDrive inlines saBump (`saN = saN + 1`) three times in a straight line; copies 2 and 3 reuse
  copy 1's load of saN. Built 1 called 1, no -5; **saN 1, twin 3. WRONG.**
- **seedScopeBT (shape B, jitterT JT-3 with nothing branching):** sbRes writes its holder by a handed-over statement
  (`sbMark := new(argument)`), inlines sbSet (`*sbMark = 0`), reads `if *sbMark == 0`. At build `*sbMark` follows the
  holder's LEFTOVER state (the first, interpreted run's node, set to 5). Built 1 called 1, no -5; **counted 0, twin 1. WRONG.**
  ⚠ Shape B needs leftover run-time state at build -- jitterT's JT-3 gets it from jtGood's run before jtBad compiles.
pop.sh 1693 -> 1705 (12 green, 2 born red: SA-1 1 / 3, SB-1 0 / 1). JT-3 and testPrecedence stay pinned as today.

### R2 -- (c) on jit-seed-scope, pre-registered (written before the build)

A `:=` or `<-` notes its target's body in runOPdirect, beside jitNoteWriter (gJitStmtHolderWrites, with the open
statement's depth); jitStmtEnd records the notes of a HANDED-OVER statement in gJitRTHolders and passes a compiled
statement's notes to its enclosing statement (which may still be handed over whole). opDeref, under jitting, hands its
statement over when its holder is recorded, before jitEmitDeref and never following it at build. Both cleared at
jitBuildFunction's head beside gJitRTCursors. No extern added (canary 372), no groups.ext change.
Movers (pre-cure = trunk c77f20be's binary; pop.sh 1705): seedScopeBT SB-1 0 -> 1 (= its twin); jitterT's witness rows
for JT-3 (jtBad NOT JITTABLE, jtBad not jittable called 2) -- jtBad and jtResult expected to build, every new value named
against the twin; testPrecedence under the census construction: its 27 -5 refusals, each one that leaves named, its rows
against the twin (today 5 of 35 differ, the *Arg rows); seedScopeAT unmoved (shape A is (a)'s). Everything else row for
row; jitLadder identical; gen26 identical. H7: the opDeref check removed -> SB-1 back to 0.

### R2 MEASURED (clone; pre-cure = trunk c77f20be's binary, cure dd405c = c92cbeed) -- (c) holds; ITS CERTIFICATE FAILS ON testPrecedence; R3 NOT BUILT

Built bare; canary **372** (no extern). The generated diff is the four blocks only.
- **seedScopeBT SB-1 0 -> 1 = the twin**, sbDrive still built 1 called 1.
- **jitterT JT-3:** jtBad now **built 1 called 2**; JT-3 2 = the twin; jtResult no longer compiled alone (its -5 is gone);
  jtMintRow's witness line `called 2` -> `called 3` (its call from jtBad's handed-over statements now reaches the jitter).
  pop.sh's two JT-3 witness rows (pinned NOT JITTABLE) go red, as registered.
- **pop.sh 1705 -> 1704**: SB-1 green, the two JT-3 witness rows red, and nothing else (acceptStartT's address and the
  fixture-name count, H3). **jitLadder identical. gen26 identical, 15 / 26.**
- **H7:** the opDeref check removed -> SB-1 **0** again. Restored from the commit: Instruct.rtn, GroupRules.mm md5 = the cure.
- **testPrecedence (the census construction, `jitter;` after Start(), against the `jitterOff;` twin) -- THE FAILURE.** Its -5
  refusals drop **27 -> 1** (tpTestResult); 9 bodies are now refused by the net instead (-8: tpAssignDot, tpPlusEQDot,
  tpPlusPlusDot, tpMinusMinusDot, tpAddAttrDot, tpAddMemberDot, tpAbsentBump, tpAbsentStep, tpReport). The newly compiled
  bodies do NOT equal the twin: **21 of its rows differ (5 before), 29 rows printed against the twin's 35**, and 21 of the 29
  read `ROW argument WANT 0 GOT n`.

**THE CAUSE IS A SECOND, PRE-EXISTING MECHANISM, and it is pinned on trunk (inlineConstArgT, 2bf88b57):** an inlined callee
handed a CONSTANT argument reads `argument` unbound in its handed-over statements -- `apShow(nine=9)` reads `argument 0`,
the twin `nine 9`, built 1 called 1, silent. **On trunk's own binary as well**, so (c) did not cause it; (c) only lets
testPrecedence's bodies compile far enough to reach it (tpTestResult(assignBare=9) is exactly that shape). Inferred, NOT
traced: Stroke B binds an inlined callee's argument at run time only for a run-time argument; a constant is bound at emit.

**STOPPED before R3**, because R2's certificate ("every value that moves, each equal to its twin") cannot be met by (c):
testPrecedence's moved values are the constant-argument mechanism's, not (c)'s. Options for Tony:
1. **Cure the constant-argument bind first** (a run-time bind for a constant argument too -- Stroke B's jitEmitArgBind
   already handles "a boxed count, or the baked operand"; the gap is which inlines emit it), then re-certify (c), then (a).
2. **Accept (c) on its own certificate** (seedScopeBT, jitterT, the fleet, jitLadder, gen26 all hold) and carry
   testPrecedence's census construction as a named mover owed to the constant-argument cure; then build (a).
3. Hold the branch until 1 lands.
## SEQ 406 -- an inlined callee's constant argument at run time (2026-10-23): R0 STOPPED

Ruled (Tony): option 1 -- the cure, then (c) re-certified, then (a); nothing bought until all three are certified.

### R0 -- dated and named (taps in the clone at trunk bb76f1e5, reverted md5-identical)

**Stroke B caused it.** inlineConstArgT: seal 194's binary (ddA1, jit-list-handover's cure, before Stroke B's bind) reads
`nine 9` = the twin; Stroke B's cure (ddB1, 0095f08b) and trunk read `argument 0`. Bought with Stroke B at SEQ 403; no
fleet row covered a constant argument to an inlined callee.

| question | measured |
|---|---|
| which statements read `argument` | both of apShow's: `apH := argument.taG` and the `cerr` -- both HANDED OVER (jitStmtRT, owner apShow) |
| what binding they find at run time | **argument BOUND -- to a box**: tag `argument`, count 0 |
| was a run-time bind emitted for this inline | **YES**: jitEmitInlineEnter -> jitEmitArgBind, BOXED -- the argument node `nine` (`nine=9`) is not a literal, has data 0 and count 0 at build and is seeded as a field load, so the bind calls jitBoxCountRT(that load) = jitBoxCountRT(0), a fresh node tagged `argument` (its fixed tag) |

**STOP (R0's condition): the read is not of an UNBOUND argument -- it is of a WRONGLY bound one.** R1's cure as written
("bind on every inline, constant or not") would not move it: this inline already binds; the bind is what is wrong. Before
Stroke B the inline bound the `nine` node itself (emit-time only), and the handed-over statements read that node, which
answers `nine` / 9 when interpreted.

**Options for Tony (nothing built):**
1. **Box only a computed value.** jitEmitArgBind boxes when the argument is a value the build computed (an emitted
   expression, a count field that HAS data); a parse-time node with no data at build -- a named value like `nine=9` -- is
   bound as itself (the baked `callArg` path it already has). Shared with jitEmitSelfCall, so the self-call's IR moves for
   such arguments too: registered movers owed.
2. **Box under the argument's own tag** (jitBoxCountRT named after the node). Fixes the name only; the value stays 0,
   because the count it boxes was never set. Not sufficient.
3. **Bind the node at run time for an inline, never a box** (the self-call keeps its box). Narrowest; it leaves an
   inlined call with a computed argument passing the node, which is what SEQ 380's box exists to avoid (its value read
   through a shared node) -- so (1) is the better split.
Recommendation: (1), certified by inlineConstArgT and testPrecedence's census construction, with Stroke B's rows
(jitInlineBindT, termCountT jitted, itRT, itBackRT, jitCursorLifeT) and jitRecur* unmoved.

## SEQ 407 -- Stroke B's bind boxes only a computed result (jit-seed-scope); then (c), then (a)

Ruled (Tony): option 1 -- box only a value the build computed, by identity; a named field binds as itself. The cure rides
jit-seed-scope with (c) and (a), bought together.

### R0 -- fixtures (trunk)

inlineConstArgT unchanged (today `argument 0`, twin `nine 9`). **inlineFieldArgT** (new): fdX = 5, a handed-over statement
sets it to 7 (`fdX = fdList["c"].listLengtH + 7`, an operand whose kind is not a count), then fdShow(fdX) inlined reads
`argument` in two handed-over statements. Today **FD-1 `argument 7`** (the value right, the box's tag), twin `fdX 7`;
FD-2 7 = the twin. Born red; pop.sh 1711 -> 1718 (7 green, 1 red).
Found on the way, not pinned (its value is pointer bits): after `fdX := fdX` the box carries **54463616** -- the bind boxes
a holder's gCount, which shares storage with gGroup. The same rule (box by data), so the identity predicate covers it.

### R1 -- the cure, pre-registered (jit-seed-scope, written before the build)

JitData gains `computed`, set where the build MINTS a value -- binResult, cmpResult, callResult, negResult, the argument
slot read (argSlot), the dot / rem / short-circuit / inline-return result channels, and jitSeedLiteral (a literal's
constant is a value the build made: Clod's reading of the ruling, since a literal has no field to bind as itself).
jitEmitArgBind boxes only an operand whose JitData is `computed`; anything else binds as ITSELF through its baked
`callArg` path, and is no longer seeded just to be boxed. No extern (canary 372), no groups.ext.

**IR movers, from a census tap on the branch's (c) binary (reverted; its pop.sh read 1717 = the branch, inert)** -- each
site where today's rule boxes an operand that is NOT computed now binds the node: the seeded load and the jitBoxCountRT
call leave that site's IR, and `callArg` (the node) replaces `argBox`:
- **inline binds of a named field**: argJitT (ajSrc), jitArithOperandT (aoA), jitCmpOperandAT (caA x2), jitCmpOperandT
  (cmA), argRoundJ (arSrc, arOther x2), inlineConstArgT (nine), inlineFieldArgT (fdX), jitterT / jtN.src (jtResult's
  zeroBump, good), seedScopeBT (seven), jitSelfFn (sfArg x2), testPrecedence's census construction (tpTestResult's 52 row
  slugs). The callee's run-time `argument` reads the field itself.
- **self-call binds of a named field**: argRoundJ (arA(arSrc) x3), jitSelfFn (sf(sfArg) x4). The callee function's
  prologue reads the field the binding names, not a box.
- **Token arguments** (literals: rsF(4), coF(3), acF(3), vcF(3), testRecurF / G(4), bRec(1)): tapped as NOT computed only
  because jitSeedLiteral did not mark them; marked now, they box exactly as today -- predicted NO move. If any Token site
  moves, the literal reading is wrong and that is a STOP.

**Value movers:** inlineConstArgT FD -> `nine 9`, inlineFieldArgT FD-1 -> `fdX 7` (both = the twin). Predicted unmoved by
value: jitInlineBindT IB-1..5, termCountT jitted, itRT, itBackRT, jitCursorLifeT, jitRecur*, jitArgChainT, jitSelfCallValT,
jitCompileOnceT, argRoundJ, jitSelfFn's rungs. ⚠ The self-call rows named above are the risk: a named field whose value
lives in the caller's frame slot is bound as a node, and only a flush makes the field current. Everything else row for row;
jitLadder identical; gen26 reported. **H7:** box always (today's rule) -> inlineConstArgT `argument 0` again.

### R1 MEASURED (cure dd407c = 10849899; pre-cure = the branch's (c) binary under the inert census tap, pop.sh 1717)

inlineConstArgT AP-1 **nine 9**, inlineFieldArgT FD-1 **fdX 7** = the twins. pop.sh **1717 -> 1719**: those two rows and
nothing else (acceptStartT's address, H3). Every IR mover registered above; **no Token (literal) site moved by value**, so
the literal reading holds. Stroke B's rows, jitRecur*, jitArgChainT, jitSelfCallValT, jitCompileOnceT, argRoundJ unmoved;
**jitLadder identical** (jitSelfFn's self-call rungs included); **gen26 identical, 15 / 26**. Canary 372. **H7:** box always
-> inlineConstArgT `argument 0`, inlineFieldArgT `argument 7`. Restored: jitEmitters.rtn, GroupRules.mm md5 = the cure.

### R2 -- (c) re-certified on top of R1 (testPrecedence, the census construction, against the `jitterOff;` twin)

- **Rows, by content: 35 = the twin's 35.** ⚠ An earlier count of 29 was the INSTRUMENT: runSection2's `print "Running"
  taG:` writes stdout with no newline, so under jit six ROW lines (cerr) land after it on one line and a `^ROW` grep missed
  them. Read by content, all 35 print.
- **Four rows differ -- assignArg, plusEQArg, plusPlusArg, minusMinusArg read GOT 7** (twin 9, 8, 8, 6). **PRE-EXISTING,
  older than Stroke B:** seal 194's binary (ddA1) and Stroke B's (ddB1) read the same four 7s. Mechanism inferred, NOT
  traced: an inlined callee's write through its argument (`tpAssignArgDo: argument = 9`, called with `*tpK`) does not
  reach the caller's field.
- **REFUSED lines = the twin's**, by name (tpNever's two).
- **`Running <taG>` lines differ** (jitted `tpBag`, `plusPlusStar` ...; twin `tpPlusPlusSub` ...). PRE-EXISTING: trunk before
  (c) also differs (`tpBag tpBag ...`). Mechanism: a bare `taG` reads lastREF, the one "referenced last" holder; the compiled
  runSection2 sees a different last reference. (c) moves WHICH wrong tag it prints, not whether.
- **Compile refusals:** -5 27 -> **1** (tpTestResult, compiled alone: a stale `unbox` in `icmp eq .., 1`, R1-of-404's shape);
  net -8 **9**, each naming a kindless local with no visible writer -- kid (tpAssignDot, tpPlusEQDot, tpPlusPlusDot,
  tpMinusMinusDot), bag (tpAddAttrDot, tpAddMemberDot), tpNever (tpAbsentBump, tpAbsentStep), tpCur (tpReport): the net
  working as designed on bodies -5 used to mask.
**No new mechanism.** tpTestResult's remaining -5 is registered as an (a) mover below.

### R3 -- (a), pre-registered (written before the build)

JitInlineFrame gains `seededAt` (gJitSeeded's size at jitInlinePush); jitInlinePop, on every exit's join, nulls the jitData
of every node seeded since, before the region's merged result is hung on its result node, and drops them from gJitSeeded.
No extern, no groups.ext. Movers: **seedScopeAT SA-1 1 -> 3** (= the twin); **parser and walkRules: no -5 in gen26** (today
26 / 78), gen26's agree count reported (today 15 / 26); testPrecedence's tpTestResult -5 expected to leave; seedScopeBT,
inlineConstArgT, inlineFieldArgT, itRT, itBackRT, termCountT jitted, jitCursorLifeT unmoved; every other row unmoved or
named; jitLadder identical or named. **H7:** the clear removed -> walkRules / parser -5 back, seedScopeAT 1.

### R3 MEASURED (cure dd407a = 019d56d2; against R1's run) -- (a) WORKS AND ITS CERTIFICATE FAILS TWICE: STOPPED

- **As registered:** seedScopeAT SA-1 **1 -> 3** = the twin; **parser and walkRules compile, no -5 in any gen26 file**
  (today parser 26, walkRules 78); seedScopeBT, inlineConstArgT, inlineFieldArgT, itRT, itBackRT, jitCursorLifeT unmoved;
  **jitLadder identical**; canary 372.
- **FAILURE 1 -- THE COMPILED GENERATOR RUNS AWAY, and termCountT jitted is Stroke B's row.** With parser / walkRules no
  longer refused, **25 of 26 gen26 files exit 139 (agree 15 -> 0)**, and **termCountT jitted exits 139** (TCR / TCC 664 -> 332,
  refusals by name moved). lldb on termCountT's: EXC_BAD_ACCESS at a stack-guard address -- a stack overflow -- with
  `Generating parse code for StatemenT` / `leftCurly` repeating to the end. **NOT NEW: SEQ 386's structural item 1** (the
  compiled generateParse takes its data exit for data-less rules, files no pendingParseR, walkRules regenerates until the
  stack overflows) -- until now the verifier's -5 on parser / walkRules was the only thing keeping it from running.
- **FAILURE 2 -- A NEW MECHANISM.** testPrecedence's tpTestResult -5 did NOT leave (registered to). Its stale value is
  `%unbox13`, made in the **`then` arm** of `if *tpRead == argument; *tpSlot = 1;` and read after **`endif`** by
  `if *tpSlot == 1` -- an if-arm to its join, inside one function and one region. Neither (a) (a region boundary) nor (c)
  (a handed-over holder: tpSlot's writer was not recorded here -- not chased) covers it. STOPPED per R2's rule.
- Rows: 35 = the twin by content, the four pre-existing *Arg rows as in R2. pop.sh 1719 -> **1716**: SA-1 green; termCountT
  jitted's runs, sentinel, TCR / TCC and refusals red.
- **H7:** the clear removed -> seedScopeAT **1**, parser **-5**, walkRules **-5** (x3), termCountT jitted exit **0**.
  Restored: jitContext.h, jitEmitters.rtn, GroupRules.mm md5 = the cure.

**Options for Tony (nothing bought; the branch holds R1, (c), (a)):**
1. **Docket item 1 first** -- the compiled generator's data exit for data-less rules (docs/jitter.md "Docket item 1") -- on this
   branch, then re-run (a)'s certificate. (a) cannot be bought while the generator's runaway is masked only by -5.
2. **The if-arm shape**: recon -- why (c) did not record tpSlot's writer, and whether the seat is the if's join (a block
   boundary, which is (b)'s family, ruled not taken) or the holder record.
3. **Buy R1 and (c) without (a)** -- contrary to SEQ 407's ruling (all three together); listed only because R1 and (c) are each
   certified on their own.
