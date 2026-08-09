# Step 1 artifact — the parse-method template family, and `Attributes` v0

**Status:** ⚠ **HOLES FILLED BY MEASUREMENT, 2026-08-09. NOT FROZEN — two answers change the
draft's shape and one of them wants Tony before First Light.** Nothing is installed. Step 2
(standalone Scaf-style run, tree-compare vs native) is next and separate.

**Provenance:** dispatched by Clay via Tony, 2026-08-09 (§1–§5 of the dispatch). Filled by Clod
the same day. **Corrections land as the decoder discipline: where draft and tree disagree, the
tree wins and the divergence is NOTED, not silently fixed.**

---

## 0. THE SHORT VERSION, because two holes move the work

| hole | answer | effect on the draft |
|---|---|---|
| **H4** *(leads)* | **YES for rules, NO for `lit`** | proceed — but §2's ALTERNATION *"no save, no restore anywhere"* is **wrong for any chain containing a literal alternative**, and the tree already knows it |
| **H2** | **`Attributes=TraiT+;`** | Clay's guess was **right**. ITERATE, one-or-more. §3 stands |
| **H1** | **NO — `Attributes` is not among the 16 plannable** | it *refuses*. The draft's premise inverts |
| **H3** | `atRuleMark` is the **real** spelling — and is **unreachable from incant** | ⚠ **the template's primitives do not exist on the kant side yet.** This is the real blocker |
| **H5** | **no helper** — bare `return 0;` | and after ⚠ D1 below there is nothing for a helper to do |
| **H6** | **`while`**, certified at ladder J3. ⚠ **never `for`** | the iterator is a named JIT-0.1 exclusion |

⚠ **AND THE ONE THAT OUTRANKS THE REST — §2's mark save/restore is a SECOND WRITER.**
`leaveRule` already owns Invariant R by explicit design, and the tree carries a scar from the last
time something else wrote there. See ⚠ D1.

---

## 1. THE CONTRACT

> A rule parse method returns `sukcess` (1) or failure (0). On failure it has consumed nothing —
> the mark exactly as at entry. On success the mark sits after what it matched. Children are held
> to the same contract, whichever arm they parse on.

**Ratified in discussion, wants Tony's formal nod, then a decoder entry.** ⚠ **One word needs
Tony's eye before that nod: "exactly".** H4 measures the native arm restoring to `hereAt`, which
is the entry position **after** the leading skip run, while the generated arm restores to `from`,
captured **before** it. Both give back everything they *matched*; they differ by whitespace. If
"exactly as at entry" is meant literally, the two arms do not satisfy it identically — and the
seam is precisely where that would be noticed.

## 2. THE TEMPLATE FAMILY — respelled in the certified spelling

⚠ **The SEQUENCE template is not a proposal — it is ladder rung JXT, green, jitted, degrade 0.**
`incant/jitXtemplate` is titled *"THE PROPOSED genKantParse SEQUENCE TEMPLATE, JITTED"* and its
constructs are individually certified: comparison (J2/J3), single-statement `if` (jitEmitGIF, both
arms), mid-block return (JRt), and a value-returning callee consumed sequentially (jitXseq).
**Its degrade count went to 0 today when E2 landed** — before that it was pinned at 2 for the
tail-return fallback. So the template's certification is one day old.

### SEQUENCE — terms T1..Tn, all must match

```
    xtRule code={
        xtSuk = xtT1();
        if xtSuk == 0;
            return 0;
        xtSuk = xtT2();
        if xtSuk == 0;
            return 0;
        return 1;
        };
```

**Note the spelling, which is load-bearing and differs from the draft in three places:** the
governed statement sits on its **own line, indented** (a same-line `if` is bear-trap #4's
neighbourhood); the failure exit is a **bare `return 0;`**, not a helper; and **there is no mark
save and no restore** — see ⚠ D1.

**It short-circuits by construction rather than by an operator that would have to decline to
evaluate**, and that is the whole reason it exists: the draft's `AND` spelling is measured
unavailable in *either* engine — `a AND b` exits 139 with no degrade line, `a OR b` exits 0 and is
**silently wrong** (`incant/jitXand2`, `incant/jitXor`; CLAIM KANT-34).

### ALTERNATION — members A1..An, first match wins

```
    xtSuk = xtA1();
    if xtSuk == 1;
        return 1;
    xtSuk = xtA2();
    if xtSuk == 1;
        return 1;
    return 0;
```

⚠ **THE DRAFT'S JUSTIFICATION IS FALSE FOR LITERAL ALTERNATIVES, AND THE TREE SAYS SO IN ITS OWN
COMMENT.** The draft argues *"no save, no restore anywhere — the contract's self-restore makes the
bare chain correct."* That holds when every alternative is a **rule**. It does not hold when one
is a **literal**, because `lit` commits its skip pass before matching and returns false with the
mark advanced (§H4). `leaveAlt` keeps `from` for exactly this reason and says so:

> *S4.2 (knowingly conservative): `from` is kept because `lit` commits its skip pass to
> atRuleMark BEFORE matching, so a failing lit returns false with the mark advanced. Until that
> is made non-destructive, leaveAlt cannot drop to (rule, ok).*

**Consequence: the bare chain is safe for `Attributes` (all-reference) and is not a general
template.** An alternation with any literal option needs either the `from` save or a
non-destructive `lit`. **Tony's call which**, and it is the same fork the seat-note anticipated,
arriving one level lower than expected — at a primitive rather than at the seam.

### ITERATE — repeated reference R

```
  zero-or-more (R*)                    one-or-more (R+)   <- Attributes wants this
    xtSuk = 1;                           xtSuk = xtR();
    while xtSuk == 1;                    if xtSuk == 0;
        xtSuk = xtR();                       return 0;
    return 1;                            while xtSuk == 1;
                                             xtSuk = xtR();
                                         return 1;
```

**H6: the loop is `while`** — certified at ladder J3 (`while jcIn > 0;`, right iteration count,
fire 2 with no recompile, degrade 0). ⚠ **NOT `for`.** A jitted action containing an iterator walk
**visits 0 leaves where the interpreter visits 2** — pinned at `incant/jitJUi`, a named JIT-0.1
exclusion, measured pre-existing and waiting on Tony's iterT3/trunk-arity ruling. A parse template
built on `for` would inherit an open divergence for nothing; `while` over a success flag needs no
tree walk.

⚠ **THIS SPELLING IS NOT CERTIFIED. There is no ITERATE rung.** JXT certifies SEQUENCE only. Per
H7 the honest statement is: *built from individually-certified constructs, composition unrun.*
**The next rung writes itself** — `xtR()` returning 1,1,0 across three calls, ticks asserted at 3,
fire 2 re-fired with a different trip count so a folded constant cannot pass. That is step 2's
business, not this artifact's.

## 3. `Attributes` v0 — the instantiation

**H2, measured, `incant/grammar:57`:**

```
    Attributes=TraiT+;
```

**Clay's read was right on every count** — Family A, `isGROUP`, references `TraiT`, body is a
simple iterated reference, and the multiplicity is `+`, one-or-more. No leading or trailing
literals, no mixed terms, so **no SEQUENCE wrapper is needed**: v0 is the bare ITERATE.

For context, the neighbourhood it sits in (`incant/grammar:55-59`):

```
    TraiTdata           '='- DatA Modifier* Limit?;
    TraiT               NamE Modifier* Limit? TraiTdata?;
    Attributes=TraiT+;
    NewGroup            TraiT@;
    DefinE              NewGroup Attributes? MemberS endDefine-=[;>];
```

**v0:**

```
    parseAttributes code={
        atSuk = <invoke TraiT parse>;
        if atSuk == 0;
            return 0;
        while atSuk == 1;
            atSuk = <invoke TraiT parse>;
        return 1;
        };
```

⚠ **`<invoke TraiT parse>` STAYS UNSPELLED, AND NOT FOR THE REASON THE DRAFT GAVE.** The draft
called it "H3's mechanism question wearing its true face." Measured, it is worse than a spelling
question and better than a design one: **the mechanism exists and is named, but it is not
reachable from kant.** See §4 H3.

⚠ **AND `Attributes` LANDS ON A PRE-RECORDED OPEN.** `parseR`'s own header carries it:

> *parseMethod lives on rStuff, and rStuff is PER NODE: the term has its own, separate from the
> registry rule's. So binding a rule's parseMethod does NOT reach the term nodes that reference
> it… Mixed mode needs an answer to that before **rung 4, which is the first cross-method call**.
> It does not bite rungs 1-2: Scaf/Scaf2 have no rule-reference terms.*

`Attributes = TraiT+` is **nothing but a rule-reference term**. So the chosen v0 subject is
exactly the case that open question was fenced against. **This is not an objection to the choice**
— it is arguably the right subject *because* it forces the question — but it should be chosen
knowingly rather than discovered at step 2.

## 4. THE HOLES — measured answers, with citations

### H4 — native failure discipline *(leads the list)*

**ANSWER: YES for rules. NO for `lit`. And the two rule arms restore to different points.**

| what fails | restores? | to where | citation |
|---|---|---|---|
| a **native** rule parse | **YES** | `hereAt` — entry position **after** the leading skip | `GroupItem.twk:1267` `atRuleMark = hereAt;` in the `matchFailed`/`debugHere` block; `hereAt` is set at `RuleStuff.twk:167`, inside `checkInput` and after the skip pass |
| a **generated** rule method | **YES, unconditionally** | `from` — captured **before** the skip | `RuleStuff.twk` `leaveRule`: `atRuleMark = from;` on the not-`ok` path. Its own comment: *"the rewind is unconditional, so R cannot be violated here"* |
| an alternation exit | **YES** | `from` | `leaveAlt`, same shape |
| **`lit`** (a literal term) | ❌ **NO** | — | `RuleStuff.twk:525-532`: `if skipSet.contains(*atRuleMark) atRuleMark = checkSkip(atRuleMark);` **commits**, then the match loop runs on a local `atText` and `return false` leaves the committed mark |

**So the dispatch's YES branch applies: the contract is a transcription of existing discipline at
RULE granularity, the seam has the same rule both sides, proceed.** The `lit` exception is at
TERM granularity, is already known and already compensated (`leaveAlt` keeps `from`), and does not
touch `Attributes`, which has no literal terms.

⚠ **GRADE: READ, NOT RUN.** The dispatch said *measure, don't infer*, and this is a source read of
four call sites — mechanical, cited, and still a read. **A run-grade confirmation is owed and is
cheap two ways:** `parseTrace` already prints `R OK mark unmoved` / `R OK mark rewound` on the
generated arm's failure path, so that half needs only a fixture that fails; the **native** half
has no such print and needs either a `groupDirectives` probe around `GroupItem.twk:1267` (one
instrumented build — ⚠ and per bear-trap #23's cross-annotation that binary must **not** measure a
POP or be committed) or a behavioural probe: an alternation whose first option fails **after
consuming**, asserting the second option matches from the right place. **Recommended before the
contract is signed**, because a signature converts a read into doctrine.

### H3 — the invocation-and-mark mechanism

**(a) Invocation — the mechanism exists and is named.** `parseR(term, into)`
(`RuleStuff.twk:758`) builds a bridge `RuleStuff`, sets `bridge.label = into`, and calls
`term.parse(bridge)`. It routes **through `parse()`, not at a generated method**, which is what
makes mixed mode free and conversion order-independent. It returns a **GroupItem or null**, not an
int — so in a `&&` chain null reads as failure, but a template written as `xtSuk == 0` needs to
know it is testing a node, not a boolean.

**(b) The mark — `atRuleMark` is the REAL spelling.** `GroupRules.h:13`, `char *atRuleMark`.
**Tony's working name is the actual name; nothing gets respelled and no parallel mechanism is
minted.**

⚠ **(c) AND THE HOLE THE DRAFT DID NOT KNOW IT HAD: NONE OF IT IS REACHABLE FROM INCANT.**
The templates in §2 are **kant** — `code={ }` bodies, jitted. Every primitive they need lives in
the C++ support library and **is not registered as an incant command**:

```
  atRuleMark   read or write   -- NO command.  Occurs in the tree only as GroupRules.h:13
                                  and inside genParse.rtn, which EMITS it as C++ TEXT
  checkSkip                    -- NO command
  parseR / lit / leaveRule /
  leaveAlt / containerTo       -- NO command
```

*Search space named:* all 62 `immediateAction` registrations in `incant/setup`; a tree-wide grep
for `atRuleMark` across `*.rtn`/`*.twk`/`*.h`; and `checkSkip`/`parseR`/`lit`/`leaveRule` against
`incant/setup`.

⚠ **`setMark` IS A FALSE FRIEND AND WOULD BE EASY TO MISTAKE FOR THE ANSWER.** It is registered
(`incant/setup:76`) and it is the **Buffer** mark — `Instruct.rtn:1069`, taking `source` and
`markOffset` attributes and moving `buffer.mark`. It has nothing to do with `atRuleMark`. Binding
a parse template to it would mint exactly the parallel mechanism H3 forbids, and it would
half-work.

**This is Tony's own note arriving as a measurement.** `IncantForms/WorkingOn/incant++` already
says, in the genKantParse sketch: *"`checkSkip();` // need a command to enable that."* Measured,
the list is longer than `checkSkip` — but it is a **registration** job, not a language one, and it
is bounded at roughly three to four commands. **Which is the good news in this artifact:** the
gap between the template family and a runnable `Attributes` is a known, small, mechanical piece of
wiring, not a design question.

### H1 — is `Attributes` among the 16 plannable?

**NO. It refuses.** Measured from `incant/phaseA`'s printed scalars (not the staging doc — T-0
lives there), exit 0, `TALLY refusals = 94`, `TALLY plannable = 16`:

```
    PLAN Attributes
      REFUSE rule Attributes -- rule-level data isGROUP (§4.1 rule-as-data, rung 5)
    DONE Attributes
```

The 16 plannable are: `BlocK Braced CodE ElsE ExpressioN GrouP InvokE InvokeArg
loopOnAttributes loopOnMembers Parens PrintField RunRulE SemI TokenXP WardeD`.

**So the artifact is a template for a rule the planner cannot yet plan** — which is coherent
(this is a *hand-write*, and Gap B rung 2 is what would make it plannable) but it inverts the
draft's framing, and it means the step-4 byte-oracle cannot be produced by the planner until
Family A lands.

⚠ **AND A NUMBERING DIVERGENCE FOR TONY, noted not resolved:** the refusal names **rung 5**
(`§4.1 rule-as-data, rung 5`), while the family table in the 08-09 seal has Family A (REFERENCE)
as the **rung 2** candidate. Two different rung numberings are in circulation for the same work.
Cheap to reconcile now, expensive as a citation later — which is T-0's whole lesson.

### H5 — helper vs block-if

**Block-if with a bare `return 0;`.** That is what the certified rung uses, and after ⚠ D1 the
helper has no work left to do. A helper would also be a value-returning callee whose *purpose* is
a side effect, which is a shape no rung certifies.

### H6 — the certified loop

**`while`** (ladder J3). Not `do` (certified at J4, but body-first is wrong for `R*`). ⚠ **Not
`for`** — see §2.

## 5. ⚠ DIVERGENCES FROM THE DRAFT — the asymmetry ledger's rows

**D1 — §2's mark save/restore is a SECOND WRITER, and the tree has a scar from the last one.**
The draft's SEQUENCE opens `xtMark = atRuleMark;` and fails through `xtFail()`, which restores.
But `leaveRule` **already** restores, unconditionally, by explicit design — genParse S1.8 put
Invariant R there rather than in emitted lines precisely so there would be **one implementation
for every rule**, and `leaveRule`'s PC-4 comment records what happened when something else also
wrote in that neighbourhood: *"A second writer here is what produced GM-17's divergence."*
**Recommendation: drop the save and the restore from the template.** The failure path is
`return 0`; the rewind belongs to the exit primitive. This also dissolves H5.

**D2 — ALTERNATION's "no save, no restore anywhere" is false for literal alternatives** (§2), and
`leaveAlt`'s S4.2 comment is the counterexample, written before the draft.

**D3 — H1 inverts:** `Attributes` refuses; it is not among the 16.

**D4 — the contract's "exactly as at entry" is stronger than the native arm provides** (§1):
native restores post-skip, generated restores pre-skip.

**D5 — a hit, recorded because the ledger wants both columns:** ⚠ **H2 was a citation and it was
RIGHT.** Clay flagged §3 as "my best reading, which is a CITATION", and the grammar line matches
the guess exactly — Family A, `isGROUP`, references `TraiT`, iterated, and the ITERATE shape
rather than SEQUENCE. **This is a structural claim holding, which is what the measured asymmetry
predicts**, and it should be read that way rather than as luck: the prediction was about *shape
from declared structure*, which is the column that holds. The dispatch's own ⚠ PULL discipline is
the same instinct, and on the decoder it caught three misses in one pass — the two together are
the method working in both directions.

## 6. WHAT IS FROZEN AND WHAT IS NOT

**Frozen as of this pass:** the three template shapes in §2 in their certified spelling, and the
`Attributes` v0 instance in §3 with its one deliberate blank.

**Not frozen, and named:**
- ⚠ the **contract's signature** — wants Tony, and wants H4 at RUN grade first (§4 H4).
- ⚠ **`<invoke TraiT parse>`** — blocked on H3(c), a bounded command-registration job.
- ⚠ the **ALTERNATION** shape for literal-bearing chains — Tony's fork (§2).
- the **ITERATE composition** — built from certified parts, itself unrun. Its rung is step 2's.

**Not in scope and not touched:** installing anything.
