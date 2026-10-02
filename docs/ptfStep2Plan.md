# Parse-then-fire step 2 -- the plan, as recorded on branch `parse-then-fire` (record, copied unchanged)

**Provenance.** Copied VERBATIM on 2026-10-02 (SEQ 263 R5) from `parse-then-fire:docs/jitDesign.md` lines 1158-1430 (branch tip `71d2a44`); nothing below this header is edited. The re-read against today's trunk is `docs/ptfReread.md`; the port shape is ruled (iii) then (ii) (SEQ 263 R1).

---

- **PARSE-THEN-FIRE STEP-2 CENSUS -- named rules and readings from step 1 (branch `parse-then-fire`, 2026-09-24).**
  - **RULE C (Tony, 2026-09-24): ATTACHING NEVER READS WHAT AN ACTION WROTE.** The label tree must be decidable from
    the parse alone. Step 1's first plant: `attachLabel` chose "attach the label or its group" from `isGROUP`, which
    NamE's action writes. Unwrapping a resolved name into its group is the PARENT ACTION's decision at fire time.
    Step 1 carries it by replaying the one predicate (`GroupItem::unwrapsOnAttach`, ruling A); step 2 removes the read.
  - **ITS SECOND MEMBER, same shape through an exemption:** `aCTionANYtoken` (parse-deciding, so it fires during the
    parse) refuses keywords by reading `input.group`, which NamE's action writes (`ANYtoken NamE@`). A matcher reading
    an action's output. Step-2 form: the keyword test is the matcher's own lookup, not a read of NamE's resolution.
  - **THE BOOTSTRAP BOUNDARY IS MEASURED, NOT RULED:** thousands of `class=outside` fires -- the setup and grammar
    defines are not parsed under StatemenT, so step 1 never touched them. Keep beside the `Start()` idea when the
    defines hunch is tested.
  - **A THIRD MEMBER, recorded by ruling (SEQ 198): the ALLHELD parse failure (SEQ 197) is a Rule C instance -- NamE's
    action is READ BY THE PARSE.** With every ORDINARY fire held (PTF_ALLHELD, reverted), `register(LoopBranch);` failed
    the parse at exit 0. Attribution is Tony's ruling; the candidate mechanism, UNMEASURED, is plant A2's shape: the
    ANYtoken recheck record re-runs the keyword test against `input.group`, which NamE's action writes -- and NamE was
    held, so nothing had written it.
  - **SHAPE-REWRITE ITEM (Tony, 2026-09-24): `field[whatever]` BECOMES `opGet field whatever`** in the ExpressioN
    rewrite, alongside `A += B` -> `+= A B`. opGet chooses its method PER FIRE by the key's kind (never cached on the
    node, as `+=`). **Preserve:** a unary binds to the PRIMARY (`*a[0]` is `(*a)[0]`, bear-trap #48's structural half),
    and a subscript stops at the element. **Retires** aCTionTokenXP's subscript arm (handleSubscript, and with it the
    InvokeArg `fLAG` marker -- the "subscript" meaning of fLAG that collides with checkInput's "recycle", plant 4).
  - The action-vs-parse overlap census (both directions) is `docs/overlapCensus.md`; a step-1 plant not in it is a
    census gap.
- **PARSE-THEN-FIRE STEP 2 -- THE PLAN (recon SEQ 174-178, 2026-09-25; read-only but for the two JSON strokes, which
  landed on trunk).** Stroke order below. **Every certificate** carries, beyond its own rows: PTF=0 equal to trunk row
  for row; fleet and jitLadder unmoved at both PTF settings except the rows named; canary read off the tree (H14); retok
  bare. Baselines at recon time: trunk 751 / 1, red list 57 (docs/redList.md form); branch at 860047e PTF=0 742 / 2
  (57 red, the same), PTF=1 740 / 2 (59 red = those + `probeDoorT stmtRejT`, `site1RoadsT`); jitLadder 215 both.
  ⚠ **`genLadder/tree.sh` and `genLadder/mixed.sh` are RED ON TRUNK TODAY and on no checklist** -- tree.sh "TREE FIXTURE
  MOVED", mixed.sh "WOKE -- NO VARIANT LOSES THE CHILD ANY MORE". Found by this recon, not chased. Any stroke naming
  them certifies "byte-identical to today's red", and their state is Tony's to rule on separately.
  - **P0 -- merge trunk into the branch.** Brings dc8b0b9/9ab2fdd (JSON) and the nullAccessorDeref guard. Cert: PTF=0 ==
    trunk; movers: the nine `jsonTest JT-*` rows join, and are PREDICTED GREEN AT PTF=1 as well (the JSON drives are
    class=outside, which step 1 never records); `jsonTest baseline` parked row leaves (retired on trunk).
  - **P1 -- the drive census row (SEQ 175 item B), on trunk and branch.** codeOnly.py-stripped, enclosing function of
    every `pushInput(` in top-level .twk/.rtn, pinned as the sorted set of 7: loadInputFromFile, demoRprime, treeOf,
    driveStep, processCode, bootstrapper, jitProbeDrive. Fails on an unknown caller (named) and on an EMPTY set. H7: a
    copy of genParse.rtn with one extra caller -> red by name. Cert: +1 green; nothing else moves. (Without codeOnly
    the census reads 8 -- a comment at GroupActions.rtn:1101 lands in runOP.)
  - **P2 -- the conservation row and the explicit failed-alternative discard (SEQ 174 item 5a).** First the ROW, pinned
    as today reads: FRAMELEAK 0 + DISCARD 12,410 + UNREACHED 932 = **13,342** at PTF=1, full fleet, PTF_LEAKLOG. ⚠ Its
    sentence: SEQ 123's 13,339 predates pop.sh's own srDot sub-run (pop.sh `PTF_TRACE=1 $B "$T/srDot.twk"`), which
    discards exactly 3 records and landed in the same commit (860047e). Then the DISCARD: the 932 are failed
    alternatives (840 under a DO that matched its body and failed at `while`; sweepT 828, s1r 92, pd 8, srDo 4, every
    one rootIsAncestor=0). A gPtfN mark per pass at parse()'s `continueHere` (GroupItem.twk ~1353), truncated at
    `matchFailed` when the pass fails; the new road's twin at exitFromParse's failure return (Generate.rtn:26-28);
    logged `DISCARD failed alternative`, apart from the rejected-parse discard. Cert: 0 + 12,410 + 932 + UNREACHED 0 =
    13,342; UNREACHED pinned 0; fleet unmoved at both settings (the 932 never fired). H7: remove the truncation ->
    UNREACHED back to 932.
  - **P3 -- route treeOf and demoRprime through driveStep (Tony, SEQ 175).** ⚠ **RULING NEEDED FIRST: the shape of
    driveStep's growth.** treeOf needs the raw tree (driveStep returns a verdict; the tree is readable at the root's
    `rStuff.label`, as aCTionTell's reply already reads it); demoRprime needs a TERM driven repeatedly into a caller's
    label inside ONE divert, with its own mark rewinds -- driveStep's no-data arm has `parseR(rule,intoField)` but no
    divert. Opens with a FIXTURE: a Scaf-shaped rule given an ORDINARY action, driven through both entries from a
    top-level statement, one accepted and one rejected pass; asserts the fire count (equal at PTF=0 and PTF=1) and the
    door (measureRuleDoor's line for each drive, presence-with-value). ⚠ **Its scoped-discard row reads 0 records at
    step 1 BY DESIGN** -- these drives' roots are not StatemenT, so step 1 records nothing inside them (SEQ 125 A: zero
    fires inside either drive, both settings). The same row must read NON-ZERO in P7; that is its H7 pair, and it is
    written now so P7 cannot pass without it. Movers: P1's row 7 -> 5; genScratch's rows, `tree.sh`, `mixed.sh`
    PREDICTED BYTE-IDENTICAL (a move there is driveStep's bracket -- floor, inputFloor, lastIndent/defining restore --
    not the scope).
    ⚠ **STATUS 2026-09-26 (SEQ 193 1a re-read): P3 OWES NOTHING OF ITS OWN.** Landed as ruled: treeOf drives through
    driveStep (driveDoorT door 1/1/1/1, fires 1/1/1/1 at both settings); demoRprime was RETIRED (ruling 3a), not routed;
    P1's census 7 -> 5; tree.sh, mixed.sh and genScratch retired by mapping, their question now `treeRowT` (AGREE).
    **One premise moved and is recorded:** "the tree is readable at the root's `rStuff.label`" was MEASURED NULL after
    every drive (the call bracket restores it); the reader is the drive floor's label slot (`driveFloorLabel`). **What
    it hands forward is P7's:** driveDoorT's discard row, pinned 0/0/0/0 "until P7", is the H7 pair P7 must turn non-zero.
  - **P4 -- retire the control signal stamped on the returned value.** Today aCTionBrancH generates
    `arg->groupBody->flags.isBranch = 1/2/3` on its return operand, which can be `falseResult` (a shared singleton),
    the keyword node, or a LIVE FIELD (`return x;` stamps x). The ruled control channel (F-122 entry 7): aCTionBrancH
    writes kind+value to a control slot; BlocK (ruleActions.rtn:55-58), DO (:429), FOR (:533), WhilE (:1212), IF (:592)
    read it after each child; the action boundary consumes a return (GroupActions.rtn:596, Generate.rtn:307).
    Trunk-landable, independent of PTF. ⚠ **RULING NEEDED: where the slot lives** -- recommend a ruler slot saved and
    restored at processAction's frame (so a callee's return cannot leak into the caller's loop). Fixture `ctlStampT`:
    after `return x;` x's isBranch reads 0 with its non-zero sibling (the returned value reads x's value); after a
    return whose operand fails, falseResult's isBranch reads 0. ⚠ isBranch has no GroupFields accessor today -- the
    fixture needs one (or a measure callout) first. H7: restore the stamp -> the x row red. Movers: none in the fleet
    (the stamp is invisible unless read); every break/continue/return row must stay green; jitLadder unmoved (the jit
    emits branches through jitEmitContinue/jitEmitReturn, not the stamp).
    ⚠ **RULED (SEQ 179, Tony):** the slot is a RULER slot saved/restored at processAction's frame; ONE writer (the keyword
    action), ONE reader (the firing parent); the jitted road's equivalent is part of the certificate -- both roads, one
    spelling; the isBranch ACCESSOR LANDS FIRST. (Site lines have moved: parseRule's consume is Generate.rtn:366 now.)
    ⚠⚠ **STOPPED 2026-09-26 AT 1b (SEQ 193): THE CERTIFICATE CANNOT BE CASHED AS WRITTEN.** The accessor landed
    (`isBrancH`, GroupFields 45, read-only) and the rows were driven on TODAY's stamped binary first (H16).
    **Both named rows read 0 BEFORE the change** -- `return x;` leaves x at 0 and a failed operand leaves falseResult at 0
    -- because processAction already ends `result.isBranch = 0` (GroupActions.rtn:596): the action boundary clears the
    stamp off the value it hands back. So "H7: restore the stamp -> the x row red" cannot fire. **The stamp DOES survive
    in two other positions**, measured by `incant/ctlStampProbe`: `continue v;` leaves the live field v at **2** (a loop
    consumes continue by replacing the result with trueResult and never clears the stamped node) and an action compiled
    by `testing()` leaves `return w;`'s operand at **3** (under jitting aCTionBlocK `continue`s past the branch and the
    compile has no processAction frame). **Candidate replacement rows, for Tony -- not adopted:** CAND-1 `continue v;`
    -> v's isBranch 0 (non-zero sibling: the loop ran 2); CAND-2 jit-compiled `return w;` -> w's isBranch 0; plus a
    leak row per bracket (processAction's, the emit frame's), each with its own H7. Nothing of the slot is built.
    ✅ **LANDED 2026-09-26 (SEQ 194) -- the certificate ADOPTED as the two surviving stamps, controls pinned:**
    `continue v;` 2 -> **0** (loop ran 2), testing()-compiled `return w;` 3 -> **0**. The slot is `ruler.branchKind`:
    ONE writer (aCTionBrancH, both roads), read by the firing parent after each child and cleared before it (BlocK,
    DO, FOR, WhilE, IF), saved/cleared/restored at processAction, parseRule's fire and the jit emit walk. **P4 leaves
    NO stamp** -- zero writers of isBranch -- so the per-bracket rows assert the returned value carries none (LV-1);
    parseRule's has no reachable position (it returns the label, not the body's value; three spellings read 0 even
    with the stamp put back) and is carried by its slot-leak row alone. Slot-leak rows SL-1..3, each red when its
    bracket's restore is removed. Rung `incant/pop/ctlStampT`, 10 rows. **One mover the plan did not name:** pop.sh's
    A4 isContinue census counts the SPELLING, re-aimed to `branchKind == 2` (3 arms, 1 setter, unchanged).
  - **P5 -- JSON's collecting actions onto the value-yield model (Tony, SEQ 176/178).** The TRUNK HALF LANDED
    (dc8b0b9: JSONfield and JSONarray mint a fresh result node per fire; 9ab2fdd: jsonTest pins the tree by value). This
    stroke only moves the two rules onto the value model -- they hand JSONblock/JSONfield values and JSONblock gains its
    collecting action. **Certificate: the pinned JT rows stay green**, at both PTF settings. Item-2 population count
    (SEQ 178): JSONblock is the ONLY action-less rule whose children's yields reach a caller -- bins pass through to
    parents with actions; lamp/thermo's members are `defer` (held, never yielded); Start and BasicElse read truth or a
    single child; tell has its own action (a fresh verdict node). Option (c) stays parked.
    ⚠⚠ **STOPPED 2026-09-26 AT ITS CERTIFICATE (SEQ 195): "the pinned JT rows stay green" CANNOT CERTIFY THE MOVE.**
    Run on today's branch binary (0c8c582) BEFORE any change: all 10 jsonTest rows ok, 0 fail, at PTF=0 and PTF=1 -- so
    they are green with the stroke undone, and certify nothing about it (H7; P4's first rows failed the same way).
    **A candidate discriminating row, measured, not adopted:** the yield channel's FIELD adoptions during jsonTest
    (measureAdoption, traceParse armed on a one-line-delta copy, sentinel present): **JSONfield 42, JSONarray 9** at both
    settings. If P5 means the JSON rules stop leaning on the yield channel, that count goes to 0 while the JT rows stay
    green -- the pair would certify it. Its other end is unmeasured (H16) until something reads 0.
    **And a premise for Tony, from the plan's own order:** before P6 builds the value handoff, the only way JSONblock's
    collecting action can receive its children's values is the adoption channel P6 retires. So either P5 is P6's first
    customer (land it with or after P6's handoff), or "the value model" in P5 means something available today -- which?
  - **P6 -- THE CORE: retire defer, deferredAbove and the held fires; parent-driven firing; the value rulings.**
    Top-level statements only (step 1's scope). Ruling 2's default for an action-less rule with content; a construct
    hands its parent a VALUE; the tree never holds a field; an unrun IF hands back nothing (today: labelNO owner-run,
    its own label direct, ruleActions.rtn:586-593). Deleted: the `d` modifier's write (Commands.rtn:576) and `defer`'s
    registration (setup:44) with the 15 grammar uses; deferredAbove (GroupItem.twk:433) and ptfStmtAbove; the held arm
    (GroupItem.twk:743-746) and the replay's twin; the five yieldOrValue splits (ruleActions.rtn DO :447, FOR :555, IF
    :589, WhilE :1230, Xpress :1246); the replay's `ret != L` substitution and unwrap; attachLabel's unwrap read
    (plants A1/A3/A4/A5 -- the parent unwraps at fire); **attachLabel's `lab == labelNO` skip, which the value handoff
    retires** (with no action firing before the attach, a label at attach time is the parse's own; labelNO only ever
    arrived as an action's return). KEPT: the null-fails-the-parse arm for the exempt class only (below). Movers named
    in advance: `adoptT FIELD` 1 -> 0 and `adoptT PROPERTY` -> 0 (the row needs a new non-zero sibling BEFORE the
    stroke); `yieldT DIRECT` (reads s2Y -- predicted unchanged) and `yieldT OWNER`; deferNatT's `through the
    recursion` and `drive floor` rows (their DEFERABOVE lines vanish -- retire by mapping); convDriveT CD-1b and
    convLeakT (their members' `defer`); printFamilyNew's two `defer` grafts; f122T/f122NatT; the retire-witness counts.
    A new fixture for the unrun IF.
    ⚠⚠ **STOPPED 2026-09-26 BEFORE BUILDING (SEQ 196): THE FIRST LINE THAT CANNOT BE CASHED IS THE STANDING CLAUSE
    "PTF=0 equal to trunk row for row".** P6 deletes the OLD road's own machinery: the held arm (GroupItem.twk:743,
    `if deferred && held`) is NOT PTF-gated -- at PTF=1 `ptfRecord` intercepts the fire one line earlier, so the held arm
    runs only at PTF=0 -- and `defer`'s registration (incant/setup) and its 15 uses in incant/grammar are shared by both
    roads. Deleting them changes what PTF=0 does, and the rows that exercise it are the named movers themselves. A reading
    of pointable lines, not a build. **Fork for Tony:** (i) P6 GATES rather than deletes until the branch lands (at PTF=1
    the held/defer paths are bypassed; deletion is a later stroke when PTF=0 retires), or (ii) P6 is where the old road
    retires, and the clause is replaced for it (e.g. "PTF=0 == PTF=1" or trunk comparison dropped from P6 on).
    **SECOND, from the P6-before-P5 reorder (SEQ 196):** Ruling 2's default (SEQ 176: an action-less rule fires its
    children in order and YIELDS THE LAST VALUE) means that once P6 retires the adoption that builds JSON's tree today
    (FIELD adoptions JSONfield 42, JSONarray 9, both settings), action-less JSONblock hands back its last field -- so the
    10 JT rows move INSIDE P6, and they are not among its named movers; and P5's control (42 / 9 still present when P5
    starts) assumes P6 left adoption alone. Needs one of: the JT rows named as P6 movers (red on the branch between P6
    and P5, attributed), P5 landing in the same stroke as P6, or adoption kept for JSON until P5.
    **Measured today, before any change, both settings (branch 50785a8 binary):** adoptT FIELD 1 / PROPERTY 4; yieldT
    DIRECT 3, OWNER 3; deferNatT through-the-recursion and drive-floor ok; convDriveT CD-1b ok; convLeakT CL-1/CL-2 ok;
    printFamilyNew graft [opPlusEQstruct opPlusEQstruct]; f122T and f122NatT all nine rows each ok; jsonTest 10 ok.
    ⚠⚠ **SEQ 197 -- RULING (i) ADOPTED (bypass at PTF=1, delete nothing; JT rows named movers, green at PTF=0, pinned
    red at PTF=1) -- AND P6 STOPPED AGAIN, ON "PARENT-DRIVEN FIRING" ITSELF, MEASURED.** The model (Tony 2026-09-24:
    the root's action fires, each action fires its components, all actions deferred) was run as an ENV-GATED EXPERIMENT,
    `PTF_ALLHELD=1`, two hunks, reverted whole after measuring: (1) ptfRecord records every ORDINARY fire as HELD;
    (2) ptfReplayRecords fires only the root after the held replay has installed every method, and aCTionStatemenT
    fires its held component (at the top level it only did bookkeeping -- "firedInLabel": the statement's action
    had already run). **Result: `incant/pop/loopBranchT`'s FIRST top-level statement, `register(LoopBranch);`, fails
    the parse and the file ends silently at exit 0.** Its chain StatemenT -> Xpress -> ExpressioN -> TokenXP -> NamE
    is all held; Xpress is a walker (it fires ExpressioN's held method), but **interpretXP (ruleActions.rtn:1580-1664)
    and aCTionTokenXP (:1062-1123) carry ZERO fire arms** -- they read their children's POST-fire state (`uxp` nodes,
    `registry == opFields`, `actionType || instructType`) and never fire them. The expression level is not written as
    walkers. **This is the model's own rule 3** (shape actions confined to their subtree still run during the parse)
    **and the split-action table's ExpressioN/NamE rows** -- but P6 names no shape class, and step 1's exempt list
    (code, outside, define, decides) does not contain TokenXP, ExpressioN or NamE, so under P6 as written they would be
    held. **RULING NEEDED before P6 can be built:** which class is held (parent-driven) and which stays as today (fired
    in post-order at the statement's end, or during the parse as shape). Candidate, NOT adopted: hold exactly the
    statement-level class -- the 15 `defer` rules plus StatemenT as root -- and leave the expression level replaying
    in post-order as step 1 does, until P7/P8 split NamE and interpretXP.
    ⚠⚠ **SEQ 198 -- THE HELD CLASS RULED, P6 BUILT, AND STOPPED ON THE JT LINE (MEASURED).** Rule: P6 holds actions
    that control whether or how often their children fire -- the statement-level class, the 15 `defer` rules under
    StatemenT; pure value nodes stay on step 1's post-order replay until P7/P8, because for them replay order IS
    evaluation order. **Pre-check (SEQ 198): AND/OR stay value nodes.** shortCircuitT's pairs driven as TOP-LEVEL
    statements (the fixture's own rows sit inside an action body, which step 1 never records): TSC-5..8 read 0/1/0/1 at
    PTF=0 and PTF=1 -- no unreached arm fires; the call runs under runShortCircuit at evaluation, not at replay.
    **The build (branch `p6-held-class`, 57f3e7a, NOT merged):** inside a top-level statement's scope a `defer` action is
    recorded HELD BY CLASS (deferredAbove is not asked for a recorded fire; PTF=0 asks it where trunk does); the root
    StatemenT's own replayed fire fires the held construct as owner and takes its VALUE, keeping its own label as
    outcome. Measured bare: PTF=0 763 / 1 == trunk row for row; PTF=1 761 / 1, the ONLY moved row is deferNatT
    "through the recursion" (named); jitLadder 215 at both; controls loopBranchT and top-level short-circuit unmoved.
    **THE LINE THAT CANNOT BE CASHED: SEQ 197's "JT rows pinned red at PTF=1".** JSONfield and JSONarray are VALUE nodes
    under the class rule, so their adoption survives P6 -- 42 / 9 at PTF=1 on the P6 binary -- and all 10 JT rows stay
    GREEN. SEQ 197 (P6 retires adoption; P5 repairs JSON) and SEQ 198 (value nodes keep step 1's replay, which adopts)
    cannot both hold. Also named but UNMOVED: adoptT FIELD stays 1 (Iterate -> s2C), yieldT DIRECT/OWNER 3/3,
    convDriveT CD-1b, convLeakT, printFamilyNew's grafts, f122T/f122NatT; adoptT PROPERTY 4 -> 1 (its row asks only for
    non-zero, so it stays green -- a loose pin). The unrun-IF fixture is not written.
    ⚠⚠ **SEQ 199 -- CERTIFICATE RESTATED (unrun IF with the switch off as control; adoptT PROPERTY 4 -> 1 attributed
    and pinned by value; deferNatT's re-pin sentence; PTF=0 == trunk). NOT LANDED -- LINE (1) CANNOT BE CASHED.**
    The switch exists: `PTF_NOCLASSHOLD=1` (p6-held-class, WIP commit) restores step 1's hold rule and no root fire;
    with it, adoptT's whole trace equals the pre-P6 branch's, addresses normalised -- a true control.
    **(1) FAILS:** five dead-arm side effects at the top level -- an action call, `++`, an assignment, a braced call, a
    print -- read **0 with the switch ON and 0 with it OFF** (live-arm sibling 1 in both). Step 1 already holds IF's
    arm: IF is a deferred ancestor, so deferredAbove holds its children. What P6 changes for an unrun IF is the VALUE
    it hands back (owner-run: labelNO to the statement; step 1: its own label as a yield), not whether its arm runs --
    and at the top level the root discards that value, so no side effect can see it. **(2) CASHABLE, ONE RESIDUAL:**
    PROPERTY reads 4 switch-off, 1 switch-on. The three top-level `cerr` statements (AD BEGIN, AD RETURNED, ADOPT
    SENTINEL) stop adopting: the root fires them as owner and takes the value. The one that remains is the PrinT inside
    `probeDrive(adPrint)`, still adopted -- but its returned node moved StatemenT -> true, measured and NOT explained.
    **(3)** the moved row's line (DEFERABOVE NumbeR held=1 end=deferred) is absent because deferredAbove is no longer
    asked for a recorded fire; "retire by mapping" needs a home for its question, and a PTF=1 absence row would break
    H4. **(4) HOLDS:** PTF=0 763 / 1, 54 red == trunk row for row, on the P6 binary.
    ⚠ Instrument note: an earlier "switch off" column was void -- zsh does not word-split an unquoted `$cfg`, so
    `env $cfg` set PTF to "1 PTF_NOCLASSHOLD=1" and never set the switch. Re-run with the variables spelled out.
    ⚠⚠ **SEQ 200 -- P6 WAITS (its own terms: "if not, P6 waits"). Work on `p6-held-class` (da782ce), NOT merged.**
    **(1) THE ROOT WITNESS IS BUILT AND THE ROW AS WRITTEN CANNOT BE CASHED.** `measureRootValue` (PTF_TRACE gated,
    reads what it is handed) reports, at a top-level statement's root, the value its construct handed back. Switch on:
    an unrun `if uiF; uiN = 1;` hands back **`uiF` -- its CONDITION's value**, not labelNO (a run IF hands back `uiN`).
    aCTionIF seeds `result` from the condition and nothing overwrites it when no arm runs, so the plan's parenthetical
    "today: labelNO owner-run" is wrong. Switch off (control): every root reads `value=StatemenT fired=0`.
    **(2) THE CANDIDATE IS NOT CONFIRMED -- the residual has a different cause.** Inside `probeDrive(adPrint)` PrinT is
    NOT held (`DEFERABOVE inDrive=1 held=0`, `walk rule=PrinT fired`): the drive's own scope applies step 1's rule, so
    its `true` is a direct-fire yield, not a held-class fire under ruling A. **The StatemenT -> true move is a TAG:**
    opPrint (and CerR) always return the shared `trueResult`; step 1's replay RETAGCARRY writes the label's tag onto the
    returned node -- `RETAGCARRY rule=CerR CerR -> StatemenT` -- so before P6 the first top-level `cerr` RENAMED THE
    SINGLETON "StatemenT" for the rest of the run. Under P6 the root fires those statements, no retag, and `true` keeps
    its name. The same line retags live fields: `RETAGCARRY rule=Iterate Iterate -> StatemenT` renames s2C.
    **(3)** not built (the presence pair waits on the landing).
    **THE OPEN QUESTION, verbatim for the next session:** *Does P6 carry "an unrun IF hands back nothing" as a change to
    aCTionIF (today it hands back its condition's value), gated so PTF=0 stays trunk-equal -- and is step 1's RETAGCARRY
    renaming a shared singleton and a live field a defect for P6 to stop, or for the value-node stroke?*
  - **P7 -- scope beyond top-level statements (SEQ 174 item 3, measured, traced fleet, PTF=1, 143 runs).**
    (a) ACTION BODIES (processCode): 74,476 fires during the parse today -- NamE 14,903, ANYtoken 14,903, TokenXP
    14,419, Parens 9,472, ExpressioN 8,546, StatemenT 8,358. What depends on them: the CACHED BlocK's shape
    (interpretXP's runOP/runShortCircuit nodes, TokenXP's handle* arms, Braced's fLAG) and NamE minting action locals
    at compile (bear-trap #39); the jit walks that BlocK. So the shape half stays at compile -- see the split table.
    (b) BOOTSTRAP: 2,512 outside fires PER RUN, constant (359,216 of 361,506): NamE 779, TraiT 679, NewGroup 330,
    DefinE 330, TraiTdata 222, QuotE 103, NumbeR 42, RunRulE 20 -- the grammar and registries themselves. ⚠ **RULING
    NEEDED: the Start() boundary** -- either setup parses under StatemenT, or outside-while-defining classes as define.
    (c) OTHER OUTSIDE: ~2,290 (an estimate by per-file remainder), sweepT 1,949 -- probe drives of non-StatemenT roots;
    their counters and verdicts depend on the fires. (d) NESTED DRIVES: 2,621 rejected, 12,410 records discarded; 0
    DRIVEREPLAY. Cert: the conservation row; the M1 per-rule fire multiset unchanged on the eight M1 fixtures plus
    jsonTest; P3's scoped-discard row goes NON-ZERO (its H7 pair); frontier's station unchanged.
    ⚠ **RULED (SEQ 179, Tony):** setup and grammar defines stay OUTSIDE as declared define-family; PIN the bootstrap's
    constant outside fires as a row; before building, REPORT what P7 makes non-zero in the scoped-discard row, and STOP
    if the answer is pulling setup's parse into scope.
    ⚠ **STATUS 2026-09-26 (SEQ 193 1a re-read) -- three premises MOVED, none of them yet re-measured:**
    (1) **The discard model.** (d)'s "2,621 rejected, 12,410 discarded" is P2's pre-(i) split. Since P2 (i) every record
    discards at its rule's own failure exit: the conservation row reads rejected **0** (a tripwire), failed-alternative
    **13,349**, UNREACHED 0. The certificate's "conservation row" is that row. (2) **Every count in (a)-(c) predates
    SEQ 191**, which retired 14 fixtures and 7 incant/setup registrations -- so the bootstrap constant SEQ 179 says to
    pin (2,512) is expected to have MOVED and is re-measured before it is pinned, never carried (H14). (3) **The
    non-zero answer SEQ 179 asks for, as the plan reads today:** driveDoorT's drives (tell/treeOf of a Scaf rule, driven
    from a top-level statement) have non-StatemenT roots, and extending the recording scope to them is what makes its
    discard row non-zero -- **not** setup's parse, so the STOP clause does not trip on that reading. It is a reading, not
    a measurement. **Unmoved:** the eight M1 fixtures all exist (oneTest, jsonTest, f122T, doWhileNameT, dotChainT,
    adoptT, fireSeatT, convDriveT); sweepT and jitProbeDrive's seat are still there (drive census).
  - **P8 -- Rule C's remaining sites (SEQ 174 item 4, against docs/overlapCensus.md direction 1).** A1, A3, A4, A5
    (unwrap at attach): retired in P6. A2 (ANYtoken reads NamE's resolution): ⚠ **RULING NEEDED -- C-form** (a direct
    text lookup in Keywords) was measured NOT neutral 2026-09-24. A6: no live instance. A7 (Braced's fLAG read by
    checkInput -- plant 4, fLAG's two meanings): NOT retired by step 2 -- its own stroke, either a second bit for
    "subscript" or the opGet shape rewrite (docket item 2), which retires Braced's subscript arm outright; ⚠ **Tony's
    choice of which**. A8 (the yield channel into sukcess/attach): P6. A9/A10 (refusals raised by ordinary actions,
    read by the parse): P6 with ruling (ii) -- an ordinary refusal no longer runs during the parse. A11 (search) and
    A19 (kant ops on rule nodes): between statements, decidable -- statement-end firing precedes the next parse.
    A13/A15: bracketed / compilation, decidable. A14: `blockSTAK` is not restored by processCode's bracket -- a small
    stroke. A12, A16, A17: the drive and code scopes, P3 and P7. One site the census lists under shape and is a Rule C
    read inside the shape class: **interpretXP reads the token's `registry == opFields` and `actionType ||
    instructType`, which NamE's resolution decides** -- the registry test can be answered by which Token alternative
    matched (a parse fact); the `invoke` marking moves to fire time.
  - **THE SPLIT-ACTION TABLE (SEQ 175 C, a measurement of the parked parse-time action slot; nothing built).**
    | row | parse-time half | walk-time half | the split falls at |
    |---|---|---|---|
    | ANYtoken (null fails the parse) | the keyword test -- but only as a TEXT lookup (C-form); today it reads `input.group` | none (returns its input) | ruleActions.rtn:7-8, `token = input.group` |
    | NamE (ordinary; its write is what A1/A2 read) | resolve against scope and, under processCode, MINT the local (a declaration: frame shape) | bind the label: `input.group = result` | ruleActions.rtn:663, the `endName:` write |
    | ShortcuT | whole action: `gCount == 2 && opFields[text]` is a registry lookup on matched text | none | -- (no split needed) |
    | CodE | whole action: it moves the mark | none | -- (needs its whole action at parse time) |
    | CheckFor | whole action: a parse stopper | none | -- |
    | DelimText | whole action: a shape rewrite of its own label | none | -- |
    | processAction's null (compile failure fails the parse) | ensure-compiled (`processCode`) | run the BlocK | GroupActions.rtn:564 -- compiling at define or first parse makes the null a parse fact again |
    | ExpressioN / interpretXP (shape) | build the runOP/runShortCircuit shape from which Token alternatives matched | `invoke` from `actionType || instructType` | ruleActions.rtn:1626, the invoke stamp |
    | define family (DefinE, NewGroup, TraiT, TraiTdata, SetBrackets, processFlags) | whole action (they build what the next statement parses against) | none | -- |
    Verdict for the parked slot: **two specimens need it (NamE, and interpretXP's invoke stamp); ANYtoken needs a
    different predicate, not a split; the rest are whole-action parse-time.** Not a population that argues for a
