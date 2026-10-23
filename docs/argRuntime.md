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

**R0 (trunk 466084ca / 7ae97eca, cherry-picked here):** itRT is a fleet row, born red under its own 10 s alarm (jitStarIdiomT's
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
