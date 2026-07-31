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
#    J2  + if/else, both arms          (the else-arm fix gets a permanent home)
#    J3  + while                       (testWhilE's honest retest, in the ladder)
#    J4  + do                          (body-runs-once-when-false asserted)
#    J5  + multi-statement operand reuse  (O5/the clobber question gets a
#                                          FIXTURE instead of an inference)
#    ... string +=, compare chains, bare return, break/continue in loops --
#        each ratified ruling eventually earns a rung pinning it in COMPILED form
#
#    JR  RECURSION -- Tony's named refinement of the POP goal, 2026-07-31.
#        ⚠ AND IT IS THE RUNG THAT FORCES THE FRAME PHASE, which is why it is
#        listed here rather than left to the design docs.
#        J1..J5 all run on BAKED ABSOLUTE ADDRESSES: a field's slot is its own
#        storage, one address per field, and a write goes straight through.
#        That model CANNOT express recursion -- a recursive call's locals would
#        all alias the SAME address, so the inner call would overwrite the
#        outer's. Tony's worry, in his words, is "handling recursion by making
#        use of undeclared slots or however", and the sharp form of it is:
#        INCANT HAS NO DECLARATIONS, so where does a recursive frame's storage
#        come from? The answer is the frame model (docs/jitDesign.md Part III):
#        the action's FIELD LIST is the frame schema -- closed at parse time,
#        which is what makes per-call slot arrays possible without the
#        programmer declaring anything.
#        So the ladder WILL hit a wall, the wall has a name, and JR is where the
#        baked-address phase ends and the frame phase has to begin. Do not
#        schedule JR as "one more rung": it is a phase boundary wearing a rung's
#        clothes, and it should be planned as one.
#  ============================================================================

echo "-- J1  assign + arithmetic + tail value"
rung jitJ1 "J1 SENTINEL" "J1" 15 35

echo ""
if [ $fail = 0 ]; then echo "jitLADDER PASSED (rungs: J1)"
else echo "jitLADDER FAILED"; fi
rm -rf "$T"
exit $fail
