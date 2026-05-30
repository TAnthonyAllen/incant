# wakeup.md — the wake-up doc template

*A standing template for the **wake-up doc**: the short, self-contained `.md` that brings a
fresh or crashed Claude back up to speed on in-flight work. Part of the cha-cha. Drafted
2026-05-30 (Clod); revised 2026-05-30 (Clay). Refine as the practice matures.*

---

## What it's for

When a Claude loses its working context — Clay's app crashes/restarts, a session compacts, or
work hands off across days — the fast way back in is **not** the transcript. The transcript is
too long, and Clay's app thrashes on large inputs. The fast way back is a **short doc that
re-establishes the mental model and the current state in one read.**

Proof of concept: the gIF crash, 2026-05-30. A freshly-restarted Clay woke clueless and thrashed
when fed the session; a ~1.5-page wake-up doc oriented him and he resumed cleanly. That shape is
the template below. (`docs/gIF-bytecode-status-2026-05-30.md` is the worked example.)

The same doc is also insurance against a subtler failure: a long session where context compacts
and Clay starts confabulating state he no longer actually holds. The wake-up doc restores the
ground truth without requiring a restart.

---

## The principles (the *why* — these matter more than the skeleton)

1. **Assume zero memory.** Fully self-contained. The reader has no recollection of the session.
   Never reference "the thing we discussed" — restate it.
2. **Short beats complete.** One read, ~1–2 pages. Cut to what's load-bearing. If it's growing
   into a design doc, split that out and keep the wake-up tight.
3. **Lens before details.** Give the mental model *first* — the handful of facts the reader must
   hold to *reason* about the work — then the specifics. A reader who can reason recovers; one
   who can only recite doesn't. This is the single most important section.
4. **Bones, not shape-reading.** State what's verified by an actual run/output, not what the
   source predicts. If you haven't run it, it's not DONE. Mark something done only when it's
   bones-confirmed.
5. **Diagnosis, not symptoms.** For open items, give the *root cause you found*, not just
   "X is broken." That's what lets the next session act instead of re-deriving.
6. **Resume-oriented.** End with the literal next steps, in order, and exactly what the reader
   needs in hand to act on them.
7. **Honest state.** Separate DONE / OPEN / DEFERRED, and say whose call the deferred ones are.
8. **Resurrection-reader standard.** It must read clean to a fresh Claude tomorrow with no memory
   of today. Convert relative dates to absolute; quote flags/artifacts/commands verbatim.
9. **Write it before the risky step, not after.** The gIF doc was written post-crash, which
   worked but means the session was already lost. The preventive form is: write or update the
   wake-up doc at a natural pause, before anything irreversible. If the crash happens before
   the pause, you still lose the session — but the doc from the *last* pause gives the reader
   a coherent landing point instead of nothing.

---

## The skeleton

```
# <topic> — Status & Handoff (<absolute date>)
*Written by <Clod/Clay> for a fresh <reader>. Assumes no memory of today. Self-contained.*

## What this is
   one paragraph: the work, the goal, where it sits in the larger arc.

## The lens
   the mental model — the few facts you must hold to reason about this. One tight
   paragraph. THE most important section.

## Current state of <the artifact>
   the actual thing, clean — the current source/shape, not a description of it.

## DONE — bones-confirmed (not shape-read)
   what's verified working, with the evidence (actual output / run result).

## OPEN — root-caused (diagnosis done; fix may be someone's call)
   each item: the symptom, the ROOT CAUSE found, and what it needs next.

## DEFERRED — not now; whose call
   out-of-scope items and who owns the decision.

## Files touched / run recipe
   what changed; the exact command to reproduce or run.

## To resume — next actions in order
   the literal next steps, in order. End with what the reader needs in hand:
   which source files to upload (for Clay), or which repo state to verify (for Clod).

## Gotchas (durable — will bite again)
   machinery/tooling traps hit this session, so the next reader doesn't re-hit them.
```

Not every section is mandatory every time — drop the ones that don't apply. But **What this is**,
**The lens**, **DONE/OPEN**, and **To resume** are the load-bearing core; rarely skip those.

---

## Notes by reader

- **For Clay** (claude.ai — no filesystem, no git, context lost on crash). The doc gets
  *uploaded* to a fresh Clay **instead of** the session. It IS his memory across the gap, so it
  must stand entirely alone and stay upload-sized. Err toward restating over referencing. The
  **To resume** section must name exactly which source files Tony should upload — Clay can't
  fetch them. Don't say "the active surface files"; name them.
- **For Clod** (Claude Code — has the repo, git, and usually session continuity). The doc lives
  in `docs/`, survives compaction, and is the resume point. Clod can lean on the tree and git for
  detail, so his wake-up doc can *point* ("see commit `abc123`", "`git status` shows the held
  files") rather than restate everything. Clod tends to wake with less trouble than Clay, so his
  bar for length is looser — but the lens-first discipline still pays off.

---

## How it fits the cha-cha

Write or update a wake-up doc at a natural pause: before a risky/irreversible step, at end of
session, or when handing off. It's cheap insurance — the minimum to get the next reader
reasoning, not a full record. One per work-thread; update it in place rather than spawning new
ones, so there's a single current entry point. When the thread closes, the wake-up doc graduates
into the durable record (bible / TODO / HWF) and can be retired.

**Coverage:** wakeup.md covers the full active work surface, not just Clod's thread from the
current session. If the session touched gIF and directives and a buffer arc, all three get at
least a lens-and-status paragraph. Clay waking up to half the picture is the same failure mode
as Clay waking up to nothing.
