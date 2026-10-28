# `#` strings -- census for the record (Tony, SEQ 449 R3, 2026-10-28)

**Why it exists.** STRINGXp (`#` followed by print items: `#"row" r`, `#$"bcLabel" labelIndex$`) left kantGrammar's
TOKEn (SEQ 449 R1) and is parked (R2: Tony may bring it back as a statement). This lists where the spelling is used, so
that decision has its population. **No respelling was done or is owed.** The old road's grammar (incant/grammar,
`StringXP` in Token) is untouched, so every use below still parses as before.

**The fact that forced it, measured 2026-10-28 (seal 246):** after an expression, `#` is a STRINGXp on BOTH roads.
The old road prints `print qa #5d:;` as `2 5 d`; a format after an expression does not apply there either in today's
tree (formats worked once, Tony; grammar changes broke them; the date is not measured -- SEQ 450 R2). So the
new road's format rows pin the INTENDED value, not the old road's (R4).

**Population searched, and why it would contain the answer.** Every file under incant/, IncantForms/, XML/,
genLadder/, jitLadder/, minionWork/, Tests/, GUI/ (attic excluded; .md/.mm/.h/.txt/.py excluded), for a `#` in VALUE
position -- after `=`, `:=`, `<-`, `(`, `,`, `[`, `%`, `+`, or `print` / `cerr` / `cout` / `return` / `if`
/ `or` -- followed by a quote, `$`, `_`, `~`, a backtick or a name. A `#` string has to sit where a value goes, so
every use is in that set; a `#` string written as a bare statement or after another shape would be missed. 105 hits,
read by eye: 22 are `#` strings, the rest are not.

## The 22 `#` strings

| file:line | text |
|---|---|
| incant/unitTests:310 | `whatsIt = #"is what" 'I am talking about';` |
| incant/utilities:372 | `bandName = #$"band" r;` |
| incant/utilities:382 | `bigName = #"big" r;` |
| incant/utilities:395 | `colName = #"strip" c;` |
| incant/utilities:403 | `cellName = #"c" cellRow "x" c;` |
| incant/utilities:418 | `rowName = #"row" r;` |
| incant/utilities:427 | `cellName = #"c" r "x" c$;` |
| incant/generate:78 | `labelName = #$"bcLabel" labelIndex$;` |
| incant/generate:81 | `labelName = #$"bcLabel" labelIndex$;` |
| incant/generate:111 | `labelName = #$"bcLabel" labelIndex$;` |
| incant/generate:114 | `labelName = #$"bcLabel" labelIndex$;` |
| incant/generate:153 | `labelName = #$"bcLabel" labelIndex$;` |
| incant/generate:163 | `labelName = #$"bcLabel" labelIndex$;` |
| incant/generate:208 | `labelName = #$"bcLabel" labelIndex$;` |
| incant/generate:211 | `labelName = #$"bcLabel" labelIndex$;` |
| incant/pop/printFamily:105 | `vDef = #"PF-S-U-def" 1 2 3;` |
| incant/pop/printFamily:107 | `vDollar = #$"PF-S-U-dol" "joined"$;` |
| incant/pop/printFamily:109 | `vUnder = #$"PF-S-U-und" _ "spaced"$;` |
| incant/pop/printFamily:125 | `vArmed = #$"PF-S-A-und" _ "spaced"$;` |
| incant/pop/baselineTests:31 | `whatsIt = #"is what" 'I am talking about';          <- is` |
| incant/pop/printFamilyNew:204 | `n1 = #"PN-O-one";` |
| incant/pop/printFamilyNew:206 | `n2 = #"PN-O" "two";` |

- **incant/utilities (6)** and **incant/unitTests (1)** load in every fixture, but BEFORE the search stack switches to
  KantGrammar, so they parse on the old road; R1 does not reach them.
- **incant/generate (8)** is reference only (the bytecode road, retired 2026-10-02).
- **The fleet (7):** incant/pop/baselineTests (1), printFamily (4), printFamilyNew (2) -- all old road.
- **Nothing that loads under KantGrammar uses a `#` string**, which is why the fleet did not move when R1 landed.

## Not `#` strings (the other 83)

- **Hex colours in form attributes, about 60** -- `fill=#d1d1d1`, `<red=#ef2b2d/>` in IncantForms/{Controls,HTML,Tests,
  Windows} and their XML/ twins. A form attribute value; whether STRINGXp or the forms machinery reads it is NOT measured.
- **Prose** -- `# TODO: review`, `# intended:` in comments and dead regions.

## Formats bind in opposite directions on the two roads (Tony, SEQ 451 R1 -- recorded, no sync work now)

- **Old road** (incant/grammar): `PrintField  ExpressioN FormaT?` -- a format applies to the EXPRESSION BEFORE IT.
  `print qa #5d qb:;` formats qa (`    2 3`); a print that starts with a format does not parse. formatTest is written
  this way (`"Formatted" #12s`).
- **New road** (kantGrammar, SEQ 449): a format is an item of its own and sets ITS TYPE's format for the items that
  follow, to the end of the print statement. `print qa #5d qb:;` formats qb (`2     3`).
