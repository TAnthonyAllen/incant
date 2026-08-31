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
| — | — | — | *none yet — the trial starts at the next long comment Clod would have written* |

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
