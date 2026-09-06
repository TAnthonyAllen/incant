# The relevance / intelligibility minion — DRAFT, NOT CHARTERED

**Parked 2026-09-08.** Tony's question, not a work order: *can a real minion check comment
entries for relevance and intelligibility — prose that was originally intelligible but may no
longer be, because the code moved underneath it?*

Clay answered yes, with a split matching what a minion can know. This is Clod's answer after
sweeping ~200 blocks across `genParse.rtn` and `jitEmitters.rtn` in one day. **It is a draft. It
is not chartered and nothing here is owed.**

---

## THE ANSWER: YES, IN THREE COLUMNS, AND THE ORDER MATTERS

### 1. PLACEMENT — run this FIRST. Cheapest, and it caught the most.

**Does the block sit above the method it names?** A string comparison, no judgment: parse the
declaration below each comment block, compare it to the name in the block's first line, report
mismatches with distances.

**Measured yield in one day: fourteen.** Ten in `genParse.rtn` — including a FILE header a
thousand lines in and four blocks sitting *below* their own method — and four in
`jitEmitters.rtn`, the worst 1,890 lines from its subject. Every one had been invisible to
reading for weeks; each surfaced in seconds under a script.

⚠ **Nobody proposed this column, and it outperformed the one everybody did.**

### 2. REFERENT — fully minion-grade, and a CANDIDATE GENERATOR, never a verdict

Every identifier, file, `:NNN`, flag and operator the prose names either exists in the current
tree or does not. That is the dangling-pointer check generalised from keys to prose, and it
catches the biggest class by construction: `gNoUnwrap` after 09-05, `tokenize` after 08-31,
`**` as an operator.

⚠ **BUT THE OUTPUT COLUMN CANNOT BE "STALE".** A correct mention of a dead thing is exactly what
an obituary is. The column is **`names X · X exists? · the mention is [live claim | dated
record]`** — and only the first two are minion-grade. The third is the obituary/rationale
distinction, and it was got wrong from a grep before the eight candidates were read.

### 3. NOUN-EXISTENCE — the honest half of intelligibility

Not *"does the sentence still describe what is there"*, which needs the code. **"Does the
comment's subject still exist, and is it still the subject?"**

`jitIfEnd`'s old comment credited PromotePass for something PromotePass does not do — a minion
cannot catch that. But it names allocas in an emitter that has none, and *"does this file contain
an alloca"* is a grep.

**The framing: a minion can check whether a claim's NOUNS are still true. It cannot check whether
its VERBS are.** That remains the human read — and it is a much shorter read once columns 1 and 2
have cleared.

---

## THE ROW THE TABLE CANNOT FAKE

⚠ **A PLANTED CONTROL, or the run is void.** One entry deliberately pointed at something that does
not exist, one pointed at something that does. **If the planted rot comes back unflagged, the table
is void regardless of how good its other rows look.**

This is not ceremony. Every instrument built during the sweep was wrong on its first run — three
void probes, an overlap scan reporting 569 then a vacuous 0, a CodeSite lint reading 0/5, a site
map that silently dropped a shared entry, a bulk edit that reattached every link to the wrong
method. **Not one announced its own failure.** Every one was caught by an adjacent number
disagreeing.

A minion's report is an instrument and inherits H9 and H11 whole.

---

## STANDING RULES, CARRIED UNCHANGED

- **It grades and never rewrites.** Sealed and dated text is not restated.
- **Its output is a table Tony rules on.** One specimen first, then the rest — the shape this week
  used for the convention itself: charter, one entry, read, then the rest.
- **What it cannot test, it marks `unverifiable as written` rather than grading.** That is itself
  useful: an entry that cannot be checked is either doctrine (fine, say so) or rot that has lost
  its evidence.

---

## CORPUS, IF IT IS EVER CHARTERED

`genParse.rtn`'s 56 entries and `jitEmitters.rtn`'s 76, all born `carried, unverified`, all
carrying a `CodeSite`. The `CodeSite` field is what makes column 1 mechanical: it already names the
file and method as data.
