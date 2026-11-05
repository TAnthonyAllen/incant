# `argument` census -- SEQ 517 R1 (2026-11-03, read only)

**RENAMED on branch action-label (SEQ 518):** the rule-code meaning is `actionLabel` -- the two C++ strings and the 92 rule-code
lines in A1 / A2. The action meaning (A3 / A4) is unchanged. tester and macros held no rule-code line.

`argument` carries two meanings. In an **action** it is the call's argument. In a **rule's code** it is the label the rule
fired on (SEQ 401). The macros line (`IncantForms/WorkingOn/macros:267`) agrees with the dispatch and already names the
side that moves: **"Rename the rule's version (actionLabel was proposed ...)"** -- so the action keeps `argument`. Tony
rules the name.

## Summary

| meaning | road | lines | entries | files | reads | writes |
|---|---|---|---|---|---|---|
| rule code (the label) | new (kantGrammar) | 79 | 20 rules | 1 | 47 | 32 |
| rule code (the label) | old | 13 | 3 rules | 3 | 10 | 3 |
| action (the call's argument) | new | 1 | 1 (`nl3an`, AL-3a) | 1 | 1 | 0 |
| action (the call's argument) | old | 561 | 264 | 126 | 502 | 59 |
| not code (prose, comments, strings, fixture headers) | -- | 374 | -- | 65 | -- | -- |

**A rename of the rule's version touches 92 kant lines in 4 files** (kantGrammar 79, unitTests 8, ruleReturnT 3,
ruleReturnOpT 2) and two C++ string sites. The action side (562 lines) does not move.

Action lines by area: fleet `incant/pop` 401 (106 files); `incant/generate` 33 (reference only, bytecode retired);
`utilities` 30; `lookup` 25; `unitTests` 22; `IncantForms/WorkingOn` 19 (3 files: parser, tester, scratch); `probes` 8;
`decoder` 7; `kantGrammar` 6 (makeInstruct, makePrint -- actions); `directives` 5; `incant/fixits` 4; `frontier` 1.

## Method, and what it can and cannot see

- **Population:** every file under `incant/` and `IncantForms/` (439 files, `incant/attic` excluded), LIVE region only --
  each file cut at its first column-0 `stop();` / `bail();`. 1,027 lines contain the word.
- **Region:** a hit inside a `code={ ... }` body is code; one inside a `(...#)` literal, a comment, or anywhere else is not.
  The 374 not-code lines are mostly fixture header prose, `designDocs` / `decoder` / `jigcorpus` text, and `macros`
  (whose prose mentions `code={}` and was moved to not-code by hand).
- **Rule vs action:** a `code={}` entry is RULE code when its definition carries `isRule` (old road) or it is one of
  kantGrammar's grammar rules (new road); everything else is an action. A first heuristic (terms before `code=`)
  over-fired on prose and on actions carrying attributes (`emitBC register`, `printDefinition recurse`,
  `hexToNumber target`) and was replaced by this rule.
- **New-road actions:** the actions handed to a new-road builder (`nlNew`, `whNew`, `ciCompile` -- the actions that call
  `compileIn` with KantGrammar). Only `nl3an` among them reads `argument`; the builders themselves are old-road actions.
- **Known members the census had to return (H11), all present:** TOPSTATEMENt's `:argument STATEMENt` (rule, new);
  makeInstruct's `argument[1]` (action); `nl3an` (AL-3a).
- **Blind spots:** `IncantForms/BackupXML/*`, `Stash`, `Notions` and similar archives hold `argument` in shapes the
  `code={` scan did not open (BackupXML/utilities 39, BackupXML/generate 31, BackupXML/unitTests 14) -- counted as
  not-code, listed in A5. A rule whose code reads the label without the word (none found) is out of reach of a word search.

## (b) C++ sites that mint or bind it

| site | meaning | what it does |
|---|---|---|
| `ruleActions.rtn:386` aCTionDefinE (the `this` / `tempField` / `argument` set minted into a rule's CodE) | **rule** | `CodE += "argument"`, isLocal, noPrint -- the pre-mint. **Renames.** |
| `GroupActions.rtn:757` processAction, isRule arm | **rule** | `code["argument"]`: group = the label this fire was handed, else clear. **Renames.** |
| `ruleActions.rtn:347` aCTionDefinE | both | refuses a DECLARED `argument` attribute ("retired -- runAction mints the binding slot"). Stays; a declared `actionLabel` would want the same refusal |
| `GroupActions.rtn:1229-1231` runAction | **action** | mints `field["argument"]` if absent, sets **isArgument**, binds the call's argument |
| `GroupActions.rtn:772` processAction | action | the entry clear exempts isArgument |
| `GroupActions.rtn:336-349, 859`; `jitEmitters.rtn:104, 125, 144, 163, 366-368, 389-390, 631, 673, 1142, 1277, 1480`; `Instruct.rtn:386`; `ruleActions.rtn:679, 1873`; `GroupActions.rtn:1487-1490` (saveLocalFields) | action | the jit's argument slot and channel, the isArgument readers. All key on **isArgument**, which only runAction sets |

**The two meanings are already separate in C++ by flag:** the rule's field is isLocal and never isArgument; every
action-side reader keys on isArgument. So the rename is two string literals plus the kant lines -- no flag moves.
`resolveName` (`ruleActions.rtn:1867-1882`) resolves the word at build: it finds the owner's own `argument` first, and
for an action with none yet it mints one as a local of that action.

## (c) AL-3a

**Its failure is the ACTION meaning, and a rename of the rule's version does not touch it.** Measured 2026-11-03 with an
env-gated tap in resolveName (generated `.mm`, reverted, binary byte-identical): building `nl3an` on the new road, the
word `argument` finds nothing on `nl3an`, so resolveName mints `nl3an`'s OWN local `argument` (isLocal, parent `nl3an`);
runAction later binds that same field. The old road does the same for `nl3ao`. Rule code in the same run resolved to its
CodE's pre-minted field (31 resolutions, owner CodE). So AL-3a's `lv3a = argument` copied a holder, not another action's or a rule's field.
⚠ **CORRECTED 2026-11-05 (Tony, R3):** this read "holder arithmetic refuses on both roads by ruling". For a bare `argument` that was false: the old road's runOPslots followed the binding first, so `argument - 1` never refused there and the two roads disagreed (docs/recursionMeasure.md). SEQ 504 R0 stands for every OTHER holder (`hz - 1` refuses, `*hz - 1` reads through; argRoadsT AR-7). By R1a the new road now follows the binding too, so AL-3a reads 0 / 1 / 2.
⚠ **CORRECTION, dated 2026-11-03 (SEQ 518):** seal 302 (SEQ 502, 2026-11-01) recorded that a new-road action body's
`argument` "is resolved at BUILD, before runAction mints the action's argument at its first call, so it lands on another
action's argument field". Measured today it does not: the tap above saw resolveName mint the action's OWN local and
runAction bind that same field. This corrects seal 302's finding (SEQ 502) ("it lands on another action's argument field"), measured here not to hold. The
macros line's "it also unblocks newLocalArgT AL-3a" does not follow from the rename.

## (d) Directive files

Both hits are one parked entry copied in two gitignored files: `Directives/groupDirectives:224` and
`Directives/GroupItem:8`, `addGroup starting ctive` -- `if tag eq "ruleLIST" && group.tag eq "argument" group.dotdot =
false;`. Disarmed; a bytecode-era tag test, neither meaning by name. No other directive file names it.

## (e) Collisions

`actionLabel` is no field, rule, local or C++ name anywhere in Groups, support, TOK, Tokf or Parse -- only prose
(`docs/wakeup.md`, `IncantForms/WorkingOn/macros`, `BeforeSave`'s copy of macros). Two near-names to know about: the
instruct's third operand is called `argument` in prose and in C++ locals (`testOP`'s `argument = field[3]`, tester's
`listChain`) -- a slot name, not a field, so neither rename touches it; and the label rules already speak of `label`
(`processAction`'s `label`, `labelOf`, `isLabel`).

## Appendix

### A1. Rule code, new road (kantGrammar) -- 79 lines

| file:line | entry | R/W | line |
|---|---|---|---|
| `incant/kantGrammar:160` | INVOKEr | W | `*argument   := *icall;` |
| `incant/kantGrammar:161` | INVOKEr | R | `return  *argument;` |
| `incant/kantGrammar:166` | STARt | R | `cur := *argument.firsT;` |
| `incant/kantGrammar:174` | STARt | W | `*argument   := *built;` |
| `incant/kantGrammar:175` | STARt | R | `return  *argument;` |
| `incant/kantGrammar:179` | SHORTCUt | R | `:argument shortcut;` |
| `incant/kantGrammar:184` | SHORTCUt | W | `*argument   := *built;` |
| `incant/kantGrammar:185` | SHORTCUt | R | `return  *argument;` |
| `incant/kantGrammar:192` | PRINt | W | `*argument   := *built;` |
| `incant/kantGrammar:193` | PRINt | R | `return  *argument;` |
| `incant/kantGrammar:197` | If | R | `:argument EXPRESSIOn STATEMENt ELSe;` |
| `incant/kantGrammar:205` | If | W | `clear(*argument);` |
| `incant/kantGrammar:206` | If | R | `return *argument;` |
| `incant/kantGrammar:215` | If | W | `clear(*argument);` |
| `incant/kantGrammar:216` | If | R | `return *argument;` |
| `incant/kantGrammar:222` | If | W | `*argument   := *built;` |
| `incant/kantGrammar:223` | If | R | `return  *argument;` |
| `incant/kantGrammar:227` | ELSEIf | R | `:argument EXPRESSIOn STATEMENt ELSe;` |
| `incant/kantGrammar:235` | ELSEIf | W | `clear(*argument);` |
| `incant/kantGrammar:236` | ELSEIf | R | `return *argument;` |
| `incant/kantGrammar:245` | ELSEIf | W | `clear(*argument);` |
| `incant/kantGrammar:246` | ELSEIf | R | `return *argument;` |
| `incant/kantGrammar:252` | ELSEIf | W | `*argument   := *built;` |
| `incant/kantGrammar:253` | ELSEIf | R | `return  *argument;` |
| `incant/kantGrammar:257` | ITERATe | R | `:argument ANYtoken attributes members ITERSOURCe;` |
| `incant/kantGrammar:269` | ITERATe | W | `clear(*argument);` |
| `incant/kantGrammar:270` | ITERATe | R | `return *argument;` |
| `incant/kantGrammar:273` | ITERATe | W | `clear(*argument);` |
| `incant/kantGrammar:274` | ITERATe | R | `return *argument;` |
| `incant/kantGrammar:285` | ITERATe | W | `*argument   := *built;` |
| `incant/kantGrammar:286` | ITERATe | R | `return  *argument;` |
| `incant/kantGrammar:290` | FOr | R | `:argument LOOPEr EXPRESSIOn LOOPRESTRICt STATEMENt reversE;` |
| `incant/kantGrammar:294` | FOr | W | `clear(*argument);` |
| `incant/kantGrammar:295` | FOr | R | `return *argument;` |
| `incant/kantGrammar:303` | FOr | W | `clear(*argument);` |
| `incant/kantGrammar:304` | FOr | R | `return *argument;` |
| `incant/kantGrammar:318` | FOr | W | `*argument   := *built;` |
| `incant/kantGrammar:319` | FOr | R | `return  *argument;` |
| `incant/kantGrammar:323` | Do | R | `:argument STATEMENt EXPRESSIOn;` |
| `incant/kantGrammar:330` | Do | W | `clear(*argument);` |
| `incant/kantGrammar:331` | Do | R | `return *argument;` |
| `incant/kantGrammar:340` | Do | W | `*argument   := *built;` |
| `incant/kantGrammar:341` | Do | R | `return  *argument;` |
| `incant/kantGrammar:345` | WHILe | R | `:argument EXPRESSIOn STATEMENt;` |
| `incant/kantGrammar:352` | WHILe | W | `clear(*argument);` |
| `incant/kantGrammar:353` | WHILe | R | `return *argument;` |
| `incant/kantGrammar:362` | WHILe | W | `*argument   := *built;` |
| `incant/kantGrammar:363` | WHILe | R | `return  *argument;` |
| `incant/kantGrammar:368` | BRANCh | R | `:argument BRANCHEs EXPRESSIOn;` |
| `incant/kantGrammar:383` | BRANCh | W | `*argument   := *built;` |
| `incant/kantGrammar:384` | BRANCh | R | `return  *argument;` |
| `incant/kantGrammar:388` | SEARCh | R | `lMint       := copyOf(*argument);` |
| `incant/kantGrammar:393` | SEARCh | W | `*argument   := *built;` |
| `incant/kantGrammar:394` | SEARCh | R | `return  *argument;` |
| `incant/kantGrammar:397` | DEBUg | R | `lMint       := copyOf(*argument);` |
| `incant/kantGrammar:402` | DEBUg | W | `*argument   := *built;` |
| `incant/kantGrammar:403` | DEBUg | R | `return  *argument;` |
| `incant/kantGrammar:406` | SCOPEXp | R | `lMint       := copyOf(*argument);` |
| `incant/kantGrammar:411` | SCOPEXp | W | `*argument   := *built;` |
| `incant/kantGrammar:412` | SCOPEXp | R | `return  *argument;` |
| `incant/kantGrammar:419` | CERr | W | `*argument   := *built;` |
| `incant/kantGrammar:420` | CERr | R | `return  *argument;` |
| `incant/kantGrammar:427` | COUt | W | `*argument   := *built;` |
| `incant/kantGrammar:428` | COUt | R | `return  *argument;` |
| `incant/kantGrammar:432` | BLOCk | R | `cur := *argument.firsT;` |
| `incant/kantGrammar:440` | BLOCk | W | `*argument   := *built;` |
| `incant/kantGrammar:441` | BLOCk | R | `return  *argument;` |
| `incant/kantGrammar:445` | TOPSTATEMENt | R | `:argument STATEMENt;` |
| `incant/kantGrammar:467` | XPRESs | R | `:argument EXPRESSIOn;` |
| `incant/kantGrammar:470` | XPRESs | W | `*argument := *xi;` |
| `incant/kantGrammar:471` | XPRESs | R | `return  *argument;` |
| `incant/kantGrammar:510` | EXPRESSIOn | W | `clear(*argument);` |
| `incant/kantGrammar:511` | EXPRESSIOn | R | `return *argument;` |
| `incant/kantGrammar:536` | EXPRESSIOn | W | `clear(*argument);` |
| `incant/kantGrammar:537` | EXPRESSIOn | R | `return *argument;` |
| `incant/kantGrammar:574` | EXPRESSIOn | W | `clear(*argument);` |
| `incant/kantGrammar:575` | EXPRESSIOn | R | `return *argument;` |
| `incant/kantGrammar:607` | EXPRESSIOn | W | `*argument := *target;` |
| `incant/kantGrammar:608` | EXPRESSIOn | R | `return  *argument;` |

### A2. Rule code, old road -- 13 lines

| file:line | entry | R/W | line |
|---|---|---|---|
| `incant/pop/ruleReturnOpT:53` | xpListTest | W | `*argument := *target;` |
| `incant/pop/ruleReturnOpT:54` | xpListTest | R | `return *argument;` |
| `incant/pop/ruleReturnT:52` | xpListTest | W | `*argument := *target;` |
| `incant/pop/ruleReturnT:54` | xpListTest | R | `dumpField(*argument);` |
| `incant/pop/ruleReturnT:56` | xpListTest | R | `return *argument;` |
| `incant/unitTests:155` | list | R | `testARG code={ print "testARG: Argument is:" argument:; };` |
| `incant/unitTests:157` | list | R | `print "testForC:"`"Components of" argument with second third:;` |
| `incant/unitTests:158` | list | R | `for grup in argument; attributes` |
| `incant/unitTests:169` | list | R | `testNew code={ grup = new(argument); grup++; return grup; };` |
| `incant/unitTests:172` | list | W | `argument = lineIn + 4;` |
| `incant/unitTests:173` | list | R | `if argument& > lineIn; print "Yes it is":; else print "No it aint":; };` |
| `incant/unitTests:178` | list | R | `:argument width height;` |
| `incant/unitTests:186` | list | R | `if grup++; print ``"now grup++ is still" grup "Unary operators must preceed their argument` |

### A3. Action code, new road -- 1 lines

| file:line | entry | R/W | line |
|---|---|---|---|
| `incant/pop/newLocalArgT:42` | nl3an | R | `nl3an code={ lv3a = argument; if lv3a > 0; nl3an(lv3a - 1); print lv3a:; };` |

### A4. Action code, old road -- 561 lines

| file:line | entry | R/W | line |
|---|---|---|---|
| `IncantForms/WorkingOn/parser:13` | generateParse | R | `if dupTermRefusal(argument);    parseRefused = 1;` |
| `IncantForms/WorkingOn/parser:21` | generateParse | R | `uncompiled +% argument;` |
| `IncantForms/WorkingOn/parser:28` | generateParse | R | `iterate grup on argument;` |
| `IncantForms/WorkingOn/parser:34` | generateParse | R | `@argument;` |
| `IncantForms/WorkingOn/parser:44` | generateParse | W | `argument +< *bprCopy;` |
| `IncantForms/WorkingOn/parser:49` | walkRules | R | `generateParse(argument);` |
| `IncantForms/WorkingOn/parser:53` | walkRules | R | `iterate grup on argument;` |
| `IncantForms/WorkingOn/parser:66` | compileRules | R | `compile(argument);` |
| `IncantForms/WorkingOn/parser:68` | compileRules | R | `setParse(argument);` |
| `IncantForms/WorkingOn/parser:72` | parser | R | `walkRules(argument);` |
| `IncantForms/WorkingOn/parser:74` | parser | R | `compileRules(argument);` |
| `IncantForms/WorkingOn/scratch:14` | invokeTEST | R | `invokeTEST code={ print "invokeTEST:" taG "=" argument:; return argument; };` |
| `IncantForms/WorkingOn/scratch:21` | getTarget | W | `argument    :. flaG;` |
| `IncantForms/WorkingOn/scratch:23` | getTarget | R | `result  +% argument;` |
| `IncantForms/WorkingOn/tester:25` | listChain | R | `op      := argument[1];` |
| `IncantForms/WorkingOn/tester:26` | listChain | R | `target  := argument[2];` |
| `IncantForms/WorkingOn/tester:27` | listChain | R | `arg     := argument[3];` |
| `IncantForms/WorkingOn/tester:30` | listChain | R | `print ,:+~ "argument is:";` |
| `IncantForms/WorkingOn/tester:40` | invokeTEST | R | `invokeTEST code={ print "invokeTEST:" taG "=" argument:; return argument; };` |
| `incant/decoder:346` | decodeOne | R | `hit = decodeCorpus[argument.taG];` |
| `incant/decoder:347` | decodeOne | R | `if decodeCorpus[argument.taG];` |
| `incant/decoder:348` | decodeOne | R | `print argument.taG " -- " hit.definition:;` |
| `incant/decoder:350` | decodeOne | R | `print "decode UNDEFINED TERM " argument.taG " -- FAILS LOUD, mint the entry now (WT14)":;` |
| `incant/decoder:360` | decodE | R | `if argument.listLengtH;` |
| `incant/decoder:361` | decodE | R | `for grup in <- argument;` |
| `incant/decoder:364` | decodE | R | `decodeOne(argument);` |
| `incant/directives:10` | deleteAt | R | `:argument source fromThis;` |
| `incant/directives:19` | deleteAt | R | `Note: getLine(argument) returns a field containing the line following` |
| `incant/directives:28` | deleteAt | R | `:argument source fromThis toThis where;` |
| `incant/directives:29` | deleteAt | R | `line = getLine(argument);` |
| `incant/directives:49` | replaceAt | R | `:argument source fromThis toThis;` |
| `incant/fixits/defineCapture:24` | tdRead | R | `cerr "TD " argument ": UnitTests maximus isRulE=" tdMv "   control, the rule NamE isRulE="` |
| `incant/fixits/defineCapture:41` | mcRead | R | `cerr "MC " argument ": UnitTests maximus has term mcKid: " mcKv:;` |
| `incant/fixits/parserCoverageMembersOnly:11` | pmM | R | `iterate pmC members on *argument;` |
| `incant/fixits/parserCoverageMembersOnly:22` | pmA | R | `iterate pmC attributes on *argument;` |
| `incant/frontier:116` | frStation6 | R | `cerr "STATION 6 populate: FAIL -- the body's argument is an empty label, so its terms are ` |
| `incant/generate:36` | generateAction | R | `generated = generateCode(argument);` |
| `incant/generate:54` | runGenerated | R | `if action := generator[argument];` |
| `incant/generate:56` | runGenerated | R | `action(argument);` |
| `incant/generate:57` | runGenerated | R | `else    print ~,argument ";":;` |
| `incant/generate:62` | runGenerated | R | `lines = argument[1];` |
| `incant/generate:73` | gDO | R | `st  := argument[1];` |
| `incant/generate:74` | gDO | R | `xp  := argument["ExpressioN"];` |
| `incant/generate:105` | gFOR | R | `looper   := argument["Looper"];` |
| `incant/generate:106` | gFOR | R | `xp       := argument["ExpressioN"];` |
| `incant/generate:107` | gFOR | R | `restrict := argument["LoopRestrict"];` |
| `incant/generate:108` | gFOR | R | `st       := argument["StatemenT"];` |
| `incant/generate:133` | gIF | R | `print `"gIF: tag=" argument.taG "text=" argument.texT:;` |
| `incant/generate:140` | gIF | R | `already does (`action := generator[argument]`). Hoisted once` |
| `incant/generate:144` | gIF | R | `dumpContents(argument);` |
| `incant/generate:145` | gIF | R | `xp  := argument["ExpressioN"];` |
| `incant/generate:147` | gIF | R | `st  := argument[2];` |
| `incant/generate:148` | gIF | R | `el  := argument[3];` |
| `incant/generate:193` | gPrinT | R | `op +% argument;` |
| `incant/generate:202` | gWhilE | R | `xp  := argument["ExpressioN"];` |
| `incant/generate:204` | gWhilE | R | `st  := argument[2];` |
| `incant/generate:229` | gXpress | R | `tmp = argument;` |
| `incant/generate:245` | emitBC | R | `bcLIST += argument;` |
| `incant/generate:246` | emitBC | R | `print `"emit tag=" argument.taG "content=" argument:;` |
| `incant/generate:247` | emitBC | R | `if arguments.listLengtH;    dumpContents(argument);` |
| `incant/generate:255` | dumpBC | R | `print `"dumpBC for" argument.taG ":":;` |
| `incant/generate:256` | dumpBC | R | `if argument.listLengtH;` |
| `incant/generate:257` | dumpBC | R | `for grup in argument;` |
| `incant/generate:263` | generatE | R | `dumpContents(argument);` |
| `incant/generate:264` | generatE | R | `for field in argument;` |
| `incant/generate:516` | genBlock | R | `emitBC(bcPushField=argument);` |
| `incant/generate:519` | genBlock | R | `whose value is the source-tree GroupItem referenced by `argument`.` |
| `incant/generate:522` | genBlock | R | `bcLIST += argument;       // append the instruction as a member` |
| `incant/generate:556` | genBlock | R | `method by texT and invokes it on the argument.` |
| `incant/kantGrammar:29` | makeInstruct | R | `miOp    := argument[1];` |
| `incant/kantGrammar:30` | makeInstruct | R | `miOpnd  := argument[2];` |
| `incant/kantGrammar:36` | makeInstruct | W | `clear(argument);` |
| `incant/kantGrammar:41` | makePrint | R | `mpStuff := argument[1];` |
| `incant/kantGrammar:42` | makePrint | R | `mpOp    := argument[2];` |
| `incant/kantGrammar:64` | makePrint | W | `clear(argument);` |
| `incant/lookup:36` | luSkeleton | R | `print "  symptom    " argument.symptom:;` |
| `incant/lookup:37` | luSkeleton | R | `print "  finding    " argument.finding:;` |
| `incant/lookup:38` | luSkeleton | R | `print "  workaround " argument.workaround:;` |
| `incant/lookup:39` | luSkeleton | R | `print "  solution   " argument.solution:;` |
| `incant/lookup:40` | luSkeleton | R | `print "  status     " argument.status:;` |
| `incant/lookup:41` | luSkeleton | R | `print "  verdict    " argument.verdict:;` |
| `incant/lookup:42` | luSkeleton | R | `print "  reviewed   " argument.reviewed:;` |
| `incant/lookup:43` | luSkeleton | R | `print "  station    " argument.station:;` |
| `incant/lookup:44` | luSkeleton | R | `print "  vintage    " argument.vintage:;` |
| `incant/lookup:45` | luSkeleton | R | `print "  site       " argument.site:;` |
| `incant/lookup:46` | luSkeleton | R | `print "  bear traps " argument.beartraps:;` |
| `incant/lookup:50` | luFull | R | `luSkeleton(argument);` |
| `incant/lookup:52` | luFull | R | `print argument.description:;` |
| `incant/lookup:58` | luOne | R | `luD = decodeCorpus[argument.taG];` |
| `incant/lookup:59` | luOne | R | `if decodeCorpus[argument.taG];` |
| `incant/lookup:60` | luOne | R | `print "=== " argument.taG " -- " luD.definition:;` |
| `incant/lookup:62` | luOne | R | `luP = ProblemRecords[argument.taG];` |
| `incant/lookup:63` | luOne | R | `if ProblemRecords[argument.taG];` |
| `incant/lookup:68` | luOne | R | `print "=== " argument.taG " -- IN NEITHER POPULATION. Not yet an id: a name is born by wri` |
| `incant/lookup:73` | lookuP | R | `if argument.listLengtH;` |
| `incant/lookup:74` | lookuP | R | `for grup in <- argument;` |
| `incant/lookup:77` | lookuP | R | `luOne(argument);` |
| `incant/lookup:81` | tombstone | R | `luP = ProblemRecords[argument.taG];` |
| `incant/lookup:83` | tombstone | R | `print "=== " argument.taG " AS A TOMBSTONE, prose shed ===":;` |
| `incant/lookup:87` | tombstone | R | `print "=== " argument.taG " -- no problem record ===":;` |
| `incant/pop/acceptStartT:12` | asTake | R | `print "   INSIDE  the argument:":;` |
| `incant/pop/acceptStartT:13` | asTake | R | `showBody(argument);` |
| `incant/pop/acceptStartT:14` | asTake | R | `return argument; };` |
| `incant/pop/actorOrderT:15` | aoRule | R | `if argument["builtinActoR"];    cerr "AOACTOR " taG:;` |
| `incant/pop/actorOrderT:16` | aoRule | R | `iterate aoCur on argument;` |
| `incant/pop/adjacentT:24` | fj | R | `fj code={ fjSeen = 1; return argument; };` |
| `incant/pop/altShadowT:51` | rowC | R | `iterate asCur attributes on *argument;` |
| `incant/pop/altShadowT:58` | poison | W | `argument +% dud;` |
| `incant/pop/anyLeafT:8` | alSay | R | `v := tell(argument);` |
| `incant/pop/anyOrNumT:16` | aonGenerateParse | R | `cerr "generating parse for " argument.taG:;` |
| `incant/pop/anyOrNumT:20` | aonGenerateParse | R | `if activating != 0;     setParse(argument);` |
| `incant/pop/anyOrNumT:32` | aonGenerateParse | R | `iterate grup on *argument;` |
| `incant/pop/anyOrNumT:40` | aonGenerateParse | R | `@argument;` |
| `incant/pop/anyOrNumT:47` | aonGenerateParse | W | `argument +% codeCopy;` |
| `incant/pop/anyOrNumT:48` | aonGenerateParse | W | `argument :. isCodeD;` |
| `incant/pop/anyOrNumT:56` | aonWalkRules | R | `aonGenerateParse(argument);` |
| `incant/pop/anyOrNumT:57` | aonWalkRules | R | `if argument["CodE"];    compile(argument);` |
| `incant/pop/anyOrNumT:60` | aonWalkRules | R | `iterate grup on *argument;` |
| `incant/pop/anyOrNumT:68` | aonParser | R | `aonWalkRules(argument);` |
| `incant/pop/anyOrNumT:71` | aonParser | R | `if argument.hasNewParsE;     compiledHere = 1;` |
| `incant/pop/anyOrNumT:73` | aonParser | R | `parseAnswer = argument(ruleText);` |
| `incant/pop/anyOrNumT:74` | aonParser | R | `print ~"PARSE " argument.taG " <- " ruleText:;` |
| `incant/pop/argBindT:14` | abRead | R | `abRead   code={ return argument; };` |
| `incant/pop/argBindT:15` | abWrite | W | `abWrite  code={ argument = 5;          return argument; };` |
| `incant/pop/argBindT:16` | abSet | W | `abSet    code={ argument := abElse;    return argument; };` |
| `incant/pop/argBindT:17` | abArrow | W | `abArrow  code={ argument <- abElse;    return argument; };` |
| `incant/pop/argBindT:20` | abRun | R | `print "B1 read through the argument       " b1 " (want 7 -- the passed field)":;` |
| `incant/pop/argBindT:22` | abRun | W | `print "B2 caller after `argument = 5`     " abCaller " (want 5 -- a WRITE reaches the call` |
| `incant/pop/argBindT:25` | abRun | W | `print "B4 caller after `argument := x`    " abCaller " (want 5 -- REBIND REFUSED, unmoved)` |
| `incant/pop/argBindT:27` | abRun | W | `print "B5 caller after `argument <- x`    " abCaller " (want 5 -- REBIND REFUSED, unmoved)` |
| `incant/pop/argJitT:14` | ajCallee | R | `ajOut = argument * 2;` |
| `incant/pop/argRoundJ:17` | arA | W | `print "  A depth" arMine " sees argument =" argument " local =" arMine:;` |
| `incant/pop/argRoundT:17` | arA | W | `print "  A depth" arMine " sees argument =" argument " local =" arMine:;` |
| `incant/pop/argWriteT:14` | awRead | R | `awRead code={ return argument; };` |
| `incant/pop/argWriteT:15` | awWrite | W | `awWrite code={ argument = 5; return argument; };` |
| `incant/pop/argWriteT:18` | awRun | R | `print "R1 read through the argument      " r1 " (want 7)":;` |
| `incant/pop/artifactSkipT:21` | asWalk | R | `iterate asCur on argument;` |
| `incant/pop/bisectQ:55` | bqGen | R | `setParse(argument);` |
| `incant/pop/bisectQ:63` | bqGen | R | `iterate bqTerm on *argument;` |
| `incant/pop/bisectQ:70` | bqGen | R | `@argument;` |
| `incant/pop/bisectQ:71` | bqGen | R | `if bqTermN == 0;    bqTagMatch(argument);` |
| `incant/pop/bisectQ:79` | bqGen | W | `argument +% bqCopy;` |
| `incant/pop/bisectQ:80` | bqGen | W | `argument :. isCodeD;` |
| `incant/pop/bisectQ:86` | bqWalk | R | `bqGen(argument);` |
| `incant/pop/bisectQ:89` | bqWalk | R | `compile(argument);` |
| `incant/pop/bisectQ:91` | bqWalk | R | `iterate bqCur on *argument;` |
| `incant/pop/bisectQ:104` | bqRun | R | `bqWalk(argument);` |
| `incant/pop/bisectQ:107` | bqRun | R | `bqGen(argument);` |
| `incant/pop/bisectQ:108` | bqRun | R | `bqOut = compile(argument);` |
| `incant/pop/chanT:10` | ctSeen | R | `print "CHANT sees" argument "  want ORIG":;` |
| `incant/pop/compileInT:17` | ciCompile | R | `ciSrc := argument.CodE;` |
| `incant/pop/compileInT:18` | ciCompile | R | `ciReq.owner  := argument;` |
| `incant/pop/compileInT:24` | ciCompile | W | `argument :. isActioN;` |
| `incant/pop/compileInT:25` | ciCompile | W | `argument +< *ciBlock;` |
| `incant/pop/compileInT:31` | ciCompileBad | R | `ciSrc := argument.CodE;` |
| `incant/pop/compileInT:32` | ciCompileBad | R | `ciReq.owner  := argument;` |
| `incant/pop/compileInT:43` | ciAnswer | R | `ciSrc := argument.CodE;` |
| `incant/pop/compileInT:44` | ciAnswer | R | `ciReq.owner  := argument;` |
| `incant/pop/connectiveT:13` | cdCount | R | `iterate cdAt attributes on *argument;` |
| `incant/pop/connectiveT:16` | cdCount | R | `iterate cdMe members on *argument;` |
| `incant/pop/connectiveT:19` | cdCount | R | `cerr "   rule " argument.taG " attributes " cdA " members " cdM:;` |
| `incant/pop/connectiveT:24` | cdRead | R | `if argument.hasAttributeS;  cdHa = 1;` |
| `incant/pop/connectiveT:25` | cdRead | R | `if argument.hasTraitS;      cdHt = 1;` |
| `incant/pop/connectiveT:26` | cdRead | R | `cerr "   rule " argument.taG "  hasAttributeS " cdHa "   hasTraitS " cdHt:;` |
| `incant/pop/connectiveT:30` | cdBoth | R | `cdRead(argument);` |
| `incant/pop/connectiveT:31` | cdBoth | R | `setParse(argument);` |
| `incant/pop/connectiveT:33` | cdBoth | R | `cdRead(argument);` |
| `incant/pop/convDriveT:10` | cdSay | R | `v := tell(argument);` |
| `incant/pop/cursorReadT:27` | crWalk | R | `iterate crCur on *argument;` |
| `incant/pop/cursorReadTb:31` | crWalk | R | `iterate crCur on *argument;` |
| `incant/pop/ddGate:36` | ddRow | R | `if argument.description;     ddDesc = 1;` |
| `incant/pop/ddGate:37` | ddRow | R | `print "GATE\|" argument.taG "\|" ddDesc "\|" argument.status "\|" argument.reviewed "\|":;` |
| `incant/pop/displayFormT:68` | exercised | R | `iterate grup attributes on *argument;` |
| `incant/pop/displayFormT:73` | exercised | R | `iterate grup members on *argument;` |
| `incant/pop/driveCompileT:18` | exSay | R | `v := tell(argument);` |
| `incant/pop/driveDoorT:8` | iaGen | R | `v := tell(argument);` |
| `incant/pop/driveDoorT:15` | iaSay | R | `v := tell(argument);` |
| `incant/pop/emitRefT:26` | erClassify | R | `parseClassify(argument);` |
| `incant/pop/emitRefT:27` | erClassify | R | `iterate erCur on argument;` |
| `incant/pop/exprPinT:44` | fId | R | `fId code={ return argument; };` |
| `incant/pop/exprPinT:48` | fNest | R | `fNest code={ nr = argument * qc + qa; return nr; };` |
| `incant/pop/exprPinT:49` | tv | R | `tv code={ if argument; cerr "EP " taG " truth 1":; return; cerr "EP " taG " truth 0":; };` |
| `incant/pop/exprPinT:118` | fdShow | R | `fdShow code={ fdk := qr.datA; cerr "EP" argument qr:; cerr "EPK" argument fdk:; };` |
| `incant/pop/f31:23` | fbSkipIt | R | `cerr "SKIP  " taG argument:;` |
| `incant/pop/f31:24` | fbSkipIt | R | `showBody(argument);` |
| `incant/pop/f31:45` | fbGen | R | `iterate fbTerm on argument;` |
| `incant/pop/f31:51` | fbGen | R | `@argument;` |
| `incant/pop/f31:52` | fbGen | R | `if fbTermN == 0;    fbTagMatch(argument);` |
| `incant/pop/f31:57` | fbGen | R | `fbSkipIt(argument);` |
| `incant/pop/f31:63` | fbGen | W | `argument +% fbCopy;` |
| `incant/pop/f31:64` | fbGen | W | `argument :. isCodeD;` |
| `incant/pop/f31:67` | fbGen | R | `if fbCount == 1;    fbFirst +% argument;` |
| `incant/pop/f31:71` | fbWalk | R | `iterate fbCur members on argument;` |
| `incant/pop/failNotRootT:7` | fnrSay | R | `v := tell(argument);` |
| `incant/pop/failNotT:7` | fnSay | R | `v := tell(argument);` |
| `incant/pop/failPointT:8` | fpSay | R | `v := tell(argument);` |
| `incant/pop/groupRefuseT:10` | pm | R | `pm code={ return argument; };` |
| `incant/pop/holderT:49` | htProbe | R | `htP <- argument.parenT;` |
| `incant/pop/iterRefuseT:63` | rowW | R | `iterate w on *argument;` |
| `incant/pop/iterT1:41` | walk | R | `print "at " taG argument:;` |
| `incant/pop/iterT1:42` | walk | R | `iterate grup on *argument;` |
| `incant/pop/iterT1m:36` | walkA | R | `print "A " taG argument:;` |
| `incant/pop/iterT1m:37` | walkA | R | `iterate grup on *argument;` |
| `incant/pop/iterT1m:43` | walkB | R | `print "B " taG argument:;` |
| `incant/pop/iterT1m:44` | walkB | R | `iterate grup on *argument;` |
| `incant/pop/iterT3:32` | twice | R | `iterate grup on *argument;` |
| `incant/pop/iterT3:40` | rebind | R | `iterate grup on *argument;` |
| `incant/pop/iterT3:49` | resetSame | R | `iterate grup on *argument;` |
| `incant/pop/iterT3:51` | resetSame | R | `grup := argument;` |
| `incant/pop/iterT3:63` | reIterate | R | `iterate grup on *argument;` |
| `incant/pop/jit/argSlotWriteT:11` | srF | R | `if argument < 3;    srF(argument + 1);` |
| `incant/pop/jit/argSlotWriteT:12` | srF | R | `++argument;` |
| `incant/pop/jit/argSlotWriteT:13` | srF | R | `srSum = srSum + argument;` |
| `incant/pop/jit/argSlotWriteT:16` | lfF | R | `++argument;` |
| `incant/pop/jit/argSlotWriteT:17` | lfF | R | `lfOut = argument;` |
| `incant/pop/jit/argSlotWriteT:20` | cfF | W | `argument = argument + 10;` |
| `incant/pop/jit/argSlotWriteT:21` | cfF | R | `cfOut = argument;` |
| `incant/pop/jit/inlineArgWriteT:17` | awAssignDo | W | `argument = 9;` |
| `incant/pop/jit/inlineArgWriteT:20` | awPlusEQDo | R | `argument += 1;` |
| `incant/pop/jit/inlineArgWriteT:23` | awPlusPlusDo | R | `++argument;` |
| `incant/pop/jit/inlineArgWriteT:26` | awMinusMinusDo | R | `--argument;` |
| `incant/pop/jit/inlineConstArgT:11` | apShow | R | `apH := argument.taG;` |
| `incant/pop/jit/inlineConstArgT:12` | apShow | R | `cerr "AP-1 name [" ,*apH "] value [" argument "]":;` |
| `incant/pop/jit/inlineFieldArgT:13` | fdShow | R | `fdH := argument.taG;` |
| `incant/pop/jit/inlineFieldArgT:14` | fdShow | R | `cerr "FD-1 name [" ,*fdH "] value [" argument "]":;` |
| `incant/pop/jit/itBackRT:11` | ibRule | R | `iterate ibCur on argument;` |
| `incant/pop/jit/itRT:11` | itRule | R | `iterate itCur on argument;` |
| `incant/pop/jit/jitArgChainT:13` | acH | R | `return argument + 100;` |
| `incant/pop/jit/jitArgChainT:19` | acF | R | `if argument == 0;   return 0;` |
| `incant/pop/jit/jitArgChainT:20` | acF | R | `h = acH(argument);` |
| `incant/pop/jit/jitArgChainT:21` | acF | R | `r = acF(argument - 1);` |
| `incant/pop/jit/jitArgNumberT:16` | nmF | R | `if argument < 1;    return 0;` |
| `incant/pop/jit/jitArgNumberT:17` | nmF | R | `t = argument;` |
| `incant/pop/jit/jitArgNumberT:18` | nmF | R | `r = nmF(argument - 1);` |
| `incant/pop/jit/jitArithOperandT:16` | aoCallee | R | `aoX = argument - 1;` |
| `incant/pop/jit/jitArithOperandT:17` | aoCallee | R | `aoY = argument;` |
| `incant/pop/jit/jitArithOperandT:18` | aoCallee | R | `aoN = -argument;` |
| `incant/pop/jit/jitArithOperandT:19` | aoCallee | R | `aoZ = argument;` |
| `incant/pop/jit/jitArithOperandT:20` | aoCallee | R | `return argument;` |
| `incant/pop/jit/jitCmpOperandAT:15` | caCallee | R | `if argument < 0;    caP = 1;` |
| `incant/pop/jit/jitCmpOperandAT:16` | caCallee | R | `if argument == 0;   caQ = 1;` |
| `incant/pop/jit/jitCmpOperandAT:17` | caCallee | R | `caR = argument;` |
| `incant/pop/jit/jitCmpOperandAT:18` | caCallee | R | `return argument;` |
| `incant/pop/jit/jitCmpOperandT:25` | cmCallee | R | `cmR = argument;` |
| `incant/pop/jit/jitCmpOperandT:26` | cmCallee | R | `return argument;` |
| `incant/pop/jit/jitCompileOnceT:17` | coF | R | `if argument < 0;    return -1;` |
| `incant/pop/jit/jitCompileOnceT:18` | coF | R | `if argument == 0;   return 0;` |
| `incant/pop/jit/jitCompileOnceT:19` | coF | R | `t = argument;` |
| `incant/pop/jit/jitCompileOnceT:20` | coF | R | `r = coF(argument - 1);` |
| `incant/pop/jit/jitCursorLifeT:13` | lRule | R | `iterate lc on argument;` |
| `incant/pop/jit/jitCursorLifeT:18` | bRec | R | `if argument > 0;` |
| `incant/pop/jit/jitCursorLifeT:21` | bRec | R | `bRec(argument - 1);` |
| `incant/pop/jit/jitDfProbe:176` | displayForm | R | `iterate grup attributes on *argument;` |
| `incant/pop/jit/jitDfProbe:181` | displayForm | R | `iterate grup members on *argument;` |
| `incant/pop/jit/jitInlineBreakRT:13` | ibkStop | R | `if argument["mark"];    break;` |
| `incant/pop/jit/jitInlineContRT:13` | icSkip | R | `if argument["mark"];    continue;` |
| `incant/pop/jit/jitRecurSaveGT:17` | rsF | R | `if argument < 0;    return -1;` |
| `incant/pop/jit/jitRecurSaveGT:18` | rsF | R | `if argument == 0;   return 0;` |
| `incant/pop/jit/jitRecurSaveGT:19` | rsF | R | `t = argument;` |
| `incant/pop/jit/jitRecurSaveGT:20` | rsF | R | `r = rsF(argument - 1);` |
| `incant/pop/jit/jitRecurSaveGT:28` | rsG | R | `if argument < 0;    return -1;` |
| `incant/pop/jit/jitRecurSaveGT:29` | rsG | R | `if argument == 0;   return 0;` |
| `incant/pop/jit/jitRecurSaveGT:30` | rsG | R | `r = rsG(argument - 1);` |
| `incant/pop/jit/jitRecurSaveGT:31` | rsG | R | `r = r + argument;` |
| `incant/pop/jit/jitRecurSaveT:17` | rsF | R | `if argument < 0;    return -1;` |
| `incant/pop/jit/jitRecurSaveT:18` | rsF | R | `if argument == 0;   return 0;` |
| `incant/pop/jit/jitRecurSaveT:19` | rsF | R | `t = argument;` |
| `incant/pop/jit/jitRecurSaveT:20` | rsF | R | `r = rsF(argument - 1);` |
| `incant/pop/jit/jitRecurSaveT:28` | rsG | R | `if argument < 0;    return -1;` |
| `incant/pop/jit/jitRecurSaveT:29` | rsG | R | `if argument == 0;   return 0;` |
| `incant/pop/jit/jitRecurSaveT:30` | rsG | R | `r = rsG(argument - 1);` |
| `incant/pop/jit/jitRecurSaveT:31` | rsG | R | `r = r + argument;` |
| `incant/pop/jit/jitScCountT:14` | scId | R | `scId code={ scN += 1; return argument; };` |
| `incant/pop/jit/jitSelfCallValT:16` | vcF | R | `if argument == 0;   return 100;` |
| `incant/pop/jit/jitSelfCallValT:17` | vcF | R | `r = vcF(argument - 1);` |
| `incant/pop/jit/jitSelfFn:121` | sf | R | `sf(argument);` |
| `incant/pop/jit/jitStarIdiomT:9` | jr1 | R | `idF := copyOf(argument);` |
| `incant/pop/jit/jitValueTargetT:38` | jvShow | R | `cerr argument " JVT-1 -a += 3 -> a " jv1:;` |
| `incant/pop/jit/jitValueTargetT:39` | jvShow | R | `cerr argument " JVT-2 -a = 3 -> a " jv2:;` |
| `incant/pop/jit/jitValueTargetT:40` | jvShow | R | `cerr argument " JVT-6 ++-a -> a " jv6:;` |
| `incant/pop/jit/jitValueTargetT:41` | jvShow | R | `cerr argument " JVT-8 a + b += 1 -> a " jv8:;` |
| `incant/pop/jit/jitValueTargetT:42` | jvShow | R | `cerr argument " JVK-1 a += 3 -> a " jk1:;` |
| `incant/pop/jit/jitValueTargetT:43` | jvShow | R | `cerr argument " JVK-2 a = -a -> a " jk2:;` |
| `incant/pop/jit/jitValueTargetT:44` | jvShow | R | `cerr argument " JR2-1 count a *= -1 -> " jr1 " kind " jr1.datA:;` |
| `incant/pop/jit/jitValueTargetT:45` | jvShow | R | `cerr argument " JR2-2 count a = -a -> " jr2 " kind " jr2.datA:;` |
| `incant/pop/jit/jitValueTargetT:46` | jvShow | R | `cerr argument " JR2-3 number a *= -1 -> " jr3 " kind " jr3.datA:;` |
| `incant/pop/jit/jitValueTargetT:47` | jvShow | R | `cerr argument " JR2-4 number a = -a -> " jr4 " kind " jr4.datA:;` |
| `incant/pop/jit/jitValueTargetT:48` | jvShow | R | `cerr argument " JVP-1 c = -a + -b, a 3 b 4 -> " jp1:;` |
| `incant/pop/jit/jitXscRT:15` | fId | R | `fId code={ return argument; };` |
| `incant/pop/jit/kindJ1T:28` | kjShow | R | `iterate h members on argument;` |
| `incant/pop/jit/seedScopeBT:15` | sbRes | R | `sbMark := new(argument);` |
| `incant/pop/jitArgListT:10` | alArg | R | `alArg code={ print "AL argument [" argument "]":; };` |
| `incant/pop/jitInlineBindT:12` | ibX | R | `ibX code={ ibSeen = argument; };` |
| `incant/pop/jitInlineBindT:14` | ibXr | R | `iterate ibQ on argument;` |
| `incant/pop/jitInlineBindT:21` | ibXn | R | `ibXn code={ ibX(argument); };` |
| `incant/pop/jitInlineBindT:23` | ibF | R | `ibX(argument);` |
| `incant/pop/jitInlineBindT:24` | ibF | R | `if argument > 0;    ibF(argument - 1);` |
| `incant/pop/jitInlineBindT:25` | ibF | R | `cerr "IB-1 fall-through, the caller's argument after the self-call [" argument "]":;` |
| `incant/pop/jitInlineBindT:28` | ibFr | R | `ibXr(argument);` |
| `incant/pop/jitInlineBindT:29` | ibFr | R | `if argument > 0;    ibFr(argument - 1);` |
| `incant/pop/jitInlineBindT:30` | ibFr | R | `cerr "IB-2 refused statement, the caller's argument after the self-call [" argument "]":;` |
| `incant/pop/jitInlineBindT:33` | ibFm | R | `ibXm(argument);` |
| `incant/pop/jitInlineBindT:34` | ibFm | R | `if argument > 0;    ibFm(argument - 1);` |
| `incant/pop/jitInlineBindT:35` | ibFm | R | `cerr "IB-3 mid-body return, the caller's argument after the self-call [" argument "]":;` |
| `incant/pop/jitInlineBindT:38` | ibFn | R | `ibXn(argument);` |
| `incant/pop/jitInlineBindT:39` | ibFn | R | `if argument > 0;    ibFn(argument - 1);` |
| `incant/pop/jitInlineBindT:40` | ibFn | R | `cerr "IB-4 nested inline, the caller's argument after the self-call [" argument "]":;` |
| `incant/pop/jitterT:14` | jtAdd | R | `jtAcc += argument;` |
| `incant/pop/jitterT:21` | jtMintRow | R | `jtMark := new(argument);` |
| `incant/pop/jitterT:24` | jtMintRow | R | `jtSlot := jtPending[argument];` |
| `incant/pop/jitterT:28` | jtResult | R | `jtName := argument.taG;` |
| `incant/pop/jitterT:30` | jtResult | R | `if *jtRead == argument; *jtSlot = 1;` |
| `incant/pop/jsonTest:7` | jtKid | R | `print "JT     KID" argument.taG "len=" argument.listLengtH "value=" argument:;` |
| `incant/pop/jsonTest:8` | jtKid | R | `addrOf(argument);` |
| `incant/pop/jsonTest:11` | jtKids | R | `iterate jtK on argument;` |
| `incant/pop/jsonTest:16` | jtMember | R | `print "JT   MEMBER" argument.taG "len=" argument.listLengtH "value=" argument:;` |
| `incant/pop/jsonTest:17` | jtMember | R | `addrOf(argument);` |
| `incant/pop/jsonTest:18` | jtMember | R | `jtN := argument.listLengtH;` |
| `incant/pop/jsonTest:20` | jtMember | R | `jtKids(argument);` |
| `incant/pop/jsonTest:24` | testJSON | R | `field = JSONblock(argument);` |
| `incant/pop/jsonTest:25` | testJSON | R | `if field;   print "  ok  :" argument:;` |
| `incant/pop/jsonTest:26` | testJSON | R | `else        print "  FAIL:" argument:;` |
| `incant/pop/kant8T:85` | k1 | R | `k1(argument);` |
| `incant/pop/kant8T:92` | k2 | R | `k2(argument);` |
| `incant/pop/kant8T:93` | k2 | R | `return argument;` |
| `incant/pop/kant8T:116` | k2x | R | `return argument.taG;` |
| `incant/pop/kant8T:119` | k2xCtl | R | `return argument.taG;` |
| `incant/pop/kant8T:131` | k4 | R | `k4(argument);` |
| `incant/pop/kant8T:148` | k5 | R | `k5(argument);` |
| `incant/pop/kant8T:169` | k6A | R | `iterate k6cur attributes on *argument;` |
| `incant/pop/kant8T:179` | k6B | R | `k6A(argument);` |
| `incant/pop/kant8T:220` | k6Aarg | R | `return argument.taG;` |
| `incant/pop/kant8T:223` | k6Barg | R | `k6Aarg(argument);` |
| `incant/pop/kant8T:244` | k6Bctl | R | `k6Actl(argument);` |
| `incant/pop/kant8T:353` | k6Awide | R | `iterate k6cur5 attributes on *argument;` |
| `incant/pop/kant8T:363` | k6Bwide | R | `k6Awide(argument);` |
| `incant/pop/kindLiftT:29` | klShow | R | `iterate h members on argument;` |
| `incant/pop/kindLiftT:34` | klOne | R | `hl := argument.listLengtH;` |
| `incant/pop/kindLiftT:35` | klOne | R | `cerr "KL value " argument " length " hl:;` |
| `incant/pop/kindT:11` | kWalk | R | `iterate kCur on argument;` |
| `incant/pop/kindT:16` | kShow | R | `iterate kShC on argument;` |
| `incant/pop/lastRefT:10` | lrEcho | R | `lrEcho code={ return argument; };` |
| `incant/pop/lastRefT:12` | lrWalk | R | `iterate lrCur on *argument;` |
| `incant/pop/leafClassT:9` | lcSay | R | `v := tell(argument);` |
| `incant/pop/leafClassT:11` | lcSay | R | `cerr "LCDRIVE " argument " matched= " m " consumed= " c:;` |
| `incant/pop/leafClassT:14` | lcClass | R | `r := Grokking[argument];` |
| `incant/pop/leafLabelT:8` | llSay | R | `v := tell(argument);` |
| `incant/pop/leafLabelT:10` | llSay | R | `cerr "LL-DRIVE " argument " matched= " m " consumed= " c:;` |
| `incant/pop/loneOpT:7` | loSay | R | `v := tell(argument);` |
| `incant/pop/nestT:38` | ntF | R | `return argument.taG;` |
| `incant/pop/nestT:42` | ntRun | R | `print "== ROW 0  ANTI-VACUITY: f reads its argument at all ==":;` |
| `incant/pop/newCallBindT:24` | nlNew | R | `nlSrc := argument.CodE;` |
| `incant/pop/newCallBindT:25` | nlNew | R | `nlReqN.owner  := argument;` |
| `incant/pop/newCallBindT:31` | nlNew | W | `argument :. isActioN;` |
| `incant/pop/newCallBindT:32` | nlNew | W | `argument +< *nlBlock;` |
| `incant/pop/newCallBindT:35` | nlOld | R | `nlSrc := argument.CodE;` |
| `incant/pop/newCallBindT:36` | nlOld | R | `nlReqO.owner  := argument;` |
| `incant/pop/newCallBindT:41` | nlOld | W | `argument :. isActioN;` |
| `incant/pop/newCallBindT:42` | nlOld | W | `argument +< *nlBlock;` |
| `incant/pop/newLocalArgT:22` | nlNew | R | `nlSrc := argument.CodE;` |
| `incant/pop/newLocalArgT:23` | nlNew | R | `nlReqN.owner  := argument;` |
| `incant/pop/newLocalArgT:29` | nlNew | W | `argument :. isActioN;` |
| `incant/pop/newLocalArgT:30` | nlNew | W | `argument +< *nlBlock;` |
| `incant/pop/newLocalArgT:33` | nlOld | R | `nlSrc := argument.CodE;` |
| `incant/pop/newLocalArgT:34` | nlOld | R | `nlReqO.owner  := argument;` |
| `incant/pop/newLocalArgT:39` | nlOld | W | `argument :. isActioN;` |
| `incant/pop/newLocalArgT:40` | nlOld | W | `argument +< *nlBlock;` |
| `incant/pop/newLocalArgT:43` | nl3ao | R | `nl3ao code={ lv3a = argument; if lv3a > 0; nl3ao(lv3a - 1); print lv3a:; };` |
| `incant/pop/newLocalT:24` | nlNew | R | `nlSrc := argument.CodE;` |
| `incant/pop/newLocalT:25` | nlNew | R | `nlReqN.owner  := argument;` |
| `incant/pop/newLocalT:31` | nlNew | W | `argument :. isActioN;` |
| `incant/pop/newLocalT:32` | nlNew | W | `argument +< *nlBlock;` |
| `incant/pop/newLocalT:35` | nlOld | R | `nlSrc := argument.CodE;` |
| `incant/pop/newLocalT:36` | nlOld | R | `nlReqO.owner  := argument;` |
| `incant/pop/newLocalT:41` | nlOld | W | `argument :. isActioN;` |
| `incant/pop/newLocalT:42` | nlOld | W | `argument +< *nlBlock;` |
| `incant/pop/newLocalT:44` | nlTag | R | `nlTag code={ print argument.taG:; };` |
| `incant/pop/newReturnSelfT:24` | nlNew | R | `nlSrc := argument.CodE;` |
| `incant/pop/newReturnSelfT:25` | nlNew | R | `nlReqN.owner  := argument;` |
| `incant/pop/newReturnSelfT:31` | nlNew | W | `argument :. isActioN;` |
| `incant/pop/newReturnSelfT:32` | nlNew | W | `argument +< *nlBlock;` |
| `incant/pop/newReturnSelfT:35` | nlOld | R | `nlSrc := argument.CodE;` |
| `incant/pop/newReturnSelfT:36` | nlOld | R | `nlReqO.owner  := argument;` |
| `incant/pop/newReturnSelfT:41` | nlOld | W | `argument :. isActioN;` |
| `incant/pop/newReturnSelfT:42` | nlOld | W | `argument +< *nlBlock;` |
| `incant/pop/newReturnT:24` | nlNew | R | `nlSrc := argument.CodE;` |
| `incant/pop/newReturnT:25` | nlNew | R | `nlReqN.owner  := argument;` |
| `incant/pop/newReturnT:31` | nlNew | W | `argument :. isActioN;` |
| `incant/pop/newReturnT:32` | nlNew | W | `argument +< *nlBlock;` |
| `incant/pop/newReturnT:35` | nlOld | R | `nlSrc := argument.CodE;` |
| `incant/pop/newReturnT:36` | nlOld | R | `nlReqO.owner  := argument;` |
| `incant/pop/newReturnT:41` | nlOld | W | `argument :. isActioN;` |
| `incant/pop/newReturnT:42` | nlOld | W | `argument +< *nlBlock;` |
| `incant/pop/noPrintFrameT:14` | npCtl | R | `cerr "N" npRow " control  arg " argument.taG " local1 " npC1.taG:;` |
| `incant/pop/noPrintFrameT:22` | npMint | R | `cerr "N" npRow " treated  arg " argument.taG " local1 " npM1.taG:;` |
| `incant/pop/omModT:7` | omSay | R | `v := tell(argument);` |
| `incant/pop/omModT:9` | omSay | R | `cerr "OMDRIVE " argument " matched= " m " consumed= " c:;` |
| `incant/pop/omModT:12` | omOne | R | `r := Grokking[argument];` |
| `incant/pop/omModT:17` | omTwo | R | `r := OmMod[argument];` |
| `incant/pop/opMixT:23` | show | R | `show code={ k := argument.datA; x := argument.texT; cerr "OMV" x k:; };` |
| `incant/pop/orProbe:13` | probeIt | R | `:argument alpha1 beta1;` |
| `incant/pop/orProbe:15` | probeIt | R | `point of this probe's subject. `:argument alpha1 beta1;` mints an absent` |
| `incant/pop/parseClass:67` | pcTerms | R | `iterate pcA attributes on *argument;` |
| `incant/pop/parseClass:72` | pcTerms | R | `iterate pcM members on *argument;` |
| `incant/pop/parseClass:79` | pcWalk | R | `iterate pcR members on *argument;` |
| `incant/pop/pass1SeqT:15` | pf | R | `pf code={ return argument; };` |
| `incant/pop/propGetT:23` | pgWalk | R | `iterate pgCur on argument;` |
| `incant/pop/propOpT:29` | poWalk | R | `iterate poCur on argument;` |
| `incant/pop/recurSaveT:15` | rsF | R | `if argument < 0;    return -1;` |
| `incant/pop/recurSaveT:16` | rsF | R | `if argument == 0;   return 0;` |
| `incant/pop/recurSaveT:17` | rsF | R | `t = argument;` |
| `incant/pop/recurSaveT:18` | rsF | R | `r = rsF(argument - 1);` |
| `incant/pop/recurSaveT:23` | rsG | R | `if argument < 0;    return -1;` |
| `incant/pop/recurSaveT:24` | rsG | R | `if argument == 0;   return 0;` |
| `incant/pop/recurSaveT:25` | rsG | R | `r = rsG(argument - 1);` |
| `incant/pop/recurSaveT:26` | rsG | R | `r = r + argument;` |
| `incant/pop/recurSaveT:30` | rsH | R | `x = argument + 100;` |
| `incant/pop/recurSaveT:31` | rsH | R | `return argument;` |
| `incant/pop/recurSaveT:35` | rsK | R | `return argument;` |
| `incant/pop/ruleCount:33` | countThem | R | `iterate rcCur members on *argument;` |
| `incant/pop/ruleCount:44` | countAttrs | R | `iterate rcCur3 attributes on *argument;` |
| `incant/pop/ruleReturnOpT:32` | invokeTEST | R | `invokeTEST code={ return argument; };` |
| `incant/pop/ruleReturnT:32` | invokeTEST | R | `invokeTEST code={ return argument; };` |
| `incant/pop/ruleTermT:7` | rtFace | R | `r := Grokking[argument];` |
| `incant/pop/ruleTermT:12` | rtOwn | R | `r := RtReg[argument];` |
| `incant/pop/ruleTermT:16` | rtTerm | R | `r := RtReg[argument];` |
| `incant/pop/ruleTermT:21` | rtGrok | R | `r := Grokking[argument];` |
| `incant/pop/searchAcc:25` | generateParse | R | `uncompiled +% argument;` |
| `incant/pop/searchAcc:33` | generateParse | R | `iterate grup on argument;` |
| `incant/pop/searchAcc:39` | generateParse | R | `@argument;` |
| `incant/pop/searchAcc:46` | generateParse | W | `argument +% *codeCopy;` |
| `incant/pop/searchAcc:47` | generateParse | W | `argument :. isCodeD;` |
| `incant/pop/searchAcc:48` | generateParse | W | `argument :. hasNewParsE;` |
| `incant/pop/searchAcc:53` | walkRules | R | `generateParse(argument);` |
| `incant/pop/searchAcc:56` | walkRules | R | `iterate grup on argument;` |
| `incant/pop/searchAcc:68` | compileRules | R | `setParse(argument);` |
| `incant/pop/searchAcc:69` | compileRules | R | `compile(argument);` |
| `incant/pop/searchAcc:75` | parser | R | `walkRules(Grokking[argument.taG]);` |
| `incant/pop/searchAcc:76` | parser | R | `compileRules(Grokking[argument.taG]);` |
| `incant/pop/searchAccB:26` | generateParse | R | `uncompiled +% argument;` |
| `incant/pop/searchAccB:34` | generateParse | R | `iterate grup on argument;` |
| `incant/pop/searchAccB:40` | generateParse | R | `@argument;` |
| `incant/pop/searchAccB:51` | generateParse | W | `argument +% *bprCopy;` |
| `incant/pop/searchAccB:57` | generateParse | W | `argument +% *codeCopy;` |
| `incant/pop/searchAccB:58` | generateParse | W | `argument :. isCodeD;` |
| `incant/pop/searchAccB:65` | generateParse | W | `if ownActionAtEntry == 0;   argument :. hasNewParsE;` |
| `incant/pop/searchAccB:71` | walkRules | R | `generateParse(argument);` |
| `incant/pop/searchAccB:74` | walkRules | R | `iterate grup on argument;` |
| `incant/pop/searchAccB:93` | compileRules | R | `setParse(argument);` |
| `incant/pop/searchAccB:94` | compileRules | R | `compile(argument);` |
| `incant/pop/searchAccB:101` | parser | R | `walkRules(argument);` |
| `incant/pop/searchAccB:102` | parser | R | `compileRules(argument);` |
| `incant/pop/seqT:23` | fId | R | `fId code={ return argument; };` |
| `incant/pop/shadowCensus:55` | scMembers | R | `iterate scCur members on *argument;` |
| `incant/pop/shadowCensus:60` | scMembers | R | `accessor after it reads scDcol's argument, not this member.` |
| `incant/pop/shadowCensus:77` | scAttrs | R | `iterate scCur2 attributes on *argument;` |
| `incant/pop/shadowCensus:82` | scAttrs | R | `accessor after it reads scDcol's argument, not this member.` |
| `incant/pop/shapeBodyT:8` | shSay | R | `v := tell(argument);` |
| `incant/pop/shapeBodyT:10` | shSay | R | `cerr "DRIVE " argument " matched= " m " consumed= " c:;` |
| `incant/pop/shapeBodyT:14` | shSay | R | `if rp == 1;     cerr "LABEL " argument " text=[" ,*lt "]":;` |
| `incant/pop/shapeBodyT:15` | shSay | R | `if rp == 0;     cerr "LABEL " argument " (none)":;` |
| `incant/pop/shortCircT:33` | scShow | R | `scShow code={ cerr "SC " argument " x " scNX " y " scNY " a " scNa " b " scNb " c " scNc "` |
| `incant/pop/starIdiomT:42` | r1 | R | `idF := copyOf(argument);` |
| `incant/pop/starIdiomT:66` | r4 | R | `idC := compile(argument);` |
| `incant/pop/termCountT:19` | tcRule | R | `iterate tcCur on argument;` |
| `incant/pop/testPrecedence:26` | tpMintRow | R | `tpMark := new(argument);` |
| `incant/pop/testPrecedence:29` | tpMintRow | R | `tpSlot := tpPending[argument];` |
| `incant/pop/testPrecedence:33` | tpTestResult | R | `tpName := argument.taG;` |
| `incant/pop/testPrecedence:35` | tpTestResult | R | `if *tpRead == argument; *tpSlot = 1;` |
| `incant/pop/testPrecedence:40` | tpTestResult | R | `cerr "ROW" ,*tpName "WANT" argument "GOT " ,*tpRead:;` |
| `incant/pop/testPrecedence:49` | tpAssignArgDo | W | `argument = 9;` |
| `incant/pop/testPrecedence:92` | tpPlusEQArgDo | R | `argument += 1;` |
| `incant/pop/testPrecedence:139` | tpPlusPlusArgDo | R | `++argument;` |
| `incant/pop/testPrecedence:164` | tpMinusMinusArgDo | R | `--argument;` |
| `incant/pop/testPrecedence:189` | tpAddAttrArgDo | W | `argument +% *tpNode;` |
| `incant/pop/testerChainT:4` | fId | R | `fId code={ return argument; };` |
| `incant/pop/testerChainT:5` | fNest | R | `fNest code={ return argument + 1; };` |
| `incant/pop/traitFlagsT:18` | tfProbe | R | `tfDisagree  +% argument;` |
| `incant/pop/traitFlagsT:25` | tfWalk | R | `iterate tfCur on *argument;` |
| `incant/pop/traitFlagsT:31` | tfTagLine | R | `iterate grup on argument;` |
| `incant/pop/treeRowT:8` | trSay | R | `v := tell(argument);` |
| `incant/pop/trigDO:21` | tdGenerateParse | R | `setParse(argument);` |
| `incant/pop/trigDO:33` | tdGenerateParse | R | `iterate grup on argument;` |
| `incant/pop/trigDO:39` | tdGenerateParse | R | `print $taG "(argument)";` |
| `incant/pop/trigDO:41` | tdGenerateParse | R | `@argument;` |
| `incant/pop/trigDO:47` | tdGenerateParse | W | `argument +% *codeCopy;` |
| `incant/pop/trigDO:48` | tdGenerateParse | W | `argument :. isCodeD;` |
| `incant/pop/trigDO:49` | tdGenerateParse | W | `argument :. hasNewParsE;` |
| `incant/pop/trigDO:54` | tdWalkRules | R | `tdGenerateParse(argument);` |
| `incant/pop/trigDO:57` | tdWalkRules | R | `iterate grup on argument;` |
| `incant/pop/trigDO:68` | tdCompileRules | R | `compile(argument);` |
| `incant/pop/trigDO:71` | tdCompileRules | R | `iterate grup on argument;` |
| `incant/pop/trigDO:78` | tdParser | R | `tdWalkRules(argument);` |
| `incant/pop/trigDO:79` | tdParser | R | `tdCompileRules(argument);` |
| `incant/pop/trigDO:82` | tdParser | R | `if argument.hasNewParsE;     compiledHere = 1;` |
| `incant/pop/whileT:31` | whNew | R | `nlSrc := argument.CodE;` |
| `incant/pop/whileT:32` | whNew | R | `nlReqN.owner  := argument;` |
| `incant/pop/whileT:38` | whNew | W | `argument :. isActioN;` |
| `incant/pop/whileT:39` | whNew | W | `argument +< *nlBlock;` |
| `incant/pop/zeroWidthT:7` | zwSay | R | `v := tell(argument);` |
| `incant/pop/zeroWidthT:9` | zwSay | R | `cerr "ZWDRIVE " argument " matched= " m " consumed= " c " length= " n:;` |
| `incant/probes/failedAtfasP1:8` | fsSay | R | `v := tell(argument);` |
| `incant/probes/failedAtfasP2:8` | fsSay | R | `v := tell(argument);` |
| `incant/probes/globalReadInAction:118` | frStation6 | R | `cerr "STATION 6 populate: FAIL -- the body's argument is an empty label, so its terms are ` |
| `incant/probes/kantGrammarLoad:21` | kgRule | R | `iterate kgC on argument;` |
| `incant/probes/kantGrammarNames:11` | kgReg | R | `iterate kgM on argument;` |
| `incant/probes/kantGrammarNames:23` | kgHead | R | `kgReg(argument);` |
| `incant/probes/subscriptShapes:10` | p4Id | R | `p4Id code={ return argument; };` |
| `incant/probes/vetoOptional:9` | vtSay | R | `v := tell(argument);` |
| `incant/unitTests:37` | lefty | R | `testARG(righty += 22) passes the result of an expression as an argument,` |
| `incant/unitTests:42` | lefty | R | `into local scope. ':argument width height' makes width and height from` |
| `incant/unitTests:43` | lefty | R | `argument available by name in the local scope. No C++ equivalent.` |
| `incant/unitTests:47` | lefty | R | `argument& dereferences a pointer-arithmetic result. & follows the field` |
| `incant/unitTests:72` | lefty | R | `printDefinition()       prints out its argument in incant field definition format` |
| `incant/unitTests:115` | lefty | R | `accessTest code={ print "accessTest: " taG; if argument.across; print `"Saw across in" taG` |
| `incant/unitTests:118` | lefty | R | `print ~"callMyself: First time:" argument righty,:+;` |
| `incant/unitTests:122` | lefty | R | `print ~"Second time:" argument righty,:-;` |
| `incant/unitTests:222` | printDefinition | R | `if datA != 0;  print ~$taG "=" argument$;` |
| `incant/unitTests:225` | printDefinition | R | `for grup in argument; attributes` |
| `incant/unitTests:231` | printDefinition | R | `for grup in argument; members` |
| `incant/unitTests:248` | testRecurF | R | `if argument < 0;    return -1;` |
| `incant/unitTests:249` | testRecurF | R | `if argument == 0;   return 0;` |
| `incant/unitTests:250` | testRecurF | R | `t = argument;` |
| `incant/unitTests:251` | testRecurF | R | `r = testRecurF(argument - 1);` |
| `incant/unitTests:256` | testRecurG | R | `if argument < 0;    return -1;` |
| `incant/unitTests:257` | testRecurG | R | `if argument == 0;   return 0;` |
| `incant/unitTests:258` | testRecurG | R | `r = testRecurG(argument - 1);` |
| `incant/unitTests:259` | testRecurG | R | `r = r + argument;` |
| `incant/unitTests:263` | testRecurH | R | `x = argument + 100;` |
| `incant/unitTests:264` | testRecurH | R | `return argument;` |
| `incant/unitTests:268` | testRecurK | R | `return argument;` |
| `incant/utilities:17` | dumpField | R | `if datA != 0;   print $taG "=" argument:;` |
| `incant/utilities:19` | dumpField | R | `if argument.listLengtH;` |
| `incant/utilities:20` | dumpField | R | `for grup in argument;` |
| `incant/utilities:66` | displayIfVisible | R | `:argument x y width height;` |
| `incant/utilities:76` | displayIfVisible | R | `if goodToGo; print "OK to display" argument.taG; };` |
| `incant/utilities:124` | flatten | R | `for grup in argument; members` |
| `incant/utilities:137` | listRules | R | `listed  += argument;` |
| `incant/utilities:139` | listRules | R | `if datA != 0;   print ~$taG "=" argument;` |
| `incant/utilities:143` | listRules | R | `iterate grup on *argument;` |
| `incant/utilities:162` | toXML | R | `if datA; print ,"=" argument;` |
| `incant/utilities:164` | toXML | R | `for grup in argument; attributes` |
| `incant/utilities:169` | toXML | R | `for grup in argument; members` |
| `incant/utilities:195` | fillDownAcross | R | `direct  := argument.dIRECTion;` |
| `incant/utilities:196` | fillDownAcross | R | `target  := argument.tARGET;` |
| `incant/utilities:197` | fillDownAcross | R | `:argument target direct;` |
| `incant/utilities:199` | fillDownAcross | R | `for grup in argument; members` |
| `incant/utilities:211` | fillDownAcross | R | `for grup in argument; attributes` |
| `incant/utilities:213` | fillDownAcross | R | `for grup in argument; members` |
| `incant/utilities:216` | fillDownAcross | R | `for grup in argument; members` |
| `incant/utilities:221` | fillDownAcross | W | `clear(argument);` |
| `incant/utilities:222` | fillDownAcross | R | `argument += newStuff;` |
| `incant/utilities:232` | setFrame | R | `:argument across down width height x y;` |
| `incant/utilities:242` | setFrame | R | `fillDownAcross(argument);` |
| `incant/utilities:246` | setFrame | R | `fillDownAcross(argument);` |
| `incant/utilities:250` | setFrame | R | `for grup in argument; members` |
| `incant/utilities:286` | setFrame | R | `for grup in argument; members` |
| `incant/utilities:300` | setFrame | R | `for grup in argument; members` |
| `incant/utilities:343` | hexToNumber | R | `:argument rows columns bigRows bigColumns regularItem bigItem selRow selCol;` |
| `incant/utilities:373` | hexToNumber | R | `band <- argument :+ new(bandName);` |
| `incant/utilities:419` | hexToNumber | R | `rowBlock <- argument :+ new(rowName);` |

### A5. Not code -- prose, comments, strings, fixture headers: 374 lines in 65 files

- `incant/designDocs` 107
- `IncantForms/BackupXML/utilities` 39
- `IncantForms/BackupXML/generate` 31
- `incant/pop/kant8T` 21
- `IncantForms/WorkingOn/macros` 15
- `IncantForms/BackupXML/unitTests` 14
- `incant/jigcorpus` 9
- `IncantForms/Generating/genNotes` 9
- `incant/pop/jit/jitDfProbe` 8
- `incant/utilities` 8
- `IncantForms/Stash/incant` 6
- `incant/pop/holderT` 5
- `incant/decoder` 4
- `incant/pop/nestT` 4
- `incant/pop/recurSaveT` 4
- `incant/unitTests` 4
- `IncantForms/BackupXML/parser` 4
- `IncantForms/Controls/dev` 4
- `IncantForms/Notions/fonting` 4
- `IncantForms/Notions/issues` 4
- `IncantForms/Stash/types` 4
- `IncantForms/Windows/bigify` 4
- `incant/pop/jit/jitSlotT2` 3
- `incant/pop/parserTest` 3
- `IncantForms/LLVM/codeGenerator` 3
- `IncantForms/Notions/current` 3
- `IncantForms/Notions/view` 3
- `incant/pop/altShadowT` 2
- `incant/pop/chainTruthT` 2
- `incant/pop/jit/jitRecurSaveGT` 2
- `incant/setup` 2
- `IncantForms/BackupXML/incant++` 2
- `IncantForms/Stash/notes` 2
- `IncantForms/Tests/query` 2
- `IncantForms/WorkingOn/jitter` 2
- `IncantForms/WorkingOn/tester` 2
- `incant/pop/abandonT` 1
- `incant/pop/actionLocalT` 1
- `incant/pop/baselineTests.golden` 1
- `incant/pop/connectiveT` 1
- `incant/pop/dirT` 1
- `incant/pop/iterT3` 1
- `incant/pop/jit/jitJ3` 1
- `incant/pop/jit/jitJ6` 1
- `incant/pop/jit/jitJ7` 1
- `incant/pop/jit/jitJRt2` 1
- `incant/pop/jit/jitPrintT` 1
- `incant/pop/jit/jitRecurSaveT` 1
- `incant/pop/jit/jitSlotT4` 1
- `incant/pop/retProbe` 1
- `incant/pop/starIdiomT` 1
- `incant/pop/stopPreT` 1
- `incant/pop/truncLitT` 1
- `incant/pop/truncT` 1
- `IncantForms/BackupXML/macros` 1
- `IncantForms/BackupXML/setup` 1
- `IncantForms/Groups/stuff` 1
- `IncantForms/NotGUI/actions` 1
- `IncantForms/Notions/changes` 1
- `IncantForms/Notions/fungits` 1
- `IncantForms/Notions/instruct` 1
- `IncantForms/Stash/stuffDone` 1
- `IncantForms/Tests/filterList` 1
- `IncantForms/Tests/testing` 1
- `IncantForms/WorkingOn/incant++` 1
