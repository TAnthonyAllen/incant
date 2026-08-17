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
Note the fork already covers it structurally: `runOP`'s seed gate is
`(op.isOperator || op.isUnary)`, and the binder sets no flag, so a unary op carrying a slot would
take the fork today. **That is an argument that it is reachable, not evidence that it works.**

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
