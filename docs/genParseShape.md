# genParse — Method Shape (design ruling + implementation brief)

```
KIND:       design ruling + implementation brief
STATUS:     live
DATE:       2026-07-28
SEQ:        clay-to-clod 25
REVISES:    genParseRuleAccess.md §1.1, §1.4 (signature); genParseSpec §4.1,
            §5.1, §5.3 (emitted shape, entry wrapper); genParseSpec §2.6
            (direct calls → through the fork)
ANSWERS:    What shape does a generated parse method have, now that it has to
            be a kant method?
AUTHORITY:  Tony, this session. Every ruling below is his.
READ-WITH:  genParseRuleAccess.md — the brief this revises
            genParseSpec §2.4 (label-transparent alternations), §2.5
            (expression vs statement), §7.4 (shape vs frame)
ORDER:      this brief BEFORE rung 3's walk/emission seam split — the seam
            hardens the emission layer around these signatures
```

---

## 0. Read this first — nothing is being ignored

The parse issues are sequenced, not set aside. Two reasons:

The emitted text is exactly what gets rewritten when the target becomes kant. Shape
decisions carry over whole; fixes to the current C++ path may not carry at all. Doing
shape first is doing the transferable work first.

And §7.5's discard is **located but unfixed**. Until it is fixed, no test on failing
input reads honestly — a generated method that fails correctly still prints `ok`. So
fixing it is *on the path to a working POP*, not deferred behind one. It comes up the
moment there is something to test.

Your findings are what settled three of today's rulings, all read off the tree rather
than off the design: `setRStuff` assigns rather than copies; `rule[n]` is one list, not
two; the `fLAG` handshake lives in `checkInput`'s label block. The structural/causal
split from the seal held again — every structural claim survived contact, and the one
causal claim in this brief is marked as such.

---

## 1. Rulings

### 1.1 One argument, and it is the rule

```
extern GroupItem parseX(GroupItem rule)
```

Kant methods take one argument — `genParse(argument)`, `testSet(field)`, rule actions
taking only the label. A two-argument parse method could never survive the kant
handover. This retires the `(GroupItem, GroupItem)` fnptr shape from step 1; the member
becomes `GroupItem &parseMethod(GroupItem)`.

Note the irony, worth banking beside bear-trap #20's: the fnptr turned a convention into
a compiler-enforced type, and enforced a shape the target language cannot express. Same
lesson as step 4, one layer down.

**This is a layout change.** `groups.ext` sync, `tokall`, rebuild, baseline re-verify.
Bear-trap #10's full apparatus; canary `grep -c extern GroupRules.h` = 161.

### 1.2 `into` is derived, not passed

New `RuleStuff` field `parentLabel`. Caller writes it on the callee's rule immediately
before calling; callee lifts it into a stack local at entry, before descending.

This is not new state — `parse()` already reaches the same value through `parentStuff`
in its attachment block. It makes an existing two-hop derivation direct and named.

The label route was considered and is dead: `setRStuff` **assigns**, so `label.rStuff`
aliases the rule's RuleStuff and carries no per-invocation isolation. Two further reasons
it could not have worked: an alternation builds no label at all (§2.4) yet is the fold
that most needs `into`; and a sequence's callee cannot read `parentLabel` off a label it
has not created yet.

Capture-at-entry closes the recursion window — the same reasoning as genParseRuleAccess
§1.5's `act()`, where setting at the boundary rather than at entry is what closes it.

### 1.3 No `locate` anywhere

Neither in the emitter nor in emitted text. The rule arrives as the argument. Two runtime
name lookups per invocation currently exist where the design specified zero, and name
resolution through the search stack is §5.3's three-silent-failure-modes class.

### 1.4 Terms are frame locals; primitives take the term

```
GroupItem   t1 = rule[1];
GroupItem   t2 = rule[2];
```

Indices baked at generate time. Leaves become `lit(t1,"{")`, not `lit(rule,"{")`. This
restores the `testSet(GroupItem field)` convention — `field` means term, `rule` means
rule — and gives every leaf frame its own identity. Under the current shape a breakpoint
in `lit` during `parseJSONfield` cannot distinguish the `":"` match from the `","`, which
is the question a debugger frame usually needs answered.

### 1.5 genParse traverses with the accessor the emitted code uses

Replace `while term = rule.nextAttribute(term)` with an indexed walk over `rule[i]`,
classifying each entry as it goes.

Reason: the emitter currently builds terms with one traversal and the emitted code will
read them with another. They agree only if the list holds exactly the attributes in
exactly that order. Any entry `nextAttribute` skips shifts every subsequent index —
silently, and with a term local bound to the wrong term, which the currently-unused
`field` parameter would not even misbehave on. Same accessor makes the correspondence
hold by construction. Tony's ruling stands that genParse may read in the order it
expects; this makes that safe rather than merely likely.

### 1.6 `parseR` owns set-then-call, and routes through `parse()`

```
parseR(t2,label)  →  t2.onGroup.parentLabel = label;
                     parse the referenced rule — via parse(), letting the fork decide
```

The write cannot be emitted into the `&&` chain — an assignment is not a term (§2.5's
expression-vs-statement problem in a new place). One primitive keeps emitted text a pure
boolean expression, and gives the fork a single natural home. No name lookup: the term
knows its `onGroup`.

**Through the fork, not direct** (revises §2.6). Generation is per-rule, so a generated
rule can call an interpretive one and vice versa. Mixed mode is free, conversion is
order-independent, and the interpretive walk stays the oracle for everything not yet
converted. Cost: an indirect call is opaque to LLVM's inliner. Not a correctness cost,
and reversible later inside `parseR` alone — no emitted file regenerates.

### 1.7 No entry wrapper

`runScaf`/`runScaf2` retire; §5.3's `runJSONblock` is not emitted. Invocation is
`Scaf()`, exactly as `Start()`. This exercises emission, the fork, binding, and dispatch
— a bespoke wrapper exercises none of them.

### 1.8 Instrumentation lives in the library, gated

HIT/WIN per §6.1, and Invariant R checking beside it — `leaveRule` holds `from` and
`atRuleMark` at exactly the moment the question is asked. One implementation, every rule,
no emitted lines, survives the kant handover.

This is what replaces `runScaf`'s R-inner/R-outer prints, which were the one thing that
harness was good for: `Scaf()` alone cannot show you R, because R is a property of the
failure path.

### 1.9 `fLAG` is CLOSED, not open — no grep needed

genParseRuleAccess §3 asked for a `grep fLAG` before §1.6's always-fresh-labels could
land. **Tony's ruling: the question does not arise. Generated code does not reuse
labels, so nothing in the generated path can care what `fLAG` says.**

Recorded because the mechanism is now understood and should not be re-derived: `fLAG` is
the label-recycling handshake. `checkInput`'s label block is the reader
(`else label.fLAG = false`, the fill-in-place branch), and the writer is `parse()`'s
`isGROUP && max > 1` recycling path — which Invariant R′ already forbids generated code
from reproducing. Generated code has neither half. Item retired.

---

## 2. Emitted shape

```
extern GroupItem parseScaf2(GroupItem rule)
{
GroupItem   into  = rule.parentLabel;
GroupItem   label = new("Scaf2");
GroupItem   t1 = rule[1];
GroupItem   t2 = rule[2];
String      from  = atRuleMark;
    return leaveRule(rule,into,label,from, lit(t1,"{") && lit(t2,"}") );
}
```

---

## 3. Implementation order

1. **`RuleStuff.parentLabel`** — additive field, nothing reads it. Layout change:
   `groups.ext`, `tokall`, rebuild, baseline. Commit alone.
2. **fnptr to one argument** — `GroupItem &parseMethod(GroupItem)`. Layout change again;
   pay it with step 1 if you prefer one rebuild.
3. **Support library to term-first** — the `field` parameter becomes the term at every
   call site. Signatures otherwise unchanged.
4. **`parseR`** — set-then-call, routing through `parse()`. New primitive, needs a
   `groups.ext` decl.
5. **genParse: indexed traversal** (§1.5), then **emission** (§2) — one-arg signature,
   `parentLabel` capture, term locals, term-first leaves, no `locate`.
6. **Binding** — see §4.1, open.
7. **Regenerate `genLadder/rung12.target`** deliberately, as a recorded change. Every
   line of the frame moves; the diff is large and expected.
8. **Baselines byte-identical** after each step: `oneTest` → 11 then 26 ×4, `jsonTest` →
   14 `ok`, **exit 0 on both**. A POP is not passed unless the process exited 0.

---

## 4. Open — and 4.1 gates the POP

### 4.1 What binds a compiled `parseScaf` to `Scaf.rStuff.parseMethod`?

Unresolved, and `Scaf()` cannot reach generated code without it. In the kant world it is
trivial — ORC-compile, store the handle. In the C++-first world something at load time
must connect a symbol compiled into the binary to a rule GroupItem.

Candidate, **unconfirmed**: the `setRuleAction` path, registered in `incant/setup` in the
`=value` form — `Scaf parseMethod=parseScaf;`. If that route is taken, §5.3's three
silent-failure modes all apply and converge on one indistinguishable symptom. Yours to
determine; it is a tree question, not a design one.

### 4.2 `leaveAlt` keeps `from` for now — knowingly conservative

It is only needed if a failing option can leave the mark moved. `lit` currently commits
the skip pass to `atRuleMark` before matching, so **a failing `lit` returns false with the
mark advanced** — meaning §3.1's claim that `leaveRule`/`leaveAlt` are the sole
implementation of R is not true as the tree stands. Benign today, since all options skip
the same whitespace. Making the skip pass non-destructive (compute into `atText`, commit
on success) would let `leaveAlt` drop to `(rule, ok)`. Sequenced as a fix, after shape.

### 4.3 End-of-input normalization

Beside `checkSkip`, not in it, at the head of each primitive that reads `atRuleMark`.
Skip is *advance over input we don't want*; this is *make sure there is input at all*.
Two functions, one call site, only the second pops. No emitted lines.

Also a fix, also after shape.

**Marked causal, therefore suspect:** the claim that the pop-on-exhaustion in
`matchFailed` is what produces the observed read-through into script text is an
attribution, and attributions have been the failing half. The structural half — that the
existing guard answers *can we pop* and never *should we* — is read off the source. Cheap
discriminator: a print at the pop site during the malformed `'{'` case.

### 4.4 `fail`, `!`, `%`

§8, unchanged. Not needed for the JSON family; needed before turning this on the incant
grammar.

---

## 5. Testing plan — Tony's

Components before containers, with one wrinkle: **the JSON family is cyclic**
(`JSONblock → JSONfield → JSONtoken → JSONblock`), so there is no topological order
within it.

Two ways through, and §1.6's ruling gives you the second for free. Order by *input*
rather than by rule — `JSONtoken` on `"false"` never descends into `JSONblock`, so the
back-edge stays unexercised and the rule is testable in isolation. Or convert one rule at
a time in any order and let the fork route everything unconverted to the interpretive
walk. The second is the mode genParseRuleAccess §1.3 called climbing inside a working
system, and it is why through-the-fork was chosen.

— Clay, 2026-07-28
