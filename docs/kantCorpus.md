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

### CLAIM KANT-3 — TWO INDEX SPACES: a rule action indexes the LABEL, the audit indexes the TERM LIST
```
statement:   Positional access inside a RULE ACTION (`input[1]`, `input[2]`)
             indexes the LABEL the parse built -- NOT the rule's term list. A
             `-` (noLabel) term produces no label, so it HOLDS A SLOT in the term
             list and is ABSENT from the action's view. The two are different
             structures with different numbering, and both are correct.
confidence:  RUN
provenance:  Tony's ruling, 2026-07-29, and both halves are observed:
               term list   `audit` walks it -- Limit[2] is `min`, with the
                           bracket literals occupying [1] and [4].
               label       aCTionIterate reads `field = input[1]`,
                           `source = input[2]` and is CORRECT, because
                           incant/grammar:156 writes
                             Iterate "iterate"- ANYtoken "on"- ANYtoken ...
                           BOTH literals dashed. The dashes are what MAKE the
                           indices right; without them the field lands at [2].
asOf:        2026-07-29
scope:       Applies to positional access. wakeup.md's "rule[i] is source order,
             1-based" is about the TERM LIST and MISLEADS anyone applying it
             inside an action.
```
**Note for genParse, and it is a live hazard rather than a curiosity:** emitted
code (`t1 = rule[1]`) reads the **term list** — which is what the baked indices
and `RuleStuff.termCount`'s count guard exist for. So genParse has **two index
spaces in one subsystem, and the count guard protects only one of them.**

### CLAIM KANT-4 — GroupBody's value slots are ONE UNION: a counter overwrites a pointer
```
statement:   gCount, gGroup, gNumber, gText/gPointer, gBuffer, gCharacter,
             gCharacterSet, gItem, gMap, gObject, gRegex and gStak all share
             storage in GroupBody. Writing any one DESTROYS whatever another was
             holding. A node cannot carry a counter AND a group reference.
confidence:  RUN
provenance:  GroupBody.h:107-130, three unions. Paid for: a runaway-abort counter
             stored in `iter.gCount` overwrote the iterator's cursor, which lives
             in gGroup -- nextGroup then dereferenced a garbage pointer and the
             process died at EXIT=139 with no output (stdout buffered away by the
             crash). The guard destroyed the state it existed to protect.
asOf:        2026-07-29
scope:       A GroupBody fact, NOT an iterator one. Any new per-node counter,
             flagword or scratch value is unsafe on a node already using another
             slot of the same union. Booleans are fine -- `flags` is a separate
             bitfield, outside the unions.
```
**How it was caught, which is the transferable part:** the crash arrived immediately
after a new nested fixture, and the obvious story — that the fixture's *reference
terms* were at fault — fitted the backtrace exactly and was wrong. What killed it
was **re-running a control that had passed before**: a plain two-entry leaf, no
references anywhere, crashed identically. A passing case re-run beats reasoning
about the new structure.

### CLAIM KANT-5 — recursion saves locals, but ONLY for DIRECT self-reference
```
statement:   An action's locals are saved/restored across recursion only when
             `field.recursive` is set, and that flag is INFERRED at parse time by
             a test for DIRECT self-reference. Mutual recursion (A->B->A) sets it
             on neither action, so no save happens and re-entry clobbers the live
             frame's locals.
confidence:  RUN
provenance:  Inference site aCTionTokenXP, ruleActions.rtn:882 --
                 if processingCode
                     if ANYtoken.groupBody == currentMETHOD.groupBody
                         currentMETHOD.recursive = true;
             an identity test against currentMETHOD. Consumed in runAction
             (GroupActions.rtn) as `if field.recursive saveLocalFields(field)`.
             POPs: incant/iterT1 direct recursion over a nested tree -> 7 visits
             in exact order, PASSES. incant/iterT1m, the SAME tree and the same
             expected trace routed through two mutually recursive actions -> 4,
             FAILS: the outer walk never resumes after the nested subtree.
asOf:        2026-07-29
scope:       Per-frame locals are a PROPERTY for direct recursion and a CHECKLIST
             for mutual recursion. Says nothing about depth -- direct recursion
             nests correctly to at least three levels with cursors coexisting.
```
**The predicate is the bug, not the mechanism.** Save/restore works; it is asked the
wrong question. "Does this action's body syntactically name itself?" is a parse-time
approximation of "am I re-entering a frame that is still live?", which is a *runtime*
property. A dynamic re-entrancy test would cover every recursion shape and need no
inference at all.

**And the underlying save/restore bug was latent for the same reason:** it only bites
a local carrying a LIST, and iterators are the first locals to keep state in a child.
Worth knowing whether any existing recursive action holds list-carrying locals — it
would have been silently losing attributes.

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
