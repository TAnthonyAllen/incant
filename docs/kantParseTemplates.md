# kantParseTemplates — one template per term kind, and the first entry

**asOf 2026-08-12 · binary: the SEQ 55 seal build (`~/bin/incant`, 1386720 bytes, mtime
2026-08-11 18:07) · no rebuild taken for anything here · every number below was RUN**

**What this file is.** A kant parse method's body is its rule's **term-kind sequence** run through
the table in §1 and joined with `AND`. Until an emitter exists, a body written by hand **is a manual
run of the generator** — so every entry here is also a **byte-target** for the eventual emitter.

**Companion:** `docs/parseCodeMeasurements.md` (the measurements this rests on) and
`docs/kantShims.md` (the shims' pricing). The stashed first file is the session scratchpad's
`parseCode`.

---

## 1. THE TERM-KIND TABLE

The left two columns are **measured from the shipped emitter's own output** —
`docs/emitted/phaseB-twelve-emitted.txt`, twelve rules — rather than derived from the grammar by
eye. The right column is what kant can say today.

| term kind | what the C++ emitter lowers it to | kant shim | status |
|---|---|---|---|
| **literal** | `lit(tN,"x")` | **`litK(N)`** | ✅ proven — `incant/kantParse1`, two of them in an `AND` chain |
| **rule reference** (in a sequence) | `parseR(tN,label)` | **`parseRK(N)`** | ⚠ **BUILT, NEVER FIRED.** No live use exists. The first entry below is its first |
| **sequence join** | `&&` | **`AND`** | ✅ proven — short-circuits, both engines byte-agree (2026-08-11) |
| optional `?` | `(parseR(tN,label) \|\| 1)` | — | ❌ **no shim.** `OR` exists but there is no kant spelling of the `1` |
| repetition `+` `*` | a generated `manyX(label,tN)` helper | — | ❌ **no shim, and no helper generator** |
| alternation (a rule with options) | `leaveAlt(rule,from, parseR(t1,into) \|\| …)` | — | ❌ **no shim.** Also a different frame — `into`, not `label` |
| **literal captured to the label** | `litTo(tN,label,"{","{")` | **`litToK(N)`** | ✅ **BUILT 2026-08-31** — discharges `incant/fixits/kantGenPath`. ⚠ **`N` may be `0`**, the zero-means-self marker, where the slot is `rule.tag` and the literal `rule.text`; at `N >= 1` both are `term.tag`. Two derivations, one argument |
| **keyword** (`do`, `while`, `if`, `in`, …) | **never emitted by anyone** | — | ❌ **unpriced.** These are `Keywords` registry entries (`incant/setup:222`), not literals, and none of the twelve emitted rules contains one |

⚠ **THE KEYWORD ROW IS THE ONE THAT WILL SURPRISE SOMEONE.** `DO do- followedBy StatemenT while- …`
*looks* like it prices onto `litK` + `parseRK`. It does not: `do` and `while` are Keywords entries,
so the term kind is neither literal nor ordinary rule reference, and **no generated method in the
tree has ever contained one.** Priced here as a first blocker, deliberately, rather than met
mid-walk.

---

## 2. ⚠ THE FINDING THAT SHOULD DRIVE SCHEDULING: THERE IS NO CLEAN FIRST LIGHT

**Every rule in `incant/grammar` whose terms price onto today's two shims is an option of a
label-transparent alternation** — i.e. sits in GM-29's `promote=0` / `attachLabel:1101` cell.
That is not an impression; it is what the shortlist measured out to.

**Live term counts, by the refusal instrument** (`parseRuleMethod` prints
`rule now has N` when `parseTerms` disagrees) — **no rebuild, no install, no edit to
`incant/grammar`**; the binds were merged onto the rules from a scratch file:

| rule | live terms | prices onto today's shims? | attach site |
|---|---|---|---|
| **`Braced`** | **3** | ✅ `lit · ref · lit` | ⚠ `pLabel=0 pRule=InvokeArg` — **measured directly**, not inherited from Parens |
| `Xpress` | 2 | ⚠ **❌ — CORRECTED 2026-08-13. `ref · isSTRING`, NOT `ref · ref`.** Term 2 is `SemI`, a charset/string term (`data isSTRING`, `testMatch SET`), which has no kant spelling | ⚠ `pLabel=0 pRule=StatemenT` — and it is on **every statement** |
| `UnaryXP` | 2 | ⚠ **❌ — CORRECTED 2026-08-13. `setref · isGROUP`, NOT `ref · ref`.** Term 1 `UnaryOPS` is `data isSET` / row `isBIN/isREGISTRY`; term 2 `ANYtoken` is `data isGROUP`. Neither is a plain rule reference | ⚠ option of `InvokeArg`; and `incant/invokeMix`'s UnaryXP row is **VOID** — hard to fire at all |
| `Parens` | 3 | ❌ term 2 is optional | the banked red |
| `FormaT` | 5 | ❌ charsets + optionals | — |
| `Precision` | 1 | ❌ the term is a repetition | — |
| **`Looper`** | ⚠ **0** | ❌ **unbuildable** | — |
| **`SemI`** | ⚠ **0** | ❌ **unbuildable** | — |

⚠⚠ **AND TWO ROWS OF THIS TABLE WERE WRONG — CORRECTED 2026-08-13 (SEQ 68 part A) BY THE EMITTER
REFUSING THEM.** The **counts** were right; the **kind column** was not. `Xpress` and `UnaryXP` were
both listed `✅ ref · ref` and neither is:

```
genKant(Xpress)   ->  REFUSE SemI     -- inline group / character data isSTRING
                      REFUSE rule Xpress -- term SemI unclassified
genKant(UnaryXP)  ->  REFUSE ANYtoken -- inline group / character data isGROUP
                      REFUSE rule UnaryXP -- term ANYtoken unclassified
```

`dumpRuleTerms` on the live tree confirms it: `Xpress` is `ExpressioN` (a real REFERENCE) then
`SemI` (`data isSTRING`, `testMatch SET`); `UnaryXP` is `UnaryOPS` (`data isSET`, row
`isBIN/isREGISTRY`) then `ANYtoken` (`data isGROUP`).

**THE CONSEQUENCE IS THAT THE WALK'S WORK LIST IS EMPTY AFTER `Braced`.** The vocabulary — literal
and rule-reference — is exhausted at one rule, not three.

⚠ **THIS IS THE T-0 SHAPE AGAIN, and it is the third time this project has paid for it:** a
rule→kind **table** reasoned on instead of re-run, on a byte-identical binary, wrong in a way one
command exposes. The standing rule is *re-measure a cited number before you reason on top of it*,
and the cost here would have been two fixtures built against a classification the tree disagrees
with. **What caught it was not vigilance — it was `kantLeaf` refusing BY KIND rather than guessing**,
which is the make-the-failure-unconstructable family doing its job on the day it landed.

⚠ **AND NOTE WHAT IT DOES NOT SAY**, per H9's refusal corollary: a refusal census reports the
**first** blocker, not the blocker set. Closing the `isSTRING` gap would unblock `Xpress`'s term 2
and reveal whatever term 1 says next — `ExpressioN` looks clean, but that is a reading, not a run.
`UnaryXP` has **both** terms unpriced, so it needs two vocabulary additions, not one.

⚠ **THE `Looper` ROW IS THE LESSON AND IT COST ONE COMMAND.** `Looper=ANYtoken` was the leading
pick on structural grounds — one plain rule reference, and its attach site measures
`pLabel=1 isTarget=0` under `FOR`, which is **outside** GM-29's mechanism on both counts, with a
blast radius of one consumer. **It reports ZERO terms.** A definition-head assignment gives the rule
its *content*, not an indexed term, so `rule[1]` finds nothing and `parseRK(1)` would fail with
*"no term 1 in the current kant parse frame"*. `SemI=";"` is the same shape. **The structural
reasoning about the attach site was right and the buildability was never checked** — the standing
asymmetry, one more time, killed by one command.

**So the pick is a KNOWING instrument, because a clean one does not exist under today's shim
vocabulary.** The actionable form of that: **the shim gap is what gates a clean first light**, and
the cheapest opener is the **optional** form — it alone would promote `Parens` and `PrintField` into
range and is one token of vocabulary, not a mechanism.

---

## 3. TEMPLATE 1 — LITERAL

```
    litK(N)
```
Position only. `lit(field,str)` uses the field for its trace line and matches off `str`, and for a
noLabel literal term **the term's own tag IS the literal** — so `litK` derives it from the same
place the C++ emitter bakes it from, and a second argument would only be a chance for the two to
disagree. Proven: `incant/kantParse1`, `ScafKB "["- "]"-`, body `return litK(1) AND litK(2);`.

## 4. TEMPLATE 2 — RULE REFERENCE

```
    parseRK(N)
```
Lowers to `parseR(term, gKantLabel)`. The **`into` is frame-owned** — the body says *what* to parse,
the frame says *where it goes* — which is the SEQ 54/55 convention expressed as a signature.
⚠ **First live use is the entry in §6. There is no prior one.**

## 5. THE JOIN

```
    return <term1> AND <term2> AND <term3>;
```
`AND` short-circuits and both engines agree on it. **Sound here for the reason the respell charter
gives:** stopping at the first failed term cannot strand the rule mark, because the mark restore
lives **outside** the terms, in the frame.

⚠ **A BODY ENDS IN `return <chain>` AND NOTHING ELSE.** Two separate measurements make this
structural rather than stylistic:
- a body that **returns a datumless node** reports a **false WIN** — the rule claims a match it
  never made, at exit 0 (`docs/parseCodeMeasurements.md` addendum (a));
- a rule action whose last statement is an **`if`/`else`** silently **replaces its own label with
  `true`** (addendum (c) §6).

Both are unconstructable if the emitter only ever emits `return <chain>;`. **That is the structural
guard, and it is why it is written into the template rather than into a review checklist.**

---

## 6. THE FIRST ENTRY — `Braced`

**Grammar:** `Braced "["- ExpressioN "]"-` (`incant/grammar:104`, an option of `InvokeArg`).
**Live term count: 3**, measured. **Emitted C++ twin**, for byte-comparison:
```
    lit(t1,"[") && parseR(t2,label) && lit(t3,"]")
```
**The kant body:**
```
    Braced code={
        return litK(1) AND parseRK(2) AND litK(3);
        };
```

**Why Braced, given §2.** It is the richest **honest** body available: it exercises `litK` (already
certified), **the first live `parseRK`**, and the `AND` chain — which is exactly the richness
increment the design asked rung 1 for. It **fires** (measured: `x[expr]` reaches it, 5 trace hits),
unlike `UnaryXP`, whose own fixture row is VOID — and a rule that never runs produces a **vacuous
green**, which is GM-30's `InvokE` lesson. Its blast radius is bracket-indexing, not every statement
like `Xpress`. And its red is **banked and named** (`docs/emitted/braced-red-specimen.txt`), so the
pre-registration below can actually be written.

### ⚠ PRE-REGISTRATION — THREE OUTCOMES, NOT TWO. Write this down before it fires.

`Braced` is the respell charter's flagship and sits in GM-29's blocked cell —
**measured on this build: `attachLabel lab=Braced promote=1 isTarget=1 pLabel=0 pRule=InvokeArg`.**
`parseViaKant` binds into `rStuff.parseMethod` and so takes `parse()`'s generated fork, which passes
**`promote=0`** (`GroupItem.twk:1231`). It therefore inherits the mechanism **structurally**, not by
inference.

| outcome | what it means |
|---|---|
| **red, same shape as the C++ arm** | kant reproduces the generated arm exactly ⇒ **the frame is faithful and this is a SUCCESS for the kant path**, reported as a red row. GM-29 is the blocker, unchanged. |
| **green** | kant **dodges `:1101`** ⇒ **NEWS, and it needs its own mechanism named before anything is claimed.** GM-29's own reverted candidate produced a green here too, so green alone does not identify the cause. |
| **truncation / no sentinel** | **VOID, not red.** A truncated run's rows are uninterpretable. Do not grade it. |

⚠ **The middle row is the whole reason this is written in advance.** `Braced` has **not been re-run
since 2026-08-05**, and the seal's own finding 2 records what happens when a flagship exhibit goes
green for an unrelated reason: GX-1, landed days earlier for a different defect, would have been
read as the respell's proof.

---

## 7. OWED BEFORE THE FILE IS PROCESSED — three items, none of them large

1. ⚠ **THE INDEX GUARD IS BYPASSED ON THE KANT DOOR.** `parseRuleMethod` REFUSES to bind when
   `parseTerms` disagrees with the live term count, and **warns** when there is no `parseTerms` at
   all (*"indices unguarded"*). The minting design binds `rStuff.parseMethod` **directly inside
   `aCTionDefinE`, with no dlsym and therefore no `parseRuleMethod`** — so **nothing checks that a
   body's positions still match the rule's terms.** That is the staleness class this project keeps
   paying for: change a rule's terms, and `litK(3)` silently addresses a different term. **The mint
   should carry the same count check the dlsym door has.** Cheap now, structural later.
2. **Registration.** `incant/parseCode` is not in `incant/setup`'s `fILEs` registry, so
   `include(parseCode)` would fail with `getFile: could not open file` **and the run would still
   exit 0** (bear-trap #28's fourth item). Register it at landing, not before.
3. **Sweep status.** The file carries no `Start()` and is not a fixture, so `completePop` will not
   sweep it — the same, correct, arrangement as `incant/designDocs`. Nothing owed; recorded so a
   future census reads it as a known state rather than a missing sentinel.

**STOPPED HERE, per the ask.** The file is stashed, not landed; nothing has processed it; processing
gates on the `aCTionDefinE` revision.

---

# ⚠ THE EMITTER EXISTS — `genKant`, 2026-08-13 (SEQ 67 part B / 66-r1 phase 2). **The hand is replaced for two rules**

*Every claim below RUN. `sh genLadder/kantRatchet.sh` is the standing instrument; canary 274 → 276
(`genKant` + `kantLeaf`); fleet byte-identical on both streams; `pop.sh` unmoved.*

**A hand-written kant parse body was always a manual run of a generator that did not exist yet.**
It exists now, and its oracle is the hand: **byte-identity with the body `incant/bracedK` certified
end to end on SEQ 63.**

## THE RESULT — two rules, both byte-identical, from the LIVE terms

```
  ---- Braced
  ok  R1 emit Braced from live terms (5 lines)
  ok  R2 Braced emitted == hand body, BYTE-IDENTICAL (oracle: incant/parseCode)
  ok  R3 EMITTED Braced parses real input -- sumple width is now 251
  ok  R3 EMITTED Braced reached the GENERATED arm (promote=0)
  ok  R3 EMITTED Braced went through the KANT door (kpBraced)
  ---- ScafKB   (R1+R2 only)
  ok  R1 emit ScafKB from live terms (5 lines)
  ok  R2 ScafKB emitted == hand body, BYTE-IDENTICAL (oracle: incant/kantParse1)
RATCHET GREEN -- 8 checks.
```

**`genKant` walks `planRule`'s classified plan** — the same walk `dumpSpellings` makes — so indices
and kinds come from the rule **as it exists in the tree at that moment**, never from a reading by
eye. That is the staleness class §7.1's index-guard item exists to name, closed here for the
emitter's half.

**`kantLeaf` spells the kinds the shim vocabulary HAS** and returns null for everything else.
⚠ **Refusing is the feature.** §1's table now has **two** dead rows — repetition and alternation —
and an emitter that guessed at them would produce a body that parses and answers **wrong**, which
is this project's worst failure shape. It names the kind it could not spell.

⚠ **THE OTHER TWO DIED ON DATES, and the order matters to anyone reading a stale copy:** optional
gained `optRK` (reference-inner only; an optional wrapping a literal still refuses BY KIND, because
`optLK` is not built), and **captured-literal gained `litToK` on 2026-08-31.** The live count is
four: `litK`, `litToK`, `parseRK`, `optRK`.

⚠ **AND CLOSING ONE DEAD ROW DOES NOT UNBLOCK THE RULES IT APPEARED IN — rule H9's corollary,
observed on camera the day `litToK` landed.** `BlocK` stopped refusing on LITTO and began refusing
on **MANY**, one term further in. Four of the five rules that carried a LITTO refusal cleared
outright; the fifth advanced to its next blocker. **A refusal census is a census of frontiers.**

## PROVENANCE IS ASSERTED IN-RUN, NEVER ASSUMED

Every stage of `kantRatchet.sh` uses **that run's own output**: emitted fresh, byte-compared,
written to a file, and executed **from that file**. That is the difference between *"the emitter can
reproduce the hand body"* and *"the bytes that just ran came out of the emitter."* Nothing in the
repo is modified — the emitted file and a re-pointed copy of the fixture live in a scratch dir — so
a red run cannot leave a half-swapped artifact behind.

R3 asserts **three** things, not one: the value, **the arm by name** (`promote=0`, because 251 alone
can pass for the wrong reason — the interpreted arm has always produced it), and **the door by
name** (`parseViaKant Braced -> kpBraced`, so a fallback to the C++ method cannot pass).

## ⚠ ScafKB IS R1+R2 ONLY, AND THE REASON IS SAID OUT LOUD

`kpScafKB`'s body lives **inline** in `incant/kantParse1`'s own define block, not in an included
file, so there is **no `fILEs` line to re-point** at emitted bytes. Its runtime certification is
**INHERITED** — byte-identity with a hand body that fixture already runs green — and is **not
re-run**. Stated per the repeat rule, because **an unsaid inheritance is how a green row starts
meaning less than a reader thinks.** Giving it an R3 means moving its body into an included file,
which is a fixture change and was not this rung's business.

## THE REPEAT RULE, as implemented

A byte-match to a proven hand body **rides the bell** — cheap, inherited. Any **deliberate**
divergence from the hand spelling **kills the byte-oracle for that rule** and re-engages full
runtime certification for it; the harness says so by name in the red row. **Do not quietly re-target
a moved oracle:** a target that moved is a claim the world changed, and the claim needs a cause.

## NEGATIVE CONTROLS — both run, both fired (H7)

| control | result |
|---|---|
| oracle perturbed by one line | **R2 RED**, "the byte-oracle is dead for this rule", exit 1 |
| R3 pointed at a fixture with no matching `fILEs` line | **RED** by the failed-`sed` guard — *and* the harness's own H2 caught the short check count, `RATCHET INVALID -- only 4 checks recorded` |

The second is the better demonstration because **nobody designed it as a pair**: the guard against a
silently-failed `sed` and the self-certification floor caught the same fault from two directions.
A vacuity guard on R1 (*emitted NOTHING*) is there for the same family — **a byte-compare of two
empty files passes.**

## ⚠ AND ONE BEAR-TRAP PAID FOR IN THE BUILDING, recorded because the detector earned its keep

`kantLeaf`'s first cut returned a concatenation straight out of an `if` and used `return 0` for the
refusal. **tok exited 139 and CASCADED** — the entire extern block gone from the regenerated header,
**274 externs to ZERO** — surfacing three files away as `no member named 'opEQ'` in `Bytecode.mm`.
Bear-trap #24 exactly. **The detector named it in one command:** `grep -c '^extern' GroupRules.h`
after every retok. The cure was to copy `emitLeaf`'s spelling exactly — build into a `String` local,
return it once, and refuse with `null` rather than `0`.

## WHAT THIS DOES NOT CLAIM

Two rules is two rules. The vocabulary is still **literal and rule-reference only**, so the four
dead rows of §1 are still dead and every rule that needs them still refuses — loudly, by kind. **The
ratchet's shape is proven; its reach is two.**

---

# SEQ 71 — THE RE-DERIVATION PASS: **PARTIAL. One defect found and fixed, one number VOID and named**

*2026-08-13. Survey driven one rule per process, 79 processes — the in-process walk crashed after
one rule (recorded below), and sidestepping it beat debugging it.*

## ⚠ THE FINDING THAT MATTERS: `genKant` WAS EMITTING **WRONG BODIES** FOR ALTERNATIONS

The survey said five rules price onto today's vocabulary. **Four of them were lies**, and the
emitter's own output is what exposed it:

```
kpInvokeArg code={ return parseRK(1) AND parseRK(2) AND parseRK(3); };
```

`InvokeArg` is the **alternation `Braced` is an option of**. `dumpRuleTerms` gives `fold=ALT` for
`InvokeArg`, `ElsE` and `WardeD`. **`genKant` joined unconditionally with `AND`** — which means
*all options must match* where an alternation means *any one does*. **Bodies that parse and answer
wrong**, which is the failure this whole campaign is built to prevent, in the emitter that landed
the same day.

⚠ **AND NOTE WHAT DID NOT CATCH IT.** `kantLeaf` refuses by KIND and covers every unknown **term**.
The join is **not a term**, so a per-item guard could not see it: **a whole-body property is
invisible to a per-item check.** That is the transferable lesson, not the three rule names.

**Fixed — and it REFUSES rather than emitting `OR`**, because the alternation row is dead for a
second, independent reason: an option attaches through a different frame (`into`, not `label`), so
an `OR` chain would be the right operator on the wrong plumbing. One dead row, not half of one.

```
  Braced     define                         <- still emits
  ElsE       REFUSING -- fold is ALT
  GrouP      REFUSING -- fold is ALT
  InvokeArg  REFUSING -- fold is ALT
  WardeD     REFUSING -- fold is ALT
```

**So the honest count of rules that price onto today's vocabulary is ONE: `Braced`.** Ratchet green,
smoke green, canary 276.

## THE POPULATION — three numbers, none of which agree

| source | number |
|---|---|
| the dispatch's citation | "**47** live rules" |
| `incant/popScratch`'s own header (measured 2026-08-05) | **78** = 60 rule members + 18 rule attributes |
| **this pass, by iterating the registry** | **79** members |

**None of them is confirmed.** The 79 is one spelling — `for r in Grokking` — and the dispatch
asked for a **second spelling**, which this pass did not deliver. ⚠ **The 47 is the one to stop
citing**: it matches nothing measured, and columns 2-5 of the jittability census were handed back
precisely because they divide by it.

## ⚠ THE BLOCKING-KIND TALLY IS **VOID** — and it is void for an instrument reason, named

The tempting table — 16 `isSET`, 9 `isGROUP`, 7 `isSTRING` — **is not reportable**, and it took one
look at the leftovers to know it. 39 of 79 rows came back with an empty reason, and reading them by
eye found **three different things wearing one blank**:

| what the blank actually was | example |
|---|---|
| **the driver never looked the rule up** | `kant: no rule named (null)` (`ANYstring`) |
| **a mangled name read** | `kant: no rule named Anydata type has no toString() method` (`Any`) |
| **a REAL refusal in a message shape the parser missed** | `REFUSING BlocK -- term 2 is MANY` |

So the counted rows are only the ones one `sed` happened to match, and the real distribution is
unknown. **An undercount reads as a smaller problem and an overcount as a bigger one; neither reads
as a broken instrument** — H9, arriving in the census H9 was quoted at.

**What it would take to finish:** fix the driver's name-passing (bear-trap #26's family — a bare
rule name whose node carries no data), and parse **both** refusal shapes (`  REFUSE <term> -- ...`
and `genKant: REFUSING <rule> -- ...`). Neither is hard; both are precision work and neither was
attempted at the end of a long session on purpose.

## THE IN-PROCESS WALK CRASHES — filed, not chased

`for r in Grokking; genKant(r);` reaches **exactly one rule** and exits **139**. Sidestepped by
running one rule per process (79 runs, ~3s, no shared state), which is also the more auditable
shape. **Not diagnosed.** Likely candidates are `genKant`'s own registry lookups disturbing the
loop's cursor, or bear-trap #26's name-read — but that is inference and the causal-claim ledger says
what inference is worth here.

## WHAT THIS PASS DID **NOT** DELIVER

The stamped table is **not** produced. Consumer counts, attach sites and verified per-rule term
kinds across the population all wait on the same two instrument fixes above. ⚠ **So the next
vocabulary charter still cannot be chosen off this table** — which was the pass's whole purpose, and
saying so is better than stamping rows built on a driver that silently failed to look up half its
population. **The one thing it did settle is worth the pass on its own: the emitter was producing
wrong bodies for four rules, and now it refuses them.**

---

# SEQ 72 — THE STAMPED TABLE, DELIVERED. **Both instrument fixes landed; the denominator settled**

*2026-08-13. Instrument: `genLadder/kantCensus.sh` (new). Raw run banked at
`docs/emitted/kantCensus-2026-08-13.txt`. **78/78 rows, zero blank, zero unclassified, zero
crashed.** No install, no bind, no parse of real input; no C++ change, no retok, no rebuild —
fleet byte-unmoved on all 60 check rows.*

## THE NAME-PASSING FIX, AND ⚠ THE OBVIOUS REPAIR WAS WORSE THAN THE DEFECT

SEQ 71's driver passed the rule name as a **bare identifier** — `genKant(Foo)` — and `genKant`
reads `argument.text`. Bear-trap #26, failing **two different ways**, which is why one `sed`
could never have sorted the 39 blanks:

| spelling | result |
|---|---|
| `genKant(ANYstring)` | `kant: no rule named (null)` — the name **never arrives** |
| `genKant(Any)` | `kant: no rule named Anydata type has no toString() method` — the name arrives at a node that **carries data**, so `.text` reads the DATA and the stringify diagnostic is what got printed as a name |

⚠ **The tempting one-liner is `.text` → `.taG`, and it manufactures the T-0 failure rather than
fixing it.** Measured, not reasoned:

```
Braced.taG    = Braced      right
Any.taG       = Any         right
ANYstring.taG = DatA        ⚠ A DIFFERENT RULE
```

A `.taG` repair would have surveyed **`DatA` under a row labelled `ANYstring`** — **39 blank rows
become 39 rows that look like facts**, in a table whose entire purpose is to be reasoned on top of.
An undercount reads as a smaller problem; a wrong row reads as the world.

**The fix is to pass a string literal: `genKant("Foo")`.** A driver change, which is why nothing
could move.

⚠ **AND THE NEGATIVE CONTROL IS THE ROW THAT MATTERS (H7):** `bare/Braced` **works — by accident.**
`Braced` carries no rule-level data, so `.text` falls back to echoing the tag (trap #26, payment 5).
**Every rule the SEQ 71 survey got right, it got right that way.** The control runs inside the
census on every invocation and the census refuses to print a table if it stops firing.

## NO BLANK ROW IS CONSTRUCTABLE — the closed set, printed in the output header

`NONE · LOOKUP · TERM · RULE · FOLD · EMITTER · UNCLASSIFIED · NO-OUTPUT · CRASH`

The two shapes SEQ 71 conflated are **TERM** (`  REFUSE <term> --`) and **RULE**
(`  REFUSE rule <rule> --`), separated only by the literal word `rule`; they turn out to be **31 and
31**, so the conflation was hiding a clean half-and-half split. `UNCLASSIFIED` **fails the census**
and prints verbatim, so an unforeseen shape gets a name rather than a bucket. The **first** refusal
line is the blocker — `genKant`'s own `-- no plan` always *trails* the refusal that caused it.

⚠ **THREE DEFECTS FOUND IN THE NEW INSTRUMENT ITSELF**, listed because the class is the point:
**(1) one channel, one meaning** — the first cut of the KINDS column spelled *unclassified* `?` and
*optional* `?`, so `FormaT` read `?G?R??L` and no reader could say which was which; kinds are now
alphabetic and modifiers punctuation. **(2) an anti-vacuity guard** — the KINDS cell must carry one
letter per counted term, because a classifier that drops a term prints a **shorter, entirely
plausible** string; control run with one arm removed fires on six rules by name. **(3) H1** —
`ls -l` on `~/bin/incant` reports the **symlink's** mtime, which never moves; `ls -lL`.

## THE DENOMINATOR — settled, and there was never a discrepancy

| source | number | verdict |
|---|---|---|
| the dispatch's citation | 47 | **matches nothing measured, on either spelling. Dead.** |
| `popScratch` header (2026-08-05) | 78 | **CONFIRMED** — 60 rule members + 18 rule attributes |
| SEQ 71, `for r in Grokking` | 79 | **CONFIRMED** — list ENTRIES, not rules |

**79 counts entries; 78 counts rules. Both are right.** The single entry that is not a rule is
**`Operators`**, the operator registry. The census's denominator is **78** and it excludes that
entry **by name, in the output, every run**.

## ⚠ WHAT THE TABLE SETTLES FOR THE NEXT VOCABULARY CHARTER

**Sixteen rules have terms that are entirely `L`/`R`** — every term already prices onto today's two
shims — and are held out by exactly one thing each. This is the only cut that can speak to *"what
does one vocabulary item buy"*, because it is the only cut where **nothing else is known to be in
the way**:

| held out by | count | rules |
|---|---|---|
| **nothing** | 1 | `Braced` |
| **OPT** (optional) | **5** | `InvokE` `Parens` `PrintField` `RunRulE` `TokenXP` |
| **ALT** (fold) | 4 | `ElsE` `GrouP` `InvokeArg` `WardeD` |
| **MANY** (repetition) | 2 | `BlocK` `ExpressioN` |
| **LITTO** | 1 | `CodE` |
| rule-level data / registry | 3 | `BrancheS` `NumbeR` `Token` |

**So §2's cheapest-opener call is measured and SUPPORTED:** the optional is the largest single
cause, 5 against the alternation's 4 — and the gap is wider in practice, because **ALT is a
mechanism and OPT is one token** (an option attaches through `into`, not `label`, which is why
SEQ 71 refused ALT rather than emitting `OR`).

⚠⚠ **AND THE FENCE IS NOT OPTIONAL. This is a STRUCTURAL READ OF A CLASSIFIER'S OUTPUT, NOT A RUN.**
It says: for those five, **no other unspelled kind appears in their term lists.** It does **not** say
spelling OPT makes them emit, nor that emitting makes them parse correctly, nor that a sixth gate
will not appear behind a closed one. Structural claims on this project hold and causal ones are a
coin flip until run — **re-run the five after any close.**

## ⚠ THE CROSS-TAB, which is H9's refusal corollary visible inside the table

**11 rules are `fold=ALT` but only 4 report FOLD as their first blocker.** The other seven refuse
*earlier* — `DatA`, `ANYorNum`, `LoopRestrict`, `PrintXP`, `ScopeField`, `StatemenT`, `Token` — and
would still refuse if the alternation row were spelled tomorrow. **That is the argument against
reading any count here as "closing X opens N rules." It does not. It reveals N next refusals.**

## BANKED STUMBLES — not chased, fix-or-skip is Tony's

1. **The in-process walk still crashes** — `for r in Grokking; genKant(r);` reaches one rule and
   exits 139. Carried from SEQ 71 unchanged; one-rule-per-process sidesteps it and has no shared
   state between rows, which is the better shape anyway.
2. ⚠ **Why bare `ANYstring` resolves to a node tagged `DatA` is UNDIAGNOSED.** The grammar line is
   `ANYstring=[^ \n\r\t;]+;` (`incant/grammar:93`) and names no `DatA`. **Symptom measured and
   reproduced; mechanism NOT written down**, per the split that keeps bear-trap #18 honest. It
   matters past this census: **any bare-identifier rule reference in incant may be reaching a
   different node than its spelling says.**
3. **`dumpRuleTerms` (`genParse.rtn:172`) carries the same hazard** — `locate(argument.text)`. Safe
   as the census drives it (string literals only), but the defect is in the function, not the
   caller. A C++ edit and a rebuild, which a measurement-only dispatch may not spend.

---

# OPT CHARTER, RUNG ONE — **the vocabulary landed; the live install stumbled at 139**

*2026-08-13 late. Decision (a) RULED by Tony off SEQ 72's stamped table: the vocabulary charter is
OPT. Fleet UNMOVED across the C++ change and rebuild — every `pop.sh` check row byte-identical.*

## THE SHIM — `optRK`, and why it is per-inner-kind

`optRK(N)` is `parseRK`'s contract with **one leg's answer flipped**: attempt term N; on success
proceed; on failure **restore the cursor and still answer success**. Cursor discipline identical,
only the verdict changes.

⚠ **A SEPARATE SHIM PER INNER KIND, not one `optK` that works out LIT-vs-CALL at run time.**
`planTerm` already makes that decision when it builds the plan, and a run-time re-derivation would
be a **second implementer** of it — the arrangement `countRuleTerms`' own comment refuses, because
two implementers of one decision drift silently. So the emitter keys on the plan node's inner kind.
**`optLK` (the literal optional) is NOT BUILT**, and `kantLeaf` refuses that shape by name.

⚠ **THE RESTORE IS BELT-AND-BRACES ON THIS SHAPE AND THE FILE SAYS SO.** For an optional
*reference* the callee owns a frame and its `leaveRule` already rewinds — `planTerm`'s rung-6 note
records exactly that. **So this rung does NOT independently falsify the restore**; its certification
arrives with `optLK`, where there is no callee frame. Recorded rather than left for someone to
assume.

## THE MEASURED DELIVERY — emittable population 1 → 4

| rule | before | after |
|---|---|---|
| `Braced` | ✅ | ✅ |
| `InvokE` | ❌ OPT | ✅ `litK(1) AND optRK(2) AND litK(3)` |
| `Parens` | ❌ OPT | ✅ `litK(1) AND optRK(2) AND litK(3)` |
| `PrintField` | ❌ OPT | ✅ `parseRK(1) AND optRK(2)` |
| `RunRulE` | ❌ OPT | ❌ **optional wraps LIT** — wants `optLK` |
| `TokenXP` | ❌ OPT | ❌ **optional wraps CONTAINER** |

⚠⚠ **SEQ 72 SAID FIVE. CLOSING OPT OPENED THREE — AND THAT IS THE FENCE PAYING OUT, NOT FAILING.**
SEQ 72's own report said *"re-run the five after any close"*, because a **first-blocker count is not
a promotion count** (H9's refusal corollary). The re-run says three. **A count of what blocks first
tells you nothing about what blocks second.**

## ⚠ RUNG ONE — TWO PICKS, TWO DIFFERENT FAILURES, BOTH INSTRUCTIVE

Full evidence: `docs/emitted/parens-opt-stumble-2026-08-13.txt`.

**Pick 1, `InvokE` — EXIT 0, both legs printed 251, and it proved NOTHING.** Zero
`parseViaKant InvokE` lines; zero `attachLabel lab=InvokE`. The **bind took** — `SEAM read` shows
`defParseMethod == boundParseMethod`, SEQ 58's closed seam working as sealed — but `parse()` never
forked, because **`fireIt()` does not parse via `InvokE`**. It parses `TokenXP → InvokeArg → Parens`
(`incant/grammar:106-109`); `InvokE` is reached from `RunRulE`.
⚠ **The STRUCTURAL claim held** (`LR?L`, optional between two literals, absent leg falsifiable);
**the CAUSAL claim — "this input reaches this rule" — was read off the grammar by eye and was
false.** GM-30 had already recorded that `InvokE` does not fire; the note was **cited and not
measured**. The standing asymmetry, one more time, killed by one run.

**Pick 2, `Parens` — EXIT 139, ZERO bytes of stdout.** `Parens` is `Braced` with term 2 made
optional: same parent alternation, same attach frame, and the control is already green. Measured:
**3556** `parseViaKant Parens -> kpParens` entries · **0** `parseR term=ExpressioN` · **0** shim
refusals · died before its own header line.

⚠⚠ **3556-with-no-progress is the signature of unbounded re-entry. THAT IS A DESCRIPTION, NOT A
DIAGNOSIS, AND IT IS LEFT THAT WAY.** Two mechanisms are available and **neither is named as
cause**: (a) re-entrancy — `docs/jitDesign.md`'s Mechanism 3 is a **filed tension** about this exact
shape and is out of scope; (b) the ALT-option frame (`into`, not `label`). **`Braced` is also an
`InvokeArg` option and works, which alone sinks (b) as a standalone story.** One run should separate
them; that run is tomorrow's, because a stumble is banked, not chased.

## ⚠ THE FENCE PROBE — FENCED

`locate(argument.text)`-shaped resolution runs at **three** live sites, **none on the install or
parse path**: `dumpRuleTerms` (instrument, filed), `runNotified` (`GroupItem.twk:1562`) and
`styleComponent` (`GroupDraw.twk:220`). **The kant doors do not use it** — `parseViaKant` and
`kantDoor` build `"kp" rule.tag` as a **String** and locate *that*, so a name never passes through a
node's `.text`. `parseRuleMethod:1908` reads `.text`, but of a `parseMethod=` attribute whose value
the source assigned with `=` (bear-trap #26 payment 6's safe form); it **dlsyms rather than
locates**, and it names the empty case.

## ⚠ AND A CORRECTION OWED TO SEQ 72's OWN TABLE — 11 of 78 rows were wrong

The census KINDS column tested **`REFERENCE` before the data row**, so every term that is *both* a
reference *and* carries data was called `R` where the tree calls it a container or charset.
**`row42`'s own header warns about precisely this** — it mirrors `setTestMatch`'s cascade *in its own
order*, and says a classifier reading the table top-to-bottom would already disagree with the tree.
**It was read top-to-bottom anyway.** Corrected and re-run: `TokenXP` `UnaryXP` `DatA` `Token`
`BrancH` `FloaT` `NumbeR` `PrintField` `ANYorNum` `FormaT` `ScopeField`.

⚠ **WHAT CAUGHT IT WAS `planTerm` REFUSING BY KIND** — `TokenXP`'s `UnaryOPS?` came back CONTAINER
where the census said `R`. **Third time in two dispatches that refuse-by-kind has named an
instrument defect.** Structure, not vigilance.

**RESIDUAL, NAMED NOT FIXED:** the census's KINDS and SHIM columns are **two classifiers** (`row42`
vs `planTerm`) and still disagree — `PrintField` reads `RC?` and emits anyway. **The SHIM column is
authoritative**; do not read KINDS as a shim predictor.
