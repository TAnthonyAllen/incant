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
