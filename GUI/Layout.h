@class NSView;
class GroupItem;
@class WKWebView;
@class NSURL;
class Details;
class Stak;
@class NSEvent;
@class WKNavigation;
@class NSError;
/*******************************************************************************
	Layout view
*******************************************************************************/
@interface Layout : NSView <WKNavigationDelegate>
{
@public
GroupItem *activeMenu;
GroupItem *base;
GroupItem *storage;
GroupItem *selection;
WKWebView *webView;
NSURL *stubURL;
Details *detail;
Stak *displayStack;
BOOL debug;
BOOL drawn;
BOOL firstTimeThru;
BOOL hasVariableContent;
BOOL isKeyEvent;
BOOL laidout;
BOOL noSelectSource;
BOOL notSelectable;
BOOL paging;
BOOL resized;
}
- (void)deselect;
- (void)displayImage:(char*)text;
- (void)drawRect:(NSRect)r;
- (void)fireAction:(GroupItem*)block event:(NSEvent*)event flag:(int)flag;
- (Layout*)init:(NSRect)f;
- (NSPoint)invertY:(NSPoint)point;
- (void)keyUp:(NSEvent*)event;
- (void)mouseUp:(NSEvent*)event;
- (void)rightMouseUp:(NSEvent*)event;
- (void)scrollWheel:(NSEvent*)event;
- (int)select:(GroupItem*)block;
- (void)viewDidEndLiveResize;
- (void)webView:(WKWebView*)view didFinishNavigation:(WKNavigation*)didFinishNavigation;
- (void)webView:(WKWebView*)view didFailNavigation:(WKNavigation*)didFailNavigation withError:(NSError*)withError;
@end
