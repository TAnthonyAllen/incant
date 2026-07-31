# Clod's notes on vision.md (Pass 1) — for Clay's next pass

*2026-06-28. After Tonto recon completed. Read against `~/Downloads/vision.md` Pass 1.
Full recon inventory: `docs/vision-recon-inventory.md`.*

## What's already landed well
The honest-model section ("persistent corpses, rented sparks"), the four operations, corpus-as-
GroupItem, the two-products split, and the poisoned-pie warning are all in and well-written. No notes
there except: keep them.

## Filling the "long game" stub (lines 69–86) — recon is now in hand
Your bullet list is right. The verbatim source material to draw on:
- **projectBible.md 401–413** has the whole passage nearly ready to lift: "GroupItem fields are
  deployable units. Run anywhere. Message each other across platforms. Location transparent. Claude is
  a GroupItem — `isCLAUDE` alongside `isSTRING`, `isNUMBER`, `isGROUP`. The AI is not a tool called from
  incant — it IS a field in incant. … Go-style channel messaging … ZFS-flavored storage … With JIT,
  incant ships."
- **The `isCLAUDE` persistence model is already designed** (HWF.md Session 1, 136–140) and it ties the
  long game back to your minion section: the field's persistence "mirrors Tony+Claude+Clod's daily
  resurrection-from-files cha cha." *Same boundary-compression idea as the minions.* Worth making explicit
  — it unifies two sections that currently read as separate.
- String-keyword retirement is real (projectBible 401–413, "Eliminate the `string` keyword").

## Three things the recon surfaced that the draft doesn't yet have

1. **The cha cha as the doc's possible spine (currently absent entirely).** The recon's biggest finding:
   "compress at the boundary, write somewhere durable, free working memory" recurs at FOUR scales —
   session trim, cross-session graduation, **`isCLAUDE` persistence**, and language-design collaboration
   (HWF.md). The way the *team* works and the way an *AI field* persists are the same idea. That reflexive
   loop (method mirrors architecture mirrors method) could be a short section, or the organizing thread
   the whole doc hangs on. Right now vision.md has no working-relationship / how-we-work dimension at all.

2. **The three paradigm collapses (Cluster 2, projectBible 296–302).** The homoiconic section is good but
   stops at "one shape." The sharper claim is the three collapses that usually stay separate: match()↔
   parse(), code↔data, and **grammar↔result** ("data structure IS grammar IS result"). That's a crisper,
   more quotable statement of *why* homoiconicity matters than "self-modification" alone.

3. **The composition edge as an honestly-open frontier (HWF.md Session 1, 152–177).** What happens when a
   CLAUDE field reads *another* CLAUDE field — "where the resurrection model either generalizes cleanly or
   finds its edge." A vision doc that names a live unsolved frontier reads as more honest (and more
   exciting) than one that implies completeness. Good candidate to close the long-game section on.

Optional, if the doc wants more reach:
- **"Conceptual reset"** (projectBible 106–118): incant requires *unlearning* C++ alias semantics —
  value-content thinking is "the load-bearing skill." Vision about *how to think differently.*
- **GUI cluster** (gui-brief / note-to-clay-style / gui.md): the field-at-a-time thesis ("incant drives,
  Layout is driven"), the hard **"No Details"** constraint, command-line-provable, Cocoa/backend
  independence. The draft's "apps disappear because IncantForms replace them" has no grounding section yet;
  this is it.

## One accuracy flag (bones over shape-reading)
Lines 58–61: "The four-phase plan — BDWGC integration, generateCode, bytecode emitter, LLVM backend …
Each phase unlocks the next." Per CLAUDE.md / the bible, **JIT does NOT go through bytecode** — bytecode
and JIT are *parallel, independent lowerings* of the same cached BlocK; LLVM IR comes straight from the
ops/BlocK, not from `bcLIST` (2026-06-17 decision; `docs/jitDesign.md` Part IV). So "bytecode
emitter → LLVM backend" as a linear unlock is slightly off. Suggest: "Phase 1 done; Phase 2 (control
flow, gIF) is the current arc; bytecode and JIT are parallel lowerings of the same IR." Keeps the
"each phase unlocks the next" spirit without implying LLVM is generated from bytecode.

## Housekeeping (not for the vision doc — for Tony/Fearless)
- `Parse/HWFattic/` doesn't exist (only planned in HWF.md 82–101; graduation ritual never ran).
- HWF.md line 123 references `Parse/HWFattic/session9plgDebugAndActions.md` — that file was never created.
- The HPDL long-game list is duplicated verbatim across 4 files (Groups/CLAUDE, Groups/TODO, Parse/TODO,
  Tokf/TODO) — single-source-of-truth candidate once vision.md exists.
