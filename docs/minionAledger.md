# Minion A — the round ledger

*Foreman's. **Not an input to the loop** — see `docs/minionAHarness.md` §1, Leak 3: the
agent's inputs are the corpus, the brief, and its rung target, and nothing else. This file
is exempt because it is never handed to a round, not because it is harmless.*

---

## THE SERIES

Round 1 is the **baseline**, not a data point — there is no fall to measure from nothing.
Its corrections will be high, and that is the instrument zeroing. **A low round-1 number
is a reason to stop and look, never a reason to proceed pleased** (harness §3, three
candidates, pre-registered before any round ran).

A **brief revision breaks the series.** Correction counts do not compare across a break.

| round | method | corrections | claims drafted | claims defeated | regression | series |
|---|---|---|---|---|---|---|
| — | *none yet* | — | — | — | — | — |

**Corrections** = distinct critique points Tony or foreman raised. Each one cites the
claim ID it defeats, or `NEW`.

**Claims defeated** is the instrument, not the count. Reading (harness §2):

| round N+1 | reading | action |
|---|---|---|
| repeats an error round N's claim should have prevented | the **claim** is badly written | rewrite the claim, not the code |
| makes a NEW error | normal | that is the next claim |
| makes no error | absorption | record it |

And the corollary: **if round N+1 needed something round N knew, that event is the
finding** — log it in the round note below even when nothing broke.

---

## BRIEF REVISIONS — logged, with reason, series broken

| when | what changed | why the brief was DEFECTIVE | series restarts at |
|---|---|---|---|
| — | *none* | — | — |

Revision is permitted **only** for defect, never to carry forward what a round taught.
A round-1 corpus-format failure is the anticipated legitimate case
(`docs/mdReorgB0.md` §6 — proof by use; if a real claim won't fit the fields, the format
is wrong and moves, and whoever moves it accounts for the move).

---

## ROUND NOTES

*One short entry per round: what the round hit, what the corpus failed to carry, and
anything that reads as a leak. Leaks first — a suspected leak invalidates the round's
number before anything else is worth discussing.*

*(empty — A has not fired)*

---

## STANDING CHECKS BEFORE EACH SPAWN

- [ ] fresh agent; inputs are **corpus + brief + rung target** only
- [ ] brief unchanged since last round (or the revision is logged above and the series broken)
- [ ] corpus is the only writable surface besides the method
- [ ] previous rounds' targets currently green (run the regression surface *before* spawning,
      so a pre-existing break is not attributed to the new round)
- [ ] foreman holds the build; agent has not been asked to `xcodebuild` or `tokall`
