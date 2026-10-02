# Parse-then-fire step 1, rebuilt on trunk's model -- the plan (SEQ 268, 2026-10-02; nothing built)

**What this is.** The plan for rebuilding step 1 on today's trunk, port shape (ii) as ruled (SEQ 263 R1). It plans and
builds nothing. **Inputs:** `docs/ptfReread.md` (the re-read), `docs/ptfStep2Plan.md` (the step-2 plan, verbatim from
the branch), `docs/overlapCensus.md` (the overlap census), and branch `parse-then-fire` (tip `71d2a44`), read-only.
The engine commits read were `58ab827`, `3f48ff2`, `cf2c768`, `0f77486`, `a9d637b`, `860047e`, `e2b1e6c`, `5e30f2a`
and `0512109`. **Trunk at planning:** `be8028e` plus the SEQ 268 riders. Its state: fleet 885 / 1 and canary 300.
T1 (P4, `branchKind`) and T2 (F-134) have landed, and fLAG case 12 has retired.

**What step 1 is**, unchanged from the branch: an ORDINARY label action inside a top-level statement is **recorded** at
its fire and **replayed** at the statement's end, in record order. The actions and their order are the same; they
simply run later. These are exempt and fire as today:
- `code`: processCode's own parse;
- `outside`: a fire with no statement around it;
- `define`: the define family;
- `decides`: the parse-deciding actions ANYtoken, DelimText, ShortcuT, CheckFor and CodE.

`PTF=0` is trunk, from the same binary.

---

## 1. The stroke list (in order, sized, each with its certificate)

**Every certificate carries these standing lines beyond its own rows:**
- PTF=0 equals trunk row for row (pop.sh, with the `docs/sealCaptures` diff);
- jitLadder, printPop, decodePop and ddPop are unmoved at both settings, except for rows named in advance;
- the canary is read off the tree (H14), with every new extern named;
- the retok is bare.

**Strokes that add a struct field** also carry the full bare-tokall diff with every generated line explained (the
SEQ 235 R2 form, extended to the new structs).

| # | stroke | size | its certificate |
|---|---|---|---|
| **1.1** | **The switch and the two witnesses, no behaviour.** `firingMode` and `firingTrace`, two GroupRules ints read once from `PTF` and `PTF_TRACE` (unset means 0 -- see OR-7). Three new callouts: `measureFireOrder` (M1: rule, the label's tag at the fire, fired or held, the phase), `measureParseFire` (M2: a fire during the parse, by class) and `ptfClass`. Nothing is gated yet. | ~90 lines, 3 externs | Fleet row for row at PTF unset, 0 and 1, because PTF=1 does nothing yet. **M2 on kant8T reads ORDINARY N > 0** (re-measured; the branch read 553). This is the non-zero sibling that 1.4b's zero row needs. |
| **1.2** | **Plant 1's predicate extracted.** `GroupItem::unwrapsOnAttach(max,promote)` is attachLabel's unwrap test (`promote && isGROUP && max > 1`, `GroupItem.twk:267`) moved verbatim, with its groups.ext mirror. A pure refactor. | ~15 lines | Generated diff: the extraction alone. Fleet row for row. (Ruling A asks the SAME predicate at replay, so it gets its one home first.) |
| **1.3a** | **The firing level, declared inert.** The two structs and `gFiring` (§3), in `GroupRules.twk` and mirrored in groups.ext, with forward declarations as for ParseActivation (bear-trap #58). Nothing reads or writes them. | ~25 lines | Full bare-tokall diff: the struct declarations and the member alone. Fleet unmoved. **The SEQ 237 R1 census of each field name is in §3 (zero bare uses).** |
| **1.3b** | **The engine: record, replay at a top-level statement's end, the replay frame.** The record seat is in `fireLabelMethod` (the ONE fire seat both roads share: `parse()` at `GroupItem.twk:1319` and `exitFromParse` at `Generate.rtn:42`). The attach note goes in `attachLabel`. The replay runs at a top-level StatemenT's own fire. The replay frame is in §3. The unwrap replay asks 1.2's predicate (plant 1). The replay never sets fLAG (plant 3). Reachability is by BODY (`0f77486`). The replayed retag uses T2's ownership test (OR-8). | ~300 lines, ~8 externs | **M2:** kant8T ORDINARY **0 at PTF=1**, against 1.1's N at PTF=0. **M1:** the per-rule fire multiset is identical at PTF=0 and PTF=1 on the named list (§6). **Error-diff:** the fleet at PTF=1 against PTF=0, every mover named in advance (§6). |
| **1.4** | **A failed pass fires nothing, and the conservation row** (the branch's P2, Tony's ruling (i)). The discard seats are the old road's per-pass mark at `parse()`'s `continueHere` (truncated at `matchFailed`), and the new road's mark at `parseRule` entry (truncated when `exitFromParse` returns 0). Integer marks only; no FireRecord-typed local in `parse()` (§3, capture). | ~40 lines, 1 extern | **Conservation, presence-with-value:** recorded = replayed + discarded(failed alternative) + rejected(0, a tripwire) + FRAMELEAK(0) + UNREACHED(0), each column printed. **H7:** with the truncation removed, UNREACHED goes non-zero (the branch read 932), red. |
| **1.5** | **Plant 2: the fire-time keyword check.** ANYtoken still decides during the parse, and it leaves a RECHECK record (`fireKind` 2). At replay, once NamE has resolved, today's test runs again, and a keyword used as a name refuses through `refuse()`. | ~30 lines | `if ;`, `do print 1;` and `else s2Y = 2;` at PTF=1 each REFUSE by name and the file continues. At PTF=0 they are ABANDONED, as trunk does. Named movers: §6's keyword rows. |
| **1.6** | **The recording scope (ruling A: a drive is its own root).** A drive entered while FIRING opens its own frame and replays its own records from its root. A drive entered while PARSING records into the enclosing frame, unchanged. The ONE writer pair is called from the two drive seats, `driveStep` and `jitProbeDrive`. A rejected drive discards its records (ruling (ii)); since 1.4 that is a tripwire at 0. | ~60 lines, 2 externs | FRAMELEAK **0** at PTF=1. The `srDot` sub-run row reads the rejected drive discarding its records and refusing nothing. **H7:** `PTF_NOSCOPE=1` gives FRAMELEAK > 0 and srDot red. driveDoorT's scoped-discard row stays 0/0/0/0 by design: its roots are not StatemenT. The row is P7's H7 pair. |
| **1.7** | **T3: plant 4's cure, the fLAG C/D split.** The cure is the one Tony chooses (OR-2): either a second bit for "subscript", leaving fLAG as "recycle" only, or the opGet rewrite. | a second bit: a layout stroke (GroupBody, groups.ext, tokall), ~20 lines; opGet: larger, its own plan | **H17: the control must run where plant 4 is not masked.** On trunk at PTF=0 it does not reproduce (six shapes green, `incant/probes/twoSubscripts`, `subscriptShapes`), so its red half runs **at PTF=1 on the 1.3b binary**. Its symptom there was deferNatT's `print s2L[1];` (`0f77486`), measured by `measureLabelReuse` (recycled-while-parented, 1 at PTF=0 on the branch). The cure makes that 0 at both settings. |
| **1.8** | **Coverage and the frontier.** A pop.sh sub-run at PTF=1 over §6's named list, with its rows. The frontier re-aimed to §7's stations. | ~60 pop.sh lines | The sub-run's rows are green at PTF=1. The frontier names its first failing station. |

**Not in step 1 (each with its reason):**
- The fLAG A/B split: define redirect and iterator poison. Neither touches the replay; held for after (§5).
- Step 2's retirements of `defer`, `deferredAbove` and the yield channel. Step 1 replays holds; step 2 retires them.
- P7's scope widening beyond top-level statements.

## 2. The open rulings (Tony's)

| # | the question | Clod's recommendation |
|---|---|---|
| **OR-1** | **May the replay frame rebuild the firing rule's activation from the record?** One activation reader a replayed action can reach is `driveStep`'s old-road attach (`GroupActions.rtn:303`, `parse(gParseActive.stuff)`). On trunk it attaches into the FIRING rule, whose activation is on the list at fire time. At replay that activation is gone; the top is the StatemenT's (overlap B10). | **Yes.** The replay frame pushes a floor and then one activation built from the record's own fields (`face` = `fireRule`, `stuff` = `fireStuff`). Nothing is copied from a live activation; SEQ 262's "no snapshots" was about the control signal. The alternative, a floor only, turns that attach into `parse(null)`, which drops the label (F-120's shape). |
| **OR-2** | **T3's cure:** a second bit for "subscript", or the opGet rewrite (P8 A7, already Tony's choice). | No recommendation beyond cost: the bit is a small layout stroke; opGet retires Braced's subscript arm outright and wants its own plan. |
| **OR-3** | **The 18 Rule C rows (§4) are a reconstruction.** The 09-24 census recorded the cause TOTALS (9 + 9) but no per-row cause. The re-read reconstructed them; this plan assigns them explicitly. | Confirm or correct the assignment in §4 before 1.3b's error-diff is read against it. |
| **OR-4** | **A8, the null yield.** On trunk, an ordinary action that returns null fails the parse, and the next alternative is tried. At replay the parse has already been accepted, so step 1 cannot reproduce that; it can only report it (`PTF NULLRET`). | Accept it as a named divergence class, counted as its own column beside the conservation row. The cure is step 2's: ordinary actions no longer decide the parse. |
| **OR-5** | **S8's order.** S8 (D-30) moves `label`, `hereAt`, `kount` and `sukcess` onto the activation. The replay writes the per-call `stuff.label` and `ruleSTUFF` for each replayed fire. | **Step 1 lands before S8**, and S8's plan inherits the replay seat as one more writer. Its target is OR-1's rebuilt activation, which is why S8's naming collision (`ParseActivation.label` is already the drive-floor slot) has to be settled in S8, not here. |
| **OR-6** | **How the seal carries PTF=1** while the switch exists. | Each seal records pop.sh at PTF=0 (the default) and a full pop.sh at PTF=1, diffed row by row, plus 1.8's named sub-run inside pop.sh. Retire the PTF=1 seal line when the switch retires. |
| **OR-7** | **The switch's default.** The branch read unset as 1. | **Unset means 0 on trunk**, so no binary changes behaviour without someone asking. PTF=1 is explicit. |
| **OR-8** | **RETAGCARRY at replay.** The branch's replay wrote the label's tag onto a returned node. On trunk T2 has ruled that a retag renames only a node the parse owns. | The replay asks T2's own test (`lab.labelOf || (!lab.registry && !lab.parent)`), extracted to one predicate with attachLabel's. A shared singleton or a live field is never renamed at replay. |

**Stop conditions, checked.** No field tok cannot see: every new field is in a tok class and mirrored in groups.ext
(§3). No contradiction found with a standing ruling:
- SEQ 262 (the control signal stays in `branchKind`, not on ParseActivation): the replay frame brackets `branchKind`; it does not move it.
- SEQ 263 R1 (shape (ii)): followed.
- Ruling A (a drive is its own root): stroke 1.6.
- Rulings (i) and (ii) (a failed pass, and a rejected parse, fire nothing): strokes 1.4 and 1.6.
- SEQ 218 R1 (no field tok cannot see) and SEQ 235 R1 / SEQ 237 R1 (naming): §3.

OR-1 is the one place a reader might see tension with SEQ 262, and it is put to Tony rather than assumed.

---

## 3. The firing level -- its shape (R2)

**What it is.** The object model's three levels are rule (GroupBody), instance (GroupItem) and activation
(ParseActivation, gone at return). Parse-then-fire needs a fourth: **work recorded during a parse, to be done after
it.** It outlives the activations that made it and dies when it is replayed or discarded. SEQ 262 ruled that what the
firing level needs does not live on ParseActivation. So it gets its own two records, declared exactly as ParseActivation
is: structs inside `class GroupRules` and mirrored in groups.ext's `external GroupRules`, with forward declarations
(`external struct FireRecord no.h`, `external struct FiringFrame no.h`) so each can name itself (bear-trap #58).

```
struct FireRecord                    one recorded fire (or hold, or keyword recheck)
    GroupItem    fireRule;           the rule whose action fired -- also the face OR-1 rebuilds
    RuleStuff    fireStuff;          its RuleStuff; the action method is read off it at replay (fireStuff.actionMethod)
    GroupItem    firedLabel;         the label handed to the action -- NOT `label` (ParseActivation.label is the drive-floor slot)
    int          fireKind;           0 fire, 1 held (deferredAbove decided it AT RECORD TIME), 2 keyword recheck
    int          fireMax;            the firing rule's max (M1 and the trace)
    String       fireTag;            the label's tag at the fire -- M1 compares this, never the tag at replay
    int          attachMax;          the max and promote of the attach that placed firedLabel WHOLE (ruling A's
    int          attachPromote;        unwrap predicate is asked with these, not the fired rule's own)
    FireRecord   *fireNext;          record order

struct FiringFrame                   one recording scope, or one replayed fire's own frame
    FireRecord   *frameFirst, *frameLast;
    int          frameCount;
    int          frameReplaying;     1 while this frame's owner is replaying -- a drive entered now is its own root (ruling A)
    RuleStuff    frameRoot;          whose label the replay walks for reachability (a top-level StatemenT, or a drive's root)
    FiringFrame  *frameOuter;

GroupRules:  FiringFrame *gFiring;   the innermost frame (a base frame is made once, lazily)
             int firingMode, firingTrace;
```

**Two things deliberately absent:**
- **No function-pointer field.** The branch kept the method (`r->method`). It is read at replay from
  `fireStuff.actionMethod` instead. Within one statement only the define family writes `actionMethod` (overlap D2),
  and that family is exempt. This also keeps tok's untested fnptr-in-a-nested-struct form out of the design: bear-trap
  #20 measured fnptr members in a class body only.
- **No activation fields.** The hold decision is taken AT RECORD TIME, while the list is live (`deferredAbove` in
  `fireLabelMethod`), and stored as `fireKind`. Nothing of an activation is carried.

**Naming (SEQ 235 R1, SEQ 237 R1), searched 2026-10-02.** The population was every `*.twk`, `*.rtn`, `*.h` and
`groups.ext` in Groups and support, plus `incant/` and `IncantForms/`. A whole-word grep was run for each name:
FireRecord, FiringFrame, fireRule, fireStuff, firedLabel, fireKind, fireMax, fireTag, attachMax, attachPromote,
fireNext, frameFirst, frameLast, frameCount, frameReplaying, frameRoot, frameOuter, gFiring, firingMode and
firingTrace.

**Result: zero bare uses of any of them.** The one near-miss, `fireLabel`, occurs only inside `fprintf` strings in
measure.twk, and is why the field is `firedLabel`. **The capture rule still binds the build:**
- a FireRecord- or FiringFrame-typed local makes these names candidates for bare names in its function (bear-trap #58),
  so such locals live only in the engine's own functions;
- `parse()`, `parseRule` and `fireLabelMethod` hold integer marks and call helpers;
- 1.3a's full-tokall diff is the confirmation.

**Where it lives and its scope:**
- **The base frame** (made once) collects a top-level statement's records while it parses.
- At that statement's own fire (StatemenT, with no StatemenT activation above it), the frame's records are detached and
  replayed, and the frame is empty again.
- **A replayed fire runs in its own frame** (pushed on the C++ stack, as a ParseActivation is). A parse that action
  starts records there, and anything left at its end is counted as FRAMELEAK and discarded, never leaked.
- **A drive entered while a frame is replaying** opens its own frame, rooted at the drive's rule (ruling A, stroke 1.6).
  Its records replay from the drive's root at the drive's end; a rejected drive discards them.

**Lifetime:**
- **A FireRecord** is GC-allocated at the fire and unlinked when it is replayed or discarded.
- **A FiringFrame** is a stack local of the function that opens it: the replay loop, `driveStep` or `jitProbeDrive`.
  The base frame is the one exception.
- **gFiring** is saved and restored strictly nested, like `gParseActive`.

**Beside `branchKind`.** They are two pieces of execution state with two homes, and neither is the other's channel.
**The replay frame is a `branchKind` frame**, the sixth after processAction, parseRule's fire, the jit emit walk,
driveStep and jitProbeDrive. Each replayed fire saves, clears and restores it, so a break fired by a replayed action
cannot reach the statement's replay loop. `branchKind` itself stays a ruler slot (SEQ 262). A FiringFrame never
carries it.

**The replay frame, in full.** For each replayed record:
1. push a FiringFrame, which collects what the action's own parses record;
2. push a ParseActivation floor;
3. push the activation rebuilt from the record (OR-1);
4. save, clear and restore `branchKind`;
5. set `ruleSTUFF` and the per-call `fireStuff.label`, as the branch did, restoring both after;
6. pop in reverse order.

## 4. Replay without activations; Rule C's 18

**Do the labels carry enough?** Yes, with the record. At replay the activations are gone. Each one was read in one of
these places (the population is every `gParseActive`, `enclosingStuff(`, `enclosingFace(` and `deferredAbove(`
reader in the tree's `.twk` and `.rtn`, by function, 2026-10-02):

| reader | at record time | at replay |
|---|---|---|
| `deferredAbove` (fireLabelMethod) | read, and stored as `fireKind` | not asked |
| `enclosingStuff` (attachLabel, exitFromParse's attach, parseRule's `into`) | parse-time only | a parse an action starts pushes its own activations |
| `enclosingFace` (Generate.rtn:130, 177, 202 -- the leaf parses) | parse-time only | same |
| `driveFloorLabel` / driveStep's floor | a drive's own floor | the drive pushes its own |
| **driveStep's old-road attach (:303)** | the firing rule's activation is on the list | **OR-1's rebuilt activation** |

**What must be kept, and the S8 interaction.** The record keeps `fireRule`, `fireStuff`, `firedLabel` and `fireKind`;
nothing else.
- **Today**, the replay's per-call writes (`fireStuff.label` and `ruleSTUFF`) go where trunk's fire writes them: onto
  the RuleStuff.
- **If S8 lands later**, those writes move with the rest of the per-call slot, onto OR-1's rebuilt activation. That is
  why step 1 goes first (OR-5).

**Rule C -- the 18 attach-time reads.** ⚠ **The per-row cause is a reconstruction (OR-3).** The 09-24 census recorded
only the totals: name resolution 9; label shape (retag, reuse, hold stamps, null yield) 9. The row ids are
`docs/overlapCensus.md`'s.

| # | row | cause | step 1 at replay? | how, or why only step 2 |
|---|---|---|---|---|
| 1 | A1 NamE -> attachLabel unwrap | name | **yes** | plant 1: the replay asks `unwrapsOnAttach` after the action wrote `group` (ruling A) |
| 2 | A2 NamE -> ANYtoken keyword test | name | **yes, late** | plant 2: the fire-time recheck refuses by name. Step 2 removes the read (the matcher's own lookup; C-form measured NOT neutral 09-24) |
| 3 | A3 QuotE -> unwrap | name | **yes** | plant 1's predicate |
| 4 | A4 TokenXP -> unwrap (Token+) | name | **yes** | plant 1's predicate. Its generating arm was cut in S4 |
| 5 | A5 handleUnary -> unwrap | name | **yes** | plant 1's predicate |
| 6 | A6 Parens / Braced -> unwrap | name | **n/a** | no live instance (max 1) |
| 7 | D4 define family -> unwrap | name | **n/a** | the define family is exempt and fires during the parse, as on trunk |
| 8 | B2 consumers of unwrapped children (Search, DEBUG, interpretXP, DefinE) | name | **yes** | post-order: a child's unwrap replays right after its fire, before its parent's record |
| 9 | B4 container entry `label.group`, read by TokenXP, Iterate, BrancH | name | **yes** | the parse wrote it, and a later read sees the same node |
| 10 | A7 Braced fLAG -> checkInput recycle | shape | **no: stroke 1.7 (T3)** | plant 4. At replay Braced's write lands after the parse, so the next statement's checkInput can recycle a still-parented label. The cure is the C/D split |
| 11 | A8 null yield -> sukcess | shape | **no** | OR-4: the parse is already accepted at replay. Reported, never reproduced. Step 2's cure |
| 12 | B1 tree shape and the promote retag | shape | **yes** | the shape is the parse's. The retag is under T2's ownership test |
| 13 | B3 label text / token | shape | **yes** | match text is unchanged by delay. C11 (a buffer edit between) is its only exposure |
| 14 | B5 DelimText label text | shape | **n/a** | exempt (decides) |
| 15 | B6 hold stamps (`method`, `deferred`) | shape | **yes** | holds replay in record order (`fireKind` 1). Step 2 retires them |
| 16 | B8 `isLabel` / `rStuff` on a label | shape | **yes** | parse-written; plant 4's recycle is its one hazard (row 10) |
| 17 | B18 `isBranch` cleared on the returned node | shape | **retired** | T1b deleted the bit (2026-10-02); the control signal is `branchKind` |
| 18 | B20 a rule call's result (oneBitReturn, labelNO) | shape | **yes** | a drive from a replayed action is its own root (stroke 1.6) |

**Outside the 18, live:** interpretXP's `registry == opFields` and `actionType || instructType` (P8's extra site).
Step 1 handles it in post-order, because NamE's record replays before interpretXP's. Step 2 moves it to a parse fact.

**Tally: of the 18 rows,**
- step 1 handles 11 at replay (rows 1-5, 8, 9, 12, 13, 15, 16, 18);
- 3 are n/a (rows 6, 7, 14);
- 1 is retired (row 17);
- 2 need more than replay: row 10, which is T3 in stroke 1.7, and row 11, which only step 2 removes.

## 5. The plants carried over

| plant | what | in step 1 |
|---|---|---|
| 1 `unwrapsOnAttach` | attach read `isGROUP`, which NamE's action writes | 1.2 extracts it; 1.3b asks it at replay with the placing attach's max and promote |
| 2 the fire-time keyword check | ANYtoken read `input.group` before NamE resolved | 1.5; refuses by name, and the file continues |
| 3 replay never sets fLAG | the branch's unwrap replay had set the recycle bit; the next statement then reused a parented label (`dwN= Token`) | 1.3b; the unwrap replay clears and does NOT set fLAG |
| 4 / T3 | fLAG "subscript" (Braced) against "recycle" (checkInput) | 1.7, at PTF=1 for its control (H17) |

**The fLAG A-D split:**
- **Only C/D belongs in step 1, as T3.** It is the one meaning pair the replay moves in time.
- **A (the define-attribute redirect) and B (the iterator poison) stay held.** Neither is fired from a recorded action
  differently than today: A belongs to the define family, which is exempt, and B is runtime iterator state.
- **E retired today (SEQ 267).**

## 6. The pre-registered certificate

**M1, identity.** The per-rule fire multiset of (rule, `fireTag`, fired/held) at PTF=0 against PTF=1 must be equal on
the named list:
- `oneTest`, `jsonTest`, `f122T`, `doWhileNameT`, `dotChainT`, `adoptT`, `fireSeatT`, `convDriveT`;
- all present in `incant/pop/` on 2026-10-02.

Order differs by design (post-order at the statement's end), so the comparison is of multisets.

**M2, parse-time ordinary fires.** `measureParseFire` class=ORDINARY must read **0 at PTF=1**, fleet-wide. Its non-zero
sibling is kant8T at PTF=0 (1.1 re-measures it; the branch read 553).

**The conservation row** (1.4): recorded = replayed + failed-alternative + rejected(0) + FRAMELEAK(0) + UNREACHED(0),
plus OR-4's NULLRET column. Each column is printed, presence-with-value.

**The error-diff: PTF=1 against PTF=0, every mover named.** The branch's movers, carried as PREDICTIONS (H14; each is
re-measured, never cited):

| predicted mover | why | stroke |
|---|---|---|
| `if ;`, `do print 1;`, `else s2Y = 2;` | ABANDONED at PTF=0; refused by name at PTF=1 and the file continues | 1.5 |
| stmtRejT, site1RoadsT (22 pairs), probeDoorT's DO #2 verdict 0 -> 1 | these rows pin PARSE verdicts; at PTF=1 the near-miss parses and the refusal comes at the fire | 1.5 |
| the srDot sub-run row | a rejected drive discards its records and refuses nothing | 1.6 |
| the deferredAbove tripwire 413 -> 420 and loopVerdict 13 -> 12 | **NOT ATTRIBUTED on the branch** | **1.3b stops** if either moves and cannot be attributed in that stroke |
| deferNatT `print s2L[1];` | plant 4 at PTF=1 | 1.7 |

Any mover not on this list stops the stroke that shows it.

## 7. Frontier's new stations (for its re-aim, stroke 1.8)

Run at PTF=1. Each station prints the value it read (H4) and dies at the first failure.

1. **Recorded, not run.** A top-level statement's ordinary fires are recorded during its parse, and none runs before
   the statement ends (M2 0 for that statement; its non-zero sibling is the same statement at PTF=0).
2. **Replay equals the old road.** The statement's fire multiset equals PTF=0's.
3. **The unwrap is replayed.** `search A B;` hands Search the resolved children (the branch's first plant:
   `kids=GrouP,GrouP,GrouP` against trunk's `kids=reset,stack,Grokking`).
4. **A failed alternative fires nothing.** The conservation row, UNREACHED 0.
5. **A keyword used as a name refuses at the fire, and the file continues.**
6. **A drive from a replayed action is its own root.** FRAMELEAK 0.
7. **No recycled label is still parented** (T3). `measureLabelReuse` reads 0 at PTF=1.

## 8. Evidence

**The branch's engine, read** (`git show parse-then-fire:Generate.rtn`, lines 460-830):
- its state lived in `jitContext.h`, as `PtfRec[]`, `PtfAttach[]`, `PtfScope[64]` and `gPtfWalking[64]`. **That is
  invisible to tok**, which is why §3 re-homes it;
- its hooks were in `fireLabelMethod` (record and statement end), `attachLabel` (the attach note), `parse()` and
  `parseRule` (the pass discard), and `driveStep` and `jitProbeDrive` (the scope);
- its `ptfStmtAbove` walked the activation list inside a drive and the `parentStuff` chain outside it. **The chain is
  retired on trunk (5.5b/5.8/5.9)**, so "is a StatemenT above" asks the list only, and the replay floor (§3) stops it.

**The branch's measured trail, cited for direction only:**
- PTF=1 fleet 598 -> 656 (plant 1) -> 660 (plants 2 and 3);
- conservation 13,339 -> 13,342 -> 13,349, with UNREACHED 0 after P2;
- FRAMELEAK 37 / 289 -> 0 with the scope.

**Every number is re-measured on trunk** in the stroke that cites it (H14). The fleet is a different size today, and
fixtures have been retired and added since `71d2a44`.

**Riders (SEQ 268 R3, R4), done in the same commit as this plan:**
- the `:.` refusal's width is noted in `docs/flagCensus.md`;
- the kill-by-PID rule is in CLAUDE.md's Working Relationship section;
- **the conflicted-copy search, over Groups, support (`~/Dropbox/data/support`) and TOK, `find -L`:**
  - Groups: none. Support: none.
  - **TOK: seven**, all Xcode breakpoint lists:
    `TOK.xcodeproj/xcuserdata/anthony.xcuserdatad/xcdebugger/Breakpoints_v2 (T Anthony Allen's conflicted copy …).xcbkptlist`,
    dated 2026-06-30 (six) and 2026-07-02 (one), 20-21 KB each.
  - All seven are **gitignored** (TOK's `.gitignore:41`, `TOK.xcodeproj/**/xcdebugger/`) and none is tracked. The live
    `Breakpoints_v2.xcbkptlist` is 18 KB, modified 2026-10-02 12:48, when Xcode restarted.
  - **Reported, not removed.** They are Tony's to keep or delete.
