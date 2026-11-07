# The operator rung: `+%`, `:=` and `copyOf` compiled natively. The recon (SEQ 558, 2026-11-07)

Recon only, by R2; nothing is built. Road: **emitted**, with kant fixtures. "Read" means read from source; "measured" means run, on trunk's bare binary. The dispatch's SEQ was blank; this calls it 558.

**One plain line: all three can be call-throughs with no frame change, no ruler slot and no new slot kind, and most of the plumbing already exists in `jitEmitOpFire`; one defect must be fixed on the way (`**`), and one ruling is needed on how far the first stroke reaches, because turning them on everywhere moves pinned rows across the fleet.**

## 1. How each runs today, and why it is handed over

| | `+%` | `:=` | `copyOf` |
|---|---|---|---|
| C++ | `opAddAttribute(argument, target)`, Instruct.rtn:125 | `opSetGroup(argument, target)` | `copyOf(grup)`, Commands.rtn, extern "C" |
| Does | Refuses a null by name (F-147). A list argument attaches each entry; a holder entry attaches its content, one level (SEQ 399). Else attaches the argument | `target.setGroup(argument)`; a null argument clears | New field, copies the body by struct, not isLocal; copies the list, unless virtual |
| Hands back | target; null when armed or refused | target; null when armed | the new field |
| Registered | `'+%' operateMethod=opAddAttribute assignTier`, setup:173 | `':=' operateMethod=opSetGroup assignTier`, setup:148 | `copyOf immediateAction`, setup:38 |

**Why handed over, read at `runOPdirect`, GroupActions.rtn. There are two gates, in this order, not one:**

1. **The kind gate (line 1436).** An operator other than `=` or `.` with an operand whose kind the jit cannot carry hands over. A list target (`+%`) and a holder target (`:=`, whose `jitNoteWriter` kind 6 makes it non-scalar) both trip it, so **a `jitEmitter=` alone would not reach its emitter.** This is the "operand whose kind is not a count or a number" degrade.
2. **`jitOpEmits` (line 1451).** With no `jitEmitter=` and not on the gated list, it hands over: "an operator with no emitter". `copyOf` takes the same line's other arm, "a command call": a command emits only if it is `jitTrace`.

**A knock-on, measured in today's degrade lists:** a handed-over `:=` records its target in `gJitRTHolders`, so every later `*target` hands over too ("a dereference of a holder written at run time", `opDeref`, Instruct.rtn:295). So native `:=` also frees the stars that read it.

## 2. What a call-through needs

**It already exists for operators: `jitEmitOpFire` / `jitOpFireRT` (jitEmitters.rtn:1527).** It is how an operator with members fires. It bakes `op`, takes each operand's run-time node, flushes a frame operand, reloads a frame target, marks the statement able to refuse, and calls the C++ `gOp` by address. So `+%` and `:=` need a gate exemption and a route to it, not a new mechanism. R1's "calls the existing C++ method directly" is exactly this.

| operand | source | how it arrives |
|---|---|---|
| a local or field | baked field address | `bake(field)`, with a frame flush if slotted |
| `*x` | `jitEmitDeref`'s fresh node, whose run-time pointer is `jitData->jitNode` | `jitEmitOpFire` already prefers `jitNode` |
| `copyOf(...)` | **new**, a fresh node the same way | same |
| a literal | baked | same |
| a handed-over statement's result | not available: it is a field read at run time, and a field it wrote reads as a field | baked field |
| `x[...]`, an action call | still handed over, so their statements stay handed | not in this rung |

**What comes back, and where it lands.**
- **`:=`** hands back its target, which nothing reads. The target is a holder: `jitNoteWriter` already gives it kind 6 and so no scalar slot, and a late finding restarts the build. **No new slot kind.**
- **`+%`** hands back its target; nothing reads that either. It writes the list, never a scalar.
- **`copyOf`** hands back a node pointer with no scalar, on a fresh node with `jitNode` set and no `jitValue`.

**Refusals keep their road:** `gJitStmtCanRefuse = true` emits the run-time check, so a refuse in the call leaves the function at that statement.

## 3. What must be handled, and would otherwise be wrong

| finding | grade | consequence |
|---|---|---|
| **`**x` is not compiled correctly.** `jitEmitDeref` bakes its operand's address and never reads `jitNode`, so a star on a star's fresh node would read the fresh node, which holds no group, and yield null. It has never shown: every `**` in today's fixtures is on a run-time holder and hands over (measured: `res = **phh` hands over and reads 4) | read | **Must be fixed in this rung**, because `cond := **EXPRESSIOn` is the commonest shape in the safe group. It is a small change in one emitter |
| **`copyOf` must read the FIELD, never a seeded value.** `jitEmitOpFire`'s argument arm boxes a value carried in a slot, under the tag `jitOpFireBox`; a copy would then carry the wrong tag. So `copyOf`'s emitter bakes the field and flushes, as the box arm does not | read | Its own emitter, not a route through `jitEmitOpFire`'s arm |
| **The action's `argument` is a binding.** `runOPslots` follows it at build, so a native read would bake the build's binding | read | Hand over any statement with an `isArgument` operand, as the walk already does (`argumentHandedOver`). This keeps all of inlined makeInstruct handed over, which is fine |
| **An adjacent argument, `a +% b c`**, reaches the operator as a run-time list, which the build cannot see as an operand | read | Stays handed. In the safe group that is `miArgs +% op x`, in every rule |
| **The eager unbox in `jitEmitDeref`** on a null: `jitUnboxCount` tests for null. Fine. The star ruling holds on both roads: `jitDerefRT` yields null, and `+%` refuses it by name | read | So F-147's rows and RF-O should read as they do. A row asserts it |

## 4. Both roads: one emitter each, two front doors

**`+%` and `:=` take one slot.** The walk goes through `runOPslots` too (`jitWalkExpr`), so `jitEmitter=` on those two operators serves both roads. `jitSlotTaken` counts them, and a slot makes them walk-eligible.

**`copyOf` takes one emitter and two call sites:** `runOPdirect`'s command arm on the old road, and a new arm in the walk, because `jitWalkCallOK` refuses anything but an action.

**The walk needs two widenings the old road does not.** `jitWalkEligible` returns 0 for a unary and for an operand it does not know, so `x := *y` and `x := copyOf(y)` stay handed over on the walk until it admits `deref` and `copyOf`.

## 5. The boundary row: `aMint := copyOf(aOn)`

Today it is one handed-over statement that reads the field. Natively, `copyOf` is called with `aOn`'s baked field address and reads the same field at the same moment.

- **On a rule, the field is already current.** A rule's locals live on its CodE, the prologue walks the rule, so they have no slot; the IR shows `aOn = 0` as a helper call writing the field directly, and RD-3 and RD-4 show its kind is right.
- **In an action, `aOn` has a frame slot,** so the emitter must flush it, with its kind, before the call. The machinery exists (`flush` in `jitEmitOpFire`, `gJitFrameAssigned`).
- **Then `:=` holds the copy** in `aMint`, and `iterArms +% *aMint` reads it at run time through a star. That star goes native because `aMint` is no longer written by a handed-over statement.

**The row then has no hand-over in it at all,** so RD-3 / RD-4's filter is what certifies it. Row to add: the copy keeps the tag `aOn` and the count, on both arms.

## 6. Predicted native counts, to be registered before the run

Top-level statements of each rule's own body, by reading each against section 3. `?` means `x := *y.prop` then `if x == 0`, whose dot-product operand I have not measured; the lower figure assumes it stays handed.

| rule | native / handed today | predicted native / handed | what stays handed |
|---|---|---|---|
| ITERATe | 6 / 17 | **14 / 9** | two scope lines; `if *ITERSOURCe[...]`, which writes `source`, so `iterArms +% *source` stays too; `op :=`; `miArgs +%`; `built :=`; `*actionLabel :=`; return |
| FOr | 2 / 16 | **9 / 9** (`?`: +2) | scope; `op :=`; `miArgs +%`; `built :=`; `loopOwnsBody`; `*actionLabel :=`; return |
| If, ELSEIf | 0 / 15 | **5 / 10** (`?`: +4) | as FOr |
| WHILe, Do | 0 / 14 | **5 / 9** (`?`: +2) | as FOr |
| BRANCh | 0 / 9 | **2 / 7** | also the `if *kw.taG` pair |
| SHORTCUt, SEARCh, DEBUg, SCOPEXp | 0 / 7 | **1 / 6** | `*lMint.methoD =`, where it applies |

**So "native above 0" becomes satisfiable for all of the safe group,** which is what the amended order wants.

**What is left, for R0's "buys speed":** `op := Operators["x"]` (a subscript), `built := makeInstruct(...)` (an action call), and the star on `built` it causes, in every rule. Those three are the next rung after this one, not this one. **Each compiled rule keeps at least 5 crossings until then.**

## 7. Ruling wanted: how far the first stroke reaches

**Turned on everywhere, this moves pinned rows.** A slot on `:=` and `+%` changes every compile, not only rules. 30 fixtures run jitted code containing `:=` or `+%` (a lexical census of their live regions, so likely short of the generated twins), and pop.sh has 93 lines and jitLadder 86 that mention degrades, hand-overs or the walk's witness. Every `walked handed native` pin in those moves if the statement goes native. **The dispatch's "pop.sh and jitLadder row for row" cannot hold on that road**; it would need a registered list of movers.

**Lean: two strokes.**
- **Stroke 1, opted-in rules only.** The emitters run only while the door is compiling a rule on `jitterRule`'s list, gated by a file-scope flag beside `gJitterRules`, not a ruler slot. Old road only. ITERATe's and FOr's counts rise, and every other row holds, so the certificate stands as written.
- **Stroke 2, everywhere and the walk.** Remove the flag, widen the walk, and register each mover with a sentence.

The alternative is one stroke with the movers registered up front: larger, and every wrong answer lands in one diff.

## 8. The certificate, named

- **Native counts:** section 6's, confirmed or revised by a dry read at the build's start, then registered before the run, exactly. The census's native column recomputed from the witnesses.
- **Twins:** ruleDoorT's and ruleForT's rows, all equal by value. The walk's own fixtures unchanged under stroke 1, re-run under stroke 2.
- **New rows:** `copyOf` keeps tag and value; `**` by value, on a rule; F-147's shape stays named on both arms (RF-O and the RC rows).
- **H7, one per operation:** with each emitter removed its count falls back and the values stay right. **Three controls, each with a single fixture under an alarm.**
- **H7's limit, said now:** "values stay right" is the point of these three, so a value row cannot be what goes red. The count row is.
- **Fleet:** pop.sh and jitLadder row for row.

## 9. STOP conditions

**None fires.** No frame-model change: rule locals are already on fields, and action locals use the existing flush. No new ruler slot: stroke 1's flag is file-scope, beside `gJitter`. No new slot kind: `:=` targets are already kind 6, and `+%` writes no scalar.
