# Incant JIT — DESIGN (open and active)

*Consolidated 2026-07-31 from eight separate JIT documents. This file holds **design**: what is
settled as invariant, what is open, and what is deferred. **What actually exists and runs is in
`docs/jit.md`** — do not record measurements here.*

**Read `jit.md` §0 first of all: THE JIT REPLACES THE INTERPRETER.** Without it the `jitting`
gate in the source reads as an accelerator and every decision below is misread accordingly.
That has already happened twice.

---

# PART I — THE SETTLED PREMISES

**These three are INVARIANTS, not questions.** They are stated as constraints the design must
satisfy, and anything in the tree or in an older document that contradicts them is a defect in
that thing, not an open debate. Contradictions found during consolidation are listed in
`ipc/clod-to-clay.md` SEQ 37 rather than silently reconciled here.

## Premise 1 — the datA-stability contract

**A field's `datA` is fixed for the lifetime of jitted code that observed it. Violating that is
undefined behaviour BY CONTRACT — no guards, no deopt paths, no type checks at run time.**

This is what makes the whole emission model cheap. The emitter reads a field's type once, at
emit time, and bakes the decision. There is no invalidation machinery, no guard branch, no
bail-out path, and none should be written: adding one would concede that the contract does not
hold and would put a runtime check on every operation to pay for it.

*HPDL, one line, so it is not lost:* a **debug-build warning plus an action-parse abort** when a
field's `datA` changes under a jitted action is the eventual safety net. Debug build only. It
is a diagnostic for the programmer, not a runtime guard for the emitter — the contract stays
"undefined behaviour," and the debug build merely makes the violation loud instead of silent.

## Premise 2 — promotion-first emission

**Rank the scalar types, widen the lesser operand, and the op×type table only ever sees matched
pairs.** Effectively 1D-per-operator after promotion.

The consequence is the point: the table does not need an N×N cell for every operand-type
combination. Promotion collapses it to one column per operator per *resulting* type. This is
already how `jitEmitBinary` behaves for the count/number case — an `isCOUNT` operand meeting an
`isNUMBER` one is `SIToFP`-promoted and the pair goes to `FAdd`. Premise 2 generalises that
from an implementation detail into the rule the table is built on.

## Premise 3 — table in kant, buttress in C++

**IR templates live in a kant table: operator member, type attribute, IR template text.**

**An extern `jitEmit` owns everything the table cannot express:** SSA name counting, slot
substitution, buffer plumbing, and any multi-instruction sequence that does not template
cleanly.

**Type at emit time comes from `dataNames[datA]` — a CARRIED FACT, not an inference.** No type
inference pass, ever. The field already knows what it is.

**Non-scalar `dataNames` (isGROUP, isMAP, isSTAK, …) map to ONE FALLBACK COLUMN: emit a runtime
call into the existing opMethod.** The interpreter does not disappear — it is what the fallback
calls.

⚠ **That last sentence is the reconciliation with `jit.md` §0 and it is easy to misread.** §0
says the JIT *replaces* the interpreter; premise 3 says the interpreter is *what the fallback
calls*. These agree, and the distinction is the whole crossover design: a **per-op runtime call
to a known opMethod, emitted into the IR**, is not the same thing as **whole-action bail-out to
an interpretive walk**. The first is a compiled program calling a helper — one execution path,
which is what §0 requires. The second is two execution paths and is the divergence §0 names.
**A prior plan proposed exactly the second as the v1 policy; premise 3 supersedes it.**

### Premise 3's verified foundation — `dataNames` is index-aligned with the datA enum

*Measured 2026-07-31 by comparing `IncantForms/WorkingOn/tester:17` against `GroupBody.h:60-74`.
All fourteen match. This is what makes `dataNames[datA]` a lookup rather than a mapping.*

| datA | name | scalar? | LLVM type | notes |
|---|---|---|---|---|
| 1 | `isANY` | — | — | fallback column |
| 2 | `isCHAR` | scalar | `i8`? | **OPEN** — no emitter today |
| 3 | `isSET` | no | — | fallback column |
| 4 | `isBUFFER` | no | — | fallback column |
| 5 | `isCOUNT` | **scalar** | `i32` | `gCount`; the proven path |
| 6 | `isGROUP` | no | — | fallback column |
| 7 | `isITEM` | no | — | fallback column |
| 8 | `isMAP` | no | — | fallback column |
| 9 | `isNUMBER` | **scalar** | `double` | `gNumber`; the proven path |
| 10 | `isOBJECT` | no | — | fallback column |
| 11 | `isREGEX` | no | — | fallback column |
| 12 | `isSTAK` | no | — | fallback column |
| 13 | `isSTRING` | **scalar** | `ptr` | `gText`; one `CreateCall` exists, nothing else |
| 14 | `isTOKEN` | **scalar** | `ptr` | as `isSTRING` |

⚠ **Do not confuse this enum with the `binType` family.** `isBIN` is also 1 and `isLIST` is
also 3, in a *different* flag family. `dataNames` indexes the **data** enum only.

---

# PART II — THE OPEN WORK

These are the three items Fearless named as carried-open, plus what consolidation added.

## O1 — the `dataNames` → IR type mapping table itself

The skeleton is above; what is open is every cell it does not fill.

- **`isCHAR` (2) is genuinely undecided.** It is a scalar and it has no emitter, no POP, and no
  stated LLVM type. It is the only scalar row with nothing behind it.
- **`isSTRING`/`isTOKEN` (13/14) are scalars whose only emitted form is a single `CreateCall`**
  (`jitEmitStringPlusEQ` → `concatEQ`). Whether they belong in the scalar table at all or in
  the fallback column with a richer helper set is open. Premise 2's ranking has no defined
  answer for "widen an `isCOUNT` to meet an `isSTRING`" — string `+` count is *pointer
  advance*, not promotion, so it may be the one operator that escapes premise 2.
  ⚠ **A THIRD OPTION EXISTS since 2026-07-31 and this item is not to be settled without it:**
  under the O2 addendum's **method-valued cells**, both of these could live in the **scalar
  table** as method cells rather than being pushed to the fallback column. Recorded, not
  resolved — it gets decided when the table arc opens.
- **The fallback column's shape.** Premise 3 fixes *that* non-scalars emit a call into the
  existing opMethod; it does not fix the **signature** that call uses. Two precedents exist and
  they disagree: the shipped `concatEQ(target, argument)` is a two-pointer write-back form, and
  the durable shape argued for the general case is a **one-argument, value-returning**
  primitive matching incant's own calling convention (one field in, one field out). The two-arg
  form was pragmatic because compound-assign needs `target` by identity. **Pick one before the
  fallback column is built**, because every non-scalar op inherits it.

## O2 — the template slot convention

The table holds "IR template text." Nothing yet says what a slot looks like inside that text,
and the choice constrains `jitEmit` (O3) directly.

Open, and unprejudged: the delimiter and escape rule; whether slots are positional or named;
how an SSA result name is requested versus supplied; how a template declares that it needs *n*
fresh names; and whether a template can carry more than one instruction or whether
multi-instruction sequences are by definition `jitEmit`'s business. That last one is the seam
between the table and the buttress, so it is really the same question as O3.

### O2 addendum — METHOD-VALUED CELLS (Tony's idea, vetted; recorded 2026-07-31)

*Recorded now, built later. No implementation, no fixtures, no schedule change — this
addendum does not touch the O4 arc.*

**A kant attribute can carry a method, so a table cell is not restricted to template text.**
The lookup may yield either:

| cell kind | what happens |
|---|---|
| **TEXT** | a template with slots — substitute and append. **The default.** |
| **METHOD** | an executable cell — it fires, and emits through the *same* C++ primitives the text path uses (fresh-name, append, emit-call) |

The second is the interesting one because it does **not** widen the C++ surface: a method cell
reaches for the same primitives, so the buttress does not grow to accommodate it.

**Three consequences, settled at record time:**

1. **The O3 boundary TIGHTENS.** The buttress owns the emission **primitives** and **block
   topology**; anything expressible as a *sequence of emissions* may live in kant as a method
   cell. That is a strict improvement in self-hosting posture over O3's current
   "buttress owns every multi-instruction sequence" — a rule that hands C++ everything merely
   because it is more than one instruction.

2. **DISCIPLINE: TEXT UNLESS TEXT CAN'T.** Method cells are the **escape hatch, not the
   default.** A table that drifts toward all-method **becomes a program**, and loses exactly
   what made a table worth having: inspectability, diffability, and the golden-IR guard.

3. **INSTRUMENT CONSEQUENCE, and it is a design-time one** — *doubt the instrument before the
   code* (CLAUDE.md Testing). The golden-IR POP validates TEXT cells by parsing their output.
   **Method cells escape that guard entirely** unless the POP grows a **fixture-firing mode**:
   fire each method cell against fixture operands and validate the emitted IR. **Both modes
   are deliverables of the table arc**, not of this addendum — but the guard must be designed
   knowing half the table can slip past it, because a table whose method cells are unchecked
   is a table with a silent half.

**Bears on O1 — noted, NOT resolved.** `isSTRING`/`isTOKEN`, and the string-plus-count
pointer-advance case that escapes premise 2's promotion rule, **could live in the scalar table
as method cells** rather than being pushed into the fallback column with a richer helper set.
That is a genuine third option O1 did not have. **It gets decided when the table arc opens,
not here** — recording it now only so the choice is on the table when O1 is settled.

## O3 — the exact `jitEmit` ownership boundary

Premise 3 lists what `jitEmit` owns — SSA name counting, slot substitution, buffer plumbing,
sequences that do not template cleanly. **"Does not template cleanly" is the load-bearing
phrase and it is not yet a test.**

The forcing case is already in the tree: `jitEmitGIF` is three basic blocks, a `CreateCondBr`,
two sub-walks and a merge. Nothing about that is a text template with slots. So control flow is
plainly `jitEmit`'s, and plain binary arithmetic is plainly the table's — the boundary runs
somewhere between, and the cases that decide it are compare-with-promotion, compound assign
(binary then store), and the fallback call.

**A useful discipline while the boundary is unsettled:** anything that needs to *know a block
structure* is the buttress; anything that is one instruction with substituted operands is the
table.

⚠ **TIGHTENED 2026-07-31 by the O2 addendum, and the change is in the middle term.** The
sentence above leaves "more than one instruction" ambiguous, and premise 3's "sequences that
do not template cleanly" hands those to C++ by default. With **method-valued cells** the rule
sharpens to:

> **the buttress owns the emission PRIMITIVES and BLOCK TOPOLOGY. Anything expressible as a
> SEQUENCE OF EMISSIONS may live in kant as a method cell.**

So multi-instruction no longer implies buttress — only *block-structural* does. Read O2's
addendum before applying the discipline above; it is the more current statement of the same
boundary, and it moves work **toward** kant rather than away from it.

## O4 — added by consolidation: the mem2reg contradiction, and it is the sharpest open item

**The design says SSA comes from alloca/load/store plus `PromotePass`, and never write a phi.
The first IR ever dumped from this tree (2026-07-30) shows field slots are `inttoptr` ABSOLUTE
ADDRESSES, not `alloca`s — so mem2reg has nothing to promote.**

`jitSeedField` bakes the field's stable `gCount`/`gNumber` address and stashes it as `jitSlot`.
That is a real address in the GroupItem, not a stack slot. It works for straight-line code and
it makes the store-through-to-the-field behaviour free, which is why it was built that way and
why the assign POPs pass by readback.

But two things in this document assume allocas: the prologue/epilogue frame model (Part III),
and "PromotePass places all phi nodes" (which is what makes a missing merge impossible).
`jit.md` §3.4 records that the gIF return value is **not** merged — and a missing merge is
exactly what an unpromoted, non-alloca slot model would produce.

### ⚠ RESOLVED 2026-07-31 BY MEASUREMENT — and (a) vs (b) was the wrong question

The IR was read properly rather than argued about, and it collapses the choice:

> ### THE PRINCIPLE, stated because it is the reasoning and not just the outcome:
> # **THE MERGE IS THE MEMORY LOCATION.**
> Two paths that write the same address need no merge instruction — the address
> *is* the merge. That one sentence covers both halves of O4: fields (baked
> absolute addresses) and results (the result slot), and it is why neither
> needed a phi written by hand.

**FIELDS DO NOT NEED PHIS, BECAUSE FIELDS ARE MEMORY.** A slot is a baked absolute address;
a read is `CreateLoad` from it and a write is `CreateStore` to it. Two stores to the same
address on two paths need **no merge at all** — that is what memory *is*. The four-block
if/else emitted for the J2 rung is correct on both paths with not a phi in sight, and the
verifier is silent because the IR is genuinely valid.

So the design's mem2reg dependency is not *broken*; it is **unnecessary for the thing it was
written about**. `jitEmitters.rtn`'s own comment already says PromotePass is "a no-op on the
current alloca-free shape" — the code knew, and only the design did not.

**(a) and (b) are therefore NOT alternatives — they are PHASES, and the doc's error was
stating the future mechanism as the current one:**

| | baked addresses (today) | frame model (later) |
|---|---|---|
| what it covers | fields and globals | **locals and recursion** |
| correctness | correct, no phis needed | correct |
| cost | a load/store per access | native values in registers |
| needs mem2reg | **no** | **yes** — that is where allocas appear |

⚠ **AND `never write a phi` IS NOW MEASURED-WORKING, not merely asserted.** The result slot is
the **first alloca this emitter has ever produced**, so `PromotePass` finally had something to
promote — and it inserted the phi itself:
```
emitter wrote:   then: store %mul, ptr %result    LLVM produced:
                 else: store 7,    ptr %result      %result.0 = phi i32 [ %mul, %then ], [ 7, %else ]
                 endif: %retval = load ptr %result  ret i32 %result.0
```
The position was carried for a month against an emitter that emitted no allocas at all. It is
now demonstrated on the one construct that needed it.

The frame model is not dropped and must not be: §0 Consequence 1 says locals-as-frames lands
**once, in the JIT**, and `saveLocalFields` is deleted rather than repaired. That is about
**recursion and per-call frames**, which baked addresses cannot do — a recursive action's
locals would all alias one address. So the frame model is **deferred, not superseded**, and
mem2reg arrives with it.

**⚠ RATIFIED 2026-07-31 (Clay, amending the same day's earlier ratification; Tony's green
carries). The phrasing to keep is PHASED, NOT (a)-vs-(b).** Baked absolute addresses are
**correct and current** for fields. `alloca` + `PromotePass` + never-write-a-phi **rescopes**
to the frame model, where baked addresses cannot work.

### The return value — ⚠ RULED 2026-07-31, no longer open

**THE COMPILED ACTION RETURNS WHAT THE INTERPRETED ACTION RETURNS. One semantics, not two.**

**Mechanism: a RESULT SLOT — results are memory too**, exactly as fields are, so this needs no
phi either and composes with the current phase rather than waiting on frames:

- every `return` → **store to the result slot, then branch to an exit block**
- `jitRunAction`'s cap → **load the slot, `ret`**
- **`gJitResult`-as-last-value retires.**

#### What the interpreter actually returns — MEASURED, not assumed
*`incant/retProbe`, one run, exit 0, 2026-07-31. Read off the source first and then run,
because a source read grades `inferred` in this project and only a run grades `verified`.*

The chain is `runAction` (`GroupActions.rtn:572,574`) → `processAction` (`:447,457,460`) →
`aCTionBlocK` (`ruleActions.rtn:21-26`).

| body ends with | returns | |
|---|---|---|
| an assignment `zqv = 41;` | **41** | the last statement's value |
| a `print` | **1** | `opPrint` yields `trueResult` |
| `return zqv;` | **43** | |
| **a BARE `return;`** | **the string `"return"`** | ⚠ see below |
| `return zqv;` with code after it | **45**, and the later statement **did not run** | `isBranch` breaks the loop |

**So the rule is: AN ACTION'S VALUE IS THE VALUE OF THE LAST STATEMENT EXECUTED.** There is no
implicit null, no implicit argument, no `falseResult` default. `return` is not "produce a
value" — it is **"stop here"**, and the value is still whatever the last executed statement
evaluated to. A group-valued result is dereferenced (`result = gGroup`) on the way out, and
`isBranch` is cleared at the action boundary so it cannot leak into the caller's loop.

⚠ **CONSEQUENCE FOR THE EMITTER, and it is bigger than "store on return": EVERY statement's
value must reach the result slot, not only the ones written `return`.** A store-on-return
emitter would return garbage from every action that simply ends. That is a materially
different shape and it follows directly from the measured rule.

#### ✅ THE BARE-RETURN WART IS CLOSED — ratified and fixed 2026-07-31

**A bare `return;` now yields the PRIOR statement's value.** Tony's ruling: bare return means
**stop**, and the action's value is the last executed statement's — the `"return"` string was
`CLAIM KANT-10` leaking through `aCTionBrancH`, never a semantics.

**Two sites, and the emitter's half is free.** Under the result-slot mechanism a bare return
is simply *branch to exit, no store* — the slot already holds the last statement's value, so
nothing special is needed. The interpreter took the fix.

⚠ **The fix could NOT live in `aCTionBrancH` alone, and the reason is worth carrying into the
emitter design: the VALUE and the BRANCH SIGNAL ride the same node.** `aCTionBrancH` stamps
`isBranch` on whatever it returns, and four loop handlers read that flag back off the body's
returned value. Substituting a different node for the value drops the signal with it. The
compiled form does not inherit this: a branch and a stored value are separate things in IR,
which is one small place where the emitter is *cleaner* than the interpreter rather than
merely equivalent.

#### ✅ AND `break` IS CONSUMED AT THE LOOP BOUNDARY — ratified and fixed 2026-07-31

Same family, found by the fixture written to protect the return fix. **A `break` terminates
the innermost loop and propagates nothing; statements after the loop run.** Before the fix a
`while` returned the break-node with `isBranch` still set, the enclosing block broke on it too,
and **the code after the loop was unreachable** — measured, `incant/loopBranchT` row 1.

**The emitter's half is again free:** `break` → `br` to the loop's exit block, already in the
loop design (Part IV). There is no signal to consume because there is no signal — the branch
*is* the control flow.

---

## THE EMITTER RULES (E-series) — audited like the H-series, and for the same reason

*A standing series for rules the emitter must obey, kept here rather than in a commit message
because each one is a trap the next emitter will walk into. Audit new emitters against them.*

### E1 — A BRACKETING EMITTER LEAVES NOTHING IN FLIGHT
**Adopted 2026-07-31, paid for the same day.** An emitter that brackets sub-walks (an `if`, and
every loop to come) **commits its own arms and then clears `gJitResult`.**

`jitEmitGIF` commits both arms to the result slot *inside their own blocks* — that is the merge
— and then clears. Without the clear, the **enclosing** walk sees a stale in-flight value and
commits it **again in the merge block**, clobbering the merge so every path returns the last arm
*emitted* rather than the one that *ran*. Measured: two extra `store i32 7` in `endif`, and both
paths returning 7.

**The rule is not "clear a variable", it is a statement about ownership:** a control-flow
statement's value is *already committed*, so there is no loose value for anyone else to commit.
**The loop emitters are E1's first audit customers** — they bracket exactly as `gIF` does.

---

# THE TABLE ARC — rulings, 2026-08-01

*Design session Tony + Clay closed 2026-07-31 late; relayed and recorded by Clod 2026-08-01.
**The frame model remains the main line** — this arc opens when schedule allows, priority
Tony's. Recorded now because a ruling written down before the first tempted implementer costs
nothing and a ruling written down after costs an argument.*

## T1 — SHARED DISPATCH, FORKED LEAVES (ruled 2026-07-31)

**The opMethod keeps its type-pair dispatch tree ONCE. Each leaf forks do-vs-emit.**

Not two parallel trees, and not a `jitting` gate at the top of the function — which is what
every op does today and is exactly why `jit.md` §3.5 can list seven ops whose gate fires
assuming a numeric target. A top-of-function gate has to re-decide the type question the
dispatch tree below it already answers, so the two answers can disagree; a forked leaf cannot
disagree with itself.

Leaf kinds, ruled:
- **Scalar leaves → templates** from the table (O1/O2).
- **Stak / Buffer / structure leaves → fallback calls**, on the J7 machinery — the first
  emitted `CreateCall` into a real opMethod that gets a value back, proven 2026-07-31.
- **Uncovered leaves → DEGRADE LOUDLY** (`jitDegrade`, §1.3 of `jit.md`). ⚠ **Silent
  fall-through is to be structurally gone, not merely discouraged** — this is the *"prefer a
  structure that makes the failure unconstructable"* family, and it is the reason the counter
  exists.

⚠ **`jitDegrade` currently has ZERO call sites** (measured 2026-08-01 — its only two were the
`"++/-- on an iterator"` lines the iterator rework replaced). The ladder's `degrade count = 0`
checks therefore still pass but are **vacuous**. The probe is what makes them mean something
again; until then, do not read a green degrade row as coverage.

**Probe coverage, as briefed:** count · number · promote · string-concat (the ruled two-arg
exception) · Stak · Buffer · SET.

## T2 — NO HAND-WRITTEN COPIES: GENERATION OR SHELLS ONLY (ruled 2026-07-31)

A dispatch tree that exists in two hand-maintained copies drifts, and the drift is invisible at
every call site. So: **the table is the source of truth, the dispatch tree is a generated
artifact — both the do side and the emit side.** Where generation is not yet available, a
hand-written *shell* that delegates is acceptable; a hand-written *copy* is not.

This is genParse's move pointed at `Instruct.rtn`, and the deliverable of the promotion is the
**ASSESSMENT** — can it, should it, what is missing — **not adoption.**

⚠ **T2 acquired direct evidence on 2026-08-01, and it is stronger than the argument that
motivated it.** See T3: three of the seven family members disagree about a property the family
is supposed to share, purely through hand-ordered arms. Generation does not *fix* that defect
class, it makes it **unconstructable**.

## T3 — THE ARGUMENT-LIST FAMILY: hypothesis GROUNDED, and it is NOT exact

**The hypothesis as briefed:** the seven list-taking ops (`:+` `+%` `:%` `/=` `-=` `*=` `+=`)
ARE the two-pointer write-back family; if exact, list-taking and target-mutating are one
property, and per-element iterate-and-fire is fold-left by construction.

**Ground check run rather than asserted** — `incant/familyT`, exit 0, sentinel present,
2026-08-01. Verdict: **half exact, and the inexact half is the interesting half.**

| claim | verdict |
|---|---|
| all seven take argument lists | ✅ exact |
| all seven mutate `target` by identity and return it | ✅ exact |
| all seven iterate the list internally | ❌ **six of seven.** `+=` does not |
| per-element fold order is source order | ✅ **MEASURED** — `+%` over three distinct tags folds `P Q R`, not `R Q P` |
| the per-element arm is reachable in every iterating member | ❌ **`-=` and `*=` cannot reach theirs** |

**On the order half — it could only be settled by running.** Every iterating member walks with
`argument.prior(...)`, which is a *backward* list walk; whether that yields source order is a
fact about how `aCTionExpressioN` builds the list, not about the walker. Reading `prior` and
concluding "reversed" is the causal-claim shape that fails in this codebase; measuring it is the
structural one that holds. **Fold-left is confirmed, so emission order is the right convention.**

**⚠ THE RUNG-DESIGN NOTE, APPLIED RATHER THAN QUOTED — and it inverted the briefed choice.**
The brief asks for a non-commutative op with distinct values, naming `-=` and `/=`. But **`-=`
and `/=` over a LIST are order-BLIND**: `100-1-2-3` is 94 in any order and `1000/2/5` is
`1000/5/2`. They are non-commutative as *binary* ops and order-blind as *folds*, so they would
have gone green on a reversed walk — a happy set in disguise. **`+%` is the order-injective
instrument**: three distinct tags land in a list whose read-back order *is* the fold order.
*Injectivity has to be checked against the fold, not against the operator.*

**⚠ AND A PRE-EXISTING DEFECT, found by the ground check, NOT introduced by it.** Measured:

```
numA = 100; numA -= 7;        ->  93     scalar path, correct
numB = 100; numB -= 1 2 3;    ->  100    SILENT NO-OP     (expected 94)
numC = 100; numC *= 2 3;      ->  0      SILENT WRONG     (expected 600)
numD = 100; numD /= 2 5;      ->  10     correct
```

⚠ **THE CAUSE IS OPEN, and a first attempt at one was withdrawn the same hour — recorded
because the withdrawal is the useful part.** The obvious story reads straight off the source:
`-=` and `*=` test their scalar arm as `data && argument.data` without checking the argument is
a *scalar*, so a list node would satisfy `argument.data`, the switch would run with the list
node as operand (`argument.count` == 0), and the `or argument.isLIST` per-element arm below
would be unreachable. It fits both numbers exactly, and `/=` — the correct one — is also the
only one that guards on the ARGUMENT's type (`argument.isCOUNT || argument.isNUMBER`). Tidy, and
probably still the answer.

**But `incant/tableProbe` went looking for that story's load-bearing premise and found the
opposite: a node carrying a list reports `datA = 0`** — no data — for both a define-block group
and one built with `+%`. If an expression-list node behaves the same, `argument.data` is false
and that arm is not the one that ran. Two unmeasured ways out: an `aCTionExpressioN`-built list
node may differ from a define-built one, or the zero comes from elsewhere.

**Filed as: behaviour MEASURED, cause OPEN.** This is the measured asymmetry from `CLAUDE.md`
behaving exactly as advertised — the structural claim (three of seven disagree) held; the causal
claim (which arm ran) did not survive its own check. Settling it needs instrumentation on the
expression-list node, not more source reading.

**NOT REPAIRED.** Pre-existing, Tony's call, and the probe's whole point is to decide whether
these get fixed by hand or deleted by generation. **Note that the assessment does not depend on
the cause** — three of seven disagreeing is the argument for T2 whichever arm is at fault.

## T5 — PREMISE 3's FOUNDATION RUNS, and two things it turned up

`dataNames[datA]` — premise 3's "type at emit time is a CARRIED FACT" — **had never been
executed.** It appears in exactly two places in the tree (`IncantForms/Windows/tabs:36`,
`IncantForms/WorkingOn/tester:57`) and in **both it sits below a `stop()`**: Tony's own prototype
of the table's index lookup was dead code that looked live, which is standing rule H2's exact
pathology and the reason H2 exists.

**It works.** `incant/tableProbe`, exit 0, sentinel present, 2026-08-01: `isCOUNT` → 5 →
`isCOUNT`, `isSTRING` → 13 → `isSTRING`. Index alignment confirmed *live*, not just by
enumeration. Premise 3's foundation is sound and the arc can be scheduled on it.

⚠ **Finding 1 — A FLOAT LITERAL DID NOT PRODUCE AN `isNUMBER` FIELD. ✅ FIXED 2026-08-01.**
`probeNumber = 3.5` came back `datA = 5` (isCOUNT) and printed `3`; `localNum2 = 7.25` printed
`7`. Not a define-block artifact — an assignment inside an action body did the same.

**Tony ruled it a defect the same day: KANT'S NUMERIC TOWER IS `count` AND `double`, NO FLOATS
EVER, and a float-like literal IS a double literal that must survive as one.** Silent truncation
at the literal's birth, with no rounding, is not a representation choice.

**Cause, MEASURED with a trace in `aCTionNumbeR` rather than reasoned:** the action branched on
a `GroupItem FloaT:;` label, and for input `3.5` that label is **absent** while the token text is
exactly `"3.5"`. `NumbeR` matched the decimal correctly; `tokenize` on `NumbeR` flattens the
match into one token and the `FloaT` child label does not survive for the action to test. So the
branch always took `atoi`. The fix classifies on the **text** — a decimal point mints
`isNUMBER` — which is reliable because the text is intact including the exponent.

Now: `3.5` → `3.5` · `0.25` → `0.25` · `1.5e2` → `150` · the field reads `datA = 9` (isNUMBER) ·
`3.5 + 1 = 4.5`. `oneTest`/`jsonTest` byte-identical. **The `number` leaf is reachable from a
literal, so the probe no longer needs a non-literal workaround.**

⚠ **STILL OPEN AND ADJACENT, NOT FIXED HERE:** `10 / 4` yields `3` and stays `isCOUNT`. That is
count-÷-count, and whether it should promote is **premise 2's promotion question**, not the
literal defect — a different ruling, and Tony's. Flagged because the probe's `promote` leaf sits
directly on it.

⚠ **Finding 2 — `datA = 0` has no entry.** `dataNames` is 1-based (`isANY` at 1), so a field
with no data indexes nothing and the lookup yields empty. Correct and harmless, but it means
**"no data" must be an explicit leaf in the dispatch tree**, not a fall-through — otherwise it
lands wherever an empty lookup happens to land. Same finding is what put T3's cause back in
doubt.

**Consequence for the emit side, and it sharpens `jit.md` §3.5.** All three compound-arithmetic
ops put `if jitting { jitEmitBinary(...); return jitEmitAssign(target,target); }` at the **top
of the function**, above every type and list test. So under jitting they are not merely
numeric-*assuming* — they are **list-blind**, and would emit one binary op against the list
node. T1's forked-leaf shape is what removes this by construction, and it is the concrete case
that makes T1 worth the rework.

## T4 — LOCATE IS PROHIBITED, NOT PROVIDED (Tony, relayed SEQ 38; ruled here 2026-08-01)

**Action execution never calls `locate`. All fields, local and global, are resolved and baked at
PARSE time.** `locate`'s legitimate callers are kant-unaware C++ hosts — never actions.

The allow-list criterion, which replaces `locate`'s appearance in PART IV's runtime-surface
list:

> **OPERATIONS ON RESOLVED THINGS — yes. RESOLUTION OF NAMES — never.**

**A `locate` call in emitted IR is a defect by definition**, not a performance question and not
a matter of taste. See PART IV, where the correction is applied.

**The invariant is INHERITED, not imposed.** Everything already built obeys it without having
been written to: baked field addresses (`jitSeedField`), the closed frame schema, baked opMethod
pointers (`jitEmitRem`, `jitEmitTrace`). Nothing in the emitted IR resolves a name. This names a
rule the design was already following so that no future convenience can unknow it.

**Standing guard, cheap and permanent:** the irshape/golden-IR layer asserts that **no call to
`locate` appears in any rung's emitted IR** — a never-assertion beside the existing presence
assertions. ⚠ **A never-assertion is absence-shaped, which is what H4 warns about** (an absence
check passes by being deleted). H4's escape is the vacuity guard: **pair it with a presence
assertion that proves the dump was captured** — the rungs already assert block names — so "no
locate" cannot pass because there was no IR to look at. Written any other way it is theatre.

---

# PART III — THE FRAME MODEL (designed, not built — and it is a LATER PHASE)

## ✅ RULED 2026-08-01 (Tony) — INLINING IS KANT'S CALLING CONVENTION

**By design, not accident. Emit-on-walk inlines by construction — the architecture IS the
inliner.** Two arms, and they are stated together because either alone misreads the design:

| call | emission |
|---|---|
| **non-recursive** | **INLINED** into the caller's function. No `call` instruction at all — `runAction → processAction` re-executes the callee's BlocK into the *current* builder, so its ops emit in place |
| **recursive** | a **real call** via `jitEmitSelfCall`, with its own frame |

*Measured before it was ruled: `incant/jitJC` fires twice with no recompile and the answer tracks
the input (21 → 61) while the IR contains no `call` whatsoever.*

**Three consequences, each worth its sentence:**
- **Zero call overhead on the jitted path.** Not "cheap" — absent.
- **mem2reg optimises ACROSS dissolved call boundaries**, because after inlining there is no
  boundary left to optimise across.
- **Small composed actions are therefore the FAST idiom, not merely the preferred one.** ⚠ The
  conversion arc should know this: it is about to mint exactly that population, and the style it
  was already going to choose for readability turns out to be the performant one too.

⚠ **The recursive arm is not a caveat, it is the other half.** Inlining a self-call cannot work,
and not only because it would not terminate: the re-walk reuses nodes already carrying `jitData`
from the enclosing pass, and `jitEmitCompare` has by then written its **i1 result** into the
condition target's `jitValue` — so the second pass compares i1 against i32 and LLVM asserts.
Measured with a trace, 2026-08-01. One channel carrying two meanings again; the cure is a second
channel — emit a call and stop re-walking.


*This is a calling-convention design, not a codegen design. It is the replacement §0
Consequence 1 refers to when it says `saveLocalFields` is deleted rather than repaired. **None
of it is implemented.***

> ### ⚠ PHASE SCOPE — read this before applying anything below to today's emitter
> **O4 is ratified as PHASED, not as a choice between two models.** Everything in this Part
> belongs to the **frame phase**, which exists for **locals and recursion** — the one thing
> baked addresses genuinely cannot do, because a recursive action's locals would all alias a
> single address.
>
> **What is CURRENT, and is correct:** fields and globals live at **baked absolute addresses**,
> and a write is an **immediate store-through** to the field's own storage. That is what the
> emitter does today and what the measured IR shows working on both arms of an if/else.
>
> **What is DEFERRED to this phase:** `alloca` slots, the unbox prologue, `PromotePass`, and
> — specifically — **the epilogue write-back semantics below, including the deferred-globals
> divergence.** None of that describes today's behaviour, and reading it as though it did is
> what let "mem2reg is the foundation" sit in this document for a month while the emitter
> emitted no allocas at all.
>
> **The result slot is the exception that does NOT wait**, because results are memory too —
> see O4's return-value ruling. It composes with the current phase.

## The problem it solves

Incant actions carry their local fields as named attributes on the action's GroupItem, which
conflates two things:

- **The frame schema** — the set of fields an action uses. Known at parse time. Belongs to the
  action *definition*.
- **The live frame** — the actual values during one specific call. Belongs to one *invocation*.
  Must be per-call for recursion to work.

The interpreter conflates them because every call operates on the same action GroupItem and its
attribute list, so recursion works by convention rather than by structure. The JIT separates
them: the definition keeps its attribute list as the authoritative schema; each call allocates a
fresh slot array from it. C++ stack discipline applied to incant's no-declarations model.

## ⚠ RECURSION IS THE FORCING CASE, and it is Tony's named refinement of the POP goal
*Recorded 2026-07-31, at Tony's request. Not scheduled — but named, because it decides when
this Part stops being deferred.*

**Tony's worry, in his words: "handling recursion by making use of undeclared slots or however."**
The sharp form is that **incant has no declarations**, so where does a recursive frame's storage
come from?

**This Part is the answer, and the ladder is what will force it.** Rungs J1–J5 all run on
**baked absolute addresses** — a field's slot *is* its own storage, one address per field.
That model **cannot express recursion**: a recursive call's locals would all alias the same
address and the inner call would overwrite the outer's. There is no patch for that; it is what
the model *is*.

So the answer to "undeclared slots" is the schema below: **the action's field list is the frame
schema**, closed at parse time, which is exactly what makes per-call slot arrays possible
*without the programmer declaring anything*. The declarations incant does not have are replaced
by a field list it already builds.

⚠ **Therefore rung J-R (recursion) is a PHASE BOUNDARY WEARING A RUNG'S CLOTHES.** Every other
rung adds a construct to a working model; J-R changes the model. Plan it as the start of the
frame phase, not as one more step on the ladder.

> ### **J-R IS THIS PART'S DEFINITION OF DONE**, the way J1 was the result slot's.
> A recursive action — one local, one argument, a self-call, a base case — compiled once and
> **fired at two depths, correct at both**. Two depths is the discriminator: **depth-1 passes on
> aliased slots, depth-N cannot.** Sequenced after the loop rungs (frames build on the calling
> convention; loops do not need it).
>
> ⚠ **Named prerequisite: there is no `jitEmitCall`** (`jit.md` §1), and its seam is the same
> `isMethod` branch the unary seed bug lives on. **A self-call is a call**, so J-R's own ladder
> is **call emission → frames → recursion as proof.**
>
> **And it closes more than itself.** When J-R goes green it certifies recursion, certifies this
> Part, closes `CLAIM KANT-8`'s whole class — returning a local from a recursive action emptied
> it via `restoreLocalFields`, which is the interpreter failing at *exactly this* — and executes
> §0 Consequence 1's death warrant on `saveLocalFields`. One fixture, four things, because they
> were always one piece of work seen from four sides.

## ⚠ RECON, 2026-07-31: THE FRAME SCHEMA ALREADY EXISTS IN THE TREE

*Read before building any of this. It de-risks the arc substantially and it was not obvious
from the design side.*

**The enumeration this Part calls "the frame schema" is already implemented, in production, for
a different purpose.** It is one predicate over the action's own field list:

```
    while grup = action.next(grup)                     GroupActions.rtn:697  (save)
        if (grup.isArgument || grup.isLocal) && !grup.noPrint { … }

    while grup = action.prior(grup)                    GroupActions.rtn:524  (restore)
        if (grup.isArgument || grup.isLocal) && !grup.noPrint { … }
```

Forward to save, backward to restore, the **same membership test both ways**. That *is* schema
closure, and it has been carrying recursion in the interpreter all along.

**Three consequences, and the first is the useful one:**

1. **The JIT does not have to invent the schema — it inherits a predicate that has been in
   production.** Model-not-oracle, exactly as genParse's walk took `noPrint` as its classifier
   rather than inventing a parallel test: take the enumeration the interpreter already agrees
   with, so the two cannot drift.
2. ⚠ **THE FUNCTION §0 SENTENCED TO DEATH IS THE ONE THAT DOCUMENTS WHAT TO BUILD.**
   `saveLocalFields` is both the thing being deleted and the specification of its replacement.
   **Read it before deleting it**, and do not delete it until the JIT's version is green — its
   walk is the only written statement of which fields constitute a frame.
3. **The interpreter's `recurseSTAK` push/pop is a manual, heap-allocated version of what
   allocas do for free.** That is the whole delta: same schema, same discipline, different
   storage — which is why §0 could sentence the function without redesigning the semantics.

### The first increment, and what it can and cannot prove
1. Walk the schema at emit time; emit one **`alloca` per local** in the entry block.
2. **Prologue** — load each local's current value into its alloca.
3. `jitSeedField` uses the alloca as `jitSlot` **for locals**; globals keep their baked address
   and immediate store-through (the phase scope above).
4. **Epilogue** — store each local back before the `ret`.

⚠ **STATED PLAINLY BECAUSE IT AFFECTS HOW THE RUNG IS READ: increment 1 is NOT independently
provable.** Without recursion, allocas-for-locals is **behaviour-neutral** — the same answers
come out. What a rung can assert is *structural* (allocas present in the IR, no baked address
for a local) plus *unchanged values* as a regression net. **The proof is J-R**, because
per-call storage only becomes observable when two calls are live at once. Do not let a green
structural rung read as "the frame model works."

## Schema closure, and the precondition it rests on

Every field an action references is added to its field list at parse time, so the field list is
the complete and closed universe of everything the action touches. Each field gets a stable slot
index; every field reference compiles to that index.

⚠ **This closes only because actions are not modified in place.** Nothing — directives, runtime
construction, reflection — adds a field to a *live* action afterward. A field appearing at
runtime that the schema never enumerated would have no slot to land in. **This is a load-bearing
dependency, not an incidental property.** If in-place action modification is ever wanted, this
is the first assumption that must be revisited.

## Slots, prologue, epilogue

**Slots are native-typed, not GroupItem pointers.** The conservative alternative — slots as
`GroupItem*` with the body calling opPlus via `CreateCall` — gives frame discipline but no real
win over the interpreter, and is not worth building.

*Prologue:* for each field, load the `GroupItem*` from the incoming slot array, read the native
value from its typed data member, store into the field's `alloca`. After that the body operates
entirely on native values.

*Epilogue:* reverse it — load each final native value and store it back to the GroupItem. The
action's result is reboxed and the function returns a `GroupItem*`, not a raw native value. The
C++ boundary signature stays `GroupItem* (*)(GroupItem* slotArray, GroupItem* argument)`.

⚠ **Globals are written back at the EPILOGUE, not immediately** — ⚠ **FRAME PHASE ONLY; this
is NOT what happens today.** Today a global write is an immediate store-through to the field's
own address, with no divergence at all. The deferred-writeback divergence below arrives *with*
the frame model and is a cost of it, not a description of the current emitter: a global updated mid-action is invisible to other incant
code until the action returns, and **on abnormal exit the epilogue may not run and global
updates are lost.**

## Assign semantics under frames

`A = B` between locals is a native value copy, fully static. `:=` (byRef) stores a
pointer-to-slot rather than a value. **The tag-aliasing ambiguity that complicates `A = B` in
the interpreter disappears**, because A and B are distinct indexed slots.

## Where `JitData` lives — and the design doc was wrong about this for a month

Transient per-field emission state (`jitSlot`, `jitValue`, `jitType`) is **hung on the node as
a `JitData`**, not held in a C++ `std::unordered_map` side table. The side table was specced
first and **fights tok two ways**: it forces passthrough for every state access, and llvm-typed
signatures poison the generated header (`jit.md` §6). The node-hung form was adopted during the
2026-06-17 wiring walk and is what shipped. **The design document was supposed to be updated to
match and never was**, which is how a superseded side table survived in the spec until this
consolidation.

---

# PART IV — CONTROL FLOW AND THE RUNTIME SURFACE

## The fundamental inversion

In execute mode `aCTionIF` evaluates the condition and runs *one* branch. **In emit mode it must
emit *both* branches as basic blocks connected by `CreateCondBr`. It cannot take a path.** The
same inversion applies to every loop: emit header, body, latch, exit.

`aCTionIF` is the template, and the strategy for the rest is one line: **a jitting gate → a
`jitEmit*` bracketing emitter that runs sub-walks via `gMethod` between basic-block brackets.**
The pivot already paid for the hard part (emission rides the walk); loops add only block
topology.

## Loop order, and why

**WHILE first** (minimal topology, no latch work), **DO second** (WHILE with the branch moved —
and its semantic POP is that the body runs once even when the condition is initially false),
**FOR last and possibly never** (O6).

Two shared mechanisms are needed **before any loop**:
1. **Re-walk semantics.** A loop's condition is walked *once* to emit into a block that
   *executes repeatedly*. Verify nothing in the walk assumes walk-once-run-once. The per-run
   `jitData` reset is per-**run**, not per-iteration — correct, but do not "fix" it when a loop
   POP confuses someone.
2. **`jitLoopBegin`/`jitLoopBody`/`jitLoopEnd`** — the loop analog of `jitIfBegin`/`jitIfEnd`.

⚠ **The `gJitResult` discipline is a silent-failure rule and it applies to every new emitter:**
the condition's `gMethod` leaves the i1 in `gJitResult`, and the next stage must read it
**immediately, with no statement in between.** A clobber does not announce itself.

⚠ **Nesting is the one plausible re-architecture item.** Each bracketing emitter is re-entrant
only if its block bookkeeping is stack-shaped rather than global-single. `gIfEndBlocks` is
already a stack, so this looks provided for — but it is untested, and two *sequential* `if`s
already segfault, so nesting has never been reached.

## Loop `continue` / `break` / `return`
WHILE and DO bodies already handle `isBranch`/`isContinue`/`isReturn` interpretively. The
emitters need explicit continue→br-latch and break→br-exit wiring. **`isReturn` inside a jitted
loop is unresolved** — the simplest correct answer was a bail, which premise 3 supersedes, so
it now wants a function-exit block reached via the epilogue.

## The runtime surface (the later arc)

Jitted code that calls back into the runtime — GroupItem methods, print, string ops — needs ORC
symbol resolution via `absoluteSymbols`. Use `extern "C"` wrappers for anything name-mangled so
ORC symbol names are predictable. There is a 2017 precedent for the allow-list
(`OLDtawkDoNotTouch/Include/UIjit.ext`) which is GUI-vintage and partly stale but answers the
shape of the question: *what host functions may jitted code call, and with what types?*

⚠ **CORRECTED 2026-08-01 per ruling T4. `locate` and registry lookup were listed here and that
was exactly backwards** — they are the two things jitted code may **never** call. The allow-list
criterion is not an enumeration to be extended case by case, it is a test:

> **OPERATIONS ON RESOLVED THINGS — yes. RESOLUTION OF NAMES — never.**

A `locate` in emitted IR is a defect by definition. See T4 in THE TABLE ARC for the full ruling,
its inheritance argument, and the never-assertion (with its mandatory vacuity guard) that keeps
the smell from arriving silently.

**This is where premise 3's fallback column actually lands**, so O1's signature question and
this arc are the same piece of work approached from two ends.

## Reference archaeology — do not port

`OLDtawkDoNotTouch/Tokf/Emitter.twk` (2017 tok LLVM emitter) and
`OLDtawkDoNotTouch/Include/UIjit.ext`. **Plan A — incant's own ops emit IR — is the chosen
direction; porting `Emitter.twk` wholesale is the abandoned Plan B.** Under Plan A the old
emitter stops being a port target and becomes a **lookup table**: "given this op and these
operand types, call this `IRBuilder` method." Its arithmetic int/float fork, its `emitCompare`
signed/unsigned matrix and its cast conversions are exactly the content premise 3's table
needs, transplanted rather than linked.

⚠ One correction the archaeology invalidates: **incant ops no longer take `&target` by
reference** (changed ~2026-06-10), which kills the mem2reg-aliasing worry the old design
carried — no address-taken alloca. Note this interacts with O4: the aliasing worry is dead, but
so, currently, is the alloca.

---

# DEBUGGABILITY — THREE TIERS AND ONE DEADLINE

**Two problems, deliberately separated:** debugging the **emitter** (is the IR right?) and
debugging **jitted code** (the IR is valid and the answer is wrong). **Every defect found to
date has been the first kind** — which is why the instrument set below is text-shaped, and why
it has been enough so far.

## Tier 0 — exists, and is the current set
`INCANT_JIT_DUMP=1` (post-pass) · **`=2` (pre-pass — the attribution instrument)** ·
`llvm::verifyFunction` · the degrade counter (H4, presence-with-value) · the **jitLadder** with
fire-twice and negative controls.

**This set found, all by reading text:** the missing merge, the constant return, the E1
double-store, and the re-seeded loads.

## Tier 1 — cheap, and scheduled: build it with the table arc
- **FIELD-NAMED SSA VALUES.** The fresh-name primitive takes a hint: emit `%jaIn.2`, not `%7`.
  **A dump that reads as incant is self-documenting; a numbered dump is archaeology.**
- **PER-STATEMENT PROVENANCE COMMENTS** — `; stmt N: <source>` ahead of each statement's
  instructions. **Not decoration:** LLVM's IR parser reports template errors **by text line**,
  so provenance comments are how a parse error finds *the table row that emitted it*. They need
  only exist in the buffer the parser reads.
- **`jitTrace` — THE PRINT THAT SURVIVES JITTING, and it is the priority item.**
  ⚠ `opPrint` is **ungated**, so under `jitting=1` a print in the body fires at **emit time**
  (§2.2, measured). **Print-debugging a jitted action therefore reports compile-time state
  once instead of run-time state per fire — it appears to work and it lies.** `jitTrace` is an
  *emitted runtime call* — the fallback column's machinery pointed at diagnosis — that fires at
  run time, per fire, carrying field values out. Under **method-valued cells** (O2 addendum)
  trace emission becomes **table data**: toggled per-op/per-type with no recompile and no
  `tokall`. **The fallback column and `jitTrace` are the same plumbing**, so it lands when the
  call path lands.

## Tier 2 — HPDL, parked until a bug demands it
`!dbg` metadata → DWARF → ORC/GDB-JIT registration → real stepping in `lldb`. Attaches
identically to text IR (metadata is just more text). **No bug to date has needed it.** Parked,
named.

## ⚠ THE DEADLINE — THE ORACLE DIES AT CROSSOVER
The interpreter is the **differential oracle**: same action, same inputs, both paths, diff. It
is **the most powerful debugging instrument the JIT will ever have, and §0 sentences it to
death.**

**A wrong jitted answer localises by bisection only while the interpreted path exists.** After
crossover, truth comes only from fixtures written *in advance*.

**Which is why every ladder rung from J2 forward records its INTERPRETED result as a captured
fact beside its asserted value** — the ladder accumulates the oracle's testimony while the
oracle can still testify. Implemented: each rung prints an `interpreted` line and the harness
checks it against fire 1.

⚠ **And capturing it has an ORDERING CONSTRAINT that is not obvious** — see the note in
`jitLadder/ladder.sh`: the oracle call must come **after** the jitted fires, because calling an
action interpreted first consumes its `isCoded` state and `testing()` then silently routes to
`jitRunIfTest` (a hand-built smoke scaffold) instead of `jitRunAction`. Found the first time a
rung tried to capture the oracle, 2026-07-31.

## Tier 1's honest gap, stated rather than discovered later
`jitTrace` is gated behind **call emission**, which does not exist — the same prerequisite J-R
named. **So the loop rungs J3/J4 arrive before the print-replacement does.** That gap is
survivable: loops are counter arithmetic and `DUMP=2` covers them. But **the
difficult-action debugging story starts when the call path lands**, which is one more reason
that path sits early in the post-loop order.

---

# PART V — DEFERRED, AND NAMED SO IT DOES NOT CREEP

- **`modedOP.boundTo` interaction with jitted dispatch** — pending that design pass.
- **Stack allocation of frames.** BDWGC heap is correct now; stack is the optimisation *earned*
  by a later non-escape analysis. ⚠ **It is not a free choice — it is determined by whether a
  `:=` pointer-to-slot can escape its frame.** If it can, stack allocation dangles on frame pop.
  Answer "can byRef escape a frame?" and allocation follows.
- **Recompile on structural edit.** The compiled entry point assumes fixed structure. The
  action wrapper — carrying both the inspectable GroupItem and the entry-point pointer — is the
  deliberate seam where invalidate-and-recompile attaches. Coupled to schema closure.
- **Type specialization / hot-path tightening.**
- **`switch`** — **DROPPED, not deferred.** No `aCTionSwitch` exists; the `switch(){}` in the
  class files is native TAWK compiling straight to C++. Host control flow, never in the
  interpret/jit system. Nothing to defer.
- **Performance.** No jitted-vs-interpreted timing has ever been taken, and under §0 it is not
  the point.

---

# PART VI — WHAT TO BUILD NEXT, AND WHY IN THIS ORDER

Not a schedule — an argument about dependency, for whoever sets the schedule.

1. **Settle O4 (allocas vs baked addresses).** Everything in Part III and the "never write a
   phi" position depends on it, and the missing return-value merge is already a symptom.
2. **`jitEmitGIF`'s else arm.** It is the only *wrong answer at exit 0* in the JIT, and wrong
   with a clean exit outranks every crash.
3. **The unary seed gap.** Cheap, three POPs prove it, and it unblocks fixture capture — but
   it moves no frontier, so do not schedule it as progress.
4. **O5 (`jitData` reuse).** Blocks loops and multi-statement bodies, i.e. everything past
   Phase 1. The IR dump can settle its inferred cause in one run and has not been used for it.
5. **The crossover ruling** (`jit.md` §0 Consequence 2). Now rulable: the boundary is
   enumerated, the primitive exists (`jitDegrade`), and premise 3 has already decided the
   *mechanism* — a per-op emitted call, not a whole-action bail. What remains is Tony's call on
   whether an un-emittable construct refuses loudly, degrades loudly, or aborts the compile.
6. **Then** the table (O1/O2/O3), which is the thing this design pass was called for and which
   the four above keep honest.

---

*Consolidated 2026-07-31. Premises 1-3 are Fearless's, stated as invariants. Contradictions
found during consolidation are in `ipc/clod-to-clay.md` SEQ 37, not silently reconciled.*
