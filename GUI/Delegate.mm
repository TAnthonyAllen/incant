#import <Cocoa/Cocoa.h>
#import <stdlib.h>
#import <WebKit/WebKit.h>
#import <string.h>
#import <stdio.h>
#import "GroupItem.h"
#import "OCroutines.h"
#import "Control.h"
#import "Details.h"
#import "Bwana.h"
#import "Layout.h"
#import "Delegate.h"

@implementation Delegate

- (Delegate*)init
{
	::printf("initializing delegates\n");
	return self;
}

- (void)webView:(WKWebView*)view didFinishNavigation:(WKNavigation*)didFinishNavigation
{
	::printf("Loaded web content\n");
}

- (void)webView:(WKWebView*)view didFailNavigation:(WKNavigation*)didFailNavigation withError:(NSError*)withError
{
int 	errorCode = (int)[withError code];
char 	*errorText = ::toString([withError localizedDescription]);
	::printf("Got web content error %d %s\n",errorCode,errorText);
}

- (void)windowDidEndLiveResize
{
	::printf("Window End resize\n");
}

- (void)windowWillClose:(NSNotification*)n
{
	::printf("Window closed\n");
	::setNoRoom(Control::bwana->controller->activeView->base,(unsigned int)1);
	Control::bwana->controller->activeView->drawn = 0;
	if ( Control::bwana->controller->activeView->base == Control::bwana->controller->root )
		{
		::printf("Bailing\n");
		::exit(0);
		}
}
@end
