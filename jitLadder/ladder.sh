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

echo "-- JP  THE TABLE-ARC PROBE: shared dispatch, FORKED LEAVES (T1)"
#  opPlusEQ's `if jitting` gate used to sit at the TOP of the function and
#  re-decide the type question its own switch already answers from carried datA.
#  Two decisions, one fact, and they can disagree -- which is precisely why
#  jit.md S3.5 lists seven ops assuming a numeric target. Now ONE dispatch tree
#  with each LEAF forking do-vs-emit: a forked leaf cannot disagree with itself.
rung jitJP "JP SENTINEL" "JP" 105 125

echo "-- JPd THE DEGRADE CITIZEN -- the rung that expects a NON-ZERO count"
#  ⚠⚠ THIS RUNG INVERTS EVERY OTHER ONE, AND THAT IS ITS WHOLE VALUE.
#  jitDegrade had ZERO call sites after the iterator rework, so every
#  `degrade count = 0` above was VACUOUS -- true, but nothing could move it.
#  T1's forked leaves gave it real citizens: a Buffer target has no emitter, so
#  `+=` on one degrades LOUDLY and runs interpreted. Asserting that it DOES fire
#  is what makes the zeros elsewhere load-bearing rather than decorative.
#  H4-shaped: this is presence-with-value, not absence-of-message.
$B incant/jitJPd > "$T/jpd" 2>&1
check "JPd runs" 0 $?
sentinel "JPd sentinel (no truncation)" "$T/jpd" "JPD SENTINEL"
if grep -q "JIT DEGRADE #1: += on a Buffer target" "$T/jpd"; then
    echo "  ok    JPd degrade FIRED and was counted (the zeros above are falsifiable)"; green=$((green+1))
else
    echo "  FAIL  JPd no degrade -- the arms stopped firing, and every"
    echo "        'degrade count = 0' in this file is unfalsifiable again"; fail=1
fi

#  JPl -- A DIFFERENT ARM, and the reason it is a separate check. JPd covers a
#  leaf INSIDE the switch; JPl covers one of the arms ABOVE it (the 35a
#  list-concat). Those were silent until the exhaustiveness pass: they have no
#  emitter and under jitting they EXECUTE AT EMIT TIME, so the side effect
#  happens once at compile time while the compiled code does nothing.
#  ⚠ A PARTIAL GUARANTEE IS NOT ONE. With any arm left silent, "no degrade fired"
#  means "covered OR silently fell through" -- exactly the ambiguity T1 removes.
#  Two checks because two arm KINDS; one passing would not imply the other.
$B incant/jitJPl > "$T/jpl" 2>&1
check "JPl runs" 0 $?
sentinel "JPl sentinel (no truncation)" "$T/jpl" "JPL SENTINEL"
if grep -q "JIT DEGRADE #1: += list-concat into a string target" "$T/jpl"; then
    echo "  ok    JPl the arms ABOVE the switch degrade too (coverage is exhaustive)"; green=$((green+1))
else
    echo "  FAIL  JPl an above-the-switch arm fell through SILENTLY"; fail=1
fi

echo "-- J-R  RECURSION. THE FRAME MODEL'S DEFINITION OF DONE."
#  ⚠ THIS IS THE PROOF jitJF SAID IT WAS NOT. Increment 1 could only assert
#  structure, because without recursion allocas-for-locals is behaviour-neutral.
#  Per-call storage becomes observable only when two activations are live at once.
#
#  JR -- factorial through an EMITTED SELF-CALL. Non-recursive calls inline (ruled:
#  inlining is the calling convention); a self-call cannot, so this is the arm that
#  needs a real `call`. Fire 2 changes the DEPTH, 3 -> 4, and 6 vs 24 are different
#  answers, not merely different inputs.
rung jitJR "JR SENTINEL" "JR" 6 24
INCANT_JIT_DUMP=2 $B incant/jitJR > "$T/jitJR.ir" 2>&1
if grep -q "call i32 @jitFn" "$T/jitJR.ir"; then
    echo "  ok    JR the recursive call is EMITTED (not inlined)"
else
    echo "  FAIL  JR no self-call in the IR -- it inlined, or did not emit"; fail=1
fi

#  ⚠⚠ JRL IS THE DISCRIMINATOR, and it is the whole phase boundary in one number.
#  jrLoc is a LOCAL read AFTER the recursive call returns, so it must be
#  per-activation. depth 3: per-activation 5, aliased 4. depth 4: 9 vs 6.
#  DEPTH-1 PASSES ON ALIASED SLOTS AND DEPTH-N CANNOT -- that is why both depths
#  are asserted and why the two answers must differ.
rung jitJRL "JRL SENTINEL" "JRL" 5 9
INCANT_JIT_DUMP=2 $B incant/jitJRL > "$T/jitJRL.ir" 2>&1
if grep -q "%jrLoc = alloca" "$T/jitJRL.ir"; then
    echo "  ok    JRL the surviving local has a FRAME SLOT (per-activation storage)"
else
    echo "  FAIL  JRL no alloca for the local -- it is not framed"; fail=1
fi

#  ============================================================================
#  JU -- THE UNARY FAMILY (++ and --), in place on data nodes. 2026-08-03.
#
#  Until today this rung could not exist: all three unary POPs exited 139 inside
#  jitEmitUnary on a null target->jitData. runOP's seed gate read
#  `if jitting && op.isOperator`, but unary operators are registered
#  `unary ruleMethod=` -- isUnary and isMethod, NOT isOperator -- so dispatch
#  took the isMethod arm and no operand was ever seeded. The gate now reads
#  `(op.isOperator || op.isUnary)`; isUnary is the precise gate, where widening
#  to isMethod would seed an operand for every rule method in the language.
#
#  11/31 from `juOut = juIn; ++juOut; ++juOut; --juOut;` -- two increments and
#  one decrement so that ++ and -- cannot BOTH fail and still land right.
#  10/30 = both no-oped · 12/32 = `--` no-oped · 9/29 = `++` no-oped.
rung jitJU "JU SENTINEL" "JU" 11 31
INCANT_JIT_DUMP=2 $B incant/jitJU > "$T/jitJU.ir" 2>&1
if grep -q "add i32" "$T/jitJU.ir" && grep -q "sub i32" "$T/jitJU.ir"; then
    echo "  ok    JU ++ and -- are both EMITTED (add i32 / sub i32 in the IR)"
else
    echo "  FAIL  JU the unary ops are not in the IR -- emitted nothing, or degraded"; fail=1
fi

#  JUi -- THE ITERATOR RUNG. ⚠ NO LONGER A PINNED DIVERGENCE: as of 2026-08-04
#  THIS IS A PARITY CHECK, and it is the one that closed the last named
#  exclusion on the JIT v0.1 claim.
#
#  WHAT IT PROVES: a jitted iterator walk visits THE SAME CHILDREN the
#  interpreter visits. Both halves are asserted at 3 over a three-child trunk,
#  and they are asserted SEPARATELY rather than as "jitted == interpreted" --
#  an equality check goes green when BOTH engines break the same way, which is
#  not an unlikely failure here since the emitted code calls the interpreter's
#  own arm. Two independent numbers against a value chosen by ruling.
#
#  THE HISTORY, kept because the shape of the defect is instructive: opPlusPlus
#  tested `isIterator` BEFORE its jitting gate, so an iterator under ++ returned
#  from the interpreted arm and NEVER REACHED THE GATE. It emitted nothing, the
#  walk happened once at EMIT time, and the compiled function contained no loop
#  -- 0 visits at run time against the interpreter's 3. Tony ruled 2026-08-04
#  that the interpreter is right and the JIT is the defect; the gate moved
#  INSIDE the iterator arm and the emitted code now calls opPlusPlus itself, so
#  the two cannot drift.
#
#  ⚠ BOTH HALVES RE-PINNED 2026-08-04, AND HERE ARE THE TWO SENTENCES.
#
#  interpreted 2 -> 3. The old pin was pinning a LEAF-DROPPING WALK. Tony's
#  iterator rework landed offline (aCTionIterate sets hasAttributes/hasMembers
#  instead of overloading the iterator's own affiliation; opPlusPlus reads the
#  same two flags). NOT signed on the diff -- signed on `incant/juiProbe`, which
#  NAMES the leaves instead of counting them: an unqualified iterate over a
#  3-child trunk visits jpA, jpB and jpC, each reporting isAttribute 1; the
#  attributes-qualified walk visits the same 3 and the members-qualified walk
#  visits 0. So 3 is every declared child, by name, and the old 2 was one short.
#  The rung's own prior comment had already flagged `2` for a three-member trunk
#  as suspect.
#
#  jitted 0 -> 3. Tony's ruling: the interpreter's measured behaviour IS the
#  intended semantics, so the JIT was the defect and was fixed rather than
#  pinned. The gate moved inside opPlusPlus's iterator arm; jitEmitIterStep
#  emits a call to opPlusPlus and branches on a null test of what it returns, so
#  the LOOP runs at run time. Verified: jitted 3, interpreted 3, same run.
#
#  ⚠ WITH THIS THE JIT PARITY CLAIM CARRIES NO ITERATOR ASTERISK. The excluded
#  list on CLAIM JIT-0.1 loses its first entry; IR persistence and inlining
#  remain.
$B incant/jitJUi > "$T/jitJUi" 2>&1
juie=$?
if [ $juie != 0 ]; then echo "  FAIL  JUi -- nonzero exit ($juie)"; fail=1
elif ! grep -qF "JUi SENTINEL" "$T/jitJUi"; then
    echo "  FAIL  JUi -- TRUNCATED at exit 0; nothing in this run is interpretable"; fail=1
else
    jj=$(sed -n 's/.*JUi jitted  *: juiCount = \([0-9-][0-9]*\).*/\1/p' "$T/jitJUi" | head -1)
    ji=$(sed -n 's/.*JUi interpreted *: juiCount = \([0-9-][0-9]*\).*/\1/p' "$T/jitJUi" | head -1)
    #  H4: both quantities are printed and COMPARED BY VALUE. Neither check can
    #  pass by a line going missing -- an empty capture fails the numeric test.
    if [ "$jj" = "3" ]; then echo "  ok    JUi jitted = 3       (the jitted walk visits every child)"
    else echo "  FAIL  JUi jitted = '$jj', want 3 -- the jitted iterator regressed"; fail=1; fi
    if [ "$ji" = "3" ]; then echo "  ok    JUi interpreted = 3  (interpretive arm taken; every child visited)"
    else echo "  FAIL  JUi interpreted = '$ji', pinned 3 -- the iterator walk itself moved"; fail=1; fi
fi

#  ---------------------------------------------------------------------------
#  JA -- THE ATTRIBUTE-METHOD RUNG. Clay SEQ 27 v2, 2026-08-04.
#
#  WHAT IT NEWLY PROVES, and it is a LIFECYCLE claim rather than a construct
#  claim -- the first rung on this ladder that is: a field's method COMPILES
#  ONCE, ON FIRST FIRE; the compiled function is stashed in a slot on the
#  field's own shape struct (rStuff.jitMethod); the emitted IR is stashed in a
#  `JiT` attribute beside CodE and BlocK; and every later fire DISPATCHES
#  THROUGH THE SLOT. Every rung above proves the JIT can compile a construct.
#  This one proves the compiled artifact PERSISTS ON THE FIELD and is reused.
#
#  THE CENTRAL QUANTITY IS THE COMPILE COUNT, and it is asserted at exactly 1
#  across THREE fires. Presence-with-value (H4): jitCompile is printed with its
#  number on every fire, so this cannot pass because a "compiling" line went
#  missing -- which is precisely how an absence-shaped version of this check
#  would eventually go green.
#
#  Criterion (a) is met by fires 2 and 3: applyScale is moved from 1 to 2 AFTER
#  emission and layoutTotal goes 25 -> 75 -> 125. A folded constant repeats 25.
#  INJECTIVITY holds -- all three answers differ.
#  Criterion (b): degrade 0 is asserted on EVERY fire, not just the compiling
#  one; the slot path prints it too, so the assertion has a line to read.
#
#  It also pins R2's method contract (idempotent check-bake-apply): bgSpec is
#  moved 5 -> 9 after the bake, and bgBaked must NOT follow it. That makes a
#  re-bake visible as a wrong value rather than merely absent.
#
#  ⚠ NO ITERATOR IN THIS FIXTURE, deliberately -- see rung JUi. Until the jitted
#  iterator walk is fixed, an iterator here would make a wrong count ambiguous
#  between this claim and that one.
echo "-- JA  ATTRIBUTE METHOD. COMPILE ONCE, DISPATCH THROUGH THE SLOT FOREVER."
$B incant/jitAttrPop > "$T/jitAttrPop" 2>&1
jae=$?
if [ $jae != 0 ]; then echo "  FAIL  JA -- nonzero exit ($jae)"; fail=1
elif ! grep -qF "AP SENTINEL" "$T/jitAttrPop"; then
    echo "  FAIL  JA -- TRUNCATED at exit 0; nothing in this run is interpretable"; fail=1
else
    ja1=$(sed -n 's/.*AP fire 1 : layoutTotal = \([0-9-][0-9]*\).*/\1/p' "$T/jitAttrPop" | head -1)
    ja2=$(sed -n 's/.*AP fire 2 : layoutTotal = \([0-9-][0-9]*\).*/\1/p' "$T/jitAttrPop" | head -1)
    ja3=$(sed -n 's/.*AP fire 3 : layoutTotal = \([0-9-][0-9]*\).*/\1/p' "$T/jitAttrPop" | head -1)
    jab=$(sed -n 's/.*AP fire 2 : bgBaked = \([0-9-][0-9]*\).*/\1/p' "$T/jitAttrPop" | head -1)
    jas=$(sed -n 's/.*AP fire 2 : bgSpec = \([0-9-][0-9]*\).*/\1/p' "$T/jitAttrPop" | head -1)
    #  THE COMPILE COUNT: take the LAST one printed. It is printed on every fire,
    #  so the last line is the count after all three -- which is the quantity the
    #  claim is about. Taking the first would read only the compiling fire and
    #  would pass no matter what fires 2 and 3 did.
    jac=$(sed -n 's/.*jitCompile count = \([0-9-][0-9]*\).*/\1/p' "$T/jitAttrPop" | tail -1)
    #  Degrade: take the MAXIMUM seen, so one bad fire cannot hide behind a good
    #  last line. The counter is monotonic, so the last value IS the maximum --
    #  taking it by tail is correct and says so.
    jad=$(sed -n 's/.*jitDegrade count = \([0-9-][0-9]*\).*/\1/p' "$T/jitAttrPop" | tail -1)
    #  ⚠ ANCHORED TO THE EMITTED LINE, not to the phrase. The first cut grepped
    #  "THROUGH THE SLOT" and counted 3 for 2 dispatches, because the FIXTURE'S
    #  OWN BANNER contains the phrase. A check that can match prose is asserting
    #  on the commentary rather than on the mechanism -- it would also have gone
    #  green if the banner stayed and the dispatch stopped.
    jaslots=$(grep -c "=== jitFieldMethod: bgColor THROUGH THE SLOT" "$T/jitAttrPop")
    jafirst=$(grep -c "=== jitFieldMethod: bgColor FIRST FIRE" "$T/jitAttrPop")
    jajit=$(sed -n 's/.*  JiT  noPrint=1  \([0-9][0-9]*\) bytes.*/\1/p' "$T/jitAttrPop" | head -1)
    jacode=$(grep -c "  CodE  noPrint=1" "$T/jitAttrPop")
    jablock=$(grep -c "  BlocK  noPrint=1" "$T/jitAttrPop")

    if [ "$jac" = "1" ]; then echo "  ok    JA compile count = 1 across THREE fires  <- THE CLAIM"
    else echo "  FAIL  JA compile count = '$jac', want 1 -- the slot is not being taken"; fail=1; fi
    if [ "$jafirst" = "1" ]; then echo "  ok    JA exactly ONE 'FIRST FIRE' (compile happened once)"
    else echo "  FAIL  JA 'FIRST FIRE' seen $jafirst times, want 1"; fail=1; fi
    if [ "$jaslots" = "2" ]; then echo "  ok    JA fires 2 and 3 both dispatched THROUGH THE SLOT"
    else echo "  FAIL  JA slot dispatches = $jaslots, want 2"; fail=1; fi
    if [ "$ja1" = "25" ]; then echo "  ok    JA fire 1 : layoutTotal = 25"
    else echo "  FAIL  JA fire 1 layoutTotal = '$ja1', want 25"; fail=1; fi
    if [ "$ja2" = "75" ]; then echo "  ok    JA fire 2 : layoutTotal = 75  <- RUN-TIME PROOF (applyScale moved after emission)"
    else echo "  FAIL  JA fire 2 layoutTotal = '$ja2', want 75 -- operands folded at compile time?"; fail=1; fi
    if [ "$ja3" = "125" ]; then echo "  ok    JA fire 3 : layoutTotal = 125 (the slot is a path, not a one-off)"
    else echo "  FAIL  JA fire 3 layoutTotal = '$ja3', want 125"; fail=1; fi
    if [ "$jas" = "9" ] && [ "$jab" = "25" ]; then
        echo "  ok    JA bake is IDEMPOTENT: bgSpec moved 5->9, bgBaked stayed 25 (R2 contract)"
    else echo "  FAIL  JA idempotence: bgSpec='$jas' (want 9) bgBaked='$jab' (want 25) -- it re-baked"; fail=1; fi
    if [ "$jad" = "0" ]; then echo "  ok    JA degrade count 0 on every fire (no silent emit-time fallback)"
    else echo "  FAIL  JA degrade count = '$jad', want 0"; fail=1; fi
    #  CORESIDENCE, and the vacuity guard is the byte count: "JiT is present" can
    #  pass on an empty artifact, "JiT holds N bytes with N > 0" cannot.
    if [ -n "$jajit" ] && [ "$jajit" -gt 0 ] 2>/dev/null; then
        echo "  ok    JA JiT attribute present and NON-EMPTY ($jajit bytes of IR)"
    else echo "  FAIL  JA JiT attribute missing or empty (read '$jajit')"; fail=1; fi
    if [ "$jacode" = "1" ] && [ "$jablock" = "1" ]; then
        echo "  ok    JA CodE + BlocK + JiT all CORESIDENT on the one node"
    else echo "  FAIL  JA coresidence: CodE=$jacode BlocK=$jablock, want 1 and 1"; fail=1; fi
fi

#  ---------------------------------------------------------------------------
#  JI -- SEQUENTIAL RE-TARGETED ITERATES, and the iterator SETUP at run time.
#
#  WHAT IT NEWLY PROVES: the `iterate` STATEMENT is emitted, so each loop
#  re-establishes its own source at RUN time. Every rung above proves the JIT
#  can compile an expression or a control structure; this one proves a
#  STATEMENT WITH A BINDING EFFECT happens at the right TIME.
#
#  ⚠ ITS FIRST FIXTURE DID NOT DISCRIMINATE, and that is why this one looks the
#  way it does. The first attempt fired ONE jitted iterate three times and
#  asserted 3/3/3 -- which passed IDENTICALLY with the emitted setup and with it
#  removed, because an exhausted iterator restarts from firstInList so a second
#  fire walks the same list again either way. Green, and evidence of nothing.
#  The discriminating shape is displayForm's own: ONE variable, TWO iterates,
#  RE-TARGETED between them, with DIFFERENT counts on the two sides.
#
#  THE TWO-POINT MEASUREMENT that licenses this rung (2026-08-04):
#      gate REMOVED, rebuilt:  jitted attrs=3 members=3   oracle 2/3   WRONG
#      gate PRESENT, rebuilt:  jitted attrs=2 members=3   oracle 2/3   right
#  The wrong answer was SILENT -- degrade count 0 in both runs -- so nothing
#  except a value assertion over a discriminating shape would have caught it.
#
#  ⚠ THE `kept` ROW GRADUATED 2026-08-05, 0 -> 2, AND HERE IS THE SENTENCE.
#  It was pinned WRONG on purpose while `continue` was built-but-uncertified.
#  The third loop is displayForm's own `if noPrinT; continue;`, and it took TWO
#  fixes, each visible in the IR before and after:
#    1. THE CONDITION WAS READING NOTHING. A bare flag read had no emitter, so
#       the `if` reused the last value in flight -- the iterator's liveness:
#           body:  %tobool = icmp ne i32 %iterCond, 0
#       opDot's new gate emits the accessor call instead:
#           %dotRes = call opDot(...) ; %dotVal = call jitUnboxCount(%dotRes)
#           %tobool = icmp ne i32 %dotVal, 0
#    2. THE STATEMENT AFTER THE `if` WAS NEVER EMITTED. aCTionBlocK breaks its
#       walk on isBranch -- interpreter control flow, which under jitting was
#       terminating THE COMPILER'S WALK. At run time a branch means stop; at
#       EMIT time the statements after it are REACHABLE and must all be emitted.
#       The branch is already in the IR as jitEmitContinue's terminator.
#  So this row now certifies `continue` AND the bare-flag read, at parity with
#  the interpreter, on both fires, at degrade 0.
echo "-- JI  SEQUENTIAL RE-TARGETED ITERATES. THE SETUP HAPPENS AT RUN TIME."
$B incant/jitIterTwice > "$T/jitIterTwice" 2>&1
jie=$?
if [ $jie != 0 ]; then echo "  FAIL  JI -- nonzero exit ($jie)"; fail=1
elif ! grep -qF "IT SENTINEL" "$T/jitIterTwice"; then
    echo "  FAIL  JI -- TRUNCATED at exit 0; nothing in this run is interpretable"; fail=1
else
    a1=$(sed -n 's/.*IT fire 1 : attrs = \([0-9-][0-9]*\).*/\1/p' "$T/jitIterTwice" | head -1)
    b1=$(sed -n 's/.*IT fire 1 : attrs = [0-9-]*  *members = \([0-9-][0-9]*\).*/\1/p' "$T/jitIterTwice" | head -1)
    a2=$(sed -n 's/.*IT fire 2 : attrs = \([0-9-][0-9]*\).*/\1/p' "$T/jitIterTwice" | head -1)
    b2=$(sed -n 's/.*IT fire 2 : attrs = [0-9-]*  *members = \([0-9-][0-9]*\).*/\1/p' "$T/jitIterTwice" | head -1)
    kj=$(sed -n 's/.*IT fire 1 : .*kept = \([0-9-][0-9]*\).*/\1/p' "$T/jitIterTwice" | head -1)
    ki=$(sed -n 's/.*IT interpreted : .*kept = \([0-9-][0-9]*\).*/\1/p' "$T/jitIterTwice" | head -1)
    oa=$(sed -n 's/.*IT interpreted : attrs = \([0-9-][0-9]*\).*/\1/p' "$T/jitIterTwice" | head -1)
    ob=$(sed -n 's/.*IT interpreted : attrs = [0-9-]*  *members = \([0-9-][0-9]*\).*/\1/p' "$T/jitIterTwice" | head -1)
    jid=$(sed -n 's/.*jitDegrade count = \([0-9-][0-9]*\).*/\1/p' "$T/jitIterTwice" | tail -1)
    jic=$(sed -n 's/.*jitCompile count = \([0-9-][0-9]*\).*/\1/p' "$T/jitIterTwice" | tail -1)

    if [ "$a1" = "2" ] && [ "$b1" = "3" ]; then
        echo "  ok    JI fire 1 : attrs 2, members 3  (the two iterates target DIFFERENTLY)"
    else echo "  FAIL  JI fire 1 attrs='$a1' members='$b1', want 2 and 3."
         echo "        attrs=3 means BOTH loops ran against the binding emit time left"
         echo "        behind -- i.e. the iterate setup is not being emitted."; fail=1; fi
    if [ "$a2" = "2" ] && [ "$b2" = "3" ]; then
        echo "  ok    JI fire 2 : attrs 2, members 3  <- RUN-TIME PROOF (no recompile)"
    else echo "  FAIL  JI fire 2 attrs='$a2' members='$b2', want 2 and 3"; fail=1; fi
    if [ "$oa" = "2" ] && [ "$ob" = "3" ]; then
        echo "  ok    JI oracle agrees: interpreted attrs 2, members 3"
    else echo "  FAIL  JI ORACLE DISAGREES: interpreted '$oa'/'$ob', jitted 2/3"; fail=1; fi
    if [ "$jic" = "1" ]; then echo "  ok    JI compile count 1 across both fires"
    else echo "  FAIL  JI compile count = '$jic', want 1"; fail=1; fi
    if [ "$jid" = "0" ]; then echo "  ok    JI degrade count 0 (no silent emit-time fallback)"
    else echo "  FAIL  JI degrade count = '$jid', want 0"; fail=1; fi
    if [ "$kj" = "2" ]; then echo "  ok    JI kept jitted = 2   (continue + bare flag read, PARITY)"
    else echo "  FAIL  JI kept jitted = '$kj', want 2 -- continue or the bare flag read regressed"; fail=1; fi
    if [ "$ki" = "2" ]; then echo "  ok    JI kept interpreted = 2  (continue is CONSUMED correctly, interpreted)"
    else echo "  FAIL  JI kept interpreted = '$ki', pinned 2 -- the interpreted continue moved"; fail=1; fi
fi

echo ""
if [ $fail = 0 ]; then echo "jitLADDER PASSED (rungs: J1 J2 J3 J4 J5 J6 J7 JE JF JP JPd JU JA JI + J-R THE PROOF)"
else echo "jitLADDER FAILED"; fi
rm -rf "$T"
exit $fail
