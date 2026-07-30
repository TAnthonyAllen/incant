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
| — | *none yet* | — | — | — | — | — | — |

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

*(round 1's result follows below when it lands)*

---

## STANDING CHECKS BEFORE EACH SPAWN

- [ ] fresh agent; inputs are **corpus + brief + rung target** only
- [ ] brief unchanged since last round (or the revision is logged above and the series broken)
- [ ] corpus is the only writable surface besides the method
- [ ] previous rounds' targets currently green (run the regression surface *before* spawning,
      so a pre-existing break is not attributed to the new round)
- [ ] foreman holds the build; agent has not been asked to `xcodebuild` or `tokall`

**Round 1's run of that list, 2026-07-29 (all five):** fresh spawn, no inherited context ·
brief unchanged, zero revisions · corpus + `incant/genEmit` are the only writable surfaces ·
`sh genLadder/pop.sh` → **POP PASSED, 22 checks, exit 0, run immediately before the spawn** ·
build and `groups.ext` held by foreman, and the agent is told to stop and ask rather than build.
