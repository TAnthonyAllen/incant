#import <Cocoa/Cocoa.h>
#import <string.h>
#import <stdio.h>
#import <stdlib.h>
#import "OCroutines.h"
#import "GroupItem.h"
#import "GroupRules.h"
#import "GroupBody.h"
#import "GroupDraw.h"
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
NSPoint 	point = [[self window] mouseLocationOutsideOfEventStream];
int 		code = [event keyCode];
int 		length = 0;
GroupItem 	*group = 0;
	group = ::blockContaining(base,point);
	if ( group )
		{
		switch (code)
			{
			case 116:
				// page up
				::printf("Page up\n");
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
				::printf("Page down\n");
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
		//scrollBlock(group,length,code);
		}
	else	::fprintf(stderr,"Layout keyUp: could not find containing block at%s\n",::toString(point));
}

- (void)mouseUp:(NSEvent*)event
{
NSPoint 	point = [self convertPoint:[event locationInWindow] fromView:nil];
GroupItem 	*block = ::blockContaining(base,point);
	if ( block )
		::printf("mouseUp: interpret block??\n");
	else	::printf("mouseUp: %s: Don't know who contains point %g %g\n",base->groupBody->tag,point.x,point.y);
}

- (void)rightMouseUp:(NSEvent*)event
{
NSPoint 	point = [self convertPoint:[event locationInWindow] fromView:nil];
GroupItem 	*block = ::blockContaining(base,point);
	if ( block )
		::printf("right mouseUp: interpret block??\n");
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
