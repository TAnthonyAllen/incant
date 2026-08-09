#!/bin/sh
#  GAP B / PHASE R -- the per-family rung POP.  Run from the Groups directory:
#      sh genLadder/gapB.sh
#
#  The charter (docs/gapBCharter.md section 2) puts each family's plan-layer
#  treatment in its own rung with its own POP, and section 4 demands TWO NUMBERS
#  at every rung, never conflated. This is that harness. Rung 1 = Family B
#  (LITERAL): SemI, loopOnAttributes, loopOnMembers.
#
#  A SEPARATE SCRIPT, NOT LINES IN pop.sh, for pop.sh's own stated reason: it
#  carries the genParse ladder's baselines and has three owned reds. A Gap B
#  rung has no business moving that file's exit status, and its reds must not
#  hide behind pop.sh's.
#
#  ⚠ RULE H1 -- THE HARNESS ECHOES THE BINARY IT IS TESTING, first output.
#  ⚠ RULE H2 -- the sentinel is checked FIRST and BY NAME; an incant parse
#     failure abandons the rest of the file AND STILL EXITS 0 (GRAM-8), so exit
#     0 alone certifies nothing. And this harness certifies ITSELF at the foot:
#     zero green checks recorded is a FAILURE, because a vanished helper set
#     cannot satisfy it (the missing-`sentinel` and three-`stop()` cases).
#  ⚠ RULE H4 -- every quantity is PRINTED AND COMPARED BY VALUE. Nothing here
#     passes because a line is absent.
#  ⚠ $? IS TAKEN DIRECTLY, NEVER THROUGH A PIPE -- ${PIPESTATUS[0]} is silently
#     empty in zsh and reports every run as passing.
#  ✅ RULE H7 -- THE NEGATIVE CONTROL, MEASURED 2026-08-09 AND NOT INFERRED.
#  A rung certifies only what fails when the mechanism is removed. Every
#  assertion below was run against the MECHANISM-ABSENT capture (phaseA's output
#  from the binary immediately before the Family B treatment landed):
#
#      row                              mechanism absent    this rung wants
#      TALLY lines                      0 lines             2          -> RED
#      ruling-4 refusals                97                  94         -> RED
#      ruling-4 plannable               13                  16         -> RED
#      Gap B branch reach               21                  18         -> RED
#      Family B x3, LITTO literal       '' (no LITTO node)  ; attributes members
#                                                                      -> RED x6
#      -------------------------------------------------------------------
#      11 rows RED without the mechanism.
#
#  ⚠ AND THE OTHER HALF, WHICH IS WHAT MAKES IT A CONTROL RATHER THAN A
#  GUARANTEED FAILURE: the five negative-control rows STAY GREEN on that same
#  capture (nameSet isSET, Attributes isGROUP, counter isCOUNT, FloaT isCHAR,
#  Any isANY). So the rung DISCRIMINATES -- it is not a script that reddens on
#  any old input, which is the way a negative control usually lies.
B=${INCANT:-$HOME/bin/incant}
T=${TMPDIR:-/tmp}/gapb.$$
mkdir -p "$T"
fail=0
green=0

check () {                      # check <name> <expected> <actual>
    if [ "$2" = "$3" ]; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 (got '$3', want '$2')"; fail=1; fi
}
sentinel () {                   # sentinel <name> <file> <text>
    if grep -qF "$3" "$2"; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 -- THE RUN TRUNCATED. A statement stopped parsing and"
         echo "        every statement after it was silently dropped, at exit 0."
         echo "        Every other result in this run is uninterpretable."; fail=1; fi
}

echo "=== GAP B / PHASE R RUNG POP ==============================================="
if [ -x "$B" ]; then
    echo "binary: $B"
    ls -lL "$B" | awk '{print "        size " $5 "   mtime " $6 " " $7 " " $8}'
else
    echo "  FAIL  binary not found or not executable: $B"; fail=1
fi

# --------------------------------------------------------------------------
echo ""
echo "-- THE CENSUS FIXTURE. incant/phaseA is the ruling-4 instrument, and"
echo "   Amendment A says NO RUNG MAY CITE AN UNVERIFIED ORACLE -- so its"
echo "   existence, completeness and reach are asserted here, not assumed."
$B incant/phaseA > "$T/pa.o" 2> "$T/pa.e"
check "phaseA runs" 0 $?
sentinel "phaseA sentinel (walk reached the end)" "$T/pa.e" "PHASEA SENTINEL"

#  ⚠ A1, phaseA's OWN completeness guard, asserted from outside. A rule with a
#  PLAN and no DONE is an incomplete walk, and it must never be scored as a
#  refusal. Both counts are printed and compared -- an absence check here would
#  pass on an empty file.
np=$(grep -c '^PLAN ' "$T/pa.e")
nd=$(grep -c '^DONE ' "$T/pa.e")
check "phaseA A1: PLAN lines = 78"  78 "$np"
check "phaseA A1: DONE lines = 78"  78 "$nd"
check "phaseA A1: PLAN == DONE"     "$np" "$nd"

#  Amendment A's REACH clause: the instrument must demonstrably arrive at the
#  Gap B branch (genParse.rtn's rule-level-data refusal), not merely run.
#  ⚠ THIS IS A NON-ZERO EXPECTATION ON PURPOSE. It falls as families land, and
#  when it reaches 0 Gap B's rule-level surface is closed -- at which point this
#  row is the one that says so.
rl=$(grep -c 'rule-level data' "$T/pa.e")
check "phaseA reaches the Gap B branch (rule-level-data refusals)" 18 "$rl"

# --------------------------------------------------------------------------
echo ""
echo "-- RULING-4: TWO NUMBERS, PRINTED AS SCALARS, NEVER CONFLATED (H4)."
echo "   Assigned to this rung by Tony 2026-08-09: until now BOTH were derived"
echo "   by grepping output, and a quantity nobody prints is one that drifts."
tr_=$(sed -n 's/^TALLY refusals = *\([0-9][0-9]*\).*/\1/p'  "$T/pa.e" | head -1)
tp=$(sed -n 's/^TALLY plannable = *\([0-9][0-9]*\).*/\1/p' "$T/pa.e" | head -1)
check "ruling-4 total plan-layer refusals = 94" 94 "$tr_"
check "ruling-4 fully-plannable rules     = 16" 16 "$tp"

#  ⚠ THE CHEAP INSTRUMENT GUARDS THE CHEAP COUNTER. planTally counts at three
#  sites rather than seventeen, licensed by a MEASURED invariant: every refusal
#  line is followed by a `return null`, and planRule stops at its first bad
#  term. A future two-line refusal path would break that silently and move the
#  metric with it. So the printed scalar is cross-checked against the grep every
#  run -- if these two ever disagree, the invariant is what died, not the count.
gr=$(grep -c 'REFUSE' "$T/pa.e")
gp=$(awk '/^PLAN /{r=$2} /^  (SEQ|ALT) /{print r}' "$T/pa.e" | sort -u | wc -l | tr -d ' ')
check "printed refusals == grepped refusals (tally invariant holds)" "$gr" "$tr_"
check "printed plannable == walked plannable (tally invariant holds)" "$gp" "$tp"

#  The partition must close. 78 rules, each either fully plannable or refused
#  somewhere; a gap means the walk lost one.
nref=$(awk '/^PLAN /{r=$2} /REFUSE/{print r}' "$T/pa.e" | sort -u | wc -l | tr -d ' ')
tot=$((tp + nref))
check "partition closes: plannable + refused = 78" 78 "$tot"

# --------------------------------------------------------------------------
echo ""
echo "-- RUNG 1: FAMILY B (LITERAL) -- SemI, loopOnAttributes, loopOnMembers."
echo "   A rule whose OWN data is a quoted literal now plans as the LIT/LITTO"
echo "   planTerm already emits for a literal in TERM position."
#  ⚠ ASSERT THE LITERAL TEXT BY NAME, NOT MERELY THAT A PLAN EXISTS.
#  Bear-trap #26: a field with no data returns its own TAG from .text, so a
#  wrong reading here arrives as `LITTO SemI` -- a plausible string that is the
#  identifier rather than the value. "It planned" cannot tell those apart; the
#  literal text can, and it is the whole point of the family.
famB () {                       # famB <rule> <expected-literal>
    got=$(awk -v R="$1" '/^PLAN /{p=($2==R)} p' "$T/pa.e" \
          | sed -n 's/^    LITTO \(.*\)$/\1/p' | head -1)
    check "Family B $1 plans LITTO with literal '$2'" "$2" "$got"
    slot=$(awk -v R="$1" '/^PLAN /{p=($2==R)} p' "$T/pa.e" \
          | sed -n 's/^      slot=\(.*\)$/\1/p' | head -1)
    check "Family B $1 attaches its own label (slot)" "$1" "$slot"
}
famB SemI             ";"
famB loopOnAttributes "attributes"
famB loopOnMembers    "members"

#  ⚠ NEGATIVE CONTROL (RULE H7). A rung certifies only what fails when the
#  mechanism is removed -- and this family's treatment is deliberately isSTRING
#  ONLY, so the OTHER five kinds must still refuse. Widening the test to
#  `rule.data` would re-merge the three constructs the taxonomy exists to
#  separate, and it would pass every row above while doing it.
echo ""
echo "-- NEGATIVE CONTROL: the other five data kinds MUST still refuse (H7)."
for pair in "nameSet:isSET" "Attributes:isGROUP" "counter:isCOUNT" "FloaT:isCHAR" "Any:isANY"; do
    r=${pair%%:*}; k=${pair##*:}
    got=$(grep "REFUSE rule $r -- rule-level data" "$T/pa.e" | awk '{print $7}')
    check "still refused: $r ($k)" "$k" "$got"
done

# --------------------------------------------------------------------------
#  ⚠ H2 TURNED ON THE HARNESS ITSELF. A check that EVAPORATES -- a helper that
#  is called but never defined -- is invisible in a count of checks, because
#  nobody knows what the count should have been. This foot assertion cannot be
#  satisfied by a vanished helper set, and it is unreachable except by reaching
#  the end.
echo ""
if [ "$green" -lt 20 ]; then
    echo "  FAIL  SELF-CERTIFICATION: only $green green checks recorded, expected"
    echo "        at least 20. Either helpers vanished or the run stopped early."
    fail=1
fi
echo "checks green = $green"
if [ $fail = 0 ]; then
    echo "GAP B RUNG POP PASSED -- rung 1 (Family B, LITERAL) green."
    echo "  ruling-4: refusals $tr_ (was 97) . plannable $tp of 78 (was 13)"
    exit 0
else
    echo "GAP B RUNG POP FAILED -- see the rows above."
    exit 1
fi
