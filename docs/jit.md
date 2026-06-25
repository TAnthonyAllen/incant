# Incant JIT Design
*Authored 2026-06-10. Replaces any prior jit.md. This is the design.*

---

## What This Design Is

This is a calling-convention and frame-model design, not a codegen-backend design. It defines incant's activation record — the per-call frame, its slot ABI, and the prologue/epilogue around every call. LLVM lowering (Phase JIT proper) is the first consumer of this model, but the slot discipline defined here is backend-agnostic; any compiled target inherits it. Getting the frame model right is the prerequisite, independent of how machine code is ultimately emitted.

---

## The Problem JIT Solves

Incant actions currently carry their local fields as named attributes on the action's GroupItem. This conflates two things that should be separate:

- **The frame schema** — the set of fields an action uses, their names, their roles. Known at parse time. Belongs to the action definition.
- **The live frame** — the actual values in those fields during a specific call. Belongs to one invocation. Must be per-call for recursion to work.

The interpreter conflates these because each call operates on the same action GroupItem and its attribute list. Recursion works only by convention, not by structure. The JIT separates them: the action definition retains its attribute list as the authoritative frame schema; each call allocates a fresh slot array from that schema. This is the C++ stack discipline applied to incant's no-declarations model.

---

## The Action Method Signature

Incant actions conform to a standard method signature: one field argument in, one field return. This is invariant and the JIT does not change it. The argument pointer is a separate handle in the call frame, distinct from the local slot array.

---

## The Frame Schema

Every field an action references in its code — locals, globals it uses, argument-derived values it pulls in explicitly — is added to the action's field list at parse time. The field list is therefore the complete and closed universe of everything the action touches. No field can appear at runtime that was not enumerated at parse time.

This is true already in the interpreter. The JIT inherits it.

**Precondition — schema-closure depends on no in-place action modification.** The field universe closes only because actions are not modified in place. The field list is fixed at parse time; nothing — directives, runtime construction, reflection — adds a field to a *live* action afterward. The slot-index scheme depends on this directly: every field reference compiles to a static index, so a field appearing at runtime that the schema never enumerated would have no slot to land in. This is the current discipline and it holds today. If in-place action modification is ever wanted, this is the first assumption that must be revisited — schema-closure is a load-bearing dependency, not an incidental property. Cross that bridge when we reach it.

The frame schema is the action's field list. Its shape is fully determined at parse time. The JIT compiler walks the field list once, assigns each field a stable slot index, and every field reference in the generated code becomes an index into that array.

---

## The Call Frame

At JIT call time, before the action body runs, a fresh slot array is allocated — one slot per entry in the frame schema, in field list order. The setup prologue walks the field list and copies each GroupItem pointer into its assigned slot.

The argument pointer lives separately as a dedicated handle. It is not a slot in the array.

The slot array is the per-call live frame. It is ephemeral. When the call returns, the slot array goes away.

**This is the primary addition that JIT generation requires beyond bytecode generation.** Bytecode generation already walks the action, resolves field references, and emits operations. The JIT layer does the same walk producing different output, plus this prologue/epilogue around every call.

---

## What Each Slot Holds

**Slots are native-typed, not GroupItem pointers.** The conservative alternative — slots as GroupItem*, body calling opPlus/etc. via CreateCall — is not worth building: it gives frame discipline but no real performance win over the interpreter. Native typing is Phase 1.

Each slot holds the field's native LLVM value, typed at emit time:
- `isCOUNT` fields → `i32` slot (from `int gCount` in GroupItem's data union)
- `isNUMBER` fields → `double` slot
- `isSTRING`/`isTOKEN` fields → `ptr` slot (Phase 3; Phase 1/2 fall back for string fields)

Fields with unjittable types (group, op, item, etc.) cause the whole action to
fall back to the interpreter — the monomorphic gate (see `jit-design.md`).

**Type stamping at define time is required for jit-eligible actions.** The gate
walks the field list and reads the type tag directly — no inference pass. For
an action to be jittable, every field must have its type stamped at define time
(e.g. `count x, y, result;`). This is a dialect constraint on jit-eligible
actions, not on the language at large.

### Prologue: unboxing into native slots

At function entry (emitted IR), for each field in the schema:
1. Load the GroupItem* from the incoming C++ slot array argument.
2. Read the native value from the GroupItem's typed data member
   (`gCount`/`gNumber`/`gText` at the appropriate offset).
3. Store into the field's `alloca` slot.

This unboxing is the prologue's work. After it runs, the function body operates
entirely on native values in LLVM allocas — no GroupItem indirection during
arithmetic.

### Epilogue: reboxing back to GroupItem

At function exit, for each field:
1. Load the final native value from its `alloca` slot.
2. Store it back to the GroupItem's typed data member.

For the return value: the action's result is reboxed into the result field's
GroupItem, and that GroupItem* is what the function returns — not the raw
native value. The function signature remains `GroupItem* (*)(GroupItem* slotArray,
GroupItem* argument)` at the C++ boundary.

### Locals vs. globals under the native model

**Locals** — the alloca slot is the authoritative value for the duration of the
call. Epilogue rebox writes back to the local GroupItem (which goes away on
return). No issue.

**Globals** — the alloca slot holds the unboxed copy of the global's value.
Writes during the action update the alloca, not the shared GroupBody.
**Global writeback is deferred to the epilogue, not immediate.**

This is a semantic divergence from the interpreter, where writing a global's
slot writes through to the shared GroupBody immediately. Two consequences:

1. A global updated mid-action is not visible to other incant code until the
   action returns and the epilogue reboxes. Phase 1 and 2 are safe (no
   concurrent access, no callbacks reading globals mid-action). Phase 3
   (callbacks into the runtime) must treat this carefully — a callee reading a
   global that the jitted caller has updated will see the pre-call value.
2. On abnormal exit (error, longjmp), the epilogue may not run and global
   updates are lost. Document this as a known limitation for Phase 1.

---

## Assign Semantics Under JIT

With native-typed alloca slots, assignment semantics become unambiguous:

- `A = B` where both are locals: native value copy. A's slot gets B's native
  value (i32, double, or ptr). Fully static, no tag-lookup at runtime.
- `A = B` where B is an argument attribute: unbox B's value from the argument
  GroupItem into A's slot at the point of assignment.
- `:=` (byRef): store a pointer-to-slot in the local slot rather than a value.
  Slots have stable addresses for the lifetime of the call frame (BDWGC heap).

The tag-aliasing ambiguity that complicates `A = B` in the interpreter
disappears because A and B are now distinct indexed slots.

**Method-bound fields are gated out.** Fields with `gMethod`/`gOp` type are not
in the jittable set — the gate rejects any action containing them. Within a
jitted body, method-dispatch hazards cannot arise.

---

## Recursion

Each call allocates a fresh slot array. Recursive calls do not stomp each other because each invocation owns its array. The frame schema (action attribute list) is shared across all calls as a read-only definition; only the live slot arrays are per-call. This mirrors C++ method call semantics exactly, without any declarations required from the programmer.

---

## Relationship to Bytecode Generation

Bytecode generation does the foundational intellectual work: walking the action, resolving field references into the action's field list, emitting operations in the correct order. The JIT translation of the action body is largely a remapping of what bytecode generation already produces — field references by tag become field references by slot index; the semantic content is the same.

The novel work in JIT generation is the call frame setup and teardown. Everything else is mechanical translation of the bytecode layer.

Natural implementation order:
1. Frame setup and teardown as a standalone piece — verify with a trivial action.
2. Body translation layered on top — slot-indexed remapping of bytecode operations.

---

## Action as Homoiconic Object

The action's attribute list (the frame schema) remains an attribute of the action GroupItem. The action is still a first-class incant object that can be inspected, passed, and stored. The JIT'd code object is an opaque implementation detail attached to the action — not something incant code manipulates directly, at least in this design iteration.

A wrapper carries both: the inspectable GroupItem (with its attribute list as frame schema) and a pointer to the compiled entry point. This wrapper is what gets stored or passed when an action is treated as data. It is also the deliberate seam where an invalidate-and-recompile story would attach if a JIT'd action's structure is ever edited at runtime (see Open Questions) — the seam is intentional, not an oversight.

---

## Open Questions

- **Slot allocation: stack vs heap — decided by byRef escape.** Stack is natural and mirrors C++; deep recursion may argue for heap. But this is not a free choice — it is *determined* by whether a `:=` pointer-to-slot can escape its frame. If `A := B` can store a pointer-to-slot into a global, or return it, that reference outlives the call and stack allocation dangles on frame pop. So the real question is "can byRef escape a frame?" — answer that and allocation follows. (These were two separate open items in the draft; they are one question.) Working lean: heap-allocate from BDWGC and let Boehm keep escaped slots alive; stack then becomes the optimization earned by a later non-escape analysis, applied only to provably-non-escaping frames.
- **Recompile on structural edit.** The compiled entry point is opaque and assumes the action's structure is fixed (see the schema-closure precondition above). If incant ever rewrites a JIT'd action in place, its compiled code goes stale. The action wrapper — carrying both the inspectable GroupItem and the entry-point pointer — is the deliberate seam where an invalidate-and-recompile story would attach. Deferred, and coupled to the same "no in-place modification" discipline that schema-closure rests on.
- **Type inference for optimization.** The conservative JIT emits code that still does runtime type checks through the GroupItem pointer indirection — semantically identical to the interpreter, just with stack-frame discipline. A specialization pass that locks in types for hot paths and emits tighter machine code is a follow-on optimization, not a prerequisite.
- **`modedOP.boundTo`** interaction with JIT'd dispatch. Deferred pending that design pass.

---

## Status (2026-06-22) — Phase 1 COMPLETE: arithmetic + compare + assign + unary + division

**Design chosen: Plan A — the jitting gate lives *inside* the opMethod.** `opPlus`
grows an `if jitting { … }` emit branch above its interpret body; `aCTionExpressioN`'s
jitting branch dispatches the operator's own `operat` (no `jit` child), which
self-gates. At endgame the interpret body and the gate strip out mechanically and the
opMethod *is* the emitter. (Plan B — emitter on a `jit` child — is the abandoned
alternative; it would have left N siblings to fold back in. See `docs/layout-recon.md`
sibling discussion only for the parallel-lowerings framing.)

**Proven end-to-end — 24 POPs, all in one pass, via `jitRunAction`** (driver
`incant/jitscratch`, fixtures `incant/generate`):

*Arithmetic — `jitEmitBinary` (`enum jitOp`):*
| POP | expression | result | path |
|---|---|---|---|
| `jitAdd` | `3 + 5` | 8 | `CreateAdd` (count / i32) |
| `jitAddF` | `3.0 + 5.0` | 8 | `CreateFAdd` (number / double) |
| `jitMix` | `3 + 5.0` | 8 | count `SIToFP`-promoted → `FAdd` (numeric promotion) |
| `jitFieldAdd` | `righty + 5` | 18 | **field unbox** — `jitSeedField` bakes the stable GroupItem address, `CreateLoad`s `gCount` at run time |
| `jitSub` | `8 - 3` | 5 | `CreateSub` |
| `jitMul` | `3 * 5` | 15 | `CreateMul` |
| `jitDiv` | `7 / 2` | 3 | `CreateSDiv` (signed, **truncates toward zero**) |
| `jitDiv10` | `10 / 3` | 3 | `CreateSDiv` |
| `jitDivNeg` | `righty(-7) / 2` | -3 | `CreateSDiv` — truncation, not floor's -4 (seeded `0 - 7`; no unary-minus literal) |

*Compare — `jitEmitCompare` (`enum jitCmp`), i1 result `ZExt`'d to i32:*
| POP | expression | result | path |
|---|---|---|---|
| `jitGT` | `3 > 5` | 0 | `CreateICmpSGT` |
| `jitLT` | `3 < 5` | 1 | `CreateICmpSLT` |
| `jitGE` | `5 >= 5` | 1 | `CreateICmpSGE` |
| `jitLE` | `7 <= 5` | 0 | `CreateICmpSLE` |
| `jitEQ` | `3 == 3` | 1 | `CreateICmpEQ` |
| `jitNE` | `3 != 5` | 1 | `CreateICmpNE` |

*Assign — `jitEmitAssign` (store-back **writes through** to the GroupItem; proven by reading the field back in interpreted incant after the run):*
| POP | expression | result | readback |
|---|---|---|---|
| `jitAssign` | `maximus = 8` | 8 | `maximus` → 8 |
| `jitPlusEQ` | `maximus += 5` (from 10) | 15 | `maximus` → 15 |
| `jitMultEQ` | `maximus *= 3` (from 4) | 12 | `maximus` → 12 |
| `jitMinusEQ` | `maximus -= 5` (from 30) | 25 | `maximus` → 25 |
| `jitDivEQ` | `maximus /= 4` (from 30) | 7 | `maximus` → 7 (`jitSDiv` truncates) |

*Unary — `jitEmitUnary` (`enum jitUnary`), in-place CreateAdd/Sub 1 with store-back (2026-06-20); unary minus added 2026-06-25:*
| POP | expression | result | readback |
|---|---|---|---|
| `jitInc` | `++righty` (from 13) | 14 | `righty` → 14 |
| `jitDec` | `--righty` (from 13) | 12 | `righty` → 12 |
| `jitNeg` | `-righty` (from 13) | -13 | (none — value-producing) |

**Unary minus (`jitNeg`, 2026-06-25) — the Phase 2 prerequisite, DONE.** `-righty` → `CreateNeg`
(double: `CreateFNeg`); **value-producing, NO store-back** (the operand is not mutated, unlike
`++`/`--`), so the negated SSA flows up as the result (`jitRunAction result = -13`). The grammar
half: `-` added to the `UnaryOPS` bin, `TokenXP` became `UnaryOPS? ANYorNum^ InvokeArg?` —
`ANYorNum` (`NumbeR | ANYtoken`) lets the operand be a literal *or* a field (`-7` *and* `-x`), and
the `^` no-skip adjacency on the operand is the steal-guard: `-x`/`-7` (adjacent) form a unary,
but spaced ` - ` (`a - b`, `20 - x`) fails adjacency and falls through to binary `opMinus`. The op
half: a new `opUnaryMinus` (value-producing, `0 - operand` into `tempField`) reached via a named
`negate` op in `Operators` (`unary ruleMethod=opUnaryMinus`) — `handleUnary` swaps the prefix `-`
to `opFields["negate"]`, keeping the binary `-` slot (`opMinus`) completely isolated (no dual-
dispatch). Proven interpret-side too: `-7`→-7, `-righty`→-13, `a - b`→0, `20 - x`→7.

Unary dispatches via `aCTionExpressioN`'s jitting branch detecting the `uxp` node
(`aCTionTokenXP.handleUnary` builds it), seeding the operand, and firing `arg.method(arg)`
→ `runOP` → the opMethod's own gate. **incant unary is PREFIX-only** (`++righty`); postfix
doesn't parse as a unary op. Compound `-=` is the `+=`/`*=` pattern with `jitSub`.

*String `+=` — `jitEmitStringPlusEQ`, the **FIRST `CreateCall` in the JIT layer** (2026-06-21):*
| POP | expression | result | readback |
|---|---|---|---|
| `jitPlusEQF` | `floaty += 1.5` (from 2.5) | 4 | `floaty` → 4 (isNUMBER path, `FAdd`) |
| `jitStrEQ` | `name += "!"` (from "world") | 0 (const cap) | `name` → `world!` |

**`opPlusEQ` now switches on `target.data`:** `isCOUNT`/`isNUMBER` → `jitEmitBinary(jitAdd)` +
`jitEmitAssign` (count vs number FAdd picked inside `jitEmitBinary` from operand type, so the
two arms coincide); `isSTRING`/`isTOKEN` → `jitEmitStringPlusEQ`; anything else falls through
to the interpreter. `jitEmitStringPlusEQ` bakes target's and argument's stable GroupItem
addresses as constant ptrs and emits **one `CreateCall`** to `concatEQ` (callee baked by
address) — `GroupItem(GroupItem,GroupItem)`. `concatEQ` does the member work as ordinary C++
(`target->setText(::concat(2, target->getText(), argument->getText()))` — the interpreter's
isSTRING `+=` body), so **no variadic IR, no member-function-pointer IR**. The driver's `i32()`
can't `ret` a pointer, so `gJitResult` caps on a constant 0 and the `+=` side effect (setText
through to the real field) is verified by readback. The call is left **untagged (not `readnone`)**
so LLVM can't DCE a callee it can't see into. **This is the proof-of-concept for `jitEmitCall`**
(method calls on the list): same bake-address + single-CreateCall mechanics, with the callee
sourced from `op.method` instead of hardcoded `concatEQ`.

- **Gates self-host the emitter dispatch (Plan A):** each opMethod (`opPlus`, `opMinus`,
  `opMultiply`, `opDiv`; `opGT`/`opLT`/`opGE`/`opLE`/`opEQ`/`opNotEQ`; `opAssign`,
  `opPlusEQ`, `opMultiplyEQ`, `opDivEQ`) carries `if jitting { … }`. Arithmetic → `jitEmitBinary`;
  compare → `jitEmitCompare`; plain `=` → `jitEmitAssign`; compound `+=`/`*=`/`/=` compose
  `jitEmitBinary` then `jitEmitAssign(target,target)` to commit the binary result.
- **`jitSeedField` now stashes `jitSlot`** (the baked field-storage address), giving the
  assign store-back a destination — immediate writeback to the field's own storage.
- **Driver:** `i32()` function, one compile+run per call, **unique function name per run**.
  Double → `FPToSI`, i1 → `ZExt`, both to i32.
- Bytecode path unaffected (`testByteCode` → 11).

**Next proof points / deferred:**
- **Return a real `GroupItem*` (full epilogue).** The assign store-through proves writeback
  *into a field's storage*; returning a real `GroupItem*` per this doc's frame model (vs the
  driver's native `i32`) is still not done.
- **Slot-array calling convention** (this doc): current field unbox/store bakes a *stable*
  address. The slot ABI is the refinement for non-stable fields and recompile-on-edit.
- **Cached-function refire.** The load-vs-fold distinction is invisible while compile+run
  is one shot — observable once a compiled action is cached and re-fired after a field
  changes. (The assign readback is a *partial* step here: it shows the store mutates real
  memory, but compile+run is still one shot.)
- **Chained-operand gate guard.** The gate assumes a non-literal operand is a real field,
  so `a + b + c` mis-routes the inner result to `jitSeedField`. Single-op POPs hide it.
  (Bear trap — CLAUDE.md.)
- **Unary (`++`/`--` → `jitEmitUnary`). DONE 2026-06-20** — see the unary table above.
- **String `+=` / first `CreateCall` (`jitEmitStringPlusEQ` → `concatEQ`). DONE 2026-06-21** —
  see the string-`+=` table above. The call-emit mechanics are now proven.
- **`jitEmitCall` — method calls on the list (the generalization of the above). PARKED for
  Clay+Tony design before Clod touches `runOP`.** The gate point is `runOP`'s
  `or op.isMethod` branch (one surgical line: `if jitting return jitEmitCall(op, target)`);
  `runOP` is otherwise kept JIT-unaware. The open design item is the **one-arg `concatenate`
  primitive** — a pure, read-only, parts-walking extern (aCTionPrinT-style, one field in / one
  field out) that fits incant's calling convention and is the clean model for `jitEmitCall`
  across all method calls, not just string `+=`. (The two-arg `concatEQ` above was the
  pragmatic write-back form for compound-assign, which needs `target` by identity; the
  general value-returning method calls don't, so one-arg is the durable shape. Container
  packing hits `addGroup`/`setGroup` parent-copy — `GroupItem.twk:73`/`:1242` — for any node
  with a parent, which is why the write-back case took two explicit pointers.)
- **Division (`/` `/=`) — DONE 2026-06-22.** The last straight-line op — see the division
  rows in the arithmetic table and `jitDivEQ` in the assign table. `opDiv`/`opDivEQ` gate onto
  `jitEmitBinary(jitSDiv)` (the established `-=` pattern); `jitSDiv`'s `CreateSDiv` was already
  in the switch. **Semantics decision (settled): C-style signed truncation toward zero** —
  `7/2=3`, `-7/2=-3` (not floor's -4). This *diverges by design* from interpret's
  `(int)lround(...)` round-to-nearest (`7/2=4`); the round-intrinsic "faithful" alternative was
  declined in favour of C semantics. Div-by-zero is **deferred (unguarded)**, matching
  interpret's own unguarded path. Caveat surfaced: incant has **no unary-minus literal** (`-`
  is binary `opMinus` only; `NumbeR` is `[0-9]+`), so `-7` silently drops the sign — the
  negative POP seeds `righty = 0 - 7` and divides the field. This is the disambiguation bear
  that gates the Phase 2 gIF POP (below).

---

## Phase 2 — control flow (gIF) — THE OPEN FRONTIER

Phase 1 straight-line is complete. The next frontier is **gIF** (conditional control
flow): the opMethod gates emit an i1 condition (already proven by `jitEmitCompare`) into an
LLVM `CreateCondBr` across then/else basic blocks. gIF instructions are **drafted and ready
to hand off**.

**Blocker CLEARED (2026-06-25): the unary-minus grammar question is resolved.** A control-flow
POP needs negative test values (`if x < 0`, decrementing loop bounds), and incant could not
express a negative literal — `-7` parsed as binary `opMinus` with no left operand and dropped
the sign. That is now fixed: prefix `-` parses as unary (`-7` *and* `-x`) via the `ANYorNum^`
operand slot + the `negate`→`opUnaryMinus` op, while spaced binary subtraction is preserved by
the no-skip adjacency guard (see the `jitNeg` entry under Phase 1 status above for the full
mechanism). With negative-valued conditions now expressible, **Phase 2 proceeds directly to the
gIF POP / `CreateCondBr`** — the gIF instructions are drafted and ready to hand off.
