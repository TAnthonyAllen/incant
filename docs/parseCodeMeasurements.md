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
