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
> ## ✅ **REPAIRED 2026-08-10 (SEQ 27). Everything below is left exactly as written because it was
> ## true when written; the repair, the K-row ledger of record, and what it does NOT fix are in the
> ## block at the END of this claim.** Two rungs: value-capture at the return seam, then the
> ## unconditional bracket. **K1/K4/K5 return 42; K6a's mutual case moved 2→3; K3 held at 42.**
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
⚠⚠ **READ THIS FIRST — THE TERRITORY IS NARROWER THAN "THE INTERPRETER". THERE ARE TWO DOORS INTO
AN ACTION BODY AND ONLY ONE HAS A BRACKET OR A SEAM** (measured 2026-08-10, by the node-return
census, which it outgrew):

| door | how it is bound | bracket? | seam? |
|---|---|---|---|
| **`runAction`** — `actionType` calls (`GroupActions.rtn:894`), plus `Commands.rtn:191` and the genParse kant seam at `genParse.rtn:847`/`:964` | dispatch | **yes** | **yes** |
| **`processAction` DIRECT** — every coded **rule** | `ruleActions.rtn:352`, `or isCoded  method = processAction;` | **no** | **no** |

`processAction` is called from `runAction` at `:790` **and nowhere else**, and `runRule` goes to
`rule.parse(0)`. **So this claim's territory is `actionType` calls, precisely — not "the
interpreter".** The entire grammar/XML population was never exposed: **`jsonTest`'s thirteen rows
never met this defect because they structurally could not.** That is why the fleet stayed green
through six weeks of a live seam bug — **topology, not luck.** ⚠ **The next seam-shaped defect gets
found faster by someone who knows there are two doors**, which is the whole reason this sits at the
head of the entry rather than inside the census that found it.

**⚠ THE OPEN PROBE IS ANSWERED, AND THE SCOPE LINE ABOVE IS UNDERSTATED (2026-08-05,
`incant/kant8T`, four rows, interpreted, exit 0).** The `asOf` block is left exactly as written
because it was true when written; both corrections are recorded here rather than by editing it.

| row | | returned |
|---|---|---|
| **K3** | NON-recursive, returns a local | **42** — the control; without it "returning a local is broken" cannot be told from "`recursive` is the discriminator" |
| **K1** | recursive, returns a local | **`k1loc`** — KANT-8 reproduced |
| **K4** | recursive, **recursive branch NEVER TAKEN** | **`k4loc`** |
| **K2** | recursive, returns its **ARGUMENT** | **7** |

**1. RETURNING THE ARGUMENT DODGES IT.** The probe this claim itself called "the obvious next
probe" is answered: **yes.** And it is structurally readable rather than inferred —
`saveLocalFields` saves an argument **without blanking it** (`if !grup.isArgument`), and
`runAction` **binds at `:672-674` BEFORE saving at `:677`**, so the argument is saved *as bound*
and restored *as bound*. **CONSEQUENCE: `CLAIM KANT-22`'s CARRIER DISCIPLINE — *anything that must
survive a recursive call lives on a carrier node* — is now MEASURED rather than proposed. An
argument IS such a carrier, today, with no runtime change and no interpreter edit.**

> ⚠⚠ **NARROWED BY MEASUREMENT, 2026-08-05 — THE CARRIER IS VALID FOR *DIRECT* SELF-RECURSION
> ONLY, AND FAILS FOR MUTUAL.** `kant8T` row **K6c**: in an A→B→A shape the outer activation's
> `argument` reads back as the **inner's** binding (`k6small` where its own was `k6big`).
>
> **And the two rows are opposites for different mechanisms, which is the part to keep.** K2 works
> *because the bracket runs and is generous*: `runAction` binds at `:708-711` **before**
> `saveLocalFields` at `:713`, so the argument is saved as-bound and restored as-bound. K6c fails
> *because the bracket never runs at all*: `recursive` is set only on **direct self-mention**
> (`ruleActions.rtn:1310`), so in A→B→A neither A nor B trips it — no save, no restore, no
> protection. The carrier is not "safe" in general; **it is safe exactly where something is
> restoring it.**
>
> **Practical consequence for anyone applying this discipline:** an accumulator parked on an
> argument survives `A → A`, and is **silently trampled** by `A → B → A`. Since genParse's grammar
> rules reference each other constantly, mutual recursion is the **normal** case on that road —
> so the carrier discipline is not a general workaround there, and the real fix stays the frame
> model (per-activation state kills both diseases; patching `saveLocalFields` kills neither the
> mutual gap nor this one).

> ### THE FULL ROW LEDGER, AND K6a's NUMBER (added 2026-08-07, `incant/kant8T`, exit 0, sentinel fires)
>
> The four-row table above is the 08-05 record and is left as written. The remaining rows were
> never tabulated anywhere, and **K6a's value in particular was measured on 08-05 and then went
> unrecorded for two days** — which matters because the frame arc's opening fixture is named as
> *"K6a's shape, jitted"*, so this number is about to become a target.
>
> | row | shape | returned | grade |
> |---|---|---|---|
> | **K5** | K1's shape, called **twice** | **`k5loc`** both calls — invocation history does **not** change the answer | RUN |
> | **K6a** | mutual A→B→A, iterator cursor carried across | **2** | RUN |
> | **K6b** | control: same shape, local written **after** the call | **3** — the shape is not the fault | RUN |
> | **K6c** | mutual, the **argument** read after the call | **`k6small`** — the inner's binding | RUN |
> | **K6d** | control: re-iterate one cursor on two nodes, no recursion | **3** — the re-iterate re-points; the iterator is not a suspect | RUN |
> | **K6e** | *new*: two consecutive walks on one cursor, **no recursion at all** | first **1**, second **1** | MEASURED |
> | **K6f** | *new*: mutual, sized 4-outer / 2-inner so three readings give three numbers | **4** | MEASURED |
>
> **K6a = 2 IS NOW EXPLAINED, AND THE EXPLANATION WAS BUILT AS A DISCRIMINATION RATHER THAN A
> READING.** K6a's own legend anticipated only **3** (protected) or **1** (trampled); 2 is neither,
> and a number outside its own value map is exactly the kind of thing that gets pinned as a target
> and then cited as if it had been understood. The decomposition is **1 outer tick + 1 restarted
> tick**: the inner activation re-points the shared cursor at `k6small` and walks it out, the outer
> resumes, and its next `++` **restarts the walk from the head of the list rather than reporting
> exhaustion**.
>
> **Two witnesses, because the hypothesis was inferred and this domain's causal claims are a coin
> flip until run:**
> - **K6e removes the second activation entirely** — one action, one cursor, no recursion of any
>   kind, two consecutive `while ++` loops with no `iterate` between them. Nothing there can trample
>   anything, so a non-zero second count can *only* be the restart. It counted **1**: exhaustion is
>   **not terminal**. Its first walk counted 1 as the anti-vacuity guard, printed **from inside the
>   action** — an action returns one value, and reading the guard from outside afterwards would mean
>   reading a node-resident local across a call boundary, i.e. the very quantity under test.
> - **K6f checks the property ACCOUNTS for K6a** rather than merely coexisting with it, sized so the
>   three readings separate: **4** trampled-and-restarting · **5** cursor never trampled · **2**
>   trampled with terminal exhaustion. Measured **4**. ⚠ The sizing is load-bearing — with the inner
>   list length equal to the outer's remaining attributes, the restart reading and the
>   never-trampled reading **both total the same** and the row discriminates nothing.
>
> **CONSEQUENCE FOR THE FRAME ARC: 2 is a composite, and a target that pins it must know that.**
> It is one part trample (the frame defect this file characterises) and one part iterator restart
> (a property of `++` that has nothing to do with frames). A jitted K6a that came back 2 would
> therefore agree with the interpreter **for two reasons at once**, and a jitted K6a that came back
> 1 would be a *restart* divergence wearing a *frame* fixture — the failure H7 was written about.
> **Assert the decomposition, not the total.**

**⚠ A DRIFT TABLE, AND THE DOCTRINE IT EARNED (2026-08-07).** Every file:line in this claim's own
prose and in `kant8T`'s commentary had drifted. **The mechanisms are all intact and unchanged — only
the numbers moved** — which is precisely what makes this dangerous rather than merely untidy.

| cited as | what it meant | where it actually is today |
|---|---|---|
| `GroupActions.rtn:587` | `recursive` cleared on outermost restore | **`:653`**, in `restoreLocalFields` (**`:648`**) |
| `GroupActions.rtn:859-879` | the save predicate | **`:928`**, in `saveLocalFields` (**`:919`**) |
| `GroupActions.rtn:672-674` / `:677` | bind before save | **`:777-778`** / **`:782`**, in `runAction` (**`:759`**) |
| `GroupActions.rtn:708-711` / `:713` | bind before save (the later citation) | same as above — **`:708` is now `jitBindArgRT`** |
| `ruleActions.rtn:1310` | `recursive` set on direct self-mention | **`:1387`** |

⚠ **THE FOURTH ROW IS THE ONE TO REMEMBER, because a stale citation that lands on nothing is
harmless and this one does not.** `:708` today is **`jitBindArgRT`**, and `:713` is
`ruleArg.group = arg;` — *an argument binding*, in a function whose job really is to bind an
argument. A reader following the citation unchecked finds code that **confirms the sentence they
came to verify**, in the wrong function, on the wrong engine: the JIT's runtime helper instead of
the interpreter's `runAction`. `:587` and `:859` are the same shape more weakly — one lands inside
a variable declaration list, the other inside a comment about the JIT seed gate; both read as
plausible neighbourhoods rather than as obvious misses.

> **DOCTRINE: CITE THE MECHANISM AND ITS ENCLOSING FUNCTION. LINE NUMBERS ARE HINTS, NEVER
> LOAD-BEARING.** A claim's checkable content is *"`recursive` is cleared on the outermost restore,
> in `restoreLocalFields`"* — that survives every edit above it. *"line 587"* is a convenience that
> decays silently, and all three drifted citations here read plausibly if followed unchecked. Same
> family as `RULE H9`: an instrument that answers plausibly is worse than one that fails loudly.
> **When a claim is re-cited, re-grep the mechanism; do not carry the number forward.**

**2. THE SCOPE IS WIDER THAN "RECURSIVE ACTIONS".** `field.recursive` is a **STATIC** flag set at
parse time by identity (`ruleActions.rtn:1387` — see the drift table above), so the save/restore
bracket runs on **every**
call. K4 **never took its recursive branch** and came back emptied identically. So the claim bites
**any action that MENTIONS ITS OWN NAME, on every invocation** — recursion or not. The cost is not
"recursion is expensive", it is "naming yourself anywhere in your body is".

**3. K1 RETURNS THE BARE TAG, NOT A ZERO** — a field with no data returns its tag from `.text`, so
the local is genuinely **emptied**, not reset to a value.

⚠ **THE JITTED HALF IS NOT ASKABLE YET, which is itself a finding.** Parity legs were written, run
and removed: **`return` under jit has NO EMITTER** (it calls `jitDegrade`), so a claim *about what
a return hands back* has no jitted form to compare. Every green rung on `jitLadder` asserts a
**FIELD's** value after the action and never a **returned** one — this is why. Parked behind a
named gate: it becomes askable when `return` gets an emitter. (Driving those legs also hit a
separate pre-existing defect, `incant/inlineSelfT` — an inlined callee's self-call re-enters the
whole enclosing function — so rule H5 kept the SIGSEGV out of a fixture characterising something
else.)
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

> ### ⚠⚠ MEASURED 2026-08-10 — REMOVING THE GATE DOES NOT ESCAPE KANT-8, IT UNIVERSALISES IT.
> ### THE UNCONDITIONAL BRACKET IS BLOCKED ON THIS CLAIM, AND THE SENTENCE ABOVE IS THE BLOCKER.
>
> The KANT-8 unconditional bracket fix (docs/wakeup.md NEXT ACTION, GO given 2026-08-09) was built
> and run: all four `if field.recursive` gates removed — `jitSaveFrameRT`, `jitRestoreFrameRT`, and
> `runAction`'s own save/restore pair. It compiles, links and runs. **It also turns this claim from
> a property of self-mentioning actions into a property of EVERY action**, because the gate was the
> only thing keeping `restoreLocalFields` away from the return seam on ordinary calls.
>
> **The fixture's own validity control is what says so, which is the cleanest possible form:**
>
> | row | shape | gated (baseline) | UNGATED |
> |---|---|---|---|
> | **K3** | **NON-recursive**, returns a local — *"want 42; if this is not 42 the fixture is void"* | **42** | **`k3loc`** |
> | K6a | mutual A→B→A, cursor carried | 2 | **`k6seen`** |
> | K6b | control, local written after the call | 3 | **`k6seen2`** |
> | K6d | control, re-iterate, no recursion | 3 | **`k6seen3`** |
> | K6e | two walks, no recursion at all | 1 | **`k6seenB`** |
> | K6f | mutual, sized so three readings give three numbers | 4 | **`k6seen5`** |
>
> **K3 IS THE ROW THAT MATTERS AND IT IS THE ROW THAT WENT VOID.** Its whole job, per the 08-05
> table above, is to separate *"returning a local is broken"* from *"`recursive` is the
> discriminator"*. Removing the gate **removes the discriminator**, so K3 answers the first way —
> and every row below it is then **uninterpretable rather than wrong**, by the fixture's own
> declared terms.
>
> ⚠ **CONSEQUENCE FOR THE PREDICTION THE RUNG CARRIED.** The dispatch predicted K6's failure
> signature would **invert completely**, and said a *partial* recovery would mean something
> non-bracket was hiding in the blast radius. Neither happened: **K6 did not partially recover, it
> stopped being readable.** So the prediction could not be evaluated on this build — and the thing
> "hiding in the radius" was not hidden at all. **It is this claim, RUN-confidence since
> 2026-07-29, sitting on the same seam and named three paragraphs above as Tony's design call.**
>
> **THREE INDEPENDENT WITNESSES, ONE SIGNATURE**, which is what makes the mechanism pointable
> rather than inferred (this domain's causal claims are a coin flip until run):
> ```
>   incant/kant8T   K3        return k3loc   ->  k3loc          the control, voided
>   incant/genEmit  speller   return leaf    ->  leaf           85 rows of spell.target + rung5
>   jitLadder JRt1  oracle    interpreted    ->  ''             vs jitted 21
> ```
> `genEmit` is the sharpest of the three because **its own header already predicted it**: *"`return
> <unset local>;` yields the local's tag"*. It is a kant speller whose answer `emitLeaf` treats as
> authoritative, so a blanked return propagates straight into generated parser text as the literal
> word `leaf`.
>
> **THE MECHANISM, READ NOT INFERRED** — and it is exactly this claim's `statement` with the
> qualifier deleted: `runAction` calls `restoreLocalFields(field)` **after** `processAction` and
> **before** `return result`, and `result` *is* the local's node. Gated, that reached only
> self-mentioning actions. Ungated, it reaches all of them.
>
> **SEQUENCING RULED BY MEASUREMENT: KANT-8's repair is a PREREQUISITE of the unconditional
> bracket, not a follow-on.** The two cannot be ordered the other way, because the gate *is* what
> currently bounds KANT-8's blast radius. **The design call named above is now on the critical
> path**, and it is unchanged in substance: detach the result before restoring, or restore before
> reading it.
>
> **Fleet evidence, full before/after/revert capture, 16 entry points:** ungated, `ladder.sh` 0→1
> (JRt1) and `pop.sh` gained two red targets (`rung5.target`, `spell.target`); `oneTest`,
> `jsonTest`, `phaseA`, `emitAll`, `tree`, `printPop` stayed **byte-identical**, so the damage is
> precisely the returns-a-local population and not a general breakage. **Reverted; the fleet
> returns to baseline with every remaining diff an H1 binary echo or a pinned-crasher PID.** The
> patch is small and reproducible — four gate removals in `GroupActions.rtn`.

> ### ⚠⚠ M1 + M2 RUN 2026-08-10 — THE DETACH PRECONDITION **FAILS**. STOP AND RECONVENE, NO CODE.
> ### AND THIS TABLE IS THE LEDGER OF RECORD — `KR-3` IS RETIRED, IT NEVER EXISTED AS A FILE.
>
> Both probes from the M-gated dispatch, run on the shipping gated binary with **no source
> change**. The pick was conditional on both coming back clean. **M2 does not.**
>
> **M2 — THE WALKER READ. IT PAIRS POSITIONALLY, VIA AN UNKEYED LIFO. DETACH BREAKS IT.**
> `saveLocalFields` walks the action's fields **forward** pushing a `GroupBody` per qualifying
> member; `restoreLocalFields` walks **backward** popping one per qualifying member. **Nothing
> associates a body with its field except walk position** — the `Stak` carries no key.
> ```
>   save   f1 f2 f3   ->  push b1 b2 b3
>   restore (backward) ->  f3<-b3   f2<-b2   f1<-b1        correct
>   with f2 DETACHED   ->  f3<-b3   f1<-b2   and b1 STRANDED ON THE STACK
> ```
> So a mid-frame detach does not merely fail — **it hands `f1` the body that belonged to `f2`**
> (a plausible wrong value, #26's family) **and leaks a stack entry into every later activation
> sharing that `stak`.** Silent both ways.
>
> ⚠ **THE TREE ALREADY SAYS THIS, IN THE JIT'S OWN DESIGN RATIONALE**, which is why this is a
> reading rather than an inference — `GroupRules.mm`, FRAME EPILOGUE, Increment 1: *"restoreLocalFields
> walks BACKWARD **because it pops a stack**, and this does not — each slot has its own address, so
> there is no ordering to honour. **That asymmetry is the point: the stack discipline was the bug
> surface, and it is gone rather than reimplemented.**"* The JIT declined to reimplement the
> positional pairing on purpose; the interpreter still has it.
>
> **CONSEQUENCE FOR THE COST ARGUMENT, stated plainly because it is the pick's whole basis:**
> *"one unlink at one site"* does not survive M2. A correct detach must also remove that field's
> body from the stack, and the stack is positional — so it is **walker surgery, not an unlink**.
> **The principled version is to key the restore by field instead of by position**, which is a
> bigger change than either option the dispatch weighed, and it is Tony's.
>
> **M1 — THE RETURN-CHANNEL PROBE. CLAY'S HYPOTHESIS IS CONFIRMED, ON A TEMPLATE-SHAPED FIXTURE.**
> `incant/kant8M1` (jitted) and `incant/kant8M1o` (interpreted, own process, per the jitJRt2o rule).
> One action, one `testing()`, then `jitRefire()` — the corruption is unconstructable in this shape.
>
> | | interpreted | jitted |
> |---|---|---|
> | returned value | **`m1count`** — the TAG | **42**, then **45** on refire |
> | degrade / compile | — | **0 / 1** |
>
> **The interpreter hands back the NODE**, which the sweep has reverted under the caller. **The jit
> hands back a VALUE** that left the node before the sweep could reach it — pointable in the emitted
> code: the frame epilogue stores each slot back and *then* `CreateRet(CreateLoad(i32,
> gJitResultSlot))`. **So the defect is interpreter-side aliasing, and the jit arm owes byte-agreement
> only, not surgery** — exactly as the dispatch predicted. Ladder rung **JRt3** already certifies the
> same divergence on the `kant8T` shape; M1 adds that it holds on the template population too.
>
> ⚠ **AND M1 ANSWERED A QUESTION IT WAS NOT ASKED, WHICH IS THE MORE USEFUL HALF: THE FRAME BRACKET
> IS NOT BROKEN. ONLY THE RETURN SEAM IS.** Printed from *inside* the action, both locals restore
> **perfectly** at every depth, in both directions, on **both** engines:
> ```
>   before  42 / 41 / 40        after  40 / 41 / 42
> ```
> Per-activation state is correct. **The bug is not "the bracket empties locals" — it is "the
> returned pointer points into the frame being restored", which is this claim's own closing
> sentence.** A repair that preserves the bracket and fixes only the seam is therefore sufficient,
> and that narrows the design space usefully.
>
> **SCALAR VS NODE-VALUED — First Light's floor, and the answer is BOTH, plus a new defect.**
> Scalar-valued locals are covered: `K1`/`K3`'s `k1loc = 42` and `k8loc = k8n + 40` are counts and
> both come back as tags. **But the probe also found a silent wrong answer on the jitted arm** — a
> **text** local prints as its **LENGTH** (`"alive"` → `5`, `"xy"` → `2`), degrade **0**, exit 0,
> while the count local beside it is right at every depth. Filed as **`docs/knownErrors.md` KE-4**,
> unruled, Tony's — it is outside this claim, and the certified template never put text in a local,
> which is why nothing had tested that fence from the other side.
>
> **`KR-3` RETIRED (Tony, 2026-08-10).** The ledger never existed as a file; the single tree-wide
> grep hit was the obligation sentence citing it — **a ledger spoken into being by the instruction
> to update it**, Amendment A's family. **The K-row table in this claim is the ledger of record**
> and future briefs name this file and this table. The obligation line in `docs/wakeup.md` carries a
> dated retirement note rather than a deletion, per the legibility rule.

> ### ✅ THE NODE-RETURN CENSUS — RUN 2026-08-10. **REAL CUSTOMERS: ZERO.** FORK BRANCH 1 EXECUTES.
> ### AND THE SEAM FIX IS RULED: **VALUE-CAPTURE, ALIGNED TO THE JIT'S CHANNEL** (Tony, 2026-08-10).
>
> **R1 — THE RULING.** `runAction` captures the result's value **before** the restore sweep and
> returns the captured value. **The bracket is untouched** — M1 measured it restoring perfectly at
> every depth on both engines, so the defect is the seam and only the seam. This is **alignment,
> not workaround**: M1 measured the jit already returning through an i32 result slot loaded after
> the epilogue, so **value-capture is the certified arm's existing semantics** and the interpreter
> is adopting it. Blast radius: `runAction`'s return neighbourhood. **The jit arm owes
> byte-agreement only.**
>
> **THE CENSUS, H9 DISCIPLINE, AND/OR's 165-vs-7 as the worked precedent.** ⚠ **CORRECTED
> 2026-08-11: that precedent's own numbers were WRONG — re-measured 294-vs-~30, and the 08-09
> pass had missed `incant/utilities` entirely, a file inside its own scope and `include`d by
> every fixture preamble in the tree. The CONCLUSION held (zero side-effecting right arms), the
> arithmetic and the file set did not.** It remains the worked precedent for H9 — it is simply a
> stronger one than intended, since it now demonstrates the failure as well as the discipline.
> Scope: `incant/`,
> `XML/`, `IncantForms/` — the files that actually carry `code={}` bodies (118 of them).
> ⚠ **`*.rtn` IS OUT BY CONSTRUCTION, not by choice**: its 581 `return`s are C++/tok functions, and
> `genParse.rtn`'s five `code=` hits are all **inside comments**.
> ```
>   surface-form matches (the word `return`)                    727
>   statement-position `return <bare name>;`                     65
>     less comment/prose lines quoting a return                  -9   -> 56
>     less keyword returns (`return true` / `return false`)      -4   -> 52
>     less `return argument;` (K2: arguments are saved AS BOUND) -1   -> 51
>   of those 51, by what is returned:
>     scalar / count locals                                      44   the bulk
>     TEXT locals                                                 6   <- KE-4's population, not this one
>     NODE-VALUED locals                                          2   <- THE CENSUS SUBJECT
>   of those 2, real customers relying on identity                0
> ```
> **Arithmetic checked against the rows, per the six-uses-four-files cautionary case: 44 + 6 + 2 =
> 52 candidates before the `argument` subtraction, 51 after — the count is stated both ways because
> that is the step the earlier census got wrong.**
>
> **THE TWO NODE-VALUED RETURNS, BOTH DISCHARGED, EACH FOR A DIFFERENT REASON:**
>
> | site | what it returns | verdict |
> |---|---|---|
> | `incant/utilities:69` — `JSONfield` | `token`, a real parsed node the JSON tree is built from | ⚠ **OUT OF THE SEAM'S REACH BY MECHANISM** — see below |
> | `incant/unitTests:166` + `scopeUnits:183` — `testNew` | `grup = new(argument)`, a minted node | **DEAD** — its only two call sites are **commented out** (`:202`, `:219`) |
>
> ⚠⚠ **THE MECHANISM FINDING, AND IT IS BIGGER THAN THE CENSUS: A CODED *RULE* NEVER ENTERS
> `runAction` AT ALL.** `ruleActions.rtn:352` binds it directly — `or isCoded method =
> processAction;` — and `processAction` is called from `runAction` at `GroupActions.rtn:790` **and
> from nowhere else**. `runRule` goes to `rule.parse(0)`. **So there are two entry paths into an
> action body, and only one of them has a frame bracket or a return seam.** Consequence: the entire
> grammar/XML population — every `isRule … code={}`, `JSONfield` included — is **outside both**.
> That is why `jsonTest`'s 13 rows never met KANT-8, and it is why the census comes back empty
> rather than merely small.
>
> **H9's widening was run and found nothing further.** Re-matched against every `return <anything>;`
> form the bare-name regex would miss: `return argument.taG;`, `return spellMany(many);`,
> `return xrIn * 2;`, and the literals. **Zero additional node-valued candidates**, so the boundary
> holds under a wider match rather than only under the one that produced the number.
>
> ✅ **FORK BRANCH 1 THEREFORE EXECUTES, PRE-RULED AND WITHOUT RECONVENING: the capture fix is the
> whole repair.** No node-return population needs fencing; no keyed-restore design item is opened.
>
> ⚠ **CARRIER DISCIPLINE — DATED RETIREMENT NOTE, 2026-08-10, NOT DELETION.** `CLAIM KANT-22`'s
> *"anything that must survive a recursive call lives on a carrier node"*, measured into K1–K4 and
> then **narrowed by K6c to direct self-recursion only**, is **obsoleted by the seam fix**: once the
> returned value is captured before the sweep, a local survives its own return and there is nothing
> to carry it out of. **It survives for no population** — the mutual case it already failed, and the
> direct case is what the fix removes. The K1–K4 rows stay exactly as written; they record what was
> true and why, and the mitigation was correct for the period it covered.
>
> ⚠ **A DESIGN CONSTRAINT THE CENSUS TURNED UP, AND THE SEAM RUNG SHOULD START FROM IT: CAPTURE
> MUST RETURN A NODE CARRYING THE VALUE, NOT A BARE SCALAR.** Both live `runAction` consumers on the
> genParse kant seam null-check the result **and then read `.text` off it**:
> ```
>   genParse.rtn:847  manyKant   if !result return 0;   if result.text eq "1" return 1;
>   genParse.rtn:964  speller    if !result return null; return result.text;
> ```
> A capture that hands back a raw integer breaks **four** reads at two sites. The value channel has
> to stay node-shaped at the boundary even though the value is what is being preserved.
>
> **REFINED TO THE RUNG'S SPEC (2026-08-10): MINT A FRESH NODE, COPY THE VALUE IN, RETURN THAT —
> never the local's node.** ⚠ **And the census pre-cleared exactly this**: *zero identity customers*
> means a fresh node is **indistinguishable from today's behaviour for every living caller**, which
> is what turns "mint a node" from a semantic change into a no-op with the bug removed.
> ⚠ **ONE DESIGN QUESTION FOLDED INSIDE IT, AND IT IS ONE SENTENCE OF SPEC: THE NULL PATH.** Both
> sites distinguish a node from a **null** (`if !result`), so the capture **must preserve "no
> result" as null rather than minting an empty node** — otherwise both null-checks silently invert
> and an empty answer starts reading as a successful one. That is the bear-trap #26 shape arriving
> through the fix rather than through the defect.
>
> ⚠ **AND THE CROSS-FINDING TO KE-4, WHICH IS THE ONE TO ACT ON: THOSE SAME TWO SITES RETURN *TEXT*
> LOCALS.** `genEmit`'s `leaf` and `genMany`'s `answer` are body-born text locals returned from live
> kant actions that **do** go through `runAction`. **So KE-4's silent-length defect has real
> customers waiting — the kant speller and manier — the moment those actions are jitted.** The
> refuse-at-emit ruling (R2) is what keeps that loud instead of silent, and the six text returns
> above are its measured population.
>
> **R2 / R3 recorded elsewhere:** KE-4's ruling in `docs/knownErrors.md`; the `i32`-by-rule fence in
> `docs/attributesTemplate.md` §6, frozen with the template shapes.
>
> **TWO CLAY CLAIMS DIE IN THIS RULING AND BOTH ARE LEDGERED WITH THE MISSES** (his own instruction):
> the **detach pick** fell to M2's walker measurement — the cost calculus rested on an unmeasured
> tolerance premise, and **the conditional-pick discipline caught it before code**; and the
> **copy-forks-the-arms** risk row **had its sign backwards** — M1 shows capture *converges* the
> arms, because the jit already returns by capture. **The risk register was written before the
> channel was measured**, which is the whole lesson and not a criticism of the register.

> ## ✅✅ CLAIM KANT-8 IS REPAIRED — BUILT, RUN AND GREEN, 2026-08-10 (SEQ 27, both rungs, one seal).
> ## THE LEDGER OF RECORD FOLLOWS. Confidence **RUN**. Fleet at seal: ladder **173 / exit 0**,
> ## pop **33 green / 1 parked**, every other harness at its baseline exit.
>
> **WHAT LANDED, IN TWO RUNGS, IN THE ORDER THE 08-10 MEASUREMENT SAID WAS THE ONLY POSSIBLE ONE.**
> Rung A repaired the **seam**; rung B removed the **gate**. The prior attempt failed because it
> tried B without A, and the block above is what diagnosed that — it is now discharged.
>
> **RUNG A — VALUE-CAPTURE IN `runAction`.** After `processAction` and **before** the restore sweep,
> the result's value is copied into a freshly minted node and that node is returned. Three clauses,
> each with the caller that makes it load-bearing:
> 1. **Mint fresh and copy in** — never the local's node, never a bare scalar. `manyKant`
>    (`genParse.rtn:847`) and `spellKant` (`:964`) both null-check the result **and then read
>    `.text`** off it. ⚠ **The copy constructor cannot be used here**: `GroupItem(GroupItem)` is
>    body-**sharing** (`groupBody = grup.groupBody`), i.e. it aliases the very body the sweep
>    overwrites. Mint on a tag, then `setContent` — that is the detaching form.
> 2. **Mint on the result's own tag**, so `.tag` and `.text` answer exactly as before. `setContent`
>    already stamps the tag as text for a contentless item, so bear-trap #26 does not bite.
> 3. **Preserve null as null** — see the honest note below, because this one is *not* what it looks
>    like.
>
> **Gated `!jitting`, deliberately.** The jitted arm already returns by capture and is the certified
> one; its node in flight is the value channel an enclosing assignment reads through `jitData`,
> which a fresh node would not carry. The jit owed **byte-agreement only** and delivered it — 173/0
> with no IR-shaped row moving.
>
> **RUNG B — THE UNCONDITIONAL BRACKET.** All four `if field.recursive` gates removed
> (`jitSaveFrameRT`, `jitRestoreFrameRT`, and `runAction`'s own save/restore pair).
>
> > ### ⚠ DATED NOTE — `field.recursive` IS VESTIGIAL AS OF `168453d` (2026-08-10)
> > **Written, cleared, and read by nothing.** The four gates removed by this rung were the flag's
> > **only readers** (tree-wide grep, same day). What remains is a **writer** at
> > `ruleActions.rtn:1389` (parse time, by identity) and a **clearer** at `GroupActions.rtn:653`
> > (run time, inside `restoreLocalFields`) — two sites maintaining a bit that nothing consults.
> > **Removal is DEFERRED, not forgotten:** it is a field-removal and therefore bear-trap #16
> > territory (`groups.ext`'s `external` mirror must be edited first or `tokall` will not drop it),
> > which is a bigger blast radius than this rung's scope. **Same family as the `ruleSTUFF`
> > write-only ruling** — a field kept alive by its writers after its readers went away.
> > ⚠ **This note exists so a future census reads it as a KNOWN state and not as a mystery**, which
> > is the failure it is written against. *(Provenance care: the `ruleSTUFF` comparison is Tony's,
> > relayed SEQ 29; a grep for that ruling's own text did not locate a file, so it is cited as a
> > family resemblance and NOT as a line reference. Whoever formalises it should locate the original
> > rather than inherit this sentence — Amendment A's lesson, applied to my own citation.)*
>
> ### THE K-ROW TABLE — THE LEDGER OF RECORD
>
> | row | shape | 08-10 baseline | after rung A | after rung B | verdict |
> |---|---|---|---|---|---|
> | **K3** | NON-recursive, returns a local — **the validity control** | 42 | **42** | **42** | ✅ held; the fixture is valid, so every row below is readable. This is the row the previous attempt voided |
> | **K1** | recursive, returns a local | `k1loc` | **42** | **42** | ✅ **KANT-8 repaired** |
> | **K4** | recursive, branch never taken | `k4loc` | **42** | **42** | ✅ repaired |
> | **K5** call 1 / 2 | invocation-history dependence | `k5loc` / `k5loc` | **42 / 42** | **42 / 42** | ✅ repaired, and history-independent |
> | **K2** | returns its ARGUMENT | 7 | 7 | 7 | unchanged — the carrier already dodged it |
> | **K6a** | **mutual** A→B→A, cursor carried | 2 | 2 | **3** | ✅ **rung B's payoff** — "its own cursor". The gate could never cover this: `recursive` is set at parse time **by identity**, so mutual recursion never set it |
> | **K6b / K6d / K6e** | controls | 3 / 3 / 1,1 | same | same | ✅ unmoved, as controls must be |
> | **K6c** | mutual, the ARGUMENT read after the call | `k6small` | `k6small` | `k6small` | unchanged — **still the inner's binding**; the argument-carrier's mutual failure is NOT repaired by either rung |
> | **K6f** | mutual, sized for three readings | 4 | 4 | 4 | ⚠ **number unmoved, MEANING changed — see below** |
>
> **⚠ K6f HAS COLLIDED, AND IT IS THE DAY'S ONE-CHANNEL-ONE-MEANING MEMBER.** The row was sized in a
> world where the bracket ran only for directly self-mentioning actions, so its "5 = no trample"
> reading assumes the outer activation's **counter** carries across the inner call even if its
> cursor does not. With the bracket unconditional the counter is per-activation too, so the outer
> simply counts its own four attributes — **which is also 4**. So 4 now means either the old
> trample-and-restart or the new fully-bracketed walk, from two different eras, on one number.
> **K6a disambiguates**: same shape over a **three**-attribute outer list, so 2 means trampled and 3
> means the activation kept its own, and K6a moved 2→3 on the build that left K6f at 4. The pair is
> consistent and the world is the bracketed one. **The fixture carries a dated note; it was NOT
> re-sized** — choosing new widths so K6f discriminates alone is a fixture-design decision and
> belongs to whoever owns this table, not to the rung that revealed the collision.
>
> > ### 🔧 THE RE-SIZE, SPEC'D AND AWAITING TONY'S NOD — DRAWER ITEM, NOT APPLIED
> > **Tony, SEQ 29.** The restraint above is ratified — *"a fixture whose meaning changed is a
> > design object again"* — and the repair is one line.
> > **THE FIX: make the outer and inner list widths DIFFER, so the two eras stop aliasing.**
> > Suggested **outer 5, inner 3** (today: outer 4, inner 2). The collision exists because the old
> > counter-carries-across arithmetic and the new per-activation arithmetic land on the same total;
> > with the widths separated, **the old semantics predicts one number and per-activation predicts
> > another**, so *"no trample"* becomes **discriminating again instead of coincidental**.
> > ⚠ **Whoever takes the next K-row rung carries this.** Re-state both predicted numbers in the
> > row's legend when it lands, so the row cannot re-collide silently — and note that a re-size
> > makes K6f independent of K6a again, which is the property its original comment claimed and
> > this rung measured it to have lost.
> > **The failure class now has a name:** `oneNumberTwoEras`, minted into the decoder corpus the
> > same day — *a green that survived a semantics change by arithmetic accident.*
>
> ### ⚠ CLAUSE 3 IS THE HONEST ROW, AND ITS FIRST FIXTURE WAS GREEN AND CERTIFIED NOTHING
> `incant/kant8N` was written as clause 3's negative control. It passed. **Then the control ran and
> the row did not move** — because `runAction` has **two** ways of answering with nothing, and the
> fixture reached the wrong one. The **reachable** null is the early return taken when a coded body
> fails to parse, which happens **above** the seam and preserves nothing-ness without the seam being
> involved. The **guarded** null is a run that gets past that and still yields no result — and a
> sweep of the whole structural fixture population measured that occurring **0 times in 128 files**.
> **So the guard is correct and prevents a null dereference, but it is uncontrolled by any fixture,
> and no negative control for it can be written until a reachable case exists.** `kant8N` now says
> so in its own header and labels its rows for what they measure. **Recorded rather than papered
> over: an uncontrolled guard is a known gap, and a green row invented to cover it would be worse
> than the gap.**
>
> ⚠ **AND THE ZERO HAS A MECHANISM — see `BLOCKED KANT-B1`, filed a week earlier by a different
> round.** B1 tried **four ways to produce a null from a kant body and could not.** So the 0-in-128
> is not *"nobody happens to do this"* but *"kant cannot express it"*, which is a much stronger
> statement and settles the ambiguity a bare count would have left. **The guard stays uncontrolled
> until B1 is solved**, and B1's blocker is now located as **upstream of the seam** — clause 3
> preserves a null if one ever arrives, so the probe belongs at `processAction`'s `BlocK` result and
> not at the return.
>
> ### CARRIER DISCIPLINE — THE DATED RETIREMENT NOTE THE OBLIGATION ASKED FOR
> **It survives for exactly one population, and it is not the one it was written for.** For
> **direct** self-recursion the carrier is now **obsolete**: K1/K4/K5 return their locals correctly,
> so parking a value on an argument buys nothing a plain local does not. For **mutual** recursion it
> was already **invalid** (K6c, 2026-08-05) and **remains invalid** — K6c is unmoved at `k6small`
> after both rungs. ⚠ **So the discipline is retired as a mitigation and survives only as a warning:
> the carrier never worked for A→B→A, and the unconditional bracket does not change that.** Not
> deleted, per the legibility rule.
>
> ### WHAT THIS DOES NOT REPAIR, STATED SO IT IS NOT OVERSOLD
> **KE-4 is untouched** — a *text* local on the **jitted** arm still returns its LENGTH. Rung A is
> gated `!jitting` by design, so it could not have touched it, and KE-4's refusal rung stays in the
> drawer as briefed. **K6c is untouched** (above). **The `recursive` flag is now vestigial** but not
> removed.
>
> ### BLAST RADIUS — the standing rider, rung-1 format
> Full fleet captured before and after **each** rung, every stream diffed. **Every harness: only the
> H1 binary echo differs, every exit status identical** (gapB, mixed, tree, printPop, containerPop,
> recordPop, formsPop, decodePop at 0; completePop at its owned-red 1). `oneTest`, `jsonTest`,
> `phaseA`, `emitAll`, `kant8M1`, `spellScratch` **byte-identical**. Named movements, all four
> accounted: **`kant8T`** (the K-rows above) · **`kant8M1o`** (`m1count` → **42**, the repair's
> second witness) · **ladder JRt3** (graduated, below) · **`completePop`** 127→**128** swept and
> 220→**222** green, both `kant8N`'s own two checks; abandoners **3** and missing sentinels **2**
> unchanged. ⚠ One apparent diff was **a capture asymmetry in the measuring, not a change**: the
> baseline split stdout/stderr and the verdict run combined them, moving the two pinned-crasher
> segfault lines between streams. Counted, named, dismissed.
>
> ### H6 GRADUATIONS — with their sentences, values never counters
> - **ladder JRt3** was pinned to the INTENDED DIVERGENCE (*interpreted returns the tag `k8loc`,
>   jitted returns 42*). It is now a full **AGREEMENT** check (42 == 42), and the old tag reading is
>   an explicit **regression** arm rather than a silent else. **The target moved because the seam
>   now takes the value before the sweep, so the interpreter no longer hands back a pointer into the
>   frame being restored.** ⚠ **The harness predicted this in advance and its own message caught
>   it** — *"That is not a regression, it is NEWS: KANT-8 may have been repaired."* Ladder stays at
>   **173**: a graduation, not an addition.
> - **`incant/kant8M1o`** likewise: its header already said *"if the interpreted column ever starts
>   agreeing with the jitted one, that is the KANT-8 repair landing, and this row is what says so."*
>   It said so. Label moved to want 42, with the tag named as the regression.
> - ⚠ **Both JRt3's harness text and the wakeup obligation cited `KR-3`.** Repointed to **this
>   table**, with the retirement noted in place rather than deleted.
>
> ### ⚠ THE CROSSING COUNTER — THE TWO DOORS, MEASURED ON BOTH SIDES
> Run before the edit, over `completePop`'s **structural** fixture population (127 files) so the
> scope is defensible rather than hand-picked. Scaffold only; removed before sealing.
>
> | door | mechanism | crossings | as action | as RULE |
> |---|---|---|---|---|
> | **one** — `runAction` | bracketed, seamed | **523** | **523** | **0** |
> | **two** — `runRule` → `rule.parse(0)` | frameless | **1183** | **0** | **1183** |
>
> **1706 dispatches, zero overlap**, and the 211 door-one names and 12 door-two names are **disjoint
> as sets**. ⚠ **The 0 is a positive result, not an absence claim** — door two is not merely failing
> to cross the seam, it is carrying the *entire* rule population somewhere else, which is what makes
> the 0 meaningful (H4). Independently, a static enumeration finds **exactly four `runAction` call
> sites** — `GroupActions.rtn:895`, `Commands.rtn:191`, `genParse.rtn:847` and `:964` — and `runOP`
> tests `or isRule` **before** `or actionType`, so a rule cannot reach the seam by construction.
> **This measurement certifies the TWO DOORS ruling (Tony, 2026-08-10) rather than merely scoping
> the rung**, and under that ruling this campaign is **maintenance of door one, the legacy door** —
> completing its correctness, not investment in the destination path.

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
> ⚠⚠ **SCOPE DEFEATED 2026-08-01 — THE CLAIM NAMES THE WRONG METHOD.** Its scope says it bars
> `emitPlan`, *"which accumulates text across a walk and reads its accumulator after each recursive
> call."* **`emitPlan` HAS NO RECURSIVE CALL** — it is two flat `while node = plan.nextMember(node)`
> loops (`genParse.rtn:863-893`; `docs/wakeup.md:458` says so outright). Self-call counts taken
> independently by minionA and by the foreman agree: `emitPlan` **0**, `printPlan` **1**.
> `terms = terms joiner piece` accumulates across a LOOP, which nothing in KANT-5/6/7/8/22 touches.
>
> **The claim is RIGHT ABOUT THE LANGUAGE and WRONG ABOUT THE METHOD.** The barred shape is real
> and it lives in **`printPlan`** — `deeper` and `kid` are locals read *after* a genuine self-call
> returns — which KANT-22 never mentions. So the carrier discipline is **not owed by `emitPlan`**,
> and building it there would be speculative design.
>
> Same family as KANT-16, and the same lesson: take the structural distinction, then CHECK THE
> CLAIM ABOUT THE TREE. The language half stands unchanged. See `docs/genParseArcMap.md`.
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

### CLAIM KANT-33 — a closing `}` is INDENTATION-SENSITIVE, and its failure is disguised
*⚠ RENUMBERED 2026-08-01, same day it was filed. It was briefly `KANT-24`, which was ALREADY
TAKEN by the zsh `${PIPESTATUS[0]}` claim above. minionA caught the collision mid-round and
declined to renumber on its own grounds that "an ID is a citation trail" — correct, and the
reason the elder keeps the number. Cited as KANT-24 in one commit message (`f811d8a`) and in one
message to the round; those references are left as written, because rewriting a provenance
falsifies the record of what was actually said.*
```
statement:   `}` / `};` are POSITION-sensitive to the parser (checkSkip), not
             free-form. The case that bites: when an action's LAST body
             statement is itself a nested block -- a `while`, an `if`, an
             `iterate` loop -- the action's closing `};` must DEDENT onto its
             own line, after the nested block has closed. Closing on the same
             line, or at the nested block's indentation, breaks the parse.

                 WRONG                          RIGHT
                 myAct code={                   myAct code={
                     iterate g on argument;         iterate g on argument;
                     while ++g;                     while ++g;
                         print g:; };                   print g:;
                                                    };

confidence:  Tony, volunteered 2026-08-01 as a known property of the parser.
             READ at the corpus level -- not independently re-derived here.
provenance:  Tony direct, mid-round, unprompted. He raised it precisely because
             "it is not obvious and could take minionA multiple cycles to
             stumble over."
asOf:        2026-08-01
scope:       ⚠ THE SYMPTOM IS DISGUISED, AND THAT IS THE EXPENSIVE HALF. An
             incant parse failure ABANDONS THE REST OF THE FILE AND STILL EXITS
             0 (CLAUDE.md testing doctrine, third corollary) -- no `stop:` line,
             prior output flushed, every assertion before the bad line still
             passing. So a brace-indentation error does NOT announce itself as a
             brace problem; it reads as "my action did not run" or "it ran
             short", and the search goes to the logic.
             THE DISCRIMINATOR IS THE SENTINEL: reached it ⇒ not this; absent ⇒
             suspect the closing brace BEFORE the logic.
             Related but distinct from bear-trap #4 (a `//` between an `if`'s
             condition and its statement) and from the `-% %-` cases: those are
             about what occupies a statement slot, this is about WHERE a
             terminator sits.
```
**Why this is in the corpus and not in the brief.** The spawn rule is explicit --
anything learned goes in the corpus or it goes nowhere, because a patched brief
carries the learning and the corpus looks like it is absorbing while the brief does
the work. This is a standing property of the tree rather than a round's finding, so
it belongs to every round equally.

---

### CLAIM KANT-25 — the minionA round-2 crash cost NOTHING, and the reason matters more than the crash
```
statement:   minionA round 2 died on a server-side 500 at the exact moment it
             was about to write its deliverable ("Now I'll write the
             deliverable"). MEASURED LOSS: ZERO BYTES AND ZERO SYNTHESIS.
             THE TRANSCRIPT IS THE PERSISTENCE LAYER, and resume reads it. The
             round was resumed from transcript with full context; recovery was
             ONE message.
confidence:  RUN (the timeline is from file mtimes and commit times, not memory)
provenance:  17:29:43  foreman commit; `git status` shows NO untracked files
                       -> nothing of the minion's was on disk at crash time
             ~17:30    round resumed from transcript
             17:31:56  incant/genMany written      <- POST-resume
             17:35:02  incant/manyScratch written  <- POST-resume
             Both artifacts are the RESUMED round's, not crash residue. The
             foreman's first instinct was that they were survivors; the mtimes
             say otherwise, which is why they were checked.
asOf:        2026-08-01
scope:       Scoped to a crash where the agent REMAINS RESUMABLE IN-SESSION.
             It says nothing about a lost session or an expired transcript,
             which are different and rarer events.
```
**⚠ THE AUDIT DEFEATS ITS OWN FRAMING, AND BOTH BRANCHES OF IT.** The question was
posed as "did minionA absorb-as-it-went or batch for the end?", with the fallback
"if absorb-as-you-go was already the doctrine and this minion batched, the fix is
enforcement, not invention."

**Neither branch holds. THE BRIEF MANDATED BATCHING** — item 4 of the deliverable
reads *"A B0-format claim … returned as your final text."* The minion did exactly
what it was told. There was no doctrine to enforce and no minion to correct; if
there is a gap it belongs to the foreman who wrote the brief.

### ⚠ AND THE PROPOSED CURE COLLIDES WITH THE SPAWN RULE — this is the finding

The standing prior was **report-incrementally**: the finish-up report as a running
file, appended per finding, so *"about to write the report"* is never a state that
exists. It is cheap and the reasoning is sound. **But it creates a NEW WRITE
SURFACE, and the spawn rule forbids exactly that:**

> *"THE TREE — during A, THE CORPUS IS THE ONLY SURFACE THE LOOP MAY WRITE TO.
> Write a round-learning into any doc that is not the corpus and round N+1 picks
> it up anyway; the corpus looks like it is absorbing while the filesystem does
> the work. THE CONFOUND LAUNDERED THROUGH DISK."*

A running report file is a doc that is not the corpus. Adopted naively it
reintroduces the precise confound the spawn rule was written to close — and it
would do so invisibly, because the file would look like bookkeeping rather than
like a channel.

**It is adoptable only if the file is ROUND-SCOPED and provably never read by a
later round**, which is a discipline that must itself be audited — and disciplines
get audited, structures do not.

### THE PRICED CANDIDATES, and the recommendation is to buy almost nothing

| discipline | overhead | verdict |
|---|---|---|
| **claim-on-finding, to the CORPUS** | ~0 — the same B0 block, written at discovery instead of at the end | ⚠ **but it bypasses gating**: the spawn rule says *the agent drafts, the foreman gates*. A direct corpus write is an ungated write |
| **report-incrementally, new file** | ~0 in minutes | **REJECT as specified** — new write surface, spawn-rule collision above |
| **checkpoint-on-milestone** | real: a bake step per method/claim | not justified by a measured loss of zero |
| **journaling / transcript persistence / session replay** | large | rejected by construction — Tony's constraint, and the audit gives them nothing to insure against |

**RECOMMENDATION: change nothing structural, and fix the brief instead.** The
measured loss was zero because resume already works. The one honest improvement is
a **brief** change, not a doctrine change: item 4 should ask for claims **as they
are found**, delivered into the round's own message stream rather than held for a
final synthesis. That costs nothing, adds no surface, and leaves gating intact,
because the foreman still promotes into the corpus.

⚠ **NOTE THE BRIEF-REVISION COST HONESTLY:** the spawn rule says a brief revision
*"is logged with a reason and IT BREAKS THE SERIES — comparisons restart from
there."* Round 2 is already the last round of the difficulty-cadence measurement
(ended by choice at the cerr reorder, instrument considered proven), so the series
cost here is nil. **It would not have been nil a week ago, and that is the reason
to say it out loud rather than let a free-looking edit set a precedent.**

### WT-11 does NOT extend, and `minionfire.md` does not exist
`CLAIM WT-11` is *"no silent overwrite — a write carries the whole file including
prior history."* That is a **concurrent-writer** hazard on a shared channel: two
writers, one file, one silently replacing the other. **This crash is a
loss-of-unwritten-work hazard: one writer, no file at all.** Different failure,
different cure; WT-11 addresses overwrite and has nothing to say here.

`docs/minionfire.md` **does not exist in the tree** (checked). The harness doctrine
lives in `docs/minionAHarness.md`, and that is where any line would go. Flagged
rather than created, because inventing a file to hold a recommendation that this
audit recommends against would be the wrong artifact twice over.

---

## ROUND 2's CLAIMS — KANT-26 … KANT-32 + KANT-B3, drafted 2026-08-01

*Method: `emitMany` (`genParse.rtn:666`) → `incant/genMany`'s `spellMany`; oracle
`genLadder/rung5.target` lines 1-10; fixture `incant/manyScratch`. Count these as
**absorption**.*

> ⚠ **ID COLLISION, flagged by round 2 rather than fixed by it.** There are **two**
> entries numbered `KANT-24` above — the zsh `${PIPESTATUS[0]}` environment claim and
> the closing-`}` indentation claim. Both are real and both are cited elsewhere.
> Renumbering is foreman's call, since a citation trail is exactly what an ID is for.
> Round 2 started at **KANT-26** because 25 was taken while it ran, and touched neither.

**Every one of these was found by a failing run, and five of the seven are about
writing TEXT rather than about the language's semantics. That is the round's
headline.** `emitMany` is 21 lines with no recursion, no iterator and two attribute
reads — the ledger pre-registered it as *"strictly simpler than emitLeaf"* — and yet
**every obstacle it hit was in the print/quote/parse layer, and none was in the layer
the corpus was carrying.** KANT-6…KANT-22 are a fine map of recursion and frames, and
not one of them fired. A corpus that carries only semantics will not shorten the next
emitter conversion; the next one needs KANT-26/27/29 on page one.

### CLAIM KANT-26 — a `}` CANNOT APPEAR ANYWHERE INSIDE A `code={ }` BODY, not even inside a quoted string
```
statement:   The CodE capture scans for the FIRST `}` after the opening `{`,
             with NO nesting count and NO quote awareness. So any `}` byte in an
             action body -- including one inside "..." or '...' -- ends the
             block early. The define then fails, the rest of the FILE is
             abandoned, and the process still EXITS 0. `{` is unaffected: only
             the first `{` is taken as the opener.
             => THE IDIOM: put the byte on the DEFINE LINE as a trait, outside
                the CodE scan, and reference it by name from the body:
                    spellMany argument closeBrace="}" code={
                        ...
                        cerr closeBrace:;
                        };
confidence:  RUN
provenance:  Bisected 2026-08-01 with a per-line fixture. Every line of the
             emitMany body parsed EXCEPT the one emitting `}`, and all four
             quoting spellings failed identically:
                 cerr "}":;      -> ERROR processCode: probe parse failed
                 cerr "x}y":;    -> ERROR processCode: probe parse failed
                 cerr $"}":;     -> ERROR processCode: probe parse failed
                 cerr '}':;      -> ERROR processCode: probe parse failed
                 cerr "{":;      -> OK, prints {
             The SAME statement at TOP LEVEL (not inside code={}) works:
                 cerr "TOP }brace in a top-level statement":;   -> prints, exit 0
             Mechanism READ at ruleActions.rtn:122-140, aCTionCodE:
                 while *atInput && *atInput != *left   atInput++;   /* the { */
                 beginBox = atInput; atInput++;
                 while *atInput && *atInput != *right  atInput++;   /* FIRST } */
             The trait workaround RUN in incant/genMany + incant/manyScratch:
             exit 0, sentinel present, rung5.target lines 1-10 byte-identical.
asOf:        2026-08-01
scope:       Covers `code={ }` bodies specifically -- the CodE rule
             (grammar:42, `CodE "{" "}" parseAction`). Says nothing about `}`
             inside a `-% %-` passthrough, and the workaround shows it parses
             fine in a DatA value on a define line. Does NOT establish whether a
             body may contain a NESTED `{ }` block at all: the naive scan says
             no, and no incant action in the tree uses one (indentation does
             that job), but that was not separately probed.
             ⚠ THE TELL IS THE SENTINEL, NOT THE MESSAGE.
             `ERROR processCode: <name> parse failed` names the action, never
             the line, and everything after the define is silently gone at
             exit 0.
```
**Why this is bigger than one method.** `emitMany` is the first kant conversion whose
*product* is C++ source, and C++ source is made of braces. Every remaining genParse
emitter that closes a function inherits it — `emitPlan` closes two. The trait carries
one byte per name; an emitter needing several wants several traits, or one node built
at top level where the byte is legal.

### CLAIM KANT-27 — `$` IS A STICKY GLOBAL: reset at ACTION ENTRY, and NOT restored when a nested call returns
```
statement:   `$` toggles `useDefaultSpace`, which is ONE GLOBAL -- not per
             statement and not per print. It is set true once per
             processAction, immediately before the action's BlocK runs, and is
             never restored afterwards. Two consequences, and both bite:
               (a) WITHIN a body, one `$` turns spacing off for EVERY statement
                   below it; a second `$` anywhere below turns it back ON.
               (b) ACROSS a call, whatever a callee leaves is what the caller
                   has when it resumes -- so a `$` written AFTER a call toggles
                   from the CALLEE's state, not from the default.
confidence:  RUN
provenance:  (a) Six-row fixture, one `cerr` per row, `$` on rows 1/3/5, read
             with `cat -et`:
                 A (default)  A|    four leading|<SP>     spacing ON
                 B ($)        B|    four leading|         OFF
                 C ($)        C| trailing | x|<SP>        back ON
                 D (none)     D| y|<SP>                   still ON
                 E ($)        E|z|                        OFF
                 F (none)     F|    still default?|       still OFF
             (b) incant/manyScratch, FIRST CUT: `runAll` called spellMany three
             times and THEN wrote `cerr $"MANY ANSWERS full=" full ...`. It
             printed `full= 1 bare= 0 half= 0 ` -- spacing ON -- because
             spellMany had already turned it off and the `$` toggled it back.
             The identical line moved into a fresh one-statement action `say`
             (fresh processAction -> flag true -> `$` -> off) printed
             `MANY ANSWER=1` / `=0` / `=0`. Both runs exit 0, sentinel present.
             Mechanism READ: GroupActions.rtn:456 `useDefaultSpace = true;`
             inside processAction's `if result = action["BlocK"]` arm;
             GroupActions.rtn:415 `if useDefaultSpace append(' ');` at the tail
             of printField; the toggle itself GroupActions.rtn:34.
asOf:        2026-08-01
scope:       ⚠ THIS IS WHY AN EMITTER MUST TOGGLE EXACTLY ONCE PER PATH. In
             `spellMany` each refusal arm and the success arm carries one `$`
             and each returns, so exactly one executes. A `$` on a second line
             would put a TRAILING space on every emitted line and the byte-exact
             target would move -- the space is appended AFTER a field, so the
             damage is trailing, which a diff shows and an eye does not.
             ⚠ AND IT MAKES SPACING OBSERVABLE STATE SHARED BETWEEN ACTIONS.
             No fixture in the tree asserts what the flag is on entry to a
             C++-invoked action. `spellMany` does not depend on it (its `$` is
             the first thing on every path) and nothing else should either.
             Measured on `cerr` only; one mechanism per KANT-13, but `print`
             and `string` were not re-run.
```

### CLAIM KANT-28 — a quoted literal's LEADING whitespace is STRIPPED in ANY spacing mode; interior and trailing survive
```
statement:   A quoted literal loses whatever whitespace it STARTS with. This is
             NOT a `$`-mode effect -- it happens with spacing on and with
             spacing off. Interior runs of spaces and TRAILING spaces are kept
             exactly. So emitted INDENTATION cannot be written as `"    text"`;
             it is written with `_` shortcuts, and they BUNCH:
                 cerr ____"while parseR(term,label)    kount++;":;
             gives exactly `    while parseR(term,label)    kount++;`
confidence:  RUN
provenance:  incant/manyScratch and its bisection fixtures, 2026-08-01, exit 0,
             read with `cat -et`:
                 $"[" "    while parseR(term,label)    kount++;" "]"
                     -> [ while parseR(term,label)    kount++; ]
                     FOUR leading spaces gone, FOUR interior ones kept
                 $"[" _ "   three after underscore" "]"     (spacing OFF)
                     -> [ three after underscore]
                     three leading gone; the one space is the `_`, not them
                 $"[    leading spaces first]"  -> [    leading spaces first]
                     the same characters INTERIOR to a literal: untouched
             `"if kount >= "` keeps its TRAILING space in the shipped emitter,
             and `___"return true;"` supplies the three that literal's own
             leading run would have lost -- `    if kount >= 1   return true;`
             is byte-identical to rung5.target line 7.
             Bunching READ at grammar:92, `ShortcuT=[-+~`$_:,]+` -- the trailing
             `+` is what makes `____` ONE token of four spaces.
asOf:        2026-08-01
scope:       ⚠ SUPERSEDES THE MECHANISM IN CLAIM KANT-11, NOT ITS ADVICE.
             KANT-11 read the same symptom as "`string $` no-space mode eats a
             literal's LEADING space". The MODE IS IRRELEVANT: it is eaten
             either way, and KANT-11's single observation happened to be under
             `$`. Its fix (`_` puts one back) is correct and is the fix here.
             Measured on `cerr`. Says nothing about TABS, and nothing about
             WHERE the stripping happens (QuotE parse vs a checkSkip before it)
             -- only that it is not the spacing mode.
```

### CLAIM KANT-29 — ⚠ HEADLINE OVERTURNED, MECHANISM STANDS: `||` was unregistered, but boolean OR EXISTED
> ⚠⚠ **CORRECTED 2026-08-01. THE MECHANISM THIS CLAIM IDENTIFIED IS EXACTLY RIGHT AND ITS
> HEADLINE IS WRONG.** `'|'` *is* registered bare with no `operateMethod` — measured, `incant/setup:85`
> — and `if a || b;` *did* fail the whole body. Round 2 hit a real wall and read it correctly.
>
> **But "there is NO boolean OR" is false.** `OR` — the WORD — was fully wired the whole time:
> `OR operateMethod=opOR` (`incant/setup:87`), `opOR` in `Instruct.rtn`, and `testOR` exercising it
> inside the `unitTests` baseline. Measured all three directions: `true OR false` → TRUE,
> `false OR false` → false, `false OR true` → TRUE.
>
> **So the gap was the SYMBOL SPELLING, not the operator.** Filling it was a one-line
> REGISTRATION against the existing method, not an implementation: `'||' operateMethod=opOR;`,
> spelled as a two-character entry rather than relying on `'|'` doubling because the Operators
> header states the matcher returns the LONGEST match.
>
> **THE LESSON IS ABOUT CLAIM SCOPE, and it is the claim-survival instrument working.** A wall
> was hit, the mechanism under it was read correctly, and the generalisation reached one level too
> far — from *"this spelling is unwired"* to *"the language lacks the concept."* The cheap check
> that would have caught it is the one the corpus already prescribes for absence claims: **grep the
> tree for a working counterexample before claiming a limitation.** `testOR` was in the baseline.
> Original claim retained verbatim below; nothing in its evidence was wrong.

### CLAIM KANT-29 — there is NO boolean OR: `'|'` is registered with no operateMethod, and `if a || b;` fails the WHOLE body
```
statement:   `||` is not a kant operator. incant/setup:85 registers `'|';` with
             NO operateMethod (contrast `'+' operateMethod=opPlus`), so
             `if !site || !min;` does not parse and takes the entire action body
             down with it. A two-clause refusal guard is written as two separate
             `if`s, each with its own arm.
confidence:  RUN
provenance:  Bisection fixture, 2026-08-01, every row exit 0:
                 if !site || !min;        -> ERROR processCode: probe parse failed
                     cerr $"refuse":;
                 if !site;                -> OK; refuses only the node lacking it
                     cerr $"refuse":;
             and the shipped two-guard form in incant/genMany, RUN over three
             nodes: site+min -> "1", neither -> "0", site only -> "0".
             Registration READ at incant/setup:85 (`'|';`) and :135 (`'&';`),
             both bare.
asOf:        2026-08-01
scope:       Covers `||` in an `if` condition inside a code body. Says NOTHING
             about `&&`: `'&'` is registered the same bare way and is therefore
             suspect, but it was NOT probed -- do not read this as covering it.
             Says nothing about single `|` anywhere.
             ⚠ NOTE WHAT THE TWO-GUARD FORM COSTS: the C++ prints ONE
             diagnostic for either missing attribute, so the kant version
             repeats that line in both arms to keep the text identical. Two
             arms, one message -- do not "tidy" it into one arm with a
             different message.
```

### CLAIM KANT-30 — an `if` and its governed statement MUST NOT SHARE A LINE
```
statement:   `if <cond>    <statement>;` on ONE line does not parse and fails
             the whole action body. The condition ends the line (with or without
             a `;`) and the governed statement is INDENTED on the next. This is
             the form every working action in the tree uses.
confidence:  RUN
provenance:  Bisection fixture, 2026-08-01, exit 0 on every row -- the failures
             visible ONLY as `ERROR processCode: probe parse failed`:
                 if !site    cerr $"no site":;                  -> FAIL
                 if !site    cerr $"no site":;                  -> FAIL
                 else        cerr $"got site":;
                 if !site;                                      -> OK
                     cerr $"no site":;
             Corroborating shipped code: incant/genEmit's spellLeaf is
             `if kind == "OPT";` with an indented arm; incant/genMany's two
             guards are the same shape.
asOf:        2026-08-01
scope:       ⚠ RELATED TO CLAIM KANT-24 (closing `}`) AND NOT THE SAME RULE.
             KANT-24 is about where a CLOSING `};` sits relative to a nested
             block; this is about where the GOVERNED STATEMENT sits relative to
             its `if`. Both are checkSkip indentation effects, both fail as "the
             action did not run", and the SENTINEL is the discriminator for
             each.
             Probed for `if` and `if/else`. Says nothing about `while`, `for` or
             `iterate`, none of which this round exercised.
```

### CLAIM KANT-31 — `if !x` DOES distinguish an ABSENT attribute from a present one after a `:scope` hoist
```
statement:   `:node a b;` creates a local per name whether or not the attribute
             exists, and an absent one PRINTS as its own tag (KANT-10). But the
             two states ARE distinguishable by TRUTH: `if !a` fires when the
             attribute was absent and does not fire when it was present. A
             refusal guard on a missing attribute is written the obvious way and
             works.
confidence:  RUN
provenance:  incant/manyScratch, exit 0, sentinel present, 2026-08-01. Three
             MANY nodes through the same `:argument site min;` hoist:
                 site + min   -> emitted the helper, answer "1"
                 neither      -> "emitMany: MANY node has no site/min", "0"
                 site only    -> "emitMany: MANY node has no site/min", "0"
             The `half` row is the one with teeth: `!site` must be FALSE and
             `!min` TRUE in the SAME call, so a guard that merely detected
             "something is missing" could not produce it.
             Mechanism READ at ruleActions.rtn, aCTionScopeXP: the local is
             minted either way and on a miss is `grup.clear()`-ed, so the NODE
             is real and the DATA is what differs.
asOf:        2026-08-01
scope:       ⚠ CLOSES THE OPEN QUESTION IN CLAIM KANT-10's SCOPE, which said
             "Not established whether `if slot` distinguishes the two states --
             it was not needed and was not tested, so do not assume it does."
             It does. KANT-10's own statement -- that the two are
             indistinguishable in PRINTED OUTPUT -- is untouched and still true;
             only the truth test is now known.
             Measured on attributes hoisted by `:scope` onto a freshly minted
             node. Says nothing about a local that was assigned and then
             cleared, nor about `if x` where x holds a numeric 0.
```

### CLAIM KANT-32 — a kant refusal crosses the seam as a TWO-VALUED TEXT answer, because `getText()` falls back to the TAG
```
statement:   An unset node is NOT textually empty across the seam:
             GroupItem::getText() ends `or tag junkText = tag;`, so a node
             carrying no data answers with its own TAG. That is why every
             KANT-B1 attempt came back as plausible text rather than as nothing,
             and it means "returned nothing" can NEVER be told from "returned a
             name". The workable refusal is therefore an EXPLICIT two-valued
             answer the action assigns on both paths -- text "1" for yes, "0"
             for no -- which a C++ caller tests with `result.text eq "1"`.
confidence:  RUN as to the kant half; REASONED as to the C++ half. Split
             DELIBERATELY: the values coming out of `runAction` were measured;
             the fork that would consume them DOES NOT EXIST YET and was not
             run.
provenance:  incant/manyScratch, exit 0: `MANY ANSWER=1` / `=0` / `=0` for
             site+min / neither / site-only, read back through an ordinary
             incant call (`full = caseFull();` -> `return spellMany(many);`).
             getText's fallback READ at GroupItem.twk:676 (`or tag junkText =
             tag;`). Corroborates KANT-B1's five attempts from the other end:
             `return;` -> "return", `return null;` -> "0",
             `return <unset local>;` -> the local's tag. None is absence; all
             are text.
asOf:        2026-08-01
scope:       ⚠ `return null;` YIELDS TEXT "0", WHICH COLLIDES WITH THIS IDIOM,
             and it is named here on purpose. A future refusal spelled
             `return null;` produces the same "0" this claim uses for a
             deliberate NO. Harmless while "0" means refuse; a trap the day
             someone wants "0" to be a real value. If the language ever
             standardises one false sentinel (OPEN KANT-20) this idiom should
             move to it.
             ⚠ AND IT DOES NOT COVER A BROKEN ACTION. When `spellMany`'s body
             failed to parse, the caller's `got = spellMany(x)` came back as the
             CALLER's own local tag (`RESULT=[got]`) -- indistinguishable from a
             refusal. A C++ fork cannot tell a refusing kant action from a
             syntactically dead one, which is a second reason the seam needs a
             MANIER pin (round 1's `SPELLER kant` shape) and not just a value
             test.
```

---

### CLAIM KANT-34 — `||` EVALUATES BOTH ARMS. No short-circuit, and it is pinned as chosen
```
statement:   `a || b` evaluates BOTH operands. A side effect on the right arm
             fires even when the left arm is already true. Same for `&&`.
confidence:  RUN
provenance:  incant/orProbe row 3 -- `if oTrue || loudZero();` where loudZero
             prints and returns 0. Output:
                 [RIGHT ARM EVALUATED]
                 true || loudZero() -> TRUE
asOf:        2026-08-01
scope:       ⚠ STRUCTURAL, NOT AN OVERSIGHT. An operateMethod receives operands
             the runtime has ALREADY evaluated, so there is no point at which
             opOR could decline to evaluate the right arm -- short-circuit is
             not something the current operator machinery can express. opAND has
             the identical shape and the identical behaviour, so the two agree.
             Tony ruled in advance that evaluate-both is acceptable for a truth
             test provided it is stated: it is stated here. Do not write `||`
             expecting a guard against an expensive or unsafe right arm.

⚠ DATED RETIREMENT NOTE, 2026-08-11 -- PARTIAL. The AND/OR rung landed
  (docs/andOrRung.md). This claim SPLITS, and it is not rewritten, because it
  records what was true and why:

    THE STATEMENT STILL HOLDS FOR THE SYMBOL FORMS. `a || b` still evaluates
    both arms -- re-measured the same day, orProbe row 3 still prints
    [RIGHT ARM EVALUATED]. `&&` is worse and separately filed (KE, `'&'` is
    registered bare with no operateMethod).

    THE MECHANISM CLAIM IS RETIRED. "There is no point at which opOR could
    decline to evaluate the right arm -- short-circuit is not something the
    current operator machinery can express" was TRUE OF THE OPERATOR
    MACHINERY and is no longer the whole story: AND/OR were PROMOTED OUT of
    that machinery (tier 3). interpretXP now binds runShortCircuit at tree
    build, which sees its operands UNRESOLVED, so declining is expressible --
    it just is not expressible AT AN operateMethod, which is what the claim
    actually established. Measured: `false AND loudOne()` no longer prints
    the marker; ladder rung JXD-3 certifies it by tick count.

    SO THE WORD AND SYMBOL FORMS NOW DIVERGE, and that divergence is FILED
    AND UNRULED rather than intended -- `OR` short-circuits, `||` does not,
    on one shared handler. Widening tier 3 to the symbols is a ruling.
```

### CLAIM KANT-35 — ⚠ `!a || !b` IS NOT EQUIVALENT TO SEQUENTIAL `!a` / `!b` GUARDS on ABSENT attributes
```
statement:   A disjunction of negations DOES NOT catch an absent attribute that
             sequential negation guards DO catch. `if !a || !b;` sees "both
             present" where `if !a; or !b;` correctly fires.
confidence:  RUN, and reduced to a minimal case
provenance:  incant/orProbe row 4, two nodes through one action after a :scope
             hoist --
               hasBoth (both present):  seq "neither -- both present"
                                        ||  "disjunction saw BOTH PRESENT"   agree
               hasOnly (beta1 ABSENT):  seq "!beta1 caught it"
                                        ||  "disjunction saw BOTH PRESENT"   DISAGREE
             Found the expensive way first: collapsing spellMany's twin guards
             into `if !site || !min;` let a site-but-no-min node EMIT instead of
             refusing, moving manyScratch.target by ten lines. Reverted.
asOf:        2026-08-01
scope:       Consistent with KANT-34's mechanism -- opOR receives ALREADY
             EVALUATED operands and tests gCount, and an absent attribute's
             negation does not arrive as a gCount opOR reads as true. So this is
             not a second defect; it is KANT-34's consequence at the one place
             it bites hardest.
             ⚠ CONSEQUENCE FOR CONVERSIONS: a multi-attribute presence check
             MUST stay as sequential guards. It reads more verbose and it is not
             a style choice -- the tidy form is wrong. incant/genMany carries
             this warning at the site so the guards are not "cleaned up" later.
             DOES NOT COVER: `a || b` on plain truth values, which is sound in
             all three directions (KANT-29's correction).

⚠⚠ DATED NOTE, 2026-08-11 -- THIS CLAIM IS REPAIRED, and it was repaired as a
  SIDE EFFECT of the AND/OR rung rather than by anyone aiming at it. Kept, not
  deleted: the claim records a real defect, a real cost, and a reverted change.

    MEASURED, same fixture, same row, before and after the rung:
        hasOnly (beta1 ABSENT)   before:  ||  "disjunction saw BOTH PRESENT"
                                 after :  ||  "disjunction caught it"
    The sequential guard was always right; the disjunction now agrees with it.

    CAUSE, and it is NOT the mechanism this claim's scope paragraph names.
    KANT-35 attributed the failure to KANT-34 -- "opOR receives ALREADY
    EVALUATED operands and tests gCount, and an absent attribute's negation
    does not arrive as a gCount opOR reads as true." The real cause was that
    opOR's STRUCTURE was inverted: it only consulted `argument` when `target`
    was ALREADY truthy, so a false left arm returned falseResult WITHOUT EVER
    LOOKING AT THE RIGHT ARM. Nothing to do with evaluation order. Routing
    both arms through the one truthOf contract fixed it.

    ⚠ SO A CORRECT CLAIM CARRIED A WRONG MECHANISM FOR TEN DAYS, and the
    mechanism was the plausible one -- it named a real property of the system
    (KANT-34 is genuine) that simply was not what was biting here. Structural
    claims hold, causal claims fail: this is another entry on that ledger,
    and it survived because the SYMPTOM kept reproducing.

    ⚠ CONSEQUENCE STILL OWED, NOT TAKEN THIS RUNG: the "multi-attribute
    presence checks MUST stay as sequential guards" instruction, and the
    warning `incant/genMany` carries at the site, are now believed obsolete
    -- but "believed" is not "measured". Re-running spellMany's collapsed
    form against manyScratch.target is the check, and it is a rung of its
    own. DO NOT tidy the guards on the strength of this note alone.
```
**Why this is filed the hour `||` landed.** `||` was filled *because* round 2's twin guards were
the demand specimen. The first thing done with it was to collapse those guards — and that was
wrong. **The feature was correct, the first use of it was not**, and the fixture caught it
immediately because `manyScratch.target` pins the refusal arm. That target existed for less than
a day and has already paid for itself.

---

### CLAIM KANT-40 — KANT-26 EXTENDS TO COMMENTS: a close-brace in a `/* */` inside an action body ends the capture
```
statement:   aCTionCodE scans for the first close-brace with NO quote awareness
             (KANT-26) and NO COMMENT AWARENESS EITHER. A close-brace character
             written inside a /* */ comment in an action body ends the CodE
             capture at that point. The action vanishes, the file emits nothing
             from there on, and the run still exits 0.
confidence:  RUN, and the provenance is embarrassing enough to be memorable
provenance:  2026-08-01. The foreman wrote a comment in incant/genMany EXPLAINING
             that a close-brace ends the CodE capture early. The comment
             contained the character. It ended the CodE capture early. The whole
             spellMany action vanished, incant/manyScratch emitted ZERO lines,
             and genLadder/pop.sh went to `FAIL rung5.target / POP FAILED --
             21 green`. Removing the character from the prose -- changing
             nothing else -- restored manyScratch.target to BYTE-IDENTICAL and
             pop.sh to PASSED.
asOf:        2026-08-01
scope:       Extends CLAIM KANT-26 from quoted strings to comments; the
             mechanism is identical and is stated there. The practical rule is
             stronger than "escape it": DO NOT WRITE THAT CHARACTER INSIDE AN
             ACTION BODY IN ANY FORM, INCLUDING WHILE DESCRIBING IT. Refer to it
             in words.
             ⚠ THE SYMPTOM IS KANT-33's, NOT A BRACE ERROR'S: exit 0, no
             diagnostic naming braces, and the file simply produces less than it
             should. The discriminator is the same -- absent sentinel, or in this
             case a fixture that emitted nothing at all.
```

## BLOCKED

### CLAIM KANT-41 — TWO DOORS into an action body, and only one has a bracket or a seam
```
statement:   There are exactly two entry paths into an action body.
             DOOR ONE -- `actionType` calls through `runAction`, which carries the
             local-save bracket and the return seam.
             DOOR TWO -- coded RULES: `ruleActions.rtn:352` binds `processAction`
             DIRECT, and `runRule` goes to `rule.parse(0)`. No bracket, no seam,
             by construction.
             RULED 2026-08-10: door two is the ARCHITECTURAL DESTINATION, not an
             unexamined gap. Rule actions are frameless BY DESIGN; their safety
             property is the recursive-descent calling convention itself --
             uniform 1/0 return, `atRuleMark` restored on failure -- and not a
             runtime frame. The bracket and the seam are door one's machinery,
             appropriate to the arbitrary-action population, which needs a frame
             precisely because it carries no contract.
confidence:  RUN
provenance:  Ruled Tony 2026-08-10 in Clay chat; CERTIFIED the same day by the
             SEQ 27 crossing census -- 1706 dispatches, door one 523/523 action/
             0 RULE, door two 1183/0/1183, name sets disjoint (211 vs 12). The 0
             is a POSITIVE named-set result, not an absence claim: door two is
             not merely failing to cross the seam, it is carrying the ENTIRE rule
             population elsewhere. Corroborated structurally by a static
             enumeration of all four `runAction` call sites
             (`GroupActions.rtn:895`, `Commands.rtn:191`, `genParse.rtn:847`,
             `:964`) and by `runOP` testing `or isRule` BEFORE `or actionType`,
             so a rule cannot reach the seam by construction.
             ⚠ THE CENSUS CERTIFIES THE RULING RATHER THAN MERELY SCOPING THE
             RUNG -- the ruling stands on measurement, not on authority alone.
asOf:        2026-08-10, commit 168453d
scope:       CONSEQUENCE 1: door one is the LEGACY door. The 2026-08-10 seam +
             bracket campaign completes its CORRECTNESS and is maintenance of the
             existing population, not investment in the destination path.
             Proposals to EXTEND door one's machinery should cite this ruling
             before proceeding.
             CONSEQUENCE 2: the calling convention is promoted from interface
             DISCIPLINE to load-bearing SAFETY. A generated parse method that
             violates the 1/0 / atRuleMark contract is a SAFETY defect, not a
             style defect. The vigram is the designated place where contract
             conformance becomes checkable rather than trusted.
```
⚠ **THE CONVERGENCE QUESTION INVERTS, AND IT IS PARKED.** Not *"does door two need a bracket"* but,
**post-self-hosting, *"does door one still need to exist"***. **Nobody's task** — recorded here so
the inversion is not rediscovered rather than because anyone is expected to act on it.

**Why this sits in the corpus rather than only in `CLAIM KANT-8`:** KANT-8's head carries the two
doors as the *territory* of that defect. This entry carries them as an **architectural ruling** with
its own provenance, because the ruling outlives the defect — and a future round asking *"why is the
rule population frameless"* needs the answer to be **a ruling it can act on**, not a scoping note
inside a repaired claim.

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

> ⚠ **ROUND 2 RAN THE ROUTE THIS ENTRY NAMED, AND IT DID NOT WORK.** See
> `BLOCKED KANT-B3` below. The refusal that DOES work is a two-valued text answer —
> `CLAIM KANT-32`. The paragraph above is left standing because it is what was believed
> when it was written; the correction sits beside it rather than replacing it.

> ### ⚠ CORROBORATED FROM THE OPPOSITE END, 2026-08-10 (SEQ 27's clause-3 census, commit `168453d`)
> **This entry and the seam campaign measured the same fact from two directions, and neither knew
> about the other until the corpus was read.** B1 tried four ways to **produce** a null from a kant
> body and could not. The SEQ 27 census instrumented `runAction`'s post-`processAction` return and
> swept the whole structural fixture population: **that null occurred 0 times in 128 files.**
>
> **So B1 is the MECHANISM behind that zero**, and the zero is independent evidence for B1. Neither
> is a bare count any more: *"nobody happens to return null"* and *"kant cannot express one"* were
> two readings of the same measurement, and B1 settles which.
>
> ⚠ **WHAT THE SEAM REPAIR DID AND DID NOT CHANGE HERE.** Rung A's value-capture preserves null as
> null (clause 3) — so **if** a body ever produced one, the seam would now hand it back intact. **B1
> therefore stands unchanged, and its blocker is located: it is UPSTREAM of the return seam**, in
> body evaluation, not at the hand-back. A future round should stop probing the return and probe
> `processAction`'s `BlocK` result instead.
>
> **Consequence for the seam's own guard, recorded honestly:** `runAction`'s null guard is correct
> and prevents a dereference, but is **uncontrolled by any fixture and cannot be controlled until B1
> is solved** — there is no reachable case to build a negative control from. `incant/kant8N` says
> so in its own header rather than carrying an invented green.
>
> *(Cross-link added by Clod, SEQ 30, on reading this entry while filing `CLAIM KANT-41` — the two
> findings were made a week apart by different rounds and would otherwise each have been re-derived.
> Neither entry's original text is altered.)*

### BLOCKED KANT-B3 — `:.` (opSetFlag) sets NO flag from a code body; every groupField tried fell to `not supported yet`
```
wanted:      KANT-B1's own named next move: return the ARGUMENT with a boolean
             stamped on it via `:.`, and have the C++ side test the flag instead
             of the pointer. This is the refusal signal `emitMany` needs, since
             its C++ contract is an int and emitPlan tests it.
source:      genParse.rtn:671-673
                 if !site || !low {
                     cerr "emitMany: MANY node has no site/min":;
                     return 0; }
             consumed at genParse.rtn:876 (`if !emitMany(node) { ... return null; }`).
attempts:    Three groupFields, one fixture, exit 0 on every run
             (2026-08-01, incant scratch, a freshly minted node `full`):
                 full :. isPercenT;   -> opSetFlag: setting full not supported yet
                 full :. noPrinT;     -> opSetFlag: setting full not supported yet
                 full :. flaG;        -> opSetFlag: setting full not supported yet
             and the read-back after each was unchanged:
                 full.flaG      -> flaG            (unset, printed as its tag)
                 full.noPrinT   -> noPrinT         (unset)
                 full.isPercenT -> access to isPercenT not supported yet
             The message comes from opSetFlag's `default:` arm
             (Instruct.rtn:1026), so `argument.gCount` was NOT 12/21/29 --
             i.e. the operand did not arrive as the GroupFields entry. The
             SAME names resolve correctly through `.` in the same fixture:
             `full.taG` -> full, `full.datA` -> 13, `full.isLocaL` -> 1,
             `full.firstMembeR` -> 0. So the entries are reachable and carry
             their gCount; something about the `:.` operand binding is
             different, and I did not isolate it.
category:    IDIOM-GAP
```
**Grepped before filing, per the brief, and the grep is why this is IDIOM-GAP.**
`:.` has exactly **eight** executable call sites in the tree, **all in
`incant/utilities`** (lines 355, 362, 365, 376, 383, 401, 407, 410 — `isPercenT` and
`mergeON`; a ninth mention at :315 is prose). Plus its registration at
`incant/setup:121` and its implementation at `Instruct.rtn:1014`.
Searched: `grep -rn ":\." incant/ *.rtn *.twk`. **So a working counterexample may
exist and I could not run it** — those sites are in layout code that no fixture in
`genLadder/pop.sh` reaches, so "utilities uses it" is not evidence that it works
today. Whoever picks this up should drive one of those eight lines first: if they
work, the difference between them and my probe *is* the idiom, and it is cheaper to
find that way than by reading `opSetFlag`.

**What round 2 did instead:** `CLAIM KANT-32` — an explicit two-valued TEXT answer.
It needed no new mechanism, it is measured, and it survives `getText()`'s tag
fallback, which is the thing that defeats every "return nothing" spelling.

---

## RELATED, AND NOT PART OF THIS CORPUS

- **`CLAUDE.md` bear traps** — tok and build hazards. Best-evidenced claims in the tree;
  they carry real error output. Input, not corpus.
- **`docs/tokClaims.md`** — the B0 tok-claim sweep, in this same format. Input, not corpus.
  Note **CLAIM TOK-1**: a recorded limitation was disproved by shipping code three
  functions away that nobody had looked at. That is the failure mode this corpus is
  built to avoid.
