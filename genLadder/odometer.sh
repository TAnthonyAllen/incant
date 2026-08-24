#!/bin/bash
#  odometer.sh -- THE genParse ODOMETER.
#
#  ⚠⚠ THIS IS NOT THE SCAFFOLD COUNT AND THE TWO MUST NEVER BE CONFLATED IN A
#  CITATION. genLadder/countPop.sh measures incant/f31's fbGen -- a campaign
#  scaffold that emits `t1() AND t2()` incant text and asks whether it PARSES.
#  This measures genParse itself: planRule + emitPlan + emitLeaf/kantLeaf, the
#  real parse-method generator, and asks whether a rule can be PLANNED AND
#  EMITTED at all. Different subject, different verb, deliberately different
#  banner wording. "Finish parse generation" means THIS number.
#
#  H1: the binary is echoed, path, size and mtime, as the first output.
#  H2/self-certification: the run fails if it reaches the foot having recorded
#  zero rows -- a vanished helper or an empty population cannot report green.
#
#  ⚠ THE POPULATION IS GENERATED AT RUN TIME AND NEVER READ FROM A FILE. That
#  is incant/fixits/countInputInTmp's lesson applied at birth: the scaffold
#  count reads /tmp/b2/rules.txt, and a missing list there yields a SHORTER run
#  with identical wording instead of an error. genLadder/odoPopulation
#  recomputes the list from the live registry every time, and this script
#  asserts the count it got.
#
#  Report tier. Exits 0 with its sentinels; red rows are the FRONTIER, not a
#  suite failure -- a red odometer is the normal, correct state today.

B=${INCANT:-$HOME/bin/incant}
if [ ! -x "$B" ]; then echo "  FAIL  binary not executable: $B"; exit 1; fi
echo "  bin   $B"
echo "  bin   $(ls -lL "$B" | awk '{print $5" bytes  "$6" "$7" "$8}')"

T=${TMPDIR:-/tmp}/odo.$$
mkdir -p "$T"

#  ---- population, live ----------------------------------------------------
"$B" genLadder/odoPopulation > "$T/pop.raw" 2>&1
if ! grep -q '^ODOPOP-END' "$T/pop.raw"; then
    echo "  FAIL  population walk did not reach its end sentinel -- list is truncated"
    exit 1
fi
grep '^ODOPOP ' "$T/pop.raw" | awk '{print $2}' > "$T/pop.txt"
P=$(grep -c . "$T/pop.txt")
echo "  pop   $P rules qualify (live walk, four filters: not noPrint, not a bin, is a rule, actionType 0)"
if [ "$P" -eq 0 ]; then echo "  FAIL  population is empty -- nothing to measure"; exit 1; fi

#  ---- one process per rule -------------------------------------------------
green=0; red=0; rows=0
: > "$T/reds.txt"
while read -r rule; do
    [ -n "$rule" ] || continue
    cat > "$T/one" <<EOF
Start();
include(unitTests);
include(utilities);
search reset stack Grokking UnitTests Utilities list;
registry(cOMMANDs);
define genParse immediateAction=genParse; ;
genParse('$rule');
print "ODO SENTINEL":;
stop();
EOF
    out=$("$B" "$T/one" 2>&1)
    rows=$((rows+1))
    if ! echo "$out" | grep -q "ODO SENTINEL"; then
        echo "  TRUNC   $rule -- no sentinel, the run did not reach its foot"
        red=$((red+1)); echo "$rule|run truncated" >> "$T/reds.txt"; continue
    fi
    if echo "$out" | grep -q "^extern GroupItem parse$rule("; then
        green=$((green+1))
    else
        why=$(echo "$out" | grep -m1 '  REFUSE ' | sed 's/^ *//')
        [ -z "$why" ] && why="no emission and no refusal line"
        red=$((red+1)); echo "$rule|$why" >> "$T/reds.txt"
    fi
done < "$T/pop.txt"

#  ---- the frontier, named not absorbed ------------------------------------
if [ "$red" -gt 0 ]; then
    echo
    echo "  -- FRONTIER: $red rules genParse cannot yet emit. Each is a row, not a total."
    while IFS='|' read -r r w; do printf "     %-16s %s\n" "$r" "$w"; done < "$T/reds.txt"
fi

echo
echo "  genParse count $green green / $red red of $rows attempted"

#  ---- self-certification (H2, turned on the harness) ----------------------
if [ "$rows" -eq 0 ]; then
    echo "  FAIL  odometer recorded ZERO rows -- the harness did not run"; exit 1
fi
if [ "$rows" -ne "$P" ]; then
    echo "  FAIL  attempted $rows but the population is $P -- the walk lost rules"; exit 1
fi
echo "  ODOMETER SENTINEL -- $rows of $P attempted, foot reached"
rm -rf "$T"
exit 0
