# The comment trial — tally

**Opened 2026-09-01.** Tony's proposal, Clay's refinements, recorded in `CLAUDE.md` under
*"LONG METHOD COMMENTS GO TO DesignDocs"*. This file is the trial's whole evidence and it retires
with the trial.

## WHAT IS BEING TESTED, in one sentence

That a long method comment can be replaced by **one inline claim plus a `method.slug` key**, with
the argument living in `incant/designDocs` — without anybody losing the argument when they need it.

## ⚠ THE QUESTION THE TALLY ANSWERS, AND IT IS NOT "DID WE WRITE THE ENTRIES"

**Was the pointer ever followed?**

| outcome | what it means | what happens next |
|---|---|---|
| entries written, **lookups zero** | the short line was all anyone needed | **the doc half can go.** Keep the one-liners, drop the ceremony |
| lookups happen and the entry is **there** | the split is working as designed | keep it; consider the dangling-pointer fleet row |
| lookups happen and the entry is **missing** | this is the *"deal with it then"* | **the fleet row earns its place** — log it here, do not stop to build it |

**Both columns are needed.** Entries-written alone measures diligence, not usefulness — and a count
of things produced is exactly the shape of an instrument that cannot fail. Same family as rule H4:
the interesting quantity is the one that can come back zero.

## ENTRIES WRITTEN

| date | key | method / site | why it was long enough to move |
|---|---|---|---|
| 2026-09-01 | `GroupItem.getGuard` | `GroupItem.twk:488` | the getter/setter split: the census that settled Tony's 5 vs Clod's 6, why three of five calls are the method's own recursion, and why the 17× mirror hazard cannot arise here |
| 2026-09-01 | `GroupItem.ensureGuard` | `GroupItem.twk:494` | why `setRuleStuff` stays on line 1, what the split does and does not cure, and where anyone reopening it should start |
| 2026-09-02 | `Instruct.opDot.accessorGate` | `Instruct.rtn` | the jit gate for the whole accessor family, and why finding #3 looked like a condition bug |
| 2026-09-02 | `Instruct.opDot.cases403to404` | `Instruct.rtn` | the guard that dereferenced the pointer it guarded — exit 139, CLAIM KANT-18 |
| 2026-09-02 | `Instruct.opDot.case405firstMember` | `Instruct.rtn` | why `.firsT` returns the ATTRIBUTE, CLAIM KANT-17 |
| 2026-09-02 | `Instruct.opDot.case42hasTraits` | `Instruct.rtn` | why hasTraits is not hasAttributes, and the write halves |
| 2026-09-02 | `Instruct.opDot.case407binType` | `Instruct.rtn` | binType is an enum; why nonzero is the right width |
| 2026-09-02 | `Instruct.opDot.case408isAction` | `Instruct.rtn` | why 406 cannot witness the isCoded → isAction transition |
| 2026-09-02 | `Instruct.opDot.case41hasNewParse` | `Instruct.rtn` | why the read and write halves ship together |
| 2026-09-04 | `Bytecode.interpretBC` | `Bytecode.twk` | the two incant blockers that made the branch inexpressible, and why a plain C++ cursor cures both |
| 2026-09-04 | `Bytecode.runByteFn` | `Bytecode.twk` | why the handler is fired in place, and why a label op's null is a fall-through rather than a refusal |
| 2026-09-04 | `jitEmitters.appendGroupValue` | `jitEmitters.rtn` | why the jitted print cannot reuse the pointer entry, and why the carrier is fresh |
| 2026-09-04 | `jitEmitters.jitAssignNodeRT` | `jitEmitters.rtn` | F-48's ruling, why it lives in assignFieldCore, and the pointer-as-data defect it cured |
| 2026-09-04 | `jitEmitters.jitBindArgRT` | `jitEmitters.rtn` | the runAction gate gap, and why the unwrap is a run-time fact |
| 2026-09-04 | `jitEmitters.jitBindArgRT.argChannel` | `jitEmitters.rtn` | stroke 3's lifted channel lines, and why no restore comes with them |
| 2026-09-04 | `jitEmitters.jitDerefRT` | `jitEmitters.rtn` | why the star is a run-time helper and not an emit-time fold |
| 2026-09-04 | `jitEmitters.jitEmitter` | `jitEmitters.rtn` | why it sets no flag and does not fork on the attribute tag |
| 2026-09-04 | `jitEmitters.jitPrintBegin` | `jitEmitters.rtn` | why there is deliberately no jitPrintEnd |
| 2026-09-04 | `jitEmitters.jitPrintNodeRT` | `jitEmitters.rtn` | why it delegates rather than re-implementing value-versus-tag |
| 2026-09-04 | `jitEmitters.jitSaveFrameRT` | `jitEmitters.rtn` | the frame bracket as measurement not architecture, and why the recursive gate was the defect |
| 2026-09-04 | `measure.addrOf` | `measure.twk` | identity as a small stable integer, and rule H3's argument for why a raw pointer cannot be pinned |
| 2026-09-04 | `measure.auditMissingRules` | `measure.twk` | the isRule-IFF-rStuff biconditional, both direction splits, and why it prints when clean |
| 2026-09-04 | `measure.auditMissingTerms` | `measure.twk` | carries none of its own; records that, and where the family argument lives |
| 2026-09-04 | `measure.auditRStuff` | `measure.twk` | empty parens arrive as an InvokeArg node, and why GroupMain was the wrong home |
| 2026-09-04 | `measure.auditSpurious` | `measure.twk` | carries none of its own; records that, and where the family argument lives |
| 2026-09-04 | `measure.auditUnconsumed` | `measure.twk` | why it is its own check and not left to MISSTERM, with its dated H7 specimen |
| 2026-09-04 | `measure.bodyCensus` | `measure.twk` | why zero pending is a reportable answer rather than a silence |
| 2026-09-04 | `measure.canonOf` | `measure.twk` | why road 1 needed it, and why definingRule() is never tested inline |
| 2026-09-04 | `measure.evictAction` | `measure.twk` | relocate-then-null as structure, and why it refuses rather than substitutes |
| 2026-09-04 | `measure.frameProbe` | `measure.twk` | the handover question it was built to answer, and why it is a separate function |
| 2026-09-04 | `measure.labelMinters` | `measure.twk` | RELOCATED from the Generate node, unchanged, because the method changed file |
| 2026-09-04 | `measure.parseClassify` | `measure.twk` | the two 2026-08-19 defects it would have made visible, and what makes `fires` go stale |
| 2026-09-04 | `measure.probeNode` | `measure.twk` | why it reports pointers and never names |
| 2026-09-04 | `measure.showBody` | `measure.twk` | why incant cannot ask a pointer question, and which copy mechanism it settles |
| 2026-09-04 | `GroupActions.chanReport` | `GroupActions.rtn` | ⚠ did NOT move: it reads `static int` state from `jitContext.h`, so a second TU gets its own zeroed copies |
| 2026-09-04 | `measure.chanReport` | `measure.twk` | ⚠ SUPERSEDES the row above: stroke 10 moved the counters onto GroupRules, so the move became legal and the entry carries why it had not been |
| 2026-09-04 | `genParse.storeBody` | `genParse.rtn` | the corpus's founding invariant -- generation never writes the live slot |
| 2026-09-04 | `genParse.storedBody` | `genParse.rtn` | why the fifth verb was a finding rather than a re-pin of the pre-registered four |
| 2026-09-04 | `genParse.activateBody` | `genParse.rtn` | why it is the only writer of CodE plus isCoded among the corpus verbs |
| 2026-09-04 | `genParse.compileStored` | `genParse.rtn` | phase two under Option B, and why it compiles out of the corpus |
| 2026-09-04 | `genParse.activateAll` | `genParse.rtn` | the no-back-pointer ruling, and why it refuses per entry rather than aborting |
| 2026-09-04 | `genParse.parseRuleMethod` | `genParse.rtn` | the §4.1 binding, definingRule-not-parent as a measured repair, and why both doors move together |
| 2026-09-06 | `GroupActions.saveLocalFields.identityPair` | `GroupActions.rtn` | M2's ruling executed: why the pairing was positional and what the noPrint filter cost. ⚠ **OWED FROM THE SAME DAY'S EARLIER STROKE** — the pointer was written in `1ab282f` and the entry was not |
| 2026-09-06 | `GroupActions.saveLocalFields.frameFloor` | `GroupActions.rtn` | why the bound is not tidiness: 20 fleet rows and five runaways measured its absence. ⚠ **OWED FROM `1ab282f`** |
| 2026-09-06 | `GroupActions.restoreLocalFields.identityPair` | `GroupActions.rtn` | the filter lives in one place now. ⚠ **OWED FROM `1ab282f`** |
| 2026-09-06 | `genParse.recordSite` | `genParse.rtn` | why the emitter and not the installer writes the record — two processes, days apart |
| 2026-09-06 | `genParse.sinkNotTee` | `genParse.rtn` | sink-swap over a fourteen-site tee, and the measured std::cerr-vs-fprintf defect |
| 2026-09-06 | `genParse.oneGate` | `genParse.rtn` | why the attribute is gated and not just the dump, and why the file sink is the only read path |

## ⚠ FIFTH FINDING, 2026-09-06 — THE DANGLING-POINTER ROW WENT 26/26 TO 67/108, AND THREE OF THE GAPS WERE MINE FROM THAT MORNING

The 09-03 sweep earned the dangling-pointer check and left it green at **26/26**. Run again at the
head of the `genParse.rtn` sweep, over every `File.method[.slug]` key in `*.rtn` and `*.twk`:
**41 dangling of 108.**

⚠ **AND THE PROVENANCE IS THE POINT, NOT THE COUNT.** Three of the 41 —
`saveLocalFields.identityPair`, `saveLocalFields.frameFloor`,
`restoreLocalFields.identityPair` — were minted **the same morning**, in `1ab282f`, by the seat
that then ran the census. The argument was not lost (it is in that commit and in
`docs/kantCorpus.md`), so the entries were written from the real reasoning rather than
reconstructed. **But nothing in the process noticed**, which is exactly the failure this file
already names: *"the shortening happens, the entry never does, and the reasoning is deleted."*

**The remaining 38 are reported, not fixed** — they belong to `Instruct.rtn` (20, almost all the
shared `storeRuling` slug), `jitEmitters.rtn` (5), `GroupItem.twk` (6), `ruleActions.rtn` (3) and
`GroupActions.rtn` (4). ⚠ **The `storeRuling` cluster is one decision, not twenty**: it is a
file-scoped slug used at many sites and needs a single entry the way the 09-03 sweep wrote three.

⚠ **THE CHECK ITSELF FAILED TWICE BEFORE IT MEASURED ANYTHING**, and both failures are on this
file's own list. The first cut matched filenames — `Bytecode.h`, `genParse.rtn` — as keys and
reported 54 dangling; the second had to be told that a pointer resolves on its LAST segment, not
its full path. **A census is an instrument (H9): read the hits before reporting the number.**

## ⚠ SIXTH FINDING, 2026-09-06 — THE LINK IS INVISIBLE IN A `/* */` BLOCK, AND THAT IS THE WHOLE COMPLAINT

Tony went back and forth between `genParse.rtn`'s `parseRuleMethod` and its DesignDocs entry and
**could not see the link** — *"I am looking for a `//` link entry left behind that is not there."*

**The link was there.** `genParse.parseRuleMethod` sat on the third line of a `/* */` header. What
was missing was not the key but its CARRIER: measured across the two swept files —

| file | links on `//` lines | links inside `/* */` blocks |
|---|---|---|
| `ruleActions.rtn` (09-03 sweep) | **25** | 11 |
| `genParse.rtn` (before this re-cut) | 3 | **7** |

**A key on a `//` line reads as a link; the same key wrapped in a prose block reads as prose.** So
the convention has a third clause nobody had written down: **the link line is a `//` line**, and a
retained `/* */` block is for site warnings, which are not links.

⚠ **AND THE DISPATCH'S DIAGNOSIS WAS WRONG IN A WAY WORTH RECORDING.** It read the symptom as
key-POSITION — *"the 09-03 template is `// <entryName> <one sentence>`, and stroke 1 dropped the
name off the front"* — and dispatched a flip to name-first. **Measured: the 09-03 sweep is 25
key-at-END and 0 key-at-start, and `CLAUDE.md`'s own documented example
(`// single writer of parentLabel; callee lifts at entry   parseRule.frameLift`) is key-at-end
too.** Executing the flip would have made `genParse.rtn` the only file out of step with both the
template and the written rule, and stroke 2 would have propagated it across 55 methods.

**One grep settled it, and the grep is the point** — this is the unmeasured-citation family
reaching the convention itself. The re-cut moved the links onto `//` lines.

⚠⚠ **AND THEN TONY RULED KEY-FIRST ANYWAY, WHICH IS THE RIGHT OUTCOME AND NOT A CLIMBDOWN.**
The measurement answered *"what does the tree currently do"* and the ruling answered *"what should
it do"*, and those are different questions. **The template is now
`// <entryName> <one sentence>` — entry name FIRST, in column one of the comment, spelled exactly
as the DesignDocs node is tagged, with NO `File.` prefix.** The reason is the one the measurement
could not see: a key at the end of a wrapped sentence is not in a fixed place, so a reader scanning
a file has nowhere to look, while a name in column one is scannable without reading the prose at
all — and `grep '^ *// <name>'` finds it from the file side, exactly as `grep '<name>'` finds the
entry from the doc side. **One token, two directions, both greppable.**

⚠ **SO `CLAUDE.md`'s EXAMPLE AND `ruleActions.rtn`'s 25 LINES ARE NOW THE DIVERGENCE, not this
file.** They are key-at-end with a `File.method.slug` path. Restating the rule and rotating those
25 is owed; it is not done here, and stroke 2 should not assume either form until it is.

## ⚠ SEVENTH FINDING, 2026-09-06 — TWO MORE CLAUSES, BOTH FROM TONY READING THE RESULT

The convention picked up two clauses that only a reader could have found, and neither was in the
written rule.

**ONE PHYSICAL LINE PER LINK, HOWEVER LONG.** Tony re-cut the three `genParse` links himself to
prove it: *"they are one line each (long lines are OK)."* A wrapped link puts the key on line one
and leaves the continuation looking like an orphan comment — and worse, `grep` returns half a
claim. One line means one hit is one whole claim.

**THE ENTRY NAME MUST NOT REPEAT ITS FILE.** *"When I look at genParse.rtn looking for genParse I
get 49 hits."* Measured: **47 hits for `genParse` in `genParse.rtn`, of which 4 are links.** Naming
the entries `genParseRecordSite` / `genParseSinkNotTee` / `genParseOneGate` buried them inside the
noise of the file's own name — the one search a reader would actually type is the one that cannot
find them. Renamed to **`recordSite` / `sinkNotTee` / `oneGate`**, each now a ONE-HIT grep in both
`genParse.rtn` and `incant/designDocs`.

⚠ **THE TEST FOR A SLUG IS THEREFORE NOT UNIQUENESS, IT IS SIGNAL.** `genParseRecordSite` was
perfectly unique and perfectly unfindable. **Grep it in its own file before minting it**; if the
count is not 1, the name is carrying something the path already says.

⚠ **AND THIS IS THE FOURTH CORRECTION TO ONE CONVENTION IN ONE SESSION** — carrier (`//` not
`/* */`), position (name first), line discipline (one line), naming (no file prefix). **Every one
came from Tony trying to READ the result, and none from the seat that wrote it.** That is the
trial's own thesis landing on the trial: the question was never *"were the entries written"*, it
was *"can the pointer be followed"*, and only a reader can answer it. **Stroke 2 opens against a
convention that has now been read.**

## ⚠ EIGHTH FINDING, 2026-09-06 — THE PAYOFF NOBODY HAD WRITTEN DOWN: METHOD NAMES BECOME GREPPABLE

Tony, from using the tree rather than from reasoning about it: *"when searching a code file I have
bumped into the genParse issue a few times, on other names. Method names appearing in comments are
hit multiple times when looking for a method. Moving long comments into DesignDocs should fix much
of that."*

**This is a THIRD argument for the register, independent of the two already on file.** The doc was
built on retrieval-failure (*a fresh paragraph nobody is looking at*) and gained
position-rot at the 09-04 file move (*prose rots by POSITION, a key cannot*). Neither predicted
this one: **long comments make the CODE unsearchable**, because every method named in prose is a
false hit when someone greps for the method itself.

**MEASURED on `genParse.rtn`, counting every hit of every `extern` name in the file and splitting
it by whether the line is code or comment:**

| | name-hits in comments | in code | noise |
|---|---|---|---|
| before stroke 1 | 218 | 187 | **53%** |
| after stroke 1 | 209 | 187 | **52%** |

**More than half of every method-name search in this file lands in prose.** The worst offenders
after stroke 1: `genParse` **40 in comments vs 4 in code**, `emitLeaf` 14 vs 8, `parseRK` 12 vs 4,
`litK` 12 vs 3, `planRule` 10 vs 5.

⚠ **ONE METHOD MOVED IT ONE POINT, AND THAT IS THE ARGUMENT FOR THE SWEEP RATHER THAN AGAINST IT.**
`genParse.rtn` has ~56 methods; stroke 1 did one. The metric is worth reporting per stroke because
it is the first thing the trial measures that a READER feels directly, and unlike entries-written
it can come back zero.

⚠ **TONY'S EXEMPTION, and it keeps the metric honest: a name mention in the comment immediately
before a method declaration is NOT noise.** That is the link line doing its job, adjacent to the
thing it names. So the target is not zero — it is *"the only comment hit for a method name is the
one line above its declaration."*

## ⚠ NINTH FINDING, 2026-09-06 — THREE HEADERS IN ONE FILE, ALL ADRIFT, ALL FOUND BY A SCRIPT

The fourth finding said *prose rots by POSITION, and the register cannot*, on one instance. The
`genParse.rtn` sweep found two more, and the third is the one that makes the argument:

| the header | belongs to | was found at | drift |
|---|---|---|---|
| `parseRuleMethod`, ~50 lines | `parseRuleMethod` | above `parseTermCount` | **234 lines** |
| `dumpRuleTerms`, 34 lines | `dumpRuleTerms` (line 319) | above `locateRule` (line 1115) | **~800 lines** |
| **the FILE header**, 32 lines | `genParse.rtn` itself | line **1012**, between `kantLeaf` and `locateRule` | **~1000 lines, and not at the top at all** |
| `emitLeaf`, 14 lines | `emitLeaf` (line 396) | above `locateManier` (line 975) | **579 lines** |
| `emitMany`, 31 lines | `emitMany` (line 444) | above `locateManier` (line 989) | **545 lines** |
| `dumpSpellings`, 23 lines | `dumpSpellings` (line 367) | above `kantLeaf` (line 808) | **441 lines** |
| `showParse`, 28 lines | `showParse` | above `ruleNameArg` | **99 lines** |
| `spellKant`, 15 lines | `spellKant` | **AFTER** its own method | 16 lines |
| `recordParse`, 20 lines | `recordParse` | **AFTER** its own method | 79 lines |
| **`genParse`, 15 lines** | `genParse` (line 624) | line 1741, **AFTER** its method | **1117 lines** |

⚠ **UPDATED THREE TIMES AS THE SWEEP WENT ON — TEN, NOT THREE, IN ONE FILE.** `emitLeaf` and
`emitMany` were found stacked TOGETHER above a third method's link line, which is the shape to
recognise: **drifted blocks accumulate at whatever declaration they were last sorted against**,
so finding one is a reason to look immediately above and below it rather than to move on.
**That prediction was then confirmed twice**: `dumpSpellings` turned up stacked above `kantLeaf`'s
link line, and `genParse` / `showParse` / `recordParse` turned up stacked THREE DEEP above
`ruleNameArg`'s.

⚠ **AND FOUR OF THE TEN SIT *AFTER* THE METHOD THEY DOCUMENT**, which reading cannot survive at
all: a header below its own function reads as the header of the NEXT one. `genParse`'s own header
was **1117 lines past** `genParse`, describing the two-pass design to a reader standing over
`ruleNameArg`.

⚠ **THE FINAL COUNT IS THE ARGUMENT. TEN HEADERS IN ONE 2900-LINE FILE WERE DOCUMENTING THE WRONG
FUNCTION**, and the file was in daily use throughout. Nobody was careless; prose simply has no
mechanism that objects when it ends up in the wrong place, and a `File.method` key does.

**The file began with `activateAll` and no header whatever.** Anyone opening `genParse.rtn` — to
learn what it is, or to be warned about the three tok traps that each cost a build cycle — saw
none of it.

⚠ **ALL THREE WERE INVISIBLE TO READING AND OBVIOUS TO A SCRIPT.** Nobody noticed in the months
they sat there, and each surfaced within seconds of a cut script looking for the `extern` it
expected to find under a block. **The drift a human notices is the small one**; past a screenful,
a misplaced comment simply reads as a different comment.

⚠⚠ **THE "PROBABLE CAUSE" WAS WRONG AND IS WITHDRAWN — MEASURED 2026-09-08.** This entry said the
09-04 alphabetisation caused the drift: *"a sort moves declarations; a detached block sorts as
whatever it happens to sit above."* **It did not.** The orphan finder, run on the pre-sort file
(`1e17912^`) against the pre-sweep file, reports:

| file | orphans the SORT caused |
|---|---|
| `genParse.rtn` | **0 of 10** |
| `jitEmitters.rtn` | **1** (`jitEmitReturn`, whose method the sort moved past `jitEmitRefusedCheck`) |

Directly, on the worst genParse case: `dumpRuleTerms` was **970 lines from its method BEFORE the
sort and 971 after**, and the file header sat at line 1208 pre-sort. **The sort moved nothing
relative to the drift; it carried block-and-declaration together.**

⚠⚠ **THE CAUSE IS NOW KNOWN, AND IT IS TONY'S HYPOTHESIS, MEASURED — INSERTION, NOT SORTING.**
*"Orphan comments may come about when a method is retired or a new one inserted. In fixit mode a
method can get inserted fast without a careful review of where it goes."*

**Both sorts are exonerated.** The finder was re-run against the base of the REAL 08-15
alphabetical pass — `9c4962b`, the commit that also introduced `alphaLint.sh`; the 09-04 "stroke 6"
commits were a later re-sort:

| base | `genParse.rtn` | `jitEmitters.rtn` |
|---|---|---|
| 08-15 pass (`9c4962b^`) | **0** | 1 |
| 09-04 re-sort (`1e17912^` / `57be920^`) | **0** | 1 |

**And the two-question test closes it.** Every orphan header was born in the SAME COMMIT as its own
method — adjacent at birth. The declaration that ended up beneath it is **younger than the header
in five of five tested**:

| header | born | method that landed beneath it | born | verdict |
|---|---|---|---|---|
| `dumpSpellings` | 07-29 | `kantLeaf` | **08-13** | insertion |
| `emitLeaf` | 07-28 | `locateManier` | **08-01** | insertion |
| `emitMany` | 07-28 | `locateManier` | **08-01** | insertion |
| `dumpRuleTerms` | 07-28 **10:57** | `locateRule` | **07-28 13:38** | insertion, same day |
| `showParse` | 08-06 **10:48** | `ruleNameArg` | **08-06 12:45** | insertion, same day |

**A new method dropped in between a header and its own method, and the header silently became the
new method's.** The two same-day cases needed commit-clock resolution, which is the tell for how
fast this happens — under three hours, twice.

⚠ **SO IT IS A PROCESS FACT, NOT A TOOL FACT.** Headers orphan when methods come and go without
their headers coming and going with them. **No fifth clause is needed, because the convention
already guards both halves** — insertion makes adjacency point at the new method while `CodeSite`
still names the old one, so the lint reads disagreement; retirement leaves a `CodeSite` naming a
method not in the tree, which is the entry-outlives-method check `CodeSite` was put in schema v2
for.

⚠ **AND THE UNIT RULE IS RE-JUSTIFIED ON BETTER GROUND THAN IT WAS ADOPTED ON.** It was argued from
sorting, which was wrong. Its real value is that **an inserted method cannot land between a header
and its declaration when the two are one unit with no blank line between them** — the insertion has
to go above the block or below the body, and both are visibly correct.

⚠ **AND THE UNIT RULE SURVIVES ITS OWN RATIONALE BEING WRONG, which is worth separating.** It was
adopted to stop sorts from orphaning headers; sorts turn out to orphan roughly one header per file,
not ten. It still earns its place — `jitEmitReturn` is exactly the case it prevents, and
`alphaLint` now catches that shape before a sort rather than after — but it is **hygiene, not the
cure for what was actually found.** Whatever produced the other nine is still at large.

**This is the argument for `jitEmitters.rtn`, not just for finishing `genParse.rtn`.** A keyed
entry cannot drift: the key resolves or it does not, and `CodeSite` now makes the reverse
direction checkable too.

## ⚠ TENTH FINDING, 2026-09-07 — THE UNIT RULE, AND IT IS THE CURE THE LINT ONLY DIAGNOSED

Tony, reading the result again: **the top-of-method comment should go with the method if it
moves.** That is the cure. The agreement lint catches drift *after* it happens; making the block
part of the method's unit prevents it.

**Why the ten orphans existed at all:** the 08-15 sort's unit was the DECLARATION, and the comments
above it were not in the unit. So the sort carried bodies and left headers where they sat.

**THE RULE, and it is structural rather than a discipline:**
- **The unit is header + declaration + body. A BLANK LINE IS THE ONLY BOUNDARY.** Block touches
  declaration; blank line above the block. Anything separated by a blank line is not part of the
  method — it is a file-level note or it is noise.
- **Whatever moves methods moves units.** `genLadder/alphaLint.sh` now checks unit shape, because
  alphaLint is what runs before a sort and **a header with a blank line under it is precisely the
  state in which the next sort orphans it.** H7 control: injecting one blank line above `actK`'s
  declaration takes it to `UNIT BROKEN … genParse.rtn: actK`, `1 broken unit(s)`; restored, 0.

**AND THE LINK'S PLACE INSIDE THE BLOCK IS TONY'S, AGAINST THE DISPATCH.** The dispatch put links
FIRST as an index. Tony put them **last, a blank line after the body**, calibrated against how he
writes `opDeref` and `opAssign`: a header leads with **what the method is**, and a list of pointers
is not that.

⚠ **AND HIS ORDERING IMPROVED THE LINES THEMSELVES, which nobody predicted.** At the top a link had
to carry the CLAIM, and it duplicated whatever description sat beside it. At the bottom it becomes
**what you will find if you follow this** — `actionTailShim` went from restating the shim
convention to *"why a shim at all: both spellings of a bare `aCTionBraced()` call are unsound, and
one of them clears the wrong node"*, which tells a reader whether it is worth opening. **A
placement ruling changed what the content should say.**

**tok inertness measured before it was adopted:** `//` inside `/* */` passes through byte-identical
— `genParse.rtn:82` reproduced at `GroupRules.mm:1496`, canary 352 unmoved.

⚠ **AND THE LINT'S FIRST REAL CUSTOMER WAS THIS STROKE'S OWN BULK EDIT.** A script that reshaped
all 28 methods at once reattached every link to the WRONG method — `CodeSite agrees with adjacency
on 14/50`, naming all 36. Reverted, redone one method at a time with indices recomputed per pass,
56/56. **An edit that plausibly succeeded was caught by an instrument that had existed for one
stroke.**

## ⚠ ELEVENTH FINDING, 2026-09-08 — A FOURTH COMMENT SPECIES: THE OBITUARY

`jitBindArgRT` carries three species in one body, which is why it was picked as the second
exemplar, and one of them had no home in the taxonomy.

| species | test | where it goes |
|---|---|---|
| **site warning** | present tense; an editor here can break it | STAYS, in the body |
| **rationale** | present tense; why it is like this | DesignDocs, link at the site |
| **obituary** | **past tense, dated, describes what the code NO LONGER DOES** | DesignDocs **whole**, `Status: superseded <date>`, **and NOTHING at the site** |

**The obituary is the new one.** `jitBindArgRT`'s tripwire block was sixteen lines explaining a
guard that had been deleted three days earlier — why it existed, why it went, and the divergence
its refusal arm had caused. Every verb past tense. **It is worth keeping and it is worth keeping
somewhere a reader of the code will not meet it**, because a reader at the site is looking at what
the code does, and an obituary answers a question they did not ask.

⚠ **AND AN OBITUARY LEAVES NO LINK, WHICH IS WHAT MAKES IT A SPECIES RATHER THAN A LONG
RATIONALE.** The other two both leave something at the site. This one leaves the site clean and
stays reachable from the registry side by `CodeSite` alone. That is a real asymmetry and it is the
thing to rule on.

**What survived at the site was one present-tense line**, and it is the half a reader still needs:
*the pending slot is the emitted path's channel bracket, paired with `jitSaveFrameRT` /
`jitRestoreFrameRT`; it is not the retired tripwire and does not retire with it.* Without that,
deleting the tripwire's neighbour looks safe.

**Body block: 37 lines → 22, comments 19 → 4, code unchanged at 18.**

⚠ **THE DETECTOR NEEDED CALIBRATING AND THE CALIBRATION IS THE DEFINITION.** A first pass matched
`retires with` and flagged the `codedPathHalf` link — which is **live**: the exemption still exists
and the sentence says what will happen to it. Past tense about a *live* thing is not an obituary;
the species is past tense about a thing that is **gone**. Site count with the corrected pattern:
**0**. File-wide it finds **8 more**, which is the population the rest of the sweep will classify.


## LOOKUPS CLOD ACTUALLY MADE

| date | key sought | found? | what it was needed for |
|---|---|---|---|
| 2026-09-04 | `Generate.labelMinters` | **yes** | the cleanup arc was moving `labelMinters` to `measure.twk`, and its argument was already in DesignDocs rather than in the code. The entry was read, relocated whole to `measure.labelMinters`, and nothing had to be reconstructed. ⚠ **Graded honestly: this is a RELOCATION lookup, not a comprehension one.** The pointer was followed because the method changed file, not because a reader needed the argument to decide something. It is the weaker of the two things the trial is measuring, and counting it as the stronger one would be the instrument lying |

## STANDING NOTE — THE FIRST MIGRATION CANDIDATE, IF IT IS EVER TOUCHED

`GroupItem.twk`'s `getRStuff` header is **~55 lines** as of 2026-09-01 and is the largest comment
Clod has written recently: the purity ruling, the deleted-warn history, the C2/C3 graded caller
table, and the complaint recipe. **It is NOT being migrated** — the trial is going-forward only and
that comment is now "existing". It is named here because it is the obvious first candidate the day
anyone edits that function, and because it is a good calibration for the too-short test: the claim
is *"pure getter, does not construct — every bare `.rStuff` read routes here"*, and everything else
under it is argument.



## ⚠ FOURTH FINDING, 2026-09-04 — THE TRIAL SURVIVED A FILE MOVE, WHICH IS THE THING PROSE COMMENTS DO NOT

The cleanup arc moved 30 methods between five files. **A `File.method` key is a TREE PATH, so a
method changing file changes its key** — `Generate.labelMinters` became `measure.labelMinters`,
`GroupActions.chanReport` became `measure.chanReport`. Both were relocated whole, in the same
commit as the code, and the diff shows the move rather than a deletion and a re-creation.

⚠ **The comparison worth drawing is with what happened to the comments that were still IN the
code.** `parseRuleMethod`'s fifty-line header had drifted 234 lines from the method it documents
and was sitting above a different one; the corpus family header named `bodyCensus`, which had
moved to another file entirely. **Neither drift is possible for a keyed entry** — the key either
resolves or it does not.

**So the trial has one measured advantage it was not looking for: prose in a file rots by
POSITION, and the register cannot.** That is separate from the retrieval-failure argument the
register was actually built on.

## ⚠ THIRD FINDING, 2026-09-04 — A METHOD THAT READS A `static` GLOBAL CANNOT LEAVE ITS TU

`chanReport` is a measuring instrument by every other test — registered as an incant command,
reached only from `incant/chanT`, no C++ caller — and it is the one method in the cleanup census
that **cannot** live in `measure.twk`. Its body reads `gChanBinds` and `gChanSame`, which are
`static int` in `jitContext.h` (`:649-650`). A `static` at file scope in a header gives **each
translation unit its own copy**, and the four sites that increment the pair all compile into
`GroupRules.mm`.

**Measured, not reasoned:** moved, retok'd and built, it failed as
`use of undeclared identifier 'gChanBinds'` — because tok only auto-emits `#include "jitContext.h"`
once something it can *see* uses a `jitExterns` type, and the read is inside raw `-% %-`
passthrough. So the compiler refused.

⚠ **THE REFUSAL WAS LUCK, AND THAT IS THE PART TO KEEP.** Had any other moved method used an LLVM
type, tok would have emitted the include, `measure.mm` would have compiled against **its own zeroed
copies**, and `chanReport` would have printed `binds = 0 same = 0` — forever, silently, in the shape
of a real reading. The fleet would have caught it, but only because `pop.sh`'s chanT row asserts a
**non-zero** total; the row's own comment says why (*"0 of 0 is agreement between two absences"*).
A row that only asserted `binds == same` would have gone green on the wrong program.

**The rule: before moving a method across a translation-unit boundary, grep its body for globals and
check their linkage.** `static` in a header means per-TU, and a per-TU counter reads zero.

## ⚠ SECOND FINDING, 2026-09-04 — A CHILDLESS `#):` ABANDONS THE PARSE, AT EXIT 0

**A node written with the has-children terminator `#):` and then given no children kills the
`designDocs` parse** — and it kills it the way the first finding did, with
`RunRulE: expected a method not DisplayDesignHTML`, naming the file's first and perfectly healthy
entry (bear-trap #32's misdirection). `#);` — the leaf terminator — parses fine with identical
prose.

**Measured by bisect, one node at a time against HEAD:** the `Bytecode` and `jitEmitters` nodes
both parse (both have children); the `measure` node, minted childless with `#):`, truncated the
run. One character.

⚠ **AND THE INSTRUMENT IS THE POINT.** `pop.sh` cannot see `designDocs` and read 197 green,
byte-identical, throughout. `genLadder/ddPop.sh` caught it in one run: `ddGate sentinel MISSING`,
`records walked reads ''`, and its own H7 negative control reporting *"stayed GREEN -- the gate
certifies nothing"*. That is rule H12's provenance repeating itself almost verbatim, on the same
file, five days later.

**The cheap discipline: run `ddPop.sh` after ANY `designDocs` edit, not at the end of the arc.**
An entry that parses is not the same fact as a file that parses, and only the second one is
checked.

## ⚠ FIRST FINDING, ON THE FIRST ENTRY — THE REGISTER ALREADY EXISTED

The convention was first written as `method.slug` with entries under a new `MethodNotes` member.
**`TokFiles` was already there** — `TokFiles → Generate → parseAny / parseSetLabel / labelMinters /
runRuleAction / setParse` — and its own text reads *"The comments cluttered up code. Now they do
not. They are here."* Tony had built this register already; the convention is **that register
named**, not a new one.

`MethodNotes` would have been a second population for one subject, which is the duplicate-register
failure `CLAUDE.md` warns about — committed by the seat writing the warning down. It was caught by
reading `designDocs` before writing to it, and only because a **parse failure** forced a second look:
the first attempt used `"..."` strings, which do not carry apostrophes, and died with bear-trap #32's
misdirection — `RunRulE: expected a method not DisplayDesignHTML`, naming the file's first and
perfectly healthy entry.

**Three things the trial learned before its first lookup:** prose entries use the `(…#)` literal,
never a quoted string; the key is the **tree path** `File.method`, because that is what the tree
already is; and **`#` is the only working delimiter** — `docs/forms.md` promised a flexible one and
was corrected on measurement, matrix included. The `Modifier`-set explanation for *why* was raised
and falsified in the same run, so the symptom is recorded and the cause is open.


## THE PRACTICE STROKE — `opDot`, 2026-09-02

**Seven long comments migrated. `opDot` went 130 lines to 85 — 45 lines saved, a 35% cut**, and
every claim an editor at a case site must not miss is still inline.

**Certificate:** fleet **byte-identical row for row**, `oneTest` and `jsonTest` byte-identical on
stdout and stderr, all POPs green, canary 326. Comments cannot change behaviour, so the only way
this breaks is tok choking on one — which fails the build in your face. It didn't.

### ⚠⚠ RATIFIED BY TONY, 2026-09-01 (SEQ 103 Part 1) — THE REVIEW ROW IS CLOSED

Tony reviewed the `Instruct.rtn` / `opDot` migration and the DesignDocs entries it produced.
**Verdict: "Reviewed. Looks good."** Ratified; nothing owed back on it.

**AND THAT SETTLES THE TWO-LINE QUESTION, which the last seal recorded as UNRULED and named as a
blocker on the `ruleActions.rtn` sweep.** The exemplar below took two inline lines for two of the
seven comments, on the ground that a single line could state the fact but not the consequence.
Reviewing the exemplar and approving it approves that. **So the rule is: ONE CLAIM, however many
lines the claim honestly needs — the convention is about moving the ARGUMENT out, not about a line
count.** Two is not a licence for three; the acid test is still the acid test, and both two-liners
here are load-bearing invariants (a segfault and a silent wrong answer).

⚠ ~~**ONE BLOCKER REMAINS ON THE SWEEP.** `docs/commentMinion.md` is signed with schema v2 and
Tony's method-scoped-not-file-scoped amendment, while this exemplar uses `TokFiles`.~~
**CLOSED 2026-09-06, AND IT WAS NEVER THE CONFLICT IT LOOKED LIKE.** Read on the day the sweep
needed it: the 08-17 amendment is about the minion's **work scope** — *"one easy file, one or two
egregiously commented methods inside it"* — not about key nesting; and `commentMinion.md`'s own
head carries a **2026-09-03 supersession** saying the schema-v2 method-scoped FORM below it *"is
not the convention any more — the `opDot` TokFiles entry is."* So the two documents had already
been reconciled by ruling and the row was stale. **A blocker nobody re-read for three weeks.**

⚠ **DATE NOTE:** the nine rows in the table above are stamped `2026-09-01` / `2026-09-02`. The
machine says those entries were all written on **2026-08-31** — see the seal-date drift ledger at
the head of `docs/wakeup.md`, where the same two-day prose drift is measured across six seals. The
rows are **left as written** rather than restated; read `09-02` as `08-31`.

### What resisted the format — one thing, and it is worth knowing before the sweep

⚠ **Two comments could not shrink to one line and were given two**, because the acid test wouldn't
let them: `cases403to404` carries a **segfault** invariant (the `groupList &&` prefix is
load-bearing) and `accessorGate` carries a **silent-wrong-answer** one. A single line could state
the fact but not the *consequence*, and the convention's own test says a line that lets someone
break the invariant without following the key is too short. **Two lines is still one claim** — the
rule is about the argument moving out, not about a line count.

### What went easily

The four enum/flag cases (42, 407, 408, 41) compressed cleanly — each was one distinction wrapped
in six lines of justification, and the distinction *is* the claim.

### The idiom that worked, for whoever sweeps the rest

`//` comments sit safely **immediately above a `case` label** — verified by the build, and worth
recording because bear-trap #4 makes `//` placement a live question and bear-trap #29 makes
comment *position* fatal in an `if`/`or` chain. A switch is not that construct. **The header keeps
its short base description; only the long sections move.** And claims travel to the **case site**
rather than staying in the header, because that is where an editor is standing.

---

## 2026-09-03 — `ruleActions.rtn` sweep (SEQ 150). **1,784 → 1,381 lines.**

**Entries written: 24** (19 new method-scoped, 3 file-scoped for blocks repeated across
methods, 2 retro-fitted for pointers that already existed with no entry).
**Lookups Clod actually made: 2** — `Instruct.opDot` as the template, and the existing
`ruleActions.aCTionIterate.legacyFollow`, which stopped a duplicate being written.

### ⚠ THE TRIAL'S DANGLING-POINTER QUESTION IS ANSWERED, AND THE ANSWER IS YES

This file said the dangling-pointer fleet row was *"obviously buildable"* and would **wait for
evidence it is needed**. The evidence arrived the first time anyone looked: a one-line check over
the file's own keys found **two pointers whose entries were never written** —
`ruleActions.aCTionDefinE.argumentHasData` and `.embeddedRuleCopy`, both minted in the
2026-09-01 first pass.

⚠ **AND THE COST IS NOT "A MISSING FILE" — IT IS THAT THE ARGUMENT IS GONE.** The blocks were
shortened to pointers and the long text they replaced was never banked anywhere. What survives is
the claim on the pointer line and whatever is in git history before that pass. Both entries were
written as **honest gaps** rather than reconstructed, because a plausible rewrite would be
indistinguishable from the original and worth less than the admission.

**So the failure mode is worse than the trial anticipated.** The doc framed the risk as *a reader
follows a pointer and finds nothing*. The real risk is *the shortening happens, the entry never
does, and the reasoning is deleted* — and nothing in the process notices, because the code still
compiles and the fleet still passes.

**The row is earned.** The check is one loop over `grep -o 'File\.method\.slug'` against
`^ *slug=(` in `incant/designDocs`, it ran green at **26/26** at the end of this sweep, and it
would have gone red on the day those two were minted.
