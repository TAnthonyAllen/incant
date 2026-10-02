# Cleanup list

A standing list of cruft spotted mid-stroke (Tony, 2026-09-28). **When you spot cruft, add an entry and keep going; don't act on it in flight.** Tony decides the cuts, one cleanup pass at a time. A cut that lands moves its entry to **Done**, with the commit.

Each entry: **what and where** (file:line) · **why it looks deletable** · **the census or measurement that would confirm it** · **seen** (date).

## Open

### `testAttributes`' artifact skip -- **KEEP: skips locals (this, tempField)** (SEQ 260 R8, 2026-10-02)
- **What/where:** `RuleStuff.twk:269`, `if noPrint continue;` in `testAttributes` (old road).
- **Why deletable:** after stroke 3, artifacts should not be on term lists.
- **Blocked on F-O38.** Measured 2026-09-28: it still skips `pendingParseR` 29,260 times across the fleet, because the kant generator attaches the pending carrier with `+%` (among the terms), and `compile` only moves it when it reaches that rule.
- **Confirm:** once F-O38 is fixed, re-run the F-O35 skip log. This site must read 0 skips with arrivals present, and the fleet must be unmoved.
- **Seen:** 2026-09-28.
- **Re-measured 2026-09-29 (SEQ 224, F-O38 closed by `+<`):** pendingParseR 30,208 -> **0**. But the site still skips **120 locals** -- `this` 60 and `tempField` 60, on coded rules (JSONfield 42+42, JSONarray 9+9, ScafA 4+4, list 3+3, ask 2+2). **So it is NOT deletable as it stands:** it has become a LOCAL skipper, the same class as `setParseWalk`, `compile` x2 and `dupTermRefusal`, which stay by ruling. Leave the entry for Tony to strike or keep.

### The Bytecode road -- RULED RETIRE (Tony, 2026-09-30). The cut is its own stroke on another day; this is its list.
- **Ruling:** the Bytecode road is retired; the JIT is the one path. **`incant/generate` is KEPT** as template material
  (interesting kant code, reference for a while) -- not deleted, not attic'd.
- **Live callers: 0** (census 2026-09-30, first entry of this section's history): the handlers are reached only through
  `interpretBC` -> `runByteFn` -> an op's `interpret` sub-attribute; `interpretBC`'s one caller is `incant/generate`'s
  `generateAction`, whose only calls (`incant/pop/oneTest:85-95`) sit below oneTest's `stop()`.
- **THE EXACT CUT LIST.**
  1. **C++ -- `Bytecode.twk` / `.mm` / `.h` whole**: 21 externs (`interpretBC`, the dispatch loop; `runByteFn`;
     `opStackOf`; `runBR` `runBRZ` `runCall` `runEQ` `runForNext` `runGE` `runGT` `runLE` `runLT` `runMultiply`
     `runNotEQ` `runPlus` `runPrint` `runPushField` `runPushLit` `runRET` `runStoreField` `runString`) and the dummy
     `class Bytecode`. `TOK.xcodeproj`: 8 references.
  2. **`interpretMethod`** -- the attribute handler `GroupActions.rtn:399` and its bootstrap in `GroupMain.twk:54-56`.
  3. **groups.ext**: the `external Bytecode` line (3), the `external Bytecode.h` block (16-30, 12 externs), and
     `interpretBC` / `interpretMethod` (553-554). The canary moves by the GroupRules-chain externs only
     (`interpretMethod`; `interpretBC` lives in Bytecode.h) -- count at cut time, per H14.
  4. **`incant/setup`**: the `interpretBC` (:55) and `runByteFn` (:79) command lines, and the **18** `interpretMethod=`
     clauses -- 8 on Operators (`>= > == <= < + * !=`, :118-170) and 10 on bcOPs (:185-194). (The 19 counted earlier
     included the prose on :180.) setup is read at runtime: these go in the same stroke as the rebuild (#31).
  5. **`bcOPs` on search lines**: `registry(bcOPs)` (:183) and its 10 entries, and `bcOPs` on the **77** incant search
     lines. Choice at cut time: keep an empty `bcOPs` registry (77 lines untouched), or drop it and edit 77 preambles.
  6. **generateAction's callers below oneTest's stop()**: `incant/pop/oneTest:85-95` (and the parked sections
     beneath it that call `generateCode`/`generateAction`). `Commands.rtn`'s `generateCode` (:179) is the C++ entry
     and goes with them.
  7. **oneTest's header** still points at `incant/generating`, which does not exist -- fix that line when the cut lands.
  8. **CLAUDE.md**: the Phase Bytecode sections and the `testByteCode` / `testIfElse` status text.
- **WHAT THE CUT MUST ANSWER FIRST, ANSWERED 2026-09-30 (probe, reverted md5-identical):** does `incant/generate` still
  load once the C++ road is gone? With `incant/setup`'s bytecode side stripped (the two command lines and all 18
  `interpretMethod=` clauses) against today's binary, **`oneTest` -- which does `include(generate)` -- is
  byte-identical, and pop.sh reads 861 / 1 row for row.** generate names `interpretBC` only inside `generateAction`'s
  `code={}` body, which compiles lazily; nothing in it names a removed command at define time. **So the outcome is the
  first one: generate stays where it is, with a header line marking it reference only, not a running road.** The
  audit pin and oneTest's include need no re-pin. (Not yet measured: a binary with the externs actually removed; the
  cut stroke re-runs this probe on it.)
- **Seen:** 2026-09-30.

### `genParse.rtn` -- the file name, not its contents (a move, not a cut)
- **What/where:** the header says this is "what is left of the C++ parse-method emitter" (retired by mapping 2026-09-26).
  Every extern left in it is live: `dataName` (GroupItem.twk:908-912, measure.twk:509), `locateRule` and `showTree`
  (via `treeOf`), `treeOf` (`incant/pop/driveDoorT` IA-3/IA-4), `traceParse` (29 fixtures), `dupTermRefusal`
  (parser). (dupCensus was cut 2026-09-30, so every extern left here is live -- re-measured 2026-10-02.)
- **Why listed:** nothing in it generates a parse any more. If Tony wants the name to match the contents, the cost is a
  file move plus the `GroupRules.twk` include line and the DesignDocs `TokFiles -> genParse` keys.
- **Seen:** 2026-09-30.

### The three escaped `::enclosingFace` calls -- NOT a cut; a respell, parked by ruling (SEQ 235 R3)
- **What/where:** `Generate.rtn:145` (parseContainer), `:196` (parseLoop), `:221` (parseRule), each
  `-% { GroupItem *zEnc = ::enclosingFace(field); if ( zEnc ) field = zEnc; } %-`.
- **Why listed:** stroke 5.1 gave `enclosingFace` its `groups.ext` line, so tok can now call it; the passthrough is
  no longer needed to reach it. **Not respelled now (Tony, R3), for bear-trap #42:** the tok spelling needs a new
  local for `zEnc`, and a new declaration mid-function re-points every bare field below it -- in `parseRule`, the
  whole body under its `use` lines. Calling it twice instead (`if enclosingFace(field) field = enclosingFace(field)`)
  avoids the local and doubles the lookup.
- **Confirm:** respell one site at a time; full bare tokall diff of the function must show only that line, then
  fleet row for row. Read the generated tail (#42), not only the canary.
- **Seen:** 2026-10-01.

### `parseAny` -- installed only on the bootstrap rule `Any`, which no grammar references
- **What/where:** `Generate.rtn:74` (`extern GroupItem parseAny`), installed by `setParseWalk`'s `case isANY:`
  (`Generate.rtn:418`). The only node carrying `isANY` data is the bootstrap rule `Any`
  (`GroupMain.twk:157-159`, `grok += new("Any"); isANY = true;`); nothing else in `.twk`/`.rtn` sets it.
- **Why it looks deletable:** no grammar term names `Any` -- a word-bounded grep of `incant/`, `IncantForms/` and
  `grammar` finds 19 hits, all prose (`incant/pop/f31` lists `Any` among names dropped). Stroke 5.4a's witness counted
  **0 calls** to `parseAny` across pop.sh + jitLadder + printPop.
- **Related, same question, not claimed:** the `Any` bootstrap rule itself and the old road's `testAny` (`RuleStuff.twk:236`,
  bound at `RuleStuff.twk:167`'s `case isANY:`), which would go with it.
- **Confirm:** a call census of `parseAny` and `testAny` over the full seal checklist (want 0 with the census's own
  call-count sibling > 0 elsewhere); delete `parseAny` and its `case`, full bare tokall, fleet row for row.
- **Seen:** 2026-10-01 (SEQ 239 rider).

### `jitProbeDrive` -- a second drive door beside `driveStep` (one-door candidate, SEQ 241 R3)
- **What/where:** `jitEmitters.rtn:682` (`extern int jitProbeDrive`, behind incant `probeDrive`). It opens a drive
  in C++ passthrough: `pushInput`, `inputFloor`, `lastIndent`/`defining` save-restore, and since stroke 5.5f its
  own activation floor -- each a copy of what `driveStep` (`GroupActions.rtn:255-310`) does.
- **Why listed:** two doors means every drive rule has to be applied twice. 5.5a found the first cost: this door
  had no floor, so an old-road activation above it became visible to `deferredAbove` and `adoptT` moved.
- **Confirm:** route its fire through `driveStep` (the jitted carrier swap would need a seat there), then the drive
  census row in `pop.sh` drops `jitEmitters.rtn:jitProbeDrive` and reads 3; every `probeDrive` fixture row for row.
- **Seen:** 2026-10-01.

## Seeded, already gone

Seeded 2026-09-28 from the dispatch. A source census shows each was already deleted, so there is nothing to cut.

| item | deleted in | census |
|---|---|---|
| F-56's `fireNewParse` (`Commands.rtn`) | `1dd73d6` -- Tier 1 of the parseMethod= deletion (SEQ 188) | 0 references in `*.twk *.rtn *.h`; only docs and the channel mention it |
| `parseGeneric` (`RuleStuff.twk`) | `2bfa808` -- Task 2 (SEQ 192) | 0 references in `*.twk *.rtn *.h` |

## Done

### `labelMinters`, `allAttributesOptional()`, parse()'s `definer`/`defStuff` -- CUT 2026-10-02 (deepClean S3, SEQ 260)
- Cut with the rest of S3's dead code (deepClean D-11 to D-16). The generated diff is exactly the deletions plus two
  re-emitted file-header comments and one `class PLGrgx;` forward declaration. pop.sh's ruleOfT RO-8 re-pinned 5 -> 4
  with its sentence: the `instanceRule()` call left with `definer`.

### `establishFrame` and `parse()`'s local `parentLabel` -- CUT 2026-10-02 (stroke 5.9b, SEQ 257 R4)
- **Were:** `GroupItem::establishFrame` (0 callers; a counting tap read 0 calls; its header claimed to be the single
  writer of parentLabel) and `parse()`'s local `parentLabel` (written, never read; listed since SEQ 240/242).
- **Cut** with the field in 5.9b (`cdad9c8`): full bare tokall shows exactly those lines gone; fleet row for row.
  `establishFrame`'s `groups.ext` line (:321) goes at merge with the field's mirror line.

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
- **CUT 2026-09-30:** extern, setup registration and groups.ext line removed; canary 316 -> 315; fleet row for row
  (the mirror-arity row counts 283 comparable names, one fewer, drift still 0).

### `compile`'s pending-carrier re-filing block -- DELETED 2026-09-29 (SEQ 225 item 2)
- **Was:** `Commands.rtn:56-68` (`pendingToProperties`), moving a `pendingParseR` carrier and its `CodE` from the
  terms to the property lists.
- **Measured before the cut:** a temporary log across the whole checklist (pop.sh, jitLadder, decodePop, ddPop,
  countPop, printPop, frontier): **4,307 arrivals with a carrier present, 0 carrier moves, 0 CodE moves** --
  `parser:43-44` file both with `+<` since SEQ 224. Deleted with the fleet row for row.

### `isLabel` as "do not clear" on action locals -- a second meaning (SEQ 248 R5, banked, not fixed)
- **Where:** `processAction`, GroupActions.rtn:713 (`result.isLabel = true;` on an action-body local bound to a label
  child), read back at :720 (`if isLocal && !isLabel ...` skips the entry clear).
- **Why it looks cuttable:** `isLabel` otherwise means "a parse minted this as a rule's label" (checkInput, with
  `labelOf`). Here it means "this local holds a label child; do not clear it" -- one flag, two meanings, and the
  locals carry no `labelOf`.
- **Confirm:** a census of every `isLabel` reader, each read classified by meaning; a separate flag for the local
  case, fleet row for row.
- **Seen:** 2026-10-01 (stroke 5.6a mint-site census).
