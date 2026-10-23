# A rule's code returns its label -- SEQ 411

Dictated via Tony ("Fearless"), 2026-10-23; transcribed by Clod at pickup.

## The dispatch, as forwarded

RULINGS

(Tony, 2026-10-23) In a rule's code, `return *argument;` hands back the label (tag = the rule's name, holding what the
code built), on both roads that run the rule:
(i) fired on a label, as InvokeD's attribute does;
(ii) called from the command line, where the caller then does `testOP(*xpListTest)`, which reaches instruct.
Action returns are unchanged.

R0 (trunk, born red). Write fixture ruleReturnT, using tester's xpListTest shape. Pin today's values with the intended
value beside each. RR-1 (road i): InvokeD's held entry has tag xpListTest, and one level down is instruct. RR-2 (road ii):
the command-line call's return has tag xpListTest; * of it is instruct; testOP(*ret) runs as tester's does. RR-0
(control): an action's `return x;` hands back what it does today.

R1 (recon, read-only; taps reverted md5-identical). The site where return reads ExpressioN in aCTionBrancH, and the
getLabelGroup unwrap: measure how many levels it strips on RR-1 and RR-2. A census of every getLabelGroup caller across
pop.sh, jitLadder and gen26: what reaches each one, and whether the unwrap changes it. Road ii: what the CodE's argument
holds when the rule is called as xpListTest(...); if it is empty or the string, STOP and report (seal 199's runAction
binding). The jitted road: does a handed-over return (jitStmtRTValueRT, SEQ 393) pass through getLabelGroup? Does a
compiled rule's code return reach it?

R2 (options for Tony, nothing built). (a) return skips the unwrap inside a rule's CodE only. (b) return never unwraps;
the census names who moves. (c) getLabelGroup unwraps one level. For each option, give its movers and the H7.

R3 (on the branch, after the ruling). Build the ruled option. Certificate: RR-1 and RR-2 go green; RR-0 is unmoved;
pop.sh and jitLadder match row for row except the registered movers. H7: the unwrap restored turns RR-1 and RR-2 red by
value.

## R0 -- pinned (trunk 7de39fb6)

**The spelling.** For the label to *hold* what the code built, the fixture's xpListTest ends
`*argument := *target; return *argument;`. tester today attaches instead (`xpListTest +% *target;`), and an attached
label is a list, not a holder, so it comes back intact today. The holding shape is the one the ruling describes ("one
level down is instruct"), and it is the one that loses the label.

| row | what it reads | today | intended |
|---|---|---|---|
| RR-IN | the label inside the code, before the return (control) | `xpListTest=instruct` | the same |
| RR-1 | road i: InvokeD's held entry | `instruct` | `xpListTest=instruct` |
| RR-2 | road ii: `ret := xpListTest("qa - qb + qc;")`, ret | `ret=instruct` | `ret=xpListTest` |
| RR-2S | road ii: `*ret` | `instruct` (the chain) | `xpListTest=instruct` |
| RR-2T | road ii: `testOP(**ret)` -- ruleReturnOpT, its own file | exit 139, no value | exit 0, value 5 |
| RR-0 | an action's `return rrH;` (rrH holds rrLeaf), and `return rrLeaf;` (control) | `v=rrLeaf w=rrLeaf` | the same |

`ret := call` makes ret a holder of the return, so the dispatch's "the return" is `*ret` and "* of it" is `**ret`.
RR-2T is split out because today `**ret` is null, testOP dereferences it, and the process dies -- it would take
ruleReturnT's other rows with it. Its intended 5 is what `testOP(*ret)` gives today, when `*ret` is the chain.
pop.sh 1744 -> 1748 green, 4 born red, nothing else moved.

## R1 -- where the label goes (taps in the clone at b0f036c1, the trunk engine; reverted md5-identical)

**THE DISPATCH'S SITE IS NOT THE SITE.** A tap on each seat the return value passes, holding-shape probe:

```
BR raw -> ExpressioN (holder, label) -> acU (method)      aCTionBrancH: getLabelGroup("ExpressioN") strips ONE level
BR ret -> xpListTest (holder, label) -> instruct          the value aCTionBrancH returns: THE LABEL, intact
PA out -> instruct                                        what processAction hands back: the chain
```

- **aCTionBrancH's getLabelGroup** strips one level on both RR-1 and RR-2: the ExpressioN parse label to its evaluator
  (`acU`), which aCTionBrancH then runs. It never touches the returned value, and the value it returns is the label.
- **The unwrap is aCTionBlocK's foot, `ruleActions.rtn:68`:** `if result && result.isGROUP  result = result.gGroup;`. A
  block hands back its last statement's value with one holder level removed. The return breaks the block with the label
  as `result`, the label holds the chain, so the block hands back the chain. Same seat on both roads, because both run
  the code through processAction -> the CodE's BlocK. Dated: the line is older than 5da61d0c (2026-07-31), which only
  re-spelled it.
- **Road ii's door** is opCall -> runRule -> driveStep: the rule parses its string and fires on the label, as road i
  does. runAction is not on it (0 entries for a rule, probe and fleet).
- **Road ii's argument (the STOP check):** the CodE's `argument` holds the label (`argument=xpListTest`, the label
  holding `lizted`), on both roads. Not empty and not the string, so the STOP does not fire. (seal 199's runAction
  binding is the action door, which a rule called with a string does not take.)
- **Found, not in scope:** runRule hands back `trueResult` instead of the label when the rule has a generated parse
  (`hasNewParse`, ruling c'). If xpListTest is ever `parser()`'d, road ii returns true, whatever the code returns.

**The jitted road.** A compiled function returns a count, never a node. A handed-over return's value goes through
jitStmtRTValueRT (jitEmitters.rtn:2419), which copies the block foot's one-level holder follow and then reads the count
-- it does not go through getLabelGroup. A rule fired on a label runs through processAction, which has no jitter
intercept (runAction's is the only one), so a rule's code is never compiled and its return never reaches the jitted
road. Census: jitStmtRTValueRT's holder follow fired **0** times across pop.sh, jitLadder and gen26.

**The census** (file-only taps, so the fleet was row for row: pop.sh 1744 = the untapped run in the same tree but
acceptStartT's address (H3); jitLadder PASSED; gen26 15 / 26 agree, as at seal 209).

*aCTionBlocK's foot unwrap* -- every firing: **24, all in pop.sh, none on a return** (branchKind 0 every time; jitLadder
0, gen26 0). Each is a block whose last statement left a holder (`x := ...`), mostly loop bodies: jitForBodyT 8 and its
.I twin 8 (fcL -> sample), walkRefT 4, testPrecedence 2 (tpRead -> kid), assignRoadT 1 (arOut -> arSrc), kindHolderJitT
1 (kH -> kN). **No return anywhere in the three instruments hands a holder through the unwrap** -- so no fleet row reads
what this unwrap does to a returned value. RR-0 is the only row that does.

*getLabelGroup* -- 12 `ExpressioN:` declarations (ruleActions.rtn, jitEmitters.rtn) plus every other `X:` label read.
Logged: every read that strips other than one level. **Two levels or more: only `ExpressioN`** -- pop.sh 520
(traitFlagsT 340, shadowCensus 85, baselineTests 14, baselineTestsNew 14, jsonTest 8, exprPinT 7, pass1SeqT 6,
firstUseT 5, carrierT 5, then 2-4 each in ruleThisT, lastRefT, jitScCountT, jitCmpOperandAT, argWriteT, recurSaveT,
kant8T, jitCmpOperandT, jitArithOperandT, argBindT, andProbe); gen26 34 (baselineTestsNew, both twins); jitLadder 0. Each
ends at a value (`hasTraitS`, `hasAttributeS`, `taG`, `ANYstring`, `tempField`, ...) two levels under the label. Zero
levels (the label is not a holder) is the common case: StatemenT, Attributes, stuff, DatA, tik, quoteBody, Modifier ...

## R2 -- options (nothing built)

The dispatch's three options are written against getLabelGroup, which R1 shows is not on the value's path. Each is given
as written and as re-aimed at the real seat, aCTionBlocK's foot.

**(a) re-aimed -- RECOMMENDED: the block-foot unwrap is skipped when the block broke on a `return` (branchKind 3) inside a
rule's code (currentMETHOD's group is a rule).** A nested block the return passes through (an `if` arm) is skipped too,
because branchKind stays 3 until processAction consumes it. Movers: **none in pop.sh, jitLadder or gen26** (census: no
return reaches the unwrap). Registered: RR-1, RR-2, RR-2S, RR-2T to their intended values; RR-IN and RR-0 unmoved. The
jitted road is untouched (a rule's code is never compiled). H7: the skip removed -> RR-1 `instruct`, RR-2 `ret=instruct`
by value. A tighter spelling of the same seat adds "and the value is a label" (`result.isLabel`); it moves the same rows.

**(b) re-aimed: a return never unwraps, in any action.** Movers in the three instruments: **none** (same census). But
**RR-0 moves**: `rrAct`'s `return rrH;` hands back the holder rrH instead of rrLeaf (projected `v=rrH`) -- against the
ruling's "action returns are unchanged". jitStmtRTValueRT would follow for a handed-over return to stay one rule (its
follow fired 0 times). H7: the unwrap restored for a return -> RR-1 / RR-2 red, RR-0 back.

**(c) re-aimed: the block-foot unwrap goes entirely.** Movers: the 24 firings change their block's value -- jitForBodyT
(and .I), walkRefT, testPrecedence, assignRoadT, kindHolderJitT; whether a row reads them is a build question (most are
loop bodies whose value is dropped) -- plus RR-0 as in (b), plus jitStmtRTValueRT's follow for consistency. H7: the line
restored -> RR-1 / RR-2 red.

**(a) and (b) as written** (the return skips getLabelGroup in aCTionBrancH): `arg` would be the ExpressioN parse label,
which is not a method, so it would never be evaluated -- every `return <expression>` would hand back its own parse node.
Not viable.

**(c) as written** (getLabelGroup unwraps one level): **does not move RR-1 or RR-2** -- the return's read strips exactly one
level already. It moves the 554 two-level ExpressioN reads above (pop.sh 520 across 21 fixtures, gen26 34), each of
which would stop one holder short of its value. H7: none to state, because it cures nothing.
