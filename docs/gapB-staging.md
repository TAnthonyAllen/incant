# Gap B — staging measurement for the director's charter

> # ⚠⚠ CORRECTION ON TOP — 2026-08-09. THE RULE→KIND TABLE BELOW IS WRONG FOR 13 OF 21.
> **RULED (Tony, 2026-08-09, T-0 adjudication, ruling 1): the re-measurement against the live
> binary is the truth of record for rule→kind across the Gap B population. The table in this file
> is SUPERSEDED.** It is left in place unedited, per §5 routing and the `f8cf727`/`a9fa6ce`
> precedent — **the wrong table stays legible with the correction on top; no silent overwrite, no
> tidying.**
>
> **What is still good here:** the **counts** (`isGROUP 9 · isSET 6 · isSTRING 3 · isCOUNT 1 ·
> isCHAR 1 · isANY 1 = 21`) reproduce **exactly** on the byte-identical binary, so every headline
> built on them survives — 21 rules, `isSET` really is twice `isSTRING`, H9's lesson stands.
> **What is not:** every statement that groups *named rules* by kind. 8 of 21 are filed correctly;
> **13 are filed under the wrong kind.**
>
> **Corrected memberships, the family table, and the evidence: `docs/gapBPhaseT.md` finding T-0.**
> The cause of the mis-assignment stays **UNDIAGNOSED** — two explanations were tested and both
> falsified (it did not read the term-level axis; it is not a global sort sliced by count), and per
> the ruling **nobody guesses a third into the file.**
>
> ⚠ Also corrected by that finding: **`Any` is not a grammar rule** (C++-minted,
> `GroupMain.twk:156-158`) and is **EVICTED** from the campaign population by ruling of the same
> date. And the **"45% of the 47"** line below **mixes axes** — the 21 derives from the 78
> (Grokking's registry population), the 47 from `incant/grammar`'s text; GM-31 warns in bold that
> the two are not the same measurement. See `gapBPhaseT.md` finding T-3.

**Status:** MEASUREMENT ONLY · asOf 2026-08-08 · SEQ 41 step 1, under fence 1
**⚠ THIS IS NOT THE CHARTER AND MUST NOT BE READ AS ONE.** SEQ 41 fence 1 puts the charter with
the director and forbids plan-layer edits before it exists. **No `planRule`/`planTerm` line was
touched.** This file exists so the charter is drafted against numbers instead of against the
three rule names everyone has been quoting.

**Source:** `incant/phaseA`, exit 0, run against `~/bin/incant` (1316624 bytes, 2026-08-08 07:57),
the same binary the 162-check ladder is green on. Reasons harvested from `planRule`/`planTerm`'s
own refusal lines — the refusals *are* the instrument, which is why this is cheap.

---

## THE HEADLINE: GAP B IS 21 RULES ACROSS SIX DATA KINDS, NOT 3 RULES ACROSS TWO

Every statement of this gap so far — the 08-07 seal, IA-1's gate note, SEQ 41 step 1 — names
**`NumbeR`/`ANYtoken`/`SemI`** and **`isGROUP`/`isSTRING`**. Both are the *specimens that were
looked at*, not the population. Measured:

| rule-level data kind | count | rules |
|---|---|---|
| `isGROUP` | **9** | `ANYtoken` `Attributes` `BrancheS` `followedBy` `loopOnAttributes` `loopOnMembers` `NewGroup` `NumbeR` `Start` |
| `isSET` | **6** | `Any` `counter` `Looper` `nameSet` `numberSet` `ShortcuT` |
| `isSTRING` | **3** | `ANYstring` `InitiatE` `SemI` |
| `isCOUNT` | 1 | `Modifier` |
| `isCHAR` | 1 | `PoweR` |
| `isANY` | 1 | `FloaT` |
| **total** | **21** | |

Against a denominator of **47** (IA-4), rule-as-data alone accounts for **45% of the grammar**.

⚠ **`isSET` (6) is twice `isSTRING` (3), and neither the seal nor the brief mentions it.** The
three quoted specimens happen to be one `isGROUP`, one `isGROUP`, one `isSTRING` — a sample that
misses the second-largest kind entirely. **Same failure family as RULE H9:** the census matched
the specimens that had been read rather than the idiom family.

---

## ⚠ §2.5 IS A PARTIAL MAP OF THIS GAP, AND THAT IS THE CHARTER'S FIRST PROBLEM

SEQ 41 step 1 carries §2.5's two shapes into the charter — *character terms **accumulate**, group
references **iterate**, conflate them and the parser accepts correctly and builds wrongly*. That
warning is real and it does not cover the population:

| family | kinds | count | §2.5 says |
|---|---|---|---|
| **accumulate** | `isSET` `isCHAR` `isANY` | **8** | ✅ covered — loop *inside* the matcher, one token spanning the run |
| **inline group** | `isGROUP` | **9** | ❌ **NOT §2.5's iterate case.** `planTerm` classifies a *reference* as `CALL` **before** the data test and names what is left over — group content with no reference — a **"named future kind"**, explicitly *"not the same thing as a call and must not quietly become one."* §2.5's iterate row is about references; this is not one. |
| **scalar data** | `isSTRING` `isCOUNT` | **4** | ❌ **in neither family.** §2.5 has no row for a rule whose own data is a string or a count. |

**So "rule-as-data" is at least three distinct constructs wearing one refusal message**, and
**13 of the 21 rules are in the two families §2.5 does not describe.** A charter that inherits
§2.5's two-shape framing will be sized for 8 rules and meet 21.

**The recommendation this measurement supports** (director's to accept or reject): **give each
family its own rung**, in the order `accumulate (8) → scalar (4) → inline group (9)`. Accumulate
is the one with a written spec and a worked precedent (`testMacro`'s three users are exactly the
three accumulating kinds). Inline group is last because it is the only one that is genuinely a
*new construct* rather than a new spelling — and because `planTerm`'s comment already refuses to
let it collapse into `CALL`, which is the mistake it would otherwise invite.

---

## THE CASCADE IS CONFIRMED — AND IT IS A FRONTIER, NOT A DEPENDENCY GRAPH

The brief's cascade is real, measured:

```
ANYtoken  (rule-level isGROUP)  →  blocks  Iterate · ANYorNum · UnaryXP
SemI      (rule-level isSTRING) →  blocks  StatemenT · Xpress
```

⚠ **But H9's corollary applies and it bites here specifically: a refusal census reports the
FIRST blocker, not the blocker set.** Those five rules are refused *at their first unclassifiable
term*. Closing rule-as-data for `ANYtoken` and `SemI` **reveals their next refusal; it does not
unblock them.** A charter claiming "closing Gap B unblocks Iterate/Xpress/ANYorNum/StatemenT/
UnaryXP" is **unsupported by this measurement** and needs those five re-run after the close.

⚠ **AND A SECOND-ORDER FACT THE CASCADE STATEMENT HIDES: `ANYtoken` AND `SemI` ARE EACH BLOCKED
TWICE, ON BOTH AXES.**

```
REFUSE rule ANYtoken -- rule-level data isGROUP      <- as a RULE
REFUSE      ANYtoken -- inline group / character data isGROUP   <- as a TERM
REFUSE rule SemI     -- rule-level data isSTRING     <- as a RULE
REFUSE      SemI     -- inline group / character data isSTRING  <- as a TERM
```

**Fixing the rule-level side leaves the term-level side standing**, so neither of the two named
cascade heads is closed by rule-level work alone. **Both axes, or neither.**

---

## THE TERM-LEVEL POPULATION, which the gap statement omits entirely

16 term refusals across 13 distinct names:

| term data kind | count | names |
|---|---|---|
| `isGROUP` | 9 | `ANYtoken` `definitions` `dtext` `min` `NewGroup` `ShortcuT` … |
| `isSET` | 4 | `first` `followedBy` `Modifier` `tik` |
| `isSTRING` | 3 | `loopOnAttributes` `SemI` `zero` |

⚠ **Six names appear on BOTH lists** (`ANYtoken` `followedBy` `loopOnAttributes` `Modifier`
`NewGroup` `ShortcuT` `SemI`). The two axes are not independent populations and **must not be
counted as `21 + 13`.**

---

## EVERYTHING ELSE REFUSING TODAY, so the charter can see what it is *not* buying

| reason | count | note |
|---|---|---|
| term `<X>` unclassified | 26 | the **frontier** class — each is a rule stopped at its first bad term. Overlaps Gap B heavily but is not reducible to it. |
| no terms at all | 6 | not Gap B |
| unmaterialised terms | 6 | not Gap B |
| parseAction | 2 | §2.8, tail-position rule |
| registry container | 1 | CT closed `isBIN`; `isREGISTRY` still refuses |
| upTo/upToOver | 1 | beyond the frontier in both back ends |

**Metric context:** 0/47 installed. Gap B is the largest single block, and after the SEQ 41 step 2
result it is **also not sufficient on its own** — a plannable rule still cannot cross alone,
because partial installs lose nodes (`genLadder/mixed.sh`). **Plannability and installability are
now measured as two separate gates**, and the charter should say which one it is buying.

---

## WHAT IS OWED BEFORE ANY EDIT

1. **The charter** — director's, fence 1.
2. **A decision on the three families**, because they cannot share one rung without re-creating
   §2.5's accept-correctly-build-wrongly failure.
3. **A ruling on the two axes** — rule-level and term-level are the same construct seen from two
   positions, and closing one alone closes no rule that carries both.

**No plan-layer edit is proposed here and none was made.**
