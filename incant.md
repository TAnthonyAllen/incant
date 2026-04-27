# incant — Project State & Design Notes

A living document capturing where the incant compiler/runtime project stands,
the decisions made, and the questions still open. Read this first when picking
up the project after a break, or when bringing a new conversation up to speed.

Last updated: 2026-04-27 (bytecode-as-field design clarified; walker moves to incant)

---

## Project at a glance

incant is a self-defining, currently-interpreted extensible language. The
runtime bootstraps from a small kernel of 32 hard-coded rules in C++/Obj-C++,
then loads `setup` and `grammar` (incant text) to define the rest of the
language. Everything in the system is a `GroupItem` — rules, fields, data,
methods, registries — and the parser invokes rule actions named
`aCTion<RuleName>`. The grammar is the same syntax used to define data, which
is what makes the system reflective.

Repo: <https://github.com/TAnthonyAllen/incant>
Working drafts of grammar/runtime files live in `XML/WorkingOn/`.
C++/Obj-C++ runtime files (`.twk`, `.h`, `.mm`) live at the repo root.

---

## Files to fetch at session start

When picking up this project in a new conversation, fetch these in order. The
first one is this file itself; the rest are the design surface for the
in-flight bytecode work.

* <https://github.com/TAnthonyAllen/incant/blob/main/incant.md> (this file — read first)
* <https://github.com/TAnthonyAllen/incant/blob/main/XML/WorkingOn/grammar>
* <https://github.com/TAnthonyAllen/incant/blob/main/XML/WorkingOn/setup>
* <https://github.com/TAnthonyAllen/incant/blob/main/XML/WorkingOn/generate>
* <https://github.com/TAnthonyAllen/incant/blob/main/XML/WorkingOn/utilities>
* <https://github.com/TAnthonyAllen/incant/blob/main/XML/WorkingOn/oneTest>
* <https://github.com/TAnthonyAllen/incant/blob/main/XML/WorkingOn/unitTests>

If the web\_fetch tool refuses any of these (intermittent behavior on github.com
in some sessions), ask the project owner to attach them directly — uploading
into the chat is reliable and fast.

The `.mm` runtime files at the repo root are not fetched proactively — pull
them only when the conversation actually needs them. The same goes for the
`.rtn` include files.

---

## Ground rules and preferences

These shape the work and shouldn't get re-litigated each session:

* **Tok is frozen for collaboration purposes.** The `.twk` files are written
  in Tok, a C++ preprocessor the project owner maintains separately. Its
  parser is hard to debug. Working alone the owner would still use Tok, but
  is happy to leave it behind when working with Claude. Read and edit the
  `.mm` files directly. Don't propose changes that would require Tok work.
  (Long-term: incant itself replaces Tok — see "The deeper goal" below.)
* **Reflectivity is a feature, not an accident.** Anything in the language
  ecosystem (bytecode, IR, generated code) should remain inspectable as a
  `GroupItem` where reasonable. This is the main argument against jumping
  straight to LLVM IR.
* **Debugger-readiness from the start.** `sourceLINE` and `sourceFILE` get
  plumbed through new code paths even before anything reads them.
* **GUI work is deferred.** A native Apple window interface for incant is
  in the plan, but only after incant is JITed and fast enough to drive it.
  Don't volunteer GUI-side concerns until the JIT work lands.
* **Two-tool workflow.** Design and architecture happen in Claude.ai chat,
  with `incant.md` as the persistent record. Implementation (mechanical
  edits, build/test loops) happens in Claude Code, which reads `incant.md`
  for context and edits `.mm` files directly. Both tools defer to the
  project owner for review and commit.

---

## The deeper goal

The reason for the JIT work isn't performance for its own sake. It's
**self-hosting**: the project owner wants to do all programming in incant,
where grammar and syntax are under his control. Today that's blocked because
incant is interpreted, which makes it impractical as a primary programming
language for serious work. JIT compilation is the path to making incant fast
enough to be the language he actually uses, not just a hosted DSL on top of
Obj-C++.

This goal shapes several decisions:

* **The runtime stays in `.mm` for now**, but only as a means to an end.
  The eventual target is for incant code to be able to do everything the
  `.mm` runtime currently does — including emitting its own bytecode and
  driving its own JIT.
* **Reflectivity matters because incant is meant to be its own metalanguage.**
  An incant program needs to be able to see, manipulate, and generate other
  incant programs. Choices that flatten or obscure structure (e.g., emitting
  opaque LLVM IR) push against this.
* **Tok was a stopgap.** The project owner is comfortable in Tok and would
  default to it alone, but is willing to leave it behind in collaboration.
  The real successor to Tok is incant itself, once it's fast enough.

## C++ floor — settled architecture

**incant aims for a "pragmatic self-hosting" model**, not maximalist. A
small, stable C++ kernel stays permanently; everything above it migrates
to incant as the JIT makes that practical. The goal is to *program in
incant*, not to eliminate C++. C++ is leverage (LLVM, GC, NSObject, macOS
GUI), not debt.

### Stays in C++ permanently

* Bootstrap: the 32 hard-coded rules and the loader that runs `setup`/`grammar`
* Input stream and tokenizer (hot path; source-position tracking lives here)
* `GroupItem` allocator and the GC — using **BDWGC** (Boehm-Demers-Weiser),
  not writing one. Conservative, stop-the-world, mature, integrates cleanly
  with C++. Allocation switches from `new`/`malloc` to `GC_malloc`.
* LLVM JIT integration and codegen glue (use the **ORC v2** API, not MCJIT)
* Platform calls: drawing, file I/O, GUI bridge, NSObject interop
* A small set of primitive operations the JIT compiles into directly

### Migrates to incant, roughly in this order

1. Bytecode emitter (Phase 2) — `generate` rewritten to emit bytecode
   GroupItems; the prior C++-source emit path is being abandoned, not
   preserved
2. **The bytecode walker itself** (Phase 2) — a short incant action that
   loops over the bytecode body and dispatches each instruction's
   per-op method. C++ keeps only the gating hook.
3. Optimization passes on bytecode (constant folding, DCE, etc.)
4. Higher-level rule actions currently in C++
5. Standard library / utility functions (`utilities` already does this)
6. Eventually: the LLVM IR emitter from bytecode, written in incant
7. Long-range stretch goal: all rule actions in incant, assuming the JIT
   makes them fast enough

### Migration rule

Code moves from C++ to incant when **both** are true:

1. It's no longer performance-critical because the JIT handles it.
2. Expressing it in incant gives the eventual incant programmer (i.e., you,
   working in incant) meaningful control or extensibility.

Code that's just "stuff that happens" — works fine, no one needs to extend
it, performance matters — stays in C++ even if it could in principle be
rewritten. This is a deliberate constraint to prevent thrashing.

---

## GroupItem allocation

CLAUDE.md previously referenced `GroupControl::groupController->itemFactory(...)`.
This is out of date. itemFactory has been replaced with a simpler `GroupItem`
constructor in anticipation of the BDWGC migration. Use the constructor
directly when allocating GroupItems in C++. CLAUDE.md should be updated to
match — until it is, treat this file as the source of truth per CLAUDE.md's
own guidance.

---

## The current goal

Move incant from pure interpretation toward a bytecode/JIT compilation pipeline,
in service of the self-hosting goal above.

### Phased plan

**Phase 0 — Integrate BDWGC.** Done. `GroupItem` allocation switched from
manual `new`/`malloc` to `GC_malloc`. itemFactory replaced with a simpler
constructor. GC statistics added to `stopParsingInput` for visibility.

**Phase 1 — `generateCode()` repurposed as bytecode emitter entry point.**
The placeholder C++-source emit path is being abandoned; the existing
`gBlocK`/`gIF`/`gFOR`/`gWhilE`/`gDO`/`gXpress`/`gPrinT` actions in
`generate` will be rewritten in Phase 2 to emit bytecode GroupItems
instead. `generateCode` itself stays as the user-facing entry point.

**Phase 2 — Build a bytecode emitter** by rewriting the existing
statement-dispatch actions in `generate` (`gBlocK`, `gDo`, `gFor`,
`gIf`, `gWhile`, `gXpress`, `gPrinT`) to emit bytecode GroupItems
instead of placeholder C++ source. Bytecode is represented as a
`GroupItem` so it stays inspectable and manipulable from incant code.
The walker is a short incant action; the C++ side is just a gating
hook plus per-op interpret methods. Staged in two halves —
see "Phase 2 staging" below.

**Phase 3 — Add an LLVM JIT backend** using the ORC v2 API, with `alloca`

* the `mem2reg` pass so we don't have to hand-manage SSA construction.
  LLVM converts stack slots to SSA registers automatically. The JIT consumes
  bytecode and emits machine code; bytecode remains the canonical IR.

### Cross-cutting concern: debugger-readiness

`sourceLINE` and `sourceFILE` live on `GroupRules` as the running parser
cursor and update as input is parsed. `aCTionStatemenT` already snapshots
these into `RuleStuff::sourceLine` (currently typed as int) at parse time.

**Decision:** `RuleStuff::sourceLine` is promoted to a GroupItem with its
count set to the current line number in aCTionStatemenT. A copy of sourceFILE
is added to sourceLine so it effectively tracks source file and the
source line at the statement level.

This shape:

* Matches the reflectivity rule — a debugger written in incant inspects
  source positions through the same field-walking machinery used for
  everything else.
* Absorbs future attributes (column, span end, macro context, "inlined
  from" chain) without changing consumers.
* Costs one pointer per RuleStuff instance; allocation pressure is
  negligible at parse time.

**Stamping site:** `aCTionStatemenT`, replacing the current int assignment
with a fresh GroupItem constructed via the GroupItem constructor.

**Granularity:** statement-level for now. Per-expression and per-token
stamping can be added later by giving those GroupItems their own
`sourceLine` attribute. The shape doesn't change.

**Bytecode connection:** the phase-2 bytecode emitter copies the statement's
`sourceLine` onto each emitted instruction GroupItem. The interpreter
ignores it; the debugger reads it. No separate `bcLINE` pseudo-op is
needed when every instruction already carries position attributes.

---

## What a bytecode is, structurally

This section captures the design center of Phase 2. It exists because
"bytecode" carries a lot of conventional baggage that doesn't apply here —
incant's bytecode is unusual in shape, and the unusual shape is the whole
point.

### A bytecode is a field that *is* an instance of its op

A single bytecode instruction is a GroupItem whose identity *is* the op
(opMultiply, opGT, bcBRZ, etc.) — the same way every field in incant is
an instance of some kind. There is no separate `tag` attribute; the field
doesn't *point at* opMultiply, it *is* opMultiply, with this instruction's
specific operands hung off it as attributes:

```
opMultiply{lhs=righty, rhs=2, dst=tempField, sourceLine=N}
```

A bytecoded action body is a parent GroupItem whose members are these
instruction fields, in execution order:

```
testByteCode_bytecode (parent)
├── opGT{lhs=righty, rhs=0, dst=tempField, sourceLine=N}
├── bcBRZ{cond=tempField, target=<ref to bcRET below>, sourceLine=N}
├── opMultiply{lhs=righty, rhs=2, dst=tempField, sourceLine=N+1}
├── opAssign{target=maximus, value=tempField, sourceLine=N+1}
└── bcRET{sourceLine=N+1}
```

That's the entire physical layout. No tag attribute, no dispatch table, no
parallel data structures.

### A bytecode field has no method of its own

This is the structural break from the existing `runOP` token. A `runOP`
token is self-driving — it carries `runOP` as its method, and tree-walking
calls `.run()` on each node. A bytecode field is **inert data**. The
method that interprets it (or compiles it, or prints it) lives on the op,
not on the instruction.

The walker reads each instruction's op-affiliation, looks up the
appropriate method on the op, and calls it. The instruction never decides
anything for itself.

### Each op carries one method per consumer

Every op grows method attributes — one per kind of walker:

```
opMultiply
├── operateMethod    = runMultiply         (today: tree-walking interpreter)
├── interpretMethod  = bcMultiply          (Phase 2: bytecode interpreter)
└── emitMethod       = emitMultiply        (Phase 3: JIT codegen)
```

A walker is hard-wired to one of these attribute names. The interpreter
walker fetches `interpretMethod`. The JIT-emit walker fetches `emitMethod`.
The "choice" of which method to use isn't per-instruction — it's per-walker,
made once at the boundary where bytecode meets execution.

This is **option (b)** of the previous open dispatch-attribute question:
every op carries every method-attribute any consumer in the system needs.
No fallback chains, no unified single name, no internal branching inside
methods. Closed and resolved.

`bc*` ops (control-flow only — bcBR, bcBRZ, bcRET) carry `interpretMethod`
and eventually `emitMethod`, but no `operateMethod` — they don't exist
in source, so the tree-walker never sees them. That asymmetry is fine
and informative.

### The walker is a short incant action, not C++

```
runBytecode body; {
    result = body[1];
    for field in body
        result = field.interpretMethod(field, result);
    return result;
}
```

(Final syntax pending; this is the shape.) `field.interpretMethod` resolves
because `field` is an instance of its op, and the op has an `interpretMethod`
attribute pointing at the per-op method. The method receives `field` as an
argument so it can read operand attributes (`lhs`, `rhs`, `dst`, etc.) off
it, and `result` so it can chain values across the loop.

The walker doesn't mutate the bytecode field — `interpretMethod` is read,
not stamped. A second walker (the JIT, an optimizer, a printer) over the
same bytecode body sees the same untouched data and reads its own
attribute on the op. The bytecode is consumer-agnostic by construction.

This is what makes the multi-consumer property work, and it's why the
walker stays in incant rather than C++: the inner loop is trivial, and
keeping it in incant means an incant programmer can later wrap it,
instrument it, or replace it with a stepping debugger walker.

### Operand handling: pre-resolved, not nested

When `gXpress` emits a sub-expression's result into a slot, the slot
reference (e.g., `tempField` in step 2a, a vreg index in step 2b) is what
gets stored in the consuming instruction's operand attribute. By the time
an instruction runs, its operands are already values or slot references
to values — never nested expressions that need evaluating.

This is what "the unboxing dance disappears in bytecode" means: the
runtime work `runOP` currently does to resolve GROUP-flagged args and
evaluate invokable subexpressions is moved to emit time. The interpreter
just reads a slot.

### Why this shape

The shape is forced by three commitments:

1. **Reflectivity.** Bytecode is GroupItems, walked by ordinary
   field-traversal machinery. Incant code can inspect, generate, and
   transform bytecode using the same operations that work on any other
   data.
2. **Multi-consumer flexibility.** The same bytecode is consumed by the
   interpreter (Phase 2), the JIT (Phase 3), eventually by optimizers
   and debuggers. Per-instruction data and per-op behavior are kept
   separate so consumers don't interfere.
3. **Uniformity.** Everything in incant is a field. Bytecode follows
   that rule. The "slight inefficiency" of looking up an operand
   attribute instead of reading a packed-byte stream is the price of
   not having half a dozen incompatible storage shapes (instruction
   stream + dispatch table + operand stack + ...). At interpreter
   speeds it's negligible; in the JIT it's literally zero at runtime
   because lowering happens once.

---

## The bytecode question — decided

**What does `generateCode` generate?** Settled: **bytecode as the canonical
IR, represented as a `GroupItem`**. LLVM IR is generated *from* bytecode
when the JIT path runs. Three options were considered:

1. Custom bytecode interpreted by a new VM. (Rejected: slow without JIT.)
2. LLVM IR directly. (Rejected: opaque, breaks the reflectivity that
   makes incant meant to host its own compiler eventually.)
3. **Bytecode-first, LLVM IR generated from it for JIT.** (Chosen.)

The choice is forced by the self-hosting goal. Since incant is meant to
eventually emit its own bytecode and drive its own JIT (see C++ floor →
migration list), bytecode must be a `GroupItem`-shaped thing that incant
code can construct, inspect, and modify. Opaque LLVM IR can't fill that role.

### Bytecode design — what we know

* **The expression triples already built by `aCTionExpressioN` are proto-bytecode.**
  Each `{op, target, arg}` group with `gMethod = runOP` is essentially a
  three-address instruction. Phase 2 is not new IR design — it's
  linearization across statements, explicit branch instructions for
  control flow (if/while/for/break/continue/return), per-instruction
  fields-that-are-instances-of-their-op, and a per-action vreg array
  (in step 2b).
* **runOP's polymorphism is statically decidable at emit time.** runOP
  dispatches across five cases (operator, C++ method, coded rule, coded
  action, generic-invokable). All five are distinguishable when the
  emitter sees the op GroupItem — by registry membership and by the
  attribute set already established during parsing. The bytecode emitter
  selects the right specialized opcode rather than emitting a generic
  RUNOP and re-doing the dispatch at runtime.
* **opAND, opOR, opIN are not short-circuiting.** Their bodies (in
  `Instruct.rtn`, with C++ versions in `GroupItem.mm`) inspect already-
  evaluated operand values. By the time runOP reaches them, both target
  and argument have been resolved. Eager linearization in the bytecode
  emitter — post-order flattening with operands materialized into vregs
  — preserves current semantics exactly. (If short-circuit `&&`/`||` are
  wanted later, they'd be added as a separate grammar-level construct
  that lowers to BR/BRZ patterns.)
* **The unboxing dance at the top of runOP** (resolving GROUP-flagged
  args, evaluating invokable subexpressions) disappears in bytecode.
  The emitter materializes subexpression results into a destination
  slot eagerly, so by the time an instruction runs, its operands are
  already values. This is also what makes the eventual LLVM lowering
  mem2reg-friendly.
* **Intermediates are flat by language design.** incant has no
  parenthetical sub-expressions and no operator precedence — expressions
  are walked right-to-left, each operation taking the previous result
  and a new operand. `B.C`, `B[C]`, `B(C)` are fused into single
  tokens at parse time, not treated as operators. As a result, at any
  point in a statement exactly **one** unnamed intermediate is live.
  This is what makes both `tempField` (interpreter) and a single-vreg-
  per-statement scheme (JIT) sufficient — there's no nested-temp
  situation to handle.

### What lives in C++ vs incant for phase 2

* **Emitter — incant.** *Reuses the existing `gIF`/`gFOR`/`gWhilE`/
  `gDO`/`gXpress`/`gPrinT`/`gBlocK` actions in `generate`*, rewriting
  their bodies to emit bytecode GroupItems instead of C++ source. The
  C++-source emit path is being abandoned (it was a stepping stone, not
  the JIT path), so there is no two-jobs problem. No new
  `XML/WorkingOn/bytecode` file — `generate` becomes the bytecode
  emitter. `runGenerated` stays as the dispatch hub. Names like `gIF`
  stay because they correspond directly to grammar tags (`IF`).
* **Walker — incant.** A short action (sketch under "What a bytecode is,
  structurally" above). Loops over the bytecode body, calls each
  instruction's op's `interpretMethod`, threads the result. Five lines.
* **Per-op interpret methods — C++ for operators, incant for `bc*`.**
  `opMultiply.interpretMethod`, `opGT.interpretMethod`, etc. wrap the
  existing operator logic in `.mm` (cheapest path: thin shims that
  pull operands from `field` attributes and call the existing `op*`
  methods). The `bc*` ops (`bcBR`, `bcBRZ`, `bcRET`) are trivial
  enough to be incant actions — they just inspect attributes and
  return next-ip references. Decision can be revisited if a `bc*`
  method gets non-trivial.
* **Gating hook — C++.** Where rule-action dispatch lands for a coded
  action, check whether the action has a `bytecodE` attribute; if so,
  invoke `runBytecode` (the incant walker) on it; otherwise fall through
  to the existing tree-walk. Lives wherever `aCTionStatemenT` or its
  callers currently dispatch action bodies. Exact site TBD next session.
  This is the *only* C++ Phase 2 deliverable.

### Phase 2 first step

Pick one trivial coded action — something with one if and one arithmetic
expression — and round-trip it through emitter → bytecode GroupItem →
walker end-to-end before generalizing. Each new opcode added afterward
is incremental: one emitter action, one `interpretMethod` on its op.

Target action: `testByteCode` (in `unitTests`), which is:

```
testByteCode; { if righty > 0; maximus = righty * 2; }
```

### Phase 2 staging — tempField then vregs

Phase 2 is split in two for risk reduction:

**Step 2a — `tempField`-based bytecode.** Emit using the existing
interpreter's `tempField` slot as the implicit destination for every
intermediate. The bytecode is correct under sequential interpretation
but not LLVM-friendly (everything aliases through one slot). This step
exists to validate the bytecode-as-GroupItem shape end-to-end, with
the smallest possible delta from the existing interpreter. The schema
uses a `dst` attribute set to `tempField` so step 2b can change *what*
goes in `dst` without changing the schema.

**Step 2b — vregs.** Replace `tempField` references with vreg indices
minted by the emitter. One fresh vreg per intermediate. The bytecode
body gains a `vregCount` attribute so the interpreter sizes its array.
Sets up Phase 3's alloca + mem2reg lowering cleanly.

### `bc*` opcode registry — first cut

Three entries cover what `testByteCode` needs:

```
registry(Bytecode);
define
    bcBR    interpretMethod=runBR;
    bcBRZ   interpretMethod=runBRZ;
    bcRET   interpretMethod=runRET;
    ;
```

* `bcBR` — unconditional branch. Operand: `target` (GroupItem ref to
  destination instruction).
* `bcBRZ` — branch if zero. Operands: `cond` (slot to test — `tempField`
  in step 2a, vreg ref in step 2b) and `target`.
* `bcRET` — end of action body. No operands. Explicit (not implicit
  end-of-members) so dumps are easy to read.

Notably absent: `bcCALL`, `bcMOV`, `bcCONST`. Add when a test forces them.
Existing `Operators` registry entries (`opGT`, `opMultiply`, `opAssign`,
etc.) gain an `interpretMethod` attribute alongside their existing
`operateMethod` (this is option (b) of the dispatch-attribute decision).

### Branch target representation — decided

Branch targets are direct GroupItem references to the destination
instruction, not integer offsets. Backpatching: when emitting a forward
branch (e.g., `gIF` emitting a `bcBRZ` to skip the then-block), append
the branch instruction with `target` unset, finish emitting the body,
then assign the now-known instruction at the join point as `target`.
No symbol tables, no offsets.

---

## Next session — start here

We left off having clarified that bytecode instructions are op-instances
(no separate tag attribute) and that the walker is a short incant action.
Next concrete moves, in order:

1. **Day-one syntax check.** Verify in incant that
   `field.interpretMethod(field, result)` resolves and invokes correctly
   when `field` is an instance of an op carrying an `interpretMethod`
   attribute. If yes, the walker is two lines and we proceed. If no,
   the language gap is "call the method behind an attribute path" — a
   small, generally-useful extension to fill before the walker can land.
2. **On-paper walkthrough** of what `generateCode(testByteCode)` should
   produce, instruction by instruction, with explicit GroupItem shapes.
   Validate the schema before any code lands. Expected output (step 2a):

   ```
   1: opGT       lhs=righty rhs=0  dst=tempField  sourceLine=...
   2: bcBRZ      cond=tempField target=<instr 5>  sourceLine=...
   3: opMultiply lhs=righty rhs=2  dst=tempField  sourceLine=...
   4: opAssign   target=maximus value=tempField   sourceLine=...
   5: bcRET      sourceLine=...
   ```
3. **Add `Bytecode` registry to `setup`** — three entries (`bcBR`,
   `bcBRZ`, `bcRET`), as specified in the "first cut" block above.
4. **Add `interpretMethod` attribute** to `opGT`, `opMultiply`, `opAssign`
   in the `Operators` registry. Each value is a thin shim that pulls
   operands from the instruction field's attributes and calls the
   existing `op*` operate method. Three shims, ~5 lines each.
5. **Implement `runBR`, `runBRZ`, `runRET`** as incant actions (or `.mm`
   methods if incant-side method invocation can't yet take a field
   argument cleanly — revisit after step 1).
6. **Write `runBytecode`** as a short incant action. Five lines, per
   the shape under "What a bytecode is, structurally."
7. **Rewrite `gIF`, `gXpress`, `gBlocK`** in `generate` to emit bytecode
   GroupItems instead of placeholder text. Get `testByteCode` emitting.
   Each emitted instruction is constructed as an instance of its op
   with operand attributes attached locally; no tag attribute.
8. **Wire the gating hook** — find the action-dispatch site in
   `GroupRules.mm` (or wherever `aCTionStatemenT` calls action bodies)
   and add the `bytecodE` attribute check. This is the only C++ change
   in Phase 2.
9. **Run `testByteCode()`** through the bytecode path. Verify
   `maximus` ends up at 26.

### Already done from previous sessions

* ✅ `sourceLine` promotion (RuleStuff::sourceLine is now a GroupItem)
* ✅ Trivial coded action picked (`testByteCode`)
* ✅ Dispatch-attribute question resolved as option (b): every op
  carries every method-attribute any consumer needs
* ✅ Bytecode-instruction shape settled: instruction *is* an instance
  of its op; no separate tag attribute
* ✅ Walker placement settled: incant, not C++

### Decisions landed this session

* Bytecode instruction = an op-instance. Dispatch is `field.<methodAttr>`,
  not `field.tag.<methodAttr>` — the field *is* the op.
* Walker is a short incant action (~5 lines), not a C++ interpreter loop.
  The previous "Step 2a interpreter pseudocode" C++ template is obsolete.
* Walker is non-mutating: it reads `interpretMethod` off the op, never
  stamps it onto the instruction. Multi-consumer property preserved.
* Each op carries one method-attribute per consumer (`operateMethod`,
  `interpretMethod`, eventually `emitMethod`). Closed and resolved —
  this is option (b) of the prior open question.
* C++ in Phase 2 shrinks to one piece: the gating hook on action
  dispatch. Walker, per-`bc*` methods, and (probably) per-operator
  shim methods are all in incant.

---

## File map (quick reference)

### incant source (in `XML/WorkingOn/`)

* `grammar` — incant grammar rules, loaded after bootstrap
* `setup` — registries: cOMMANDs, Operators, pROPERTIEs, Keywords, GroupFields,
  *(planned, phase 2)* Bytecode
* `generate` — bytecode emitter: `gBlocK`/`gIF`/`gFOR`/etc. dispatch table,
  rewritten in phase 2 to emit bytecode GroupItems (was: C++ source emit).
  *(planned, phase 2)* `runBytecode` walker action.
* `utilities` — JSON, layout, frame-fill, hex-color helpers
* `oneTest` — entry-point test driver
* `unitTests` — test fixtures and assertions (includes `testByteCode`,
  the phase 2 round-trip target)

### Runtime (C++/Obj-C++ at repo root)

The `.mm` files are the actual compiled source. The `.twk` files are written
in **Tok**, a C++ preprocessor that the project owner maintains separately.
Tok generates the `.mm` from the `.twk`. **For working on the language,
read the `.mm` files; ignore the `.twk` source unless the question is
specifically about Tok generation.**

* `GroupItem.{h,mm}` — the universal data type
* `GroupRules.{h,mm}` — rule machinery (parsing, action dispatch).
  *(planned, phase 2)* gating hook on coded-action dispatch lives here
  or in a caller.
* `GroupMain.{h,mm}` — top-level driver, input handling
* `GroupBody.{h,mm}` — group bodies / member lists
* `GroupControl.{h,mm}` — control flow primitives
* `GroupList.{h,mm}` — list operations
* `GroupStak.{h,mm}` — stack support
* `GroupDraw.{h,mm}` — drawing/rendering (incantGUI side)
* `RuleStuff.{h,mm}` — rule helper utilities
* `Layout.{h,mm}` — layout engine
* `groups.{C,h,mm}` — top-level group handling

(Note: the previously-planned `Bytecode.{h,mm}` is no longer needed.
The walker moved to incant; the only C++ Phase 2 deliverable is the
gating hook, which lives in an existing file.)

### Other

* `Generate.rtn`, `Debug.rtn`, `Instruct.rtn`, `parse.rtn`,
  `ruleActions.rtn`, `GroupActions.rtn` — source-code include files
  (split out of larger `.mm` files to keep work-in-progress sections
  easier to edit; `#include`d into the corresponding implementation file)
* `cppMacros`, `groupDirectives`, `groupIncludes` — build/include helpers
* `Stylish.twk` — styling

---

## How to use this file across sessions

1. At the start of a new conversation about incant, point Claude here:
   *"Fetch incant.md from the repo for current state."*
2. After we make a real decision or finish a phase, ask Claude to update
   the relevant section. Commit the change.
3. Keep it terse. This is orientation, not history. Old decisions that
   are no longer relevant should be cut, not archived.

The `XML/WorkingOn/` files are the design surface; this file is the index
to where we are in working on them.
