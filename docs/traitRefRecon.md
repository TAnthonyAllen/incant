# TraiTdata: what a define's attribute holds, and what `:=` in a define would cost (SEQ 530, 2026-11-04)

Recon only. Nothing here is on trunk except the pin, `incant/pop/traitGridT` and its 24 rows. The trial below ran in a clone.

## Today, on both roads (fleet: traitGridT)
| row | define sits in | name points at | modifier | kind | list | value |
|---|---|---|---|---|---|---|
| G1 | rule | a rule | + | 0 | 1 | child copy of the rule |
| G2 | rule | a rule | none | 0 | 1 | child copy of the rule |
| G3 | rule | a plain field | + | 6 | 0 | a copy of the field (same body) |
| G4 | rule | a plain field | none | 13 | 0 | the field's name, as text |
| G5 | action | a rule | none | 6 | 0 | the rule itself |
| G6 | action | a plain field | none | 13 | 0 | the field's name, as text |
| G7 | action | a plain field holding 10 | none | 5 | 0 | 10 |
| G8 | action | a plain field holding members | none | 0 | 2 | a copy of the list |
| G9 | action | a plain field | + | 6 | 0 | the field itself |

At the end of aCTionTraiT, G1 and G2 are still kind 6, group the rule. The test is ruleActions.rtn:1155 (isRuleTerm).
History: 36 of 41 swept trunk commits built, 2026-06-25 to today, and the plain-field rows never change. The first
commit's source tests the same thing. Nothing older than 06-25 was built, so there is nothing to revert.

## `+` writes the other field
`field=other+` sets isRule on `other` (gP3, gP9 read 1; gP4, gTen read 0). Already on the ledger: incant/fixits/defineCapture,
section 3. It also writes affiliation on the original, and hands a copy instead if `other` already has rStuff (read, not run).

## embedAttribute
ruleActions.rtn:415-416 runs it on attributes only `if isRule && groupList`. In an action host it never runs on an attribute,
so G5 and G9 hold the target field itself (field identity read in the clone: same field, same body). In a rule host: a listed
rule becomes a child copy (G1, G2), and a plain field stamped by `+` becomes a copy through embedRule (G3: same body, new field).

## `:=` census
0 in define text; 695 in code bodies and 19 at top level; 480 files under incant/ and IncantForms/, dead regions and prose
stripped. Positive control: a planted `h b:=a;` counted 1, one in a body and one at top level counted apart, one below stop() not at all.

## The clone trial
incant/grammar's TraiTdata and TraiT lines are inert mirrors (editing one changed nothing). The sites are GroupMain.twk:292
(TraiTdata) and :332 (TraiT's terms).
| shape | result |
|---|---|
| optional `:` first in TraiTdata, branch at 1155 | setup abandoned, exit 139 at bootstrapper setBuffer |
| the same, TraiTdata unGuarded | the same |
| new rule TraiTref, opening with ColoN and EquaL, a term of TraiT | the same |
| TraiTref defined, not a term of TraiT (control) | setup lives; `:=` does not parse |
| TraiTref opening with one new literal `:=`, a term of TraiT | setup lives, `:=` parses, target isRule stays 0 |

Last row: aCTionTraiTref does not fire and the attribute reads kind 0 even with its groups.ext line. NOT SOLVED. Causes of the
crashes not isolated beyond the one-variable step from ColoN to a new literal.

## What the term moves (last row's binary against the clone's baseline)
pop.sh 2505 -> 2493 green, 12 FAIL rows added, all grammar censuses: actorOrderT AO-1 (32 -> 33); itBackRT IB-1 x2, itRT IT-1
x2, jitCursorLifeT LB-1 and its twin (262 -> 265); parserCoverage.target; traitFlagsT TF-1 to TF-4. No traitGridT row moved.
jitLadder, printPop, decodePop, ddPop: no row moved (only the binary echo differs).
