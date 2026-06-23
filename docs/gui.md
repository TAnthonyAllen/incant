# Incant GUI
*One-stop shop for GUI design, recon, and status. Read this first for any GUI session.*
*Resurrection-reader audience: knows incant, has not touched GUI work recently.*

---

## 🎉 FIRST WINDOW — 2026-06-22 (note for Clay)

**We have a window.** A real Cocoa `NSWindow`, opened and owned from the *command-line*
`incant` binary — full lifecycle: open → run loop → close button → clean terminate (exit 0).
The thin-shim thesis is **proven**: incant drives Cocoa through a small C++ rind, and **no
`incantGUI.xcodeproj` is needed** — the command-line `Groups` target already links Cocoa.

How: `Layout` flattened to a skeleton and **linked into the binary**; a tiny `openWindow`
extern (`NSApplication` + `NSWindow` + run loop) in `guiHost.rtn`. The one real bear was a
**BDWGC × Cocoa collision** — AppKit's framework-load storm overflowed Boehm's root-set table
(`Too many root sets` → abort); **`GC_set_no_dls(1)`** tames it (it also took the tok-only-
emits-an-external-`#include`-when-the-symbol-is-referenced-in-parsed-code trick, the *newer*
`/usr/local/include/gc/gc.h`, and moving that path out of *User* Header Search Paths).

What this means for you: **the seam is no longer the question — the design is.** Over to you
for the Font/Color model (Option A) and how `Layout` paints from incant. Next mechanical
brick: hang `Layout` as the window's `contentView` and give `drawRect:` a color to fill.

**HOOAHH.** 🥃🐕

---

## 🧱 BIGIFY in incant — 2026-06-23 (band-splitter done, painter pending)

Reimplementing the old Bwana `bigify` (object pool + by-ref counter + `goto`) as pure
incant — and it's *slicker*: the layout is two nested `while`s and a clamp. Status:

**Build half — DONE & proven (committed `06e9c9b`).** `bigifyLayout` (`incant/utilities`)
builds a `rows × columns` grid as a band-wrapper tree: clamp `selRow`/`selCol` (block
state) → `bOR`/`bOC`, split each intersecting row into **left-strip `bigColumn`s / big cell
/ right strip**, non-intersecting rows full-width. Each cell **merges** its template
(`regularItem`/`bigItem`) and is **stamped** `row`/`col`. **Percent** sizes via `:.
isPercenT`; stamps wrapped in `copyOf` (else `+%` aliases the reused local). Verified at a
non-corner slot (4×3, big 2×2 @ (1,1)): correct three-band tree, per-cell stamps, heights
25/50/25, widths 33/33/33 + strip 33 / big 67.

**This session also landed the language primitives bigify needed** (see commits): the
**revived merge subsystem** + two-sided opt-in contract + `:.`/`opSetFlag` (`290af9c`), and
**`<-`/`opRebind`** — the clean slot-rebind that `:=` (byRef-sticky) and `=` (content-copy)
couldn't express; it's the "rebind a local to a fresh node" semantics, already JIT-shaped
(`1b31126`).

**Painter — PENDING (the one bounded debug left).** `setFrame` integration (`layoutTree`
recursive driver) is *out* of the commit. Two bugs: (1) `setFrame`'s **`fillAcross` fires on
the pre-built rows** (they carry `across=1`) and duplicates cells ~17× — the `*`-fill path
(`if across == "*"`) shouldn't run on already-populated blocks; suspect the `across` marker
choice or a "skip fill if already filled" guard. (2) `x`/`y` come out empty after the fill
mess — check the position pass once fill's untangled. Start from the green build tree.

**Next after painter:** `seq` (covered-before reading-order stamp for source-fill);
`reBigify` (selection → `selRow`/`selCol` + rebuild). Then bigify is done & dusted.

---

## Current Status

**GUI work is in preparation phase — recon complete, design starting.** The old GUI is
fully reconnoitered; the next move is design (Clay+Tony) of the **Font/Color model**
(Option A), then incremental build.

**Recon landed & wrapped (2026-06-22)** — capability inventory, architecture, and salvage
list below; deep dives of `Map.rtn` (Appendix A), `Bwana` (Appendix B), and the reactive
data-binding loop (Appendix C). Drawing grammar architecture is settled; grammar revision in
progress.

**Two settled directions going in:**
- **Strategy: redo Bwana et al in incant, not C++** — much of the old GUI's bear-trap soup
  (`__bridge`-in-tok, `memset` Details tape, `hold()` GC-retention, mirrored subscribe flags)
  is *C++/ObjC artifact* that dissolves in incant. `setFrame` already proves the hard part
  (the layout engine) lives cleanly in incant. **Stage it interpret-first, JIT-later** — don't
  author GUI incant and JIT it in the same breath (two moving targets); get each piece working
  under the interpreter, then let JIT accelerate the proven piece.
- **Apple shim is small and known.** Color ≡ `NSColor*`, Font ≡ `NSFont*`, boxed in GroupItems
  via `getPointerGroupItem`/`setPointerGroupItem`, with `getRGB(&r,&g,&b,&a)` the one color
  seam. Resolving Font/Color **is** resolving the shim — hence Option A first.

---

## Immediate Next Steps

- [x] **Old GUI recon** — Tonto pass + deep dives (`Map.rtn`, `Bwana`) + reactive-loop autopsy (Appendices A/B/C).
- [x] **Drawing grammar** — Architecture settled (see below). Grammar revision in progress.
- [ ] **Option A — Font/Color model design (Clay+Tony).** Resolve the Font/Color data model
  in incant, model-first / Cocoa-deferred (provable command-line via SVG/text dump). Design
  brief in the Layout / Stylish section below. **← next.**
- [ ] **Option B — minimal Apple host for `Layout`.** Stand up a butt-simple NSWindow host
  (no `incantGUI.xcodeproj`) and decorate `Layout` one display extern at a time. Measured path
  in the Apple Shim section below.

---

## Old GUI Recon

*Salvage reconnaissance of `OLDtawkDoNotTouch/Groups/GUI/GroupUI` (2026-06-22). Source
read from `.twk`/`.rtn` only (`.mm`/`.h` excluded). `Tests/oldGUI/` is now a **symlink** into
the live `OLDtawkDoNotTouch/.../GroupUI` tree (read-only; line refs below match it).
Drawing-grammar files (`Groups.g/.rtn/.act`, `DrawPoint`, `Filler`, `PathView`) skipped —
superseded by the new incant drawing grammar — except `Groups.g`'s coordinate-mode model
(cross-referenced under Drawing Grammar below). Documents the **old** tree; a live `GUI/`
dir also exists in the repo as a separate, more recent copy.*

### Capability inventory

**Windows/views** — a 3-bit `pane:[isMenu isPanel isView isWindow]` enum on `Details`, not
distinct classes. Top-level `isWindow`/`isPanel` (`Control.convertWindowToPanel` downgrades
one to the other); `isView` = a sub-region promoted to its own draw layer; `isMenu` =
popups. **The only real `NSView` subclass is `Layout` (`extends View implements
WindowDelegate`)** — *one* Layout view is the whole window's content view *and* its
delegate; it draws the entire block tree itself.

**UI elements** — a `content:[isButton isCell isImage isPath isText]` enum (draw-flavors,
not Cocoa controls): **button** (`displayButton`, basically a stub — behavior comes from
action wiring), **cell** (`displayCell` — aligned text, bg fill, **inline edit** swaps in a
live `NSTextField` on `editable && selected`), **image** (`displayImage` — scale/crop-to-fit,
`oRIGIn`/`oFFSEt`/`sCALe`), **path** (`displayPath` via `PathView`), **text** (`displayText`
— editable `NSTextView`). Higher-level: **menus** (popup/pulldown/popUp), **tabs**, **tree**
(expand/collapse), **card deck** (single-visible), **matrix/table** (rows·columns with
`sUM`/`cOUNT`/expand-collapse). Scrollbars are **hand-rolled** (`scrollableX/Y`,
`scrollContent/Text/Cards`), not `NSScrollView`. **Absent**: checkbox, slider,
`NSTableView`, `NSScrollView`, real modal sheets (`NSAlert`/`beginSheet`/`runModal`).

**Event/interaction model** — `Layout` catches `mouseUp`/`rightMouseUp`/`scrollWheel`/
`keyUp` → `base.blockContaining(point)` hit-test → **`fireAction()` walks bottom-up through
`.parent`**, firing the first block whose `group.method` matches the event class
(event-bubbling). The triggering event is stashed on the block's `Details`
(`blockDetail.event = event`) — **events are GroupItem-carried**. Modifier state read from
ambient globals (`controlKeyed`, `shiftKeyed`). Keystrokes via `keyStrokeMatch` (magic key
codes hard-coded: 116/126/121/125/123/124).

### Architecture — key classes and concepts

| Class / file | Owns |
|---|---|
| **`Bwana`** | **The overseer/registration hub** ("boss", Swahili). Owns the whole GUI object graph + the attribute→method dispatch tables. `mapMethod`(layout-time), `mapAction`(`deferred=true`, fires on input), `mapAndTrack`(parser indexes every block with the attr); `registerMethods()` ≈ 70 bindings. *(Appendix B.)* |
| **`Control`** | Controller/loader; drives `layout(base)` — the 2–3-pass tree walk (`setDetails`→`layout`→`flexLayout`→`resetHierarchy`→`checkFit`→`processAttributes`). |
| **`Details`** (41K) | **Geometry sidecar + layout engine + hit-test + text/scroll glue.** Hung off each block as `wig.other`. `initialize` (attrs→geometry), `setFrame`/`layout`/`setPadding`/`setPercent`/`fitSize`/`fitSizeToText`, `blockContaining` (hit-test), scroll engine. |
| **`Layout`** | The single `NSView` — `drawRect` walks the tree; `displayButton/Cell/Image/Path/Text`; event capture + `fireAction`; inline `NSTextField` edit via `field.action=@fieldAction:`. |
| **`Stylish`** (14K) | Style struct + cascade. Named colors (`cOLOr` registry, lazy `colorize`→NSColor), fonts as GroupItems carrying a boxed `NSFont`, named styles (`sTYLEs` registry), copy-on-write inheritance via `Stylish(item, source)`. |
| **`Source`** | **Observable model** — `GroupItem` as scrollable/sortable list + `DoubleLinkList listeners` + `updateListeners`/reactions. Reactive data-binding layer. |
| **`Actions`** | Deferred user-action handler registry (`dISPLAY`, `fIRE`, `mENU`, `sELECTtab`, `sORT`, `tOGGLE`, `xPAND`…). |
| **`PDF`** (13K) | **Parallel renderer over the same tree** via libHaru (`HPDF_*`), *not* Apple PDF. `drawPDFdetail` mirrors `drawDetail`, walked via `walkVisible`. |
| **`Map.rtn`** (56K) | ⚠️ **Misnamed** — not bitmaps. The attribute-action table (~46 handlers). *(Appendix A.)* |
| **`Sheet.rtn`** (41K) | ⚠️ **Misnamed** — not modal sheets. Matrix/tree row-height **collapse/expand** adjustment (`adjustHeight`…). |
| **`URLservice`** | Async HTTP fetch-to-buffer/file (`NSURLConnection` delegate wrapper). |

**Layout handling**: single-tree, multi-walk flow/box. **Orientation**
`orient:[down across cards layers]` × **sizing** {absolute (`fixX/Y/W/H`), percent-of-parent
(`isPercent`/`setPercent`), fit-to-content (`fitSize`/`fitSizeToText`)}. Parent-relative
cursor (`ancestor.mark` down, `ancestor.remaining` across); leftover space split across
unfixed children (`length /= stretched`). `flexLayout` clones a `vCONTENt` template to fill
space (data-driven repeater bound to a `Source`).

**Apple bridge** — **thin by wrapping, not by abstraction.** `Font ≡ NSFont*`,
`Color ≡ NSColor*`, both boxed as `void*` inside GroupItems, round-tripped through
`getPointerGroupItem`/`setPointerGroupItem` + `__bridge` inside `-% %-` escapes (`__bridge`
"not supported in tok"). `hold()` retains bridged objects against BDWGC. Window/view via
`Window`/`Panel`/`View` typedef wrappers. **`getRGB(&r,&g,&b,&a)` is the universal
color-extraction seam** feeding both Cocoa and libHaru. (Lowest-level vector Cocoa drawing
lives in `PathView` — not deep-read, per scope.)

### What is worth salvaging

**Carry forward (ideas/capabilities):**
1. **One layout tree, multiple renderers.** `drawPDFdetail` (libHaru) parallels `drawDetail`
   (Cocoa) over the *same* tree via `walkVisible`, touching the backend only at a few
   **fill/stroke/text/path/image** primitives. **The ready-made "Apple = thin shim"
   template** — box/unbox + `getRGB` are the shim points; add a Cocoa renderer beside PDF.
2. **Compact layout vocabulary**: 3 sizing modes × 4 orientations, with **`cards` (deck)**
   and **`layers` (z-stack)** as clean primitives.
3. **Styling model**: named colors in a registry (lazy realize→NSColor), fonts as
   GroupItems mutated via `convert()` (family/size/bold-italic-mask), named styles with
   **copy-on-write cascade** (`Stylish(item, source)`).
4. **Homoiconic wiring**: attribute-named handlers, **two-tier bind** (`mapMethod`
   build-time vs `mapAction` input-time), event-as-GroupItem, `fireAction` bottom-up
   bubbling, `mapAndTrack` as a built-in scene-graph index.
5. **`Source` as observable model** (listeners/reactions) + flex repeaters — a reactive
   data-binding layer that already works. *(End-to-end mechanics: Appendix A §C.)*

**Problems you'll have to solve again:** hit-testing (`blockContaining`),
first-responder/focus, inline text editing, hand-rolled scrolling, the **coordinate flip**
(Cocoa bottom-left vs top-left readers — `iosY = height-(y+height)`), font mutation,
GC-retention of bridged Apple objects.

**Bear traps (documented + implicit):**
- **Events ride ambient globals** (`wig`, `view`, `controlKeyed`…) instead of an event
  object — *the* thing to fix in the redesign.
- The **double-`setModified()` "WTF??"** redisplay hack (pops up blank otherwise).
- **`Details` is a `memset`-zeroed raw struct on a manual tape** — replace with GC
  GroupItem fields.
- **`wig.other` stale-after-copy**; **`noRoom` aliased to `isTarget`** (one bit, two
  meanings); `laidout` set-then-unset ordering fragility.
- **Acknowledged leak** in `resetVariableContent`; **window close = `exit(0)`** if root.
- **`setPDFfill`/`setPDFstroke` ignore their `Color` argument** (read ambient state) —
  latent bug.
- **`itemFactory` usage predates its removal** ("constructors are now the only path").
- **Misleading filenames**: `Map.rtn` (attribute actions), `Sheet.rtn` (matrix heights),
  `Groups.g` (drawing, not XML).
- **`bigify` comment: "Tried it as a lambda. Collosal fail."** — a known runtime sharp edge.

---

## Layout and Stylish — salvage + Option A design brief

### The layout engine already lives in incant — `setFrame`

`setFrame` (`incant/utilities:183`) is the old-GUI `Details` layout engine **reborn in
incant**, and it works. Running `setFrame(sumple)` (fixture `incant/unitTests:88`,
`height=200 width=250 x=100 y=100 down=*`) produces:

```
About to fill down for sumple        ← down=* triggers fillDown (the * content-fill)
  Adding 3 members down to: sumple
  crossing width=250 height=50 ...    ← 4 rows, full width (250), height 50 (= 200/4 stretch)
```

It already does **orientation** (`across`/`down`), the **`*` content-fill** expansion
(`fillAcross`/`fillDown`), **percent sizing** (`width.isPercent; width = width*sideRoom/100`),
**stretch distribution** (leftover split via `sideOut`/`upOut`), and the **parent-relative
cursor** (2nd pass sets x/y from `pX`/`pY`). **Design consequence:** the row/column-expansion
half of the old `setFLEXcontent` is *already solved*. A new reactive content updater only needs
the **trigger** (source-changed → re-run `setFrame`/fill + repoint to next source elements), not
the layout machinery — the observable-`Source` half (Appendix C) bolted onto `setFrame`.

*Finding to eyeball (not fixed):* in the `setFrame(sumple)` run, the four `crossing` members
**sized** correctly (height 50 each) but **positions** came out uniform (`y=250 x=100` for all)
rather than stacked (100/150/200/250). Likely copied-attribute aliasing or the x/y pass not
advancing the cursor for filled members. Repro: `Tests/frameTest`.

### Font / Color — current model (the Apple shim)

From `Stylish.twk` (old) + the font-consolidation work already committed:
- **Color** — named entries in the `cOLOr` registry; lazy `colorize()` (spec → `NSColor`) on
  first use, then cached as a `void*` pointer on the GroupItem. Reached via
  `getColorNamed`/`getColorFromItem`; **`getRGB(&r,&g,&b,&a)` is the one universal extraction
  seam** (feeds both Cocoa and the libHaru PDF renderer).
- **Font** — a GroupItem (`fontItem`) carrying a boxed `NSFont*`; mutated by `convert()`
  (family by `NSString`, size by `double`, traits by `NSBoldFontMask`/`NSItalicFontMask`).
  Handlers `fONT`/`fONTname`/`fONTsize`/`fONTstyle`. Format consolidated onto
  `family=`/`size=`/`bold`/`italic` across the registries (committed).
- **Styles** — named in the `sTYLEs` registry; **copy-on-write cascade** via
  `Stylish(item, source)` (`if !style style = new(wig, getStyle())` — lazy-derive on first
  modification).
- **Bridge** — `Font ≡ NSFont*`, `Color ≡ NSColor*`, boxed as `void*` in GroupItems via
  `getPointerGroupItem`/`setPointerGroupItem` + `__bridge` inside `-% %-` (because `__bridge`
  is unsupported in tok). `hold()` retains bridged objects against BDWGC.

**Keep:** named-color registry + lazy realize; the consolidated `family=/size=/bold/italic`
font format; `sTYLEs` copy-on-write cascade; `getRGB` as the single color seam.
**Pound (cruft/bugs):** the parked `setFont`/`setColor` fixes; `setPDFfill`/`setPDFstroke`
**ignore their `Color` argument** (read ambient state — latent bug); the `-% %-` bridge
boilerplate.

### The build/run-loop reality (why Option A is model-first)

Everything proofed so far (JIT, bytecode, JSON) runs via `~/bin/incant` (command-line `Groups`
target). `Stylish.twk`/`Layout.twk` are **GUI-target material, not in the command-line build**,
and `incantGUI.xcodeproj` is unused (and has unrelated missing-file errors). So "pound the cruft
and prove it" needs a run path — and *shape-reading isn't verification*. Hence the fork:

- **Option A (model-first, Cocoa-deferred) — Clay's design plate, NEXT.** Resolve the Font/Color
  *data model* in incant: color-name→RGB resolution and the font format → a `describe`-style
  dump — **provable command-line at the SVG/text-dump level, zero Cocoa.** The actual
  `NSColor`/`NSFont` boxing stays stubbed until the host exists. Stays interpret-first and fully
  runnable.
- **Option B (the host) — see Apple Shim section.** Stand up a minimal NSWindow to hang `Layout`
  and verify against real `NSColor`/`NSFont`, decorating one extern at a time.

### Option A — open design questions for Clay

1. **Color model in incant** — is a color a GroupItem with `r/g/b/a` count fields (resolved from
   a name via the `cOLOr` registry), with `getRGB` lowering to the Apple boxing only at the leaf?
   What's the name→RGB table's home (registry vs incant data)?
2. **Font model** — keep fonts as GroupItems with `family=/size=/bold/italic` attributes; is
   `convert()` replaced by incant that builds a font-spec GroupItem, with the `NSFont`
   realization a single leaf extern (`realizeFont`)? Where does the cascade live?
3. **Style cascade in incant** — re-express `Stylish(item, source)` copy-on-write as incant
   (`getStyle()` walk-up + lazy-derive). Does this ride the existing GroupItem copy semantics, or
   need a new primitive? (Watch bear traps #1–#3 — `=` content-copy drops bindings.)
4. **The SVG/text-dump sink** — define the stub renderer that makes all of the above
   command-line-provable (color → `rgb(...)`, font → `font-family/size/weight`), so Option A
   POPs without Cocoa.
5. **Expected missing-incant bits** — like generating, budget for gaps (color arithmetic,
   attribute introspection, spec-building idioms). Each gap = a finding → add a primitive/extern.

---

## Drawing Grammar

### Architecture (settled 2026-06-22)

**Goal:** Drawing interpreter written in incant, JIT-compiled for performance. Apple
display machinery called only at the leaf level via thin C++ externs (`displayPath`,
`displayCell`, etc.) — same pattern as `aCTionPrinT`. No hand-written C++ drawing loop.

**Instruction representation:** Drawing instructions are GroupItems, not C++ `DrawPoint`
objects. The grammar emits a list of tagged GroupItems; the incant drawing interpreter
walks that list. `DrawPoint` C++ objects are retired from the hot path.

**Two-part drawing model:**
1. Incant produces a list of drawing instructions (GroupItems) from the drawing grammar
2. The incant drawing interpreter walks the list and calls Apple display externs at the leaves

**Registry design:**
- `Drawing` registry — owns all field definitions. Master definition home.
- `DrawingOps` — lightweight subset: geometric operators (`line`, `move`, `arc`, `curve`,
  `oval`, `rectangle` etc.)
- `DrawingFlags` — lightweight subset: mode/flag operators (`percent`, `relative`, `reset`,
  `save`, direction flags etc.)
- Search order set by caller at top of drawing file: `search DrawingFlags DrawingOps Drawing;`
- Grammar searches via `locate` naturally — no condition-switching inside the grammar.
  Search order is the caller's responsibility, not the grammar's.

**Operator actions (tag-based dispatch):**
Each operator field carries its own action. The interpreter loop fires the action against
interpreter state — no switch statements, no flag knowledge in the interpreter itself.
Adding a new operator means adding it to the registry with an action; the interpreter
needs no changes.

```
percent action={
    toggle(state.percent);
    };
```

**Toggle:** A thin `toggle` extern flips a count field between 0 and 1 in place.
`toggle(state.percent)` — one call, one C++ operation. Cleaner than read-modify-write
in incant source.

**Interpreter state:** A dedicated GroupItem with named attributes for persistent mode
flags (`state.percent`, `state.relative`, direction flags etc.). Mutable, owned by
incant, threaded through the interpreter loop.

**Flag separation rationale:** Flag operators (`percent`, `relative`, `reset`) and
geometric operators (`line`, `arc`, `curve`) are kept in separate registries. No mixing.
The search list loads the right registry for the task at hand. This is the incant-idiomatic
solution — search order as context, not conditions inside the grammar.

**JIT payoff:** The drawing interpreter is the primary JIT target. A tight
read-modify-write on a count field (toggle, direction set) compiles to almost nothing.
The overhead of named-attribute dispatch disappears under JIT. This is why we're not
bit-packing flags — readability now, performance from JIT later.

### Cross-reference — the old `Groups.g` coordinate-mode model

The old drawing grammar already had **absolute + relative + percent coordinate modes as
first-class flags**, the idea worth carrying into the new grammar. A path was
`operator + xOffset + yOffset?` triples; current point defaulted to the frame origin.
Mode/path operators (`pathOpSet [%~@:!dIlrRSTu]`): `%` = lengths as % of frame, `~` =
relative (current point follows the pen), `@` = move-to, `:` = close, `!` = reset modes to
pixel/absolute, `d/u/l/r` = direction, `R` = rotate, `S` = scale, `T` = translate. Curve
operators (`curveOpSet [aco]`): `a` = arc, `c` = bézier, `o` = oval. These map onto the new
`DrawingFlags` (`% ~ ! save`) / `DrawingOps` (`line arc curve oval …`) split.

### Grammar Revision

*In progress — see `incant/drawRules` for current state.*

Key changes from original `drawRules`:
- `DrawOperator` simplified — `DrawName` trusts search order, no condition gymnastics
- Flag operators and geometric operators separated into `DrawingFlags` / `DrawingOps`
  subsets within the `Drawing` define block
- Action stubs on flag operators (placeholders to be filled)
- Grammar emits GroupItems, not `DrawPoint` C++ objects

### Bear Traps

- `rStuff` lives on GroupItem not GroupBody — condition state is per-instance. Not a
  problem for `Drawing` registry conditions since we're not using conditions for the
  registry switch, but worth remembering if conditions are added to the drawing grammar.
- Large registries: at some list-length threshold incant builds a sorted array for binary
  search. Drawing registries are small — not a current concern, but a known scaling
  mechanism exists if needed.

---

## Apple Shim — Option B host path (measured)

**Goal:** the smallest possible place to hang `Layout`. `Layout` (the one `NSView` that draws
the block tree) does the work; the host just has to open a window and make `Layout` its content
view. "Butt-simple," decorated one good bit at a time.

**The de-risker (verified 2026-06-22):** the command-line `Groups` binary (`~/bin/incant`)
**already links Cocoa, Foundation, and CoreFoundation** (`otool -L ~/bin/incant` shows
`Cocoa.framework`). So we can spin up `NSApplication` + an `NSWindow` and hang a view **from the
existing command-line target** — no separate GUI app needed.

**Measured path:**
1. A tiny extern/command (`openWindow` or similar) — `NSApplicationMain`-lite: create
   `NSApplication`, one `NSWindow`, set its `contentView` to a trivial `View`/`Layout`, run the
   loop. Callable from incant (`immediateAction`), so a scratch file pops a window.
2. First decoration: `Layout.drawRect` draws *one* thing (a filled rect from a `getRGB` color) —
   proves the incant→Cocoa draw seam end to end.
3. Then decorate `Layout` one display extern at a time (`displayCell` → `displayText` →
   `displayPath` → font/color), each visually verifiable, each a small green brick.

**Rabbit holes to route around (explicit):**
- **Do NOT resurrect `incantGUI.xcodeproj`** — unused, has unrelated missing-file errors. Build
  on the command-line target that already links Cocoa.
- **Do NOT port all of `Layout` at once** — hang a stub, decorate incrementally.
- **Keep the host trivial and stable** — it's a coat rack, not a feature.
- **Don't entangle with JIT** — interpret-first; the host and its display externs are C++/Cocoa
  leaves, the orchestration above them is interpreted incant.

*Option B is staged after Option A: get the Font/Color model command-line-provable first, then
stand up this host to render it for real.*

---

## Architecture

*Pending Clay+Tony design pass. Drawing-grammar architecture (above) is the first settled
piece; Font/Color (Option A) is next on Clay's plate; full window/layout architecture follows.
Salvage inputs: Old GUI Recon + Appendices A (Map.rtn), B (Bwana), C (reactive loop).*

---

## Relevant Files

| File / Directory | Role |
|-----------------|------|
| `incant/drawRules` | Drawing grammar — active revision target |
| `incant/drawing` | Drawing registry definitions and overview notes |
| `OLDtawkDoNotTouch/Groups/GUI/GroupUI` | Old GUI source — recon target (read-only) |
| `Tests/oldGUI/` | **Symlink** → live `OLDtawkDoNotTouch/.../GroupUI` (read-only; all Appendix line refs match it) |
| `incant/utilities` | **`setFrame`** (`:183`) — the layout engine, already in incant (orientation/fill/percent/stretch) |
| `Tests/frameTest` | Scratch repro: `setFrame(sumple)` (gitignored) |
| `Stylish.twk` | Font/Color/style — Apple-shim salvage target (Option A) |
| `Layout.twk` | The one `NSView` — display externs; Option B host hangs it |

*Update this table as recon lands.*

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Drawing interpreter in incant, not C++ | JIT target; self-hosting direction; Apple called only at leaves |
| Instructions as GroupItems, not DrawPoint C++ objects | Incant-native; interpreter can walk without C++ indirection |
| Two registries: DrawingOps / DrawingFlags | No mixing of geometric and mode operators; search order as context |
| Tag-based dispatch — operators carry their own actions | Interpreter stays dumb and uniform; new operators add no interpreter changes |
| Named attributes for interpreter state, not bit-packed flags | Readability now; JIT eats the overhead |
| `toggle` extern for flag flip | One call, one C++ op; cleaner than read-modify-write in incant |

---

# Appendix A — `Map.rtn` deep dive (the attribute-action table)

*Method-by-method porting brief. `Map.rtn` is NOT bitmap machinery; it is the legacy GUI's
table of ~46 attribute handlers that turn declarative widget attributes into a live
`GroupItem`/`Details` tree. Each handler runs when layout encounters an attribute of the
matching (case-mangled) name on a widget block.*

**Vocabulary:** `item` = the *attribute* GroupItem being processed; `wig` = the parent
*block* (widget) owning it; `Details detail = item.getDetail()` = the layout sidecar
(`item.other`), opened atop nearly every handler to bring its fields into bare-name scope.
**`attributed`** = the recurring "already ran once?" guard (false first pass, true on
re-layout/reaction).

## A. Method catalogue (file order)

- **`aCTION`** (L5) — generic "set an action": reads `item.text`, calls `setAction(item, name)`
  on the attribute itself (deliberately), errors if no parent / empty name.
- **`bigify`** (L24) — largest (~170 lines). Builds a rows×columns cell grid with one enlarged
  `bigRows`×`bigColumns` "big item"; the big-item row becomes a left/big/right 3-column
  wrapper. Reads `rows`/`columns`/`bigRows`/`bigColumns`/`sRCe`/`source`; attaches a source via
  `sOURCE`; builds rows from the `getStashedItem` pool; percentage height/width. `goto
  bailOnError`.
- **`buildBigifyRow`** (L201) — per-row helper (comment: *"Tried it as a lambda. Colossal
  fail."*). By-ref source counter, skips the big-item slot; pulls `"cell"` from the stash,
  `setAction(cell,"makeBIG")`, merges small-template + source.
- **`bUTTON`** (L236) — `isButton; deferDraw; draw=@displayButton; isDisplayable;
  setModified(wig)`.
- **`cELL`** (L249) — ensure style, `isCell`, `draw=@displayCell`. Tag `'c'` → editable, bound
  to `object=field`; text `"tag"` → `useTagForLabel`.
- **`debugFLAG`** (L271) — per-detail debug flags by tag: `dRAW`/`dUMP`/`pDF`/else `pRINT`.
- **`delimitFILE`** (L284) — loads a delimited (CSV/TSV) file via
  `controller.parser.loadDelimited(wig)`.
- **`dESCRIBE`** (L298) — reactive description. First pass: `hasReactions; item.reacts;
  selectedMembers.addListener(wig)`. Later: look up `lastSelect`'s tag in the `descriptions`
  registry, write into `wig.text` **and** the live `TextView`/`TextStore`.
- **`expandTREE`** (L380) — expands a collapsed node by destructive re-wrap: snapshot into
  `expandedRow`, retag `item` as `"wrapper"`, null `attributes/members/other`, clone per
  branch, `resetHierarchy()`.
- **`flagFIELD`** (L433) — `switch(*item.tag)`: `b`=blank, `c`=comma(formatter/thousands),
  `d`=noScroll, `k`=key, `n`=noSelectSource, `s`=selectable, `z`=zero.
- **`getBlock`** (L484, extern) — JIT-callable lookup: `"selection"`→`lastSelect`, else
  `item.find(text)`.
- **`getStashedItem`** (L496) — **object-pool core.** First call `new(text)`+append; later
  `next()`+`release()`+retag+reset (`attributed=false; object=null`), strip cached
  `height`/`width`. Errors "ran out of stuff on stack" on exhaustion.
- **`iMAGE`** (L527) — resolve filename (own text, or `file`+`directory`), self-`replace()` if
  shared, build `Image` from URL/file, `object=image; draw=@displayImage`, default
  `setAction(wig,"iMAGEwork")`.
- **`indent`** (L584/L589) — two geometry helpers: inset a rectangle uniformly or by
  vertical/horizontal amounts (overloaded).
- **`itemMETHOD`** (L598) — **JIT glue (immediate):** `item.jIT()` compiles the attribute's
  incant code; `onLayout`→`hasOnLayout`; runs `item.method(item)` now.
- **`jitMETHOD`** (L610) — **JIT glue (deferred):** compiles but doesn't run; self-`replace()`
  if shared; sets parent `deferred=true`.
- **`keyCode`** (L624, extern) — typed key-code accessor (ObjC calls fail in JIT; `keyCode`
  crashes on non-key events).
- **`keySTROKE`** (L640) — `processKeySpec(item)`; on success marks `item.parent.keyAction` +
  `wig.keyAction`.
- **`keyStrokeMatch`** (L654, int) — predicate: event keystroke matches the spec AND all
  modifier conditions (`alt/control/command/shift` Set vs Keyed).
- **`menuITEM`** (L672) — `setAction(wig,"iTEM")` (default), `cELL(item)`, `isMenu=true`.
- **`mERGE`** (L685) ⭐ — walks parents for a `sRCe`; override-merges its group's attributes
  into `wig` (`wig.mergeAttributes(block,true)`); first pass registers a source listener.
- **`mINIMUM`** (L717) — sets `minimumHeight`/`minimumWidth` from `item.number` by tag.
- **`nEXT`** (L728) ⭐ — **scrolling content-update.** First pass recreates `sRCe`, wires the
  **flex-content reaction** on the nearest `contentVaries` ancestor (`source.addListener;
  block.method = setFLEXcontent`). Each pass: `block=source.next()`; null→`noData/noRoom`,
  else repoint `wig.group`.
- **`pATH`** (L806) — builds a `pathSet` (`DrawPoint ***`, via `buildPath`); `wig.pointer =
  pathSet; draw=@displayPath; isPath`.
- **`popUP`** (L826) — `setAction(wig,"display")`.
- **`pullDOWN`** (L837) — `cELL`, `setAction(wig,"menu")`, link the named menu + back-link
  `menu["pULLdOWN"]=wig`.
- **`rEGISTER`** (L859) — registers the attribute's **parent** into a named registry (or
  `currentRegistry`).
- **`resetTREE`** (L874) — clears `sourced=false` then `tREE(item)` (workaround: "jit can't
  read a boolean").
- **`rightCLICK`** (L884) — binds the action to the right button; `wig.rightClick=true`.
- **`scrollWITH`** (L900) — links blocks that scroll together via a shared scroller member
  list; toggles `doNotChangeParent`.
- **`sELECTsource`** (L945) ⭐ — binds source to selection: `selectedAttributes` or
  `selectedMembers`, stored as `sRCe`, `source.addListener(wig)`.
- **`setAction`** (L964) ⭐ — **core dispatch binder.** `properties[property]` → copy
  `.method` + `.deferred` onto the block (if no method yet / is attribute).
- **`setCARD`** (L985) — sets the initially-visible deck card (`noRoom` off new, on old).
- **`setExpander`** (L1020) — sets the tree expander glyph from `tEMPLATEs`
  (`expanded`/`expandable` per leaf state).
- **`setModified`** (L1049) — mark-dirty: clear `drawn`, `mustDisplay(true)`, `modified=true`.
- **`setSORT`** (L1060) — adds the sort key as a member, `setAction(wig,"sORT")`.
- **`sHOW`** (L1080) ⭐ — conditional visibility from source data; first pass registers a
  listener; sets `wig.noRoom` by whether the source has displayable data.
- **`sOURCE`** (L1121) ⭐⭐ — **primary source-attachment.** `"selected"`→`sELECTsource`; else
  locate the block, reuse/create a `Source` (`new(block)`/`new(nextBlock)`/`emptySource`, lazy
  `load`), remove any stale copied `sRCe` (`entry %-= oldAttribute`), store `entry["sRCe"] =
  (void*)source; sourced=true`.
- **`tABS`** (L1204) — builds a tab strip: select first tab, resolve each body from
  `currentRegistry`, `setAction(tabBlock,"tab")`; optional initial tab via `sELECTtab`.
- **`tAG`** (L1247) ⭐ — display the source's tag/value (`resolvedTag()`); fallbacks
  `lastSelect`→`sourceItem`→`"Nothing selected"`; first pass registers a listener.
- **`tEXT`** (L1286) — text + `draw=@displayText`. Fast path: `attributed && wig.modified` →
  `detail.changeText()`. Tag `'t'` + registry name → bind that block, repoint `wig.group`.
- **`timeEnd`** (L1325, Date) — profiling: print elapsed seconds, return now.
- **`toString`** (L1336, String) — format a Frame as `"width height x y"`.
- **`tOGGLED`** (L1350) ⭐ — toggle-driven visibility: `wig.noRoom` from a named toggle's
  state; registers `item` on the toggle's `toggle` attribute.
- **`tRAIT`** (L1386) ⭐ — display a *named attribute* of the source (vs `tAG`'s tag); resolve
  trait block, repoint `wig.group`; key-field repeated-value suppression; first pass registers
  a listener.
- **`tREE`** (L1435) ⭐ — tree source + action: require a `leaf` descendant; `"selected"` →
  `selectedMembers` listener, else locate the source; assign to `branch.group`+`entry.group`;
  `setExpander`; `sourced`.
- **`tYPE`** (L1481) — set the `type` attribute's text to the parent registry's name.
- **`wINDOW`** (L1490) — **window/pane creation** (first pass): style mask from
  `closable`/`title`/`resize`; root→reuse `bwana.window`, `isPanel`→`new Panel`, else
  `new Window`; `setFrame`/`setTitle`/`contentView.add`/`setDelegate`.
- **`xmlFILE`** (L1540) — load+merge an XML file (`wig.merge(block)`), saving/restoring
  `currentRegistry`.

## B. Functional clusters

1. **Dispatch / registration** — `setAction` (hub), `aCTION`, `rEGISTER`, `rightCLICK`,
   `popUP`, `setSORT`, `tYPE`.
2. **Window / view creation** — `wINDOW`.
3. **Widget flag-and-draw binders** — `bUTTON`, `cELL`, `iMAGE`, `pATH`, `tEXT`, `menuITEM`,
   `pullDOWN` (attribute → `isX` + `draw=@displayX` + `isDisplayable`).
4. **Data-source & reaction** — `sOURCE`, `sELECTsource`, `nEXT`, `mERGE`, `tAG`, `tRAIT`,
   `sHOW`, `dESCRIBE`, `tREE`, `tOGGLED` (see §C).
5. **Tree / card / tab structure** — `tREE`, `resetTREE`, `expandTREE`, `setExpander`,
   `setCARD`, `tABS`.
6. **Grid / "bigify" layout** — `bigify`, `buildBigifyRow`, `getStashedItem` (object pool).
7. **Input / keystroke** — `keySTROKE`, `keyStrokeMatch`, `keyCode`.
8. **JIT glue** — `itemMETHOD`, `jitMETHOD`, `getBlock`, `keyCode`.
9. **Flag / format / geometry helpers** — `debugFLAG`, `flagFIELD`, `mINIMUM`, `setModified`,
   `indent`×2, `toString`, `timeEnd`.
10. **File loaders** — `delimitFILE`, `xmlFILE`.

## C. Data-source & reaction machinery (end-to-end)

A classic **observable/listener** system layered on the GroupItem tree. A source is stashed
in an attribute named **`sRCe`** whose `.pointer` holds a `Source*`.

1. **Attach** (`sOURCE`): locate the named block; reuse its `sRCe` or create a `Source`; store
   `entry["sRCe"] = (void*)source`. Defensive: remove any **stale copied `sRCe`**
   (`entry %-= oldAttribute`) first — copied/scrolled blocks inherit a stale pointer.
2. **Selection sources** (`sELECTsource`): the singletons `selectedMembers` /
   `selectedAttributes` (**held on Bwana**) stored as `sRCe`; `source.addListener(wig)`.
3. **Generate content** (`nEXT`/`tAG`/`tRAIT`/`sHOW`/`mERGE`): read the current source
   position and write into the block — `nEXT` advances (`source.next()`) and repoints
   `wig.group`; `tAG` writes the tag/value; `tRAIT` writes a named attribute; `sHOW` toggles
   `noRoom`; `mERGE` override-merges per-record attributes.
4. **Reaction registration** (one-shot, gated on `!attributed`/`!sourced`): `hasReactions=true;
   item.reacts=true; source.addListener(wig)`.
5. **Update propagation — the scroll loop** (`nEXT`): first pass climbs to the nearest
   `contentVaries` ancestor and sets `block.method = setFLEXcontent` on its `across`/`down`
   layout attribute. Runtime cycle: **scroll → `Source` fires listeners → `setFLEXcontent` runs
   → re-drives `nEXT` per visible cell → each `wig.group` repointed to the next record →
   redisplay.**
6. **Selection reactions** (`dESCRIBE`/`tREE`/`tAG`/`tRAIT`): registered against
   `selectedMembers`/`selectedAttributes`; selection change → listeners fire → handler re-runs
   reading `lastSelect`. `dESCRIBE` also pushes into the live `TextStore`.

## D. Dispatch wiring

`setAction(block, property)` looks up `properties[property]` (the `pROPERTIEs` registry) and
copies its `.method` + `.deferred` onto the block — after which "the block *is* that action."
The handlers here are themselves the methods registered into `pROPERTIEs` under their
attribute names (case-mangling maps `button`→`bUTTON`, etc.). Three paths from attribute name
→ behavior:
- **(a)** fixed registered handler (`pROPERTIEs[name].method`);
- **(b)** `itemMETHOD`/`jitMETHOD` JIT-compiling the attribute's *own incant text* into a
  method (run now vs deferred);
- **(c)** a handler calling `setAction(wig, "<name>")` to bind a *named runtime action* for
  event/reaction time (`iMAGE`→`iMAGEwork`, `pullDOWN`→`menu`, `popUP`→`display`, `tABS`→`tab`,
  `menuITEM`→`iTEM`, `buildBigifyRow`→`makeBIG`).
`getBlock`/`keyCode` are externs the JIT-compiled code calls.

## E. Porting notes & bear traps

1. **Misleading filename** — `Map.rtn` is the attribute-action table, unrelated to
   `BitMAP`/`Maps/`.
2. **`getStashedItem` is a hand-rolled object pool** (`stash.noPrint`+`next()`) — reproduce
   the exact allocation count or replace wholesale.
3. **`buildBigifyRow` resists closurization** (by-ref counter + shared stash) — the
   abandoned-lambda comment is a real signal.
4. **`goto bailOnError`/`goto bailTAG`** — restructure on port.
5. **Self-`replace()` copy-on-write** (`iMAGE`, `jitMETHOD`) guards shared attribute nodes —
   preserve or corrupt shared templates.
6. **Stale-copy `sRCe` cleanup** (`entry %-= oldAttribute`) — drop it and sources
   alias/clobber.
7. **One-shot guards** `attributed`/`sourced`/`indexed`/`hasReactions` are load-bearing, set
   on subtly different objects (detail vs attribute vs block) — audit each. `resetTREE` exists
   only because "jit can't read a boolean."
8. **Commented-out manual-memory calls** predate BDWGC; confirm the live `release()` in
   `getStashedItem` isn't double-managing memory.
9. **Direct AppKit reach-through** — `dESCRIBE` pokes `TextStore`/`TextView`; `wINDOW` does
   `new Window/Panel`, `setFrame/setTitle/setDelegate/contentView`. The Apple-shim boundary.
10. **`itemFactory` is gone** but this file predates that — verify `new(...)` sites.
11. **Ambient `wig`/bare-name detail fields** resolve via `item.getDetail()` + `use` scoping +
    global registry state — the biggest porting hazard (same bare name, different meaning per
    method; TAWK "last-mentioned wins / `use X` re-mentions").
12. **`flagFIELD`/`debugFLAG` dispatch on a single character** — preserve the first-letter
    contract (`b/c/d/k/n/s/z`).
13. **`keyCode`/`getBlock` are JIT-environment workarounds** — may become unnecessary once
    Phase JIT ops emit IR directly.
14. **`expandTREE` destructively re-tags the live node** — relies on node-identity mutation.
15. **Well-worn debug territory** — many `//cout` traces / commented lines; don't resurrect
    blindly.

---

# Appendix B — `Bwana` deep dive (the overseer)

*`Bwana` ("boss") is the GUI **overseer / registry-owner** — a singleton (`static Bwana
bwana` on `Control`, built in `Control()`). Its job: populate the global `pROPERTIEs`
registry with one handler-bearing GroupItem per XML attribute, and hold the cross-cutting
runtime state (selection sources, fonts, windows, delayed-action stack) that per-item layout
code reaches via `use Control.bwana`.*

## A. Field inventory

| Field | Type | Purpose |
|---|---|---|
| `actions` | `Actions` | The named-UI-action table (reset to `new()` atop `registerMethods`). |
| `fontManager` | `FontManager` | `sharedFontManager()` — used by `fONT`/`fONTname`/`fONTsize`/`fONTstyle`. |
| `window` | `Window` | The native top-level window (written by `Control.start()`). |
| `extendParser` | `Groups` | Parser-extension carrying the `cOLOr`/`fonts` registries so the XML parser resolves color/font tokens inline. |
| `descriptions` | `GroupRegistry` | `dESCRIPTIONs` — help/description text, read by `dESCRIBE`. |
| `properties` | `GroupRegistry` | **`pROPERTIEs` — the central DSL table**: attribute-name → handler GroupItem. Every `mapMethod` appends here. `loadAsAttributes=true`. |
| `types` | `GroupRegistry` | `tYPEs` — type metadata, filled in `Control.setup()` from `XML/attributes.xml`. |
| `windows` | `BaseHash` | Hash of created windows (`Control.start` checks `.length` for "no window block"). |
| `lastSelect` | `GroupItem` | The most-recently-selected block — the *value* behind the selection Sources. |
| `expandables` | `Source` | **Declared but never used — dead field.** Likely a superseded selection-source variant. |
| `emptySource` | `Source` | A **null-object Source** — safe fallback so code never branches on "no source yet." |
| `selectedMembers` | `Source` | Observable Source over the **members** of the current selection. |
| `selectedAttributes` | `Source` | Same, **attributes mode** (`sourceAttributes=true`); chosen when a block has `useAttributes`. |
| `expandList` / `expandLabel` | `DoubleLinkList` / `String` | Matrix row/column expansion scratch (used by `Sheet.rtn`). |
| `controller` | `Control` | Back-pointer (gives access to `parser`). |
| `delayActions` | `Stak` | The **delayed-action queue** — `processMethods` pushes `modified` traits here and drains them last ("show runs last"). |
| `bwanaBuffer` | `Buffer` | Shared scratch buffer, reused by `DrawPoint.toString()` (a global temp — reentrancy smell). |
| `dRAW` | `boolean` | Debug flag. |

### ⭐ The Source fields — WHY a Source lives on the overseer (the answer)

A `Source` (`Source.twk`) wraps a GroupItem as a data source: caches its member/attribute
list as an array, tracks a scroll cursor, and — critically — **holds a listener list it
notifies when its data changes** (`updateListeners → processReaction`). The Source-typed
members exist on Bwana because **selection is a global, observable broadcast channel.** When
the user clicks a block, every block bound to "the current selection" must redraw. Rather
than poll, those blocks **subscribe** to a shared Source on the overseer (via
`sELECTsource`/`addListener`), and a selection write fires `updateListeners` on each
subscriber. Constructor wiring:

```
selectedMembers     = new;   selectedMembers.sourceSelected      = true;
selectedAttributes  = new;   selectedAttributes.sourceAttributes = true;
                             selectedAttributes.sourceSelected   = true;
emptySource         = new(lastSelect);   // null-object, from a throwaway item
```

**Why the *overseer* specifically:** these Sources are process-global (one selection, one
subscriber set), must outlive any window/layout pass, and are the rendezvous between the
native selection event and the many reactive blocks. The overseer is the only object with
that lifetime that everyone can reach (`use Control.bwana`). **The Source-on-overseer pattern
*is* the old GUI's reactive/observer system** — a hand-rolled publish/subscribe keyed on
selection.

### ⚠️ Critical porting finding — the publish side is native C++ and ABSENT from the source

The **writes** that set `lastSelect` and call `selectedMembers.setSourceItem(...)` /
`selectedAttributes.setSourceItem(...)` are **not in the oldGUI `.twk`/`.rtn` at all.** The
click path is `Layout.mouseUp → fireAction(block) → select(block)`, and `select()` is a
**native C++ method on `GroupItem`.** So only the *subscribe* side (`addListener`) and the
*react* side (`updateListeners`/`processReaction`) are in the GUI source; the *publish* side
lives in the kernel. **A port must re-implement that native `select()`** to set `lastSelect`
+ the two Sources' `sourceItem` and trigger `updateListeners`. (Likewise `ParseXML` — the
parser that builds the trees and the `track` member-lists — is **out of tree**, only in
gitignored `Aside/WithJIT/ParseXML.rtn`. Bring it in before porting.)

## B. Methods

- **`Bwana(Control c)`** (constructor, `:30`) — called once from `Control()`. Wires the
  back-pointer, borrows the parser, builds `extendParser` with the color/font registries,
  fetches the five registries (`pROPERTIEs`/`tYPEs`/`dESCRIPTIONs` + color/font), inits the
  scratch state (windows hash, `delayActions`, the four Sources, `expandList`). Does **not**
  call `registerMethods` — `Control.setup()` does.
- **`mapMethod(name, &method)`** (`:88`) — base registration primitive: `new(name)`, append
  to `properties`, flag `isSingleton`/`isClosed`, bind the C fn-ptr via `setMethod`. These
  property items run **during layout** (`Details.processMethods`).
- **`mapAction(name, &method)`** (`:62`) — `mapMethod` + `item.deferred=true`: handler fires
  on **user input**, not layout. (Only `"expand"` uses it.)
- **`mapAndTrack(name, &method)`** (`:76`) — `mapMethod` + `item.track=true`: the parser
  appends every enclosing block bearing this attribute to the property item's member list;
  `Control.checkLoad → processActionTrack` runs the handler once per tracked block after the
  full parse. (`"matrix"`, `"register"`, `"bigify"`.)
- **`registerMethods()`** (`:107`) — called once from `Control.setup()`; populates `properties`
  with the **entire attribute DSL** (table below). Registration order is (admittedly fragile)
  load-bearing: window/panel/drawPath first; describe/onLayout/show last (`show` also marked
  `modified` to force it into the delayed queue).
- **No `registerActions`** — action registration folds into `registerMethods` (deferred attrs
  + `setAction` in Map.rtn pulling the method off the matching property).

**The DSL vocabulary (attribute → handler):**
- *Front (order-sensitive):* `panel`/`window`→`wINDOW`, `drawPath`→`pATH`.
- *Flag fields (→`flagFIELD` unless noted):* `blank`, `commas`, `doNotScroll`, `key`,
  `keyAction`, `keyStroke`→`keySTROKE`, `noSourceSelect`, `selectable`, `zero`.
- *Main layout:* `action`→`aCTION`, `align`→`aLIGN`, `bold`/`italic`/`caps`→`fONTstyle`,
  `border`/`rounded`/`underline`→`bORDER`, `button`→`bUTTON`, `cards`→`setCARD`,
  `cell`/`label`→`cELL`, `color`/`textColor`→`textCOLOR`, `count`→`cOUNT`, `expand`→`eXPAND`
  *(mapAction)*, `fill`/`selectFill`/`selectStroke`→`fILL`, `font`→`fONT`,
  `fontName`→`fONTname`, `fontSize`→`fONTsize`, `format`→`fORMAT`, `image`→`iMAGE`,
  `jit`→`jitMETHOD`, `list`→`delimitFILE`, `matrix`→`buildMatrix` *(mapAndTrack)*,
  `menuItem`→`menuITEM`, `merge`→`mERGE`, `minimumHeight`/`minimumWidth`→`mINIMUM`,
  `next`→`nEXT`, `popup`→`popUP`, `pullDown`→`pullDOWN`, `register`→`rEGISTER` *(mapAndTrack)*,
  `rightClick`→`rightCLICK`, `scrollWith`→`scrollWITH`, `sort`→`setSORT`, `shadow`→`sHADOW`,
  `source`→`sOURCE`, `style`→`sTYLE`, `sum`→`sUM`, `tabs`→`tABS`, `tag`/`value`→`tAG`,
  `text`→`tEXT`, `toggled`→`tOGGLED`, `trait`→`tRAIT`, `tree`→`tREE`, `type`→`tYPE`,
  `xml`→`xmlFILE`.
- *Debug (→`debugFLAG`):* `dUMP`, `dRAW`, `pDF`, `pRINT`.
- *Tail (order-sensitive):* `bigify`→`bigify` *(mapAndTrack)*, `describe`→`dESCRIBE`,
  `onLayout`→`itemMETHOD`, `show`→`sHOW` *(+`group.modified=true`)*.

## C. Concepts, relationships & lifecycle

- **Bwana ↔ Control** — Control owns `static bwana`; Bwana keeps `controller`. Control drives
  lifecycle; Bwana provides the registry tables Control's `load`/`layout`/`start` consume.
- **Bwana ↔ `properties`** — the heart. Every usable attribute is a GroupItem here with a
  bound method + flags; `Details.processMethods` resolves each parsed attribute to its
  property trait and fires `trait.method(item)`.
- **Bwana ↔ Source/selection** — global selection Sources; blocks subscribe; native `select()`
  publishes; `updateListeners → Details.processReaction` re-fires reactive attribute methods.
- **Bwana ↔ Details** — `Details` (per-item `item.other`) reaches Bwana via `use Control.bwana`
  for `properties`/`delayActions`/selection state.
- **Lifecycle:** `Control()` → `new Bwana` (registries + scratch) → `Control.setup()` →
  `registerMethods()` + parse `attributes.xml` → `load(file)` (ParseXML builds trees +
  tracked member-lists) → `checkLoad()` runs tracked actions → `start(window)` → `layout()` →
  per item `processMethods` fires immediate methods, queues `modified`, drains `delayActions`
  (show). Runtime: click → native `select()` → Source `updateListeners` → `processReaction`;
  deferred actions (expand) fire from `Layout.fireAction`.

## D. Porting notes & bear traps

- **`properties`/`mapMethod` registry-of-handlers — keep the concept** (it *is* the DSL, and
  "attribute GroupItem carries a method" is already the incant idiom). But registration-order
  influencing processing-order is fragile (the comments admit it "does not quite guarantee"
  ordering) — a redesign should make ordering explicit (phases/priorities), not insertion
  order.
- **Selection Sources + `lastSelect` — keep the reactive concept**, but the publish side
  (`select()`) is native and absent (see ⚠️ above) — must be re-implemented. `emptySource`
  null-object is sound; keep it. **`expandables` is dead — drop it.**
- **`mapAndTrack`/`track`** — a parse-time workaround for "collect all blocks bearing an
  attribute, act after full parse." `processActionTrack` **overloads `deferred` as an
  already-ran guard** (confusing). A real "collect matching nodes" query should replace it.
- **`mapAction`/`deferred`** — `deferred` carries two meanings (skip-at-layout vs. ran-guard);
  disentangle.
- **`modified` + `delayActions`** — a one-bit "run me last" priority; subsumed by a proper
  phase system.
- **`bwanaBuffer`, `expandList`, `expandLabel`** — cross-method scratch parked on the overseer
  only for reach via `use Control.bwana`; should be locals/params. `bwanaBuffer` is a
  non-reentrant global temp — a smell.
- **`isSingleton`/`isClosed`** — parser-coupling read by the (out-of-tree) ParseXML; confirm
  semantics before relying on them.
- **Two divergent copies** — `Tests/oldGUI/Bwana.twk` (recon target) vs a top-level `GUI/`
  copy (extra fields like `item.layoutAction`); don't cross line numbers.
- **Confabulation caveat (resolved):** during this dive a sub-agent invented an `addToTracks`
  method, a `tracks` registry, and bogus `ParseXML.twk` line refs — **those do not exist.**
  The verified track-builder is `Aside/WithJIT/ParseXML.rtn:1145-1152`. Trust the grounded
  refs only.

---

# Appendix C — reactive data-binding loop (autopsy)

*Line-by-line autopsy of the subscribe+react half of the old GUI's observer system — the
mechanism `setFrame` does NOT cover (it does layout; this does the reactive trigger). Files:
`Tests/oldGUI/Actions.twk`, `Map.rtn`, `Source.twk`, `Details.twk`.*

**Ambient-context primer (load-bearing):** every handler opens with `Details detail =
item.getDetail();`. In TAWK a local typed as a class makes that instance the **bare-field
receiver** — so inside these functions `wig`, `sourced`, `isNext`, `noData`, `noRoom`,
`hasReactions`, `down`, `across` are fields of *that* `Details`, not locals. `wig` = the
GroupItem the detail describes (`wig.other` holds the `Details*`; `getDetail` at
`Details.twk:1181` resolves it). The flags live on **three different objects** (the Details, the
GroupItem `wig`, the ancestor `content`) — which one a bare name hits depends on `use`/typed-local
context. *This is the fragile part.*

### A. `setFLEXcontent` — the reaction body (`Actions.twk:277`)

The method installed as `block.method`, fired on every source change. Tiny — "re-walk the
varying block, re-drive `nEXT` per cell":
```
flexed = item.parent;                         // the content-varying container (scroll body)
while group = flexed.nextMember(group)        // each visible cell/row
    if stuff = group["next"]   nEXT(stuff);   // re-run the content step per cell
```
No direct mutation, no repaint — pure fan-out over visible cells; all work delegates to `nEXT`.

### B. `nEXT` — one-shot wiring + every-pass content step (`Map.rtn:728`)

Resolves the source every pass: `block = wig.findParent(name)`; `source = (block%sRCe).pointer`.

**First-pass wiring** (guarded `if !sourced`, one-shot): scrub any stale copied `sRCe`
(`wig %-= sourceAttribute`), re-stamp `wig["sRCe"] = (void*)source`, `sourced = true`. Then the
**`contentVaries` ancestor climb** — walk parents to the viewport flagged `contentVaries` (the
`*`-axis block), grab its `across`/`down` attribute, and **subscribe once** (`if !content.indexed`):
```
source.addListener(content);     // SUBSCRIBE — viewport joins the source's listener list
content.indexed     = true;      // idempotency
contentDetails.hasReactions = true;
block.reacts        = true;       // axis attr participates in reactions
block.method        = setFLEXcontent;   // INSTALL the reaction on the axis attribute
```

**Every-pass content step** (always runs): `block = source.next()` advances the **shared**
cursor; if null → blank the cell (`wig.group = null; noData = true; wig.noRoom = true`); else
**repoint** `wig.group = block` (cell now shows the element), clear `noData`/`noRoom`.

### C. Source mechanics (`Source.twk`)

`Source` wraps a backing GroupItem, snapshots its children into a flat `GroupItem **list` with a
`BitMAP map` of live children and a `current`/`start` cursor.
- `addListener(item)` (`:39`) — SUBSCRIBE; `listeners += item` (`+=` so it doesn't reparent).
- `next()` (`:107`) — advance cursor; `map.nth(++current)` → live element, sets `exhausted` at end.
  The cursor is **shared across all cells** — successive `nEXT` calls stripe successive elements.
- `setSourceItem`/`setList` (`:172`/`:157`) — snapshot (`list = sourceItem.toArray()`), reset
  cursor, then `updateListeners()`.
- `pageShift(length)` (`:132`) — scroll-by-page: move `start`, clear `exhausted`, `current = start`.
- `updateListeners()` (`:215`) — NOTIFY sweep: walk `listeners`; for each, if its detail
  `hasReactions`, call `processReaction()`.
- `processReaction()` (`Details.twk:695`) — REACT: walk `wig`'s attributes, skip `!item.reacts`,
  fire `trait.method(item)` / `item.method(item)` — this is where the installed `setFLEXcontent`
  runs.

### D. The loop, cradle to grave

1. **PUBLISH (native C++, ABSENT here)** — `select()`/scroll mutates the `Source` (sets item /
   `pageShift`), resetting the cursor. **Must be rebuilt.**
2. **NOTIFY** — the mutator calls `Source.updateListeners()`.
3. **FAN-OUT / subscribers** — walks `Source.listeners`; per listener with `hasReactions` →
   `processReaction()`.
4. **REACT** — `Details.processReaction()` fires the `reacts`-flagged axis attribute's
   `item.method` = `setFLEXcontent(axisAttr)`.
5. **FAN-OUT / cells** — `setFLEXcontent` loops the viewport's members; per cell with a `next`
   attr → `nEXT(cellNext)`.
6. **ADVANCE + REPOINT** — `nEXT`: `source.next()` (shared cursor) → `wig.group = element`.
7. **REDISPLAY** — no explicit repaint; the next layout/draw pass renders from the updated
   `wig.group`. **Repaint is decoupled from the reaction.**

### E. Salvage / rebuild / bear traps

**Keep:** Source-as-observable + viewport-as-subscriber; the **shared cursor striping** N elements
across N cells with zero per-cell index math; two-level fan-out (which blocks react vs which cells
refresh); `toArray()` snapshot (tree mutation can't corrupt iteration); **reaction-stored-on-the-
tree** (`block.method = setFLEXcontent` — pure homoiconic dispatch, the same `field.attribute`→call
idiom as the JIT/bytecode work — directly portable).

**Rebuild (absent):** the entire **publish side** (`select()` → source mutation → broadcast) is
native and not in these files. Budget an event→source-mutation layer. `toArray`/`map.nth`/`BitMAP`
are native — need an equivalent "flat indexable live-children view."

**Don't carry verbatim / bear traps:**
- **Four mirrored subscribe flags** (`sourced`/`indexed`/`reacts`/`hasReactions`) on three objects,
  all hand-maintained — make "is subscribed" a single fact (membership in `listeners`).
- **Receiver-less `processReaction()`** (`Source.twk:229`) runs against ambient `attributeDetail`;
  if listeners and ambient diverge it misfires — a genuine latent-bug surface. Rebuild with
  **explicit receivers**: `subscriber.react(source, element)`.
- **`contentVaries` ancestor climb** couples reactivity to layout/geometry parsing — let a block
  *declare* itself a reactive viewport instead of inferring from a `*` in its frame spec.
- **`sRCe` copy-scrubbing** (`Map.rtn:745`) exists only because attribute value-copy leaks stale
  source pointers (CLAUDE.md bear traps #1–#3) — design subscription to survive cell copying.
- **Repaint coupled by convention, not call** — a reaction firing outside the layout cycle shows
  stale pixels. Make react→invalidate→redraw explicit.
