@class NSView;
class GroupItem;
@class NSBezierPath;
@class NSColor;
@class NSFont;
@class NSTextFieldCell;
@class NSTextField;
class Stylish;
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
NSColor *strokeColor;
NSColor *textColor;
NSColor *wallColor;
NSFont *currentFont;
NSTextFieldCell *cell;
NSTextField *textField;
Stylish *style;
}
- (void)displayCell;
- (void)displayImage;
- (void)displayText;
- (void)drawRect:(NSRect)r;
- (Layout*)init:(GroupItem*)field;
- (NSPoint)invertY:(NSPoint)point;
- (void)viewDidEndLiveResize;
- (void)windowWillClose:(NSNotification*)notification;
@end
