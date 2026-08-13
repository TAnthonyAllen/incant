# parseCode — the measurements behind Clod's reply to the rule-code{} design

**asOf 2026-08-12 · binary: `~/bin/incant` → DerivedData Debug/Groups, 1386720 bytes, mtime
2026-08-11 18:07 (the SEQ 55 seal build — no rebuild taken for any row here) · tree clean but
Tony's held-back `IncantForms/WorkingOn/incant++`**

Written because the design discussion is happening in chat and **a premise whose only home is a
thread is an unmeasured citation waiting to be made** (`docs/respellRung.md`'s own reason for
existing). Every row below was run, not read. Where something is read-not-run it says so.

---

## M1 — THE PARTITION. The census, H9-stamped.

**What was matched, said before the number:** every definition in `incant/*`, `*.rtn` and `*.twk`
carrying the `isRule` flag — matched at the flag and then scanned forward to the definition's
closing `;` at brace depth 0, so a `code={` three lines below the `isRule` is caught. Excluded
`isRule =` / `isRule immediateAction` (those are the flag's own registration, not a use).
**145 isRule definitions matched; 8 carry code; 3 of the 8 are false positives read by eye.**

### The five real coded rules — ALL outside Grokking

| rule | file | registry | terms |
|---|---|---|---|
| `list` | `incant/unitTests:144` | `UnitTests` | `entries=ANYstring+ SemI?-` |
| `list` | `incant/scopeUnits:161` | `UnitTests` | same (second copy) |
| `JSONfield` | `incant/utilities:66` | `Utilities` | `JSONtoken ":"- JSONvalue ","?-` |
| `JSONarray` | `incant/utilities:73` | `Utilities` | `"["- JSONlist? "]"-` |
| `DelimOver` | `incant/delimTest:90` | `Delim` | `body}=delimiter` |

False positives, named so the 8 reconciles: `GroupActions.rtn:553` is a bare `if isRule {`;
`RuleStuff.twk:840` and `:968` are **comment headers quoting `incant/utilities`** above the
hand-written `parseJSONfield`/`parseJSONarray`.

⚠ **`incant/utilities` is `include`d by every fixture preamble in the tree** (the AND/OR rung's
part-3 census finding, 2026-08-11). So the coded-rule population is not a corner of `unitTests` —
**two of the five sit in the file the whole fleet loads**, and `jsonTest` is a byte-identical
baseline over them.

### Grokking's own count is ZERO, and the scope of that claim is stated

`grep -n "code *=" incant/grammar` → **no hits**. `registry(Grokking)` is opened in exactly one
live file (`incant/grammar:68`; the only other hit is `IncantForms/BackupXML/grammar`, an archive).
So the grammar registry's coded population is **0/0** — not "0 found by a grep that might have
missed a spelling", but 0 in a file that contains no `code=` at all.

---

## M1b — ⚠ THE ROW NOBODY ASKED FOR, AND IT IS THE ONE THAT MOVES §1

**`code{}` ON A GROKKING RULE THAT ALREADY HAS A C++ ACTION IS SILENTLY INERT TODAY.** Run, not
inferred (fixture kept in the session scratchpad as `m1parens`; no include line, for the reason
`incant/parensMin`'s header gives):

```
=== ROW A: baseline, no code on Parens ===
   INSIDE m1Take, argument is 7
=== MERGE: give the Grokking rule Parens a code body ===
=== ROW B: same call, after Parens carries code ===
   INSIDE m1Take, argument is 7          <- Parens still parses (7)
M1PARENS SENTINEL
```
`PARENS CODE BODY RAN` **never appears.** Exit 0, no error, no warning.

**The mechanism is pointable, one line.** `ruleActions.rtn:348` gates the whole method-binding
block on `if !isREGISTRY && !isMethod`. `Parens` already carries `isMethod` from its original
definition (dlsym found `aCTionParens`), so on re-definition the block is skipped entirely and
`:352`'s `or isCoded  method = processAction` never fires. `:328` still sets `isCoded = true` and
the CodE is attached — **read by nobody.**

### Which makes the real fork `isMethod`, not registry membership

| rule | C++ `aCTion<Tag>` exists | `isMethod` at define | what `code{}` means today |
|---|---|---|---|
| `Parens`, and every Grokking rule with a C++ action | yes | true | **nothing. Silently inert** (measured above) |
| `list` · `JSONfield` · `JSONarray` · `DelimOver` | no | false | `method = processAction` — **code IS the action** |
| a Grokking rule with **no** C++ action (`SemI`, `Token`, `InvokeArg`, `Start`, `InitiatE`, … — `isMethod=0` in any `parseTrace` run) | no | false | **would also mean ACTION** |

⚠ **So the partition does not follow the registry line, and the third row is why.** Registry
membership and "has a C++ action" happen to coincide across today's five coded rules, but they are
different tests, and they come apart exactly on a Grokking rule with no C++ action — of which there
are many.

**The ruling is still safe, for a narrower and better reason than the one proposed:** it is safe
because **`incant/grammar` carries no `code=` at all**, so scoping the routing to Grokking cannot
change the meaning of anything that exists. It is *not* safe because Grokking rules are
structurally exempt — they are not.

**Latent trap, filed rather than fixed:** writing `code{}` on a rule that already has a C++ action
is accepted at exit 0 and does nothing. Bear-trap #26's family by signature — a plausible outcome
where an error was wanted.

---

## M2 — THE MERGE. Confirmed, with a discriminating negative row.

Fixture in the session scratchpad as `m2merge`. Rule defined with terms in `M2reg`, then
**re-defined with code only from outside the registry block**, then parsed again.

```
=== ROW A: terms only, before any merge -- 'ab' ===        (match, no action, nothing printed)
=== MERGE: re-define M2rule with CODE ONLY, outside the registry ===
=== ROW B: same input after the merge -- 'ab' ===
   M2rule code body ran                                     <- terms STILL matched, code attached
=== ROW C: non matching input after the merge -- 'zz' ===   (silent — the rule FAILED)
M2MERGE SENTINEL
```

**Row C is the anti-vacuity guard and it is load-bearing.** A merge that wiped the term list would
still let rows A and B report success if an empty term list were vacuously satisfied. Row C wants a
FAIL and gets one, so the terms demonstrably survived rather than being merely un-contradicted.

**Verdict: terms survive a code-only re-definition from outside the registry.** §2's merge premise
holds.

**Noise, characterised so it is not read as a merge artifact:** the run emits
`nextGroup: ERROR CodE does not contain a list` ×2 on stderr. A control (`m2ctl` — the same rule
defined *with* code in one go, no merge) emits the **identical two lines**. So it is a property of
coded rules generally, pre-existing, and says nothing about merging.

---

## §3(a) — IS REGISTRY MEMBERSHIP CHECKABLE AT DEFINE TIME? Yes, and the spelling matters.

**Available:** `currentRegistry` is already read four times inside `aCTionDefinE`
(`ruleActions.rtn:265-276`), and `currentRegistry.isRule` is already the codebase's own
"am I in the grammar registry" test — used at `ruleActions.rtn:269` and again at
`Commands.rtn:540`.

**It resolves to Grokking and only Grokking.** `grokking.isRule = true` at `GroupMain.twk:16` is
the **only live site** that marks a registry as a rule (the two other `isRule = true` hits are
`GroupMain.twk:246`, the bootstrap `CodE` *rule*, and `Commands.rtn:535`, `processFlags` handling
the `isRule` keyword; the `Aside/` hits are archive).

⚠ **But `currentRegistry` is the WRONG read for §2's file.** The parseCode file has no
`registry()` wrapper by design, so at the moment its entries are processed `currentRegistry` is
whatever was last open — not Grokking. The check that works for **both** the in-place grammar
definition and the bare re-definition is the definee's own registry:

```
NewGroup.registry.isRule          not   currentRegistry.isRule
```

`registry` is already read on `NewGroup` at `ruleActions.rtn:265`. **This one line is the whole of
duty (a)**, and it exempts `list`, `JSONfield`, `JSONarray` and `DelimOver` automatically with no
marker and no exemption list.

---

## §3(c) — THE BINDING IS BIGGER THAN ONE LINE, AND THERE IS A CHEAPER SPELLING

`parseViaKant` does **not** read the rule's own CodE. `genParse.rtn:1810-1812`:

```
    want    = "kp" rule.tag;
    action  = locate(want);
```

It finds its body **by naming convention in a separate action** (`incant/kantParse1` proves the
loop with `ScafKB` → `kpScafKB`, the action living in its own `KantParse1` registry). So §3's duty
(b) — *"route the compiled block into parse-method storage"* — has no storage to route into yet;
as spelled it implies widening `parseViaKant` with a second lookup path.

**Cheaper, and it leaves the proven trampoline byte-untouched:** have duty (b) mint `kp<Tag>` and
hang the CodE there. Then duty (c) is genuinely one line (`rStuff.parseMethod = parseViaKant`),
`parseViaKant` is not edited at all, and the mechanism certified on 2026-08-11 keeps its
certification. The user still writes `Parens code={ … }`; `kp Parens` is an implementation detail
of the routing.

---

## §4 — THE ACTION-CALL TAIL ALREADY EXISTS. `actK()` IS UNNECESSARY AND, AS SPELLED, A HAZARD.

**Measured live, in the `incant/kantParse1` run of this session** (`parseTrace` on, stderr):

```
    parseViaKant ScafKB -> kpScafKB
  WIN  ScafKB  (kant)
  fireLabelMethod ScafKB isMethod=0 label=1 deferred=0 parseACTION=0
```

The frame fires the rule action **after** `parseViaKant` returns, with a live label
(`label=1`). Nothing ran only because `ScafKB` has no action (`isMethod=0`). The same run shows the
positive case on the interpreted arm: `fireLabelMethod Parens isMethod=1 label=1` →
`fireLabel IN Parens` → `fireLabel OUT Parens`.

**The structure, pointable:** `parseViaKant` binds into `rStuff.parseMethod`, so it takes
`parse()`'s generated fork at `GroupItem.twk:1219`. That fork does:

```
    label   = defStuff.parseMethod(this);
    sukcess = label != 0;
    if sukcess {
        fireLabelMethod(ruleStuff);          // GX-1, 2026-08-06
        attachLabel(ruleStuff,pStuff,0); }   // PC-4
```

`fireLabelMethod` is documented at `GroupItem.twk:969` as **"THE RULE ACTION, and the ONLY site
that fires one."** GX-1 made both arms use it.

⚠ **So a `actK()` in the kant body would be a SECOND fire, not the first.** For `aCTionParens` that
might survive; for any rule whose action has an effect it would not, and it would not announce
itself. This is the one-channel-one-meaning family arriving from the other direction — two live
firing paths for one fact.

**The counter-exhibit, and why it does not overturn this:** `RuleStuff.twk:857`'s hand-written
`parseJSONfield` fires the action *itself* —
`if ok { ruleSTUFF = label.rStuff; label = rule.method(label); }` — and folds it into the verdict
as `ok && label`. That is **pre-GX-1 legacy and is bound nowhere live** (`jsonTest` runs the JSON
rules interpreted; no fixture or `.rtn` binds `parseJSONfield`). Checked, because a shipping
counter-example to a "only site" claim has to be accounted for rather than ignored. If it were
ever installed it would double-fire — worth a line in the corpus, not worth a rung.

**What §4 should say instead:** the frame owns the action call, as it owns position, label, mark
and rule identity. That is the SEQ 54/55 convention holding one term further than it was stated to.

---

## §5 — `Parens` IS A NAMED-BLOCKED RULE. Same list as `Braced`, four days after that lesson.

`docs/grammarCorpus.md` **GM-29** (2026-08-07) classifies the plannable rules and puts `Parens`
in the first group:

> **alternation OPTIONS, blocked directly:** `Braced` · `Parens` · `PrintField`

The mechanism is named to one line — `attachLabel`'s no-label guard, `GroupItem.twk:1101` — and it
fires because the **generated arm passes `promote=0`** (`GroupItem.twk:1231`, PC-1's ruling) while
`Parens`'s parent `InvokeArg` is a label-transparent alternation with no label to attach under.
The interpreted arm passes `promote=1` (`:1254`) and works. Confirmed live in this session's
`kantParse1` stderr: `attachLabel lab=Parens promote=1 isTarget=1 pLabel=0 pRule=InvokeArg`.

**`parseViaKant` takes the `promote=0` fork.** It is the generated arm — same line, one level up.
So the kant install inherits the mechanism structurally, not by inference.

**The measured red, banked:** `docs/emitted/parens-red-specimen.txt`, arms A and B, same binary.
Install ON → `pmTake(7)`'s argument **silently vanishes** while the trace reports `HIT Parens` /
`WIN Parens` on every fire, and — separately — **every fixture that `include`s anything dies on its
first statement**, because `include(...)` is parsed by `Parens`.

⚠ **Which makes `Parens` the exact shape of the trap the seal paid for on 2026-08-11.** If it comes
back green, green means *"the kant arm dodged `:1101`"* — a claim that needs its own mechanism
before it is celebrated, not read as first light's proof. If it comes back red, red says nothing
about kant. **A two-outcome prediction has nowhere to put either.**

### The case FOR keeping it anyway, which the design does not make

`Parens` is the **only** rule in the grammar with a pre-built, negative-controlled instrument:
`incant/parensMin` runs both arms by construction, its header records that its first cut
discriminated nothing and was caught by H7, and `docs/emitted/parens-red-specimen.txt` is the
banked comparand. Nothing else on the slate has that.

**So keep it — and write the pre-registration first, in three outcomes, not two:**

| outcome | what it means |
|---|---|
| argument absent, trace says WIN | kant reproduces the C++ arm exactly ⇒ **the frame is faithful**, and GM-29 is the blocker, unchanged. A *success* for the kant path, reported as a red row. |
| argument present (`INSIDE pmTake, argument is 7`) | kant **dodges `:1101`** ⇒ NEWS, and it needs the mechanism named before anything is claimed. GM-29's own reverted candidate produced exactly this line, so the line alone does not identify the cause. |
| anything truncates / no sentinel | **VOID.** Not a red. `include` is downstream of this rule; a truncated run's rows are uninterpretable. |

The alternative slate is thin, which is itself worth knowing: GM-30 measured that three of GM-29's
five "plain rules" (`CodE`, `InvokE`, `RunRulE`) **are inside `incant/grammar`'s opening comment**
and are not definitions at all; `ExpressioN` installed **RED** with a different, unestablished
mechanism; **`BlocK` was never attempted** and is the one untried plain candidate — with the
wrinkle that it is `defer`red, so it fires 2 and attaches 0.

---

## ⚠ THE PRIZE THE DESIGN DOES NOT NAME: A KANT INSTALL COSTS **ZERO BUILDS**

GM-30's own aside: *"THE GRAMMAR IS RUNTIME DATA, SO THIS COSTS NO REBUILD. `incant/grammar` is
read at startup; only the generated method needs compiling."*

**The kant path removes the second half of that sentence.** `parseViaKant`, `litK` and `parseRK`
are already compiled and already registered. A kant parse method is a **file edit** — the
`parseMethod=`/`parseTerms=` binds are runtime data, and so is the `kp<Tag>` body.

Contrast the campaign this replaces: GM-29 and GM-30 cost **two builds per candidate**, a full
revert each, and an extern canary count to prove the revert. `incant/parseCode` costs a text file.

**This changes the shape of §5's ladder, not just its cost.** "Candidate zero, chosen because Tony
recognizes it" is the right pick for a rung that costs a build. When a candidate costs nothing,
the question stops being *which one* and becomes *how many in one afternoon* — and a rule whose
outcome is ambiguous (`Parens`) is worth running **beside** one whose outcome is not, rather than
instead of it.

---

## §6 / RUNG 1 — WHICH IS CLOSER TODAY: **BY HAND.**

**There is no `genKantParse` emitter in the tree.** Every hit is prose: `docs/genKantParse.md` is
Clod's 2026-08-08 assessment of planB, and the `.rtn`/`.twk` hits are comments referring forward to
"genKantParse v1". `docs/kantParseTemplates.md` **does not exist**.

So rung 1 is: hand-write from the two proven shims, and the templates file is a **new** artifact
written *by* rung 1 rather than consumed by it. That is the right order anyway — §6's own point is
that a hand-written body IS a manual run of the generator, so the first one written by eye is what
the templates get generalised *from*.

**The three shims that exist**, and the whole of today's vocabulary: `litK(n)`, `parseRK(n)`, and
the `AND`/`OR` chain. `Parens` is `"("- ExpressioN? ")"-`, so its body is
`return litK(1) AND parseRK(2) AND litK(3);` — with the **optional** `?` on term 2 having no shim
and being the first blocker, which §6 predicts belongs in the census's first-blocker column and
which lands on candidate zero rather than later. Worth pricing before rung 1, not during.

---

## §8 — STORED-ACTION vs STORED-COMBINED. Both sides, and a third option that exists already.

| | **stored-combined** (file holds the welded body) | **derived-at-load** (file holds the action; prefix derived from live terms) |
|---|---|---|
| certification | byte-artifact; fire-twice compares it directly | nothing stored to compare; must compare the *derived* body across arms |
| staleness vs term changes | **possible, and SILENT** — add a term, the stored prefix still matches the old shape, parse succeeds on the wrong shape at exit 0 | **unconstructable** — re-derived every load |
| emitter defects | frozen into an artifact you can read | become a **runtime** fault in every load |
| the eyeball step (WT-9 relocated) | free — the text is right there | lost, unless something dumps it |
| §2's idempotency clause | coherent (regenerate whole from the registry) | **incoherent** — there is nothing to regenerate; the file becomes hand-owned source |

**The staleness row decides it on this project's own doctrine.** *Prefer a structure that makes the
failure unconstructable over a discipline that avoids it* — and the failure being avoided here has
this codebase's worst signature: a wrong parse at exit 0 with a green verdict, which is precisely
what `parensMin` measured and what finding 3 of the 08-11 seal (parse-green is not shape-correct)
was written about.

**And the eyeball loss is recoverable, with a mechanism that already ships.**
`INCANT_PARSE_RECORD` / `incant/recordPT` exists and was used by GM-29 to *regenerate rather than
paste* a specimen — it came back byte-identical, which is why that step was worth taking. So:

> **derive at load · dump on demand · certify by byte-comparing the DUMP across arms.**

That keeps derived-at-load's unconstructability and buys back both the close-reader step and
fire-twice's byte target, without storing anything that can go stale. It is not a compromise
between the two columns; it is the third column.

⚠ **What it costs, said plainly so it is not sold as free:** §2 has to be rewritten. The file stops
being "generated, idempotent, rewritten whole from the registry" and becomes **hand-owned source**
carrying only what the user wrote. The B0 provenance header survives; "generated-by" does not.

---

## THE ENDPOINT, AND WHY `list()` CONVERTS FOR FREE UNDER IT

Under derive-at-load the user-facing meaning of `code{}` converges back to **action**, for every
rule including grammar rules, and the parse prefix is machinery. `aCTionDefinE` becomes the
generator's front door: receive action code → read the live terms → emit the prefix from the
template table → append the action as tail → compile → bind.

`list` then converts with **no edit to `list`** — its existing body just gains a generated prefix.
Same for `JSONfield`, `JSONarray`, `DelimOver`. The interim exemption of §3(a) is the scaffold, and
the endpoint is where it comes down.

⚠ **One thing the endpoint must not inherit:** under §4's measured finding the action tail is
**already fired by the frame**, so "append the action as tail" is the wrong picture. What the
generator emits is the prefix; the frame keeps firing the action as it does today. Getting this
backwards is how the double-fire arrives.

---

# ADDENDUM 2026-08-12 — THE DISPATCH QUESTION: `processAction` / `runAction` / a new wrapper

Same binary, no rebuild. Fixtures `kpvalue`, `kpwhy`, `kparg` in the session scratchpad; none left
in `incant/`.

## What the certified path already does

`parseViaKant` (`genParse.rtn:1866`) calls **`runAction(rule, action)`**. The layering is
`runAction` → `processAction` → (`processCode` on first fire) → `BlocK.gMethod`. So the question is
not *"which one"* from scratch — it is whether to keep the wrapper `runAction` adds, drop to the
inner call, or add a third.

`runAction` (`GroupActions.rtn:770`) adds exactly four things over `processAction`:
argument binding · **`saveLocalFields`/`restoreLocalFields`, unconditional since SEQ 27 rung B** ·
the jit inline bracket · **rung A's value capture** (`!jitting`).

## ⚠ MEASURED: THE VALUE CHANNEL REPORTS A FALSE **WIN**

Three kant parse bodies over `"["- "]"-`, every row fed `'xx'` — **the terms never match**, so every
row must FAIL. Verdicts read from the frame's own trace line:

| row | body | verdict |
|---|---|---|
| D / I | `return litK(1) AND litK(2);` — the certified spelling | **FAIL** ✅ |
| E | `litK(1) AND litK(2);` — no `return` at all | **FAIL** ✅ (falls off the end → null → `truthOf` false) |
| **F** | `… return nuffin;` — returns an undeclared name | ⚠ **WIN** |
| G | `… return zeroFld;` where `zeroFld=0` | **FAIL** ✅ |
| **H** | `… return emptyFld;` — a declared, **datumless** field | ⚠ **WIN** |

**G and H together locate it.** A field holding `0` correctly reports false, so `truthOf`'s
numeric-by-value rule is working. A **datumless** node reports **true by presence** — which is
`truthOf`'s ruled contract (AND/OR rung, 2026-08-11: *null false · numeric by value · non-numeric
true by presence*), and that contract is exactly right for an action's value and exactly wrong for a
parse verdict.

⚠ **ONE CHANNEL, ONE MEANING, and this is a new member of the family.** `runAction`'s result carries
**"the value the action produced"**; `parseViaKant` reads it as **"did the parse succeed"**. The two
agree on `null` and on numbers and diverge silently on an empty node — and the divergence direction
is a rule reporting a **match it did not make**, at exit 0, with `fireLabelMethod` and `attachLabel`
then firing on it.

**F is the likelier authoring accident than E**, which is what makes it urgent: falling off the end
is safe, and *returning a slot* is not. A generated body is far more likely to end in a `return` of
something than in nothing.

**Rung A's clause 1 predicted this in its own words** — *"setContent already carries the contentless
case (it stamps the tag as the text), so a result with no value reads back the same string it does
today"* — which was correct and deliberate for a return value. Nothing was wrong with rung A; a
second reader arrived with a different question.

## ⚠ MEASURED: A KANT PARSE BODY **CAN** HOLD THE RULE NODE TODAY

`runAction` binds `field["argument"]` from the argument it was handed, and `parseViaKant` hands it
the **rule**. So:

```
    kpScafJ argument code={ print "sees argument tag =" argument.taG:; … };
    ->  kpScafJ sees argument tag = ScafJ
```

**SEQ 54/55's convention — *"holds no node at all"* — is enforced today only by nobody having
written the spelling.** (It is a partial hold: the body can read the rule's identity but still
cannot *index* its terms, which is the SEQ 54 finding that produced the position-taking shims.)
Under minting, `aCTionDefinE` owns the shape, so **minting without an argument slot makes the breach
unconstructable** rather than conventional.

## `processAction` alone would drop the frame bracket, on the worst population for it

The bracket was made **unconditional** on 2026-08-10 because gating it on `recursive` — set at parse
time **by identity** — never fires for **mutual** recursion. A grammar is mutual recursion
throughout: this session's own trace shows
`ExpressioN → Token → TokenXP → InvokeArg → Parens → ExpressioN`. And `parseViaKant` is re-entrant
**by construction** (its own comment): a kant body calls `parseRK`, which calls `parse()`, which
forks straight back in.

**The cost objection does not survive contact.** `saveLocalFields` walks attributes and allocates
per **local** (`isArgument || isLocal`, `!noPrint`) — a convention-conforming parse body has none,
so the bracket is a walk over an empty set. This is free safety, not a trade.

## THE ANSWER

**Keep `runAction`. Add a thin `parseAction` seam whose job is CHANNEL CONVERSION, not dispatch.**

```
parseAction(rule, action)  =  runAction(rule, action)  +  verdict conversion at the seam
```

and the conversion **REFUSES rather than substitutes**: a parse method must yield a node carrying
data; a datumless result is a loud diagnostic and a FAIL, never a silent WIN.

Three reasons refusal is the right shape here, all citations rather than taste:
- the AND/OR rung's companion rule — *"make the emit-side gate a **REFUSAL** rather than a
  fall-through — a refusal is counted by every rung's degrade-zero assertion; a fold is counted by
  nothing"*;
- the idiom already exists **in the same file**: `parseRuleMethod` (`genParse.rtn:1646`) refuses
  loudly on a `parseTerms` mismatch, and GM-30 turned that refusal into a free no-rebuild
  instrument;
- `jitPrintItem`'s precedent — *"refuse rather than substitute"*, because a substituted constant is
  asserted by nothing.

**And it makes the defect unconstructable in generated code**: if the emitter only ever emits
`return <chain>;`, F and H cannot be written by the generator at all. The refusal is then a guard on
hand-written bodies and on emitter bugs — which is where it belongs.

## WHAT THIS ASKS OF `aCTionDefinE`'s MINT — three things, all free now and impossible later

1. **Mint `kp<Tag>` with NO `argument` attribute.** Closes the measured node-holding hole
   structurally. (Only reachable via the mint; a convention cannot enforce it.)
2. **Mint it NOT `isRule`.** `processAction` carries a rule-action mode (`GroupActions.rtn:552-559`)
   that binds the CodE's attributes to the label's children **by name** — the `list` / `JSONfield`
   semantics. It is gated on `isRule`, so a non-rule mint makes that branch unreachable and keeps
   position-naming the only way a body can name a term.
3. **Bind `rStuff.parseMethod = parseViaKant`, and leave `parseViaKant` unedited** — it finds
   `kp<Tag>` by `locate`, so hanging the CodE on the minted name is the whole of duty (b).

⚠ **`isCoded` IS CONSUMED BY RUNNING, so the mint must not be validated with it.** `processCode`
sets `isAction = true` and consumes `isCoded` on the first fire; `parseViaKant`'s guard is already
written as `!action.isCoded && !action.getAttribute("BlocK")` for exactly this reason, and a rule
parses many times. Any check `aCTionDefinE` adds about *"does this carry a body"* inherits the same
trap (bear-trap #25).

---

# ADDENDUM 2026-08-12 (b) — THE `label=Rule` SINGULAR ASK

Same binary, no rebuild. Fixtures `lblfork`, `lblname`, `lbliso` in the session scratchpad.
⚠ **Two of the ASK's four items came back FALSIFIED**, and the spec target moves out of
`checkInput()`. Read items 2 and 4 before acting on item 3.

## 1. THE CENSUS — Tony's cursory inspection is CONFIRMED, and now for a stated reason

**Scope of the match, said before the number:** every `ident[mods]=RHS` occurrence in
`incant/grammar` with block comments stripped, classified on three axes — **position** (definition
HEAD vs term inside another rule's sequence), **kind** (rule reference / literal / charset), and
**multiplicity** (trailing `+`/`*`). 30 occurrences: 12 HEAD, 18 term-level.

**Term-level, rule-reference, singular — the gap cell — is 3 hits, and 2 are false positives**
(read by eye, H9, because the classification is the finding):

| line | hit | verdict |
|---|---|---|
| 17 | `parseAction=processFlags` | ❌ **command attribute**, not a labelled term (`parseAction` is registered `immediateAction=setRuleAction`). Same family as `ruleMethod=`, `parseMethod=`, `parseTerms=` |
| 53 | `ruleMethod=aCTionIF` | ❌ same |
| **23** | **`formatWIDTH?=NumbeR` in `FormaT`** | ✅ **the only genuine instance in the grammar** |

**Blast radius of the singular change: ONE term.** Multiples for contrast — `stuff=PrintXP+` (×4),
`rules?=NamE+`, `scopeList=ScopeField+`, `precision=counter*`, `flags=[…]*`, `value-=[…]+`.

⚠ **The adjacent population the census also turned up, flagged not scoped:** three **HEAD-position**
singular rule references — `followedBy<^-=notInNameSet` (:7), `ANYtoken=NamE` (:14),
`Looper=ANYtoken` (:47). Same *shape* one level up (a rule whose whole body is one rule reference).
Whether a `checkInput`/`attachLabel` change touches them is a **blast-radius question to answer, not
an assumption to carry** — and `Looper` already has a recorded naming collision (project memory:
*"the carried attr is tagged `Looper` … but the local stays lowercase `looper`"*).

## 2. ⚠ THE FORK — ITEM 2's EXPECTED SHAPE IS FALSIFIED. NEITHER PATH DROPS THE LABEL.

The ASK predicts *"the multiple path keeps the explicit label; the singular path drops it at the
derivation branch."* Four spellings over one referenced rule, input `[a]`, read off `parseTrace`:

| row | spelling | trace |
|---|---|---|
| **S** | `wanted?=ScafA` singular **labelled** | `fireLabelMethod ScafA` → `attachLabel lab=ScafA promote=1 **isTarget=1** pLabel=1 **pRule=wanted**` → `fireLabelMethod **wanted**` → `attachLabel lab=wanted … pRule=ScafS` |
| Sx | `ScafA?` singular unlabelled | `attachLabel lab=ScafA promote=1 isTarget=0 pLabel=1 pRule=ScafSx` |
| **M** | `wanted=ScafA+` multiple **labelled** | `attachLabel lab=ScafA promote=1 **isTarget=0** pLabel=1 **pRule=wanted**` → `fireLabelMethod **wanted**` → `attachLabel lab=wanted … pRule=ScafM` |
| Mx | `ScafA+` unlabelled | `attachLabel lab=ScafA promote=1 isTarget=0 pLabel=1 pRule=ScafMx` |

**`fireLabelMethod wanted` fires in BOTH S and M**, and `pRule=wanted` in both — so the term node's
identity **is** the explicit label, and `checkInput()`'s `label = new(tag)` (`RuleStuff.twk:181-186`)
mints it correctly on **both** paths. **The singular path does not drop the explicit label and does
not consult a derivation branch that ignores one.**

**The only difference between S and M in the whole trace is one flag: `isTarget=1` vs `isTarget=0`.**
`getWhatFollows` (`RuleStuff.twk:222`) sets it on an embedded term when **`max == 1`** — i.e.
*singularity itself* is what raises it.

## 3. ⚠ THE SYMPTOM IS REAL, AND IT IS NARROWER THAN THE ASK ASSUMES

The gap shows up not in the tree shape but in **by-name addressability from a consumer** — a coded
rule, whose body is bound from the label's children by name (`processAction`,
`GroupActions.rtn:552-559`). Six spellings, same referenced rule, same input:

| spelling | kind | multiplicity | by-name lookup |
|---|---|---|---|
| `want=ScafA` | rule reference | singular | ⚠ **ABSENT** |
| `want?=ScafA` | rule reference | singular | ⚠ **ABSENT** |
| `want?=ScafA+` | rule reference | MULTIPLE | **PRESENT** (yields the container, prints `want`) |
| `want="a"` | literal | singular | **PRESENT** (yields the value, prints `a`) |
| `want=[a-z]` | charset | singular | **PRESENT** (prints `a`) |
| `want=[a-z]+` | charset | MULTIPLE | **PRESENT** (prints `a`) |

**Two things fall out, both narrowing the job:**
- ⚠ **THE `?` IS IRRELEVANT.** `want=ScafA` and `want?=ScafA` behave identically. Optionality is not
  the fork; **singularity** is.
- ⚠ **THE DARK CELL IS EXACTLY ONE: singular × rule-reference.** Literals and charsets are
  addressable at every multiplicity. So the gap is not *"the singular path"* — it is
  *"a singular rule reference"*, which is precisely `formatWIDTH?=NumbeR` and nothing else.

## 4. ⚠ ITEM 4's PRECEDENT IS FALSIFIED — THE TRANSPARENCY BEING CITED DOES NOT EXIST

The ASK asks for one row confirming that *"consumers can't distinguish explicit from derived
container labels"* in the working multiple case, because **the singular fix is to inherit that
shape**. Measured, it is the opposite:

| | labelled | unlabelled |
|---|---|---|
| multiple | `wanted` **PRESENT** | `ScafA` **ABSENT** |
| singular | `wanted` **ABSENT** | `ScafA` **ABSENT** |

**A consumer can tell exactly which way a multiple's label was born**, because only the explicit
one is addressable at all. So the acceptance test as written — *"a labelled singular relates to an
unlabelled singular exactly as labelled/unlabelled multiples already relate"* — is currently
satisfied by **doing nothing**: both singular cells are ABSENT, and both `unlabelled` cells are
ABSENT, so the two rows already "relate" identically. **The test cannot fail, and therefore cannot
pass meaningfully.** It needs restating against the property actually wanted, which is
*addressability*, not *indistinguishability*.

**This is exactly why item 4 said measure rather than assume**, and it paid.

## 5. THE SPEC — AND THE TARGET IS NOT `checkInput()`

`checkInput()` already honours the explicit label (§2). The divergence is downstream, at the
**`isTarget` promotion in `attachLabel`** (`GroupItem.twk:1093-1096`):

```
    if promote && stuff.isTarget {
        pStuff.label    = lab;
        lab.tag         = pStuff.ruleName;
        return; }
```

Only the singular takes this case (`isTarget` ⇐ `max == 1`), and it is the one case that **replaces**
the parent's label rather than attaching under it. That is the candidate site, and it is supported
by the flag diff being the *only* difference in the trace.

⚠ **THE MECHANISM IS NOT ESTABLISHED, AND IS NOT WRITTEN HERE AS IF IT WERE.** Structural claims on
this project hold; causal ones are a coin flip until run. What is measured: the symptom's exact
cell, the `?`-independence, and that the flag diff is the sole trace difference. What is **not**
measured: whether the promoted node is absent from the tree or present-but-unfindable. **That is
one probe** — walk the label's children instead of asking for one by name — and it is **owed**;
two spellings were tried (`for g in this;` → `ERROR processCode: R1 parse failed`) and the attempt
was stopped at two rather than ground on. **Do not write the spec's fix line until that probe
runs**, because "mint it differently" and "attach it differently" are different repairs and the
probe is what separates them.

## 6. ⚠ THE ADJACENCY FLAG IS NOT ADJACENCY — IT IS IDENTITY

The ASK flags label plumbing as *adjacent*, and asks that a surprise near this work not be read as a
regression from it. **It is closer than that: the candidate site IS the banked Parens red's site.**
GM-29 names `attachLabel`'s promote/no-label pair as the mechanism, and the case above is the same
three lines. Two consequences the spec must carry:

- **`promote` has a NAMED EXPIRY.** IT-3 (director, 2026-08-07, recorded in `attachLabel`'s own
  header) retires `isTarget` promotion as a parse-layer mechanism entirely — *"when the last carrier
  converts, `promote` and the isTarget case DELETE, three cases become one."* A fix that adds a
  **fourth** consumer of the promote case moves against a standing end state. That is a ruling to
  take deliberately, not a side effect to discover.
- **PC-1 forbids the generated arm consulting `isTarget`**, which is why GM-29's own one-line
  candidate — measured green, whole fleet at footprint — **was not landed**. Any repair here inherits
  that constraint.

**Sequencing, revised:** the ASK's *"independent, gates nothing in flight"* holds for
`aCTionDefinE` and the amendment file — confirmed, no overlap. It does **not** hold for GM-29/IT-3,
which now share the site. **Tony's nod on the spec should be a nod on the promote-case question, not
just on the singular fix.**

---

# ADDENDUM 2026-08-12 (c) — THE OWED PROBE. Hypothesis falsified; the repair relocates AGAIN.

Same binary, no rebuild. Fixtures `lblprobe`, `lblprobe2`, `lblboth` in the session scratchpad.

## 0. PRECONDITION — the dark cell WAS measured on matched input

`R1 isRule "["- want=ScafA "]"-` carries **no `?`**, was fed `'[a]'`, and **its action ran**. A rule
with a mandatory term cannot succeed unless that term matched. So the ABSENT is not Tony's
presence-gating working correctly, and the thread does not close here.

## 1. ⚠ §3's HYPOTHESIS IS FALSIFIED, AND TWICE OVER

The hypothesis: `lab.tag = pStuff.ruleName` clobbers the explicit label with the **enclosing rule's**
name, so the label promotes correctly and is renamed on the way up. Predicted probe result: *the tag
reads as the rule name.*

**It reads as the explicit label.** The trace already on disk says so in two adjacent lines:

```
    attachLabel lab=ScafA  promote=1 isTarget=1 pLabel=1 pRule=wanted
    attachLabel lab=wanted promote=1 isTarget=0 pLabel=1 pRule=ScafS
```

`pRule=` prints `pStuff.ruleName`, and at the promote site it is **`wanted`** — the *term's own
name*, not the enclosing `ScafS`. So `lab.tag = pStuff.ruleName` **honours** the explicit label; the
next line reads `lab=wanted`, which is the renamed node wearing the right name.

**Consequences, stated rather than bent:** the repair species is **not** retag-precedence — there is
nothing to retag. And the *"this simplifies toward IT-3 rather than adding a fourth consumer"*
argument does not apply, because no change to the promote case is indicated at all.

## 2. THE PROBE ANSWER — a THIRD outcome, not either of §2's two

§2 offered *present-but-wearing-the-wrong-name* or *absent-from-tree*. Measured: **present, and
wearing exactly the right name**, in the dark cell *and* the control.

`lblprobe2` — the walk, with **no actions** on the inner rules so nothing can replace a label:

```
=== OUT1: dark cell.  input [(a)]  (P1 isRule "("- want=ScafA  ")"-) ===
     P1 label has a list. children:
        child: want                       <- the dark cell CARRIES want
=== OUT3: control.    input {<a>}  (P3 isRule "<"- want=ScafA+ ">"-) ===
     P3 label has a list. children:
        child: want
```

## 3. ⚠ TONY'S CONTRACT IS ALREADY SATISFIED BY THE PARSE LAYER

> *"If isTarget is in effect then NumbeR's label IS formatWIDTH's label."*

Measured: **yes, exactly.** The promote case does `pStuff.label = lab` and stamps it with the term's
own name, and the walk finds the result under the enclosing label wearing `want`. The parse layer
builds the tree the contract asks for, in **both** cells.

## 4. SO THE DEFECT IS IN THE CONSUMER BINDING, NOT THE PARSE LAYER

`lblboth` puts both views in **one run** — each inner rule asks for its own term by name, on the
same input shapes:

| cell | spelling | the rule's own action |
|---|---|---|
| dark | `want=ScafA` singular ruleref | **`want` ABSENT by name** |
| control | `want=ScafA+` multiple ruleref | **`want` PRESENT by name** |

Join with §2: **the tree carries `want` in both cells, and only one of the two consumers can reach
it.** The failing lookup is `processAction`'s binding loop — `if grup = label[result.tag]`,
`GroupActions.rtn:552-559` — which walks the CodE's attributes and resolves each against the label.

⚠ **THE JOIN'S BASIS, since the two probes are different fixtures.** It rests on the label the
action *receives* being the actionless tree, which is **pointable rather than inferred**:
`fireLabelMethod` does `stuff.label = method(stuff.label)` — the argument is what the action sees,
and the replacement happens on the way out.

⚠ **AND THE MECHANISM OF THE LOOKUP FAILURE IS NOT ESTABLISHED.** Why `label["want"]` resolves over
a `+%`-attached container and not over a promoted-and-renamed node is the **next** probe, not this
one. Candidate worth one grep — affiliation: the promote case installs by assignment
(`pStuff.label = lab`) and the multiple case by `+%`, and `[]` may not search both kinds. **Offered
as a lead, not a diagnosis.**

## 5. ⚠ THIS INVERTS §6's SEQUENCING CONCLUSION — IN THE GOOD DIRECTION

My previous addendum put the repair on `attachLabel`'s promote case and therefore in collision with
GM-29 and IT-3. **On the probe's evidence it is not there.** If the repair is in the consumer
binding then it:
- **does not touch `attachLabel`**, so it adds **no fourth consumer** of the promote case;
- **does not make the generated arm consult `isTarget`**, so **PC-1 is not engaged**;
- **does not move against IT-3's end state**, which deletes promotion as a *parse-layer* mechanism
  and says nothing about how a consumer resolves a name.

**So the promote-case question becomes informational rather than gating.** ⚠ Held deliberately:
**no fix line, per the standing condition** — the lookup mechanism is unestablished, and "mint it
differently", "attach it differently" and "resolve it differently" are three repairs, of which the
probe has only excluded the first two.

## 6. INCIDENTAL, FOUND AS A CONFOUND AND WORTH FILING

**A rule action whose last statement is an `if`/`else` silently REPLACES its own label with `true`.**
`fireLabelMethod`'s `stuff.label = method(stuff.label)` takes the body's yielded value, and an
`if`/`else` yields `trueResult`. In `lblboth` this turned every P1/P3 label into a node tagged
`true`, which is why that fixture's walk rows are absent and its stderr carries
`nextGroup: ERROR true does not contain a list` twice. **The action reported correctly and destroyed
the tree underneath it on the way out**, at exit 0.

Same family as bear-trap #22 (an action damaging its own parse-tree nodes) and as the standing
`fireLabelMethod` note that *"14 of 33 rule actions return a node they were not handed"*. Filed, not
fixed. ⚠ **Read it before writing any rule action that ends in a conditional** — including a kant
parse body, where the same shape would hand the verdict to the label channel.

---

# ⚠ CLOSED 2026-08-12 — TONY'S RULING. The label-affiliation thread is PARKED BY DESIGN, not left dangling.

**Label components are always attributes — a design invariant, stated by Tony.** The promoted
singular violates it at **one install site**, with **one live grammar instance**
(`formatWIDTH?=NumbeR`). Everything else in addendum (c) stands: the parse layer honours the
contract completely, and the tree carries `want` correctly named in both cells.

**Affiliation-filtered access operators already exist** for authors who need to choose — `=/`
(`opGetMember`) and `=%` (`opGetAttribute`). **For labels nobody should have to choose**, which is
why `[]` works everywhere else and why the deviation is a deviation rather than a spelling.

**Repair-if-ever: conform the INSTALL** — a promoted component arrives as an **attribute**, like
every other label component. ⚠ **NOT a consumer respell, NOT operator widening, NOT anything in
`attachLabel`'s promote case.** So addendum (c) §5 stands and is now ruled: the promote-case
question was informational, and it is answered by not being the site.

**No repair scheduled. Gates nothing.** Filed in the **known-deviations family**
(divergence-ledger species): **held open knowingly, by name.**

The `if`/`else` label-clobber incidental (addendum (c) §6) **stays filed as written** — no action —
and it now has two forward customers: the `parseAction` verdict-channel rationale, and the eventual
emitter's *"a body ends in return-of-chain"* structural guard.

---

# ADDENDUM 2026-08-12 (d) — THE FULL-MONTY GO: two blockers, and the tail spelling measured

Same binary (1386720 bytes, mtime 2026-08-11 18:07). **No edit was made to any tracked file.**
Fixtures `tailtest`…`tailtest4` in the session scratchpad.

## 0. BASELINES CAPTURED BEFORE ANYTHING — per §3, and they match the seal

| fixture | result | seal says |
|---|---|---|
| `oneTest` | exit 0, `maximus = 11` then **26 ×4**, 301 lines | 11 / 26×4 ✅ |
| `jsonTest` | exit 0, **13 `ok :` rows**, stderr empty | 13 ok ✅ |

Stored in the scratchpad's `baseline/`. **They are the before-picture for the `incant/setup` edit
(c) would make** — `setup` is loaded by every fixture preamble, so that edit is the one with fleet
reach.

## 1. ⚠ BLOCKER ONE — THERE IS NO `aCTionDefinE` DRAFT

`grep -H '^STATUS:' ipc/*.md`: `clay-to-clod.md` is **CLEARED**, last entry **SEQ 55** (the 08-11
seal). Nothing has arrived. §1(a) is *"TONY'S DRAFT → Clod reviews, implements"*, and (b) and (c)
both gate on it.

**And (b)+(c) landing without (a) would be VACUOUS, not merely early** — measured, not assumed:
`aCTionBraced` exists as a C++ extern (`ruleActions.rtn:97`, live in the binary as `_aCTionBraced`),
so `Braced` carries **`isMethod=1`** (trace: `fireLabelMethod Braced isMethod=1 label=1`). Per M1b,
`ruleActions.rtn:348` gates method binding on `if !isREGISTRY && !isMethod` — so
**`Braced code={…}` attaches a CodE that nothing reads.** Including the file, registering it, and
running would produce a clean green fleet **because nothing happened**. That is GM-30's `InvokE`
result exactly: *"installed clean with the entire fleet byte-identical — which is what a rule that
never runs also produces."*

⚠ **Two things in §1(a) need Tony's word before anyone implements them, and guessing either is the
expensive kind of wrong:**
- **The scope of "dlsym-into-method DELETED."** Read unconditionally it removes every grammar
  rule's C++ action binding — `aCTionIF`, `aCTionFOR`, `aCTionExpressioN` — and the system stops.
  The sentence *"the method slot stays EMPTY **for kant-doored rules**"* implies the scoped reading,
  which is surely what is meant, but the deletion is at a shared site and the scoping is the whole
  content of the change.
- **What the tail calls THROUGH once the slot is empty.** §1(a) empties `method` so `:1230`'s fire
  goes vacuous, and §1(b) has the body call the C++ action. Those are consistent only if the tail
  reaches the action by some route other than the method slot — an explicit `dlsym` in the shim, or
  a pointer stashed at mint time. **Both are fine; neither is chosen.**

## 2. ⚠ BLOCKER TWO — BOTH OFFERED TAIL SPELLINGS ARE UNSOUND. Measured, with a negative control.

§1(b) asks which spelling is honest. **Neither, and the reason is structural.**

**(i) A bare extern call from a kant body does not dispatch — and looks exactly like success.**

| row | body | result |
|---|---|---|
| unregistered | `aCTionBraced();` | prints "returned", **exit 0, no diagnostic** |
| **negative control** | `aCTionNOSUCHatALL();` | prints "returned", **exit 0, no diagnostic** |

**A name that cannot exist behaves identically**, so the first row measured nothing. H7, and it would
have gone into the record as *"the tail call works."*

**(ii) Registered, it dispatches — and then reports TRUE unconditionally.** `aCTionBraced` is
`input.clear(); input.group = ExpressioN; input.fLAG = true; return input;` — it hands back a
**datumless** node. Same call, two readings, one run:

```
    A  bare if aCTionBraced()                  -> FALSE
    B  if traceParse() AND aCTionBraced()      -> TRUE
```

⚠ **This is the bare-`if` truthiness fork** — named UNRULED in the 08-11 seal, with *"zero live
customers"* — **landing on the proposed spelling.** `… AND aCTionBraced()` reads **TRUE whatever the
action did**, because the AND contract reads a present non-numeric node as true. The tail would be a
verdict-neutral no-op that always says success, composed with addendum (a)'s false-WIN mechanism.
**The rung's own instrument would be the thing that lies.**

**(iii) And the statement-after-the-gate spelling does not escape it**, because the real problem is
underneath both: **the action needs the LABEL, and the convention says the body holds no node.** A
bare call hands `aCTionBraced` whatever the command dispatch supplies — and since the first thing it
does is **`input.clear()`**, it *clears the wrong node*. That is bear-trap #22's family: an action
destructively mutating something it was not handed.

## 3. THE HONEST SPELLING IS A FRAME-SIDE SHIM — the `actK()` priced on 2026-08-12

The frame already holds `gKantLabel` and `gKantRule`. A zero-argument `actK()` does inside the chain
what `fireLabelMethod` does outside it, and it is the only spelling that satisfies all three
constraints at once: **the body names no node** (convention), **the action receives the label**
(correctness), and **the verdict is the shim's, not the action's return** (addendum (a)).

⚠ **And it is one fire site by construction only if §1(a)'s deletion lands with it** — otherwise
`:1230` fires the action too and the tail is the second fire. **The two halves of §1(a) and §1(b)
are a single change; landing either alone is worse than landing neither**, which is the AND/OR
rung's finding 1 (*"a partial landing of a two-arm change can be worse than not starting"*).

## 4. DISPOSITION — STOPPED, NOTHING EDITED

No tracked file was touched; `incant/` is unchanged; the fleet has not moved. The stashed
`parseCode` gains `parseTerms=3` (unambiguous and ruled) and carries the tail question inline
pending the ruling. **The POP was not run, because a POP on an inert install is a vacuous green and
reporting one would be worse than reporting nothing.**

---

# ADDENDUM 2026-08-12 (e) — THE FULL-MONTY RUN: **THE FOURTH THING**, and §6's revert taken

**Built and run.** tok bare (bear-trap #23's normal-build side), extern canary **270 → 273**
(actK, kantDoor, kantDoored — no cascade), two clean builds, binary echoed at every step (H1).

## 1. WHAT WAS BUILT

- **`actK`** (`genParse.rtn`) — the tail shim, third of the litK/parseRK family. Zero information
  from the body; frame supplies label and rule; **verdict owned by the shim**; loud refusal when the
  symbol is absent. **Route: dlsym at call time**, priced against a pointer stashed at mint — the
  stash needs actK to find the mint anyway, adds a field with one reader, and **step 2 deletes the
  question**. Cheap-to-remove beat cheap-to-run.
- **`kantDoor` / `kantDoored`** — the three duties lifted out of `aCTionDefinE` so its hunk is three
  lines and the revert is one.
- **`aCTionDefinE` reorder** — `isCoded` above the dlsym arm, `!isMethod` left on the dlsym arm only.
- **`groups.ext`** gained two prototypes. ⚠ **Out-of-repo build dependency (bear-trap #11); it will
  not appear in a Groups `git status`.** Backup of the pre-edit file is in the session scratchpad.

## 2. ⚠ THREE THINGS THE ORDER'S SKELETON DID NOT COVER, all measured

1. **The `isCoded` arm cannot live under `!isMethod`.** Braced already carries `isMethod` from its
   original definition, so a `code{}` re-definition never reaches the block — M1b's silent inertness,
   mechanically this guard. The test had to move above it.
2. **"The method slot stays empty" needs an ACTIVE CLEAR.** Braced arrives with `gMethod` already
   set. Not-binding is not enough; the door must clear `gMethod`/`isMethod`/`immediateACTION`.
   **Measured working:** the trace reads `fireLabelMethod Braced isMethod=0`.
3. **The scoping is a real conditional, not an ordering consequence.** A bare `if isCoded` would
   also capture `list`, `JSONfield`, `JSONarray`, `DelimOver` — two of them in `incant/utilities`,
   which every preamble includes. The ratified `registry.isRule` test was kept.

**And one in the file, not the code: ⚠ THE `define` WRAPPER IS REQUIRED.** A bare top-level
`Braced code={…};` is read as a RunRulE invocation and rejected —
`RunRulE: expected a method not code` — which **abandons the rest of the file at exit 0**, zero
stdout, no sentinel. **VOID by the pre-registration, and correctly caught by it.**
⚠ **This corrects my own M2:** that fixture carried a `define` wrapper, so it verified merging from
outside the **registry**, never the bare form. I reported it as verifying §2's "no define wrapper".
It did not.

## 3. ⚠ THE RESULT: THE FOURTH THING. **The clear lands; the bind does not.**

| what | evidence |
|---|---|
| `kantDoor` runs, bounds pass | `kantDoor: Braced -> kpBraced via parseViaKant, 3 terms` |
| install alone is clean | a fixture that installs and never uses the door: **exit 0, sentinel present** |
| the method-slot clear TAKES | `fireLabelMethod Braced isMethod=0` — was `isMethod=1` |
| **the parseMethod bind does NOT take** | **`parseViaKant Braced` appears ZERO times**, and `attachLabel lab=Braced promote=1` — **`promote=1` is the INTERPRETED arm** |
| consequence | nothing builds the Braced result, `sumple[width]` yields null, and the consumer dereferences it: **SIGSEGV, `setContent(this=0x0)`** |

**So the change disables Braced without replacing it.** Not red-matching-the-oracle, not green,
and the crash makes it **VOID** — the fourth thing §6 names.

**Bisected with no rebuild, which is the kant path's own cheapness paying off:** the body was cut
back to `litK(1)` alone and to two-`litK` and three-term forms, all by editing `incant/parseCode`
as runtime data. **All four crash identically**, so it is not the shims, not `parseRK`, not `actK`
— it is the dispatch never arriving.

**Two spellings of the bind were tried and both failed the same way:** the raw `rStuff` field, and
`getRStuff()` — the latter chosen because `parseRuleMethod`, the *working* `parseMethod=` door, has
always used it. Copying the working door was not sufficient.

⚠ **THE LEAD, OFFERED AS A LEAD AND NOT A DIAGNOSIS** (standing causal-claim asymmetry):
`parse()` forks on **`definingRule().rStuff.parseMethod`**. `kantDoor` binds onto the node
`aCTionDefinE` hands it, which for a **re-definition** is the merged node — and that may not be the
node `definingRule()` resolves to at parse time. **Note this is the same shape as the label thread's
finding**: the merge lands on one node and the consumer reads another. Worth one probe before any
further build: print the two rStuff addresses at bind time and at fork time.

## 4. DISPOSITION — §6's REVERT LINE TAKEN, VERIFIED

Reverted: the **`aCTionDefinE` hunk** and the **`incant/setup` fILEs registration** (`git checkout`,
both tracked). Kept: **`actK`**, its two siblings (uncalled now, and the next rung's material), the
`groups.ext` prototypes, this document, and `incant/parseCode` — **unregistered, so nothing loads
it**. `incant/bracedK` moved to the scratchpad.

**Fleet verified back to the mark, after retok and rebuild:** `oneTest` and `jsonTest`
**byte-identical on BOTH streams** against the baselines banked before the first edit; `bracedT`,
the C++ oracle, still green. **The fleet count did not move** — `parseCode` is unregistered and
carries no `Start()`, so `completePop` does not sweep it; `bracedT` is the only new swept fixture,
and it was landed at Tony's request in the previous turn.

---

# ⚠ ADDENDUM 2026-08-12 (f) — SHUTDOWN PROBE. **THE KANT DOOR IS NOT THE DEFECT.**

Two runs, no rebuild, taken at shutdown against tomorrow's parked bench order. **They re-aim it.**

## THE MEASUREMENT

The **existing, known-working `parseMethod=` door** — the one `parseRuleMethod` implements and that
`incant/kantParse1` and `incant/genScratch` bind through successfully — was pointed at a
**re-definition of `Braced`** from a fixture, with `kantDoor` nowhere in the picture:

```
    define  Braced parseTerms=3 parseMethod=parseViaKant;  ;
```

| question | answer |
|---|---|
| does the run survive? | **exit 0, sentinel, `sumple width is now 251`** — the C++ arm answered |
| does `parseViaKant` fire? | ⚠ **ZERO times** |
| are the attributes consumed, or absorbed as terms? | **consumed** — Braced reads **3 terms before and 3 after**, so `incant/setup:52-58`'s "3 terms became 5" hazard is NOT in play |
| does `parseRuleMethod` actually run? | **yes** — a deliberately bogus `parseTerms=99` bind printed `REFUSING ... rule now has 3`, twice, before and after |
| therefore, on the real bind | it did **not** refuse ⇒ the count matched ⇒ **`setParseMethod` was called and returned** |

## ⚠ WHAT IT MEANS: THE BIND IS WRITTEN AND NEVER READ — AND IT PREDATES TODAY'S CODE

`kantDoor` was not in this probe. **The same failure reproduces through the door that already
works.** So:

- **The defect is NOT in `kantDoor`, `actK`, the mint, the reorder, or anything built today.** The
  three duties may well be right; they were never given a chance to be wrong.
- **It is in re-definition binding generally**: `parseMethod=` applied to a rule defined
  **elsewhere** (Braced lives in `incant/grammar`, loaded at setup) writes a `parseMethod` that
  `parse()`'s `definingRule().rStuff.parseMethod` fork does not read.
- **The discriminator is same-definition vs cross-file re-definition.** Every binding that works
  today — `kantParse1`, `genScratch`, the Scaf family — binds a rule **defined in the same define
  block**. Nobody had ever bound one from another file.

## CONSEQUENCES FOR THE PARKED BENCH ORDER

- **§0's premise moves.** "The kant Braced path is in it-don't-work-fix-it mode" is true, but the
  broken part is not the kant path. The bench as specced would isolate a mechanism that is not the
  faulty one and could certify it green while Braced still does not parse.
- **§3a's two-node probe is still the right first move**, but its subject is `parseRuleMethod`
  versus `parse()`'s fork — **not `kantDoor`**. Same three outcomes, different patient.
- **A cheaper first run exists and needs no kant anything:** bind a **generated C++** method
  (`parseMethod=parseBraced`) to Braced by re-definition from a fixture. If that also fails to fire,
  the defect is confirmed orthogonal to kant and the whole investigation moves off this campaign's
  critical path.
- ⚠ **§3d's breakpoint discriminator needs one word changed.** It asks that **`:1251`** stay
  silent. `:1251` is the **interpreted** arm's fire; once the door works, `parse()` forks at
  `:1219` and never reaches the match loop, so `:1251` is silent **by construction** and asserts
  nothing. The discriminating site is **`:1230`**, the generated arm's fire, which the method-slot
  clear is supposed to starve. An assertion that cannot fail is the thing this fleet's rules exist
  to prevent.

## §1's PRICING CALL, ANSWERED SO TOMORROW DOES NOT SPEND ON IT

**Fixture-local `fILEs` entry plus `include`, not inline `code{}`.** Three reasons:
- it exercises **the real artifact**, and an inline copy drifts from `incant/parseCode` the moment
  one is edited and the other is not — §2's own anti-drift rule, applied to the file as well as the
  duties;
- it keeps the **runtime-data bisect** working on the shipping file, which is what made yesterday's
  four-body bisect cost zero rebuilds;
- **promotion in §4a becomes a one-line move** — the same `fILEs` line relocates from the fixture to
  `incant/setup`, so the promotion diff is exactly the thing being promoted and nothing else.

A fixture-local `registry(fILEs); define parseCode File='incant/parseCode'; ;` touches no shared
file, so the bench's blast radius stays at one fixture.

---

# ADDENDUM 2026-08-13 (g) — SEQ 56: THE ARM REORDER, REDONE STANDALONE AND **LANDED**

**asOf 2026-08-13 · binary `~/bin/incant` → DerivedData Debug/Groups, 1387072 bytes, mtime
2026-08-13 08:23 (rebuilt for this change) · before-binary was the same size at mtime
2026-08-12 16:49, the post-revert build of addendum (e)**

Tony's standing order: **fix forward, do not revert.** (e)'s hunk was reverted whole because the
kant door crashed; the *dispatch reorder* inside it was never the thing that failed, so it comes
back on its own.

## 1. WHAT LANDED — two lines, and nothing else from (e)

`ruleActions.rtn`, `aCTionDefinE`. Before / after:

```
    if !isREGISTRY && !isMethod {                if !isREGISTRY {
        String methodName = "aCTion" tag;            if isCoded     method = processAction;
        void*  methodAddress;                        or !isMethod {
        if methodAddress = dlsym(...)                    String methodName = "aCTion" tag;
            gMethod = methodAddress;                     void*  methodAddress;
        or isCoded  method = processAction;              if methodAddress = dlsym(...)
        free(methodName);                                    gMethod = methodAddress;
        if gMethod {                                     free(methodName);
            isMethod = true;                             if gMethod {
            immediateACTION = true; }}                       isMethod = true;
                                                             immediateACTION = true; }}}
```

**`!isREGISTRY` stays on BOTH arms** — it is not the guard the order names, and leaving it in place
keeps a coded registry doing exactly what it did yesterday. **`!isMethod` moved to the dlsym arm
alone**, which is (e) §2 item 1 carried over: a `code={}` re-definition of a rule already carrying
`isMethod` never reaches a guarded arm, and that is M1b's silent inertness *mechanically*.

**Deliberately NOT brought back**, per the order — they gate on the bind-defect investigation (f):
no `kantDoor` call, no method-slot clear, no `registry.isRule` scoping, no `fILEs` registration.
The scoping was needed in (e) because the arm routed to the door; here it routes to
`processAction`, which is where the four pure-kant coded rules already landed.

## 2. THE PRE-MEASURE — taken, one command, and it names the whole collision set

The order only discriminates for a rule that is **both coded and dlsym-resolvable**. Censused
before building, with a positive control so the grep cannot pass by finding nothing:

| what | result |
|---|---|
| `aCTion*` symbols in the binary | **34** |
| positive control (`aCTionParens`, `aCTionBlocK`) | both present — the pattern matches something |
| `aCTionlist` · `aCTionJSONfield` · `aCTionJSONarray` · `aCTionDelimOver` | **none exist** |
| the 34 tags cross-matched against every `code=`/`code{` rule definition in `incant/`, `*.rtn`, `*.twk` | **one hit: `incant/parseCode:39` `Braced code={`** |
| is that hit live? | **no** — `parseCode` appears in no `File=` line of `incant/setup`'s `fILEs`, so `include` cannot reach it |

**So the predicted fleet outcome was outcome 1, and it is what happened.**

## 3. VERIFICATION — the ladder, in order

- baselines captured **before any edit**, both streams **split** *and* merged, so the after-capture
  is like-for-like on each channel separately (the 08-11 instrument lesson);
- edit → **`tok GroupRules.twk`, bare** (bear-trap #23's normal-build side — no `groupDirectives`);
- **extern canary `grep -c '^extern' GroupRules.h` = 273 before and 273 after.** Unmoved, as
  predicted: this change adds no symbol;
- generated `.mm` read by eye at `GroupRules.mm:605-626` — the reorder is exactly the intended
  shape, `setMethod(::processAction)` first, the dlsym block under `!isMethod`;
- rebuilt (TOK.xcodeproj, Groups scheme, `BUILD SUCCEEDED`); **`GroupRules.o` and the product both
  stamped 08:23**, so the change is demonstrably in the binary that ran;
- binary echoed at every step (H1).

### The fleet diff — BYTE-IDENTICAL, on every stream

| stream | before vs after |
|---|---|
| `oneTest` stdout · stderr · merged | **identical** |
| `jsonTest` stdout · stderr · merged | **identical** |
| `genLadder/pop.sh` whole log | **identical** apart from the two `git status` lines naming this change's own files |

`oneTest` still reads **11 then 26 ×4**; `jsonTest` still **13 ok**. Both exit 0.

**The fleet was already red at the mark, and this is a finding, not this change's:** `pop.sh`
reports **33 green / 1 parked / 3 FAIL** identically before and after — `census.target` (`MemberS`
now refuses where the target holds a `SEQ`), `iterT1m` plus its refusal count 4-want-7, and the
`oneTest baseline` diff (the AUDIT block: loose-index numbering moved, three `MISSTERM JSONtoken`
/`JSONvalue` rows gone, and the summary line gained `0 unconsumed`). ⚠ **Those three targets are
owed a re-pin with a sentence each** — the standing rule is that a moved target is a claim the
world changed and the claim needs a cause. Not taken here, because the order's scope is two lines
and a silent re-pin is exactly what that rule forbids.

`genLadder/completePop.sh`: **134 fixtures swept, 236 green, 0 missing sentinels, 3 abandoned
parses** — `delimTest`, `grammarOnTheFly`, `hashProbe`, abandon=1 each. **Pre-existing and
recorded**, same three and same counts, at `docs/grammarCorpus.md:1534-1536` and
`docs/wakeup.md:1203` ("none session-caused").

## 4. ⚠ THE REORDER IS **NOT** INERT — M1b IS REPAIRED, MEASURED

Byte-identical on the fleet is not the same claim as *"the change does nothing"*, and conflating
the two would be an unsurprising green nobody audits. So the M1b discriminator was rebuilt and run
(scratchpad `m1parens`, prose header per bear-trap #27, no `include` line for the reason
`incant/parensMin`'s header gives):

```
=== ROW A: baseline, no code on Parens ===
INSIDE m1Take, argument is 7
=== MERGE: give the Grokking rule Parens a code body ===
=== ROW B: same call, after Parens carries code ===
PARENS CODE BODY RAN            <-- ⚠ NEW. M1b measured this line NEVER appearing
INSIDE m1Take, argument is 7    <-- and Parens still parses; the 7 still arrives
M1PARENS SENTINEL
```
exit 0, sentinel present, run under `script -q /dev/null`.

**The negative control is banked rather than re-run** — M1b measured this exact shape on the
dlsym-first order and reported `PARENS CODE BODY RAN` never appearing, at exit 0 with no warning.
That is H7 satisfied without a second build: the line that appears now is the one that could not
appear before.

**What it establishes, stated no wider than it goes:** a `code={}` body on a rule that already
carries a C++ action now **runs**, where yesterday it was accepted and silently discarded. The
rule's own parse is undisturbed — the C++ action still matched and still delivered its argument.
The `nextGroup: ERROR CodE does not contain a list` ×2 is M2's characterised noise (a control with
no merge at all emits the identical two lines), not a reorder artifact.

**Not established, and not claimed:** what happens when the coded arm and a live `gMethod` disagree
about the answer. Both fire here and both are right; nothing in this change decides an order
between them, and nothing in today's tree makes them disagree.

## 5. THE LATENT TRAP M1b FILED IS NOW CLOSED

M1b filed it rather than fixing it: *"writing `code{}` on a rule that already has a C++ action is
accepted at exit 0 and does nothing"* — bear-trap #26's family, a plausible outcome where an error
was wanted. **The outcome is no longer plausible-and-empty; the body runs.** The trap entry should
be read as closed by this addendum, not as live.

## 6. WHAT THIS DOES NOT TOUCH

(f)'s re-aimed investigation is undisturbed and unadvanced: the two-node address probe
(`parseRuleMethod` vs `parse()`'s `definingRule().rStuff.parseMethod` fork), the generated-C++
re-definition control (`parseMethod=parseBraced` from a fixture), and the bench charter all stay
parked exactly as (f) left them. **The re-definition bind defect is orthogonal to this dispatch**
and remains the thing standing between the kant path and a green Braced.

---

# ⚠ ADDENDUM 2026-08-13 (h) — SEQ 58: **THE BIND-READ SEAM IS FOUND, AND CLOSED.** The next wall has a name and it is Tony's.

**asOf 2026-08-13 · binary `~/bin/incant` 1387216 bytes, mtime 08:49 · fleet byte-identical
across three rebuilds · every address below copied from a run, none inferred**

(f) localized the defect to *"a write that returned and a read that found nothing"*. SEQ 58 asked
for one bit: same node or different. **Different**, and the repair it pre-registered was the right
one.

## 0. ⚠ THE ORDER'S VEHICLE DID NOT EXIST, AND THIS IS THE FIRST FINDING

SEQ 58 §0 specifies the control as `parseMethod=parseBraced` *"because parseBraced has an oracle
(bracedT)"*. **`parseBraced` had never been compiled.** `nm ~/bin/incant | grep parseBraced` → **0
hits**; the only occurrences in the tree were **emitted text inside two `.md` files**. Bound as
specified it would have died in `setParseMethod` with `ERROR no method found`, and the run that was
supposed to certify the seam would have certified nothing.

**It costs one extern in one in-repo file, so it was added** — pasted verbatim from
`docs/emitted/phaseB-twelve-emitted.txt`, which `docs/respellRung.md` re-derived on 2026-08-11 and
found unmoved. **No `groups.ext` edit is owed** (the door reaches it by `dlsym` on the name, as it
does the whole `parseScaf` family) and **no `incant/grammar` line** (the bind is made from a
fixture — that is the point of a cross-file control). Extern canary **273 → 274**, and the +1 is
this.

## 1. ⚠ PROBE 1 — **DIFFERENT NODE.** Measured, in one run, with a negative control beside it

Two probes, both **`parseTrace`-gated** so no baseline can move: the **write** half inside the
binding door, the **read** half at `parse()`'s fork in `GroupItem.twk`. One run of the bind,
pre-repair:

```
SEAM bind  Braced  boundNode=0x104c60840  boundStuff=0x104c5c100  ownRStuffField=0x104c5c100
SEAM read  Braced  definer=0x104c36a80    defStuff=0x104c34000
                   defParseMethod=0x0     boundParseMethod=0x10406f3c8
SEAM fork  Braced  this=0x104c38380  definer=0x104c36a80  defStuff=0x104c34000  defParseMethod=0x0
```

| the question | the answer, from those three lines |
|---|---|
| did the write take? | **yes** — `boundParseMethod` is non-null. (f)'s refusal-instrument reasoning is confirmed at the address level, not just by inference from a non-refusal |
| did the reader see it? | **no** — `defParseMethod=0x0`, at bind time *and* at parse time |
| same node? | **no.** Bound `0x104c60840`; the reader resolves `0x104c36a80` |
| which is canonical? | **the reader's.** `definingRule()` called **on the bound node itself** already returned `0x104c36a80` — the satellite knew where the real rule was; the door never asked |
| does the fork line even fire? | **yes**, and the negative control proves it is not vacuous: with no bind at all the same probe prints for `Braced` with `defParseMethod=0x0`, and the rule parses interpretively |

**So probe 2 was never needed.** Nothing cleared the field; the field the reader reads was never
written. Probe 3's three-moment question is answered by the same output, because the bind-time
`definingRule()` and the parse-time `definer` are **the same address**.

## 2. THE REPAIR — SEQ 58 §4's first pre-registered shape, landed

Both doors now resolve their target the way the reader does:

```
    GroupItem   ruleNode = grup.definingRule();
    stuff = ruleNode.getRStuff();
```

**BOTH doors, not one, and that is not tidiness.** `parseTermCount` writes `termCount` and
`parseRuleMethod`'s refusal guard reads it. Moving only the method door would compare a count
nobody wrote against the rule's live terms and **silently downgrade the refusal to the
no-`parseTerms` warning — which still binds.** The guard would have been lost quietly.

**Nothing that worked before changes, and the fleet is the proof.** `definingRule()` returns `this`
for a node that owns its children, so every same-file binding — `kantParse1`, `genScratch`, the
`Scaf` family — resolves exactly as it did. `oneTest`, `jsonTest` and the whole `pop.sh` log are
**byte-identical on both streams, split and merged**, across all three rebuilds of this session.

### Post-repair, the same three lines

```
SEAM bind  Braced  boundNode=0x1010d4840  boundStuff=0x10073c000
SEAM read  Braced  definer=0x10073ea80    defStuff=0x10073c000
                   defParseMethod=0x1004eab90   boundParseMethod=0x1004eab90
SEAM fork  Braced  this=0x100740380  definer=0x10073ea80  defStuff=0x10073c000
                   defParseMethod=0x1004eab90
```

`boundStuff == defStuff`. The bind lands where the reader looks. **The seam is closed.**

## 3. ⚠ AND THE CONTROL FIRES — for the first time, on Braced

```
  parseR term= ExpressioN  -> attached as  ExpressioN  under  Braced
  lit " ] " at term  ]
  HIT  Braced
  WIN  Braced
  fireLabelMethod Braced isMethod=1 label=1 deferred=0 parseACTION=0
    attachLabel lab=Braced promote=0 isTarget=1 pLabel=0 pRule=InvokeArg
```

`parseBraced` runs its **whole** chain — both literals and the `ExpressioN` reference. **`promote=0`
is the generated arm**, against the control's `promote=1`. That is (f)'s §3d discriminator, and it
has inverted in the right direction.

## 4. ⚠ THE ANSWER IS STILL WRONG, AND IT IS **NOT** THIS SEAM

`sumple width is now 1`, where the oracle says **251**. Exit 0, sentinel present. **A green reading
of that run is a misreading.**

The mechanism is named, commented at its own site, and is **not** the bind: **GM-29 / IA-2**,
`GroupItem.twk`'s `attachLabel`. `Braced` is an option of the alternation `InvokeArg`; an
alternation is label-transparent so `pStuff.label` is null; the generated arm passes `promote=0` by
PC-1's ruling; so it falls past the promote case into `if !pStuff.label return;` and **the option's
label is dropped on the floor.** The trace line above is that signature, term for term.

⚠ **AND THIS IS THE FIRST TIME IT HAS BEEN MEASURED ON `Braced`.** `docs/respellRung.md` states the
honest limit in as many words — GM-29's post-GX-1 reproduction is on **`Parens`**, and that `Braced`
is still red *"rests on shared shape and shared alternation parent — structural, pointable, and not
measured."* **It is measured now.** The structural claim held, which is this project's standing
asymmetry pointing the usual way.

## 5. ⚠ THE NEXT MOVE IS A DIRECTOR'S CALL THAT IS ALREADY WRITTEN DOWN

IA-2's own comment records it, and nothing here should be read as re-opening it:

> *A one-line experiment promoting in this case turned `parensMin` green with the whole fleet at its
> standing footprint — so the missing promotion ACCOUNTS for the red completely. It was NOT landed:
> it makes the generated arm consult `isTarget`, which PC-1 forbids, and it moves against IT-3's end
> state where promotion deletes entirely. Director's call.*

So the cure is known, measured green once, and **refused on design grounds** — not on doubt. **It
was not guessed past**, per SEQ 58 §4's third branch.

## 6. WHAT LANDED, AND ONE DELIBERATE FLEET MOVE REPORTED BY NAME

- `genParse.rtn` — the two-door repair, the write-half probe, and `parseBraced`.
- `GroupItem.twk` — the read-half probe, `parseTrace`-gated and narrowed to one rule name on
  purpose. **Do not delete it**; it is the only instrument that makes this seam visible.
- `incant/bindSeamA` / `incant/bindSeamB` — the negative control and the reproduction, landed
  rather than left in a scratchpad, because an unrecorded control dies with the session (H7).

⚠ **`completePop` moves 134 → 136 swept and 236 → 240 green.** That is these two fixtures and
nothing else; the three abandoned parses are the same recorded three. **`pop.sh` is untouched and
byte-identical** — and the pair is **deliberately NOT wired into it**, because until §5's call is
made there is no correct value to pin for `bindSeamB`, and a pin whose answer has not been chosen
is exactly what H6 forbids creating.

## 7. WHERE THIS LEAVES SEQ 57 AND SEQ 58

- **SEQ 58 §5's bell has half rung.** The control fires, `bracedT` is green, the fleet is
  byte-identical — but `sumple` width is 1, not 251. **The seam is past; GM-29 is not.**
- **SEQ 57's rungs 1-3 are closed by this.** Rung 1's fork went the way (f) predicted (the C++
  control failed to fire *before* the repair, so the defect was orthogonal to kant); rung 2's
  two-node probe is §1 above; rung 3 is §2.
- **SEQ 57 rung 4 — the kant door — stays parked**, and now for a *better* reason than yesterday's.
  It is no longer blocked by an unexplained bind. It is blocked behind a named alternation defect
  that would corrupt its grading: a kant `Braced` would come back wrong for a reason that has
  nothing to do with kant, and the pre-registration's "red-matching-the-C++-arm = SUCCESS" row
  would be true but uninformative.

---

# ADDENDUM 2026-08-13 (i) — SEQ 59: **THE IA-2 TRIAL LADDER.** Rung 1 green, rung 2 answered, rung 2b red and instructive

**asOf 2026-08-13 · every rung built, run, and REVERTED · baselines re-banked against the SEQ 58
binary before rung 1 · revert verified byte-identical between rungs · canary 274 throughout**

Baseline for every row below: **`bindSeamA` 251, `bindSeamB` 1**, `pop.sh` at its standing footprint.

## RUNG 1 — **SUCCESS, row 1 of the pre-registration**

| the bell | before | after |
|---|---|---|
| `bindSeamB` | **1** | **251** |
| `bindSeamA` (oracle) | 251 | 251, unchanged |
| `oneTest` / `jsonTest`, both streams, split and merged | — | **byte-identical** |
| `pop.sh` whole log | — | **byte-identical** |
| `completePop` | 136 / 240 / 3 / 0 | **identical** |

**The cell opens.** Remaining cost is design-side only.

### ⚠ The spelling landed is NARROWER than "the generated arm consults isTarget", and it matters for the ruling

```
    if (promote || !pStuff.label) && stuff.isTarget {
```

The generated arm consults `isTarget` **only when there is no parent label to attach under.** PC-1
forbids that consult *because* promotion would replace the parent's subtree — GM-22's third wall,
measured as `ScafOUT` coming back childless. **In the `pLabel==0` case there is no parent subtree to
replace.** So this violates PC-1's letter and not its rationale, which should make the amendment
Tony is owed a narrow one.

## ⚠ RUNG 1b — THE BROAD SPELLING IS ALSO GREEN, AND THAT GREEN ASSERTS NOTHING

`if stuff.isTarget {` — dropping the `promote` conjunct outright — **also** takes `bindSeamB` to 251
with the fleet byte-identical. The tempting read is *"then the broad one is safe too."* It is not,
and the census says why. Over one full run of `bindSeamB` (setup + grammar + fixture):

| `attachLabel` calls | count |
|---|---|
| total | **216** |
| `promote=1` | **215** |
| `promote=0` | **1** — `lab=Braced promote=0 isTarget=1 pLabel=0 pRule=InvokeArg` |
| **the cell where the two spellings DIVERGE** (`promote=0 isTarget=1 pLabel=1`) | **0** |

**The two spellings are indistinguishable on today's population.** The broad one's fleet-unmoved
result is not evidence of safety — it is a green on a case that never occurs. Same shape as the
gate-removed fixture that stayed green in H7. **Prefer the narrow spelling on principle: it cannot
reach GM-22's cell by construction, so no future population can make it wrong.**

⚠ **And the same census bounds rung 1's own claim honestly:** the generated arm is exercised
**once** in that entire run. "Fleet byte-identical" is true, and it also means the fleet barely
touches this path today. It is not yet evidence about a fleet with many generated rules in it.

## RUNG 2 — THE FRAME PROBE: **label reachable in-frame**

Probe at the drop site, `parseTrace`-gated, with `bindSeamA` as its negative control (**zero** hits
there — it fires only in the cell it is about):

```
IA2 DROP  lab=Braced  pRule=InvokeArg  pStuff.parentLabel=(null)
          pStuff.parentStuff=TokenXP  pp.label=TokenXP  stuff.parentLabel=(null)
```

**The label is not what is missing** — it is right there, and the guard above already returned if it
were not. **What is missing is a DESTINATION**, and the frame holds one: `pStuff.parentStuff.label`.

⚠ **The order's premise wanted `leaveAlt`'s frame, and `leaveAlt` is not in this picture.**
`leaveAlt` is the **generated** alternation's exit; `InvokeArg` is interpreted, so the drop happens
on the interpreted alternation's own `RuleStuff`. That reframing is what made the probe answerable
at all. It also explains the whole cell in one table:

| alternation | option | outcome |
|---|---|---|
| interpreted | interpreted | works — `promote=1 && isTarget` promotes into the null slot |
| interpreted | **generated** | **drops** — `promote=0`, nothing promotes, no parent label |
| generated | generated | works — `parseR` hands the option `into` through the bridge, so its parent label is non-null |

## ⚠ RUNG 2b — BUILT, AND **RED**. The destination the frame offers is reachable and wrong

```
    if pStuff.parentStuff && pStuff.parentStuff.label {
        pStuff.parentStuff.label +% lab;
        return; }
```

`bindSeamB` **stayed at 1**, and its whole trace and stdout came back **byte-identical but for
ASLR**.

**It is not a no-op misread as a red, and that was checked before grading.** The guard is true by
the probe's own printed values; the generated line was read at the site
(`pStuff->parentStuff->label->addAttribute(lab)`). **The node was really planted, and nothing reads
it there.**

**The lesson, and it is the durable part of this rung:** an alternation must **YIELD** its winning
option's label upward, not **PARK** it in the grandparent's subtree. Rung 1 works because promotion
makes the option's label *be* the alternation's yield; 2b fails because attaching adds a child in a
place no consumer walks. **Reachable is not correct, and a frame having somewhere to put a node is
not evidence that it is the right somewhere.**

## THE COMPARISON, graded against SEQ 59's own pre-statement

- **Both green → prefer rung 2.** Does not apply: **rung 2b is red.**
- **Only rung 1 greens → amend-PC-1 vs ledger, Director's call with the fleet evidence attached.**
  **This is the live branch.** The evidence: fleet byte-identical on both streams and the whole
  `pop.sh` log; the amendment needed is the **narrow** spelling, which leaves PC-1's *rationale*
  intact; and the honest bound is that today's fleet exercises the generated arm exactly once.
- **Not landed.** Reverted per the wall, revert verified byte-identical against the pre-rung
  baselines. `bindSeamB` is back to 1 and is still deliberately unpinned — the pin belongs to the
  winner at landing, which is Tony's call.

**Kept from this ladder:** the `IA2 DROP` probe, `parseTrace`-gated, with rung 2b's failure recorded
at the site so the next reader does not reach for the same destination.

---

# ⚠ ADDENDUM 2026-08-13 (j) — SEQ 61: **PC-1 RULED.** The narrow spelling is landed and the bell is pinned

**asOf 2026-08-13 · binary `~/bin/incant` 1387216 bytes, mtime 09:46 · `pop.sh` 33 → 39 green,
nothing else moved · `completePop` unchanged at 136 / 240 / 3 / 0 · canary 274**

## THE RULING, VERBATIM — Tony, 2026-08-13. This block is the record; everything else cites it

> **PC-1 restated (2026-08-13):** the generated arm never consults `isTarget` **where a parent label
> exists** — promotion there would replace the parent's subtree (GM-22, `ScafOUT` childless). Where
> **no** parent label exists there is no subtree at risk, and the consult is permitted: the IA-2
> cell. Narrow spelling `(promote || !pStuff.label) && stuff.isTarget` landed **`e6438ba`**; broad
> spelling measured indistinguishable on today's population (216 calls, zero in the divergent cell)
> and **rejected on principle**.
>
> **IT-3 reconciliation:** **no new carrier** — the narrow guard extends the condemned case and
> deletes with it at attrition. **Demolition item added to IT-3's list:** before the
> `promote`/`isTarget` case deletes, the IA-2 cell requires an **action-layer carrier** (the
> option's label yielded upward, per the rung 2b constraint); **`bindSeamB`'s pin at 251 is the
> tripwire.** PC-1's rationale stands; its letter is trimmed to the rationale's reach.

**Cited from three places in the source**, so a reader arriving at any of them finds it: the guard
itself, the IA-2 block below it, and the IT-3 header above it — all in `GroupItem.twk`'s
`attachLabel`.

## WHAT LANDED, AND THE SHAPE HELD

The order pre-stated the expected shape as *one hunk, one pin, one comment, one bank*, and said a
surprise would be information. **There was no surprise.** `pop.sh` against the pre-edit bank:

```
> ok  bindSeamA runs (IA-2 oracle, interpreted arm)
> ok  bindSeamA oracle value (251)
> ok  bindSeamA reaches Braced by the INTERPRETED arm (promote=1)
> ok  bindSeamB runs (IA-2 pin, generated arm)
> ok  bindSeamB PINNED at 251 -- PC-1 restated, SEQ 61
> ok  bindSeamB reaches Braced by the GENERATED arm (promote=0)
  POP FAILED -- 33 green  ->  39 green / 1 parked-WIP
```

**Six new rows and nothing else.** The three pre-existing reds are unchanged and still owed a
re-pin by someone; `oneTest`/`jsonTest` byte-identical on both streams split and merged;
`completePop` unmoved because no fixture file was added — both already existed.

## ⚠ THE PIN CARRIES A THIRD ROW THE ORDER DID NOT ASK FOR, AND IT IS THE ONE THAT MAKES IT HONEST

**251 alone can pass for the wrong reason**, and the failure it would hide was live in this tree for
days. If the cross-file bind ever silently stops being read — the exact SEQ 58 defect — `bindSeamB`
**falls back to the interpreted arm and prints 251 anyway**, because the interpreted arm has always
worked. The value check would go green while certifying the opposite of what it claims.

So **the arm is asserted by name**: `promote=0` on Braced's `attachLabel` line is the generated arm,
`promote=1` the interpreted one. `bindSeamA` is checked for `promote=1` for the same reason in the
other direction — an oracle that quietly started using the generated arm would stop being an oracle.

Same family as the standing rule that a constant the default could also produce asserts nothing:
here the *value* is reachable by two paths, so the value is not the assertion — **the path is.**

## WHAT THE PIN NOW OWES IT-3

`bindSeamB` at 251 is a **tripwire with a stated trigger**, recorded on IT-3's own list in the
`attachLabel` header: demolish the `promote`/`isTarget` case without first supplying the IA-2 cell's
action-layer carrier, and this row goes red. **That is intended, not incidental** — it is how a
scheduled deletion is prevented from silently re-opening a closed defect. The carrier's shape is
already constrained by measurement rather than left open: the option's label must be **yielded
upward**, because **parking it in the grandparent's subtree was built and measured RED** (SEQ 59
rung 2b, recorded at the drop site).

## THE FRONTIER MOVES

`genLadder/smoke.sh` slot 1 is **green**, all six checks, fleet unmoved against a freshly banked
reference. ⚠ **And that makes slot 1 due for a swap rather than a thing to celebrate:** a fixture
pinned in `pop.sh` is fleet business, and holding it in the smoke bell as well is duplication, not
coverage. Noted in the file. **Next frontier is SEQ 57 rung 4** — the kant `Braced` body, which
un-parks on its original terms now that the bind is read and the label is honest, and whose
pre-registration finally discriminates: *red-matching-the-C++-arm* is now a true SUCCESS row instead
of an uninformative one.
