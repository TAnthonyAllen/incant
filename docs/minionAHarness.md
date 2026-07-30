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

### ⚠ AND THAT EXEMPTION WAS UNVERIFIABLE UNTIL ROUND 1 — `roundTrace.sh`
*"Enforced by Leak 1's input list, not by good intentions"* named the mechanism and
supplied no instrument. There was no way to answer the leak question except to ask the
round, **which is the round reporting on its own compliance** — the same defect as
grading a claim by the agent that wrote it, one level up.

> **`sh docs/minions/roundTrace.sh <agent-transcript.jsonl>` — run it EVERY round, and
> read its WRITE SURFACE before reading anything the round says.**

It reports every path opened (via `Read` **and** via the file arguments of `Bash` lines,
because `cat X` reads X exactly as `Read` does), every path written, and the action trace.
Round 1's: **write surface clean** — corpus + method, nothing else — and an input surface
of **31 paths**, all brief-permitted background, none of them this file or the ledger. So
the exemption held in practice on its first measured round. Added on Clay's suggestion
after Tony noticed a round's status lines going past unrecorded.

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

### Round 1's ordering — RULED (SEQ 30d): the decision is DEFERRED, not pre-made
Round 1 is both the corpus format's second acceptance test **and** the baseline, so a
format failure would break a series containing exactly one round. Ruled: **neither**
"shakedown round" nor "format rides on whatever round 1 produces."

> **Fire as-is. Do not enter round 1's number in the ledger until the format holds.**

| outcome | cost |
|---|---|
| format held | enter the number — the cheap option, free |
| format bent | revise, spawn 1′, baseline is 1′ — the expensive option, paid only because it was needed |

**The method survives either way** — it toks, it hits its target, it is converted. Only
the *datum* is discarded, and only on the round least able to produce a good one.
Decide on evidence, not in advance.

**Two conditions, or the deferral leaks:**

1. **The threshold is set NOW, not after seeing it.** "The format bent" is not binary, so:
   > **A format change that would alter what an EARLIER round would have written breaks
   > the series. One that would not, does not.**

   An added optional field no prior claim needed is **not** a break. Census discipline —
   account for what moved — applied to the format itself.

2. **The deferral is invisible to the round.** Not to the agent (already amnesiac, frozen
   brief) — **to foreman.** A gate held one notch looser because *"it's a shakedown
   anyway"* is exactly how a baseline gets contaminated.
   > **Gate identically. Decide afterward.**

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

**(c) is the most likely one in practice, and it was only HALF mitigated** (SEQ 30d).
The byte-exact target pins **method** surface — the agent cannot shrink the code without
failing the gate. **Nothing pins CLAIM surface.** An agent can reproduce its target
perfectly and write **one thin claim where three were owed**; round N+1 then has less to
fail against and **survival looks better**. There is no target to diff a claim against.

**The closer, and the data is already in hand — log CORRECTIONS separately from CLAIMS:**

> **Every correction produces a claim, or an explicit decision not to.**
> **Corrections persistently exceeding claims means claims are under-written.**

Visible per round instead of at round 4. The residual — a correction that was *never
raised* because nobody noticed the omission — is not covered by this and is not covered
by anything; it is the same family as the §7 named gap.

**The instrument only works if the baseline is genuinely expensive.** A cheap round 1 is
a reason to stop and look, never a reason to proceed pleased.

---

## 3a. THE ABORT CONDITION — Clay's, recorded in his name

*A metric with no attached decision is expense in the costume of rigour. §3 pre-registers
what a LOW number means; nothing stated what happens if the number **never falls**. Set
before round 1 so it is not a judgment call under sunk cost.*

> **If round 4 shows no improvement over baseline and no leak is found, the corpus
> hypothesis is FALSIFIED for this task.**

**The abort puts Clay's premise on the line, not the minion's competence.** Tony called
the corpus a fringe benefit; Clay called it the main event and overrode him, and that
reframing has driven every turn since without being re-tested. If the abort fires, the
finding is that **Clay was wrong about which artifact mattered** — and the converted
methods, which survive regardless, were the deliverable all along.

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

Run by **foreman**, **before the spawn as well as after**. Project doctrine already —
*capture BEFORE changing anything and diff after* — and without the pre-run a break that
was already there gets charged to the new round, invalidating a round for someone else's
damage.

### ⚠ It is NOT a census, and the gap it leaves is the one that matters (SEQ 30d)
Clay named it "A's census" and then withdrew the name, correctly:

| instrument | catches |
|---|---|
| genParse's census | **erosion of judgment** in rules nobody is looking at |
| A's regression surface | **breakage** in methods already converted |

> **Nothing catches C++-shaped kant in a method nobody is re-reading.**

That is precisely the erosion named as least carryable — it looks like progress, and a
converted method that still hits its target byte-for-byte is *green while being wrong in
the only way that matters to a corpus about idiom*.

**Recorded, not built for.** One kind per rung, and A has no methods to erode across yet.
**Revisit after round 3.**

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
