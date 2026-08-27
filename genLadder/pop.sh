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

#  ===========================================================================
#  THE KITCHEN LAW, 2026-08-04. Clean kitchen is not declared while anything
#  working sits uncommitted -- "clean" means the fleet is green AND git status
#  is quiet, in BOTH repos, Groups and support. Work-in-progress that is
#  deliberately unfinished may ride uncommitted while it is the live task; the
#  moment it becomes SUBSTRATE -- a pin moves on it, a baseline is captured over
#  it, anything else builds on top -- it commits first.
#
#  ⚠ PRINT, DO NOT GATE, and the choice is deliberate. Gating on a clean tree
#  would fail this POP during legitimate mid-task work, which trains people to
#  bypass the check -- the same erosion as leaving a signed diff red. VISIBILITY
#  IS THE ENFORCEMENT; the law supplies the judgement about when visible dirt is
#  acceptable (live task) versus overdue (substrate). So this block can never
#  set fail, and it prints a count with its value rather than staying silent
#  when clean (H4) -- "trees clean" is an assertion, silence is not.
#
#  BOTH REPOS, because groups.ext is the standing counterexample: it is a real
#  build dependency, it lives outside this repo, and it is tracked in the
#  SUPPORT repo -- so `git status` here will never show it and a Groups-only
#  check would report a clean kitchen over an uncommitted layout change.
#  ===========================================================================
#  THIRD LEG, 2026-08-05: PUSHED. Clean kitchen = fleet green + trees quiet +
#  PUSHED. Committed-but-unpushed history is the uncommitted pile one level up,
#  and it reached 118 before anyone counted it -- the same way the working-tree
#  pile reached 109. Dropbox rewrote a tracked file mid-session on 2026-08-04, so
#  "it is safe on disk" is not a property this tree has.
#  ⚠ NO FETCH HERE, DELIBERATELY. The count is against the last-known remote ref,
#  so a POP never blocks on the network and never fails because GitHub is slow.
#  It reads stale-low, never stale-high -- it can under-report being ahead, never
#  over-report -- so it cannot manufacture a false alarm, only miss one, which is
#  the right direction for a line that is printed and not gated.
gdirt=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
sdirt=$(git -C "$HOME/data/support" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
gahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "?")
sahead=$(git -C "$HOME/data/support" rev-list --count @{u}..HEAD 2>/dev/null || echo "?")
echo "  tree  Groups: $gdirt uncommitted, $gahead unpushed   support: $sdirt uncommitted, $sahead unpushed"
if [ "$gahead" != "0" ] || [ "$sahead" != "0" ]; then
    echo "        ^ UNPUSHED history. Not a failure -- but clean kitchen has three"
    echo "          legs now, and this is the third."
fi
if [ "$gdirt" != "0" ] || [ "$sdirt" != "0" ]; then
    git status --porcelain 2>/dev/null | sed 's/^/          Groups   /'
    git -C "$HOME/data/support" status --porcelain 2>/dev/null | sed 's/^/          support  /'
    echo "        ^ NOT a failure. Live-task WIP is legitimate; substrate is not."
    echo "          A wakeup reseal or session close over this either names it or is false."
fi

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

#  ============================================================================
#  RULE H5 -- A FIXTURE MUST NOT BE ABLE TO DELETE THE REST OF THE SUITE.
#  Adopted 2026-08-02, paid for the same day.
#
#  `incant/iterT1m` began to HANG rather than return, so pop.sh never reached
#  its own summary line, its own exit status, or the eleven checks below the
#  iterator block. Those checks did not fail and did not pass -- like the
#  missing `sentinel` helper above, THEY CEASED TO EXIST, and the operator sees
#  a terminal that is merely quiet. Worse than the sentinel case, because there
#  is no output at all to be suspicious of.
#
#  ⚠ AND THE FIXTURE THAT DID IT WAS A **PARKED** ONE. The parked mechanism was
#  built so that a fixture whose answer is not yet chosen cannot fail the suite
#  -- and it does that job perfectly. It never contemplated a parked fixture
#  taking the suite hostage by never returning at all. So the containment was
#  real but one dimension short: it bounded the VERDICT and not the RUN.
#
#  Every fixture now runs under a wall-clock cap. A timeout is reported as its
#  own kind of failure, LOUDLY and by name -- never as a diff, because a killed
#  process yields truncated output and a truncation diff names the wrong row.
#  `timeout(1)` is not on macOS, hence the sleep-and-kill; 137 is the SIGKILL
#  that produces, and it is mapped to 124 so it reads like GNU timeout's.
#  Override the cap with POPCAP=<seconds> when a slow machine needs room.
#  ============================================================================
#  ⚠ TWO RUNNERS, AND THE SPLIT IS LOAD-BEARING, NOT STYLE. `run1` merges the
#  streams IN THE CHILD (`2>&1`) exactly as the old call sites did, so ordering
#  by flush is preserved byte for byte; capturing them apart and concatenating
#  afterwards would reorder every merged baseline. `run2` keeps them apart,
#  which is what iterT1's ORDER assertion needs.
POPCAP=${POPCAP:-90}
_cap () {                       # _cap <fixture> -- caller has already redirected
    _p=$!
    #  The watchdog is launched inside a brace group whose stderr is discarded,
    #  because reaping it makes the shell announce `Terminated: 15` on EVERY
    #  fixture -- 9 lines of job-control noise per run, in a log whose whole job
    #  is to be diffed. Same reasoning as the FAIL text: an instrument that adds
    #  its own chatter to the evidence is an instrument that will be misread.
    { ( sleep "$POPCAP"; kill -9 $_p 2>/dev/null ) >/dev/null 2>&1 & } 2>/dev/null
    _w=$!
    wait $_p; _ec=$?
    { kill $_w 2>/dev/null; wait $_w 2>/dev/null; } 2>/dev/null
    if [ $_ec = 137 ]; then
        echo "  FAIL  $1 TIMED OUT after ${POPCAP}s -- KILLED, not failed."
        echo "        Its capture is TRUNCATED, so every diff below it would name"
        echo "        the wrong row. Fix the hang before reading anything else."
        #  ⚠ A TIMEOUT FAILS THE SUITE EVEN ON A **PARKED** FIXTURE, and that is
        #  the point of H5 rather than an oversight in it. Parking suspends a
        #  VERDICT -- "the answer this would be measured against has not been
        #  chosen" -- and a hang is not a wrong answer, it is the absence of a
        #  run. Nobody parked that. Letting parkcheck absorb a 124 would restore
        #  exactly the silence H5 exists to remove, one layer further in.
        fail=1
        return 124
    fi
    return $_ec
}
run1 () { $B "incant/$1" > "$2" 2>&1      & _cap "$1"; }   # merged
run2 () { $B "incant/$1" > "$2" 2> "$3"   & _cap "$1"; }   # split

run1 genScratch "$T/gen";    check "genScratch runs"  0 $?
run1 popScratch "$T/cen"; check "popScratch runs" 0 $?
run1 oneTest "$T/one";       check "oneTest runs"     0 $?
run1 jsonTest "$T/jsn";      check "jsonTest runs"    0 $?

#  SMOKE CHECK ONLY -- EXIT CODE, NO GOLDEN DIFF (Clay's ruling, 2026-07-31).
#  incant/baselineTests is the ONLY fixture that reaches testUnitTests, so the
#  whole unitTests surface -- printDefinition, stringTest, xpTest -- hangs off
#  it, and it was in NO pop script. On 2026-07-31 it SEGFAULTED while all three
#  POPs stayed green. Its golden moves whenever a unitTests fixture's text
#  moves, which is a different maintenance contract from the ladder targets, so
#  only the exit code is asserted here. Promote to a diffcheck if that contract
#  ever stabilises.
run1 baselineTests "$T/base"; check "baselineTests runs (smoke, exit code only)" 0 $?
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

#  parseClass -- WHICH setParse ARM CLAIMS EACH FIELD, over the whole grammar.
#  Added 2026-08-19, and it is the instrument that day did not have.
#
#  BOTH parse-generation defects found that day were CLASSIFICATION defects and
#  neither needed a parse to be visible. `tokenize` was falling past every arm
#  into the data switch and binding parseString -- which, until the parseString
#  repair, reported success without matching anything. `CodE`, which the grammar
#  declares parseAction, came within one arm ORDER of binding parseRule. A third
#  landed the same afternoon: with `or method` above an unguarded data switch,
#  three isGROUP references carrying a method (ANYtoken, NewGroup, ShortcuT --
#  seven rows) bound parseAction where the template leaves them unbound.
#
#  ⚠ IT READS THE BOUND POINTER, IT DOES NOT RE-DERIVE THE ARM. parseClassify
#  compares the actual fnptr, so this cannot drift into being a second
#  implementation of setParse's chain that disagrees with the real one.
#
#  ⚠ AND IT IS THE ONLY ROW IN THIS FILE THAT EXERCISES setParse AT ALL. Every
#  other check here runs the interpretive path, where no parse method is ever
#  bound -- so before this row the whole generated-parse arc was invisible to
#  the fleet, and "fleet unmoved" said nothing whatever about it.
#
#  stderr, not stdout: every line the fixture prints is cerr, deliberately, so a
#  run that ends badly cannot lose it in a block buffer.
run2 parseClass "$T/pco" "$T/pce"; check "parseClass runs" 0 $?
sentinel "parseClass" "$T/pce" "PARSECLASS SENTINEL"
grep '^PC ' "$T/pce" | sort > "$T/pcp"
diffcheck "parseClass.target (setParse classification)" genLadder/parseClass.target "$T/pcp"

#  connectiveT -- THE CONNECTIVE DISCRIMINANT, promoted out of Tony's fixit queue
#  2026-08-27 after he stepped and blessed its REMEDY row. It was
#  incant/fixits/connectiveDiscriminant; the three-lives rule says a stepped
#  citizen becomes the regression test, and the fleet did not cover this.
#
#  WHAT IT GUARDS: hasTraits, the flag that answers "does this rule conjoin
#  traits" where hasAttributes answers "is this node marked up". setParse hangs
#  two noPrint decoration attributes on every rule it touches, which made the
#  old gate read AND for all 36 emitted bodies and left the OR branch
#  unreachable across the whole grammar.
#
#  ⚠ THE ASSERTED ROW IS StatemenT AFTER setParse, AND IT NEEDS BOTH NUMBERS.
#  hasAttributeS 1 is CORRECT there -- the node genuinely is marked up -- and
#  hasTraitS 0 beside it is the fix. Asserting either alone asserts nothing: a
#  flag stuck at 1 passes the first, a flag never written at all passes the
#  second. The BlocK row is the H11 hit control and is why a never-written flag
#  cannot pass this block: it wants 1 on a rule that really does carry traits.
#
#  ⚠ AND THE CENSUS HALF IS DELIBERATELY NOT HERE. connectiveT's ROW 4 carries
#  the 2x2 population figures as PROSE. The measurement behind them drives off
#  IncantForms/WorkingOn/parser, which is Tony's live working file -- its gates
#  and its target rule move between sessions by design -- so a fleet row reading
#  it would move for reasons that say nothing about the connective. Rule H3. The
#  flag rows are the stable half; the census is re-run by hand. Said out loud
#  because a silent cap reads as coverage.
run2 connectiveT "$T/ct.o" "$T/ct.e"; check "connectiveT runs" 0 $?
sentinel "connectiveT sentinel (no truncation)" "$T/ct.e" "CONNECTIVE SENTINEL"
CT_REMEDY="rule  StatemenT hasAttributeS  1 hasTraitS  0"
CT_CONTROL="rule  BlocK hasAttributeS  1 hasTraitS  1"
if grep -qF "$CT_REMEDY" "$T/ct.e"; then
    echo "  ok    connectiveT: StatemenT after setParse reads hasAttributeS 1 hasTraitS 0"; green=$((green+1))
else
    echo "  FAIL  connectiveT: the remedied row MOVED:"
    grep "StatemenT hasAttributeS" "$T/ct.e" | sed 's/^/          actual:   /' || echo "          (no StatemenT flag row at all -- did cdBoth stop being called?)"
    echo "          expected: $CT_REMEDY"
    echo "          1 0 is the remedy. 1 1 is the 2026-08-26 defect back."
    fail=1
fi
if grep -qF "$CT_CONTROL" "$T/ct.e"; then
    echo "  ok    connectiveT: BlocK hit control still reads 1 1 (hasTraits is not simply dead)"; green=$((green+1))
else
    echo "  FAIL  connectiveT: the HIT CONTROL moved -- hasTraits may be stuck off:"
    grep "BlocK hasAttributeS" "$T/ct.e" | sed 's/^/          actual:   /' || echo "          (no BlocK flag row at all)"
    echo "          expected: $CT_CONTROL"
    fail=1
fi

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
run2 spellScratch "$T/spo" "$T/spe";  check "spellScratch runs" 0 $?
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
run2 manyScratch "$T/ms.o" "$T/ms.e"; check "manyScratch runs" 0 $?
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
#  RE-PINNED 15 -> 12 (2026-08-02), and the three that vanished are named
#  because a moved number with no sentence is just a number: JSONtoken[1]
#  JSONblock, JSONvalue[1] JSONblock and JSONvalue[2] JSONarray. All three were
#  `isRule term, no rStuff` -- forward references that had minted empty stubs.
#  Naming JSONblock and JSONarray before JSONtoken/JSONvalue reference them
#  turned all three into real references, which is why they are no longer
#  missing. Explanation plus measurement, not just a green diff.
#  RE-PINNED 12 -> 0 (2026-08-16), and the WHOLE population closed rather than
#  partially moved, which is why this one gets a mechanism and not just a count.
#  Tony's aCTionDefinE change mints rStuff for any isRule term that lacks it --
#      if item.isRule   if !item.rStuff  item.rStuff = new(item);
#  -- and every one of the twelve was an `isRule term, no rStuff`, so they are
#  closed BY CONSTRUCTION, not by accident: CerR[4] CouT[4] PrinT[4] StringXP[2]
#  stuff, FormaT[1] flags, FormaT[4] formatTYPE, Precision[1] precision,
#  ScopeXP[2] scopeList, list[1] entries, list[3] CodE, JSONarray[4] CodE,
#  JSONfield[5] CodE. The `stuff=PrintXP+` gap the 08-01 note called "the gap to
#  close, not the count to keep bumping" is the one that closed.
#  ⚠ THE OTHER TWO POPULATIONS DID NOT MOVE -- 4 missing rules and 4 loose stand
#  exactly as pinned, which is what says this was a targeted close and not the
#  instrument going quiet. It went quiet for four hours on 2026-08-16 for an
#  unrelated reason (see below) and that is precisely how a real move can hide.
#  ⚠ AND THE INSTRUMENT HAD TO BE REPAIRED BEFORE THIS NUMBER COULD BE READ AT
#  ALL. The labelled-literals grammar change broke aCTionParens' empty-parens
#  case, so `audit()` audited a literal and reported `AUDIT rightParen: 0,0,0,0`.
#  Had this line been pinned at the natural-looking ZERO, a completely dead audit
#  would have read GREEN. Pinning open populations at their real non-zero values
#  is what made a dead instrument visible.
AUDITLINE="AUDIT all registries: 4 missing rules, 0 missing terms, 4 loose, 0 unconsumed"
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
    run2 "$1" "$T/$1.o" "$T/$1.e"; ec=$?
    parkcheck "$3 exit 0" 0 $ec
    grep -vE "^Search list:|^stop:|^$" "$T/$1.o" > "$T/$1.f"
    parkdiff "$3" "$2" "$T/$1.f"
}

#  T1 -- SAME ACTION RECURSING, with cursors that genuinely coexist. trunk's
#  cursor must sit untouched while walk(leafA) runs its own loop to completion
#  and then RESUME at leafB. Any sharing breaks the ORDER, not just the count.
#  ⚠ iterT1 IS NO LONGER PARKED (2026-08-02). It fired WOKE -- the parked-pin
#  alarm -- once Tony's iterator work landed, and its ORIGINAL target matches
#  byte for byte under the new semantics. That is the alarm doing exactly what
#  it was built for, so the pin graduates to a full check rather than sitting in
#  the parked list being quietly right. A parked item that starts passing and is
#  left parked is how a parked item becomes a forgotten one.
iterrunLIVE () {                # iterrunLIVE <fixture> <target> <label>  -- NOT parked
    run2 "$1" "$T/$1.o" "$T/$1.e"; check "$3 exit 0" 0 $?
    grep -vE "^Search list:|^stop:|^$" "$T/$1.o" > "$T/$1.f"
    diffcheck "$3" "$2" "$T/$1.f"
}
iterrunLIVE iterT1 genLadder/iterT1.target "iterT1 (per-frame locals, deep)"

#  T3 -- rewind, and := as the only reset. Fresh and exhausted are the same
#  state deliberately, and emitPlan's two passes depend on it. `resetSame` is
#  the case with teeth: `grup := argument;` READS LIKE A NO-OP AND IS NOT ONE.
iterrun iterT3 genLadder/iterT3.target "iterT3 (rewind, := reset)"

#  T1m -- GRADUATED 2026-08-20, from a pinned WRONG answer to a real target.
#  Tony ran incant/fixits/iterT1m, read the walk, and blessed it. This is the
#  iterT1 graduation a second time (H6): a pin that starts holding must become
#  either a full check or a deliberately pinned defect, never stay a stale pin.
#
#  WHAT THE TARGET NOW HOLDS: the 7-line trace -- A trunk / B leafA / A i /
#  A j / B leafB / A k / A l -- every node visited exactly ONCE, in order.
#  That is the answer incant/iterT1m's own header PRE-REGISTERED as correct
#  ("7 in that order"), so this is not a green diff blessed for being green:
#  the fixture named the right answer before the world produced it.
#
#  THE SENTENCE THE RE-PIN RULE ASKS FOR, and it is a subsequence claim rather
#  than a count: the old 14-line divergence pin differed from today's output by
#  DELETIONS ONLY -- 4d3, 6,7d4, 9,10d5, 13,14d7, nothing added and nothing
#  reordered. Today's walk IS the old walk with its seven duplicate visits
#  removed. That is exactly "each node once" and it is why the move is legible
#  without a bisect. It is also the SAME 7-changed-line diff KE-4 measured on
#  2026-08-13, so the walk has not moved since; only the refusal count has.
#
#  ⚠ WHAT IS *NOT* CLAIMED, because the fixture's own header would have you
#  claim it: the header reasons "7 in that order -> the inference covers mutual
#  recursion after all". THAT INFERENCE IS UNSUPPORTED. field.recursive is still
#  set by identity against currentMETHOD (ruleActions.rtn:1320, unchanged), so
#  it still covers DIRECT self-reference only and neither walkA nor walkB names
#  itself. The walk is right for some OTHER reason, and which one is not
#  established. The target pins the ANSWER, which Tony has read; it does not
#  pin a mechanism nobody has measured.
iterrunLIVE iterT1m genLadder/iterT1m.target "iterT1m (mutual recursion, each node once)"
#  ⚠ THE REFUSAL IS ASSERTED BY COUNT, NOT BY ABSENCE OF A HANG (rule H4).
#  Before 2026-08-02 this fixture did not fail -- it HUNG, at 1,475,745 refusals,
#  because a refused `iterate` returned before setting isIterator, so `while
#  ++grup` missed opPlusPlus's iterator arm and fell through to the DATA arm,
#  which returns a truthy node forever. A refused source is now announced once
#  and POISONED, and the advance is the poison's only reader.
#  Asserting the NUMBER rather than "it finished" means the check breaks if the
#  announcement is deleted, if the poison stops taking, OR if mutual recursion
#  silently starts working.
#
#  ⚠ RULED AND RESTORED 2026-08-20, and the count is 4 rather than 7 for a
#  reason worth keeping. KE-4 held this row red pending a cause and named three
#  candidates. It resolved to the FIRST -- the announcement was DELETED, in
#  9c4962b (2026-08-15). The poison was never the problem: the refusal arm's
#  real work, `if iterator iterator.fLAG = true; return 0;`, was intact the
#  whole time and the walk terminated correctly without the cerr. What was lost
#  was the ability to ASSERT it, since nothing printed and the only pin
#  available was zero -- an absence assertion, which H4 forbids.
#  Tony ruled RESTORE. The line is back in ruleActions.rtn's refusal arm,
#  verbatim from 9c4962b^, and the fleet can measure the poison again.
#  ⚠ WHY 4 AND NOT 7: seven was the count under the BROKEN walk, which visited
#  seven leaves because it revisited them. The walk now visits each node once,
#  so there are exactly four leaf visits -- i, j, k, l -- and one refused
#  iterate each. The number moved because the WALK moved, not the announcement.
#  Both halves of this fixture are now live checks and neither is a pinned
#  defect: the trace above, and the count below.
n=$(grep -c "aCTionIterate: source" "$T/iterT1m.e")
if [ "$n" = 4 ]; then echo "  ok    iterT1m announces its refusal 4 times (once per leaf)"; green=$((green+1))
else echo "  FAIL  iterT1m refusal count is $n, want 4 -- the announcement, the poison, or the walk's leaf count has moved; 0 means the cerr in aCTionIterate's refusal arm is gone again (it was, once: 9c4962b)"; fail=1; fi

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
    run1 "$1" "$T/$1"
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

#  ---------------------------------------------------------------------------
#  THE IA-2 PIN -- THE RULING MADE EXECUTABLE. SEQ 61, 2026-08-13.
#
#  bindSeamB binds a generated C++ parse method to Braced by CROSS-FILE
#  re-definition, so it exercises two things nothing else in this fleet does:
#  the bind-read seam (SEQ 58) and the generated arm of an alternation option
#  (IA-2/GM-29). Its value was unpinnable until 2026-08-13 because the correct
#  answer had not been chosen; the director's PC-1 restatement chose it, which
#  is what dissolved H6's objection to pinning.
#
#  bindSeamA is the ORACLE and is pinned beside it deliberately: the same
#  fixture with no bind, reaching the same rule through the INTERPRETED arm.
#  Both want 251. A pin without its oracle would say nothing about which arm
#  produced the number.
#
#  ⚠ AND THE THIRD ROW IS THE ONE THAT MAKES THE PIN HONEST. 251 ALONE CAN
#  PASS FOR THE WRONG REASON. If the cross-file bind ever silently stops being
#  read -- exactly the SEQ 58 defect, which was live for days -- bindSeamB
#  falls back to the interpreted arm and prints 251 ANYWAY, because the
#  interpreted arm has always worked. The value check would go green while
#  certifying the opposite of what it claims. So the arm is asserted BY NAME:
#  promote=0 on Braced's attachLabel line is the generated arm, promote=1 is
#  the interpreted one. bindSeamA is checked for promote=1 for the same reason
#  in the other direction -- an oracle that quietly started using the generated
#  arm would stop being an oracle.
#
#  ⚠ TRIPWIRE DUTY: this pin is also IT-3's. When the promote/isTarget case is
#  demolished, the IA-2 cell needs an action-layer carrier first (the option's
#  label yielded upward -- attaching it into the grandparent's subtree was
#  built and measured RED, SEQ 59 rung 2b). Delete the case without supplying
#  the carrier and this row goes red. That is intended, not incidental.
#  ---------------------------------------------------------------------------
branchrun bindSeamA "BINDSEAMA SENTINEL" "bindSeamA runs (IA-2 oracle, interpreted arm)"
valcheck  bindSeamA "sumple width is now " 251 "bindSeamA oracle value (251)"
if grep -q "attachLabel lab=Braced promote=1" "$T/bindSeamA"; then
    echo "  ok    bindSeamA reaches Braced by the INTERPRETED arm (promote=1)"; green=$((green+1))
else
    echo "  FAIL  bindSeamA -- no promote=1 Braced attach; the oracle is not on the interpreted arm"; fail=1
fi
branchrun bindSeamB "BINDSEAMB SENTINEL" "bindSeamB runs (IA-2 pin, generated arm)"
valcheck  bindSeamB "sumple width is now " 251 "bindSeamB PINNED at 251 -- PC-1 restated, SEQ 61"
if grep -q "attachLabel lab=Braced promote=0" "$T/bindSeamB"; then
    echo "  ok    bindSeamB reaches Braced by the GENERATED arm (promote=0)"; green=$((green+1))
else
    echo "  FAIL  bindSeamB -- no promote=0 Braced attach; the cross-file bind is NOT being read,"
    echo "        and the 251 above is the interpreted arm answering. See SEQ 58."; fail=1
fi

#  ---------------------------------------------------------------------------
#  displayForm -- THE INTERPRETER PIN. Step 0 of the displayForm arc (Tony +
#  Clay addendum, 2026-08-04). Tony's own tests in IncantForms/WorkingOn/tester
#  pass and are happy-path by design; this pins the same action against a tree
#  carrying nesting to depth 2, a noPrint attribute, and a leaf with attributes
#  and no members.
#  ⚠ WHAT IT ASSERTS IS "THIS IS WHAT IT DOES TODAY", NOT "THIS IS RIGHT".
#  Tony's standing rule: no error-hunting on working code -- pin it, run it,
#  deal with what the diff turns up when it turns up. The output WAS reviewed
#  once before capture (noPrint attributes correctly skipped, indentation
#  correct at both depths, a bare member printing its tag and nothing else).
#  ⚠ THE ACTION IS A VERBATIM COPY of the one in tester, so this baseline is
#  stale the moment that one changes -- and the diff is the notification.
#  Later designation, not yet in force: displayForm is the convergence fixture
#  for the JIT arc, certifying the assembled stack once the attribute-method
#  POP, the iterator fix and the KANT-8 hunt have landed individually.
run1 displayFormT "$T/dsp";  check "displayFormT runs" 0 $?
sentinel "displayFormT sentinel" "$T/dsp" "displayFormT SENTINEL"
diffcheck "displayForm baseline (interpreter pin)" genLadder/displayForm.base "$T/dsp"

#  ---------------------------------------------------------------------------
#  THE ACTION-LOCAL COUNTER, promoted from Tony's fixit queue 2026-08-25 after
#  bisectQmover was stepped and blessed. It is the regression test for the trap
#  that produced that citizen: an UNDECLARED name in an action body is an action
#  LOCAL, cleared on entry by parseRule/processAction, so two actions sharing an
#  undeclared counter each get their OWN node and the bumps never land.
#
#  ⚠ ROW U EXPECTS ZERO AND THEREFORE CANNOT STAND ALONE -- a fixture that ran
#  nothing would also read 0. ROW D IS ITS ANTI-VACUITY SIBLING and wants 3, so
#  it fails unless the counter mechanism is genuinely live. Pair kept per the
#  standing rule: every zero-expecting row gets a non-zero sibling.
#
#  ⚠ AND ROW U GOING RED IS NOT AUTOMATICALLY A BUG -- it means the LANGUAGE
#  changed. If action locals stop being cleared per invocation, this row is the
#  first thing in the fleet that will say so, and the right response is a ruling,
#  not a repair. bear-trap #38 is its twin one construct over.
run1 actionLocalT "$T/alc";  check "actionLocalT runs" 0 $?
sentinel "actionLocalT sentinel" "$T/alc" "ACTIONLOCALT SENTINEL"
if grep -q "^AL D ok" "$T/alc"; then
    echo "  ok    action-local: a DECLARED counter is shared across actions (3 bumps land)"; green=$((green+1))
else
    echo "  FAIL  actionLocalT row D -- a declared counter did not reach 3, so the"
    echo "        anti-vacuity sibling is dead and row U below asserts nothing."; fail=1
fi
if grep -q "^AL U ok" "$T/alc"; then
    echo "  ok    action-local: an UNDECLARED counter is per-action (bumps do not land)"; green=$((green+1))
else
    echo "  FAIL  actionLocalT row U -- an undeclared counter MOVED across actions."
    echo "        Action-local clearing semantics have changed. This wants a RULING,"
    echo "        not a repair: incant/bisectQ and every emitter copy depend on it."; fail=1
fi

#  ---------------------------------------------------------------------------
#  F-15 REGRESSION + THE PARTITION GUARD. Both landed 2026-08-18 with the guard
#  reorder in parse; ruling 3 makes the census a standing fleet check.
#
#  altShadowT is the F-15 control, graduated per H6. It poisons a members-shaped
#  rule with one noPrint attribute and asserts the alternation still matches. Its
#  row C is the vacuity guard: a poison that never landed would also let row B
#  pass, so the attribute is named back rather than assumed.
run1 altShadowT "$T/alt";    check "altShadowT runs (F-15 regression)" 0 $?
sentinel "altShadowT sentinel" "$T/alt" "ALTSHADOWT SENTINEL"
if grep -q "^B ok" "$T/alt"; then
    echo "  ok    F-15 stays closed: a poisoned alternation rule still parses"; green=$((green+1))
else
    echo "  FAIL  F-15 HAS RETURNED -- one noPrint attribute killed an alternation rule."
    echo "        The arm order in parse, or its !data gate, has moved. See fixIts F-15."; fail=1
fi
if grep -q "^C guard poisoned rule carries attribute" "$T/alt"; then
    echo "  ok    altShadowT vacuity guard: the poison demonstrably landed"; green=$((green+1))
else
    echo "  FAIL  altShadowT VACUITY: no attribute on the poisoned rule, so the row"
    echo "        above asserts nothing. The check passed by not testing anything."; fail=1
fi

#  ⚠ THE PARTITION GUARD ASSERTS A SET BY NAME, NOT A COUNT, AND THE SET IS NOW
#  EMPTY. Re-pinned 2026-08-19. It used to expect { BrancheS Operators } and its
#  own note said the row goes red "when it splits". It did not split -- the
#  CLASSIFIER was wrong about it. A bin or registry's data is DERIVED, not
#  authored: GroupItem::addGroup folds each member's first character into the set
#  at add-member time, one character per member, and nothing anywhere authors it.
#  So that datum is a cache of the membership, never a rule-level alternative to
#  it, and the two rules were reported as hybrids that were never written.
#  shadowCensus now exempts a container by the SAME `binTypE` test addGroup writes
#  under. Both rules moved -MD- -> -M--, the members-shaped population went 11 ->
#  13, and pick-one holds with NO exceptions for the first time.
#
#  ⚠ AN EMPTY EXPECTED SET IS AN ABSENCE CHECK UNLESS SOMETHING PROVES THE COLUMN
#  STILL WORKS (rule H4), and a D column that had gone inert would produce exactly
#  this empty set. So the data-only population is asserted non-zero on the row
#  below, beside the existing rows/members guards. All three must hold before the
#  emptiness means anything.
run1 shadowCensus "$T/sc";   check "shadowCensus runs (pick-one partition)" 0 $?
sentinel "shadowCensus sentinel" "$T/sc" "SHADOWCENSUS SENTINEL"
scrows=$(grep -c "^row " "$T/sc")
scmembers=$(grep "^row " "$T/sc" | awk '$3=="M"' | wc -l | tr -d " ")
scdata=$(grep "^row " "$T/sc" | awk '$4=="D"' | wc -l | tr -d " ")
schybrid=$(grep "^row " "$T/sc" | awk '$3=="M" && $4=="D" {print $NF}' | sort | tr "\n" " ")
#  Anti-vacuity: a census that walked nothing would report an empty hybrid set
#  and pass. Both populations are asserted non-zero first, so an inert walk is
#  a failure and not a clean bill of health.
if [ "$scrows" -gt 0 ] && [ "$scmembers" -gt 0 ] && [ "$scdata" -gt 0 ]; then
    echo "  ok    shadowCensus walked $scrows rules, $scmembers members-shaped, $scdata data-shaped (non-vacuous)"; green=$((green+1))
else
    echo "  FAIL  shadowCensus walked nothing, or a COLUMN went inert"
    echo "        ($scrows rows, $scmembers members-shaped, $scdata data-shaped)."
    echo "        The empty hybrid set below would be empty for that reason, not"
    echo "        because the population is clean."; fail=1
fi
if [ -z "$schybrid" ]; then
    echo "  ok    pick-one: data-plus-members set is EMPTY -- no exceptions"; green=$((green+1))
else
    echo "  FAIL  pick-one partition MOVED: data-plus-members set is { $schybrid}"
    echo "        Expected EMPTY. A container's derived set is exempt by binTypE;"
    echo "        anything appearing here is a rule that was genuinely written as"
    echo "        both, which is what pick-one forbids."; fail=1
fi

diffcheck "oneTest baseline"  genLadder/oneTest.base  "$T/one"
diffcheck "jsonTest baseline" genLadder/jsonTest.base "$T/jsn"

#  ===========================================================================
#  THE genParse ODOMETER, wired in 2026-08-24 once its first baseline existed.
#
#  ⚠ WHAT THIS ROW IS AND IS NOT. It is NOT a pass/fail on parse generation --
#  the odometer is RED by design today (45 of 64) and a red odometer is the
#  correct state. This row asserts only that the number HAS NOT MOVED WITHOUT
#  SOMEONE SAYING SO. A moved odometer is the point of having one; it just has
#  to be a re-pin with a sentence behind it, like every other target here.
#
#  The `bin` lines are filtered because H1 makes the harness echo the binary's
#  size and mtime, which move on every rebuild for reasons that say nothing
#  about genParse -- rule H3, assert the thing that only moves when the answer
#  moves.
#
#  ⚠ AND THE NAME IS LOAD-BEARING: this is the genParse count, never the
#  scaffold count. genLadder/countPop.sh measures incant/f31's fbGen and asks
#  whether emitted text PARSES; this measures planRule/emitPlan/emitLeaf and
#  asks whether a rule can be PLANNED AND EMITTED. Two numbers, two subjects,
#  and conflating them in a citation is the failure this wording exists to
#  prevent.
bash genLadder/odometer.sh 2>&1 | grep -v '^  bin ' > "$T/odo"
diffcheck "genParse odometer (19 green / 45 red of 64 -- RED BY DESIGN, pinned; ratchet monotone)" \
          genLadder/odometer.base "$T/odo"

#  ---- THE SCAFFOLD COUNT, ruled into the fleet by Clay 2026-08-28 -----------
#  ⚠ IT IS THE SOLE ASSERTOR THAT `DatA` DOES NOT CRASH THE COMPILER. That was
#  incant/fixits/dataCrash's entire surviving coverage when it retired by
#  mapping, and until now it lived OUTSIDE the standing instrument -- an
#  assertion that only runs when someone remembers to run it, which is the
#  ghost mechanism this fleet exists to abolish. 2.3s against the fleet's 3.5s.
#
#  ⚠ WHAT IS AND IS NOT ASSERTED HERE. countPop.sh is RED-BY-DESIGN about FAIL
#  and CRASH rows -- those are the genParse frontier, like the odometer -- so a
#  frontier row must NOT fail this fleet. What its exit status DOES carry is the
#  instrument's own integrity: a MISSING row (a name the population handed it
#  that compile never took), a truncated population walk, an empty population,
#  or attempted != population. Those are the harness disagreeing with itself,
#  and they are never facts about genParse.
#  So: exit 0 is asserted, and the headline is asserted BY VALUE (H4) rather
#  than by the absence of a complaint.
bash genLadder/countPop.sh > "$T/cnt" 2>&1; check "countPop runs (scaffold count; instrument integrity)" 0 $?
sentinel "countPop sentinel (no truncation)" "$T/cnt" "COUNTPOP SENTINEL"
#  H4: the count is compared BY VALUE. A row that merely greps for the word
#  "clean" would pass the day the number went to zero.
cntline=$(grep -m1 '^THE COUNT:' "$T/cnt")
if [ "$cntline" = "THE COUNT: 39 compiled clean, 0 parse-failed, 0 crashed/truncated, 0 missing, of 39 attempted" ]; then
    echo "  ok    countPop headline (39/39 clean, 0 missing) -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  countPop headline moved"; echo "          actual:   $cntline"
    echo "          expected: THE COUNT: 39 compiled clean, 0 parse-failed, 0 crashed/truncated, 0 missing, of 39 attempted"
    fail=1
fi

echo ""
if [ $fail = 0 ]; then echo "POP PASSED -- $green green / $parked parked-WIP"
else echo "POP FAILED -- $green green / $parked parked-WIP"; fi
if [ $parked != 0 ]; then
    echo "              parked = iterator fixtures pinned to the OLD design;"
    echo "              semantics are Tony's offline work and nothing is owed until it lands."
fi
rm -rf "$T"
exit $fail
