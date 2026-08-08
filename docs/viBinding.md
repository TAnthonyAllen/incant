# VI binding table — the A4 commission

**Status:** STARTED, NOT DELIVERED · asOf 2026-08-08 · commissioned by `docs/verification.md`'s
Appendix §A4 (Tony via Clay, 2026-08-08)
**Scope of this file today: row A2.6 + the full `byteIdentical` census (SEQ 43 task 1).** A4 is a one-session walk over every VI candidate term and
it has not been done. Row **A2.6** is answered early and alone because Tony flagged it by name as
the row to watch — *"if his file:line walk contradicts my READ-grade claim that minting is
manual, that's the appendix's own grades doing their job."*

⚠ **TWO TERMS ARE WALKED; THE REST ARE NOT, and this file says so on its face** so nobody reads a
partial table as coverage. **`byteIdentical` is complete** (30 instances, SEQ 43 task 1) and
**A2.6/mint** is complete. Every other VI term is **UNWALKED**, which is a different state from
A4's **UNBOUND** — unbound is a finding, unwalked is an absence of work. Do not conflate them;
that conflation is how a partial census gets read as a complete one (RULE H9).

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

## TASK 1 (SEQ 43) — the `byteIdentical` census. **WALKED, 30 instances.**

**Counting rule, stated because a census is an instrument (H9):** one row per **instance that
fires**, not per line of script. A helper body invoked N times counts N. `diffcheck` and
`parkdiff` **definitions** are excluded; their **invocations** are counted, including the four
that sit after a `;` on an `extract` line — an anchored `^diffcheck` regex misses those and
undercounts pop.sh 13 → 8, which is the first thing this walk got wrong about itself.

| # | site | capture | baseline | **generation** | verdict |
|---|---|---|---|---|---|
| 1–4 | `pop.sh:215-218` rung12/4/5/6 | `extract` slice of `$T/gen` | `genLadder/rung*.target` | **committedTarget** | sayable |
| 5 | `pop.sh:220` rung7 | same | `genLadder/rung7.target` | **committedTarget** | ⚠ **PINCH 2** |
| 6 | `pop.sh:224` census | filtered `$T/cen` | `genLadder/census.target` | **committedTarget** | sayable |
| 7 | `pop.sh:251` spell | `$T/sp` (stderr slice) | `genLadder/spell.target` | **committedTarget** | sayable |
| 8 | `pop.sh:300` manyScratch | `$T/ms.e` | `genLadder/manyScratch.target` | **committedTarget** | sayable |
| 9–11 | `pop.sh:495-498` displayForm/oneTest/jsonTest | run captures | `*.base` | **committedTarget** | sayable |
| 12 | `pop.sh:408` iterT1 | filtered `$T/iterT1.o` | `genLadder/iterT1.target` | **committedTarget** | sayable |
| 13 | `pop.sh:413` iterT3 | filtered capture | `genLadder/iterT3.target` | **committedTarget** | ⚠ **PINCH 6** (parked) |
| 14 | `pop.sh:430` iterT1m | filtered capture | `iterT1m.divergence` | **committedTarget** | ⚠ **PINCH 3** |
| 15–16 | `printPop.sh:54,65` printFamily | stdout / stderr | `printFamily.target`/`.captured` | **committedTarget** | sayable |
| 17–18 | `printPop.sh:147,149` printFamilyNew | stdout / stderr | `*.divergence` | **committedTarget** | ⚠ **PINCH 3** |
| 19 | `printPop.sh:166` print-vs-cout | `$T/o.print` | `$T/o.cout` | **sameRun** | ⚠ **PINCH 1** |
| 20–27 | `recordPop.sh:121,133,134,180,196,215,286,287` | `$T/*` | `$T/*` | **sameRun** ×8 | ⚠ **PINCH 1** |
| 28 | `tree.sh:24` | `$T/d` — *a diff of two captures* | `genLadder/tree.divergence` | **committedTarget** | ⚠ **PINCH 3 + 4** |
| 29 | `ladder.sh:892` rung JC | `$T/jc.jit` | `$T/jc.int` | **sameRun** | ⚠ **PINCH 1** |
| 30 | `mixed.sh` pin | `$lost` (a shell string) | `PINNED_LOST` *inline literal* | **neither** | ⚠ **PINCH 5** |

**Generation tally: committedTarget 19 · sameRun 10 · neither 1 · CANNOT-SAY 0.**

---

## ⚠⚠ CLAY'S PREDICTION IS FALSIFIED, AND THE MISS IS INFORMATIVE

**Predicted:** *"pinches cluster on generation… I doubt the existing scripts consistently know
whether they're diffing same-run output or a committed target."*

**Measured: every one of the 30 classifies, and it is not close.** `CANNOT-SAY` is **zero**. The
attribute is not merely knowable, it is **syntactically obvious at every call site**: the second
argument is either a `genLadder/…` repo path (committedTarget) or a `$T/…` temp path (sameRun).
The shell already encodes the distinction the grammar wanted to add.

**Why the prediction was reasonable and still wrong:** it assumed the *scripts* had to know. They
don't — the **filesystem** knows, and the call site reads it off. **A distinction can be reliably
present in a system without anyone having named it**, and the census's job was to find out which.
So `generation` is the **cheapest** attribute in the rule, not the expensive one, and 4.5's
payment is **not** in progress anywhere in the fleet.

⚠ **But that is a fact about today's fleet, not about the rule.** Every instance is a *shell
script* where the argument is a literal path. The moment a check takes its baseline from a
variable, generation stops being readable and `CANNOT-SAY` becomes constructible. **Clay's
instinct is right about the failure mode and wrong about whether it has happened yet** — which
makes `no default · unstated does not parse` worth keeping precisely because it is currently free.

---

## THE PINCHES, and my amendment-vs-dirty call on each

### ⚠ PINCH 1 — `baseline : name` HAS THE WRONG KIND FOR A THIRD OF THE FLEET · **RULE AMENDMENT**
**10 of 30 instances have no named artifact at all.** All 8 of `recordPop`, `printPop`'s
print-vs-cout, and ladder rung JC compare **two captures produced in the same run**. `baseline :
name · must resolve` is not merely unsatisfied — it is *meaningless*: there is nothing to resolve,
and "absence is LOUD" has no referent.

**This is the round's real finding and it is bigger than generation.** The rule as spelled parses
**19 of 30**.

**Amendment proposed: `baseline`'s KIND IS GOVERNED BY `generation`.**
```
    generation=committedTarget  ->  baseline : name     -- must resolve · absence LOUD
    generation=sameRun          ->  baseline : bytes    -- a second capture · same kind as capture
```
That is a **kind lattice doing enforcement work**, exactly as the `capture = kind` ruling
predicted it would — and it means the two generations are not two values of one shape but **two
shapes sharing a name**. Worth Tony's eye: if that is too much for one rule, the honest
alternative is **two rules** (`byteIdentical` and something like `sameRunIdentical`), and the
census mildly favours two, because the 10 sameRun instances also mint a *different claim* — they
assert an **invariance** (the hook adds no bytes; the gate changes nothing; two engines agree),
not a **correctness**.

### ⚠ PINCH 2 — rung7's BASELINE ABSENCE IS SILENT · **DIRTY CHECK**
```
if [ -f genLadder/rung7.target ]; then
    extract … ; diffcheck "rung7.target" genLadder/rung7.target "$T/r7"
fi
```
**A missing baseline makes the check cease to exist** — no pass, no fail, no line. That is the
evaporation class (`jiquery`'s three `stop()`s, `pop.sh`'s missing `sentinel`, the JIT ladder's
undefined `check`), and it is **the exact thing `absence is LOUD, never pass` was written to
forbid**. The rule is right; **the check is dirty.** The file is committed today so the hole is
**latent**, which is why nobody has seen it. **The grammar would make this unsayable** — and this
is the round's best evidence that the grammar earns its existence, because the guard already
exists as doctrine and was skipped anyway.

### ⚠ PINCH 3 — DIVERGENCE BASELINES ARE A DIFFERENT ORACLE · **NEW KIND, not an amendment**
**4 instances** (`tree.divergence`, `iterT1m.divergence`, `printFamilyNew.divergence`,
`printFamilyNew.err.divergence`) — plus yesterday's `JXD-1`/`JXD-2` and `mixed.sh`'s pin, which
are the same shape in the jit ladder.

Mechanically these are byteIdentical. **Semantically the expected value is known to be WRONG**,
and the claim minted is not *"the output is correct"* but *"the defect is unchanged."* They go
**red on repair**, which inverts the whole meaning of a match. VI's oracle-kind list has no term
for this and it is not a variant of byteIdentical — a claim that cites one as evidence of
correctness would be reading it exactly backwards.

**Proposed: `pinnedDivergence`.** Its distinguishing obligation is a **graduation clause** (H6):
a pin that starts passing must be re-pinned with a *sentence*, never a green diff. That obligation
is grammar-shaped and currently lives only in prose.

### PINCH 4 — CAPTURE IS OFTEN DERIVED, NOT RAW · **SAYABLE, with a note**
Most captures are filtered (`grep -vE "^Search list:"`), sliced (`extract`'s `sed`), or — at
`tree.sh` — **a diff of two other captures**. `capture : bytes` covers all of it, so it parses.
But **nothing in the rule states WHICH filter produced the bytes**, and the filter is load-bearing:
`printPop` captures stderr *only*, deliberately, because a combined capture interleaves by flush
timing rather than event order. That provenance lives in A2 step 3 (divert) and is invisible in
the check. **Not a pinch today; a candidate slot** (`via:`) if filters ever move.

### PINCH 5 — `mixed.sh`'s BASELINE IS AN INLINE LITERAL · **RULE AMENDMENT (small)**
`PINNED_LOST=" leaf alt"` is a baseline that resolves to nothing on disk. It is the right design
— the expected value is three words and a file would be worse — but the rule cannot say it.
**Third kind for `baseline`: `literal`.** Cheap, and it removes the temptation to create a
one-line target file purely to satisfy the notation.

### PINCH 6 — `result : matched | failed` IS INCOMPLETE · **RULE AMENDMENT**
`parkdiff` (iterT3) has **three** outcomes, and the mapping is **inverted**: a match prints
`WOKE`, counts green, and demands graduation; a mismatch prints `park` and counts **neither**
green nor fail. So the fleet as run has a third result state — **parked** — and for parked
instances *matching is the alarm*.

This is not a dirty check; parking is a ruled mechanism with its own doctrine (H6). **The rule's
`result` channel needs the third value**, or parked checks are outside the language. ⚠ And note
it interacts with PINCH 3: `pinnedDivergence` and `parked` are both "the expected value is not the
right value", but they differ in whether an answer has been *chosen* — parked means *nobody has
ruled*, pinned means *we ruled it wrong and are watching it*. **Two states, not one.**

---

## VERDICT ON RULE ONE

**Parses as spelled: 19 of 30 (63%).** All 19 are `generation=committedTarget` with a real file.

**The spelling does not fight the fleet systematically** — VI-7's clause is not triggered, the
rule survives. But it is **sized for one of the two things the fleet actually does**: compare
against a stored artifact (19) and compare two things produced right now (10). The second is not
an edge case at a third of the population, and it mints a different claim.

**Ranked for Tony:** PINCH 1 (amendment, 10 instances, possibly two rules) → PINCH 6 (amendment,
cheap, unblocks parked) → PINCH 3 (new kind, 4+3 instances) → PINCH 5 (amendment, trivial) →
PINCH 2 (**dirty check, fix in `pop.sh` regardless of the grammar**).

---

## SURVEY-ROW NOTES (VI-2's ASSUMED grade, burned down opportunistically)

Comparisons found in the walk that are **neither** `byteIdentical` nor `assertsLine`:

- **`differs`** (`recordPop.sh:49`) — asserts two captures are **NOT** identical. Negated
  byteIdentical, and its purpose is **anti-vacuity**: it proves the record is per-entity, because
  a stale global would pass every other check in that file. **Candidate kind.**
- **`nonempty`** (`recordPop.sh:57`) — the vacuity guard, and ⚠ **its comment states an ordering
  pretension in words**: *"a diff of two empty files passes, which is why this guard runs BEFORE
  any diff."* **This is a live, hand-enforced instance of exactly the structural question next
  round is about** — a rule that must appear in a given position relative to another. The fleet
  already needs `conjunct-only`; it just spells it as a comment.
- **conservation** (`mixed.sh`) — sum-of-parts equals whole (per-rule divergences vs the
  all-installed divergence). Not a comparison against an expected value at all; an **algebraic
  relation among captures**. **Candidate kind, and the one the `capture = kind` lattice was
  already anticipating.**
- **WOKE meta-check** (`parkdiff`) — **confirmed** as a check whose subject is the check
  registry's own state rather than program output. VI-2 nominated it as a candidate; the walk
  finds it real and finds a **second** member (the `_cap`/timeout guard, which asserts *a run
  happened* rather than anything about its content).
- **structured-value assertion** (`formsPop.sh`'s `pixel`) — expected value is a tuple
  (`r255 g0 b0 a255`), not a line and not a file. Possibly `assertsLine` with a compound value;
  possibly the `countRatio` slot VI-2 suspected. **Left open — one instance is not a kind.**

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
