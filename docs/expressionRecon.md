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

## Candidates (D5 try-and-buy) -- recorded, nothing built

### C1 -- Tony's accumulator runOP, walked left to right (SEQ 310 R3, Tony 2026-10-06; verbatim from the dispatch)

Tony's runOP from an earlier interpreter, turned to walk left to right. The walk feeds
runOP one field at a time: the first operand becomes the running value, an op is
parked, the next operand fires (running op operand) and the result becomes the running
value. Assignment: `A =` at the head is parked and fires last. && and || decide on the
running value and reset rather than combine: && false -> skip to the next looser op
(or the end) with false; true -> start a fresh running value on what follows. || is
the mirror. Operands arrive finished per D4 (prefix, name, postfixes). The running
value belongs to the expression being executed, not to a shared field (nesting).
The exercise: simplified interpretXP and TokenXP feeding a separate runOP, beside
today's trio behind a switch, run over the difficult list. A design exercise and proof
of concept; careful coding only on a buy.

**Its measuring stick is on trunk:** `incant/pop/exprPinT`, pinned in `genLadder/pop.sh` at today's values with the
intended value beside each row (SEQ 310 R1/R2). `a = b = c` is HPDL and not on the list (R4); kant has no parenthetical
expressions (R5). **Open edge, Tony's to rule:** `qa > qb + qc` -- refuse by name, or the left fold.

**New from the pins (measured 2026-10-06, kant, trunk):** `!f(x)` loses its call the way `*block(code)` does -- neither
`!fTrue(qa)` nor `!fFalse(qa)` runs its action, and both leave a tag echo (rows O3, O3b, and the RAN count). `fFalse() &&
gSay()` runs `gSay` (S3). `utilities:302`'s `across > 0 || down > 0` reads 0 for across 0, down 5 (U302a).

### ⚠⚠ C1 BOUGHT IN PRINCIPLE (Tony, 2026-10-06, SEQ 312 R1) -- branch `expr-accum` stays pushed and UNMERGED

**`expr-accum` (Groups `31069dc`, support `fc72698`) is the reference for a careful build in a clean session; it is a
PoC and is not merged.** Built beside today's trio behind `INCANT_EXPR_ACCUM`: one gate atop aCTionTokenXP hands the label
up untouched; ExpressioN's actor is `interpretXPaccum`, which flattens each TokenXP label to raw pieces and decides by
position into ONE flat list; `runOPaccum` runs it, recursing at the parked head and at `&&`/`||`. Full report
clod-to-clay SEQ 222.

**Rulings with the buy:** print lists keep the position rule -- a prefix after a print item needs a separating
shortcut (`,*x`, `:*x`, any non-operator shortcut, multi-character included); the 10 fixtures' respell belongs to the
careful build (R2). `return falseResult;` reading truthy is banked as Clod's fixit `falseResultTruthy` (R3). `a = b = c`
stays HPDL (R4).

**M1 -- exprPinT, switch on** (qa=2 qb=10 qc=3):

| expression | today | candidate | intended |
|---|---|---|---|
| qa * qb + qc | 23 | 23 | 23 |
| 2 * 10 + 3 | 26 | 23 | 23 |
| qa - qb + qc | -5 | -5 | -5 |
| qa + qb - qc | 9 | 9 | 9 |
| qa / qb + qc | 0.153846 | 3.2 | 3.2 |
| bgSpec * 3 + 2 (jitAttrPop:69) | 25 | 17 | 17 |
| lt + bk * sc, 1 17 3 (:70) | 52 | 54 | 54 |
| utilities:70/72/75 forms at 20 | 1 | 0 | false |
| across > 0 \|\| down > 0: 0 5 / 5 0 / 0 0 | 0 / 1 / 0 | 1 / 1 / 0 | true / true / false |
| x > px && x < pxw: x 5 / 0 / 20 | 1 / echo / 1 | 1 / 0 / 0 | true / false / false |
| a && b \|\| c, 0 1 1 | 0 | 1 | true |
| a \|\| b && c, 0 1 0 | 0 | 0 | false |
| fFalse() && gSay() | 1, g runs | 1, g runs (a) | false, g does not run |
| fId(qa + qb) * qc | 36 | 36 | 36 |
| qa + fNest(qb) + qc | 37 | 37 | 37 |
| *block(src) | pz 0, r3 echo | pz 0, r3 echo (b) | pz 7 |
| -qa + qb | 8 | 8 | 8 |
| !fTrue(qa) | echo, not run | echo (null = false), fTrue runs | false |
| !fFalse(qa) | echo, not run | echo, fFalse runs (a) | true |
| *ph.pMid + 1, pMid 41 | 42 | 42 | 42 |
| hz += qa * qb, hz 1 | 21 | 21 | 21 |
| hw := qa * qb + qc | 23 | 23; its print line lost (c) | 23 |
| hx.noPrinT = hy.noPrinT | 1 | 1 | 1 |
| qa > qb + qc | echo (false) | REFUSED by name | refuse |

(a) `return falseResult;` reads truthy on BOTH roads, and so does a bare `if falseResult;` -- fixit `falseResultTruthy`;
with a body returning 0 both roads skip g. (b) Two causes, apart: on trunk the call is LOST; under the candidate it
reaches BlocK, which drives the HOLDER's name text `[pSrc]` (driveStep). (c) `" star " *hw` -- a prefix after a print item
is binary under the position rule; `,*hw` is the spelling (R2).

**M3 -- P1 answered, on trunk's road** (a tap on the instruction node, reverted md5-identical): 201 fixtures, 10,231
instruction nodes, 30 arm switches. **ONE INSTRUCTION DOES TAKE TWO ARMS**, and only one kind: a call (`op false`) whose
target is a BIN with an installed parse (`Operators`, `UnaryOPS`: isRule 0, hasNewParse 1) takes `runRule` at emit time
and the target's method when interpreted, because arm 3's door is `isRuleTerm() || (jitting && hasNewParse)` (opLenT 20,
tokJitT 6, sweepT 4). The switch is the jitting PHASE, never a change in the target.

**Switch on, the fleet (M2, information):** 1022 -> 757 green; families are the jit road refusing (R4), the
generated-parse road ("no carrier" / "no compiled body"), unescaped print stars, and value movers (pointerT, omModT,
hasActionT ...); spacingT exits 139.

**The careful build opens with a PLAN AND RECON, not a build** (SEQ 312; order Tony's to set): (a) generated-parse bodies
compiling and running under the candidate (the largest); (b) the jit road: a flat list's emit, and the one door that
checks jitting (M3); (c) D5 per road: executor kinds and instruction layout; (d) tier tests from setup data (D3), not
spelled operator names; (e) triage of the value movers and spacingT's 139; (f) the print-list respells (R2); (g) the
switch reading any value as on; (h) separately: driveStep driving a holder's name text. **After the buy lands:** the
TokenXP rule and InvokeArg's UnaryXP alternative leave the grammar, and KANT-43 retires with a dated note.

### ⚠⚠ THE CAREFUL BUILD: PLAN AND RECON (SEQ 313, Clod, 2026-10-07) -- NOTHING BUILT; TONY RULES THE ORDER FIRST (R5)

**Rulings carried (Tony, 2026-10-07):** R0 `opAddAttribute`'s `prior` -> `next` rides the walk turnaround on the
careful-build branch, never trunk. R1 the call is bound in `interpretXPaccum`'s operand build, beside the prefix; `opCall`
takes the method, action and rule cases inside itself. R2 juxtaposition wraps by default (`A += B C D` takes one list);
a per-operator "distributes" property is **banked as a later candidate, not in this plan**. R3 the `opAssign` tap. R4 a
direct runOP entry `(op, target, arg)` retires the per-step `acStep` list; a step node is always fresh, never the running
value. R5 Tony rules the order below before any build.

#### R3 -- the opAssign tap (measured 2026-10-07, trunk, kant, reverted md5-identical)

A tap on both `=` roads (`opAssign` and `jitAssignNodeRT`) printed every call and every call whose argument carries a
non-empty `groupList`. **Population:** every file in `incant/pop` and `incant/pop/jit`, every fixture the checklist
scripts name through `ip()`, and `incant/jit*` -- 209 runs, all exit 0. It would have found a list-carrying `=` in any
fleet fixture, because each fleet fixture is in that population.

| | calls | argument carries a list |
|---|---|---|
| interpreted `=` | 9,534 | **47**, in 10 fixtures |
| jitted `=` | 5 | 0 |

The 47, by what the argument is (target's own list was empty in all 47):

| argument | n | fixtures | the list is |
|---|---|---|---|
| no data, list only (`JSONblock`, `JSONvalue`, decoder records `H4` `H7` `blastRadius` `byteIdentical` `parked`, `BlocK`) | 36 | jsonTest 27, decodeT 5, decode 3, exprPinT 1 (O1's `r3 = *block(src)`) | **the whole value** -- under setData alone the target gets nothing (a tag echo) |
| a string with a `stuff` list (StringXP products) | 8 | printFamily 4, printFamilyNew 2, baselineTests 1, baselineTestsNew 1 | StringXP's parts; setData keeps the string and drops the parts |
| a count with a list (`k7Self`, `Token`) | 2 | kant8T, faceT | members beside a value |
| `xl1`, a juxtaposition list | 1 | printFamilyNew (`n4`) | a list value (R2's shape) |

⚠⚠ **RULED (Tony, 2026-10-07, SEQ 314 R2): setData is PARKED. `=` keeps setContent, and the 47 calls below are the
reason** -- the JSON reader and the decoder assign whole structures with `=`.

So `=` copying a list is **rare (0.5% of calls) but load-bearing where it happens**: the JSON reader and the decoder
assign whole structures with `=`, and under setData-only those 36 would need another spelling. The ruling is Tony's.

#### STEP (c) RECON AND PLAN -- EXECUTOR KINDS (SEQ 317, Clod, 2026-10-07; NOTHING BUILT -- R0)

Measured on `expr-accum` `020672e` in the clone (switch on, `INCANT_ACCUM_TRACE`), unless marked read.

**1. The PoC's instruction shape: ONE FLAT LIST, each operator carrying its tier mark** -- not tiers nested as sub-lists.
The operator nodes in the list are the Operators entries themselves, so their setup flags ride with them. On
`r = *blk(cv) + n * 2 > lim && ok;` (blk := fId, cv 5, n 3, lim 8, ok 1) the trace reads:

```
acX  r · = [assignTier] · acC(false, acU(*, blk), cv) · + · n · * · 2 · > [compareTier] · lim · && [shortCircuit] · ok
```

Prefix and call are already NODES inside the operand slot (acU, acC), built at instruction build. The tiers are not:
they are discovered at run time, op by op. **Value: r = 1, correct**, and every prefix of it is right (5, 8, 16, 1). On
the trunk road `x1 = *blk(cv)` reads a tag echo and the action stops there -- the known lost call. (A first probe named a
field `code`, which is a Keyword, and read wrong on both roads; it measured the probe, not the candidate.)

**2. The executor kinds that shape needs, and what each does at run time** (read, `runOPaccum`, `runOPaccumFrom`,
`runOPaccumOperand`, `interpretXPaccum`):

| kind | node | run time |
|---|---|---|
| FOLD (with the head) | `acX` | if slot 2 is `assignTier`, evaluate the tail from slot 3 and assign it to slot 1; else fold from slot 1. The fold loop: running value = first operand; for each (op, operand): `shortCircuit` -> decide on the running value, skip or recurse on the tail; `compareTier` -> refuse if arithmetic follows before the next connective; else build an `acStep [op, run, operand]` and `runOP` it |
| PREFIX | `acU` | evaluate the operand, apply the prefix entry's method (`-` -> `negate`, `*` -> `deref` by SPELLING, `GroupActions.rtn:1043-1044`) |
| CALL | `acC` | evaluate a built target (acU/acDot/acSub/acC), then `runOP [false, target, arg]` -- runOP's ladder picks rule, action or method |
| BINARY postfix | `acDot`, `acSub` | `method = runOP` on the node itself: today's runOP with the node as its instruction |
| (value) | `xl1` | a juxtaposition list; not executed -- an operand that is a list |

**3. Can the logic and compare tiers share the arithmetic fold's executor?** They do today: one loop, two flag tests per
operator per run. The two answers, with cost:

| | SHARED (today's flat list) | SPLIT AT BUILD (D3 "tiers by split", D5 "dispatch fixed at build") |
|---|---|---|
| shape | `acX` flat, tier read per op at run time | ASSIGN `[target, op, rhs]` -> LOGIC `[part, &&, part, ...]` -> COMPARE `[fold, op, fold]` -> FOLD `[operand, op, operand, ...]`, built once by `interpretXPaccum` |
| executors | one loop with two in-loop branches | four small ones, each with no tier test inside |
| run-time cost | two named attribute lookups per operator per fire (`op["shortCircuit"]`, `op["compareTier"]`), plus a scan for the next connective at each compare | none for tiers; the split is paid once at build |
| build cost | none | ~40 lines in `interpretXPaccum` to split loosest-first; the executors are today's loop cut into parts |
| D5 | the tier is a STRUCTURAL choice made at run time -- against D5's letter | fixed at build -- D5 as written |
| jit road (b) | the emitter re-derives tiers while walking | LOGIC maps to branches and FOLD to straight-line IR directly |

**R4 -- what E1 `qa > qb + qc` (qa 2, qb 10, qc 3) reads under each layout:**

| layout | E1 | how |
|---|---|---|
| SHARED, as built | **refused by name** (row reads empty) | the compareTier guard at `runOPaccumFrom` (`GroupActions.rtn:1098`) sees arithmetic after `>` |
| SHARED, no guard | **3** | `(qa > qb) + qc` = 0 + 3 -- MEASURED (seal 93's H7) |
| SHARED, with a run-time split | **0 (false)** | the split happens IN `runOPaccumFrom`'s compareTier branch: evaluate the right side as its own fold up to the next `shortCircuit` op (a recursion with a stop index), then compare -- the same move the `&&` branch already makes |
| SPLIT AT BUILD | **0 (false)** | COMPARE `[fold(qa), >, fold(qb + qc)]` = 2 > 13 -- by construction (computed from D3, not run) |

The refusal is **not** taken as the intended answer (R4); by D3 the intended value is false, and either split gives it.

**Clod's recommendation for Tony's ruling: SPLIT AT BUILD.** It is what D3 and D5 say in words, it answers E1 without a
guard, it removes the per-operator lookups, and the jit road inherits a shape it can emit. Open edge for the same ruling:
a chained comparison `a < b < c` (COMPARE with three parts) -- refuse, or fold left.

⚠⚠ **RULED (Tony, 2026-10-07, SEQ 318):** layout SPLIT BY TIER AT BUILD, the fold executor runs arithmetic only (R0);
`a < b < c` REFUSED BY NAME, pinned (R1: exprPinT E2 on trunk -- today it refuses by ACCIDENT, a null operand from the
right-to-left fold; the candidate refuses it with E1's message); C5 reads `2 10` plus a length row (R2); c1 and c2 build,
c3 and c4 wait (R3); c4 opens with a census of every reader of the `tag + "InSet"` set (R4).

**c1 LANDED on `expr-accum` `d46aa45` / support `28f0342` (2026-10-07).** Built as three functions, not two, because
measurement said so: `runOP(field)` unpacks into **`runOPslots(op, target, arg)`** -- the instruction's half: follow, refuse a
rebound argument, invoke, the virtual fork, and under jitting the term call, which bakes the RAW slots and replays
`runOPslots` at run time -- and **`runOPdirect(op, target, arg)`** fires on FINISHED operands (D4). The accumulator finishes
its own operands and builds no step list. **The finding that forced the split:** with `runOPdirect` still resolving its
operands, holderT recursed to a stack overflow (exit 139) -- the head's value was the unevaluated `acDot` (`htKid.parenT`,
invoke 1), and `runOPdirect` invoked it again; the old step list had hidden this, because `+%` handed runOP a copy that had
lost its invoke (measured in lldb). That run is c1's H7. **Certificate:** switch off row for row with seal 93 (1073, 0
differ); switch on 757 -> **772**, fifteen rows red -> green (jsonTest JT-2/3/5/TREE, omModT OM-1 x2 / OM-2 x4, ruleTermT
RT-1..4), none green -> red. That those fifteen were the step list's copies is INFERRED, not measured. jitLadder, printPop,
decodePop PASSED; canary 317.

**c2 LANDED on `expr-accum` `2600a8a` / support `7d06fad` (2026-10-07).** `opCall(target, arg)` -- rule, action, method, in
runOP's old order; `callIsRule` is M3's door in ONE predicate, read by opCall and by runOPslots' jitting term-call
intercept, so no instruction changes executor between phases. runOPdirect's ladder: operator, method op,
`isCallable(target)` -> opCall, else the unknown-operator refusal. The accumulator's `acC` goes straight to opCall, with
the dispatch witness kept at its seat (without it `searchNewParseT SNP-0` went red -- measured). **Certificate:** switch off
and switch on both row for row with c1 (1073 / 1075 rows, 0 differ; on 772). **H7:** opCall's action case removed ->
every action call refuses by name through opCall (A1, A2, ... and no values); restored md5-identical. Canary 320.
**Next is c3, the layout -- a real design build (SEQ 318's note): check with Tony before it opens.**

**c3 LANDED on `expr-accum` `15f8b28` (2026-10-07, SEQ 319).** The flat list is consumed left to right and rebuilt
loosest first, ONE NODE AND ONE EXECUTOR PER TIER, set at build: `acA` (runAccAssign, a single step), `acAnd`/`acOr` (left
side, early-out, right side if needed; nested to the left, so `a && b || c` is `(a && b) || c`), `acK` (runAccCompare, a
single step), `acKchain` (a second comparison in one part -- refused by its own name at run time), `acX` (runAccFold, which
asks no operator for a tier). Every item is DETACHED from the flat list before it is re-attached (`accPop`), because
`addGroup` copies a node that already has a parent -- c1's hidden-copy lesson, designed out. `runOPaccumFrom` is gone;
`runOPaccum` keeps the prefix and the call. Canary 331.
**Certificate:** switch off row for row with c2 (1073, 0 differ); switch on row for row with c2 but for **E1, refused ->
false** (reads `qr`, trunk's pin; 772 -> 773). **E2** now refuses as *"a chained comparison (a < b < c) -- refused by name"*
(its rows are trunk-only, read directly). No other mover. Call rows and C3 hold (12, 15, 36, 5, `xl1InSet`, -2); the sample
`r = *blk(cv) + n * 2 > lim && ok` reads 1. jitLadder, printPop, decodePop PASSED.
**H7 -- the ruled one is MASKED (H17), and the masker is named.** Giving the compare node the fold executor stays GREEN:
the compare node already holds two FINISHED folds, so folding `[left, >, right]` is the same single step. The structure,
not the executor, carries the answer. **The unmasked control:** the builder stops splitting at a comparison -> E1 reads
**3** (the left fold) and E2 no longer refuses -- red. Both runs restored md5-identical.

**4. The rest of (c) -- the plan (R2), in build order, each a stroke with its own certificate:**

**(c1) runOPdirect(op, left, right).** runOP's body moves into it; `runOP(field)` becomes the three-slot unpacker for every
existing caller (acDot, acSub, the trunk road). **Snag, from the read:** runOP's rule arm under jitting is
`jitEmitTermCall(field)`, which bakes the INSTRUCTION NODE's address into IR (`jitEmitters.rtn:977-991`) -- so that arm
cannot live in a function that has no field. It moves to opCall (c2), which keeps its call node. The accumulator then calls
runOPdirect with no step list (retires `acStep`; R4 of SEQ 313). Certificate: switch off and on row for row with seal 93.

**(c2) opCall, the CALL executor.** `acC` stops going through `runOP [false, ...]`. Inside opCall, in TODAY's order (runOP's
ladder, so the certificate can be row for row): **rule** -- `isRuleTerm()`, or `hasNewParse` under jitting, which is M3's
door, now inside one executor (interpreted: `runRule`; jitting: `jitEmitTermCall` on the call node); **action** --
`actionType`, `runAction(arg, target)`; **method** -- `isMethod`, `target.method(arg)`, with the target as its own argument
when there is none (`field()`). The invoked-field resolution runOP does first (`target.invoke` -> `target.method(target)`) and
`followArgument` come with it. (h) is NOT in this stroke: it is step 4, inside opCall's rule case.

**(c3) the layout** -- SPLIT AT BUILD if ruled: `interpretXPaccum` splits loosest-first; FOLD / COMPARE / LOGIC / ASSIGN
executors; the compareTier guard retires; E1 moves to false (its pin moves, with a sentence). If SHARED is ruled: the
run-time split in `runOPaccumFrom`'s compareTier branch, and the guard retires the same way.

**(c4) the turnaround.** ⚠ **THE READERS ARE SHARED BY BOTH ROADS, SO BOTH BUILDERS TURN TOGETHER.** Trunk's interpretXP
builds `xl1` right to left (`ruleActions.rtn:1446-1450`, appending the left term after the right), and so does the PoC on
purpose (`interpretXPaccumWrap`'s reverse loop). Flipping the readers while the switch-off road still builds reversed would
reverse every list on that road -- the switch-off certificate could not hold. **So c4 is one stroke:** the PoC builds in
source order (drop the reverse loop), the old interpretXP PREPENDS instead of appending (same source order, still walking
backward), and every reader below flips `prior` -> `next`, in one commit.

**The readers** (census: every `isLIST` in `*.rtn`, `*.twk`, `incant/setup`, `incant/utilities`, `incant/grammar` on trunk,
plus the branch's builder):

| site | reader | walk today | at c4 |
|---|---|---|---|
| `Instruct.rtn:60` | opAddAttribute (`+%`) | prior | **next** (R0 of SEQ 313) |
| `Instruct.rtn:319` | opDivEQ | prior | next |
| `Instruct.rtn:743` | opMinusEQ | prior | next |
| `Instruct.rtn:875` | opMultiplyEQ | prior | next |
| `Instruct.rtn:1333` | opAddMember (`+/`) | prior | next |
| `Instruct.rtn:1352` | opReplaceAttribute (`:%`) | prior | next |
| `Instruct.rtn:1374` | opReplaceMember (`:+`) | prior | next |
| `Instruct.rtn:1073` | opPlusEQisSTRING | `appendGroup(argument, ...)` | read appendGroup's walk at c4 |
| `Instruct.rtn:1129` | opPlusEQstruct | `copyListTo` -- STORED order, i.e. reversed today | becomes source order (a mover, with a sentence) |
| `GroupActions.rtn:70` | printField | prior, or next under `reversePrint` | next; `reversePrint` inverts |
| `jitEmitters.rtn:2627` | jitPrintList (from `ruleActions.rtn:725`) | prior | next |
| `Instruct.rtn:1042/1058/1097/1114` | `+=` kind members | refuse a list | order-free |
| `GroupActions.rtn:592` | pickKindOP | shape test | order-free |
| `ruleActions.rtn:1449`, `interpretXPaccumWrap` | the two BUILDERS | -- | source order |

⚠ **The population's limit, said out loud:** this census finds code that TESTS `isLIST`. Code that walks an argument list
WITHOUT testing the flag is not in it. The c4 certificate (fleet row for row on both roads, movers named) is what covers
that gap.

**C5 red -> green (R2 of SEQ 317):** C5 `fId(qa qb)` reads `xl1InSet` for a reason the turnaround alone does not touch:
`xl1` carries a SET -- the GroupList constructor names a bin-typed item's list `tag + "InSet"` and gives it a character set
(`GroupList.twk:21-26`), and SEQ 313's tap read `xl1` with `data=3` (isSET) -- and `=` copies that across. So C5 goes green
when (i) the list is in source order (c4), (ii) `xl1` stops carrying a set, and (iii) a printed list prints its members.
**The intended printed form is Tony's to state** (the pin asserts one token today); Clod's proposal: the members' values in
source order, `2 10`, plus a row for the list length.

**Context, left alone (Tony):** the `+`, `*` and `?` Operators entries carry `repeatClass`, which is the Modifiers
registry's flag (trace above; seal 92's walk counted it in their list lengths). No row fails on it.

#### STEP (d) RECON -- TIERS FROM SETUP DATA (SEQ 315, Clod, 2026-10-07; recon only, NOTHING BUILT -- R0)

**(a) Where the candidate decides a tier by spelled name** (`expr-accum` `5868d69`, read; every `tag eq "` and
`opFields["` in `runOPaccum*` and `interpretXPaccum*`):

| site | decides | how |
|---|---|---|
| `GroupActions.rtn:1055` (runOPaccum) | **assignment tier** -- a head op is parked and fires last | **15 spellings**: `=` `:=` `+=` `-=` `*=` `/=` `<-` `:%` `:+` `+%` `+<` `+/` `+*` `:.` `<:` |
| `GroupActions.rtn:1099` (runOPaccumFrom) | **comparison tier** -- refuses a comparison whose right side continues into arithmetic | **8 spellings**: `>` `>=` `<` `<=` `==` `!=` `~=` `IN` |
| `ruleActions.rtn:1892/1900` (opIsShortCircuit, opIsOR), called from runOPaccumFrom | **logic tier** and its skip direction | **already data**: `shortCircuit` and `isOR` flags on `'&&'`/`'||'` in setup |
| everything else | **arithmetic fold** | the default: whatever is not in the three above |

Not tiers, recorded so the census is whole: `GroupActions.rtn:1043-1044` map a prefix `-`/`*` to the `negate`/`deref` entries
(spelled, a prefix question, not a tier); `ruleActions.rtn:1554/1602` find the `.` postfix (structural); `acU`/`acC`/`acX`/
`acDot`/`acSub`/`acJux`/`acPostCall`/`acPostSub` are the candidate's own node kinds, not operators. **Untiered entries that
fold by default today:** `=[` `=/` `=%` `=<` (the opGet family), `modedOP`, `%`, and the unbound `|` `^` `?` `>>` `<<` `:>`
`:<` `:-` `GO` `&`.

**(b) Operators entries that carry members** (measured, trunk binary, a walk over Operators reading `hasMemberS` and
`listLengtH` through `:=` captures): **53 entries; exactly one has members -- `'+='`** (hasMembers 1, seven kind members).
Five others have a non-empty list made only of flag attributes (`||` 2, `*` 2, `&&` 1, `+` 1, `?` 1), and `'+='` is the
positive control the walk had to find.

**(c) Does a tier attribute on an entry with members trip bear-trap #56?** Scratch probe: five copies of `incant` in the
scratchpad (setup edited, `IncantForms` linked read-only), each run with a read-back (`dumpContents` of `'>='` and `'+='`)
and an lldb hit count of the `+=` methods, from a fixture whose `:=` holder target falls to the PARENT's own method
(`pickKindOP` has no `+=isGROUP` member) and whose count target takes `+=isCOUNT`. `'>='` carries `tier=compare` in V1-V4 as
the no-members control.

| variant | `'+='` spelling | `tier` reads back | parent method hit | `+=isCOUNT` hit |
|---|---|---|---|---|
| V0 control | today's setup | -- | **opPlusEQ** 1 | 1 |
| V1 | `tier=assign` on the FIRST mention, members on the reopened one | `assign` | **opPlusEQ** 1 | 1 |
| V2 | `tier=assign` on the REOPENED mention, with the members | `assign` | **opPlusEQ** 1 | 1 |
| V3 | bare flag `tierAssign` on the reopened mention | present | **opPlusEQ** 1 | 1 |
| V4 | ONE mention: `operateMethod=opPlusEQ tier=assign` + members | `assign` | **opPlusEQstruct** 1, opPlusEQ **0** | 1 |

**#56 does not bite the tier; it bites the binding.** The tier attribute reads back as written in all four shapes. The one
that fails is V4, #56's own hazard-2 shape (attributes and members on one mention), and what fails is `operateMethod=`: the
parent binds to its LAST member's method (`opPlusEQstruct`; #56 recorded `opPlusEQisCOUNT` under the member order of the
day). Today's two-mention shape is safe whichever mention carries the tier. `'>='` read back `compare` in every variant.

**(d) Candidate spellings, each with its cost:**

| | spelling in setup | reader | cost |
|---|---|---|---|
| **T1** | **bare flags**, the `shortCircuit`/`accessClass` precedent: `assignTier` on the 15, `compareTier` on the 8; the logic tier IS `shortCircuit` (no third flag -- two flags for one fact is two channels, one meaning) | `op["assignTier"]` / `op["compareTier"]` presence, as opIsShortCircuit reads today | 23 setup edits; two 4-line helpers (`opIsAssign`, `opIsCompare`) beside opIsShortCircuit; the two spelled lists go. `'+='` takes its flag on the FIRST mention (V1 shape) |
| **T2** | **one valued attribute** `tier=assign` / `tier=compare` (arithmetic = absent) | `op["tier"]` read, then its TEXT compared | same 23 edits; one helper returning a tier number -- but it compares text against tier names, so a spelling survives in the reader, and a typo in setup (`tier=asign`) silently folds as arithmetic |
| T3 | off the attribute entirely: a bin per tier in `pROPERTIEs`, the `UnaryOPS bin` shape (`AssignOPS bin` listing the 15) | `AssignOPS[op.tag]` | **not needed -- #56 does not bite the tier (c)**; it names every operator a second time, so adding an operator and forgetting its bin drifts silently |

**Clod's recommendation, for Tony's ruling: T1.** It is the shape the tree already uses for this exact question one tier
over (`shortCircuit`), it is a presence test with no text in the reader, and a misspelled flag is a missing flag -- which the
fixture rows (exprPinT's U70/B-rows and the `=` rows) see as a value move rather than a silent fold.

⚠⚠ **RULED T1 (Tony, 2026-10-07, SEQ 316) and LANDED on `expr-accum` `020672e` / support `3d0d354`:** `assignTier` on
the 15, `compareTier` on the 8, `shortCircuit` the logic tier, everything else (the `=[` family included) folds as
arithmetic. `opIsAssignTier`/`opIsCompareTier` beside `opIsShortCircuit`, mirrored in groups.ext; the two spelled lists are
gone. `'+='` keeps two mentions, flag on the first, the reopened one naming #56. **Certificate:** switch on 757 row for row
with seal 91's switch-on run (1075 rows, 0 differ); switch off 1022 row for row with seal 91's switch-off run (1073, 0);
canary 313 -> 315. **H7:** `compareTier` dropped from `'>'` -> E1 `qa > qb + qc` stops refusing and folds to **3**, the one
row that moves; restored md5-identical.

**Carried (R2): C5 `fId(qa qb)`** stays RED in step (c)'s certificate (pinned today at `xl1InSet`; intended a two-member list)
until the turnaround builds the juxtaposition list in source order, and is **not re-pinned as a mover**.

#### R1 -- where the call binds, and whether its argument is one entry

**Read on `expr-accum` (Groups `31069dc`):** pass 1 of `interpretXPaccum` wraps a TokenXP's `InvokeArg` that is
neither a UnaryXP (`.b`) nor a subscript (`fLAG`) in an `acPostCall` piece holding the InvokeArg node; pass 2 builds
`acC` from it with `handleCall(node, cur, term[1])` -- **already in the operand build, beside the prefix**, so R1's seat
exists. `handleCall` hands on `[false, target, arg]`, with `arg` the InvokeArg's group, or the node itself if it has a
list or data, and **no third operand for an empty `()`**.

**The argument is one entry by grammar:** `Parens leftParen-="(" ExpressioN? rightParen-=")"` (`incant/grammar:130`) --
one optional ExpressioN, and `,` is in ExpressioN's guard, so `f(a, b)` cannot arrive at all. Under the candidate that
ExpressioN is built by `interpretXPaccum` like any other, so `f(a + b)` arrives as one acX, `f(a b)` as one xl1 (R2),
`f()` as nothing. ⚠ **Grade: read, plus seal 87's measured N1/N2 (`fId(qa + qb) * qc` = 36, `qa + fNest(qb) + qc` = 37
on the candidate). The C rows below were NOT run on the candidate** -- a branch build was declined this session (see
SEQ 224), so they carry trunk values only. **The stop condition did not fire on anything read or measured.**

**Call rows, trunk (2026-10-07, a copy of exprPinT with six rows added; qa 2 qb 10 qc 3):**

| row | expression | trunk | intended |
|---|---|---|---|
| C1 | `qa + fId(qb)` | 12 | 12 |
| C2 | `qa + fId(qb) + qc` | 15 | 15 |
| C3 | `fId(qa + qb * qc)` | 32 | 36 |
| C4 | `fNone()` (empty argument, returns 5) | 5 | 5 |
| C5 | `fId(qa qb)` | `xl1InSet` | a two-member list (R2) |
| C6 | `fId(-qa)` | -2 | -2 |
| O1 | `*block(src)` | pz 0, r3 echo | pz 7 |

**How the two required shapes come out under the plan:**
- **`a + f(x)`:** flat list `[a, +, acC]`; the running value is `a`; the operand `acC` runs `opCall(f, x)`, the call
  executor picks the action case, and its value is the right operand of `+`. Measured shape: N2 = 37.
- **`*block(code)`:** `*` is an access prefix, so it binds to the name first (D4): `acU(*, block)`; the call postfix then
  makes `acC(acU(*block), code)`. The acU evaluates to the `BlocK` rule and `opCall`'s **rule case** drives it. That
  reaches BlocK today on the candidate -- and then **(h)**: driveStep drives the HOLDER's name text `[pSrc]`, because
  `code` is a `:=` holder and `followArgument` follows only `isArgument` holders. **`*block(code)` comes out right only
  when (h) lands with the call executor**: the rule case reads a holder argument through to what it holds before driving.
- **`!f(x)`:** `!` is not an access prefix, so it wraps the finished operand: `acU(!, acC(f, x))`, and the call runs.

**The call executor (`opCall`), one kind, cases inside (D5):** method (`target.isMethod`), action (`target.actionType`),
rule (`isRuleTerm()`, or `hasNewParse` under jitting -- **M3's one door that reads `jitting` moves inside this executor**,
so no instruction switches executor between phases; the phase is a run-time choice inside it, which is what D5 allows).
`field()` is the same executor with no argument; the method case then hands the target as its own argument, as runOP's
last arm does today.

#### R4 -- the direct entry, and the step list

`runOPaccumFrom` mints a fresh `acStep` per step and `runOP` unpacks it as `field[1..3]`. **Plan:** split runOP's body
into `runOPdirect(op, target, arg)`; `runOP(field)` becomes a three-line unpacker for every existing caller, and the
accumulator calls the direct entry, so **no step list is built at all**. Tony's sketch's `result +% *op *result *grup`
attaches the running value to itself; the PoC already used a fresh node, and the direct entry retires the question --
where any list must still be built, it is a fresh node. The running value's copy-out of `tempField` stays. ⚠ **One
correction to carry into the build: operand order.** runOP's target is the LEFT operand; a right-to-left sketch must hand
`[op, left, right]`, not `[op, running, next]`.

#### R0 and R2 together -- the list's order

The PoC holds juxtaposition lists **right to left on purpose** (`interpretXPaccumWrap`'s `acJux` -> `xl1` loop) so that
`opAddAttribute`'s `prior` still yields source order (probe 2026-10-07: `aoBag +% aoA aoB aoC` reads aoA, aoB, aoC on
trunk). The turnaround stroke builds `xl1` in source order and flips `prior` -> `next` in the same commit. **Owed in that
stroke: a census of every other reader of an `isLIST`/`xl1` operand** (`jitPrintList`, `GroupActions.rtn:70`, any
`iterate` over an argument), because each one walks the order it was built for.

#### R5 -- the proposed order for (a)-(h)

⚠⚠ **RULED AS WRITTEN (Tony, 2026-10-07, SEQ 314 R0).** Step 0 LANDED 2026-10-07: C1-C6 pinned in exprPinT, pop.sh
1029 / 51 (H7: C1's argument and fNone's line mutated -> both rows red by value; restored md5-identical).

**Step (g) LANDED on `expr-accum` 2026-10-07 (`5868d69`, built and measured in a clone outside Dropbox, SEQ 314 R1):**
`exprAccumOn()` in `jitContext.h` reads the switch's VALUE -- `1` on; unset, empty or `0` off; anything else off with one
stderr line. Before it, `INCANT_EXPR_ACCUM=0` switched the candidate ON (pop.sh 757 at `=0`). After: `=0` reads 1022 row for
row with switch-off before; `=1` row for row with switch-on before; the before-binary's `=0` run differs by 556 lines.

**The call rows on the candidate (owed from SEQ 313, measured the same day in the clone, switch on):** C1 12, C2 15,
**C3 36** (trunk 32; intended 36), C4 5 with one fNone line, **C5 `xl1InSet`** (unchanged; intended a two-member list),
C6 -2; N1 36, N2 37, O1 pz 0 / r3 echo as seal 87. The argument arrived as one entry in every row; R1's stop did not fire.

| step | item | why here |
|---|---|---|
| 0 | **pin C1-C6 into exprPinT on trunk**, at today's values with the intended beside (D6's pattern) | the call rows are the measuring stick for step 3; today they live only in scratch |
| 1 | **(g)** the switch reads its value, not its presence | every later measurement is taken through the switch; one line, and an `INCANT_EXPR_ACCUM=0` that reads as ON would void a control run |
| 2 | **(d)** tier tests from setup data (D3) | removes the spelled operator lists from `runOPaccum`/`runOPaccumFrom`; small, and step 3's executors read the tiers |
| 3 | **(c)** executor kinds and instruction layout, interpreted road: `opCall` (R1), `runOPdirect` (R4), the walk turnaround with R0 and its `isLIST` census | the core; everything after it reads its layout |
| 4 | **(h)** the call executor's rule case reads a holder argument through | finishes `*block(code)` = pz 7; small, and it belongs to step 3's executor |
| 5 | **(e)** triage of the value movers and spacingT's 139 | movers measured after the core moves, not before -- step 3 may move them again |
| 6 | **(f)** the print-list respells (R2's `,*x`, 10 fixtures) | mechanical; after (e) so a respell is not mistaken for a mover |
| 7 | **(a)** generated-parse bodies under the candidate | the largest; it compiles against the instruction layout step 3 fixes, so it waits for it |
| 8 | **(b)** the jit road: a flat list's emit | last, on a settled layout; M3's door is already inside `opCall` from step 3 |

**After the buy lands (unchanged):** the TokenXP rule and InvokeArg's UnaryXP alternative leave the grammar; KANT-43
retires with a dated note. **Banked, not planned:** R2's per-operator "distributes" property.

### C1 FLOW -- the build-time call chain, interpretXP to the finished tier tree (SEQ 320, Clod, 2026-10-07)

Measured on `expr-accum` `fbb5561` (lldb at `accBuilt`, `IncantForms/WorkingOn/tester`'s `c1Builds`, switch on). Lines are
the branch's sources; the Xcode `.mm` line is given where Tony will set the breakpoint.

**Run it:** scheme environment `INCANT_EXPR_ACCUM=1` (the candidate; unset or `0` is today's road) and, for the printout,
`INCANT_ACCUM_TRACE=r` (only expressions whose first item is `r`; `=1` prints every expression).
**THE BREAKPOINT** -- the tree finished, nothing run: `ruleActions.rtn:1640` `if traced accBuilt(node);` =
**`GroupRules.mm:3483`**, or the symbol **`accBuilt`** (it is called only for traced expressions, so with `=r` it stops on
the `r = ...` lines alone). `node` there is the root.

⚠ **COMPILATION IS LAZY.** An action's body is parsed and built on its FIRST CALL, not at `define`: the chain below starts
from `c1Builds()` being run. So both trace prints come before `C1 variant begin`.

| # | method | file:line | what it does |
|---|---|---|---|
| 1 | `runOPaccum` (acC arm) | `GroupActions.rtn:1098` | the statement `c1Builds();` -- a call, handed to opCall |
| 2 | `opCall` | `GroupActions.rtn` (c2) | the call executor: `c1Builds` is an action -> `runAction` |
| 3 | `runAction` | `GroupActions.rtn:932` | binds the argument, and on a first call has the body compiled |
| 4 | `processCode` | `GroupActions.rtn:669` | compiles the action's CodE: `driveStep(code, BlocK, ...)` at `:702` |
| 5 | `driveStep` | `GroupActions.rtn:221` | drives the BlocK rule over the code text |
| 6 | `GroupItem::parse` / `testAttributes` / `testOptions` | `GroupItem.twk:1298`, `RuleStuff.twk` | recursive descent: statement -> Xpress -> ExpressioN -> Token+ |
| 7 | `aCTionTokenXP` (per term) | `ruleActions.rtn:976`, gate `:985` | each TokenXP's actor; under the switch it hands its label up UNTOUCHED (`exprAccumOn`) |
| 8 | `GroupItem::fireLabelMethod` | `GroupItem.twk:710`, fire `:732` | ExpressioN matched: fires its actor on the label -- `interpretXPaccum`, installed at bootstrap by `setActions` (`GroupItem.twk:1665`, `exprAccumOn`) |
| 9 | `interpretXPaccum` pass 1 | `ruleActions.rtn:1497`, `:1502` | flattens every TokenXP label into raw pieces -- unary, name, InvokeArg -- in `acSeq` (`:1518` prefix, `:1534` call/subscript) |
| 10 | `interpretXPaccum` pass 2 | `ruleActions.rtn:1538` on | decides BY POSITION into `flat`: op where an operand is expected = prefix (`interpretXPaccumU`, `:1773`); `.` builds acDot; a call builds acC (`handleCall`, `:1258`, at `:1579`); a subscript acSub (`:1587`); juxtaposed operands wrap to xl1 (`interpretXPaccumWrap`, `:1785`) |
| 11 | `accTraceWanted` / `accTraceFlat` | `ruleActions.rtn:1633` | under `INCANT_ACCUM_TRACE`, prints `ACCUM FLAT` before the split consumes the list |
| 12 | `accBuild` | `ruleActions.rtn:1681` (called `:1638`) | assignment head -> acA (target, op, the rest) |
| 13 | `accLogic` | `:1697` | && / || -> acAnd / acOr, nested to the left |
| 14 | `accCompare` | `:1720` | one comparison -> acK; a second -> acKchain |
| 15 | `accFold` | `:1750` | (op, operand) while arithmetic -> acX; one operand alone is itself |
| 16 | `accPop` | `:1658` | takes an item off `flat`, parent cleared, so `+%` attaches it and not a copy |
| 17 | **`accBuilt`** | `:1867` (called `:1640`) | **THE BREAKPOINT** -- prints `ACCUM TREE`; then `xpList.group = node` (`:1642`) |

**What the tree reads** for `r = *blk(cv) + n * 2 > fId(qa + qb) - lim && ok || !done` (c1Builds) -- exactly Clay's
prediction: `acA [r, =, acOr [acAnd [acK [acX [acC [false, acU [*, blk], cv], +, n, *, 2], >, acX [acC [false, fId, acX [qa,
+, qb]], -, lim]], &&, ok], ||, acU [!, done]]]`; it runs to **r = 1**.
⚠ **THE RULED LINE (`... > lim - fId(qa + qb) ...`, c1Run) DOES NOT PARSE, ON EITHER ROAD.** `-` is in UnaryOPS, so
InvokeArg's `UnaryXP UnaryOPS ANYtoken` alternative absorbs `- fId` into `lim`'s term, and `(qa + qb)` is then a SECOND
postfix that TokenXP's single `InvokeArg?` cannot take (bear-trap #52). `lim - fId(qa + qb)` alone fails the same way;
`qa + fId(qb)` parses because `+` is not in UnaryOPS. It is the grammar change already queued "after the buy lands".

### c4's OPENING CENSUS -- who reads the `tag + "InSet"` set (SEQ 320 R4, read only, trunk sources, 2026-10-07)

**What the set is.** `GroupList(GroupItem item)` (`GroupList.twk:20-27`, generated `GroupList.mm:25-38`): for ANY item whose
`binType` is non-zero -- BIN, CLASS, **LIST**, REGISTRY -- a new `PLGset` named `tag + "InSet\n"` becomes the item's
`characterSet` (`setCharacterSet`, `GroupItem.twk:1704-1705`, which also makes its DATA isSET), a `guardSet` is made, and
`guarding` is set. `addGroup`'s binType block (`GroupItem.twk:136-143`) then adds each child's first character to the
guardSet and its name to the characterSet. **For a bin that is the point** -- first-character membership for parsing.
**For a list it is an accident**: `xl1` is `binType` LIST, so it gets a bin's set.

**Who makes LIST-typed items:** trunk's interpretXP (`ruleActions.rtn:1449-1450`, xl1), the branch's
`interpretXPaccumWrap` (xl1), and the `isList` command (`Commands.rtn:434`, registered `incant/setup:49`, used once:
`incant/utilities:193` `newStuff isList;`).

**The readers** (census: every `characterSet`, `guardSet`, `guarded`/`guarding`, `isSET`, `InSet` in `*.twk`/`*.rtn`):

| reaches a LIST value? | reader | file:line | what it does with the set |
|---|---|---|---|
| **yes -- C5's symptom** | `getText` | `GroupItem.twk:1046` | `case isSET: junkText = characterSet.name` -- a list prints as `xl1InSet` |
| **yes -- how it travels** | `copyData` via `setContent` (`=`) | `GroupItem.twk:391-402` | copies `data` and the `gText` union: the target gets isSET and THE SAME set pointer |
| yes | `opIN` | `Instruct.rtn:587-591` | an isSET operand is tested as a CHARACTER SET -- `x IN list` asks the InSet set |
| yes | `getType` | `Commands.rtn:208` | an isSET value reports type `PLGset*` |
| yes, consistently | `get(name)`, `getFromList` | `GroupItem.twk:770`, `:890` | `guarded && !guardSet.contains(*name)` -- the first-character reject on a name lookup |
| yes | `getCharacterSet` | `GroupItem.twk:848-849` | hands the set out for an isSET item |
| parse only (bins and rules) | `checkGuard`, `ensureGuard`, `setTestMatch`/`testSet`/`testContainer`/`upToMatch` | `RuleStuff.twk:46-49, 128, 241, 273, 329`; `GroupItem.twk:579-655` | the parser's first-character tests |
| parse only | `parseContainer`, `parseSet`, `setParseWalk` | `Generate.rtn:185, 350, 473` | generated parse of a container or a set |
| setup and commands | `guard`, `processFlags`, `aCTionSetBrackets`, `makeRegistry`, `bootstrapper`, `setColor` | `Commands.rtn:237-251, 421-423`; `ruleActions.rtn:891`; `GroupItem.twk:1115-1117`; `GroupMain.twk`; `Stylish.twk:136` | build or read sets for bins, rules and colours -- not for a list value |

⚠ **The population's limit:** this finds code that NAMES the set's fields. A reader that switches on `data` with an
isSET case it does not name this way (a `printField` switch, a jit kind table) is not in it; c4's fleet certificate covers
that gap. **What it says about c4:** the set is a bin's tool attached to lists by `binType != 0`, and the readers that a
LIST value reaches are the six "yes" rows -- the place to stop it is the two writers (`GroupList(item)` and `addGroup`'s
binType block), where LIST can be told apart from the bin kinds. Nothing built.

### ⚠⚠ c4 STOPPED BY R1 -- THE TURNAROUND IS CLEAN; C5's `2 10` NEEDS A RULING (SEQ 322, Clod, 2026-10-08; nothing committed to expr-accum but the merge)

**R0 done:** trunk `e93c164` (seal 99 + Tony's tester) merged into `expr-accum` as `5ed1536`, support `main` as `2acfa25`.
Fleet off 1031 (seal 98's 1022 + trunk's nine exprPinT rows), on 780 (773 + seven of the nine), every older row row for
row; canary 337.

**What was probed, in the clone, parked on branch `c4-probe` (`9942cc1`, uncertified):**
- *(i) the turnaround.* trunk's interpretXP appends a juxtaposed term with `+=` (addGroup's work kept) and then moves it
  to the FRONT (`listLastToFront`, a relink: no copy, listLength and parent untouched), so xl1 ends in source order;
  `interpretXPaccumWrap` drops its reverse loop; the seven Instruct readers, printField (`reversePrint` now inverts) and
  jitPrintList walk `next`. Canary 338. **Fleet off 1031, on 780 -- zero movers on either road** (heap addresses only).
- *Order witness* (one probe, three rows): `holdA = fId(qa qb qc); holdA[1], holdA[3]` reads **3, 2 on trunk** and **2, 3
  on the probe**, both switches; `holdB +% qa qb qc` and `cerr qa qb qc` read the same on both (2 3 / 2 10 3). So the
  stored order turned and the flipped readers hand back what they always did -- which is why the fleet does not move.
  ⚠ **The fleet is order-symmetric here: a pair that flips together is invisible to it.** copyListTo (`+=` on a struct
  with a list argument), the census's predicted mover, moved nothing: no fleet row reaches it with an xl1.
- *(ii) xl1 stops carrying the set:* `GroupList(item)` and addGroup's binType block skip a LIST. **One mover on each
  road: C5 `xl1InSet` -> `5`.** Nothing else moved, so no other InSet reader the census names (copyData, opIN -- which
  tests `groupList` before the set, so a list argument never reaches the set -- getType, the get/getFromList guard,
  getCharacterSet) changed a fleet row.

**Why C5 reads `5`, and why that is the stop.** `qr = fId(qa qb)` is `setContent(xl1)`. With no set, xl1 has a list and
NO DATA, so setContent copies the list and leaves qr's data alone (`GroupItem.twk:1722-1733`) -- qr still holds C4's `5`
(row C4, `qr = fNone()`, runs just before). **Read from the code and that ordering, not isolated by a run.** The print
then prints qr's data. So `2 10` cannot come from the turnaround or from removing the set: it needs a decision
about **what `=` does with a data-less list value, and how such a value prints** -- that is the census's getText and
copyData rows, i.e. an InSet reader that needs a ruling (R1's stop). Two shapes, NOT measured:
- (A) `=` with a LIST argument makes the target a LIST (clears its data, takes the list, binType LIST), and printField
  walks it. Reach: the 1 `=` call in SEQ 313's tap that carries an xl1 (printFamilyNew `n4`), plus whatever a target that
  STAYS a list does on its next scalar `=` (C6 reuses qr: it would need `=` of a scalar to drop the list again).
- (B) print a data-less field that has a list as its members. Reach: every print of a structure field, which prints its
  tag today (bear-trap 26).

**R3's witnesses, on `5ed1536` (no c4), both switches.** *testListed:* switch off walks as Tony wrote it --
`field qc / regular op + / field qb / result is 7`, then -5, 18, `invokeTEST: righty = 18`, `unary op ! on target 18
result is 0`, exit 0. Switch on, exit 0, the same arithmetic (7, -5, 18) but **every `taG` in a print reads `1`**
(`field 1`, `regular op 1`, `invokeTEST: 1 = 18`), the `"result is"` string parts drop, and the unary line prints
`18 18`; one extra `REFUSED Operators -- a prefix operator with no operand after it [line 11]`. *The folded line*
`if op.datA != 0 && result.datA != 0 && target.datA != 0;`, switch on: **the trace is byte-identical to the nested
ifs** -- the condition is true exactly where the three nested ifs are. Switch off it still exits 139 (seal 99).
⚠ Tony's tester and the C1 scaffold share names after the merge (`qa`, `qb` in both TestStuff and C1Tester); testListed's
walk reads qb as 3 (7 = 4 + 3).

### ⚠⚠ c4 LANDED on `expr-accum` `aaf57cf` (SEQ 323 R0, Clod, 2026-10-08) -- UNMERGED, FOR TONY TO BUY

**Rulings carried (Tony, 2026-10-08):** print is a feature -- a field with no value prints its tag, unchanged. `=` is
to copy DATA ONLY (setData, not yet built); setContent stays where a list is part of the deal (TraiT, TraiTdata). tester
may be committed between edits.

**What landed** (built from the parked probe, one commit, on top of trunk `8d1f19c` merged in as `1c59c4e`): both
builders build xl1 in source order -- trunk's interpretXP appends with `+=` and then `listLastToFront` (a relink, no
copy); `interpretXPaccumWrap` loses its reverse loop. The seven Instruct readers, printField (`reversePrint` now walks
`prior`) and jitPrintList walk `next`. `GroupList(item)` and addGroup's binType block skip a LIST: xl1 is a value with
no first-character set. Canary 338.

**C5 respelled on the branch** to WALK the call's list (`c5L := fId(qa qb); iterate c5C on *c5L; while ++c5C; cerr
*c5C;`) and to capture the length before printing it: **`2 10`, length `2`**. The same walk reads `10 2` on trunk, so
the row discriminates the turnaround. Two spelling traps met on the way: a `" "` separator prints `quoteBody` (bear-trap
28), and with the switch on a string followed by `*` reads the `*` as BINARY -- `cerr "x" *c5C` refuses as "Operator *
cannot apply"; `cerr *c5C` and a captured length do not.

**Certificate (clone binary, bare):**
- Fleet off **1039 -> 1040**, on **784 -> 785**. The only movers, both roads: C5 (one row -> two, green) and **ST1,
  re-pinned `xl1InSet` -> `7`** -- the stale value R1(b) names: xl1 has a list and no data, and setContent keeps qs's 7.
- printPop: printFamilyNew section 6 re-pinned, `omitted-2 [ xl1InSet ]` -> `[ n4 ]` (same mechanism: n4 had no data,
  so it prints its tag). printPop PASSED.
- **H7, two readers.** opAddAttribute left on `prior`: **no fleet row moves**, though the order probe shows `+%` over
  a juxtaposed list reversed (`attr first 3 last 2`) -- **no row pins the order of `+%` over a juxtaposition; a coverage
  finding.** printField left on `prior`: **fleet off 1040 -> 610**, red by value (kindT R1 reads `[]` for `3 x2 5`,
  C5's length row empty, oneTest's baseline diffs). Both restored md5-identical and rebuilt.
- jitLadder PASSED switch off; switch on row for row with c1's run (128 FAIL each, the SEQ 311 R4 jit refusal).
  decodePop and frontier byte-identical to their captures; ddPop 5 / 1 standing; dirCheck PASSED, 52 of 56 inject, tree
  retokked byte-identical (run in the clone with clone include paths and a copy of groupDirectives, restored after).
  ⚠ **One more parked directive is dark than on trunk: `runOP starting`** -- dark since c1 (`d46aa45`) made runOP a
  one-line unpacker; the anchor wants `runOPslots` when the branch merges (Tony's file).
- **The fold rows on the branch:** with the switch on, FA2 reads 0 and foldAndT exits 0 and reaches its foot -- the
  intended values, red only against trunk's today-pins. They read that way before c4 too (the tiers, c3).

### ⚠⚠ (e) TRIAGE -- THE SWITCH-ON MOVERS, BUCKETED BY CAUSE (SEQ 326 R1-R3, Clod, 2026-10-09; READ-ONLY, nothing re-pinned)

**Population, measured:** trunk `ed1089d` (expr-h merged), installed binary, bare. `pop.sh` switch off **1052 / 51 / 1**,
switch on **791 / 314 / 1**. A row-sequence diff (heap addresses normalised) pairs **275 moved rows**. Each is mapped to the
fixture that produced it. A wrapper binary logged the fleet's 174 invocations (36 of them pop.sh's generated `.twk`
snippets, kept aside), and each was run both ways under a 90s alarm: **119 differ in output**, four in exit status (foldAndT
139 -> 0, kindJ1T and kindLiftT 0 -> killed, spacingT 0 -> 139). **No source tap:** every probe was a scratchpad copy of a
fixture plus counting lines (bear-trap 43), and one lldb batch run.

| bucket | rows | what it is |
|---|---|---|
| **(a)** generated-parse bodies | **116** | `parseRule: X has a parse method but no compiled body` / `PROBE REFUSED: X has no carrier`; the new-road column reads 0/0 while the old road holds |
| **(b)** the jit road | **44** | `the accumulator candidate is interpreted only -- under jitting it refuses (SEQ 311 R4)`; jitted columns move, interpreted ones hold. **kindJ1T and kindLiftT HANG** after the refusals of `acU`/`acA` in `kjWalk` |
| **(f)** print-list position rule | **46** | a prefix after a print item reads as binary: `Operator * -- cannot apply`, and the refusal ENDS THE ACTION, so every later row in it disappears (pointerT loses L2-F1 and all of L4-L6). Two use `~taG` (iterRefuseT, starIdiomT), not `*` |
| **(L)** the ruled direction | **28** | moves to the intended value |
| **(D)** candidate defect | **40** | four causes, below |
| **(?)** not classifiable | **1** | below |

**Seal 88's named movers:** **pointerT** -- (f), 10 rows: `print "... =" *ptNamed` refused at L2 ends the action.
**omModT** -- NOT a mover today: identical output on both switches. **hasActionT** -- (D) bare accessor, 6 rows:
`HA 1 -> 36` (the rule's tag reads `1`). **spacingT's 139** -- (D), a crash: `runOPaccum`'s `acU` fires `op.method(val)`
with `val` null, `opDeref(null)` dereferences it (lldb: opDeref <- runOPaccum <- runOPaccumOperand <- runAccAssign). Trunk
refuses that row (`* *x`) by name.

**⚠⚠ RULED (Tony, 2026-10-09, SEQ 327):**
- **R0 -- THE BARE ACCESSOR STAYS.** A bare `taG` / `noPrinT` / `isRulE` resolves through `lastREF` on BOTH roads. The
  candidate not doing so is **defect D1**, its own stroke next (SEQ 328). Cause 1 below is D1.
- **R1 -- A LONE OPERATOR IS NOT AN ExpressioN.** The (?) row is **(L)**: checked, every one of orc_old's 12 lone-operator
  inputs (`@ + * ? ! %`, as StatemenT and as ExpressioN) is refused BY NAME (`REFUSED + -- a prefix operator with no
  operand after it`), none silent. The 166 -> 155 is those 12 lost, plus one GAINED: **or067, `.5`**, which switch off
  gets F-117's by-name refusal and switch on reads `m=1 c=2` -- D4's family. Pinned: `incant/pop/loneOpT`, run by pop.sh
  WITH THE SWITCH ON -- `+` and `!` each refused by name once, no verdict read (switch off it prints two verdicts, the
  rows' negative control).

#### (f) RESPELLED ON TRUNK (SEQ 327 R2, Clod, 2026-10-09) -- fixtures only, no source change

**The house form, checked first** (a scratchpad probe, both switches): `cerr "x=" ,*h " y"` prints exactly what
`cerr "x=" *h " y"` prints switch off (`x= 7 y`), and switch on it parses where the bare form refuses; `,~taG` likewise.
**The census:** a scanner over every tracked `incant/` file's live region (above `stop();`/`bail();`), skipping strings,
flagging a `*` or `~` tight to an operand after the first print item -- validated on a probe in both directions (flags the
four bare forms, none of the comma forms). 99 raw hits, of which the comment banners and prose (`*****`, `**WRONG**`, the
`* *x` notes) are noise; the live hits are in 24 fleet fixtures, plus the attic, a probe and a fixit (not respelled, below).

**45 respells on 42 lines** (`,` inserted before the prefix, nothing else touched):

| file:line | before | after |
|---|---|---|
| `incant/pop/altShadowT:53` | `print "C guard poisoned rule carries attribute" ~taG:;` | `print "C guard poisoned rule carries attribute" ,~taG:;` |
| `incant/pop/altShadowT:59` | `print "A ok    poisoned" ~taG "with one noPrint attribute":;` | `print "A ok    poisoned" ,~taG "with one noPrint attribute":;` |
| `incant/pop/assignRoadT:24` | `print "AR-J jitted      : *arOut =" *arOut " (want ARV)":;` | `print "AR-J jitted      : *arOut =" ,*arOut " (want ARV)":;` |
| `incant/pop/assignRoadT:28` | `print "AR-I interpreted : *arOut =" *arOut " (want ARV)":;` | `print "AR-I interpreted : *arOut =" ,*arOut " (want ARV)":;` |
| `incant/pop/bisectQ:88` | `cerr "SEQ" bqSeen ~taG:;` | `cerr "SEQ" bqSeen ,~taG:;` |
| `incant/pop/compileInT:20` | `print "CI-4a currentMETHOD before compileIn -> " *currentMETHOD:;` | `print "CI-4a currentMETHOD before compileIn -> " ,*currentMETHOD:;` |
| `incant/pop/compileInT:27` | `print "CI-4b currentMETHOD after compileIn  -> " *currentMETHOD:;` | `print "CI-4b currentMETHOD after compileIn  -> " ,*currentMETHOD:;` |
| `incant/pop/ctlStampT:47` | `cerr "CT LV-1 action returned value " *ctGot:;` | `cerr "CT LV-1 action returned value " ,*ctGot:;` |
| `incant/pop/dotChainT:103` | `cerr "DC-S seed: mid=" *dcQ1 " leaf=" *dcQ2 " twig=" *dcQ3:; };` | `cerr "DC-S seed: mid=" ,*dcQ1 " leaf=" ,*dcQ2 " twig=" ,*dcQ3:; };` |
| `incant/pop/dotNameT:37` | `cerr "DN-1 member   dnBag.dnKid       taG   = " *dnRes.taG " (want dnKid)":;` | `cerr "DN-1 member   dnBag.dnKid       taG   = " ,*dnRes.taG " (want dnKid)":;` |
| `incant/pop/dotNameT:39` | `cerr "DN-2 miss     dnBag.zzNoSuchMember    = " *dnRes.taG " (want 0 -- a miss mints nothing)":;` | `cerr "DN-2 miss     dnBag.zzNoSuchMember    = " ,*dnRes.taG " (want 0 -- a miss mints nothing)":;` |
| `incant/pop/exprPinT:69` | `H2 code={ hw := qa * qb + qc; cerr "EP H2 " hw " star " *hw:; };` | `H2 code={ hw := qa * qb + qc; cerr "EP H2 " hw " star " ,*hw:; };` |
| `incant/pop/f31:68` | `cerr "INSTALL " fbCount " " ~taG:;` | `cerr "INSTALL " fbCount " " ,~taG:;` |
| `incant/pop/f31:92` | `cerr "COMPILING " ~taG:;` | `cerr "COMPILING " ,~taG:;` |
| `incant/pop/iterRefuseT:65` | `print "W member" ~taG:;` | `print "W member" ,~taG:;` |
| `incant/pop/jit/kindJ1T:30` | `cerr "J1 value " *h:;` | `cerr "J1 value " ,*h:;` |
| `incant/pop/kindT:18` | `cerr "R1 value " *kShC:;` | `cerr "R1 value " ,*kShC:;` |
| `incant/pop/memberLitT:15` | `cerr "ML-1 length = " *mlLen " (want 1)":;` | `cerr "ML-1 length = " ,*mlLen " (want 1)":;` |
| `incant/pop/memberLitT:24` | `cerr "ML-3 length AFTER the refusal = " *mlLen " (want 1 -- nothing was attached)":;` | `cerr "ML-3 length AFTER the refusal = " ,*mlLen " (want 1 -- nothing was attached)":;` |
| `incant/pop/opRoadT:15` | `cerr "ROAD-A registered +% len = " *orLenA:;` | `cerr "ROAD-A registered +% len = " ,*orLenA:;` |
| `incant/pop/pointerT:61` | `print "pointerT L2 name-then-star =" *ptNamed "  want CHANGED -- LAW 4, the lawful read":;` | `print "pointerT L2 name-then-star =" ,*ptNamed "  want CHANGED -- LAW 4, the lawful read":;` |
| `incant/pop/pointerT:63` | `print "pointerT L3 assign-then-star =" *ptAssigned "  want CHANGED -- = with a holder on the right carries its group across":;` | `print "pointerT L3 assign-then-star =" ,*ptAssigned "  want CHANGED -- = with a holder on the right carries its group across":;` |
| `incant/pop/pointerT:104` | `print "pointerT X  star binds tightest =" *ptBagP["ptSrc"] "  want 0 -- LAW 3, the star took ptBagP":;` | `print "pointerT X  star binds tightest =" ,*ptBagP["ptSrc"] "  want 0 -- LAW 3, the star took ptBagP":;` |
| `incant/pop/propGetT:12` | `cerr "PG-1 property via subscript = " *pgA.taG:;` | `cerr "PG-1 property via subscript = " ,*pgA.taG:;` |
| `incant/pop/propGetT:14` | `cerr "PG-3 term via subscript = " *pgT.taG:;` | `cerr "PG-3 term via subscript = " ,*pgT.taG:;` |
| `incant/pop/propOpT:18` | `cerr "PO-1 =< reads the filed property = " *poP:;` | `cerr "PO-1 =< reads the filed property = " ,*poP:;` |
| `incant/pop/propOpT:20` | `cerr "PO-3 =% the same name = " *poA.taG:;` | `cerr "PO-3 =% the same name = " ,*poA.taG:;` |
| `incant/pop/propOpT:39` | `cerr "PO-5 host[BlocK] = " *poSub:;` | `cerr "PO-5 host[BlocK] = " ,*poSub:;` |
| `incant/pop/propOpT:40` | `cerr "PO-6 host =< BlocK = " *poGet:;` | `cerr "PO-6 host =< BlocK = " ,*poGet:;` |
| `incant/pop/propOpT:47` | `cerr "PO-7 StatemenT[BlocK] = " *poSt.taG:;` | `cerr "PO-7 StatemenT[BlocK] = " ,*poSt.taG:;` |
| `incant/pop/propOpT:49` | `cerr "PO-9 StatemenT =< builtinActoR = " *poSa.taG:;` | `cerr "PO-9 StatemenT =< builtinActoR = " ,*poSa.taG:;` |
| `incant/pop/ruleCount:37` | `if isRulE;  print "  rule    " ~taG:;` | `if isRulE;  print "  rule    " ,~taG:;` |
| `incant/pop/ruleCount:38` | `else        print "  NOTRULE " ~taG:;` | `else        print "  NOTRULE " ,~taG:;` |
| `incant/pop/ruleCount:48` | `if isRulE;  print "  attrRule " ~taG:;` | `if isRulE;  print "  attrRule " ,~taG:;` |
| `incant/pop/ruleCount:49` | `else        print "  attrNOT  " ~taG:;` | `else        print "  attrNOT  " ,~taG:;` |
| `incant/pop/shadowCensus:74` | `print " " ~scTag:;` | `print " " ,~scTag:;` |
| `incant/pop/shadowCensus:96` | `print " " ~scTag:;` | `print " " ,~scTag:;` |
| `incant/pop/shapeBodyT:14` | `if rp == 1;     cerr "LABEL " argument " text=[" *lt "]":;` | `if rp == 1;     cerr "LABEL " argument " text=[" ,*lt "]":;` |
| `incant/pop/starDotNullT:13` | `print "SD-1 the temporary spelling reads through -> " *blk:;` | `print "SD-1 the temporary spelling reads through -> " ,*blk:;` |
| `incant/pop/starIdiomT:45` | `cerr "ROW1 member" ~taG:;` | `cerr "ROW1 member" ,~taG:;` |
| `incant/pop/testPrecedence:40` | `cerr "ROW" *tpName "WANT" argument "GOT " *tpRead:;` | `cerr "ROW" ,*tpName "WANT" argument "GOT " ,*tpRead:;` |
| `incant/pop/unaryClassT:30` | `cerr "UC-1 access   *ucH.listLengtH         = " *ucH.listLengtH " (want 3 -- deref bound to the PRIMARY)":;` | `cerr "UC-1 access   *ucH.listLengtH         = " ,*ucH.listLengtH " (want 3 -- deref bound to the PRIMARY)":;` |

**NOT respelled, and why:**
- `incant/pop/spacingT:64`, `print "spacingT E value    =" * *spWrap:;` -- the SPACED star is spacingT's subject (the
  spelling law: spaced is binary). Respelling it deletes the row's question.
- **Three respells REVERTED because they moved a switch-off value** (the ruling: such a respell is a mistake, not a
  mover): `propGetT:13` `*pgZ.taG`, `propOpT:19` `*poM.taG`, `propOpT:48` `*poSp.taG`. Each is a MISS that yields null:
  the bare form prints `0` on trunk, the comma form prints nothing, so PG-2 / PO-2 / PO-8 read `=` instead of `0`. They stay
  bare and stay (f) -- and they take PG-3, PO-3, PO-9 with them switch on (the refusal ends the action). **A spelling that
  keeps the `0` is owed a ruling.**
- Off the fleet, reported only: `incant/attic/derefAllT:15,17,18`, `attic/membersFlagCapture:11`,
  `attic/traitDataCapture:11` (x2), `incant/probes/unrunIf:40,42`, and Clod's fixit `incant/fixits/defineCapture:22`
  (x2), `:38`.
- **Tony's incantations, reported only:** `IncantForms/WorkingOn/tester:37` `print \`"unary op" taG "on target" *target;`,
  `:40` `... "on result" *result;`, `:43` `print " result is" *result:;`, `:48` `if *grup.isLiteraL == 1;    print \`"number"
  *grup:;`, `:60` `print "result is" *target:;`. Nothing else under `IncantForms/` (the other hits are banners and prose).

**Certificate.** Switch off **row for row** with the pre-respell run (1057 / 51 / 1). Switch on 796 -> **835** green.
**38 of the 46 (f) rows** now read their switch-off values; the other 8: `,~taG` reads `1` in iterRefuseT and starIdiomT
(**D1** -- the comma form goes through the bare accessor), and the three reverted rows plus their three collaterals.
**Re-diff of the two switches: 236 rows move, NO NEW MOVER** -- a row a refused print hid was already counted as moved,
so revealing it either cured it or left it moved under the same switch-off text. One correction to the triage: row 162,
shapeBodyT's OLD-road label (`aaac`), was bucketed (a) and is cured by the respell at `shapeBodyT:14` -- it was (f).

| bucket | before R2 | after R2 |
|---|---|---|
| (a) | 116 | 115 |
| (b) | 44 | 44 |
| (f) | 46 | 6 |
| (L) | 28 | 29 (orc_old's row, R1) |
| (D) | 40 | 42 (D1 24 -> 26) |
| (?) | 1 | 0 |
| **moved** | **275** | **236** |

**The four (D) causes:**
1. **Bare accessor -- 24 rows.** Inside a walk, `taG`, `noPrinT`, `isRulE`, `hasAttributeS` read their own GroupFields
   value (`taG=1`, `isRulE=23`, `noPrinT=29`): the candidate never takes the accessor road through `lastREF` that
   aCTionTokenXP's `dot-LEADING` arm gives trunk. Measured on parseClass's own walk: switch off 11 members seen and 11 pass,
   switch on 65 seen and **0 pass** `if noPrinT; continue;`. Switch-on reads: traitFlagsT 87 / 87 / 87 / 0, walkRefT `1`,
   cursorReadT A `bare= 1`, B `bare= ENCLOSING`, artifactSkipT `1 isRulE 23 noPrinT 29`, actorOrderT 1, parserCoverage
   `0 rules`, shadowCensus nothing, propOpT PO-4 `1`, propGetT PG-4 `1 1`, iterT1/iterT1m `at 1 trunk`. ⚠ Stroke 6b's ruling
   retires the bare accessor in favour of the explicit `cur.taG`, which today reads the CURSOR (cursorReadT); whether these
   rows are a candidate defect or a respell owed is Tony's.
2. **`a.*b` refused at BUILD -- 11 rows** (abandonT 5, stopPreT 3, truncT 1, dotChainT DC-9 2). The candidate's
   `REFUSED * -- an operator on the right of a dot` fails the statement's parse, so the run abandons the file
   (`ABANDONED ... the parse STOPPED with input left over`) or the action (`processCode: dcR9 parse failed`). Trunk refuses at
   RUN time and carries on -- the refusal is scoped to its statement, which is what these fixtures pin.
3. **The prefix on a null -- 2 rows** (spacingT runs, sentinel): the 139 above.
4. **`.5` by name -- 1 row** (dotNumT): F-117's by-name refusal lives in aCTionTokenXP, which the candidate bypasses;
   `opDot` refuses with "the left of this dot holds nothing" instead. (The `un*`/`sr*` `.5` rows are (a): their new road
   refuses first.)

**(?) -- 1 row:** oldRoad anti-vacuity, 166 -> 155 inputs read a verdict. orc_old drives lone operators (`+ ! ? @ * %`) as
an ExpressioN; the candidate refuses each as `a prefix operator with no operand after it`. Still green either way. **What
would classify it:** whether a lone operator is an ExpressioN (then (D)) or not (then (L)).

**The (L) rows**, each moving to the intended value: exprPinT A2 23, A5 3.2, A6 17, A7 54, U70/U72/U75 0, B2/B3 0, U302a 1,
S1 1, C3 36, FA2 0, O1 pz 7 / r3 7, O3 3 lines, E2 (refused by its new name -- the row counts the old message); foldAndT
exit 0, after 1, sentinel 1; blockCallT BC2 and BC4 (pz 7, rc 7); testPrecedence 8 -> 5 rows not yet true; starT S3a `stD`;
setFlagTopT SFT-1 1 and the noPrint dump (top-level `:.` keeps its operand). exprPinT H2 is (f) (`" star " *hw`).

**Per-row detail** (generated; numbers are the row's position in the paired diff):

*** *x: runOPaccum acU hands null to opDeref -- crash 139** (2 rows)

| # | fixture | switch off | switch on | intended |
|---|---|---|---|---|
| 23 | spacingT | spacingT runs | spacingT runs (exit 139) | exit 0, row C refuses by name |
| 24 | spacingT | spacingT sentinel (no truncation) | spacingT sentinel MISSING -- F-36 regressed to a crash | exit 0, row C refuses by name |

**bare accessor reads its GroupFields value (taG 1, isRulE 23, noPrinT 29)** (24 rows)

| # | fixture | switch off | switch on | intended |
|---|---|---|---|---|
| 36 | parseClass | anti-vacuity: parseRule carries 11 parked actions (must be > 0) | anti-vacuity: parseRule carries NO parked actions -- the extractor | 11 parked actions |
| 37 | traitFlagsT | traitFlagsT TF-2 carrying hasAttributeS       =  49 -- PINNED BY VALUE | traitFlagsT TF-2 carrying hasAttributeS       =  49 -- MOVED. TF-5 is the TraiT packet | 49 / 49 / 49 / 38 |
| 38 | traitFlagsT | traitFlagsT TF-3 carrying hasTraitS           =  49 -- PINNED BY VALUE | traitFlagsT TF-3 carrying hasTraitS           =  49 -- MOVED. TF-5 is the TraiT packet | 49 / 49 / 49 / 38 |
| 39 | traitFlagsT | traitFlagsT TF-4 carrying BOTH                =  49 -- PINNED BY VALUE | traitFlagsT TF-4 carrying BOTH                =  49 -- MOVED. TF-5 is the TraiT packet | 49 / 49 / 49 / 38 |
| 40 | traitFlagsT | traitFlagsT TF-6 no attributes                =  38 -- PINNED BY VALUE | traitFlagsT TF-6 no attributes                =  38 -- MOVED. TF-5 is the TraiT packet | 49 / 49 / 49 / 38 |
| 46 | iterT1 | iterT1 (per-frame locals, deep) | iterT1 (per-frame locals, deep) | trunk walk |
| 47 | iterT1m | iterT1m (mutual recursion, each node once) | iterT1m (mutual recursion, each node once) | trunk walk |
| 147 | artifactSkipT | artifactSkip term numberSet    is a rule -- PINNED BY VALUE | artifactSkip term numberSet    is a rule -- MOVED. The 1 1 0 0 census is the | 1 1 0 0 |
| 148 | artifactSkipT | artifactSkip term FloaT        is a rule -- PINNED BY VALUE | artifactSkip term FloaT        is a rule -- MOVED. The 1 1 0 0 census is the | 1 1 0 0 |
| 149 | artifactSkipT | artifactSkip artifact builtinActoR is NOT -- PINNED BY VALUE | artifactSkip artifact builtinActoR is NOT -- MOVED. The 1 1 0 0 census is the | 1 1 0 0 |
| 152 | cursorReadT/Tb | cursorRead A: bare reads the MEMBER, explicit reads the CURSOR -- PINNED BY VALUE | cursorRead A moved -- the two spellings no longer read what they read on 2026-09-10: | trunk value (the member / the shadow) |
| 153 | cursorReadT/Tb | cursorRead B: a declared same-named field SHADOWS both spellings -- PINNED BY VALUE | cursorRead B moved -- the shadowing changed: | trunk value (the member / the shadow) |
| 155 | shadowCensus | shadowCensus walked 87 rules, 14 members-shaped, 19 data-shaped (non-vacuous) | shadowCensus walked nothing, or a COLUMN went inert | 87 rules walked |
| 175 | parserCoverage.sh | parserCoverage.target (parser() over the whole grammar: 47 compile of 63) | parserCoverage.target (parser() over the whole grammar: 47 compile of 63) | 47 compile of 63 |
| 176 | walkRefT | W bare taG = aa -- PINNED BY VALUE (invariant, both arms) | W bare taG = aa -- moved | the member tag (aa, bb, wrHeld) |
| 177 | walkRefT | W bare taG = bb -- PINNED BY VALUE (invariant, both arms) | W bare taG = bb -- moved | the member tag (aa, bb, wrHeld) |
| 178 | walkRefT | walkRefT row 3 = wrHeld -- THE FLIP HAS LANDED, or the binary is | walkRefT row 3 is neither wrTarget nor wrHeld -- a third answer | the member tag (aa, bb, wrHeld) |
| 234 | actorOrderT | actorOrderT AO-1 rules whose builtinActoR is found by lookup (non-zero sibling) = [33] | actorOrderT AO-1 rules whose builtinActoR is found by lookup (non-zero sibling) -- got [1] want [33] | 33 |
| 245 | hasActionT | hasActionT HA IF has an action, at rest = [1] | hasActionT HA IF has an action, at rest -- got [] want [1] | 1 / 0 per rule |
| 246 | hasActionT | hasActionT HA DO has an action, at rest = [1] | hasActionT HA DO has an action, at rest -- got [] want [1] | 1 / 0 per rule |
| 247 | hasActionT | hasActionT HA FOR has an action, at rest = [1] | hasActionT HA FOR has an action, at rest -- got [] want [1] | 1 / 0 per rule |
| 248 | hasActionT | hasActionT HA ExpressioN has an action, at rest = [1] | hasActionT HA ExpressioN has an action, at rest -- got [] want [1] | 1 / 0 per rule |
| 249 | hasActionT | hasActionT HA NamE has an action, at rest = [1] | hasActionT HA NamE has an action, at rest -- got [] want [1] | 1 / 0 per rule |
| 250 | hasActionT | hasActionT HA SemI control: no actor, no action = [0] | hasActionT HA SemI control: no actor, no action -- got [] want [0] | 1 / 0 per rule |

**a.*b refused at BUILD: dcR9 parse failed** (2 rows)

| # | fixture | switch off | switch on | intended |
|---|---|---|---|---|
| 56 | dotChainT | dotChain DC-9 a.*b is REFUSED, by message not by absence | dotChain DC-9 a.*b -- NO REFUSAL. Actual: | refused once, by message |
| 57 | dotChainT | dotChain DC-9 refuses EXACTLY ONCE (seat is inside the target guard) | dotChain DC-9 refused 0 times, want exactly 1 -- a count of 2 means | refused once, by message |

**.5 by-name refusal lost (lives in aCTionTokenXP); opDot refuses instead** (1 rows)

| # | fixture | switch off | switch on | intended |
|---|---|---|---|---|
| 62 | dotNumT | dotNumT old road refuses .5 by name | dotNumT old road did not refuse .5 by name | .5 refused by name (F-117) |

**lone operator driven as ExpressioN refused by the candidate -- is a lone operator an ExpressioN?** (1 rows)

| # | fixture | switch off | switch on | intended |
|---|---|---|---|---|
| 115 | orc_* | oldRoad column anti-vacuity: the old road reads a verdict on 166 inputs | oldRoad column anti-vacuity: the old road reads a verdict on 155 inputs | ? |

**a.*b refused at BUILD: the statement fails to parse, the file is abandoned** (9 rows)

| # | fixture | switch off | switch on | intended |
|---|---|---|---|---|
| 138 | truncT | truncT TR-4 the resume point quotes the first UNPARSED statement | truncT TR-4 no resume text -- the report names no place | trunk: resume text |
| 139 | abandonT | abandonT AB-1 ran TWICE -- the refusal is scoped to its statement | abandonT AB-1 ran 1 times, want exactly 2 -- a 1 means the refusal | trunk: scoped refusal, run continues |
| 140 | abandonT | abandonT AB-2 a plain statement after the refusal RAN | abandonT AB-2 did not run -- execution did not survive the refusal | trunk: scoped refusal, run continues |
| 141 | abandonT | abandonT AB-3 the refusal fired -- without it AB-1 and AB-2 are vacuous | abandonT AB-3 NO REFUSAL -- every row above passes trivially now | trunk: scoped refusal, run continues |
| 142 | abandonT | abandonT AB-4 the run ended properly -- stop() fired with a refusal behind it | abandonT AB-4 stop() did not fire | trunk: scoped refusal, run continues |
| 143 | abandonT | abandonT AB-5 not abandoned (0) -- read WITH AB-4, never alone | abandonT AB-5 ABANDONED 1 times -- a refusal reached end of file | trunk: scoped refusal, run continues |
| 144 | stopPreT | stopPreT SP-1 execution is NOT halted by a refusal | stopPreT SP-1 did not run -- the refusal halted execution | trunk: scoped refusal |
| 145 | stopPreT | stopPreT SP-3 stop() FIRED -- the positive that makes SP-2 readable | stopPreT SP-3 stop() never fired, so SP-2's zero means nothing | trunk: scoped refusal |
| 146 | stopPreT | stopPreT SP-4 the refusal was standing -- without it the fixture is vacuous | stopPreT SP-4 NO REFUSAL -- nothing here is being tested | trunk: scoped refusal |

**bare taG in the walk reads 1** (2 rows)

| # | fixture | switch off | switch on | intended |
|---|---|---|---|---|
| 224 | propGetT | propGetT PG-4 QuotE's terms, walked = [QuotE1 QuotE2 ] | propGetT PG-4 QuotE's terms, walked -- got [1 1 ] want [QuotE1 QuotE2 ] | QuotE1 QuotE2 |
| 228 | propOpT | propOpT PO-4 host's terms are the +% child only -- +< is not on groupList = [poTerm] | propOpT PO-4 host's terms are the +% child only -- +< is not on groupList -- got [1] want [poTerm] | poTerm |

**(L) rows**

| # | row (switch off pin) | switch on |
|---|---|---|
| 19 | setFlagTopT -- wanted: SFT-1 top-level :. read-back  ->  1 | setFlagTopT SFT-1 top-level :. read-back  ->  1 -- PINNED BY VALUE |
| 20 | setFlagTopT -- dumpContents shows sfTop WITHOUT noPrint | setFlagTopT dumpContents shows sfTop noPrint |
| 25 | starT S3a **x  ONE-deep   = stD -- moved | starT S3a **x  ONE-deep   = stD -- PINNED BY VALUE |
| 51 | testPrecedence 8 of 35 rows not yet true (ratchet: 8) | testPrecedence 5 of 35 rows not yet true (ratchet: 8) |
| 251 | exprPinT A2 2 * 10 + 3 (KANT-43 split) = [26] | exprPinT A2 2 * 10 + 3 (KANT-43 split) -- got [23] want [26] |
| 252 | exprPinT A5 qa / qb + qc = [0.153846] | exprPinT A5 qa / qb + qc -- got [3.2] want [0.153846] |
| 253 | exprPinT A6 bgSpec * 3 + 2 (jitAttrPop:69) = [25] | exprPinT A6 bgSpec * 3 + 2 (jitAttrPop:69) -- got [17] want [25] |
| 254 | exprPinT A7 lt + bk * sc, 1 17 3 (jitAttrPop:70) = [52] | exprPinT A7 lt + bk * sc, 1 17 3 (jitAttrPop:70) -- got [54] want [52] |
| 255 | exprPinT U70 xw > px && xw < pxw, xw 20 = [1] | exprPinT U70 xw > px && xw < pxw, xw 20 -- got [0] want [1] |
| 256 | exprPinT U72 y > py && y < pyh, y 20 = [1] | exprPinT U72 y > py && y < pyh, y 20 -- got [0] want [1] |
| 257 | exprPinT U75 yh > py && yh < pyh, yh 20 = [1] | exprPinT U75 yh > py && yh < pyh, yh 20 -- got [0] want [1] |
| 258 | exprPinT B2 utilities:67, x 0 = [goodToGo] | exprPinT B2 utilities:67, x 0 -- got [0] want [goodToGo] |
| 259 | exprPinT B3 utilities:67, x 20 = [1] | exprPinT B3 utilities:67, x 20 -- got [0] want [1] |
| 260 | exprPinT U302a across > 0 // down > 0, 0 5 = [0] | exprPinT U302a across > 0 // down > 0, 0 5 -- got [1] want [0] |
| 261 | exprPinT S1 a && b // c, 0 1 1 = [0] | exprPinT S1 a && b // c, 0 1 1 -- got [1] want [0] |
| 262 | exprPinT O1 *block(src) -- pz = [0] | exprPinT O1 *block(src) -- pz -- got [7] want [0] |
| 263 | exprPinT O1 *block(src) -- r3 = [r3] | exprPinT O1 *block(src) -- r3 -- got [7] want [r3] |
| 264 | exprPinT O3 the called action runs, lines = [1] | exprPinT O3 the called action runs, lines -- got [3] want [1] |
| 266 | exprPinT E2 qa < qb < qc refused, lines = [1] | exprPinT E2 qa < qb < qc refused, lines -- got [0] want [1] |
| 267 | exprPinT C3 fId(qa + qb * qc) = [32] | exprPinT C3 fId(qa + qb * qc) -- got [36] want [32] |
| 268 | exprPinT FA2 folded &&, the middle one 0 = [1] | exprPinT FA2 folded &&, the middle one 0 -- got [0] want [1] |
| 269 | foldAndT folded && with an empty clause, exit = [139] | foldAndT folded && with an empty clause, exit -- got [0] want [139] |
| 270 | foldAndT reached the line after the if, lines = [0] | foldAndT reached the line after the if, lines -- got [1] want [0] |
| 271 | foldAndT sentinel, lines = [0] | foldAndT sentinel, lines -- got [1] want [0] |
| 272 | blockCallT BC2 rc = *block(holder) -- pz = [0] | blockCallT BC2 rc = *block(holder) -- pz -- got [7] want [0] |
| 273 | blockCallT BC2 rc = *block(holder) -- rc = [rc] | blockCallT BC2 rc = *block(holder) -- rc -- got [7] want [rc] |
| 274 | blockCallT BC4 rc = *block(pSrc), no holder -- pz = [0] | blockCallT BC4 rc = *block(pSrc), no holder -- pz -- got [7] want [0] |
| 275 | blockCallT BC4 rc = *block(pSrc), no holder -- rc = [rc] | blockCallT BC4 rc = *block(pSrc), no holder -- rc -- got [7] want [rc] |

**(a)**: probeDoorT 15, tokJitT 10, f122NatT 7, opLenT 7, df* 6, modSeamT 6, leafClassT 6, shapeBodyT 5, searchNewParseT 4, un* 4, site1RoadsT 4, orc_* 4, qn* 3, sweepT 3, doWhileNameT 3, zeroWidthT 3, ownerT 3, driveCompileT 3, termCountT 3, failPointT 3, adoptT 2, treeRowT 2, definerT 2, baselineTestsNew 1, leafLabelT 1, chainTruthT 1, df*/nn*/un*/qn* 1, nn*/un*/qn* 1, sr* 1, carrierT 1, driveDoorT 1

**(b)**: kindLiftT 14, kindJ1T 8, kindSRT 4, jitDotAssignT 3, kindJitT 3, kindHolderJitT 3, kindJ2T 3, argJitT 2, assignRoadT 2, argRoundJ 2

**(f)**: pointerT 10, propOpT 8, compileInT 6, ctlStampT 4, opRoadT 3, propGetT 3, starDotNullT 2, memberLitT 2, assignRoadT 1, starIdiomT 1, dotChainT 1, dotNameT 1, unaryClassT 1, iterRefuseT 1, kindT 1, exprPinT 1


### ⚠⚠ (h) BUILT on `expr-h` `fabb4a2` (SEQ 325 R2/R3, Clod, 2026-10-09) -- UNMERGED, FOR TONY TO BUY

**Ruled (Tony, 2026-10-09): both roads, in driveStep.** driveStep's unwrapTheHolder moves to ENTRY, before anything
reads the field -- still the single dereference; `intoField` reads the already-unwrapped field. Generated diff: exactly
the moved lines, nothing re-aimed (bear-trap 42); canary 338. Groups only -- support untouched.

**Certificate (clone binary, bare; baseline = the trunk-source binary):**
- Fleet switch off 1052 -> 1052 with the re-pins: movers **BC1 pz/rc and BC3 pz, 0/rc -> 7** (re-pinned to their
  intended 7). Switch on 795 -> 791 (the four: BC2 x2 and O1 x2 now read their intended 7, red only against the switch-off pins): movers BC1, BC3, **BC2 and exprPinT O1 -> 7** -- the acceptance line
  `result = *block(code);` works switch on. Nothing else moves on either road.
- Switch off, BC2 and O1 stay 0 / tag: their call never happens (the star-call defect, BC4) -- not (h).
- **H7, the entry unwrap removed:** off 1052 -> 1049, BC1 x2 and BC3 red by value (`0`, `rc`); on, BC1 and BC3 red and
  BC2 and O1 back to 0 / tag. Restored md5-identical, rebuilt.
- jitLadder PASSED switch off, switch on row for row with c4 (128 FAIL each); printPop PASSED; ddPop 5 / 1 standing;
  decodePop binary echo only; frontier identical; dirCheck identical to trunk's capture (52 of 56, run in the clone with
  clone include paths and a copy of groupDirectives, removed after), and its bare retok of every `.twk` left the tree
  byte-identical.

### (h) RECON -- A RULE CALLED WITH A HOLDER (SEQ 325 R0/R1, Clod, 2026-10-09; READ-ONLY, nothing built)

**R0, pinned on trunk `3888016`: `incant/pop/blockCallT`.** pSrc holds `{ pz = 7; }`, so `pz` reads 7 only if the
SOURCE TEXT was driven; `rc` is what came back (its tag = nothing). Switch off today, intended, [switch on today]:

| row | spelling | pz | rc |
|---|---|---|---|
| BC0 control | `rc = BlocK(pSrc)` | 7 -> 7 [7] | 7 -> 7 [7] |
| BC1 | `src := pSrc; rc = BlocK(src)` | 0 -> 7 [0] | rc -> 7 [rc] |
| BC2 (O1's shape) | `block := Grokking["BlocK"]; rc = *block(src)` | 0 -> 7 [0] | rc -> 7 [rc] |
| BC3 | `BlocK(src);` as a statement | 0 -> 7 [0] | -- |
| BC4 | `rc = *block(pSrc)`, no holder | 0 -> 7 [**7**] | rc -> 7 [**7**] |

**BC4 separates BC2's two defects.** Switch off the star-call is lost before any drive (step 1 section 3: the call
node never gets a method); switch on, `(*block)(pSrc)` calls. So BC2 is (h) AND the star-call switch off, and (h)
alone switch on. Fleet 1041 -> 1052 / 51 / 1; switch on, BC4's two rows read 7, nothing else differs.

**R1 -- THE DOORS. There is ONE.** Every road a kant rule call takes reaches `driveStep` through `opCall`'s rule case
(`GroupActions.rtn:1077-1081`, `callIsRule` -> `runRule(arg,target)` -> `driveStep(arg,rule,null,null)`):

| road | how it gets to opCall |
|---|---|
| trunk (switch off) | `runOPslots` -> `runOPdirect` -> `isCallable` -> `opCall` |
| candidate (switch on) | `runOPaccum`'s `acC` (the call, target finished first) -> `isCallable` -> `opCall` |
| jit | `runOPslots` under jitting emits `jitTermCallRT`, which at run time replays `runOPslots` on the raw slots -> the trunk row |

**What driveStep reads off the argument** (`GroupActions.rtn:221`): `field.data` as the gate -- a holder passes, its
data is the isGROUP kind; `pushInput(field)`, i.e. **`field.getText()`, which for a holder is the HELD field's NAME**
(`driven=[pSrc]`, not the holder's own tag `src`, and not pSrc's text); `measureMarkArm(field)`; and only after the
push, `intoField = field.gGroup` (unwrapTheHolder) -- read solely by the old-road `noDataMeansLabel` arm. So the held
field's TEXT is never read.

**Other drive doors, for the record -- none is a kant rule call:** RunRulE's action (`ruleActions.rtn:800`) already
unwraps ONE level before `runRule`; `compileIn` (`:745-746`) unwraps every level (`while ... isGROUP`); `compile`
(`:702`) drives the action's CodE property; `aCTionTell` builds a fresh message node from `message.getText()` (a
holder message would hand it the held name the same way -- not a call, not in (h)); `treeOf` (`genParse.rtn:137`)
drives its argument unwrapped (a command, not a call).

**Census (temporary tap in driveStep, clone, every drive handed a holder, reverted md5-identical).** Population: every
file in `incant/pop`, `incant/pop/jit`, `incant/jit*`, the top-level corpus files and `walkRefT` -- 204 files, both
switches, 408 runs. A holder drive anywhere in the fleet would have been seen, because every fleet fixture is in it.

| switch | holder drives | where | outcome |
|---|---|---|---|
| off | 2 | blockCallT BC1, BC3 | result 0 |
| on | 4 | blockCallT BC1, BC2, BC3; exprPinT O1 | result 0 |

All six are `BlocK` holding `pSrc`, and **every one fails -- no caller relies on the name text being driven** (R1's
STOP not met). Switch on, 19 jit fixtures crash (14 x 139, 5 x 142) identically on the untapped binary: standing
switch-on behaviour (the SEQ 311 R4 jit refusal family), not the tap.

**What it means for R2's open question.** Because the door is shared, the one-line unwrap -- in `opCall`'s rule case
before `runRule`, or `driveStep`'s unwrapTheHolder moved above the push -- fixes BOTH roads (and the jit replay) at
once; a candidate-only fix would need a switch test added at the door. BC1 and BC3 turn green on both switches; BC2 turns
green switch on only, because switch off its call never happens (the star-call defect, BC4).

### ⚠⚠ c4 BOUGHT AND MERGED (SEQ 324, Clod, 2026-10-09) -- the switch stays OFF by default

**R1 first -- the +% order row, which seal 101's H7 showed nothing pinned.** exprPinT **PA1**: `holdB +% qa qb qc;`
then holdB's length and its entries 1, 2, 3, captured with `=` and printed one per line: **`3: 2 10 3`**, intended the
same (source order). The first spelling read through `:=` holders and printed `cerr "x" *p`: on expr-accum with the
switch on that star reads as BINARY and refuses the rest of the action (the trap c4 met), so the row printed nothing;
`cerr *p1 *p2 *p3` in one line exits 139 on trunk (context, not chased). Last action in exprPinT, so a crash there
can take only the sentinel.

**Certificate:**
- trunk (installed binary): fleet 1039 -> **1040** / 51 / 1, PA1 green (`9099b08`, respelled `2d90c05`).
- expr-accum (clone binary, trunk merged in as `d25a3e8`, rebuilt from the committed `.mm`): switch off 1040 -> **1041**,
  on 785 -> **786**; PA1 the ONLY mover against c4's runs on both roads.
- **H7, opAddAttribute left on `prior`** (`Instruct.rtn:61`, built into a second DerivedData): off 1041 -> 1040, on
  786 -> 785, **PA1 red by value, `3: 3 10 2`**, and nothing else moves. Restored md5-identical (Instruct.rtn,
  GroupRules.mm, GroupRules.h).

**R2 -- merged.** Groups: trunk `d0c0d7b` merges expr-accum `d25a3e8` (tree identical to the branch). Support: main
`4394d53` merges expr-accum `2acfa25` (groups.ext +7, globals +1). Branch deleted local and remote in both repos. Full
bare tokall on trunk byte-identical, canary **338**. Trunk fleet **1041 / 51 / 1** -- row for row with the clone's
switch-off run but for two counts the live tree owns (fixture names 222, the clone lacks untracked fixtures; groups.ext
arity 258 -> 265, the merged mirror lines), and against this morning's trunk the only movers are c4's own (C5 one row
-> two, `2 10` and `2`; ST1 `xl1InSet` -> `7`). dirCheck 52 of 56: **`runOP starting` dark** (parked; R3, no worry).
Context: one dirCheck run printed `Bus error: 10` from a tok in its bare retok loop and still came out byte-identical;
three further bare passes and a re-run were clean.

### The fold and the stale value, pinned on trunk (SEQ 323 R1, Clod, 2026-10-08; kant, trunk binary)

**(a) folded `&&` in an if.** exprPinT FA1 (`fpA fpD fpC` all set) reads 1, intended 1; **FA2 (the middle one 0)
reads 1, intended 0** -- with no tiers, right to left, the line reads `a != (0 && ...)`, i.e. `a != 0`. A plain folded
line does NOT crash; Tony's 139 is the BODY running on an empty field after that misfire. `incant/pop/foldAndT`
reproduces it in his shape (`kop=1`, `kres` empty, `ktgt=5`, body `testOP([kop, kres, ktgt])`): **exit 139, `FC before`
1, body 0, `FC after` 0, sentinel 0**; intended exit 0 and `FC after` 1. The nested-if spelling of the same fields
exits 0 with the body not run. Its own fixture because a crash would void every exprPinT row after it (H5).
**(b) the stale value.** exprPinT ST1, `qs = 7; qs = fId(qa qb);` reads **`xl1InSet`** on trunk, intended `qs` (its
tag: `=` copies data only, and a list has none). On expr-accum since c4 it reads **`7`**.
**H7:** FA1, FA2, ST1, and foldAndT's exit and FC-after pins mutated -> five reds by value; restored md5-identical.
Trunk fleet 1031 -> 1039 / 51 / 1.

### setData RECON -- every `=` whose source carries a list (SEQ 323 R3, Clod, 2026-10-08; READ-ONLY, nothing built)

**The tap:** SEQ 313's, re-run on trunk `8d1f19c` in the clone -- both `=` roads (opAssign and jitAssignNodeRT) print
every call, and every call whose source has a non-empty `groupList`, with its data kind and binType; reverted
md5-identical. **Population:** every file in `incant/pop`, `incant/pop/jit`, `incant/jit*`, the top-level `designDocs
grammar directives utilities frontier decoder lookup`, and every fixture a checklist script names through `ip()` (the
one not already in, `incant/walkRefT`, was run too) -- 203 runs, all exit 0 but foldAndT's pinned 139. A list-carrying
`=` in any fleet fixture would have been seen, because every fleet fixture is in it. **No per-statement line exists at
run time** (`GroupActions.rtn:765`), so each hit is mapped to its line by its target and source tags in the run's own
source and includes.

| | calls | source carries a list |
|---|---|---|
| interpreted `=` | 9,376 | **51**, in 12 fixtures |
| jitted `=` | 5 | 0 |

**LIST ONLY (source has no data) -- 38:**

| file:line | statement | n | does a name or comment say a list is the deal? |
|---|---|---|---|
| `incant/utilities:106` (JSONfield) | `*jfOut = *JSONvalue;` | 14 (jsonTest: keys `a` 5, `files` 3, `variants` 3, `subsets` 2, `items` 1) | nothing says; JSONvalue's alternatives are JSONblock / JSONarray, so a structure is what arrives |
| `incant/pop/jsonTest:24` | `field = JSONblock(argument);` | 13 | nothing says; the next lines read `field.listLengtH` and iterate `field` |
| `incant/decoder:346` | `hit = decodeCorpus[argument.taG];` | 3 (decode) | nothing says; the next line reads `hit.definition`, an attribute |
| `incant/pop/decodeT:66, 67, 68` | `h4 = / h7 = / br = decodeCorpus[...]` | 3 | nothing says; the print reads `.definition` ("three spot values") |
| `incant/pop/decodeT:139, 140` | `pk = / bi = decodeCorpus[...]` | 2 | nothing says; reads `.definition` |
| `incant/lookup:58` | `luD = decodeCorpus[argument.taG];` | 1 | nothing says; reads `luD.definition` |
| `incant/lookup:62` | `luP = ProblemRecords[argument.taG];` | 1 | nothing says; `luFull(luP)` walks it |
| `incant/pop/exprPinT:61` (O1) | `r3 = *block(src);` | 1 (a BlocK) | its row says intended "the BlocK's result" -- not a list |

**LIST AND DATA -- 13:**

| file:line | statement | data | n | does a name or comment say a list is the deal? |
|---|---|---|---|---|
| `incant/pop/printFamily:105, 107, 109, 125` | `vDef = #"..." 1 2 3;` and three `$`/`_` strings | string | 1-5 (StringXP parts) | no -- "a string expression"; the parts build the string |
| `incant/pop/printFamilyNew:204, 206` | `n1 = #"PN-O-one";`, `n2 = #"PN-O" "two";` | string | 1 | no -- spelled strings |
| `incant/unitTests:244` (baselineTests, baselineTestsNew) | `whatsIt = #"is what" 'I am talking about';` | string | 1 | no -- a string |
| `incant/pop/printFamilyNew:210` | `n4 = "PN-O" "two";` | SET (xl1) | 2 | no -- its comment says it MUST BECOME `n4 == n2`, a string |
| `incant/pop/exprPinT:81` (C5) | `qr = fId(qa qb);` | SET (xl1) | 2 | **yes** -- its row says intended "a two-member list" |
| `incant/pop/exprPinT:88` (ST1) | `qs = 7; qs = fId(qa qb);` | SET (xl1) | 2 | no -- intended: nothing left behind, qs prints its tag |
| `incant/pop/faceT:34` | `faP1 = faSrc.parenT;` | count | 3 | no -- "want faP1 -- NOT READABLE" (its note, :94: a field with no data) |
| `incant/pop/kant8T:545` | `kOut = k7Self();` | count | 4 | no -- "want 46; a NAME here = the bracket ate the value" |

Since SEQ 313 (47): +2 `incant/lookup` (not in that population), +2 C5/ST1 (rows written since). ⚠ Context, not a
finding: C5's and ST1's `xl1` arrives at opAssign with **binType 0** (through the call's argument carrier) where
printFamilyNew's `n4` arrives with binType 3 -- the carrier hands `=` a node that is not itself the LIST.

**Kant operators that already copy or attach a list (read, trunk sources):**

| operator | method | with a list on the right | reaches |
|---|---|---|---|
| `=` | opAssign / jitAssignNodeRT | `copyListFrom`: clears the target's list, adds each entry (an entry with its own list via `new(entry)`) | **setContent** |
| `+=` | opPlusEQstruct (struct target) | `copyListTo`: each entry added to the target (addGroup copies a parented entry) | addAttribute / addMember |
| `+=` | opPlusEQisSTRING | concatenates the list's printed parts (appendGroup); no list copy | -- |
| `+=` | isCOUNT / isNUMBER / isBUFFER / isSTAK | refuse a LIST argument | -- |
| `+%` `+/` | opAddAttribute / opAddMember | a LIST argument: each item added; otherwise the argument added whole (a copy, `new(group)`, when it already has a parent) | addAttribute / addMember |
| `:%` `:+` | opReplaceAttribute / opReplaceMember | each item of a LIST replaced in, else the argument | `replace` |
| `-=` `*=` `/=` | opMinusEQ / opMultiplyEQ / opDivEQ | the op applied per item; no list copy | -- |
| `+<` | opAddProperty | the argument (copied if parented) onto the property list; its list rides with it | addProperty |
| `+*` | opAddPointer | an attribute POINTING at the argument; nothing copied | -- |
| `:=` | opSetGroup | holds the argument; nothing copied | **setGroup** |
| `<-` | opRebind | `target.group = argument`; nothing copied | **setGroup** |

Not operators, recorded so the list is whole: the `copyOf` command (wraps copyListTo). Whether a `new(group)` copy
carries the source's list by SHARING the body (C18) or by copying it is read from the docs, not measured here.

#### ⚠⚠ setData PARKED (SEQ 324 R0, Tony, 2026-10-09) -- a design decision is owed; NOTHING BUILT

**The proposal on the table, NOT ruled:**

| operator | becomes | does |
|---|---|---|
| `=` | **setData** | copies data only; **CLEARS** the target when the argument has none |
| `<-` | **setContent** | copies content, list included |
| `:=` | setGroup (unchanged) | the holder |

**It opens with a census of every `<-` use** (kant and fixtures): which sites rely on holder/rebind behaviour, and
whether `:=` covers them unchanged. **ST1 stays pinned** -- `7` on trunk since the c4 merge (intended `qs`) -- until then.

### `&&` in an `if` on trunk -- CONTEXT, not a finding (seal 99, Clod, 2026-10-08; kant, trunk binary of seal 99)

Tony's `testListed` (tester) folded three nested ifs into `if op.datA != 0 && result.datA != 0 && target.datA != 0;` and
the clauses "never ran". Measured: **`&&` and `||` are right between plain values** (0/1 flags: 1&&0, 1&&1, 0||1, 0||0 all
correct). **What fails is binding:** with no tiers and right-to-left, the line reads `op.datA != (0 && (...))`, i.e.
`op.datA != 0`, so the body ran with `result` empty (exit 139). `zero == 0 && one == 0` takes its branch the same way;
rows that happen to agree under that reading discriminate nothing. Add seal 86's half: **no short-circuit** --
`fFalse() && g()` runs g (exprPinT S3). Spellings that do NOT work around it today: grouping parens (`r = (a == b) && ...`
fails to parse), and `=`-capturing a comparison (a false comparison leaves a data-less field, which reads its tag and is
truthy, bear-trap 26). Spellings that do: nested ifs, or the 0/1 flag idiom (`fa = 0; if a == b; fa = 1;`). The cure is
the tier work on expr-accum (compareTier above the `&&`/`||` tier); exprPinT's B, U and S rows are its yardstick.

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
