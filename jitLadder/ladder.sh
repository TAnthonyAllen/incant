#!/bin/sh
#  THE jitLadder.  Run from the Groups directory:   sh jitLadder/ladder.sh
#
#  Tony's goal, shaped: one simple action, jitted end to end, fired, intended
#  result returned -- then grown one construct at a time.
#
#  WHY A LADDER AND NOT ONE ACCRETING ACTION: an action that swells with every
#  new statement type gives you a red that says "something broke" and a
#  haystack. Rungs -- each the previous plus ONE construct -- give you a red
#  that NAMES the construct. genLadder's lesson, applied to the subsystem that
#  never had it.
#
#  ============================================================================
#  ⚠⚠ EVERY RUNG CARRIES BOTH MANDATORY CRITERIA. A GREEN ROW WITHOUT THEM IS
#  NOT EVIDENCE.
#
#  (a) COMPILE ONCE, FIRE TWICE, input changed AFTER emission.
#      A right answer does not prove the COMPILED code produced it. Under
#      jitting the interpreter executes the body FOR REAL at emit time
#      (docs/jit.md S2.2 -- a jitted print printed during compilation), so an
#      end-to-end POP can go green on an emit-time side effect while the
#      compiled function returns a baked constant. Right answer, wrong
#      universe, exit 0 throughout. The second fire recompiles NOTHING: if its
#      answer tracks the new input, the computation is happening at RUN time.
#      There is no other explanation, and nothing weaker will do.
#
#  (b) jitDegrade count == 0 for any rung claiming full coverage.
#      Nothing in the rung may silently fall through to emit-time
#      interpretation. This promotes the degrade counter from crossover
#      burn-down to a per-rung assertion.
#  ============================================================================
#
#  THE TWO INSTRUMENTS MEET AT THE CROSSOVER: the degrade count falling toward
#  zero measures the crossover in the NEGATIVE; each green rung measures it in
#  the POSITIVE -- language surface the JIT provably owns, end to end, at run
#  time. Burn-down on one side, ladder on the other.
#
#  Standing harness rules apply (CLAUDE.md Testing): H1 the binary is echoed;
#  H2 each rung's sentinel is checked FIRST and by name; H3 values are asserted,
#  never a golden IR diff -- field slots are baked ABSOLUTE ADDRESSES, so an IR
#  diff would move every run for reasons unrelated to correctness.
#  ⚠ $? is taken directly from the binary, never through a pipe.
#
#  ⚠ A DIVIDEND OF THE REFIRE SCAFFOLD, worth knowing before you split a rung in
#  two: a rung uses ONE testing() plus jitRefire, so it never calls testing()
#  twice on the same action -- which STRUCTURALLY avoids the sequential-state
#  corruption that forced the old jitElseT/jitThenT pair into separate files. The
#  scaffold built for the run-time proof also dissolved that constraint.
#
#  Debugging a rung: INCANT_JIT_DUMP=2 <binary> incant/<rung>  -- mode 2 is the
#  ATTRIBUTION instrument, showing the EMITTER'S OWN output before mem2reg. The
#  post-pass dump cannot tell you whether the emitter emitted something or the
#  optimiser produced it, which is the first question any rung failure raises.
B=${INCANT:-$HOME/bin/incant}
T=${TMPDIR:-/tmp}/jitladder.$$
mkdir -p "$T"
fail=0

if [ ! -x "$B" ]; then echo "  FAIL  binary not executable: $B"; exit 1; fi
echo "  bin   $B"
echo "  bin   $(ls -lL "$B" | awk '{print $5" bytes  "$6" "$7" "$8}')"

#  rung <file> <sentinel> <label> <want1> <want2>
#  Asserts, in this order: exit 0 · sentinel present · fire-1 value ·
#  fire-2 value (the run-time proof) · degrade count zero.
rung () {
    f=$1; sent=$2; label=$3; w1=$4; w2=$5
    $B "incant/$f" > "$T/$f" 2>&1
    if [ $? != 0 ]; then echo "  FAIL  $label -- nonzero exit"; fail=1; return; fi
    if ! grep -qF "$sent" "$T/$f"; then
        echo "  FAIL  $label -- TRUNCATED at exit 0; nothing in this run is interpretable"
        fail=1; return; fi
    g1=$(sed -n 's/.*fire 1 result: [a-zA-Z]* = \([0-9-][0-9]*\).*/\1/p' "$T/$f" | head -1)
    g2=$(sed -n 's/.*fire 2 result: [a-zA-Z]* = \([0-9-][0-9]*\).*/\1/p' "$T/$f" | head -1)
    dg=$(sed -n 's/.*jitDegrade count = \([0-9]*\).*/\1/p' "$T/$f" | head -1)
    [ "$g1" = "$w1" ] && echo "  ok    $label fire 1 = $w1" \
                      || { echo "  FAIL  $label fire 1 (got '$g1', want $w1)"; fail=1; }
    if [ "$g2" = "$w2" ]; then
        echo "  ok    $label fire 2 = $w2  <- RUN-TIME PROOF (no recompile, answer tracked input)"
    else
        echo "  FAIL  $label fire 2 (got '$g2', want $w2)"
        echo "        If it equals fire 1, the input was FOLDED at compile time and"
        echo "        fire 1 proved nothing. If empty, the refire never happened."
        fail=1
    fi
    if [ "$dg" = "0" ]; then echo "  ok    $label degrade count 0 (no silent emit-time fallback)"
    else echo "  FAIL  $label degrade count = '$dg', want 0 -- a construct fell through"; fail=1; fi
}

#  ============================================================================
#  THE RUNG PLAN. Each rung is the previous PLUS ONE construct.
#
#    J1  assign + arithmetic                          <- GREEN
#    J2  + if/else, both arms                       <- GREEN  (the else-arm
#        fix's permanent home; the two fires take DIFFERENT ARMS)
#    J3  + while                       (testWhilE's honest retest, in the ladder)
#    J4  + do                          (body-runs-once-when-false asserted)
#    J5  + multi-statement operand reuse  (O5/the clobber question gets a
#                                          FIXTURE instead of an inference)
#    ... string +=, compare chains, bare return, break/continue in loops --
#        each ratified ruling eventually earns a rung pinning it in COMPILED form
#
#    J-R RECURSION -- THE FRAME MODEL'S DEFINITION OF DONE, the way J1 was the
#        result slot's. Tony's named refinement of the POP goal, 2026-07-31.
#        Recorded now, built later.
#
#        THE RUNG: a recursive action, factorial-shaped -- one local, one
#        argument, a self-call, a base case -- compiled ONCE and fired at TWO
#        DEPTHS, correct at both.
#
#        ⚠ TWO DEPTHS IS THE DISCRIMINATOR, and it is the same trick as J1's
#        two fires. DEPTH-1 PASSES ON ALIASED SLOTS; DEPTH-N CANNOT. A rung that
#        only ran the base case would go green on exactly the machinery it
#        exists to test, which is how a fixture certifies nothing while looking
#        certain.
#
#        WHY IT CANNOT BE BUILT ON THE CURRENT MODEL: J1..J5 run on BAKED
#        ABSOLUTE ADDRESSES -- a field's slot IS its own storage, one address
#        per field. A recursive action's locals would therefore ALL ALIAS ONE
#        LOCATION, every call depth sharing the same slots, each recursion
#        clobbering its caller. That is not a bug in the model; it is the
#        boundary the phased O4 ruling drew ON PURPOSE.
#
#        SEQUENCED AFTER THE LOOP RUNGS: frames build on the calling convention;
#        loops do not need it.
#
#        ⚠ NAMED PREREQUISITE, honestly: THERE IS NO jitEmitCall (docs/jit.md
#        S1), and the seam is the same isMethod branch the unary seed bug lives
#        on. A SELF-CALL IS A CALL. So J-R's own ladder is:
#              call emission  ->  frames  ->  recursion as proof.
#
#        THE UNDECLARED-SLOT WORRY IS ANSWERED BY SCHEMA CLOSURE, by
#        construction: every field an action references is enumerated into the
#        frame schema at parse time, so a field appearing at RUNTIME that the
#        schema never saw HAS NOWHERE TO LAND -- and must fail LOUDLY (degrade
#        doctrine), NEVER silently alias into someone else's slot. Aliasing is
#        the failure mode this whole rung exists to make impossible.
#
#        WHAT GOES GREEN WITH IT, and it is why this is one fixture rather than
#        four: J-R certifies recursion, certifies the FRAME MODEL, closes
#        CLAIM KANT-8's whole class (returning a local from a recursive action
#        emptied it via restoreLocalFields -- the interpreter failing at exactly
#        this), and executes S0 Consequence 1's death warrant on saveLocalFields
#        (DELETED, not repaired). Tony's worry list and the architecture's
#        to-do list turn out to be the same list.
#  ============================================================================

#  irshape <fixture> <label> <block>...  -- assert the emitter produced these
#  basic blocks. NOT an IR diff (H3): field slots are baked ABSOLUTE ADDRESSES,
#  so a byte-exact target would move every run for reasons unrelated to
#  correctness. Uses DUMP=2 -- the EMITTER'S own output -- because the question
#  is what the emitter built, not what the optimiser left.
irshape () {
    f=$1; label=$2; shift 2
    INCANT_JIT_DUMP=2 $B "incant/$f" > "$T/$f.ir" 2>&1
    for blk in "$@"; do
        if grep -q "^$blk:" "$T/$f.ir"; then echo "  ok    $label block $blk:"
        else echo "  FAIL  $label block $blk: MISSING from emitter output"; fail=1; fi
    done
}

echo "-- J1  assign + arithmetic + tail value"
rung jitJ1 "J1 SENTINEL" "J1" 15 35

echo "-- J2  + if/else -- the two fires take DIFFERENT ARMS"
#  Stronger than J1's criterion. J1's two fires proved the OPERANDS were read at
#  run time; J2's prove the BRANCH is decided at run time. One compiled function,
#  two paths, nothing between the fires but an assignment to the input -- a
#  folded condition would send both fires down the same arm.
rung jitJ2 "J2 SENTINEL" "J2" 20 7
irshape jitJ2 "J2" entry then else endif
if grep -q "br i1 %cmp, label %then, label %else" "$T/jitJ2.ir"; then
    echo "  ok    J2 condition branches to then/else (a real two-way branch)"
else
    echo "  FAIL  J2 no two-way CondBr in emitter output -- branch not gated"; fail=1
fi

echo ""
if [ $fail = 0 ]; then echo "jitLADDER PASSED (rungs: J1 J2)"
else echo "jitLADDER FAILED"; fi
rm -rf "$T"
exit $fail
