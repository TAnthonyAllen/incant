# Forms step 4, the PDF context: recon (SEQ ___ R2, 2026-11-08)

**One plain line:** nothing in the tree opens, closes or reads back a PDF yet, and all of it is plain Core Graphics with
one request field each; the one question is where the PDF context lives, because the dispatch rules out the slot the
bitmap already uses.

Recon only. Trunk `c1251073` (borders bought, pixelAt fixed), binary bare. Road: C++ floor (GroupDraw).

## 1. The PDF floor

**Nothing exists.** No CGPDF*, CGContextDrawPDFPage, PDFKit or PDF-context call in any tracked `.twk`, `.rtn` or `.h`, nor
in the support repo or TOK (searched by name; the same search finds the bitmap's CGBitmapContextCreate when asked). The
binary links Cocoa, so Core Graphics' PDF calls are already available; no new framework (docs/firstLightPdfRecon.md).

**The smallest floor, three one-argument methods in GroupDraw beside makeDisplay:**
- `openPDF(request)`: CGPDFContextCreateWithURL at the request's `path`, media box from its `width` and `height`
  (points), CGPDFContextBeginPage, then the same flip makeDisplay sets (y down, origin at the top's x and y). Strings and
  numbers only: kant carries both natively, so not shape (C).
- `closePDF(request)`: CGPDFContextEndPage, CGPDFContextClose, release.
- `readPDF(request)`: CGPDFDocumentCreateWithURL on `path`, page 1, CGContextDrawPDFPage into a fresh bitmap of the
  page's size, so pixelAt reads it as it reads today's bitmap.

## 2. The display -- WHERE THE STOP IS

**The dispatch's premise does not hold: the bitmap DOES use the pointer slot, on the top field only.** makeDisplay ends
`field->setPointer((void*)ctx)` (GroupDraw.twk:164), and displayOf answers "the field itself if it opened one"
(`if field.isPointer return field`, :109). Step 1's finding was narrower: a context must not go in a CHILD's pointer
slot, because gPointer shares its union with gText and would destroy the child's text. So each descendant holds a
`display` PROPERTY naming the top, and only the top's pointer slot holds the context. firstLight's top carries no text,
which is why that is safe for it.

**So a PDF context can ride the handed-down display with NO new slot, exactly as the bitmap does** -- openPDF puts the
PDF CGContextRef in the top's pointer slot and hands the top down (handDisplay); displayFillRT and displayBorder read
`top->getPointer()` as a CGContextRef and draw into a PDF context unchanged. But that uses the pointer slot, which this
dispatch rules out. Without it, the context needs another home: the object slot (typed NSObject*; a CGContextRef is a
CF type, not an NSObject, and makeDisplay's own comment records the slot rejecting it at compile time), or a new slot.
R5 says stop on a new slot.

**Options for Tony:**
- (a) **The top's pointer slot, as the bitmap.** No new slot, no change to displayOf, fill or border. Same caveat the
  bitmap already carries: a top field whose value is text cannot hold a context there.
- (b) The object slot, by a bridging cast. No new slot, but it overrides a typed slot that setColor and getTextView use
  for their own objects, and makeDisplay's comment calls it rejected.
- (c) A new slot (a GroupBody field: groups.ext and tokall, bear-trap #10).

## 3. Page size and file

- **Page size:** the top field's frame, in points (ruled 2026-11-07): getFrame(firstLight) is 400 x 200 after setFrame.
  The request would carry `width` and `height`, so openPDF need not know about forms; drawWalkT copies them from the top.
- **File:** nothing decides it. The request's `path` names it. Tony opens it on his monitor, so it wants a stable place:
  for example `IncantForms/Windows/firstLight.pdf`, committed or gitignored, Tony's call. The fleet run writes its own copy
  under pop's temporary directory so a run never touches the one Tony looks at.

## 4. One thing the build must handle either way

drawWalk opens its own display (`makeDisplay(argument)` is its first line). Between openPDF and closePDF that would
replace the PDF context with a fresh bitmap and draw nothing into the PDF. So drawWalk must open a display only when the
top has none (`if !argument.isPointeR`, or a kant spelling for it), and that change has to be measured against today's
rows, which call makeDisplay before drawWalk.
