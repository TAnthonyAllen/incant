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
