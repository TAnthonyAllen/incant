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

**THREE SHAPES, not two** (added 2026-07-30, `docs/minion-corpus-format.md`): **CLAIM** is
knowledge, **BLOCKED** is a road that does not go through and the evidence why, **OPEN** is
*work* — a real question with what is established, what is not, and what it would cost to
settle. The tell that you want OPEN: **the entry's most useful sentence describes something
nobody has done yet.** `OPEN KANT-20` is the worked example and is what caused the shape.

**An ABSENCE claim must name where it looked** — the paths, the pattern, the scope. A claim
that something does not exist is only as good as the search that failed to find it, and it
rots silently, because the world only has to gain the thing. `CLAIM KANT-17` was made false
within the hour by its own author for exactly this reason.

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
asOf:        2026-07-30 — RE-TESTED AND IT HOLDS
retest:      2026-07-30, foreman, on a tree changed in three relevant ways since
             the original (rStuff-at-define, the iterator work, and the 403/404
             fix). Swapped `this(wrapped)` -> `spellLeaf(wrapped)` in the shipped
             body and ran incant/spellScratch:
                 GroupItem add: Tried to add spellLeaf to itself
                 EXIT=139, spell.target truncated
             Identical signature to round 1's. NOT STALE — the mechanism is
             insensitive to everything that moved. Reverted immediately; the
             restored body is exit 0 and byte-identical.
             ⚠ CONSEQUENCE, and it BLOCKS BRIEFED WORK: SEQ 32's step 4 ("this()
             out, minted slot in") CANNOT PROCEED. It assumed removing `this()`
             was possible and would arm KANT-8; it is not possible at this seam.
             And under `this()` KANT-7 says locals are shared, so KANT-8 never
             fires — meaning the minted carrier would pass here whether or not it
             works, which is exactly the "green stub reads as coverage" failure
             the speller pin exists to prevent. Step 4's stated value —
             validating the workaround against a byte-exact oracle before
             emitPlan needs it — is NOT obtainable this way.
             THE ONE UNTRIED ROUTE, and it is this claim's own scope note: a
             WARM-UP call (`spellLeaf(spellWarm);` as an ordinary incant
             statement) made the self-name spelling compile clean. That would
             give a real named self-call with real per-frame locals, which is
             what step 4 wants. Untried in anger, and it trades one workaround
             for another — Tony's/Clay's call, not foreman's.
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
UPDATE:      2026-07-30 — QUALIFIED, and the scope above named TWO options where
             there are THREE. The grammar minion found the third and foreman
             verified it (`incant/sinkStderr`, exit 0):
                 printTO(errBuf);  ...print...;  printTO(null);
                 errBuf modedOP "/dev/stderr";   closeFile(errBuf);
             → the buffered lines came out ON FD 2, IN ORDER, while lines
             outside the divert stayed on stdout. **STDERR IS REACHABLE FROM
             INCANT TODAY WITH NO C++ CHANGE.** See grammarCorpus CLAIM GRAM-6.
             The claim's HEADLINE still stands — there is no per-statement
             stderr sink, and `cerr` as a keyword remains correctly REFUSED
             (GRAM-4: `opPrint` is a two-arm if with no third branch).
             ⚠ WHAT IS NOT SETTLED, and it is the whole question for a kant
             emitter: ORDERING ACROSS THE FLUSH. A buffer flushes when it is
             closed, so a kant `printPlan` that buffers its body would emit
             AFTER a C++ caller's already-written header line, scrambling
             `census.target` even though each side is internally ordered.
             Flushing per invocation is the obvious fix and is UNTESTED.
             So: the round-2 hold is now SOFT (a route exists) rather than HARD
             (no route exists), and the remaining work is real.
```

---

## ROUND 2's INTAKE — KANT-13 … KANT-20, written 2026-07-30, BEFORE round 2 fired

**Count these as ORIENTATION, not absorption.** They were drafted by foreman and by
Tony, not by a round, so scoring them as round 2's absorption would make the ledger's
instrument read noise — the same error the ROUND 1 table above exists to prevent.

**Origins differ and the difference matters:**

| claims | origin | grade it by |
|---|---|---|
| **KANT-13 … KANT-15** | **Tony's design rulings** on print/sink/keyword semantics | his authority — they are decisions, not measurements |
| **KANT-16** | **a correction pointed at the REVIEWERS**, not at round 1 | read it before trusting a brief |
| **KANT-17 … KANT-19** | foreman's step-0 runs, 2026-07-30 | RUN provenance, exit 0 captured |
| **KANT-20** | a grep, with the inference deliberately NOT drawn | it is an open item wearing a claim's clothes |

*Clay's brief said "nine claims" and listed six, two of which were already among
foreman's three — the true distinct count is EIGHT. Written as eight rather than padded
to nine: inventing a claim to reach a number is exactly what this format exists to stop.*

### CLAIM KANT-13 — ONE print mechanism, FOUR destinations; the keyword selects only the SINK
```
statement:   `print`, `string`, and the coming `cout`/`cerr` are ONE mechanism.
             `PrintXP+` is FIXED and identical under all of them. The keyword
             selects only WHERE the text lands — stdout, stderr, or a value.
             Spacing, shortcuts, formats and parsing DO NOT VARY BY SINK.
confidence:  RULING (Tony, 2026-07-30) — corroborated READ
provenance:  Tony's ruling, dictated in chat. Corroborated in the grammar:
                 incant/grammar:147  PrinT     print  followedBy PRINTing- stuff=PrintXP+ SemI- defer;
                 incant/grammar:118  StringXP  string followedBy PRINTing- stuff=PrintXP+ ruleMethod=aCTionPrinT defer;
             — same `stuff=PrintXP+`, same action. ruleActions.rtn:624
             `aCTionPrinT` forks ONLY at the tail:
                 if command.tag == 'p'  return opPrint(input,buffer);
                 else                   return opString(command,buffer);
             One walk, one buffer, two exits. That fork is the whole difference.
asOf:        2026-07-30
COMPLETED:   2026-07-30, Tony (SEQ 33) — THE FAMILY IS NOW CLOSED AT FOUR:

               keyword                    destination   divertible
               print                      stdout        YES (printTo)
               cout                       stdout        no
               cerr                       stderr        no
               string (and omitted form)  a value       n/a

             ONE spacing default across all four. `$` is the ONLY mode that ever
             changes it. `_` is the explicit space. There are NO per-destination
             spacing defaults — a `cout`-specific default was drafted for this
             corpus and Tony's cut removed it before it landed.
             ⚠ AND THE CLAIM CAME OUT OF THAT STRONGER, WHICH IS THE POINT: a
             per-sink spacing default would have been the first crack in
             "the keyword selects only the sink", written INTO the corpus by the
             people holding the ruling. One mechanism survived contact.
scope:       This is why adding cout/cerr is SMALL. The language is not gaining a
             feature; it is gaining two sinks. Anything that makes a sink differ
             in SPACING or PARSING is out of spec, not an enhancement.
             Corollary for the oracle: `print` IS the fixture for `cout`. Route
             both to a captured stream, feed identical PrintXP, demand identical
             bytes — the same trick spell.target plays on emitLeaf.
```

### CLAIM KANT-14 — `,` is INERT alone and exists to BUNCH; `,+` reaches shortcut `+`
```
statement:   The shortcut set is `-+~`$_:,` (ONE character class, bunchable).
             `,` does nothing on its own. It exists so shortcuts can be BUNCHED,
             which is how you reach a shortcut whose character also has an
             operator reading: `,+` is shortcut `+`, where bare `+` would read as
             addition. The operator/shortcut collision is therefore ALREADY
             RESOLVED in the grammar — user-side and per-site.
confidence:  RULING (Tony, 2026-07-30) — corroborated READ
provenance:  Tony's ruling. Set definition, two places, identical:
                 incant/grammar:92   ShortcuT=[-+~`$_:,]+;      <- note the trailing `+`: bunchable
                 GroupRules.twk:103  shortcutSet = new("-+~`$_:,");
             `ShortcuT` is an alternative of `PrintXP` (incant/grammar:103-105),
             so it is legal anywhere a print term is.
asOf:        2026-07-30
scope:       DO NOT invent disambiguating syntax for the operator/shortcut
             overlap — it is solved. Whether BARE `+` should read as shortcut or
             operator is a separate, existing, Tony-owned question and is
             untouched by this. Says nothing about bunching ORDER or about
             whether every pair bunches; only `,+` was ruled on.
```

### CLAIM KANT-15 — an OMITTED keyword must not change semantics; a DIFFERENT keyword may
```
statement:   DESIGN PRINCIPLE, not a fact about the tree. If a user OMITS a
             keyword they chose nothing, so nothing may change underneath them —
             the omitted form must mean exactly what the spelled form meant. If a
             user types a DIFFERENT keyword they made a choice, so the two may
             legitimately differ. `string` omitted must behave as `string`;
             `cout` versus `print` may differ, because the user typed it.
confidence:  RULING (Tony, 2026-07-30)
provenance:  Tony's ruling, dictated in chat 2026-07-30, in the discussion that
             collapsed SEQ 31's step 1 from a feature to two sinks.
asOf:        2026-07-30
scope:       ⚠ THIS IS THE LEAST RECOVERABLE CLAIM IN THE FILE. A minion reading
             source can rediscover every other claim here eventually; it cannot
             rediscover a principle that exists only in Tony's head. It is also
             load-bearing on work already briefed: it is precisely why bundling
             `$`-removal with `string`-removal was wrong — `$` is a MODE the user
             typed, `string` is a keyword they would be omitting, and the two are
             on opposite sides of this line. Apply it BEFORE agreeing to a brief
             that removes a keyword, not after the bytes move.
```

### CLAIM KANT-16 — round 1's `iterate … on argument MEMBERS` was CORRECT; the reviewers were wrong
```
statement:   Round 1 wrote the OPT descent as `iterate inner on argument members`
             — affiliation-FILTERED. Review proposed replacing it with
             `inner := argument.firsT;` as a simplification. THE REVIEW WAS
             WRONG: `.firsT` does not filter (KANT-17), and on an OPT plan node
             it returns the `at` ATTRIBUTE instead of the wrapped term. The
             starved-corpus round had the filtering RIGHT and paid a cursor for
             it.
confidence:  RUN (the measurement is KANT-17's)
provenance:  Round 1's shipped `incant/genEmit`; SEQ 31 step 3's proposed
             replacement; foreman's Q2 run 2026-07-30 (incant/nameRecurse).
             Caught BEFORE round 2 was briefed, not after it shipped.
asOf:        2026-07-30
scope:       ⚠ READ THIS BEFORE TRUSTING A BRIEF. The standing rule for weighting
             a design brief is "take the STRUCTURAL distinctions, CHECK the
             claims about what is in the TREE" — this is one more instance, and
             the reviewer flagged his own tree-claim record as zero for five the
             same day. A brief's simplification is a HYPOTHESIS about the tree
             until it is measured. Cost of measuring: one run. Ledger this under
             adversarial absorption with the correction pointed AT THE REVIEWERS,
             not at round 1.
```

### CLAIM KANT-17 — `.firsT` does NOT filter by affiliation; it is plain `firstInList`
```
statement:   `.firsT` returns `firstInList` with NO affiliation filter — it is
             exactly an UNFILTERED `iterate`, not a member-filtered one.
             Attributes and members share ONE list distinguished by affiliation,
             so on any node built attribute-first `.firsT` returns the ATTRIBUTE.
             ⚠ SUPERSEDED IN PART, SAME DAY: there is now a member-filtered
             accessor, `.firstMembeR` (case 405) — see the UPDATE below. The
             claim about `.firsT` ITSELF still stands unchanged.
confidence:  RUN
provenance:  incant/nameRecurse `shapeProbe`, exit 0, 2026-07-30. Built the exact
             OPT shape (`shape +% atx;` then `shape += kidx;`) and asked three
             ways:
                 GOT=         atx     <- .firsT
                 FIRSTMEMBER= kidx    <- iterate ... on shape members
                 FIRSTANY=    atx     <- iterate ... on shape (unfiltered)
             Mechanism READ at Instruct.rtn:145, case 403 -> target.firstInList.
             Why it bites OPT specifically: genParse.rtn:456 builds an OPT as
             `opt = new("OPT"); opt +% at; opt += node;` — the `at` attribute
             goes on FIRST, the wrapped term is a MEMBER and goes on SECOND.
asOf:        2026-07-30
scope:       Measured on a hand-built two-child node and on the OPT construction
             read from source. Says nothing about `.lasT`'s affiliation
             behaviour (not probed) — only about its crash behaviour, KANT-18.
UPDATE:      2026-07-30, LATER THE SAME DAY — `.firstMembeR` (case 405) now
             exists and IS affiliation-filtered. Instruct.rtn case 405 =
             `target.nextMember(0)` behind a groupList guard; incant/setup
             declares `firstMembeR=405`. RUN on the same OPT shape:
                 NEWFIRSTMEMBER= kidx      <- the MEMBER, as wanted
             So the descent a walk wants is `x.firstMembeR`, NOT `x.firsT`.
             ⚠ AND NOTE WHY THIS UPDATE IS HERE RATHER THAN A NEW CLAIM: the
             original text asserted "there is NO member-filtered first accessor",
             which foreman then made FALSE by adding one, one hour later. A claim
             that goes stale because its own reader changed the tree is the
             format's central failure mode. Edited in place, same day, before any
             round could read it.
```

### CLAIM KANT-18 — `.firsT`/`.lasT` SEGFAULT on any leaf: the guard derefs the pointer it guards
```
statement:   `.firsT` (case 403) and `.lasT` (case 404) crash with SIGSEGV on any
             node carrying no list. The null guard is written correctly in incant
             but generates a dereference of the very pointer it is testing.
             `.nexT`/`.prioR` (401/402) are SAFE — they read a direct field with
             no intermediate pointer.
confidence:  RUN
provenance:  First cut of incant/nameRecurse descended via `.firsT` and died
             EXIT=139 on the third level (the leaf). Crash frame 0 under
             `script -q /dev/null`: opDot, GroupRules.mm:4373.
             Source, Instruct.rtn:145 — reads as guarded:
                 case 403: if !target.firstInList  product = null;
                           else product = target.firstInList;
             Generated, GroupRules.mm:4373:
                 if ( !target->groupBody->groupList->firstInList )
             — `groupList` is dereferenced IN ORDER TO TEST it. A leaf has
             groupList == 0, so the guard crashes on exactly the case it exists
             to handle. Contrast 401/402: `!target->nextInParent`, no
             intermediate.
asOf:        2026-07-30
scope:       NOT a tok bug — the incant source says `target.firstInList` and the
             intermediate is implicit, so tok generated what it was asked for.
             PRE-EXISTING, surfaced not caused.
STATUS:      ⚠ FIXED 2026-07-30, same day, by foreman — this claim is kept as the
             REASONING TRAIL, not as a live hazard. Instruct.rtn cases 403/404 now
             read `if !target.groupList || !target.firstInList` (the same idiom
             case 5 already used eight lines up), and C++ `||` short-circuits, so
             the intermediate is never dereferenced when it is null. RUN, exit 0
             where it was 139:
                 LEAFFIRST-SURVIVED= edge       <- null, printed as its own tag
                                                   per KANT-10; previously SIGSEGV
             `.lasT` was fixed identically but is NOT separately covered by a
             fixture — 404 was corrected by symmetry with 403, which is a
             REASONED fix on an unexercised path. Whoever first uses `.lasT` on a
             leaf gets to promote that to RUN.
```

### CLAIM KANT-19 — a BARE NAMED self-call DOES trip `recursive`; `this(...)` does not
```
statement:   A bare named self-call inside a registered action DOES set
             `field.recursive`, so save/restore runs and locals ARE per-frame.
             `this(...)` does NOT (KANT-7). The two spellings therefore have
             DIFFERENT frame semantics, and swapping one for the other silently
             changes whether a local survives a call.
confidence:  RUN
provenance:  incant/nameRecurse `probe`, exit 0, 2026-07-30. Assigns a scalar
             local, recurses BY NAME, reads its OWN local AFTER the call — the
             read KANT-7 forbids under `this()`:
                 ENTER L-outer / ENTER L-inner / ENTER L-deep
                 AFTER L-deep  / AFTER L-inner / AFTER L-outer
             Each AFTER pairs with its OWN ENTER. Under shared slots every AFTER
             would read L-deep. Corroborating: incant/iterT1 self-calls by name
             and passes per-frame. Mechanism READ: GroupActions.rtn:570/572 gate
             save/restore on `field.recursive`; the inference itself is a
             syntactic identity check against currentMETHOD (ruleActions.rtn).
asOf:        2026-07-30
scope:       COMPLETES the KANT-5/6/7/8 knot — read all five together.
             CONSEQUENCE, and it is why this was run: replacing `this(...)` with
             a named self-call ARMS KANT-8. The locals become per-frame, so a
             returned LOCAL comes back emptied. The two changes are ONE MOVE —
             the named call arms the hazard, the carrier disarms it, and landing
             them apart leaves a knowingly-broken intermediate state.
             Coverage caveat inherited from KANT-5: this is DIRECT recursion.
             Mutual recursion (A→B→A) still gets NO per-frame locals, because
             neither action names itself (pinned wrong answer: incant/iterT1m).
```

### OPEN KANT-20 — `0` vs `falseResult` is inconsistent, and the "latent bugs" inference does NOT follow
> **RESHAPED 2026-07-30 from CLAIM to OPEN**, and it is the entry that caused the shape to
> exist. Its own scope line already had to warn that it was *"an open item wearing a claim's
> clothes"*; `docs/minion-corpus-format.md` now carries OPEN as a first-class shape, so the
> warning becomes the label. **ID deliberately unchanged** — it is cited elsewhere, and
> renumbering to tidy a shape change would break the trail the format exists to keep.
> **What it blocks:** nothing today. **What it would cost to settle:** one grep, sized below.
```
statement:   The asymmetry is real and large: `return trueResult` 47 sites,
             `return falseResult` only 4, against 322 `return 0` and 259
             `return null`. So the idiomatic YES is a real node and the
             idiomatic NO is a raw null. BUT the proposed inference — that
             KANT-B1 makes some of those raw nulls latent bugs — DOES NOT FOLLOW
             AS STATED, and is recorded here UNDRAWN on purpose.
confidence:  READ (the counts are RUN; the inference is explicitly NOT drawn)
provenance:  Counts by grep over *.rtn/*.twk, 2026-07-30. Definitions:
             GroupControl.twk:152/155 — trueResult and falseResult are real
             GroupItem nodes in `properties`, tagged "true"/"false".
             THE SCOPING CORRECTION: KANT-B1 is about a KANT action's return
             crossing `runAction`. These 581 sites are C++ externs returning to
             C++ CALLERS, which is a different boundary and is unaffected — the
             C++ `emitLeaf` returns NULL to refuse and that works fine today.
             The genuinely suspect set is only the INTERSECTION: C++ externs
             registered as incant actions/commands whose null result is then
             consumed by incant. That intersection has NOT been sized.
asOf:        2026-07-30
scope:       ⚠ DO NOT act on this as "581 suspect sites" — that is the reading
             this entry exists to prevent. It is an OPEN ITEM wearing a claim's
             clothes: the counts are solid, the boundary distinction is solid,
             and the work of sizing the intersection is UNDONE. Whoever sizes it
             should also settle whether the language wants ONE false sentinel;
             the standing ruling is DO NOT standardise on one until something
             reachable needs it.
```

### CLAIM KANT-21 — `string` CONSTRUCTS FRESH before assigning, which is why aliased read-and-assign survives
```
statement:   `leaf = string ... piece ...;` where `piece` and `leaf` are THE SAME
             NODE does not self-destruct. `string` builds its result complete
             before the assignment touches the target, so reading an operand that
             aliases the destination is safe.
confidence:  RUN as to the OUTCOME; REASONED as to the MECHANISM. Graded split on
             purpose — what was observed is that the aliased case is green, not
             that `string` allocates first. Do not upgrade without reading
             aCTionPrinT/opString.
provenance:  The shipped spellLeaf's OPT arm, live at depth 1 every time
             `spell.target` is produced:
                 piece = this(wrapped);
                 leaf  = string $"(" piece _ "|| 1)";
             `this(...)` gives SHARED locals (KANT-7), so the inner frame's
             `leaf` IS the outer frame's `leaf` — and `piece` is assigned that
             very node. The second line therefore READS `piece` while ASSIGNING
             `leaf`, with both naming one slot. `spell.target` is byte-identical
             and exit 0, and has been across every run since round 1.
asOf:        2026-07-30
scope:       ⚠ THIS WAS LOAD-BEARING AND UNRECORDED FOR A FULL ROUND. Round 1
             answered it by accident — the arm works — and nobody wrote it down,
             so it was rediscovered from the other end while reasoning about
             whether the aliasing hazard fires at depth 1. It does fire; it is
             simply survivable.
             The dependency is REAL but should become UNINTERESTING: under the
             carrier discipline (KANT-22) the accumulator stops being a local, so
             nothing aliases and this stops mattering. Recorded because "we do not
             depend on this any more" is only sayable once someone has said what
             the dependency WAS.
```

### CLAIM KANT-22 — ⚠ KANT HAS NO STATEFUL RECURSION. Both routes are barred, for different reasons. USE A CARRIER NODE.
```
statement:   TODAY, no kant action can hold a value in a LOCAL across its own
             recursive call. There are exactly two ways to recurse and both fail:

               route              state across the recursive call
               ---------------    ----------------------------------------
               named self-call    DOES NOT COMPILE            (KANT-6, 139)
               this(...)          compiles, LOCALS SHARED —
                                  the inner frame overwrites the outer's
                                                              (KANT-7)

             THE IDIOM THAT WORKS, and it is doctrine, not a workaround:
             ⇒ ANYTHING THAT MUST SURVIVE A RECURSIVE CALL LIVES ON A CARRIER
               NODE, NEVER IN A LOCAL. The caller mints a node, passes it down,
               the callee stamps onto it.
             A carrier is not a local, so SHARING cannot reach it; it is not in
             the action's field list, so a RESTORE cannot reach it either
             (KANT-8). ONE mechanism, correct under BOTH regimes — and it is the
             same shape KANT-B1's refusal wants (mint empty, stamp nothing to
             refuse, empty is unambiguous).
confidence:  RUN for both bars (KANT-6 re-tested 2026-07-30, EXIT=139; KANT-7
             measured round 1). REASONED for the carrier discipline — it follows
             from both, and it is NOT yet exercised in shipped code.
provenance:  KANT-6 + KANT-7, read together. Neither is new; the CONJUNCTION is,
             and it was missed for a full round because each was filed as a fact
             about spellLeaf rather than about the language.
asOf:        2026-07-30
scope:       ⚠ THIS IS NOT A `spellLeaf` PROBLEM AND THAT IS THE WHOLE POINT.
             It bars `emitPlan` — which accumulates text across a walk and reads
             its accumulator after each recursive call, i.e. exactly the barred
             shape — so it bars STEP 3 OF THE MINION ARC, which nobody knew when
             the arc was planned.
             UNDER THE CARRIER DISCIPLINE, emitPlan IS WRITABLE IN KANT TODAY:
             under `this()`, with shared locals, with no KANT-6 fix, because the
             accumulator is a carrier field and nothing that matters sits in a
             local across the call.
             THREE EXITS, and this is the ruling wanted from Tony:
               1. fix the define-time self-name bar (KANT-6)
               2. make `this()` per-frame (KANT-7)
               3. adopt the carrier discipline as the language's recursion idiom
             Exit 3 costs nothing, works today, and needs no runtime change.
             ⚠ AND NOTE WHAT A GREEN FIXTURE HERE WOULD AND WOULD NOT PROVE:
             under `this()` KANT-8 never fires, so a carrier landed now is
             UNEXERCISED AGAINST KANT-8 and green does NOT certify it against
             that hazard. It IS exercised against the aliasing hazard, which
             fires at depth 1 under sharing (KANT-21). Label any such fixture
             loudly or the next reader takes green for coverage.
```

### CLAIM KANT-23 — DIVERSION BELONGS TO `print` ALONE, and that is the entire reason `cout` exists
```
statement:   `printTo` diversion is a property of `print` and of nothing else.
             `cout` and `cerr` are NOT divertible, by design and not by omission.
             So when a diversion is armed, `cout` STILL REACHES THE TERMINAL —
             which is the whole reason the keyword exists. Cake, and eating it.
             `cerr` is not divertible either: a user who wants to capture
             diagnostics prints them into a buffer DELIBERATELY. That is data
             they built, not an error channel intercepted — and the capability
             was never missing.
confidence:  RULING (Tony, 2026-07-30, SEQ 33)
provenance:  Tony's ruling. Mechanism located and VERIFIED in source by foreman:
             the diversion gate is a single `if toBUFFER` INSIDE `opPrint`
             (Instruct.rtn:775-787) —
                 if toBUFFER  toBUFFER += printText;
                 else         cout printText;
             — with `toBUFFER` set by `printToBuffer` (Commands.rtn:444). So
             "route cout past the diversion check to the stdout arm" names a
             place that actually exists. Note also that `opPrint` ALREADY uses
             tok-level `cout` and `cerr`, so the output primitives are present
             and a third sink does not need one invented.
asOf:        2026-07-30
scope:       ⚠ THIS IS THE CLAIM MOST WORTH HAVING WRITTEN DOWN, and the reason
             is a general one: **from source, the existence of `cout` reads as
             arbitrary — a redundant second spelling of `print`. From the
             rationale it is obvious and load-bearing.** A reader who finds
             `cout` in the tree and not this claim will eventually "simplify" it
             away, because nothing in the code says why a second stdout keyword
             is not duplication. That gap — obvious-given-why, arbitrary-given-
             what — is exactly what a corpus is for, and it is the same class as
             KANT-15 (a design principle recoverable from nobody's reading of
             the source).
             Says nothing about whether a FUTURE sink should be divertible; the
             ruling covers these four.
```

### CLAIM KANT-24 — ENVIRONMENT: `${PIPESTATUS[0]}` is silently EMPTY in zsh and reports every run as passing
```
statement:   This project's shell is zsh, which spells the pipe-status array
             `$pipestatus` (lowercase, 1-indexed). `${PIPESTATUS[0]}` is a BASH
             spelling: in zsh it expands to NOTHING, so
                 cmd | filter; echo "EXIT=${PIPESTATUS[0]}"
             prints `EXIT=` and any test against it reads as SUCCESS. Every run
             checked this way reports passing, including runs that segfaulted.
             ⇒ TAKE `$?` DIRECTLY FROM THE BINARY, NEVER THROUGH A PIPE:
                 $BINARY incant/fixture > out 2> err;  echo "EXIT=$?"
confidence:  RUN
provenance:  Bit THREE times on 2026-07-30, in three different hands, each
             independently: foreman's first nameRecurse run (reported no exit
             status at all), the JIT recon scout (caught itself mid-round and
             re-ran everything with $? before drawing a conclusion), and the
             grammar minion's POP script, whose header now documents it.
asOf:        2026-07-30
scope:       ⚠ THIS IS AN ENVIRONMENT CLAIM, NOT A KANT CLAIM, and it is in this
             corpus because THE CORPUS IS WHAT ROUNDS READ. It says nothing
             about incant; it is about the instrument every round uses to decide
             whether incant worked.
             It belongs to the same family as CLAUDE.md's exit-status doctrine
             and the parse-failure trap: **the ways this project has been fooled
             are overwhelmingly about the measuring, not the measured.** Three
             separate instrument failures surfaced in one day — this, the
             parse-failure-exits-0 trap, and a status table falsified a month
             ago by a refactor nobody re-ran. When something reads green, ask
             what the green was produced BY before asking what it says.
             Says nothing about bash, where the spelling is correct.
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
