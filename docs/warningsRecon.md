# Overwritten entries and named warnings: recon (SEQ 743, 2026-11-22)

Clay's dispatch of 2026-11-22, Tony's direction, assess first: reports and documents only; nothing built. Measured in
**kant** on trunk after the pour-stage2 buy (`01b83715`), bare build 2026-11-22. The census used a temporary tap in
`aCTionTraiT` (two lines, logging to a file named by an environment variable), run under every checklist instrument and
tester, then removed by hand: `ruleActions.rtn` restored by md5, the bare retok left git clean, the binary rebuilt.

**The short answer.** The dangerous overwrite is not the one the direction describes. Within one registry, redefining a
name with different text almost never happens (no text-valued case in the whole fleet). What bit colorList was a define
under one registry writing **another registry's** entry, and kant already has a guard meant to stop exactly that; its
test for "is this another registry" misses most registries. Fix that test first. Then A2 (always warn, own names only)
costs nothing today, and where-defined is one property a definition.

## 1. Who overwrites today

**Where an overwrite happens.** Not in `aCTionDefinE`. By the time it runs the entry already holds the new value. The
write is in `aCTionTraiT` (`ruleActions.rtn:1167`), the line `trait.setContent(TraiTdata)`: `trait` is whatever the name
located on the search list, and the value is written onto it. Old and new are both in hand only there, so that is where a
guard that names both texts has to sit.

**The census** (every `name=value` that landed on a field already holding a value; pop.sh, formsPop, jitLadder,
printPop, decodePop, ddPop and tester; 246,026 writes):

| what was written | count | reading |
|---|---|---|
| an **attribute** inside a definition, landing on a `cOMMANDs` entry | 223,401 | **by design.** `operateMethod=` (112,372), `ruleMethod=` (91,155), `jitEmitter=` (19,819), `immediateAction=` (48) are attributes that ARE commands: the value is written onto the command's own entry and the command reads it there (bear-trap 7). A guard on attributes would warn on every operator in setup. |
| other attributes | 22,376 | 22,285 rewrote the same value; 91 differed, all in fixtures built to do it (`name` in IfElseShapeT 81 times, `dfShared`, `red` in StylesT, the fixit `defineAttrWritesField`) |
| a **definition's own name**, same value | 205 | a reload (section 2): `openBrace` and `closeBrace` in Utilities 144 of them |
| a definition's own name, **different value** | **11** | seven names: `qa` (fixtures BridgeT, TopLevelT: counts re-set on purpose); `ShortcuT`, `ANYstring`, `followedBy` (Grokking: grammar entries redefined, sets and groups); `notInNameSet`, `hexSet` (pROPERTIEs: sets). **None is text.** |
| `:=` onto a field already holding something | 33 | `listenTo:=` on its `cOMMANDs` entry (26, by design); a fixture's look placeholders (7) |

**Tester alone** (`Start(); show(colorList);`): 101 writes, all attributes on `cOMMANDs` entries; no definition's own
name overwritten at all.

**So A2 ("every overwrite warns"), taken literally, would print 223,000 lines a fleet run.** Restricted to a
**definition's own name whose value differs**, it would print on seven names across the whole fleet, none of them in an
ordinary run, and none of them text.

## 2. What a reload looks like

One session: `show(colorList)` twice, then `include(styles)` again, then the form's file included again.

- **A second `show` reads nothing again:** one "deferred" line, two draws. The form is defined, so show draws it.
- **A second `include(styles)` rewrote cOLOr's 14 entries, each with the value it already had.** An include always
  reads its file; nothing remembers that it was read. (`loadedFiles` is show's own list and guards only show's files.)
- **The form's file included again rewrote its 14 dESCRIPTIONs entries, same text.**

So "same name, same value" is what every reload looks like, and it must stay silent. All 205 same-value cases in the
census are this.

## 3. The guard that already exists, and why it missed colorList

`traitOwnsValue` (`ruleActions.rtn`, SEQ 457): when a definition's own name resolves to an entry of **another**
registry and a value arrives with it, the definition gets a node of its own and the original is left alone. That is
exactly colorList's case: `black="the darkest..."` under `cOLOrdESCRIPTIONs`, with `cOLOr` on the search list.

Measured on that case, the guard's four conditions read:

| condition | reads |
|---|---|
| a value arrives | yes |
| the entry's home is not the current registry | yes (home cOLOr, current the new registry) |
| **the home is a registry** | **no** |
| the name is the definition's own (not an attribute) | yes |

The third is tested as "the home is the `registries` field, or the home's parent is". **cOLOr's parent is not
`registries`** (measured: 0), so the guard reads cOLOr as not a registry and steps aside. The define then writes cOLOr's
black and lists that same entry in the new registry too: after it, **both** registries read the new text (measured four
ways: `registry(...)` and `register(...)`, with a later define, and twice over).

**A registry knows it is one:** `binType` is `isREGISTRY` (`GroupBody.twk:59`; set by `makeRegistry` and
`getRegistry`, `GroupControl.twk:66`). Asking the home that, instead of asking who its parent is, makes the guard see
every registry. Then colorList needs no search-reset lines, the descriptions get their own entries, and nothing is
overwritten, so there is nothing to warn about. **This is the smallest stroke with the largest effect.** Its reach in
the fleet, to be re-measured when built: the census holds four cross-registry own-name writes today (`lkHas`, a fixture
redefining Utilities' field under its own registry, twice; `followedBy`, whose home has no tag, twice).

## 4. Registry flags (for A1)

A registry is a field with `binType` `isREGISTRY`. It can carry attributes and properties like any field
(`properties.method`, the rule registries' `isRule`). Flags on the body are a fixed set (`GroupBody.twk`, `bools`), and
adding one is a layout change (bear-trap 10: `groups.ext`, a full `tokall`). So A1's cheap spelling is not a new flag
but an attribute or property on the registry, written once where the registry is made, for instance in setup:

```
registry(dESCRIPTIONs);
dESCRIPTIONs +% warnsOnOverwrite;      (a noPrint marker defined in pROPERTIEs, the :. refusal's own advice)
```

read by the guard as "does the home registry carry it". **But section 1 says A1 is not needed:** warning on every
own-name overwrite with a different value is already quiet.

## 5. Where an entry was defined

**Not recorded.** `GroupBody` has no file or line field, and no definition adds a property saying where it came from.

**What is in hand when a definition runs:** `ruler.sourceFILE`, the input field being read, whose Buffer holds its file's
name (`Commands.rtn` getFile: `buffer.setFile(fileName)`); and `ruler.sourceLINE`, the parser's line in that input,
saved and restored as inputs are pushed and popped (`GroupRules.twk:268`, `:338`).

**What recording costs:** one property on the entry (`definedAt`: the file's name and the line), added in `aCTionDefinE`
where the new entry is known. A property, so no layout change, no `groups.ext` line and no retok of the tree
(properties have had their own list since the object-model work). One small node a definition.

Three things to know:
- **The line is where the definition ENDS.** `sourceLINE` is the parser's position, and the action runs when the entry's
  `;` is read. For a one-line entry that is the entry's line; for a form it is its last line. (`refuse`'s own comment,
  `GroupActions.rtn:905`, warns the number is the parser's, not a statement's.) Capturing it when the name is read
  would give the first line.
- **Text that is not a file has no file:** an entry defined from a string (`list("...")`, a driven message) would read
  as text, with a line inside that text.
- **Kant can read a property:** `=<` is `opGetProperty` (`incant/setup:175`, `Instruct.rtn`), the read beside `+<`, the
  add. So a poured row can read `definedAt` with no new accessor. Not run here; the spelling is to be measured when built.

With it, the overwrite warning can name both places, and pour's derived row can show it as a fourth cell.

## 6. Warnings today

**How they print.** Three ways, none of them through one door:

| kind | sites | how |
|---|---|---|
| refusals | 130 calls of `refuse(...)` in C++ | **one function** (`GroupActions.rtn:908`): `REFUSED name -- why [line N]` on stderr; it also arms the statement so nothing is stored |
| literal `WARNING` / `ERROR` / `REFUS` lines in C++ | 11 / 28 / 54 source lines | `cerr` or `fprintf(stderr, ...)` written at the site (159 `cerr` lines and 151 `fprintf(stderr` lines in all; most of the rest are traces and the `measure*` witnesses) |
| kant's own | 36 `cerr` lines in `incant/utilities` and `incant/setup`: 7 WARNING, 25 REFUSING | plain `cerr` in the action |

**What tester prints on every run today:** 16 lines, all one warning:
`WARNING compare: number Token [0] against string direct [across] ...` (`GroupItem.twk:2181`), 14 for across and 2 for
down. The cause is one line of kant: `fillDownAcross` compares the direction's value, a count, with the string `"*"`
(`if direct == "*";`). Comparing as strings there cures all 16 with no switch at all.
The other line named in the dispatch, `nextGroup: ERROR <field> does not contain a list` (`GroupItem.twk:1283`, `:1479`),
is printed twice a layout for every text field with no attribute; `mergeStyles` and `resolveLook` walk a field with no
list. Tester's colorList has no such field today, so it does not print there. The cure is a guard in those two walks.

**What a name and an on/off costs.** `refuse` is one door, so every refusal could be named in one place; but a refusal
is not a warning: it changes what the statement does, and fleet rows pin both the message and the effect. The literal
warnings are few (11 lines in C++, 7 in kant). A registry `wARNINGs` in setup, one entry a warning holding 1 or 0, and
one helper each side (`warns("compareKinds")` in C++, the same lookup in kant) is small: the registry, the helper, and
one `if` at each of 18 sites.

## 7. The lean

1. **Fix `traitOwnsValue`'s registry test first** (section 3). It removes the overwrite that actually happened, with no
   warning to design. One line of C++ and a fleet run; colorList's two search lines then become unnecessary (and a row
   can say so).
2. **A2, not A1, and narrowed:** warn when a **definition's own name** lands on an entry of the **same registry** that
   holds a **different value**; never on attributes; same value silent. The census says this is quiet today, so it needs
   no flag and no switch to be livable. **Overwrite, not keep-first:** the eleven cases in the fleet redefine on
   purpose (a fixture re-setting a count, the grammar replacing an entry), and keep-first would change what they do.
3. **Where-defined as a property** (section 5), so the warning names both places and the sampler can show it. It comes
   before the warning, since the warning wants it.
4. **B, smallest first stroke:** cure tester's 16 lines at their cause (one kant line), and the no-list line by its two
   guards. Then the `wARNINGs` registry with the two compare warnings and the literal kant warnings in it, each on by
   default, plus one all-on / all-off entry. **Refusals stay out of it:** they are not noise to be switched off, and the
   fleet runs with everything on. The sampler's Warnings page is then one more pour: `pour:=wARNINGs`, the show-me the
   entry's 1 or 0, the click writing it.

## 8. Not measured

- The reach of the `traitOwnsValue` fix beyond the four cross-registry writes named in section 3: a fleet run on the
  fixed build is the measurement.
- How many definitions a run makes (the count of `definedAt` properties): not counted; setup and utilities define
  on the order of thousands.
- `=<` reading a property from an action body: read in setup and Instruct.rtn, not run.
- Which of the eleven different-value redefinitions belong to which fixture beyond the registry names the tap logged.
