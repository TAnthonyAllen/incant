# HWF on Documentation Strategy — Session Summary

*Written 2026-05-09 by Clay (Claude at claude.ai). For the resurrection-reader: this is a session summary of an HWF discussion between Tony and Clay, captured so future-Clay can pick up the thread without having to re-derive what was settled. Not yet promoted to HWF.md or projectBible.md — Tony will fold it into formal documentation when the form work is ready to commit.*

---

## Origin

Session opened with Tony's bottom-line concern: *"I do not think we are getting adequate return on our HWF work, which I find helpful and valuable."*

Initial framing was "fix HWF." That framing was wrong. Tony reframed mid-session:

> *"I want to maximize the return on our HWF efforts and include HWF in a documentation strategy that currently does not exist. The point I want to get to is be able to generate documentation in incant. ... The ability to do it from incant means if we want to change how documentation looks or how it is generated, that becomes an incant problem and I want incant to be able to handle it. That way what the documentation looks like is just an incant `printDocument()` action."*

The real goal: **all project documentation generated from incant data, with HWF as one input among several.**

---

## The Reframe (Settled)

The destination is incant-generated documentation for the entire project — code documentation, HWF session records, projectBible.md, TODO.md, CLAUDE.md per repo. All of it.

Today's markdown files are source-of-truth. In the destination state, the source-of-truth becomes incant data (GroupItems with documentation-bearing fields), and the markdown files become *output* produced by `printDocument()` walking the incant data.

Implications:

- Editing the bible becomes "modify the incant data" rather than "edit projectBible.md."
- Cross-repo mirroring becomes a property of rendering rather than a Clod chore.
- Resurrection-readers consume rendered output, not source markdown.

The Javadoc model is one renderer (`printJavadoc()`), not the model. `printJavadoc()`, `printBible()`, `printHWF()` are siblings — all walking the same documentation data, each shaping output for their target.

---

## Bootstrapping Reality

Incant doesn't currently have:
- A working `printDocument()` action
- A `documentation` field design
- Rendering machinery

The documentation we'd want to generate in incant is the documentation we'd use to define those things. Same bootstrap pattern as PLG and TAWK.

The way out: work in markdown until incant can render, then migrate. Markdown stays live until incant produces equivalent output, then markdown becomes derived output rather than source.

This is a multi-session arc, parallel to or after Phase 3 (Incant bytecode/JIT).

---

## Architectural Decisions (Settled)

Three pokes during the discussion. Tony's answers settled them.

**Decision 1: Each attribute knows how to render itself.**

Originally framed as "where do rendering decisions live?" Tony's answer: each attribute has rendering behavior loaded from a registry specific to the current target. Print machinery just invokes; the renderer is loaded as a registry before printing.

Open for extension via new registries. A TeX renderer is "load TeX registry, print." HTML renderer is "load HTML registry, print." Bitmap renderer (long-game, see below) is "load bitmap registry, print." printDocument()-the-action is target-agnostic.

The renderer registries are themselves incant data — findable, readable, modifiable. The system documents itself.

**Decision 2: Style = bundled field of attributes.**

A style is a field whose contents are a bundle of rendering attributes. To apply a style: add it as an attribute on the target field. Cut-and-paste of styles across documents becomes trivial (it's just attribute application).

Structurally identical to a "field with attributes" — a style isn't a different kind of thing, it's a reusable bundle.

**Decision 3: Incant attribute merge handles cascading.**

The existing incant attribute-merge feature handles style layering. Field-specific attributes override style-provided attributes. Most recently specified style is the "current" default. Multiple styles can apply; ordering rule is deterministic.

This is CSS-cascade in pure incant terms, using mechanism that already exists. No new subsystem.

---

## Rich Text — Resolved

Rich text is *not* a new subsystem. It's existing-incant doing what existing-incant does, applied to text content.

A piece of styled text is a GroupItem. Content is the text plus child GroupItems for sub-spans. Style attributes (bold, italic, font, size, color) live on the GroupItem. Renderer walks the tree, asks each attribute to render itself, combines via existing attribute-merge.

A document is a tree of these GroupItems with layout attributes (`across`, `down`, percentages — same vocabulary as the existing XML/incant windowing system) determining arrangement.

**Tony's framing of this, verbatim:** *"In incant text is wrapped in an incant field, which can have attributes like bold, italic, font, whatever. When the incant print command gets `print field;` it has to know what to do with those attributes (if the attribute has a method or action, fire it and print the result. print already does that). Then a document is just a set of such fields."*
        Worth pointing out here that print does not deal w/fields that are really a hierarchy of fields. Will have to enhance print to do that.

---

## XML File Walk-Through (Context)

Tony walked Clay through two XML files (`simple.xml` and `inspector.xml`) from his existing windowing system, plus the `setFrame` incant action that handles layout.

These files use the same attribute model that documentation will use:
- Direct values (`fill=paleGray`)
- Registry references (`fill=wall` → looked up in current registry)
- State-conditional attributes (`fill=paleGray` + `selectFill=wall`)
- Deferred computation against context (`width=50%`)
- Cross-references (`text=one`, `next=inspector`)
- Code-bearing attributes (`onLayout` with code block)

Lesson: **the attribute-resolution model already exists and is general.** Documentation rendering inherits all four flavors of attribute resolution from the existing system. printDocument() doesn't need new layout machinery — it uses the existing layout machinery to arrange text.

The `setFrame` walk-through (across/down handling, percent computation, parent-context defaults) showed POP-tested layout already works. Tony: *"The structure is sound."*
    Current version of setFrame defines something akin to an Apple View/Frame. It could be applied to a page, a part of a page, a window/panel/pop up window, a form, or an entire document (altho that has not been tested)

---

## The GUI Long Game (HPDL)

Tony's dream: incant runs on multiple OSes, including phones. The GUI strategy is to **render incant documents to a bitmap, ship the bitmap to a thin presentation surface, accept events back, refresh on update.**

Pattern has a name (display server / immediate-mode rendering). Prior art: Flutter, game engines, X11, browser canvas apps.

Tradeoffs registered: accessibility is harder, native look-and-feel is impossible by design, text rendering is genuinely hard cross-platform, performance needs dirty-rectangle optimization, input handling has subtleties.

Mitigations identified: macOS first means Core Text first — Apple already wrote the text-to-bitmap methods. iOS as natural follow-on (same Core Text). Cross-platform is the long-term hard part; HPDL.

Implication for current documentation work: **don't bake the renderer's output target into `printDocument()`.** It's already designed as renderer-agnostic per Decision 1, so this just means honoring that. Today's renderer-of-the-day produces markdown. Tomorrow's produces HTML. Eventually one produces bitmaps for the macOS presentation surface. printDocument() doesn't change.

---

## Smallest First Step (Decided)

Three candidates were considered:

- **A:** Pick v1 attribute vocabulary and first renderer target.
- **B:** Hand-translate one existing markdown document (HWF.md) into the incant documentation field representation.
- **C:** Design the gate form for HWF list additions ("you wanna add a topic, fill in the boxes").

Tony chose **C**. Smallest, most concrete, immediately useful. Produces an artifact (the gate form) that gets used the next time someone wants to add an HWF topic.

A and B are deferred follow-ons, not abandoned.

---

## Phase Plan for the Gate Form Work

**Phase 1 — Draft the form.** Tony writes a first-cut markdown sketch. Field names, required vs optional, free-text vs structured. Seed: original outline (title, description, why-and-fits-overall-plan, issues with how-each-addressed, ecosystem affected, what's done, what's not done, implementation plan). Output: half a page to a page.

**Phase 2 — Test on three real HWF topics.** Apply the form to:
1. HWF Session 1 (isCLAUDE) — exists in active-discussion form in HWF.md.
2. HWF on HWF (this very session, the conversation Clay and Tony just had).
3. HWF on Printing/Display — Tony's originally-wanted topics not yet started.

Three different session colors: in-flight, just-had, not-yet-started. Strong test of the form's coverage. Paper-only — incant rendering test waits until incant is back up (post-TAWK Revival, "just what we need to run incant" subset).

**Phase 3 — Trim.** Tony shows Clay the form draft + three test fills. Clay registers what's missing, redundant, over-specified. Iterate the form in conversation. Result: v1 form ready to commit to HWF.md as the conventions section.

**Important design note Clay flagged:** the form does two jobs — gate (can't add a topic without it) and header (sits on the session once added). Same boxes serve both. Distinguish *required-at-add* fields from *fills-in-as-session-progresses* fields. Otherwise the gate becomes a barrier instead of a structure.

---

## Working Mode

Tony will do Phase 1 and the paper part of Phase 2 offline at his own pace. Clay does not need to persist the work-in-progress — Tony is keeping it in his own working file (currently a file called `flags`). When Phase 1 + 2 are ready for review, Tony brings them to a Clay session. Phase 3 happens in conversation.

The Phase 3 review session is where this summary becomes useful — future-Clay will need this orienting context to engage with the form draft productively.

---

## Where This Lands

After this session, with the gate-form work in flight on Tony's side and TAWK Revival continuing on the technical side:

- **Settled:** the documentation strategy reframe; the three architectural decisions; rich text approach; macOS/iOS rendering target priority.
- **In flight (Tony, paper, offline):** Phase 1 + 2 of the gate form.
- **Future sessions:** Phase 3 review of the gate form. Then v1 commit to HWF.md. Then incremental movement toward `documentation` field design and `printDocument()` action — gated on incant being back up.
- **HPDL:** bitmap renderer; cross-platform GUI; full Javadoc-equivalent code documentation; migration of bible/TODO/HWF/CLAUDE.md from markdown source-of-truth to incant-derived output.

The bigger arc: today's session was diagnostic and architectural. The next session is concrete (form review). The session after that begins the long migration of project documentation into incant.

---

## Glossary additions pending

Terms used in this discussion that may want HWF.md or bible/glossary promotion once stable:

- **gate form** — the structured-fields template that must be filled to add a topic to the HWF list. Same template serves as the session header in HWF.md once added.
- **renderer registry** — incant data structure holding per-target rendering instructions. Loaded before printing. Decision 1.
- **style as field** — a bundled set of rendering attributes, applied to text by attribute reference. Decision 2.
- **`printDocument()`** — the planned target-agnostic action that walks documentation data and produces rendered output via the current renderer registry.
- **`documentation` field** — the planned field type on GroupItems carrying structured documentation data. Central design question, not yet detailed.

---

*End of summary. Resurrection-reader: if you need more context, the source is the conversation between Tony and Clay on 2026-05-09 (Saturday). The TAWK Revival session work in TODO.md is the technical track this documentation work runs alongside, not on top of.*
