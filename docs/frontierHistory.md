# incant/frontier -- THE RETIRED REASONING TRAIL

**HISTORICAL. Not the live record.** Split out of `incant/frontier` on 2026-08-23 on Tony's
offline report: the analysis had grown to ~440 lines of chronological prose below `stop();`,
newest pass on top, and reading a station's meaning meant scrolling back and forth between the
prose and the station code.

**Where the live material went, and nothing was deleted:**

| what | now lives in |
|---|---|
| what each station MEANS, its standing defect, the workaround, whether a fix is owed, and Tony's verdict | `incant/designDocs` -> `FrontierStations`, one entry per station, eight named attributes each |
| the shorthand ids the analysis leans on -- `bt32`, `bt34`, `bt35`, `bt37`, `H2`, `H4`, `H7`, `RulingA/D/E`, `F31` | `incant/designDocs` -> `Shorthand` |
| looking either of those up | `incant/lookup` -- edit the lookup line at the foot and run |
| what the file IS, how to drive it in Xcode, why every station prints, and the current reading of record | `incant/frontier` itself, which is now ~130 lines of prose instead of 440 |

**The passes below are kept verbatim, newest first.** They record what was believed at each seal,
including the readings that were later withdrawn or inverted -- which is the point of keeping them.
A provenance naming a superseded reading records *what was run*, so rewriting it would falsify the
record. Read them as history; read `FrontierStations` for what is true now.

---

## THE 2026-08-22 RESTRUCTURE, THE FLAG-TEST NOTE, THE if/else NOTE, AND STATION 8

Moved out of `incant/frontier` 2026-08-23. The LESSONS are live in `incant/designDocs` ->
`FrontierStations` (`FS2`, `FS3`, `FS4`, `FSflagTest`, `FSifElse`, `FS9`); this is the narrative
they were extracted from.

```
THE 2026-08-22 RESTRUCTURE, AND WHY THE STATIONS MOVED

Three changes, all ruled by Clay on Tony's 2026-08-22 offline report. Each one
closes a defect that had been producing readings nobody could trust.

ONE. THE TWIN IS MINTED BEFORE ANYTHING IS HUNG ON THE LIVE RULE. Stations 2
and 3 swapped. The old order hung a StorE on the live Braced at station 2 and
only then copied that rule at station 3, so the twin was BORN carrying a StorE
and station 4 hung a second one. Two StorE entries and no CodE is what compile
was being handed. That was an ordering artifact of this file, not a substrate
defect, and swapping the stations removes it at the source rather than cleaning
up after it.

TWO. THE INSTALL GOES THROUGH activateBody, AND THE FLAG IS NOT SET BY HAND.
Station 4 used frHang plus `frTwin :. isCodeD`, which attaches an attribute
still tagged StorE and then asserts codedness separately. But isCoded IS
actionType == 2 (GroupBody.h:75), and the two shipped verbs -- activateBody
(GroupRules.mm:1893-1898) and compileStored (:2586-2591) -- both set it as the
last of the same three lines that mint the CodE: copyOf the stored body, retag
it CodE, noPrint it, attach it, actionType = 2. Hand-setting the flag put the
claim and the artifact on two channels that could disagree, and they did: the
flag said coded and there was no CodE to compile. Now the flag and the artifact
come from the same three lines, so they cannot.

THREE. NOTHING RULE-SHAPED IS TRUTH-TESTED WITH `if`, ANYWHERE IN THIS FILE.
This is the big one and it is the reason the old station 4 "failure" was a
ghost. `aCTionIF` evaluates a condition by CALLING the condition node's gMethod
(GroupRules.mm:857, behind the isMethod(instructType) gate). instructType and
gMethod both live in groupBody, and copyOf copies the groupBody wholesale --
so a twin of Braced carries aCTionBraced, and `if frTwin;` RUNS IT.
aCTionBraced (GroupRules.mm:136) is four lines: it clears its input and sets
the node's group to ExpressioN. So the old station 3 gutted the twin while
testing that the twin existed, and station 4 then failed to install onto a
node with no list. The 2026-08-21 seal's front question -- "what does install
require that a copyOf twin lacks?" -- had the answer NOTHING. Station 4 was
reading a corpse station 3 had made.

It is not a frontier-only hazard. It took this session's own probe: a bare
`if <returned rule>;` fired the action and wiped the CodE that had just been
attached to it, and the probe then reported, correctly and uselessly, that no
CodE was there. Any measurement that truth-tests a rule-shaped value is
reading through a corrupting instrument.

So every station now asserts on an artifact a fired action CANNOT FAKE:
groupList length, and the presence of a CodE or a BlocK reached by subscript.
A cleared node has length zero, so a station that fires its own subject fails
loudly instead of passing quietly. Bare calls are used where the return value
would be rule-shaped -- activateBody and compile are called for effect and
their returns are deliberately not tested, because both hand back the rule.

This restriction lifts when the gMethod move lands (rule actions relocate to
rStuff.actionMethod, vacated gMethod reverts to the structural default). Until
then it is absolute.

AND WHY THE FLAG IS TESTED AS `frOk == 1` AND NEVER AS `if frOk`

Measured here, on this file, on its first run. `if frOk;` on a DECLARED field
tests that the field EXISTS, which is always true -- so station 4 printed its
PASS line and its FAIL line together, and stations 1 to 3 had been printing
PASS whether or not they had earned it. The instrument was void in exactly the
way it was built to prevent, and it was caught only because station 4 failed
loudly enough to print both halves.

That is bear-trap 26's family: existence and value are different questions, and
`if x;` answers the first. For a lookup that can return null -- frCode, frBlock,
frArt, frFire -- `if x;` is the RIGHT test and is kept, because those are not
rule-shaped and firing is not a risk. For a numeric flag it is always wrong.
Both forms appear in this file on purpose.

A NOTE ON THE if/else SHAPE USED THROUGHOUT

Every station reads a flag and then tests it twice rather than using if/else.
That is not style. Measured 2026-08-21 while building this file: a
multi-statement indented if-arm followed by an else BREAKS THE PARSE, and it
breaks it silently at define time -- the whole define block fails and the run
reports "RunRulE: expected a method not <first action>", which names the first
action in the file rather than the offending one. Two controls passed in the
same probe: a multi-statement indented arm with NO else is fine, and a
single-statement if with an else is fine. Only the combination fails.
So: frOk = 0, set it, then two separate ifs.

WHAT STATION 8 ACTUALLY DOES

Braced fires when a bracket expression is parsed. So the trigger is a small
body containing one -- frSample[width] = 251 -- compiled after the artifact has
been commissioned onto the live Braced. If the commissioned artifact executes,
the marker prints. The bracket-expression driver is borrowed from
incant/bindSeamA, which drives Braced the same way and is already in the fleet.
```

---

WHERE THE EDGE WAS, 2026-08-22 FOURTH PASS -- CONVERTED TO DIRECT SUBSCRIPTS

Stations 1 to 8 PASS on values. Station 9 never ran. Read the three boxes
below before the banner, because the banner is wrong and says so here.

⚠ THE CONVERSION, AND WHY EVERY EARLIER READING OFF THIS FILE IS SUSPECT.
`<-` HANDS BACK A COPY. Measured with pointers: canonOf on a direct subscript
reports face==canon, SAME NODE, twice; canonOf on a `<-` local reports a third
pointer, DIFFERENT NODES. A copy answers every READ correctly -- same tag,
flags, list, definingRule -- and diverges only on MUTATION, where the write
lands on the copy and every read-back off that copy CONFIRMS IT.

So stations 2 to 7 were interrogating an impostor. The file now MUTATES THE
REAL NODE (`Grokking["Braced"] +% ...`, `setParse(Grokking["Braced"])`) and
READS THROUGH A FRESH CAPTURE (`frLive <- Grokking["Braced"]` immediately
before each read). Both halves are necessary: a chained subscript in a READ
position is unreliable -- `frLiveLen = Grokking["Braced"].listLengtH;`
returned the string `xlInSet` -- which is bear-trap #35 widened from print
position to assignment position, measured here on the first conversion attempt.

⚠ STATION 7 IS RECLASSIFIED: INSTRUMENT, NOT SYSTEM. It stood red for a day
reading `PC none` and `actionMethod 0`, and that was the copy. On the real node
it reads `PC parseRule Braced` and `actionMethod 1` and PASSES. There was never
a binding defect. The same correction retires findings 2 and 3 entirely, and
Ruling E resolves to its simplest form: bind the node, not a copy -- the fork's
node is the ordinary catalog node, reachable by subscript, no carrier needed.

⚠⚠ BOX ONE -- #37 IS **NOT** CONFIRMED CURED. ITS RETIREMENT CLAUSE DOES NOT
FIRE. Station 6's verdict was moved back INLINE for exactly this test, because
the relocation to frVerdict6 was #37's workaround and restoring it is the only
honest check. Containment landed at parseRule's fire site and the decisive
probe proves it works THERE. Station 6's verdict still does not print:

    STATION 6 BlocK harvested 1 -- CodE harvested 1 -- isActioN reads back 1
    <no verdict line>
    ANCHOR frontier station 7 ...

The marker fires mid-station and the block still loses its tail, so the
artifact is reaching a fire site containment does not cover. parseRule is not
the only door. NOT chased, NOT repaired -- the row stays standing and the next
task is to find the second door.

⚠⚠ BOX TWO -- STATION 9 NEVER RAN, AND THE BANNER LIES ABOUT IT.

    987654 ERROR processCode: frStation9 parse failed
        failed at :reached end of input
        on line 5
    === FRONTIER: all nine stations PASSED. ===

Line 5 is `frHang(Grokking["QuotE"]);` -- A BRACKET EXPRESSION. By then Braced
is commissioned and bound, so that bracket routes to the artifact, and this
file's marker body is a STUB: it writes a witness and returns, it does not
match leftBrace/ExpressioN/rightBrace. A bound parse method REPLACES the
interpretive walk, so once the stub is live every later bracket in this file's
own source fails to parse -- including the one station 9 needs to build its
trigger.

That is the staging hazard in its sharpest form: COMMISSIONING A STUB ONTO A
LIVE GRAMMAR RULE BREAKS THE PARSER FOR EVERYTHING WRITTEN AFTER IT. The
mechanism is fine -- minionWork/probeDecisiveV2 runs the same pipeline green
with the genParse-shaped body `{ if leftBrace() AND ExpressioN() AND
rightBrace(); ... return runRuleAction(this); }` and reads trigger parsed 1,
witness 987654, exit 0. The frontier's body is the wrong body.

⚠ AND THE BANNER HOLE IS A REAL DEFECT IN THIS FILE, recorded not fixed: a
station whose BODY FAILS TO PARSE never runs, never sets frDead, and the foot
prints "all nine stations PASSED". frDead only ever rises from a station that
RAN. H2 exactly -- the completeness assertion cannot see a section that was
never reached. No repair on sight; it comes home.

WHERE THE EDGE WAS, 2026-08-22 THIRD PASS -- BINDING ATTEMPTED, TWO FINDINGS

Station 7 is new: it applies the napalm pattern's binding clause by calling
setParse on the live rule. The frontier now dies THERE, and the reason is a
measured defect rather than a missing piece.

⚠⚠ FINDING ONE IS WITHDRAWN, 2026-08-22, AND THE WITHDRAWAL IS THE FINDING.
It was a MISATTRIBUTED READING, and it was mine. The claim below says
"measured on a PRISTINE Braced". It was not. The `PC parseRule` half came
from a pristine bind; the `hasActioN 0` half came from a DIFFERENT POINT IN
THE SAME RUN, after commissioning. Two readings from two states, reported as
one measurement on one state.

Re-measured cleanly with canonOf's build, pristine face, treatment in between:

    face hasActioN BEFORE setParse   0
    face hasActioN AFTER  setParse   1

So `actionMethod = method` WORKS. setParse moves the action exactly as
designed, on the node it is handed. There is no finding one.

⚠ AND WHAT IT COST IS THE POINT: a ruling was issued on it. Finding one was
reclassified as "design correct, mechanics fail" and a probe was chartered
against mechanics that were never failing. The defect was in the report, not
the code, and nothing downstream could have caught it -- which is why the
citation discipline says re-measure a number before you reason on top of it,
and why a reading assembled from two points in a run is not one reading.

WHERE FINDINGS ONE AND THREE WENT: they are ONE finding, and it is three.

    pristine Braced      setParse -> PC parseRule,  hasActioN 1
    commissioned Braced  setParse -> PC none,       hasActioN 0

COMMISSIONING BREAKS setParse. That is the whole of it, and it now also
carries what used to be finding one's evidence. Station 7 fails on the
commissioned rule and is correct to. Finding two -- the fork reading null --
may be downstream of the same cause, since a rule that never bound has
nothing for the fork to read; that is NOT established and is not claimed.

THE SUPERSEDED CLAIM, kept because the record should show what was believed:

FINDING ONE (WITHDRAWN) -- setParse BINDS THE PARSE METHOD BUT DOES NOT MOVE THE ACTION.
`setParse` (Generate.rtn:367) opens its bind block with `actionMethod =
method;`, which is Ruling B's gMethod-to-actionMethod move, already shipping.
It does not take. Measured on a PRISTINE Braced, so nothing the crucible did
is responsible:

    setParse(Braced)  ->  parseClassify prints  PC parseRule Braced
                          hasActioN still reads 0

The parse method binds; the action does not move. Station 7 fails on exactly
that read, which is what a station is for.

FINDING TWO -- AND IT IS THE BIGGER ONE: BINDING THE REGISTRY RULE DOES NOT
REACH THE NODE THE PARSE ACTUALLY CONSULTS. Measured with the seam probe that
already lives in GroupItem.twk:1310, armed by registering `traceParse` as a
command (the extern was already in the binary; no rebuild). During the
trigger parse:

    SEAM fork  Braced  this=0x104eef4c0  thisRStuff=0x104ef0630
               definer=0x104eec5c0  defStuff=0x104eed3f0  defParseMethod=0x0

Read it left to right. The fork FIRES, so the parse reaches Braced -- Q1 is
now answered by a trace and no longer by inference. `this` is the TERM node.
`definer` is a DIFFERENT node. And the fork reads `defStuff->parseMethod` and
finds NULL -- after a setParse that reported PC parseRule Braced.

We bound the registry rule. The walk consults the definer of the term that
REFERENCES it. Those are different nodes with different rStuff, so the
binding lands somewhere the parse never looks.

⚠ THIS IS NOT NEW AND IT IS NOT A CODING DECISION. RuleStuff.mm:520-527
records it as an OPEN question in exactly these words: "parseMethod lives on
rStuff, and rStuff is PER NODE: the term has its own, separate from the
registry rule's. So binding a rule's parseMethod does NOT reach the term
nodes that reference it, and a converted rule would be used when invoked BY
NAME but not when referenced from another rule." It is marked Tony's and
Clay's call. The crucible has now walked into it from the other side and
measured it on a live trigger parse.

So the binding clause is NOT buildable as "call setParse on the rule". What
it needs is a ruling on which node carries the binding, and that ruling is
the open question above. Nothing further is built here.

FINDING THREE -- OBSERVED, NOT DIAGNOSED, AND RECORDED THAT WAY ON PURPOSE.
setParse's classification DIFFERS between a pristine and a commissioned rule:

    pristine Braced      setParse -> PC parseRule Braced
    commissioned Braced  setParse -> PC none Braced

Station 7 prints the second. `none` is parseClassify's arm for "rStuff
exists and parseMethod is null", so the bind block either did not run or ran
and assigned nothing -- and by inspection it has an `else` fallback, so
"assigned nothing" should not be reachable. That is as far as measurement
goes today. No mechanism is offered here, because the last four times a
mechanism was reasoned out on this project rather than run, it was wrong.

⚠ For the record, measured and NOT assumed: even with the bind in place on
the registry rule and isActioN set, the trigger still leaves the witness at
0. Both findings are live at once; closing finding one would not by itself
move station 9.

WHERE THE EDGE WAS, 2026-08-22 SECOND PASS -- ACTIVATION LIVE, INSTRUMENT HONEST

Stations 1 to 7 PASS on values. Station 6 now verifies that isActioN actually
TOOK rather than that frArt existed, and it reads back 1, because opSetFlag
gained its isActioN case the same day -- before that, `:. isActioN` printed
"no case yet -- gCount 408", did nothing, and the station reported PASS
anyway. That was the station claiming more than it verified, and it is the
reason the hardening was ruled.

STATION 8 SAYS NO, AND THAT IS THE READING OF RECORD. The trigger PARSES
(1), and the witness reads 0 where it must read 987654. So the artifact is
commissioned onto the live rule -- BlocK copied, isActioN verified set,
corpus reporting commissioned 1 stray 0 -- and it DOES NOT EXECUTE when a
bracket expression is parsed. A third piece is missing between activation
and execution, and the frontier has located it on a Braced specimen, as a
measured NO rather than a SIGSEGV in the tokenizer. That is the file working
as designed.

⚠ THE WITNESS IS WHY THAT SENTENCE CAN BE WRITTEN AT ALL. Until this pass
station 8 asserted only that the trigger parsed and left the marker to the
operator's eye -- and the run ended "all eight stations ran", which READS as
success over a NO verdict. The marker did print, twice, at stations 5 and 6,
so an eye scanning for 987654 found it and would have called it green. It
was never station 8's marker. The witness field is set by the generated body
itself and zeroed immediately before the trigger fires, so it can only carry
the marker value if the artifact executed AT STATION 8. Headline-count as
camouflage, inside the instrument built to prevent it.

⚠⚠ AND WHY THERE IS A frVerdict6 SITTING OUTSIDE STATION 6 -- A FINDING, NOT
A STYLE CHOICE. A COMMISSIONED ARTIFACT'S `return` TERMINATES THE BLOCK THAT
FIRED IT.

The generated body ends `return runRuleAction(this);`, as every generated
body does. Once the artifact is live on Braced, something in station 6's own
harvest fires it -- the marker prints mid-station -- and its return
propagates OUT, so every statement after that point in frStation6 is never
executed. Not a parse truncation: the statements are in the block and the
block stops running.

MEASURED, by removing only the return tail from the generated body:

    with `return runRuleAction(this);`     station 6 prints its values, then
                                           NOTHING -- no checkpoints, no
                                           verdict, no frDead
    without it                             checkpoints and verdict all print

Two controls ruled out first, so the cause is not guessed: the
multi-statement indented arm was replaced with two single-statement ifs (no
change), and the dot read on the commissioned rule was removed entirely (no
change, and the marker still fired).

This is the one-channel-one-meaning family again -- a return signal that
means "leave the artifact" is read as "leave the enclosing block" -- and it
is NOT repaired here, because repairing it is a ruling, not a fix. What the
file does instead is refuse to let the defect silence a verdict: station 6
captures its values and frVerdict6 evaluates them one statement later, in a
block the artifact cannot unwind. The assertion is unchanged; only its seat
moved.

⚠ Note the interaction to watch: this same return-propagation is a candidate
for station 8's NO and has NOT been shown to be its cause. Station 8 reads
NO with the return tail present AND absent, so the two are separate
findings until something says otherwise.

WHERE THE EDGE WAS, 2026-08-22 FIRST PASS -- AFTER THE RESTRUCTURE

Stations 1 to 4 PASS with real values: live and twin both read list length 3
at the mint, the live rule goes 3 -> 4 when the body is hung, the twin goes
3 -> 4 when activateBody installs, and the CodE reads back in full. The two
StorE entries are gone and there is exactly one CodE.

STATION 5 IS THE EDGE, AND IT GETS FURTHER THAN ANYTHING HAS BEFORE. compile
on the twin now reaches the body and RUNS IT -- the marker 987654 prints,
which is the first time a generated body has executed in this pipeline. It
then dies on the body's LAST statement, `return runRuleAction(this)`, with a
null dereference at GroupRules.mm:12411 (Generate.rtn:291):

    RuleStuff *ruleStuff = field->rStuff;
    if ( ruleStuff->label )          <-- rStuff is null, this is the crash

`this` is the twin, and a copyOf twin HAS NO rStuff -- copyOf copies the
groupBody and the list, and rStuff is a GroupItem member, so it is neither.
That is now doctrine rather than a gap (Ruling A, 2026-08-22: a twin is a
specimen, not an organism, and nothing re-arms one by copying rStuff). But
every generated body ends in runRuleAction(this), so the inert-twin ruling
and this unguarded read are in direct collision: the ruling says a twin has
no action to run, and the code cannot survive asking.

⚠ SO STATION 5 CURRENTLY EXITS 139 AND ITS FAIL LINE NEVER PRINTS. That
breaks this file's own promise that the failing verdict is the last thing on
screen. It is recorded here rather than worked around, because the fix is a
guard in runRuleAction and that is C++, gated on a build.

A KNOWN BLOCKER SITTING AT STATION 6

`frSubject :. isActioN` has no case in opSetFlag -- it prints "groupField
isActioN has no case yet -- gCount 408" and does nothing. Station 6 will need
another route to the isAction half. Recorded at the 2026-08-21 seal as a
blocker-in-waiting; it is not paid yet and this file does not pretend it is.
