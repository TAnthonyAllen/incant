#!/bin/sh
#  RECORD POP -- ParsE and JiT, the per-rule/per-action audit records (PJ).
#  Run from the Groups directory:   sh genLadder/recordPop.sh
#
#  WHAT IT CERTIFIES. genParse hangs the generated parse source on the rule as a
#  noPrint `ParsE` attribute; jitRunAction hangs the post-mem2reg IR on the
#  action as a noPrint `JiT` attribute. Both are RECORDS: written by the thing
#  that produced the fact, never read by execution. This script asserts that
#  each record exists, carries the right bytes, is per-entity rather than a
#  stale global, updates in place on a second pass, and -- the check that
#  matters most -- CANNOT MOVE A BASELINE when its dump hook is not armed.
#
#  A SEPARATE SCRIPT, NOT LINES ADDED TO pop.sh. pop.sh carries the genParse
#  ladder's baselines and three deliberately-owned reds; a record-layer change
#  has no business moving that file's exit status, and this file's exit status
#  should not be hostage to those three reds either.
#
#  ⚠ EXIT 0 IS NOT ENOUGH. An incant parse failure ABANDONS THE REST OF THE FILE
#  AND STILL EXITS 0 (grammarCorpus CLAIM GRAM-8), so every fixture carries a
#  sentinel printed as its last statement and it is checked FIRST and by name.
#
#  ⚠ $? IS TAKEN DIRECTLY, NEVER THROUGH A PIPE. ${PIPESTATUS[0]} is silently
#  empty in zsh and reports every run as passing.
#
#  ⚠ EVERY HELPER THIS FILE CALLS IS DEFINED IN THIS FILE. That sentence is here
#  because "copy the idiom, lose the helper" has now happened three times in
#  this tree (incant/jiquery's three stop()s, pop.sh's missing sentinel, the JIT
#  ladder's missing check/sentinel at JPd and JPl). A vanished helper does not
#  fail -- the check CEASES TO EXIST, and a green count cannot show you a check
#  that is not in it. The foot of this file therefore certifies ITSELF: if zero
#  green checks were recorded, the run FAILS regardless of what else happened.

B=${INCANT:-$HOME/bin/incant}
T=${TMPDIR:-/tmp}/recordpop.$$
mkdir -p "$T"
fail=0
green=0

#  ---- helpers (all of them, see the note above) ------------------------------
check () {                      # check <name> <expected-exit> <actual-exit>
    if [ "$2" = "$3" ]; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 (exit $3)"; fail=1; fi
}
diffcheck () {                  # diffcheck <name> <expected-file> <actual-file>
    if diff "$2" "$3" > "$T/d" 2>&1; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1"; sed 's/^/          /' "$T/d"; fail=1; fi
}
differs () {                    # differs <name> <file-a> <file-b>  -- must NOT match
    if diff "$2" "$3" > /dev/null 2>&1; then
        echo "  FAIL  $1 -- the two records are IDENTICAL, so the record is not"
        echo "        per-entity. A stale global would pass every other check here."
        fail=1
    else echo "  ok    $1"; green=$((green+1)); fi
}
nonempty () {                   # nonempty <name> <file>   -- H4 + the vacuity guard
    if [ -s "$2" ]; then echo "  ok    $1 ($(wc -c < "$2" | tr -d ' ') bytes)"; green=$((green+1))
    else echo "  FAIL  $1 -- EMPTY or ABSENT. Note a diff of two empty files"
         echo "        passes, which is why this guard runs BEFORE any diff."; fail=1; fi
}
hasmark () {                    # hasmark <name> <file> <text>
    if grep -qF "$3" "$2"; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 -- marker '$3' absent"; fail=1; fi
}
sentinel () {                   # sentinel <name> <file> <text>
    if grep -qF "$3" "$2"; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 -- THE RUN TRUNCATED. A statement stopped parsing and"
         echo "        every statement after it was silently dropped, at exit 0."
         echo "        Find the statement that stopped parsing, not the row that"
         echo "        diffed."; fail=1; fi
}

#  ---- wall-clock cap (RULE H5). timeout(1) is not on macOS; 137 is the SIGKILL
#  that sleep-and-kill produces, mapped to 124 so it reads like GNU timeout's.
#  A timeout is reported BY NAME and never as a diff: a killed process yields a
#  truncated capture, and a truncation diff names the wrong row.
POPCAP=${POPCAP:-90}
_cap () {                       # _cap <label> -- caller has already redirected
    _p=$!
    { ( sleep "$POPCAP"; kill -9 $_p 2>/dev/null ) >/dev/null 2>&1 & } 2>/dev/null
    _w=$!
    wait $_p; _ec=$?
    { kill $_w 2>/dev/null; wait $_w 2>/dev/null; } 2>/dev/null
    if [ $_ec = 137 ]; then
        echo "  FAIL  $1 TIMED OUT after ${POPCAP}s -- KILLED, not failed."
        echo "        Its capture is TRUNCATED, so every check below it would"
        echo "        name the wrong thing. Fix the hang first."
        fail=1
        return 124
    fi
    return $_ec
}
#  split streams: stdout carries the sentinel, stderr carries the emission.
runrec () {                     # runrec <fixture> <out> <err> [VAR=value ...]
    _f=$1; _o=$2; _e=$3; shift 3
    env "$@" $B "incant/$_f" > "$_o" 2> "$_e" & _cap "$_f"
}

#  ---- RULE H1: a harness echoes the binary it is testing, FIRST. -------------
#  A stale binary does not fail as a diff, it HANGS -- which reads as an
#  infinite loop in whatever you last touched.
echo "  bin   $B"
if [ -e "$B" ]; then
    echo "  bin   $(wc -c < "$B" | tr -d ' ') bytes  $(date -r "$B" '+%b %e %H:%M')"
else
    echo "  FAIL  binary $B DOES NOT EXIST"; fail=1
fi
echo ""

echo "-- ParsE: the generated parse source, recorded on the rule."

runrec recordPT "$T/pt.o" "$T/pt.e" INCANT_PARSE_RECORD="$T/pt.rec"
check    "recordPT runs" 0 $?
sentinel "recordPT sentinel (no truncation)" "$T/pt.o" "RECORDPT SENTINEL"
#  Vacuity guard BEFORE the diff. Two empty files diff clean, so an unwritten
#  record would otherwise report byte-identical and assert nothing at all.
nonempty "ParsE record is non-empty" "$T/pt.rec"
nonempty "the emission itself is non-empty" "$T/pt.e"
#  THE ORACLE. Two independent channels of one fact: what the emitter WROTE
#  (stderr) and what LANDED ON THE NODE (the record, read back through
#  pe->getText()). Byte-identical or the record is lying.
diffcheck "ParsE record == emitted text, byte for byte" "$T/pt.rec" "$T/pt.e"
hasmark  "ParsE carries the generated function by name" "$T/pt.rec" "parseBraced"

echo "-- ParsE: the hook cannot move a baseline (the 2026-08-02 lesson)."

#  An instrument that adds bytes to a measured stream broke three POP targets on
#  2026-08-02 -- printFamily.target diffed 0a1,288, lines PREPENDED, zero content
#  divergence. So the dump hook is env-gated, and THIS is the check that the
#  gating actually holds: same fixture, variable unset, stderr identical.
runrec recordPT "$T/pt2.o" "$T/pt2.e" INCANT_UNUSED_PROBE=1
check    "recordPT runs with the hook UNARMED" 0 $?
sentinel "recordPT unarmed sentinel" "$T/pt2.o" "RECORDPT SENTINEL"
diffcheck "stderr identical armed vs unarmed (hook adds no bytes)" "$T/pt.e" "$T/pt2.e"
diffcheck "stdout identical armed vs unarmed" "$T/pt.o" "$T/pt2.o"
if [ -e "$T/pt2.rec" ]; then
    echo "  FAIL  unarmed run wrote a record file anyway"; fail=1
else
    echo "  ok    unarmed run writes no record file"; green=$((green+1))
fi

echo "-- ParsE: the gate arms the RECORD, not just a dump of it (PJ-7)."

#  ONE GATE, THREE STATES: unset = nothing at all; =1 = capture + attribute;
#  =<path> = capture + attribute + file. The attribute itself is gated because
#  an always-on write changes the attribute LIST of every rule genParse touches,
#  and this tree BASELINES attribute lists (pop.sh's census walks registries
#  counting terms and loose entries). A record that can move an audit is an
#  instrument that can move a measurement -- the 2026-08-02 defect exactly.
runrec recordPT4 "$T/p4.o" "$T/p4.e" INCANT_PARSE_RECORD=1
check    "recordPT4 runs with the gate at =1" 0 $?
sentinel "recordPT4 sentinel (no truncation)" "$T/p4.o" "RECORDPT4 SENTINEL"
#  THE DIRECTOR'S WINDOW. showParse resolves the rule by NAME through
#  ruleOrRefuse, because naming a rule in expression position INVOKES it --
#  `print Braced.ParsE;` prints nothing and `if Braced;` exits 139, both
#  measured. So this command is the only read path from inside a fixture.
hasmark "showParse prints the recorded source (director's window)" \
        "$T/p4.o" "extern GroupItem parseBraced(GroupItem rule)"
hasmark "showParse's output is the WHOLE record, to its last line" \
        "$T/p4.o" "bind:  Braced parseTerms=3 parseMethod=parseBraced;"
if [ -e "$T/p4.rec" ]; then
    echo "  FAIL  =1 wrote a file; that mode is attribute-only"; fail=1
else
    echo "  ok    =1 arms the attribute and writes NO file"; green=$((green+1))
fi

#  GATE CLOSED. Not an absence check dressed up: showParse prints a NAMED line
#  saying the record is absent, so this asserts a value rather than a silence.
#  An instrument whose quiet means two different things (no record / no output)
#  is the one-channel-one-meaning failure.
runrec recordPT4 "$T/p4c.o" "$T/p4c.e" INCANT_UNUSED_PROBE=1
check    "recordPT4 runs with the gate CLOSED" 0 $?
sentinel "recordPT4 gate-closed sentinel" "$T/p4c.o" "RECORDPT4 SENTINEL"
hasmark  "gate closed -> showParse says so BY NAME" \
         "$T/p4c.o" "has no ParsE record"
if grep -qF "extern GroupItem parseBraced" "$T/p4c.o"; then
    echo "  FAIL  gate closed but a record was printed anyway"; fail=1
else
    echo "  ok    gate closed -> no record exists to print"; green=$((green+1))
fi
diffcheck "recordPT4 stderr identical, gate open vs closed" "$T/p4.e" "$T/p4c.e"

echo "-- ParsE: second pass on the SAME rule (bear-trap #22 coverage rule)."

#  An action's body is parsed ONCE into a cached BlocK and RE-EXECUTED, so a
#  statement that damages its own nodes reads correctly the first time and wrong
#  every time after. A fixture that exercises a feature ONCE cannot see it. This
#  one calls genParse on Braced twice, which is also the only way to reach the
#  `else setText(...)` update-in-place arm.
runrec recordPT2 "$T/p2.o" "$T/p2.e" INCANT_PARSE_RECORD="$T/p2.rec"
check    "recordPT2 runs" 0 $?
sentinel "recordPT2 sentinel (no truncation)" "$T/p2.o" "RECORDPT2 SENTINEL"
nonempty "ParsE record after two passes is non-empty" "$T/p2.rec"
#  The record must hold ONE emission, not two concatenated: the second pass
#  REPLACES. The emission stream holds two, so the record must equal the first
#  one exactly -- which is also the second one, the emitter being deterministic.
diffcheck "second pass REPLACES, does not append (record == one emission)" \
          "$T/pt.rec" "$T/p2.rec"
_ptn=$(wc -c < "$T/pt.e" | tr -d ' ')
_p2n=$(wc -c < "$T/p2.e" | tr -d ' ')
_want=$((_ptn * 2))
if [ "$_p2n" = "$_want" ]; then
    echo "  ok    two passes emitted twice the bytes ($_p2n = 2 x $_ptn)"; green=$((green+1))
else
    echo "  FAIL  two passes emitted $_p2n bytes, expected $_want (2 x $_ptn) --"
    echo "        so the second pass did not emit, and the record's stability"
    echo "        above proves nothing."; fail=1
fi

echo "-- ParsE: per-rule, not a stale global."

runrec recordPT3 "$T/p3.o" "$T/p3.e" INCANT_PARSE_RECORD="$T/p3.rec"
check    "recordPT3 runs" 0 $?
sentinel "recordPT3 sentinel (no truncation)" "$T/p3.o" "RECORDPT3 SENTINEL"
nonempty "Parens ParsE record is non-empty" "$T/p3.rec"
diffcheck "Parens record == its own emission" "$T/p3.rec" "$T/p3.e"
hasmark  "Parens record names ITS function" "$T/p3.rec" "parseParens"
differs  "Braced and Parens records differ (per-rule)" "$T/pt.rec" "$T/p3.rec"

echo "-- JiT: the IR, recorded on the action, via the jitRunAction route."

#  THE POINT OF THIS SECTION. The JiT record used to be hung by jitFieldMethod
#  -- the fallback-column route only -- so every rung that reaches jitRunAction
#  directly (testing(), the whole jit ladder) left NO record and nothing said
#  so. The write now lives at the capture site inside jitRunAction, the only
#  function in the tree that compiles, so every compile records whoever drove
#  it. jitJ1 goes through testing(), NOT jitFieldMethod: before the move this
#  section could not have passed.
runrec jitJ1 "$T/j1.o" "$T/j1.e" INCANT_JIT_RECORD="$T/j1.ir"
check    "jitJ1 runs" 0 $?
nonempty "JiT record written on the jitRunAction route" "$T/j1.ir"
hasmark  "JiT names the function by action identity" "$T/j1.ir" "@jit_jitJ1"
#  H4: presence-with-value on the degrade counter, printed unconditionally by
#  jitRunAction on every fire. Asserting "the degrade message is absent" would
#  go green the day the message is deleted.
if grep -q "jitDegrade count = 0" "$T/j1.o" "$T/j1.e" 2>/dev/null; then
    echo "  ok    jitJ1 degrade count 0"; green=$((green+1))
else
    echo "  FAIL  jitJ1 degrade count is not 0 (or was not printed at all)"; fail=1
fi

runrec jitJ2 "$T/j2.o" "$T/j2.e" INCANT_JIT_RECORD="$T/j2.ir"
check    "jitJ2 runs" 0 $?
nonempty "JiT record for the branching rung" "$T/j2.ir"
hasmark  "JiT names jitJ2's function" "$T/j2.ir" "@jit_jitJ2"
#  ASSERT DEPTH BY NAME. j1 and j2 would both satisfy "non-empty IR"; only the
#  branch rung can contain a conditional branch, so this is the check that the
#  record is the RIGHT IR and not merely some IR.
hasmark  "branching rung's IR contains a conditional branch" "$T/j2.ir" "br i1"
differs  "jitJ1 and jitJ2 records differ (per-action)" "$T/j1.ir" "$T/j2.ir"

echo "-- NEGATIVE CONTROLS (RULE H7: certify only what fails when the mechanism goes)."

#  NC-1 IS THE DECISIVE ONE. The JiT section above would be worthless if jitJ1
#  reached jitFieldMethod, because jitFieldMethod hung the record BEFORE this
#  change and the section would go green either way. It does not: jitJ1 goes
#  through testing() -> jitRunAction, so the record on this route can only come
#  from the moved write. Measured, not assumed -- the run is asserted to mention
#  jitFieldMethod ZERO times and to name jitRunAction by entry.
if grep -q "jitFieldMethod" "$T/j1.o" "$T/j1.e" 2>/dev/null; then
    echo "  FAIL  NC-1: jitJ1 DOES reach jitFieldMethod, so the JiT section above"
    echo "        would pass with or without the write having moved. It certifies"
    echo "        nothing. Pick a rung that does not take the fallback column."
    fail=1
else
    echo "  ok    NC-1 jitJ1 never reaches jitFieldMethod (record proves the move)"
    green=$((green+1))
fi
hasmark "NC-1b jitJ1 entered jitRunAction by name" "$T/j1.o" "jitRunAction: entering on jitJ1"

#  NC-2: a run that compiles nothing must write no record. Without this, every
#  "record is non-empty" check above could in principle be passing on a file
#  left behind by something else.
rm -f "$T/nc2.ir"
runrec recordPT "$T/nc2.o" "$T/nc2.e" INCANT_JIT_RECORD="$T/nc2.ir"
check "NC-2 a non-jitting fixture runs" 0 $?
if [ -e "$T/nc2.ir" ]; then
    echo "  FAIL  NC-2: a record appeared for a run that compiled nothing"; fail=1
else
    echo "  ok    NC-2 no compile -> no JiT record"; green=$((green+1))
fi

echo "-- JiT: the hook cannot move a baseline either."

runrec jitJ1 "$T/j1b.o" "$T/j1b.e" INCANT_UNUSED_PROBE=1
check     "jitJ1 runs with the hook UNARMED" 0 $?
diffcheck "jitJ1 stdout identical armed vs unarmed" "$T/j1.o" "$T/j1b.o"
diffcheck "jitJ1 stderr identical armed vs unarmed" "$T/j1.e" "$T/j1b.e"

echo ""
#  ---- RULE H2, TURNED ON THE HARNESS ITSELF --------------------------------
#  A green count is a tally of the checks that RAN. A check that evaporates --
#  because a helper went missing in a copy -- is INVISIBLE in a count of checks,
#  since nobody knows what the number should have been. So the foot asserts that
#  the run recorded green checks AT ALL, which a vanished helper set cannot
#  satisfy: with the helpers gone, `green` never increments and this fires.
if [ "$green" -lt 1 ]; then
    echo "RECORD POP FAILED -- ZERO green checks were recorded."
    echo "  That is not 'everything failed'. It is almost certainly a HELPER that"
    echo "  does not exist: the shell prints 'command not found' to stderr and"
    echo "  carries on, so the checks did not pass and did not fail -- they ceased"
    echo "  to exist. Check that check/diffcheck/differs/nonempty/hasmark/sentinel"
    echo "  are all still defined ABOVE their first use."
    fail=1
fi

if [ $fail = 0 ]; then echo "RECORD POP PASSED -- $green checks, ParsE + JiT"
else echo "RECORD POP FAILED -- $green green, see above"; fi
rm -rf "$T"
exit $fail
