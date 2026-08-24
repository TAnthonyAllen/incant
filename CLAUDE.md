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
> 2026-07-31 as instrument doctrine, from the JIT harness's decision to carry **no
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
> ⚠ **AND ITS OTHER HALF, ratified 2026-08-05 and paid for the same day: DOUBT THE INSTRUMENT WHEN
> THE RESULT DOESN'T SURPRISE YOU EITHER. AN UNSURPRISING GREEN IS THE ONE NOBODY AUDITS.** Every
> failure in the ledger above was found because something looked wrong. This one was found by
> accident, while wiring an unrelated rung: `jitLadder/ladder.sh` **called `check` and `sentinel`
> at JPd and JPl and never defined them.** Every run printed `ladder.sh: line 393: check: command
> not found` to stderr and carried on. Those four checks did not pass and did not fail — **they
> ceased to exist** — so for four days JPd and JPl had no exit-status check and no truncation
> guard, and since output printed before a crash is real, **a crashing `jitJPd` would have reported
> green.** Inside the harness that certifies JIT-0.1.
>
> **THE HEADLINE COUNT WAS THE CAMOUFLAGE, and that is the sentence to keep.** "103 ok, exit 0"
> *reads* as an audit; it is a **tally of the checks that RAN**. **A check that evaporates is
> invisible in a count of checks** — the number goes down by four and nothing says so, because
> nobody knows what the number should have been. A green banner is therefore not evidence about
> the checks that are missing from it.
>
> **Third instance of one named class — COPY THE IDIOM, LOSE THE HELPER** (`incant/jiquery`'s three
> `stop()`s, `pop.sh`'s missing `sentinel`, now the JIT ladder), and `pop.sh`'s own helper carries a
> comment recording the previous occurrence. **The structural fix is that a harness certifies
> ITSELF before it certifies anything else**: an end-of-file assertion that fails if the run reaches
> the foot with **zero green checks recorded**, which a vanished helper set cannot satisfy. That is
> H2 turned on the harness rather than on the fixture, and it is the form to copy.
>
> **Two corollaries ratified with it, both the anti-vacuity instinct applied one level up:**
> - **ASSERT DEPTH BY NAME, because identical-but-shallow passes a diff.** Rung JC diffs the jitted
>   walk against the interpreted walk and would go green on two walks that both stopped at depth 1
>   — **a walk that stops early agrees with itself.** So it also greps for `zeta`, the depth-3 leaf.
> - **A CONSTANT THE DEFAULT COULD ALSO PRODUCE ASSERTS NOTHING.** Rung JV's rows A and B both want
>   `0`, which a result slot that merely defaults to zero yields too; they cannot distinguish
>   *convention carried* from *nothing written*. Row C wants **4**, so it fails unless the slot
>   holds a real computed value. **Pair every zero-expecting row with a non-zero sibling.**
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
> its search:** every assertion in `genLadder/pop.sh`, `printPop.sh`, `tree.sh` and
> `jitLadder/ladder.sh` was read (`jitPop.sh` was audited too and has since retired into the
> ladder). **No conversions owed.** The `grep -v` occurrences are output
> *filters* before a comparison, not assertions; the `-s`/`!= 0` tests are exit-status checks or
> anti-vacuity guards. Two were already H4-shaped for the right reasons and are the models to
> copy: `pop.sh`'s rStuff `AUDITLINE` (its own comment argues the point — *"an absence-based
> check passes by being removed; this one cannot"*), and `printPop.sh`'s
> `if [ ! -s "$T/o.print" ]`, which exists so its cross-keyword oracle cannot pass by comparing
> two empty files. **A vacuity guard is H4's other half:** an assertion that compares nothing to
> nothing is an absence check wearing a diff's clothes.
>
> ⚠ **ONE CHANNEL, ONE MEANING — PROMOTED TO DOCTRINE 2026-08-05, on its fourth
> and fifth measured members.** It has now named the day's bug twice in one day,
> which is the bar. The full ledger:
>
> | the channel | meaning A | meaning B smuggled in | what it cost |
> |---|---|---|---|
> | `isBranch` on the returned node | the statement's VALUE | its BRANCH SIGNAL | both 07-31 branch defects |
> | `gJitResult` non-null | the value in flight | "something was emitted" | silently un-jitted every if/else |
> | `gJitResult` per print item | the value in flight | **the value THIS item produced** | printed `0`, then `80329152` |
> | `isBranch` read by `aCTionBlocK` | stop EXECUTING this block | stop **EMITTING** this block | every statement after a `continue` vanished from the IR |
>
> **The last two are the promotion, and the fourth is the sharpest yet** because
> the two meanings belong to *different eras* rather than different facts: at RUN
> time a branch means stop; at EMIT time the statements after it are REACHABLE
> and must all be emitted. One flag, one reader, two eras.
>
> ⚠ **AND THE THIRD ROW IS WHY THIS IS URGENT RATHER THAN TIDY: A CONFLATED
> CHANNEL GETS MORE DANGEROUS AS THE SYSTEM GETS BETTER.** While nothing emitted,
> a stale `gJitResult` was always null and the bug printed `0` — wrong, but
> stable and obviously wrong. The moment real values started flowing, the same
> code printed `80329152`: a stale read **wearing the shape of data**, with
> degrade count 0 the whole way. **The fix that improves the system is what arms
> the latent bug.** So a conflated channel is not debt you can pay later at the
> same price.
>
> **The cure is always a second channel, never a cleverer test** — `gJitEmitted`
> beside `gJitResult`, `jitPrintArm` clearing per item so "this item emitted
> nothing" becomes answerable, `if jitting continue;` so the emit walk does not
> inherit the interpreter's stop. And once the fact is answerable, **refuse
> rather than substitute**: `jitPrintItem` now calls `jitDegrade` on a null
> instead of passing a constant, because the degrade counter is asserted at zero
> by every rung and a substituted constant is asserted by nothing.
>
> ⚠ **A DEGRADE LINE ASSERTS THAT A FALLBACK *OCCURRED*, NEVER THAT THE FALLBACK WAS *SOUND*.**
> Adopted 2026-08-08, and it is the one-channel-one-meaning family's newest member — the two facts
> are *"a construct fell through"* and *"the answer is still correct"*, and `jitDegrade`'s counter
> carries both on one number.
>
> **Soundness is PER-CONSTRUCT, and E2 is the counterexample.** `jitDegrade` reports
> *"return INSIDE AN INLINED CALLEE … running INTERPRETED"* identically in two positions:
>
> | position | degrade count | actually sound? |
> |---|---|---|
> | **tail** return | 2 | **yes** — a tail return needs no branch to the enclosing epilogue, so falling through is equivalent. Ladder rung **JXT** is green on exactly this. |
> | **mid-body** return | **2** | **NO** — the early exit is not taken, the tail runs, the answer changes. `incant/jitXe2`: jitted 222/999 where the interpreter says 111/0. |
>
> **Same count, opposite safety.** So the fleet's degrade-zero rule — asserted by every rung, and a
> genuine H4-shaped instrument — **cannot distinguish a handled fallback from an unhandled one.**
> Rungs **JE2** and **JXN** therefore assert **values**, never the counter. When a degrade line
> appears, the question *"is this fallback sound for THIS construct"* has not been answered by
> anything; go and answer it.

> **RULE H7 — A RUNG CERTIFIES ONLY WHAT FAILS WHEN THE MECHANISM IS REMOVED.** Adopted
> 2026-08-04, and it is the day's best finding because the fixture that taught it was GREEN.
>
> A new fixture for the jitted iterator asserted 3/3/3 across three fires and passed. It also
> passed **with the gate it was written to certify removed** — because an exhausted iterator
> restarts from `firstInList`, so a second fire walks the same list either way. Green, and
> evidence of nothing. Nobody would have looked: it tested the right feature, produced the
> right number, and asserted it with a value rather than an absence, so it satisfied H4 and
> every other rule on this list.
>
> **The instrument already existed** — `incant/regProbe` ran a negative control (the
> unregistered sibling stays dark) — and this promotes it from a good habit to a rule:
> **where feasible, a new rung records its negative control**: the gate-removed,
> emitter-removed, flag-removed run that goes RED. The worked example is the replacement
> fixture — two sequential re-targeted iterates with DIFFERENT counts on the two sides:
> ```
> gate REMOVED, rebuilt:  jitted attrs=3 members=3   oracle 2/3   WRONG
> gate PRESENT, rebuilt:  jitted attrs=2 members=3   oracle 2/3   right
> ```
> and the wrong answer was **silent** — degrade count 0 in both runs.
>
> **Its other half, and the same doctrine seen from the opposite side:** where a construct is
> built but not certified, PIN IT RED ON PURPOSE rather than letting an accident of topology
> imply coverage. `continue` emits the correct branch, but the condition feeding it is wrong,
> so the rung pins its outcome wrong and says why. **A green row is a claim; do not make one
> the mechanism cannot cash.**
>
> ⚠ **MATCH THE TASK'S FAILURE LOUDNESS TO THE SEAT'S MECHANICAL STATE.** Adopted 2026-08-08, and
> it is doctrine about the three-seat model itself rather than about the code.
>
> **Not all wrong work fails at the same volume.** A crashing fixture, a red diff, a broken build
> announce themselves. **A misfiling in a precision classification does not** — it becomes a
> charter-level mistake that gets *built on*, and the cost surfaces rungs later with no line
> pointing back. **So late-session mechanical state routes to self-checking work, or to shutdown —
> never to silent-failure work.**
>
> **The citation is the eight-slip inventory of 2026-08-08**, preserved verbatim in that day's
> wakeup vintage. The session's *reasoning* held — E2 gating the campaign, the parse-arm answering
> NO, a pre-registered prediction falsified — while the *mechanical* layer degraded: a harness
> banner contradicting its own rows, a census matching prose, an anchored regex undercounting 13→8,
> a `git add -A <paths>` omitting a directory so a commit **described work it did not contain**, a
> second `git add -A` sweeping up a file held back one command earlier, a fixture comment header
> crashing the parser, a broken `printf`, and **`${PIPESTATUS[0]}` used by someone who had read
> that bear-trap the same day.**
>
> **That last one is the whole argument: knowing the rule did not prevent the error.** Which is why
> the answer is *structure and scheduling*, not *more care* — and why it belongs beside the
> make-the-failure-unconstructable family rather than in a list of things to remember.

> **RULE H8 — THE RECONCILIATION LAW.** Tony, 2026-08-05. **After any offline work session,
> the next joint session OPENS with reconciliation**: `git status` on both repos, Tony walks
> every dirty hunk, and each one gets a verdict — **commit** (the revised square), **revert**
> (back to square), or **named-WIP with an owner**. **No work stacks on an unreconciled tree.**
>
> **Clause two, the quarantine rule: a surprise diff — dirt that neither Clod nor the session's
> log explains — gets STASHED, never overwritten.** Restoration from HEAD may proceed for fleet
> health, but the stash preserves the intent until Tony adjudicates. **Three-day-old surprises
> are a protocol failure, not a mystery.**
>
> ⚠ This law was written the day it was needed and one hour after it would have helped:
> `Commands.rtn` was found reverted to an older blob mid-session and was restored from HEAD
> **without a stash**. It happened to be lossless — the working copy was byte-identical to a
> committed blob, which is provable and was proved — but that was luck, not process. The
> byte-identity check (`git cat-file -p <blob>` against the old commit's version) is the cheap
> way to show a discard cost nothing; it is bear-trap #21's compare-trees-not-labels rule run
> in the other direction.
>
> **RULE H5 — A FIXTURE MUST NOT BE ABLE TO DELETE THE REST OF THE SUITE.** Adopted
> 2026-08-02. `incant/iterT1m` began to HANG rather than return, so `pop.sh` never reached its
> summary line, its exit status, or the eleven checks below the iterator block. Those checks did
> not fail and did not pass — **they ceased to exist**, and the operator sees a terminal that is
> merely quiet. That is worse than the missing-`sentinel` case above, because there is no output
> at all to be suspicious of.
>
> ⚠ **AND THE FIXTURE THAT DID IT WAS A PARKED ONE.** Parking was built so a fixture whose answer
> is not yet chosen cannot fail the suite, and it does that perfectly. It never contemplated a
> parked fixture taking the suite hostage by never returning. The containment was real but one
> dimension short: **it bounded the VERDICT and not the RUN.** So every fixture runs under a
> wall-clock cap (`POPCAP`, default 90s), and **a timeout fails the suite even when parked** — a
> hang is not a wrong answer, it is the absence of a run, and nobody parked that. `timeout(1)` is
> not on macOS; `pop.sh` uses sleep-and-kill and maps 137 to 124. A timeout is reported by name
> and NEVER as a diff, because a killed process yields truncated output and a truncation diff
> names the wrong row.
>
> **RULE H6 — A PARKED PIN THAT STARTS PASSING MUST GRADUATE.** Adopted 2026-08-02, after `WOKE`
> fired twice in one day. Parking means *"the answer this would be measured against has not been
> chosen"*. Once it is chosen the item becomes either a full check (`iterT1`, whose original
> target held byte for byte under the new semantics) or a deliberately pinned known defect
> (`iterT1m`, the `tree.divergence` pattern) — **never still parked**. A pin that silently begins
> to hold is how a parked item becomes a forgotten one, which is the failure the `WOKE` alarm
> exists to prevent; leaving it parked after the alarm defeats the alarm.
>
> **A RE-PIN NEEDS A SENTENCE, NOT A GREEN DIFF.** Adopted 2026-08-02, and it paid its bill the
> day it was written: BOTH of that day's "probably fine, just re-pin it" candidates came back
> **regression** on one grep each. A target that moved is a claim that the world changed, and the
> claim needs a cause. The audit's `15 → 12` was signed only once the three vanished terms were
> *named* and explained. Without the discipline, two live breakages would have been frozen into
> the baselines as truth.
>
> ⚠ **IN A DEMOLITION ARC, THE RECON IS HOW YOU LEARN WHAT THE CONDEMNED CODE KNOWS.**
> Adopted 2026-07-31. When a component is scheduled for deletion and its replacement designed,
> **read it before deleting it** — not for sentiment, but because the condemned code is often
> the only written specification of the thing you are about to rebuild.
>
> The worked example: `saveLocalFields` was sentenced by `docs/jit.md` §0 ("DELETED, not
> repaired") a full two days before anyone read it closely enough to notice that **its walk is
> the only written statement of which fields constitute a frame** —
> `(isArgument || isLocal) && !noPrint`, forward to save and backward to restore. **The sentence
> predated the discovery that the code was the spec.** Deleting first would have thrown away the
> definition and left the replacement to guess at it.
>
> **Two rules follow.** *Inherit the schema, not the bug* — the same machinery carries
> `CLAIM KANT-8`, so take the enumeration and leave the save/restore discipline behind. And
> *do not delete until the replacement is green*, because until then the condemned code is still
> the reference.
>
> ⚠ **PREFER A STRUCTURE THAT MAKES THE FAILURE UNCONSTRUCTABLE OVER A DISCIPLINE THAT AVOIDS
> IT.** A new family, adopted 2026-07-31 with three members found in one week. **Disciplines get
> audited; structures do not need to be.**
>
> | the failure | the discipline that avoided it | the structure that makes it unbuildable |
> |---|---|---|
> | value/signal conflation | care, in three loop handlers plus the block | **in IR a `br` carries no value and a `store` carries no control flow** — nothing to conflate |
> | a bracketing emitter leaving a stale value in flight | remember to clear it | **E1**: the emitter that commits *owns* the clearing, so an enclosing walk has nothing to re-commit |
> | sequential-state corruption from a second `testing()` on one action | split the fixture into two files and warn | **one `testing()`, then `jitRefire()` forever** — a rung cannot call it twice, so the corruption is not avoided, it is **unconstructable in rung shape** |
>
> The third is the instructive one because **nobody set out to fix it.** The refire scaffold was
> built for the run-time proof; it dissolved a tar baby that had already produced one phantom
> regression and forced a two-file split. **When a fix and a shape are both available, the shape
> is worth more than the difference in effort suggests** — because the discipline has to be
> re-applied by everyone who touches the area afterwards, and the shape does not.
>
> **RETIREMENT BY MAPPING** — the standing form when a fixture or harness retires into another:
> **list every assertion and where it now lives, in the commit, checkable line by line.** Do not
> assert equivalence. Silent coverage loss hides in exactly the gap between "these overlap" and
> "here are the eight things it asserted and here is each one's new home." Worked example:
> `jitPop.sh`/`jitElseT`/`jitThenT` retiring into ladder rung J2 (eight carried, two
> strengthened). And **historical provenance stands** — a provenance naming a since-deleted
> fixture records *what was run*, so rewriting it falsifies the record; add a retirement note and
> repoint only present-tense and forward-looking references.
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
>
> ⚠ **AND ITS SHARPENED FORM, ratified 2026-08-09 so the pattern is not misread as a scoreboard:
> THE ASYMMETRY IS UNMEASURED-CITATION LOSING TO MEASUREMENT — it is not one seat losing to
> another. A SEALED DOCUMENT IS AN INSTRUMENT AND GETS DOUBT-THE-INSTRUMENT TREATMENT.** Three
> citations, all the same shape and all cheap to have caught: **Amendment A** (a fixture name cited
> from a sealed wakeup instead of checked — `censusScratch` had been renamed a week earlier);
> **T-0** (a rule→kind *table* cited from a sealed staging doc instead of re-run — **13 of 21
> memberships wrong**, on a byte-identical binary, found by one grep); and **the `Looper` premise**
> (a whole mechanism question — resolved-vs-declared — built on top of T-0's bad row, so the
> divergence it went hunting for **did not exist**).
>
> **The last is the expensive shape and the reason this is doctrine rather than a note:** a
> defective citation does not merely state something false, it **generates downstream questions
> that are themselves well-reasoned and entirely unnecessary.** T-1 was designed carefully, fenced
> properly, and aimed at a phenomenon that was an artifact of a mis-transcribed table. **Re-measure
> a cited number before you reason on top of it** — the re-run is nearly always one command against
> a fixture that already exists, and the reasoning it saves is not.
>
> ⚠ **AND A THIRD OUTCOME THAT PREDICTIONS KEEP OMITTING — THE TREATMENT VOIDS THE CONTROL.**
> Ratified 2026-08-10, on a prediction that failed this way rather than by being wrong. **Any
> prediction about how a fixture will move under a treatment that touches the fixture's own read
> machinery must enumerate VOIDING as an outcome**, beside the pass and the fail. The worked
> example: the KANT-8 bracket rung predicted `incant/kant8T`'s K6 rows would *invert completely*,
> and said a *partial* recovery would mean something non-bracket was hiding in the blast radius.
> **Neither happened.** The treatment removed the very discriminator K3 exists to be, so **K3 went
> void and every row below it became uninterpretable rather than wrong** — by the fixture's own
> declared terms.
>
> ⚠ **AND THE SHARPEST STATEMENT OF THE WHOLE ASYMMETRY, EARNED 2026-08-10 WHEN **FOUR** RULINGS
> DIED IN ONE DAY TO FOUR CHEAP MEASUREMENTS.** Not one bad session — the doctrine **eating well**:
>
> | the ruling | what killed it | cost of the check |
> |---|---|---|
> | the **detach** pick over value-capture | M2's walker read — restore pairs **positionally** | one function, read |
> | **"copy forks the arms"** as a risk row | M1 — the jit **already returns by capture**, so capture *converges* them | one fixture |
> | **"the unpushed channel cost us the SEQ divergence"** | `ipc/` was **gitignored** ⚠ **— AND THAT PREMISE EXPIRED THE SAME DAY, see below** | one `git check-ignore` |
> | **"the whole interpreted arm crosses the seam"** | only `actionType` reaches `runAction`; coded rules bind `processAction` direct | one grep |
>
> ⚠ **AND THE THIRD ROW'S PREMISE HAS SINCE FLIPPED — CORRECTED 2026-08-13, AND THE CORRECTION IS
ITSELF THE LESSON.** `ipc/` was in `.gitignore` from `a5c6be1` (2026-07-02) until **`48f134a`
(2026-08-10) REMOVED it** — *"Seal 2026-08-10: ipc/ tracked (publicity accepted)"* — the **same day**
this table was written. All six channel files are tracked today; `git check-ignore` on them now
returns nothing.

**So the row was RIGHT WHEN MEASURED and is WRONG NOW**, which is a harder failure than being wrong
at the time: **a dated measurement written as a timeless fact.** It was repeated to Tony on
2026-08-13 as *"ipc/ is gitignored, so the ledger rides in no commit"* — false, and the channel file
was sitting as uncommitted dirt while being described as scratch.

**The rule this adds to the doctrine above:** *measure before you reason on it* has a twin —
**re-measure before you CITE it, and stamp the measurement with its date.** A premise with no date
cannot be told apart from a premise that has expired, and this table's whole subject is premises
nobody re-ran.

**EVERY ONE WAS SOUND REASONING ON A PREMISE NOBODY HAD RUN**, and three of the four were
> *load-bearing for a scheduling or design decision*. **The rule is not "reason less".** It is:
> **when a premise is one command away from being measured, measure it before you build on it** —
> and note that the two disciplines that caught these were structural, not vigilant: the
> **conditional pick** (name the precondition, gate the code on it) and the **negative control**.
>
> **THE PRECEDENT IS THE REFUSAL: DO NOT GRADE A VOIDED CONTROL.** Reporting *"this could not be
> evaluated"* is a result. Grading it anyway is reading a broken instrument — the failure this
> whole section exists to prevent — and it arrives **disguised as diligence**, because the rows are
> right there and they do have values. A two-outcome prediction has nowhere to put a voided run,
> and that absence is itself the pressure to misreport it.

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

## Where a finding goes — three registers, and picking the wrong one loses it

Measurement taken for one purpose routinely turns up a defect belonging to another. **CAPTURE, DO
NOT CHASE** — stopping to fix it derails the task that found it, and mentioning it in prose loses
it. Three destinations, and they are not interchangeable:

| register | for | shape |
|---|---|---|
| **`docs/fixIts.md`** | **the default.** Something is broken or owed, and it is actionable | a row: what · where (file:line) · evidence · done-when · owner |
| `docs/knownErrors.md` | a deep defect needing investigation and a **ruling** before anyone can act | long-form KE entry with measurement and discrimination |
| `TODO.md` | design and roadmap work, organised by arc | prose under its phase |

### ⚠ AND A FOURTH REGISTER, ADOPTED 2026-08-19: `incant/fixits/` — RUNNABLE CAPTURE

**PROSE CAPTURE ROTS; RUNNABLE CAPTURE DOES NOT.** An issue banked for Tony as a paragraph costs him
a reconstruction before he can start — the exhibit that forced this was *"what are the iterT1m
re-pins?"*, asked weeks after they were banked. So an issue owed to Tony is banked as an
**incantation he can run**, in `incant/fixits/`.

⚠ **RATIONALE AMENDED 2026-08-20 (Tony's observation, and it changes what counts as a regression):
THE REGISTER EXISTS BECAUSE PROSE HOOK-ITEMS GET *FORGOTTEN*, NOT BECAUSE THEY *ROT*. Retrieval
failure, not staleness.** The line above is true and is not the point. A perfectly fresh, perfectly
accurate paragraph fails just as completely if nobody is looking at it on the day it matters.

**So the generated seal line and its shutdown placement are not conveniences — they ARE the
mechanism**, and the files are what the mechanism points at. It follows that **any future change
making the nag skippable, hand-typed, or quieter is a regression against the register's actual
purpose**, however much it improves the files themselves. Judge changes to `fixitNag.sh` on that
axis, not on tidiness.

⚠ **AND THE CHEAP DISCIPLINE THAT FALLS OUT, for anything landing on Tony's hook mid-session: the
question is NOT "did we write it down." It is "will it be staring at him at shutdown." If the answer
is no, IT IS NOT CAPTURED YET** — it is merely recorded, which is the failure mode this register was
built to end.

⚠⚠ **THE SEAL LINE IS THE LOADED GUN** (Tony's coinage, 2026-08-20, and it is the name the practice
was missing). It is **not a reminder — it is an armed condition.** A fixit sitting in the queue at
shutdown is **pointing at Tony's foot until it is stepped.** That is the whole difference between a
docket and this register: a docket waits to be consulted, a loaded gun does not.

**The design consequence is the previous note with teeth: the line stays GENERATED, UNSKIPPABLE, and
TERMINAL in the brief.** Not "prominent", not "usually included" — those are decisions someone
re-makes every session, and the session where it goes badly is the session someone is busy.
**Silencing it is unloading someone else's gun** — which is not a tidying decision anybody but Tony
gets to make.

⚠⚠ **THE REMEDY BLOCK NAMES WHAT IT REMEDIES, AS ITS FIRST WORD — `BEHAVIOUR` or `ASSERTABILITY`**
(Clay, refinement to Addendum 3, 2026-08-20). Two classes, and they set opposite reader
expectations:

| first word | what changed | what a reader should expect on re-running the fixit |
|---|---|---|
| **BEHAVIOUR** | the machine does something different | the machine's answer moves |
| **ASSERTABILITY** | only the fleet's ability to *measure* it | **the output moves and the machine is UNCHANGED** |

**The block exists to stop a specific misreading**, and it is the difference between a reader asking
*"did the fix take?"* and asking *"wait — was anything broken?"* An assertability remedy looks
alarming precisely because output appears where there was none, while nothing about the program has
moved. Say which it is, first word, and the alarm never starts.

**THE FOUNDING EXAMPLE IS `iterT1m`'s ROW 2** (KE-4, ruled 2026-08-20). Restoring the deleted
`cerr` in `aCTionIterate`'s refusal arm **changed no behaviour whatever** — the poison
(`if iterator iterator.fLAG = true; return 0;`) was intact throughout and the walk already
terminated correctly at exit 0 with nothing printed. What it restored was **the fleet's only
presence-with-value cover for the poison**, which without it could be pinned only at zero, and H4
forbids that. `ASSERTABILITY`, and the fleet moving 52 → 53 green is the whole of the change.

**THE BLOCK ITSELF — ADDENDUM 3, transcribed verbatim from issue (Clay, Tony's ruling, 2026-08-20).**

**1. IF A RECOMMENDED SOLUTION EXISTS AT MINT TIME, IT GOES BELOW `stop();` LOUDLY** — a marked
`REMEDY:` block, **not buried in diagnosis prose**. It states **the fix**, **its site**, and **what
the incantation's output looks like when the remedy has taken versus not** — plus the
`BEHAVIOUR`/`ASSERTABILITY` first word above.

**2. THAT CHANGES WHAT THE CITIZEN IS FOR SUCH ISSUES: not an investigation but a VERIFICATION
HARNESS.** The gun discharges by **running the fixit after the remedy and blessing the output.**
That is exactly how row 2 resolved, **and it worked because the file prompted the "did the restore
fix it?" question instead of leaving that check to memory.**

**3. ~~NO REMEDY KNOWN IS ALSO INFORMATION — the ABSENCE of a `REMEDY:` block tells the reader this
one is genuinely open.~~ ⚠ SUPERSEDED SAME DAY BY ADDENDUM 4, BELOW.** The half that **stands**:
⚠ **never write a speculative remedy as if recommended** — candidate mechanisms stay in prose **with
their grade attached**, per the standing citation discipline. The half that **failed**: absence as a
signal. **It failed its first cold reader, on the first file to use it.**

**4. Retrofit clause — ✅ SATISFIED BY RETIREMENT, not owed.** It asked that `iterT1m` gain its
REMEDY block in the same commit that re-pinned it. `iterT1m` **retired by mapping** instead
(`859afe9`), which supersedes the retrofit: **a block's life ends when its citizen's does**, and its
content is mapped out like every other assertion — walk → `iterT1m.target`, refusal count → the
`pop.sh` grep row, exit 0 → `iterrunLIVE`. The reason lives on in KE-4.

⚠⚠ **ADDENDUM 4 — EVERY CITIZEN ENDS WITH `NEXT:` (Clay, Tony's ruling, 2026-08-20). IT IS NEVER
ABSENT.** The dead region of every fixit **terminates** in a marked `NEXT:` block whose **first word
is one of three grades**:

| first word | means | carries |
|---|---|---|
| **`REMEDY`** | fix known and **recommended** | Addendum 3's block — the fix, its site, taken-vs-not signatures, and the `BEHAVIOUR`/`ASSERTABILITY` word |
| **`BEST GUESS`** | candidate fix or fixes | each **with its grade**, and what would **promote or kill** it. ⚠ **Explicitly NOT a recommendation** |
| **`OPEN`** | no idea | **what would generate one** — the measurement, the trace, the census — or, if truly nothing is known, **that** |

**IT ANSWERS ONE QUESTION: "what do I do after ruling on what is on screen."** It may name a next
measurement, a fix, or a **fork** (*"if you ratify, then…"*). **A fixit whose output leaves the
reader asking *now what* is half-briefed, however good its diagnosis.**

⚠ **THIS SUPERSEDES ADDENDUM 3 CLAUSE 3'S ABSENCE-AS-SIGNAL, and the rationale is the register's own
doctrine turned on the register: ABSENCE IS AMBIGUOUS BETWEEN DELIBERATE AND FORGOTTEN**, and the
whole purpose of this register is that **nothing load-bearing rides on memory.** It failed its first
cold reader on the first file to use it — a deliberate, documented, correctly-graded absence read as
a missing piece, which is exactly what an absence always will.

⚠⚠ **ADDENDUM 5 — THE FOURTH GRADE: `RULED` (Clay, 2026-08-20).** `NEXT:` gains a fourth first
word. **`RULED` — the fix SHAPE is selected by ruling, the build is GATED, and the block names both
the gate and the shape.** Explicitly: **nothing in a `RULED` block is applicable yet.** A reader
arriving there learns *what was decided* and *what must happen before it becomes a remedy*.

**THE LIFECYCLE IS NOW ORDERED, and the transitions are named:**

`OPEN` → `BEST GUESS` → `RULED` → `REMEDY`

| transition | requires |
|---|---|
| `OPEN` → `BEST GUESS` | a candidate found |
| `BEST GUESS` → `RULED` | **a ruling issued** |
| `RULED` → `REMEDY` | **a build landed, with site and taken-vs-not signatures** |

⚠ **A citizen may skip states downward but MUST NEVER wear a later word than its state has earned.
`REMEDY` without a site is the specific overclaim this addendum exists to forbid.**

**WHY IT IS A GRADE AND NOT A QUALIFYING CLAUSE — this is the reasoning to keep.** The first three
grades are **epistemic**: *what do we know about the fix* (known / guessed / nothing). **`RULED` is
different in kind — it is DEONTIC: what has been DECIDED.** A project that rules on trajectory ahead
of evidence — which this one does deliberately and on principle — **will keep producing
decided-but-not-yet-buildable**, so the state recurs structurally rather than occasionally.

⚠ **AND IT IS THE REGISTER'S OWN THEOREM APPLIED TO THE REGISTER, for the third time: A GRADE THAT
NEEDS A QUALIFYING CLAUSE TO BE READ CORRECTLY IS A FAILURE SURVIVING CORRECT APPLICATION.** The
interim spelling was `REMEDY — BEHAVIOUR (shape ruled, build gated)`, which is accurate and which
**requires the reader to finish the line to learn that the first word overclaimed.** Same family as
absence-as-signal in Addendum 4: correct at the application site, wrong at the reading site.
**Provenance:** found by Clod on first contact, resolved interim by Clod correctly under the
then-existing taxonomy, promoted to a grade because the state is structural.

⚠ **AND THE IRONY IS THE LESSON, so it is written down rather than enjoyed:** everything f31's
`NEXT:` block needed **already existed** — it had been said, in full, in chat. **It just lived in a
conversation instead of in the file you had just run.** The answer to *"now what"* has to be staring
at the reader from the artifact, not resident two seats away. That is this register's founding
argument applied one level down, to the register itself.

⚠ **AND A RELAY LESSON, recorded because the failure was invisible from both ends** (2026-08-20). The
refinement above travelled and **its parent did not** — Addendum 3 was issued and never arrived, so
Clod held a rule about a block whose definition it had never seen. **The refusal was to flag the gap
rather than reconstruct the parent from context**, and that is the behaviour to copy: a relayed
amendment whose parent is not confirmed-landed is **one clause of a convention, not the convention**.
Reconstructing it would have produced something plausible, unmarked, and wrong — the citation
failure this project already has a ledger for, arriving through a new door. **Clay's half of the fix
is to carry the parent's full text whenever an amendment goes out against an unconfirmed ruling.**

⚠⚠ **THE SEAL CHECKLIST GAINS A LINE — THE FRONTIER INCANTATION (Clay, Tony's word, 2026-08-21).**
**Every seal revises `incant/frontier` to the current edge, RUNS it, and NAMES ITS FIRST FAILING
STATION in the seal.**

`incant/frontier` is the campaign's live edge in executable form: a numbered pipeline that walks the
current frontier one station at a time and **dies at the first thing that does not work yet**. That
death is the deliverable — the station that fails is where the campaign *is*.

**It is ONE file, revised in place, NEVER forked.** No `frontier2`, no `frontierOld`. A copy means
someone broke the practice.

**It is neither a fleet citizen nor a fixit citizen** — it never joins `pop.sh` and never appears in
`fixitNag`'s count, and the reason is the cleanest statement of what it is: **the fleet measures what
holds; the frontier measures what does not yet.** A red frontier is the normal, correct state.

**Every station prints PASS or FAIL with the value it read, unconditionally** (rule H4), and the
first FAIL stops the ladder so later stations run silently and nothing buries the frontier line.
Each station opens with a uniquely-named inert anchor (`fixFrontier<n>Here`) so a name-conditioned
Xcode breakpoint lands exactly there with everything the earlier stations built still in scope.
⚠ **And it caught itself being void on its first run** — `if frOk;` on a declared field tests
EXISTENCE, always true, so three stations printed PASS unearned. That is bear-trap #26's family, and
it is why the file now tests `frOk == 1` for flags while keeping `if x;` for lookups that can
return null. The structure found it, not anybody's memory.

⚠⚠ **THE PEAS PASS — A STANDING SESSION-OPEN STEP (Clay proposed, Tony ratified, 2026-08-20).
SHUTDOWN ARMS, WAKEUP CONFRONTS.** The seal line only works if something makes Tony look at it
again, so the count is now a **matched pair on the same generated number**, and neither half is
skippable or hand-typed.

**The step, at session open, before any new business:** run `genLadder/fixitNag.sh` **from the repo
root** and put its line at the **top of the wakeup exchange**. Generated, never typed — same
discipline as the seal line, same reason.

**⚠ AND THE FRAMING IS A QUESTION, NOT A STATUS.** The queue is Tony's, so the pass asks:
**step one now, or name which citizen goes first?** **New campaign work does not open while that
answer is pending.** Answering *"none — the new thing is hotter"* is a **legitimate ruling** under
fix-or-skip and closes the pass cleanly. What is not allowed is **defaulting into** that answer by
not asking: an unasked question reads identically to a skipped one a week later.

**AGEING GOES IN THE LINE**, which is why `fixitNag.sh` carries *oldest … since*. **A citizen three
sessions old is a different conversation from one minted yesterday**, and the pass exists to make
that difference visible without anyone reconstructing it.

**It costs zero new machinery** — the script exists and the wakeup brief exists. The ruling is only
*where the line goes* and *what Clod does about it*.

⚠ **ONE FILE MAY CARRY MORE THAN ONE TEST (Tony, 2026-08-20).** The unit is the *issue owed*, not
the assertion — a file that demonstrates two related things in one run is fine and is often better,
because it is one thing to run. Do not split a file per assertion.

**Each file carries four things.** An explanation in plain language — *this mechanism · is doing
this wrong · the fix wanted is this* — with ledger numbers only as a footnote. A driver action
that **demonstrates the issue live** and prints measured beside pinned, so the mystery is on screen
rather than in a document. A uniquely-named inert anchor (`fixIterT1mHere = 0;`) at the point where
the answers sit side by side, with a `cerr` naming what he is looking at, so a name-conditioned
breakpoint lands exactly there. And the house shape throughout: cached action, `cerr` sentinel, bare
calls, no `:=` captures.

**Three lives, one artifact.** Born as a reminder → stepped as a repro → on the fix, the same file
re-pins its expectation and **promotes into the fleet as the regression test**, or retires through
`parked.sh`'s two-stage pattern if the fleet already covers it. No orphaned prose at any stage.

### ⚠ A FIFTH REGISTER, ADOPTED 2026-08-23: `incant/designDocs` → `ProblemRecords` — THE OPERATIONAL HISTORY

**`docs/fixIts.md` says what is OWED. `ProblemRecords` says what we have FOUGHT.** They are different
questions and the second one had no home, which is why bear-trap knowledge lived in `CLAUDE.md` prose
and in the humans' memory, and why Tony kept having to ask what `H4` or `F-31` meant.

**One entry per PROBLEM, never per station or per rung.** `incant/frontier` iterates — its station 4
next month is a different animal from its station 4 today — so an archive keyed on where a problem
was met goes stale the first time the ladder rotates, and goes stale **silently**. `station` and
`vintage` are attributes; the problem is the identity.

**SKELETON, permanent:** `symptom` · `finding` · `workaround` · `solution` · `status` · `verdict` ·
`reviewed`. **FLESH:** `description`, and nothing else. **Trimming an entry deletes `description` and
nothing else** — mechanical, not a judgment about which sentences matter.

⚠ **THREE FACTS, THREE CHANNELS**, because this project has paid four times for putting two meanings
on one. `status` is the lifecycle grade only — the ratified `NEXT:` grades (`open` · `guess` ·
`ruled` · `remedy`) plus `baked` · `workaround`, with **two terminal flavours: `remedy` and
`retired-unreproduced`**, which are different tombstones on purpose. `verdict` is Tony's disposition
and is the **loud** channel — where FIX THIS goes, standing verbatim once written. `reviewed` is the
commentary ledger, append-only while live, collapsing to the final ruling at trim.

⚠ **THE TRIM GATE IS TONY'S AND IT IS STRUCTURAL, NOT REMEMBERED.** An entry is trimmable only when
`status` is terminal **and** `reviewed` is past the exact placeholder token `-- unreviewed --`.
`genLadder/ddPop.sh` asserts it, with an H7 negative control that strips a non-terminal record's
prose and requires the gate to go red. **The gate exists because four findings were withdrawn or
inverted in one month and what caught every inversion was the surviving record of HOW the original
conclusion was reached** — trimming an active or freshly-settled entry destroys exactly that.

⚠ **THE BIRTH RULE — ONE ACT, THREE EFFECTS. AN ID IN NEITHER PLACE IS NOT YET AN ID.** A new id is
born by writing its **one-sentence decoder line** (`incant/decoder`), **and** creating its **problem
record** with `status=open` and explicit placeholders, **and** rendering it with `tombstone()` before
it is committed. **Birth happens when a symptom is FIRST NAMED, not when the write-up happens** — an
archive that only records finished fights is systematically missing every fight in progress, which
are the ones most likely to be re-encountered.

⚠ **SKELETON ATTRIBUTES ARE WRITTEN TO SURVIVE ALONE** — one sentence each, leaning on no prose, and
`symptom` written as **what a future rematch would grep for**, because a rematch is recognised by
symptom and never by name. Nobody greps for `bt34`; they grep for *the measurement destroyed its own
subject*. This is cheap at birth and impossible to retrofit, so `tombstone()` in `incant/lookup` is
the enforcement: it renders the entry with the prose already shed, which is exactly what the trim
will leave. **Render before you commit.**

**Reading it:** `incant/lookup` is ONE verb over BOTH populations — `lookuP(bt34)` prints the
decoder's one-line definition and the problem record's operational history, whichever exist, so
nobody has to know which file to ask. `tombstone(x)` previews the trim. `lookupIndex()` lists every
record with its status. **`incant/decoder` stays one present-tense sentence per term; depth lives in
the problem records and never in the decoder.**

⚠ **`incant/fixits/` IS TONY'S QUEUE, NOT THE FLEET.** Nothing in it runs under `pop.sh` until it is
promoted. The single coupling is the seal line, and that line is **generated, not remembered** —
`genLadder/fixitNag.sh` reads the directory and prints
`Tony's fixit incantations waiting: N (oldest: <name>, since <date>)`. Tony's words for the record:
*forgetting is not an excuse once the seal reminds him to get off the pot.*

⚠ **THE STANDING RULE (Tony ruled, 2026-08-19): BANKING AN ISSUE OWED TO TONY MEANS WRITING ITS
FIXIT INCANTATION AS PART OF THE BANKING.** Capture means runnable capture. **Applies from now, not
retroactively** — existing docket items migrate as each becomes topical, and there is no bulk
conversion owed.

⚠ **THE EXPLANATION GOES BELOW `stop();`, NOT IN A HEADER COMMENT (Addendum 2, ratified by Tony
2026-08-20).** The runnable region ends at `stop();`; everything after it is **parse-dead — the
parse terminates there and the text below is never read.** So explanation prose is *unconstrained*:
no quoting, no comment markers, no brace discipline, no worrying about operators or semicolons.

**PROVENANCE: architect's word, 2026-08-20**, and a hostile-text probe run the same day agrees —
a block below `stop();` carrying an unmatched `{`, bare `:=`/`<-`/`&&`, an unterminated string
literal, an unclosed `/*`, a stray `%-` and a fake `code={ }` ran clean at exit 0 with the live
region intact.

**This retires the header comment for fixit files, and the reason is bear-trap #27:** a fixture's
comment header is *not inert* — `incant/jitXnest`'s header killed its parse at exit 138 with zero
bytes of output. A dead region cannot do that. **`ANCHOR` and `SENTINEL` lines stay ABOVE the stop**
— they are output, and output only comes from the live region. The dead region is for the reader,
never for the run.

⚠ **A finding recorded ONLY in a commit message is recorded and simultaneously lost.** That is
where fixits lived until 2026-08-16 and it is why this section exists.
⚠ **A `fixIts.md` row is MINION-READY OR IT IS NOT A ROW** — if it cannot be handed to someone with
no context, it is not finished being written.

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

23. **`tok sourceFile directivesFile` — THE DIRECTIVES FILE IS AN ARGUMENT, and a bare `tok
    File.twk` SILENTLY APPLIES ZERO DIRECTIVES.** No warning, exit 0, and the injected code simply
    is not in the generated `.mm`. So any retok **strips every directive** unless the file is named
    on the command line — `tok GroupRules.twk groupDirectives`. Found 2026-08-02 the expensive way:
    the directives vanished after a retok, reverting `groupDirectives` did NOT bring them back, and
    the edit looked guilty because the edit was the only thing that had changed *in the space being
    searched*. Bear-trap #19's corollary exactly, except the file the narrowing never looked at was
    the **command line**. Symptom to recognise: generated code that used to contain directive-
    injected statements now contains none, with a clean tok exit. (Related: `tokall` is a shell
    function whose body is `for item in *.twk; do tok $item; done` — see #10's correction — so it
    passes no directives file either.)
    ⚠ **CROSS-ANNOTATION, 2026-08-05 — THIS ENTRY AND THE 08-02 RULING POINT OPPOSITE WAYS, AND
    THE FORK HAS NOW COST TWO REBUILDS (one in each direction).** This trap says *name the
    directives file or lose your directives*; `docs/wakeup.md`'s 08-02 section says *the `.mm` are
    retok'd **without** directives at Tony's word*. **Both are true, and they answer different
    questions.** Read the discriminator before you type the command:
    | you want | the invocation | what you get |
    |---|---|---|
    | a **normal build** — the committed `.mm`, anything a POP or a baseline will be measured against | `tok GroupRules.twk` | clean codegen, no trace |
    | **ephemeral instrumentation** — you are hunting, and you want the hooks | `tok GroupRules.twk groupDirectives` | an **instrumented binary** |
    **The default is BARE.** `groupDirectives` currently carries ~10 `active` hooks (e.g. line 23
    on `aCTionDefinE`), so passing it injects live `cerr` trace into ordinary runs. A binary built
    that way must **not** be used to measure a POP and its `.mm` must **not** be committed —
    that is precisely the 08-02 defect where an *instrument* broke three POP targets by prepending
    ~290 lines of trace with zero content divergence. Paid for again on 2026-08-05: a retok that
    correctly applied bear-trap #23 flooded a JIT measurement, and the run had to be discarded and
    rebuilt bare. **A trap that tells you how to turn something ON is not a ruling that it should
    be on.**

    ⚠⚠ **AND THE 2026-08-18 HARDENING, WHICH RAISES THE STAKES: A DIRECTIVES BUILD IS
    *SEMANTICALLY DIFFERENT*, NOT MERELY INSTRUMENTED.** Everything above treats the hazard as
    *extra output* — trace lines polluting a diff. That understates it. A directive injects
    arbitrary code at its anchor, and some armed entries **change behaviour**: `aCTionNamE
    starting active` is `if arg eq "this" result = 0;`, which alters how a name resolves. A binary
    built with directives is therefore **a different program**, and a byte-agreement,
    fleet-unmoved or POP result taken on it is a result about that other program.

    **THE RULE, now doctrine rather than habit: REBUILD BARE BEFORE ANY CAPTURE.** Not "discard
    the run if it looks noisy" — the noisy case is the *lucky* one, because you can see it. An
    armed behaviour-changing directive produces a clean-looking capture that is simply about
    something else. The order is: `tok <file>` with no directives file · rebuild · *then* measure.
    Ratified 2026-08-18 after the F-15 landing, where the bare rebuild was done first and the
    before/after certification is only worth anything because it was.

25. **`testing()` ROUTES BY `isCoded`, AND AN INTERPRETED RUN CONSUMES IT — SO AN ORACLE PLACED
    ABOVE THE JITTED HALF SILENTLY MEASURES THE WRONG ENGINE, AT EXIT 0.** `testing()` calls
    `jitRunAction` only `if input.isCoded` and otherwise falls to `jitRunIfTest`, the control-flow
    smoke test (`Commands.rtn:663-664`). Running the action interpreted first clears that, so a
    fixture written in the natural order — *record the oracle, then jit it* — compiles nothing,
    asserts nothing about the JIT, and **prints a plausible number the whole way**. Symptom to
    recognise: `=== jitRunIfTest on <action> ===` where you expected
    `=== jitRunAction: entering on <action> ===`. **Fixture order is therefore load-bearing: the
    jitted half FIRST, the oracle last** — which is what `incant/jitJR` already does, for reasons
    its header never states. (2026-08-05.)
    ⚠ **AND ITS SHARPER SIBLING, found the same day: A POST-JIT INTERPRETED CALL IS NOT A CLEAN
    ORACLE FOR A *RETURNED* VALUE.** Putting the oracle last fixes the routing but not this. The
    identical interpreted call returns **120 standalone and 5 below the jitted fires** — the
    outermost activation's pre-call value, which is the save/restore signature — because
    `recursive` is **cleared at run time** by `restoreLocalFields` (`GroupActions.rtn:587`), so
    whether the frame bracket runs depends on **invocation history**. It went unnoticed for as long
    as it did because reading a **FIELD** in the same position is correct (`incant/jitJR` does
    exactly that and is right); only a **returned** value diverges, and returned values were not
    assertable until the return emitter landed. **The fix is a separate process, not a separate
    statement** — `incant/jitJRt2o` and `incant/jitJRt3o` exist for nothing else.

24. **AN INCANT ACCESSOR IS NOT A tok ACCESSOR, and the failure surfaces three files away.**
    Writing `field.listLengtH` (the incant spelling) in a `.rtn` produces bear-trap #10's exact
    signature — `Expected } or statement` / `FAIL Body3 at: …` / `Expected a semi-colon` — which
    **cascades and wipes the ENTIRE extern block from the regenerated `GroupRules.h`** (0 externs),
    so the build fails in `Bytecode.mm` with `no member named 'opEQ'` and nothing points at the
    real line. tok exits **139**. In tok source use `groupList` (the raw field, which is what
    `nextGroup` itself tests) or `contents()`. Generalises #10 from *GroupBody-flag/extern sync* to
    **any tok-vs-incant accessor confusion in a `.rtn`**, and the detector is the same either way:
    **`grep -c '^extern' GroupRules.h` after every retok.** A sudden drop to 0 is this. Same family
    as the three-languages-share-the-tree note — before editing, confirm which language the line is.
    (2026-08-02.)

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

26. **A FIELD WITH NO DATA RETURNS ITS OWN TAG FROM `.text`. THE INVOICE IS AT SIX PAYMENTS AND
    COUNTING — treat every `.text` read as "value, or the name if there is no value".** This one
    fact is behind an entire family of bugs that look unrelated, and its signature is always the
    same: **a wrong answer wearing the shape of a real reading.** Not a crash, not an empty — a
    plausible string that happens to be the identifier you were asking about.
    **The ledger, because the pattern is the point:**
    | # | site | what it cost |
    |---|---|---|
    | 1 | `+=` pre-load (2026-07-30) | an unguarded pre-load would concatenate onto the field's OWN NAME. The guard is `data`, **not** "text is non-empty" |
    | 2 | `if x.taG;` as an existence test (2026-08-03) | truthy whether or not the lookup found anything; produced a false tools-down alarm. **Use `if x;`** |
    | 3 | PJ-8's record clear (2026-08-06) | `clear()`ing the `JiT` attribute makes it read back as the string `"JiT"`, so every non-empty check in the fleet passes on it. **`setText("")`, never `clear()`**, for anything a POP reads |
    | 4 | the `parensMin` localizer (2026-08-06) | `pmOut = argument;` then printing `pmOut` gave `pmOut is pmOut` — **with the mechanism installed AND removed alike.** A fixture that discriminated nothing and would have been read as proof. Print from INSIDE the action instead |
    | 5 | `genParse`'s argument (2026-08-06) | the BARE form (`genParse(Parens)`) worked **by accident of this trap** — a node with no data echoes the tag, which happens to be the rule name — while the FIELD form failed by the same mechanism, because the *reference* node passed in has no data even when the *defined* field does |
    | 6 | define syntax (2026-08-06) | **`gsRule "Parens";` does NOT give the field data** and prints as `gsRule`; only `gsRule = "Parens";` does. Two characters, and the failure is a plausible name |
    **THE RULE THAT FALLS OUT, and it is cheap: never test presence or identity with `.text`.**
    Test `data` for "does this field carry a value", test the node itself (`if x;`) for existence,
    and when reading a name out of a field, be explicit about which you want. Payment 5 is the one
    to remember, because there the trap made something *work* — and a thing that works by accident
    breaks the day the accident stops.

27. **A FIXTURE'S COMMENT HEADER IS NOT INERT — it can kill the parse before the first statement,
    at exit 138 with ZERO BYTES of output.** Candidate trap, 2026-08-08, reproduced and bisected but
    **not diagnosed to a cause**. `incant/jitXnest`'s original header crashed the run: no output at
    all, not even the `Search list:` line, so it read as "the binary is broken" rather than "your
    comment is". Bisection: **fields-only crashed, every action was innocent, and the header ALONE
    reproduced it**; rewriting the header as plain prose fixed it with the fixture body untouched.
    The offending block held **indented, code-shaped lines** (statement-looking text with `;`, an
    assignment, and an arrow token). Consistent with the standing fact that **tok/incant have no
    lexer and comments are parsed, not skipped** (project memory; bear-trap #4 is the same family at
    statement scope, and the `/* */` type-name note is its sibling).
    **Practical rule until someone diagnoses it: fixture headers get PROSE, not pasted code.** If a
    header must show a construct, keep it un-indented and free of `;` and operator tokens.
    ⚠ **METHOD NOTE, recorded because it is the only reason a wrong cause is not written here:** the
    attractive theory was the `<-` **rebind operator** appearing in the header. It was **tested and
    FALSIFIED** — a header containing `<-` runs clean — *before* the bisect landed. Bear-trap #19's
    corollary in its cheap direction: the theory that survives narrowing is not thereby confirmed,
    and one test beat an hour of plausible reasoning.

28. **THREE INCANT SPELLINGS THAT FAIL WITHOUT SAYING SO — CANDIDATE TRAPS, symptoms reproduced
    and bisected 2026-08-09 while building the decoder, NONE DIAGNOSED.** Recorded as symptoms
    only, per bear-trap #18's split: reproduction proves the SYMPTOM, never the CAUSE.
    | spelling | what happens |
    |---|---|
    | `group[argument.text]` in an action body | **exit 139, ZERO bytes of output** — before the `Search list:` line, so it reads as "the binary is broken". `group[argument.taG]` in the identical position works. Bear-trap #26's family: `.taG` is the reliable read of a name |
    | `if !x.attribute;` | **exit 139, ZERO bytes of output.** The positive form `if x.attribute;` is fine, and so is `x.attribute == "literal"` |
    | `print "":;` for a blank line | prints the **string `quoteBody`**. Use `print :;` (jiquery's idiom). An empty string literal has no data, so it echoes its own tag — #26 again |
    | `eq` against a tag inside an `iterate` body | **matches EVERY member.** Both `if taG eq "x"` and
      `if fbCur.taG eq "x"` used as a skip guard in an `iterate`/`while ++` walk skipped the entire
      population — 43 installs became 0. No error, no diagnostic; the walk simply does nothing and a
      control built on it is **void rather than negative**. Found 2026-08-19 building F-31's negative
      control, and the A/B that replaced it needed no name test at all |
    **And a fourth, mechanical rather than syntactic, in the same silent class: `include(X)`
    SEARCHES NO PATH.** `getFile` opens the name relative to the working directory; every
    includable file is registered by hand in **`incant/setup`'s `fILEs` registry**
    (`grammar`, `utilities`, `unitTests`, `jigcorpus`, …). A new corpus file that is not
    registered there fails with `getFile: could not open file: <name>` **and the run continues to
    exit 0** — so the file is simply not there and nothing downstream says why.
    ⚠ **The instructive part is the shared signature, not the three spellings:** all four fail in
    a way that points at the wrong thing. Two produce no output at all (which reads as a broken
    build), one produces a plausible string (which reads as data), and one produces a missing
    include at exit 0 (which reads as a working run). None of them names the line.

29. **A `/* */` BLOCK COMMENT WEDGED BETWEEN TWO ARMS OF AN `if`/`or` CHAIN — immediately before an
    `or` — WIPES THE ENTIRE EXTERN BLOCK TO ZERO.** Bear-trap #4 one scope up: same no-lexer cause
    (comments are *parsed*, not skipped), but `/* */` instead of `//`, and **chain arms** instead of
    an `if`'s governed statement. Signature is #10/#24's exactly — `grep -c '^extern' GroupRules.h`
    goes **288 → 0**, and the build then fails three files away in `Bytecode.mm` with `no member
    named 'opEQ'`. tok prints `FAIL Block at: or <cond> {` **and** `FAIL Body3 at: {_...`, where the
    Body3 line names the **START of the enclosing function**, not the comment — so the diagnostic
    points at a function that is fine.
    **MEASURED THREE WAYS, 2026-08-16, in `genParse.rtn`'s `planTerm` (the same edit each time,
    only the comment moved):**
    | placement | externs |
    |---|---|
    | above the whole `if`/`or` chain | **288 — fine** |
    | inside an arm's braced body, after the `{` | **288 — fine** |
    | between two arms, immediately before an `or` | **0 — fatal** |
    **The cure is the convention that was already there**: `planTerm`'s existing design comments all
    sit above the chain, and the trap was walked into by not copying them. Put the prose above the
    whole chain, or inside the arm it describes — never in the gap between arms.
    ⚠ **The bisect is worth copying too, because content looks guilty and is not.** Every paragraph
    of the comment killed it individually, which is what proves the cause is POSITION rather than
    any token inside it — an hour of hunting for a bad character is an hour wasted. And the standing
    canary is what caught it: **`grep -c '^extern' GroupRules.h` after every retok.**

30. **THE DIRECTIVE CONTRACT: `groupDirectives` APPLIES AT MOST ONE DIRECTIVE PER TARGET FUNCTION —
    THE FIRST *ARMED* ENTRY IN FILE ORDER. Every loser injects NOTHING, silently.** ⚠ **This is BY
    DESIGN, not a tok defect** (ratified 2026-08-16) — but it is undocumented everywhere else and
    reads exactly like a broken directive. Sibling of #23: that one is about *passing* the
    directives file, this one about what happens once you have.
    **The three clauses, each measured 2026-08-16:**
    - **First armed wins.** Two `active` entries on `aCTionDefinE` — the first at file line 23
      fired, the second at line 27 did not.
    - **Disarmed entries are SKIPPED ENTIRELY and do not hold a slot.** A `ctive` dummy placed
      *first* did not block an `active` entry below it. (The file's own convention: dropping the
      leading `a` from `active` disarms an entry while parking it for reuse.)
    - **Anchors do NOT create separate slots.** The two `aCTionDefinE` entries above had
      *different* anchors (`"if Attributes"` vs `"if isLiteral"`) and still contested one slot.
    **THE FAILURE MODE IS THE DANGER, not the rule:** the losing directive produces no warning, a
    clean `tok` exit, and an intact extern block. You get a well-formed directive, a successful
    build, and zero output — which reads as *"the code path never ran"* when the truth is *"your
    instrument was never installed."* That is a whole afternoon aimed at the wrong question.
    ⚠ **THE DISCIPLINE, and it is H1 one level down — an instrument must prove it is installed
    before it is trusted: `grep <your-marker> GroupRules.mm` after the retok, BEFORE the build.**
    One command, and it converts a silent no-op into a visible one. It is what caught this.
    **Live example in the tree:** `aCTionDebuG` carries **three** stacked entries. All three are
    disarmed, so the stack is harmless parking today — but arming *two* of them would silently give
    you only the first, and nobody has ever found that out.

31. **`incant/setup` IS READ AT RUNTIME, SO A NEW REGISTRATION GOES LIVE THE MOMENT IT IS SAVED —
    AGAINST WHATEVER BINARY IS INSTALLED. A registration whose extern is not in that binary turns
    green fixtures red and reads as N REGRESSIONS FROM YOUR EDIT.** Measured 2026-08-17, with a
    control. This is the runtime twin of the stale-`.mm` hazard: that one is *a stale build compiles
    and runs*, this one is *a live registration runs against a stale build*.
    **The signature, on stderr, in every fixture's output:**
    ```
    setCompiledMethod: ERROR no method found <name>
    setCompiledMethod: failed for <name>
    setRuleAction: could not set action for immediateAction
    ```
    **What it cost, and why the arithmetic is the trap:** adding `compile immediateAction;` to
    `incant/setup` before the rebuild dropped `pop.sh` from **40 green to 37**. Four rows carried the
    error line; three of them went red on it **alone**. Nothing was broken — the extern simply did
    not exist yet. **The three reds are in fixtures that have nothing to do with the new command**
    (`manyScratch.target`, `displayForm baseline`, `oneTest baseline`), because the error prints into
    the captured output that a diff-based row compares.
    ⚠ **THE DISCRIMINATOR IS A CONTROL, AND IT IS ONE COMMAND: `git checkout HEAD -- incant/setup`,
    re-run the fleet.** If the reds vanish against the *same* binary, the cause is the pending
    rebuild and not your code. That reproduced the seal exactly (40 green) and turned a three-
    regression scare into a one-line diagnosis. Restore the working copy afterwards and **check the
    md5** — the file is somebody's uncommitted work.
    **Generalises past `setup`:** any incant source read at runtime — the grammar, the registries —
    can reference C++ that a not-yet-rebuilt binary lacks. **Order is rebuild, then measure.** A
    fleet number taken between the edit and the build is a number about the gap, not about the code.

32. **A MULTI-STATEMENT INDENTED `if`-ARM FOLLOWED BY AN `else` BREAKS THE PARSE — AND THE ERROR
    NAMES A HEALTHY ACTION, NEVER THE OFFENDER.** Measured 2026-08-21 with two passing controls, so
    it is the COMBINATION and not either half:
    | shape | result |
    |---|---|
    | multi-statement indented arm, **no** `else` | ok |
    | single-statement `if` + `else` | ok |
    | multi-statement indented arm **then** `else` | **BROKEN** |
    ⚠ **THE MISDIRECTION IS THE EXPENSIVE PART.** It fails at **define** time, so the whole `define`
    block dies and the run reports `RunRulE: expected a method not <X>` where **X is the FIRST action
    in the file** — an action that is perfectly fine. Every instinct then says "what is wrong with
    X", and nothing is. Bisect by *removing later actions*, not by staring at the named one.
    **The cure is the flag idiom:** `frOk = 0;` · set it in a single-statement `if` · then two
    separate `if`s on its value. `incant/frontier` uses it at all eight stations and its prose says
    why. Same no-lexer family as bear-traps #4 and #29 — the parser has no idea a block ended.

33. **AN EXTERN WIRED AS AN INCANT COMMAND MUST RETURN `GroupItem`. RETURNING `int` KILLS THE
    PROCESS ON THE STATEMENT *AFTER* THE CALL.** Measured 2026-08-21. The command machinery takes
    the return value as a `GroupItem*`, so an `int` is read as a pointer and the crash lands on the
    NEXT statement — the callee's own entry trace never fires, which reads exactly like *"the
    command was never registered"* and sends you hunting registration (bear-trap #7/#19 territory)
    for something that dispatched perfectly.
    **Census at that date: of every registered `immediateAction` command in the tree, ZERO return
    `int`.** The convention was total and undocumented. If a verb needs to report a count, PRINT it
    (rule H4 wants the value printed anyway) and return `trueResult` or `null`.
    ⚠ Detector: a command whose first line of tracing never appears, while the statement before it
    completed normally. Look at the RETURN TYPE before you look at the registration.

34. **TRUTH-TESTING A RULE-SHAPED VALUE FIRES ITS ACTION. `if x;` IS NOT A READ — IT IS A CALL.**
    Found by Tony 2026-08-22 in `incant/frontier` station 3; reproduced the same day, and it took
    the investigating agent's OWN probe within the hour. `aCTionIF` evaluates its condition by
    calling the condition node's method — `GroupRules.mm:857`, behind the `isMethod(instructType)`
    gate — which is the normal path, because a condition is usually an `ExpressioN` whose `gMethod`
    is `aCTionExpressioN`. But `instructType` and `gMethod` both live in **`groupBody`**, and
    `copyOf` (`Commands.rtn:252`) does `*groupBody = *grup.groupBody`. **So a `copyOf` twin of a
    rule carries that rule's action, and `if twin;` RUNS IT.**
    For `Braced` the action is four lines (`GroupRules.mm:136`): `input->clear()` then
    `setGroup(ExpressioN)`. So the test that asked *"did the copy work?"* **destroyed the copy**,
    and the next station read the corpse.
    ⚠ **THE COST WAS A SEALED QUESTION AIMED AT A GHOST.** The 2026-08-21 seal named station 4 as
    the campaign's edge and asked *"what does install require that a `copyOf` twin lacks?"* The
    answer is **nothing** — station 4 was installing onto a node station 3 had gutted. A whole
    session's front question, generated by a one-line hazard three lines upstream.
    ⚠ **AND IT BIT THE INVESTIGATION, WHICH IS WHY THIS IS A TRAP AND NOT A NOTE.** A probe wrote
    `frOut := activateBody(twin); if frOut;` — and `activateBody` **returns the rule**, so the
    truth-test fired the action and **wiped the `CodE` that had just been attached**. The probe then
    reported, correctly and uselessly, that no `CodE` was there. Knowing the hazard did not prevent
    it; the shape did.
    **THE RULE: never truth-test a rule-shaped value. Assert on an artifact a fired action cannot
    fake** — `groupList` length (a cleared node reads zero), or the presence of a `CodE`/`BlocK`
    reached by subscript. Call for effect and drop the return where the return is the rule
    (`activateBody`, `compile`). `incant/frontier` does this at every station and its prose says why.
    ⚠ **RETIRE THIS ROW WHEN THE gMethod MOVE LANDS** — rule actions relocate to
    `rStuff.actionMethod` and the vacated `gMethod` reverts to the structural default, which kills
    this and the documented statement-scope twin (*"naming a rule FIRES it"*, `GroupRules.mm:864`)
    in one stroke. Until then the restriction is absolute. Retire with a note, do not delete.

35. **A CHAINED-SUBSCRIPT READ IN PRINT POSITION IS UNRELIABLE — `opDot` UNWRAPS ONCE.** Second
    confirmed instance of the same single-unwrap poisoning (Tony named the first on 2026-08-22
    reading `frTwin.taG` as `Braced` **after** the node had been turned into `ExpressioN`).
    Measured the same day, one run, one node: `cerr Grokking["Braced"].listLengtH` printed
    **`Braced 11`** — two tokens, a name and a wrong number — while `prLive.listLengtH` through a
    **bare local** printed **`3`**, which is correct.
    | spelling | reads |
    |---|---|
    | `cerr Grokking["X"].prop` — chained subscript, print position | **two-token echo, wrong value** |
    | `prLive <- Grokking["X"];` then `cerr prLive.prop` — bare local | correct |
    ⚠ **THE DANGER IS THAT IT ANSWERS**, which is bear-trap #26's whole family: not a crash, not an
    empty, but *a plausible number wearing the shape of a reading*. An 11 is not obviously wrong
    until something else says 3.
    ⚠ **AND A SECOND VOIDING IN THE SAME PROBE, worth as much as the first: `if x;` after `<-` is
    not an existence test.** `prSub <- Grokking["zzzNotARule"]; if prSub;` reads **TRUE** — the
    rebind mints a node, so the miss is unobservable. The direct form `if Grokking["zzzNotARule"];`
    correctly reads **0**. A census built on the `<-` spelling reported *"no rStuff"* for **15 of 15**
    rules including a name that does not exist — uniform, confident, and void. **Every probe carries
    a hit/miss control pair** (`minionWork/probeTwinCopy` rows 0a/0b) for exactly this reason.
    **The rule: probes read through bare locals, and test existence with a direct subscript.**

36. **A BACKTRACE NAMES THE LINE THAT DIED, NOT THE LINE THAT READ NULL — AND A CONTROL SPECIFIED
    OFF A BACKTRACE INHERITS THAT OFF-BY-ONE.** Found 2026-08-22 while building the rStuff census's
    own control. The crash frame read `runRuleAction ... GroupRules.mm:12411`, so the control was
    written against **12411**. The `rStuff` read is at **12410**:
    ```
    12410   RuleStuff *ruleStuff = field->rStuff;     <- the null read
    12411   if ( ruleStuff->label )                   <- the line the backtrace names
    ```
    The null arrives on one line and is dereferenced on the next, so the debugger points at the
    **consumer**, never the **producer**. Harmless when reading a crash; **not** harmless when the
    line number becomes a control, a target, or a grep — the control then looks for a site that
    does not exist and reports the whole census void (or worse, silently passes on a wrong row).
    ⚠ **The tell is that the named line has no obvious null source in it.** When a backtrace line
    dereferences something it did not fetch, walk BACKWARD to the fetch before writing the number
    down anywhere. Same family as bear-trap #19's corollary — the cause sits outside the space the
    evidence points at — one line up instead of one file over.

37. **A COMMISSIONED ARTIFACT'S `return` UNWINDS THE BLOCK THAT FIRED IT — SO ANY BLOCK THAT
    TOUCHES AN ARMED RULE CAN LOSE ITS TAIL, SILENTLY.** Measured 2026-08-22 with two controls.
    A generated body ends `return runRuleAction(this);`. Under the two-doors ruling door two mints
    **no frame**, so that return unwinds whatever frame it stands in — which is the *caller's*
    block, not the artifact's. Observed the first time a live body carried a return.
    | generated body | the firing block |
    |---|---|
    | with `return runRuleAction(this);` | prints up to the fire, then **NOTHING** — no later statement, no verdict, no flag set |
    | without it | runs to completion |
    ⚠ **THE SYMPTOM IS AN ABSENCE, WHICH IS WHY IT COSTS.** The block does not crash and does not
    report; it simply stops, and the statements that vanish are usually the ones that would have
    said something was wrong. `incant/frontier` station 6 printed its values and then **no verdict
    at all** — an H4 hole opened by the defect, not by the fixture. Two authors were bitten the same
    day: the station, and then `minionWork/probeBind`, whose first version did commissioning and
    reporting in one action and ended silently at the commissioning line.
    **INTERIM DISCIPLINE, and it is a seat change rather than a fix: put verdicts and assertions ONE
    STATEMENT LATER, in a block the artifact cannot unwind.** `frVerdict6` is the pattern — station 6
    captures its values, a sibling action evaluates them. The assertion is unchanged; only its seat
    moves.
    ⚠ **RETIREMENT CLAUSE, keyed to containment landing:** ruled 2026-08-22 (Amendment 4, Mark 1) —
    the machinery that fires a commissioned body **consumes the body's return as a value, never as
    control flow**; *"leave the artifact"* terminates at the firing boundary. When that lands in
    `runRuleAction` and its firing callers, retire this row **with a note**, and the relocated
    verdicts may come home.

38. **DECLARING AN ITERATE CURSOR IN THE `define` BLOCK LIMITS THE WALK TO EXACTLY ONE MEMBER —
    SILENTLY, AT EXIT 0.** Found 2026-08-24 while writing a census that reported **1** where the
    answer was **60**, and the wrong number looked entirely healthy: no error, no diagnostic, a
    sentinel reached, a clean exit. Measured as a one-run A/B in `minionWork/probeCursorDeclared` —
    same process, same registry, two arms differing by one declaration line:
    | arm | cursor | members visited |
    |---|---|---|
    | A | `pdDeclared;` named in the `define` block | **1** |
    | B | `pdFresh` introduced by `iterate` itself | **60** |
    ⚠ **THE DANGER IS THAT IT PUNISHES GOOD HABITS.** Declaring your locals up top is what every
    other field in an incant fixture does, and `incant/f31`'s `fbWalk` — the walk this idiom is
    copied from — happens to get it right only because `fbCur` and `fbTerm` are **never declared**,
    which its source says nothing about. So the natural, tidy spelling is the broken one, and the
    working example gives no hint why it works.
    **The rule: never declare an iterate cursor. Let `iterate` introduce it.** And per rule H11, a
    census over a known population states the expected magnitude before it runs — this one was
    caught because 1 was obviously not 42-ish, and a walk that returned 55 instead of 60 would not
    have been.
    Same family as bear-trap 28's fourth row (`eq` against a tag inside an `iterate` body matches
    EVERY member, taking 43 installs to 0) — **silent iterate-walk miscount, opposite direction**:
    that one over-matches to nothing, this one under-walks to one. Both produce a plausible number
    and neither names a line.

⚠⚠ **RULING E-A — THE ATTACH-AT-SUCCESS LAW. Tony, 2026-08-24, minted on a measured Part 1.**

**ATTACHMENT HAPPENS ONLY AT THE SUCCESS BOUNDARY. NO PROVISIONAL ATTACH, EVER. Iterating forms
unwind to the pre-attempt state on failure.** This is the failure half of *a labelled sub-term
attaches its children*, written down.

**It is DESCRIPTIVE, not new** — `containerTo` (`RuleStuff.twk:595`) already embodies it, and the
law was ratified only after that was **measured rather than read**, because `containerTo` had never
executed: its sole caller is genParse's emitter, and no generated parse method calling it has ever
been built.

| cell | result |
|---|---|
| mark ON a container entry | `match=1`, `into` **0 → 1** |
| mark NOT on an entry | `match=0`, `into` **0 → 0** |

⚠ **THE HIT CELL IS THE ANTI-VACUITY CONTROL AND IS NOT OPTIONAL.** `0 → 0` alone is exactly what a
function that never attaches anything would print, so the miss on its own asserts nothing. Pair
every zero-expecting row with a non-zero sibling.

**The shape the law demands is one-directional and visible at a glance: MATCH FIRST, ATTACH AFTER.**
In `containerTo` the attach sits inside the success branch and is immediately followed by
`return true`; the failure path never reaches it, and `atRuleMark` advances only in that same
branch. Any new leaf helper copies that order — a helper that mints a node before it knows the match
succeeded has already broken the law even if it later tries to tidy up.

**Cross-reference:** `incant/fixits/litToMissing`, the citizen that surfaced the gap, and
`litTo` (`RuleStuff.twk`), the first helper written *against* the law rather than found to comply
with it.

⚠⚠ **RULING D — SHAPE, LIVENESS, AND BIRTH. Tony, 2026-08-22, and it is the real yield of the
rStuff census.** Two clauses, and they point opposite ways on purpose.

**D1 — AN `isRule`-CLASS FLAG SAYS *RULE-SHAPED*, NEVER *LIVE*.** `copyOf` copies `groupBody`
wholesale and never copies `rStuff`, so after Ruling A (a twin is a specimen, not an organism) a
`groupBody` flag can only ever mean *shaped like a rule*. **Liveness is asked of `rStuff` itself —
presence IS the liveness test.** Absence is **lawful**: it is what a specimen is. Code touching
`rStuff` guards for it, and where the yield matters the specimen semantics apply — `runRuleAction`
returns `trueResult`, because for an inert specimen *"ran successfully, nothing happened"* is the
truthful report.

**D2 — `isLabel` IS A BIRTH CERTIFICATE, NOT A SHAPE FLAG.** A label exists only as the result of a
live parse, and its `rStuff->rule` link is part of that birth. **So `isLabel` implies live `rStuff`,
always.** An `rStuff`-less label is **not a specimen — it is wreckage**: something upstream broke,
copied, or hand-built what only a parse may mint. Absence here is **unlawful — refuse loud at the
point of discovery, naming the invariant**, because the defect happened in the getting-there and
this is merely where it became visible.

⚠ **THE DIAGNOSTIC THAT FALLS OUT, and it is the one to remember: THE DEFECT IS A QUESTION POSED TO
THE WRONG ORACLE.** `processFlags` guards an `rStuff` deref with `if (isRule)`; `processCode` guards
one with `if (isLabel)`. Both flags live in `groupBody`, which is **copied**; the thing being
dereferenced is **never** copied. So the guard passes and the deref dies — and it reads as a
mysterious crash rather than as a wrong test. **Whenever a guard and its subject live in different
structures, ask whether they can disagree.**

⚠ **AND A CERTIFICATION THE ARCHITECTURE EARNED FOR FREE — THE DISPATCH IS THE GUARD.** Of the 78
`rStuff` deref sites, **34 are the generated `parse*` family, and not one is reachable by a
specimen** — they are dispatched *through* `rStuff->parseMethod`, so a node with no `rStuff` cannot
arrive. That is **structure, not audit**: nobody has to remember it, and it cannot rot. Worth
knowing when the parse-generation design is next weighed — it bought a whole family of
crash-immunity as a side effect of how it dispatches.

**CLOSED BY RULING, so nobody re-opens it:** *"does the crucible ever mint an `isLabel` specimen?"* —
**no, ever.** Labels do not wander; they are tree denizens after a parse. A label specimen is not a
direction the campaign might take, it is a state the machinery must report as a wound.

> **THE GLOSS CONVENTION — NO MINTED ID SHIPS WITHOUT A TWO-TERM GLOSS.** Tony's suggestion,
> adopted 2026-08-22, effective immediately, **all seats**.
>
> Every minted identifier travels with a two-term gloss on **first mention in a document or
> message**; repeats may go bare. **The gloss is the HOOK, not a summary** — the thing that makes a
> reader go *"oh, that one."*
>
> `F-31` (tokenize snake-eats-tail) · `F-13` (aliased bodies) · `R-4` (compile owns preconditions) ·
> `#31` (Tony builds C++) · `#34` (truth-test fires action) · `#37` (artifact return unwinds caller) ·
> `H11` (census needs a positive control) · `Ruling A` (twin is a specimen) · `Ruling B` (gMethod
> vacancy) · `Ruling C` (compile's two refusals) · `Ruling D` (shape vs liveness vs birth) ·
> `Mark 3` (producer asserts the invariant)
>
> **The gloss is assigned AT MINTING, in the register where the id is born**, and registers gain a
> gloss field; when entries reach DesignDocs it joins the lowercase field set. `docs/wakeup.md`
> carries the gloss block — one compact `id → gloss` line each, **live ids only**, maintained as
> ordinary register upkeep.
>
> ⚠ **THE CONSTRAINT IS A COMPREHENSION CHECK, NOT A STYLE RULE: a row that cannot be named in two
> terms is not understood yet.** And the reason it binds every seat rather than being a nicety —
> **a gloss that drifts between seats is a third dialect**, which is the disease it cures. Backfill
> of live ids and the wakeup template addition are Clod-sized, queued post-seal.

> **RULE H11 — A CENSUS WITHOUT A KNOWN-POSITIVE CONTROL IS NOT A MEASUREMENT.** Adopted
> 2026-08-22, promoted from practice the same hour it was practised, because it caught **two
> confident wrong numbers in one census** — and neither looked wrong.
>
> The rStuff census pre-registered a clause: *both already-known sites must appear in the raw hits,
> or the count is void.* They are the control pair, not decoration. It fired twice.
> - `grep -r --include=*.mm` — **the globs were UNQUOTED**, so the shell expanded them against the
>   cwd before grep saw them. Reported **64 hits** over a file set that included `.md` files. Then
>   `ugrep` ignored `--include` entirely, warned about it in passing, and printed a total anyway.
> - The pattern `->rStuff->` **missed the entire local-deref idiom** — `RuleStuff *s = x->rStuff;`
>   then `s->member`, which is precisely the shape of `runRuleAction`, **the crash that started the
>   census.** A census of a population that excludes the known member is not a small error.
>
> **The corrected count was 116 raw / 78 sites.** The first number, 64, was plausible, quotable, and
> wrong. **Nothing but the control clause stood between it and the report.** Same family as H9 (a
> count is a value, and a wrong one arrives wearing the shape of a right one) — this is its
> constructive half: **name the rows the search MUST return before you run it.**
>
> ⚠ **AND THE PREDICTION-DISCIPLINE NOTE THE SAME RUN PAID FOR: COUNTS WITHOUT A MECHANISM BEHIND
> THEM ARE GUESSES WEARING NUMBERS.** Graded across both seats, every prediction grounded in a
> *mechanism* held — reachability, where the bulk would live, at-least-one-can't-tell — and **every
> bare count missed, in the same direction, by up to 3x.** Predict mechanisms; when you must predict
> a count, say what mechanism sets it, or mark it as the guess it is.

> **RULE H10 — THE CITATION BOUNDARY: SMOKE-GREEN AUTHORIZES CONTINUING, ONLY A FLEET CHECK
> AUTHORIZES LANDING. A smoke-green is NEVER citable as fleet-green.** Adopted 2026-08-13 (SEQ 60,
> Tony's two-tier proposal). `genLadder/smoke.sh` is the iteration bell — fixture-under-test ·
> oracle · same-door regression · liveness canary · fleet-unmoved — one screen, and **WIP by
> design**: the membership rule is durable, the four names are today's values and swap when the
> frontier moves. `pop.sh` is unchanged and owed before commit, after any C++ rebuild of shared
> machinery, and before any target re-pin.
>
> ⚠ **AND THE PROPOSAL NEEDED ONE WORD CHANGED, FROM THE EXECUTION SEAT: UNMOVED, NOT GREEN.**
> `pop.sh` exits 1 today and has all day — `census.target`, `iterT1m` and its refusal count, and the
> `oneTest` baseline AUDIT block are red at the mark and owed a re-pin by someone else.
> *"Only pop-green authorizes landing"* would have blocked SEQ 56 and SEQ 58, **both of which landed
> correctly against an already-red fleet.** The landable property is that the fleet did not MOVE,
> diffed against a capture banked before the first edit.
>
> ⚠ **AND THE PREMISE UNDER THE TWO TIERS WAS MEASURED AND DOES NOT HOLD: THE SLOW TIER IS NOT
> SLOW.** `oneTest` 0.04s, every fixture ~0.03s, and **the entire `pop.sh` fleet 0.64s**. A
> four-fixture smoke run saves about half a second. **What the operator actually pays is SCREEN, not
> seconds** — ~90 lines ending in POP FAILED, re-read every iteration to spot whether *your* change
> moved anything. So `smoke.sh` does **not** run a cheaper subset; it runs the WHOLE fleet and
> reports it as ONE LINE. **When a tiering proposal cites cost, measure the cost first — the fix may
> be a different fix than the one being asked for.**

> **RULE H9 — A CENSUS MATCHES THE IDIOM FAMILY, NOT THE SURFACE FORM.** Adopted 2026-08-07,
> after a census miscounted its own subject **twice in two passes, in both directions.**
>
> Counting sentinel-returning rule actions by `return trueResult|falseResult` reported **1**. The
> commoner idiom is `result = falseResult; … return result`, so the real figure was **6** — and a
> re-census that matched assignments then reported 6 where the true yielding population was **4**,
> because two of the hits assigned a sentinel to a *local flag* and to an *operator slot* and
> returned something else entirely.
>
> **AN UNDERCOUNT READS AS A SMALLER PROBLEM; AN OVERCOUNT READS AS A BIGGER ONE. Neither reads as
> a broken instrument**, which is what both were. A census is an instrument and inherits every rule
> on this list: state what it matched, and prefer a form that fails loudly over one that answers
> plausibly. Where the population is small enough — 33 here — **read the hits by eye before
> reporting the number**, because the classification, not the grep, is the finding.
>
> Same family as H4's absence-versus-value: a count is a value, and a wrong one arrives wearing the
> shape of a right one.
>
> ⚠ **COROLLARY, 2026-08-07 — A REFUSAL CENSUS REPORTS THE *FIRST* BLOCKER, NOT THE BLOCKER SET.**
> A walk that refuses a rule stops at the first term it cannot classify, so a census of refusals is a
> census of **frontiers**, not of causes. Closing one gap does not unblock the rules it appeared in;
> it reveals their next refusal. Measured: closing the container gap moved `BrancH` from *"term
> BrancheS unclassified"* to *"term SemI unclassified"* — same rule, next blocker — and left
> `UnaryXP` blocked on its second term after its first was fixed. A sequencing claim of the form
> *"closing gap A unblocks rule R"* is therefore **unsupported by a refusal census** and needs the
> rule re-run after the close. Total refusals falling (99 → 97) is real progress and is **not** the
> same measurement as any rule becoming plannable.

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
