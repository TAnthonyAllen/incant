# incant — Project State & Design Notes

A living document capturing where the incant compiler/runtime project stands,
the decisions made, and the questions still open. Read this first when picking
up the project after a break, or when bringing a new conversation up to speed.

Last updated: 2026-04-25

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

1. Code generation logic (`generate` file is already mostly there)
2. Bytecode emitter (Phase 2 of the plan — natural next step)
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

## The current goal

Move incant from pure interpretation toward a bytecode/JIT compilation pipeline,
in service of the self-hosting goal above.

### Phased plan

**Phase 0 — Integrate BDWGC.** Switch `GroupItem` allocation from manual
`new`/`malloc` to `GC_malloc`. Touches every allocation site but is largely
mechanical. Done before serious JIT work because doing it during would
conflate two sources of bugs.

Phase 0 is simpler than it would be in most C++ codebases:
- **No destructors are in use.** The only manual cleanup is a small number
  of `delete` calls that should just go away once GC handles lifetime.
- **The project owner has prior experience with Apple's GC** without issues,
  so the conceptual model is familiar. BDWGC is the same idea with a
  different name.
- **NSObject interop is a future concern, not a current one.** A native
  Apple window interface is planned but deferred until incant is JITed and
  fast. Until then, the GC/NSObject-lifetime question doesn't bite.

**Phase 1 — Fix and flesh out `generateCode()`** so it produces a real,
useful IR (which we've decided is bytecode — see below).

**Phase 2 — Build a bytecode emitter in incant itself**, modeled on the
existing `generate` file (which already walks statements via a hashed
dispatch table — `gBlock`, `gDo`, `gFor`, `gIf`, `gWhile`, `gXpress`, etc.).
Bytecode is represented as a `GroupItem` so it stays inspectable and
manipulable from incant code.

**Phase 3 — Add an LLVM JIT backend** using the ORC v2 API, with `alloca`
+ the `mem2reg` pass so we don't have to hand-manage SSA construction.
LLVM converts stack slots to SSA registers automatically. The JIT consumes
bytecode and emits machine code; bytecode remains the canonical IR.

### Cross-cutting concern: debugger-readiness

`sourceLINE` and `sourceFILE` fields have been added to the relevant data
structures but are not yet populated or consumed. They're future-proofing
for an incant debugger. Any new code that handles tokens, expressions, or
statements should plumb these through from the start, even if nothing reads
them yet.

---

## Key insight from the last grammar revision

The expression grammar was reworked so that `ExpressioN` now hands its action
a **list of resolved tokens** (sometimes a single token). Token resolution
happens in `TokenXP`, which handles:

- Simple tokens: `A`, `B`
- Invocations: `A(B)`, `A()`
- Member access: `A.B`
- Nested cases: `A(C.D)` where `C.D` itself must be invoked before being
  passed to `A`

Invocation goes through `runOP(token)`. So a parsed expression like
`A = B + C` becomes a flat token list with operator tokens that, when walked,
produce a `GroupItem` result.

**Why this matters for bytecode:** the token list is already linearized.
A bytecode emitter is essentially a token-list walker that emits opcodes
instead of invoking `runOP` directly. The transformation should be local and
mechanical — no separate AST traversal needed.

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

Open sub-questions on bytecode design — to be answered when we start Phase 2:

- Stack machine vs register machine for the bytecode VM?
- Opcode set: how primitive? Mostly `runOP`-flavored, or finer-grained?
- Encoding: how is bytecode laid out as a `GroupItem` structure?
- Relationship to the token list `ExpressioN` already produces — is the
  token list essentially proto-bytecode, or a separate representation?

---

## What we were about to look at when we paused

How the input stream is managed in `GroupRules.twk` and `GroupMain.twk`.
The motivation: this is where source-position tracking would hook in for
the eventual debugger, and understanding the read path will inform how
`generateCode` consumes its input.

**Next concrete step:** fetch `GroupRules.twk` and `GroupMain.twk`,
focusing on:

- Where the input stream is read and tokenized
- Where line/column counters live (or where they'd need to be added)
- How `aCTionExpressioN` and `aCTionTokenXP` access the token stream
- Whether `sourceLINE`/`sourceFILE` are wired in but unused, or not yet wired

---

## State of `generateCode` today

Working but skeletal. The structure is in place — `generateCode(action)`
parses the action and produces something that gets handed to `interpret()`
(see `generate` file, `generateAction` rule). The `generator` hash dispatches
per-statement-type to `gBlock`, `gFor`, `gIf`, etc.

Intentionally not flushed out further until the bytecode/IR question above
is settled. No point writing emitters when we don't yet know what they
emit.

---

## File map (quick reference)

### incant source (in `XML/WorkingOn/`)
- `grammar` — incant grammar rules, loaded after bootstrap
- `setup` — registries: cOMMANDs, Operators, pROPERTIEs, Keywords, GroupFields
- `generate` — code generation actions (the `gBlock`/`gFor`/etc. dispatch table)
- `utilities` — JSON, layout, frame-fill, hex-color helpers
- `oneTest` — entry-point test driver
- `unitTests` — test fixtures and assertions

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
