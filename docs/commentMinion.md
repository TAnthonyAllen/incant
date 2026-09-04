> ⚠⚠ **SUPERSEDED IN PART, 2026-09-03 (Tony's ruling via Clay, SEQ 150). THE
> SCHEMA-V2 METHOD-SCOPED FORM BELOW IS NOT THE CONVENTION ANY MORE — the
> `opDot` TokFiles entry is.** This is a dated note, deliberately not a rewrite:
> the document's reasoning is why the convention arrived where it did, and
> rewriting it would delete the trail that justifies the ruling.
>
> **What replaces it, in one sentence:** if the comment explains WHY, it moves to
> a TokFiles entry and leaves a one- or two-line pointer at its post; if it says
> LOOK BEFORE YOU TOUCH, it stays, as one line, where it guards. **Site-scoped
> warnings never move.** The reader model is Tony reading the pointer as *"there
> may be something here I need to look into before changing this"* — the long
> text is for the registry and the AI.
>
> **The worked exemplars** are `Instruct.opDot` (130 lines to 85, fleet
> byte-identical, 2026-09-02) and `ruleActions.rtn` (1,784 lines to 1,381,
> 2026-09-03).

# COMMENT MINION — CHARTER (the comment pancake)

**STATUS: SIGNED, 2026-08-20. Clod drafted 08-17; Clay reviewed and signed 08-20 with amendments
A1/A2/A3; Tony fires.** One seam (S1) is open and marked in place, awaiting Tony's nod.
⚠ **NO MINION SEES THIS UNTIL CLOD AND CLAY HAVE BOTH SIGNED.** Nothing here acts before Tony
fires it.

---

## MISSION

Move oversized comment blocks out of `.rtn` method bodies into **`incant/designDocs`** entries
(schema v2), leaving a short pointer at the code site. The comment stops being prose nobody
maintains and becomes **data with a status, a provenance and a code site**.

**The reference specimen is a number, not a taste:** `Generate.rtn` carries **8** comment-block
lines across the whole file, and the next file up carries ~150x that. That gap is the target style
stated in numbers.

## ⚠ SCOPE AMENDMENT — METHOD-SCOPED, NOT FILE-SCOPED (Tony, 2026-08-17)

The minion picks **one easy file** and **one or two egregiously commented methods inside it**.
Not a file sweep. Not a campaign.

⚠ **AND IT STATES ITS PICK BEFORE IT CUTS ANYTHING**, in one message, so a target can be vetoed
in one sentence. A pick announced after the cutting has started is not a pick, it is a report.

**Precedent, and the reason the scope is what it is:** the `jitFieldMethod` pilot ran
method-scoped — **66 comment lines → 3**, one entry with 8 children — and it held. It is live in
`incant/designDocs` as the `JitFieldMethod*` attribute family. Read it before drafting anything;
it is the shape, not an example of the shape.

---

## THE CANDIDATE POOL, MEASURED (Clod, 2026-08-17)

Comment lines per method, the two files Tony named as the "easy" pool:

| method | file | comment lines |
|---|---|---|
| `opPlus` | `Instruct.rtn` | **55** |
| `arrondir` | **`Commands.rtn`** | **42** |
| `setMark` | `Instruct.rtn` | 41 |
| `opPlusPlus` | `Instruct.rtn` | 39 |
| `opDivEQ` | `Instruct.rtn` | 29 |
| `opAssign` | `Instruct.rtn` | 24 |
| `guard` | **`Commands.rtn`** | **22** |
| `getType` | **`Commands.rtn`** | 16 |
| `dumpContents` | **`Commands.rtn`** | 16 |
| `stopParsingInput` | `Commands.rtn` | 15 |

*(Method boundaries taken at `^extern`/`^static`; block comments counted whole, `//` lines counted
singly. The count is a ranking instrument, not a contract — the minion recounts its own target by
eye before proposing it, per H9: read the hits before reporting the number.)*

## ⚠ RECOMMENDATION: TAKE THE TRIAL FROM `Commands.rtn`. THE `Instruct.rtn` HEAD OF THE TABLE
## COLLIDES WITH TRACK A.

"Tracks don't touch" is the ruling; on the raw numbers it would be **nominally true and literally
false**. The three fattest `Instruct.rtn` targets are precisely where step 2 works:

| target | why it is not free |
|---|---|
| `opMultiply` | **the step-2 pathfinder itself** (`opMultiply`/`jitMul`) |
| `opPlusPlus` | **parked as `fixIts` F-7**, owner Tony — the duplicated poisoned-iterator guard at `:887`/`:923` |
| `runOP` | carries the **existing seed gate** that step 2's presence-gated fork lands in |
| `opPlus`, `opAssign`, `opDivEQ` | same file, same sweep radius, and the op family is exactly what the slot migration walks |

**So the recommendation is `arrondir` (42) as the primary target, `guard` (22) as the optional
second.** Both are in `Commands.rtn`, neither is an operator, and nothing in the jit campaign
walks either. If Clay or Tony would rather have the bigger `Instruct.rtn` numbers, that is a
sequencing call — **after step 2 lands, not beside it.**

---

## SCHEMA v2 — THE FOUR RULED FIELDS

| field | contract |
|---|---|
| `Status` | `canonical` · `measured <date>` · `open, owner <name>` · **`extracted <date>`** |
| `Evidence` | **verbatim, no reflow.** Numbers, addresses and captured output as they were recorded |
| `CodeSite` | **a field, not prose** — so entry-outlives-method becomes lint-checkable |
| `Rejected` | an alternative is recorded **only once two independent authors have reached for it** |

Naming follows the pilot: `<MethodName><Aspect>`, e.g. `ArrondirContract`, `ArrondirEvidence`.

### ⚠ A1 — `extracted <date>` IS THE BIRTH-STATE OF EVERY MIGRATED ENTRY (Clay, 2026-08-20)

Every minion-migrated entry is born `extracted <date>`. **Promotion to `canonical` or `measured` is
a STATUS CHANGE, NEVER A MOVE** — that is the promotion-not-migration ruling made concrete.

**This settles the one-registry-or-two squabble (Tony, 2026-08-20), and it settles it by adopting
the instinct rather than overruling it.** The case for a separate `CommentsDocs` was that harvested
comments differ from authored design entries in provenance and in curation state. **They do — and
both differences are now first-class fields**: `CodeSite` carries the provenance, `Status` carries
the curation state. ⚠ **The context-rebuild walk of `DesignDocs` filters on `extracted`** — that is
the *named walk* the `Operators`/`bcOPs` split precedent requires, and it is **satisfied by field
query rather than by a second registry.** One registry, two channels, no migration on promotion.

---

## ⚠ THE FIVE CONSTRAINTS, CARRIED INTACT

1. **NOT `genParse.rtn` (1242) and NOT `jitEmitters.rtn` (1066).** The giants are the **payoff**,
   not the trial. A trial that fails on the biggest file teaches nothing about the method.
2. **NOT `ruleActions.rtn`, NOT `GroupActions.rtn`.**
3. ⚠ **SITE-SCOPED WARNINGS NEVER MIGRATE.** A warning stays **one line at its post**, in the
   function it guards. The registry may carry the *why*; the post keeps the *warning*.
   **This is the constraint most likely to bite at method scope**, and the reason is structural:
   an egregiously-commented method interleaves narration with warnings, so the minion is
   classifying line by line inside one block rather than moving a clean prologue. When in doubt,
   **the line stays.** A warning wrongly migrated is a warning deleted from the only place a
   reader was going to meet it.
4. **The verb is a WALKER, not a bare locate.** Sub-entries are **members**, and members are **not
   bare-locatable** — measured: bare name → empty node, `Parent["Child"]` → empty node, iterating
   the parent's members → the real node. A query written the obvious way returns empty nodes and
   looks like data loss.
5. **No double quotes in entry text.** A `"` terminates the string. Apostrophes and semicolons are
   fine.
   ### ⚠ S1 — THE SEAM WITH THE `Evidence` CONTRACT. MEASURED 2026-08-20; AWAITING TONY'S NOD.
   Clay flagged the collision: `Evidence` is **verbatim, no reflow**, and constraint 5 forbids `"`.
   **A migrated comment containing a double quote cannot be both.** Routed to Clod to measure
   rather than to invent.
   **⚠ THE NEGATIVE CONTROL FIRST, BECAUSE IT RERATES THE WHOLE CONSTRAINT.** A `"` inside entry
   text does **not** error — it **silently truncates**:
   ```
   qnB="text with a "double quote" inside it"     reads back as:  text with a
   ```
   **Exit 0, sentinel printed, and the entries before and after are unharmed.** So constraint 5 is
   not a style rule — it is a **silent data-loss hazard**, and it lands squarely on `Evidence`,
   because captured output is exactly where quotes live. **The live example is in this project's own
   docket right now:** F-31's evidence reads ``failed at "else() AND followedBy()"``, which would
   migrate as `failed at ` — losing the discriminating half, silently.
   **PROPOSED CONVENTION (Clod):** substitute `'` for `"`, and append **`[quotes substituted]`** to
   the entry. **Measured to survive verbatim** — apostrophes (`it's`), paired single quotes
   (`'like this'`), brackets, semicolons and colons all read back unchanged, and the note itself
   survives.
   ⚠ **The note is not courtesy — it is what keeps the `Evidence` contract honest.** *Verbatim, no
   reflow* cannot be literally satisfied for quote-bearing text, so the entry must **declare the one
   transformation applied**; without it, a reader comparing entry against source sees a mismatch and
   cannot tell substitution from transcription error.
   ⚠ **AND ONE HARD RULE THE NEGATIVE CONTROL EARNS: GREP THE SOURCE TEXT FOR `"` BEFORE WRITING
   THE ENTRY, NEVER AFTER.** A post-hoc check on the written entry cannot find what was truncated
   away — **the evidence of the loss is gone.**

---

## PROCEDURE — six steps, and step 1 is a full stop

1. **PROPOSE THE PICK AND STOP.** File, method(s), current comment-line count, and one sentence on
   why it is a fair trial. **Wait for a verdict.**
2. **CLASSIFY EVERY LINE** of the target block into exactly one of: **MIGRATE** (design reasoning,
   contract, evidence, rejected alternatives) · **STAY** (site-scoped warnings, and anything whose
   reader is the next person editing this line) · **DELETE** (restates the code, or is dead).
   The classification is the deliverable that gets reviewed — not the diff.
3. **WRITE THE ENTRY** in `incant/designDocs`, schema v2, pilot naming.
4. ⚠ **VERIFY BY WALKING IT.** See the standing warning below. Exit status proves nothing here.
5. **CUT, AND LEAVE A POINTER.** ⚠ **The spelling is RATIFIED and is not a choice:**
   `see DesignDocs: <EntryName>` — the form the tree already ships at `jitEmitters.rtn:1812`.
   **One spelling, stated here, so a second dialect never exists.** A reader at the method finds the
   reasoning without knowing the registry exists, and the uniform marker makes the pointer
   population *countable*.
   *(Chartered as a future fleet row, explicitly NOT the minion's task: a pointer census — every
   `see DesignDocs:` pointer resolves to an entry, every entry's `CodeSite` resolves to a live site,
   with a **deliberately broken pointer as the negative control**, or it is a check that passes by
   finding nothing.)*
6. **FLEET CHECK** (`genLadder/pop.sh`), diffed against a capture banked **before** step 5.
   Prediction on record: **unmoved** — comments are not code. A red is news.
   ⚠ **A3 — AND THE CANARY FIRST, BY NAME (Clay, 2026-08-20):** after any retok of a touched file
   and **before trusting the fleet run**, `grep -c '^extern' GroupRules.h` against the canary count
   — ⚠ **READ IT OFF THE TREE, DO NOT TRUST A NUMBER IN THIS FILE.** It was **308** at 2026-08-20
   and is **333** at 2026-09-04; it has moved five times in between. Take the before-capture in
   the same stroke (rule H14). **This is bear-trap #29's exact territory** — a comment in the wrong
   position wiped the extern block **288 → 0** at `tok` exit 0 and BUILD SUCCEEDED, and the canary
   was the only tell. The minion's entire diet is comment edits in `.rtn` files. **The charter says
   it here, where the minion reads, rather than relying on the operator remembering why the canary
   exists.**

## PAUSE-AND-ASK GATES

- after step 1, always
- after step 2 if any line is genuinely ambiguous between MIGRATE and STAY
- if the target turns out to carry a **finding** rather than narration — that goes to
  `docs/fixIts.md` and the minion continues; **capture, do not chase**
- before touching a second method

---

## ⚠ STANDING WARNING — PARSE-GREEN IS NOT SHAPE-CORRECT, AND THIS REGISTRY HAS ALREADY PAID

**Measured 2026-08-11 on the first entry.** Three missing terminating semicolons meant
`EmissionPrinciple`, `DisplayLayout` and `DisplayEvents` each **nested what followed instead of
ending itself**. The run was **exit 0, sentinel printed, stderr empty** — and the tree said
`EmissionPrinciple` governed layout, targets and events, which is not what anyone wrote.

**So the acceptance test is a WALK, not a run:** load the registry and walk the new entry, asserting
the **top-level member count** and each child's **own count** against what was drafted. `incant/ddProbe`
and `incant/ddProbe2` already do this shape; copy them rather than writing a third.

⚠ **And copy the probe, not just the idea — this project's third-named failure class is
COPY THE IDIOM, LOSE THE HELPER.** A probe that silently loses its check function prints nothing
and passes.

## NOT IN SCOPE

- any second file
- the query verb over `designDocs` (later work, nobody's task)
- reflowing or "improving" comments that are staying
- `docs/*.md` — this charter is about **comments in code**, not the markdown fleet

## PROVENANCE

Scope amendment and candidate pool: Tony, 2026-08-17, relayed via Fearless. Precedent:
`jitFieldMethod` pilot, migrated 2026-08-15, live at `incant/designDocs`. Schema v2 and the
walker ruling: 2026-08-15 seal. Measured candidate table and the Track-A collision finding: Clod,
2026-08-17.
