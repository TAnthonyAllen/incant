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
