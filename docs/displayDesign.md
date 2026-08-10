# DISPLAY DESIGN — source → form → attributes → target

**Drafted Clay, ruled Tony, 2026-08-10. Recorded via SEQ 29.**

**Provenance.** Design session in Clay chat, the same day as the two-doors ruling and sharing its
signature: **safety and structure by construction, not by guard machinery.** Tony's earlier
GUI→HTML work is prior art and existence proof for the no-CSS emission model.

⚠ **Independently convergent with the 2026-08-06 Display ruling** (*"context + one style slot + pen
+ measure, typeset is a pre-pass"*): **§3's current style is that slot, §6's measurement is that
measure.** Two design passes, different entry points, same architecture — **checked, not assumed**
(Clod, SEQ 30).

---

## §1 The pipeline

Write text into a **source** → a **form** reads from the source → the form's **attributes** format
the text → output goes wherever the form **targets**.

Four stations, all GroupItem populations in one tree:

| station | what it is |
|---|---|
| **content** | source fields |
| **structure** | the form |
| **presentation** | style attributes |
| **medium** | target parameter |

The separation that CSS, XSLT and TeX each reinvent as a separate glued-on language **exists here
natively** — which is why no target ever needs a style language of its own (§5).

---

## §2 Display, akin to Buffer

`Buffer` accumulates text; **`Display` accumulates formatted intent and owns translation to a bound
target.** The **form** is the unit; the **target** is a parameter — *"print form to HTML."* One
form, N targets.

**POPable claim from day one:** the same form printed to two targets disagrees in **medium only,
never in content.**

---

## §3 The stream model — RULED (Tony)

**Output is a forward-only stream, not a scope tree.** Three tiers, and **no scoping anywhere**:

1. **Named styles** — the only thing that changes stream state. A named-style set **replaces the
   current style wholesale** (absolute, not delta). A style sheet is a GroupItem group of named
   bundles, defined once and referenced by name. **Every named set is a sync point:** the current
   style at any point is the last named set, with no replay.
2. **Current style** — stream state owned by `Display`. A set is **permanent until the next set**.
   ⚠ **No restore exists, by construction** — no `restoreLocalFields` analogue, no bracket, no
   seam. Forward only.
3. **Field explicits** — a field's own attributes **merge over** the current style for that field's
   rendering only; ephemeral, never written back. **An explicitly-bold field does not bolden the
   stream.**

**Anonymous incremental sets to stream state are disallowed.** Misordering damage is therefore
bounded to the next named-style anchor.

---

## §4 Rationale for §3

- **Raw deltas** make state the residue of history — you must replay to know it, and it is
  order-fragile.
- **Save/restore** is door one's bracket in costume, and its failure class is **measured SEQ 27,
  commit `168453d`** (`CLAIM KANT-8`, `docs/kantCorpus.md`).
- **Parent-hierarchy walk** rejected: query-per-read cost, and it couples rendering to tree
  position, so **moving a fragment changes its print**.

**Named-style anchors** buy: one-lookup state · bounded damage · a **censusable** style vocabulary ·
and a vigram-shaped claim — *"every referenced style name exists in the sheet"* — which is the same
class as decode lines.

---

## §5 Emission principle — RULED (Tony)

**Targets receive resolved output; style machinery never crosses the emit boundary.**

At emit, the named style merges with the field explicits and **each element goes out carrying its
resolved attributes inline**. **No CSS** — no stylesheet, no classes, no selectors. Position via
frame settings (`x`, `y`, `width`, `height`) as inline style; decoration as inline HTML-native
attributes.

**Cost accepted knowingly:** verbose output, repeated attributes. A non-cost for generated output,
and it buys **self-containment** — every element carries its full truth. Prior art: Tony's
GUI→HTML.

---

## §6 Layout ownership

**Kant owns layout; targets are paint surfaces differing only in paint protocol.**

**Measurement** — glyph widths for line-breaking, pagination — is **kant-side**, via the platform
text engine (Core Text; the runtime already lives where the measurer is). **No target is ever asked
to lay anything out.**

**Residual, accepted:** target rasterization may differ from Core Text by hairs; generous frames
absorb it.

---

## §7 Target ladder, in order

1. **HTML — the First Light target.** ⚠ **Scope fence (Tony): wiki-like static documents.**
   Emitted, resolved, **done when written** — no JavaScript, no event handling, no reflow loop.
   Pure §5 emission; exercises source / attributes / target **without geometry pressure**. Lands
   directly on the documentation work: **docs printed to HTML is Display's first customer.**
2. **Window — the interactive surface.** Live events, resize → reflow → repaint, drag-and-drop and
   whatever else: that machinery belongs **here**, sorted as we go. Beachhead exists
   (`Layout`/`Stylish`, `displayFill`).
3. **Print / typesetting** — full measurement, pagination. §6 already places the measurer
   kant-side, so **this rung inherits its hard question pre-answered.**

---

## §8 Parked note — the event conduit

When the window/interactive territory is taken up: **events crossing surface → kant is the minimal
stem-cell form of the web-channel item** (serve output, receive events, loop). Throttling live-drag
event rates is a knob to set then.

Recorded here so the connection is not rediscovered. **No bearing on the HTML rung.**

---

## §9 Scope fences

**`Display` is output-only**, as `Buffer` is accumulation-only. Input handling is **form logic**, a
different station.

**Open, unruled:**

- **(a) Based-on style chains** (`Heading2 = Heading1 + deltas`) — permissible **only as
  definition-time resolution when the sheet loads**, never render-time. ⚠ **Tony rules whether it
  is wanted at all.**
- **(b) Whether any attribute class is non-inheriting** across named-style replacement (page-level
  vs. run-level vocabulary) — decidable when the attribute vocabulary is drafted.
