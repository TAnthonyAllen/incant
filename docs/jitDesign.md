# Incant JIT — DESIGN (open and active)

*Consolidated 2026-07-31 from eight separate JIT documents. This file holds **design**: what is
settled as invariant, what is open, and what is deferred. **What actually exists and runs is in
`docs/jit.md`** — do not record measurements here.*

**Read `jit.md` §0 first of all: THE JIT REPLACES THE INTERPRETER.** Without it the `jitting`
gate in the source reads as an accelerator and every decision below is misread accordingly.
That has already happened twice.

---

# PART I — THE SETTLED PREMISES

**These three are INVARIANTS, not questions.** They are stated as constraints the design must
satisfy, and anything in the tree or in an older document that contradicts them is a defect in
that thing, not an open debate. Contradictions found during consolidation are listed in
`ipc/clod-to-clay.md` SEQ 37 rather than silently reconciled here.

## Premise 1 — the datA-stability contract

**A field's `datA` is fixed for the lifetime of jitted code that observed it. Violating that is
undefined behaviour BY CONTRACT — no guards, no deopt paths, no type checks at run time.**

This is what makes the whole emission model cheap. The emitter reads a field's type once, at
emit time, and bakes the decision. There is no invalidation machinery, no guard branch, no
bail-out path, and none should be written: adding one would concede that the contract does not
hold and would put a runtime check on every operation to pay for it.

*HPDL, one line, so it is not lost:* a **debug-build warning plus an action-parse abort** when a
field's `datA` changes under a jitted action is the eventual safety net. Debug build only. It
is a diagnostic for the programmer, not a runtime guard for the emitter — the contract stays
"undefined behaviour," and the debug build merely makes the violation loud instead of silent.

## Premise 2 — promotion-first emission

**Rank the scalar types, widen the lesser operand, and the op×type table only ever sees matched
pairs.** Effectively 1D-per-operator after promotion.

The consequence is the point: the table does not need an N×N cell for every operand-type
combination. Promotion collapses it to one column per operator per *resulting* type. This is
already how `jitEmitBinary` behaves for the count/number case — an `isCOUNT` operand meeting an
`isNUMBER` one is `SIToFP`-promoted and the pair goes to `FAdd`. Premise 2 generalises that
from an implementation detail into the rule the table is built on.

## Premise 3 — table in kant, buttress in C++

**IR templates live in a kant table: operator member, type attribute, IR template text.**

**An extern `jitEmit` owns everything the table cannot express:** SSA name counting, slot
substitution, buffer plumbing, and any multi-instruction sequence that does not template
cleanly.

**Type at emit time comes from `dataNames[datA]` — a CARRIED FACT, not an inference.** No type
inference pass, ever. The field already knows what it is.

**Non-scalar `dataNames` (isGROUP, isMAP, isSTAK, …) map to ONE FALLBACK COLUMN: emit a runtime
call into the existing opMethod.** The interpreter does not disappear — it is what the fallback
calls.

⚠ **That last sentence is the reconciliation with `jit.md` §0 and it is easy to misread.** §0
says the JIT *replaces* the interpreter; premise 3 says the interpreter is *what the fallback
calls*. These agree, and the distinction is the whole crossover design: a **per-op runtime call
to a known opMethod, emitted into the IR**, is not the same thing as **whole-action bail-out to
an interpretive walk**. The first is a compiled program calling a helper — one execution path,
which is what §0 requires. The second is two execution paths and is the divergence §0 names.
**A prior plan proposed exactly the second as the v1 policy; premise 3 supersedes it.**

### Premise 3's verified foundation — `dataNames` is index-aligned with the datA enum

*Measured 2026-07-31 by comparing `IncantForms/WorkingOn/tester:17` against `GroupBody.h:60-74`.
All fourteen match. This is what makes `dataNames[datA]` a lookup rather than a mapping.*

| datA | name | scalar? | LLVM type | notes |
|---|---|---|---|---|
| 1 | `isANY` | — | — | fallback column |
| 2 | `isCHAR` | scalar | `i8`? | **OPEN** — no emitter today |
| 3 | `isSET` | no | — | fallback column |
| 4 | `isBUFFER` | no | — | fallback column |
| 5 | `isCOUNT` | **scalar** | `i32` | `gCount`; the proven path |
| 6 | `isGROUP` | no | — | fallback column |
| 7 | `isITEM` | no | — | fallback column |
| 8 | `isMAP` | no | — | fallback column |
| 9 | `isNUMBER` | **scalar** | `double` | `gNumber`; the proven path |
| 10 | `isOBJECT` | no | — | fallback column |
| 11 | `isREGEX` | no | — | fallback column |
| 12 | `isSTAK` | no | — | fallback column |
| 13 | `isSTRING` | **scalar** | `ptr` | `gText`; one `CreateCall` exists, nothing else |
| 14 | `isTOKEN` | **scalar** | `ptr` | as `isSTRING` |

⚠ **Do not confuse this enum with the `binType` family.** `isBIN` is also 1 and `isLIST` is
also 3, in a *different* flag family. `dataNames` indexes the **data** enum only.

---

# PART II — THE OPEN WORK

These are the three items Fearless named as carried-open, plus what consolidation added.

## O1 — the `dataNames` → IR type mapping table itself

The skeleton is above; what is open is every cell it does not fill.

- **`isCHAR` (2) is genuinely undecided.** It is a scalar and it has no emitter, no POP, and no
  stated LLVM type. It is the only scalar row with nothing behind it.
- **`isSTRING`/`isTOKEN` (13/14) are scalars whose only emitted form is a single `CreateCall`**
  (`jitEmitStringPlusEQ` → `concatEQ`). Whether they belong in the scalar table at all or in
  the fallback column with a richer helper set is open. Premise 2's ranking has no defined
  answer for "widen an `isCOUNT` to meet an `isSTRING`" — string `+` count is *pointer
  advance*, not promotion, so it may be the one operator that escapes premise 2.
- **The fallback column's shape.** Premise 3 fixes *that* non-scalars emit a call into the
  existing opMethod; it does not fix the **signature** that call uses. Two precedents exist and
  they disagree: the shipped `concatEQ(target, argument)` is a two-pointer write-back form, and
  the durable shape argued for the general case is a **one-argument, value-returning**
  primitive matching incant's own calling convention (one field in, one field out). The two-arg
  form was pragmatic because compound-assign needs `target` by identity. **Pick one before the
  fallback column is built**, because every non-scalar op inherits it.

## O2 — the template slot convention

The table holds "IR template text." Nothing yet says what a slot looks like inside that text,
and the choice constrains `jitEmit` (O3) directly.

Open, and unprejudged: the delimiter and escape rule; whether slots are positional or named;
how an SSA result name is requested versus supplied; how a template declares that it needs *n*
fresh names; and whether a template can carry more than one instruction or whether
multi-instruction sequences are by definition `jitEmit`'s business. That last one is the seam
between the table and the buttress, so it is really the same question as O3.

## O3 — the exact `jitEmit` ownership boundary

Premise 3 lists what `jitEmit` owns — SSA name counting, slot substitution, buffer plumbing,
sequences that do not template cleanly. **"Does not template cleanly" is the load-bearing
phrase and it is not yet a test.**

The forcing case is already in the tree: `jitEmitGIF` is three basic blocks, a `CreateCondBr`,
two sub-walks and a merge. Nothing about that is a text template with slots. So control flow is
plainly `jitEmit`'s, and plain binary arithmetic is plainly the table's — the boundary runs
somewhere between, and the cases that decide it are compare-with-promotion, compound assign
(binary then store), and the fallback call.

**A useful discipline while the boundary is unsettled:** anything that needs to *know a block
structure* is the buttress; anything that is one instruction with substituted operands is the
table.

## O4 — added by consolidation: the mem2reg contradiction, and it is the sharpest open item

**The design says SSA comes from alloca/load/store plus `PromotePass`, and never write a phi.
The first IR ever dumped from this tree (2026-07-30) shows field slots are `inttoptr` ABSOLUTE
ADDRESSES, not `alloca`s — so mem2reg has nothing to promote.**

`jitSeedField` bakes the field's stable `gCount`/`gNumber` address and stashes it as `jitSlot`.
That is a real address in the GroupItem, not a stack slot. It works for straight-line code and
it makes the store-through-to-the-field behaviour free, which is why it was built that way and
why the assign POPs pass by readback.

But two things in this document assume allocas: the prologue/epilogue frame model (Part III),
and "PromotePass places all phi nodes" (which is what makes a missing merge impossible).
`jit.md` §3.4 records that the gIF return value is **not** merged — and a missing merge is
exactly what an unpromoted, non-alloca slot model would produce.

### ⚠ RESOLVED 2026-07-31 BY MEASUREMENT — and (a) vs (b) was the wrong question

The IR was read properly rather than argued about, and it collapses the choice:

**FIELDS DO NOT NEED PHIS, BECAUSE FIELDS ARE MEMORY.** A slot is a baked absolute address;
a read is `CreateLoad` from it and a write is `CreateStore` to it. Two stores to the same
address on two paths need **no merge at all** — that is what memory *is*. The four-block
if/else emitted for `jitElseT` is correct on both paths with not a phi in sight, and the
verifier is silent because the IR is genuinely valid.

So the design's mem2reg dependency is not *broken*; it is **unnecessary for the thing it was
written about**. `jitEmitters.rtn`'s own comment already says PromotePass is "a no-op on the
current alloca-free shape" — the code knew, and only the design did not.

**(a) and (b) are therefore NOT alternatives — they are PHASES, and the doc's error was
stating the future mechanism as the current one:**

| | baked addresses (today) | frame model (later) |
|---|---|---|
| what it covers | fields and globals | **locals and recursion** |
| correctness | correct, no phis needed | correct |
| cost | a load/store per access | native values in registers |
| needs mem2reg | **no** | **yes** — that is where allocas appear |

The frame model is not dropped and must not be: §0 Consequence 1 says locals-as-frames lands
**once, in the JIT**, and `saveLocalFields` is deleted rather than repaired. That is about
**recursion and per-call frames**, which baked addresses cannot do — a recursive action's
locals would all alias one address. So the frame model is **deferred, not superseded**, and
mem2reg arrives with it.

**WHAT IS ACTUALLY OPEN, and it is narrower than O4 was written as: the RETURN VALUE HAS NO
DEFINED SOURCE.** `jitRunAction` caps with whatever `gJitResult` last held — a constant, in
every fixture measured. Field stores are right; the function's answer is not. Under baked
addresses the fix is a designated result slot (store to it, load-and-ret at the end — memory
again, still no phi); under frames it is the epilogue. **Both are cheap. Neither can be
chosen without saying what an incant action's compiled return value IS**, which is the
genuinely open question and is Tony's.

⚠ **One thing NOT to conclude from this:** that the JIT is nearly right because gIF is. The
gIF path is the one construct with a working emitter. §2's census is unmoved — 24 ungated
operators and 29 ungated statement handlers still execute interpreted at emit time.

## O5 — added by consolidation: does the one-`jitData`-per-GroupItem model survive Phase 2?

Seeding attaches one SSA value to a *node*, and emitters write results back onto operand nodes.
That is coherent for a single straight-line expression and **structurally cannot work for
operand reuse** — a node holds exactly one SSA value at a time (`jit.md` §3.3). Loops and
multi-statement bodies both fail today, with different symptoms and one plausible shared cause.

The question is whether emission needs a **value stack or a per-use SSA mapping** instead of
per-node storage. This is an architecture question, not a bug, and it blocks everything past
Phase 1. Note it is the same family as the chained-operand bear trap (`a + b + c`), which
suggests the problem was visible earlier in a narrower form.

## O6 — `aCTionFOR`, and it got harder under §0

`aCTionFOR` is a **GroupItem tree-walk, not a counting loop**. Under "accelerator" the answer
was obvious: defer it, bail the action. **Under §0 that answer is the divergence §0 names**, and
under premise 3 whole-action bail is superseded anyway. So the question becomes *"can the JIT
emit a loop that walks a GroupItem list?"* — which, given premise 3's fallback column, probably
means a loop whose body calls back into interpreted `next()`/`prior()` each iteration.

That is expressible. Whether it is *worth* emitting — the tree-walk cost dominates the
arithmetic — is a separate question, and it is the first place where premise 3's fallback
column meets something with a loop around it.

---

# PART III — THE FRAME MODEL (designed, not built)

*This is a calling-convention design, not a codegen design. It is the replacement §0
Consequence 1 refers to when it says `saveLocalFields` is deleted rather than repaired. **None
of it is implemented** — see O4, which may change it.*

## The problem it solves

Incant actions carry their local fields as named attributes on the action's GroupItem, which
conflates two things:

- **The frame schema** — the set of fields an action uses. Known at parse time. Belongs to the
  action *definition*.
- **The live frame** — the actual values during one specific call. Belongs to one *invocation*.
  Must be per-call for recursion to work.

The interpreter conflates them because every call operates on the same action GroupItem and its
attribute list, so recursion works by convention rather than by structure. The JIT separates
them: the definition keeps its attribute list as the authoritative schema; each call allocates a
fresh slot array from it. C++ stack discipline applied to incant's no-declarations model.

## Schema closure, and the precondition it rests on

Every field an action references is added to its field list at parse time, so the field list is
the complete and closed universe of everything the action touches. Each field gets a stable slot
index; every field reference compiles to that index.

⚠ **This closes only because actions are not modified in place.** Nothing — directives, runtime
construction, reflection — adds a field to a *live* action afterward. A field appearing at
runtime that the schema never enumerated would have no slot to land in. **This is a load-bearing
dependency, not an incidental property.** If in-place action modification is ever wanted, this
is the first assumption that must be revisited.

## Slots, prologue, epilogue

**Slots are native-typed, not GroupItem pointers.** The conservative alternative — slots as
`GroupItem*` with the body calling opPlus via `CreateCall` — gives frame discipline but no real
win over the interpreter, and is not worth building.

*Prologue:* for each field, load the `GroupItem*` from the incoming slot array, read the native
value from its typed data member, store into the field's `alloca`. After that the body operates
entirely on native values.

*Epilogue:* reverse it — load each final native value and store it back to the GroupItem. The
action's result is reboxed and the function returns a `GroupItem*`, not a raw native value. The
C++ boundary signature stays `GroupItem* (*)(GroupItem* slotArray, GroupItem* argument)`.

⚠ **Globals are written back at the EPILOGUE, not immediately** — a semantic divergence from
the interpreter with two consequences: a global updated mid-action is invisible to other incant
code until the action returns, and **on abnormal exit the epilogue may not run and global
updates are lost.**

## Assign semantics under frames

`A = B` between locals is a native value copy, fully static. `:=` (byRef) stores a
pointer-to-slot rather than a value. **The tag-aliasing ambiguity that complicates `A = B` in
the interpreter disappears**, because A and B are distinct indexed slots.

## Where `JitData` lives — and the design doc was wrong about this for a month

Transient per-field emission state (`jitSlot`, `jitValue`, `jitType`) is **hung on the node as
a `JitData`**, not held in a C++ `std::unordered_map` side table. The side table was specced
first and **fights tok two ways**: it forces passthrough for every state access, and llvm-typed
signatures poison the generated header (`jit.md` §6). The node-hung form was adopted during the
2026-06-17 wiring walk and is what shipped. **The design document was supposed to be updated to
match and never was**, which is how a superseded side table survived in the spec until this
consolidation.

---

# PART IV — CONTROL FLOW AND THE RUNTIME SURFACE

## The fundamental inversion

In execute mode `aCTionIF` evaluates the condition and runs *one* branch. **In emit mode it must
emit *both* branches as basic blocks connected by `CreateCondBr`. It cannot take a path.** The
same inversion applies to every loop: emit header, body, latch, exit.

`aCTionIF` is the template, and the strategy for the rest is one line: **a jitting gate → a
`jitEmit*` bracketing emitter that runs sub-walks via `gMethod` between basic-block brackets.**
The pivot already paid for the hard part (emission rides the walk); loops add only block
topology.

## Loop order, and why

**WHILE first** (minimal topology, no latch work), **DO second** (WHILE with the branch moved —
and its semantic POP is that the body runs once even when the condition is initially false),
**FOR last and possibly never** (O6).

Two shared mechanisms are needed **before any loop**:
1. **Re-walk semantics.** A loop's condition is walked *once* to emit into a block that
   *executes repeatedly*. Verify nothing in the walk assumes walk-once-run-once. The per-run
   `jitData` reset is per-**run**, not per-iteration — correct, but do not "fix" it when a loop
   POP confuses someone.
2. **`jitLoopBegin`/`jitLoopBody`/`jitLoopEnd`** — the loop analog of `jitIfBegin`/`jitIfEnd`.

⚠ **The `gJitResult` discipline is a silent-failure rule and it applies to every new emitter:**
the condition's `gMethod` leaves the i1 in `gJitResult`, and the next stage must read it
**immediately, with no statement in between.** A clobber does not announce itself.

⚠ **Nesting is the one plausible re-architecture item.** Each bracketing emitter is re-entrant
only if its block bookkeeping is stack-shaped rather than global-single. `gIfEndBlocks` is
already a stack, so this looks provided for — but it is untested, and two *sequential* `if`s
already segfault, so nesting has never been reached.

## Loop `continue` / `break` / `return`
WHILE and DO bodies already handle `isBranch`/`isContinue`/`isReturn` interpretively. The
emitters need explicit continue→br-latch and break→br-exit wiring. **`isReturn` inside a jitted
loop is unresolved** — the simplest correct answer was a bail, which premise 3 supersedes, so
it now wants a function-exit block reached via the epilogue.

## The runtime surface (the later arc)

Jitted code that calls back into the runtime — `locate`, registry lookup, GroupItem methods,
print, string ops — needs ORC symbol resolution via `absoluteSymbols`. Use `extern "C"`
wrappers for anything name-mangled so ORC symbol names are predictable. There is a 2017
precedent for the allow-list (`OLDtawkDoNotTouch/Include/UIjit.ext`) which is GUI-vintage and
partly stale but answers the shape of the question: *what host functions may jitted code call,
and with what types?*

**This is where premise 3's fallback column actually lands**, so O1's signature question and
this arc are the same piece of work approached from two ends.

## Reference archaeology — do not port

`OLDtawkDoNotTouch/Tokf/Emitter.twk` (2017 tok LLVM emitter) and
`OLDtawkDoNotTouch/Include/UIjit.ext`. **Plan A — incant's own ops emit IR — is the chosen
direction; porting `Emitter.twk` wholesale is the abandoned Plan B.** Under Plan A the old
emitter stops being a port target and becomes a **lookup table**: "given this op and these
operand types, call this `IRBuilder` method." Its arithmetic int/float fork, its `emitCompare`
signed/unsigned matrix and its cast conversions are exactly the content premise 3's table
needs, transplanted rather than linked.

⚠ One correction the archaeology invalidates: **incant ops no longer take `&target` by
reference** (changed ~2026-06-10), which kills the mem2reg-aliasing worry the old design
carried — no address-taken alloca. Note this interacts with O4: the aliasing worry is dead, but
so, currently, is the alloca.

---

# PART V — DEFERRED, AND NAMED SO IT DOES NOT CREEP

- **`modedOP.boundTo` interaction with jitted dispatch** — pending that design pass.
- **Stack allocation of frames.** BDWGC heap is correct now; stack is the optimisation *earned*
  by a later non-escape analysis. ⚠ **It is not a free choice — it is determined by whether a
  `:=` pointer-to-slot can escape its frame.** If it can, stack allocation dangles on frame pop.
  Answer "can byRef escape a frame?" and allocation follows.
- **Recompile on structural edit.** The compiled entry point assumes fixed structure. The
  action wrapper — carrying both the inspectable GroupItem and the entry-point pointer — is the
  deliberate seam where invalidate-and-recompile attaches. Coupled to schema closure.
- **Type specialization / hot-path tightening.**
- **`switch`** — **DROPPED, not deferred.** No `aCTionSwitch` exists; the `switch(){}` in the
  class files is native TAWK compiling straight to C++. Host control flow, never in the
  interpret/jit system. Nothing to defer.
- **Performance.** No jitted-vs-interpreted timing has ever been taken, and under §0 it is not
  the point.

---

# PART VI — WHAT TO BUILD NEXT, AND WHY IN THIS ORDER

Not a schedule — an argument about dependency, for whoever sets the schedule.

1. **Settle O4 (allocas vs baked addresses).** Everything in Part III and the "never write a
   phi" position depends on it, and the missing return-value merge is already a symptom.
2. **`jitEmitGIF`'s else arm.** It is the only *wrong answer at exit 0* in the JIT, and wrong
   with a clean exit outranks every crash.
3. **The unary seed gap.** Cheap, three POPs prove it, and it unblocks fixture capture — but
   it moves no frontier, so do not schedule it as progress.
4. **O5 (`jitData` reuse).** Blocks loops and multi-statement bodies, i.e. everything past
   Phase 1. The IR dump can settle its inferred cause in one run and has not been used for it.
5. **The crossover ruling** (`jit.md` §0 Consequence 2). Now rulable: the boundary is
   enumerated, the primitive exists (`jitDegrade`), and premise 3 has already decided the
   *mechanism* — a per-op emitted call, not a whole-action bail. What remains is Tony's call on
   whether an un-emittable construct refuses loudly, degrades loudly, or aborts the compile.
6. **Then** the table (O1/O2/O3), which is the thing this design pass was called for and which
   the four above keep honest.

---

*Consolidated 2026-07-31. Premises 1-3 are Fearless's, stated as invariants. Contradictions
found during consolidation are in `ipc/clod-to-clay.md` SEQ 37, not silently reconciled.*
