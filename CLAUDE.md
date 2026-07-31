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

**Backup directories** (`Aside/`, `BackupIncant/`, `BeforeRefactor/`) are gitignored
archaeology. Don't make new ones — the Incant repo IS the backup.

**`BeforeSave/` is the exception and is NOT dead.** (Corrected 2026-07-27 — this
section previously lumped it in with the above, which understates it.) It holds a
snapshot of every `.twk` and `.rtn`, and it is **Tony's live working tool**: he
refreshes it *once there is a clean kitchen*, then diffs his offline code changes
against it in **FileMerge** — and keeps it as a safety net "in case I pooch
something." So its contents are always the **last clean-kitchen state**, not an
arbitrary old copy.

Why Clod should care: it is a legitimate audit path for *"what did this file look
like before the current round of work"* — particularly for generated files and
out-of-repo dependencies where git history alone can't answer (bear-traps #11/#16).
Two consequences worth knowing:
- **Its usefulness is dated.** As of 2026-07-27 it held **end-of-June** state, which
  is exactly why the `-s ours` merge of `28347a7` cites it as the way to close that
  merge's deliberately-unaudited gap. **A refresh closes that particular path** — so
  an audit against an old commit is cheaper *before* the next refresh than after.
- **Never refresh or delete it, and never propose it as redundant with git.** The
  refresh is Tony's call and is tied to his offline-work cycle, not to ours.

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

**THE JIT REPLACES THE INTERPRETER (Tony's plan, written down 2026-07-29).** It is not an
accelerator running beside an interpreter that stays — the JIT *becomes* the interpreter, one
execution path. Read `docs/jit.md` §0 before any JIT decision: it carries the two consequences
(locals-as-frames lands ONCE in the JIT, so `saveLocalFields` gets **deleted** rather than
repaired; the iterator becomes two stack slots) and one open ruling for Tony (what happens to a
construct the JIT cannot emit yet — falling back to the interpreter *is* divergence).

**Phase JIT does NOT go through bytecode (2026-06-17 decision).** Bytecode and
JIT are *parallel, independent lowerings* of the same cached BlocK — not a
pipeline. LLVM IR comes straight from the ops/BlocK (the incant ops emit IR
directly via a `jitting` gate), **not** from `bcLIST`. The prior "LLVM IR
generated from bytecode" plan is superseded. Full rationale:
`docs/jitDesign.md` Part IV. **All JIT documentation consolidated 2026-07-31
into exactly two files: `docs/jit.md` (what is true today, every claim dated)
and `docs/jitDesign.md` (settled premises + open work). Six older JIT docs were
deleted in that pass; they are in git history if a reasoning trail is wanted.**

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

> **A POP IS NOT PASSED UNLESS THE PROCESS EXITED 0.** "Expected strings present" is NOT "the run
> succeeded" — a process can print every correct line, in the correct order, and then die. Check
> `$?`, not just the output. Found 2026-07-27 the expensive way: the genParse ladder floor was
> reported green for five hours on a `grep` for `Invariant R OK`, while `incant/genScratch` was
> exiting **139 (SIGSEGV)** the whole time. The printed lines were real and correct; the run was
> not. This is the instrument-level version of bear-trap #19's corollary — four times that day the
> search space excluded the answer because of the *code* being looked at; this one excluded it
> because of *how the looking was done*, which is why it survived four rounds of care.
>
> **Two corollaries, both load-bearing:**
> - **A byte-identical diff is still trustworthy on a crashing run**, because a crash truncates
>   output — a full matching capture cannot come from a process that died early. That is what kept
>   `oneTest`/`jsonTest` valid as baselines while the ladder POPs were not. **Scope a discovered
>   exit-status hole; do not discard the whole ledger over it.**
> - **Check what the assertion actually covers, not just that it passed.** The floor's "Invariant R
>   OK" was true — the *mark* rewound, exactly as claimed. It said nothing about the *input stack*,
>   which was broken underneath it the entire time. R held; R-as-a-proxy-for-clean-failure did not.
>   Same failure family as the exit-status hole: one is about the instrument, the other about what
>   the instrument covers.
>
> **⚠ THIRD COROLLARY, and it inverts the rule above: EXIT 0 IS NECESSARY BUT NOT SUFFICIENT.
> AN INCANT PARSE FAILURE ABANDONS THE REST OF THE FILE AND STILL EXITS 0.** Found 2026-07-30
> (grammar minion round 2, `CLAIM GRAM-8`; reproduced independently by foreman). A statement that
> fails to parse prints `RunRulE: expected a method not <x>` on **stderr**, silently drops **every
> statement after it**, emits **no `stop:` line**, flushes the output it already had, and returns
> **0**. So the run is indistinguishable from a short, complete, successful one — and every
> assertion that ran before the bad line still passes.
>
> **This is worse than the SIGSEGV case above, because 139 is at least visible.** A truncated
> fixture reports green on the rows it reached and simply *does not have* the rows it didn't.
>
> **THE MITIGATION IS A SENTINEL, and every fixture should carry one:** print a known marker as
> the LAST statement of the file and assert its presence *before* reading any other result. Absent
> sentinel ⇒ the run truncated ⇒ every other "ok" in that run is uninterpretable, not merely
> incomplete. `genLadder/printPop.sh` implements this (`sentinel` helper, checked first and by
> name); it caught an injected truncating row while the run's own `... runs` check still said `ok`.
>
> **And the same file documents the shell-level twin: `${PIPESTATUS[0]}` is silently empty in
> `zsh`** and reports every run as passing. Take `$?` directly from the binary, never through a
> pipe. That one bit two separate agents on this project in a single day.
>
> ---
>
> ## STANDING HARNESS RULES — a harness is an instrument, and an instrument that lies is
> ## worse than no instrument. Two rules, both paid for on 2026-07-31.
>
> **RULE H1 — A HARNESS ECHOES THE BINARY IT IS TESTING.** Path, size, mtime, as its first
> output. All three POP scripts had hardcoded an absolute DerivedData path belonging to a
> project **that no longer exists in the tree**, and had gone stale. A stale binary against
> current sources does not fail as a diff — the first symptom was a **HANG**, which reads as
> an infinite loop in whatever you last touched. Echoing the binary turns that into a diff in
> the log. `genLadder/pop.sh` implements it; prefer `${INCANT:-$HOME/bin/incant}` over any
> absolute path, because the symlink is what Tony's own builds follow.
>
> **RULE H2 — EVERY HARNESS ASSERTS ITS OWN COMPLETENESS.** An end sentinel that can only
> fire if the FINAL section ran, checked first and by name.
>
> This generalises the fixture sentinel above from *fixtures* to *the things that check
> fixtures*, and it is not hypothetical: **`incant/jiquery` had three `stop()` calls, so only
> its first section ever ran.** `stop()` exits the process — sections 2 and 3 were dead code
> that looked live, and the file reported a clean **exit 0 while answering one question out of
> three**. It sat that way for a month and hid a second defect underneath it (the corpus was
> holding no data — `docs/knownErrors.md` KE-1), because the section that would have shown the
> empty values was one of the two that never ran.
>
> **The rule is stronger than "put a sentinel at the end", and this is the part worth
> keeping:** the sentinel must be **unreachable except through the last section**. A marker
> that a truncated run can still print asserts nothing. In a shell POP the natural form is a
> final summary line plus a real exit status; in an incant harness it is a `print` immediately
> before the single `stop()` — **single**, because a second `stop()` anywhere above it silently
> deletes everything between.
>
> **RULE H3 — AN ASSERTION THAT MOVES FOR CORRECTNESS-UNRELATED REASONS IS NOISE.** Ratified
> 2026-07-31 as instrument doctrine, from `genLadder/jitPop.sh`'s decision to carry **no
> `.target` file**: the JIT's field slots are baked **absolute addresses**, so a byte-exact IR
> diff would move on every run for reasons that say nothing about whether the JIT is right. It
> asserts the **block topology** and the **values** instead. A target that cries wolf gets
> regenerated green, and a target that is regenerated green is not a target — so the choice is
> not "assert less", it is **assert the thing that only moves when the answer moves.**
>
> **And the generalisation behind all three rules:** the instrument-level failures on this
> project now outnumber the code-level ones — a stale binary, a `$?` through a pipe, a sentinel
> that was never checked, a harness with three exits, an assertion that covered the wrong
> thing. **When a result surprises you, doubt the instrument before the code.**
>
> **RULE H4 — ASSERT PRESENCE-WITH-VALUE, NEVER ABSENCE-OF-MESSAGE.** Adopted 2026-07-31.
> Generalises H2's sentinel logic from *completeness* to **every asserted quantity**: if a check
> can pass because a line is missing, it will eventually pass because someone deleted the code
> that emitted the line. Print the quantity unconditionally and compare its value.
>
> The worked example is the JIT degrade counter. `jitDegrade` writes to stderr when a construct
> falls through to emit-time interpretation, so the tempting check is *"assert that message does
> not appear"* — which goes green the day the message is removed. Instead `jitRunAction` prints
> `=== jitDegrade count = N ===` on **every** run, and the ladder asserts `N == 0`. Same fact,
> but a deletion now breaks the check instead of satisfying it.
>
> **FLEET AUDIT, 2026-07-31, and its scope is named because an absence claim is only as good as
> its search:** every assertion in `genLadder/pop.sh`, `printPop.sh`, `tree.sh`, `jitPop.sh` and
> `jitLadder/ladder.sh` was read. **No conversions owed.** The `grep -v` occurrences are output
> *filters* before a comparison, not assertions; the `-s`/`!= 0` tests are exit-status checks or
> anti-vacuity guards. Two were already H4-shaped for the right reasons and are the models to
> copy: `pop.sh`'s rStuff `AUDITLINE` (its own comment argues the point — *"an absence-based
> check passes by being removed; this one cannot"*), and `printPop.sh`'s
> `if [ ! -s "$T/o.print" ]`, which exists so its cross-keyword oracle cannot pass by comparing
> two empty files. **A vacuity guard is H4's other half:** an assertion that compares nothing to
> nothing is an absence check wearing a diff's clothes.
>
> ⚠ **ONE CHANNEL, ONE MEANING.** A second family, distinct from the causal-claim asymmetry
> below and now with two measured members. When one channel is made to carry two meanings, a
> change to either meaning silently corrupts the other:
> - **`isBranch` on the returned node** carried a statement's **value** *and* its **branch
>   signal**, so changing the value dropped the signal — the structural root of both branch
>   defects ruled on 2026-07-31.
> - **`gJitResult` non-null** meant *"the value in flight"* **and** *"something was emitted"*.
>   The moment a bracketing emitter legitimately cleared it, the second meaning inverted and the
>   driver bailed before emitting a return, silently un-jitting every `if/else`.
>
> **The cure is a second channel, not a cleverer test:** `gJitEmitted` in the emitter, and in IR
> the separation is free — a `br` carries no value and a `store` carries no control flow. When
> you find yourself reading a field for something other than what it holds, that is this bug.
>
> ⚠ **AND A MEASURED PROPERTY OF THIS SYSTEM, not a run of bad luck: STRUCTURAL claims here
> hold, CAUSAL claims here fail.** The causal-claim ledger in the JIT domain stands at **five
> failures**, the latest being "the return is a dominance violation" — falsified by a dump
> showing a *constant*, which dominates everything. Over the same period the structural
> rulings (unified emit-on-walk, the seam, single-topology if/else, phases-not-alternatives)
> have all held. **The asymmetry is now measured across two independent reasoners**, so treat
> it as a property of the system rather than a comment on anyone's care: in this codebase, a
> mechanism you can *point at* is usually right, and a mechanism you *inferred from a symptom*
> is roughly a coin flip until it is run. Grade accordingly — and note that withdrawing a
> prediction whose premise was removed counts as part of the same discipline, not as an
> admission.

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

4. **`//` comments that interrupt an `if`-statement parse** — the narrow real trigger
   (refined 2026-06-30, Tony). A `//` is **fine** in a block, inside a `-% … %-`
   passthrough, or outside a method. The failure is positional: a `//` wedged **between
   an `if`'s condition expression and its statement** breaks the parse and cascades
   field-resolution bleed into following externs. So: don't reflexively strip every `//`
   from a method body (that over-flags) — only avoid them mid-`if` (condition↔statement).
   Near an `if`, prefer `/* */` or put the comment above the whole statement.
   **Heuristic (Tony's rule of thumb): put `//` only where a *statement* is allowed.** tok
   parses a `//` into a statement slot, so it's safe anywhere a statement is legal; the
   `if` failure is precisely where tok expects the governed statement and the `//` gets
   consumed as it, orphaning the real one.

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

9. **JIT gate: `else jitSeedField` assumes a non-literal operand is a real field.** In
   `aCTionExpressioN`'s jitting branch, an operand that isn't a literal is routed to
   `jitSeedField` (unbox a real field). That holds for single-op POPs (`righty + 5`), but
   a chained expression `a + b + c` produces an inner *result* node that is also
   non-literal — and it would be wrongly handed to `jitSeedField`, which bakes a bogus
   `gCount` address. Latent: only bites when chaining lands. Guard on "already carries
   `jitData`" (the emit result) before treating an operand as a field. (Phase JIT, 2026-06-18.)

10. **Adding a GroupBody flag needs `groups.ext` sync AND `tokall` — miss either and it
    fails *silently and catastrophically*.** A new boolean in `GroupBody.twk`'s `bools` block
    is only half the job. Cross-file code (anything in the `GroupRules.twk` include chain —
    `Commands.rtn`, `Instruct.rtn`, …) resolves `field.newFlag` against the **`external
    GroupItem` block in `groups.ext`**, *not* the class. If the flag isn't added there too,
    tok can't parse `field.newFlag`, and — single-pass, no lexer — that parse error
    **cascades and wipes the ENTIRE extern block** from the regenerated `GroupRules.h` (0
    externs instead of ~144), so `Bytecode.mm` etc. fail with "no member named `opEQ`…".
    The tok output buries the cause in `FAIL Body3 …` lines. Second: a GroupBody change shifts
    the bitfield, so **`tokall`**, not a single retok. Symptom of a
    missed sync: `Expected a semi-colon` / `Expected } or statement` at an innocent-looking
    line. (`markWindow`/`isWindow`, 2026-06-25.)
    **CORRECTION 2026-07-27 — `tokall` does NOT "regenerate every `.mm/.h`".** It is a shell
    *function*, not a script, and its whole body is `for item in *.twk; do tok $item; done` —
    so it sweeps **only top-level `*.twk` in the current directory** (13 files). There are
    **14 more `.twk` below top level** it never touches: `GUI/*.twk` (11), `GUI/Stuff/*.twk` (2),
    `Tests/testGenerate.twk`. Those carry checked-in `.mm/.h` generated against the *old* layout,
    and a bitfield shift makes them stale in the silent way — compiles clean, links clean, wrong
    at runtime. **The check after any layout change:** grep the unswept generated files for the
    class you shifted (`grep -c "rStuff\|RuleStuff" GUI/*.mm GUI/Stuff/*.mm Tests/*.mm`). Zero
    hits ⇒ documentation-only, nothing owed — which is what it was for the `RuleStuff.parseMethod`
    add on 2026-07-27. Any hits ⇒ retok those before trusting the binary on those paths.
    Same category as bear-trap #11: the build has more surface than the instructions describe.
    Related, unresolved and Tony's: `GUI/Layout.twk` and `GUI/Stylish.twk` share basenames with
    the top-level `Layout.twk`/`Stylish.twk`, and only the top-level pair is ever swept.

11. **`groups.ext` lives OUTSIDE this repo** at `~/Dropbox/data/InProcess/Include/groups.ext`
    (pulled in via `groupIncludes`). It is a real **build dependency** but is **not tracked in
    the Groups git repo** — so edits to it (e.g. trap #10's flag/extern sync) won't appear in
    `git status` or any commit here. Resurrection-reader: if a build fails on a missing field
    or extern that "should be there," check this file. Note it explicitly whenever a change
    touches it.

12. **`extern "C"` name collisions link-fail silently until `Ld`** — two unrelated `extern`s
    with the same name in different `.twk` files compile clean individually (each file's own
    `tok` pass has no visibility into the other) and only blow up at the final link step
    (`duplicate symbol '_foo'`), by which point the error message gives no hint which two
    *incant* files are the culprits (only the `.o` names). Hit twice in one pass (2026-07-02):
    `blockContaining` defined in both `GroupDraw.twk` (old) and `Stylish.twk` (new rewrite);
    `indent`/`indentWH` collided with the **unrelated** debug-print `indent()` in the shared
    support `StringRoutines.C` (`extern "C"` strips C++ overload resolution, so signature
    differences don't save you — only the name matters). Before adding a new `extern` with a
    short/common name, `grep -rn "extern.*<name>(" --include=*.twk --include=*.h .` first
    (repo-wide, including support/shared dirs) — a name that only conflicts with something one
    parser pass can't see is the whole danger.

13. **`-% … %-` passthrough drops incant-declared locals tok thinks are "unused."** A local
    declared at the incant level (`Color c = getColor(name);`) that is only *referenced* inside
    a following passthrough block gets pruned — tok can't see into passthrough, decides the
    incant-level declaration (and its initializing call) is dead, and emits nothing for it,
    leaving the passthrough body referencing an undeclared C++ identifier (`use of undeclared
    identifier 'c'`). tok will warn `Declarations ignored because not used: N` when this
    happens — treat that warning as load-bearing, not cosmetic. Fix: do the whole
    computation *inside* the passthrough (call the C-linkage function directly, e.g.
    `NSColor *c = ::getColor(name);`), using the raw Apple/C++ type (`NSColor*`, not the
    incant typedef `Color` — passthrough is literal, unprocessed code, so incant's type
    aliases don't resolve there either). A variable is only safe from pruning if something
    *outside* the passthrough also references it (parameters are always safe; `hold((void*)font);
    object = font;` after a passthrough that sets `font` is why `setFont` didn't need this fix).

14. **`printf`/`cout` inside a passthrough is lost if the run ends via `stop()`.** Confirms and
    generalizes the existing run-recipe note (stdout is block-buffered when not a tty; `stop()`
    calls a hard `exit()` with no flush). Any debug/POP-tool extern that prints from inside
    `-% %-` must use `fprintf(stderr, …)` (unbuffered), not `printf(…)` (stdout) — otherwise the
    output silently vanishes and looks exactly like "the extern was never called" (cost real
    debugging time chasing a phantom no-op on 2026-07-02's `dumpColorRGB`/`dumpFontInfo`).

15. **Bare top-level incant script statements (`incant/oneTest`-style files) don't support
    `identifier = new(...)` for a not-yet-existing identifier** — `RunRulE: expected a method
    not <name>` — regardless of whether `<name>` collides with anything. **CONFIRMED FIX (same
    day, follow-up):** wrap the construction in a registered action's `code={ }` body instead of
    a bare top-level statement — `register(Name); define myAction code={ x = new("x"); ... };
    ; myAction();` (`incant/unitTests`'s `testNew argument code={ grup = new(argument); ... };`
    is the confirmed template) — run under the FULL `oneTest`-style preamble
    (`include(unitTests); include(generate); include(utilities); search reset stack Grokking;
    search Generating UnitTests bcOPs Utilities list;`). This eliminates the parse rejection.
    **But two more issues surfaced testing this (2026-07-02, unresolved):**
    (a) two-argument `new(tag,value)` still doesn't parse even inside `code={ }`
    (`ERROR processCode: <action> parse failed`) — use two-step construction instead
    (`x = new("tag"); x.text = value;`), matching `testNew`'s single-arg shape exactly.
    (b) with that fixed, a field with a real attribute attached (e.g. `boldFont.family = new(...)`
    two-step) still segfaults when passed through `setFont`/`dumpFontInfo` — before any output —
    while the exact same shape with ZERO attributes attached runs crash-free but ALSO produces
    zero output from a `fprintf(stderr,...)` call that should be unbuffered (rules out bear-trap
    #14's buffering explanation). Likely **two separate bugs**, not one: an attribute-construction-
    then-dereference crash, and an independent silent-non-dispatch of either the action call or
    the print. Separately, colors' `setColor` `properties["hexSet"]` null-deref (this trap's
    original attempt 2) **still segfaults even under the full preamble** — that global doesn't
    get populated by `include(unitTests/generate/utilities)` alone; the real init path is still
    unknown. Next agent: don't re-derive the two-arg-`new()` or `code={ }` findings above: start
    from a *zero-attribute* field in a registered action to confirm the dispatch/print path
    first, before reintroducing attribute construction.

16. **tok's `.h` ivar list is additive against `groups.ext`'s external mirror — retok/`tokall`
    alone will NOT drop a member you removed from the `.twk` class body.** Removing a field from
    a class in `.twk` and retok-ing (even a full `tokall`) leaves it sitting in the generated
    `.h`/`.mm` forever, because tok cross-checks/merges against the class's `external ClassName {
    }` mirror in `groups.ext` (outside the repo, bear-trap #11) — and that mirror doesn't update
    itself. Symptom: you delete a field, retok, and it's still in the header (and still getting
    zero-initialized in every constructor). Fix: edit `groups.ext`'s matching `external ClassName`
    block to match, THEN `tokall`. Found 2026-07-02 removing `Stylish`'s `subbed` (plus 5
    already-stale `shadowBlur`/`shadowOffset`/`shadowX`/`shadowY`/`shadowColor` ivars that had
    drifted out of `Stylish.twk` at some earlier, unrecorded refactor and were still being
    zero-inited in every `Stylish` constructor). Generalizes bear-trap #10 beyond
    GroupBody-flag-and-extern-sync to any class's ivar list.

17. **A short/common bare keyword can be silently claimed by TAWK's own Apple-symbol alias table,
    shadowing a same-named real function elsewhere — only surfacing when both get compiled in the
    same pass.** `~/data/support/Include/OCframe` (a global, cross-project TAWK keyword table,
    shared with other TAWK-based projects) maps `alignLeft`/`alignCenter`/`alignRight` to
    `NSLeftTextAlignment`/etc. Separately, `~/data/support/Frame/StringRoutines.C` (also shared,
    cross-project) has a genuine `alignLeft(text, length)` string-padding function, used by
    `Debug.rtn`. Both are legitimate, both are outside this repo, and tok's keyword resolution
    doesn't scope the alias per-file — so the moment BOTH are live in the same `tokall` pass (as
    happened 2026-07-02 once `Layout.twk` started using `alignLeft` as the Apple constant),
    `Debug.rtn`'s real function call silently mis-generates as `NSLeftTextAlignment(tag,20)` — a
    non-existent function call, caught only at the C++ compile step (`called object type
    'NSTextAlignment' is not a function or function pointer`), with no hint that the actual cause
    was in an unrelated file two directories away. **Do not rename either shared/cross-project
    definition to fix this** — blast radius extends beyond this repo. Fix at the narrow call site
    instead: wrap the colliding usage in `-% … %-` passthrough with the real, long Apple constant
    name (`NSLeftTextAlignment`, not the short alias `alignLeft`) — this sidesteps the alias table
    for that one call site without touching either shared definition. Before adding a *new* short
    bare-keyword usage of an Apple constant alias anywhere, grep the target name across the repo
    first (`grep -rn "<name>(" --include=*.twk --include=*.rtn .`) — the danger class is identical
    to bear-trap #12 (extern "C" collisions) but one layer up, at the TAWK-keyword level instead
    of the linker level, and harder to spot because it isn't `extern`-declared anywhere to grep for.

18. **OBSERVATION (confirmed, load-bearing): tok's `#name(args)-...-` macro facility would not
    support the shapes genParse needed, so genParse §3 was rewritten against ordinary `extern`
    functions — which is why that code looks the way it does. ATTRIBUTION (OPEN, see the end of
    this entry): *why* it wouldn't is NOT settled, and the causal headline this entry used to
    carry is falsified by shipping code.** Read the three failure modes below as reproduced
    symptoms, which they are, and not as a mechanism, which they are not.
    ~~only works when the invocation is the ENTIRE, SOLE
    body of its containing function~~ — exactly `testMacro`'s only existing usage (`testAny`/
    `testCharacter`/`testSet`, each just `use field \n testMacro(...);`). The moment a macro call
    is one statement among several, it fails, and fails in two different ways depending on shape:
    (a) nested in an expression (`return someMacro(x) && true;`, or even bare
    `return someMacro(x);`) — **silently does not expand**, emitted verbatim as a literal call to a
    function that doesn't exist, flagged only as "referenced but not declared" in a trailing
    comment; fails at the C++ compile step, not at tok. (b) a bare statement that is NOT the
    function's only statement (preceded or followed by other code) — **tok segfaults** (exit 139),
    reproduced with both a GCC `({...})` block and plain ordinary tok syntax matching `testMacro`'s
    own style, so it is not about `({...})` specifically. (c) **the most consequential**: two
    macro calls in sequence in one function (an `enterX(...)` bare statement followed by
    `return leaveX(...);`) does not crash, but silently drops the FIRST macro's statement entirely
    (locals pruned, "Declarations ignored because not used: N" — the same warning bear-trap #13
    uses for a different cause) while the SECOND remains an unresolved, unexpanded call. Neither
    macro fires. Root cause per Clay (2026-07-25): not a tok bug so much as a category mismatch —
    a macro expands to a block that declares locals and executes `return`; a statement can never be
    a term in `A && B`. Candidates Tony was checking for a narrower rule (untested as of this
    writing): missing terminating semicolon on the macro call, column-0/declaration-position vs
    indented/statement-position, and whether `use field` needs to precede the call for bare-name
    resolution inside the expansion to have anything to bind to. **Fix that actually worked**:
    don't use tok macros for anything beyond `testMacro`'s existing shape. Write plain `extern`
    functions instead — they're expressions by construction, so `&&`/`||` composition works
    natively with zero substitution machinery, and multiple calls in one function are just
    ordinary sequential statements. (genParse S3, 2026-07-25 — see `docs/genParseSpec.md`.)
    **ATTRIBUTION — OPEN, and do not act on the strikethrough above (2026-07-27).** The
    "sole body of its function" rule is **falsified by shipping code**: `testSet` in
    `RuleStuff.twk` has a declaration (`PLGset set = characterSet;`) *before* its `testMacro(...)`
    call and works, in the current build. So the real constraint is narrower than the symptoms
    suggested, and four candidates remain, **one of which is Clay's own spec error**:
    (a) **the terminating semicolon** — every working invocation is `testMacro(...);`; genParseSpec
    §5.1 wrote `enterSeq(JSONblock)` with none, and an unterminatable construct would produce
    exactly mode (c)'s dropped-statement signature; (b) **column-0 / declaration position** — all
    three working invocations sit unindented, and if tok expands macros during declaration parsing
    then "works at column 0, fails indented" explains modes (b) and (c) with no tok bug at all;
    (c) **the `use field` prefix** — all three working sites have it, and `testMacro`'s body
    references bare `isOK`/`max`/`min`/`label`/`hereAt` which only resolve through it, so stripping
    it is a plausible route to a tok-side segfault; (d) **category mismatch** (Clay, 2026-07-25) —
    a macro expands to a block that declares locals and executes `return`, and a statement can
    never be a term in `A && B`; on this reading §3 was wrong on its own terms and tok is fine.
    **Tony's sign-off is owed on which, if any** — he is the only one who knows what tok promises.
    What is NOT in doubt and stands as doctrine regardless: **tok exiting 139 with no diagnostic is
    a real defect**, and **the fix that worked was to stop using macros for anything beyond
    `testMacro`'s existing shape.** Split out per bear-trap #19's corollary — reproduction proves
    the SYMPTOM, never the CAUSE, and this entry was one bad session from hardening a wrong
    mechanism into doctrine.

19. **The "invocation blocker" is an ENVIRONMENT/STALENESS class, not a language class — suspect
    the build state before the language.** Signature: an `extern` registered as an incant command
    produces *nothing at all* — never entered, clean exit, no error, no diagnostic. Four instances
    to date (genParse Step 1, Step 2, `runScaf2`, and the runJSONblock-era one). **Every one has
    resolved as build/regen state, none as an incant-language rule.** `runScaf2` (2026-07-27) is
    the cautionary case: it was narrowed hard — `nm` showed `_runScaf2` live, codegen was
    structurally identical to the working `runScaf`, single-entry `=value` registration, non-brace
    input — and the surviving hypothesis was *"incant command names can't carry trailing digits."*
    **That hypothesis is FALSE.** After a `groups.ext` sync and a full `tokall` for unrelated work,
    `runScaf2` dispatched with no change to its name, registration, or call site. Digits are fine.
    **So when a registered command won't dispatch, in order:** (1) re-sync `groups.ext` (bear-traps
    #10/#11/#16 — it is out of repo and merges rather than regenerates, so it goes stale silently);
    (2) full `tokall` (see #10's correction — and note it misses subdirectories); (3) rebuild; and
    only *then* start hypothesising about the language. The cheap mechanical sweep has beaten the
    clever narrowing four times out of four.
    **THE COROLLARY, AND IT IS BIGGER THAN THIS ENTRY — read it as a general rule, not a fact
    about command dispatch: a hypothesis that survives narrowing is not thereby confirmed.
    Narrowing is only valid INSIDE the space you are searching. When it fails, the usual defect is
    a wrong SPACE, not a wrong candidate — the real cause sits in a file the narrowing never
    looked at.** `runScaf2`'s digit theory was the last hypothesis standing and still wrong,
    because the cause was in `groups.ext`, which is outside the repo and was never in the search.
    The same shape ran four separate times on 2026-07-27 alone, each surviving careful reasoning
    and dying on contact with a single grep: (1) `runScaf2` = digits, actually regen staleness;
    (2) the `ruleSTUFF` clobber-window story, actually a `field.rStuff`-vs-`label.rStuff`
    provenance difference — and `parse()` already set it post-descent, so the window never existed;
    (3) `setLabel` deleted and its job orphaned, actually taken over by `<:` in a rewritten
    JSONfield; (4) min-zeroing as the JSON cause, actually never executed at all. **Cost of the
    check in every case: one grep. Cost of the reasoning: hours.** Grep first, theorize second —
    and when a theory survives, ask what files were never in the search space before believing it.

20. **tok's fnptr member syntax takes MULTIPLE arguments** — `int &name(TypeA, TypeB);` in a class
    body generates `int (*name)(TypeA *, TypeB *);`. Only the single-argument `testMatch`
    (`RuleStuff.twk:21`) existed as precedent, so this was untested until `parseMethod` on
    2026-07-27. Not a trap — an idiom worth knowing, because it converts an interface *convention*
    into a compiler-enforced *type*: a uniform generated-method signature stops being something
    every call site must remember and becomes something the field declaration guarantees. Note the
    corollary: widening such a signature later is a **layout change** (bear-trap #10's whole
    apparatus — `groups.ext` sync plus `tokall`), not an edit. Same file also shows the dispatch
    idiom to copy — `if <fnptr>  result = <fnptr>(args)` at `GroupItem.twk:949-950` — and the one
    NOT to copy: `testMatch`'s lazy `if !testMatch setTestMatch()` self-initialisation.

21. **Identical commit message does NOT mean identical commit. Compare TREES, not subjects.**
    Two commits can carry the same subject line, the same body, the same author and intent, and
    land different content — a rebase, an amend, a cherry-pick with drift, or a re-do after
    feedback all produce exactly that. A commit message is evidence about *what someone was doing*,
    not about *what landed*. Found 2026-07-27 one sentence away from an irreversible mistake:
    `origin/jit-unified-emit-wip` carried `28347a7` "WIP: unified JIT emit-on-walk model…", and our
    branch carried `3cce6d8` with a **byte-identical subject**. The natural read — twins, so
    discarding the remote one is free — was about to justify a `git push --force`. The check that
    killed it took ten seconds:
    ```
    git rev-parse <a>^{tree}  vs  git rev-parse <b>^{tree}     # definitive
    git show <a> | git patch-id --stable                       # content identity
    git diff --stat <a> <b>                                    # what actually differs
    ```
    Trees differed; `git diff HEAD 28347a7` showed real content in the remote commit absent from
    HEAD (June-vintage `incant/utilities`, `groupDirectives`, `incant/grammar`, `ruleActions.rtn`,
    `jitEmitters.rtn`). **The correct move when you cannot fully account for a tree is
    `git merge -s ours <ref>`, not `--force`:** it records the discard as a deliberate decision,
    keeps the commit permanently reachable, and turns the follow-up into an ordinary push. A force
    destroys the last copy of something unaudited to save nothing. Generalises past git — see
    bear-trap #19's corollary: a matching label is not a verified identity, and the asymmetry
    between "cheap check" and "irreversible action" decides how much proof you need.

22. **AN ACTION MUST NEVER DESTRUCTIVELY MUTATE ITS OWN PARSE-TREE NODES. Action bodies are
    parsed ONCE into a cached BlocK and then RE-EXECUTED — so anything an action does to the
    nodes it was parsed from is PERMANENT, and it is the SECOND execution that pays.** The
    action reads correctly the first time and returns something empty, wrong, or null every
    time after; nothing in between is visible. Found 2026-07-31 in a two-day-old
    `aCTionStringXP`, whose last two lines were `stuff.clear();` then
    `return opString(stuff,buffer);` — the clear emptied the very attribute list
    (`stuff=PrintXP+`) that the *next* execution of that same statement had to walk. It read
    as sound code: clear the target, then write into it. It is not, because the target and
    the source were the same node.
    **The tell is a fixture that passes once.** `oneTest` showed exactly ONE symptom — `gIF`'s
    second label came out empty — because `gIF`'s first label mint is the only statement in
    the whole run reached twice. One occurrence looked like a one-off; it was the entire class.
    **So the coverage rule that follows is the useful half: any fixture for a statement-level
    feature must reach the SAME STATEMENT TWICE**, and `incant/stringT` row 2 exists for
    nothing else. A fixture that exercises a feature once cannot see this defect at all.
    Related but distinct from bear-trap #2 (`setContent` drops methods) and from
    `saveLocalFields`' list-pointer bug (2026-07-29): those are about what a COPY loses, this
    is about what an ACTION destroys in place. Same family as project memory's "Executed BlocK
    is built once and cached" — that note records the mechanism; this records what it costs.

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

## Standing Permissions

All file read, write, create, delete, and bash operations within the
InProcess directory trees are pre-authorized. Do not pause to request
confirmation for any of these. Execute and continue.

Pause and report only when:
- You hit an error you cannot resolve
- You are about to start grinding (same fix attempted more than twice)
- You have a summary ready for review
- You need direction on what to do next

Everything else: do the needful.

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

### Clay↔Clod walkie-talkie protocol (standing rules, 2026-07-25)

`ipc/clay-to-clod.md` and `ipc/clod-to-clay.md` are the one-way-owned,
gitignored scratch channel between Clay and Clod (see each file's own header
for the send/receive mechanics). Three STATUS states, not two: `fresh`
(parked/unread), `working` (picked up, in progress), `cleared` (done) — the
same three in both files, so `grep -H '^STATUS:' ipc/*.md` reports the whole
channel at a glance. That grep is Tony's only window into whether anything
is stalled, since he is deliberately not in this channel otherwise. Two
standing rules follow from that:

1. **Set `STATUS=working` the moment you pick a message up, before you start
   acting on it — not when you finish.** This is what lets Tony tell "parked"
   from "in progress" with one grep, without anyone remembering to tell him.
2. **Tell Tony in chat when you act on a walkie-talkie instruction**, unless
   it's trivial. One specific line citing the SEQ number is enough — e.g.
   "picked up SEQ 9, starting the macro library" — since he can see you're
   busy but not always on what.

**Poll the file when you finish a unit of work.** Messages have sat `fresh`
unread across session boundaries more than once (a SEQ 2 from 2026-07-02, three
questions in `rstuff-chokepoint.md` open since 2026-06-20, a SEQ 7 skipped
entirely) — the channel mechanics are fine, the polling discipline is what
lapses. Check it proactively; don't wait to be told something is waiting.

See `projectBible.md` for full glossary, HWF protocol, and ecosystem context.
