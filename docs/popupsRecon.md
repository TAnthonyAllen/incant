# Popups recon (SEQ 760, assigned by Clod, 2026-11-23)

The resurrection dispatch, piece 2 (Clay, ruled by Tony, 2026-11-23): a popup is a form shown in its own small window.
Read-only recon, then decisions for Tony, then strokes smallest first. Documents only: this file, a pointer in
`Topics/windows`, a line on F-158 in `docs/fixIts.md`.

**Every fact here is READ on trunk at seal 539, not run, unless it says measured.** The population read: `guiHost.mm`
(all of it), `incant/utilities` (show, the click, selection, describe, the window actions), `IncantForms/Windows/`
(colorList, descriptions, firstLight, and a grep of every form for `popup`), `GUI/` and `formsRecon` for the old popup,
`Topics/windows`, `Topics/forms` (user edits) and the notes in `incant++`.

## 1. What exists today that a popup can stand on

| a popup needs | today | where |
|---|---|---|
| a second window | yes: any number of windows, each with its own form, request and search list | `guiHost.mm` gWindows, makeWindow |
| opened from a click | yes, seen by Tony (stroke 5): a button's click action called show and a window opened from inside the loop | Topics/windows seal 538 |
| opened at a place | yes in the machinery, by no action yet: a request may carry `frame:=`, and the window opens there (windowLay keeps it, setFrame reads it). showForm builds its request with no frame | `guiHost.mm` windowRequest; `utilities` windowLay, showForm |
| to know where the clicked field is on the screen | yes: a window lays its form out at the window's own frame, so every field on the laid-out copy holds its frame in screen points, y down. The action is handed that field | `guiHost.mm` windowRelay, formFrame |
| to know what was clicked when the action sits higher up | yes: the action is handed the level that fired, and `selection` holds the field that was hit. For a poured row, the hit field's `each` is the member it stands for (tsEachFind) | `utilities` clickField, pourMark |
| closed from kant | yes, built for the fleet: `windowClose(request)`, form:= the form. Not run from a click inside the window it closes | `guiHost.mm` windowClose |
| one popup per form | yes: a second show of an open form raises it and lays it out again, never a second window | `guiHost.mm` alreadyOpen |
| the owner redrawn after OK | only by showing it again (which also brings it to the front), or by its own next click or resize. Nothing redraws another window in place | `guiHost.mm` windowRelay is static |
| the popup tied to its form | no. Windows do not know each other: closing the form leaves the popup open, and the program runs until the popup closes too | `guiHost.mm` windowClosed, loopCheck |
| modal | no. Every window takes clicks at all times | `guiHost.mm` windowClickAt |
| a selection of its own | no. `selection` is ONE field for the run, and it is matched by NAME on every layout: a click in the popup takes the selection away from the form, moves the form's help box, and a popup field named like a form field (ok) would be outlined in both | `utilities` selectionPick, describePick, describedName |
| keys | no. The view has mouseUp only: no keyDown, no first responder | `guiHost.mm` Layout (Events) |
| chrome | title bar, close button and resize are hard-coded for every window (W4); the title is the form's `title=` | `guiHost.mm` makeWindow |

**The old GUI's popup** (`formsRecon` :125, `GUI/Actions.twk` dISPLAY): `popup=Name` on a field made a click bring the
window or panel registered as Name to the front, loading it from the field's `file=` if it was not registered. No
value came back and nothing was modal; it was "show that panel". Four forms still carry the old spelling and are not
respelled: inspector, layout, menu, and a template in Controls.

## 2. The customers, and what each needs beyond a plain popup

| customer | needs |
|---|---|
| the colour description popup | nothing more: text shown, one button. The smallest real customer |
| the colour popup (sampler, edits: lighten / darken stepped by clicks, open forms redrawing live) | lighten / darken (parked dispatch); a redraw of other open windows in place, without raising them; the scope question (everywhere or this form) is itself a small popup |
| the text-editing popup | keys, which do not exist. Its command pop-up (2026-11-09: pick a command, its action fires) needs none, but the editing does. Its own recon |

## 3. The decisions that are Tony's

**D1. What opens one.** Three ways, not exclusive:
- (a) an action: `onClick:=someAction`, the action calling a new `popup(request)`. Works with today's click rule and nothing else.
- (b) an attribute: `popup:=aForm` on a field, as the old GUI spelled it. A click on the field, or on anything under it
  that fires nothing itself, opens aForm. This is Tony's note for colorList: `popup:=` on clRows, the pour unaware. One
  new arm in clickFire (a held form under the name popup is opened, not fired).
- (c) on select, with no click rule at all. Since a click always selects first (2026-11-04), (b) already is "on select"
  for the mouse; (c) would differ only for a selection made some other way, and there is none today.

Clod's lean: (b) resting on (a). The popup is told three things: the form it was opened from, the field that was hit
(`selection` at that moment), and that field's `each` when it is a poured row.

**D2. Where it appears.** At the hit field (its top left under the field's bottom left, moved to stay on the display);
or centred on its form; or where it was last closed (formFrames does this for every window today). Lean: at the hit
field the first time; after that, wherever the user left it. (Ruled otherwise: 3a, item 2.)

**D3. Modal or not.** Lean: not modal by default, since the sampler and a colour popup are meant to sit beside the
form while it redraws. `modal` as an attribute of the popup form for the cases that need it (the scope question, "you
really want to do this?"): while it is open its form ignores clicks and a click there brings the popup forward. That is
one test in the window's click, not AppKit's modal loop, which would run a second event loop inside ours.

**D4. OK and Cancel.**
- What OK writes to: the copy that was clicked is thrown away at the next layout, so a value can only go back BY NAME:
  to the definition's field (form name and field name) or to a registry entry (a colour, a description). Lean: the
  popup holds a target written as those names; OK's action writes it; then the form is laid out again in place.
- Cancel and the close button are the same: nothing is written, the popup closes.
- Live preview (the colour popup): each step writes and redraws at once, so Cancel must put the old value back. The
  popup keeps the value it opened with.
- For Tony: is OK / Cancel built in (two reserved field names or two actions every popup uses), or does each popup
  form write its own onClick actions on top of `popupOk` and `popupCancel`? Lean: the two actions, forms use them by name.

**D5. Closing the form with a popup open.** Lean: the form's popups close with it, as Cancel. Today they would stay
open and keep the program running. Also for Tony: does a popup float above its form and move with it (AppKit gives
both for a child window), or is it an ordinary window? Lean: a child window.

**D6. Selection.** A popup needs a selection of its own or it steals the form's (section 1). Lean: selection kept per
form, by the form's name, as formFrames keeps frames; describe follows it. This also corrects two ordinary windows
open side by side today.

**D7. Chrome.** Lean: a popup keeps the title bar and close button and loses resize, read from the form
(`resize` is already an inert attribute name, W4).

## 3a. RULED (Tony, 2026-11-23, via Clay)

1. What opens one: `popup:=aForm`, resting on a plain `popup(request)` action.
2. Where it appears: at the hit field, every time. Remembering where it was left is not ruled; parked.
3. Modal: not by default; `modal` as an attribute where needed.
4. OK and Cancel: two shared actions popup forms use by name; the value goes back by name; Cancel writes nothing.
5. Closing the form closes its popups, as Cancel; the popup is a child window above its form and moves with it.
6. Selection: per form. A fix for two plain windows too, not only for popups.
7. Chrome: title bar and close button, no resize.

Strokes 0-6 below are bought as the plan, in that order; none starts until Tony sends it.

## 3b. Built

- Stroke 0 (SEQ 762, bought and merged 2026-11-23): `laidLook` on every laid-out copy's top; typeset reads it. F-158 closed.
- Stroke 1 (SEQ 763, bought and merged 2026-11-23): `selections` and `describedNames` in utilities keep, by the
  name of the form a window shows, the selected field's name and what the help box described last. Every laid-out copy's
  top carries `laidForm`, the form its layout was for (a held form's top carries its host's), and a click reads it.
  `unselect(form)` clears one form's. `selection` still holds the last field clicked in any form. formsPop windowSelectT.

- The climb (SEQ 764, bought and merged 2026-11-23; windows TO DO 1 with two rulings of 2026-11-23): an only-room
  field is not selectable and the selection climbs to the first field that is; a click in a held form bubbles on into its
  host; a window's close clears its form's selection (`windowShut`, the one C++ line: the close calls it, not keepFrame).
  formsPop windowClimbT.

## 4. Strokes, smallest first (RULED as the plan, Tony 2026-11-23)

| # | stroke | size | proof with nobody watching |
|---|---|---|---|
| 0 | **The look rides on the laid-out copy** (RULED, Tony 2026-11-23; F-158; the first piece of the 2026-11-12 layout context). setFrame leaves the look it resolved on the copy's top field (and on a held form's top when that form fell back to its own); typeset climbs from the field it is drawing to the nearest one and resolves the run through it. The four shared look fields stay for layout. | small, kant only: about 25 lines in setFrame, placeForm and typeset; no C++, no rebuild | piece 1's probe as a fixture: two offscreen windows under two looks, the first read again after the second is laid out: 470 pixels differ today, 0 after; a held form that fell back, its run in its own look; H7 |
| 1 | **Selection per form** (D6). | medium, kant only: selectionPick, describePick, click, clickField, describedName | two offscreen windows: a click in the second leaves the first's outline and help text; the same field name in both, outlined only where clicked |
| 2 | **`popup(request)` opens a form as a window at a place, and remembers what it was opened on** (D1a, D2). | small, kant only | offscreen: a click on a field opens a second window whose frame is at that field; a second click raises, no third window; the target reads back by name |
| 3 | **OK and Cancel** (D4): the write by name, the close from the popup's own click, the form laid out again in place. | small kant, plus one small C++ command (redraw a form's window in place, no raise); closing a window from its own click is not measured | offscreen: OK changes the form's page by value, Cancel leaves it equal pixel for pixel; both leave one window |
| 4 | **The popup belongs to its form** (D5, D3, D7): closes with it, sits above it, `modal`, no resize. | small C++ in guiHost.mm (an owner in the window's record) | offscreen: closing the form leaves no window; a click on the form under a modal popup fires nothing and says so |
| 5 | **`popup:=aForm` as an attribute** (D1b), and the first customer: the colour description popup on colorList. | small, kant only | offscreen: a point in a poured row opens the popup showing that colour's words |
| 6 | A run watched by Tony. | | Tony's eyes |

Strokes 0 to 5 need no visible window. The colour popup proper waits on lighten / darken; the text-editing popup
waits on keys.

## 5. Not measured, and what would measure it

- Closing a window from a click inside it (windowClose called by the popup's own OK action): one offscreen run.
- Whether a window opened at a frame partly off the display is moved onto it by AppKit or must be moved by us.
- Whether a child window that is never shown behaves as a shown one does (stroke 4's offscreen proof depends on it).
- An open popup under `GCSTRESS`: each window holds its form in its own cell, so no new question is expected; not run.
