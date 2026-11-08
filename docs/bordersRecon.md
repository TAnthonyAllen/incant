# Forms step 3, borders: recon (SEQ ___ R1, 2026-11-08)

**One plain line:** there is no floor method that draws a border into the display, and nothing gives firstLight's borders
a colour, so per R3 and R4 nothing is built; one one-argument floor method and a colour ruling would unblock it.

Recon only. Trunk `708bed16` (draw-walk bought), binary bare. Road: C++ floor (GroupDraw) and kant (utilities).

## 1. The floor

**No floor method strokes into the display today.** Searched every tracked `.twk`, `.rtn` and `.h` for CGContextStroke*,
CGContextAddLine*, MoveTo, StrokeRect, NSFrameRect, SetLineWidth and SetRGBStroke, and every extern whose name carries
border, stroke or line: no hit. (A search for CGContextFillRect in the same population finds displayFillRT, so it can
find what it looks for.) The one stroke in the tree is `Layout.twk` drawRect (:101): AppKit NSBezierPath, the TOP field's
frame only, inside openWindow's window loop, black, width 0. It does not reach the bitmap and kant cannot call it.

**The smallest one** is displayFillRT's shape: `displayBorder(GroupItem field)`, ONE argument, registered as an
immediateAction like the other three, so kant reaches it and shape (C) is not needed. It reads the field's own `border`
and the four side names (bare = 1, =number = width), finds the context through displayOf (step 1's handed-down
property), sets the width and colour, and draws CGContextStrokeRect for a plain border or MoveTo / AddLineToPoint /
StrokePath per named side. A kant drawWalk then calls it after drawFill. One question it raises (below): whether a
width-w line sits inside the frame or centred on the edge.

## 2. The spellings

Census: the 23 files in IncantForms/Windows, each field's tokens in the live region (above bail() / stop()), with
comments, quoted strings, (...#) literals and code bodies removed first.

| token | uses | files |
|---|---|---|
| `border` (bare) | 4 | firstLight 1 (ok), draw 2, inspector 1 |
| `border=off` | 37 | 12 forms |
| `border=black` | 4 | layout 2, list 1, sheet 1 |
| `border=green` | 3 | layout 2, menu 1 |
| `bottomBorder` | 1 | firstLight (heading) |
| `topBorder`, `leftBorder`, `rightBorder` | 0 | -- |
| `rounded` (bare / =5 / =10.0 / =20.0) | 54 / 3 / 2 / 1 | 14 forms; **firstLight has none** |
| `border=<number>`, `borderColor`, `strokeColor`, `borderWidth`, `lineColor`, `lineWidth` | 0 | -- |

**firstLight uses exactly two:** `ok` has `border` (plain, four sides, width 1) and `heading` has `bottomBorder` (one
side, width 1). It has no rounded field, so R2's open-sides clause does not arise in it.

**A collision worth a ruling, though not on firstLight:** the old forms give `border` a COLOUR value (`border=black`,
`border=green`, 7 uses) or `off` (37), while the ruled shape gives it a WIDTH (`=number`). No form uses a number. The
forms plan's own line 10 already says number = width, off = none.

## 3. Colour

**Nothing gives a border a colour today, and nothing on firstLight's two bordered fields names one.**
- The style slot's design names `strokeColor` as a style COMPONENT (GroupDraw.twk DS-6 / SG note, :75-88), and
  styleComponent can read any component. Fixtures carry one (dsFill's `dsStyle ... strokeColor="dsBlue"`), but nothing
  reads it, and neither `ok` nor `heading` names a style.
- The old forms' `border=black` / `border=green` carry a colour in the border's own value (above), unread.
- The only default is C++: Stylish's constructor sets strokeColor = blackColor, and Layout.drawRect strokes black. Both
  are the AppKit window road; displayFillRT's road reads no Stylish.

## 4. Why nothing was built

- **R3's precondition fails:** it builds only if R1 finds a one-argument floor method or one kant already reaches. There is
  none; the smallest (section 1) is one argument but has to be written.
- **R4 trips:** border colour has no source today (section 3).

## 5. What would unblock it (for Tony's ruling)

1. **Write `displayBorder(field)`**, one argument, in GroupDraw beside displayFillRT (section 1). Not shape (C).
2. **A colour source for a border.** Candidates, none ruled: (a) the field's style's `strokeColor` component, falling back
   to black (the DS-6 design; firstLight would need a style or rely on the fallback); (b) black always, until a colour
   spelling is ruled; (c) the border's own value when it is a colour (`border=black`), which collides with `=number`.
3. **Where a wide line sits:** inside the frame (inset by half the width, so the fill's edge pixels are the border's), or
   centred on the edge (half outside, over the neighbour). The registered rows read "just inside and just outside", so
   the answer sets their expected values.
