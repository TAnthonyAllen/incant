# Tabs recon (SEQ 699, 2026-11-18)

Clay's dispatch of 2026-11-18 (afternoon, forms): recon only, documents only. Tabs is the next form to test. Measured on
trunk at seal 509, bare build 2026-11-18 14:10. One probe was run from the scratchpad (a respelled copy of the form,
drawn to a scratch PDF); nothing in the tree was changed but this file and a pointer line in `Topics/forms`.

## 1. The form as it stands

**Where:** `IncantForms/Windows/tabs` (last touched at seal 460, `ede70292`, when its crash was cured). It is NOT a
definitions-only file: it carries its own `Start()`, includes, search line and a driver.

**What it defines:**

| registry | field | what |
|---|---|---|
| dESCRIPTIONs | `tabFORM`, `tabBAR` | two help texts (prose about the old GUI's tabs) |
| FORMs | `tabFORM window closable resize x=400 y=400 width=360 height=400 fill=wall title="Using Tabs"` | the form |
| | `body` > `intro height=50 fill=white bordered` > `heading="Tabs Example" flex center titleFont` | the heading |
| | `body` > `tabBAR height=25 flex headerFont tabs=tabTwo` | the tab bar; `tabs=` names the selected tab |
| | `tabOne=firstCard bordered fill=lightGreen selectFill=green` (and `tabTwo`, `tabThree`) | three tabs; each value names its card |
| | `body` > `bodies cards` > `firstCard="The first tab body" register bordered fill=green` (and two more) | three cards |
| | `body` > `help describe=tabFORM bordered height=100 fill=lightGreen` | the help box |

The driver (`layIt(tabFORMReq)`) calls `setFrame` and nothing else: no PDF.

**What it does today, run as it stands:** exit 0, nothing laid out that anyone sees, and two warnings,
`cOLORs must be a registry` and `fONTs must be a registry` (the search line names `cOLORs`; the registry is `cOLOr`).
The plain-`=` colours and the bare font names are the old GUI's spellings; today a colour or font is named with `:=`.

**What tab switching does today: nothing.** Nothing in the tree reads `tabs`, `cards` or `selectFill`
(`grep -w` in `incant/utilities`, `incant/setup`: 0 hits each). No action, no listener. The probe drew a respelled copy
(the `:=` respells of section 2, `bordered` to `border`, `flex` to `across`, `center` to `align=center valign=center`;
measured, scratch PDF) and showed:

- the three cards stacked down the body, all three drawn (`cards` is ignored; the default direction is down);
- the three tabs drawn alike, in `lightGreen` (`selectFill` is ignored; `tabs=tabTwo` selects nothing);
- each tab's label is its value: `firstCard`, `secondCard`, `thirdCard`. The value does two jobs (the label and the card
  it names), and the label wins;
- the help box shows the word `tabFORM` (its `describe=` value); the `describe` action (utilities) is not fired by a draw.

A window with no `x=` / `y=` refuses in `setFrame` (`REFUSED x -- Operator + -- cannot apply to these operands`) and every
text then reads "does not fit its frame"; with them it lays out cleanly. firstLight carries both, so this matters only
for a respell that drops them.

**Old-GUI leftovers, and where the old meaning lived** (`IncantForms/WorkingOn/formsRecon` 314-325, 461-471;
`formsTable` lines 75, 99, 178). The GUI code below is not in the binary (formsRecon 1159).

| leftover | the old meaning | where |
|---|---|---|
| `tabs=Name` on the bar | picks the selected tab (else the first member); points each tab at its body | `GUI/Map.rtn` `tABS` 1021-1076 |
| `tabOne=firstCard` | the tab's body, looked up by name in the current registry (the old `tabBODY`) | the same |
| `register` on each card | puts the card in the current registry, so `tABS` could find it by name | `currentRegistry[name]` |
| `cards` on `bodies` | members stacked, all `noRoom` but one: `cards=Name`, else the first; each gets the full box | `GUI/Map.rtn` `setCARD` 764-800 |
| `selectFill=` | the selected tab's fill | `tABS`, `swapSelectDecor` |
| the switch | a click on a tab ran `sELECTtab`: deselect the old tab, `noRoom` its body, select the new, set `cards=` | `GUI/Actions.twk` 266-310 |
| `closable resize title=` | window chrome | inert today (descriptions still carries them) |
| `flex`, `center`, `bordered`, bare `titleFont` / `headerFont` | templates and CSS hints | formsTable: drop / respell |

## 2. What it needs to run under show()

Listed, not made.

1. **The form's name.** `show(name)` loads `sTASh[name]` and then draws `FORMs[name]` (`incant/setup`, `show`,
   `showFinish`), so the form must carry the name the stash knows it by, as `descriptions` was renamed from
   `webViewExample`. **`tabs` cannot be that name:** `tabs` is also the bar's attribute (`tabs=tabTwo`), the same collision
   that made `simple` merge into UnitTests' field (firstLight's notes). Proposal: file and form both `tabForm`
   (`git mv IncantForms/Windows/tabs IncantForms/Windows/tabForm`; the dESCRIPTIONs entry `tabFORM` renamed to match, and
   `describe=tabForm`). **Tony's call: the name.**
2. **An entry in `incant/stashList`:** `tabForm;` under `stashNames`, then `genLadder/stash.sh` (which writes
   `incant/stash`; pop.sh's `stash --check` row then holds).
3. **Definitions only**, shaped like firstLight and descriptions: drop `Start()`, `include(unitTests)`,
   `include(utilities)`, `search reset stack Grokking`, the search line and the `layIt` driver; keep the two
   `register(...)` blocks; end with `bail();` and the notes below it.
4. **Its own include of styles: NOT needed, and I'd leave it out.** `show` loads styles itself when they are not loaded
   (`incant/setup`: `if stylesLoaded == 0; include(styles);`) and puts `cOLOr fONTs sTYLEs` on the search list before the
   form file is read (`showStage`). firstLight and descriptions carry no include; descriptions' header says the includer
   loads styles. A fleet fixture that includes the form without `show` includes styles itself, as formsPop's do.
5. **`:=` respells** (a colour or a font is held, not copied):
   `fill=wall` → `fill:=wall`; `fill=white` → `fill:=white`; `fill=lightGreen` (x4) → `fill:=lightGreen`;
   `fill=green|blue|red` (cards) → `fill:=…`; `selectFill=green|blue|red` → `selectFill:=…`;
   bare `titleFont` → `font:=titleFont`; bare `headerFont` → `font:=headerFont`.
6. **Placeholders in place of explicit colours and fonts.** Five exist (`IncantForms/Controls/styles`): `pageFill`,
   `headingFont`, `bodyFont`, `textColor`, `accent`, with `defaultLook` the one look. A map, and what it does not cover:

   | explicit | placeholder |
   |---|---|
   | `titleFont` (heading) | `headingFont` (defaultLook: titleFont) |
   | `headerFont` (the bar) | `bodyFont` is normalFont, not bold: a new role, or accept normalFont |
   | `wall` (the page) | `pageFill` (defaultLook: **white**, so the page changes colour) |
   | `white` (intro) | no role |
   | `lightGreen` (tabs, help) | no role |
   | `green` / `blue` / `red` (cards and their tabs' selectFill) | no role; three colours that pair a tab with its card |

   **Tony's call:** new roles (say `panelFill`, `tabFill`, and one per card), or cards keep explicit colours, as firstLight
   still does (`fill:=wall`, `fill:=lightGreen`). firstLight and descriptions name explicit colours today, so a tabs that
   uses placeholders would be the first form that does.
7. **Old-GUI respells, not in Clay's list but needed for the draw** (each measured by the probe):
   `bordered` → `border`; `flex` → `across`; `center` → `align=center valign=center`; keep `x=` / `y=` on the window.
8. **Two spellings that the switch needs (section 3), proposed:**
   - **a tab's label and its card apart:** `tabOne="One" card=firstCard`. The value is the label; `card=` names the card.
     A NAME, not `card:=firstCard`: a `:=` names a field that must already be defined (firstLight's notes), and the
     cards are defined after the bar.
   - **`register` on the cards goes:** it existed so the old GUI could find a card in the current registry; a name looked
     up inside the form does not need it.

## 3. The smallest mock click that tests tab switching

**Tony's goal (2026-11-11):** fire a click on a named field, not a point; run its attribute actions left to right (the
kant click model); select the field, as the old GUI did; lay the form out again with `setFrame`; draw `output.pdf`; all in
one call.

**What exists** (all kant, `incant/utilities`, on `incant/grammar`):

| piece | where | what it does |
|---|---|---|
| `click(request)` | utilities `click` | request `form:=theForm field="name"`; finds the field by name in the form (`tsFind`), refuses by name if absent; `selection := field`; fires the field's own action, then its attribute actions left to right (`clickFire`). Does not redraw. `clickT`, six rows. |
| `show(form)` / `showForm` | setup / utilities | builds the request, lays out a copy (`setFrame`), draws to the form's `path=` or `output.pdf`, opens the viewer |
| `redrawForm(request)` | utilities | `setFrame` then draw, one PDF |
| the swap by listening | firstLight, IBkant | a click's action writes a held field; that field's listener calls `show` or `redrawForm`. IBkant's `ibHears listenTo:=ibPage code={ show(IBkant); }` is click-then-redraw in one call today |
| `isHidden`, `noRoom` | utilities `frameMembers` | a hidden member takes no room and is not drawn |
| `selection` | utilities | written by `click`; read by `describe` only |

**What does not exist:**

1. **A `cards` reader.** At layout, of a `cards` field's members only one is laid out: the one `cards=Name` names, else
   the first; it gets the full box; the others are not drawn (the old GUI's `noRoom`; today `isHidden` on the copy).
2. **A `tabs` reader and `selectFill`.** The bar's `tabs=Name` marks one tab selected (else the first); the draw fills
   that tab with its `selectFill`. ⚠ It should read the BAR's `tabs=`, not the global `selection`: `click` sets `selection`
   to the definition's field, while `setFrame` lays out and draws a copy, so a test of "is this the selected field" on
   the copy would not match by identity.
3. **The tab's action** (`selectTab`): handed the clicked tab, it writes the bar's `tabs=` to the tab's name and the
   cards field's `cards=` to the tab's `card=`. How it finds the cards field is a choice: a `cards=` attribute on the bar
   naming the cards field (proposed: `tabBAR tabs=tabTwo cards=bodies`), or a search under the form for the one field
   carrying `cards`.
4. **Redraw in the same call.** `click` does not redraw. Two ways:
   - (a) **a new action `clickShow(request)`**: `click(request)`, then `showForm` on the request's form. Built once, any
     form.
   - (b) **IBkant's way**: the state lives in a field outside the form (`tabSelected`), the tab's action writes it, and
     that field's listener calls `show(tabForm)`. Nothing new in utilities, but every form wires its own listener.

   Proposal: (a). One call, as Tony's goal asks, and the form carries no wiring. ⚠ A form that already redraws by
   listening (firstLight, IBkant) would draw twice under `clickShow`; it is for forms that do not.
5. **Where the selection state lives: Tony's call.** (a) writes the DEFINITION's `tabs=` and `cards=`: the next layout
   reads them, since `setFrame` lays out a fresh copy each time. firstLight's swap was ruled the other way ("firstLight's
   own definition is never written by a swap"; the state is `insideForm`, outside the form). Tabs' `tabs=tabTwo` is
   already the initial state written on the definition, so writing it there keeps one place for it.

**Proposed spelling:**

```
tabOne="One" card=firstCard border fill:=lightGreen selectFill:=green onClick:=selectTab;
...
define
    tabClick form:=tabForm field="tabOne";
    ;
clickShow(tabClick);
```

`onClick:=selectTab` is an attribute holding an action, so `clickFire` already fires it, handed the tab (the kant click
model, left to right). `selectTab` and `clickShow` would live in `incant/utilities`.

**Which grammar:** `incant/grammar`, everywhere. The form is read by `define` on `incant/grammar`; `click`, `clickFire`,
`show`, `setFrame` and the draw walk are kant action bodies in `incant/utilities` and `incant/setup`, which build on
`incant/grammar` (the old road). Nothing here needs `incant/kantGrammar`.

## 4. Proposed strokes, smallest first, each ending in a PDF

| # | stroke | the PDF Tony looks at | rows |
|---|---|---|---|
| 1 | **Respell and stash.** `tabs` → `tabForm`, definitions only (section 2, items 1-3, 5, 7, 8); a stash entry. `Start(); show(tabForm);` draws. | today's picture: heading, three tabs labelled One Two Three, the three cards stacked, help | formsPop: the stash entry, the draw, three tab labels |
| 2 | **cards.** A `cards` field lays out one member: `cards=Name`, else the first, in the full box; the others hidden on the copy. | one card under the bar; with `cards=secondCard` written on bodies, the blue card | formsPop: which card is drawn, its frame is the body's box |
| 3 | **tabs and selectFill.** The bar's `tabs=Name` selects a tab (else the first) and the draw fills it with `selectFill`; the bar's `cards=bodies` sets bodies' card from the selected tab's `card=`. | tabTwo filled blue, the blue card shown; `tabs=` dropped, tabOne green and the green card | formsPop: the tab's fill, the card shown, both from one attribute |
| 4 | **The click.** `selectTab` (writes `tabs=` and `cards=`) and `clickShow(request)`; `onClick:=selectTab` on each tab. | after `clickShow` on tabOne: tabOne green, the green card; then tabThree: red and red | formsPop: three clicks in a row, each PDF's tab and card; a click on a name the form lacks refuses by name |

Placeholders (section 2, item 6) can ride stroke 1 if Tony rules the roles, or follow stroke 4. Stroke 2 can be tested
without stroke 3 by writing `cards=` by hand; stroke 3 without stroke 4 by writing `tabs=` by hand.

**Rulings this asks of Tony:** the form's name (`tabForm`?); placeholders (new roles, or explicit colours); where the
selection state lives (on the definition, or outside the form); the two spellings `card=` and `cards=` on the bar.
