@class NSObject;
@class WKWebView;
@class WKNavigation;
@class NSError;
@class NSNotification;
/*******************************************************************************
	A class to delegate
*******************************************************************************/
@interface Delegate : NSObject <WKNavigationDelegate,NSWindowDelegate>
{
@public
}
- (Delegate*)init;
- (void)webView:(WKWebView*)view didFinishNavigation:(WKNavigation*)didFinishNavigation;
- (void)webView:(WKWebView*)view didFailNavigation:(WKNavigation*)didFailNavigation withError:(NSError*)withError;
- (void)windowDidEndLiveResize;
- (void)windowWillClose:(NSNotification*)n;
@end
