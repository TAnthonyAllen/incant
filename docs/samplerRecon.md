# Sampler recon (SEQ 739, 2026-11-22)

Clay's dispatch of 2026-11-22 (forms, shape agreed with Tony): a recon of rows built at run time, reports and documents
only. Measured on trunk after seal 524, bare build 2026-11-22 09:42 (2191200 bytes), road **kant** (`incant/grammar`
bodies) throughout. Every probe drew to `IncantForms/PDF/test.pdf`; the specimen that draws both layouts side by side is in
`IncantForms/WorkingOn/tester` above `stop()`. Nothing in the tree changed but this file, tester, and a pointer line in
`Topics/forms`.

**THE SIZE ASSUMED (Tony, 2026-11-22: when something does not fit, the first cure is a bigger form, up to a maximum;
only then the letter row or next / previous).** The maximum is the display's height (less menu bar and dock) and about
0.62 of that wide. Until windows the display is unknown, so for a PDF the maximum is the page: **US Letter, 612 x 792
points, so a sampler panel at most 490 x 792** (0.62 x 792 = 491; it fits inside the page's 612). Section 4's commands
verdicts are measured at that size; the side-by-side windows are smaller, for comparing the two layouts only.

**The short answer: everything stage 1 needs exists today, in kant, with the existing actions.** Rows are built by a walk
(`new()`, `:%`, `+/`), held by `form:=`, swapped by listening, laid out by setFrame, drawn by the floor, re-coloured by a
look without a rebuild, clicked by the mock click, and shown in a display line by a typeset insert. The costs are spellings
and two design points (sections 1, 3 and 6), not missing machinery.

## 1. A walk builds page fields at run time; setFrame lays them out; the floor draws them -- YES

Probe: a walk over three `cOLOr` entries builds one row each, a name cell 120 wide and a swatch, into a page defined
empty (`spPage window ... down`), then `redrawForm`.

| measured | reads |
|---|---|
| the laid-out copy | three rows 30 high, each `name` 120 wide and the swatch taking the other 180 |
| the swatch pixels | black r0 g0 b0, blue r0 g81 b186, darkBrown r107 g71 b20 -- the colour each row holds |
| the name cells | drawn, 5, 4 and 9 characters |

**How a row is built** (all kant, all existing operators):

```
sr := new(srTag);            a row named for the entry
*sr :% new("across");        a bare attribute
sh := new("height"); *sh = 30; *sr :% *sh;      an attribute with a value
sf := new("fill"); *sf := *srC; *sk :% *sf;     an attribute HOLDING a colour (fill:=it)
*sr +/ *sn;                  a member: +/ (opAddMember)
spPage +/ *sr;
```

**Spellings this cost, each measured:**
- **`+/` adds a member; `+%` adds an attribute.** Built with `+%`, the rows were attributes and setFrame laid out nothing.
- **The page is generated, so the build writes it, not setFrame's copy.** setFrame still never writes the page; the
  generator owns it. A rebuild without clearing doubles it (3 rows -> 6); `clear(page)` empties it **attributes and all**,
  so the build re-adds the page's own attributes (`down`) first.
- **A walk takes its list as `argument`.** `for grup in *spSrc; members` reads the star as text and walks nothing
  (incant/setup's starNotInFor, SEQ 724). The builders take the registry as their argument.
- **Never hand a command entry to an action.** A `cOMMANDs` member is rule-shaped, so passing it as an argument fires it
  (bear-trap 34): the run stopped silently at the first one (`bail`/`stop`), no sentinel, nothing on stderr. Read
  `*grup.taG` inside the loop and pass the name.
- **A literal that starts with spaces loses them:** `" = "` joined as `"= "`; `"   kant:"` as `"kant:"`. A literal that is
  only spaces is `quoteBody` (bear-trap 28's doctrine).
- A top-level `x := redrawForm(...)` captures nothing; the driver goes in an action (bear-trap 15's family).

## 2. form:= holds a page built that way; swapping it by listening redraws -- YES

Probe: a Colors page and a Fonts page, both generated; an outer window `spBody form:=spHeld`; a listener
`listenTo:=spHeld code={ redrawForm(spReq); }`, IBkant's shape.

- `spHeld := spColors` draws the colours through the held field; `spHeld := spFonts` runs the listener **once** and the
  Fonts page draws its sample text in each font.
- **Held two deep, as IBkant's Reference page would be** (a window holding the sampler window holding its page): lays out
  and draws the same, the click and the display line included.
- **A row sized for 12-point text clips a large font:** Courier New 24 bold drew 0 of 11 characters in a 30-point row. The
  Fonts list needs rows sized to their font, or a fixed sample size.

## 3. A look switch -- free for what is drawn through a placeholder; text naming the look's value needs a rebuild

Probe: the Colors list built from `defaultLook`'s own colour placeholders. Each swatch holds the **placeholder**
(`*sf := sTYLEs[srTag]`, i.e. `fill:=accent`), not the colour. Drawn under no look, then under
`spDark merge pageFill:=black accent:=blue textColor:=white defaultLook`, with no rebuild between:

| row | plain | dark |
|---|---|---|
| pageFill | white | **black** |
| textColor | black | **white** |
| accent | red r239 g43 b45 | **blue** r0 g81 b186 |

**So today's merge pass (resolveLook, on setFrame's copy) re-resolves a generated page's placeholders as it does a
written form's, held or not; nothing new is owed.** The one cost: a name cell's text ("accent = red") is written when the
page is built, so under the dark look it would still say red. Either the Colors page is rebuilt on a look switch (one
`clear` and a build), or the cell's text reads the look at layout through a typeset insert. Not probed.

## 4. Both layouts on one registry, side by side

**Colors (`cOLOr`, 14 entries).** One window, A on the left, B on the right. Pictures, made from test.pdf after each
draw: `samplerColors.pdf` (as first drawn) and `samplerColorsClicked.pdf` (after a click on blue), in the session's
scratchpad; the specimen in tester redraws them.

- **A, the list:** a row per entry, "name = #hex" in a 130-wide cell and a bordered swatch. All 14 fit.
- **B, the buttons:** three to a row, each filled with its colour and carrying its name; the short last row's two buttons
  stretch (across divides the row). Black text on the black button is invisible: B needs a text colour per button.
- **The display line, driven the way describe is: YES.** Below the grid, a field whose text is the insert
  `{SamP.spDetail}`. Each button carries `onClick:=spPick`, **attached at run time** (`*bo := spPick` -- the tabForm trap
  is a define-time trap and does not arise). `click(form:=spPageB field="blue")` fires spPick, which writes `spDetail`
  ("Selected blue = #0051ba ... fill:=blue"); the redraw shows it (32 characters before, 38 after).
- **A click must name the page, not the window:** `click(form:=spOuter field="blue")` refuses ("the form spOuter has no
  field named blue"). click's search does not go into a held form. Fine for mock clicks; a real click from a point
  (windows) will need it.

**Commands (`cOMMANDs`, 107 entries, names 3 to 15 characters, median 8).** `samplerCommandsAll.pdf`,
`samplerCommandsNext.pdf`, `samplerCommandsAF.pdf`.

- **First cure, the bigger form.** Each layout alone at the maximum, 490 x 792 (`samplerCommandsMaxA.pdf`,
  `samplerCommandsMaxB.pdf`):
  - **B fits whole: all 107 commands, four to a row, 27 rows of 20 = 540 of the 762 points under the title; nothing
    clipped** (108 spans drawn: the title and every button). Room for the display line and about 50 more commands.
    **So the letter row is not needed today.**
  - **A does not fit and pages:** 33 rows of 22 a page, so 4 pages, where the small window needed 7.
- **A, next / previous -- the smallest spelling:** one count outside the page (`spFirst`) and a page size (33 at the
  maximum; 16 in the side-by-side window). The build lays out entries `spFirst` to `spFirst + size` and ends with a row
  of two buttons, `onClick:=spNext` and `spPrev`, which move `spFirst` by the page size (not past the end, not below 0)
  and rebuild. Measured in the small window: one click on next, page 2 is entries 16-31.
- **In the small side-by-side window (380 x 400 for B) B did not fit:** about 19 rows drawn, the rest off the bottom, and
  two names (`dupTermRefusal`, `immediateAction`) clipped at a quarter width. That window is smaller than the maximum,
  so this is not a verdict on B.
- **B's letter row, for when the maximum is not enough: cheap, and measured.** Four buttons (a-f, g-m, n-s, t-z) above the grid; the build keeps
  an entry when its name's first character's code is in range -- `name.numbeR`, the accessor restored at SEQ 738, is its
  first use. Group sizes: **a-f 35, g-m 27, n-s 37, t-z 8**; at four to a row the largest is 10 rows, 200 points. Drawn:
  a-f shows 34 buttons in 9 rows.
  ⚠ **Case:** `BLOCKing` and `TOKENize` start with capitals (codes 66, 84) and fall outside a lowercase range; a letter
  row needs both cases in each range.
- A's page is the same height whatever the registry; B's height is the registry's size. At the maximum size B holds
  about 150 entries before it needs the letter row; every list today is under that.

## 5. What stage 1's shape would make hard in stage 2

- **Picks must live outside the pages.** Every list switch and every look switch rebuilds a page (`clear`, build), so a
  try-it slot's state kept on a page is lost at the next rebuild. Keep it outside, as `tabSelected` is.
- **A run style cannot carry a fill.** The dispatch's preview style is `tryStyle merge font:=headingFont fill:=accent
  color:=textColor`; used as a run (`{tryStyle: text}`), typesetting warns and drops box attributes ("a run takes font,
  color, italic and space only", utilities `tsBoxWarn`). The fill goes on the preview field's `style:=`, the run keeps
  font and colour.
- **A style built at run time must be findable by the run.** A `{name: text}` run looks its style up by name; whether a
  style made with `new()` is found (or must be added to `sTYLEs`) is not measured.
- **Printed kant spellings are text in a typeset field,** so a `{` in one starts a run or an insert. "myStyle merge
  font:=..." has none; anything with braces needs the literal-brace spelling (`tsLit`, a doubled brace).
- **Leading spaces in literals vanish** (section 1), which matters to a line meant to be copied.

## 6. Design points for Tony (not rulings asked; what the build would have to decide)

1. **When the pages are built.** A form file is definitions only and `show` draws at once, so a generated page needs a
   build step before the draw: an action such as `sampler(list, look)` that builds, then shows. Or the list and look
   picks are held fields whose listeners rebuild and redraw (IBkant's shape, measured in section 2).
2. **The Colors list's source.** Section 3 builds from the look's placeholders (what a form names); section 4 from
   `cOLOr` (every colour there is). The dispatch's table says the former for Colors and Fonts.
3. **A or B** is Tony's choice after seeing them. Measured difference at the maximum size: A pages commands (4 pages);
   B shows every list whole, each entry's look on its own button, with no paging and no letter row.

## The probes

All in the session's scratchpad, run from the repo root with `INCANT_NOVIEW=1` and a 30-60 second alarm. The side-by-side
Colors specimen (section 4, with the click) is parked in `IncantForms/WorkingOn/tester` above `stop()`; Clod's G3
specimens moved below it, as tester's own note asks.
