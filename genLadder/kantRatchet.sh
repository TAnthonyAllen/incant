#!/bin/sh
#  kantRatchet.sh -- GENERATE -> BYTE-COMPARE -> INSTALL -> RUN, in one pass.
#  Run from the Groups directory:   sh genLadder/kantRatchet.sh
#
#  ===========================================================================
#  WHAT THIS IS. Phase 2 of the parse monty (SEQ 66-r1 / SEQ 67 part B): the
#  emitter replacing the hand, one rule at a time. A hand-written kant parse
#  body IS a manual run of genKant; this asserts that the machine reproduces it
#  and then runs what it produced.
#
#  ⚠ PROVENANCE IS ASSERTED IN-RUN, NEVER ASSUMED. Every stage uses THIS run's
#  own output: the body is emitted fresh here, byte-compared here, written to a
#  file here, and executed from that file here. Nothing is carried in from a
#  previous run and nothing is taken on trust -- which is the difference between
#  "the emitter can reproduce the hand body" and "the bytes that just ran came
#  out of the emitter."
#
#  THE ORACLE IS THE HAND BODY, and the dividend is that a byte-match INHERITS
#  its runtime certification instead of re-earning it: incant/bracedK certified
#  that exact text end to end on 2026-08-13 (SEQ 63), and identical bytes
#  through a certified pipeline cannot behave differently. Rung R3 runs it
#  anyway, because that inheritance is an argument and R3 is a measurement.
#
#  ⚠ THE REPEAT RULE, for whoever adds the next rule to RULES below. A
#  byte-match to a proven hand body rides the bell -- cheap, inherited. ANY
#  deliberate divergence from the hand spelling (the emitter formats
#  differently, optimises, reorders) KILLS THE BYTE-ORACLE FOR THAT RULE and
#  re-engages full runtime certification for it. Say which, per rule, in the
#  report. Do not quietly re-target a moved oracle: a target that moved is a
#  claim the world changed, and the claim needs a cause.
#
#  ⚠ NOTHING IN THE REPO IS MODIFIED. The emitted file and the fixture that
#  loads it are written into a scratch dir and reached by absolute path, so a
#  red run cannot leave a half-swapped artifact behind and the fleet's fixture
#  population does not move.
#  ===========================================================================

B=${INCANT:-$HOME/bin/incant}
T=${TMPDIR:-/tmp}/ratchet.$$
CAP=${POPCAP:-30}
mkdir -p "$T"
fail=0
checks=0

. genLadder/smokelib.sh

if [ ! -x "$B" ]; then echo "  FAIL  binary not executable: $B"; exit 1; fi
echobin
echo ""

#  ---------------------------------------------------------------------------
#  RULES: <rule> <hand-file> <hand-body-lines> <live-fixture> <sentinel> <want>
#  Add a row when a rule's body class comes into the shim vocabulary.
#  ---------------------------------------------------------------------------
RULE=Braced
HAND=incant/parseCode
HANDLINES=5
FIXTURE=incant/bracedK
SENTINEL="BRACEDK SENTINEL"
WANT="sumple width is now 251"

echo "  ---- $RULE"

#  --- R1: EMIT FRESH, from the live terms -----------------------------------
cat > "$T/emit" <<EOF
Start();
registry(cOMMANDs);
define genKant immediateAction=genKant; ;
search reset stack Grokking list;
genKant($RULE);
stop();
EOF
$B "$T/emit" > "$T/emit.out" 2> "$T/emitted"
rc=$?
if [ $rc != 0 ]; then bad "R1 emit $RULE -- exit $rc"
elif [ ! -s "$T/emitted" ]; then
    bad "R1 emit $RULE -- emitted NOTHING."
    echo "        Guarded on purpose: a byte-compare of two empty files passes, so an"
    echo "        emitter that silently produced nothing would go green on R2."
else pass "R1 emit $RULE from live terms ($(wc -l < "$T/emitted" | tr -d ' ') lines)"
fi

#  --- R2: BYTE-COMPARE against the hand body --------------------------------
tail -"$HANDLINES" "$HAND" > "$T/hand"
if [ ! -s "$T/hand" ]; then
    bad "R2 oracle for $RULE is EMPTY -- $HAND missing or truncated"
elif diff "$T/hand" "$T/emitted" > "$T/d" 2>&1; then
    pass "R2 $RULE emitted == hand body, BYTE-IDENTICAL (oracle: $HAND)"
else
    bad "R2 $RULE DIVERGES from the hand body -- the byte-oracle is dead for this rule:"
    sed 's/^/        /' "$T/d" | head -20
    echo "        Runtime re-certification re-engages for $RULE. Say so in the report."
fi

#  --- R3: INSTALL THIS RUN'S OWN BYTES AND EXECUTE ---------------------------
#  The emitted body is given a real file, and a copy of the live fixture is
#  re-pointed at it by absolute path. Same fixture, same door, same input --
#  the ONLY change is which file supplies the body.
cp "$T/emitted" "$T/emittedCode"
sed "s#File='$HAND'#File='$T/emittedCode'#" "$FIXTURE" > "$T/fixture"
if ! grep -q "$T/emittedCode" "$T/fixture"; then
    bad "R3 could not re-point $FIXTURE at the emitted file -- the fILEs line did not match."
    echo "        Guarded because a failed sed would silently run the HAND file and pass."
else
    $B "$T/fixture" > "$T/run" 2>&1 &
    cap_pid=$!
    { ( sleep "$CAP"; kill -9 $cap_pid 2>/dev/null ) >/dev/null 2>&1 & } 2>/dev/null
    cap_wd=$!
    wait $cap_pid; rc=$?
    { kill $cap_wd 2>/dev/null; wait $cap_wd 2>/dev/null; } 2>/dev/null
    [ $rc = 137 ] && rc=124
    if   [ $rc = 124 ]; then bad "R3 run of EMITTED $RULE -- TIMEOUT after ${CAP}s"
    elif [ $rc != 0 ];  then bad "R3 run of EMITTED $RULE -- exit $rc"
    elif ! grep -qF "$SENTINEL" "$T/run"; then
        bad "R3 run of EMITTED $RULE -- sentinel absent, run TRUNCATED"
    elif ! grep -q "$WANT" "$T/run"; then
        bad "R3 run of EMITTED $RULE -- wrong value" "want: $WANT"
        grep -o 'sumple width is now [0-9]*' "$T/run" | sed 's/^/        got:  /'
    else pass "R3 EMITTED $RULE parses real input -- $WANT"
    fi
    #  ⚠ THE ARM, BY NAME. 251 alone can pass for the wrong reason: the
    #  interpreted arm has always produced it, so a green value says nothing
    #  about which engine answered. promote=0 is the generated arm.
    if grep -q "attachLabel lab=$RULE promote=0" "$T/run"; then
        pass "R3 EMITTED $RULE reached the GENERATED arm (promote=0)"
    else
        bad "R3 EMITTED $RULE -- no promote=0 attach; the interpreted arm answered,"
        echo "        so the value above proves nothing about the emitted body."
    fi
    #  The kant door by name too, so a fallback to the C++ method cannot pass.
    if grep -q "parseViaKant $RULE -> kp$RULE" "$T/run"; then
        pass "R3 EMITTED $RULE went through the KANT door (kp$RULE)"
    else
        bad "R3 EMITTED $RULE -- the kant door did not fire; something else parsed it."
    fi
fi

echo ""
#  ---------------------------------------------------------------------------
#  ScafKB -- SECOND RULE ON THE RATCHET, and R1+R2 ONLY.
#
#  ⚠ R3 IS NOT AVAILABLE FOR THIS RULE, AND THE REASON IS STRUCTURAL RATHER
#  THAN A SHORTFALL: kpScafKB's body lives INLINE inside incant/kantParse1's
#  own define block, not in an included file, so there is no fILEs line to
#  re-point at emitted bytes. Its runtime certification is therefore INHERITED
#  -- byte-identity with a hand body that incant/kantParse1 already runs green
#  -- and is NOT re-run here. Said out loud per the repeat rule; an unsaid
#  inheritance is how a green row starts meaning less than a reader thinks.
#  Giving ScafKB an R3 means moving its body into an included file, which is a
#  fixture change and is not this rung's business.
#  ---------------------------------------------------------------------------
echo "  ---- ScafKB   (R1+R2 only -- body is inline in its fixture, see comment)"
cat > "$T/emit2" <<'EOF'
Start();
registry(cOMMANDs);
define genKant immediateAction=genKant; ;
register(RatchetKB);
define
    ScafKB isRule "["- "]"-;
    ;
search reset stack Grokking RatchetKB list;
genKant(ScafKB);
stop();
EOF
$B "$T/emit2" > "$T/emit2.out" 2> "$T/emitted2raw"
rc=$?
grep -v '^WARNING:' "$T/emitted2raw" > "$T/emitted2"
if [ $rc != 0 ]; then bad "R1 emit ScafKB -- exit $rc"
elif [ ! -s "$T/emitted2" ]; then
    bad "R1 emit ScafKB -- emitted NOTHING (vacuity guard)"
else pass "R1 emit ScafKB from live terms ($(wc -l < "$T/emitted2" | tr -d ' ') lines)"
fi
#  The oracle is kpScafKB's five lines inside kantParse1, sliced by name rather
#  than by a line number that any edit above it would silently invalidate.
sed -n '/^    kpScafKB code={/,/^    ;/p' incant/kantParse1 > "$T/hand2body"
{ echo "define"; cat "$T/hand2body"; } > "$T/hand2"
if [ ! -s "$T/hand2body" ]; then
    bad "R2 oracle for ScafKB is EMPTY -- the kpScafKB block was not found in incant/kantParse1"
elif diff "$T/hand2" "$T/emitted2" > "$T/d2" 2>&1; then
    pass "R2 ScafKB emitted == hand body, BYTE-IDENTICAL (oracle: incant/kantParse1)"
else
    bad "R2 ScafKB DIVERGES from the hand body -- byte-oracle dead for this rule:"
    sed 's/^/        /' "$T/d2" | head -20
fi

echo ""
#  --- H2 ON THE HARNESS ITSELF ----------------------------------------------
if [ "$checks" -lt 8 ]; then
    echo "RATCHET INVALID -- only $checks checks recorded, expected 8."
    echo "                   A check that evaporates is invisible in a count of checks."
    rm -rf "$T"; exit 1
fi
if [ $fail = 0 ]; then
    echo "RATCHET GREEN -- $checks checks. generate -> byte-compare -> install -> run,"
    echo "                 all on THIS run's output. Emitter reproduces the hand for: $RULE, ScafKB"
else
    echo "RATCHET RED -- $checks checks, see FAIL rows above."
fi
rm -rf "$T"
exit $fail
