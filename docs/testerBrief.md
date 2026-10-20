# tester -- what was measured before the tester session (2026-10-20)

`IncantForms/WorkingOn/tester` is Tony's kant expression algorithm: it builds an instruction chain that `testOP`
(GroupActions.rtn, 12 lines) runs. These are the facts measured on 2026-10-20 (kant, trunk) for the session that changes
it. Tony brings the plan of attack; this file is context, not a plan.

## The order question

- **tester folds RIGHT TO LEFT; the ruled order is LEFT TO RIGHT.** `righty -= qa - qb + qc` (13, 2, 3, 4): tester builds
  `qa - (qb + qc)` = -5 and gives 18; the old parse gives `(qa - qb) + qc` = 3 and `13 - 3` = **10**. That is D1/D2
  (docs/expressionRecon.md, ruled 2026-10-06; the accumulator road live since SEQ 355). The disagreement Tony found is the
  order, not a bug in either.
- **The tiers (D3):** assignment, then `&&` / `||`, then comparison, then the arithmetic fold, loosest first. The tier is
  data in incant/setup (`assignTier`, `compareTier`); `-=` is assignTier (setup:138).
- **Where tester's direction lives:** `xpListTest` starts at `*lizted.lasT` and `getInstruction` walks back with
  `prioR`, so each new instruction wraps the result so far as its RIGHT operand. Left to right starts at the first item
  and walks forward; the result so far becomes the next operator's TARGET. `resultPark` and getTarget's "leading edge of
  a chain" check exist because the chain hangs off the right; a left fold may not need them.
- **The cost of going left to right:** right to left gets assignment last for free (the leftmost operator is applied
  last). Left to right must hold an `assignTier` operator and its target until the rest folds, then apply it.

## The oracle

`incant/pop/exprPinT` (pinned in genLadder/pop.sh) gives a trunk answer per expression; tester's own dead region already
lists harder expressions against it. Row A3 is `qa - qb + qc`.

## Two edges measured on the way

- **`wi = mx -= qa - qb + qc`** (two assignment-tier operators in one expression) reads mx 11, wi 12 on the old parse:
  it splits at the leftmost assignment and folds the `-=` as arithmetic, `wi = ((mx -= qa) - qb) + qc`. `a = b = c` is
  HPDL (R4) -- unruled, and silent today.
- **`L +% *hA *hB *hC`** refuses (`Operator * -- cannot apply to these operands`: the second `*` reads as multiply), and
  `L +% *hA ,*hB ,*hC` does not parse. This is why tester parks operands in instructEntry / targetEntry / resultPark.
  TODO.md (Housekeeping) carries it as a language ruling owed after the jitter docket.
