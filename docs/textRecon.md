# Forms step 5, text: recon (SEQ 581 R4, 2026-11-09, trunk binary)

STOPPED at R4: the font and the text colour have no source today. Nothing built, no branch, no rows.
Probes were scratch files loaded by path; no file in the tree changed but this one and the seal.

## The five questions

1. **Which firstLight fields carry text, and how.** Three, all their own string value (data kind 13 on each,
   read with `.datA`): `heading` "First Light", `words` (150 characters), `ok` "OK". The top and `bar` hold no value
   (0). No field uses the `*field` spelling. `heading` and `ok` also carry `align=center` and a bare `text`
   attribute; step 5 draws left-aligned, so both will read as left-aligned until align is built.

2. **Where the font comes from: NO SOURCE (STOP).** firstLight says `font=normal` and heading `font=title`.
   `fONTs` (IncantForms/Controls/styles) holds `normalFont` and `titleFont`; there is no entry named `normal` or
   `title` (`fONTs["normal"]` reads 0; `normal` has no `family`). Nothing reads `font=` today. Bot's getFontFrom
   looked the name up in its own register of libharu names, so it is no precedent for `normal` -> `normalFont`.
   The fonts that DO load: `normalFont` -> Palatino 14 regular, `titleFont` -> Palatino 24 bold (fontReport;
   Core Text loads family Palatino by name). `words` and `ok` name no font; the subtree rule gives them firstLight's.
   The parent chain is there for that walk: ok -> bar -> firstLight, measured by addrOf (body #4 = firstLight's).

3. **Where text colour comes from: NO SOURCE (STOP).** No firstLight field and no style names one. formsTable keeps
   `color` (layout, inherited, from style) and drops `textColor` as a second name for it.

4. **Does Core Text draw upside down in the top's flipped context? YES, measured.** A scratch bitmap flipped as
   makeDisplay flips it, "T" in Palatino 40 at baseline y=50 (y down): with the identity text matrix the ink runs
   rows 49..77 and the bar is at row 75 (below the baseline: upside down); with the text matrix scaled (1,-1) the
   ink runs rows 21..49 and the bar is at row 22 (upright). A framesetter lays lines out y-up inside its path,
   so the floor un-flips locally around the field's frame. That is H7 (b)'s mechanism.

5. **Long enough to wrap?** `words` wraps but does not overflow: Palatino 14, 400 x 135 less a 4-point inset, gives
   3 lines, all 150 characters visible (line height 15.4). Nothing in firstLight overflows its height or has a word
   wider than its frame. Proposed, on trunk, in a new formsPop fixture `textT` (not in firstLight): `tOver`, the
   words text in a 120 x 40 frame (overflows height; the last drawn word ends before the edge); `tLong`, one long
   word in a 60-wide frame (clipped at the edge).

## Proposals for Tony's ruling

- **Font spelling.** (a, recommended) respell firstLight `font=normalFont`, heading `font=titleFont`: names as the
  fONTs entries stand, respelled form by form. (b) the floor tries `X`, then `XFont`: no form changes, a naming rule.
- **Font and colour inheritance: where the walk lives.** R3 puts style resolution in kant, but displayFillRT and
  displayBorder already read their attributes and style in C++. Proposed: displayText reads the field's own `font`
  and `color`, then its style's, then the nearest enclosing field's (the parent chain), in C++ as its siblings do;
  or kant resolves and the floor reads only the field. Tony's call.
- **Colour.** `color`, as above; none anywhere is black. firstLight names none, so it draws black.
- **Inset.** 4 points, fixed in the floor (R2).
