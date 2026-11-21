# The kant library read (R0, 2026-11-21, SEQ 732 assigned by Clod; read-only)

Clay's dispatch, Tony's ruling of 2026-11-21: a read-only pass over the kant library, utilities first, measured against
`docs/kantPatterns.md` ("today's kant"). Three lists. Every item gives where, the claim, and the measurement that would
confirm it. **Nothing in the library was edited.** List 1 is proposals only (R1's whole-tree census decides); list 3 goes
to the kant docket, not the cleanup.

**The binary:** `~/bin/incant`, the bare build of 2026-11-20 12:54, 2191072 bytes (the one seal 520 was measured on).

**What was read.** In full: `incant/utilities` (1597 lines), `incant/unitTests`, `incant/lookup`, the live part of
`IncantForms/WorkingOn/parser` (lines 1-78), `Topics/forms` above its `bail()`, the show actions in `incant/setup`
(lines 384-565), `IncantForms/Controls/` (all five files), `incant/stash`, `stashList`, `showStage`, `showFinish`.
Skimmed, head and foot only: `incant/directives`, `incant/decoder`.
**Not read:** `incant/kantGrammar`, `incant/kantJitter` (the kant topic's own code, 1891 lines), `incant/designDocs`,
`incant/jigcorpus`, `incant/generate` (reference only), the forms in `IncantForms/Windows/`. An absence claimed below is
an absence in the files read, plus the `git grep` named with it.

**How "measured" is used.** *Measured* = run today, in this pass, by a scratch probe (one process each, under an alarm,
exit status and a sentinel read) or by a grep whose population is named. *Not measured* = read from the source only.
The probes were scratch files and are not in the tree; each is small enough to retype from its description.

**The numbers for utilities** (counted by a script over the file, comments stripped):
41 actions, 63 declarations that are not actions (22 of them rules). 336 lines are block comment and 51 are `//` lines: 24% of the file.
Three actions hold 489 of the code lines: `typeset` 255, `frameMembers` 134, `bigifyLayout` 100.
In the whole file: `&&` 0 times, `break` 0, `continue` 1, `else` 16, `or` 11; 150 tests of the form `if flag == 0;`.

---

## List 1 -- Organization (proposals; R1 decides)

### 1a. What is in utilities, and an order for it

Utilities holds ten unrelated families. Today they are interleaved; the proposal is one block per family, in this order,
each with its fields directly above its actions.

| family | what | where today |
|---|---|---|
| tell | the `tell` rule | 11 |
| printing a field | `dumpField` 16, `listRules` 601 (with `listed` 595) | apart by 580 lines |
| JSON | the JSON rules | 41-68 |
| layout | `fillDownAcross` 659, `frameMembers` 700, `placeForm` 869, `frameWhole` 896, `setFrame` 1185 | split by looks and cards |
| looks and styles | `setLook` 927, `lookFirst` 970, `setLookByName` 975, `resolveLook` 1027, `mergeStyles` 1059, the nine `lk*`/`ln*` fields | inside the layout family |
| cards | `cpBars` `cpBar` `cpCards` `cpOne` `cardsPick` 1097-1184 | between mergeStyles and setFrame |
| the frame store | `formFrames` 1246, `keepFrame` 1253 | after setFrame, which reads it |
| typesetting | the `ts*` rules 161-181, `tsFind`, `tsBoxWarn`, `typeset` 213 | between drawWalk and drawText |
| drawing | `drawWalk` 97, `drawText` 480, `drawImage`, `drawFill`, `drawBorder`, `drawKids` 582 | drawWalk is 380 lines above the rest |
| show, redraw, click | `redrawWindow` 1283, `redrawForm` 1306, `showPathRoot`, `showForm` 1350, `clickFire`, `click` 1422, `describe` 121 | describe is 1300 lines from click |

- **O1. Order is free for actions, so it can be chosen for the reader.** `incant/utilities` throughout.
  Claim: an action's names bind at its first call (F-164), not where it is written, so moving an action changes nothing;
  a *rule* does need defining before use (the JSON forward declarations at 41-42 say so; fixit ruleUsedBeforeDefined).
  Confirm: reorder a copy, show `genLadder/codeOnly.py` reads the same lines sorted, and run pop.sh and formsPop.sh: no
  row moves. The cheat pattern cannot test this (it shadows actions, not their order), so it is a branch.

- **O2. Two headers have drifted away from their actions.** `incant/utilities:835-852` is setFrame's header; setFrame is
  at 1185, 333 lines down, and the header is followed directly by placeForm's header. `:904-913` is mergeStyles' header;
  mergeStyles is at 1059, and the header is followed by the `lk*` fields and setLook's header.
  Confirm: by reading; nothing to run.

- **O3. A field declared after the action that uses it.** `cpHits` is declared at `:1175`, after `cpOne` uses it at
  `:1163`; `rlSays` at `:1020`, after `typeset` uses it at `:325`. Both work (binding at first call). Proposal: fields
  first, per family. Confirm: as O1.

- **O4. `click` borrows typeset's search state.** `incant/utilities:1434-1439` writes `tsHit`, `tsWant`, `tsFound`,
  which are typeset's (`:182-184`), and calls `tsFind`. The comment at `:1443` is there because of it: a redraw fired by
  the click runs typeset, which overwrites `tsFound`. Proposal: the find is one small action of its own, named for what
  it does (find a field by name in a form), owned by neither. See C4 for its shape.
  Confirm: measured that the script finds `tsWant`, `tsFound`, `tsHit` in exactly three actions: tsFind, typeset, click.

- **O5. The show family lives in two files.** `incant/setup:403-565` holds `show`, `showNow`, `showFinish`,
  `showStage`, `showSearch`, `showAddRegs`, `showCheckFiles`, `showLoadFiles` (160 lines of actions, in the file whose
  own commentary calls it a reference table); `incant/utilities:1341-1390` holds `showForm` and `showPathRoot`.
  setup's must be there: show has to work before utilities is loaded. Proposal: no move; one line in each place naming
  the other half. Also: setup's `showFinish` uses locals `sfN sfHas sfF sfShow`, the same `sf` prefix setFrame uses for
  eleven names in utilities. They are locals, so nothing collides, but a grep for `sfHas` lands in both.
  Confirm: by reading.

- **O6. Utilities pulls in two other files at its foot.** `incant/utilities:1589` `include(parser)` is marked INTERIM
  (ruled 2026-09-17); the file is `IncantForms/WorkingOn/parser`, which registers its actions into Utilities.
  `:1594` `include(forms)` is `Topics/forms`, a topic file whose first 60 lines are library code.
  Proposal for M2: both are library code living outside `incant/`; decide their home when files are split.
  Confirm: `git grep -n "include(parser)\|include(forms)"` for who else includes either.

- **O7. Comments: a quarter of the file, and the house rule says they go at the foot.** 336 block-comment lines and 51
  `//` lines of 1597. 25 lines are over 160 characters; the longest are `:360` (721), `:237` (702), `:404` (676), all
  inside typeset or fillDownAcross. CLAUDE.md's rule for an incantation is comments below `bail()`, and `incant/setup`
  already moved its commentary to its foot (Tony, 2026-09-16). Utilities cannot end in a bare `bail()` today because its
  foot does work (`:1589-1597`). Proposal: one line above each action saying what it does; the argument, the dates and
  the SEQ numbers below a `bail()` placed after line 1597.
  Confirm: that a `bail()` at the foot of an *included* file ends only that file is ruled (seal 520); run pop.sh and
  formsPop.sh on a branch.

### 1b. What looks dead (proposals; each needs R1's census before a cut)

For each: no caller in the tracked tree outside its own file. The grep was `git grep -lw <name>` over everything except
`incant/utilities`, `incant/attic`, `docs`, `incant/designDocs` and the generated `.mm`/`.h`.

- **D1. `toXML`, `incant/utilities:625-642`.** No caller, no fleet row. **Measured: its body no longer parses**
  (`toXML(simple)`: "ERROR processCode: toXML parse failed ... failed at if hasAttributes;", exit 0). It is written in
  an older kant (`tag`, `hasMembers`, `if grup.datA print`).
- **D2. `flatten`, `:73-79`.** No caller, no row; its own header says "just a test action". It writes `whatsIt`, a field
  of `incant/unitTests`. **Measured:** `flatten(simple)` prints "Adding 0" three times and three
  "ERROR Operator += failed on whatsIt and grup"; nothing is added.
- **D3. `hexToNumber` `:1453` and `setHexColor` `:1468`.** No caller, no row; colours come from the floor now.
  **Measured:** `hexToNumber` on a field holding "ff" refuses once ("Operator ++ ... no value to bump") and then does
  not end (killed by the 30 second alarm, exit 142); `setHexColor` refuses at its first line. The probe's own spelling
  may be part of this: neither has a known-good call to copy.
- **D4. `bigifyLayout`, `:1485-1584`, 100 lines.** No caller: `IncantForms/Windows/bigify` does not name it, and that
  form includes two deleted XML paths (seal 442's open issue). **Measured:** on a 2x2 request it refuses at its first
  arithmetic ("REFUSED rows -- Operator -") and carries on. It is the third-largest action in the file.
- **D5. `newStuff isList`, `:658`.** Named by no action. The comment at `:676` says the scratch-list way it served was
  replaced (SEQ 653). `incant/pop/climbT` and formsPop.sh name it in prose only.
- **D6. The obituary at `:1449`** ("quoteIfNeeded obituary: never called") is a comment for an action that is gone.
- **D7. In `incant/unitTests`: thirteen entries the runner never calls and no fixture names.** `callMyself` 118 (its own
  header says it recurses for ever), `invokeTest` 145, `testForC` 159, `testNegate` 171, `testNew` 172, `testPointer`
  173, `testScope` 180, `delimitRecord` 126, `commaStuff` 125, `jsonFile` 146 (an absolute path under
  `/Users/anthony/Dropbox/...`), `winForm` 95, `plainField` 94, `floaty` 88. The header (`:7-8`) calls them
  "unverified, legacy-POP sweep pending".
  Confirm: R1's census by name; then call each once in a scratch file to learn which still build.
  Note: `layout` (`:147`) is the name of an action here and a common word in the fleet (33 files), so a name grep cannot
  clear it; it needs reading.
- **D8. `IncantForms/Controls/attributes`, `traits`, `templates`.** XML-era text (`#registry`, `<tag/>`), not kant.
  Nothing loads them: the only references are three forms (bigify, db, inspector) including deleted XML paths, and
  `attributes:91` itself includes a path under `/Users/anthony/data/Tawk/`. `styles` and `formFacts` are today's.
  Confirm: the grep above returned those lines and no other; R1's census.

Alive, for the record: `dumpField` (5 fixtures), `listRules` (2), the JSON rules (jsonTest and two more), `tell` (45),
`describe` (the forms). `incant/lookup` runs today (exit 0, its sentinel printed; two "list too short to stack" warnings).

---

## List 2 -- Catching up (old actions that should use today's kant)

- **C1. The flag ladder where `if / or / else` and `&&` now work.** All of utilities; worst in `typeset`.
  Claim: utilities was written before the ergonomics census (`docs/ergoCensus.md`, 2026-11-19) showed that an indented
  multi-statement `else`, `or` as else-if, `&&`, `||`, `break` and `continue` all work in an action body on both
  grammars. The file has 150 lines of the form `if flag == 1;`, 0 `&&`, 0 `break`, 1 `continue`. `typeset` alone sets a
  0/1 flag 59 times and tests one 37 times, with one `else` and no `or`.
  Already shown once: `IncantForms/WorkingOn/ergoSpecimen` rewrote `resolveLook` 32 lines to 19, byte-identical output.
  Confirm, per action: rewrite in a cheat (kantPatterns 16), its rows unchanged.

- **C2. Five-deep `if` pyramids that are one condition.** `incant/utilities:531-535` (drawText: five nested `if`s to
  say "all five found"); `incant/unitTests:322-326` (tsfCount, four deep); the `kfOk = kfOk + 1 ... if kfOk != 3` count
  at `:1255-1258` and `:1424-1427`.
  **Measured today:** `s := argument; if *s["x"] && *s["y"] && *s["width"];` reads 1 when all three are there and 0 when
  one is missing; `if p == 1 && q == 1 && r == 1;` reads right both ways. (Row for the count case: IE-20. The subscript
  case has no fleet row.)
  Confirm: a row for `&&` over subscript reads, then the rewrite in a cheat.

- **C3. Results handed back through a shared field where `return` works.** `frameWhole` writes `fwOk` (`:895-903`) and
  setFrame reads it (`:1197`); `lookFirst` writes `lnFirst` (`:970`); `cpBar` writes `cpWant` (`:1147`); `cpOne` bumps
  `cpHits` (`:1163`).
  Claim: an action's `return` reads as its truth in an `if` (kantPatterns 15; rows RR-22 to RR-24), so
  `if frameWhole(**sfFrame);` needs no `fwOk`.
  Confirm: the cheat, rows `frameStoreT`, `resizeT` and the frame-refusal row unchanged.

- **C4. The find, without three shared fields.** `tsFind`, `incant/utilities:185-194`, signals through `tsHit` and
  hands back through `tsFound`; both callers (`:281-288`, `:1434-1439`) also test the top field by hand first.
  **Measured today:** a recursive find that returns the field it found (`if *pfT == *pfWant; return *grup;` inside a
  `for ... members`, and `pfR := pfFind(*grup); if *pfR; return *pfR;` for the recursion) found a field two levels down,
  one at the top level, and read false for a name that is not there. `tsHit` and `tsFound` go; the wanted name is still
  one shared field, or rides in a request (kantPatterns 4).
  Confirm: `typesetT`'s insert rows and the click rows unchanged, in a cheat.

- **C5. Arguments handed over through shared fields.** `tARGET` and `dIRECTion` (`:656-657`) are set by frameMembers
  (`:727-733`) so that fillDownAcross can read them: a second and third argument by another name. Today's spelling is a
  request field (kantPatterns 4), or simply two calls sites that pass the direction's name and derive the target from it.
  Confirm: the cheat (the template cheat already carries frameMembers), `climbT` and the repeat rows unchanged.

- **C6. Three spellings of "compare a tag" in one file.** `tfTag := *grup.taG; if *tfTag == *tsWant;` (`:188-189`);
  `cbT = string $*grup.taG$; if cbT == cbName;` (`:1121-1124`, 19 `string $...$` captures in the file);
  `if *tyNl.taG == "close";` directly (`:404`, `:232`). Proposal: one spelling, the direct one where a literal is on the
  right. Confirm: not measured whether the direct form works with a field on the right; one probe, then the cheat.

- **C7. Three spellings of "add one".** `tyOpen = tyOpen + 1;` (`:313`), `tyHops += 1;` (`:280`), `++shareN;` (`:772`).
  All work. One spelling. Confirm: by reading; rows unchanged.

- **C8. The climb to the top field, written twice.** `:274-280` (typeset) and `:505-538` (drawText) both walk
  `.parenT` up to the field whose `isPointeR` is 1, each with its own `Hops < 32` counter used as a `break`.
  Today: `while 1; if top; break;` or one small action `formTop` that returns the top. Confirm: cheat, rows unchanged.

- **C9. The old scope statement.** `=:argument across down ...;` at `:701`, `:741`, `:796`, `:897`; `:argument ...;` at
  `:1487`, and in `incant/unitTests:332`, `incant/directives` (three places). It works on `incant/grammar` and, for the
  value form, on kantGrammar since full monty stroke 2 (scopeValueNewT). No change proposed; listed so the full monty's
  marking of these bodies knows where they are. Confirm: `grep -nE '^\s*=?:[a-z]'` over the library.

- **C10. `copyOf` where the copy is then attached.** 40 `copyOf(` in utilities against 6 `copyDeep(`. Most are
  `*grup :% copyOf(width);` on a plain count, where sharing attributes cannot matter. Not claimed wrong. Listed because
  kantPatterns 7 makes `copyDeep` the default "own copy" and three comments in this file (`:331`, `:440`, `:1208`)
  record a `copyOf` that had to become `copyDeep`. Confirm: a census of the 40 by what is copied (a count, or a field
  with attributes); only the second kind is a risk.

### Shortening typeset (254 lines, `incant/utilities:213-467`)

The hypothesis to measure was that typeset is long because its state is carried in shared fields. **Measured, and it is
half right.** typeset names 12 shared fields (`tsOut tsRuns tsRunCount tsWho tsRun tsSpan tsRunName tsWant tsFound tsHit
rlSays` and the three rules) but **66 locals** of its own. The length is in the locals: the action is one loop with
eight levels of nesting, 59 flag sets and 37 flag tests, because it was written as one body. It was written as one body
because splitting it means handing a dozen values to each piece, and kant passes one argument (list 3, K1). So the
shared fields are the symptom; the single-argument call is the cause. In order of what each would save:

- **T1. Respell the control flow (C1).** No design change. The specimen's ratio (32 to 19) suggests roughly 250 lines to
  170. Confirm: cheat, `typesetT` and `runLookT` unchanged.

- **T2. Keep the open runs as a stack, not a log.** `:350-372` and `:414-423` walk `tsRuns` three times, counting
  positions, to find "the last entry written with each depth", because an entry is appended at an open (`:333`) and
  never removed at a close (`:334-337`). If a close removed the last entry (`tsRuns -% ...`, as setFrame does with
  `sfChain` at `:1235`), the open runs would be exactly the list, outermost first, and the three walks become one
  `for e in tsRuns`. About 35 lines to about 10, and `tyD`, `tyPos`, `tyAt`, `tySpace` go.
  Confirm: `typesetT`'s nested-run rows and `runLookT`; a new row for close-then-reopen at the same depth, which is
  the case the log was written for.

- **T3. Resolve the insert in its own action.** `:249-301`, 53 lines: given a piece, find the field or registry entry,
  warn by name, hand back a mode and the found field. One argument in (the piece) and a record out (kantPatterns 5).
  Confirm: `typesetT`'s T3 and passages rows.

- **T4. The inserted text by recursion, not by diving.** The loop switches itself onto the inserted text's units and
  back (`tyDive`, `tyBack`, `tyInside`, `tyFloor`, `tyOutGaps`, `tyOutLines`; `:302-308`, `:445-466`, and the look-past
  at `:382-397`). A walk action called on a list of units, calling itself for an insert, would drop the switch and the
  surface block. It needs the walk's state passed in or shared, so it waits on the layout context already ruled
  (Topics/typesetting 44). Not measured; the largest saving and the largest risk.

- **T5. One warning action.** `tyFt := *tsWho.taG;` then a `cerr "drawSpans: WARNING" tyFt ...` appears five times
  (`:246`, `:264-269`, `:290`, `:320`). The capture is forced: a starred read cannot follow another item in a print
  (list 3, K2). Compute it once at the top of typeset. Confirm: the warning rows' text unchanged.

- **T6. Emit and gap as two small actions** (`:373-412` the gap after a span, `:424-444` the emit). Same cost as T3.

---

## List 3 -- Kant friction (for the kant docket, not the cleanup)

What in kant itself got in the way, read from what the library had to write around it. The five complaints already
answered (control flow, several arguments, results by label, holder or held, list walking: `docs/ergoCensus.md`) are not
repeated; these are beyond them, or sharpen one. Each says whether a fixit already holds it.

- **K1. One argument is the reason long actions stay long.** Sharpens complaint 2. Ruled convention: a request field in,
  a record out. Reading the library, the convention is used at the *outside* of the forms code (setFrame, redrawForm,
  click, keepFrame all take a request) and almost never *inside* it: an action that wants to split into two pieces keeps
  one piece and shares fields instead (`tARGET`/`dIRECTion`, `fwOk`, `cpWant`/`cpHits`/`cpTab`, `lnFirst`/`lnHeld`,
  `tsWant`/`tsHit`/`tsFound`, `rlSays`). **Measured:** of utilities' 41 declared fields that are neither actions nor rules, 27 are named by
  two or more actions; 25 of those only carry a value from one action to another (`formFrames` and `showPath` are real state). A request costs a declared field, a line per member to
  fill it and a line per member to read it; a shared field costs one line. So the cheap path is the one that tangles.
  What would help: a call that takes named values without a declared request (the callee reading them as locals).
  Docket; no fixit (multiArgLosesBody covers only the refusal for `f(a, b)`).

- **K2. A starred read cannot follow another item in a print.** `incant/utilities:246`, `:264`, `:290`, `:320`, `:1365`
  and others (17 lines of the form `x := *y.taG;`) capture a tag into a local before printing it. **Measured today:** `print *h.taG:;` prints
  the tag; `print *h.taG "then text":;` prints both; `print "text then" *h.taG:;` refuses,
  "REFUSED Token -- Operator * -- cannot apply to these operands": after an item the star is read as multiply.
  The refusal names neither the print nor the cure. No fixit found for it (`ls incant/fixits`). Cost in the library: one
  extra line and one extra local at nearly every message.

- **K3. A slot of a request cannot be starred through its dot.** `incant/utilities:485-487` keeps the same choice twice,
  once in `textReq.source` and once in a local `dtSrc`, and says why. **Measured today:** `rq.source := pl;` then
  `who(*rq.source);` refuses, and the refusal is a good one: "in `*x.y` the star binds to x, so read through a
  temporary". So this is ruled behaviour (2026-10-06 R1) with a named cure, not a defect. It is friction all the same:
  a request is the ruled way to pass several things, and reading one back out of it takes two statements.

- **K4. Stars have to be counted, and the count changes with how the thing was reached.** One, two or none for the same
  idea within a few lines: `tyE := tsRuns.firsT;` (`:355`, none: a declared field) beside `tyUnit := *tyTree.firsT;`
  (`:222`, one: a holder); `**tyEs["font"]` (`:367`, two); `**grup.taG` against `*grup.taG` (`:1042`, `:1056`, the held
  field's tag against the attribute's own). utilities has 258 lines with a starred read, 53 of them double; each count was settled by running it.
  The compare law made one wrong count refuse by name. The same treatment for a read (a holder read unstarred where a
  value is wanted) would catch the rest. Docket (Clay's holder-or-held write-up); fixit starlessHeldWriteCrash covers
  the write.

- **K5. A cited trap that does not reproduce: "a := made inside an if arm holds nothing after it".** Cited as measured
  (SEQ 687, 688) at `incant/utilities:969`, `:1219` and `incant/setup:485`, `:493`, `:556`, and each site binds a holder
  early and tests a flag later because of it. **Measured today, in an action body, three shapes** (a one-line arm
  `if k == 1; e := store[nm];`, an indented arm, and bound at the top): the holder reads right after the arm in all
  three. So either it was cured since, or it bites only in the shape SEQ 687 met (inside `show`, with an include
  queued), which this probe did not rebuild. Confirm: in a cheat of setFrame, move `sfEnt :=` (`:1220`) into the arm at
  `:1217-1218` and run `frameStoreT`; the same for `show` in a copy of setup. If both stay green the five comments and
  their flags go; if not, the failing shape is the fixit.

- **K6. A `for` cannot walk what a starred holder holds, so each such walk is its own action.** `tsBoxWarn` (`:198`,
  "its own action because a for loop walks an argument's attributes and not a starred holder's"), `lookFirst` (`:969`),
  `showAddRegs` (`incant/setup:524`, "for grup in *x reads the star as text"). Held by fixit oldRoadForStarWalk. Listed
  for its cost: three actions and their shared fields exist only for this.

- **K7. A subscript on a field with no list is an error, not a "no".** `:1103-1106`, `:1131-1142`, `:1152-1154` each
  read `listLengtH` first and guard the subscript. Held by fixit bareFieldNoList. Cost here: a flag and two lines at
  every "does this field have attribute x".

- **K8. An empty held field cannot be told from a placeholder.** `:1031` ("kant cannot read the virtual flag, so a
  placeholder is known by what it is"), and its price at `:1088` and `:1113`: the tab bar's "nothing selected" has to be
  a held 0, because held-and-empty already means placeholder. Held by fixit emptyFieldIsPlaceholder.

- **K9. An attribute in a define named like a field on the search list writes that field.** The reason for
  `searchNames`/`fileNames`/`stageNames` (`incant/setup:390`: "a member named search or show writes onto the command of
  that name") and for `look="dark"` by text (`:959`). Held by fixit defineAttrWritesField (ruled: virtual cures it; not
  built). Listed because the library is now choosing its names around it.

- **K10. A body binds its names at its first call.** `incant/setup:516-518` and `:558-560` reach `showForm` as
  `Utilities["showForm"]` and call through a holder, and the cheat pattern's whole discipline (search the cheat before
  the first call) is this fact. F-164. Not a defect by itself; it makes "which copy am I running" something only a
  witness line can answer.

- **K11. No way to hand a context down a call chain, so it is saved and put back by hand.** `placeForm` saves
  `lkHas`, `lkNamed`, `lkLook`, calls setFrame, and restores them (`:882-890`); typeset sets `rlSays = "drawSpans:"`,
  calls resolveLook, and sets it back (`:325-327`); `lkHeld` is raised for exactly one call and cleared by the callee
  (`:885`, `:930-931`). Each is a value that should be true "for this call and what it calls". The layout context is
  already ruled (Topics/typesetting 44; Topics/forms, stroke 4's note). Listed as the second place the same need shows.

- **K12. The end of a sibling chain is tested by `datA`.** `while tyUnit.datA != 0;` (`:223` and six more). It reads as
  "while this unit has data", and what it means is "while there is a unit". **Measured today:** it is not the hazard it
  looks like: a walk over three members, the first with no value, counts 3, the same as `for`. So no defect; the
  spelling says the wrong thing to a reader, and `for e in t` (kantPatterns 3) says the right one wherever the walk does
  not need to stop and resume.

### Hypotheses this pass falsified, so nobody re-derives them

- "A member with no value ends a `.nexT` / `datA` walk early." No: K12.
- "typeset is long because of shared fields." Half: 12 shared, 66 local; see the typeset section.

---

## What this pass did not do

No edit to any library file, no fixit minted, no entry added to `docs/cleanupList.md` (R1's census decides the dead
list). No instrument was run: this commit adds one file under `docs/` that no instrument reads. The scratch probes are
not in the tree.

---

## R1 -- the census of 1b, whole tree (2026-11-21, SEQ 733 assigned by Clod; read-only, nothing cut)

**The search.** `grep -rlw <name> .` from the repo root, `.git` excluded and nothing else: so the gitignored
`Directives/`, `groupDirectives`, `IncantForms/WorkingOn/incant++` and `tester`, `IncantForms/Windows/`,
`incant/attic`, the fixtures, the scripts and the generated `.mm`/`.h` were all in it. A hit in `docs/`, a topic file or
a comment is named as prose and is not a caller. `layout` was read, not grepped.

| item | callers in the whole tree | proposal |
|---|---|---|
| D1 `toXML` | none. Prose only: four files under `docs/`. | **cut** (its body does not parse today) |
| D2 `flatten` | none. Prose only: `docs/`, TODO.md; `docs/cleanupList.md:9` already lists it (2026-11-08). | **cut** |
| D3 `hexToNumber` | none. Prose only: three files under `docs/`. | **kept, ruled (Tony)**; see below |
| D3 `setHexColor` | none anywhere; this file is the only other mention. | **cut** |
| D4 `bigifyLayout` | none. Prose only: three files under `docs/`. `IncantForms/Windows/bigify` does not name it. | **cut**, or keep with the bigify form if that form is to be repaired: Tony's call, they go together |
| D5 `newStuff` | none. Prose only: `incant/pop/climbT:82` and `genLadder/formsPop.sh:858-859` (comments recalling the old way); `docs/cleanupList.md:375` already lists it (2026-11-14). | **cut** |
| D6 the `quoteIfNeeded` obituary | no action of that name exists. `incant/designDocs:95-118` holds the same obituary as an entry. | **cut** the line in utilities; the designDocs entry is the record |
| D7 `callMyself` | none. | **cut** (known to recurse for ever) |
| D7 `invokeTest`, `testNegate`, `testPointer`, `testScope`, `delimitRecord`, `commaStuff`, `jsonFile`, `winForm`, `plainField` | none in the whole tree, each. | **cut**, except `testPointer`: **keep until the string-pointer fixture below exists**, then cut (it is the only other string-pointer text) |
| D7 `testForC` | none. `incant/attic/goldenDrift:125` names it in a table of old output. | **cut** |
| D7 `testNew` | none. Prose: CLAUDE.md bear-trap #15 cites it as "the confirmed template"; three files under `docs/`. | **keep** (a cited example), or cut and reword the bear-trap: Tony's call |
| D7 `floaty` | **one live user**: `incant/generate:330-334` (`jitPlusEQF code={ floaty += 1.5; }`). generate is reference-only by ruling. | **keep** |
| D7 `layout` (read) | none. Every other `layout` in the forms, fixtures, Directives and tester is the English word, the form file `IncantForms/Windows/layout`, or the field `layoutExample`. The action is from 2026-05-31; the old GUI's layout hook was `onLayout`, dropped by ruling (`IncantForms/Windows/simple:27`). | **cut** |
| D8 `Controls/attributes`, `traits`, `templates` | no loader. Named by `incant/setup:393` (a comment listing absolute paths to remedy), the three forms that include the deleted XML paths, and prose. Nothing includes these three files themselves. | **cut all three** when bigify, db and inspector are ruled; until then they are the only record of the old attribute and template names |

### D3, hexToNumber: the hang, and what it uses

**The hang is kant's, set off by the action's own loop.** Two facts, both measured today:

1. *A string walked to its end never reads false.* `while s; ++s;` over "ff9" takes five turns, not three: after the
   third `++` the field holds an empty string and still reads true; the fourth `++` clears it; a field with no value
   reads as its own tag (bear-trap #26), true again; the fifth `++` refuses ("no value to bump"). So `while target;
   ... ++target;`, hexToNumber's loop, cannot end by itself on today's truth rules.
2. *After that refusal the loop spins.* A refusal in a while body ends the action when the loop's condition is a
   comparison, and never ends it when the condition is a bare field: no body statement runs again and nothing prints.
   **Fixit minted, as the dispatch ruled: `incant/fixits/refusedLoopSpins`** (Clod's lane; it hangs by design and the
   nag's alarm ends it). Cutting or fixing hexToNumber does not retire it.

**The string-pointer operations hexToNumber and setHexColor use, and what each does today:**

| operation | where | today (measured) | covered by a fixture? |
|---|---|---|---|
| `while target;` (true while string is left) | utilities, hexToNumber | reads true one turn too long, then true for ever (fact 1) | none found |
| `++target` (step one character) | hexToNumber | steps: "ff9", "f9", "9", then empty, then no value | none found |
| `target.numbeR` (the character's code) | hexToNumber | **not an accessor today**: `numbeR` is in no registry and no tok source; the read hands back nothing | none; nothing else in the tree spells it |
| `hex + 2` (skip two characters) | setHexColor | **joins**: "abcdef" + 2 reads "abcdef2" (ruled, SEQ 347 R3: a string on the left concatenates) | the concatenation is covered (stringJoinT); the skip no longer exists |
| `hex - 4`, `-= 2` (drop characters from the end) | setHexColor | works: "abcdef" - 4 reads "ab", `-= 2` reads "abcd" | none found |
| `argument&` (unitTests' testPointer) | `incant/unitTests:176` | `&` is registered `opNotBuilt` (`incant/setup:219`) | none |

"None found" is from two greps (`\.numbeR` over the fixtures, tester, the grammars and setup; "string pointer",
"chop", "walks the string" over pop.sh and `incant/pop`): it shows no fixture names these, not that no fixture happens
to step a string.

**Proposal: the fixture first, then the fix.** hexToNumber cannot be made to work by editing hexToNumber alone: it
needs a way to read a character's code (numbeR is gone) and a loop test that ends at the string's end, and both are
kant rulings, not library edits. So: (1) a fixture that pins the string-pointer operations as they read today, one row
each from the table above, with the five-turn walk pinned as read and marked not-blessed; (2) Tony rules what an
exhausted string reads and how a character's code is read; (3) hexToNumber is fixed to the ruled spellings and given
its own row ("ff" reads 255, "ef2b2d" splits to 239 43 45). A unitTest alone (the second option) would exercise the
operations but leave the one real user broken, so it is step 1 of this, not an alternative to it.

### D3, what moved under hexToNumber (Tony: it worked once and has not changed since; history read 2026-11-21)

Its body is the same text as in June but for one respell (`target++` became `++target`, `89be1cb3`, 2026-06-19).
Three things in kant moved under it; two have a commit, one predates the repo.

| what it relies on | what moved | when |
|---|---|---|
| `target.numbeR`, the character's code | the accessor `numbeR=27` is in this repo's history exactly once: in `BackupIncant/setup` at the first commit (`9db8ca6f`, 2026-04-09), a backup directory removed on 2026-04-26. The live setup has never held it in this repo, and today's engine has no case 27 (26 and 28 are there). | **before the repo's first commit**; no commit to name |
| the loop ending when the string is used up | `++` on a field with no value now refuses ("zero is a value, absent is not"), so the walk's last step is a refusal instead of a quiet no-op | `686e202b`, 2026-09-11 |
| setHexColor's `hex + 2`, skip two characters | a string on the left of `+` now joins | `6aa30d81`, 2026-10-12 (SEQ 347 R3) |

Not dated: when a refusal inside a `while` on a bare field began to spin (fixit refusedLoopSpins), and whether the
string walk read false at its end before 2026-09-11. Each needs a build of an older commit, which is a clone outside
Dropbox by the standing rule, so neither was cheap.

---

## M1 -- utilities reordered into the ten families (2026-11-21, SEQ 734 assigned by Clod; branch m1-utilities-families, for Tony's buy)

Moves only. `incant/utilities` is cut into 97 pieces by line range and written back in the order of 1a: within a
family, its fields first (in the order they stood), then its actions (in the order they stood), each header directly
above its own action. No line of any body changed; no comment was rewritten; the foot (the last 13 lines) is untouched.

**The families as built** (file order): tell · printing a field (`listed`; dumpField, flatten, listRules, toXML) ·
JSON (its block, verbatim) · layout (`tARGET dIRECTion newStuff placeReq sfChain fwOk`; fillDownAcross, frameMembers,
placeForm, frameWhole, setFrame, bigifyLayout) · looks and styles (the ten `lk*` `ln*` `rlSays` fields; setLook,
lookFirst, setLookByName, resolveLook, mergeStyles, hexToNumber, setHexColor) · cards (`cpWant cpTab cpTabName
cpHits`; cpBars, cpBar, cpCards, cpOne, cardsPick) · the frame store (`formFrames`; keepFrame) · typesetting (the `ts`
rules and fields; tsFind, tsBoxWarn, typeset) · drawing (`textReq imageReq`; drawWalk, drawText, drawImage, drawFill,
drawBorder, drawKids) · show, redraw, click (`windowReq pageReq showPath showReq ckFn ckNm`; describe, redrawWindow,
redrawForm, showPathRoot, showForm, clickFire, click).

**Where the dead items went** (1a named no family for them; my choice, say if another is wanted): flatten and toXML
with printing a field; bigifyLayout with layout; hexToNumber and setHexColor with looks and styles (colours).

**Headers, matched by what they say.** 29 block headers and 4 one-line `//` notes. Moved to their action: setFrame's
(was 333 lines above it), mergeStyles' (146 above), setLookByName's, cardsPick's, showForm's, click's, typeset's,
placeForm's, fillDownAcross', drawImage's and redrawWindow's (each had fields or other actions between it and its
action).
- **Matches none:** the `quoteIfNeeded` obituary (one `//` line; no such action). Left after `click`, where it stood.
- **Matches a field, not an action:** the `formFrames` header. It sits above `formFrames`.
- **Matches two or more:** the JSON header (the whole rule set: kept above the block, which is verbatim); the typeset
  header (the `ts` grammar and the action: placed above the action, so the grammar now stands above it with no header);
  the cardsPick header (the five `cp` actions: placed above cardsPick, the last of them); the showForm header (it also
  describes the viewer, which is showForm's own code).
- **No header at all:** tsFind, frameWhole, drawFill, drawBorder, drawKids, cpBars, cpBar, cpCards, cpOne, clickFire.

**The proof.**

| check | reads |
|---|---|
| every line, sorted, before and after | identical, 1597 lines each |
| `genLadder/codeOnly.py`, sorted, before and after | identical, 1201 lines each |
| the foot (last 13 lines) | identical, in place |
| `genLadder/pop.sh` | exit 1, **4217 green**, FAIL rows 63, identical by name to `docs/sealCaptures/pop.fails.txt` |
| pop.sh against a run on the unmoved file the same hour | the same but for the tree-status header and one printed memory address (acceptStartT's body address, different every run) |
| `genLadder/formsPop.sh` | **317 green**, F-149 red as banked; its whole output identical to `docs/sealCaptures/formsPop.txt` (0 lines differ) |

Binary: the bare build of 2026-11-20 12:54, 2191072 bytes. Not run: jitLadder, printPop, decodePop, ddPop, frontier,
dirCheck (the dispatch named pop.sh and formsPop.sh as the proof; a buy runs the rest).

---

## What was done with it (2026-11-21, seal 521)

M1 bought (merge `8e00a71b`). Cut, by ruling: D1, D2, setHexColor, D4, D5, D6 and eleven D7 entries (callMyself,
invokeTest, testNegate, testScope, testForC, layout, delimitRecord, commaStuff, jsonFile, winForm, plainField). No
existing fleet row moved. Kept: hexToNumber, testPointer, testNew, floaty. Deferred: D8, with the bigify / db /
inspector ruling. The string-pointer operations are pinned as read in `incant/pop/stringPointerT`; the two rulings
hexToNumber needs are in `Topics/kant`'s docket beside fixit refusedLoopSpins. Line numbers above this section are
those of utilities and unitTests BEFORE M1 and the cuts. Lists 2 and 3 are untouched and still open.
