# The jitEmitter slot migration — step 2's own doc

**Opened 2026-08-17.** The campaign that moves each operator's JIT emission out of an
`if jitting` gate buried in its interpreter body and onto a **slot the op node carries**.

This file is the citation. When the sweep closes, the obligations below are meant to be **read**,
not re-derived.

---

## THE MECHANISM, as built

| piece | where |
|---|---|
| the slot | `GroupBody.gJitEmitter`, aliased `jitEmitter` — **beside** the `gMethod`/`gOp` union |
| the setter | `GroupItem::setJitEmitter(void*)`, hand-cast like `setOperat` |
| the binder | `jitEmitter=` definition attribute → `jitEmitter()` in `GroupActions.rtn`, booted in `GroupMain.twk` |
| the fork | inside `runOP`'s **existing** seed gate, `GroupActions.rtn` |
| the counter | `gJitSlotCount` (`jitContext.h`), incremented **at the fork**, printed by `jitRunAction` |

**Beside the union, never inside it.** An op must carry its interpreter binding *and* its emitter at
once; a union would make installing one destroy the other.

**The slot sets no flag.** `isOperator`/`isMethod` say how the *interpreter* dispatches. Presence of
the slot is the only migration signal, which is what lets the fork be a null test.

⚠ **There is no default emitter and there must never be one.** A `jitCantEmit` delegating to
`operat` would make every unmigrated op look migrated, at degrade count zero. **The null slot IS the
refusal.**

---

## THE LEDGER

| # | op | family | shim | rung | landed |
|---|---|---|---|---|---|
| 1 | `*` | `jitOp` | `jitEmitMul` | `incant/jitSlotT` (ladder **JM1**) | 2026-08-17 |
| 2 | `>` | `jitCmp` | `jitEmitGT` | `incant/jitSlotT2` (ladder **JM2**) | 2026-08-17 |
| 3 | `>=` | `jitCmp` | `jitEmitGE` | `incant/jitSlotT3` (ladder **JM3**) | 2026-08-17 |
| 4 | `<` | `jitCmp` | `jitEmitLT` | `incant/jitSlotT3` | 2026-08-17 |
| 5 | `<=` | `jitCmp` | `jitEmitLE` | `incant/jitSlotT3` | 2026-08-17 |
| 6 | `==` | `jitCmp` | `jitEmitEQ` | `incant/jitSlotT3` | 2026-08-17 |

**Batch 1 (ops 3-6) landed together**, four shims of three lines each. The **ordered half of
`jitCmp` is now complete**.

### The eligible population, censused 2026-08-17

**16** one-line-return jit gates in `Instruct.rtn`. **10** are strict binary/comparison
`(argument,target,selector)` shape — the sweep-eligible set. **6 migrated, 2 remain:**

| remaining | selector |
|---|---|
| `!=` | `jitNE` |
| `+` `-` `/` | `jitAdd` `jitSub` `jitSDiv` |

*(That is 4 remaining, not 2 — `!=` plus the three arithmetic. Batch 2's natural shape.)*

**The other 6 are correctly out of scope**, and the reason is shape rather than preference:
`jitEmitDot` and `jitEmitRem` take a **third** argument (`ruler->tempField`), so they do not fit a
two-argument slot as written; three are `jitEmitUnary` (parked, see below); and `jitEmitAssign` is
the parked call-shape wrinkle — note it *is* already `(argument,target)`, so it is a shape fit and
parked for other reasons.

### Batch discipline

**A batch of N asserts the slot count moving by exactly N.** An op that silently failed to install
shows as **N-1** rather than hiding behind siblings that worked. One **H7 spot control** per batch:
pull one member's registration and confirm the count drops by one **with the values unchanged**.
Measured for batch 1 by pulling `<=` — count 4 → 3, fire 1 and fire 2 still 1 and 3.

⚠ **A batch rung must not contain an op that is itself a sweep candidate.** `jitSlotT3` uses four
`if`s assigning distinct constants rather than summing the comparisons, because folding them with
`+` would make its expected count jump to 7 the day `+` migrates — **an assertion moving for reasons
unrelated to what it certifies** (H3).

**Op two was three lines** — shim, `groups.ext` decl, registration. **The pathfinder generalizes.**
The finding it was sent to get is a null one and is worth stating: `jitEmitCompare` has the same
`(argument,target) → target` shape as `jitEmitBinary` despite a different *result* type (an `i1`),
so the two-argument slot spans `jitOp` and `jitCmp` with nothing special-cased.

**Tempo is not authorized past op two.** That decision belongs to whoever reads this after op two
reports, which is now.

---

## ⚠ SWEEP-CLOSE OBLIGATIONS — the ruling's tail, parked here so op 13 finds it

**1. NEVER-NULL HARDENS AT SWEEP CLOSE.** The presence-gated fork is a *migration* device. Once
every op carries an emitter, the null case stops meaning "not yet migrated" and starts meaning "a
bug", so the fork's `if slot` becomes an invariant rather than a branch. **Do not harden early** —
a half-swept population with never-null enforcement fails on ops nobody has reached yet.

**2. IT IS CERTIFIED BY A SLOT CENSUS, NOT BY INSPECTION.** Walk the `Operators` registry (and the
unary population, see below), count entries carrying a `jitEmitter`, and compare against the live
operator count. ⚠ **State what the census matched** — H9, which has already miscounted its own
subject twice on this project, in both directions. Read the hits by eye at this population size.

**3. THE COUNTER OUTLIVES THE MIGRATION OR IT DOESN'T — decide deliberately.** `gJitSlotCount` exists
because the fork is value-transparent. After never-null, "did it go through the slot" is no longer a
question (there is nowhere else to go), so the counter's job ends. Retiring it is fine; **retiring it
silently is not** — the `JM*` rungs assert it and would go green-by-vacancy if the line simply
vanished. If it retires, the rungs retire *by mapping*, assertion by assertion.

---

## PARKED, DELIBERATELY

**UNARY.** The slot-beside-the-binding ruling was built to reach it, but the install path differs —
`ruleMethod=` into `method`/`isMethod`, not `operateMethod=`/`isOperator`. It gets its **own first
specimen with the same care as op one**, not a three-line assumption off the binary/cmp pattern.

⚠ **AND THE EDGE IS NOW HARDENED RATHER THAN LEFT TO CONVENTION (2026-08-17).** `runOP`'s fork
accepts any node carrying a slot and its seed gate spans `isUnary`, so a unary op handed an emitter
would have gone live down an uncertified path with nothing but habit stopping it. It is now a
**loud, counted refusal**: `gJitSlotUnaryRefused` increments, a numbered line goes to stderr, and
control falls through to the interpreter arm. **KE-4 posture — refusals are counted, quiet
acceptances are counted by nothing.**

**Demonstrated to fire**, because a guard nobody has triggered is a guard nobody has tested:
temporarily registering `jitEmitter` on `'++'` gave **refused 2, slot count 0, values still 11/31**.
Every `slotrung` asserts `jitSlotUnaryRefused = 0`.

**RETIRE GUARD, COUNTER AND RUNG ROW TOGETHER** when unary opens — by mapping, not by letting a
line vanish.

**`opPlusEQ` AS A NAMED EXCEPTION** (per-leaf dispatch, outside the slot model) and the
**`jitEmitAssign` call-shape wrinkle** stay parked with unary. Clod proposes when the campaign opens
that door.

---

## HOW TO ADD AN OP — the whole recipe

1. **Shim** in `jitEmitters.rtn`: one line onto `jitEmitBinary`/`jitEmitCompare`/`jitEmitUnary` with
   the selector baked in. ⚠ **Check the name against the enum first** — `jitMul` was unavailable
   because `enum jitOp` already had it; the stem is `jitEmit*`.
2. **Declare** it in `groups.ext` (out of repo, bear-trap #11).
3. **Register** `jitEmitter=<shim>` on the op in `incant/setup`.
4. `tok GroupRules.twk` **bare**, check `grep -c '^extern' GroupRules.h` moved by exactly your count,
   rebuild.
5. **Rung**: copy `jitSlotT2`. One `testing()` then `jitRefire()`, answers that differ, output field
   initialized, jitted half first, sentinel last. Wire it with `slotrung`.

**Do not add the counter increment to your shim.** It lives at the fork precisely so you cannot
forget it.
