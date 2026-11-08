# F-146 recon -- a compiled rule's ending (SEQ 564 R1, 2026-11-08)

**One plain line:** a compiled body can hand back only a count or a node, and it hands back a count in three places where
the interpreted body hands back a node or nothing; the cure is to hand back exactly what the interpreted body does, and
one part of it (a rule that runs off its end) needs Tony's ruling first.

Recon only, nothing built. Trunk `a2922c4f` (stroke 2 merged), binary bare. Road: **emitted**. Probes in the scratchpad,
each run interpreted and through `jitterRule(X);`, values read back.

## 1. What it is

**Today:** a compiled rule that refuses, runs off its end, or returns a label holding a count leaves with a bare count, and
the rule door refuses by name and adopts nothing -- where the interpreted rule adopts a value or nothing quietly.

**The mechanism.** A compiled function returns an i32 and a kind (`gJitRetKind`: 0 nothing, 1 count, 2 node, with
`gJitRetNode`); `jitTakeReturn` turns kind 1 into a fresh box of the count. Three endings come out as kind 1:

| ending | why kind 1 | interpreted |
|---|---|---|
| a refusal mid-body | it leaves through the epilogue, and the kind starts at 1 (`jitBuildFunction`) | adopts nothing |
| running off the end | same start, nothing sets it | adopts the last statement's value |
| a handed-over `return` of a node that is, or holds, a count | `jitStmtRTValueRT` follows a holder and sends any count as kind 1 | hands back the node |

The third row is two shapes. **A label holding a count:** XPRESs's `return *actionLabel` hands back its label; the label
holds EXPRESSIOn's chain, and an assign chain's top instruct carries a count, its tier (`instruct = kind`,
kantGrammar EXPRESSIOn). **A holder on the new road:** nh's `return h` (h bound by `:=` to 7); the new road's interpreted
`return h` hands back the holder (kind read 6), while `jitStmtRTValueRT`'s follow is the OLD road's rule (aCTionBlocK
follows, `oh` reads 5 on both roads).

**The sites:** `GroupActions.rtn` processAction, the rule door's guard (`ruleDoorGuard`, the `if ( ruleKind == 1 )` refuse);
`jitEmitters.rtn` `jitStmtRTValueRT` (the follow and the count test) and the kind 1 start in `jitBuildFunction`.

**A correction to seal 381 (Q2):** "nothing reads `instruct = kind;`" was true of the interpreted fleet only. Compiled, it
is read: with the line removed, XPRESs through the door reads `qr = qa + 1` as 3 and `qr = 4` as 4 with no guard line;
with it, the guard fires and the statement is lost (QR 0). docs/cleanupList.md is corrected.

## 2. What it blocks, and what each reads now

Measured 2026-11-08, interpreted against `jitterRule(X);`:

| rule / row | interpreted | compiled today |
|---|---|---|
| **nh** (newReturnKindT, new road, under `jitter;`) | 7:6 | refused by name, NOT JITTABLE (stroke 2's R1), so it runs interpreted: 7:6. Refusal out: built, **7:5** |
| **XPRESs**, `qr = qa + 1;` | QR 3 | **QR 0**, one guard line: the statement is lost |
| XPRESs, `qr = 4;` | QR 4 | **QR 0**, one guard line |
| XPRESs, `print qa:;` | 2 | 2 (a print's instruct carries no count) |
| **TOPSTATEMENt** (through FILe), `qr = qa + 1;` | QR 3 | QR 3, **one extra guard line** (it falls off its end on every path) |
| **INVOKEr**, `qr = fId(qa);` | QR 2 | QR 2, no guard. Its `return ANYtoken` exit (kind 1 in the IR, per the census) is not reached by any spelling tried: `fId()` builds no call (cmdCallT CC-6), `qr = qa` never fires the rule |
| **EXPRESSIOn** (seal 381 Q4) | right | every shape wrong: `r = b`, `a + b`, `- b` assign nothing **silently**; `a < b` refuses `+% -- an operand that is nothing`, then the guard; a call meets the guard twice |
| **If**, `if qa > 1; qr = 5;` | QR 5 | QR 5, no guard on this shape. Its refusal shape (as FOr's RF-O) is read, not run |
| ruleDoorT RG **REFUSEs** | ANS untouched | ANS untouched, **1 guard line** (pinned) |
| ruleDoorT RG **FELLOFf** | ANS 1 | **ANS untouched**, 1 guard line (pinned, the deliberate difference) |
| ruleDoorT RG KEEPs | ANS untouched | same, 0 guard lines |
| ruleForT **RF-O** | the child's refusal | the same and **1 extra guard line** (pinned) |

**EXPRESSIOn is not cured by F-146 alone.** Its silent cases (an assignment that does nothing, no refusal) are a second
mechanism, not measured; it also sits in the census's F-145 group (its own `while cur.datA` loop).

## 3. The cure

**In one sentence:** a compiled body hands back exactly what the interpreted body hands back -- a returned node leaves as
that node, a refusal leaves with nothing -- so the door's guard can never fire and is deleted; running off the end waits
on a ruling.

**The shape, four parts:**
1. **The handed-back value, `jitStmtRTValueRT`.** A label leaves as itself (kind 2, the node), never followed to its
   count. A holder is followed only on the old road, as aCTionBlocK follows it; on the new road (the handed-over statement
   is a testOP instruct) it leaves as the holder. The road is recorded at run time beside `gJitStmtRTValue` -- a C++
   global in jitContext.h, as its neighbours are.
2. **A native `return` of a label** (`jitEmitReturn`) leaves as the node too. INVOKEr's `return ANYtoken` is the one known
   case; unreached by the fleet, so this part is IR-only until a spelling reaches it.
3. **The label a rule adopts, on a refusal.** The epilogue reads the refusal arm before it clears it, and an armed exit
   leaves kind 0 (nothing), as the interpreted rule adopts nothing.
4. **Running off the end -- RULING OWED (Tony, SEQ 555: "whether both roads should refuse a rule that runs off its end
   belongs to its cure").** (a) the compiled body adopts the last statement's value as the interpreted one does, which
   lets a box become the label and undoes the door guard's own principle (SEQ 554 R2); or (b) both roads refuse a rule
   that runs off its end by name, which changes the interpreted road, and TOPSTATEMENt (off the end on every path) gains
   `return *actionLabel;` in the same stroke. **Lean: (b)** -- a rule hands back its label on purpose, and the one rule
   that does not is TOPSTATEMENt.
5. The guard is deleted (or kept as an unreachable assertion, Tony's call). nh's by-name refusal (stroke 2's R1) is deleted.

**What it touches:** the handed-back value (1, 2) and the label a rule adopts (3, 4). **Not the frame.** No new ruler slot,
no frame-model change, no change to gJitMethod's signature (`i32(ptr)`; the kind already travels by globals).

## 4. The certificate, pre-registered

Rows to register on trunk before the build, at today's values, the intended beside each:

| row | today | intended |
|---|---|---|
| newReturnKindT nh witness (new): built under `jitter;` | NOT JITTABLE (by name) | built 1 called 1 |
| newReturnKindT under jitter; = plain (existing) | green, nh 7:6 | green, nh 7:6 |
| ruleDoorT REFUSEs guard lines (existing) | 1 | 0, ANS untouched both roads |
| ruleDoorT FELLOFf compiled + guard lines (existing) | ANS untouched, 1 | (a) ANS 1, 0 / (b) both roads refuse by name, ANS untouched |
| ruleForT RF-O guard lines (existing) | 1 | 0 |
| XPRESs through the door (new fixture, as ruleForT is FOr's): `qr = qa + 1;`, `qr = 4;`, `print qa:;`, `5;` | QR 0 + guard, QR 0 + guard, 2, (not run) | = interpreted, 0 guard lines |
| TOPSTATEMENt through FILe (new rows): `qr = qa + 1;` | QR 3, 1 guard line | QR 3, 0 guard lines (and, under (b), its new return) |
| INVOKEr through the door (new row): `qr = fId(qa);` | QR 2 | QR 2 (a control: must not move) |

**H7s, each on its own, cure committed first:** (1) restore the holder follow and the label decay in `jitStmtRTValueRT`:
nh reads 7:5 and XPRESs `qr = qa + 1` reads QR 0 again; (2) remove the armed-exit kind 0: a compiled REFUSEs adopts a box,
so its ANS reads a count, a value change, not only a line.

## 5. Movers expected outside that set

- **None from part 1 in the fleet beyond nh.** A census of every live action body in `incant/pop` for a bare `return` of a
  name bound by `:=` (positive control: nh, found) gives five: nh, oh, argBindT abSet, dotChainT dcTouch, ruleReturnT
  rrAct. Only newReturnKindT is ever compiled (no `jitter;`, `jitterRule` or `testing(` in the other three, and pop.sh
  drives none of them under the jitter); oh is the old road, whose follow stays.
- **Label returns already leave as nodes** where the label holds no count: ITERATe and FOr build through makeInstruct, which
  sets no count, and KEEPs's label holds a word. Expected unmoved: ruleDoorT RD rows, ruleForT's value and stderr rows.
- **Part 3 can move a compiled action that refuses mid-body when its caller reads the return:** it leaves nothing where it
  left a box of 0. Candidates, to be measured by the build's own census: refusalEndsT, the jitRefuse* fixtures, argRoadsT
  AR-J1. Not measured here.

## 6. Functions the cure would touch, and their directive anchors

jitStmtRTValueRT, jitStmtRT (the road), jitTakeReturn, jitEmitReturn, the epilogue in jitRunAction, processAction (the
guard): **only processAction carries a directive**, parked (`ctive`), anchored at `code` (`code = action.actionBody();`),
in Directives/GroupRules and Directives/groupDirectives. The guard sits in a `-% %-` passthrough below it; the anchor
is untouched.

## 7. R1's census (SEQ 565, 2026-11-08): every rule with code, and every path that runs off its end

Ruled first (SEQ 565 R0): option (b) -- a rule whose code runs off its end is refused by name on both roads; TOPSTATEMENt
gains `return *actionLabel;`. The census asks whether TOPSTATEMENt is the only such rule. **It is not: `list` is the second.**

**Population and how it was read.** Rule-ness was asked of the running system (`NAME.isRulE`, a positive and a negative
control in every probe that loads the file), not read from text, because kantGrammar's rules carry no `isRule`.

| source | code bodies | rules among them | runs off its end |
|---|---|---|---|
| incant/kantGrammar | 21 (regex count = grep count) | 19 (+ ELSEIf, which shares If's code); makeInstruct and makePrint are Utilities actions | **TOPSTATEMENt**, every path. The other 18 end in `return *actionLabel` (INVOKEr: `return ANYtoken` after its call path) |
| incant/grammar | 0 (its rules act through C++ aCTion methods) | 0 | -- |
| incant/unitTests | 41 | **list** (`list isRule entries=ANYstring+ SemI?- code={ print ...; for sumGrup in entries; print ...; }`, unitTests:147) | **list**, its only path |
| incant/utilities (included with unitTests everywhere) | 13 | JSONfield, JSONarray | neither: both end in `return *jfOut` / `return *jaOut` |
| IncantForms/WorkingOn/tester | 3 live | 0 (measured: describe, listChain, printDef) | -- |
| IncantForms: scratch (measured, control NamE 1), checkSKIP, parser, Windows keyStroke / simple / tree | 3, 1, 4, 2 / 1 / 1 | 0: actions in TestStuff / Utilities, and field handlers on window fields | -- |
| IncantForms: forms, formsRecon, macros | prose (no stop line; `code={` appears in descriptions) | -- | -- |

**`list` is live in the fleet.** unitTests' `testList` and the testUnitTests driver both call `list("righty 3.1 seven eight
nine;")`, and `incant/pop/baselineTests.golden` holds its output (`list tests the for statement:`) twice -- baselineTests
is the only fixture that reaches testUnitTests (pop.sh:273). Under (b) as written, `list` would refuse on both roads and
that golden would move. **Ruling owed: `list` gains an explicit `return *actionLabel;`, or it is refused.**

**Not covered:** rules defined inside fleet fixtures (incant/pop). They are outside R1's named sources but inside R0's
reach (both roads); ruleDoorT's FELLOFf is one, deliberately. A first static pass over them was void (its pattern counted
any field with an attribute as a rule) and is not reported; a census by `isRulE` per fixture is the read to do next if
Tony wants it before R2.
