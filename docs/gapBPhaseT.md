# Gap B — Phase T (the family table)

**Status:** T-1 **ANSWERED** · family table **DELIVERED, with 3 OPEN rows named** · asOf 2026-08-09
**Charter:** `docs/gapBCharter.md` ruling 2 (taxonomy before repair) · ruling 4 (two numbers, every rung)
**Instrument:** `incant/phaseA`, exit 0, sentinel present, **78 PLAN / 78 DONE** (walk complete),
run against `~/bin/incant` → DerivedData `Debug/Groups`, **1316624 bytes, 2026-08-08 07:57** — the
**byte-identical binary** the SEQ 42 census was taken on. No plan-layer line was edited.

---

## ⚠⚠ FINDING T-0 — THE SEQ 42 CENSUS'S RULE→KIND MAPPING IS WRONG FOR 13 OF 21.
## THE COUNTS ARE RIGHT. THE MEMBERSHIPS ARE SCRAMBLED.

This is reported **first** because every other statement in this file, in the charter, and in
T-1's original framing was built on top of it.

`docs/gapB-staging.md` reports the six-kind partition as counts **and** as named rule lists. Re-run
today on the same binary and the same fixture, the **counts reproduce exactly** —
`isGROUP 9 · isSET 6 · isSTRING 3 · isCOUNT 1 · isCHAR 1 · isANY 1 = 21` — and the **memberships do
not**. Eight rules are filed correctly; **thirteen are filed under the wrong kind.**

| rule | staging census says | `planRule` actually says | |
|---|---|---|---|
| `ANYtoken` `Attributes` `nameSet` `NewGroup` `NumbeR` `numberSet` `SemI` `Start` | — | — | ✔ **8 correct** |
| `Any` | isSET | **isANY** | ✗ |
| `ANYstring` | isSTRING | **isGROUP** | ✗ |
| `BrancheS` | isGROUP | **isSET** | ✗ |
| `counter` | isSET | **isCOUNT** | ✗ |
| `FloaT` | isANY | **isCHAR** | ✗ |
| `followedBy` | isGROUP | **isSET** | ✗ |
| `InitiatE` | isSTRING | **isGROUP** | ✗ |
| `Looper` | isSET | **isGROUP** | ✗ |
| `loopOnAttributes` | isGROUP | **isSTRING** | ✗ |
| `loopOnMembers` | isGROUP | **isSTRING** | ✗ |
| `Modifier` | isCOUNT | **isSET** | ✗ |
| `PoweR` | isCHAR | **isSET** | ✗ |
| `ShortcuT` | isSET | **isGROUP** | ✗ |

**Evidence** — the 21 refusal lines verbatim, `incant/phaseA` stderr, grep `"rule-level data"`:
```
  REFUSE rule Any              -- rule-level data isANY
  REFUSE rule ANYstring        -- rule-level data isGROUP
  REFUSE rule loopOnAttributes -- rule-level data isSTRING
  REFUSE rule Modifier         -- rule-level data isSET
  REFUSE rule PoweR            -- rule-level data isSET
  REFUSE rule counter          -- rule-level data isCOUNT
  REFUSE rule FloaT            -- rule-level data isCHAR
        ... (21 lines total; full capture reproduces with one grep)
```

**The measured mapping is internally coherent and the census one is not**, which is the
independent check that says which is right rather than merely which is newer:
- `loopOnAttributes="attributes"` and `loopOnMembers="members"` are **string literals** and measure
  **isSTRING**. The census filed both **isGROUP**.
- The rule literally named **`Any`** measures **isANY**. The census filed it **isSET** and gave
  isANY to `FloaT`.
- `PoweR`'s data is the character set `[eE]` — and `GroupMain.twk:162` sets
  `characterSet = new("eE")` on it in the bootstrap. **isSET** is right; the census said isCHAR.

**Two rival explanations were tested and both fail**, so the cause is recorded as **UNDIAGNOSED**
rather than guessed (the standing asymmetry: structural claims hold here, causal ones run about even):
- *"The census read the term-level axis instead."* **No.** Where a rule refuses on both axes the two
  kinds **agree** — `ShortcuT` isGROUP/isGROUP, `followedBy` isSET/isSET, `Modifier` isSET/isSET,
  `loopOnAttributes` isSTRING/isSTRING.
- *"The lists are one global sort sliced by count."* **No.** Each census group is internally
  alphabetical but the groups are not contiguous in any single ordering.

⚠ **WHAT THIS COSTS, STATED PLAINLY.** The counts were right, so every headline built on them
survives: **21 rules, 45% of the 47, `isSET` really is twice `isSTRING`, H9's original lesson
stands.** What does **not** survive is any statement that grouped *named rules* by kind — which
includes **T-1's entire original premise** (below) and **one row of Amendment B** (`BrancheS`
"censused isGROUP" — it is isSET; the container reasoning is unaffected, the cited evidence is not).

⚠ **AND THE INSTRUMENT LESSON, which is the same one the charter already paid for once.** Amendment
A exists because a fixture name was **cited from a sealed document instead of checked**. This is
that failure's twin one layer down: a *table* was cited from a sealed document instead of re-run.
The re-run cost **one grep against a fixture that already existed** and needed no new instrument.
**A committed measurement is evidence about what someone saw, not about what is true** — bear-trap
#21's compare-trees-not-labels, applied to numbers.

---

## ✅ T-1 — ANSWERED: `planRule` READS THE **DECLARED** KIND. ONE PARTITION SERVES.

**The question (charter ruling 4 / SEQ 47):** when `planRule` refuses on rule-level data, is the
kind it reads the **RESOLVED/transitive** one (chased through a reference chain to its terminal) or
the **DECLARED** one (data on the rule's own node)?

**The refusal is a single field read, with no chasing anywhere in the function** —
`genParse.rtn:517-519`:
```
    if rule.data {
        cerr "  REFUSE rule " rule.tag " -- rule-level data " dataName(rule.data) …
        return null; }
```
So the question is not which of two kinds the function picks. It is **what `rule.data` holds**, and
that is measurable.

### The discriminating measurement — a referent that has NO data at all

A rule where declared and resolved coincide discriminates nothing. The discriminator used is
sharper than a divergence: **five reference-shaped rules, four of whose referents carry no
rule-level data whatsoever** (they pass line 517 and go on to plan or to refuse at term level).
**Resolution cannot manufacture a kind from a referent that has none.**

| referring rule | grammar | its `rule.data` | referent's `rule.data` |
|---|---|---|---|
| `Looper=ANYtoken;` | :132 | **isGROUP** | isGROUP |
| `ANYtoken=NamE;` | :92 | **isGROUP** | **NONE** — `NamE` passes 517 |
| `InitiatE=RunRulE+;` | :62 | **isGROUP** | **NONE** — `RunRulE` passes 517 (and fully plans) |
| `Attributes=TraiT+;` | :57 | **isGROUP** | **NONE** — `TraiT` passes 517 |
| `Start=StatemenT+;` | :159 | **isGROUP** | **NONE** — `StatemenT` passes 517 |

**Four independent falsifications.** Under transitive resolution these five would report their
chains' terminal kinds — sets and characters, and *different ones from each other*. They report
**isGROUP, uniformly**: the kind of *the reference itself*, held on the rule's own node.

**ANSWER: DECLARED.** Per the brief's own conditional — *"if `planRule` refuses on declared kind,
the family boundaries are the refusal boundaries and one partition serves"* — **the table needs one
partition**, and the family table below is built on declared shape with the measured kind as the
refusal column.

### ⚠ T-1a — but the map from grammar TEXT to stored KIND is not the naive one, and that is a real sub-question

The transitive hypothesis is dead; **a weaker divergence is alive and it is not the same thing.**
The kind stored on a rule's own node is a function of the *form* of its declaration, and reading it
off the grammar text by eye gets it wrong in five of 21 places:

| grammar text | naive reading | measured |
|---|---|---|
| `nameSet=[a-zA-Z0-9];` | set | isSET ✔ |
| `counter=[0-9];` | set | **isCOUNT** |
| `ShortcuT=[-+~$_:,]+;` (repeated set) | set | **isGROUP** |
| `ANYstring=[^ \t;]+;` (repeated negated set) | set | **isGROUP** |
| `numberSet=[0-9]+` (repeated set, **nested** in `NumbeR`) | set | **isSET** |
| `FloaT=".";` (one-char literal) | string | **isCHAR** |
| `SemI=";";` (one-char literal) | string | **isSTRING** |

**Repetition appears to promote a set to a group, and length-1 literals split between isCHAR and
isSTRING — but `numberSet` breaks the first rule and `SemI`/`FloaT` break the second, so neither is
stated as a mechanism.** Offered as **observation, not ruling**; the two counterexamples are named
precisely so nobody adopts the pattern without explaining them. **This is what OPEN row 3 below is.**

**Consequence for the charter, and it is a refinement of the brief rather than a contradiction:**
one partition serves for the *refusal boundary* (T-1's answer), but a family table keyed on grammar
text still needs the **measured kind printed beside it**, because the two disagree in five places
for reasons nobody has established. Both columns are carried below. Cost: one column.

---

## THE FAMILY TABLE — all 21, each in exactly one family or OPEN (charter ruling 2)

Population is **21 censused, PROVISIONAL** (Amendment B). Evictions are **rows with reasons**;
nothing is renumbered silently in either direction.

### Family A — REFERENCE (rule data is a reference to another rule) · 5 members + 1 deferred
Uniform kind, uniform obligation. **The cleanest family and the one T-1 was decided on.**

| rule | grammar | declared shape | kind |
|---|---|---|---|
| `ANYtoken` | :92 `ANYtoken=NamE;` | plain reference | isGROUP |
| `Looper` | :132 `Looper=ANYtoken;` | plain reference | isGROUP |
| `Attributes` | :57 `Attributes=TraiT+;` | repeated reference | isGROUP |
| `InitiatE` | :62 `InitiatE=RunRulE+;` | repeated reference | isGROUP |
| `Start` | :159 `Start=StatemenT+;;` | repeated reference | isGROUP |
| ~~`NewGroup`~~ | :58 `NewGroup TraiT@;` | reference **+ promote** | isGROUP |

**Plan-layer obligation:** a rule whose own data is a reference must plan as the referenced rule's
`CALL`, with the repetition modifier becoming `MANY` — i.e. **exactly what `planTerm` already does
for a reference in term position.** The refusal is at *rule* position only.
⚠ **`NewGroup` is DEFERRED, not filed** (Amendment B): the `@` carries isTarget/promote, which
**IT-3 holds under a named expiry**. No chartered work for a shape a standing expiry deletes.
⚠ **This family is §2.5's ITERATE case** — loop outside, one fresh label per pass. It is the family
the charter already has a spec for.

### Family B — LITERAL (rule data is a quoted literal) · 3 members
| rule | grammar | declared shape | kind |
|---|---|---|---|
| `SemI` | :84 `SemI=";";` | one-char literal | isSTRING |
| `loopOnAttributes` | :134 `loopOnAttributes="attributes";` | word literal | isSTRING |
| `loopOnMembers` | :135 `loopOnMembers="members";` | word literal | isSTRING |

**Plan-layer obligation:** plan as `LIT` — the kind `planTerm` already emits for a literal in term
position. **The smallest family with a fully-known treatment; the natural first Phase R rung.**
⚠ `FloaT` is *not* here — see OPEN row 2.

### Family C — CHARACTER SET (rule data is an inline or named character set) · 4 members
| rule | grammar | declared shape | kind |
|---|---|---|---|
| `nameSet` | :31 `nameSet=[a-zA-Z0-9];` | inline set | isSET |
| `Modifier` | :54 `Modifier=[-~+?!%&\|*@_<^{}$] noPrint;` | inline set + `noPrint` | isSET |
| `followedBy` | :82 `followedBy<^-=notInNameSet;` | **named** set reference | isSET |
| `numberSet` | :35 (nested in `NumbeR`) `numberSet=[0-9]+` | inline set, repeated | isSET |

**Plan-layer obligation:** §2.5's **ACCUMULATE** case — loop *inside* the matcher, one token
spanning the run — and `testMacro` is the cited precedent. **This family has a spec.**
⚠ `followedBy` is a *named* set, not an inline one, and is declared with `<^-` modifiers; whether
that is the same treatment or a sibling is flagged **at the row**, not assumed.
⚠ `numberSet` is filed here on its declared text but is the counterexample of T-1a — same text
shape as `ShortcuT`, different kind. **Its filing is provisional on OPEN row 3.**

### Family D — SET-PLUS-SUBFIELDS (rule data is a set AND the rule carries sub-fields with their own data) · 2 members
| rule | grammar | declared shape | kind |
|---|---|---|---|
| `PoweR` | :32 `PoweR=[eE] sign?=[+-] power=[0-9]+;` | set + 2 sub-fields | isSET |
| `NumbeR` | :35 `NumbeR=numberSet=[0-9]+ FloaT? tokenize;` | named set + sub-field + `tokenize` | isGROUP |

**Meets the minting rule** (>1 member) and is a genuinely new shape: the rule-level data and the
sub-fields must both be planned, and **the two members do not agree on kind** (isSET vs isGROUP),
which is the first thing this family's rung has to explain.
⚠ **This is the family §2.5 does not cover and did not anticipate** — neither accumulate nor
iterate. It is the leading candidate for the "inline group" work the charter names as the only
genuinely new construct.

### Family E — REPEATED SET (declared as a set with `+`, stored as a group) · 2 members
| rule | grammar | declared shape | kind |
|---|---|---|---|
| `ShortcuT` | :91 ``ShortcuT=[-+~`$_:,]+;`` | inline set, repeated | isGROUP |
| `ANYstring` | :93 `ANYstring=[^ \n\r\t;]+;` | negated inline set, repeated | isGROUP |

Minted as its own family **because its two members agree with each other and disagree with Family
C**, which is the minting rule working as intended. Whether E collapses into C is exactly OPEN
row 3; **filed separately so that a collapse has to be argued rather than assumed.**

### EVICTIONS AND OPEN ROWS

| rule | disposition | reason |
|---|---|---|
| `BrancheS` :96 `BrancheS bin` (+ `break`/`continue`/`return` members) | **EVICTED — container, already paid** | Containers closed with `containerTo` (GAP A / CT, 2026-08-07). Its refusal is a container refusal wearing a rule-as-data message. ⚠ **Amendment B's row cites "censused isGROUP"; it is measured `isSET`.** The disposition is unaffected — the eviction rests on `bin`, not on the kind — but the charter's evidence line needs correcting. |
| `NewGroup` :58 | **DEFERRED** | `TraiT@` carries promote, under IT-3's named expiry. Listed in Family A struck through so the shape is visible without being chartered. |
| **`Any`** | **OPEN row 1 — POPULATION QUESTION, now ANSWERED as to fact** | ⚠ **`Any` is not a grammar rule.** It is a **C++ bootstrap primitive**: `GroupMain.twk:156-158` mints it into `grok` and sets **`isANY = true` explicitly**. It appears in no line of `incant/grammar`, which is why the census could not place it. It is a genuine member of the 21 (it really does refuse at 517) but it **has no declared grammar shape to file**, so it belongs to no family. **Tony's call: evict as "not a grammar rule", or charter a PRIMITIVE family of one** — noting the minting rule forbids a family of one. |
| **`FloaT`** :33 | **OPEN row 2 — singleton** | `FloaT="." decimals=[0-9]+ PoweR?;` is a **literal plus sub-fields** — Family B's data shape with Family D's structure — and it is the **only** rule of that shape, so the minting rule keeps it OPEN. It is also the only `isCHAR` in the population. Resolves the moment either B or D is ruled to absorb it. |
| **`counter`** :29 | **OPEN row 3 — the text→kind question** | `counter=[0-9];` is textually Family C and measures **isCOUNT**, alone in the population. It is the cleanest specimen of T-1a: *why does a declared set store as a count here and as a set in `nameSet`?* **Until answered, `counter` is OPEN and `numberSet`'s Family C filing and Family E's separateness are both provisional on the same answer.** |

### THE COUNT, AS AMENDMENT B REQUIRES IT

```
  21 censused (provisional)
   -1  BrancheS   EVICTED  — container, already paid (CT)
   -1  NewGroup   DEFERRED — promote under IT-3 expiry
  ---
  19 in scope, of which:
       Family A  REFERENCE            5
       Family B  LITERAL              3
       Family C  CHARACTER SET        4
       Family D  SET + SUBFIELDS      2
       Family E  REPEATED SET         2
       OPEN      Any · FloaT · counter    3
  ---
  19  ✔ every rule in exactly one family or OPEN
```

---

## RULING-4 NUMBERS (both, never conflated) — and the instrument is now NAMED BY MEASUREMENT

| number | value, asOf 2026-08-09 |
|---|---|
| **total plan-layer refusals** | **97** |
| **fully-plannable rules** | **13** of 78 |

Partition checks clean: **13 plannable + 65 refused-somewhere = 78**, and 78 PLAN / 78 DONE says the
walk completed. 97 total refusals reproduces the 08-07 seal's *"partition moved REFUSE 99 → 97"*.
The 13: `BlocK Braced CodE ElsE ExpressioN GrouP InvokE InvokeArg Parens PrintField RunRulE TokenXP
WardeD`. (The 08-05 vintage's *"12 PLAN / 66 REFUSE"* is superseded — Gap A/CT moved one rule across.)

### ✅ AMENDMENT A DISCHARGED — `incant/phaseA` IS the ruling-4 instrument
Verified rather than assumed, which is the whole point of the amendment:
- **It exists** (`incant/phaseA`, 192 lines) — unlike the charter's original `incant/censusScratch`.
- **It reaches the refusal branch**: 21 hits on `genParse.rtn:518`, the Gap B line specifically.
- **It produces both numbers**, and it is complete while doing so — single `stop()`, foot sentinel
  present, per-rule `DONE` markers, 78/78.

⚠ **ONE HONEST QUALIFICATION, because the amendment says *demonstrably produces*.** phaseA emits the
**evidence** for both numbers; it does not **print either as a scalar**. Both were derived here by
counting its output. By H4 that is a gap: a quantity nobody prints is a quantity that can drift
silently. **Recommendation for the first Phase R rung: have it print the two scalars and assert
them**, rather than have each rung re-derive them by grep. Small, and it is the difference between a
metric and an eyeball. **The slot is filled; the hardening is named.**

---

## WHAT PHASE T DID NOT DO

- **No plan-layer line was edited.** Ruling 2 forbids repair before the table; the table now exists.
- **No family's treatment was designed.** Each family's named obligation above is a one-line
  statement of what the plan layer owes, not a spec.
- **T-1a is not diagnosed** — the grammar-text→stored-kind map has two counterexamples and no
  mechanism. It gates OPEN row 3 and provisionally gates two filings; it does not gate Families A,
  B or D, which is why the table ships rather than parks.
- **The T-0 census correction is routed as a FINDING, per §5** — no charter text edited. Amendment
  B's `BrancheS` evidence line and the charter's §2 expectation about *"the scalar kinds
  (isSTRING/isCOUNT/isCHAR)"* both want Tony's word now that the memberships have moved.
