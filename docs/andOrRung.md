# `AND` / `OR` — the ruling, and the drawer-ready rung

**Status:** ⚠ **RULED, NOT BUILT — five parts remain, part 3 is DISCHARGED.** Ruling by Tony,
2026-08-09. Spec settled in the Clay↔Tony thread the same day and **transcribed here**.

**SCHEDULING — Clod's read, 2026-08-09, after measuring:** post-First-Light as ruled, and
**immediately after rather than later**. Nothing on the path to First Light needs it — the parse
templates short-circuit *by construction* precisely because AND was unavailable, so there is no
forcing function. The `a OR b` silent-wrong-at-exit-0 is the project's most dangerous defect class
but has **one non-fixture use** (part 3), so urgency is low. **The real argument is adjacency:**
this rung wants the interception/registration surface, and so do H3's command registrations and
rung 2 — running them concurrently entangles blast radii, while running AND/OR *after* the parse
arc means that surface has been exercised once and the OR collapse lands with a consumer waiting.
**Queue:** bracket fix → H4's run → H3's registrations → rung 2 (Family A) → install arc →
First Light → **this rung** → the alternation respell.

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
2. **Emitter diamond, carrying E2's lessons.** Value rides the **operand's `jitValue` channel**
   (⚠ *not* `gJitResult` — that conflation silently un-jitted every if/else and is the
   one-channel-one-meaning ledger's second row). **No phi** — fields are memory, and the merge is
   the memory location. **Parent-once** — re-inserting an already-parented block surfaced as
   *"pointer being freed was not allocated"* inside `~Function()` at module teardown, with a
   backtrace naming `LLJIT::lookup` and nothing of ours.
3. ✅ **PRE-FLIGHT CENSUS — RUN 2026-08-09, AND THE RISK MEASURES NEAR ZERO.** Short-circuit is a
   **behaviour change to shipping text**: any `a AND b` whose right arm has a side effect changes
   meaning the day this lands. Censused across `incant/`, `*.rtn`, `XML/`, `IncantForms/`:
   ```
     surface-form matches (the word AND/OR)          165
     genuine OPERATOR uses, read by eye                7
        incant/orProbe          x3   fixture ABOUT OR
        incant/jitXor           x1   fixture documenting the defect
        incant/jitXand/jitXand2 x2   fixtures documenting the 139
        incant/scopeUnits:168   x1   `if !righty OR feeling;`  <- the ONE real use
     right arms carrying a SIDE EFFECT                 0
   ```
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
- ⚠ **SEQUENCE KEEPS ITS ENTRY-SAVE / TAIL-RESTORE EPILOGUE. The `AND` collapse alone does not
  satisfy the contract.** Short-circuit stops the *evaluation*; it does not give back what the
  arms that DID run consumed. Those are different facts and only one of them is an operator's job.
- ⚠ **The alternation collapse inherits §2's literal caveat unchanged** — a bare chain is correct
  only while every alternative is a rule reference. A **literal** alternative does not self-restore
  (`lit` commits its skip pass before matching), and no `OR` semantics fixes that, because it is a
  property of the operand rather than of the operator.

## 5. NOT DONE, AND WHY

**Nothing here is built.** Parked deliberately at the 2026-08-09 seal: part 3 is a **behaviour
change to shipping text**, which is the loudest reason on the list to start it at the top of a
session rather than the bottom of one — *match the task's failure loudness to the seat's
mechanical state*. The rung is specced so that starting it costs no archaeology.
