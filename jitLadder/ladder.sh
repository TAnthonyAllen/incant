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
#  RUNG STYLE, adopted 2026-07-31:
#    - EACH RUNG NAMES ITS CLAIM, and the claims are not interchangeable:
#         J1  the OPERANDS are read at run time
#         J2  the BRANCH is decided at run time
#         J3  the loop RUNS THE RIGHT NUMBER OF TIMES at run time
#      A rung that cannot say what it newly proves is a rung that adds coverage
#      without adding confidence.
#    - ⚠ INJECTIVITY: IT IS NOT ENOUGH FOR THE TWO INPUTS TO DIFFER -- THE TWO
#      ANSWERS MUST DIFFER. Choose inputs the operation cannot collapse. 17 % 3
#      and 20 % 3 are BOTH 2, so that pair would pass on a folded constant and
#      prove nothing.
#      ⚠ RUNGS J1-J6 SATISFIED THIS BY LUCK, not by design -- their operations
#      happened to be injective over the inputs used. The fire-twice criterion
#      carried this assumption silently from the day it was written; J7 is where
#      it surfaced, and it is now explicit.
#    - CHOOSE EXPECTED VALUES SO THE WRONG ANSWERS ARE DIAGNOSTIC. J2's are the
#      model: 20/7 correct, 20/20 the condition was folded, 20/0 the pre-fix
#      else-arm bug. The rung does not merely fail -- IT NAMES ITS FAILURE MODE
#      FROM THE VALUE ALONE, before anyone opens a dump.
#
#  ⚠ THE LADDER'S PROOF-OF-THESIS, and it happened inside one session:
#  J5's dump showed a REDUNDANT COMMITTER (three stores to the result slot for a
#  two-statement body), so the explicit commit was removed from jitEmitWHILE --
#  correctly -- and, ON THE SAME REASONING, from its sibling jitEmitDO. That was
#  WRONG: a do body is committed by nobody, so J4 immediately emitted no result
#  at all. The sibling had a fixture and it went red in the same commit that
#  introduced the defect.
#  A ONE-RUNG LADDER WOULD HAVE SHIPPED IT.
#  That is the argument for rungs over one accreting action, stated as an event
#  rather than a principle.
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
    #  THE ORACLE'S TESTIMONY, captured while it can still testify. Not an
    #  assertion against a target -- a CAPTURED FACT recorded beside the
    #  asserted value, because section 0 sentences the interpreter to death and
    #  after crossover a wrong jitted answer can no longer be localised by
    #  differential bisection. Truth will come only from fixtures written in
    #  advance, so the ladder banks the oracle's answers now.
    #  It IS checked against fire 1 -- same action, same input, both paths.
    or=$(sed -n "s/.*interpreted  *: [a-zA-Z]* = \\([0-9-][0-9]*\\).*/\\1/p" "$T/$f" | head -1)
    if [ -z "$or" ]; then echo "  FAIL  $label oracle not recorded -- the rung must capture it"; fail=1
    elif [ "$or" = "$w1" ]; then echo "  ok    $label oracle agrees with fire 1 = $or  (interpreted == jitted)"
    else echo "  FAIL  $label ORACLE DISAGREES: interpreted $or vs jitted $w1"; fail=1; fi
}

#  ============================================================================
#  THE RUNG PLAN. Each rung is the previous PLUS ONE construct.
#
#    J1  assign + arithmetic                          <- GREEN
#    J2  + if/else, both arms                       <- GREEN  (the else-arm
#        fix's permanent home; the two fires take DIFFERENT ARMS)
#    J3  + while                                    <- GREEN  (testWhilE's
#        honest retest; trip-count-dependent, back edge asserted)
#    J4  + do                          (body-runs-once-when-false asserted)
#    J5  + multi-statement operand reuse            <- GREEN  (an ATTRIBUTION
#        rung: the clobber tested DIRECTLY and found not to bite)
#    J6  + an EMITTED CALL (jitTrace)              <- GREEN  (the first that
#        is not concatEQ; the print that survives jitting)
#    J7  + the FALLBACK COLUMN on a real opMethod  <- GREEN  (emit a call,
#        get a value back, layout-free both legs)
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

echo "-- J3  + while -- THE HONEST RETEST of testWhilE's ICmp abort"
#  testWhilE died at 134 (SIGABRT, ICmp operand type mismatch) from 2026-07-30,
#  and the recorded cause -- jitEmitCompare clobbering the target's SSA value --
#  was INFERRED and later WEAKENED when the IR showed re-seeding.
#  IT DOES NOT RECUR, and the reason is simpler than the clobber: aCTionWhilE
#  had NO jitting gate, so under jitting the loop EXECUTED at emit time and
#  walked its condition REPEATEDLY. With a gate the condition is emitted ONCE,
#  into `cond`, and the loop runs at RUN time. Trip-count-dependent by
#  construction: the two inputs land on DIFFERENT values.
rung jitJ3 "J3 SENTINEL" "J3" 0 -1
irshape jitJ3 "J3" entry cond body loopexit
if grep -q "^  br label %cond" "$T/jitJ3.ir"; then
    echo "  ok    J3 back edge present (body branches to cond -- it is a LOOP)"
else
    echo "  FAIL  J3 NO BACK EDGE -- emitted a guarded block, not a loop"; fail=1
fi

echo "-- J4  + do -- the body runs ONCE when the condition starts FALSE"
#  The ONLY thing distinguishing `do` from `while`, so a rung not testing it
#  would be re-testing J3. Fire 2's input makes the condition false at ENTRY:
#     -2  correct (do semantics, body ran once)
#      0  WHILE SEMANTICS -- the body was skipped, the branch was not moved
#  The topology difference is ONE BRANCH TARGET: a while's back edge goes to
#  cond, a do's goes to BODY -- which is what the CondBr check below asserts.
rung jitJ4 "J4 SENTINEL" "J4" 0 -2
irshape jitJ4 "J4" entry dobody docond doexit
if grep -q "label %dobody, label %doexit" "$T/jitJ4.ir"; then
    echo "  ok    J4 back edge targets BODY (do semantics, not while)"
else
    echo "  FAIL  J4 back edge does not target dobody -- this is a while, not a do"; fail=1
fi

echo "-- J5  + multi-statement body with OPERAND REUSE -- an ATTRIBUTION rung"
#  ⚠ THE FIRST RUNG WHOSE PURPOSE IS ATTRIBUTION RATHER THAN COVERAGE. It is the
#  direct test of jitDataClobber, INFERRED for a month and left UNIMPLICATED by
#  J3 (which removed its only alleged symptom without ever testing it).
#  jeN is compared in cond, read twice and written once in the body, every
#  iteration. If a node can hold only one SSA value and the compare's i1
#  clobbers it, this is where it shows.
#  IT DOES NOT. And the reading, from DUMP=2: jeN is loaded FOUR SEPARATE TIMES
#  in one iteration -- once per USE -- so the stored SSA value is never what a
#  later use reads, and the clobber cannot be observed.
rung jitJ5 "J5 SENTINEL" "J5" 10 15

echo "-- J6  + AN EMITTED CALL -- and the trace is its own evidence"
#  ⚠ THE FIRST EMITTED CALL THAT IS NOT THE LONELY concatEQ, and the mechanism
#  under four threads: the fallback column, jitTrace, J-R, the runtime surface.
#  `print` CANNOT do this job -- opPrint is UNGATED, so a print in a jitted body
#  fires at EMIT time and reports compile-time state ONCE, looking like it
#  worked. A trace appearing TWICE WITH DIFFERENT VALUES can only have been
#  called from compiled code on each fire.
rung jitJ6 "J6 SENTINEL" "J6" 8 22
#  Two jitted traces (one per fire) plus one from the interpreted oracle.
tr1=$(grep "JIT TRACE" "$T/jitJ6" | sed -n '1s/.*= \([0-9-][0-9]*\).*/\1/p')
tr2=$(grep "JIT TRACE" "$T/jitJ6" | sed -n '2s/.*= \([0-9-][0-9]*\).*/\1/p')
trn=$(grep -c "JIT TRACE" "$T/jitJ6")
if [ "$tr1" = "4" ] && [ "$tr2" = "11" ]; then
    echo "  ok    J6 trace fired PER FIRE with the live value ($tr1 then $tr2)"
elif [ "$tr1" = "$tr2" ]; then
    echo "  FAIL  J6 both traces read '$tr1' -- the argument was FOLDED, not loaded per fire"; fail=1
else
    echo "  FAIL  J6 traces read '$tr1'/'$tr2', want 4/11"; fail=1
fi
if [ "$trn" = "3" ]; then echo "  ok    J6 trace count 3 (2 jitted + 1 interpreted oracle)"
elif [ "$trn" = "1" ]; then
    echo "  FAIL  J6 ONE trace -- the call ran at EMIT time (the print disease)"; fail=1
else echo "  FAIL  J6 trace count '$trn', want 3"; fail=1; fi
if grep -q "call ptr inttoptr" "$T/jitJ6.ir" 2>/dev/null || \
   INCANT_JIT_DUMP=2 $B incant/jitJ6 2>&1 | grep -q "call ptr inttoptr"; then
    echo "  ok    J6 a CreateCall is in the emitted IR (ptr in, ptr out)"
else
    echo "  FAIL  J6 no emitted call in the IR"; fail=1
fi

echo "-- J7  + THE FALLBACK COLUMN meeting a REAL opMethod"
#  J6 called a purpose-built helper; J7 calls an EXISTING OPERATOR (opRem, one
#  of the 24 ungated ops) and UNBOXES ITS RETURN VALUE back into emitted code.
#  That is the complete calling story: emit a call, get a value back, LAYOUT-FREE
#  ON BOTH LEGS.
#  ⚠ THE INPUTS ARE CHOSEN SO THE ANSWERS DIFFER, not merely the inputs: 17 % 3
#  and 20 % 3 are BOTH 2, so that pair would pass with a folded constant. 19
#  lands on a different remainder. Added to rung style -- earlier rungs got this
#  for free because their operations were injective over the inputs used.
rung jitJ7 "J7 SENTINEL" "J7" 2 1
INCANT_JIT_DUMP=2 $B incant/jitJ7 > "$T/jitJ7.ir" 2>&1
if grep -q "call ptr inttoptr" "$T/jitJ7.ir" && grep -q "call i32 inttoptr" "$T/jitJ7.ir"; then
    echo "  ok    J7 BOTH legs emitted (call ptr -> opMethod, call i32 -> unbox)"
else
    echo "  FAIL  J7 the two-leg calling story is not in the IR"; fail=1
fi

echo "-- JE  `if` WITH NO ELSE ARM -- the shape no rung had"
#  J2 covers if/else. NOTHING covered a bare `if cond; body;`, and that gap hid a
#  dominance violation for as long as the emitter has existed: with no else arm to
#  overwrite it, gJitResult still held the THEN arm's value when the commit fired
#  inside elseBB. verifyFunction REFUSED the function, so it was never a wrong
#  answer -- it was a refusal to run, which is why no value target ever saw it.
#  Fire 2 FLIPS THE CONDITION, so it proves the branch is decided at run time AND
#  that an absent else leaves the result slot alone (7, not 0 and not 50).
rung jitJE "JE SENTINEL" "JE" 50 7
INCANT_JIT_DUMP=2 $B incant/jitJE > "$T/jitJE.ir" 2>&1
if grep -qE "INVALID IR|does not dominate" "$T/jitJE.ir"; then
    echo "  FAIL  JE emitted invalid IR (the absent-else dominance bug is back)"; fail=1
else
    echo "  ok    JE absent-else emits VALID IR (verifier silent)"
fi

echo "-- JF  THE FRAME MODEL, INCREMENT 1 -- STRUCTURE ONLY, NOT THE PROOF"
#  ⚠⚠ THIS RUNG DOES NOT CERTIFY THE FRAME MODEL AND MUST NOT BE READ AS DOING
#  SO. Without recursion, allocas-for-locals is BEHAVIOUR-NEUTRAL -- one
#  activation's alloca and one field's storage hold the same value at every
#  observable point, so the answers are identical either way. THE PROOF IS J-R:
#  factorial-shaped, fired at TWO DEPTHS, because depth-1 passes on aliased slots
#  and depth-N cannot. Until J-R exists, this rung asserts STRUCTURE plus the
#  value-regression net above.
#
#  ⚠ AND IT EXISTS BECAUSE THE NET COULD NOT SEE THE CHANGE. Every rung J1..J7
#  uses fields declared in a DEFINE BLOCK -- registry globals, not action locals
#  -- and Part III says globals KEEP their baked addresses. So the prologue
#  correctly did nothing for them, the ladder stayed 47/47 green across the whole
#  increment, and a structure claim read off that would have been VACUOUS.
#  Measured by dumping J1's IR: no frame alloca, both operands still inttoptr.
rung jitJF "JF SENTINEL" "JF" 115 135
INCANT_JIT_DUMP=2 $B incant/jitJF > "$T/jitJF.ir" 2>&1
#  THE DISCRIMINATOR IS BOTH HALVES IN ONE FUNCTION, and each half alone is
#  satisfiable by a wrong emitter: "an alloca exists" passes if the prologue
#  framed EVERYTHING; "a baked address exists" passes if it framed NOTHING.
if grep -q "%jfTmp = alloca i32" "$T/jitJF.ir"; then
    echo "  ok    JF local jfTmp got a FRAME SLOT (alloca)"
else
    echo "  FAIL  JF the local has no alloca -- the prologue did not fire"; fail=1
fi
if grep -q "store i32 %prolog, ptr %jfTmp" "$T/jitJF.ir"    && grep -q "%epilog = load i32, ptr %jfTmp" "$T/jitJF.ir"; then
    echo "  ok    JF prologue IN and epilogue OUT both emitted"
else
    echo "  FAIL  JF prologue/epilogue missing -- the frame is not carried"; fail=1
fi
if grep -q "store i32 %add, ptr %jfTmp" "$T/jitJF.ir"; then
    echo "  ok    JF the local's WRITE lands in the frame slot, not a baked address"
else
    echo "  FAIL  JF a local write still targets baked storage"; fail=1
fi
#  THE OTHER HALF: globals must be UNCHANGED. jfOut is declared in the define
#  block, so it is a registry global and Part III's phase scope says it keeps an
#  immediate store-through to its own address.
if grep -qE "store i32 %add2, ptr inttoptr" "$T/jitJF.ir"; then
    echo "  ok    JF global jfOut KEPT its baked address + immediate store-through"
else
    echo "  FAIL  JF a global was framed -- increment 1 must not touch globals"; fail=1
fi

echo ""
if [ $fail = 0 ]; then echo "jitLADDER PASSED (rungs: J1 J2 J3 J4 J5 J6 J7 JE + JF structure-only)"
else echo "jitLADDER FAILED"; fi
rm -rf "$T"
exit $fail
