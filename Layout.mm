#import <Cocoa/Cocoa.h>
#import <string.h>
#import <stdio.h>
#import <stdlib.h>
#import "OCroutines.h"
#import "GroupItem.h"
#import "Layout.h"

@implementation Layout

- (void)drawRect:(NSRect)r
{
	::printf("drawRect: not written yet\n");
}

- (Layout*)init:(NSRect)f
{
	[self frame] = f;
	layoutPath = [NSBezierPath bezierPath];
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
	::printf("Layout keyUp\n");
}

- (void)mouseUp:(NSEvent*)event
{
	::printf("Layout mouseUp\n");
}

- (void)rightMouseUp:(NSEvent*)event
{
	::printf("Layout rightMouseUp\n");
}

- (void)scrollWheel:(NSEvent*)event
{
double 	delta = 0;
int 	down = 0;
int 	length = 0;
	//paging  = false;
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
	/***************************************************************************
	HPDL
	Point		point = convertPoint(mouseAt(),nil);
	GroupItem   block;
	if selection
	selection.scrollBlock(length,1);
	or block = base.blockContaining(point)
	block.scrollBlock(length,1);
	***************************************************************************/
}

- (void)viewDidEndLiveResize
{
	::printf("View End resize\n");
	[self setFrame:[[self superview] frame]];
	//base.updateFrame(frame);
	[self drawRect:[self frame]];
}

- (void)windowWillClose:(NSNotification*)notification
{
	::printf("Window closing: will exit\n");
	::exit(0);
}
@end
