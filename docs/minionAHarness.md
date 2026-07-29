# Minion A — the harness

*Foreman's spec. Ruled by SEQ 30c (Clay, via Tony, 2026-07-29) with Clod's
per-round-spawn correction folded in. **A fires when this is harnessed** — this file
is the gate.*

A converts C++ methods to kant, one method per round, and the **deliverable is the
critique, not the corrected code**. The corpus of kant idiom is what A is actually
building; the converted methods are its exhaust.

---

## 0. THE ONE-LINE VERSION

**Amnesia is a property of how rounds are SPAWNED, not of who wears the hat.** A single
long-lived agent reproduces the confound exactly, minus project orientation — strictly
worse than a foreman doing it by hand. Everything below exists to keep the amnesia real.

---

## 1. THE THREE LEAK PATHS — one rule each, any one open and the metric is theatre

### Leak 1 — AGENT CONTEXT. Fresh spawn per round.
**A round is ONE method.** Inputs: **the corpus, the brief, the rung target.** Nothing
else. Round N does not inherit round N−1's context.

**Within** a round, continuity is allowed and necessary — Tony cannot critique an agent
that does not remember what it wrote. The boundary is where amnesia bites:

> **THE ROUND ENDS WHEN ITS CLAIM IS WRITTEN AND ITS TARGET IS GREEN.**

### Leak 2 — THE BRIEF. Frozen, one slot.
The brief is a template with exactly one variable: **which method**. If foreman patches
round N+1's brief with what round N taught, **the brief is carrying the learning and the
corpus is being bypassed** — the same confound in a different vessel.

> Anything learned goes in the corpus or it goes nowhere.

**Revision is permitted only when the brief is DEFECTIVE** (round 1's format test is
exactly this case). It is logged with a reason and **it BREAKS THE SERIES** — correction
comparisons restart from that round.

### Leak 3 — THE TREE. The corpus is the only surface the loop may write to.
Igor reads the repo, so all of `docs/` is an **input**. Write a round-learning into any
doc that is not the corpus and round N+1 picks it up anyway — the corpus looks like it is
absorbing while the filesystem does the work. **The confound laundered through disk.**

> If it must be written down, it is a claim.

Foreman's own notes, the ledger, and the log are exempt **only because they are not read
by the loop** — enforced by Leak 1's input list, not by good intentions.

---

## 2. THE METRIC — claim survival, not corrections-per-method

Corrections-per-method is the **aggregate**, not the instrument: it cannot separate
*"the corpus is absorbing"* from *"the methods got easier."* Claim survival can, and it
is per-claim and directly checkable.

| what round N+1 does | reading | action |
|---|---|---|
| repeats an error that round N's claim should have prevented | **the claim is badly written** | rewrite **the claim**, not the code. This is the finding. |
| makes a NEW error | normal | that is the next claim |
| makes no error | absorption | record it |

**The corollary, same instrument from the other end:** if round N+1 *needs* something
round N knew, **that event is the finding**. Under a long-lived agent it is invisible —
it just works, and nothing gets written.

Mechanical requirement: a correction must cite the claim ID it defeats, or `NEW` if none
applies. Without that the first row cannot be distinguished from the second.

### Difficulty is controlled — and it was luck, not design
The cadence is **table → string assembly → control flow**, chosen for review value. It is
also **increasing difficulty**, so falling corrections against a *rising* floor is a
stronger signal than it would be in any other order. **Do not reorder for convenience
without stating what it costs the measurement.**

### Round 1 is the BASELINE, not a data point
There is no fall to measure from nothing. Its corrections will be high, and that is the
instrument zeroing.

---

## 3. PRE-REGISTERED — what round 1's number means, decided BEFORE it runs

*Tony's flag, 2026-07-29, and it is the sharpest line in the exchange. Recorded here
rather than as a note because deciding what a number means after seeing it is the exact
failure this harness exists to prevent.*

> **If round 1's corrections come back LOW, that is NOT success.**

Three candidates, and they are discriminable — check in this order:

| candidate | check | verdict |
|---|---|---|
| **(a) leak** | walk §1's three rules. Did the agent see anything outside {corpus, brief, target}? | invalidate the round, close the leak, re-run |
| **(b) method too easy** | does the method exercise any construct with no prior claim? If every construct it touched was already trivial, there was nothing to be corrected **about** | re-pick the method; not diagnostic |
| **(c) thin method / low ambition** | *Clod's addition.* A fresh agent told "the critique is the deliverable" has a standing incentive to write **less**. Few corrections then means small surface, not absorption | see mitigation below |

**(c) is the most likely one in practice and it is already mitigated:** the round is not
green until the method **reproduces its rung target byte-for-byte**. The target pins
ambition — the agent cannot shrink the surface without failing the gate. If (c) ever
fires anyway, the defect is a target that under-specifies, and that is foreman's.

**The instrument only works if the baseline is genuinely expensive.** A cheap round 1 is
a reason to stop and look, never a reason to proceed pleased.

---

## 4. THE REGRESSION SURFACE — A's census

*Clod's own point, transferred by Clay: the least carryable thing is a **discipline** —
positive tests only, loud refusal over quiet skip — and it erodes under pressure to make
a rung green **because the erosion looks like progress**. In genParse that is caught by
the census, which watches the rules nobody is working on. A has the same exposure and no
such instrument.*

The rung target tests **the method being written**. Nothing tests the methods **not**
being written — so round 4 fixing its own method by breaking a shared helper reads green.

> **Every previously-converted method reproduces its target, EVERY round.**

Cheap: the fixtures already exist, one diff each. And the spawn rule makes it *more*
necessary, not less — a fresh agent has no memory of the earlier methods, so it is more
likely to break one. **The instrument is needed precisely because the spawn rule is in
force.**

Run by **foreman**, after the agent reports green, before anything reaches Tony.

---

## 5. ROLES AND THE GATE

| | owns |
|---|---|
| **Igor (the agent)** | one method per round. Drafts its claim and its BLOCKED records. Runs `tok`, `sh genLadder/pop.sh`, `sh genLadder/tree.sh`, and its own target diff. |
| **Clod (foreman)** | the harness, the fixtures, the frozen brief, the ipc, the regression surface, **the build**, and the gate. Gates claims. Never patches the brief with learning. |
| **Tony** | rules on style and closes claims. Should never spend a review on something a fixture would have caught. |
| **Clay** | design and reasoning. Briefs A's shape. |

### Who writes the claim
**The agent drafts it, foreman gates it, Tony rules on style.** A claim cannot be
validated by whoever wrote it — the gap named for round-1 seeding applies to **every**
round. **The next round is the test.**

### The gate, before anything reaches Tony
1. it toks clean
2. it reproduces its rung target **byte-for-byte**
3. the regression surface is green (§4)
4. it has been checked against **every idiom claim already on the books**
5. exit status checked, not output grepped — *a POP is not passed unless the process
   exited 0*

### The build carve-out — shared state, not capability
Igor toks, POPs, and diffs. **Foreman builds and holds `groups.ext`.** Not a capability
limit: `xcodebuild` targets one workspace containing **Tony's uncommitted Group-A work**,
`groups.ext` lives outside the repo with no commit trail, and `tokall` is currently
forbidden. Worktree isolation does **not** save you — DerivedData and `groups.ext` both
sit outside any worktree. Two agents building concurrently, or one reaching for `tokall`
because a retok "didn't take", is how Tony's uncommitted work is lost.

---

## 6. THE PRICE, stated so nobody discovers it at round 4

**Re-orientation every round.** That is the cost of the measurement, and it is expensive
in the intended way — the same argument that made cold start acceptable.

> **If it proves prohibitive the answer is a CHEAPER BRIEF, not a longer-lived agent.**

---

## 7. WHAT IS STILL OPEN

- **The corpus's own format is untested against its real reader.** B0 proved the
  claim-record format against tok claims — written by Clod, for Clod. Round 1's BLOCKED
  and claim records are its **second acceptance test**, on B0's own terms: if a real claim
  will not fit the fields, the format is wrong and moves, and whoever moves it accounts
  for the move. A format defect is a Leak-2 brief revision — logged, with the series
  broken.
- **`docs/mdReorgB0.md` §3's KANT-GAP-lands-as-RUN line is PROVISIONAL** pending SEQ 30a.
  Do not absorb it. `signed:` on negative claims is **proposed and unruled**.
- **"Project knowledge is fully briefable" is READ, scoped to non-genParse work.** Clod
  arrived cold on 2026-07-29 and ran B0 off `wakeup.md` plus the tree — but B0 was small
  and deliberately not genParse, and no rung has been climbed cold. **Round 1 of A is its
  first real test**, which is a second reason not to seed it.
- **The iterator** (mdReorgB0 §8) is not designed. A's cadence is table → string assembly
  → control flow and **only the third step needs it**, so A fires on steps 1–2 while it
  settles. Steps 1–2 file every wanted-an-iterator site as a BLOCKED-adjacent record — a
  requirements document written by use rather than by speculation.
