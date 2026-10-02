# Parse-then-fire, re-read on today's trunk (SEQ 261, resumed by SEQ 262; 2026-10-02, read-only)

**The question.** What is parse-then-fire's step 2 on today's trunk, after object-model strokes 1–5 and the deep clean?

**Provenance.** Trunk `jit-unified-emit-wip` (the 5.9 merge and deep-clean seals), bare; branches `parse-then-fire`
(tip `71d2a44`, last trunk merge 2026-09-27) and `p6-held-class` (2026-09-26) were **read, never rebased or merged**.
Four read-only agents did the census work: branch inventory, step-2 sizing, overlap census, and rulings plus P6.
Clod verified each headline claim before banking it: the stop condition's two texts; both probes, re-run and banked in
`incant/probes/`; and plant 4, with two more probes of its own. Nothing was built and no tap was opened.

**The stop, and its ruling.** The re-read stopped on its own stop condition: Control 6 (2026-09-25; the control signal
is read by the firing parent, at fire time) contradicted the signed object model (row 88 and F-O15: `isBranch` →
`ParseActivation`, "gone at return"). **Ruled 2026-10-02 (SEQ 262):** the control signal is **execution state** in
**P4's ruler slot (`branchKind`)**, bracketed at `processAction`, one writer, read by the firing parent. It does not
go on `ParseActivation`, and no snapshots are taken. The object model is amended in its §1.5 and row 88. **The
finding recorded with it:** parse-then-fire adds a **firing level** that the three-level model does not name, and its
shape is designed with step 2.

---

## The counts

| item | today |
|---|---|
| Branch commits not on trunk | `parse-then-fire` 24 non-merge, `p6-held-class` 3 more; `git cherry`: **27 of 27** not patch-equivalent to anything on trunk |
| Done on trunk by other means | the srDot and P1 drive-census `pop.sh` rows (`02ca6cf`, `26f499c`), 860047e's `pop.sh` half, P4's inert `branchKind` declaration |
| Obsolete | the C-form code (440ee54; 1b49e47's code half) -- ruled out in P8. Every `parentStuff` chain arm in the ptf code -- strokes 5.5b/5.8/5.9 retired the chain. Every bare `gParseActive` / `->floor` -- 5.1 moved the list into GroupRules and renamed `isFloor` |
| Still needed | the step-1 engine (58ab827, 3f48ff2, cf2c768, 0f77486, a9d637b, 860047e's code, 5e30f2a, e2b1e6c); measureRetire (0512109); **P4** (e181681, 333c331 -- home now ruled); P6's work in progress (57f3e7a, 700c884, da782ce); the record docs (2aac1f8, 4502e41, the P5/P6 stop notes); `docs/overlapCensus.md`, which exists only on the branch |
| `deferred` | **2 writers, 8 readers** in tok (plan 3 / 11, 09-25); 10 generated lines; 15 `defer` rules in incant/grammar (unchanged); 6 fixture lines |
| `deferredAbove` | **20 lines, 1 caller** (fireLabelMethod), list-only to the first floor (5.5b), reads the activation's face (5.3); 4 witness calls; **4 pop.sh rows** (the plan named 2, so 2 more are owed a mapping) |
| The yield channel | **1 adoption seat** (GroupItem.twk fireLabelMethod), 5 readers (2 exempt), 2 attach seats, **5 yieldOrValue splits** (aCTionDO, aCTionFOR, aCTionIF, aCTionWhilE, aCTionXpress) -- unchanged |
| Overlap census | **55 then, 51 live** (A12, B7, B15 removed on trunk; A17 never landed); causes 1 and 2 -- where every plant lives -- **intact, 18 of 18** |
| Step 1 on trunk | **none of it.** No `ptfRecord`, no replay, no RETAGCARRY code, no `unwrapsOnAttach` |

## The port shapes (costed; no recommendation here)

| shape | what it is | conflicts with strokes 1–5, by function | cost |
|---|---|---|---|
| **(i)** replay step 1 onto a fresh branch from trunk | cherry-pick the still-needed commits, dropping the done `pop.sh` rows and the C-form code, and respell every chain arm and list spelling | `parseRule` (heaviest: 5.1's push, 5.8's `enclosingStuff`, 5.9's `into` snapshot, the bracket); `parse()` (5.5a push, 5.9); `attachLabel` (5.8); `checkInput`'s label mint (5.6a's `labelOf` -- the same lines as 0f77486's witness); `driveStep` (floor, `driveFloorLabel`, the load-bearing hand-carry); `processAction` (5.6b); `jitBuildFunction`; `jitProbeDrive`; `jitContext.h` (ParseActivation moved into GroupRules) | every step-1 certificate re-run; P2's numbers re-measured (H14) |
| **(ii)** rebuild step 1 from the plan on trunk's model | write the engine fresh against today's names: the activation list instead of chains, `enclosingStuff` for "who is above" | no textual conflicts | re-deriving the engine; the plan's P2 numbers re-measured |
| **(iii)** land the trunk-ready strokes first, then (i) or (ii) | three strokes independent of parse-then-fire, each landable and certifiable on trunk today:<br>**T1 -- P4, as ruled.** The `isBrancH` accessor (e181681's shape; GroupFields slot 45 is free). The `branchKind` ruler slot with one writer (aCTionBrancH, both roads), read and cleared by the firing parent after each child (aCTionBlocK, aCTionDO, aCTionFOR, aCTionWhilE, aCTionIF), and saved/cleared/restored at processAction, parseRule's fire and the jit emit walk. The `isBranch` stamp's writers retired, then the GroupBody bit (a layout change). Fixture: ctlStampT's 10 rows. **The plan's gap belongs here too:** `byRef`'s loop-steering meaning (aCTionFOR reads it off the statement RESULT) is control on the value channel, which Control 6 forbids.<br>**T2 -- F-134**, RETAGCARRY's trunk road: shared nodes renamed at attach.<br>**T3 -- F-135**, plant 4's cure: a second bit for "subscript", or the opGet shape rewrite (Tony's choice, P8 A7). | T1: `parseRule` (Generate.rtn's `isBranch = 0`), `processAction` (its `isBranch = 0`), `jitBuildFunction`. The ruleActions functions P4 touches were **not** changed on trunk since `f6af722`. T2: `attachLabel`, `fireLabelMethod`. T3: `aCTionBraced`, `checkInput`'s label mint, `attachLabel`'s unwrap arm, or `aCTionTokenXP`'s subscript arm | T1 is a layout stroke, and its fixture exists on the branch. T2 is small, or it closes with step 2's value handoff. T3's size depends on the cure chosen |

## The evidence

### What the branch holds (item 1)

The full commit table is in `ipc/clod-to-clay.md` SEQ 166. **The named plants on today's trunk:**

| plant | on trunk |
|---|---|
| 1 -- attach reads `isGROUP`, which NamE's action wrote | **live**; the inline predicate is unchanged (`attachLabel`'s unwrap arm). A Rule C read |
| 2 -- aCTionANYtoken reads NamE's resolution | **live**, unchanged; the C-form alternative was ruled out (P8) |
| 3 -- the replay set `fLAG` on an unwrapped label | branch-only; no trunk road (no replay) |
| **4 -- `fLAG` "subscript" vs "recycle"** | **pointable by reading; NOT reproduced on trunk** -- six shapes green (`incant/probes/twoSubscripts`, `subscriptShapes`). Filed **F-135** (SEQ 262 R3) |
| **RETAGCARRY** | the replay code is branch-only, **but trunk has its own road, reproduced**: fireLabelMethod adopts an action's return and attachLabel's promote arm retags it. `true` becomes "StatemenT" after the first top-level `cerr`, and the live field s2C becomes "StatemenT" after an Iterate (`incant/probes/retagSharedNode`). Filed **F-134** |
| stale chains | **retired on trunk** (5.5b, 5.8, 5.9); a port asks the list only |

### Step 2's retirements, sized (item 2)

Every population is the same size or smaller than in the 09-25 plan. Step 1's own deletions (ptfStmtAbove, the replay's
held arm, its substitution and unwrap) were never on trunk. **The deletion list is smaller and the mover list is two
rows larger** -- deferredAbove's (b) anti-vacuity row and the ShortcuT row also retire with it. P4's control slot is
not on trunk: `isBranch` is still stamped and read at 17 lines.

### The overlap census, on trunk (item 3)

`docs/overlapCensus.md` is branch-only. The cause assigned to each row was reconstructed by the agent so that every
count matches the 09-24 wakeup's totals; it is not the census author's.

| cause | then | now | status | what changed it |
|---|---|---|---|---|
| 1 name resolution (`group`) | 9 | 9 | **remains** | nothing; only A4's generating arm went (S4) |
| 2 label shape at attach | 9 | 9 | **remains** | some sites trimmed (parseAny, leaveAlt, processCode's label arm) |
| 3 define / registry state (exempt) | 14 | 14 | remains, smaller surface | setLimits, the parentStuff/parentLabel writes, fireNewParse, statementMatches cut |
| 4 input-stream state | 10 | 10 | remains | sourceLine's stamp cut (S5) |
| 5 method / frame context | 6 | **4** | reduced | **A12** (SEQ 212: the face re-resolve reads `gParseActive`), **B7** (5.6b: `ruleSTUFF` has no reader) |
| 6 refusal | 3 | 3 | remains | -- |
| 7 misc | 3 | **2** | reduced | **B15** (S4: `isPRINTING` has no reader) |
| 8 step 1's globals | 1 | 0 | not on trunk | never landed |

**Through Rule C's lens:** strokes 1–5 changed the who-is-active machinery (cause 5). **They did not remove a single
attach-time read** -- trunk still fires every ordinary action during the parse, so every direction-1 overlap is a live
read. One Rule C read sits outside the 55: interpretXP reads the token's `registry == opFields` and
`actionType || instructType`, which NamE's resolution decides (P8's extra site). It is live.

### P6's open question, re-asked (item 4)

- **Does an unrun IF still hand back its condition's value? Yes.** aCTionIF seeds `result` from the condition, and
  nothing overwrites it when no arm runs. Owner-run, it hands back the condition FIELD itself; a run arm hands back the
  live assignment target. `incant/probes/unrunIf`: `UI HOLD unrun tag= uiF`, `UI HOLD else tag= uiN`. **Both break
  values ruling 1–5** ("a construct hands its parent a VALUE … an IF whose arms did not run hands back nothing").
- **Does RETAGCARRY's shared-node rename still have a road on trunk? Yes** -- the adoption-then-promote road above
  (F-134). Step 2's value handoff closes it by construction: with no ordinary action firing before attach, "a label at
  attach time is the parse's own" (P6's text).

### The held refactors (item 5)

| refactor | step 2 | why |
|---|---|---|
| D-23 `fLAG` (5 meanings) | **reshapes in part** | P6 moves the unwrap arm's recycle write (meaning D) to fire time; plant 4 (C vs D) is its own stroke (P8 A7); meanings A, B and E are untouched |
| D-24 `sukcess` V vs R | **narrows** | ordinary actions no longer fire in the parse, so the veto survives only for the exempt class (ruling 7) |
| D-25 `isLabel` "do not clear" | **leaves alone** | unrelated to firing order |
| D-27 `deferred` | **retires as first planned; reshapes as ruled** | SEQ 198 kept `defer` as the held-class marker; its pending-action meaning is bypassed at PTF=1; its owner-run value becomes the root taking the value |
| D-28 `byRef` | **leaves alone -- a gap** | its loop-steering meaning reads control off the statement's value, which Control 6 forbids; T1 is its natural home |
| D-29 RuleStuff `label` (a promoted child) | **reshapes; becomes reachable** | under parent-driven firing a promoted label is the parent's while its `labelOf` stays the child's, so a label-keyed dispatch would run the child's action. The one-site fix (write `labelOf` on promote) becomes owed with P6 |
| **S8** (D-30: label, hereAt, kount, sukcess onto the activation) | **neither a prerequisite nor made moot** | step 2 removes S8's fire-time writers (the adoption into `label`, the veto into `sukcess`) but not its parse-time recursion state (the callBracket, getStuff's inProcess copy). **The ordering hazard:** if S8 lands first, the per-call slot moves onto an activation that is gone by replay time, and whichever lands second carries the fix. **SEQ 262's ruling sets the precedent:** what the firing level needs does not live on `ParseActivation`. `ParseActivation.label` already names the drive-floor slot (D-30's naming collision) |

### Frontier's next edge (item 6) -- candidate stations, in pipeline order

The frontier is "re-aim pending, after the parse-then-fire re-read" (SEQ 260 R2). These are drawn from step 2. Each
station prints its read value (H4) and dies at the first one that fails:

1. **The control slot (T1).** After `continue v;` and a jit-compiled `return w;`, the operands' `isBrancH` reads 0, and
   the loops still branch (its non-zero sibling: the loop ran 2).
2. **No shared node renamed (T2).** After a top-level `cerr`, `true`'s tag is still `true`; after an Iterate, s2C keeps
   its tag.
3. **Recorded, not run.** A top-level statement's ordinary fires are recorded during its parse, and none runs before
   the statement ends.
4. **Replay equals the old road.** At statement end, the fire multiset equals PTF=0's on the eight M1 fixtures.
5. **A failed alternative fires nothing.** The conservation row: discarded + replayed = recorded, UNREACHED 0.
6. **The held class.** A statement-level `defer` construct is held and fired by the root as owner; deferredAbove is not
   asked.
7. **Values.** An unrun IF hands back nothing (values 1–5), and the root reads its construct's value.

---

Clod's lean, as asked, kept out of the body above: shape (iii). T1 is ruled and has a ready fixture; T2 is a reproduced
silent wrong answer on trunk today and T3 a ruled one. Landing them first leaves step 1 a smaller, cleaner surface, after which (ii)
costs less than (i) against five strokes of conflicts.
