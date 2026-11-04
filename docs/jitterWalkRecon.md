# The jitter walk -- recon (SEQ 519, 2026-11-03, read only, nothing built)

The ruling (docs/jitter.md, 2026-10-31): the new road's jitter walks the finished instruct chain at an action's first
call, writes IR, and any node it cannot emit falls back to `testOP`. The reasoning is `docs/instructJitter.md`.
Trunk ebcee005, the installed binary; probes in the scratchpad, no engine source changed.

## The finding the recon opened with

**Today `jitter;` does not fall back on a new-road action -- it crashes.** Measured on all five new-road fixtures
(newLocalT, newCallBindT, newReturnT, newReturnSelfT, newLocalArgT), `jitter;` inserted after the builds:

| fixture | NOT JITTABLE before the crash | exit |
|---|---|---|
| newLocalT | nlRPn (-2), nl1n (-8), nl2n (-8) | 139 |
| newCallBindT | cbRPn (-2) | 139 |
| newReturnT | rtRPn, rt1n, rt2n (-2 each) | 139 |
| newReturnSelfT | rtRPn (-2) | 139 |
| newLocalArgT | nlRPn (-2) | 139 |

-2 is "no result emitted"; -8 is "a slotted local is kindless" (jitEmitters.rtn:422, :439). The crash (lldb, newCallBindT
CB-2): `runAction -> jitterReady -> jitRunAction -> jitBuildFunction -> jitExecBlock -> testOP -> opSeq -> opBodySeq ->
testOP -> opMinus -> jitEmitBinary`, null `jitData` (GroupRules.mm:4525). jitBuildFunction walks the action's BlocK the
old-road way with `jitting` on; a new-road BlocK is bound to testOP (GroupActions.rtn:141), so testOP runs the chain and
each op's own jitting gate fires on operands nothing seeded. **Any new-road action with arithmetic segfaults under
`jitter;` today.** No fleet row runs `jitter;` on a new-road action, so nothing pins it. Reported, not fixed.

## (a) The op set, and the C++ emitter each could reuse

The Operators entries a new-road chain can hold (kantGrammar's builders plus every operator EXPRESSIOn builds).
Line counts are each extern's span in jitEmitters.rtn.

| op | reuse | lines | note |
|---|---|---|---|
| `seq` | none -- the walk itself | -- | statements in order in the current block; catches a break: needs a block-exit target (below) |
| `bodySeq` | none -- the walk itself | -- | as seq, no target pushed; the break goes on to the loop |
| `ifThen` | jitIfBegin / jitIfElse / jitIfEnd | 27 / 18 / 13 | take no arguments, read the condition in gJitResult. The old driver jitEmitGIF (55) walks old-road nodes and is not reused; its rules (fresh condition, commit per arm, clear after) are copied |
| `whileLoop` | jitLoopBegin / jitLoopBody / jitLoopEnd | 23 / 21 / 16 | push / pop gLoopCondBlocks and gLoopExitBlocks. Old driver jitEmitWHILE (27) |
| `doLoop` | jitDoBegin / jitDoCond / jitDoEnd | 18 / 11 / 20 | old driver jitEmitDO (30) |
| `forLoop` | the loop brackets + jitEmitIterStep / jitEmitIterStepBack, jitNoteFor | 35 / 28, 37 | old road compiles `for` through these; the new walk's binding of the cursor is unmeasured |
| `iterateOn` | jitEmitIterate | 30 | takes the old road's input node; the new operand list [cursor, source, attrs, members] would need an adapter |
| `branchSignal` continue | jitEmitContinue | 22 | branches to gLoopCondBlocks.back() |
| `branchSignal` break | **none** | -- | the old road degrades it ("break under jit -- no emitter yet", ruleActions.rtn:150). gLoopExitBlocks already exists, so a jitEmitBreak is jitEmitContinue's mirror, about 20 lines |
| `branchSignal` return | jitEmitReturn | 63 | stores the result slot, branches to the epilogue |
| `printList` | jitPrintOpen / jitPrintItem / jitPrintClose (jitPrintList, jitPrintArm) | 30 / 86 / 40 (68, 13) | take the old road's PRINT node and PrintXP items; whether the new road's print-item list has the same shape is unmeasured |
| `cerrList`, `coutList`, `printShortcut` | none | -- | the old road hands cerr to run time (aCTionCerR's jitHandOver); fallback |
| `call` | jitEmitSelfCall (self-calls); jitInlinePush / jitInlinePop / jitEmitInlineEnter / jitEmitArgBind (inlined callee) | 161; 28 / 57 / 18 / 54 | the old road inlines a callee through runAction's jitting arm; a new-road callee's body is itself a chain, so inlining means walking it |
| `runRule` | none | -- | a C++-only statement (bridge-run); permanent fallback |
| `deref` | jitEmitDeref | 39 | |
| `negate` | jitEmitUnary | 73 | |
| arithmetic `+ - * / %` | jitEmitBinary + jitEmitAdd / Sub / Mul / Div / Rem; jitEmitConcat for text | 47 + 17 / 8 / 21 / 14 / 47; 26 | the ops' own jitting gates call these (Instruct.rtn) -- reached only after the operands are seeded |
| compare `== != < <= > >=` | jitEmitCompare + jitEmitEQ / NE / LT / LE / GT / GE | 64 + 15 / 16 / 16 / 6 / 19 / 16 | registered as jitEmitter= slots in setup |
| logic `&& \|\|` | jitEmitShortCircuitSlots, jitScBegin / jitScEnd | 38, 40 / 49 | short-circuit needs blocks, so the walk drives it, not the op |
| assign `=` and the compound assigns | jitEmitAssign (+ jitEmitBinary) | 179 | opAssign's jitting gate |
| `++ --` | jitEmitUnary / jitEmitIterStep(Back) | 73 / 35 (28) | |
| `.` | jitEmitDot | 51 | |
| the rest (`:=`, `<-`, `+%`, `+<`, `:.`, `IN`, `~=`, ...) | none found | -- | fallback |
| operand seeding (every op) | jitSeedField / jitSeedLiteral / jitEmitBareRead | 49 / 31 / 54 | runOP seeds today (GroupActions.rtn); testOP never does -- the crash above |

## (b) What the walk needs, and whether it exists

| need | exists? | where |
|---|---|---|
| break / continue targets | **mostly.** The loop stacks exist (gLoopCondBlocks, gLoopExitBlocks). Which block catches a break is now the op: `seq` catches (push a block-exit target), `bodySeq` passes (push nothing) -- loopOwnsBody's rebinding is exactly the information a top-down walk needs. Missing: the block-exit stack for seq, and jitEmitBreak | jitEmitters.rtn:905, 3317 |
| the frame: locals | **yes.** jitBuildFunction's prologue walks the action's attributes (isLocal / isArgument); the new road's build-time locals (Ruling A, minted on the owner by resolveName) are the same attributes | jitEmitters.rtn:366-368 |
| the argument slot (SEQ 380) | **yes.** Filled at entry from the caller's node | jitEmitters.rtn:389-390, jitArgSlotRead |
| return's value riding up | **yes** for the emit (jitEmitReturn); the walk must hand the value in gJitResult first, as aCTionBranch does | ruleActions.rtn:133-148 |
| the per-node testOP fallback | **yes, at statement grain.** jitEmitStmtRT (91) emits a run-time call to jitStmtRT (32), which runs `statement.gMethod(statement)` -- an instruct's method IS testOP -- and maps a return / continue / break left set to codes 2 / 3 / 4 the emitted code acts on. For a sub-expression that needs a value back: jitEmitOpFire (112) / jitOpFireRT (12) | jitEmitters.rtn:2468 |
| the first-call hook | **yes.** runAction -> jitterReady -> jitRunAction -> jitBuildFunction (the crash's own stack). The new walk is a branch in jitBuildFunction: a BlocK bound to testOP walks the chain instead of jitExecBlock | GroupActions.rtn:141 marks the BlocK |

## (c) The population

**32 fleet actions are built wholly on the new road** -- 31 through `nlNew` (KantGrammar's STARt): newCallBindT 9,
newReturnT 10, newLocalT 7, newLocalArgT 2, newReturnSelfT 2 -- and whileT's `wrN` through `whNew`. (compileInT's
builders set no rule, so they build on the old road; the 31 `nlOld` twins are old road by design.)

Interpreted, 31 of the 32 run equal to their old-road twins (their rows are green). **One does not, by cause:**
- `nl3an` (newLocalArgT AL-3a) -- `lv3a = argument` copies a holder; the action meaning, ruled (SEQ 504, argumentCensus.md (c)).

Outside that population: **CC-6** (cmdCallT) is a top-level call through FILe with empty `()`, not an action build; and
"a kant action that hands up nothing builds nothing, silently" has no fleet instance -- it was measured in scratch
grammars only (seal 312).

Under `jitter;` all 32 are unreachable today: every fixture crashes as above before its first new-road action can compile.

## (d) A plan in strokes, each with its certificate written before its build

Every stroke's twin is the same fixture run WITHOUT `jitter;` (testOP interpreting the chain). Every row asserts values
and block topology, never IR text (H3). Fixtures run one process each under an alarm (H5).

| stroke | what it builds | pre-registered certificate | H7 |
|---|---|---|---|
| **S0** (trunk) | fixture `newJitT`: one action per row, built by nlNew, run under `jitter;`, born red. First row `nj1 code={ print 7:; };` | rows red today by exit 139 / NOT JITTABLE; the twin rows green | -- |
| **S1** | the walk's skeleton: jitBuildFunction sees a testOP-bound BlocK and walks the chain; EVERY statement falls back through jitEmitStmtRT | nj1 compiles (no NOT JITTABLE), prints 7, = twin; handed-over count = statements; the five new-road fixtures under `jitter;` no longer crash; fleet row for row | the branch removed: the crash returns |
| **S2** | `seq` / `bodySeq` walked natively; arithmetic and assign with seeding (`x = 3 + 4; return x;`) | IR has the add, no hand-over for that statement; value = twin; degrade 0 | the seed step removed: hand-over (or crash) returns |
| **S3** | `ifThen` through jitIfBegin / Else / End | both arms by value, a no-else row; topology then / else / endif | condition fallback: the if hands over |
| **S4** | the loops and break / continue / return; jitEmitBreak; seq's block-exit target | whileT / doT / forT shapes = twin; WH-3 / WH-6 / WH-7 break shapes; TL-10's braced break | the bodySeq / seq distinction ignored: WH-3 reads 1 2 3 |
| **S5** | printList (and the sinks, if the item shape matches) | printing rows = twin | fallback count returns |
| **S6** | `call` (self-call, then a callee chain) and return riding up; AL-3 shapes | newReturnT / newReturnSelfT under `jitter;` = twin | -- |

## (e) Kant or C++ first?

**C++ first.** The walk drives an IRBuilder through some thirty existing emitters, the frame, the epilogue, verify and
the cache -- all inside jitBuildFunction, all C++, and "an IRBuilder emitter can never be kant" (docs/jit.md §0).
The kant route is textual IR: it needs `compileIR(buffer)`, a field's address as text, and kinds at first call, and none
exists (instructJitter.md §5), plus an unmeasured question of whether a kant string carries IR text intact.
**What keeps the door open:** make the dispatch DATA -- an Operators attribute naming each op's walk step, as
`jitEmitter=` already does for the compares and arithmetic -- so a later kant walk (after chainOP) replaces the dispatcher,
not the emitters.

## Docket (SEQ 521, 2026-11-03)

- **S0 + S1 bought** (merge 3dbec07c): the walk with every statement on the fallback; newJitT green.
- **The non-count return channel, rides with S4.** A compiled function returns `i32` and runAction boxes the value as a
  count (jitBoxCountRT), so a return of a non-count value reads 0 -- on both roads' compiled functions. Pinned born red:
  newReturnT RT-5 / RT-5f / RT-5p under `jitter;` (0, intended `rx`). The old-road twins lose theirs the same way.
- **S1b, next:** nl3an under `jitter;` runs away (pinned born red); the measured cause decides the cure.
- **S2 (SEQ 522 / 523):** a statement built only of `=` and the `jitEmitter=` operators is compiled through the old road's
  runOPslots, unchanged, inside aCTionBlocK's statement bracket; everything else is handed over. No per-statement result
  store (A3); a statement reading the argument binding stays handed over.
- **The next opener, (a):** kindless-local inference that tells NUMBER from count. SEQ 388's net gives a kindless local one
  scalar kind (5), and the prologue slots a kindless field as i32, so `a5 = 3.5; b5 = a5 + 1` compiles to 5 -- on both
  roads (probe on the old road: 5; plain 4.5). Pinned: newJitT NJ-5. jitLadder is the control. Then S3 (if).

## S3 (SEQ 525, 2026-11-04) -- ifThen through the jit brackets; branch new-jit-s3, pins on trunk

**Built:** `jitWalkStmt` is one statement of the walk. An ifThen whose condition is an instruct the walk emits natively goes through
jitIfBegin / jitIfElse / jitIfEnd, each arm walked by the same step (a seq arm statement by statement), under jitEmitGIF's rules: nothing in
flight before the condition, none after each arm; a condition that hands over or carries no boolean hands the whole if over. No result
store (A3). The net's arm stack carries native arms; `jitScanArmsChain` the rest. Two stays on the fallback: a **bare condition** (`if x;`,
truthOf is the interpreter's and the emit does not repeat it), and **a seq arm holding a branch signal** (that seq catches a break, and the
block-exit target is S4's). Witness counts now include arm statements. Canary 409 -> 412 (jitArmHasBranch, jitWalkIfNative, jitWalkStmt).

**Certificate:** newJitIfT = its twin on every shape (each arm by value, no else each way, nested, or chain, seq arm with a fallback inside,
return in an arm taken and not, a number crossing the compare, conditions that hand over, break in each arm shape). Witness as pinned; i1's
topology then else endif, one each; ia's none. pop.sh 2458 -> 2461 + the unset control, 60 FAIL rows + newJitIfUnsetT; jitLadder 224 / 0 row
for row. NJ-7 (added on trunk) keeps the fallback's flush-and-reload test now NJ-6's if is native. gen26 24 / 2, per file as before.

**H7 (cure committed first; single fixtures, alarm; binary byte-identical after):**
| control | newJitIfT values | witness / blocks | other |
|---|---|---|---|
| condition falls back: the if hands over (the recon's H7) | = twin | i1 back to 3 2 1; then 27 -> 0 | newJitIfUnsetT's new road reads `un` |
| the seq-arm branch guard removed | **id loses its 2** | then 27 -> 29 | |
| native arms not noted to the net | = twin | | kindArmNetT refusals 2 -> 1 (the new road's gone) |

**The divergence S3 opens on the new road, pinned red (newJitIfUnsetT):** `if 1 > 2; u = 1; print u:;` prints `u` plain and `0` compiled.
The build saw `u` written, so gJitFrameAssigned has it, and the flush before the handed-over print stamps a count, though the run never wrote
it. The old road has always read 0 here (same row). On trunk the new road reads `u`, because its if hands over whole (H7 row 1): **this
stroke moves that shape from right to wrong.**

**Docket, found on the way, on trunk today:** an OLD-road action calling a new-road action under `jitter;` segfaults at compile
(jitEmitCompare, null jitData, through opCall -> testOP): inlining runs the callee's chain with jitting on. No row reaches it. Its first
sighting was a `rg = i8()` action that `ifNew` left on the old road; why it stayed there was not chased.

## The unset slot (SEQ 526 R2, 2026-11-04) -- branch unset-slot, both roads

A kindless local's slot carries a **written mark**: an i32 alloca, 0 until a compiled store runs. `gJitFrameAssigned` says a store was EMITTED;
the mark says it RAN. **The invariant: while the mark is clear, the field is the truth**, because only a handed-over statement or an op-fire
can have written it, and both reload. Clear, a flush stamps no kind (jitFlush{Count,Number}{Slot,}MarkRT) and a bare print reads the field,
whose tag is what the interpreter shows (appendGroupMarked, appendGroupNumberMarked). Canary 412 -> 418.

**Certificate:** newJitIfUnsetT: `un` and the old-road twin `uo` compiled, both born red. pop.sh, the two rows flip, nothing else; jitLadder 224 / 0
row for row. **H7 (the mark always reads written):** both read 0 again; binary byte-identical after.

**Past its reach, pinned red, a decision for Tony:** UA and UC. A native statement has already emitted its read, so `v = u + 1` reads 0 + 1 (plain
refuses) and `v = u` copies 0 (plain copies the tag's text). Reaching them needs a statement to branch on the mark and fall back.

## S4 (SEQ 526, 2026-11-04) -- while, do, break, continue, a computed return; branch new-jit-s4, pins on trunk

**Built:** `jitWalkStmt` now also takes whileLoop and doLoop through jitLoop* / jitDo*, a break to `gJitWalkBreak.back()` (a seq's exit or a loop's;
a bodySeq pushes nothing, which is the whole distinction) or the epilogue, a continue to the innermost loop's condition or the epilogue, and a computed
count return through jitEmitReturn. A condition that cannot emit gives the whole statement up, after popping the loop's stacks; a `do` gives up a body it
already walked, the roll-back taking it and `jitWalkHandedBack` restoring the counts. A statement handed over whole carries `jitWalkBranches` (a seq keeps
its own break, a loop both) and `jitEmitStmtRT` lands its break through the walk's stack. S3's guard on a seq arm holding a branch is gone: the arm has an
exit. Canary 418 -> 419 (jitWalkBranches, jitWalkCondOK, jitWalkHandedBack in; jitArmHasBranch, jitWalkIfNative out).

**Stays handed over:** `for` and `iterate` (their cursors are now recorded as holders, so lj compiles around them; the recon's "binding unmeasured" stands);
a bare return or a bare condition; a return of a double. **The non-count return channel (docket, "rides with S4") is NOT in this stroke:** RT-5 / RT-5f /
RT-5p stay pinned red. The recon's S4 certificate does not name it.

**Certificate:** newJitLoopT = its twin on all shapes (WH-3 / WH-6 / WH-7 and DO-1..7 in action form, TL-10's break in a braced arm, return bare and computed,
handed-over break and continue landing on a compiled loop and on a compiled seq arm). The FR rows' shape only as lj, handed over. Witness as pinned; topology
l1 cond loopexit body, l5 dobody docond doexit. pop.sh + the new rows, no FAIL row moves but the pinned ones; jitLadder 224 / 0 row for row; gen26 24 / 2, per file.

**H7 (cure committed first; single fixture, alarm; binary byte-identical after):**
| control | what moved |
|---|---|
| the bodySeq / seq distinction ignored (the recon's H7) | l2 reads 1 2 4 5 8; l4, l7, lb the same way. The recon's "WH-3 reads 1 2 3" is this on WH-3's bound of 3 |
| a handed-over break ignores the walk's stack | ln loses its 3 |
| a handed-over statement's branch unread | lb and lc end the action at the signal: 1, no 8 |
