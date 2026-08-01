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
B=${INCANT:-$HOME/bin/incant}          # Tony's canonical symlink -- see note at foot
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
#  ⚠⚠ BOTH ACCEPTANCE TESTS HAVE NOW FIRED -- 2026-08-01. These files were
#  pinned-wrong-answer fixtures on an OPEN item (same shape as iterT1m.divergence
#  and tree.divergence). The item is CLOSED for the sink half. Read the two
#  paragraphs below before assuming anything here is still divergent.
#
#  THE SINGLE MOST IMPORTANT BYTE, and it has moved the right way. It used to
#  read: "on stderr, the three PN-C-A-* rows sit in the flush alongside
#  PN-P-A-def -- that is `cout` being captured by a diversion, and it is the
#  whole defect (KANT-23). After the change PN-P-A-def must be ALONE in the
#  flush and the PN-C-A-* rows must appear on STDOUT between the ARMING and
#  RELEASED markers."  ✅ CHECKED, BOTH HALVES:
#      stderr line 7 is PN-P-A-def and the file ENDS there -- alone in the flush
#      stdout lines 8-10 are PN-C-A-def/dol/und, between ARMING (6-7) and
#      RELEASED (12)
#  Both halves moved together, which is what the fixture demanded: "if only one
#  does, the diversion gate was widened rather than bypassed." It was bypassed --
#  opCout never consults toBUFFER, so there is no gate left to widen.
#
#  ⚠⚠ RE-PINNED 2026-08-01 -- THE cerr HALF HAS LANDED AND ITS ACCEPTANCE TEST
#  PASSED. `cerr` is now a NATIVE statement keyword (rule CerR in incant/grammar,
#  action aCTionCerR in ruleActions.rtn, sink opCerr in Instruct.rtn). It was
#  built because it was blocking minionA round 2: genParse's remaining emitters
#  write their PRODUCT via cerr and kant had no stderr, so a kant version could
#  not reproduce its own target. Grammar-minion round 1 refused to build it in
#  its sandbox and named the exact edit (CLAIM GRAM-4); this is that edit.
#
#  THE MOVE, ACCOUNTED FOR TO THE LINE. Three lines left stdout, six arrived on
#  stderr, and the six are the same three plus a relocation:
#      stdout  -PN-E-U-def / -dol / -und     section 2 rows LEFT stdout
#      stderr  +PN-E-U-def / -dol / -und     ...and arrived here, at the TOP,
#                                            ahead of the section-5 flush
#      stderr  ~PN-E-A-def / -dol / -und     section 3 rows RELOCATED: they were
#                                            INSIDE the flush, they are now
#                                            BEFORE it
#  Both halves are what incant/printFamilyNew's own section headers demanded:
#  section 2 "MUST STILL BECOME: three lines on stderr, byte-identical to the
#  PN-C-U-* trio above but for the row name", and section 3 "MUST BECOME: three
#  lines on stderr HERE, in statement order ... they must NOT appear in the
#  section-5 flush". Checked both: the E-U trio is byte-identical to the C-U
#  trio modulo the row name, and the E-A trio sits at stderr lines 4-6 while the
#  flush is lines 7-10.
#
#  THE cout HALF LANDED IN THE SAME PASS, and it is why KANT-23 is closed.
#  `cout` is now native too (rule CouT, action aCTionCouT, sink opCout) and it
#  exists for a reason beyond symmetry (Tony): `print` is DIVERTIBLE, and the
#  moment you have diverted it you invariably need to reach the terminal anyway.
#  So the three keywords are three DIFFERENT things, not three spellings:
#      print   divertible      -> buffer if armed, else stdout
#      cout    NOT divertible  -> always stdout
#      cerr    NOT divertible  -> always stderr
#  Neither opCout nor opCerr consults toBUFFER, and in both cases THE MISSING
#  TEST IS THE FEATURE. Adding it back to opCout restores KANT-23 exactly;
#  adding it to opCerr makes a diagnostic vanish into a capture buffer, which is
#  the opposite of a diagnostic. incant/sinkT is the fixture that pins all three
#  under an ARMED diversion -- the only condition that can tell them apart.
#
#  ⚠ DEAD SCAFFOLDING, LEFT DELIBERATELY, FLAGGED SO IT IS NOT MISREAD:
#  incant/printFamilyNew still grafts PfCerrGraft, whose own header says "DELETE
#  WHEN cout/cerr GO NATIVE". Native CerR now wins and the graft is inert. It is
#  kept only so this fixture is not churned twice -- delete it together with
#  PfCoutGraft when KANT-23 lands. Until then, know that removing native CerR
#  would silently hand `cerr` back to the graft.
#
#  ⚠ GRAM-P1 IS UNCHANGED BY THIS AND STILL TONY'S. The `'p'` character test is
#  gone (the `#`/StringXP split removed it), so there is still NO discriminator
#  inside aCTionPrinT. `cerr` did not need one because it is a SIBLING RULE with
#  its own action -- which is exactly why it could be built without preempting
#  the sink= design. `cout` is the case that still wants a discriminator.
#  ⚠ WHAT THESE FILES STILL PIN, now that the sink half is correct: SECTION 6.
#  `omitted-2 [ xlInSet` on stdout is an UNINITIALISED READ -- it is 35b (`=`
#  with a list on a non-string target), a different open item entirely, and it
#  is the only knowingly-wrong byte left in either file. The `.divergence` names
#  are kept for that reason and because renaming them would churn the ledger;
#  they are no longer divergent ABOUT SINKS.
diffcheck "printFamilyNew.divergence (stdout: sinks CORRECT; sec.6 xlInSet still 35b)" \
          genLadder/printFamilyNew.divergence "$T/pn.f"
diffcheck "printFamilyNew.err.divergence (stderr: cerr native, flush holds print ALONE)" \
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
