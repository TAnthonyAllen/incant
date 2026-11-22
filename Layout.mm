#import <Cocoa/Cocoa.h>
#import <string.h>
#import <stdio.h>
#import <stdlib.h>
#import "OCroutines.h"
#import "GroupItem.h"
#import "Stylish.h"
#import "GroupDraw.h"
#import "Layout.h"

@implementation Layout

- (void)drawRect:(NSRect)r
{
	
	void windowDrawForm(GroupItem *top, double height);
	windowDrawForm(base, [self bounds].size.height);
	
}

- (Layout*)init:(GroupItem*)field
{
	base = field;
	layoutPath = [NSBezierPath bezierPath];
	return self;
}

- (NSPoint)invertY:(NSPoint)point
{
double 	baseY = [self frame].size.height - point.y;
	point.y = baseY;
	return point;
}

- (void)viewDidEndLiveResize
{
	::printf("View End resize\n");
	[self setFrame:[[self superview] frame]];
	//base.updateFrame(frame);
	[self setNeedsDisplay:1];
}

- (void)windowWillClose:(NSNotification*)notification
{
	::printf("Window closing: will exit\n");
	::exit(0);
}
@end
