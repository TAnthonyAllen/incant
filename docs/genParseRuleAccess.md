# genParse — Rule Access & Parse-in-rStuff (design delta + Clod pickup)

```
KIND:       design delta + implementation brief
STATUS:     live
DATE:       2026-07-27
COMPANION:  genParseSpec.md — revises the support-library signatures (§4.2/§5),
            settles the §9-Step-3 rung-10 layer question
            genParseLadder.md — lands BEFORE rung 3's seam split
ANSWERS:    How does a generated parse method know which rule it is parsing,
            and where does the generated method itself live?
READ-WITH:  genParseSpec §2.9 (parse dispatch), §7.4 (shape vs state),
            §4.2 (leaf emitter)
ORDER:      this brief FIRST, then rung 3's walk/emission seam split.
            The seam hardens the emission layer around these signatures.
OPEN:       grep fLAG (below); the bare-ref-to-alternation retag ruling
            (still Tony's, unchanged)
```

---

## 1. Decisions

### 1.1 Rule as first parameter on every generated support call

Every support primitive a generated method calls takes the rule GroupItem
first:

```
leaveRule(field, into, label, from, ok)
leaveAlt (field, from, ok)
lit      (field, ...)
litTo    (field, ...)
parseR   (field, ...)
promoteR (field, ...)
act      (field, label)
```

Buys: a rule to inspect in every Xcode frame (the motivating reason); §6
instrumentation gets rule identity for free; parse failures can name the rule
that failed; and it works when `label == 0`, which is exactly the alternation
case (`isRule && hasMembers && !binType` → no label).

Costs one pointer per call and no runtime lookup — genParse knows the rule
statically at emit time and bakes the reference in.

### 1.2 The generated parse lives in `rStuff`, not `rule.method`

`rStuff.parseMethod` holds the generated parse. `rule.method` is left alone and
keeps the rule action.

Consequences, all of them wanted:

- **Idempotent generation.** Nothing genParse reads is clobbered by what
  genParse writes, so it can be re-run on the same rule any number of times —
  which is the whole working mode of climbing the ladder.
- **Correctly typed** per §7.4: the generated parse is *shape* — one per rule,
  immutable once generated. That is what `rStuff` is for.
- **No externs, no `cOMMANDs` registration.** The method is reached through the
  rule, not through a name in a table. This retires the invocation-blocker class
  for generated parses (three recurrences to date).

### 1.3 `parse()` forks on `rStuff.parseMethod`

```
rStuff.parseMethod set  → call it
otherwise               → existing interpretive walk
```

A trivial change to `GroupItem parse`, and a **no-op until something is
generated**, which makes it safe to land early: with no rule carrying a
generated parse, every path is the old path and the baseline must be unchanged.

It also gives incremental migration with a safety net — `Scaf` can run generated
while everything else stays interpretive. The ladder then climbs *inside* a
working system instead of requiring all seven JSON methods to land at once.

### 1.4 Dispatch supplies the rule

Because dispatch goes *through* the rule, the dispatcher already holds the rule
GroupItem and passes it in. No lookup, no hoisted static, no resolution problem.

This forces **signature uniformity**: every generated parse shares one shape so
the dispatcher can call any of them blind.

```
int parseX(GroupItem field, GroupItem into)
```

### 1.5 `act(field, label)` owns `ruleSTUFF`

```
act(field, label)  →  ruleSTUFF = field.rStuff
                      label     = field.method(label)
```

Set immediately before the action fires — *after* all descent has returned.

Rule actions keep their present signature (label only); `ruleActions.rtn` is not
migrated. `ruleSTUFF` remains how an action learns which rule it is working on —
we are fixing its **scoping**, not removing it.

`ruleSTUFF` is a global and mutual recursion clobbers it. Setting it at method
entry means a nested call overwrites it before the outer action fires. Setting
it at the `act` boundary closes that window.

**Hypothesis, not yet confirmed:** this is the open JSON bug. `parseJSONfield`
sets `ruleSTUFF`, descends into `parseJSONvalue` which overwrites it, returns,
and runs its action against the wrong rule. It fits the symptom — nesting is the
trigger, which is why `Scaf` (no nesting) is green and `parseJSONfield` is not.
Confirm in the walk: when JSONfield's action fires, is `ruleSTUFF` still
JSONfield's?

**This settles rung 10.** The fix lives in `act()` — the support library — so
the emitted method emits nothing new and the target shape is settled.

### 1.6 Labels always fresh

Generated methods construct a new label every time. No reuse, no `clear()`; GC
handles the cleanup, and dropping `clear()` roughly offsets the allocation.

The emitted frame already worked this way — it builds its own `label` locally
and attaches with `into +% label` in `leaveRule`. This makes that explicit and
removes a conditional from the emission layer.

Discipline this depends on: **callers use the returned label**, never assuming
the one they passed was filled in place. `parse()` already does exactly that
(`label = method(label)`, §2.9).

Tree-diff safe: a fresh label and a reused one produce structurally identical
output, so the top-of-ladder POP against the interpretive walk is unaffected.

### 1.7 `label.rStuff` is unchanged

It stays exactly as it is, answering the question it was added to answer:
**which rule built this label.** First-writer-wins is deliberate — a label keeps
its maker's mark even after a caller retags it.

The *executing* rule is a different question and does not route through it. That
is the explicit parameter of §1.1. The two normally agree for a sequence rule;
where they diverge, the divergence is informative.

---

## 2. Why this sets up the kant handover

Tony asked for this to be explicit.

Every decision above moves logic **out of emitted text and into the support
library**. The emitted text is precisely what must be reimplemented when the
target becomes kant — so a smaller, plainer emission is a smaller port.

- **§1.1 rule-first** is a *calling convention*, not C++ syntax. Kant
  reimplements the primitives against the same convention; the walk does not
  change.
- **§1.2 parse-in-rStuff** is the endgame arriving early. No externs, no
  registration, no name in any table — the method is reached through the rule.
  At JIT, the compiled code is just a pointer in `rStuff`: emit kant,
  ORC-compile the buffer, store the handle, nothing on disk. That is the "done
  done done, no file hanging around" this project was aiming at.
- **§1.5 `act()` owning `ruleSTUFF`** keeps the emitted tail to a single call.
- **§1.6 always-fresh labels** removes a conditional from the emission layer.

---

## 3. Implementation order

Land in this order, each step verified before the next. This whole brief
precedes rung 3's seam split.

1. **`parse()` fork** (§1.3), alone and first. Riskiest edit — it touches core
   dispatch. Verify the baseline is *unchanged*: `oneTest` → 11/26, `jsonTest`
   byte-identical. With no generated parse anywhere yet, this must be a no-op.
   Commit on its own.
2. **Support-library signatures** (§1.1) — rule-first across `leaveRule`,
   `leaveAlt`, `lit`, `litTo`, and any other primitive in the generated path.
3. **`act(field, label)`** (§1.5) — and check whether it alone closes the JSON
   bug. If it does, say so loudly; that retires a thread that has been open
   since before the break.
4. **genParse emission** — emit the rule reference as the first argument at every
   call site; store the generated method into `rStuff.parseMethod`.
5. **Regenerate the rung 1–2 POP targets.** `genLadder/rung12.target` carries the
   old signatures and will fail the text-diff by design. Update it deliberately,
   as a recorded change, not as a fix-until-green.
6. **Re-verify the runnable floor:** `runScaf('x')` parses, `runScaf('y')` fails,
   mark unmoved (Invariant R).
7. **Then** rung 3's seam split.

Also, one line, whenever convenient: **`grep fLAG`** across the tree. Expected
answer is that only `checkInput` touches it, in which case §1.6 is trivially
safe. If something else sets `fLAG = true` before handing a label down, that
caller expects fill-in-place and needs a look before §1.6 lands. Tony's
assessment is that he uses it knowingly and rarely; this is confirmation, not
suspicion.

---

## 4. POP — Tony's acceptance test

**Tony reads every method in the genParse path and satisfies himself that the
rule is reachable from each one.**

Deliverable:

1. The emitted `parseScaf` text, printed for review.
2. The source of every support primitive it calls, with the rule-first
   signature visible.
3. A run where Tony can breakpoint in each of those methods, with `field` live
   and correctly populated in every frame.

Green means: the emitted text and the support library are both readable, and at
any breakpoint in the path there is a rule GroupItem in the frame that can be
inspected — no dereference chain to walk, no reconstruction from `into` and
`label`.

Secondary, mechanical: rungs 1–2 text-diff green against the regenerated
targets; runnable floor still green with Invariant R holding.

---

## 5. Carried forward, unchanged

- **`runScaf2` never dispatches.** Symbol live, codegen structurally identical
  to `runScaf`, `=value` single-entry form. Narrowed, not root-caused; stopped
  at the two-failure line. Note §1.2 makes this class less likely to recur for
  *generated* parses, since they are no longer reached by name.
- **The retag ruling** (bare reference to an alternation: auto-promote, or
  require explicit `@`?) — still Tony's, still gating rung 9.
- **Bear-trap #18** is banked on an unconfirmed cause (§7.6 lists three
  candidates and one of them is Clay's own error). Pending Tony's sign-off
  before it hardens into doctrine.

— Clay, 2026-07-27
