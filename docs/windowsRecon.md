# Windows recon (SEQ 740, 2026-11-22)

Topics/windows plan item 1: a read-only recon of the old GUI's window code and today's `openWindow`. No dispatch existed,
so the charter below is Clod's draft (Tony's go-ahead, 2026-11-22); Tony and Clay amend it and anything it missed is a
second pass. Documents only: this file, a pointer in `Topics/windows`, one `docs/cleanupList.md` entry.

**Every fact here is READ, not run, on trunk after seal 525 (2026-11-22).** No window was opened: `openWindow` takes the
screen's focus and blocks until its window is closed, and Tony was working at the machine. What a run would add is named
in section 7.

## 0. The charter (Clod's draft)

Answer, with file and line, so the first window stroke can be dispatched without re-reading the code:

1. What `openWindow` does today, start to finish, and what of it is in the binary.
2. How the old GUI opened, drew, resized and closed a window, and who owned the event loop. (What each old *attribute*
   did is already in `IncantForms/WorkingOn/formsRecon`, Parts 1-2; this recon points there and does not repeat it.)
3. What a real window needs from today's forms machinery, piece by piece: a place to draw, a point turned into a
   field, a resize, a close; and for each, whether the piece exists.
4. What a window must keep alive (the collector).
5. The decisions that are Tony's, and the smallest strokes that follow from each answer.

Out of scope: text editing, images' zoom, the Font and Colour panels (plan item 2), scrolling. Each rides on a window
that draws and clicks.

## 1. Today's window path

| piece | where | what it does |
|---|---|---|
| `window` attribute | `Commands.rtn` markWindow (:490) | at define, sets `isWindow` on the form field. **Nothing reads `isWindow`** (GroupBody.twk:89 declares it; grep of `*.twk`, `*.rtn`, utilities, setup: one writer, no reader). |
| `openWindow(form)` | `guiHost.mm:26`, hand-written Objective-C++, compiled by the Groups target, registered `incant/setup:85` | makes the app a regular app; reads the form's frame with `getFrame`; flips y for the screen (:57); makes one titled, closable, resizable NSWindow titled "incant"; hangs a `Layout` view on it with `view->base = form`; **enters `[app run]` and does not return**; a close notification calls `[NSApp terminate:nil]`. |
| `Layout` view | `Layout.twk` (top level, 155 lines; `Layout.mm` is in the target) | `drawRect` (:101) **strokes the top field's frame and nothing else**: it reads no child and calls no floor. `viewDidEndLiveResize` (:142) prints and re-sets its own frame; its relayout line is commented out. `windowWillClose` (:150) calls `exit(0)`. **No mouse or key method**: a comment (:133) names keyUp, mouseUp, rightMouseUp, scrollWheel as to be designed. |
| hit test | `Stylish.twk` blockContaining (:53), contains (:71) | C++, takes a `Point`: the lowest member whose frame contains the point. In the binary; **called by nothing** today. Not a kant command. |
| the collector | `guiHost.mm:28-45` | `GC_set_no_dls(1)`, then roots the controller and holds the form in one uncollectable cell (SEQ 589). Section 4. |

So today a window is a rectangle outline that blocks the script and ends the process when closed. Nothing in the fleet,
the forms or tester calls `openWindow` (grep of `incant/`, `IncantForms/`, `genLadder/`, `jitLadder/`: setup's
registration and formsRecon's prose only).

`Layout.twk` also carries three display methods from the July rewrite, before the floor existed: `displayCell` (:18),
`displayImage` (:46), `displayText` (:64), with the ivars `textField`, `layoutPath`, `style`, `selection`. Nothing calls
them (grep outside `Layout.twk` and `GUI/`: no hit). Listed on `docs/cleanupList.md`.

## 2. The old GUI's window (GUI/, tracked, not in the binary; formsRecon :1090)

- **It was a Cocoa application, and the app owned the loop.** `GUI/GroupUIAppDelegate.mm:34`: `applicationDidFinishLaunching`
  calls `Control::bwana->controller->start(window)`. The engine ran *inside* the app; forms were loaded from there.
  Today is the other way round: incant is a command-line process reading a script, and `openWindow` borrows AppKit.
- **A window was made at layout, first time only,** by the `window` / `panel` attribute's method, `GUI/Map.rtn` wINDOW
  (:1320-1368): mask from `closable`, `title`, `resize`; an NSWindow or NSPanel; placed at the form's `x`, `y`; sized from
  the laid-out frame; then a **WKWebView and a Layout view added to its content view**. Windows were kept by name in a
  `windows` table (`Bwana.twk:28`, `Details.twk:353`), which is how `popup=Name` raised one (formsRecon :126).
- **It drew HTML.** `GUI/Layout.twk` drawRect (:119) lays out, builds a canvas, and calls `webView.loadHTML` (:140).
  (`InProcess/Bot`'s variant drew a PDF with libharu into a PDFView, formsRecon :770-780; that library is not on this
  machine.) **Neither drawing road survives:** today's floor is Core Graphics (`GroupDraw.twk`).
- **A click:** `mouseUp` (:300) converts the point, flips y (`invertY` :229), finds the field with
  `base.blockContaining(point)`, and calls `fireAction` (:160): select the field, then walk **up the parents**, at each
  level running the field's own method and then its matching attribute actions left to right, stopping at the first level
  that fired. `rightMouseUp` (:322), `keyUp` (:241, arrows and paging) and `scrollWheel` (:333) follow the same shape.
- **A resize:** `viewDidEndLiveResize` (:400) wrote the window's x, y, width, height **into the form's own attributes**,
  cleared `laidout`, and laid out and drew again. (Today the definition is never written; the frame goes in a request.)
- **A close:** `GUI/Delegate.twk:39` windowWillClose marks the form `noRoom`; closing the root window calls `exit(0)`.
- **Selection:** `select` (:361) and `deselect` (:30) swap the field's fill and stroke for its `selectFill` /
  `selectStroke` and remember it in `selection`; tabs are exempt from deselect.

## 3. What a real window needs, and what exists

**A place to draw: one new opener, nothing else.** The floor draws into a Core Graphics context kept in the top field's
pointer slot and handed down to every descendant (`GroupDraw.twk` displayOf :106, handDisplay :117). Two openers exist:
`makeDisplay` (:131, a bitmap) and `openPDF` (:184). Each sets the same three transforms (translate by the height, scale
y by -1, translate by minus the top's origin) and stores the context. **A window is a third opener:** inside `drawRect`,
take the view's current context, apply the same three transforms, store it in the top's slot, hand it down, run
`drawWalk`, clear the slot (closePDF's `noDangling`, :227). `drawWalk` already draws into a top that holds a context
(utilities :1095, "drawn into as it stands"). Keep the view unflipped so the transforms are byte-for-byte the bitmap's;
text is the part that would notice a different one.

**C++ calling kant: exists.** `drawRect` and the event methods must call kant actions (`drawWalk`, `click`,
`redrawWindow`, `keepFrame`). The engine already does this for listeners: `GroupItem.twk` runNotified (:1640) calls
`processAction(notified)`; `runAction(argument, field)` (`GroupActions.rtn:1390`) is the call with an argument. An action
is found by name in the Utilities registry, as `incant/setup` does (`Utilities["showForm"]`).

**What the window holds: the laid-out copy, not the form.** Today `view->base` is the definition. setFrame lays out a
deep copy and the definition has no frames (Topics/forms, State), so a window must hold what `showForm` / `redrawForm`
returns, and swap it on every redraw. That copy is what `drawRect` draws and what a point is tested against. A held form
(`form:=`) is in that copy too: `placeForm` adds the held form's laid-out copy as a member of its host
(utilities :326), so the hit test descends into it with no extra work.

**A point turned into a field: half exists.** `blockContaining` finds the lowest field under a point on the copy. Frames
on the copy are in the form's coordinates, origin at the top's `x`, `y`, so a view point needs the y flip and the top's
origin added. What does not exist is the step from that field to a click:
- `click(request)` takes a form and a field **name**, and looks the name up in the *definition* (utilities, click).
  It refuses a field of a held or generated page unless the request names that page (measured today, samplerRecon
  section 4: "the form spOuter has no field named blue").
- So a click from a point needs either (a) `click` taught to accept the field itself, found on the copy, or (b) a walk up
  from the hit field to the nearest held form's top, giving (page, name) for today's `click`.
- **Bubbling** is the same walk: the old GUI climbed parents until something fired; today's `click` fires one level and
  G1 lists bubbling as open. On the copy a member's parent is its enclosing field (merge 24beb5f0), so the climb is
  there to be used.
- The ruling of 2026-11-04 stands and suits this: firing from a point is proved with a **synthetic point and no window**.

**A resize and a close: the kant halves exist.** `redrawWindow(request)` keeps the window's frame and redraws;
`keepFrame(request)` alone is a close (G3, SEQ 730; frameStoreT). What is missing is the caller: `viewDidEndLiveResize`
building a request with the window's frame and calling `redrawWindow`, then swapping the held copy and redrawing; and the
close notification calling `keepFrame`. A window's frame includes its screen position, in screen coordinates with y up;
the flip at `guiHost.mm:57` has to be undone on the way back.

**The display's size.** Tony's size rule (2026-11-22, Topics/forms) caps a form at the display's height less menu bar and
dock. AppKit has that number (the main screen's visible frame). Nothing hands it to kant today; a window stroke can
publish it as a field for setFrame to read.

## 4. What a window must keep alive

- **F-153, windowHidesGlobals (docs/fixIts.md:241), is open and is this topic's.** After `GC_set_no_dls(1)` the collector
  scans no global but the controller and the one held form. Any engine object reached only through a raw-pointer global
  is collectable while a window is open: the JIT's globals, `gParseActive`, any `static GroupItem*`. Today nothing runs
  under an open window, so it has never bitten. **A window that lays out again and runs kant on every click and resize
  runs the engine under exactly that condition.** Its done-when is a window run that survives a relayout with the JIT on.
- **The held copy changes on every redraw,** so the one uncollectable cell `openWindow` makes for the form (:44) must be
  rewritten each time, not written once.
- **Threads.** AppKit and Core Graphics bring their own. F-152 (a system thread allocating through a single-threaded
  collector) was cured for the PDF road by `gcThreads.mm`; whether a live window raises the same thing by another door is
  not known and is one `GCTHREADS_REPORT` run to learn.

## 5. The decisions that are Tony's

1. **Who owns the loop, and how many windows.** Today `openWindow` blocks and a close kills the process, so nothing
   after it in a script runs and there can be one window. The sampler is meant to stay open beside the form being
   designed, so at least two. Options: **(a)** split it: `openWindow` makes a window and returns; the loop starts once,
   when the script's input ends (or at an explicit `runWindows();`), and ends when the last window closes, returning so
   the process exits normally. **(b)** keep one blocking call per script. **(c)** make incant an app again, as the old
   GUI was. Clod's lean: (a); it is the least change that allows two windows and a clean exit.
2. **What a click from a point hands kant:** the field itself (extend `click`), or a page and a name (today's `click`,
   plus a climb). And whether bubbling comes with it or after.
3. **Where selection shows.** `selection` is written by `click` and read only by `describe`; the old GUI recoloured the
   selected field. Tabs already recolour through `selectFill` and `tabSelected`. Is there a general selected look, or is
   it per form as tabs does it?
4. **`window`'s chrome.** `closable`, `resize`, `title` are inert today and `openWindow` hard-codes all three with the
   title "incant". Read them from the form, or leave until a form needs the difference.
5. **When F-153 is cured:** before the first window that runs kant (stroke 2 below), or ahead of everything as its own stroke.

## 6. Strokes, smallest first (proposed; none ruled)

| # | stroke | proof with nobody watching |
|---|---|---|
| 1 | **The window draws the form.** `Layout` holds the laid-out copy; `drawRect` is the third opener and runs `drawWalk`. `openWindow` takes what `show` builds. The three dead display methods go. | the view drawn into an offscreen bitmap (AppKit can render a view without showing it) and read by `pixelAt`: firstLight's pixels equal its PDF's, row for row with drawWalkT's |
| 2 | **F-153**, sized by its own done-when. | a relayout with the JIT on under an open (offscreen) window, GCSTRESS |
| 3 | **A click from a point**, per decision 2. | a synthetic point on tabForm: the point inside tab Three gives the red card, as tabClickT's TK-1; a point on no field fires nothing and says so |
| 4 | **Resize and close** call `redrawWindow` and `keepFrame`. | a synthetic resize: the frames equal frameStoreT's for the same size; a close then a reopen reads the kept frame |
| 5 | **The loop**, per decision 1; the display's size published. | two windows opened, both drawn offscreen; the script's last line still runs |
| 6 | A real run, watched by Tony: firstLight, then tabForm clicked by hand. | Tony's eyes; nothing in the fleet opens a visible window |

Strokes 1, 3 and 4 need no visible window and no run loop, which is what keeps them in the fleet.

## 7. Not measured, and what would measure it

- Whether `openWindow` still opens a window on today's binary (last recorded run: none found in the seals read). One run
  under an alarm, when Tony is not at the keyboard, or by Tony.
- Whether AppKit renders a `Layout` offscreen without an app loop on this OS (stroke 1's proof depends on it; the
  fallback is drawing the copy through the same opener into a bitmap context, which proves the opener but not the view).
- Text under the window's context: the same transforms should give the same glyph placement; not run.
- The thread question in section 4.
