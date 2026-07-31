#!/bin/sh
#  JIT POP.  Run from the Groups directory:   sh genLadder/jitPop.sh
#
#  A SEPARATE SCRIPT, NOT LINES ADDED TO pop.sh, for the reason printPop.sh
#  already argues: pop.sh carries the genParse ladder's baselines, which belong
#  to another arc, and a JIT change has no business moving that file's exit
#  status. Fold in later if you want one entry point.
#
#  WHAT THIS ASSERTS, AND WHAT IT DELIBERATELY DOES NOT.
#  It asserts VALUES, in both directions, on the one construct the JIT emits
#  correctly today. It does NOT assert that the JIT is trustworthy -- 24 of 42
#  operators and 29 of 30 statement handlers have no gate at all and run
#  interpreted at emit time (docs/jit.md S2). Read a green here as "the gIF
#  branch emits and both arms reach their target", nothing wider.
#
#  ⚠ ONE `testing()` PER FILE, WHICH IS WHY THERE ARE TWO FIXTURES AND NOT ONE.
#  A second generate on the same action in one process hits the documented
#  sequential-state-corruption tar baby. The first draft of jitElseT ran both
#  directions in one run and reported a REGRESSION THAT DID NOT EXIST.
#
#  Standing harness rules (CLAUDE.md Testing):
#    H1 the binary is echoed -- a stale binary hangs rather than diffing.
#    H2 each fixture's sentinel is checked FIRST and by name; absent sentinel
#       means the run truncated at exit 0 and every other line is uninterpretable.
#  ⚠ $? IS TAKEN DIRECTLY FROM THE BINARY, NEVER THROUGH A PIPE -- ${PIPESTATUS[0]}
#  is silently empty in zsh and reports every run as passing.
B=${INCANT:-$HOME/bin/incant}
T=${TMPDIR:-/tmp}/jitpop.$$
mkdir -p "$T"
fail=0

if [ ! -x "$B" ]; then echo "  FAIL  binary not executable: $B"; exit 1; fi
echo "  bin   $B"
echo "  bin   $(ls -lL "$B" | awk '{print $5" bytes  "$6" "$7" "$8}')"

check () {                      # check <name> <expected> <actual>
    if [ "$2" = "$3" ]; then echo "  ok    $1"; else echo "  FAIL  $1 (got $3, want $2)"; fail=1; fi
}
sentinel () {                   # sentinel <name> <file> <text>
    if grep -qF "$3" "$2"; then echo "  ok    $1"
    else echo "  FAIL  $1 -- THE RUN TRUNCATED at exit 0. Every other line in"
         echo "        this run is uninterpretable, not merely incomplete."; fail=1; fi
}
#  Pull `maximus = <n>` out of a result line.
maxval () { sed -n 's/.*result: maximus = \([0-9-][0-9]*\).*/\1/p' "$1" | head -1; }

echo "-- gIF ELSE ARM: the POP. False condition must reach the else statement."
#  Was maximus=11 with a garbage return, at exit 0 -- the only wrong-answer-at-
#  exit-0 in the JIT, and a wrong answer with a clean exit outranks every crash.
$B incant/jitElseT > "$T/else" 2>&1;  check "jitElseT runs" 0 $?
sentinel "jitElseT sentinel (no truncation)" "$T/else" "JE SENTINEL"
check "else arm reached (maximus: 7 = else, 11 = the old bug, 26 = wrong arm)" 7 "$(maxval "$T/else")"

echo "-- gIF THEN ARM: the regression net. NOT evidence on its own."
#  Green BEFORE the else arm existed -- correct by luck, exercising only the arm
#  that was emitted. Its job is to catch the else change breaking what worked.
$B incant/jitThenT > "$T/then" 2>&1;  check "jitThenT runs" 0 $?
sentinel "jitThenT sentinel (no truncation)" "$T/then" "JT SENTINEL"
check "then arm reached (maximus: 26 = then, 7 = wrong arm, 11 = neither)" 26 "$(maxval "$T/then")"

echo "-- IR SHAPE: four blocks, both arms storing."
#  The topology check, not a byte-exact target: an IR diff would move on every
#  address bake (the slots are baked ABSOLUTE ADDRESSES, so they differ per run).
#  That is also why there is no .target file here -- see docs/jitDesign.md O4.
INCANT_JIT_DUMP=1 $B incant/jitElseT > "$T/ir" 2>&1
for blk in "entry:" "then:" "else:" "endif:"; do
    if grep -q "^$blk" "$T/ir"; then echo "  ok    block $blk emitted"
    else echo "  FAIL  block $blk MISSING from the dumped IR"; fail=1; fi
done
if grep -q "br i1 %cmp, label %then, label %else" "$T/ir"; then
    echo "  ok    condition branches to then/else (a real two-way branch)"
else
    echo "  FAIL  no two-way CondBr -- the branch is not gated"; fail=1
fi

echo ""
echo "-- KNOWN AND NOT ASSERTED HERE (docs/jit.md, docs/jitDesign.md):"
echo "     the RETURN VALUE is still a constant (ret i32 7 above). Field stores"
echo "     are correct on both paths because fields are MEMORY; the function's"
echo "     return has no defined source. jitDesign.md O4."
echo ""
if [ $fail = 0 ]; then echo "JIT POP PASSED (gIF only -- 24 ops and 29 handlers remain ungated)"
else echo "JIT POP FAILED"; fi
rm -rf "$T"
exit $fail
