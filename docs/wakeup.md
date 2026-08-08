# ⚠⚠ SEALED 2026-08-08 (FINAL VINTAGE) — READ THIS SECTION FIRST.
# Everything from `# ⚠⚠ SEALED 2026-08-07` down is older vintage. THE METRIC IS 0/47, NOT 0/78.
# A FORK IS OPEN ON THE BOARD — planB / genKantParse — AND IT IS THE FIRST TIME THIS PROJECT
# HAS INHERITED A CHOICE RATHER THAN A FRONTIER.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-08 — planB OPENED (genKantParse), AND THE SKETCH'S SPELLING DIED ON
#              SEVEN FIXTURES WHILE ITS PREMISE SURVIVED
# ═══════════════════════════════════════════════════════════════════════════

## WHAT IS RUNNABLE
```
sh jitLadder/ladder.sh        150 checks, exit 0    (re-run today, green)
sh genLadder/pop.sh            33 green / 1 parked  (the SAME 3 owned reds)
sh genLadder/recordPop.sh      48 checks · formsPop.sh 14 · printPop 9 · containerPop 11 · tree 0
sh genLadder/completePop.sh    121 swept · 3 abandoned · 2 missing sentinels · 208 green · exit 1
sh jitLadder/ladder.sh         162 checks, exit 0     (150 + JXT + JXD pins)
sh genLadder/mixed.sh            7 checks, exit 0     NEW — the parse-arm decomposition, PINNED RED-SIDE
<binary> incant/oneTest · jsonTest · kant8T · phaseA · emitAll      exit 0
```
**Metric: 0/47 installed.** Nothing regressed today; today's work added fixtures only.

## ⚠ THE SEAL CORRECTIONS OWED FROM THE 08-07 VINTAGE, APPLIED
The section below this one says **0/78** in three places and it is **stale, not wrong-headed**:
- **THE DENOMINATOR IS 47** (IA-4). 78 counts **Grokking's registry population** (60 members + 18
  attributes); 47 counts **names in `incant/grammar` that can consume an install bind at their own
  definition site**. Different sources, different axes — 47 does not *correct* 78, it **replaces
  it as the campaign's denominator**, because a rule that cannot consume a bind cannot be
  installed however plannable it is. 102 sites probed: 67 LIVE, 35 dead, 0 VOID.
- **The oracle is amended to EVIDENCE-OF-EXECUTION** (IA-5). For a **deferred** rule neither axis
  of the union lens discriminates the arms — `BlocK` reads `fire=2 attach=0` identically with the
  install on and off, because `defer` skips its label at the yield guard long before
  `attachLabel`'s no-label guard. **The crash was the evidence the lens could not supply.**
- **The abandonment instrument is LIVE with three catches** (IA-6). `genLadder/completePop.sh`,
  structurally defined population. Three pre-existing live abandoners, all at
  exit 0, none session-caused: **`delimTest`, `grammarOnTheFly`, `hashProbe`**. Reported, not
  diagnosed. **The sweep is RED on arrival and that is the instrument working.**

⚠ **AND IT PROVED THE STRUCTURAL POPULATION WORKS BY CATCHING TODAY'S OWN FIXTURES — the numbers
moved and the movement is named, not absorbed.** `112 / 3 abandoned / 0 missing sentinels`
became **`121 / 3 / 2`**. The two new sentinel misses are **`jitXand` and `jitXand2`, and their
missing sentinel IS the finding they were written to record**: `AND` under jit exits 139, so the
sentinel cannot print. Nothing regressed — the abandoner count is **unchanged at 3**, and the
sweep swept nine new fixtures with nobody maintaining a list, which is exactly what IA-6 bought.
**⚠ But two deliberate crashes are now STANDING REDS with no way to own them.** `pop.sh` has an
owned-red/parked vocabulary and `completePop.sh` has none, so these will be re-explained every
session until someone rules. **That is IA-6's own named follow-on** (*"hardening their choke
points is day-size but not this fire's day"*) arriving with a concrete demand case. **Tony's
call:** an owned-red list, or measurement fixtures kept out of the swept population — noting that
the second option weakens the structural-population property that makes the sweep worth having.
- **GATE discharged on K5/K6** · **bracket fix scheduled at the green-fleet junction.**

## ⚠⚠ THE FORK: planB / genKantParse — ASSESSED, NOT SCHEDULED
Full assessment with every measurement: **`docs/genKantParse.md`**. Three sentences of it:

**THE PREMISE IS SOUND AND THE SKETCH AS WRITTEN DOES NOT RUN, AND THOSE ARE SEPARATE FINDINGS.**
The proposal — generate the parse as **kant CodE** installed in the rule's `method` slot, with the
semantic action moved to `actionMethod` — collapses the whole PC divergence class for generated
rules, because there stops being two artifacts to keep in parity. **But the body it is written in,
`sukcess = t1() AND t2() AND t3()`, uses the two worst-behaved constructs the JIT currently has.**

| measured today | result |
|---|---|
| `AND`, plain field operands | ❌ **exit 139, and NO degrade line — it crashes before the counter sees it** |
| `OR`, plain field operands | ❌ **exit 0, degrade 0, WRONG ANSWER** (fire 2 wants 1, gets 0 — emit-time fold) |
| action→action call, acyclic | ✅ emitted, runs per fire |
| **action→action, MUTUALLY RECURSIVE** | ✅ **the cycle closes** — ticks 4→10, one compile, degrade 0 |
| two value-returning callees, sequential | ✅ green (degrade 2, the known E2 tail-return) |
| **the proposed replacement template** | ✅ **short-circuits for real — ticks 1→3** |

**THE REPLACEMENT NEEDS NO NEW JIT WORK — ONLY A DIFFERENT SPELLING**, built from constructs the
ladder already certifies (comparison, `if`, mid-block `return`, sequential calls):
```
    xtSuk = xtT1();   if xtSuk == 0;   return 0;
    xtSuk = xtT2();   if xtSuk == 0;   return 0;
    return 1;
```
⚠ **AND IT SHORT-CIRCUITS BY CONSTRUCTION, WHICH IS THE POINT AND NOT AN OPTIMISATION.** KANT-34
records `&&`/`||` as evaluating both arms **in the interpreter too**, and records the reason as
structural. **For a parser that is a correctness requirement, not a style choice** — a parse term
consumes input, so an eager right arm advances the mark past text the rule never matched. The AND
spelling cannot express parse semantics in **either** engine. The if-chain does not need to.
If short-circuit is ever wanted as an *operator*, it must become **control flow** with its own
`aCTion*` handler and emitter — the shape `if` and the loops already have — **not** a repair to
`opAND`.

## ⚠ THE FINDING THAT MOST CHANGES THE CAMPAIGN'S SHAPE — put in front of Tony first
**`t1()` DISPATCH IS UNIFORM.** `aCTionRunRulE` dispatches on `rule.isMethod` and never asks
whether the method was generated; under jit the callee is **inlined**, and `jitXmutual` shows a
**two-cycle closes**. A generated and a non-generated callee are **the same call at both layers**.
**So the mixed-shape world is safe — and IA-0's premise is what that undermines.** IA-0 ("the
migration unit is the ALTERNATION, all of one parent's options cross together") exists precisely
to prevent mixed shapes. If they are safe, **the migration unit can be the RULE**, and IA-1's gate
loses the reason it refuses every install. **IA-0/IA-1 would dissolve rather than get satisfied.**
⚠ Measured for **action** dispatch only. The **parse-arm** fork inside `parse()` is a separate
question these fixtures do not cover, and the claim must not be stretched over it.

## WHAT planB DOES NOT DO, STATED SO IT IS NOT OVERSOLD
**It does not move the metric.** The gate is **GAP B (rule-as-data)**, and both of its refusals
live in the **PLAN layer** — `planRule`'s *"rule-level data"* and `planTerm`'s *"inline group /
character data"* — which genKantParse **shares unchanged**. A second back end respells plans that
already succeed; it cannot make a refused rule plannable. **Close Gap B in the plan layer first**,
where it pays both back ends and where a red has exactly one cause.

## ⚠ genParse WAS ALREADY BUILT FOR A SECOND BACK END, and this is the cost answer
`genParse.rtn` is already two layers with a clean seam, **and says so in its own comments**:
`planRule` DECIDES (a GroupItem plan tree — `SEQ`/`ALT` over `CALL`/`LIT`/`LITTO`/`CONTAINER`/
`OPT`/`MANY`), `emitPlan` WRITES, *"nothing between them knows about C++."* So **genKantParse is a
second back end on a shared plan, ~200 lines of respelling — not a second campaign.** Adjudication
is then the H8 shape Tony asked for almost for free: same rule, same plan, two back ends, one
comparison fixture.
**And the fork the brief did not name:** emit **kant source text** through the ordinary
`define … code={ }` door (cheap, keeps `emitPlan`'s shape, keeps the artifact human-readable) vs
**synthesize the BlocK tree** (needs the tree-synthesis idioms, bypasses `aCTionDefinE`).
**Take the text route for v1.**

## THE COMMAND TALLY IS SHORT — but the library needs REGISTERING, not writing
~8 → **~11 for parity with today's frontier, ~13 to clear it**. Missing and load-bearing:
**`inGuard`** (every member option is `(inGuard(...) && parseR(into))`) and **`stashDefer`**
(`defer` is the parse→generate seam — where `gIF`/`gFOR`/`gPrinT`/`gXpress` come from).
`containerTo` is **already paid**. `upTo`/`upToOver`/`macroVal` are beyond the frontier in *both*
generators, so not owed for v1. ⚠ **But the seven support functions already exist as `extern "C"`
in `RuleStuff` — making them kant-callable is shims + registration, not implementation.**
**What is actually hiding is not a command:** Invariant **R′**'s two-part label-recycling
handshake (an obligation on the emitted loop, deliberately not inherited), and **§7.1's
min-zeroing defect**, which a kant action re-inherits the moment it reads `rs.min` at RUN time —
which is the worked example that earns Tony's **generation-era doctrine** its promotion.

## DOCTRINE / DEFECTS ADDED TODAY
- **TWO PRE-EXISTING JIT DEFECTS, LOGGED INDEPENDENTLY OF planB.** `AND` under jit **crashes with
  no degrade line**; `OR` under jit is **silently wrong at degrade 0**. Both are the ungated-
  operator class. ⚠ The general statement — *an ungated operator in a jitted body folds its
  emit-time value* — is **inferred from two members and NOT swept**; the not-gated list has **24**
  entries. **A sweep is the obvious next instrument** and is cheap (the `jitXor` shape, one
  fixture per operator, two discriminating fires).
- **`if !field;` IS INERT ON A FIELD CARRYING A VALUE** — measured interpreted-only, `0` and `1`
  both failing to fire, **both engines agreeing**, so it is a language question and not a JIT one.
  KANT-35's `if !a;` idiom is measured only against **absent attributes**. **Use `== 0`.** Tony's.
- ⚠ **THE ANTI-VACUITY RULE PAID ITS BILL INSIDE TODAY'S OWN INVESTIGATION.** The first `jitXor`
  used `0 OR 1` and `1 OR 1` — both 1 — and **reported green**. It would have entered the
  assessment as *"OR is fine."* The re-run with a discriminating pair found the fold. **A fixture
  that cannot distinguish the answers distinguishes nothing** — including one written by someone
  who had just finished reading the rule.
- **E2 IS SURVIVABLE BY ACCIDENT, AND SHOULD BE KNOWN AS SUCH.** A `return` inside an inlined
  callee degrades (*"it would branch to the enclosing function's epilogue"*). Every fixture shows
  it. It is green today **only because a TAIL return needs no branch**, so falling through is
  accidentally equivalent. genKantParse's templates are tail-shaped naturally — fine, but that is
  an accident to be aware of, not a property to lean on.

## ⚠⚠ CAMPAIGN OPENED — genKantParse (SEQ 41, Tony, 2026-08-08). FIVE STEPS, TWO FENCES.
The assessment is **adopted**. Order: **1** Gap B in the plan layer · **2** the parse-arm dispatch
fixture then the migration-unit ruling · **3** genKantParse v1 · **4** the adjudicator, before any
rule crosses · **5** parallel jit-ladder work (E2 rung, scale fixture, not-gated sweep).
**FENCES, exactly two:** the **Gap B charter precedes Gap B edits** (director's), and the
**migration-unit ruling follows the parse-arm fixture**. Everything else is Clod's discretion.
**Victory condition, stated so it is not re-litigated:** *not* "the same parse, generated" — **a
compiled parser with the grammar folded in**. Generation is **partial evaluation of the parser
with respect to the grammar**; the JIT compiles the frozen form. Full text: `ipc/clod-to-clay.md`
SEQ 41.

## ⚠⚠ STEP 2 IS ANSWERED AND THE ANSWER IS **NO** — the fence earned its keep on first use
`genLadder/mixed.sh` (new, pinned, exit 0). **Parse-arm dispatch is NOT uniform.**
```
    variant   installed                '(a)'      '(i)'
    none      (interpretive)           ScafALT    ScafALT
    leaf      ScafA ScafI              NONE       NONE      <-- child DROPPED
    alt       ScafALT                  NONE       NONE      <-- child DROPPED
    out       ScafOUT                  ScafALT    ScafALT
    all       everything               ScafA      ScafI
```
**Both PURE configurations keep the child; a MIXED one drops it** — not retagged, not
mis-parented, **gone, at exit 0, with no diagnostic.** Strictly worse than the §2.4 retag
divergence, and **new**: `tree.divergence` records a tag changing, never a node vanishing.
⚠ **So IA-0 STANDS AS WRITTEN — the migration unit stays the ALTERNATION**, and the previous
section's hopeful reading of `t1()` uniformity is **corrected**: `jitXmutual`'s **action**-dispatch
uniformity is real and **does not extend to the parse arm**. Two forks, two answers.
**Mechanism is a LEAD, not a ruling** (usual odds): IA-2's silent return generalised — the
generated arm's `promote=0` meets a label-transparent parent whose label is null, and the promote
case that rescues it interpretively sits on the **other arm**.
⚠ **Built as a DECOMPOSITION, and that is why it found anything.** *"Does a mixed config parse"*
is nearly vacuous — something always comes out. Asking whether an install **perturbs only itself**
is what exposed the loss.

## ⚠ GAP B IS 21 RULES ACROSS SIX DATA KINDS, NOT 3 ACROSS TWO (`docs/gapB-staging.md`)
Staged under fence 1 — **measurement only, no plan-layer edit made.** Every prior statement names
`NumbeR`/`ANYtoken`/`SemI` and `isGROUP`/`isSTRING`; those are **the specimens that were looked at,
not the population.** Measured: `isGROUP` 9 · **`isSET` 6** · `isSTRING` 3 · `isCOUNT` 1 ·
`isCHAR` 1 · `isANY` 1 = **21 rules, 45% of the 47 denominator.** `isSET` is **twice** `isSTRING`
and appears in no prior statement — **RULE H9 again.**
- ⚠ **§2.5 IS A PARTIAL MAP, and it is the charter's first problem.** Accumulate/iterate covers
  **8 of 21**. **Inline group (9) is explicitly NOT the iterate case** — `planTerm` classifies a
  reference as `CALL` *before* the data test and names the leftover a *"named future kind"* that
  **must not quietly become one**. `isSTRING`/`isCOUNT` (4) are in **neither** family. **Three
  constructs wearing one refusal message**; a charter sized on two shapes will meet 21 rules.
  Suggested rung order: **accumulate (8, has a spec and `testMacro` as precedent) → scalar (4) →
  inline group (9, the only genuinely new construct).**
- ⚠ **THE CASCADE IS A FRONTIER** (H9's corollary): closing rule-as-data **reveals** the next
  refusal in `Iterate`/`ANYorNum`/`UnaryXP`/`StatemenT`/`Xpress` rather than unblocking them.
  **And `ANYtoken` and `SemI` are each blocked TWICE — rule-level AND term-level — so rule-level
  work alone closes NEITHER cascade head. Both axes or neither.**
- ⚠ **PLANNABILITY AND INSTALLABILITY ARE NOW TWO SEPARATE GATES.** Gap B buys the first. After
  step 2 it does **not** buy the second: a plannable rule still cannot cross alone while partial
  installs lose nodes. **The charter should say which one it is purchasing.**

## LADDER 150 → 162, and three rows that assert defects rather than fixes
**JXT** graduates `jitXtemplate` — ticks **1→3** (cumulative on purpose, so no folded constant
satisfies both rows), oracle agrees, and **degrade PINNED AT 2**, the honest value: E2's
tail-return accident is what makes it green, so **when E2's rung lands the count drops and JXT
goes red demanding graduation.** Using the generic `rung` helper would have forced a choice
between weakening the fleet's degrade-zero rule and not landing the rung; asserting the true value
costs neither. **JXD-1/JXD-2** pin `AND`'s 139 and `OR`'s **wrong value by name**, both inverted.
⚠ **`genLadder/mixed.sh` caught itself three times** and records all three: its anti-vacuity guard
fired on **its own census** (matched `treeScratch`'s header *comment*, 5 bindings for 4 — H9 on the
guard rather than the guarded) · its first verdict was an unreadable **diff-of-diffs** when the
finding was plain in the trees · and its **PASS banner said the opposite of its verdict**,
inherited from the draft written before the answer came back. **A harness whose summary line
contradicts its own rows is the worst instrument failure available**, because the banner is the
line most readers see.

## OPEN, AND WHOSE
**Director's, in priority order:** (1) **the Gap B charter** — fence 1, and now with numbers · (2) **Gap B's brief** — still the largest thing on the
board and still the metric · (3) planB scheduled or parked, on §4's five-point recommendation ·
(4) the ungated-operator sweep · (5) `if !field;` on valued fields.
**Reconciliation (H8):** `docs/verification.md` is **untracked** — stage-1 durable, asOf
2026-08-07, VI-1..VI-7, its own SURVEY ROW open and self-graded ASSUMED. Explainable as yesterday's
output not yet committed, **but it has had no verdict** — commit / revert / named-WIP is Tony's.
`IncantForms/WorkingOn/incant++` is Tony's own working document, dirty as normal, safe to ignore.
**Flagged, not chased:** `litTo` still unimplemented · the three IA-6 abandoners
(`delimTest`, `grammarOnTheFly`, `hashProbe`) · GM-19's single audit line.

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ SEALED 2026-08-07 — the 08-07 section follows. Older vintage from here down.
# ⚠ ITS METRIC LINE (0/78) IS SUPERSEDED BY 0/47 ABOVE.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-07 — THE PARSE-CONTRACT CAMPAIGN OPENED, THE EXTRACTION LANDED,
#              AND THE FORMS ARC GREW A COMMAND, A HARNESS AND A RECIPE
# ═══════════════════════════════════════════════════════════════════════════

## WHAT IS RUNNABLE — six POPs now, two of them new
```
sh jitLadder/ladder.sh        150 checks, exit 0
sh genLadder/pop.sh            33 green / 1 parked   (the SAME 3 owned reds)
sh genLadder/recordPop.sh      48 checks, exit 0     NEW — ParsE/JiT records
sh genLadder/formsPop.sh       14 checks, exit 0     NEW — displayFill, BY PIXEL
sh genLadder/printPop.sh        9 · containerPop 11 · tree exit 0
<binary> incant/oneTest · jsonTest · kant8T · phaseA · emitAll      exit 0
```
**Metric: 0/78 installed.** Nothing regressed today; everything below either landed green or
reverted clean.

## ⚠ THE ONE PROTOCOL TO CARRY: **CONVERT, GATE, THEN INSTALL**
Earned three times today, in ascending cost. A change to the parse layer is proved against the
INTERPRETIVE arm **before** any rule is installed. When the discriminator in `aCTionInvokeArg` was
wrong it failed as **18 diagnostic lines and one moved baseline**; the same class of error two
passes earlier, un-gated, arrived as a **fleet-wide SIGSEGV**. The gate is where this campaign's
errors are supposed to die.

## THE PC CAMPAIGN — the three walls were one finding
`parse()`'s two arms never had a shared, enumerated contract. Every wall this week was a place they
quietly disagreed. PC is the ledger; each divergence gets a row, measured both arms, dated.
- **Row 1, fire-label — CLOSED (GX).** `fireLabelMethod` extracted; both arms fire the same rule
  action. Was: the generated arm's `goto generatedExit` jumped clean over it.
- **Row 2, attach — CLOSED (PC-1/PC-4).** `attachLabel` owns the attach for both arms;
  `leaveRule`'s attach removed. **The generated arm passes `promote=0` (attach-under always), the
  interpretive arm `promote=1` (legacy)** — the fork is a PARAMETER, not an inference, and carries
  IT-3's expiry in its own comment. `tree.sh` green for the first time since LA.
- **Row 3, empty-yield — CLOSED (PC-3).** `labelNO` is the return channel's third value:
  **NULL = failed · labelNO = succeeded, yields nothing · any node = succeeded, yields that.**
  ⚠ **Minted `isCOUNT` 0, and that is the whole trick.** The JIT's value channel is an **i32
  alloca** and cannot carry a GroupItem, so a non-numeric labelNO would have split the engines
  permanently. The meaning lives in **identity** (`lab == labelNO`); the numeric reading is
  courtesy, unchanged at 0, so both engines still agree and rung JV needed no re-pin.

## ⚠ IT — isTarget PROMOTION IS RETIRED AS A PARSE-LAYER MECHANISM (director)
**The parse builds one shape; opinions about shape belong to actions.** Promotion becomes opt-in in
one line: an action returns the child's label as its own yield, and attach-under plants it.
Interpretive promotion runs untouched as legacy and retires by attrition. **End state, nameable
now:** the `isTarget` predicate deletes, the promote case leaves `attachLabel`, three cases become
one — `pStuff.label +% lab`, skip NULL and labelNO, both arms, no fork.
**And the cost model beside it (IT-6, Tony's observation):** an action is ONE artifact serving BOTH
engines — the interpreter fires it through `fireLabelMethod`, the jitter calls it through the
fallback column — so **action-layer fixes are two-for-one and arm fixes pay per-arm.** Prefer the
action layer where a divergence permits the choice. Exception: an action containing an `if jitting`
fork is arm code in disguise and pays arm prices.

## WHERE THE METRIC IS STUCK, AND IT IS ONE NAMED GAP
**IA-0: the migration unit is the ALTERNATION** — all of one parent's options cross together, so the
mixed-shape world never exists. **IA-1's gate then refuses every install**, because no
reader-bearing alternation is fully plannable:
```
    InvokeArg  Braced OK · Parens OK · UnaryXP BLOCKED     <- nearest by far
    ANYorNum   0 of 2        StatemenT  2 of 5        DatA  blocked (+ NotA is not a rule)
```
- **GAP A — container terms: CLOSED TODAY (CT).** `containerTo` in the support library, `CONTAINER`
  a plannable kind classified BEFORE the reference test (a bin term is also a reference).
  Partition moved **REFUSE 99 → 97**.
- **GAP B — rule-as-data (§4.1, rung 5): OPEN, BANKED, AND NOW THE ONLY THING IN THE WAY.**
  `NumbeR`/`ANYtoken`/`SemI` refuse on rule-level `isGROUP`/`isSTRING`, cascading into `Iterate`,
  `Xpress`, `ANYorNum`, `StatemenT` — and into `UnaryXP`'s second term, which is why Gap A alone did
  not unblock `InvokeArg`.

⚠ **AND THE INSTRUMENT LESSON THAT CORRECTS ITS OWN SEQUENCING CLAIM: A REFUSAL CENSUS REPORTS THE
FIRST BLOCKER, NOT THE BLOCKER SET.** The classification walk stops at the first term it cannot
classify, so a refusal census is a census of **frontiers**. Closing a gap does not unblock the rules
it appeared in — it reveals their next refusal. **Total refusals falling is real progress and is not
the same measurement as any rule becoming plannable.** CLAUDE.md, H9 corollary.

## WHAT ELSE LANDED — capability, not campaign
- **DRAWING EXISTS, INTERPRETED AND JITTED.** `displayFill` fills a frame's rect through a style
  slot into a `CGBitmapContext`. Interpreted `r0 g0 b0 a0 → r255 g0 b0 a255`; **jitted fire 2 tracks
  a style swapped AFTER emission** (`r0 g128 b128 a255`), degrade 0, one compile — so it ran from
  compiled code. **FR §4's prediction held: the route is the fallback column, not IR emission** —
  a drawing method must be CALLABLE, not EMITTABLE. Five-seam recipe with file:line in
  `docs/formsRecon.md` §8, plus §8.6's **handover fences**.
  ⚠ Named `displayFill`, not `fill` — bear-trap #17, `fill()` is in the shared `OCframe` alias table.
- **`ParsE` and `JiT` records.** `genParse` hangs the generated source on the rule; `jitRunAction`
  hangs the post-mem2reg IR on the action. **One writer per fact**, both `noPrint`, both gated
  (`INCANT_PARSE_RECORD` / `INCANT_JIT_RECORD`, and `recordParse()` for the in-fixture door).
  **`showParse('Rule')`** prints the record — ⚠ **a command and not a kant action, because naming a
  rule in expression position INVOKES it.** `incant/showGen` is the no-preparation looksee: run it,
  edit one line, read any rule's generated method.
- **`aCTionIF` no longer SIGSEGVs on a missing statement.** `if 1;` used to exit 139 with zero
  output — **that was bear-trap #4's crash all along**, and the trap only ever described the parse
  bleed above it. Refuses loudly now, naming the three known causes.

## DOCTRINE ADDED TODAY
- **BEAR-TRAP #26 — a field with no data returns its own TAG from `.text`.** Six payments in the
  ledger, in both directions; one of them is a case where the trap made something *work*.
- **RULE H9 — a census matches the IDIOM FAMILY, not the surface form**, plus the frontier corollary
  above. Written after a census miscounted its own subject twice, in both directions.
- **A minion inherits FENCES, not just crossings** (`docs/formsRecon.md` §8.6). The recipe says how;
  the fences say when you have left it. Every finding worth having today was a fence product.

## OPEN, AND WHOSE
**Director's:** Gap B's brief (largest thing on the board — its blast radius wants its own charter) ·
the IA-0 refinement for non-rule alternation options (`NotA`) · `aCTionTokenXP`'s conversion to the
attached shape, which is specified and unblocked but pointless until an alternation can cross.
**Flagged, not chased:** `litTo` still has no implementation in the support library — the labelled
LITERAL road is a stub while the labelled CONTAINER road is now paved · guiDesign §10.0 vs §10.2
disagree about whether measurement belongs on Display (flagged at the insert, reconcilable) ·
GM-19's single audit line (`AUDIT TERM Parens [3]`) stays banked, unpinned, uncaused.

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ SEALED 2026-08-05 — the 08-05 section follows. Older vintage from here down.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-05 — KANT-8 CLOSED, `return` EMITTED, AND THE GRAMMAR CAMPAIGN OPENED
#              ON MEASURED GROUND
# ═══════════════════════════════════════════════════════════════════════════

## ✅ RULED (Tony) — **KANT-8 IS CLOSED BY DISPOSITION**
- **jitted side correct** (JRt F3, ledger row one) · **characterisation complete** (K1–K6d, deterministic)
- **interpreter repair PARKED pending the frame model**, and **strengthened by K6**: patching
  `saveLocalFields` would not touch the mutual-recursion gap; **only per-activation state kills both**
- **carrier discipline NARROWED by measurement** — valid for **direct** self-recursion (K2),
  **invalid for mutual** (K6c)
- **frame-model gate SATISFIED**, opening fixture named: **K6a's shape, jitted**

## ✅ ITEM 1 — the inlined self-call died at its cause (option **(b)**, build-on-discovery)
`jitEmitSelfCall` said `CreateCall(gJitCurrentFn)` unconditionally; a self-call inside an **inlined**
body got the **enclosing** function and replayed the driver's preamble every recursion. **The map is
the predicate**, populated by the inline-stack test at discovery. S1 extraction byte-identical · S2
names from action identity (`jit_<tag>`) · S3 restart bounded and checked · S4 entry by name · S5 rung
**JS**. H7: the pre-S3 binary exits **139 after 173,400 replays**. **Rule H5 reached the JIT ladder** —
it had never had a wall-clock cap.

## ✅ ITEM 2 — `return` IS EMITTED. **Ladder 129 → 150.**
Rung **JRt**: returned scalar 21/27 · **factorial(5)=120 through real recursion** · KANT-8's shape
jitted **42/45 with the interpreted tag asserted as an intended divergence** · mid-block return
111/222 with tail 0/999. **E3 was not real — a bare `return;` is correct by construction.** A fifth
edge the brief did not name: **a bare field read as the returned expression emitted nothing.**
**Bear-trap #25** records both oracle traps (`isCoded` routing; post-jit interpreted calls are not
clean oracles for *returned* values).

## THE GRAMMAR CAMPAIGN — opened, and at its real question
- **Population 78**, not 60 — Grokking's **60 rule members + 18 rule attributes**. ⚠ A one-axis walk
  reports 60 **and looks right**; `GrouP`/`NamE` were the tell.
- **Partition 12 PLAN / 66 REFUSE / 0 UNKNOWN**, guard-controlled, with a **role axis**
  (6 declaration-flag, 72 parsing). **`docs/phaseA-partition.txt` is corpus.**
- **`popScratch`** (was `censusScratch`) — a **sample**, never a census; `debug` is a **deliberate
  negative control**.
- **Gap #6** (flag-setting as a plannable term kind, any position) chartered to the **main line**.
- **Corpus stood up** — `docs/grammarCorpus.md`, **GM-1…GM-16**, stage-1 durability in force:
  every claim written for a reader with **no session context**.
- **Install vocabulary registered in `incant/setup`** (`parseMethod`, `parseTerms`) with the
  **consumed-check standing** in the audit family; H7 control is today's Braced SIGSEGV.
- **Rule one `Braced`: installs clean, verifies RED, parked** with a 253-line specimen.

## ⚠⚠ THE DAY'S LAST FINDING — **THE GENERATED ARM DOES NOT FIRE THE RULE ACTION**
The FU-2′ localizer worked on first use **and falsified the lead it was built to test**: `parseR`
attaches `ExpressioN` under the label, correctly named. **The fork point is elsewhere and now has
file:line** — `parse()`'s generated arm ends `goto generatedExit` (`GroupItem.twk:1050-1054`), and
`generatedExit` (`:1109-1113`) skips **`:1073-1079`, *"Success. Fire label method if there is one."***

**So Braced's red is an ACTION-LAYER divergence, not a parse divergence — the exact thing GM-6 rules
must not exist.** GM-6's isolation property is **true of the design and false of the code today**,
which the very first red exposed. **The ruling stands; it is now a work item with a named site rather
than an assumed invariant — and that is why it was worth writing down before it was needed.**
**No fix taken:** `Parens` runs first; two specimens make the pattern systemic and the fix lands
**once at the right level**.

## WHAT IS RUNNABLE
```
sh jitLadder/ladder.sh        150 checks, exit 0   … JC JS JRt + J-R
sh genLadder/pop.sh            33 green / 1 parked  (the SAME 3 owned reds)
sh genLadder/printPop.sh        9 · containerPop 11 · tree · harnessCensus (6 harnesses, 112 fixtures)
<binary> incant/oneTest        exit 0, 11 then 26 x4
<binary> incant/jsonTest · incant/kant8T · incant/phaseA · incant/emitAll      exit 0
```
**Metric: 0/78 installed** — honest, and blocked by **rule behaviour**, not by the door.

## QUEUE
**Next fire: `Parens`** (designed discriminator — same three-term shape, different action), preceded
by **FU-1** (answered: `parseTerms` is a **guard only**, define-time, GM-12a) and **FU-2′** (built:
`parseTrace` extended to `parseR`/`lit`, gated, **fleet byte-identical with the gate closed**).
**Gap #6 brief on Clay's shelf.** **Frame arc gated open**, opening fixture named (K6a's shape, jitted).
**Still open:** ipc SEQ 38 consequence 3 (the `locate` never-assertion) · the print-length defect ·
`pop.sh`'s three owned reds.

**Housekeeping:** `IncantForms/WorkingOn/incant++` is Tony's own working document, safe to ignore.

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ UPDATED 2026-08-03 — the 08-03 section follows. Older vintage from here down.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-03 — THE JIT'S LAST KNOWN CRASH DIED AT ITS CAUSE, THE SWEEP LANDED,
#              AND FOUR CONFIDENT CLAIMS DIED ON MEASUREMENTS
# ═══════════════════════════════════════════════════════════════════════════

## ✅ CLAIM JIT-0.1 — DECLARED, and written as a claim rather than a banner

**The JIT compiles the certified instruction families with interpreter parity, certified by
`jitLadder/ladder.sh` (83 checks, exit 0), asOf this reseal.** Families: assign · arithmetic ·
compare · **unary (`++ --`, new today)** · if/else · while · do · multi-statement operand reuse ·
an emitted call · the fallback column · **recursion on real frames**. Every rung compiles ONCE and
fires TWICE with the input changed after emission, so the answers are proven to come from compiled
code; every rung asserts **degrade count 0** and records the interpreted oracle beside its value.

⚠ **EXCLUDED, AND NAMED ON THE FACE OF THE CLAIM — this list IS v0.2's contents:**
- **Iterator semantics divergence.** A jitted action containing an iterator walk visits **0** leaves
  where the interpreter visits **2**. Pinned in `incant/jitJUi`; **measured pre-existing** (both the
  old and new seed gates give 0/2), and it waits on Tony's `iterT3`/trunk-arity ruling. **It is an
  interpreter question wearing a JIT fixture.**
- **IR persistence** — designed, unbuilt, next arc.
- **Inlining** — parked question, blocks nothing.

**The honest form of the parity statement, and it is stronger than a clean banner:** we do **not**
claim the engines agree everywhere. We claim **they agree everywhere certified, and the one known
disagreement is pinned and owned.**

## THE FIX — the unary crash died at its cause, not under a bandage
`jitInc`/`jitDec`/`jitNeg` had exited 139 inside `jitEmitUnary` since the 06-30 unified-emit pivot.
`runOP`'s seed gate read `if jitting && op.isOperator`, but unary operators are registered
`unary ruleMethod=` — **isUnary and isMethod, NOT isOperator** — so dispatch took the `isMethod` arm
and **no operand was ever seeded**. `jitEmitUnary` derefs `target->jitData` unconditionally, so the
miss was a SIGSEGV rather than a wrong answer.

```
    if jitting && (op.isOperator || op.isUnary)
```
**`isUnary` is the precise gate** — widening to `isMethod` would seed an operand for every rule
method in the language. **No layout change** (`isUnary` was already in `.twk`, `.h` and
`groups.ext`). Now 14 / 12 / -13, degrade 0, pinned by **ladder rung JU** (+7 checks, 76 → 83).

**What made it VERIFIED rather than inferred** — the corpus had graded the cause `inferred` for four
days and wrote its own graduation criterion. A **debugger probe** closed it:
`gJitSeeded.size() == 0` at the crash, with `gJitBuilder`/`gJitCurrentFn`/`gJitResultSlot` **all
non-null**. That last line **refuted the rival hypothesis by measurement** — "the emit context is not
set up on the newly-live `jitRunAction` path" predicts a null builder — so the shared-prologue design
question it would have raised never arose.

## THE SWEEP — and the disease was nastier than the one we thought we had
`oneTest`: 5 × `generateCode failed` → **0**; `maximus = 11` then **26 ×4**.

⚠ **`generatE` WAS NEVER THE DARK NAME.** C++ reaches it via `generator["generatE"]`, a **parent
index**. The names that went dark were **`gXpress` and `emitBC`, called by bare name from INSIDE
SIBLING MEMBER BODIES** — so the dispatched action ran and **its innards quietly did nothing**,
at exit 0. Repaired by hoisting the sibling once per body through the table that owns it (31 sites).

## ⚠ THE REGISTER LAW, STATED AS MADE
**`register` as a `noPrint` definition attribute publishes an otherwise-dark member into a registry**
— `currentRegistry` by default, `registries[name]` when the attribute carries data. Dormant prior
art, POP'd before being trusted (`incant/regProbe`, three legs): the registered entry is
bare-findable, **the unregistered sibling stays dark**, and both stay reachable through their parent.
**First production use today: `emitBC`**, with a negative control confirming `gXpress` stayed dark.

**And the rule it operates on, measured four ways:** a member is on its **parent's** list and **not**
on the registry's (`Generating` 49 entries with `generator` among them and no `gXpress`; `generator`
10 with `gXpress` among them). **`incant/vantage2x2`: two names × two vantages, ALL FOUR CELLS
DARK** — not the vantage, not the entry. **The members gate IS the mechanism**, and it is complete.

## ⚠⚠ FOUR CONFIDENT CLAIMS DIED ON MEASUREMENTS TODAY — the tally, because the pattern is the point
1. **`generatE` is the dark name** (wakeup 08-02 + briefs, carried as settled fact) — died on one
   grep. **A parent index was working the whole time.**
2. **"The gate has drifted, tools down"** — my own alarm, from leg B of the register POP. Died on
   re-measuring the real specimen. **Interrogating the failing measurement before escalating is what
   produced everything below it.**
3. **"Registry membership is not the discriminator"** — my overturn claim. **Wrong**, and so was the
   self-correction I offered after it. Both were inference; walking the lists settled it.
4. **Vantage as the discriminator** (Clay's lead suspect, offered at the usual odds) — died on the
   2×2. All four cells dark.

⚠ **AND THE INSTRUMENT THAT CAUSED #2 AND #3, worth more than any of them:
NEVER TEST EXISTENCE WITH `if x.taG;`.** A GroupField accessor returns a **fresh temporary field of
property text**, so it is **truthy whether or not the lookup found anything**. Use `if x;`. This is
in project memory already and was used wrongly anyway; it survived two fixture rewrites and produced
a false tools-down alarm that would have sent Tony hunting corrupted lists — **his least favourite
quarry, and there was nothing there.**

**The standing asymmetry held again:** structural claims survived, causal claims died 4-for-4.

## ERRATA AGAINST THIS FILE'S OWN EARLIER SECTIONS
- **"`groups.ext` changes have NO COMMIT TRAIL"** (said three times below) — **false.** It is
  **tracked in the support repo** (`~/data/support`, its own git, 5 commits naming the file).
  Bear-trap #11's practical warning stands — *this* repo's history will not save you — but the
  **distrust-the-audits corollary was overdrawn.**
- **The `generatE` diagnosis** in the 08-02 section — superseded by the sweep above.

## ⚠ A LATENT FINDING NOBODY WAS LOOKING FOR — `oneTest` RUNS ONE SECTION OF SIX
`incant/oneTest` has **six `stop()` calls** and terminates at the **first**, on line 31. **32 lines
below it never execute** — including `testUnitTests()` and the GUI-utilities section. Verified by
marker: `hello world`, `dumpBC for`, `testGXLeaf`, `Unit Tests`, `printDefinition` all appear
**zero** times in a full run.

**This is `jiquery`'s disease (RULE H2's own worked example) sitting in the project's PRIMARY
BASELINE**, and it means `oneTest.base` certifies only the five `generateAction` rows. **Whether the
later sections are deliberately parked or a debug `stop()` was left in is Tony's call** — reported,
not touched. It also corrects today's own census: the four `dumpBC` calls were **`stop()`-dead, not
bare-lookup-dead** (deleted today per Tony's ruling; the baseline did not move, byte-identical).

## WHAT IS RUNNABLE
```
sh jitLadder/ladder.sh       83 checks, exit 0   J1..J7, JE, JF, JP, JPd, JU + J-R
sh genLadder/pop.sh          32 green / 1 parked  (2 documented reds, see below)
sh genLadder/printPop.sh      9 checks, exit 0
sh genLadder/containerPop.sh 11 checks, exit 0
sh genLadder/tree.sh                     exit 0
<binary> incant/oneTest      exit 0, ZERO `generateCode failed`, 11 then 26 x4
```
⚠ **`pop.sh`'s two reds are still deliberately unpinned.** `census.target` (genParse refuses to plan
`MemberS` — a capability regression tangled with a deliberate grammar change; **they want separating
before either is pinned**) and `oneTest baseline` — **whose bytecode-emit half is now FIXED**; its
remaining 9-line diff is **only** the already-signed audit movement (the three named terms
`JSONtoken[1] JSONblock`, `JSONvalue[1] JSONblock`, `JSONvalue[2] JSONarray` plus the `pROPERTIEs`
index shift). **The re-pin is its own act and was deliberately not taken today.**

## ✅ RULED 2026-08-03 (Tony) — TWO PRINT FORMS FROM ONE WALK
**display** — today's behaviour, `noPrint` attributes elide, the default **for eyes**.
**fidelity** — **`noPrint` attributes SURVIVE**; the archive persists this and the round-trip oracle
runs against it.

**The law line:** *a form meant to be **re-read as definition** must be **fidelity**; a form meant
for **eyes** may elide.*

**Why it was forced:** the archive persists entities **through the print form**, and **re-reading a
printed definition is defining.** A `noPrint` `register` that vanished at print **never fires on
re-read — a lit member comes back dark.** Byte-identical storage, different citizen. It also closes
a real oracle blind spot by construction: `register` is consumed silently and does not echo in
`printDefinition`, so a round-trip POP is blind to it — but **the archive prints what survives,
because fidelity is *defined as* what survives.**

⚠ **PREREQUISITE, TONY'S** *(⚠ corrected 2026-08-03 — the first wording was wrong in a way that
changes the fix)*: `aCTionDefinE` does **NOT delete** a `noPrint` attribute that has a method — **it
never ATTACHES it.** `ruleActions.rtn:207` runs the method inside `if noPrint && immediateACTION`
and falls past the `else` that would attach it; the source comment says so outright (*"item gets run
but is not added to the new group"*). **"Stop deleting" and "start attaching" are different edits**,
and only the second exists. Fidelity print needs those attributes present, so this must change
before the fidelity form can round-trip. Named now so it is not discovered at build time.
Nothing builds today; the flag is parked at the site (`docs/supportMinion.md` TASK 2).

## NEXT
0. **Fire order is ruled: FORMS BEFORE SEARCH** — the forms corpus carries **43 measured
   `register`-as-attribute uses**, so search's question 3 inherits a real population instead of a
   hypothetical. Forms fires once support's census legs settle and the channel is judged clear.
1. **Minions.** Three charters are shelf-ready (`docs/formsMinion.md` added): `docs/supportMinion.md` (recon → Buffer compress +
   registry → Display; TASK 0 is a verbatim floor-snapshot commit; NO GRINDING) and
   `docs/searchMinion.md` (the first **design** minion — five questions of search law, deliverable is
   a proposal with no oracle, judged at Tony's gauntlet). **Stagger the firing** so two minions'
   pause-and-ask traffic does not interleave in one relay channel.
2. **The disposition sorting** — `docs/bareLookupCensus.md`, 39 sites. Unblocked now that
   *"register it"* has a known meaning.
3. **The census signature** / separating the `MemberS` regression from the grammar change.
4. **`checkSkip` capture** — lower-level scan, not a callback (Tony's ruling).

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ UPDATED 2026-08-02 — the 08-02 section follows. Older vintage from here down.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-02 — THE DAY THE FLEET STARTED TELLING THE TRUTH. FOUR DEFECTS FIXED,
#              ONE ENTIRE ARC BUILT AND THEN DELETED, AND THE INSTRUMENTS WON
# ═══════════════════════════════════════════════════════════════════════════

## IF YOU READ NOTHING ELSE — five things, in the order they will bite you

**1. `tok sourceFile directivesFile` — THE DIRECTIVES FILE IS AN ARGUMENT.** A bare
`tok GroupRules.twk` applies **ZERO** directives and says nothing about it: no warning, exit 0,
and the injected code simply is not in the output. So a retok **silently strips every directive**
unless the file is named on the command line. This cost a full bisect — the directives vanished,
reverting `groupDirectives` did not bring them back, and the edit looked guilty because the edit
was the only thing in the search space. **It was never the variable; the INVOCATION was.**
⚠ **BUT THE DEFAULT IS BARE — cross-annotated 2026-08-05, because this item and the 08-02
"diagnostic trace off stdout" fix below point OPPOSITE WAYS and the fork has now cost a rebuild in
each direction.** `groupDirectives` carries ~10 `active` hooks, so naming it injects live `cerr`
trace into ordinary runs. Use `tok GroupRules.twk` **bare** for any build whose output a POP,
baseline or measurement will be read from, and for anything committed; name the directives file
**only** for ephemeral instrumentation, and then neither measure a POP on that binary nor commit
its `.mm`. Full discriminator table: `CLAUDE.md` bear-trap #23. **A trap explaining how to turn
something ON is not a ruling that it should be on.**

**2. NAME IT BEFORE YOU USE IT.** A reference term resolves by *sharing the definer's child
list*, so a name that does not exist yet mints an empty stub that **never becomes a reference**.
Forward-declare then flesh out:
```
    JSONblock isRule;      <- two lines, and they retired an entire arc
    JSONarray isRule;
```
Symptoms when you get it wrong are TWO and they look unrelated: genParse plans `LITTO` where it
should plan `CALL`, and the *first* parse fails while a later identical one succeeds.

**3. ⚠ AN INCANT ACCESSOR IS NOT A tok ACCESSOR, and the failure is displaced by three files.**
`listLengtH` is incant; in a `.rtn` it produced bear-trap #10's exact signature — `Expected } or
statement` / `FAIL Body3` / `Expected a semi-colon` — which **cascaded and wiped GroupRules.h's
extern block to ZERO**, surfacing as `no member named 'opEQ'` in `Bytecode.mm`. tok exited 139.
Use `groupList` / `contents()`. **The extern canary (`grep -c '^extern' GroupRules.h`) is what
caught it** — check it after every retok.

**4. A HANG IS USUALLY NOT A HANG.** Two separate impostors met today: the **Swift backtracer's
interactive prompt** (`Press space to interact… (30s)`) makes a SIGSEGV look like an infinite
loop — `SWIFT_BACKTRACE=enable=no` turns it back into an honest 139; and **copying a binary over
the signed one gets it SIGKILLed** (137) by macOS, which reads as a timeout. Re-`codesign
--force --sign -` after any swap.

**5. rStuff IS BEAR COUNTRY (Tony, and he is right).** `parse()`'s first act is
`getStuff(pStuff)`. Anything wired in beside it crashes in ways that do not name themselves —
null `groupBody` in `addGroup`, via `parse → testAttributes → parse`, with **zero bytes of
output**. If a change touches rStuff, expect the failure to arrive somewhere else entirely.

## WHAT IS RUNNABLE — five POPs
```
sh genLadder/pop.sh          32 green / 1 parked   genParse ladder + baselines + iterators
sh genLadder/printPop.sh      9 checks, exit 0     print family, fully green
sh genLadder/tree.sh          exit 0               §2.4 divergence unchanged (OPEN, not broken)
sh genLadder/containerPop.sh 11 checks, exit 0     NEW — testContainer + Buffer::shorten
sh jitLadder/ladder.sh       76 checks, exit 0     J1..J7, JE, JF, JP, JPd + J-R
```
⚠ **`pop.sh` reports FAILED on 2 reds that are DELIBERATELY UNPINNED** — see "TWO REDS" below.
Everything else is green. The parked count is down from 4 to 1.

## THE FOUR FIXES

**`testContainer` — LONGEST-ENTRY MATCH.** The greedy scan over the container's *character set*
is an UPPER BOUND, never the answer: set membership can say "this character could belong to some
entry", never "is this prefix an entry", because a set has no notion of where an entry ends. Any
container holding both a symbol and a word poisons the symbol with the word's letters. `Operators`
holds `negate` and `modedOP`, so `n e g a t m o d` are all in its set and **`9 -grup` scanned
`-g`** — an entry of nothing — taking the enclosing statement's parse with it, silently, at exit 0.
Now the buffer backs off one character at a time (`Buffer::shorten`, new, mark-unaware on purpose)
until it IS an entry or is empty. **Same disease class as the ShortcuT `+`-merge that sank `,`:
set-based character grouping making token decisions. Two specimens; the class has a name if a
third surfaces.**

**Forward references — and the fix is grammar, not machinery.** See item 2 above. jsonTest went
11 ok / 2 FAIL → **13 ok / 0 FAIL**, and its baseline is byte-identical again.

**Iterator refusal — announced once, poisoned, and the advance is the only reader.** A refused
`iterate` returned 0 *before* setting `isIterator`, so `while ++grup` missed `opPlusPlus`'s
iterator arm and fell through to the **DATA** arm — `if !data count = 1;` returns the node, which
is truthy, **so the loop could never end**. Now `aCTionIterate` announces once at the door and
sets `fLAG`; `++`/`--` gate on it before any advance work; the `while` is untouched.
**THE RESET LIVES ON `aCTionIterate`'s SUCCESS PATH** and nowhere else — the poison means "the
LAST iterate on this node was refused", so a fresh successful iterate is exactly what clears it,
and re-running the Iterate rule is now the only way to change a source. `iterT1m` went from HANG
to exit 0. Uses the existing `fLAG`, so **no layout change** — no `groups.ext`, no `tokall`.

**Diagnostic trace off stdout.** Three POP targets were broken by an *instrument*:
`printFamily.target` diffed `0a1,288` and `printFamilyNew.divergence` `0a1,292` — lines
**prepended**, zero content divergence. Cause: directive hooks tracing with `cout`, which is never
divertible. All 47 sinks in `groupDirectives` are `cerr` now (not just the 3 live ones — the other
44 are landmines for whoever flips a `ctive` to `active`), and the `.mm` are retok'd without
directives at Tony's word.

## ⚠ THE ARC THAT WAS BUILT AND THEN DELETED, and why that is a good outcome

A whole deferred-repair mechanism — `finalizeRegistry`, `finalizeRegistries`, `finalizeIfDirty`,
`registriesDirty`, `markRegistriesDirty`, a dirty flag, a `currentDefine` gate, two reader entries
— was built, made to work on the census half, and then **deleted in favour of two lines of
grammar**. Trail: `3957233 / 713d45f / 8bb989e`, superseded by `c8d38f6`.

**Read this before rebuilding any of it.** The arc was not wasted: it produced the measurement
that made the two-line fix findable (`incant/termScratch` showing three sibling options of ONE
alternation split by nothing but declaration order). But **the deletion was licensed by a probe,
not by optimism** — the census was re-run with the sweep disabled and still read `CALL`, because
*"the fix works"* and *"the old machinery is redundant"* are different claims and only the second
justifies a deletion.

**Three hypotheses died in that arc, each on one measurement, and the pattern is the lesson:**
- *"identity — the readers see different nodes"* → pointer probes: **same GroupItem, same
  GroupBody, both readers.** Killed.
- *"the write does not stick"* → probe right after the assignment: `kids=1`. **It stuck.** Killed.
- *"the hook site is wrong, find a better one"* → true but unfixable, because **input lifetime and
  define lifetime are independent**. popInput was too late (only the 10 base registries exist at
  include-pop); pushInput crashed. That is the same fact from both ends.

## TWO REDS LEFT, BOTH DELIBERATELY UNPINNED — pinning either would freeze a real defect
- **`census.target`** — the diff is now ONLY Tony's `MemberS ':'- MEMBERs- Mlist=DefinE+;`
  rewrite, but **genParse now REFUSES to plan MemberS**. The grammar change is deliberate; the
  planner losing a rule is a capability regression. **Those two want separating before either is
  pinned.** Tony's signature.
- **`oneTest baseline`** — the audit movement plus **`generateCode failed`: the whole bytecode
  emit is gone.** `generatE` (`incant/generate:233`) sits one indent deep — a MEMBER — and is
  reached by bare lookup, which the new members gate no longer serves. **That is the bare-lookup
  sweep's first fix, not a re-pin.**

## NEXT, in order
1. **The bare-lookup sweep**, gXpress first. Grep the tree for every site that locates a
   member-depth name by bare lookup and fix the population in ONE pass — the gate's blast radius
   becomes a counted list instead of a series of ambushes. `oneTest baseline` goes green with it.
2. **The census signature** (or the separation above).
3. **`checkSkip` capture — LOWER-LEVEL SCAN, NOT A CALLBACK** (Tony's ruling). One skip/consume
   primitive that understands quoted strings and comments, with BOTH `checkSkip` and `aCTionCodE`
   routing through it. A callback bolted onto `checkSkip` leaves `aCTionCodE` to grow its own
   quote-awareness later — two implementations in one subsystem. **This retires `CLAIM KANT-40`
   by construction**: an action containing a comment containing `}` survives capture and runs.
   C++ now, kant at self-hosting.
4. **Timed green pass → per-block POPCAP budgets** at measured-time × margin. The 90s default is a
   courtesy allowance, not a target.

## TONY'S OFFLINE WORK THAT LANDED TODAY (his words, kept because they explain the fleet)
- **Iterators finished.** They filter on attributes or members, triggered by whether the iterator
  `isAttribute` or `isMember`. **Resetting an iterator is REMOVED from `:=`** — to change a source,
  run the Iterate rule again. All the unused `iterWhatever` methods were removed rather than
  updated for changes not worth making.
- **The attribute-pollution fix**: `aCTionDefinE` did not gate on member processing.
  `aCTionNewGroup()` sets `currentDefine`; `processFlags()` gets a `MEMBERs` toggle from the
  `MemberS` rule setting an `addingMembers` flag that `aCTionDefinE` gates on. So
  `MemberS ':'- MEMBERs- Mlist=DefinE+;`. **Note the consequence, and it is load-bearing: if
  `currentRegistry.isRule` members get added to it; if not they are NOT added to the
  currentRegistry and so are not found by `locate()`.** That is what `generateCode failed` is
  downstream of.
- Still open, his: mutual recursion loses locals (`iterT1m` pins the wrong answer at 14 lines
  where 7 is correct) · `iterT3`, the last parked fixture.

## DOCTRINE ADDED TODAY
**RULE H5 — A FIXTURE MUST NOT BE ABLE TO DELETE THE REST OF THE SUITE.** `iterT1m` began to hang,
so `pop.sh` never reached its summary, its exit status, or the eleven checks below the iterator
block. Those checks did not fail and did not pass — **they ceased to exist**, and the operator
sees a terminal that is merely quiet. Worse than the missing-sentinel case, because there is no
output to be suspicious of. **And the fixture that did it was a PARKED one**: parking bounds a
VERDICT, and it never contemplated a fixture bounding nothing at all by never returning. So every
fixture runs under a wall-clock cap, and **a timeout fails the suite even when parked** — a hang
is not a wrong answer, it is the absence of a run, and nobody parked that.

**A PARKED PIN THAT STARTS PASSING MUST GRADUATE.** `WOKE` fired twice today and both fixtures
came off the list. Parking means *"the answer has not been chosen"*; once it is chosen the item is
either a full check (`iterT1`, whose original target held byte for byte) or a deliberately pinned
known defect (`iterT1m`, the `tree.divergence` pattern) — **never still parked**. A pin that
silently begins to hold is how a parked item becomes a forgotten one.

**A RE-PIN NEEDS A SENTENCE, NOT A GREEN DIFF.** Both of today's "probably fine, just re-pin it"
candidates came back **regression** on one grep each. The audit's `15 → 12` was signed only once
the three vanished terms were *named* (`JSONtoken[1] JSONblock`, `JSONvalue[1] JSONblock`,
`JSONvalue[2] JSONarray`) and explained. **Without that discipline both breakages would have been
frozen into the baselines as truth.**

**PRIOR ART BEATS SPECULATION.** The forward-reference fix was two lines that a worn path already
sanctioned, reached after a day of armchair analysis about fill-in-place and cycle depth. Tony's
call — *"act like it won't until it do"* — was right, and the experiment answered in under a
minute. **When a question is measurement-shaped, measuring is cheaper than deciding it is safe to
measure.**

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ UPDATED 2026-08-01 — the 08-01 section follows. Older vintage from here down,
# still broadly accurate, just no longer the top of the story.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-08-01 — THE LONGEST DAY IN THE RECORD. J-R WENT GREEN, THE CONVERSION
#              ARC OPENED AND RAN TWICE, AND THE NUMERIC TOWER GOT ITS RULINGS
# ═══════════════════════════════════════════════════════════════════════════

## IF YOU READ NOTHING ELSE — five things, in the order they will bite you

**1. `cerr` AND `cout` ARE NATIVE STATEMENT KEYWORDS.** Three sinks, three different things:
`print` is DIVERTIBLE (buffer if armed, else stdout); `cout` is NOT (always stdout); `cerr` is
NOT (always stderr). Neither `opCout` nor `opCerr` consults `toBUFFER`, and **in both cases the
missing test IS the feature** — adding it back to `opCout` restores KANT-23 exactly. Fixture
`incant/sinkT` pins all three under an ARMED diversion, the only condition that tells them apart.

**2. THE JIT NOW DOES RECURSION, ON REAL FRAMES.** `J-R` is green — factorial through an
**emitted self-call**, fired at two depths (6→24), plus `jitJRL` where a LOCAL read *after* the
recursive call returns proves per-activation storage (5→9; aliased slots would give 4→6).
**Depth-1 passes on aliased slots and depth-N cannot**, which is why both depths are asserted.

**3. ⚠ INLINING IS THE CALLING CONVENTION, BY CONSTRUCTION.** A non-recursive jitted call is
INLINED — emit-on-walk re-executes the callee's BlocK into the caller's builder, so there is no
`call` instruction at all. Only a SELF-call gets a real call, because inlining one cannot work.
Zero call overhead, mem2reg optimises across dissolved boundaries, and **small composed actions
are the FAST idiom** — which the conversion arc should know, since it is minting that population.

**4. THE CONVERSION ARC IS OPEN AND HAS RUN TWICE.** Order ratified:
`emitMany` → `countRuleTerms` → `printPlan` → `emitPlan` → `unresolvedTerms` → `planRule` →
`planTerm`. **Conversion 1 is CLOSED** (kant `emitMany` answers through the seam, `rung5.target`
byte-identical, `MANIER kant` pinned). **Conversion 2's kant is written and NOT wired** — see
OPEN below, it is blocked on a real ordering problem.

**5. ⚠ A CLOSE-BRACE CANNOT APPEAR ANYWHERE IN AN ACTION BODY — INCLUDING IN A COMMENT.**
`aCTionCodE` scans for the first one with no quote awareness and no comment awareness.
`CLAIM KANT-40` was earned by writing a comment *explaining* this, which contained the character,
which ended the capture. The whole action vanished at exit 0. **Do not write it in any form,
including while describing it.** Emitters carry `closeBrace="}"` as a define-line trait instead.

## WHAT IS RUNNABLE — four POPs, all exit 0
```
sh genLadder/pop.sh        29 green / 5 parked-WIP   genParse ladder + baselines + conversions
sh genLadder/printPop.sh    9 checks                 print family, now fully green
sh genLadder/tree.sh                                 §2.4 divergence unchanged (OPEN, not broken)
sh jitLadder/ladder.sh     76 checks                 J1..J7, JE, JF, JP, JPd + J-R
```
⚠ **"5 parked-WIP" IS THE CLEAN STATE, NOT DEBT.** The five iterator fixtures are pinned to an
OLD design; Tony reworked iterators offline and their semantics are his. They re-pin when his
work lands, as part of it. **A `WOKE` alarm fires loudly if one starts passing** — negative-
controlled, so it is known to work.

## THE LANGUAGE MOVED — rulings implemented today
- **`/` PROMOTES.** `10/4` → `2.5` typed double. **Always** a double, including `8/4` — because
  premise 1's datA-stability contract forbids a result type that depends on runtime values.
- **Narrowing rounds HALF-UP, uniformly**, in ONE place: `getCount`'s `isNUMBER` arm. Not
  `lround`, which rounds half away from zero and disagrees on negatives.
- **Compound assign computes in doubles and narrows the RESULT**; the **binary family PROMOTES**.
- **`arrondir(x)`** is explicit rounding. ⚠ Named in French deliberately: `round` is libc and an
  `extern "C"` clash is bear-trap #12. **Borrowing a word from another language beat inventing
  one** — it removed both the collision and the `=method` indirection.
- **`||` is registered** (`'||' operateMethod=opOR`). ⚠ **It EVALUATES BOTH ARMS** — structural,
  an operateMethod receives already-evaluated operands. And **`!a || !b` IS NOT `if !a; or !b;`**
  on absent attributes (KANT-35) — multi-attribute presence checks MUST stay sequential.
- **`isRulE` has its opDot case.** ⚠ The fix was TWO lines, not one: unnumbered GroupFields
  entries get no index at all, so they hit the `default` arm. Ten more are in that state.

## ⚠ OPEN, AND WHOSE

**Blocking conversion 2 (foreman's, needs one measurement):** `parseRuleMethod` calls
`countRuleTerms` at **DEFINE** time, but `genScratch`'s `search … list;` runs AFTER the define
block — so a `locateCounter` fork would find nothing at define time and **the binder would run
C++ while `planRule` ran kant**. Two implementations in one subsystem, which that method's own
header forbids. Fixture ordering is the remedy. **Do not land the fork before settling it.**

**Tony's:** the T6 generation assessment (below) · the iterator semantics · the name-scope
pollution fix (`docs/nameScopeRecon.md`) · the `ruleOrRefuse` convention change.

**Foreman's, parked demand-driven:** the `}`-scan and quoted-whitespace gaps. Neither blocks
anything; they jump the queue with a specimen attached.

## T6 — THE GENERATION ASSESSMENT, awaiting Tony's go (`docs/jitDesign.md`)
**34 ops carry an `operateMethod`; exactly TWO have a `switch(data)` dispatch tree.** So
`opPlusEQ` — the probe — is the OUTLIER, not the exemplar. Answer is **per-family**: GENERATE the
comparison six (character-identical but for three slots, and generation closes §3.5's bypassed
null-guards by construction); SHELLS for arithmetic + compound assign; DON'T for the ~20
structural ops. **15 ops still carry the top-gate shape T1 condemns**, ~1 mechanical edit each.

## INSTRUMENT LESSONS PAID FOR TODAY — all three were the harness lying
- ⚠ **`pop.sh` called `sentinel` without defining it.** Copied the idiom, not the helper. Every
  run printed `command not found` and CARRIED ON — the check did not pass, did not fail, **it
  ceased to exist**. H2's own failure mode inside the harness that enforces H2, and the second
  instance after `jiquery`. Found by minionA, which deliberately did NOT fix it because the brief
  pinned the count.
- ⚠ **A negative control needs its own negative control.** Renaming a sentinel to
  `MS SENTINEL-BROKEN` still passed — `grep -F` matched it as a SUBSTRING.
- ⚠ **A number written without measuring it is a lie in the ledger.** One commit says
  "jitLadder 78/78"; the real count was 76.

## THE MINION HARNESS — two rounds, both strong
Round 2 (`emitMany`) and round 3 (`countRuleTerms`) both held the carve-out exactly: kant only,
no `tok`, no `xcodebuild`, no `groups.ext`. **Round 3 hit no obstacle a corpus claim should have
prevented** — the corpus worked as an instrument. Its own headline: **a double-quoted literal
SPANS NEWLINES**, so ten `cerr` statements became one and the emitter now looks like the C++ it
emits. That was Tony's instruction and it held.
⚠ **A crash autopsy (KANT-25) found the loss from a mid-round 500 was ZERO** — the transcript is
the persistence layer and resume reads it. **Do not build preservation machinery against it**; the
cure proposed at the time collided with the spawn rule's only-write-to-the-corpus clause.

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ UPDATED 2026-07-31 — the 07-31 section follows.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-07-31 — THE STRING EXPRESSION MOVED TO `#`, TWO LANGUAGE RULINGS LANDED,
#              AND THE JIT GREW A LADDER THAT CERTIFIES ITS OWN CLAIMS
# ═══════════════════════════════════════════════════════════════════════════

## IF YOU READ NOTHING ELSE

**`#` is the string-expression opener.** `x = #"a" "b";` replaces the old `string` keyword.
It was tried as `,` first and that had to be abandoned: `,` is already in the shortcut set
(`ShortcuT=[-+~`$_:,]+`, `incant/grammar:92`) whose `+` MERGES adjacent shortcut characters, so
a `,` inside a print had two readings — and `print "it is", maximus + 3, "done":;`, live in
`unitTests`, SEGFAULTED. `#` is not in that set. Record: `incant/hashProbe`.

**`$` is now a PERSISTENT TOGGLE.** `useDefaultSpace = true` was removed from `opPrint`/
`opString`. `processAction` resets it before each action runs, so it cannot leak *into* one, but
it survives across statements *within* one and a nested call resets it. **The safe idiom is
BALANCED `$ … $`** — off at the start of a statement, on at the end. `incant/printFamily` is
the worked example; `incant/stringT` row 4 pins the persistence itself.

## WHAT IS RUNNABLE — five POPs, all green, all exit 0
```
sh genLadder/pop.sh        30 checks   genParse ladder + baselines + branch semantics
sh genLadder/printPop.sh                print family (moving half still pinned WRONG)
sh genLadder/tree.sh                    §2.4 divergence unchanged (OPEN, not broken)
sh jitLadder/ladder.sh     47 checks    THE JIT LADDER, rungs J1..J7
<binary> incant/jiquery                 the JIT minion corpus, queried
```
⚠ **`pop.sh` echoes the binary it is testing as its first two lines.** All three genLadder POPs
used to hardcode a DerivedData path from a project that no longer exists; a stale binary does
not fail as a diff, it HANGS. They now use `${INCANT:-$HOME/bin/incant}`.

## THE JIT LADDER — the month's main artifact
`jitLadder/ladder.sh`. **Nothing in this tree had ever asserted that an ACTION, jitted end to
end, RETURNS THE INTENDED VALUE.** Each rung is the previous plus ONE construct, so a red NAMES
the construct.

| rung | adds | the claim it proves |
|---|---|---|
| J1 | assign + arithmetic | the OPERANDS are read at run time |
| J2 | if/else | the BRANCH is decided at run time |
| J3 | while | the loop RUNS THE RIGHT NUMBER OF TIMES |
| J4 | do | the body runs ONCE when the condition starts FALSE |
| J5 | multi-statement operand reuse | **attribution, not coverage** — the clobber's trial |
| J6 | an emitted call (`jitTrace`) | a call is EMITTED and runs PER FIRE |
| J7 | fallback column on a real opMethod | emit a call, GET A VALUE BACK, layout-free |

**EVERY RUNG COMPILES ONCE AND FIRES TWICE**, input changed *after* emission. A right answer
does not prove compiled code produced it — under jitting the interpreter executes the body for
real at emit time, so a naive POP goes green on an emit-time side effect. Fire 2 recompiles
NOTHING; if its answer tracks the input, the computation happened at RUN TIME.
⚠ **INJECTIVITY: the two ANSWERS must differ, not just the inputs.** J1–J6 satisfied this by
luck; J7 (`17 % 3` and `20 % 3` are both 2) is where it surfaced.
Every rung also asserts **degrade count 0** and records the **interpreted oracle** beside its
value — §0 sentences the interpreter, so the ladder banks its testimony while it can.

## THE FRAME MODEL IS NEXT, AND IT IS TEED UP
**Recon done, nothing built.** `docs/jitDesign.md` Part III.

⚠ **THE FRAME SCHEMA ALREADY EXISTS IN THE TREE** — `(isArgument || isLocal) && !noPrint`,
walked forward by `saveLocalFields` (`GroupActions.rtn:697`) and backward by
`restoreLocalFields` (`:524`). The JIT **inherits** it rather than inventing one.
⚠ **THE FUNCTION §0 SENTENCED TO DEATH IS THE ONE THAT DOCUMENTS WHAT TO BUILD.** Read it
before deleting it; do not delete until the replacement is green. **Inherit the schema, NOT the
bug** — `CLAIM KANT-8` lives in the same machinery.

**Increment 1:** schema walk at emit → one alloca per local → prologue in → locals via alloca
while **globals keep baked addresses and immediate store-through** → epilogue out.
⚠ **IT IS NOT INDEPENDENTLY PROVABLE.** Without recursion, allocas-for-locals is
behaviour-neutral. A rung can assert STRUCTURE plus a value regression net, and **must label
itself not-the-proof**. **J-R is the proof** — factorial-shaped, fired at TWO DEPTHS, because
depth-1 passes on aliased slots and depth-N cannot.

## LANGUAGE RULINGS IMPLEMENTED (Tony's, 2026-07-31)
- **A bare `return;` yields the PRIOR statement's value.** An action's value is the value of the
  LAST EXECUTED STATEMENT; `return` means *stop*. It used to yield the string `"return"` —
  KANT-10 leaking through `aCTionBrancH`. Fixture `incant/retProbe`.
- **`break` is CONSUMED by the innermost loop** and propagates nothing, so statements after the
  loop run. It used to make post-loop code unreachable. Fixture `incant/loopBranchT`.
- ⚠ Both share a structural root — **the VALUE and the BRANCH SIGNAL ride the same node** — and
  both are retired at crossover rather than fixed, because in IR a `br` carries no value.

## RULES ADOPTED THIS MONTH (CLAUDE.md Testing)
**H1** a harness echoes its binary · **H2** every harness asserts its own completeness with a
sentinel unreachable except through the final section · **H3** assert what only moves when the
answer moves · **H4** presence-with-value, never absence-of-message (fleet-audited, no
conversions owed) · **E1** a bracketing emitter leaves nothing in flight · **one channel, one
meaning** · **prefer a structure that makes the failure unconstructable** · **retirement by
mapping** · **in a demolition arc the recon is how you learn what the condemned code knows**.

## OPEN, and whose
**Tony's:** the crossover ruling (degrade loudly?) · `sink=`'s run-time half (the define-time
half is cheap; `definingRule()` cannot reach a rule from a parsed instance — `ipc/clod-to-clay.md`
SEQ 36) · `knownErrors.md` KE-1/KE-2 · FormaT does not fire, and when fixed its lead character
should be `%` not `#`.
**Mechanism curiosity, blocks nothing:** why seeding happens per use against bear-trap #9, and
why a `do` body is not block-wrapped where a `while` body is (`openWalkStructureReads`).

## ⚠ THE INSTRUMENT THAT CHANGES HOW YOU DEBUG
```
INCANT_JIT_DUMP=2 <binary> incant/<fixture> 2>&1
```
**Mode 2 is PRE-mem2reg — the EMITTER'S OWN output.** Mode 1 cannot tell you whether the emitter
emitted something or the optimiser produced it, which is the first question any emitter failure
raises. The result-slot clobber was invisible at `=1` because folding hid it.
And **`jitTrace(field)` is the print that survives jitting** — `print` fires at EMIT time under
jitting and reports compile-time state once: **it appears to work and it lies.**

# ═══════════════════════════════════════════════════════════════════════════

# ⚠⚠ UPDATED 2026-07-30 — the 07-30 section follows.
# Everything from `# ⚠ UPDATED 2026-07-29` down is 07-29 vintage and still accurate; it is
# just no longer the top of the story. CLEAN STOP, tree clean, both POPs green.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-07-30 — TWO MINIONS RAN, THE JIT GOT ITS FIRST INSTRUMENTS, AND
#              "EXIT 0" STOPPED MEANING SUCCESS
# ═══════════════════════════════════════════════════════════════════════════

## THE ONE THING MOST EXPENSIVE TO LOSE, if you read nothing else

**AN INCANT PARSE FAILURE ABANDONS THE REST OF THE FILE AND STILL EXITS 0.** No `stop:`
line, prior output still flushed, every assertion before the bad line still passing. It is
indistinguishable from a short, complete, successful run — and it is **worse than the
SIGSEGV case**, because 139 is at least visible.

```
A: before the bad line     <- printed
x = $"a" _ "b";            <- RunRulE: expected a method not x   (stderr)
B: AFTER the bad line      <- NEVER PRINTED
EXIT=0, no stop: line
```

**Mitigation, and every new fixture must carry it: a SENTINEL** — a known marker as the
file's last statement, asserted FIRST and by name. Absent sentinel ⇒ the run truncated ⇒
every other "ok" in it is *uninterpretable*, not merely incomplete. `genLadder/printPop.sh`
implements it and negative-controls it. Written into `CLAUDE.md`'s testing doctrine as a
third corollary.

**Its shell-level twin: `${PIPESTATUS[0]}` is silently EMPTY in zsh** (bash spelling; zsh
uses `$pipestatus`) and reports every run as passing. Take `$?` directly from the binary,
never through a pipe. **It bit three separate agents in one day**, including this one.

## WHERE WORK STOPPED, AND WHY — 35b is PARKED ON A DESIGN DECISION, not on effort

**Tony took it offline on 2026-07-30.** *"The issue here is shortcuts, I want them in; now
have to figure out how best to make that happen."* **Do not start 35b until that lands.**

The blocker, measured: **no print shortcut parses in an `ExpressioN` position.** `$`, `_`
and `,+` all fail (`ERROR processCode: <action> parse failed`). Cause, per Tony:
**ExpressioN does not deal with shortcuts — PrintXP does**, and the right-hand side of an
assignment is an ExpressioN. A design boundary, not an accident.

Why that blocks 35b specifically: its briefed oracle is "the 24 `string` call sites,
byte-identical under the omitted form." **There are 30, and 25 of them carry a shortcut**
(overwhelmingly `$` — `local = string $"t" at;`, `cellName = string $"c" r "x" c;`). Those
25 **cannot be written in the omitted form at all**, so the oracle as briefed covers 5
sites, and the 5 least representative ones.

**Three questions are open and were put to Tony** (see `ipc/clay-to-clod.md`, foot):
1. **BLOCKING** — is 35b's oracle the ~5 shortcut-free sites; or should the omitted form
   reach shortcuts (which routes `=`'s RHS through PrintXP — much bigger than "add list
   handling"); or is the oracle a *fixture* mirroring the shapes rather than converting
   live sites?
2. Does `=` want the same append/assign rule `+=` got, or does `=` always assign? *(Do not
   infer it — the amendment's own root cause was reading `=` and `+=` as one operation with
   a modifier.)*
3. `=` with a list on a non-string target: leave it (today it yields `xlInSet`, an
   **uninitialised read** — broken, not merely absent) or make it a loud refusal?

## 35a IS DONE AND IN THE PRODUCT

`field += this that and the other` concatenates. The arm sits above `opPlusEQ`'s
`isLIST → copyListTo` short-circuit and routes through `appendGroup` + `opString` — **one
call, not a loop**, because appendGroup already walks a list and an expression list answers
`isLIST`. Fixture `incant/concatT`.

- **Oracle answered empirically: there are NO `+=`-with-a-list call sites in the tree.**
  Instrumented the copyListTo arm and ran 17 named fixtures — **zero hits**. That arm is
  dead in-tree; there was no behaviour to preserve. Absence scoped to those 17 by name.
- **Append if the target has data, assign if it does not** (Tony's ruling). The guard is
  `data`, **not** "text is non-empty" — **a field with no data returns its TAG from
  `.text`**, so an unguarded pre-load would concatenate onto the field's own name.
- Trailing space under default spacing is **the user's to deal with** (Tony). A shortcut
  that backs up over one is a noted maybe, not scheduled.

## THE RULING TONY OWES, AND IT IS BIGGER THAN THE ITEM THAT SURFACED IT

**`CLAIM KANT-22` — KANT HAS NO STATEFUL RECURSION.** Both routes barred, different reasons:

| route | state across the recursive call |
|---|---|
| named self-call | **does not compile** (KANT-6, exit 139, re-tested 07-30 and it holds) |
| `this(...)` | compiles, **locals SHARED** — inner overwrites outer's (KANT-7) |

Neither claim is new. **The conjunction is**, and it was missed for a whole round because
each was filed as a fact about `spellLeaf` rather than about the language. **It bars
`emitPlan`** — which accumulates text across a walk and reads its accumulator after each
recursive call — so it **bars step 3 of the minion arc**, which nobody knew when the arc was
planned.

**Three exits: fix the self-name bar; make `this()` per-frame; or adopt the CARRIER
DISCIPLINE** — *anything that must survive a recursive call lives on a carrier node, never
in a local*. Sharing can't reach a carrier and neither can a restore. **Exit 3 costs
nothing, works today, needs no runtime change**, and under it `emitPlan` is writable in kant
right now. The warm-up workaround was considered and **rejected** by Clay: it manufactures a
configuration nothing in the product will be in.

## THE JIT HAS INSTRUMENTS FOR THE FIRST TIME

Nothing in the live tree had ever called `verifyFunction`, and no IR had ever been dumped.

- **The verifier REFUSES** (`-5`), placed *before* mem2reg so it catches the emitter's own
  output. **It is SILENT on the gIF fixtures** — and that is the finding: a branch with a
  missing merge is *valid* IR that computes the wrong thing. Validity and correctness are
  different questions.
- **`INCANT_JIT_DUMP=1` dumps the module.** Env var, not a GroupBody flag, so no bitfield
  shift and no `tokall`. **This is what produced bones:**

```
endif:                        ; preds = %then, %entry
  ret i32 99                  ; ⚠ A CONSTANT — taken and not-taken IR are IDENTICAL
```

  The **store is properly conditional** (`maximus` correctly stays 11 on the not-taken
  path); the **return value is not merged**. So the defect is precisely a missing
  return-value merge. ⚠ **This CORRECTS the record** — the stored note "IR: unconditional
  store + `br i1 true`" describes the OLD state; unified emit-on-walk fixed the branch.
  Second finding read off the dump: **field slots are `inttoptr` absolute addresses, not
  allocas, so mem2reg has nothing to promote** — the "mem2reg is the foundation" comment
  does not hold for baked field addresses.
- **`jitDegrade` lifted** — §0's "degrade to the oracle LOUDLY", which existed exactly once
  and was **inside `if result.isIterator`, a gate §0 schedules for deletion**. It carries a
  counter, which is the point: ~53 silent fallbacks become countable. ⚠ **It has NO
  behavioural coverage** — its two call sites are unreachable by any fixture, blocked by an
  open question (see below). `incant/jitDegradeT` is committed reaching its sentinel and
  **not** its target, and says so in its own header.

## TWO MINIONS RAN. Both held their sandbox; leak-checked mechanically, not on trust.

**Grammar minion (new, its own corpus `docs/grammarCorpus.md`, no frozen brief).**
- Round 1: `cout` **built** via runtime graft; `cerr` **REFUSED** with evidence (`opPrint`
  is a two-arm if). The refusal was the better half and was accepted as success.
- Round 2: the **print-family POP** (`sh genLadder/printPop.sh`, 9 checks, exit 0, its own
  script — it correctly refused to touch `pop.sh`). `cerr` rows **pinned RED on purpose**,
  `iterT1m`-style; they flip when the C++ lands.
- ⚠ **It corrected its own predecessor**: GRAM-3's byte-identical oracle was captured
  **entirely with the diversion unarmed** — the one condition under which correct and broken
  are indistinguishable. **`cout` under an armed diversion goes into the buffer.**

**Minion A round 2 is HELD**, and not on judgement: **every remaining emitter in genParse
writes its PRODUCT via `cerr`** (`emitMany` 11, `printPlan` 6, `emitPlan` 14, `planTerm` 11)
and **kant has no stderr**. Targets are captured from stderr, so a kant version cannot
reproduce its own target. `emitLeaf` was convertible only because it *returns* a String.
Pre-registration is in `docs/minionAledger.md`, difficulty confound named **before** the
round. Softened but not cleared by GRAM-6 (below).

## DOCTRINE ADDED TODAY — all of it paid for the same day

- **`CLAUDE.md`** — the exit-0 third corollary + sentinel discipline (above).
- **An ABSENCE claim must name where it looked.** `CLAIM KANT-17` said no member-filtered
  accessor existed; foreman added one an hour later, falsifying the corpus.
- **OPEN is a third shape** beside CLAIM and BLOCKED. `KANT-20`'s own scope had to call
  itself "an open item wearing a claim's clothes."
- **AN ORACLE IS ONLY EVIDENCE OVER THE CONDITIONS IT WAS CAPTURED UNDER.** A fixture that
  does not vary the discriminating condition is **silent, not green**. Three of today's
  failures are instances: GRAM-3 never armed the diversion; `spell.target` never crosses a
  renamed sink; the four baselines never reached a recursive action with a list-carrying
  local.
- **A status table is a claim with an `asOf` nobody wrote down.** `jit.md`'s Phase-1 unary
  rows say DONE; all three exit 139. **Left standing with the contradiction beside them** —
  they were TRUE when written and were falsified by the 06-30 pivot that folded out `jitXP`.
- **THE PROPAGATION FAILURE, logged in `grammarCorpus.md`:** the minion read `opPrint`
  correctly; foreman verified the *reading* and carried the *inference* further; Clay checked
  the inference against the reading. **Nobody re-derived the `'p'` test from source.** It
  took Tony opening the file. *"I verified X" and "I verified someone's reading of X" are
  different acts and read identically in a report.*

## OPEN, and whose

**Tony's:** the KANT-22 stateful-recursion ruling (three exits) · the shortcuts-in-
ExpressioN design (parked, offline, gates 35b) · the JIT seam ruling — whether the JIT gets
rung 3's walk-decides/emitter-writes shape, which is what turns ~53 undeclared fallbacks
into a countable artifact · the `sink=` proposal (GRAM-P1) replacing the `'p'` character
test · whether `=` gets append/assign · the upload bundle (`docs/jit.md`,
`docs/jitDesign.md`, TODO's JIT sections).

**Clod's, unblocked:** the `isCoded` question — a `define` in an **included** file yields a
coded field, the identical define in a **top-level script file** does not (`jitAdd` works,
`walkBag` does not). Plausibly bear-trap #15's family, **not established**. It is what
blocks coverage for `jitDegrade`.

**Still open from before, untouched:** everything in the 07-29 and 07-28 sections below.

## RUN RECIPE — what is new today
```
sh genLadder/pop.sh                      # 22 checks, exit 0 (unchanged)
sh genLadder/printPop.sh                 # 9 checks, exit 0, moving half pinned WRONG
INCANT_JIT_DUMP=1 <binary> incant/jitGifScratch 2>&1     # the IR, first time visible
<binary> incant/concatT                  # 35a, 5 rows + sentinel
<binary> incant/nameRecurse              # per-frame locals + .firsT affiliation + 403/404
<binary> incant/jitDegradeT              # ⚠ reaches its sentinel, NOT its target
```
New this day: `.firstMembeR` (opDot case 405) · `.firsT`/`.lasT` no longer segfault on a
leaf · `jitDegrade` · the verifier · the dump. **`groups.ext` was NOT touched today.**
Extern canary **203 → 204** (jitDegrade), the one addition accounted for.

# ═══════════════════════════════════════════════════════════════════════════

# ⚠ UPDATED 2026-07-29 — read the 07-29 section FIRST (it is directly below this header block).
# THE JIT REPLACES THE INTERPRETER, and 07-29 was the ITERATOR + Minion-A-harness day. The
# genParse ladder narrative that follows is 07-28 vintage and still accurate; it is just no
# longer the whole story.
#
# Incant — Status & Handoff (2026-07-28: SHAPE (SEQ 25), RUNG 4, the SEAM (SEQ 26), and RUNG 5
# (SEQ 27), RUNG 6 (SEQ 28) and RUNG 7 (SEQ 29) all landed. The walk DECIDES into a plan of
# GroupItems, the emitter WRITES from it, and SEQ/ALT/LIT/LITTO/CALL/MANY/OPT all emit. THE WHOLE
# JSON FAMILY NOW PLANS. ⚠ RUNG 7's TREE POP FOUND A REAL PRE-EXISTING §2.4 GAP — read it before
# trusting an alternation. `sh genLadder/pop.sh` is the one-command POP.
# Everything RUN with exit status checked. CLEAN STOP — see "WHERE THIS STOPPED" below.)
*Written by Clod for a fresh Clay/Clod with ZERO memory of today. Self-contained. Read fully before
touching code. Everything is on branch `jit-unified-emit-wip`; main is untouched.*

## READ THIS FIRST IF YOU ARE COLD — the one thing most expensive to lose

**A generated parse method now looks like this, and it RUNS:**
```
extern GroupItem parseScaf2(GroupItem rule)
{
GroupItem   into  = rule.rStuff.parentLabel;
GroupItem   label = new("Scaf2");
GroupItem   t1 = rule[1];
GroupItem   t2 = rule[2];
String      from  = atRuleMark;
    return leaveRule(rule,into,label,from, lit(t1,"{") && lit(t2,"}") );
}
```
One argument and it is the rule (§1.1 — kant methods take one argument). `into` is DERIVED from the
new `RuleStuff.parentLabel`, not passed (§1.2). Leaves take the TERM, not the rule (§1.4). No
`locate` anywhere (§1.3). No entry wrapper — invocation is `Scaf('x')`, exactly as `Start()` (§1.7).

**Invocation is bound in incant, and this is §4.1 ANSWERED:**
```
registry(cOMMANDs);
define parseMethod immediateAction=parseRuleMethod noPrint; ;   <-- noPrint IS LOAD-BEARING
register(Ladder);
define  Scaf  isRule "x"- parseMethod=parseScaf;  ;
```
The `noPrint` is not decoration. Without it the binding attribute lands in the rule's **own term
list** as a bogus second term, and the emitter writes a term local for it. That is §1.5's hazard
arriving from a direction nobody predicted, and it is what the first run crashed on.

## ⚠ 2026-07-29 — THE JIT REPLACES THE INTERPRETER (and everything below is 07-28)
**Tony's plan is that the JIT BECOMES the interpreter — not an accelerator beside one.** One
execution path, and in the end it is the compiled one. This was undocumented anywhere until
07-29; a cold reader derives "accelerator" from the `jitting` gate in the source and then
misreads every JIT decision downstream (Clay did exactly that on 07-29 and argued for repairing
the interpreter's frames on the strength of it). **The statement, its two consequences and its one
open ruling now live in `docs/jit.md` §0 — read that before touching JIT work.** Headlines:
- **`saveLocalFields` gets DELETED, not repaired.** Locals-as-frames lands ONCE, in the JIT. The
  07-29 per-frame fix below is a deliberate **bridge**; its fixtures outlive it.
- The iterator becomes **two stack slots** (source, current) — no heap handle, no `isIterator`
  gate. Tony's usage already reads as pointer semantics, so no language design changes.
- **OPEN, Tony's:** during crossover, what happens to a construct the JIT cannot emit yet?
  Falling back to the interpreter *is* divergence, arriving as a schedule artifact. Candidate
  answer (the one that made mixed mode safe): **degrade to the oracle LOUDLY.**
- The whole class of *"will jitted and interpreted paths diverge?"* worries is **retired** —
  there is only ever one path.

### 2026-07-29's other work, in commits (details in each commit message, not repeated here)
```
77750cd  B0: claim format + tok-claim sweep
aabf7c7  Minion A harness: spawn rule, frozen brief, empty corpus, ledger
a4b72bb  Minion A harness: SEQ 30d rulings -- deferred baseline, claim-surface closer, abort
1bf80a0  Tony's Group-A work (GUI, Debug.rtn, docs, JSON fixtures)
552d60c  Tony's runtime work: rStuff-at-define rework + the iterator source (PRE-TOK)
3a8611f  Iterator Stages 1+2: flags tok'd, Iterate rule live, aCTionIterate compiles
60b237a  GroupMain: setRuleStuff on Limit's min and max -- POP back to GREEN
8a4e94a  auditRegistry: the verifier, presence-based -- found 3 more on first run
61b2487  B0: claims name their verifier
90f6366  audit: user-driven command, both directions, populations split and PINNED
6bd1928  Stage 3 WIP: ++/-- dispatch to iterAdvance -- reached, correct operand, then HANGS
015e9e8  incant/iterScratch: the iterator hang fixture
23df1b0  Iterator WORKS: runOP must not unwrap a handle. FWD a,b,c / BCK c,b,a
6abfd86  T1 PASSES: PER-FRAME. Cause was saveLocalFields
2401b61  T1 DEEP: coexisting cursors, exact order
80e5873  T1m: recursion coverage is DIRECT-ONLY. Mutual recursion loses locals
6bd642b  := is the iterator's only reset. T3 x4 GREEN. Sweep came back EMPTY
cc8eba6  Iterators FINISHED: runaway tripwire, the gate PROVEN, T1/T3 in pop.sh
```
### ⚠ TWO LIVE OPEN ITEMS FROM 07-29, and the first is a BUG in a hot-path function
1. **`runAction` empties a returned local when `recursive` is set** (corpus `CLAIM KANT-8`).
   `restoreLocalFields` runs **after** `processAction` and before the return, so an action that
   returns one of its own locals hands the caller that local **reverted to its pre-call state**.
   Measured three ways: return a **local** → emptied; return the **argument** → survives (that
   is the idiom until it is fixed); **mint a node into a local** → emptied. So it is about *which
   slot the returned pointer is*, not node identity — and `restoreLocalFields` is not itself
   wrong, restoring the caller's frame is its job; the defect is that `result` points into the
   frame being restored. **Same function whose `saveLocalFields` was fixed the same morning** —
   a second, independent hole in the same frame machinery. `emitPlan` recurses and must return
   text, so Minion A's step 3 inherits it. **THE FIX IS TONY'S** — both candidates touch the
   interpreter's hot path. Repro: two identical action bodies differing only by an *unreached*
   self-mention.
2. **A kant action cannot return NULL across `runAction`** (`BLOCKED KANT-B1`, IDIOM-GAP, five
   attempts with output pasted). Live consequence: the kant `spellLeaf` is *loud* on an unknown
   kind but does not *refuse*, so `emitPlan` would take junk text as a spelling. Suggested first
   move, untried: return the argument with a flag stamped via `:.` and test the flag C++-side.

### MINION A ROUND 1 IS IN, AND GREEN — `emitLeaf` is kant
`incant/genEmit` holds it (registry `Spellers`, action `spellLeaf`). `emitLeaf` **forks**: with a
`spellLeaf` registered it runs, without one the C++ body runs unchanged — so absent the kant file
every target still holds. **A registered speller's answer is authoritative INCLUDING NULL**, on
purpose: a fallback would let a kant defect silently produce the right text.
- `genLadder/spell.target` is its oracle — **the C++ `emitLeaf`'s own answer**, captured before
  anything moved: 5 plan kinds × both sinks. It reaches **`LITTO`**, which no ladder rung does,
  so `litTo`/`litOption` are gated only there. **`emitLeaf`'s own refusal arm is NOT covered** —
  the walk refuses anything the emitter would, so no plan node of an unknown kind ever exists.
- `spellMode` + `pop.sh`'s **speller pin** answer "which implementation produced this", because
  the fork is silent and the target is green either way. **Pinned at `kant`** — if it ever reads
  `c++` again the kant speller stopped being found.
- **The pick's decoupling argument was half wrong, worth knowing:** `emitLeaf` was chosen partly
  as "a table, not a walk — needs no iterator." True of the table, **false of the round** — `OPT`
  wraps a term and reaching it took `iterate inner on argument members`.
- Ledger `docs/minionAledger.md` (round 1's number entered; format held). Leak check is now
  mechanical: `sh docs/minions/roundTrace.sh <transcript>`, **read its WRITE SURFACE first**.

**THE ONE BUG WORTH NOT RE-DERIVING:** `saveLocalFields` copied the locals struct *including the
list pointer* and then cleared the shared object in place, so **no local carrying a list survived
recursion — since the initial commit.** Iterators were merely the first thing to notice.
Coverage is **DIRECT-ONLY**: `field.recursive` is inferred by identity against `currentMETHOD`
(`ruleActions.rtn`), so in `A → B → A` neither action names itself, neither gets flagged, and
locals are lost. `incant/iterT1m` is that hole, committed as a **pinned wrong answer** in
`pop.sh`. The sweep for live victims came back **EMPTY** — the bug was latent.

**`pop.sh` now has 22 checks** including `iterT1`/`iterT3`/`iterT1m`, `spell.target` and the
speller pin. The four old baselines came back byte-identical across the `saveLocalFields` fix,
because nothing in them reaches a recursive action with a list-carrying local — **baseline parity
was not evidence the fix was safe.**

### CLEAN STOP, 2026-07-29 — nothing in flight, nothing half-applied
```
sh genLadder/pop.sh    -> POP PASSED, 22 checks, exit 0
sh genLadder/tree.sh   -> exit 0 (§2.4 divergence unchanged — OPEN, not broken)
```
Working tree clean; everything on `jit-unified-emit-wip`. **Tony is reading round 1's kant code
offline** (`incant/genEmit`, ~30 lines) and rules on style — the ledger's correction count for
round 1 is marked PROVISIONAL until he does.

**`groups.ext` moved today and has NO COMMIT TRAIL** (bear-trap #11, it lives outside the repo).
Added: `iterSpins`, `dumpSpellings`, `locateSpeller`, `spellMode`, `spellKant` — plus a real fix,
`emitLeaf` was declared there with **two** parameters against a three-parameter definition, stale
since the `sink` argument was added. Extern canary 198 → 203, every addition accounted for.

**genParse's recursion shape, measured 07-29 (it decides Minion A's step 3, not today's work):**
`emitPlan` does **not** recurse at all — a flat two-pass walk that calls `emitLeaf`/`emitMany`.
`emitLeaf` **already self-recurses**, directly, for `OPT`'s wrapped term. `planRule → planTerm` is
one level; `planTerm` never calls `planRule`. All are C++ externs today, so recursion is free
stack frames — the coverage question bites only once they are **converted to kant**, and the
recursion that exists is the **direct** kind, which is covered. **A nesting rung must route
recursion through `emitPlan` itself, never `emitPlan → emitLeaf → emitPlan`** — that shape is
mutual, and mutual is the uncovered one.

⚠ **NAMING:** the spec (`genParseSpec.md` §4.2) and Clay's briefs say **`emitTerm`**. The live
function is **`emitLeaf`** (`genParse.rtn`) — renamed at the rung-3 seam. There is no `emitTerm`
in the source. Minion A round 1's target is `emitLeaf`.

## 2026-07-28's commits (branch `jit-unified-emit-wip`, in order)
```
da698e8  genParseShape steps 1-2: RuleStuff.parentLabel + one-argument parseMethod fnptr
e261e5d  genParseShape steps 3-7: term-first library, parseR, indexed emit, binding, POP
5c71db4  wakeup.md reseal + import Clay's SEQ 25 brief
ec34f59  RUNG 4 GREEN: a generated rule reached through another rule's reference term
a21e8ed  wakeup.md reseal for rung 4
30b7cd6  §1 census + FIX: `!rStuff` was never a classifier, and it dropped real terms
41a3831  rung 3a: plan vocabulary + walk builds plans, emission untouched (no-op)
835b5fc  rung 3b: emitter consumes the plan; old interleaved path deleted
092f96c  wakeup.md reseal for rung 3 + import SEQ 26 seam brief
4deaa6e  scope genParse's own lookup to rule registries (§1.3 second half)
af7e43d  genParseSpec §2.2a: Invariant R′, with its provenance checked
f6c599a  RUNG 5 GREEN: MANY + Invariant R′ demonstrated
502e7d0  wakeup.md reseal for rung 5
0463d51  RUNG 6 GREEN: OPT, the inline ((term) || 1) form
15712d1  wakeup.md reseal for rung 6
0ae2923  isGROUP ordering: reference wins; inline group a named future kind
3eb8398  RUNG 7: ALT emission — and §2.4's tree POP found a real gap
a5d541a  wakeup.md reseal for rung 7
168195b  rStuff at define time: late materialisation now fires ZERO times
```
(Session tip on arrival was `23d6888`.)

## POP LEDGER — every line RUN, exit status checked (the doctrine from 2026-07-27 holds)
| check | result |
|---|---|
| `oneTest` / `jsonTest` after **every** step | exit 0, **BYTE-IDENTICAL** (11 then 26 ×4 · 13 `ok`) |
| `genScratch` | **exit 0** — emission plus all four runtime cases |
| `Scaf('x')` · `Scaf('y')` | **WIN** · **FAIL, mark UNMOVED** |
| `Scaf2('{}')` · `Scaf2('{')` | **WIN** · **FAIL, mark REWOUND** — Invariant R both directions |
| `ScafB('ab')` · `ScafB('ax')` | **WIN through a reference term** · **FAIL, mark REWOUND across a nested generated call** |
| binder count guard, deliberately mismatched | **REFUSED**, and ScafA degraded to the interpretive walk |
| emitted text vs the compiled-in methods | **byte-for-byte identical** (rungs 1-2 and rung 4) |
| `grep -c extern GroupRules.h` | **166** (was 161; every addition accounted for — canary intact) |
| `genLadder/rung12.target` | regenerated **deliberately** — every line of the frame moved |
| `genLadder/rung4.target` | new |
| `genLadder/census.target` | 30 rules, plan-level, stable across runs |
| `genLadder/rung5.target` | repetition helper + method |
| `genLadder/rung6.target` | optional reference + optional literal |
| `genLadder/rung7.target` | new — alternation + its enclosing sequence |
| `ScafOUT('(a)')`/`('(i)')`/`('(x)')` | WIN · WIN · **FAIL, mark REWOUND** |
| census after ALT emission | **moved by ZERO lines** — nothing leaked across the seam |
| `ScafE`/`ScafF` × 3 each | optional present · absent · **failing mandatory neighbour, mark REWOUND** |
| `ScafC('ac')` · `('aaac')` | **WIN** · **WIN** (three passes) |
| `ScafC('aax')` · `('c')` | **FAIL, mark REWOUND** (R across a generated LOOP) · **FAIL, mark unmoved** |
| emission after the seam vs before it | **IDENTICAL**, whole genScratch run |

Note what the runtime rows now prove that they could not before: the wrapper is gone, so a green run
means **emission + the fork + binding + dispatch** all work. The old wrapper called `parseScaf`
directly and could have passed with the binding wholly unbuilt.

## THE MEASUREMENT THAT SETTLED THREE QUESTIONS — `dumpRuleTerms`, and it is kept
§1.5 says genParse must traverse with the same accessor the emitted code reads with. Whether a
`fail` modifier or a `code={}` tail occupies a slot is a question about the **tree**, so it was
measured (`incant/termScratch`, one run) rather than reasoned about. Findings, all load-bearing:

1. `rule[i]` is source order, 1-based. **`fail` occupies NO slot.**
2. **A `code={}` tail occupies FOUR slots, not one** — `CodE`, `this`, `tempField`, and a cached
   `BlocK` that appears **only after the rule has been parsed once**. The tail of `rule[]` is not
   even stable across a run. §1.5's hazard is real and bigger than the brief supposed.
3. **All four are `noPrint`; no real term is.** So the classifier is `noPrint` — and that is not an
   invention, it is the test `testAttributes` already uses (`if noPrint continue`). Model-not-oracle
   applied to classification itself: take the oracle's own test rather than a parallel one that can
   drift from it.
4. Sequence terms are `isAttribute`; alternation options are `isMember`. One list, distinguished by
   affiliation.
5. A rule-reference term (JSONblock's `JSONfield`) is a **DISTINCT NODE** from the registry rule of
   the same name — different parent — but the two **SHARE a child list**. `rStuff`, however, is
   **per node**.
6. **No rule-reference term is `isGROUP`, and none has `onGroup` set**, before or after a parse.

Re-measuring is one command: `<binary> incant/termScratch`.

## TWO CORRECTIONS TO THE BRIEF, both made against the tree
- **§1.6's `t2.onGroup` does not exist to be written to** (finding 6). A reference term is a node
  carrying `isRule` and sharing the referenced rule's list, so it **parses directly** — which is
  exactly what the interpretive walk does (`testAttributes` calls `grup.parse(stuff)` on the term
  itself, never on a dereferenced target). `parseR` was written for parity with the oracle rather
  than as a parallel mechanism.
- **§2's `rule.parentLabel` cannot compile as written.** `parentLabel` is a `RuleStuff` field and
  `GroupItem` does not forward to it, so the emitted line is `rule.rStuff.parentLabel`. Only
  deviation from §2's literal text.

## ⚠ ONE NEW THING THAT WAS NOT IN THE BRIEF, and it is load-bearing
**`leaveRule` must tolerate a NULL `into`.** Retiring the entry wrappers (§1.7) makes a generated
rule reachable from a top-level incant call, and `runRule` invokes `rule.parse(0)` — no parent
stuff, so `parentLabel`, and therefore `into`, is **null**. The interpretive path has always guarded
this (`parse()`'s attachment block is `if label && pStuff`); the guard is now also in `leaveRule`,
one implementer down. **Without it `Scaf('x')` dereferences null on its FIRST success.** Any future
exit primitive inherits this obligation.







## WHERE THIS STOPPED (2026-07-28, end of day) — clean kitchen
**Both POPs pass. Nothing in flight. Nothing half-applied.**
```
sh genLadder/pop.sh    -> POP PASSED   (7 rung targets + census + both baselines, exit 0 each)
sh genLadder/tree.sh   -> fixture ok   (§2.4 divergence unchanged — it is OPEN, not broken)
```
Landed today: **rung 3** (the walk/emission seam, plan-as-GroupItem), **rung 4**
(`definingRule()`, resolve-at-use-time binding), **rung 5** (MANY, Invariant R′), **rung 6** (OPT),
**rung 7** (ALT emission), and **rStuff at define time** — six rungs and one structural change,
every one with the baselines accounted for and exit 0.

Fixtures that did not exist this morning: the **census** (30 rules, plan-level), **tree.divergence**,
**pop.sh** as one command, and **rung4–rung7 targets**. Two of the three defects caught this week
came from rules nobody was working on — that is the census earning its place, and the argument for
growing it as rungs land rather than treating it as done.

**Tony is reading the day's work offline.** Design changes are possible but not expected. **If any
turn up, check them against the census** — it is the only artifact that speaks for the rules you are
not looking at.

**Uncommitted and NOT ours:** Tony's Group-A files (`Debug.rtn`, `Stylish.*`, `Layout.*`, `TODO.md`,
`docs/guiDesign.md`, `CLAUDE.md`, `incant/utilities`, `incant/jsonTest`, and the `.mm` regenerated
alongside them). Left exactly as found. **Do not run `tokall`** without checking with him first —
it would regenerate `Layout.twk`/`Stylish.twk` over his uncommitted work.

## rStuff IS MATERIALISED AT DEFINE TIME — late materialisation fires ZERO times
`getRStuff`'s `no rStuff - creating` warning fired **8 times in oneTest and 6 in jsonTest**. It now
fires **zero times, in all four fixtures**. The warning stays in place as the instrument: **if it
ever fires again, WHICH rule is the interesting part.**

**Measured first, and it moved the target.** Terms defined *from incant source* already materialised
at definition — `modify` calls `setRuleStuff`, and even an unmodified term comes back with rStuff.
The real gap was **the bootstrapper**, which hand-builds rules in C++: `GroupMain`'s `Limit` adds
`"["` and `"]"` with **no `modify()` call at all**, and applies its `+`/`*` to `item.group` (the
shared `counter` rule) rather than to the `min`/`max` terms.

Two call sites, both at a **completion point** rather than per-attribute — the ordering lesson rung 7
paid for:
- `aCTionDefinE`, just before `input.clear()`, where attributes *and* members are both in
- the bootstrapper, over `grok`, before setup is parsed (setup's own rules go through `aCTionDefinE`)

It materialises the **rule node as well as its terms**. Terms alone left exactly two late sites,
`define` and `InitiatE`, both rule nodes — which is how that was found.

**Uses `setRuleStuff`, per Tony's ruling: it only ever applies to rules anyway**, so the `isRule`
propagation is correct rather than a side effect to work around, and it keeps this to one
implementer. That propagation is **load-bearing, not cosmetic**: a reference term shares the
referenced rule's member list, so `isRule && hasMembers` is precisely how `parse()` dispatches into
a referenced alternation (`GroupItem.twk:1062`) and how `checkInput` suppresses its label
(`RuleStuff.twk:139`).

### The three deliberate moves
| moved | to what |
|---|---|
| `oneTest.base` | the 8 `getRStuff` lines removed, **nothing else**. 11 then 26 ×4, exit 0 |
| `jsonTest.base` | the 6 `getRStuff` lines removed, nothing else. 13 `ok`, exit 0 |
| `census.target` | exactly two rules, both bootstrap-built (below) |

- **`CodE`** — REFUSE (2 unmaterialised) → **plans**, as SEQ with two **LITTO** terms. LITTO and not
  LIT is **correct**: `incant/grammar:42` lists `CodE "{" "}" parseAction;` with no modifiers.
- **`Limit`** — REFUSE (3 unmaterialised) → refusal **moved** to `min` being isGROUP, the named
  inline-group kind. It now refuses on honest, named grounds rather than on "cannot tell".

### ⚠ FINDING: `Limit`'s `']'-` never had its modifier applied
`incant/grammar:52` lists `Limit '['- min=[0-9]+ max?=[0-9]+ ']'- noPrint;` — with the `-`. The
bootstrapper adds `"["` and `"]"` **bare**. A real divergence between the documented grammar and the
built one, invisible until materialisation made it readable. **`CodE` is NOT such a case** — do not
"fix" it to match a modifier its listing does not have.

This also **closes open item 2 by dissolving it**: there is no longer a window in which a term is
defined but unclassifiable, so the walk's unmaterialised-term refusal is now unreachable. Left in
place deliberately — it is a guard, not dead code to mourn.

## ⚠ RUNG 7 — ALT EMITS, BUT §2.4 IS OPEN. Read this before trusting an alternation.
```
extern GroupItem parseScafALT(GroupItem rule)
{
GroupItem   into  = rule.rStuff.parentLabel;      <- NO `label` local: §2.4, an ALT builds none
GroupItem   t1 = rule[1];
GroupItem   t2 = rule[2];
String      from  = atRuleMark;
    return leaveAlt(rule,from, parseR(t1,into) || parseR(t2,into) );
}
```
The fold decides the **sink** (`into` for ALT, `label` for SEQ) and the **joiner** (`||` vs `&&`),
both emitter-side. `litOption` is the ALT spelling of a labelled literal — re-read 2026-07-28: its
first parameter is **already** the term and unused exactly as `lit`'s is, so term-first was
satisfied; only the reasoning needed checking.

**The sharp POP held: the census moved by ZERO lines.** Emission changed no planning, so nothing
leaked across the seam rung 3 closed.

### THE TREE POP FAILED, and that is the result — not a regression
```
generated     ScafOUT -> ScafA        (winner keeps its OWN tag)
interpretive  ScafOUT -> ScafALT      (winner RETAGGED to the ALT's name)
```
Cause, read off `parse()`: an alternation member is `isTarget`, and the attach block does
`pStuff.label = label; label.tag = pStuff.ruleName`. **Right language, wrong tree** — every WIN/FAIL
check passes on it, which is exactly why §2.4 was told to use a tree comparison.

**Not new and not introduced here.** `RuleStuff.twk`'s RETAGGING NOTE (2026-07-25) records the same
divergence, found when a tail action received two children both tagged `GrouP` and silently
discarded the field. It was patched **by hand** in `parseJSONfield` and called *"a gap in
genParseSpec's sub(R) semantics generally"*. The seam now makes it fixable in one place.

**And the interpretive path is not self-consistent about it:** `isTarget` is set on only **11 of 16**
measured alternation members — `JSONvalue`'s `JSONblock`/`JSONarray`, `JSONtoken`'s
`JSONblock`/`NumbeR` and `DatA`'s `DelimText` do **not** have it. So it retags some winners and not
others, *within the same rule*.

**NOT GUESSED AT.** Which tag is correct — and whether `leaveAlt` should take `into` and retag — is
a semantics decision for Tony/Clay. The divergence is recorded in `genLadder/tree.divergence`, and
`sh genLadder/tree.sh` asserts it is **unchanged**: a fixture on an open item rather than a broken
gate. Settle it and the fixture moves, and whoever moves it accounts for the move.

### GUARDS — scoped, and the recommendation is SPLIT THEM OUT, well past rung 8
`getGuard` is ~70 lines of recursive first-set computation: cycle detection (`guardInProcess`), a
stop-at-first-mandatory-attribute rule tied to `min`, member union, set/data/registry special cases.
Reproducing it at generate time is an **arc, not a rung**. Two concrete blockers beyond size, both
read off the source:
- `if isMember && parent.guardSet  parent.guardSet += guardSet` — **getGuard MUTATES ITS PARENT**
- `setRuleStuff()` on entry — **it MATERIALISES rStuff**

So calling it from the walk **re-introduces tree mutation during generation**, precisely what rung 3
established the walk must not do, and it collides with the open rStuff-materialisation item too.
Unguarded ordered `||` is correct and merely slower — the ALT above has no guards and passes — so
guards are an **optimization**. §4.3's `_` already means "emit unguarded", so the plan has a place
for the distinction whenever it lands.

### Fixture note: an alternation must be bound in a SECOND define block
A definition attribute fires **when it is parsed**, so `parseMethod=` on an alternation's own line
runs *before its members exist*; the §3 count guard then sees 0 terms and refuses — correctly. A
second `define` re-opens the rule. Sequence rules are unaffected (terms on the same line).
**The count guard caught this itself.**

## isGROUP ORDERING — reference wins; "inline group" is a named future kind
Content-is-a-group and is-a-reference are **orthogonal**; two terms are both (`JSONtoken[5]`,
`DatA[2]`, both `NumbeR`). `data` used to be tested first so the overlap refused — right while the
precedence was unsettled. Settled now: **a term that names another rule is a call, whatever its
content**. What is left over is `isGROUP` *without* a reference — a group inlined at the term rather
than named — which is a **named future kind** and keeps refusing.

`JSONtoken` planning was the last gap, so **the JSON family is complete: all seven rules plan**
(14 of 30 census rules). `DatA` is *not* "likewise" — its refusal **moved** from `NumbeR` to `CodE`,
which is both a reference and `parseACTION`, and parseACTION is tested before the reference test.

## RUNG 6 — OPT. The label question was settled from `parse()` BEFORE anything was emitted.
```
ScafE isRule "e"- ScafA? "f"-;   ->  lit(t1,"e") && (parseR(t2,label) || 1) && lit(t3,"f")
ScafF isRule "f"- ","?- "g"-;    ->  lit(t1,"f") && (lit(t2,",")       || 1) && lit(t3,"g")
```
**What the interpretive path does with a non-matching optional, read off the source:** it takes the
min-0 rescue — `matchFailed` sets `sukcess = true` on `kount >= min` **before** `debugHere`, so
`debugHere` is skipped (label not zeroed, mark not rewound) and `generatedExit` returns the label
`checkInput` built. **But the attach lives inside the loop's success block** (`pStuff.label +%
label`), which a non-match never reaches. **So nothing is attached** — and the inline form agrees
exactly, because the callee's `leaveRule` attaches on success and not on failure. Non-match and
match-with-nothing stay distinguishable in the tree (nothing vs an empty child), which is what the
`code={}` actions read.

One divergence, recorded rather than relied on, and **generated is the tighter**: the interpretive
non-match skips the rewind and can leave the mark advanced by `checkInput`'s skip pass; the
generated callee rewinds to its own `from`. Both re-skip before the next term, so it is not
observable.

### One rung, not two — measured
Of the **12** optionals in the census, **4 are character-level** (`data` set) and already refuse
*above* the min/max test, alongside the accumulators. So `?` on a character-level term **never
reaches OPT by construction**, and §2.5's conflation warning cannot bite here. The other 8 are
**6 references** and **2 noLabel literals** — exactly the two shapes OPT wraps. A *labelled* literal
optional does not occur, so it refuses rather than being designed for.

### The POP case that matters
The optional sits **between two mandatory terms** deliberately. *An optional that swallows a
following failure is optional-as-mandatory inverted*, and only a mandatory neighbour catches it:
```
ScafE('ef')  absent  -> ScafA FAIL (mark unmoved), ScafE WIN
ScafE('eaf') present -> ScafA WIN,  ScafE WIN
ScafE('ex')  absent  -> ScafE FAIL, mark REWOUND      <- NOT swallowed
ScafF('fg') WIN · ScafF('f,g') WIN · ScafF('fx') FAIL, mark REWOUND
```

## RUNG 5 — MANY. One kind, iteration only.
```
ScafC isRule ScafA+ "c"-;
    extern int manyScafC1(GroupItem label, GroupItem term)
    {
    String      from = atRuleMark;          <- captured ONCE, at entry
    int         kount;
        while parseR(term,label)    kount++;
        if kount >= 1   return true;        <- min baked
        atRuleMark = from;
        return false;
    }
    ... leaveRule(rule,into,label,from, manyScafC1(label,t1) && lit(t2,"c") );
```
The helper is emitted by **emitPlan's first pass** — which is what the two-pass shape was built
for. **R′ is structural here, not promised:** `from` once at entry (mark clause); every pass goes
through `parseR`→`parse()` and builds a fresh label, with no `fLAG` anywhere (label clause). **R and
R′ compose** — a failing pass rewinds *itself* via the callee's `leaveRule`, so the helper only ever
gives back the whole run.

### ⚠ OPTIONAL IS NOW REFUSED, and that is the finding of the rung
An optional term (min 0, max 1) was planning as a **plain conjunct** — so it would have emitted as
**mandatory**: `lit(t4,",")` where the hand-written model wrote `(lit(rule,",") || true)`. Four
census rules were affected (`JSONfield`, `JSONitem`, `JSONarray`, `InvokE`) — they were planning a
parser that **accepts too little**. They refuse until optionality gets its own kind. One kind per
rung.

Measured min/max shapes: **40** terms plain (1,1) · **12** optional (0,1) · **4** star
(0,unbounded) · **5** plus (1,unbounded). Unbounded sentinel is **268435457**.

### ⚠ min ≥ 2 IS UNREACHABLE THROUGH THE GRAMMAR — pre-existing, and it is not just latent
- `X[2]` → **rejected outright**: `ERROR Operator - failed on isRule and Token`
- `X[2 9]` → parses, prints `nextGroup: ERROR max does not contain a list`, and **leaves min/max at
  1/1** — the limit is **silently not applied**
- `setLimits` itself reads correctly (`ruleStuff.min = minimum.count`), so the fault is **upstream
  of it**

genParseSpec §2.2 says R′'s mark clause is "latent until someone writes `X[2]`". It is stronger than
that: you *cannot* write it. This is why the mark clause is demonstrated as a **controlled
comparison** rather than as a ladder rule.

### Invariant R′ DEMONSTRATED — a passing run proves neither clause
```
MARK,  input "a" against a term needing 2:
  entry-saved (emitted) : matched 1 of 2 -- REWOUND to loop entry
  per-pass  (parse())   : matched 1 of 2 -- rewound only to the FAILED PASS, input STRANDED
LABEL, input "aa":
  2 passes attached 2 FRESH labels          (a recycling loop would show one)
```
`demoRprime` in `genParse.rtn`. A first cut reported "STRANDED" on a **successful** run, because it
compared the mark to loop entry without first asking whether a rewind was due. Fixed before landing
— **a POP that reports a false signal is worse than no POP.**

## genParse's OWN lookup is now scoped (§1.3's second half)
Emitted text has carried no `locate` since the shape brief; **the emitter still ran one**, and a
bare `locate()` resolves down the *general* search stack — search registries, then base registries
(`pROPERTIEs`, `Operators`, `cOMMANDs`, `fILEs`, `Keywords`, `GroupFields`). Any rule sharing a name
with a keyword or command was a **silent mis-target**.

`locateRule` walks the search list and accepts **only `isRule` hits**. `ruleOrRefuse` names which
problem it is — "no rule of that name" and "that name is a keyword, here is its registry" are
different.

**Correcting `41a3831`'s guess:** `debug` resolves to a **not-isRule node in Keywords**
(`incant/setup:196` defines it as a bare keyword), *not* cOMMANDs. The real grammar rule is
**`DEBUG`** — isRule, Grokking, four terms. So there is no lowercase `debug` rule and it now refuses,
correctly. **Why it could not wait:** the mis-target was visible only because that node happened to
carry no terms. A collision with a node that *has* terms would have produced a plausible-looking
plan and nothing would have complained.

## RUNG 3 — THE SEAM IS CLOSED. Read this before touching genParse.
`planRule` **decides**, `emitPlan` **writes**. The artifact between them is a **plan tree of
GroupItems** — resolved decisions, baked literals, **no target syntax anywhere**. It is the bytecode
move one level up.

**Five kinds, and that is the whole vocabulary** for rungs 1, 2 and 4:

| kind | carries |
|---|---|
| `SEQ` | rule tag, `label`, ordered conjuncts (members, in order) |
| `ALT` | rule tag, ordered disjuncts, no label |
| `LIT` | literal text (noLabel) + `at` = baked `rule[]` index |
| `LITTO` | literal text + `slot` + `at` |
| `CALL` | the term to parse through + `at` |

It grows **one kind at a time as a rung demands it** — `MANY` with rung 5, `GUARD` with the
alternation rung, `ACT` when actions land. **If the vocabulary ever comes back complete, it is too
big** — that is the tell this rung went wrong.

### THE RULING THAT MATTERS MOST — positive tests only
**Every plan node comes from a positive test, and an unclassified term is a REFUSAL, never a
default.** This is the one place genParse must **not** copy `setTestMatch`: there, references are
classified by **fall-through** — "no row matches" *is* the answer, and `parse()` collects them on
the `hasAttributes` arm. Inherit that residual and every future unmatched kind becomes a **silent
bogus CALL** — and the census says the unmatched group is the **largest one**, so that failure would
be easy to write and hard to see. `definingRule() != term` is what turns the residual into a
positive, pointer-based property.

**Loud refusal over quiet skip, everywhere in the walk.** Both defects found today were quiet skips.

### What sits on each side (do not let these drift back together)
- **Walk** — fold selection, the `noPrint` gate, classification, baked indices, and **all
  refusals**. A refusal is a validity question about the *rule*, so it reads the same whichever
  emitter is downstream.
- **Emitter** — the frame preamble, joining conjuncts with `&&`, quoting, and **which support
  function spells a decision the walk already made**. `LIT`/`LITTO` carries "does this attach a
  label"; that a `LITTO` in a `SEQ` is spelled `litTo` (and in an `ALT` would be `litOption`) is
  emitter work.

`emitPlan` walks the plan **twice**, once to validate and once to write. Deliberate: §3.3's helper
functions are discovered mid-walk, and with text already going out you must buffer or emit out of
order. With a plan you walk it again.

**ALT is now REFUSED, not emitted.** The old interleaved path would have written a `SEQ` frame with
`&&` joins for an alternation — simply wrong, and invisible until there was an artifact to look at.

## GROW THE CENSUS AS RUNGS LAND — it is not a finished artifact
**Two of the three defects the ladder has caught came from rules nobody was working on, both via
the census** (`debug`'s empty fold; the four rules planning optionals as mandatory). The ladder
targets test the rung you are on; the census tests the rules you are not looking at. Add to it when
a rung lands, and treat a census move as something to *account for*, never to regenerate green.

## THE CENSUS FIXTURE — the classifier's own POP
`genLadder/census.target`, 29 rules, produced by `<binary> incant/censusScratch`. The ladder targets
**cannot** test the classifier: Scaf/Scaf2/ScafA/ScafB reach two kinds out of five and never carry
an unmaterialised term. This asserts a plan **or a named refusal** for every term, **at plan level**,
so it is target-independent and survives the kant emitter unchanged.

**It found a bug on its first run:** `debug` planned as a `SEQ` with **zero conjuncts** — same shape
as the `CodE` `(null)` defect, different cause (`locate('debug')` resolves to something carrying no
terms; the cOMMANDs entry, not the grammar rule). An empty fold is now a refusal.

### The plans, the day the seam was introduced (SEQ 26 §6)
```
PLAN Scaf                PLAN Scaf2               PLAN ScafB
  SEQ Scaf                 SEQ Scaf2                SEQ ScafB
    label=Scaf               label=Scaf2              label=ScafB
    LIT x                    LIT {                    CALL ScafA
      at=1                     at=1                     at=1
                             LIT }                    LIT b
                               at=2                     at=2
```
This is the first artifact in the project that a C++ emitter and a kant emitter would both have to
agree on.

## §1 CENSUS — §4.2's table vs the tree. VERDICT: several rows wrong.
27 rules / 73 terms; the JSON family **plus** a spread of the real bootstrap grammar (restricting to
JSON would have flattered the table).

| §4.2 row | count |
|---|---|
| **NO ROW MATCHES** | **24** |
| default `lit`/`litTo` | 19 |
| `isSET` | 11 |
| (no rStuff yet) | 5 |
| `isGROUP` | 4 |
| `upToOver` · `parseACTION` · `isCHAR` | 1 each |
| `upTo` · `isBIN/isREGISTRY` · `isANY` · `isMacro` · `isCondition` | **0** |

- **The largest group falls in no row, and all 24 are rule-reference terms.** They fail every branch
  and `!contents()` is false (they carry the shared list), so `setTestMatch` leaves `testMatch` null
  and `parse()` reaches them on the `hasAttributes` arm. **References are handled by fall-through,
  not by `onGroup`.**
- **The `isGROUP` row exists but means something else** — *content-is-a-group* (`min=[0-9]+`,
  `NumbeR`→`numberSet`), not "a rule reference". Orthogonal properties, conflated by the table.
- **§4.1's `if rule.onGroup` is dead** — 13 of 13 reporting rules NONE, zero positives anywhere.
- **§4.1's `if rule.data` is live and unimplemented** — 6 rules carry rule-level data
  (`FloaT` isCHAR, `PoweR` isSET, `Modifier` isSET are accumulator cases). The walk **refuses** them
  until rung 5.
- §4.1's **fold test itself held**: ALT 4 / SEQ 23.

So the walk is a **fresh classifier written against the tree**, not a transcription of
`setTestMatch` — which makes the seam a *correctness* argument rather than a tidiness one: it is new
code you would otherwise write twice.

## NAMED OPEN ITEMS from the census (not unnoticed ones)
1. **`isGROUP` + reference is a real overlap with no precedence rule.** Two terms are both
   (`JSONtoken[5]`, `DatA[2]`, both `NumbeR`). `planTerm` tests `data` **before** the reference test
   so the both-case **refuses** rather than silently becoming a CALL. What it means semantically is
   unsettled and no ladder rule reaches it.
2. **Where do modifiers live before rStuff exists?** `Limit`'s `']'-` has a source modifier and no
   rStuff to hold it. Unknown, and it is why eager materialisation would **fabricate** a
   classification rather than discover one.
3. **`locate('debug')` finds a term-less node** — a name collision between the `debug` command and
   the `debug` grammar rule. Surfaced by the fixture; nobody has looked at it.

## MEASURED, because it was flagged as a hazard to check rather than assert
**Eager materialisation via `getRStuff` CANNOT reach `getWhatFollows`'s `parent.rStuff.min = 0`** —
the §7.1 write. `getRStuff` constructs and `setRStuff`s, nothing more; `getWhatFollows` has exactly
**one** caller, `getStuff`, gated on `!followed`. The hazard is real but **bounded to `getStuff`**.
Refusing is still right, for a second and independent reason — see open item 2 above.

## RUNG 4 — SOLVED. The route exists, and it is a pointer walk.
The question that gated it: `parseMethod` lives on `rStuff`, `rStuff` is PER NODE, so a reference
term has its own and was never bound. Binding a rule therefore looked like it could not reach the
terms that reference it — which is exactly what mixed mode needs.

**Measured, not reasoned (the same `termScratch` method):** a reference term shares the defining
rule's child list, and **the children are parented to the DEFINER** — so `term[1].parent` **IS the
defining rule, by pointer.** Verified against what `locate()` returns for the same name on
`JSONblock→JSONfield`, `JSONfield→JSONtoken`, `JSONfield→JSONvalue`.

`GroupItem.definingRule()` is that walk. **It needs no guard because the test discriminates:** a
node that OWNS its children (a defining rule, and also `CodE`/`BlocK`) routes back to ITSELF, and a
leaf term has no children at all — both fall through to `return this`. Only genuine references
resolve elsewhere.

**The ruling: resolve at USE time.** `parse()`'s fork reads `parseMethod` from `definingRule()`, so
binding a rule once reaches every reference to it **including references created later**. No
registry sweep (would miss late references), no `locate` (§1.3 forbids it).

### The shape/frame split, and why the two fields go to DIFFERENT nodes
- **`parseMethod` is SHAPE** — one answer, always the same for a rule → read from the **definer**.
- **`parentLabel` is FRAME** — it varies per invocation and is the field that carries the variation
  → stays on **`this`**, the node actually being parsed. Routing it to the definer would make every
  reference to a recursive rule write the **same slot**, which is correct-looking right up until the
  recursion is live.

**The general tell, worth more than this instance: a field that looks like it belongs with the rule
because it is usually the same is exactly the dangerous case.** (Clay corrected his own near-miss on
this twice in one session, on Tony's lesson.)

`this` is what gets passed to the generated method, not the definer — the two share a child list so
`rule[n]` reads the same terms from either, while `rule.rStuff.parentLabel` must be this
invocation's.

## THE COUNT GUARD — and it has been made to fire
Every emitted `rule[n]` bets the list only ever mutates BEHIND the real terms. The cached `BlocK`
appearing after a rule's first parse proves the list *does* mutate at runtime, and nothing enforced
the bet. Now: `RuleStuff.termCount`, recorded by a **`parseTerms=N`** binding attribute, checked by
**`parseMethod=`** before it installs anything.

`countRuleTerms` is the **ONE implementer** of "real term" — the emitter bakes indices with it and
the binder re-checks with it. A check using its own private notion of the classifier would be worth
nothing.

**Negative test, RUN:**
```
parseMethod: REFUSING to bind parseScafA to ScafA
             emitted against 9 terms, rule now has 1
```
and note the behaviour on refusal: ScafA fell back to the **interpretive walk** while ScafB still
ran generated and still WON. **A refused binding degrades to the oracle rather than breaking** —
mixed mode doing exactly its job. Reproduce with:
`sed 's/ScafA isRule "a"- parseTerms=1/ScafA isRule "a"- parseTerms=9/' incant/genScratch > /tmp/g && <binary> /tmp/g`

`termCount` 0 means unrecorded, which **binds with a warning** rather than refusing — a silent trap
would be worse than an unguarded one.

## RUNG-4 POP (all RUN, exit 0)
```
ScafA isRule "a"-;                  ScafB isRule ScafA "b"-;      both generated, both bound
emitted:  return leaveRule(rule,into,label,from, parseR(t1,label) && lit(t2,"b") );
ScafB('ab')  ->  HIT/WIN ScafA nested inside HIT/WIN ScafB
                 ScafA's GENERATED method ran, reached through a reference term
ScafB('ax')  ->  ScafA WINs, lit "b" fails, FAIL ScafB with mark REWOUND
                 Invariant R across a NESTED generated call
emitted text == compiled-in source, byte-for-byte   (genLadder/rung4.target, new)
```
Reading the trace: `HIT` prints at the top of **leaveRule**, which is the rule's EXIT (§1.8 moved
instrumentation into the library, so there is no entry hook). One HIT per invocation, so §6.1's
attempt count is right; only the ORDER reads oddly — a callee's HIT appears before its caller's.

## Also landed, worth not re-deriving
- **§1.8 instrumentation is in the library, gated.** HIT/WIN and Invariant R live in
  `leaveRule`/`leaveAlt` behind `GroupRules.parseTrace` (off by default, so baselines cannot move;
  `traceParse('on')` turns it on). One implementation, every rule, no emitted lines, survives the
  kant handover. This is what replaces `runScaf`'s R-inner/R-outer prints — R is a property of the
  **failure path**, so `Scaf()` alone could never show it.
- **`runScaf`/`runScaf2`/`runJSONblock` are RETIRED.** Do not re-emit an entry wrapper.
- **JSON models converted** to the same shape using the **measured** indices. They stay dormant
  (nothing invokes them; JSON is last by ruling). `parseGeneric` survives with no callers —
  `parseR` subsumes it.
- **`setParseMethod`** does the `void*` → typed-fnptr cast in `-% %-` passthrough, because tok has
  no syntax for it. Its body is entirely passthrough and everything arrives as a **parameter**
  (bear-trap #13: an incant-level local referenced only inside a passthrough is pruned as unused).
- **Latent, flagged not carried:** `emitTerm`'s labelled branch emits `litTo`, which has **no
  implementation** in the support library. Never fires for rungs 1-2/4 (all terms `noLabel`).
- **`emitTerm` now classifies**: a term whose `definingRule()` differs from itself emits
  `parseR(tN,label)`; literals still emit `lit`/`litTo`.
- **A `noPrint` definition attribute does NOT persist in the rule's list** — "fire and forget" is
  literal. Measured: `Scaf isRule "x"- parseMethod=parseScaf;` leaves `Scaf` with exactly one entry.
  That is why the term count needed a real field and could not ride on a sibling attribute.
- **tok note, and it has bitten twice now:** juxtaposed concat does not work in **return position**
  (`return "a" b;` -> `FAIL Block`/`ERROR Inheritance`, taking the whole extern with it) **or in
  argument position** (`f(x, pad "  ")` silently generated a THREE-argument call, caught only by
  the C++ compiler). Concat into a local first, always. Assignment position is fine.

## NEXT — Clay's standing order (SEQ 27 §5), each waiting on the one before it
0. **Recon owed before B can be briefed** — read-only, perturbs nothing. TWO greps:
   *(a)* what do rule actions actually return, and how do they locate a child? Tag-locating actions
   survive B; position-locating ones may not. *(b)* which bootstrap-built rules add terms with no
   `modify()` call — i.e. confirm `Limit` is the only one, or find the others.
1. **B — drop the automatic `isTarget` stamp on members.** Tony's ruling: `isTarget` becomes `@` and
   nothing else. `genLadder/tree.divergence` flips from asserting the divergence to asserting
   AGREEMENT — that flip is the acceptance test. Expect quiet fallout, not loud: a wrong result, not
   a failed parse. This is §2.4's retag question below, and it gates the JSON family end-to-end. The whole family plans and
   emits, but the trees diverge, and the hand-patched RETAGGING NOTE in `parseJSONfield` is the
   same bug. Decide whether `leaveAlt` takes `into` and retags. Note the interpretive path is not
   self-consistent, so "match the oracle" does not fully determine the answer.
2. **Accumulators** — `data`-carrying repetition (`FloaT`/`PoweR`/`Modifier`/`NamE`), still refused.
   §2.5: star and plus mean something different for character-level terms than for references, and
   conflating them yields a parser that accepts correctly and BUILDS WRONGLY.
3. **D — the guard arc**: genParse's own NON-mutating first set. Not a call into `getGuard` — see the
   scoping above. An arc, not a rung.
4. **Inline group** — `isGROUP` without a reference, the named future kind. `Limit` refuses on it.
5. Standing tripwire: the interpretive path does `kount++` on success, the generated path does not.
4. **Rung 9 is TONY'S RULING and gates only rung 9** — bare reference to an alternation:
   auto-`promoteR`, or require explicit `@`?
5. **§4.2 / §4.3 fixes, after shape**: make `lit`'s skip pass non-destructive (then `leaveAlt` drops
   to `(rule, ok)`); end-of-input normalization beside `checkSkip`.
6. **§7.5's result-discard is LOCATED but UNFIXED**, and it is on the path to a working POP, not
   behind one: until it is fixed no test on failing input reads honestly. Narrowing from 07-27: the
   discard sits **above `runOP`, or in the script-level invocation**; `parse()`, `runRule`, `runOP`
   and `matchFailed` are all exonerated.
7. JSON LAST, and only once `jsonTest` is a clean oracle again.

## STILL OPEN from 2026-07-27 — none of it closed today
- **DIVERSION BOUNDARY NOT RESPECTED DURING MATCH.** A failing parse reads past the end of its
  diverted buffer into the enclosing script text *while matching*; the tell is a `Failed at:` window
  containing the script's own source. Process exits 0 (crash fixed 07-27) but following statements
  are swallowed. **Consequence: `jsonTest` still cannot run multiple failing cases in one process**,
  so §7.1's inverted-ordering fixture stays REQUIRED (well-formed to arm, malformed to read, nothing
  after, ONE process).
- `jsonTest`'s last case is annotated `KNOWN TO FAIL` while printing `ok` — **when the
  invocation-layer bug is fixed it flips to a real failure, which terminates the run, so jsonTest
  will appear to break at the moment the bug is fixed.**
- **`ruleSTUFF` is a WRITE-ONLY GLOBAL** (Tony's ruling 07-27). Exactly one reader,
  `GroupActions.rtn:269`, and that local is never referenced again; inert since the initial commit.
  Leave `parse()`'s own write and the global's declaration alone — `parse()` is the parity anchor.

## FINDING — pre-existing, surfaced not caused (report, do not chase)
`Commands.rtn`'s `testing()` had been **hijacked** to call `runScaf` twice. Since `runScaf` retired
it had to change, and it was restored to what its own doc comment describes (`jitRunAction` for a
coded argument, `jitRunIfTest` otherwise). **`incant/jitscratch` therefore exercises the JIT for the
first time in a while, and it crashes (139) on the `jitInc` fixture:**
```
0  jitEmitUnary  GroupRules.mm:2424   <- crash
1  opPlusPlus    GroupRules.mm:3904
2  runOP · aCTionBlocK · jitExecBlock · jitRunAction · testing
```
Squarely in the JIT arc (`++`'s emit path), nothing to do with genParse. `jitscratch` is not a
baseline and was not passing before in any meaningful sense — the old body never called
`jitRunAction` at all.

## Open, Tony's (carried forward, none touched today)
- **TODO.md cause-1 entry** — annotate as dead-since-`875b936`, don't strike. His file.
- **Bear-trap #18's ATTRIBUTION** — split into a confirmed OBSERVATION (keep as doctrine) and an
  OPEN attribution with four candidates, one of them Clay's own spec error. Tony signs off.
- **`GUI/Layout.twk` and `GUI/Stylish.twk`** share basenames with the top-level files he edits, and
  `tokall` only ever sweeps top level.
- His Group-A work (Debug.rtn, Stylish, Layout, TODO, guiDesign, incant/utilities+jsonTest) is still
  uncommitted.

## THE POP IS ONE COMMAND NOW
```
sh genLadder/pop.sh     # every ladder target + census + both baselines, exit status checked
sh genLadder/tree.sh    # §2.4 tree fixture — asserts the OPEN divergence is unchanged
```
`pop.sh` prints one line per check and the diff when something moves. Baselines live in
`genLadder/` so it is self-contained. I hand-rolled these checks every rung and got the escaping
wrong once; this exists so nobody does that again.

## Run recipe / reproduce
- Binary: `~/Library/Developer/Xcode/DerivedData/InProcess-ezzmcllcsvijqmbipricnduikqfp/Build/Products/Debug/Groups`.
- Build: `cd ~/Library/CloudStorage/Dropbox/data/InProcess && xcodebuild -workspace
  InProcess.xcworkspace -scheme Groups -configuration Debug build`.
- `.rtn` (genParse.rtn, Commands.rtn, GroupActions.rtn, ruleActions.rtn) are `include`d into
  GroupRules.twk → edit one, then **`tok GroupRules.twk`** (NOT a standalone retok). Standalone
  class files (`RuleStuff.twk`, `GroupItem.twk`…) → `tok <File>.twk` directly.
- **`tokall` is a shell FUNCTION** — `for item in *.twk; do tok $item; done`. Top-level only (13
  files); misses 14 below (`GUI/`, `GUI/Stuff/`, `Tests/`). After a layout change, grep those
  generated files for the class you shifted. Today: only `GUI/Bwana.mm`, and it merely `#include`s
  `GroupRules.h` without touching a field — nothing owed.
- **`groups.ext` lives OUTSIDE the repo** at `~/Dropbox/data/InProcess/Include/groups.ext`
  (bear-trap #11). It now carries `parentLabel`, the one-arg `parseMethod`, `parseTrace`, `parseR`,
  `parseRuleMethod`, `traceParse`, `dumpRuleTerms`, the renamed `leaveRule`/`leaveAlt` params and
  the one-arg JSON parse decls — and `runScaf`/`runScaf2`/`runJSONblock` removed. Rung 4 added
  `termCount`, `definingRule`, `countRuleTerms`, `parseTermCount`, `parseScafA`/`parseScafB`.
  **No commit trail exists for any of it.**
- genParse ladder: `<binary> incant/genScratch` → emits parseScaf/parseScaf2, then runs
  `Scaf('x')`/`('y')`/`Scaf2('{}')`/`('{')` with the leaveRule R report. POP:
  `sed -n '/^extern GroupItem parseScaf(/,/^}/p;/^extern GroupItem parseScaf2(/,/^}/p'` of the
  output vs `genLadder/rung12.target` (empty diff = PASS).
- Term measurement: `<binary> incant/termScratch`.
- Baselines: `<binary> incant/oneTest` → `maximus = 11` then `26` ×4; `<binary> incant/jsonTest` →
  13 `ok` — **13, not 14**; the briefs carried 14 and Clay has corrected it. **Capture BEFORE
  changing anything and `diff` after.**
- Census POP: `<binary> incant/censusScratch 2>&1 | grep -v "^getRStuff" | sed -n '/^PLAN /,$p' |
  grep -v "^Search list:" | grep -v "^stop:" | grep -v "^$"` vs `genLadder/census.target`.
- Crash frames without Xcode: run under `script -q /dev/null` (segfaults lose buffered stdout).
- No `timeout` on this shell — background + kill anything that might hang.

## HOW TO WEIGHT A CLAY BRIEF (earned 2026-07-27, held again today)
The split is **structural vs causal**, not design-vs-tree. Today's structural claims all held (one
argument, derived `into`, term-first, no locate, no wrapper, instrumentation in the library,
through-the-fork). The two that needed correcting were both **claims about what is in the tree**
(`t2.onGroup`, `rule.parentLabel`) — same family as the five that failed on 07-27.
**Take the distinctions, check the attributions.** Cost of checking: one measurement run.

## PARKED by Clay (SEQ 26), neither blocks the ladder
`jitEmitUnary`←`opPlusPlus` (see the finding above), and the LLVM-IR-for-inlining question raised by
routing `parseR` through the fork. Both are JIT-ladder work.

## THE WALKIE-TALKIE HAS ITS OWN DOC NOW — `docs/walkieTalkie.md`
One pointer, by that file's own instruction: its content stays there, not here. It is Clay's
2026-07-29 rulings on the Clay↔Clod channel, in the B0 claim format. **Read it before writing
anything into `ipc/`.** The three that bite hardest:
- **WT-11 — NO SILENT OVERWRITE.** A write carries the whole file, prior history included.
  Downloading or rewriting atop a file *replaces* it, and an unread turn vanishes with nothing
  saying so. **Broken once already, by Clod, on 2026-07-29** — `clod-to-clay.md`'s SEQ 17 was
  still `fresh` when SEQ 18 went over it (erratum + reconstruction are in that file's header
  and foot). The rule binds both directions.
- **WT-9 — direct write is proven, so route deliberately:** a brief Clod will act on gets
  dictated and transcribed, because *the transcription step was a second close reader*;
  reference docs get downloaded straight in.
- **WT-10 / WT-13 — the channel is ASYMMETRIC.** Clod polls `ipc/clay-to-clod.md` for an
  on-disk change; Clay cannot poll anything and reads only when Tony prompts him.

**Open and assigned to Clod in that file's PLAN step 1** (untouched, and it wants Tony's nod
first because it puts repo files into a sync path): expose `ipc/` to Clay read-only via the
Drive connector. Step 2 says **measure before building** — if removing the paste step only
saves typing, MCP is not worth a build.

## Working relationship (unchanged)
Tony (Haps) = architect/final authority. Clay (claude.ai) = design/reasoning. Clod (Claude Code) =
execution/edits/build. Standing permission: change source freely, commit/push routine work at
discretion.
**Walkie-talkie transport is SETTLED: Clay has NO filesystem reach — read-only uploads only. CLAY
DICTATES, CLOD TRANSCRIBES; Clod owns every `ipc/` write in both directions.** SEQ 25
(genParseShape) arrived as a file in `~/Downloads`, imported to `docs/genParseShape.md`.
SEQ 26 (rung 4) arrived in chat; SEQ 26's seam brief as `docs/genParseSeam.md`.
`grep -H '^STATUS:' ipc/*.md` is Tony's window.
