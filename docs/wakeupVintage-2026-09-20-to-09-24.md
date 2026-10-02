# ⚠⚠⚠ SEALED 2026-09-24, SHUTDOWN -- PARSE-THEN-FIRE STEP 1 (TRY-AND-BUY) REACHES 660 / 662 ON ITS BRANCH.
# EVERY PLANT SO FAR IS ONE OF TWO CAUSES; THE NEXT SESSION DECIDES GO / NO-GO ON STEP 2.
#
#   ## THE ONE-LINE STATE: **trunk `jit-unified-emit-wip` at bf7182f + this seal, installed and BARE -- fleet
#   662 / 2 · jitLadder 214 ok, PASSED · canary 358 · fixit queue 0 · no incant process left. Branch
#   `parse-then-fire` at 0f77486, pushed: PTF=1 660 / 2, PTF=0 662 / 2 from the same binary.**
#
#   ## THE MODEL AND ITS RULINGS (Tony, 2026-09-24, via Fearless)
#   A parse builds a pure label tree and fires no ordinary actions; when a statement has parsed, its root
#   label's action fires, and each action decides whether, when and how often its components fire -- the
#   actions ARE the walker; a BlocK is a statement whose action fires its children.
#   1. The parse builds the tree; actions fire afterward, top-down, parent-driven, per statement.
#   2. A rule with content and no action gets a default: fire the components in order, yield the last value.
#   3. Only two kinds may run during a parse: parse-changing effects (immediateAction/parseAction -- define,
#      include, search) and SHAPE actions confined to their own subtree (ExpressioN's `+= A B` rewrite).
#   4. defer retires -- all actions are deferred -- at STEP 2, not step 1.
#   5. A field is typed once (at define, or by its first value) and never retyped; `+=` picks its method
#      per fire from the target's kind (or the argument's when empty), never cached on the node.
#   6. `:.` sets flags only; naming a data kind refuses by name (supersedes "opSetFlag clears data").
#   7. Both roads share one firing pass; the jitter compiles generated parse bodies as pure matchers.
#   Direction, not ruled: GroupFields entries carry a getter (and optional setter) that `.` calls.
#   **AMENDMENT (after Clod's Part 0):** premise "action bodies already work this way" withdrawn as written --
#   code bodies are parse-with-shape-and-a-few-effect-actions, then fire. PARSE-DECIDING code belongs to the
#   parse (a null return failing it, aCTionCodE moving the mark) and is exempt in step 1; NewGroup/MEMBERs are
#   define-family, exempt; step 1 covers TOP-LEVEL statements only (processCode untouched); the walk REPLAYS
#   fireLabelMethod's own fire-or-hold decisions and never recomputes deferral; the adoption channel stays.
#   **THE Start() BOUNDARY IS MEASURED, NOT RULED:** thousands of `class=outside` fires -- the setup and
#   grammar defines are not parsed under StatemenT, so step 1 never touched them.
#   **RULE C: ATTACHING NEVER READS WHAT AN ACTION WROTE.** The label tree must be decidable from the parse
#   alone. Step-2 rule; recorded in the branch's pause docket (docs/jitDesign.md).
#   **FIRE-TIME KEYWORD CHECK:** ANYtoken still decides during the parse and ALSO re-runs today's test at
#   replay, after NamE has resolved; a keyword used as a name refuses loudly there.
#
#   **SHAPE-REWRITE ITEM (Tony, 2026-09-24):** `field[whatever]` becomes `opGet field whatever` in the ExpressioN
#   rewrite, beside `A += B` -> `+= A B`; opGet picks its method per fire by the key's kind. Preserve: unary binds to
#   the primary (`*a[0]` = `(*a)[0]`), subscript stops at the element. Retires TokenXP's subscript arm (and the
#   subscript meaning of fLAG, plant 4). Full entry in the branch's pause docket.
#
#   ## STEP 1 ON THE BRANCH -- the engine, the plants, the fixes
#   Engine: fireLabelMethod RECORDS an ordinary fire or hold inside a top-level statement (ptfRecord); the
#   top StatemenT's fire REPLAYS the records reachable from its label tree, in record order (ptfStatementEnd).
#   Switches: PTF=0 is trunk behaviour from the same binary; PTF_TRACE=1 arms M1 (measureFireOrder) and M2
#   (measureParseFire). M2 on kant8T: ORDINARY parse-time fires 553 at PTF=0, **0 at PTF=1**.
#   | # | plant | fix | fleet |
#   |---|---|---|---|
#   | 1 | attachLabel's unwrap (`promote && isGROUP && max>1`) reads isGROUP, which NamE's action writes -- `search A B;` attached bare GrouP labels | ruling A: ONE predicate `GroupItem::unwrapsOnAttach`, asked again at replay with the max/promote of the attach that placed the label WHOLE (GrouP's, not NamE's) | 598 -> 656 |
#   | 2 | aCTionANYtoken (exempt) refuses keywords by reading NamE's resolution -- `if ;` parsed as an expression | the fire-time keyword check | refuses loudly |
#   | 3 | MY replay set fLAG on an unwrapped label; fLAG = "recycle this shell", so the next statement reused a still-parented label (doWhileNameT `dwN= Token`) | replay clears, never sets fLAG | +1 |
#   | 4 | fLAG's SECOND meaning: aCTionBraced sets it for "subscript"; checkInput reads it as "recycle" -- a Braced label still in a code body's cached tree is reused, attached as a body-sharing COPY, and the record held the original (deferNatT dfPrint) | reachability by groupBody | 660 |
#   ⚠ **Plant 4 exists ON TRUNK**: `measureLabelReuse` fires at PTF=0 (a recycled label still parented). Latent
#   trunk defect, exposed by step 1, not caused by it. One channel, two meanings.
#   Measured and NOT needed: the parse-entry record frame (a drive during replay flushes itself). The replay
#   frame stays and logs FRAMELEAK (37, all near-miss drives in site1RoadsT/probeDoorT).
#   C-FORM (ANYtoken asking Keywords directly) measured NOT NEUTRAL: 327 decision disagreements at trunk timing
#   (define 227 -> the define rule, new 58 -> the new command, this 1 -> no registry, in a CodE parse); the
#   fleet run with it (killed) moved chainTruthT, searchNewParseT, dotChainT/testPrecedence (exit 139), opRoadT,
#   directives. Switch KW_DIRECT kept; recorded as not neutral.
#
#   ## THE ERROR-DIFF, trunk vs branch (every mover named)
#   | row | trunk | branch | why |
#   |---|---|---|---|
#   | `if ;` `do print 1;` `else s2Y = 2;` | ABANDONED -- the rest of the file never parses | `REFUSED <kw> -- a KEYWORD used as a name`, the statement refused, the file continues | late refusal, by design |
#   | probeDoorT stmtRejT, site1RoadsT (22 pairs), DO #2 verdict 0 -> 1 | the parse rejects the near-miss | the parse accepts; the refusal comes at fire time | same, by design -- these rows pin PARSE verdicts |
#   | tripwire 413 -> 420, loopVerdict 13 -> 12 (green rows) | -- | -- | **NOT ATTRIBUTED** |
#   Step-1 certificate items NOT yet run: M1 identity trunk vs branch on a named list (oneTest, jsonTest, f122T,
#   doWhileNameT, dotChainT, adoptT, fireSeatT, convDriveT); station 2's fires column (predicted unmoved -- it
#   counts generated parse-body runs at parseRule's door, i.e. DURING the parse); jitLadder on the branch.
#
#   ## THE OVERLAP CENSUS -- docs/overlapCensus.md (ON THE BRANCH), 55 overlaps, 8 causes
#   label `group` / name resolution 9 · label shape at attach (retag, reuse, hold stamps, null yield) 9 ·
#   define and registry state 14 (exempt) · input-stream state 10 · method/frame context 6 · refusal 3 ·
#   misc 3 · step 1's own globals 1. **EVERY PLANT LIVES IN THE FIRST TWO** -- both are rule C.
#
#   ## GO / NO-GO -- what the next session decides
#   GO needs all three: (1) step 1's certificate met with every divergence named and ACCEPTED (the error-diff
#   above, plus the two unattributed value moves attributed); (2) fixes still clustering in the two families;
#   (3) step 2's retirements -- defer, deferredAbove, the yield channel -- confirmed deletable in principle.
#
#   ## PARKED
#   deferNatT's stale parent -- ANSWERED: it was plant 4, and it exists on trunk (fLAG's two meanings) ·
#   gParseActive at replay (unbuilt; the activations are gone by then, so it needs snapshots) · the Keywords
#   tidy-up for new/this (the two readers, GroupItem.twk:1853 and aCTionBlocK's bare return, need neither) ·
#   the per-word KW_DIRECT split (single fixture under an alarm, never the fleet) · the pause docket's other
#   items · station 3 · the two owed rulings (the yield channel, parseLoop's silent success at max) · Tony's
#   cleanup items (bs not run; BeforeSave still holds the previous clean kitchen).
#
#   ## FINDING AT SEAL, not chased: decodePop is RED AT TRUNK
#   5 red rows -- "82 of them carry a definition (got '0')", self-cert and the H4/H7 decode lines absent --
#   on bf7182f built from its own committed .mm. This morning's seal records decodePop 14 green on the same
#   tree. Either the morning number was carried (H14) or something outside the tree moved. One run of
#   incant/decodeT with its output read is the next step.
#
#   ## CHECKLIST, measured at this tree (H12, H14) -- date checked, 2026-09-24 18:16
#   pop.sh 662 / 2 · jitLadder 214 ok, PASSED · **decodePop FAILED (5 red, above)** · ddPop 5 / 1 ·
#   countPop 47 of 47 attempted, foot reached · frontier dies at station 4 (fire) · canary 358 · retok bare ·
#   groups.ext untouched · Groups, support, TOK clean and pushed · no incant process · fixit queue 0.
#
#   ## TONY'S FIXIT INCANTATIONS WAITING: **0**
#   Generated by `genLadder/fixitNag.sh`, not typed.

# ⚠⚠⚠ SEALED 2026-09-24, PAUSE -- JITTER STATION 2 CERTIFIED IN ONE PROCESS: 45 CARRIERS AGREE, DEGRADE 0,
# PINNED IN THE FLEET (sweepT). THE JITTING PAUSE IS HERE; THE DOCKET IS IN docs/jitDesign.md.
#
#   ## THE ONE-LINE STATE: **trunk at e87f194 + this seal -- fleet 662 green / 2 parked, red set unmoved all day ·
#   jitLadder 214 ok, PASSED · canary 358 · fixit queue 0 · binary BARE · no stale incant process.**
#
#   ## WHAT CLOSED TODAY (each with its control; docs/fixIts.md carries every attempt log)
#   F-114 (sites 1-3 and the hangs; parseRule's per-call bracket) · F-116 · F-117 (`.5` refused by name) · F-120 ·
#   F-121 · F-122 (Xpress `defer`; loops and IF yield their label fired directly, their value owner-run) ·
#   F-123 (runOP's jitting term call covers a bin with a generated parse -- Operators was parsed at emit time) ·
#   F-124 (container lookup stops at its longest hit -- on the new road `==` ASSIGNED and `+=` did nothing) ·
#   F-125 (a drive restores the caller's lastIndent and defining). Fleet 465 -> 662 green.
#
#   ## STATION 2
#   `SWEEP END carriers=65 skipped=4 nopick=16 certified=45 agree=45 diff=0`, exact-line sentinel, no degrade line.
#   **Coverage is 45 of 61**, not 45 of 45: the 16 unpicked carriers are named with measured reasons in F-114 entry
#   23 -- four are a pairs gap (if/else, if/or, for/attributes), two wait on F-126, seven on F-127, two are not
#   Grokking names, one (DelimText) needs a pairs-file line.
#
#   ## NEXT SESSION -- TWO OPENINGS, THE PAUSE FIRST (Clay's lean)
#   1. **The pause work** (docs/jitDesign.md, THE PAUSE DOCKET): the actions-and-ops census toward one method per
#      case (the per-kind `+=` split at its top), run TOGETHER with the C++-escape recon, and the measure* move from
#      Generate.rtn to measure.twk. Read against Tony's direction: the parse builds a pure label tree per statement,
#      a second pass does the work.
#   2. **Station 3 onward**, after the cheap coverage lines (pairs.sweep, ~50 of 61), F-126, F-127, and a road-parity
#      sweep.
#   **3. Tony's cleanup items, pending, addressed on wake-up AFTER the docket items** (Tony, 2026-09-24). He has not
#      run bs yet (read as the BeforeSave refresh), so BeforeSave still holds the previous clean-kitchen state.
#   Rulings owed at the pause: the yield channel (F-122 entry 7; the (b) guard stays unarmed, adoptT pins the
#   live-field count at 1) and parseLoop's silent success at max (F-114 entry 24).
#
#   ## CHECKLIST, measured at this tree (H12, H14) -- date checked against the last commit, 2026-09-24 13:51
#   pop.sh 662 / 2 parked, reds identical to the start-of-day capture · jitLadder 214 ok, PASSED · decodePop 14 ·
#   ddPop 5 / 1 · countPop 47 of 47 (standing) · frontier dies at station 4 (fire) · canary 358 (+1 today:
#   measureAdoption) · retok bare · groups.ext untouched · Groups, support, TOK clean and pushed · fixit queue 0 ·
#   **stale processes killed**: this session's hung `nat5` probe (4 h) and an F-122-era `f122NatT` run (1 h).
#

# ⚠⚠⚠ SEALED 2026-09-23, SHUTDOWN -- JITTER STATION 2 ON THE FIRST FIVE: DO CERTIFIED BOTH SIDES,
# FOUR ACCEPTING SIDES; THE REJECTS ARE BLOCKED ON THE INTERPRETER, WHICH SEGFAULTS WHERE A PARSE
# SHOULD FAIL. TOMORROW OPENS ON THAT CRASH (F-114). THE FULL SWEEP WAITS ON IT.
#
#   ## THE ONE-LINE STATE: **trunk at 3aefb72 + this seal -- jitLadder 214 ok, PASSED · fleet 465
#   green / 2 parked, unmoved · canary 348 · fixit queue 0 · binary BARE · no stale incant process.**
#
#   ## COVERED (jitted first, one compile, then the oracle; every row agrees on verdict / consumed /
#   ## term calls / the rule's own fires and successes; degrade 0)
#   | rule | accepting input | rejecting input |
#   |---|---|---|
#   | **DO** | `do print 1; while 1 < 0;` 1/24, t=54 | `do print 1;` fires 1, true 0 -- **CERTIFIED** |
#   | StatemenT | `print 1;` 1/8, t=25 | `}` **VOID** -- the body never runs (fires 0) |
#   | IF | `if 1 < 0; s2Y = 1;` 1/18, t=67 | **BLOCKED** -- every near-miss crashes the interpreter (F-114) |
#   | WhilE | `while 1 < 0; s2Y = 1;` 1/21, t=68 | **BLOCKED** (F-114) |
#   | PrinT | `print 1;` 1/8, t=25 | **BLOCKED** (F-114) |
#   Two fires per input per road; the term count is the short-circuit witness and agreed on every row.
#   Measured before the stop, interpreted only, NOT certified: firing rejects `@` (StatemenT), `ifx;`
#   (IF), `printx;` (PrinT).
#
#   ## LEFT
#   The other 55 generated bodies (the sweep -- tomorrow, after F-114). The five still falling back
#   (Limit, Token's right operand, TokenXP, UnaryXP, IterSource). The spelling checks in the
#   interpreter files. The stuff-face naming key.
#
#   ## HOW THE PROBE WORKS NOW, because two harness defects ate the afternoon
#   - **A top-level drive of a member rule REFUSES on the interpreted road**: "checkInput: no enclosing
#     activation to take the label" -- DO, IF, WhilE, PrinT, CerR, BlocK, Search, NumbeR, QuotE, FOR,
#     Iterate, BrancH. While armed, every term returns null (0 term calls), and it leaked into the next
#     probe. So rules are reached NESTED from StatemenT or ExpressioN, and a DOOR at parseRule's BlocK
#     fire watches the rule's carrier (fires, successes) and, jitted, fires its compiled body there.
#   - lldb evaluating `carrier->parent` hung; a probe that timed out reported lldb's STALE stop reason
#     ("breakpoint 1.1"), which read as a breakpoint problem. It was a hang.
#   Harness: `jitLadder/station2/` -- probe.py, sweep.sh, pick.py, compare.py, pool, pairs, crashpairs,
#   five/.
#
#   ## THE 28 CRASHING PAIRS, BY FUNCTION -- three sites, likely three fixits (F-114 carries the table)
#   | site | fault | inputs |
#   |---|---|---|
#   | `interpretXP` GroupRules.mm:4043 | null+0x10 | 29 -- every statement near-miss, `search`, `else`, `#`, `)`, `"`, and statements driven through ExpressioN |
#   | `aCTionQuotE` GroupRules.mm:1024 | null+0x0 | 7 -- every quoted input |
#   | `aCTionTokenXP` GroupRules.mm:1367 | null+0x0 | 2 -- a leading unary (`-1`, `.5`) |
#   | hang | -- | `s2L(1)`, `s2L[1]` |
#   (40 inputs driven: the 28 banked pairs plus the IF/WhilE/PrinT near-misses and F-114's originals.)
#
#   ## ONE PROCESS PER RULE -- NOT NEEDED FOR COMPILING ANY MORE, STILL THE SAFE CHOICE UNTIL F-114
#   The naming fix lets 62 of 65 bodies compile together (the 3 extra stuff faces collide). The probe
#   compiles per rule with compile-only and clears `refused` either side of a drive, so a batch in one
#   process works. What still argues for isolation is **F-114 itself**: a crash kills the process and
#   every rule queued behind it, and the crash set was measured once and excluded rather than fixed.
#   **Recommendation: once F-114 closes, run the sweep in ONE process** -- the carrier walk (the slow
#   part, ~10s) then happens once instead of 60 times. Keep the stuff faces aside until their naming key.
#
#   ## CHECKLIST, measured at this tree (H12, H14)
#   pop.sh 465 / 2 parked · jitLadder 214 ok, PASSED (+1: the JS R3 rider, H7 control run) ·
#   decodePop 14 green · ddPop 5 / 1 · countPop 47 of 47 · frontier dies at station 4 (fire) ·
#   canary 348 · retok bare · groups.ext committed · Groups, support, TOK clean and pushed ·
#   **stale incant processes killed**: three `f108` runs from another session (6-8 h), `msScratch2/3`
#   (1 day+), and two of today's hung probes; Xcode's lldb-rpc-server left alone.
#
#   ## TONY'S FIXIT INCANTATIONS WAITING: **0**
#   Generated by `genLadder/fixitNag.sh`, not typed.

# ⚠⚠⚠ SEALED 2026-09-23, LATE AFTERNOON -- JITTER STATION 1: FIRST LIGHT. ExpressioN COMPILES TO A
# REAL CALL-THROUGH AND AGREES WITH THE INTERPRETER BY VALUE; EVERY JITTED BODY IS NOW i32(ptr).
#
#   ## THE ONE-LINE STATE: **trunk at e3001a9 + this seal, support at 07cab37 -- jitLadder 213 ok,
#   PASSED · fleet 465 green / 2 parked, rows unmoved · canary 348 · fixit queue 0 · binary BARE.**
#
#   ## WHAT LANDED
#   - **The call-through.** A rule invoked as a term (`Token()`) was PARSED AT EMIT TIME by runOP's
#     isRule arm -- traced, inside jitBuildFunction. Under jitting that arm now emits
#     `call i32 jitTermCallRT(<node>)`, which at run time is `truthOf(runOP(node))` -- the
#     interpreted dispatch, one spelling on both roads.
#   - **Uniform `i32(ptr)`.** Function type, driver call, refire, `rStuff.jitMethod` (+ groups.ext,
#     support 07cab37), jitFieldMethod, and the emitted self-call. The pointer is `jitBodyField`:
#     what the action's `argument` holds now, or null. No emitter reads it yet -- station 4's door
#     passes the carrier's frame through it.
#   - **`jitProbeDrive(rule, msg, jitted)`** -- driveStep's own push/fire/offset/pop with the fire
#     switched. The certificate's instrument; lldb-driven until the door exists.
#
#   ## CERTIFICATE (jitted first, one compile, then the oracle)
#   | msg | jitted verdict/consumed (two fires) | interpreted |
#   |---|---|---|
#   | `abc` | 1/3 · 1/3 | 1/3 · 1/3 |
#   | `}` | 0/0 · 0/0 | 0/0 · 0/0 |
#   | `42 rest` | 1/7 | 1/7 |
#   Degrade 0, compile count 1 over five fires. **H7 control, arm disabled:** every jitted row
#   0/0 (`ret i32 0`), and the emit walk parses the grammar at compile time -- 202 degrades.
#   **Ladder re-pin, with its sentence:** JS R3 matched `@jit_x()`; the new text is
#   `@jit_x(ptr %field)`, so its self-call ban passed BY ABSENCE. Patterns end at the open paren.
#   JA's IR byte count moved 1266 -> 1276 in its label. Nothing else moved.
#
#   ## ⚠ NOT CERTIFIED, AND THE NEXT STROKE'S SUBJECT
#   **60 of 65 generated bodies now compile with NO degrade line** -- `&&`/`||` operands reach the
#   same runOP arm, so DO compiles to six call-throughs in short-circuit diamonds. Degrade 0 is not
#   a value certificate; station 2 owes the jitted-vs-interpreted rows. Still degrading: Limit,
#   Token (right operand), TokenXP, UnaryXP, IterSource.
#
#   ## RIDERS
#   - **F-55 does NOT pass -- and no writer skips the slot.** The jitted stores land in the count
#     cell; `jdCount` is DATA-LESS and a baked scalar store never marks it as holding a count, so it
#     echoes its tag. `jdCount = 7;` first -> jitted 3/4, matching. Located in `docs/fixIts.md` F-55.
#   - **`op.tag eq` census:** none left in `jitEmitters.rtn`. Spelling selections remain at
#     `ruleActions.rtn` 593 (`*`), 1261/1420/1429/1651 (`.`), 1342 (`=`), 1497-1498 (`-`/`*` to
#     negate/deref); `GroupActions.rtn` 398 (`buffer`), 1511/1513 (`immediateAction`/`parseAction`);
#     `Commands.rtn` 635/638/698 (`class`/`register`/`bail`). Listed, not judged.
#
#   ## FINDING, not chased
#   ExpressioN on the INTERPRETED road crashes on `)`, `#` and `"` -- EXC_BAD_ACCESS at 0x10 in
#   `interpretXP` (GroupRules.mm:4043). `}`, `;` refuse cleanly; `@` matches.
#
#   ## STANDING, new today
#   Bisects run in a clone OUTSIDE Dropbox -- now in CLAUDE.md with the check that lists what an old
#   commit tracks and HEAD ignores. `groupDirectives` and `incant++` were restored by Tony from Time
#   Machine after the in-place bisect deleted them.
#
#   ## CHECKLIST, measured at this tree (H12, H14)
#   pop.sh 465 / 2 parked · jitLadder 213 ok, PASSED · decodePop 14 green · ddPop 5 / 1 · countPop 47
#   of 47 · frontier dies at station 4 (fire) · canary 348 · retok bare · groups.ext committed
#   (07cab37) · Groups, support, TOK clean and pushed.
#
#   ## TONY'S FIXIT INCANTATIONS WAITING: **0**
#   Generated by `genLadder/fixitNag.sh`, not typed.

# ⚠⚠⚠ SEALED 2026-09-23, EVENING -- THE JIT LADDER FLOOR IS GREEN: jitLADDER PASSED, 213 ok. JC AND
# JXD WERE BROKEN BY THE 09-01 FRAME BIND, THE 09-02 NODE YIELD AND THE 09-10 `&&` RESPELL.
#
#   ## THE ONE-LINE STATE: **trunk `jit-unified-emit-wip` at 221c1bb + this seal -- jitLadder 213 ok,
#   exit 0, PASSED · fleet 465 green / 2 parked, rows unmoved · canary 344 · fixit queue 0 · binary
#   BARE and built at the tree.**
#
#   ## RULINGS RECORDED (Tony, via the dispatch)
#   Call-through first, inline later. Jitted bodies take a UNIFORM `i32(ptr)` -- the pointer is the
#   field the body runs on (an action's argument, a parse carrier's frame). One layout change, paid
#   in STATION 1's stroke. The stuff-face naming key is deferred until a stroke needs it.
#   **Standing: every seal runs `jitLadder/ladder.sh` and records its line beside pop.sh** --
#   now in CLAUDE.md's H12 checklist.
#
#   ## WHEN EACH WENT RED, AND WHY (measured by building trunk commits)
#   | rows | first red | cause | fix |
#   |---|---|---|---|
#   | JXD-1, JXD-3 | **2b39d87** (09-10), green at its parent | the `&&` respell of the fixtures; `jitEmitShortCircuit` still chose direction by `op.tag eq "AND"` -- the third spelling list, so `&&` compiled as OR | `!opIsOR(op)`, the registration |
#   | JC | **9ad1e5a** (09-01, C8 frame bind) by first-parent bisect, 306148d green | the jitted walk RUNS AWAY | see layers |
#   | JC, reshaped | **18d37f7** (09-02, C26 opDot yields the node) | walk STOPS AT ROOT -- hid the runaway | frame-slot reload |
#   **JC was two fixes, found one under the other:**
#   1. `jitEmitAssign`'s node branch writes the FIELD; a frame local's reads load its SLOT, and the
#      epilogue wrote the stale prologue value back. The branch now reloads the slot from its home.
#   2. With that in, the walk recursed on dfRoot until exit 139: since the 09-04 class-(e) respell
#      the call is `displayForm(*grup)`, the star is a run-time deref, runAction hands the self-call
#      a NULL argument, and `if (argument)` skipped the bind silently. `jitEmitSelfCall` now binds
#      the published `gJitResultNode` through `jitBindArgRT`.
#   ⚠ The 09-01 bind-order layer was NOT re-driven on today's spelling -- a bare `grup` is now the
#   cursor holder and the interpreted oracle itself prints `grup grup`, so that control is VOID.
#   That the 09-05 pending-slot bracket made the order irrelevant is a reading, not a measurement.
#
#   ## ⚠ HOUSEKEEPING THE BISECT COST, AND WHERE IT IS
#   Building old commits IN PLACE in a Dropbox folder races the sync: `minionWork/` is tracked
#   before 09-11 and not after, so checkouts across that line created and deleted 105 files and
#   Dropbox wrote back older copies and "conflicted copy" files. **All of it is stashed, not
#   dropped:** `stash@{0}` "dropbox-resync debris from bisect checkouts 2026-09-23 (Clod)". It is
#   Clod's own debris, explained, nothing of Tony's -- drop it when convenient. Future bisects:
#   stay on one side of 09-11, or expect this. The TOK project also lists `measure.mm`, absent
#   before 09-04; an empty placeholder was created per build and removed.
#   Also seen, not touched: long-running `incant` processes from other sessions (`f108`,
#   `msScratch2/3`, hours to a day old).
#
#   ## CHECKLIST, measured at this tree (H12, H14)
#   pop.sh 465 / 2 parked · **jitLadder 213 ok, exit 0, PASSED** · decodePop 14 green · ddPop 5 / 1 ·
#   countPop 47 of 47, foot reached · frontier dies at station 4 (fire) · canary 344 · retok bare ·
#   groups.ext untouched · Groups, support, TOK clean and pushed.
#
#   ## NEXT: STATION 1 -- first light on `ExpressioN = { return Token(); }`, call-through, and the
#   `i32(ptr)` layout change paid in the same stroke. `jitLadder/carrierRecon/recon.sh` is its probe.
#
#   ## TONY'S FIXIT INCANTATIONS WAITING: **0**
#   Generated by `genLadder/fixitNag.sh`, not typed.

# ⚠⚠⚠ SEALED 2026-09-23, AFTERNOON -- JITTER STROKE 0 LANDED: THE SILENT RETURN IS LOUD, A CARRIER'S
# FUNCTION IS NAMED FROM ITS RULE, AND THE PARAMETER QUESTION IS ALREADY A NAMED SEAM.
#
#   ## THE ONE-LINE STATE: **trunk `jit-unified-emit-wip` at f5b4e89 + this seal -- fleet 465 green /
#   2 parked, rows unmoved; canary 344; fixit queue 0; binary BARE and built at the tree.**
#
#   ## WHAT LANDED (f5b4e89)
#   - **The silent return degrades.** `aCTionBrancH` clears `gJitResult` before a return's operand is
#     evaluated; a return WITH an operand that leaves nothing in flight calls
#     `jitDegrade("return operand produced no value")`. The recon's 13 constant-0 rules now each
#     count 1. ⚠ **The 52 are NOT unmoved in count**: their first failing construct is unchanged
#     (51 AND/OR LEFT, endDef's bare read of a LIST), but each now also prints the return line
#     (count 2), because their `return` stores 0 too. That is truthful, not a misfire.
#   - **`-3` CONFIRMED, then fixed.** LLVM's text: `duplicate definition of symbol '_jit_builtinParseR'`.
#     A noPrint carrier is now named from its holder (`jit_ExpressioN_builtinParseR`); ordinary
#     actions keep `jit_<tag>`. ExpressioN then ANYtoken in one process: both compile, both 0.
#     **All 65 in one process: 62 compile, 3 fail** -- `'_jit_stuff_builtinParseR'`: the four `stuff`
#     faces are FOUR DISTINCT carriers under one rule name. Naming by holder cannot separate them.
#   - `addIRModule` failures now print LLVM's reason instead of a bare `-3`.
#
#   ## THE READ -- a field parameter (`i32 @jit_X(ptr)`), measured by grep, nothing built
#   ⚠ **It is already a named seam**: `RuleStuff.twk:59-74` (2026-08-05) says the nullary slot holds
#   only while the caller is EMITTED code, and that POINTER-SLOT DISPATCH FROM C++ -- parse() calling
#   a jitted generated method -- FORCES a real parameter, "decided the day the first generated method
#   is jitted", and that widening it is a LAYOUT change (bear-trap #10).
#   | site | today | what the parameter touches |
#   |---|---|---|
#   | `jitBuildFunction` `jitEmitters.rtn:190` | `FunctionType::get(i32,false)` | the one place the type is minted |
#   | `jitRunAction` `:2724` | `sym->toPtr<int(*)()>()`, calls `fp()` | cast and call need the field |
#   | `gJitLastFn` `jitContext.h:152` / `jitRefire` `:2464` | `int(*)()` | refire needs a field to pass |
#   | `rStuff.jitMethod` `RuleStuff.h:104`, `groups.ext:763` | `int(*)()` | **layout change** -- groups.ext + tokall |
#   | `jitFieldMethod` `:1785` / `:1813` | `stuff->jitMethod()` | the pointer-slot caller |
#   | inline self-call `:1498` | `CreateCall(target, {})` | emitted call must pass the operand -- or stay on the FIELD ROUTE (ruled 2026-08-05, `jitBindArgRT`) |
#   | `jitRunIfTest` `:2820/2854`, addTwo `:2769/2787` | own nullary functions | untouched -- separate modules |
#   **Ladder exposure**: 6 fixtures, all reached through `testing()`/`jitRefire`/`jitFieldMethod`, so
#   they go through the two call sites above, not their own signatures.
#   **Can argument-free actions coexist? Yes, cleanly, if the type is chosen per function** -- a
#   carrier gets `i32(ptr)`, an ordinary action keeps `i32()`. The cost is that `gJitLastFn` and
#   `jitMethod` then hold two types, so each needs either a second slot or a uniform `i32(ptr)` with
#   ordinary actions ignoring the argument. **The uniform form is one layout change; the split form
#   is two slots.** Not chosen -- that is the ruling.
#
#   ## FINDINGS, reported not chased
#   - **jitLadder is RED AT HEAD** and the seal never said so: JC x2 (engines disagree; never reached
#     depth 3) and JXD-1/JXD-3 (fire 1 = 1, want 0). 209 ok. Identical before and after stroke 0.
#   - The four `stuff` carriers collide by name (above). Needs a name that is not the rule's tag.
#
#   ## THE INSTRUMENT: `jitLadder/carrierRecon/recon.sh list|one <n>|each|all`
#   lldb-driven, stops after parser(DO), jits carriers straight through `jitRunAction` (testing()
#   cannot reach one: a carrier is not isCoded). Echoes the binary; `each` ends in a sentinel.
#   ⚠ Read DEGRADE lines from `jitRunAction: entering`, never from lldb's PICK line -- the Python
#   print lands AFTER the process's stderr, and the first summary read ZERO degrades on all 65.
#
#   ## CHECKLIST, measured at this tree (H14)
#   pop.sh 465 / 2 parked (rows identical to HEAD's build) · decodePop 14 green · ddPop 5 / 1 ·
#   countPop 47 of 47, foot reached · frontier dies at station 4 (fire) · canary 344 · retok bare ·
#   groups.ext untouched · Groups, support, TOK clean and pushed.
#
#   ## TONY'S FIXIT INCANTATIONS WAITING: **0**
#   Generated by `genLadder/fixitNag.sh`, not typed.

# ⚠⚠⚠ SEALED 2026-09-23, MIDDAY -- DO PARSES END TO END ON THE NEW ROAD, F-95 IS CLOSED, AND
# THE JITTER RECON SAYS THE JIT CAN EMIT NOTHING OF A GENERATED BODY YET. THAT IS WHAT IS IN FRONT.
#
#   ⚠ DATE CHECK: `date` reads 2026-09-23 12:22 and `git log -1 --date=iso` 11:59 (1f3b13a). They agree.
#
#   ## THE ONE-LINE STATE: **trunk `jit-unified-emit-wip` at 1f3b13a -- fleet 465 green / 2 parked
#   (54 FAIL lines); canary 344; fixit queue 0; Groups, support and TOK clean and pushed; binary BARE
#   and built at the tree.** `bs` is Tony's to run -- not run this session.
#
#   ## ⚠⚠⚠ IN FRONT: THE JITTER. THE RECON, IN FULL (measure only, nothing built)
#   **How it was run.** parser(DO), stop under lldb (breakpoint on stopParsingInput CONDITIONED on DO
#   having its builtinParseR -- stopParsingInput also serves bail()), then jitRunAction on each
#   generated body, ONE PROCESS PER RULE (65 runs), INCANT_JIT_DUMP=1 on 16 of them for the IR.
#   ⚠ Three traps met on the way, each a void reading if believed:
#     - the unit is the rule's **builtinParseR carrier**, not the rule: DO is actionType 1 (aCTionDO),
#       so testing(DO) routes to jitRunIfTest and jitRunAction(DO) returns -2 "no result emitted";
#     - kant cannot probe DO: naming the rule inside an action FIRES it and the refusal aborts the action;
#     - jitRunAction called twice in one process returns -3 (addIRModule/lookup failed,
#       jitEmitters.rtn:2690/2768 -- symbol collision), so every rule needs its own process.
#   **THE RESULT: all 65 bodies compile, and EVERY ONE compiles to the same empty function** --
#       define i32 @jit_builtinParseR() { entry: br %epilogue ... epilogue: store i32 0; ret i32 0 }
#   no `call` instruction anywhere. Per construct:
#     | term call `X()`                  | NOT EMITTED -- runs interpreted at emit time (per the degrade text; not measured separately) |
#     | `&&` / `||` with a term call left | DEGRADE: `AND/OR LEFT operand produced no value -- not JIT-supported yet, running INTERPRETED: Token` (51 rules) |
#     | endDef's body                    | DEGRADE: `bare read of a LIST -- parts must be classified by the caller ... Token` |
#     | `return X();`, a single term     | ⚠ SILENT -- no value, NO degrade line; the epilogue stores constant 0 (13 rules) |
#   **The term call, hop by hop:** chain operand -> jitEmitShortCircuit (jitEmitters.rtn:1511) emits
#   only an isMethod+invoke node; a term call is a `Token`, so it goes to jitEmitBareRead, which emits
#   nothing, and the degrade fires at :1524. Single-term return -> aCTionBrancH's return arm
#   (ruleActions.rtn:113-116) sends it to the same bare read, silently, and jitEmitReturn closes to the
#   epilogue. handleCall (ruleActions.rtn:1357), runOP, runRule, driveStep and parseRule have NO
#   jitting arm: the call is neither inlined nor emitted as a call-through.
#   **Per-rule verdict.** 52 NOT JITTABLE, first failing construct the && / || left term call (endDef:
#   the list bare read) -- DO, StatemenT, BlocK, WardeD, Token, IF, FOR, WhilE, PrinT, Search, TokenXP,
#   NumbeR, define, and the rest. 13 COMPILE TO A CONSTANT 0 at degrade count 0 -- ExpressioN, ANYtoken,
#   rules, Looper, the four `stuff` faces, scopeList, definitions, NewGroup, Attributes, formatWIDTH --
#   which is WORSE than a degrade: a silent wrong answer. So the degrade counter cannot certify a
#   jitter; its rows must assert VALUES (consumed and verdict, jitted against interpreted).
#   **Candidate first subject:** a single-term body -- `ExpressioN = { return Token(); }` or
#   `ANYtoken = { return NamE(); }`. It lacks exactly ONE construct: a term call emitted as a real call
#   whose truth feeds the return. That same emitter then answers the && / || operand for the other 52.
#   ⚠ The jitted function takes no arguments (`i32 @jit_builtinParseR()`), and a parse needs the drive's
#   mark and frame -- so the likely first shape is a CALL-THROUGH to runRule/driveStep, not an inline.
#   **Floor check:** not run -- nothing jits. By the IR alone every jitted body returns 0, so it would
#   disagree with the interpreted parse on any matching input.
#
#   ## TODAY'S CLOSURES (all on trunk, all pushed)
#   - **The input floor and hereAt** (e5c0dcb, b618a0b): a drive's own message is the floor, so an
#     end-of-message failure no longer pops into the sender; checkInput sets hereAt before its
#     end-of-input exit. convLeakT green. modSeamT MS-1/MS-3 re-pinned to consumed 1.
#   - **The parseContainer re-resolve and F-108 retired** (3ac7aed, da38bbb): a bin or registry reached
#     by name lands on the calling rule's face; 5136e05's free-standing label is gone, the skip stays.
#   - **The duplicate-face refusal** (3deff25, 3f872c4, dupCensus 352527c): generateParse refuses a rule
#     with two faces carrying one tag, and a refused root stops parser(). It found **define** (labelled
#     endDef, 328afa8) and **Limit** (a stray re-add in GroupMain, f97227d); the complete census then
#     found only the three JSON rules (F-112). ⚠ The first census stripped comments and missed define --
#     an absence is evidence only when the population was the whole tree.
#   - **The road check** (b347078): parserTest PT-2 and doWhileNameT DW-9 assert the DO drive reaches
#     parseRule. Both were born red -- DO had silently run the OLD road since 3f872c4 -- and are green.
#   - **Terms return truth** (de29e38): a successful term returns trueResult; a label carrying a matched
#     0 had read as a failed `||` alternative (Token on `while 0`).
#   - **F-95 closed** (1f3b13a): `sukcess = truthOf(result)` at parseRule's seat; chainTruthT CT2-CT4
#     green; a rule no longer succeeds on its first term alone.
#   - **Conversation line** built and PARKED: the floor, driveStep, tell and the verdict (convDriveT
#     CD-1/CD-3/CD-5 green). **Resume at the fire verb**; CD-4 waits on it and the default handler.
#
#   ## OPEN
#   **F-111** tell into a generated root is refused (driveStep hands parseRule the registry's own
#   definition). **F-112** JSONfield/JSONarray/JSONblock have two GrouP faces -- wait on the bare-literal
#   respell campaign and on JSON leaving the parking lot. **F-113** a standalone Limit fails at `min`
#   straight after `[`, on both roads, and has never parsed.
#
#   ## CHECKLIST, measured at this tree (H14)
#   pop.sh 465 green / 2 parked · decodePop 14 green · ddPop 5 / 1 · countPop 47 of 47, foot reached ·
#   frontier dies at station 4 (fire) · canary 344 · groups.ext committed · Groups, support, TOK clean
#   and pushed · `bs` is Tony's to run.
#
#   ## TONY'S FIXIT INCANTATIONS WAITING: **0**
#   Generated by `genLadder/fixitNag.sh`, not typed.

# ⚠⚠⚠ SEALED 2026-09-22, EVENING -- PrinT(...) FIRES ON THE COMMAND LINE (on a branch), AND THE
# LABEL CHANNEL IS LOCATED: AN ALTERNATIVE OF A `||` RULE NEVER GETS ITS OWN parentLabel.
#
#   ⚠ DATE CHECK: `date` reads 2026-09-22 19:52 and `git log -1 --date=iso` 18:32 before this commit.
#
#   ## THE FULL STORY IS IN `IncantForms/WorkingOn/tester`, section *Current Status*. Read that first.
#   This seal is only the numbers and the pointers.
#
#   ## THE ONE-LINE STATE: **main line `jit-unified-emit-wip` -- fleet 446 green / 59 red / 2 parked,
#   row-for-row identical to the afternoon seal; canary 337; fixit queue 0; all three repos clean and
#   pushed; binary BARE and built at this tree.**
#
#   | what | where | state |
#   |---|---|---|
#   | a value may carry `+`/`*` (`one-='a'+`, `one-="ab"+`) | `ffa850f`, main line | **LANDED** |
#   | a deferred action fires when nothing above it defers | branch **`try-fire-root`** (`ce046dc`) | **NOT merged** -- fleet 442 |
#   | the label channel, new road | measured only | **Tony, with Clay's input** |
#
#   ## ⚠⚠ WHAT IS IN FRONT -- TONY'S, AND HE WANTS CLAY ON IT BEFORE parentLabel SETTING CHANGES
#   On the new road every **alternative of a `||` rule** (children of `Token`, `PrintXP`, `ANYorNum`)
#   mints with `parentLabel` **(none)**, and its own children attach to the alternation **above** it --
#   `ANYorNum` lands in `Token`, not `TokenXP`. A **bin** (`UnaryOPS`) fires a label that is never
#   minted or attached. One pattern, four symptoms: the dropped `++`, the 09-20 null `ANYorNum` in
#   `aCTionTokenXP`, `while dwN < 2` arriving as `xl1` with no method, and `trigDO`'s empty `DO`
#   label. The table is in tester. **Where to look:** where the new road sets a child's
#   `parentLabel` -- the generated call sites and `parseRule`'s `parentRepair` (`Generate.rtn:252`,
#   from `currentMETHOD.rStuff`). Tony's intent was *set it once and do not pooch it after*.
#
#   ## WHY try-fire-root IS NOT MERGED
#   The old road is right on it and several HEAD defects go away (`if 0` no longer runs its body; a
#   direct `DO` loops; `while 0;` no longer calls a null). **Every missing fleet row is
#   `doWhileNameT`**: DW-4 (new road) now LOOPS FOREVER, killed at 90s, because its truncated `xl1`
#   condition is truthy. That closes with the label channel, not before. Merge after it.
#   ⚠ `aCTionStatemenT` no longer executes anything on that branch -- statements fire in
#   `fireLabelMethod` (gate `deferredAbove`). That is the design change to review, not a side detail.
#
#   ## BANKED, NOT CHASED
#   **1.** A STRING repetition loses its last match when the next attempt fails at END OF INPUT
#   (`"ab"+` on `"ab"` returns true, mark unmoved) -- predates today; the name-side spelling does it too.
#   **2.** A top-level `do x = x + 1; while x < 3;` exits 139 on HEAD.
#   **3.** Limit on a string value is dropped -- Tony never uses Limit; recorded, leave it.
#   **4.** Everything in the afternoon seal's banked list below still stands.
#
#   ## CHECKLIST, measured at this tree (H14)
#   `pop.sh` 446 / 59 / 2 parked (diff vs the afternoon capture: empty) · decodePop 14/9 · ddPop 5/1 ·
#   countPop 47 of 47, foot reached · frontier dies at station 4 · canary 337 · groups.ext untouched ·
#   Groups, support, TOK clean and pushed.

# ⚠⚠⚠ SEALED 2026-09-22, AFTERNOON -- THE CHAIN NOW TELLS THE TRUTH. F-95's SOURCE HALF
# IS FIXED IN TWO LINES; ITS EXIT HALF IS OPEN AND IS A SMALL QUESTION NOW.
# THE LABEL CHANNEL IS THE ONLY THING IN FRONT, AND IT NO LONGER CRASHES.
#
#   ⚠ DATE CHECK: `date` reads 2026-09-22 13:32 and `git log -1 --date=iso` 13:29. They agree.
#
#   ## THE ONE-LINE STATE: **fleet 446 green / 59 red / 2 parked, canary 337, fixit queue 0,
#   all three repos clean and pushed, binary BARE.** Five strokes, four landings, and the
#   red column fell by five with every mover named.
#
#   ## ⚠⚠⚠ WHAT IS IN FRONT -- ONE THING, AND IT IS TONY'S XCODE WALK
#
#   **THE LABEL CHANNEL, AND THE WALK IS NOW A COMPLETING RUN RATHER THAN A SEGFAULT.**
#   `incant/pop/doWhileNameT` runs to its foot at **exit 0** with its sentinel printed and
#   every window closed. **The crash is gone and the defect is not.**
#
#   | what | reads |
#   |---|---|
#   | `DW-6` after the NEW-road drive | **`dwN == 1`, want 2** -- the body DOES NOT EXECUTE |
#   | the 09-20 site | `ANYtoken = xpress["ANYorNum"]` -- **live and NON-CRASHING** |
#   | producer / consumer | `ruleActions.rtn:988` / `GroupRules.mm:1265` (bear-trap #36) |
#
#   ⚠ **WHY IT STOPPED CRASHING, so nobody reads the green rows as the channel closing:**
#   SEQ 196 made a lawfully-absent optional return `trueResult` instead of a null, and **a
#   null optional inside `TokenXP` was what that seat was dereferencing.** The slot is now
#   a true. Nothing about the label channel changed. **`DW-6` is the row that answers
#   whether it has, and `DW-6` is still red.** The fixture's header is date-stamped to say
#   so and its crash frames are now HISTORY, not today's reading.
#
#   ## ⚠⚠ WHAT A FRESH READER MUST NOT RE-DERIVE
#
#   **a. F-95 WAS NEVER AN EXIT-SIDE DEFECT. IT WAS THE TERM'S RETURN, AND IT IS FIXED IN
#   TWO LINES.** Three attempts (SEQ 165, 169, and 2026-09-22) aimed at `parseRule`'s exit
#   and all three took CT1 -- a CORRECT parse -- red. The reason, located by `lldb` at the
#   `&&` seat: **the chain was being handed a NULL by a term that had succeeded.**
#       - **SEQ 195, `parseLoop`:** a repetition ends by FAILING -- that is what ends it --
#         so the last attempt always leaves `sukcess` at 0 and the loop was reporting THAT
#         as its verdict. `GrouP+` read **kount=1 min=1 max=100 sukcess=0** and returned 0.
#         Fix: `if kount >= min return trueResult;`. **`SemI` dispatches for the first time.**
#       - **SEQ 196, `exitFromParse`'s failure tail:** a term whose **minimum is ZERO** is
#         SATISFIED by not matching, so it owes the chain a success. Fix:
#         `if max <= 1 && !min && !field.isCondition return trueResult;`.
#   ⚠ **BOTH READ A FACT AND NEITHER WRITES `sukcess`** -- that flag already carries two
#   meanings (*did THIS attempt match* / *did the TERM succeed*) and neither line joins it.
#
#   **b. THE RESULT CHANNEL DISCRIMINATES NOW, WHICH IT NEVER DID BEFORE.** Before SEQ 195
#   all four `chainTruthT` drives returned **one node**, `tag=false truthOf=0`, the correct
#   drive included -- so nothing at the exit could ever have told them apart, and that is
#   why the first three attempts could not have worked. Today:
#       CT-ROW1 "search list;"  tag=true  truthOf=1    SemI dispatches
#       CT-ROW2 "search list"   tag=false truthOf=0    SemI dispatches
#       CT-ROW3 "search ;"      tag=false truthOf=0    correctly does not
#       CT-ROW4 "search"        tag=false truthOf=0    correctly does not
#
#   **c. ⚠⚠ F-95's EXIT HALF IS OPEN, AND THE SPELLING IS AN *ASSIGN*, NEVER A TEST.**
#   SEQ 197 built `if truthOf(result) sukcess = true;` bare and **it is INERT** -- fleet
#   identical row for row -- and **reverted it**. The seat read says why:
#   **`sukcess` IS ALREADY 1 ON ARRIVAL**, failing drives included, because `parseRule`
#   writes `sukcess = 0` and then calls `checkInput()`, **which sets it**. A set-only test
#   cannot move anything. ⚠ **F-95's own log had recorded exactly this, dated, one screen
#   away, and it was not checked before building** -- the unmeasured-citation family
#   arriving through this project's own register.
#   ⚠ **THE REMAINING QUESTION IS NOW SMALL, AND ITS BLAST RADIUS IS MEASURED.** The assign
#   `sukcess = truthOf(result);` broke `parserTest` to 2 of 4 at SEQ 191 -- **but that was
#   measured before the two fixes above, when every chain returned false and the assign
#   therefore cleared nearly everything.** Re-read at the seat this stroke, WITHOUT
#   building it: on `parserTest`, **16 arrivals, 15 with truthOf=1 across 13 rules, and
#   exactly ONE with truthOf=0 -- a rule tagged `Token`.** So the assign would clear one
#   rule, not the wholesale clear of 09-20. **That is a blast-radius reading and NOT a
#   prediction that it is safe:** whether clearing `Token` is right is unmeasured, and the
#   `reportNoBody` arm was not swept. **Measure that one rule, then build the assign.**
#   CT2/3/4 close there and nowhere else.
#
#   **d. THE MODIFIER SEAM IS CLOSED AND IT WAS A SPELLING FAULT, NOT A DEFECT.** Tony's
#   ruling, SEQ 193, out of his Xcode walk. A bare `"a"-` in an `isRule` rule **steals
#   `GrouP` as its tag** and the tag is promoted to a rule, which is where
#   `return GrouP() && GrouP();` came from -- two different literals emitting one call,
#   neither carrying its value. And **the modifier belongs on the LABEL**: `one="a"-`
#   refuses, `one-="a"` and `two?-="b"` do not. **There is no `generateParse`
#   modifier-drop defect.** `incant/pop/modSeamT` now asserts the `?` behaviourally with a
#   PAIR of drives on both roads, because the modifier is nowhere in the emitted text.
#
#   ## STATE OF THE CHECKLIST
#   `pop.sh` **446 green / 59 red / 2 parked** · decodePop 14 green / 9 red · ddPop 5 green /
#   1 red · countPop 47 of 47, foot reached · formsPop **14 PASSED** · **frontier dies at
#   station 4** · canary **337** · groups.ext untouched and clean · **Groups 0/0, support
#   0/0, TOK 0/0** · binary BARE (directives detector 3/3, the genuine source hits). Every
#   number measured this stroke (H14).
#
#   ⚠ **THE RED ARITHMETIC CLOSES AND EVERY MOVER IS NAMED.** 64 at the 09-22 midday seal.
#   **-1** `modSeamT` MS-3 (retired as a SUBJECT CHANGE, SEQ 193 -- its bare-literal root is
#   gone from the fixture, not a row that started passing). **-1** `searchNewParseT` SemI
#   (SEQ 195). **-3** `doWhileNameT` runs / sentinel / DW-8 (SEQ 196). **= 59.** Nothing
#   else moved, row for row, across four landings, each diffed against a capture banked
#   before its first edit.
#
#   ## ⚠ BANKED, NOT CHASED -- listed so nothing is lost across the pause
#   **1. F-100 IS GRADEABLE FOR THE FIRST TIME AND IS UN-GRADED.** `DW-5` survives now and
#   reads **0 refusals** where the row was opened on 100. ⚠ **Zero is AMBIGUOUS**: it can
#   mean the over-repeat was fixed, or that the refusing seat is no longer reached because a
#   satisfied-by-min term returns before it. **Nothing measured separates them.**
#   **2. THE BARE-LITERAL-IN-`isRule` REFUSAL + GRAMMAR RESPELL CAMPAIGN** -- ruled;
#   ordering is Tony's.
#   **3. THE EXIT-SIDE TWO-WRITERS NOTE beside `parseRule`** -- `checkInput`'s
#   `enclosingActivation` arm and `attachLabel`'s promote arm are two writers of the
#   parent's label slot; the `alreadyIsParentLabel` guard exists only because they can reach
#   the same node. One-channel-one-meaning, for whenever the exit is reworked.
#   **4. F-103 / F-104, THE TWO LABELLED 139s**, and they are DIFFERENT SITES:
#   F-103 `repT isRule "a"+ ;` -> `getText()` on a null `this`, `GroupItem.mm:1322`,
#   measured pre-existing at `b5e1557`; F-104 a labelled chain that matches part-way then
#   fails a MANDATORY term -> `GroupItem::parse` with `pStuff=0`, `GroupItem.mm:1704`.
#   F-104 is the H7 negative control for `modSeamT`'s `?` rows, which is why those rows
#   carry no in-fleet control -- installing it would take the suite down (H5).
#
#   ## ⚠ WAITING ON TONY
#   **1. `bs` IS HIS TO RUN.** Not run this session.
#   **2. THE LABEL CHANNEL XCODE WALK** -- the one thing in front; see the top of this seal.
#   **3. `checkSKIP` NEEDS A WAY TO TURN `checkSkip` OFF** before it can be tested.
#   **4. F-102**, the flag/list disagreement on the `DatA` label under `ShortcuT`.
#
#   ## TONY'S FIXIT INCANTATIONS WAITING: **0**
#   Generated by `genLadder/fixitNag.sh`, not typed. An empty queue is a READING, not an absence.
#
# ⚠⚠⚠ SEALED 2026-09-22, MIDDAY -- THE LABEL CHANNEL IS FIXED AND THE MISSING HALF WAS
# THE RETAG. THE MODIFIER SEAM NOW HAS A SPECIMEN, AND ITS BODY EMITS `GrouP()`.
#
#   ⚠ DATE CHECK: `date` reads 2026-09-22 10:52 and `git log -1 --date=iso` 10:48. They agree.
#
#   ## THE ONE-LINE STATE: **fleet 433 green / 64 red / 2 parked, canary 337, fixit queue 0,
#   all three repos clean and pushed, binary BARE.** Two landings, four commits, and the red
#   column moved by **exactly one row, born red by design**.
#
#   ## ⚠⚠ WHAT A FRESH READER MUST NOT RE-DERIVE
#
#   **a. THE LABEL CHANNEL IS CLOSED. `exitFromParse` CALLS `attachLabel` AT promote=1.** It
#   hand-rolled its own `addAttribute` until 2026-09-22; now there is ONE attach on both roads
#   (`Generate.rtn:21`), plus an identity guard in `attachLabel` (`GroupItem.twk:263`).
#   ⚠ **THE MISSING HALF WAS NEVER THE ATTACH -- IT WAS THE RETAG.** `attachLabel`'s promote
#   arm is TWO statements, `pStuff.label = lab` **and** `lab.tag = pStuff.ruleName`, and the
#   second is what makes an alternation's winning option arrive under the ENCLOSING rule's name.
#   A hand-rolled `+%` cannot do it. Measured: at promote=0 the trace reads
#   `attachLabel lab=ANYtoken ... pRule=TokenXP`, so TokenXP's label carried a member named
#   **ANYtoken** and `xpress["ANYorNum"]` found nothing; at promote=1 the same line reads
#   `lab=ANYorNum`, and `PrintField` promotes into `PrintXP`.
#
#   **b. promote=0 WAS TRIED FIRST AND IS INERT HERE. DO NOT RE-TRY IT.** The promote arm reads
#   `(promote || !pStuff.label) && stuff.isTarget`, so at promote=0 it needs an EMPTY parent
#   slot -- and `checkInput`'s `enclosingActivation` arm (`RuleStuff.twk:208`) has **already
#   filled that slot by hand, unretagged**, for any `hasNewParse` member. The disjunct is false
#   in exactly the cell where the retag is owed.
#   ⚠ **RULED 2026-09-22 (Tony, SEQ 192): THE RETAG STAYS, promote=1 IS THE LANDED SHAPE, AND
#   THE 08-07 IT NOTE IS AMENDED BY NAME** -- it read *"the generated arm passes promote=0,
#   attach-under always"*. PC-1 is not repealed; what is withdrawn is promote=0 as this road's
#   value. Recorded in `incant/designDocs` -> `Generate.exitFromParse.oneAttach`.
#
#   **c. BANKED, NOT CHASED (same ruling), AND IT SITS BESIDE F-95.** `checkInput`'s
#   `enclosingActivation` arm and `attachLabel`'s promote arm are **two writers of the parent's
#   label slot**; the `alreadyIsParentLabel` guard exists only because they can reach the same
#   node. One-channel-one-meaning question, for whenever the exit is reworked.
#
#   **d. F-95 WAS RE-MEASURED AND THE SPELLING IS NARROWED. `sukcess` IS SET-ONLY, AND THAT IS
#   THE DEFECT -- NOT THE PRESENCE TEST.** `parseRule` writes `sukcess = 0`, then calls
#   `checkInput()`, **which sets it true**, and the result test only ever SETS. So
#   `if truthOf(result) sukcess = true;` -- built, bare, driven -- **buys NOTHING**, fleet
#   identical row for row. Only the ASSIGN moves anything, and `sukcess = truthOf(result);`
#   takes `chainTruthT` CT2/CT3/CT4 **green** and **CT1 red** plus `parserTest` to 2 of 4 roots,
#   because it also clears the `reportNoBody` arm and every non-action rule. **Reverted whole.**
#   A NARROWED clear -- one that fires only where a body actually ran and answered -- has NOT
#   been tried and is the next thing. Three attempts now on F-95's log; do not make it four
#   with the blanket assign.
#
#   **e. ⚠⚠ THE SEQ 192 SPECIMEN, AND THE EXPECTATION IN THE DISPATCH WAS WRONG.** The bodies:
#
#       optT isRule "a"- "b"?- ;    ->   optT = CodE { return GrouP() && GrouP(); }
#       repT isRule "a"+ ;         ->   repT = CodE { return GrouP(); }
#
#   The modifiers are gone as expected. **The term is not `lit("a")` -- it is `GrouP()`**, the
#   tag of the rule that parsed the quote, so optT's two DIFFERENT literals emit the SAME call
#   and neither carries its own text. `generateParse` emits `print $taG "()"` per non-noPrint
#   member and consults neither data nor modifier. **The literal VALUE is absent from the body.**
#
#   **f. THE CURSOR IS THE INSTRUMENT AND IT WORKS ON BOTH ROADS.** `MARKARM drive base=` is the
#   zero point, `MARKPT 2b-before-pop` is the last instant the drive's own cursor exists, and
#   **consumed is `mark - base`, never an address** (H3: addresses move under ASLR). The `in=`
#   field says DRIVE-STRING or not-in-drive. Verdict is `CAPFIRE fireLabelMethod <rule>`, which
#   prints on both roads and ONLY on success, so no action body is needed for it -- and
#   **a body must NOT be added**, because it is parsed INSIDE the drive on first fire and walks
#   the mark out of the drive string, destroying the reading.
#
#   **g. BOTH ROADS SAY WIN; ONLY THE CURSOR SEPARATES THEM.**
#       `optT("a")`   OLD  WIN, mark `in=not-in-drive` -- left the 1-char drive entirely
#       `optT("a")`   NEW  WIN, mark `in=DRIVE-STRING`, **CONSUMED 0**
#   That is why `modSeamT` MS-1 and MS-3 are an anti-vacuity PAIR. A fixture reading the verdict
#   alone would be green on both and measuring nothing.
#
#   **h. `repT isRule "a"+ ;` EXITS 139 ON BOTH ROADS, AND IT IS PRE-EXISTING.**
#   `GroupItem::getText()` on a null `this`, `GroupItem.mm:1322`, through
#   `ACTFIRE fireLabelMethod GrouP`. **Built at `b5e1557`** -- the seal before the attachLabel
#   conversion -- **and it exits 139 there too, with optT's four cells reading identically.**
#   The control was run because SEQ 191's identity guard sits immediately above `attachLabel`'s
#   labelled-repetition branch, which is this exact shape. `"a"+-` (noLabel) does NOT crash; the
#   LABELLED repetition does.
#   ⚠ **AND THE OLD-ROAD DRIVE MUST COME FIRST OR IT IS NOT THE OLD ROAD** -- `parser()` is a
#   one-way door -- so repT's body and its new-road cursor reading CANNOT live in `modSeamT`
#   beside its old-road drive. They live in `tester`.
#
#   **i. NEITHER BODY IS ASSERTED IN `modSeamT`, AND THE REASON IS TRUNCATION.** `generateParse`
#   prints to cout, which is block buffered and flushed at exit; MS-5 crashes before that flush,
#   so **no body reaches that capture at all** -- optT's included, though optT was generated long
#   before the crash. A row greping for it could only ever fail. **Do not add one until MS-5
#   stops crashing.**
#
#   **j. `tester` IS TRACKED AGAIN (Tony, 2026-09-22), REVERSING SEQ 105 R4.** The `.gitignore`
#   entry is REMOVED, not commented -- an ignore line and a rule that the file commits cannot
#   both be true. `CLAUDE.md`'s two paragraphs went in the same commit. **`incant++` is now the
#   ONLY scratch file.** Clod writes in `tester` under Clay's SEQ 192 authorization, and the
#   narrow reading is recorded: **Tony marks the lines he is done with** -- the 09-22 file
#   carried `// Clod you can replace the following two lines as needed` -- **and that marker is
#   the invitation, not a general licence over the file.**
#
#   ## STATE OF THE CHECKLIST
#   `pop.sh` **433 green / 64 red / 2 parked** · decodePop 14 green / 9 red · ddPop 5 green /
#   1 red · countPop 47 of 47, foot reached · formsPop **14 PASSED** · **frontier dies at
#   station 4** · canary **337** · groups.ext untouched and clean · **Groups 0/0, support 0/0,
#   TOK 0/0** · binary BARE (directives detector 0). Every number measured this stroke (H14).
#
#   ⚠ **THE RED ARITHMETIC CLOSES EXACTLY AND `docs/redList.md` CARRIES THE LIST:** 63 at the
#   09-21 seal **plus `modSeamT MS-3`** (born red by design) = **64**. Nothing else moved, row
#   for row, across BOTH landings -- each diffed against a capture banked before its first edit.
#
#   ⚠ **THE FRONTIER WAS RUN AND NOT REVISED, DELIBERATELY.** It still dies at **station 4**
#   (*"the action RAN WITHOUT ITS TERMS"*, CT-5) and the edge did not move: the label channel
#   landing is upstream of it and the specimen is a measurement rather than a station. Adding
#   stations below a failing one would be ceremony -- they cannot be reached.
#
#   ## ⚠⚠ WHAT IS IN FRONT
#   **1. THE MODIFIER SEAM, AND TONY WALKS IT.** Two things the Xcode walk settles so Clod does
#   not: **does the emitted call reach the TERM (with its rStuff min/max) or the DEFINER by
#   name**, and **where the modifier would have to be read**. The specimen is in two homes --
#   `IncantForms/WorkingOn/tester` and `incant/pop/modSeamT`, one grammar.
#   **2. F-95's NARROWED CLEAR**, which waits on that walk: the specimen says what a false chain
#   MEANS at the exit before anyone changes what the exit DOES with it.
#   **3. THE repT 139**, unattributed beyond "pre-existing and not the conversion".
#
#   ## ⚠ WAITING ON TONY
#   **1. `bs` IS HIS TO RUN.** He ran it at the head of this session; not run since.
#   **2. `checkSKIP` NEEDS A WAY TO TURN `checkSkip` OFF** before it can be tested -- a toggle
#   command. His docket, deferred, no fixit row, banked from his own offline note.
#   **3. F-102**, the flag/list disagreement on the `DatA` label under `ShortcuT`, still
#   unexplained and carried forward from the 09-21 seal.
#
#   ## TONY'S FIXIT INCANTATIONS WAITING: **0**
#   Generated by `genLadder/fixitNag.sh`, not typed. An empty queue is a READING, not an absence.
#
# ⚠⚠⚠ SEALED 2026-09-21, MIDDAY -- THE HOLDER CONVERSION AND F-98 ARE MERGED TO TRUNK.
# THE DRIVES NOW REACH TokenXP, AND THE LABEL CHANNEL IS WHAT IS IN FRONT.
#
#   ⚠ DATE CHECK: `date` reads 2026-09-21 12:44 and `git log -1 --date=iso` 12:42. They agree.
#
#   ## THE ONE-LINE STATE: **fleet 429 green / 63 red / 2 parked, canary 337, fixit queue 0,
#   all three repos clean and pushed, binary BARE.** Two merges landed on
#   `jit-unified-emit-wip`. Only TWO reds are not on the 09-20 list, both born red by design.
#
#   ## ⚠⚠ WHAT A FRESH READER MUST NOT RE-DERIVE
#
#   **a. THE HOLDER CONVERSION, AND ITS ONE SITE.** A field whose group carries a list -- a
#   HOLDER, e.g. `stuff=PrintXP+` -- now takes that rule as an **ATTRIBUTE** instead of in its
#   group slot. `GroupItem.embedAttribute` does it; the ONE call site is **aCTionDefinE's loop,
#   `ruleActions.rtn:348`**, widened to convert `NewGroup` ITSELF as well as its attributes,
#   because `Attributes=TraiT+` and `Looper=ANYtoken` are rule-level holders that the
#   attribute walk cannot reach.
#   ⚠ **ONE COPY, AND THE DUPLICATE WAS A TRAP:** `addGroup` does `if group.parent group =
#   new(group)`, so setting `copy.parent` before `addAttribute` minted a SECOND copy and left
#   the first orphaned at affiliation 3. The parent is NOT set and the RETURN is taken --
#   `item = strap +% grok/RunRulE` in GroupMain is the model, and `InitiatE` is the exemplar.
#
#   **b. GroupMain :366 (`Attributes`) AND :407 (`define.definitions`) ARE BORN CONVERTED, AND
#   THE REASON IS NOT TIDINESS.** `definitions` is converted **from inside its own live
#   `parse()` activation** -- measured, frame #4 is `parse(this="definitions")` while frame #0
#   converts it -- and the grammar road then stops matching part-way through the file that
#   redefines it. Born-converted in the bootstrapper, the problem does not exist.
#   ⚠ **DO NOT CALL THE CONVERSION AT GroupMain's `embedRule` SITES.** All five read the copy
#   BACK through the group slot (`item = item.group`) to land their modifier; clearing the slot
#   there loses the `+`.
#
#   **c. THE noPrint SKIP.** `compile()`'s `this` carries `group = field` and is an ARTIFACT,
#   not a term. The conversion skips any noPrint field and routes it to `embedRule`, which is
#   exactly what trunk does with it. Without the skip, `this` gets a copy of the whole rule.
#
#   **d. F-98 IS CLOSED, AND THE RULING IS: parseMethod IS A FACT ABOUT THE RULE'S SHAPE.** It
#   is installed on and read from `definingRule()`. `parse()`'s fork already did this
#   (`GroupItem.twk:1281-82`); `setParseWalk` wrote the FACE and `parseLoop` fired the FACE, and
#   that gap was the crash. `installParseMethod` parks it on the definer, `runLeafParse` fires
#   through the definer, and a missing method is a **NAMED REFUSAL, never a call and never a
#   bare guard** -- a bare guard trades the crash for a silent wrong answer.
#   ⚠ **MIN AND MAX STAY PER FACE.** Only the METHOD moved.
#
#   **e. THE FIELD-SIDE REAL-TERMS TEST, AND WHY THE CONVERSION PREDICATE WAS NOT CHANGED.**
#   `setParseWalk`'s shape arm and `generateParse`'s data-and-a-list check both ask
#   `hasTraits || hasMembers` -- a field whose only entries are noPrint artifacts is a DATA
#   rule. ⚠ **`hasTraitS` ALONE IS WRONG**: `PrintXP` and `ScopeField` are ALTERNATIONS, so
#   `hasTraitS=0` and `hasMemberS=1`, and a hasTraits-only test breaks all four `stuff` holders.
#   ⚠⚠ **`embedAttribute`'s PREDICATE STILL ASKS THE GROUP'S REAL `groupList`, AND MUST.**
#   Changing it admitted three fields it should not have -- `ANYstring`, `ShortcuT`,
#   `FormaT.flags` -- because their group `DatA` reads `groupLen = -1` (NO list at all) while
#   its body carries the flags SET. **The flag and the list disagree on one node. That is F-102
#   and it is unexplained.**
#
#   **f. THE doWhileNameT GREEN WAS HOLLOW, AND THREE VALUE ROWS REPLACED IT.** Four rows said
#   each drive RETURNED, and a drive that parses nothing returns fastest of all: `dwN` read 1
#   before the drive and 1 after, a traceParse window dispatched 20 rules with TokenXP not among
#   them, and PARSERESULT read `rule=DO ... truthOf=0`. **DW-6** pins `dwN == 2` (the pre-drive
#   value is 1, so 2 is the one reading a do-nothing drive cannot produce); **DW-7/DW-8** count
#   `REFUSED parseRule:` in their window, compared to 0, **and each requires its window's own
#   RETURNED marker so an EMPTY window cannot pass**. That last clause was added after an empty
#   window counted zero and went green.
#
#   **g. ⚠⚠ oneTest AND jsonTest WERE MIS-ATTRIBUTED FOUR TIMES. DO NOT START AGAIN.** Their
#   extra lines -- three `AUDIT TERM list/JSONarray/JSONfield` and two `nextGroup: ERROR
#   JSONlist does not contain a list` -- are **PRE-EXISTING ON TRUNK**. Measured: sources at
#   `9475ae0`, no conversion code in the tree, both fixtures produce the IDENTICAL diffs. They
#   were called movers, then blamed on `this`, then bisected to GroupMain's two sites; every
#   intermediate control said "still differs", which was read as "not the cause" when it meant
#   **"the diff was never yours"**. The control that ends it -- rebuild at the pre-change commit
#   -- was on disk from the first hour. **F-99 carries it so nobody repeats it.**
#
#   **h. jsonTest baseline is PARKED** by Tony's ruling, out of the line of fire until fonts.
#   `parkdiff`, not skipped: it still runs and goes loud with WOKE if it starts passing.
#
#   ## STATE OF THE CHECKLIST
#   `pop.sh` **429 green / 63 red / 2 parked** · decodePop 14 green / 9 red · ddPop 5 green /
#   1 red · countPop 47 of 47, foot reached · formsPop **14 PASSED** · **frontier dies at
#   station 4** · canary **337** · alphaLint 11 (10 pre-existing + `installParseMethod` after
#   `runLeafParse`, report tier) · groups.ext committed and clean · **Groups 0/0, support 0/0,
#   TOK 0/0** · binary BARE. Every number measured this stroke, none carried (H14).
#
#   ⚠ **THE RED ARITHMETIC CLOSES EXACTLY AND docs/redList.md CARRIES THE LIST:**
#   62 at the 09-20 shutdown, **minus `jsonTest baseline`** (parked, not fixed), **plus
#   `doWhileNameT DW-6` and `DW-8`** (born red by design, now reading real values instead of
#   truncation artifacts) = **63**. Nothing else moved.
#
#   ## ⚠⚠ WHAT IS IN FRONT: THE LABEL CHANNEL, REACHED FROM THE FLEET
#   `incant/pop/doWhileNameT` exits 139 at **the 09-20 site**, and it gets there now because the
#   `ShortcuT` misclassification that was stopping it short is gone:
#
#       frame #0  aCTionTokenXP    GroupRules.mm:1265
#       frame #1  fireLabelMethod  GroupItem.mm:953
#       frame #2  exitFromParse    GroupRules.mm:2784
#       frame #3  parseRule        GroupRules.mm:10139
#       frame #4  runRule :12059   #5 runOP :11998   #6/#7 runShortCircuit :12184/:12204
#
#   Per bear-trap #36 the dying line is not the reading line: the PRODUCER is
#   `GroupRules.mm:1249` / `ruleActions.rtn:987`, `GroupItem ANYtoken = xpress["ANYorNum"]`.
#   `xpress` is NOT null; its `ANYorNum` member is absent. **`parserTest` is at 4 ROOTS and the
#   bare load is clean underneath it**, which is new -- the channel is now the only thing there.
#
#   ## THREE BRANCHES KEPT AS RECORDS, ALL PUSHED AND UNMERGED
#   **`group-descent`** (`7e24fbe`) -- the list-predicate no-buy. ⚠ **TONY'S `compile`
#   parentStuff STAMP IS PARKED HERE** along with his `setParseWalk isGROUP -> parseRule`; the
#   bisect measured that the stamp alone fixes nothing and `setParseWalk` alone was the fixer.
#   **`holder-attribute`** (`caf4e8f`) -- its `dfd73ee` is merged; the tip is the SEQ 188 try
#   that moved six re-pinned rows and was never signed. F-101 was re-banked on trunk's line so
#   it is not stranded there.
#   **`checkinput-state`** -- unchanged, nothing from it has landed.
#
#   ## ⚠ WAITING ON TONY
#   **1. `bs` IS HIS TO RUN** -- one line: **`! ~/bin/bs`**. Not run this session.
#   **2. F-102**, the flag/list disagreement on the `DatA` label under `ShortcuT`, is the thing
#   under the conversion predicate and is unexplained.
#   **3. `testAction` (`RuleStuff.twk:382-83`) still reads the FACE's parseMethod.** It cannot
#   call a null so it is not F-98; its divergence carries Tony's own 2026-09-15 ruling and was
#   reported rather than changed.
#
# ⚠⚠⚠ SEALED 2026-09-20, SHUTDOWN -- THE LABEL CHANNEL GOES OFFLINE TO TONY. THREE ATTEMPTS
# BROKE WHAT ALREADY WORKED, ALL THREE ARE REVERTED, AND THERE IS NO ATTEMPT 4.
#
#   ⚠⚠ FIRST, AND IT GOVERNS THE WHOLE NEXT SESSION: **LEAVE THE PARSE ROAD ALONE UNTIL TONY'S
#   STATUS NOTE.** He is walking `parseRule` / `exitFromParse` / `checkInput` in Xcode offline.
#   Clay, SEQ 173. **No attempt 4**, no "just one more spelling", no probe that binds a label.
#
#   ⚠ AND THREE THINGS IN THE TREE ARE TONY'S AND STAY, so nobody reverts them as dirt:
#   **`compileRules` runs compile THEN setParse** · **`DEBUG debug-` and `DEF def-="define"`**
#   in `incant/grammar` · and **`bs` IS TONY'S TO RUN** -- it was not run this session.
#
#   ⚠ DATE CHECK: `date` reads 2026-09-20 17:34 and `git log -1 --date=iso` 17:26. They agree.
#
#   ## THE ONE-LINE STATE: **fleet 428 green / 62 red, canary 335, fixit queue 0, all three
#   repos clean and pushed, binary BARE.** Two of the 62 reds are new and are **red by design**
#   -- `doWhileNameT`, born red this session. Branch `checkinput-state` still pushed and
#   UNMERGED; nothing from it landed.
#
#   ## ⚠⚠ WHAT A FRESH READER MUST NOT RE-DERIVE
#
#   **a. THE BINARY WAS A DIRECTIVES BUILD AT WAKEUP AND THE TREE WAS NOT.** The 15:51 binary
#   carried `succeeded with count` and `Match container`; every `.mm` was bare. Rebuilt bare
#   before any number was taken. **The detector is `strings ~/bin/incant | grep -c "succeeded
#   with count"`** -- a `.mm` that moved with no `.twk` behind it is the other tell, and here
#   even that was absent because Tony had reverted the sources and kept the binary.
#
#   **b. COMPILE-FIRST GIVES ZERO REFUSALS BECAUSE `compileRules` DOES NOT LOOP AT ALL.** It
#   calls two externs and **each does its own whole-tree recursion** -- `compile()` at
#   `Commands.rtn:86-91`, `setParseWalk()` at `Generate.rtn:391`. So the ordering is TOTAL, not
#   interleaved: every body is parsed before any node carries `hasNewParse`, and `checkInput`'s
#   refusal arm is never entered. **"All but the first rule" needs a per-rule loop, and there
#   isn't one.** Measured both ways, order restored byte-identical:
#   compile-then-setParse **0 refusals / 39 compiles / 118 generating**; setParse-then-compile
#   **39 / 39 / 118**. ⚠ **39 refusals = 39 compiles** -- one per body `processCode` parses.
#   The incant comment *"setParse and compile loop recursively thru components"* is what invites
#   the wrong reading; the looping is inside the externs.
#
#   **c. THE CRASH, WITH FRAMES, AND THE LINE THAT DIED IS NOT THE LINE THAT READ NULL.**
#   `parser(DO); DO("do print ++dwN; while dwN < 2;")` -> EXC_BAD_ACCESS, exit 139, rule
#   **TokenXP**. Crash at `GroupRules.mm:1265`. **PRODUCER at `GroupRules.mm:1249` /
#   `ruleActions.rtn:987`** -- `GroupItem ANYtoken = xpress["ANYorNum"]`. **`xpress` is NOT
#   null**; its `ANYorNum` member is absent. Bear-trap #36.
#   The channel: `exitFromParse` attaches with `parentLabel->addAttribute(label)`, `parentLabel`
#   syncs from `parentStuff->label`, and nothing binds it.
#
#   **d. `result` WAS NEVER THE VARIABLE, AND THE LADDER SAYS WHAT IS.** A counter DECLARED in
#   the fixture dies identically. One run each, same generated parse, drive string the only
#   change: `while 0;` and `while 1 < 0;` PASS; `while result < 2;`, `while result;`,
#   `while !result;`, `while !1;` all die. ⚠ **`do print ++result; while 0;` PASSES** -- the
#   bump and the name are fine in the statement BODY; only the while EXPRESSION kills it.
#   ⚠⚠ **`while !1;` IS A COUNTEREXAMPLE TO THE TIDY STORY.** "An ABSENT optional unary
#   short-circuits the chain, so ANYorNum is never asked" cannot be the whole cause: `!1` has a
#   PRESENT unary on a literal and dies the same way. No positive cause is claimed.
#
#   **e. THE THREE ATTEMPTS, AND ATTEMPT 2 IS THE ONE THAT BOUGHT SOMETHING.**
#   1. (a)+(b) ported from `checkinput-state` minus the carrier fire. **H15 control first, and
#      it fired at once**: `parserTest` 4 roots -> 2, and the fixture's own literal-while
#      control stopped returning.
#   2. **(a) ALONE** -- identical breakage, so **(a) is the breaker and (b) is not.** One
#      variable at a time is what produced the attribution attempt 1 could not.
#   3. The bind **BRACKETED** round the body (= Clay's (c) recursion save, tightened from the
#      call to the body) so `exitFromParse` sees what it saw before. Still breaks the control,
#      and **the crash MOVES** to `interpretXP` at `GroupRules.mm:3759`, `groupList` null. So
#      the bind is NOT inert -- it really does reshape the tree.
#   **Reverted whole; red column identical row for row.** F-96 carries all three with the
#   attempt log, appended in the same commit as the attempts.
#
#   **f. ⚠ THE READING THAT SURVIVES ALL THREE, and it is the sentence to hand Tony.**
#   `checkInput`'s `label = 0` for a members-rule **is not an oversight to override**. Every
#   spelling that overrides it -- in place or under a bracket -- breaks rules that already
#   worked. Either the terms need a channel `exitFromParse` does not already read, or
#   `exitFromParse` has to learn the difference.
#
#   **g. THE ORACLE IS ONE PASS, NOT A LOOP.** Old road, no `parser()`: exit 0, prints `1`, and
#   **it prints `1` for every condition tried -- under 2, under 4, and under a constant true.**
#   Whether that is do-while not iterating or a rule-drive not executing a loop is **NOT
#   MEASURED** and nothing claims either. Clay banked it: it wants a plain-statement control
#   and its own row.
#
#   **h. TWO SPELLING FACTS FOR TONY, measured on the way past.** `result = 0;` at file level
#   **does not take**, while `define dwN=0;` in the define block **does** share its node with
#   the drive string (`dwN` reads 0 before the drive and 1 after). And **that counter must be
#   read BARE**: a `:=` capture of it prints its own tag both before and after, so a capture
#   would have pinned nothing.
#
#   ## STATE OF THE CHECKLIST
#   `pop.sh` **428 green / 62 red** · decodePop **14 green / 9 red** · ddPop 5 green / 1 red ·
#   countPop **0 of 45** · formsPop **14 PASSED** · **frontier dies at station 4** (unrevised --
#   nothing landed, so the edge has not moved) · canary **335** · alphaLint 10 (pre-existing) ·
#   groups.ext untouched · **Groups 0/0, support 0/0, TOK 0/0** · binary BARE. Every number
#   measured this stroke, none carried (H14).
#
#   ⚠ **THE FLEET ARITHMETIC, so nobody reads the move as a regression:** 426 green at the 13:31
#   seal + 2 new green control rows = **428**; 60 red + 2 new red-by-design = **62**.
#
#   ## ⚠⚠ AN INSTRUMENT FINDING, FOUND AT THE SEAL AND WORTH MORE THAN THE NUMBERS
#   **`genLadder/decodePop.sh` AND `formsPop.sh` ARE NOT EXECUTABLE** while `pop.sh` and
#   `ddPop.sh` are -- so `./genLadder/decodePop.sh` is *permission denied*. **And the wrapper
#   swallowed it: `perl -e 'alarm N; exec @ARGV'` returns EXIT 0 WHEN THE EXEC ITSELF FAILS**,
#   so both instruments read as a clean pass with an **empty output file**. Run them as
#   `bash ./genLadder/<name>.sh`. ⚠ **An empty capture at exit 0 is not a green** -- check that
#   an instrument printed something before believing its status. The mode bits are left as
#   found rather than chmod'd, because they may be deliberate; Tony's call.
#
#   ## ⚠⚠ WAITING ON TONY
#   **1. THE LABEL CHANNEL, OFFLINE.** `parseRule` / `exitFromParse` / `checkInput` in Xcode.
#   Nothing on the parse road moves until his status note. **No attempt 4.**
#   **2. `bs` WAS NOT RUN** -- it is his to run, one line: **`! ~/bin/bs`**.
#   **3. `checkinput-state` is pushed and unmerged.** Unchanged; nothing from it landed.
#   **4. `doWhileNameT`'s two reds are BY DESIGN.** Do not "fix" them by re-pinning; they go
#   green when the channel lands. The two green rows beside them are their controls.
#   **5. The `decodePop`/`formsPop` mode bits** -- deliberate, or a chmod owed?
#
#   ## ⚠ BANKED, NOT CHASED
#   The old-road `do` body running once for every condition, including a constant true (Clay
#   banked it; wants a plain-statement control and its own row). · `generateParse` prints
#   *"rules should not have data and a list"* for `BrancheS`; a bin's set data is derived, so it
#   wants the `binTypE == 0` exemption -- row or ride. · Tony's landed leaf guard omits F-93's
#   `printTO(0)`; whether that can strand the buffer is **not measured** and nothing was lost in
#   any run this session. · Emitted bodies still carry no modifiers -- `TokenXP` emits
#   `UnaryOPS() && ANYorNum() && InvokeArg()` against `UnaryOPS? ANYorNum^ InvokeArg?`, which is
#   F-89's seam and is what the ladder keeps walking into.
#
#   ## TOMORROW, IN ORDER
#   1. **Tony's status note from the Xcode walk.** Everything else waits on it.
#   2. The TREE row (SEQ 172 amendment 2) -- dump `xpress` on both roads for `dwN < 2`, `!1`,
#      `dwN` and diff. **It starts "once the label binds", so it is not owed until then.**
#   3. Step 3 re-cut (amendment 3): read DISPATCH, not exit status -- is `ANYorNum` asked with
#      the unary absent versus present? Also waits on `xpress` surviving.
#   4. Station 4 -- the action still runs without its terms, CT-5.
#
#   ## DOCTRINE EARNED TODAY
#   H15 paid for itself inside one build -- driving the target first would have read as "the
#   target is hard" when the change had broken two working roots · one variable at a time is
#   what turned "the port fails" into "(a) is the breaker and (b) is not", and it cost one build
#   · a crash that MOVES under a treatment is evidence the treatment is live, not evidence it is
#   wrong · **a count cannot be diffed** -- `docs/redList.md` exists because a 60-vs-61 could be
#   stated and never explained · and an instrument that cannot be executed reports exit 0
#   through the wrong wrapper, which is the empty-capture twin of the unsurprising green.
#
#   ## ⚠ THE FIXIT LINE, GENERATED, LAST
#   `Tony's fixit incantations waiting: 0`
#   **The queue is empty. Nothing is pointing at anybody's foot.**
