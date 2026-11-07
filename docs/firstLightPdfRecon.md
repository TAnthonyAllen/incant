# firstLight to a PDF file: recon (R2, 2026-11-07)

Recon and docs only. Nothing built. The goal is IncantForms/Windows/firstLight on disk as a PDF; a page with framed
fills and borders counts as a first PDF, and text may come last. Measured on trunk at `007c5b59`, binary bare.
The probe is `docs/pdfProbes/firstLightDraw` (run from Groups). It exits 0 with its sentinel printed.

## The pieces

| piece | exists? | where | what it does today, measured |
|---|---|---|---|
| **setFrame on firstLight** | **yes, works** | incant/utilities :258 (kant) | Every field framed and the sizes sum: heading 400x30 at (300,450), words 400x135 at (300,480), bar 400x35 at (300,615), and in the bar space 340 and ok 60 side by side. Frames are absolute: they include the window position (300,450). |
| **the draw walk** | **no** | nothing walks a form and draws | Layout.twk drawRect (:101) is the window path: it strokes the TOP field's frame only and reads no child. It runs only inside openWindow's AppKit loop (guiHost.mm :26). |
| **fill** | **yes, one field at a time, onto its own bitmap** | GroupDraw.twk displayFillRT :157; command displayFill jitEmitters.rtn :43; makeDisplay :99; pixelAt :202 | Colours resolve: firstLight's wall, white and lightGreen are all in IncantForms/Controls/styles. **Two gaps, both measured.** (1) The context lives on the field itself, so a child cannot draw: `words` refuses "no display; call makeDisplay first". (2) It fills at the frame's ABSOLUTE x and y, but makeDisplay sizes the bitmap to width and height only, so a field not at 0,0 paints off its own canvas. firstLight reads pixel (5,5) = 0,0,0,0 after its wall fill. The control, the same 400x200 at 0,0 with the same fill, reads 247,232,170, which is wall. Not registered in incant/setup; fixtures register it locally (dsFill). |
| **border, bottomBorder** | **no** | no CGContextStroke or line drawing anywhere in the built tree | The plan names the floor calls: CGContextStrokeRect for border, MoveTo/AddLineToPoint/StrokePath for one side (forms :290-310). No reader of either attribute. |
| **text** | **no** | no Core Text call in the built tree | Last, by R2. |
| **a Core Graphics PDF context** | **no** | no CGPDFContext anywhere in the built tree (searched all of InProcess except the backup directories and Bot) | Bot/PDF.twk drew PDFs in 2021 through **libharu**, which the plan rules out (forms :135). It is a reference for what a draw walk visits, not code to reuse. The binary links Cocoa, which brings Core Graphics and Core Text, so no new framework is needed. |

**Coordinates, for every step below.** Forms are top-left, y down (openWindow flips for the screen, guiHost.mm :48).
A PDF page is bottom-left, y up. A page's origin is its top field's x and y, so a field draws at (x - top.x, top.height - (y - top.y) - height). Units are points, by ruling (forms :417), so firstLight's page is 400 by 200 points.

**Foreign calls.** The first floor methods of the PDF stroke are the first written in shape (C) (forms :421): one
request group per call, results written into the request, true or false back, and a refusal by name.

## The smallest steps to a first page, in order

Each step is one stroke with its own certificate. Each certificate is read by value, with an H7.

**1. Draw relative to a page, into a context handed down.** Change the fill floor so a field draws into its top
field's context at page coordinates (above), not into its own bitmap at absolute ones. Bitmap only, no PDF yet,
so pixelAt can read it.
Certificate: firstLight's wall at (5,5) reads 247,232,170, and the 0,0 control still reads the same. H7: absolute
coordinates restored, and (5,5) reads 0,0,0,0 again.

**2. The draw walk, in kant.** Walk the form parent before child, depth first, and fill each field that names a
fill; skip those that do not (today heading refuses for having none).
Certificate: one pixel per field: wall inside heading (it has no fill, so its parent shows), white inside words,
wall inside space, lightGreen inside ok. Plus a count of fields visited, 6. H7: the walk stops at the top, and words
and ok read wall.

**3. Borders.** One stroke floor method for border (four sides, width 1) and the named sides (bottomBorder).
Certificate: a pixel on heading's bottom edge reads the stroke colour, and one a few points above it reads wall; a
pixel on ok's left edge reads the stroke, and one inside reads lightGreen. H7: the side spelling ignored, and
heading's bottom edge reads wall.

**4. Open and close a PDF context; the walk draws into it.** Two floor methods in shape (C): open a CGPDFContext
at a path, sized to the top field's width and height, and begin the page; then end the page, close and release.
The walk from steps 2 and 3 is unchanged; only the context differs.
Certificate: the file exists, begins `%PDF`, and has one page of 400 by 200. Its content is read back by a floor
reader that draws the page into a bitmap (CGContextDrawPDFPage), so pixelAt reads the same four pixels as step 2.
H7: no close, and there is no readable page.
This is the first PDF.

**5. Text.** A single line for heading and ok (CTLineDraw, align=center), then words poured into its frame with the
count of characters that fit (CTFramesetter), as the typesetting subset rules (forms :398).

## Notes

- Steps 1 to 3 work entirely on the bitmap, where pixelAt already reads by value. So the PDF arrives in step 4 with
  its drawing already certified, and step 4 certifies only the context and the read-back.
- firstLight lays out once, as ruled (R0), so no step needs a second run.
- Today's fill refuses loudly for a field with no fill. The walk decides whether to call it. The refusal stays for
  a direct call.
- An earlier probe crashed at exit 139 on the top-level statement `firstLight.px = 5;`. It was set through an action
  instead. That is the setFlagTopLevel family, not anything in drawing. Context only.
