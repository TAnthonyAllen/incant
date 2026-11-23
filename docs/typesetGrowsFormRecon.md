# Typesetting modifies its form: recon (SEQ 761, assigned by Clod, 2026-11-23)

The resurrection dispatch, piece 3 (Clay, ruled by Tony, 2026-11-23). Tony's idea: when a pour does not fit,
typesetting changes the form it runs in (grows a field, adds a continuation field or a page) and layout runs again.
Read only. Documents only: this file and a pointer in `Topics/typesetting`.

**Every fact here is READ on trunk at seal 539, not run.** Read: `incant/utilities` (setFrame, fitHeight, pourPlan,
frameMembers' noRoom, drawText, typeset), `GroupDraw.twk` drawSpans, `Topics/typesetting`, `Topics/features` 33 and 34,
`Topics/forms` (SIZE). Size assumed where one matters: the page, 490 x 792, and for a window the display's usable height.

## 1. Today: the wall

1. **Layout never sees text.** setFrame works on a deep copy in this order: pourPlan, fitHeight, mergeStyles, the
   picks, frameMembers. Every frame is final when it returns.
2. **Text is first measured when it is drawn.** drawText (the draw walk) resolves the font, calls typeset, and hands
   drawSpans the request. drawSpans breaks lines inside the frame it is given, draws the lines that fit, cuts the rest
   and warns by name.
3. **Nothing comes back.** drawSpans knows how many lines it drew, how many characters of how many, and what follows
   the last drawn word (its stdout line says so), and writes none of it into the request. It refuses a field with no
   display, so it cannot be asked before a draw.
4. **`height=fit` adds up declared heights only**, on the top field only; a member with no height sends it to the cap.
   A poured row is a fixed 24 points.

So "text measured before frames are final" is the one wall, and fit (features 33) and wrapping rows (34) both name it.

## 2. What layout and the floor need

| piece | what | where | size |
|---|---|---|---|
| A. measure without drawing | drawSpans takes the same request with no display, draws nothing, and writes back: the height all the text needs at this width, the lines and characters that fit the frame, and where it stopped. One line-breaking loop for both, so what is measured is what is drawn. No new floor method (features 33's reading stands) | `GroupDraw.twk` drawSpans | small C++, a rebuild |
| B. the text half of drawText, callable from layout | resolve the field's font and the rest, run typeset, fill the request: today this is inside drawText and only the draw walk calls it | `utilities` drawText | small, kant |
| C. the layout context | typeset resolves a run's font through the look of the last layout (F-158), and a font changes every width. A measure inside layout must use this layout's look, so popups stroke 0 comes first. The context then also holds what this recon adds: the wishes, the pass count, the pour cursor | `utilities` | stroke 0, then small |
| D. the passes | after frameMembers: measure every text field that may change; each that does not fit records a wish (this field wants N points more); apply; lay out again; stop when no wish is new or the pass count is spent, then cut and warn by name as today | `utilities` setFrame | medium, kant |
| E. a draw that starts part-way | for flow and pages only: the request carries where to start (the "where it stopped" of A) | `GroupDraw.twk` drawSpans | small C++ |
| F. a second page | for pages only: the PDF is opened for one page today (redrawForm's pageReq) | `GroupDraw.twk`, `utilities` | not sized |

**How a pass applies a wish (Clod's lean).** Not by editing the laid-out copy and running frameMembers on it again
(whether frameMembers gives the same answer on a copy it has already framed is not measured). Instead: wishes are kept
by field name in the context, and each pass is a fresh copy of the definition with the wishes applied before
frameMembers, exactly as a resize is a fresh copy with a frame applied. The definition is never written, the same
state gives the same answer, and a wish can only grow, so the passes must end.

## 3. What each customer gets

| customer | gets | needs |
|---|---|---|
| **fit** (features 33) | a text field written `height=fit` takes the height its text needs at its width; the top's `height=fit` then adds real heights up, to the cap (SIZE: a bigger form first) | A B C D |
| **the help box** (windows TO DO 3) | the first small case of fit: describeHelp grows to hold a long description | A B C D |
| **wrapping rows** (features 34) | a row is a field laid across; its height is the tallest of its cells' needs, so the cells share it and the rows below move down. Poured rows (24 points today) the same | A B C D |
| **flow** (typesetting step 4) | text that does not fit goes on in the next frame: a field the form names as its continuation, or one typesetting adds (a copy of the field, below it or on the next page) | A to E |
| **pages** (step 5) | when the form is at its cap and text is left, a page is added: another copy of the page's fields, the pour going on from the cursor. The two-line rule needs the measure to give lines by paragraph. In a window, pages are next / previous (SIZE) | A to F |
| **float** (step 8) | does not change the form. It needs the measure to break lines round keep-out boxes (a width for each line), and the float's frame known before the text beside it is measured. It rides on A, with one more input | A, extended |

## 4. Clay's proposed bounds, read against the code

| bound | reading |
|---|---|
| one direction only: grow or add, never shrink within a pass | fits: with wishes that only grow, passes end. A field that grew and then finds itself with room is left as it is |
| a fixed number of passes, then cut and warn by name | fits: cut and warn by name is what drawSpans does today, so the last pass is today's behaviour. The number is Tony's; Clod's lean is 4 |
| changes land on the laid-out copy, never the definition | already how setFrame works; the fresh-copy pass above keeps it |
| the pour gives the same answer for the same state | holds today: typeset reads the text, the styles, the look and the inserted fields, nothing else. A field whose action produces text is ruled the same way and not built |
| the layout context first | yes, and for a concrete reason: the look decides fonts, fonts decide widths (C) |

Three more, for Tony:
- **Opt in.** A field changes only when it says so (`height=fit`, a continuation, a page rule); every other field is cut and warned as today. Nothing grows silently.
- **Height only, to begin.** A grown width changes every line break under it.
- **A new layout starts from the definition.** Wishes are not kept from one layout to the next, so a wider window gives a shorter field by itself.

## 5. Decisions that are Tony's

1. The bounds in section 4, and the pass count.
2. Opt in, and what the opt-in is called for a text field (`height=fit` is the lean: it is the word the top already uses).
3. In a window: a form that grows at its first opening sizes its window (it does today for `height=fit`). After the
   user has resized the window, does a growing form resize it again, or is the text cut and warned? Lean: cut and warn; the window's size is the user's.
4. Flow's continuation: named by the form, added by typesetting, or both.
5. The order of customers. Lean: fit on one text field (the help box), wrapping rows, flow, pages, the float.

## 6. Smallest first step

**Step 1: the measure, alone.** drawSpans measures with no display and writes the answer into its request (A), and
drawText's text half becomes callable (B). No form changes. Proof with nobody watching: for firstLight's words at
three widths, the measured height drawn at exactly that height draws every character, and one point less cuts the last
line; the measured lines equal the drawn lines; H7.

**Step 2: `height=fit` on one text field**, one extra pass (C and D at their smallest), after popups stroke 0.

## 7. Not measured

- What one layout of a real form costs, so what four passes cost (Tony's note: probably fast enough, even interpreted).
- Whether frameMembers gives the same frames on a copy it has already framed (the reason for the fresh-copy lean).
- Whether Core Text gives the same line breaks with no drawing context as with one (step 1's proof is that measurement).
