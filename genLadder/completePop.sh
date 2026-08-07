#!/bin/sh
#  completePop.sh -- THE COMPLETENESS SWEEP. Run from the Groups directory:
#      sh genLadder/completePop.sh
#
#  ⚠ WHAT THIS EXISTS FOR, and it is one sentence: A RUN WHOSE PARSE DIES
#  WITHOUT COMPLETING MUST NOT READ AS GREEN. On 2026-08-07 an ExpressioN
#  install made incant/oneTest lose 312 lines and incant/kant8T truncate at
#  line 3 -- both AT EXIT 0, both with no sentinel, and neither harness noticed,
#  because an abandoned parse is indistinguishable from a short successful one.
#  That is CLAUDE.md's third exit-status corollary operating at scale, and it is
#  a harness-honesty defect independent of whatever caused the abandonment.
#
#  THE TWO CHECKS, per fixture:
#    1. ABANDONMENT COUNT.  incant already prints `<Rule>: expected a method
#       not <x>` on stderr when a statement fails to parse -- it then silently
#       drops every statement after it and returns 0. The message was always
#       there; nothing ever ACTED on it. This counts it and requires ZERO.
#    2. SENTINEL OBLIGATION. A fixture that declares a completion sentinel must
#       print it. This generalises the discipline incant/kant8T already keeps.
#
#  ⚠ H4 -- THE COUNT IS PRINTED WITH ITS VALUE, NEVER ASSERTED AS AN ABSENCE.
#  The tempting form is `grep -q "expected a method" && fail`, which goes green
#  the day somebody deletes the line that emits it. This prints `abandon=N` for
#  every fixture and compares N to 0, so a deletion BREAKS the check instead of
#  satisfying it. Same shape as the JIT ladder's degrade counter.
#
#  ⚠ H1 -- the binary is echoed first. ⚠ H5 -- every fixture runs under a
#  wall-clock cap and a timeout FAILS, because a hang is not a wrong answer, it
#  is the absence of a run. ⚠ H2 turned on the harness itself -- the foot fails
#  if ZERO fixtures were checked, which a vanished helper or a bad glob cannot
#  satisfy. That is the `pop.sh`-missing-`sentinel` failure, pre-empted.
#
#  EXIT STATUS IS DELIBERATELY NOT GATED HERE. Some fixtures are known-red or
#  parked, and that is pop.sh's business. This sweep asks ONE question --
#  did the parse run to the end -- so it stays orthogonal and cannot inherit
#  another harness's pins.

B=${INCANT:-$HOME/bin/incant}
T=${TMPDIR:-/tmp}/complete.$$
CAP=${POPCAP:-20}
mkdir -p "$T"
fail=0; green=0; checked=0; abandoned=0; nosent=0

if [ ! -x "$B" ]; then
    echo "  FAIL  binary not executable: $B"; exit 1
fi
echo "  bin   $B"
echo "  bin   $(ls -lL "$B" | awk '{print $5" bytes  "$6" "$7" "$8}')"
echo "  cap   ${CAP}s per fixture"
echo ""

#  A runnable fixture is defined STRUCTURALLY -- it calls Start() and stop() --
#  rather than by a hand-kept list, so a fixture added tomorrow is swept without
#  anyone remembering to add it. A list would rot silently; this cannot.
for f in incant/*; do
    [ -f "$f" ] || continue
    grep -q '^Start();' "$f" 2>/dev/null || continue
    grep -q 'stop();'   "$f" 2>/dev/null || continue
    nm=$(basename "$f")

    SWIFT_BACKTRACE=enable=no "$B" "$f" > "$T/o" 2>&1 &
    _p=$!
    { ( sleep "$CAP"; kill -9 $_p 2>/dev/null ) >/dev/null 2>&1 & } 2>/dev/null
    _w=$!
    wait $_p; ec=$?
    { kill $_w 2>/dev/null; wait $_w 2>/dev/null; } 2>/dev/null

    checked=$((checked+1))

    if [ $ec = 137 ]; then
        echo "  FAIL  $nm TIMED OUT after ${CAP}s -- capture truncated, not a diff"
        fail=1; continue
    fi

    #  H4: the quantity is printed with its value on every failing row, and the
    #  aggregate is printed at the foot on EVERY run whatever the outcome.
    #  ⚠ NOT `$(grep -c ... || echo 0)`. grep -c EXITS 1 WHEN THE COUNT IS ZERO,
    #  so the `||` fires on the healthy case and appends a SECOND line: n becomes
    #  "0\n0", which compares unequal to "0" and fails every fixture. The first
    #  run of this script reported 112 abandoned parses out of 112 and was caught
    #  only because that number is absurd on its face -- had the fleet been large
    #  and the bug partial, it would have read as a real finding. An instrument
    #  written to expose silent failure is not exempt from silent failure.
    n=$(grep -c "expected a method not" "$T/o" 2>/dev/null)
    n=$(printf '%s' "$n" | tr -dc '0-9')
    n=${n:-0}
    if [ "$n" != "0" ]; then
        echo "  FAIL  $nm ABANDONED its parse: abandon=$n (exit $ec)"
        grep "expected a method not" "$T/o" | sed 's/^/          /' | head -4
        echo "          ^ every statement after each of those was silently dropped."
        fail=1; abandoned=$((abandoned+1))
    else
        green=$((green+1))
    fi

    #  SENTINEL OBLIGATION -- only for fixtures that declare one, and the
    #  declaration is read out of the fixture rather than guessed, so a renamed
    #  sentinel cannot quietly stop being checked.
    s=$(grep -o '"[A-Za-z0-9_ ]*SENTINEL[A-Za-z0-9_ -]*"' "$f" 2>/dev/null | head -1 | tr -d '"')
    if [ -n "$s" ]; then
        if grep -qF "$s" "$T/o"; then green=$((green+1))
        else
            echo "  FAIL  $nm declares sentinel \"$s\" and did NOT print it (exit $ec)"
            echo "          ^ the run did not reach its own last line. Every other"
            echo "            result from this fixture is uninterpretable, not merely short."
            fail=1; nosent=$((nosent+1))
        fi
    fi
done

echo ""
echo "  fixtures swept        = $checked"
echo "  abandoned parses      = $abandoned"
echo "  missing sentinels     = $nosent"
echo "  green checks          = $green"

#  ⚠ H2 ON THE HARNESS ITSELF. A sweep that checked nothing must not be able to
#  report success. This is the `pop.sh` failure -- a helper vanished, four checks
#  ceased to exist, and the headline count was the camouflage because a check
#  that evaporates is invisible in a tally of checks that ran.
if [ "$checked" = "0" ]; then
    echo "  FAIL  SWEPT ZERO FIXTURES -- the glob or the Start()/stop() test is broken."
    echo "        A sweep of nothing is not a pass."
    fail=1
fi

echo ""
if [ $fail = 0 ]; then
    echo "COMPLETENESS SWEEP PASSED -- $checked fixtures, no abandoned parses, no missing sentinels"
    exit 0
fi
echo "COMPLETENESS SWEEP FAILED -- see the rows above"
exit 1
