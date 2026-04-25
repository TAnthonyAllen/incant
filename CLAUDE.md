# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Read incant.md for current project state and architecture decisions. That document is the source of truth for ongoing design choices."

Per the Phase 0 plan in incant.md, switch GroupItem allocation from new/malloc to GC_malloc. Use the BDWGC C++ API (gc_cpp.h or gc_allocator). Find and remove any stray delete calls on GroupItems. Don't touch the .twk files. Run the build when you're done and report errors.

You can include "ask before making non-obvious changes" in your initial instructions.## Overview

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

## Code Generation

The system generates C++ code through:
1. **Parse phase** - Rules match input and build GroupItem trees
2. **Generate phase** - `generating` flag enables code generation mode
3. **Actions** - aCTion* functions transform parsed structures into code
4. **Output** - Generated code emitted via Buffer system

Key generation functions in Generate.rtn:
- `adder()` - Generates + operator code
- `decrement()` - Generates -- operator code
- `divide()` - Generates / operator code
- Other operator and expression generators

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
Use GroupControl::groupController->itemFactory() methods, never raw new():
```cpp
GroupItem *item = GroupControl::groupController->itemFactory("name");
GroupItem *item = GroupControl::groupController->itemFactory("name", value);
```

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
- .mm files are generated from .twk files via `tok` compiler - edit .twk source, not .mm
- Generated .mm/.h files should match .twk files in naming
- Rule names are case-sensitive
- Tag names must start with a letter (enforced by NamE rule guard)
- After modifying .twk files, recompile with `tok <filename>.twk` to regenerate .mm files
