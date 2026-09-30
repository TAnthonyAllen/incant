# Field flavors: design direction, 2026-09-30 (Tony, Clay, Clod). Not ruled, not scheduled.

Sibling of `docs/objectModel.md`, and not part of its Part 1. It records direction only: nothing here is
ruled and nothing is scheduled.

**A field knows what it is.** Its flavor is specified by its components.

**Two axes.**
- **position:** attribute, member, or property;
- **kind:** plain, rule instance, or fire-and-forget.

Each axis is a small field of its own. Do not fold both into one enum: that would put two meanings on one
channel, which is today's affiliation-boolean problem (F-O39 -- `addProperty` sets `isAttribute`, so `=%`
answers a property).

**Instances own their bodies.** An instance is a copy of its original with a link back (`ruleOf`). Its body
holds only what differs; everything else is asked of the original. `rStuff` dissolves into the instance's
body. We accept the efficiency cost. This is where R1 (copy on first write) was already heading.

**Flavor goes on `groupBody` once instances own their bodies.** Until then it stays on the instance.

**Lookup: ask the field; if it does not have it, the answer is no.** Each flavor carries a rule for whether
a miss delegates to the original. Terms delegate; `label`, `parentLabel` and activation facts never do.

**Lists.** Tony leans toward one list, but not strongly. One list requires BOTH of these:
- every walk goes through a flavored iterator;
- each flavor has a delegation rule.

Otherwise keep stroke 3's two lists (terms are shared, properties are the instance's own).

**Flags stay C++ bits, possibly forever.** Kant design should not have to think about them. Each flag gets
a `GroupFields` entry carrying its own accessor, and `opDot` dispatches through the registry instead of its
switch. 0 means off, non-zero means on. An unset flag reads 0 and must never echo its own tag (bear-trap #26).

**Fire-and-forget attributes are kept after they fire,** with their flavor set, so a definition can print
itself back out. This is consistent with the 08-03 fidelity-print ruling.

**Open:** under this model, "rule instance" as a kind replaces `rStuff` presence as the liveness test
(Ruling D).

## Affiliation census (2026-09-30, SEQ 233 part 2) -- sizing the two-axes idea. Read-only; measured with a temporary tap, reverted.

**Affiliation is already ONE field, not three flags.** `GroupItem.options.affiliation:2[isAttribute isMember
isEmbedded]` (GroupItem.twk:16) is a 2-bit enum on the NODE (not the body): 0 none, 1 attribute, 2 member, 3 embedded.
So "two of the three set at once" cannot be constructed. The F-O39 mix is a different conflict: the enum answers
**position within the term list** and is also written on **properties**, which live on a different list. That is
the two-meanings-on-one-channel problem this note is about, found in place.

### Writers and readers (tok source, code lines only)

| field | writers | readers |
|---|---|---|
| isAttribute | 8: `addAttribute` (generated GroupItem.mm:248), **`addProperty` (GroupItem.twk:171) -- F-O39's site**, the term copy (:554), `aCTionTraiT` on a Modifier (ruleActions.rtn:1114, :1144), compile's `this`/`tempField` locals (Commands.rtn:72, :79), the `+%` operator (Instruct.rtn:1380, :1383) | 18 |
| isMember | 3: `addMember` (GroupItem.twk:156), the member operator (Instruct.rtn:1402, :1405) | 17 |
| isEmbedded | 1: the embedded copy (GroupItem.twk:574) | 4 |
| (reset) | `affiliation = 0` in aCTionDefinE (ruleActions.rtn:273) | -- |

### Live co-occurrence (list the node sits on x affiliation x inferred kind)

Tap: at process exit, walk every node reachable from `ruler->registries` through BOTH `groupList` and `propertyList`,
each node once. Population: pop.sh + jitLadder + printPop, **314 processes, 429,831 nodes** (fleet 861 / 1 on the tap,
unchanged). Kind as inferred below: rule = `isRule` or `rStuff.ruleTerm`; "ff" = not rule, `noPrint`, has a method,
not a local; plain = the rest.

| list | affiliation | rule | ff | plain |
|---|---|---|---|---|
| term | none | 0 | 0 | 314 (the registries root, once per process) |
| term | attribute | 84,425 | 254 | 137,888 |
| term | member | 40,646 | 10,677 | 111,637 |
| term | embedded | 0 | 0 | 0 |
| **property** | **attribute** | **862** | **16,960** | **26,168** |
| property | none / member / embedded | 0 | 0 | 0 |

- **Control holds -- the census is valid:** every one of the 43,990 property-list nodes carries affiliation *attribute*.
  That is F-O39 (`addProperty` sets it), found at full population, not a sample.
- **`isEmbedded` has no live population.** One writer, four readers, zero nodes in the fleet. A two-axes redesign can
  drop it or keep it for free; nothing measured depends on it.
- **"Rule" kind appears in both positions** (84,425 attributes, 40,646 members), as fieldFlavors predicts: kind is not
  position. 862 rule-shaped nodes sit on property lists (not classified further today).

### Where "kind" is inferred today, and from which flags

| kind | inferred from | where |
|---|---|---|
| rule instance | `isRule` (body, definition-time: 46 code lines), `isRuleTerm()` = `rStuff.ruleTerm` or body `isRule` (22 lines), `ruleOf` (the copy link, 18), `rStuff` presence (Ruling D's liveness, 67) | four channels for one question |
| fire-and-forget | **`noPrint && immediateACTION`** (`methodType`, GroupBody.twk:61) | aCTionDefinE's attribute loop, ruleActions.rtn:294 |
| plain | the absence of the above | -- |

- **FINDING: fire-and-forget attributes are NOT kept today.** ruleActions.rtn:294's own comment: *"item gets run but is
  not added to the new group."* The direction above ("kept after they fire, with their flavor set") is a behaviour
  change, not a relabel.
- **FINDING: no flag means fire-and-forget.** It is inferred from `noPrint` plus a method, and that pair also matches
  `builtinActoR` (the 16,960 "ff" on property lists) and the command registry's entries (most of the 10,677 "ff"
  members, inferred -- not classified by name). `noPrint` is doing double duty again (#50's family). A `kind` field would be the first single-meaning
  channel for it.

## Kant flag-access census (2026-09-30, post-seal errand) -- which flags kant reads or writes, and which are C++-only. Read-only.

(The brief asked this to replace a "census wanted later" line; no such line exists in this file or in objectModel.md,
so the section is new.)

**Population.** Live: every incantation under `incant/` and `IncantForms/` (WorkingOn included) -- 298 files, attic
excluded. Side column: `incant/attic/` and `minionWork/` -- 11 files. **Excluded by Tony's word:** `IncantForms/BackupXML/setup`
and the `GroupFields` define block itself (registrations, not accesses).
**Stripped before matching:** the GroupFields block (by content, not line number), everything after the first
`stop();`/`bail();` (parse-dead), `=(`...`#)` literals, `/* */` and `//` comments, `"..."` strings (multi-line), `'...'`
strings, and backtick spans.
**Idiom family (H9):** dotted `x.X` / `*x.X`, bare `X` (lastREF), `:. X` writes. Assignment to a dotted accessor
(`x.X = ...`) was matched separately: **0 sites**, so the table does not carry it.

**Controls, named before running:** positives `isRulE` (the parser's `walkRules`, IncantForms/WorkingOn/parser:56) and
`noPrinT` (`artifactSkipT`); negative `isFilE` (no number, no opDot case; files load through `fILEs` and `getFile`, never
a flag test). **First run VOID:** `isFilE` read 1, which traced to `IncantForms/BackupXML/setup`'s own copy of the
GroupFields block; Tony ruled it and the block out of the population. Two more instrument defects were fixed before this
table: the live block's line-range exclusion was too short (`isActioN=408;` counted as a read), and multi-line strings
and `(...#)` prose leaked (the dropped hits were all `incant/designDocs`, checked by diff). **Final: isRulE 15 reads in 10
files, noPrinT 33 reads + 18 writes in 20 files, isFilE 0. Valid.** `isGrouP`'s 0 was checked by hand: its only mentions
are prose below `starFlagT`'s stop().

Columns: reads and writes are **live / attic+minionWork** occurrences. "opDot" is how a read resolves: its case, or the
default arm (`"access to X not supported yet"`). "Write" says whether `:.` has an opSetFlag case for it.

| GroupFields entry | C++ it reaches | kant reads | kant writes (`:.`) | opDot read | `:.` write | C++-only |
|---|---|---|---|---|---|---|
| `taG` | `tag` | 165 / 9 | 0 / 0 | case 1 | -- | no |
| `parenT` | `parent` | 4 / 2 | 0 / 0 | case 2 | -- | no |
| `registrY` | `registry` | 5 / 0 | 0 / 0 | case 3 | -- | no |
| `texT` | `text` | 2 / 1 | 0 / 0 | case 4 | -- | no |
| `listLengtH` | `listLength` | 77 / 2 | 0 / 0 | case 5 | -- | no |
| `datA` | `data` | 28 / 1 | 0 / 0 | case 6 | -- | no |
| `debuggeD` | `debugged` | 12 / 0 | 0 / 0 | case 44 | -- | no |
| `hasActioN` | `rStuff.actionMethod` | 0 / 0 | 0 / 0 | case 36 | -- | **yes** |
| `hasAttributeS` | `hasAttributes` | 8 / 1 | 0 / 0 | case 7 | -- | no |
| `hasMemberS` | `hasMembers` | 5 / 0 | 0 / 0 | case 8 | -- | no |
| `hasTraitS` | `hasTraits` | 8 / 1 | 0 / 0 | case 42 | -- | no |
| `isLocaL` | `isLocal` | 1 / 0 | 0 / 0 | case 9 | -- | no |
| `isArgumenT` | `isArgument` | 0 / 0 | 0 / 0 | case 10 | -- | **yes** |
| `invokE` | `invoke` | 0 / 0 | 0 / 0 | case 11 | -- | **yes** |
| `flaG` | `fLAG` | 0 / 0 | 0 / 0 | case 12 | opSetFlag case | **yes** |
| `isAttributE` | `affiliation` | 0 / 0 | 0 / 0 | case 34 | -- | **yes** |
| `isBiN` | `binType` | 0 / 0 | 0 / 0 | case 33 | opSetFlag case | **yes** |
| `isConditioN` | `isCondition` | 0 / 0 | 0 / 0 | default arm (no number) | -- | **yes** |
| `isFilE` | `fileType` | 0 / 0 | 0 / 0 | default arm (no number) | -- | **yes** |
| `isGrouP` | `data` | 0 / 0 | 0 / 0 | case 43 | -- | **yes** |
| `isIndexeD` | `isIndexed` | 0 / 0 | 0 / 0 | default arm (no number) | -- | **yes** |
| `isInitializeD` | `isInitialized` | 0 / 0 | 0 / 0 | default arm (no number) | -- | **yes** |
| `isLiteraL` | `isLiteral` | 1 / 0 | 0 / 0 | case 17 | -- | no |
| `isLisT` | `binType` | 0 / 0 | 0 / 0 | **default arm** (32 has no case) | opSetFlag case | **yes** |
| `isMacrO` | `isMacro` | 0 / 0 | 0 / 0 | default arm (no number) | -- | **yes** |
| `isMembeR` | `affiliation` | 0 / 0 | 0 / 0 | case 35 | -- | **yes** |
| `isMethoD` | `instructType` | 2 / 0 | 0 / 0 | case 19 | -- | no |
| `isOperatoR` | `instructType` | 1 / 0 | 0 / 0 | case 20 | -- | no |
| `isPercenT` | `isPercent` | 0 / 0 | 5 / 0 | **default arm** (21 has no case) | opSetFlag case | no |
| `isPointeR` | `isPointer` | 0 / 0 | 0 / 0 | default arm (no number) | -- | **yes** |
| `isRulE` | `isRuleTerm()` | 15 / 0 | 0 / 0 | case 23 | -- | no |
| `isShortcuT` | `isShortcut` | 0 / 0 | 0 / 0 | case 24 | -- | **yes** |
| `isVirtuaL` | `isVirtual` | 0 / 0 | 0 / 0 | **default arm** (25 has no case) | opSetFlag case | **yes** |
| `mergeON` | `mergeOn` | 0 / 0 | 3 / 0 | **default arm** (26 has no case) | opSetFlag case | no |
| `noLabeL` | `rStuff.noLabel` | 0 / 0 | 0 / 0 | case 28 | -- | **yes** |
| `noPrinT` | `noPrint` | 33 / 2 | 18 / 1 | case 29 | opSetFlag case | no |
| `noSkiP` | `rStuff.noSkip` | 0 / 0 | 0 / 0 | default arm (no number) | -- | **yes** |
| `byReF` | `byRef` | 0 / 0 | 0 / 0 | **default arm** (31 has no case) | opSetFlag case | **yes** |
| `hasNewParsE` | `hasNewParse` | 7 / 0 | 3 / 0 | case 41 | opSetFlag case | no |
| `isCodeD` | `actionType` | 4 / 0 | 6 / 0 | case 40 | opSetFlag case | no |
| `nexT` | `nextInParent` | 5 / 1 | 0 / 0 | case 401 | -- | no |
| `prioR` | `priorInParent` | 2 / 0 | 0 / 0 | case 402 | -- | no |
| `firsT` | `firstInList` | 2 / 0 | 0 / 0 | case 403 | -- | no |
| `lasT` | `lastInList` | 2 / 0 | 0 / 0 | case 404 | -- | no |
| `firstMembeR` | `nextMember(0)` | 2 / 0 | 0 / 0 | case 405 | -- | no |
| `actionTypE` | `actionType` | 3 / 0 | 0 / 0 | case 406 | -- | no |
| `binTypE` | `binType` | 9 / 0 | 0 / 0 | case 407 | -- | no |
| `isActioN` | `actionType` | 0 / 0 | 0 / 0 | case 408 | opSetFlag case | **yes** |

**Totals: 27 entries used live by kant, 21 C++-only** (no live read or write; none is used only in the attic).
- **Kant writes flags through `:.` on five entries only:** `noPrinT` (18), `isCodeD` (6), `isPercenT` (5), `mergeON` (3),
  `hasNewParsE` (3). All five have an opSetFlag case.
- **Two live entries are write-only from kant, and their reads would fall to the default arm:** `isPercenT` (21) and
  `mergeON` (26), both from `incant/utilities`' layout code. A kant read of either would print "not supported yet".
- **12 entries fall to opDot's default arm on a read:** the 7 unnumbered (`isConditioN`, `isFilE`, `isIndexeD`,
  `isInitializeD`, `isMacrO`, `isPointeR`, `noSkiP`) and 5 numbered with no case (`isPercenT` 21, `isVirtuaL` 25,
  `mergeON` 26, `byReF` 31, `isLisT` 32). Of the 12, only `isPercenT` and `mergeON` are touched live, and only as writes.
- **The affiliation entries are C++-only in practice:** `isAttributE` (34) and `isMembeR` (35) have cases and zero live
  kant sites. So is `hasActioN` (36), `isGrouP` (43) and `isActioN` (408), all minted with cases and unused by kant today.

### C++ flags that GroupFields does not expose at all -- C++-only by construction (C++ code-line references in .twk/.rtn)

- **GroupBody single-bit flags (13 of 35):** isLabel 17 · addingMembers 5 · altered 10 · debugGuard 7 · deferred 18 ·
  hasListeners 16 · isIterator 8 · isSingleton 5 · isUnary 4 · isWindow 3 · reversePrint 3 · tokened 9 · parseWalked 5.
- **GroupBody enums (4 of 9 wholly unexposed):** guarding 12 · isBranch 18 · isSorted 8 · methodType 2. (`fileType` is
  exposed only as the case-less `isFilE`.)
- **RuleStuff booleans (16 of 19):** banged 2 · doNothing 2 · followed 10 · guardOK 4 · guardFAIL 3 · inProcess 5 · isOK 7 ·
  isOption 1 · isTarget 10 · modPercent 4 · modPointer 4 · modUnGuarded 7 · noAdvance 7 · notifyFail 3 · overTo 3 ·
  sukcess 60. (Exposed: noLabel as `noLabeL` 28, noSkip as the case-less `noSkiP`, ruleTerm inside `isRulE`'s
  `isRuleTerm()`.)

**Standing (Tony, 2026-09-30):** no sweep. Other flags that could become property fields are taken up as we trip over them in ordinary work; the census above is the reference when one comes up.
