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
#
#  ⚠⚠ AND IF YOU ARE THE PERSON SWITCHING ON THAT CONTENT DIFF, READ THIS FIRST.
#  incant/baselineTests.golden IS A DELIBERATELY MIXED ARTIFACT AS OF 2026-09-01.
#  Its testOR row (line 16) was re-pinned that day under Tony's ruling -- the
#  function is correct as designed and the pin was eleven weeks stale. Its OTHER
#  TWO drifted clusters were left STALE ON PURPOSE, parked by the same ruling and
#  still unattributed:
#        lines 65-66   second=56 / third=WTF?   (values disappearing)
#        lines 70-71   width=50% / text         (see incant/fixits/goldenDrift)
#  So a content diff turned on today comes up RED ON TWO CLUSTERS BY DESIGN. That
#  is the pin being honest, NOT a regression -- do not "fix" it by re-pinning
#  them, which is precisely the move goldenDrift's clause 2 prohibits: re-pinning
#  an unattributed drift banks an unknown breakage as normal, permanently, and no
#  later reader can tell the difference. Attribute first, then pin.
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

#  ============================================================================
#  ⚠ argWriteT -- A PRE-FLIP INSTRUMENT, GREEN NOW SO IT CAN GO RED LATER.
#  Added 2026-08-30 with the bind-by-body build plan (docs/wrapperPlan.md §4).
#
#  A write through an action's argument REACHES THE CALLER'S FIELD today -- R2
#  reads 5. That is delivered by the AUTO-UNWRAP, which the migration removes:
#  plain `=` carries no assign flag, so runOP's !op.isAssign arm is true and the
#  target is unwrapped to the caller. Retire the unwrap without the wrapper and
#  the write silently stops arriving -- no error, no crash, NO K-ROW MOTION.
#  The fleet had nothing that would notice. Now it does.
#
#  R3 is the anti-vacuity sibling and is not decoration: a run where writes leak
#  everywhere, or where every field happens to read 5, passes R2 and means
#  nothing. Asserted by VALUE per H4, never by absence of an error.
run1 argWriteT "$T/aw"; check "argWriteT runs" 0 $?
if grep -q "ARGWRITE SENTINEL" "$T/aw"; then
    echo "  ok    argWriteT sentinel (no truncation)"; green=$((green+1))
else
    echo "  FAIL  argWriteT sentinel MISSING -- run truncated, rows above uninterpretable"; fail=1
fi
for _r in "R1 read through the argument       7" \
          "R2 caller after write through arg  5" \
          "R3 untouched sibling               7" \
          "R4 read a GROUP-carrying caller    99"; do
    if grep -qF "$_r" "$T/aw"; then
        echo "  ok    argWriteT ${_r%% *} (write through an argument reaches the caller)"; green=$((green+1))
    else
        echo "  FAIL  argWriteT ${_r%% *} -- wanted: $_r"; fail=1
    fi
done

#  ============================================================================
#  ⚠ K7 -- THE FRAME BRACKET vs A FIELD THAT IS BOTH DATA AND BEHAVIOUR.
#  Added 2026-08-30, and the reason it is HERE rather than only in kant8T is the
#  promotion convention: would the fleet have caught it? It did not, for 20 days.
#
#  The frame bracket wrote its save-stack into the ACTION NODE'S DATA SLOT. For
#  an ordinary action that slot is empty and the write is free; for a field
#  carrying a VALUE and a CODE BLOCK it held the value, and the bracket
#  destroyed it -- data type 5 becoming 12 (isSTAK), measured. kant8T was in NO
#  pop script, so its whole K-family rode outside the fleet; and every K row was
#  GREEN throughout anyway, because no other row uses a data-carrying action.
#
#  ⚠ ASSERTED BY VALUE, NEVER BY ABSENCE OF THE ERROR (rule H4). The failure
#  prints a NAME plus a toString complaint, so "grep -v the complaint" would go
#  green the day the complaint text changes. Each arm's 46 is compared instead.
#  THREE ARMS BECAUSE ONE CANNOT DISCRIMINATE: K7b falling means `+=` itself is
#  out, K7c falling means actions are broken generally -- and in either case
#  K7a says nothing about THIS class. H7 negative control, run at promotion:
#  with the repair reverted, K7a goes red while K7b, K7c, K1 and K5 stay green.
run1 kant8T "$T/k8"; check "kant8T runs" 0 $?
if grep -q "kant8T SENTINEL" "$T/k8"; then
    echo "  ok    kant8T sentinel (no truncation)"; green=$((green+1))
else
    echo "  FAIL  kant8T sentinel MISSING -- the run truncated; every K row above is uninterpretable"; fail=1
fi
for _arm in "K7a own name returned = 46" \
            "K7b other field returned = 46" \
            "K7c no field at all returned = 46"; do
    if grep -qF "$_arm" "$T/k8"; then
        echo "  ok    ${_arm%% returned*} = 46 (frame bracket leaves a data+code field's value alone)"; green=$((green+1))
    else
        echo "  FAIL  $_arm -- got: $(grep -o "${_arm%% returned*}[^(]*" "$T/k8" | head -1)"; fail=1
    fi
done

#  ============================================================================
#  ⚠⚠ K2x -- A TRIPWIRE PINNED AT A DEFECT ON PURPOSE. Added 2026-09-01, SEQ 103.
#
#  kant8T's K2 asks "does an argument dodge the frame restore?" and answers 7 --
#  and 7 IS WHAT A TRAMPLED RUN PRINTS TOO, because K2 passes `argument` straight
#  down, so the inner activation binds the value the outer already had. It has
#  discriminated nothing for a month while being read as the gate's answer.
#
#  K2x is K2 with the one defect removed: a DIFFERENT node goes down, and the
#  witness is `.taG` rather than the node (printing a group node prints its
#  ATTRIBUTE COUNT -- a legal-looking number in the answer's own range).
#
#  ROWS 0 AND 2 ARE ANTI-VACUITY CONTROLS AND MUST BE GREEN FOREVER. Row 0 is a
#  bare non-recursive call; row 2 is the same action with the recursive branch
#  never taken. If either goes red the fixture is void and row 1 means nothing --
#  which is the whole failure K3 exists to prevent one row up.
#
#  ⚠⚠ ROW 1 RE-PINNED 2026-09-01, k2xSmall -> k2xBig, AND HERE IS THE SENTENCE.
#  It was pinned at the WRONG answer on purpose, as a tripwire for exactly this
#  event, and the tripwire fired: THE FRAME BIND LANDED (SEQ 106) and the trample
#  is fixed in BOTH directions of recursion. The cause is one statement's
#  position -- saveLocalFields now runs BEFORE the argument bind in runAction, so
#  the frame captures the OUTER argument and restore returns it, where before it
#  captured the NEW one and handed the inner's back. K6c moved with it,
#  k6small -> k6big, on the same run and the same mechanism.
#  The falsified asymmetry stays falsified: K6c's own comment claimed "in DIRECT
#  recursion an argument DODGES the emptying", and K2 could not see otherwise
#  because it passed its argument straight down. One mechanism covers both rows.
#  ⚠ K6c IS PINNED HERE AS OF 2026-09-01 BECAUSE IT WAS NOT, AND THAT WAS A HOLE.
#  Certificate 2 of the frame-bind charter leaned on K6c -- mutual recursion
#  A->B->A carrying an argument -- and NO FLEET ROW PINNED IT. When the SEQ 107
#  copy-bind attempt regressed it from k6big to k6small, the fleet stayed at 101
#  green and said nothing; it was caught only because the certificate was re-run
#  by hand. A certificate the fleet cannot see is a certificate that expires the
#  day someone stops re-running it.
#  It is the MUTUAL sibling of K2x row 1's DIRECT case, and the two are pinned
#  together deliberately: the save reorder fixed both, and any change that moves
#  one without the other is a finding.
if grep -qF "K6c outer returned = k6big" "$T/k8"; then
    echo "  ok    K6c outer = k6big (mutual recursion carries its own argument) -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  K6c outer -- got: $(grep -o 'K6c outer returned = [a-zA-Z0-9]*' "$T/k8" | head -1)"; fail=1
fi
for _arm in "K2x row 0 control  = k2xBig" \
            "K2x row 1 recursed = k2xBig" \
            "K2x row 2 depth 0  = k2xBig"; do
    if grep -qF "$_arm" "$T/k8"; then
        echo "  ok    ${_arm%% =*} = ${_arm##*= } -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  $_arm -- got: $(grep -o "${_arm%% =*}[^(]*" "$T/k8" | head -1)"; fail=1
    fi
done

#  ============================================================================
#  ⚠ holderT -- .parenT THROUGH AN ACTION-ARGUMENT HOLDER. Added 2026-09-01.
#
#  THIS IS ALL THAT REMAINS OF incant/fixits/parentUnreachable, which retired by
#  ruling in the fixit cull (SEQ 104). The citizen's text is in incant/attic; its
#  ASSERTION is here, and this comment is the mapping.
#
#  An action reaches its argument's PROPERTIES correctly through the holder and
#  its argument's PARENT incorrectly -- runAction binds by `ruleArg.group =
#  argument`, so the node-returning case hands back the HOLDER, tagged
#  `argument`. Rows 1 and 2 are the anti-vacuity pair and must be green always:
#  without the direct read, row 3 cannot tell "the holder loses the parent" from
#  "the accessor is broken everywhere".
#
#  ⚠ ROW 3 IS PINNED AT THE WRONG ANSWER ON PURPOSE. The holder read is the
#  implicit unwrap THE FLIP REMOVES, so WHEN THE FLIP LANDS THIS ROW GOES RED.
#  That is the fix arriving, not a regression. Re-pin to htWindow with the
#  sentence.
run1 holderT "$T/hold"; check "holderT runs" 0 $?
if grep -q "HOLDERT SENTINEL" "$T/hold"; then
    echo "  ok    holderT sentinel (no truncation)"; green=$((green+1))
else
    echo "  FAIL  holderT sentinel MISSING -- the run truncated"; fail=1
fi
for _arm in "holderT 1 direct    .parenT = htWindow" \
            "holderT 2 identity  .taG    = htInside" \
            "holderT 3 holder    .parenT = argument"; do
    if grep -qF "$_arm" "$T/hold"; then
        echo "  ok    ${_arm%% =*} = ${_arm##*= } -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  $_arm -- got: $(grep -o "${_arm%% =*}[^ ]*.*" "$T/hold" | head -1)"; fail=1
    fi
done

#  ============================================================================
#  ⚠ nestT -- f(g(x)), A CALL IN ARGUMENT POSITION. Certificate 3 of the frame
#  bind (SEQ 106), added 2026-09-01.
#
#  When the outer call's argument is itself a call, the INNER activation binds an
#  argument while the OUTER one is still being set up. WRITE-LAST is what makes
#  that safe -- the caller evaluates every argument expression first and writes
#  the frame slot last, so g's bind has finished and been consumed before f's is
#  written. Row 2 is the certificate; if it ever reads ntBig, the inner bind
#  clobbered the outer setup.
#
#  ⚠ g DELIBERATELY IGNORES ITS ARGUMENT AND RETURNS A DIFFERENT NODE, and that
#  is the discrimination rather than a quirk: a g that returned its own argument
#  would print the right answer whether or not the channel worked. That is
#  exactly kant8T's K2 mistake, which discriminated nothing for a month.
#  Rows 0 and 1 are the anti-vacuity pair -- f reads its argument at all, and f
#  reports what it is given rather than a constant.
run1 nestT "$T/nest"; check "nestT runs" 0 $?
if grep -q "NESTT SENTINEL" "$T/nest"; then
    echo "  ok    nestT sentinel (no truncation)"; green=$((green+1))
else
    echo "  FAIL  nestT sentinel MISSING -- the run truncated"; fail=1
fi
for _arm in "f(ntBig)      = ntBig" \
            "f(ntSmall)    = ntSmall" \
            "f(g(ntBig))   = ntSmall"; do
    if grep -qF "$_arm" "$T/nest"; then
        echo "  ok    nestT ${_arm%% =*} = ${_arm##*= } -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  nestT $_arm -- got: $(grep -oF "${_arm%% =*}" "$T/nest" | head -1)"; fail=1
    fi
done

#  ============================================================================
#  ⚠ spacingT -- THE SPELLING LAW, and F-36's certificate. Added 2026-09-01.
#
#  TIGHT BINDS, SPACED DOES NOT: an operator character written tight to its
#  operand is the prefix/unary form; the same character with a space is the
#  binary form and binds to what PRECEDES it. Longest match picks the token,
#  spacing picks the operator. User beware, no guard.
#
#  ⚠ ROWS A-D ARE ASSIGNMENT POSITION, ROW E IS PRINT-ITEM POSITION, AND THEY ARE
#  DIFFERENT MEASUREMENTS. With nothing to the left, `* *x` is unary-of-unary and
#  composes; with a literal to the left it is BINARY MULTIPLY. Same three
#  characters, two operators. Row E is the line F-36 actually reported.
#
#  ⚠ ROW A IS THE ANTI-VACUITY CONTROL: a single `*` on a field holding no group
#  must stay a CLEAN error returning nothing. If it becomes a crash, or starts
#  succeeding, rows B-E assert nothing.
#  ⚠ ROWS A, C, D READ BACK AS THEIR OWN TAG. That is bear-trap #26 working as
#  designed -- a refusal leaves the field with no data, and a field with no data
#  returns its tag -- so pinning the echo is pinning "holds nothing".
run1 spacingT "$T/spc"; check "spacingT runs" 0 $?
if grep -q "SPACINGT SENTINEL" "$T/spc"; then
    echo "  ok    spacingT sentinel (no truncation)"; green=$((green+1))
else
    echo "  FAIL  spacingT sentinel MISSING -- F-36 regressed to a crash"; fail=1
fi
for _arm in "spacingT A tight-1  = spA" \
            "spacingT B tight-2  = spB" \
            "spacingT C spaced   = spC" \
            "spacingT D tight-3  = spD" \
            "spacingT E survived"; do
    if grep -qF "$_arm" "$T/spc"; then
        echo "  ok    ${_arm} -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  $_arm -- missing"; fail=1
    fi
done
#  H4: every refusal is asserted BY ITS TEXT, never by the absence of a crash.
#  A check that passed because no message appeared would also pass the day
#  somebody deleted the guard, which is the failure H4 exists to forbid.
#
#  ⚠ F-41's EIGHT ROWS. Each drives ONE operator into a refused operand with the
#  spelling `a OP *b`, where b holds no group -- so the tight unary refuses and
#  hands the operator nothing. Guards added 2026-09-01 after F-36 measured the
#  crash on opMultiply and a structural census found seven siblings with zero
#  guards against 3-6 dereferences each.
#  ⚠ THESE ROWS ARE ONLY MEANINGFUL WHILE spacingT ROW A IS GREEN. Row A is the
#  unary still refusing cleanly; if it ever starts succeeding there is no null,
#  and all eight rows below go green while asserting nothing.
for _op in "*" "+" "-" ">" "<" "==" ">=" "<="; do
    if grep -qF "ERROR Operator $_op failed on Token and a refused operand" "$T/spc"; then
        echo "  ok    spacingT refuses BY NAME on '$_op' (F-41)"; green=$((green+1))
    else
        echo "  FAIL  spacingT '$_op' named refusal missing -- its guard stopped naming it"; fail=1
    fi
done
if grep -qF "spacingT F seven operators driven into a refused operand" "$T/spc"; then
    echo "  ok    spacingT F reached (all eight operators were actually driven)"; green=$((green+1))
else
    echo "  FAIL  spacingT F marker missing -- the operator rows did not run"; fail=1
fi
#  ⚠ THE LONGEST-MATCH ROWS -- the spelling law, certified on the machine.
#  `+*` already existed as opCopyList (incant/setup) with ZERO call sites, so the
#  law could be asked without minting anything. H and I differ from G by ONE
#  SPACE and nothing else, which is the whole hazard and is correct behaviour.
#  ⚠ G USES `**`, NOT `*`, AND THAT IS A MEASURED CORRECTION TO THE LAW AS
#  STATED. A single `*` unwraps one level PAST the leaf and refuses at every
#  wrapping depth, so `a + *b` does not read a pointer -- `a + **b` does.
#  ⚠ G2 PINS `a + *b` AS A REFUSAL ON PURPOSE. The `*` quarantine lifts at the
#  flip; if a single star ever starts reading a pointer, G2 goes RED and somebody
#  re-reads the law. A row that only agreed with itself could not do that.
for _arm in "spacingT G a + **b  = spG" \
            "spacingT G2 a + *b  = spG2" \
            "spacingT H a +* b   = 1" \
            "spacingT I a+*b     = 1"; do
    if grep -qF "$_arm" "$T/spc"; then
        echo "  ok    ${_arm} -- PINNED BY VALUE (longest match)"; green=$((green+1))
    else
        echo "  FAIL  $_arm -- got: $(grep -oF "${_arm%% =*}" "$T/spc" | head -1)"; fail=1
    fi
done

#  ============================================================================
#  ⚠ starT -- THE STAR LAW. Added 2026-09-01 (SEQ 111). `*x` reads ONE level,
#  `**x` is `*` applied TWICE, a `*` past the leaf refuses, and a fixpoint read
#  is a named call or nothing. `**` left the operator table and the UnaryOPS bin;
#  opDerefAll retired with it (zero call sites). derefAllT retired BY MAPPING into
#  this fixture -- it was never in the fleet, so no coverage moved.
#  ⚠ EVERY ROW IS FLIP-GATED AND PINNED AT ITS FLIP-OFF VALUE. Flip-off the
#  auto-unwrap overshoots and every star refuses; the whole file goes red at the
#  flip and re-pins, deliberately, like holderT row 3.
#  ⚠⚠ S3a IS RECORDED UNRESOLVED, NOT GRADED. Under the flip it READ where the law
#  says refuse -- a fixpoint signature -- but neither witness can be trusted: a
#  printed pointer follows the chain, and the tag witness returns `argument`
#  because of the carrier defect. The instrument is blocked by the defect the
#  campaign is fixing. S4 is the only row asserting something the law uniquely
#  predicts today.
run1 starT "$T/star"; check "starT runs" 0 $?
if grep -q "START SENTINEL" "$T/star"; then
    echo "  ok    starT sentinel (no truncation)"; green=$((green+1))
else
    echo "  FAIL  starT sentinel MISSING"; fail=1
fi
for _arm in "starT S1  *x   one-deep   = stA" \
            "starT S3a **x  ONE-deep   = stD" \
            "starT S4  *x   on a LEAF  = stF"; do
    if grep -qF "$_arm" "$T/star"; then
        echo "  ok    ${_arm} -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  $_arm -- moved"; fail=1
    fi
done

#  ============================================================================
#  ⚠ pointerT -- THE `+*` CERTIFICATE. Added 2026-09-01 (SEQ 111). `+*` is now
#  opAddPointer: `a +% b` adds a copy, `a +* b` adds a POINTER to b. Read back
#  with a SUBSCRIPT, which already follows the pointer.
#  ⚠⚠ P1 AND P2 ARE A PAIR AND NEITHER MEANS ANYTHING ALONE. P1 writes to the
#  source after the add and must see the NEW value through the pointer.
#  ⚠ P2 IS PINNED AT `CHANGED`, WHICH IS A FINDING, NOT A TARGET. It was written
#  expecting ORIG -- a copy should not see later writes -- and `+%` sees them too,
#  measured identically with the flip ON and OFF. `+%` ALREADY SHARES the source's
#  GroupBody (Bytecode.twk:77 says so). So the copy/pointer difference is the
#  LINK, not the contents, and any plan resting on `+%` isolating a value needs
#  re-reading. If `+%` ever DOES start isolating, P2 goes red and someone reads
#  pointerT's note.
#  ⚠ ROW D IS A FLIP TRIPWIRE: 0 with the flip off, OTHER with it on, measured
#  both ways. Pinned at the baseline value.
#  ⚠⚠ L AND X RE-PINNED 2026-09-01 (SEQ 113) TO TONY'S FOLLOW-THROUGH LAWS.
#  The VALUES did not move; the MECHANISM they were pinned against was wrong, and
#  a value-pinned row cannot catch that by itself. Law 1 print follows; law 2
#  subscript stops at the ELEMENT; law 3 unary binds tightest, `*a[0]` is
#  `(*a)[0]`; law 4 the read of a pointer out of a list is NAME IT THEN STAR IT.
#  L1 was credited to the subscript and belongs to PRINT. X was credited to "one
#  level too many after the subscript read" and is really the star binding to the
#  BAG -- which is why the X ROW BELOW IS PAIRED WITH AN ERROR-TEXT ASSERTION:
#  a row pinned only at 0 goes green the day the star binds the other way.
#  ⚠ L2/L3 ARE A PAIR AND THE PAIR IS THE POINT: `<-` then star FOLLOWS (CHANGED),
#  `=` then star REFUSES (0). "Name it" means REBIND it. L3 exists so the next
#  reader who writes the natural `=` spelling does not conclude the law is broken.
#  ⚠⚠ LAW 2 IS CERTIFIED AS OF 2026-09-02 BY ROW L4, and this comment replaces
#  the one saying it was not. The blocker was identity -- addrOf -- which landed
#  in the SAME stroke (SEQ 113 item 2); nobody walked through the open gate for a
#  day. L4 asks it by ADDRESS: the subscript result is a DIFFERENT BODY from the
#  source (law 2), and the same capture STARRED is the source (law 4).
#  ⚠ THE BODY COLUMN IS PINNED AND THE FIELD COLUMN IS DELIBERATELY NOT. The
#  argument carrier mints a fresh FIELD per call -- the source reads field=#1, #3
#  and #8 in one run while its body stays #2 -- so the rows below match
#  `field=#<anything> body=#<pinned>`. Pinning the field column would be pinning
#  the carrier, which moves for reasons that say nothing about the laws (H3).
#  ⚠ L4b AND L4c ARE THE ANTI-VACUITY PAIR. A column answering "same" to
#  everything passes L4b; one answering "different" to everything passes L4c.
#  Only the pair earns L4d's difference and L4e's match, and those two are each
#  other's control -- law 2 IS the difference, law 4 IS the match, and anything
#  faking one would have to break the other.
#  ⚠ EACH ROW IS ANCHORED TO ITS OWN LABEL LINE (grep -A1), not to a count of
#  matching bodies. Four of the five ADDROF lines carry the tag `ptSrc` and three
#  carry body=#2, so an unanchored grep would pass on the wrong line.
#  ⚠⚠ NEGATIVE CONTROL RECORDED, 2026-09-02 (rule H7 -- a rung certifies only what
#  fails when the mechanism is removed). The subscript was replaced by a direct
#  capture of the source, `ptElem <- ptSrc`, and the fleet re-run:
#
#      MECHANISM REMOVED   L4a ok   L4b ok   L4c ok   L4d FAIL   L4e FAIL
#      MECHANISM PRESENT   L4a ok   L4b ok   L4c ok   L4d ok     L4e ok
#
#  So L4d and L4e are load-bearing and the three control rows are correctly
#  indifferent to the subscript -- which is what they are FOR. L4e failing with
#  L4d is not noise either: with the capture pointing at the source, the star has
#  nothing to follow and refuses, so the pair moves together exactly as the two
#  laws predict.
run1 pointerT "$T/ptr"; check "pointerT runs" 0 $?
if grep -q "POINTERT SENTINEL" "$T/ptr"; then
    echo "  ok    pointerT sentinel (no truncation)"; green=$((green+1))
else
    echo "  FAIL  pointerT sentinel MISSING"; fail=1
fi
for _arm in "pointerT P0 both added   = 1 1" \
            "pointerT P0b before write = ORIG ORIG" \
            "pointerT P1 pointer      = CHANGED" \
            "pointerT P2 copy         = CHANGED" \
            "pointerT R  rebind       = OTHER" \
            "pointerT L  three ptrs   = 3" \
            "pointerT L1 print follows = CHANGED OTHER" \
            "pointerT L2 name-then-star = CHANGED" \
            "pointerT L3 assign-then-star = 0" \
            "pointerT D  depth        = 0" \
            "pointerT X  star binds tightest = 0"; do
    if grep -qF "$_arm" "$T/ptr"; then
        echo "  ok    ${_arm} -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  $_arm -- moved"; fail=1
    fi
done
#  ⚠ THE STAR'S REFUSAL ASSERTED BY ITS TEXT, NOT BY ROW X's ZERO (H4). Row X
#  reads 0 whenever the star refuses ANYTHING; this names WHAT it refused, and it
#  is the only thing in the fleet that would go red if `*a[0]` ever started
#  binding as `*(a[0])` instead of `(*a)[0]`.
if grep -qF "ERROR unary * on ptBagP -- it holds no group" "$T/ptr"; then
    echo "  ok    pointerT X witness: the star bound to the BAG (law 3)"; green=$((green+1))
else
    echo "  FAIL  pointerT X witness MISSING -- the star no longer binds to ptBagP"; fail=1
fi

#  ⚠ L3's REFUSAL, ASSERTED BY ITS TEXT FOR THE SAME REASON X's IS (H4). L3 was
#  pinned only at 0 -- the exact weakness X's comment above forbids -- and the
#  witness had been in the output all along, unread.
#  ⚠ IT NAMES THE SOURCE, NOT THE ASSIGNEE. `=` reimprints the left-hand tag
#  (bear-trap #1), so a reader expects `ptAssigned`. The attribution was MEASURED,
#  not read off the source: minionWork/probeL3name isolates the `=`-then-star
#  shape as the only star in its file and the refusal names the source there too.
if grep -qF "ERROR unary * on ptSrc -- it holds no group" "$T/ptr"; then
    echo "  ok    pointerT L3 witness: the star refused, naming the SOURCE"; green=$((green+1))
else
    echo "  FAIL  pointerT L3 witness MISSING -- the = -then-star refusal changed"; fail=1
fi
for _l4 in "L4a source asked once:|body=#2|source body, first ask" \
           "L4b SAME source again|body=#2|source body REPEATS -- column is stable" \
           "L4c a DIFFERENT field|body=#5|other body DIFFERS -- column discriminates" \
           "L4d the SUBSCRIPT RESULT|body=#7|the subscript STOPPED (law 2, certified)" \
           "L4e that capture STARRED|body=#2|the star REACHED the source (law 4)"; do
    _lbl=${_l4%%|*}; _rest=${_l4#*|}; _want=${_rest%%|*}; _why=${_rest##*|}
    if grep -A1 -F "$_lbl" "$T/ptr" | grep -qE "ADDROF .* $_want( |\$)"; then
        echo "  ok    pointerT ${_lbl%% *}: $_why -- PINNED BY IDENTITY"; green=$((green+1))
    else
        echo "  FAIL  pointerT ${_lbl%% *} -- $_want not on the line after its label"; fail=1
    fi
done

#  ============================================================================
#  ⚠ faceT -- THE PAIR FIXTURE. Added 2026-09-01 (SEQ 113 item 3). Step 3 measured
#  that the definition sweep makes a COPY OF A FIELD sharing the original's body,
#  so a field can have TWO FACES OVER ONE BODY. This asks WHICH COLUMN state lives
#  in -- the body is shared, the field is not.
#  ⚠⚠ F1 IS LOAD-BEARING FOR EVERY OTHER ROW. Without it, "the write round-tripped"
#  could just mean both names were the same field, and the fixture would be a
#  tautology. addrOf prints per-run SEQUENCE NUMBERS (not raw %p, which moves every
#  run and cannot be pinned under H3), so F1 asserts field=#1 vs field=#3 with a
#  SHARED body=#2 -- two fields, one body, by value.
#  ⚠ noPrinT LIVES IN GroupBody's flags, THE SHARED COLUMN -- asked and answered
#  for Clay. GroupItem's options struct holds only affiliation and isCopy. So
#  roundTripT's ARM B2 was already a body-half arm, not a field-half arm; what
#  faceT adds is identity, the FORWARD direction, and the column census.
#  ⚠ F4 IS PINNED AT A TAG ECHO AND IS NOT A VERDICT. The parent column cannot be
#  read from incant -- `x.parenT` captured yields a data-less field, which returns
#  its own tag (bear-trap #26). A prediction that cannot be measured is not
#  confirmed by failing to measure it. See faceT's note.
#  ⚠ F0 is the anti-vacuity control: if an unwritten flag ever reads 1, F2 and F3
#  assert nothing.
run1 faceT "$T/face"; check "faceT runs" 0 $?
if grep -q "FACET SENTINEL" "$T/face"; then
    echo "  ok    faceT sentinel (no truncation)"; green=$((green+1))
else
    echo "  FAIL  faceT sentinel MISSING"; fail=1
fi
for _arm in "ADDROF faSrc field=#1 body=#2" \
            "ADDROF faSrc field=#3 body=#2" \
            "faceT F2 flags FORWARD  = 1" \
            "faceT F0 anti-vacuity   = noPrinT" \
            "faceT F3 flags REVERSE  = 1" \
            "faceT F4 parent read    = faP1"; do
    if grep -qF "$_arm" "$T/face"; then
        echo "  ok    ${_arm} -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  $_arm -- moved"; fail=1
    fi
done

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

#  ---------------------------------------------------------------------------
#  P2 -- THE fires=NEVER ROSTER, PINNED. Minted 2026-08-29, Tony's ruling.
#
#  parseClassify's PA line carries three facts per field: what setParse parked
#  (act), whether a builtinActoR is actually on the node (hung), and whether
#  anything on this executor's path ever runs it (fires). The census answered
#  Tony's recon question -- NO rule bound to a label-work executor carries a
#  parked action -- and the answer is MEASURED, not structural. It changes the
#  day a rule gains a method.
#
#  ⚠ SO THE CHEAP INSURANCE IS THIS PAIR: when the population moves, something
#  goes red BY NAME here, instead of a code body dying silently three files
#  downstream the way ANYorNum's did. This is the fleet learning to catch the
#  disease class rather than the instance -- the same promotion convention the
#  ANYorNum POP below answers YES for ("would the fleet have caught it?").
#
#  ⚠ AND THE ZERO ROW DOES NOT STAND ALONE. A count that expects 0 is exactly
#  what a broken extractor also produces, so it is paired with a sibling that
#  demands a NON-ZERO -- if the pipeline breaks, the sibling goes red and the
#  zero row's silence is no longer evidence of anything.
pcNEVER=$(awk '/^PA / && $4=="fires=NEVER" {print $5}' "$T/pce" | sort -u | tr '\n' ' ' | sed 's/ $//')
#  ⚠ ONE LITERAL, READ BY BOTH THE TEST AND THE MESSAGE. Written as two, the
#  FAIL arm printed "actual X, expected X" under its own H7 perturbation --
#  a message that cannot describe the failure it is reporting.
pcNEVERwant="ANYtoken NewGroup ShortcuT"
if [ "$pcNEVER" = "$pcNEVERwant" ]; then
    echo "  ok    fires=NEVER roster PINNED BY VALUE (ANYtoken NewGroup ShortcuT)"; green=$((green+1))
else
    echo "  FAIL  fires=NEVER roster MOVED"
    echo "          actual:   [$pcNEVER]"
    echo "          expected: [$pcNEVERwant]"
    echo "          A rule gained or lost a parked action with no executor to run it."
    echo "          That is isGroupActorPoison's shape. designDocs ProblemRecords."
    fail=1
fi
#  The label-work executors: everything that ends at parseSetLabel and therefore
#  never fires an action. parseRule fires via the generated body's
#  runRuleAction; parseAction fires field.method itself; these seven do neither.
#  ⚠ READ AS A PAIR, NOT AS TWO STREAMS. parseClassify prints PC then PA for
#  the same field, adjacently, so awk carries the last PC method forward. A
#  two-stream join would silently misalign the day either line moved.
pcLABELWORK=$(awk '/^PC /{m=$2} /^PA / && $2=="act=parked" && m ~ /^parse(String|Set|Container|UpTo|Character|Any|Condition)$/ {n++} END{print n+0}' "$T/pce")
if [ "$pcLABELWORK" = "0" ]; then
    echo "  ok    label-work executors carry 0 parked actions -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  a label-work executor now carries a parked action ($pcLABELWORK of them)"
    echo "          Those executors end at parseSetLabel and fire nothing, so the"
    echo "          action is parked and unreachable. Either they owe a"
    echo "          runRuleAction tail or the parking is wrong. Tony's call."
    fail=1
fi
#  ⚠ THE ANTI-VACUITY SIBLING, and it is not optional: the row above expects a
#  ZERO, which a broken extractor produces just as readily as a healthy tree.
pcBODY=$(awk '/^PC /{m=$2} /^PA / && $2=="act=parked" && m=="parseRule" {n++} END{print n+0}' "$T/pce")
if [ "$pcBODY" -gt 0 ]; then
    echo "  ok    anti-vacuity: parseRule carries $pcBODY parked actions (must be > 0)"; green=$((green+1))
else
    echo "  FAIL  anti-vacuity: parseRule carries NO parked actions -- the extractor"
    echo "        is broken, so the two rows above assert nothing whatever."
    fail=1
fi

#  ---------------------------------------------------------------------------
#  anyOrNumT -- THE isGROUP POISON STAYS FIXED. Minted 2026-08-29 immediately
#  after the fix certified, and NOT before: a target captured earlier would have
#  pinned four refusals as the truth.
#
#  ⚠ WOULD THE FLEET HAVE CAUGHT THE ORIGINAL POISON? NO -- and that is the
#  reason this row exists. setParse binding an actor onto an isGROUP alias with
#  no executor broke every code body compiled after it, and the fleet sat at 67
#  green through all of it, because parseClass was the only row that ran
#  setParse at all and its target was already red for unrelated reasons.
#
#  THREE ASSERTIONS, THREE FAILURE MODES, deliberately not blurred into one:
#  the census line catches a refusal, the body target catches generation drift,
#  and the answer catches a body that compiles and then does not run.
#
#  ⚠ ITS NEGATIVE CONTROL IS ON RECORD RATHER THAN ASSERTED. Remove the gate on
#  the builtinActoR attachment in Generate.rtn's setParse and this reads 4
#  attempted / 4 REFUSED -- that was the measured baseline of the three-arm
#  probe. designDocs ProblemRecords isGroupActorPoison carries the table.
run2 anyOrNumT "$T/aon" "$T/aone"; check "anyOrNumT runs" 0 $?
sentinel "anyOrNumT sentinel (no truncation)" "$T/aone" "VERIFY SENTINEL"
aonline=$(grep -m1 '^compile census:' "$T/aone")
aonwant="compile census: 4 attempted, 0 refused"
if [ "$aonline" = "$aonwant" ]; then
    echo "  ok    anyOrNumT census (4 attempted, 0 refused) -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  anyOrNumT census moved -- the isGROUP poison is back or generation changed"
    echo "          actual:   $aonline"
    echo "          expected: $aonwant"
    fail=1
fi
#  H4's vacuity guard: a body diff between two empty files passes and means
#  nothing, so the target's own non-emptiness is asserted before it is used.
if [ -s genLadder/anyOrNum.target ]; then
    echo "  ok    anyOrNum.target is non-empty (vacuity guard)"; green=$((green+1))
else
    echo "  FAIL  anyOrNum.target is EMPTY -- the body diff below asserts nothing"; fail=1
fi
diffcheck "anyOrNum.target (generated bodies + the parsed answer)" genLadder/anyOrNum.target "$T/aon"

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
#  ⚠⚠ RE-PINNED 10/4 ON 2026-09-02, AND THE ROW NOW COUNTS SOMETHING ELSE THAN
#  ITS NAME SUGGESTS. Tony's ruling on Clay's recommendation. The audit counts
#  `isRule && !rStuff`, and under Ruling D that conjunction IS NOT A DEFECT --
#  it is the lawful signature of a BARE MASTER. The SEQ 100 C3 table then proved
#  no reader in the tree needs rStuff off those ten: all five callers graded
#  ASKING. So the number CANNOT be driven to zero without breaking doctrine, and
#  a gate demanding zero of a lawful count is a gate that never opens.
#
#  WHAT THIS ROW ASSERTS IS NOT "nothing is missing". It is "THE POPULATION OF
#  BARE MASTERS HAS NOT MOVED".
#      reads 11  -> a new route is marking masters
#      reads  9  -> an attachment road started constructing rStuff somewhere it
#                   did not before
#  Either is exactly when somebody should look. Same instrument-shape as
#  incant/broadcastT pinned pre-law: the number is the fact, and MOTION is the
#  alarm.
#
#  10/4 is measured on the PURE binary, twice, on two boards that now agree --
#  which they did not before the getRStuff purity ruling (F-35, closed). The
#  alternative was re-specifying what "missing" should mean, and that is a
#  semantic ruling on code neither seat wrote, starting life unmeasured.
#  ⚠ THE GATE READS "AUDIT AT PIN", NEVER "AUDIT CLEAN".
AUDITLINE="AUDIT all registries: 10 missing rules, 0 missing terms, 4 loose, 0 unconsumed"
if grep -qF "$AUDITLINE" "$T/one"; then
    echo "  ok    bare-master population AT PIN (isRule without rStuff = 10, loose = 4)"; green=$((green+1))
else
    echo "  FAIL  bare-master population MOVED (row pinned 2026-09-02, NOT a defect count):"
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
#  trailingContinueT -- A TRAILING `continue` MUST NOT EAT THE REST OF THE BLOCK.
#  Promoted from incant/fixits/trailingContinue on 2026-08-28, remedy stepped and
#  blessed. Three arms, identical shape: a loop whose last executed statement is
#  `continue`, then one statement after the loop. All three must reach it.
#
#  ⚠ WHY THIS IS NOT REDUNDANT WITH loopBranchT ABOVE, WHICH IS THE ADJACENT
#  FIXTURE AND WAS MEASURED BLIND TO IT. loopBranchT asserts that a break is
#  consumed and that continue skips correctly -- both about behaviour INSIDE the
#  loop. This asserts what survives AFTER it. With the remedy stripped from
#  aCTionFOR and aCTionDO and the binary rebuilt, the whole fleet reported 62
#  green and a byte-identical failure set: NOTHING here covered it. That
#  measurement is why the citizen was promoted rather than simply retired.
#
#  ⚠ THE arm-entered ROWS ARE THE ANTI-VACUITY CONTROL AND MUST NOT BE DROPPED
#  AS NOISE. Without them "FOR reported nothing" cannot be told from "the FOR
#  arm never ran", which is a different defect entirely. They are what makes the
#  three value rows below mean the TAIL was reached rather than the arm was.
branchrun trailingContinueT "TC SENTINEL" "trailingContinueT runs (trailing continue in all 3 loop forms)"
armed=$(grep -c "arm entered" "$T/trailingContinueT")
if [ "$armed" = "3" ]; then echo "  ok    trailingContinueT anti-vacuity: all 3 arms ENTERED (3)"; green=$((green+1))
else echo "  FAIL  trailingContinueT anti-vacuity: $armed arms entered, want 3"; fail=1; fi
valcheck trailingContinueT "WhilE  after-loop statement ran -> *" 1 "WhilE: statement after a trailing continue runs (1)"
valcheck trailingContinueT "FOR    after-loop statement ran -> *" 1 "FOR: statement after a trailing continue runs (1)"
valcheck trailingContinueT "DO     after-loop statement ran -> *" 1 "DO: statement after a trailing continue runs (1)"

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
#  the odometer is RED by design today (45 of 63) and a red odometer is the
#  correct state.
#
#  ⚠ RE-PINNED 2026-09-02, AND THE SENTENCE IS: `tokenize` RETIRED BY RULING.
#  It was one of the NINETEEN genParse-green rules, so green went 19 -> 18 and
#  the population 64 -> 63 in the same stroke. The ratchet did exactly what it
#  is for -- it called STOP-THE-LINE and named `tokenize` as RED NOW, WAS GREEN
#  -- and the correct response was to check the cause, not to regenerate a green
#  diff. The cause is a deliberate removal (docs/fixIts.md F-37, retired on a
#  zero-firing measurement plus the tokened/captureSpan succession), so the
#  greenness went with the rule. ONE rule left the population and ONE left the
#  green set; any other arithmetic here would have been a finding. This row asserts only that the number HAS NOT MOVED WITHOUT
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
diffcheck "genParse odometer (18 green / 45 red of 63 -- RED BY DESIGN, pinned; ratchet monotone)" \
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

#  ---------------------------------------------------------------------------
#  RAW ->rStuff READS IN THE GENERATED .mm -- THE MIRROR-DRIFT TRIPWIRE.
#  SEQ 100 C1, 2026-09-01. This row exists because F-35 was discovered as an
#  AUDIT DISCREPANCY when it was really codegen drift, and the drift came from
#  ONE LINE IN AN OUT-OF-REPO FILE that a Groups `git status` can never show.
#
#  Adding getRStuff to groups.ext's external GroupItem mirror moved ~129 reads
#  from the raw field onto the accessor -- measured: 8 getRStuff() call sites
#  before, 137 after. That is harmless while the getter is PURE and would be a
#  tree-wide mutation the day anybody puts work back into it (bear-trap #11's
#  sequel; the getter's own header carries the argument).
#
#  H4: the count is printed and compared BY VALUE, never asserted as an absence.
#  The 21 survivors are hand-written `-%` passthrough sites, which no mirror
#  change can reach. If this row moves, the mirror moved -- go and read it
#  BEFORE believing any audit number taken on the new binary.
rawreads=$(grep -o -- "->rStuff" GroupItem.mm GroupBody.mm GroupControl.mm GroupMain.mm \
                       GroupRules.mm RuleStuff.mm 2>/dev/null | grep -vc "getRStuff\|setRStuff")
rawlines=$(grep -l -- "->rStuff" *.mm 2>/dev/null | wc -l | tr -d ' ')
#  ⚠ WENT 30 -> 32 -> 30 ON 2026-09-01 AND IS BACK AT ITS ORIGINAL VALUE, which is
#  the strongest thing this row could say: SEQ 106's frame bind added one line
#  carrying two raw reads, SEQ 107 stripped it, and the codegen returned EXACTLY to
#  where it started. Adding and then removing `frameArg` in the groups.ext RuleStuff
#  block moved nothing else in either direction -- verified line-by-line against the
#  commits, not inferred from the total. That is the opposite of F-35, where a single
#  mirror line took one getter's blast radius from 8 sites to 137.
#
#  ⚠⚠ AND A WEAKNESS IN THIS ROW, FOUND BY IT MISCOUNTING ITSELF: THE MATCH COUNTS
#  COMMENT TEXT. During the strip the count came back 31 instead of 30, and the extra
#  hit was a COMMENT in runAction that quoted the guard verbatim. Nothing had drifted;
#  prose had. The `grep -v getRStuff` above is also a no-op -- `grep -o` prints the
#  matched text, so the filter can never fire -- which is fine for a pure occurrence
#  count but is not the filter it looks like.
#  SO: WHEN THIS ROW MOVES, CHECK WHETHER A COMMENT MOVED IT BEFORE BELIEVING THE
#  CODEGEN DID. And do not write `->rStuff` literally in prose near this file.
if [ "$rawreads" = "30" ]; then
    echo "  ok    raw ->rStuff reads = 30 across $rawlines .mm -- PINNED BY VALUE (mirror-drift tripwire)"; green=$((green+1))
else
    echo "  FAIL  raw ->rStuff reads MOVED -- the groups.ext mirror changed codegen"
    echo "          actual:   $rawreads"
    echo "          expected: 30   (21 hand-written passthrough lines)"
    echo "          => read ~/Dropbox/data/InProcess/Include/groups.ext before trusting"
    echo "             any audit number taken on this binary. See F-35."
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
