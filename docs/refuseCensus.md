# The refusal census — scope for REFUSAL IS TERMINAL FOR THE ACTION

Tony's ruling, 2026-09-05, on `incant/f31`'s 2,808,029 lines. Step 0 of that
stroke is this list, and the ruling says editing does not start before it exists.

**Measured 2026-09-05** over the eight chain `.rtn` — `Commands`, `GroupActions`,
`ruleActions`, `Debug`, `Instruct`, `jitEmitters`, `genParse`, `Generate` — which are
one translation unit. **114 sites.**

## ⚠ The control clause, named before the count is believed (rule H11)

The ruling named five families by hand. A census that missed any of them would be a
census of the wrong population, so they are checked by name rather than assumed:

| family the ruling named | found at |
|---|---|
| the seven operators (F-41) | `Instruct.rtn` — 24 operator sites, the seven among them |
| `aCTionIterate`'s holder/pointer refusals | `ruleActions.rtn:591, :615, :649` |
| `:=` / `<-` on `argument` | `GroupActions.rtn:854` |
| `setParse`'s no-rStuff | `Generate.rtn:340` |
| `compile`'s REFUSING | `Commands.rtn:106, :162, :217` |

**All five present.** The count stands.

## ⚠ What the census actually found, and it is not what the ruling's wording implies

**Not one of the 114 sites "prints ERROR and continues" in its own body.** Fifty-five
`return null` immediately; another eight return `0`; most of the rest return a
sentinel of some kind. **They are already terminal for the FUNCTION.**

**The continuation happens one level up, and that is the whole defect.** A helper that
returns null leaves the statement's value null, and `aCTionBlocK` runs the next
statement. There is no unwind channel at all — nothing a refusing site could set even
if it wanted to. **So step 1 is not "make these sites return"; it is "give them
somewhere to say so, and give the block somewhere to look."**

⚠ That distinction changes the size of the stroke. Editing 114 return statements would
be a large mechanical change that fixes nothing. Adding one arm and one check, and
routing 114 sites through a `refuse()` that sets it, is a different and smaller shape.

## By enclosing kind

| kind | sites | note |
|---|---|---|
| HELPER | 75 | reached from actions through `runOP`; the bulk |
| OPERATOR | 24 | F-41's seven plus the rest of `Instruct.rtn` |
| JIT | 8 | emit-time; see the JIT question below |
| ACTION | 7 | the only ones that ARE an activation already |

## By what the site returns today

| returns | sites |
|---|---|
| `return null` | 55 |
| `(falls through)` | 32 |
| `return 0` | 8 |
| `return group` | 7 |
| `return result` | 4 |
| `return item` | 2 |
| `return target` | 2 |
| `return input` | 1 |
| `return trueResult` | 1 |
| `return false` | 1 |
| `return tempField` | 1 |

## ⚠ The JIT question, reported rather than decided

The dispatch asks which was built and what it cost in IR. **Neither is built**, because
step 0 is the whole of this commit. The question is real and here is what is measured:

An inlined callee's block is emitted **flat** — `incant/argJitT`'s IR is one function
with the callee's statements inline and no `call` at all. So an unwind arm has two
possible shapes on that road:

- **a check emitted per statement** — a load and a conditional branch after every
  statement of every inlined body, which is a real IR cost on every jitted action
  whether or not it can refuse; or
- **the inline becomes an emitted call when the body contains a refusable site** —
  cheap in the common case, but it makes inlining depend on a whole-body property
  that nothing currently computes, and `jitEmitSelfCall` is the only existing
  precedent for refusing to inline.

**A third outcome should be enumerated before either is built** — that the emitted road
cannot do it yet and must degrade LOUDLY to the oracle, which the ruling explicitly
allows. Rule H4's degrade counter is asserted at zero by every rung, so a degrade here
is a red and a silent substitution is not.

## The sites
```
ACTION    ruleActions.rtn    :272   aCTionDefinE             (falls through)
ACTION    ruleActions.rtn    :332   aCTionDefinE             (falls through)
ACTION    ruleActions.rtn    :547   aCTionIF                 (falls through)
ACTION    ruleActions.rtn    :591   aCTionIterate            (falls through)
ACTION    ruleActions.rtn    :615   aCTionIterate            (falls through)
ACTION    ruleActions.rtn    :649   aCTionIterate            return 0
ACTION    ruleActions.rtn    :893   aCTionRunRulE            return input
HELPER    Commands.rtn       :106   compile                  return null
HELPER    Commands.rtn       :162   compile                  return null
HELPER    Commands.rtn       :217   compile                  return null
HELPER    Commands.rtn       :264   debugOnGuard             return trueResult
HELPER    Commands.rtn       :323   fireNewParse             return 0
HELPER    Commands.rtn       :365   generateCode             (falls through)
HELPER    Commands.rtn       :368   generateCode             (falls through)
HELPER    Commands.rtn       :437   getType                  (falls through)
HELPER    Commands.rtn       :493   guard                    (falls through)
HELPER    Commands.rtn       :572   loadDirectory            (falls through)
HELPER    Commands.rtn       :818   setInternalType          return null
HELPER    Commands.rtn       :819   setInternalType          return null
HELPER    Generate.rtn       :340   setParse                 return null
HELPER    GroupActions.rtn   :71    assignFieldCore          (falls through)
HELPER    GroupActions.rtn   :76    assignFieldCore          (falls through)
HELPER    GroupActions.rtn   :116   dispatcher               (falls through)
HELPER    GroupActions.rtn   :131   fAIL                     (falls through)
HELPER    GroupActions.rtn   :212   interpretMethod          return group
HELPER    GroupActions.rtn   :353   makeDataType             (falls through)
HELPER    GroupActions.rtn   :362   makeDataType             (falls through)
HELPER    GroupActions.rtn   :582   processCode              return false
HELPER    GroupActions.rtn   :774   ruleMethod               return group
HELPER    GroupActions.rtn   :775   ruleMethod               return group
HELPER    GroupActions.rtn   :854   runOP                    (falls through)
HELPER    GroupActions.rtn   :1009  runRule                  (falls through)
HELPER    GroupActions.rtn   :1257  setRuleAction            return item
HELPER    GroupActions.rtn   :1258  setRuleAction            return item
HELPER    Instruct.rtn       :46    getMarkLineAt            return result
HELPER    Instruct.rtn       :47    getMarkLineAt            return result
HELPER    Instruct.rtn       :1429  setMark                  return null
HELPER    Instruct.rtn       :1430  setMark                  return null
HELPER    genParse.rtn       :20    activateAll              (falls through)
HELPER    genParse.rtn       :40    activateBody             return null
HELPER    genParse.rtn       :44    activateBody             return null
HELPER    genParse.rtn       :48    activateBody             return null
HELPER    genParse.rtn       :143   actK                     (falls through)
HELPER    genParse.rtn       :164   compileStored            return null
HELPER    genParse.rtn       :168   compileStored            return null
HELPER    genParse.rtn       :172   compileStored            return null
HELPER    genParse.rtn       :466   emitLeaf                 return null
HELPER    genParse.rtn       :504   emitMany                 return 0
HELPER    genParse.rtn       :550   emitPlan                 return null
HELPER    genParse.rtn       :583   emitPlan                 return null
HELPER    genParse.rtn       :590   emitPlan                 return null
HELPER    genParse.rtn       :594   emitPlan                 return null
HELPER    genParse.rtn       :691   genKant                  return null
HELPER    genParse.rtn       :712   genKant                  return null
HELPER    genParse.rtn       :718   genKant                  return null
HELPER    genParse.rtn       :724   genKant                  return null
HELPER    genParse.rtn       :920   kantDoor                 return 0
HELPER    genParse.rtn       :942   kantDoor                 (falls through)
HELPER    genParse.rtn       :1100  kantLeaf                 return null
HELPER    genParse.rtn       :1104  kantLeaf                 return null
HELPER    genParse.rtn       :1658  parseRuleMethod          (falls through)
HELPER    genParse.rtn       :1690  parseRuleMethod          return group
HELPER    genParse.rtn       :1844  parseTermCount           return group
HELPER    genParse.rtn       :1996  planRule                 return null
HELPER    genParse.rtn       :2031  planRule                 return null
HELPER    genParse.rtn       :2034  planRule                 (falls through)
HELPER    genParse.rtn       :2062  planRule                 return null
HELPER    genParse.rtn       :2107  planRule                 return null
HELPER    genParse.rtn       :2230  planTerm                 return null
HELPER    genParse.rtn       :2233  planTerm                 return null
HELPER    genParse.rtn       :2240  planTerm                 return null
HELPER    genParse.rtn       :2243  planTerm                 return null
HELPER    genParse.rtn       :2246  planTerm                 return null
HELPER    genParse.rtn       :2249  planTerm                 return null
HELPER    genParse.rtn       :2316  planTerm                 (falls through)
HELPER    genParse.rtn       :2332  planTerm                 return null
HELPER    genParse.rtn       :2341  planTerm                 return null
HELPER    genParse.rtn       :2397  planTerm                 return null
HELPER    genParse.rtn       :2408  planTerm                 return null
HELPER    genParse.rtn       :2420  planTerm                 return null
HELPER    genParse.rtn       :2636  setParseMethod           return 0
HELPER    genParse.rtn       :2763  storeBody                return null
JIT       jitEmitters.rtn    :502   jitDerefRT               return 0
JIT       jitEmitters.rtn    :506   jitDerefRT               return 0
JIT       jitEmitters.rtn    :904   jitEmitContinue          (falls through)
JIT       jitEmitters.rtn    :1560  jitEmitReturn            (falls through)
JIT       jitEmitters.rtn    :1573  jitEmitReturn            (falls through)
JIT       jitEmitters.rtn    :1892  jitEmitter               return group
JIT       jitEmitters.rtn    :1894  jitEmitter               return group
JIT       jitEmitters.rtn    :2710  jitPrintNodeRT           return 0
OPERATOR  Instruct.rtn       :190   opAddPointer             return target
OPERATOR  Instruct.rtn       :281   opDiv                    return null
OPERATOR  Instruct.rtn       :307   opDivEQ                  (falls through)
OPERATOR  Instruct.rtn       :427   opEQ                     return null
OPERATOR  Instruct.rtn       :450   opGE                     return null
OPERATOR  Instruct.rtn       :509   opGT                     return null
OPERATOR  Instruct.rtn       :573   opLE                     return null
OPERATOR  Instruct.rtn       :596   opLT                     return null
OPERATOR  Instruct.rtn       :629   opMinus                  return null
OPERATOR  Instruct.rtn       :645   opMinus                  return null
OPERATOR  Instruct.rtn       :688   opMinusEQ                (falls through)
OPERATOR  Instruct.rtn       :745   opMinusMinus             return result
OPERATOR  Instruct.rtn       :778   opMultiply               return null
OPERATOR  Instruct.rtn       :784   opMultiply               return null
OPERATOR  Instruct.rtn       :806   opMultiplyEQ             (falls through)
OPERATOR  Instruct.rtn       :879   opPlus                   return null
OPERATOR  Instruct.rtn       :894   opPlus                   (falls through)
OPERATOR  Instruct.rtn       :896   opPlus                   return null
OPERATOR  Instruct.rtn       :995   opPlusEQ                 (falls through)
OPERATOR  Instruct.rtn       :1078  opPlusPlus               return result
OPERATOR  Instruct.rtn       :1146  opRem                    return tempField
OPERATOR  Instruct.rtn       :1276  opSetFlag                return target
OPERATOR  Instruct.rtn       :1344  opDeref                  return null
OPERATOR  Instruct.rtn       :1377  opUnaryMinus             return null
```

## Excluded, by reading rather than by pattern (rule H9)

Ten functions print a matching word and are **reports, not refusals** — tallies, dumps
and the `report*` family that exists to explain a refusal raised elsewhere:
`dumpPlanTally` `dumpRuleTerms` `reportCodeFail` `reportMaxLimit` `reportNoBody`
`reportRepeatLimit` `limitWriteCheck` `debugRuleNamed` `jitRunAction` `genParse`.

⚠ **They are named rather than silently filtered.** A census that drops rows without
saying which is a census nobody can check, and the classification — not the grep — is
the finding.


## ⚠ THE ARM-LEAK QUESTION, ANSWERED 2026-09-05 — AND IT GATES PART OF B

**Asked:** on the emitted road, a top-level function, a helper refuses mid-body —
the arm is set, and `runAction`'s clear is EMIT-time. What clears it at the
function boundary? If nothing does, the arm leaks and the next inlined check
anywhere fires on someone else's refusal.

**Probed** (`probeArmLeak`: refuse in one activation, then call an action with an
inlined callee): both roads read **99** — the inline ran, no leak.

⚠ **BUT THE PROBE PASSES FOR A REASON THAT B REMOVES, so read it as a dated fact
and not as an all-clear.** Nothing sets the arm at RUN time on the emitted road
today, because **no run-time emitted-road helper calls `refuse()`**. Measured,
all six: `jitBindArgRT`, `jitDerefRT`, `jitPrintNodeRT`, `jitAssignNodeRT`,
`jitSaveFrameRT`, `jitRestoreFrameRT` — zero `refuse(` calls between them. The
arm can only be set during the emit walk, where `runAction` clears it at the
activation boundary exactly as on the interpreted road.

⚠⚠ **THREE OF THE UNROUTED SITES ARE CALLED FROM EMITTED CODE AT RUN TIME, AND
ROUTING THEM IS WHAT CREATES THE LEAK:**

| site | called at |
|---|---|
| `jitEmitters.rtn:502` `jitDerefRT` — null operand | RUN time, from emitted code |
| `jitEmitters.rtn:506` `jitDerefRT` — holds no group | RUN time, from emitted code |
| `jitEmitters.rtn:2751` `jitPrintNodeRT` — item produced no node | RUN time, from emitted code |

**So B must not route those three until an emitted function's epilogue clears the
arm** — or B introduces the defect this question was asked to prevent. The other
JIT sites (`jitEmitContinue`, `jitEmitReturn`) are emit-time and are safe.

**THE FIX SHAPE, reported and NOT built:** the emitted function's epilogue clears
the arm, mirroring what `runAction` does for an interpreted activation — the
emitted function *is* the activation. It is about four lines of emission.
⚠ **It is NOT a one-liner in consequence, which is why it was not just done.** It
adds a store to EVERY emitted function's epilogue, and A3 has just demonstrated
how sensitive the JIT ladder's block-topology assertions are to IR shape. It
wants its own stroke with the ladder read before and after.


## ⚠⚠ B IS NOT "ROUTE THE REMAINING 92" — THE CLASSIFICATION IS B's REAL WORK

Measured 2026-09-05, before any of B's routing. **The 92 split four ways, and
only one of the four may be routed at all.**

| bucket | sites | may B route it? |
|---|---|---|
| **INTERNAL-planner** | **44** | ⚠ **NO, AND ROUTING THEM IS CATASTROPHIC** |
| GATED-runtime-emitted | 3 | not until the epilogue clears the arm |
| JIT-emit-time | 5 | safe but low value; held |
| candidate-TERMINAL | 40 | yes, site by site |

⚠⚠ **THE PLANNER BUCKET IS THE FINDING, AND IT IS THE spacingT LESSON AT SCALE.**
`planRule`, `planTerm`, `emitPlan`, `genKant` and their family refuse as a
NORMAL ANSWER their caller handles — `genParse`'s odometer is pinned at
**46 refusals of 64 rules, RED BY DESIGN**, all raised inside ONE walk. Routing
them through `refuse()` would arm on the first unplannable rule and terminate
the walking action, destroying the odometer entirely. A helper returning null
to a caller that expects it is NOT a refusal in the ruling's sense; the ruling
is about a user-facing "this cannot be done, stop".

**So the honest count for B is 40, not 92** — and each of the 40 needs its own
look, because the bucket boundary is a judgement about who handles the null.

## Item 3's table — the Instruct sites, and the sentinel-as-data set

| site | function | returns | class |
|---|---|---|---|
| :1415 | `setMark` | `null` | REFUSAL — **routed** |
| :1416 | `setMark` | `null` | REFUSAL — routable |
| :306 :680 :796 :983 | `opDivEQ` `opMinusEQ` `opMultiplyEQ` `opPlusEQ` | falls through | REFUSAL — compound assign cannot apply |
| :190 | `opAddPointer` | **`return target`** | ⚠ SENTINEL-AS-DATA |
| :1134 | `opRem` | **`return tempField`** | ⚠ SENTINEL-AS-DATA |
| :46 :47 | `getMarkLineAt` | **`return result`** | ⚠ SENTINEL-AS-DATA |
| :737 :1066 | `opMinusMinus` `opPlusPlus` | **`return result`** | ⚠ SENTINEL-AS-DATA |
| :1264 | `opSetFlag` | `return target` | **WARNING** — its own text says *guessing*; rename, do not route |
| :883 | `opPlus` | falls through | **WARNING** — string advanced past length; not a refusal |

⚠ **THE SENTINEL-AS-DATA SET IS REPORTED BEFORE PROMOTION, AS ASKED, AND IT IS
SEVEN SITES.** Each announces a failure and then hands the caller a VALUE that
looks like a successful answer — `target`, `tempField`, `result`. Promoting them
to terminal refusals changes what every caller sees from *a value* to *null plus
an armed unwind*. That is the right direction and it is a BEHAVIOUR change per
site, not a routing edit, so none of the seven is promoted here.
⚠ **And two of the fourteen are WARNINGS, not refusals** — `opSetFlag` says in
its own message that it is *guessing*, and `opPlus`'s is a string-length notice.
Routing either would turn a diagnostic into a stop.
