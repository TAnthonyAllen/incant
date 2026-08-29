#!/bin/sh
#  DECODER POP.  Run from the Groups directory:
#      sh genLadder/decodePop.sh
#
#  The decoder is the project glossary as kant data (docs/decoder.md): a lookup
#  table with a print verb. Small, and it still gets a real instrument, because
#  the failure it is most exposed to is the one that reads as success -- an
#  entry whose definition silently did not store looks exactly like an entry.
#
#  A SEPARATE SCRIPT, not lines in pop.sh: pop.sh carries the genParse ladder's
#  baselines and three owned reds, and a glossary has no business moving that
#  file's exit status.
#
#  ⚠ RULE H1 -- THE HARNESS ECHOES THE BINARY IT IS TESTING, first output.
#  ⚠ RULE H2 -- the sentinel is checked FIRST and BY NAME. An incant parse
#     failure abandons the rest of the file AND STILL EXITS 0, so the fixtures'
#     own exit statuses certify nothing on their own. This harness also
#     certifies ITSELF at the foot: too few green checks is a FAILURE, which a
#     vanished helper set cannot satisfy.
#  ⚠ RULE H4 -- every quantity is PRINTED AND COMPARED BY VALUE. Nothing here
#     passes because a line is absent.
#  ⚠ $? IS TAKEN DIRECTLY, NEVER THROUGH A PIPE -- ${PIPESTATUS[0]} is silently
#     empty in zsh and reports every run as passing.
#
#  ✅ RULE H7 -- THE NEGATIVE CONTROLS, MEASURED 2026-08-09 AND NOT INFERRED.
#  Three mechanisms were removed one at a time and the affected rows went RED,
#  with every other row staying green -- so this harness discriminates rather
#  than reddening on any input:
#
#      mechanism removed                 green   rows that go RED
#      -------------------------------   -----   --------------------------------
#      ownedRed's `definition=` line     18/22   TALLY definitions 34 -> 33, the
#                                                every-term-defined row, and
#                                                decodeT's own self-cert (5 -> 4)
#      decodeOne's fail-loud `else` arm  21/22   UNDEFINED TERM line absent
#      ownedRed written `definition=(#)` 21/22   dataless-echo row, 0 -> 1
#
#  ⚠ AND THE HALF THAT MAKES THEM CONTROLS RATHER THAN GUARANTEED FAILURES:
#  every other row stays GREEN in all three runs, so this harness discriminates
#  instead of reddening on any input -- the way a negative control usually lies.
#  ⚠ NOTE ROW 3 AGAINST ROW 1: the dataless form leaves TALLY definitions at 34
#  and the term count at 34. It is INVISIBLE to both in-language counts and is
#  caught ONLY by the greppable printed line. That is the measurement behind the
#  paragraph below, not an argument for it.
#
#  ⚠ THE THIRD ROW IS WHY THIS SHELL POP EXISTS AT ALL. A present-but-dataless
#  definition PRINTS as the attribute's own name and does NOT compare equal to
#  it, so no in-language test found in this pass can see it -- but the printed
#  line is trivially greppable here. Measured 2026-08-09, three shapes side by
#  side: `definition="text"` reads the text; a missing definition reads 0; and
#  `definition=(#)` reads the string "definition".
#
#  ⚠ RULE H5 -- every run is capped. timeout(1) is not on macOS, so this uses
#  sleep-and-kill and maps 137 to 124. A TIMEOUT IS REPORTED BY NAME AND NEVER
#  AS A DIFF: a killed process yields truncated output, and a truncation diff
#  names the wrong row.

B=${INCANT:-$HOME/bin/incant}
T=${TMPDIR:-/tmp}/decodepop.$$
CAP=${POPCAP:-90}
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
present () {                    # present <name> <file> <text>
    if grep -qF "$3" "$2"; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 -- expected line not produced: $3"; fail=1; fi
}
#  ⚠ THE WATCHDOG IS LAUNCHED AND REAPED INSIDE BRACE GROUPS WHOSE STDERR IS
#  DISCARDED -- pop.sh's idiom, copied for its stated reason: reaping it
#  otherwise makes the shell announce `Killed: 9` on every fixture, and an
#  instrument that adds its own chatter to the evidence is one that will be
#  misread. (Measured here on the first run: two such lines, interleaved with
#  the check rows.)
capped () {                     # capped <outfile> <errfile> <args...>
    of=$1; ef=$2; shift 2
    "$B" "$@" > "$of" 2> "$ef" &
    p=$!
    { ( sleep "$CAP"; kill -9 $p 2>/dev/null ) >/dev/null 2>&1 & } 2>/dev/null
    w=$!
    wait $p; rc=$?
    { kill $w 2>/dev/null; wait $w 2>/dev/null; } 2>/dev/null
    [ $rc = 137 ] && rc=124
    return $rc
}

echo "=== DECODER POP =========================================================="
if [ -x "$B" ]; then
    echo "binary: $B"
    ls -lL "$B" | awk '{print "        size " $5 "   mtime " $6 " " $7 " " $8}'
else
    echo "  FAIL  binary not found or not executable: $B"; fail=1
fi

# --------------------------------------------------------------------------
echo ""
echo "-- THE POP FIXTURE. incant/decodeT produces the quantities; this harness"
echo "   compares them. Its sentinel is checked FIRST and by name."
capped "$T/dt.o" "$T/dt.e" incant/decodeT
rc=$?
if [ $rc = 124 ]; then
    echo "  FAIL  decodeT TIMED OUT after ${CAP}s -- a hang is the absence of a run,"
    echo "        not a wrong answer. No row below is interpretable."
    fail=1
else
    check "decodeT exits 0" 0 $rc
fi
sentinel "decodeT sentinel (run reached the end)" "$T/dt.o" "DECODET SENTINEL"

#  The two scalars decodeT prints. Both compared by value.
nt=$(sed -n 's/^TALLY terms = *\([0-9][0-9]*\).*/\1/p'       "$T/dt.o" | head -1)
nd=$(sed -n 's/^TALLY definitions = *\([0-9][0-9]*\).*/\1/p' "$T/dt.o" | head -1)
#  ⚠ RE-PIN 2026-08-29 (seventeenth) -- ONE TERM, BY THE BIRTH RULE.
#  79 -> 80 terms, 82 -> 83 dump rows. `methodSlotFourReaders` (repointing
#  method has four readers) -- a rule's gMethod slot is read as THE ACTION by
#  fireLabelMethod, parseAction, aCTionStatemenT and aCTionIF, so installing a
#  parse method into it changes what all four run; parseAction is the sharp one
#  because it is a PARSE EXECUTOR whose whole body is field.method(field), so
#  the install makes it call itself. Measured by reading the 40 gMethod call
#  sites in the generated GroupRules.mm at step 0 of the QuotE brief, which
#  stopped there on its own census clause. Operational record: designDocs
#  ProblemRecords methodSlotFourReaders (status open).
#  NOTHING WAS LOST: +1 in every column and the addition is named here.
#
#  ⚠ RE-PIN 2026-08-29 (sixteenth) -- TWO TERMS, BOTH BY THE BIRTH RULE.
#  77 -> 79 terms, 80 -> 82 dump rows. `isGroupActorPoison` (half-installed
#  executor on an alias) -- an isGROUP alias gets no parse method but still
#  gets a builtinActoR, and that breaks every later parse of the grammar it
#  sits in; measured as a three-arm suppression probe, one rebuild per arm.
#  `verifyParse139` (the walk is good, the specimen parse dies) -- banked and
#  not chased by Tony's ruling. Operational records: designDocs ProblemRecords
#  isGroupActorPoison (status guess) and verifyParse139 (status open).
#  NOTHING WAS LOST: +2 in every column and both additions are named here.
#
#  ⚠ RE-PIN 2026-08-27 (fifteenth) -- ONE TERM, MINTED BY THE BIRTH RULE.
#  76 -> 77 terms, 79 -> 80 dump rows. The term is `firstCallerNullList`
#  (dead helper meets its first caller), born the moment the symptom was
#  named: updateContentFlags gained its first live caller and died on an
#  unguarded groupList it had never had to survive. Operational record:
#  designDocs ProblemRecords firstCallerNullList, status remedy. NOTHING WAS
#  LOST: +1 in every column and the addition is named on this line.
#
#  ⚠ RE-PIN 2026-08-26 (fourteenth, same day) -- ONE MORE, SAME RULE. 75 -> 76
#  terms, 78 -> 79 dump rows. The term is `hasTraits` (attributes that are not
#  decoration), the GroupBody flag built this day as the connectiveDiscriminant
#  remedy by Tony's ruling. It is a code identifier and not a doctrine id, which
#  is why it sits beside `tokened` and `canonOf` rather than beside the Rulings.
#  NOTHING WAS LOST: +1 in every column and the addition is named on this line.
#
#  ⚠ RE-PIN 2026-08-26 (thirteenth, same day) -- ONE MORE, SAME RULE. 74 -> 75
#  terms, 77 -> 78 dump rows. The term is `passthroughPercentDash` (a printf
#  flag closes the passthrough), met while building the probe instrument for
#  the recursion station and banked so the next author does not pay for it.
#  Operational record: designDocs ProblemRecords passthroughPercentDash.
#
#  ⚠ RE-PIN 2026-08-26 (twelfth, same day) -- ONE MORE TERM, SAME RULE.
#  73 -> 74 terms, 76 -> 77 dump rows. The term is `connectiveDiscriminant`
#  (alternation emitted as conjunction), promoted from a noted-not-graded line
#  on the recursion docket to its own citizen by Tony's ruling. Operational
#  record: designDocs ProblemRecords connectiveDiscriminant, status open.
#  Runnable citizen: incant/fixits/connectiveDiscriminant (promoted to the fleet
#  as incant/connectiveT on 2026-08-27; the name here is its vintage name).
#
#  ⚠ RE-PIN 2026-08-26 (eleventh) -- ONE TERM, MINTED BY THE BIRTH RULE. 72 -> 73
#  terms, 75 -> 76 dump rows. The term is `parseSelfRecursion` (generated parse
#  re-enters itself), born the moment the symptom was first named, per the rule
#  that an id in neither the decoder nor the problem records is not yet an id.
#  Its operational record is designDocs ProblemRecords parseSelfRecursion,
#  status open. NOTHING WAS LOST: the delta is +1 in every column and the name
#  of the addition is on this line, which is the whole of what a re-pin owes.
#
#  ⚠ RE-PIN 2026-08-23 (tenth, same day) -- THE CAMPAIGN'S CLOSE. 68 -> 72 terms,
#  71 -> 75 dump rows. FOUR terms added, all nameable, all minted by the closing
#  work under the birth rule: `TOKENize`, `tokened`, `labelsAreForReaders`,
#  `absenceIsNotAChannel`. +4 and +4; the arithmetic closes exactly. F31's
#  definition was also CORRECTED in place (not added) -- the mechanism story is
#  reclassification, not body-misread.
#
#  ⚠ RE-PIN 2026-08-23 (ninth, same day). 67 -> 68 terms, 70 -> 71 dump rows.
#  ONE term added, named: `boundarySupplyNotSubstitutable`, minted by SEQ 92
#  step 2 under the birth rule. +1 and +1; arithmetic closes exactly.
#
#  ⚠ RE-PIN 2026-08-23 (eighth, same day). 66 -> 67 terms, 69 -> 70 dump rows.
#  ONE term added, named: `unregisteredIsATerm`, minted by SEQ 90 D1 under the
#  birth rule. +1 and +1; arithmetic closes exactly.
#
#  ⚠ RE-PIN 2026-08-23 (seventh, same day). 65 -> 66 terms, 68 -> 69 dump rows.
#  ONE term added, named: `parentPopulationSplit`, minted by SEQ 89 C1 under the
#  birth rule. +1 and +1; arithmetic closes exactly.
#
#  ⚠ RE-PIN 2026-08-23 (sixth, same day). 64 -> 65 terms, 67 -> 68 dump rows.
#  ONE term added, named: `boundaryStampIsTermLevel`, minted by SEQ 87 phase 1
#  under the birth rule. +1 and +1; arithmetic closes exactly.
#
#  ⚠ RE-PIN 2026-08-23 (fifth, same day). 63 -> 64 terms, 66 -> 67 dump rows.
#  ONE term added, named: `noActionNoHome`, minted by the SEQ 86 migration under
#  the birth rule. +1 and +1; arithmetic closes exactly.
#
#  ⚠ RE-PIN 2026-08-23 (fourth, same day). 62 -> 63 terms, 65 -> 66 dump rows.
#  ONE term added, named: `percentMinusClosesPassthrough`, minted by the SEQ 85
#  NamE-span probe under the birth rule. +1 and +1; arithmetic closes exactly.
#
#  ⚠ RE-PIN 2026-08-23 (third, same day). 61 -> 62 terms, 64 -> 65 dump rows.
#  ONE term added, named: `canonRoadDependence`, minted by M3's instrument check
#  under the birth rule. +1 and +1; the arithmetic closes exactly.
#
#  ⚠ RE-PIN 2026-08-23 (second, same day). 60 -> 61 terms, 63 -> 64 dump rows.
#  ONE term added, named: `hookIdentityFork`, minted by the Arm A measurement
#  under the birth rule -- a new id is born by writing its decoder line AND its
#  problem record in the same act. +1 and +1; the arithmetic closes exactly.
#
#  ⚠ RE-PIN 2026-08-23, AND THE SENTENCE THE RULE ASKS FOR. 36 -> 60 terms,
#  39 -> 63 dump rows. ONE CAUSE, and every moved row is that cause: the corpus
#  had stood at its 2026-08-10 mark while the campaign minted ids continuously,
#  and the 2026-08-23 brief (Clay, ratified Tony) ordered the backfill. EXACTLY
#  24 TERMS WERE ADDED, and they are nameable, which is what makes this a re-pin
#  and not a regenerated green:
#      H10 H11 RulingA RulingB RulingC RulingD RulingE doorTaxonomy F31
#      bt4 bt26 bt29 bt32 bt34 bt35 bt37
#      frontier peasPass loadedGun glossConvention problemRecord tombstone
#      canonOf armingWithoutRouting
#  36 + 24 = 60, and the dump row count moves by the same 24. No term was
#  removed or reworded; the arithmetic is additive and closes exactly.
#  Operational depth for the bt- and Ruling- entries lives in designDocs
#  ProblemRecords, never here -- the decoder stays one sentence per term.
#
#  ⚠ RE-PIN 2026-08-10, SEQ 27/28/29, AND THE SENTENCES THE RULE ASKS FOR. 34 -> 36
#  in two named steps, neither of them a loss -- the count went UP and both terms are
#  in incant/decoder under their own dated heading:
#      +1  `twoDoors`          the two entry paths into an action body. Ruled Tony
#                              2026-08-10, and CERTIFIED the same day by the SEQ 27
#                              crossing census rather than resting on authority.
#      +1  `oneNumberTwoEras`  a green that survived a semantics change by
#                              arithmetic accident. Dictated SEQ 29 from kant8T's
#                              K6f, which is the measured case.
check "corpus holds 80 terms"          80 "$nt"
check "80 of them carry a definition"  80 "$nd"
check "every term is defined"     "$nt" "$nd"

#  decodeT's own self-certification, asserted FROM OUTSIDE -- a harness that
#  scores its own completeness and is never read has scored nothing.
ng=$(sed -n 's/^GREEN CHECKS RECORDED = *\([0-9][0-9]*\).*/\1/p' "$T/dt.o" | head -1)
check "decodeT recorded 5 green checks" 5 "$ng"
present "decodeT self-cert green" "$T/dt.o" "SELF-CERT ok"

#  ⚠ D, THE FAIL-LOUD ARM (WT14). Asserted as PRESENCE-WITH-VALUE: the line
#  must appear AND must name the term. An assertion that the term is merely
#  absent from the corpus would pass with the fail-loud arm deleted.
present "undefined term fails loud, by name" "$T/dt.o" \
        "decode UNDEFINED TERM  notATermAnybodyMinted"

#  The two slots must announce themselves, so a decode of either cannot be
#  read as a ruling. Both sentences are asserted, because the whole point of
#  the hold is that BOTH are on the table.
#  ⚠ THE FIRST DRAFT OF THIS ROW PASSED VACUOUSLY. It grepped for
#  "RESERVED SLOT" and matched this fixture's own SECTION HEADER
#  ("=== E. UNRATIFIED / RESERVED SLOTS ==="), not the entry -- a check that
#  was satisfied by the label above the thing it was checking. Both rows now
#  assert a phrase that appears ONLY inside the definition.
present "parked declares itself an unratified slot" "$T/dt.o" \
        "two candidate sentences are on the table"
present "parked carries candidateA (the dispatch)" "$T/dt.o" \
        "a scheduling state, not a verdict"
present "parked carries candidateB (SEQ 44 PINCH 6)" "$T/dt.o" \
        "pinned means we ruled it wrong and are watching"
present "byteIdentical declares itself reserved" "$T/dt.o" \
        "waits on vigram O4 at the V1 gate"

check "decodeT writes nothing to stderr" "" "$(cat "$T/dt.e")"

# --------------------------------------------------------------------------
echo ""
echo "-- THE RUNNER. incant/decode serves a decode line and dumps the corpus."
capped "$T/dc.o" "$T/dc.e" incant/decode
rc=$?
if [ $rc = 124 ]; then
    echo "  FAIL  decode TIMED OUT after ${CAP}s."; fail=1
else
    check "decode exits 0" 0 $rc
fi
sentinel "decode sentinel (run reached the end)" "$T/dc.o" "DECODE SENTINEL"

#  ⚠ VACUITY GUARD BEFORE ANY COUNT: a count over an empty capture is an
#  absence check wearing a number's clothes.
if [ ! -s "$T/dc.o" ]; then
    echo "  FAIL  decode produced no output -- every count below would be vacuous"; fail=1
else
    echo "  ok    decode produced output (vacuity guard)"; green=$((green+1))
fi

#  The full corpus dump: one line per term, plus the three from the decode line.
#  ⚠ ANCHORED, because ' -- ' also occurs INSIDE definitions and in the
#  sentinel line ("DECODE SENTINEL -- run reached the end"). An unanchored
#  count read 38 for 37 real rows. A definition row is `<singleWord> -- `.
nl=$(grep -cE '^[A-Za-z][A-Za-z0-9]* -- ' "$T/dc.o")
check "corpus dump + decode line = 83 definition rows" 83 "$nl"

#  ⚠ THE DATALESS-ECHO ROW, and the reason this file exists. A definition that
#  never stored prints as the ATTRIBUTE'S OWN NAME. In-language it compares
#  equal to nothing; here it is one grep.
ne=$(grep -cE '^[A-Za-z][A-Za-z0-9]* --  *definition *$' "$T/dc.o")
check "no entry's definition printed as the string 'definition'" 0 "$ne"

#  ⚠ AND ITS ANTI-VACUITY SIBLING. A row expecting 0 cannot distinguish
#  "nothing wrong" from "nothing looked at", so pair it with one that wants a
#  real number: the decode line must serve three named terms with real text.
present "decode line served H4 by its own words" "$T/dc.o" \
        "never absence-of-message"
present "decode line served H7 by its own words" "$T/dc.o" \
        "measured, not inferred"
present "decode line served blastRadius by its own words" "$T/dc.o" \
        "every stream diffed"

check "decode writes nothing to stderr" "" "$(cat "$T/dc.e")"

# --------------------------------------------------------------------------
#  ⚠ H2 TURNED ON THE HARNESS ITSELF. A check that EVAPORATES -- a helper
#  called but never defined -- is invisible in a count of checks, because
#  nobody knows what the count should have been. This foot assertion cannot be
#  satisfied by a vanished helper set, and it is unreachable except by reaching
#  the end.
echo ""
if [ "$green" -lt 18 ]; then
    echo "  FAIL  SELF-CERTIFICATION: only $green green checks recorded, expected"
    echo "        at least 18. Either helpers vanished or the run stopped early."
    fail=1
fi
echo "checks green = $green"
rm -rf "$T"
if [ $fail = 0 ]; then
    echo "DECODER POP PASSED -- $nt terms, all defined, fail-loud arm live,"
    echo "  both unratified slots announcing themselves."
    exit 0
else
    echo "DECODER POP FAILED -- see the rows above."
    exit 1
fi
