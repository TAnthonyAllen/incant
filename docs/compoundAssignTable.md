# What += -= *= /= do, by the target's kind

Measured 2026-11-28 (GO 4, SEQ 805) off `incant/pop/compoundT`, after the cure. **Both roads read the same in every
cell** (the old road on `incant/grammar`; a `newRoad` body on `incant/kantGrammar`), so the table has one value per cell.
It is a record of what the engine does today, not a ruling: it is the starting sheet for Tony's discussion of operators
by data type. Nothing here was changed on the old road.

Marks: **(nothing)** the target is left as it was, silently, no error line. **(rounds)** a count target keeps a count:
the answer is worked in numbers and rounded to the nearest count. **?** looks wrong or at least surprising.

| target, then operand | `+=` | `-=` | `*=` | `/=` |
|---|---|---|---|---|
| count 7, by count 2 | 9 | 5 | 14 | 4 **(rounds: 3.5)** ? |
| count 7, by number 1.5 | 9 **(rounds: 8.5)** | 6 **(rounds: 5.5)** | 11 **(rounds: 10.5)** | 5 **(rounds: 4.67)** |
| number 7.5, by count 2 | 9.5 | 5.5 | 15 | 3.75 |
| number 7.5, by number 1.5 | 9 | 6 | 11.25 | 5 |
| string "ab", by string "cd" | abcd | ab **(nothing)** | ab **(nothing)** | ab **(nothing)** |
| string "ab", by count 2 | ab2 | ab **(nothing)** | ab **(nothing)** | ab **(nothing)** |
| list (a field with two attributes), by count 2 | **(nothing)** ? | **(nothing)** ? | **(nothing)** ? | **(nothing)** ? |

The operand's shape makes no difference (count 12, operand 3 as a name, a call, an expression `caK + 1`): 15, 9, 36, 4.
Closing a while, each of the four ends the loop by itself (0 to 5 by `+= 1`; 5 to 0 by `-= 1`; 1 to 64 by `*= 2`;
64 to 1 by `/= 2`).

## The cells worth a look

- **A count divided by a count rounds**: 7 /= 2 is 4, not 3 (integer division) and not 3.5. The same rounding gives
  7 += 1.5 = 9 and 7 -= 1.5 = 6.
- **A list target: all four do nothing and say nothing.** Not even `+=` adds to it here (the operand was a count).
- **`-=`, `*=`, `/=` on a string do nothing and say nothing.** Only `+=` has per-kind arms (`'+=isCOUNT'` and its kin
  in `incant/setup`); the other three are one method each.
- **Nothing in the 44 cases refuses or prints an error line**, on either road.

## Not measured

A list operand (`x += aList`); a string by a number; a target with no value yet; a buffer or a stack target; a holder
on either side; the jitter (old or kant). `incant/pop/compoundT` is the place to add a case: one body, written twice.

## What was cured (SEQ 805)

Before: in a new-road body `+=` printed `ERROR Operator += failed on x and TOKEn` and left the target as it was, so a
while closed by `+=` never ended. Cause: the new road's runner (`testOP`) did not pick the per-kind member of an operator
that has members, so the method that ran was `opPlusEQ`, which today is only that refusal. Cure: one line in `testOP`,
the same pick (`pickKindOP`) the old road's runner makes. `-=`, `*=` and `/=` have no members and already agreed.
