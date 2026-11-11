# setFrame, a second run: recon (R3, 2026-11-07)

Recon and docs only, under R3 (Tony's offline status, via Clay): read utilities' setFrame, not tester's. Nothing built.
setFrame is in utilities as of `370b9016` (tester's draft, moved verbatim). Binary bare, unchanged since seal 372.

**The question** (docs/setFrameSpec.md): a resize re-runs setFrame on the top field (ruled). For that to work, where do
the computed sizes live, and where does the original member set live?

**The probe** is `docs/setFrameProbes/secondRun.sh`, rerunnable from Groups. It runs six shapes once, twice, and after
a resize to width 400, each in its own process, and then lays out a copy. All 21 runs exit 0 with the sentinel printed.
A second run of the script gave byte-identical frames.

## What a second run does (kant, measured)

| shape | one run | second run | after resize to 400 |
|---|---|---|---|
| simple: across, three members, one width, one height | right | same as first | **children unmoved**: fifth keeps 50 where 200 is right |
| pct: across, `half width=50%`, `rest` | 100 and 100, right | same as first | **unmoved**: half stays 100, right is 200 |
| tri: `down=3`, two members | 6 cells of 15 | **18 cells**, running out to y 255 in a 90-high field | 18 cells, unmoved |
| nest: `down=3` of a cell holding two | 3 cells | **9 cells** | 9, unmoved |
| sumple: `down=* across=2` | 2 columns of 4, right | **4 columns** out to x 475 in a 250-wide field, and 4 warnings "dirCell can only have one member" | the same 4 columns |
| star: `down=*`, one row of 50 | 2 rows | "can only have one member", then 2 rows | 2 rows, unmoved |

**The declared percent does not survive even one run.** half reads `50`, isPercent 1, before setFrame and `100`,
isPercent 0, after. The ruling that declared values survive a run is broken on the first run, not only the second.

## Why: the two writes

1. **The fill replaces the member set and keeps its own trigger.** fillDownAcross builds newStuff from the attributes
   plus copies of the members, then does `clear(argument); argument = newStuff;`. The `down=3` / `down=*` attribute
   rides across, so the next run fills again from the copies. bothDirections does the same one level out: it wraps
   the members in a dirCell, drops the inner direction, and leaves the outer number, so the next run puts dirCells
   inside new dirCells. **The original member set does not exist anywhere after one run.**
2. **Computed sizes are written over the declared ones.** Each member gets width, height, x and y by `:%` of a copy,
   so the same attribute names hold the declared value before the run and the computed one after. The next run cannot
   tell them apart, so it reads a computed size as declared and nothing under the top field moves.

simple and pct survive a second run only because neither has a fill. Their sizes are still stale after a resize.

## Who reads a frame today

Searched: utilities in full, and the forms plan (`Topics/forms`). In utilities, only setFrame itself and
`displayIfVisible` (:35) read x, y, width and height. `bigifyLayout` writes them as percents for setFrame to read. In
the plan, only the window's own frame is read (`getFrame`, forms :291); nothing draws yet. **So no reader yet depends
on where computed sizes live, and the choice is still cheap.**

## Two designs, for ruling

**A: lay out a copy (measured, works).** setFrame runs on `copyOf(top)`, never on the declared tree. The copy is deep
enough: after laying out a copy of nest, the original's cells and leaves still have no frame. After sumple's, the
original still holds its one crossing. A resize lays out a fresh copy. pct, stamped, resized to 400 and stamped again,
reads half 200 and rest 200 at x 200, both right, and the original still reads `50`.
- For: one move answers both questions. The declared tree is the original member set, and the copy holds the computed
  sizes. setFrame itself needs no change, and a second run cannot multiply, because every run starts from the declared tree.
- Against: two trees. Anything that changes a form while it is up (edited text, the selected tab, a field hidden)
  must be made in the declared tree, and a hit found in the copy must map back to it (by tag path, say). Each copy is
  never freed (KE-5, the collector entry): about 300KB a layout on a 110-field form, measured 2026-11-06. So a resize
  on every drag step grows memory until KE-5 is ruled.

**B: one tree, computed values kept apart.** The computed frame goes in its own place on each field, either a frame
attribute holding x, y, width and height, or four names of its own. The fill keeps the declared members, for example
under an attribute, or with its copies marked so the next run drops them first.
- For: one tree, so state, hits and identity stay simple.
- Against: setFrame and fillDownAcross both change: read the declared values, write the frame, and undo the last fill
  before filling again. Every future reader of a frame must read the new place.

**Clod's lean: A for firstLight to PDF, and the window choice made when windows come.** A PDF is laid out once, with
no resize, so the next step (R2's order) needs only a first run that is right. Today's first run is right in every
shape above except the declared percent, which A keeps intact. B's cost is paid only when a form can resize.

## Context, not findings (no row red; relevance gate)

- utilities' setFrame prints `WARNING compare: ... the string is not a number` on stderr in every run of these shapes,
  70 lines across the probe. It comes from the string-against-number tests in fillDownAcross and setFrame. Values are right.
- `tsfLine` (unitTests) prints a coordinate of 0 as `x=-`, because `if argument["x"]` reads 0 as absent. That is the
  trace's own reading, not setFrame's. The fleet's simple and sample have no zero coordinate.
- The certificate row the spec registered, "a resize to 400 reads 200 and the declared 50% is still there", reads 100,
  with the bit gone, today.

**Ruled 2026-11-07 (Tony, R0): A or B is NOT chosen.** The first PDF lays out the original form once; the second run and resize are discussed with Clay and come back as their own dispatch. Clod's lean above stands as a lean only.

## THE DESIGN (Tony, 2026-11-07, via Clay). Build after the first PDF.

1. setFrame(request): the request carries the form and, optionally, a revised frame (x, y, width, height).
2. The gate: if the request has a revised frame, the top field takes those four values from it; if not, it uses the
   form's declared values. Only the top field is gated; every child recomputes from its parent, so a % follows the new
   size. The "is there a frame" check must read right when absent (a lookup miss has read as true before); pin both cases.
3. setFrame copies the form, lays out the copy and returns it. The form's definition is never written.
   printDefinition(setFrame(form)) is the test.
4. The engine keeps the returned layout to draw from. On a resize it calls setFrame on the original form with the
   revised frame, replaces its stored layout, drops the old one. No laid-out result is ever saved.
5. fillDownAcross takes one request group (target, direction, ...), the compileIn pattern.

OWED: a returned tree arrives whole through return (members kept). Each copy leaks until KE-5.
LATER (windows): a laid-out field keeps a link to the field it came from, so clicks and listeners reach it.

**The OWED line, measured 2026-11-07 (kant, interpreted; docs/setFrameProbes/returnWhole).** A copy of a nested form,
laid out inside an action and returned, arrives whole by all three spellings tried: `return *pc;` read with `:=`, the
same read with `=`, and `return pc;` (the holder) starred by the caller. Each reads 8 list entries, the same count as
inside the action (3 cells and the form's 5 attributes), and every frame to the leaves; the original stays unframed. Not
measured: a jitted return, or returning through more than one call. This answers the OWED line for the interpreter only.
Nothing is pinned in the fleet; the build's certificate owes the rows.
