# genParse — Rung 3, the walk/emission seam (design ruling + implementation brief)

```
KIND:       design ruling + implementation brief
STATUS:     live
DATE:       2026-07-28
SEQ:        clay-to-clod 26
FOLLOWS:    genParseShape.md (SEQ 25) — rung 4 green at ec34f59
REVISES:    genParseSpec §4.1 (walk emits text → walk builds a plan);
            §4.2 pending measurement, see §1
ANSWERS:    What separates deciding-what-a-rule-means from writing-it-out,
            and what crosses the line?
AUTHORITY:  Tony, this session.
GOAL:       rung 3 — the seam. No grammar feature is added. Nothing new is
            proven; something existing must survive.
```

---

## 0. Why now, and what the POP is

Rung 3 is the only rung that adds no grammar, and the only one whose POP already exists:

- `rung12.target` and `rung4.target` diff **empty**
- `oneTest` → 11 then 26 ×4; `jsonTest` → 14 `ok`; both **exit 0**
- emitted text still byte-identical to the compiled-in source

That safety net is why this rung is cheap today and expensive later. Right now it is three
targets and two folds. At rung 9 it is nine targets and the whole §4.3 modifier cross-product.

The reason the seam exists at all is the kant handover. Today's emitter decides *and* writes in
one pass, so the whole function gets rewritten for kant — including the classification, which has
nothing to do with the target language. Split it and the walk is written once.

---

## 1. Measure before designing — §4.2's table against the tree

genParseSpec §1.1 calls "the leaf emitter is `setTestMatch()` with the assignment replaced by a
text emission" the single strongest reason to believe genParse is a small job. Your rung-4 finding
dents it: **no reference term is `isGROUP` or has `onGroup` set, ever.** But §4.1's walk contains
`if rule.onGroup`, and §4.2's leaf table has an `isGROUP` row. Spec and tree disagree, on the case
that matters most.

Rung 3 is exactly where classification gets consolidated into one place, so find out how far the
disagreement runs **before** designing the walk. `termScratch` again: for a real rule, print each
term's `data`, `testMatch`, and modifier fields, and record which §4.2 rows actually occur.

- One row wrong → fix the row.
- Several rows wrong → the walk is a **fresh classifier written against the tree**, not a
  transcription of `setTestMatch()`, and rung 3 is a bigger rung than it looks. Say so before
  building.

Measuring beat reasoning twice this week, both times yours. Same move here.

---

## 2. Ruling — the seam artifact is a PLAN, and the plan is GroupItems

The walk produces a plan tree: resolved decisions, baked literals, **no target syntax anywhere**.
Emitters consume it.

Reasons, specific to this tree rather than general taste:

- **It is the bytecode move one level up.** Bytecode instructions are GroupItems; so is this. The
  structure is free — `new(tag)`, `+%`, attributes for baked literals — and `printDefinition`
  gives plan-printing for nothing.
- **A plan diff is target-independent.** `Scaf2`'s plan is identical whether the emitter writes
  C++ or kant. A rung POP can assert the *decision* rather than the *text*; text diffs break when
  the emitter changes, plan diffs do not.
- **It is where generate-time refusals belong.** §2.8's tail-position-only, §1.5's term count, and
  eventually §8's `!`/`%` are validity questions about the plan. Validate once, every emitter
  inherits it. Interleaved, a kant emitter re-implements the refusals and gets one wrong.
- **Helpers need a tree regardless.** §3.3 emits `manyRTerm`/accumulator functions alongside the
  body. The walk discovers a helper mid-stream while text would already be going out — with a
  visitor you buffer or you emit out of order; with a plan you walk it twice. That gets ugly at
  rung 5 specifically, which is the next rung.
- **It is the road to no text at all.** §1.2's endgame — emit kant, ORC-compile the buffer,
  nothing on disk. Plan → IR drops the buffer too.

**The cost, stated so it is not a surprise:** a second representation means a bug can now live in
the walk, the plan, or the emitter. The mitigation is that a plan is printable and an intermediate
visitor state is not — a wrong plan is visible.

---

## 3. Build ONLY the vocabulary the current rungs need

**Five node kinds. That is the whole vocabulary for rungs 1, 2 and 4:**

| kind | carries |
|---|---|
| `SEQ` | rule tag, label, ordered conjuncts |
| `ALT` | rule tag, ordered disjuncts, no label |
| `LIT` | literal text (noLabel) |
| `LITTO` | literal text + slot |
| `CALL` | the term to parse through |

At that size the plan version is the same work as a visitor. The vocabulary grows **one kind at a
time, as a rung demands it** — `MANY` with rung 5, `GUARD` with the alternation rung, `ACT` when
actions land.

**Anti-goal, and the tell that this rung has gone wrong:** designing all fifteen kinds now against
grammar features not yet on the ladder. That is speculative design and it is what the ladder
exists to prevent. If the vocabulary comes back complete, it is too big.

---

## 4. What sits on each side

**Walk side** — everything about the rule, nothing about the target:

- fold selection (§4.1: `isRule && hasMembers && !binType` → ALT, else SEQ)
- the `noPrint` gate and `countRuleTerms` — single implementer, already shared with the binder
- term classification (§4.2, as corrected by §1 above)
- the §4.3 modifier fold, both axes — it produces *resolved decisions*, which is what a plan node is
- baking literals: guard sets, min/max, slot names
- **plan validation and refusal** — §2.8 tail position, §1.5 term count

**Emitter side** — everything about the target, nothing about the rule:

- the frame preamble (kant's differs from C++'s, so it cannot be walk-side)
- joining conjuncts with `&&`, disjuncts with `||`
- helper placement in the output file
- quoting, escaping, the `char dq = 34` idiom

**Diagnostics ride the walk.** A refusal is about the rule and should read the same whichever
emitter is downstream.

---

## 5. Order

1. **Measure (§1).** Report before designing.
2. **Plan vocabulary, five kinds.** Plan nodes constructed, nothing consuming them yet.
3. **Walk builds plans.** Existing emission still live and unchanged — the plan is built and
   discarded. Baselines must be untouched; this step is a no-op by construction.
4. **Emitter consumes the plan.** Old path deleted in the same commit, not before.
5. **Verify:** `rung12.target` and `rung4.target` diff empty, `oneTest`/`jsonTest` byte-identical,
   exit 0, emitted text byte-identical to compiled-in source.
6. **Print the plans** for `Scaf`, `Scaf2`, `ScafB` into the seal beside the emitted text (§6).

Step 3 landing as a provable no-op is the point of splitting it from step 4 — if a baseline moves
at step 3, the walk changed something it should not have.

---

## 6. Also in the seal

The printed plan for `Scaf`, `Scaf2`, `ScafB`. Costs nothing, and it is the first artifact in this
project that a C++ emitter and a kant emitter would both have to agree on. Worth having a record
of what it looked like the day it was introduced.

---

## 7. Parked — not this rung

- `jitEmitUnary←opPlusPlus` on `jitInc`. Pre-existing, frames recorded, JIT-ladder work.
- LLVM IR in the JITDylib for inlining. Real, and it decides whether jitted parse methods beat
  compiled C++ or merely match it — but it belongs with JIT-ladder work, not here. One sizing
  question when that time comes: does the ORC v2 setup take modules, or only resolve symbols
  against the host process?
- §4.2's `lit` skip-pass commit (genParseShape §4.2) and end-of-input normalization
  (genParseShape §4.3). Both fixes, both after shape.

— Clay, 2026-07-28
