#!/bin/sh
#  PRINT-FAMILY POP.  Run from the Groups directory:   sh genLadder/printPop.sh
#
#  The POP for a C++ change that has not been written yet: widening the print
#  sink fork, routing `cout` past the diversion check, adding an `opCerr`
#  (kantCorpus KANT-13 as COMPLETED, and KANT-23). Grammar minion round 2.
#
#  A SEPARATE SCRIPT, NOT LINES ADDED TO pop.sh, AND ON PURPOSE. pop.sh carries
#  the genParse ladder's baselines, which belong to another arc; a print-family
#  change has no business making that file's exit status move. Fold these
#  checks in later if you want one entry point -- but only once the divergence
#  half has been flipped, or pop.sh acquires a permanently-red member.
#
#  Every line RUN and EXIT STATUS CHECKED -- a POP is not passed unless the
#  process exited 0 (CLAUDE.md Testing).
#
#  ⚠ AND EXIT 0 IS NOT ENOUGH HERE, WHICH IS WHY THE SENTINEL CHECKS EXIST.
#  An incant parse failure ABANDONS THE REST OF THE FILE AND STILL EXITS 0
#  (grammarCorpus CLAIM GRAM-8). A row that stops parsing silently deletes
#  every row after it while this script would happily report exit 0. The
#  byte-exact diffs would catch it, but they would blame the wrong row, so the
#  sentinel is checked FIRST and by name.
#
#  ⚠ $? IS TAKEN DIRECTLY, NEVER THROUGH A PIPE. ${PIPESTATUS[0]} is silently
#  empty in zsh and reports every run as passing.
B=~/Library/Developer/Xcode/DerivedData/InProcess-ezzmcllcsvijqmbipricnduikqfp/Build/Products/Debug/Groups
T=${TMPDIR:-/tmp}/printpop.$$
mkdir -p "$T"
fail=0

check () {                      # check <name> <expected-exit> <actual-exit>
    if [ "$2" = "$3" ]; then echo "  ok    $1"; else echo "  FAIL  $1 (exit $3)"; fail=1; fi
}
diffcheck () {                  # diffcheck <name> <target> <actual>
    if diff "$2" "$3" > "$T/d" 2>&1; then echo "  ok    $1"
    else echo "  FAIL  $1"; sed 's/^/          /' "$T/d"; fail=1; fi
}
sentinel () {                   # sentinel <name> <file> <text>
    if grep -qF "$3" "$2"; then echo "  ok    $1"
    else echo "  FAIL  $1 -- THE RUN TRUNCATED. A row stopped parsing and every"
         echo "        row after it was silently dropped, at exit 0. Find the row"
         echo "        that stopped parsing, not the row that diffed."; fail=1; fi
}
strip () { grep -vE "^Search list:|^stop:|^$" "$1"; }

echo "-- STABLE HALF: print + string. GREEN NOW, AND MUST STAY GREEN AFTER THE CHANGE."

$B incant/printFamily > "$T/pf.o" 2> "$T/pf.e"; check "printFamily runs" 0 $?
sentinel "printFamily sentinel (no truncation)" "$T/pf.o" "PF SENTINEL"
strip "$T/pf.o" > "$T/pf.f"
#  stdout: print unarmed, string in all three spacing modes, the armed rows
#  ABSENT, and a clean release. If widening the sink fork disturbs `print` or
#  `string` in any way at all, this is the line that says so.
diffcheck "printFamily.target (stdout: print/string x diversion x \$ x _)" \
          genLadder/printFamily.target "$T/pf.f"
#  stderr: the diverted buffer, flushed at the end. Turns the armed rows from
#  an absence assertion into a presence one -- the bytes have to show up, in
#  order. Flushed to /dev/stderr and NOT /dev/stdout: a flush is an unbuffered
#  write while `print` is block-buffered, so a /dev/stdout flush lands at the
#  TOP of the capture, ahead of everything that preceded it (CLAIM GRAM-9).
#  NOTE: this target is the WHOLE of fd 2, so it also catches any incant
#  diagnostic that starts appearing on stderr. That is deliberate -- a new
#  diagnostic IS a behaviour change -- but it means a red here is not
#  automatically a buffer-ordering problem. Look at the diffed line first.
diffcheck "printFamily.captured (stderr: what the diversion swallowed)" \
          genLadder/printFamily.captured "$T/pf.e"

echo "-- MOVING HALF: cout + cerr. RED ON PURPOSE. TARGETS ARE .divergence FILES."

$B incant/printFamilyNew > "$T/pn.o" 2> "$T/pn.e"; check "printFamilyNew runs" 0 $?
sentinel "printFamilyNew sentinel (no truncation)" "$T/pn.o" "PN SENTINEL"
strip "$T/pn.o" > "$T/pn.f"
#  PINNED WRONG ANSWERS, same shape as iterT1m.divergence and tree.divergence:
#  a fixture on an OPEN item, asserting today's wrong answer is UNCHANGED.
#  These two go RED when Tony's change lands, and THAT IS THE ACCEPTANCE TEST.
#  incant/printFamilyNew's section headers say, row by row, what each must
#  become. WHOEVER MOVES THEM ACCOUNTS FOR THE MOVE.
#
#  The single most important byte in either file: on stderr, the three
#  PN-C-A-* rows sit in the flush alongside PN-P-A-def. That is `cout` being
#  captured by a diversion, and it is the whole defect (KANT-23). After the
#  change PN-P-A-def must be ALONE in the flush and the PN-C-A-* rows must
#  appear on STDOUT between the ARMING and RELEASED markers.
diffcheck "printFamilyNew.divergence (stdout: KNOWN WRONG, pinned)" \
          genLadder/printFamilyNew.divergence "$T/pn.f"
diffcheck "printFamilyNew.err.divergence (stderr: KNOWN WRONG, pinned -- cout IS being diverted)" \
          genLadder/printFamilyNew.err.divergence "$T/pn.e"

echo "-- CROSS-KEYWORD ORACLE: one mechanism, KANT-13."

#  THE STRONGEST CHECK IN THE FILE, and the one that has to hold on BOTH sides
#  of the change. `print` and `cout` are fed character-identical PrintXP and
#  must emit character-identical bytes -- one mechanism, the keyword selecting
#  only the sink. Row names are normalised away so only the bytes are compared.
#  Today `cout` is round 1's runtime graft; after the change it is native. If
#  this ever differs, a per-destination spacing default has crept in, which
#  KANT-13 explicitly cut.
grep '^PF-P-U-' "$T/pf.f" | sed 's/^PF-P-U-/ROW-/' > "$T/o.print"
grep '^PN-C-U-' "$T/pn.f" | sed 's/^PN-C-U-/ROW-/' > "$T/o.cout"
if [ ! -s "$T/o.print" ]; then
    echo "  FAIL  oracle: no PF-P-U-* rows captured at all"; fail=1
else
    diffcheck "print vs cout byte-identical (unarmed, 3 spacing modes)" "$T/o.print" "$T/o.cout"
fi

echo ""
if [ $fail = 0 ]; then echo "PRINT-FAMILY POP PASSED (moving half still pinned to the WRONG answer)"
else echo "PRINT-FAMILY POP FAILED"; fi
rm -rf "$T"
exit $fail
