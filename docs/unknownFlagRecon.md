# An unknown flag name in a define -- recon (SEQ 544, 2026-11-06). Nothing built.

**The answer: the candidate rule fails, both ways. Twenty-three intended names would refuse, and it cannot catch a capital in the wrong place. A rule that compares a name against the flags does hold: fold or one edit from a flag, lower case first, on a non-rule host, after the commands. In today's tree it fires on one field, `isGROUP` in `IncantForms/Windows/tabs`.**

**How it was measured (kant):** a temporary tap in `flagAttribute`, which every non-command attribute passes, under pop.sh, jitLadder, printPop, decodePop, ddPop, frontier, tester and every tracked live file in incant/ and IncantForms/ (441 files, attic and BackupXML out; 432 exit 0). 397,712 passes, 3,760 distinct sites by registry, host and name. Removed after, md5-identical. **The population is what the runs reached:** six form files exit 2 and formsRecon 138, so they got a text scan for the flag class (one hit, a comment). A command attribute takes the first arm and never reaches the tap, so section 3 reads the commands separately.

## 1. What makes a bare attribute a flag name

Three roads exist today, and they are measured in one define (`a1`..`a10`):

| spelling | road | result today |
|---|---|---|
| `noPrinT` | flagAttribute, GroupFields 29 | sets the flag, no attribute |
| `noPrint`, `isRule` | a command, first arm (isRule by processFlags; noPrint's registration not read) | **sets the flag, no attribute. Not typos.** |
| `isLocal`, `isMacro`, `byRef`, `isBin`, `noprint`, `noPrinX` | ordinary path | **silently an ordinary attribute, flag off** |
| `across` | ordinary path | an ordinary attribute, correctly |

**So the dispatch's example does not hold: `noPrint` for `noPrinT` is not a typo, it works.** The silent ones are the defect. The two bare-spelling populations are also why the accessor spelling cannot be the rule: a command flag has no final capital, and a capital proves nothing either way.

## 2. The census

**Bare attributes matching a GroupFields flag: 9 names, 13 sites, every one in `incant/pop/flagAttrT`.** No form and no other live file uses one. The registry holds 53 entries: 13 flags with a write case (byReF flaG hasNewParsE invokE isActioN isBiN isCodeD isLisT isMacrO isPercenT isVirtuaL mergeON noPrinT); 23 flag-shaped with no write case; 15 accessors, not flags; and lastIndenT and processingCodE, which have write cases but which flagAttribute excludes. Of the 23, **one is used: `isRulE`, FA-6, and it stays silent (SEQ 338).** Six of them carry no number (isConditioN isFilE isIndexeD isInitializeD isPointeR noSkiP).

**Bare, accessor spelling, no entry: 23 names, 24 sites. Every one intended, none a typo.**

| names | where | what |
|---|---|---|
| isANY isBUFFER isCHAR isCOUNT isGROUP isITEM isMAP isNUMBER isOBJECT isREGEX isSET isSTAK isSTRING isTOKEN | Windows/tabs, dataNames | a form listing the data kinds by name |
| controlA controlB | Windows/keyStroke, body | key names |
| isOR | setup, the `\|\|` operator | a marker, read at ruleActions.rtn:2069 |
| fsItemsR (2 sites) | fireSeatT | a fixture's term |
| juiA juiB juiC | jitJUi | a fixture's members |
| leafA leafB | iterT1, iterT1m | a fixture's members |

**Bare, plain spelling, no entry: 537 sites, 183 names** (434 sites and 146 names on a non-rule host, the rest rule terms).

## 3. The rule that holds

Against the settable and flag-shaped entries only (36), never the 15 accessors, so `text`, `first` and `list` are not near anything:

> A bare attribute names a flag it missed when: its host is not a rule; it is no command; it is no GroupFields entry; it starts lower case; and it folds to a flag, or is one edit from one.

Run over every site:

| clause alone | fires on |
|---|---|
| fold | `isGROUP` (tabs) |
| one edit | `flags` (rule hosts FormaT, FORMAt), `InvokeD`, `INVOKEd` (capital first, a rule host) |
| **all clauses** | **`isGROUP` in tabs, and nothing else** |

It catches all six silent ones above. Two commands fold onto entries, `isList` and `isRule`; the first arm takes them before this line, so they are exempt without a list.

## 4. Proposal

**Where:** `flagAttribute`, at its `if !flagDef return 0;` line: the one point a non-command attribute passes, with host and item in hand. **The bootstrap does not matter:** it never passes through aCTionDefinE, and GroupFields is not filled until setup line 264, so nothing above that line is checked and the rule cannot fire there. It costs a walk of the flag class on a miss; 397,712 passes in the whole census.

**What a refusal does there, the part to weigh:** a refusal inside a define trips aCTionDefinE's refusalBoundary, which prints `REMOVED <field> from <registry>`, and **the field is gone**. Loud and by name, as ruled. It does mean one typo in a form loses that whole field, and what reads it then fails on its own.

**What it would refuse today, by name:** `isGROUP` in `IncantForms/Windows/tabs`, field dataNames. Nothing in the fleet.

**The rows, in a fixture of their own:** `isLocal`, `isMacro`, `byRef`, `isBin`, `noprint`, `noPrinX` each refuse by name, naming the flag it was near. Controls that stay: `noPrinT`, `noPrint`, `isRule`, `isList`, `across`; a rule term `flags`; `InvokeD`. A count row over the corpus reading the refusals. H7: the arm out, the six are silent attributes again.

**Two questions this cannot answer, for Tony:**
- **`isGROUP` in tabs.** Respell the form, or add a clause (a run of capitals is not a near miss), which clears tabs, and also stops catching `isLIST`, `isBIN`, a C spelling a kant writer could plausibly reach for. **Leaning respell:** a list of kind names can spell them any way, and the catch is worth more.
- **A flag with no write case, `isRulE`.** SEQ 338 left those silent. This stroke could refuse them too. It moves FA-6, and only that row today, so it is cheap now and is the same defect seen from the other side. **Leaning yes,** as its own ruling.
