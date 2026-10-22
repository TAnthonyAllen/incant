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
