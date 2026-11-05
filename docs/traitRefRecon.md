# TraiTdata: what a define's attribute holds, and what `:=` in a define would cost (SEQ 530, 2026-11-04)

RULED (Tony, SEQ 533 R0, 2026-11-04): `:=` in a define is first on the morning docket, for onClick, ahead of the parked listener; its own rule, its own `:=`, refused in a rule host. BUILT below.

Below "BUILT" is the recon as of 2026-11-04: the trial ran in a clone, and its pin is `incant/pop/traitGridT`, 24 rows.

## BUILT, SEQ 534 (Tony's rulings, 2026-11-05; bought, merge 294d2087)
R1: a form attribute that means a field is spelled `:=` (`fill:=wall`, `onClick:=`). Plain `=` stays a value copy. R2: no respell and no census; each form changes on a forms afternoon when it comes up for repair. R3: proved on its own fixture, `incant/pop/defineRefT`; no forms file touched; the temporary `locate(input)` in listenTo reverted. R4: listening stays parked.
- **Why the trial's action did not fire: NOT RECOVERED.** The trial's clone is gone. A fresh build with the same shape (one new literal, TraiTref a term of TraiT, a marker in the action) fired on the first run. The only thing the old table is good for is "the attribute reads kind 0", which follows anyway: aCTionTraiT never read TraiTref in the trial.
- Grammar: `BindOp` (the literal `:=`, beside ColoN and EquaL); `TraiTref  BindOp- GrouP`; `TraiT  GrouP Modifier* TraiTref? TraiTdata?` (GroupMain.twk).
- aCTionTraiTref locates the name now and holds the field. A name that does not locate refuses by name, so a forward reference refuses too. RULED (Tony, 2026-11-05): it stays a loud refusal until a form needs one.
- aCTionTraiT copies the held field to the trait and leaves a noPrint `traitRef` property; traitRefMarks, called from aCTionDefinE where the host is known, spends every mark and refuses in a rule host. No GroupBody bit, no layout change.
- A held action fires with `fire := **h; *fire();`. Bare `fire();` on that holder does nothing and says nothing (context, measured once).
- H7 (fix committed first; single fixture under an alarm; `.mm` md5 identical after restore): the action hands a value copy -> DR-1, DR-3 read kind 5; the rule-host arm off -> 0 refusals and the rule host stands; listenTo back to locate -> DR-7 reads 2 and DR-8 reads 0.
- Fleet: 2505 -> 2521 green (DR's 16 rows), FAIL rows identical by name. Re-pins, sentences in pop.sh: TF-1 85 -> 87, TF-2/3/4 47 -> 48, TF-6 38 -> 39, bare-master 6 -> 7, AO-1 32 -> 33, IT / IB / LB 262 -> 265, parserCoverage.target (BindOp NOBODY, TraiTref COMPILES). traitGridT's 24 did not move.

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
