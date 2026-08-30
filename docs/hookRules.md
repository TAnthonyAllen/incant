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

| **sub-terms** — labels are for readers | a **label** minted by a sub-term nobody reads | the label is attached to the parent's product and persists once the collapse that swept it is gone | `NamE`'s `first-` / `nameSet-` carry the noLabel dash and were immune throughout; `NumbeR`'s `numberSet=` was labeled and was not. Respelling with the dash: load census 42 → 4 |

**LABELS ARE FOR READERS.** A sub-term whose label no reader consumes carries the **noLabel dash**.
That is shipped, decade-green machinery — `NamE` has spelled it that way since the beginning, which
is the entire reason `NamE` migrated clean and `NumbeR` did not.

**The practical rule for anyone adding machinery:** before you decorate a node, ask which population
it belongs to and what reads it. A flag is free; a **child is not**; and a **label nobody reads is a
child waiting to happen**.

⚠ **AND THE EPITAPH, because all three rows are one sentence in three spellings: THE SYSTEM USED
ABSENCE AS A CHANNEL.** A bare hook meant *I am live machinery*; a leaf product meant *I am a
value*; an unread label meant *nothing*. Uniform progress erased the absences — an install gave the
hook its first attribute, a capture gave the product its first child, a retired janitor stopped
sweeping the labels. **Every fix this campaign shipped is the same fix: say the thing explicitly.**
A flag instead of bareness. `setToken` instead of decoration. A dash instead of an unread label.
**Absence is not a channel.**

---

# Doctrine rows registered 2026-08-30

These are not hook-rules. They are registered here because the dictation ruled that the pair
belongs in **one row rather than three scattered files**, and this is the standing registry.

## ⚠ PROBE PLACEMENT INHERITS THE CONCLUSION — the observational twin of H7

**A probe placed downstream of the predicate it is testing can observe only one outcome, so its
silence is structurally guaranteed rather than measured.**

H7 asks whether a mechanism can be shown to **fire** before it is trusted. This is the same
question asked of the *instrument*: **can it observe both answers?** An anti-vacuity-clean
assertion can still be fed by a one-outcome probe, and then the assertion is honest about a
measurement that was not.

**The instance that funded it, 2026-08-30.** A `cerr` was placed inside `opDot`'s
`if product && !product.parent` guard to ask whether the trailing parent stamp ever lands on a real
node. It reported the two substituting cases as **firing zero times**. Moved *above* the guard, the
same binary on the same corpus reported **33 arrivals**, with the dangerous event still at zero.

**Same conclusion. Opposite epistemic status.** The first was a probe that could only print when the
stamp fired; the declined class could never reach it, and its silence was read as absence. A whole
mechanism story — a coupling to another citizen — was built on that silence and had to be struck.

**THE RULE: argue a probe's placement before you read its silence, and print unconditionally on both
sides so a decline is as visible as a fire.**

⚠ **AND IT IS HALF A PAIR.** The other half is the `frameProbe` lesson of 2026-08-29, which points
the same way from the opposite side: *a doctrine row whose control has been thrown away is a claim
nobody can re-check*, which is why the stale-singleton reading was **kept on the same line** as the
four correct ones. One says *put the instrument where both answers can reach it*; the other says
*keep the wrong answer visible beside the right one*. **Both are about where the evidence sits, not
what it says** — and neither is caught by reading the assertion.

## ⚠ `!` WALKS FREE A SECOND TIME — the culprit is the capture, and the split will cure it

**`!` has now been suspected twice and exonerated twice, and both times the real fault was reading a
property through a capture that reimprints.**

| occasion | suspected | actually |
|---|---|---|
| bear-trap #35's six-way table | `!` on an `opDot` result | reading the property **in the condition**; `== 0` failed identically and `!` on a captured local was fine |
| 2026-08-30, the parent census | `!` again (architect's instinct) | `local = node.parenT` then `local.taG` — **the assignment reimprints the local's tag**, so the read answers with the holder, never the held |

The 2026-08-30 probe that failed was in **positive** form — `if x.parenT … else …`, printing
*neither* arm — so the negation is exonerated by the shape of its own failure.

⚠ **AND THE CULPRIT HAS A NAME THIS PROJECT ALREADY RULED ON.** A capture answering with the
holder's tag instead of the held value is **identity and storage sharing one struct**, observed from
the probe side — the same conflation the `GroupBody` split was ruled to cure. `tag` lives in
`GroupBody`; a copy takes the body; the copy therefore takes the name.

**So the split does not only fix binding — it fixes PROBING.** After it, a captured local cannot
reimprint a tag it no longer carries in shared storage, and the commonest way an instrument lies in
this codebase stops being constructable. **In a shop whose failure ledger is mostly instrument-level,
that may be the split's largest dividend** — and it is worth saying out loud, because it is not the
reason the split was ruled and it will not otherwise appear in its motivation record.
