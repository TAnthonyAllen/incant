#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <stdlib.h>
#import <string.h>
#import <stdio.h>
#import "GroupItem.h"
#import "OCroutines.h"
#import "Control.h"
#import "GroupControl.h"
#import "PLGparse.h"
#import "Details.h"
#import "Bwana.h"
#import "Stak.h"
#import "ParseXML.h"
#import "PLGitem.h"
#import "Source.h"
#import "Stylish.h"
#import "Layout.h"

@implementation Layout

- (void)deselect
{
Details 	*selectDetail = 0;
	if ( selection )
		{
		selectDetail = ::getDetail(selection);
		if ( selectDetail->style && (selectDetail->style->selectFill || selectDetail->style->selectStroke) )
			{
			if ( selectDetail->style->filler && selectDetail->style->selectFill )
				{
				storage->setDataFrom(selectDetail->style->filler);
				selectDetail->style->filler->setDataFrom(selectDetail->style->selectFill);
				selectDetail->style->selectFill->setDataFrom(storage);
				}
			if ( selectDetail->style->stroker && selectDetail->style->selectStroke )
				{
				storage->setDataFrom(selectDetail->style->stroker);
				selectDetail->style->stroker->setDataFrom(selectDetail->style->selectStroke);
				selectDetail->style->selectStroke->setDataFrom(storage);
				}
			::setModified(selection);
			//if filler cout `"Deselect:",selection.tag,filler.getTagXML() :;
			}
		if ( selectDetail->isTab )
			return;
		selection->processUpTo = 0;
		selection = 0;
		}
}

- (void)displayImage:(char*)text
{
GroupItem 	*scale = 0;
GroupItem 	*origin = 0;
GroupItem 	*offset = 0;
NSRect 		imageFrame;
NSRect 		adjustedFrame;
NSString 	*fileName = 0;
NSImage 	*image = 0;
NSPoint 	*atOffset = 0;
NSPoint 	*atOrigin = 0;
double 		hp = 0;
double 		wp = 0;
double 		factor = 0;
	adjustedFrame = detail->frame;
	adjustedFrame.origin.y = [self frame].size.height - adjustedFrame.origin.y;
	fileName = [NSString stringWithCString:text encoding:NSASCIIStringEncoding];
	if ( GroupControl::groupController->groupParser->isURL(text) )
		{
		NSURL 	*url = [NSURL URLWithString:fileName];
		image = [[NSImage alloc] initByReferencingURL:url];
		}
	else	image = [[NSImage alloc] initByReferencingFile:fileName];
	if ( origin = detail->wig->get("oRIGIn") )
		atOrigin = (NSPoint*)origin->getPointer();
	else {
		atOrigin = (NSPoint*)::calloc(1,sizeof(NSPoint));
		origin = detail->wig->addAttrValue("oRIGIn",(void*)atOrigin);
		}
	imageFrame.origin.x = atOrigin->x;
	imageFrame.origin.y = atOrigin->y;
	imageFrame.size = [image size];
	if ( offset = detail->wig->get("oFFSEt") )
		atOffset = (NSPoint*)offset->getPointer();
	if ( offset && offset->fLAG )
		offset->fLAG = 0;
	else {
		if ( scale = detail->wig->get("sCALe") )
			factor = scale->getNumber();
		hp = adjustedFrame.size.height / imageFrame.size.height;
		wp = adjustedFrame.size.width / imageFrame.size.width;
		if ( hp < wp )
			hp = wp;
		if ( factor )
			hp *= factor;
		imageFrame.size.height *= hp;
		imageFrame.size.width *= hp;
		if ( imageFrame.size.width > adjustedFrame.size.width )
			imageFrame.origin.x = (imageFrame.size.width - adjustedFrame.size.width) / 2;
		if ( imageFrame.size.height > adjustedFrame.size.height )
			imageFrame.origin.y = (imageFrame.size.height - adjustedFrame.size.height) / 2;
		[image setSize:imageFrame.size];
		atOrigin->x = imageFrame.origin.x;
		atOrigin->y = imageFrame.origin.y;
		}
	if ( atOffset )
		{
		if ( atOffset->x + adjustedFrame.size.width > imageFrame.size.width )
			imageFrame.origin.x = imageFrame.size.width - adjustedFrame.size.width;
		else	imageFrame.origin.x += atOffset->x;
		if ( atOffset->y + adjustedFrame.size.height > imageFrame.size.height )
			imageFrame.origin.y = imageFrame.size.height - adjustedFrame.size.height;
		else	imageFrame.origin.y += atOffset->y;
		}
	[image setBackgroundColor:[NSColor blackColor]];
	imageFrame.size = adjustedFrame.size;
	[image drawInRect:adjustedFrame fromRect:imageFrame operation:NSCompositeSourceOver fraction:1.0];
	//cout `"Frames",adjustedFrame``imageFrame :;
	//image.drawIn(adjustedFrame);
}

- (void)drawRect:(NSRect)r
{
GroupItem 	*group = 0;
GroupItem 	*item = 0;
	[webView setFrame:r];
	::printf("drawRect:\n");
	if ( !laidout )
		Control::bwana->controller->layout(base);
	if ( !drawn )
		{
		item = base->copy();
		if ( debug )
			::printf("%s\n",item->toString());
		item->reset();
		GroupControl::groupController->groupParser->isRigorous = 1;
		group = Control::bwana->controller->makeCanvas(item);
		group->affiliation = 0;
		if ( group )
			{
			char 	*htmlText = group->toString();
			if ( !stubURL )
				stubURL = [[NSURL alloc] initWithString:[NSString stringWithCString:Control::bwana->controller->baseURL->getText() encoding:NSASCIIStringEncoding]];
			if ( htmlText && stubURL )
				[webView loadHTMLString:[NSString stringWithCString:htmlText encoding:NSASCIIStringEncoding] baseURL:stubURL];
			}
		/***************************************************************************
		saveGS();
		if displayStack.length
		while group = displayStack.next()
		{
		detail = group.getDetail();
		displayImage(group.text);
		}
		restoreGS();
		***************************************************************************/
		GroupControl::groupController->groupParser->isRigorous = 0;
		drawn = 1;
		}
}

- (void)fireAction:(GroupItem*)block event:(NSEvent*)event flag:(int)flag
{
GroupItem 	*group = 0;
GroupItem 	*action = 0;
Details 	*blockDetail = 0;
int 		actionFlag = 0;
int 		done = 0;
	[self select:block];
	group = block;
	/***************************************************************************
	In case the event is needed, set the event in block details.
	***************************************************************************/
	while ( !done && group )
		{
		blockDetail = ::getDetail(group);
		if ( !blockDetail )
			return;
		blockDetail->event = event;
		if ( (group->methodType == 1) || group->hasActions )
			{
			if ( group->gMethod && flag == group->rightClick && isKeyEvent == group->keyAction )
				{
				group->gMethod(group);
				done = 1;
				}
			/*******************************************************************
			Run multiple attribute actions if they exist
			*******************************************************************/
			if ( group->hasActions )
				while ( action = group->nextAttribute(action) )
					if ( action->gMethod && (action->methodType == 1) )
						{
						if ( !isKeyEvent && flag == action->rightClick && !action->keyAction )
							actionFlag = 1;
						else
						if ( isKeyEvent && action->keyAction && ::keyStrokeMatch(action) )
							actionFlag = 1;
						if ( actionFlag )
							{
							if ( action->parent != group )
								action->parent = group;
							blockDetail = ::getDetail(action);
							blockDetail->event = event;
							action->gMethod(action);
							done = 1;
							actionFlag = 0;
							}
						}
			}
		if ( done && group == activeMenu )
			{
			::setModified(activeMenu);
			activeMenu = 0;
			}
		group = group->parent;
		}
}

- (Layout*)init:(NSRect)f
{
	[self setFrame:f];
	displayStack = new Stak();
	storage = GroupControl::groupController->itemFactory("storage");
	return self;
}

- (NSPoint)invertY:(NSPoint)point
{
double 	baseY = [self frame].size.height - point.y;
	point.y = baseY;
	return point;
}

- (void)keyUp:(NSEvent*)event
{
NSPoint 	point = [self invertY:[Control::bwana->window mouseLocationOutsideOfEventStream]];
int 		code = [event keyCode];
int 		length = 0;
GroupItem 	*group = 0;
	if ( group = selection )
		{
		while ( group && !group->keyAction )
			group = group->parent;
		if ( group )
			{
			isKeyEvent = 1;
			[self fireAction:group event:event flag:0];
			isKeyEvent = 0;
			return;
			}
		group = selection;
		}
	if ( !group )
		group = ::blockContaining(base,point);
	if ( group )
		{
		paging = 0;
		switch (code)
			{
			case 116:
				// page up
				paging = 1;
			case 126:
				// arrow up
				length = 1;
				break;
			case 123:
				// arrow left
				code = 0;
				length = 1;
				break;
			case 121:
				// page down
				paging = 1;
			case 125:
				// arrow down
				length = -1;
				break;
			case 124:
				// arrow right
				code = 0;
				length = -1;
				break;
			default:
				return;
			}
		::scrollBlock(group,length,code);
		}
	else	::fprintf(stderr,"Layout keyUp: could not find containing block at%s\n",::toString(point));
}

- (void)mouseUp:(NSEvent*)event
{
NSPoint 	point = [self convertPoint:[event locationInWindow] fromView:nil];
GroupItem 	*block = 0;
	point = [self invertY:point];
	if ( activeMenu && !(block = ::blockContaining(activeMenu,point)) )
		{
		// turn off the menu
		activeMenu = 0;
		drawn = 0;
		[self setNeedsDisplay:1];
		}
	if ( !block )
		block = ::blockContaining(base,point);
	if ( block )
		[self fireAction:block event:event flag:0];
	else	::printf("mouseUP: %s: Don't know who contains point %g %g\n",base->tag,point.x,point.y);
	[webView mouseUp:event];
}

- (void)rightMouseUp:(NSEvent*)event
{
NSPoint 	point = [self invertY:[self convertPoint:[event locationInWindow] fromView:nil]];
GroupItem 	*block = 0;
	if ( block = ::blockContaining(base,point) )
		[self fireAction:block event:event flag:1];
}

- (void)scrollWheel:(NSEvent*)event
{
NSPoint 	point = [self invertY:[self convertPoint:[event locationInWindow] fromView:nil]];
double 		delta = 0;
int 		down = 0;
int 		length = 0;
GroupItem 	*block = 0;
	paging = 0;
	delta = [event deltaY];
	if ( delta < 0 )
		{
		down = 1;
		length = -delta;
		}
	else	length = delta;
	if ( !length )
		length++;
	if ( down )
		length = -length;
	// if direction is down, length is negative
	if ( selection )
		::scrollBlock(selection,length,1);
	else
	if ( block = ::blockContaining(base,point) )
		::scrollBlock(block,length,1);
}

- (int)select:(GroupItem*)block
{
Details 	*selectionDetail = 0;
Details 	*blockDetail = 0;
GroupItem 	*item = 0;
int 		result = 0;
	if ( block )
		blockDetail = ::getDetail(block);
	if ( !notSelectable )
		{
		if ( block && blockDetail && !block->processUpTo && blockDetail->selectable )
			{
			[self deselect];
			selection = block;
			selectionDetail = blockDetail;
			selection->processUpTo = 1;
			if ( blockDetail->style && (blockDetail->style->selectFill || blockDetail->style->selectStroke) )
				{
				if ( blockDetail->style->filler && blockDetail->style->selectFill )
					{
					storage->setDataFrom(blockDetail->style->filler);
					blockDetail->style->filler->setDataFrom(blockDetail->style->selectFill);
					blockDetail->style->selectFill->setDataFrom(storage);
					}
				if ( blockDetail->style->stroker && blockDetail->style->selectStroke )
					{
					storage->setDataFrom(blockDetail->style->stroker);
					blockDetail->style->stroker->setDataFrom(blockDetail->style->selectStroke);
					blockDetail->style->selectStroke->setDataFrom(storage);
					}
				::setModified(selection);
				}
			result = 1;
			}
		}
	else {
		::printf("Not selectable: %s\n",block->tag);
		if ( item = base->get("describe") )
			item->setText("");
		[self deselect];
		}
	if ( !noSelectSource && selection && result )
		{
		GroupControl::groupController->groupParser->lastSelect = selection;
		if ( (selection->data == 5) )
			Control::bwana->selectSource->setSourceItem(selection->getGroup());
		else	Control::bwana->selectSource->setSourceItem(selection);
		}
	return result;
}

- (void)viewDidEndLiveResize
{
GroupItem 	*group = 0;
NSRect 		windowFrame = [[self window] frame];
	::printf("View End resize\n");
	drawn = 0;
	resized = 1;
	[self setFrame:[[self superview] frame]];
	if ( group = base->getAttribute("x") )
		group->setCount((int)windowFrame.origin.x);
	if ( group = base->getAttribute("y") )
		group->setCount((int)windowFrame.origin.y);
	if ( group = base->getAttribute("height") )
		group->setCount((int)[self frame].size.height);
	if ( group = base->getAttribute("width") )
		group->setCount((int)[self frame].size.width);
	laidout = 0;
	Control::bwana->controller->layout(base);
	[self drawRect:[self frame]];
}

- (void)webView:(WKWebView*)view didFinishNavigation:(WKNavigation*)didFinishNavigation
{
	if ( debug )
		::printf("Layout: Loaded web content\n");
}

- (void)webView:(WKWebView*)view didFailNavigation:(WKNavigation*)didFailNavigation withError:(NSError*)withError
{
int 	errorCode = (int)[withError code];
char 	*errorText = ::toString([withError localizedDescription]);
	::printf("Layout: Got web content error %d %s\n",errorCode,errorText);
}
@end
