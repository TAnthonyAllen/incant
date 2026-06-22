# Layout.twk Recon — the incant-GUI redesign lens

*Tonto recon, 2026-06-18. Depth-first archaeology, not a spec. Read with the
design sketch as the lens: **incant owns the model, Layout owns the pixels.***

**Provenance:** all file:line references cite the true subject
`OLDtawkDoNotTouch/Groups/GUI/GroupUI/Layout.twk` (664 lines). It is sandbox-blocked
from the recon tooling, so it was read from an md5-verified byte-for-byte copy;
line numbers are identical. The in-repo `GUI/Layout.twk` (431 lines) and top-level
`Layout.twk` (192 lines) are **divergent forks** — not the subject, not equivalent.

---

## Orientation

`Layout.twk` is the established AppKit-based windowing/layout view. It walks a
GroupItem tree rooted at an instance field `base` (plus a parallel geometry tree
reached through `group.other`, the "Details" tree), and paints each node by
dispatching per-type via `performSelector(draw)`. The crucial finding for the
redesign: **Layout does not merely paint — it makes real frame, style, and content
decisions, and in places writes results back into the model.** That is exactly the
ownership the new design moves to incant.

Against the target vocabulary (`frame` / `type` / `style` / `action`): `style` and
`action` (= `group.method`) already have model homes; **`frame` is trapped** in the
`group.other` Details shadow tree; **`type` does not exist as a single attribute** —
it's a `performSelector(draw)` selector plus roughly a dozen BOOL flags. The split
is **~40% done**: style/action are model-resident and event dispatch is already
model-routed; the hard remainder is `frame` (Details tree) and `type` (selector +
BOOL soup).

---

## Q1 — Ownership migration: what Layout decides that should move to incant

Layout currently owns decisions in all three categories the design assigns to incant:

**Frame / geometry (the biggest offender):**
- `displayImage` (L128) computes the entire scale/crop/center fit **and writes the
  result back into the model** — `wig["oRIGIn"]` at L141/L166. This is a model
  mutation performed by the view.
- `drawRect`/`drawDetail` decide clipping (L259) and trigger the layout solve
  `layout(base)` (L319).

**Style:**
- Alignment branches (L80–86), font defaulting via the `lastFont` chain (L273/L327),
  colors (`filler.color`, `texter`, `clearColor`).

**Content:**
- `getCellText` (L77) and the edit-commit path in `fieldAction` (L367–372).
- `displayText` hardcodes a 5pt indent (L213) — a layout/style decision baked in the view.

**Vocabulary gap:** `style` and `action` already have model homes, so they migrate
cleanly. `frame` lives in the parallel `group.other` Details tree (not on the member
itself) — the central thing to lift onto members as a `frame` attribute. `type` must
be synthesized: today it is a draw selector + ~12 BOOLs, which the new `type`
attribute (cell/image/text/draw/view) collapses into one named value.

---

## Q2 — The `drawRect` → `drawFromField(windowField)` seam

`drawRect(Frame r)` (L305) **ignores its `r` argument** and runs purely off instance
state:
- It roots everything at the instance field `base` and that field's `.other` Details
  tree (the geometry source).
- It is gated by a `drawn` dirty flag (L313) and a `laidout` re-layout dance
  (L316–322) that calls the `layout()` solve before painting.
- The real paint engine is `drawDetail` (L250): it walks the visible tree via
  `walkVisible` and dispatches each node per-type via `performSelector(draw)`.

To become `drawFromField(windowField)`, the work is:
1. **Thread the field as an argument** instead of reading the instance `base`.
2. **Replace the `.other`/Details geometry source** with `frame` attributes read off
   the walked members.
3. **Drop the `drawn`/`laidout` shadow-state flags** — that state is now incant's
   (the window field *is* the display state).
4. **Move the `layout()` solve to incant** — Layout keeps only the paint walk and the
   per-type dispatch.

What's left in Layout after the seam is exactly "walk members, translate attributes
to Apple types, draw" — which is the design's intent.

---

## Q3 — View-component inventory (the `type` values + translation-seam outputs)

Components Layout instantiates/draws (these are what incant's `type` attribute must
name):

| Component | Where | `type` value |
|---|---|---|
| `TextCell` | L8 | cell |
| `TextField` (editable cell) | L9 | cell (editable) |
| `Image` | L131 | image |
| `TextView` + `Box` | L211 / L221 | text |
| `PathView` (vector) | L189 | draw |
| generic `View` (embedded NSView) | — | view |

So **`type` ∈ {cell, image, text, draw, view}**.

Apple types the attribute→AppKit translation seam must produce:
- Geometry: `Frame` / `Point` / `Box` (NSRect / NSPoint / NSSize).
- Vector: `Path` / `bezierPath` plus `rounded` / `rectangle` / `moveTo` / `lineTo` /
  `stroke` / `saveGS`.
- Color: NSColor from `filler` / `texter` / `stroker` / `clearColor`.
- Font: NSFont from `style.getFont`.
- Plus shadow / stroke.

These are the concrete outputs of the "translate incant attributes → Apple types at
the last moment, inside Layout" seam.

---

## Q4 — Event handling shape

Apple events hit overridden responders, each of which hit-tests the model tree and
funnels into a shared dispatch:
- `mouseUp` (L513), `rightMouseUp` (L535), `keyUp` (L459), `scrollWheel` (L549).
- Each does `base.blockContaining(point)` to find the target node, then funnels into
  `fireAction` (L381).
- `fireAction` walks **up** the parent chain matching click/key flags and invokes the
  handler as a raw selector: `group.method(group)` (L402/L422).
- `fieldAction` (L354) commits edits **straight to the model** and fires listeners.

To pass events back to incant per the design: Layout should only **normalize the
event and forward the field**. The parent-chain matcher (`fireAction`) and the
edit-commit logic (`fieldAction`) move to incant, and `group.method(...)` becomes an
OS-agnostic `action` dispatch. **Encouragingly, dispatch is already model-routed** —
events resolve against the GroupItem tree today — so this is relocation, not redesign.

---

## Layout ↔ Bwana boundary

**No by-name Bwana reference exists in Layout.** All upward coupling is via GroupItem
methods and free functions — the contract is the GroupItem API, not a named module
import. So there is nothing to *sever* at this seam; the migration is method
relocation, not decoupling. (Bwana's own source was out of scope and unread.)

---

## Tar babies (snags noted for later, not resolved)

1. **The `group.other` Details shadow-geometry tree** is the single biggest blocker to
   "the model carries `frame`." It is load-bearing throughout `drawRect`/`drawDetail`/
   `layout`, and its structure is defined in a GroupUI sibling that was unreadable in
   this recon — so its full shape is an open question that must be opened before the
   frame migration.
2. **`type` as selector + BOOL soup.** The `performSelector(draw)` dispatch (L288) plus
   ~12 BOOL flags encode what the single `type` attribute will replace. Enumerating
   every BOOL and how the draw selector is chosen is prerequisite work for defining the
   `type` vocabulary precisely.

## Findings (concerns surfaced, not fixed)

1. **`displayImage` (L128) and `fieldAction` (L354) are the two clearest ownership
   violations** — geometry-compute-and-write-back into the model, and edit-commit
   performed in the view. They are the prime first migration targets.
2. **Likely resource leak:** `displayText` never removes its substituted editor — the
   cleanup is commented out (L243–244).
3. **The redesign is ~40% pre-done:** `style`/`action` are already model-resident and
   event dispatch is already model-routed. The hard, genuinely new work is `frame`
   (lift out of the Details tree) and `type` (collapse selector + BOOLs into one
   attribute).

---

## Addendum — GUI backend strategy: the incant→HTML bridge (parked direction, 2026-06-18)

This recon establishes that Layout is *one backend* lowering the window-field model.
A second backend is planned: an **incant→HTML transpiler**. Settled intent, for when
GUI work starts (parked behind the JIT arc):

**Intent — a portability bridge, not a permanent backend, not the endgame.** It gives
incant users on non-Apple platforms a rendered GUI in a browser while a native OS
backend for their platform doesn't yet exist. Good enough to work. When a native
backend exists for a given OS, the HTML bridge retires for that OS.

**The mapping is mechanical** (same window-field tree as the AppKit backend):
- `frame` (x, y, w, h) → `position:absolute; left:Xpx; top:Ypx; width:Wpx; height:Hpx`
  as **inline** style.
- `type` → HTML element tag: cell→`<input>`, image→`<img>`, text→`<div>`, draw→`<svg>`,
  view→`<div>`.
- `style` → remaining inline style attributes (color, font, border).
- `action` → event-handler attributes (`onclick`, `onchange`, …).

**No CSS file, no classes, no cascade.** `position:absolute` on every element turns the
browser's layout engine *off* — incant places elements exactly where it says and the
DOM gets out of the way. The DOM is a dumb pixel placer; that's all it needs to be.

**The HTML output is a build artifact, like JIT output — nobody reads it.** The
transpiler owns the impedance translation; the incant window-field model never changes.

**Architecture:** the same lowering shape as the AppKit backend, off the same window-field
tree — and the same parallel-lowerings story as JIT one level up: incant→AppKit-draw,
incant→HTML, incant→bytecode, incant→JIT, all from one homoiconic model. The HTML bridge
is a *compile-time* lowering (model → HTML text); AppKit-Layout is the *runtime* one.
Because the recon's "~40% already model-resident" is backend-agnostic, it banks toward
the HTML target too.
