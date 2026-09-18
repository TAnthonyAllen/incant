# checkInput recon — the eight callers, their state at entry, and the conflict question

**SEQ 159 item 1, 2026-09-18. READ-ONLY. Nothing was built and nothing was changed.**
Every row below is either read at its site or observed on an existing instrument (`traceParse`
plus the standing `measure*` callouts). Where a claim is an inference rather than a reading it
says so.

**THE RULING UNDER TEST** (Tony, provisional): *checkInput discriminates on STATE, not road —
"is there an activation with a bound label to write into" decides, and neither road is ever
asked.*

**THE QUESTION THIS FILE ANSWERS:** is there any cell where the two roads arrive in the same
state and want different answers?

**THE ANSWER: NO — and the ruling survives the recon. But the try-and-buy as scoped cannot
reach its own certificate, and §5 is why.** That is a scope finding, not a falsification.

---

## 1. The eight callers

`checkInput()` is one method on `RuleStuff` (`RuleStuff.twk:167`). **It takes no argument and
reads only the rule's own state**, so every caller gets the identical function; the callers
differ in *what state the rule is in when they call it*, never in what it does.

| # | caller | file | road | reached through | attach seam |
|---|---|---|---|---|---|
| 1 | `GroupItem::parse` | `GroupItem.twk:1204` | **OLD** | `rule.parse(pStuff)` — runRule's else arm, `testOptions`, `onGroup.parse` | **`attachLabel(ruleStuff, pStuff, 1)`** |
| 2 | `parseRule` | `Generate.rtn:198` | **NEW** | `rStuff->parseMethod`, via `parseLoop` | `exitFromParse` |
| 3 | `parseAny` | `Generate.rtn:68` | shared | " | `exitFromParse` |
| 4 | `parseCharacter` | `Generate.rtn:92` | shared | " | `exitFromParse` |
| 5 | `parseContainer` | `Generate.rtn:131` | shared | " | `exitFromParse` |
| 6 | `parseSet` | `Generate.rtn:245` | shared | " | `exitFromParse` |
| 7 | `parseString` | `Generate.rtn:267` | shared | " | `exitFromParse` |
| 8 | `parseUpTo` | `Generate.rtn:283` | shared | " | `exitFromParse` |

⚠ **THE TWO ROADS HAVE DIFFERENT ATTACH SEAMS, AND THAT IS THE STRUCTURAL FACT THE WHOLE
QUESTION TURNS ON.** The old road attaches through `attachLabel`, taking the parent label as a
**passed argument** (`pStuff`). The new road attaches through `exitFromParse`, taking it from
**`parentStuff.label`** — read off the tree rather than handed in. **checkInput is upstream of
both and knows about neither.**

⚠ **`parseRule` IS NOT NEW-ROAD-ONLY BY CLASSIFICATION.** `setParseWalk` installs it for *any*
rule carrying a `groupList`. It is listed as NEW here because that is where it is reached from
today — measured below, `list` driven on the old road produces **zero** `LABELMINT` lines, so
`parseRule` never fires there; the old road goes through `GroupItem::parse`.

---

## 2. What checkInput writes today — the whole of it

```
    if sukcess
        if noLabel || (hasMembers && !binType)   label = 0;
        else {
            if !label || !label.fLAG { label = new(tag); label.isLabel = true; }
            else label.fLAG = false;
            if !label.rStuff || ruleName ne tag  label.setRStuff(this);
            // enclosingActivation
            if hasNewParse && isMember {
                if parent && parent.rStuff  parent.rStuff.label = label;
                else refuse(field,"checkInput: no enclosing activation to take the label"); } }
```

**Three writes, and only the third is road-conditioned.**

| write | condition | road-blind? |
|---|---|---|
| `label = 0` | `noLabel` **or** a members-rule (`hasMembers && !binType`) | ✅ **yes** |
| mint or reuse `label`, stamp `rStuff` | otherwise | ✅ **yes** |
| `parent.rStuff.label = label` | **`hasNewParse && isMember`** | ❌ **NO — this is the road read** |

⚠⚠ **SO THE RULING'S *"neither road is ever asked"* DESCRIBES THE TARGET AND NOT THE PRESENT.**
`hasNewParse` is read at `RuleStuff.twk:208`, on the **field's own** flag
(`field->groupBody->flags.hasNewParse` in the generated `.mm`, confirmed) — not the parent's.
**Deleting that read is the stroke's first act**, and it is the only line in `checkInput` that
has to go.

---

## 3. The cell-by-cell comparison

The state dimensions `checkInput` actually reads: `noLabel` · `hasMembers` · `binType` ·
`isMember` · an existing `label` and its `fLAG` · `ruleName` vs `tag` · `parent` and
`parent.rStuff` · and the road flag.

| state at entry | OLD road wants | NEW road wants | same? |
|---|---|---|---|
| `noLabel` set | `label = 0` | `label = 0` | ✅ |
| **members-rule** (`hasMembers && !binType`) | `label = 0` | `label = 0` **today** — and see §5 | ✅ |
| bin / registry | mint a label | mint a label | ✅ |
| leaf with data | mint a label | mint a label | ✅ |
| re-entry with `label.fLAG` set | reuse, clear the flag | reuse, clear the flag | ✅ |
| **member, parent has rStuff** | **no up-write** (works today) | **`parent.rStuff.label = label`** | ❌ **the only divergence** |

**The last row is the only cell where the two roads differ today, and it is the road read
itself.** It is not a case of the same state wanting different answers — it is the same state
being *told apart by a flag*, which is what the ruling removes.

⚠ **AND THE RULING DOES NOT GENERALISE THAT CLAUSE, IT RETIRES IT.** The clause tests for an
**activation** (`parent && parent.rStuff`) and then **overwrites the parent's label slot with the
child's**. The ruling tests for a **bound label** (`parent.rStuff.label` non-null) and **writes
matched data into it**. Different test, different operation, different direction. **Reading the
ruling as "drop the `hasNewParse` and keep the line" would be a different change from the one
ruled**, and would hand every old-road member's label up into its parent's slot.

**So: no conflicting cell. The ruling stands and a split is NOT the honest shape.**

---

## 4. What was measured, and with what

Two runs of the same fixture shape, `traceParse` on, one with generation and one without.

**OLD ROAD** — `testList()` with no generation: 460 trace lines, **zero `LABELMINT`**, zero
`PARENTPROBE`. `parseRule` is never entered. `runRule DOOR on list field=1 fieldData=1
hasNewParse=0 gMethod=1` — the else arm, `rule.parse(0)`.

**NEW ROAD** — `parser(list)` then `testList()`:

```
LABELMINT   list at=0x104b1aa80 into=(none) intoAt=0x0 intoLen=0
PARENTPROBE list self=0x104b1ae40 parent=0x104b183c0 parentTag=testList
            stuff=0x104b135a0 parentLabel=0x0 parentLabelTag=(none)
```

**Two readings, and the second is the important one.**

1. **Exactly ONE `LABELMINT` fires.** `entries` and `SemI` never reach `parseRule` at all —
   which is frontier station 5 restated: the generated parse is parked as text and the executor
   runs the action instead, so the terms are never matched.
2. **`parentLabel = 0x0`, `into = (none)`.** At `list`'s own `checkInput`, **there is no
   activation with a bound label** — so under the ruling the lawful answer is **0**, which is
   exactly what `checkInput` writes today for a members-rule. **The ruling and the current code
   agree at this cell.**

---

## 5. ⚠⚠ THE SCOPE FINDING — the certificate is not reachable from checkInput

**The try-and-buy's certificate is `list` firing its action with `entries` populated, so
`for sumGrup in entries` runs and prints.** The recon says that needs **three** links and
`checkInput` is the third:

| link | what | state today |
|---|---|---|
| 1 | **the carrier must be runnable** | `builtinParseR` is a bare `string` node with **no `BlocK`**. Nothing compiles it. Frontier station 5 |
| 2 | **something must run the parse body and then the action**, in that order, on one activation | `parseRule` runs exactly one `BlocK`, and it is the action's |
| 3 | **the minted label must become the terms' parent label** | `parseRule` mints `myLabel` and binds it as the body's `argument`; it does **not** write it into `ruleStuff.label`, so `exitFromParse`'s `parentLabel` reads `0x0` — measured above |

**`checkInput` cannot produce the certificate on its own, and neither can `checkInput` plus the
`setParse` switch.** Turning the switch on makes link 1 load-bearing immediately: `setParse`
would install a `parseMethod` pointing at a body that does not exist.

⚠ **THIS IS A SCOPE FINDING AND NOT A FALSIFICATION.** Nothing above contradicts the ruling.
What it says is that **the stroke as scoped has a certificate that three links must be closed to
satisfy, and it names two of them**, so whoever runs item 2 knows before starting that
`checkInput` alone will not move the acceptance line.

⚠ **AND THE ORDER IS FORCED, WHICH IS WORTH HAVING: link 1, then link 2, then link 3, then
checkInput.** Each earlier link is what makes the next one observable — the terms cannot arrive
at `checkInput` until something runs the parse body that calls them.

---

## 6. What the stroke would touch, if it runs

- **`RuleStuff.twk` `checkInput`** — delete the `hasNewParse && isMember` clause; write into the
  bound label when `parent.rStuff.label` exists; **0 when none, as a lawful answer, not a
  refusal** (which retires the `no enclosing activation` refusal — it is the message
  `incant/pop/skipT`'s header quotes and it would stop appearing).
- **`Generate.rtn` `setParseWalk`** — install `parseMethod` from `builtinParseR` when present.
- ⚠ **`GroupItem.twk` is NOT in the path.** The old road's attach is `attachLabel`, which takes
  its parent label as an argument and does not read `rStuff.label`, so it is insulated from the
  third write either way. That is the structural reason the old road is expected to hold, and it
  is the one prediction here worth grading.

**H7 control named in advance, per the dispatch:** restoring the road-blind zero must take
`list`'s row red and nothing else.
⚠ **AND A SECOND CONTROL THE DISPATCH DID NOT NAME, which this recon says is needed:** deleting
the `hasNewParse && isMember` clause is a behaviour change for **every old-road member that mints
a label**, and it has **no test of its own today**. The fleet is its only witness, so *"old-road
fleet unmoved row for row"* is carrying that control as well as its own, and should be read as
two claims rather than one.
