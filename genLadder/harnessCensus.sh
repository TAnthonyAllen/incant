#  harnessCensus.sh -- THE HARNESSES CHECK EACH OTHER. 2026-08-05.
#
#  WHY THIS EXISTS. Three times on this project a harness or fixture has
#  answered FEWER QUESTIONS THAN IT APPEARED TO, at exit 0, inside a green
#  banner:
#      incant/jiquery      three stop() calls -> sections 2 and 3 were dead code
#      genLadder/pop.sh    `sentinel` called, never defined -> the check evaporated
#      jitLadder/ladder.sh `check` AND `sentinel` called, never defined, at JPd
#                          and JPl -- four checks, four days, inside the harness
#                          that certifies JIT-0.1
#  The class has a name -- COPY THE IDIOM, LOSE THE HELPER -- and every instance
#  was found by accident while doing something else.
#
#  ⚠ THE POINT IS THAT A GREEN BANNER CANNOT REPORT THIS. "103 ok, exit 0" is a
#  TALLY OF THE CHECKS THAT RAN; a check that evaporates is invisible in a count
#  of checks, because nobody knows what the count should have been. So the
#  detection cannot live inside the harness's own tally -- it has to be a
#  separate instrument that reads the harnesses as TEXT.
#
#  ⚠ STATIC ON PURPOSE. A helper called inside an untaken branch never fires, so
#  "no `command not found` in the log" is NOT a clean bill. Leg 1 reads source.
#
#  ⚠ THIS CENSUS NEGATIVE-CONTROLS ITSELF (rule H7). Leg 0 builds a deliberately
#  broken copy of the real ladder -- helper definitions deleted -- and FAILS THE
#  RUN if the census does not flag it. A census that cannot go red asserts
#  nothing, and this one is checked before it is trusted, every time.
#
#  SCOPE, named because an absence claim is only as good as its search (and the
#  first draft of this census reported a FALSE GREEN: zsh does not word-split
#  unquoted parameters, so the file list arrived as one filename and every
#  harness "passed"). Covers: the 6 tracked .sh harnesses, and incant/* fixtures
#  for multiple statement-position stop(). Does NOT cover: whether a defined
#  helper is ever REACHED, or whether a check asserts the right thing.
B=${INCANT:-$HOME/bin/incant}
T=${TMPDIR:-/tmp}/harnesscensus.$$
mkdir -p "$T"
fail=0
green=0

HARNESSES="docs/minions/roundTrace.sh
genLadder/containerPop.sh
genLadder/pop.sh
genLadder/printPop.sh
genLadder/tree.sh
jitLadder/ladder.sh"

defsOf () { grep -oE '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)' "$1" | tr -d ' ()' ; }

#  called-but-not-defined, restricted to the POOL of helpers some harness
#  defines -- that is exactly the copy-the-idiom class, and it keeps the check
#  free of the prose-from-comments noise a generic scan produces.
missingIn () {                  # missingIn <file> ; echoes offending names
    _f=$1
    _defs=" $(defsOf "$_f" | tr '\n' ' ') "
    echo "$POOL" | while IFS= read -r h; do
        [ -n "$h" ] || continue
        case "$_defs" in *" $h "*) continue;; esac
        if grep -vE '^[[:space:]]*#' "$_f" | grep -qE "(^|[;&|]|then |else |do )[[:space:]]*${h}[[:space:]]"; then
            printf '%s ' "$h"
        fi
    done
}

POOL=$(echo "$HARNESSES" | while IFS= read -r f; do [ -f "$f" ] && defsOf "$f"; done | sort -u)

echo "  pool  helpers defined by some harness: $(echo $POOL | tr '\n' ' ')"
if [ -z "$POOL" ]; then
    echo "  FAIL  the helper pool is EMPTY -- the census cannot see anything and"
    echo "        every 'ok' below would be vacuous."; fail=1
fi

#  --- LEG 0: the negative control, run BEFORE the real legs are believed -----
awk '/^check \(\) \{/{s=1} /^sentinel \(\) \{/{s=1} s&&/^\}/{s=0;next} !s' \
    jitLadder/ladder.sh > "$T/broken.sh"
nc=$(missingIn "$T/broken.sh")
case "$nc" in
    *check*|*sentinel*) echo "  ok    NEGATIVE CONTROL: census flags a stripped ladder ($nc)"; green=$((green+1));;
    *) echo "  FAIL  NEGATIVE CONTROL: the census did NOT flag a ladder with its"
       echo "        helper definitions deleted. It is BLIND -- it would not have"
       echo "        caught the real 2026-08-05 defect, so nothing below is evidence."; fail=1;;
esac

#  --- LEG 1: copy-the-idiom, statically ------------------------------------
echo "$HARNESSES" | while IFS= read -r f; do
    [ -f "$f" ] || { echo "  FAIL  $f MISSING"; echo x >> "$T/f"; continue; }
    bad=$(missingIn "$f")
    if [ -n "$bad" ]; then
        echo "  FAIL  $f calls but never defines: $bad"
        echo "        COPY THE IDIOM, LOSE THE HELPER. Those checks do not pass"
        echo "        and do not fail -- they cease to exist, at exit 0."
        echo x >> "$T/f"
    else
        echo "  ok    $f no called-but-undefined helper"
    fi
done

#  --- LEG 2: a fixture must not carry a second statement-position stop() ----
#  stop() exits the process, so anything between two of them is dead code that
#  looks live. Matched with a trailing ';' so prose in header comments (which
#  legitimately discusses stop()) is not counted -- grammarOnTheFly:48 is
#  exactly that, and an untightened pattern reports it as a defect.
sc=0
for f in incant/*; do
    [ -f "$f" ] || continue
    n=$(grep -cE '^[[:space:]]*stop\(\)[[:space:]]*;' "$f" 2>/dev/null)
    if [ "$n" -gt 1 ] 2>/dev/null; then
        echo "  FAIL  $f has $n statement-position stop() calls -- everything"
        echo "        between the first and the last is DEAD CODE THAT LOOKS LIVE"
        echo x >> "$T/f"
    fi
    sc=$((sc+1))
done
if [ "$sc" -lt 1 ]; then
    echo "  FAIL  LEG 2 examined ZERO fixtures -- vacuous, not clean"; echo x >> "$T/f"
else
    echo "  ok    LEG 2 examined $sc fixtures, none with a second stop()"
fi

[ -f "$T/f" ] && fail=1

echo ""
#  H2 -- unreachable except through the final leg.
if [ "$green" -lt 1 ]; then
    echo "harnessCENSUS FAILED -- reached the foot with no green recorded"; fail=1
elif [ $fail = 0 ]; then
    echo "harnessCENSUS PASSED -- negative control fired, 6 harnesses clean, $sc fixtures clean"
else
    echo "harnessCENSUS FAILED"
fi
rm -rf "$T"
exit $fail
