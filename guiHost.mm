/***************************************************************************
    GUI host — the minimal Apple shim, hand-written Objective-C++ that
    bypasses tok entirely (tok can't parse inline [bracket] message sends).
    Keep Apple in its lane: open a window, hang a Layout, pump the event
    loop — nothing more. incant does layout/font/color above this; Layout
    paints into the window below it.

    openWindow(field): creates an NSWindow whose contentView is a Layout
    bound (view->base) to the laid-out form, shows it, and RETURNS AT ONCE
    (W1): the event loop starts when the script ends (windowsRun) and stops
    when the last shown window closes. extern "C" so the incant runtime
    dlsym-binds it (incant/setup: openWindow immediateAction=openWindow).

    windowOffscreen(field): the same window, never shown -- no focus taken,
    no dock icon, no run loop; it finishes launching, drains the events
    waiting, and returns. The fleet's door (incant/pop/windowGcT).
    windowRootProbe: what the collector still scans (below).
    Either door takes a laid-out copy (the window shows it and nothing more)
    or a REQUEST, form:= the form: the window then lays the form out itself
    and again after every resize and click, and keeps its frame at a close.

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
//  windows held[0] is the laid-out copy, held[1] the request the window was opened with (0 for a window handed a bare copy), held[2] the search list in force when it was opened
struct WindowRecord { Layout *view; GroupItem **held; bool shown; };
static std::vector<WindowRecord> gWindows;

/***************************************************************************
    THE LOOP (windows stroke 4; W1, Tony 2026-11-22). openWindow returns at
    once. windowsRun is called where a script ends (stop's exit, and main's
    foot): with a shown window open it runs the application's event loop,
    and the loop stops when the last shown window closes, so the process
    then exits as it always did. With no shown window it returns at once.
    FOR THE FLEET: windowClick, windowResize and windowClose on a request
    that carries `later` are not done when called; they are kept, in order,
    and done inside the loop once it is running. Kept requests start the
    loop too, and it stops when they are all done and no shown window is
    open -- so a fixture runs the real loop with nothing on the screen.
***************************************************************************/
static bool gLooping, gDraining;
static std::vector<std::pair<int, GroupItem *> > gLater;

static int shownWindows()
{
    int n = 0;
    for ( WindowRecord &w : gWindows ) if ( w.shown ) n++;
    return n;
}

static void loopCheck()
{
    if ( !gLooping || gDraining || shownWindows() || !gLater.empty() ) return;
    [NSApp stop:nil];
    //  wakeTheLoop stop: takes effect when the loop next returns from an event, so it is handed one
    [NSApp postEvent:[NSEvent otherEventWithType:NSEventTypeApplicationDefined location:NSZeroPoint modifierFlags:0
                                       timestamp:0 windowNumber:0 context:nil subtype:0 data1:0 data2:0] atStart:YES];
}

static bool keptForLater(GroupItem *request, int kind)
{
    if ( gDraining || !request || !request->get((char *)"later") ) return false;
    gLater.push_back(std::make_pair(kind, request));
    return true;
}


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
    THE WINDOW'S REQUEST (windows stroke 3). A window opened with a request
    (form:= the form, look= or look:= optional, frame:= optional) keeps it,
    and every later layout goes back through kant with the window's frame
    now: Utilities' windowLay keeps the frame in formFrames (keepFrame) and
    lays the form out from there (setFrame), as redrawWindow does, writing no
    PDF. windowLay hands the laid-out copy back through windowTake -- a
    command's argument is the field itself, where an action's returned value
    reaches C++ as a copy. A resize, a click and a close all come here.
***************************************************************************/
static GroupItem **gTaken;

/***************************************************************************
    THE WINDOW'S SEARCH LIST (fix stroke W5-1, 2026-11-23). A window calls
    kant long after the statement that opened it: a draw, a click, a resize,
    a close, all from the event loop, which runs when the script has ended.
    show puts the search list back when it returns, so by then Utilities is
    not on it -- and a kant body binds its names when it is first built, with
    the search list of that moment. drawWalk, first built inside the loop,
    bound drawFill to a fresh local and the first window anyone saw was blank
    (REFUSED drawFill; Tony's watched run). So each window keeps the search
    list in force when it was opened (held[2]), and every call a window makes
    into kant runs under that list, the caller's put back after.
***************************************************************************/
static GroupItem *runUnder(GroupItem *search, GroupItem *argument, GroupItem *action)
{
    if ( !search ) return runAction(argument, action);
    GroupItem *was = searchSave(0);
    searchRestore(search);
    GroupItem *result = runAction(argument, action);
    searchRestore(was);
    return result;
}

extern "C" GroupItem *windowTake(GroupItem *input)
{
    if ( !gTaken ) gTaken = (GroupItem **)GC_MALLOC_UNCOLLECTABLE(sizeof(GroupItem *));
    *gTaken = input;
    return input;
}

static GroupItem *utilityAction(const char *name)
{
    GroupItem *utilities = GroupControl::groupController->getRegistry((char *)"Utilities");
    GroupItem *action = utilities ? utilities->get((char *)name) : 0;
    if ( !action ) fprintf(stderr, "window: REFUSING -- no %s in Utilities\n", name);
    return action;
}

//  frameField a field holding x y width height, as a form's frame is written: whole points, y down from the top of the screen
static GroupItem *frameField(NSRect r)
{
    GroupItem *frame = new GroupItem((char *)"windowFrame");
    const char *names[4] = { "x", "y", "width", "height" };
    double      values[4] = { r.origin.x, r.origin.y, r.size.width, r.size.height };
    for (int i = 0; i < 4; i++) {
        GroupItem *part = new GroupItem((char *)names[i]);
        part->setCount((int)values[i]);
        frame->addAttribute(part); }
    return frame;
}

//  windowRequest a request of the window's own for one call: the opening request's form and look, and frame:= the frame given (or the opening request's own, when none is)
static GroupItem *windowRequest(GroupItem *opened, NSRect *frame)
{
    GroupItem *request = new GroupItem((char *)"windowRequest");
    const char *carried[3] = { "form", "look", "frame" };
    for (int i = 0; i < 3; i++) {
        GroupItem *part = opened->get((char *)carried[i]);
        if ( !part || (i == 2 && frame) ) continue;
        //  freshNodes never a copy of the caller's attribute: a copy shares its body, so the caller re-pointing its form:= (showForm's showReq does, at the next show) would re-point this window's too (measured, stroke 4)
        GroupItem *own = new GroupItem((char *)carried[i]);
        if ( isGROUP(part->groupBody->flags.data) )    own->setGroup(part->getGroup());
        else                                            own->setContent(part);
        request->addAttribute(own); }
    if ( frame ) {
        GroupItem *holder = new GroupItem((char *)"frame");
        holder->setGroup(frameField(*frame));
        request->addAttribute(holder); }
    return request;
}

//  displayPublish the display's usable size -- the main screen less menu bar and dock -- written into Utilities' displaySize (width, height), where windowLay reads the cap for height=fit
static void displayPublish()
{
    GroupItem *utilities = GroupControl::groupController->getRegistry((char *)"Utilities");
    GroupItem *size = utilities ? utilities->get((char *)"displaySize") : 0;
    GroupItem *wide = size ? size->get((char *)"width") : 0, *high = size ? size->get((char *)"height") : 0;
    if ( !wide || !high ) return;
    @autoreleasepool {
        [NSApplication sharedApplication];
        NSRect usable = [[NSScreen mainScreen] visibleFrame];
        wide->setCount((int)usable.size.width);
        high->setCount((int)usable.size.height); }
}

static GroupItem *windowLayout(GroupItem *opened, NSRect *frame, GroupItem *search)
{
    GroupItem *lay = utilityAction("windowLay");
    if ( !lay ) return 0;
    displayPublish();
    windowTake(0);
    runUnder(search, windowRequest(opened, frame), lay);
    return *gTaken;
}

//  formFrame the window's content rectangle as a form's frame: x from the left, y down from the top of the screen
static NSRect formFrame(Layout *view)
{
    NSWindow *win = [view window];
    NSRect c = [win contentRectForFrameRect:[win frame]];
    c.origin.y = [[NSScreen mainScreen] frame].size.height - c.origin.y - c.size.height;
    return c;
}

static WindowRecord *windowOf(Layout *view)
{
    for ( WindowRecord &w : gWindows ) if ( w.view == view ) return &w;
    return 0;
}

//  windowRelay lay the window's form out again at the window's frame now, and hold and draw the new copy; a window handed a bare copy has no request and keeps what it holds
static void windowRelay(Layout *view)
{
    WindowRecord *w = windowOf(view);
    if ( !w || !w->held[1] ) return;
    NSRect now = formFrame(view);
    GroupItem *laid = windowLayout(w->held[1], &now, w->held[2]);
    if ( !laid ) return;
    //  refetch the layout ran kant, which may open a window: gWindows can have moved
    w = windowOf(view);
    if ( !w ) return;
    w->held[0] = laid;
    view->base = laid;
    [view setNeedsDisplay:YES];
}

//  windowResized Layout.viewDidEndLiveResize calls it: the resize is over, lay out at the new frame
void windowResized(Layout *view)
{
    NSRect now = formFrame(view);
    printf("=== window resized: %s now %gx%g at (%g,%g) ===\n", view->base ? view->base->groupBody->tag : "nothing", now.size.width, now.size.height, now.origin.x, now.origin.y);
    fflush(stdout);
    windowRelay(view);
}

//  windowClosed keepFrame alone is a close (G3): the frame is kept for the form's next opening; the window is forgotten and its form no longer held
static void windowClosed(Layout *view)
{
    WindowRecord *w = windowOf(view);
    if ( !w ) return;
    if ( w->held[1] ) {
        NSRect now = formFrame(view);
        GroupItem *keep = utilityAction("keepFrame");
        printf("=== window closed: %s kept %gx%g at (%g,%g) ===\n", view->base ? view->base->groupBody->tag : "nothing", now.size.width, now.size.height, now.origin.x, now.origin.y);
        fflush(stdout);
        if ( keep ) runUnder(w->held[2], windowRequest(w->held[1], &now), keep);
        w = windowOf(view);
        if ( !w ) return; }
    w->held[0] = 0;
    w->held[1] = 0;
    w->held[2] = 0;
    view->base = 0;
    gWindows.erase(gWindows.begin() + (w - &gWindows[0]));
}

//  isRequest a request names a form (form:=) and has no width of its own; a laid-out copy's top always has one
static bool isRequest(GroupItem *input)
{
    GroupItem *formF = input ? input->get((char *)"form") : 0;
    return formF && isGROUP(formF->groupBody->flags.data) && !input->get((char *)"width");
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
static Layout *makeWindow(GroupItem *input, GroupItem *request, bool visible)
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
    GroupItem **heldForm = (GroupItem **)GC_MALLOC_UNCOLLECTABLE(sizeof(GroupItem *) * 3);
    heldForm[0] = input;
    //  ownSearch the search list of the statement that opened the window (show's, or a fixture's own): every later call into kant runs under it (runUnder)
    heldForm[2] = searchSave(0);
    //  ownRequest the window keeps a request of its own: the caller's field may be reused for the next window (showForm's showReq is)
    heldForm[1] = request ? windowRequest(request, 0) : 0;
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
    gWindows.push_back({view, heldForm, visible});
    //  closeKeeps a close keeps the window's frame for its form (keepFrame) and forgets the window; the last shown window closing stops the loop (loopCheck)
    [[NSNotificationCenter defaultCenter]
        addObserverForName:NSWindowWillCloseNotification
        object:win queue:nil
        usingBlock:^(NSNotification *note){ windowClosed(view); loopCheck(); }];
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
static WindowRecord *windowHolding(GroupItem *top);

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
    WindowRecord *drawn = windowHolding(top);
    runUnder(drawn ? drawn->held[2] : 0, top, walk);
    top->groupBody->gPointer = 0;
    top->groupBody->flags.isPointer = 0;
    CGContextRestoreGState(ctx);
}

static WindowRecord *windowHolding(GroupItem *top)
{
    if ( !top ) return 0;
    for ( WindowRecord &w : gWindows )
        if ( w.held[0] && w.held[0]->groupBody == top->groupBody ) return &w;
    //  byItsForm a window opened with a request is also found by the form that request names: the copy it holds changes at every redraw, the definition does not
    for ( WindowRecord &w : gWindows ) {
        GroupItem *formF = w.held[1] ? w.held[1]->get((char *)"form") : 0;
        GroupItem *form = (formF && isGROUP(formF->groupBody->flags.data)) ? formF->getGroup() : 0;
        if ( form && form->groupBody == top->groupBody ) return &w; }
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
    WindowRecord *clicked = windowOf(view);
    runUnder(clicked ? clicked->held[2] : 0, hit, clicker);
    //  clickRedraws a window that knows its request lays out again after the click (clickShow's kin), so what the click changed, and the selection, show
    windowRelay(view);
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
    if ( keptForLater(request, 0) ) return request;
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
    w->held[0] = now;
    w->view->base = now;
    [w->view setNeedsDisplay:YES];
    return request;
}

/***************************************************************************
    windowResize(request): form:= the form a window shows (or the copy it
    holds) and frame:= a field holding width and height, and x and y if the
    window is to move. The fleet's resize: the window takes the size, then
    the view's own viewDidEndLiveResize is called, as AppKit calls it when a
    drag ends. windowClose(request): form:= likewise; the window is closed
    as its close button closes it.
***************************************************************************/
static WindowRecord *windowNamed(GroupItem *request, const char *who)
{
    GroupItem *formF = request ? request->get((char *)"form") : 0;
    GroupItem *top = (formF && isGROUP(formF->groupBody->flags.data)) ? formF->getGroup() : 0;
    WindowRecord *w = windowHolding(top);
    if ( !w ) fprintf(stderr, "%s: REFUSING %s -- needs form:= a form a window shows\n", who, request ? request->groupBody->tag : "nothing");
    return w;
}

extern "C" GroupItem *windowResize(GroupItem *request)
{
    if ( keptForLater(request, 1) ) return request;
    WindowRecord *w = windowNamed(request, "windowResize");
    if ( !w ) return 0;
    GroupItem *frameF = request->get((char *)"frame");
    GroupItem *frame = (frameF && isGROUP(frameF->groupBody->flags.data)) ? frameF->getGroup() : 0;
    GroupItem *wide = frame ? frame->get((char *)"width") : 0, *high = frame ? frame->get((char *)"height") : 0;
    if ( !wide || !high ) {
        fprintf(stderr, "windowResize: REFUSING %s -- needs frame:= a field holding width and height\n", request->groupBody->tag);
        return 0; }
    @autoreleasepool {
        NSWindow *win = [w->view window];
        NSRect now = formFrame(w->view);
        GroupItem *x = frame->get((char *)"x"), *y = frame->get((char *)"y");
        NSRect want = NSMakeRect(x ? x->getNumber() : now.origin.x, y ? y->getNumber() : now.origin.y, wide->getNumber(), high->getNumber());
        want.origin.y = [[NSScreen mainScreen] frame].size.height - want.origin.y - want.size.height;
        [win setFrame:[win frameRectForContentRect:want] display:NO];
        [w->view viewDidEndLiveResize];
    }
    return request;
}

extern "C" GroupItem *windowClose(GroupItem *request)
{
    if ( keptForLater(request, 2) ) return request;
    WindowRecord *w = windowNamed(request, "windowClose");
    if ( !w ) return 0;
    @autoreleasepool { [[w->view window] close]; }
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
        GroupItem *request = isRequest(input) ? input : 0;
        GroupItem *top = request ? windowLayout(request, 0, 0) : input;
        if ( request && !top ) {
            fprintf(stderr, "windowOffscreen: REFUSING %s -- its form was not laid out\n", input->groupBody->tag);
            return 0; }
        Layout *view = makeWindow(top, request, false);
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
        GroupItem *request = isRequest(input) ? input : 0;
        GroupItem *top = request ? windowLayout(request, 0, 0) : input;
        if ( request && !top ) {
            fprintf(stderr, "openWindow: REFUSING %s -- its form was not laid out\n", input->groupBody->tag);
            return 0; }
        Layout *view = makeWindow(top, request, true);
        if ( !view ) return 0;
        NSWindow *win = [view window];
        [win makeKeyAndOrderFront:nil];
        [NSApp activateIgnoringOtherApps:YES];
        [win displayIfNeeded];
        printf("=== openWindow: %s shown; the loop starts when the script ends ===\n", top->groupBody->tag);
        fflush(stdout);
    }
    return input;
}

//  laterDrain the kept requests, in the order they were asked, done inside the running loop
static void laterDrain()
{
    gDraining = true;
    for (size_t i = 0; i < gLater.size(); i++) {
        GroupItem *request = gLater[i].second;
        if ( gLater[i].first == 0 )         windowClick(request);
        else if ( gLater[i].first == 1 )    windowResize(request);
        else                                windowClose(request); }
    gLater.clear();
    gDraining = false;
    loopCheck();
}

//  twoNames stop's exit is in an extern "C" function and main is not, so a declaration written inside each has that one's linkage: windowsRun is the C name, windowsRunAtEnd the C++ one
extern "C" void windowsRun()
{
    static bool ran;
    if ( ran || (!shownWindows() && gLater.empty()) ) return;
    ran = true;
    @autoreleasepool {
        [NSApplication sharedApplication];
        printf("=== window loop: started, %zu open, %d shown, %zu kept for later ===\n", gWindows.size(), shownWindows(), gLater.size());
        fflush(stdout);
        gLooping = true;
        dispatch_async(dispatch_get_main_queue(), ^{ laterDrain(); });
        [NSApp run];
        gLooping = false;
        printf("=== window loop: ended, %zu open ===\n", gWindows.size());
        fflush(stdout);
    }
}

void windowsRunAtEnd() { windowsRun(); }

//  isWindowForm 1 when the form was written with the window attribute (markWindow set isWindow at its define), else 0. The attribute itself is not kept on the form, and kant has no accessor for the flag; show reads this to decide between a window and the PDF (Tony, 2026-11-22)
extern "C" GroupItem *isWindowForm(GroupItem *input)
{
    GroupItem *answer = new GroupItem((char *)"isWindowForm");
    answer->setCount(input && input->groupBody->flags.isWindow ? 1 : 0);
    return answer;
}
