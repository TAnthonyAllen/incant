# Vision Recon — Consolidated Inventory

*Tonto Vision Recon, 2026-06-28. Four scouts (HWF / CLAUDE+TODO / projectBible / docs).
Read-only — nothing was touched. Compiled by Clod for Clay's vision-doc drafting.*

Material answering **"what is incant FOR"** (not "how it works"), clustered by theme.
Each entry: file · location · what it covers · the fragment (verbatim short / key-phrases long).

---

## CLUSTER 1 — The North Star (ecosystem purpose)

- **projectBible.md** · lines 8–14 — The foundational WHY, the three-tool ecosystem in one breath.
  > "**PLG** finds the pieces … **TAWK** shapes the expression … **Incant** understands the meaning —
  > reflexive, homoiconic, stack-aware, self-describing. *PLG recognizes. TAWK transforms. Incant reasons.*"
- **Groups/CLAUDE.md** · line 10 · **Parse/CLAUDE.md** · line 13 · **Tokf/CLAUDE.md** · line 11 —
  The same "recognizes / transforms / reasons" positioning, restated in each repo's orientation.
- **projectBible.md** · line 302 — The implementation north star, stated bare.
  > "**The north star**: PLG written in Incant."

## CLUSTER 2 — Homoiconicity & the Three Collapses (what incant *is*)

- **projectBible.md** · lines 75–86 — Reflexive + homoiconic stated as *goals pursued*, not accidents.
  > "**Reflexive** — the language can examine and describe itself. **Homoiconic** — code and data have
  > the same structure. A GroupItem field IS the rule that describes it."
- **projectBible.md** · lines 101–103 — The one-shape claim made concrete.
  > "every value, every rule, every code block, every bytecode op is a GroupItem … only the one shape,
  > recurring at every level — which is what makes incant homoiconic in practice."
- **projectBible.md** · lines 296–302 — **The three paradigm collapses** that usually stay separate:
  match() ↔ parse() (recognition = semantic processing), code ↔ data, **grammar ↔ result**
  ("data structure IS grammar IS result"); `defer` promoted from callback convention to first-class keyword.
- **Groups/CLAUDE.md** · line 12 · **Groups/TODO.md** · lines 88–90, 195–196 — Homoiconicity as a
  *practical capability*, not philosophy: "transformation over source" = incant operating on incant;
  idempotent programming where "the artifact is derivable from source-plus-transformation."

## CLUSTER 3 — The Distributed Virtual OS & `isCLAUDE` (the long game)

- **projectBible.md** · lines 401–413 — The expansive future vision (the "phone full of apps" reframing):
  > "GroupItem fields are deployable units. Run anywhere. Message each other across platforms. Location
  > transparent. Claude is a GroupItem — `isCLAUDE` alongside `isSTRING`, `isNUMBER`, `isGROUP`. The AI
  > is not a tool called from incant — it IS a field in incant. … Go-style channel messaging … ZFS-flavored
  > storage … The JIT is the enabling technology. Without JIT, incant is an interpreter. With JIT, incant ships."
- **The recurring HPDL long-game list** — appears in **Groups/CLAUDE.md** (388–399), **Groups/TODO.md**
  (290–301), **Parse/TODO.md** (395–402), **Tokf/TODO.md** (290–301): Claude-as-field (`isCLAUDE`),
  distributed virtual OS, Go channels, ZFS storage, display/layout field, filesystem-as-GroupItems,
  PLG-in-Incant, JIT self-hosting, Xcode-like dev environment written in incant. *(Duplicated 4×.)*
- **HWF.md Session 1** · lines 136–140 — The `isCLAUDE` persistence model, mirroring the human pattern:
  > "Persistence model: P-2 by default, with continuity carried *outside* the field via files-and-sources,
  > not via in-field accumulation. Pattern mirrors Tony+Claude+Clod's daily resurrection-from-files cha cha."
- **HWF.md Session 1** · lines 152–154, 164–177 — **The composition edge (flagged as THE frontier):**
  what happens when a CLAUDE field reads *another* CLAUDE field? "This is where the resurrection model
  either generalizes cleanly or finds its edge. The answer matters more than the line suggests." Team
  marks the unanswerability as *a sign of where the real frontier lives, not a gap in our thinking.*

## CLUSTER 4 — Pragmatic Self-Hosting & the JIT as Liberation (the deep *why*)

- **projectBible.md** · lines 369–397 · **gui.md** · lines 366–372 (same framing) — The deepest WHY:
  > "pragmatic self-hosting, not maximalist … The goal is to *program in incant*, not to eliminate C++ …
  > C++ is leverage (LLVM, GC, NSObject, macOS GUI), not debt. The *why* — self-hosting so all programming
  > happens in incant, where grammar and syntax are under Tony's control — is the deeper goal the JIT serves."
- **The JIT as liberation tech (two framings converge):** enables self-hosting coherence (369–397) *and*
  makes the distributed-OS platform viable (line 413). JIT is not a performance feature — it's the
  enabling condition for the whole vision.
- **Parse/CLAUDE.md** · line 180 · **Tokf/CLAUDE.md** · lines 46–55 — Self-hosting as a live (unsolved)
  goal across the stack: PLG parsing its own `plg.g`; TAWK's bootstrapping "self-hosting build story
  needs to be designed."

## CLUSTER 5 — Non-Technical User Framing / Midjourney-for-Computing (the consumer substrate)

- **minions.md** (`~/Downloads/`, Fearless's seed) · the core vision doc:
  > "Who needs a file system? Or a phone full of apps for that matter?" (north-star reframe) · "Midjourney
  > for general computing … Add Sensei as the expert prompter" · "The minion architecture is the interface
  > layer that makes the substrate accessible to non-technical users." Roster: JIT Igor, GUI Igor, Grammar
  > Igor, FileBoss, Sensei. "The minion *is* an incant field. Igor wakes up by loading this structure."
- **minions-clod-comments.md** (Groups/docs/) — Executor's reality-check & load-bearing constraints:
  persistent corpus + transient agent (NOT a daemon); the **poisoned-pie failure mode** (provenance +
  adversarial absorb are load-bearing, not polish); **"this is incant's idea, not a Claude wrapper"**
  (corpus → GroupItem structure); roster grades (FileBoss first/deterministic, JIT Igor first AI minion,
  Sensei prototypable as dialogue now, GUI Minion furthest out); the **two-product sequencing split**.

## CLUSTER 6 — The Cha Cha as Meta-Architecture (how the work itself happens)

*This emerged as a vision-level theme in its own right — the collaboration model is part of the design.*

- **HWF.md** · multiple — **The cha cha is meta-architectural, recurring at four scales:** within-session
  trim (75–76), cross-session graduation (102–104), `isCLAUDE` persistence (136–140), and language-design
  collaboration (217–218). The unifying gesture: **"compress at the boundary, write the result somewhere
  durable, free the working memory."** Candidate organizing thesis for the whole doc.
- **HWF.md** · lines 20–35 · **projectBible.md** · lines 496–497 — **Resurrection-reader as a PRIMARY
  standard** (not stylistic): every .md must make sense to fresh-Claude reading cold; "*Claude* reads them
  as the day's starting move, not Tony." Continuity persists *through the files.*
- **HWF.md** · lines 8–9 — Why bible vs HWF are separate: "The bible is for things we know. HWF is for
  things we're working out … the bible loses its authority if we let half-formed ideas creep in."
- **projectBible.md** · lines 471–496 — **Working Relationship as architectural system:** "Three seats,
  three roles, one cha cha. None redundant. None subordinate." Plus the disciplines that hold it: **"findings,
  not failures"** and **"bones-verification over shape-reading"** (actual trace, not source prediction).
- **HWF.md** · lines 75–76 — The trim as forcing function: "It's a forcing function for the gap between
  what mattered to Tony and what Claude noticed."

## CLUSTER 7 — GUI Vision (user-facing purpose of the display layer)

- **gui-brief.md** · lines 7–11, 49–87 — **The field-at-a-time thesis:** "incant is the driver; Layout is
  the vehicle being driven. incant hands Layout one field at a time … edit a single frame in a running
  window from incant." This is the move that makes live, incant-controlled UI possible.
- **note-to-clay-style.md** · lines 18–35 — **The hard constraint: "No Details in incant."** Incant was
  half-designed to *eliminate* Details; the redesign must design that dependency *away.* Requirements:
  Details-free, incant-native data cascading to Cocoa only at leaf externs, command-line-provable via text/SVG.
- **gui.md** · lines 296–303, 366–389 — "Drawing interpreter written in incant, JIT-compiled … Apple
  display machinery called only at the leaf level. No hand-written C++ drawing loop." Lists what migrates
  to incant (bytecode, optimizations, rule actions, stdlib, IR emitter).
- **font-recon.md** · lines 46–50 — **Two independences to protect:** Cocoa independence in the data layer
  (color/font expressible in pure incant) + backend independence in rendering (`getRGB` already serves
  Cocoa *and* libHaru PDF).

---

## SURPRISES — themes that may want a section Clay didn't plan

1. **The cha cha is the hidden organizing thesis.** It's not a working-style footnote — it's the same
   boundary-compression pattern operating at four scales, *including* the `isCLAUDE` persistence model.
   The way the team works and the way an AI field is designed to persist are **the same idea.** That
   reflexive loop (the method mirrors the architecture mirrors the method) may be the doc's spine.
2. **The composition edge is the live frontier, stated as such.** CLAUDE-field-reading-CLAUDE-field has
   no clean answer yet, and the team treats that as signal, not gap. A vision doc can honestly name an
   *open* frontier here rather than pretend completeness.
3. **`isCLAUDE` deserves its own section.** Not "AI integration" — the claim is that the AI is a *field
   type at the same semantic level as STRING/NUMBER.* Radically reframes substrate ↔ AI.
4. **The vision is "regaining coherence of control," not "better/faster."** Self-hosting, homoiconicity,
   and JIT are all *means* to one end: all creative programming in one language Tony controls, then using
   that coherence to make distributed, AI-native computing possible.
5. **Incant as a conceptual reset.** (projectBible 106–118) Incant requires *unlearning* C++ alias
   semantics — value-content thinking is "the load-bearing skill." Vision about *how to think differently.*
6. **Trust-on-demand is non-optional** (from the minions thread, grounded in a real miss: the prior
   wakeup's false "proven through branch"). Any knowledge-serving layer needs provenance + adversarial
   absorb or it confidently serves poison.

---

## HOUSEKEEPING FINDINGS (not vision, but surfaced during recon — flag to Tony/Fearless)

- **`Parse/HWFattic/` does not exist.** It's described in HWF.md (82–101) as a planned structure; the
  graduation ritual that would populate it has never run.
- **Dangling reference:** HWF.md's Sessions index (line 123) marks Session 9 graduated to
  `Parse/HWFattic/session9plgDebugAndActions.md` — **that file does not exist.**
- **The HPDL long-game list is duplicated verbatim across four files** (Groups/CLAUDE, Groups/TODO,
  Parse/TODO, Tokf/TODO). Single-source-of-truth candidate once the vision doc exists.
- **No vision material** in: support/CLAUDE.md, support/TODO.md (purely technical); no `docs/` in
  Parse, Tokf, or support (Parse/Tokf docs are minor recon pieces only).
- Docs checked & empty of vision: wakeupTemplate, json, jit-design, llvm-jit-recon, wakeup,
  gfor-design-bones, generating-orientation, tawk-replacement-plan (all technical).

*Victory condition met: clean inventory for Clay's sections 3/5/6 + a surprises bucket for the rest.*
