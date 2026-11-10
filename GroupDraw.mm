#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "GroupControl.h"
#include "GroupBody.h"
#include "Layout.h"
#include "Stylish.h"
#include "GroupDraw.h"

extern "C" GroupItem *closePDF(GroupItem *request)
{
	
	if (!request) return 0;
	GroupItem *formF = request->get("form");
	GroupItem *top = (formF && isGROUP(formF->groupBody->flags.data)) ? formF->getGroup() : 0;
	CGContextRef ctx = top ? (CGContextRef)top->getPointer() : 0;
	if (!ctx) {
	::fprintf(stderr,"closePDF: REFUSING %s -- its form holds no open PDF\n", request->groupBody->tag);
	return 0; }
	CGPDFContextEndPage(ctx);
	CGPDFContextClose(ctx);
	CGContextRelease(ctx);
	//  noDangling the slot is cleared, so a later read finds no context rather than a released one
	top->groupBody->gPointer = 0;
	top->groupBody->flags.isPointer = 0;
	
	return request;
}

/*****************************************************************************
    displayBorder -- forms step 3. Strokes the field's border into the display
    its top handed down, built as displayFillRT is: one argument, the field's
    own drawing attributes read here in C++.

    WIDTH: border, topBorder, bottomBorder, leftBorder, rightBorder; a bare
    name is width 1, =n is width n. Naming any side draws only the sides
    named; a plain border draws all four. Any other value is refused by name:
    a border's value is its width (Tony, forms step 3 R1).
    COLOUR: strokeColor, the field's own first, then its style's, else black.
    PLACE: width sits INSIDE the frame -- each line is inset by half its width,
    so a field's drawing never spills onto a neighbour (R2).
*****************************************************************************/
extern "C" GroupItem *displayBorder(GroupItem *field)
{
GroupItem 	*comp = 0;
NSColor 	*colour = 0;
char 		*value = 0;
	if ( !field )
		return 0;
	// ownThenStyle the field's own strokeColor first, then its style's; none at all is black (forms step 3 R1)
	comp = field->get("strokeColor");
	if ( !comp )
		comp = ::styleComponent(field,"strokeColor");
	if ( comp )
		{
		value = comp->getText();
		if ( isGROUP(comp->groupBody->flags.data) )
			colour = ::setColor(comp->getGroup());
		else
		if ( *value == '#' )
			colour = ::setColor(comp);
		else	colour = getColor(value);
		if ( !colour )
			{
			::fprintf(stderr,"displayBorder: REFUSING %s -- %s names no colour that could be realised\n",field->groupBody->tag,comp->groupBody->tag);
			return 0;
			}
		}
	
	NSRect       framed = ::getFrame(field);
	GroupItem   *top    = displayOf(field);
	CGContextRef ctx    = top ? (CGContextRef)top->getPointer() : 0;
	if (!ctx) {
	::fprintf(stderr,"displayBorder: REFUSING %s -- no display; call makeDisplay first\n", field->groupBody->tag);
	return 0; }
	const char *bad = 0;
	auto widthOf = [&](const char *name, CGFloat *w) -> int {
	GroupItem *side = field->get((char*)name);
	if (!side) return 0;
	unsigned int d = side->groupBody->flags.data;
	if (isCOUNT(d))         *w = side->getCount();
	else if (isNUMBER(d))   *w = side->getNumber();
	else if (!d)            *w = 1;
	else { bad = name; return -1; }
	return *w > 0 ? 1 : 0; };
	CGFloat wAll = 0, wT = 0, wB = 0, wL = 0, wR = 0;
	int all = widthOf("border", &wAll);
	int t = widthOf("topBorder", &wT), b = widthOf("bottomBorder", &wB);
	int l = widthOf("leftBorder", &wL), r = widthOf("rightBorder", &wR);
	if (bad) {
	::fprintf(stderr,"displayBorder: REFUSING %s -- %s's value is not a width\n", field->groupBody->tag, bad);
	return 0; }
	if (!t && !b && !l && !r) {
	if (all <= 0) return field;
	t = b = l = r = 1;
	wT = wB = wL = wR = wAll; }
	//  asFillDoes a named colour's components go in as displayFillRT hands its own; no colour named is black
	CGFloat cr = 0, cg = 0, cb = 0, ca = 1;
	if (comp) [colour getRed:&cr green:&cg blue:&cb alpha:&ca];
	CGContextSetRGBStrokeColor(ctx, cr, cg, cb, ca);
	CGContextSetLineCap(ctx, kCGLineCapButt);
	CGFloat x0 = framed.origin.x, y0 = framed.origin.y;
	CGFloat x1 = x0 + framed.size.width, y1 = y0 + framed.size.height;
	//  insideTheFrame each side's line is inset by half its width, and runs the frame's whole length (R2)
	auto side = [&](CGFloat w, CGFloat ax, CGFloat ay, CGFloat bx, CGFloat by) {
	CGContextSetLineWidth(ctx, w);
	CGContextBeginPath(ctx);
	CGContextMoveToPoint(ctx, ax, ay);
	CGContextAddLineToPoint(ctx, bx, by);
	CGContextStrokePath(ctx); };
	if (t > 0) side(wT, x0, y0 + wT / 2, x1, y0 + wT / 2);
	if (b > 0) side(wB, x0, y1 - wB / 2, x1, y1 - wB / 2);
	if (l > 0) side(wL, x0 + wL / 2, y0, x0 + wL / 2, y1);
	if (r > 0) side(wR, x1 - wR / 2, y0, x1 - wR / 2, y1);
	
	return field;
}

extern "C" GroupItem *displayFillRT(GroupItem *field)
{
GroupItem 	*comp = 0;
NSColor 	*colour = 0;
char 		*value = 0;
	if ( !field )
		return 0;
	// ownFill the field's own fill first, never a parent's: fill is not inherited (SEQ 549 R0, R1)
	comp = field->get("fill");
	if ( !comp )
		comp = ::styleComponent(field,"fillColor");
	if ( !comp )
		{
		::fprintf(stderr,"displayFill: REFUSING %s -- its style names no fillColor component\n",field->groupBody->tag);
		return 0;
		}
	// heldNotName := draws the field it holds; a # value is parsed where it sits; any other value is a name, looked up at draw (Tony, SEQ 535 R1, SEQ 549 R0)
	value = comp->getText();
	if ( isGROUP(comp->groupBody->flags.data) )
		colour = ::setColor(comp->getGroup());
	else
	if ( *value == '#' )
		colour = ::setColor(comp);
	else	colour = getColor(value);
	if ( !colour )
		{
		::fprintf(stderr,"displayFill: REFUSING %s -- %s names no colour that could be realised\n",field->groupBody->tag,comp->groupBody->tag);
		return 0;
		}
	
	NSRect       framed = ::getFrame(field);
	GroupItem   *top    = displayOf(field);
	CGContextRef ctx    = top ? (CGContextRef)top->getPointer() : 0;
	if (!ctx) {
	::fprintf(stderr,"displayFill: REFUSING %s -- no display; call makeDisplay first\n",
	field->groupBody->tag);
	return 0; }
	CGFloat r = 0, g = 0, b = 0, a = 0;
	[colour getRed:&r green:&g blue:&b alpha:&a];
	CGContextSetRGBFillColor(ctx, r, g, b, a);
	CGContextFillRect(ctx, CGRectMake(framed.origin.x, framed.origin.y,
	framed.size.width, framed.size.height));
	
	return field;
}

/*****************************************************************************
    DS-6 — THE MINIMAL DISPLAY. 2026-08-06.

    Two of the GD ruling's four things, and only two: A BITMAP CONTEXT and a
    CURRENT-STYLE SLOT. The pen and the measure method are explicitly OUT --
    they belong to drawText's day, and naming them here as absent is what keeps
    this a seed of the ruled design rather than a rival to it.

    IT LIVES ON A GroupItem, WHICH IS WHY THERE ARE NO STATICS. The
    CGBitmapContext goes in the node's object slot -- the same slot getTextView
    already uses for its editor and setColor uses for its realised NSColor -- so
    "the display" is an ordinary field you can pass, attach and look up. No
    global current-display, nothing to reset between runs, and the display is
    findable by every mechanism a GroupItem is findable by.

    THE CURRENT-STYLE SLOT IS THE NODE'S `style` ATTRIBUTE, and per FR-2a it
    NAMES A STYLE GroupItem THAT HOLDS COMPONENTS AS ATTRIBUTES -- `fillColor`,
    `strokeColor`, and whatever later commands need. A draw method reads a
    NAMED COMPONENT (styleComponent below), never the style's own text.

    ⚠ SG, 2026-08-06: THIS REPLACED A DEGENERATE SLOT, and the reason is the
    whole point of converting before `line` rather than after. The first cut had
    the style attribute's text name a colour DIRECTLY -- so the style WAS one
    colour. That is sufficient for fill, which needs exactly one, and it is why
    the fill specimen could be small. It cannot express a second component, so
    `line` (which needs a stroke colour) would have forced an ad-hoc
    `strokeColor` attribute beside it and shipped a SECOND styling convention --
    DS-6's rival-design failure, arriving one command after the fence was aimed
    at it. One command is a conversion; three is a migration.

    The colour is parsed when it is drawn, with nothing kept (Tony, SEQ 535 R1): a
    component holding a field reads that field; a quoted component names one.

    COORDINATES (step 1 toward the first PDF, Tony, 2026-11-07): the top field
    opens the one context and sets it, once, to draw in the form's own
    coordinates: y down from the top, the origin at the top field's x and y. So
    every field fills its own frame as it stands and lands at page coordinates;
    no field below the top knows about the flip. The top then hands the context
    down: each descendant gets a `display` PROPERTY holding the top field, and
    displayOf finds the context through it. A property, not an attribute, so the
    form's definition is unchanged (Tony, SEQ ___ R0). Not the pointer slot:
    gPointer shares its union with gText, so a context there would destroy a
    child's text.
*****************************************************************************/
/*  displayOf the field whose pointer slot holds the drawing context: the field
    itself if it opened one, else the top field its `display` property holds.  */
GroupItem *displayOf(GroupItem *field)
{
GroupItem 	*hold = 0;
	if ( field->groupBody->flags.isPointer )
		return field;
	hold = field->getProperty("display");
	if ( hold && isGROUP(hold->groupBody->flags.data) )
		return hold->getGroup();
	return 0;
}

/*****************************************************************************
    displayText -- forms step 5. Draws a field's text in its frame, into the
    display its top handed down. ONE argument, a request kant's drawText fills
    afresh on every call (utilities): field:= the field (frame and display),
    source:= the field whose own string is the text (the field, or *field one
    level down), font:= and color:= as kant resolved them -- own, style, then
    the enclosing field (Tony, SEQ 582 R1). A slot written `= 0` holds no
    group and means none: the font is then Helvetica 12, the colour black.
    The floor resolves nothing; it reads the request.

    WRAP at word boundaries, wrapped lines not indented; a line that does not
    fit the frame's height is not drawn, so the last line drawn ends on a
    space; a single word wider than the frame is kept whole and clipped at the
    frame edge (R1). Either case warns once, naming the field. The inset is a
    fixed 4 points (R3). align (step 5a, SEQ 584): left, center, right or
    justify, read from the request's align slot; each line is flushed or
    justified on its own inside the inset, and justify leaves the paragraph's
    last line left (Core Text's own meaning). valign (step 5b, SEQ 605): top,
    center or bottom, read from the request's valign slot; the block of lines
    that fit is counted first, then moved down as one inside the inset.
    A line per call on stdout says what was used -- font, colour, lines drawn,
    characters drawn, and what follows the last drawn word -- so a row
    compares values (H4).
*****************************************************************************/
extern "C" GroupItem *displayText(GroupItem *request)
{
	
	if (!request) return 0;
	//  heldBy follows a slot through holders to the first node that is not one; a slot holding no group gives null
	auto heldBy = [](GroupItem *slot) -> GroupItem* {
	GroupItem *node = slot;
	int hops = 0;
	while (node && isGROUP(node->groupBody->flags.data) && hops < 4) { node = node->getGroup(); hops++; }
	return hops ? node : 0; };
	GroupItem *fieldSlot = request->get("field"), *sourceSlot = request->get("source");
	GroupItem *field  = (fieldSlot && isGROUP(fieldSlot->groupBody->flags.data)) ? fieldSlot->getGroup() : 0;
	GroupItem *source = (sourceSlot && isGROUP(sourceSlot->groupBody->flags.data)) ? sourceSlot->getGroup() : 0;
	if (!field || !source) {
	::fprintf(stderr,"displayText: REFUSING %s -- needs field:= and source:=\n", request->groupBody->tag);
	return 0; }
	unsigned int kind = source->groupBody->flags.data;
	//  oneLevel the text is the source's own string; a source that holds a group is a group inside a group
	if (isGROUP(kind)) {
	::fprintf(stderr,"displayText: REFUSING %s -- its text is a group holding a group; one level only\n", field->groupBody->tag);
	return 0; }
	if (!isSTRING(kind) && !isTOKEN(kind)) return request;
	//  topText a top's pointer slot shares its union with the text slot, so a top that holds a display and a string has lost the string
	if (source->groupBody->flags.isPointer) {
	::fprintf(stderr,"displayText: REFUSING %s -- a top keeps its display in its text slot; put the text on a child\n", source->groupBody->tag);
	return 0; }
	char *text = source->getText();
	if (!text || !*text) return request;
	GroupItem   *top = displayOf(field);
	CGContextRef ctx = top ? (CGContextRef)top->getPointer() : 0;
	if (!ctx) {
	::fprintf(stderr,"displayText: REFUSING %s -- no display; call makeDisplay first\n", field->groupBody->tag);
	return 0; }
	GroupItem *fontNode = heldBy(request->get("font")), *colorNode = heldBy(request->get("color"));
	NSFont *font = fontNode ? ::getFont(fontNode) : 0;
	if (!font) font = [NSFont fontWithName:@"Helvetica" size:12];
	//  asFillDoes a colour entry is read as displayFillRT reads one; none named is black (R2)
	NSColor *colour = 0;
	if (colorNode) {
	char *value = colorNode->getText();
	colour = (value && *value == '#') ? ::setColor(colorNode) : ::getColor(value); }
	CGFloat cr = 0, cg = 0, cb = 0, ca = 1;
	if (colour) [colour getRed:&cr green:&cg blue:&cb alpha:&ca];
	//  alignOf left, center, right or justify as kant resolved it; none is left; any other value is refused by name and drawn left (R0, R3)
	GroupItem  *alignNode = heldBy(request->get("align"));
	const char *align = "left";
	if (alignNode) {
	char *named = alignNode->getText();
	if (named && (!::strcmp(named,"left") || !::strcmp(named,"center") || !::strcmp(named,"right") || !::strcmp(named,"justify")))
	align = named;
	else ::fprintf(stderr,"displayText: REFUSING %s's align=%s -- not left, center, right or justify; drawn left\n",
	field->groupBody->tag, named ? named : ""); }
	int alignKind = !::strcmp(align,"center") ? 1 : !::strcmp(align,"right") ? 2 : !::strcmp(align,"justify") ? 3 : 0;
	//  valignOf top, center or bottom as kant resolved it; none is top; any other value is refused by name and drawn top (SEQ 605 R1)
	GroupItem  *valignNode = heldBy(request->get("valign"));
	const char *valign = "top";
	if (valignNode) {
	char *named = valignNode->getText();
	if (named && (!::strcmp(named,"top") || !::strcmp(named,"center") || !::strcmp(named,"bottom")))
	valign = named;
	else ::fprintf(stderr,"displayText: REFUSING %s's valign=%s -- not top, center or bottom; drawn top\n",
	field->groupBody->tag, named ? named : ""); }
	int valignKind = !::strcmp(valign,"center") ? 1 : !::strcmp(valign,"bottom") ? 2 : 0;
	CTFontRef ct = (CTFontRef)font;
	NSString *str = [NSString stringWithUTF8String:text];
	NSDictionary *attrs = @{ (id)kCTFontAttributeName: (id)ct, (id)kCTForegroundColorFromContextAttributeName: @YES };
	NSAttributedString *as = [[NSAttributedString alloc] initWithString:str attributes:attrs];
	CTTypesetterRef ts = CTTypesetterCreateWithAttributedString((CFAttributedStringRef)as);
	NSRect  framed = ::getFrame(field);
	CGFloat inset = 4;
	CGFloat x0 = framed.origin.x + inset, width = framed.size.width - 2 * inset;
	CGFloat bottom = framed.origin.y + framed.size.height - inset;
	CGFloat asc = CTFontGetAscent(ct), desc = CTFontGetDescent(ct), lineH = asc + desc + CTFontGetLeading(ct);
	CGFloat baseline = framed.origin.y + inset + asc;
	CFIndex len = [str length], start = 0;
	int lines = 0, tooWide = 0;
	//  lineBreak the characters of the line that starts here: a word boundary that fits the width, or a whole word with no space to break at
	auto lineBreak = [&](CFIndex from) -> CFIndex {
	CFIndex n = CTTypesetterSuggestLineBreak(ts, from, width);
	if (n < 1) n = 1;
	BOOL spaced = NO;
	for (CFIndex i = from; i < from + n; i++) if ([str characterAtIndex:i] == ' ') { spaced = YES; break; }
	if (!spaced && from + n < len && [str characterAtIndex:from + n - 1] != '-') {
	CFIndex e = from + n;
	while (e < len && [str characterAtIndex:e] != ' ') e++;
	n = e - from; }
	return n; };
	//  blockFirst center and bottom count the lines that fit, then move the whole block down inside the inset; the same lines fit after the move
	if (valignKind) {
	int fit = 0;
	CFIndex at = 0;
	CGFloat line0 = baseline;
	while (at < len) {
	if (fit) while (at < len && [str characterAtIndex:at] == ' ') at++;
	if (at >= len || line0 + desc > bottom) break;
	at += lineBreak(at);
	fit++;
	line0 += lineH; }
	if (fit) {
	CGFloat spare = (framed.size.height - 2 * inset) - ((fit - 1) * lineH + asc + desc);
	if (spare > 0) baseline += (valignKind == 1) ? spare / 2 : spare; } }
	CGContextSaveGState(ctx);
	//  clipAtFrame a word wider than the frame is cut at the frame's edge, never beyond it (R1)
	CGContextClipToRect(ctx, CGRectMake(framed.origin.x, framed.origin.y, framed.size.width, framed.size.height));
	CGContextSetRGBFillColor(ctx, cr, cg, cb, ca);
	//  uprightGlyphs the top's context is flipped (y down); this turns the glyphs the right way up, and only them
	CGContextSetTextMatrix(ctx, CGAffineTransformMakeScale(1, -1));
	while (start < len) {
	//  noIndent a wrapped line starts at its first character that is not a space
	if (lines) while (start < len && [str characterAtIndex:start] == ' ') start++;
	if (start >= len) break;
	//  wholeLines a line that does not fit the frame's height is not drawn
	if (baseline + desc > bottom) break;
	CFIndex n = lineBreak(start);
	CTLineRef line = CTTypesetterCreateLine(ts, CFRangeMake(start, n));
	if (CTLineGetTypographicBounds(line, 0, 0, 0) - CTLineGetTrailingWhitespaceWidth(line) > width) tooWide = 1;
	//  alignLine within the inset: center and right flush the line; justify stretches every line but the paragraph's last (R1)
	CGFloat offset = 0;
	CFIndex rest = start + n;
	while (rest < len && [str characterAtIndex:rest] == ' ') rest++;
	if (alignKind == 3 && rest < len) {
	CTLineRef justified = CTLineCreateJustifiedLine(line, 1.0, width);
	if (justified) { CFRelease(line); line = justified; } }
	else if (alignKind == 1 || alignKind == 2) {
	offset = CTLineGetPenOffsetForFlush(line, alignKind == 1 ? 0.5 : 1.0, width);
	if (offset < 0) offset = 0; }
	CGContextSetTextPosition(ctx, x0 + offset, baseline);
	CTLineDraw(line, ctx);
	CFRelease(line);
	lines++;
	start += n;
	baseline += lineH;
	}
	CGContextRestoreGState(ctx);
	CFRelease(ts);
	[as release];
	//  afterLastWord what follows the last word drawn: a space, the end of the text, or more of the same word
	const char *next = "end";
	if (start < len) {
	CFIndex k = start - 1;
	while (k >= 0 && [str characterAtIndex:k] == ' ') k--;
	next = ([str characterAtIndex:k + 1] == ' ') ? "space" : "word"; }
	if (start < len || tooWide)
	::fprintf(stderr,"displayText: WARNING %s -- %s; %ld of %ld characters drawn\n", field->groupBody->tag,
	tooWide ? "a word wider than its frame is clipped at the frame" : "its text does not fit its frame", (long)start, (long)len);
	int bold = (CTFontGetSymbolicTraits(ct) & kCTFontBoldTrait) ? 1 : 0;
	CFStringRef family = CTFontCopyFamilyName(ct);
	::printf("=== displayText %s font %s %g %d color r%d g%d b%d lines %d drawn %ld of %ld next %s valign %s align %s ===\n",
	field->groupBody->tag, [(NSString*)family UTF8String], (double)CTFontGetSize(ct), bold,
	(int)lrint(cr * 255), (int)lrint(cg * 255), (int)lrint(cb * 255), lines, (long)start, (long)len, next, valign, align);
	::fflush(stdout);
	CFRelease(family);
	
	return request;
}

/*******************************************************************************
	blockContaining now lives in Stylish.twk (2026-07-02 dedup — was defined
    twice, causing a duplicate-symbol link error; Stylish's version is current).
*******************************************************************************/
/****************************************************************************
	Get the frame struct for the group passed in.
****************************************************************************/
extern "C" NSRect getFrame(GroupItem *item)
{
GroupItem 	*x = item->getLabelGroup("x");
GroupItem 	*y = item->getLabelGroup("y");
GroupItem 	*width = item->getLabelGroup("width");
GroupItem 	*height = item->getLabelGroup("height");
NSRect 		framed;
	framed.origin.x = x ? x->getNumber() : 0.0;
	framed.origin.y = y ? y->getNumber() : 0.0;
	framed.size.width = width ? width->getNumber() : 0.0;
	framed.size.height = height ? height->getNumber() : 0.0;
	return framed;
}

/*  handDisplay the top hands its context down: every descendant's `display`
    property holds the top field (an existing one is re-aimed, not doubled).  */
void handDisplay(GroupItem *field, GroupItem *top)
{
GroupItem 	*item = 0;
GroupItem 	*hold = 0;
	if ( !field->groupBody->flags.hasMembers )
		return;
	while ( item = field->nextMember(item) )
		{
		hold = item->getProperty("display");
		if ( !hold )
			{
			hold = new GroupItem("display");
			item->addProperty(hold);
			}
		hold->setGroup(top);
		if ( item->groupBody->flags.hasMembers )
			::handDisplay(item,top);
		}
}

extern "C" GroupItem *makeDisplay(GroupItem *field)
{
	
	/*  getFrame IS CALLED INSIDE THE PASSTHROUGH, with the raw NSRect rather
	than the incant `Frame` alias. Declaring it at incant level and using it
	only in here gets it PRUNED -- tok cannot see into a passthrough, decides
	the declaration is dead, and emits nothing for it, leaving this block
	referencing an undeclared identifier. tok warns
	"Declarations ignored because not used", which is bear-trap #13 and is
	load-bearing rather than cosmetic; it fired on exactly this code.  */
	NSRect framed = ::getFrame(field);
	int w = (int)framed.size.width, h = (int)framed.size.height;
	if (w < 1 || h < 1) {
	::fprintf(stderr,"makeDisplay: REFUSING %s -- frame is %dx%d; needs width and height attributes\n",
	field->groupBody->tag, w, h);
	return 0; }
	CGColorSpaceRef  cs  = CGColorSpaceCreateDeviceRGB();
	CGContextRef     ctx = CGBitmapContextCreate(0, w, h, 8, 0, cs,
	kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(cs);
	if (!ctx) {
	::fprintf(stderr,"makeDisplay: REFUSING %s -- CGBitmapContextCreate failed\n",
	field->groupBody->tag);
	return 0; }
	/*  THE POINTER SLOT, NOT THE OBJECT SLOT. getObject/setObject are typed
	NSObject* and a CGContextRef is not one -- it is a CF type, so the
	object slot rejects it at compile time. The pointer slot is the
	tree's existing home for a non-NSObject payload; it is what
	makeStyleFor uses to hang a Stylish on a GroupItem.  */
	/*  flipOnce top-left, y down, origin at the top field: set here and nowhere else  */
	CGContextTranslateCTM(ctx, 0, h);
	CGContextScaleCTM(ctx, 1, -1);
	CGContextTranslateCTM(ctx, -framed.origin.x, -framed.origin.y);
	field->setPointer((void*)ctx);
	
	::handDisplay(field,field);
	return field;
}

/*****************************************************************************
    openPDF / closePDF / readPDF -- forms step 4, the first PDF. One request
    field each. The request names the file (`path`) and, for openPDF, the form
    (`form:=` its top field) and the page (`width`, `height`, points).

    openPDF opens a PDF context and treats it exactly as makeDisplay treats a
    bitmap: the same flip (y down, origin at the top's x and y), the context in
    the TOP field's pointer slot, handed down to every descendant (Tony, step 4
    R0: step 1's finding covers the children's slots only). So drawWalk and
    the fill and border floors draw into it unchanged. closePDF ends the page,
    closes the file, and clears the top's slot so nothing reads a released
    context. readPDF draws page 1 into a fresh bitmap held by the request
    itself, the page's own size, so pixelAt reads it as it reads the display.
*****************************************************************************/
extern "C" GroupItem *openPDF(GroupItem *request)
{
	
	if (!request) return 0;
	GroupItem *pathF = request->get("path"), *formF = request->get("form");
	GroupItem *wF = request->get("width"), *hF = request->get("height");
	GroupItem *top = (formF && isGROUP(formF->groupBody->flags.data)) ? formF->getGroup() : 0;
	char *path = pathF ? pathF->getText() : 0;
	double w = wF ? wF->getNumber() : 0, h = hF ? hF->getNumber() : 0;
	if (!path || !*path || !top || w < 1 || h < 1) {
	::fprintf(stderr,"openPDF: REFUSING %s -- needs path, form:= its top field, and width and height\n", request->groupBody->tag);
	return 0; }
	CFURLRef url = CFURLCreateFromFileSystemRepresentation(0, (const UInt8*)path, ::strlen(path), false);
	CGRect   box = CGRectMake(0, 0, w, h);
	CGContextRef ctx = url ? CGPDFContextCreateWithURL(url, &box, 0) : 0;
	if (url) CFRelease(url);
	if (!ctx) {
	::fprintf(stderr,"openPDF: REFUSING %s -- could not create %s\n", request->groupBody->tag, path);
	return 0; }
	CGPDFContextBeginPage(ctx, 0);
	NSRect framed = ::getFrame(top);
	CGContextTranslateCTM(ctx, 0, h);
	CGContextScaleCTM(ctx, 1, -1);
	CGContextTranslateCTM(ctx, -framed.origin.x, -framed.origin.y);
	top->setPointer((void*)ctx);
	handDisplay(top, top);
	
	return request;
}

/*****************************************************************************
    pixelAt — THE POP'S EYES. Reads one pixel back out of the bitmap and
    prints its RGBA, so the interpreted half of DS-4 is verified BY PIXEL and
    not by exit 0. Reads px/py attributes off the field.

    Presence-with-value (H4): it prints the four components every time it is
    called, so a check compares numbers rather than noting that no error
    appeared.
*****************************************************************************/
extern "C" GroupItem *pixelAt(GroupItem *field)
{
	
	/*  px/py are fetched IN HERE for bear-trap #13's reason -- declared at
	incant level and referenced only inside a passthrough, tok prunes them.
	It pruned exactly one of the pair on the previous pass, which is the
	nastiest form of this trap: the survivor makes the block look wired.  */
	GroupItem   *px = field->get("px");
	GroupItem   *py = field->get("py");
	GroupItem   *top = displayOf(field);
	CGContextRef ctx = top ? (CGContextRef)top->getPointer() : 0;
	if (!ctx) { ::fprintf(stderr,"pixelAt: no display on %s\n", field->groupBody->tag); return 0; }
	unsigned char *data = (unsigned char*)CGBitmapContextGetData(ctx);
	size_t rowBytes = CGBitmapContextGetBytesPerRow(ctx);
	size_t h        = CGBitmapContextGetHeight(ctx);
	size_t w        = CGBitmapContextGetWidth(ctx);
	int    ix = px ? (int)px->getNumber() : 0;
	int    iy = py ? (int)py->getNumber() : 0;
	//  bothAxes x past the width would read the next row's pixel: refused as y is (forms step 4 R1)
	if (!data || ix < 0 || iy < 0 || (size_t)iy >= h || (size_t)ix >= w) {
	::fprintf(stderr,"pixelAt: %s (%d,%d) OUT OF RANGE\n", field->groupBody->tag, ix, iy);
	return 0; }
	unsigned char *p = data + (size_t)iy * rowBytes + (size_t)ix * 4;
	::printf("=== pixelAt %s (%d,%d) = r%d g%d b%d a%d ===\n",
	field->groupBody->tag, ix, iy, p[0], p[1], p[2], p[3]);
	::fflush(stdout);
	
	return field;
}

extern "C" GroupItem *readPDF(GroupItem *request)
{
	
	if (!request) return 0;
	GroupItem *pathF = request->get("path");
	char *path = pathF ? pathF->getText() : 0;
	if (!path || !*path) {
	::fprintf(stderr,"readPDF: REFUSING %s -- needs path\n", request->groupBody->tag);
	return 0; }
	CFURLRef url = CFURLCreateFromFileSystemRepresentation(0, (const UInt8*)path, ::strlen(path), false);
	CGPDFDocumentRef doc = url ? CGPDFDocumentCreateWithURL(url) : 0;
	if (url) CFRelease(url);
	CGPDFPageRef page = doc ? CGPDFDocumentGetPage(doc, 1) : 0;
	if (!page) {
	::fprintf(stderr,"readPDF: REFUSING %s -- no readable page 1 in %s\n", request->groupBody->tag, path);
	if (doc) CGPDFDocumentRelease(doc);
	return 0; }
	CGRect box = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
	int w = (int)box.size.width, h = (int)box.size.height;
	CGColorSpaceRef cs  = CGColorSpaceCreateDeviceRGB();
	CGContextRef    ctx = CGBitmapContextCreate(0, w, h, 8, 0, cs, kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(cs);
	if (!ctx) {
	::fprintf(stderr,"readPDF: REFUSING %s -- CGBitmapContextCreate failed\n", request->groupBody->tag);
	CGPDFDocumentRelease(doc);
	return 0; }
	CGContextDrawPDFPage(ctx, page);
	::printf("=== readPDF %s pages %d size %dx%d ===\n", request->groupBody->tag, (int)CGPDFDocumentGetNumberOfPages(doc), w, h);
	::fflush(stdout);
	CGPDFDocumentRelease(doc);
	request->setPointer((void*)ctx);
	
	return request;
}

/*****************************************************************************
    displayFillRT — THE SPECIMEN, and the runtime half of it.

    Fills the field's own frame rect with its own `fill`, or else with the
    fillColor of the style it names. Nothing else: no pen, no text, no path, no clip.

    NAMED displayFill AND NOT `fill`, AND THAT IS BEAR-TRAP #17 AND NOT TASTE.
    `fill()` is in ~/data/support/Include/OCframe -- the shared cross-project
    TAWK keyword/alias table -- so a bare `fill` would be silently claimed by
    the alias table the moment both were live in one pass, mis-generating into
    an Apple selector with no diagnostic until the C++ compile.
*****************************************************************************/
extern "C" GroupItem *styleComponent(GroupItem *field, char *component)
{
GroupItem 	*style = field->get("style");
GroupItem 	*node = 0;
	if ( !style )
		return 0;
	node = GroupControl::groupController->locate(style->getText());
	if ( !node )
		{
		::fprintf(stderr,"styleComponent: %s names style %s which does not resolve\n",field->groupBody->tag,style->getText());
		return 0;
		}
	return node->get(component);
}

/*****************************************************************************
	Print utilities
*****************************************************************************/
char *toString(NSPoint p)
{
char 	*text = 0;
	text = ::concat(3,::toStringFromDouble(p.x),",",::toStringFromDouble(p.y));
	return text;
}

char *toString(NSRect f)
{
char 	*text = 0;
	text = ::concat(5,::toString(f.origin),",",::toStringFromDouble(f.size.width),",",::toStringFromDouble(f.size.height));
	return text;
}
/*	Warning: the following methods were referenced but not declared
	getColor(char*)
*/
