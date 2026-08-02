#!/bin/sh
# ============================================================================
#  containerPop.sh -- the POP for testContainer's LONGEST-ENTRY MATCH and for
#  the Buffer::shorten primitive it is built on. Added 2026-08-02.
#
#  TWO SECTIONS, and they are different KINDS of evidence:
#    1. shorten, as a unit -- compiled straight against Frame/Buffer.C, values
#       asserted. shorten has no incant surface, so wiring it to a command
#       would cost an extern and move the canary to test twenty lines.
#    2. testContainer, through the language -- incant/containerT, whose every
#       row is a MATCHED PAIR: the same operator against a name whose leading
#       letter IS in the container's character set and one whose is not.
#       A single-name row would be silent, not green.
#
#  RULE H1 -- this echoes the binary it is testing, first, before anything.
#  RULE H2 -- the summary is unreachable except through the LAST section, and
#             section 2 asserts containerT's own sentinel before reading any
#             row, because an incant parse failure truncates a file at exit 0.
#  RULE H4 -- every row prints its quantity and compares it. The one refusal
#             row (H) is asserted by the PRESENCE of its refusal, and the count
#             of refusals is compared to 1, so a second refusal appearing
#             anywhere in the file fails the check instead of passing quietly.
# ============================================================================
B=${INCANT:-$HOME/bin/incant}
#  H1 resolves the symlink before stating it: ~/bin/incant is a link, and
#  stat-ing the link reports 111 bytes forever no matter what it points at.
R=$(readlink "$B" 2>/dev/null); [ -n "$R" ] || R=$B
T=$(mktemp -d)
fail=0
green=0

ck () { if [ "$2" = "$3" ]; then echo "  ok    $1  [$2]"; green=$((green+1))
        else echo "  FAIL  $1  got [$2] want [$3]"; fail=1; fi }

echo "  bin   $B"
echo "  bin   $R"
echo "  bin   $(stat -f '%z bytes  %Sm' -t '%b %e %H:%M' "$R" 2>/dev/null)"
echo ""

# --- section 1: shorten, as a unit -------------------------------------------
F=$(cd "$(dirname "$0")" && pwd)
S=$HOME/data/support/Frame
clang++ -std=c++17 -w -I "$S" -o "$T/shortenPop" \
    "$F/shortenPop.C" "$S/Buffer.C" "$S/StringRoutines.C" "$S/CharSet.C" 2>"$T/cc.err"
if [ $? != 0 ]; then
    echo "  FAIL  shortenPop did not compile"; sed 's/^/          /' "$T/cc.err" | head -20; fail=1
else
    "$T/shortenPop" > "$T/sp.out" 2>&1
    if [ $? = 0 ]; then
        echo "  ok    shortenPop -- $(grep -c '^  ok' "$T/sp.out") checks"; green=$((green+1))
    else
        echo "  FAIL  shortenPop"; grep '^  FAIL' "$T/sp.out" | sed 's/^/        /'; fail=1
    fi
fi

# --- section 2: testContainer, through the language --------------------------
SWIFT_BACKTRACE=enable=no $B incant/containerT > "$T/ct.out" 2> "$T/ct.err"
rc=$?
if [ $rc != 0 ]; then echo "  FAIL  containerT runs (exit $rc)"; fail=1
else echo "  ok    containerT runs"; green=$((green+1)); fi

# the sentinel is read FIRST and by name: absent, every other row below is
# uninterpretable rather than merely missing
if grep -qF "CT SENTINEL" "$T/ct.out"; then
    echo "  ok    containerT sentinel (no truncation)"; green=$((green+1))
else
    echo "  FAIL  containerT TRUNCATED -- a row stopped parsing and every row"
    echo "        after it was dropped at exit 0. Every 'ok' below is void."
    fail=1
fi

val () { sed -n "s/^$1 .*->\[ *\([^ ]*\) *\].*/\1/p" "$T/ct.out" | head -1; }
A=$(val A); Bv=$(val B)
ck "A == B -- the g/b asymmetry is gone (A=$A B=$Bv)" "$A" "$Bv"
ck "C  9 -grup  (the presenting bug)              " "$(val C)" "4"
ck "D  9 -brup  (the control)                     " "$(val D)" "4"
ck "E  zed ==grup -- LONGEST wins, 5 means \`=\` won" "$(val E)" "9"
ck "F  zed ==brup (the control)                   " "$(val F)" "9"
ck "G  zed &&grup -- back-off iterates 3->2->1    " "$(val G)" "zed"

# H is the no-entry-at-any-length row: a refusal is the CONTRACT, and the count
# is compared so an unexpected second refusal fails rather than passes
n=$(grep -ac "parse failed" "$T/ct.err")
ck "H  exactly one contained refusal (tilGrup)    " "$n" "1"
if grep -qa "tilGrup parse failed" "$T/ct.err"; then
    echo "  ok    H  the refusal is tilGrup's"; green=$((green+1))
else echo "  FAIL  H  the one refusal is not tilGrup's"; fail=1; fi

echo ""
if [ $fail = 0 ]; then echo "CONTAINER POP PASSED -- $green checks"
else echo "CONTAINER POP FAILED -- $green green"; fi
rm -rf "$T"
exit $fail
