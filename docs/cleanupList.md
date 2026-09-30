# Cleanup list

A standing list of cruft spotted mid-stroke (Tony, 2026-09-28). **When you spot cruft, add an entry and keep going; don't act on it in flight.** Tony decides the cuts, one cleanup pass at a time. A cut that lands moves its entry to **Done**, with the commit.

Each entry: **what and where** (file:line) · **why it looks deletable** · **the census or measurement that would confirm it** · **seen** (date).

## Open

### `labelMinters`
- **What/where:** `measure.twk:279` (`extern int labelMinters(GroupItem rule)`), declared in `measure.h`; also a DesignDocs slug (`TokFiles -> Generate -> labelMinters`).
- **Why deletable:** no caller. Only its definition and declaration reference it in tok, C++ or incant, and `incant/setup` does not register it as a command.
- **Confirm:** a `grep -rn 'labelMinters('` over `*.twk *.rtn *.mm` (definition only) plus a check that no incant file calls it. F-O35's skip census found its 0 skips were vacuous: empty population, not measurement (`objectModel.md` F-O35). **Canary cost:** `measure.h` 42 -> 41.
- **Seen:** 2026-09-28.

### `allAttributesOptional()`
- **What/where:** `GroupItem.twk:184`, declared in `GroupItem.h:46`.
- **Why deletable:** no caller. Its only caller was the parent-`min` promotion, retired 2026-09-03 by measurement (SEQ 152). DesignDocs `promotionRetired` records that it was "left callerless, deliberately".
- **Confirm:** a `grep -rn 'allAttributesOptional()'` over `*.twk *.rtn *.mm` (definition only), then a retok with a byte-identical diff apart from the method, and the fleet unmoved. Its DesignDocs entry and the CLAUDE.md census example (comment convention) cite it and would need a note.
- **Seen:** 2026-09-28 (first noted callerless in the 2026-09-03 wakeup).

### `testAttributes`' artifact skip
- **What/where:** `RuleStuff.twk:269`, `if noPrint continue;` in `testAttributes` (old road).
- **Why deletable:** after stroke 3, artifacts should not be on term lists.
- **Blocked on F-O38.** Measured 2026-09-28: it still skips `pendingParseR` 29,260 times across the fleet, because the kant generator attaches the pending carrier with `+%` (among the terms), and `compile` only moves it when it reaches that rule.
- **Confirm:** once F-O38 is fixed, re-run the F-O35 skip log. This site must read 0 skips with arrivals present, and the fleet must be unmoved.
- **Seen:** 2026-09-28.
- **Re-measured 2026-09-29 (SEQ 224, F-O38 closed by `+<`):** pendingParseR 30,208 -> **0**. But the site still skips **120 locals** -- `this` 60 and `tempField` 60, on coded rules (JSONfield 42+42, JSONarray 9+9, ScafA 4+4, list 3+3, ask 2+2). **So it is NOT deletable as it stands:** it has become a LOCAL skipper, the same class as `setParseWalk`, `compile` x2 and `dupTermRefusal`, which stay by ruling. Leave the entry for Tony to strike or keep.

### `parse()`'s `definer` and `defStuff`
- **What/where:** `GroupItem.twk` parse(), `definer = instanceRule(); defStuff = definer.rStuff;` (the two locals and their
  declarations).
- **Why deletable:** assigned and never read -- in the .twk and in the generated `GroupItem.mm`. Stroke 4.3 family 2 switched the
  first line from definingRule() and measured 1,227,517 changed answers across the checklist with the fleet row for row,
  which is only possible because nothing reads it.
- **Confirm:** delete both, retok, the generated parse() loses exactly those four lines, fleet row for row.
- **Seen:** 2026-09-29.

### The Bytecode road (whole) -- `Bytecode.twk` and everything that exists only to feed it
- **What/where:** `Bytecode.twk` (21 externs: `interpretBC`, `runByteFn`, `opStackOf`, `runBR`, `runBRZ`, `runCall`,
  `runEQ`, `runForNext`, `runGE`, `runGT`, `runLE`, `runLT`, `runMultiply`, `runNotEQ`, `runPlus`, `runPrint`,
  `runPushField`, `runPushLit`, `runRET`, `runStoreField`, `runString`, plus the dummy `class Bytecode` tok needs to
  emit the file) and `Bytecode.mm`/`.h`.
- **What it was for:** Phase Bytecode, the stack-form interpreter (2026-05-30); branch execution proven 2026-06-11.
  Direction since then: bytecode and JIT are parallel lowerings (2026-06-17), and the JIT replaces the interpreter
  (2026-07-29).
- **Callers, every source (census 2026-09-30):** the handlers are reached only through `interpretBC` -> `runByteFn` ->
  each op's `interpret` sub-attribute, bound at setup by 19 `interpretMethod=` registrations (`incant/setup`).
  `interpretBC`'s one caller is `incant/generate`'s `generateAction`. `generateAction`'s only calls are
  `incant/pop/oneTest:85-95`, which sit **below oneTest's `stop()`**. No other region reaches it. The population
  searched: every `incant/` and `IncantForms/` file's region above its first `stop()`/`bail()`, plus all
  `.twk`/`.rtn`/`genLadder`/`jitLadder` sources. **Live callers: 0.** oneTest's header says the generator now runs
  from `incant/generating` "on demand", and that file does not exist.
- **Cost of cutting (it is a direction ruling, not tidying):** `Bytecode.twk/.mm/.h`; 8 references in
  `TOK.xcodeproj`; groups.ext's `external Bytecode.h` block (12 lines) and the `external Bytecode` line; the 19
  `interpretMethod=` registrations and the `interpretBC`/`runByteFn` commands in `incant/setup`. setup is read at
  runtime, so those go in the same stroke as the rebuild (bear-trap #31). Also `interpretMethod` in
  `GroupActions.rtn:391`; `incant/generate`'s `generateAction` and generator; `Commands.rtn`'s `generateCode`; and
  CLAUDE.md's Phase Bytecode sections. **The `bcOPs` registry is on 77 incant files' search lines**: keep the
  registry empty, or edit 77 preambles.
- **Confirm:** a run-level reachability check (a temporary breakpoint or tap on `interpretBC` across the H12 checklist
  reading 0), then Tony's ruling on whether bytecode stays as a parallel lowering.
- **Seen:** 2026-09-30.

### `dupCensus`
- **What/where:** `genParse.rtn:136`, registered `dupCensus immediateAction;` in `incant/setup`, and a groups.ext line.
- **What it was for:** the complete two-faces census for F-110 (Clay, 2026-09-23). It walks every reachable node and
  asks each `dupTermRefusal`.
- **Callers:** 0 in any incant, `IncantForms`, `.sh` or `.twk`/`.rtn` file; only its own registration. Its sibling
  `dupTermRefusal` is live (`IncantForms/WorkingOn/parser:13`, above its `bail()`) and is **not** a candidate.
- **Cost of cutting:** the extern, the setup line and the groups.ext line, in one stroke with the rebuild (#31). It
  loses a re-runnable instrument; F-110's record keeps the numbers it produced.
- **Confirm:** the census above re-run at cut time; fleet row for row.
- **Seen:** 2026-09-30.

### `genParse.rtn` -- the file name, not its contents (a move, not a cut)
- **What/where:** the header says this is "what is left of the C++ parse-method emitter" (retired by mapping 2026-09-26).
  Every extern left in it is live: `dataName` (GroupItem.twk:908-912, measure.twk:509), `locateRule` and `showTree`
  (via `treeOf`), `treeOf` (`incant/pop/driveDoorT` IA-3/IA-4), `traceParse` (29 fixtures), `dupTermRefusal`
  (parser). Only `dupCensus` above is callerless.
- **Why listed:** nothing in it generates a parse any more. If Tony wants the name to match the contents, the cost is a
  file move plus the `GroupRules.twk` include line and the DesignDocs `TokFiles -> genParse` keys.
- **Seen:** 2026-09-30.

## Seeded, already gone

Seeded 2026-09-28 from the dispatch. A source census shows each was already deleted, so there is nothing to cut.

| item | deleted in | census |
|---|---|---|
| F-56's `fireNewParse` (`Commands.rtn`) | `1dd73d6` -- Tier 1 of the parseMethod= deletion (SEQ 188) | 0 references in `*.twk *.rtn *.h`; only docs and the channel mention it |
| `parseGeneric` (`RuleStuff.twk`) | `2bfa808` -- Task 2 (SEQ 192) | 0 references in `*.twk *.rtn *.h` |

## Done

### `compile`'s pending-carrier re-filing block -- DELETED 2026-09-29 (SEQ 225 item 2)
- **Was:** `Commands.rtn:56-68` (`pendingToProperties`), moving a `pendingParseR` carrier and its `CodE` from the
  terms to the property lists.
- **Measured before the cut:** a temporary log across the whole checklist (pop.sh, jitLadder, decodePop, ddPop,
  countPop, printPop, frontier): **4,307 arrivals with a carrier present, 0 carrier moves, 0 CodE moves** --
  `parser:43-44` file both with `+<` since SEQ 224. Deleted with the fleet row for row.
