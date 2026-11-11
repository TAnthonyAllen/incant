# setFrame's rerun (forms step 6): proposed strokes (SEQ 625 W1, 2026-11-11). Read-only; nothing built.

**RULED 2026-11-11 (Tony, SEQ 626 R1-R5): the five points at the foot are answered in Topics/forms, "setFrame's rerun". Stroke 1 built at seal 456. The text below is the proposal as written.**

**Plain line: the rerun itself needs no listening. Three strokes build it on what is already ruled; Tony's frame-and-listener
idea is a fourth, and it is the only one that waits on listening. Five points need a ruling; they are listed at the foot.**

Read for this: `incant/utilities` (setFrame, fillDownAcross, bothDirections), `docs/setFrameSecondRunDesign.md` (the ruled
design), `docs/setFrameSecondRun.md` (the measurements of 2026-11-07), `Commands.rtn` listenTo, `GroupItem.twk`
updateListeners, and the listenT and defineRefT rows in `genLadder/pop.sh`. Measured in **kant** unless a line says tok.

## What is true today
- **setFrame writes the definition, three ways.** (1) Every child's width, height, x and y are written with `:%` over what
  was declared, so a declared 50% reads as a plain 200 afterwards (measured again today, `simple`). (2) fillDownAcross
  replaces the member set of a `down=3` or `across=*` field with copies, so a second run multiplies them (6 cells become 18).
  (3) bothDirections wraps the members in a new cell.
- **A first run is right**, percent included (roundedT RD-8). Only a rerun is wrong.
- **A child's own x and y are always overwritten.** The x/y pass is unconditional (`x = pX; y = pY`). A parent with neither
  down nor across is treated as down: its children are stacked from its origin, whatever x and y they declare (found at
  seal 452, shadowT). In the old GUI a parent with no direction took the overlay case: a child fills the parent's box
  unless it fixes its own x, y, width or height (`GUI/Details.twk`, setFrame's default case). So today differs from the old GUI here.
- **Listening today:** `listenTo:=` arms when the listener is defined. On EVERY write to the notifier the listener copies
  the notifier's VALUE, at once (updateListeners is called from each setter, tok). None of the notifier's attributes
  arrive (listenT LN-2). There is no onNotify, and no way to hold a notification back until a command.

## Already ruled (2026-11-07), and still the base
The definition is never written; setFrame lays out a copy and returns it; the result is used and dropped; a rerun is a
fresh run from the definition; the request may carry a revised frame, which only the top field takes.

## The strokes
**Stroke 1 -- lay out a copy. Needs nothing from listening.**
setFrame copies the form, lays out the copy and returns it. Callers draw the returned copy: `laid := setFrame(form)`,
then the walk on `*laid`. Done when: the definition prints the same before and after; a declared percent still reads as a
percent after; a second run equals the first on the six shapes of `docs/setFrameProbes`. Every fixture and form driver that
calls setFrame and then draws the form changes to draw the copy (firstLight's, descriptions', roundedT's among them): a
respell with rows registered first. Known cost: each copy is never freed (KE-5), about 300KB for a 110-field form.

**Stroke 2 -- the revised frame. Needs nothing from listening.**
`setFrame(request)`: the request holds the form and, optionally, a frame (x, y, width, height). With a frame the copy's top
takes those four; without one it takes the form's declared four. Done when: a resize to 400 gives the 50% child 200, and
"no frame given" and "frame given" are both pinned (a lookup miss has read as true before). This is where the first half
of Tony's idea already fits: **the frame set outside the definition is this request's frame.** With strokes 1 and 2 the
mock click (G1) can re-lay out and redraw; it needs no more than these.

**Stroke 3 -- a child's own x and y. Needs nothing from listening; small; can go before or after stroke 1.**
Under a parent with neither down nor across, a child keeps the x and y it declares. Two things must be ruled first (below,
3 and 4). It is safer after stroke 1, because then no declared value can be lost whatever the pass does.

**Stroke 4 -- layoutFrame and the listener. This one waits on listening.**
On a resize Layout writes a global layoutFrame; the form's frame listens to it; an explicit command fires the listeners;
the form is laid out again from the new frame and redrawn. What it needs from listening, none of it built:
- **a notifier that is a group of four values.** Today a listener receives one value and no attributes. Either the listener
  receives the notifier's attributes, or each of the four is its own notifier and listener.
- **firing on an explicit command.** Today every write fires at once, so writing x, y, width and height would lay the form
  out four times. listenT LN-1 pins "three writes reach the listener", so this changes a pinned behaviour.
- **onNotify.** Copying four numbers lays nothing out; something has to run setFrame and the redraw when the frame arrives.
  The design of record is one onNotify per listener, its handler handed the notifier.
- **a place for the result.** The ruled design says the engine keeps the laid-out copy and never saves it; a handler needs
  to be told where that is.

**Clod's lean:** build 1, 2 and 3. Do the first resize by a plain call -- Layout calls a kant extern with the new frame, as
is already ruled for mouseUp -- and move it onto layoutFrame and a listener when listening is sorted out (Tony's, SEQ 622
R4). Stroke 4 is then a change in who calls stroke 2, not a new design, and nothing in 1 to 3 has to be undone for it.

## Where a ruling is needed
1. **The frame's home and shape.** A field of its own outside the form that the request holds, or an attribute on the form
   (which puts it back inside the definition)? One `frame` with four attributes, as Tony's idea says?
2. **The top's declared x, y, width and height.** Do they stay legal as the default when no frame is given (the ruled
   design says yes), or does the frame replace them?
3. **A parent with no direction.** Stack its children as down (today), or overlay them as the old GUI did?
4. **A child's declared x and y.** Measured from its parent's origin, or from the page? (The top's are page coordinates today.)
5. **Listening, for stroke 4 only:** firing on a command (for every notifier, or only for one marked so); what a listener
   receives from a group; onNotify's build. These are listening's own questions and can wait for it.

## Also in step 6's "done when", not covered above
noRoom and isHidden. setFrame's own comment says it should check for no room and stop; nothing does. Neither depends on
the choices above; they are a stroke after 1 and 2.
