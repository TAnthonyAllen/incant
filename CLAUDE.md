# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Read incant.md for current project state and architecture decisions. That document is the source of truth for ongoing design choices, including any guidance here that has gone out of date.

Phase 0 (BDWGC integration) is complete. Phase 1 (`generateCode` repurposed as bytecode emitter entry point) complete in spirit — the placeholder C++-source emit path is being abandoned. Phase 2 (bytecode emitter in incant) is **in progress**: the three design questions are decided (see "Code Generation" section below), Phase 2 is now ready to implement. See incant.md for the canonical plan and TODO.md for the immediate task list.

**Workflow note (temporary):** Currently edit `.mm` files directly, not `.twk`. The TAWK autopsy is pending; once it lands, `.twk` becomes the preferred source again.

Ask before making non-obvious changes.

This is the **Groups** system - a custom parser-generator and rule-based language processing framework. The codebase is written in **tok**, a custom language that compiles to Objective-C++. Groups implements a domain-specific language (DSL) for defining parsing rules and generating C++ code. The system uses a recursive descent parser with a custom syntax and compiles to native code.

## Core Architecture

### Language Pipeline
The system processes files through multiple stages:
1. **Source files (.twk)** - Source files written in the tok custom language
2. **Compilation** - `tok` compiler transpiles .twk files to Objective-C++ (.mm files)
   - Example: `tok GroupItem.twk` → produces `GroupItem.mm`
3. **Runtime (.rtn)** - Runtime instruction files containing action definitions and control flow
4. **Native compilation** - .mm files compiled to native code

### Key Components

**GroupItem (GroupItem.h/mm/twk)**
- Core doubly-linked list structure for representing parsed elements
- Uses Boehm garbage collector (gc/gc_cpp.h) for automatic memory management
- Supports multiple data types via unions: strings, numbers, groups, buffers, regex, etc.
- Contains affiliation system: attributes vs members (isAttribute/isMember)
- Provides recursive tree navigation with parent/child relationships

**GroupBody (GroupBody.h)**
- Storage container for GroupItem data
- Manages tag, registry, linked list pointers (first/last), and listLength
- Contains union-based polymorphic data storage (gText, gBuffer, gGroup, gNumber, etc.)
- Implements bitfield flags for item properties (debugged, isLabel, isRule, etc.)

**GroupRules (GroupRules.h/mm)**
- Core parsing engine implementing recursive descent parsing
- Manages rule execution, input stacks, and parsing state
- Contains debugging infrastructure (debugAllRules, debugGuards flags)
- Handles input diversion, blocking (Python-like indentation), and code generation
- Key methods: pushInput(), popInput(), checkSkip(), setGuard()

**GroupControl (GroupControl.h/mm)**
- Factory for creating GroupItems
- Manages registries (symbol tables) for different scopes
- Singleton pattern via static groupController
- Methods: itemFactory(), locate(), getRegistry(), setBaseRegistries()

**RuleStuff (RuleStuff.h/mm/twk)**
- Metadata about parsing rules (labels, guards, min/max repetition)
- Tracks what follows a rule (onSuccess, onTrack, onGroup, onFail)

**GroupHash (GroupHash.h/mm/twk)**
- Hash-based lookup for groups
- Used for efficient registry/symbol table access

### Rule System

The Groups language defines parsing rules with:
- **Guards** - Character sets or tokens that must match for rule to apply
- **Labels** - Named captures (e.g., `name=[a-zA-Z]+`)
- **Modifiers** - Control rule behavior:
  - `+` plus (one or more)
  - `*` star (zero or more)
  - `?` question (optional)
  - `!` banged (negation)
  - `<` noAdvance (don't consume input)
  - `%` isPercent
  - `&` isPointer
  - `@` isTarget
  - `|` isAlternate
  - `-` noLabel
  - `_` unGuarded
  - `^` noSkip
  - `{` upTo
  - `}` upToOver
  - `$` isMacro
- **Attributes** - Rule properties starting with `:` (e.g., `MemberS=':'`)
- **Actions** - Code executed when rule matches (aCTion* functions)

### File Organization

**Source Structure:**
- `.twk` files - tok language source files (49 files in this codebase) - compiled by `tok` to produce .mm files
- `.mm` files - Objective-C++ implementation (generated from .twk or hand-written)
- `.h` files - C++ headers
- `.rtn` files - Runtime action/instruction definitions (text-based)

**Key Directories:**
- `GUI/` - Graphical interface components (Bwana.*, Control.*, Actions.*, etc.)
- `Aside/`, `BeforeRefactor/`, `BeforeSave/` - Backup/archive directories
- `Maps/` - Mapping data structures
- `XML/` - XML processing support
- `Tests/` - Test files (test.json is a sample widget definition)

**Include Dependencies (groupIncludes):**
The build system expects these includes in order:
1. `/Users/anthony/Dropbox/data/InProcess/Include/globals`
2. `/Users/anthony/Dropbox/data/InProcess/Include/frame`
3. `/Users/anthony/Dropbox/data/InProcess/Include/plg.ext`
4. `/Users/anthony/Dropbox/data/InProcess/Include/maps`
5. `/Users/anthony/Dropbox/data/InProcess/Include/OCframe`
6. `/Users/anthony/Dropbox/data/InProcess/Include/groups.ext`

## tok Language Features

The tok language has special directives that control code generation:

- **`#import <header>`** - Adds an import statement to the generated .h file
  - Example: `#import <Cocoa/Cocoa.h>` in .twk → appears in generated .h file
- **`#autoGetSet`** - Automatically generates getter/setter methods (seen in GroupItem.twk)
- **`include <file>`** - Includes another file (e.g., `include groupIncludes`)
- **`use <variable>`** - Provides convenient access to fields/methods of a variable within a block

tok syntax also supports:
- **Class inheritance** - Uses `extends` keyword instead of C++ `:` syntax
  - tok: `class MyClass extends gc { ... }` compiles to C++: `class MyClass : public gc { ... }`
- Boolean bitfield declarations (e.g., `boolean GroupOptions { ... }`)
- Type specifications with bit widths (e.g., `affiliation:2[isAttribute isMember isEmbedded]`)
- Simplified switch/case and if/else syntax
- Member access operators that compile to C++ pointer/reference syntax

## Development Workflow

### Building
1. **Compile .twk files to .mm using tok compiler:**
   ```bash
   tok GroupItem.twk    # Produces GroupItem.mm
   tok GroupControl.twk # Produces GroupControl.mm
   # ... repeat for other .twk files
   ```

2. **Compile the generated .mm files** (and hand-written .mm files) to native code using your C++ compiler

3. **Link and create executable**

The main entry point is `groups.mm` which contains `main()`. The system:
1. Creates GroupMain instance
2. Calls bootstrapper() to set up core rules
3. Loads input file specified as command-line argument
4. Parses input using the rule system

### Running
```bash
# Run with an input file
./groups <input_file>
```

The program reads a file and parses it according to the loaded rules.

### Debugging
The system has extensive debugging support controlled by flags:
- `debugAllRules` - Trace all rule matching
- `debugGuards` - Show guard evaluation
- `debugRule` - Debug specific rules
- Use `debugRuleNamed("RuleName")` to enable debugging for specific rules
- Debug directives are in `groupDirectives` file

### Key Debugging Hooks (from groupDirectives)
Toggle debugging in specific functions/actions by uncommenting directives:
- Global debugging: `debugGuards = true;` or `debugAllRules = true;`
- Per-rule: `debugRuleNamed("DefinE");`
- Per-action: Add debugging flag to specific aCTion* functions

## Code Generation — Phase 2 (bytecode, in progress)

The old C++-source emit path is **being abandoned**, not preserved. The new target is **bytecode as canonical IR**, represented as GroupItems so incant code can construct, inspect, and manipulate it. LLVM IR (Phase 3) will be generated *from* bytecode for the JIT.

### Pipeline as it currently stands

1. **Parse phase** — rules match input, build GroupItem trees (unchanged).
2. **`generateCode(action)`** in `Generate.rtn:30-40` — C++ entry point. Looks up the incant `generatE` action and runs it. This is the bridge from the runtime into the incant-side emitter.
3. **`generatE`** in `XML/WorkingOn/generate:118-122` — top-level emitter, walks fields and dispatches via `runGenerated`.
4. **`runGenerated`** in `XML/WorkingOn/generate:58-65` — dispatch hub. Looks up handler in the `generator` registry by statement kind.
5. **Per-statement handlers** (`gBlocK`, `gIF`, `gFOR`, `gWhilE`, `gDO`, `gExpressioN`, `gXpress`, `gPrinT`) — currently emit C++ source via `print` statements. **All to be rewritten** to emit bytecode GroupItems.
6. **`interpret(generated)`** — called from `generateAction` after `generateCode` returns. **Does not yet exist.** Implementation lives in the planned `Bytecode.{h,mm}` and walks the bytecode GroupItem stream.

### Handler status

| Handler | Status |
|---|---|
| `gBlocK`, `gFOR`, `gWhilE`, `gDO`, `gDeclare` | Functional but emit old-style C++ source — to be rewritten as bytecode emitters |
| `gIF` | Stub (`print "generate if statement"; **argument`) |
| `gExpressioN` | Stub (`print "Need to work out how to generate an expression"`) |
| `gXpress` | Stub (`print "Saw xpress" argument`) |
| `gPrinT` | Stub — currently delegates to `genPrint()` (old printf-style C++ generator in `Generate.rtn:45-93`) |

### Bytecode-side missing pieces

- **`bcOPs` registry** in `setup` — separate from `Operators`. Holds the new control-flow ops (`bcBR`, `bcBRZ`, `bcRET`, etc.) so user code walking `Operators` doesn't see them. Not yet defined.
- **C++ handlers** at repo root (`Bytecode.{h,mm}` or folded in nearby) — the per-op handlers (`runBR`, `runBRZ`, `runRET`, plus thin shims for `opGT` / `opMultiply` / `opAssign`). Not yet written.
- **Gating hook** — somewhere near `aCTionStatemenT`'s action-dispatch site, check for a `bytecodE` attribute on the coded action and route through the bytecode `interpret()` when present. Not yet wired.
- **`interpret()`** — the dispatch loop. Open question whether to write it in incant or in C++ (see TODO.md "Open assessment").

### Round-trip target

`testByteCode` in `XML/WorkingOn/unitTests:116-117`:
```
testByteCode; { if righty > 0; maximus = righty * 2; }
```
Expected emit (per `incant.md`'s 5-instruction walk-through): `runGT`, `runBRZ`, `runMultiply`, `runAssign`, `runRET`. Verify `maximus` ends up at 26.

### Three design questions — DECIDED

1. **Handler identity on instructions** — the instruction's tag is the **op GroupItem itself**, drawn from the existing `Operators` registry (for `>`, `*`, `=`, etc.) plus a new `bcOPs` registry (for `bcBR`, `bcBRZ`, `bcRET`, etc.). The op GroupItem carries the handler reference; the interpreter dispatches via that reference (`runOP`-style).
2. **Dispatch registry split** — `Operators` and `bcOPs` are **separate registries**, *not* folded together. User-level operators stay in `Operators`; bytecode control-flow ops live in `bcOPs`. An incant program walking `Operators` should not see `bcBR`.
3. **Instruction successor** — **implicit-next** (sibling member). Instructions are members of the body in execution order; "next" means "next sibling member." Branches override by returning their target. Operands materialize into vregs (Phase-2 step 2b applies; the `tempField` intermediate stage is being skipped).

See `incant.md` for the broader discussion and `Sessions/incant-bytecode-session.md` for the design reasoning these choices flow from.

## Data Type System

GroupItem supports these data types (via `data` field):
- `isCOUNT` - Integer count
- `isNUMBER` - Floating point (double)
- `isSTRING` - String with length
- `isTOKEN` - Text token
- `isCHAR` - Single character
- `isSET` - Character set (PLGset)
- `isGROUP` - Nested group
- `isHASH` - Hash table
- `isBUFFER` - Text buffer
- `isSTAK` - Stack structure
- `isREGEX` - Regular expression
- `isMAP` - Bitmap
- `isOBJECT` - NSObject (Cocoa)

## Important Patterns

### GroupItem Creation
Use the GroupItem constructor directly. `itemFactory` has been replaced with simpler constructors as part of the BDWGC migration:

```cpp
GroupItem *item = new GroupItem("name");
GroupItem *item = new GroupItem("name", value);
```

Under BDWGC, `new` resolves to GC-managed allocation since GroupItem inherits from `gc`. No manual `delete` is needed. (Earlier docs referenced `GroupControl::groupController->itemFactory(...)` — that path is gone; the constructor is the only path.)

### Registry/Scope Lookup
```cpp
GroupItem *item = locate("name");              // Search current scope
GroupItem *item = locateInMethod("name");      // Search method scope
GroupItem *item = getRegistry("RegistryName"); // Get registry
```

### List Navigation
```cpp
GroupItem *item = group->next(current);           // Next in list
GroupItem *item = group->nextAttribute(current);  // Next attribute
GroupItem *item = group->nextMember(current);     // Next member
```

### Memory Management
- Uses Boehm GC - no manual delete needed
- GroupItem inherits from `gc` base class
- garbageSTAK exists for compatibility but not required for GC

## Testing

Limited test infrastructure. The `Tests/test.json` contains a sample widget definition for testing JSON/XML parsing capabilities.

## Important Constraints

- All paths in includes are absolute (not relative)
- The system expects specific include directory structure in parent directories
- **Currently edit `.mm` files directly, not `.twk`.** TAWK autopsy is pending; the `.twk → .mm` pipeline is unreliable for collaboration. Once TAWK is fixed, `.twk` becomes the preferred source again. Do not back-port `.mm` edits to `.twk` in the meantime.
- Generated .mm/.h files match .twk files in naming (when .twk-as-source resumes)
- Rule names are case-sensitive
- Tag names must start with a letter (enforced by NamE rule guard)
