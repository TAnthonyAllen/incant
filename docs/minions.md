# Minion Architecture — Brainstorm & Design Vision

*Captured: late night session, June 28 2026*  
*Status: design seed — not yet scheduled, ready to pick up when the time comes*

---

## The Core Idea

The Anthropic AI "wakes up fresh" every session. Our `.md` resurrection files are a good start, but this vision takes it further: instead of Claude hunting for context cold, **specialized minion agents hold pre-digested, continuously updated knowledge on specific domains**, and deliver it instantly on demand.

Tonto dispatches scouts for parallel recon. When they return, the relevant **Igor minion** for that domain absorbs the report and updates its standing knowledge. Clay, Clod, or Tony can then query the minion and get a deep, current answer — not a cold reconstruction.

---

## The Minion Roster

### Igor Minions (Domain Experts)
Each Igor minion owns a specific task domain. They accumulate scout reports, synthesize them, and serve as the standing local authority. Examples:

- **JIT Igor** — everything about the JIT compiler: current phase, decisions made, open questions, next steps
- **GUI Igor** — IncantForms, bigify/reBigify, Layout, displayText, live-resize state
- **Grammar Igor** — parser rules, PLG, ANYorNum/isAltRule issues, grammarOnTheFly
- **FileBoss** — (see below, a special-purpose minion)

### FileBoss Minion (Infrastructure Guardian)
Invisible redundancy manager. Three-copy rule: local primary, local backup, cloud/network sync. FileBoss knows the health of each copy, checksums them, and reroutes transparently if one goes down. The user never sees a file path or a failure. If system A goes down, FileBoss switches to B silently.

### GUI Minion (IncantForm Drafter & HandHolder)
When a user wants to build or modify an IncantForm, GUI Minion guides the process conversationally. Flow:
1. User expresses intent in plain language
2. **Sensei** asks 3–5 clarifying questions (Midjourney style) to surface what the user *really* needs vs. what they literally said
3. GUI Minion drafts the IncantForm
4. User refines via conversation
5. FileBoss saves it — user never touched a file path or syntax rule

### Sensei (Expert Prompter Personality)
Layered over the whole system. Translates vague user intent into precise incant. Thinks like an expert prompter — the way a good Midjourney prompter coaxes a model toward the right image. Sensei is the interface between the non-technical user and the incant substrate. Sensei asks; the minions deliver.

### Tonto's Scouts (Parallel Recon)
Already established pattern. Dispatched for parallel information gathering. Return reports are routed to the appropriate Igor minion for absorption and synthesis. Scouts are ephemeral; Igor minions are persistent.

---

## The "Pie in the Face" Wakeup Protocol

Current state: `wakeup.md` gives a cold briefing that Claude has to integrate.

Target state: each Igor minion *is* the pre-digested briefing for its domain. You wake up, you get the **strawberry rhubarb JIT pie** — here's where we are, here's what's decided, here's what's next, here's why. The flavor of the pie is the domain:

- JIT pie: current phase, green POPs, open tasks, standing decisions
- GUI pie: layout state, pending work, locked architectural choices
- Grammar pie: rule status, known issues, agreed fixes

The minion file is continuously overwritten as new scout reports come in. Wakeup = load minion file + role definition + inject as context. Instant expert resurrection.

---

## Minion Anatomy

A minion is three things:

1. **Role definition** — what domain am I expert in? What questions can I answer?
2. **Knowledge corpus** — what do I know so far? (continuously updated)
3. **Synthesis prompt** — how do I answer from this position?

In incant terms: a structured `.md` file per minion, living in the project support tree. FileBoss ensures these are always backed up and current.

---

## The Bigger Vision: incant as Invisible Substrate

Most users can't program. Can't manage files. Have no mental model of a file system. That's fine — they shouldn't need one.

With Sensei + GUI Minion + FileBoss, incant becomes the layer that handles all of it invisibly:

- User talks to **Sensei** in plain language
- Sensei interprets intent, asks smart questions
- **GUI Minion** builds the IncantForm
- **FileBoss** keeps it safe and redundant
- User never touches syntax, file paths, or app settings

This is the **Midjourney model applied to general computing** — not just image generation. Midjourney interprets a vague prompt and produces something close to what the user imagined. incant + Sensei does the same for *any computing task*.

Who needs a file system? Who needs a phone full of apps? The user has a conversation. incant handles the rest.

---

## What We Already Have

These primitives are already in place or in progress:

| Primitive | Status |
|---|---|
| `.md` resurrection files (`jit.md`, `gui.md`, `json.md`) | ✅ Active |
| Parallel scout pattern (Tonto recon) | ✅ Established |
| IncantForms (XML-to-incant conversion) | ✅ ~100 files converted |
| GUI framework (Layout, bigify, displayText) | 🔄 Active track |
| JIT compiler | 🔄 Phase 2 in progress |
| FileBoss redundancy layer | ⬜ Not yet built |
| Minion coordination layer | ⬜ Not yet designed |
| Sensei personality | ⬜ Not yet designed |

---

## What's Missing: The Minion Coordination Layer

The gap is the layer that:
- Defines minion spec (role, corpus, synthesis prompt fields)
- Routes scout reports to the right Igor minion
- Manages wakeup protocol (which pie to serve)
- Integrates with FileBoss for persistence and redundancy

**Suggested first candidates to specify:**
1. JIT Igor (most immediately useful — we're deep in Phase 2)
2. FileBoss (foundational — everything else depends on reliable storage)

---

## Next Steps (When We're Ready)

1. Draft the **minion spec** — what fields define a minion, what the file format looks like
2. Design the **scout-to-minion absorption protocol** — how recon reports get ingested and synthesized
3. Specify **FileBoss** redundancy rules (three-copy, checksum, failover trigger)
4. Design **Sensei** question flow for IncantForm elicitation
5. Decide: do minion files live in `support/` repo or a new `minions/` subtree?

---

*This doc is a design seed. Nothing here is committed or scheduled. It's captured so the idea isn't lost and so Clod, Clay, and Tony can pick it up with full context when the time comes.*
