# Clod's Comments — on Tony's Offline Report + Fearless's `minions.md`

*Written 2026-06-28 for Tony to pass on to Clay/Fearless. Executor's reality-check on the vision.*

---

## Bottom line up front

The vision is sound and most of it is buildable — but the architecture lives or dies on **one
reframe** and **one failure mode**, and both deserve to be load-bearing in the design, not
footnotes.

- **The reframe:** a minion is not a living, persistent agent. It is a **persistent corpus file**
  plus a **transient agent that puts it on like a costume** for one task and then dies. Get this
  right and everything else follows cleanly. Get it wrong and we design for a daemon that can't exist.
- **The failure mode:** a confidently-served *stale or wrong* pie. We have already been bitten by
  exactly this (see below). The minion architecture's whole value is trust-on-demand; an
  auto-absorbing corpus that ingests a falsehood serves it forever. Provenance and staleness-honesty
  are core, not polish.

Everything below expands those two and grades the pieces.

---

## What agents-as-minions CAN and CANNOT do (Tony's direct question)

**CAN (real today):**
- Spawn many agents in parallel, each with its own isolated context — *this is literally Tonto's
  scouts.* Not aspiration; I do it routinely.
- Hand a freshly-spawned agent a briefing file and have it *become* the expert for that one task.
- Have a scout return findings and merge ("absorb") them into a corpus file as a discrete step.
- Run a "bake" pass that synthesizes a raw session into a pre-digested pie.

**CANNOT (no matter how we wish):**
- Keep a minion *alive in memory* between sessions. There is no standing JIT Igor daemon awake and
  "continuously absorbing." When the session ends, the agent is gone.
- "Continuously update" anything in the background. **Every** absorption, synthesis, or answer is an
  agent invocation that *something has to trigger.* "Continuous" really means **event-driven** —
  fired at session boundaries, on scout return, or on demand.
- Synthesize for free. Each query/absorb/bake is a model call with a cost.

**The honest decomposition:** a minion = `{ corpus file on disk } + { a fixed set of operations
(query, absorb, bake), each of which spawns an agent that loads the corpus }`. That's it. It's less
magical than "a being who knows things," but it's *real*, and it's enough to deliver the experience
the vision promises.

---

## The piece Fearless mostly nails

His "a minion is three things — role definition, knowledge corpus, synthesis prompt" (line 39) is
**exactly right** and is the buildable core. So is "the minion *is* an incant field… Igor wakes up
by loading this structure" (line 102). Where the doc drifts is the word **"persistent agents…
continuously absorbing"** (line 13) and "auto-maintained" (line 150) — that's the daemon mirage.
Swap "persistent agent" → "persistent corpus + on-demand agent" and "continuous" → "event-driven
(at session end / on scout return)" and the doc is technically honest end to end.

---

## The failure mode, with evidence from our own week

This is the most important thing I can add, because it's not theoretical — **it already happened to
us.** The prior `wakeup.md` confidently asserted the gIF then-arm store was "proven through the
branch (taken→99)." It was a **shape-read — false.** Hard IR evidence this week showed an
unconditional store branching on `i1 true`, a dead branch.

Now run that through the proposed architecture: an auto-absorbing JIT Igor would have ingested
"taken→99 ✓" into its corpus and **served that poison as fact on every future query.** The pie
would have been beautiful and wrong. That is the single biggest risk in the whole design.

**Implication — three things become non-optional:**
1. **Provenance.** Every claim in a corpus carries where it came from (which scout, which run, hard
   IR vs. inference). "Verified by IR dump" and "inferred from shape" must be *visibly different.*
2. **Staleness-honesty.** A minion must know and declare what it *doesn't* know or what may be rotten
   (`lastUpdated` is a start; add a confidence/verified flag per claim).
3. **Adversarial absorption.** Scout findings shouldn't be merged on faith. The absorb step should
   *challenge* the new claim against the corpus before blending it — the same bear-trap discipline we
   already practice by hand. (This maps perfectly onto the parallel-verify pattern I can run today.)

A minion you can't trust is worse than no minion, because it's confident. Bake this in from day one.

---

## The amplification: this is *incant's* idea, not a Claude wrapper

The thing to lean into hard with Clay: **the minion architecture is already how I work** — dispatch
sub-agents, they read briefing files, return findings. The vision is to **formalize that pattern
into incant's own homoiconic data model** so it survives across sessions and eventually serves users.

That's elegant and it's *load-bearing for the "why incant" question*: a minion is a GroupItem, a
corpus is a GroupItem tree, and incant programs can **construct, inspect, and rewrite minions the
same way they rewrite any other structure** — which is the founding premise of the language. The pie
isn't a markdown blob bolted on; it's a first-class incant structure. That's what makes this
incant's feature and not "a folder of `.md` files with a chatbot."

**One sharpening of the field spec (lines 91–100):** `corpus: [path to .md file]` is the right
*bootstrap* but the wrong *destination.* md gets us moving; the endgame is the corpus **being** a
GroupItem structure (queryable, walkable, homoiconic) — keeping faith with "the minion is an incant
field." Note md as the scaffold, the GroupItem corpus as where it's going.

---

## Grading the roster

- **FileBoss — build this FIRST, and notice it's barely an "AI" minion at all.** Three-copy rule +
  checksum-on-write + transparent reroute is *deterministic incant code.* It needs no LLM, it's
  testable, demonstrable, and it proves the headline user contract ("your stuff is always there, you
  never thought about it") cheaply. It's the lowest-risk way to make the invisible-substrate promise
  *real* instead of slideware. Strong candidate for first concrete deliverable.
- **JIT Igor — right first *AI* minion.** `docs/jit.md`/`wakeup.md` are already 80% a corpus. Making
  it "official" mostly means adding provenance + an absorb step + the verify discipline above. Low
  cost, immediate payoff to *us.*
- **Sensei — prototypable as pure dialogue, earlier than the GUI it will eventually drive.** Sensei
  is fundamentally a prompt + a 3–5 question template. We can build and test the clarifying-question
  flow as a conversation pattern *now,* with no GUI, and learn the vocabulary translation problem
  before it has to drive form-drafting.
- **GUI Minion — the north star, correctly furthest out.** Depends on the GUI arc, which is deferred.
  Midjourney-for-computing is the destination; don't let it gate the near-term wins.

---

## The sequencing caution (restating, because it matters for planning)

The doc fuses **two products** under one coat:
1. **Internal tooling** — minions help *Clod/Clay/Tony* build incant. Buildable now, pays off now.
2. **Consumer substrate** — minions let a non-technical user skip the file system entirely.
   Multi-year.

For a *vision* doc, fusing them is fine — the thread from one to the other is the inspiring part.
For a *plan,* split them, so the near-term win (a trustworthy JIT Igor + a working FileBoss) never
gets held hostage to the moonshot. We can be using minions to build incant long before any
grandmother talks to Sensei.

---

## My proposed first concrete step (for discussion)

If we want one buildable artifact out of this arc that isn't prose, I'd pick **the minion corpus
format + the three operations** (query / absorb / bake), prototyped against JIT Igor using
`docs/jit.md` as the seed — *with provenance and the adversarial-absorb check built in from the
first line.* That gives us: a real format, a real first minion, and a real test of the trust
problem, all at once — and FileBoss can proceed in parallel as the deterministic-substrate proof.

*Final product still TBD — this is input to that conversation, not a verdict.*
