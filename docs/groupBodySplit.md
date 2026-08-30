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
