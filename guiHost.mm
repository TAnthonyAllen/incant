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
#import <vector>
#import <mach-o/dyld.h>
#import "gc/gc.h"   // quoted: Groups/include (bdw-gc 8.3.0, the library this links), never /usr/local/include (seal 298, SEQ 505)
#import "OCroutines.h"
#import "GroupItem.h"
#import "GroupControl.h"
#import "GroupDraw.h"
#import "Layout.h"
#import "GroupBody.h"
#import "GroupRules.h"
#import "Stylish.h"

//  windows every window made, with the cell that keeps its form alive; found by the form's body (a field and its faces share one)
struct WindowRecord { Layout *view; GroupItem **held; };
static std::vector<WindowRecord> gWindows;


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
    NSRect asked = input ? getFrame(input) : NSZeroRect;
    if ( asked.size.width < 1 || asked.size.height < 1 ) {
        fprintf(stderr, "%s: REFUSING %s -- frame is %gx%g; a window needs a laid-out form (what redrawForm or showForm returns)\n",
                visible ? "openWindow" : "windowOffscreen", input ? input->groupBody->tag : "nothing", asked.size.width, asked.size.height);
        return nil; }
    if ( !getenv("WINDOW_KEEP_DLS") ) GC_set_no_dls(1);
    if ( getenv("WINDOW_CLEAR_ROOTS") ) GC_clear_roots();
    GC_add_roots((char *)&GroupControl::groupController,
                 (char *)&GroupControl::groupController + sizeof(GroupControl *));
    GroupItem **heldForm = (GroupItem **)GC_MALLOC_UNCOLLECTABLE(sizeof(GroupItem *));
    *heldForm = input;
    GroupItem *titleF = input ? input->get((char *)"title") : 0;
    char *titled = titleF ? titleF->getText() : 0;
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
    //  title W4 (Tony, 2026-11-22): the title is the form's title=; a form naming none is titled incant, as every window was
    [win setTitle:(titled && *titled) ? [NSString stringWithUTF8String:titled] : @"incant"];
    Layout *view = [[Layout alloc] initWithFrame:NSMakeRect(0, 0, content.size.width, content.size.height)];
    view->base = input;
    [win setContentView:view];
    gWindows.push_back({view, heldForm});
    return view;
}

/***************************************************************************
    THE WINDOW AS A DISPLAY (windows stroke 1). Layout.drawRect calls
    windowDrawForm: the third opener beside makeDisplay (a bitmap) and
    openPDF. It takes the context AppKit is drawing the view into, sets the
    floor's three transforms (y down, origin at the top field's x and y),
    puts the context in the top's pointer slot, hands it down, runs kant's
    drawWalk on the top, and clears the slot again -- the context is
    AppKit's and is gone when drawRect returns.
***************************************************************************/
void windowDrawForm(GroupItem *top, double height)
{
    if ( !top ) return;
    CGContextRef ctx = [[NSGraphicsContext currentContext] CGContext];
    GroupItem *utilities = GroupControl::groupController->getRegistry((char *)"Utilities");
    GroupItem *walk = utilities ? utilities->get((char *)"drawWalk") : 0;
    if ( !ctx || !walk ) {
        fprintf(stderr, "windowDrawForm: REFUSING %s -- %s\n", top->groupBody->tag, ctx ? "no drawWalk in Utilities" : "no drawing context");
        return; }
    NSRect framed = getFrame(top);
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 0, height);
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, -framed.origin.x, -framed.origin.y);
    top->setPointer((void *)ctx);
    handDisplay(top, top);
    runAction(top, walk);
    top->groupBody->gPointer = 0;
    top->groupBody->flags.isPointer = 0;
    CGContextRestoreGState(ctx);
}

static WindowRecord *windowHolding(GroupItem *top)
{
    for ( WindowRecord &w : gWindows )
        if ( top && *w.held && (*w.held)->groupBody == top->groupBody ) return &w;
    return 0;
}

/***************************************************************************
    readWindow(request): form:= the top field a window holds. AppKit draws
    that window's view -- its real drawRect -- into a fresh bitmap the size
    of the view, held by the request itself, so pixelAt reads it as it reads
    readPDF's. Nothing is shown.
***************************************************************************/
extern "C" GroupItem *readWindow(GroupItem *request)
{
    if ( !request ) return 0;
    GroupItem *formF = request->get((char *)"form");
    GroupItem *top = (formF && isGROUP(formF->groupBody->flags.data)) ? formF->getGroup() : 0;
    WindowRecord *w = windowHolding(top);
    if ( !w ) {
        fprintf(stderr, "readWindow: REFUSING %s -- needs form:= a top field that a window holds\n", request->groupBody->tag);
        return 0; }
    @autoreleasepool {
        NSRect bounds = [w->view bounds];
        int wide = (int)bounds.size.width, high = (int)bounds.size.height;
        CGColorSpaceRef cs  = CGColorSpaceCreateDeviceRGB();
        CGContextRef    ctx = CGBitmapContextCreate(0, wide, high, 8, 0, cs, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(cs);
        if ( !ctx ) {
            fprintf(stderr, "readWindow: REFUSING %s -- CGBitmapContextCreate failed\n", request->groupBody->tag);
            return 0; }
        NSGraphicsContext *into = [NSGraphicsContext graphicsContextWithCGContext:ctx flipped:NO];
        [w->view displayRectIgnoringOpacity:bounds inContext:into];
        printf("=== readWindow %s title [%s] size %dx%d ===\n", request->groupBody->tag, [[[w->view window] title] UTF8String], wide, high);
        fflush(stdout);
        request->setPointer((void *)ctx);
    }
    return request;
}

/***************************************************************************
    A CLICK FROM A POINT (windows stroke 2; W2, Tony 2026-11-22).
    windowClickAt turns a point in the view into the field under it on the
    laid-out copy the window holds -- blockContaining, the lowest field whose
    frame contains the point; the top itself when no member does -- and hands
    kant that field: Utilities' clickField selects it and fires, bubbling up
    the copy's parents. A point on no field fires nothing and says so.
    The view's y runs up and the form's runs down, and the copy's frames
    start at the top field's own x and y: both are undone here, once.
    mouseUp is AppKit's door to it. windowClick(request) is the fleet's:
    form:= the copy a window holds, px py a point counted from the view's
    top left as pixelAt counts; it makes a mouse-up event at that point and
    sends it to the view's own mouseUp, so the real road is the one tested.
***************************************************************************/
static void windowClickAt(Layout *view, NSPoint inView)
{
    GroupItem *top = view->base;
    if ( !top ) return;
    NSRect  framed = getFrame(top);
    double  down = [view bounds].size.height - inView.y;
    NSPoint p = NSMakePoint(inView.x + framed.origin.x, down + framed.origin.y);
    GroupItem *hit = contains(top, p) ? blockContaining(top, p) : 0;
    if ( !hit && contains(top, p) ) hit = top;
    printf("=== windowClick %s at (%g,%g): %s ===\n", top->groupBody->tag, inView.x, down, hit ? hit->groupBody->tag : "no field, nothing fired");
    fflush(stdout);
    if ( !hit ) return;
    GroupItem *utilities = GroupControl::groupController->getRegistry((char *)"Utilities");
    GroupItem *clicker = utilities ? utilities->get((char *)"clickField") : 0;
    if ( !clicker ) {
        fprintf(stderr, "windowClick: REFUSING %s -- no clickField in Utilities\n", top->groupBody->tag);
        return; }
    runAction(hit, clicker);
}

@interface Layout (Events)
- (void)mouseUp:(NSEvent *)event;
@end
@implementation Layout (Events)
- (void)mouseUp:(NSEvent *)event
{
    windowClickAt(self, [self convertPoint:[event locationInWindow] fromView:nil]);
}
@end

extern "C" GroupItem *windowClick(GroupItem *request)
{
    if ( !request ) return 0;
    GroupItem *formF = request->get((char *)"form"), *px = request->get((char *)"px"), *py = request->get((char *)"py");
    GroupItem *top = (formF && isGROUP(formF->groupBody->flags.data)) ? formF->getGroup() : 0;
    WindowRecord *w = windowHolding(top);
    if ( !w || !px || !py ) {
        fprintf(stderr, "windowClick: REFUSING %s -- needs form:= a top field that a window holds, and px and py\n", request->groupBody->tag);
        return 0; }
    @autoreleasepool {
        NSPoint inView = NSMakePoint(px->getNumber(), [w->view bounds].size.height - py->getNumber());
        NSEvent *up = [NSEvent mouseEventWithType:NSEventTypeLeftMouseUp
                                         location:[w->view convertPoint:inView toView:nil]
                                    modifierFlags:0 timestamp:0 windowNumber:[[w->view window] windowNumber]
                                          context:nil eventNumber:0 clickCount:1 pressure:0];
        [w->view mouseUp:up];
    }
    return request;
}

/***************************************************************************
    windowHold(request): held:= the copy a window holds now, form:= the
    copy it is to hold from here on (a fresh layout). (Not window:= -- window
    is a form attribute and marks the request at define.) The cell that keeps the
    form alive is rewritten, the view draws the new copy from its next draw,
    and the window is found by the new copy after this.
***************************************************************************/
extern "C" GroupItem *windowHold(GroupItem *request)
{
    if ( !request ) return 0;
    GroupItem *wasF = request->get((char *)"held"), *nowF = request->get((char *)"form");
    GroupItem *was = (wasF && isGROUP(wasF->groupBody->flags.data)) ? wasF->getGroup() : 0;
    GroupItem *now = (nowF && isGROUP(nowF->groupBody->flags.data)) ? nowF->getGroup() : 0;
    WindowRecord *w = windowHolding(was);
    NSRect asked = now ? getFrame(now) : NSZeroRect;
    if ( !w || asked.size.width < 1 || asked.size.height < 1 ) {
        fprintf(stderr, "windowHold: REFUSING %s -- needs held:= a top field that a window holds and form:= a laid-out form\n", request->groupBody->tag);
        return 0; }
    *w->held = now;
    w->view->base = now;
    [w->view setNeedsDisplay:YES];
    return request;
}

/***************************************************************************
    displayDiff(request): first:= and second:= two fields that each hold a
    bitmap (readPDF's request, readWindow's request, a makeDisplay top).
    Compares them pixel for pixel and prints how many differ, by how much at
    most, and how many differ by more than 16 in some channel -- text drawn
    straight into a bitmap and text drawn through a PDF are antialiased
    apart, so the edges of glyphs differ a little and nothing else should.
***************************************************************************/
extern "C" GroupItem *displayDiff(GroupItem *request)
{
    if ( !request ) return 0;
    GroupItem *f[2] = { request->get((char *)"first"), request->get((char *)"second") };
    CGContextRef c[2] = { 0, 0 };
    for (int i = 0; i < 2; i++) {
        GroupItem *held = (f[i] && isGROUP(f[i]->groupBody->flags.data)) ? f[i]->getGroup() : 0;
        GroupItem *top = held ? displayOf(held) : 0;
        c[i] = top ? (CGContextRef)top->getPointer() : 0; }
    if ( !c[0] || !c[1] ) {
        fprintf(stderr, "displayDiff: REFUSING %s -- needs first:= and second:= fields that each hold a bitmap\n", request->groupBody->tag);
        return 0; }
    size_t w = CGBitmapContextGetWidth(c[0]), h = CGBitmapContextGetHeight(c[0]);
    if ( w != CGBitmapContextGetWidth(c[1]) || h != CGBitmapContextGetHeight(c[1]) ) {
        printf("=== displayDiff %s sizes differ: %zux%zu and %zux%zu ===\n", request->groupBody->tag, w, h, CGBitmapContextGetWidth(c[1]), CGBitmapContextGetHeight(c[1]));
        fflush(stdout);
        return request; }
    unsigned char *a = (unsigned char *)CGBitmapContextGetData(c[0]), *b = (unsigned char *)CGBitmapContextGetData(c[1]);
    size_t ra = CGBitmapContextGetBytesPerRow(c[0]), rb = CGBitmapContextGetBytesPerRow(c[1]);
    long differ = 0, far = 0, inked = 0; int most = 0;
    for (size_t y = 0; y < h; y++)
        for (size_t x = 0; x < w; x++) {
            unsigned char *p = a + y * ra + x * 4, *q = b + y * rb + x * 4;
            int d = 0;
            for (int k = 0; k < 4; k++) { int e = abs((int)p[k] - (int)q[k]); if ( e > d ) d = e; }
            if ( p[0] != a[0] || p[1] != a[1] || p[2] != a[2] ) inked++;
            if ( d ) differ++;
            if ( d > 16 ) far++;
            if ( d > most ) most = d; }
    printf("=== displayDiff %s size %zux%zu pixels %zu; unlike the first's corner %ld; differing %ld, by more than 16: %ld, at most %d ===\n",
           request->groupBody->tag, w, h, w * h, inked, differ, far, most);
    fflush(stdout);
    return request;
}

extern "C" GroupItem *windowOffscreen(GroupItem *input)
{
    @autoreleasepool {
        unsigned before = _dyld_image_count();
        Layout *view = makeWindow(input, false);
        if ( !view ) return 0;
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
        if ( !view ) return 0;
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
