# setWindow — Recon + Try-and-Buy Plan (2026-07-02)

*Answers Tony's offline-report item: "windows defined in incant... recon for setWindow and
related methods in oldGUI... try and buy version of setWindow... pop ups and panels as well
as main window creation."*

## 1. Recon summary — what oldGUI's window/panel/popup actually did

The live code is `GUI/Map.rtn:1320` (`wINDOW`), registered via `mapMethod("panel",wINDOW)` /
`mapMethod("window",wINDOW)` in `GUI/Bwana.twk:137,139`. Orchestration lives in
`GUI/Control.mm` (`Control::start`) and `GUI/Bwana.h` (the `windows` hash, `docs/gui.md:682`).

**Window/panel creation (`wINDOW`, `GUI/Map.rtn:1320-1373`):**
- Style mask built from `closable`/`title`/`resize` attributes on the block (same 3 flags the
  current `GroupDraw.twk:setWindow` stub already reads).
- **Three-way branch**, not two: `item.parent == root` → reuse `bwana.window` (the one root
  window, created once outside this method — see Control::start below); `or isPanel` → `new
  Panel(frame,mask,buffered,true)`; `else` → `new Window(frame,mask,buffered,true)`. The
  current stub only has the panel/else branch — it's missing the root-reuse case entirely.
- Frame math: pulls `x`/`y` overrides off the block (`windowBlock%"x"`/`%"y"`), sizes from
  `detail.width`/`detail.height` (the old Details geometry sidecar, not plain `frame`
  attributes — see `docs/font-recon.md`'s "Details shadow-geometry tree" flag, same blocker
  recurs here), corrects height for the title-bar delta same as the current stub does.
- Title: `window.setTitle(name)` only `if mask & titled`.
- **Content view wiring** (the biggest thing the current stub stubs out): `view.add(webView)`
  — every old window also hosted a `WbView` (a Cocoa WebKit view) alongside the layout, with
  `layout` set as its `navigationDelegate`. **This is legacy-specific — the new architecture
  almost certainly does NOT want a WebKit view baked into every window** (that's what the
  separate webChannel/socket work is for). Treat the `webView` lines as **do-not-port**, but
  keep `view.add(layout)` + `makeFirstResponder(layout)`.
- `detail.view.deselect()` at entry, `mustDisplay(true)` + `setModified(wig)` at exit.
- Each `item` (block) has its own `Details.view` — a **`Layout` already constructed earlier**
  in the per-item pipeline (`item.getDetail()` → `detail.view`), *not* created inline by
  `wINDOW`. `wINDOW` only *places* an existing Layout into a new window's content view.

**Root window + delegate (`Control::start`, `GUI/Control.mm:1145-1179`):**
- The **one root `NSWindow`** is created *outside* `wINDOW` (by the app-launch path, not
  shown in this recon — `wINDOW` only reuses it via `bwana.window` when `item.parent == root`).
- `[window setDelegate:(id)delegator]` — delegate is a **separate hand-rolled `delegator`
  object**, not the Layout itself, despite today's `Layout implements WindowDelegate` +
  `windowWillClose` (root `Layout.twk:153-157`). This is a design fork point, not a straight
  port — see §3 open decision D1.
- Iterates top-level blocks with a `window` or `panel` attribute and calls `layout(group)` for
  each (this is the multi-window entry point — a "shell" loadedItem can define several
  windows).
- **`bwana.windows->hashList->length == 0` guard**: if nothing produced a window, synthesizes
  an `<error window closable text>No window block found</error>` block and lays it out — a
  fallback so the app never launches with zero windows.
- `[window makeKeyAndOrderFront:window]` + `[window display]` at the very end, once, after all
  blocks are laid out.

**Popups (`GUI/Actions.twk:11-26` / `GUI/Actions.mm`):**
- A popup is a **named, cached window** in the `windows` hash on Bwana (`docs/gui.md:682`):
  `block = windows[name]`. First reference to a given popup name lazily loads it — if absent
  *and* the block has a `file` attribute, it sets a flag `convertWindowToPanel = true`, calls
  `controller.load(wig)` (parses the XML file, which recurses into `wINDOW` for whatever
  `window`/`panel` block that file defines), then re-fetches from `windows[name]`. The
  `convertWindowToPanel` flag is read somewhere inside the `wINDOW`/load path to force the
  `isPanel` branch — i.e. **a popup is implemented as a Panel, not a distinct API** — confirms
  `docs/gui.md:111` ("`Control.convertWindowToPanel` downgrades... popups").
- Once resolved, `detail = block.getDetail()` and the caller proceeds to show/position it
  (truncated past `Actions.twk:27` in this recon — the show/position logic wasn't chased
  further; low risk, it's cosmetic once the panel exists).
- **Caching is the whole popup/panel distinguishing feature**: same window machinery as a
  regular window, just keyed by name so repeat triggers reuse instead of re-creating.

## 2. Gap analysis — current `GroupDraw.twk:setWindow` stub vs the above

| Old GUI (`wINDOW` + `Control::start`) | Current stub (`GroupDraw.twk:21-51`) | Gap |
|---|---|---|
| 3-way branch: root-reuse / panel / window | 2-way: panel / window only | **Missing root-window-reuse case** — every call currently makes a fresh window, no single-root-window concept |
| `view.add(layout)` where `layout` = the block's *own* pre-existing `Details.view` | `//layout = new(framed); layout.base = block;` **commented out**, then `setContentView(layout)` against GroupDraw's single shared `layout` ivar | **No per-block Layout is ever created or attached** — every window would show whatever `layout` last held, or nothing. This is the stub's biggest hole, exactly as flagged in the fork brief. |
| `window.setDelegate` set once on the root window in `Control::start`, using a separate `delegator` object | **No delegate wiring at all** | `windowWillClose` on the (new) `Layout` (`Layout.twk:153`) is dead code today — never fires because nothing calls `setDelegate` |
| `bwana.windows` hash: bookkeeping + the "no window block" fallback + popup name-cache | **No registry at all** | No multi-window bookkeeping, no popup cache/reuse, no launch-time fallback |
| `x`/`y` override attributes read from block | Not read | Minor — positioning always defaults to the frame's own math |
| WebKit view attached to every window | N/A | **Do not port** — flagged above as legacy-specific, not a gap |
| Popup = named cached Panel, loaded from a `file` attribute if not yet cached | No popup concept | Whole popup mechanism absent — expected, it's explicitly Tony's next-scope ask |

## 3. Try-and-buy implementation plan

Scoped as small steps; each should `tok`+build+run clean before the next. Steps 1-3 get main
window creation fully working (today's stub's core gap); 4 adds the registry/bookkeeping that
popups need; 5 adds popups on top. Steps map roughly 1:1 to separable commits.

1. **Wire a fresh `Layout` per window.** Replace the commented-out
   `layout = new(framed); layout.base = block;` with a live call (today's `Layout` class ctor
   is `Layout init(GroupItem field)` — root `Layout.twk:121-126` — so this becomes
   `layout = new(); layout.init(block);` or equivalent per whatever `new` actually threads
   through to `init` in this codebase's construction convention). Replace `setContentView(layout)`
   → `view.add(layout)` (matches old GUI; `setContentView` alone likely isn't the right call —
   verify against the `View`/`Window` typedef wrapper). Drop the dead shared `GroupDraw.layout`
   ivar once no longer needed (or repurpose it as "most recently created," if useful for D1
   below). **Verify:** build, run against a single-window test fixture, confirm the window
   shows the block's content (visually, or via a debug `cout` if headless).

2. **Wire the window delegate.** Decide D1 (below) first. If the answer is "Layout is its own
   delegate" (the simpler, already-half-built option since `Layout implements WindowDelegate`
   already): add `window.setDelegate(layout)` right after `view.add(layout)` in step 1's edit.
   **Verify:** trigger a close (Cmd-W or the window's close button) and confirm
   `windowWillClose`'s `cout "Window closing: will exit"` + `exit(0)` fires.

3. **Root-window-reuse branch.** Add the `item.parent == root` (or equivalent — confirm how
   "top-level block" is spelled in the current tree-walk convention) check ahead of the
   panel/window branch, reusing a single held root `Window` instead of always constructing new.
   Decide whether GroupDraw (or a new small owner, see D2) holds that single root-window
   reference. **Verify:** two top-level window blocks in one input still each get their own
   window; a second call against the *same* top-level block does not leak a second window.

4. **Window registry.** Add a hash (`BaseHash` per old GUI, or whatever the current codebase's
   idiomatic map type is) holding open windows by name/tag, populated in `setWindow`. This is
   the prerequisite for popup caching (step 5) and gives a natural home for a "no window block
   found" fallback (port the `Control::start` guard if a bare-binary entry point wants it —
   may be out of scope if `main()`'s shell-loading path already guarantees at least one window
   block; check before porting the fallback verbatim).
   **Verify:** open two windows, confirm the registry holds two distinct entries; close one,
   confirm bookkeeping (whatever cleanup convention fits — a `windowWillClose` hook is the
   natural place to deregister) removes it.

5. **Popups.** Add the named-cache lookup pattern from `GUI/Actions.twk:11-26`: on a `popup`
   attribute, look up by name in the step-4 registry; if absent, load/build it (mirroring
   `controller.load` — likely just "run `setWindow` on the popup's own block definition") and
   cache it; if present, reuse/reshow it instead of rebuilding. Popups are Panels (`isPanel`
   forced), matching old GUI's `convertWindowToPanel` — so this step should be able to ride the
   panel branch built in step 1 with no new window-creation code, only the cache-or-build
   *policy* wrapped around it.
   **Verify:** trigger the same popup twice; confirm the second trigger reuses the first
   window object rather than creating a new one (e.g. compare object identity via a debug
   print, or visually confirm no duplicate window appears).

### Open decisions for Tony (do not guess these)

- **D1 — delegate ownership.** Old GUI used a separate hand-rolled `delegator` singleton for
  the *root* window only (`Control.mm:1150`), while today's `Layout` already declares
  `implements WindowDelegate` with a working `windowWillClose`. Simplest path: every window's
  delegate is its own content `Layout` (no separate delegator object needed at all — one fewer
  class to port). Confirm this is intended before step 2, since it's a real behavior change
  from old GUI (root window delegate ≠ its content view there) rather than a straight port.
- **D2 — registry ownership.** Old GUI hangs `windows`/`fontManager`/etc. off a `Bwana`
  singleton-overseer object (`docs/gui.md` Appendix B) that doesn't otherwise exist in the new
  architecture. Does the window registry belong on `GroupDraw` (already the `setWindow` owner),
  a new small singleton, or somewhere else? Affects step 3 and step 4's implementation, not
  their external behavior — worth deciding once rather than per-step.
- **D3 — WebKit view.** Confirmed **not** wanted per this plan's read (webChannel/socket work
  covers that ground differently) — flagging explicitly in case that's wrong, since silently
  dropping it is an actual behavior change from old GUI, not a neutral simplification.
- **D4 — Details geometry dependency.** Old `wINDOW` sizes off `detail.width`/`detail.height`
  (the Details shadow-geometry tree — `docs/font-recon.md`'s flagged blocker). Today's
  `GroupDraw.twk:getFrame` reads plain `x`/`y`/`width`/`height` attributes directly off the
  GroupItem instead — simpler, and probably the intended new direction, but confirm this
  doesn't need to inherit any of Details' behavior (e.g. `x`/`y` block-level overrides, which
  old `wINDOW` reads separately via `windowBlock%"x"`/`%"y"` — worth folding into `getFrame`
  or handling explicitly in step 1/3 if window positioning ever needs it).

## Sources
- `GroupDraw.twk:21-51` (current stub, post-dedup commit `dae8ec9`)
- `GUI/Map.rtn:1320-1373` (`wINDOW`)
- `GUI/Bwana.twk:137,139` (mapMethod registration)
- `GUI/Control.mm:1123-1179` (`Control::setup`/`Control::start`)
- `GUI/Actions.twk:11-26`, `GUI/Actions.mm` (popup lookup/cache)
- `docs/gui.md:565-567, 629-660 (bear traps), 663-684 (Bwana field inventory)`
- `Layout.twk:6, 121-126, 153-157` (root `Layout` class decl, `init`, `windowWillClose`)
- `docs/font-recon.md` ("Details shadow-geometry tree" — same blocker resurfaces here)
