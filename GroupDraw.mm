#include <Cocoa/Cocoa.h>
#include <string.h>
#include <stdio.h>
#include "OCroutines.h"
#include "StringRoutines.h"
#include "GroupItem.h"
#include "GroupBody.h"
#include "Layout.h"
#include "GroupDraw.h"

/*******************************************************************************
	Return the lowest descendent block that contains the point passed in.
    Assumes the group passed in contains the point.
*******************************************************************************/
extern "C" GroupItem *blockContaining(GroupItem *grup, NSPoint p)
{
GroupItem 	*item = 0;
GroupItem 	*group = 0;
	if ( grup && ::containsPoint(grup,p) )
		{
		//cout "blockContaining",base.tag,frame,"Point:",p.x,p.y:;
		while ( item = grup->nextMember(item) )
			if ( ::containsPoint(item,p) )
				break;
		if ( item && item->groupBody->flags.hasMembers )
			if ( group = ::blockContaining(item,p) )
				return group;
		}
	return item;
}

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
GroupDraw *GroupDraw::drawer;

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
	layout = [[Layout alloc] init:framed];
	layout->base = block;
	framed.size.height += windowFrame.size.height - [view frame].size.height;
	[window setFrame:framed display:0];
	[window setContentView:layout];
	if ( mask & NSTitledWindowMask )
		[window setTitle:[NSString stringWithCString:block->getText() encoding:NSASCIIStringEncoding]];
	[window makeKeyAndOrderFront:nil];
	[view setNeedsDisplay:1];
}
