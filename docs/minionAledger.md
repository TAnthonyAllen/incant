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

| round | method | corrections | claims drafted | corr. with NO claim | claims defeated | regression | series |
|---|---|---|---|---|---|---|---|
| **1** | `emitLeaf` | **2** (both foreman, both vs KANT-8) — *provisional, Tony has not reviewed* | **8** (KANT-6…12 + KANT-B1) | **0** | n/a — baseline | **green** | 1 |

**Round 1's number IS entered, because the format HELD.** Eight records fit the
claim/BLOCKED fields with **no field added, none repurposed, and no wording
changed**. The pre-registered threshold was *"a format change that would alter
what an earlier round would have written breaks the series"* — no change was
needed at all, so nothing breaks and the series starts at 1. That was the cheap
outcome and it is the one that happened.

⚠ **The correction count is PROVISIONAL. Tony rules on style and has not reviewed.**
Banking `2` before that review would be exactly the contamination the deferral
exists to prevent, in the other direction.

**Corrections** = distinct critique points Tony or foreman raised. Each one cites the
claim ID it defeats, or `NEW`.

**Corrections and claims are logged SEPARATELY, and that is the (c) closer** (harness §3,
SEQ 30d). The byte-exact target pins method surface; **nothing pins claim surface**, so an
agent can hit its target perfectly and write one thin claim where three were owed —
after which round N+1 has less to fail against and survival *looks* better.

> **Every correction produces a claim, or an explicit decision not to** (recorded in the
> round note, with the reason). **Corrections persistently exceeding claims means claims
> are under-written** — visible per round instead of at round 4.

**Round 1's number is entered only once the format holds** (harness §3, deferred ruling).
A format change that would alter **what an earlier round would have written** breaks the
series; one that would not, does not. Gate round 1 **identically** to every other round —
a gate held looser because "it's a shakedown anyway" is how a baseline gets contaminated.

**ABORT (Clay's, in his name):** if **round 4 shows no improvement over baseline and no
leak is found, the corpus hypothesis is falsified for this task.** Set before round 1 so
it is not a judgment call under sunk cost.

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

### ROUND 1 — PRE-SPAWN (foreman, 2026-07-29). Written BEFORE the round ran.

**Method: `emitLeaf`.** Tony's ruling (SEQ 33) names *"`emitTerm`'s kind→spelling
dispatch"*. **There is no `emitTerm` in the source** — it is `emitLeaf`
(`genParse.rtn`), renamed at the rung-3 seam; `emitTerm` survives only in
`genParseSpec` §4.2 and in `wakeup.md`'s history. Same method, corrected name.

**Target: `genLadder/spell.target`** (new), via `incant/spellScratch` +
`dumpSpellings`. It did not exist; authoring it is foreman work per harness §4.
Six plan kinds and the refusal path, both sinks on every node.
> ⚠ **That last sentence was WRONG when written, and it is left standing with this
> correction beside it rather than edited away — a pre-spawn note that gets tidied
> after the fact is not a pre-spawn note.** There are **five** kinds, and the
> refusal in the target is the **walk's** (`planTerm`/`planRule`), not the
> emitter's — `emitLeaf`'s own refusal arm is never reached, because the walk
> refuses anything the emitter would. Round 1 caught it. See the result note below.

**Three things recorded now so they are not interpreted after the fact:**

1. **The gate has a named hole.** `litTo(t1,label,"{","{")` carries the literal
   and the slot as the *same string*, so a rewrite that swapped those two
   positions would pass. It is a property of `planTerm` (a literal term's slot IS
   its text) and **every** LITTO in the census is like it, so there is no rule to
   add that would close it.
2. **"A green stub reads as coverage" was real, and is closed.** `emitLeaf`'s
   fork is silent, so `spell.target` is green whether kant ran or not.
   `spellMode` prints which implementation is live and `pop.sh` pins it at `c++`.
   **Flipping that pin to `kant` is round 1's acceptance test.**
3. **Per-round parameterization vs Leak 2.** The spawn carried the *interface* the
   kant action must satisfy (registry `Spellers`, action `spellLeaf`, one
   argument = the plan node, `sink` as an attribute, return the spelling). That
   is target definition, not learning carried forward, and **the frozen brief was
   not touched.** Logged here rather than left implicit.

**One verification note was given to the round, deliberately, and it is not a
kant idiom:** *exit 0 with no output at all is a swallowed run, not a pass.*
Foreman hit it while proving the bridge — a malformed block in an included file
produced exit 0 and an empty capture. The brief's doctrine ("a POP is not passed
unless the process exited 0") **does not cover that case**, so withholding it
risks the round reporting a false pass, which corrupts a baseline worse than the
note does.

**Foreman hit two failures while proving the bridge and wrote NEITHER into the
corpus. They are deliberately not described here either** — this file sits in a
tree the round is allowed to read while orienting, so naming the mechanisms would
be the same leak one file further out. Seeding is what the harness exists to
prevent; if they are real hazards the round will meet them and claim them, and
*that* is the datum.

⚠ **Residual, and it is honest to name it:** the commit that landed the gate
describes both failures in its message. Git history is not one of the round's
three inputs, but neither is it sealed — a round that goes looking could find it.
Recorded as a known, narrow exposure rather than claimed as airtight.

**The bridge was proven before the spawn**, not handed over on faith: a throwaway
kant speller returned both a node and an assembled string through the fork, and a
deliberately wrong one made the gate go red on both the target and the pin.

### NEW INSTRUMENT — THE ROUND TRACE. Clay's ask, and it closes the harness's biggest hole.

`sh docs/minions/roundTrace.sh <agent-transcript.jsonl>` → a ledger-ready block.
Added mid-round-1 on Clay's suggestion after Tony noticed the round's status lines
going past unrecorded.

**It is not for the narrative.** Harness §1 makes the leak check the *first* thing
that matters — *did the agent see anything outside {corpus, brief, target}?* — and
§2's entire instrument depends on that answer, because **a leaked round's number is
uninterpretable whichever way it comes back.** Until this script there was **no way
to answer it.** Foreman watched a scroll go past and would then have reconstructed
from the round's own report — *which is the round reporting on its own compliance.*
That is the same defect as grading a claim by the agent that wrote it, one level up.

Three sections, and the first two are the point:

| section | answers |
|---|---|
| **INPUT SURFACE** | every path the round opened — via `Read` **and** via the file arguments of `Bash`, because `cat X` reads X exactly as `Read` does and a check that counted only `Read` would be trivially evadable |
| **WRITE SURFACE** | Leak 3 — the corpus and the method, nothing else. This is the one that must come back SHORT. |
| **ACTION TRACE** | the shape of the round, in order. Context, not evidence. |

Mechanical on purpose — the same argument `pop.sh` earns its place on. Hand-rolling
a check per round is how the escaping goes wrong once and nobody notices.

⚠ **Honest exposure, named not claimed away:** the script lives in the repo, and the
repo is background a round may read. A round that reads it learns it is being
traced — an observer effect on the very compliance being measured. It carries no
round-learning, so it is not a Leak-3 laundering path, but it is not sealed either.
Same category as the git-history residual above.

**Retrofit note:** round 1's trace is captured *because the transcript survived*.
Nothing before it has one, and the standing checks list gains a line so no later
round is graded on foreman's memory of a scroll.

### ROUND 1 — RESULT. Target green, pin flipped, and it found a live bug.

**Gate, run by foreman and not taken on the round's word** (harness §5, all five):

| gate item | result |
|---|---|
| toks clean | **n/a and correctly so** — `incant/genEmit` is incant source read at runtime. No `tok`, no build. The round asked for neither. |
| reproduces its target byte-for-byte | **yes.** `spell.target` unmoved while the implementation producing it changed language. |
| regression surface green | **yes.** All 7 rung targets, census, rStuff audit, all 3 iterator fixtures, both baselines. `sh genLadder/tree.sh` exit 0 too. |
| checked against claims on the books | yes — and it *extended* two of the seeded ones rather than colliding with them |
| exit status checked | yes. `pop.sh` exit 0 after the pin flip; `spellScratch` exit 0 with full output. |

**THE ACCEPTANCE TEST PASSED:** the speller pin read `SPELLER kant`, so the POP
went red on exactly the one line that was *supposed* to. Pin flipped `c++`→`kant`;
it now guards the other direction — reading `c++` again means the kant speller
stopped being found and the C++ body is quietly answering for it.

**LEAK CHECK — the first thing that matters, and now answered mechanically** from
`docs/minions/round1.trace` rather than from the round's account of itself:

```
WRITE SURFACE   docs/kantCorpus.md   +   incant/genEmit        <- and nothing else
INPUT SURFACE   31 paths
```
**Leak 3 held exactly.** The input surface is 31 paths — every one background the
brief explicitly permits (*"background you may read to orient"*), and none of them
`minionAHarness.md`, `minionAledger.md` or `minions/`, so the exemption held **in
practice** and not only on paper. The 31 is itself a datum: harness §6 priced
re-orientation as the cost of the measurement, and this is the first actual figure.

**⚠ IT USED THE ITERATOR, which the pick was made to avoid.** Clay chose `emitLeaf`
partly because *"emitTerm NEEDS NO ITERATOR — it is a table, not a walk"*, decoupling
round 1 from the iterator docket. True of the table; **false of the round.** `OPT`
wraps a term, and reaching it took `iterate inner on argument members` — so the
iterator work finished the same morning was load-bearing for round 1 after all, and
KANT-9 is a claim about iterator semantics. The decoupling argument was right about
the schedule and wrong about the dependency; the schedule survived because the
iterator happened to be done first.

#### WHAT ROUND 1 FOUND, ranked by what it costs to not know

1. **KANT-8 is a LIVE LATENT BUG in `runAction`, not a kant idiom.** With
   `field.recursive` set, `restoreLocalFields` runs *after* `processAction` and
   before the return, so an action returning one of its own locals hands back that
   local **reverted to its pre-call state**. Confirmed independently by foreman on
   a fixture with no `spellLeaf`, no C++ seam and no warm-up — two identical bodies
   differing only by an **unreached** self-mention. **It is the same function whose
   `saveLocalFields` was fixed hours earlier**, and it is a second, independent
   hole in the same frame machinery. *The fix is Tony's* — both obvious candidates
   touch the interpreter's hot path.
2. **KANT-B1: a kant action cannot return NULL across `runAction`** (IDIOM-GAP,
   grepped first, five attempts with output pasted). **The consequence is live:**
   the shipped `spellLeaf` is *loud* on an unknown kind but does not *refuse*, so
   `emitPlan` would take junk text as a spelling. **No target covers it** — see the
   `pop.sh` label correction below, which is the same hole from the other side.
3. **KANT-6/7 together:** recursion is `this(...)`, and `this(...)` does **not** set
   `recursive`, so it does not get per-frame locals. They must be read as a pair —
   the fix for one is the price of the other.

#### CORRECTIONS — 2, both foreman's, both against KANT-8, both produced claim text

1. **Provenance could not isolate the mechanism.** The round's evidence had to dodge
   the KANT-6 crash with a warm-up call, so it could not separate *"restore empties
   the result"* from *"the recursive call misbehaved."* Foreman re-ran with the
   recursive call **never taken**. Separated. → claim strengthened.
2. **The scope named the decisive probe and did not run it** (*"not verified whether
   returning the ARGUMENT dodges it"*). That probe decides whether kant recursion is
   *usable at all*, so leaving it unrun left the claim true and unactionable. Run:
   returning the **argument survives**, returning a local is emptied, and **minting a
   fresh node does NOT dodge it** — so it is about which *slot* the returned pointer
   is, not about node identity. → claim extended, and A's step 3 now has an idiom.

**Every correction produced claim text; corrections (2) do not exceed claims (8).**
So harness §3's (c) — thin claims — does not fire, and the low count is not the
under-writing signal. §3's other two: **(a) no leak** (write surface clean), **(b) not
too easy** (a segfault, a latent runtime bug, and a genuine BLOCKED). Foreman's
reading: the baseline is honest. **But it is provisional until Tony reviews.**

#### TWO CORRECTIONS THAT WENT THE OTHER WAY — the round corrected FOREMAN

1. **The brief-slot text.** It said *"returns a field whose content is the spelling"* —
   true, but it silently assumes that field is a **local**, which is exactly what
   KANT-8 empties. The stated interface and the runtime were in tension and the
   round said so. Fixed in `incant/genEmit`'s contract.
2. **`pop.sh`'s own label** said *"all 6 kinds + refusal."* **Both halves overstated
   it:** there are **five** kinds, and `Limit`'s rows are the **walk's** refusal
   (`planTerm`/`planRule`) plus `dumpSpellings`' own "no plan" — **`emitLeaf`'s own
   refusal arm is never reached by the target.** An emitter that dropped its refusal
   branch entirely would pass. Label corrected; the gap is now stated, not implied.

*These are worth more than the two corrections above.* A round that reads its
foreman's fixture closely enough to catch an overstated label is a round whose
compliance claims are worth something.

#### STILL OPEN OUT OF ROUND 1

- **`runAction`'s restore-after-return** (KANT-8) — Tony's call, and it blocks a
  value-returning recursive kant action, which is what `emitPlan` will be.
- **Refusal across the seam** (KANT-B1) — the round's suggested first move is to
  return the argument with a flag stamped via `:.` and have the C++ side test the
  flag rather than the pointer. Untried.
- **`emitLeaf`'s own refusal arm is untargeted.** Cheapest close: a plan node of a
  kind the emitter does not know, which needs a synthetic node, since the walk
  refuses anything the emitter would.

---

## STANDING CHECKS BEFORE EACH SPAWN

- [ ] fresh agent; inputs are **corpus + brief + rung target** only
- [ ] brief unchanged since last round (or the revision is logged above and the series broken)
- [ ] corpus is the only writable surface besides the method
- [ ] previous rounds' targets currently green (run the regression surface *before* spawning,
      so a pre-existing break is not attributed to the new round)
- [ ] foreman holds the build; agent has not been asked to `xcodebuild` or `tokall`
- [ ] **AFTER the round: `sh docs/minions/roundTrace.sh <transcript>`, and read its WRITE
      SURFACE before reading anything the round says.** Added after round 1. Until it
      existed the leak question could only be answered by asking the round, which is the
      round reporting on its own compliance.

**Round 1's run of that list, 2026-07-29 (all five):** fresh spawn, no inherited context ·
brief unchanged, zero revisions · corpus + `incant/genEmit` are the only writable surfaces ·
`sh genLadder/pop.sh` → **POP PASSED, 22 checks, exit 0, run immediately before the spawn** ·
build and `groups.ext` held by foreman, and the agent is told to stop and ask rather than build.
