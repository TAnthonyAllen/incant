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
