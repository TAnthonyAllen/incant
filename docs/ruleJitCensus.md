# The rule census: the order for compiling kantGrammar rules (SEQ 555, 2026-11-07)

**Of 20 rules with a body: 11 safe (ITERATe already compiled, so 10 to do), 3 wait on F-146, 6 meet F-145. The other 24 rules have no body to compile.**

Read only, by R1: nothing built, no branch, nothing added to jitterRule, on merged trunk's bare binary (canary 444). Road: **kant / emitted**.

## The population

**46: 44 rules and the 2 actions they inline.** Counted from the live registry, a walk of `KantGrammar`, and matched against the file. The walk reads 49 entries; 5 are shared and only named here (ANYtoken, NumbeR, QuotE, SemI, Operators). 20 of the 44 have a body: 19 `code=` plus ELSEIf, which shares If's.

**How each column was taken:**

| column | how | grade |
|---|---|---|
| ending, loops, refusal arms | read from the body | read |
| count label | read, then a scratch parse dumped, plus the IR for INVOKEr | measured where it says so |
| testing, native / handed | `testing(<rule>)` under an alarm, then `gJitOldNative` / `gJitOldHanded` read under lldb at exit, so nothing was added to jitterRule | measured. `testing` fires with no label, so only the compile is evidence |
| fleet | every `pop.sh` input loading kantGrammar run a second time with `traceParse();` added, recording each coded rule's fire and each refusal | measured, whole fleet |

The tap moved 8 of pop.sh's own rows (2821 -> 2813), all from witness lines or refusal lines the second pass doubled, as in `kindArmNetT`'s `1 | 2`. That is the tap, not the code; the untapped run on the same binary reads 2821. `jitLadder` is not in the fleet column, as the dispatch asks for pop.sh rows.

## Safe now (11): returns on every path, no loop, no count label, fired

ITERATe is bought. The rest, ranked by fleet reach, then native:

| rule | ending | loops | count label | refusal arms | testing | native / handed | fleet: fixtures that fire it |
|---|---|---|---|---|---|---|---|
| ITERATe | returns, 3 paths | none | no | cursor, source: no fleet row; not reached in scratch | exit 0 | 6 / 17 | 4: argRoadsT, codeBraceT, iterT, ruleDoorT |
| SHORTCUt | returns, 1 path | none | no | none | exit 0 | 0 / 7 | 34: adjacentT, argRoadsT, branchT, bridgeT, cmdCallT, codeBraceT, doT, elseIfT, forT, ifT, iterT, kindArmNetT, kindArmSameT, newCallBindT, newJitCallT, newJitIfT, newJitIfUnsetT, newJitLoopT, newJitPrintT, newJitT, newLocalArgT, newLocalT, newPlusEqT, newReturnSelfT, newReturnT, printFormatT, printListT, printSinkT, quoteT, ruleDoorT, shortcutOpT, topLevelT, trailingContinueT, whileT |
| If | returns, 3 paths | none | no | then arm, else arm: no fleet row; both reached in scratch | exit 0 | 0 / 15 | 27: argRoadsT, branchT, bridgeT, codeBraceT, doT, elseIfT, forT, ifT, iterT, kindArmNetT, kindArmSameT, newCallBindT, newJitCallT, newJitIfT, newJitIfUnsetT, newJitLoopT, newJitPrintT, newJitT, newLocalArgT, newLocalT, newReturnKindT, newReturnSelfT, newReturnT, oldCallsNewT, refusalEndsT, topLevelT, whileT |
| BRANCh | returns, 1 path | none | no | none | exit 0 | 0 / 9 | 17: argRoadsT, branchT, codeBraceT, doT, elseIfT, forT, iterT, newJitCallT, newJitIfT, newJitLoopT, newJitT, newReturnKindT, newReturnSelfT, newReturnT, oldCallsNewT, topLevelT, whileT |
| WHILe | returns, 2 paths | none | no | statement: no fleet row; reached in scratch | exit 0 | 0 / 14 | 16: argRoadsT, bridgeT, codeBraceT, doT, elseIfT, forT, iterT, newCallBindT, newJitCallT, newJitLoopT, newJitPrintT, newJitT, newReturnT, refusalEndsT, ruleDoorT, whileT |
| FOr | returns, 3 paths | none | no | restriction: forT; statement: no fleet row, reached in scratch | exit 0 | 2 / 16 | 3: forT, newJitLoopT, refusalEndsT |
| Do | returns, 2 paths | none | no | statement: no fleet row; reached in scratch | exit 0 | 0 / 14 | 3: doT, newJitLoopT, refusalEndsT |
| ELSEIf | returns, as If (shares If's CodE) | none | no | If's arms, naming If: no fleet row | exit 0 | 0 / 15 | 2: elseIfT, newJitIfT |
| SEARCh | returns, 1 path | none | no | none | exit 0 | 0 / 7 | 1: bridgeT |
| DEBUg | returns, 1 path | none | no | none | exit 0 | 0 / 7 | 1: bridgeT |
| SCOPEXp | returns, 1 path | none | no | none | exit 0 | 0 / 7 | 1: bridgeT |

## Waits on F-146 (3)

| rule | ending | loops | count label | refusal arms | testing | native / handed | fleet: fixtures that fire it |
|---|---|---|---|---|---|---|---|
| XPRESs | returns, 1 path | none | **yes, measured**: `XPRESs("5;")` holds `5 int` | none of its own | exit 0 | 0 / 4 | 27: argRoadsT, bridgeT, cmdCallT, codeBraceT, doT, elseIfT, forT, kindArmNetT, kindArmSameT, newCallBindT, newJitCallT, newJitIfT, newJitIfUnsetT, newJitLoopT, newJitPrintT, newJitT, newLocalArgT, newLocalT, newPlusEqT, newReturnKindT, newReturnSelfT, newReturnT, oldCallsNewT, printSinkT, refusalEndsT, trailingContinueT, whileT |
| INVOKEr | returns, 2 paths; **the `return ANYtoken` path is a native return, kind 1** | none | **yes in effect**: the IR shows kind 1 at that exit, so every plain token meets the guard | none of its own | exit 0 | 2 / 0 | 16: adjacentT, argRoadsT, cmdCallT, codeBraceT, instructTargetT, newCallBindT, newJitCallT, newJitPrintT, newLocalArgT, newLocalT, newReturnSelfT, newReturnT, printFamilyNew, printSinkT, refusalEndsT, trailingContinueT |
| TOPSTATEMENt | **falls off the end, every path** | none | no | top-level break, continue, return: topLevelT. They do not end the body | exit 0 | 1 / 5 | 8: bridgeT, cmdCallT, defineRefT, flagAttrT, newLocalT, printSinkT, topLevelT, traitGridT |

## Meets F-145 (6): a loop, own or inlined

| rule | ending | loops | count label | refusal arms | testing | native / handed | fleet: fixtures that fire it |
|---|---|---|---|---|---|---|---|
| EXPRESSIOn | returns, 4 paths | **own**, `while cur.datA` | **yes, measured**: `EXPRESSIOn("5")` holds `5 int` | call-argument run, operand run: adjacentT; instruct left of `=`: instructTargetT | exit 0 | 5 / 3 | 39: adjacentT, argRoadsT, branchT, bridgeT, cmdCallT, codeBraceT, doT, elseIfT, forT, ifT, instructTargetT, iterT, kindArmNetT, kindArmSameT, newCallBindT, newJitCallT, newJitIfT, newJitIfUnsetT, newJitLoopT, newJitPrintT, newJitT, newLocalArgT, newLocalT, newPlusEqT, newReturnKindT, newReturnSelfT, newReturnT, oldCallsNewT, printFamilyNew, printFormatT, printListT, printSinkT, quoteT, refusalEndsT, ruleDoorT, shortcutOpT, topLevelT, trailingContinueT, whileT |
| BLOCk | returns, 1 path | **own**, `while cur.datA` | no | none | exit 0 | 1 / 7 | 27: argRoadsT, branchT, bridgeT, codeBraceT, doT, elseIfT, forT, iterT, kindArmNetT, kindArmSameT, newCallBindT, newJitCallT, newJitIfT, newJitIfUnsetT, newJitLoopT, newJitPrintT, newJitT, newLocalArgT, newLocalT, newPlusEqT, newReturnKindT, newReturnSelfT, newReturnT, oldCallsNewT, refusalEndsT, topLevelT, whileT |
| STARt | returns, 1 path | **own**, `while cur.datA` | no | none | exit 0 | 1 / 7 | 29: argRoadsT, branchT, bridgeT, cmdCallT, codeBraceT, doT, elseIfT, ifT, iterT, kindArmNetT, kindArmSameT, newCallBindT, newJitCallT, newJitIfT, newJitIfUnsetT, newJitLoopT, newJitPrintT, newJitT, newLocalArgT, newLocalT, newPlusEqT, newReturnKindT, newReturnSelfT, newReturnT, oldCallsNewT, refusalEndsT, ruleDoorT, trailingContinueT, whileT |
| PRINt | returns, 1 path | **inlined**, makePrint, two | no | none | exit 0 | 0 / 5 | 32: adjacentT, branchT, bridgeT, cmdCallT, doT, elseIfT, forT, ifT, iterT, kindArmNetT, kindArmSameT, newCallBindT, newJitCallT, newJitIfT, newJitIfUnsetT, newJitLoopT, newJitPrintT, newJitT, newLocalArgT, newLocalT, newPlusEqT, newReturnSelfT, newReturnT, printFormatT, printListT, printSinkT, quoteT, ruleDoorT, shortcutOpT, topLevelT, trailingContinueT, whileT |
| CERr | returns, 1 path | **inlined**, makePrint, two | no | none | exit 0 | 0 / 5 | 5: argRoadsT, bridgeT, codeBraceT, newJitPrintT, printSinkT |
| COUt | returns, 1 path | **inlined**, makePrint, two | no | none | exit 0 | 0 / 5 | 3: bridgeT, newJitPrintT, printSinkT |

EXPRESSIOn also waits on F-146. None of these loops has F-145's literal condition: all read `cur.datA != 0` or `m.datA != 0`. They sit here by the dispatch's rule, that a loop means F-145. Whether that is stricter than F-145 needs is a question worth asking, because this group holds the fleet's busiest rules.

## The two inlined actions: not rules, not ordered

| action | ending | loops | testing | native / handed | note |
|---|---|---|---|---|---|
| makeInstruct | returns | none | exit 0, **compile returns -8**: `its local argument is kindless` | 1 / 8 | Alone it is NOT JITTABLE. Inside a rule its call statement is handed over, so this does not block a rule |
| makePrint | returns | **own, two** | exit 0, **compile returns -8**, same refusal | 1 / 8 | Why PRINt, CERr and COUt are in the F-145 group |

## No body (24): nothing to compile

ANYORNUm, ANYSTRINg, BASICELSe, BRANCHEs, DEf, ELSe, FILe, FORMAt, INVOKEd, ITERSOURCe, LOOPEr, LOOPRESTRICt, PRECISIOn, PRINTXp, SCOPEFIELd, STATEMENt, STRINGXp, TOKEn, WARDEd, break, continue, loopOnAttributes, loopOnMembers, return.

Each exits through the parse with no action, so the door never opens for them and no fire can be counted. Not a gap in the fleet.

## The proposed order

Ranked as ruled: fleet reach, then native.

| # | rule | fixtures | native | carries |
|---|---|---|---|---|
| 1 | SHORTCUt | 34 | 0 | nothing |
| 2 | If | 27 | 0 | F-147 |
| 3 | BRANCh | 17 | 0 | F-147 |
| 4 | WHILe | 16 | 0 | F-147 |
| 5 | FOr | 3 | 2 | F-147 |
| 6 | Do | 3 | 0 | F-147 |
| 7 | ELSEIf | 2 | 0 | F-147; shares If's body, so it comes after If |
| 8-10 | SEARCh, DEBUg, SCOPEXp | 1 each | 0 | bridgeT is the only fixture; the rows are thin |

**Then:** F-146's cure opens XPRESs, INVOKEr and TOPSTATEMENt. A ruling on the F-145 group opens the rest, EXPRESSIOn last.

**Ruled since (Tony, 2026-11-07):** F-147's cure, then FOr, then a jitter rung compiling `+%`, `:=` and `copyOf` natively, then a measurement of the six loop rules, then this order resumes. The certificate keeps "native above 0".

## Three things the dispatch's rules do not settle

**1. Only FOr has a native count among those left.** The other nine are native 0: every statement hands over. SEQ 554's certificate asks for native above 0, and these cannot give it. A compile of them proves the door and the label path, and buys no speed. So either that certificate line changes for this group, or FOr goes first, or the order waits on hand-overs becoming native (`+%`, `:=`, copyOf are nearly all of them).

**2. F-147, found by this census: a refused condition crashes the new road, interpreted, at exit 139.** `if qa qb + 1; print 1:;` prints its refusal and then dies, through STARt as well as at the rule's root. It crashes in opAddAttribute with a null argument: If's `ifArms +% *cond`, with `cond` read from a child that refused and cleared its label. Measured the same on ELSEIf, WHILe, Do, FOr's source, BRANCh's return value and INVOKEr's argument. No fleet row reaches it. It is not a compile problem, and it is on both arms. A compiled-equals-interpreted row cannot include that shape until it is cured. Registered in `docs/fixIts.md`.

**3. "A refusal can reach the hand-back" is not closed for the safe group.** Nothing there has a refuse() that a parse is known to reach, because that path crashes first (F-147) and the rules' own refusal arms end in `return`. That is what was searched: a refused child, per rule. It is not a proof no other refuse() exists. The guard is the backstop, and it would be loud.

## Fleet coverage worth knowing

**Refusal arms no fleet row reaches:** If's then and else, the statement arm of WHILe, Do and FOr (all four reached in scratch), and ITERATe's cursor and source (not reached in scratch either). A certificate for those rules needs rows for them.

## Added 2026-11-07, after FOr's certificate (SEQ 557)

**Point 3 above has moved. With F-147 cured, a refused child now does reach the hand-back.** Measured on FOr: `for lp in qa qb + 1; ...` raises a real refuse() at the attach, in a handed-over statement, so the compiled body leaves with a boxed count and the guard adds its line. The value and the other refusals match interpreted; it is one extra `REFUSED FOr -- a compiled rule handed back a count` line, pinned by ruleForT's RF-O. If, ELSEIf, WHILe, Do and BRANCh have the same shape, read and not run, because compiling them here would open them. So by this census's own test they now meet "a refusal can reach the hand-back". Whether that moves them to the F-146 group, or stays in the safe group with the line pinned as FOr's is, needs a ruling before If.
