# THE METHOD — how this project works and why
**REFERENCE — NO ACTION. This document describes the working system. Nothing in it builds, blocks, or modifies any active arc.**
*Drafted by Clay, 2026-08-05, at Tony's direction. Corrections are Tony's; the file is fidelity-class — meant to be re-read.*

---

## 1. The three seats

**Tony (Haps)** — architect and final authority. Every ruling is his; every ambiguity resolves at his desk. He is also the relay: no seat talks to another except through him or through files he carries.

**Clay** — the design seat (claude.ai, conversational). Writes briefs, probes, charters, and rulings-for-signature. **Clay has no filesystem reach** — read-only uploads only. This is not a limitation to be worked around; it is load-bearing (§3).

**Clod** — the execution seat (Claude Code, filesystem and build access). Implements, measures, greps, builds, commits. Standing permission: change source freely, commit and push routine work at discretion. Clod's reports carry measurements, not opinions.

The separation is adversarial by construction. Clay's claims must survive Clod's greps because Clay cannot quietly make them true himself. A design seat that can edit the tree will, eventually, confirm its own theories. This one can't.

## 2. The transport — walkie-talkie

Full protocol in `docs/walkieTalkie.md`; read it before writing anything into `ipc/`. The essentials:

- **Channel:** `Groups/ipc/clay-to-clod.md` and `ipc/clod-to-clay.md`, sequenced (SEQ n), with a three-state header: fresh / working / cleared.
- **Asymmetric by nature** (WT-10/13): Clod polls the file; Clay reads only when Tony prompts.
- **No silent overwrite** (WT-11): every write carries the whole file. This rule has been broken exactly once; the erratum lives in the file it damaged.
- **Route by class** (WT-9): a brief Clod will *act on* is dictated by Clay and transcribed by Clod — the transcription is a second close reader. Reference docs travel as files, imported directly.
- **Tony's window:** `grep -H '^STATUS:' ipc/*.md`.

## 3. The claim discipline

**B0 format:** every claim carries provenance (file:line), confidence, and asOf. A claim without provenance is an opinion wearing a lab coat.

**The measured asymmetry — the single most useful fact this project knows about itself:** structural claims (what shape a thing has, where a seam is, what an interface owes) hold at high rates. Causal claims (why something failed, which mechanism produced an output) have died at rates approaching five-for-five on first contact with a grep or a measurement. This is not a slogan; it is a running tally, re-confirmed repeatedly, with named specimens. Consequence, codified as **HOW TO WEIGHT A CLAY BRIEF**: *take the distinctions, check the attributions. Cost of checking: one measurement run.*

**Rulings are Tony's and they are written down** — with date, in the artifact they govern. A ruling that lives in memory is a future argument.

## 4. Measurement doctrine

- **Bones over shape-reading:** if you haven't run it, it's not DONE. Reading code and predicting its behavior is design work; only execution certifies.
- **POP** — proof of practice: a small executable test that demonstrates the thing, captured as a baseline *before* changing anything and diffed after. Committing rides on POPs.
- **Baselines are byte-diffed**, not eyeballed. The current fleet at any moment is enumerated in `wakeup.md` under WHAT IS RUNNABLE.
- **Measure before building** (WT rule, general doctrine): if a proposed mechanism only saves typing, it isn't worth a build.
- **Prior art beats speculation:** before designing, grep for the worn path that already solves it.

## 5. The instrument doctrine — tests that prove they can fail

The project's tests are treated as instruments, and instruments are themselves under test. The rules were each paid for by a specific incident (§7):

- **H2 — a fixture must reach its assertions.** A `stop()` above the interesting half certifies nothing.
- **H3 — prefer oracles that cannot be regenerated green.** A same-run diff between two engines moves only when the engines disagree; a `.target` file can be quietly re-blessed.
- **H5 — anything whose failure mode is a hang runs under a wall-clock cap.** A timeout is reported by name, never as a diff; a hang is not a wrong answer, it is the absence of a run.
- **H7 — negative controls on real captures.** Every instrument proves it can detect the defect it exists for, ideally against a rebuilt known-defective binary, not an argued expectation.
- **Vacuity guards:** identical-but-shallow passes a diff, so depth is asserted *by name* (a marker only the deepest activation prints).
- **Foot census:** harnesses assert their own completeness at the end of the run. A check that evaporates (helper called but never defined) is invisible in a count of checks that ran — the headline tally is the camouflage.
- **The unsurprising green is the one nobody audits.** Doubt the instrument when the result doesn't surprise you either.

## 6. Oracles, by family

Parity with the interpreter was the founding oracle: the JIT must agree with the interpreted engine, certified by same-run diff (rung JC's construction). It remains the default. But parity is scoped, not sacred — **ruled 2026-08-05:** *parity where the interpreter is trusted; tailored oracles where it is indicted; the ledger records which is which, per family.* For the recursion/locals family (KANT-8's territory) the JIT is correct-by-construction and the oracles are: closed forms (values computed by neither engine), unrolled twins (same computation, two shapes, one engine), and inverted K-rows (each known interpreter defect pinned as a must-not-reproduce). Every intended divergence is a ledger row with its value asserted by name; an unlisted disagreement is a defect, full stop.

## 7. Doctrine remembers its etiology

Every rule above traces to a named incident with provenance — the four evaporated checks inside a green banner (08-05), the `stop()` that parked five sixths of a baseline, the zsh word-split that passed every harness, the `if x.taG` truthy-always trap, COPY THE IDIOM LOSE THE HELPER (three instances). Bear-traps live in `CLAUDE.md`; H-rules and worked examples in the harness headers and `wakeup.md` vintages. **A rule that has forgotten its incident is ritual; these haven't.** When a new class of failure appears, the response is: fix the instance, then ask what instrument would have caught it, then build that instrument with a negative control.

## 8. The cycle

1. **Tony names the objective** (or the wakeup file's OPEN list does).
2. **Probe** — Clay drafts read-and-report questions; Clod greps and measures; nothing is built. The probe exists because of §3: the brief's attributions get checked before anyone acts on them.
3. **Ruling** — Tony decides, on measured ground. Options are presented with costs; the ruling is recorded with date.
4. **Brief** — Clay dictates: RULED / CONTEXT / STEPS with a POP between each / edges named so they are decided rather than discovered / NOT IN SCOPE / baselines. Held-out items are stated as held out.
5. **Build** — Clod executes sequentially, POPs each step, reports in B0 with per-step measurements, commits on green.
6. **Absorb** — Clay grades the report, tallies which claims died, promotes incidental findings that deserve it, and stages the next move.
7. **Seal** — `wakeup.md` gets a dated vintage at day's end: newest section first, older vintages retained below, findings, errata against its own earlier sections, WHAT IS RUNNABLE, and OPEN-and-whose. Silence in a newer vintage about an older item means *resolved*.

## 9. Vocabulary

POP (proof of practice) · BYU (Bob Yo Uncle — done) · WSS (we shall see) · HWF (hands waving furiously — the unproductive design spiral, to be exited) · HPDL (highly desirable, park for later) · kitchen check (tree/status sweep) · vintage (a dated wakeup section) · fleet (the full set of runnable checks) · bones (execution evidence, vs shape — reading) · ledger (the enumerated intended-divergence table) · gate (a named precondition that must fire before a parked item unparks).

## 10. What is actually unusual here

The ingredients are standard best practice — regression suites, differential testing, negative controls, hermetic baselines. The assembly is not: instruments that audit themselves every run; an epistemology with a *measured* error rate that changed how work is weighted; doctrine that cites its incidents; and a three-seat structure where the design intelligence provably cannot touch the tree, so its claims are checked by construction rather than by virtue. The system's defining habit is that it treats its own confidence as a suspect and its own green banners as claims requiring provenance — because the times it didn't are all named in §7.
