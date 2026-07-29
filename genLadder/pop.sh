#!/bin/sh
#  genParse ladder POP. Run from the Groups directory:  sh genLadder/pop.sh
#  Every line RUN, and EXIT STATUS CHECKED -- a POP is not passed unless the
#  process exited 0 (CLAUDE.md Testing). Prints one line per check.
B=~/Library/Developer/Xcode/DerivedData/InProcess-ezzmcllcsvijqmbipricnduikqfp/Build/Products/Debug/Groups
T=${TMPDIR:-/tmp}/genpop.$$
mkdir -p "$T"
fail=0

check () {                      # check <name> <expected-exit> <actual-exit>
    if [ "$2" = "$3" ]; then echo "  ok    $1"; else echo "  FAIL  $1 (exit $3)"; fail=1; fi
}
diffcheck () {                  # diffcheck <name> <target> <actual>
    if diff "$2" "$3" > "$T/d" 2>&1; then echo "  ok    $1"
    else echo "  FAIL  $1"; sed 's/^/          /' "$T/d"; fail=1; fi
}

$B incant/genScratch > "$T/gen" 2>&1;    check "genScratch runs"  0 $?
$B incant/censusScratch > "$T/cen" 2>&1; check "censusScratch runs" 0 $?
$B incant/oneTest > "$T/one" 2>&1;       check "oneTest runs"     0 $?
$B incant/jsonTest > "$T/jsn" 2>&1;      check "jsonTest runs"    0 $?

extract () { sed -n "/^extern [A-Za-z]* $1(/,/^}/p;/^extern [A-Za-z]* $2(/,/^}/p" "$T/gen"; }

extract parseScaf   parseScaf2 > "$T/r12"; diffcheck "rung12.target" genLadder/rung12.target "$T/r12"
extract parseScafA  parseScafB > "$T/r4";  diffcheck "rung4.target"  genLadder/rung4.target  "$T/r4"
extract manyScafC1  parseScafC > "$T/r5";  diffcheck "rung5.target"  genLadder/rung5.target  "$T/r5"
extract parseScafE  parseScafF > "$T/r6";  diffcheck "rung6.target"  genLadder/rung6.target  "$T/r6"
if [ -f genLadder/rung7.target ]; then
    extract parseScafALT parseScafOUT > "$T/r7"; diffcheck "rung7.target" genLadder/rung7.target "$T/r7"
fi

grep -v "^getRStuff" "$T/cen" | sed -n '/^PLAN /,$p' | grep -vE "^Search list:|^stop:|^$" > "$T/cenp"
diffcheck "census.target" genLadder/census.target "$T/cenp"

#  rStuff audit -- PRESENCE-based, and that is the whole point of it.
#  The instrument this replaces was getRStuff's "no rStuff - creating" cerr, and
#  grepping for that returned zero in TWO indistinguishable cases: nothing fired
#  late, and the cerr had been deleted. The second became true on 2026-07-29.
#  So this asserts the audit line IS THERE with a zero count. A check that
#  requires something to be present cannot pass by being removed -- delete
#  auditRegistry and this goes RED, which is exactly what the old one could not do.
if grep -q "^AUDIT Grokking: 0 terms missing rStuff$" "$T/one"; then
    echo "  ok    rStuff audit (present, 0 missing)"
else
    echo "  FAIL  rStuff audit -- line absent or non-zero:"
    grep "^AUDIT" "$T/one" | sed 's/^/          /' || echo "          (no AUDIT line at all -- is auditRegistry still called?)"
    fail=1
fi

diffcheck "oneTest baseline"  genLadder/oneTest.base  "$T/one"
diffcheck "jsonTest baseline" genLadder/jsonTest.base "$T/jsn"

echo ""
if [ $fail = 0 ]; then echo "POP PASSED"; else echo "POP FAILED"; fi
rm -rf "$T"
exit $fail
