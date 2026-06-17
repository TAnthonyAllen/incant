# CLAUDE.md — Incant Repository

This file orients Claude Code (Clod) when working in this repository.
Read `projectBible.md` for the full ecosystem context (PLG/TAWK/Incant).

---

## What Incant Is

Incant is the third project in the ecosystem: **PLG recognizes, TAWK transforms, Incant reasons.**

Incant is a reflexive, homoiconic, stack-aware language. Code and data have the same structure — a GroupItem field IS the rule that describes it. Programs construct, inspect, and rewrite their own structure. The bytecode IR is itself a tree of GroupItems, walked by an `interpret()` written in incant.

The runtime is C++/Objective-C++; the language surface is `.twk` source compiled to `.mm` via TAWK.

---

## Repository Structure

```
Groups/
├── GroupItem.{twk,mm,h}    — Core GroupItem class. Doubly-linked tree node. Polymorphic data
│                              (string, number, group, buffer, set, regex, etc.). BDWGC-managed.
├── GroupBody.{twk,mm,h}    — Storage container backing a GroupItem. Tag, registry, list pointers,
│                              union-based polymorphic data.
├── GroupControl.{twk,mm,h} — Factory + registry manager. Singleton (groupController). itemFactory
│                              path is gone; constructors are now the only path.
├── GroupRules.{twk,mm,h}   — Recursive-descent parser/runtime. pushInput/popInput, checkSkip,
│                              setGuard, action dispatch. The bytecode gating hook lives at
│                              GroupRules.mm:786.
├── GroupMain.{twk,mm,h}    — main() entry point. Bootstraps, loads input, runs parse.
├── GroupDraw.{twk,mm,h}    — Drawing primitives for GUI work (HPDL).
├── GroupList.{twk,mm,h}    — DoubleLinkList wrapper.
├── GroupStak.{twk,mm}      — Stack support for the runtime.
├── RuleStuff.{twk,mm,h}    — Rule metadata: labels, guards, repetition, onSuccess/onFail wiring.
├── GroupHash.{twk,mm,h}    — Hash-based GroupItem lookup.
├── Bytecode.{mm,h}         — Phase Bytecode interpreter handlers (runBR, runBRZ, etc.)
├── parts.twk, action.twk   — Supporting source.
├── Generate.rtn            — Runtime: generateCode() bridge from C++ into incant emitter.
├── GroupActions.rtn        — Runtime action definitions.
├── grammar                 — Bootstrap grammar — 32 seed rules.
├── groupIncludes           — Include manifest for the build.
├── groupDirectives         — TAWK directive file for Incant classes.
├── incant/                 — Active incant source files (setup, grammar, generate, bytecode,
│                              directives, oneTest, unitTests, utilities). Promoted from
│                              XML/WorkingOn/ on 2026-05-29.
├── XML/                    — Window-definition DSL files. 12 subdirs of GUI material
│                              staged for later conversion-to-incant work.
├── Maps/                   — Symlink → ~/data/support/Maps (BitMAP, Segment).
└── projectBible.md, TODO.md, CLAUDE.md
```

**Symlinked support classes** (Frame, Include, KeyTable, Maps) live once in
`~/data/support/`. The InProcess paths are symlinks that keep existing
`.twk` `include` directives working unchanged.

**Backup directories** (`Aside/`, `BackupIncant/`, `BeforeRefactor/`, `BeforeSave/`)
are gitignored. Incant repo IS the backup; no separate copies needed.

---

## File Types

- `.twk` — TAWK source. **Source of truth.** Compile with `tok FileName.twk` → `.mm`.
- `.mm` — Generated Objective-C++. Do not edit by hand when the `.twk` pipeline is reliable.
- `.h` — Generated headers.
- `.rtn` — Runtime files: action definitions, control flow, C++ glue.
- Files with no extension (`grammar`, `groupIncludes`, `groupDirectives`) — TAWK manifests / directive files.

**Workflow note (temporary):** the TAWK runtime replacement (Phase Integrate)
is in flight. While that's pending, some `.mm` edits are hand-applied and
not yet back-ported to `.twk`. Once Phase Integrate lands, `.twk` becomes
the authoritative source again across the board. Check the bible's "TAWK
Runtime Replacement (Phase Integrate)" section for the current state
before assuming.

---

## Build Workflow

```bash
# 1. Edit .twk source
# 2. Regenerate .mm
tok GroupItem.twk    # produces GroupItem.mm + GroupItem.h
# (repeat for each changed .twk)

# 3. Compile via command-line C++ compiler
#    (incantGUI Xcode target work is out of scope for the current Phase Bytecode arc)
# 4. Run
./groups <input_file>
```

Same TAWK quirks as the rest of the ecosystem (see Parse/CLAUDE.md or the
bible's TAWK Known Issues table):
- Empty `//` lines reset field-resolution context — remove from method bodies
- `field = new` sometimes fails type inference — use `field = new ClassName()`
- Re-tawk drops `#include` lines and include guards in `.h` — re-add manually
- `extern "C"` blocks get clobbered on re-tawk — keep C-linkage in hand-written files

---

## Core Architecture

### GroupItem
The universal tree node. Every value, rule, field, and bytecode op is a
GroupItem. Boehm-GC managed (inherits from `gc`); no manual `delete`.

```cpp
GroupItem *item = new GroupItem("name");
GroupItem *item = new GroupItem("name", value);
```

Data types (via `data` field): `isCOUNT`, `isNUMBER`, `isSTRING`, `isTOKEN`,
`isCHAR`, `isSET`, `isGROUP`, `isHASH`, `isBUFFER`, `isSTAK`, `isREGEX`,
`isMAP`, `isOBJECT`. Affiliation: `isAttribute` vs `isMember` vs `isEmbedded`.

### Rule System
Rules carry guards, labels, modifiers, and actions. Modifier characters:
`+ * ?` (repetition), `!` (banged/negation), `<` (noAdvance), `^` (noSkip),
`{ }` (upTo / upToOver), `% & @ |` (semantic markers), `_` (unGuarded),
`$` (isMacro), `-` (noLabel).

### List Navigation
```cpp
group->next(current);          // next in list
group->nextAttribute(current); // next attribute only
group->nextMember(current);    // next member only
```

For recursive contexts use the safe pattern (shared `entry` state in default
`next()` gets clobbered by nested calls):
```cpp
for (DoubleLink *link = list->first; link; link = link->next) {
    GroupItem *item = (GroupItem*)link->value;
}
```

### Registry / Scope
```cpp
locate("name");                // current scope
locateInMethod("name");        // method scope
getRegistry("RegistryName");   // named registry
```

`GroupControl::groupController` is the singleton entry point.

---

## Phase Bytecode

The old C++-source emit path is being **abandoned**, not preserved. The new
target is **bytecode as canonical IR**, represented as GroupItems so incant
code can construct and walk it.

**Phase JIT does NOT go through bytecode (2026-06-17 decision).** Bytecode and
JIT are *parallel, independent lowerings* of the same cached BlocK — not a
pipeline. LLVM IR comes straight from the ops/BlocK (the incant ops emit IR
directly via a `jitting` gate), **not** from `bcLIST`. The prior "LLVM IR
generated from bytecode" plan is superseded. Full rationale:
`docs/llvm-jit-recon.md` (ADDENDUM section) and the `jit-design.md` /
`jit.md` design pair.

### Pipeline

1. Parse builds GroupItem trees (unchanged).
2. `generateCode(action)` in `Generate.rtn` — C++ entry. Looks up the incant
   `generatE` action and runs it.
3. `generatE` (in `incant/generate`) — top-level emitter. Walks
   fields and dispatches via `runGenerated`.
4. `runGenerated` — dispatch hub. Looks up handler in the `generator`
   registry by statement kind.
5. Per-statement handlers (`gBlocK`, `gIF`, `gFOR`, `gWhilE`, `gDO`,
   `gExpressioN`, `gXpress`, `gPrinT`, `gDeclare`) — emit bytecode
   GroupItems. **`gIF`, `gXpress`, and the `aCTionExpressioN`-built
   `revisedList` (the `gExpressioN` path) are live** — they carry
   `testByteCode` to `maximus = 26` (see Status).
6. `interpret(bytecode)` — the dispatch loop. Written in incant
   (`incant/bytecode`). Walks the bytecode stream; each op
   GroupItem's `interpret` sub-attribute is the handler.

### Settled design decisions

1. **Op identity** — an instruction's tag IS the op GroupItem itself. Drawn
   from `Operators` (for `>`, `*`, `=`) plus `bcOPs` (for `bcBR`, `bcBRZ`,
   `bcRET`).
2. **Two registries** — `Operators` and `bcOPs` are separate. User code
   walking `Operators` should not see control-flow ops.
3. **Implicit-next dispatch** — instructions are members of the body in
   execution order. Branch ops override by reassigning `grup` mid-loop.
4. **Bytecodes are GroupItems.** No vregs as separate objects — "a virtual
   register is just a GroupItem field."

### Status

| Component | State |
|---|---|
| `interpret()` (in incant) | ✅ Written |
| `Bytecode.{h,mm}` (C++ handlers) | ✅ Written |
| Gating hook in `GroupRules.mm:786` | ✅ Wired (falls through to gMethod when no bytecode) |
| `bcOPs` registry | ✅ Defined |
| `gIF` emitter | ✅ emit correct — then *and* else arms (condition via `gXpress`, `bcBRZ`→`elseLabel`/`endLabel`, then-branch, `bcBR`, `elseLabel`, else body, `endLabel`); **unique labels** `bcLabel<n>` via `:=` + `labelIndex` (2026-06-10) |
| `gXpress` emitter | ✅ Live — emits push-ops/operators from a `revisedList`'s members |
| `gExpressioN` path | ✅ Live — `aCTionExpressioN` builds the `revisedList` that `gXpress` walks |
| `testByteCode` / `testIfElse` end-to-end | ✅ **branches taken** — `testByteCode` false→11, `testIfElse`→26, both through the **C++ `interpretBC`** dispatch loop (9-op / 13-op `bcLIST`) |

**The branch works — via the C++ dispatch loop (resolved 2026-06-11).** The 2026-06-09 deep
dive (`docs/branch-mechanism.md`) concluded the branch wasn't expressible in interpreted
incant and prescribed moving the dispatch loop to C++. A 2026-06-10 claim that the incant
`interpretBC` took the branch was a **shape-read** — under a clean run it fell straight
through (`testByteCode`→26, `testIfElse`→7). Two entangled incant blockers were the cause:
(A) `grup := result` **welds** the test variable to the branch-target node (bear-trap #3 —
`=`/setContent can't re-tag, so it can't be reset); (B) `aCTionFOR` advances its **own**
C++ cursor, so a body `:=` can't steer iteration. The fix was Clay's: a small **C++
`interpretBC`** (`GroupActions.rtn`) with a plain C++ cursor — no `:=`/byRef weld, and
`nextGroup` is stateless so it relocates to an arbitrary branch-target member cleanly.
`runByteFn` returns the target stream-member on a taken branch; the loop relocates by tag,
else `nextMember`. Also fixed: `runBR` (Bytecode.twk) now mirrors `runBRZ`'s attribute-walk
(was a dead `getFromList("dst")`). Verified: `testByteCode` false→**11**, `testIfElse`
true→**26** (init `maximus=11`; no-op→11/11, straight-through→26/7, correct branching→11/26).
The incant `interpretBC` is retired; `branch-mechanism.md` is vindicated (kept as the
reasoning trail; see `docs/branch-dispatch-findings.md` for the resolution). Remaining:
broaden the bytecode-generation POP (more statement forms, `gPrinT` proper emit, `gDeclare`,
real field refs vs folded values).

### Incant Dispatch Idiom (IMPORTANT)
Two steps — never chain:
```
handler = field.attribute;    // get the attribute
handler(argument);            // call its method
```
One method per field by design. Sub-attribute pattern for second invokable behavior.

---

## XML Directory

`XML/` is a window-definition DSL — XML-flavored declarative incant. Tags
are GroupItem field declarations; attributes are sub-fields; bodies can be
content, nested fields, or — when an attribute names an event (e.g.
`onLayout`) — incant action code. Closing-tag conventions are lax (one `</tag>`
can pop several opens).

The 11 `XML/` subdirectories (`Windows/`, `Controls/`, `Notions/`, `NotGUI/`,
`Tests/`, `HTML/`, `LLVM/`, `Generating/`, `Stash/`, `Groups/`, `WorkingOn/`,
`BackupXML/`-gitignored) are GUI-arc material — staged for the
conversion-to-incant work that's part of the long-term GUI thread. The
active incant source files (setup, grammar, generate, bytecode, directives,
oneTest, unitTests, utilities) now live at the top-level `incant/` directory
(2026-05-29 promotion); see "Repository Structure" above.

---

## Current State

### Working ✅
- Incant parses and interprets itself
- BDWGC integration complete (Phase 0)
- `generateCode()` repurposed as bytecode emitter entry point (Phase 1)
- Bytecode interpreter: **C++ `interpretBC` dispatch loop** (`GroupActions.rtn`) + C++ op handlers (`Bytecode.twk`/`.mm`)
- Gating hook wired at `GroupRules.mm:786`
- Emit path is live and correct: `gIF` (then **and** else arms), `gXpress`, and
  the `gExpressioN`/`revisedList` path all emit; the C++ `interpretBC` runs the stream.
  `testByteCode` emits a 9-op `bcLIST`, `testIfElse` a 13-op `bcLIST`, and `testPrint`
  produces `"hello world"` (via the `gPrinT` thunk).
  **Branch execution works (2026-06-11) via the C++ `interpretBC`:** `testByteCode` false→11
  and `testIfElse` true→26 run correctly (init `maximus=11`; only correct branching yields
  11/26). The plain C++ cursor sidesteps the `:=`/byRef weld and `aCTionFOR`'s non-steerable
  advance that blocked the incant loop; `runBR` was also fixed to mirror `runBRZ`'s
  attribute-walk. The incant `interpretBC` is retired. See `docs/branch-dispatch-findings.md`.

### In Progress
- **Broaden the bytecode-generation POP.** Branch execution is **done** — it works via the
  C++ `interpretBC` dispatch loop (see above). Next proof points as generation work
  continues: more statement forms, real field references vs folded values, `gPrinT` proper
  emit, `gDeclare`. (`docs/branch-mechanism.md`'s C++-dispatch conclusion was vindicated;
  kept as the 2026-06-09 reasoning trail.)

### Next
- `gPrinT` proper bytecode emit (currently a thunk that re-fires `aCTionPrinT`)
- `gDeclare` verification
- More test cases beyond `testByteCode` / `testIfElse`
- Phase JIT: LLVM IR straight from the ops/BlocK (parallel to bytecode, not from it) (HPDL)

**Out of scope for current arc:** `Bytecode.mm` into the incantGUI Xcode
target. Phase Bytecode proceeds via the command-line C++ compiler path.

---

## Testing

```
testByteCode / testIfElse fixtures in incant/generate; init maximus=11, righty=13 (unitTests:82)
  testByteCode code={ if righty <= 0; maximus = righty * 2; };
    emit (9 ops): bcPushField 13 · bcPushLit 0 · <= · bcBRZ ·
                  bcPushField 13 · bcPushLit 2 · * · bcStoreField · bcLabel1
    outcome: maximus = 11  ✅ — bcBRZ branches past the then-arm (false condition)
  testIfElse code={ if righty > 0; maximus = righty * 2; else maximus = 7; };
    emit (13 ops): … bcBRZ→bcLabel2 … bcBR→bcLabel1 · bcLabel2 · …else… · bcLabel1
    outcome: maximus = 26  ✅ — then runs, bcBR jumps to bcLabel1 skipping else
  Both run through the C++ `interpretBC` dispatch loop (2026-06-11). Labels are the
  unique, space-free `bcLabel1`/`bcLabel2` ($-suppressed). Only correct branching in
  both directions yields 11/26 (no-op→11/11, straight-through→26/7).
```

Note: `oneTest` currently runs `generateAction(testByteCode); stop();` at the top, so
`testByteCode` (→ `maximus = 11`) runs directly from `oneTest`. For `testIfElse` (or any
other fixture) drive it with a small scratch file that includes `unitTests`/`generate`/
`utilities`, sets the search list, then `generateAction(<fixture>); stop();` — single pass
(a second generate on the same action still hits the sequential-state-corruption tar baby).

`Tests/test.json` — sample widget definition for JSON/XML parsing exercises.

---

## Debugging

Flags in scope:
- `debugAllRules` — trace all rule matching
- `debugGuards` — show guard evaluation
- `debugRule` — debug specific rule (set with `debugRuleNamed("RuleName")`)

Use `groupDirectives` for ephemeral instrumentation — TAWK directive files
let you inject trace code without polluting `.twk` source. See the bible's
"TAWK Directives used in anger" entry.

---

## Bear Traps

Hard-won lessons. Each one has cost real debugging time.

1. **`=` tag-imposition (opAssign → setContent)** — `A = B` copies B's content into A
   but reimprints A's own tag. B's tag does not transfer. `endLabel = new("bcLabel1")`
   gives a node tagged `endLabel`, not `bcLabel1`. Use `:=` when the argument's tag
   must survive.

2. **`setContent` method-drop** — `=` (setContent) drops method bindings on copied
   content. A `copyOf` through `=` loses its `interpret` child's method. The inline
   `copyOf → +% → emitBC` path preserves it; an intermediate `=` assignment does not.

3. **`byRef` sticky** — `:=` stamps `byRef` on the argument permanently. Any later `=`
   on that same field also references instead of copying. Audit `:=` sites whose fields
   later get legitimately `=`-copied (see TODO audit note).

4. **`//` comments in `.rtn` method bodies** — cascade field-resolution bleed into
   following externs. Keep them out of method bodies entirely. Doc goes in the block
   comment above the method.

5. **`tok` drops `#include` lines and include guards on retok** — re-add manually.

6. **`extern "C"` blocks clobbered on retok** — keep C-linkage in hand-written files.

7. **`immediateAction` binding — bare usually works; verify dispatch.** Bare
   `name immediateAction;` binds to the extern named `name`, and works for the common
   case — `copyOf`, `dumpContents`, and `testing` are all registered bare. The
   `=method` form (`x immediateAction=processFlags;`) is only needed to bind a command
   to a *differently*-named extern. **Exception:** `runByteFn` had to be
   `runByteFn immediateAction=runByteFn;` — the bare form silently failed to bind there
   (setRuleAction reads the method name from `item.text`). Cause of the asymmetry vs the
   bare-works cases is unreconciled; if a bare registration doesn't dispatch, switch to
   the explicit `=name` form.

8. **`setGroup: cannot add group to itself`** — benign but noisy. Caused by a redundant
   `:generator bcLIST` rebind inside `emitBC` scope.

---

## The `testing` Command

```
testing(actionName);
```

Scratch verification harness in `Commands.rtn`. Primes a fresh list-typed `bcLIST`
on the generator (same way `generateCode` does), runs the named action's body against
it, returns `generator["bcLIST"]` for inspection.

Use instead of `generateCode` for isolated emit verification — run it, dump the
result, verify the structure before wiring into real code. When the next verification
need arises, rewrite the C++ body to focus on it. No new command method needed.

Invocation: `testing(testBRZEmit);` in `oneTest`.

**NB:** keep the C++ body free of `//` comments — bear trap #4 applies. (`testing()` lives
in `Commands.rtn` and is regenerated by `tok GroupRules.twk` like any other extern — it is
*not* a hand-applied `.mm` edit.)

---

## Working Relationship

**Anthony (Tony, Haps)** — architect, domain expert, final authority.
**Clay** (Claude at claude.ai) — design, reasoning, architecture, HWF navigation.
**Clod** (Claude Code) — execution, file edits, GitHub, build verification.

**Standing permissions**: Clod changes any code in source directories
without asking. Trivial repo operations (commits, pushes for routine
work) happen at Clod's discretion; flag non-trivial or uncertain
situations before acting. Same commit-and-push freedom — no
verification round-trip on routine work.

**Resurrection-reader standard**: this file (and the bible, TODO, HWF, all
project `.md` files) must read clean to fresh-Claude tomorrow with no
memory of today. See bible's Working Relationship section for the full
statement.

See `projectBible.md` for full glossary, HWF protocol, and ecosystem context.
