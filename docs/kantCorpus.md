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

**ROUND 1 HAS FIRED (2026-07-29). Which claims are ORIENTATION and which are
ABSORPTION — get this right or the ledger's instrument reads noise:**

| claims | origin | count them as absorption? |
|---|---|---|
| **KANT-1 … KANT-5** | **seeded by foreman**, deliberately and by exception, on Clay's instruction (2026-07-29) — hazards a round would hit before it could possibly discover them, every one paid for in real debugging that day | **NO.** Orientation. |
| **KANT-6 … KANT-12, KANT-B1** | **drafted by round 1** (`emitLeaf` → kant) | **YES** — and round 1 is the BASELINE, so they are the zero, not a rise |

*(The header this replaces said "A has not fired" and "the two below" — both went
stale the same day, the second when KANT-3/4/5 were seeded after it was written. A
stale count here would have had round 2 reading three of foreman's own claims as
round 1's absorption.)*

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

*Everything below was drafted by **round 1** (method: `emitLeaf` → `incant/genEmit`'s
`spellLeaf`, target `genLadder/spell.target`, 2026-07-29). Unlike KANT-1..5 above,
these are absorption, not seeding.*

### CLAIM KANT-6 — recursion is spelled `this(...)`; the SELF-NAME spelling does not survive the C++ seam
```
statement:   In a coded action reached through the C++ `runAction` seam, writing
             the action's OWN NAME in its body to recurse fails. `this(arg)` --
             the isLocal `this` field every coded field is given at define time
             -- recurses correctly and is the spelling that works.
confidence:  RUN
provenance:  incant/genEmit's spellLeaf, driven by `incant/spellScratch`
             (dumpSpellings -> emitLeaf -> spellKant -> runAction).
               `piece = spellLeaf(wrapped);`  ->  first invocation prints
                   GroupItem add: Tried to add spellLeaf to itself
                 and dies EXIT=139, with the run truncated after `fold SEQ`.
                 Reproduced with the call unreachable (`if kind == "NEVER";`),
                 so it is a BODY-PARSE effect, not a runtime one.
               `piece = this(wrapped);`  ->  EXIT=0 and
                 `sh genLadder/pop.sh` reports spell.target byte-identical.
             Mechanism READ off GroupRules.mm:582-608 (aCTionNamE): a bare name
             that locateInMethod resolves to something NOT isArgument/isLocal is
             re-attached with `action->addAttribute(result)`; when the name IS
             the action, that is add-to-itself, GroupItem.twk:62 refuses it and
             returns null, and the call then dispatches on an empty node.
             `this` escapes it by being isLocal (ruleActions.rtn:193-195,
             `grup = NewGroup += "this"; grup.group = NewGroup;`).
asOf:        2026-07-29
scope:       The DISCRIMINATOR IS NOT SETTLED and do not assume this is a
             universal ban on self-naming: `walk` in incant/iterT1 self-names
             and works (7 visits, correct order, POP-green), and so do
             listRules/toXML/flatten/printDefinition in incant/utilities and
             incant/unitTests -- none of which is invoked from C++. MEASURED:
             the same spellLeaf body compiled clean when its FIRST invocation
             came from an ordinary incant statement added to genEmit
             (`spellLeaf(spellWarm);`), and still compiled clean with
             `search Spellers list;` in front of it -- so "is the name
             resolvable" is NOT the discriminator either. What is established is
             only that the self-name spelling is unusable at THIS seam, and for
             two independent reasons (see CLAIM KANT-8).
```

### CLAIM KANT-7 — `this(...)` recursion does NOT get per-frame locals
```
statement:   Recursing via `this(arg)` does not set `field.recursive`, so no
             save/restore happens and the inner frame overwrites the outer
             frame's locals. Nothing may read a local after a `this(...)` call
             except the call's own result.
confidence:  RUN
provenance:  spellLeaf's OPT branch, probe added after the recursive call:
                 leaf = string $"(" piece _ "|| 1) k=" kind;
             printed `k=CALL` for ScafE and `k=LIT` for ScafF -- the INNER
             frame's kind -- where the outer frame's own value is OPT. Expected
             from CLAIM KANT-5's mechanism: the inference (ruleActions.rtn:882)
             is a syntactic identity test of the named token against
             currentMETHOD, and `this` is a different node, so it never fires.
asOf:        2026-07-29
scope:       This is the PRICE of KANT-6's fix and the two claims must be read
             together: the spelling that compiles is the spelling with no
             per-frame locals. Says nothing about depth -- spellLeaf recurses
             exactly one level (planTerm cannot nest an OPT inside an OPT), and
             `piece` is safe only because the inner frame never assigns it.
```

### CLAIM KANT-8 — with `recursive` set, returning one of the action's OWN LOCALS returns an EMPTIED node
```
statement:   When `field.recursive` is set, runAction calls
             restoreLocalFields(field) AFTER processAction and BEFORE returning
             the result. If the result IS one of the action's locals -- the
             normal way a kant action returns a value -- the caller receives that
             local reverted to its pre-call state, i.e. empty.
confidence:  RUN
provenance:  The self-name variant of spellLeaf, run with a warm-up call so the
             KANT-6 crash was dodged: EXIT=0, and EVERY row of spell.target came
             back as the bare local tag --
                 LIT sink=label leaf          (expected: lit(t1,"x"))
                 CALL sink=label leaf
                 MANY sink=label leaf
             including the LIT rows, which never execute a recursive call. An
             in-body probe confirmed the body ran and assigned: it printed
             `OPTBRANCH entered` / `OPTBRANCH back` and still returned `leaf`.
             Mechanism READ off GroupActions.rtn:570-573 --
                 if field.recursive      saveLocalFields(field);
                 result  = processAction(field);
                 if field.recursive      restoreLocalFields(field);
                 return  result;
asOf:        2026-07-29
scope:       Bites any recursive kant action that returns a local, which is the
             only return idiom in the tree (utilities' hexToNumber, unitTests'
             testNew). It does NOT bite an action that only mutates its argument
             -- walk/toXML/listRules all return nothing anyone reads, which is
             why this survived. Not verified whether returning the ARGUMENT
             instead of a local dodges it; that is the obvious next probe.
```
**FOREMAN ADDITION (2026-07-29), and it does not count as round-1 absorption.**
*Independently confirmed on a fixture with no `spellLeaf`, no C++ seam and no
warm-up call — two actions with IDENTICAL bodies, one carrying an UNREACHED
self-mention so `recursive` is inferred and nothing else differs:*
```
CONTROL   (no self-mention)   ->  <tripletriple>     the value survives
RECURSIVE (self-mention)      ->  tagged             the value is GONE
```
*That is a stronger provenance than the claim shipped with: the round's evidence
had to dodge the KANT-6 crash, so it could not fully separate "restore empties
the result" from "the recursive call misbehaved". This separates them — the call
is **never taken**.*

**AND THE NEXT PROBE THE SCOPE NAMED IS NOW RUN. There IS a workaround:**
```
A  return a LOCAL                     ->  tagged             EMPTIED
B  return the ARGUMENT                ->  <tripletriple>     SURVIVES
C  mint a node, hold it in a local    ->  grup               EMPTIED
```
**B is the idiom for a recursive value-returning kant action: carry the result out
through the ARGUMENT.** C is the one worth knowing — minting a fresh node does
**not** dodge it, because the node is still *held in a local* and it is the local's
slot that gets reverted. So this is not about node identity; it is about **which
slot the returned pointer is**, which is also why `restoreLocalFields` is not
itself wrong: restoring the caller's frame is its job, and the defect is that
`result` points into the frame being restored.

**Consequence for the arc, not just for a claim:** `emitPlan` recurses and must
return text, so A's step 3 inherits this. Either it returns through the argument
(B), or `runAction` gets fixed. **The fix is a design call and it is Tony's** —
the obvious candidates (detach the result before restoring, or restore before
reading the result) both change a function on the interpreter's hot path.

### CLAIM KANT-9 — an iterator is a HANDLE: `.taG` reads the iterator, and only ARGUMENT position derefs
```
statement:   After `iterate g on X; ++g`, `g` is a handle whose cursor is in its
             own group slot. `g.taG` answers "g", not the entry's tag, and an
             operator with `g` as its TARGET operates on the handle. To act on
             the entry, rebind first: `node <- g;` -- `<-` puts `g` in ARGUMENT
             position, where it does deref -- and then use `node`.
confidence:  RUN
provenance:  spellLeaf's OPT branch. `leaf = string $"OPT[" inner.taG "]"`
             printed `OPT[inner]` for both ScafE and ScafF, where the wrapped
             terms are a CALL and a LIT. With
                 wrapped <- inner;
                 wrapped :% sink;
                 piece = this(wrapped);
             spell.target goes byte-identical: `(parseR(t2,label) || 1)` and
             `(lit(t2,",") || 1)`. Mechanism READ off runOP
             (GroupActions.rtn:623-625) and stated in its own header: the
             isIterator exemption applies to the TARGET unwrap only, "an
             iterator in TARGET position stays the handle, in ARGUMENT position
             it derefs to the current entry".
asOf:        2026-07-29
scope:       `:%` (opReplaceAttribute) is the set-or-replace spelling and is what
             a REUSED attribute needs -- spellLeaf writes `sink` onto the same
             node twice (once per sink) and the second write must retarget, not
             stack; both sinks come out right, so it retargets. Says nothing
             about `+%`, which would stack.
```

### CLAIM KANT-10 — an UNSET field prints as its own TAG, so "absent" and "named" are indistinguishable in output
```
statement:   `:field a b c;` creates a local per name whether or not the
             attribute exists. A local with no data prints as its own TAG, not
             as empty and not as 0 -- so an absent attribute silently yields
             plausible-looking text.
confidence:  RUN
provenance:  spellLeaf probe `leaf = string $kind ":" local ":" sink ":" slot
             ":" site;` over the whole spellScratch fixture:
                 LIT:t1:label:slot:site        <- slot and site ABSENT on a LIT
                 MANY:t1:label:slot:ScafC1     <- site present, slot absent
                 LITTO:t1:label:{:site         <- slot present, site absent
             Same fact from the other end: an action returning an unset local
             `leaf` yields the string "leaf".
asOf:        2026-07-29
scope:       This is why spellLeaf dispatches on the TAG first and only reads
             `slot`/`site` inside the branch that guarantees them. Not
             established whether `if slot` distinguishes the two states -- it
             was not needed and was not tested, so do not assume it does.
```

### CLAIM KANT-11 — `string $` no-space mode eats a literal's LEADING space; `_` puts one back
```
statement:   `$` toggles useDefaultSpace, and under it a quoted literal loses
             its LEADING space while interior spaces survive. The `_` print
             shortcut appends one space and is the way to get it back.
confidence:  RUN
provenance:  `leaf = string $"(" piece " || 1)";` produced
             `(parseR(t2,label)|| 1)` -- one space short, and the space after
             `||` intact. `leaf = string $"(" piece _ "|| 1)";` produced
             `(parseR(t2,label) || 1)` and spell.target went byte-identical.
             Shortcut table READ at GroupActions.rtn:31-38 (`~ $ _ : + - ` ,`).
asOf:        2026-07-29
scope:       Observed for a leading space under `$`. Says nothing about trailing
             spaces or about behaviour with `$` off. `string` and `print` share
             this machinery (grammar: StringXP ruleMethod=aCTionPrinT), so it
             should apply to both -- only `string` was run.
```

### CLAIM KANT-12 — kant has NO stderr: `print` reaches stdout or a buffer, never stderr
```
statement:   Incant `print` writes to the diverted buffer if `printTO` set one,
             otherwise to stdout. There is no incant spelling that writes
             stderr. A C++ method being converted whose diagnostics go to `cerr`
             therefore CHANGES STREAM when it becomes kant.
confidence:  RUN
provenance:  opPrint, Instruct.rtn:756-764 --
                 if printText
                     if toBUFFER toBUFFER += printText;
                     else        cout printText;
             and observed: spellLeaf's refusal `print` landed in spellScratch's
             stdout capture while every C++ genParse diagnostic is on stderr.
             Grepped for an alternative: `printTO` is the only diversion command
             and it takes a buffer.
asOf:        2026-07-29
scope:       Load-bearing beyond diagnostics: genParse's EMITTED TEXT all goes
             to `cerr` (emitPlan/emitMany), and `genLadder/pop.sh` captures
             stderr and stdout SEPARATELY on purpose. A kant emitPlan cannot put
             its output where the ladder targets read it without either a new
             stderr primitive or moving the capture.
```

---

## BLOCKED

### BLOCKED KANT-B1 — a kant action cannot return NULL across `runAction`
```
wanted:      The refusal answer. C++ emitLeaf refuses an unknown plan kind with
             a loud cerr and `return null`, and emitPlan tests that null to
             refuse the whole rule. genEmit's header states the contract as
             "its answer is authoritative, INCLUDING A NULL". I could not
             produce a null.
source:      genParse.rtn:798-800
                 else {
                     cerr "emitLeaf: no emission for plan kind " node.tag:;
                     return null; }
             consumed at genParse.rtn:756 (`if !result return null;`) and
             genParse.rtn:613 (`if !piece piece = "REFUSED";`).
attempts:    Four, all run through spellScratch with the LIT branch renamed to
             LITX so every LIT node reaches the refusal branch. In every case
             the diagnostic printed correctly AND a non-null spelling came back:
                 return;                     ->  LIT sink=label return
                 return null;                ->  LIT sink=label 0
                 return leaf;   (unset)      ->  LIT sink=label leaf
                 clear(leaf); return leaf;   ->  LIT sink=label leaf
                 leaf = ""; return leaf;     ->  LIT sink=label quoteBody
             (that last one leaks the QuotE rule's internal tag, which is its
             own oddity and was not chased). EXIT=0 on all five.
category:    IDIOM-GAP
```
**Grepped before filing, per the brief.** No kant action anywhere in `incant/` returns
a refusal that a C++ caller tests — every existing kant action either returns a real
field (`hexToNumber`, `testNew`, `JSONfield`) or returns nothing anyone reads. So there
is no counterexample to find and no established idiom to copy; that is *why* this is
IDIOM-GAP rather than KANT-GAP. **The consequence is live, not theoretical:** the kant
`spellLeaf` shipped in `incant/genEmit` is LOUD on an unknown kind but does not REFUSE,
so `emitPlan` would take the junk text as a spelling. No target covers it.

**What a future round should try first:** returning the ARGUMENT with a flag stamped on
it (`:.`), and having the C++ side test that flag instead of the pointer. That moves the
refusal signal from "can kant produce a null" (apparently not) to "can kant set a
boolean" (bear-trap #10's apparatus, but known to work).

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
