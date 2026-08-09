# `AND` / `OR` — the ruling, and the drawer-ready rung

**Status:** ⚠ **RULED, NOT BUILT.** Ruling by Tony, 2026-08-09. Spec settled in the Clay↔Tony
thread the same day and **transcribed here** — scheduling is post-First-Light natural, earlier
permitted, **Clod's clock**.

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

## 3. THE RUNG — drawer-ready, six parts

1. **Interceptor handlers, per the `if` precedent.** The existing gate shape; nothing new invented.
2. **Emitter diamond, carrying E2's lessons.** Value rides the **operand's `jitValue` channel**
   (⚠ *not* `gJitResult` — that conflation silently un-jitted every if/else and is the
   one-channel-one-meaning ledger's second row). **No phi** — fields are memory, and the merge is
   the memory location. **Parent-once** — re-inserting an already-parented block surfaced as
   *"pointer being freed was not allocated"* inside `~Function()` at module teardown, with a
   backtrace naming `LLJIT::lookup` and nothing of ours.
3. ⚠ **PRE-FLIGHT CENSUS OF RIGHT-ARM SIDE EFFECTS IN THE EXISTING CORPUS.** Short-circuit is a
   **behaviour change to shipping text**: any `a AND b` whose right arm has a side effect changes
   meaning the day this lands. **Grep before, then migrate or certify-clean in the SAME commit.**
   ⚠ **H9 applies to that census** — match the idiom family, not the surface form, and with a
   population this small **read the hits by eye before reporting the number.**
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
