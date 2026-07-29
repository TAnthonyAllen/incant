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

*Minion A has not fired. The two below are **seeded by foreman deliberately and
by exception**, on Clay's instruction (2026-07-29), because they are hazards a
round would hit before it could possibly discover them, and both were paid for in
real debugging this session. They are **orientation, not absorption** — do NOT
count them when reading whether the corpus is absorbing (`docs/minionAledger.md`).
Round 1 is still the baseline.*

### CLAIM KANT-1 — an intervening rebind silently retargets everything after it
```
statement:   A bare field reference resolves against the MOST RECENTLY BOUND
             field, not against the one the line appears to be about. So a
             rebind between an attach and a later call silently retargets that
             call, and the line still reads as though it operates on the
             original node.
confidence:  RUN
provenance:  GroupMain.twk, Limit's min/max and define's `definitions`:
                 item = strap +% item;      <- item is the attached TERM
                 item.group = grok/counter;
                 item = item.gGroup;        <- item is now the SHARED target
                 modify(item,"+");          <- materialises THAT, never the term
             modify() calls setRuleStuff, so this read as "the term is
             materialised" for as long as the bootstrap has existed. It was not.
             Proved by auditRegistry: 3 terms missing rStuff before the fix,
             0 after. `sh genLadder/pop.sh` -> POP PASSED.
asOf:        2026-07-29
scope:       Covers bare and short-qualified reads in tok. Says nothing about
             whether the rebind itself is wrong -- in every case here it was
             intended; only the LATER line was reading the wrong node.
```
**Same family as `CLAIM TOK-5`** (`docs/tokClaims.md`): in `ruleMethod`, `use input`
followed by `grup = parent` makes a bare `method =` bind to **`grup`**, not `input`.
Two instances now, one in generated code and one in hand-written bootstrap.

> **The tell: a line whose meaning depends on what was most recently bound rather
> than on what it appears to say.** When you attach a node and then want to act on
> it, act on it *before* anything else is bound — or qualify the read explicitly.

### CLAIM KANT-2 — `:=` is incant, and does not parse in tok
```
statement:   `:=` (opSetGroup) is an INCANT operator. It has no meaning in tok
             source (.twk/.rtn) and does not parse there.
confidence:  RUN
provenance:  ruleActions.rtn's aCTionIterate carried `source := input[2];` -- the
             only ` := ` in any .twk or .rtn in the repo. tok emitted
             `FAIL Block at: source := input[2];`, the error CASCADED (single
             pass, no lexer) and GroupRules.h came back with ZERO externs instead
             of 190. Bear-trap #10, and only the extern count caught it.
asOf:        2026-07-29
scope:       The tok spelling of `<-`/opRebind (bind, no byRef, no copy) is
             `target.group = source;` -- opRebind's body is literally
             `target->setGroup(argument)`, and by CLAIM TOK-3 that assignment
             generates exactly that call. The tok spelling of `:=` proper, WITH
             the byRef stamp, is not established here and was not needed.
```
**Three languages share this tree — tok, C++ and incant — and their syntax bleeds.**
Before editing a line, confirm which language it is by checking a
known-same-language neighbour. When a tok error makes no sense, suspect
wrong-language syntax first.

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
