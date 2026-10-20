# Docket item 3 -- the kind hand-over (branch jit-kind-handover)

Ruled 2026-10-20: an emitter's choice of a value's KIND is a run-time fact; read at build, it is item 3's class. A cure
is built only in the jitOpEmits pattern -- a kind the build cannot carry hands its statement to run time. The census
(R1) is in docs/jitter.md on trunk, under "Docket item 3".

## Pre-registered movers (written before the build -- but AFTER four exploratory builds, V1-V4, in the clone)

Honest provenance: the movers below were MEASURED on uncommitted prototypes before this file was written, so this list
is a record, not a prediction. V1 handed over inside jitSeedField and caught correct statements (a string field that is
only a dot's target, `jdA.noPrinT = 1`; a holder that is only a deref's target, `*arOuter`) -- the hand-over belongs where
a value is CONSUMED, not where it is seeded. V2 put it there; V3 exempted `=`'s target (its store has run-time roads,
jitEmitAssign :926); V4 exempted a node in flight (gJitLastIsNode: jitAssignNodeRT and jitPrintNodeRT read the kind at
run time). V4 is what is built.

The shape: jitKindUncarried(x) is 1 for an UNSEEDED operand whose kind at build is known and is neither a count nor a
number. Two consumers ask it: runOPdirect, for a binary operator other than `.` (both sides, but only the source of `=`),
when no node is in flight; and jitEmitBareRead (the print road). Either hands the statement over (jitHandOver; jitStmtEnd
rolls its IR back and emits one run-time call). A KINDLESS operand is not caught: that is the gap the census names, and
it is Tony's to rule.

- jitterKindT JK-1 3 -> abc, JK-2 digits -> xyz (= the twin).
- jitOpEqFoldT JOF-2 `2x 1` -> `ab cd` (its intended value: the string concatenation is handed over, not jitted as
  integers). JOF-4 degrade count 1 -> 6 (the five extra are hand-overs of `joK1 = joS`-shaped string assigns; each a
  correct fallback; the row's "intended 0" was written for the outer `=` that got a null, which still degrades once).
- jitLadder JS degrade count 0 -> 2: jitSelfFn's `print "PREAMBLE":;`, pinned WRONG on purpose (it printed its length),
  is handed over and prints PREAMBLE. The rung's degrade-zero row moves; its line count does not.
- Everything else in pop.sh and jitLadder row for row with the branch point (pop.sh 1572 green). Canary 362 -> 363.
- H7 (cure committed first), two halves: the runOPdirect hand-over removed alone -> JK-2 digits again, JOF-2 `2x 1`
  again, JK-1 stays cured; the jitEmitBareRead hand-over removed alone -> JK-1 3 again, JK-2 stays cured.
- Measurement: the 26 generator files (V4, exploratory): 24 exit 0 and disagree, 2 exit 139 (leafClassT, zeroWidthT),
  every rule now filed with a real CodE whose conjuncts read `0` (`return a() 0 b()`). The conjunct is a KINDLESS local
  (`conjunct = "&&"` at run time), whose frame slot the prologue made i32 at build (:359). The two crashes are new-road
  parses through those malformed bodies (aCTionSetBrackets, aCTionTraiT reading a missing child) -- inferred, not proven.
