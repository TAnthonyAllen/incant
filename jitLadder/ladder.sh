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
green=0

#  ⚠⚠ THESE TWO HELPERS WERE CALLED AND NEVER DEFINED, 2026-08-01 -> 2026-08-05.
#  THIRD INSTANCE OF THIS DISEASE ON THIS PROJECT, and the first INSIDE the JIT
#  ladder: incant/jiquery's three stop() calls, then pop.sh's missing sentinel,
#  now this. The call sites at JPd and JPl (below) printed
#      jitLadder/ladder.sh: line 393: check: command not found
#  on EVERY run, to stderr, and the ladder CARRIED ON. Those four checks did not
#  pass and did not fail -- THEY CEASED TO EXIST. So for four days JPd and JPl
#  had NO exit-status check and NO truncation guard: each rested on a single
#  grep for its degrade message, and output printed before a crash is real, so a
#  CRASHING jitJPd would have reported green.
#  ⚠ THE LADDER'S OWN HEADLINE COUNT WAS THE CAMOUFLAGE. "103 ok, exit 0" reads
#  as an audit; it is a tally of the checks that RAN. A check that evaporates is
#  invisible in a count of checks -- which is why H2 says assert completeness by
#  NAME, and why the CLAUDE.md line "when a result surprises you, doubt the
#  instrument before the code" has to extend to results that DON'T surprise you.
check () {                      # check <name> <expected-exit> <actual-exit>
    if [ "$2" = "$3" ]; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 (exit $3)"; fail=1; fi
}

sentinel () {                   # sentinel <name> <file> <text>
    if grep -qF "$3" "$2"; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 -- THE RUN TRUNCATED. A row stopped parsing and every"
         echo "        row after it was silently dropped, at exit 0. Find the row"
         echo "        that stopped parsing, not the row that diffed."; fail=1; fi
}

#  ⚠⚠ RULE H5 REACHES THIS LADDER, 2026-08-05. genLadder/pop.sh has run every
#  fixture under a wall-clock cap since 2026-08-02; THIS FILE NEVER DID, and it
#  did not matter until rung JS -- whose regression mode is INFINITE RECURSION.
#  A fixture that never returns does not fail: it takes the summary line, the
#  exit status, and every check below it, and those checks do not pass and do not
#  fail, THEY CEASE TO EXIST. That is worse than a red, because the operator sees
#  a terminal that is merely quiet.
#
#  A TIMEOUT IS REPORTED BY NAME AND NEVER AS A DIFF: a killed process yields
#  truncated output, and a truncation diff names the wrong row. `timeout(1)` is
#  not on macOS, hence sleep-and-kill; 137 is the SIGKILL that produces. The
#  watchdog is reaped inside a brace group with stderr discarded, or the shell
#  announces `Terminated: 15` on every capped fixture -- an instrument that adds
#  its own chatter to the evidence is an instrument that will be misread.
JITCAP=${JITCAP:-90}
runcap () {                     # runcap <label> <fixture> <outfile> [env-prefix]
    if [ -n "$4" ]; then env "$4" $B "incant/$2" > "$3" 2>&1 & else $B "incant/$2" > "$3" 2>&1 & fi
    _p=$!
    { ( sleep "$JITCAP"; kill -9 $_p 2>/dev/null ) >/dev/null 2>&1 & } 2>/dev/null
    _w=$!
    wait $_p; _ec=$?
    { kill $_w 2>/dev/null; wait $_w 2>/dev/null; } 2>/dev/null
    if [ $_ec = 137 ]; then
        echo "  FAIL  $1 TIMED OUT after ${JITCAP}s -- KILLED, not failed."
        echo "        Its capture is TRUNCATED, so every assertion below it would"
        echo "        name the wrong row. For JS specifically, a hang IS the"
        echo "        pre-S3 defect: the driver's preamble is replaying."
        fail=1
        return 124
    fi
    return $_ec
}

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
if grep -q "call i32 @jit_" "$T/jitJR.ir"; then
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

#  ---------------------------------------------------------------------------
#  JPv -- THE JITTED PRINT CARRIES REAL VALUES.
#
#  WHAT IT NEWLY PROVES, and it is an EFFECT rather than a return value -- the
#  first rung whose subject is something the compiled function DOES rather than
#  what it hands back: a print emitted by the JIT fires at RUN time, once per
#  fire, with values read at run time.
#
#  THE THREE WORLDS IT SEPARATES, which is why both the line COUNT and the
#  VALUES are asserted:
#      emit-time print    ONE line, and nothing on the refire
#      run-time, folded   TWO lines, both the same
#      run-time, correct  TWO lines that track the input        <- the claim
#
#  TWO SHAPES, because they exercise different halves of the seam:
#    pAct   `print "P value =" pVal:;`  a MULTI-PART operand -- one constant
#           part and one computed part, classified by constancy (jitPrintList).
#           The constant goes to appendGroup's existing entry (immutable, so the
#           stale-frame disease cannot apply); the computed part is materialized
#           and goes through appendGroupValue.
#    pBare  `print pVal;`               a BARE operand -- the primitive alone.
#
#  ⚠ THE HISTORY IS THE REASON THE VALUES ARE ASSERTED AND NOT JUST THE COUNT.
#  This fixture printed `0` before the bare-read primitive existed, and 75102656
#  after -- a stale read wearing the shape of data, at degrade 0 both times. A
#  count-only check would have been green for the whole of that.
echo "-- JPv PRINT VALUES. THE JITTED PRINT FIRES AT RUN TIME, WITH REAL VALUES."
$B incant/jitPrintT > "$T/jitPrintT" 2>&1
jpe=$?
if [ $jpe != 0 ]; then echo "  FAIL  JPv -- nonzero exit ($jpe)"; fail=1
elif ! grep -qF "JP2 SENTINEL" "$T/jitPrintT"; then
    echo "  FAIL  JPv -- TRUNCATED at exit 0; nothing in this run is interpretable"; fail=1
else
    n7=$(grep -c "^P value = 7 *$" "$T/jitPrintT")
    n9=$(grep -c "^P value = 9 *$" "$T/jitPrintT")
    n41=$(grep -c "^41 " "$T/jitPrintT")
    n58=$(grep -c "^58 " "$T/jitPrintT")
    jpd=$(sed -n 's/.*jitDegrade count = \([0-9-][0-9]*\).*/\1/p' "$T/jitPrintT" | tail -1)
    if [ "$n7" = "1" ] && [ "$n9" = "1" ]; then
        echo "  ok    JPv multi-part: 'P value = 7' then 'P value = 9'  <- RUN-TIME PROOF"
    else echo "  FAIL  JPv multi-part: saw $n7 x '= 7' and $n9 x '= 9', want 1 and 1."
         echo "        Two identical lines = the operand was FOLDED at compile time."
         echo "        One line only = the print fired at EMIT time and not at run time."; fail=1; fi
    if [ "$n41" = "1" ] && [ "$n58" = "1" ]; then
        echo "  ok    JPv bare operand: 41 then 58 (the primitive alone)"
    else echo "  FAIL  JPv bare operand: saw $n41 x 41 and $n58 x 58, want 1 and 1"; fail=1; fi
    if [ "$jpd" = "0" ]; then echo "  ok    JPv degrade count 0 (nothing fell through, nothing refused)"
    else echo "  FAIL  JPv degrade count = '$jpd', want 0"; fail=1; fi
fi

echo ""
echo "-- JV VALUE PARITY on an EMPTY loop or branch."
#  aCTionDO / aCTionIF / aCTionWhilE all end `if !result result = falseResult;`
#  -- falseResult being a pROPERTIEs node, isCOUNT, value 0 -- and all three
#  return at their `if jitting` gate ABOVE that line. So whether the emitters
#  reproduce the convention was an open candidate, raised by the early-return
#  census and settled here by measurement: THEY DO.
#  Not shared state; VALUE parity. Cheap insurance taken before the genParse
#  conversions lean on conditionals wholesale, since every planned rule is
#  branches and loops and an action ending in an untaken arm is ordinary.
#  ⚠ ROW C IS THE ANTI-VACUITY LEG. A and B both want 0, which a result slot
#  that merely DEFAULTS to zero would also produce -- they cannot distinguish
#  "the convention was carried" from "nothing was written". C wants 4, so it
#  fails unless the slot holds a REAL computed value. Two zeros alone would be
#  an absence check wearing a value's clothes.
$B incant/jitFalseT > "$T/jv" 2>&1
check "JV runs" 0 $?
sentinel "JV sentinel (no truncation)" "$T/jv" "jitFalseT SENTINEL"
jva=$(sed -n 's/.*jitRunAction result = \([0-9-][0-9]*\).*/\1/p' "$T/jv" | sed -n 1p)
jvb=$(sed -n 's/.*jitRunAction result = \([0-9-][0-9]*\).*/\1/p' "$T/jv" | sed -n 2p)
jvc=$(sed -n 's/.*jitRunAction result = \([0-9-][0-9]*\).*/\1/p' "$T/jv" | sed -n 3p)
ova=$(sed -n 's/^A interpreted value = \([0-9-][0-9]*\).*/\1/p' "$T/jv" | head -1)
ovb=$(sed -n 's/^B interpreted value = \([0-9-][0-9]*\).*/\1/p' "$T/jv" | head -1)
ovc=$(sed -n 's/^C interpreted value = \([0-9-][0-9]*\).*/\1/p' "$T/jv" | head -1)
jvd=$(sed -n 's/.*jitDegrade count = \([0-9-][0-9]*\).*/\1/p' "$T/jv" | tail -1)
if [ -z "$jva" ] || [ -z "$ova" ]; then
    echo "  FAIL  JV VACUITY GUARD: a value was not captured at all (jitted='$jva' oracle='$ova')"; fail=1
else
    for row in "A:$jva:$ova:0" "B:$jvb:$ovb:0" "C:$jvc:$ovc:4"; do
        r=${row%%:*}; rest=${row#*:}; j=${rest%%:*}; rest=${rest#*:}; o=${rest%%:*}; w=${rest##*:}
        if [ "$j" = "$w" ] && [ "$o" = "$w" ]; then
            echo "  ok    JV $r jitted $j == oracle $o == $w"; green=$((green+1))
        else
            echo "  FAIL  JV $r jitted='$j' oracle='$o' want $w -- the engines disagree"
            echo "        about what an empty construct is WORTH. Silent by nature:"
            echo "        it is a value, not a crash, and degrade stays 0."; fail=1
        fi
    done
fi
if [ "$jvd" = "0" ]; then echo "  ok    JV degrade count 0"; green=$((green+1))
else echo "  FAIL  JV degrade count = '$jvd', want 0"; fail=1; fi

echo ""
echo "-- JC CONVERGENCE. THE JITTED WALK MATCHES THE ORACLE AT EVERY DEPTH."
#  ⚠ THE ONE CONSTRUCT NO OTHER RUNG TOUCHES: RECURSION OVER A SHARED ITERATOR
#  LOCAL. Every rung above passes per-activation state through SCALARS, and a
#  jitted scalar local is an ALLOCA in the compiled function -- per-activation
#  for free. That is why J-R and JRL were green while displayForm was wrong:
#  node-resident state (an iterator's CURSOR) lives in a baked GroupItem shared
#  by every activation, and had no mechanism at all until the frame bracket.
#
#  ⚠ H3: THIS RUNG ASSERTS A DIFF AGAINST THE ORACLE, NOT A GOLDEN FILE. There
#  is no .target: the two halves are produced by the SAME RUN, so the assertion
#  moves only when the two ENGINES disagree -- never for a reason unrelated to
#  correctness. It cannot be regenerated green.
#
#  ⚠ H7 NEGATIVE CONTROL, MEASURED 2026-08-05 rather than asserted. With the
#  frame bracket removed, this rung goes RED and the wrongness is legible:
#      bracket ABSENT:  dfRoot alpha beta dfMid [dfBare] dfInner     6 lines
#      bracket PRESENT: dfRoot alpha beta dfMid delta dfInner zeta dfBare  8
#  `dfBare` is dfRoot's MEMBER surfacing INSIDE dfMid -- the outer members
#  iterator's cursor, clobbered by the inner activation. Degrade count was 0 in
#  BOTH runs, so the wrong answer was SILENT. That is the rung's whole argument.
#
#  ⚠ VACUITY GUARD, H4's other half: both halves must be NON-EMPTY before they
#  are compared, or a run that emitted nothing at all would diff clean and pass.
$B incant/jitDfProbe > "$T/jc" 2>&1
check "JC runs" 0 $?
sentinel "JC sentinel (no truncation)" "$T/jc" "jitDfProbe SENTINEL"
#  ⚠ THE FILTER DROPS COMPILE NARRATION, NOT OUTPUT, AND THE CONVENTION IS THE
#  WHOLE OF ITS LICENCE. Every compile-time report the JIT driver emits has the
#  shape `=== jit<Name>: ... ===`; the WALK prints tree content and never does.
#  Widened 2026-08-05 from the single `jitRunAction: entering` to the family,
#  because S3 added three more (DISCOVERED / callee built / restart count) and
#  naming them one at a time is how a filter silently stops covering the next one.
#  ⚠ THE VACUITY GUARD BELOW IS WHAT MAKES A WIDER FILTER SAFE: if this ever ate
#  the walk itself, the half is EMPTY and the rung FAILS rather than diffing two
#  blanks clean. That is the anti-vacuity instinct doing real work, not decoration.
awk '/^== JITTED ==/{f=1;next} /^=== jitRunAction result/{f=0} f&&!/^=== jit[A-Za-z]*:/' "$T/jc" > "$T/jc.jit"
awk '/^== INTERPRETED/{f=1;next} /SENTINEL/{f=0} f' "$T/jc" > "$T/jc.int"
jcd=$(sed -n 's/.*jitDegrade count = \([0-9-][0-9]*\).*/\1/p' "$T/jc" | head -1)
if [ ! -s "$T/jc.jit" ] || [ ! -s "$T/jc.int" ]; then
    echo "  FAIL  JC VACUITY GUARD: a half is EMPTY -- the walk emitted nothing."
    echo "        A clean diff of two empty captures is an absence check wearing"
    echo "        a diff's clothes. Nothing about this run is interpretable."; fail=1
elif diff "$T/jc.jit" "$T/jc.int" > /dev/null; then
    echo "  ok    JC jitted walk BYTE-IDENTICAL to the oracle ($(wc -l < "$T/jc.jit" | tr -d ' ') lines, both halves)"; green=$((green+1))
else
    echo "  FAIL  JC THE ENGINES DISAGREE -- the jitted walk diverged from the oracle:"
    diff "$T/jc.jit" "$T/jc.int" | sed 's/^/        /'
    echo "        A member surfacing under the WRONG parent means an iterator"
    echo "        cursor is shared across activations: check the frame bracket"
    echo "        in jitEmitSelfCall (save/call/restore) before anything else."; fail=1
fi
#  DEPTH IS ASSERTED BY NAME, because identical-and-shallow would pass the diff.
#  zeta is the depth-3 leaf; a walk that stopped at depth 1 agrees with itself.
if grep -qF "zeta" "$T/jc.jit"; then
    echo "  ok    JC reached DEPTH 3 (zeta present -- identical-but-shallow cannot pass)"; green=$((green+1))
else
    echo "  FAIL  JC never reached depth 3: the halves may agree while both stop early"; fail=1
fi
if [ "$jcd" = "0" ]; then echo "  ok    JC degrade count 0 (the walk compiled; nothing fell through)"; green=$((green+1))
else echo "  FAIL  JC degrade count = '$jcd', want 0"; fail=1; fi

echo ""
echo "-- JS  THE SHAPE THAT EXITED 139. A DRIVER WITH A PREAMBLE, ABOVE A"
echo "       SELF-CALLING CALLEE, ITS GUARD RESET INSIDE THE DRIVER."
#  ⚠ THE RUNG JC COULD NOT BE. JC's driver, dfDrive, is exactly ONE statement,
#  so re-entering the whole function happened to equal re-entering the callee --
#  JC was green for a reason true of ITS DRIVER rather than of the mechanism,
#  the same class as `continue` appearing to work because both arms fell to the
#  back edge. This rung's driver has a THREE-statement preamble, which is the
#  normal case and precisely the shape genParse's emitted rules will have.
#
#  ⚠ H7 NEGATIVE CONTROL, AND IT IS A HANG RATHER THAN A RED. On a pre-S3 binary
#  the driver's `sfDepth = 3` replays on every recursion, the guard is restored,
#  and the recursion never ends -- measured as exit 139 by inlineSelfT, which
#  could only carry this shape as PROSE for exactly that reason. Hence the cap
#  above; a timeout here is not a flaky machine, it is the defect returning.
runcap "JS runs" jitSelfFn "$T/js"
check "JS runs" 0 $?
sentinel "JS sentinel (no truncation)" "$T/js" "jitSelfFn SENTINEL"

jsp=$(sed -n 's/.*SF jitted : pre = *\([0-9-][0-9]*\).*/\1/p' "$T/js" | head -1)
jsc=$(sed -n 's/.*SF jitted : .*count = *\([0-9-][0-9]*\).*/\1/p' "$T/js" | head -1)
jso=$(sed -n 's/.*SF jitted : .*out = *\([0-9-][0-9]*\).*/\1/p' "$T/js" | head -1)
jsd=$(sed -n 's/.*jitDegrade count = \([0-9-][0-9]*\).*/\1/p' "$T/js" | tail -1)
jscc=$(sed -n 's/.*jitCompile count = \([0-9-][0-9]*\).*/\1/p' "$T/js" | tail -1)

#  ⚠ THE LOAD-BEARING ROW, and it is the defect stated as a number. Under the
#  replay the driver's preamble re-executes per recursion, so this reads 4 -- or
#  the run never returns and the cap above catches it. ONE is the only value a
#  driver whose preamble ran as written can produce.
if [ "$jsp" = "1" ]; then
    echo "  ok    JS the driver's preamble ran EXACTLY ONCE (pre = 1)  <- THE CLAIM"; green=$((green+1))
else echo "  FAIL  JS pre = '$jsp', want 1. The driver's preamble is REPLAYING:"
     echo "        an inlined callee's self-call is targeting the ENCLOSING"
     echo "        function instead of the callee's own. Check jitEmitSelfCall's"
     echo "        four-arm decision and gJitFnMap before anything else."; fail=1; fi

#  ⚠ THE NON-ZERO SIBLING. A `1` that a default could also produce asserts
#  nothing; 4 activations cannot come from a slot that merely defaults.
if [ "$jsc" = "4" ]; then
    echo "  ok    JS 4 activations (the recursion actually ran to depth 3)"; green=$((green+1))
else echo "  FAIL  JS count = '$jsc', want 4"; fail=1; fi

#  PER-ACTIVATION STORAGE, one level further out than JRL: sfLoc is read AFTER
#  the recursive call returns. Per-activation 3; aliased slots 0, because the
#  innermost activation would have written the shared slot last.
if [ "$jso" = "3" ]; then
    echo "  ok    JS out = 3  (the outermost activation's local survived the call)"; green=$((green+1))
else echo "  FAIL  JS out = '$jso', want 3. 0 means the locals ALIAS."; fail=1; fi

if [ "$jsd" = "0" ]; then echo "  ok    JS degrade count 0"; green=$((green+1))
else echo "  FAIL  JS degrade count = '$jsd', want 0"; fail=1; fi
#  THE BRIEF'S OWN DISCRIMINATOR: two functions inside ONE compile leaves this at
#  1. If it moved, the implementation NESTED jitRunAction instead of sequencing
#  jitBuildFunction, and the sixteen globals are being re-entered.
if [ "$jscc" = "1" ]; then
    echo "  ok    JS compile count 1 across TWO emitted functions  <- sequenced, not nested"; green=$((green+1))
else echo "  FAIL  JS compile count = '$jscc', want 1 -- the build NESTED"; fail=1; fi

#  ============ R3: THE DEFECT SIGNATURE, ASSERTED ON THE IR ITSELF ============
#  Stronger than the values above because it names the MECHANISM rather than its
#  consequence: NO function may call ITSELF unless it is the callee's own
#  function. Before S3 the driver's function called itself.
runcap "JS IR dump" jitSelfFn "$T/js.ir" "INCANT_JIT_DUMP=1"
#  S2 (amended, 2026-08-05): names derive from ACTION IDENTITY -- `jit_<tag>` --
#  not from a per-process counter, so these patterns match the identity form. A
#  rung still grepping `jitFn[0-9]*` would go quietly VACUOUS the day the naming
#  moved, which is exactly why the vacuity guard below reads the captured BLOCK
#  and not merely the name.
jsdrv=$(sed -n 's/^=== IR \(jit_[A-Za-z0-9_]*\) (post-mem2reg) ===.*/\1/p' "$T/js.ir" | head -1)
#  The driver's own define block, and nothing else's.
awk -v d="define i32 @$jsdrv()" '$0 ~ d {f=1} f{print} f && /^}/{exit}' "$T/js.ir" > "$T/js.drv"
#  ⚠ VACUITY GUARD FIRST, H4's other half. A "does not contain" assertion passes
#  trivially against an empty file, and an absence check that can pass by having
#  nothing to look at is theatre. So: the driver must be NAMED, and its block
#  must have been CAPTURED, before the never-assertion is allowed to mean anything.
if [ -z "$jsdrv" ] || [ ! -s "$T/js.drv" ]; then
    echo "  FAIL  JS R3 VACUITY: no driver name in the dump, or its define block"
    echo "        was not captured. The never-assertion below would pass by"
    echo "        having nothing to read. Nothing here is interpretable."; fail=1
else
    echo "  ok    JS R3 driver function named ($jsdrv) and its IR captured"; green=$((green+1))
    if grep -q "call i32 @$jsdrv()" "$T/js.drv"; then
        echo "  FAIL  JS R3 THE DRIVER CALLS ITSELF -- call i32 @$jsdrv() inside"
        echo "        @$jsdrv. That IS the defect: an inlined callee's self-call"
        echo "        targeting the enclosing function. Every recursion replays"
        echo "        the driver's preamble."; fail=1
    else
        echo "  ok    JS R3 the driver does NOT call itself"; green=$((green+1)); fi
    #  PRESENCE, so R3 cannot be satisfied by a driver that calls nothing at all.
    if grep -q "call i32 @jit_" "$T/js.drv"; then
        echo "  ok    JS R3 the driver DOES call another function (the callee's own)"; green=$((green+1))
    else
        echo "  FAIL  JS R3 the driver calls no function -- it inlined, or the"
        echo "        callee never got its own function"; fail=1; fi
fi
#  AND THE POSITIVE HALF: the callee's own function DOES call itself. Recursion
#  is still real; S3 moved WHERE the call lands, it did not remove the call.
if [ -n "$jsdrv" ] && grep -E "^define i32 @jit_" "$T/js.ir" | grep -qv "@$jsdrv"; then
    jscal=$(sed -n 's/^define i32 @\(jit_[A-Za-z0-9_]*\)().*/\1/p' "$T/js.ir" | grep -v "^$jsdrv$" | head -1)
    awk -v d="define i32 @$jscal()" '$0 ~ d {f=1} f{print} f && /^}/{exit}' "$T/js.ir" > "$T/js.cal"
    if [ -s "$T/js.cal" ] && grep -q "call i32 @$jscal()" "$T/js.cal"; then
        echo "  ok    JS R3 the CALLEE's function calls ITSELF ($jscal) -- recursion is real"; green=$((green+1))
    else
        echo "  FAIL  JS R3 the callee's function does not recurse into itself"; fail=1; fi
else
    echo "  FAIL  JS R3 only one function was emitted -- the callee never got its own"; fail=1
fi

echo ""
echo "-- JRt RETURN. THE FIRST RUNG THAT ASSERTS WHAT AN ACTION HANDS BACK."
#  ⚠⚠ EVERY RUNG ABOVE THIS ONE ASSERTS A **FIELD** AFTER THE ACTION, NEVER A
#  **RETURNED** VALUE, AND THERE WAS ONE REASON: `return` called jitDegrade. So
#  "what did the compiled action hand back" had never been asked of any
#  construct, and CLAIM KANT-8's jitted parity was not merely unanswered, it was
#  NOT ASKABLE. Item 2 (Tony, 2026-08-05) built the emitter; this rung is the
#  question finally being put.
#
#  ⚠ THE WITNESS IS THE HARNESS'S OWN LINE, NOT A print IN THE FIXTURE.
#  jitRunAction and jitRefire print the returned value from C++ printf, so it
#  never passes through the incant print path -- which matters because a jitted
#  print of a bare string literal currently emits the string's LENGTH instead of
#  its text (pre-existing, measured, pinned in incant/jitSelfFn's header, degrade
#  count 0 throughout). An oracle that can be silently wrong is not an oracle.
retrung () {                    # retrung <file> <sentinel> <label> <want1> <want2>
    f=$1; sent=$2; label=$3; w1=$4; w2=$5
    runcap "$label runs" "$f" "$T/$f"
    if [ $? != 0 ]; then echo "  FAIL  $label -- nonzero exit"; fail=1; return; fi
    if ! grep -qF "$sent" "$T/$f"; then
        echo "  FAIL  $label -- TRUNCATED at exit 0; nothing in this run is interpretable"
        fail=1; return; fi
    r1=$(sed -n 's/.*jitRunAction result = \([0-9-][0-9]*\).*/\1/p' "$T/$f" | head -1)
    r2=$(sed -n 's/.*jitRefire result = \([0-9-][0-9]*\).*/\1/p' "$T/$f" | head -1)
    dg=$(sed -n 's/.*jitDegrade count = \([0-9]*\).*/\1/p' "$T/$f" | tail -1)
    [ "$r1" = "$w1" ] && { echo "  ok    $label RETURNED $w1 on fire 1"; green=$((green+1)); } \
                      || { echo "  FAIL  $label fire 1 returned '$r1', want $w1"; fail=1; }
    if [ "$r2" = "$w2" ]; then
        echo "  ok    $label RETURNED $w2 on fire 2  <- RUN-TIME PROOF (no recompile)"; green=$((green+1))
    else
        echo "  FAIL  $label fire 2 returned '$r2', want $w2"
        echo "        If it equals fire 1 the value was FOLDED at compile time and"
        echo "        fire 1 proved nothing. If empty, the refire never happened."
        fail=1
    fi
    #  E4: INSIDE A SELF-TEST-PASSING CALLEE A RETURN MUST NOT DEGRADE. This is
    #  the no-degrade-in-family posture made real at its first site.
    if [ "$dg" = "0" ]; then echo "  ok    $label degrade count 0 (the return EMITTED; nothing fell through)"; green=$((green+1))
    else echo "  FAIL  $label degrade count = '$dg', want 0 -- a return fell through"; fail=1; fi
}

#  F1 -- the base case. A returned scalar from a NON-recursive action.
retrung jitJRt1 "JRt1 SENTINEL" "JRt1" 21 27
o1=$(sed -n 's/.*JRt1 interpreted  *: rtOut = *\([0-9-][0-9]*\).*/\1/p' "$T/jitJRt1" | head -1)
if [ "$o1" = "21" ]; then echo "  ok    JRt1 oracle agrees: interpreted returned 21 == jitted"; green=$((green+1))
else echo "  FAIL  JRt1 ORACLE DISAGREES: interpreted '$o1' vs jitted 21"; fail=1; fi

#  F2 -- factorial(5) = 120 through REAL RECURSION, carried out through the
#  return value rather than read off a field afterwards. KR-1's first row.
retrung jitJRt2 "JRt2 SENTINEL" "JRt2" 120 720
#  ⚠ THE ORACLE IS A SEPARATE PROCESS, AND THAT IS A FINDING. The identical
#  interpreted call placed BELOW the jitted fires returns 5 -- ftAcc's value at
#  the outermost activation before it recursed, the save/restore signature --
#  while standalone it returns 120. So a post-jit interpreted call is NOT a clean
#  oracle for a RETURNED value, whatever it is for a field (jitJR reads its
#  accumulator as a field in the same position and is correct, which is why
#  nothing had caught this). Interpreter-side, out of item 2's scope, reported.
runcap "JRt2 oracle runs" jitJRt2o "$T/jitJRt2o"
check "JRt2 oracle runs" 0 $?
sentinel "JRt2 oracle sentinel" "$T/jitJRt2o" "JRt2o SENTINEL"
o2=$(sed -n 's/.*JRt2o interpreted : ftOut = *\([0-9-][0-9]*\).*/\1/p' "$T/jitJRt2o" | head -1)
if [ "$o2" = "120" ]; then echo "  ok    JRt2 oracle (own process) agrees: interpreted 120 == jitted"; green=$((green+1))
else echo "  FAIL  JRt2 ORACLE DISAGREES: interpreted '$o2' vs jitted 120"; fail=1; fi

#  F3 -- CLAIM KANT-8's shape. ⚠⚠ AN INTENDED DIVERGENCE, RULED, NOT A DEFECT.
#  KR-3's first inverted row: the jitted column is asserted at 42/45, and the
#  interpreted column is asserted to be the bare TAG. Both by name.
retrung jitJRt3 "JRt3 SENTINEL" "JRt3" 42 45
runcap "JRt3 interpreted column runs" jitJRt3o "$T/jitJRt3o"
check "JRt3 interpreted column runs" 0 $?
sentinel "JRt3 interpreted column sentinel" "$T/jitJRt3o" "JRt3o SENTINEL"
#  ⚠ ASSERTED, NOT MERELY NOTED. A divergence nobody measures is
#  indistinguishable from one that has quietly closed -- and if KANT-8 is ever
#  repaired, THIS row is what says so loudly instead of the repair landing
#  unnoticed. Presence-with-value on both sides (H4).
#
#  ⚠ GRADUATED 2026-08-10 (SEQ 27 rung A, H6) -- AND THE RE-PIN SENTENCE, because
#  a target that moved is a claim that the world changed and the claim needs a
#  cause. THE CAUSE: runAction now captures the result's VALUE before
#  restoreLocalFields sweeps the frame (GroupActions.rtn, the return seam), so
#  the interpreter no longer hands back a pointer into the frame being restored.
#  It returns 42, which is what the jitted arm has always returned. CLAIM KANT-8
#  is repaired for the door-one population, and this row fired on exactly the day
#  it was built to fire -- the pre-registered message above is what caught it.
#  The row is therefore no longer a pinned divergence but a full AGREEMENT check,
#  and the old tag reading is now an explicit REGRESSION arm rather than a silent
#  else. Values, never counters.
#  ⚠ LEDGER OF RECORD: the K-row table under CLAIM KANT-8 in docs/kantCorpus.md.
#  The former text here said "update the KR-3 ledger row"; KR-3 was RETIRED
#  2026-08-10 (Tony) -- it never existed as a file, and a tree-wide grep returned
#  only the sentence instructing people to update it.
if grep -q "JRt3o interpreted : k8out = 42" "$T/jitJRt3o"; then
    echo "  ok    JRt3 ENGINES AGREE: interpreted 42 == jitted 42 (CLAIM KANT-8 repaired at the seam)"; green=$((green+1))
elif grep -q "JRt3o interpreted : k8out = k8loc" "$T/jitJRt3o"; then
    echo "  FAIL  JRt3 REGRESSION -- the interpreter is back to returning the TAG k8loc."
    echo "        The runAction value-capture seam is not firing; CLAIM KANT-8 has returned."; fail=1
else
    echo "  FAIL  JRt3 interpreted column is neither the tag nor 42 -- unreadable"; fail=1
fi

#  F4 -- E1's mid-block return, with statements after it. Both fires take the
#  OPPOSITE arm, and mbTail is the second channel: a returned value alone cannot
#  distinguish "the tail was skipped" from "the tail ran and was discarded".
retrung jitJRt4 "JRt4 SENTINEL" "JRt4" 111 222
t1=$(sed -n 's/.*JRt4 fire 1 tail  : mbTail = *\([0-9-][0-9]*\).*/\1/p' "$T/jitJRt4" | head -1)
t2=$(sed -n 's/.*JRt4 fire 2 tail  : mbTail = *\([0-9-][0-9]*\).*/\1/p' "$T/jitJRt4" | head -1)
if [ "$t1" = "0" ]; then echo "  ok    JRt4 fire 1 tail NOT executed (mbTail = 0, the early return was taken)"; green=$((green+1))
else echo "  FAIL  JRt4 fire 1 mbTail = '$t1', want 0 -- the tail ran past a taken return"; fail=1; fi
if [ "$t2" = "999" ]; then echo "  ok    JRt4 fire 2 tail DID execute (mbTail = 999, the return was not taken)"; green=$((green+1))
else echo "  FAIL  JRt4 fire 2 mbTail = '$t2', want 999 -- the statements after the"
     echo "        return were never EMITTED. aCTionBlocK's 'if jitting continue'"
     echo "        is what keeps the emit walk going past a branch."; fail=1; fi

echo ""
echo "-- JXT SEQUENCE TEMPLATE. THE genKantParse BODY, AND A REAL SHORT-CIRCUIT."
#  ⚠⚠ THIS RUNG DOES NOT USE `rung`, DELIBERATELY, AND THE REASON IS THE POINT:
#  `rung` asserts degrade == 0, and this fixture's honest answer is degrade == 2.
#  Using the generic helper would have forced a choice between weakening the
#  fleet's degrade-zero rule and not landing the rung. Neither was right --
#  the count is ASSERTED AT ITS TRUE VALUE instead, so it is still H4 (a value,
#  not an absence) and it still breaks when the world moves.
#
#  WHAT IT CERTIFIES (SEQ 41 step 3's template, measured 2026-08-08):
#      xtSuk = xtT1();  if xtSuk == 0;  return 0;   ... return 1;
#  ticks 1 on fire 1 -- THE SECOND TERM NEVER RAN. ticks 3 on fire 2 -- both did.
#  That is a short-circuit BY CONSTRUCTION rather than by an operator declining
#  to evaluate, which CLAIM KANT-34 says the operator machinery cannot express.
#
#  ⚠ ticks IS CUMULATIVE ACROSS FIRES ON PURPOSE. It is not reset between them,
#  so fire 2's 3 = 1 + 2 and the two rows CANNOT both be satisfied by a folded
#  constant. A per-fire reset would have made 1 and 2 the expected pair, and a
#  slot that merely defaulted could produce the first of those.
runcap "JXT runs" jitXtemplate "$T/jitXtemplate"
check   "JXT runs" 0 $?
sentinel "JXT sentinel" "$T/jitXtemplate" "XT SENTINEL"
xt1=$(sed -n 's/.*XT fire 1 result: ticks = *\([0-9][0-9]*\).*/\1/p' "$T/jitXtemplate" | head -1)
xt2=$(sed -n 's/.*XT fire 2 result: ticks = *\([0-9][0-9]*\).*/\1/p' "$T/jitXtemplate" | head -1)
xtd=$(sed -n 's/.*jitDegrade count = \([0-9]*\).*/\1/p' "$T/jitXtemplate" | head -1)
xto=$(sed -n 's/.*XT interpreted  *: ticks = *\([0-9][0-9]*\).*/\1/p' "$T/jitXtemplate" | head -1)
if [ "$xt1" = "1" ]; then echo "  ok    JXT fire 1 ticks = 1  <- THE SHORT-CIRCUIT: term 2 never ran"; green=$((green+1))
else echo "  FAIL  JXT fire 1 ticks = '$xt1', want 1. A 2 means BOTH terms ran on a"
     echo "        failed first term -- eager evaluation, and for a parser that is"
     echo "        input consumed past text the rule never matched."; fail=1; fi
if [ "$xt2" = "3" ]; then echo "  ok    JXT fire 2 ticks = 3  <- RUN-TIME PROOF (no recompile, both terms ran)"; green=$((green+1))
else echo "  FAIL  JXT fire 2 ticks = '$xt2', want 3 (cumulative 1+2)."
     echo "        Equal to fire 1 means the calls were folded at compile time."; fail=1; fi
#  ⚠ E2 PINNED AT ITS TRUE VALUE, AND IT IS A GRADUATION TRIGGER (RULE H6).
#  The two degrades are `return INSIDE AN INLINED CALLEE` -- E2, unbuilt. This
#  fixture is green ONLY because a TAIL return needs no branch to the enclosing
#  epilogue, so falling through is accidentally equivalent. When E2's rung lands
#  (SEQ 41 step 5) this count goes to 0 and THIS ROW GOES RED ON PURPOSE. Do not
#  re-pin it green without a sentence: a target that moved is a claim that the
#  world changed, and the claim needs a cause.
#  ✅ GRADUATED 2026-08-09, AND THE SENTENCE THE RE-PIN RULE ASKS FOR: the pin
#  moved from 2 to 0 because E2 WAS BUILT, not because the fixture drifted. The
#  two degrades were both `return INSIDE AN INLINED CALLEE`; an inlined region
#  now carries its own exit block and the return branches there, so there is
#  nothing left to fall through. The prediction was written into the old pin
#  ("when E2's rung lands this count goes to 0") and it is what happened.
#  This row is now an ORDINARY degrade-zero assertion and rejoins the fleet rule.
if [ "$xtd" = "0" ]; then echo "  ok    JXT degrade count = 0 (E2 built 2026-08-09; was pinned at 2)"; green=$((green+1))
else echo "  FAIL  JXT degrade count = '$xtd', want 0. E2 landed on 2026-08-09, so a"
     echo "        non-zero count means something fell through that did not before --"
     echo "        the template is no longer built from certified constructs."; fail=1; fi
if [ "$xto" = "1" ]; then echo "  ok    JXT oracle agrees: interpreted ticks 1 == jitted (both short-circuit)"; green=$((green+1))
else echo "  FAIL  JXT ORACLE DISAGREES: interpreted '$xto' vs jitted 1"; fail=1; fi

echo ""
echo "-- JXD PINNED DEFECTS. TWO ROWS THAT ASSERT THE BUG, NOT THE FIX."
#  ⚠⚠ THESE TWO ROWS ARE INVERTED AND THAT IS THEIR WHOLE VALUE. They go GREEN
#  while the defect is present and RED when it is repaired, which is the WOKE
#  alarm's shape (RULE H6). A defect nobody pinned is a defect that comes back,
#  and worse -- an UNPINNED defect gets rediscovered as a new finding and costs
#  the investigation twice. Both were measured 2026-08-08 and are PRE-EXISTING.
#
#  BOTH ARE THE UNGATED-OPERATOR CLASS: opAND and opOR are on jit.md S2.1's
#  not-gated list (24 entries). SEQ 41 step 5 sweeps the other 22.

#  JXD-1 -- `AND` UNDER JIT EXITS 139, AND PRINTS NO DEGRADE LINE AT ALL.
#  ⚠ THE MISSING DEGRADE LINE IS THE SHARP PART, not the crash. It dies BEFORE
#  the counter every other rung asserts at zero can see it, so degrade-0 is not
#  evidence about this construct. A gate that was never installed reads, from
#  outside, exactly like one that passed.
#  ⚠ THE SHELL PRINTS ITS OWN `Segmentation fault: 11` LINE ON THE NEXT ROW AND
#  IT IS EXPECTED. runcap's own header warns that an instrument adding chatter to
#  the evidence will be misread -- so it is ANNOUNCED rather than suppressed,
#  because silencing it would mean silencing the same line on a rung where a
#  crash is NOT expected. Announced beats hidden; hidden beats nothing.
echo "     (the next line is the shell reporting the PINNED crash -- expected)"
runcap "JXD-1 AND-under-jit runs (expecting the crash)" jitXand2 "$T/jitXand2"
xa=$?
if [ "$xa" = "139" ]; then
    echo "  ok    JXD-1 PINNED: \`AND\` under jit exits 139 (defect present, as recorded)"; green=$((green+1))
elif [ "$xa" = "0" ]; then
    echo "  FAIL  JXD-1 WOKE -- \`AND\` under jit NO LONGER CRASHES (exit 0)."
    echo "        This is GOOD NEWS ARRIVING AS A RED, which is the pin working."
    echo "        Do not delete this row: GRADUATE it (H6). Verify the answers are"
    echo "        also CORRECT before believing it -- not crashing and being right"
    echo "        are different claims, and jitXor is the cautionary sibling."
    fail=1
else
    echo "  FAIL  JXD-1 exit '$xa' -- neither the pinned 139 nor a clean 0. The"
    echo "        defect changed shape; re-measure before re-pinning."; fail=1
fi

#  JXD-2 -- `OR` UNDER JIT IS SILENTLY WRONG AT DEGRADE 0.
#  ⚠ THE WORSE OF THE TWO, because it exits 0 and lies. Fire 2 (1 OR 0) must be
#  1 and is 0: the expression evaluated at EMIT time and folded. The pin asserts
#  the WRONG value, by name, so a repair breaks this row instead of passing it.
#
#  ⚠⚠ AND THE FIXTURE ITSELF CARRIES THE LESSON THAT FOUND IT. The first version
#  of jitXor used fires `0 OR 1` and `1 OR 1` -- BOTH 1 -- and REPORTED GREEN.
#  It would have entered the record as "OR is fine." A fixture that cannot
#  distinguish the answers distinguishes nothing, including one written minutes
#  after citing the anti-vacuity rule.
runcap "JXD-2 OR-under-jit runs" jitXor "$T/jitXor"
check   "JXD-2 OR-under-jit runs" 0 $?
sentinel "JXD-2 sentinel" "$T/jitXor" "XO SENTINEL"
xo1=$(sed -n 's/.*XO fire 1 result: xoOut = *\([0-9-][0-9]*\).*/\1/p' "$T/jitXor" | head -1)
xo2=$(sed -n 's/.*XO fire 2 result: xoOut = *\([0-9-][0-9]*\).*/\1/p' "$T/jitXor" | head -1)
xod=$(sed -n 's/.*jitDegrade count = \([0-9]*\).*/\1/p' "$T/jitXor" | head -1)
if [ "$xo1" = "0" ]; then echo "  ok    JXD-2 fire 1 = 0 (0 OR 0 -- correct, and the only correct row)"; green=$((green+1))
else echo "  FAIL  JXD-2 fire 1 = '$xo1', want 0"; fail=1; fi
if [ "$xo2" = "0" ]; then
    echo "  ok    JXD-2 PINNED: fire 2 = 0 but WANTS 1 -- the emit-time fold, silent"; green=$((green+1))
elif [ "$xo2" = "1" ]; then
    echo "  FAIL  JXD-2 WOKE -- \`OR\` under jit now returns the CORRECT 1 on fire 2."
    echo "        Good news arriving as a red. GRADUATE this row to a normal"
    echo "        assertion (H6) and re-pin with a sentence naming the cause."
    fail=1
else
    echo "  FAIL  JXD-2 fire 2 = '$xo2' -- neither the pinned 0 nor the correct 1."; fail=1
fi
if [ "$xod" = "0" ]; then echo "  ok    JXD-2 degrade count 0 CONFIRMS the silence (wrong answer, no warning)"; green=$((green+1))
else echo "  FAIL  JXD-2 degrade count = '$xod', pinned at 0. If nonzero, OR now"
     echo "        DECLARES its fallback -- an honest answer, and a graduation."; fail=1; fi

echo ""
echo "-- JE2 / JXN  E2 OWNED WHILE IT WAITS. TWO MORE INVERTED ROWS."
#  ⚠⚠ E2 IS A CAMPAIGN PREREQUISITE, NOT PARALLEL-TRACK PURITY WORK (R1, Tony,
#  2026-08-08). These two rows exist so it is OWNED rather than remembered: an
#  unpinned defect gets rediscovered as a new finding and costs the
#  investigation twice.
#
#  E2 = a `return` inside an INLINED callee. jitEmitters degrades it, saying
#  "running INTERPRETED". THAT IS TRUE AND IT IS NOT THE SAME AS SOUND:
#      TAIL position      -- degrading is equivalent, because a tail return
#                            needs no branch to the enclosing epilogue.
#                            Rung JXT is green on exactly this, degrade 2.
#      MID-BODY position  -- degrading CHANGES THE ANSWER. Same degrade count.
#  So the degrade counter cannot distinguish the two, which is why both rows
#  below assert VALUES and not the counter.

#  JE2 -- the construct, isolated. Fire 1 must take an early return and does
#  not: 222/999 where the interpreter says 111/0. PINNED WRONG.
runcap "JE2 runs" jitXe2 "$T/jitXe2"
check   "JE2 runs" 0 $?
sentinel "JE2 sentinel" "$T/jitXe2" "XE SENTINEL"
e1=$(sed -n 's/.*XE fire 1 result: xeOut = *\([0-9-][0-9]*\).*/\1/p' "$T/jitXe2" | head -1)
et=$(sed -n 's/.*XE fire 1 result:.*xeTail = *\([0-9-][0-9]*\).*/\1/p' "$T/jitXe2" | head -1)
eo=$(sed -n 's/.*XE interpreted  *: xeOut = *\([0-9-][0-9]*\).*/\1/p' "$T/jitXe2" | head -1)
#  ✅ GRADUATED 2026-08-09 -- E2 BUILT, and this row is now a POSITIVE assertion.
#  Was pinned at 222/999 (the early return ignored, the tail running anyway).
#  The fix: an inlined region gets an epilogue of its own -- one JitInlineFrame
#  per inline, whose exit block is the branch target for a return inside the
#  callee. Branching to gJitEpilogueBB instead would have returned from the
#  CALLER, which is why the case was refused rather than guessed at.
#  ⚠ THE SECOND CHANNEL IS STILL LOAD-BEARING AND IS STILL ASSERTED. xeTail
#  answers what the returned value cannot: 111 alone cannot distinguish "the
#  early return was taken" from "the tail ran and its value was discarded".
#  Both are checked, on both fires, and the two fires take OPPOSITE arms from
#  ONE compile -- so no folded constant and no default satisfies both.
#
#  ✅ H7 NEGATIVE CONTROL -- MEASURED, and stronger than the usual synthetic
#  gate-removal because the mechanism-absent run was PINNED GREEN IN A SHIPPING
#  HARNESS for a day rather than being staged for the occasion:
#      E2 ABSENT  (binary 1316624, 2026-08-08):  111/0 wanted, got 222/999,
#                 degrade 2, exit 0, oracle 111/0  -- WRONG AND SILENT
#      E2 PRESENT (binary of 2026-08-09):        111/0 and 222/999, degrade 0,
#                 exit 0, oracle 111/0           -- engines agree
#  The wrong answer cost NOTHING visible: exit 0, sentinel printed, and a
#  degrade line that said "running INTERPRETED" -- true, and not the same as
#  sound. That gap is why this rung asserts values and never the counter.
e2=$(sed -n 's/.*XE fire 2 result: xeOut = *\([0-9-][0-9]*\).*/\1/p' "$T/jitXe2" | head -1)
e2t=$(sed -n 's/.*XE fire 2 result:.*xeTail = *\([0-9-][0-9]*\).*/\1/p' "$T/jitXe2" | head -1)
if [ "$e1" = "111" ] && [ "$et" = "0" ]; then
    echo "  ok    JE2 fire 1: early return TAKEN -- 111, xeTail 0 (E2 built 2026-08-09)"; green=$((green+1))
elif [ "$e1" = "222" ] && [ "$et" = "999" ]; then
    echo "  FAIL  JE2 REGRESSED to the pre-E2 defect: mid-body return ignored again"
    echo "        (222/999). The inlined region's exit block is not being reached."; fail=1
else
    echo "  FAIL  JE2 fire 1 = $e1/$et, want 111/0."; fail=1
fi
if [ "$e2" = "222" ] && [ "$e2t" = "999" ]; then
    echo "  ok    JE2 fire 2: early return NOT taken -- 222, xeTail 999 (opposite arm)"; green=$((green+1))
else
    echo "  FAIL  JE2 fire 2 = $e2/$e2t, want 222/999. A fixture that cannot take"
    echo "        BOTH arms from one compile distinguishes nothing."; fail=1
fi
xed=$(sed -n 's/.*jitDegrade count = *\([0-9][0-9]*\).*/\1/p' "$T/jitXe2" | head -1)
if [ "$xed" = "0" ]; then echo "  ok    JE2 degrade count = 0 (was 2 -- both were this construct)"; green=$((green+1))
else echo "  FAIL  JE2 degrade count = '$xed', want 0."; fail=1; fi
if [ "$eo" = "111" ]; then echo "  ok    JE2 oracle: interpreted 111 -- the engines now AGREE"; green=$((green+1))
else echo "  FAIL  JE2 oracle = '$eo', want 111. The interpreter's answer moved, not the JIT's."; fail=1; fi

#  JXN -- THE CAMPAIGN CONSEQUENCE, and the row that makes E2 a prerequisite.
#  Two levels of the SEQ 41 sequence template, inner rule failing its first
#  term. Jitted reports SUCCESS on a failing term: for a parser that is
#  ACCEPTING INPUT IT MUST REJECT, silently, at exit 0.
#  ⚠ Both tails are asserted, not just the returned value: out=1 alone cannot
#  distinguish "no early return fired" from "one fired and the other did not".
runcap "JXN runs" jitXnest "$T/jitXnest"
check   "JXN runs" 0 $?
sentinel "JXN sentinel" "$T/jitXnest" "XN SENTINEL"
n1=$(sed -n 's/.*XN fire 1 result: xnOut = *\([0-9-][0-9]*\).*/\1/p' "$T/jitXnest" | head -1)
ni=$(sed -n 's/.*XN fire 1 result:.*innerTail = *\([0-9-][0-9]*\).*/\1/p' "$T/jitXnest" | head -1)
no=$(sed -n 's/.*XN interpreted  *: xnOut = *\([0-9-][0-9]*\).*/\1/p' "$T/jitXnest" | head -1)
#  ✅ GRADUATED 2026-08-09 -- and this is the row that mattered most, because it
#  is the CAMPAIGN consequence rather than the construct. Was pinned at out 1 /
#  innerTail 999: the two-deep template ACCEPTING input it must REJECT, silently,
#  at exit 0. It now rejects, and R1's correctness prerequisite for genKantParse
#  v1 is discharged.
#  ⚠ THE SENTENCE THE RE-PIN RULE ASKS FOR: this row moved for the SAME single
#  cause as JE2 and JXT -- E2 -- and no fixture, oracle or template was touched.
#  Three pins, one repair, and the ladder moved nowhere else, which is the
#  evidence that E2 was the whole of it rather than one of several causes.
#  ⚠ BOTH TAILS STILL ASSERTED: out=0 alone cannot distinguish "no early return
#  fired" from "one fired and the other did not".
if [ "$n1" = "0" ] && [ "$ni" = "0" ]; then
    echo "  ok    JXN: nested template REJECTS the failing term (out 0, innerTail 0)"; green=$((green+1))
elif [ "$n1" = "1" ] && [ "$ni" = "999" ]; then
    echo "  FAIL  JXN REGRESSED to the pre-E2 defect: the two-deep template is"
    echo "        ACCEPTING INPUT IT MUST REJECT again, at exit 0. This is the"
    echo "        campaign-blocking shape, not a purity row."; fail=1
else
    echo "  FAIL  JXN got out $n1 / innerTail $ni, want 0/0."; fail=1
fi
xnd=$(sed -n 's/.*jitDegrade count = *\([0-9][0-9]*\).*/\1/p' "$T/jitXnest" | head -1)
if [ "$xnd" = "0" ]; then echo "  ok    JXN degrade count = 0 -- E2 holds at DEPTH 2, not just depth 1"; green=$((green+1))
else echo "  FAIL  JXN degrade count = '$xnd', want 0."; fail=1; fi
if [ "$no" = "0" ]; then echo "  ok    JXN oracle: interpreted 0 -- the engines now AGREE"; green=$((green+1))
else echo "  FAIL  JXN oracle = '$no', want 0."; fail=1; fi

echo ""
#  ⚠ H2 -- THE LADDER ASSERTS ITS OWN COMPLETENESS, and it must be unreachable
#  except through the LAST rung. Added 2026-08-05 with the check/sentinel
#  repair: for four days this file called two helpers it never defined, and the
#  only symptom was `command not found` on stderr amid a PASSED banner.
if [ "$green" -lt 1 ]; then
    echo "jitLADDER FAILED -- END MARKER REACHED WITH NO GREEN CHECKS RECORDED;"
    echo "                   the helpers are missing again or the rungs evaporated."
    fail=1
fi
#  ⚠ THE BANNER NAMES WHICH ROWS ARE PINNED AND IT IS KEPT HONEST DELIBERATELY.
#  JE2 and JXN GRADUATED on 2026-08-09 when E2 landed; leaving them listed as
#  "pinned" would make the summary line contradict its own rows, which is the
#  instrument failure mixed.sh paid for on 2026-08-08 and the line most readers
#  are the only one they read. JXD-1/JXD-2 are the only inverted rows left.
if [ $fail = 0 ]; then echo "jitLADDER PASSED (rungs: J1 J2 J3 J4 J5 J6 J7 JE JF JP JPd JU JA JI JPv JV JC JS JRt JXT JE2 JXN + JXD-1/JXD-2 pinned + J-R THE PROOF)"
else echo "jitLADDER FAILED"; fi
rm -rf "$T"
exit $fail
