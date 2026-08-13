#!/bin/sh
#  smoke.sh -- THE ITERATION BELL. Run from the Groups directory:
#      sh genLadder/smoke.sh
#
#  ===========================================================================
#  STATUS: WORK IN PROCESS, BY DESIGN (Tony, SEQ 60). Expect this file to
#  change as the frontier moves. The DURABLE part is the membership rule; the
#  names in the CONFIG block are today's values and are meant to be swapped.
#  Editing them to track the frontier is normal maintenance and wants no
#  dispatch. If this ever takes more than a minute to run or a screen to read,
#  it has drifted and wants cutting.
#
#  MEMBERSHIP RULE -- five slots, and the fifth is Clod's amendment:
#      1. the fixture under test        (today: bindSeamB)
#      2. its oracle                    (today: bindSeamA)
#      3. one same-door regression      (today: kantParse1)
#      4. one liveness canary           (today: oneTest)
#      5. FLEET UNMOVED                 (pop.sh diffed against a banked log)
#
#  ⚠ THE CITATION BOUNDARY, and it is the whole point of two tiers:
#  SMOKE-GREEN AUTHORIZES CONTINUING. ONLY A FLEET CHECK AUTHORIZES LANDING.
#  A smoke-green is never citable as fleet-green.
#  ===========================================================================
#
#  ⚠ WHY SLOT 5 EXISTS, AND IT IS A MEASURED CORRECTION TO THE PROPOSAL.
#  SEQ 60 assumed the two tiers trade seconds for coverage. Measured on this
#  machine, 2026-08-13:
#
#      oneTest 0.04s   jsonTest 0.03s   bindSeamA/B 0.03s   kantParse1 0.03s
#      THE ENTIRE pop.sh FLEET: 0.64s
#
#  So a four-fixture smoke run saves about half a second over the whole fleet.
#  THE SECONDS ARGUMENT DOES NOT HOLD. What actually costs the operator is not
#  time, it is SCREEN: pop.sh prints ~90 lines and currently ends in POP FAILED
#  on three pre-existing reds, so spotting whether YOUR change moved anything
#  means re-reading a wall of text every iteration. That is a signal problem,
#  not a speed problem -- so this file does not run a cheaper SUBSET of the
#  fleet, it runs the WHOLE fleet and reports it as ONE LINE.
#
#  ⚠ AND THE BINDING SENTENCE NEEDED ONE WORD CHANGED: **UNMOVED, NOT GREEN.**
#  pop.sh exits 1 today and has all session -- census.target, iterT1m and its
#  refusal count, and the oneTest baseline AUDIT block are red at the mark and
#  are owed a re-pin by someone else. "Only pop-GREEN authorizes landing" would
#  have blocked SEQ 56 and SEQ 58, both of which landed correctly against an
#  already-red fleet. The landable property is that the fleet did not MOVE,
#  measured against a capture banked before the first edit.
#
#  BANKING THE FLEET REFERENCE:  sh genLadder/smoke.sh --bank
#  Do that BEFORE the first edit of a work item, exactly as the both-streams
#  baselines are banked. Slot 5 is skipped-with-a-loud-line if none is banked;
#  it never passes by finding nothing (H4).
#
#  PLUMBING NOTES, all paid for on this project:
#   · $? is taken DIRECTLY from the binary, never through a pipe --
#     ${PIPESTATUS[0]} is silently empty in zsh and reports every run passing.
#   · No `script -q /dev/null` here. It is for crash backtraces; wrapping an
#     ordinary run mangles the capture (cost real confusion 2026-08-13).
#   · timeout(1) is not on macOS. Sleep-and-kill, 137 mapped to 124, and a
#     TIMEOUT is reported BY NAME and never as a content failure -- a killed
#     process yields truncated output and a truncation diff names the wrong row.
#   · H1: the binary is echoed FIRST, and this one goes further -- it FAILS if
#     the binary is older than the newest generated .mm. A stale binary does not
#     fail as a diff; it fails as a hang or a phantom, and twice this week a
#     rebuild came back byte-identical in SIZE so size alone proved nothing.
#   · H2 turned on the harness itself: the foot FAILS if zero checks ran, which
#     a vanished helper or a bad path cannot satisfy. Third instance of
#     copy-the-idiom-lose-the-helper on this project; pre-empted here.

#  ===========================  CONFIG -- swap freely  =======================
#  ⚠ AS SHIPPED TODAY SLOT 1 IS RED, ON PURPOSE. The frontier is the IA-2 cell
#  and it is NOT FIXED in the tree -- SEQ 59's rung 1 went green and was
#  REVERTED pending Tony's PC-1 ruling, so bindSeamB reads 1 where the oracle
#  reads 251. A standing red here is the frontier being open, not breakage.
#  When the ruling lands, slot 1 goes green and the frontier moves on.
FRONTIER=bindSeamB          # slot 1: the fixture under test
FRONTIER_WANT="sumple width is now 251"
FRONTIER_SENT="BINDSEAMB SENTINEL"

ORACLE=bindSeamA            # slot 2: its oracle
ORACLE_WANT="sumple width is now 251"
ORACLE_SENT="BINDSEAMA SENTINEL"

REGRESS=kantParse1          # slot 3: one same-door regression
CANARY=oneTest              # slot 4: one liveness canary
CANARY_FLOOR=300            # its documented failure is TRUNCATION at exit 0,
                            # so assert a line floor, not just exit+sentinel:
                            # an ExpressioN install once cost it 312 lines
                            # silently, which exit status could not see.
#  ===========================================================================

B=${INCANT:-$HOME/bin/incant}
T=${TMPDIR:-/tmp}/smoke.$$
CAP=${POPCAP:-30}
BANK=genLadder/smoke.fleet.base
mkdir -p "$T"
fail=0
checks=0

pass () { echo "  ok    $1"; checks=$((checks+1)); }
bad  () { echo "  FAIL  $1"; shift; [ -n "$1" ] && echo "        $*"; fail=1; checks=$((checks+1)); }

#  --- H5: run a fixture under a wall-clock cap, exit status taken directly ---
#  ⚠ THESE LOCALS ARE PREFIXED cap_ ON PURPOSE. sh has no function scope, so
#  the first cut used _p/_w/_rc here and _s/_w/_l in row() -- and the watchdog
#  PID silently overwrote the wanted STRING, so every row compared its output
#  against a five-digit process id and reported FAIL with `want: 80340`. It was
#  caught in one run only because the row prints the value it wanted (H4); a
#  bare pass/fail would have read as a real red on three slots.
runcap () {                       # runcap <fixture> <outfile>
    $B "incant/$1" > "$2" 2>&1 &
    cap_pid=$!
    { ( sleep "$CAP"; kill -9 $cap_pid 2>/dev/null ) >/dev/null 2>&1 & } 2>/dev/null
    cap_wd=$!
    wait $cap_pid; cap_st=$?
    { kill $cap_wd 2>/dev/null; wait $cap_wd 2>/dev/null; } 2>/dev/null
    [ $cap_st = 137 ] && cap_st=124
    return $cap_st
}

#  --- slots 1-4 share one shape: ran, did not truncate, said the right thing --
row () {                          # row <fixture> <sentinel|-> <want|-> <label>
    _f=$1; _s=$2; _w=$3; _l=$4
    runcap "$_f" "$T/$_f"; _rc=$?
    if [ $_rc = 124 ]; then bad "$_l -- TIMEOUT after ${CAP}s (a hang is not a wrong answer)"; return; fi
    if [ $_rc != 0 ];  then bad "$_l -- exit $_rc"; return; fi
    if [ "$_s" != "-" ] && ! grep -q "$_s" "$T/$_f"; then
        bad "$_l -- sentinel absent, run TRUNCATED; every other ok in it is uninterpretable"; return; fi
    if [ "$_w" != "-" ] && ! grep -q "$_w" "$T/$_f"; then
        bad "$_l" "want: $_w" ; grep -o 'sumple width is now [0-9]*' "$T/$_f" | sed 's/^/        got:  /'; return; fi
    pass "$_l"
}

if [ ! -x "$B" ]; then echo "  FAIL  binary not executable: $B"; exit 1; fi
echo "  bin   $B"
echo "  bin   $(ls -lL "$B" | awk '{print $5" bytes  "$6" "$7" "$8}')"

#  --- H1+, THE STALENESS GUARD. Size is not proof: two rebuilds this week came
#      back byte-identical in size. Compare mtimes against generated sources. ---
newest=$(ls -t *.mm 2>/dev/null | head -1)
if [ -n "$newest" ] && [ "$newest" -nt "$B" ]; then
    bad "STALE BINARY -- $newest is newer than $B. Rebuild before reading anything below."
    echo ""
    echo "SMOKE ABORTED -- a stale binary fails as a hang or a phantom, not as a diff."
    rm -rf "$T"; exit 1
else
    pass "binary is newer than the newest generated .mm"
fi

echo ""
row "$FRONTIER" "$FRONTIER_SENT" "$FRONTIER_WANT" "1 frontier   $FRONTIER"
row "$ORACLE"   "$ORACLE_SENT"   "$ORACLE_WANT"   "2 oracle     $ORACLE"
row "$REGRESS"  "-"              "-"              "3 same-door  $REGRESS"

#  slot 4 -- liveness, plus the line floor its own recorded failure needs
runcap "$CANARY" "$T/canary"; rc=$?
lines=$(wc -l < "$T/canary" | tr -d ' ')
if   [ $rc = 124 ]; then bad "4 liveness   $CANARY -- TIMEOUT after ${CAP}s"
elif [ $rc != 0 ];  then bad "4 liveness   $CANARY -- exit $rc"
elif [ "$lines" -lt "$CANARY_FLOOR" ]; then
    bad "4 liveness   $CANARY -- only $lines lines, floor $CANARY_FLOOR (silent truncation at exit 0)"
else pass "4 liveness   $CANARY ($lines lines, floor $CANARY_FLOOR)"
fi

#  --- slot 5 -- THE WHOLE FLEET, AS ONE LINE. 0.64s, so it is not a luxury. ---
if [ "$1" = "--bank" ]; then
    sh genLadder/pop.sh 2>&1 | grep -v '^  bin \|^  tree \|^          Groups \|^          support ' > "$BANK"
    echo ""
    echo "  BANKED  fleet reference -> $BANK  ($(wc -l < "$BANK" | tr -d ' ') lines)"
    echo "          Slot 5 will diff against this until you bank again."
    rm -rf "$T"; exit 0
fi

if [ ! -s "$BANK" ]; then
    bad "5 fleet     NO BANKED REFERENCE -- run 'sh genLadder/smoke.sh --bank' before your first edit."
    echo "        Reported as a FAILURE, not skipped: a slot that passes by finding nothing is an absence check."
else
    sh genLadder/pop.sh 2>&1 | grep -v '^  bin \|^  tree \|^          Groups \|^          support ' > "$T/fleet"
    if diff "$BANK" "$T/fleet" > "$T/fd" 2>&1; then
        pass "5 fleet     UNMOVED against $BANK ($(wc -l < "$BANK" | tr -d ' ') lines)"
        echo "        NB: unmoved, NOT green. pop.sh carries pre-existing reds; this asserts your change did not move them."
    else
        bad "5 fleet     MOVED -- name every moved row before continuing:"
        sed 's/^/        /' "$T/fd" | head -40
    fi
fi

echo ""
#  --- H2 ON THE HARNESS ITSELF: a vanished helper cannot satisfy this. ---
if [ "$checks" -lt 6 ]; then
    echo "SMOKE INVALID -- only $checks checks recorded, expected 6."
    echo "                 A check that evaporates is invisible in a count of checks."
    rm -rf "$T"; exit 1
fi
if [ $fail = 0 ]; then
    echo "SMOKE GREEN -- $checks checks. Authorizes CONTINUING, never landing."
else
    echo "SMOKE RED   -- $checks checks, see FAIL rows above."
fi
rm -rf "$T"
exit $fail
