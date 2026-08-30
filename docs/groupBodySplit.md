# The GroupBody Split — Census and Move List

**Stroke 2 census, 2026-08-30. Ruled by Tony: cure now, shape (a) — identity leaves
GroupBody for GroupItem; GroupBody becomes pure storage.**

**VERDICT: GREEN LIGHT ON THE RADIUS — 65 hand-written sites, not 1,946.** The census
does not re-price. It stops for one reason only, and it is a reason the dictation named:
**the move list is incomplete until Tony rules on `gMethod`.**

---

## 1. Why the radius is small — measured, not assumed

The raw count is alarming and misleading: **1,946 `groupBody->` accesses tree-wide**, and
`tag` alone has **423**. There is **no accessor layer** — `GroupItem.h` has neither
`getTag` nor `setTag`, so every access is raw by construction.

**But almost all of them are GENERATED, and tok re-points them for free.** The proof is
already in the tree and needed no edit to obtain:

**`GroupItem` ALREADY CARRIES AN IDENTITY FLAGS BLOCK.** `groups.ext:201` declares
`boolean GroupOptions { affiliation:2[isAttribute isMember isEmbedded] isCopy } options;`
on **GroupItem, not GroupBody**. And the spelling in source is identical to a GroupBody
flag's:

| source (`.rtn`) | tok generates |
|---|---|
| `if term.isAttribute` | `if ( isAttribute(term->options.affiliation) )` |
| `if term.isRule` | `if ( term->groupBody->flags.isRule )` |

**Same bare spelling, different addressing, chosen by tok from where the field is
declared.** So moving a field from GroupBody to GroupItem requires **no change to any
tok-resolved site** — every `.twk` and every non-passthrough `.rtn` line re-points itself
on the next retok.

⚠ **The destination is not being invented. It exists, and its current tenants —
`affiliation` and `isCopy` — are already identity-class.** The split moves fields into a
home that already holds exactly the right kind of thing.

---

## 2. The move list

**THE LAW:** identity describes the **holder**; storage describes the **held**.

### 2.1 MOVE to GroupItem — identity

**Non-flag:** `tag` · `registry` · `guardSet`

**Flags:** `isRule` `isLabel` `noPrint` `invoke` `fLAG` `isArgument` `isLocal`
`isLiteral` `isMacro` `isShortcut` `isSingleton` `isVirtual` `isWindow` `isXP`
`isCondition` `isIterator` `isUnary` `isAssign` `isPointer` `isPercent` `isToggle`
`isIndexed` `negate` `deferred` `recursive` `tokened` `reversePrint` `mergeOn`
`debugged` `debugGuard` `hasListeners` `hasNewParse` `hasTraits` `byRef` ·
enums `actionType` `binType` `fileType` `guarding` `methodType` `isBranch` `isSorted`

### 2.2 STAY in GroupBody — storage

`groupList` · the `gText`/`gPointer` union · the value union (`gBuffer` `gCharacter`
`gCharacterSet` `gCount` `gGroup` `gItem` `gMap` `gNumber` `gObject` `gRegex` `gStak`) ·
`data` · `isInitialized` · `hasAttributes` · `hasMembers` · `addingMembers` · `altered`

### 2.3 ⚠ FLAGGED — `gMethod` / `gOp` / `gJitEmitter` / `instructType`. **TONY RULES.**

**Not moved by default, per the dictation.** The verdict requested, with the argument on
both sides:

- **FOR moving:** *"which method does this node run"* describes the **holder**, so the law
  puts it in identity. And **bear-trap #34 is standing evidence they are mislaid** — a
  `copyOf` twin fires the original's rule action precisely because `gMethod` and
  `instructType` live in the shared body. **#34's own retirement clause anticipates this
  exact relocation**, and moving them would retire it and its statement-scope twin in one
  stroke.
- **AGAINST moving in this stroke:** #34's clause describes relocation to
  `rStuff.actionMethod`, which is a *different destination* from GroupItem. Riding it
  along with the split would settle by accident a question that has its own design.

**Radius if moved:** 9 hand-written passthrough sites (`gMethod` 4, `gJitEmitter` 3,
`gOp` 1, `instructType` 1) plus 44 bare tok-resolved sites needing no edit.

---

## 3. The price — hand-written sites, the only ones needing edits

| field | sites | | field | sites |
|---|---|---|---|---|
| `tag` | **43** | | `isPointer` | 4 |
| `isArgument` | 6 | | `isLiteral` | 3 |
| `noPrint` | 4 | | `isIterator` | 2 |
| `isShortcut` · `isUnary` · `isAssign` | 1 each | | | |
| **TOTAL** | **65** | | | |

Storage fields, for contrast — these stay and need nothing: `data` 12 · `gCount` 5 ·
`groupList` 3 · `gText` 1.

⚠ **`tag` is two thirds of the whole job**, so the move is effectively *one field plus a
tail*. That is worth knowing before scheduling: a `tag`-first pass proves the mechanism
against the largest population, and the remaining 22 sites are a mop-up.

**Bear-trap #10's sweep gap: MEASURED AND CLEAR.** The 14 sub-level generated files
`tokall` misses (`GUI/*.mm`, `GUI/Stuff/*.mm`, `Tests/*.mm`) carry **zero** hits on any
moved identity field. Nothing is owed there — which is a check, not an assumption, and it
is the one this bear-trap exists to force.

---

## 4. Why this stroke stops here

**Not a re-price.** The radius is 65 sites with a proven auto-repointing mechanism and a
destination that already exists.

**The move list is incomplete.** §2.3 is a ruling, not a measurement, and the dictation
said so: *report, Tony rules, don't move them by default*. Moving without it means either
moving `gMethod` by default (forbidden) or **moving twice** — and a second layout change
costs a second `groups.ext` sync, a second `tokall`, and a second full certification.

**One ruling, then the move is mechanical.**

---

## 5. What the move stroke will do, in order

1. Fields to `GroupItem.twk`; `groups.ext`'s `external GroupItem` / `external GroupBody`
   mirrors updated **in the same stroke** (bear-trap #11/#16 — out of repo, no commit trail
   protects you, and it commits rather than riding dirty).
2. `tok GroupRules.twk` plus every standalone class file touched; `tokall`.
3. Grep the sub-level generated files for the moved fields — measured clear today, re-checked
   after.
4. **Read the generated `.mm` at the bind and bracket sites** per the declaration-rebind trap.
5. **Certify byte-identical at `gNoUnwrap 0` — the split alone must move nothing.** Any
   motion is a finding about a reader the census missed.
6. **Only then** re-arm: `gNoUnwrap 1`, `acceptStartT` un-parks, certification resumes
   against `wrapperPlan.md` §4 — `parser(Start)` by pointer first, K2 at 7, `argWriteT`'s
   rows, the 26-site ledger, full seal per H12.

⚠ **A REGISTERED PREDICTION RIDES ON STEP 5**, from the fixit hour: the split kills the
groupBody-share class only, so `incant/fixits/literalMasterIsRule`'s audit should read
**10 → 4**, not 10 → 0 — the other six are bin-propagation (3), a direct registry write (1).
**Any other number is a finding**, either about a missed reader or about that citizen's
three-mechanism split being wrong.

---

# ⚠⚠ THE SPLIT WAS ATTEMPTED, 2026-08-30, AND CERTIFICATION FAILED — WITH A CAUSE

**Reverted; fleet byte-identical to its pre-split baseline (86 green), all POPs green,
frontier exit 0/10 PASS, canary 325, both repos clean.** Per the ruling, the stroke closes
as measurement.

## What was run

| tranche | fields | build | certification |
|---|---|---|---|
| **A — `isLabel` alone** | 1 | clean | ✅ **BYTE-IDENTICAL** — fleet and six fixtures, stdout and stderr |
| **B — 34 identity flags** | 34 | clean after 24 site repoints | ❌ **86 green → 3.** frontier **exit 139**. Every fixture moved |

**Tranche A proved the pipeline exactly as the census predicted.** tok re-pointed every
generated site to `->options.isLabel` with no source edit; bear-trap #16's removal check
passed (`isLabel` gone from `GroupBody.h`, present on `GroupItem.h`); the sub-level files
`tokall` misses carried none. **The mechanism is not in doubt.**

## The cause, and it is not a missed reader

**`copyOf` copies the BODY** — `*groupBody = *grup->groupBody`. So **every identity flag
resident in `GroupBody` is inherited by a copy**, and that inheritance is not incidental:
the grammar depends on it. Move the flag to `options` on the node and a copy stops
inheriting it.

The number that names it: `literalMasterIsRule`'s audit went **10 → 0**, not the 10 → 4
this document predicted — and **not because the split fixed six masters.** `isRule` stopped
propagating *everywhere*, so nothing read as a rule at all, and the grammar collapsed with
it. `frontier` at 139 is the same fact from the other end.

⚠ **THE PREDICTION REGISTERED IN THE FIXIT HOUR IS FALSIFIED, and in the more informative
direction.** It assumed the split would remove one propagation *mechanism* among three.
What it actually removes is the propagation *substrate* that all rule-shaped nodes stand
on. `literalMasterIsRule`'s option B carried the warning — *"BLAST RADIUS UNMEASURED AND
LARGE: isRule is read across the tree and this changes what it means for every copied
node"* — and the radius is now measured. **It is not large. It is total.**

## What this means for the ruled law

**The law is right as a DESCRIPTION and insufficient as a MIGRATION PREDICATE.**
*Identity describes the holder* correctly classifies `isRule`. It does not tell you that
`isRule`'s residency in the shared body is **load-bearing** — that copies are *supposed* to
inherit rule-ness, and that the body is currently the channel doing it.

**So the move list needs a third column**, and `isLabel` versus `isRule` is the measured
contrast that defines it:

| | identity? | does `copyOf` propagation carry weight? | movable alone |
|---|---|---|---|
| `isLabel` | yes | **no** | ✅ measured byte-identical |
| `isRule` | yes | **yes — the grammar stands on it** | ❌ collapses the parse |

**A field is movable when it is identity AND its copy-inheritance is not load-bearing.**
Everything else needs its inheritance re-provided explicitly before it can move — which is
a design question per flag, not a sweep.

## Recommended next shape — and it is a re-price, not a retreat

1. **Bank `isLabel`.** It is measured byte-identical and it is the bridgehead.
2. **Census the 34 by copy-inheritance**, not by identity alone: for each, does anything
   depend on a copy inheriting it? `copyOf`'s callers are the population.
3. **Move the free ones in a batch**, certifying byte-identical after each batch.
4. **The load-bearing ones — `isRule` at least — need their inheritance re-provided** (an
   explicit propagation at the copy site) *before* the move, and that is Tony's design call.
5. `gMethod` stays held out, unchanged.

⚠ **AND THE FLIP IS STILL BLOCKED ON THE SAME TWO FIELDS IT WAS BLOCKED ON.** The
acceptance failure was `tag` and `isArgument` travelling with the adopted body. Neither is
in tranche A, and neither has been shown free of load-bearing copy-inheritance. **The
flip's unblocking is exactly step 2 applied to those two fields**, and it is now the
cheapest next measurement in the campaign.

---

# SECOND ATTEMPT, 2026-08-31 — both halves in one motion. Canary read **1**.

**Reverted; every fleet row byte-identical to the pre-stroke baseline (86 green), all POPs
green, frontier 0/10, canary 325, both repos clean, audit back at 10.**

## Census headline

**TWO ROADS, four call sites.** `copyOf` (copies the body) and the **copy constructor**
(shares it) — reached directly and from `addGroup`, `GroupRules.mm:1667` and `:2479`.
`copyListTo` mints nothing; it re-adds existing entries.

⚠ **THE COLUMNS WERE ALREADY IN THE CODE, WHICH IS WHY NO ROW WAS ARGUED AMBIGUOUS.**
The copy constructor stamps `isCopy = true`; `copyOf` clears `isLocal = false` and
`isVirtual = false`. **Those three lines are the DIVERGE column, written by hand before it
had a name.** The split's job was to add the other half — an explicit INHERIT stamp — not
to invent a policy.

**23 INHERIT / 10 DIVERGE**, `isCopy` already node-resident. Full list in the commit.

## What was built

`GroupItem::inheritIdentity(grup)` — the copy law written once, called at **both** roads,
so no road ships unstamped. Only the INHERIT column appears in it, and only upward: a false
source flag never clears a true one, because the copy is fresh. **DIVERGE costs no code** —
a fresh node defaults it false, which is the whole economy of the design.

One consequential rider found while writing it: `copyOf`'s `if isVirtual isVirtual = false`
read the **copied body**, where the source's virtualness had just landed. With identity on
the node the copy starts false, so that test would always fail and silently switch every
virtual source onto the list-copying arm. Re-subjected to `grup.isVirtual`. **Same
decision, correct subject** — and it is exactly the class of thing the split surfaces.

Generated code verified at the constructor per the standing instruction: `options.isCopy = 1;`
then `inheritIdentity(grup);`, and `inheritIdentity` emitting `if (grup->options.isRule)
options.isRule = 1;` — the shape is right.

## Certification: FAILED, and the canary named the side

| canary | baseline | wanted | **read** |
|---|---|---|---|
| audit MISSRULE | 10 | **4** | **1** |
| fleet | 86 green | byte-identical | **hung** (>10 min against a 90s/fixture cap) |

**1 is on the 10 → 0 side**, which the charter reads as *a road was missed or a freight
flag wrongly diverged*. Nine nodes stopped reading `isRule`-without-`rStuff` where six were
predicted to.

**What the road hunt found, and it does not close it.** The only wholesale body writes
outside the two stamped roads are `saveLocalFields`/`restoreLocalFields`
(`*body = *grup.groupBody` and its inverse) — a **save/restore**, not a mint, and under the
split it correctly no longer carries identity. No third minting road exists. **So the
likelier residual is a column row, not a missed road** — and the direction says a freight
flag diverged, i.e. something in the INHERIT list is not actually reaching the copy, or
something that should be in it is not.

⚠ **AND THE HANG IS THE REAL BLOCKER ON DIAGNOSING IT.** Every re-measure costs ten
minutes, so the one-edit-and-re-certify economics the ruling prices this at do not hold at
the moment: the loop is too slow to bisect a 33-row column by trial. **The next stroke
needs a cheaper oracle than the fleet** — a single fixture that reads `isRule` on a known
copy before and after, which would name the failing row in one run instead of one
afternoon.

## What is now known that was not

1. **The columns are not the hard part.** They were derivable from the roads' own existing
   lines and no row needed a judgement call.
2. **The stamp mechanism works** — it builds, it generates correctly, and it is one function
   at two sites.
3. **The residual is a specific wrong row, and the canary can name it** — but only with an
   instrument that runs in seconds. That instrument is the next stroke's first build, not
   its last.
