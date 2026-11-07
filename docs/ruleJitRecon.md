# A kantGrammar action under the old-road jit: the recon (SEQ 553, 2026-11-07)

Recon only, by R1; nothing is built. Road: **emitted / kant**, measured on trunk's bare binary of 2026-11-06 18:52.
"Measured" means run; "read" means read from source and not run. Probes were scratch files outside the tree.

R0 (Tony's word, via Clay): the first jitterized kantGrammar action is compiled by the old-road jit from its existing
body. The rebuild as a new-road chain is a later stroke, recorded and not scheduled.

## 1. Where rule code fires, and the one seat

**The path (read).** `parseRule` (GroupItem.twk:1360) and the generated road (Generate.rtn:76) call `fireLabelMethod`
(GroupItem.twk:716), which calls `fireActor.method(fireLab)`. `setActions` binds that method to `processAction` for a
coded rule (GroupItem.twk:1654, 1658), so a rule fire never passes through `runAction`, where the only intercept is
(GroupActions.rtn:1297). A deferred fire stores the same method on the label, so it also lands in `processAction`.

**`processAction` is the one seat, and within it line 773:** `result = result.gMethod(result);`

| processAction, in order | line | under the intercept |
|---|---|---|
| currentMETHOD = the rule; first-fire processCode | 746-747 | kept, runs first |
| branchKind saved and cleared | 750-751 | kept |
| actionLabel bound to this fire's label; terms bound or cleared | 757-766 | kept, per fire |
| locals cleared | 771-772 | kept |
| **the BlocK runs** | **773** | **the one replaced line** |
| branchKind, currentMETHOD, tempField restored | 774-776 | kept |

So all of the bracket and the binding stay interpreted and stay where they are. The compiled body replaces only the walk.

**Three things the seat must do (read):**
- Pass `jitterReady` the **rule**. At 773 `action` has been reassigned to `code`, and `field` may be the label, so the rule has to be saved before 768.
- Guard on `!jitting`, because an inlined callee passes through this function during an emit walk.
- Guard on `isRule`, so that an ordinary action taking the inlined path at GroupActions.rtn:1279 is untouched.

**STOP conditions: neither fires, on one condition.** No ruler slot is needed; the opt-in list sits beside `gJitter` and
`gJitterTally`, file-scope C++ in jitContext.h. No frame-model change is needed. **The condition is the gate: see ruling 2.**

## 2. Can jitBuildFunction take a rule's CodE as it stands?

**Not the CodE; the rule, yes.** Measured, `testing(<rule>)` under a 30 second alarm, exit 0, sentinel printed, all five:

| rule | degrade count | hand-over calls in the IR | native |
|---|---|---|---|
| XPRESs | 4 | 4 | 0 |
| TOPSTATEMENt | 5 | 5 | `topRun = 1`, `if topRun == 1` |
| SHORTCUt | 15 | 7 | 0 |
| ITERATe | 31 | 23 | see section 3 |
| PRINt | 28 | 5 | only inside the inlined makePrint |

The degrade count is higher than the IR's hand-overs where a callee's statements inline; a rolled-back statement also
degrades. `testing` fired each one with no label bound, so those runs' values mean nothing; only the compile is evidence.

The CodE itself (read): `actionBlocK()` on a CodE finds no builtinActoR, so it looks on the CodE, and the BlocK is on the
carrier. `jitBuildFunction` would walk nothing and return -2. Not run.

**What the compiled body must keep:**

| the requirement | status |
|---|---|
| **actionLabel, per fire** | **Kept by the seat** (read). Bound at 757-759, before the body. Handed-over statements read the field at run time. Native statements hit baked addresses of CodE's fields, and CodE is one per rule. No slot: the prologue walks the rule's own list, the locals are on the CodE, and the IR shows native writes going through a run-time helper on a baked address. |
| **The label-keeping return (seal 211)** | **Kept for the candidate** (read). A return runs as a hand-over; `jitStmtRT` runs it with the owner, the rule, as currentMETHOD, so an inner block's foot still skips the unwrap, and the compiled function has no foot of its own. `jitStmtRTValueRT` hands back kind 2, the node itself, **unless the node it holds is a count**. |
| **That exception** | A label holding a count comes back as a **box of the count; the label is lost**. Not reachable from ITERATe, whose built instruct is a list. **Reachable from EXPRESSIOn** (`instruct = kind` at kantGrammar:554), so it blocks EXPRESSIOn later. Read, not run. |
| **processAction's restore** | **Kept by the seat.** Lines 774-776 run after the call. |
| **The refusal ending the action** | **Half kept. Ruling 3.** The function does end (measured in the IR: `stmtRefused` branches to the epilogue). What the caller receives differs (read, below). |

**The refusal, and falling off the end (read, not run):**

| case | interpreted | compiled today |
|---|---|---|
| a refuse() in a statement | block breaks; hands back the prior value, or null, which fails the fire; `refused` stays armed (processAction does not clear it) | function leaves with kind 1, value 0: **a box of 0, non-null, adopted as the label**; `jitStmtRT` has **cleared** the arm |
| ran off the end | the last statement's value, or labelNO | kind 1: **a box of the result slot, adopted as the label** |

The kind 1 start is the old road's convention for actions (jitEmitters.rtn:457). `runAction` copes with it; `fireLabelMethod`'s adoption does not.
ITERATe reaches neither on a parse: every path of it ends in a `return`, and its own refusals are `cerr`, `clear`, `return`, not refuse().

**A first-fire detail (read):** `jitterReady` clears `ruler->refused` after a compile, so a refusal armed before the first fire would be wiped. Small; a guard or a row at build.

## 3. The candidate: ITERATe (kantGrammar:228)

Of the rule actions, only ITERATe, TOPSTATEMENt and EXPRESSIOn write a plain count, and EXPRESSIOn is the largest and has a loop.

**No loop, so F-145 cannot be met**: no `while`, `do` or `for` in its body or in the inlined makeInstruct.

| statements | fate |
|---|---|
| `aOn = 0;` `mOn = 0;` | **native** (measured in the IR: helper call on a baked address) |
| `if attributes.datA != 0; aOn = 1;` and the `members` twin | **native**: the condition is a run-time dot call, not a build-time read, and the arm is a native write |
| `:actionLabel ANYtoken attributes members ITERSOURCe;` `:ITERSOURCe ANYtoken;` | handed over (scope) |
| `cursor :=`, `source :=`, `aMint :=`, `mMint :=`, `op :=`, `armsMint :=`, `built :=`, `*actionLabel :=` | handed over (`:=`, copyOf, a call) |
| every `+%` | handed over |
| `if *ITERSOURCe["UnaryOPS"];` with its deref build | handed over |
| both `if ... datA == 0;` refusal checks | **native if** (its arm's `cerr`, `clear`, `return` are handed over, one each, in the degrade list) |
| `return *actionLabel;` | handed over |

**Why it over the smaller TOPSTATEMENt:**
- It ends in the label-keeping return, the thing most worth certifying. TOPSTATEMENt has no return, so it falls off the end into the box above on every fire.
- `aMint := copyOf(aOn)` is a handed-over read of a natively written local, so a wrong kind on the native store shows up as a wrong filter. **This is the row that says whether native and handed-over agree.**
- Two fires with different terms catch anything baked at the first fire, and the filters are observable in the iterate that runs.
- `incant/pop/iterT` already drives it, including at the root (row IR-0 `it1 = ITERATe(...)`), with an old-road column.

TOPSTATEMENt would also run the whole program inside a compiled body, on every statement, as the first case.

## 4. The certificate

- **Compiled equals interpreted, by value, per row.** iterT's IR rows with a compiled column, plus rows it lacks: `attributes`, `members`, a starred source, and **attributes then members in one process** (the second fire differs from the one that compiled). The two refusals by name, with the fire's outcome.
- **The witness: native above 0.** ⚠ **It does not exist on this road.** `=== jitter walk: ... native N ===` (jitEmitters.rtn:5425) is the chain walk's only. `=== jitter: X built N called M ===` will print for a rule, and says nothing about native. An old-road counterpart is part of the stroke; expected value for ITERATe, stated before the run: 6 of its own top-level statements native (`aOn = 0`, `mOn = 0`, four ifs), with 2 more native writes inside two of those ifs. Ruling 4.
- **H7, one per half:** intercept removed, the witness reads no compile and goes red by name. Binding left unbound: actionLabel's lines skipped under the intercept, the rows go red by value. Each by the single fixture under an alarm.
- **pop.sh and jitLadder row for row** against `pop.fails` and the capture; both run on the branch. Also the seal's other instruments, as any landing.

## 5. Rulings wanted

1. **The candidate:** ITERATe, as above.
2. **The gate.** Opening the seat on `gJitter` alone compiles **every** coded rule fired after `jitter;`, EXPRESSIOn and its count-label exception included, so it cannot be the first stroke. Lean: an explicit opt-in, `jitterRule(ITERATe);`, a list beside gJitter, with one new command (canary +1, setup, groups.ext). The fleet's exposure to the wider gate is not measured: a lexical census of 31 files shows the jitter fixtures building before `jitter;`, but pop.sh writes twins, so that population is not whole.
3. **What a compiled rule hands back on a refusal and on running off the end.** Lean: for the first stroke, not reachable from ITERATe, so write it down, add a docket row, and refuse by name at the seat if `gJitRetKind` comes back 1 from a rule. A silent box adopted as a label is the outcome to rule out; a loud refusal is cheap.
4. **The witness:** an old-road counterpart of the walk line, counting the function's own statements.

## 6. Cautions, as carried in

- **F-145:** the candidate has no loop. PRINt, STARt, BLOCk and EXPRESSIOn do, the first through makePrint, though none has a literal condition, which is F-145's shape.
- **Old-road defects:** none hit in these compiles; `kindZeroT` (red ledger 9, `.datA` reading a number field before its slot flushes) is the one closest to ITERATe, which reads `.datA` only on terms it does not write. Reported, not chased.
- **ELSEIf** shares If's CodE and BlocK (SEQ 528), with a separate rule body, so the cache keyed by body would compile it twice. Later.

## 7. Built: SEQ 554, branch `rule-door` (70ec82dd), measured 2026-11-07

Rulings as section 5, with Clay's addition: a per-fire count, so that compiled equals interpreted cannot pass with the interpreted road doing all the work.

- **The door:** processAction's walk line only. Binding, local clear and restore are unchanged. No ruler slot, no frame change. `jitterRule` is the one new extern (canary 443 -> 444) with one groups.ext line.
- **Witnesses:** `=== jitter rule walk: ITERATe native 6 handed 17 ===` per compile, exactly as registered in section 4 before the run. `=== jitter rule: ITERATe built 1 fired N ===` at exit, printed even at zero.
- **The rows:** `incant/pop/ruleDoorT` and pop.sh: 9 RD rows on two arms, each exit, sentinel, pinned value, compiled = interpreted, fired count, walk line, including attributes, members, a starred source, and two fires with different terms in both orders. Plus `jitter;` alone, a non-rule opt-in, and the guard's rows. 73 rows, all green.
- **H7s, each a single-fixture run under an alarm, restored md5-identical:**

| removed | what moved |
|---|---|
| the door | `built 0 fired 0`; **the values stayed right**, which is exactly why the count exists |
| the binding, under the door | every RD value empty, `REFUSED deref`, then the guard's line |
| the guard | FELLOFf compiled reads `ANS 1`: the box is adopted |

- **The guard's reach:** ITERATe cannot reach it, as the recon said. It is driven from the fleet by three scratch rules in the fixture.
- **Not reached:** ITERATe's two `REFUSED ITERATe` arms. `iterate 5 on fsrc;` and `iterate ic on 5;` do not take them, interpreted, so no row pins them.
- **Fleet:** see seal 363. Everything outside these rows is unmoved but for an address (H3), the fixture-name count and the groups.ext mirror count, both bookkeeping.
