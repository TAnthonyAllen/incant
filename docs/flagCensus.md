# The kant flaG census (SEQ 265 R4, revised by SEQ 266 R1) -- 2026-10-02, read-only

**Subject:** kant's generic flag, GroupFields case 12 (`flaG`), read by opDot case 12 and written by opSetFlag
case 12 (Instruct.rtn). The engine's own fLAG meanings A-D are NOT in scope (held for step 1). Nothing respelled.

## 1. The census

**Population, and why it would hold every use:** an exact, case-sensitive grep for `flaG` over `incant/`,
`IncantForms/`, `genLadder/`, `jitLadder/`, `Tests/`. Case 12 is reachable from kant only through a GroupFields entry
whose gCount is 12, and `flaG=12` is the only `=12;` entry in `incant/setup`. Every kant read (`x.flaG`) and every set
(`x :. flaG`) therefore spells that token. The search also ran for `fLAG`; its hits are all prose about the engine bit.

| # | file:line | set / read | what the marker does | fit to the pROPERTIEs marker |
|---|---|---|---|---|
| 1 | `incant/setup:259` `flaG=12;` | registration | names case 12 for kant | **retires with case 12** |
| 2 | `IncantForms/BackupXML/setup:185` `flaG;` | registration (backup copy) | none; a stale copy of setup | **unused, delete** (or leave; it is a backup) |
| 3 | `incant/probes/flagPlusPlus:13` `pfX :. flaG;` | set | F-131's exhibit: sets the bit that steers `++` | **retires with case 12**: it exists to show the defect retirement cures |
| 4 | `incant/designDocs:233-238` | prose | describes compileRules' visited mark (row 5) | text only: update or trim when Tony rules |
| 5 | *(historical)* `IncantForms/WorkingOn/parser` compileRules, `argument :. flaG;` / `if flaG; return;` | set + read | a **visited mark** that stopped a four-rule cycle | **gone**: added `cf14246` (2026-09-11), removed by Tony in `5f24cf3` (2026-09-14). The attribute form expresses it: `argument +% visitMark;` / `if argument["visitMark"]; return;` |

**Live kant uses of case 12 today: zero.** Rows 1-4 are a registration, a backup, a defect exhibit and prose. The one
real use (row 5) is already gone. **No use the attribute form cannot express** was found. Row 5's set, test-at-entry
and early return map one-for-one onto `+%`, a subscript test and (if wanted) `-=`.

## 2. The candidate, probed (incant/probes/markerCandidate)

`pfMark noPrint;` defined into pROPERTIEs. Set with `pfF +% pfMark;`, tested `pfF["pfMark"]`, tossed `pfF -= pfMark;`.
The control is `pfBare` (same, no noPrint) on a twin field. Exit 0, sentinel reached, trunk `b95a10f` bare.

| question | result | evidence |
|---|---|---|
| defines, carries noPrint | yes | MC-0 1, MC-0n 1 |
| set + test by subscript | works | MC-1 1 |
| **survives a toss** | **no** -- gone, listLengtH back to 0; the pROPERTIEs definition itself survives | MC-6 0, MC-6b len 0, MC-6c 1 |
| **prints** | **yes** -- dumpContents shows `pfMark attribute noPrint`; printDefinition prints `pfF=5 pfMark;` | MC-4 dumps; printDefinition variant |
| **plain attribute walkers count it** | **yes** -- listLengtH 1, a `for` walk 1 | MC-2, MC-5 |
| **testAttributes' noPrint skip** | **skipped by construction**: the skip reads the attribute's own noPrint, which the marker carries. ⚠ The run is **VOID**: the non-noPrint control rule parsed too (MC-7c 1), so parse outcome cannot discriminate. A count of parse calls would. | MC-7 1, MC-7c 1 |
| **reads as a trait** | **no** -- hasTraitS 0, control 1, and still 0 after the toss | MC-3, MC-6b |
| **lands in a frame** | **no, structurally**: saveLocalFields takes `(isArgument or isLocal) and !noPrint`, and the entry clear needs isLocal. The marker is neither, and noPrint besides. Attached to an action it survives the call (MC-8 1, visible inside: MC-F1 1). ⚠ That row cannot discriminate, because a non-local bare attribute would survive too. | MC-8, MC-F1 |

**Of noPrint's five meanings it picks up: not-a-trait (yes), not-a-frame-slot (yes, doubly), skipped by
noPrint-gated walkers such as testAttributes (yes, by construction). It does NOT pick up print suppression on the two
print commands kant has (dumpContents, printDefinition).** "Fires at define, not added" does not arise: the marker is
added, and `noPrint` on its define line is the flag attribute doing its usual job. **And ungated walkers
(listLengtH, `for`) count it**, so while a marker is attached it is visible to any count the field's owner takes.
That is the cost of an attribute over a bit: a bit lives off the list.

**RULED 2026-10-02 (SEQ 267): case 12 RETIRED.** The registration (setup, BackupXML) and both case-12 arms are cut;
`x :. flaG` refuses by name. F-131 closed by construction (fleet: incant/pop/flagRetiredT). The pROPERTIEs noPrint
marker is the sanctioned use-then-toss form, with the two caveats above (DesignDocs `Instruct.opSetFlag.notAFlag`).
