# C-155 — `groupDirectives` CULL

**Ruled by Tony, executed 2026-09-04. `groupDirectives` is untracked and gitignored, so
there is no git archive of it and no commit of the file itself. THIS REPORT IS THE ONLY
RECORD OF WHAT WAS CUT, and every removed entry rides in it verbatim (§4).**

| | |
|---|---|
| file before | 359 lines, 70 entries, 9 armed, md5 `4f14022bc4ed12f07c15cbd54070afca` |
| file after | 278 lines, 46 entries, 6 armed, md5 `7ae5e649ebdcf8276fc89b6ba186637a` |
| cut | **24 entries** — 16 FUNCTION GONE, 8 ANCHOR GONE (3 of them ARMED) |
| kept and listed for Tony | 17 AMBIGUOUS, 3 SHADOWED (see §5 — and §5a, a charter deviation) |
| pre-cut backup | `scratchpad/groupDirectives.pre-C155` (session-local, not durable) |

---

## §1 The file's grammar, measured not assumed

`parts.g:104`, with the keyword bin at `keywords.g:85`:

```
DebugDirective : '#'! Comment? method=Name body=CodeMatch? locate=Directives?
                 active='active'? code='#;'}
Directives     : before | ending | starting | within
```

Four facts follow, and all four are load-bearing for the census.

**Arming is the literal token `active`.** `DebugDirectiveTawkAct` (`Tawk.twk:4418`) opens
`if active` and does nothing at all otherwise, so the house convention of dropping the
leading `a` to give `ctive` parks an entry by making the token fail to match. A disarmed
entry is never resolved, never attached, and never diagnosed.

**The anchor is a PREFIX test against source text at a statement point.** `Tawk.twk:1147`
and `:2723` both run `strncmp(codeMatch, pointInCode.itemStart, strlen(codeMatch))`, at
if-statements and at every ordinary statement respectively. So an anchor is matched against
the `.twk`/`.rtn`, never the `.mm` — which is why this census resolves against source.

**Section scoping is real.** `currentType.getMethod(text)` falls back to
`findGlobalMethod` only when `currentType.isGlobal` (`Tawk.twk:4436`), so a global function
named under a class section is not found at all. Two entries were graded on this.

**One directives file, positionally.** `Tok.C:55` is `if (argc == 3) directivesFile = argv[2];`
and nothing else ever assigns it.

## §2 The resolver certifies itself (Step 2)

Driven on a name known retired in full and a name known live, plus three shape controls.
All five grade differently, so the instrument discriminates:

```
 ln sec         method               anchor               loc       arm    n  grade
  2 globals     tokenize             None                 starting  ARM    0  FUNCTION GONE
  5 globals     compile              endCompile           None      ARM    1  RESOLVES
  8 globals     compile              zzzNoSuchAnchor      None      ARM    0  ANCHOR GONE
 11 globals     compile              if                   before    ARM    4  AMBIGUOUS
 15 GroupItem   listenTo             ending               -         ARM    0  FUNCTION GONE  (global named in a class section)
```

**And a second, stronger certification fell out of the diagnostic retok: the resolver's
grade predicted injection on all nine armed entries, with no exceptions.** Every entry
graded RESOLVES or AMBIGUOUS injected into the `.mm`; every entry graded ANCHOR GONE
injected nothing. The resolver and the generated code agree completely.

## §3 The census — all 70 entries, pre-cut

`n` is the number of source sites the anchor prefix-matches inside the resolved function.

```
  ln sec         method               anchor               loc       arm    n  grade
  14 globals     aCTionDebuG          debugged             None      -      0  FUNCTION GONE
  17 globals     aCTionDebuG          subrule.debugged     None      -      0  FUNCTION GONE
  20 globals     aCTionDebuG          embed.debugged       None      -      0  FUNCTION GONE
  23 globals     aCTionDefinE         if Attributes        before    -      1  RESOLVES
  26 globals     aCTionElsE           if                   None      -      0  FUNCTION GONE
  29 globals     aCTionExpressioN     while                before    -      0  ANCHOR GONE
  32 globals     aCTionNamE           None                 starting  -      0  RESOLVES
  35 globals     aCTionRunRulE        if                   within    -      9  AMBIGUOUS
  38 globals     aCTionSearch         cout                 None      -      3  AMBIGUOUS
  41 globals     aCTionXpress         result               before    -      0  ANCHOR GONE
  44 globals     compile              if                   before    -      4  AMBIGUOUS
  63 globals     compile              endCompile           None      -      1  RESOLVES
  67 globals     copyOf               None                 starting  -      0  RESOLVES
  70 globals     generateCode         generating           None      -      2  AMBIGUOUS
  75 globals     guard                GroupItem            None      -      1  RESOLVES
  78 globals     guard                clearData            None      -      1  RESOLVES
  81 globals     loadInputFromFile    if                   before    -      1  RESOLVES
  87 globals     opDebug              return               before    -      1  RESOLVES
  90 globals     opDot                product              None      -      9  AMBIGUOUS
  99 globals     parseRule            if                   before    ARM    8  AMBIGUOUS
 106 globals     parseRule            if label             before    ARM    1  RESOLVES  SHADOWED by ln 99
 137 globals     printToBuffer        toBUFFER             None      -      3  AMBIGUOUS
 140 globals     printToBuffer        debugHere            None      -      1  RESOLVES
 143 globals     processAction        code                 None      -      2  AMBIGUOUS
 146 globals     processCode          processingCode       None      -      1  RESOLVES
 149 globals     processCode          result               None      -      2  AMBIGUOUS
 152 globals     rEGISTER             currentRegistry      None      -      1  RESOLVES
 156 globals     runDefer             processingCode       None      -      0  FUNCTION GONE
 159 globals     runAction            if                   before    -     13  AMBIGUOUS
 163 globals     runOP                None                 starting  -      0  RESOLVES
 166 globals     runRule              if                   None      -      6  AMBIGUOUS
 169 globals     restoreLocalFields   None                 starting  -      0  RESOLVES
 172 globals     saveLocalFields      None                 ending    -      0  RESOLVES
 175 globals     scopeXP              return               before    -      0  FUNCTION GONE
 178 globals     setCompiledMethod    block                None      -      1  RESOLVES
 187 GroupItem   addGroup             None                 starting  -      0  RESOLVES
 190 GroupItem   addGroup             altered              None      -      1  RESOLVES
 193 GroupItem   addGroup             None                 ending    -      0  RESOLVES
 196 GroupItem   addToGuard           if                   before    -      0  FUNCTION GONE
 199 GroupItem   addToGuard           if blockGuard        within    -      0  FUNCTION GONE
 202 GroupItem   addToGuard           if isCHAR            within    -      0  FUNCTION GONE
 205 GroupItem   addToGuard           or isSTRING          within    -      0  FUNCTION GONE
 208 GroupItem   addToGuard           or isITEM            within    -      0  FUNCTION GONE
 211 GroupItem   addToGuard           or isSET             within    -      0  FUNCTION GONE
 220 GroupItem   getGuard             if                   before    ARM    0  ANCHOR GONE
 223 GroupItem   getGuard             if isCondition       before    ARM    0  ANCHOR GONE  SHADOWED by ln 220
 229 GroupItem   getGuard             endSetGuard          None      -      0  ANCHOR GONE
 232 GroupItem   getGuard             returnGuard          before    ARM    0  ANCHOR GONE  SHADOWED by ln 220
 239 GroupItem   getStuff             if                   before    -      2  AMBIGUOUS
 244 GroupItem   listenTo             None                 ending    -      0  FUNCTION GONE
 252 GroupItem   parse                if !checkInput       before    ARM    1  RESOLVES
 259 GroupItem   parse                ruleSTUFF            None      -      0  ANCHOR GONE
 262 GroupItem   parse                fireLabelMethod      None      ARM    2  AMBIGUOUS  SHADOWED by ln 252
 275 GroupItem   parse                debugHere            None      ARM    1  RESOLVES  SHADOWED by ln 252
 288 GroupItem   push                 if                   before    -      8  AMBIGUOUS
 291 GroupItem   push                 finishAdd            None      -      1  RESOLVES
 294 GroupItem   printToBuffer        printItem            None      -      0  FUNCTION GONE
 298 GroupItem   remove               if                   before    -      9  AMBIGUOUS
 301 GroupItem   setGroup             None                 starting  -      0  RESOLVES
 304 GroupItem   setRuleStuff         if                   before    -      4  AMBIGUOUS
 307 GroupItem   updateContentFlags   None                 starting  -      0  RESOLVES
 317 GroupMain   bootstrapper         pushInput            None      ARM    1  RESOLVES
 326 GroupRules  checkSkip            stacked              before    -      2  AMBIGUOUS
 330 GroupRules  checkSkip            if stacked           before    -      1  RESOLVES
 334 GroupRules  pushInput            sourceFILE           before    -      1  RESOLVES
 337 GroupRules  popInput             return               before    -      1  RESOLVES
 347 RuleStuff   checkGuard           sukcess              None      -      0  ANCHOR GONE
 350 RuleStuff   getLabel             if                   before    -      0  FUNCTION GONE
 353 RuleStuff   getLabel             endLabel             None      -      0  FUNCTION GONE
 356 RuleStuff   getWhatFollows       followed             None      -      1  RESOLVES

total entries: 70   armed: 9
  RESOLVES: 29
  AMBIGUOUS: 17
  FUNCTION GONE: 16
  ANCHOR GONE: 8
```

**Prediction held: ANCHOR GONE is non-empty, at 8.** The pre-registered armed count of 9
was exact.

## §4 THE CUT — 24 entries, verbatim

**This section is the archive. Nothing else holds this text.**

### §4a Why each class was cut

**FUNCTION GONE (16).** The named function has no definition in any source file in the
tree. Confirmed by hand for every distinct name: `aCTionDebuG`, `aCTionElsE`, `runDefer`,
`scopeXP`, `addToGuard`, `getLabel` return **zero** mentions from a repo-wide grep across
`*.twk`, `*.rtn`, `*.mm`, `*.h` — not a moved definition, not a rename, absent. `listenTo`
and `printToBuffer` are the two section-scope cases: both are live globals in
`Commands.rtn`, but both were declared under `#GroupItem`, where tok's lookup cannot reach
a global.

**ANCHOR GONE (8).** The function is live and the anchor text no longer appears anywhere in
its body. Every one of these is a refactor that walked away from the anchor, and two are
worth naming because they are the charter's predicted cause:

- **`getGuard` ×4, three of them ARMED.** `getGuard` was split. It is now a two-line pure
  read — `return guardSet;` at `GroupItem.twk:493` — and the entire machinery, including
  the `returnGuard` and `endSetGuard` labels and the `if isCondition` arm, moved into a new
  `ensureGuard()`. **So the parse-guard trace has been silently dead since that split**, and
  the three armed entries attached to a live function and injected nothing. Measured, not
  inferred: `tok` reported `getGuard() has directives` while the generated `GroupItem.mm`
  body stayed three lines long and carried no `Setting guard for`, no `setGuard:`.
- **`aCTionExpressioN while`.** `aCTionExpressioN` is now an eight-line thin dispatcher over
  `generateXP`/`interpretXP` (the 2026-06-30 unified-emit pivot). The loop the anchor named
  went with the body.

Also cut on the same grounds: `aCTionXpress result` (the function is nine lines and has no
`result` statement), `parse ruleSTUFF`, `checkGuard sukcess` (the `sukcess` statements the
anchor wanted are in `checkInput`, not `checkGuard` — the same guard migration).

### §4b The removed entries, verbatim

```
--- ln14 #globals FUNCTION GONE
aCTionDebuG debugged ctive
    if debugged print "Debugging",grup.tag:;
#;

--- ln17 #globals FUNCTION GONE
aCTionDebuG subrule.debugged ctive
    if subrule.debugged print "Debugging",subrule.tag:;
#;

--- ln20 #globals FUNCTION GONE
aCTionDebuG embed.debugged ctive
    if embed.debugged print "Debugging",embed.tag:;
#;

--- ln26 #globals FUNCTION GONE
aCTionElsE if ctive
    if blocking cerr "unBlocked:", blocking:;
#;

--- ln29 #globals ANCHOR GONE
aCTionExpressioN while before ctive
    if entries.listLength == 1   result = 0;
#;

--- ln41 #globals ANCHOR GONE
aCTionXpress result before ctive
    print "Instructions for",action.tag: list:;
#;

--- ln156 #globals FUNCTION GONE
runDefer processingCode ctive
    debugRuleNamed("ExpressioN");
#;

--- ln175 #globals FUNCTION GONE
scopeXP return before ctive
    currentMETHOD.dumpContents();
#;

--- ln196 #GroupItem FUNCTION GONE
addToGuard if before
    if parent && parent.debugGuard cerr "addToGuard: add to",guardSet,"from",block.tag:;
#;

--- ln199 #GroupItem FUNCTION GONE
addToGuard "if blockGuard" within
    if debugGuard cerr "addToGuard: add to",guardSet,"from",blockGuard:;
#;

--- ln202 #GroupItem FUNCTION GONE
addToGuard "if isCHAR" within
    if debugGuard cerr "addToGuard: adding character",character,"to",guardSet.name,"from",block.tag:;
#;

--- ln205 #GroupItem FUNCTION GONE
addToGuard "or isSTRING" within
    if debugGuard cerr "addToGuard: adding string","to",guardSet.name,"from",block.getTagXML():;
#;

--- ln208 #GroupItem FUNCTION GONE
addToGuard "or isITEM" within
    if debugGuard cerr "addToGuard: adding item",item,"to",guardSet.name,"from",block.tag:;
#;

--- ln211 #GroupItem FUNCTION GONE
addToGuard "or isSET" within
    if debugGuard cerr "addToGuard: adding set","to",guardSet.name,"from",block.tag:characterSet:;
#;

--- ln220 #GroupItem ANCHOR GONE  [ARMED]
getGuard if before active
int debugging = debugGuards || debugGuard;
#;

--- ln223 #GroupItem ANCHOR GONE  [ARMED]
getGuard "if isCondition" before active
    if debugging {
        if parent cerr "Setting guard for",tag,"in",parent.tag:;
        else cerr "Setting guard for",tag:;
        junk = 0; }
#;

--- ln229 #GroupItem ANCHOR GONE
getGuard endSetGuard ctive
    if tag eq "first"   junk = 0; }
#;

--- ln232 #GroupItem ANCHOR GONE  [ARMED]
getGuard returnGuard before active
    if debugging {
        if guarding
            if guarded  cerr "setGuard:",tag``guardSet;
            else        cerr "setGuard:",tag,"is unguarded":;
        junk = 0; }
#;

--- ln244 #GroupItem FUNCTION GONE
listenTo ending
	cerr "Adding to listener: " group.tag,group.text; if group.parent cerr " of " group.parent.tag;
    cerr `": " tag,text; if parent cerr " of " parent.tag; cerr :;
#;

--- ln259 #GroupItem ANCHOR GONE
parse ruleSTUFF ctive
    if tag eq "DEBUG"  doNothing = false;
#;

--- ln294 #GroupItem FUNCTION GONE
printToBuffer printItem
    cerr ``"printToBuffer before processing:",bufferName,printEntry,i:;
    printEntry.dumpContents();
#;

--- ln347 #RuleStuff ANCHOR GONE
checkGuard sukcess ctive
    if tag eq "CodE" sukcess = false;
#;

--- ln350 #RuleStuff FUNCTION GONE
getLabel if before ctive
    if tag eq "debug"  doNothing = 0;
#;

--- ln353 #RuleStuff FUNCTION GONE
getLabel endLabel ctive
    if tag eq "DefinE"  doNothing = 0;
#;```

---

## §5 LISTED FOR TONY, NOT CUT

### §5a ⚠ RESOLVED 2026-09-04 — **AMBIGUOUS IS A GRADE, NOT A CUT CLASS.** Tony's ruling.

**The charter's step 3 listed AMBIGUOUS among the classes to cut. It is corrected here, dated,
rather than silently left as a deviation:** an AMBIGUOUS row has a live function and a live
anchor, and the mechanism is deterministic first-match-wins, so the grade measures **legibility**
and not resolution. Only FUNCTION GONE and ANCHOR GONE describe a target that is not there.
`genLadder/directiveCensus.py` keeps reporting the match count and its header now says nothing is
cut on it. **The deviation recorded below stands as the reasoning that produced the ruling.**

### §5a ⚠ A CHARTER DEVIATION, REPORTED LOUDLY: AMBIGUOUS WAS **NOT** CUT

Step 3 said to cut AMBIGUOUS. **I did not, and the reason is a measurement rather than a
preference.**

`parseRule if before active` grades AMBIGUOUS at 8 matching sites. It is also **armed, live,
and demonstrably injecting** — the diagnostic retok put its trace at `GroupRules.mm:11235`,
at the intended site. It is the directive that prints the `Match X on text` line of the
parse trace, the one the 2026-09-03 seal reads an 830-line capture from. Cutting it deletes
a working instrument. `parse fireLabelMethod active` is the same case.

**The mechanism is deterministic first-match-wins, not undecidable.** So AMBIGUOUS here
grades *legibility* — a reader cannot tell at a glance where the anchor lands — and not
*resolution*. Every AMBIGUOUS row has a live function and a live anchor, which is the exact
opposite of the charter's own purpose sentence, *"remove every directive whose target no
longer exists."*

And the charter's own rule for the neighbouring class covers 16 of the 17: *"disarmed-but-
resolving are LISTED, not cut — a directive Tony parked on purpose isn't the same as one the
tree walked away from."* Only one AMBIGUOUS row is armed, and that one injects.

**Cutting them would also have made Step 4 row 2 vacuous for the two armed rows**, since a
deleted directive trivially has no marker to grep.

**The ruling is Tony's. The rows are listed below with their match counts and their
first-match site, which is where the mechanism actually lands.** If the answer is cut, this
report holds every one of them verbatim in the file's history at `groupDirectives`
lines listed — say the word and they go in a second pass.

### §5b The 17 AMBIGUOUS rows (line numbers are in the CULLED file)

```
  ln  20 #globals    aCTionRunRulE      'if'                9 sites; lands at ruleActions.rtn:877 +5  
  ln  23 #globals    aCTionSearch       'cout'              3 sites; lands at ruleActions.rtn:943 +14  
  ln  26 #globals    compile            'if'                4 sites; lands at Commands.rtn:138 +23  
  ln  52 #globals    generateCode       'generating'        2 sites; lands at Commands.rtn:525 +8  
  ln  72 #globals    opDot              'product'           9 sites; lands at Instruct.rtn:321 +19  
  ln  81 #globals    parseRule          'if'                8 sites; lands at Generate.rtn:106 +16  [ARMED, injects]
  ln 119 #globals    printToBuffer      'toBUFFER'          3 sites; lands at Commands.rtn:812 +4  
  ln 125 #globals    processAction      'code'              2 sites; lands at GroupActions.rtn:850 +5  
  ln 131 #globals    processCode        'result'            2 sites; lands at GroupActions.rtn:1164 +5  
  ln 138 #globals    runAction          'if'               13 sites; lands at GroupActions.rtn:1357 +8  
  ln 145 #globals    runRule            'if'                6 sites; lands at GroupActions.rtn:1719 +9  
  ln 178 #GroupItem  getStuff           'if'                2 sites; lands at GroupItem.twk:748 +22  
  ln 194 #GroupItem  parse              'fireLabelMethod'   2 sites; lands at GroupItem.twk:1510 +126  [ARMED, injects]
  ln 220 #GroupItem  push               'if'                8 sites; lands at GroupItem.twk:1764 +4  
  ln 226 #GroupItem  remove             'if'                9 sites; lands at GroupItem.twk:1829 +2  
  ln 232 #GroupItem  setRuleStuff       'if'                4 sites; lands at GroupItem.twk:2129 +2  
  ln 254 #GroupRules checkSkip          'stacked'           2 sites; lands at GroupRules.twk:118 +83  
```

### §5c The 3 SHADOWED rows — and bear-trap #30 is FALSIFIED on this data

```
  ln  88  parseRule  'if label'         armed, sits after armed ln 81
  ln 194  parse      'fireLabelMethod'  armed, sits after armed ln 187
  ln 207  parse      'debugHere'        armed, sits after armed ln 187
```

⚠ **Bear-trap #30 says a target function gets at most ONE directive, the first armed in file
order, and every loser injects nothing silently. That is not what happens.** Measured on the
culled file, one directives retok, markers greped per file:

| entry | method | injects? | site |
|---|---|---|---|
| ln 81 | `parseRule if before` | **yes** | `GroupRules.mm` `"Match %s on text` ×1 |
| ln 88 | `parseRule "if label" before` | **yes** | `GroupRules.mm` `w/no label` ×1 |
| ln 187 | `parse "if !checkInput" before` | **yes** | `GroupItem.mm` `"Match %s on text` ×1 |
| ln 194 | `parse fireLabelMethod` | **yes** | `GroupItem.mm` `w/no label` ×1 |
| ln 207 | `parse debugHere` | **yes** | `GroupItem.mm` `succeeded with count` ×1 |
| ln 245 | `bootstrapper pushInput` | **yes** | `GroupMain.mm` `ruler->debugGuards = 1` ×1 |

**Six of six, one injection each.** `parseRule` carries two armed directives and both fire;
`parse` carries three and all three fire. The mechanism supports it: `Statement2TawkNow`
walks the whole directive list at every statement point, skips any already-fired entry via
`isDirected`, and `break`s only out of that one point — so a second directive with a
*different* anchor fires at its own statement.

⚠ **The trap is not wholly wrong and should be amended rather than deleted.** Two armed
entries with the SAME anchor would still contest one point, and the first would latch. What
is falsified is the general claim, *one per target function.* The correct statement is **one
per matching statement point.**

⚠ **AND THE TRAP'S CITED LIVE EXAMPLE HAS EXPIRED.** It names *"`aCTionDebuG` carries three
stacked entries"* as its example in the tree, and `docs/fixIts.md` **F-8** is an open row on
the same three. **`aCTionDebuG` does not exist** — zero mentions in any source — and its
three entries are in §4b above. Same shape as the `ipc/` gitignore row and bear-trap #3: a
dated measurement written as a timeless fact, agreed by two registers, re-run by neither.
**F-8 is dischargeable by this report; the trap needs the amendment above.**

---

## §6 THE CERTIFICATE

**Row 1 — resolver re-run over the culled file.**
46 entries, 6 armed. **29 RESOLVES, 17 AMBIGUOUS (the listed-for-Tony class), and ZERO in
any other class.** No FUNCTION GONE, no ANCHOR GONE.

**Row 2 — one directives retok.**
```
tok GroupRules.twk groupDirectives   exit=0
tok GroupItem.twk  groupDirectives   exit=0
tok GroupMain.twk  groupDirectives   exit=0
tok RuleStuff.twk  groupDirectives   exit=0
canary  grep -c '^extern' GroupRules.h   332   (unchanged)
tok diagnostics: "Could not find directive method" / "missing location" /
                 "parseDirective: failed"          -- ZERO of each
tok attached directives to: bootstrapper, parse, parseRule   (getGuard gone, correctly)
```
Each of the six surviving armed directives greps in its generated `.mm`, exactly once — the
table in §5c. **The cut `getGuard` trace is absent: `Setting guard for` = 0.** No stop-clause
trip: nothing that resolves fails to inject.

**Row 3 — bare retok, and this is the state that stays.**
```
tok GroupRules.twk / GroupItem.twk / GroupMain.twk / RuleStuff.twk   all exit=0, BARE
canary                                                              332
md5 of all 8 generated files  vs pre-stroke baseline    IDENTICAL
git status                    clean but for IncantForms/WorkingOn/parser (Tony's WIP)
```
**No build ran during this stroke and none was needed** — the eight generated files are
byte-identical to the committed state the installed binary was built from, so the shipped
binary was never non-bare. The two diagnostic directives retoks were reverted from `HEAD`
before anything else happened, md5-verified back to baseline both times.

**Fleet and the rest of the H12 checklist — every instrument unmoved against the
2026-09-03 seal.**

| instrument | seal | now |
|---|---|---|
| `pop.sh` | 191 green / 1 parked / 3 pinned red | **191 / 1 / 3** (`parseClass.target`, `oneTest baseline`, `jsonTest baseline` — the same three) |
| `incant/frontier` | exit 0, 10 PASS | **exit 0, 10 PASS** |
| canary | 332 | **332** |
| `ddPop` | 31 records | **exit 0, 6 green** |
| `countPop` | 40/40 | **40 of 40, foot reached** |
| `decodePop` | 82 | **82 terms, 22 checks green** |
| `formsPop` | 14 | **14 checks** |
| both repos | clean/pushed but for `parser` | **same; support repo clean** |

---

## §7 ⚠ A FALSE ALARM WORTH KEEPING, because it is bear-trap #19's corollary again

Checking the shipped binary for directive-injected trace, `strings ~/bin/incant` returned
**one** hit for `Match %s on text` — a string that exists in **no** source or `.mm` in the
Groups tree. That reads as *the shipped binary is not bare*, which would have been a serious
finding against the 2026-09-03 seal.

**It is PLG's own trace.** The binary's string is `Match %s on text: %s` — with a colon —
against the directive's `Match %s on text %s\n`. It lives at
`InProcess/Parse/PLGrule.C:157`, with its siblings `%s succeeded` and `%s match failed` at
`:203`/`:218` and `w/no label` in `Parse/Alternative.C`. The Parse repo is a legitimate
compiled-in dependency, and **F-10 puts it explicitly out of this charter's scope.**

⚠ **The cause sat in a file the search space excluded**, and the discriminator was one
character. The lesson is the cheap one: **compare the exact string before concluding from a
`grep -c`.** An earlier instance in the same stroke cost less but was the same shape — a
first pass reported `bootstrapper` as not injecting, because the grep looked for
`debugGuards = true` while tok generates `ruler->debugGuards = 1`. **Two instrument errors
in one stroke, both caught, neither by care.**

---

## §8 WHAT THIS LEAVES

- **The queue is unchanged at 1** (`carrierNode`, since 2026-08-31). Per Rule F2 nothing here
  was minted as a citizen; the findings are in this report.
- **Owed to Tony, three rulings:** the AMBIGUOUS class (§5a) · whether the orphaned comment
  blocks that sat above cut entries should go too (they were left untouched — they are Tony's
  prose, and several are parked code stashes) · bear-trap #30's amendment (§5c).
- **Dischargeable:** `docs/fixIts.md` **F-8**, whose three `aCTionDebuG` entries are cut and
  archived at §4b.
- **Not touched, by scope:** `Parse/plgDirectives` (F-10) and `incant/directives` (runtime,
  a different mechanism).
- **`GUI/groupDirectives` — RULED 2026-09-04, and it is NOT an open item here.** Tony:
  ignore it until the GUI arc, and *"shitcan is the probable result after a make-sure-that-
  is-the-right-call recon."* So it is a recon-then-probably-delete, **not** a second cull —
  nothing in it is presumed worth keeping, which is the opposite of this file's premise.
  Homed in `docs/gui.md` under *What is worth salvaging*; `genLadder/directiveCensus.py`
  runs against it unchanged, and §1 above carries the grammar the recon needs.
