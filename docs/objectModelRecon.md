# Object-model recon: rule, instance, activation

Read-only recon for the curveball design discussion (Tony, 2026-09-28; Clay's three-level
refinement). **No code changed.** Measured on trunk `jit-unified-emit-wip` at `836c763`, **tok**
source (`*.twk`, `*.rtn`) and the tok-generated `*.mm`. Counts are grep counts and are
approximate. The classification is the finding, not the numbers (H9).

Asked for: the seam census, the three-level `rStuff` table, the flags table, the kernel
inventory. Then the two options (delegation and copy) walked on paper, not coded.

---

## 1. The headline: today's model is BOTH options at once, split along the wrong line

The copy constructor (`GroupItem.twk:42`) is the whole story in six lines:

```
GroupItem(GroupItem grup)
    groupBody   = grup.groupBody;      <- SHARED: delegation, with no per-instance override
    isCopy      = true;
    if grup.rStuff
        rStuff  = new(this);
        *rStuff = *grup.rStuff;        <- COPIED: a full snapshot, with no propagation
        rule    = this;
        followed = isOK = sukcess = false;
```

- **Everything in `GroupBody` is delegated with no override.** Tag, list, data, methods and
  all ~60 flags are one object shared by the rule and every face. A write through any face lands
  on the rule, and on every other face.
- **Everything in `RuleStuff` is copied with no propagation.** Modifiers, limits, the label and
  the parse/action method pointers are a snapshot taken at copy time. A later write to the rule
  (say, an installed parse) does not reach a face.

So the design question "delegate or copy?" has in practice been answered **both ways at once**.
The dividing line is the storage boundary (`groupBody` vs `rStuff`), and that line does not
match any semantic boundary. **Each seam bug is a field sitting on the wrong side of that line
for the question being asked of it:**

| field | lives in | so it is | the question asked of it | what broke |
|---|---|---|---|---|
| `isRule` | body | shared | "is THIS node a rule?" | back-propagation to the master (8 write sites) |
| `unGuarded`, `isPercent`, `isPointer`, `isMacro` | body | shared | set by a modifier at ONE reference | see §4.3: structurally reaches every reference |
| `parseMethod`, `actionMethod` | rStuff | copied | "what is this rule's shape?" | installed parse invisible to faces, hence `definingRule()` |
| `label`, `parentLabel` | rStuff | copied, and ONE per node | "what did THIS activation mint?" | recursion; F-114's bracket; `ParseActivation` |

`definingRule()` (`GroupItem.twk:455`) is a delegation pointer that was never declared:
*"the definer is the first child's PARENT, by pointer."* It works only because the child list is
shared and the children's `parent` points at the defining node.

---

## 2. The three-level `RuleStuff` table

Levels (Clay): **Rule**, the shape as defined. **Instance**, one reference site in the grammar
(`NamE?` inside `TokenXP`). **Activation**, one parse of that instance.

| field | level | notes (writes / refs in generated code, approx.) |
|---|---|---|
| `rule` | rule-ptr | the delegation pointer itself; `getStuff` compares `stuff.rule != this` |
| `ruleName` | rule | debug copy of the tag |
| `sourceLine` | rule | where defined (`ruleActions.rtn:952`) |
| `testMatch` | rule | leaf matcher chosen from the rule's data kind (`setTestMatch`) |
| `parseMethod` | rule | 14 writes. Ruled to go to the definer ("shape vs frame") |
| `actionMethod` | rule | |
| `jitMethod` | rule | |
| `hasMacro` | rule-ish | copied from body `isMacro`, which a `$` modifier writes. See §4.3 |
| `min`, `max`, `maxRepeat`, `limitsSet` | **instance** | `+ * ?` and `[min max]` at a reference |
| `banged`, `noAdvance`, `noLabel`, `noSkip`, `isTarget`, `overTo` (`upTo`/`upToOver`) | **instance** | `! < - ^ @ { }` at a reference. `isTarget` is also *computed* (`max==1`, `Generate.rtn:438`) |
| `notifyFail` | instance | `f` flag command |
| `followed`, `onFail` | instance (lazy) | `getWhatFollows()`: what follows this term in its parent. `onFail`: 0 readers found |
| `onGroup` | instance | the embedded group this term also matches (`embedAttribute`) |
| `parentStuff` | **instance and activation, conflated** | set at construction from the grammar parent (instance), but read at parse time for `parentLabel` and walked by `deferredAbove` (activation) |
| `label` | **activation** | ~92 refs. The single most-read field |
| `parentLabel` | **activation** | 7 writes. F-114's bracket exists for this one |
| `kount`, `sukcess`, `isOK` | **activation** | `sukcess`: 34 writes, 56 refs |
| `hereAt`, `failedAt` | **activation** | input marks for rewind |
| `inProcess` | **activation** | the recursion detector (below) |
| `guardOK`, `guardFAIL` | activation | guard evaluation state |
| `doNothing` | ? | one write (`ruleActions.rtn:977`), one read |
| `isOption` | dead | 0 readers |

**The finding nobody had written down: there is already a fourth mechanism for activations.**
`getStuff` (`GroupItem.twk:1033`):

```
    if stuff.rule != this || stuff.inProcess {
        stuff       = new(rStuff);          <- a fresh activation copy, only on recursion
        stuff.rule  = this; }
```

So activation state lives in the node's own `rStuff` **unless** the rule is already running, in
which case a copy is made. On top of that, the new road added `ParseActivation`
(`jitContext.h:707`, `{stuff, prev, floor, label}`): a C++ stack that answers "who is active
above". **Activations currently have three homes: the node's rStuff, the recursion copy, and
the ParseActivation stack.** That is the hamster wheel measured as data structures.

Tally: **rule 8 · instance 13 · activation 9 · conflated 1 · dead/unknown 3.**

---

## 3. The flags table (`GroupBody.bools`, `GroupItem.options`)

Classified by the level each flag *means*, next to where it *lives*. Anything not at rule level
and living in the body is shared by every face. That is a seam by construction, whether or not
it has ever bitten.

| level it means | flags | lives in |
|---|---|---|
| **rule / shape** (sharing is correct) | `isRule` (Ruling D: rule-*shaped*), `hasNewParse`, `parseWalked`, `tokened`, `binType`, `methodType`, `instructType`, `actionType`, `isUnary`, `isXP`, `hasTraits`, `isSingleton`, `isVirtual`, `mergeOn`, `addingMembers`, `isIndexed`, `isSorted`, `isWindow` | body |
| **value kind** (orthogonal to parse) | `data` (isCOUNT… isTOKEN), `fileType`, `isLiteral`, `isShortcut`, `isPointer`?, `byRef` | body |
| **instance** (set at ONE reference) | `unGuarded`/`guarding`, `isPercent`, `isPointer`, `isMacro`, via `modify()` (see §4.3) | **body: wrong side** |
| **instance, per node** | `affiliation` (isAttribute/isMember/isEmbedded), `isCopy` | GroupItem `options`: right side |
| **action frame** | `isLocal`, `isArgument`, `recursive`, `isIterator` | body. Per action; `saveLocalFields`' territory |
| **activation / runtime state** | `isBranch` (break/continue/return), `guardInProcess`, `fLAG` (two meanings, ledgered), `invoke`, `altered`, `debugged`, `isInitialized`?, `deferred`? | body: **wrong side** |
| **presentation** | `noPrint`, `reversePrint`, `negate`, `isToggle`, `isCondition`, `isAssign` | body. `noPrint` also doubles as "I am an artifact" (#50) |

`?` = not settled by this recon. `deferred` is a rule property (a `defer` action) but is *read* by
the activation walk. `isInitialized` has 24 writes and needs its own look.

**Only two flags live on the per-node side today (`affiliation`, `isCopy`).** Every other
instance-level or activation-level flag is shared.

---

## 4. The seam census

Sites that cross rule and instance, from **tok** source, comment lines excluded.

| crossing | sites | where |
|---|---|---|
| `definingRule()` callers (face → definer walk) | **13** | GroupItem.twk ×3, Generate.rtn ×2, genParse.rtn, GroupActions.rtn ×3, jitEmitters.rtn ×2, measure.twk ×2 |
| body-sharing copies (`groupBody = x.groupBody`, `*groupBody = …`) | **2** | copy ctor `GroupItem.twk:44`; `copyOf` `Commands.rtn:129` (`*groupBody = *…`: copies the body's *contents*, so a twin carries the action; #34) |
| rStuff snapshot copies (`*rStuff = *…`, `new(rStuff)`) | **4** | copy ctor; `getStuff`'s recursion copy; `setRuleStuff`'s re-own; `ruleActions.rtn:318` |
| rStuff (re)owners (`setRuleStuff` calls) | **48** | 40 in GroupMain's bootstrap, 8 elsewhere |
| direct `rStuff =` writes | **15** | GroupItem.twk ×8, ruleActions.rtn ×6, Commands.rtn ×1 |
| `isRule` writes on shared body | **8** | GroupItem.twk ×2, GroupMain.twk ×2, ruleActions.rtn ×3, Commands.rtn ×1 (matches Clay's "eight write sites") |
| `isCopy` readers | **0 in the engine** (declared, set once by the copy ctor) + 6 in `measure.twk` | nothing in the engine *decides* on it |
| `parkOnMaster` | **0** | retired; survives in designDocs prose only |

### 4.1 `isCopy` is written and never consulted

Exactly one node-level fact says "I am a face, not the rule", and **no engine code reads it**.
Every reader that needs the distinction reconstructs it instead: `definingRule()`'s pointer walk,
`getStuff`'s `stuff.rule != this`, Ruling D's shape-vs-liveness test.

### 4.2 The bootstrap is where rStuff is born

40 of the 48 `setRuleStuff` calls are GroupMain's hand-built seed grammar. `materialiseTerms`
(`GroupActions.rtn:489`) exists to close the gap those hand-built rules leave. Any new object
model has to rebuild this bootstrap first; it is the kernel's front door (§5).

### 4.3 Four modifiers write instance facts into the SHARED body (structural, unmeasured)

`modify()` (`GroupActions.rtn:525`) is the reference-site modifier switch. Ten of its fourteen
cases write `rStuff` (per node, which is right). Four write the shared body:

```
case '%':   isPercent = true;      case '&':   isPointer = true;
case '_':   unGuarded = true;      case '$':   isMacro   = true;
```

So `Foo_` at one reference marks the body that every reference to `Foo`, and its definition,
shares. **This is structural and visible in source. Whether any grammar in the tree relies on
it, or suffers from it, is NOT measured.** It is a candidate member of the seam family, graded
as such. `{` and `}` also set `unGuarded`, so they belong on this list too.

---

## 5. Kernel inventory: what a kant-written parse would still need from C++

**What the kant road is today:** `parser()` (`IncantForms/WorkingOn/parser`, 392 lines)
generates bodies of the form `return A() && B() || C();`. That is **sequencing and alternation
only**. Every term call goes back into C++ (`driveStep` → `parse()`/`parseRule`, `checkInput`,
`attachLabel`, `fireLabelMethod`). So the kant road moved the *grammar walk* into kant and left
the *matching and bookkeeping* in C++.

The C++ parse core, grouped by what a kant rewrite would do with it (sizes are rough tok line
counts):

| group | functions | ~lines | fate under a kant parse |
|---|---|---|---|
| **input substrate** | `checkSkip` 115, `pushInput`/`popInput` ~50, `checkInput` 46, `setMark`, `atRuleMark` | ~220 | **KERNEL.** Byte-level; stays C++ and gets exposed as commands |
| **leaf matchers** | `testCharacter`, `testSet`, `testString`, `testAny`, `testUpTo`, `testContainer`, `testCondition`, regex | ~100 | **KERNEL.** One command per kind; the JIT can inline them |
| **bootstrap** | GroupMain seed grammar (40 `setRuleStuff`), `embedRule` 108, `materialiseTerms` | ~300 | **KERNEL, rewritten.** Something must build the first grammar |
| **the activation machine** | `parse()` 67, `getStuff` 19, `attachLabel` 59, `fireLabelMethod` 36, `testOptions`/`testAttributes` ~25, `getWhatFollows` 19, `ParseActivation`, `deferredAbove` 30 | ~260 | **MOVES TO KANT.** This is exactly the rule/instance/activation code |
| **new-road drivers** | `driveStep` 71, `parseRule` 82, `parseLoop` 16, `parseContainer` 61, `exitFromParse` 23, `runLeafParse`, `repeatsInLoop`, `driveFloorLabel` | ~290 | **MOVES OR DIES.** Most exist to bridge the kant body back into C++ |
| **generation/installation** | `setParse`, `setParseWalk` 51, `installParseMethod`, `parseR` | ~90 | shrinks. Installing a parse becomes "the rule has a body" |

**Already registered as commands** (`incant/setup`): `setMark`, `setParse`, `probeDrive`,
`labelTree`, `traceParse`, `parseClassify`, `getLine`. **Not registered:** the leaf matchers,
`checkSkip`, push/pop input, and any read of the current mark. **A kernel floor is about the
first two rows plus a rewritten bootstrap, about 600 lines of C++, down from about 1,300 across
all six groups.** That floor is a first sketch to argue with, not a commitment.

**Tony's "tall hill" worry, located:** the hill is **row 4**, the activation machine. It holds
`hereAt`/`failedAt` rewind, repetition with a min, input-divert popping at end of message, label
promotion (`isTarget`) and fire order. It is small in lines and dense in rulings, and every ruling
in it is pinned by a fleet row. Rows 5 and 6 are mostly bridges that a unified model would not
need.

---

## 6. Walking both options (sketch, no code)

The same seven scenarios, three ways. **Today** is the hybrid from §1.

**Delegation:** an instance holds `rule` (one pointer) plus only its own attributes. A read tries
the instance first and falls through to the rule. A write lands on the instance unless it names
the rule explicitly.

**Copy:** an instance is a full copy of the rule at creation, with its own everything.

| # | scenario | today | delegation | copy |
|---|---|---|---|---|
| 1 | grammar redefines `Foo` | body shared, so faces see new terms; rStuff stale | **free**: faces read through `rule` | **needs a propagation pass**: every instance recorded, re-copied or patched |
| 2 | a generated parse is installed on `Foo` | lands on the definer's rStuff; faces need `definingRule()` | **free**: a rule-level attribute | as #1 |
| 3 | modifier `_` at ONE reference | writes shared body, so reaches all (§4.3) | lands on that instance only | lands on that instance only |
| 4 | write `x.flag` through a face, then read it | lands on the master; every face sees it (broadcast) | lands on the instance; read-your-write holds; no broadcast | lands on the copy; holds; no broadcast |
| 5 | recursion: `Expr` inside `Expr` | one rStuff per node, plus `getStuff`'s inProcess copy, plus `ParseActivation` | activation is a **third object** (stack frame) → clean | a per-activation copy of the whole rule → correct, costly |
| 6 | "what rule am I?" | `definingRule()` walk, or `isCopy` (unread) | `instance.rule`, one pointer | must be stored anyway (a copy has forgotten its origin) |
| 7 | memory per instance | node + rStuff (~35 fields) | node + own-attribute list (often empty) | node + full list + full attributes |

**Reading the table:**

- Copy wins #3 and #4 outright, but **so does delegation**. Those two are fixed by "writes land on
  the instance", and both options have that.
- Delegation wins #1, #2 and #6 for free. **Copy has to rebuild delegation to pass them**: #6
  forces it to keep a rule pointer, and #1/#2 force it to walk from the rule to its instances.
  That is delegation plus a cache.
- #5 is decided by the **third level**, not by copy-vs-delegate. Either option leaves recursion
  broken if activation state stays on the instance.

**Tony's answer on grammar changes (2026-09-28) is the tie-breaker:** *"change the grammar changes
the instances that are defined based on the rules they reference."* That is #1. It is free under
delegation, and under copy it needs a new mechanism (a rule → instances back-index plus a
re-copy). **On this recon, copy is delegation with an eager cache and an invalidation
problem.** The lean is delegation, three levels.

### 6.1 What delegation owes, stated so it is not oversold

- **A read rule.** Instance first, then rule. Does fall-through apply to members (the list) or
  only to attributes? Today's list is shared, and the parse leans on that (`definingRule`,
  hasNewParse), so the natural answer is **the list lives on the rule; instances carry
  attributes only**. That needs Tony's ruling.
- **An explicit rule-write spelling.** Kant needs a way to say "write the rule, not me" (today's
  accidental broadcast, made deliberate). Candidate: write through `x.rule`. Unexplored.
- **Flags.** If flags become attributes, a flag read is a lookup plus a fall-through. Clay's cache
  suggestion (bitfield on the hot path) keeps the bitfields as a derived cache. That conflicts with
  "get rid of bitfields" only in timing, not direction.
- **The three homes of activation collapse to one:** a frame per activation holding `label`,
  `parentLabel`, `kount`, `sukcess`, `hereAt`, `failedAt`. On success it **becomes the label**
  and attaches (Ruling E-A); on failure it is dropped and collected. `getStuff`'s copy,
  `inProcess`, F-114's bracket and `ParseActivation` all retire into it.

---

## 7. Against the four open questions

| question | where the recon leaves it |
|---|---|
| delegation or copy? | **walked (§6).** Delegation, unless the answer on grammar changes is withdrawn |
| must a grammar change reach instances? | **Tony: yes.** Free under delegation |
| flags: attributes with a cache, or bitfields? | direction attributes, bitfields as cache; the §3 table is the migration list. **Not urgent** (Tony) |
| how much C++ is the permanent kernel? | **first sketch: input substrate + leaf matchers + bootstrap, ~600 lines (§5).** To be argued |

---

## 8. Try-and-buy (proposed by Clay; not started, not authorised)

The Scaf family built on delegation with three levels, parsed in kant against the §5 kernel
commands, compared with the old tree. Disposable, on its own branch. It answers "is it simpler"
by measurement. **Owed before it can start:** the list-vs-attribute fall-through ruling (§6.1)
and a decision on whether `parse-then-fire` pauses at P6's open question (Clay's lean, not yet
ruled).

---

## 9. Addendum, same day: Clay's three A/B measurements

**Instrument.** An lldb expression run against the stopped Debug binary (`~/bin/incant`, no
source or build change). It walks every rule in the `Grokking` registry and descends inline
sub-terms, but never through a term that shares its body with a registered rule. Per term it
records: body shared with the registered rule, `rStuff` present and owned, `min`/`max`, each
`rStuff` modifier bit, the body's `guarding`/`%`/`&`/`$` bits, and `noPrint`.

- **Control (H11):** `InvokE`'s optional term reads `min 0`, so the override column is live.
- **Instrument slip, caught:** the first post-compile run stopped at the *first*
  `stopParsingInput`, which is inside `include(unitTests)`, before `parser(Start)` runs. It
  reported "no artifacts". The absence was the instrument's (the population searched predated
  the compile). The rerun skips the first hit.

### 9.1 Instances per rule, and how many carry anything of their own (at rest, before any compile)

63 rules, 350 term rows. **158 terms are references to a registered rule, and all 158 share
that rule's body** (0 references with a body of their own).

| refs per referenced rule | 1 | 2 | 3 | 4 | 5 | 6 | 8 | 10 | 11 | 16 |
|---|---|---|---|---|---|---|---|---|---|---|
| rules | 58 | 10 | 4 | 3 | 1 | 1 | 1 | 1 | 1 | 1 |

- **81 of 158 references (51%) carry an own modifier.** By kind: repetition only 30, noLabel
  only 30, `noLabel noAdvance noSkip` 11, repetition + noLabel 7, noSkip 2, overTo 1.
- The heavy repeats are punctuation and it is all overrides: `SemI` 16 refs / 16 own,
  `followedBy` 11/11. Structural rules mostly read through: `ExpressioN` 10/2, `StatemenT` 8/2,
  `ANYtoken` 6/0, `NumbeR` 5/0.
- **Reading for A vs B:** half the instances override, but each override is 1–3 small
  instance-level facts (all §2's instance column). Nobody overrides shape. That is delegation's
  profile: a short own-list over an inherited everything. Under copy, every one of the 158 would
  duplicate its rule to change one bit.

### 9.2 §4.3 is now MEASURED, not just structural: a `}` at one reference unguards every reference

`SetBrackets leftBrace- rightBrace};` (`incant/grammar:55`). The `}` sets `upToOver` in
SetBrackets' own `rStuff` (overTo=2 on that row only, correct) **and** `unGuarded` on the body
`rightBrace` shares. Registry read: `rightBrace` body `guarding = 2` (`unGuarded`).
`Braced` (`rightBrace-="]"`) and `Limit` (`rightBrace-`) never asked for it and read it anyway.
Same `rStuff`/body split as §1, inside one modifier. **Behaviour impact is NOT measured**
(guarding on a literal `]` may never matter). `leftBrace`'s `="["` in `Braced` is a restatement of
the bootstrap value, not a leak.

Other shared bodies reading `unGuarded`: `PRINTing` (3 refs), `DEFINing` (2), `define` (1). Their
source is not yet traced.

### 9.3 The artifact population in term lists (after `parser(Start)` and an action compile, `driveCompileT`)

| entry at a rule's top level | rules carrying it | beneath it |
|---|---|---|
| `builtinParseR` (the generated-parse carrier) | 57 | `CodE` → `BlocK`, `this`, `tempField` |
| `builtinActoR` | 33 | none |
| `frameSTAK` | 19 | none |

**59 of 63 rules end up with artifacts mixed into the list their terms live in.** A carrier adds
four more noPrint nodes below it.

⚠ **The census tripped over this itself, which is the argument in one line:** the walk's
"real term" count went **317 → 792** after the compile. It descended into each carrier's
compiled code and counted statements as grammar terms, because nothing structural separates a
term from a property. Every term walker in the tree carries the noPrint gate for this reason
(`countRuleTerms`, #50). **Clay's terms-vs-properties split holds under either option, and this
is its population.**

### 9.4 Not done: rule-level vs instance-level reads per parse

This one needs a runtime count of `rStuff`/body reads, split by §2's levels. That is a `measure*`
callout in `parse()`/`checkInput`/`attachLabel`, which is a code change, so it wasn't run in a
read-only pass. A static proxy from §2 (refs in generated code): activation fields dominate
(`label` 92, `sukcess` 56), then instance (`min`/`max`/modifiers ~100 combined), then rule
(`parseMethod` 25, `actionMethod` 17, `rule` 28). That counts sites, not executions, and says
nothing about the hot path. **Owed if the chain-walk cost becomes the deciding question.**

---

## 10. Header check of Clay's five-stroke table (2026-09-28, read-only)

Clay's per-stroke table was written from the seal record. Checked against `GroupItem.h`,
`RuleStuff.h`, `GroupBody.twk` and `jitContext.h`, with every reader of the stroke-1 bits read by
line.

**Headers as they stand.**
- `GroupItem`: `groupBody`, `parent`, `nextInParent`, `priorInParent`, `rStuff`, `jitData`,
  `options` {`affiliation`:2, `isCopy`}.
- `RuleStuff`: 18 members + 17 bitfields, exactly the §2 rows.
- `ParseActivation` (`jitContext.h:707`) is a **plain C++ struct**, not a tok class:
  `{stuff, prev, floor, label}`, and it **already has `label`**.

| stroke | correction |
|---|---|
| **1** | **The four body bits each carry a second, non-modifier meaning, so they cannot be removed.** `isPointer` is a value-kind bit (`GroupItem.twk:349,1003`: the `gPointer` union; `Instruct.rtn:803`; `Stylish.twk:180`). `isPercent` is a print format (`GroupItem.twk:1071`). `isMacro` is read at define time (`ruleActions.rtn:312,338`; the `macro` flag command writes it). `guarding` is a bin/registry property (`GroupList`, `GroupStak`, `Commands.rtn:291-323`) and `unGuarded` has body-level writers (`GroupItem.twk:586`, `Commands.rtn:311`). **So stroke 1 is a one-channel-one-meaning SPLIT:** `modify()` stops writing the body, and the reference-site fact goes to `rStuff`. The body bits stay. |
| **1, population** | **Only `unGuarded` is live at a reference.** The §9 census found 0 of 158 references with a `%`, `&` or `$` bit on their body; the only reference-site body bits are `unGuarded` (from `_ { }`). `hasMacro` and `overTo` already live in `RuleStuff`. So stroke 1 is probably **one new `RuleStuff` bit** (instance `unGuarded`) plus rerouting `%` `&` `$` (dormant, no live specimen). |
| **4** | `isCopy` is in **GroupItem.options**, not GroupBody. **An instance→rule pointer already exists and is aimed at SELF:** `RuleStuff.rule`, which the copy ctor sets to `this` (`GroupItem.twk:47`). But 109 terms have no `rStuff` at all (lazy, §9), so it can't carry the link as is. The two shapes: a new `GroupItem` field (layout: `groups.ext` `external GroupItem` + tokall), or re-aim `rStuff.rule` and make `rStuff` eager. That choice is the stroke's design question. |
| **5** | `ParseActivation` is not tok-generated, so adding fields there is **no `groups.ext`/tokall**. **Removing** the activation fields from `RuleStuff` is the layout change. `label` already has a slot. |
| **3** | A property list on `GroupBody` is a GroupBody layout change. Beyond `groups.ext` + tokall, it owes the bear-trap #10 subdirectory check (`GUI/*.twk`, `GUI/Stuff/*.twk`, `Tests/*.twk` are unswept by tokall). |
| **2** | No layout change, confirmed. The 8 write sites are §4's list. |

---

## 11. Stroke 3 step 0: terms and properties (2026-09-28, trunk `4f69c7b`, read-only)

**Scope note first:** artifacts sit on **action** lists as well as rule term lists (`CodE`, `tempField`, `frameSTAK` on actions), so "separate terms from properties" is a `GroupBody` change for every field that carries artifacts, not a grammar-only change.

### 11.1 Writers (≈ 12 sites)

| site | writes | onto |
|---|---|---|
| `setActions` (`GroupItem.twk:1649/1666/1677`) | `builtinActoR` (three shapes), and moves the action's `CodE` into it (`:1660`) | the rule |
| `aCTionDefinE` (`ruleActions.rtn:306-349`) | `CodE` (noPrint), `tempField` | the action being defined |
| `compile` (`Commands.rtn:56-97`) | `tempField`; the staged `pendingParseR`, retagged `builtinParseR` when green | the field |
| `attachBlocK` (`GroupItem.twk`) | `BlocK` | the action or parse holder |
| `frameStak` (`GroupActions.rtn:293`) | `frameSTAK` | the action |
| kant generator (`IncantForms/WorkingOn/parser:37-46`) | a `pendingParseR` carrier holding a `copyOf(CodE)` | the rule |

The "binding attributes" named in the dispatch (`builtinParsE`) no longer exist in source.

### 11.2 Name lookups: ONE mechanism

Every name read of an artifact goes through **`get(String)`**, which walks the single `groupList`. `getAttribute(name)` calls `get(name)`, and kant's `x["name"]` is `opGet` -> `get(name)`. Readers: **tok ≈ 20** (`actionBlocK`, `actionBody`, `actionHolder` ×2, `fireLabelMethod`, `parseBlocK`, `parseBody`, `parseHolder` ×2, `setActions` ×2, `compile` ×3, `frameFind`, `frameStak`, `processCode`, `parseRule`, `jitProbeDrive`, `probeSweep`); **kant 12** (the generator 4, `incant/frontier` 5, fixtures 3). **So one function decides whether every lookup still works:** if `get(name)` searches terms and then properties, no name reader changes.

### 11.3 Skippers

| class | sites |
|---|---|
| **retire** (skips artifacts on a rule/term list) | `ensureGuard` `GroupItem.twk:634`, `testAttributes` `RuleStuff.twk:269`, `setParseWalk` `Generate.rtn:419`, `dupTermRefusal` `genParse.rtn:110,112`, `compile` `Commands.rtn:65,105`, `probeSweep` `jitEmitters.rtn:2782`, `labelMinters` `measure.twk:286` -- **9 lines** |
| **retire if action lists split too** | `processAction` `GroupActions.rtn:636`, `jitBuildFunction` `jitEmitters.rtn:269` -- 2 |
| **stay** (presentation `noPrint`, printing) | `aCTionPrinT` `ruleActions.rtn:732,753`, `appendPrintXP` `:1237`, `next()`'s `ignoreNoPrint` option -- 4 |
| **unclear** | `setDebug` `GroupItem.twk:1750` (artifacts and noPrint commands alike) -- 1 |
| **kant** | 20 lines in 13 files: the generator 2, `incant/utilities` 1, fixtures/instruments 17 |

`countRuleTerms` no longer exists.

### 11.4 Positional: THE PREMISE IS REFUTED

**12 of 63 rules have an artifact BEFORE a real term** -- `builtinActoR` at index 1 (`NumbeR`: index 2, between terms), because the bootstrap calls `setActions()` before adding terms: `DefinE`, `DelimText`, `ExpressioN`, `NamE`, `NewGroup`, `NumbeR`, `QuotE`, `RunRulE`, `SetBrackets`, `StatemenT`, `TraiT`, `TraiTdata` (same at rest and after `parser(Start)`). **The split shifts those rules' real-term indices by one.** Positional readers of rule lists: `definingRule()` (`get(1)`, the first child's parent -- lands on the same owner either way), `materialiseTerms` (`rule[i]`, walks artifacts too), `aCTionCodE` (`rule[1]`/`rule[2]` on `CodeBody`, not among the 12), and the audit's `entry[i]` walks (instruments). Generated bodies call by NAME, never by index; kant has no positional rule reads. The other positional reads (`input[1]`, `field[1..3]`, `InvokE[1]`, ...) index LABEL and expression trees, not rule lists -- though label trees carry a `noPrint` artifact of their own (TraiTdata's Modifier packet), outside stroke 3.

### 11.5 Instance vs rule

**`groupList` lives in `GroupBody`, so everything on a list is shared by construction -- no artifact can sit per-reference** (a face has no list of its own). One finding: **`frameSTAK` is ACTIVATION data (an action's frame stack) stored in rule substance** -- stroke 5's territory, next to NO HUNT.

### 11.6 Subdirectory reach

Zero `GroupBody` references in `GUI/`, `GUI/Stuff/`, `Tests/` generated files; **no `GUI/` or `Tests/` `.mm` is in the Groups target's Sources** (`GUI/Groups.mm` and `GUI/Control.mm` are file references only; the compiled `Layout.mm` is top-level). A `GroupBody` layout change reaches nothing unswept.

### 11.7 Expected line-count delta -- THE PREDICTION

**On the 39-function parse metric: ≈ −1** -- of the retiring skippers only `testAttributes`' line is on the list; `get()` and the other skippers are not. **Stroke 3 will not visibly shrink the metric**, because its savings live outside the functions the metric counts. **Tree-wide:** −9 to −11 tok skipper lines and ≈ −20 kant lines, against the property list's own cost (a `GroupBody` list field, `get()` searching two lists, accessors: ≈ +10-15) -- **net ≈ −15 to −20 tree-wide.** If the stroke is to be judged by shrinkage, the metric needs a second column that covers the skippers.

---

## 12. Stroke A step 0: the `isMacro` census (2026-09-28, trunk `e680c77`, SEQ 218)

Measured, not read: a temporary build (every site logs to a scratch file; reverted, the retok came back
byte-identical to HEAD) run across the whole `pop.sh` fleet, **253 processes**. Each site logs its
first arrival per process as a positive control, then every hit.

### 12.1 Writers

| # | site | meaning | fleet |
|---|---|---|---|
| W1 | `modify()`'s `$` arm, `GroupActions.rtn:549` | a reference's `$` modifier | **253 -- once per process**: the bootstrap `modify(item,"$")`, `GroupMain.twk:205`, on QuotE's inner `tik` (grammar line `QuotE tik=['"] quoteBody}=tik$@;`) |
| W2 | the `macro` flag command, `Commands.rtn:513` | a macro definition | **0** |

### 12.2 Readers

| # | site | class | arrivals | hits |
|---|---|---|---|---|
| RR1 | `getWhatFollows`, `RuleStuff.twk:151` -- `if grup.isMacro hasMacro = true; else onGroup = grup;` | **rule** | 253 | **253 -- one per process** (quoteBody, whose group datum is the `$`-marked `tik`) |
| RR2 | `setTestMatch`, `RuleStuff.twk:176` -- `or isMacro testMatch = setMacroValue;` | **rule** | 253 | **0** |
| RR3 | `parse()`, `GroupItem.twk:1366` -- `if hasMacro setMacroValue(this);` (the `isMacro` meaning carried in `RuleStuff.hasMacro`, whose only writer is RR1) | **rule** | 253 | **37,200** |
| -- | `setMacroValue`, `RuleStuff.twk:204` -- copies the nearest ancestor label's same-tag data into the macro | rule (the consumer of RR2/RR3) | -- | -- |
| NR1 | `aCTionDefinE`, `ruleActions.rtn:312` -- attributes of a macro definition are `noPrint` | non-rule | -- | **0** |
| NR2 | `aCTionDefinE`, `ruleActions.rtn:343` -- a macro's `CodE` kept as text | non-rule | -- | **0** |
| NR3 | `aCTionDefinE`, `ruleActions.rtn:350` -- "a macro definition must have code" | non-rule | not instrumented | needs a define-time `isMacro`, and W2 fired 0 |
| K | `incant/setup:301` `isMacrO` | kant accessor | **unnumbered** (no `opDot` case), no kant reader | -- |

**Rule side 3 live readers (RR1 253, RR3 37,200), non-rule 3 (0 hits).**

### 12.3 The 07-28 count, re-taken

The 07-28 census classified terms by `setTestMatch` arm and read **0** in the `isMacro` row. Re-taken
today: **RR2 still reads 0.** But that census could not see the live specimen: the `$` sits on
quoteBody's **group datum** (`tik`), not on a term, so it is read by RR1, not RR2.

### 12.4 What `$` does in the grammar: a back-reference

`quoteBody}=tik$` means *up to and over a `tik` that matches the SAME character the opening `tik`
matched*. RR1 raises `hasMacro` on quoteBody; RR3 calls `setMacroValue` on every iteration, which copies
the opening quote's label data into the closing `tik`, so `"it's"` ends at `"` and not at `'`. **So the
rule-side `isMacro` is a match modifier, live on every string literal in every run.**

### 12.5 The strip, measured and reverted

RR1 (to `onGroup = grup;` unconditionally), RR2 and RR3 removed, rebuilt bare: **`pop.sh` 815 -> 36
green**; `oneTest`, `jsonTest`, `baselineTests` and nearly every fixture **exit 139**. Reverted and
rebuilt: 815 / 1, row for row (one heap address in `acceptStartT` differs); canary 313 + 21 + 42.

---

## 13. Stroke 3 pre-build checks (2026-09-28, trunk `8a4eeab`, SEQ 219)

Instrument: `incant/pop/actorOrderT`'s walk (every Grokking entry, its children in list order), run at
rest and again after `parser(Start)`; classified in shell by tag, because a captured `noPrinT` in kant
compares as a holder (bear-trap 55) and printing it echoes a tag (41).

### 13.1 `tempField` is a LOCAL, and it never sits on a rule list

Two writers, both `isLocal` + `noPrint`: `compile` (`Commands.rtn:75-80`) puts `this` and `tempField` on
the generated **`CodE`** (inside the carrier), and `aCTionDefinE` (`ruleActions.rtn:334-341`) puts them
on the **action**. Both are frame slots the body's names resolve against. The global `ruler.tempField`
(arithmetic scratch; `processAction` saves and restores it) is a third thing with the same name. **No
Grokking rule list carries `tempField` or `this`** at rest or after `parser(Start)`. Under "rule lists
plus artifacts only; locals stay", `tempField` stays where it is.

### 13.2 What is on rule lists

| | at rest | after `parser(Start)` |
|---|---|---|
| children on the 85 Grokking entries | 280 | 336 |
| `builtinActoR` | 33 | 33 |
| `builtinParseR` | 0 | **56** (the only change) |
| `BlocK` | 1 -- a **real term** (see 13.3) | 1 |
| `CodE`, `pendingParseR`, `frameSTAK`, `tempField`, `this` | 0 | 0 |

`CodE`, `BlocK` and the locals sit one level down, inside the carriers. `frameSTAK` appears only
after an action compile (recon 9.3: 19 rules, via `driveCompileT`), which this walk does not drive.

### 13.3 Collision census: ONE, and it is `BlocK`

`BlocK` is a grammar rule (`incant/grammar:116`) and a real term of `StatemenT` (`:178`), and it is
also the artifact name `attachBlocK` writes. `CodE` has no grammar twin. **The live hazard:**
`actionHolder()` returns the rule itself when its actor carries no `CodE` -- true for every rule whose
action is a C function, `StatemenT` included -- so `actionBlocK()` on `StatemenT` is
`getAttribute("BlocK")` on a list that holds the grammar term. After the split, a term-first `get()`
would still answer the term. **So artifact accessors (`actionBlocK`, `parseBlocK`, `actionBody`,
`parseBody`, the two holders, `attachBlocK`) must read the property list only**, not the shared `get()`.

### 13.4 The 317 oracle is not yet independent

317 (and 792) came from recon 9's lldb walker, which descends into inline sub-terms and stops at
shared bodies. This walk's top-level population is 280 at rest, of which 33 actors, so **247 top-level
terms**. A count "from the grammar text" needs a text parse of `incant/grammar` plus the `GroupMain`
bootstrap (whose rules have inert mirror lines in the text). It is not built.

---

## 14. Stroke 2b census: readers of the matched quote character (2026-09-28, trunk `e5eabb2`, SEQ 222)

| reader | what it reads | answerable by which member matched? |
|---|---|---|
| `aCTionQuotE` (`ruleActions.rtn:807-826`) | `tik.gText != '"'`: double quotes give a text literal; single quotes look the body up in `opFields` (the `'++'` path: an operator name that is not a NamE), else a char or text literal | **yes** -- "single member" / "double member" |
| `parse()` -> `setMacroValue` (old road, recon 12) | copies the opening quote into the closing `tik` | **yes** -- each member's close is fixed, so the back-reference goes away |
| `aCTionDefinE`'s operator-naming site | `isLiteral`, which `aCTionQuotE` sets | **yes**, unchanged |
| new-road generated body | `tik` classified `parseSet` (`parseClass.target:176`); no `macroVal` | **yes** -- fixed closes need no back-reference |
| instruments | `termCountT` TC-4 (QuotE = 2 terms), `leafClassT` LC-5 (F-O25), `parseClass.target` | shape pins; they move by name |

**Every reader is answerable. The respell was NOT started**, because the census missed one thing that is a design choice, not
a mechanical edit: **the label level.** Measured (a temporary print in `aCTionQuotE`, reverted): today the `QuotE` label holds
`tik` and `quoteBody` DIRECTLY, and its text is the body. A two-member QuotE puts a member label between them, so
`aCTionQuotE`'s `tik:` binding finds nothing (and then dereferences it), and `GrouP -> QuotE -> member` is one level deeper than
`aCTionDefinE`'s single `isGROUP` unwrap. **Which node carries the result -- the member's own action writing through to the
QuotE label, or `aCTionQuotE` reading the member -- is the ruling owed before the respell.**

**Baseline for the certificate, old road (all correct):** `"it's" tail` 1/6 (ends at the `"`), `'it"s' tail` 1/6, `'abc'` 1/5,
`"abc"` 1/5, `'++'` 1/4. **New road after `parser(DO)`:** `'abc'` 0/0 and `'++'` 0/0 (F-O25), and **every input containing
`"` crashes, exit 139** -- F-O37.

---

## 15. Property operators: spelling census (2026-09-29, trunk `42007b9`, SEQ 223 item 3, read-only)

Direction ruled (a pair calling addProperty / getProperty; `+%` / `=%` stay attributes-only); spelling NOT
ruled. Candidates `+(` `=(` and `+<` `=<`. Population for (a): `incant/` (grammar and setup included,
`attic/` excluded), `IncantForms/`, `Tests/`, unspaced `grep -F`.

| | `+(` | `=(` | `+<` | `=<` |
|---|---|---|---|---|
| **(a) sites written today** | 0 | **610 -- every one is `name=(`, the `(…#)` define-literal opener** (define lines, plus a few in dead-region prose such as `first=(none)`); none in action/expression text | 0 | 2, both prose: `incant/pop/fireSeatT:57` (`pRule=<rule>`, dead region), `IncantForms/Notions/issues:25` (Tony's note proposing `=<`) |
| **(b) in Operators today** (kant `*Operators["x"].taG`; controls `=%`, `+%` read back) | no | no | no | no |
| **(c) with the pair registered** in `incant/setup` (temporary, bound to opAddAttribute / opGetAttribute; restored, md5 checked) | reads back `+(` | reads back `=(` | reads back `+<` | reads back `=<` |

**(c) rows, identical registered and not, for BOTH pairs:** a `(…#)` define value (`hello there, world`); a
`(…#)` value whose body contains `a=(b`, `c+<d`, `e=<f` and `g+(h`; a rule with a `<` noAdvance modifier,
`ltT isRule one<-="a" two-="a"`, `tell("ltT a")` 1/1, with its control `ltN` (no `<`) 0/0. **And the whole
fleet, row for row (834 / 1, addresses masked), under each pair** -- the 610 `=(` sites and the grammar's live
`<` modifier (`followedBy<^-=notInNameSet`, `incant/grammar:88`) included.

**Notes a reader needs, not a pick:** `+` is in the ShortcuT set (`[-+~`$_:,]+`, used only in `PrintXP`), so in
print position ShortcuT takes the `+` of `+(` or `+<` -- exactly as it does for `+%` today. `=(` is the
define-literal opener by spelling; registering it moved nothing, but it is the pair that shares characters with
610 live sites. `<` is also a Modifier (`noAdvance`), so `+<` reads as two modifiers (`+` repeat, `<` noAdvance)
in a grammar term's modifier string; no term writes that pair today.

**(d) `field["<property>"]` through opGet:** yes -- `opGet` calls `target.get(String)` (read), which searches terms
then properties (stroke 3); measured by `incant/pop/propGetT` (fleet), PG-1 `QuotE["builtinActoR"]` reads the
actor. **Property names** (every `addProperty` writer): `builtinActoR`, `CodE`, `BlocK`, `frameSTAK`,
`pendingParseR`, `builtinParseR`. **Collision with a term name: one -- `StatemenT` has a grammar term `BlocK`**
(termCountT's walk of every Grokking rule's direct terms, at rest and after `parser(Start)`; nested terms are
outside that population), so `StatemenT["BlocK"]` answers the term. No other property name is a term of any
Grokking rule.

**The F-O38 site** the build converts: `IncantForms/WorkingOn/parser:44`, `argument +% *bprCopy;` (the
pendingParseR carrier). Line 43, `*bprCopy +% *codeCopy;`, is the carrier's CodE; compile re-files both today
(`Commands.rtn:56-68`).

---

## 16. Stroke 4 recon: the instance -> rule link (2026-09-29, trunk `6bed9a1`, SEQ 226, read-only)

Nothing built. The measurements used a **temporary build, reverted** (retok bare, byte-identical to the clean copies): the
copy constructor recorded, for every copy, its source chased to the root (a prototype of the link, `L`) and the
function that called it (`dladdr` of the caller); a census walked every node reachable from `Grokking` through the term
lists (379 nodes, each visited once), at rest and again after `parser(Start)` -- **identical both times.**

### 16.0 Where the doc and the dispatch disagree, or the doc is stale

| item | doc / dispatch says | measured today |
|---|---|---|
| stroke 4 certificate | "the **13** `definingRule()` callers switch one at a time" (Part 2) | **5 engine call sites** + 2 instruments (16a). The 13 is an older count. |
| `options.isCopy` row | "no engine reader (6 readers, all in `measure.twk`)" (1.3) | **4 engine readers** today (16a) -- F-O27 added the first; stroke 2 added two more. |
| RuleStuff rule-level row | lists `hasMacro` | deleted by SEQ 225 (row corrected in this commit) |
| stroke 2b status | "`incant/grammar:44` still reads the `$` QuotE line" | deleted by SEQ 225 (note corrected in this commit) |
| dispatch item 2 | parser "lines 30 and **59**" | the second skip is **line 56**. The 59 is my own miscount in the SEQ 224 report. |

### 16a. READERS -- "which rule is this field an instance of?"

| family | sites | what it answers |
|---|---|---|
| **`definingRule()`** (`GroupItem.twk:481`: `get(1).parent`, else `this`) -- this IS the positional read; **no other `get(1)`-style site exists** | engine **5**: `parse()` (`GroupItem.twk:1398`), `installParseMethod` (`Generate.rtn:49`), `runLeafParse` (`Generate.rtn:360`), `jitFieldMethod` (`jitEmitters.rtn:2027`), `jitShowRecord` (`:3437`). instruments **2**: `canonOf` (`measure.twk:222`), `definersOf` (`GroupActions.rtn:138-143`) | the node that minted the first term |
| **`options.isCopy`** | engine **4**: `setRuleStuff` (`GroupItem.twk:1948`, copy -> `ruleTerm`), `setParseWalk` (`Generate.rtn:401`, F-O27), `aCTionDefinE` member propagation (`ruleActions.rtn:317`), TraiTdata (`ruleActions.rtn:1151`). instruments 3 prints in `measure.twk` (`addrOf`, `PEQWRITE`, `PPWRITE`); kant `isCopY` is unreadable (pointerT L5c pins that) | "am I a reference or a definition" -- no answer to *which* rule |
| **by name** | `enclosingFace` (`Generate.rtn:15`, via 3 callers) looks the tag up in the enclosing activation's rule; `definersOf` / `grammarHolds` / probes look tags up in `Grokking` | the face in the enclosing rule (a parse-time question, NO HUNT's -- stroke 5, not stroke 4) |
| parent walks | none found that answer "which rule"; `setRuleStuff`'s `parent.isRuleTerm()` asks the *parent's* instance fact | -- |

**Disagreements on the live grammar (379 nodes: 218 copies, 161 originals):**

| comparison | agree | disagree |
|---|---|---|
| `isCopy` vs the link exists | 379 | **0** -- one writer, the copy constructor |
| body shared with the link's target | 218 | **0** |
| `definingRule()` vs the link, copies | 104 | **114 -- every one a LEAF copy, where `definingRule()` answers the copy ITSELF** (`get(1)` is null): `rightBrace` in SetBrackets, `nameSet` in NamE, `EquaL` in TraiTdata, ... All 114 minted by `addGroup` |
| `definingRule()` vs itself, originals | 160 | **1: `Operators/?` answers `Modifiers/?`** -- the original's first child is parented to its COPY (the Modifiers define added terms through the shared body) |
| the link vs the `Grokking` entry of the same name | 152 | **8**: `break`/`continue`/`return` (in Grokking and in BrancheS) are copies of the **Keywords** entries; `Operators` (in Grokking and as a Token term) is a copy of the registry `Operators`. **58** copies have no Grokking entry of their name |

### 16b. WRITERS -- where a copy is minted

Every copy goes through **one constructor**, `GroupItem(GroupItem)` (`GroupItem.twk:42`). Its callers (whole setup, process-wide,
at rest): `addGroup` **1,130** · `aCTionTraiT` 45 · `addProperty` 43 · `aCTionTraiTdata` 16 · `embedRule` 11 ·
`embedAttribute` 8 · `copyListFrom` 6 · `cOPY` (the kant `copy` command). **`aCTionDefinE` and the bootstrap mint through
`addGroup`** (`currentRegistry += NewGroup`, `strap += grok/X`, `+%`); neither calls the constructor directly. **All 218
grammar copies were minted by `addGroup`.**

**So the link has ONE writer: the copy constructor**, written as the prototype did -- `ruleOf = grup.ruleOf ? grup.ruleOf :
grup` (a copy of a copy points at the root, never at the intermediate). Open question for the ruling: `addProperty`'s 43
copies get a link too (a copied property); harmless, but they are not rule instances.

**Cross-registry copies, every registry (442 entries): 17**, all via `addGroup` -- the define resolved a name to an entry in
ANOTHER registry and copied it: `Modifiers/! % & * + - < ? @ ^` <- `Operators` (10); `Grokking/break continue return` <-
`Keywords` (3); `Keywords/define` <- `Grokking`; `Keywords/new` <- `cOMMANDs`; `UnitTests/counter` <- `Grokking`;
**`Utilities/parser` <- `fILEs` (F-O33).**

### 16c. LAYOUT

- **Field:** `GroupItem ruleOf;` on `GroupItem` -- name proposed, **Tony's to rule**. Zero collisions for `ruleOf` across
  `*.twk *.rtn *.h groups.ext`. **Not `rule`**: `RuleStuff.rule` exists and is read bare in every `RuleStuff` method; a
  `GroupItem` member of that name would re-aim bare reads (bear-traps #42/#57).
- **Declaration order:** GroupItem already declares three `GroupItem` fields (`parent`, `nextInParent`, `priorInParent`).
  Per bear-trap #57 (a second field of one type, declared after, captured bare names), declare `ruleOf` **before `parent`**
  and run #57's detector (full-tree `.mm`/`.h` compare) -- expected change: `GroupItem.h` (one ivar) and `GroupItem.mm` (the
  three constructors' zero-inits and the copy constructor's write).
- **`groups.ext`:** the `external GroupItem` block (`groups.ext:229-240`) gains the line; when `isCopy` goes, its
  `options` line loses it.
- **tokall scope:** full bare `tokall` (top-level `*.twk`). **Subdirectories:** `GUI/*.mm` reference `GroupItem` (Bwana 136,
  Control 80, ...), but **none of them is in the `Groups` target** (its Sources are top-level `.mm` plus
  `Frame/OCroutines`, `Bot`, `URLservice`), so `~/bin/incant` cannot pick up a stale one.

### 16d. F-O33

The link makes it **answerable, not moot.** `Utilities/parser` is an `addGroup` copy of `fILEs/parser`
(`isCopy` 1, same body); the prototype link and `definingRule()` both name the fILEs node. What the link adds is that the
fact becomes one read -- `ruleOf.parent` is a different registry -- so the 17 cross-registry copies are a census, not a
discovery. **The cause is upstream of the link:** `aCTionDefinE` resolving a new action's name to an existing entry in
another registry and copying it. Whether a define may ever do that is a ruling the link cannot make.

### 16e. Proposed stroke order (each step on its own branch, fleet row for row)

| step | what lands | certificate row |
|---|---|---|
| **4.1** write the link | `ruleOf` declared (before `parent`), written by the copy constructor only; nothing reads it | a census row (a `measure*` callout, not a directives build): copies 218, `ruleOf` set exactly where `isCopy` is (mismatch 0), same body 218/218, cross-registry 17 -- **pinned by value**. H7: writer removed -> set on 0, red |
| **4.2** isCopy readers -> the link | the 4 engine readers ask `ruleOf != null`; measure prints follow; then `options.isCopy` deleted (layout; groups.ext) | fleet row for row; `omModT`, `leafClassT`, `ruleTermT` unmoved; **zero-reader census** for `isCopy` |
| **4.3** definingRule callers -> the link, one family at a time | (a) `runLeafParse` + `installParseMethod` -- **the family that can MOVE**: on 114 leaf copies the answer changes from the copy to the rule, so a leaf would read the rule's `parseMethod` instead of its own snapshot; (b) `parse()`'s `definer`; (c) jit: `jitFieldMethod`, `jitShowRecord`; (d) instruments `canonOf`, `definersOf` | (a) `leafClassT`, `parseClass.target`, sweepT, fleet -- **any mover named with its sentence**; (b) fleet; (c) jitLadder; (d) their own rows. Then `definingRule()` deleted, or kept as `ruleOf ? ruleOf : this` |
| **4.4** `RuleStuff.rule` | retire, or keep as a cache (Part 1: decided in the stroke); rule-level `RuleStuff` fields (`parseMethod`, `actionMethod`, `testMatch`, `jitMethod`, `ruleName`, `sourceLine`) read through the link | its own census |

`Operators/?` (16a) is the case to watch in 4.3(b): `definingRule()` answers its copy today, and the link answers itself.

### 16f. The parser file's own noPrinT skips (item 2) -- `IncantForms/WorkingOn/parser` lines **30** and **56**

Measured in a **clone** (`genLadder/cloneBuild.sh` at `6bed9a1`, outside Dropbox) whose copy of `parser` carried a print
beside each skip -- Tony's file untouched. Whole checklist through a per-process stderr log (366 processes); the fleet
read 847 / 1 through the wrapper, as on trunk.

| line | where | hits | what it skips | from |
|---|---|---|---|---|
| **30** | `generateParse`'s term walk | **8** | `this` 4, `tempField` 4 | `parser()` on a CODED rule: chainTruthT (`wzNum`), parserTest and carrierT (`list`), frontier station 1 (`frRule`) -- the compiled action's two hidden locals |
| **56** | `walkRules`' term walk | **8** | the same 8 | the same four processes |

**No carrier is skipped at either line any more.** H16 control (the clone's parser reverted to `+%` at 43-44): line 56
**4,310** `pendingParseR`, line 30 **5** -- so the probe sees a carrier when one is there, and today's zero is real.

**For Tony's ruling, each line's removal measured in the clone:**
- **line 56 removed:** pop.sh 847 / 1 **row for row** (bar a clone-only fixture-name count), frontier identical. The locals
  it skips read `isRulE= 0`, so **line 57 (`if isRulE == 0; continue;`) already catches them** -- line 56 is redundant.
- **line 30 removed:** pop.sh **845** -- `chainTruthT` CT7 and `carrierT` CT-2 go red (the generator emits calls to the
  locals). **Line 30 is load-bearing** as a local skipper.

---

## 17. Stroke 4.1's census: the 17 cross-registry copies classified (2026-09-29, SEQ 227 R2 -- reported, NOT ruled)

`ruleOfCensus` (`GroupActions.rtn`, fleet fixture `incant/pop/ruleOfT`) lists each registry entry whose `ruleOf` is an entry
of a DIFFERENT registry, with how many of the shared body's terms and properties are parented to the COPY -- i.e. were
written by the copy's own definition into a body it shares with the original. Identical at rest, after a `tell()` and
after `parser(Start)`.

| copy <- original | written through the copy | classification |
|---|---|---|
| `Grokking/break`, `continue`, `return` <- `Keywords/…` | nothing | **intended instance** -- the grammar's `BrancheS bin` names the keyword masters (stroke 2's "nine keyword masters") |
| `Keywords/define` <- `Grokking/define` | nothing | **intended instance** -- the Keywords registry lists each keyword by reference to the rule that implements it |
| `Keywords/new` <- `cOMMANDs/new` | nothing | **intended instance** -- the same, to a command |
| `Modifiers/! % & - < @ ^` <- `Operators/…` (7) | nothing | **accidental name capture, by shape** -- `registry(Modifiers)` defines modifier characters (`incant/setup:227-240`); each name resolved to the same-named OPERATOR and copied it |
| `Modifiers/* + ?` <- `Operators/…` (3) | **1 term each** | **accidental, and CONTAMINATING** -- these are exactly the three setup writes as `'+' repeatClass;`, `'*' repeatClass;`, `'?' repeatClass;` (the term is the modifier's, now inside the operator's body). `Operators/?` therefore answers `definingRule()` = `Modifiers/?` (recon 16a) |
| `UnitTests/counter` <- `Grokking/counter` | nothing listed, **but the DATA is shared** | **accidental and CONTAMINATING** -- `incant/unitTests:87` `counter=0;` is a test variable that captured the grammar's digit set `counter=[0-9]` (`incant/grammar:29`, used by `Precision`). Measured: `Grokking["counter"]` reads the value **0** with `include(unitTests)` and the set without. **F-O40.** |
| `Utilities/parser` <- `fILEs/parser` | **2 terms, 1 property** | **accidental and CONTAMINATING -- F-O33**: the action's own definition wrote into the include-file entry's body |

**Totals: 5 intended, 12 accidental; 5 of the 12 contaminate the original** (3 Modifiers, `counter`, `parser`). Nothing was
changed; the mechanism for all 12 is the define resolving a new name to an existing entry of another registry (`addGroup`'s
copy-if-parented). Whether a define may ever do that is the open ruling.

---

## 18. R2's design input: where a define's name resolves across registries (2026-09-29, trunk `c4d5801`, SEQ 228, read-only)

Measured with a **temporary build, reverted** (retok bare byte-identical): `aCTionDefinE` logged every definition whose
name arrived resolved to a node parented OUTSIDE the current registry, and whether it was copied, across the whole
checklist (pop.sh, jitLadder, decodePop, ddPop, countPop, printPop, frontier): 10,233 events, **47 distinct**.

### 18b. The resolution site -- one lookup, two copy points

- **Resolution:** a define's name is a `NamE`, and `aCTionNamE` -> `resolveName` (`ruleActions.rtn:1774`) calls
  `GroupControl::locate(name)` (`GroupControl.twk:95`), which tries the registry names, then `currentRegistry`, then
  **every registry on the search list, then the base registries**. A name not yet in the current registry is found
  wherever else it exists. **This is the one site R2 changes** -- but it is shared: the same `resolveName` resolves every
  term reference inside a definition (where crossing registries is the point, e.g. `ExpressioN` in a rule body).
- **Copy point 1, the registry arms of `aCTionDefinE`** (`ruleActions.rtn:279` rule registries, `:287` the others):
  `if NewGroup.parent != currentRegistry  NewGroup = currentRegistry += NewGroup` -- `addGroup` copies a parented node.
- **Copy point 2, the member road** (`ruleActions.rtn:359`): `NewGroup += item` for each of `MemberS`, same copy.

So R2 can be written at the resolution (a define's own name looks in `currentRegistry` only, members in the entry being
defined) or at the two copy points (a name found in another registry mints fresh instead of copying). **Either way the
term references inside a definition must keep the search-list walk.**

### 18a. The 5 intended copies (and one more) reach their original through the same fall-through

| copy | spelled today | road |
|---|---|---|
| `Grokking/break`, `continue`, `return` | `incant/grammar:117-120`, `BrancheS bin` members `break;` `continue;` `return;` | member DefinE; the name resolves to `Keywords/…` via the search list; the RULE-registry arm copies it into Grokking (that arm ignores `addingMembers`), then the member road copies again into BrancheS |
| `Keywords/define`, `Keywords/new` | `incant/setup:256, 261`, plain `define;` / `new;` in `registry(Keywords)` | resolves to `Grokking/define` / `cOMMANDs/new`; copy point 1 |
| `Grokking/Operators` (not in recon 17's 17: its original is the `registries` node) | `incant/grammar:141`, the `Token` bin member `Operators;` | resolves the REGISTRY `Operators`; copy point 1. **The grammar needs this one** -- `Token` matches operators through it |

**All six use exactly the fall-through R2 closes**, so each needs R2's explicit spelling or it becomes a fresh, empty entry.

### 18c. Everything that would move -- 47 distinct definitions resolve outside their registry

**19 copied at copy point 1:** recon 17's 17; `Grokking/Operators` (above); and **`CursorRead/taG` <- `GroupFields/taG`**
(fixture `incant/pop/cursorReadTb:26`, `taG="ENCLOSING";` -- the fixture's own field named `taG` is a copy of the
accessor's registry entry, and its value lands in that entry's body; same shape as F-O40, fixture-only).

**28 resolve outside but take the MEMBER road (copy point 2), not copy point 1:**
- `pROPERTIEs` members `- -- ! * @ . ++ $$` <- `Operators` (8), `Utilities` members `NumbeR`, `GrouP` <- `Grokking` (2), in
  setup;
- `DesignDocs` / `Decoder` entries named after commands -- `stop`, `compile`, `canonOf` (x2), `TOKENize`, `addrOf`, `arrondir`,
  `bodyCensus`, `chanReport`, `evictAction`, `interpretBC`, `jitEmitter`, `parseAction`, `parseClassify`, `probeNode`,
  `runByteFn`, `showBody` <- `cOMMANDs`, and `lastREF` <- `pROPERTIEs` (18).

**The DesignDocs members are LIVE CONTAMINATION -- F-O41.** Measured: with `include(designDocs)`, `cOMMANDs["stop"]` reads
*"Immediate method for the stop command."* and `cOMMANDs["compile"]` *"compiles a rule parse generated in the parser
incantation."*; without it each reads its own tag (no data). The command still dispatches (its method is in another slot).

### 18d. `repeatClass` on `Operators/* + ?` -- inert, by census

`repeatClass` has **one reader**, `modifierIsRepeat` (`GroupActions.rtn:564`), and it reaches the entry through the
**Modifiers** registry -- the copy. No source site or fixture walks an `Operators` entry's terms generically, and the
operator-side readers (`unaryIsAccess`'s `accessClass`, `shortCircuit`, `isOR`) ask by other names. **Inert as far as a
source census can tell; not run-measured.** The reverse sharing is inert the same way: the Modifiers copies carry the
operators' method bindings and flags, and `modifierIsRepeat` reads nothing but `repeatClass`.

---

## 19. R2 try-and-buy: a definition's own name resolves in the current registry (2026-09-29, SEQ 229, branch `om-r2-ownname`, NOT merged)

**Built** (`974c304`, then `0332caa`): one test at the top of `aCTionDefinE`, ahead of both registry arms and the member road --
a `NewGroup` found in ANOTHER registry mints a fresh node of its name. `0332caa` adds two things: a **repair** and a
**measurement knob**.
- **The repair is part of any build of R2.** `aCTionNewGroup` sets `currentDefine` to the resolved node before `aCTionDefinE`
  runs, and the end-of-define clear compares BODIES, so a fresh node left `currentDefine` stuck and every later definition in
  that (non-rule) registry was read as "adding members" -- every action after it did nothing. The fresh mint must take over
  `currentDefine`. **Every run before the repair (variants A, C, D) is void** and is not reported.
- **The knob** `OMFRESHONLY="|Registry/name|..."` limits the mint to the named cases, so each case was measured alone on one
  binary; unset = R1 exactly as ruled.

### 19a. Fleet (pop.sh against trunk's 855 / 1)

| run | fresh cases | pop.sh | notes |
|---|---|---|---|
| **A' -- R1 exactly as ruled** | all 47 | **391 / 1** | jitLadder: `jitDfProbe`, `jitJD` hung (watchdog-killed) |
| **E3 -- all but the 7 that need content (19b/c)** | 40 | **844 / 1** | 11 rows moved, each named below; decodePop, ddPop, countPop, printPop, frontier **identical**; jitLadder FAILED |

**E3's 11 movers:** `chainTruthT` x5 (exit 2 -- `Utilities/parser`, F-O33 moved, 19d); `retProbe` bare return (`Grokking/return`);
`testPrecedence` (`-`, `--`); `andProbe` AP-5b (`!`); `cursorReadTb` B (19f, expected); `ruleOfT` RO-4 (expected -- the 17
cross-registry copies are now fresh; only `Keywords/new` remains); the audit's "missing rules" 6 -> 3 (the fresh
`break`/`continue`/`return` in Grokking now carry rStuff). **jitLadder under E3:** `-` alone fails JM4; `--` alone fails JU and
hangs JD; `!` alone passes; JR, JRt2, JA (139), JM1 fail only with the five UnaryOPS members fresh together.

⚠ **Instrument note (H16):** `chainTruthT`'s output differs between three identical runs, so it was bisected by EXIT STATUS,
which is stable; `retProbe`, `andProbe`, `testPrecedence` were checked deterministic before use. The jit ladder has no
per-fixture wall-clock cap (pop.sh's H5 `POPCAP` does not reach it) -- `jitJD` under `--` ran 27 minutes until killed.

### 19b. The 6 intended instances -- fresh works, or what breaks

| case | fresh | verdict |
|---|---|---|
| `Grokking/break`, `continue` (BrancheS) | loops with `break`/`continue` correct; jitLadder passes | **name only** |
| `Grokking/return` | a bare `return;` no longer yields the prior statement's value (retProbe 44 -> ''); valued returns and jitLadder fine | **content needed** (that semantic) |
| `Keywords/define` | every probe and the fleet unmoved | **name only** |
| `Keywords/new` | `new("x")` stops minting | **content needed** -- the command behind it |
| Token's `Operators;` | every binary operator dies (`3 + 4` -> 0) | **content needed** -- the registry itself |

### 19c. Setup's 10 member-road cases -- all 10 are intended

`pROPERTIEs`' `UnaryOPS bin` members ARE the unary operators (`TokenXP UnaryOPS? …`); `Utilities`' `JSONtoken` members are the
JSON grammar's references to Grokking's `GrouP` and `NumbeR`.

| member | fresh | verdict |
|---|---|---|
| `*`, `$$` | unaryClassT, the canaries and the ladder unmoved | name only |
| `.` | unaryClassT moves; `*x.taG` fails | content |
| `++` | argRoundT, jsonTest, probeDoorT all move -- it is `iterate`'s advance | content |
| `@` | probeDoorT moves | content |
| `-` | testPrecedence; jitLadder JM4 | content |
| `--` | testPrecedence; jitLadder JU, JD hangs | content |
| `!` | andProbe AP-5b | content |
| `JSONtoken/GrouP`, `NumbeR` | jsonTest moves | content |

### 19d. F-O40 and F-O41 -- NOT fixed on the branch; F-O33 MOVES

**The contamination happens before `aCTionDefinE`.** A definition's value is written by `aCTionTraiT`
(`trait.setContent(TraiTdata)`, `trait = input[1]` -- the RESOLVED node) during the parse, so the original is already written
when R1's test runs. Measured on the branch: `Grokking["counter"]` still reads `0`; `cOMMANDs["stop"]` still carries the
DesignDocs prose. **And the fresh definitions LOSE their values**: `UnitTests["counter"]` reads no data (it read `0` on trunk).
So R1 at `aCTionDefinE` cannot fix a value-carrying capture; the resolution has to be decided before TraiT writes.

**F-O33 moves rather than resolves:** the Utilities action `parser` was sharing the fILEs entry's body, so its value WAS the
include path; fresh, it shadows the file entry and `include(parser)` fails (`getFile: could not open file: parser`), which is
chainTruthT's exit 2.

### 19e. Same-registry alternation still references its rules

Under E3 `definersOf` reads, exactly as on trunk: `Braced`, `Parens`, `InvokeArg`, `BrancheS` each **occurrences=2 registry=2
others=0**; the loop / return / operator / `new` probes read 4/3, 9, 7, minted.

### 19f. cursorReadTb's `taG="ENCLOSING"` arm

On trunk the define-block `taG` is a **copy of the GroupFields accessor entry** (its value lands in the accessor's body): the
walk reads `bare= 0 explicit= 1` twice, walked 2. Fresh, it is a real CursorRead field named `taG` -- what the arm says it tests
-- and **the walk reads 0 members** (want 2): a same-registry field named `taG` shadows the accessor for that registry's
actions, so the iterate body cannot read its cursor's tag. The arm stops measuring "both spellings shadowed" and starts
measuring "a local `taG` kills the walk".

### 19g. What this means for R2's shape (input, not a ruling)

**Eleven cases need the original's CONTENT** (`Operators;`, `Keywords/new`, `Grokking/return`'s bare-value semantic, the
UnaryOPS `.` `++` `@` `-` `--` `!`, JSONtoken's `GrouP` and `NumbeR`); **five need only the name** (`break`, `continue`,
`Keywords/define`, UnaryOPS `*` and `$$`); and the value-carrying captures (F-O40,
F-O41) are written before `aCTionDefinE` can intervene. **Every content case is a bare reference** (`x;` with no value,
attributes or code); every contaminating case brings content. A spelling that treats a bare member as a reference and a
definition with content as its own entry would keep all the intended cases -- but the contamination fix still has to move
earlier than `aCTionDefinE`, to the point where the definition's own name is resolved (`aCTionNamE` under `NewGroup`, or
`aCTionTraiT`'s write).

---

## 20. SEQ 230 item 1: every write to a definition's own field before `aCTionDefinE` (2026-09-29, read-only) -- STOP

Read in the generated `.mm` (tok resolves bare names by last mention, so only the `.mm` says which node a write lands on).
Between name resolution (`aCTionNamE` -> `resolveName`) and `aCTionDefinE`, the grammar runs `TraiTdata`, `TraiT`,
`NewGroup` and, for a definition with members, `MemberS ':'- MEMBERs- Mlist=DefinE+`.

| site | writes to the DEFINITION's own field? |
|---|---|
| `aCTionNamE` (`ruleActions.rtn:650`) | no -- `input.setGroup(resolved)`, the label only |
| `aCTionTraiTdata` | **no -- it writes the VALUE (`DatA`)**: affiliation, `setRuleStuff`, `modifyClass`, `isRule` / `ruleTerm`. Same capture class (a value that resolves to another registry's field is written there), but not the definition's own field |
| **`aCTionTraiT`** | **yes, all on `trait = input[1]` (the resolved node):** `affiliation = isAttribute`; `setRuleStuff()` (or a copy when it already has rStuff); `setContent(TraiTdata)`; `modify(trait, Modifier)`; `modifyClass(trait, …)` twice. **Also runs for every ATTRIBUTE trait**, which resolves and is written the same way |
| `aCTionNewGroup` | no field write -- sets `ruler.currentDefine` to the resolved node |
| **the `MEMBERs` flag command** (`Commands.rtn:516-517`, run at parse time by `MemberS`) | **YES: `currentDefine.addingMembers = true`** -- `currentDefine` is the resolved node, so a definition with members whose name resolved to another registry's entry sets the flag on the ORIGINAL's body. `aCTionDefinE` clears it at the end (`ruleActions.rtn:377`) on `NewGroup` -- which under copy-on-first-write would be the fresh mint, so the original's flag would stay set |

**`aCTionTraiT` is not the only writer, so R1's site list is incomplete (SEQ 230's stop condition). The build (item 2) was
not started.** The second writer is the `MEMBERs` command. Two notes for the ruling: attribute traits go through the same
`aCTionTraiT` writes (a first-write mint there would mint an attribute's own node as well as the definition's), and
`aCTionTraiTdata`'s writes to a resolved VALUE are the same capture on a different field.
