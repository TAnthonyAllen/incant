# To Clay — the font/color/style layer needs your design pass (Stylish forced the issue)
*Design handoff drafted by Clod, 2026-06-27. Constraint set by Tony.*

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
