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

Every slot holds a GroupItem pointer — the action's own copy of the field wrapper for that field. This is uniform across all field categories. There are no special cases.

**Locals** — the GroupItem's GroupBody is not shared with anything outside this action. Writes stay local. The slot goes away when the call returns.

**Globals** — the GroupItem is a copy of the global's wrapper, but both wrappers point at the same GroupBody. Writing through the slot writes through to the shared GroupBody automatically. The JIT inherits the interpreter's global-writeback semantics for free, with no explicit writeback pass needed. This is how the interpreter works today; the JIT does not change it.

The JIT cannot distinguish locals from globals by inspecting a slot — nor does it need to. The GroupItem pointer indirection handles both cases uniformly.

---

## Assign Semantics Under JIT

With locals as stack slots, assignment semantics become unambiguous:

- `A = B` where both are locals: slot-to-slot copy. A's slot gets B's GroupBody content. Fully static, no tag-lookup at runtime.
- `A = B` where B is an argument attribute: dereference the argument handle, copy value into A's slot.
- `:=` (byRef): store a pointer-to-slot (or pointer-to-attribute) in the local slot rather than a value. Expressible cleanly because slots have stable addresses for the lifetime of the call frame.

The tag-aliasing ambiguity that complicates `A = B` in the interpreter disappears because A and B are now distinct indexed slots, not lookups into a shared attribute namespace.

**One hazard carries over.** "Fully static" above means the *tag-aliasing* ambiguity is gone — A and B are distinct slots, no shared-namespace lookup. It does not mean every `=` hazard is gone. Slot-to-slot copy is still content copy: it moves data and lists, not method bindings. A method-bound field (`gMethod`/`gOp`) copied A ← B still loses its method, exactly as in the interpreter. The slot model relocates that hazard to a new address space; it does not cure it. Method-bound fields must be dispatched in place, never copied-then-called — under JIT as under the interpreter.

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
