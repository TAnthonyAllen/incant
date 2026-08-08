# Gap B Charter — rule-as-data (§4.1, rung 5)

**Authority:** Tony (director), rulings ratified 2026-08-08 · drafted by Clay under those rulings ·
supersedes every prior informal statement of Gap B, including the three-specimen framing.
**Standing input:** SEQ 42's staging census — **21 censused, PROVISIONAL** — across six data kinds:
isGROUP 9 · isSET 6 · isSTRING 3 · isCOUNT 1 · isCHAR 1 · isANY 1. 45% of the 47.
The three previously-quoted specimens (NumbeR/ANYtoken/SemI) were a frontier, not the set (H9 corollary).

⚠ **AMENDMENT B (2026-08-08, ratified) — THE TABLE'S COUNT IS THE COUNT.** 21 is the censused
figure, not the chartered population. **Evictions land in the family table as ROWS WITH REASONS,
never as silent renumbering** — a population that shrinks without a named cause is H9's overcount
running backwards, and the charter would report progress it did not make. Three are already
identified by Phase T (`docs/gapBPhaseT.md`, finding T-2):

| rule | disposition | reason |
|---|---|---|
| `BrancheS` | **CONTAINER — already paid** | `grammar:96` is `BrancheS bin`; containers closed with `containerTo` (GAP A / CT, 2026-08-07). Its refusal is a container refusal wearing a rule-as-data message. |
| `NewGroup` | **DEFERRED** | `grammar:58` is `NewGroup TraiT@` — carries the promote mark, which **IT-3 holds under a named expiry**. No chartered work for a shape a standing expiry deletes. |
| `Any` | **POPULATION QUESTION — ESCALATED** | Censused, but **absent from `incant/grammar` entirely**. That is a **census-instrument** question, not a family question, and it is asked of the instrument before it is asked of the taxonomy. |

---

## 1. SCOPE (ruling 1) — plannability only, stated in the charter's own voice

**This charter closes plan-layer refusals. It does not open installs.** Installability is
separately gated by the mixed-config child-drop defect (SEQ 42, silent node loss, unchartered as
of this writing) and by the migration-unit ruling, which stands as IA-0 pending that defect's
resolution. A future reader seeing "Gap B closed" may conclude ONLY that no rule refuses on
rule-level data grounds — not that anything installed, and not that anything may.

Plannability and installability are two gates. This charter buys the first. (SEQ 42, req. 3.)

## 2. SHAPE OF THE WORK (ruling 2) — taxonomy before repair

**Phase T (first, gating):** classify all 21 rules into shape families. §2.5's two families
(character-level ACCUMULATE: loop inside the matcher, one token spanning the run · group-reference
ITERATE: loop outside, one fresh label per pass) are known to cover 8 of 21. The remaining 13 are
expected to mint NEW families — inline-group (9, explicitly not the iterate case) is the leading
candidate; the scalar kinds (isSTRING/isCOUNT/isCHAR) another. Minting rule: **a family requires
more than one member** (the structured-value precedent — one instance is not a kind); singletons
stay OPEN rows in the taxonomy until a second member or a ruling.

Phase T's deliverable: the family table — every one of the 21 in exactly one family or OPEN,
each family with its named plan-layer obligation. **No repair work begins in any family before
the table exists.** Three constructs currently share one refusal message; the taxonomy is what
makes that unsayable going forward — each family gets its own refusal text as it gets its own
treatment.

**Phase R (per family, each its own rung):** plan-layer treatment for one family at a time,
smallest sufficient family first within the ruling-3 ordering. Convert, gate, then install
discipline applies at the plan layer: each family's treatment proves against the census fixture
before the next family opens.

## 3. ORDER OF ATTACK (ruling 3) — by target, aimed at First Light

Priority is the family set blocking **InvokeArg's alternation** — UnaryXP's second term and the
rule-level refusals of NumbeR/ANYtoken/SemI — because the goal is the first fully-plannable
reader-bearing alternation, not the fastest-falling refusal count. Bulk families (isGROUP's 9,
isSET's 6) queue behind the target set unless Phase T shows overlap.

⚠ **THE DOUBLE-BLOCK RIDER (SEQ 42, req. 2 — load-bearing):** ANYtoken and SemI are each blocked
TWICE — rule-level (this charter's surface) AND term-level (planTerm's inline-group/character-data
refusal). **This charter scopes BOTH blocks for those two rules.** Rule-level work alone closes
neither cascade head, and a charter that omitted the term-level half would report success while
the target alternation stayed shut. The term-level work for these two is in-scope even where its
family would otherwise queue later.

## 4. METRIC AND BOUNDARY (ruling 4)

**Two numbers, every rung, never conflated:**
- total plan-layer refusals (progress; expected to fall unevenly)
- fully-plannable rules (the gate; may not move for several rungs, and that is not failure)
H9's corollary is standing law here: a refusal census reports frontiers; closing a gap reveals
the next refusal. Total-refusals-falling is real and is not the same measurement as any rule
becoming plannable. Both numbers appear in every STATUS.

**Surface boundary:**
- Default surface: `planRule` / `planTerm` and the classification walk.
- Support-library additions: IN scope where a family needs one (the containerTo pattern), but
  each lands as its own named rung with its own POP — never folded silently into a family rung.
- **OUT of scope, explicitly: the emit side of data rules** — the peek / match-class / consume /
  capture quartet and everything downstream of a plan. That work belongs to genKantParse v1
  (SEQ 43 scope) and stays there. This exclusion is what keeps the charter from swallowing the
  parser campaign it serves.

## 5. ADJUDICATION AND STANDING RULES

- ⚠ **AMENDMENT A (2026-08-08, ratified) — THE RULING-4 INSTRUMENT SLOT IS OPEN, NOT ASSUMED.**
  The original text named `incant/censusScratch` as the per-rung oracle. **That fixture does not
  exist** — renamed to `incant/popScratch` (wakeup 08-05). The defect is Clay's and its cause is
  worth keeping: **the name was cited from a sealed wakeup instead of checked**, which is this
  project's own doubt-the-instrument rule failing inside a governing document.
  Replaced with: *the ruling-4 instrument is whichever fixture demonstrably produces **BOTH**
  numbers (total plan-layer refusals · fully-plannable rules). Clod verifies —* **`incant/phaseA`
  is the candidate** *(SEQ 42's partition numbers came from it), and* **`incant/popScratch` is on
  record as "a sample, never a census"** *— and this section then names the instrument* **BY
  MEASUREMENT.** **Until that verification lands the slot is OPEN**; no rung may cite an
  unverified oracle.
- H9 applies to the taxonomy itself: families match the idiom family, not the surface form.
- A red localizes to one cause: no family rung opens while another family's rung is mid-flight.
- Charter amendments are Tony's; findings that want to amend it route as findings first.

## 6. RELATION TO THE BOARD

Discharging this charter unblocks SEQ 41 step 3 (genKantParse v1) to its full population and is
the main-line dam. It does NOT discharge: the child-drop hunt (separate, unchartered), the
migration-unit ruling (waits on that defect), or installs (gate 2). First Light remains
generator-agnostic and remains the metric moving off 0/47 — this charter is the largest single
piece of the road to it, and it is only a piece.
