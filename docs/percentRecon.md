# The %: width=50% on the road to setFrame (SEQ 551, recon only, 2026-11-06)

**Plain line: nothing is built. The % is lost twice before setFrame can use it, the fix fits in one existing bit with two write sites, and the frame row cannot go green until Tony's setFrame draft is in utilities.**

Measured in **kant**, bare binary, merged trunk 54287f99 (2026-11-06). Written tok lines are tok. Probes: docs/percentProbes (scratch, not fleet). Ruling in force, SEQ 538 via SEQ 551 R0: a % after a value is a unit on that value and travels through every value copy.

## R1. Today's path
| step | where | what happens |
|---|---|---|
| grammar | incant/grammar:59, GroupMain.twk | `TraiTdata '='- DatA Modifier*`: the % is a Modifier on TraiTdata |
| hand-up | ruleActions.rtn aCTionTraiT, `upFlags = TraiTdata["Modifier"]` | the value's modifiers reach the trait as upFlags |
| value | same, `trait.setContent(TraiTdata)` | the count 50, modifier stripped |
| **LOSS 1** | same, `modifyClass(trait,upFlags.text,0)`, then GroupActions.rtn:583 `case '%': modPercent = true` | written to the instance's rStuff, not the body |
| **LOSS 2** | incant/utilities:253, :263 `width.isPercent` | a lookup of an attribute named isPercent, so false. The flag's spelling is isPercenT |

- **modPercent has no reader.** Grep of every .twk and .rtn: one write, one declaration, and measure.twk's witness. omModT OM-2 pins it.
- **The body bit isPercent is read by:** opDot case 21 (Instruct.rtn:393), and getText (GroupItem.twk:1046, appends %).
- **CORRECTION to macros and forms:** they say `.isPercenT` answers "not supported yet". Today it reads 1 on a field with the bit set, including under the JIT. The body bit's only kant writer is `:. isPercenT` (Instruct.rtn:1567), used at utilities:377, 387, 398, 423, 432.
- **The tester draft has no percent read at all**, so with it the second loss is simply absent code.

**The window:** seal 346's 06-27 to 09-04 still holds, and reading narrows it to one candidate. **6212a711, 2026-08-16** ("Tony's offline work") changed aCTionTraiTdata's `if isRule ...` to `if (isRule && !isLiteral) ...`. Before, a literal with a modifier was held by group and kept its bit. After, it goes through setContent, and copyData does not carry the bit. copyData is byte-identical at 33206bb6 and 14044dcc. READ, NOT RUN: no build of 6212a711 or its parent. f7e0f499 (09-28) moved `%` to modPercent later, so it is not the loss. The sealed note's 09-04 "bit read 0" agrees.

## R2. The copy roads
Bit set with `:. isPercenT`, then read through each road (pctRoads). Control pair: source 1, unset field 0. Reads through a holder need `*h.isPercenT`; `:=` and copyOf read 1 only that way, which is the anti-vacuity row for the spelling.

| road | carries today | mechanism | with the unit on the value |
|---|---|---|---|
| `=` into a new local | **DROPS** | setContent, copyData | **cure at copyData** |
| `=` into same kind | **DROPS** | setContent, copyData | same cure |
| `=` into an empty field | **DROPS** | setContent, copyData | same cure |
| `=` into another kind | **DROPS** | castStore, never copyData (Instruct.rtn:46) | **second write site** |
| `=` copy of an argument | **DROPS** | copyData | copyData |
| `=:` value scope | **DROPS** | aCTionScopeValue, copyData | copyData |
| define's TraiTdata | **DROPS** | trait.setContent, and never written (loss 1) | loss 1's cure, then copyData |
| setContent on a list | n/a | copyListFrom shares or copies each entry's body | carries |
| `:=` hold | carries | the holder reaches the same body | carries |
| `<-` hold | carries | same | carries |
| `:` scope | carries, through | bare reads the holder: 0; `*width` reads 1 | **a reader must star** |
| copyOf | carries | copies the body whole | carries |
| `+%` of a copy or a field | carries, through | entry 0, `*entry` 1 | carries |
| argument binding | carries | the carrier shares the body | carries |
| copy constructor, new GroupItem(x) | carries | shares the body (GroupItem.twk) | carries |

Not copies, but the stroke has to say what they do:
- **Sticky:** `w :. isPercenT; w = 60;` reads bit 1, value 60. copyData leaves the bit alone today. If it assigns the bit (`isPercent = item.isPercent`), a plain write clears it, which is what a unit on the value means. castStore needs the same.
- **Arithmetic:** a product is a new value, bit 0 (`src * 2` reads 100). Reading: correct, not a copy.
- **`new(field)`** mints by tag, no value; not a road.
- **`w = 50%;` in a body:** value 50, bit 0, no refusal. The % is silently swallowed. **Open: R0 says a value's unit; no spelling in a body carries it, and no form needs one.**
- **Text:** a percent's text is `50%` (dumpContents; castStore into a string gives `50%`). A compare or a reader by text sees the %.
- **Print:** `print` and printDefinition show 50 with the bit set, dumpContents shows 50%. So goldenDrift's `width=50%` line will not come back from this stroke alone; printDefinition's rewrite owns it.

## R3. The split
Position separates them in the grammar and in the action. `TraiT NamE Modifier* TraiTdata?` against `TraiTdata '='- DatA Modifier*`: aCTionTraiT holds them as two nodes, `Modifier` and `upFlags`. So `OmA%`, `width%=50` stay modify's modPercent (OM-2 pins it, body pct 0), and only `upFlags` writes the bit.

**One case position does not separate:** a value-position % in a RULE host, `term=5%`. ffa850fe made a value's + and * real rule-term modifiers, so that position is live in rules, and aCTionTraiT does not know its host. Written to the bit, its text reads `5%`, so a literal term would match `5%`. Census of incant/grammar, kantGrammar, grammar, setup, directives: **zero**. Options: refuse it, as traitRefMarks refuses `:=` in a rule host, from aCTionDefinE where the host is known (recommended), or leave it.

**A related hazard, not new:** a named trait resolved to a searched field writes through (defineCapture, ST-5). `x width=50%` with a searched `width` would set the bit on that field's body, as `=` already writes its value. modPercent on the instance could not. Same family, no worse.

Not measured: `width=50 %` with a space. It parses and prints 50; modPercent cannot be read from kant, so which node took it is unknown.

## R4. The readers
**setFrame (tester draft, Tony's; utilities' copy is older):** `=:grup width height;` then the count. With copyData cured, bare `width.isPercenT` reads 1, because `=:` gives a value and no holder. utilities' `:grup width height` would need `*width.isPercenT`. The draft needs one line per dimension.

**Tony's call, three questions the draft raises:**
1. **Percent of what?** utilities:253 uses `sideRoom`, which shrinks as siblings are taken, so 50% then 25% of 200 gives 100 then 25. `pWidth` gives 100 then 50. The ruling's 100 row holds either way; the second child does not.
2. **Resize:** a computed width written over the declared one loses 50%, and `forms:150` says a resize re-runs setFrame. The draft writes with `*grup :% copyOf(width)`, so a second run sees 100.
3. **Cross-axis:** whether a percent height counts toward headRoom the same way.

**fillDownAcross:** `pValue -= target` and `pValue / target` treat target's count as absolute, so 50% reads as 50. It is not percent-aware, and copyOf carries the bit onto the copies. `direct="*"` with a percent member is wrong until it reads the bit.

**The JIT:** nothing jits setFrame or fillDownAcross (grep of incant and WorkingOn; both run interpreted on the old road). Measured on an old-road action through testing(), interpreted statements under the hood:
- `src.isPercenT` reads 1, 4 degrades; `*h.isPercenT` reads 1, 6 degrades: each statement runs at run time.
- `a1 = src` reads 0, the same drop.
- `=:` hands over at emit ("binds locals, so it runs at RUN time"), and on this probe the action's print did not appear. Not chased.
No emitted store carries the bit, because no JIT path was seen writing it; **jitEmitAssign's count store is the one to check in the stroke**. Its emitted `=` with a node on the right calls setContent (jitEmitters.rtn:54), which would carry after the cure.

## R5. Census by text
% after a value, by form. Numeric every one; **19 uses, width 16, height 3**. Dead = below bail() or stop().
| file | live | dead | note |
|---|---|---|---|
| IncantForms/Windows/sheet | 4 | 0 | |
| IncantForms/Windows/inspector | 2 | 0 | no stop or bail in file |
| IncantForms/Windows/layout | 2 | 0 | no stop or bail in file |
| IncantForms/Windows/wraplist | 2 | 0 | XML-era, does not parse (forms:314) |
| IncantForms/Windows/simple | 1 | 0 | |
| IncantForms/Windows/firstLight | 0 | 1 | prose below bail() |
| IncantForms/BackupXML/unitTests | 1 | 0 | backup, not run |
| IncantForms/WorkingOn/forms | 4 | 0 | notes, never run |
| IncantForms/WorkingOn/macros | 2 | 0 | notes, never run |

So **11 uses in forms**, 8 of them in notes or a backup or dead text. Outside IncantForms: incant/unitTests:105 (`sample`). `incant/pop/baselineTests.golden:72` pins that line.

## R6. The proposed certificate
**Rows, born red on trunk, by value (fixture name a placeholder, percentT):**
- Define: `width=50%` bit 1, value 50; `width=50` bit 0 (sibling).
- Frame: `width=50%` under a 200-wide parent reads 100. **Today setFrame is refused before it frames a child (memberCount, sideRoom), so this row reads no width, not 50.** It cannot go green until Tony's draft is in utilities, so it needs item 3 first, or the row names the draft.
- Copies, one row per road, bit by value: `=` new local, same kind, empty, other kind (castStore), copy of an argument, `=:`, define. Controls that stay green: `:=`, `<-`, `:` through, copyOf, `+%` of a copy and of a field, argument, the copy constructor.
- Clearing: a plain value over a percent reads bit 0, value 60, both through copyData and castStore.
- Arithmetic: a product reads bit 0 (control).
- Split: OM-2 unmoved; `width%=50` bit 0; `term=5%` in a rule host refuses, if ruled.
- JIT: `=` and a flag read jitted against the interpreted twin.

**H7 halves, fix committed first, single fixture under an alarm:**
1. The write out (aCTionTraiT): define rows and the frame row go red.
2. The carry out of copyData: every `=` road, `=:` and define go red; castStore's stays green, which shows it is a separate site.
3. The carry out of castStore: only that row goes red.
4. Carry made set-only: the clearing rows go red.
5. The reader out of setFrame: the frame row reads 50.
6. `case '%'` in modify writes the bit again: OM-2 goes red, which shows the split is real.

**Bookkeeping:** no GroupBody field is added (isPercent exists), so no layout change and no tokall sweep owed. Canary unmoved unless a helper is added. Bare tokall diff stands. utilities' five `:. isPercenT` sites come alive once setFrame reads the bit; `height = x; height :. isPercenT` sets after the write, so the clearing does not undo them.

## For ruling
1. **Percent of what:** remaining room or the parent's size, in Tony's setFrame.
2. **Resize:** does the declared 50% survive a computed frame?
3. **`term=5%` in a rule host:** refuse (recommended) or leave.
4. **`w = 50%;` in a body:** swallowed silently today. Refuse, carry, or leave.
5. **Order:** the frame row needs the draft in utilities, so item 3 comes before this stroke.
