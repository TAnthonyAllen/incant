@class NSView;
class GroupItem;
@class NSBezierPath;
@class NSNotification;
/*******************************************************************************
	Layout view
*******************************************************************************/
@interface Layout : NSView <NSWindowDelegate>
{
@public
GroupItem *base;
GroupItem *selection;
NSBezierPath *layoutPath;
}
- (void)drawRect:(NSRect)r;
- (Layout*)init:(GroupItem*)field;
- (NSPoint)invertY:(NSPoint)point;
- (void)viewDidEndLiveResize;
- (void)windowWillClose:(NSNotification*)notification;
@end
