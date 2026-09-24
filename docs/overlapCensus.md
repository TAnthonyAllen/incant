# Overlap census -- action writes vs parse reads

**2026-09-24.** Read-only recon for parse-then-fire step 1 (branch `parse-then-fire`, HEAD `58ab827`
plus the working-tree `unwrapReplay` diff). No build, no tok, no run. Every site below is cited from
**tok** source (`.twk`/`.rtn`) unless it is a passthrough block, and from **kant** only for
`IncantForms/WorkingOn/parser`. Line numbers were read in this session; `ruleActions.rtn` was edited
by someone else mid-census (a `measureKeywordDecision` line appeared at :11), so its numbers are the
post-edit ones.

**The shape being hunted:** the parse reads something an action writes (direction 1), or an action reads
something the parse writes (direction 2). Step 1 moves ordinary label actions from the fire to the
statement end, so every direction-1 line below is a place where the parse can now read a value the
action hasn't written yet. Every direction-2 line is a place where the action now reads the parse's
state at the statement's end instead of at its own fire.

Columns: `action | parse function | shared item | dir | can the action change so the parse no longer
depends on it? | write site ; read site`

---

## Direction 1 -- an ACTION writes, the PARSE reads

### Ordinary actions, kant rule actions (processAction/runAction), and their helpers

| # | action | parse function | shared item | dir | changeable? | write ; read |
|---|---|---|---|---|---|---|
| A1 | aCTionNamE | attachLabel -> `unwrapsOnAttach` | label `group` / `isGROUP` (attach the label, or its group) | 1 | **yes** -- the working-tree `unwrapReplay` re-asks the same predicate at replay; or NamE's resolution becomes a parse fact | ruleActions.rtn:668 ; GroupItem.twk:266 via :1954 -- **PLANT 1** |
| A2 | aCTionNamE | aCTionANYtoken (parse-deciding; its null fails the parse) | label `group`, then the resolved token's `registry == keyWords` and `noPrint` | 1 | **yes** -- ANYtoken could look `input.text` up in keyWords directly, without NamE's resolution. `measureKeywordDecision` (Generate.rtn:711) is already witnessing exactly that comparison | ruleActions.rtn:668 ; ruleActions.rtn:8, :12 (grammar `ANYtoken NamE@`, incant/grammar:115) -- **PLANT 2** |
| A3 | aCTionQuotE | attachLabel -> `unwrapsOnAttach` | label `group = opFields[body]` (a single-quoted operator) | 1 | yes -- the same fix as A1 | ruleActions.rtn:828 ; GroupItem.twk:266 |
| A4 | aCTionTokenXP (primary, leading-dot-number and generating arms) | attachLabel -> `unwrapsOnAttach` (`ExpressioN Token+`, max>1) | `xpress.group` | 1 | yes -- the same fix as A1. Live only where Token+ has no deferred ancestor, because a held TokenXP never writes it on trunk either | ruleActions.rtn:1060, :1066, :1078 ; GroupItem.twk:266 |
| A5 | handleUnary | attachLabel -> `unwrapsOnAttach` | `xpress.group = uxp` | 1 | yes -- the same fix as A1 | ruleActions.rtn:1549 ; GroupItem.twk:266 |
| A6 | aCTionParens, aCTionBraced | attachLabel -> `unwrapsOnAttach` | `input.group` | 1 | n/a -- **no live instance**: they're InvokeArg members with max 1, so the predicate can't fire | ruleActions.rtn:720, :90 ; GroupItem.twk:266 |
| A7 | aCTionBraced | checkInput (label reuse) | `label.fLAG` -- the "reuse this label" bit | 1 | yes -- the reuse bit could be owned by the parse alone (attachLabel's unwrap arm is its only other writer) | ruleActions.rtn:91 ; RuleStuff.twk:206-209 |
| A8 | every ORDINARY action (its return) | fireLabelMethod -> parse() / exitFromParse (sukcess, kount, attach) | the yield channel: a null `stuff.label` sets `sukcess = false` | 1 | unclear -- by protocol a null return fails the parse. Step 1 only traces it (`PTF NULLRET`). The actions that can return null are aCTionIterate (refuse), and processAction/runAction for a kant rule action (a processCode failure, a refusal, a body that yields null) | ruleActions.rtn:611, :618, :629; GroupActions.rtn:564, :920 ; GroupItem.twk:735, :739, :1349 |
| A9 | refuse() raised by an ordinary action: aCTionIterate, refuseLeadingDotNumber (from aCTionTokenXP), refuseDotUnaryRight (from interpretXP), runOP and op* refusals while a replayed statement executes, getMarkLineAt | runOP and aCTionBlocK **while running a generated parse body** (parseRule -> parseBlocK), where `if ruler.refused` returns null / breaks, so the `&&` chain fails | `ruler.refused` | 1 | yes, but it needs a ruling -- a statement-scoped refusal could stay off the parse road's dispatch | GroupActions.rtn:859 ; GroupActions.rtn:967, ruleActions.rtn:50 |
| A10 | aCTionStatemenT, runAction (via clearRefusal) | same readers as A9 | `ruler.refused` cleared | 1 | the clear that ends a refusal's reach is itself an action, and step 1 records StatemenT's LAST | ruleActions.rtn:988 -> :1274, GroupActions.rtn:919 ; GroupActions.rtn:967 |
| A11 | aCTionSearch (`search stack X`) | testContainer / parseContainer via `GroupItem::get` | registry `stakked` | 1 | yes, and it only bites between statements, never within one | ruleActions.rtn:928 ; GroupItem.twk:787, RuleStuff.twk:459, Generate.rtn:180 |
| A12 | processAction (kant rule action; also fireNewParse's CODE arm) | parseRule / parseLoop / parseContainer (face re-resolve `currentMETHOD.get(field.tag)`, parentRepair) | `currentMETHOD` | 1 | unclear -- it's bracketed, so only a rule invoked from INSIDE a kant action sees it | GroupActions.rtn:563, :597 ; Generate.rtn:237, :261, :275, :137, :166 |
| A13 | processCode (a coded action's first fire, reached from processAction/runAction/compile) | deferredAbove, checkSkip | `processingCode` | 1 | bracketed; the effect is confined to its own nested parse, but step 1 moves WHEN that nested parse happens | GroupActions.rtn:660, :666 ; GroupItem.twk:419, GroupRules.twk:194 |
| A14 | processCode | checkSkip | `lastIndent` (restored) and `blockSTAK` (**not** restored) | 1 | yes -- `blockSTAK` could join the bracket. It only matters in processingCode or defining mode | GroupActions.rtn:659/:667, GroupRules.twk:208 (nested checkSkip) ; GroupRules.twk:128, :220 |
| A15 | processCode | parseRule (`parseBlocK` / `parseHolder`) | the `BlocK` attached beside CodE on the holder | 1 | no -- this is compilation and has to precede the body's first run | GroupActions.rtn:664 ; GroupItem.twk:1382-1386, Generate.rtn:298 |
| A16 | driveStep / runRule (from aCTionRunRulE, and from runOP inside a replayed statement or a kant action) | parse(), checkInput, popInput, deferredAbove, ptfStmtAbove | `gParseActive` floor, `inputFloor`, pushInput state (`atRuleMark`, `sourceFILE`, `sourceLINE`, `inputSTAK`, `inputDiverted`); `lastIndent`/`defining` are restored | 1 | already bracketed, except for step 1's own globals (A17) | GroupActions.rtn:1147-1190 ; GroupItem.twk:418, :1363, Generate.rtn:479 |
| A17 | a parse DRIVEN from a replayed action (A16), writing through ptfRecord / ptfNoteAttach | ptfRecord / ptfStatementEnd of that nested parse | `gPtfRecs`/`gPtfN`/`gPtfAtt`/`gPtfAttN` -- zeroed by the outer replay before it runs actions, and **not** bracketed by driveStep | 1 | yes -- driveStep (or ptfStatementEnd) could save and restore them | Generate.rtn:572-590, :551-567 ; Generate.rtn:603-607 |
| A18 | aCTionStatemenT | aCTionFailed (called by parse() on notifyFail) | `lastStatement` | 1 | yes; same timing on trunk (StatemenT's own action) | ruleActions.rtn:983 ; ruleActions.rtn:479 via GroupItem.twk:1372 |
| A19 | a generic kant action body using an op on a RULE node (`:. deferred`, `+%` onto a rule, opSetFlag case 12 `fLAG`, opAssign) | the whole parse: rule shape, flags and rStuff | rule structure | 1 | unclear -- grammar on the fly is a feature | Instruct.rtn:1387 and the op* family ; GroupItem.twk:1339-1344, RuleStuff.twk:179-214 |

### Define family (aCTionDefinE / NewGroup / TraiT / TraiTdata and their helpers) -- exempt from step 1, listed anyway

| # | action | parse function | shared item | dir | changeable? | write ; read |
|---|---|---|---|---|---|---|
| D1 | aCTionTraiT, aCTionTraiTdata via modify / modifyClass / setLimits | parse, checkInput, attachLabel, testX, exitFromParse, parseLoop | rStuff `max/min/maxRepeat/limitsSet/noLabel/isTarget/noSkip/noAdvance/upTo/upToOver/banged` | 1 | no -- this is definition | GroupActions.rtn:498-514, :1493-1503 ; GroupItem.twk:1337, RuleStuff.twk:179, :202, :333-340, Generate.rtn:22, :25, :240-243 |
| D2 | aCTionTraiTdata | fireLabelMethod | `rStuff.actionMethod = null` | 1 | no | ruleActions.rtn:1161 ; GroupItem.twk:711, :723 |
| D3 | aCTionDefinE | getStuff, checkInput, parse, testOptions | `isRule`, new rStuff, the item's `parentStuff`/`parentLabel`, the member list, `currentRegistry`, `isCoded`/CodE | 1 | no | ruleActions.rtn:272-362 ; GroupItem.twk:1021-1030, :1339 |
| D4 | aCTionDefinE, aCTionTraiT, aCTionTraiTdata | attachLabel -> `unwrapsOnAttach` (`Attributes=TraiT+`, `definitions=DefinE+`, both max>1) | `input.group` | 1 | the plant-1 shape lives inside define too, but the class exemption hides it | ruleActions.rtn:373, :1142, :1179 ; GroupItem.twk:266 |
| D5 | aCTionSetBrackets | setTestMatch, testSet, parseSet, testContainer | `characterSet` | 1 | no | ruleActions.rtn:944 ; RuleStuff.twk:366-368, Generate.rtn:338 |

### Commands: processFlags, parseAction and immediateAction (exempt from step 1, listed as their own group)

| # | command | parse function | shared item | dir | changeable? | write ; read |
|---|---|---|---|---|---|---|
| C1 | processFlags `'D'` (the DEFINing parseAction) | checkSkip (indent rewrite to `:` and `>`) | `defining`; `lastIndent = 0` | 1 | no -- it fires inside the parse by design | Commands.rtn:577-578 ; GroupRules.twk:194-216 |
| C2 | processFlags `'d' 't'/'T' 'b' 'c' 'f' 'n' 'i' 'm'` (define-time attributes) | deferredAbove, fireLabelMethod/captureSpan, checkGuard/get, setTestMatch, parse (notifyFail), testAttributes | rule flags `deferred`, `tokened`, `isBIN`+`guardSet`, `isCondition`, `notifyFail`, `noPrint`, `isRule`, `isMacro` | 1 | no | Commands.rtn:567-603 ; GroupItem.twk:424, :718, :1372, RuleStuff.twk:162-167, :405 |
| C3 | compile | aCTionANYtoken (parse-deciding) | `compiling` | 1 | yes (A2's direct lookup would still read it) | Commands.rtn:76-83 ; ruleActions.rtn:12 |
| C4 | stopParsingInput (`stop`, `bail`) | parse, checkInput, popInput | `*atRuleMark = 0`, popInput | 1 | no | Commands.rtn:705, :711 ; RuleStuff.twk:175-187 |
| C5 | loadInputFromFile / getFile (`include`) | checkInput, parse, popInput | pushInput state | 1 | no -- same point on both engines (statement end) | GroupRules.twk:278-292 via Commands.rtn:253, :449 ; RuleStuff.twk:175, GroupItem.twk:1361-1366 |
| C6 | `parser` (kant generateParse/walkRules/compileRules), setParse, compile, `parseMethod=`/parkParse | parseRule, parseHolder, runLeafParse, testAction, runOP/driveStep (the hasNewParse door), fireLabelMethod (builtinActoR) | `builtinParseR`+CodE, BlocK, ParsE, `hasNewParse`, `isCodeD`, `rStuff.parseMethod`/`actionMethod`, `gMethod` | 1 | no -- these ARE the new road | IncantForms/WorkingOn/parser:38-45, Generate.rtn:417ff, Commands.rtn:49, :511 ; GroupItem.twk:1404-1408, :712, Generate.rtn:204-213, GroupActions.rtn:1170-1172 |
| C7 | guard | checkGuard, ensureGuard | `guardSet`/`guarded` | 1 | no | Commands.rtn:342 ; RuleStuff.twk:162-167 |
| C8 | rEGISTER (register, class, registry) | testContainer / parseContainer `get()` | registry membership (`currentRegistry` is read only by locate, which is action-side) | 1 | no | Commands.rtn:629-660 ; RuleStuff.twk:459 |
| C9 | traceParse | attachLabel, captureSpan, lit*, parseR, leaveRule/leaveAlt, measure* | `parseTrace` -- instrument only, changes output and nothing else | 1 | n/a | genParse.rtn (traceParse) ; GroupItem.twk:229, :299 |
| C10 | probeDrive (jitEmitters.rtn) | parse | `refused`, `divertToRule`, `inputFloor`, `lastIndent`, `defining`, pushInput -- bracketed | 1 | n/a | jitEmitters.rtn:722-747 |
| C11 | setMark / unMark / getLine (getMarkLineAt) / the opIN buffer arm / applyTextDirective | pushInput / popInput (they read Buffer `current`/`start`, never `mark`) | Buffer `mark` and the buffer's bytes (insertAtMark shifts them) | 1 | unclear -- this is an overlap only if the edited buffer is the live input | Instruct.rtn:594-603, :22-50 ; GroupRules.twk:252, :289 |

Not counted as overlaps (read, then ruled out):
- The parse-deciding actions: aCTionCodE writes `atRuleMark` (parse to parse); aCTionCheckFor and aCTionDEBUG write `debugAllRules`, which only setParseWalk reads (Generate.rtn:811-826, a command); aCTionShortcuT only reads.
- aCTionIterate's `iterator.fLAG` (:610/:617/:628): the iterator is a field, and checkInput reads `rStuff.label.fLAG` only.
- aCTionFOR/runAction/opLastREF write `lastREF`, and no parse-path function reads it.
- aCTionNewGroup writes `currentDefine`, which only actions and processFlags read.
- aCTionStatemenT writes `rStuff.sourceLine`, which no parse function reads.
- `divertToRule`, `endParse`, `noSkipping`, `lastSkip`, `beforeSkip` are write-only; a tree grep found zero readers.
- setMacroValue reads a sibling label's data (RuleStuff.twk:297), but the only `$` macro in the grammar (`tik` in QuotE) has no action, so it has no live instance.

---

## Direction 2 -- the PARSE writes, an ACTION reads

| # | action(s) | parse function | shared item | dir | changeable? | write ; read |
|---|---|---|---|---|---|---|
| B1 | every action that reads children by tag (`X:`, `input["X"]`, `input[1]`), plus processAction's `label[result.tag]` binding | attachLabel | label tree shape, including the promote retag `lab.tag = pStuff.ruleName` | 2 | no -- it's the contract | GroupItem.twk:236-237, :273 ; ruleActions.rtn:88, :496-500, GroupActions.rtn:572 |
| B2 | aCTionSearch, aCTionDEBUG (`rules?=NamE+`, `grup.setDebug()`), interpretXP, aCTionDefinE's walks | attachLabel's unwrap arm | children are resolved GROUPS (unwrapped) vs LABELS (placed whole) -- the consumer side of plant 1 | 2 | the fix is A1's | GroupItem.twk:267, :273 ; ruleActions.rtn:915-930, :229-239, :1570 |
| B3 | aCTionNamE, aCTionNumbeR, aCTionQuotE, aCTionSetBrackets, aCTionDEBUG, processFlags, rEGISTER (and the exempt ShortcuT, DelimText) | captureSpan, testMacro, testString, testUpTo, parseAny/Character/Set/String | label text/token | 2 | no -- it's the match | GroupItem.twk:312, RuleStuff.twk:338, :490, :551, Generate.rtn:76, :103, :352 ; ruleActions.rtn:650, :695, :823 |
| B4 | aCTionTokenXP/handleUnary (the UnaryOPS unary), aCTionIterate (`getLabelGroup("UnaryOPS")`), aCTionBrancH (`*BrancheS.tag`) | testContainer / parseContainer | `label.group` = the container entry | 2 | no | RuleStuff.twk:461, Generate.rtn:182 ; ruleActions.rtn:1542, :602, :115 |
| B5 | aCTionDelimText (exempt) | testUpTo | label text plus `label +% grup` | 2 | no | RuleStuff.twk:551-552 ; ruleActions.rtn:389-392 |
| B6 | aCTionDO/FOR/IF/WhilE/Xpress (yieldOrValue reads `input.deferred`); aCTionBlocK/runOP (dispatch held methods) | fireLabelMethod hold arm, replayed by ptfStatementEnd | `label.method`, `label.deferred`, text `"g"+tag` | 2 | step 1 replays holds in record order, which is equivalent unless a parse read comes between | GroupItem.twk:726-728, Generate.rtn:647-651 ; ruleActions.rtn:445, :551, :583, :1222, :1236 |
| B7 | processAction (resolves a label action's rule) | fireLabelMethod | `ruleSTUFF` | 2 | **handled** -- ptfStatementEnd sets it before each replayed fire | GroupItem.twk:714, Generate.rtn:657 ; GroupActions.rtn:554, :562 |
| B8 | processAction (`isLabel`), processCode (the D2 tripwire `isLabel && !rStuff`), aCTionStatemenT (`rStuff`), aCTionFailed | checkInput | `label.isLabel`, `label.rStuff` | 2 | no | RuleStuff.twk:207-210 ; GroupActions.rtn:562, :633, ruleActions.rtn:964-972, :475 |
| B9 | aCTionNamE (`action = currentMETHOD`; `result.parent == action`), aCTionScopeXP (adds locals to it), handleCall (the recursion stamp), locateInMethod, generateXP | parseRule (while a generated body runs) | `currentMETHOD` | 2 | yes -- NamE's check could be handed the rule instead of reading the global. At replay the global names StatemenT's enclosing rule, not NamE's | Generate.rtn:294, :308 ; ruleActions.rtn:647, :877, :1420, GroupControl.twk:125 |
| B10 | driveStep (the old-road attach target `gParseActive->stuff`), plus deferredAbove and ptfStmtAbove inside action-driven parses | parseRule (activation push/pop) | `gParseActive` | 2 | yes -- the replay could re-establish the recorded activation. At replay the top of the list is the StatemenT's, not the firing rule's | Generate.rtn:270-271, :321 ; GroupActions.rtn:1178, GroupItem.twk:418, Generate.rtn:479 |
| B11 | refuse() (`[line N]` in the message), aCTionStatemenT (the sourceLine stamp), aCTionFailed, reportCodeFail | checkSkip, pushInput, popInput | `sourceLINE`, `sourceFILE` | 2 | yes -- the stamp could be taken at record time | GroupRules.twk:142, :251, :286 ; GroupActions.rtn:858, :704, ruleActions.rtn:972, :477 |
| B12 | stopParsingInput, reportRunAbandoned, measureMarkPoint (in aCTionStatemenT), aCTionCodE (exempt) | checkInput, the leaves, parse | `atRuleMark` | 2 | no | RuleStuff.twk:179-187 ; Commands.rtn:711, ruleActions.rtn:1774 |
| B13 | aCTionFailed, reportDrive | parse() | `rStuff.failedAt` | 2 | no | GroupItem.twk:1368 ; ruleActions.rtn:475, GroupActions.rtn:1212 |
| B14 | aCTionBlocK, appendPrintXP, runAction, aCTionDefinE (refusalBoundary), aCTionStatemenT (clear) | parse-path refusals: checkInput (no enclosing activation), runLeafParse, parseAction, driveStep (no method), and runOP's unknown-operator arm while a generated body runs | `ruler.refused` | 2 | yes -- under step 1 a parse-time refusal now comes before EVERY action of its statement, not only the later ones | RuleStuff.twk:214, Generate.rtn:212, :48, GroupActions.rtn:1171 ; ruleActions.rtn:50, :1254, :377, :988, GroupActions.rtn:917 |
| B15 | aCTionTokenXP (the generating gate); aCTionPrinT clears it | processFlags `'P'` (the PRINTing parseAction) | `isPRINTING` | 2 | low -- only matters under generating | Commands.rtn:594 ; ruleActions.rtn:1052 (cleared at :810) |
| B16 | aCTionNamE (the virtual copyOf), guard, aCTionTell, statementMatches | processFlags `'D'` (DEFINing) | `defining` | 2 | exempt: NamE is class "define" while it's set | Commands.rtn:577 ; ruleActions.rtn:653 |
| B17 | aCTionDefinE (`addingMembers`) | processFlags `'M'` (the MEMBERs parseAction) | `currentDefine.addingMembers` | 2 | exempt (define) | Commands.rtn:591-592 ; ruleActions.rtn:284-285, :369 |
| B18 | aCTionBlocK and the loop actions (read `isBranch`) | parseRule | `result.isBranch = 0` on the body's returned node | 2 | no | Generate.rtn:307 ; ruleActions.rtn:53-60 |
| B19 | processCode, driveStep (save/restore) | parse() (end-of-input popInput) | `lastIndent` | 2 | benign | GroupItem.twk:1364 ; GroupActions.rtn:611, :1149 |
| B20 | kant actions that call a rule (runOP -> runRule -> truthOf) | exitFromParse (oneBitReturn `trueResult`), leaveAlt (`labelNO`) | the rule-call result | 2 | no | Generate.rtn:24-25, RuleStuff.twk:836 ; GroupActions.rtn:1098 |

**Counts:** direction 1 has **35** (A1-A19 ordinary, kant and helpers; D1-D5 define family; C1-C11
commands). Direction 2 has **20** (B1-B20).

---

## CROSS-CHECK

**Known-positive control: both plants are present.**
- **Plant 1 = A1**: attachLabel reads `lab.isGROUP` through `unwrapsOnAttach` (GroupItem.twk:266,
  :1954), and aCTionNamE writes it (`input.group = result`, ruleActions.rtn:668). The consumer side is
  B2 (aCTionSearch's `GrouP must be a registry`).
- **Plant 2 = A2**: aCTionANYtoken reads `input.group` and the token's `registry`/`noPrint`
  (ruleActions.rtn:8, :12), all of which NamE's action produces through `ANYtoken NamE@`.

The search reached both without being pointed at them: the first through the `.group =` writer grep
crossed with the attachLabel read, the second through the parse-deciding list crossed with the same
writer.

**Predicted plants for the unattributed step-1 movers.** These are candidates with grades, not findings.
None has been run.

| mover | candidate | grade | why |
|---|---|---|---|
| doWhileNameT DW-1: `dwN= Token` instead of 2 | **A17** -- the `DO(...)` drive runs INSIDE the outer statement's replay; its StatemenT/PrinT records land in globals the outer replay has just zeroed, and nothing brackets them | medium | The printed value `Token` is the **promote retag** (GroupItem.twk:237) of a TokenXP label whose action never ran. That is bear-trap #26's tag echo, and it points at a record that was never replayed (`PTF UNREACHED`/`DEADLABEL` under `PTF_TRACE=1` is the one-run check) |
| | **B6** -- the hold marks on DO's body are replayed at the inner StatemenT's end; the while-ExpressioN's terms are class `outside` and hold at parse | medium | the two halves of one DO are now marked at different times |
| | **B10** -- a drive started from a replayed action sees `gParseActive` = the StatemenT's activation | low-medium | old road in DW-1 |
| deferNatT `print s2L[1];` no longer prints `aa` | **B10** -- a replayed action's drive and deferredAbove read the StatemenT's activation, not the firing rule's (F-120's attach target) | medium | the rows are about exactly this list |
| | **A9/B14** -- a refusal raised by an action no longer silences the rest of the generated-body parse, or a parse-time refusal now precedes every action | low-medium | |
| | **A7** -- aCTionBraced's `fLAG` reuse bit is set at replay instead of at fire, so the next Braced checkInput mints or reuses differently | low | only one subscript in the drive |
| opIN directives buffer arm / replaceAt rows | **A13/A15** -- the directive actions' first-fire processCode (kant compile) moves into the replay, under a different `processingCode`/`gParseActive` context | medium | |
| | **C11** -- buffer `mark`/bytes edited by opIN / insertAtMark, if the edited buffer is also the live input (getFile pushes it) | low-medium | |
| | **B11** -- REFUSED/`[line N]` text in a pinned target moves, because `sourceLINE` is read at statement end | low | |
| | ✗ **A2 (plant 2)** ruled out for `IN`: `IN` is not in Keywords (incant/setup:243-262) | -- | |
| small count moves in loopVerdict | **A2 (plant 2)** -- keywords no longer rejected at ANYtoken, so repeated-term loops take a different number of turns | medium | |
| | **A9** -- refusals no longer silence runOP in generated bodies, so more term calls run | medium | |
| the deferredAbove tripwire's counts (`fires inside a drive`) | **A16/B10** -- drives launched from replayed actions start with a different activation list | medium | |
| | **A13** -- processCode's nested parse (the `end=processingCode` branch) happens at the replay | medium | note: the pinned `walk=chain inDrive=1` row is structurally zero (GroupItem.twk:418-429 takes the list walk whenever inDrive), so only the `_twt` total can move |

**Top candidates for the NEXT plant, beyond the two known:**
1. **A3/A4/A5** -- the same unwrap-predicate shape as plant 1, through QuotE and TokenXP/handleUnary (Token+). The working-tree `unwrapReplay` should cover them; certify each separately.
2. **A9 + B14** -- `ruler.refused` read by runOP/aCTionBlocK while a generated parse body runs, with refusals now arriving at the statement end.
3. **B10** -- `gParseActive` read by a replayed action's drive and by deferredAbove, when at replay it names the StatemenT's activation.
4. **A17** -- step 1's own record globals, which a parse driven from a replayed action writes into.
5. **B9** -- `currentMETHOD` read by aCTionNamE (and ScopeXP/handleCall) at replay, when it no longer names the generated rule that fired it.

---

## SEARCH POPULATION

**Files read in full or by function** (tok unless marked):
- GroupItem.twk: attachBlocK, attachLabel, captureSpan, deferredAbove, fireLabelMethod, get, getStuff, parse, parseBlocK/Body/Holder, unwrapsOnAttach.
- RuleStuff.twk:1-600 (class fields, constructors, checkGuard, checkInput, getWhatFollows, setTestMatch, setMacroValue, testMacro, testAny/Character/Set/Action/Attributes/Condition/Container/Options/String/UpTo, lit), :755-960 (inGuard, leaveRule, leaveAlt, parseR, JSON helpers).
- GroupRules.twk (the whole file: globals, checkSkip, popInput, pushInput).
- Generate.rtn:1-720 (exitFromParse, parseAction, parseAny, parseCharacter, parseCondition, parseContainer, runLeafParse, installParseMethod, parseLoop, parseRule, parseSet, parseString, parseUpTo, setParse, and all the ptf*/measure* step-1 code).
- ruleActions.rtn (the whole file, every aCTion* and helper).
- GroupActions.rtn: appendGroup, processAction, processCode, restoreLocalFields, refuse, runAction, runOP, driveStep, reportDrive, runRule.
- Commands.rtn: processFlags, stopParsingInput, fireNewParse, compile (by grep).
- Instruct.rtn: getMarkLineAt, opIN, truthOf.
- GroupControl.twk: locate, locateInMethod.
- GroupMain.twk: the bootstrapper (DEFINing, MEMBERs).
- genParse.rtn:1400-1480 (parseViaKant).
- **kant**: IncantForms/WorkingOn/parser (the generator), incant/grammar, incant/setup:1-140 and :240-262.
- The fixtures incant/pop/doWhileNameT and incant/pop/deferNatT, and genLadder/pop.sh's rows for the movers.

**The cross-reference instrument.** A script (in the session scratchpad, not in the tree) assigns every
line of the files below to its enclosing function, then classifies each mention of a name as a write
(`=`, `++`, `--`, `+=`, `-=`, `+%`) or a read:

`GroupItem.twk RuleStuff.twk GroupRules.twk Generate.rtn genParse.rtn ruleActions.rtn GroupActions.rtn
Commands.rtn Instruct.rtn GroupControl.twk GroupBody.twk GroupMain.twk Debug.rtn Bytecode.twk measure.twk`

It was run over:
- every GroupRules global (`atRuleMark lastREF currentMETHOD currentDefine currentRegistry defining
  processingCode compiling generating jitting isPRINTING refused lastIndent ruleSTUFF searchList
  lastStatement sourceLINE sourceFILE inputDiverted inputFloor inputSTAK blockSTAK bufferSTAK skipSet
  debugAllRules debugGuards parseTrace endParse divertToRule noSkipping lastSkip beforeSkip stringBUFFER
  labelNO keyWords opFields grokking rulesParsed ruleSkipSet isRigorous ignoreThis tempField generator
  failedAt hereAt`);
- every RuleStuff field (`label sukcess kount parentStuff parentLabel max min maxRepeat limitsSet isOK
  inProcess guardOK followed onGroup onFail isTarget noAdvance noLabel noSkip hasMacro actionMethod
  parseMethod testMatch notifyFail banged doNothing isOption upTo upToOver sourceLine termCount ruleName
  rStuff`).

The writer set was then crossed against the parse-function set named in the brief (plus checkGuard,
getWhatFollows, setTestMatch, the lit* family, leaveRule/leaveAlt, parseR, pushInput/popInput, driveStep,
fireNewParse, parseViaKant and the ptf* functions).

**Two whole-tree control greps for the label-flag writers** (quoted globs, BeforeSave/Aside/Backup
excluded):
- `grep -rn --include='*.rtn' --include='*.twk' -E '\.fLAG *= *(true|1)|\bfLAG *= *(true|1)' .`
- `grep -rn --include='*.rtn' -E '^\s*(input|xpress|xpList)\.group *=' .`

Both returned the populations above; the second's 13 hits are A1-A6, D4, B2's generating arms, and
interpretXP/generateXP (whose ExpressioN term is max 1, so their unwrap cannot fire).

**Why an absence would have been found.**
- Direction-1 writers: every writer of a label or rule flag outside the parse functions lives in
  `ruleActions.rtn`, `GroupActions.rtn`, `Commands.rtn` or `Instruct.rtn` (the only files holding
  `aCTion*`, commands or `op*`), and all four were in the xref population.
- Parse readers: every parse function the brief lists lives in `GroupItem.twk`, `RuleStuff.twk`,
  `Generate.rtn`, `genParse.rtn` or `GroupRules.twk`, all in the population. The generated parse
  bodies are kant `&&`/`||` call chains (IncantForms/WorkingOn/parser:28-36), so their only runtime
  readers are runOP/handleCall/aCTionBlocK/driveStep, which were read directly.
- The known-positive pair (plants 1 and 2) came out of this population unprompted.

**What the population does NOT cover, named so no absence is over-read:**
- Hand-written C++ in `.h` files, except `jitContext.h`'s ptf and `gParseActive` state, which was read.
- `jitEmitters.rtn` beyond the probeDrive block, because the jit road is not the parse road.
- The GUI/ tree.
- `/* */` comments. The xref only strips `//`, so some hits were comments; every row above was checked
  by eye against its source line.
- Semantic writes through a field's contents (`lastREF.gGroup = ...`) are scored as reads by the xref.
  lastREF was therefore traced by hand; it has no parse reader.

**Bookkeeping.** At read time GroupRules.mm and GroupRules.h were modified in the working tree. The
`measureKeywordDecision` line visible in the `.mm` corresponds to a `ruleActions.rtn:11` passthrough that
appeared during this session, so the `.mm` follows its source and is not a directives build.
