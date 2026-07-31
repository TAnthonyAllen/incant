# genParse — Design Spec

```
KIND:       spec
STATUS:     live
DATE:       2026-07-25
REVISED:    2026-07-25 — §7.2 resolved (group-ref failure fix specified);
                         Step 0 split into commits 0a/0b; §7.1 name-resolution
                         caveat closed from codegen (Clod); 0a landed 7b84748;
                         §3 REWRITTEN — tok macro library abandoned, everything
                         is now ordinary functions (§7.6); §1.2, §2.1, §2.4,
                         §2.5, §4.1, §5.1, §6.1 follow it
ANSWERS:    How does genParse emit a rule-specific parse method, and what
            exactly does it emit for the seven JSONblock rules?
READ-WITH:  rstuff-chokepoint.md   RuleStuff lifecycle + getStuff codegen.
                                   Bears on §7.1 and §7.4. Its own open Q1
                                   (2nd-invocation spin) may share §7.1's root.
            json.md                Input diversion, push/pop, the isRule
                                   semantic. Bears on §5.3 and §7.3.
            docs/jitDesign.md O6   aCTionFOR is a tree walk, not a counting
                                   loop. Bears on the jit target in §9.
            CLAUDE.md #12–#17      tok codegen hazards. Any build step.
SUPERSEDES: nothing. Replaces the 2026-07-25 design conversation, which is
            not archived — this file is the only record.
OPEN:       §8  ! and % modifier semantics, `fail` recovery, skip placement,
                position-zero cycle check                          → Tony
            §7.6 which of three candidates actually breaks tok macro
                expansion — now a tok question, not a genParse one  → Tony
            §7.5 does the JSON family reach GroupItem::parse() at all?
                aCTionRunRulE result-discard + the Grokking-fold
                decision. Instrumentation suspect, see the "26"   → Tony/Clod
            §7.1 mechanism CONFIRMED from codegen; 0b fix FALSIFIED
                2026-07-27 against a live fixture — present in the
                tree, ineffective on JSONblock. Prime conjecture:
                vacuous truth in allAttributesOptional(). Mechanism
                unmeasured; instrumented print pending      → Clod
```

*Clay, 2026-07-25. Written from Tony's return-from-hibernation design session. Source material
read: `grammar`, `RuleStuff.twk`, `GroupItem::parse()`, `getStuff()`, `getRStuff()`,
`aCTionTraiT()`, `aCTionTraiTdata()`, `modify()`, `incant/jsonTest`, `incant/json1`, and the seven
JSON rules from `incant/utilities`. Design is closed enough to build — §9 is the staged build
order, and nothing in §8 blocks step 1.*

---

## 0. What genParse is

genParse is a kant action that reads a rule's own structure from the registry and emits a
**rule-specific parse method**. It replaces, for that rule, the generic table-driven walk in
`GroupItem::parse()`.

- **Initial target:** C++ that tok compiles. This is the deliverable.
- **Eventual target:** jittable kant. Same generator, different emission — kant doesn't care
  whether it spits out kant or C++, it's text into a field buffer either way.
- **Not a goal:** replacing `GroupItem::parse()` wholesale. Generated methods coexist with the
  generic driver, rule by rule, and the generic driver stays the correctness oracle (§9).

The three constraints on emitted code — no `if` statements, no call-outs to the generic matcher,
no recursive descent through the interpretive dispatch — are all satisfied, with one deliberate
allowance: **generated methods call each other directly.** See §2.6.

---

## 1. Why this is tractable

Three observations, each verified against the source. They are the load-bearing claims; if one
turns out false the design needs revisiting.

### 1.1 The per-term classifier already exists

`RuleStuff::setTestMatch()` is the complete classification of what kind of thing a term is:

```
if upTo || upToOver     testMatch = testUpTo;
or isBIN || isREGISTRY  testMatch = testContainer;
or data     switch(data) { case isANY: … case isCHAR: … case isSET: …
                           case isGROUP: testMatch = null; default: testString; }
or isMacro              testMatch = setMacroValue;
or isCondition          testMatch = testCondition;
or parseACTION          testMatch = testAction;
or !contents()  if !isMethod    testMatch = testString;
```

genParse's leaf emitter is **this switch with the assignment replaced by a text emission**.
`testMatch = testSet` becomes "emit an accumulator function"; `testMatch = null` (the isGROUP
case) becomes "emit a call to the referenced rule's parse method". Ten cases, already written,
already correct. This is the single strongest reason to believe genParse is a small job.

### 1.2 The one-line-body pattern already exists

`testMacro` in `RuleStuff.twk` carries the entire min/max counting loop, the `atRuleMark`
advance, the `noAdvance` rewind, and the `label.setToken()` call. Its three users — `testAny`,
`testCharacter`, `testSet` — are each **one line**: a tester expression handed to the macro.

genParse follows the same division, with one correction learned the hard way (§7.6): the shared
machinery lives in a **hand-written support library of ordinary functions**, not in macros. Emitted
rule bodies are pure boolean expressions over calls into it. That is what makes "no `if` statements
in generated code" achievable rather than aspirational — the branching is in `&&`/`||`
short-circuit evaluation and inside the library, never in emitted text.

`testMacro` remains the right *shape* to imitate — one shared body, many one-line users. It is only
the mechanism that changes, because a tok macro expands to a statement block and a statement can
never be a term in an `&&` chain.

### 1.3 A rule is a sequence XOR an alternation

From `parse()`'s dispatch:

```
if testMatch || onGroup || hasAttributes { … }
or isRule && hasMembers    sukcess = testOptions(ruleStuff);
```

Members are consulted **only** when there is no own-data test, no group reference, and no
attributes. So Tony's three-part concern resolves: the data test and the group reference are
conjunctive terms sitting at the head of the attribute sequence (his "isGROUP is really like an
attribute" is precisely right), and members are the mutually-exclusive alternative shape.

genParse never needs a general three-part combinator. It picks one of two folds by inspection.

---

## 2. The compilation scheme

### 2.1 Signature convention

```
extern int parse<Rule>(GroupItem into)
```

Returns 0/1. `into` is the **parent label to attach into**, not the rule's own label. Label
creation belongs to the callee — emitted as a local declaration in its own body (§3.1) — which
gives two properties for free:

- children are attached **only on success**, so a failed term leaves no debris; and
- an alternation rule can decline to create a label at all (§2.4).

The GroupItem-returning boundary that outside callers expect (`field = JSONblock(argument)`) is
a thin wrapper, §5.3.

### 2.2 Invariant R — and it already exists

> **Invariant R.** A generated parse method that returns false leaves `atRuleMark` exactly where
> it found it.

Every alternation and every optional term depends on R and on nothing else. With R, alternation
is a pure `||` chain — a failing option has already rewound itself, so the caller needs no
bookkeeping.

R is not new. It is `parse()`'s `matchFailed` block:

```
failedAt    = atRuleMark;
atRuleMark  = hereAt;
if label    label = 0;
```

Generated code inherits the existing contract rather than diverging from it. R lives entirely in
`leaveRule`/`leaveAlt` and is never emitted code's problem.

**One deliberate divergence.** The current rewind targets `hereAt`, which `checkInput()` resets
at the top of *every* iteration of the repetition loop. For a term with min ≥ 2 that matches
once and fails, `kount >= min` fails the rescue and the rewind goes to the start of the *second*
attempt, stranding the first match's consumed input. `?`, `*`, `+` are all safe (min ≤ 1 means
the rescue always covers a partial run), so nothing in the current grammar hits it — latent until
someone writes `X[2]`. **Generated loops save the mark once at loop entry** and are correct for
all min/max. Trivial when emitting a loop; awkward in a general driver.

### 2.2a Invariant R′ — repetition carries no state across passes

> **Invariant R′.** Generated repetition carries no state across passes. The mark is saved **once
> at loop entry**, not per iteration; each pass builds a **fresh label**, never recycled.

R governs a rule that fails. R′ governs a rule that repeats. They are separate obligations and a
loop must hold both.

**Provenance — checked against the tree 2026-07-28, both clauses, because until then this had only
ever been stated in a brief.**

**The mark clause** is §2.2's deliberate divergence, restated as an invariant instead of an aside.
`checkInput()` assigns `hereAt = atRuleMark` (`RuleStuff.twk:125`) and `parse()` calls it at the top
of *every* iteration, while the failure rewind targets that same `hereAt`
(`GroupItem.twk:1101`). So the rewind target moves with the loop: after N successful passes it
points at the start of pass N, not at loop entry. A term with min ≥ 2 that matches once and then
fails gets `kount >= min` false, so the rescue does not fire, and the rewind strands the first
match's consumed input. Confirmed latent: no `[2` … `[9` limit appears anywhere in the live incant
sources, and `?`/`*`/`+` are all min ≤ 1.

**The label clause** is genParseRuleAccess §1.6's, and it is a two-part handshake — both halves are
in the tree. The writer is `parse()`'s recycling path, `label.fLAG = true` after
`pStuff.label +% label.group; label.clear()` (`GroupItem.twk:1087`), reached only when
`label.isGROUP && max > 1`. The reader is `checkInput()`'s label block:
`if !label || !label.fLAG { label = new(tag); … } else label.fLAG = false`
(`RuleStuff.twk:141-144`) — i.e. *fill this one in place instead of minting a new one*. **Generated
code has neither half**, which is why the clause is an obligation rather than a port: nothing stops
an emitter from inventing its own recycling, and R′ says do not.

Both clauses are properties of the emitted loop, so they land with the repetition rung rather than
being provable in the abstract. Trivial when emitting a loop; awkward in a general driver — which is
the same reason §2.2 gives for the mark.

### 2.3 The two body shapes

```
/* sequence */
return leaveRule( <data> && <group> && <attr1> && <attr2> && … && <tailAction> );

/* alternation */
return leaveAlt( <opt1> || <opt2> || <opt3> );
```

That is the whole scheme. Conjunction for attributes, ordered alternation for members, both
branching without an `if`.

`<group>` is a group reference (`onGroup`) and is **not a special case** — per §7.2 it carries
identical semantics to an attribute term. It appears first in the chain because that is
`parse()`'s own order, and for no other reason.

### 2.4 Alternation rules are label-transparent

From `checkInput()`:

```
if noLabel || (isRule && hasMembers && !binType)    label = 0;
```

An alternation rule builds **no label of its own** — the winning option's label becomes the
result. So an alternation method declares no label and passes its `into` straight through to
whichever option wins. Getting this wrong produces an empty `JSONvalue` node wrapping every value,
i.e. the right language over the wrong tree, which the `code={}` actions then read. `leaveRule` and
`leaveAlt` are two separate functions precisely because of this line.

### 2.5 Two repetitions, not one

`*` and `+` mean different things depending on the term's data kind, and conflating them yields a
parser that accepts correctly and builds wrongly.

| | **Accumulation** | **Iteration** |
|---|---|---|
| applies to | character-level terms (isSET, isCHAR, isANY) | group references (isGROUP) |
| loop position | **inside** the matcher | **outside**, wrapping the term |
| result | one label, one token spanning the whole run | one fresh label per pass, appended |
| example | `field=[a-z]+` → one `field` holding `"abc"` | `JSONfield*` → N `JSONfield` children |
| emission | a generated per-term accumulator function | a generated per-term `many…` helper |

This is exactly the distinction `testMacro` embodies: its three users are precisely the three
data kinds that accumulate. **The applicability of `testMacro` and the ordering of the `data` enum
are the same fact** — which is why genParse can dispense with `getWhatFollows()`'s
`data && data < 4` comparison entirely (§2.7).

Accumulation also resolves an expression-vs-statement problem in the scheme: a loop cannot be a
term in a `&&` chain, and it doesn't need to be. Both kinds go into a small **generated function
per term** and the rule body calls it — the same relationship `testSet` already has with
`testMacro`, one tiny function per term. That this applies to iteration as well as accumulation is
what makes the whole scheme work without macros (§3.3).

### 2.6 Rule-to-rule calls are allowed; calls into the generic matcher are not

The forbidden thing is interpretive dispatch: `parse(stuff)`, `testOptions` walking
`nextMember`, `getStuff` allocation, indirection through `testMatch` function pointers. All of
that is gone from emitted code.

Direct calls between generated methods stay. Recursion is not the cost — interpretive dispatch
is. `JSONblock → JSONfield → JSONvalue → JSONblock` is a call graph that LLVM handles natively
and that terminates because `JSONblock` consumes `{` before descending. The alternative (an
explicit state machine over a work stack) reintroduces a dispatch switch — the branching ladder
the no-`if` constraint exists to avoid — and hands the JIT an interpreter loop instead of a clean
call graph. Strictly worse for the stated goal.

### 2.7 What genParse deletes

Everything `getWhatFollows()` computes is a compile-time constant: `hasMacro`, `onGroup`,
`onFail` (just `followingMember()`), `isTarget`, and `testMatch` via `setTestMatch()`. It is a
lazy static analysis cached on a mutable singleton. genParse makes it an eager static analysis
emitted as literals.

More than a tidiness win: of everything in that method, exactly one line is a **write** rather
than a query —

```
if !min && parent.min   parent.min = 0;
```

— and that line is the bug in §7.1. Generated code carries each rule's min as a baked literal and
nothing can reach across and zero it. genParse deletes the only site of that defect.

Also deleted, all for the same underlying reason: `isTarget`, the `data < 4` gate, and the
retag-to-parent's-ruleName. All three are the runtime asking *"where does this result go?"* —
a question genParse answers at generate time by naming the destination slot in emitted code.

Guards go the same way. `getGuard()`/`guarding`/`unGuarded` is lazy and stateful at runtime, but
guard sets are static. genParse bakes them in.

### 2.8 Actions in tail position only

Invariant R rewinds `atRuleMark`. It cannot rewind tree mutations, and `code={}` actions mutate
(`JSONfield`'s sets a tag and returns `token`). An action inside a chain that later fails will
have already run.

Both JSON actions sit last, which is where they naturally belong. Make it a rule:
**genParse emits `parseACTION` terms only in tail position, and refuses loudly at generate time
otherwise.** The current machinery has the same hazard; this closes it rather than inheriting it.

Note this constrains `code={}` parseActions specifically. Label methods (`ruleMethod=`, and the
`aCTion<Name>` pattern) are already tail-only in `parse()` — they fire after all terms succeed —
and both `if !parseACTION` guards in `parse()` exist to keep parseActions out of that path.

### 2.9 `defer`

```
if deferred {
    label.method    = method;
    label.deferred  = true;
    if !label.data  label.text = "g" tag; }
or !parseACTION
    if !(label = method(label)) sukcess = false;
```

`defer` means: don't fire the label method, stash it on the label and name it `g` + tag. That is
where `gIF`, `gFOR`, `gPrinT`, `gXpress` come from — the seam between parsing and generation.
genParse reproduces it: for a `defer` rule emit the stash; for a non-`defer` rule with a method,
emit a tail call that can retroactively fail the rule.

---

## 3. The support library

*Rewritten 2026-07-25. This section originally specified a tok macro library. That mechanism does
not support the shape required — see §7.6 — and it was the wrong shape regardless. Everything here
is now ordinary functions.*

**genParse does not use tok's macro facility at all.** A macro is compile-time text substitution;
genParse *is* a text substitution engine. Anything a macro would have expanded to, genParse emits
directly. And because function calls are expressions, `&&`/`||` composition works natively with no
macro mechanism involved.

The division of labour:

- **Hand-written support library** (§3.2) — the machinery: rewind, guard test, literal match, skip
  pass. Written once in C++, called from generated code.
- **genParse-emitted code** (§3.3) — the structure: one parse method per rule, plus one small
  helper per repeated or character-level term.

**Print for structure, calls for machinery.** Do not inline the machinery at each use. A six-line
counted loop emitted a few hundred times across the grammar destroys the one property that makes
§9's step-2 diff usable — that a human can read the generated file.

### 3.1 Frame and lifecycle

There are no enter functions. A sequence rule's frame is **two emitted declarations**; an
alternation rule's is one. Exit goes through a real function that receives the frame explicitly:

| function | signature | does |
|---|---|---|
| `leaveRule` | `(GroupItem into, GroupItem label, String from, int ok)` | on ok: attach `label` into `into`, `WIN`, return 1. Else `failedAt = atRuleMark; atRuleMark = from;` discard label, return 0 |
| `leaveAlt` | `(String from, int ok)` | as above minus the attach — an alternation builds no label of its own (§2.4) |

`leaveRule`/`leaveAlt` are the sole implementation of Invariant R. Nothing else rewinds.

The short-circuit still works: C++ evaluates the argument expression — including all its `&&`/`||`
— *before* the call, so `leaveRule` receives a finished boolean and only then does the rewind.

### 3.2 The hand-written support library

| function | for | does |
|---|---|---|
| `lit("x")` | string term, noLabel | skip pass, match literal at `atRuleMark`, advance |
| `litTo(label,slot,"x")` | string term, labelled | as above, text into the named slot |
| `inGuard("set",c)` | member option | one-character guard test against a baked literal set |
| `upTo(...)` / `upToOver(...)` | upTo / upToOver | capture until match; leave at / past the match |
| `macroVal(label,slot)` | isMacro | back-reference to an earlier same-named label |
| `container(R,label,slot)` | isBIN / isREGISTRY | longest-match lookup in the container |
| `act(name,label)` | parseAction, tail only | invoke the action against the label |
| `stashDefer(label,method,tag)` | defer rules | stash method + `g`-tag on the label |
| `leaveRule` / `leaveAlt` | every rule | §3.1 |

### 3.3 What genParse emits

| emitted | for | shape |
|---|---|---|
| `parseR(into)` | every rule | §5.1 |
| a direct call `parseR(label)` | isGROUP term | no wrapper needed — a call is already an expression |
| `(inGuard(...) && parseR(into))` | member option | guard baked as a literal at generate time |
| `manyRTerm(label)` | iteration, max > 1 | counted loop, mark saved **once** at entry |
| `matchSlot(label)` | isSET / isCHAR / isANY | accumulator, §5.2 |
| `((term) || 1)` | min 0, max 1 | inline, no helper |
| `promote` | isTarget | `parseR(into)` plus retag to the enclosing rule's name |

**Reversal of an earlier note, recorded so nobody reinstates it.** This section previously said
*"`many` must be a macro, not a function"* on the grounds that its term is re-evaluated each
iteration. That held only while `many` was generic. It is not: genParse emits **one helper per
repeated term**, so the term is baked into that helper's body and re-evaluation is just the loop
running. `many` being a function is now the point rather than a compromise, and it puts iteration
on the same footing as the accumulators, which were always generated functions (§5.2).

Two hazards the macro version carried are simply gone: no implicit shared state between macros, and
no redeclaration collision from using the same macro twice in one function.

### 3.4 Skip-set placement

One decision, made once, stated out loud: **the skip-set pass happens at the head of each token
match** (`lit`, `litTo`, and each accumulator), not in the frame. noSkip selects the raw variant.
Conventional, and it keeps the frame free of input manipulation, which matters because the frame is
established on paths that then fail.

---

## 4. The emitter

### 4.1 Top-level walk

```
genParse(rule)
    if rule.isRule && rule.hasMembers && !rule.binType
        emitAlternation(rule)
    else
        emitSequence(rule)
```

```
emitSequence(rule)
    emit "extern int parse" rule.tag "(GroupItem into)\n{\n"
    emit "GroupItem label = new(\"" rule.tag "\");\nString from = atRuleMark;\n"
    emit "    return leaveRule(into,label,from,"
    terms = []
    if rule.data && rule.data != isGROUP    terms += emitTerm(rule, asData)
    if rule.onGroup                         terms += emitTerm(rule.onGroup)   // same path as an attribute
    for attr in rule.attributes             terms += emitTerm(attr)
    join terms with " && "
    emit " );\n}\n"
```

```
emitAlternation(rule)
    emit "extern int parse" rule.tag "(GroupItem into)\n{\n"
    emit "String from = atRuleMark;\n"
    emit "    return leaveAlt(from,"
    for member in rule.members              terms += emitOption(member)
    join terms with " || "
    emit " );\n}\n"
```

Ordering within a sequence is `data → group → attributes → tail action`, matching `parse()`'s own
order. There is no ambiguity, because when generating for a rule we already know what the rule
contains — which is why `getWhatFollows()` has no analogue here.

### 4.2 Leaf emitter

Mirrors `setTestMatch()` case for case:

| condition | emits |
|---|---|
| `upTo` | `upTo(…)` |
| `upToOver` | `upToOver(…)` |
| `isBIN \|\| isREGISTRY` | `container(R,label,slot)` |
| `data == isANY` / `isCHAR` / `isSET` | a generated accumulator function + a call to it |
| `data == isGROUP` | a direct `parseR(label)` call; guard-wrapped for a member option; or promote — per context and modifiers (§3.3) |
| `isMacro` | `macroVal(label,slot)` |
| `isCondition` | a baked constant — min is known at generate time |
| `parseACTION` | `act(name,label)` — **tail position only**, else refuse |
| default / `!contents() && !isMethod` | `lit("…")` or `litTo(label,slot,"…")` |

### 4.3 The modifier fold

`modify()` walks a modifier **string** and assigns into RuleStuff fields:

```
while *modifier
    switch(*modifier++) { … }
```

Multi-character modifier strings are live in the grammar today — `nameSet-^*`,
`quoteBody}=tik$@`, `flags=[-# 0+']*` — so the emitter **folds** a modifier string rather than
looking up a single character. Note `modify()` has no accumulation logic, only assignment, so
stacked modifiers are **last-write-wins on shared fields**: `+` then `*` leaves min at 0 because
`*` overwrites it. Probably what anyone wants, but it is ordering-sensitive and silent.

The fold runs on two independent axes.

**Match axis** — picks or wraps the matcher:

| mod | sets | emits |
|---|---|---|
| `+` | max = MANY | a `many…` helper with min 1, or accumulator with min 1 |
| `*` | min = 0, max = MANY | a `many…` helper with min 0, or accumulator with min 0 |
| `?` | min = 0 | `((term) \|\| 1)` inline |
| `<` | noAdvance | match, then restore the mark |
| `^` | noSkip | raw variant, no skip pass |
| `{` | upTo, unGuarded | `upTo(term)` |
| `}` | upToOver, unGuarded | `upToOver(term)` |
| `$` | isMacro | `macroVal(label,slot)` |
| `!` | banged | **open — see §8** |
| *(Limit)* | min, max explicit | a `many…` helper with those bounds |

**Result axis** — picks the attach form:

| mod | sets | emits |
|---|---|---|
| `@` | isTarget | promote — child's label becomes ours, retagged |
| `-` | noLabel | no label built, no attach |
| `_` | unGuarded | a bare `parseR(...)` call rather than a guard-wrapped one |
| `&` | isPointer | definition-time marker; per `opPointer`'s own comment, no parse-time effect |
| `%` | isPercent | **open — see §8** |

`~` and `|` are unused. `|` was reserved for `A | B` alternatives and is not needed — members
already give ordered alternation with a per-option guard test.

---

## 5. Worked example — JSONblock

Source rules, as they stand after Tony's `JSONblock`-in-`JSONtoken` fix:

```
JSONtoken isRule
    JSONblock; "false"; "true"; GrouP; NumbeR;
JSONvalue isRule
    JSONblock; JSONarray; JSONtoken;
JSONfield isRule JSONtoken ":"- JSONvalue ","?- code={…};
JSONitem  isRule JSONtoken@ ","?-;
JSONlist  isRule JSONitem+;
JSONarray isRule "["- JSONlist? "]"- code={…};
JSONblock isRule fail "{"- JSONfield* "}"-;
```

### 5.1 The seven methods

Sequence rules declare a label and a mark, then hand both to `leaveRule`. Alternation rules declare
only a mark, build no label, and pass `into` straight through to the winning option (§2.4). Guard
sets are baked in as literals at generate time.

```
/*  JSONblock isRule fail "{"- JSONfield* "}"-                          */
extern int parseJSONblock(GroupItem into)
{
GroupItem   label = new("JSONblock");
String      from  = atRuleMark;
    return leaveRule(into,label,from,
                   lit("{")
                && manyJSONblockFields(label)
                && lit("}") );
}

/*  JSONfield isRule JSONtoken ":"- JSONvalue ","?- code={...}          */
extern int parseJSONfield(GroupItem into)
{
GroupItem   label = new("JSONfield");
String      from  = atRuleMark;
    return leaveRule(into,label,from,
                   parseJSONtoken(label)
                && lit(":")
                && parseJSONvalue(label)
                && (lit(",") || 1)
                && act(JSONfieldCode,label) );
}

/*  JSONvalue isRule : JSONblock; JSONarray; JSONtoken;                 */
extern int parseJSONvalue(GroupItem into)
{
String      from = atRuleMark;
    return leaveAlt(from,
                   (inGuard("{",*atRuleMark) && parseJSONblock(into))
                || (inGuard("[",*atRuleMark) && parseJSONarray(into))
                || parseJSONtoken(into) );
}

/*  JSONtoken isRule : JSONblock; "false"; "true"; GrouP; NumbeR;       */
extern int parseJSONtoken(GroupItem into)
{
String      from = atRuleMark;
    return leaveAlt(from,
                   (inGuard("{",*atRuleMark) && parseJSONblock(into))
                || lit("false")
                || lit("true")
                || parseGrouP(into)
                || parseNumbeR(into) );
}

/*  JSONitem isRule JSONtoken@ ","?-                                    */
extern int parseJSONitem(GroupItem into)
{
GroupItem   label = new("JSONitem");
String      from  = atRuleMark;
    return leaveRule(into,label,from,
                   promoteJSONtoken(label)
                && (lit(",") || 1) );
}

/*  JSONlist isRule JSONitem+                                           */
extern int parseJSONlist(GroupItem into)
{
GroupItem   label = new("JSONlist");
String      from  = atRuleMark;
    return leaveRule(into,label,from,
                   manyJSONlistItems(label) );
}

/*  JSONarray isRule "["- JSONlist? "]"- code={...}                     */
extern int parseJSONarray(GroupItem into)
{
GroupItem   label = new("JSONarray");
String      from  = atRuleMark;
    return leaveRule(into,label,from,
                   lit("[")
                && (parseJSONlist(label) || 1)
                && lit("]")
                && act(JSONarrayCode,label) );
}
```

And the two generated iteration helpers those refer to — one per repeated term, the term baked into
the body, mark saved **once** at entry:

```
extern int manyJSONblockFields(GroupItem label)          /*  JSONfield*  min 0  */
{
String  from = atRuleMark;
int     kount;
    while parseJSONfield(label)     kount++;
    return true;                    /*  min 0 — cannot fail; `from` unused, elided by genParse  */
}

extern int manyJSONlistItems(GroupItem label)            /*  JSONitem+   min 1  */
{
String  from = atRuleMark;
int     kount;
    while parseJSONitem(label)      kount++;
    if kount    return true;
    atRuleMark = from;
    return false;
}
```

Nine functions, no `if` in any rule body, no interpretive dispatch, no macro facility, recursion via
ordinary calls. `JSONvalue`'s and `JSONtoken`'s guards bake down to single-character tests.

Note `manyJSONblockFields` shows the min-0 elision from §5.2 in situ: with min 0 the loop cannot
fail, so the counter test and the rewind are dead code and genParse should not emit them. Shown here
commented rather than removed so the general shape stays legible against the min-1 case beside it.

### 5.2 A generated accumulator

For `field=[a-z]+`, which is the case that lets the `data` enum ordering go away:

```
/*  from:  field=[a-z]+                                                 */
extern int matchField(GroupItem label)
{
int     kount;
String  from = atRuleMark;
    while kount < MANY && aToZ.contains(*atRuleMark) { kount++; atRuleMark++; }
    if kount { label.field.setToken(from,kount); return true; }
    atRuleMark = from;
    return false;
}
```

Called from the parent as one term: `&& matchField(label)`.

Compare the path this replaces: `+` sets max = MANY, so `aCTionTraiTdata` fires `isRule = true`
and `input.group = DatA`, making `field` a group reference to an anonymous set node; that node's
parse runs `testSet` → `testMacro`, which accumulates and calls `setToken` once after the loop;
then attaching back to `field` takes the `isTarget` path via `data && data < 4`, replacing
`field`'s label and retagging it. Two levels of indirection, an anonymous node, a promotion and a
retag — all collapsed into one function that writes `label.field` directly, because the emitter
knows the destination slot's name at generate time.

Two banked optimizations, not for now: simple sets can emit a direct range comparison instead of
`PLGset::contains` (arbitrary sets need care, so PLGset stays the default); and `min` is always 0
or 1 in practice for these, so `kount >= minK` degenerates to `kount`.

### 5.3 The entry wrapper

Outside callers do `field = JSONblock("json string or filename")` and expect a GroupItem. One
wrapper per externally-invoked rule preserves that:

```
extern GroupItem runJSONblock(GroupItem argument)
{
GroupItem   result = new("JSONblock");
    pushInput(argument);
    if !parseJSONblock(result)   result = 0;
    or !result.hasAttributes     result = trueResult;
    return result;
}
```

`trueResult` on empty success mirrors `parse()`'s last line. **The `pushInput` side wants
checking** — `getFile`'s unconditional `pushInput` is a known sore spot per the directives notes.
Diversion *teardown* needs nothing here: it is handled generically in `parse()`'s failure path and
is not a JSONblock mechanism (§7.3).

**Bug caught by Clod, 2026-07-25 — this example originally read `!result.hasMembers`, which would
have discarded every successful parse.** `leaveRule` attaches children with `+%`, which compiles to
`addAttribute()`, so a JSON tree is built from **attributes, not members**; `hasMembers` is never
true and the guard fired on every good result. Confirmed from generated code. Worth dwelling on as
the archetype of this scheme's worst failure mode — the parse was right, the tree was right, and a
wrong predicate at the boundary threw it away silently. §6.5's tree diff is what catches this class.

**Making the wrapper callable from incant — three requirements, and the first GATES the others**
(added 2026-07-25 after Clod hit this; strong candidates, not yet confirmed):

**Method binding runs through tok external declarations. No declaration, no binding — silently.**
`setRuleAction` resolves the method *by name*, so with nothing declared there is nothing for the
lookup to find, and no registration form rescues it.

1. **An `extern` declaration in `groups.ext` — the gating item.** It lives OUTSIDE the repo, and per
   bear trap #16 tok **merges** against it rather than regenerating it. So adding an extern to a
   `.twk`, retokking and building clean leaves it undeclared and unbindable. `json.md` records the
   identical requirement for `getURLintoBuffer`. Sanity check: `grep -c extern GroupRules.h` ≈ 152.
2. Registration in **`incant/setup`** in the `=value` form:
   `runJSONblock immediateAction=runJSONblock;` — **the bare no-value form silently fails to bind**,
   per TODO.md's Phase Bytecode note (`setRuleAction` reads the method name from `item.text`).
3. Visibility from the call site's search stack.

Missing any one gives the same symptom — the function is simply never entered, with no error and a
clean build. Which makes this a strong candidate for a bear trap of its own: **three separate
silent-failure modes converge on one indistinguishable symptom.**

---

## 6. Instrumentation

Tony's ask. Not required for step 1, specified now so it lands in the right place rather than
being retrofitted.

### 6.1 Counters

Two per rule, emitted as file-static ints in the generated file: **attempts** and **wins**.
`HIT` at the top of each generated method (one emitted line, alongside the frame declarations),
`WIN` in `leaveRule`/`leaveAlt`'s success path (§3.1). Gated behind a single compile-time switch so
instrumented and clean builds come from the same generator.

The generic driver needs the same two counters in `parse()` for the comparison to be
apples-to-apples — one `HIT` after `getStuff`, one `WIN` in the success path.

### 6.2 Two measurements for two different questions

Worth keeping distinct:

- **Wall clock** answers *"is generated faster than generic?"* Different code, same work.
- **Attempt counts** answer *"is this grammar/ordering doing unnecessary work?"* Same code,
  different work. Deterministic and noise-free, which makes it the better metric for ordering
  decisions — a machine-noise-immune number beats a timer for anything you want to compare
  across small changes.

### 6.3 Option ordering

The direct payoff Tony flagged: member options are currently ordered by best guess.

For an alternation of n options with win probabilities p₁…pₙ, expected options tried is Σ i·pᵢ,
minimised by sorting descending by p. Hit-rate data gives p directly.

**But be honest about the size of the prize.** A guard test is one character comparison, so a
guard-rejected option costs almost nothing and reordering a well-guarded alternation buys little.
The win concentrates in **guard-ambiguous** alternations — options whose guard sets overlap, where
a miss costs a real descent. So the useful report is not "all rules by hit rate" but
*"alternations whose options have overlapping guard sets, ordered by attempt volume."* That list
is short, computable statically from the baked guard sets, and is where ordering should be
applied. Measure before optimising.

### 6.4 Three more things the counters give you free

- **Dead options.** An option with attempts > 0 and wins == 0 across a real corpus is grammar
  cruft or a guard that can never pass.
- **Inlining candidates.** High-attempt transparent wrappers. `JSONitem` is the archetype: a rule
  whose only substance is an `@` promotion plus optional punctuation. `JSONlist isRule JSONitem+`
  could inline JSONitem's body into the loop and drop a call layer. The generate-time information
  to detect this is already present.
- **A regression tripwire.** Attempt counts are a fingerprint of a parse. A grammar change that
  shifts them unexpectedly is a signal that something moved.

### 6.5 Harness

The generic-vs-generated comparison is meaningless unless both paths produce the **same tree**, so
a structural tree compare is part of the harness, not an afterthought. `printDefinition` output
diffed between the two paths is the cheap version and is enough — and `incant/json1` is already
that harness in prototype ("ONE JSON case at a time … printDefinition shows what result tree (if
any) got built"). Note the diff is **black box**: it compares output trees, not drivers, so it does
not depend on §7.5 resolving.

**Diff on passing cases; expect divergence on failing ones.** The generic path may still carry
§7.1's defect, which affects failure *reporting*, not tree shape on success. For input that parses,
both paths should produce identical trees. For input that fails, generated code correctly returns
false while the generic path may hand back a non-null sentinel. That divergence is the fix showing,
not a regression — do not "correct" generated code to reproduce it.

Worth noting: Tony's Idea Three (`print form` / `print form to field`) is exactly the tool this
harness wants. The text form of a form is the thing you diff. Independent motivation for that
work, from a direction nobody planned.

---

## 7. Bugs found while designing this

These are parser bugs, not genParse design. **They belong in `docs/json.md` and `CLAUDE.md`'s bear
traps**, and are recorded here only because they surfaced in the course of this design and each
one bears on the parity target genParse is measured against. Fold them out of this document when
they land somewhere permanent.

### 7.1 The min-zeroing defect — a rule that cannot report failure

This is the mechanism behind `jsonTest`'s silent success-on-failure, and it is not confined to
JSON.

`getWhatFollows()`, for an embedded (attribute) term:

```
if !min && parent.min   parent.min = 0;
```

An attribute with min 0 **permanently zeroes its parent rule's min.** Then in `parse()`:

```
matchFailed:
    if !sukcess {
        if !sukcess && kount >= min sukcess = true;
```

With min == 0 and kount == 0 that always holds, so **a rule whose min has been zeroed cannot
report failure.** Everything downstream follows: the `debugHere` block is skipped, so no
`atRuleMark = hereAt` rewind and `label = 0` never runs; `if !sukcess && notifyFail` is
suppressed, so the `fail` prefix stops reporting; and `if sukcess && !label label = trueResult;`
hands the caller a non-null sentinel. `field = JSONblock(argument)` is non-null, `if field` is
true, `testJSON` prints `ok`. The `Rule JSONblock / Failed at:` line in the log is a *nested*
JSONblock still failing honestly on its way up.

`JSONblock isRule fail "{"- JSONfield* "}"-` has the trigger exactly: `JSONfield*` is min 0.

**Persistence.** `getStuff` returns the field's own persistent RuleStuff and only copies when
`stuff.rule != this || stuff.inProcess`, so a first non-reentrant call runs `getWhatFollows()`
against the persistent stuff; `RuleStuff(RuleStuff r)`'s `*this = *r` then copies min and
`followed` into every later frame, and `if !followed` guarantees it is never recomputed. Written
once, inherited for the life of the process. Hence: clean `FAIL` in isolation, `ok` on every
invocation after. The probe's "several prior successful calls" is a red herring — **one prior call
is enough.**

**Test (decisive, one run).** Print `min`/`max` on JSONblock's stuff immediately before and
immediately after the first parse. Cheaper alternative: feed `JSONblock` malformed input that must
fail — `'{'` — **twice in a row and nothing else**. First `FAIL`, second `ok` confirms it; both
`FAIL` means the defect is real but has no current reproduction, which is itself a reportable
answer.

**Scope.** Scan the grammar for attributes with `?` or `*`: `IF … SemI-? StatemenT ElsE?`,
`DefinE NewGroup Attributes? MemberS`, `RunRulE NamE InvokE? ';'-?`, `TraiT NamE Modifier* Limit?
TraiTdata?`. Nearly every rule in the language has one. If the propagation fires as it reads, most
rules lose the ability to report failure after their first use — a strong candidate explanation for
TODO.md's standing finding that *"the parser backtracks silently and the top-level `strap.parse(0)`
result is unchecked, so parse errors currently produce NOTHING,"* and for why `aCTionFailed` has
stayed dormant despite being wired (`notifyFail` sits behind a `!sukcess` already flipped).

**Fix direction.** The defect is in the propagation, not the rescue. Zeroing the parent's min is
only sound when *every* attribute of the parent has min 0; `JSONblock`'s `"{"-` is mandatory, so
its min must stay 1. The `kount >= min` rescue is doing its legitimate job — it is what makes `X*`
and `X+` terminate correctly — it is being fed a lie.

**Caveat closed (Clod, 2026-07-25, from generated `RuleStuff.mm:567-568`).** The name-resolution
worry is resolved and the diagnosis stands unchanged. The line compiles to:

    if ( !min && rule->parent->rStuff->min )
        rule->parent->rStuff->min = 0;

Bare `min` reads this RuleStuff's own min. `parent.min` writes the **parent GroupItem's persistent
RuleStuff's** min, reached through the auto-forward tok applies when a GroupItem lacks a field it
finds on its rStuff (same mechanism as `item.min` → `item->rStuff->min` elsewhere in
`GroupItem.mm`). The rule GroupItem has no `min` field of its own. So the write does land on
shared, memoized, per-rule state exactly as §7.1 describes.

**0b (Clod, 2026-07-25).** Fix implemented: a helper walks `nextAttribute()` and the zeroing is
gated on *every* attribute being individually optional. Confirmed from codegen that the zeroing sits
in `getWhatFollows`'s `isEmbedded` branch and the `isMember` branch is mutually exclusive with it
(`RuleStuff.mm:557-570`, if/else on `rule->options.affiliation`), so an attribute-only walk is
correctly scoped. A sibling with unset rStuff is counted mandatory-unknown rather than optional —
the conservative direction, but it can decline to zero a min that legitimately should be zeroed.
Baseline byte-identical before and after; ~~the fix is code-correct but not yet falsified against a
live fixture~~ — **tested 2026-07-27, and the result moves the attribution rather than confirming
it. §7.1's mechanism is REAL but is NOT the cause of jsonTest's silent `ok`.**

**Read this before the paragraphs below, which were written between the two measurements and
overstate the first result.** Two measurements landed in sequence:

1. *Behavioural (no instrumentation).* 0b is in the tree (`8e3c118`) and the predicted `ok`→`FAIL`
   flip does NOT occur. That falsifies **the prediction**, not 0b itself.
2. *Instrumented (`min`/visited-count prints at the zeroing site and in the gate).* **`parent.min = 0`
   NEVER EXECUTES** — not during grammar definition, not during either parse. The print sits inside
   the taken branch, so its absence is airtight: min is never zeroed, and min-zeroing therefore
   cannot be what rescues JSONblock's return.

So 0b is not "inert" or "failing to gate." **The two claims the record needs, because they are about
the same commit and point opposite ways:**

> **0b is FALSIFIED as a cure for the JSON symptom, and VINDICATED as a fix for the defect.**
> §7.1's tag: mechanism real, fix working, not the cause of jsonTest's silent `ok`.

Which of the two worlds obtains — gate correctly declines, versus site never reached — is settled by
inspection of the rule itself:

```
JSONblock isRule fail "{"- JSONfield* "}"-;
```

`"{"-` and `"}"-` are **mandatory** (min 1; the `-` is noLabel, not optionality). So
`allAttributesOptional()` reaches `if !attr.rStuff || attr.min` and returns **false** at the first
literal. The gate declines, correctly, and `parent.min = 0` is correctly not executed.

That also explains the instrumented silence in one stroke rather than two: the visited-count print
was placed only on the return-*true* path, so a correctly-declining gate produces exactly the
observed absence. Consistent negative evidence, not a missing print.

Confidence: strong inference from the grammar plus consistent negatives; **one print on the gate's
false path would confirm it directly** and is folded into the next build. Not treated as proven here.

**Consequence for the Scope paragraph below.** §7.1's claim that nearly every rule in the language
loses failure reporting is a claim about the **PRE-0b tree**. Post-0b, any rule with at least one
mandatory attribute — which is most of them — correctly declines to zero. The Scope paragraph should
be read as describing the defect 0b fixed, not the tree as it stands. Its real post-0b scope is
unmeasured.

**What still needs an explanation:** JSONblock returns non-null for `'{'` with `min` never zeroed. The
rescue is elsewhere — `kount >= min` at the `matchFailed` label is the next place to look, since it
rescues on `kount >= min` and that holds trivially when a rule matched zero times and min is 1 only
if kount reached 1. Unexamined as of this writing.

**The fixture** (Clay SEQ 20's inverted ordering — the discriminator the earlier attempt lacked).
§7.1's own memoization story predicts a first-call FAIL under *both* hypotheses, so "malformed twice"
spends the reading on the arming call. Invert it: a well-formed parse arms, a malformed one reads,
nothing follows. One process — memoization is per-process, so two binary invocations are two fresh
first-calls and both FAIL regardless.

```
testJSON('{"a":"b"}');   ->  ok  : {"a":"b"}      arming call succeeds
testJSON('{');           ->  ok  : {              THE READING: non-null for malformed input
```
`FAIL` here would have meant 0b works. `ok` means it does not. Interleaved in that output, a
`Rule JSONblock / Failed at:` report *fires* while the return is still rescued to non-null.

**Scope of the claim — narrower than "the defect is still live".** Proved: JSONblock returns non-null
for `'{'` on a second in-process call with 0b present. NOT proved: that `min` is still being zeroed.
That is the presumed mechanism and it is unmeasured. Two worlds sit behind one observation —
`min == 0` after arming (the gate isn't firing) versus `min` stays 1 (0b works and something *else*
rescues the return, which would move three days of attribution). Instrumented print pending.

**Prime conjecture — vacuous truth (confirmed available by inspection, not yet confirmed as the
cause).** `GroupItem.twk:897 allAttributesOptional()` walks siblings and `return true`s on falling
out of the loop. A universal over an empty set is true, so a walk that finds *no* attributes — or
runs before the attribute list is linked — passes the gate vacuously and zeroes exactly as the
ungated code did. The unset-sibling case IS guarded (`!attr.rStuff` → false); the no-siblings-found
case is NOT, and the two fail in opposite directions. If the visited-count reads 0 or 1 for
JSONblock (which has a `fail` prefix plus three terms), that is the bug, and the fix is a floor:
refuse to zero unless the walk visited at least one attribute.

**Also observed, unresolved:** a failing JSONblock runs off the end of its argument and consumes the
enclosing script, terminating the run (`stop: ending input divert`). See the third restoration in
§2.2's neighbourhood — the input stack, alongside R (the mark) and R′ (the tree). Generated code
gets it structurally from §5.3's entry wrapper popping the diversion on *both* paths.

**Consequence for jsonTest as an oracle:** its last case is annotated `KNOWN TO FAIL` and prints
`ok`. When min-zeroing is genuinely fixed that case flips to a real failure, which under the
input-eating above terminates the run — so jsonTest will appear to break at the moment the defect
is fixed. It is already the last case, so nothing downstream is lost.

### 7.2 The group-reference success asymmetry — RESOLVED, fix specified

In `parse()`'s match block:

```
if sukcess && onGroup && onGroup.parse(ruleStuff)   sukcess = true;
if sukcess && hasAttributes                         sukcess = testAttributes(ruleStuff);
```

The attributes line **assigns** its result. The group line only ever sets true — so if
`onGroup.parse()` returns null, `sukcess` stays true from `checkInput()` and the term reports
success despite its group reference having failed.

Not catastrophic, because the failing child has already rewound `atRuleMark`, so the parent's
*next* term sees the original input and fails there instead. Net effect: correct accept/reject in
most cases, but **failures land one term late and `failedAt` points at the wrong place.** That
compounds with §7.1 — a late failure inside a min-zeroed rule gets rescued outright.

**Tony's ruling (2026-07-25): a group reference should behave exactly like an attribute.** This is
a bug, not a design choice.

The current line is not careless, and that is worth knowing before touching it: it is deliberately
written so the returned GroupItem doubles as a boolean, and `if sukcess && !label label =
trueResult;` at `parse()`'s tail exists precisely to make that safe when a success produces no
label. The success path is handled on purpose. Only failure is not.

**Fix** — minimal diff, preserves short-circuit, avoids any GroupItem→int coercion question:

```
if sukcess && onGroup && !onGroup.parse(ruleStuff)  sukcess = false;
```

Reads as the exact complement of the attributes line below it, calls `parse` exactly once, and
leaves the enclosing `!parseACTION` guard untouched. **Landed as commit `7b84748`, baseline
byte-identical — exactly as predicted, since its effect is masked while §7.1 is live.**

**Why optional terms stay safe.** Optionality lives downstream, in `matchFailed`'s `kount >= min`
rescue — not in ignoring failure here. A min-0 term that now correctly reports failure gets
rescued there, and the child has already rewound itself per Invariant R, so `atRuleMark` is where
it started.

**Commit sequencing — this landed BEFORE §7.1's fix, as its own commit.**

- While §7.1 is live, min-zeroed parents rescue anyway, so this fix's effect is largely masked.
  That made it the cheap one to land first: run the standing baseline (full workspace build,
  `grep -c extern GroupRules.h` = 152, `oneTest` → `maximus = 26`, `jitGifScratch` → 99/11,
  `jsonTest`) and if it holds, a correctness fix is banked at near-zero risk. It held.
- Then §7.1 unmasks failure propagation generally, and any fallout is attributable to §7.1 alone
  because this change is already in and proven neutral.
- The reverse order teaches much less: fixing §7.1 first turns both bugs loose at once and nothing
  that moves can be attributed.

**One case not resolved statically.** `{`/`}` (upTo/upToOver) sets `testMatch` while `data` is
isGROUP, so a term can carry both `testUpTo` — which consumes input — and `onGroup`. Whether the
mark position after a rescued failure is then right is unclear to me. But it is unclear in exactly
the same way for the attributes line, which is the argument for the change rather than against it:
making them identical inherits whatever the exercised path does, instead of maintaining a second
set of semantics nobody has tested.

**genParse payoff.** With this landed, a group reference is not a special case — it is the first
conjunctive term, emitted by the same path with the same failure semantics as any attribute
(§2.3, §4.1). Tony's "isGROUP is really like an attribute" becomes literally true.

### 7.3 NEXT-0 appears answered — and Clod's instrumentation corroborates it

`wakeup.md`'s NEXT-0 asks whether a top-level-statement parse entry for arbitrary incant code
exists, or whether webChannel's `/eval` needs its own parser rule. Diversion is handled in
`parse()`'s *generic* failure path:

```
if !*atRuleMark && inputDiverted {
    while inputDiverted && !*atRuleMark { lastIndent = 0; popInput(); }
    if sukcess && *atRuleMark   goto continueHere; }
```

That is what *any* rule does when it exhausts diverted input — pop and resume. It is not a
JSONblock mechanism. With `Start=StatemenT+` as the declared entry point, `/eval` is
`pushInput(text)` plus a parse of `Start`: a thin wire-up, not a parser task. **This unblocks
webChannel Step 1 without building anything.** The `pushInput` side still wants Clod's
confirmation; the parse side is settled.

**Corroborated 2026-07-25 (Clod, 0b instrumentation).** Instrumenting `GroupItem::parse()` during
a `jsonTest` run showed every observed call to be a bootstrap-grammar rule (`Start`/`StatemenT`
family: `RunRulE`, `DefinE`, `NamE`, `GrouP`, `InitiatE`, `TraiT`, …) parsing the fixture's own
**incant source text**. `incant/jsonTest` opens with `Start();` on line 1, so this is `Start`'s own
descent — direct evidence that arbitrary incant code reaches the parser through `parse()` under
`Start`, which is exactly the `/eval` path. §7.3's conclusion stands and is now observed rather
than inferred.

The same instrumentation raised a *separate* question about the **JSON** route specifically — see
§7.5. Do not conflate the two: the incant-source path is confirmed; the JSON-family path is in
doubt.

### 7.4 `getStuff` — leave it alone, genParse retires it

Tony's dislike of `getStuff` is well-founded: RuleStuff is two classes wearing one coat.

- **Shape** — `testMatch`, `onGroup`, `onFail`, `isTarget`, `hasMacro`, min/max, guard set.
  Immutable, derivable at definition time.
- **Frame** — `label`, `kount`, `sukcess`, `hereAt`, `failedAt`, `inProcess`, `parentStuff`.
  Strictly per-invocation.

Every awkward thing follows from the merge. `inProcess` exists only to detect reentry on a shared
object; the copy constructor exists only to hand-clear the four frame fields out of a shape copy;
`followed` exists only to memoize shape computation on an object that also carries frame state.
Split them and all three disappear.

Moving it to the `DefinE` action is the right eventual fix. But **genParse performs that split
maximally**: shape becomes emitted literals and emitted structure, frame becomes the generated
method's stack locals. Nothing to allocate, nothing to reset between parses, nothing to reenter.
So `getStuff` is not debt to pay before genParse — it is scaffolding genParse retires. Leave it
where it is.

### 7.5 Does the JSON family reach `GroupItem::parse()` at all? — **ANSWERED YES, AND LOCATED 2026-07-27**

> **RESOLVED at the observation level; the earlier "no JSON rule reaches parse()" reading below was
> the suspect measurement it warned it might be. It was wrong. Keep reading it as a lesson in why
> §7.5 carried three self-issued caveats, not as a finding.**
>
> **The measurement** (Clay SEQ 22 §2's capped boundary test — instrument the BOUNDARY, not the
> match; one test, then stop regardless of outcome). Two prints: what `parse()` returns for
> JSONblock, and what the invocation layer hands back. Fixture = §7.1's inverted arm/read pair.
>
> ```
> DIAG runRule  : JSONblock parse() -> NON-NULL     well-formed {"a":"b"} — correct
> DIAG runRule  : JSONblock parse() -> NULL         malformed  '{'       — CORRECT FAILURE
> ...and testJSON still prints   ok  : {
> ```
>
> **So: the JSON family DOES reach `parse()`, `parse()` detects the failure correctly, returns NULL
> correctly, and reports it correctly (`Rule JSONblock / Failed at:` fires in the same run). The
> caller sees non-null anyway.** Honest inner layer, truthy outer layer — a result-discard
> signature, at a different level of the stack from the match.
>
> **Consequences, all of them narrowing:**
> - `matchFailed`'s `kount >= min` rescue is **exonerated** — with min at 1 and kount at 0 it cannot
>   fire, and the boundary print shows the failure surviving `parse()` intact.
> - §7.1 min-zeroing is **exonerated** (see §7.1 — `parent.min = 0` never executes).
> - The bug is **entirely in the invocation layer.**
>
> **One refinement the trace gives free, recorded rather than chased:** JSONblock's `runRule` calls
> are NOT followed by `aCTionRunRulE` discard lines, while every `define` call is. So JSONblock
> reaches `runRule` via the `GroupActions.rtn:484` dispatch path (`or isRule result =
> runRule(arg,target)`), **not** through `aCTionRunRulE` — which means the specific discard at
> `ruleActions.rtn:666` (`rule = runRule(...); return input;`, TODO.md cause 2) is not the one on
> this path. Same layer, different site. Next investigator starts at `GroupActions.rtn:484` and
> follows `result` to whatever `JSONblock(argument)` actually returns to incant.
>
> **Not fixed. Locating it was the assignment; fixing it was explicitly not.**

---

*Superseded reading below — retained per the resurrection-reader standard.*

### 7.5 (original) Does the JSON family reach `GroupItem::parse()` at all? — OPEN, instrumentation suspect

*Found by Clod 2026-07-25 while trying to falsify 0b. This one deserves its own dated finding doc
rather than a home here; recorded now because it changes §9.*

**The observation.** Instrumenting `parse()`, `getWhatFollows()` and `runRule()` through a
`jsonTest` run: every observed `parse()` call was a bootstrap-grammar rule parsing the fixture's
own incant source. **No JSON-family rule was observed calling `parse()`**, and `runRule()` fired
once, with `rule=define`, never with `rule=JSONblock`. If that holds, `getWhatFollows()` — and
therefore both §7.1's bug and 0b's fix — is architecturally unreached by this fixture.

**BUT THE MEASUREMENT IS SUSPECT ON THREE COUNTS. Do not build on it before re-verifying.**

1. **26 is implausibly low.** `Start=StatemenT+` descending through
   `StatemenT`/`WardeD`/`ExpressioN`/`Token+` should produce hundreds of match attempts for a
   source file of any size, not 26.
2. **26 is precisely `oneTest`'s baseline answer** (`maximus = 26`) — the one number burned into
   every doc in this repo, and therefore exactly the number to double-check you were reading a
   counter and not a result.
3. **Decisive: `jsonTest` line 1 is `Start();`.** `Start` is a rule, so that is a rule invocation
   and `runRule` provably fired for it. It was reported as firing once, for `define`, never for
   `Start`. That is an arithmetic contradiction inside the data, not a matter of interpretation.

**Clay's predicted flip was ill-formed — corrected twice, note the lesson.** The first correction
claimed the Google-Fonts case sits behind an early `stop()` and never executes. That came from
`json.md` ("2 array tests → both ok, reaches stop()") and `jsonTest-googlefonts-probe.md` ("placed
after the file's first `stop()`"). **Both docs have drifted.** `incant/jsonTest` has exactly ONE
`stop()`, on the last line; all thirteen `testJSON` calls execute.

The actual reason no flip was possible is better: **Tony fixed the choke offline before vacation.**
His pre-vacation status report says he "revised the JSON grammar adding JSONblock as an option in
JSONtoken", and the current rules confirm `JSONtoken` now lists `JSONblock` first — precisely the
root cause `jsonTest`'s own 2026-07-02 comment block names for the array-of-objects failure. So the
case labelled `KNOWN TO FAIL` most likely passes **legitimately** now, and has since early July.
There was no masked failure left in it to unmask. `jsonTest`'s comment block is stale in the same
way and should be corrected.

*Lesson, and it is the doc-organisation thesis in miniature: reasoning from two dated docs instead
of from the live artifact, when the docs had moved on. For "what does this fixture do," read the
fixture.*

**Registry question — settled, the fold did NOT happen.** `incant/grammar` is `registry(Grokking)`,
ends at `Start=StatemenT+`, and contains **no JSON rules** (6,972 bytes, read in full).
`incant/utilities` opens with `register(Utilities)`. `incant/jsonTest` does `include(utilities)` and
`search reset stack Grokking UnitTests Utilities list`, then invokes `field = JSONblock(argument)`.
So the JSON rules live in the **Utilities** registry, reached through the search stack, and are
entered by *rule invocation*. Tony's recollection was that he would have folded them into Grokking
and run them under `Start`; the files say otherwise. Note both can be true and were being confused:
the *fixture* does run under `Start` (line 1), while the JSON *rules* were never folded.

**Two live hypotheses, not yet discriminated.**

1. *Mundane.* The JSON cases go through a driver the instrumentation did not cover.
   `RuleStuff::checkInput()`'s own header comment says it is *"Called by GroupItem match()"* — but
   the `parse()` we have calls `checkInput()` directly. Either that comment is stale or there is a
   **second entry path (`match()`, and possibly `matches()`, used by `testString`)** carrying work
   `parse()` instrumentation cannot see.
2. *Serious.* `aCTionRunRulE` (`ruleActions.rtn:869`) calls `input.clear()` then, on the isRule
   branch, `rule = runRule(argument,rule); return input;` — **discarding the parse result**
   (documented in TODO.md, 2026-06-06, "diagnosis done, fold pending"). If `JSONblock(...)` never
   actually invokes the rule, then whatever `testJSON` reports `ok`/`FAIL` from is not the parse
   outcome, and `json.md`'s "green end-to-end" may be measuring a harness that never ran the
   parser. That would explain silent success-on-failure **without any min bug at all** — an
   alternative to §7.1 that must be ruled out rather than assumed away.

**The discriminating probe.** Instrument **`checkInput()`**, not `parse()`. Every rule match must
pass through it regardless of which driver called it, so it is the chokepoint — the same
methodology `rstuff-chokepoint.md` established for rStuff. Print the rule tag. If `checkInput`
fires for JSON-family rules, hypothesis 1 holds and the question is only *which* driver. If it
never fires, hypothesis 2 holds and it is more consequential than anything else in this document.

**Decision needed from Tony.** TODO.md records the plan as folding the JSON rules from
`incant/utilities` into `incant/grammar` so JSON parses under `Start`, *rather than* fixing
`aCTionRunRulE`'s discarded return. Which of the two is wanted is his call, not Clod's.

**Effect on §9.** Step 2's POP is **not** blocked by this — the tree diff is black box (§6.5), so it
compares output trees without needing to know which driver produced them. Step 1 is unaffected.
What this does gate is any *claim about parity* on failing input.

### 7.6 tok macros do not support the shape §3 originally required

*Found by Clod 2026-07-25 while starting §9 step 1, before writing any real code. Reproduced three
times, minimal, tree verified back to the 0b state after each. Like §7.5 this belongs in its own
dated finding doc; recorded here because it forced the §3 rewrite.*

**The three observed failure modes.** A macro defined via tok's `#name(args)- ... -` facility:

1. **Nested in an expression** — silently does not expand. Emitted verbatim as a call to a function
   that does not exist, flagged only as "referenced but not declared" in a trailing comment. Fails
   later at the C++ compile step, not at tok.
2. **As a bare statement that is not the function's only statement** — tok segfaults, exit 139.
   Reproduced twice with different macro bodies, including one in plain tok syntax matching
   `testMacro`'s own style, so the GCC `({...})` extension was ruled out as the cause.
3. **`enterSeq(R)` followed by `return leaveRule(...)`** — the exact two-line shape every method in
   the original §5.1 used. No crash, but the `enterSeq` statement was dropped entirely, its locals
   pruned with bear-trap #13's "Declarations ignored because not used" warning, and `leaveRule` left
   unexpanded as in mode 1. Neither macro fired.

**Mode 1 is not a tok defect — it is a design error in §3.** `testMacro` expands to a block that
declares locals and executes `return`. A statement can never be a term in `lit("{") && many(...)`.
No fix to tok changes that. §3 as originally specified was wrong on its own terms, independent of
anything else here.

**Mode 2 is overstated, and there is a live counterexample.** The reported rule was "only works when
the invocation is the entire sole body." From `RuleStuff.twk`, in the build:

    extern int testSet(GroupItem field)
    {
    use field
    PLGset  set = characterSet;
    testMacro(set.contains(*atRuleMark));
    }

A declaration precedes the macro call and it works. So the real constraint is narrower. Three
candidates, two of which would mean tok is fine:

- **Semicolon.** Every working invocation is `testMacro(...);` with a terminating semicolon. The
  original §5.1 wrote `enterSeq(JSONblock)` with none. If the template was transcribed literally,
  mode 3's silent drop is what an unterminatable construct would produce. *This one is Clay's error,
  not tok's.*
- **Position.** All three working invocations sit at column 0 — declaration position under tok's
  convention, where declarations are unindented and statements indented four. If macros expand
  during declaration parsing, "works at column 0, fails indented" explains modes 2 and 3 with no bug.
- **`use`.** All three working sites have `use field` first. `testMacro`'s body references bare
  `isOK`/`max`/`min`/`noAdvance`/`label`/`hereAt`, which resolve only through the enclosing `use`.
  Without it, resolution inside the expansion has nothing to bind to — a plausible route to a
  tok-side crash.

**Bear trap regardless of outcome:** tok exiting 139 with no diagnostic is worth recording with the
minimal repro whichever candidate proves responsible.

**Resolution.** §3 rewritten around ordinary functions; genParse uses no macro facility at all. The
forced change is an improvement rather than a workaround — it removes implicit shared state between
macros and the redeclaration collision from invoking one twice in a function, and it makes `many`'s
per-term specialisation explicit (§3.3).

---

## 8. Open items

None of these block §9 step 1.

| item | what's needed |
|---|---|
| `!` / banged | semantics. Negation of what — the term, or the guard? |
| `%` / isPercent | semantics unknown |
| `fail` prefix | recovery behaviour. Touches `notifyFail`/`onFail`, lands in `leaveRule` |
| position-zero cycles | a generate-time cycle check. JSON is safe (`JSONblock` consumes `{` before descending) but a general genParse needs the check |
| §7.2 asymmetry | **resolved and landed** — `7b84748` |
| §7.1 min-zeroing | **fix landed (0b), unfalsified.** Needs the malformed-input probe in §7.1 |
| **`Limit` is broken upstream of `setLimits`** | see below — and note it makes §2.2a's mark clause **unreachable through the grammar**, not merely latent |

### 8.1 The `Limit` defect — measured 2026-07-28

`Limit '['- min=[0-9]+ max?=[0-9]+ ']'-` does not deliver a limit to the rule, in two distinct
ways, neither of them in `setLimits` itself:

- **`X[2]` is rejected outright** — `ERROR Operator - failed on isRule and Token`. The grammar says
  `max?` is optional, so a single-value limit should parse.
- **`X[2 9]` parses and is silently ignored** — it prints `nextGroup: ERROR max does not contain a
  list` (non-fatal, the run continues) and the term's `min`/`max` are left at **1/1**.

`setLimits` reads correctly (`ruleStuff.min = minimum.count; if maximum ruleStuff.max =
maximum.count;`), so the fault is in its **caller or in the `Limit` rule's own parse**, upstream of
it. Nobody has looked at it.

**Consequence for §2.2a.** The mark clause of Invariant R′ is only observable at `min >= 2`, and
`min >= 2` cannot currently be written. §2.2's wording — "latent until someone writes `X[2]`" —
understates it: writing `X[2]` does not work. Until this is fixed, R′'s mark clause can only be
demonstrated by controlled comparison (`demoRprime`, `genParse.rtn`), never by a ladder rule.

| §7.5 JSON route | re-verify the instrumentation first (three reasons to distrust it), then the `checkInput` chokepoint probe |
| §7.6 tok macros | **routed around** — §3 uses no macros. Which candidate actually breaks expansion is now a tok question |
| grammar file drift | `TraiT NamE Modifier* Limit? TraiTdata?;` should read `NamE@` per `aCTionTraiT`'s comment, which is reality. `TraiTlist` appears in that comment but not the grammar and does not exist — drop it from the comment |
| `jsonTest` comment drift | its 2026-07-02 block still says `JSONtoken` lacks `JSONblock` and calls the fix "NOT done here". Both untrue since Tony's offline pass; the `KNOWN TO FAIL` label is probably wrong now |
| `data` enum ordering | **resolved and dispensed with** — see §2.5, §5.2 |

---

## 9. Build order

Staged so that the correctness target is proven before the generator exists.

**Step 0 — settle the parity target.** Two discrete commits, in this order, each with its own
baseline check:

- **0a.** Land §7.2's one-liner (group reference fails like an attribute fails). Baseline should
  hold unchanged — its effect is masked while §7.1 is live, which is exactly why it goes first.
  **Done, `7b84748`, baseline held.**
- **0b.** Fix §7.1's propagation, gated on every attribute being individually optional.
  Implemented, committed `8e3c118`, baseline byte-identical — and **FALSIFIED 2026-07-27**. The
  predicted `ok`→`FAIL` flip does not occur; JSONblock still returns non-null for `'{'`.
  **Correction to the probe recorded here:** `testJSON('{');` *twice in a row* discriminates
  nothing — §7.1's own memoization story predicts a first-call FAIL under both hypotheses, so both
  calls are arming calls and the second never reads. The working fixture inverts the order —
  well-formed to arm, malformed to read, nothing after — in ONE process, since memoization is
  per-process. See §7.1 for the run and for the vacuous-truth conjecture on why 0b is inert.

**Step 1 — hand-write the support library** (§3). No generator, and no tok macros (§7.6). Ordinary
C++ functions: `lit`, `litTo`, `inGuard`, `leaveRule`, `leaveAlt`, plus the skip pass. This is where
every `if` in the system ends up, so it gets written once and read carefully. `testMacro` is still
the model for the *shape* — one shared body, many one-line users — just not for the mechanism.

**Step 2 — hand-write the seven JSONblock methods** (§5.1) using that library, plus the
`runJSONblock` entry wrapper (§5.3). POP: the black-box tree diff of §6.5 — `json1` for the generic
path's tree, `runJSONblock` for the generated one, diff `printDefinition` output on **passing**
cases. Green means the scheme is sound, which is worth knowing before a line of genParse exists.

**Step 3 — write genParse to emit exactly those seven methods.** The POP is a *diff against the
hand-written file from step 2.* A generator whose output matches code a human wrote and proved is
a generator you can trust on rules nobody has inspected.

**Step 4 — turn it on the incant grammar's own rules.** Expect the modifier fold (§4.3) to be
where the work is; the grammar uses stacked modifiers freely (`nameSet-^*`, `quoteBody}=tik$@`)
and JSON exercises almost none of them.

**Step 5 — instrumentation** (§6), once there is something to compare.

Deliberately not in this list: the jit target. genParse emitting kant instead of C++ is a change
of emission, not of design, and it waits on the JIT ladder in `docs/jitDesign.md` Part VI. It is also the
best argument for that ladder — a generated parse is a real workload rather than a synthetic POP.

---

## 10. Banked, not now

- Guard sets → switch/jump-table dispatch for alternations
- Transparent-wrapper inlining (§6.4)
- Direct range comparison instead of `PLGset::contains` for simple sets (§5.2)
- `kount >= minK` elision where min is 0 or 1 (§5.2)
- The iterator (`iterate grup on source`) as a language-level primitive — `many…` helpers are
  hand-rolled list walks, and the codebase has seven-plus more of the same shape
- kant emission for the jit target
