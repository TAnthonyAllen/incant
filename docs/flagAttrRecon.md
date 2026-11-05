# aCTionDefinE flag attributes (Tony, SEQ 533 R1; recon and stroke 2026-11-05)

RULED: an attribute whose name is a GroupFields flag goes through setGroupField on NewGroup and is not added, as a noPrint immediate attribute is not. processFlags stays; commands whose names differ or do more than set a flag keep their commands. Its own stroke, never with := or defineCapture B2.

## Which of setup's 15 processFlags commands are covered: NONE
A GroupFields name ends in a capital (`incant/setup`: "to avoid overlaps"), so no command name matches one. The nearest flag, and why each stays a command:

| command | nearest GroupFields name | write case? | why it keeps its command |
|---|---|---|---|
| virtual | isVirtuaL (25) | yes | name differs |
| merge | mergeON (26) | yes | name differs |
| isList | isLisT (32) | yes | name differs |
| unary | isUnarY (45) | no | name differs |
| condition | isConditioN (no number) | no | name differs |
| index | isIndexeD (no number) | no | name differs |
| macro | isMacrO (no number) | no | name differs |
| bin | isBiN (33) | yes | name differs; also sets a guard |
| isRule | isRulE (23) | no | name differs; also mints rStuff |
| TOKENize | none | - | sets tokened |
| BLOCKing | none | - | fires only with its guard |
| defer | none | - | sets deferred |
| fail | none | - | sets notifyFail |
| sort | none | - | reads a direction |
| exit | none | - | exits |

So no command in setup can be cut by this stroke. To retire one, its uses would have to be respelled (`virtual` -> `isVirtuaL`); nothing here does that and nothing here is ruled to.

## Who spells a flag name as an attribute today: NOBODY
A tap in aCTionDefinE printed every attribute whose name is a GroupFields entry. Positive control: a planted file fired it 8 of 8. Population: every file in incant/pop and incant (242) and every tracked file in IncantForms, XML and Tests (174), run alone, 0 hits. A file that needs another's preamble stops early when run alone, so the second population is weaker; the fleet's own fixtures carry their preambles.

## What such an attribute did (trunk binary, same fixture)
The flag stayed off and a copy of the registry entry was added: `faA noPrinT` read noPrint 0, attrs 1.

## FOUND, A DEFECT, NOT CURED (value-capture, incant/fixits/defineCapture): `noPrinT=0` writes the table
aCTionTraiT writes the value onto the trait, and the trait IS the GroupFields entry. So gCount, the field number, becomes 0, and every later read of noPrinT in the run says `access to noPrinT not supported yet`. Pinned as FA-9. Left alone because this stroke rides nothing from defineCapture. No file in the census spells it.

## BUILT
`flagAttribute(host,item)` (ruleActions.rtn), called as the second arm of aCTionDefinE's attribute loop. It asks groupFields by the attribute's name and calls setGroupField with 1; a yes means set and not added.
- lastIndenT (411) and processingCodE (412) have setGroupField cases but are not flags, so they keep the ordinary path.
- A flag name with no write case (isRulE, isLocaL, hasMemberS and the rest) keeps the ordinary path: flag off, attribute added, silently (FA-6). The same name under `:.` warns. Worth a word from Tony; not ruled.
- `isBiN` writes the kind only, with no guard, as `x :. isBiN` does. The `bin` command sets one too.
- opDot has no read case for isVirtuaL, mergeON or byReF, so FA-5 asserts only that they were not added.
