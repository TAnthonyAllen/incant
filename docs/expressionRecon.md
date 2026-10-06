# Expression recon

Dispatch: clay-to-clod expression recon, step 1 (Tony's rulings 2026-10-06). **A map, no design, no proposal; the order of
what follows is Tony's to set after reading it.** Two read-only passes (one traced and ran probes, one read every builder
and reader); the probes that carry a claim were re-run by Clod on trunk `7f7dcac` and agree. Probe files:
`scratchpad/expr/p1..p5` (session scratch, not in the repo); each runs with `traceParse();` on and reads the TOKENARM /
RULEDISPATCH callouts. **(read, not run)** marks what was read only.

## ⚠⚠ THE RULED DIRECTION (Tony, 2026-10-06, D1-D6) -- read this first

Ruled at the shutdown of 2026-10-06, on the step 1 map and the step 2 probes below. **The direction is ruled; the
executor kinds and the instruction layout are not -- they are designed on a try-and-buy branch (D5).**

- **D1. Expressions walk LEFT TO RIGHT.**
- **D2. No arithmetic precedence: arithmetic folds strictly left to right.**
- **D3. Tiers by split, loosest first: assignment, then `&&`/`||`, then comparison, then the arithmetic fold; left to right
  within a tier.** Tiers are expected to live in grammar rules, with each operator's tier as data in incant/setup.
- **D4. An operand is prefix, name, postfixes; prefixes bind to the name first.** `*block(code)` is `(*block)(code)`
  (the uniform form of the 10-05 `*a.b = (*a).b` ruling; R1 of 2026-10-06).
- **D5. Structural dispatch is fixed at instruction build, one executor per kind; run-time choices live inside the
  executor.** Executor kinds and instruction layout are designed on a try-and-buy branch, whose first measurement is P1's
  open question -- does one instruction ever switch arm -- answered with a code tap on the instruction node itself.
- **D6. Before the branch: pin on TRUNK, at today's values,** the KANT-43 split fixture (`qa * qb + qc` = 23 against
  `2 * 10 + 3` = 26, and the `-` pair: `qa - qb + qc` = -5), P2's seven sites (jitAttrPop:69-70, utilities:67, 70, 72, 75,
  302), and the utilities `&&` lines -- **wrong today, expected to move** under D1-D3.

**The migration this implies, from P2/P3:** seven sites in three files change value; two are pinned by jitLadder rung JA
(25 / 75 / 125), whose fixture comment already expects the left-to-right 17; the five utilities comparisons are wrong today
under either strict direction and come right only with D3's comparison tier.

## Step 1 -- what exists, end to end, for one expression

### 1. `a = b + c;`, interpreted

**Grammar, in match order** (`incant/grammar`): `Start StatemenT-+` (:181) -> StatemenT's `Xpress` alternative (:175-180)
-> `Xpress ExpressioN SemI- defer` (:174) -> `ExpressioN Token+` (:142). Each `Token` (:136-141) is `QuotE | NumbeR |
StringXP | TokenXP | Operators`, NumbeR before TokenXP. A name goes through `TokenXP UnaryOPS? ANYorNum^ InvokeArg?` (:135)
-> `ANYorNum` (:132) -> `ANYtoken NamE@`; `=` and `+` match `Operators`. Trace (p1): NamE -> ANYtoken -> ANYorNum ->
TokenXP -> Token for `a`, Operators -> Token for `=`, the same for `b`, `+`, `c`, then ExpressioN (5 kids), SemI, Xpress,
StatemenT.

**How the actions fire.** A term's exit (`exitFromParse`, Generate.rtn:59, or old-road `parse()`) calls
`fireLabelMethod` (GroupItem.twk:710), which calls the rule's `builtinActoR.method(label)` (:732). A `defer` rule under a
deferred ancestor is stashed instead (`fireLab.method = actor; deferred`, :724-726).

**What is built, in order:**
1. **`aCTionTokenXP`** (ruleActions.rtn:976), once per name. Reads `UnaryOPS`, `InvokeArg`, `ANYorNum`, then
   `xpress.clear()` (:984). No InvokeArg and no unary: the `primary` arm, `xpress.group = ANYtoken` (:999-1000).
   p1: `TOKENARM primary primary=a|b|c`.
2. **The label hands up** (`attachLabel`, GroupItem.twk:220). TokenXP -> Token (isTarget) is retagged Token. Token ->
   ExpressioN has `max=100` and the label holds a group, so `dest +% lab.group; lab.clear(); lab.fLAG = true`
   (:280-285): **ExpressioN's list receives the term's GROUP** (the bare field, or a `uxp`), not the TokenXP node. A label
   that is not a group (a bare call) goes in whole (:286).
3. **`aCTionExpressioN`** (ruleActions.rtn:441) is `return interpretXP(xpList)` (:444).
4. **`interpretXP`** (:1398) walks `[a, =, b, +, c]` BACKWARD (section 2) and builds `xl2 = [+, b, c]`, then
   `xl2 = [=, a, xl2(+)]`, each with `method = runOP` (`runShortCircuit` for a `shortCircuit` op) and `invoke = true`
   (:1464-1474); then `xpList.clear(); xpList.group = root` (:1479-1480).
5. **`aCTionXpress`** (:1147): `getLabelGroup("ExpressioN")` is the root; outside a compile it fires
   `ExpressioN.gMethod(ExpressioN)` -- runOP (:1151-1152); under a deferred owner it returns the value (:1154); in a
   compile it parks it (`input.group = ExpressioN`, :1156-1158). Inside an action body the statement fires later, from
   `aCTionBlocK`'s loop.
6. **`aCTionStatemenT`** (:908) records `lastStatement` and clears refusal. It builds nothing.

**Firing: `runOP`** (GroupActions.rtn:981). `op = field[1]`, `target = field[2]`, `arg = field[3]` (:984-987);
`refuseArgRebind` (:989); `followArgument` on both operands (:990-991); a refused statement stops here, interpreted only
(:993-994); `op.instructType && target.isMethod && target.invoke` fires the target (:995); `arg.isMethod && arg.invoke`
fires the arg (:996-997) -- **this is where the inner `+` runs first**; `isVirtual` copies (:1000); `op.hasMembers` ->
`pickKindOP` (:1002-1004); jit seed and slot (:1006, :1008); `measureRuleDispatch` (:1010); then the ladder (:1012-1024):
`op.isOperator` -> `op.operat(arg,target)` (gOp); `op.isMethod` -> `op.method(target)`; otherwise the target decides --
`isRuleTerm` -> `runRule`; `actionType` -> `runAction`; `isMethod` -> `target.method(arg or target)`; else
`refuseUnknownOperator`. gOp/gMethod are bound by `ruleMethod` (GroupActions.rtn:908) from `operateMethod=` /
`ruleMethod=` in incant/setup: `'+' operateMethod=opPlus jitEmitter=jitEmitAdd` (:155), `'=' operateMethod=opAssign`
(:118). `opPlus(c, b)` (Instruct.rtn:931) writes `tempField` and returns it; `opAssign(tempField, a)` (:116) is
`setContent`.

p1 (`pa = pb + pc;`): `RULEDISPATCH pb ... arm=operator`, then `RULEDISPATCH pa ... arm=operator` -- the inner `+` first.

### 2. Where interpretXP walks backward, and why

`while token = xpList.prior(token)` (ruleActions.rtn:1408). Each `[op, target]` pair that arrives takes the finished
RIGHT-hand subtree as its `arg`, so `a OP1 b OP2 c` builds `OP1(a, OP2(b, c))` -- right to left, no precedence. The code
says so in its own warning (*"THE ACCUMULATOR IS THE RIGHT-HAND SIDE HERE, NOT THE LEFT … The loop walks `xpList.prior` --
BACKWARD -- so the term already in `arg` sits further RIGHT in the source"*, ruleActions.interpretXP.dotFold). The rule
it implements is **KANT-43** (docs/kantCorpus.md:2032-2050): *"`a * 10 + b` is `a * (10 + b)`"* -- Tony, 2026-09-04,
*"That is how kant do… I do not want to deal with precedence"*. The dot-fold is the one left-associative exception, by
construction (foldDot, with the chain-fold stack for `a.b.c`). Juxtaposed terms with no operator collect into an `xl1`
list (`isLIST`, :1448-1452).

⚠ **interpretXP's header comment says "build the left-associative runOP tree" (:1394); only the dot-fold is.**

⚠⚠ **MEASURED: KANT-43 IS NOT UNIFORM TODAY.** `InvokeArg` has a `UnaryXP` alternative, `UnaryOPS ANYtoken` (grammar :126,
:131). So a BINARY operator whose spelling is also in the UnaryOPS bin (`-- - ++ @ ! $$ * .`, setup:181), when it follows a
NAME, is taken as that name's InvokeArg: the term takes the `dot-COMPOSED` arm and `handleDot` builds `[op, left, right]`
inside the one term, before interpretXP sees it. Literals are NumbeR tokens, so it never happens to them. Re-run by Clod,
`qa=2 qb=10 qc=3`:

| spelling | arms | reads | right-to-left would be |
|---|---|---|---|
| `qa * qb + qc` | `dot-COMPOSED primary=qa` | **23** (qa*qb first) | 26 |
| `qa - qb + qc` | `dot-COMPOSED primary=qa` | **-5** ((qa-qb)+qc) | -11 |
| `qa + qb - qc` | `dot-COMPOSED primary=qb` | 9 | 9 |
| `2 * 10 + 3` | no TokenXP terms | 26 | 26 |
| `qa / qb + qc` | all `primary` (`/` is not a UnaryOPS spelling) | 0.153846 = 2/13 | 2/13 |
| `qa + qb + qc` | all `primary` | 15 | 15 |

### 3. `result = *block(code);` and `BlocK(code)` -- where the call never happens

TODO.md:483-490 records both as kant acceptance lines, neither working; Tony's attempt is `IncantForms/WorkingOn/tester`
(`block := Grokking["BlocK"]; result = *block(code);`).

**`*block(code)`** (p3, re-run):
1. InvokeArg is Parens -- not a groupList, not fLAG -- so aCTionTokenXP takes the **`call` arm** (:1009-1011):
   `handleCall` (:1255) sets `op = falseResult` (the falsy op is the call marker, :1260) and builds the xpress LIST
   `[falseResult, block, code]` (:1266-1268).
2. Back in aCTionTokenXP, `xpress.invoke = true` (:1012); no arm set `xpress.method`, so `unaryOwed = 1` (:1018-1020).
3. **`handleUnary(xpress, *, ANYtoken)`** (:1022): `*` -> `opFields["deref"]`, builds `uxp = [deref, ANYtoken]` where
   ANYtoken is the bare `block`, not the call, and sets **`xpress.group = uxp`** (:1384-1389). `goto endToken` (:1023)
   skips `if xpress.invoke xpress.method = runOP` (:1024) -- the call node never gets a method.
4. **The line where the chain stops: GroupItem.twk:280-283.** The label now holds a group, so `dest +% lab.group` hands
   ExpressioN the `uxp`, and `lab.clear()` wipes the call list `[falseResult, block, code]`.
5. runOP on `[=, result, uxp]` fires the uxp (`arg.isMethod && arg.invoke`): op `deref` is isMethod -> `opDeref(block)`
   (Instruct.rtn:1609) -> the held field or null (:1625-1626) -- never invoked; then `opAssign` stores it.
   Contrast: handleSubscript rotates `*a[b]` (:1351-1365), and its comment says the rotation is *"gated on `=[` so an
   INVOCATION `*fn(x)` is left alone"* -- the call arm has no rotation.
   p3: `TOKENARM call primary=blk ... unary=*` -> `P3-A star res= res` (a tag echo) and no "PACT RAN"; the same action
   called without the star runs (`PACT RAN arg= hello`). On the jit road (p5) the call is lost the same way (same tree).

**`BlocK(code)`:** the `call` arm, the label goes in whole (:286) with `method = runOP`; runOP: op `falseResult`, target
`BlocK` is a rule term -> `runRule` (:1030) -> `driveStep` (:221). driveStep pushes **the field it was handed**
(`pushInput(field)`, :258; `atRuleMark = text`, GroupRules.twk:331) and unwraps the holder only one line later (:270-271),
so with `src := pSrc; BlocK(src);` **it drives the holder's own name text, "pSrc"** (p3 re-run: `MARKARM drive len=4
text=[pSrc]`, `P3-D pz= 0`). Handed the source field itself (`BlocK(pSrc)` inside an action), the body runs (p3c:
`text=[{ pz = 7; }]`, `P3-G rc= 7 pz= 7`). A top-level `tb = BlocK(pSrc)` stored nothing (p3c). The name `BlocK` resolves
to a separate instance each time it is written -- same body, its own rStuff (p3b: three nodes, one body).

### 4. Unary operators

**aCTionTokenXP's arms** (ruleActions.rtn:976-1027): a leading `.5` is refused (:987); no InvokeArg + a unary ->
`unary-only` (:993) -> handleUnary; no InvokeArg, no unary, ANYtoken in groupFields -> `dot-LEADING` (:995-997); with
InvokeArg: `.groupList` -> `dot-COMPOSED` -> handleDot (:1002); `.fLAG` -> `subscript` -> handleSubscript (:1006); else
`call` -> handleCall (:1009). **If an arm set `xpress.method` (a rotation finished the term), the unary is not applied
again (:1013-1020); otherwise handleUnary runs (:1021-1023).**

**handleUnary** (:1375-1391): `-` -> `opFields["negate"]` (setup:106, `opUnaryMinus`); `*` -> `opFields["deref"]`
(setup:107, `opDeref`); every other unary keeps its own entry -- `!` opNOT (:162), `++` opPlusPlus (:150), `--`
opMinusMinus (:137), `@` opLastREF, `$$` opDebug. All become `uxp = [op, ANYtoken]`, runOP, invoke, set as
`xpress.group`. The binary `-`/`*` slots (opMinus/opMultiply, with jit emitters) are separate entries.

**The star rotation (starDotRotation).** handleDot (:1308-1325): when `unaryIsAccess(unary)` (the `accessClass`
attribute, setup:157) and the op is `.`, it builds `[., uxp[deref, ANYtoken], arg]` -> `(*a).b`. Any other unary with a
composed op builds a separate `xp` returned as a swap and wrapped by handleUnary -> `-(a.b)`. handleSubscript does the same
for `=[`. A call is not rotated. A dot's right operand is re-minted as a data-less name unless it is a groupFields entry
(:1304-1307); `a.*b` is refused in interpretXP (`refuseDotUnaryRight`, :1524).

**At run time** runOP(uxp): op is isUnary + isMethod -> `op.method(target)` (GroupActions.rtn:1013). `opUnaryMinus`
(Instruct.rtn:1650) `tempField = 0 - operand`; `opNOT` (:892) trueResult if falsy, else **null**; `opDeref` (:1609) group
or null; `opPlusPlus` (:1140) / `opMinusMinus` (:753) work **in place** -- the iterator arm steps `result.group` and
`lastREF`, the scalar arm refuses a field with no data ("zero is not absent") and bumps gCount.

p4 (Clod's re-run agrees on the arms):

| statement | arm | result |
|---|---|---|
| `x1 = -py;` | `unary-only ... unary=-` | -5 |
| `x2 = !py;` | `unary-only ... unary=!` | tag echo -- opNOT returned null and `=` cleared x2 |
| `pp := pTarget; x3 = *pp;` | `unary-only ... unary=*` | TGT |
| `++cur;` / `--cur;` | `unary-only ... unary=++` / `--` | 2 / 1 |
| `ph := pRoot; x6 := *ph.pMid;` | `dot-COMPOSED primary=ph ... unary=*` | MIDVAL -- `(*ph).pMid` |
| `x7 := *ph["pMid"];` | `subscript primary=ph ... unary=*` | MIDVAL |

⚠ **`*a.b` is ONE term today** (dot-COMPOSED with `unary=*`, rotated to `(*a).b`). CLAUDE.md bear-trap #48 and
docs/unaryPlacement.md said it was two terms associating to `*(a.b)`; both carry a dated correction now (2026-10-06).

⚠⚠ **BINDING, RULED (Tony, 2026-10-06, R1): the 10-05 ruling `*a.b = (*a).b` stands, made UNIFORM. A prefix unary binds
to its NAME first, then the postfixes (`.`, call, subscript) apply in order. So `*block(code)` is `(*block)(code)`.** This
supersedes SEQ 218's kibitz that "postfix binds tighter than prefix". Today the subscript and dot rotations already give
`(*a)[i]` and `(*a).b`; the call arm is the one that does not (section 3).

### 5. The jit emit path

**Entry:** `testing(action)` (Commands.rtn:567) -> `jitRunAction` (jitEmitters.rtn:2968) -> `jitBuildFunction` (:130):
`ruler->jitting = 1` (:243), `processCode` (:254) builds the same trees, the frame prologue, then `jitExecBlock` (:2104)
runs `BlocK.gMethod(BlocK)` -> aCTionBlocK -> each Xpress -> runOP **under jitting**; `jitting = 0` (:326). It is
emit-on-walk: the tree executes and each op's jitting gate emits IR.

**runOP under jitting, in order:** the refused check is skipped (:993-994); inner nodes fire first through the same
`arg.method(arg)` (:997); `op.hasMembers` -> `jitEmitOpFire(op,arg,target)` (:1003; jitEmitters.rtn:878, a call to
`jitOpFireRT` :866 that runs pickKindOP and gOp at run time); `op.isOperator || op.isUnary` -> `jitSeedOperands`
(:1006, :397) -> `jitSeedLiteral` / `jitSeedField`; `jitSlotTaken(op)` (:413) -> `op.gJitEmitter(arg,target)` (:1008) --
slots installed by `jitEmitter=` (setup: `+ - * /` and the compares); a unary op carrying a slot is refused and counted
(`gJitSlotUnaryRefused`); then the ordinary ladder, each op with its own gate: opAssign -> `jitEmitAssign`, opUnaryMinus ->
`jitEmitUnary(jitNeg)`, opPlusPlus/MinusMinus -> `jitEmitUnary(jitInc/jitDec)` or `jitEmitIterStep(Back)`, opDeref ->
`jitEmitDeref` (a call to `jitDerefRT`, published on `gJitResultNode`, `jitDegrade` if it fails), opDot -> `jitEmitDot`,
a rule target -> `jitEmitTermCall` (re-runs runOP at run time, :970), an action target -> runAction's jitting arm
(`jitEmitSelfCall`, or `jitInlinePush` / processAction / `jitInlinePop`, GroupActions.rtn:947-956). Short circuit:
`runShortCircuit` -> `jitEmitShortCircuit(field)` (jitEmitters.rtn:1902): left, `jitScBegin`, right, `jitScEnd`.

p5 (testing): `ja = jb + jc` -> 5 (one slot, jitEmitAdd); `jx = -jy` -> -5; `++jcur` -> 2 (`PPWRITE ... jitting=1`);
`jr2 = *jq(jArg)` -> the call is lost, as interpreted. ⚠ **jitEmitUnary's header comment says "not wired yet … no gate
currently reaches opPlusPlus/opMinusMinus under jitting"; p5 shows it reached -- stale.** Not run: jitEmitOpFire,
jitEmitShortCircuit, jitEmitDot, jitEmitTermCall (read, not run).

### A. The instruction node

**Shared facts.** `field[n]` is `get(int)`: it walks from `firstInList` in insertion order and ignores attribute vs member
(GroupItem.twk:782). `addGroup` copies a node that already has a parent (`if group.parent group = new(group)`, :129), and
the copy shares the body -- so an operator, `falseResult` or a registered field lands in a slot as a fresh GroupItem over
the original's body (inferred), and `invoke` (a body flag) is shared with it.

**Builders:**

| site | node | how | entries, in order | missing slot? | method / invoke |
|---|---|---|---|---|---|
| aCTionTokenXP primary :998-1000 (and the `.5` refusal :987) | xpress | -- | none: `xpress.group = ANYtoken` | n/a | none |
| handleDot, no InvokeArg :1285-1291 | xpress | `+%` | `.`, ANYtoken | **no 3rd** (opDot then uses `lastREF`) | invoke; runOP at :1024. Only a bare groupFields name reaches it |
| handleDot composed :1334-1337 | xpress | `+%` | op = InvokeArg first, ANYtoken, arg = InvokeArg last (re-minted for `.`) | 3 | invoke :1012, runOP :1024; op can be any UnaryOPS entry |
| handleDot, access unary + `.` :1313-1325 | uxp + xpress | `+%` | uxp `[deref, ANYtoken]`; xpress `[., uxp, arg]` | uxp: no 3rd | both runOP + invoke |
| handleDot, other unary :1327-1333 | xp | `+%` | op, ANYtoken, arg | 3 | runOP + invoke; returned as a swap, wrapped by handleUnary |
| handleSubscript :1366-1369 | xpress | `+%` | `=[`, ANYtoken, arg | 3 | invoke, runOP |
| handleSubscript, access unary :1354-1365 | uxp + xpress | `+%` | uxp `[deref, ANYtoken]`; xpress `[=[, uxp, arg]` | uxp: no 3rd | set here |
| handleCall :1255-1270 | xpress | `+%` | **`falseResult`** (the op), ANYtoken, arg | **empty `()`: no 3rd** | invoke, runOP |
| handleUnary :1375-1391 | uxp | `+%` | op, ANYtoken | **never a 3rd** | runOP + invoke; `xpress.group = uxp` |
| foldDot plain :1240-1247 | xdot | `+%` | `.`, left, right | 3 | runOP + invoke |
| foldDot chain :1218-1239 | xdot x2 | `+%` | lower `[op, left, operand[2]]`; upper `[operand first, lower, operand last]` | 3 | runOP + invoke |
| interpretXP :1464-1474 | xl2 | `+=` | op, target, arg | always 3 | runShortCircuit if `shortCircuit`, else runOP; invoke |
| interpretXP :1448-1452 | xl1 | `+=` | juxtaposed terms, collected backward | -- | **not an instruction node** (no method); `binType=3`; can sit in an xl2's arg slot |

**A mixed shape (read, not run):** a non-access unary on a call or plain subscript (`!f(x)`, `-a[1]`): handleCall has
already added three attributes and set invoke, no method is set, handleUnary then sets `xpress.group = uxp` over the
primary and `goto endToken` skips the runOP bind -- the xpress keeps `[op, target, arg]` AND a group, invoke = 1, no method.
`*block(code)` (section 3) is this shape, which is why the call list is what `lab.clear()` wipes.

**Readers:**

| reader | where | reads | assumes |
|---|---|---|---|
| runOP | GroupActions.rtn:981-1026 | [1] op, [2] target, [3] arg | op and target non-null (`op.instructType`, `target.isMethod` read unguarded, :995); arg may be null; a call (op falseResult) reaches the `target.isMethod` arm, where `if !arg arg = target` (:1022) |
| runShortCircuit | :1041-1060 | [1] [2] [3] | target unguarded; arg guarded |
| jitEmitShortCircuit | jitEmitters.rtn:1902-1934 | [1] [2] [3] | target AND arg unguarded (xl2 always has both) |
| jitEmitTermCall / jitTermCallRT | :977 / :970 | the node by address | re-runs runOP on it at run time |
| jitEmitOpFire / jitOpFireRT | :878 / :866 | op, arg, target as runOP passes them | null operands fall back to `gJitResultNode`, else degrade |
| gJitEmitter slot emitters | runOP :1008 | the operands | unary ops refused at the fork, so a 2-slot uxp never reaches a binary emitter |
| foldDot | ruleActions.rtn:1204-1226 | `dotUxp` first/last; operand first, [2], last when `listLength == 3` | dotUxp is a 2-slot uxp; splices only when the inner first entry is the `.` |
| handleDot | :1292-1295 | InvokeArg first/last | a 2-entry UnaryXP label, not an instruction node |
| isDotUxp / refuseDotUnaryRight | :1494-1505 / :1524-1552 | `tag eq "uxp"`, `firstInList` | first entry is the `.` |
| interpretXP | :1405-1477 | the ExpressioN label list (`listLength`, `firstInList`, `prior`, `registry == opFields`) | the list, not instruction nodes |
| aCTionTokenXP | :1020, :1024 | `xpress.method`, `xpress.invoke` | -- |
| opDot | Instruct.rtn:332 | operands; `!argument` -> lastREF (:341-346); case 11 reads `invoke` (:379) | -- |
| callers that fire `node.gMethod(node)` | aCTionXpress :1151, aCTionIF :550, loopCondition :386-391, aCTionBrancH :105, appendPrintXP :1178, aCTionPrinT's jit arm :730, jitEmitGIF | the node's method | no slot reads |
| generic walkers | labelTree / labelSpans (measure), showTree (genParse), dumpField, jitPrintProbe, jitPrintList (`prior()` over an xl1) | the whole list | no positional assumption |

**Who reads `invoke`:** runOP (:995, :997), runShortCircuit (:1051, :1057), jitEmitShortCircuit (:1910, :1926),
aCTionTokenXP (:1024), opDot case 11 (Instruct.rtn:379). interpretXP also WRITES it on an operand that has `actionType ||
instructType` (:1456) -- the shared body flag (inferred).

### B. The tag's first letter

**As an OPCODE (a switch or compare on the first character):**

| site | node | decides |
|---|---|---|
| processFlags, Commands.rtn:416-453 | `command = item.tag` (read before the `if item` null check) | sets a flag on `target` (`item.parent` if `fLAG`, else item) or on the ruler -- letters below |
| processFlags' `s` arm, :447 | first char of `item.TEXT` == `d` | sort descending, else ascending |
| ruleMethod, GroupActions.rtn:917 | the define-attribute instance | `r` (`ruleMethod`) -> `parent.setMethod`, instructType 1; anything else (`operateMethod`) -> `setOperat`, instructType 2 |
| makeDataType, GroupActions.rtn:469-492 (via setInternalType, Commands.rtn:510) | the attribute instance | `b` buffer (by string) else bitmap; `f` file; `r` regex; `s` stack (setup:25, 27, 44, 66, 78) |
| aCTionBrancH, ruleActions.rtn:112-121 | the BrancheS bin label (its tag is the keyword) | `b`/`c`/`r` -> branchKind 1/2/3; under jit `c` -> jitEmitContinue, `r` -> the return path |

**processFlags' letters, and the spellings that depend on them:** `n` noPrint (`noPrint`); `M` addingMembers (`MEMBERs`);
`D` toggles `defining` (`DEFINing`); `P` `isPRINTING` (`PRINTing`); `v` isVirtual (`virtual`); `b` isBIN + a new guardSet
(`bin`); `c` isCondition (`condition`); `d` deferred (`defer`); `e` prints "Exiting parse" and exits (`exit`); `f`
notifyFail (`fail`); `i` by full string -- isIndexed / isList / isRule (`index`, `isList`, `isRule`); `m` -- `macro` ->
isMacro, any other m-word -> mergeOn (`macro`, `merge`); `s` sort (`sort`); `T` tokened (`TOKENize`); `t` tokened (no
spelling found); `u` isUnary (`unary`); **`B` has no case** -> `processFlag: invalid argument` (`BLOCKing`, setup:26 --
unused in the grammar now, so probably never fired, inferred). Which node's tag is switched on depends on the path: a
define attribute's own tag; a parse action's node (MEMBERs, DEFINing, PRINTing); and a command call through runOP's
`target.isMethod` arm, where `item` is the ARGUMENT if there is one -- so the switch runs on the argument's tag (inferred).

**As a GUARD CHARACTER:**

| site | what |
|---|---|
| addGroup, GroupItem.twk:137-142 | a node with `binType` (bin, class, list, registry) adds `*group.tag` to its guardSet. That includes bin members, registry entries, and **`xl1` juxtaposition lists** (isLIST gives binType 3) (inferred) |
| makeRegistry, :1113-1117 | the first character of every existing member |
| ensureGuard, :595-597 | an opFields node, or one with no data and no list, guards on its own tag's first character (`negate` -> `n`, inferred) |
| ensureGuard, :620 | `set(*tag)` -- **unreachable** (:595 already took `!data && !groupList`, inferred) |
| ensureGuard, :625 | a bin rule takes each member's first character |
| readers | `get(String)` :770 and `getFromList` :890 refuse a name whose first character is not in a guarded bin's set; `checkGuard` (RuleStuff.twk:49) tests the input character |

Not tag reads (excluded): resolveName's `alphaSet` test on a name (ruleActions.rtn:1642), loadDirectory's filename
characters, ensureGuard's data-text first char (:618), and the shortcut, modifier and escape strings.

### Stale text found along the way (recorded, not fixed)

- interpretXP's header (ruleActions.rtn:1394) says "left-associative"; only the dot-fold is.
- CLAUDE.md #48 and docs/unaryPlacement.md say `*a.b` is two terms; it is one, `(*a).b`.
- jitEmitUnary's header says no gate reaches opPlusPlus/opMinusMinus under jitting; one does.
- KANT-43 (docs/kantCorpus.md) states uniform right-to-left; the UnaryOPS-spelled binary operators are absorbed left.

## Step 2 -- probes (2026-10-06, read-only; Tony leads the design, R0)

**R2, the direction under study (NOT ruled):** left to right, arithmetic folded strictly left to right, with a few tiers
by split rather than a precedence engine -- assignment, comparison, and possibly short-circuit. Nothing was built; every
probe ran in the scratchpad (`scratchpad/expr3/`), the tree untouched.

### P1 -- arm stability: does an expression node take two different arms in runOP across fires?

**How:** every `incant/pop` and `incant/pop/jit` fixture (198 run; 1 has no `Start();` and was skipped) was copied to the
scratchpad with `traceParse();` inserted after `Start();`, run under a 60 s alarm, and every `RULEDISPATCH` line kept:
**480,524 dispatches**. ⚠ **Instrument limit, named:** `measureRuleDispatch` prints the TARGET's address, not the
instruction node's, so a "node" here is (fixture, target address) -- **30,952 of them**; and its `arm=` string RE-DERIVES
runOP's ladder (it does not see `hasMembers`/pickKindOP, the refused or null early returns, or the virtual copy). The
instruction node's own identity would need a tap, which R0 rules out today.

| arms seen | dispatches |
|---|---|
| runRule | 278,552 |
| operator | 119,807 |
| opMethod | 49,269 |
| method | 24,474 |
| runAction | 8,412 |
| NONE | 10 (the refusal fixtures: argRetiredT, leafLabelT, opPrefixT x5, opRoadT, testPrecedence) |

- **Targets that switch between the TARGET-decided arms (runRule / runAction / method): ZERO.**
- **1,766 targets take two OP-decided arms** -- every one `operator` + `opMethod` (one also `runRule`: anyOrNumT's
  ANYorNum). That is the signature of **two different instructions sharing one target** (a unary op and a binary op on the
  same holder, e.g. `*cur` and `x := cur`), which this instrument cannot tell from one instruction switching. An
  instruction's op slot is built once, so its op-decided arm can only change if the op node's own kind changes (inferred).
- **The target's state DOES change between fires, without changing its arm:** `actionType` 2 -> 1 (97 targets -- coded
  becoming action: generateParse 42, walkRules 9, compileRules 9 ...), `actionType` 0 -> 2 (7) and 0 -> 1 (4),
  `hasNewParse` 0 -> 1 (7 -- parser() installing), `isMethod` 0 -> 1 (7). So a design that fixes the dispatch kind at build
  time is consistent with every arm the fleet took, but the kind's DETAILS (which action road, an installed parse) move
  after build.

### P2 -- left-to-right census

**How:** a scratch census (`census.py`) over the live region (above the first column-0 `stop();`/`bail();`) of every kant
file under `incant/` and `IncantForms/WorkingOn/`, excluding the grammar and the data registries (designDocs, decoder,
jigcorpus); comments and string literals stripped; print/cerr/cout statements skipped; each statement split at its first
assignment operator; parenthesised groups, calls and subscripts treated as one operand; `.` joined into its operand.
Each expression with two or more binary operators was evaluated three ways with random operand values: **strict left to
right**, **strict right to left** (KANT-43 as written), and **today** (right to left after the measured absorption -- a
NAME followed by `-` or `*` and another NAME folds first; a number is not absorbed: `qa*3+2` = 25, `qa*qb-qb` = 40,
`qa-qb-qb` = -15, all measured). **Control (H11):** an independent line grep for code-shaped lines with two binary
operators returned the same real population (its other hits were two statements on one line, a unary `*` counted as
binary, grammar modifiers and paths). Static and approximate: each textual site counts once however often it runs.

**12 expressions in kant have two or more binary operators. 9 mix kinds.** By file:

| file | expression | ops | changes under strict left vs TODAY? |
|---|---|---|---|
| incant/pop/jit/jitAttrPop:69 | `bgBaked = bgSpec * 3 + 2` | `* +` | **YES**: today `bgSpec * (3+2)` = 25, left 17. **Pinned by jitLadder rung JA (25 / 75 / 125, bgBaked 25)**, and the fixture's own comment already says 17 |
| incant/pop/jit/jitAttrPop:70 | `layoutTotal = layoutTotal + bgBaked * applyScale` | `+ *` | **YES**: today `bgBaked*applyScale` is absorbed, then added; left would be `(layoutTotal+bgBaked)*applyScale`. Same rung |
| incant/utilities:67, 70, 72, 75 | `goodToGo = x > px && x < pxw` (and the `xw`, `y`, `yh` forms) | `> && <` | **YES** -- and see P3: today this reads `x > (px && (x < pxw))`, strict left `((x > px) && x) < pxw`; neither is the intended `(x > px) && (x < pxw)` |
| incant/utilities:302 | `if across > 0 \|\| down > 0` | `> \|\| >` | **YES** -- same shape |
| incant/utilities:253, 263 | `width = width * sideRoom / 100` (and height) | `* /` | no: today absorbs `width*sideRoom` first, which IS the left fold (strict right to left would differ) |
| incant/utilities:117 | `if !length \|\| grup IN listed` | `\|\| IN` | not evaluated (IN) |

Same kind, no change: `incant/pop/connectiveT` (`&&` x4 over calls), `incant/probes/subscriptShapes` (`+ +`).
**Total: 7 sites in 3 files change value under a strict left fold** -- 2 of them pinned by a fleet rung (jitLadder JA),
5 in incant/utilities (a display-bounds helper; no fleet row found reading it -- inferred from the census of fixtures).

### P3 -- tier census

| candidate tier | sites | where |
|---|---|---|
| (a) comparison mixed with arithmetic in one expression | **0** | none in live kant |
| (b) `&&` / `\|\|` mixed with comparison | **6** | incant/utilities:67, 70, 72, 75 (`> && <`), :302 (`> \|\| >`), :117 (`\|\| IN`) |
| assignment over a compound right side | every assignment above; today's right-to-left already puts `=` last because it is leftmost | -- |

⚠ **What (b) shows about today, recorded and not ruled:** with no tiers, the five `utilities` comparisons combine as
`x > (px && (x < pxw))` under today's right-to-left, and as `((x > px) && x) < pxw` under a strict left fold -- **neither
direction alone gives the reading the code was written for; a comparison tier above the short-circuit one does.**
