# The `star=field*` → `star?=field*` promotion — recon, 2026-09-03 (SEQ 149)

**RECON ONLY. NOTHING WAS EDITED.** No build, no grammar change, no code change. Every claim below
is a read of the current tree or a consequence of the fleet's own observed behaviour; the two things
that would need an instrumented run are named as such and were not run.

---

## 1. VERDICT: LIVE, and `getWhatFollows` is not retired

`getWhatFollows` is **live**, `RuleStuff.twk:230` → `RuleStuff.mm:1244`. Two callers:
`GroupItem.twk:774` (`if !followed getWhatFollows();`) and `RuleStuff.mm:1270`.

**The promotion is one line**, `RuleStuff.twk:244`, in the `isEmbedded` arm:

```
or isEmbedded {
    if (data && data < 4) || max == 1 isTarget = true;
    if !min && parent.min && parent.allAttributesOptional()   parent.min = 0; }
```

Read it as: *this embedded term is optional* (`!min`) **and** *the parent is currently mandatory*
(`parent.min`) **and** *every one of the parent's attributes is optional* → **the parent becomes
optional too.** `allAttributesOptional()` is `GroupItem.twk:1047`, and its own header states the
conservative rule it implements: an attribute with no `rStuff` yet counts as **mandatory**, because
it has not had a chance to relax the `min = 1` that `RuleStuff(GroupItem)` sets at `RuleStuff.twk:135`.

`min` itself is written by exactly one thing besides this line and the constructor: `modify()` in
`GroupActions.rtn`, where **both** `*` (`:799`) and `?` (`:802`) set `min = 0`. So on the term
itself the two modifiers are already indistinguishable — the promotion is entirely about what
happens to the **parent**.

---

## 2. ⚠ IT DESTROYS ITS OWN EVIDENCE, WHICH IS WHY "WHICH RULES" IS THE HARD HALF

After the promotion fires, `parent.min` reads `0` and **nothing anywhere records that it used to be
1**. There is no flag, no counter, no second channel. So a census of live `min` values cannot
separate *declared optional* from *promoted*, and any table built that way would be a confident
tautology.

**Naming this rather than working around it, because a number produced by that census would look
exactly like an answer.** The definitive list needs one instrumented run — a counter or a `cerr` at
`RuleStuff.twk:244` naming `parent.tag` — and that is an edit, so it was not done.

**What CAN be said read-only** is the candidate set: rules every one of whose `=`-labelled terms
carries `?` or `*`. Over `incant/grammar` there are **three**:

| line | rule | labelled terms |
|---|---|---|
| 56 | `debug` | `rules=NamE*` |
| 165 | `DEBUG` | `rules?=NamE+` |
| 169 | `FOR` | `reversE?="<-"` |

⚠ **THIS IS A CANDIDATE LIST, NOT THE FIRING LIST, and the gap is named:** it was computed over
`=`-labelled terms, while the mechanism walks `nextAttribute`. Those two sets coincide only if every
`=`-labelled term is an attribute and no rule reference is. That is consistent with
`getWhatFollows`'s own `if isMember … or isEmbedded` fork, but it is **not measured**, and
`genLadder/parseClass.target` cannot settle it — it reports parse classification, not affiliation.

⚠ **`FOR` IS THE ROW THAT MATTERS AND THE ONE MOST LIKELY TO BE A FALSE CANDIDATE.** Its other
terms — `Looper`, `ExpressioN`, `LoopRestrict?`, `StatemenT` — are rule references. If any of them
is an attribute with `min 1`, `allAttributesOptional()` returns false and `FOR` is never promoted.
If none is, then **`FOR` — a statement — is optional**, which is a much larger claim than this recon
can cash.

---

## 3. EMPTY-versus-MISSING: NO READER DISTINGUISHES THEM, AND THE GUARD IS WHAT SAVES IT

**The label is minted BEFORE the match, not after.** `RuleStuff.twk:199-206` sits in **`checkInput()`**
— which `GroupItem match()` calls to validate the input and the guard — and it mints
`label = new(tag); label.isLabel = true;` whenever `sukcess` holds there. The **token** is stamped
much later and under a different condition: `RuleStuff.twk:327`,
`if counter && counter >= min  label.setToken(hereAt,counter)`, inside `if counter && …`.

**So a term that matched ZERO times can own a label node that was never tokenised** — present, and
carrying no data. Bear-trap #26 then applies in full: `.text` on it returns **its own tag**. A
reader asking `if label` gets true, and a reader printing it gets a plausible word.

⚠ **AND NO READER OF THESE LABELS TESTS ANYTHING ELSE.** `aCTionFOR` (`ruleActions.rtn:693, 726`) is
the worked example, and it is a bare pointer test:

```
reversE = input["reversE"],
…
while grup = reversE ? LoopOn.prior(grup) : LoopOn.next(grup) {
```

If an unmatched optional minted an empty label, **every `for` loop in the system would run
backwards.** They do not.

**THE THING THAT PREVENTS IT IS THE GUARD, NOT THE MATCH.** `checkInput`'s `sukcess` requires
`unGuarded`, or `guarded && guardSet.contains(*atRuleMark)`. For a literal like `"<-"` the guard set
is effectively `{'<'}`, so on any other input the guard fails, `sukcess` is false, and **the label is
never minted at all**. Missing stays missing.

⚠ **SO THE SAFETY OF EVERY PRESENCE-TESTED OPTIONAL LABEL RESTS ON ITS GUARD.** The hazard set is
*optional labelled terms that are also unguarded* — `_` (unGuarded) or `{` (upTo, which sets
`unGuarded` as well, `GroupActions.rtn`). **Censused: that set is EMPTY today.** The only `_`/`{`
hits in the grammar are the two character-class definitions at lines 30 and 60 that contain those
characters as set members, and the three `upTo` terms (`quoteBody}`, `rightBrace}`, `dtext^}`) are
none of them optional.

**Nothing is broken. But nothing is checked either** — no fleet row asserts that this set stays
empty, and the day an optional labelled term acquires `_` or `{`, every presence test on it silently
inverts.

---

## 4. ONE PIECE OF DRIFT FOUND IN PASSING, NOT FIXED

The `FOR` rule is written **two different ways** in two places, and the copy in the source comment
is the stale one:

```
incant/grammar:169    FOR  for- followedBy Looper in- reversE?="<-" ExpressioN SemI- LoopRestrict? StatemenT defer;
ruleActions.rtn:685   FOR  for- followedBy Looper in- reversE="<-"? ExpressioN SemI- LoopRestrict? BLOCKing- StatemenT defer;
```

Two differences: the `?` sits on the **label** in the live grammar and on the **term** in the
comment, and the comment carries a `BLOCKing-` term the live grammar does not have. The comment is
documentation only — `incant/grammar` is what runs — but it is the rule a reader of `aCTionFOR`
would take as authoritative. **Reported, not edited.**

---

## 5. WHAT WOULD SETTLE THE OPEN HALF

One `cerr` at `RuleStuff.twk:244` naming `parent.tag` when the promotion fires, one bare build, one
run of the corpus, then revert. That answers §2's firing list exactly and would also confirm or kill
`FOR`. It is an edit, so it was not done.
