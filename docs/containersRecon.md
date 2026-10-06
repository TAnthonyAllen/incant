# Containers recon

Tony's idea, **not ruled**: a field's group list holds only fixed-position containers, e.g. `[members, attributes,
properties]`, instead of one mixed list of entries. The recon runs in three steps, each reported before the next goes
out (SEQ 309 R1, 2026-10-06):

1. **Who walks the group list** -- this file, below. Blast radius only: no shape proposal, no recommendation.
2. rStuff's place in a containers shape.
3. What it does to 1.3/1.4.

## Step 1 -- who walks the group list (2026-10-06, read-only)

### How it was measured

Three read-only census passes, one per population, every site read in source (tok `.twk`/`.rtn`; kant live regions):

| population | files | sites |
|---|---|---|
| **core classes** | GroupItem, GroupBody, GroupList, GroupStak, RuleStuff, GroupControl, GroupMain, measure, Layout, Stylish, GroupDraw (`.twk`) | **274** (152 + 122 in GroupMain's bootstrap) |
| **the GroupRules chain** | GroupRules.twk + all eight top-level `.rtn` | **366** |
| **kant** | incant/ (setup, grammar, utilities, unitTests, generate, pop/, pop/jit/, attic/, probes/, fixits/, ...) and IncantForms/WorkingOn | **629 live** (+ 7 kant-as-data payload lines); 111 files |

⚠ **The units differ.** The two C++ passes count call sites; the kant pass counts lines per mechanism (a walk, a
subscript, an accessor read). Add the verdict columns; do not compare raw totals across rows.

**Controls (H11), named before the passes ran and all returned:** `next()` GroupItem.twk:1231, `nextAttribute` :1244,
`get(name)` :755, `copyListTo` :423, `testContainer` RuleStuff.twk:237 (site :252), `aCTionIterate` ruleActions.rtn:577ff,
`anyOrNumT`'s iterate (:32), `artifactSkipT`'s `asWalk` (:21). Scale check: 316 raw primitive lines in the C++ sources.

**Population searched, and why the answer would be in it:** every top-level `.twk` that defines or calls a list
primitive, every `.rtn` in the GroupRules include chain, and every kant file reachable from `incant/setup`'s `fILEs`
plus every fixture and WorkingOn file. Not searched: GUI/, XML/, Tests/, the backup dirs, legacy IncantForms outside
WorkingOn (about 14 files of old-syntax walks, none registered in `fILEs`, noted by the kant pass), and the shell
scripts under genLadder/ (parserCoverage.sh carries a kant heredoc that walks Grokking in member order).

### Verdict scale

- **AT** -- changes at the site: it touches `groupList`, `firstInList`/`lastInList`, sibling pointers or `listLength`
  directly, or relies on position in the mixed list.
- **INSIDE** -- the site calls an accessor (`next`, `nextMember`, `get`, `[ ]`, `+%`, `iterate` ...) and stays as written
  if that accessor's body is re-aimed. For kant, "ONLY-IF-PRIMITIVE-CHANGES".
- **NO** -- reads a flag (`hasMembers`, `hasAttributes`, `hasTraits`) only.
- **UNCLEAR** -- depends on a meaning the shape has not decided: position across kinds, or what "has a list" means.

### Totals

| verdict | core | chain | kant | **total** |
|---|---|---|---|---|
| AT | 41 | 34 | **0** | **75** |
| UNCLEAR | 8 | 30 | 17 | **55** |
| NO | 6 | 13 | 26 | **45** |
| INSIDE | 219 | 289 | ~586 | **~1,094** |

**No live kant text needs respelling as long as the primitives keep their meaning.** Every kant walk goes through
`iterate`/`for`, a subscript, an accessor case or an operator, all of them C++.

### What the sites want, and how they tell entries apart today

| wants | core | chain | kant walks (128) |
|---|---|---|---|
| by tag | 68 | 155 (63 are label declarations `X:`) | (subscripts 250, dot-by-tag ~78, colon-pull 18, IN 8, kind gets 11) |
| members | 87 | 23 | 28 (`members` keyword) |
| attributes | 59 | 64 (49 are `+%` builds) | 24 (`attributes` keyword) |
| all | 51 | 55 | 76 unqualified (~20 of them want terms only and skip by flag) |
| first / positional | 6 | 37 | 13 positional subscripts, 15 navigation accessors |
| terms only | 2 | 10 | -- |
| count (`listLength`) | in "all" | 7 | 82 `listLengtH` |
| presence of `groupList` | 8 | 9 | -- |

| discriminator | core | chain | kant walks |
|---|---|---|---|
| tag compare | 120 | 158 | 3 (+ every subscript) |
| none | 115 | 117 | ~55 |
| affiliation flags (`isAttribute`/`isMember`) | 19 (incl. noPrint) | 18 | 52 by keyword (C++ filter behind it) |
| `noPrint` | (in affiliation) | 5 | 17 |
| position | 7 | 38 | 13 subscripts + navigation |
| `has*` flags | 6 | 15 | 26 `has*S` |
| `isRule`/`isRuleTerm` | 3 | 3 | 12 |
| `binType` | 3 | 5 | 8 |
| locals (`isLocal`/`isArgument`/`isLabel`) | -- | 4 | -- |

A site that tests two things (tag + `isAttribute`, say) appears in both lines, so the columns do not sum to the
site totals. `isLabel` is never used as a list discriminator.

### The AT sites (75) -- the blast radius proper

**The primitives themselves (core, GroupItem.twk unless noted):** `addAttribute` :93, `addGroup` :112 (its
`isIndexed` branch stores `listLength` as a position), `addMember` :152, `append` :206, `clearList` :363, `contents`
:375, `dQ` :474, `dumpField` :493, `get(String)` :754, `get(int)` :773, `getAttribute` :792, `getFromList` :876,
`getMember` :923, `makeRegistry` :1093/:1104, `merge` :1164, `mergeAttributes` :1185, `next` :1231, `nextAttribute`
:1244, `nextGroup` :1256, `nextMember` :1270, `pop` :1418, `prepend` :1436, `prior` :1450, `push` :1464, `remove()`
:1531, `sort` :1918, `updateContentFlags` :1955, `walk` :2005, `compareAttribute` :2049 and `compareTags` :2080 (both
sort comparators encode *attribute before member* inside one list); GroupList `clear` :33; GroupStak ctor :19,
`resetStak` :164, `resize` :178 (size from `listLength`); GroupControl `setBaseRegistries` :142 (builds a list object
directly).

**Instruments (core, measure.twk):** `labelTree` :243 and `labelSpans` :273 (raw `firstInList`/`nextInParent`
recursion), `measureBlockResult` :323, `measureFireLabelActionIn` :383, `measureLabelMint` :495 (`listLength` as a
count).

**The chain:**
- raw C++ walks: genParse `dupTermRefusal` :109-114 (2); GroupActions `ruleOfCensus` :125, :141, :142, :147 and
  `definersOf` :183.
- raw first/last/sibling reads: ruleActions `aCTionDelimText` :375, `foldDot` :1204, :1205, :1219, :1226,
  `handleDot` :1292, :1293, `isDotUxp` :1500, `refuseDotUnaryRight` :1533; Instruct `opDot` cases 401-404 (`nexT`,
  `prioR`, `firsT`, `lasT`) :423-435, **`opMinusMinus` :779, :782 and `opPlusPlus` :1192, :1193 -- the unqualified
  iterate step walks raw `firstInList`/`nextInParent`.**
- `listLength` as a count: Debug :21; ruleActions `aCTionSearch` :865, :874, `foldDot` :1217, `interpretXP` :1405;
  Instruct `opDot` case 5 (`listLengtH`) :370.
- raw `groupList` writes: Commands `copyOf` :113; GroupActions `saveLocalFields` :1085; **ruleActions `aCTionIterate`
  :605-607 -- the iterator is handed the source's `groupList` pointer.**

### The UNCLEAR sites (55)

- **position across kinds (`get(int)`, `x[n]`)** -- `get(int)` counts every entry from `firstInList`, `noPrint`
  included: chain `aCTionCodE` :159-160, `aCTionDefinE` :233, `aCTionIterate` :580, :586, `aCTionRunRulE` :793, :799,
  `aCTionSetBrackets` :886, `aCTionTraiT` :1039, `materialiseTerms` :508, `opGet` :514; **`runOP` :987-989,
  `runShortCircuit` :1045-1047 and `jitEmitShortCircuit` :1904-1906** -- operator nodes are built by `+%` in
  foldDot/handleDot/handleCall and by `+=` in interpretXP, so the index crosses kinds depending on who built the node;
  kant `incant/generate` :62, :73, :147, :148, :204 (`argument[1..3]` on parse nodes).
- **presence of `groupList`** ("has a list" -- depends on whether containers would be allocated lazily): core
  `embedAttribute` :526, `ensureGuard` :586, :611, `setContent` :1711, measure :231, :250, :280, :809; chain `copyOf`
  :112, `dumpContents` :132, `aCTionDefinE` :349, `aCTionFOR` :498, :499, `aCTionTokenXP` :1002, `handleCall` :1264,
  `jitEmitBareRead` :1035, `jitPrintProbe` :2782.
- **the iterate filter overload**: `aCTionIterate` :614-617 writes `hasAttributes`/`hasMembers` on the ITERATOR as
  filter selectors; `opPlusPlus` reads them back (:1190-1191).
- **order across kinds in kant output**: 7 emitter walks that write terms in list order -- `utilities` `listRules`
  :143, `anyOrNumT` :32, `bisectQ` :63, `f31` :45, `searchAcc` :33, `searchAccB` :34, `trigDO` :33, and
  `IncantForms/WorkingOn/parser` `generateParse` :28; plus `nexT`/`prioR` reads (nullAccessT, bisectQ :68, f31 :49,
  generate :232, attic/nullAccessorDeref :17, utilities :173).

### The property list (already separate since stroke 3)

`builtinActoR`, `CodE`, `ParsE`, `builtinParseR`, `pendingParseR`, `BlocK`, `JiT` live on `propertyList`, walked by
`getProperty` (GroupItem.twk:962) and by hand in `addProperty` :163 / `removeProperty` :1570; `nextProperty` :1278 has
**no callers**. Raw property walks: GroupActions `ruleOfCensus` :126, :148; `jitShowRecord` jitEmitters :3508. Facts
that bear on a containers shape:
- **`get(name)` falls back to `getProperty`** (:766), so every `[ ]`, `get`, `getAttribute` and `getLabelGroup` miss
  also scans the properties. `getAttribute` can return a property, because `addProperty` sets `isAttribute`;
  `getMember` cannot. Reached that way today: `builtinParseR` (Generate :325, jitEmitters :769, :2871), `BlocK`
  (jitEmitters :2106), `builtinActoR` (measure :338, :868; kant `propGetT` PG-1).
- `remove()` tries `removeProperty` first, so every term removal also walks the parent's property list.
- `copyOf` copies the whole body and replaces only `groupList`, so `propertyList` stays shared with the source (inferred).
- `addProperty` sets `isAttribute` and does not set `hasAttributes`/`hasTraits`.

### Facts read along the way (recorded, not evaluated)

- **`next()` never skips anything.** Its `noPrint` skip is gated on `ignoreNoPrint` (GroupRules.twk:104), which no
  `.twk`, `.rtn` or setup line ever writes (grep, 2026-10-06). So every `next` walk sees artifacts that are still on the
  group list, and the sites that want terms filter for themselves (17 kant `noPrinT` skips; chain `compile` :50, :93,
  `setParseWalk` :495, `processAction` :648, `appendPrintXP` :1170 ...).
- **`copyListTo`/`copyListFrom` re-add anything that is not `isAttribute` as a member** (GroupItem.twk:406, :423).
- **Flag upkeep is uneven:** `clearList` resets `hasAttributes`/`hasMembers` but not `hasTraits`; `pop()` updates none;
  `updateContentFlags` has **no caller** anywhere.
- **No callers in core scope:** `prior` (core only; the chain calls it), `dQ`, `GroupItem.pop`, `replace` (the chain
  calls it), `sort`, `walk`, `dumpField`, `updateContentFlags`, `nextProperty`, `firstComponent` (Instruct `opIN` calls
  it), `setDebug`.
- `sort()`'s bare `nextInParent`/`priorInParent` (:1928, :1931) generate `this->`, not the walked entry's.
- `getFromStak(int)` (GroupStak.twk:86) and `get(int)` disagree on 0- vs 1-based indexing (comment vs code).
- `GroupControl.twk` defines `locate(String)` twice, identically (:77, :95).
- The JIT's iterate/for emitters do no walk of their own; they emit calls to `aCTionIterate`/`opPlusPlus`/`opMinusMinus`.

### Fixtures pinned on list ORDER (kant pass, pop.sh read)

Order-sensitive pins: `iterT1`, `iterT1m`, `iterT3` (parked), `displayFormT` (attributes then members per node, by
qualified walks), `jsonTest` (JT ROOT/MEMBER/KID sequence), `kindT`, `kindJ1T`, `kindLiftT`, `propGetT` PG-4,
`propOpT` PO-4, `cursorReadT`/`cursorReadTb` (identity of the first visited entry), `anyOrNumT` (generated term order),
`shapeBodyT` (bodies from WorkingOn/parser's walk). Outside kant: **`oneTest.base` pins `audit()`'s `[n]` positions**
(`BlocK [4] builtinActoR`, measure.mm:150 -- 33 rows), and `parserCoverage.target` follows Grokking's member order.
`parseClass.target` is sorted before its diff and is not order-sensitive. Walking fixtures no harness pins: `emitRefT`,
`f31`, `ruleCount`, `searchAcc`, `searchAccB`, `bisectQ`.

### What step 1 does not say

No shape is proposed and nothing is recommended. The UNCLEAR rows are questions the shape would have to answer, not
findings. Inferences above are marked; none of the verdicts was measured by running a changed build.

## Step 1b -- the unclear sites classified, positional reads, copyListTo (2026-10-06, read-only)

### How it was measured

A temporary tap (reverted, every `.mm`/`.h` md5-identical to HEAD; fleet after revert 987 / 51) recorded, at every
positional read, the list it read, whether that list mixed attributes and members, and whether the hit was counted past
an entry of the other kind. Five seats: `get(int)` (with its caller), the unqualified iterate step (`opPlusPlus`),
`opMinusMinus`'s raw step, `opDot` 401/402 (`nexT`/`prioR`) and 403 (`firsT`). Run over pop.sh, jitLadder, printPop,
decodePop, ddPop and frontier. **H16, the known-bad end, came free:** the tap reported mixed lists where they exist (the
registries, below), so it can see a cross-kind read when one happens. A per-rule census walked every Grokking rule and
counted its attributes and members.

⚠ **Recount: step 1's kant UNCLEAR was 17; the explicit list is 22** -- 8 emitter walks (utilities `listRules` :143,
`anyOrNumT` :32, `bisectQ` :63, `f31` :45, `searchAcc` :33, `searchAccB` :34, `trigDO` :33, WorkingOn/parser
`generateParse` :28), 5 positional reads (`incant/generate` :62, :73, :147, :148, :204) and 9 sibling reads
(`nullAccessT` 4, `bisectQ` :68, `f31` :49, `generate` :232, `attic/nullAccessorDeref` :17, `utilities` :173). So the
pool is **60**, not 55.

### What the positional readers actually read (fleet, measured)

| reader | reads | lists it read |
|---|---|---|
| `runOP` `field[1..3]` | 2,342,946 | attribute-only 1,936,608 (the `+%` builds) · member-only 406,338 (interpretXP's `xl2`) · **never mixed** |
| `runShortCircuit` `field[1..3]` | 618,921 | member-only |
| `jitEmitShortCircuit` `field[1..3]` | 504 | member-only |
| label readers: `aCTionTraiT`, `aCTionDefinE`, `aCTionCodE`, `aCTionIterate`, `aCTionRunRulE`, `aCTionSetBrackets`, `foldDot` | 446,053 | attribute-only (labels are built by `attachLabel`'s `dest +% lab`) |
| `auditMissingTerms` (measure) | 311 | one kind per list |
| **`auditSpurious`** (measure; oneTest's `audit()`) | 1,139 | **117 on MIXED lists**, hits counted across kinds -- the registries (Utilities, pROPERTIEs, Keywords) and unitTests' sample fields |
| `opGet` (kant `x[n]`) | 2 | 1 attribute-only · 1 mixed (a miss) |
| unqualified iterate step | 37,390 | 28,893 attribute-only · 8,123 member-only · **374 mixed**: Grokking (termCountT, traitFlagsT, actorOrderT walk the registry), unitTests' `sample`, and ANYorNum inside anyOrNumT |
| `opMinusMinus` raw step | 28 | attribute-only |
| `nexT`/`prioR` | 4 | member-only parents |
| `firsT` | 1 | member-only |

**Per-rule census (Grokking, every rule):** 49 rules hold attributes only, 14 members only, **0 mix the two.** ANYorNum
is mixed in the fleet only because `anyOrNumT` hangs a noPrint copy of its CodE on it with `+%` (:47) -- that fixture's
own frozen idiom; the live parser files artifacts on the property list.

### R1 -- the 60 unclear sites, classified

| sites | verdict | why |
|---|---|---|
| presence tests: core `embedAttribute` :526, `ensureGuard` :586, :611, `setContent` :1711, measure `labelTree` :250, `labelSpans` :280, `measureTokenArm` :809; chain `copyOf` :112, `dumpContents` :132, `aCTionDefinE` :349, `aCTionFOR` :498, :499, `aCTionTokenXP` :1002, `handleCall` :1264, `jitEmitBareRead` :1035, `jitPrintProbe` :2782 (16) | **AT** | each reads the raw `groupList` pointer as "has entries"; under fixed containers a present pointer no longer says that |
| measure `includeGroupList` :231 (1) | **NO** | a tok include trick (`if field.groupList return;`) -- it exists only so GroupList.h is included, and reads nothing |
| iterate's filter overload, `aCTionIterate` :614-617 (1) | **AT** | it writes `hasAttributes`/`hasMembers` onto the iterator as the attributes/members selector, which `opPlusPlus` reads back; a containers walk picks a container instead |
| **instruction readers** `runOP` :987-989, `runShortCircuit` :1045-1047, `jitEmitShortCircuit` :1904-1906 (9) | **AT -- EXPRESSION-OWNED** | see R2 below; tagged per Tony's direction (not ruled): the expression redo rebuilds instructions as op, target, argument in one fixed layout. Listed, not designed for |
| label readers `aCTionCodE` :159-160, `aCTionDefinE` :233, `aCTionIterate` :580, :586, `aCTionRunRulE` :793, :799, `aCTionSetBrackets` :886, `aCTionTraiT` :1039 (9) | **INSIDE** | measured attribute-only on every read (446,053); `get(int)` keeps its meaning if it indexes the one populated container |
| `materialiseTerms` :508 (1) | **INSIDE** | no fleet read; it indexes a rule's terms, and no grammar rule mixes kinds (census) |
| kant positional `incant/generate` :62, :73, :147, :148, :204 (5) | **INSIDE** | `argument[n]` on parse labels, attribute-only |
| kant emitter walks (8, listed above) | **INSIDE** | an unqualified walk over one rule's terms; no rule mixes kinds, so list order within one container is the order they emit. anyOrNumT's mixed ANYorNum is its own `+%` artifact, and the walk skips noPrint |
| kant `nexT`/`prioR` (9, listed above) | **INSIDE** | sibling reads within one kind; the fleet's 4 reads all had member-only parents |
| `opGet` :514 (1) | **UNCLASSIFIED** | a kant `x[n]` on a field holding both kinds has no one container to index -- what `[n]` means there is the shape's to say |

**R1 totals: 26 AT (9 of them expression-owned), 1 NO, 32 INSIDE, 1 unclassified.**

**One INSIDE row from step 1 is AT on measurement:** measure `auditSpurious` :175 (`entry[i]`) read mixed registries
117 times, counting across kinds, and `oneTest.base` pins those positions (`BlocK [4] builtinActoR`, 33 rows). Also
recorded, not reclassified: unqualified iterates over a **registry** (termCountT, traitFlagsT, actorOrderT over
Grokking) visit both kinds in one pass; those fixtures are pinned by count and value, not order.

**Step 1 totals as amended: 102 AT · 46 NO · ~1,125 INSIDE · 1 unclassified · 0 unclear.**

### R2 -- positional cross-kind reads

**There are none in the instruction layout today.** Every node read by position holds one kind, and which kind is fixed
by its builder:

| node kind | builder | entries, in order | readers |
|---|---|---|---|
| `xp`, `uxp`, `xdot`, and a TokenXP label re-used as an instruction (`xpress`) | `handleCall` :1266-1268, `handleDot` :1287-1336, `handleSubscript` :1356-1368, `handleUnary` :1385-1386, `foldDot` :1228-1244 -- each clears or mints its node, then `+%` only (**attributes**) | op, target, argument (`uxp`: op, operand -- no third) | `runOP` `field[1..3]` |
| `xl2` | `interpretXP` :1465-1467 -- `+=` only (**members**) | op, target, argument | `runOP`, or `runShortCircuit` when the op is registered `shortCircuit` (:1471); `jitEmitShortCircuit` at emit time |
| `xl1` (juxtaposition) | `interpretXP` :1451-1452, `+=` (members) | args, then tokens | read as a list (`isLIST`), not by position |
| parse labels | `attachLabel` `dest +% lab` (**attributes**); the repeat case `dest +% lab.group` | the rule's matched terms in match order | `aCTionCodE`, `aCTionDefinE`, `aCTionIterate`, `aCTionRunRulE`, `aCTionSetBrackets`, `aCTionTraiT`, `foldDot`; kant `incant/generate` |
| registries | `+=`/`addString`/`+%` in GroupMain's bootstrap and `define` -- **both kinds** | sorted (`put`) | `auditSpurious` `entry[i]` (measure, oneTest), `opGet` on a registry |

**The same instruction layout in the JIT** (expression-owned with runOP): `jitEmitShortCircuit` (jitEmitters :1904-1906)
reads `field[1..3]` itself. `jitEmitOpFire`, `jitSeedOperands` and every `gJitEmitter` slot emitter take op, target and
argument already unpacked by runOP (GroupActions :1000-1010); `jitTermCallRT` (jitEmitters :973) re-runs `runOP` on the
node at run time.

### R3 -- can a property on the source come out as a member on the copy? **No.**

`copyListTo`/`copyListFrom` walk the group list only (`next()`), and properties live on `propertyList`. Probed both copy
roads, with a control member that does copy:

| | getMember `pcKid` (the property) | getProperty `pcKid` | control: getMember `pcMem` |
|---|---|---|---|
| `copyOf(pcHost)` | miss | **KID** -- the copy still reaches it | found |
| `pcSet = pcHost` (setContent -> copyListFrom) | miss | **miss** -- dropped | found |

Both copies hold 1 attribute and 1 member, the source's two terms. **No fixit.** Two facts, context under the relevance
gate (no row fails on either): `copyOf` copies the whole body, so the copy shares the source's `propertyList`; `=` loses
the properties. And `getAttribute` on the copy returns the property (it carries `isAttribute`), as step 1 recorded.
⚠ Separate from properties: `copyListTo` re-adds anything that is **not** `isAttribute` as a member, so an embedded or
unaffiliated entry on the group list does come out a member.

## Step 2 -- rStuff's place in a containers shape (2026-10-06, read-only)

No shape, no recommendation. Measured with a temporary entry counter in the 55 functions that read RuleStuff (inserted
into the generated `.mm`, restored from git, every `.mm`/`.h` md5-identical to HEAD; fleet after 987 / 51), over pop.sh,
jitLadder and printPop -- A3's "fleet run". The field-per-function map is static: every occurrence of the field in that
function's generated body, so **read volumes below are upper bounds** (writes and untaken branches included).

### The storage fact the whole step turns on

**`groupList` and `propertyList` live on `GroupBody` (GroupBody.twk:9-10), and a rule shares its body with every
instance:** the copy constructor sets `groupBody = grup.groupBody` (GroupItem.twk:44). The only per-node storage is on
`GroupItem` itself -- `rStuff` (copied per instance, `*rStuff = *grup.rStuff`), `parent`/siblings, `options`,
`labelOf`, `ruleOf`. **So under today's layout an attribute or a property hung "on the instance" lands on the rule's
shared body, and every instance and the rule see it.** A per-instance home in a list exists only if the list itself is
per-node -- which is A3's shelved "instances with their own bodies", or containers held on `GroupItem` rather than on the
body. Recorded, not weighed.

### R1 -- RuleStuff's fields today (after stroke 1.2 and the actionMethod cut)

19 members: 8 plain + 11 bits (`RuleStuff.h`). objectModel O8's test: same for every reference -> **rule**; differs per
reference, fixed -> **instance**; changes per call -> **activation**.

| field | kind | note |
|---|---|---|
| `ruleName` | rule | debug name -- but also `attachLabel`'s retag name (`destName = pStuff.ruleName`) |
| `testMatch` | rule | old-road leaf test, set by `setTestMatch` from the rule's shape |
| `parseMethod` | rule | the installed leaf |
| `jitMethod` | rule | read only by `jitFieldMethod` (raw) -- no parse-walk reader |
| `min`, `max`, `maxRepeat` | instance | repetition; `isTarget` is also computed from `max == 1` |
| `onGroup` | instance | per position in the parent (`getWhatFollows`, `embedAttribute`) |
| `followed` | instance | per position; the copy constructor clears it |
| `isTarget` | instance | |
| `modPercent`, `modPointer`, `modUnGuarded` | instance | the `% & _ { }` modifiers (stroke 1) |
| `noAdvance`, `noLabel`, `noSkip` | instance | |
| `notifyFail` | instance | |
| `overTo` (`upTo`/`upToOver`) | instance | |
| `ruleTerm` | instance | stroke 2 |

**4 rule, 15 instance, 0 activation.** The activation fields all left with stroke 1.2 (`ParseActivation`:
`label`, `hereAt`, `kount`, `sukcess` ...).

### R2 -- where each instance fact could live, and what a read costs

**Cost per read, by home** (from the code that would serve it):

| home | a read is | scan length |
|---|---|---|
| **RuleStuff (today)** | `getRStuff()` (a call returning the member), one load, a bit test. Inside RuleStuff's own methods (`checkInput`, `checkGuard`, `inputAt`, `mintLabel`, `getWhatFollows`) no pointer at all | none |
| **attribute, by name** | `get(name)`: walk the group list, one `strcmp` per entry; **on a miss, then walk the property list too**; then read the value through the attribute's own body | the list: Grokking rules hold **4.0 entries on average** (20 rules hold 2, 17 hold 3, one holds 53). A default-false flag stored as presence pays the **full scan plus the property fallback on every false read** |
| **property** | `getProperty(name)`: walk the property list, one `strcmp` per entry | the property list |
| **per-node list** | as above, plus whatever per-node container replaced the body-shared list | -- |

**Read volume on the walk, per fleet run (upper bound, calls x occurrences):**

| instance fact | est. reads | the walk readers that carry it |
|---|---|---|
| `maxRepeat` | 14.1M | `parse` 3.50M x4 |
| `onGroup` | 10.9M | `parse` 3.50M x3; `embedAttribute`; `getWhatFollows` |
| `noSkip` | 8.3M | `inputAt` 4.16M x2 |
| `isTarget` | 6.3M | `attachLabel` 2.98M x2; `embedAttribute`; `getWhatFollows` |
| `max` | 5.6M | `attachLabel` 2.98M; `testSet` 0.80M x2; `exitFromParse`; `parseLoop`; ... |
| `min` | 5.2M | `parse` 3.50M; `testSet`; `exitFromParse`; `parseLoop`; ... |
| `modUnGuarded` | 4.9M | `isUnGuarded` 4.81M |
| `ruleTerm` | 4.2M | `isRuleTerm` 3.88M |
| `followed` | 3.9M | `getStuff` 3.50M |
| `noLabel` | 3.7M | `mintLabel` 3.14M; `exitFromParse`; `opDot`; `upToMatch` |
| `notifyFail` | 3.5M | `parse` 3.50M |
| `noAdvance` | 1.4M | `testSet`; `exitFromParse`; `testString`; `testContainer`; `parseContainer` |
| `overTo` | 0.76M | `driveStep` 0.28M; `runLeafParse` 0.24M; `upToMatch`; `setParseWalk` |
| `modPercent`, `modPointer` | 0.04M each | `modify` only (define time) |

**About 73M instance-fact reads per fleet run, upper bound, almost all on the walk.** For scale: `parse`/`getStuff`
run 3.50M times, `checkInput` 4.08M, `checkGuard` 4.79M. Rule facts on the walk: `testMatch` 21.0M (`parse` x6),
`ruleName` 18.4M (`attachLabel` x5, `mintLabel`, `exitFromParse`), `parseMethod` 0.8M.
**Outside the walk** (Tony's principle: they pay for themselves): `opDot` (kant accessors, 0.13M), the `measure`
instruments, `modify`/`processFlags`/`aCTionDefinE`/`aCTionTraiT(data)`/`setRuleStuff`/`embedAttribute` at define
time, `setParseWalk`/`installParseMethod` at generation.

**Where each instance fact could live** -- the three homes the dispatch names, each with what it would cost the walk:

| fact | attribute on the instance | property | stay on RuleStuff |
|---|---|---|---|
| any of the 15 | a by-name scan per read (mean 4 entries + the property fallback on a miss) on a list that is **body-shared today**, so per-instance only with per-node containers | a by-name scan per read on the **body-shared** property list -- per-rule, not per-instance, today | today's cost: one call and one load |
| the hot ones (`maxRepeat`, `onGroup`, `noSkip`, `isTarget`, `max`, `min`, `modUnGuarded`, `ruleTerm`, `followed`, `noLabel`, `notifyFail`) | 3.5M-14.1M scans per run each | the same | -- |
| define-time only (`modPercent`, `modPointer`) | 37K scans per run | the same | -- |

### R3 -- what removing the `rStuff` pointer would take

**The 22 raw `->rStuff` reads** (pop.sh's tripwire row; 19 lines, comments excluded) **are none of them on the walk:**
16 in `measure.mm` instruments (`canonOf`, `measureFrameProbe`, `measureLoopVerdict`, `measureParentProbe`,
`measureParseClass`, `modsOf`, `parseClassify`, `probeNode`), 3 in `jitFieldMethod` (the jit's `jitMethod`), 1 in
`compareValues` (49,812 calls, a sort comparator).

**The pointer's real coupling is tok's spelling: every `x.rStuff` compiles to `getRStuff()` -- 85 sites in 44
functions, 29.9M calls per fleet run.** The walk's share, by calls per run:

| ≥ 1M | `getRStuff` 29.92M · `isUnGuarded` 4.81M · `checkGuard` 4.79M · `inputAt` 4.16M · `checkInput` 4.08M · `isRuleTerm` 3.88M · `ensureRStuff` 3.50M · `parse` 3.50M · `getStuff` 3.50M · `mintLabel` 3.14M · `fireLabelMethod` 3.06M · `deferredAbove` 3.06M · `attachLabel` 2.98M · `recordLabel` 2.00M · `testAttributes` 1.24M |
|---|---|
| 0.1M - 1M | `parkInRecord` 0.83M · `testSet` 0.80M · `testOptions` 0.59M · `captureSpan` 0.35M · `exitFromParse` 0.32M · `driveStep` 0.28M · `aCTionTraiT` 0.25M · `runLeafParse`/`parseRule` 0.24M · `testString` 0.24M · `parseLoop` 0.22M · `embedAttribute` 0.17M · `opDot` 0.13M · `aCTionDefinE` 0.12M |
| below 0.1M | `setRuleStuff`, `aCTionTraiTdata`, `compareValues`, `upToMatch`, `getWhatFollows`, `modify`, `processFlags`, `ensureGuard`, `parseSet`, `testAction`, `testContainer`, `parseContainer`, `parseString`, `setParseWalk`, `repeatsInLoop`, `installParseMethod`, `processCode`, `parseUpTo`, `testCharacter`, `parseCharacter`, `testAny` |
| never called in the fleet | `materialiseTerms`, `parseCondition`, `parseAction`, `reportMaxLimit` |

**And RuleStuff travels by value, not only through the pointer:** 14 engine signatures take one -- `parse(pStuff)`,
`getStuff`, `attachLabel(stuff, pStuff)`, `fireLabelMethod`, `deferredAbove`, `recordLabel`, `parkInRecord`,
`enclosingStuff`, `testAttributes`, `testOptions`, `driveFloorLabel`, `setTargetFlag`, `setRStuff`, and RuleStuff's copy
constructor -- plus 3 measure callouts; `ParseActivation.stuff` (GroupRules.twk:24) and the ruler's `ruleSTUFF` (:29)
hold one. RuleStuff's own methods (`checkInput`, `checkGuard`, `inputAt`, `mintLabel`, `getWhatFollows`,
`setTestMatch`) read the instance facts as `this`.

**The writers a replacement home would need:** the copy constructor (about 386K rule copies per run, A3), `ensureRStuff`
(lazy -- absent on 109 of 350 grammar terms, recon §9), `setRuleStuff`, `modify`, `processFlags`, `aCTionTraiT`,
`aCTionTraiTdata`, `getWhatFollows`, `embedAttribute`, `aCTionDefinE`, `setTargetFlag`.

## Step 3 -- containers against strokes 1.3 and 1.4 (2026-10-06, read-only)

### R0 (Tony, 2026-10-06) -- recorded

**rStuff is OUT of the containers scope.** It is an HPDL design issue (hard part, do later), not for now. **RuleStuff
stays a struct; A3 (instances with their own bodies) stays shelved.** Containers are **list organization only**. Step 2
stands as the record of what rStuff would cost if it is ever reopened. Also recorded in objectModel's open items (A4).

Read volumes below come from step 2's call counts (pop.sh + jitLadder + printPop, one fleet run). Each read is counted
in its function's source and generated body, **excluding parseTrace-gated lines**, so these are executed reads, not
step 2's upper bounds.

### R1 -- does stroke 1.3 (stuff derived; `face` renamed `instance`) touch list layout? **No.**

1.3's sites are `ParseActivation`'s own fields (`GroupRules.twk:19`, `:24`) and their readers and writers: the creators
(`parse()` GroupItem.twk:1300/1306, `parseRule` Generate.rtn:282/288, `driveFloor` GroupActions.rtn:243/250, `topFloor`
:821/827, `probeFloor` jitEmitters.rtn:795); the record matches in `recordLabel` and `parkInRecord` (Generate.rtn:29,
:39), `enclosingStuff` (:51-53), `exitFromParse` (:85-89, :108), `deferredAbove` (GroupItem.twk:447-449),
`driveFloorLabel` (GroupActions.rtn:212) and `refire` (:285); one trace line in `attachLabel` (:257-259). None reads
`groupList`, a list end, a sibling pointer or `listLength`. **One site reaches a list through a primitive:**
`enclosingFace` (Generate.rtn:21) returns `top.face.get(field.tag)` -- a by-tag `get`, INSIDE in step 1's terms, so a
rename touches only the spelling of `face`.

### R2 -- stroke 1.4: rule facts onto `groupBody`

| fact | executed reads per fleet run on the walk | readers |
|---|---|---|
| `testMatch` | **3.50M to ~21M** -- at least 1 per `parse()` call (3,497,172; the `if testMatch \|\| onGroup \|\| hasAttributes` guard), and up to 6 when set (the call, then the `leafDone` compare against `testAny`/`testCharacter`/`testSet`) | `parse()` GroupItem.mm:1718-1723; `getWhatFollows` (40K, define time) |
| `ruleName` | **up to 6.4M** -- `attachLabel` 1 per call that has a parent stuff (≤ 2,984,173; `destName = pStuff.ruleName`), `mintLabel` 1 string compare per call (3,139,871; `ruleName ne field.tag`), `exitFromParse`'s label retag (≤ 315,742) | the other 4 mentions are trace-gated or `measure` |
| `parseMethod` | **~0.53M** -- `runLeafParse` 2 per call (243,463), `testAction` 2 (31,275), `repeatsInLoop` 1 (10,254) | writes at generation: `setParseWalk` (18,809), `installParseMethod` (9,211), `setParseAction` |
| `jitMethod` | **0 on the parse walk** | `jitFieldMethod` only (jitEmitters.rtn:2132-2133, the JIT's field method); not in step 2's count |
| `ruleOf` + `instanceRule()`'s REGISTRY test | **243,463 `instanceRule()` calls** (one per `runLeafParse`): `ruleOf`, `ruleOf.parent`, `holder.isREGISTRY`, then `definer.rStuff` | also `installParseMethod` (9,211, generation), `setParseWalk`'s `!field.ruleOf` (18,809), `setRuleStuff` (91,549, define time), `jitFieldMethod`/`jitShowRecord`, the `ruleOfCensus`/`definersOf` instruments |

**Cost per read, two homes (from the code that would serve it; no shape):**

| home | a read is |
|---|---|
| **`groupBody` slot** (A5 stroke 4) | `this->groupBody->fact`: two loads, and `groupBody` is already in hand on these lines (`parse()` reads `groupBody->flags.hasAttributes` beside `testMatch`). Shared by the rule and every instance by construction, so **`instanceRule()`'s hop disappears**: `runLeafParse` reads `field->groupBody->parseMethod` instead of `ruleOf` -> `parent` -> `isREGISTRY` -> `definer` -> `rStuff` -> `parseMethod` |
| **property under fixed-position containers** | body -> the properties container (a fixed position, so one more load) -> **find the fact inside it**: by name, a `strcmp` walk of the property entries (today's `getProperty`); by a fixed slot inside the container, a further walk or index -> the entry -> the entry's body -> the value (`gMethod` for a method, `tag` for a name). The property list already holds the artifacts (`builtinActoR`, `builtinParseR`/`builtinParsE`, `CodE`, `ParsE`, `BlocK`, `JiT`, `pendingParseR`); its per-rule length was not measured |

**Facts read along the way:** `ruleName` is initialised from the tag (`RuleStuff.twk:32`, `ruleName = tag`), so on the
body it would sit beside `groupBody->tag`; `mintLabel`'s read is a string compare of the two. `testMatch` and
`parseMethod` are function pointers: as a property each becomes a node whose `gMethod` holds the pointer. Today both
are copied into every instance's `rStuff` by the copy constructor (about 386K rule copies per run, A3's figure), which
is why `installParseMethod`/`instanceRule()` exist (F-O32, 4.3).

### R3 -- order: before, after, or independent of a containers build

- **1.3 is independent.** It touches no list layout (R1); its one list read goes through `get(name)`, which a
  containers build would re-aim inside the primitive.
- **1.4 as A5 states it (body slots) is independent.** Its reader sites (`parse()`'s `testMatch`, `attachLabel`/
  `mintLabel`/`exitFromParse`'s `ruleName`, `runLeafParse`/`testAction`/`repeatsInLoop`'s `parseMethod`,
  `jitFieldMethod`, `instanceRule()` and its callers) are none of them in step 1's AT list, and a body slot is not a list
  entry. Either order reworks nothing in the other; the two share files (`GroupItem.twk` `parse()`, `Generate.rtn`), so
  the cost of running them side by side is merge, not meaning.
- **1.4 with rule facts as properties is NOT independent.** It needs the properties container to exist, so it runs
  after a containers build; run before, its readers are written against today's `getProperty` scan and re-aimed when
  the container lands (inside the primitive if read by name; respelled at each site if the shape gives facts fixed
  slots). Either way the walk's rule-fact reads (3.5M-21M `testMatch`, up to 6.4M `ruleName` per run) would move from
  two loads to a container lookup per read.
- **R0 removes the other coupling:** with rStuff out of scope, 1.4's retirement of `ruleOf` and the REGISTRY test does
  not wait on anything containers decides.
