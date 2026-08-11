# `AND` / `OR` — the ruling, and the drawer-ready rung

**Status:** ✅ **BUILT AND GREEN, 2026-08-11.** All six parts discharged. Ladder **184 / exit 0**
(was 173 with two inverted rows); `jitXand`/`jitXand2`/`jitXor` all correct on both fires at
degrade 0; short-circuit certified by **tick count** with a recorded negative control.
Original ruling by Tony 2026-08-09; the **truthiness amendment** (§3 part 1) and the **seat**
(`interpretXP`, not `runOP`) are Tony's, 2026-08-11.

**WHAT LANDED, by part:**

| part | state |
|---|---|
| 1 interceptor handlers | ✅ `runShortCircuit` (`GroupActions.rtn`), bound at **tree build** by `interpretXP`; `truthOf` (`Instruct.rtn`) is the single contract; `opAND`/`opOR` rewritten to 1/0 |
| 2 emitter diamond | ✅ `jitEmitShortCircuit` + `jitScBegin`/`jitScEnd` (`jitEmitters.rtn`), entry-block alloca, **no hand-written phi**, result seeded onto the node's `jitData` |
| 3 pre-flight census | ✅ discharged 08-09, **re-measured and corrected 08-11** — see below |
| 4 `jitXand`/`jitXand2` flip | ✅ graduated per H6, re-pin sentences at the head of the ladder's JXD block |
| 5 `CLAIM KANT-34` retirement note | ✅ dated note added, claim not rewritten |
| 6 H7 negative control | ✅ **run and recorded** — mechanism removed ⇒ tick rows red, **value and degrade rows stayed green** |

⚠ **THE SEAT MOVED, AND THE REASONING IS REUSABLE.** The first build gated AND/OR at the top of
`runOP`. Tony's ruling moved it to `interpretXP`'s tree build. `TokenXP` — the natural guess, since
it is where unaries are handled — **cannot** work for a binary: `TokenXP UnaryOPS? ANYorNum^
InvokeArg?` *groups* a unary with its operand, so the pairing is a parse fact, whereas
`ExpressioN Token+` is a **flat sequence** in which `AND` has no arms and no precedence yet. The
binary structure first exists in `interpretXP`, which is therefore where the **category** decision
belongs — paid once per expression, and leaving `runOP` what §6 calls it: the strict dispatcher and
nothing else.

⚠ **AND A FINDING THAT OUTLIVES THE RUNG: THE PROMOTION ALONE MADE THINGS WORSE, MEASURABLY.**
On the intermediate build — interpreted arm promoted, no emitter — the `AND`-under-jit **139
disappeared and was replaced by the silent wrong answer** (`jitXand2` and `jitXor` both wanted 1 on
fire 2 and returned 0, **at degrade count 0**). Trading a loud crash for §2's *"dangerous one"* is a
**regression in loudness wearing the shape of progress**, and it was visible only because the two
inverted JXD rows were watched across both builds. This is why `runShortCircuit`'s `jitting` gate
is a **refusal** rather than a fall-through.

⚠ **STILL UNRULED, so nothing here reads as finished that is not: the SYMBOL forms.** `OR`
short-circuits; `||` does not, **on the same handler**. `&&` is worse — it answers `true && true`
as **false**, because `'&'` is registered *bare* at `incant/setup:162` with no `operateMethod`,
exactly the state `'|'` was in before 2026-08-01. Both filed in `docs/knownErrors.md`; **widening
tier 3 to the symbols is a ruling, not a rung.**

⚠ **SCHEDULING — TONY'S PREFERENCE, 2026-08-09, AND IT SUPERSEDES CLOD'S READ: BEFORE
genKantParse, not after.** Stated as a preference and not an order, and taken.

**His reason, which is the better one: it changes and simplifies the parse code we will be
generating.** The step-1 artifact is meant to **freeze as the step-4 byte-oracle**. If ALTERNATION
collapses to a bare `OR` chain once this rung lands, then freezing first means freezing a shape
that is about to move — an oracle that needs re-pinning, an install built on the superseded
spelling, and generated text produced twice. **Ordering AND/OR first means genKantParse emits the
final shape the first time.**

⚠ **AND CLOD'S ARGUMENT FOR THE OTHER ORDER DID NOT SUPPORT ITS CONCLUSION, recorded because the
reasoning error is the reusable part.** It ran: *this rung wants the interception/registration
surface, and so do H3's registrations and rung 2, so running them concurrently entangles blast
radii.* True — and an argument against **concurrency**, which nobody proposed. It says nothing
about which of two **sequential** orderings is better. A valid objection was used to defend a
position it was silent on.

**Queue as it now stands:** bracket fix (still first, perishable junction) → **this rung** →
H4's run + H3's registrations → rung 2 (Family A) → install arc → First Light. The alternation
template is then written once, already collapsed.

⚠ **THIS FILE EXISTS BECAUSE THE RULING WAS MADE IN CHAT.** That is the decoder's diagnosis and
T-0's cost arriving on the same day both were written down: a ruling whose only home is a thread
is an unmeasured citation waiting to be made. Transcribed against the dictating text; **if the
thread and this file disagree, the thread wins and this file is corrected.**

---

## 1. THE RULING

**`AND` and `OR` take C++ semantics.**

- They **return 1 or 0, always** — never an operand, never a node.
- **Both engines byte-agree** — interpreted and jitted give the same answer.
- **They short-circuit.** `AND` stops on the first false, `OR` on the first true. **The unreached
  arm is never evaluated — side effects included.**

This was **the last open ruling on the promotion.**

## 1a. ⚠ WHAT THE RULING ACTUALLY COSTS — measured 2026-08-09, and it is not where the spec assumed

**SHORT-CIRCUIT CANNOT LIVE IN AN OPERATOR HANDLER.** `runOP` evaluates both operands *before* it
dispatches, so by the time `opAND`/`opOR` are entered, the right arm has already run — side
effects included. Declining to evaluate is not available at that position **at all**.

```cpp
extern GroupItem opAND(GroupItem argument, GroupItem target)
{   if gCount && argument.gCount    return trueResult;
    return null; }                                          // Instruct.rtn:18

extern GroupItem opOR(GroupItem argument, GroupItem target)
{   if target
        if gCount   return trueResult;
        or argument && argument.gCount  return trueResult;
    return falseResult; }                                   // Instruct.rtn:595
```

**So "interceptor handlers per the `if` precedent" is the whole job, not a styling note.** AND/OR
must be **promoted from operators to intercepting rule actions** — they are registered today as
`AND operateMethod=opAND;` / `OR operateMethod=opOR;` (`incant/setup:114,117`), the two-arg
isOperator arm — and the promotion lands in **BOTH engines**, not just the JIT.
**The category the promotion moves them INTO is named in §6** — tier 3, evaluation-controlling
constructs, which are not operators at all.

⚠ **AND THE REASSURING HALF: THE INTERPRETED ARM DOES NOT MEET THE RULING TODAY EITHER.** `opAND`
returns `trueResult` **or `null`**; `opOR` returns `trueResult`/`falseResult`. Neither returns
1/0, and **they are not even consistent with each other** — `null` is "no node", `falseResult` is
"the value 0". So this rung is not changing behaviour anyone could have relied on; it is bringing
an arm up to a rule it never satisfied.

**Difficulty, honestly: MEDIUM AND FRONT-LOADED.** The novel work is the category change plus
interception in the interpreter. The JIT diamond is **already-solved machinery** — the
`resultSlotLanded` pattern: an alloca, each arm storing in its own block, the exit loading, and
**mem2reg inserting the phi itself**. Never-write-a-phi, already proven. Corpus migration:
measured nil (part 3).

## 2. WHY IT MATTERS BEYOND TIDINESS

The current state is measured and bad in two distinct ways (`incant/jitXand2`, `incant/jitXor`,
2026-08-08):

| spelling | today |
|---|---|
| `a AND b` | **exit 139**, and **no degrade line** — it crashes before the counter sees it |
| `a OR b` | **exit 0, degrade 0, SILENTLY WRONG** — fire 2 wants 1 and gets 0, the emit-time value folded |

The second is the dangerous one and it is the reason this is a promotion rather than a cleanup: a
wrong answer at exit 0 with a clean degrade counter is the shape that survives review.

⚠ **AND THE PARSE CONNECTION, WHICH IS WHY THE RULE READS THE WAY IT DOES.** A parse term
**consumes input**. A right arm that runs after a failed left arm advances the mark past text the
rule never matched — so for parse work, short-circuit is not an optimisation, it is correctness.
`incant/jitXtemplate` exists precisely because that could not be expressed with `AND` today, and
short-circuits by construction instead (`CLAIM KANT-34`).

## 3. THE RUNG — six parts, ONE DISCHARGED (part 3), five remaining

1. **Interceptor handlers, per the `if` precedent.** The existing gate shape; nothing new invented.

   ⚠ **OPERAND TRUTHINESS — NORMATIVE FOR BOTH ENGINES. AMENDED 2026-08-11 (Tony, carried by
   Clay, SEQ 32) AFTER THE ORIGINAL TABLE WAS MEASURED AGAINST THE TREE AND FOUND TO CONTRADICT
   IT.** The interceptors accept mixed operand types and test truth per this table, identically in
   both engines. **It is LAYERED: presence decides only when no value exists to decide by.**

   | # | operand | truth |
   |---|---|---|
   | 1 | absent / null | **false** |
   | 2 | node holding a **numeric value** | **BY ITS VALUE** — 0 false, nonzero true. **Comparison results live here, always.** |
   | 3 | node holding **no numeric value** | **true by presence** — the parse-consumer row: `parseR`'s GroupItem-or-null, structural nodes, rule results |
   | 4 | **text-valued operand** | ⚠ **DELIBERATELY UNRULED** — see the fence below |

   Pinned because the parse consumer chains mix **kant** methods (1/0 per the contract) with
   `parseR` results (**GroupItem or null** — §4 H3(a) of `docs/attributesTemplate.md`), and because
   **the pre-rung handlers disagreed with each other**: `opAND` failed with `null`, `opOR` with
   `falseResult`. **Neither was the rule; this table is.**

   > ⚠ **WHAT THE ORIGINAL MIDDLE ROW SAID, AND WHY IT COULD NOT STAND.** It read *"present node,
   > any contents — **including a node holding 0** — true"*, with the gloss *"presence, not
   > contents, for nodes; value for scalars."* The doc flagged it as **"the one that would bite
   > silently"** and it was right — it just bit in the opposite direction from the one expected.
   >
   > **Measured 2026-08-11 before any code was written:** a field holding 0 dumps as
   > `aFalse=0 int` — it carries `isCOUNT` and `gCount` 0, so it is *both* "a present node holding
   > 0" *and* "a scalar", and the two halves of the old gloss give opposite answers on the same
   > operand. Applied literally, row 2-as-written would have flipped `orProbe`'s `false OR false`
   > and both of `andProbe`'s false rows from false to **TRUE**, and made
   > `goodToGo = x > px AND x < pxw` always-true in `incant/utilities`.
   >
   > **Tony's ruling, and the reason it is FORCED rather than preferred:** under a flat
   > "any present node is true", **a comparison returning 0 is true and every conditional over a
   > value-bearing expression is always-true. That is not a semantics, it is the abolition of
   > falsehood.** The table had been written in the *parse* frame, where null-vs-node IS the whole
   > discrimination; rows 1–3 preserve that purpose without eating the value world.
   >
   > **The fixtures were the instrument and they cost one run each.** This is the citation-sweep
   > charter's freshest exhibit at the *table* level rather than the number level.

   ⚠ **ROW 4 IS FENCED, NOT FORGOTTEN.** Text-valued truthiness has **no measured customer**, it
   borders **KE-4**'s territory, and ruling it now would be spec without a customer. **A text
   operand is REFUSED at emit** — `jitEmitShortCircuit` calls `jitDegrade` rather than substituting
   a constant — and answers row 3 at run time. Since a refused emit falls back to interpretation,
   the two arms **agree in outcome**: this is one answer and a refusal to bake it, not two answers.

   ⚠ **AND A DISAGREEMENT THIS TABLE DOES *NOT* CLOSE, measured the same day and recorded so
   nobody reads the rung as having closed it: `if <field>` and `<field> AND …` ALREADY ANSWER
   DIFFERENTLY, and did so before the rung.** `if aFalse;` reads **TRUE** on a field holding 0
   (bare tests go by presence) while `aFalse AND aTrue` reads **false**. This contract governs
   **the operator**, which is the thing it was written for. Closing the gap is a separate ruling
   with its own customer. Instrument: `incant/andProbe` §1 and §5.
2. **Emitter diamond, carrying E2's lessons.** Value rides the **operand's `jitValue` channel**
   (⚠ *not* `gJitResult` — that conflation silently un-jitted every if/else and is the
   one-channel-one-meaning ledger's second row). **No phi** — fields are memory, and the merge is
   the memory location. **Parent-once** — re-inserting an already-parented block surfaced as
   *"pointer being freed was not allocated"* inside `~Function()` at module teardown, with a
   backtrace naming `LLJIT::lookup` and nothing of ours.
3. ✅ **PRE-FLIGHT CENSUS — RUN 2026-08-09, RE-MEASURED 2026-08-11. THE CONCLUSION STANDS; THE
   NUMBERS AND THE FILE SET DO NOT.** Short-circuit is a **behaviour change to shipping text**: any
   `a AND b` whose right arm has a side effect changes meaning the day this lands. Censused across
   `incant/`, `*.rtn`, `XML/`, `IncantForms/`:

   ~~surface-form matches 165 · genuine OPERATOR uses 7 (orProbe ×3, jitXor ×1, jitXand/jitXand2
   ×2, scopeUnits:168 ×1 — "the ONE real use") · right arms with a SIDE EFFECT 0~~

   **Struck 2026-08-11. The re-measurement, by eye per H9:**
   ```
     surface-form matches (the word AND/OR)         294   (was 165)
     genuine OPERATOR uses                          ~30   (was 7)
        incant/utilities        x6   ⚠ MISSED ENTIRELY BY THE 08-09 PASS
                                     4 AND in displayIfVisible (assignment position)
                                     `if !length OR grup IN listed`   in listRules
                                     `if across > 0 OR down > 0`
        incant/orProbe          x3   fixture ABOUT OR
        incant/jitXand/jitXand2 x3   fixtures, now the rung's certifying rows
        incant/jitXor           x1   fixture documenting the defect
        incant/scopeUnits:168   x1   `if !righty OR feeling;`
        incant/unitTests:151    x1   the same testOR, duplicated
        XML/BackupXML + IncantForms/BackupXML   x12   gitignored archaeology
        IncantForms/WorkingOn/incant++          x1    Tony's own WIP
        XML/Notions/current + IncantForms/…     x2    inside a PROSE "Problems"
                                                      block, not live code
     right arms carrying a SIDE EFFECT                0   ⚠ HOLDS under the wider net
   ```
   **REACHABILITY, measured rather than assumed:** `displayIfVisible` is **defined and never
   called** — its four assignment-position `AND`s are latent. **`listRules` IS live** (called from
   `incant/jitAttrPop:109` and recursively at `utilities:112`).

   ⚠ **THE MISS THAT MATTERS: `incant/utilities` was inside the census's own scope and is
   `include`d by every fixture preamble in the tree.** The conclusion survives because the
   side-effect count held at 0 under the wider net — but *"certify-clean"* was reached on a search
   that had never looked at the most load-bearing file in its own population. **H9 one more time,
   on the census in the paragraph directly below the rule about censuses.** Flagged to the
   citation-sweep charter as its freshest exhibit.

   ⚠ **AND ONE CONSEQUENCE THE ORIGINAL CENSUS COULD NOT HAVE SEEN, because it was measuring the
   wrong risk:** the census asked only about *side effects*. The **return-value** change bites too
   — a false conjunction used to yield a node with no data (which a bare `if` reads as false) and
   now yields a node holding 0 (which a bare `if` reads as **true**). `andProbe` §4 records this as
   a **pre-registered prediction that FAILED**. `displayIfVisible` is the only shipping consumer of
   that shape and it is uncalled, so nothing live moved.
   ⚠ **H9 EARNED ITS KEEP HERE: 165 vs 7.** The surface form matches the English words in every
   comment block in the tree, and reporting 165 would have made this look like a migration.
   **Read by eye, per the rule, because the population was small enough to.**
   **Consequence: nothing to migrate.** Six of the seven uses sit in **four fixture files** that
   are the rung's own subjects (and `jitXand`/`jitXand2` flip under part 4); the seventh,
   `scopeUnits:168`, is a plain field read. **Certify-clean, no migration commit.**
   ⚠ **A FIRST DRAFT OF THIS PARAGRAPH SAID "the five fixtures" — SIX USES ACROSS FOUR FILES,
   miscounted two ways at once, in a census, one paragraph below the rule about censuses.
   Corrected the same day. H9 is about the instrument, and the instrument includes the arithmetic
   after the grep.**
4. **`jitXand` / `jitXand2` flip from documenting-the-139 to certifying.** Two fixtures whose
   present job is to record a defect become the rung's positive rows. **H6 graduation: each gets
   its re-pin sentence.**
5. **`CLAIM KANT-34`'s both-arms line gets a DATED RETIREMENT NOTE — not deletion.** Same
   legibility rule as everywhere: the claim records what was true and why, and rewriting it
   falsifies the record.
6. ⚠ **H7 negative control, and it must discriminate.** The short-circuit half needs a **tick
   count**, not a value: a right arm that runs anyway still produces the right *answer* in most
   shapes, so only counting proves it was skipped. `jitXtemplate`'s `xtTicks` is the worked
   example — fire 1 ticks 1 (term 2 never ran), fire 2 ticks 3.

## 4. THE CONSUMER RUNG, AFTERWARD

The parse-template respell (`docs/attributesTemplate.md`):

- **ALTERNATION → a bare `OR` chain.** With C++ semantics and real short-circuit, the
  first-match-wins chain collapses to one expression.
- ⚠ **SEQUENCE does NOT collapse to an `AND` chain.** The if-chain SEQUENCE is **JXT — green,
  jitted, degrade 0** — and an `AND`-chain respell would need **its own certification rung** to buy
  brevity that *generated* text does not need. **Freeze-once compels movement only where the shape
  is expected to be superseded, and only ALTERNATION carries that banner.** SEQUENCE's certified
  spelling is **final** for the step-4 oracle.
- ⚠ **SEQUENCE KEEPS ITS ENTRY-SAVE / TAIL-RESTORE EPILOGUE. The `AND` collapse alone does not
  satisfy the contract.** Short-circuit stops the *evaluation*; it does not give back what the
  arms that DID run consumed. Those are different facts and only one of them is an operator's job.
- ⚠ **The alternation collapse inherits §2's literal caveat unchanged** — a bare chain is correct
  only while every alternative is a rule reference. A **literal** alternative does not self-restore
  (`lit` commits its skip pass before matching), and no `OR` semantics fixes that, because it is a
  property of the operand rather than of the operator.

## 5. ~~NOT DONE, AND WHY~~ — BUILT 2026-08-11. WHAT THE PARKING BOUGHT.

~~**Nothing here is built.** Parked deliberately at the 2026-08-09 seal…~~

The parking rationale was: short-circuit is a **behaviour change to shipping text**, which is the
loudest reason on the list to start it at the **top** of a session — *match the task's failure
loudness to the seat's mechanical state*. **It was started at the top of 2026-08-11 and it paid
for itself in the first hour**, before a line was written: the pre-flight re-measurement caught a
normative table that contradicted the tree, and the corrected census caught a missed file. Both
are the kind of finding that is cheap at the top of a session and expensive at the bottom.

**And the claim that the rung would cost no archaeology held** — the only recon needed was the
grammar (to rule out `TokenXP`) and `jitEmitGIF`/`jitEmitRem` as emitter precedents.

## 6. DOCTRINE — THE `runOP` TIERS, AND THE PHASE RULE

Ruled in the Clay↔Tony thread, 2026-08-10; **this file is the transcription — the thread wins on
disagreement**, same standing as §0's note.

**`runOP` is the interpreter's strict-operator dispatcher and nothing else.** The emitter reads
**the same registration table** at emit time and **never calls `runOP`.** Three tiers:

| tier | what | how it is emitted | how agreement is bought |
|---|---|---|---|
| **1** | **hot scalar operators** | inlined IR | **by measured rung** |
| **2** | **strict long-tail operators** | emitted **direct call to the shared C++ handler** | **by construction** |
| **3** | **evaluation-controlling constructs** — *not operators* | **interceptor + diamond** | **by measurement, tick-discriminated** (part 6) |

**Tier 3 stays small: `if`, `AND`/`OR`, iteration — then the door closes.**

⚠ **THE PHASE RULE: emit time never enters a runtime handler for its value; run time never enters
an emitter.** §2's `OR` silent-wrong is the **first violation** — the handler ran at emit and the
value folded. The parked **`jitEmitUnary`←`opPlusPlus` 139** carries the **inverse** signature in
its backtrace (a runtime handler entering an emitter); that parking note is cross-referenced to
this rule as its **likely diagnosis frame**. **The 139 stays parked — adjacency is not scope.**

⚠ **TIER-2 CAVEAT, UNMEASURED:** tier 2 assumes the **GroupItem-in / GroupItem-out** boundary holds
for handlers **called from IR with no `runOP`-established interpreter state around them.** Not
owed now, named so it is owed then: **the probe is Clod-sized when tier 2 is first exercised — one
cold operator, emitted direct call, fire twice.**
