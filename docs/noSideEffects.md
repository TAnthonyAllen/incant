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
