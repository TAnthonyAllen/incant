# GUI Design Brief — for Clay (self-contained; pull from gui.md only on demand)

*This is the whole context you need to start designing. Don't read gui.md front-to-back —
it's 923 lines, ~half archaeology. Use the **Drill-down index** at the bottom to pull a
specific slice when a question needs it.*

## The thesis (Tony, firm but pushback-welcome)
**incant is the driver; Layout is the vehicle being driven.** incant hands Layout **one field
at a time** — Layout does **no tree-walking** of its own, it just iterates the *attributes of
the single field passed in* and does what they say. Payoff: we can test how one field displays
in isolation, and ideally **edit a single frame in a running window from incant**.

A passed-in field's attributes declare:
- **Content** — what it holds: `text` / `image` / `path` / `cell`. (Old-GUI `Layout.twk` had
  these handlers; they need porting + revising into the current `Layout.twk`.)
- **Style** — fonts, borders, colors. Tony's lean: each of these is an **attribute with a
  method Layout can fire** to do the needful. Those methods are unwritten; the **font-setting
  path incant→Layout is the piece to nail down**.
- **Frame** — Layout calls **`getFrame()`** to cobble an `NSRect`/`Frame` out of the field's
  `x`/`y`/`width`/`height` attributes (the ones `setFrame` already sets).

## What's already solid (don't redesign — build on)
- **Layout engine = `setFrame`** (`incant/utilities`), the old `Details` engine reborn in
  incant. Does orientation (`across`/`down`), `*` content-fill, percent sizing, stretch
  distribution, parent-relative x/y cursor. So the row/column half is **solved**. (Multi-row
  position propagation + simultaneous across+down is the live WIP; not Clay's concern.)
- **`getFrame`** (`GroupDraw.twk`) already reads x/y/width/height → a `Frame`.
- **Font/Color model (the keep-list):** named-color registry + lazy `colorize()`; `getRGB`
  as the **single color-extraction seam** (feeds Cocoa *and* the libHaru PDF path); font as a
  GroupItem with consolidated `family=/size=/bold/italic`; `sTYLEs` copy-on-write cascade.
- **Apple is a thin shim:** `Font ≡ NSFont*`, `Color ≡ NSColor*`, boxed as `void*`. First
  window is already up (host exists).

## The open questions for Clay
*(items 1–5 are the model-first "Option A" set; 6–8 are Tony's newer field-handoff asks.)*
1. **Color in incant** — GroupItem with `r/g/b/a` resolved from a name via the `cOLOr`
   registry, `getRGB` lowering to Apple boxing only at the leaf? Where does name→RGB live?
2. **Font in incant** — keep `family=/size=/bold/italic` GroupItems; is `convert()` replaced by
   incant building a font-spec, with `NSFont` realization a single leaf extern (`realizeFont`)?
   Where does the cascade live?
3. **Style cascade** — re-express `Stylish(item, source)` copy-on-write as incant. Ride existing
   GroupItem copy semantics, or need a new primitive? (Bear traps #1–#3: `=` drops bindings.)
4. **SVG/text-dump sink** — the stub renderer that makes 1–3 **command-line-provable** (color →
   `rgb(...)`, font → `font-family/size/weight`) with zero Cocoa. This is what keeps it POP-able.
5. **Expected missing-incant bits** — budget for gaps (color arithmetic, attribute
   introspection, spec-building idioms). Each gap = a finding → add a primitive/extern.
6. **The content handlers** — bring old-GUI `text/image/path/cell` into current `Layout.twk`.
   See **"Porting the content handlers"** below — the dispatch shape, the subview-vs-direct-draw
   split, and the cell-recursion question are worked out there as the starting position.
7. **The style-method protocol** — fonts/borders/colors as attributes carrying methods Layout
   invokes. Define the calling convention (esp. the **font-set handoff incant→Layout**).
8. **Single-field, single-frame editing** — what does "incant edits one frame in a live window"
   require of the Layout/host boundary?

## Porting the content handlers — salvage the cores, don't lift the walking
*(Clod's recon of the concrete code; this is the starting position for questions 6–7, not a
closed decision.)*

**Salvage, don't port.** The old content rendering has **no clean `displayCell/Path/Image`
methods to lift** — it lives *inside tree-walking drivers* (e.g. Bot's `drawPDFdetail(base)`
walks a Details tree and paints the whole thing). That walking is exactly the model this design
rejects. What's valuable is the **native drawing core** of each type (`NSString`/TextView for
text, `image.drawIn` for image, bezier stroke/fill for path, sub-frame for cell). Extract those
bodies; re-house each in a field-at-a-time method. Don't drag the walking driver across.

**`displayText` is the template.** The commented `displayText(field)` (`Layout.twk:18`) is
already the target shape: `Frame framed = getFrame(field)`, style read off the one field's
attributes (`field["align"]`), the view cached on the node, `addSubview` once. The job is
**filling in three siblings to the one good example** — each `displayImage/Path/Cell(field)`
mirrors it. Per-handler, mechanically swap `detail.frame`→`getFrame(field)` and `detail.*`→ the
field's own attributes.

**Subview vs. direct-draw is forced by the content, not a preference** — state it this way so
it doesn't get unified:
- **text → a live subview** (NSTextView, added once, `setFrame` on resize). It needs a real view
  because it has *live state*: cursor, selection, editing.
- **image / path / cell → stateless direct draws** inside `drawRect` (`image.drawIn`, bezier
  stroke/fill). Nothing to persist; repaint each pass.

That split — persistent view vs. repaint-each-frame — shapes how the field-at-a-time dispatch
routes every content type, so pin it before any code moves.

**`displayCell` is the recursion — and incant owns it, not Layout.** Cell is the hard test of
the thesis. A cell contains children, but Layout must **not** walk them. The rule: **recursion
means incant hands Layout each child field, one at a time** — `displayCell(field)` paints the
cell's own frame/border, and incant drives the descent into its children. Layout never holds the
tree. Pin this now; it's where the field-at-a-time contract earns its keep.

**The current `drawRect` is a bring-up scaffold, not the destination — treat it as temporary,
not load-bearing.** It currently does `base.walk(item)` to stroke borders, which is the *opposite*
of "no walking in Layout." Fine for proving pixels; the end state dispatches per passed-in field
to `displayText/Image/Path/Cell` and retires the walk. Don't build on the walk as if it's the model.

*Suggested sequence (a note, not a directive — Clay's call on order):* un-comment + build
`displayText` against the live window first (it's done — proves the whole render path end-to-end);
then `displayImage` (native `image.drawIn`, cleanest salvage); then `displayCell` (the recursion
case); then `displayPath` (bezier, entangled with the drawing-grammar arc).

## Tension worth resolving early (my flag)
gui.md frames Clay's plate as **Option A: model-first, Cocoa-deferred, prove at the
SVG/text-dump level**. Tony's status report leans **toward the window** (port content handlers,
fonts in a real window, live single-frame edits) — which is more **Option B (the host)**. These
aren't opposed, but decide the **order**: lock the incant data-model (A, command-line-provable)
*then* wire it to the live window (B)? Or co-develop against the now-existing window? That choice
sets what's provable at each step.

## Drill-down index (pull only when needed)
- Layout engine / `setFrame` detail & the position-aliasing finding → gui.md **210–233**
- Font/Color current model (the keep/pound list) → gui.md **235–257**
- Why Option A is model-first (build/run-loop reality) → gui.md **259–273**
- Option A open questions (verbatim) → gui.md **274–289**
- Drawing grammar architecture → gui.md **293–381**
- Apple shim / Option B host path → gui.md **382–414**
- Relevant files / design decisions → gui.md **423–452**
- *(Skip unless excavating: Appendix A Map.rtn 453–662, B Bwana 663–822, C binding 823–923.)*
