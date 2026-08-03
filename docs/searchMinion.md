# Search Law Minion — Charter

**STATUS: CHARTER, NOT A TASK.** Fires on Tony's word. Until then this file is a charter.

*Dictated by Clay 2026-08-03, countersigned Tony ("consider word given"). Transcribed by Clod per
WT-9. The charter body below is Clay's text. Clod's reader-notes are quarantined in the
TRANSCRIPTION MARGIN at the foot — they are **not** part of the charter and carry no authority.*

---

# SEARCH LAW MINION CHARTER — 2026-08-03, Clay, countersigned Tony

## SPECIES NOTE

**This is a design minion — the first.** Its deliverable is a **proposal, not code**, and **no
oracle exists for it**: the output is judged at Tony's gauntlet, not diffed against a baseline.
**That is the experiment, and either verdict feeds the ledger.**

## FIRE CONDITION

Fires on Tony's word, **and not while Clod is deep in the JIT arc** — a minion runs in Clod's hours
and relays through Clod's hands; fire when there is genuine slack, **judged by Tony**. No
dependency on the support minion or the taxonomy ruling, but if the taxonomy ruling exists at fire
time, it rides along as palette.

## PREMISE

The search list has **graduated from plumbing to semantics**: what a name resolves to depends on
what is loaded, in what order, at what depth — and the `generatE` incident (`generateCode failed`;
a member one indent deep, unreachable by bare lookup after the members gate) is the specimen
proving accidents in this space **fail silently at exit 0**.

**Law is wanted before speed:** every efficiency structure precomputes an answer, and
precomputation before law **freezes accidents into behaviour**.

## THE CANVAS — five questions. Propose law for each.

1. **Order.** Is the search list a stack? Does nearest-loaded win? Is load order **semantics or
   accident**?
2. **Shadowing.** Two registries hold one name: **silent, announced, or error**? (Doctrine palette
   leans *announced* — the fail-loud family — but the proposal may argue otherwise, with the
   argument on display.)
3. **Depth.** What may **bare lookup** reach, now that the members gate makes depth load-bearing?
   State the law the gate implies; the bare-lookup sweep is cleaning up its blast radius and
   **deserves a rule to sweep toward**.
4. **Mutation.** Load/unload mid-execution: **when does a resolution go stale?** (Note the rhyme
   with `irOf` — resolution-as-claim, invalidated by membership change. **Use it or reject it,
   visibly.**)
5. **Identity.** Is a registry's name part of resolution — **qualified lookup, a namespace
   concept** — or is the list an anonymous whole? **This is the largest question; it may change the
   grammar.**

## THE PALETTE

Signed doctrine, available as material, **none of it binding on the proposal except where already
law**: fail-loud announcements to `cerr` · the staleness-gate pattern (`irOf`/`irEnv`) · claims
carrying provenance and `asOf` · fork-then-fallback · little steps for little feet.

**Required reading:** the `generatE` incident and the members-gate consequence (wakeup 08-02,
Tony's offline section). *(⚠ See margin note M1 — that account has since been corrected by
measurement, and the corrected specimen is the one to reason from.)*

## THE BRUSHSTROKE

**Here is your canvas, brush, and palette; paint something interesting.**

## DELIVERABLE

**One proposal document.** Per question:

- the **proposed rule**;
- its **consequences run against the actual registries** as worked examples — *including the
  `generatE` incident replayed under the proposed law, stating what happens instead*;
- the **fixtures the rule implies, named but not built** — every rule should arrive pointing at its
  own future POPs, because search is going to warrant lots of testable.

**Rejected alternatives and named costs are welcome** and strengthen a proposal at the gauntlet;
they are **not entry requirements**.

## THE GAUNTLET

The proposal passes through **adversarial absorption** per `minionfire.md`, then **Clay's review**,
then **Tony's judgment**. **The proposal proposes; only Tony's signature enacts.** Law that
survives becomes the spec Layer 2 builds against.

## OUT OF SCOPE

**All implementation:** no `locate()` edits, no caches, no indexes, no grammar changes. **Layer 2**
(profile first, then speed structures keyed on registry generations) charters separately after
signature, likely support-minion territory with the recon's caller census as its measurement floor.

## CLAY'S MARGIN NOTE TO THE TRANSCRIPTION PASS

The charter **deliberately does not tell the minion how to think** — the deliverable spec
constrains the output's **shape**, not the **path**. *That is the species test.* If Clod's
reader-notes want to tighten it, same quarantine discipline as the support charter: margin, no
authority, flagged for signature.

---

# TRANSCRIPTION MARGIN — Clod, 2026-08-03

*Not part of the charter. Two notes. I have deliberately **not** tightened the brushstroke — the
looseness is the species test and tightening it would run the experiment on a different animal.
Both notes below are about the **specimen's accuracy**, not about the minion's latitude.*

## M1 — ⚠ THE REQUIRED READING IS WRONG ON ITS CENTRAL FACT, corrected by measurement today

This is the note that matters, because the `generatE` incident is named three times in the charter
and is the proposal's worked example for question 3.

**Wakeup 08-02 says:** *"`generatE` (`incant/generate:233`) sits one indent deep — a MEMBER — and
is reached by bare lookup, which the new members gate no longer serves."*

**Measured 2026-08-03, and it does not hold.** `generateCode` finds `generatE` perfectly well —
`generateCode: running on testByteCode` fires and `End of generatE` prints. It finds it because it
uses `generator["generatE"]`, a **parent index**, not a bare lookup.

**The names that actually went dark were `gXpress` and `emitBC`** — called **by bare name from
inside sibling member bodies** (`gIF` calling `gXpress(xp)`). The dispatched action ran; its
internal sibling calls resolved to nothing and **did nothing, silently, at exit 0**.

Probe (`incant/sweepProbe`, committed as the artifact):
```
A: generator          FOUND by bare name (10 members)   <- attribute depth
B: generator[gXpress] FOUND                             <- parent index
C: gXpress            NOT FOUND by bare name            <- member depth
```

**Why this matters to the minion and not just to the record:** a law for question 3 derived from
the wakeup's version would be answering *"why can't a caller reach a member it names directly?"*
The real question is narrower and more interesting: **a member cannot reach its own SIBLING by
bare name, while the table that owns them both is reachable.** Those imply different laws. The
minion cannot ask, so the specimen must be right before it fires.

**`incant/sweepProbe` is the measurement floor for question 3** — it is the only artifact in the
tree that pins the attribute-reachable / member-dark rule, and it is three checks long.

## M2 — Question 3 will have a moving floor; date it

The bare-lookup sweep and the **register pivot** are live work as of this writing. If `register`
holds (POP pending), **visibility becomes a per-name declaration rather than an accident of
depth** — which is question 3's answer arriving from the implementation side while the charter
sits on the shelf.

Not an argument to change the charter: a law is still owed, and a mechanism that *can* declare
visibility does not say *what may* declare it or *what happens when two do*. But the minion should
be handed the **then-current** state of `register` at fire time rather than this document's, and
the charter's own `asOf` discipline is the reason to say so here.
