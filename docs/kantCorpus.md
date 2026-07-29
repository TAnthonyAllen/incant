# The kant corpus

*What a round of minion A knows about writing kant. **This is the only surface the loop
may write to.** It starts empty by design — see `docs/minionAHarness.md`.*

**If you are a round of A:** read this first, then `docs/minionAbrief.md`. Everything here
was drafted by an earlier round that has no way to tell you anything except through this
file. If you need something that is not here, **that is the finding** — record it, do not
work around it silently.

Format is `docs/minionAbrief.md`'s claim record. Grade on your **own** provenance, never
on a neighbour's — adjacency is not provenance.

| confidence | a reader should |
|---|---|
| **RUN** | act on it |
| **MEASURED** | act, but respect `asOf` — the tree moves |
| **READ** | act with care |
| **REASONED** | **do not act — check first** |
| **ASSUMED** | treat as an open item |

**A corpus whose claims drift downward over time is rotting**, and that is visible at a
glance. REASONED and ASSUMED are the challenge queue — a finite, named worklist rather
than a re-read of everything.

---

## CLAIMS

*(empty — minion A has not fired. Round 1 is the baseline.)*

---

## BLOCKED

*(empty)*

Assume **IDIOM-GAP** first, **TOK-BUG** second, **KANT-GAP** last. Grep the tree for the
construct before writing any failing test: a limitation claim dies to a working
counterexample faster than to a new test, and the counterexample shows you the idiom
rather than merely proving one exists.

A false gap is **self-sealing** — the workaround works, nobody returns, and the belief is
documented as fact. That is the risk here, not the reverse.

---

## RELATED, AND NOT PART OF THIS CORPUS

- **`CLAUDE.md` bear traps** — tok and build hazards. Best-evidenced claims in the tree;
  they carry real error output. Input, not corpus.
- **`docs/tokClaims.md`** — the B0 tok-claim sweep, in this same format. Input, not corpus.
  Note **CLAIM TOK-1**: a recorded limitation was disproved by shipping code three
  functions away that nobody had looked at. That is the failure mode this corpus is
  built to avoid.
