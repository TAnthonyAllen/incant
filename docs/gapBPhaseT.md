# Gap B — Phase T working notes (the family table)

**Status:** STARTED, NOT DELIVERED · asOf 2026-08-08 · charter: `docs/gapBCharter.md` ruling 2
**⚠ THE FAMILY TABLE IS NOT IN THIS FILE.** Phase T's deliverable is all 21 rules in exactly one
family or OPEN, and it does not exist yet. What is here is the **opening walk** plus **two findings
that change how the table must be built** — recorded now because both bear on the charter's own
expectations, and because a half-built taxonomy read as a whole one is the failure this project
keeps paying for (H9). **No repair work has begun and none may, per ruling 2.**

---

## ⚠ FINDING T-1 — THE CENSUSED DATA KIND IS NOT THE RULE'S SHAPE, so the table cannot be grouped on it

The charter's ruling-2 expectation reads *"the scalar kinds (isSTRING/isCOUNT/isCHAR) another
[family]"* — i.e. it anticipates that **data kind ≈ shape**. The grammar text says otherwise.
Read the definitions against SEQ 42's censused kinds:

| rule | censused kind | `incant/grammar` says | reads as |
|---|---|---|---|
| `Looper` | **isSET** | `Looper=ANYtoken;` (:132) | a **reference** to another rule |
| `InitiatE` | **isSTRING** | `InitiatE=RunRulE+;` (:62) | a **reference**, repeated |
| `Attributes` | isGROUP | `Attributes=TraiT+;` (:57) | a reference, repeated ✔ consistent |
| `Start` | isGROUP | `Start=StatemenT+;` (:159) | a reference, repeated ✔ consistent |

**`Looper` and `InitiatE` are references whose censused kind is a scalar.** The likely mechanism —
**offered as a lead, not a ruling**, because causal claims here run about even — is that the
reported kind is **transitive**: `Looper=ANYtoken`, `ANYtoken=NamE`, and `NamE` bottoms out in a
character set, so the *resolved* kind is `isSET` while the *declared* shape is a reference. Same
chain for `InitiatE` through `RunRulE`.

**If that holds, the six-kind partition is a partition of RESOLVED kinds and the family table needs
DECLARED shape** — and the two do not agree on at least 2 of 21. **A table grouped on the census
column would put two references in a scalar family**, which is §2.5's accept-correctly-build-wrongly
failure arriving at the taxonomy layer instead of the emitter.

**Owed before the table:** establish which kind `planRule` actually reads when it refuses, and
build the families on **declared shape**, citing the grammar line for each of the 21. That is the
Phase T pass proper.

## ⚠ FINDING T-2 — AT LEAST TWO OF THE 21 ARE NOT DATA RULES AT ALL

- **`BrancheS`** (`grammar:96`) is `BrancheS bin` — a **container**, and containers are a settled,
  already-paid kind (`containerTo`, GAP A/CT closed 2026-08-07). Censused `isGROUP` at rule level.
  If its refusal is a container refusal wearing a rule-as-data message, it is **not Gap B's** and
  the charter's 21 is really 20.
- **`NewGroup`** (`grammar:58`) is `NewGroup TraiT@;` — a reference carrying **`@` (isTarget /
  promote)**, and promotion is under IT-3's named expiry (retiring as a parse-layer mechanism).
  A family built around it risks chartering work that IT-3 deletes.

**Neither is settled.** Both are flagged so the family table does not silently absorb a rule that
belongs to another arc — and the charter's own minting rule (a family needs more than one member)
makes exactly this kind of misfiling expensive to undo.

## Located, not yet classified

`Any` does not appear in `incant/grammar` at all — defined elsewhere (setup? another source?) and
must be found before it can be filed. `numberSet` appears only nested inside
`NumbeR=numberSet=[0-9]+ FloaT? tokenize;` — a **named set inside another rule's data**, which may
be a shape of its own rather than a peer of the other 20.

## The remaining 17, with their grammar lines, for the pass proper

```
ANYtoken=NamE;                          (92)     followedBy=[a set definition].   (79)
loopOnAttributes="attributes";          (134)    loopOnMembers="members";         (135)
NumbeR=numberSet=[0-9]+ FloaT? tokenize;(35)     counter=[0-9];                   (29)
nameSet=[a-zA-Z0-9];                    (31)     ShortcuT=[-+~`$_:,]+;            (91)
ANYstring=[^ \t;]+;                     (93)     SemI=";";                        (84)
Modifier=[-~+?!%&*@_<^{}$] noPrint;     (54)     PoweR=[eE] sign?=[+-] power=[0-9]+; (32)
FloaT="." decimals=[0-9]+ PoweR?;       (33)     Attributes=TraiT+;               (57)
Start=StatemenT+;                       (159)    InitiatE=RunRulE+;               (62)
Looper=ANYtoken;                        (132)
```

⚠ **Even at a glance these are not three families.** `PoweR` and `FloaT` carry **sub-fields with
their own data** (`sign=`, `power=`, `decimals=`); `loopOnAttributes`/`loopOnMembers` are **string
literals**; `SemI` is a **one-character literal**; `Modifier` is a **set plus `noPrint`**;
`followedBy` is a set. Whether "literal-valued rule" and "set-valued rule" are one family or two is
a real question and it is Phase T's to answer, not to assume.

---

## ⚠ CHARTER DEFECT — the per-rung oracle named in §5 DOES NOT EXIST

> *"Census fixture (`incant/censusScratch` + census.target) is the per-rung oracle"*

**`incant/censusScratch` is absent.** It was renamed to **`incant/popScratch`** (wakeup 08-05,
which also records *"a **sample**, never a census; `debug` is a **deliberate negative control**"*).
`incant/popScratch` exists; `census.target` exists and is driven from `pop.sh:224`.

Two things follow and both want Tony's word rather than my guess:
1. **The name needs correcting in the charter** — a per-rung oracle nobody can find is an
   instrument-level defect in a governing document, and this session's ledger says those outrank
   code defects.
2. ⚠ **More than the name may be wrong.** If `popScratch` is *"a sample, never a census"*, then it
   may not be able to carry the charter's ruling-4 obligation of **two numbers every rung** (total
   refusals AND fully-plannable rules). The partition numbers in SEQ 42 came from **`incant/phaseA`**,
   not from `popScratch`. **Which fixture is the ruling-4 instrument is therefore an open charter
   question, not a typo.**

**Reported as a finding, per §5's routing rule (findings that want to amend the charter route as
findings first). No charter text edited.**
