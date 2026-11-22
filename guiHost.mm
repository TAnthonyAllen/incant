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

    windowOffscreen(field): the same window, never shown -- no focus taken,
    no dock icon, no run loop; it finishes launching, drains the events
    waiting, and returns. The fleet's door (incant/pop/windowGcT).
    windowRootProbe: what the collector still scans (below).

    This file is compiled directly by the Xcode Groups target — it is NOT
    included via GroupRules.twk and never goes through tok.
***************************************************************************/
#import <Cocoa/Cocoa.h>
#import <stdio.h>
#import <mach-o/dyld.h>
#import "gc/gc.h"   // quoted: Groups/include (bdw-gc 8.3.0, the library this links), never /usr/local/include (seal 298, SEQ 505)
#import "OCroutines.h"
#import "GroupItem.h"
#import "GroupControl.h"
#import "GroupDraw.h"
#import "Layout.h"

/***************************************************************************
    THE ROOT PROBE (windows stroke 0, F-153) -- measures what the collector
    still scans. Four sets of 8 collectable blocks, each block with a
    finalizer that fills it with 0xDE: one set held ONLY by raw-pointer
    globals of this image in bss, one by globals in data (the question), one
    only by hidden pointers (the known-bad end), one by an uncollectable
    array (the known-good end). One collection, then one stderr line saying
    how many of each set were kept.
    READING IT: the collector is conservative, so a stray word on the stack
    can keep a block nothing else holds -- "kept" can be an accident, a filled
    block cannot. Scanned globals therefore read kept 8 of 8, always; globals
    NOT scanned read fewer than 8 (measured: 0 of 8 on 15 runs of 15).
***************************************************************************/
enum { kProbeN = 8 };
static void *gRootProbeBss[kProbeN];                                    // zero-initialised: __DATA,__bss
static void *gRootProbeData[kProbeN] = { (void *)1, (void *)1, (void *)1, (void *)1, (void *)1, (void *)1, (void *)1, (void *)1 };   // __DATA,__data
static GC_hidden_pointer gRootProbeH[4][kProbeN];
static void **gRootProbeGood;

static void rootProbeFill(void *obj, void *) { memset(obj, 0xDE, 64); }

static __attribute__((noinline)) GC_hidden_pointer rootProbeBlock(void **holder)
{
    void *p = GC_malloc(64);
    memset(p, 0x11, 64);
    GC_register_finalizer_no_order(p, rootProbeFill, 0, 0, 0);
    if ( holder ) *holder = p;
    return GC_HIDE_POINTER(p);
}

static __attribute__((noinline)) void rootProbeAllocate()
{
    if ( !gRootProbeGood ) gRootProbeGood = (void **)GC_MALLOC_UNCOLLECTABLE(sizeof(void *) * kProbeN);
    for (int i = 0; i < kProbeN; i++) {
        gRootProbeH[0][i] = rootProbeBlock(&gRootProbeBss[i]);
        gRootProbeH[1][i] = rootProbeBlock(&gRootProbeData[i]);
        gRootProbeH[2][i] = rootProbeBlock(0);
        gRootProbeH[3][i] = rootProbeBlock(&gRootProbeGood[i]); }
}

//  scrub overwrite the stack the allocation used, so no stale copy of a block's address is left for the collector to find
static __attribute__((noinline)) void rootProbeScrub()
{
    volatile char pad[4096];
    for (int i = 0; i < 4096; i++) pad[i] = 0;
}

static int rootProbeKept(int set)
{
    int kept = 0;
    for (int i = 0; i < kProbeN; i++) {
        unsigned char *q = (unsigned char *)GC_REVEAL_POINTER(gRootProbeH[set][i]);
        if ( !(q[0] == 0xDE && q[63] == 0xDE) ) kept++; }
    return kept;
}

extern "C" GroupItem *windowRootProbe(GroupItem *input)
{
    rootProbeAllocate();
    rootProbeScrub();
    GC_gcollect();
    GC_invoke_finalizers();
    fprintf(stderr, "=== rootProbe: no_dls %d; of %d blocks each, kept: by bss globals %d; by data globals %d; hidden (bad end) %d; uncollectable (good end) %d ===\n",
            GC_get_no_dls(), (int)kProbeN, rootProbeKept(0), rootProbeKept(1), rootProbeKept(2), rootProbeKept(3));
    return input;
}

/***************************************************************************
    makeWindow: everything openWindow does up to the run loop. visible=false
    (windowOffscreen) never orders the window front.

    THE COLLECTOR (F-153, measured 2026-11-22, windows stroke 0).
    GC_set_no_dls(1) was put here to dodge AppKit's framework-load root-set
    storm ("Too many root sets"). It stops the collector registering the data
    segments of images loaded FROM THEN ON; the roots it already holds stay,
    this image's globals among them (windowRootProbe: a block held only by a
    global of ours reads kept under the open window). The comment that stood
    here said the switch blinds the collector to our own data segment; that
    was read, never run, and is not so on this library (bdw-gc 8.3.0).
    The controller is still rooted by hand and the form is still held in an
    uncollectable cell: a Layout is an Objective-C object in malloc memory,
    never scanned, so a form reachable only through view->base would be
    collected under the window (SEQ 589). One word per window, never freed.

    Environment switches, inert when unset, measurement only:
      WINDOW_CLEAR_ROOTS  drop every static root, then root the controller:
                          the state F-153 feared. The probe must then read
                          COLLECTED -- the fleet row's negative control.
      WINDOW_KEEP_DLS     skip GC_set_no_dls. Offscreen, 197 more images
                          load and nothing aborts (2026-11-22); a visible
                          run has not been tried (docs/cleanupList.md).
      WINDOW_IMAGES       print the loaded-image count before and after.
***************************************************************************/
static Layout *makeWindow(GroupItem *input, bool visible)
{
    if ( !getenv("WINDOW_KEEP_DLS") ) GC_set_no_dls(1);
    if ( getenv("WINDOW_CLEAR_ROOTS") ) GC_clear_roots();
    GC_add_roots((char *)&GroupControl::groupController,
                 (char *)&GroupControl::groupController + sizeof(GroupControl *));
    GroupItem **heldForm = (GroupItem **)GC_MALLOC_UNCOLLECTABLE(sizeof(GroupItem *));
    *heldForm = input;
    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:(visible ? NSApplicationActivationPolicyRegular : NSApplicationActivationPolicyProhibited)];
    NSRect content = getFrame(input);
    NSRect scr = [[NSScreen mainScreen] frame];
    if ( visible )
        printf("incant window: getFrame(form) -> %g x %g at (%g,%g)  [screen %g x %g]\n",
               content.size.width, content.size.height,
               content.origin.x, content.origin.y,
               scr.size.width, scr.size.height);
    content.origin.y = scr.size.height - content.origin.y - content.size.height;
    NSWindow *win = [[NSWindow alloc]
        initWithContentRect:content
        styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
        backing:NSBackingStoreBuffered
        defer:(visible ? NO : YES)];
    [win setReleasedWhenClosed:NO];
    [win setTitle:@"incant"];
    Layout *view = [[Layout alloc] initWithFrame:NSMakeRect(0, 0, content.size.width, content.size.height)];
    view->base = input;
    [win setContentView:view];
    return view;
}

extern "C" GroupItem *windowOffscreen(GroupItem *input)
{
    @autoreleasepool {
        unsigned before = _dyld_image_count();
        Layout *view = makeWindow(input, false);
        [NSApp finishLaunching];
        NSEvent *e;
        while ( (e = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES]) ) [NSApp sendEvent:e];
        fprintf(stderr, "=== windowOffscreen: a window %g x %g, not shown ===\n",
                [view frame].size.width, [view frame].size.height);
        if ( getenv("WINDOW_IMAGES") ) fprintf(stderr, "=== windowOffscreen: images loaded %u before, %u after ===\n", before, _dyld_image_count());
    }
    return input;
}

extern "C" GroupItem *openWindow(GroupItem *input)
{
    @autoreleasepool {
        Layout *view = makeWindow(input, true);
        NSWindow *win = [view window];
        [win makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];
        [[NSNotificationCenter defaultCenter]
            addObserverForName:NSWindowWillCloseNotification
            object:win queue:nil
            usingBlock:^(NSNotification *note){ [NSApp terminate:nil]; }];
        printf("incant window: created (native .mm), entering run loop\n");
        [NSApp run];
    }
    return input;
}
