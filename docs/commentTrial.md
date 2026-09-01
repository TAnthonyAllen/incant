# The comment trial — tally

**Opened 2026-09-01.** Tony's proposal, Clay's refinements, recorded in `CLAUDE.md` under
*"LONG METHOD COMMENTS GO TO DesignDocs"*. This file is the trial's whole evidence and it retires
with the trial.

## WHAT IS BEING TESTED, in one sentence

That a long method comment can be replaced by **one inline claim plus a `method.slug` key**, with
the argument living in `incant/designDocs` — without anybody losing the argument when they need it.

## ⚠ THE QUESTION THE TALLY ANSWERS, AND IT IS NOT "DID WE WRITE THE ENTRIES"

**Was the pointer ever followed?**

| outcome | what it means | what happens next |
|---|---|---|
| entries written, **lookups zero** | the short line was all anyone needed | **the doc half can go.** Keep the one-liners, drop the ceremony |
| lookups happen and the entry is **there** | the split is working as designed | keep it; consider the dangling-pointer fleet row |
| lookups happen and the entry is **missing** | this is the *"deal with it then"* | **the fleet row earns its place** — log it here, do not stop to build it |

**Both columns are needed.** Entries-written alone measures diligence, not usefulness — and a count
of things produced is exactly the shape of an instrument that cannot fail. Same family as rule H4:
the interesting quantity is the one that can come back zero.

## ENTRIES WRITTEN

| date | key | method / site | why it was long enough to move |
|---|---|---|---|
| 2026-09-01 | `GroupItem.getGuard` | `GroupItem.twk:488` | the getter/setter split: the census that settled Tony's 5 vs Clod's 6, why three of five calls are the method's own recursion, and why the 17× mirror hazard cannot arise here |
| 2026-09-01 | `GroupItem.ensureGuard` | `GroupItem.twk:494` | why `setRuleStuff` stays on line 1, what the split does and does not cure, and where anyone reopening it should start |
| 2026-09-02 | `Instruct.opDot.accessorGate` | `Instruct.rtn` | the jit gate for the whole accessor family, and why finding #3 looked like a condition bug |
| 2026-09-02 | `Instruct.opDot.cases403to404` | `Instruct.rtn` | the guard that dereferenced the pointer it guarded — exit 139, CLAIM KANT-18 |
| 2026-09-02 | `Instruct.opDot.case405firstMember` | `Instruct.rtn` | why `.firsT` returns the ATTRIBUTE, CLAIM KANT-17 |
| 2026-09-02 | `Instruct.opDot.case42hasTraits` | `Instruct.rtn` | why hasTraits is not hasAttributes, and the write halves |
| 2026-09-02 | `Instruct.opDot.case407binType` | `Instruct.rtn` | binType is an enum; why nonzero is the right width |
| 2026-09-02 | `Instruct.opDot.case408isAction` | `Instruct.rtn` | why 406 cannot witness the isCoded → isAction transition |
| 2026-09-02 | `Instruct.opDot.case41hasNewParse` | `Instruct.rtn` | why the read and write halves ship together |

## LOOKUPS CLOD ACTUALLY MADE

| date | key sought | found? | what it was needed for |
|---|---|---|---|
| — | — | — | *none yet* |

## STANDING NOTE — THE FIRST MIGRATION CANDIDATE, IF IT IS EVER TOUCHED

`GroupItem.twk`'s `getRStuff` header is **~55 lines** as of 2026-09-01 and is the largest comment
Clod has written recently: the purity ruling, the deleted-warn history, the C2/C3 graded caller
table, and the complaint recipe. **It is NOT being migrated** — the trial is going-forward only and
that comment is now "existing". It is named here because it is the obvious first candidate the day
anyone edits that function, and because it is a good calibration for the too-short test: the claim
is *"pure getter, does not construct — every bare `.rStuff` read routes here"*, and everything else
under it is argument.


## ⚠ FIRST FINDING, ON THE FIRST ENTRY — THE REGISTER ALREADY EXISTED

The convention was first written as `method.slug` with entries under a new `MethodNotes` member.
**`TokFiles` was already there** — `TokFiles → Generate → parseAny / parseSetLabel / labelMinters /
runRuleAction / setParse` — and its own text reads *"The comments cluttered up code. Now they do
not. They are here."* Tony had built this register already; the convention is **that register
named**, not a new one.

`MethodNotes` would have been a second population for one subject, which is the duplicate-register
failure `CLAUDE.md` warns about — committed by the seat writing the warning down. It was caught by
reading `designDocs` before writing to it, and only because a **parse failure** forced a second look:
the first attempt used `"..."` strings, which do not carry apostrophes, and died with bear-trap #32's
misdirection — `RunRulE: expected a method not DisplayDesignHTML`, naming the file's first and
perfectly healthy entry.

**Three things the trial learned before its first lookup:** prose entries use the `(…#)` literal,
never a quoted string; the key is the **tree path** `File.method`, because that is what the tree
already is; and **`#` is the only working delimiter** — `docs/forms.md` promised a flexible one and
was corrected on measurement, matrix included. The `Modifier`-set explanation for *why* was raised
and falsified in the same run, so the symptom is recorded and the cause is open.


## THE PRACTICE STROKE — `opDot`, 2026-09-02

**Seven long comments migrated. `opDot` went 130 lines to 85 — 45 lines saved, a 35% cut**, and
every claim an editor at a case site must not miss is still inline.

**Certificate:** fleet **byte-identical row for row**, `oneTest` and `jsonTest` byte-identical on
stdout and stderr, all POPs green, canary 326. Comments cannot change behaviour, so the only way
this breaks is tok choking on one — which fails the build in your face. It didn't.

### ⚠⚠ RATIFIED BY TONY, 2026-09-01 (SEQ 103 Part 1) — THE REVIEW ROW IS CLOSED

Tony reviewed the `Instruct.rtn` / `opDot` migration and the DesignDocs entries it produced.
**Verdict: "Reviewed. Looks good."** Ratified; nothing owed back on it.

**AND THAT SETTLES THE TWO-LINE QUESTION, which the last seal recorded as UNRULED and named as a
blocker on the `ruleActions.rtn` sweep.** The exemplar below took two inline lines for two of the
seven comments, on the ground that a single line could state the fact but not the consequence.
Reviewing the exemplar and approving it approves that. **So the rule is: ONE CLAIM, however many
lines the claim honestly needs — the convention is about moving the ARGUMENT out, not about a line
count.** Two is not a licence for three; the acid test is still the acid test, and both two-liners
here are load-bearing invariants (a segfault and a silent wrong answer).

⚠ **ONE BLOCKER REMAINS ON THE SWEEP AND IT IS NOT THIS ONE.** `docs/commentMinion.md` is signed
with schema v2 and Tony's **method-scoped-not-file-scoped** amendment, while this exemplar uses
`TokFiles`. **Two conventions, one job** — still unreconciled, and the sweep does not open until it
is. That is a ten-minute ruling, not a build.

⚠ **DATE NOTE:** the nine rows in the table above are stamped `2026-09-01` / `2026-09-02`. The
machine says those entries were all written on **2026-08-31** — see the seal-date drift ledger at
the head of `docs/wakeup.md`, where the same two-day prose drift is measured across six seals. The
rows are **left as written** rather than restated; read `09-02` as `08-31`.

### What resisted the format — one thing, and it is worth knowing before the sweep

⚠ **Two comments could not shrink to one line and were given two**, because the acid test wouldn't
let them: `cases403to404` carries a **segfault** invariant (the `groupList &&` prefix is
load-bearing) and `accessorGate` carries a **silent-wrong-answer** one. A single line could state
the fact but not the *consequence*, and the convention's own test says a line that lets someone
break the invariant without following the key is too short. **Two lines is still one claim** — the
rule is about the argument moving out, not about a line count.

### What went easily

The four enum/flag cases (42, 407, 408, 41) compressed cleanly — each was one distinction wrapped
in six lines of justification, and the distinction *is* the claim.

### The idiom that worked, for whoever sweeps the rest

`//` comments sit safely **immediately above a `case` label** — verified by the build, and worth
recording because bear-trap #4 makes `//` placement a live question and bear-trap #29 makes
comment *position* fatal in an `if`/`or` chain. A switch is not that construct. **The header keeps
its short base description; only the long sections move.** And claims travel to the **case site**
rather than staying in the header, because that is where an editor is standing.
