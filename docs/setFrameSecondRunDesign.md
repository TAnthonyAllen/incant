# setFrame -- the second-run design (Tony, 2026-11-07, via Clay). Build after the first PDF.

Filed under SEQ ___ R0 (2026-11-07), beside docs/setFrameSecondRun.md, which holds the recon and the measurement of the
OWED line. Nothing is built from this note until after the first PDF.

1  setFrame(request): the request carries the form and, optionally, a revised frame (x, y, width, height).
2  The gate: if the request has a revised frame, the top field takes those four values from it; if not,
   it uses the form's declared values. Only the top field is gated; every child recomputes from its parent,
   so a % follows the new size. The "is there a frame" check must read right when absent (a lookup miss has
   read as true before); pin both cases.
3  setFrame copies the form, lays out the copy and returns it. The form's definition is never written.
   printDefinition(setFrame(form)) is the test.
4  The engine keeps the returned layout to draw from. On a resize it calls setFrame on the original form
   with the revised frame, replaces its stored layout, drops the old one. No laid-out result is ever saved.
5  fillDownAcross takes one request group (target, direction, ...), the compileIn pattern.
OWED: a returned tree arrives whole through return (members kept). Each copy leaks until KE-5.
LATER (windows): a laid-out field keeps a link to the field it came from, so clicks and listeners reach it.

Measured since (docs/setFrameSecondRun.md): the OWED line holds in the interpreter, three spellings, 2026-11-07.
Noted for step 1 of the PDF (branch fill-page): a drawn field now carries a `display` attribute that the top field
hands down; a laid-out copy is the natural thing to hand it to, since the form's definition is never written (point 3).
