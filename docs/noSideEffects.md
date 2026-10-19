# Compiling has no side effects -- SEQ 384 R1 (2026-10-19)

Tony's ruling (SEQ 384 R0, `docs/jit.md` §0): a statement the jit cannot emit becomes a RUN-TIME call that runs it on
the interpreted road. Nothing executes at build time. This file is the census taken before the build, and the
pre-registration of every row expected to move. Branch `jit-no-side-effects`.

## Census -- every place a statement or command runs while jitting is on (trunk bfffb47, read-only)

| site | file:line (trunk) | caller | what runs at build |
|---|---|---|---|
| cerr | `aCTionCerR`, ruleActions.rtn:159 | aCTionBlocK's statement loop (ruleActions.rtn:32) | the print, after jitDegrade announces |
| cout | `aCTionCouT`, ruleActions.rtn:206 | aCTionBlocK | the print |
| FOR | `aCTionFOR`, ruleActions.rtn:489 | aCTionBlocK | the whole loop, body included |
| search | `aCTionSearch`, ruleActions.rtn:866 | aCTionBlocK | the search-stack edit |
| string expression | `aCTionStringXP`, ruleActions.rtn:947 | an operand: appendPrintXP, runOPaccumOperand | the build of the string |
| an operator with no emitter | `runOPdirect`, GroupActions.rtn:1272 (`op.operat`) | runOPslots, runAccAssign, runOPaccum | `:=` `:.` `=[` `+%` `<-` `!` `@` `$$` and every other operator whose function has no jitting gate |
| a unary with no emitter | `runOPdirect`, GroupActions.rtn:1273 (`op.method`) | runOPaccum's acU arm | `!` `@` `$$` |
| a command | `runOPdirect` -> `opCall`, GroupActions.rtn:1274 -> :582 (method arm) | runOPaccum's acC arm via runOPslots | `stop()`, `testing()`, `dumpContents()` -- any immediateAction but `jitTrace`, which emits |
| an IF whose condition has no value | `jitEmitGIF`, jitEmitters.rtn:1556 | aCTionIF's jitting arm | `jitIfRT` itself runs at RUN time; but the condition was evaluated at build to learn it has no value, and that evaluation runs the commands above (`dumpContents` in jitIfNoValueT) |
| `stop()` in a body | the command row | -- | ends the process inside the compile |
| `testing()` in a body | the command row | -- | a NESTED jitRunAction inside the build (cluster F, SEQ 383) |

jitDegrade's other callers (return / break with no value, print parts, an unseeded assign or unary, `x.a = y.b`, an
operator fire with no producer, `+=` on an unhandled kind, unary `*` refused, a bare read of a LIST, AND/OR operands)
announce and then emit a run-time substitute or drop the part. **None of them executes anything at build.**
`aCTionDEBUG` (ruleActions.rtn:216) has no jitting gate, but no jitted body reaches it.

**THE NUMBER (a tap in the clone, env-gated, reverted md5-identical).** Statements executed during jitBuildFunction:
**pop.sh 14, jitLadder 1, total 15.** The pop.sh 14 are: the 6 in the four born-red fixtures (sfBody cerr; ivBody's
dumpContents; spBody cerr + stop; ntOuter cerr + testing) and 8 already in the fleet -- `:=` 6 (jitBlockCallT,
jitBlockNameT, jitBlockCtlT's BJ: 5; jitScCountT's scDriver: 1, `scH := scId`), `:.` 2 (jitRefuseFlagT's rfBody, run
twice by pop.sh), and `=[` (jitBlockCtlT, in the same statement as one of the `:=`s). jitLadder's 1 is jitJPd's
cerr. (`jitTrace` in jitJ6 is a command that emits; it is not counted.) The tap counted a dispatch as an execution
when the function under construction gained no instruction and the result was not a folded constant. A second
pass with the cure's own door logging (below) reported the same population.
**Certificate target: 0.**

## The cure

- **A door, asked BEFORE dispatch** -- `jitOpEmits(op,target)`, called by runOPdirect under jitting. An operator or unary
  emits only if its function is on a list of the ones that carry a jitting gate; a call emits for a rule (the term call)
  or an action (inlined), and for a command only if it is `jitTrace`. Anything else is HANDED OVER. A new operator
  therefore defaults to running at run time, never at build.
- **The sinks** (cerr, cout, string expression, FOR, search) hand over instead of announcing and then running.
- **The IF with no value** hands over. Its condition was evaluated through the door, so nothing in it ran.
- **A hand-over** (`jitHandOver`) announces through jitDegrade, once per statement (later degrades in the same
  statement are folded into it), and marks the statement. At the statement's end, aCTionBlocK ROLLS BACK every
  instruction and block that statement emitted, and then emits one run-time call, `jitStmtRT`. The rollback is what
  stops an emitted half of a statement from running and then running again inside the interpreted whole.
- **The run-time call sees current values:** every frame slot is stored to its field before the call and reloaded
  after it, and the refusal exit is kept (the reload comes first, so the epilogue cannot write a stale slot over what
  the statement wrote). The two existing hand-overs (an unseeded assign, a statement refused at emit) take the same
  road. jitRunAction nulls gJitBuilder before it fires, so no run-time code sees a dangling builder.

## Pre-registered movers (written before the cure was built)

| row(s) | today | predicted |
|---|---|---|
| jitSinkFireT SFJ | `0` | `1 2` |
| jitIfNoValueT dumps per segment | `2 1 1 1` | `1 1 1 1` |
| jitStopT SPJ | `0 0` | `1 0` |
| jitNestTestT runs / sentinel / twin / jitted / no-nested-build (5 rows) | exit 139 | 0 / present / `1 10` / `1 10` / `1` |
| jitRefuseFlagT JRS-F (b c d, and a) and its stmtRT IR count | `1 7 6`, a `0`, stmtRT `1` | unmoved -- the `:.` statement already ran at run time; it now also skips its build-time try |
| jitBlockCallT / jitBlockNameT / jitBlockCtlT exit and pz rows | 0, 7, 7 | unmoved -- the `:=` and `=[` statements move to run time, and pz is set by a statement that emits |
| jitScCountT calls, jitted = interpreted | `2 1 1` | unmoved |
| jitLadder JPd "degrade FIRED" and the Buffer row | green | unmoved -- a hand-over still announces |
| every degrade-count row in pop.sh and jitLadder | as pinned | **unmoved by construction**: a hand-over announces through jitDegrade once per statement, exactly where the site announced before. Only a cascade inside an already handed-over statement is folded, and the census found no statement in the fleet with two |

Anything else that moves is a finding, and the stroke stops on it.

## Certificate (measured on the branch, clone, after the build)

- **The four born-red fixtures are green**, each against its interpreted twin. SFJ `1 2` = SFI. IV dumps `1 1 1 1`.
  SPJ `1 0` = SPI. NT `1 10` = the twin, and the line before the inner compile is the FIRE's `n 1`.
- **Statements executed during jitBuildFunction: 0** (pop.sh 0, jitLadder 0; it was 15). Same tap as the census, plus
  one refinement: a dispatch inside a statement that is already handed over is not counted, because it runs nothing.
- **pop.sh 1522 green. Movers against trunk bfffb47 are exactly the 8 born-red rows**, plus H3's fixture-name count.
  **jitLadder row for row.** Every other pre-registered row is unmoved, as predicted. printPop PASSED, decodePop =
  capture, ddPop 5 / 1, frontier = capture, and bare tokall = branch.
- **H7, one per site class**, each run on its fixture alone under an alarm, with the tap on:

  | restored | fixture | result | tap |
  |---|---|---|---|
  | the cerr sink, announcing and then running | jitSinkFireT | SFJ `[0]` | 1 |
  | the IF (old jitEmitIfRT road) with the door letting commands through | jitIfNoValueT | dumps `2 1 1 1` | 2 |
  | the same build, the command class | jitStopT / jitNestTestT | no SPJ line (stop ran at build) / exit 139 | 1 / 1 |

  All red. Restored from git, md5 = the cure, rebuilt.
- **refireSkipsDegraded is retired by mapping** to jitSinkFireT (`incant/attic/refireSkipsDegraded` carries the map).

## Forced-jit census, re-run (the SEQ 383 tap, re-applied in the clone and reverted md5-identical)

| per fixture | SEQ 383 old / new | SEQ 384 old / new |
|---|---|---|
| agree | 68 / 67 | 102 / 97 |
| DISAGREE | 98 / 110 | 83 / 95 |
| exit during the compile (stop() at build) | 8 / 6 | **0 / 0** |
| crash during the compile | 7 / 5 | **0 / 0** |
| crash after compiling | 3 / 2 | 2 / 1 |
| hang | 0 / 0 | 1 / 1 |

(The population grew by the five new fixtures.) By cluster:
- **The sink cluster (A) and the IF cluster (B) left.** A sink now announces as a hand-over and prints at run time.
  The degrade line `IF condition produced no value` fell from 627 to 24, because a condition that is a command now
  hands over at the door.
- **The stop cluster (E) left**: 0 exits inside a compile.
- **The nested-testing cluster (F-i) left**, and so did the emit-time null derefs (F-ii). That took two more door
  rules, both found by this re-run: a unary on an operand the build cannot see, and an emitter slot with a side the
  build cannot see.
- **Duplicate symbol (C) stays**, as predicted for SEQ 385: 114 compiles, 49 files on each road.
- **The parse generator (D) is reported, not chased.** parser / walkRules are verifier-refused in 38 files;
  generateParse compiles in 38; parserTest still crashes at run.

What the re-run found in the cure itself, every one fixed on the branch before this certificate:
- **The raw flush overwrote pointers.** kindJ1T's iterator, and kindHolderT's holder through opFire's flush. Flush and
  reload now go through a kind check.
- **Emitters were handed nulls by a door.** A handed-over statement now dispatches nothing more.
- **A scope statement had no jitting gate.** It now hands over.
- **The run-time call had no owner.** dirT's scope statement read a null currentMETHOD. jitStmtRT now takes the owner.

Remaining, NOT chased (the relevance gate holds -- no fleet row fails):
- **starIdiomT hangs.** `idF := copyOf(argument)` now runs at run time, but the iterate on `*idF` that follows
  reads its source at BUILD, so the jitted walk never ends. **This is the class this ruling exposes: an emitter that
  reads a run-time value at build was right only while the statement that sets it ran at build too.**
- **foldAndT** crashes at run. Its jitted `x.datA != 0` condition reads true where the interpreted road reads
  false, so the arm runs and its own `+% *kop` hands opAddAttribute a null.
- **33 more verifier refusals (rc -5), nearly all in testPrecedence**, which used to crash at compile and so was never
  measured. The verifier says `Instruction does not dominate all uses` on an unbox load reused across statements. The
  build refuses and the action runs interpreted.
- The rest of DISAGREE is cluster G (value disagreements), not one mechanism. Samples: actionLocalT's declared
  counter (1 for 3); argWriteT reads a group-carrying argument as a count (95848720 for 99); kindLiftT; and the
  generator's trace where parser() is jitted.

**A named limit, not met in general and not reached by any fleet row:** after a run-time call turns a frame local
into a non-scalar (`x := y` handed over), the slot cannot hold the new value. The kind check keeps the slot's old
value, and the frame EPILOGUE still stores raw, so at exit it writes that old value's bits over the field's pointer.
The call site cannot cure this; it needs a frame decision (evict the slot, or home locals off the union). Inside
runAction's save/restore bracket (the forced census) the restore covers it; `testing()` / `jitRefire` have no bracket.
(SEQ 385 R3: filed as Clod's fixit `incant/fixits/epilogueWriteBack`, with a kant repro -- `testing()` then
`dumpContents` exits 139, and the local's gGroup reads 0x0000000100000007 after `x = 7`: the low half is the slot.)

## SEQ 385 R2 -- the class starIdiomT exposes, pinned and censused (trunk f2eb312, 2026-10-19). No cure.

**The class: an emitter reads AT BUILD a value that a run-time setter writes, and decides its IR from it.** It was
right only while the setter also ran at build. `incant/pop/jit/jitStarIdiomT` pins the worked example under a 10 s
alarm: exit 142 (it hangs), intended 0 and 8 members (the interpreted twin). A sample of the hung run sits in the
compiled function's `jitOpFireRT`, so the hang is at RUN time; what goes wrong is decided at build.

`docs/jitDesign.md:20-27` (Premise 1) makes a field's kind fixed for the life of jitted code that observed it, so the
kind reads below follow a contract on purpose. What SEQ 384 adds is the case the contract did not foresee: a field that
is kindless, or holds no group, AT BUILD because its setter now runs only at run time.

The sites. The population was every `jitting` site in Instruct.rtn, ruleActions.rtn and GroupActions.rtn (about 50),
plus every emitter in jitEmitters.rtn they reach. Each gate judged out of class was named with a reason. Two rows were
re-read by hand (opDeref, jitSeedField).

| site | read at build | the IR decision | run-time setter |
|---|---|---|---|
| ruleActions.rtn:593-611 aCTionIterate (the worked example) | `opDeref(source)`, `isGROUP` / `isArgument`, `groupList` -- all before its gate at :612 | no source: poison and return, `jitEmitIterate` never emitted | `:=`, `<-`, a handed-over `copyOf` |
| Instruct.rtn:904 opPlusPlus, :634 opMinusMinus | `isIterator` (written by aCTionIterate's build-time body) | iterator step (`jitEmitIterStep[Back]`) or a plain inc / dec | aCTionIterate at run time |
| Instruct.rtn:253-259 opDeref | the gate emits and FALLS THROUGH to `result.isGROUP -> result.group` (:258), handing the build-time group up the walk | every consumer of `*x`: aCTionIterate's source, a dot's target | `:=`, `<-`, `=` of a holder |
| Instruct.rtn:308 opDot -> jitEmitDot (jitEmitters.rtn:1533), via runOPslots (GroupActions.rtn:1309) | for `(*x).y`, the build-time `*x` above; jitEmitDot bakes the target's address | which node opDot runs on at run time; `.` has no `jitEmitter=`, so the null-side hand-over (GroupActions.rtn:1274) does not catch it | `:=` / `<-` on x |
| GroupActions.rtn:328-333 followArgument (runOPslots :1305, runAccAssign :1040, runOPaccumOperand :1249) | when `jitArgSlotRead` returns null, the argument's build-time `getGroup()` | which node is seeded or baked for an `argument` operand | the caller's run-time bind (jitBindArgRT) |
| jitEmitters.rtn:1271-1288 jitEmitBareRead | the same argument follow, then `groupList` | which node is loaded; a list degrades instead | the run-time bind; `+=` / `+%` giving a field a list |
| jitEmitters.rtn:3931, 3942 jitSeedField | `isNUMBER(flags.data)` | home gNumber or gCount, load double or i32 -- every operand passes here | `=` on a kindless field, `:=`, `<-` |
| jitEmitters.rtn:359 the frame prologue | each local's `isNUMBER(data)` | alloca double or i32, and its home | the first `=` at run time |
| jitEmitters.rtn:374-376 the argument slot | the build-time argument's isGROUP, groupList, kind | whether an i32 argSlot exists at all | the caller's argument |
| jitEmitters.rtn:926, 932 jitEmitAssign (also from opDivEQ / opMinusEQ / opMultiplyEQ) | the target's `flags.data` | cast helper or a typed store; double or i32 | an earlier `=` now run at run time |
| Instruct.rtn:752 opPlus; jitEmitters.rtn:800 jitEmitAdd | `target.isSTRING \|\| isTOKEN` | a concat call or an integer add | `=` of a string to a kindless field |
| jitEmitters.rtn:2178-2182 jitEmitSelfCall | the argument's groupList and kind | box an i32, or pass the node | `=` / `:=` on the argument field |
| jitEmitters.rtn:3139 jitPrintList | a part's isSTRING / isTOKEN | a baked node through appendGroup, or an i32 load | `=` of text into the part |

Downstream only (no read of their own; they inherit the seeded type): jitEmitBinary, jitEmitCompare, jitEmitUnary,
jitStoreResult. **Unsure, not decided:** GroupActions.rtn:98 (`hasNewParse` chooses the term-call emit, and a run-time
`parser()` can set it); GroupActions.rtn:1314 / :1045 (`isVirtual` -> a build-time `copyOf`, baked); jitEmitRem and
jitEmitDot call through FIELD storage and flush no frame slot first (a different defect, not traced).
