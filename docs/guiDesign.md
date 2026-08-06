# GUI Design Brief — Layout/Stylish Review, Fonts, Colors, Event & Display Cha-Cha

```
KIND:       spec
STATUS:     live — but §6(b)'s subview text model is SUPERSEDED by §10
DATE:       2026-07-02
REVISED:    2026-07-25 — §10 added (Display object, Tony's bitmap decision).
                        §10 supersedes §6(b)'s NSTextView/NSTextField subview
                        model for text. §1's bear #1 resolved (option A) and
                        landed in a5c6be1.
ANSWERS:    How do Layout/Stylish resolve styles, fonts and colours, how does
            the draw cycle work, and what surface does kant see for drawing?
READ-WITH:  wakeup.md          thread status for everything below
            setWindow-plan.md  window/panel recon; §10 draws into what it opens
            font-recon.md      the Apple-side font material behind §5
SUPERSEDES: nothing wholesale. §10 supersedes §6(b) in part — see §10.
OPEN:       §10 text editing — RESOLVED 2026-07-25: NSTextView overlay while
                editing (plan A); editing over the Display surface is plan B.
                Risk to watch is overlay/bitmap layout match.
            §10 displayPath() — paths and curves deliberately undesigned
            §2 resolveStyle — designed, never built
```

*Clay, 2026-07-02. Reviewed: revised Layout.twk, Stylish.twk (Tony's 06-30 rewrite).*
*Self-contained. Written to survive a month of hibernation. Companion to wakeup.md.*

## Verdict up front
The rewrite is a good foundation — the class shapes are right, the extern seams are in
the right places, and the tree-as-interface display model works. But there is one
structural design bear (shared-vs-per-field state in Stylish), one missing subsystem
(style resolution — nothing populates a Stylish from its definition), and a handful of
concrete bugs. All are fixable within the current shapes. Nothing needs to be torn down.

---

## 1. DESIGN BEAR #1 — Stylish conflates shared style with per-field state

`getStyle()` resolves to the **shared** Stylish stored in the sTYLEs registry (one
object per style *name*). Every field wearing `titleStyle` gets the same pointer.
But Stylish carries per-field state:

- `selected`, `editable`, `selectable` — selection state of ONE field
- `subbed` — "my subview has been added" for ONE field
- `shadow` / `shadowField` — arguably per-field

Consequences today: select one titled field → all titled fields report selected.
First titled field displays → `subbed=true` on the shared object → second titled
field never gets its NSTextView added.

**Fix (design decision needed, recommend option A):**
- **A. Split.** Stylish = shared visual attributes only (colors, font, border,
  radius, transparency, formatter). Per-field state moves to attributes on the
  field's GroupItem (`selected`, `subbed` as flag attributes) or into a small
  per-field C++ side-struct keyed off the field. Cleanest; matches "the tree is
  the state."
- **B. Per-field copies.** `getStyle` uses the existing copy-constructor
  `Stylish(item, source)` to hand each field its own clone, cached on the field's
  object/pointer slot. Simpler to implement, but duplicates visual attrs and
  makes live style editing (change red once, everything updates) harder.

Note the copy-constructor already exists and is currently **unused** — it reads
like option B was once the intent. Tony's call.

## 2. THE MISSING MIDDLE — style resolution (nothing populates Stylish)

`displayText` reads `style.font`; `displayCell` reads `style.fillColor`/`textColor`.
Nothing ever writes them. `setFont()` bakes an NSFont onto the **font field's**
object slot in the fONTs registry; `setColor()` bakes an NSColor onto the **color
field's** object slot in cOLORs. `makeStyleFor()` creates an empty named Stylish
and stops. The bridge is missing.

**Design: a resolveStyle pass.** When a style definition is first referenced
(inside `makeStyleFor`, or a new `resolveStyle(styleDef, Stylish*)`):

```
walk styleDef attributes:
    font=<name>        → fONTs[name]  → getFont(item)  → styled.font
    textColor=<name>   → cOLORs[name] → getColor(name) → styled.textColor
    bgColor / fillColor / strokeColor → same via getColor
    borderWidth / radius / transparency → .number → styled fields
    shadow=<field>     → styled.shadowField = field (sHADOW lazies the rest)
    editable / selectable → flags (see bear #1 for where they land)
```

This gives live-editing for free later: re-run resolveStyle on a style def after
incant mutates it, every field wearing it repaints new. One extern, minion-sized,
POP = define a style with font+colors, display text, observe correct font/color.

Prereq: a `getFont(GroupItem)` symmetric to `getColor(String)` — lazy `setFont`
if `!isOBJECT`, return object, error to cerr on failure. Trivial.

## 3. Code review — Stylish.twk findings

**3.1 `setFont()` — traits are a triple no-op (BUG, blocks fonts):**
1. `int mask;` uninitialized — garbage.
2. `mask &= boldMask` — AND *clears* bits; building a trait mask is OR (`|=`).
3. `mask` is never used — `fontWithName(name, size.number)` already ran; the
   trait computation is discarded. Today `titleFont family=Palatino size=24 bold`
   yields **regular** Palatino 24.
Also: no guard if `family` or `size` attribute is missing (`size.number` on null),
no fallback if `fontWithName` returns nil. Full redesign in §5.

**3.2 `setColor()` — likely renders WHITE (VERIFY FIRST, cheap):**
`rgbColor((double)red, (double)blue, (double)green, 1.0)` passes 0–255 component
values. NSColor components are 0.0–1.0; anything > 1.0 clamps. Unless the
`rgbColor` wrapper divides by 255, `red="ef2b2d"` renders as white.
**Minion POP #1: check the rgbColor wrapper for /255.0; if absent, add it there
(one place) rather than in setColor.**

**3.3 `setColor()` — accidental double-swap (LANDMINE, works today):**
For "rrggbb": `start+4` (the BLUE pair) is scanned into variable `green`;
`start+2` (the GREEN pair) into variable `blue`. The call
`rgbColor(red, blue, green, ...)` then passes them in swapped order, so the two
mistakes cancel and the colors are positionally correct. Rename the variables
and pass in order before someone "fixes" half of it. Also `red` is reused as the
charset-validation boolean before being reused as the component — rename that too.

**3.4 `getColor()` — null-deref (BUG):**
```
if item
    if !isOBJECT setColor(item);
if !(color = item.object) ...   // runs even when item == null
```
If `locate(name)` misses, `item.object` dereferences null. Move the second
check inside the `if item`, and cerr+return null on the miss.

**3.5 `contains()` — two POP questions:**
- Bare `x`/`y` with no `use p`: they must resolve to the Point arg, but `frame.x`
  vs bare `x` in the same expression is scope-ambiguity bait. POP with a known
  point/frame pair to pin tok's resolution — and consider `use p` for explicitness.
- Strict `>` excludes points exactly on the left/bottom edge; `<=` on top/right
  includes those edges. Asymmetric. Probably fine, but decide on purpose.

**3.6 `blockContaining()` — scoping + semantics:**
- `selectable` is read with no `use style` in scope (contrast Layout.twk, which
  does `use style` explicitly). What does it resolve to? POP or add `use style`.
- Loop logic reads: skip non-selectable containing members, break on first
  selectable one, recurse into it if it has members. The `if item.hasMembers ||
  !item.noPrint` guard's intent should get one comment line — it's the kind of
  condition that gets "simplified" wrong later.

**3.7 `sHADOW()` — flagged by Tony already; agree it needs a design+POP pass.
Defer until style resolution (§2) lands, since shadowField wiring depends on it.**

## 4. Code review — Layout.twk findings

**4.1 `addSubview`/`makeFirstResponder` inside the paint path (STRUCTURAL):**
`displayCell` and `displayText` mutate the view hierarchy. Once content dispatch
hangs these off `drawRect`, that's view-hierarchy mutation during painting —
invalidation loops and undefined redraw behavior on macOS. Restructure per §6
(two-phase: reconcile pass vs. draw pass). This is the one finding that changes
the display design rather than a line of code.

**4.2 Adopt `isFlipped = true` (SIMPLIFICATION, recommend strongly):**
Override `isFlipped` on Layout to return true. macOS then gives the view a
top-left origin natively: delete `invertY`, delete the manual flip in `drawRect`
(`f.y = frame.height - f.y - f.height`), and note that `displayImage` currently
does **no** flip (a latent bug that vanishes with this change). Text system,
controls, and event `convertPoint` all handle flipped views correctly. One
override kills the entire coordinate-flip class of bugs, including wakeup.md's
"y-coordinate flip" workaround.

**4.3 `switch` fallthrough on align (POP QUESTION, appears twice):**
```
case 'c': cell.setAlign(alignCenter);
case 'l': cell.setAlign(alignLeft);
case 'r': cell.setAlign(alignRight);
```
If tok follows C fallthrough, 'c' sets center→left→right and everything ends
right-aligned. POP a one-off switch in a scratch file to pin tok's semantics;
add breaks if needed. (Same pattern in displayCell and displayText.)
Re the `// case j justify` comment: NSText has `alignJustified`
(NSTextAlignmentJustified) — it exists; add it when aligns get POPped.

Tony note: in tok if a switch has NO breaks specified, a break is added after each case in the C++ switch statement that tok generates.

**4.4 `displayText` first-run null (BUG):**
```
if object   editor = object;
else        object = editor;    // editor is declared, never constructed
```
On first display, `editor` is nil; nil gets stored on the field, every message
to it no-ops silently, nothing renders, and the nil is now cached so it never
self-heals. The else branch needs a construct-then-store (`editor = new`-style,
frame-initialized), then `object = editor`.

**4.5 `displayImage` details:**
- `viewImage.setSize(size)` — `size` is unbound in scope (nothing in `use base`
  obviously supplies it). Confirm intent; probably `frame`-derived.
- `if scale imageFrame = indent(...)` then `if offset imageFrame = *offset.pointer`
  — offset unconditionally overwrites the scale result. If both can be set,
  the combination rule needs stating (offset-then-indent? mutually exclusive?).
- Argument order of `drawIn(frame, imageFrame, ...)` (which is dest, which is
  source portion) — POP with a known image; classic silent-swap territory.

**4.6 `viewDidEndLiveResize` calls `drawRect(frame)` directly (ANTI-PATTERN):**
Never call drawRect yourself; set the frame and mark `setNeedsDisplay`. AppKit
will call drawRect with proper graphics context. Direct calls draw with no/stale
context — works by accident until it doesn't.

**4.7 `drawRect` comment vs. code:** the header describes the flat nextAttribute
loop, but the body only strokes `base` itself (further simplified). Fine as the
stable-platform checkpoint; content dispatch design is §6. Update the comment
when dispatch lands so the next reader isn't hunting for a loop that isn't there.

**4.8 `windowWillClose` → `exit(0)`:** fine for the pilot; note it becomes wrong
the moment popups/panels exist (closing a panel exits the app). The setWindow
recon (window-recon.md, minion task) should propose the main-window-vs-panel
close policy.

## 5. FONTS — the transition design (incant → Apple)

### 5.1 What exists on the incant side (keep as-is, it's good)
The fONTs registry pattern is already the right canonical form:
- trait flags as named numeric defines: `bold=1 italic=2 smallCaps=128`
  (attribute presence on a font def = trait requested; the numbers become
  incant-side bookkeeping, NOT Apple mask values — see 5.3)
- font defs: `titleFont family=Palatino size=24 bold`
- directory loads: `systemFonts directory="/System/Library/Fonts" fontFileMask load`

### 5.2 The transition, stated once
**incant font def → NSFontDescriptor (family + symbolic traits + feature
settings) → NSFont at size → cached on the def's object slot (hold() for GC) →
consumed by resolveStyle (§2) into Stylish.font → applied by displayText/Cell.**

NSFontDescriptor is the single Apple object that handles all three traits:
- bold  → symbolic trait `NSFontDescriptorTraitBold` (kCTFontTraitBold)
- italic → symbolic trait `NSFontDescriptorTraitItalic`
- smallCaps → **not a trait**: feature-settings attribute
  (`kLowerCaseType` / `kLowerCaseSmallCapsSelector`). This is why the current
  mask approach can never work for smallCaps — masks and features are different
  Apple mechanisms; the descriptor unifies them.

Fallback chain (each step logged to cerr): descriptor+family → if nil, direct
`fontWithName(family, size)` → if nil, `systemFontOfSize(size)`. Missing `size`
attribute → default 12.0. Never return nil from getFont.

All Apple types live in the translator layer (guiHost.mm / passthrough bodies),
per the standing architecture: incant drives structure, C++ owns exactly the
font/color/frame→Apple translation. setFont signatures stay header-clean.

### 5.3 Font FILE loading (and the Google Fonts door)
Loading a font *file* is `CTFontManagerRegisterFontsForURL(url,
kCTFontManagerScopeProcess, &err)`. After registration, the family name resolves
through the exact same descriptor path — no special "loaded font" branch.
- `/System/Library/Fonts*` dirs: already OS-registered; `load` there means
  *enumerate/validate*, not register. Registering system fonts errors harmlessly;
  skip system paths.
- New extern: `registerFontFile(path)` → bool + cerr on failure. This is the
  ONE piece of plumbing Google Fonts needs from font design. Tony is right that
  the JSON parsing is independent (feed jsonTest now, in parallel); the meet
  point is: JSON gives family→URL, something downloads the .ttf, then
  `registerFontFile`, then `family=` just works.

### 5.4 Minion-sized step plan (each: one extern touched, one POP, commit)
1. **POP the baseline.** Display titleFont text; capture `font.displayName` +
   traits. Expected finding: regular Palatino (per bug 3.1). This is the red bar.
2. **Rewrite setFont on the descriptor path** — family + size + bold/italic
   symbolic traits, fallback chain, size default. POP: titleFont displays as
   Palatino-Bold 24 (displayName check), bogus family falls back without crash.
3. **smallCaps via feature settings.** POP: a smallCaps def renders small caps
   (visual + descriptor attribute dump).
4. **Add `getFont(GroupItem)`** (lazy, symmetric to getColor). POP: two lookups,
   one setFont call (cache hit).
5. **`registerFontFile(path)` extern.** POP: register a ttf from Supplemental or
   any non-registered path; then resolve its family via step-2 path.
6. **Wire fONTs directory defines**: walk directory × fontFileMask regex;
   `load` ⇒ register (skip system dirs) ⇒ cerr per-file failures. POP: moreFonts
   dir enumerates; a registered family resolves.
Steps 1–4 unblock resolveStyle (§2). Steps 5–6 unblock Google Fonts plumbing.

## 6. DISPLAY CHA-CHA — the design, made explicit

Tony's implicit loop ("field gets framed in incant, passed to Layout, rinse and
repeat") works, with two clarifications:

**(a) Nothing is "passed."** The GroupItem tree IS the interface. Incant writes
x/y/width/height (and content) attributes; Layout reads them via getFrame during
its passes. The only signal that crosses the seam is *dirty*: after incant
mutates, Layout gets `setNeedsDisplay`. **v1 policy: whole-window redraw on any
change.** Per-field dirty rects are a later optimization; at current scale the
full repaint is instant and eliminates an entire class of missed-invalidation
bugs during bring-up.

**(b) Two phases, because AppKit demands it** (finding 4.1):
- **Reconcile pass** (runs on tree change, BEFORE drawing): walks base's members;
  for text/cell content ensures an NSTextView/NSTextField subview exists, is
  frame-synced, style-applied; removes subviews whose fields are gone.
  v1 reconcile-removal policy: on structural change, remove all content subviews
  and rebuild (mark-and-sweep comes later if rebuild flickers). This pass owns
  every `addSubview` / `removeFromSuperview` / `makeFirstResponder`.
- **Draw pass** (`drawRect`): strokes frames, draws images/paths. Touches no
  view hierarchy. Text/cells draw themselves as subviews — drawRect ignores them.

Content dispatch (successor to the current stroke-only drawRect) then splits
naturally: reconcile dispatches text/cell; drawRect dispatches frame-stroke/
image/path. Recursion guard stands: descend only into `hasMembers` nodes (the
old scalar-leaf SIGSEGV stays dead).

**Trigger wiring:** incant-side mutation completes → calls a `refreshLayout`
extern (or the event round-trip in §7 does it on return) → Layout runs
reconcile → `setNeedsDisplay` → AppKit calls drawRect. Resize path: `viewDidEnd
LiveResize` sets frame, runs reconcile, marks dirty (replaces the direct
drawRect call, finding 4.6).

## 7. EVENT CHA-CHA — the design

**Shape: synchronous round trip on the main thread.** Simplest, correct, and
matches "C++ handles only narrow translators." This is the third translator
(window-event → incant) the architecture reserved.

```
Apple event (keyUp / mouseUp / rightMouseUp / scrollWheel)
  → Layout override (one per event)
  → locationInWindow → convertPoint (top-left native once isFlipped lands)
  → blockContaining(base, p)  → target field (null ⇒ base)
  → translator builds event GroupItem:
        event type=mouseUp x=312 y=88 field=<target ptr> key=<char>
              modifiers=<flags> clicks=<n> deltaY=<scroll>
        (only attributes meaningful to that type; field is a live pointer
         attribute — same live-pointer discipline as jitSeedField)
  → call ONE incant extern entry: handleEvent(event)
  → incant: dispatch on type, mutate tree / reframe / set selection
  → return
  → Layout: reconcile + setNeedsDisplay
```

Decisions embedded there, each cheap to reverse later:
- **One entry point** (`handleEvent`), incant dispatches on `type` — vs. four
  externs. One seam is easier to log, POP, and evolve.
- **Selection moves incant-side**: mouseUp sets selection in the tree (per bear
  #1, selection is per-field tree state, not Stylish state); reconcile reads it
  to decide editable/firstResponder. Kills the current
  makeFirstResponder-during-display path.
- **keyUp routing**: while a field is selected+editable, AppKit's field editor
  handles typing natively (NSTextView is already an editor); incant sees keyUp
  for command-keys/navigation. Don't rebuild text editing in incant.
- **blockContaining is the hit-tester** — which is why its POPs (3.5, 3.6)
  gate this thread.

POP ladder: (1) mouseUp prints the event GroupItem via dumpContents — proves
translator; (2) mouseUp sets selection, reconcile draws selected border —
proves round trip; (3) scrollWheel adjusts a y-offset attribute and repaints —
proves continuous events survive the loop.

## 8. COLORS — verification checklist (small minion, run first)
1. rgbColor wrapper: /255.0 present? (3.2 — likely THE bug; fix in wrapper)
2. Rename the swapped green/blue locals + pass in order (3.3)
3. getColor null-guard (3.4)
4. POP: `red` renders visibly red in a stroked/filled frame; lightBlue renders
   light blue (catches both /255 and channel-order in one look)
5. Then colors are DONE pending resolveStyle wiring (§2)

## 9. Dependencies & sequencing (who's blocked on what)
```
colors POP (§8)            → unblocked NOW, ~1 minion-hour
fonts steps 1–4 (§5.4)     → unblocked NOW
bear #1 decision (Tony: A or B) → gates resolveStyle
resolveStyle (§2)          → needs bear #1 + fonts step 4 + colors POP
reconcile/draw split (§6)  → needs resolveStyle (styles must resolve to paint)
event round trip (§7)      → needs §6 + blockContaining POPs (3.5/3.6)
fonts steps 5–6            → independent; feeds Google Fonts
jsonTest google-font probe → independent, parallel, unblocked NOW (Tony's call
                             confirmed: no dependency on font design)
setWindow / window-recon   → independent recon, parallel, unblocked NOW
```
Everything above the line is startable today in parallel. The single design
decision needed from Tony before minions touch Stylish: **bear #1, option A
(split state) or B (per-field copies). Clay recommends A.**

---

## 10. DISPLAY OBJECT — the bitmap surface (added 2026-07-25)

**Tony's decision, 2026-07-25:** kant draws forms into a bitmap; Apple's view
displays that bitmap. No drawing, text handling, path work, font or colour
handling in Apple-side code. Motivation is **control, not portability** — but
nothing is to be done that makes portability harder later.

### 10.0 Display — the shape (ruled 2026-08-06)

*Newest statement of what Display **is**; read before §10.1–10.8, which predate it.
Numbered 10.0 rather than 10.9 so it reads first without renumbering the existing
subsections, which are cited by number elsewhere.*

Display (ruled 2026-08-06). Display is four things: a bitmap context, one current-style
slot, a pen, and a measure method.

The window attribute in a form instantiates a Display from the frame — define-then-show,
the markWindow/isWindow precedent. Font and color are components of a style; Stylish is
the carrier. A style attribute in the forms walk sets Display's current-style slot; draw
methods read components through the current style, never as loose state; any translation
into context state happens once, at setStyle time. The displayForm walk paints parents
before children, so containment order is z-order. Attribute methods are the only writers
to the bitmap; forms never touch the context directly.

Napkin text wraps. The pen is x,y inside the parent frame: measure the next word; if it
fits before the right edge, draw and advance; otherwise drop a line; stop at the frame's
bottom. No per-line frames — frames are layout-time artifacts, and minting them during the
display walk means the walk writes to the tree it is walking.

Word measurement is one method on Display, single site. The napkin answers "does this word
fit" with the current font's crude advance. The typeset option — a pre-pass that runs
before display, uses real metrics, and produces structure (line frames, page frames) which
the ordinary walk then paints — swaps real metrics in at that same site. Typeset is HPDL,
parked with its seam named. A page of printout is a Display whose frame has page
dimensions; how pages leave the building is a blit question, not a drawing one.

> ⚠ **FLAG RAISED AT INSERT TIME (Clod, 2026-08-06) — NOT PART OF THE RULING, and it wants
> a sentence from the director or designer.** The last paragraph puts **word measurement on
> Display**; **§10.2 below rules that metrics do NOT belong on Display** and puts `widthOf` /
> `breakAt` on **Font**, on the argument that *"if `widthOf(text)` is a Display method you
> need a Display to compute the size of the Display."*
>
> The two are **reconcilable and possibly already agree** — if Display's measure method is a
> **facade** (`Display.measure(word)` → current style's font → `Font.widthOf`), then Font
> still owns metrics, layout can still measure with no Display in existence, and §10.0's
> "single site" is about **where the draw walk asks**, not about where metrics live. That
> reading costs nothing and preserves both.
>
> They **conflict** only if the measure method is meant to *own* the metric. **Not settled
> here** — recorded so a resurrection-reader meets the tension instead of picking whichever
> section they read first.

### 10.1 What this supersedes

**§6(b)'s text model.** That section has text and cells drawing themselves as
NSTextView/NSTextField **subviews**, with the reconcile pass owning every
`addSubview` / `removeFromSuperview` / `makeFirstResponder`. Under §10 there are
no content subviews: text is rendered into the bitmap like everything else.

Most of §6 survives and gets *simpler*: the dirty signal, whole-window-redraw
v1 policy, the recursion guard, and the trigger wiring all stand. What goes away
is the reconcile pass's subview bookkeeping — no mark-and-sweep, no rebuild-on-
structural-change, no first-responder juggling.

**The cost, and it is real: editing.** NSTextView was giving caret, selection,
key handling and IME for free. Drawing text into a bitmap gives all of that back
to us. **Tony's decision, 2026-07-25: take the overlay route as plan A.**

- **PLAN A (chosen).** Keep exactly one NSTextView overlay, created only while a
  field is being edited, destroyed on commit, with the committed text blitted
  back into the bitmap. Far less work, and it preserves the decision's intent —
  Apple does no *layout* and no *rendering* of our content, it hosts one editor
  widget briefly. Note this is the ONLY surviving use of §6(b)'s subview
  machinery, and it is one widget with an explicit lifetime rather than a
  reconcile pass that owns a tree of them.
- **PLAN B (fallback, not now).** Implement caret, selection and key handling
  directly over the Display surface. Only worth it if the overlay proves
  unworkable — e.g. if matching the overlay's text layout to the bitmap's
  rendering pixel-for-pixel turns out to be the hard part, which is the risk to
  watch: the overlay must appear in the same place, at the same size, in the
  same font as what the bitmap will show after commit, or the field visibly
  jumps when editing starts and ends.

### 10.2 The one structural decision: metrics do NOT belong on Display

Layout must measure text before it can place it, and must place things before it
knows how big the bitmap needs to be. If `widthOf(text)` is a Display method you
need a Display to compute the size of the Display.

So the surface splits in two:

- **Font owns metrics** — pure functions of font + string, no bitmap required:
  `widthOf`, `lineHeight`, `ascent`, `descent`, `breakAt(text,width)`.
- **Display owns drawing** — side effects on pixels, nothing else.

Layout calls the first repeatedly, decides a geometry, *then* creates a Display
and calls the second. Same reconcile-then-draw phase separation §6 already wants.

### 10.3 Coordinates: top-left, y-down, always

CoreGraphics is origin-bottom-left, y-up. Layout and text both think top-left,
y-down — the y-flip already had to be hand-fixed once during the GUI session.

**Display exposes top-left, y-down.** The CG implementation flips internally and
the convention never leaks. Kills a recurring bug source and removes a
translation layer if the backend is ever swapped.

### 10.4 The surface — about fifteen calls

```
state    setFont(font)  setColor(color)  setLineWidth(n)
draw     fillRect(x,y,w,h)   strokeRect(x,y,w,h)   drawLine(x1,y1,x2,y2)
         drawText(text,x,y)  drawInto(display,x,y)
clip     pushClip(x,y,w,h)   popClip()
life     display(w,h)   clear()   width()   height()
metrics  (on Font) widthOf(text)  lineHeight()  ascent()  descent()
                   breakAt(text,w)
```

`drawText` takes **top-left, not baseline** — the implementation subtracts
ascent. Baseline is a typesetting concept and layout should not have to know it.

Small enough to reimplement on a different substrate in a week, which is the
point.

### 10.5 The portability boundary is one grep

What must never appear in kant code: `CGContextRef`, `CGImageRef`, `NSFont`,
`NSColor`, `CTLineRef`. Kant sees numbers, strings, and opaque handles it never
dereferences — a font ID, a display ID. If an Apple type name shows up on the
kant side the boundary has leaked, and you find out with a grep rather than a
rewrite. That satisfies "don't make portability harder" without doing any
portability work now.

### 10.6 The implementation floor is smaller than it looks

A `CGBitmapContext` **is** a bitmap. Draw into it with CoreGraphics, hand the
CGImage to the view; the Apple-side code becomes a blit. All drawing/text/font/
colour work lives behind §10.4's surface.

For text, CoreText's `CTLine` gives metrics and drawing from the same object —
create a line from an attributed string, ask typographic bounds for
width/ascent/descent, draw it. That covers the first cut of **both halves** of
the surface. Rects, lines and clipping are direct CG calls. No font-file
parsing, no glyph rasterization, no shaping.

And it is exactly where a later swap would land: `Font` reimplemented over
FreeType for metrics, `drawText` over a scanline rasterizer (AGG, Blend2D, or
`stb_truetype` for a simpler cut). Nothing above the boundary changes. **Do not
write a rasterizer now** — text rendering done properly is glyph rasterization,
hinting, shaping, kerning and line breaking, and that is a multi-year project.

**Where metrics come from, and the one landmine (checked 2026-07-25).** The
Google Fonts Developer API (`webfonts/v1`) returns metadata only — family,
variants, subsets, version, files, category, menu. **No metrics.** That is the
same `webfonts#webfontList` shape already in `incant/jsonTest`. Metrics come from
the font file itself, and CoreText reads them: once `registerFontFile` lands
(§5.3-5.4), `CTFont` gives ascent/descent/leading/advances directly. The API
delivers; the platform measures. (For bulk metrics without loading fonts — a
picker preview, say — khempenius/font-fallbacks-dataset publishes a
`font-metadata.csv` with ascent/descent/line-gap/UPM/glyph-widths for the whole
library. Not on the critical path.)

**THE LANDMINE, and it is a portability one.** A font carries TWO sets of
vertical metrics. Per Google's own metrics guide, **hhea is what macOS reads**,
while Windows reads the OS/2 Typo values when `Use_Typo_Metrics` is enabled.
They are *supposed* to be identical and usually are, with exceptions where the
primary script is not Latin/Greek/Cyrillic. So CoreText silently picks one, and
every line height in every form gets calibrated against that choice. If FreeType
ever replaces CoreText, **read the same table deliberately** — otherwise every
layout shifts and the cause is invisible. Cheap to know now, baffling later.

### 10.7 `print form to X` — one walk, three back ends

```
print form;              -> text        (what printDefinition does now)
print form to buffer;    -> RTF / HTML
print form to display;   -> pixels
```

Same traversal of the form, different emitter — structurally the same idea as
genParse (walk a structure, emit through a swappable back end). The payoff:
**the text emitter is the debugging tool for the display emitter.** When the
bitmap looks wrong, print the same form to text and diff it. Build them as one
walk and the diagnostic is free.

Independent motivation, from a direction nobody planned: genParse's §6.5 harness
(`genParseSpec.md`) needs to diff two parse trees, and the text form of a form is
exactly the thing you diff. `incant/json1` is already that harness in prototype.

### 10.8 Deliberately not designed yet

- **Paths and curves.** `displayPath()` is a known gap and it is the expensive one.
- **Sub-display compositing and dirty-region caching.** Natural given the field
  model — each block could own a Display and only re-render dirty subtrees — but
  it is an optimization and wants real forms to justify its shape.
- **Scrolling.**
- **Text editing** (§10.1) — the one that needs a decision rather than deferral.

All of these bolt on above §10.4's surface without disturbing it, which is the
test of whether stopping here is safe.
