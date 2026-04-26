# incant — Project State & Design Notes

A living document capturing where the incant compiler/runtime project stands,
the decisions made, and the questions still open. Read this first when picking
up the project after a break, or when bringing a new conversation up to speed.

Last updated: 2026-04-26 (evening — bytecode design session)

---

## Project at a glance

incant is a self-defining, currently-interpreted extensible language. The
runtime bootstraps from a small kernel of 32 hard-coded rules in C++/Obj-C++,
then loads `setup` and `grammar` (incant text) to define the rest of the
language. Everything in the system is a `GroupItem` — rules, fields, data,
methods, registries — and the parser invokes rule actions named
`aCTion<RuleName>`. The grammar is the same syntax used to define data, which
is what makes the system reflective.

Repo: https://github.com/TAnthonyAllen/incant
Working drafts of grammar/runtime files live in `XML/WorkingOn/`.
C++/Obj-C++ runtime files (`.twk`, `.h`, `.mm`) live at the repo root.

---

## Files to fetch at session start

When picking up this project in a new conversation, fetch these in order. The
first one is this file itself; the rest are the design surface for the
in-flight bytecode work.

- https://github.com/TAnthonyAllen/incant/blob/main/incant.md  (this file — read first)
- https://github.com/TAnthonyAllen/incant/blob/main/XML/WorkingOn/grammar
- https://github.com/TAnthonyAllen/incant/blob/main/XML/WorkingOn/setup
- https://github.com/TAnthonyAllen/incant/blob/main/XML/WorkingOn/generate
- https://github.com/TAnthonyAllen/incant/blob/main/XML/WorkingOn/utilities
- https://github.com/TAnthonyAllen/incant/blob/main/XML/WorkingOn/oneTest
- https://github.com/TAnthonyAllen/incant/blob/main/XML/WorkingOn/unitTests

If the web_fetch tool refuses any of these (intermittent behavior on github.com
in some sessions), ask the project owner to attach them directly — uploading
into the chat is reliable and fast.

The `.mm` runtime files at the repo root are not fetched proactively — pull
them only when the conversation actually needs them. The same goes for the
`.rtn` include files.

---

## Ground rules and preferences

These shape the work and shouldn't get re-litigated each session:

- **Tok is frozen for collaboration purposes.** The `.twk` files are written
  in Tok, a C++ preprocessor the project owner maintains separately. Its
  parser is hard to debug. Working alone the owner would still use Tok, but
  is happy to leave it behind when working with Claude. Read and edit the
  `.mm` files directly. Don't propose changes that would require Tok work.
  (Long-term: incant itself replaces Tok — see "The deeper goal" below.)
- **Reflectivity is a feature, not an accident.** Anything in the language
  ecosystem (bytecode, IR, generated code) should remain inspectable as a
  `GroupItem` where reasonable. This is the main argument against jumping
  straight to LLVM IR.
- **Debugger-readiness from the start.** `sourceLINE` and `sourceFILE` get
  plumbed through new code paths even before anything reads them.
- **GUI work is deferred.** A native Apple window interface for incant is
  in the plan, but only after incant is JITed and fast enough to drive it.
  Don't volunteer GUI-side concerns until the JIT work lands.
- **Two-tool workflow.** Design and architecture happen in Claude.ai chat,
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

- **The runtime stays in `.mm` for now**, but only as a means to an end.
  The eventual target is for incant code to be able to do everything the
  `.mm` runtime currently does — including emitting its own bytecode and
  driving its own JIT.
- **Reflectivity matters because incant is meant to be its own metalanguage.**
  An incant program needs to be able to see, manipulate, and generate other
  incant programs. Choices that flatten or obscure structure (e.g., emitting
  opaque LLVM IR) push against this.
- **Tok was a stopgap.** The project owner is comfortable in Tok and would
  default to it alone, but is willing to leave it behind in collaboration.
  The real successor to Tok is incant itself, once it's fast enough.

## C++ floor — settled architecture

**incant aims for a "pragmatic self-hosting" model**, not maximalist. A
small, stable C++ kernel stays permanently; everything above it migrates
to incant as the JIT makes that practical. The goal is to *program in
incant*, not to eliminate C++. C++ is leverage (LLVM, GC, NSObject, macOS
GUI), not debt.

### Stays in C++ permanently

- Bootstrap: the 32 hard-coded rules and the loader that runs `setup`/`grammar`
- Input stream and tokenizer (hot path; source-position tracking lives here)
- `GroupItem` allocator and the GC — using **BDWGC** (Boehm-Demers-Weiser),
  not writing one. Conservative, stop-the-world, mature, integrates cleanly
  with C++. Allocation switches from `new`/`malloc` to `GC_malloc`.
- LLVM JIT integration and codegen glue (use the **ORC v2** API, not MCJIT)
- Platform calls: drawing, file I/O, GUI bridge, NSObject interop
- A small set of primitive operations the JIT compiles into directly

### Migrates to incant, roughly in this order

1. Bytecode emitter (Phase 2) — `generate` rewritten to emit bytecode
   GroupItems; the prior C++-source emit path is being abandoned, not
   preserved
2. Optimization passes on bytecode (constant folding, DCE, etc.)
3. Higher-level rule actions currently in C++
4. Standard library / utility functions (`utilities` already does this)
5. Eventually: the LLVM IR emitter from bytecode, written in incant
6. Long-range stretch goal: all rule actions in incant, assuming the JIT
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
C++-side support is a small interpreter loop (`Bytecode.{h,mm}`) and
gating hook; the design center of gravity is in incant. Staged in
two halves — see "Phase 2 staging" below.

**Phase 3 — Add an LLVM JIT backend** using the ORC v2 API, with `alloca`
+ the `mem2reg` pass so we don't have to hand-manage SSA construction.
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

- Matches the reflectivity rule — a debugger written in incant inspects
  source positions through the same field-walking machinery used for
  everything else.
- Absorbs future attributes (column, span end, macro context, "inlined
  from" chain) without changing consumers.
- Costs one pointer per RuleStuff instance; allocation pressure is
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

- **The expression triples already built by `aCTionExpressioN` are proto-bytecode.**
  Each `{op, target, arg}` group with `gMethod = runOP` is essentially a
  three-address instruction. Phase 2 is not new IR design — it's
  linearization across statements, explicit branch instructions for
  control flow (if/while/for/break/continue/return), and a per-action
  vreg array. The "opcode" of an instruction is just the op GroupItem
  itself, drawn from the existing `Operators` registry plus a small set
  of new control-flow ops (`bcBR`, `bcBRZ`, `bcCALL`, `bcRET`).

- **runOP's polymorphism is statically decidable at emit time.** runOP
  dispatches across five cases (operator, C++ method, coded rule, coded
  action, generic-invokable). All five are distinguishable when the
  emitter sees the op GroupItem — by registry membership and by the
  attribute set already established during parsing. The bytecode emitter
  selects the right specialized opcode rather than emitting a generic
  RUNOP and re-doing the dispatch at runtime.

- **opAND, opOR, opIN are not short-circuiting.** Their bodies (in
  `Instruct.rtn`, with C++ versions in `GroupItem.mm`) inspect already-
  evaluated operand values. By the time runOP reaches them, both target
  and argument have been resolved. Eager linearization in the bytecode
  emitter — post-order flattening with operands materialized into vregs
  — preserves current semantics exactly. (If short-circuit `&&`/`||` are
  wanted later, they'd be added as a separate grammar-level construct
  that lowers to BR/BRZ patterns.)

- **The unboxing dance at the top of runOP** (resolving GROUP-flagged
  args, evaluating invokable subexpressions) disappears in bytecode.
  The emitter materializes subexpression results into a destination
  slot eagerly, so by the time an instruction runs, its operands are
  already values. This is also what makes the eventual LLVM lowering
  mem2reg-friendly.

- **Intermediates are flat by language design.** incant has no
  parenthetical sub-expressions and no operator precedence — expressions
  are walked right-to-left, each operation taking the previous result
  and a new operand. `B.C`, `B[C]`, `B(C)` are fused into single
  tokens at parse time, not treated as operators. As a result, at any
  point in a statement exactly **one** unnamed intermediate is live.
  This is what makes both `tempField` (interpreter) and a single-vreg-
  per-statement scheme (JIT) sufficient — there's no nested-temp
  situation to handle.

### Bytecode physical layout (phase 2)

Bytecode for a coded action is a GroupItem. The expected shape:

- Top-level GroupItem represents the bytecoded action body.
- Members are instruction GroupItems, in execution order.
- Each instruction GroupItem has:
  - tag = the opcode (the op GroupItem itself, or a `bc*` control-flow op)
  - attributes = the operands (vreg references, branch targets, literals)
  - a `sourceLine` attribute for debugger plumbing (see above)
- vregs are addressed by index; the per-action vreg array lives as a
  member or attribute on the bytecode GroupItem.

This shape is reachable from incant code through normal field access — no
C++-side special case. A coded action gains a bytecode reference as a
regular GroupItem attribute (not a new C++ field on GroupItem itself).

### What lives in C++ vs incant for phase 2

- **Emitter — incant.** *Reuses the existing `gIF`/`gFOR`/`gWhilE`/
  `gDO`/`gXpress`/`gPrinT`/`gBlocK` actions in `generate`*, rewriting
  their bodies to emit bytecode GroupItems instead of C++ source. The
  C++-source emit path is being abandoned (it was a stepping stone, not
  the JIT path), so there is no two-jobs problem. No new
  `XML/WorkingOn/bytecode` file — `generate` becomes the bytecode
  emitter. `runGenerated` stays as the dispatch hub. Names like `gIF`
  stay because they correspond directly to grammar tags (`IF`).
- **Interpreter — C++.** New file `Bytecode.{h,mm}` at repo root,
  hand-edited (not via Tok). Walks bytecode GroupItems via a single
  dispatch loop: read `instr.tag`, look up its method, call it, use
  its return value as the next ip. Small; ~200–300 lines.

  Owner will write the first cut in Tok and then switch to .mm. Pseudocode
  template for the first cut is in this file under "Step 2a interpreter
  pseudocode" below.
- **Gating hook — C++.** Where rule-action dispatch lands for a coded
  action, check whether the action has a `bytecodE` attribute and run
  `Bytecode::run()` on it; otherwise fall through to the existing
  tree-walk. Lives wherever `aCTionStatemenT` or its callers currently
  dispatch action bodies. Exact site TBD next session.

### Phase 2 first step

Pick one trivial coded action — something with one if and one arithmetic
expression — and round-trip it through emitter → bytecode GroupItem →
interpreter end-to-end before generalizing. Each new opcode added
afterward is incremental: one emitter action, one interpreter case.

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

- `bcBR` — unconditional branch. Operand: `target` (GroupItem ref to
  destination instruction).
- `bcBRZ` — branch if zero. Operands: `cond` (slot to test — `tempField`
  in step 2a, vreg ref in step 2b) and `target`.
- `bcRET` — end of action body. No operands. Explicit (not implicit
  end-of-members) so dumps are easy to read.

Notably absent: `bcCALL`, `bcMOV`, `bcCONST`. Add when a test forces them.
Existing `Operators` registry entries (`opGT`, `opMultiply`, `opAssign`,
etc.) reuse their existing identity — the bytecode interpreter dispatches
on `instr.tag` regardless of which registry it came from.

### Branch target representation — decided

Branch targets are direct GroupItem references to the destination
instruction, not integer offsets. Backpatching: when emitting a forward
branch (e.g., `gIF` emitting a `bcBRZ` to skip the then-block), append
the branch instruction with `target` unset, finish emitting the body,
then assign the now-known instruction at the join point as `target`.
No symbol tables, no offsets.

### Step 2a interpreter pseudocode (template for `Bytecode.{h,mm}`)

C++-flavored pseudocode the owner can adapt to Tok then `.mm`:

```
// Bytecode.h
class Bytecode {
public:
    static GroupItem* run(GroupItem* bytecodeBody, GroupItem* invocationContext);
};

// Bytecode.mm
GroupItem* Bytecode::run(GroupItem* body, GroupItem* ctx) {
    GroupItem* ip = body->firstMember();
    while (ip != nullptr) {
        GroupItem* opcode = ip->tag();
        Method m = lookupInterpretMethod(opcode);
        if (m == nullptr) { reportError("unknown opcode", opcode); return nullptr; }
        ip = m(ip, ctx);   // method returns next ip, or nullptr to halt
    }
    return ctx->returnValue();
}

GroupItem* runBR(GroupItem* instr, GroupItem* ctx) {
    return instr->getAttribute("target");
}

GroupItem* runBRZ(GroupItem* instr, GroupItem* ctx) {
    GroupItem* condSlot = instr->getAttribute("cond");
    GroupItem* value = condSlot->resolveValue();
    return value->isZero()
        ? instr->getAttribute("target")
        : instr->nextMember();
}

GroupItem* runRET(GroupItem* instr, GroupItem* ctx) {
    return nullptr;
}
```

Existing operator opcodes (`opGT`, `opMultiply`, `opAssign`) need to be
callable with the same `(instr, ctx) -> next-ip` signature. Two options:
write thin shim methods that pull operands from `instr` attributes and
call the existing `op*` methods, or extend the existing methods to take
`(instr, ctx)` directly. Cheapest for step 2a: shims (3 of them, ~5
lines each). Decision deferred until coding.

### Open question — dispatch attribute name

`Operators` uses `operateMethod`, the new `Bytecode` registry uses
`interpretMethod`. The dispatch hub needs to handle both. Three options:
(a) try one, fall back to the other; (b) add `interpretMethod` to
operator entries too; (c) unify under one attribute name. Leaning (a)
for minimum disruption — confirm next session.

---

## Next session — start here

We left off having designed step 2a on paper. Next concrete moves, in order:

1. **On-paper walkthrough** of what `generateCode(testByteCode)` should
   produce, instruction by instruction, with explicit GroupItem shapes.
   Validate the schema before any code lands. Expected output (step 2a):
   ```
   1: opGT       lhs=righty rhs=0  dst=tempField  sourceLine=...
   2: bcBRZ      cond=tempField target=<instr 5>  sourceLine=...
   3: opMultiply lhs=righty rhs=2  dst=tempField  sourceLine=...
   4: opAssign   target=maximus value=tempField   sourceLine=...
   5: bcRET      sourceLine=...
   ```

2. **Add `Bytecode` registry to `setup`** — three entries (`bcBR`,
   `bcBRZ`, `bcRET`), as specified in the "first cut" block above.

3. **Stub `Bytecode.h` / `Bytecode.mm`** at repo root using the
   pseudocode template above. Owner writes first cut in Tok, switches
   to `.mm`. Includes `runBR`, `runBRZ`, `runRET`, and decide-and-implement
   shims for `opGT` / `opMultiply` / `opAssign`.

4. **Resolve dispatch-attribute question** (a/b/c above) — decision
   needed before #3 lands.

5. **Rewrite `gIF`, `gXpress`, `gBlocK`** in `generate` to emit bytecode
   GroupItems instead of placeholder text. Get `testByteCode` emitting.

6. **Wire the gating hook** — find the action-dispatch site in
   `GroupRules.mm` (or wherever `aCTionStatemenT` calls action bodies)
   and add the `bytecodE` attribute check.

7. **Run `testByteCode()`** through the bytecode path. Verify
   `maximus` ends up at 26.

### Already done from the previous session's open-work list
- ✅ `sourceLine` promotion (RuleStuff::sourceLine is now a GroupItem)
- ✅ Trivial coded action picked (`testByteCode`)

### Decisions landed this session
- `gIF`/`gFOR`/etc. are repurposed in place; no new `XML/WorkingOn/bytecode` file.
- C++-source emit path (the old `generate` job) is abandoned, not preserved.
- Phase 2 is staged: 2a uses `tempField` as implicit dst; 2b switches to vregs.
- Branch targets are direct GroupItem refs, not integer offsets.
- `bcRET` is explicit (not implicit end-of-members).
- `testByteCode` confirmed as the round-trip target; expected emit is 5 instructions.

---

## File map (quick reference)

### incant source (in `XML/WorkingOn/`)
- `grammar` — incant grammar rules, loaded after bootstrap
- `setup` — registries: cOMMANDs, Operators, pROPERTIEs, Keywords, GroupFields,
  *(planned, phase 2)* Bytecode
- `generate` — bytecode emitter: `gBlocK`/`gIF`/`gFOR`/etc. dispatch table,
  rewritten in phase 2 to emit bytecode GroupItems (was: C++ source emit)
- `utilities` — JSON, layout, frame-fill, hex-color helpers
- `oneTest` — entry-point test driver
- `unitTests` — test fixtures and assertions (includes `testByteCode`,
  the phase 2 round-trip target)

### Runtime (C++/Obj-C++ at repo root)
The `.mm` files are the actual compiled source. The `.twk` files are written
in **Tok**, a C++ preprocessor that the project owner maintains separately.
Tok generates the `.mm` from the `.twk`. **For working on the language,
read the `.mm` files; ignore the `.twk` source unless the question is
specifically about Tok generation.**

- `GroupItem.{h,mm}` — the universal data type
- `GroupRules.{h,mm}` — rule machinery (parsing, action dispatch)
- `GroupMain.{h,mm}` — top-level driver, input handling
- `GroupBody.{h,mm}` — group bodies / member lists
- `GroupControl.{h,mm}` — control flow primitives
- `GroupList.{h,mm}` — list operations
- `GroupStak.{h,mm}` — stack support
- `GroupDraw.{h,mm}` — drawing/rendering (incantGUI side)
- `RuleStuff.{h,mm}` — rule helper utilities
- `Layout.{h,mm}` — layout engine
- `groups.{C,h,mm}` — top-level group handling
- `Bytecode.{h,mm}` — *(planned, phase 2)* bytecode interpreter and gating hook

### Other
- `Generate.rtn`, `Debug.rtn`, `Instruct.rtn`, `parse.rtn`,
  `ruleActions.rtn`, `GroupActions.rtn` — source-code include files
  (split out of larger `.mm` files to keep work-in-progress sections
  easier to edit; `#include`d into the corresponding implementation file)
- `cppMacros`, `groupDirectives`, `groupIncludes` — build/include helpers
- `Stylish.twk` — styling

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
