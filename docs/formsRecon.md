# formsRecon — the drawing surface, measured

**KIND:** §1–§7 are recon — measurement only, no source edits in that pass. **§8 is DS**, the
drawing specimen, and it BUILT things; its own acceptance is stated there. The two are kept in one
file because the recipe in §8 is only readable against the table in §1, and splitting them would
put a claim and its evidence in different documents.
**Brief:** FR-0…FR-5 plus amendment FR-2a; then DS-0…DS-6 (Clay → Clod via Tony, 2026-08-06).
**Ran:** 2026-08-06, branch `jit-unified-emit-wip`.
**Corpus status:** first corpus file of the **forms minion** role. Written for a reader with **no
session context** (stage-1 durability) — whoever fires forms next inherits this table, not the
session that made it.

**Why this exists (FR-0).** Display/forms design would otherwise assume dispatch shapes. Unary
operators sat in the `isMethod`-not-`isOperator` hole from the 2026-06-30 unified-emit pivot until
2026-08-03 and **exited 139 rather than answering wrong**. This brief exists so drawing methods do
not repeat that. Every dispatch-route claim below carries its measurement site; they were grepped,
not recalled.

---

## 0. THE HEADLINE, and it changes what the design pass is for

**THERE ARE NO DRAWING FIELD METHODS. Zero. The count is not "few" — it is none.**

Nothing in the tree registers a drawing operation as an incant field method, by any registration
idiom (`immediateAction=`, `ruleMethod=`, `operateMethod=`, `interpretMethod=`, `unary`). The
drawing surface that exists is in two pieces, **neither of which incant can dispatch**:

1. **Objective-C++ view methods** on `class Layout extends View` (`Layout.twk`) — `displayCell`,
   `displayImage`, `displayText`, `drawRect`. These are Apple-side view methods, invoked by the
   Cocoa paint cycle, not by any incant walk. They are also written against the **subview** model
   (`NSTextField` / `NSTextView` + `addSubview`) that `docs/guiDesign.md` §10.1 explicitly
   **supersedes**.
2. **Unregistered C++ externs** in `Stylish.twk` and `GroupDraw.twk` — reachable from other C++,
   reachable from `Debug.rtn`'s POP tools, **not reachable from incant**.

**The two consequences worth carrying forward:**

- **The seed-gate trap family cannot bite today, because there is nothing in it to bite.** That is
  not reassurance — it means the trap is entirely in front of us, and §4 below states exactly which
  arm a drawing method will land on the moment one is registered.
- **Set/get colour and font are NOT greenfield.** They exist, they are written, and one of them is
  a known segfault. §2 has them.

**Method of the absence claim, because an absence is only as good as its search.** The names in §1
were each grepped across `incant/` (all 118 files) and across `--include=*.twk --include=*.rtn`
tree-wide, excluding the gitignored archaeology (`BackupIncant/`, `Aside/`, `BeforeRefactor/`,
`BeforeSave/`). The registration idioms were enumerated from `incant/setup` in full (lines 18–165)
rather than sampled. Two names returned hits and **both are false positives, checked by eye**:
`setColor` appears in `incant/jitAttrPop:13` inside a comment citing bear-trap #15, and `contains`
is an ordinary English word in six unrelated files.

---

## 1. FR-1 — THE TABLE

One row per candidate drawing/geometry/style method. "Dispatch route" is **the flags actually set**,
measured at the registration site; where there is no registration site the route is what the code
*is*, not what it could be.

| # | name | signature | defined at | registered at | dispatch route (flags) | interpreter-only vs jit-gated |
|---|---|---|---|---|---|---|
| 1 | `displayCell` | `void displayCell()` | `Layout.twk:18` | **nowhere** | ObjC++ **view method** on `class Layout` — no incant flags | **neither.** Not on any incant path; runs from Cocoa's paint cycle |
| 2 | `displayImage` | `void displayImage()` | `Layout.twk:46` | **nowhere** | as above | as above |
| 3 | `displayText` | `void displayText()` | `Layout.twk:64` | **nowhere** | as above | as above |
| 4 | `drawRect` | `void drawRect(Frame r)` | `Layout.twk:101` | **nowhere** | as above (`NSView` override) | as above |
| 5 | `invertY` | `Point invertY(Point point)` | `Layout.twk:125` | **nowhere** | as above | as above |
| 6 | `setWindow` | `void setWindow(GroupItem block)` | `GroupDraw.twk:21` | **nowhere** | plain C++ function, not `extern` | interpreter-only, and not even that — no incant caller |
| 7 | `containsPoint` | `extern int containsPoint(GroupItem, Point)` | `GroupDraw.twk:62` | **nowhere** | `extern`, unregistered | C++-callable only |
| 8 | `getFrame` | `extern Frame getFrame(GroupItem)` | `GroupDraw.twk:74` | **nowhere** | `extern`, unregistered | C++-callable only |
| 9 | `getTextView` | `extern TextView getTextView(GroupItem)` | `GroupDraw.twk:91` | **nowhere** | `extern`, unregistered | C++-callable only |
| 10 | `toString(Point)` / `toString(Frame)` | `String toString(...)` | `GroupDraw.twk:114,121` | **nowhere** | plain C++ | C++-callable only |
| 11 | `blockContaining` | `extern GroupItem blockContaining(GroupItem, Point)` | `Stylish.twk:53` | **nowhere** | `extern`, unregistered | C++-callable only |
| 12 | `contains` | `extern int contains(GroupItem, Point)` | `Stylish.twk:71` | **nowhere** | `extern`, unregistered | C++-callable only |
| 13 | `getColor` | `extern Color getColor(String name)` | `Stylish.twk:87` | **nowhere** | `extern`, unregistered | C++-callable only |
| 14 | `getStyle` | `extern Stylish getStyle(GroupItem)` | `Stylish.twk:103` | **nowhere** | `extern`, unregistered | C++-callable only |
| 15 | `indentFrame` | `extern Frame indentFrame(Frame, double)` | `Stylish.twk:122` | **nowhere** | `extern`, unregistered | C++-callable only |
| 16 | `indentFrameWH` | `extern Frame indentFrameWH(Frame, double, double)` | `Stylish.twk:127` | **nowhere** | `extern`, unregistered | C++-callable only |
| 17 | `setColor` | `extern void setColor(GroupItem)` | `Stylish.twk:136` | **nowhere** | `extern`, unregistered | C++-callable only. ⚠ **known segfault**, see §2.4 |
| 18 | `sHADOW` | `extern void sHADOW(GroupItem)` | `Stylish.twk:164` | **nowhere** | `extern`, unregistered | C++-callable only. Header says *"design required plus POP"* — uncertified |
| 19 | `setFont` | `extern void setFont(GroupItem)` | `Stylish.twk:196` | **nowhere** | `extern`, unregistered | C++-callable only |
| 20 | `getFont` | `extern Font getFont(GroupItem)` | `Stylish.twk:248` | **nowhere** | `extern`, unregistered | C++-callable only |
| 21 | `makeStyleFor` | `extern Stylish makeStyleFor(GroupItem)` | `Stylish.twk:262` | **nowhere** | `extern`, unregistered | C++-callable only |

**The only two GUI-adjacent names that ARE registered**, and they are both window lifecycle rather
than drawing — included so the table is not read as "nothing GUI is wired":

| name | registered at | form | dispatch route |
|---|---|---|---|
| `window` → `markWindow` | `incant/setup:62` | `window immediateAction=markWindow noPrint;` | command, `noPrint` definition attribute (define-time mark) |
| `openWindow` | `incant/setup:74` | `openWindow immediateAction=openWindow;` | command (explicit run-time raise; host in `guiHost.mm:26`) |

This is the **define-then-show** precedent `docs/guiDesign.md` §10.0 cites for the forms `window`
attribute instantiating a Display: `markWindow` marks at define time, `openWindow` raises later.
The precedent is real and it is two registrations, not a framework.

---

## 2. FR-2 — THE STYLE ROW

### 2.1 What a style IS today

`Stylish` is a **C++ class** (`Stylish.twk:6-47`), not a GroupItem. Its members:

```
String   styling                                          (:8)   the style's name
Shadow   shadow                                           (:9)
double   borderWidth, radius, transparency                (:10-12)
Color    bgColor, fillColor, strokeColor, textColor       (:13-16)
Font     font                                             (:17)
GroupItem shadowField                                     (:18)
NumberFormatter formatter                                 (:19)
boolean  editable, selected, selectable                   (:20-24)
```

### 2.2 What `setStyle` would cost today — **a pointer swap, already**

This is the FR-2 question and the answer is favourable:

- A GroupItem **already carries a Stylish through its `pointer` slot.** `makeStyleFor`
  (`Stylish.twk:262-284`) mints a `Stylish`, boxes it in a GroupItem's `.pointer`, files that under
  the `sTYLEs` registry, and attaches a `style` attribute to the field (`:280-282`).
- `getStyle` (`:103-114`) resolves by walking parents for a `style` attribute and then does exactly
  `styled = style.pointer;` (`:111`). **One dereference. No conversion.**

So **Display pointing at a style costs a pointer read**, and the translation-into-context-state
branch of FR-2's question does not arise at setStyle time.

### 2.3 Where translation DOES happen — and it is already once-per-entity, not per draw call

The design intent ("translation happens once at setStyle time, never per draw call") is **already
satisfied by a different mechanism than the one the brief anticipated**: components are realised
lazily and memoised on the **component GroupItem's `object` slot**, not on Stylish.

| component | source form | realise fn | memo slot | lazy accessor |
|---|---|---|---|---|
| colour | `"rrggbb"` hex text on a `cOLORs` entry | `setColor` (`Stylish.twk:136-158`) — `sscanf` × 3 → `rgbColor()` | `item.object` | `getColor` (`:87-96`), `if !isOBJECT setColor(item);` |
| font | `family` / `size` / `bold` / `italic` / `smallCaps` attributes on a `fONTs` entry | `setFont` (`:196-241`) — `NSFontDescriptor` → `NSFont`, 3-deep fallback chain | `field.object` | `getFont` (`:248-256`), `if !isOBJECT setFont(field);` |
| shadow | `blur` / `color` / `x` / `y` attributes on `shadowField` | `sHADOW` (`:164-187`) | `shadow` member | none — uncertified |

**Read that table as the good news it is:** the expensive Apple-side conversion is already
realise-once-and-cache, keyed on the entity, and `Stylish`'s `Color`/`Font` members hold
**already-realised Apple objects**. Whatever else changes, that shape should survive.

### 2.4 ⚠ THE THREE THINGS THAT ARE BROKEN OR ABSENT, stated so design does not assume them working

1. **NOTHING POPULATES STYLISH.** Already documented as `docs/guiDesign.md` §2 *"THE MISSING MIDDLE
   — style resolution (nothing populates Stylish)"*, and re-measured here: `makeStyleFor` mints a
   Stylish whose constructors, in the source's own words, *"just zeros out everything"*
   (`Stylish.twk:31`) bar `strokeColor`/`textColor` = black and `styling` = name. **No code path
   assigns `bgColor`, `font`, `fillColor`, `borderWidth`, `radius` or `transparency` from a form's
   attributes.** The cascade is designed and unbuilt.
2. **`setColor` SEGFAULTS.** `properties["hexSet"]` (`Stylish.twk:140`) null-derefs — CLAUDE.md
   bear-trap #15, and it *"still segfaults even under the full preamble"*; the real init path for
   that global is recorded as unknown. Anything that calls colour realisation hits this first.
3. **`sTYLEs` may not exist.** `makeStyleFor`'s own header says it *"Looks up styles in sTYLEs
   registry that does not exist yet"* (`:260`) and the code `cerr`s and returns an empty style if
   the registry is missing (`:268-270`). `cOLORs`/`fONTs`/`sTYLEs` are named only in comments and
   in `makeStyleFor`'s lookup — **no `registry(...)` declaration for any of the three was found in
   `incant/setup`**, which declares `bcOPs`, `pROPERTIEs`, `GroupFields`, `fILEs` and others.

### 2.5 Live readers of style components — the population Display inherits

Grepped tree-wide, excluding the `GUI/` fossil (§3): the **only** live readers of Stylish members
are in `Layout.twk` —

| reader | components read | site |
|---|---|---|
| `displayCell` | `fillColor`, `textColor`, `editable`, `selected` | `Layout.twk:31-36` |
| `displayText` | `bgColor`, `font`, `selected` | `Layout.twk:83-86` |
| `drawRect` | (calls `getStyle`, then uses a local `strokeColor`, not the style's) | `Layout.twk:105-108` |

**So the component set a first Display must actually serve is small and named: `bgColor`,
`fillColor`, `textColor`, `font`** — plus `editable`/`selected`, which are interaction state rather
than paint. `borderWidth`, `radius`, `transparency`, `formatter`, `selectable` and `strokeColor`
have **no live reader at all**.

---

## 3. FR-2a — STYLE-AS-GROUPITEM MAPPING

**Director's preference declared 2026-08-06:** a style is a GroupItem holding what Display needs as
conveniently placed attributes. It **holds; it does not behave.** The question below is the mapping
and what stands between here and there.

**The headline: the mapping is clean, and cleaner than the class listing suggests — because the
source of truth for every visual component is ALREADY a GroupItem.** `Stylish`'s `Color`/`Font`
members are *caches of realised Apple objects*; the authored form of a colour is hex text on a
`cOLORs` GroupItem and the authored form of a font is a `fONTs` GroupItem carrying
`family`/`size`/`bold`/`italic`/`smallCaps`. **Attribute position is where these things already
live.** The C++ class is the layer in the middle, and it is the layer that was never populated.

| component | current home in Stylish | authored form today | verdict |
|---|---|---|---|
| `styling` (name) | `String styling` (`Stylish.twk:8`) | set from `item.tag` (`:30,45`) or a name (`:38`) | **not an attribute — it is the TAG.** A style GroupItem's tag *is* its name; `makeStyleFor` already keys `sTYLEs` by that name (`:274-279`) |
| `bgColor` | `Color bgColor` (`:13`) | `cOLORs` entry, hex text + `.object` cache | **attribute-ready as-is.** Attribute names the colour entry; `getColor` is the existing realise-on-first-miss accessor |
| `fillColor` | `Color fillColor` (`:14`) | as above | **attribute-ready as-is** |
| `strokeColor` | `Color strokeColor` (`:15`) | as above; defaulted to black in both ctors (`:28,36`) | **attribute-ready as-is.** No live reader — the default is the only behaviour, and a default is expressible as an absent attribute |
| `textColor` | `Color textColor` (`:16`) | as above; defaulted black (`:29,37`) | **attribute-ready as-is** |
| `font` | `Font font` (`:17`) | `fONTs` entry — already a GroupItem with attributes | **attribute-ready as-is, and it is the strongest case in the table:** the authored font is *already exactly the shape being asked for* |
| `borderWidth`, `radius`, `transparency` | `double` (`:10-12`) | nothing authors them | **attribute-ready as-is** — number-valued attributes, trivial. No live reader; no migration, only creation |
| `editable`, `selected`, `selectable` | `boolean` (`:20-24`) | nothing authors them | **attribute-ready, presence-based** — same idiom `setFont` already uses for `bold`/`italic`. ⚠ carry `setFont:211-214`'s warning with it: *a bare flag has no data and would read as off on a value-check* — presence is the test, never value |
| `shadowField` | `GroupItem shadowField` (`:18`) | already a GroupItem read by `["blur"]/["color"]/["x"]/["y"]` (`:173-176`) | **already an attribute in all but name.** Needs no relocation — it needs `sHADOW` certified, which is a separate open item |
| `shadow` | `Shadow shadow` (`:9`) | realised from `shadowField` | **cache, not content** — same class as the realised `Color`/`Font`. Lives in the `.object`/pointer slot, not as authored content |
| `formatter` | `NumberFormatter formatter` (`:19`) | **nothing** — no reader, no writer, tree-wide | ⚠ **THE ONE THAT RESISTS — see below** |

### ⚠ 3.1 The one that resists attribute placement, named per FR-2a, and stopped at

**`NumberFormatter formatter` (`Stylish.twk:19`).** Every other member is either a value (expressible
as attribute text or a number), a name pointing at another GroupItem (already the idiom), or a cache
of a realised object (belongs in `.object`, not in authored content). **A formatter is none of
those: it is an Apple object with behaviour** — it *formats*, it does not *hold*. Its authored form
would be a format specification (a pattern string, or a set of attributes), and the `NumberFormatter`
would be the realised cache of that spec — which is the `getColor`/`getFont` pattern again and would
be perfectly clean.

**But that is a design ruling, not a recon finding, and this is where the brief says stop.** The
spec language is not chosen, nothing in the tree authors a format today, and `docs/gui.md:762`
records a legacy `format`→`fORMAT` handler in the archived material that would be the prior art to
read before inventing one. **Flagged, not resolved.**

### 3.2 What stands between here and there — the honest list

Nothing in the mapping blocks. The work is elsewhere, and it is the work §2.4 already named:

1. The cascade that populates a style from a form's attributes **does not exist** in either shape.
   Moving to GroupItems does not create it — but it does mean the thing being populated is a tree
   the walk can write with ordinary incant, instead of a C++ struct nothing can reach.
2. `cOLORs` / `fONTs` / `sTYLEs` have **no registry declaration** found in `incant/setup`.
3. `setColor` segfaults before it can realise anything (bear-trap #15).

**If the mapping is taken, FR-2's translation-step branch dies unmeasured** — which the brief names
as the best outcome, and it is the outcome. `setStyle` is a pointer swap; component reads are
attribute reads; the Apple-object realisation stays exactly where it already is, on the component
entity's `object` slot, keyed and cached per entity rather than per draw.

---

## 4. HOW A DRAWING METHOD WOULD BE INVOKED UNDER JITTING

This is FR-0's actual question, and since §0 establishes there is nothing registered yet, the answer
is stated as **what will happen the moment one is** — read as a prediction with its mechanism cited,
not as a measurement of drawing code, because there is no drawing code to measure.

`runOP` (`GroupActions.rtn:828`) is the dispatch hub. Its ladder, verbatim (`:869-875`):

```
    if op.isOperator    result = op.operat(arg,target);
    or op.isMethod      result = op.method(target);
    or isRule           result = runRule(arg,target);
    or actionType       result = runAction(arg,target);
    or isMethod {
        if !arg arg = target;
        result = method(arg); }
```

and the JIT operand seed gate immediately above it (`:857`):

```
    if jitting && (op.isOperator || op.isUnary) {
```

**The consequence, and it is the whole reason this brief was commissioned.** A method registered the
way every command in `incant/setup` is registered — `name immediateAction=name;` — is
**`isMethod` and NOT `isOperator` and NOT `isUnary`**. It therefore reaches the **last arm** of the
ladder, and **the seed gate above does not cover that arm**. Its operands are never seeded, so
`target->jitData` is null for anything downstream that reads it.

**That is precisely the shape that made unary exit 139.** And the narrowing is deliberate and
documented at the site (`GroupActions.rtn:848-856`): *"isUnary is the precise gate: widening to
isMethod would seed an operand for every rule method."* So **the hole is not an oversight to be
closed by widening — it was left open on purpose**, and a drawing method that needs seeded operands
needs its own answer, not a wider gate.

**Grading, per this project's standing asymmetry (structural claims hold, causal claims fail).**
The ladder, the gate, and the flag each command registration sets are **structural and grepped**.
The prediction *"a drawing method registered as a command will arrive at the last arm with unseeded
operands"* follows from them directly but is **not measured** — no such method exists to run. Treat
it as the lead to test first, with a one-fixture cost, not as a fact.

**The route that already works, and is probably the answer.** `jitFieldMethod`
(`jitEmitters.rtn:2506`, registered `incant/setup:84`) is the fallback column: compile-on-first-fire,
cache the compiled function pointer in `rStuff->jitMethod`, dispatch through the slot on every later
fire. Ladder rung **J7** certifies *"emit a call, GET A VALUE BACK, layout-free"*. **A drawing method
does not need to be emittable as IR** — it needs to be *callable* from emitted code, which is what
the fallback column is for. Design should assume drawing methods take that route until something
forces otherwise.

---

## 5. FR-3 — THE STYLISH FOSSIL FINDING (stated, not re-derived)

**The top-level pair is live. `GUI/Stylish.twk` is a March 2021 fossil.**

```
Stylish.twk       10680  Jul  2 15:01     <- live source
Stylish.mm        11748  Aug  4 09:45     <- regenerated
Stylish.h          1469  Aug  4 09:45     <- regenerated
GUI/Stylish.twk    8125  Mar  4  2021     <- fossil
GUI/Stylish.mm     2653  Jan 12  2021
GUI/Stylish.h          0  Jun  6  2021    <- ZERO BYTES
```

**The sweep hazard is unchanged and is already carried as an open item of Tony's** in CLAUDE.md
bear-trap #10's correction: `tokall` is a shell *function* whose entire body is
`for item in *.twk; do tok $item; done` — **top level only**. `GUI/` is never swept, so its
checked-in generated files are stale against every layout change since, in the silent way (compiles
clean, links clean, wrong at runtime). The same paragraph names `GUI/Layout.twk` and
`GUI/Stylish.twk` sharing basenames with the top-level pair as the unresolved part.

**For this recon's purposes the ambiguity is not real** — the dates settle which file is live — and
the `GUI/` hits were excluded from every population count in §1 and §2.5 on that basis. Recorded so
the next reader does not re-derive it.

---

## 6. WHAT THIS RECON DID NOT ANSWER, and whose it is

- **The formatter's authored form** (§3.1) — director's/designer's, flagged and stopped at.
- **Whether a drawing method takes the fallback column or wants IR emission** (§4) — design, and the
  recon's recommendation is the fallback column.
- **Where the style cascade lives** — the populate-Stylish gap (§2.4 item 1) is `docs/guiDesign.md`
  §2's "missing middle" and predates this brief.
- **`cOLORs`/`fONTs`/`sTYLEs` registry declarations** (§2.4 item 3) — measured absent from
  `incant/setup`; whether they are declared elsewhere at startup in C++ was **not** chased, because
  it is one grep away for whoever needs it and this pass was fenced at measurement.
- **`sHADOW` certification** — its own header asks for design + POP; unchanged.

**Scope fence honoured (FR-4):** the §4 seed-gate finding is a flagged row, not a repair. Nothing was
edited. This pass did not touch the `Parens` fire or the `generatedExit` work item.

---

## 7. FR-5 — ACCEPTANCE

**No source file was modified and nothing was rebuilt.** This recon was greps and reads only, so the
fleet cannot have moved: no `.twk`, `.rtn`, `.mm`, `.h`, fixture, target or harness was written.
`docs/guiDesign.md` gained a §10.0 (the GD insert, a separate item in the same relay) and this file
is new; both are documentation.

**Per RULE H1's spirit — the state this was measured against**, so a later reader can tell whether
the tree moved underneath it:

```
branch      jit-unified-emit-wip
HEAD        ed8d308  SEAL 2026-08-05: KANT-8 buried, the campaign at its real question
dirty       IncantForms/WorkingOn/incant++   (Tony's working document, expected)
```

---

# 8. DS — THE DRAWING SPECIMEN, AND THE RECIPE THAT IS ITS PRODUCT

**asOf 2026-08-06 · confidence: MEASURED, both halves green · fixtures `incant/dsFill`
(interpreted) and `incant/dsFillJ` (jitted)**

`displayFill` fills a field's frame rect with the colour its style names, into a bitmap.
Nothing else. It was chosen because it crosses every seam exactly once, and the crossings —
not the fill — are the deliverable.

**⚠ IT IS NAMED `displayFill`, NOT `fill`, AND THAT IS BEAR-TRAP #17 RATHER THAN TASTE.**
`fill()` is declared in `~/data/support/Include/OCframe`, the **shared cross-project TAWK
keyword/alias table**. A bare `fill` gets silently claimed by that table the moment both are
live in one pass and mis-generates into an Apple selector, with no diagnostic until the C++
compile names an unrelated file. Grep any short drawing verb against that file before using it
— `line`, `text`, `clear` and `stroke` are all candidates.

## 8.1 THE FIVE-SEAM RECIPE — every later drawing command inherits these crossings

| # | seam | how, with the site | notes for the next command |
|---|---|---|---|
| 1 | **registration** | `define displayFill immediateAction=displayFill; ;` in the FIXTURE, not `incant/setup` | fixture-local on purpose: `incant/setup`'s registries are walked and baselined by `pop.sh`'s census, so a permanent entry is a baseline event. Same discipline `genParse`/`showParse` already follow |
| 2 | **dispatch route** | command → `runOP` (`GroupActions.rtn:828`) → its **last** arm, `or isMethod` (`:890`) | ⚠ **the seed gate at `:874` does NOT cover that arm.** FR §4 predicted exactly this and it held. It does not bite here because the emitted call passes a **baked node address**, not a seeded operand — a drawing command needs to be *callable*, not *emittable* |
| 3 | **style read** | `field["style"]` → its text names a colour → `getColor` (`Stylish.twk:87`) → `setColor` (`:136`) realises hex→NSColor **once**, cached on the colour node's object slot | **DS's opening measurement, answered: the slot hands over a NAME needing realisation, not a realised colour** — and the realisation is already once-per-entity, never per draw call |
| 4 | **Display write** | `CGContextSetRGBFillColor` + `CGContextFillRect` on the context in the node's pointer slot — `displayFillRT` (`GroupDraw.twk:204`) | the only line that differs per command |
| 5 | **jit-callable** | `displayFill` (`jitEmitters.rtn:2846`) gates on `jitting`; `jitEmitFill` (`:2819`) bakes the node address and `displayFillRT`'s address and emits ONE `CreateCall` of `GroupItem*(GroupItem*)` | a carbon copy of `jitEmitTrace`. That signature is the **fallback-column convention, verified against `runOP`'s own dispatch** rather than adopted from a design, so every drawing command can wear it |
| 6 | **what Display minimally is** (DS-6) | `makeDisplay` (`GroupDraw.twk:158`): a `CGBitmapContext` in the node's **pointer** slot, plus the node's `style` attribute as the current-style slot | **two of the GD ruling's four things. Pen and measure are absent by instruction**, not oversight |

## 8.2 DISPLAY, AS MEASURED — the seed the class brief inherits

- **It lives on a GroupItem and there are no statics.** The context goes in the **pointer** slot
  (`setPointer`), which is where `makeStyleFor` already hangs a `Stylish`. ⚠ **Not the object
  slot** — `setObject` is typed `NSObject*` and a `CGContextRef` is a CF type, so the object slot
  rejects it at compile time. Consequence: "the display" is an ordinary field you can pass,
  attach and look up, with nothing global to reset between runs.
- **The current-style slot is the node's `style` attribute**, read at draw time.
- ⚠ **NO Y-FLIP. Deliberate omission, and a debt named rather than hidden.** guiDesign §10.3 rules
  that Display exposes top-left/y-down and flips internally; this increment fills a rect it was
  handed and does not flip. The flip wants a frame height to be meaningful, which is layout's
  question, not this specimen's.

## 8.3 ⚠ THE RECIPE DOES **NOT** REPLICATE CLEANLY TO `line`, AND THAT IS THE FINDING DS-2 ASKED FOR

Seams 1, 2, 4 and 5 carry over unchanged — registration, dispatch, the one CG call, the emitted
call. **Seam 3 does not**, and the reason is structural rather than incidental:

**this specimen's style slot is DEGENERATE — the `style` attribute's text names a colour
directly, so the style IS one colour.** That is enough for `fill`, which needs exactly one, and
it is why the specimen could be small. `line` needs a **stroke** colour and would soon want a
width; `drawText` needs a text colour and a font. The moment a second component exists there is
nothing in this shape to distinguish them.

**So `line` is precisely where FR-2a's style-as-GroupItem stops being a preference and becomes
required:** a style node carrying named component attributes (`fillColor`, `strokeColor`,
`font`), with seam 3 reading a *named component* rather than the style's own text. **Do that
before `line`, not after** — one command is a cheap conversion and three is a migration.
Everything else on the recipe is ready.

## 8.4 BEAR-TRAP #15 IS FALSIFIED ON ITS COLOUR HALF (DS-3)

The trap records `setColor`'s `properties["hexSet"]` as a null-deref that *"still segfaults even
under the full preamble"*, with the real init path unknown. **It does not segfault.**
`hexSet=[0-9a-fA-F]` is defined in `incant/setup`'s `pROPERTIEs` registry and is present under an
ordinary `Start()`. Measured with `dumpColorRGB` (which existed in `Debug.rtn` all along and was
**never registered**, which is why nobody re-measured it):

```
    ff0000  ->  r=1.000 g=0.000 b=0.000 a=1.000
    008080  ->  r=0.000 g=0.502 b=0.502 a=1.000     exit 0
```

Correct parse, correct scale. **It is not in the specimen's path as a hazard; it is the path, and
it works.** The trap's *other* half — attribute-construction-then-dereference — was not exercised
and is untouched by this. Likely cause of the original failure, unproven: the trap's own fixture
built fields with no data, which is bear-trap #26.

## 8.5 WHAT THE TWO POPs ASSERT

```
incant/dsFill    interpreted   pixel (2,2)  r0 g0 b0 a0   ->  r255 g0 b0 a255
incant/dsFillJ   jitted        before       r0 g0 b0 a0
                               fire 1       r255 g0 b0 a255      compiled, style=djRed
                               fire 2       r0 g128 b128 a255    NO recompile, style=djTeal
                                            degrade 0, compile 1, jitRunAction entered
```

**Fire 2 is the whole proof.** Under jitting the interpreter executes an action body for real at
emit time, so a correct pixel after one fire proves nothing — the emit-time pass could have
painted it. Fire 2 recompiles nothing and its pixel tracks a colour changed **after** emission,
so the fill ran from compiled code. The two fires want **different** answers, not merely
different inputs.

**The before-row is paired on purpose:** `r0 g0 b0 a0` is also what a bitmap nobody drew into
gives, so alone it asserts nothing. Every zero-expecting row has a non-zero sibling.
