# Cleanup census -- "what is it for?" (2026-10-06, read-only)

Dispatch: clay-to-clod cleanup census, Tony's rulings 2026-10-06. **R1: nothing here was cut, moved or respelled.** Tony rules
each line afterwards, on a clean kitchen; he rules the FLAG rows and the SECOND MEANING rows first, the rest waits for the
cleanup days. **R2: out of scope** -- interpretXP, aCTionTokenXP, foldDot, handleDot/Call/Subscript/Unary, runOP,
runShortCircuit and their jit emitters (the expression recon owns them); a field whose readers are only there is marked
**expression-owned** and not analysed. Expression emitters (Binary, Compare, Unary, Dot, Deref, BareRead, ShortCircuit,
OpFire, Assign, TermCall, SelfCall, ...) count as expression-owned; statement emitters (DO, WHILE, GIF, Iterate, IterStep,
Return, Continue, RefusedCheck, Print*) count as engine.

**How it was measured.** Five read-only passes over trunk at `cb842b4` (stroke 1.4 merged): every member's reads and writes
counted in the top-level generated `.mm` (comments and strings stripped; constructor zero-inits and push-site inits are not
writers), split **E** engine / **M** `measure.mm` instruments / **X** expression-owned; kant exposure checked against
`incant/setup`'s GroupFields (opDot / setGroupField cases) and the pROPERTIEs registry. Counts are grep counts of sites, not
executions. **(inferred)** marks what was read but not run.

---

## FLAGS FOR TONY -- the purpose is not obvious from the code, or the code and its comments disagree

Each answer becomes the member's slug comment.

| member | what is unclear |
|---|---|
| RuleStuff.ruleName | Slug says "no engine code reads it" (today's R2), but `reportMaxLimit`'s ungated REFUSED message prints it (GroupRules.mm:9812). A message read, not a decision |
| RuleStuff.max / maxRepeat | Two repeat caps set together by `modify`; the old road's `parse()` loops on `maxRepeat`, the new road's `parseLoop` on `max` |
| RuleStuff.isTarget | Two independent writers (getWhatFollows on the old road, setTargetFlag on the new; measureTargetAgree compares them); only ever set, never cleared |
| RuleStuff.modPercent / modPointer | No engine reader at all -- only `measure`'s modsOf and fixture omModT. What are they for? |
| RuleStuff.noLabel | Its upToMatch use (skip-count mode, below) is documented nowhere |
| ParseActivation.label | Three meanings share the slot (below) |
| ParseActivation.failPoint | Meaningful on floors only; call records write 0; jitProbeDrive never initialises it |
| GroupItem.labelOf, ruleOf | No declaration comments; purpose only from comments elsewhere (mintLabel, the copy ctor) |
| GroupItem.parent | Overloaded (six other uses, below) |
| GroupItem.nextInParent / priorInParent | `sort()` reads `this`'s links where it means `current`'s (:2467, :2471); `sort()` has no callers |
| GroupItem.options.affiliation | No constructor sets `options`; the copy ctor's comment says "the affiliation remains the same" but it is not copied (whether memory starts zeroed depends on the allocator -- not traced); properties are marked isAttribute |
| GroupBody.gMethod | On a rule body it holds the PARSE executor (setParseWalk installs parseLoop / gParseMethod into it), not an action |
| GroupBody.gCount | Also the string/token length, the GroupFields field number, and the JIT frame-slot key |
| GroupBody.noPrint | Three uses: print suppression, artifact/decoration marker, define-command marker (aCTionDefinE:438) |
| GroupBody.fLAG | Three or four meanings (below); objectModel ledgers two |
| GroupBody.actionType | addGroup reads it as an ordering switch (`isSorted \|\| actionType` -> put) |
| GroupBody.byRef | Commit 9244bc3 says byRef's loop steering retired, but aCTionFOR still reads it (635, 669); its only writer is kant `byReF` |
| GroupBody.debugged | opDot's comment says "no reader anywhere"; setDebug reads it (toggles only) |
| GroupBody.debugGuard | Purpose not derivable; written by aCTionDEBUG and guard, never read |
| GroupBody.isInitialized | Written at 23 sites, never read |
| GroupBody.isPointer | Two meanings: "gPointer valid" and a string-cursor switch in opMinusMinus (7930) |
| GroupBody.isSingleton | Ctor sets 1, addMember/merge clear it, nothing reads it |
| GroupBody.reversePrint | No writer; appendGroup prints REVERSED when it is 0 -- the name is inverted against the behaviour |
| GroupBody.hasNewParse | setGroupField's comment calls it "the artifact gate"; the code raises it whenever gMethod or gParseMethod is set |
| GroupRules.ruleSTUFF | Reputation "the singleton handed to processAction" is false: written by fireLabelMethod, read only by measureFrameProbe |
| GroupRules.currentMETHOD | objectModel:265 parks "readable from kant" as undispatched, but it is already in pROPERTIEs (GroupControl:270) |
| GroupRules.tempField | processAction saves and restores it, but nothing ever replaces the pointer -- the restore is inert |
| GroupRules.trueResult | GroupControl:146 first assigns it the fieldBUFFER item, then :148 overwrites it with "true" |
| GroupRules.branchKind | GroupRules.twk:73-78 still says "INERT ON TRUNK"; it is live (18 readers, 24 writers) |
| GroupRules.refused | clearRefusal claims to be "THE SINGLE WRITER of refused = 0"; jitProbeDrive also writes 0 and jitBuildFunction stores 0 through `&refused` in IR |
| GroupRules.compiling | A second compile signal beside the floor-derived `inCompile()`; compileIn/processCode do not set it (inferred) |
| GroupRules.debugAllRules | CLAUDE.md says "trace all rule matching"; its only readers are setParseWalk's install-walk diagnostics |
| GroupRules.debugGuards | CLAUDE.md says "show guard evaluation"; nothing reads or writes it |
| GroupRules.printSPACE | No engine use (pROPERTIEs only) |
| GroupRules write-only / dead members | debugJunk, divertOutput, punctuateSet, shortcutSet, rulesParsed, beforeSkip, lastSkip, formatBUFFER, divertToRule, endParse (and its comment's order is backwards, 10619-10627), ignoreThis, ignoreNoPrint, ignoreNoRoom, isPERCENT, isPRINTING, isRELATIVE, isRigorous, noSkipping, showWarnings -- see ZERO |
| jit globals, comment vs code | gJitResult (comment says jitRunAction reads it; it only nulls it), gJitEmitted (comment names the wrong setter/resetter), gProbe* ("for an lldb driver"; read by probeDrive/probeSweep), gJitPrintBuf (names a function that does not exist), gJitLastIsNode (six more raisers than stated), gJitStmtCanRefuse (jitEmitOpFire also raises it), gScEndBlocks/gScSlots and gJitInlineFrames (not cleared by jitFlushTransient, inferred), gJitFieldResident (never cleared, inferred) |
| docs | CLAUDE.md:2644-2661 describes `gNoUnwrap` as a live static -- it no longer exists; jitContext.h:667 says gCompileOwner "moved to GroupRules" -- GroupRules has no such member |

## SECOND MEANINGS -- a reader using a field for something other than its stated purpose

| member | the other meaning, and where |
|---|---|
| RuleStuff.max | Shape test: `max == 1` = single-valued so a target (getWhatFollows RuleStuff.mm:471, setTargetFlag 10570, embedAttribute GroupItem.mm:780); `max > 1` = repeating, attach as attribute / a loop (attachLabel 460, exitFromParse 2341, repeatsInLoop 9746); `max != 1 \|\| min != 1` = mint a fresh RuleStuff (aCTionDefinE 519) |
| RuleStuff.min | `min != 0` read as "required term" while building the guard set (ensureGuard GroupItem.mm:852, 869, 895) |
| RuleStuff.noLabel | `noLabel && isCOUNT(data)` switches upToMatch into a skip-count mode (RuleStuff.mm:301) |
| ParseActivation.label | A floor parks the drive root's label (driveFloorLabel 2091, read by driveStep 2174); a child's label is written into the PARENT's record (parkInRecord 8710, exitFromParse 2325); testAction uses `!label` as a switch (RuleStuff.mm:53) |
| GroupItem.labelOf | Non-null = "this parse owns the node, a retag is allowed" (attachLabel 426, exitFromParse 2327) |
| GroupItem.ruleOf | Non-null = "is a copy" (setRuleStuff 2393, aCTionDefinE 467, aCTionTraiTdata 1402, setParseWalk 10470) -- the retired options.isCopy |
| GroupItem.parent | Accessor-product back-pointer (opDot 7449 writes, accessorWriteValue 1535 reads); embedRule parents a copy held in the group slot, not a list (796); the real target of an fLAG node (processFlags 9463, rEGISTER 9573); the parent's TEXT as a sort key (compareAttribute 37); the notifier chain (dispatcher 2050-2053) |
| GroupItem.nextInParent / priorInParent | Also thread the property list (addProperty, getProperty, removeProperty) |
| GroupItem.rStuff | On a minted label it is the RULE's RuleStuff (a lawful borrow, RuleStuff.mm:510) |
| GroupItem.options.affiliation | Properties are marked isAttribute (addProperty 331); aCTionFOR compares it with a raw int (633) |
| GroupBody.tag | Its first letter is a command opcode (processFlags `switch(*command)` 9461; ruleMethod `*tag=='r'` 9963) and the guard character (GroupItem.mm:293, 836, 874, 880, 1491) |
| GroupBody.groupList | aCTionIterate points the iterator's list at the source's own (789) -- an alias |
| GroupBody.registry | `registry == groupFields` classifies a token as an accessor name (1533, 7231, 8575, 9716); `== keyWords` marks keywords (39, inferred) |
| GroupBody.guardSet | ensureGuard merges a member's set into the parent's while parsing (924) -- a rule fact written outside definition |
| GroupBody.gMethod | Holds the parse executor on rule bodies (setParseWalk 10517-10518; driveStep 2155/2160 and jitProbeDrive call it as the parse; setRuleAction copies it into gParseMethod 10552) |
| GroupBody.gOp | Compared by pointer with `&opSetGroup` / `&opRebind` to identify the operator (refuseArgRebind 9635) |
| GroupBody.gTestMatch, gParseMethod | Compared with functions as classifiers (parse 1737 `== testAny ...`; repeatsInLoop 9746 `== parseRule`) |
| GroupBody.gText | A string cursor (`gText++/--` in opPlusPlus 8411, opMinusMinus 7932); aCTionDefinE strips a macro brace (499); text left behind on a group holder is read by opGet (7564) |
| GroupBody.gPointer | fAIL's `setPointer(0)` on a method node zeroes gText through the union (2367, inferred) |
| GroupBody.gBuffer | getCount returns the buffer length (1178) |
| GroupBody.gCount | String/token length (setText 2429, setToken 2446, getText 1373, ++/--, aCTionDefinE 500); GroupFields selector (opDot 7243, opSetFlag 8611, accessorWriteValue 1535); its address is the JIT frame-slot key (3333, 6063, 6224, 6243) |
| GroupBody.gNumber | copyData copies it to carry the whole 8-byte union (603, inferred); its address is a JIT frame key (3332, 6224, 6236) |
| GroupBody.gGroup | lastREF's gGroup is written directly, bypassing setGroup (aCTionFOR 637/671, opLastREF 7742, ++ 8373, -- 7901) |
| GroupBody.gStak | On a frame node, the local-save stack (10220-10224, 9941) |
| GroupBody.noPrint | Artifact/decoration marker (addAttribute 252, setParseWalk 10510, dupTermRefusal, jitBuildFunction 3200/3328, saveLocalFields, parseRule, processAction); define-command marker (`noPrint && immediateACTION`, aCTionDefinE 438); keyword visibility (aCTionANYtoken 39) |
| GroupBody.fLAG | (a) "run as a define attribute, target = parent": aCTionDefinE 447/449 writes, processFlags, rEGISTER, opPointer, guard, fAIL, listenTo, loadDirectory, markWindow, ruleMethod, jitEmitter read; (b) poisoned iterator: aCTionIterate writes, opPlusPlus reads; (c) braced expression: aCTionBraced writes, aCTionTokenXP reads (X); (d) attachLabel sets it on a cleared promoted label (465) -- no reader found for that meaning |
| GroupBody.actionType | Ordering switch in addGroup (284) |
| GroupBody.hasAttributes / hasMembers | Iterator filter selectors: aCTionIterate writes them on the ITERATOR (799-803), opPlusPlus reads (8362, 8365) |
| GroupBody.isPointer | String-cursor switch in opMinusMinus (7930) |
| GroupRules.atRuleMark | stopParsingInput writes through it to NUL-terminate the input (10626) |
| GroupRules.tempField | Handed to the JIT as the dot/rem result node (opDot 7212, opRem 8483) |
| GroupRules.trueResult | Briefly holds the fieldBUFFER item (GroupControl:146); a non-null local marker in aCTionDEBUG (296/301) |
| GroupRules.falseResult | The null-print stand-in (printField 9147); handleCall's placeholder operator (X) |
| GroupRules.lastREF | aCTionFOR's loop-element binding, saved and restored around the loop (628-674) |

---

## PART A -- one row per member

Columns: purpose (from the code) · readers E/M/X (kant exposure) · writers · ZERO. FLAG and SECOND MEANING are gathered above.

### RuleStuff (16 members: 5 + 11 bits)

| member | purpose | readers | writers | ZERO |
|---|---|---|---|---|
| ruleName | Debug name: tag of the node it was built for; a struct copy keeps the source's | E 5 (2 parseTrace-gated, 1 reportMaxLimit), M 2 | ctor; struct copies only | no post-ctor writer |
| onGroup | Group a group-valued term parses next (set by getWhatFollows on isGROUP) | E 3 (parse) | 3 (getWhatFollows; embedAttribute x2 resets) | -- |
| max | Repeat cap (`+`/`*` set maxLimit); bounds leaf loops and parseLoop | E 19, M 1 | 2 (modify) | -- |
| maxRepeat | Loop bound for the old road's parse() repeat loop | E 4 | 2 (modify) | -- |
| min | Minimum match count | E 14, M 1 | 2 (modify) | -- |
| followed | Lazy latch: getWhatFollows has run | E 1 (getStuff), M 2 | 4 | -- |
| isTarget | This term's label is promoted into its parent (attachLabel) | E 2, M 2 | 5 | -- |
| modPercent | The `%` modifier on the instance | M 1 | 1 (modify) | **no engine reader** |
| modPointer | The `&` modifier on the instance | M 1 | 1 (modify) | **no engine reader** |
| modUnGuarded | Instance-level unguarded (`_ { }`), via isUnGuarded() | E 1 (+3 via isUnGuarded), M 1 | 3 (modify) | -- |
| noAdvance | `<`: the match does not consume input | E 7 | 1 | -- |
| noLabel | `-`: mint or attach no label | E 4; kant `noLabeL` (28) R | 1 | -- |
| noSkip | `^`: do not skip skipSet characters first | E 2 (inputAt); kant `noSkiP` listed, no case (unwired, inferred) | 1 | -- |
| notifyFail | On failure, call aCTionFailed with this call's own point | E 1 | 1 (processFlags `f`) | -- |
| overTo | upTo mode (`{`=1, `}`=2), asked first by parse/runLeafParse/driveStep | E 8 (3 macro uses) | 2 | -- |
| ruleTerm | "I take part as a rule term", ORed with the body's isRule in isRuleTerm() | E 1 (+15 via isRuleTerm); kant `isRulE` (23) | 3 | -- |

### ParseActivation (6 fields; no constructor -- every push site sets each field)

| member | purpose | readers | writers | ZERO |
|---|---|---|---|---|
| instance | The field this call runs; 0 on a floor; its stuff is `stuffOf()` | E 12, M 1 | 5 (push only) | no writers after push |
| isFloor | Marks a drive / top-level floor; walks stop there | E 12, M 1 | 5 (push only) | no writers after push |
| compileOwner | On a compile's floor, the owner being compiled (floorOwner -> inCompile) | E 1 | 5 (push; only driveStep can be non-zero) | no writers after push |
| label | The label this activation hands back | E 30, M 6 | 13 (5 push + 8) | -- |
| prev | Link to the activation below | E 22, M 1 | 5 (push only) | no writers after push |
| failPoint | Root failure point, written only on a floor, handed to reportDrive | E 1 (driveStep) | 6 (4 push + 2) | -- |

### GroupItem (9 members)

| member | purpose | readers | writers | ZERO |
|---|---|---|---|---|
| groupBody | Pointer to the (possibly shared) body; a copy shares its source's | E 1592, M 166, X 110 | ctor only (pointee overwritten wholesale at 1852, 9948) | no post-ctor writer |
| labelOf | On a minted label, the rule it was minted for | E 11 | 2 (mintLabel, parseRule) | -- |
| ruleOf | On a copy, the ORIGINAL (never an intermediate copy) | E 12, M 3 | copy ctor only | **no writer outside the ctor** |
| parent | Owner whose groupList or propertyList holds the node; kant `parenT` R | E 81, M 7, X 1 | 12 | -- |
| nextInParent | Forward sibling link; kant `nexT` (401) R | E 33, M 2 | 13 | -- |
| priorInParent | Backward sibling link; kant `prioR` (402) R | E 17 | 13 | -- |
| rStuff | The node's RuleStuff, created lazily | E 6 + 87 via getRStuff(), M 15 | setRStuff (14 call sites, 2 with null) + copy ctor | -- |
| jitData | Per-node JIT state (jitValue, jitSlot), seeded per compile | E 7, X 32 | E 6, X 2 | (readers mostly expression-owned) |
| options.affiliation | Attribute (1) / member (2) / embedded (3); kant `isAttributE`/`isMembeR` R | E 37 | 14 | -- |

### GroupBody -- data members

| member | purpose | readers | writers | ZERO |
|---|---|---|---|---|
| tag | The node's name; kant `taG` (1) R | E 238, M 79, X 7 | 6 | -- |
| propertyList | Rule artifacts and properties, apart from the terms (stroke 3) | E 20 | 1 (lazy new) | -- |
| groupList | The child list; kant `listLengtH`/`firsT`/`lasT`/`firstMembeR` | E 128, M 14, X 13 | 9 | -- |
| registry | The registry/class the definition sits in; kant `registrY` (3) | E 37, M 3, X 4 | 6 | -- |
| guardSet | Guard characters of a bin or rule | E 23 | 11 | -- |
| gMethod | The node's action / command / method function | E 47, M 4, X 16 | 1 direct (setMethod; 33 calls) | -- |
| gOp | Binary operator binding | E 3, X 1 | 1 (setOperat) | -- |
| gJitEmitter | JIT emitter slot, beside the gMethod/gOp union | E 1, X 1 | 1 | -- |
| gTestMatch | Old-road match test for the rule's shape (stroke 1.4) | E 7 | 9 (setTestMatch) | -- |
| gParseMethod | New-road parse executor (stroke 1.4) | E 6, M 4 | 12 | -- |
| gJitMethod | Cached native function for a definer's action (stroke 1.4) | E 5 (jitFieldMethod) | 1 | -- |
| gText | String/token text (gCount its length); kant `texT` (4) | E 21 + ~109 getText | 7 + 56 setters | -- |
| gPointer | Raw void* payload (GUI CGContext, Stylish) | E 1 (+5 getPointer) | 1 (+4) | -- |
| gBuffer | Buffer payload | E 3 (+22) | 1 (+4) | -- |
| gCharacter | Single-char payload | E 2 | 1 | -- |
| gCharacterSet | PLGset payload | E 2 (+11) | 1 (+14) | -- |
| gCount | int payload | E 44 + 4 address, M 3 (+40 getCount) | 14 (+51 setCount) | -- |
| gGroup | Held group reference | E 20 (+49 getGroup) | 8 (+42 setGroup) | -- |
| gItem | PLGitem payload | E 2 | setItem's body only -- **setItem has 0 callers** | **no writers** |
| gMap | BitMAP payload | none | 1 (makeDataType) | **no readers** |
| gNumber | double payload | E 9 + 3 address | 8 (+12) | -- |
| gObject | NSObject payload (GUI) | E 1 (+5) | 1 (+3) | -- |
| gRegex | PLGrgx payload | none (no getRegex exists) | 1 (setRegex) | **no readers** |
| gStak | Stak payload | E 3 (+5), M 2 | 1 (+2) | -- |

### GroupBody -- flags (44)

| flag | purpose | readers | writers | ZERO |
|---|---|---|---|---|
| isRule | Rule or rule term; kant `isRulE` via isRuleTerm | E 17 (+16), M 7 | 8 | -- |
| isLabel | A minted parse label | E 5, M 3 | 2 | -- |
| noPrint | Hide from print; kant `noPrinT` RW | E 29 | 26 | -- |
| invoke | Expression node is a call; kant `invokE` | E 1 (opDot 11), X 7 | X 13 | **expression-owned** |
| fLAG | Generic bit | E 12, M 1, X 1 | 8 | -- |
| data (5 bits) | Value-kind enum; kant `datA`, `isGrouP` | E 285, M 15, X 7 | 37 | isANY, isMAP, isREGEX: 0 macro uses |
| actionType (2) | isAction / isCoded; kant `isCodeD`, `actionTypE`, `isActioN` | E 13, M 3, X 2 | 6 | -- |
| binType (3) | BIN / CLASS / LIST / REGISTRY; kant `isBiN`, `isLisT`, `binTypE` | E 49, M 2 | 9, X 1 | -- |
| fileType (2) | File / dir / exec data kind | E 2 | 1 | isDirectory, isExec: 0 uses |
| guarding (2) | guarded / unGuarded / guardInProcess | E 13 (+3), M 1 | 21 | (modify no longer writes it -- F-O8 is stale) |
| instructType (2) | isMethod / isOperator; kant `isMethoD`, `isOperatoR` | E 18, M 6, X 16 | 13 | -- |
| isSorted (2) | Sort order of a list or registry | E 5 | 6 | -- |
| methodType (2) | immediateACTION / parseACTION | E 7, M 1 | 15 | -- |
| addingMembers | Define in progress: MEMBERs active | E 2 | 2 | -- |
| altered | A list's stak cache is dirty | E 6 | 3 | -- |
| byRef | FOR leaves lastREF alone; kant `byReF` W | E 2 | 1 (kant only) | -- |
| debugged | Debug toggle; kant `debuggeD` R | E 6 (3 self-toggles) | 3 (toggles) | no consumer beyond toggling |
| debugGuard | -- | none | 3 | **no readers** |
| deferred | Statement deferred (`d`) | E 7, M 1 | 2 | -- |
| hasAttributes | Has attributes; kant `hasAttributeS` | E 7, M 1 | 9 | -- |
| hasListeners | Value changes notify listeners | E 13 | 1 | -- |
| hasMembers | Has members; kant `hasMemberS` | E 18, M 1, X 1 | 10 | -- |
| isArgument | Rule-action argument slot; kant `isArgumenT` | E 9, X 1 | 1 | -- |
| isCondition | Rule is a condition (`c`) | E 4 | 1 | -- |
| isIndexed | A bin numbers members by position | E 1 | 1 | -- |
| isInitialized | Has had a value set | none | 23 | **no readers** |
| isIterator | An iterate cursor | E 3, M 1 | 1 | -- |
| isLiteral | Literal number or quote; kant `isLiteraL` | E 9, X 1 | 3 | -- |
| isLocal | Action-local field; kant `isLocaL` | E 9 | 8 | -- |
| isMacro | Macro definition (CodE becomes text) | E 3 | 2 | -- |
| isPercent | Print a count with `%`; kant `isPercenT` W | E 1, M 1 | 1 (kant only) | -- |
| isPointer | gPointer holds a valid pointer | E 4, M 1 | 2 | -- |
| isShortcut | Print-shortcut node; kant `isShortcuT` | E 4 | 1 | -- |
| isSingleton | -- | none | 4 | **no readers** |
| isUnary | Op is unary (`u`) | E 1, X 1 | 1 | -- |
| isVirtual | Define-time virtual field, copied on use; kant `isVirtuaL` W | E 3, M 2, X 1 | 3 | -- |
| isWindow | Form is a window | none | 1 | **no readers** |
| mergeOn | Two-sided attribute merge; kant `mergeON` W | E 4 | 2 | -- |
| reversePrint | List print order | E 1 | none | **no writers** (forward branch dead, inferred) |
| tokened | The rule's text is tokened | E 1, M 1 | 4 | -- |
| hasNewParse | A new-road parse method is installed; kant `hasNewParsE` RW | E 7, M 4, X 1 | 3 | -- |
| parseWalked | setParseWalk's visited mark | E 2 | 2 | -- |
| hasTraits | Has a non-noPrint attribute; kant `hasTraitS` | E 5 | 4 | -- |
| isAccessorProduct | opDot's copy of a group field, so `=` writes the field | E 3 | 1 | -- |

### GroupRules members (excluding ParseActivation's fields)

| member | purpose | readers | writers | ZERO |
|---|---|---|---|---|
| gParseActive | Head of the activation list | E 35, M 6 | 10 (push/pop pairs) | -- |
| atRuleMark | Parse cursor into the input | E 65, M 1 | 27 | -- |
| ruleSTUFF | Last RuleStuff handed to fireLabelMethod | M 1 | 1 | **no engine reader** |
| currentDefine | Group being defined (MEMBERs sets addingMembers) | E 8 | 2 | -- |
| currentMETHOD | Holder whose gGroup is the current action; pROPERTIEs | E 12 | 1 (+6 setGroup) | -- |
| currentRegistry | Registry new definitions go into | E 17 | 2 | -- |
| baseRegistryList | Base registries searched by locate | E 5 | 1 | -- |
| commands / files / grokking / groupFields / keyWords / opFields / properties / registries | The named registries | E 7 / 1 / 5 / 8 (2 X) / 7 / 22 (8 X) / 16 / 17 | 1 each | files: read only at setup |
| falseResult / trueResult | The false / true nodes; pROPERTIEs | E 19 / E 72, M 3 | 1 / 2 | -- |
| inDENT | Tab depth for appendGroup's `~`; pROPERTIEs "indenter" | E 7 | 1 | -- |
| labelNO | "Succeeded, yields nothing" sentinel; pROPERTIEs | E 12 | 1 | -- |
| lastREF | "What was referenced last" holder; pROPERTIEs | E 18 | 1 (+ gGroup writes) | -- |
| lastStatement | Last StatemenT, printed by aCTionFailed | E 1 | 1 | -- |
| maxLimit / repeatLimit | Token-length / repetition ceilings; pROPERTIEs | E 11 / 12 | 1 / 1 | -- |
| printSPACE | Text " " property | setup only | 1 | **no engine readers** |
| ruleSkipSet | Property wrapping skipSet | setup only | 1 | **no engine readers** (kant property) |
| searchList | Registry search order | E 6 | 1 | -- |
| setupFILE / sourceFILE | incant/setup node / current input source | E 2 / 14 | 1 / 2 | -- |
| tempField | Scratch result node for arithmetic ops | E 33 | 1 (an inert restore) | effectively no writer |
| alphaSet / nameSet / spaceSet / skipSet | Character sets | E 1 / 1 / 1 / 5 | 0 / 0 / 0 / 1 (ctor allocs) | no writers (ctor) |
| blockSTAK / bufferSTAK / inputSTAK | Indent-block stack / buffer pool / diverted-input stack | E 2 / 10 / 17 | 0 / 0 / 1 | -- |
| branchKind | break=1 / continue=2 / return=3 control slot | E 17, M 1 | 24 | -- |
| chanBinds / chanSame | Argument-bind counters | M 1 each | 2 each | **no engine readers** (instrument) |
| inputFloor | inputSTAK depth parse() must not auto-pop below | E 3 | 4 | -- |
| refused | Statement-scoped refusal flag | E 36 + IR load, M 1 | 4 + IR store | -- |
| lastIndent | Last indent column (checkSkip); kant `lastIndenT` (411) RW | E 5 | 8 | -- |
| sourceLINE | Input line counter | E 4 | 3 | -- |
| fieldBUFFER / stringBUFFER / toBUFFER | Buffers: fieldBUFFER property / string-literal scan / printTO target | setup / E 4 / E 4 | 1 / 1 / 2 | fieldBUFFER: no engine reader |
| defining | Define mode (processFlags `D`) | E 8 | 3 | -- |
| inputDiverted | Input is pushed over a prior source | E 6 | 3 | -- |
| parseTrace | Trace switch (`traceParse`), never cleared | E 5, M 26 | 1 | -- |
| useDefaultSpace | printField appends a trailing space | E 2 | 3 | -- |
| jitting | JIT emit-mode gate | E 46, X 6 | 2 | -- |
| compiling, debugAllRules | (FLAG rows) | E 1 / 4 | 3 / 1 | -- |
| **no readers, no writers** | debugJunk, divertOutput, punctuateSet, shortcutSet, rulesParsed, debugGuards, ignoreThis, ignoreNoRoom, isPERCENT, isRELATIVE, isRigorous, showWarnings | 0 | 0 | **12 dead members** |
| **write-only** | beforeSkip, lastSkip, noSkipping, formatBUFFER, divertToRule, endParse, isPRINTING | 0 | 1-3 | **no readers** |
| **ignoreNoPrint** | Gate in next() to skip noPrint items | E 1 | 0 | **no writers** (Part B) |

### Engine globals

`groupController` (the GroupControl singleton; ~359 readers, written once at GroupMain:19). Everything else is the JIT's
state in `jitContext.h`, read and written only in GroupRules.mm: gJitBuilder, gJitResult, the if/loop/short-circuit block
stacks, gJitResultSlot, gJitEmitted, gJitLastFn/LastAction, the probe door (gJitProbeCarrier/Fn, gProbe*), the counters
(gJitDegradeCount, gJitSlotCount, gJitSlotUnaryRefused, gJitCompileCount, gTermCallCount), gJitLastIR, gJitPrintBuf,
gJitResultNode, gJitLastIsNode, gJitFieldResident, gJitFrameAssigned, gJitSeeded, gJitFrame, gJitInlining/InlineFrames,
gJitCtx/Module, gJitBuiltFn/Name, gJitFnMap/NeedOwnFn, gJitEpilogueBB, gJitStmtCanRefuse, gJitRestartNeeded, the argument
channel (gChanPend*, gChanStk*, gChanStkTop). None is fully dead. **Expression-owned:** gJitDotSeeded/SeededVal/Product,
gJitCurrentAction/Fn, gJitFrameAssigned's reader. Comment-versus-code disagreements are in the FLAG table. Instrument-only
statics live in measure.twk (gMarkDriveBase, gMarkDriveLen, seenTable/seenCount).

---

## PART B -- the banked items: state, and the smallest change that settles each

### B1. C++ escapes in Tony's tok code

**73 escapes in scope** (GroupItem 11, GroupDraw 3, Stylish 1, Commands 2, Generate 5, genParse 1, GroupActions 16,
Instruct 23, ruleActions 11). **37 sayable in tok today** (an equivalent tok spelling is in use elsewhere in the tree),
**12 not** (CoreGraphics/ObjC, a lambda, stack `char` arrays, static hash tables), **24 unclear** (16 jit enum constants,
6 jitContext.h C globals or the resolveName binding, 2 function-pointer setters). Out of scope and not classified: 101 (runOP
2, runShortCircuit 1, handleDot 1, interpretXP 1, jitEmitters.rtn 96); measure.twk's 38 are instruments.

**GroupItem's 11** (line numbers today):

| site | what | sayable today? |
|---|---|---|
| attachLabel :260-273 | parseTrace-gated IA2 DROP trace walking the records | YES (inferred): the same walk is tok in this function (:233-235), `cerr` as at :243 |
| attachLabel :281 | `::measureAttachRepeat(stuff,lab)` | YES: tok passes RuleStuff into measure calls (:454) |
| captureSpan :318 | length-bounded print of a raw span (`%.*s`) | NO (inferred): no tok spelling of a bounded print |
| checkOP :338 | stack `char name[128]` + snprintf | YES (inferred): tok concat + free, as setActions does (:1660/:1676) |
| fireLabelMethod :731, :734 | a mid-function local `adoptHanded`, then `::measureAdoption` | YES: a top-of-function local did not capture `deferred` here (GroupItem.mm:1004) |
| parse :1352 | the label fire (brace block scoping `firedLab`) | YES (inferred): a top local, or a no-local spelling using constructs already in parse() |
| parse :1354, :1387 | measureOldFireFlag, measureParseReturn | YES |
| setJitEmitter :1780 | `gJitEmitter = (fnptr)m` from dlsym | UNCLEAR: tok generates this cast for `.method =` (GroupItem.mm:2137); not verified for this slot |
| setOperat :1818 | `gOp = (fnptr)m`; comment says tok cannot render a fnptr cast with a reference param | UNCLEAR, and **the premise is stale in the class but live in the mirror** -- see B6 |

**Waiting on the `&` tok fix:** 1 by its own comment (setOperat), 2 if setJitEmitter is counted with it. Neither slot's type
in `GroupBody.twk` carries a reference parameter today. **Four measure calls are escaped although their callouts are declared
in groups.ext** and their argument types already pass from tok (GroupItem :281, :734, :1354, :1387). The three Generate.rtn
`zEnc` re-resolves (now `::enclosingInstance`, :195, :242, :269) are parked for bear-trap #42 by ruling (SEQ 235 R3).
**Smallest change:** respell one escape per commit, each with a full bare tokall diff; the measure calls first (no logic
moves), then fireLabelMethod's two, then parse :1352 together with B2.

### B2. parse()'s readability, and the `beforeAction:` anchor

**State:** parse() is 92 lines (`GroupItem.twk:1298-1389`): 71 of code, 17 one-line slug comments, 3 escapes. The label
fire is the brace-scoped escape at :1352; `beforeAction:` and its no-op `ownPoint = 0;` (:1349-1350) are the anchor for
Tony's on-success directive (`groupDirectives:255 parse ownPoint active`), placed because tok dropped that directive while
the escape sat there (SEQ 213 R1). **Smallest change:** respell :1352 in tok (B1); in the same commit remove the label and
the no-op assign, re-aim the directive at the respelled statement, and show it injects (dirCheck). Readability beyond that
is Tony's to direct -- the slug comments carry the "why" pointers the comment convention asks for.

### B3. The 412 cut (`processingCodE`)

**State:** restored 2026-10-06 (Tony's offline-rulings R2, option a, seal 71; fba6f04). `incant/setup:294`; Instruct.rtn read :449 (`inCompile()`), write-refusal :1507-1508.
Readers: `compileFloorT` CF-0..4, `compileInT` CI-H3/H4, `fieldSetT` (and a comment in WorkingOn/tester). **Smallest change:**
a ruling on whether the compile-floor mark needs a kant reader at all; if not, retire CF-0..4, CI-H3/H4 and the refusal row
by mapping, then cut the three lines.

### B4. Uncalled and never-set

| item | state today | smallest change |
|---|---|---|
| recordLabel | Generate.rtn:25 + groups.ext:506; no caller since the ruleName stroke | cut both; canary 306 -> 305 |
| enclosingStuff | Generate.rtn:46 + groups.ext:510; no caller | cut both; canary down one more |
| ignoreNoPrint | GroupRules.twk:103 + groups.ext:438; one read (GroupItem.twk:1243), no writer | cut the flag, the read, the mirror line |
| updateContentFlags | GroupItem.twk:1965 + groups.ext:328 + **a directive, groupDirectives:296-298** (not named in the cleanupList entry); no caller | cut the method, the mirror line and the directive |

### B5. ParseActivation passed by value through tok

**State:** tok passes a struct that is not a tok class BY VALUE when a parameter is spelled `ParseActivation rec`; the build
fails (stroke 1.3). `stuffOf(ParseActivation *rec)` is the only parameter of that type in the tree, and every local is
already spelled `ParseActivation *x`. **Smallest change:** none in code; record it beside bear-trap #58 (a tok struct
parameter needs the explicit `*`).

### B6. NEW, found by this census: `gOp`'s mirror disagrees with its class

`GroupBody.twk:15` and the generated header declare `GroupItem &gOp(GroupItem,GroupItem)` -- target by value since `fa9989c`
(2026-06-14). **groups.ext:72 still mirrors `GroupItem &gOp(GroupItem,GroupItem&)`.** setOperat's escape comment, which says
tok cannot render a reference-parameter fnptr cast, is true of the mirror and false of the class. **Smallest change:** a
ruling on which is right; then align the mirror, and test whether setOperat's escape can go (full bare tokall diff).

### B7. docs/cleanupList.md, re-checked against trunk (25 entries)

**YES 15 · PARTLY 2 · ALREADY CUT 8 · NO 0.**

| entry | verdict | note / smallest change |
|---|---|---|
| testAttributes' artifact skip | YES (a KEEP) | Tony rules it a keep, or strike |
| setPointer command -> opPointer | YES | also has groups.ext:611; cut setup:76, opPointer (Instruct.rtn:1232), ext:611, the setup note |
| genParse.rtn's name | YES | every extern still live; a move only if Tony wants one |
| three escaped `::enclosingFace` calls | PARTLY | renamed `enclosingInstance` (stroke 1.3), Generate.rtn:195/242/269; re-title; respell stays parked |
| testAny and bootstrap rule Any | PARTLY | gained callers: `anyLeafT` drives it (AL-1 rows) and parse()'s leafDone compares it; cutting now needs AL-1 retired by mapping |
| jitProbeDrive's second drive door | YES | a stroke: route the fire through driveStep, drive census 4 -> 3 |
| modPercent / modPointer | YES | also ext:716-717 and omModT's OM-2 rows; usage census still owed |
| fold interpretXP into aCTionExpressioN | YES | expression recon's (R2) |
| parseTrace / traceParse | YES | waits on Tony's ruling; fixture rows first |
| fireNewParse, parseGeneric, parseAny | ALREADY CUT | -- |
| named-rule trace quiet on a face | YES (unmeasured) | needs the measurement |
| Bytecode road | ALREADY CUT | leftovers only in gitignored groupDirectives:54-60 (`generateCode`, `bcPushField`) |
| labelMinters / allAttributesOptional / definer, establishFrame / parentLabel, dupCensus, compile's pending block | ALREADY CUT | -- |
| isLabel's second meaning on action locals | YES | needs the reader census (processAction :652/:659) |
| GroupItem's escapes / parse() readability | YES | B1/B2; "captureSpan :329" was really checkOP (:338) |
| processingCodE (412) | YES | B3 |
| ignoreNoPrint, updateContentFlags, recordLabel, enclosingStuff | YES | B4 (the cleanupList entries omit the mirror lines and updateContentFlags' directive) |

⚠ **The list's own structure:** seven live entries (isLabel, GroupItem escapes, processingCodE, ignoreNoPrint,
updateContentFlags, recordLabel, enclosingStuff) sit under its `## Done` heading -- appended there by Clod today. They are
not done.

### B8. objectModel §1.3 is out of date (found by the field passes)

Its GroupItem row lists `options.isCopy` (gone) and misses `labelOf`, `ruleOf`, `jitData`; its RuleStuff row counts 35
members (now 16) and lists the rule-level and activation fields that left; its ParseActivation is `{stuff, prev, floor,
label}` (now `{instance, isFloor, compileOwner, label, prev, failPoint}`); its GroupBody description predates
`propertyList`, the four function slots and the flag deletions (44 flags now); F-O8's `modify()` writes are stale (modify
writes RuleStuff's modPercent/modPointer/modUnGuarded; only `$` -> isMacro still reaches the body). **Smallest change:** a
docs pass on §1.3 from this census.
