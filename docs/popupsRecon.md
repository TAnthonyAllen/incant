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

- The outline over a held form (SEQ 765, bought and merged 2026-11-23): a selected field that holds a form has
  its border drawn once more after its members. formsPop windowClimbT C-3o.

- Stroke 2 (SEQ 766, bought and merged 2026-11-23): `popup(request)`, form:= the popup form and on:= a field of a
  laid-out copy. It opens under the field's bottom left, every time. WHERE IT REMEMBERS: `popupTargets` in utilities, by
  the popup form's name, holding form=, field= and each= as NAMES -- names because the clicked copy is thrown away at
  the next layout and a value goes back by name; by the popup form because one popup form is one window; in kant so OK
  and Cancel read it without a door into the window code. Cleared when the popup closes. Not built: moving a popup that
  would fall off the display back onto it. formsPop windowPopupT.

- Stroke 3 (SEQ 768, bought and merged 2026-11-24; both choices below stand as built, Tony): `popupPick`, `popupOk`, `popupCancel` in utilities, the
  shared click actions of a popup form, each handed the clicked field. popupPick keeps that field's text as the popup's
  value (in its `popupTargets` entry, so it goes when the popup closes); popupOk writes it as the TEXT of the field the
  popup was opened on, in the definition, found by name in FORMs, closes the popup, and has the form's window laid out
  again where it is (`windowRedraw`, the one new C++ command: no move, no raise); popupCancel closes and writes nothing.
  CLOD'S CHOICES, kept by Tony: the value is picked by a third action (ruling 4 names two); what is written
  is a field's text. Not built: a write to the poured member (each=), a value that is a colour or an attribute. A form
  file read under show cannot write `onClick:=popupOk` (Utilities is not searched at its define); it wraps the action
  in one of its own, as tabForm's tabClick wraps selectTab. formsPop windowOkT.

- Stroke 4 (SEQ 770, bought and merged 2026-11-24; modal=1 stands, a bare modal word is not wanted now; rider: a popup whose owner form is not in FORMs still opens, unowned, and says so by name -- windowOwnerT W-6): the popup belongs to its form. utilities' popup
  hands the window `owner:=` the form it was opened from (by name, FORMs); `guiHost.mm` keeps the owner's view and
  `modal` in the window's record. A window that closes closes its popups first, as Cancel. A popup's window has a title
  bar and close button and no resize. A popup form carrying `modal=1` stops its owner's clicks while it is open: nothing
  fires, the click line says so, a shown popup comes forward. A shown popup of a shown window is made its child window
  (above it, moves with it): that part is AppKit's, not reached offscreen, and is stroke 6's to see. `modal` is written
  `modal=1`, as title= is written: a bare word on a form's line is not an attribute unless defined. formsPop windowOwnerT.

- Stroke 5 (SEQ 775, 2026-11-25; bought and merged 2026-11-25): `popup:=aForm` as an attribute. clickFire
  opens a held form under the name popup as a popup, at the cell that was hit; it ends the climb as an action does, so a
  click on anything under the field that fires nothing itself opens it. WITH TONY'S TWO OF 2026-11-24: every action a
  click fires is handed the cell that was hit, not the level that fired; a poured cell carrying a write-back address is
  selectable even when it shows nothing. THE LINK: popup() reads the hit cell's pour address when it opens and keeps it
  in its target as names (kind, source, entry, make, why); popupOk writes through it with pourWrite -- the source entry,
  the text alone, a missing description made and said so -- and a read-only cell says so with its reason; a field in no
  poured row is written as stroke 3 writes it. Cancel through the link writes nothing. A popup's laid-out copy carries
  `each`, the member it was opened on (found by name in the row's registry at every layout), so the popup form's own text
  may say `{each.taG}`, `{each}` and `{aRegistry.each}`. THE CUSTOMER: colorList's clRows carries `popup:=colorWords`; a
  click in a row shows that colour's name and words, OK closes it. Nothing in colorWords can be picked, so its OK writes
  nothing: changing the words waits for keys. formsPop popupAttrT, 12 rows, five H7s.
- The follow-up (SEQ 776, 2026-11-25; on branch popups-selectable, Tony buys; his two rulings of 2026-11-25): a field
  carrying only popup:= is selectable (selWhy popup); an entry of sTYLEs holding nothing (each, contrast, any
  placeholder) is read-only in a pour and refused by pourWrite by name -- virtual in Controls/styles, resolved when
  drawn, nothing stores it. Told by what the entry is, not by the virtual flag: the flag reads 0 on every loaded styles
  entry, and isVirtuaL has no read arm in opDot (both measured, with the arm added for the measurement and taken out).
  popupAttrT Q-6 re-pinned, Q-8 the negative control; pourWriteT W-9 new; pourAddressT A-12 back to 0. Two H7s.

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

- MEASURED (SEQ 768): closing a window from a click inside it is clean at GCSTRESS=1000, offscreen (windowOkT K-1, K-3 to K-5). A shown window has not been tried.
- Whether a window opened at a frame partly off the display is moved onto it by AppKit or must be moved by us.
- NOT MEASURED, by choice (SEQ 770): an unshown popup is not made a child window at all; closing with the form, modal and no resize are our record's and are proved offscreen. The child window (above, moves with it) waits for stroke 6.
- An open popup under `GCSTRESS`: each window holds its form in its own cell, so no new question is expected; not run.

## 6. Stroke 4b, the pour return link: part A, read only (SEQ 772, assigned by Clod, 2026-11-24)

Tony's ruled shape (2026-11-24) is in the dispatch: the source is the truth, the form a view; a write goes to the source
entry's member and the row is poured again; each poured field has a return address (source, entry by name, member); the
text alone is written. Read: `incant/utilities` (fillDownAcross, pourOpen to pourRowBuild, tsEachFind, typeset's inserts),
pourT, colorList. Measured where it says so (a scratch probe, two forms over a three-entry registry, real clicks offscreen).

**1. What pour knows today.** There are two kinds of poured row and they differ.
- A WRITTEN TEMPLATE ROW (stage 1; pourT): each copy of the row carries `each`, holding the source ENTRY ITSELF (not a
  name, not a position). The entry's registry is read from the entry (`registrY`). Measured: a click in the second row
  reads each beta, registry PrThree. The cells under the row carry nothing of their own; what a cell shows is in its
  TEXT, still as written when it is clicked (measured: `{each.taG}`, `{each}`, `is {each}!`), and typeset resolves it at
  the draw. An attribute holding each (fill:=each) is re-pointed at the entry and no longer says each.
- A DERIVED ROW (stage 2; colorList, stroke 5's customer): the row and its three cells are built from the entry and
  carry NO each (measured: each none). `pour` is taken off the field. pourName's text is the entry's name, copied;
  pourShow's is the entry's value, copied (or sample text for a font or a style); pourWhat's is dESCRIPTIONs' entry of
  that name, copied. So a derived row has no way back at all today.
- A click action is handed the level that fired (the row, or the poured field), not the cell; the cell is `selection`.

**2. Where the address should live.** Not a registry keyed by form and field: every poured row has the same field
names (ptRow, ptName; pourRow, pourName), so the key would need the entry's name too, and the registry would have to
be rebuilt at every layout or it goes stale when the source changes. The leak the Reference recon measured is a
DEFINITION's facts reaching its copies; this address is never on the definition. Lean: on the laid-out copy, where
`each` already is, written at every layout, as NAMES (source registry, entry) on the row, and per CELL where a cell's
source differs from its row's (pourWhat's is dESCRIPTIONs). Whoever must remember past a layout copies the names out,
as popupTargets already does with each=.

**3. One row again, or the whole form.** Nothing pours one row: every redraw is a fresh deep copy of the definition
laid out whole, and every click already does that. Measured: colorList (14 rows), 20 whole layouts through
windowRedraw, 0.17 s, about 9 ms each (layout only; offscreen nothing draws). Pouring one row would be new machinery,
and a row whose height changes moves every row under it. Lean: "poured again" is the whole form's redraw.

**4. What the write-back cannot reach.**
- the entry's NAME (`{each.taG}`, pourName): a rename, not a member write. Read-only.
- text that is more than one insert (`is {each}!`), and a font's or a style's sample text: computed. Read-only.
- a placeholder read through the look (pourShow, an empty sTYLEs entry): the value is the look's, not the entry's.
- an entry that is a rule or an action: pour never reads one (reading fires it). Read-only.
- `{aRegistry.each}` and pourWhat when that registry has NO entry of the name: there is nothing to write to. Refuse,
  or make the entry: Tony's.
- an entry's own attributes: `{each.X}` is read for taG only today, so no cell shows one.
- a pour inside a poured row: not measured.

**5. One stroke or two.** Two. B1, the address: template and derived rows and their cells carry it; one action answers,
for a clicked field, source, entry and member, or read-only and why; rows for each case in 4. B2, the write: by name,
the text alone, the errant cases (entry gone or renamed, a second form, Cancel), then the form's redraw; its own test,
no popup. Stroke 5's OK is then the first user.

**For Tony:** (a) the address on the copy, not in a registry (2); (b) poured again = the whole form (3); (c) a
description cell with no entry yet: refuse, or make the entry (4); (d) the read-only list in 4 as it stands; (e) the split.

**RULED (Tony, 2026-11-24, on part A):** (a) the address lives on the laid-out copy, not in a registry; (b) poured again =
the whole form redraws; (c) a description cell whose entry does not exist yet: B2 makes the entry and says so on the click
line ("made dESCRIPTIONs entry <name>"); (d) finding 4's read-only list stands, a pour inside a poured row is read-only
until measured, and a rename is not a write-back (a separate operation, later); (e) split into B1 and B2.

**B1 BUILT (SEQ 773, 2026-11-24): the return address.** At every layout a poured row and each cell that shows something
carry `pourSource`, `pourEntry` (names) and `pourMember`, or `pourReadOnly` and why, on the copy. A written row's cells are
read by their text as written; a derived row is told as it is built and now carries `each`, as a written row does.
`pourAddress(field)` answers "source S, entry E, member M", "read-only: why" or "not poured". Read-only reasons reached:
the entry's name; text that is more than one insert; text written in the form; a row; a rule or an action; a font's or a
style's sample text; a value read through the look; a pour inside a poured row. Also: a row's `each` is no longer read
through the look as a placeholder (resolveLook; a styles pour has an entry named each, and derived rows now carry the mark).
FOUND: a cell that shows nothing (a description cell with no description) cannot be reached by a click -- only room is not
selectable, and a click action is handed the level that fired, not the field that was hit. B2's "make the entry" needs a
way to that cell. formsPop pourAddressT, 14 rows.

**B2 BUILT (SEQ 774, 2026-11-24): the write.** `pourWriteAt(request)`, on:= a clicked cell and value=, reads the cell's
address and calls `pourWrite(request)`: source=, entry= and value= BY NAME, make=1 when the entry was not there at the
layout (the cell carries `pourMake`), form= the form to lay out again in place. The entry's text alone is written. A
read-only cell says so with its reason. Refused by name, nothing written: an entry no longer there (deleted or renamed
since the layout), no such registry, an entry that is a rule or an action, a field in no poured row, a request lacking a
part. A description with no entry yet is made, and the line says "made dESCRIPTIONs entry <name>". A second form pouring
the same source shows the old value until it is laid out again. formsPop pourWriteT, 10 rows.
NOT HERE: Cancel through the link (no popup in this test; windowOkT K-1 pins Cancel for the text write, and stroke 5's
OK is the link's first popup user); a cell that shows nothing is still not reached by a click (B1's finding).

## 7. Stroke 6, the watched run (SEQ 777, assigned by Clod, 2026-11-25)

Run `IncantForms/WorkingOn/tester` (Xcode with tester as the argument, or `~/bin/incant IncantForms/WorkingOn/tester`
from the repo root). Three windows: Colors (left), Watch A (middle), Watch B (right). Every step below was run
offscreen with real mouse-ups first and read as written; none had been seen in a shown window before this run.

| # | click | should be seen | covers | seen by Tony |
|---|---|---|---|---|
| 1 | Watch A: "Clicks counted: 0" | a mid-blue outline round it; the text becomes "Clicks counted: 1"; the help box at the bottom reads "waTally: counts the clicks it gets." | seal 539's outline and describe | |
| 2 | Watch B: "B one" | outlined in B; B's help box reads "wbOne: the first field of window B."; in A the outline stays on the counter and A's help text does not change | selection per form | |
| 3 | Watch A: the empty bordered box under the counter | nothing changes: no new outline, the counter keeps its outline, the help text stays | the only-room click | |
| 4 | Watch A: the words "text inside the held form" (yellow area) | those words are outlined, inside the yellow form | a click inside a held form | |
| 5 | Watch A: the empty yellow area under those words | the whole yellow form is outlined, the outline drawn over it; help reads "waHeld: this field holds another form." | the climb into a host; the outline over a held form | |
| 6 | Watch A: "Pick: click me" | a small window titled Pick opens just under that field, above Watch A, with no resize control | popup open | |
| 7 | drag Watch A by its title bar | Pick moves with it and stays on top of it | the popup above its form and moving with it | |
| 8 | Pick: "apple", then "OK" | Pick closes; the field in Watch A now reads "apple" | OK | |
| 9 | Watch A: "apple" (the same field), then Pick: "pear", then "Cancel" | Pick opens again, then closes; the field still reads "apple" | Cancel | |
| 10 | Watch A: "Modal: click me" | a window titled Modal opens under it | modal popup open | |
| 11 | Watch A: the counter, twice | the count does not change; Modal comes to the front | modal | |
| 12 | Modal: "Close", then Watch A: the counter | Modal closes; the count goes up by one | modal ends with the popup | |
| 13 | Colors: any colour's row | a window titled Color opens under the cell clicked, showing that colour's name large and its words; "OK" closes it | stroke 5's colour description popup | |
| 14 | Colors: midBlue's row, in the empty space right of its swatch | the empty cell is outlined and Color opens with the name midBlue and no words | the empty addressed cell | |
| 15 | open Pick again (step 6), then close Watch A with its close button | Pick closes with it | a form's close closes its popups | |
| 16 | close Watch B and Colors | the program ends by itself | the loop | |
