# Ledger row 1, the recursion measure (Tony, SEQ 529 R1; measured 2026-11-05, trunk binary, nothing built). STOPS FOR A RULING.

Road: kant. Old = the action as defined; new = the same text through compileIn (KantGrammar STARt). Probes: docs/recursionProbes/ (rc, ra, rs; run from the repo root).

## The answer: IT IS NOT RECURSION. The two roads disagree on a bare `argument` as an operand.
The new road never recursed. `r = f(argument - 1)` refuses at the `-` on every call, depth 0 included, so `r` stays unwritten and reads its tag.

**With `*argument` the new road recurses correctly (rs):** entries 3, 2, 1, 0 in order, and returns "s", 1.5 and 5 at every depth tried, by a local or by a direct return. A plain call that does not touch the argument agrees across all four old / new pairings (rc).

## What each spelling does, one variable at a time (ra, args 0 and 3)
| in the action body | old road | new road |
|---|---|---|
| `cerr argument` | 0, 3 | 0, 3 |
| `argument.datA` | 5, the value's kind | 6, a holder |
| `*argument.datA` | no value (echo) | 5 |
| `if argument < 1` | yes, no | **no, no: SILENT and wrong at 0** |
| `x = argument - 1` | -1, 2 | **REFUSED** |
| `x = 1 + argument` | 1, 4 | **REFUSED** |
| `y = argument; y - 1` | -1, 2 | y prints right, **then REFUSED** (AL-3a's shape) |
| `y = 0; y = argument; y - 1` | -1, 2 | y prints right, **then REFUSED** |
| `if *argument < 1` | yes, **yes: SILENT and wrong at 3** | yes, no |
| `x = *argument - 1` | -1, **-1: SILENT and wrong at 3** | -1, 2 |

**So no one spelling works on both roads**: bare fails on the new road, star fails on the old. And the old road's starred recursion looks right by accident: `os1(2)` enters once and returns "s", because `*argument < 1` is true on a value (a star on a plain field yields null, by the star ruling). Its printed answer agrees and its walk does not.

## Why (read; the table agrees)
Both roads mint the action's own `argument` and runAction binds it as a holder.
- **Old road:** runOPslots (GroupActions.rtn:1429) calls `followArgument` on both operands. Its comment: "argument is a BINDING, not a field: an isArgument operand holding a group yields what it holds".
- **New road:** testOP (GroupActions.rtn:1560) calls `op.operat(argument,target)` with no follow, so the holder reaches the operator. opMinus has no arm for it and refuses; `<` answers false. Print follows on its own, which is why the value looks fine.

## Which road is right
**For a bare `argument`, the old road**, on its own written rule that argument is a binding, and because the new road's two silent or refusing answers are on a program that reads correctly. **For `*argument`, the new road**: Tony's kant bodies write it (`*argument := *target; return *argument;`), and the old road's reading is a silent wrong walk. This second half is the part that needs a word, since a star on a binding is not covered by the star ruling's text as far as was read.

## What the ledger row should have said
"Measured once, not diagnosed" was a wrong symptom: its `r` is the tag echo of a local the refused statement never wrote. docs/argumentCensus.md already filed AL-3a under holder arithmetic "by ruling, on both roads"; on this table the old road does not refuse it, because the follow runs first. newLocalArgT's AL-3a rows pin the minus. **Nothing pins the silent `argument < 1`.**

## NOT DONE, NOT TRIED
No cure was run. Candidate, read only: testOP follows its binary operands as runOPslots does, leaving unary `*argument` alone, so bare and star both work on the new road. The old road's starred reading is a separate question.
