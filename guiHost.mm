/***************************************************************************
    GUI host — the minimal Apple shim, hand-written Objective-C++ that
    bypasses tok entirely (tok can't parse inline [bracket] message sends).
    Keep Apple in its lane: open a window, hang a Layout, pump the event
    loop — nothing more. incant does layout/font/color above this; Layout
    paints into the window below it.

    openWindow(field): creates an NSWindow whose contentView is a Layout
    bound (view->base) to the passed-in field, so a setFrame'd field paints
    (Layout.drawRect strokes its frames). Closing the window terminates the
    app. extern "C" so the incant runtime dlsym-binds it
    (registered in incant/setup: openWindow immediateAction=openWindow).

    This file is compiled directly by the Xcode Groups target — it is NOT
    included via GroupRules.twk and never goes through tok.
***************************************************************************/
#import <Cocoa/Cocoa.h>
#import <stdio.h>
#import <gc/gc.h>
#import "OCroutines.h"
#import "GroupItem.h"
#import "Layout.h"

extern "C" GroupItem *openWindow(GroupItem *input)
{
    GC_set_no_dls(1);
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        NSRect content = NSMakeRect(0, 0, 480, 360);
        NSWindow *win = [[NSWindow alloc]
            initWithContentRect:content
            styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
            backing:NSBackingStoreBuffered
            defer:NO];
        [win setReleasedWhenClosed:NO];
        [win setTitle:@"incant"];
        Layout *view = [[Layout alloc] initWithFrame:content];
        view->base = input;
        [win setContentView:view];
        [win center];
        [win makeKeyAndOrderFront:nil];
        [app activateIgnoringOtherApps:YES];
        [[NSNotificationCenter defaultCenter]
            addObserverForName:NSWindowWillCloseNotification
            object:win queue:nil
            usingBlock:^(NSNotification *note){ [NSApp terminate:nil]; }];
        printf("incant window: created (native .mm), entering run loop\n");
        [app run];
    }
    return input;
}
