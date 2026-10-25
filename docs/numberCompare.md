# Number compare -- SEQ 417 (V1 of docs/gen26Recon.md), 2026-10-25

**R0 (Tony): a number compare compares the values.** `compareValues` (GroupItem.twk) is the interpreted compare behind
all six compare operators (`==` `!=` `<` `<=` `>` `>=`, Instruct.rtn:419-744, its only callers). The jitted road
compares doubles (`jitEmitCompare`) and is untouched.

## R1 -- why `1 < 1.5` read 1 (measured, lldb on opLT / compareValues)

A second path. With a COUNT on the left (kind 5), compareValues takes its count arm, `count - group2.count`, and a
NUMBER's `getCount()` rounds half up (`floor(x + 0.5)`, GroupItem.twk:862): 1.5 -> 2, so 1 - 2 = -1 and `<` reads
true. Right by the rounding. lldb: target kind 5 gCount 1, argument kind 9 gNumber 1.5, compareValues returned -1.
Predictions from it, all read: `1 < 1.4` 0 (truth 1), `2 > 1.5` 0 (truth 1), `1 == 1.4` 1 (truth 0).
The text/token arm (`case isBUFFER/isSTRING/isTOKEN`) reads a right-hand number through the same getCount.
**The cure covers all three arms:** when either side is a NUMBER, both sides are read through `getNumber()` (a count
as itself, a string or token as its count, SEQ 347 R3) and compared as doubles, three-way.

## Pre-registered movers (census before the cure)

The census was a temporary tap in compareValues (since reverted; md5 back to HEAD's): it computed the cure's answer
next to the old one and logged every compare whose sign differed, by fixture. H16: on a scratch repro it logged the
seven known-wrong compares and none of the known-right ones (0.5<1.6, 1<1.5, 1<2). It ran under pop.sh, jitLadder,
printPop, decodePop, ddPop, frontier and gen26. **Population: every fixture those instruments run.** Logged: halfLessT
and jitArgNumberT, nothing else.

| row | today | after | sentence |
|---|---|---|---|
| pop.sh halfLessT HL old road | 0 1 0 0 | **1 1 0 1** | 0.5 < 1 and 1.5 < 2 now compare the values; the intended value since 2026-10-19 |
| pop.sh halfLessT HL new road | 0 1 0 0 | **1 1 0 1** | same, on the new parse road |
| pop.sh jitArgNumberT NM interpreted | 10 5 0 5 | **9 5 0 4** | nmF(0.5) now meets `argument < 1`, so the recursion stops at depth 4, not 5; r is count-kind and rounds at each step: 0, 2 (0+1.5), 5 (2+2.5), 9 (5+3.5) |
| pop.sh numCompareT NC interpreted (new, born red) | 0 0 1 1 1 0 1 0 1 1 | **1 1 0 0 0 1 1 1 0 1** | = the jitted row |
| gen26 halfLessT | DISAGREE | **agree** (16 / 26) | the plain road now matches the jitted one |

The halfLessT row's `1<0.5` compare changes sign (0 -> 1) but `<` reads false either way, so it does not move.
jitArgNumberT's jitted row (193 5 1 51) does not move; its label's "intended: 10 5 0 5" becomes 9 5 0 4, the
interpreted twin it names.

## Cure and certificate (689458ff)

Every mover above moved to its registered value and nothing else moved: pop.sh 1757, jitLadder identical, printPop
PASSED, decodePop = capture but the binary line, ddPop 5 / 1 (designDocs md5 line only), dirCheck PASSED, frontier =
capture, canary 373, bare tokall moved GroupItem.mm only. gen26 16 / 26 (`results/gen26.seq417.txt`).

**H7, one variable at a time** (each rebuilt, numCompareT run alone):

| restored alone | NC interpreted | what went red |
|---|---|---|
| none (the cure) | 1 1 0 0 0 1 1 1 0 1 | -- |
| the number arm's `(int)(a - b)` | 0 0 1 1 1 0 1 1 0 1 | columns 1-6; halfLessT back to 0 1 0 0 |
| the count arm's getCount read of a number | 1 1 0 0 0 1 1 0 1 1 | columns 8-9 (1<1.4, 1>=1.4); column 7 (1<1.5) stays 1, right by the rounding (R1) |

Restored from the commit; md5 = the cure.
