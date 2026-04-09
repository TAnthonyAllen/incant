@class NSView;
class GroupItem;
@class NSBezierPath;
@class NSColor;
@class NSFont;
@class NSEvent;
@class NSNotification;
/*******************************************************************************
	Layout view
*******************************************************************************/
@interface Layout : NSView <NSWindowDelegate>
{
@public
GroupItem *base;
GroupItem *fireDraw;
GroupItem *selection;
NSBezierPath *layoutPath;
NSColor *strokeColor;
NSColor *textColor;
NSColor *wallColor;
NSFont *currentFont;
}
- (void)drawRect:(NSRect)r;
- (Layout*)init:(NSRect)f;
- (NSPoint)invertY:(NSPoint)point;
- (void)keyUp:(NSEvent*)event;
- (void)mouseUp:(NSEvent*)event;
- (void)rightMouseUp:(NSEvent*)event;
- (void)scrollWheel:(NSEvent*)event;
- (void)viewDidEndLiveResize;
- (void)windowWillClose:(NSNotification*)notification;
@end
