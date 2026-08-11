# To Clay — the font/color/style layer needs your design pass (Stylish forced the issue)
*Design handoff drafted by Clod, 2026-06-27. Constraint set by Tony.*

> ## ⚠ DATED POINTER, 2026-08-10 (SEQ 30) — **THE DESIGN PASS THIS ASKED FOR HAS HAPPENED:
> ## `docs/displayDesign.md`.** Read that first; this file is the ASK and remains legible as such.
>
> ⚠ **REPOINTED 2026-08-11: `docs/displayDesign.md` IS NOW HISTORICAL.** The live ruling is the
> **`DisplayDesignHTML` entry of the `DesignDocs` registry, `incant/designDocs`** — the md was
> converted to kant, reviewed by Tony and Clay, and ruled canonical 2026-08-11. **The section
> numbers cited below still resolve against the md**, which is retained in full and unedited, so
> this pointer's own citations stay checkable; the *rulings* they summarise now live in the
> registry entry, and three of them MOVED at that review (HTML event fence widened, measurer made
> a protocol parameter, CSS-reconsider hedge recorded).
>
> **Classified: this document is style-system content end to end** — it carries no
> channel-etiquette half, so the whole of it falls under the pointer (Clod, SEQ 30, asked to
> classify it).
>
> **What `displayDesign.md` SETTLES of the ask below:**
> - *"what IS a Style and where does it live (per-element field? registry?)"* — **§3**: a style
>   sheet is a GroupItem group of **named bundles**, defined once and referenced by name.
> - *"how the cascade does copy-on-write without Details"* — **§3 dissolves the question.** There
>   is **no cascade and no scoping**: a named set replaces the current style **wholesale**, and a
>   field's own attributes merge for that field's rendering only, never written back. **The
>   Details-free constraint is met by there being no inheritance structure to host.**
> - The **output** half of the sink — **§5**: targets receive **resolved** output, everything
>   inline, no CSS, no classes, no selectors. **§7.1** makes HTML the First Light target.
>
> **What it does NOT settle, so this file is not superseded:**
> - The **Cocoa seams** — `getRGB` and `realizeFont` as thin leaf externs, one seam each.
> - The **command-line-provable text/SVG sink** for proving it without a window.
> - The **incant primitives each gap implies**, and `font-recon.md`'s parked Option A questions.
> - **§9(a) is still open and Tony's:** based-on style chains (`Heading2 = Heading1 + deltas`),
>   permissible only as definition-time resolution when the sheet loads, if at all.
>
> ⚠ **The hard constraint below — *no Details in incant* — is UNCHANGED and is satisfied rather
> than relaxed** by the §3 model. Nothing here reopens it.

Clay —

Tonight Tony and I set out to make `Stylish.twk` compile — expecting a mechanical "reconnect the
proven shim" job. It turned into a finding that lands squarely on your plate, and it deserves your
real design attention now rather than after another lap of recon.

**What we found.** Stylish doesn't fail on the font/color shim — `Font`/`Color`/`Shadow` reconnect
cleanly through OCframe. It fails because the actual work in it
(`fONT`/`fONTname`/`fONTsize`/`fONTstyle`/`sTYLE`/`setFont`) is **widget-context code**: it reaches
for `wig`, `style`, `getStyle`, `getDetail`, `setColor`/`setFont` — which live on the old GUI's
widget / **Details** / OBwrap classes and drag in the whole `Frame`/`Point`/`Layout`/`Event`/
`TextView` web. There's no cherry-pick that compiles it. The dependency isn't the font leaves; it's
the widget they hang on.

**The hard constraint (Tony, firmly).** *No Details in incant.* Incant was half-designed to
**eliminate** Details — so this redesign has to design that dependency **away**, not reconnect it.
That's the line in the sand: whatever the new style/font/color layer becomes, it cannot lean on the
Details tree or the C++ widget context.

**Why it's yours.** `docs/font-recon.md` already did the archaeology and explicitly parked the open
questions on you (Option A): Color as incant data off the `cOLOr` registry; Font as a
`family=/size=/bold/italic` spec with a single `realizeFont` leaf extern; the `Stylish(item,source)`
cascade re-expressed in incant (`=` vs `:=`, mindful of the method-drop / byRef traps); a Cocoa-free
SVG/text sink for command-line provability; and the incant primitives each gap implies. The recon has
marinated. This is the moment to commit to an actual design.

**The ask.** A design for the font/color/style layer that is (1) **Details-free** — no widget/Details
C++ context; (2) **incant-native** for data + cascade, with Cocoa pushed to thin leaf externs at
exactly one seam each (`getRGB`, `realizeFont`); (3) **command-line-provable** via the text/SVG sink.
Concrete enough for Clod to execute: what *is* a Style and where does it live (per-element field?
registry?); how the cascade does copy-on-write without Details; where color-name→RGB and font
realization cross to Apple.

It's genuinely complex — the interesting kind. Tony's call, which I think is right, is that all three
of us being in this from the design stage serves us far better than me executing around a half-formed
shape. So: the floor's yours for the design pass.

— Clod

---

## Background pointers for the design
- `docs/font-recon.md` — the recon this builds on (settled decisions + Option A open questions).
- `docs/gui-brief.md`, `docs/font-recon.md`, `docs/layout-recon.md` — GUI-arc context.
- The proven-but-Details-bound implementation: `GUI/Stylish.twk` (reference for *what* it did, not
  *how* the new one should be structured).
- The active rewrite that triggered this: `Stylish.twk` (top-level) — note its font/style functions
  are free externs reaching for widget-class `wig`/`style`, which is the smell.
