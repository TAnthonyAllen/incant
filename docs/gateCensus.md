# The Gate Census — which methods emit, which execute at emit time

**Written 2026-08-04** as the rider on Clay's degrade-by-default proposal. The proposal:
flip the polarity at the dispatch spine so that under jitting an action **without** an emitter
degrades loudly (counted) instead of executing silently — gates become a whitelist. One change,
and every latent case converts from silent-wrong to counted-visible.

**The caution that kept it a proposal:** some of the effectful column may be the **emit walk's
own machinery**, and degrading those breaks emission itself. This pass decides which.

---

## ⚠ CORRECTION TO THE FIRST COUNT, recorded because the number was reported before it was right

The first pass reported **262 methods, 38 gated, 224 ungated**. Those numbers are **wrong**.
They came from a `sed` extraction that matched prototypes and text inside comments as if they
were definitions, and a gate-detector that only looked 40 lines past each `extern` — so a gate
deeper in a long body read as absent.

Re-derived by splitting each `.rtn` on column-0 `extern` and searching **whole function bodies**:

| | count |
|---|---|
| `aCTion*` / `op*` definitions | **78** |
| gated (`if jitting` anywhere in the body) | **26** |
| ungated | **52** |

The correction matters beyond arithmetic: under the 40-line detector `aCTionTraiTdata` read as
gated and is not, and the ungated list was inflated with names that do not exist as definitions.
**A census is an instrument; this one lied on its first run.**

---

## THE ANSWER: the ungated column is NOT one population

Of the 27 ungated `aCTion*` methods, the large majority are **walk machinery** — they run
*during* emission and are how the IR gets built. Degrading them does not make a latent bug
visible; it stops the compiler.

### A. WALK MACHINERY — ungated BY DESIGN. Name them so, do not degrade them.

**The decisive case, and it is checkable rather than argued: `aCTionExpressioN`.** Its own
header calls it a *"thin dispatcher over two mode-handlers"*, and under jitting it **falls
through to `interpretXP`** — the emission happens one level BELOW it, in `runOP`'s seed gate
(`GroupActions.rtn:729`, `if jitting && (op.isOperator || op.isUnary)`) and in each op-method's
own `if jitting`. So `aCTionExpressioN` is not an un-jitted action; **it is the walk**. That is
exactly the failure mode Clay's caution predicted, confirmed by pointer.

| method | why it is machinery |
|---|---|
| `aCTionExpressioN` | dispatcher; emission happens below it in runOP + op gates |
| `aCTionStatemenT` | the statement walker itself |
| `aCTionXpress`, `aCTionScopeXP`, `aCTionParens`, `aCTionBraced`, `aCTionTokenXP` | expression-tree plumbing that feeds runOP |
| `aCTionNamE` | **builds the frame** — `jitRunAction`'s prologue comment records that a local is *born by being parsed* here |
| `aCTionNumbeR`, `aCTionANYtoken`, `aCTionQuotE`, `aCTionShortcuT`, `aCTionSetBrackets` | leaf/token construction |
| `aCTionDefinE`, `aCTionNewGroup`, `aCTionTraiT`, `aCTionTraiTdata`, `aCTionCodE` | definition-time; they run at parse, not at body execution |
| `aCTionRunRulE`, `aCTionFailed` | parse machinery |
| `aCTionCheckFor`, `aCTionDEBUG` | debug tooling, parse-time by construction |

### B. BODY-REACHABLE CONTENT — degrade by default. This is the real population.

| method | the disease |
|---|---|
| **`aCTionFOR`** | ⚠ **first against the wall.** It is `iterate`'s disease with a different keyword: a loop whose setup runs at emit time. `aCTionIterate` has just been fixed the same way and the fix is a template. |
| `aCTionCouT` | a sink. Same family as `print`, which fired at compile time until today. |
| `aCTionCerR` | ditto — and it is the one genParse's emitters write their product through, so it is not hypothetical. |
| `aCTionSearch` | mutates the search stack; at emit time that mutation lands once, in the wrong era. |
| `aCTionStringXP` | ⚠ **borderline, wants a look before it is degraded.** It produces a VALUE like an expression (machinery-ish) but reaches `appendPrintXP` and `opString` (content-ish). Classify it properly rather than by its neighbours. |

**So the degrade-by-default flip is worth doing, and its blast radius is five methods, not
fifty-two.** That is a much smaller and much more tractable change than the raw census
suggested — and the reason the raw census suggested otherwise is that it counted the compiler
as if it were the program.

---

## THE MECHANISM, and why the whitelist should be explicit

Clay's shape — gates become a whitelist — is right, but the whitelist should be **written down
as a list of names**, not inferred from the presence of `if jitting`. Two reasons:

1. **Presence of a gate is not evidence of coverage.** `aCTionBrancH` is now "gated", but its
   break and return arms only call `jitDegrade` — the gate is a *refusal*, not an emitter.
   A whitelist derived by grepping for gates would count it as covered.
2. **Absence of a gate is not evidence of a bug**, per section A above. A method that is
   machinery needs to say so in one line, at the site, so the next census does not re-litigate
   it and the next flip does not break emission.

**Recommended shape:** machinery methods carry a one-line marker naming them as walk machinery;
everything else degrades by default. The marker is what makes the census cheap to re-run and
impossible to get wrong twice.

---

# THE RUN-TIME-FLAG CENSUS — 2026-08-05

**The question, Clay's:** after `aCTionBlocK`'s `isBranch` break turned out to be a run-time flag
steering the emit walk, are there others? *"The signature is the same shape as
`if isMethod … else <no call>` was for the bare-read family: a walk decision keyed on a flag that
only means something during execution."*

**It is the effect-free-emit law's MIRROR IMAGE.** That law stops the walk causing run-time
effects. This class is a run-time flag steering the walk — the same boundary violated from the
other side, and worth naming as such because a reader who has internalised one will not
automatically look for the other.

## The sweep

Every flag-guarded `return` / `break` / `continue` inside the emit-reachable walk — the
jitting-gated actions plus `jitEmitters.rtn`:

| site | flag | verdict |
|---|---|---|
| `aCTionBlocK` `if result.isBranch … break` | `isBranch` | **MEMBER 5** — fixed 2026-08-05, `if jitting continue;` |
| `opPlusPlus` `if result.fLAG return 0;` | `fLAG` (iterator poison) | ⚠ **MEMBER 6 — FOUND BY THIS CENSUS.** See below. |
| `aCTionWhilE` / `aCTionDO` `if isContinue / or isReturn` | branch signal | **SAFE** — both sit BELOW their jitting gate, which returns first. Not emit-reachable. |
| `aCTionFOR` same pair, plus `if restrict && …  continue` | branch signal | **NAMED, not fixed.** Emit-reachable ONLY through the degrade fall-through, which is by design and now COUNTED. It is the known price of degrade-with-fall-through, not a hole. |
| `aCTionPrinT` `if noPrint continue;` | `noPrint` on a PrintXP item | **SAFE and correct.** A static property of the parse node — whether that item prints at all — not execution state. Mirrors `appendPrintXP` exactly. |
| `aCTionExpressioN` `if generating return generateXP(…)` | `generating` | **SAFE.** A MODE flag, and `jitRunAction` sets it to 0 deliberately. |
| `aCTionStatemenT` `if method return method(statement);` | `method` | **SAFE.** Dispatch, not a stop. |
| `jitEmitters.rtn:63` `if !jitting return 0;` | `jitting` | **SAFE.** Mode guard. |

## ⚠ MEMBER 6, and it was in code written the same morning

`opPlusPlus` opened with `if result.fLAG return 0;` — **above** the jitting gate. `fLAG` means
*"the LAST iterate on this node was refused"*, which is a fact about **execution**. Read at
**emit** time, a poisoned node would produce a compiled loop containing **no advance instruction
at all** — silent, permanent, baked into the function for every later fire.

**It did not bite, and the reason is precisely the danger:** `aCTionIterate` clears `fLAG` on its
success path, and that happened to run first. **Correct by accident of ordering** — the same
shape as `continue` appearing to work because its fall-through target happened to be the back
edge. Moved below the gate, so the poison is now evaluated at RUN time inside the emitted call to
`opPlusPlus` itself, which re-enters with `jitting` down and reaches the line properly.

## THE CLASS IS NOT DECLARED EMPTY — it is declared SWEPT, with its scope named

Eight sites examined, two members, one fixed today and one already fixed, four safe with reasons,
one named-and-deliberate. **The scope of this absence claim:** flag-guarded early exits in the
jitting-gated actions and `jitEmitters.rtn`. It does NOT cover the op-methods' own gates, nor
anything reached through the degrade fall-through, where run-time control flow runs at emit time
**by design** and is counted rather than prevented. A seventh member would most likely live
there, and the counter is what would surface it.

---
---

# B0 — THE GATE CENSUS FOR JIT/INTERPRETER SEPARATION (step 1 of N)

**asOf 2026-08-16.** Provenance: **grep + read**. Measurement only — no source changed.
Brief: Clay → Clod, "JIT/interpreter separation, step 1 of N: THE GATE CENSUS."

**Stability:** the census was run against the **working tree** and re-run against **HEAD
(`9c4962b`)**; the gate/emit site lists are **IDENTICAL** (53 gate hits, 68 emit hits, both
trees). The tree is dirty in `Instruct.rtn` (+2), `ruleActions.rtn` (18/18), `GroupActions.rtn`
(-1), but **no dirty hunk touches a `jitting` / `jitEmit` / `jitDegrade` / `fLAG` line**, so the
table below is valid against either tree. Stated because H8 forbids stacking on an unreconciled
tree, and because a census is an instrument (H9).

## THE TWO GREPS, AND THE FULL ACCOUNTING

| grep | form | repo-wide hits | in-scope source hits |
|---|---|---|---|
| **A** | literal `if jitting` | **142** | **53** |
| **B** | `jitEmit<Name>(` — call or definition | **215** | **68** |

**Grep A accounting (142 = 53 + 89 excluded):**

| bucket | n | where |
|---|---|---|
| **IN-SCOPE SOURCE** | **53** | `Instruct.rtn` 32 · `ruleActions.rtn` 13 · `GroupActions.rtn` 5 · `jitEmitters.rtn` 3 |
| excl: archaeology (gitignored) | 50 | `Aside/` ×3 files |
| excl: prose | 23 | `docs/` ×9 files, `CLAUDE.md` |
| excl: fixture prose | 10 | `incant/` ×8 files — **all verified comment text, zero live gates** |
| excl: harness | 4 | `jitLadder/ladder.sh` |
| excl: generated | 2 | `GroupRules.mm` |

**Grep B accounting (215 = 68 + 147 excluded):**

| bucket | n | where |
|---|---|---|
| **IN-SCOPE SOURCE** | **68** | `jitEmitters.rtn` 30 · `Instruct.rtn` 28 · `ruleActions.rtn` 8 · `GroupActions.rtn` 2 |
| excl: generated | 87 | `GroupRules.mm` 68 · `GroupRules.h` 19 |
| excl: archaeology | 38 | `Aside/` ×3 files |
| excl: prose | 11 | `docs/` ×4 files |
| excl: fixture prose | 9 | `incant/generate` 7 · `jitXcall` 1 · `jitJUi` 1 |
| excl: harness | 2 | `jitLadder/ladder.sh` |

**EXCLUDED-WIP, per the brief's scope boundary** — `Generate.rtn` and
`IncantForms/WorkingOn/parser`. Checked and logged rather than read:
**both contain ZERO hits on either grep.** They contribute nothing to the census, so the
exclusion costs no coverage. (`IncantForms/WorkingOn/incant++` carries one prose mention of
"jitting" — Tony's own note asking for exactly this separation work. Filed, not read further.)

## THE CLASSIFICATION RULE (stated, because the brief's four buckets are not disjoint as written)

`SHIM` is a claim about the **gate body**; `SHARED` is a claim about **what runs before the
gate**. Those are orthogonal axes, and several hits satisfy both (`opDot` has a one-line shim
body *and* an executed prologue the emit call consumes). Applied precedence, so every hit lands
in exactly one bucket:

**CROSSER > SHARED > SHIM > PARSE-ADJACENT.**

- **SHIM** — the gate hands off and returns; nothing interpreted runs before it, and nothing the
  emit path consumes is computed before it. *Mechanically liftable to a slot install.*
- **SHARED** — executable code runs before the gate AND either the emit path consumes it, or the
  gate does not return so interpretation continues underneath it. *The separation has to cut here.*
- **CROSSER** — as the brief defines it.
- **PARSE-ADJACENT** — lives in or serves parser code.

## THE TABLE — 51 live gates (53 hits − 2 comment-text mentions)

### SHIM — 21

| file:line | function | class | body | notes |
|---|---|---|---|---|
| `Instruct.rtn:99` | `opAssign` | SHIM | 1 | `return jitEmitAssign(argument,target)` |
| `Instruct.rtn:198` | `opDiv` | SHIM | 1 | `jitEmitBinary(…,jitSDiv)` |
| `Instruct.rtn:365` | `opEQ` | SHIM | 1 | `jitEmitCompare(…,jitEQ)` |
| `Instruct.rtn:384` | `opGE` | SHIM | 1 | `jitEmitCompare(…,jitGE)` |
| `Instruct.rtn:439` | `opGT` | SHIM | 1 | `jitEmitCompare(…,jitGT)` |
| `Instruct.rtn:499` | `opLE` | SHIM | 1 | `jitEmitCompare(…,jitLE)` |
| `Instruct.rtn:518` | `opLT` | SHIM | 1 | `jitEmitCompare(…,jitLT)` |
| `Instruct.rtn:547` | `opMinus` | SHIM | 1 | `jitEmitBinary(…,jitSub)` |
| `Instruct.rtn:661` | `opMultiply` | SHIM | 1 | `jitEmitBinary(…,jitMul)` |
| `Instruct.rtn:721` | `opNotEQ` | SHIM | 1 | `jitEmitCompare(…,jitNE)` |
| `Instruct.rtn:750` | `opPlus` | SHIM | 1 | `jitEmitBinary(…,jitAdd)` |
| `Instruct.rtn:1130` | `opUnaryMinus` | SHIM | 1 | `jitEmitUnary(…,jitNeg)` |
| `ruleActions.rtn:535` | `aCTionDO` | SHIM | 1 | `return jitEmitDO(input)`; preceding `StatemenT:`/`ExpressioN:` are declarations |
| `ruleActions.rtn:705` | `aCTionIF` | SHIM | 1 | `return jitEmitGIF(input)`; the preceding `result = ExpressioN` is inert for the emit path |
| `ruleActions.rtn:1396` | `aCTionWhilE` | SHIM | 1 | `return jitEmitWHILE(input)` |
| `GroupActions.rtn:1081` | `runShortCircuit` | SHIM | 1 | `return jitEmitShortCircuit(field)`; its own comment names this "THE PHASE GATE … everything BELOW this line is run time" |
| `Instruct.rtn:229` | `opDivEQ` | SHIM *(compound)* | 2 | `jitEmitBinary` **then** `return jitEmitAssign` |
| `Instruct.rtn:576` | `opMinusEQ` | SHIM *(compound)* | 2 | same shape |
| `Instruct.rtn:688` | `opMultiplyEQ` | SHIM *(compound)* | 2 | same shape |
| `jitEmitters.rtn:30` | `displayFill` | SHIM *(dual-arm)* | 2 | `if jitting {jitEmitFill}` **else** `displayFillRT` — emit/runtime twins, no shared work |
| `jitEmitters.rtn:3068` | `jitTrace` | SHIM *(dual-arm)* | 2 | `jitEmitTrace` / `jitTraceRT` — same shape |

### SHARED — 29

| file:line | function | class | body | notes |
|---|---|---|---|---|
| `Instruct.rtn:289` | `opDot` | SHARED | 1 | `ruler = groupRules` runs first and the emit call **consumes** it (`ruler->tempField`) |
| `Instruct.rtn:636` | `opMinusMinus` | SHARED | 1 | whole `if isIterator {…return}` arm runs **at emit time** above the gate |
| `Instruct.rtn:825` | `opPlusEQ` | SHARED | 1 | degrade-only; `use target` + list dispatch above |
| `Instruct.rtn:832` | `opPlusEQ` | SHARED | 1 | degrade-only |
| `Instruct.rtn:835` | `opPlusEQ` | SHARED | 1 | degrade-only |
| `Instruct.rtn:841` | `opPlusEQ` | SHARED | 2 | `case isCOUNT:` leaf, binary+assign |
| `Instruct.rtn:848` | `opPlusEQ` | SHARED | 2 | `case isNUMBER:` leaf |
| `Instruct.rtn:855` | `opPlusEQ` | SHARED | 1 | `return jitEmitStringPlusEQ` — one-line body, but nested in the type switch |
| `Instruct.rtn:858` | `opPlusEQ` | SHARED | 1 | degrade-only (Buffer target) |
| `Instruct.rtn:863` | `opPlusEQ` | SHARED | 1 | degrade-only (Stak target) |
| `Instruct.rtn:866` | `opPlusEQ` | SHARED | 1 | degrade-only (unhandled datA) |
| `Instruct.rtn:869` | `opPlusEQ` | SHARED | 1 | degrade-only (no datA) |
| `Instruct.rtn:872` | `opPlusEQ` | SHARED | 1 | degrade-only (dataless argument) |
| `Instruct.rtn:900` | `opPlusPlus` | SHARED | 1 | `jitEmitIterStep`; sits **inside** the iterator arm, below a run-time `fLAG` read |
| `Instruct.rtn:1013` | `opRem` | SHARED | 1 | `ruler = groupRules` consumed by the emit call |
| `ruleActions.rtn:63` | `aCTionBlocK` | SHARED | 1 | `jitStoreResult()` mid-walk; statement already dispatched above |
| `ruleActions.rtn:88` | `aCTionBlocK` | SHARED | 1 | `if jitting continue;` — the emit walk must **not** inherit the interpreter's stop |
| `ruleActions.rtn:171` | `aCTionBrancH` | SHARED | ~24 | `arg = arg.gMethod(arg)` **executes** above the gate; multi-statement emit block |
| `ruleActions.rtn:239` | `aCTionCerR` | SHARED | 1 | degrade-then-fall-through |
| `ruleActions.rtn:333` | `aCTionCouT` | SHARED | 1 | degrade-then-fall-through |
| `ruleActions.rtn:641` | `aCTionFOR` | SHARED | 1 | degrade-then-fall-through; prologue extracts `Looper`/`ExpressioN`/… |
| `ruleActions.rtn:770` | `aCTionIterate` | SHARED | 1 | ⚠ **emits and deliberately does NOT return** — its own comment: "the only gate in the tree that does not return" |
| `ruleActions.rtn:981` | `aCTionPrinT` | SHARED | ~35 | multi-statement emit block; `jitPrintOpen`/`jitPrintArm`/`jitEmitBareRead` |
| `ruleActions.rtn:1148` | `aCTionSearch` | SHARED | 1 | degrade-then-fall-through |
| `ruleActions.rtn:1245` | `aCTionStringXP` | SHARED | 1 | degrade-then-fall-through |
| `GroupActions.rtn:812` | `runAction` | SHARED | 1 | `isCoded`/`processCode` runs above; gate is a **conditional** return (`jitEmitSelfCall`) |
| `GroupActions.rtn:829` | `runAction` | SHARED | 1 | `jitInlinePush(field)` — mid-body, after `saveLocalFields` |
| `GroupActions.rtn:838` | `runAction` | SHARED | 1 | `jitInlinePop(result)` — mid-body, after `processAction` |
| `GroupActions.rtn:941` | `runOP` | SHARED | — | compound condition `if jitting && (op.isOperator \|\| op.isUnary)`; the seed gate, deep prologue |

### CROSSER — 1

| file:line | function | class | body | notes |
|---|---|---|---|---|
| `Instruct.rtn:939` | `opPlusPlus` | CROSSER | 1 | `return jitEmitUnary(result,jitInc)`. **PARKED — not chased.** ⚠ The brief's coordinates `GroupRules.mm:3904→2424` are **STALE**: 3904 is inside a `jitBuildFunction` comment and 2424 is `debugText`. Current generated coordinates are **`GroupRules.mm:9105 → 5435`**; source is `Instruct.rtn:939 → jitEmitters.rtn:1587`. |

### PARSE-ADJACENT — 0

**The bucket is empty, and the absence is bounded rather than assumed.** Searched: every `.rtn`
in the tree (`genParse.rtn` included — **0 hits on both greps**), every top-level `.twk`, and the
jit headers. The `if jitting` stub that `docs/wakeup.md`'s parked list attributes to `parseRule`
is **not present**: `parseRule` lives in `Generate.rtn`, which Tony rewrote offline as the
12-method `parse*` family, and that file now carries zero hits on either grep. Nothing in the
parser population reaches emit machinery today.

**Tony's ruling is still owed on the bucket** — but the thing to rule on is that it is currently
**empty**, not a list.

## THE 13 SELECTORS — `jitContext.h:454-465`

`enum jitOp { jitAdd, jitSub, jitMul, jitSDiv }` (454) ·
`enum jitCmp { jitEQ, jitNE, jitLT, jitLE, jitGT, jitGE }` (461) ·
`enum jitUnary { jitInc, jitDec, jitNeg }` (465). **13, confirmed by count.**

**CONFIRMED: nothing computes a selector at run time.** Every in-scope source occurrence of all
13 falls into exactly three kinds — the `enum` declaration; a `case <sel>:` / `(op == <sel>)` in
the consumer switch inside `jitEmitters.rtn`; or a **compile-time literal argument at a gate
site**. There is no variable of type `jitOp`/`jitCmp`/`jitUnary`, no arithmetic on one, and no
table mapping a name to one. The slot model's premise holds.

**The 18 selector-passing gate sites**, all in `Instruct.rtn`:

| selector | sites | gate lines |
|---|---|---|
| `jitAdd` | 3 | 751 (`opPlus`) · 842, 849 (`opPlusEQ` leaves) |
| `jitSub` | 2 | 548 (`opMinus`) · 577 (`opMinusEQ`) |
| `jitMul` | 2 | 662 (`opMultiply`) · 689 (`opMultiplyEQ`) |
| `jitSDiv` | 2 | 199 (`opDiv`) · 230 (`opDivEQ`) |
| `jitEQ` `jitNE` `jitLT` `jitLE` `jitGT` `jitGE` | 1 each | 366 · 722 · 519 · 500 · 440 · 385 |
| `jitInc` `jitDec` `jitNeg` | 1 each | 940 (the CROSSER) · 637 · 1131 |
| | **18** | |

## NOTES — anomalies. Nothing here was fixed; nothing here is a row.

**N1. ⚠ `opPlusPlus` CARRIES THE POISONED-ITERATOR GUARD TWICE, AND THE COPY ABOVE THE GATE
DOMINATES. A two-half change where only one half landed.** Structural, checkable by pointer:
`if result.fLAG return 0;` appears at **`Instruct.rtn:887`** (top of function, above everything)
**and again at `Instruct.rtn:923`** (inside the iterator arm, below the jitting gate). The
comment block at 923 is a verbatim duplicate of the one at 887 plus this rider:

> ⚠ MOVED BELOW THE JITTING GATE, 2026-08-05, by the run-time-flag census. It used to sit ABOVE
> it, at the top of the function, where it was a RUN-TIME FLAG STEERING THE EMIT WALK …

**It was copied below, not moved.** Two consequences follow from the ordering alone:
1. Line **923 is unreachable**. Nothing between 887 and 923 mutates `fLAG` — only the `isIterator`
   test and the `if jitting { return jitEmitIterStep }` gate, which returns.
2. The condition the rider describes as the danger is **still constructed at 887**: under jitting,
   a poisoned node returns 0 before reaching any gate, so no advance instruction is emitted.

⚠ **The structural claim above is what I am asserting.** Whether a poisoned node actually reaches
`opPlusPlus` during an emit walk is a **causal** claim and is NOT made here — this project's
ledger says structural claims hold and causal ones are a coin flip until run. The 08-05 note
itself records that it "did not bite … correct by accident of ordering". **One fixture answers
it; none exists.** This is the census's only finding that could be a live defect.

**N2. THE BRIEF'S CROSSER COORDINATES HAVE EXPIRED.** `GroupRules.mm:3904→2424` points at a
comment and at `debugText` in today's `.mm`. The pair itself is real and still parked; only the
addresses moved (now `9105→5435`). Same shape as the `ipc/`-gitignored row in `CLAUDE.md`: a
dated measurement carried as a timeless fact. `.mm` line numbers are generated output and should
be re-derived, never cited across sessions — `Instruct.rtn:939` is the durable address.

**N3. ⚠ THE SEAL'S "18" IS RIGHT AND ITS DEFINITION IS WRONG — AND THERE ARE TWO DIFFERENT 18s.**
`docs/wakeup.md` (08-15 seal, item 5) says *"18 gates already have a body that is exactly one
`return jitEmitX(...)` line."* Measured:

| property | count |
|---|---|
| gate sites passing a selector (all in `Instruct.rtn`) | **18** |
| gates whose body is exactly one `return jitEmitX(…)`, **in `Instruct.rtn`** | **18** |
| gates whose body is exactly one `return jitEmitX(…)`, **tree-wide** | **22** |
| gates that are SHIM under this census's precedence rule | **21** |

The two 18s are **different sets**: the selector set includes `opPlusEQ:842/849`,
`opDivEQ:230`, `opMinusEQ:577`, `opMultiplyEQ:689` (all two-call bodies) and excludes
`opAssign`, `opDot`, `opRem`, `opPlusPlus:901`, `opPlusEQ:855` (which pass no selector). They
coincide in size by accident. **The op-selector campaign's scope is the FIRST 18**; anyone
reading the seal's wording will build against a set of 18 that is not the one the campaign needs.

**N4. THE SELECTOR NAMES COLLIDE WITH INCANT FIXTURE ACTION NAMES.** `incant/generate` defines
`jitAdd code={ 3 + 5; };`, `jitSub`, `jitMul`, `jitEQ`, `jitInc`, … and `incant/jitscratch` calls
`testing(jitAdd)`. Different namespace entirely, but a `grep -w jitAdd` returns them looking like
uses. Anyone auditing selector reach must filter `incant/`, or the count inflates.

**N5. A FIXTURE COMMENT CARRIES AN EXPIRED CLAIM.** `incant/jitDfProbe:70` states *"aCTionIterate
has NO jitting gate — verified by grep, not by absence in the dump: in ruleActions.rtn only
aCTionBlocK, aCTionDO, aCTionIF and aCTionWhilE carry `if jitting`."* That was true when written;
**`aCTionIterate` now carries a gate at `ruleActions.rtn:770`**, and `ruleActions.rtn` now has
gates in 13 places, not 4. Not a defect — a dated statement with no date on it, in a file a future
reader will treat as a measurement.

**N6. `aCTionIterate:770` IS THE ONLY GATE THAT EMITS AND FALLS THROUGH.** Recorded because it
breaks the pattern every other row follows and its own comment says the deviation is deliberate:
the emit-time walk still needs the iterator **established** so the enclosing `while ++grup` takes
`opPlusPlus`'s iterator arm and reaches `jitEmitIterStep`. It is the one SHARED row where the
sharing is load-bearing by design rather than by inheritance.

**N7. SCOPE OF THE PARSE-ADJACENT ABSENCE CLAIM.** Stated so it is not read as broader than it is:
searched every `.rtn` in the tree, all top-level `.twk`, `jitContext.h`, `jitExterns`,
`GroupRules.h`. **Not** searched: `GUI/`, `GUI/Stuff/`, `Tests/`, `XML/` (no hits on either
repo-wide grep, so they contain none), and the two excluded-WIP files (checked for hit COUNT only,
zero on both, not read). Generated `.mm`/`.h` were excluded as generated, not audited line by line
against their sources.

## POP

| requirement | result |
|---|---|
| table row count equals grep hit count | ✅ 53 grep-A hits = 51 rows + 2 comment-text mentions; 68 grep-B hits accounted (see below) |
| every hit classified into exactly one bucket or logged as excluded-WIP | ✅ 21 SHIM + 29 SHARED + 1 CROSSER + 0 PARSE-ADJACENT = 51 |
| zero unclassified remainder | ✅ |

**Grep B's 68 in-scope hits reconcile as:** 38 are the emit call inside a grep-A gate already
tabled above (no separate row — same site, two greps); 19 are `extern` **definitions** in
`jitEmitters.rtn`; 6 are emitter→emitter internal calls (`jitEmitDO:820`, `jitEmitGIF:941`,
`jitEmitShortCircuit:1477/1493`, `jitEmitWHILE:1652`, `jitPrintList:2257` — all already inside the
emit world, so a gate would be meaningless); 3 are comment text (`jitEmitters.rtn:519, 532, 645`);
2 are the dual-arm dispatchers' emit calls (`displayFill:31`, `jitTrace:3069`, tabled as SHIM).
**38 + 19 + 6 + 3 + 2 = 68.** ✅

**No site reaches jit emit machinery without the literal gate.** Every `jitEmit<Name>(` call
outside `jitEmitters.rtn` is inside an `if jitting` block; every one inside `jitEmitters.rtn` is
either a definition or a call already downstream of a gate.

---
---

# B0-2 — THE isLiteral RECON (Item 2, measurement only)

**asOf 2026-08-16.** Provenance: **grep + read + one new probe** (`incant/litFlagProbe`).
No source changed by this section. Bound honoured: census and traces first, verdict at the end.

**⚠ THE CLAIM I WAS ASKED TO BANK DOES NOT SURVIVE MEASUREMENT AS WORDED, AND THE CORRECTED
VERSION IS MORE USEFUL.** Asked to bank: *"isLiteral does not carry across rStuff duplication or
the TraiT handoff."* The OBSERVATION behind it is real and reproduced — the flag reads **clear at
every site that matters**. The MECHANISM is not duplication.

## 1. THE CENSUS — every isLiteral site in source

Excludes `Aside/` (gitignored) and generated `GroupRules.mm`/`.h`.

| # | site | function | W/R | which copy of the truth |
|---|---|---|---|---|
| 1 | `GroupBody.twk:68` | — | decl | the flag lives in **GroupBody**, not in RuleStuff |
| 2 | `ruleActions.rtn:905` | `aCTionNumbeR` | **W** | sets on `input`, the NumbeR parse node |
| 3 | `ruleActions.rtn:1052` | `aCTionQuotE` | **W** | sets on `input`, the QuotE parse node |
| 4 | `ruleActions.rtn:1055` | `aCTionQuotE` | **W** | sets on `input`, the QuotE parse node |
| 5 | `ruleActions.rtn:376` | `aCTionDefinE` | R | reads on **`NewGroup`** (`use NewGroup`), tag-swap arm |
| 6 | `ruleActions.rtn:1381` | `aCTionTraiTdata` | R | reads on **`DatA`** — see §4, this is the live one |
| 7 | `Instruct.rtn:319` | `opDot` case 17 | R | the incant accessor, `isLiteraL`, GroupField 17 |
| 8 | `GroupActions.rtn:944` | `runOP` | R | jit seed, operand node at expression time |
| 9 | `GroupActions.rtn:948` | `runOP` | R | jit seed, operand node at expression time |
| 10 | `jitEmitters.rtn:2215` | `jitPrintList` | R | print-item classification |
| 11 | `jitEmitters.rtn:2345` | `jitPrintProbe` | R | trace only |
| 12 | `jitEmitters.rtn:2361` | `jitPrintProbe` | R | trace only |

**Three writers, all at PARSE time on the token node. Nine readers, split across three unrelated
populations** — rule definition (5,6), the incant accessor (7), and the JIT operand path (8-12).
Sites 8-12 are a different population entirely and are NOT in question: they read the operand
node the parse just built, with no definition machinery in between.

## 2. WHAT THE DUPLICATION COPIES AND WHAT IT DROPS

⚠ **THE PATH IS NOT "rStuff duplication". IT IS NODE DUPLICATION, GATED ON rStuff PRESENCE** —
`if rStuff  DatA = new(DatA);` (`aCTionTraiTdata`), `if rStuff  trait = new(trait);`
(`aCTionTraiT`). rStuff is the *trigger*, not the thing copied. That distinction is why the flag
hunt went where it went.

`GroupItem(GroupItem grup)`, `GroupItem.twk:40-48`, in full:

| what | happens |
|---|---|
| `groupBody` | **SHARED — `groupBody = grup.groupBody`. Not copied.** |
| `isCopy` | set true |
| `rStuff` | **deep-copied** — fresh RuleStuff, then `*rStuff = *grup.rStuff` |
| `rule` | re-pointed to the new node |
| `followed`, `isOK`, `sukcess` | **explicitly reset to false** — the only three passengers dropped |

⚠ **SO THE DUPLICATION CANNOT DROP isLiteral. THE FLAG LIVES IN `groupBody->flags`, AND THE BODY
IS THE ONE THING THE COPY SHARES.** A flag set before the copy is visible through both handles;
worse, a flag *set after* the copy through either handle is visible through the other.

**Corroborated in-tree, independently and for a different reason:** `GroupActions.rtn:857`, the
return-seam comment — *"the copy constructor is NOT usable here: it SHARES the body, which is
precisely what the sweep overwrites."* Two readers reached the same structural fact from opposite
directions.

**What IS dropped, and it is worth its own line:** `followed`, `isOK`, `sukcess` — three parse
bookkeeping fields, reset deliberately. Clay asked whether isLiteral was the only passenger
falling off. It is not a passenger at all; these three are, and they are dropped **on purpose**.

## 3. THE TraiTdata → TraiT HANDOFF

`aCTionTraiTdata` ends `input.group = DatA` or `input.setContent(DatA)`. `aCTionTraiT` then takes
`trait = input[1]`, may `trait = trait.group`, may duplicate, and ends `input.group = trait`.
**Neither reads nor writes isLiteral except at site 6.** The handoff moves *nodes*, and since the
copy shares the body, no flag is lost crossing it.

## 4. ⚠ THE MEASUREMENT, AND IT IS THE FINDING

`incant/litFlagProbe` reads `isLiteraL` (GroupField 17) directly, on a labelled literal, a bare
literal, a reference and a rule, so a set value and a clear value could both appear:

```
Braced[1]   labelled literal   isLiteraL = [ 0
Braced[3]   labelled literal   isLiteraL = ] 0
Braced[2]   reference          isLiteraL = ExpressioN 0
LitScaf[1]  bare literal       isLiteraL = x 0
```

**Every literal term reads CLEAR.** The text is right there — `[`, `]`, `x` — so these are
unambiguously the literals, and the flag is off.

⚠ **PUT §2 AND §4 TOGETHER AND THE MECHANISM INVERTS: THE FLAG IS NOT LOST IN TRANSIT, IT WAS
NEVER ON THE NODE THAT IS READ.** `aCTionQuotE` flags the **QuotE parse node**; what survives into
the rule as a term is a node reached through the DatA/TraiT chain. Duplication shares bodies, so
nothing could have dropped it — therefore the writer and the reader are looking at **different
nodes**. This is a **provenance mismatch, not a copy loss**, and that is why chasing it through
the duplication path produced a confusing blast radius: *the mechanism was never on that path.*

⚠ **CONSEQUENCE, AND IT WANTS TONY'S EYE: `aCTionTraiTdata:1381`'s `&& !isLiteral` MAY BE INERT
TODAY.** With isLiteral clear, `(isRule && !isLiteral)` reduces to `isRule`, which is the
pre-change condition exactly. If that clause was added to route a literal to `setContent` rather
than `setGroup`, the measurement says the routing is coming from somewhere else — namely
`aCTionDefinE` no longer substituting `new(item.text)`. **Stated as a consequence of a measured
premise, NOT as a diagnosis**: the reading above is on post-definition term nodes, and confirming
it on the `DatA` node *at TraiTdata time* is one more probe that this recon's bound does not cover.

## 5. VERDICT — **GENUINE YAK, with the blast radius named**

Not "obvious small fix". Making the flag survive means one of:

1. **Flag the right node** — set isLiteral where the term is materialised, not only on the QuotE
   node. That is inside `aCTionDefinE`/`aCTionTraiT`, the two functions Tony has just rewritten,
   and it changes what every one of the nine readers sees, including the three JIT ones.
2. **Propagate at the handoff** — copy the flag explicitly across the DatA/TraiT chain. Cheap to
   write, and it re-introduces exactly the shared-body hazard §2 names: after
   `new GroupItem(node)` the two handles share flags, so a later write through either is visible
   through both.

**The blast radius is `aCTionDefinE` + `aCTionTraiT` + `aCTionTraiTdata`** — the three functions
that build every rule in the grammar, mid-rewrite, with the fleet not yet re-baselined. That is
the confusing blast radius Tony hit, and it is real.

**AND NOTHING NOW DEPENDS ON IT.** `planTerm` was the one consumer that mattered and as of
`0a75df5` it is keyed to the representation instead. Sites 8-12 are the unaffected population.
Site 6 is the open question above. **Recommendation: leave the flag alone; if site 6's clause is
confirmed inert, delete the clause rather than repair the flag.**

## 6. RESIDUAL — a fixture-authoring gotcha, paid for twice today

**A probe needs `Start();` as its FIRST line, with `include`/`search` before the comment header.**
Without it the includes never run, `search` fails token by token, and **`print` emits ZERO BYTES
at exit 0** — a run indistinguishable from a short successful one. `incant/countScratch` has the
correct shape; `incant/litProbe`'s first draft did not, which is why that probe asserts its
completeness on stderr instead. Same silent-failure family as bear-trap #28.
