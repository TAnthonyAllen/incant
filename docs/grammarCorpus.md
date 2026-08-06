# GRAMMAR MINION — CORPUS (stage 1: a document)
**Every claim is written for a reader with NO session context.** Self-contained, full provenance,
leaning on no shared history — the stage-1 durability rule (`docs/grammarMinion.md`, STAGES).
The corpus is the part that outlives the executor. B0 throughout: provenance · confidence · asOf.

---

## GM-1 — THE RULE POPULATION IS 78, ACROSS TWO AXES
**asOf 2026-08-05 · confidence: MEASURED · provenance: `incant/ruleCount`, `docs/phaseA-partition.txt`**

The incant grammar's rule population is **78**: the `Grokking` registry carries **60 rule members**
(of 61 members; the 61st, `Operators`, is a registry and not a rule) and **18 rule attributes**, all
18 flagged `isRulE`, with **zero overlap** between the axes.

⚠ **A ONE-AXIS WALK REPORTS 60 AND LOOKS RIGHT.** The first probe walked members only and reported
60, then flagged `GrouP` and `NamE` as unexplained absences — rules named in `incant/grammar`'s own
header comment but missing from the count. **They are attribute-axis rules.** The anomaly was in the
walk, not the grammar, and it was visible in the probe's own output as a puzzle it could not answer.
**Walk both axes or the number is wrong.**

## GM-2 — `popScratch` IS A SAMPLE, NOT A CENSUS
**asOf 2026-08-05 · confidence: MEASURED (a reading of the file's own header) · provenance:
`incant/popScratch:8-13`, renamed from `incant/censusScratch` by Tony's ruling**

`incant/popScratch` makes **30** `dumpRulePlans('X');` calls, hand-listed to exercise the classifier.
Its own header always said *"a spread of the REAL bootstrap grammar"*. **It is not an enumeration and
never was.** It touches **18** of the 78 population rules; its other 12 entries are the 7 JSON rules
and 4 `Scaf` scaffolds (fixture-local) plus `debug`.

⚠ **`debug` IS A DELIBERATE NEGATIVE CONTROL, NOT A CASE DRIFT OF `DEBUG`.** It must come back
refused — `census.target:161-162`, *"REFUSING debug — not a rule; locate finds a non-rule in registry
Keywords"* — while `DEBUG`, the real rule and the very next call, plans or refuses on its merits.
**Do not "fix" the case.**

⚠ **THE NAME COST REAL GROUND.** Called *census*, it was read as coverage, and the grammar campaign
opened believing 30 described the population. Its header also said "27 rules" while making 30 calls
(`debug`/`DEBUG`/`InvokE` appended without the count moving). Both corrected 2026-08-05.

## GM-3 — A `noPrint` ATTRIBUTE WITH AN IMMEDIATE ACTION IS INVISIBLE TO ANY TREE WALK
**asOf 2026-08-05 · confidence: MEASURED, with a proven instrument · provenance: `incant/setup:7-11`
(the vocabulary's own statement), `incant/grammar:52` and `:54`, `incant/npAll`, `incant/npFlag`**

`incant/setup:7-11` states the mechanism: *"Commands fire C++ methods used to set flags… They have an
associated method specified by the immediateAction attribute, which is a noPrint attribute. **noPrint
attributes are fire and forget. They change the group being defined but are not added as a group
attribute once forgotten.** For example, the isRule command/attribute makes the group it appears in a
rule, then it disappears so it does not become a rule attribute."*

**So the class exists in SOURCE and not in the TREE, and every classification walk reads the tree.**

**Two rules carry one** (RULED by Tony as canonical define-time firing, `isRulE` family — identified
and closed, not a defect):
- `Limit` — `incant/grammar:52` — `Limit '['- min=[0-9]+ max?=[0-9]+ ']'- noPrint;`
- `Modifier` — `incant/grammar:54` — `Modifier=[-~+?!%&|*@_<^{}$] noPrint;`

**The other class is EMPTY:** across all 78 rules, both axes, **zero ATTACHED `noPrint` attributes**
(`incant/npAll`). So the grammar contributes no fidelity-prerequisite customers, and no archaeology
is owed.

⚠ **RECORDED OBSERVATION, NOT CHASED** (the rider's instruction was source-read, no chase). The
`noPrint` on those two rules leaves **no observable trace on the rule**: not as an attached attribute
(`Limit`'s four attributes are `[ min max ]`, all plain; `Modifier` has none), and not as the rule's
own `noPrinT` flag, which reads **clear** on both. The identical syntax on a plain field —
`npLit noPrint;` — **does** set the flag. **The instrument is proven, not assumed:** `incant/npFlag`
carries a positive control (`npLit` reads SET) beside a negative (`npPlain` reads clear), because a
first draft asked only the four rules, got "clear" four times, and could not tell that from an
accessor that never reports SET. Where the firing lands is not established here and was not pursued.

**STANDING CONSEQUENCE:** any future `noPrint`-with-action use on a rule must be flagged at
definition, because nothing downstream can see it.

## GM-4 — ATTRIBUTE-AXIS RULES DISPATCH IDENTICALLY; THE FORK TESTS NO AXIS
**asOf 2026-08-05 · confidence: MEASURED (source read, file:line) · provenance:
`GroupItem.twk:1048-1054` and `:956-963`**

`parse()` forks to a generated method at `GroupItem.twk:1048-1054`:
```
    definer  = definingRule();
    defStuff = definer.rStuff;
    if defStuff && defStuff.parseMethod { … label = defStuff.parseMethod(this); … }
```
and `definingRule()` (`:956-963`) is `get(1)` → `first.parent` → owner. **It tests no axis at all** —
not membership, not attribute-ness — only whether the node's first child is parented elsewhere. Its
own header states why this is the right seam: *"parseMethod is SHAPE — one answer, always the same —
so resolving it here means binding a rule once reaches EVERY reference to it, including references
created LATER."* **An attribute-axis rule such as `GrouP` needs no special handling.**

## GM-5 — THE POINTER IS PER-RUN; THE INSTALL IS NOT
**asOf 2026-08-05 · confidence: MEASURED (source read) · provenance: `RuleStuff.mm:838` and `:877`,
`genParse.rtn:1284-1293` and `:1328-1334`, `GroupItem.twk:1311`**

`rStuff.parseMethod` is a raw function pointer, zeroed by **both** `RuleStuff` constructors — the one
from a `GroupItem` (`:838`) **and the copy constructor** (`:877`). Nothing serialises it and nothing
can. A cloned frame therefore does not carry the method; dispatch reads the **defining** rule's
persistent `rStuff`.

The install route is a **definition attribute** in grammar source —
`Scaf isRule "x"- parseMethod=parseScaf;` — reaching `setParseMethod` → `dlsym(RTLD_SELF, name)`.

⚠ **SO A CRASHED OR ABANDONED RUN LEAVES NOTHING BEHIND (isolation is free), BUT REMOVING AN INSTALL
IS AN EDIT TO THE SOURCE, NOT A CALL.** An attribute in grammar source re-installs on **every**
incantation for as long as it is there.

**Baseline for the campaign metric:** `parseMethod=` appears **zero** times in `incant/grammar` and
`incant/setup`; the only tree-wide occurrences are three scratch fixtures. The fraction opens at
**0/78 installed**.

## GM-6 — GENERATED PARSE METHODS FIRE RULE ACTIONS THROUGH `ruleActions.rtn`. ONE ACTION LAYER, BOTH FORK ARMS.
**RULED by Tony at genParse's conception; restated with evidence 2026-08-05 · confidence: RULING ·
provenance: this corpus, `docs/grammarMinion.md`**

A generated parse method fires its rule's action through `ruleActions.rtn` exactly as the interpretive
`GroupItem::parse()` does. **There is one action layer and both arms of the fork run it.**
**Consequence, and it is why the arrangement is load-bearing rather than tidy: the verify oracle
isolates PARSE divergence by construction** — if both arms run the same actions, a diff between them
cannot be an action difference, so a red verify names the parse.

⚠ **BYPASSING THE ACTION CHAIN FROM GENERATED CODE IS A RULING, NOT A CONVENIENCE.** Do not "optimise"
it away; doing so destroys the oracle's isolation property in the same stroke.

**JITTING THE ACTIONS IS PHASE TWO**, motivated by inlining, and **gated on FOUR conditions, all of
them:**
1. **inlining certified**
2. **the frame model landed**
3. **planner gap #6 proven** (flag-setting as a plannable term kind, at any position, including as the
   entire body)
4. **the actions rewritten in kant, ONE AT A TIME**, each with its **C++ original as that action's own
   oracle**, and each rewrite **independently banked**

⚠ **GATE FOUR CARRIES THE SELF-HOSTING METRIC IN ACTION CLOTHES:** the fraction
**actions-in-kant / actions-in-`ruleActions`**.

## GM-7 — `CLAIM KANT-40`: A PARSE CAN DIE SILENTLY AT EXIT 0, AND CLASSIFICATION MUST GUARD FOR IT
**asOf 2026-08-05 · confidence: MEASURED, negative-controlled · provenance: `incant/phaseA`,
`incant/ruleCount`**

`aCTionCodE` scans an action body for the **first** close brace with no block awareness, so a braced
block inside an action body ends the capture early: the statement fails to parse, **every statement
after it in the file is dropped**, and the run **still exits 0**.

**A classification walk performs the vulnerable act once per rule, so a silent death would read as a
REFUSAL.** The guard: each rule emits its own completion marker after its dump on the same stream, and
the file carries a foot sentinel. **A PLAN with no DONE is UNKNOWN — walk incomplete — never a
refusal.**

**H7 negative control:** a KANT-40 specimen injected after rule 40 gives **exit 0, 40 PLAN, 40 DONE,
no sentinel**, and the 38 unreached rules produce no PLAN line at all. ⚠ **Scope of what that proved,
stated rather than implied:** the specimen exercised the **file-level** death, where PLAN and DONE
vanish together. The per-rule DONE is the finer guard — a death **between** a PLAN and its DONE — and
this specimen did not force that case.

⚠ **THE GUARD CAUGHT A DIFFERENT DISEASE THAN IT WAS BUILT FOR, WHICH IS THE ARGUMENT FOR BUILDING
IT.** A probe that emitted one call per rule with the rule **name bare** died at rule 11 — `break` —
because several rules are **keywords** (`break`, `continue`, `return`, `define`) and a bare keyword is
not a name in an argument slot. Signature: exit 0, 10 DONE markers, no sentinel. **The repair was a
shape, not a reminder:** walk the registry with nested iteration and name no rule at all.

## GM-8 — A SECOND ACTION WALKING THE SAME NODE CAME BACK EMPTY (`CLAIM KANT-8`'s FAMILY, OBSERVED WILD)
**asOf 2026-08-05 · confidence: OBSERVED, not diagnosed · provenance: `incant/ruleCount`'s first draft;
cross-reference `incant/kant8T` rows K6a–K6d**

Counting a registry's members in one action and then listing them in a **second** action over the
**same node** produced a correct count (61/60) and then **nothing** from the second walk. Folding both
branches into a single walk answers the same question and cannot fail that way.

**Not chased.** It is the node-resident-state family that `incant/kant8T` characterises: K6a measures
an iterator cursor trampled across activations, K6d eliminates the re-iterate as a suspect. **Recorded
as evidence for the frame arc**, whose opening fixture is K6a's shape jitted — *does the runtime frame
bracket inherit the gap for node-resident state?* — not as a defect for this campaign to fix.

## GM-9 — WHERE `noPrint`'s DEFINE-TIME FIRING LANDS ON A RULE IS UNESTABLISHED
**asOf 2026-08-05 · confidence: OBSERVED (the discrepancy), UNMEASURED (the cause) · owner: parked,
chased by nobody until it blocks something or Tony fires it · provenance: `incant/grammar:52` and
`:54`, `incant/setup:7-11`, specimen instrument `incant/npFlag`**

The cOMMANDs vocabulary says a `noPrint` command *"changes the group being defined"*
(`incant/setup:7-11`). On a plain field the identical syntax does exactly that: `npLit noPrint;`
reads with its `noPrinT` flag **SET**. On a **rule** it does not appear to: `Limit`
(`incant/grammar:52`) shows four attributes — `[ min max ]` — **all plain**, `Modifier`
(`incant/grammar:54`) shows **none**, and **both rules' own `noPrinT` flags read CLEAR**.

**The instrument is not in doubt.** `incant/npFlag` carries both controls — `npLit` (SET) and
`npPlain` (clear) — precisely because a first draft asked only the rules, got "clear" four times, and
could not have distinguished that from an accessor that never reports SET.

**LEAD, offered at the usual odds and UNMEASURED (Clay's):** a `processFlags`-family routing
difference when the target is rule-shaped.

⚠ **THIS IS A CAUSAL-SHAPED CLAIM IN A CODEBASE WHERE THOSE FAIL ROUGHLY HALF THE TIME AND
STRUCTURAL ONES HOLD.** Treat it as a place to look first, not as a diagnosis. The disposition of
`Limit` and `Modifier` does **not** depend on it: Tony has ruled both as canonical define-time firing
of the `isRulE` family, identified and closed. This row exists so the discrepancy is not rediscovered
from scratch by whoever next trips over it.

## GM-10 — ALL TWELVE PLANNABLE RULES EMIT CLEANLY
**asOf 2026-08-05 · confidence: MEASURED · provenance: `incant/emitAll`,
`docs/emitted/phaseB-twelve-emitted.txt`**

`genParse` produces a complete, compilable method plus its own bind line for **all twelve** rules in
the PLAN column — Braced · Parens · ElsE · InvokE · InvokeArg · PrintField · WardeD · GrouP · CodE ·
RunRulE · BlocK · ExpressioN. Twelve `DONE` markers and the foot sentinel (the standing completeness
guard), exit 0. Term counts range 1 (`ExpressioN`) to 12 (`WardeD`).

Emission is **read-only**: `genParse` writes text and installs nothing. **Emission is therefore not
the campaign's bottleneck — installation is** (see GM-11).

## GM-11 — ⚠ THE INSTALL VOCABULARY IS FIXTURE-LOCAL, SO THE FRONT DOOR IS SHUT FOR REAL GRAMMAR RULES
**asOf 2026-08-05 · confidence: MEASURED, and the specimen is a SIGSEGV · provenance:
`incant/genScratch:18` and `:20`; `incant/setup` (absence); `incant/grammar:107`**

`parseMethod` and `parseTerms` are registered as commands **only in the test fixture**:
```
    incant/genScratch:18   define parseMethod immediateAction=parseRuleMethod noPrint; ;
    incant/genScratch:20   define parseTerms  immediateAction=parseTermCount  noPrint; ;
```
They appear **nowhere in `incant/setup`**. So in any ordinary run — `oneTest`, `jsonTest`, the whole
fleet — those names are **not commands**, and a `parseMethod=` written into `incant/grammar` is not
fired and consumed at define time. **It is parsed as an ordinary TERM of the rule.**

**MEASURED, installing `Braced` (`incant/grammar:107`) with
`parseTerms=3 parseMethod=parseBraced`:**
```
    AUDIT MISSTERM Braced [4] parseTerms  -- isRule term, no rStuff
    AUDIT MISSTERM Braced [5] parseMethod -- isRule term, no rStuff
    AUDIT all registries: 4 missing rules, 14 missing terms, 4 loose   (was 12)
    oneTest: Segmentation fault: 11  (exit 139)
```
The rule gained **two spurious terms**, 3 → 5, against a generated method that indexes `rule[1..3]`
and a `parseTerms=3` that never took effect.

⚠ **WHY THE SCAFFOLDS NEVER SHOWED THIS:** every `Scaf*` rule is defined **inside
`incant/genScratch` itself** (`:55-62`), where the vocabulary is registered. The install route has
only ever been exercised in the one file that defines the words it needs.

**CONSEQUENCE FOR THE CAMPAIGN:** Phase B cannot install into shipped grammar until
`parseMethod`/`parseTerms` are registered where every run can see them. That is a change to
`incant/setup` — the front door's vocabulary, not `rStuff` internals and not the fork — and it
affects every incantation, so it is **Tony's ruling, not the minion's**.

⚠ **THE BASELINE MOVED AND WAS EXPLAINED, NOT RE-BLESSED** (the brief's standing rule, live for the
first time). Which install: `Braced`. Why byte-different: two spurious terms and a SIGSEGV, cause
above. The install was **reverted**, the tree rebuilt, and `pop.sh` and `oneTest` confirmed
**byte-identical to the pre-install capture**. The metric stays at **0/78 installed** — honestly.

## GM-12 — THE FRONT DOOR IS OPEN: THE INSTALL VOCABULARY IS REGISTERED IN `incant/setup`
**asOf 2026-08-05 · confidence: MEASURED · RULED by Tony · provenance: `incant/setup:59-60`,
`GroupActions.rtn` `auditUnconsumed`, `Commands.rtn` audit line**

`parseMethod` and `parseTerms` are now registered as commands in `incant/setup`, beside `isRule` and
the rest of the define-time fire-and-forget family — **where the grammar is read**, not only inside
the fixture that tests them (GM-11). Registration alone moves **no baseline**: `incant/setup` is
runtime data, and the fleet was byte-identical before any install.

**Verified consumed:** with the vocabulary live, installing `parseTerms=3 parseMethod=parseBraced`
on `incant/grammar:107` yields **`0 unconsumed`** and no `MISSTERM Braced` lines. The attributes fire
and disappear, exactly as `isRule` does.

**THE CONSUMED-CHECK IS NOW PART OF THE AUDIT FAMILY** (Tony's rider). `auditUnconsumed` reports any
`parseMethod`/`parseTerms` found sitting in a rule's **term list** — proof it was never a command in
that context. It is **its own check and not folded into MISSTERM**, because MISSTERM says *"isRule
term, no rStuff"*, which reads as a materialisation problem and points at `rStuff` — bear country,
and the wrong country.
**H7 control: the 2026-08-05 Braced specimen is real and dated** (GM-11's SIGSEGV run). The count is
printed **unconditionally with its value** in the audit line — `… 4 loose, 0 unconsumed` — and
asserted by `genLadder/pop.sh`'s `AUDITLINE`, so deleting the emitter breaks the check rather than
satisfying it (rule H4).

## GM-13 — ⚠ RULE ONE, `Braced`: INSTALLS AND CONSUMES CLEANLY, BUT **VERIFIES RED**. PARKED.
**asOf 2026-08-05 · confidence: MEASURED, isolated · provenance: `incant/grammar:107`,
`docs/emitted/braced-red-specimen.txt` (253 lines), generated method in
`docs/emitted/phaseB-twelve-emitted.txt`**

With the vocabulary registered, `Braced` installs correctly — `0 unconsumed`, no spurious terms,
`oneTest` **exit 0**, `jsonTest` exit 0, ladder 150, `pop.sh` 33 green / 1 parked. **The install
mechanism is not the problem any more.**

**But the fleet is not byte-identical, so the generated method diverges from the interpretive rule on
real input.** Isolated with a clean before/after on the grammar line alone (two builds, nothing else
changed): installing `parseBraced` **deletes ~30 lines of bytecode-generation output from
`oneTest`** — the entire `gIF` / `gXpress` emit trace for `testByteCode`:
```
    runGenerated:  action is: gIF
    ExpressioN  attribute  length 3 revisedList …
    Entering gXpress   /  emit tag= bcPushField … bcBRZ …
```
⚠ **AND THE DIVERGENCE NAMES THE PARSE BY CONSTRUCTION.** Both fork arms run the same rule actions
through `ruleActions.rtn` (GM-6), so this cannot be an action difference. That is the oracle's
isolation property paying for itself on its first use.

**LEAD, at the usual odds, UNMEASURED and NOT HARDENED:** the emitted method attaches the parsed
`ExpressioN` via `parseR(t2, label)`, while `aCTionBraced` (`ruleActions.rtn`) reads a named
attribute — `GroupItem ExpressioN:;` then `input.group = ExpressioN`. If the generated attachment
differs in name or shape, the action finds nothing and the enclosing expression collapses silently.
**This is a causal-shaped claim in a codebase where those fail roughly half the time. It is a place
to look first, not a diagnosis.**

**DISPOSITION: PARKED, per the brief — a red parks the rule with its specimen and the campaign takes
the next rule.** `Braced` is reverted; the generated method is **not** left in the tree as dead code,
and the emitted text is banked in `docs/emitted/`. **Metric stays 0/78 installed.**

## GM-12a — `parseTerms` IS A GUARD, NOT OPERATIONAL (FU-1)
**asOf 2026-08-05 · confidence: MEASURED (source read) · provenance: `genParse.rtn:1345-1358`
(setter), `:1360-1382` (reader), `RuleStuff.h:13-18`**

`parseTermCount` records `stuff.termCount = atoi(name)` and does nothing else. `parseRuleMethod`
reads it **once, at bind time**: computes `live = countRuleTerms(grup)`, then
- `!stuff.termCount` → **WARNING**, *"binding … with no parseTerms — indices unguarded"*, installs anyway
- `stuff.termCount != live` → **REFUSES to bind** and returns without installing

**Nothing else reads it.** The emitted method indexes `rule[1..n]` with literal integers; the count
does **not** feed the parse. `RuleStuff.h:13-18` states the bet it guards: *"Every emitted rule[n]
bets the list only ever mutates BEHIND the real terms; the cached BlocK appearing after a rule's
first parse proves the list does mutate at runtime, and nothing else enforces the bet."*

**So a guard exists and it is a good one — but it is a DEFINE-TIME guard.** If a rule's term list
drifts **after** the bind, nothing re-checks. Whether a run-time equivalent is wanted is **Tony's
ruling**.

⚠ **AND THE GUARD COULD NOT DEFEND AGAINST ITS OWN PREREQUISITE.** In GM-11's failure `parseMethod`
was not a command at all, so `parseRuleMethod` never ran and the guard never fired. **That is
precisely why the consumed-check belongs in the audit family** rather than relying on this one: a
guard reached through the mechanism it guards cannot catch that mechanism being absent.

## GM-14 — A FULL-MONTY VERIFY IS A DETECTOR, NOT A LOCALIZER
**asOf 2026-08-05 · confidence: RULED (Tony) · provenance: this campaign's rule one**

`oneTest`'s corpus diff is **the verdict**: it says *divergence / no divergence*, and it is the
oracle. It does **not** say where. `parseTrace` narration is the **standard red-response**: gated,
default off, instrumenting the support layer once so every generated method self-narrates for free.
**Every future red arrives with its fork point named, not merely its symptom banked.**

## GM-15 — FULL-MONTY COVERAGE HONESTY
**asOf 2026-08-05 · confidence: RULED (Tony)**

**"Diff empty" means "no divergence in the corpus's usage of the rule" — nothing more.** A sparsely
used rule verifies sparsely. **The campaign claims exactly that and no more**, and a green row is a
claim about coverage the corpus actually exercises.

## GM-16 — ⚠⚠ THE GENERATED ARM DOES NOT FIRE THE RULE ACTION. GM-6 IS DESIGN INTENT, NOT AN IMPLEMENTED FACT.
**asOf 2026-08-05 · confidence: MEASURED, located by the FU-2′ localizer on its first use ·
provenance: `GroupItem.twk:1050-1054` (the fork), `:1073-1079` (the action site), `:1109-1113`
(`generatedExit`) · specimen `docs/emitted/braced-exhibit-narration.txt`**

**The localizer worked, and it falsified the lead it was built to test.** With `parseBraced`
installed and `parseTrace` open, the minimal input `bmArr[1]` narrates:
```
    lit " [ "  at term  [
    parseR term= ExpressioN  into= Braced
    parseR term= ExpressioN  -> attached as  ExpressioN  under  Braced
    lit " ] "  at term  ]
    HIT  Braced
    WIN  Braced
```
**`parseR` attaches `ExpressioN` under the label, correctly named.** GM-13's lead — *"the generated
attachment differs in name or shape, so `aCTionBraced` finds nothing"* — is **dead**. The attachment
is right.

**THE ACTUAL FORK POINT, with file:line.** `parse()`'s generated arm (`:1050-1054`) ends
`goto generatedExit`, and `generatedExit` (`:1109-1113`) does only `aCTionFailed` on failure, the
`trueResult` substitution, and `return label`. **The rule action fires at `:1073-1079` — inside the
match loop, under the comment *"Success. Fire label method if there is one."* — and the `goto` jumps
clean over it.**

⚠ **SO BRACED'S RED IS NOT A PARSE DIVERGENCE AT ALL. IT IS AN ACTION-LAYER DIVERGENCE — THE EXACT
THING GM-6 RULES MUST NOT EXIST.** `aCTionBraced` (`input.clear(); input.group = ExpressioN;
input.fLAG = true;`) never runs on the generated path, so the enclosing expression collapses and
~30 lines of downstream bytecode-generation output vanish.

⚠ **AND GM-6's ISOLATION PROPERTY IS THEREFORE NOT YET EARNED.** GM-6 says a verify diff *cannot* be
an action difference because both arms run the same actions. **That is true of the design and false
of the code today** — which the very first red exposed. The ruling stands as a ruling; what changed
is that it is now a **work item with a named site** rather than an assumed invariant. **This is why
GM-6 was worth writing down as a ruling before it was needed.**

**NO FIX TAKEN, per the brief.** `Parens` runs first; if it reds the same way, two specimens make the
pattern systemic and the fix lands **once at the right level** — the generated exit — instead of once
per rule.

## GM-17 — ⚠⚠ RULE TWO, `Parens`: REDS IN BRACED'S EXACT SHAPE. **THE PATTERN IS SYSTEMIC.**
**asOf 2026-08-06 · confidence: MEASURED, both arms, negative-controlled · provenance:
`incant/grammar:108` (the install, since reverted), `incant/parensMin` (the localizer specimen),
`docs/emitted/parens-red-specimen.txt`, generated method in
`docs/emitted/phaseB-twelve-emitted.txt:15-25`**

`Parens` was the **designed discriminator** for GM-13/GM-16: the same three-term shape as `Braced`,
a **different rule action**, so a matching red makes the fault systemic and a green would have made
Braced's red specific to `aCTionBraced`. **It reds, in the same shape, and the answer is systemic.**

**No emitter drift.** `genParse('Parens')` regenerated on 2026-08-06 is **byte-identical** to the
2026-08-05 banking. Its one shape difference from Braced is its own and is correct: the middle term
is optional (`ExpressioN?`), emitted as `(parseR(t2,label) || 1)`.

**THE MEASUREMENT, both arms, same binary, install toggled at `incant/grammar:108` alone:**
```
ARM A  install ON      lit " ( " at term  (
                       parseR term= ExpressioN  into= Parens
                       parseR term= ExpressioN  -> attached as  ExpressioN  under  Parens
                       lit " ) " at term  )
                       HIT  Parens
                       WIN  Parens
                       stdout: (the action's print NEVER APPEARS)      exit 0, sentinel present
ARM B  install OFF     stdout: INSIDE pmTake, argument is 7            exit 0, sentinel present
                       stderr: empty (parseR/lit are not called on the interpretive path)
```
**Parse correct · attachment correctly named · rule HITs and WINs · the action never fires.** That is
GM-16's finding reproduced on a second rule with a different action, which is exactly what the
discriminator was built to decide.

## ⚠ AND RULE TWO IS NOT A QUIETER RED THAN RULE ONE — IT IS A CATASTROPHIC ONE, FOR A STRUCTURAL REASON
`Braced` cost ~30 lines of bytecode-generation output. **`Parens` takes the whole language down.**
`StatemenT` contains no `RunRulE`; a top-level call parses as
`Xpress → ExpressioN → Token → TokenXP → ANYorNum^ InvokeArg? → Parens`, so **`Parens` is on the path
of EVERY parenthesised invocation in incant.** With the action skipped, `include(unitTests)` invokes
`include` carrying no argument and the run dies on its **first statement**:
```
    getFile: could not open file: include: Is a directory        EXIT=2
```
Every fixture in the tree that includes anything fails identically. **The severity is a property of
where the rule sits, not of how wrong the generated method is** — the generated method is, as far as
the parse goes, right.

⚠ **A CONSEQUENCE THAT WILL BITE THE NEXT EXECUTOR: THE STANDARD INSTALL GATE IS UNMEASURABLE FOR
THIS RULE.** The consumed-check (`AUDIT all registries: … 0 unconsumed`, GM-12) is reached by calling
`audit()` — **itself a parenthesised invocation**, so it does not dispatch under the install and
prints nothing at all. Measured both ways: ARM A emits no `AUDIT` line, ARM B emits one. **So GM-13's
"installs and consumes cleanly, but verifies red" cannot be stated for `Parens` — the install half is
not observable while the install is live.** Do not record it as clean; record it as unmeasurable, and
note that any future rule on the invocation path inherits the same blind spot.

⚠ **THE LOCALIZER'S FIRST FIXTURE WAS GREEN-LOOKING AND CERTIFIED NOTHING — RULE H7, PAID AGAIN.**
The first cut of `incant/parensMin` assigned the argument to an outer field and printed it after the
call; it printed `pmOut is pmOut` with the install **ON and OFF alike** — a field with no data
returns its TAG from `.text`, so the wrong answer looked like a real reading. **It discriminated
nothing and would have been read as proof.** The fix was to print the argument **from inside the
action**, where absence of the line is the signal. **A rung certifies only what fails when the
mechanism is removed: run both arms, always, and treat a first-try agreement between arms as a
broken instrument rather than a finding.**

**DISPOSITION: PARKED AND FULLY REVERTED, per the standing brief.** `incant/grammar:108` restored,
the generated `parseParens` **removed from `genParse.rtn` rather than left as dead code**, extern
count back 257 → 256, rebuilt. **Restoration verified byte-identical, not assumed:** `oneTest`,
`jsonTest`, `kant8T`, `phaseA` and `emitAll` all match their pre-install captures on **both streams**;
`pop.sh` 33 green / 1 parked, `ladder.sh` 150, `recordPop.sh` 48, `printPop`/`containerPop`/`tree`
exit 0. `incant/parensMin` is **kept** — it runs clean with no install and is the specimen for
whoever takes the fix. **Metric stays 0/78 installed.**

**WHAT THIS UNBLOCKS.** GM-16 said *"`Parens` runs first; if it reds the same way, two specimens make
the pattern systemic and the fix lands once at the right level — the generated exit — instead of once
per rule."* **It reds the same way. The condition is met.** The fix is a separate decision after this
report and is not part of the fire.

## GM-18 — GX: THE ACTION NOW FIRES ON THE GENERATED ARM. **A SECOND, DISTINCT DIVERGENCE IS UNDERNEATH IT.**
**asOf 2026-08-06 · confidence: MEASURED, both arms, probe-instrumented · provenance:
`GroupItem.twk` `fireLabelMethod` (new) and `parse()`'s generated arm, `RuleStuff.twk:603-617`
(`leaveRule`), `GroupItem.mm:1086-1094` (the interpretive attach), specimen `incant/parensMin`**

**THE FIX, AND IT IS THE SHAPE GX-1 ASKED FOR RATHER THAN A COPIED BLOCK.** The action-firing block
was **extracted verbatim** from `parse()`'s match loop into `GroupItem::fireLabelMethod(RuleStuff)`,
and **both arms now call it** — the interpretive arm where the block used to sit, the generated arm
under `if sukcess` before `goto generatedExit`. One writer of the behaviour, so the two arms cannot
drift on action-firing again. This extends `parse()`'s own S1.3 principle — *"the generated path
matches the interpretive path because it RUNS the same exit, not because the exit was copied
carefully"* — one region further up; the defect was that **the shared region started too late.**

**No return value, deliberately:** both things it can change (`label`, `sukcess`) live on the
RuleStuff, so it mutates in place. The tempting *"return the label, null means failure"* is wrong
here and quietly so — `RuleStuff.twk:181` sets `label = 0` **on success** for a `noLabel` rule, so
null would mean *"no label"* and *"method failed"* at once.

**BEHAVIOUR-NEUTRAL WITH NO RULE INSTALLED, MEASURED:** `oneTest`, `jsonTest`, `kant8T`, `phaseA`,
`emitAll` byte-identical on **both streams**; `pop.sh` 33 green / 1 parked, ladder 150,
`recordPop` 48, `printPop`/`containerPop`/`tree` exit 0.

**✅ THE PRIMARY ORACLE MOVED.** With `Parens` installed, a `parseTrace`-gated probe inside
`fireLabelMethod` reports, for the first time, on the generated arm:
```
    fireLabelMethod Parens isMethod=1 label=1 deferred=0 parseACTION=0      <- BOTH arms now
```
**The rule action fires on the generated path.** GM-16/GM-17's defect is closed.

## ⚠ AND THE ORACLE IS STILL RED, BECAUSE A SECOND DIVERGENCE SITS UNDER THE FIRST
`incant/parensMin` still does not print `INSIDE pmTake, argument is 7` with the install live, and the
probe names where it now goes wrong — one level up the tree:
```
    install ON    fireLabelMethod InvokeArg isMethod=0 label=0      <- nothing attached
    install OFF   fireLabelMethod InvokeArg isMethod=0 label=1
```
**THE MECHANISM, AND IT IS STRUCTURAL RATHER THAN A BUG IN THE EMITTED METHOD.** The two arms attach
the finished label to the parent in different places, and the generated one is a strict subset:

| | interpretive (`GroupItem.mm:1086-1094`) | generated (`leaveRule`, `RuleStuff.twk:608`) |
|---|---|---|
| target rule | `pStuff.label = label; label.tag = pStuff.ruleName` | — |
| `label.isGROUP && max > 1` | `pStuff.label +% label.group` then clear the label | — |
| otherwise | `pStuff.label +% label` | `if into  into +% label` |
| ordering | attach **after** the action | attach **before** the action |

**Both differences bite `Parens` at once.** `aCTionParens` is `input.clear(); input.group =
ExpressioN;` — it MAKES the label `isGROUP`, which is precisely the middle row, so the interpretive
arm attaches the **ExpressioN** and the generated arm attaches a `Parens` wrapper around it. And it
cannot even reach that row, because `leaveRule` has already attached by the time the action runs.
**Right language, wrong tree** — the hazard `genParse.rtn`'s own §2.4 note raises for ALT, arriving
here by a different road.

**THIS IS A NEW FINDING, NOT NOISE** (GX-2 anticipated the disposition). It is also **not day-sized**:
closing it means either `leaveRule` taking over the full three-case attach *and* firing the action
before it, or generated methods ceasing to attach at all so `parse()` owns the plumbing for both
arms. The second is the structurally-right answer and changes **every generated method's contract**.
**Reported rather than chosen, per GX-5.**

**DISPOSITION.** The `fireLabelMethod` extraction is **KEPT** — proven neutral, strictly correct, and
a prerequisite for either shape above. `Parens` is **NOT installed**; `incant/grammar` is untouched
and `parseParens` is not in the tree. **Metric stays 0/78.** The probe is kept, gated on the existing
`parseTrace` and therefore silent by default. **GX-3's audit door was NOT built** — the install it
was to unblock did not happen, so it would have been a door onto a room nobody can enter yet.

## GM-19 — LA: THE ATTACH EXTRACTION WORKS AND **THE ALTERNATION RESISTS IT**. STOPPED AND REPORTED.
**asOf 2026-08-06 · confidence: MEASURED, isolated, candidate fix falsified · provenance:
`RuleStuff.twk:689` (parseR), `:603` (leaveRule), `:625` (leaveAlt), `GroupItem.mm:1086-94`
(the three-case attach), `genLadder/tree.sh`**

**THE PRE-FIRE MEASUREMENT ANSWERED CLEANLY, AND IT WAS THE RIGHT ONE TO TAKE FIRST.** LA's
premise is that `parse()` can own the attach for both arms, which requires that nested rule
references come through `parse()` at all. **They do.** `parseR` builds a bridge RuleStuff, sets
`bridge.label = into`, and calls `term.parse(bridge)` — so a reference term reaches `parse()` with
`into` arriving as `pStuff`'s label. `parseR`'s own header states the intent outright: *"ONE
mechanism serves both halves of mixed mode."* **The design already said one mechanism; the code had
two.** (A designer-side prediction that nested references reach `parse()` was offered at the usual
odds beforehand and is **confirmed** — one for the structural column.)

**WHAT WAS BUILT.** `GroupItem::attachLabel(stuff, pStuff)`, the three-case attach extracted
verbatim from `parse()`'s match loop, called by **both** arms — the interpretive one where the
block used to sit, the generated one after `fireLabelMethod`. `leaveRule`'s `if into  into +% label`
removed rather than left beside it. Emitter untouched.

**✅ THE PRIMARY ORACLE WENT GREEN.** `incant/parensMin` with `Parens` installed printed
`INSIDE pmTake, argument is 7` — the argument arrives, from inside the action — and the probe read
`fireLabelMethod InvokeArg … label=1`, **matching the uninstalled arm exactly, 4/4 both ways.**

**✅ AND THE INSTALL GATE IS CLEAN, WHICH GM-17 COULD NOT STATE.** `AUDIT all registries: 4 missing
rules, 12 missing terms, 4 loose, **0 unconsumed**` — byte-identical to the uninstalled arm.
⚠ **GX-3's audit door needed no building: `audit()` dispatches again as a CONSEQUENCE of the action
firing.** The room became enterable by fixing the door, so the separate non-parenthesised entry is
not owed.

## ⚠ AND THEN `tree.sh` WENT RED — THE ALTERNATION RESISTS THE SHARED SHAPE
```
    generated, before LA:   ScafOUT / ScafA        (the winning option, S2.4)
    generated, after LA:    ScafOUT / true
    interpretive, both:     ScafOUT / ScafALT      (unchanged)
```
**MECHANISM.** S2.4 rules an alternation **label-transparent**: it builds no label of its own and
its winning option attaches itself. So `leaveAlt` returns **`trueResult`, not a label**, and on the
generated path `stuff.label` is therefore **sometimes not a label at all**. An unconditional shared
attach puts `true` into the parse tree where the option belongs. **Right language, wrong tree —
the same hazard GM-18 named, arriving from the other side.**

**ISOLATED TO LA, NOT TO THE INSTALL:** `tree.sh` is red with `Parens` **not** installed, since it
exercises the Scaf rules. One measurement, no inference.

⚠ **THE OBVIOUS CANDIDATE IS FALSIFIED, AND CHEAPLY — WHICH IS WHY IT WAS TRIED BEFORE BEING
PROPOSED.** Guarding on `lab.isLabel` — *"is this actually a label"*, a predicate rather than a
sentinel test, and `RuleStuff.twk:185` stamps `isLabel` when it mints one — **breaks everything**:
exit **2** on all five named fixtures, every harness red, `parensMin` losing its argument line. So
**interpretive labels do NOT reliably carry `isLabel`**, and the discriminator has to be something
else. Recorded so nobody spends the build on it twice.

**DISPOSITION: STOPPED AND REVERTED, per LA-3's tension clause.** `GroupItem.twk`, `RuleStuff.twk`
and `incant/grammar` restored; `parseParens` removed rather than left as dead code. **Restoration
verified byte-identical on both streams** for `oneTest`/`jsonTest`/`kant8T`/`phaseA`/`emitAll`, with
`pop.sh` 33 green / 1 parked, ladder 150, recordPop 48, formsPop 14, tree/printPop/containerPop
exit 0. **Metric stays 0/78.**

**WHAT THE RULING NEEDS TO DECIDE**, and all three are above this seat:
1. **How a generated method says "I attached nothing of my own".** `trueResult` currently carries
   that meaning *and* "success" — one channel, two meanings, the family this tree keeps paying for.
2. **Whether `leaveAlt` should return the winning option's label** instead. That is the shape that
   removes the ambiguity at its source, and it **changes the emitter contract**, which LA-2 fenced
   out.
3. **Whether the alternation is simply exempt** from the shared attach, which keeps LA's extraction
   for the SEQ case and accepts one deliberate asymmetry — cheapest, and honest if it is written
   down rather than discovered later.

**ONE MORE FINDING, BANKED NOT CHASED.** Installing `Parens` adds exactly one audit line —
`AUDIT TERM Parens [3] ) -- rule TERM, not isRule, has rStuff` — so `oneTest`'s stderr baseline
moves by one row. Cause **not established**. Leading hypothesis, graded as hypothesis: one of the
two definition attributes resolves its `parent` to the final **term** rather than to the rule, and
`getRStuff()` then mints rStuff there. **Not re-pinned** — a moved target is a claim that the world
changed, and this one has no cause yet.
