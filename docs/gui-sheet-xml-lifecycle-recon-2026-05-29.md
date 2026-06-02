# GUI Architecture Recon — 2026-05-29

**Scope.** `Groups/GUI/` — 42 files, ~11.5K lines of `.mm`. Probe
question: "how does `sheet.xml` become a window?" — used to drive
depth-first reading, not to catalog. Output is an architectural map of
the GUI runtime, with explicit notes on what's load-bearing,
planned-replacement, and salvageable.

**Steering from Tony at start of recon** (preserved in memory):
- `GUI/Layout.twk` is the windowing approach Tony wants to **redesign**,
  not port. It works; he doesn't like it.
- `GUI/Groups.{g,act,rtn,twk}` is the **drawing language** parser, not a
  GroupItem or window grammar. Name is misleading.

## Bottom line

The runtime is small in concept, three layers:

1. **Cocoa scaffolding** (GroupUIAppDelegate, Delegate) — boilerplate.
2. **Dispatch architecture** (Bwana, Actions, Map.rtn) — XML attribute
   names register C-handler function pointers; when the parsed window
   tree is walked, each attribute fires its handler. This is the
   architectural backbone — same idiom as incant's `cOMMANDs` registry.
3. **Rendering strategy** (Layout, Details, Stylish) — what's in the
   tree today is HTML generation into `WKWebView`. Confirmed via
   `Layout.mm:146`: `[webView loadHTMLString:[NSString stringWithCString:
   htmlText encoding:...] baseURL:stubURL];`.
   **CORRECTION post-recon (Tony, 2026-05-29):** the HTML/WebKit
   approach was a late experiment, *not* the main path that drove the
   spreadsheet app. Tony's "most successful try had nothing to do with
   WKWebView." So the code in the live `Layout.{h,mm,twk}` represents
   the *last attempt*, not *the* approach. The earlier-and-better
   approach likely lives in archived directories (`Aside/`,
   `OLDtawkDoNotTouch/`) — same pattern as ParseXML. Either way, Tony
   wants a complete overhaul of the windowing bit — the question for
   Clay is "what's the new design," not "which past approach do we
   port."

Two independent concerns ride alongside: a small **drawing language**
parser (`Groups.{g,act,rtn,twk}`) and a **data-source abstraction**
(`Source`) for binding widgets to GroupItem collections. Both are
salvageable independent of the HTML-via-WebKit decision.

## The lifecycle of sheet.xml

The XML window definitions don't get parsed in `GUI/` at all — they
get parsed by **ParseXML** (archived, see
`plg-delimited-file-recon-2026-05-29.md`). The GUI subsystem
**consumes** the resulting GroupItem tree.

End-to-end, conceptually:

```
1. App launches → GroupUIAppDelegate → Control instantiated
2. Control creates Bwana (overseer)
3. Bwana.registerMethods() → builds the dispatch table:
       mapMethod("window",   ::wINDOW)
       mapMethod("popup",    ::popUP)
       mapMethod("source",   ::sOURCE)
       mapMethod("matrix",   ...)  // (and ~45 more)
   Actions.registerActions() registers another set (dISPLAY, fIRE, mENU, etc.)
4. ParseXML reads sheet.xml → parsed GroupItem tree
5. Tree is walked; each attribute name dispatches to its registered
   C handler via the Bwana table
6. Handlers mutate the tree, attach Source bindings, install layout
   traits, register events
7. Layout (NSView wrapping a WKWebView) generates HTML from the
   processed tree; loadHTMLString puts it in front of the user
8. WebKit calls back through the Delegate protocol for navigation,
   resize, etc. — Layout responds and mutates state
```

**The two parsers in the system don't talk directly**: ParseXML reads
the window XML; GUI reads the result. Groups.g (drawing) is a third,
orthogonal parser used inside specific draw-path attributes.

## Class roster (file: lines, role, status)

| File | Lines | Role | Status |
|---|---:|---|---|
| `GroupUIAppDelegate.{h,mm}` | 39 | Cocoa NSApplicationDelegate. 2010-vintage boilerplate. | **Replace** — pure scaffolding. |
| `Control.{h,mm,twk}` | (twk) | Top-level controller. Holds `root`, `activeView`, `delegator`, `flexLayoutStash`. | **Keep** — orchestration layer. |
| `Bwana.{h,mm,twk}` | 1700+ | Overseer / dispatch table. `mapMethod("name", ::cHandler)` registers ~45 attribute→handler bindings. Owns `actions`, `extendParser` (Groups drawing parser), `descriptions`/`types`/`windows` registries, `expandables`/`emptySource`/`selectSource` Sources, `delayActions` stack. | **Keep** — same pattern as incant cOMMANDs. |
| `Actions.{h,mm,twk}` | ~? | Second dispatch table (11 handlers: dISPLAY, fIRE, gotoCARD, iMAGEwork, mENU, reBIGIFY, sELECTtab, sORT, setFLEXcontent, tOGGLE, xPAND). Action-style attributes split off from Bwana's structural set. | **Keep**, but **merge** into Bwana? Worth asking why split. |
| `Map.rtn` | (rtn) | Additional handler implementations (aCTION, bigifyCheck etc.). Lives in PLG `.rtn` format — older glue. | **Lineage check** — overlaps with Bwana? |
| `Layout.{h,mm,twk}` | 433 (mm) | `@interface Layout : NSView <WKNavigationDelegate>`. Holds `WKWebView`, generates HTML, `loadHTMLString`s it in. **Note**: this is a *late experiment*, not the historical main approach; the more-successful prior implementation likely lives in `Aside/` or `OLDtawkDoNotTouch/`. | **REDESIGN** — complete overhaul, not port. |
| `Details.{h,mm,rtn,twk}` | 1129 (mm) | Per-element display info: `wig`, `object`, `draw` (SEL), `innerBox`/`frame`, `Stylish *style`, `Layout *view`, `event`. The "render this widget" lives here. | **Tied to Layout** — likely needs redesign too, but rendering-primitive parts may survive. |
| `Source.{h,mm,twk}` | 273 (mm) | Wrapper for a GroupItem with members exposed as an array, plus listeners, current-position, flags. This is what binds `matrix source=phone` to `phone`'s members. | **Keep** — clean abstraction, format-neutral. |
| `Stylish.{h,mm,twk}` | 117 (mm) | Style attributes (font, color, fill). | **Keep candidate** — style is style, regardless of rendering target. |
| `DrawPoint.{h,mm,twk}` | 482 (mm) | Drawing primitives — point + drawing directives (HPDL-style). | **Keep** — independent of layout. |
| `Groups.{g,act,rtn,twk,mm,h}` | 614 (mm) | **Drawing-language** parser. Grammar for path expressions: ops (`-+*/`, `%~@:!dgIlrRSTu`, `aco`), operands, curves. Independent of window definitions. | **Keep** — port as separate concern. Rename suggested. |
| `Delegate.{h,mm,twk}` | 50 (mm) | NSWindowDelegate + WKNavigationDelegate stub. | **Replace** — boilerplate, regenerate. |
| `Source/` references in incant currently | — | sheet.xml's `source=phone` / mapped cells / drill-down work through Source bindings + Bwana handlers + Layout's HTML output. | — |
| `junk.{h,mm,twk}` | 107 (mm) | Named "junk" — drop. | **Drop** unless something in it is actually used. |
| `groupDirectives` | — | TAWK directives for the GUI subsystem. | Keep as needed. |
| `GUIincludes` | 21 | Include manifest: globals, frame, maps, OCframe, plg.ext, groups.ext, GUIexternals. | Keep. |
| `Stuff/` | (dir) | Subdirectory — not surveyed. | Defer. |

## Tar babies

1. **The HTML/WebKit code in Layout is a late experiment, not the main
   path** (per Tony 2026-05-29). The historically-successful
   implementation predates this and likely lives in an archive
   directory. When this gets redesigned, the question becomes: what
   was the better prior approach, what worked about it, and what does
   the new design borrow from there? Worth a Clay conversation plus a
   second recon into the archives before deciding direction. Don't
   reason about "the windowing strategy" from `Layout.mm` alone — that
   file is one attempt of several.
2. **Bwana and Actions are two dispatch tables in the same idiom.**
   Why split? Likely because `Actions` was added later for
   action-attribute handlers specifically; `Bwana` is the older
   structural set. Worth understanding the split before reproducing it
   in incant.
3. **Map.rtn duplicates handler space.** `aCTION`, `bIGIFY` etc. have
   implementations in both `Map.rtn` and headers reference them from
   `Bwana.h`. Some lineage / dedup work needed before port.
4. **Source is format-neutral and small.** This is the binding
   abstraction Tony's "pretty cool spreadsheet" relied on. The
   `current` index + `listeners` + sorted/exhausted flags pattern is
   clean. Keep this shape.
5. **Drawing language is fully separable.** `Groups.{g,act,rtn,twk}` is
   a tiny self-contained DSL — 4 components (operators, x-offset,
   y-offset, optional control points), parses directly to draw-path
   GroupItems. Could be the first GUI piece to port to incant
   independent of any layout decision.
6. **GroupUIAppDelegate is dated 2010.** Pure Cocoa scaffolding, "Created
   by anthony on 1/8/10". Boilerplate; regenerate from a modern
   template.
7. **WKNavigationDelegate on Layout.** Layout is both the layout view
   and the webview-navigation delegate. The role conflation makes the
   "which class does what" question harder than it needs to be.

## Findings (no fixes)

- The **dispatch-table pattern** (Bwana's `mapMethod`) is exactly
  incant's `cOMMANDs` registry idiom. Porting the GUI dispatch
  layer = "create another base registry, register handlers into it
  the same way `setup` does." Cheap.
- **Layout / Details / Stylish are intertwined**: each holds pointers
  to the others (Details has `Stylish *style` + `Layout *view`; Layout
  has `Details *detail`). Redesigning Layout will ripple through
  Details. Plan accordingly.
- **`expandables` / `expandTREE` / `cOLLAPSErow`** in Bwana suggests
  collapsible-tree machinery alongside the matrix. sheet.xml's
  drill-down (right-click → popup with cell contents) probably uses
  this. Worth understanding before redesign.
- **Two registries hold window definitions**: `descriptions` and
  `windows` (both `GroupItem*` in Bwana). Plus `types`. Three-way
  split worth unpacking — naming suggests metadata vs. live
  instances.
- **Tape** class is forward-declared in `Control.h` but not seen in
  the GUI/ directory listing. Either lives elsewhere or got dropped.
  Tar baby to chase only if it's load-bearing.

## Port-to-incant recommendation

When GUI work cycles back:

1. **First conversation with Clay is design, not migration.** Layout
   strategy is the up-for-revision piece; pin that down before
   touching code.
2. **Port independently, low-risk first**:
   - **Drawing language** (`Groups.{g,act,rtn,twk}` → incant
     `drawing` file plus a `Drawing.rtn` for externs). Renames suggested:
     call the incant file `drawing` (not `Groups`).
   - **Source abstraction** — small, clean, format-neutral. Maps to a
     GroupItem + listeners pattern in incant.
   - **Dispatch backbone** — create `wINDOW`, `pOPUP`, `sOURCE` etc.
     as incant commands in a new registry `wINDOWattrs` (or extend
     `cOMMANDs`). Bwana's `mapMethod` calls become entries in that
     registry's `setup` block.
   - **Stylish / DrawPoint** — likely portable as-is; rendering
     primitives don't care about layout strategy.
3. **Hold for design**:
   - **Layout** — design pass needed.
   - **Details** — likely tied to layout decision; defer.
4. **Drop / regenerate**:
   - GroupUIAppDelegate + Delegate (Cocoa boilerplate).
   - junk.{h,mm,twk}.
5. **Investigate before porting**:
   - Bwana vs. Actions split.
   - Map.rtn vs. Bwana.mm overlap.
   - Stuff/ subdirectory contents.

## Tar babies for follow-up recons

If more investigation time appears:

- **Bwana.registerMethods() full inventory.** What are all ~45
  attribute handlers, what do they do, and which fall into "structural
  / source / style / event / draw" buckets? Useful for planning the
  incant `wINDOWattrs` registry shape.
- **Details.mm walkthrough.** 1129 lines is the densest file in
  GUI/; understanding it is required for the redesign conversation.
- **Stuff/ subdirectory.** Not opened — may be supporting headers,
  may be dead code.
- **Bwana / Actions / Map.rtn lineage.** Why three places for handler
  implementations? Probably refactoring archaeology.

## Memory updates

Notes saved during recon and follow-on conversation:
- `project_gui_layout_to_redesign.md` — Layout is for redesign, not
  port. The HTML/WebKit code is a late experiment, not the historical
  main path.
- `project_groups_g_is_drawing_language.md` — Groups.g is the drawing
  parser, not window XML.
- `project_gui_runtime_design_sketch.md` — Tony's working direction
  for the GUI overhaul (captured 2026-05-29). incant owns
  scene/layout/render/hit-test/events; Apple is a thin shim for
  window+bitmap+text-input only. Skia/Flutter pattern. Read this
  before reasoning about the GUI port — the recon describes what's
  there; the sketch describes what's coming.
