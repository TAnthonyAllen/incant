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

⚠ **TWO CAUSES, AND THEY EXPLAIN DIFFERENT HALVES — do not merge them** (measured 2026-08-20, F-31
Arm A):

| the cause | what it explains |
|---|---|
| **the DUAL ROLE** | **the collision.** A rule the reader depends on gets a body installed over it while the reader is still using it. This is the hook-rule property, and it is why this registry exists |
| **TERMLESSNESS** | **the degenerate body.** `tokenize` is declared `tokenize^@;` with **zero terms**, so the generator emits `if `, finds nothing to loop, and produces `{ if  return runRuleAction(this); }` — an `if` with no condition. Charted separately as **F-33** |

The two compound: a hook that is *also* termless gets a body **incapable of doing the hook's job**,
and the measurement is the C++ `tokenize` going **2 calls → 0** during the poisoned compile against an
unchanged whole-run total. **But a hook WITH terms is still a hook**, and installing over it is still
wrong — which is exactly why the fix was ruled on the dual role and not on the body.
**When adding a row, note whether the rule carries terms** — it tells you how *loud* the failure will
be, not whether there is one.

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

---

## ⚠ THE DECORATION-CHANGES-CLASSIFICATION PAIR — two populations, two convictions

Adopted 2026-08-23. Both members were found the same way: a node was given something extra that
was believed inert, and the extra thing changed what the node **was**.

| population | the decoration | what it changed | the receipt |
|---|---|---|---|
| **grammar nodes** — the bare-hook class | an installed `CodE`, i.e. the rule's **first attribute** | a bare method-hook flips to an attribute-matcher and its method stops being fired at all | install #43 on `tokenize`: `hasAttr 0 -> 1`, and `Braced` — which already had attributes and gained the same `CodE` — did **not** flip |
| **product nodes** — products stay leaf | a `noPrint` attribute hung on a rule's product | a `NumbeR` product that gains a child stops evaluating as a number; `+=` adds nothing and the enclosing loop never advances | `captureSpan` = `setToken` + attach → 48 green and `baselineTests` never terminates; `setToken` alone → 52 green, reproducer reads 15 then 17 |

**PRODUCTS STAY LEAF.** A product consumed as a *value* must carry no children. The attribute that
broke this was ruled in as *"free debug surface"* and it was not free — it was the entire defect.

⚠ **THE MECHANISM IS UNCLAIMED IN BOTH ROWS AND THE DOCTRINE DOES NOT NEED IT.** Nobody has traced
why a child breaks the arithmetic, and nobody traced the hook's arm-flip past the flag reading. Each
row stands on a **cleave** — three states, one variable each, the set site counted in the
*generated* file before every run — not on a story. Three mechanisms that fit these symptoms
perfectly were killed on contact before the cleaves were run; the cleaves are why the doctrine is
safe to state and the mechanisms are not.

**The practical rule for anyone adding machinery:** before you decorate a node, ask which population
it belongs to and what reads it. A flag is free; a **child is not**.
