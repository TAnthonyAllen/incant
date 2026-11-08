# clear on a holder -- recon for a ruling (Tony's docket, 2026-11-08)

**One plain line:** inside an action and on the new road, `clear(holder)` already empties the holder and `clear(*holder)`
reaches the target, which is the proposed ruling. Only a statement at a file's top level differs: there `clear(holder)`
empties the target. No fleet row clears a holder at top level, so no row would move. The missing-`;` rider is a list of
two adjacent operands that never runs, on both roads.

Measured 2026-11-08 on trunk `a6c6be4b`, binary as installed, kant/incant only. Nothing built. The probes are in
`docs/clearHolderProbes/`. Run each one from the Groups directory; every probe ends in a sentinel and exits 0.

## The docket item

`clear(selection)`, with `selection` a holder, cleared the field it points at (dESCRIPTIONs' `listChain` entry, measured
in tester), not the holder. By the star law a bare name means the holder. **Question for ruling:** should `clear(holder)`
empty the holder, with `clear(*holder)` reaching the target?

## What clear itself does

`cLEAR` (Commands.rtn:22) clears whatever node it is handed: it resets a buffer, clears a stak, or else runs
`clearData()` and `clearList()`. It never follows a group. So which node gets cleared depends only on what the call
path hands it.

## The measurement: three places a statement can run

"Holder" means a field bound with `:=`; `isGrouP` reads 1 on it before the clear (checked on every row).

| where the statement runs | `clear(h)` | `clear(*h)` | probe |
|---|---|---|---|
| inside an action body (old grammar), declared global holder | **holder emptied** (isGrouP 1 -> 0), target intact | -- | actionVsTop B0-B2 |
| inside an action body, action-local holder | **holder emptied**, target intact | **target emptied** | actionVsTop B3-B4, oldRoadStar A0-A2 |
| new road (`STARt("...")` + `testOP`) | **holder emptied**, target intact | **target emptied**, holder intact | newRoad N1, N1b |
| file top level (old road), declared holder, incl. `selection` | **target emptied**, holder still isGrouP 1 | **target emptied** | oldRoadStar K5-K10, actionVsTop B5-B6, oldRoadTop R1 |

The same global holder `gH` gives opposite answers in one run (actionVsTop): emptied when cleared inside an action,
target emptied when cleared at top level. So declaration doesn't decide it; where the statement runs does.

⚠ **A correction to the docket's wording, and to my own first pass:** a file's top-level statements always run on the
**old road**, even with KantGrammar first in the search list (tester's case). The new road is reached only through
`STARt("...")` plus `testOP`, as cmdCallT drives it. My first "new road" probe was really an old-road top-level run.
What showed it: the refusal it printed named `xl1`, the old road's accumulator, not KantGrammar's message.

**Mechanism at top level: not measured.** The candidates are wherever the top-level statement's argument is read through
a holder before it reaches opCall (`followArgument` only follows `isArgument`, so it is not that one). Not chased; the
ruling does not depend on it.

## Census: `clear(` across the fleet, tester and IncantForms

Population: every tracked file under `incant/` (fixtures in `incant/pop` included, `incant/attic` excluded),
`IncantForms/`, `genLadder/` and `jitLadder/`, by `git grep -F "clear("`, dropping `.clear(` and `xclear(` method
calls. 56 hits. That search covers every kant/incant call spelled `clear(`. It would miss `clear (x)` with a space
(a second grep found none) and untracked files (`incant++`). Tester no longer carries a `clear(` (Tony removed it
since the measurement).

| sites | where they run | argument | under the proposal |
|---|---|---|---|
| kantGrammar 35, 159, 474, 504, 567; ruleReturnT 48, ruleReturnOpT 49 | action | `instruct`, `ADJACENt` -- plain fields built with `+%` | unchanged |
| kantGrammar 475, 529, 534, 568, 569; ruleReturnT 49-50, ruleReturnOpT 50-51 | action | `pre`, `cmpP`, `logP`, `arg`, `op` -- **holders** (bound by `:=`, or by `=` from a holder) | **already empties the holder.** Reaching the target here would wipe the instruct just closed into `target`, or an Operators registry entry (`pre := Operators["negate"]`, `op = cur`). kantGrammar's EXPRESSIOn depends on the proposed semantics today |
| kantGrammar 205-551 (9 sites) | action | `*actionLabel` | target, as the star says; unchanged |
| kantGrammar 36, 64; utilities 220, 249 | action | `argument` -- a binding, which `followArgument` follows to the caller's field (makeInstruct "clears its pieces") | unchanged, but see the note below |
| utilities 211, 244; testPrecedence 11-12; inlineArgWriteT 11; jsonTest 23; unitTests 144 | action | plain declared fields (`newStuff`, `bothStuff`, `tpBag`, `tpOuter`, `awBag`, `listed`, `aGroup`) | unchanged |
| f31 59, bisectQ 75, anyOrNumT 43, trigDO 43, parser 37 | action | `CodE`, a plain attribute | unchanged |
| cmdCallT CC-4 `clear(cx)` | top level (old road) and new road | `cx=5`, plain | unchanged |
| generate 53 | reference only (not run) | `action` | -- |
| designDocs (6), parser 142, Notions/instruct 30, Stash/incant 395, BackupXML (2) | prose, or `clear()` with no argument in archived material | -- | -- |

**Rows that would move:** none found. Every holder passed to `clear` in the fleet is passed inside an action body, where
the proposed behaviour already holds. The only top-level fleet call (CC-4) clears a plain field. The case the ruling
changes, a holder cleared at top level, appears nowhere in the fleet. It was tester's line, now gone.

⚠ **`argument` is the one place where the bare name already reaches through**, by design (`followArgument`: "argument
is a BINDING, not a field"). Six live sites rely on it. A ruling that "the bare name means the holder" should say whether
`argument` stays the exception. Nothing in this recon argues that it should change.

## The rider: `clear(x)` then `describe();` with no `;` between

Both roads read the two calls as **one statement made of two adjacent operands**, and neither call runs. No error,
exit 0. The newline does not end the statement; only `;` does.

| road | `clear(tgtQ) bump(1);` (new) / `clear(tgtQ)` NL `bump();` (old) | the same with `+ 1` after it | probe |
|---|---|---|---|
| old, top level | tgtQ intact, bump 0 times (control: a lone `bump();` bumps once) | `REFUSED xl1 -- Operator + -- cannot apply to these operands` | oldRoadTop R3-R4, oldRoadAdjacent V2 |
| old, in an action | tgtV intact, bump 0 | -- | oldRoadAdjacent V4 |
| new | tgtQ intact, bump 0 (control: `bump(1);` bumps once) | `REFUSED + -- a list of adjacent operands is not built on the new road yet` | newRoad N3-N4, newRoadOperator |

The refusal with an operator is the discriminator: it names the adjacent-operand list on each road (`xl1` on the old,
KantGrammar's ADJACENt on the new). With no operator, nothing refuses. On the new road the statement is an ADJACENt list,
not an instruct, and nothing runs it. On the old road it is the `xl1` juxtaposition list. `bump() bump();` on one line
behaves the same way (V1: 0 bumps).

So **"it worked without the `;`" was an absence**: the clear never ran, so the registry entry survived. The rider's
own question, whether a list of adjacent calls that meets no operator should refuse by name rather than do nothing,
belongs to the parked adjacent-operands work (SEQ 467/468). It is not decided here.

**Note on the new-road control:** `bump();` with empty parentheses builds no call on the new road (known, cmdCallT
CC-6) and refuses `it1 -- not an instruct`, so the new-road probes use `bump(1)`.

## For the ruling

1. **`clear(holder)` empties the holder; `clear(*holder)` reaches the target.** This is already true in action bodies and
   on the new road. A yes changes only file-top-level statements on the old road, and no fleet row exercises that.
2. **Whether `argument` stays the exception** (the bare name follows the binding).
3. **Not measured, and possibly the larger question:** whether the top-level read-through is specific to `clear` or
   applies to every call that takes a holder at top level. A cross-check with `copyOf` failed on my spelling (a starred
   flag read, bear-trap #26 payment 7) and was dropped.

## Side observation (context, not a finding)

At top level, `hA := tgtA` on a name **declared nowhere** left `hA.isGrouP` reading 0; `clear(hA)` did not touch
`tgtA`, and `clear(*hB)` on a second such name did not touch `tgtB` (probe topUndeclared, K0-K4). The declared holders behaved as in the table. No row relies on either.
