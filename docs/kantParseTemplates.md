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
| literal captured to the label | `litTo(tN,label,"{","{")` | — | ❌ no shim |
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

**`kantLeaf` spells the two kinds the shim vocabulary HAS** and returns null for everything else.
⚠ **Refusing is the feature.** §1's table has four dead rows — optional, repetition, alternation,
captured-literal — and an emitter that guessed at them would produce a body that parses and answers
**wrong**, which is this project's worst failure shape. It names the kind it could not spell.

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
