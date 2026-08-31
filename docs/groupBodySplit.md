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

# ⚠⚠⚠ THE CERTIFICATION GATE READS "AUDIT AT PIN", NOT "AUDIT CLEAN" — RULED 2026-09-02

Tony's ruling on Clay's recommendation, and it closes a question that had been holding the flip.

**The audit counts `isRule && !rStuff`.** Under **Ruling D** that conjunction is not a defect — it
is the **lawful signature of a bare master**. SEQ 100's C3 table then measured that **no reader in
the tree needs rStuff off those ten**: all five callers graded ASKING, four of them producers about
to construct and the fifth the audit itself.

**So the number cannot be driven to zero without breaking doctrine, and a gate that demands zero of
a lawful count is a gate that never opens.**

**The row is pinned at 10 missing / 4 loose** (`genLadder/pop.sh`), measured on the pure binary,
twice, on two boards that now agree — which they did not before the `getRStuff` purity ruling closed
F-35. What it asserts is **not** *"nothing is missing"*; it is **"the population of bare masters has
not moved"**:

| reads | means |
|---|---|
| **11** | a new route is marking masters |
| **9** | an attachment road started constructing rStuff where it did not before |

Either is exactly when somebody should look. **Same instrument-shape as `incant/broadcastT` pinned
pre-law: the number is the fact, and MOTION is the alarm.**

⚠ **THE REJECTED ALTERNATIVE IS RECORDED BECAUSE IT MAY LOOK BETTER LATER.** Re-specifying what
"missing" counts was the other option. It means deciding what *missing* should mean — a semantic
ruling about code **neither Tony nor Clay wrote** — and any new definition starts life unmeasured.
Pinning requires no code change and no new understanding of the audit's internals, which is the
honest position from both seats.

⚠ **AND THE ROW'S NAME CHANGED WITH ITS MEANING**, so the number cannot decay into a lie: it reads
*"bare-master population AT PIN (isRule without rStuff = 10, loose = 4)"*, not *"rStuff audit"*.
A row whose name says `missing` while its doctrine says `lawful` is the one-channel-two-meanings
failure waiting to happen.

---

# ⚠⚠⚠ THE ROUND-TRIP ORACLE ANSWERS, 2026-08-31 — **TRUTH-TABLE ROW 3, AND THE
# COVERING MECHANISM IS CONFIRMED DIRECTLY ON THE BARE BINARY**

`incant/roundTripT`, built to Clay's C1. **The split was not attempted a fourth time and did
not need to be.**

## The measurement, at the two sites themselves

An ephemeral `%p` instrument in `opSetFlag` case 29 and `opDot` case 29 — the actual write and
the actual read — reverted and the binary rebuilt **bare** before any capture:

```
ARM A   RTWRITE noPrint target=0x104f74c00  body=0x104f68280
        RTREAD  noPrint target=0x104f77e80  body=0x104f68280
        r = 1
```

**Two different nodes. One shared body. Legacy layout, no split anywhere near it.**

**THE ROUND TRIP WORKS TODAY FOR EXACTLY ONE REASON: THE FLAG LIVES IN THE SHARED
`GroupBody`.** `x :. noPrinT` writes one node and `x.noPrinT` reads another, and the two agree
only because they are looking at the same storage.

⚠ **AND ARM A AND ARM B2 ARE ONE PHENOMENON.** ARM B2 takes an `addGroup` twin, writes the
twin and reads the original: same body, different nodes, original reads **1**. Naming a field
twice is, at the node level, **indistinguishable from taking an addGroup twin**. So what this
document has been calling *broadcast* and what the brief calls *a round trip* are the same
mechanism seen from opposite sides — and `incant/broadcastT`'s ARM 2b was already firing it in
the other direction.

## ⚠⚠ THIS IS UPSTREAM OF ALL THREE ATTEMPTS, AND IT RE-READS THEM

The columns, the stamp, the roads and the writers were the search space for three strokes.
**None of them is the mechanism.** Attempts 2 and 3 built a correct copy law and got `1` twice
because the copy law is not what was carrying the flag between the write and the read — **the
shared body was**, and it was doing it for ordinary named access, with no copy road involved.

**A stamp at a minting road cannot help**, and now the reason is structural rather than
temporal: `inheritIdentity` fires when a copy is MINTED, and the nodes in ARM A are not a
mint-and-a-copy — they are two wrappers over one body, produced by the naming road on demand.
There is no moment for a road to stamp.

## ⚠ WHAT IT COSTS `noPrint`, AND THE GATE DECIDES IT WITHOUT A FOURTH ATTEMPT

C4 requires `roundTripT` green under the split — `R2 r == 1` — before a flag may move. **A bit
resident on the NODE, written to node X, cannot be read back from node Y.** The naming road is
independent of where flags live, so no layout change alters it.

**`noPrint` therefore CANNOT meet its gate**, and C4's own clause applies: *a flag that fails
the gate STAYS in the body and gets a register row naming which truth-table row it hit.*

| flag | truth-table row | verdict |
|---|---|---|
| `noPrint` | **row 3** — addresses differ, `r` reads 1 in R1 | **STAYS in `GroupBody`.** Fails C4's gate for a reason no layout change can fix |

**AND THE ROW GENERALISES, WHICH IS WHY IT IS A CENSUS TRIGGER AND NOT ONE FLAG'S PROBLEM:**
nothing in ARM A is about `noPrint`. Any flag read back through a name has the same two nodes
under it. ⚠ **So the question the campaign now owes is not "which flags are identity" — §2's
list answers that and is not in doubt — it is "which flags are ever READ BACK THROUGH A NAME
after being written", because those are the ones the shared body is currently carrying.**

⚠ **AND `isLabel` IS THE MEASURED COUNTER-EXAMPLE ALREADY ON FILE**, which is what makes this
a discriminator rather than a blanket refusal: tranche A moved it alone and certified
**byte-identical**. Nothing writes `isLabel` through `:.` and reads it back through a name, so
the covering never mattered for it. **The bridgehead stands.**

## The price, re-measured — and it moved

| | register §3 said | measured 2026-08-31 |
|---|---|---|
| `noPrint` hand-written sites | **4** | **5** — `genParse.rtn:757`, `jitEmitters.rtn:219`, `:2458`, `:2708`, `:3140` |

Small, and it changes no routing. Recorded because **a cited number that is never re-run cannot
be told apart from one that has expired.** H11's control was pre-registered — all five rows
named by eye before the count — and it is the reason a first attempt at this census, **run with
UNQUOTED `--include` globs so the shell expanded them against the cwd**, was caught and thrown
away rather than reported. That is H11's own recorded failure, walked into again by someone who
had read it the same day, which is the standing argument that **structure beats vigilance**.

⚠ **The bear-trap #10 sweep gap IS clear for this flag, and a correction was withdrawn before
it was reported.** `GUI/Bwana.mm`, `GUI/Control.mm` and `GUI/Details.mm` do carry `noPrint` —
but as `item->noPrint`, the GUI widget classes' **own** member, with no `groupBody` in the path.
Nothing is owed there and §3's clearance claim stands.

## ⚠ AND ONE ARM VOIDED ITSELF, WHICH IS THE INSTRUMENT LESSON

ARM 0 — two adjacent `probeNode` calls on one name, nothing between — reports **different
`node=` and the same `body=`**. So `probeNode` mints a wrapper per call and **its** address
column cannot attribute anything to `:.` or `.`. The arm was added as a control on a reading
that already looked decisive, and it voided that reading; the site instrument was built only
because it did. **Reported as void, not graded.** Had ARM 0 been skipped, a confident and
unsupported conclusion would have gone into this document in its place.

---

# ⚠⚠⚠ THE THREE-ATTEMPT LEDGER — written 2026-08-31 at Clay's instruction, because
# nothing on file answered "did the reverts teach anything about SHAPE"

**They did. THE THREE ATTEMPTS WERE NOT THE SAME SHAPE**, and a fourth described as
*"unchanged in shape"* would need to say unchanged from **which one**. Each attempt added
machinery the one before it lacked, and the reading moved once and then stopped moving.

| # | date | shape — what was actually built | audit MISSRULE | other instruments | write-up commit |
|---|---|---|---|---|---|
| **0** | 08-30 | the census. No code. | — | — | `31e6acb` (S11) |
| **1** | 08-30 | **move only.** Tranche A `isLabel` alone, then tranche B's 34 identity flags. **No copy law at all** | baseline 10 → **0** | fleet 86 green → **3**; frontier **139** | `a115cd8` (S13) |
| **2** | 08-31 | move **+ `GroupItem::inheritIdentity(grup)`**, the copy law written once and called at both minting roads. 23 INHERIT / 10 DIVERGE. Plus `copyOf`'s `isVirtual` test re-subjected to `grup.isVirtual` | **1** | fleet **HUNG** (>10 min against a 90s/fixture cap) | `3ee1d0f` (S14) |
| **3** | 08-31 | attempt 2 **+ the writer fix (checked per site, resolved to a NO-OP)** **+ `isVirtual` re-homed to STAY**, rider reverted | **1** | `kant8T` still **times out at 90s** | `058d2cf` (the 08-31 seal) |

**WHAT THE PROGRESSION SAYS.** Attempt 1's `0` is a *substrate* failure — nothing read as a
rule at all. Attempt 2's `1` is a *residual* failure, and it is the copy law doing almost all
of its job: 9 of 10 recovered. **Attempt 3 moved the reading not at all**, which is the datum
that sent the search upstream — two different additions, same number, so neither addition was
touching the thing that was wrong.

⚠ **AND THE SHAPE-CHANGE IS WHY "TRY IT AGAIN UNCHANGED" IS NOT A NULL INSTRUCTION.** Attempts
2 and 3 differ by two edits, one of which (`isVirtual` at STAY) was **reverted** and one of
which (the writer fix) **was never written because the per-site check dissolved it**. So
attempt 3's *delivered* shape is attempt 2's shape. **The re-attempt is unchanged from attempt
TWO, and attempt one is a different animal that should not be counted as a precedent for it.**

## ⚠⚠ THE PART THAT IS A RISK ROW RATHER THAN A HISTORY ROW: **NO SPLIT CODE HAS EVER BEEN
## COMMITTED. NOT ONCE, IN THREE ATTEMPTS.**

Measured, not assumed — `git log -S"inheritIdentity" --all` and `git log -S"options.isRule"
--all` return `3ee1d0f` and `ca92331`, and **both are prose**: S14 touched only this file, S15
only `incant/broadcastT`. The working tree carries no `inheritIdentity` today.

**So every attempt's shape exists ONLY as the paragraphs above.** There is no diff to re-read,
no branch to check out, nothing to compare a fourth attempt against. That is what turns
*"unchanged in shape"* from a cheap instruction into an unverifiable one, and it is the same
class as bear-trap #21 — **a description is evidence about what someone was doing, never about
what landed.**

**THE CHEAP FIX, AND IT COSTS NOTHING THE NEXT TIME:** land the next attempt on a **named WIP
branch** before certifying it, or `git stash` it under a named message at the revert. The
revert stays the right call; what is wrong is that the revert has been taking the only copy of
the artifact with it. `git merge -s ours` exists for precisely the discard-but-keep-reachable
case (bear-trap #21's other half).

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

---

# THIRD ATTEMPT, 2026-08-31 — writer fix + isVirtual re-homed. Still 1, and a sharper symptom.

**Reverted; every fleet row byte-identical to stroke-open (86 green), all seven fixtures
identical, all POPs green, frontier 0/10, canary 325, probes zero, switch at 0.**

## The writer fix: per-site check says THE WRITES ARE ALREADY EARLIEST

The ruling asked each of the three to move to the earliest moment its inputs exist, and to
land at attachment rather than mint where registry or parent shape is not knowable. **Checked
per site, and none of them moves:**

| site | inputs | earliest possible | where it is |
|---|---|---|---|
| `ruleActions.rtn:449` bin write | `NewGroup.isRule`, `item.binType` | attachment | **already there** — it is inside `aCTionDefinE`'s attachment walk |
| `GroupItem.twk:1983` registry arm | `registry.isRule` | attachment — `registry` is set then | **already there** |
| `GroupItem.twk:1985` parent arm | `parent.isRule` | attachment — `parent` is set then | **already there** |

`setRuleStuff`'s ~50 callers are `GroupMain`'s definition walk plus `modify` at attachment.
**So "three writes moved earlier" resolves to a no-op**, and that is the per-site check's
answer rather than a skipped step: a derivation cannot be asked before its inputs exist, and
these are asked exactly when they come into existence.

## `isVirtual` at STAY — ruled correctly, and it was NOT the hang

Re-homing it was the standing hypothesis for the hang (list-sharing decided by a flag read
from the wrong structure). **Measured: the hang survives.** `kant8T` times out at 90s with
`isVirtual` firmly in the body and no rider. So the ruling's re-home is right on its own
terms — it is a mechanism flag — but it does not explain the failure, and that hypothesis
is dead.

## ⚠ THE NEW AND SHARPEST DATUM: A NODE CANNOT READ A FLAG IT JUST HAD SET

`broadcastT`'s **ARM 3 is the anti-vacuity control** — *the write landed on the original at
all* — and under the split **it fails**:

```
ARM1  copy-time   copy reads <tag>     (was 1)
ARM2a control     copy reads <tag>     (was 0)
ARM2b broadcast   copy reads <tag>     (was 1)
ARM3  ANTI-VACUITY  the ORIGINAL reads <tag>   -- MUST be 1. It is not.
```

**`x :. noPrinT` then `x.noPrinT` no longer round-trips on the same node.** The setter
(`opSetFlag`, which spells `target.noPrint = true` and is tok-resolved) and the reader
(`opDot`'s numbered case) have come apart across the move. Every other arm's failure is
downstream of this one — with the control void, arms 1 and 2 assert nothing.

**This is the lead, and it makes the next measurement three lines instead of a fleet run:**
set a flag on a node and read it back on the same node, under the split, with nothing else
in the fixture. If that fails, the setter/reader disagreement is isolated with no copy road,
no inheritance and no broadcast anywhere near it — and the audit's 1 and the `kant8T` hang
are both explained by flags that cannot be read after they are written.

⚠ **AND IT REFRAMES ALL THREE ATTEMPTS.** The columns, the stamp, the roads and the writers
have been the search space for three strokes. **A flag round-trip failing on a single node
is upstream of every one of them** — it would produce exactly this signature no matter how
perfect the copy law was. That question was never asked because the instrument that would
have asked it, `broadcastT`, did not exist until today, and its control is what caught it.

## The prediction, and why it is not graded

The stroke was to write the predicted audit number before re-attempting. **It was not
computed**, because the per-site check dissolved its inputs — no writes moved, so the
pre-law census and the post-law census are the same census, and there was no new number to
derive. The reading is **1** for the third time, and with ARM 3 void it is not evidence
about identity residency at all. **An ungraded prediction is the honest outcome here; a
computed one would have been arithmetic over a void control.**
