# Gap B — Phase R rung records

**Charter:** `docs/gapBCharter.md` §2 (one family per rung), §4 (two numbers, every rung).
**Taxonomy:** `docs/gapBPhaseT.md` (the family table, delivered 2026-08-09).
**Rung POP:** `genLadder/gapB.sh` — its own harness, deliberately not folded into `pop.sh`.

⚠ **EVERY RUNG RECORDS ITS BLAST RADIUS, and rung 1 sets the precedent** (Tony, 2026-08-09):
the deliverable includes a full before/after fleet diff stated as the install's impact record.
**Exit codes do not discharge it — the record is the diff, even when the diff is "nothing moved
but the targets."** This is the only cheap place to establish the habit before 44 more inherit it.

---

## RUNG 1 — FAMILY B (LITERAL) · ✅ GREEN · 2026-08-09

**Population:** `SemI` (`grammar:84` `SemI=";";`) · `loopOnAttributes` (`:134`
`loopOnAttributes="attributes";`) · `loopOnMembers` (`:135` `loopOnMembers="members";`)

### The treatment, and why this family was chosen first

A rule whose **own data** is a quoted literal matches that literal — which is **precisely what
`planTerm` already emits for a literal in TERM position**. So the family needs **no new plan kind
and no new support function**: it reuses `LIT`/`LITTO`, and the LIT-vs-LITTO split is taken from
the rule's own `rStuff.noLabel`, **mirroring `planTerm` rather than re-deciding it**. That reuse is
the whole reason this was rung 1 — the charter asked for the smallest family with a fully-known
treatment.

**The test is `rule.isSTRING`, not `rule.data`, and the narrowness is deliberate.** Three
constructs used to share one refusal message; the taxonomy exists so each gets its own treatment
*and its own refusal text*. Widening to `rule.data` would re-merge them on day one — and it would
pass every positive row in the rung while doing it, which is why the rung carries five negative
controls.

**Plan shape produced** (identical across all three):
```
  SEQ SemI
    label=SemI
    LITTO ;
      at=0
      slot=SemI
```
⚠ **`at=0` is a MARKER, not an index.** Everywhere else `at` is a baked `rule[]` index and term
indices are 1-based, so 0 cannot collide with one; it reads as *"the rule's own data, not a term
slot"*. **Emit is out of scope for this charter (§4)** and belongs to genKantParse v1 — flagged
here so the emit side inherits the question **stated** rather than discovering an index that
indexes nothing. Related and already on the board: **`litTo` still has no support-library
implementation**, so the labelled-literal road is planned but not yet paved.

⚠ **Bear-trap #26 was the live risk here and it did not bite.** `rule.text` on a data-carrying node
returns the value (`;`), not the tag (`SemI`). Had it returned the tag, the plan would have been
wrong *in the plausible-looking way* — which is why the rung asserts **the literal text by name**
rather than merely that a plan exists. "It planned" cannot tell `LITTO ;` from `LITTO SemI`.

### Ruling-4 numbers (§4 — two numbers, never conflated)

| | before | after |
|---|---|---|
| **total plan-layer refusals** | 97 | **94** |
| **fully-plannable rules** | 13 of 78 | **16 of 78** |

Partition closes both sides: `16 + 62 = 78`. Rule-level-data refusals **21 → 18**.

✅ **THE H4 OBLIGATION IS DISCHARGED — both numbers are now PRINTED AS SCALARS** by
`incant/phaseA` (`TALLY refusals = N` / `TALLY plannable = N`), not derived by counting output.
- `planTally` counts at **three sites, not seventeen**, licensed by a **measured invariant**: every
  refusal line is followed by a `return null`, and `planRule` stops at its first bad term, so
  `total == planRule nulls + planTerm nulls`. Verified against the pre-change corpus before being
  relied on — `97 == 65 + 32`, with `65 ==` distinct rules refused and `32 ==` `unclassified`.
- ⚠ **The invariant is asserted, not assumed.** A future two-line refusal path would break it
  silently *and move the metric with it*, so the rung **cross-checks the printed scalar against the
  grep every run**. The cheap instrument guards the cheap counter.

⚠ **AND THE TALLY'S FIRST DRAFT BROKE THE FIXTURE'S OWN COMPLETENESS GUARD.** The lines were
originally prefixed `PLAN TALLY`, and phaseA's A1 guard counts `PLAN <name>` against `DONE <name>`
— so it read **80 PLAN / 78 DONE**: *the instrument that detects a truncated walk reported a
truncated walk, caused by the instrument added beside it.* Renamed to `TALLY`. Caught on the first
run because A1 is asserted from outside; it would otherwise have been a standing false alarm.

### The rung POP — `genLadder/gapB.sh`, 22 checks, exit 0

H1 binary echo · H2 sentinel checked first and by name · A1 asserted from outside (PLAN == DONE ==
78) · Amendment A's **reach** clause (the fixture must demonstrably arrive at the Gap B branch) ·
both ruling-4 scalars by value · both invariant cross-checks · partition closure · six Family B
rows (literal text **and** slot, per rule) · five negative controls · **self-certification at the
foot** (fewer than 20 green checks recorded is a failure, which a vanished helper set cannot
satisfy).

✅ **H7 NEGATIVE CONTROL — MEASURED, NOT INFERRED.** Every assertion was run against the
mechanism-absent capture (phaseA's output from the binary immediately before the treatment landed):

| row | mechanism absent | rung wants | |
|---|---|---|---|
| `TALLY` lines | 0 | 2 | RED |
| ruling-4 refusals | 97 | 94 | RED |
| ruling-4 plannable | 13 | 16 | RED |
| Gap B branch reach | 21 | 18 | RED |
| Family B ×3, LITTO literal | *no LITTO node* | `;` `attributes` `members` | RED ×6 |

**11 rows red without the mechanism** — and ⚠ **the five negative-control rows STAY GREEN on that
same capture**, which is what makes it a control rather than a guaranteed failure. The rung
**discriminates**; it is not a script that reddens on any old input.

### ⚠ BLAST RADIUS — THE INSTALL'S IMPACT RECORD (the rider, and the precedent)

Full fleet captured before and after, every stream diffed.

**Exit statuses: IDENTICAL across all 13 entry points.** But exit codes do not discharge the
rider, so:

| stream | verdict |
|---|---|
| **`phaseA.err`** | **the intended change, and ONLY it** — three `REFUSE rule … isSTRING` lines become three plans, plus the two new `TALLY` lines. **Nothing else in the 78-rule walk moved.** |
| `pop.out` | H1 binary echo + pop.sh's own **working-tree status readout** (uncommitted-file count). A report, not an assertion. |
| `ladder.out`, `completePop.*`, `containerPop.out`, `formsPop.out`, `mixed.out`, `recordPop.out` | **H1 binary echo only**, plus **PIDs** in the shell's segfault lines for the *pinned* crashers (JXD-1; completePop's two known ones). Correctness-unrelated by construction — H3's "assertion that moves for reasons that say nothing about the answer", which is why no harness diffs them. |
| `oneTest`, `jsonTest`, `kant8T`, `emitAll`, `tree`, `printPop` (+ every `.err` not named above) | **byte-identical** |

**Statement of impact: the install touched exactly its three targets.** No baseline moved, no
target was re-pinned, no harness changed verdict.

### Fleet at rung close
```
sh genLadder/gapB.sh           22 checks, exit 0     NEW -- the Phase R rung POP
sh jitLadder/ladder.sh        173 checks, exit 0
sh genLadder/pop.sh            33 green / 1 parked (exit 1, the same 3 owned reds)
sh genLadder/mixed.sh           7 checks, exit 0
sh genLadder/completePop.sh   123 swept · 3 abandoned · 2 missing sentinels · exit 1
sh genLadder/tree.sh · printPop · containerPop · recordPop · formsPop      exit 0
<binary> incant/oneTest · jsonTest · kant8T · phaseA · emitAll             exit 0
```

### What rung 1 did NOT do
- **No emit-side work** — §4 puts it out of scope; `at=0` and `litTo`'s missing implementation are
  flagged **for** genKantParse v1, not solved here.
- **No installs.** §1 is unchanged: this charter buys **plannability**, and installability remains
  gated by the mixed-config child-drop defect. **16 plannable is not 16 installable.**
- **The metric is still 0/47.** Three rules became plannable; none crossed.

### Next rung
**Family C (CHARACTER SET, 4)** or **Family A (REFERENCE, 5)** — A is larger but is §2.5's ITERATE
case and has a spec; C is §2.5's ACCUMULATE case and also has one. ⚠ **§3's ordering aims at
`InvokeArg`'s alternation via `NumbeR`/`ANYtoken`/`SemI`** — `SemI`'s **rule-level** block is now
closed, but the **double-block rider** says `SemI` and `ANYtoken` are each blocked **twice**, and
`SemI`'s term-level half is still open. **Rule-level work alone closes neither cascade head.**

---

## RUNG 2 — FAMILY C (CHARACTER SET) · ⚠ **RECON ONLY, NOT BUILT** · 2026-08-11

**Opened on SEQ 50 item 6, then RE-ORDERED by SEQ 51 before any code was written.** Loop closure
on one rule became the session's work and the rule list its seal, so this rung's *implementation*
is unstarted. **What follows is measurement taken before the re-order**, banked so the next
executor starts at the treatment instead of re-deriving the ground. **Nothing here is a plan
decision.**

**Baseline re-measured today, same binary:** `TALLY refusals = 94` · `TALLY plannable = 16` —
exactly rung 1's close, so the ground has not moved.

### ⚠ FINDING 1 — THE RULE-LEVEL `isSET` REFUSAL SITE HOLDS **SIX** RULES, NOT FOUR

`planRule`'s `if !rule.isSTRING` refusal (`genParse.rtn:541-543`) is where Family C waits. Its
current occupants, measured rather than counted from the taxonomy:

```
  REFUSE rule BrancheS   -- rule-level data isSET      <- EVICTED (container, paid)
  REFUSE rule followedBy -- rule-level data isSET      <- Family C
  REFUSE rule Modifier   -- rule-level data isSET      <- Family C
  REFUSE rule nameSet    -- rule-level data isSET      <- Family C
  REFUSE rule numberSet  -- rule-level data isSET      <- Family C
  REFUSE rule PoweR      -- rule-level data isSET      <- Family D (SET+SUBFIELDS)
```

⚠ **SO `if rule.isSET` IS THE WRONG TEST, AND IT WOULD PASS EVERY POSITIVE ROW WHILE BEING WRONG**
— rung 1's exact lesson, arriving one rung later on a different kind. `BrancheS` is a **bin**
(`grammar:96`, `BrancheS bin`) and `PoweR` carries **sub-fields with their own data**
(`grammar:32`, `PoweR=[eE] sign?=[+-] power=[0-9]+;`). Both belong to other families with other
treatments.

**Candidate discriminator, offered as recon and NOT as a ruling:** Family C's four members carry
**no terms at all** — their data *is* their content — while `PoweR` has two and `BrancheS` is a
container classified earlier. `countRuleTerms(rule) == 0` therefore separates them, and
`planRule` already computes it one branch below. **It wants measuring against all six before it is
believed**, per this file's own standing on narrow tests.

**Negative controls the rung owes:** `BrancheS` and `PoweR` must stay refused **and refuse for
their own reasons**, not fall through a widened test.

### ⚠ FINDING 2 — `followedBy` REFUSES IN **TWO POSITIONS**, AND RULE-LEVEL WORK CLOSES ONLY ONE

Measured: besides its rule-level refusal above, `followedBy` refuses **in TERM position** —
`REFUSE followedBy -- inline group / character data isSET (named future kind)` — and that refusal
is the first blocker for **9 rules** (`BasicElse`, `CerR`, `DEBUG`, `DEF`, `DO`, `FOR`, `IF`,
`WhilE`, `PrinT`).

⚠ **THIS IS H9's COROLLARY WITH A NAME ATTACHED, AND IT PREDICTS THE RUNG'S NUMBER.** Making
`followedBy` plannable **as a rule** does nothing for the 9 rules that reference it **as a term**:
different site, different test (`planTerm`'s `term.data` branch), and `planTerm` refuses
character-level data **deliberately**, because §2.5's ACCUMULATE-vs-ITERATE conflation *"yields a
parser that accepts correctly and builds wrongly."* **So the expected movement is refusals 94 → 90
and plannable 16 → 20 — four, not thirteen** — and a rung that reports otherwise has widened
something it should not have.

### WHAT FAMILY C DOES NOT INHERIT FROM RUNG 1

Rung 1 was cheap because `planTerm` already emitted `LIT`/`LITTO` for a literal in term position,
so the family reused a kind. ⚠ **There is no SET kind to reuse** — `genParse.rtn` has no `isSET`
branch in `planTerm` at all (it refuses there, on purpose, per above). **Family C needs a NEW plan
kind**, which is the §2.5 ACCUMULATE case: loop *inside* the matcher, one token spanning the run.
Open at the row and not decided here: whether the rule's own repetition (`numberSet=[0-9]+` carries
`+`, `nameSet=[a-zA-Z0-9]` does not) rides the node as `min`/`max` or is inherent to the kind.
