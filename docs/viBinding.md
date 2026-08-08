# VI binding table — the A4 commission

**Status:** STARTED, NOT DELIVERED · asOf 2026-08-08 · commissioned by `docs/verification.md`'s
Appendix §A4 (Tony via Clay, 2026-08-08)
**Scope of this file today: ONE ROW.** A4 is a one-session walk over every VI candidate term and
it has not been done. Row **A2.6** is answered early and alone because Tony flagged it by name as
the row to watch — *"if his file:line walk contradicts my READ-grade claim that minting is
manual, that's the appendix's own grades doing their job."*

⚠ **A ONE-ROW TABLE IS NOT A TABLE, and this file says so on its face** so that nobody reads a
stub as coverage. The remaining terms are **UNWALKED**, which is a different state from A4's
**UNBOUND** — unbound is a finding, unwalked is an absence of work. Do not conflate them; that
conflation is how a partial census gets read as a complete one (RULE H9).

---

## Row A2.6 — MINT · **CLAY'S CLAIM CONFIRMED, and it upgrades from READ to measured**

| slot | content |
|---|---|
| **term** | mint (A2 step 6 — claim becomes durable residue) |
| **binding** | **UNBOUND.** No file, no line. |
| **invoker** | **human** |
| **position** | step 6 of A2 |
| **consumes** | a collected verdict (pop.sh's roll-up, a ladder's green/FAIL rows) |
| **consumed-by** | `docs/*Corpus.md`, `docs/knownErrors.md`, wakeup seals, commit messages — **all written by hand** |
| **structural / disciplinary** | **disciplinary**, wholly |

**The walk, so the grade is checkable rather than asserted:**

- **No harness script writes any repo file.** Every redirect in `genLadder/*.sh` and
  `jitLadder/*.sh` targets the per-run temp dir (`$T`, `mkdir -p`'d at the head, `rm -rf`'d at the
  foot). Searched for writes to `docs/`, `genLadder/`, `jitLadder/`, `incant/`: **none.**
- **No `B0` writer and no claim-row writer exists** anywhere in the harness fleet. The only `mint`
  occurrences in those scripts are the English word in comments (`pop.sh:345`, about forward
  references minting empty stubs — a *parser* fact, not a checking-language one).
- So the flow does stop at **collect**, exactly as A2.6 states, and every B0 row exists because a
  human typed it.

**⚠ ONE REFINEMENT, AND IT NARROWS WHAT THE GRAMMAR HAS TO MECHANIZE.** A2.6 reads as *"nothing is
automated at step 6."* More precisely: **evidence has an automatic door; verdicts do not.**
`INCANT_PARSE_RECORD` and `INCANT_JIT_RECORD` (`genParse.rtn:1216` and the `jitRunAction` writer)
persist the generated source and the post-mem2reg IR onto the node, with a **file sink** when the
env var carries a path — one writer per fact, both `noPrint`, both gated, with `recordParse()` as
the in-fixture door. That machinery already does automatically what step 6's *input* needs.

**What has no door is the residue** — the sentence that says *this evidence means this claim, as
of this date, at this grade.* So the mint gap is not "step 6 is unautomated"; it is **"the claim
is the only artifact in the lifecycle with no writer,"** which is a smaller and much more
tractable target for grammar-making than the appendix's wording implies.

**Verdict on the grade:** the file:line walk **does not contradict** Clay's READ claim. It
confirms it and sharpens it. A2.6 stands as finding #1 of the appendix.

---

## Everything else — UNWALKED

A4's rules of engagement stand unamended for the real pass: every VI term gets a row, **UNBOUND**
is recorded and never omitted, VI-2's SURVEY ROW gets folded in (sweep `pop.sh` · `recordPop.sh` ·
`ladder.sh` · `printPop` · `containerPop` for missed oracle kinds — the WOKE alarm as a meta-check
candidate, `countRatio` as a possible distinct kind), each binding marked **structural** or
**disciplinary**, and the whole thing **read-only against the scripts** — VI-7's fence unamended,
no runner, no compiler, no syntax.

**Two candidate rows already have measured evidence sitting in the tree, and should be picked up
first when the real walk runs** — both from 2026-08-08, both recorded in their harnesses:
- **the anti-vacuity guard** — `genLadder/mixed.sh` refuses to report its diffs when its stripper
  matched the wrong count. A check whose subject is *its own instrument*, which is the same
  meta-check shape VI-2's SURVEY ROW nominates the WOKE alarm for.
- **the inverted pin** — ladder rows JXD-1/JXD-2 and `mixed.sh`'s pin assert a **defect** and go
  red on repair. VI's oracle-kind list has no term for an assertion whose expected value is known
  to be wrong; if that is a distinct kind, it belongs beside `fixpoint` and `degradeZero`.
