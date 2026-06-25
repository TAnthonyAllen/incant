# Font Design — Recon Synthesis (2026-06-25)

*Tonto-style archaeology across the docs + Stylish.twk, feeding the Clay design conversation
on font/color handling in the incant→Layout GUI. Excerpt-based recon — verify specifics
(line numbers, the Details-tree claim) during design, but the shape is reliable.*

## The headline
**The font/color model is already proven** — the old GUI's `Stylish` struct + `convert()` +
the `getRGB` seam works end to end. The design question is **not whether it works, but *where it
lives*** — how much moves from C++ procedures into incant logic. Cocoa boxing punts to leaf
externs; the data model wants to be pure incant and command-line-provable.

## Settled decisions
1. **Color** — named `cOLOr` registry, entries hold hex `#rrggbb`; lazy `colorize()` → `NSColor*`
   cached as `void*` on the GroupItem. **`getRGB(&r,&g,&b,&a)` is the single extraction seam** —
   feeds both Cocoa and the libHaru PDF backend (Cocoa stays out of the data layer).
2. **Font** — carried as a GroupItem (`fontItem`) boxing `NSFont*`; **consolidated attribute
   format `family=/size=/bold/italic`** (was scattered `fONT`/`fONTname`/`fONTsize`/`fONTstyle`).
   Mutated by `convert(font, arg)` (NSString family / double size / int trait-mask).
3. **Style cascade** — copy-on-write via `Stylish(item, source)` (`*this = *source`, then override);
   **lazy-derive guard** `if !style style = new(wig, getStyle())` on first write. Named styles in
   the `sTYLEs` registry, cached as `void*`.
4. **Apple shim** — `Font ≡ NSFont*`, `Color ≡ NSColor*`, boxed via
   `getPointerGroupItem`/`setPointerGroupItem`; `__bridge` inside `-% %-`; `hold()` retains
   against Boehm GC. Thin-by-wrapping, proven in old GUI.

## Open questions (Clay's plate — Option A)
1. **Color in incant** — GroupItem with `r/g/b/a` count fields resolved from the `cOLOr` name
   registry? Where does name→RGB live (registry vs inline incant)?
2. **Font in incant** — keep `family=/size=/bold/italic`; replace `convert()` with incant that
   builds a font-spec, `NSFont` realization a single **leaf extern `realizeFont`**? Where does
   the cascade live — per-widget `style` field, or registry lookup?
3. **Cascade mechanism** — re-express `Stylish(item,source)` copy-on-write in incant. Ride
   existing GroupItem copy semantics (`=` vs `:=`), or a new primitive? (Bear traps #1–#3: `=`
   drops method bindings; `:=` stamps byRef permanently.)
4. **SVG/text-dump sink** — stub renderer making color/font command-line-provable with zero
   Cocoa (color→`rgb(...)`, font→`font-family/size/weight`). Keeps Option A POP-able.
5. **Missing incant primitives** — color arithmetic, attribute introspection, spec-building
   idioms. Each gap → a finding → add a primitive/extern.

## The wedge
**`convert()` is the one C++ procedure** standing between a pure-incant font model and Cocoa
realization. Lifting it (or replacing it with a registry of immutable font variants) is the path
to Option A command-line provability.

## Two independences to protect
- **Cocoa independence in the data layer** — color/font expressible in pure incant (`r/g/b/a`,
  `family/size/bold/italic`), Cocoa boxing only at the leaf (`getRGB`, `realizeFont`).
- **Backend independence in rendering** — `getRGB` already proves colors work for Cocoa *and*
  libHaru PDF; a leaf `realizeFont` should give fonts the same backend-neutrality.

## Surprises / tar babies (don't fix — flag during design)
- `setFont`/`setColor` fixes parked in old GUI (gui.md).
- `setPDFfill`/`setPDFstroke` **ignore their `Color` arg**, read ambient state — latent bug; the
  color seam isn't fully clean across backends.
- **Stale boxed pointers on copy** — `=` content-copy doesn't drop copied `pointer` fields, so a
  copied block's boxed color/font (and `sRCe`) stale-point to the original. Needs explicit scrub.
- **Details shadow-geometry tree** (per layout-recon.md) — old Layout keeps geometry in a parallel
  `group.other` Details struct, not `frame` attributes on the model. Biggest blocker to moving
  frame logic to incant; *separate* from font/color but will collide with the cascade work.

## Where it lives (drill-down)
- Font/color/cascade source: **`Stylish.twk`** (font handlers ~97–239, copy-ctor ~51–57).
- Font/Color model write-up + `getRGB` seam: **`docs/gui.md`** ~235–257 (keep/pound list), 163–164.
- Option A open questions: **`docs/gui-brief.md`** Q1–2, **`docs/gui.md`** 274–289.
- Layout font bridge: `Layout.twk:41` (`style.getFont()` inline — will change post-design).
- Old GUI recon (reference, not load-bearing): `docs/gui.md` Appendices A–C (453–923).
