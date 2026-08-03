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

- ⚠ **NO SUSPICIOUS TEMPORARIES LEFT AMBIENT** *(standing discipline, all charters — Tony's
  ruling 2026-08-03)*. **Delete when spent · manifest when kept · attic when uncertain.**

  *Earned the day it was written: `Frame/BeforeRefactor/` (24 files mirroring the entire census
  unit, silently doubling every grep), `Frame/Buffer.rvsd` (an unreviewed alternate of the file
  TASK 2 was about to build on) and `Frame/Stack.C` (a dead class one letter from a live one, and
  still in a Sources build phase). None was a secret; each was a temporary nobody had swept.
  ⚠ **The three dispositions are not interchangeable** — attic-ing something ruled **spent**
  overstates its status, and deleting something merely **uncertain** destroys evidence. Say which
  of the three a file is, then act.*

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

## M1 — THE RULE IN THE REQUIRED READING IS CORRECT. ONLY ITS SPECIMEN IS WRONG.

*⚠ Narrowed 2026-08-03 after the 2×2 read out. An earlier draft of this note said the required
reading was "wrong on its central fact" and implied the **rule** was wrong too. **It is not.** That
draft rested on an instrument error of mine, and the correction is recorded here rather than
quietly edited, because the charter's worked example depends on which half was wrong.*

**The rule stands as the wakeup states it:** a member-depth name is not reachable by bare lookup.
Measured four ways, and the last is decisive:

```
incant/listWalk    Generating's own list  49 entries, `generator` among them, NO gXpress
                   generator's own list   10 entries, gXpress among them
                   -> a member is on its PARENT's list, not the REGISTRY's
incant/vantage2x2  two names x two vantages -- ALL FOUR CELLS DARK
                   -> not the vantage, not the entry. The members gate IS the mechanism.
```

**What IS wrong is the specimen.** Wakeup 08-02 names `generatE` as the dark name. It is not:
`generateCode` reaches it via `generator["generatE"]`, a **parent index**, and always did —
`generateCode: running on testByteCode` fires and `End of generatE` prints.

**The names that actually went dark were `gXpress` and `emitBC`**, called **by bare name from
inside sibling member bodies** (`gIF` calling `gXpress(xp)`). The dispatched action ran; its
internal sibling calls resolved to nothing and **did nothing, silently, at exit 0.**

**Why the minion needs the corrected specimen:** the two versions send question 3 at different
targets. The wakeup's version asks *"why can't a caller reach a member it names?"* The real case is
sharper — **a member cannot reach its own SIBLING by bare name, while the table owning them both is
reachable from anywhere.** A law written against the first would not obviously cover the second,
and the minion cannot ask.

**Measurement floor for question 3:** `incant/sweepProbe` (attribute-lit / member-dark, three
checks) and `incant/vantage2x2` (the four cells).

⚠ **And one instrument warning the minion should carry, because it cost a false alarm here:**
**never test existence with `if x.taG;`.** A GroupField accessor returns a *fresh temporary field of
property text*, so it is truthy whether or not the lookup found anything. Use `if x;`. That artifact
produced a "the members gate has drifted" alarm that survived two fixture rewrites before the real
specimen killed it.

## M2 — Question 3's floor moved while the charter sat; here is where it landed

The **register pivot is settled and is now product**, not pending as this note first said.

- `incant/regProbe` — three legs green: an entry carrying `register` is bare-findable; its
  unregistered sibling **stays dark**; both stay reachable through their parent.
- **First production use, 2026-08-03:** `emitBC` carries `register`, with a negative control
  confirming `gXpress` stayed dark — so the mechanism publishes exactly one name at a time.

**So visibility can now be a per-name declaration rather than an accident of depth.** That is
question 3's answer arriving from the implementation side.

**It does not retire the question — it sharpens it.** A mechanism that *can* declare visibility says
nothing about **what may** declare it, **what happens when two registries both claim a name**, or
whether *"declared public"* should be a property the grammar recognises at all. If anything the
charter's question 3 is now the more urgent one, because the tree has started acquiring public
member names and there is no law saying which ones deserve to be.
