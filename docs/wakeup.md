# Incant — Status & Handoff (2026-06-25)
*Written by Clod for a fresh Clay/Clod tomorrow. Assumes no memory of today. Self-contained.*

## Headline
A big GUI day. The arc went from "a bare window opens" to **the field-at-a-time thesis proven
end to end at the window envelope**: a form's own attributes now drive a real Cocoa window's
**size and position**, a stable Layout paints into it, and the `window` attribute fires the
window via clean define-then-show wiring. The platform is solid; **content dispatch
(text/image/cell/path) is the next frontier** and is teed up for a Clay design conversation.

All five commits below are **pushed to `main`** (`758bb5a..767d16c`).

## Verify it still works (do this first)
```
~/bin/incant incant/oneTest      # bytecode battery -> "maximus = 26" (testByteCode 11, testIfElse 26)
~/bin/incant incant/jsonTest     # -> "ok  : {"a":[]}" / "ok  : {"a":["x","y"]}"
~/bin/incant incant/jitscratch   # JIT POPs -> green readbacks
~/bin/incant Tests/windowTest    # opens a 300x520 window, upper-right, paints, closes clean
```
`windowTest` blocks in the Cocoa run loop until you close the window (close -> terminate, exit 0).
To run it non-interactively (CI / quick check), cap it:
`script -q /dev/null perl -e 'alarm 5; exec("/Users/anthony/bin/incant","Tests/windowTest")'`
(Boot noise `getRStuff:` / `aCTionDefinE:` is normal.)

---

## TODAY'S COMMITS (all on `main`)
- `5f74ab2` — **Back to green: rip out MEMBERing.** The working tree was red (oneTest +
  jsonTest both failing) from an offline experiment: a `MEMBERing` flag copied into the
  `MemberS` grammar rule (mirroring `DEFINing`) silently broke the member-list parse of *every*
  define -> JSON alternation and bytecode-gen both died. Removed it entirely (grammar +
  GroupMain bootstrap + the dead flag/`case 'M'`). Restored two innocent GroupItem edits
  (clearList null-on-empty, isTOKEN compare case) reverted during bisection.
- `2898b62` — **gui-brief.md** — Clay-facing GUI design brief (one page + drill-down index into
  the 923-line gui.md) + the content-handler port recon (salvage the rendering cores, don't lift
  the old tree-walking; subview-vs-direct-draw split; incant-owned cell recursion).
- `4d40f56` — **Stable painting window.** Native `guiHost.mm` host (tok can't parse inline
  `[bracket]` sends -> moved Apple out of tok). drawRect crash fixed: the recursive
  `GroupItem.walk` scaffold descended into scalar attribute leaves (null `groupList`) and
  SIGSEGV'd -> replaced with a flat read-only `nextAttribute` loop.
- `39d71dd` — **window-attribute binding (markWindow).** A form's `window` attribute fires
  `markWindow` at define time (marks `isWindow`, NO open) — define-then-show; explicit
  `openWindow(form)` is the separate raise trigger. Modeled on `listenTo` (parent-targeting via
  `fLAG`). **Required an out-of-repo groups.ext edit** (see Traps).
- `767d16c` — **Window envelope from the form.** `openWindow` sizes+positions the window from
  `getFrame(input)` (was hardcoded 480x360), with a y-flip (forms top-left, Cocoa bottom-left).
  Plus the **GC root fix** that killed an intermittent wild-pointer crash (see below).

## The GUI platform as it stands
- **Host** = `guiHost.mm` — a hand-written ObjC++ file, **compiled directly by the Groups Xcode
  target, never through tok**. `extern "C" openWindow(GroupItem*)` dlsym-binds to the incant
  command (`incant/setup: openWindow immediateAction=openWindow`). It creates the NSWindow,
  hangs a `Layout` as contentView (`view->base = input`), runs the loop, terminates on close.
- **Two independent `getFrame` levels** (the settled design): `openWindow` calls `getFrame(form)`
  for the **window envelope** (size + screen position); `Layout.drawRect` calls `getFrame`
  per-field for **content** position *within* the view. Each level reads the frame it needs —
  Layout keeps its autonomy. Both read the same `setFrame`-populated x/y/width/height attributes.
- **drawRect** currently does a flat read-only `nextAttribute` pass stroking rectangles — a
  *stable platform*, not the destination. Real content dispatch hangs off it next.
- **The binding**: `window immediateAction=markWindow noPrint` (setup). `markWindow`
  (Commands.rtn) takes `input.parent`, guards `if input.fLAG`, sets `isWindow`. Define-then-show.

## Hard-won traps banked (CLAUDE.md Bear Traps + memories)
- **#10 — adding a GroupBody flag needs `groups.ext` sync AND `tokall`, or it fails silently and
  catastrophically.** A new `bools` flag isn't enough: cross-file code resolves `field.newFlag`
  against the `external GroupItem` block in **groups.ext**, not the class. Miss it and tok's
  parse error (single-pass, no lexer) **cascades and wipes the entire extern block** from
  GroupRules.h (0 vs ~144) -> Bytecode.mm fails on "no member `opEQ`". And a GroupBody change
  shifts the bitfield -> **tokall**, not a single retok.
- **#11 — `groups.ext` lives OUTSIDE this repo** at `~/Dropbox/data/InProcess/Include/groups.ext`
  (via `groupIncludes`). Real build dependency, NOT git-tracked here. Edits to it never show in
  `git status`/commits; a fresh checkout won't build until it carries them. **The markWindow
  commit needs an out-of-repo groups.ext edit (isWindow field + markWindow extern) to build.**
- **tok can't parse inline `[obj msg]` brackets** — throws `ERROR Inheritance` and drops the
  whole function. Pure dot-syntax via OCframe wrappers, OR a hand-written `.mm` (what guiHost is).
- **GC vs Cocoa**: `GC_set_no_dls(1)` is load-bearing (dodges AppKit's framework-load root-set
  storm -> "Too many root sets" abort) but blinds BDWGC to incant's own data segment, so objects
  reachable only through ObjC-allocated views get collected mid `[app run]`. Fix:
  `GC_add_roots(&GroupControl::groupController, ...)` re-roots incant's whole graph (one root set).
- **`nm`, not `strings`**, to check a symbol is compiled in (strings gave false negatives). Binary
  mtime is unreliable; interpreted `incant/*` runs fresh regardless.
- Build = `xcodebuild -project ../TOK/TOK.xcodeproj -scheme Groups -configuration Debug build`;
  `~/bin/incant` symlinks to the DerivedData product. `.twk` -> `tok` first; `.rtn` and the
  native `guiHost.mm` compile directly.

## THREE LOOSE ENDS (next session)
1. **Drop the diagnostic `printf`** in `guiHost.mm` (`getFrame(form) -> ...` line) — it served
   its purpose proving size/position flow.
2. **Resize** — `Layout.viewDidEndLiveResize` -> re-run layout. The next envelope feature;
   `setFrame` + `getFrame` already provide the machinery.
3. **Content dispatch** — the big one. drawRect's `nextAttribute` stub becomes real content
   rendering: route each field to `displayText`/`displayImage`/`displayCell`/`displayPath`.
   **This is Clay's design conversation** (see below).

## FOR CLAY — content dispatch design context
Two docs are the brief: **`docs/gui-brief.md`** (the design thesis + open questions + the
content-handler port position) and **`docs/font-recon.md`** (font/color model archaeology).
The decision to settle *before* code moves: **subview vs. direct-draw**, forced by content
nature — text needs a live NSTextView subview (cursor/selection/editing state); image/path/cell
are stateless direct-draws in drawRect. And **cell recursion is incant-owned** (incant hands
Layout each child field; Layout never walks the tree). `displayText` (commented in `Layout.twk`)
is the proven template and the lowest-risk first handler. Font/color: the model is *already
proven* (old GUI `Stylish` + `convert()` + `getRGB` seam); the question is *where it lives* —
how much lifts from C++ into incant (the `convert()` -> `realizeFont` leaf extern is the wedge).

## Key files / test targets
- `guiHost.mm` — the native Apple host (openWindow). NOT tok'd; Groups target compiles it.
- `Layout.twk` — the contentView; `drawRect` (nextAttribute stub), `displayText` (commented template).
- `GroupDraw.twk` — `getFrame` (reads x/y/width/height), `setWindow` (old dot-syntax builder, incomplete).
- `Commands.rtn` — `markWindow` (the binding handler), `listenTo` (its model).
- `incant/setup` — command registrations (`openWindow`, `window`=markWindow).
- `incant/unitTests` — `winForm` (windowed fixture, 300x520 @ 700,100), `plainField`.
- `Tests/windowTest` — the window smoke test (define winForm, openWindow(winForm)).
- `docs/gui-brief.md`, `docs/font-recon.md` — Clay's design inputs. `docs/gui.md` — full recon (923 lines).

## Parked threads (not today's work)
JIT Phase 2 (control flow / IF-FOR) — `docs/jit.md`. Bigify setFrame fill-path (multi-row
across+down) is still WIP in `incant/utilities`. JSON parser green; Google-Fonts two-step needs a
`getURLintoBuffer` extern. None blocked by today's GUI work.
