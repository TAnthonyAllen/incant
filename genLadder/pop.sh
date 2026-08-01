#!/bin/sh
#  genParse ladder POP. Run from the Groups directory:  sh genLadder/pop.sh
#  Every line RUN, and EXIT STATUS CHECKED -- a POP is not passed unless the
#  process exited 0 (CLAUDE.md Testing). Prints one line per check.
#  ⚠ THE BINARY IS IDENTIFIED ON THE FIRST LINE OF OUTPUT, AND THAT IS NOT
#  DECORATION. Until 2026-07-31 this script hardcoded an absolute DerivedData
#  path belonging to a project that NO LONGER EXISTS IN THE TREE
#  (`InProcess-*`; the tree has TOK, plg and wbView). It had gone stale, and a
#  stale binary against current incant sources does not fail as a diff -- the
#  first symptom was a HANG, which reads as an infinite loop in whatever you
#  last touched. Printing the resolved path, the mtime and the size makes a
#  stale-binary run a DIFF IN THE LOG rather than a mystery, which is the same
#  move as the sentinel: convert a silent failure into a visible one.
B=${INCANT:-$HOME/bin/incant}          # Tony's canonical symlink
T=${TMPDIR:-/tmp}/genpop.$$
mkdir -p "$T"
fail=0

if [ ! -x "$B" ]; then
    echo "  FAIL  binary not executable: $B"; exit 1
fi
echo "  bin   $B"
echo "  bin   $(ls -lL "$B" | awk '{print $5" bytes  "$6" "$7" "$8}')"

green=0
parked=0

check () {                      # check <name> <expected-exit> <actual-exit>
    if [ "$2" = "$3" ]; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 (exit $3)"; fail=1; fi
}
diffcheck () {                  # diffcheck <name> <target> <actual>
    if diff "$2" "$3" > "$T/d" 2>&1; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1"; sed 's/^/          /' "$T/d"; fail=1; fi
}

sentinel () {                   # sentinel <name> <file> <text>
    #  ⚠ THIS HELPER WAS MISSING UNTIL 2026-08-01 AND THE CALL SITE AT THE
    #  manyScratch CHECK SILENTLY EVAPORATED. It was copied from printPop.sh
    #  along with the idiom but the DEFINITION was not, so every run printed
    #  `pop.sh: line N: sentinel: command not found` and CARRIED ON: the check
    #  did not increment green, did not set fail, and the suite still reported
    #  PASSED. It neither passed nor failed -- it ceased to exist.
    #  THIS IS STANDING RULE H2's OWN FAILURE MODE INSIDE THE HARNESS THAT
    #  ENFORCES H2 -- a sentinel that is never checked -- and it is the second
    #  instance on this project after incant/jiquery's three stop() calls.
    #  Found by minionA round 3, which was told not to fix it because the brief
    #  pinned the count. It was right to report rather than repair.
    if grep -qF "$3" "$2"; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 -- THE RUN TRUNCATED. A row stopped parsing and every"
         echo "        row after it was silently dropped, at exit 0. Find the row"
         echo "        that stopped parsing, not the row that diffed."; fail=1; fi
}

#  PARKED CHECKS -- Tony's reclassification, 2026-08-01. A parked check RUNS and
#  REPORTS exactly like any other; the only difference is that its failure does
#  not fail the suite, because the answer it would be measured against has not
#  been chosen yet.
#
#  ⚠ IT IS NOT A SKIP, AND THE DIFFERENCE IS THE WHOLE DESIGN. A skipped check
#  passes by being absent, which is standing rule H4's failure mode exactly. A
#  parked check still executes the fixture, still prints its real state, and --
#  the part that matters -- GOES LOUD IF IT STARTS PASSING. A pin that silently
#  begins to hold is how a parked item becomes a forgotten item.
parkcheck () {                  # parkcheck <name> <expected-exit> <actual-exit>
    if [ "$2" = "$3" ]; then echo "  ok    $1"; green=$((green+1))
    else echo "  park  $1 (exit $3)  -- old-design pin, semantics parked with Tony"
         parked=$((parked+1)); fi
}
parkdiff () {                   # parkdiff <name> <target> <actual>
    if diff "$2" "$3" > "$T/d" 2>&1; then
        echo "  WOKE  $1 -- A PARKED PIN NOW PASSES."
        echo "        Tony's offline iterator work may have landed. Re-pin it against the"
        echo "        semantics he chose and take it off the parked list; do not leave it here."
        green=$((green+1))
    else echo "  park  $1  -- old-design pin, semantics parked with Tony"
         parked=$((parked+1)); fi
}

$B incant/genScratch > "$T/gen" 2>&1;    check "genScratch runs"  0 $?
$B incant/censusScratch > "$T/cen" 2>&1; check "censusScratch runs" 0 $?
$B incant/oneTest > "$T/one" 2>&1;       check "oneTest runs"     0 $?
$B incant/jsonTest > "$T/jsn" 2>&1;      check "jsonTest runs"    0 $?

#  SMOKE CHECK ONLY -- EXIT CODE, NO GOLDEN DIFF (Clay's ruling, 2026-07-31).
#  incant/baselineTests is the ONLY fixture that reaches testUnitTests, so the
#  whole unitTests surface -- printDefinition, stringTest, xpTest -- hangs off
#  it, and it was in NO pop script. On 2026-07-31 it SEGFAULTED while all three
#  POPs stayed green. Its golden moves whenever a unitTests fixture's text
#  moves, which is a different maintenance contract from the ladder targets, so
#  only the exit code is asserted here. Promote to a diffcheck if that contract
#  ever stabilises.
$B incant/baselineTests > "$T/base" 2>&1; check "baselineTests runs (smoke, exit code only)" 0 $?
#  ⚠ AND ITS COMPLETENESS IS ASSERTED SEPARATELY, per standing harness rule H2.
#  Exit-code-only is exactly the shape a truncated run passes: an incant parse
#  failure abandons the rest of the file and still exits 0. baselineTests has no
#  sentinel of its own (its output is testUnitTests', not ours to stamp), so the
#  completeness marker is the LAST LINE OF ITS GOLDEN -- which only appears if
#  the run reached the end. This is a presence check on one line, not the golden
#  diff that ruling 3 deliberately declined.
if [ -s "$T/base" ] && tail -1 incant/baselineTests.golden | grep -qFf - "$T/base"; then
    echo "  ok    baselineTests reached its end (completeness, not content)"; green=$((green+1))
else
    echo "  FAIL  baselineTests TRUNCATED -- exited 0 without reaching its last line"; fail=1
fi

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

#  emitLeaf's OWN target -- THE ORACLE IS THE FUNCTION BEING REPLACED. Captured
#  while the C++ emitLeaf was still the only implementation, so a kant rewrite
#  has something byte-exact to answer to (Minion A round 1).
#
#  The rung targets above DO gate emitLeaf -- it writes every term spelling
#  inside them -- but only for the kinds the LADDER reaches, and nothing in the
#  ladder is a labelled literal. LITTO was therefore ungated in BOTH spellings,
#  litTo and litOption. This drives off `CodE` as well as the scaffolds, prints
#  both sinks on every node, and includes `Limit` for the REFUSAL path, which is
#  behaviour too and the part a rewrite is likeliest to quietly drop.
#
#  stderr ONLY, not 2>&1: emitted text goes to stderr unbuffered while the
#  "Search list:" lines are buffered stdout, so a combined capture appends them
#  wherever the exit flush lands rather than where they happened.
$B incant/spellScratch > "$T/spo" 2> "$T/spe";  check "spellScratch runs" 0 $?
sed -n '/^SPELL /,$p' "$T/spe" > "$T/sp"
#  ⚠ LABEL CORRECTED 2026-07-29, and the correction is foreman's own. This line
#  used to read "all 6 kinds + refusal". BOTH HALVES OVERSTATED IT:
#    - there are FIVE plan kinds, not six (LIT LITTO CALL MANY OPT)
#    - `Limit`'s rows are the WALK's refusal (planTerm/planRule) plus
#      dumpSpellings' own "no plan". emitLeaf's OWN refusal branch -- the
#      "no emission for plan kind" arm -- is NEVER REACHED by this target,
#      because a node the walk refuses never becomes a plan node to spell.
#  So an emitter that dropped its refusal arm entirely would pass here. Minion A
#  round 1 flagged it about its own conversion; the label was mine.
diffcheck "spell.target (emitLeaf: 5 kinds x 2 sinks; emitter's own refusal NOT covered)" genLadder/spell.target "$T/sp"

#  WHICH IMPLEMENTATION PRODUCED IT -- and this line is the whole answer to "a
#  green stub reads as coverage". emitLeaf's fork is silent: with no kant speller
#  registered it is the function it always was, so spell.target is green EITHER
#  WAY and the diff above cannot tell them apart. A Minion A round that never
#  registered its action would read exactly like one that did.
#
#  PINNED, and the pin IS the acceptance test: flip `c++` to `kant` when the kant
#  emitLeaf lands, and whoever flips it accounts for the flip. Same shape as
#  tree.divergence flipping from asserting a divergence to asserting agreement.
#  FLIPPED c++ -> kant, 2026-07-29, Minion A round 1. This was the acceptance
#  test and it passed: spell.target stayed byte-identical while the implementation
#  producing it changed language. The pin now guards the other direction -- if it
#  ever reads c++ again, the kant speller stopped being found and the C++ body is
#  quietly answering for it.
SPELLER="SPELLER kant"
if grep -qF "$SPELLER" "$T/spe"; then
    echo "  ok    speller is kant (flipped by round 1 -- c++ here again means the kant one is not being found)"; green=$((green+1))
else
    echo "  FAIL  speller pin MOVED:"
    grep "^SPELLER" "$T/spe" | sed 's/^/          actual:   /' || echo "          (no SPELLER line -- is spellMode still called from spellScratch?)"
    echo "          expected: $SPELLER"
    fail=1
fi

#  THE MANIER PIN -- emitMany's fork, exactly as SPELLER pins emitLeaf's, and for
#  the same reason: THE FORK IS SILENT BY DESIGN. Absent a kant emitMany the C++
#  body runs and every target still holds, so a round that never registered its
#  action would be JUST AS GREEN as one that did. This line is what tells them
#  apart. Pinned at `kant` -- if it ever reads `c++` again the kant emitMany
#  stopped being found and the C++ body is quietly answering for it.
MANIER="MANIER kant"
if grep -qF "$MANIER" "$T/gen"; then
    echo "  ok    emitMany is kant (round 2 -- c++ here again means the kant one is not found)"; green=$((green+1))
else
    echo "  FAIL  manier pin MOVED:"
    grep "^MANIER" "$T/gen" | sed 's/^/          actual:   /' || echo "          (no MANIER line -- is manyMode still called from genScratch?)"
    echo "          expected: $MANIER"
    fail=1
fi

#  manyScratch -- THE REFUSAL ARM, which no ladder rung reaches. rung5 exercises
#  the SUCCESS path only; the two no-site/no-min refusals and the site-but-no-min
#  case exist nowhere else. minionA flagged this as owed and it is cheap.
#  ⚠ SITE-BUT-NO-MIN IS THE ROW THAT EARNS IT: a single combined guard could not
#  produce it, so it is what says the two guards are genuinely separate.
$B incant/manyScratch > "$T/ms.o" 2> "$T/ms.e"; check "manyScratch runs" 0 $?
sentinel "manyScratch sentinel (no truncation)" "$T/ms.o" "MS SENTINEL"
diffcheck "manyScratch.target (kant emitMany: emission + both refusals)" \
          genLadder/manyScratch.target "$T/ms.e"

#  rStuff audit -- PRESENCE-based, and count-PINNED on the tree.divergence pattern.
#
#  PRESENCE: the instrument this replaces was getRStuff's "no rStuff - creating"
#  cerr, and grepping for that returned zero both when nothing fired late AND
#  when the cerr had been deleted. An absence-based check passes by being
#  removed; this one cannot -- delete the audit and the line vanishes and it
#  goes RED.
#
#  PINNED, NOT ZERO: three known populations are OPEN, not broken, so this
#  asserts they are UNCHANGED -- a fixture on an open item, exactly as
#  tree.sh does for the S2.4 retag divergence. Settle one and the number moves,
#  and whoever moves it accounts for the move.
#      4 missing rules  -- 3 Keywords entries + SearchList/Grokking. Marked
#                          isRule but they are keywords and a registry, so the
#                          likely defect is the isRule mark, not the absent rStuff.
#                          MOVED 2026-07-31, 6 -> 4, and BOTH removals are
#                          accounted for by the StringXP grammar change:
#                          `Keywords/string` -- `string` is no longer a term of
#                          any rule at all (`,` replaced it), so nothing marks it
#                          isRule; and `Keywords/print` -- PrinT's `print` term
#                          gained a noLabel `-`. Two entries LEFT the population
#                          and none arrived, which is the direction the pin
#                          wants. ⚠ The `print-` half is a SIDE EFFECT of a
#                          change made for other reasons; it was not aimed at
#                          this audit and Tony has not ruled on it.
#     15 missing terms  -- 3 CodE tails, 3 alternation reference terms, 9 ordinary.
#                          ⚠ 13 -> 15 on 2026-08-01, and the two are ACCOUNTED FOR:
#                          `CerR [4] stuff` and `CouT [4] stuff`, the two new stream
#                          keyword rules. They are term-for-term copies of PrinT, and
#                          `PrinT [4] stuff` WAS ALREADY IN THIS LIST -- so they inherit
#                          a pre-existing gap rather than opening a new one. Any FUTURE
#                          rule of the `stuff=PrintXP+` shape will add one more; that is
#                          the gap to close, not the count to keep bumping.
#      4 loose          -- pROPERTIEs/UnaryOPS and /delimiter, each seen twice.
#                          rStuff on a node that is neither a rule nor a rule's
#                          term. NO constructor change: no failing case in hand,
#                          whole-tree blast radius, and aCTionDefinE's
#                          `if !isRule rStuff = 0;` is MASKING it -- known-masked,
#                          not accepted.
AUDITLINE="AUDIT all registries: 4 missing rules, 15 missing terms, 4 loose"
if grep -qF "$AUDITLINE" "$T/one"; then
    echo "  ok    rStuff audit (present, populations unchanged)"; green=$((green+1))
else
    echo "  FAIL  rStuff audit -- line absent or populations MOVED:"
    grep "^AUDIT all registries" "$T/one" | sed 's/^/          actual:   /' || echo "          (no AUDIT summary at all -- is audit() still called from oneTest?)"
    echo "          expected: $AUDITLINE"
    fail=1
fi

#  ITERATOR FIXTURES -- and they are in HERE, not in scratch, for one reason:
#  T1 is the ONLY thing standing between saveLocalFields and a silent
#  regression. saveLocalFields copied the locals struct including the list
#  POINTER and then cleared the shared object in place, so NO LOCAL CARRYING A
#  LIST survived recursion -- since the initial commit. The four baselines above
#  came back byte-identical across that fix, because nothing in them reaches a
#  recursive action with a list-carrying local. So BASELINE PARITY IS NOT
#  EVIDENCE THE FIX IS SAFE, and only these fixtures are.
#
#  stdout and stderr are captured SEPARATELY. T1's assertion is ORDER, and the
#  no-list diagnostics go to stderr unbuffered while the trace is buffered, so a
#  2>&1 capture interleaves them by flush timing rather than by event order.
#  ⚠⚠ RECLASSIFIED 2026-08-01 (Tony): THESE THREE FIXTURES ARE WIP-BY-DESIGN,
#  NOT DEBT. Tony reworked the iterator offline -- ++/-- now carry an isIterator
#  gate, an iterator inherits its source's groupList, and exhaustion returns null.
#  These targets were pinned against the OLD design, so they measure a question
#  whose answer has not been chosen yet. The open halves (:= / <- source change,
#  attribute/member restrictions, post-exhaustion restart, leaf-source semantics)
#  are all parked with Tony as part of his offline work.
#
#  SO NOTHING ABOUT THEM IS OWED BY ANYONE. They re-pin when that work lands, as
#  part of it, against semantics Tony chose -- not before, and not by whoever
#  happens to run the POP next. A prior SEQ proposing a no-list guard on ++/--
#  was WITHDRAWN for exactly this reason: it presumed a leaf-source ruling that
#  is his to make.
#
#  GREEN-BUT-FOR-PARKED IS THIS FLEET'S CLEAN STATE, and the summary line says so
#  in both numbers so neither can be read alone.
iterrun () {                    # iterrun <fixture> <target> <label>  -- PARKED
    $B "incant/$1" > "$T/$1.o" 2> "$T/$1.e"; ec=$?
    parkcheck "$3 exit 0" 0 $ec
    grep -vE "^Search list:|^stop:|^$" "$T/$1.o" > "$T/$1.f"
    parkdiff "$3" "$2" "$T/$1.f"
}

#  T1 -- SAME ACTION RECURSING, with cursors that genuinely coexist. trunk's
#  cursor must sit untouched while walk(leafA) runs its own loop to completion
#  and then RESUME at leafB. Any sharing breaks the ORDER, not just the count.
iterrun iterT1 genLadder/iterT1.target "iterT1 (per-frame locals, deep)"

#  T3 -- rewind, and := as the only reset. Fresh and exhausted are the same
#  state deliberately, and emitPlan's two passes depend on it. `resetSame` is
#  the case with teeth: `grup := argument;` READS LIKE A NO-OP AND IS NOT ONE.
iterrun iterT3 genLadder/iterT3.target "iterT3 (rewind, := reset)"

#  T1m -- PINNED DIVERGENCE, not a passing test. Same shape as tree.divergence:
#  a fixture on an OPEN item. field.recursive is INFERRED by identity against
#  currentMETHOD, so it covers DIRECT self-reference only; in A -> B -> A
#  neither action names itself, neither gets flagged, and locals are lost. The
#  target below is therefore the WRONG ANSWER (4 lines, not 7), asserted
#  UNCHANGED. Fix the inference and this goes RED -- account for the move, and
#  the 7-line trace T1m's own header documents is what it should become.
iterrun iterT1m genLadder/iterT1m.divergence "iterT1m (mutual recursion: KNOWN WRONG, pinned)"

#  BRANCH SEMANTICS -- language-level POPs, here for the same reason iterT1 is:
#  they are the only cover for rules that were RATIFIED on 2026-07-31 and had no
#  fixture at all before that day.
#    retProbe     an action's value is the LAST EXECUTED STATEMENT'S; a bare
#                 `return;` means STOP and yields the prior statement's value
#                 (it used to yield the STRING "return" -- a KANT-10 leak).
#    loopBranchT  a `break` is CONSUMED by the innermost loop and propagates
#                 nothing, so statements AFTER the loop run. Before the fix a
#                 while returned the break-node and the enclosing block broke on
#                 it too, making the code after the loop unreachable.
#  ⚠ VALUES ARE ASSERTED, NOT A GOLDEN DIFF (rule H3): these fixtures print
#  their own expectations, so a diff would move whenever a comment moved.
branchrun () {                  # branchrun <fixture> <sentinel> <name>
    $B "incant/$1" > "$T/$1" 2>&1
    if [ $? != 0 ]; then echo "  FAIL  $3 (nonzero exit)"; fail=1; return; fi
    if ! grep -qF "$2" "$T/$1"; then
        echo "  FAIL  $3 -- TRUNCATED at exit 0; every line in it is uninterpretable"; fail=1; return; fi
    echo "  ok    $3"; green=$((green+1))
}
valcheck () {                   # valcheck <file> <pattern> <want> <name>
    got=$(sed -n "s/.*$2//p" "$T/$1" | sed 's/[^0-9-].*//' | head -1)
    if [ "$got" = "$3" ]; then echo "  ok    $4"; green=$((green+1))
    else echo "  FAIL  $4 (got '$got', want $3)"; fail=1; fi
}
branchrun retProbe "RP SENTINEL" "retProbe runs (branch/return semantics)"
valcheck retProbe "4 bare return  *->\\[ " 44 "bare return yields the PRIOR statement's value (44)"
valcheck retProbe "3 explicit return value  *->\\[ " 43 "explicit return still yields its expression (43)"
branchrun loopBranchT "LB SENTINEL" "loopBranchT runs (break/continue in loops)"
valcheck loopBranchT "1 bare break in while  *->\\[ " 3 "break is CONSUMED by the loop; code after it runs (3)"
valcheck loopBranchT "2 bare continue in while *->\\[ " 12 "continue still skips correctly (12)"

diffcheck "oneTest baseline"  genLadder/oneTest.base  "$T/one"
diffcheck "jsonTest baseline" genLadder/jsonTest.base "$T/jsn"

echo ""
if [ $fail = 0 ]; then echo "POP PASSED -- $green green / $parked parked-WIP"
else echo "POP FAILED -- $green green / $parked parked-WIP"; fi
if [ $parked != 0 ]; then
    echo "              parked = iterator fixtures pinned to the OLD design;"
    echo "              semantics are Tony's offline work and nothing is owed until it lands."
fi
rm -rf "$T"
exit $fail
