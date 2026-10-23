# The inlined callee's run-time argument -- branch jit-arg-runtime (SEQ 396, Stroke B)

Ruled (Tony, SEQ 393 R2, SEQ 395, SEQ 396): runAction's inline arm binds the callee's argument AT RUN TIME as
jitEmitSelfCall does, through one helper for both; the bracket is option (c) -- a push at the inlined region's entry and
a pop-and-restore at its exit, the argument binding only, no locals (R0); the pop runs on EVERY exit -- the fall-through,
the refusal exit, the handed-over return's exit (R1); inlined regions nest, so the pending store behaves as a stack (R2).
Recon: docs/jitter.md "SEQ 392" R2, "SEQ 395" B0.

## The cure, as designed (written before the build)

- **One bind helper**, `jitEmitArgBind(argument, action)`: jitEmitSelfCall's argument block lifted verbatim (the
  published run-time node, a boxed count, or the baked operand, bound through jitBindArgRT). It leaves the emitted
  argument in gJitBoundArg and returns 1 when it emitted a bind. jitEmitSelfCall calls it -- its IR is unchanged.
- **The channel halves**, `jitChanPushRT()` / `jitChanPopRT()`: the pending push and the pop-and-restore, lifted out of
  jitSaveFrameRT / jitRestoreFrameRT, which now call them -- the self-call's IR and behaviour unchanged.
- **The inline arm** (GroupActions.rtn, runAction's jitting arm): after the emit-time bind (kept -- the walk needs it),
  `jitEmitInlineEnter(argument, field)` emits the bind and, ONLY when a bind was emitted, a jitChanPushRT call, and marks
  the frame. jitInlinePush then opens the frame as today. jitInlinePop, after it has joined the region's exits (the
  fall-through branches to exitBB, and every early exit -- jitEmitReturn's, jitEmitStmtRT's refusal and handed-over
  return, jitEmitRefusedCheck's -- already targets exitBB), emits jitChanPopRT at that one join for a marked frame. An
  inline that binds nothing emits nothing new, so its IR stays byte-identical.
- **R1 holds by construction**: every exit of the region reaches the join. (Named, not covered: a `continue` in an
  inlined callee with no loop of its own branches to the CALLER's loop condition -- a pre-existing divergence, no row.)
- **R2 holds as it stands**: gChanPend is one slot, but it lives only between the bind and the push emitted right after
  it; gChanStk is the stack. Nested regions push and pop in LIFO order around each other and around self-calls.
- New externs: jitEmitArgBind, jitChanPushRT, jitChanPopRT, jitEmitInlineEnter -- canary 366 -> 370. No groups.ext
  change. The inline arm consumes a published node (gJitLastIsNode cleared), as jitEmitSelfCall does.

## Pre-registered movers (pre-cure = ~/bin/incant at trunk seal 194; pop.sh 1646 green with these rows)

1. **termCountT jitted** (pop.sh, gen26's construction): `REFUSED argument` lines **170 -> 0**; TCR / TCC lines
   **170 -> 664** = the plain run; the refusals by name **= the plain run's** (its 48 named, data-less rules). Born red.
2. **gen26 termCountT**: DISAGREE (712) -> agree; agreement **14 -> 15 / 26**.
3. **generateParse's 8 inlined null-argument cases** (every generator file: inlined into parser 2, walkRules 6, each a
   published node -- tap, reverted): they now emit a bind, push and pop into parser's and walkRules' IR, which the
   verifier refuses (-5) in all 26 files. **Expected: still -5 in all 26, no value moves.** A change in either is a finding.
4. **jitInlineBindT** (new, today's values = the twin): unchanged by the cure; it carries H7 (ii) and (iii).
5. Everything else row for row; jitLadder identical. Anything else that moves is a finding.

## H7 (cure committed first), each red by value

(i) the inline arm's run-time bind removed -> termCountT jitted red (170 back); (ii) the pop removed -> jitInlineBindT's
sections red; (iii) the pop on the fall-through only -> IB-2 and IB-3 (the early exits) red, IB-1 green. Restored md5 = cure.

## Measured, and STOPPED (2026-10-22; clone; pre-cure ~/bin/incant at seal 194, cure ddB1 = 0095f08b)

Built bare; canary **366 -> 370** (jitEmitArgBind, jitChanPushRT, jitChanPopRT, jitEmitInlineEnter); jitSaveFrameRT /
jitRestoreFrameRT now call the channel halves. pop.sh pre-cure 1646, cure 1645; jitLadder identical; gen26 14 / 26 both.

| pre-registered | measured |
|---|---|
| termCountT jitted `REFUSED argument` 170 -> 0 | **as registered (0)** -- the inlined argument is bound at run time |
| termCountT jitted TCR / TCC 170 -> 664; refusals by name = the plain run's | **FAILED -- THE STOP: the run RUNS AWAY** (exit 142 under the 60 s alarm, 13.4 M lines, `TCC  ANYorNum` forever). tcRule's handed-over `iterate tcCur on argument` now succeeds at run time, so the COMPILED `while ++tcCur` after it is reached for the first time -- and never ends. Before the cure the iterate refused and the refusal left the inlined region ahead of the loop |
| gen26 termCountT agrees, 14 -> 15 | **no: x1 = 142**, DISAGREE; agreement 14 / 26 |
| generateParse's 8 inlines: parser / walkRules still -5 | **as registered** (25 files; termCountT's copy is lost to the kill) |
| jitInlineBindT unchanged | **as registered**: every row as today |
| everything else row for row; jitLadder identical | **true** |

**Minimal reproduction (probe itRT, not in the fleet):** `itRule code={ iterate itCur on argument; while ++itCur; itN = itN
+ 1; };` inlined into `itWalk`'s `while ++itR; itRule(*itR);` over Grokking. Trunk: 0 children (85 refusals, the unbound
argument). Cure: runs away (142). Twin: 247. So the bind exposes a SECOND mechanism: a compiled `++cursor` loop over an
iterate that was HANDED TO RUN TIME does not terminate -- the cursor the run-time iterate set up is not the one the
compiled step advances (inferred, NOT traced).

**H7, run on the bracket half (the runaway does not touch it), single fixture, alarm-bounded:**
- (ii) the pop removed -> jitInlineBindT **IB-1..IB-4 all `0 0 1`** (the caller reads the inlined callee's binding --
  B0's leak exactly); IB-5 0.
- (iii) the pop on the fall-through only -> **IB-2 and IB-3 `0 0 1`** (the refusal exit and the handed-over return's
  exit skip it), **IB-1 and IB-4 `0 1 2`**.
- (i) the run-time bind removed is the pre-cure state (170 `REFUSED argument`), not rebuilt.
Restored md5 = the cure; bare retok = the committed .mm.

**Open for Tony:** the compiled `++cursor` loop over a handed-over iterate -- recon, a fleet row (itRT's shape, pinned),
or a fixit; Stroke B's buy waits on it, since the cure turns termCountT's wrong answer into a hang.

## SEQ 402 -- the runaway: the handed-over iterate's ++ (2026-10-23; clone; cure binary ddB1 = 0095f08b)

**R0 (trunk e0a45132 / d3548391; cherry-picked here as 466084ca / 7ae97eca):** itRT is a fleet row, born red under its own 10 s alarm (jitStarIdiomT's
shape): IT-1 jitted, today 0 on trunk, intended the twin's 247; its REFUSED lines, today 85, intended the twin's 24 (the
members with no list), by name. On this branch before the cure: exit 142, IT-1 never printed, 2 REFUSED lines.

**R1, MEASURED (no STOP):** itRT's IR on the cure binary (INCANT_JIT_DUMP=2, INCANT_JITTER_ERR): the inlined iterate is
ONE run-time call (`%stmtRT = jitStmtRT(...)`, the statement handed over), and `++itCur` (block `cond3`) is `load i32`,
`add 1`, `store`, `icmp ne 0` on a baked address -- a COUNT increment that is never zero. The outer `++itR` emits
`iterNext` (opPlusPlus called at run time). Tap on opPlusPlus's build-time read (clone, reverted md5-identical): `itR
isIterator=1`, `itCur isIterator=0`, both build walks; in one run the baked address is itCur's body + 0x58, its count. So
the emitted ++ is a count increment on the cursor the handed-over iterate sets up at run time: the iterate refuses at
build (the argument has no list there), so it never flags its cursor, and opPlusPlus takes the count arm.

**R2, the cure, as designed (written before the build):** aCTionIterate's three poison arms (the source is nothing, a
pointer not a list, no list) record the cursor under jitting -- `jitCursorHandOver(iterator)` into gJitRTCursors (cleared
at each compile's entry, jitRunAction). Those are the refusals that hand the iterate's statement over (aCTionBlocK ->
jitStmtEnd). opPlusPlus's build-time read asks `jitHandedCursor(result)` ahead of its isIterator arm, and a recorded
cursor emits jitEmitIterStep -- the iterator step called at run time, where the handed-over iterate has flagged the
cursor and given it its list -- the same IR the outer `++itR` gets. New externs jitCursorHandOver, jitHandedCursor:
canary 370 -> 372. No groups.ext change (same include chain, bear-trap #46).
Named, not covered: `--cursor` (opMinusMinus) over a handed-over iterate has the same build-time read; not touched.

**Pre-registered movers (pre-cure = ddB1, pop.sh with the itRT rows):**
1. **itRT**: exit 142 -> 0; IT-1 -> 247; REFUSED lines 2 -> 24 and = the twin's by name.
2. **termCountT jitted**: runs to its end (exit 0, sentinel); TCR / TCC -> 664 = the plain run's; the refusals by name =
   the plain run's. gen26 termCountT x1 142 -> 0 and agrees: 14 -> 15 / 26.
3. **jitStarIdiomT may move** (its hang is the same class: aCTionIterate poisons `*idF` at build, opPlusPlus then reads
   isIterator 0). Reported, not re-pinned (SEQ 402).
4. Everything else row for row (termCountT's runaway line count is alarm-timing noise, H3); jitLadder identical;
   generateParse's inlines still -5. Anything else that moves is a finding.

**H7 (cure committed first):** opPlusPlus's jitHandedCursor read removed -> itRT back to 142. Restored md5 = cure.

### SEQ 402 R2 measured (2026-10-23; clone; pre-cure ddB1 = 0095f08b + the itRT rows, cure dd402 = b228051f)

Built bare; generated diff = the intended blocks only (no #42 re-aim); canary **370 -> 372** (jitCursorHandOver,
jitHandedCursor). pop.sh pre-cure **1648**, cure **1654**; jitLadder **PASSED, identical**; gen26 **14 -> 15 / 26**.

| pre-registered | measured |
|---|---|
| itRT exit 142 -> 0, IT-1 -> 247, REFUSED 2 -> 24 = the twin's by name | **as registered** -- all four rows green |
| termCountT jitted runs to its end; TCR / TCC -> 664; refusals by name = the plain run's | runs (exit 0), sentinel, TCR / TCC **664**: as registered. The by-name row stayed red, and the cause is the ROW (B1's, mine): the jitted source has one more line (`jitter;`), so every `[line N]` is one higher. Same 48 names. Stripped of line numbers (the commit after the cure) it is green |
| gen26 termCountT x1 142 -> 0, agrees; 14 -> 15 | **as registered** (diff 0) |
| jitStarIdiomT may move -- report, don't re-pin | **MOVED: its hang is cured** -- exit 0, JSI-1 walks **8** = JSI-I, its `# intended`. Its two rows (pinned 142 / 0) read red; NOT re-pinned |
| everything else row for row; jitLadder identical; parser / walkRules -5 | **true** (gen26's other 25 lines identical); acceptStartT's printed address moves (H3 noise) |

**H7** (cure committed first, single fixture, alarm-bounded): opPlusPlus's jitHandedCursor read removed -> itRT **exit
142**, IT-1 never printed; termCountT jitted **142** under a 20 s alarm. Restored from the commit: Instruct.rtn and
GroupRules.mm md5 = the cure.

Named, not covered: `--cursor` over a handed-over iterate (opMinusMinus reads isIterator at build the same way).

## SEQ 403 -- closing Stroke B: the cursor record's lifetime, then `--`

**R0, MEASURED -- A LEAK (clone, cure dd402 = b228051f).** gJitRTCursors is cleared at ONE site, jitEmitters.rtn:3785,
jitRunAction's entry: once per COMPILE. A compile builds several functions (the callees that need their own function,
then the driver, across restarts), and they share it. Two probes:
- **(a) the dispatched shape, two separate compiles** (A hands over `iterate c on argument`; B, compiled later, does
  `c = 5; ... ++c`): B's IR carries iterNext -- but it CANNOT discriminate. After A's run c is a real iterator on BOTH roads
  (`c = 5` leaves it holding the walk's last member; the twin prints DEFINing), so B's iterator step is the language's own
  isIterator read, not the record.
- **(b) one compile, two functions -- jitCursorLifeT, the fixture now:** lDrive inlines bRec(1), whose self-call gives bRec
  its own function, built after lDrive's walk recorded lc. Nothing has run, lc is a plain count, and bRec's IR carries an
  **iterNext**; LB-2 jitted **5**, the twin **6**. The record outlives the function build that wrote it.
Born red on the branch (pop.sh 1654 -> 1661: 7 new green, 2 red -- LB-2 5 / 6, jit_bRec iterNext 1 / 0); jit_lDrive's
iterNext x2 (lR, lc) is green and is R1's "A still steps its cursor".

**R1, the reset, as designed:** the clear moves from jitRunAction's entry to jitBuildFunction's head, beside
gJitComputedVal -- every function build, the driver's restart builds included, starts with an empty record; the iterate
and its ++ always sit in one build (an inlined callee is part of its caller's). Movers: jitCursorLifeT's two red rows ->
green; everything else row for row. H7: the clear removed from jitBuildFunction (and not restored at jitRunAction) -> LB-2
back to 5. Canary unchanged (372).

**R1, MEASURED (cure dd403a = 5e92c41b):** jitCursorLifeT LB-2 **6** = the twin, jit_bRec's `++lc` is `add i32 ... 1` (no
iterNext), jit_lDrive keeps both iterNext (lR, lc); itRT 247. pop.sh **1661 -> 1663**, exactly the two registered rows
(plus acceptStartT's printed address, H3). Canary 372. **H7:** the clear removed (not restored at jitRunAction) -> LB-2
**5** again. Restored from the commit: jitEmitters.rtn and GroupRules.mm md5 = the cure.

**R2, `--`, pre-registered (born red at dd403a):** itBackRT -- itRT with `while --ibCur`. Today exit **142** (opMinusMinus
reads isIterator 0 at build and emits jitDec, a count that goes 0, -1, -2 ... and never stops), IB-1 never printed, 2 REFUSED
before the kill; the twin 247 with 24 REFUSED. pop.sh 1663 -> 1666 (3 green, 4 born red). The cure: opMinusMinus asks
jitHandedCursor ahead of its isIterator arm and emits jitEmitIterStepBack. Movers: itBackRT's four rows -> green; itRT,
termCountT jitted, jitStarIdiomT and jitCursorLifeT unmoved; jitLadder identical; canary 372 (no new extern). H7: the
check removed -> itBackRT 142 again.

**R2, MEASURED (cure dd403b = aa51c889):** itBackRT exit **0**, IB-1 **247**, 24 REFUSED = the twin's by name. pop.sh
**1666 -> 1670**: itBackRT's four rows and nothing else (acceptStartT's address, H3); itRT, termCountT jitted and
jitStarIdiomT's rows byte-identical to SEQ 402's cure run; jitLadder **identical**; gen26 **identical** (15 / 26); canary
**372**. **H7:** the `--` check removed -> itBackRT **142**, IB-1 never printed. Restored from the commit: Instruct.rtn and
GroupRules.mm md5 = the cure. Stroke B closes here; the buy follows on trunk (SEQ 403 R3).
