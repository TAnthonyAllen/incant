# Minion Corpus Format — v0

*2026-06-28. The structure a minion's knowledge lives in. Markdown is the bootstrap
encoding; a GroupItem tree is the destination — the field names below are chosen so the
two are the same shape. See `vision.md` ("The corpus as GroupItem") for the why.*

---

## What a corpus is

A minion is **a persistent corpus file + a transient agent that reanimates it** (vision.md,
"persistent corpses, rented sparks"). This document defines the *corpus* — the durable part.
The agent is whatever process loads it; the corpus is what survives between sessions.

A corpus is one GroupItem (the `minion` root) with a fixed set of sub-fields. Everything a
minion knows is a **claim**; every claim carries the metadata that lets a later reader trust
it or doubt it. The format exists for exactly one reason: **so a minion cannot confidently
serve a falsehood.** (The poisoned-pie lesson — see Acceptance Test.)

---

## The shape

```
minion                      ← corpus root (a GroupItem)
  name        : "JIT Igor"
  domain      : one-line scope — what this minion is the authority on
  lastBaked   : YYYY-MM-DD   ← when the corpus was last distilled (bake)
  sources[]   : the files/runs this corpus was built from (for re-bake + audit)

  claims[]                  ← the knowledge, as discrete entries. Each claim:
      id          : short stable slug (so other claims / openItems can reference it)
      text        : the claim itself, one assertion
      confidence  : verified | inferred | stale-suspect | refuted   (see vocab)
      provenance  : where it came from — file:line, run name, "IR dump", scout id
      asOf        : YYYY-MM-DD  ← when this claim was last confirmed true
      supersedes  : (optional) id of a claim this replaces — keeps the trail

  openItems[]               ← unresolved questions the minion is tracking
      id, text, why-it-matters

  scouts[]                  ← recon feeding this corpus (pending or absorbed)
      id, mission, status (pending|absorbed|rejected), landed (date)
```

### The confidence vocabulary (the load-bearing part)

| value | means | how it got there |
|---|---|---|
| `verified` | **bones-confirmed.** Actual trace, IR dump, readback, or test run. | A run was observed. Not predicted from source. |
| `inferred` | reasoned from structure/design/shape — *plausible, not run.* | Read from code/design, never executed. |
| `stale-suspect` | was believed; now doubted, superseded, or aging past `asOf`. | Newer evidence, a supersede, or time. |
| `refuted` | **shown false.** Kept (not deleted) so the trail survives. | Evidence contradicted it. |

**`verified` means bones, not shape.** This is the whole discipline (projectBible
"bones-verification over shape-reading"). A claim read off source code is `inferred`, never
`verified`, no matter how obvious it looks. The gIF "taken→99" disaster (wakeup.md) was a
shape-read promoted to fact — under this format it would have been `inferred` at best, and the
contradicting IR dump would have flipped it to `refuted`, not silently overwritten it.

---

## Two rules added 2026-07-30, both paid for the same day

**SERIES ASSESSMENT, because a format change can break the measurement** (`minionAHarness.md`
§3: *a format change that would alter what an earlier round would have written breaks the
series; one that would not, does not*). **Neither rule below breaks it.** Round 1's eight
records were genuine claims plus one genuine BLOCKED — none was an absence claim, and none
was an open item in claim's clothes. So an earlier round's output would be **unchanged**
under these rules, and the series continues. Assessed before adding, not after.

### RULE 1 — AN ABSENCE CLAIM MUST NAME WHERE IT LOOKED

A claim that something **does not exist** is only as good as the search that failed to find
it, and unlike a positive claim it **rots silently** — the world only has to gain the thing.
So an absence claim carries **the search that grounds it**: the paths, the pattern, and the
scope.

> ✗ "there is no member-filtered first accessor"
> ✓ "no member-filtered first accessor: `grep -rn 'firstMember' --include=*.rtn --include=*.twk .`
>    over the repo returns nothing, 2026-07-30"

**Paid for the same day it was written.** `CLAIM KANT-17` asserted flatly that no
member-filtered first accessor existed. Foreman added one an hour later, making the corpus
false — and it was caught only because the same person happened to be holding both. Had a
round written it and a later round read it, nothing would have caught it at all.

**And the sharper case, which is why this is a rule and not a style note:** an absence claim
whose search space was wrong is *indistinguishable* from one that is true (bear-trap #19's
corollary — narrowing is only valid inside the space you searched). Naming the search is what
lets the next reader re-run it instead of re-trusting it.

### RULE 2 — AN OPEN ITEM IS ITS OWN SHAPE. IT IS NOT A CLAIM WITH HEDGES.

Three shapes now, not two:

| shape | means | a reader should |
|---|---|---|
| **CLAIM** | this is so, at this confidence | act on it per the confidence table |
| **BLOCKED** | I tried, it cannot be done this way, here is the evidence | do not retry blind; read the evidence first |
| **OPEN** | a real question, with what is known and what is *not yet done* | **this is work, not knowledge** |

**The failure this prevents is specific and already happened.** `CLAIM KANT-20` had to
describe itself, in its own scope line, as *"an OPEN ITEM WEARING A CLAIM'S CLOTHES"* — its
counts were solid, its inference was deliberately undrawn, and the work of sizing the real
suspect set was simply **undone**. Written as a CLAIM it reads as knowledge and invites
action; the only thing stopping that was a warning stapled inside it.

> **The tell that you want OPEN and not CLAIM: the entry's most useful sentence describes
> something nobody has done yet.** A claim says what is true. An open item says what is
> missing, what it would cost, and what it blocks.

An OPEN carries: the question · what IS established (with provenance) · what is NOT ·
what it blocks · what it would cost to settle. It graduates to a CLAIM when someone does
the work — and **the graduation is the point**: a corpus with a growing OPEN list is
healthy, one where opens are quietly rewritten as claims is rotting in the way the
confidence table cannot show.

## The four operations (how agents act on a corpus)

These are the verbs from vision.md, defined against this format:

- **Query** — load the corpus, answer a question. A query answer **must respect confidence**:
  serve `verified` claims as fact, hedge `inferred` ones, and flag `stale-suspect`/`refuted`
  rather than repeat them. (This is what the Acceptance Test checks.)
- **Absorb** — merge a scout's finding as a new `claim` (or a `supersedes` of an old one),
  *with provenance and confidence set at merge time.* Never merge a finding as bare prose.
- **Bake** — distill raw session/source material into the corpus: re-derive claims, refresh
  `asOf`, age stale ones, update `lastBaked` and `sources[]`.
- **Challenge** — adversarial absorb. Before a finding is accepted, verify it against the
  corpus and the bones. A finding that can't be bones-confirmed lands as `inferred`, not
  `verified`. The one thing worse than a stale corpus is a confidently wrong one.

---

## Encoding now / destination

- **Now (bootstrap):** a markdown file. Claims are `###`-or-bullet entries carrying the
  metadata inline (`confidence:` / `provenance:` / `asOf:`). Human- and agent-readable today.
- **Destination:** the same structure as a GroupItem tree — `minion` root, `claims` a member
  list, each claim a GroupItem with `text`/`confidence`/`provenance`/`asOf` attributes. At
  that point the corpus is *queryable, walkable, and rewritable by incant programs* like any
  other field — the homoiconic payoff. The field names above are the GroupItem attribute names,
  so the bootstrap md retrofits into the tree with no rename.

---

## Acceptance Test (the format earns its keep here)

A fresh agent loaded with a corpus in this format, asked *"what's proven vs. what's just
believed in this domain?"*, must:
1. serve `verified` claims as fact (with their provenance available),
2. clearly hedge `inferred` claims as not-yet-run,
3. **refuse to repeat `stale-suspect`/`refuted` claims as true** — instead naming them as
   superseded/false.

Concretely: an agent on the JIT Igor corpus must **not** answer "the JIT gIF branch works
(taken→99)" — because that claim is recorded `refuted` with the IR-dump provenance that killed
it. If the agent repeats it, the format failed. If the agent says "that was a shape-read, since
refuted; JIT gIF is parked WIP," the format worked.

*v0. First instantiation: `docs/minions/jit-igor.md`.*
