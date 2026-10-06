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

### The `setPointer` command (-> `opPointer`) -- no user left (seen 2026-10-02, deepClean S4)
- **Where:** `incant/setup:74` `setPointer immediateAction=opPointer noPrint;` and `opPointer`, Instruct.rtn:1246.
- **Why it looks cuttable:** its one user was `bcPushField`'s `setPointer` clause in the bcOPs registry, which retired with
  the bytecode road. Census 2026-10-02 over incant/**, IncantForms/**, genLadder, jitLadder, *.twk, *.rtn: no kant use of
  the command. `GroupItem::setPointer(void*)` (GroupItem.twk:1799, used by GroupDraw.twk:130) is a different method and is
  live.
- **Confirm:** cut the registration and `opPointer`; setup is read at runtime, so rebuild in the same commit (#31); fleet
  row for row.

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

### `testAny` and the bootstrap rule `Any` -- the rest of parseAny's question (open; seen 2026-10-02)
- **Where:** `testAny` (RuleStuff.twk, bound by `setTestMatch`'s `case isANY:`), the bootstrap rule `Any` (GroupMain.twk,
  `grok += new("Any"); isANY = true;`).
- **Why it looks cuttable:** S6's witness (2026-10-02, pop.sh + jitLadder + printPop) counted **testAny 0** calls beside a
  `parseString` sibling of 18,487 (equal to stroke 5.4a's measured count). No grammar term names `Any`.
- **Confirm:** cut both; full bare tokall; fleet row for row. The `isANY` data type itself stays (GroupBody's enum,
  setGuard, dataName).

### `jitProbeDrive` -- a second drive door beside `driveStep` (one-door candidate, SEQ 241 R3)
- **What/where:** `jitEmitters.rtn:682` (`extern int jitProbeDrive`, behind incant `probeDrive`). It opens a drive
  in C++ passthrough: `pushInput`, `inputFloor`, `lastIndent`/`defining` save-restore, and since stroke 5.5f its
  own activation floor -- each a copy of what `driveStep` (`GroupActions.rtn:255-310`) does.
- **Why listed:** two doors means every drive rule has to be applied twice. 5.5a found the first cost: this door
  had no floor, so an old-road activation above it became visible to `deferredAbove` and `adoptT` moved.
- **Confirm:** route its fire through `driveStep` (the jitted carrier swap would need a seat there), then the drive
  census row in `pop.sh` drops `jitEmitters.rtn:jitProbeDrive` and reads 3; every `probeDrive` fixture row for row.
- **Seen:** 2026-10-01.

### `modPercent` and `modPointer` -- RuleStuff flags with no reader but a measure (seen 2026-10-02, SEQ 269/270)
- **What/where:** `RuleStuff.twk:26-27`; written only by `modify()` (`GroupActions.rtn:565-566`, the `%` and `&` modifiers).
- **Why deletable:** read only by `measure.twk` `modsOf` (the MODSOF witness, :766-770). Whole-tree word census of `*.twk`/`*.rtn`, 2026-10-02.
- **Confirm:** a census of `incant/`, `IncantForms/` and the grammar for `%`/`&` modifiers in use; cut the two flags, the two `modify` arms and the witness columns; layout (groups.ext + full bare tokall); fleet row for row. The draft Part 1 amendment (objectModel.md A2f) classes them measurement-only.

### Fold `interpretXP` into `aCTionExpressioN` (seen 2026-10-02, SEQ 269/270)
- **What/where:** `ruleActions.rtn:441-445` `aCTionExpressioN` is `return interpretXP(xpList);`; `interpretXP` at `ruleActions.rtn:1396`.
- **Why:** the bytecode branch that made it a dispatcher retired in deepClean S4 (2026-10-02). `aCTionExpressioN` is the ONLY caller -- searched in `*.twk`, `*.rtn`, the generated `.mm` and `incant/`, 2026-10-02.
- **Confirm:** move the body, keep the `aCTionExpressioN` name (it is the registered rule action), respell the DesignDocs keys `ruleActions.interpretXP.*` and the `jitEmitters.rtn:1925` comment; fleet and jitLadder row for row.

### `parseTrace` / `traceParse` -- overlaps Tony's directives (seen 2026-10-02, SEQ 269/270)
- **What/where:** `GroupRules.parseTrace`, set by `traceParse` (`genParse.rtn:87-92`, registered `incant/setup:81`); gates about 51 lines in `measure.twk` and three inline blocks in `GroupItem.twk:226-291`.
- **Why:** `groupDirectives` already carries entry traces for `parseAction`/`Container`/`Set`/`String`/`UpTo`, `exitFromParse` and `parse()` -- two ways to trace a parse. Tony, 2026-10-02: "we do not need two ways to do that."
- **Confirm / first:** fleet rows read its output -- `incant/pop/driveDoorT` (door row), `chainTruthT` (rows 1-6), `searchAcc`. Retire those by mapping before any cut. Note the 2026-09-10 measure-callout ruling chose callouts over directives builds; this entry reopens that for parse tracing, and the call is Tony's.

### `isLabel` as "do not clear" on action locals -- a second meaning (SEQ 248 R5, banked, not fixed)
- **Where:** `processAction`, GroupActions.rtn:713 (`result.isLabel = true;` on an action-body local bound to a label
  child), read back at :720 (`if isLocal && !isLabel ...` skips the entry clear).
- **Why it looks cuttable:** `isLabel` otherwise means "a parse minted this as a rule's label" (checkInput, with
  `labelOf`). Here it means "this local holds a label child; do not clear it" -- one flag, two meanings, and the
  locals carry no `labelOf`.
- **Confirm:** a census of every `isLabel` reader, each read classified by meaning; a separate flag for the local
  case, fleet row for row.
- **Seen:** 2026-10-01 (stroke 5.6a mint-site census).

### GroupItem's C++ escapes, and parse() readability (Tony, 2026-10-06 offline status)
- **What / where:** eleven `-% %-` escapes in `GroupItem.twk`: `attachLabel` (:252, :272), `captureSpan` (:309, :329),
  `fireLabelMethod` (:723, :726), `parse()` (:1343, :1345, :1378), `setJitEmitter` (:1775), `setOperat` (:1813).
  `parse()` also reads poorly: one-line slug comments and escapes break up its flow.
- **Why it looks deletable:** the label escapes came in with strokes 1.2a-1.2g and may be expressible in tok now.
  `setJitEmitter`/`setOperat` are fnptr casts, kept because tok drops `&` on fnptr-cast reference params
  (FormatC.twk fix deferred), so they stay unless that is fixed.
- **Confirm:** respell each in tok, then a full bare tokall diff and the fleet row for row.
- **Tied to it (Tony, 2026-10-06 R1):** parse()'s `beforeAction:` label and its no-op `ownPoint = 0;` are a deliberate
  directive anchor -- the on-success directive (`parse ownPoint active`) was being dropped while the fireLabelMethod
  escape sat at that point. When that escape is respelled in tok, the label and the no-op assign leave together and the
  directive is re-aimed at the respelled statement (dirCheck confirms).
- **Seen:** 2026-10-06. Tony proposes a "do we need this" cleanup day or two once the design docket is done.

### `processingCodE` (GroupFields 412) -- Tony cut it offline, restored by R2a (2026-10-06)
- **What / where:** `incant/setup` `processingCodE=412`; `Instruct.rtn` its read (`case 412: product.count = inCompile();`)
  and its write refusal (`refuse(target,"processingCodE is read-only ...")`).
- **Why it looks deletable:** Tony's parseCode no longer brackets with it (compileIn marks its own floor, SEQ 299), and
  the old processCode-port writes are gone from macros.
- **Why it was restored rather than cut (Clod, R2):** it is kant's only door onto the compile-floor mark. `compileFloorT`
  CF-0..4 and `compileInT` CI-H3/H4 certify that MARK (a nested drive reads 0, a rule fired by the compile reads 1), not
  the accessor -- cutting the accessor deletes the mark's only coverage, and mapping needs another reader first.
- **Confirm:** census every kant read (tester, macros, forms, incant/, fixits); name a replacement reader for the floor
  mark or rule its coverage unowed; then retire CF-0..4, CI-H3/H4 and the refusal row by mapping, each with its sentence.
- **Seen:** 2026-10-06 (Tony's offline cut; uncommitted working copy saved by Clod, reverted to HEAD).

### `ignoreNoPrint` -- a switch nothing sets (containers recon step 1, 2026-10-06; SEQ 309 step 1b R4)
- **What / where:** the GroupRules flag declared at `GroupRules.twk:104`, read once, by `GroupItem.next()` (:1234):
  `if ignoreNoPrint && current.noPrint continue;`.
- **Why it looks deletable:** no `.twk`, `.rtn` or `incant/setup` line writes it, so `next()` never skips anything and
  every term-wanting walk filters noPrint for itself.
- **Confirm:** grep every repo and the gitignored directive files for a writer; cut the flag and its one read; full bare
  tokall diff (the read goes, nothing else moves); fleet row for row.
- **Seen:** 2026-10-06.

### `updateContentFlags` -- no callers (containers recon step 1, 2026-10-06; SEQ 309 step 1b R4)
- **What / where:** `GroupItem.twk:1955`, which re-derives `hasAttributes`/`hasMembers`/`hasTraits` from a walk.
- **Why it looks deletable:** no caller in any `.twk`, `.rtn` or kant file (the 2026-08-29 isGroupActorPoison probe once
  suppressed it and measured it irrelevant).
- **Confirm:** census callers across all three repos and the directive files; cut it; full bare tokall diff; fleet row
  for row. If the containers shape lands, its flag upkeep is the place a replacement would be decided, not here.
- **Seen:** 2026-10-06.

### `recordLabel` -- no caller since the ruleName stroke (2026-10-06)
- **What / where:** `Generate.rtn:25`, `extern GroupItem recordLabel(RuleStuff s)` -- the nearest live record's label.
- **Why it looks deletable:** its one caller, `attachLabel`, now walks the records itself so it can read the record's
  `face` (the retag asks the rule, not `ruleName`); kept in place by the stroke so the extern canary did not move.
- **Confirm:** grep every repo and the directive files for a caller; cut it and its groups.ext line if any; canary
  307 -> 306, named; fleet row for row.
- **Seen:** 2026-10-06 (ruleName stroke, branch stroke-ruleName).

### `enclosingStuff` -- no caller (stroke 1.3 recon, 2026-10-06)
- **What / where:** `Generate.rtn:48`, `extern RuleStuff enclosingStuff(GroupItem askField, RuleStuff askStuff)`, and its
  groups.ext line (:504).
- **Why it looks deletable:** no caller in any `.twk`, `.rtn`, kant file or directive (stroke 1.3's stuff tap recorded 0
  reads there across pop.sh, jitLadder and printPop). Stroke 1.3 respelled it to `stuffOf` so it compiles, nothing more.
- **Confirm:** grep all three repos and the directive files; cut it and its groups.ext line; canary 307 -> 306, named;
  fleet row for row.
- **Seen:** 2026-10-06 (stroke 1.3, branch stroke13).

## Seeded, already gone

Seeded 2026-09-28 from the dispatch. A source census shows each was already deleted, so there is nothing to cut.

| item | deleted in | census |
|---|---|---|
| F-56's `fireNewParse` (`Commands.rtn`) | `1dd73d6` -- Tier 1 of the parseMethod= deletion (SEQ 188) | 0 references in `*.twk *.rtn *.h`; only docs and the channel mention it |
| `parseGeneric` (`RuleStuff.twk`) | `2bfa808` -- Task 2 (SEQ 192) | 0 references in `*.twk *.rtn *.h` |

### A named-rule trace may be quiet on a face (SEQ 284 R4, parked, 2026-10-03)
- `groupDirectives`' parse-debugging bodies test `field.debugged`, and `parseRule`/`parseContainer` re-resolve `field` to the enclosing face first; if a face does not share the registry rule's body, `debugRuleNamed` stays quiet there (`debugAllRules` is unaffected). Unmeasured. Confirm: `debugRuleNamed` on a rule reached by face, and count its trace lines.

## Done

### `parseAny` -- CUT 2026-10-02 (deepClean S6, SEQ 260)
- Witness re-run first: parseAny **0** calls, parseString sibling 18,487. Cut: the function, its `case isANY:` installer in
  setParseWalk (an `isANY` node now classifies as the default, parseString), the two measure name-table entries, its
  groups.ext line. Its DesignDocs leaf-template note re-keyed to `parseCharacter`. Canary 301 -> 300; fleet row for row
  but mirror arity 255 -> 254.

### The Bytecode road -- CUT 2026-10-02 (deepClean S4, SEQ 260; ruled 2026-09-30)
- Cut: `Bytecode.twk/.mm/.h` and their 8 TOK.xcodeproj references; `interpretMethod` and its bootstrap; `generateCode`;
  the `generating` mode (`generateXP` and the branches in aCTionExpressioN, aCTionPrinT, aCTionStatemenT, aCTionTokenXP,
  jitEmitters' reset); `bcOPs` dropped whole (R4) -- the GroupRules members `bcOPs`, `generator`, `generating`, the
  GroupControl init, the setup registry and its 8 Operators clauses, the 77 search lines; groups.ext 23 lines; oneTest's
  dead-region calls and its two stale header lines; CLAUDE.md's Phase Bytecode text. `incant/generate` stays as reference
  with a header line saying so, and still loads (oneTest exit 0).
- Certificate: full bare tokall, deletions only plus two comments; canary 304 -> 301; fleet row for row with S3 but the
  mirror-arity census (270 -> 255, the 15 cut externs with definitions).

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
