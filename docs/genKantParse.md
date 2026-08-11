# genKantParse — Clod's assessment of planB

**Status:** measured, not read · asOf 2026-08-08 · written against the 2026-08-08 design
discussion (Tony's offline status + Clay's brief), which explicitly solicited pushback before
anything is scheduled.

**Reader with no session context:** planB proposes that instead of generating **C++ parse
functions** (what `genParse` does today), a generator emits the parse as **kant CodE** — an
ordinary rule action, installed in the rule's `method` slot, jitted like any other action. The
rule's own semantic action moves to `actionMethod` in `rStuff` to free that slot. The claimed
prize is that the parse method becomes **one artifact serving both engines**, so the
parse-contract (PC) divergence class becomes unconstructable for generated rules.

---

## 0. THE HEADLINE, AND IT IS A SPELLING PROBLEM, NOT A PREMISE PROBLEM

**The idea is sound and the sketch as written does not run.** Those are separate findings and
collapsing them is the mistake to avoid.

The sketch's body is

```
if sukcess = t1() AND t2() AND t3();
```

Every load-bearing word in that line was measured today, and the conjunction is the one that
fails:

| construct | jitted | evidence |
|---|---|---|
| one action calling another, no return value | ✅ emitted, runs per fire | `incant/jitXcall` |
| **mutual recursion between two actions** | ✅ **cycle closes, one compile** | `incant/jitXmutual` |
| a callee that RETURNS a value | ✅ green, degrade 1 (E2, tail position) | `incant/jitXret` |
| **two returning callees, sequential** | ✅ green, degrade 2 | `incant/jitXseq` |
| `a AND b`, plain field operands | ❌ **exit 139, NO degrade line** | `incant/jitXand2` |
| `a OR b`, plain field operands | ❌ **silently wrong, exit 0, degrade 0** | `incant/jitXor` |
| the proposed replacement template | ✅ **short-circuits, both fires correct** | `incant/jitXtemplate` |

⚠ **The two spellings the sketch depends on are the two worst behaviours the JIT currently has
to offer.** `AND` crashes *before the degrade counter sees it* — so H4's instrument, which every
rung asserts at zero, cannot catch it. `OR` is worse: exit 0, degrade 0, and the **wrong
answer**. `jitXor` fire 2 wants 1 and gets 0, because the whole expression evaluated at emit time
and folded. Both are the ungated-operator class (`opAND`/`opOR` are on `jit.md` §2.1's not-gated
list, 24 entries), and this is the **one-channel-one-meaning** family's newest member: a gate
that was never installed reads, from outside, exactly like one that passed.

**And the anti-vacuity rule paid its bill inside this very investigation.** The first version of
`jitXor` used fires `0 OR 1` and `1 OR 1` — both 1 — and **reported green**. It would have gone
into this document as "OR is fine." The re-run with `0 OR 0` / `1 OR 0` is what exposed the fold.
A fixture that cannot distinguish the answers distinguishes nothing.

---

## 1. THE REPLACEMENT, MEASURED BEFORE IT IS RECOMMENDED (H7)

The sketch needs no new JIT work. It needs a different spelling, built only from constructs the
ladder already certifies — comparison (J2/J3), `if` (`jitEmitGIF`, both arms), mid-block `return`
(JRt), and sequential value-returning calls (measured today):

```
xtRule code={
    xtSuk = xtT1();
    if xtSuk == 0;   return 0;
    xtSuk = xtT2();
    if xtSuk == 0;   return 0;
    return 1;
    };
```

`incant/jitXtemplate`, jitted: **ticks 1 on fire 1** (first term fails, second term never runs)
and **ticks 3 on fire 2** (both run), one compile, no recompile between fires, exit 0.

> ## ⚠⚠ RETIRED FOR THE WORD FORMS, 2026-08-11 (SEQ 49) — **THE AND SPELLING IS AVAILABLE. FIRED AND MEASURED.**
>
> **This section's refusal was right when written and its cure is the thing that landed.** It ruled
> that if short-circuit were ever wanted as an operator *"it has to become CONTROL FLOW — an
> `aCTion*` handler with its own emitter, the shape `if` and the loops already have — not a repair
> to `opAND`."* **That is exactly the 08-11 AND/OR rung**: `runShortCircuit`, intercepting at
> `interpretXP` where the expression tree is built, with `jitEmitShortCircuit` on the emit side.
>
> **THE ROW THAT SAID ❌ THE WALL NOW READS:** `incant/jitXand`, AND over two **returning callees** —
> the parse-term shape — fire 1 **`ticksR = 0`, the right arm never ran**, degrade 0, one compile,
> interpreted oracle agreeing.
>
> **AND THE SPELLING WAS FIRED ON A RULE SHAPE, not just on the operator.** `incant/kantRuleA` is
> the method this generator would emit for a rule with a three-term sequence and an alternation in
> the middle — `krSuk = krT1() AND krAlt() AND krT3();`, one statement where the template below
> needs seven. Jitted, four rows, first try, **degrade 0, one compile, no recompile between fires**:
>
> | row | ticks | cursor | what it certifies |
> |---|---|---|---|
> | first term fails | 1 | **0** | short-circuit **and no over-consumption** |
> | all terms pass | 3 | 3 | one token per term |
> | alternation opt 1 fails | 4 | 3 | opt 1 rewound itself, opt 2 ran |
> | alternation opt 1 passes | 3 | 3 | **opt 2 skipped** — the OR chain's own short-circuit |
>
> ⚠ **THE CURSOR IS THE POINT, AND THE TICK COUNT IS NOT ENOUGH.** This section's harm was never
> "an extra call" — it was *"a parse term consumes input, so an eagerly-evaluated right arm advances
> the mark past text the rule never matched."* So every term moves a shared cursor and every row
> asserts where it lands. **H7 control, and it is free because the eager spelling already exists:**
> `incant/kantRuleS` is the same rule with the alternation spelled `||`, and it ends at **cursor 4
> where the word form ends at 3** — a token eaten by an option that did not match. **Both spellings
> return SUCCESS on that row.** A harness asserting the verdict would have certified the eager one.
>
> **WHAT IS NOT RETIRED.** ⚠ **The symbol forms**, where this section's argument now stands
> *measured* rather than argued (`docs/knownErrors.md` KE-5/KE-6, both amended the same day; `&&`
> over calls does not answer wrongly, it **kills the parse at 139 with zero output**). And ⚠ **the
> if-chain template below is NOT deleted** — it is certified, it is the fallback, and it is what the
> AND chain was measured against. **Which spelling v1 emits is Tony's call, not this file's.**
>
> **WHAT STILL BLOCKS A LIVE INSTALLED RULE, and it is not AND/OR:** the support library
> (`lit`, `parseR`, `leaveRule`, `litOption`, `inGuard`, `containerTo`, `leaveAlt`) is `extern "C"`
> and **not callable from kant** — §2(a)'s shim-and-registration job. `kantRuleA` stands in for the
> terms with ticking actions for exactly that reason, and says so in its header.

⚠ **IT SHORT-CIRCUITS BY CONSTRUCTION, AND THAT IS THE ARCHITECTURAL POINT, NOT AN OPTIMISATION.**
`CLAIM KANT-34` records that `&&`/`||` evaluate **both arms** and records the reason as
**structural**: an operateMethod receives operands the runtime has already evaluated, so there is
no point at which `opAND` could decline. **For a parser that is not a style preference — it is a
correctness requirement.** A parse term consumes input, so an eagerly-evaluated right arm
advances the mark past text the rule never matched. The AND spelling cannot express the parse
semantics **in either engine**, today. The if-chain does not need to.

**So short-circuit is not owed as a JIT feature.** If it is ever wanted as an *operator*, it has
to become **control flow** — an `aCTion*` handler with its own emitter, the shape `if` and the
loops already have — not a repair to `opAND`.

**Negation is not available as the guard.** `if !field;` is **inert on a field carrying a value**
— measured interpreted-only in `incant/jitXnot`, both `xnIn = 0` and `xnIn = 1` failing to fire,
**both engines agreeing**, so it is a language question and not a JIT one. KANT-35's `if !a;`
idiom is measured only against **absent attributes**; a field holding numeric `0` is a different
animal (bear-trap #26's neighbourhood — presence and value are different questions). **Use
`== 0`.** Flagged for Tony; not chased.

---

## 2. ANSWERS TO THE FOUR QUESTIONS PUT TO CLOD

### (a) Is the 8-command tally right? — **No. It is short, and it is short in the places that
### matter. But the shortfall is smaller than it looks, because the library already exists.**

Clay's tally: `mark, rewind, report, checkSkip, peek, match-class, consume, capture`.

**The real support library today is seven `extern "C"` functions in `RuleStuff`** —
`lit`, `litOption`, `litTo`(spec'd, unbuilt), `inGuard`, `containerTo`, `leaveRule`, `leaveAlt`,
`parseR`. Against that:

| Clay's item | reality |
|---|---|
| mark / rewind / report | ✅ all three are **inside `leaveRule`/`leaveAlt`**, which are the *sole* implementation of Invariant R. Not three commands — one, twice. |
| checkSkip | ✅ owed, but see the design answer in §3 — its placement is already ruled |
| peek / consume | ✅ = `lit` |
| capture | ✅ = `litTo` / `litOption` |
| match-class | ⚠ **not one command.** §2.5 rules that character-level terms **accumulate** (loop *inside* the matcher, one token spanning the run) while group references **iterate** (loop *outside*, one fresh label per pass). Conflating them yields "a parser that accepts correctly and builds wrongly." This is a **generated helper per term**, two shapes, not a library call. |
| — | ❌ **`inGuard` — MISSING FROM THE TALLY.** Every member option is emitted `(inGuard(...) && parseR(into))`. Alternation without it is not alternation. |
| — | ❌ **`stashDefer` — MISSING, AND IT IS THE LOAD-BEARING ONE.** `defer` is the parse→generate seam: it is where `gIF`, `gFOR`, `gPrinT`, `gXpress` come from (spec §2.9). A rule fleet without it cannot feed the generator. |
| — | ⚠ `upTo`/`upToOver` and `macroVal` — missing from the tally, **but not owed for v1**: `planTerm` refuses both today, so they are beyond the current frontier in *both* generators. |
| — | ✅ `containerTo` — **already paid** (GAP A / CT, closed 2026-08-07). Free. |
| — | ✅ `act` and `promote` — **dissolving**, correctly. `act` is largely absorbed by Tony's `actionMethod` move; `promote` retires with IT. |

**So: ~8 → ~11 for parity with today's frontier, and ~13 to clear it.** But the honest cost
statement is not the count. It is this:

⚠ **THE LIBRARY DOES NOT NEED REWRITING — IT NEEDS REGISTERING.** Those seven functions are
already `extern "C"`, already the machinery, already proven by the C++ ladder. Making them
callable from kant is a **shim + registration** job (the `immediateAction=` / `ruleMethod=`
door, one-arg `GroupItem*(GroupItem*)`, multi-arg via the attributes-plus-`:scope` idiom),
not an implementation job. That is materially cheaper than "8 commands owed" implies.

**And what is hiding is not a command at all.** Two things:

1. **Invariant R′** (spec §2.2a) — a **two-part handshake** in `parse()`/`checkInput()`
   (`GroupItem.twk:1087` writes `label.fLAG`, `RuleStuff.twk:141-144` reads it) that generated
   code **deliberately does not inherit**. Mark saved **once at loop entry**, fresh label every
   pass, never recycled. It is an *obligation on the emitted loop*, and nothing stops an emitter
   from inventing its own recycling. It lands with repetition, in whichever generator gets there.
2. **The min-zeroing defect** (spec §7.1) — `getWhatFollows()`'s one write,
   `if !min && parent.min  parent.min = 0;`. genParse **deletes** it by baking min as a literal.
   ⚠ **A kant action that reads `rs.min` at RUN time re-inherits the bug.** Which is exactly why
   Tony's proposed generation-era doctrine is right, and now has a worked example behind it
   rather than being a principle — see §3.

### (b) Real cost of genKantParse v1 vs continuing genParse — **same campaign, and much smaller than it looks, because genParse was already built for this.**

`genParse.rtn` is 1654 lines, and it is **already two layers with a clean seam**:

- **the PLAN layer** — `planTerm` / `planRule` / `countRuleTerms` / `unresolvedTerms` and every
  refusal. Produces a **GroupItem tree**: `SEQ`/`ALT` folds over `CALL`, `LIT`, `LITTO`,
  `CONTAINER`, `OPT`, `MANY` nodes.
- **the C++ back end** — `emitPlan` / `emitLeaf` / `emitMany` / `spellKant` / `manyKant`,
  roughly 200 lines of spelling.

**The code already says the seam is generator-agnostic, in its own words:** *"Every refusal now
lives in planRule, where it belongs — a refusal is a validity question about the RULE, so it
reads the same whichever emitter is downstream (§4)."* And `emitPlan`'s header: *"planRule
DECIDES, emitPlan WRITES. Nothing between them knows about C++."*

⚠ **genKantParse is therefore a SECOND BACK END ON A SHARED PLAN, not a second campaign.** That
is the single most important structural fact in this assessment, and it is the kind of claim that
holds here (the standing asymmetry: structural claims survive, causal claims are a coin flip).

Three consequences:

- **v1's emitter is ~200 lines of respelling**, not a rebuild. The intellectual mass — the
  classification, the refusal discipline, the census, the partition, the ladder — is shared and
  already paid for.
- **Adjudication is nearly free and is exactly the H8 shape Tony wants.** Same rule, same plan,
  two back ends, one comparison fixture: identical tree + identical R report. The plan tree is
  itself printable (`printPlan`), so a divergence localizes to *plan vs spelling* immediately.
- ⚠ **A fork Clay's brief did not name, and it decides v1's cost.** There are two ways to get a
  kant action out of a C++ generator:
  **(i) emit kant SOURCE TEXT** and let it in through the ordinary `define … code={ }` door — the
  emitter changes spelling only, `emitPlan`'s exact shape survives, the generated artifact stays
  **human-readable** (spec §3.1's explicit requirement), and installation uses the one jit door
  with no new path; or
  **(ii) synthesize the BlocK tree directly** — no text, no re-parse, but it needs the
  tree-synthesis idioms the wakeup already gates the kant-native generator behind, and it
  bypasses `aCTionDefinE`.
  **Take (i) for v1.** It is the cheap one *and* the one that keeps the readable-diff property
  that makes step-2 adjudication possible. (ii) is the milestone, not the prerequisite.

### (c) Anything in the four measurements Clod already knew — **yes, three of four, and one was wrong in the brief's favour.**

| # | brief's item | answer |
|---|---|---|
| 1 | **loops on the jitted path** | ✅ **YES, and richer than "one wall-shaped suspect."** `jitLoopBegin`/`Body`/`End` with a real back edge; `while`, `do` and **`iterate`** all carry `if jitting` gates; `break`/`continue` are consumed at the loop boundary. Rung JUi is **no longer a pinned divergence** (since 2026-08-04). ⚠ **The one exception is `for`**, which calls `jitDegrade("FOR under jit -- no emitter (iterate's disease, different keyword)")` — a named missing emitter, honestly counted, not a wall. |
| 2 | **emitted AND/OR short-circuit** | ✅ **THE WALL IS DOWN, 2026-08-11 — this row is the respell's prerequisite and it now reads exactly the AND/OR seal.** ~~❌ The wall … not short-circuiting in either engine and structurally so (KANT-34); under jit `AND` **crashes** and `OR` is **silently wrong**.~~ **Struck.** `AND`/`OR` are promoted to **tier 3** and short-circuit in **both** engines: `jitXand` fire 1 `ticksR` **0 = SKIPPED**, fire 2 `ticksR` **1** / `ticksL` **2** (emitted per fire); `jitXand2` and `jitXor` fire 1 **0** → fire 2 **1**, degrade **0**. Ladder rungs **JXD-1/2/3**. ⚠ **KANT-34's mechanism clause is RETIRED** (short-circuit *is* expressible — just not at an `operateMethod`); its statement survives for the **symbol** forms only, which is **KE-6**. Spec: `docs/andOrRung.md`. |
| 3 | **return emitter** | ✅ landed 2026-08-05, rung JRt, ladder 129→150 (returned scalar, factorial through real recursion, mid-block return). ⚠ **Residual: E2.** A `return` inside an **inlined callee** degrades — *"it would branch to the enclosing function's epilogue."* Every §1-shaped fixture shows it. **Green today only because a TAIL return needs no branch**, so falling through is accidentally equivalent. The genKantParse templates put returns in tail position naturally, so this is survivable — but it is an accident to be *aware of*, not a property to rely on. |
| 4 | **action-invokes-action through the fallback column** | ✅ **YES — and the framing is wrong in a way that helps.** It does not go through the fallback column at all: the callee is **inlined**. Measured green acyclic (`jitXcall`) **and cyclic** (`jitXmutual` — mutual recursion, ticks 4→10, one compile, degrade 0). ⚠ **That cyclic result is the one that matters**, because genParseSpec §2.6 rests explicitly on a cyclic call graph (`JSONblock → JSONfield → JSONvalue → JSONblock`), and recursive descent *is* a cycle. `jitEmitSelfCall`'s inline-stack test sees a two-cycle, not just a self-call. |

**Net: the JIT is in better shape for this than the brief assumed on three items, and worse on
one — and the one it is worse on is the one the sketch is written in.**

### (d) Does this change First Light's definition? — **No, and it cannot, by construction.**

*(First Light is not defined anywhere in the repo — it is Clay's term in this brief. Read here as
"the first generated rule installed and running in the fleet," i.e. the metric moving off zero.)*

**It is generator-agnostic because the thing blocking it is upstream of both back ends.** The
metric is stuck at **0/47** on IA-1's gate: no reader-bearing alternation is fully plannable,
because **GAP B (rule-as-data)** refuses `NumbeR`/`ANYtoken`/`SemI`. Both refusals live in the
**plan layer** —

- `planRule`: `REFUSE rule … rule-level data … (§4.1 rule-as-data, rung 5)`
- `planTerm`: `REFUSE … inline group / character data … (named future kind)`

— which `genKantParse` **shares unchanged**. A second back end changes the spelling of plans that
already succeed; it cannot make a refused rule plannable.

⚠ **So planB does not move First Light one inch closer, and should not be sold as doing so.**
Gap B is the work. That is not an argument against planB — it is an argument about **sequencing**,
and it is the honest version of the claim.

**One caveat, stated because it cuts the other way:** Tony's note that "genParse has to handle
data if rule has data … isGROUP and attributes … members" is a description of Gap B. If planB is
taken as the *occasion* to close Gap B, then it moves the metric — but the credit belongs to Gap B,
and doing both at once means a red cannot be localized to one of them. **Close Gap B in the plan
layer first, where it benefits both back ends and where a red has one cause.**

---

## 3. THE OPEN DESIGN DECISIONS — three of five are already answered by the tree

**Skip discipline — ALREADY RULED, and against the sketch.** Spec §3.4: *"the skip-set pass
happens at the head of each token match (`lit`, `litTo`, and each accumulator), not in the
frame."* Stated reason: it keeps the frame free of input manipulation, **which matters because
the frame is established on paths that then fail**. The sketch's `checkSkip()` on entry is the
rejected option. Not attribute-governed; ruled once, for a reason that still holds.

**`t1()` dispatch uniformity — CONFIRMED, and IA-0/IA-1 do dissolve rather than get satisfied.**
`aCTionRunRulE` dispatches on `rule.isMethod` and calls `input.method(...)` — it does **not** ask
whether the method was generated. Under jit the callee is inlined and, per `jitXmutual`, a cycle
closes. **A generated and a non-generated callee are the same call at both layers.** The
mixed-shape world is safe. ⚠ **This is the finding that most changes the shape of the campaign**,
because IA-0's "the migration unit is the ALTERNATION — all of one parent's options cross
together" exists precisely to prevent a mixed-shape world. If mixed shapes are safe, the
migration unit can be **the rule**, and the gate that refuses every install loses its premise.
**Worth Tony's attention ahead of anything else in this document.** (Measured for *action*
dispatch; the *parse-arm* fork in `parse()` is a separate question and is not covered by these
fixtures.)

**Generation-era rule — ADOPT IT, and it has a worked example rather than only a principle.**
"Anything read at generation time is frozen into the method; anything mutable post-generation
must not be read then." §7.1's min-zeroing defect is exactly this: genParse deletes the bug by
baking `min` as a literal, and a kant action that reads `rs.min` at run time re-inherits it.
**Propose promoting to doctrine with that citation attached** — a rule with a paid-for example
survives; a principle gets re-litigated.

**Yield protocol / one writer — no objection, and PC-3 already built the hard part.** `labelNO`
was minted `isCOUNT 0` precisely so the JIT's i32 value channel could carry it. "Value channel
carries only success, node-yield becomes attach-side" is that decision followed to its end. It is
also the one-channel-one-meaning cure applied before the bug, which is the right order.

**One jit door — agree, emphatically, and the tree agrees.** `jitRunAction` is the single writer
of the `JiT` record and `testing()` routes on `isCoded` (bear-trap #25). A generator that invoked
the jitter would be a second door onto a one-writer fact, which is the failure family this
project has paid for most often.

---

## 4. RECOMMENDATION

**Open planB. It is cheaper than the brief assumes and the premise is sound.** But sequence it
honestly:

1. **Do not schedule it as a metric-mover.** Gap B is the metric. planB is an *architecture*
   move — it collapses the PC divergence class and puts one artifact in front of both engines.
   Those are worth having on their own terms and should be argued on them.
2. **Respell the templates before writing them.** `AND`/`OR` are unavailable — one crashes
   invisibly, one lies. §1's if-chain is measured and uses only certified constructs.
3. **Take the emit-kant-source route for v1** (§2b), keeping `emitPlan`'s shape and the readable
   artifact.
4. **Register the existing support library rather than rewriting it**, and add `inGuard` and
   `stashDefer` to the tally.
5. **Put the `t1()`-dispatch-uniformity finding in front of Tony first** — if it holds for the
   parse arm too, IA-0's migration unit shrinks from the alternation to the rule, and that is
   worth more than planB itself.

**Two defects to log independently of planB, both found today, both pre-existing:**
- **`AND` under jit exits 139 with no degrade line.** Crash, not a fallback.
- **`OR` under jit is silently wrong at degrade 0** (folds its emit-time value).
Both are the ungated-operator class; the general statement — *an ungated operator in a jitted
body folds its emit-time value* — is **inferred from two members and not swept**, and the
not-gated list has 24 entries. **A sweep of that list is the obvious next instrument** and would
be cheap: the `jitXor` shape, one fixture per operator, two discriminating fires.

---

## 5. THE FIXTURES

All seven are committed, all carry a sentinel (H2), all were run under a wall-clock cap (H5).
Order is jitted-half-first, oracle-last throughout (bear-trap #25).

| fixture | asks | result |
|---|---|---|
| `incant/jitXcall` | acyclic action→action call | exit 0, ticks 2, 8→22, degrade 0 |
| `incant/jitXmutual` | **mutual recursion** | exit 0, ticks 4→10, one compile, degrade 0 |
| `incant/jitXret` | value-returning callee | exit 0, degrade 1 (E2), green by tail position |
| `incant/jitXseq` | two returning callees, sequential | exit 0, degrade 2, all values correct |
| `incant/jitXand` | the sketch's shape | ~~exit 139, 2 degrades then crash~~ → **exit 0**, fire 1 `ticksR` **0 = SKIPPED**, fire 2 `ticksR` **1** / `ticksL` **2**, degrade **0** |
| `incant/jitXand2` | `AND` on plain fields | ~~exit 139, no degrade line at all~~ → **exit 0**, fire 1 **0** / fire 2 **1**, degrade **0** |
| `incant/jitXor` | `OR` on plain fields | ~~exit 0, degrade 0, wrong answer~~ → **exit 0**, fire 1 **0** / fire 2 **1**, degrade **0** |
| `incant/jitXnot` | `!` on a valued field (interpreted only) | inert both rows — a language question |
| `incant/jitXtemplate` | the proposed replacement | exit 0, **ticks 1→3, real short-circuit** |

⚠ **UPDATED 2026-08-11 — three rows moved and the "not wired" caveat is now HALF TRUE.**
`jitXand`, `jitXand2` and `jitXor` **graduated into the ladder** as rungs **JXD-3, JXD-1 and
JXD-2**, so they are no longer loose measurement fixtures. ~~If planB is opened … `jitXand2`/
`jitXor` should become pinned known-defect rows~~ — **they were pinned, they woke, and they
graduated**, which is the full H6 arc in nine days. `jitXtemplate` is still the one that would
graduate if planB opens; the rest remain design measurements.

⚠ **§5 CONTROLS — AMENDED AT DE-PARK (SEQ 33, 2026-08-11). Two KEPT instruments join this
table, and the reason is a sequencing one:** the respell composes AND/OR **chains**, so the
**per-operator semantics must be pinned before the first regenerated rule fires** — otherwise a
chain defect and an operator defect are indistinguishable at the only moment anyone is looking.

| kept instrument | pins |
|---|---|
| `incant/andProbe` | the `AND` truth table, short-circuit (word) vs strict (symbol), assignment position, and the `if`-vs-operator truthiness gap |
| `incant/orProbe` | the `OR` truth table, `\|\|` strictness, and `!a \|\| !b` on an absent attribute (the `KANT-35` row, now repaired) |

**This charter also inherits, as standing context:** the **operand truthiness ruling**
(`docs/andOrRung.md` §3 part 1, SEQ 32) and the **placement doctrine** (§6 of the same file) —
its chains compose under exactly those semantics, and neither is re-litigated here.

**Binary under test:** `~/bin/incant`, mtime 2026-08-08 07:57, with `jitLadder/ladder.sh` green
at 150 checks in the same session (H1 — a harness echoes the binary it is testing, and a stale
binary is this project's most-paid-for instrument failure).

⚠ **THAT BINARY AND THAT COUNT ARE HISTORICAL AS OF 2026-08-11 — they record what the §5 table
above was measured against and are deliberately NOT rewritten** (a provenance naming the run it
came from is the record; repointing it would falsify that). **The current reference is the
2026-08-11 seal: ladder 184 / exit 0, `completePop` 129 swept / 226 green / 0 missing
sentinels.** The three struck rows above were re-measured against the 08-11 binary, not this one.
**Any doc still citing 173 as the live ladder count is citation-sweep fodder, not a live claim.**
