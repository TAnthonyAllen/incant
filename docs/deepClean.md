# Deep-clean recon (SEQ 259, 2026-10-02, read-only -- nothing cut)

**What this is.** One ranked list for Tony to rule line by line (SEQ 259 R2). Each line proposes ONE action: **cut**, **keep** (with its reason), **refactor**, **fix**, or **retire by mapping**. The proposed strokes, in a suggested order, are at the top; the evidence is below them. **Nothing was cut, moved or refactored**, and no runtime tap was opened (R1). The only runs were the three instruments, the six fixits, and one frontier probe in the scratchpad; all were read-only.

**Tree.** Trunk `jit-unified-emit-wip` at the 5.9 merge seal (6), bare, no incant process.

**Provenance.** Five read-only census agents (dead code; cleanupList re-measure; two-meaning slots; the three red instruments; leftovers and escapes) plus Clod's own stroke-5-tail census and spot checks. **Spot-checked by Clod before banking:**
- a sample of the zero claims re-run whole-tree (`jitForceInclude`, `getGuard`, `isOption`, `attachBlocK`, `updateDispatch`, `statementMatches`, `aCTionCheckFor`) -- all held;
- RuleStuff's `isOption` hits outside the engine are a different identifier, in a GUI file that is not in the build and two Stash copies;
- the frontier one-line probe re-run, all six stations PASS;
- repo clean (one agent wrote two scratch files into the repo root and moved them out at once; `git status` was clean).

**Populations (R4: every zero names its population).**
- **tok:** `*.twk`, `*.rtn`, `GUI/**/*.twk`, `Tests/*.twk`.
- **generated:** `*.mm`, `*.h`.
- **kant:** `incant/**` and `IncantForms/**` (attic and BackupXML reported separately). Dead regions below `stop();`/`bail();` are classed separately.
- **other:** `groups.ext` (as a mirror, never as a caller); `jitExterns`; `groupDirectives`; `genLadder`, `jitLadder`.
- **name dispatch:** `incant/setup` registrations and `ruleMethod=` / `operateMethod=` / `jitEmitter=` / `interpretMethod=` / `immediateAction=`; dlsym of `"aCTion"+tag` checked against every rule tag in grammar, setup and the bootstrap.
- **whole-struct copies:** `*rStuff = *grup.rStuff` (GroupItem.twk:51) and `*this = *r` (RuleStuff.twk:61) write every RuleStuff field without naming it.
- **Every zero was confirmed with a whole-tree `grep -rlw`** (excluding the backup dirs and `.git`).
- **Blind spot, named:** an lldb or Xcode expression call is invisible to all of these. The debug helpers flagged below are exactly the ones that could be called that way.

## Counts per population

| population | items | of which |
|---|---|---|
| 1 dead code | 386 externs checked; 10 DEAD, 4 dead-text-only, 1 directives-only; 12 mirror-only groups.ext externs; 13 groups.ext ghost class members; RuleStuff 2 dead fields + 4 write-only; 16 dead class methods + 3 header-only ghosts | -- |
| 2 cleanupList | 10 live entries re-measured | 4 still true and moved, 1 changed (Bytecode, incomplete), 1 stale sentence, 4 unchanged in substance; "Seeded, already gone" confirmed |
| 3 two-meaning slots | 10 slots | 3 with measured collisions (sukcess G/M and F, noPrint, historically isBranch); 5 structural with pointable paths (fLAG x3, sukcess V/R, opDot, deferred, byRef); isLabel invariant violated by construction |
| 4 stroke 5 tail | 4 fields, 29 functions, ~200 generated sites | -- |
| 5 instruments | 3 red | none red for the reason its own message gives: decodePop fix, countPop retire by mapping, frontier fix + re-aim |
| 6 leftovers | branches 27 merged + 9 not; wakeup.md 2,188 lines; 7 false DesignDocs entries; 6 fixits (5 keep, 1 close); measure move already done; ~60 jit globals referenced from tok with no mirror | -- |
| 7 C++ escapes | 220 passthrough blocks in 12 files | count only (parked) |

---

## PROPOSED STROKES, in suggested order

The order follows one principle: **make the instruments honest before anything is cut, because the instruments certify the cuts.** Then documents that are false today, then cuts that do not touch layout, then the Bytecode road, then layout cuts, then the refactors.

| # | stroke | lines in it | size | risk | why here |
|---|---|---|---|---|---|
| **S1** | **Instruments that lie** | D-1, D-2, D-3, D-4, D-5 | ~10 lines of fix + one pop.sh block retired (~25 lines) + frontier re-aim | low; each has a stated H7 | decodePop, countPop and frontier sit on the seal checklist recorded "row for row" while measuring nothing (none is red for its own reason). Every later stroke is certified by them |
| **S2** | **Documents that are false today** | D-6, D-7, D-8, D-9, D-10 | docs only, ~15 entries | none | 5 DesignDocs entries went false TODAY with 5.8/5.9; a cold reader would build on them |
| **S3** | **Dead code, no layout** | D-11 to D-16 | ~250 tok lines; ~20 externs; 12 groups.ext lines; 0 fixtures | low; canary moves by the extern count, named per H14 | pure deletions; fleet should read row for row |
| **S4** | **The Bytecode road** (ruled 09-30) | D-17 | ~1,014 lines (Bytecode.*) + ~23 (interpretMethod) + ~38 (generateCode) + ~100 (the `generating` / generateXP road) + ~19 groups.ext + ~13 setup + 8 clause edits; 8 TOK.xcodeproj refs; oneTest dead region | medium: setup is read at runtime, so the rebuild lands in the same stroke (#31); `bcOPs` keep-empty or drop is a choice at cut time (77 search lines) | the largest single cut, already ruled; `incant/generate` stays as reference |
| **S5** | **Layout cuts** | D-18, D-19, D-20 | RuleStuff 6 fields; ~13 ghost members across GroupItem/GroupRules/Layout/Stylish; 4-6 dead jitContext.h globals | medium: layout; full bare tokall + #10 subdirectory check (GUI/ carries Layout/Stylish) | one layout stroke instead of three |
| **S6** | **One-door refactors from cleanupList** | D-21, D-22 | parseAny (~24 lines + 6 extra sites); jitProbeDrive one-door (~69 lines) | low-medium | already banked, re-measured |
| **S7** | **Two-meaning splits, probes first** | D-23 to D-29 | probes: 3 one-run fixtures; splits: 2-25 sites each | medium; each is its own try-and-buy | three of them have a pointable wrong-answer path that nobody has run |
| **S8** | **Stroke 5's tail: per-call state onto the activation** | D-30 | 29 functions, ~200 generated sites, layout on both structs | high; recon first | the finding of SEQ 258 R4; stroke-sized |
| -- | **Housekeeping, any time, Tony's word** | D-31 to D-35 | git and docs | none | branches, `main`, wakeup trim, fixits |
| -- | **Parked** | D-36 to D-41 | -- | -- | keeps with reasons; escapes and jit declarations wait for the jitter |

---

## THE RANKED LIST

Size = lines removed or changed · externs · fixtures touched. Risk is what could break. **Action** is the one proposal Tony rules.

### S1 -- instruments that lie

**D-1 · `incant/frontier` station 4 -- FIX (1 line), then RE-AIM.**
- **Evidence:** the station prints "the action RAN WITHOUT ITS TERMS ... CT-5". A minimal-delta probe shows the body DID run and walked 3 matched terms. What fails is the witness: `frWitness = frMark;` (frontier:20) reads a data-less `frMark` inside the rule's body, and afterwards `frMark` itself echoes its tag (bear-trap #26).
- **Measured by Clod:** with only that line changed to `frWitness = 987654;`, **all six stations PASS** ("=== FRONTIER: all six stations RAN and PASSED ==="). The H7 holds: the witness is zeroed before the drive.
- **Red since:** passed 09-18 (`763747e`); failing by `fa15fe6`/`9b4d81c` (09-20), the commit that wrote the CT-5 blame -- an inferred cause that does not hold.
- **Size:** 1 line now. The re-aim revises the stations to the next real edge (its charter: a green frontier means nothing), about the 60-line live region plus its stale dead-region prose.
- **Risk:** none for the fix. The re-aim needs Tony to name the next edge (parse-then-fire P4 on, or the ShRep divergence).
- **Finding (rule F2: reported, not minted):** a rule action's read of a declared Frontier global comes through data-less, and afterwards the global reads as its tag. Reproducible with the scratch probe; not chased.

**D-2 · `carrierT` CT-5 and F-83 -- FIX (re-pin with a sentence, close F-83).**
- **Evidence:** the same win as D-1, read as a failure in the fleet: `docs/redList.md` already says "the label gap is GONE ... re-pin ... close F-83".
- **Size:** one pop.sh pin plus its sentence (H6). **Risk:** none.

**D-3 · `genLadder/decodePop.sh` -- FIX (3 lines in 2 files), plus the same void test in `incant/lookup`.**
- **Built to catch:** an incant/decoder entry whose definition silently did not store (`469347a`, 08-09).
- **Red since 2026-09-24**, the 09-24 18:16 seal. Three spellings stopped discriminating once the iterate cursor became a holder:
  - `decodeT:97` `if grup.definition;` counts 0 of 82 -> `if *grup.definition;` (82; negative control 0).
  - `decoder:347` `hit = decodeCorpus[...]; if hit;` is TRUE on a miss -> `if decodeCorpus[argument.taG];` (bear-trap #35's existence half).
  - `decoder:361` `decodeOne(grup)` hands over the holder -> `decodeOne(*grup)`.
- **Same void test:** `incant/lookup:58-59` (`luD = decodeCorpus[...]; if luD;`), so `lookuP` of an unknown id claims a hit.
- **Size:** 4-5 lines, 3 files, 0 fixtures. **Risk:** low. **Lost if retired instead:** glossary integrity has no other home.

**D-4 · `genLadder/countPop.sh` -- RETIRE BY MAPPING to `genLadder/parserCoverage.sh`.**
- **Built to catch** (`d84c259`, 08-23): every live Grokking rule compiles clean when every generated body is installed (F-31's interference family).
- **Why red:**
  - Its scorer is dead since **2026-09-08**: `ad35796` removed `gCompileAttempted++`/`gCompileRefused++`, so `reportCompileCensus` returns silently and every rule reads MISSING. `docs/wakeup.md:976` already said so.
  - Its f31 scaffold is broken too: a `quoteBody` tag echo, then "REFUSED ... isCoded is set but there is no CodE attribute" after stroke 3 moved `CodE` to the property list, then an ABANDONED parse. Restoring the counters would turn 47 MISSING into 47 FAIL.
  - Masked 09-11..09-25 by the f31 move.
- **Mapping:**

| assertion | new home |
|---|---|
| per-rule "compiles clean" | `parserCoverage.target`'s COMPILES/LEAF/NOBODY row per rule |
| "DatA does not crash the compiler" | "COMPILES DatA" |
| population derived live | parserCoverage recomputes from Grokking with the same four filters |
| H2 | parserCoverage's summary line |
| ghost/MISSING row | **partly carried**; one extra row if wanted |

- **Lost:** the install-ALL-then-compile-one interference question. Its scaffold is broken and rides the retired C++-emitter road.
- **Size:** pop.sh block ~25 lines (:4785-4810); the CLAUDE.md H12 line; the seal template; `docs/sealCaptures/countPop.txt`. Keep the scripts as history.
- **Also cut with it:** the dead counters `gCompileAttempted`/`gCompileRefused`/`gCompileReported` and `reportCompileCensus` (jitContext.h:678-697, Commands.rtn:641).
- **Risk:** low.

**D-5 · fixit `ppwriteCountIsAnAddress` -- FIX and CLOSE.**
- **Evidence:** `measurePlusPlusWrite` prints `gCount` when `data == 6` (a group), so the column is pointer bits (74322880 vs 48567232 on two runs).
- **Fix:** one line at measure.twk:703 and :681, PEQWRITE's same column. Check that nothing in genLadder reads the raw count.
- **Risk:** none.

### S2 -- documents that are false today

**D-6 · DesignDocs entries now false -- FIX (rewrite or retire each).**

| line | entry | why false |
|---|---|---|
| 737 | `Generate.exitFromParse` | "sync parentLabel ..." |
| 1377-1428 | `GroupItem.establishFrame` | "THE SINGLE WRITER of parentLabel"; the function is cut |
| 1688-1753 | `GroupItem.parse.genParseRuleAccess` | `into` travels through the parentLabel field |
| 1968 | `RuleStuff.fields.parentLabel` | the field is gone |
| 3200-3204 | `genParse` | lists dupCensus as left |
| 896 | `GroupActions.reportMaxLimit.refuseNotTruncate` | gate spelled `!limitsSet`; limitsSet deleted |
| 3205 | `genParse.invariantRprime` | describes `demoRprime`, which is not in source |

- **Historical but honest (keep, mark):** 1222-1233 (quotes dead `parentStuff` code); 1573 `getRstuff` (method gone -- fold into `ensureRStuff`).
- **Size:** ~10 entries. **Risk:** none (ddPop reads the file -- run it).

**D-7 · `docs/jitDesign.md:1162` -- FIX (strike).** It lists "move the measure* methods from Generate.rtn to measure.twk" as open; `0d7dea0` (09-26) did it. No `measure*` definition lives outside measure.twk today (27 of 27).

**D-8 · CLAUDE.md bear-trap #16 -- FIX.** It says the Stylish `shadow*`/`subbed` ivars were removed 2026-07-02. `groups.ext` :840-850 still carries them, so they survive in Stylish.h and the constructor zero-inits (and see D-19).

**D-9 · CLAUDE.md's `measureLabelProbe` pin sentence -- FIX.** CLAUDE.md says `measureLabelProbe` is "pinned by exact string in `genLadder/pop.sh`". pop.sh:5143 is a comment recording that those rows retired by mapping (F-109). See D-13.

**D-10 · CLAUDE.md's fixit register text -- FIX.**
- It says "the queue is at zero and `incant/fixits/` is empty". `incant/fixits/` holds 6 files.
- `fixitNag.sh` prints a "Clod's" lane that CLAUDE.md never describes; they were filed under Clay and Tony rulings (SEQ 202, 230, 231).
- One paragraph.

### S3 -- dead code, no layout

**D-11 · Ten dead externs -- CUT.** Zero references outside definition and declaration in every population above, each confirmed whole-tree.

| extern | site | lines |
|---|---|---|
| `containsPoint` | GroupDraw.twk:62 | 7 |
| `getTextView` | GroupDraw.twk:91 | 19 |
| `aCTionCheckFor` | ruleActions.rtn:162; no rule is tagged `CheckFor`, so dlsym can never resolve it | 5 |
| `dumpColorRGB` | Debug.rtn:56 | 12 |
| `dumpFontInfo` | Debug.rtn:73 | 13 |
| `jitForceInclude` | jitEmitters.rtn:2143 | 5 |
| `loadRegistryFromString` | GroupActions.rtn:495 | 23 |
| `statementMatches` | GroupActions.rtn:1132 | 4 |
| `indentFrameWH` | Stylish.twk:127 | 4 |
| `sHADOW` | Stylish.twk:164 | 24 |

- **Size:** ~116 lines, 10 externs.
- **Risk:** `jitForceInclude`'s body is `Builder b; b=0;` -- possibly a link-forcing idiom. Check its history before cutting. `dumpColorRGB`/`dumpFontInfo` are lldb-callable debug helpers (CLAUDE.md bear-trap #14 cites them).

**D-12 · Four dead-text-only externs -- CUT.**
- `jitRunAddTwo` (jitEmitters.rtn:3137, 38 lines; only a `//` in incant/generate);
- `materialiseRegistry` (GroupActions.rtn:555, 7; only inside a `/* */` in GroupMain.twk:437);
- `labelMinters` (measure.twk:278, 14; already on cleanupList; plus a groups.ext:43 line the list missed);
- `measureLabelProbe` (measure.twk:533, 15; only a pop.sh comment).
- **Size:** ~74 lines, 4 externs. **Risk:** low.

**D-13 · `debugRuleNamed` (Debug.rtn:6) -- KEEP (ruled, SEQ 260 R6).** Reason: it is the directives build's rule-debug switch, so it is meant to be dead in a bare build. Its only callers are armed `groupDirectives` entries (parseUpTo :149, bootstrapper :301). It is a directives-build instrument, dead in a bare build by design.

**D-14 · Dead class methods -- CUT, except the debug helpers.**
- **Cut:**

| method | line | lines |
|---|---|---|
| `GroupItem::allAttributesOptional` | :205 | 7 (on cleanupList) |
| `attachBlocK` | :231 | 5 |
| `frameParent` | :768 | 8 |
| `getGuard` | :929 | 4 |
| `getRegex` | :1009 | 5 |
| `insertAfter` | :1098 | 8 |
| `insertGroup` | :1112 | 12 |
| `moveTo` | :1307 | 7 |
| `setMap` | :1849 | 8 |
| `sortByAttribute` | :2041 | 7 |
| `updateDispatch` | :2086 | 15 |
| `GroupDraw::setWindow` | GroupDraw.twk:21 | 31 |

  `getGuard` is a pure read; its three directives were culled by C-155.
- **KEEP (ruled, SEQ 260 R6), each for the same reason: an lldb or Xcode expression call is their road, and no
  census can see it** (the blind spot named at the head of this file):
  - `GroupItem::dQ` (:487) -- dumps a node's flags and body from a breakpoint;
  - `GroupItem::dumpField` (:506) -- prints one field with its attributes, the standard `po`-from-lldb helper;
  - `GroupControl::dumpSearchList` -- prints the live search list, which no runtime command shows;
  - `GroupStak::listStakked` -- prints the input stack, the one view of a divert in flight.
- **Size:** ~117 lines. **Risk:** low.

**D-15 · `parse()`'s `definer` / `defStuff` (GroupItem.twk:1380, 1383, 1399-1400) -- CUT.**
- On cleanupList; re-measured: written, never read.
- **Risk:** `instanceRule()` is a call, and the two lines are the last bare mentions after `use ruler`/`use ruleStuff` (#42/#58). Read the generated tail.

**D-16 · Twelve mirror-only `groups.ext` externs -- CUT.**
- `aCTionUnaryXP` 529, `debugTokens` 544, `genXP` 555, `iterBind` 568, `iterSpins` 569, `iterAdvance` 570, `tokenInSet` 706, `wrapDot` 711, `getInput` 807, `hasNNPattributes` 808, `setMacroValue` 809, `getColorNamed` 861.
- Zero definitions in tok, `.mm` or `.h`. The pop.sh mirror-arity row ignores names with no definition, so it will not move.
- **Size:** 12 support-repo lines. **Risk:** none on trunk (a function mirror is inert; measured in 5.8a).

### S4 -- the Bytecode road (ruled 09-30)

**D-17 · CUT, per cleanupList's list, CORRECTED.**
- **Still true:** Bytecode.h 21 externs; TOK.xcodeproj 8 refs (13, 160-162, 2161, 2184, 2265, 3278); Bytecode.twk/.mm/.h 1,014 lines; `incant/setup:55, :79` and 18 `interpretMethod=` clauses (8 on Operators, 10 on bcOPs); `Commands.rtn` `generateCode` :179 (~38 lines); oneTest dead region :78-105.
- **Moved:** `interpretMethod` handler is GroupActions.rtn:409-425 (was :399); `groups.ext` `interpretBC`/`interpretMethod` are :566-567 (was 553-554).
- **The list MISSED:**
  - `generateCode` at groups.ext:554 and `generateCode immediateAction;` at setup:49;
  - oneTest's header names `incant/generating` at **:17 and :37** (two lines);
  - **the whole `generating` mode, fed only by `generateCode`:**
    - `ruleActions.rtn:462` -> `generateXP` (:1320-1386, 67 lines, holding `copyOf(bcOPs["bcStoreField"])` at :1368);
    - `generating` branches at :725 (an "UNUSED" block), :973, :1035;
    - the `generating` (GroupRules.twk:102), `generator` (:56) and `bcOPs` (:37) members;
    - the bcOPs init at GroupControl.twk:195-196;
    - the stale comment at ruleActions.rtn:458.
- **bcOPs search lines:** 79 lines name bcOPs, 2 of them in the attic, so the 77 holds.
- **Choice at cut time:** keep an empty `bcOPs` registry (77 lines untouched), or drop it (77 preambles plus the members).
- **Size:** ~1,200 lines, 21+1 externs (canary moves by the GroupRules-chain ones only; count at cut time), 8 Xcode refs, ~19 groups.ext lines, ~13 setup lines + 8 clause edits, oneTest. CLAUDE.md's Phase Bytecode section (:221-315) plus the testByteCode mentions.
- **Risk:** medium. setup is read at runtime (#31): rebuild in the same commit. Re-run the 09-30 probe on the externs-removed binary (generate still loads).
- `incant/generate` stays as reference (R3) with a header line saying so.

### S5 -- layout cuts (one stroke, full bare tokall + #10 subdirectories)

**D-18 · RuleStuff fields -- CUT.**
- **Dead:** `isOption` (no writer, no reader); `doNothing` (only ever written 0, at ruleActions.rtn:979).
- **Write-only:** `banged` (GroupActions.rtn:611), `onFail` (RuleStuff.twk:145), `guardFAIL` (RuleStuff.twk:78, :100), `sourceLine` (ruleActions.rtn:954-957; Xcode-visible only -- Tony's call).
- RuleStuff is reachable from kant only through opDot cases 28 (`noLabeL`) and 36 (`hasActioN`), which read neither field.
- **Size:** 6 fields + their writers. **Risk:** layout.
- **KEEP:** `modPercent`/`modPointer`. Their only reader is a witness callout (measure.mm:840); an instrument reader is a reader.

**D-19 · groups.ext ghost class members -- CUT.**
- **GroupItem:** `addRuleStuff()` 253, `followingEntry()` 280 and `getActionMethod()` 283 (declared in GroupItem.h, never defined or called); overloads `()`->run 367, `+*` 370, `*=` 375, `&=` 377 and the `getDate` alias 363 (targets undefined).
- **GroupRules:** flag `membering` 481 (zero-init only).
- **Layout:** `wallColor`, `currentFont` 208-209.
- **Stylish:** `shadowOffset`, `shadowX`, `shadowY`, `subbed` 841-850, plus `shadowBlur`/`shadowColor` (exist only as same-named locals).
- **Size:** ~16 mirror lines; tokall changes GroupItem.h, GroupRules.h/.mm, Layout.h, Stylish.h/.mm.
- **Risk:** layout; GUI/ also has Layout/Stylish (the #10 basename caveat).

**D-20 · Dead jitContext.h globals -- CUT.**
- `gKantLabel`, `gKantFrom`, `gKantRule` (SEQ 54's kant parse frame) and `gParseRecordArmed` (genParse's retired GX-6 switch): no tok reference, no `.mm` reference outside the header.
- **Cut with D-4:** `gCompileAttempted`/`gCompileRefused`/`gCompileReported`.
- `gJitLastFn` is used only in GroupRules.mm -- keep, jit lane.
- **Size:** ~10 header lines. **Risk:** low (hand-written header, not tok).

### S6 -- one-door refactors already banked

**D-21 · `parseAny` -- CUT** (on cleanupList; re-measured).
- Generate.rtn:83-106 (~24 lines), `case isANY:` :420, the bootstrap GroupMain.twk:157-159, `testAny` RuleStuff.twk:230 bound at :161.
- **Sites the entry missed:** measure.twk:651 and :870 name tables, groups.ext:671 and :811, genParse.rtn:29 (`"isANY"`), GroupItem.twk:612 (`case isANY:` in setGuard).
- 17 word-bounded `Any` hits in kant are all prose. **Risk:** low; re-run its 0-call witness first.

**D-22 · `jitProbeDrive` -- REFACTOR to one drive door** (on cleanupList).
- jitEmitters.rtn:682-750 (~69 lines), called from probeDrive :2738, :2801, :2822. `driveStep` is now GroupActions.rtn:242-321.
- 6 fixtures use `probeDrive` (opLenT, tokJitT, adoptT, site1RoadsT, driveLeakT, probeDoorT); the pop.sh drive census reads 4 seats and should read 3 after.
- **Risk:** medium (the jitted carrier swap needs a seat in driveStep). Jit lane: Tony's timing.

### S7 -- two-meaning slots (ONE CHANNEL, ONE MEANING). Probes first, then splits, each a try-and-buy

**D-23 · `fLAG` -- FIX, probes first. FIVE meanings, not the two F-O15 ledgers.**

| meaning | writers | readers |
|---|---|---|
| A. define-attribute redirect | ruleActions.rtn:302/304 | 12 command handlers (Commands.rtn 148, 310, 360, 387, 451, 492, 557; GroupActions.rtn 329, 415, 913; Instruct.rtn 1263; jitEmitters.rtn 1860) |
| B. iterator poison | ruleActions.rtn 610, 617, 628, cleared 625 | Instruct.rtn 1176, 1212 |
| C. "this InvokeArg is a subscript" | ruleActions.rtn:89, on Braced's own label | :1067 |
| D. "recycle this label" | GroupItem.twk:288 (attachLabel promote) | RuleStuff.twk:105/110 (checkInput) |
| E. kant's generic flag | opSetFlag case 12 | opDot case 12 |

**Three pointable, unrun paths:**
1. **C -> D:** Braced's label keeps fLAG=1 in `rStuff.label`, so the next Braced match recycles the node already attached as the previous subscript (`a[0] + b[1]`). Not covered by `genParseShape.md` §1.9, which names only parse()'s promote as a writer. Depends on whether F-122's `defer` on Xpress delays aCTionTokenXP.
2. **B <- E:** Instruct.rtn:1176 reads the poison for EVERY `++` operand, so `x :. flaG; x++;` silently does not increment. This is F-7's surviving copy (:1176 dominates, :1212 is dead), still letting the run flag steer the emit walk.
3. **A <- B/C/D/E:** e.g. `x :. flaG; register(x)` silently redirects to `x.parent`.

- **Proposal:** run three one-file probes; on a red, split into four bits (isDefineFire 2w/12r, iterPoisoned 4w/1r with :1176 deleted, isSubscript 1w/1r, recycleLabel 2w/1r), plus a ruling on what kant's case 12 means.
- **Size:** ~25 sites, GroupBody layout. **Risk:** medium.

**D-24 · `sukcess` -- FIX (probe first) for the new collision; the rest is D-30.**
- **Meanings:**
  - G guard passed (checkInput);
  - M this iteration matched;
  - V action veto (fireLabelMethod GroupItem.twk:741);
  - R satisfied by min (GroupItem.twk:1430; Generate.rtn:136);
  - P chain truth (Generate.rtn:286);
  - F saved per-call state (callBracket).
- **Already measured:** G/M (F-114; cured by seven `sukcess = false` resets -- a discipline, not a structure) and F (F-121).
- **NEW, pointable, unrun:** V vs R. On the old road a vetoed iteration hits matchFailed, where `kount >= min` flips it back to true and the rewind inside `if !sukcess` is skipped, so the vetoed match's input stays consumed. exitFromParse rewinds first. **The two roads disagree on a vetoed optional term.**
- **Size:** a probe; then a `vetoed` channel (1 write, 3 reads) and a separate guard result (5 writes, delete 7 resets). **Risk:** medium.

**D-25 · `isLabel`'s "do not clear" -- REFACTOR (a separate bit).**
- GroupActions.rtn:713 stamps `isLabel` permanently on action locals with no rStuff and no labelOf, which **falsifies Ruling D2 ("isLabel => live rStuff") by construction**. The `:150` census counts them as labels.
- The new road's entry clear (Generate.rtn:256) does not test isLabel, so the two roads' clears disagree on stamped locals.
- No road observed to hand a stamped local to processAction or processCode.
- **Size:** 1 write, 1 read, GroupBody layout. **Risk:** low.

**D-26 · opDot's `if !argument` (Instruct.rtn:362) -- REFACTOR (a unary channel).**
- It means "called as the leading-dot unary" AND "the right operand evaluated to null". In a binary `a.<null>`, opDot silently swaps and reads the LEFT operand as the property name, against `lastREF.group`, with no refusal.
- Reachable only through isArgument or invoked operands.
- **Size:** 3-4 sites (opDot, the leading arm in handleUnary/handleDot, jitEmitDot, runOP). **Risk:** low-medium.

**D-27 · `deferred` -- REFACTOR (an `ownerRun` bit).**
- **Meanings:** the rule modifier "my action waits for an owner" (Commands.rtn:501); "label carries a pending action" (GroupItem.twk:731, never cleared); "I am being run by my owner, return VALUE" (5 readers in ruleActions.rtn -- F-122's two returns).
- **Pointable:** parseAction hands the FACE to the action, which then reads the rule modifier as owner-run; a recycled label (D-23 path D) keeps a stale `deferred=1`.
- **Size:** 1-2 writes, 5 reads. **Risk:** medium (F-122 territory).

**D-28 · `byRef` -- REFACTOR (three bits).**
- **Meanings:** opAssign store-by-reference; loop source "do not publish lastREF"; loop steering read off the statement RESULT (GroupRules.mm:661).
- **Pointable:** a `:. byRef`'d field returned by a FOR body steers the loop into the wrong list; a bytecode branch target stamped byRef later assigns by reference. (The bytecode writers go with S4.)
- **Size:** ~10 sites. **Risk:** medium.

**D-29 · RuleStuff `label` -- KEEP (watch).**
- "My own label" vs "a promoted child's label": attachLabel writes `pStuff.label = lab` while `lab.labelOf` stays the child. A promoted label reaching the parent's processAction would run the child's BlocK.
- **Why keep:** 5.6a's tap read labelOf == the rule on 60 / 60 processAction calls, and the fleet never reaches the case.
- **The cheap fix if ever wanted:** write labelOf on promote (1 site), or fold it into D-30.

**Also STRUCTURAL, ranked lower:**
- **`noPrint`, five meanings:** print suppression, fires-at-define, artifact/scaffolding, not-a-frame-slot, not-a-trait. Bear-trap #50 is the measured case. **REFACTOR later:** a first cut is an `artifact` / `frame-exempt` bit for the three frame walkers and ~8 artifact writers (>30 sites for a full split).
- **`isBranch`:** value vs signal; already planned onto ParseActivation (objectModel F-O15) -- **KEEP** pending that.

### S8 -- stroke 5's tail

**D-30 · Per-call state on the shared RuleStuff -> the activation -- REFACTOR, recon first (SEQ 258 R4's finding).**
- **Census** (generated code, by function):
  - `label` -- attachLabel, fireLabelMethod, parse, captureSpan, exitFromParse, every leaf parse method (parseUpTo/Any/Action/String/Character/Container/Set), parseRule, driveFloorLabel, aCTionCodE, checkInput and every RuleStuff `test*`, two measure callouts;
  - `hereAt` -- parse, exitFromParse, parseAny/Character/Set, parseRule, checkInput, the `test*` methods, captureSpan;
  - `kount` -- parse, parseLoop, parseRule, measureLoopVerdict;
  - `sukcess` -- parse (16 sites), every leaf parse method, exitFromParse, parseRule, parseCondition, fireLabelMethod, checkInput, the GroupItem copy constructor, two measure callouts.
  - Total: **29 functions, ~200 generated sites.**
- **What the move costs:**
  1. **Leaf parse methods push no activation**, so they would have to push one or be handed the caller's.
  2. **The `test*` methods take the field, not an activation:** signature changes (5.4's shape).
  3. **`ParseActivation.label` already exists** with another meaning (the drive floor's label, one writer `driveFloorLabel`). The moved field needs a new name or it becomes a two-meaning slot (SEQ 235 R1 naming rule; bear-trap #58).
  4. **Layout on both structs** (SEQ 237's name grep, a full bare-tokall certificate).
  5. **What it retires:** the callBracket's four slots and getStuff's inProcess copy (NO HUNT sites 6 and 7), F-114 and F-121 by structure, and `sukcess`'s F meaning.
- **§25d's measurement is the ledger for this:** the label slot protects 4,871 live outer frames today, so the moved state must keep that protection by construction.
- **Risk:** high. Recon first.

### Housekeeping (Tony's word; no code)

**D-31 · Branches.**
- **Delete (27, fully merged, local + remote):** cut-dupcensus, definert-watch, f130-rows, om-fo32, om-fo35, om-stroke1, om-stroke1b, om-stroke2, om-stroke3, om-stroke3a, retire-limit, om-stroke44a, om-stroke44b, real-terms, seq196-optional-min0, seq212-drive-compile, stroke-5.5a-stopped, try-fire-root-rebased, tryAndBuy-argBind, and local-only om-macrostrip, om-propop, om-rename, om-stroke41, om-stroke42, om-stroke43.
- **Not merged:**

| branch | ahead | proposal |
|---|---|---|
| try-fire-root | 1 | **delete**: `git cherry` shows its patch is in trunk |
| tryAndBuy-gNoUnwrap | 1, declined | **delete** (or keep as a tag) |
| flip-argument | 1, superseded | **delete** |
| checkinput-state | 2, NO BUY | **delete** after confirming `d1c92a5` "comment store" was not wanted |
| group-descent | 5 | **delete** after confirming F-98 is banked on trunk |
| holder-attribute | 1, a signature try | **Tony's call** |
| om-r2-ownname | 2 | **keep**: counterCapture and membersFlagCapture cite its currentDefine repair |
| parse-then-fire | 24 | **keep until ruled** |
| p6-held-class | 26 | **keep until ruled**, or one ruling deletes both with parse-then-fire |

**D-32 · `main` and `origin/HEAD` -- Tony's call.**
- Local `main` (b411ffa, 06-30) is an ancestor of trunk, 1,407 commits behind, and 8 commits ahead of `origin/main`, never pushed.
- `origin/HEAD` points at `origin/main`, so GitHub's default branch is three months stale.
- Fast-forward `main` to trunk, or retire it.

**D-33 · `docs/wakeup.md` trim -- REFACTOR (a move, verbatim).**
- 2,188 lines, 47 seals (09-20 .. 10-02). The 12 seals older than 7 days are lines 1165-2185 (~1,021 lines, 47%).
- **Precedent:** `docs/wakeupVintage-to-2026-09-19.md`.
- Move them verbatim to `docs/wakeupVintage-2026-09-20-to-09-24.md` and extend the footer pointer; wakeup.md drops to ~1,167 lines.

**D-34 · Clod's six fixits.**

| fixit | proposal | reason |
|---|---|---|
| `counterCapture` (F-O40) | **keep** | still reproduces |
| `docsOnCommands` (F-O41) | **keep**, merge into counterCapture's file | same R2 fix site (aCTionTraiT); one file may carry two tests |
| `membersFlagCapture` | **keep** | still reproduces; tied to om-r2-ownname |
| `traitDataCapture` | **keep**, consolidate with the three above | still reproduces; one define-road capture family |
| `ppwriteCountIsAnAddress` | **close** by D-5 | -- |
| `refireSkipsDegraded` | **keep** | jit lane, Tony's phased rewrite (SEQ 193) unwritten |

- **Finding for `refireSkipsDegraded`:** its anchors pin only the compiled statement, so they pass for the wrong reason.

**D-35 · The measure* move -- nothing to do (done 09-26, `0d7dea0`)** except D-7's strike.

### Parked, with reasons

**D-36 · cleanupList `testAttributes`' artifact skip (`if noPrint continue;`, RuleStuff.twk:242) -- KEEP pending Tony** (its strike-or-keep is already Tony's). The 09-29 dynamic counts were not re-run.

**D-37 · cleanupList `genParse.rtn` rename -- KEEP (a move, Tony's timing).** One sentence is stale: "Only dupCensus is callerless" -- dupCensus was cut 09-30, and every extern left in the file is live. Fix the sentence.

**D-38 · cleanupList's three `::enclosingFace` escapes -- KEEP (parked by SEQ 235 R3).** Now Generate.rtn:155, :202, :227.

**D-39 · Inline `// slug` comments with no DesignDocs entry -- KEEP.** 126 distinct slugs (Generate.rtn 43, ruleActions.rtn 40, GroupItem.twk 36, GroupActions.rtn 25, ...). The 09-15 `// slug sentence?` ruling allows them, and the comment trial has no dangling-pointer row by design.

**D-40 · jit tok declarations -- PARKED with the jitter.**
- ~60 jitContext.h globals and structs are referenced from tok through passthrough with **no groups.ext mirror**. The bulk is in jitEmitters.rtn (the jit lane).
- **Outside it, and engine state rather than jit:** `gCompileOwner` (GroupActions.rtn:761/763, ruleActions.rtn:649 -- compile's name owner, read by aCTionNamE). It is the first candidate for "NO NEW FIELD TOK CANNOT SEE" when the lane opens.
- **Others outside jitEmitters:** `gJitResult` (ruleActions.rtn ×4), `gJitStmtCanRefuse`, the probe globals in Generate.rtn:270-274, `gJitSlotCount`/`gJitSlotUnaryRefused`, `gTermCallCount`, `reportCompileCensus` (D-4 cuts it).

**D-41 · C++ escapes -- COUNT ONLY (parked until the jitter pauses).**

| file | blocks | lines inside | `::name` | `ns::name` |
|---|---|---|---|---|
| jitEmitters.rtn | 95 | 2,232 | 65 | 778 |
| measure.twk | 38 | 364 | 76 | 36 |
| Instruct.rtn | 25 | 8 | 5 | 0 |
| GroupActions.rtn | 20 | 188 | 39 | 7 |
| ruleActions.rtn | 16 | 28 | 4 | 4 |
| GroupItem.twk | 9 | 19 | 7 | 1 |
| Generate.rtn | 7 | 27 | 6 | 0 |
| GroupDraw.twk | 3 | 61 | 9 | 0 |
| Commands.rtn | 3 | 2 | 4 | 0 |
| Debug.rtn | 2 | 15 | 0 | 0 |
| Stylish.twk | 1 | 38 | 2 | 0 |
| genParse.rtn | 1 | 14 | 2 | 0 |
| **total** | **220** | | **217** | **826** |

None in Bytecode, GroupBody, GroupControl, GroupList, GroupMain, GroupRules, groups, GroupStak, Layout, RuleStuff. Outside jit and measure: 87 blocks in the engine.

---

## Registered commands never invoked (live by rule -- listed for Tony, no proposal)

Registration is a caller (R4), so these are live, but no kant file outside `incant/setup` uses the command name: `arrondir` (setup:22), `bodyCensus` (:28), `debugGuard` -> debugOnGuard (:39), `evictAction` (:44), `flushBuffer` (:48), `system` -> runSystem (:87), `copy` -> cOPY (:37; used only in the attic). If any is not meant as user API, it joins S3.
