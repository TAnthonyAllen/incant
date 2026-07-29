# The attic — a manifest, not a pile

*`docs/mdReorgB0.md` §5. Tony ruled deletions must be recoverable. **Git already holds
every deleted line permanently**, so a pile holding content would be a second and worse
copy — and would recreate the accretion the reorg exists to end.*

What git does **not** give is discoverability: you cannot grep for *"things that used to
be in docs."* That is this file's whole job. One line per removal:

```
what · when · why removed · commit that still holds it
```

Recovery is one `git show <commit>:<path>`.

**Delete authority is granted, scoped:** nothing may be removed whose landing commit
cannot be named. **The shutdown task is a review, not a purge** — content never leaves
git, so "final delete" means closing the review window: walk the manifest, confirm
nothing is wanted, Tony signs, clear it.

---

| what | when | why removed | commit that still holds it |
|---|---|---|---|
| `genParse.rtn` `setParseMethod`'s passthrough justification — *"Passthrough because tok has no syntax for casting a void\* to a typed fnptr member, and parseMethod is typed by construction (bear-trap #20)"* | 2026-07-29 | **FALSE.** Disproved by CLAIM TOK-1 (`docs/tokClaims.md`): tok emits the cast itself from the member's declared type, and `ruleMethod` has shipped that construct since before the claim was written (`GroupActions.rtn:451` → `GroupRules.mm:5632`). | **`e261e5d`** *genParseShape steps 3-7: term-first library, parseR, indexed emit, binding, POP* — the commit that introduced the text. |

### Entry 1 — status, stated precisely

**Superseded in place, not yet deleted.** Tony annotated the correction directly beneath
the original on 2026-07-29 rather than removing it, so `genParse.rtn:1071-1082` currently
carries **both** the false justification and its correction. This row is filed now so the
manifest exists and is exercised; the row's `when` is the date the claim died, not the
date the text goes.

The deletion itself belongs with the `setParseMethod` rewrite, which is **not B0's** —
B0 grades, records, and queues (§7). Two things the rewrite owes, both recorded in
CLAIM TOK-1 so they cannot be lost with the comment: the passthrough uses `RTLD_DEFAULT`
(not `ruleMethod`'s `RTLD_SELF`), and it NULL-checks the address and reports
`setParseMethod: ERROR no method found %s` on stderr before returning 0. The one-line
replacement drops that diagnostic.

Note what does **not** go with it: the same doc-comment's appeals to bear-trap #13
(passthrough prunes incant-level locals) and bear-trap #14 (stderr, not stdout) are
**sound and survive** — see CLAIM TOK-4. One paragraph, three claims, one false.
Adjacency is not provenance in either direction.
