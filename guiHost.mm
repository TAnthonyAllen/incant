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
#import "GroupControl.h"
#import "GroupDraw.h"
#import "Layout.h"

extern "C" GroupItem *openWindow(GroupItem *input)
{
    GC_set_no_dls(1);
    /* GC_set_no_dls skips ALL data segments — needed to dodge AppKit's
       framework-load root-set storm ("Too many root sets" abort), but it also
       blinds BDWGC to incant's OWN data segment. Re-root incant's object graph
       via the singleton controller (one root set, no table overflow) so the
       form passed in (and its whole tree) survives the long [app run] loop —
       otherwise it gets collected mid-run and drawRect derefs freed memory. */
    GC_add_roots((char *)&GroupControl::groupController,
                 (char *)&GroupControl::groupController + sizeof(GroupControl *));
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        NSRect content = getFrame(input);
        NSRect scr = [[NSScreen mainScreen] frame];
        printf("incant window: getFrame(form) -> %g x %g at (%g,%g)  [screen %g x %g]\n",
               content.size.width, content.size.height,
               content.origin.x, content.origin.y,
               scr.size.width, scr.size.height);
        /* Forms use top-left origin (y down); Cocoa screen coords are
           bottom-left (y up). Flip so the form's y means "from the top". */
        content.origin.y = scr.size.height - content.origin.y - content.size.height;
        NSWindow *win = [[NSWindow alloc]
            initWithContentRect:content
            styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
            backing:NSBackingStoreBuffered
            defer:NO];
        [win setReleasedWhenClosed:NO];
        [win setTitle:@"incant"];
        Layout *view = [[Layout alloc] initWithFrame:NSMakeRect(0, 0, content.size.width, content.size.height)];
        view->base = input;
        [win setContentView:view];
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
