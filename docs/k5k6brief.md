# K5/K6 — kant8T Extension (GATE errand, ruled 2026-08-05)

**Nature:** MEASUREMENT ONLY. Nothing gets repaired. Interpreted-only. Day-size or smaller; rides alongside campaign work, touches nothing the campaign touches.

---

## WHY (read first — it governs every judgment call below)

KANT-8 is the interpreter's recursion defect family: locals are node-resident, protected by a save/restore bracket, and the bracket is guarded by a boolean flag (`recursive`) where the problem is a **depth**. The suspected tell is at RuleStuff/interpreter line ~587: `recursive` is cleared on the *outermost* restore. A flag doing a counter's job has two characteristic failure shapes, and K5/K6 are those two shapes, built as fixtures.

A ruling is queued behind these measurements: whether to make the bracket **unconditional** (push locals on every entry, pop on every exit, no flag) — which would make KANT-8 unconstructable and restore interpreter/JIT parity — or whether the blast radius is bigger than the bracket and the fix escalates. The GATE (2026-08-05) says no KANT-8 repair and no frame-model ruling until K5/K6 numbers exist. Your results feed the KR-3 ledger rows that ruling will cite. That is why this errand is measurement-only: **if you see the fix and it looks like one line, do not land it.** The broken behavior is the specimen. Fixing it during measurement destroys the baseline the ruling needs.

Because this is measurement, a result that contradicts the predictions below is a *success*, not a problem. Report what is, with file:line.

## K5 — sequential re-entry (flag cleared, then trusted)

**Shape:** call K1 twice in sequence from the same caller, same session.

**Prediction to test:** first call arms and runs the bracket correctly; the outermost restore clears `recursive`; the second call then either (a) re-arms correctly at entry — in which case document the re-arming site with file:line, because that mechanism is load-bearing for the ruling — or (b) skips the bracket and returns intact-looking results built on unsaved locals.

**Measure:** the returned value of both calls, plus a named probe on whether the bracket ran on call 2 (assert by name, not by silence — a line that prints `K5 bracket call2 ran=<0|1>`). If call 2 is wrong, capture the corruption shape: which local, what value, where it leaked from.

## K6 — mutual recursion (flag never trips)

**Shape:** A→B→A, where outer A holds a node-resident local across the B call, and the inner A activation writes the same local.

**Prediction to test:** the flag detects direct self-recursion only, so A→B→A never arms the bracket at all; inner A clobbers outer A's local; blast radius currently graded UNMEASURED in the corpus — this fixture is what measures it.

**Measure:** (1) named probe: did the bracket run at inner-A entry (`K6 bracket innerA ran=<0|1>`); (2) outer A's local after B returns — expected-if-broken is the inner activation's value, expected-if-sound is the outer's; assert the observed value by name; (3) the final returned result. If clobbering occurs, note whether it is confined to the shared local or reaches further (other locals, label state) — that confinement question is the single most ruling-relevant number in this errand.

## FORM AND ORACLES

- Extend `incant/kant8T` following the K1–K4 pattern; fixture registration in the standard two lines. kant8T (plus registration) is the only surface that changes.
- Oracles: value-assertion-by-name throughout. Every probe is a named line; absence of the line is a failure of the fixture, never a pass. No check rides on exit status alone.
- Before citing line 587, confirm the mechanism at that site — the line number is from an earlier read and may have drifted. The claim is "clears `recursive` on outermost restore," not "line 587."
- Fleet stays byte-identical everywhere outside kant8T's own new output. Run pop.sh; expected result is the current standing footprint with only kant8T's additions differing.

## DELIVERABLE

kant8T extended with K5/K6, run output, and a short report: per case, predicted / measured / delta, file:line for every mechanism named, B0 form (provenance, confidence RUN/MEASURED, asOf). Flag anything observed that neither prediction anticipated — unanticipated observations are in scope; acting on them is not.

## FENCE

No repair. No frame-model changes. No JIT involvement. No production-path edits, even one-liners, even obvious ones. Interpreted-only. If a fixture cannot be built without touching production code, stop and report the wall instead — that finding feeds the ruling too.
