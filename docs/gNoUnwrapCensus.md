# The `gNoUnwrap` census — scope for the removal stroke

Ordered by Fearless: *"the census still comes first — every site by file:line,
which arm dies, any non-clean bare-vs-flip pair reported before a delete."*
**Measured 2026-09-05. NO EDITS IN THIS COMMIT.**

The certificate for the removal, when it runs, is **grep-count zero + fleet
byte-identical + the `jitContext.h` static row struck from the `.twk` shopping
list**.

## The population is smaller than the grep suggests

A repo-wide grep returns ~190 hits. **Eleven are live gates.** The rest are
prose — `docs/`, `ipc/`, fixture headers, and this file — plus the declaration
and one harness reader. ⚠ **Counting the grep rather than the gates is how this
stroke would be mis-sized**; the prose is history and mostly must NOT be edited,
because a dated record rewritten to match a later convention falsifies itself.

## Group 1 — CLEAN. The bare arm is a legacy auto-unwrap and simply dies (6)

| site | what dies |
|---|---|
| `ruleActions.rtn:649` | `if (!gNoUnwrap) source = ::unWrap(source);` — iterate's legacy follow |
| `ruleActions.rtn:824` | `aCTionPrinT`'s walk unwrap, with its `!isArgument` exemption |
| `ruleActions.rtn:1309` | `generateXP`'s single-operand unwrap |
| `ruleActions.rtn:1384` | the same, in its non-generating twin |
| `GroupActions.rtn:1172` | `runShortCircuit`'s target unwrap |
| `GroupActions.rtn:1187` | `runShortCircuit`'s arg unwrap |

⚠ **The four `!isArgument` exemptions retire WITH these lines, not separately.**
They exist only inside the dying arms. `docs/wrapperPlan.md` §2.3 ruled that
`isArgument` itself does NOT retire with them — it still has readers in the
frame schema and in `Instruct.rtn`'s case 10 — so the FLAG stays and only the
exemptions go.

## Group 2 — the FLIP arm becomes unconditional; drop the `gNoUnwrap &&` (3)

| site | what stays, unconditionally |
|---|---|
| `ruleActions.rtn:654` | iterate's `isArgument` follow (ArgBinding) |
| `GroupActions.rtn:888` | `runOP`'s `:=` / `<-` rebind refusal |
| `jitEmitters.rtn:778` | `jitEmitBareRead`'s `isArgument` follow |

`GroupActions.rtn:898` is an `if (!gNoUnwrap) {…} else {…}` pair spanning both
groups: the bare arm dies, the else — B's `isArgument` follow — becomes the body.

## ⚠ Group 3 — NOT CLEAN PAIRS. Reported before any delete (2)

These are the two the instruction asks for by name. In both, **the two arms do
different things rather than "an extra unwrap versus none"**, so deleting the
bare arm removes behaviour rather than removing a hop.

**`Instruct.rtn:140` — `opAssign`.**
```
if (gNoUnwrap) { ::assignFieldCore(argument,target); }
else             target->setContent(argument);
```
`assignFieldCore` REFUSES a holder on the right by name; `setContent` just
copies. Two assignment semantics, not two unwrap depths. Removal makes the
refusing one unconditional — which is the intended end state — but it is a
**behaviour deletion**, and `docs/fixIts.md` records half B of that ruling as
PARKED over 179 sites in 21 files including `jsonTest`, a fleet baseline.
⚠ **That parked half should be re-read before this line is touched**, because
removing the switch is what makes the refusing arm unconditional for everyone.

**`jitEmitters.rtn:76` — `jitBindArgRT`.**
The bare arm does an unwrap **AND A BIND** — `setGroup` plus the chan counters.
The flip arm does the pending-slot bind. **Both arms bind**, differently, so the
delete removes a binding road rather than a hop. It is the correct road to
remove, and it is not a one-line excision.

## Also owed by the removal, and not a gate

- **`jitContext.h:632`** — `static int gNoUnwrap = 1;`, the switch itself, and
  its explanatory block at `:612`.
- **`genLadder/pop.sh:44`** — the staleness line prints the source's value. It
  must lose the `gNoUnwrap` read WITHOUT losing the binary-vs-source check
  beside it, which is bear-trap #49's instrument and outlives the switch.
- **`docs/wakeup.md`'s `.twk` shopping list** — the `jitContext.h` file-scope
  static row for `gNoUnwrap` is struck; one fewer global to migrate.
- **`docs/fixIts.md`'s "runtime `noUnwrap;` directive"** — never built, no
  longer wanted, retires with the switch.

## ⚠ Live fixture prose that describes the flag — review, do not sweep

`incant/starT`, `pointerT`, `holderT`, `spacingT`, `atypeT`,
`minionWork/tripwireNeg`, `minionWork/f46Star`. These are not gates; they are
fixtures whose headers explain behaviour "under `gNoUnwrap`". Several say
*"only meaningful under gNoUnwrap = 1"*, which stops being a caveat and becomes
the plain state. ⚠ `pointerT` row D is documented as **a flip tripwire** —
"reads 0 with gNoUnwrap OFF and OTHER with it ON" — so it asserts a distinction
that will no longer exist and needs a ruling rather than an edit.
