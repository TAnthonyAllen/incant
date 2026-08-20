# The Hook-Rule Registry

**Chartered 2026-08-20 (Tony's ruling, via Clay).** A standing registry, not a census. It was born as
a one-off count during F-31's step zero and was **rechartered the same day**, because the count
turned out to be the wrong question.

## What a hook-rule is

A grammar rule that the **reading machinery itself invokes** — it wears two hats at once: a citizen
of the grammar like any other rule, *and* live plumbing the reader depends on. That dual role is what
makes installing a generated body over it dangerous: the install does not break the rule, it breaks
the hook.

## The rows

| # | rule | site | role | added |
|---|---|---|---|---|
| 1 | `tokenize` | `incant/grammar:34` (constructed `GroupMain.twk:157`, `method = tokenize`) | the tokenizer — turns raw text into tokens for every read. Used by `NamE`, `NumbeR`, `HeX`, `FormaT` | 2026-08-20 |

**Append a row whenever machinery migrates into a rule.** That is the entire maintenance rule, and it
is the reason this is a registry rather than a measurement.

## ⚠ Why the count does not decide anything

**Tony ruled the hook class OPEN**, and the word doing the work is *now*: `tokenize` may be the only
member today, but **self-hosting structurally mints dual-role rules over time.** A language that
parses itself will keep moving machinery into rules, because that is what self-hosting *is*.

So **`defer-the-hook` is refuted as a class fix regardless of what this table counts** — it is
correct for today's grammar and **silently wrong for tomorrow's**, which is the worst failure shape
available: a fix with an expiry date and no alarm on it.

**The measurement agreed by a different route, and is recorded because two independent paths to one
answer is worth more than either.** The census found exactly one member — but found the *siblings'
immunity to be incidental*: `nameSet`, `numberSet`, `counter`, `delimiter`, `Modifier`, `Limit`,
`MEMBERs`, `Any` and `ruleSkipSet` are all built in `GroupMain.twk` the same way, and every one is
safe only because it **carries data** (they are character sets) and the `datA` gate drops it before
installation. `tokenize` carries none. Nothing *exempts* the siblings; they are merely the wrong
shape to be bitten today.

⚠ **SEARCH SPACE, named because an absence claim is only as good as its search:** the founding count
censused **one surface** — rules the bootstrap constructs by name in `GroupMain.twk`, cross-read
against `fbWalk`'s own ENTER/INSTALL trace (59 entered, 43 installed, 16 dropped at the `datA` gate).
**A rule declared in the grammar that the reader nonetheless invokes would not have appeared in it**,
and whether that class is empty was never measured. Any future row may come from there.

## What was selected instead

**Off-rule storage plus explicit activation** — the invariant fix, chosen **on trajectory grounds**:
it is right for a grammar that will keep growing hooks, whatever this table holds. It is the fourth
customer of that ruling, with the napalm, the `BlocK` re-poison, and mid-walk `setParse` binding.
**Pending only Arm A's mechanism promotion before build** (see `docs/fixIts.md` F-31). The verdict
that gated the campaign — F-31 `CONFIRMED` — was **ratified by Tony on 2026-08-20**; the build gate
is Arm A and nothing else.

⚠ **AND THE META-NOTE, because this is the second time in the campaign it has happened: the fix was
chosen by asking what the PROJECT IS, not what the BUG DOES.** The pick-one constraint went the same
way. A bug-shaped question here would have returned *"one member, take the cheap special case"* — the
correct answer to the wrong question.
