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
