# The Object Model — target shape, stroke ledger, findings

**Status:** DRAFT, 2026-09-28 (Clay). Part 1 becomes the target of record once Tony signs it.
**Evidence:** `docs/objectModelRecon.md` (Clod, `2463cea`; §9 in `04c4cd4`; §10 header check in `68fa8c7`), measured on trunk `836c763`.

## How this document works

It has three parts, and each changes for a different reason:

| part | what it holds | what may change it |
|---|---|---|
| **1. Target shape** | where every field ends up | **a dated ruling by Tony only** |
| **2. Stroke ledger** | what has moved so far | each stroke landing (status column only) |
| **3. Findings** | what the strokes uncover | anything; a finding that would change part 1 waits for a ruling |

Coding never edits part 1. If a stroke shows part 1 is wrong, the stroke stops, the finding goes in part 3, and the target changes only by a ruling recorded in §1.5. This keeps the target stable while the ledger moves.

---

## Part 1 — Target shape

### 1.1 The problem this retires

The copy constructor (`GroupItem.twk:42`) **shares `groupBody` and copies `rStuff`**. So today's model is delegation and copy at the same time, split by *where a field happens to be stored*, not by what it means:

- anything in the body is **delegated with no override** — a write through one instance reaches every instance and the rule;
- anything in `rStuff` is **a snapshot** — later changes to the rule never reach it.

Every seam defect in the record is a field on the wrong side of that split (`isRule` back-propagation; `parseMethod` needing `definingRule()`; `label`/`parentLabel` one-per-node, so recursion breaks; the shared-body modifiers).

### 1.2 The model: delegation, three levels

| level | object | one per | holds | written by |
|---|---|---|---|---|
| **rule** | `GroupBody` | rule definition | shape: tag, **term list**, **property list**, rule-level flags, data union, methods | definitions only |
| **instance** | `GroupItem` | reference to a rule in a grammar (or the rule itself) | pointer to its rule, parent, siblings, affiliation, **own `RuleStuff`: instance facts only** | the definition that places it |
| **activation** | `ParseActivation` | parse call | mark, label, `parentLabel` | the parse; gone at return |

- **Reads fall through:** instance first, then its rule.
- **Writes land where they are made:** a write through an instance lands on the instance; writing the rule is explicit.
- **Terms fall through, properties are local** (ruled 2026-09-28): the term list lives on the rule; instances carry attributes only.
- **A grammar change reaches instances automatically** (ruled 2026-09-28), because instances read through to their rule.
- **Terms and properties are separate lists.** Artifacts (carriers, actors, frames, compiled CodE) never sit in the term list.

### 1.3 Field table

⚠ **PARTLY VERIFIED — every "today" cell now checked against the headers (`GroupItem.h`, `GroupBody.h`, `RuleStuff.h`, `jitContext.h:707`) at `68fa8c7`, 2026-09-28; still open: F-O13, F-O15, F-O16, F-O17 await Tony.** Both directions checked: every header field appears below (as a row or inside a named group), and every row exists in a header.

**GroupItem** (`GroupItem.h`: 6 members + `options`)

| field | today | target | stroke |
|---|---|---|---|
| `groupBody` | pointer to the body; shared by every face (copy ctor, `GroupItem.twk:44`) | pointer to its rule's body (unchanged in kind) | — |
| `options.isCopy` | bit; set only by the copy ctor, **no engine reader** (6 readers, all in `measure.twk`) | replaced by the instance → rule link; **form not yet ruled** (see §1.6) | 4 |
| `options.affiliation` | 2 bits (isAttribute / isMember / isEmbedded) | unchanged (instance) | — |
| `parent`, `nextInParent`, `priorInParent` | per node | unchanged (instance) | — |
| `rStuff` | per-node `RuleStuff *`; **copied** by the copy ctor (`*rStuff = *grup.rStuff`, then `rule = this`); absent on 109 of 350 grammar terms (lazy, recon §9) | instance facts only | 4, 5 |
| `jitData` | per-node `JitData *` | unchanged | — |

**GroupBody** (`GroupBody.h`: 4 fields, 3 unions, `gJitEmitter`, `flags`)

| field | today | target | stroke |
|---|---|---|---|
| `tag` | shared | unchanged (rule) | — |
| `groupList` | shared; terms **and** artifacts (`builtinParseR`, `builtinActoR`, `frameSTAK`; recon §9.3) | **terms only** | 3 |
| *(new)* property list | — | rule-level artifacts and properties | 3 |
| `registry` | shared; the registry the definition sits in | *not addressed in the target; see F-O17* | — |
| `guardSet` | shared; a bin's guard characters | *not addressed; see F-O17* | — |
| `gMethod` / `gOp` (one union) | shared; the rule action or operator binding | unchanged (rule) | — |
| `gJitEmitter` | shared; the JIT emitter slot, beside the union | *not addressed; see F-O17* | — |
| `gText` / `gPointer` (one union) | shared; text or raw pointer | *not addressed; see F-O17* | — |
| data union (`gBuffer`, `gCharacter`, `gCharacterSet`, `gCount`, `gGroup`, `gItem`, `gMap`, `gNumber`, `gObject`, `gRegex`, `gStak`) | shared | unchanged (rule) | — |
| `flags.isRule` | shared; written through faces (8 sites, recon §4) | written only at definition, on the rule | 2 |
| `isPointer`, `isPercent`, `isMacro`, `guarding` (the body bits `modify()` sets for `& % $` and `_ { }`) | shared; each has a **second meaning** besides the modifier (raw-pointer data `GroupItem.twk:349,1003`; print format `:1071`; define-time `ruleActions.rtn:312,338`; bin/registry guarding `Commands.rtn:291-323`) | **bits stay** for their second meaning; `modify()` **stops writing them** — the modifier fact moves to the instance's `RuleStuff` | 1 |
| other flags (44, listed below) | shared | classified in verification: rule-level stay, instance-level move to `RuleStuff` | ? |

**The other 44 flags** (`struct bools`, 49 entries in all, multi-bit fields counted once; the four above and `isRule` are in their own rows). Level = what the flag *means*: a fact about the definition (**rule**), about one reference site (**instance**), or about one execution (**activation**). All live in the shared body today.

| level | flags |
|---|---|
| **rule** — node kind / shape | `isLabel` (set at mint, `RuleStuff.twk:112`), `invoke` (Xpress node kind, `ruleActions.rtn:1071`), `actionType`, `binType`, `fileType`, `instructType`, `methodType`, `isSorted`, `hasAttributes`, `hasMembers`, `hasTraits`, `isCondition`, `isIndexed`, `isLiteral`, `isShortcut`, `isSingleton`, `isUnary`, `isVirtual`, `isWindow`, `mergeOn`, `reversePrint`, `deferred` (read by the activation walk, but a property of the action) |
| **rule** — value / data state | `data` (5 bits, value kind), `byRef`, `altered` (stak cache dirty), `isInitialized`, `hasListeners` |
| **rule** — action-frame declaration | `isLocal`, `isArgument`, `isIterator` |
| **rule** — generation bookkeeping | `tokened`, `hasNewParse`, `parseWalked` |
| **rule** — debugging | `debugged`, `debugGuard` |
| **rule, with a second use** | `noPrint` — presentation, **and** the de facto "I am an artifact" marker (#50); stroke 3's property list retires the second use |
| **activation** | `isBranch` (2 bits; the control signal of one execution — P4 moved it to `branchKind` on the paused branch) |
| **activation?** | `fLAG` (two meanings, ledgered), `addingMembers` (transient state *of a definition in progress*: set by the MEMBERs command, cleared by DefinE, `ruleActions.rtn:369`), `recursive` (declares an action recursive, but **cleared at run time** by `restoreLocalFields`, bear-trap #25) |
| **dead** (no reader) | `isToggle`, `isXP` (no source reference beyond the declaration); `negate` (the *flag* is never read or written — every `negate` in source is the operator's name); `isAssign` (write-only, `Commands.rtn:493`) |

(`guarding`'s three values split three ways: `guarded` rule, `unGuarded` rule when defined and instance when set by `_ { }` (stroke 1), `guardInProcess` activation.)

**RuleStuff** (`RuleStuff.h`: 18 members + 17 bitfields = 35). Recon classification, **corrected against the header: 8 rule-level, 13 instance-level, 10 activation-level** (recon §2 said 9 — F-O12), `parentStuff` mixed, 3 dead or unclear. 8 + 13 + 10 + 1 + 3 = 35.

| group | fields | target home | stroke |
|---|---|---|---|
| rule-level 8 (7 here, `rule` below) | `ruleName`, `sourceLine`, `testMatch`, `parseMethod`, `actionMethod`, `jitMethod`, `hasMacro` (copied from the body's `isMacro` when the `RuleStuff` is built, `RuleStuff.twk:146`; see F-O13) | the rule, read through the instance pointer | 4 |
| `rule` | exists; the copy constructor aims it at the **face itself**, not the rule | candidate carrier for the instance → rule link (see §1.6) | 4 |
| instance-level 13 | `min`, `max`, `maxRepeat`, `limitsSet`, `banged`, `noAdvance`, `noLabel`, `noSkip`, `isTarget` (also computed, `max == 1`), `overTo` (`upTo`/`upToOver`), `notifyFail`, `followed` + `onGroup` (per position in the parent: `getWhatFollows`, `embedAttribute`) | stay in the instance's `RuleStuff` | 1 (adds the `unGuarded` fact; `%`/`&`/`$` rerouted) |
| activation-level 10 | `label`, `parentLabel`, `kount`, `sukcess`, `isOK`, `hereAt`, `failedAt`, `inProcess`, `guardOK`, `guardFAIL` | `ParseActivation` (today `{stuff, prev, floor, label}` — `label` already has a slot) | 5 |
| `parentStuff` | set at construction from the grammar parent (instance), read at parse time for `parentLabel` and walked by `deferredAbove` (activation) | split: instance part stays, activation part moves | 5 |
| dead / unclear 3 | `onFail` — written by `getWhatFollows` (`RuleStuff.twk:150`), **no reader**; `doNothing` — one write (`= 0`, `ruleActions.rtn:977`), **no reader**; `isOption` — declared, **no reference** at all | ruling per field: delete or classify | ? |

### 1.4 Out of scope for strokes 1–5 (later phases, not part of this target)

- Merging field and `GroupBody` (a rule as a GroupItem with no rule pointer owning its body).
- `RuleStuff` as attributes.
- Removing bitfields.
- Parse in kant, including the permanent C++ kernel (recon sketch: input machinery, leaf matchers, rewritten bootstrap, about 600 lines).

Each of these gets its own ruling and its own target section after stroke 5. They are listed so the summary does not absorb them along the way.

### 1.5a Rulings owed before the target is signed

| # | question | options |
|---|---|---|
| O-1 | How does an instance point at its rule? (stroke 4) | **(a)** a new `GroupItem` field — a layout change, `groups.ext` plus full `tokall`; **(b)** re-aim the existing `RuleStuff.rule` at the rule and give every term an `rStuff` up front (109 terms have none today) |
| O-2 | Delegation recorded as its own ruling (§1.2), or implied by step 0? | — |

### 1.5 Rulings of record

| date | ruling |
|---|---|
| 2026-09-28 | Step 0: terms/members live on the rule; instances carry attributes only. |
| 2026-09-28 | Step 0: parse-then-fire pauses at P6's open question. F-129 is independent and can be fixed on trunk when ruled in. |
| 2026-09-28 | A grammar change must reach the instances defined from it. |
| 2026-09-28 | Restructure the field in C++ first; decide the kant climb after. |

---

## Part 2 — Stroke ledger

Every stroke: its own try-and-buy branch cut from trunk; full seal checklist; line count of `parse()` and its helpers recorded before and after (the running "is it simpler" metric). A layout stroke updates `groups.ext` and runs a full `tokall`.

| # | stroke | GroupItem | GroupBody | RuleStuff / ParseActivation | layout | certificate | status |
|---|---|---|---|---|---|---|---|
| 1 | shared-body modifiers move to the instance | — | `modify()` stops writing the four bits; the bits stay for their second meanings | one new bit for `unGuarded`; `%`/`&`/`$` rerouted (dormant: no grammar reference carries them) | yes (one `RuleStuff` bit) | new row: `rightBrace}`'s `unGuarded` no longer reaches `Braced`/`Limit`; any other fleet movement is a finding | planned |
| 2 | `isRule` not written through faces | — | `isRule` written at definition only | — | no | `literalMasterIsRule` audit pin (10) moves; re-pinned with its sentence | planned |
| 3 | terms and properties separate | — | property list added; artifacts leave `groupList` | — | yes | term counts equal the grammar's (recon: 317, not 792); `countRuleTerms` and the `noPrint` term gates retire; **bear-trap #10 subdirectory check** (`GUI/`, `Tests/` — `tokall` does not reach them) | planned |
| 4 | instance pointer | per O-1: new field **or** none | — | per O-1: none **or** `RuleStuff.rule` re-aimed and every term gets `rStuff`; rule-level fields read through the link | yes if O-1(a) | the 13 `definingRule()` callers switch one at a time | **blocked on O-1** |
| 5 | activation consolidates | — | — | activation fields added to `ParseActivation` (plain C++ struct, no tok layout; already has a `label` slot) and **removed from `RuleStuff`** (the layout change); getStuff's running copy retires | yes (`RuleStuff` side only) | recursion rows (K-rows, A→B→A) through the new home | planned |

`parse()` + helpers line count — **baseline before stroke 1: 905 lines in 37 functions** (`68fa8c7`, 2026-09-28; each counted from signature through its closing column-0 `}`, comments inside included):
`GroupItem.twk` parse 62 · attachLabel 53 · fireLabelMethod 29 · embedAttribute 27 · deferredAbove 24 · getStuff 13 · setRuleStuff 11 · embedRule 10 · the copy ctor `GroupItem(GroupItem)` 10 · definingRule 8 · ensureRStuff 7 · getRStuff 4 —
`RuleStuff.twk` checkInput 44 · setTestMatch 19 · getWhatFollows 17 · parseR 17 · testAttributes 12 · `RuleStuff(GroupItem)` 12 · followingMember 11 · testOptions 9 · checkGuard 9 · `RuleStuff(RuleStuff)` 8 —
`GroupRules.twk` checkSkip 111 · pushInput 28 · popInput 24 —
`GroupActions.rtn` driveStep 68 · modify 25 · materialiseTerms 15 · modifyClass 11 · driveFloorLabel 10 · runRule 8 —
`Generate.rtn` parseRule 80 · parseContainer 59 · exitFromParse 21 · parseLoop 14 · runLeafParse 8 · repeatsInLoop 7.
**Every later count uses this same list**; a function a stroke deletes counts 0, and a function a stroke adds joins the list with a note.

---

## Part 3 — Findings

| # | date | finding | status |
|---|---|---|---|
| F-O1 | 2026-09-28 | The copy constructor shares the body and copies `rStuff`: the model is both options at once, split along the wrong line. | the reason for this document |
| F-O2 | 2026-09-28 | `isCopy` is written and never read; every reader rebuilds "am I a face" another way. | becomes the rule pointer, stroke 4 |
| F-O3 | 2026-09-28 | `modify()` writes `_ % & $` (and `{ }` via `unGuarded`) onto the shared body. Observed in memory: `SetBrackets`' `rightBrace}` puts `unGuarded` on the body `Braced` and `Limit` read. Effect on any parse: **not measured.** | stroke 1 |
| F-O4 | 2026-09-28 | Activation state has three homes: the node's `rStuff`, getStuff's copy when the rule is already running, and `ParseActivation`. | stroke 5 |
| F-O5 | 2026-09-28 | After `parser(Start)` and a compile, 59 of 63 rules have artifacts in their term lists; a census walking terms counted 792 where the grammar has 317. | stroke 3 |
| F-O6 | 2026-09-28 | Reference census: 63 rules, 158 references, all share their rule's body; 51% carry 1–3 own modifier facts; none overrides shape. The profile delegation is built for. | supports §1.2 |
| F-O7 | 2026-09-28 | Rule-level vs instance-level reads per parse: **not measured** (needs `measure*` counters). Deferred; correctness decides this design, not read cost. | open, low priority |
| F-O8 | 2026-09-28 | The four body bits `modify()` writes each carry a second meaning (`isPointer` raw-pointer data, `isPercent` print format, `isMacro` definition processing, `guarding` registry property), so stroke 1 re-routes the modifier and keeps the bits. | applied to §1.3 and stroke 1 |
| F-O9 | 2026-09-28 | Stroke 1's live population is `unGuarded` alone: none of the 158 references carries `%`, `&` or `$`; `hasMacro` and `overTo` already live in `RuleStuff`. | applied to stroke 1 |
| F-O10 | 2026-09-28 | `RuleStuff.rule` already exists but the copy constructor aims it at the face, not the rule; 109 terms have no `rStuff`, so it cannot carry the link as things stand. | ruling O-1 |
| F-O11 | 2026-09-28 | `ParseActivation` is a plain C++ struct: adding fields needs no `groups.ext` or `tokall`. | applied to stroke 5 |
| F-O12 | 2026-09-28 | Recon §2 counted **9** activation-level `RuleStuff` fields; the header gives **10** (`guardOK` and `guardFAIL` are both activation). Totals now reconcile with the header: 8 + 13 + 10 + 1 + 3 = 35. `termCount`, named in the old rule-level row, **does not exist** (retired 2026-09-26, SEQ 191). No target or stroke changes: all ten go to stroke 5. | applied to §1.3 |
| F-O13 | 2026-09-28 | `hasMacro` is rule-derived today (copied from the body's `isMacro` when a `RuleStuff` is built, `RuleStuff.twk:146`), and `isMacro` has two writers: the `macro` flag command (definition, `Commands.rtn:513`) and the `$` modifier (reference, `GroupActions.rtn:547`). The old §1.3 put `hasMacro` in the instance group; the header puts it in the rule group. **Question: is `$` a per-reference fact (then stroke 1 makes `hasMacro` instance-level) or a per-rule one (then `$` should not be rerouted)?** Dormant either way: no grammar reference carries `$` (F-O9). | **awaits Tony** |
| F-O14 | 2026-09-28 | Instance-level flags other than the stroke-1 modifier bits: **none found.** Every body flag outside the stroke-1 four is rule-level, activation-level, or dead. So the "other flags … move to `RuleStuff`" half of that row has an empty population. | informs F-O15 |
| F-O15 | 2026-09-28 | **Activation-level body flags have no target home.** Part 1 says where rule-level flags go (stay) and instance-level (to `RuleStuff`), but not activation-level: `isBranch`, `guarding`'s `guardInProcess` value, and the three `?` rows (`fLAG`, `addingMembers`, `recursive`). They are the stroke-5 family in the body; stroke 5 covers only `RuleStuff`. | **awaits Tony** |
| F-O16 | 2026-09-28 | **Dead fields.** Body flags `isToggle`, `isXP`, `negate` (no reader or writer) and `isAssign` (write-only); `RuleStuff` `onFail`, `doNothing` (write-only) and `isOption` (unreferenced). The `RuleStuff` three have a target row ("ruling per field: delete or classify"); the four body flags have none. | **awaits Tony** |
| F-O17 | 2026-09-28 | Four `GroupBody` fields were missing from §1.3 and are now rows with **no target**: `registry`, `guardSet`, `gJitEmitter`, the `gText`/`gPointer` union. §1.2 implies "unchanged (rule)" for all four, but that is Clod's inference, not a ruling, so the target cell says "not addressed". Also split out of the old `gMethod`, `instructType` row: `gOp` (union partner of `gMethod`, added) and `instructType` (a flag, now in the flags list). | **awaits Tony** |
