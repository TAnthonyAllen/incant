#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "GroupBody.h"
#include "Layout.h"
#include "Stylish.h"
#include "GroupDraw.h"

/*******************************************************************************
	blockContaining now lives in Stylish.twk (2026-07-02 dedup — was defined
    twice, causing a duplicate-symbol link error; Stylish's version is current).
*******************************************************************************/
/*****************************************************************************
	Check if point is in the frame defined here. Edges do not count.
*****************************************************************************/
extern "C" int containsPoint(GroupItem *grup, NSPoint p)
{
NSRect 	frame = ::getFrame(grup);
	if ( p.y > frame.origin.y && p.y < frame.origin.y + frame.size.height && p.x > frame.origin.x && p.x < frame.origin.x + frame.size.width )
		return 1;
	return 0;
}

/*****************************************************************************
    displayFillRT — THE SPECIMEN, and the runtime half of it.

    Fills the field's own frame rect with the colour its `style` attribute
    names. Nothing else: no pen, no text, no path, no clip.

    NAMED displayFill AND NOT `fill`, AND THAT IS BEAR-TRAP #17 AND NOT TASTE.
    `fill()` is in ~/data/support/Include/OCframe -- the shared cross-project
    TAWK keyword/alias table -- so a bare `fill` would be silently claimed by
    the alias table the moment both were live in one pass, mis-generating into
    an Apple selector with no diagnostic until the C++ compile.
*****************************************************************************/
extern "C" GroupItem *displayFillRT(GroupItem *field)
{
GroupItem 	*style = field->get("style");
NSColor 	*colour = 0;
	if ( !field )
		return 0;
	if ( !style )
		{
		::fprintf(stderr,"displayFill: REFUSING %s -- no style attribute to take a colour from\n",field->groupBody->tag);
		return 0;
		}
	colour = getColor(style->getText());
	if ( !colour )
		{
		::fprintf(stderr,"displayFill: REFUSING %s -- style names no colour that could be realised\n",field->groupBody->tag);
		return 0;
		}
	
	NSRect       framed = ::getFrame(field);
	CGContextRef ctx    = (CGContextRef)field->getPointer();
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

/*******************************************************************************
	Sets the content for and returns TextView to display the field passed in
*******************************************************************************/
extern "C" NSTextView *getTextView(GroupItem *field)
{
NSString 			*atText = 0;
NSAttributedString 	*aString = 0;
NSTextStorage 		*store = 0;
NSTextView 			*editor = 0;
NSRect 				frame = ::getFrame(field);
char 				*txt = field->getText();
	if ( txt )
		{
		if ( isOBJECT(field->groupBody->flags.data) )
			editor = (NSTextView*)field->getObject();
		else	editor = [[NSTextView alloc] initWithFrame:frame];
		atText = [NSString stringWithCString:txt encoding:NSASCIIStringEncoding];
		store = [editor textStorage];
		aString = [[NSAttributedString alloc] initWithString:atText];
		[store setAttributedString:aString];
		}
	return editor;
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

    THE CURRENT-STYLE SLOT IS THE NODE'S `style` ATTRIBUTE, read at draw time.
    Per FR-2a the style is a GroupItem holding components as attributes; this
    increment reads exactly one component (the fill colour) and reads it the way
    the tree already realises colours: the attribute's text names a cOLORs-style
    entry, and getColor does realise-on-first-miss onto its object slot. So the
    answer to DS's opening measurement -- does the slot hand over a realised
    colour or a name needing realisation -- is A NAME, realised once and cached
    on the colour node, never per draw call.

    COORDINATES: CGBitmapContext is origin-bottom-left. guiDesign S10.3 rules
    that Display exposes top-left/y-down and flips internally. This increment
    does NOT flip, and that is a deliberate omission rather than an oversight:
    the flip needs the frame's height to be meaningful and this specimen fills a
    rect it was handed. Named here so the class brief inherits the debt.
*****************************************************************************/
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
	field->setPointer((void*)ctx);
	
	return field;
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
	CGContextRef ctx = (CGContextRef)field->getPointer();
	if (!ctx) { ::fprintf(stderr,"pixelAt: no display on %s\n", field->groupBody->tag); return 0; }
	unsigned char *data = (unsigned char*)CGBitmapContextGetData(ctx);
	size_t rowBytes = CGBitmapContextGetBytesPerRow(ctx);
	size_t h        = CGBitmapContextGetHeight(ctx);
	int    ix = px ? (int)px->getNumber() : 0;
	int    iy = py ? (int)py->getNumber() : 0;
	if (!data || ix < 0 || iy < 0 || (size_t)iy >= h) {
	::fprintf(stderr,"pixelAt: %s (%d,%d) OUT OF RANGE\n", field->groupBody->tag, ix, iy);
	return 0; }
	unsigned char *p = data + (size_t)iy * rowBytes + (size_t)ix * 4;
	::printf("=== pixelAt %s (%d,%d) = r%d g%d b%d a%d ===\n",
	field->groupBody->tag, ix, iy, p[0], p[1], p[2], p[3]);
	::fflush(stdout);
	
	return field;
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

/*******************************************************************************
	Set up a window or pane
*******************************************************************************/
void GroupDraw::setWindow(GroupItem *block)
{
NSWindow 	*window = 0;
NSRect 		framed = ::getFrame(block);
NSRect 		windowFrame;
int 		mask = 0;
NSView 		*view = 0;
	if ( block->get("closable") )
		mask |= NSClosableWindowMask;
	if ( block->get("title") )
		mask |= NSTitledWindowMask;
	if ( block->get("resize") )
		mask |= NSResizableWindowMask;
	if ( block->get("panel") )
		{
		NSPanel 	*pane = (NSPanel*)[[NSWindow alloc] initWithContentRect:framed styleMask:mask backing:NSBackingStoreBuffered defer:1];
		window = pane;
		block->setObject((NSObject*)pane);
		}
	else {
		window = [[NSWindow alloc] initWithContentRect:framed styleMask:mask backing:NSBackingStoreBuffered defer:1];
		block->setObject((NSObject*)window);
		}
	view = [window contentView];
	windowFrame = [window frame];
	//layout      = new(framed);
	//layout.base = block;
	framed.size.height += windowFrame.size.height - [view frame].size.height;
	[window setFrame:framed display:0];
	[window setContentView:layout];
	if ( mask & NSTitledWindowMask )
		[window setTitle:[NSString stringWithCString:block->getText() encoding:NSASCIIStringEncoding]];
	[window makeKeyAndOrderFront:nil];
	[view setNeedsDisplay:1];
}
/*	Warning: the following methods were referenced but not declared
	getColor(char*)
*/
