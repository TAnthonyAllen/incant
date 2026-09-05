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

#  ⚠ IS THE BINARY BUILT FROM THE SOURCE ON DISK? Added 2026-09-05, and it is
#  rule H1's second half: H1 says ECHO the binary, this says CHECK it against
#  what it claims to be built from. A stale binary does not fail as a diff.
#
#  ⚠ PAID FOR THE SAME MORNING. jitContext.h read `gNoUnwrap = 0` while the
#  installed binary had been built at 1 -- the switch was flipped, a test was
#  run, the SOURCE was flipped back, and no rebuild followed. The fleet read 141
#  green against a sealed 197 and looked like a catastrophic regression. It was
#  the OTHER PROGRAM. Nothing in the tree could say so: the source grep reads 0
#  and is right, the binary is right about itself, and only the pair is wrong.
#  A GREP ON gNoUnwrap ALONE IS NOT A CHECK -- it reads the source, which is
#  exactly the half that was telling the truth.
newest=$(ls -t *.rtn *.twk *.h 2>/dev/null | head -1)
if [ -n "$newest" ] && [ "$newest" -nt "$(readlink "$B" 2>/dev/null || echo "$B")" ]; then
    echo "  ⚠ STALE  $newest is NEWER than the binary -- REBUILD BEFORE BELIEVING ANY ROW BELOW."
    echo "           Every number in this run is about a program that is not the source on disk."
else
    echo "  bin   built no earlier than the newest source ($newest)"
fi
echo "  bin   gNoUnwrap = $(sed -n 's/^static int gNoUnwrap = \([01]\);/\1/p' jitContext.h) in SOURCE -- and the line above is what says the binary agrees"

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
#  ⚠ argBindT / argRoundT / argRoundJ -- THE ARGUMENT BINDING (Tony's VERDICT
#  BUY, 2026-09-05). designDocs ArgBinding is the ruling; these are its rows.
#
#  argBindT asserts the two halves that pull in opposite directions. A WRITE
#  through the argument LANDS (B2, 5 -- moved from 7); a REBIND of the binding
#  is REFUSED so the caller is UNMOVED (B4/B5, still 5). ⚠ B2 IS WHAT MAKES B4
#  NON-VACUOUS: without a preceding write that moved the value, "unmoved" is
#  satisfied by a run in which nothing whatever happened.
#
#  The two refusal lines are asserted BY PRESENCE WITH VALUE (H4), naming the
#  operator. A row that only checked "the caller did not move" would go green
#  the day the refusal is deleted and the rebind silently does nothing -- and
#  that is not hypothetical: B's own H7 negative control measured it. Gate
#  removed, B4/B5 read 41, `argument := x` SILENTLY REPOINTS THE CALLER'S FIELD.
run1 argBindT "$T/abt"; check "argBindT runs" 0 $?
sentinel "argBindT sentinel (no truncation)" "$T/abt" "ARGBIND SENTINEL"
for _b in "B1 read through the argument        7" \
          "B2 caller after \`argument = 5\`      5" \
          "B3 untouched sibling                7" \
          "B4 caller after \`argument := x\`     5" \
          "B5 caller after \`argument <- x\`     5" \
          "B6 the rebind target itself         41"; do
    if grep -qF "$_b" "$T/abt"; then
        echo "  ok    argBindT ${_b%% *} -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  argBindT ${_b%% *} -- wanted: $_b"; fail=1
    fi
done
for _o in ':=' '<-'; do
#  ⚠ RE-PINNED 2026-09-05 to refuse()'s uniform line. Same refusal, same two
#  operators, same presence-with-value discipline -- only the spelling moved
#  into the one funnel.
    if grep -qF "\`$_o\` on argument -- argument is a BINDING" "$T/abt"; then
        echo "  ok    argBindT '$_o' refusal NAMED (presence-with-value, not absence)"; green=$((green+1))
    else
        echo "  FAIL  argBindT '$_o' refusal missing -- the guard stopped naming itself"; fail=1
    fi
done

#  argRoundT -- A->B->A, a LOCAL and an ARGUMENT each carried across the nested
#  call. The intervening arB is passed 41 and every arA is passed 7, ON PURPOSE:
#  had both been 7, a channel that handed every callee the same node would print
#  7 three times and pass. INTERPRETED ARM ONLY -- the JIT arm is argRoundJ.
run1 argRoundT "$T/art"; check "argRoundT runs" 0 $?
sentinel "argRoundT sentinel (no truncation)" "$T/art" "ARGROUND SENTINEL"
for _a in "A depth 3 sees argument = 7 local = 3" \
          "A depth 2 sees argument = 7 local = 2" \
          "A depth 1 sees argument = 7 local = 1"; do
    if grep -qF "$_a" "$T/art"; then
        echo "  ok    argRoundT ${_a%% sees*} -- own argument AND own local -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  argRoundT ${_a%% sees*} -- wanted: $_a"; fail=1
    fi
done

#  ============================================================================
#  ⚠ argRetiredT -- A DECLARED `argument` REFUSES BY NAME AND IS NOT INSTALLED.
#  Tony's ruling 2026-09-05: a refusal is terminal for THE UNIT THAT RAISED IT.
#  At run time that unit is the activation; AT DEFINE TIME IT IS THE DEFINITION.
#
#  ⚠ THE `AR AFTER` ROW IS THE ONE THAT COSTS SOMETHING TO GET WRONG, and it is
#  here because getting it wrong was measured. A first attempt armed WITHOUT
#  clearing at the definition boundary, so the first declared `argument` in a
#  file killed EVERY LATER DEFINITION IN IT -- fleet 171 -> 107. This row is
#  what would have caught it, and it is why the boundary clear is not optional.
#
#  ⚠ `AR BAD` IS AN ABSENCE and does not stand alone (H4). It is read only with
#  the sentinel and its two neighbours: sentinel present plus BEFORE and AFTER
#  present means the run COMPLETED and BAD was SKIPPED. Sentinel absent would
#  mean the run DIED, which is a different fact. Without the pairing this passes
#  on any truncated run.
run1 argRetiredT "$T/art2"; check "argRetiredT runs" 0 $?
sentinel "argRetiredT sentinel (no truncation)" "$T/art2" "ARGRETIRED SENTINEL"
if grep -q "REFUSED arBad -- a declared .argument. attribute is retired" "$T/art2"; then
    echo "  ok    argRetiredT the retired spelling REFUSES BY NAME, with the respell"; green=$((green+1))
else
    echo "  FAIL  argRetiredT the refusal is gone or stopped naming the respell"; fail=1
fi
for _n in BEFORE AFTER; do
    if grep -q "^AR $_n ran" "$T/art2"; then
        echo "  ok    argRetiredT AR $_n ran -- the definition $_n a refusal is unharmed"; green=$((green+1))
    else
        echo "  FAIL  argRetiredT AR $_n did NOT run -- the refusal escaped its definition"; fail=1
    fi
done
if grep -q "ARGRETIRED SENTINEL" "$T/art2" && grep -q "^AR AFTER ran" "$T/art2" && ! grep -q "^AR BAD ran" "$T/art2"; then
    echo "  ok    argRetiredT the REFUSED definition was NOT installed"; green=$((green+1))
elif grep -q "^AR BAD ran" "$T/art2"; then
    echo "  FAIL  argRetiredT the refused definition WAS installed and ran"; fail=1
else
    echo "  FAIL  argRetiredT truncated -- AR BAD's absence asserts nothing"; fail=1
fi

#  ============================================================================
#  ⚠ acceptStartT -- THE ACCEPTANCE LINE. UN-PARKED 2026-09-05 (rule H6).
#  Parked since 2026-08-30 with "un-parks at the flip", because the answer it
#  would be measured against had not been chosen. The flip has landed and B has
#  discharged it, so parking it further is what turns a parked item into a
#  forgotten one -- which is the failure the WOKE alarm exists to prevent.
#
#  THE CRITERION IS THE FIXTURE'S OWN, unchanged since it was written:
#      LEGACY   the argument is a CARRIER -- its groupBody DIFFERS from the caller's
#      FLIPPED  the argument IS the caller's storage -- groupBody IDENTICAL
#  It used to print `asSubject` and `argument` over TWO bodies. It now prints
#  the caller's tag twice over ONE.
#
#  ⚠ THE TWO BODIES ARE COMPARED TO EACH OTHER, NEVER TO A PINNED ADDRESS
#  (rule H3). Addresses move every run for reasons that say nothing about
#  whether the answer is right; a golden diff here would cry wolf daily and be
#  regenerated green, which is not a target.
#  ⚠ ANTI-VACUITY: the row demands exactly TWO BODY lines and a non-empty body
#  value. Two absent lines compare equal, and "equal" over nothing is precisely
#  what a fixture that stopped printing would report.
run1 acceptStartT "$T/acc"; check "acceptStartT runs" 0 $?
sentinel "acceptStartT sentinel (no truncation)" "$T/acc" "ACCEPT SENTINEL"
_accn=$(grep -c '^BODY ' "$T/acc")
_acc1=$(grep '^BODY ' "$T/acc" | sed -n '1s/.*groupBody=//p')
_acc2=$(grep '^BODY ' "$T/acc" | sed -n '2s/.*groupBody=//p')
if [ "$_accn" != 2 ] || [ -z "$_acc1" ]; then
    echo "  FAIL  acceptStartT VACUITY: $_accn BODY line(s), body '$_acc1' -- the fixture stopped reporting, so the comparison below asserts nothing"; fail=1
elif [ "$_acc1" = "$_acc2" ]; then
    echo "  ok    acceptStartT THE ACCEPTANCE LINE: callee and caller share ONE body ($_acc1)"; green=$((green+1))
else
    echo "  FAIL  acceptStartT THE ACCEPTANCE LINE FAILS -- the callee is on a DIFFERENT body"
    echo "          caller $_acc1"
    echo "          callee $_acc2   (a CARRIER; see designDocs ProblemRecords carrierNodeCarrier)"
    fail=1
fi

#  ⚠ argJitT -- THE JITTED ARGUMENT READ, ON THE INLINED ROAD.
#  PROMOTED 2026-09-05 BECAUSE ITS ABSENCE COST A SILENT REGRESSION THAT DAY.
#  Until it existed NO fixture in the tree read an action's `argument` under the
#  JIT -- every jit fixture reads globals. Item 3 moved the argument bind out of
#  runAction's jitting arm, the inlined road stopped reading the passed field
#  and answered 0, and THE FLEET STAYED AT 179 GREEN through it. Found by hand.
#
#  ⚠ AND argRoundJ COULD NOT HAVE CAUGHT IT, which is the sharper half: that row
#  is pinned RED on jitArgBake, so a second, unrelated JIT defect landing
#  underneath it changes nothing anyone can see. A red row absorbs new breakage
#  silently. THIS is the green row that could not.
#
#  8 then 22 -- different ANSWERS, not merely different inputs, so a folded
#  constant cannot satisfy both. Oracle LAST (bear-trap #25): testing() routes
#  on isCoded and an interpreted run consumes it.
run1 argJitT "$T/ajt"; check "argJitT runs" 0 $?
sentinel "argJitT sentinel (no truncation)" "$T/ajt" "ARGJIT SENTINEL"
for _j in "AJ fire 1 result: ajOut = 8" \
          "AJ fire 2 result: ajOut = 22" \
          "AJ interpreted  : ajOut = 14"; do
    if grep -qF "$_j" "$T/ajt"; then
        echo "  ok    argJitT ${_j%%:*} -- jitted body reads the PASSED FIELD -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  argJitT ${_j%%:*} -- wanted: $_j"; fail=1
    fi
done

#  ⚠ argRoundJ -- THE JIT ARM. Minted pinned RED by name on jitArgBake and
#  RE-PINNED GREEN the same day when the flag hoist discharged it; see the
#  sentence at the argument-column row below. It stays a separate file from
#  argRoundT because a fixture gets ONE testing().
run1 argRoundJ "$T/arj"; check "argRoundJ runs" 0 $?
sentinel "argRoundJ sentinel (no truncation)" "$T/arj" "ARGROUNDJ SENTINEL"
#  The LOCAL column IS covered and IS green -- it agrees with the interpreted
#  oracle at 3/2/1, which is what says the defect is the argument channel and
#  not the frame. Without this row the red below could not be attributed.
_arjloc=$(grep -c 'local = [123] *$' "$T/arj")
if [ "$_arjloc" = 3 ]; then
    echo "  ok    argRoundJ local column agrees with the oracle (3/2/1) -- the JIT frame is sound"; green=$((green+1))
else
    echo "  FAIL  argRoundJ local column moved -- $_arjloc of 3 rows. That is the FRAME, not jitArgBake"; fail=1
fi
#  ⚠ RE-PINNED RED -> 7 ON 2026-09-05, SAME DAY, WITH ITS CAUSE (H6, and a
#  re-pin needs a sentence rather than a green diff). jitArgBake DISCHARGED, and
#  not by the machinery its BEST GUESS proposed building -- it fell out of item
#  3's flag hoist. Setting isArgument ABOVE runAction's jitting gate means the
#  JIT frame prologue's (isLocal || isArgument) walk finally SEES the argument
#  and gives it an alloca, so the read is a FRAME LOAD fed per activation
#  instead of a baked absolute address. Confirmed on the emitted IR: jit_jabA
#  gained `%argument = alloca i32` with its `%prolog` load, where before it had
#  only `%jabMine`. That IS "feed a slot, stop baking"; the guess was right
#  about the shape and wrong about the work.
#  ⚠ THE ROW NOW ASSERTS AGREEMENT WITH THE INTERPRETED ORACLE, which is what it
#  wanted to say all along -- argRoundT reads 7/7/7 interpreted and this reads
#  7/7/7 jitted, same fixture body, two engines.
_arjarg=$(grep -c 'sees argument = 7 ' "$T/arj")
if [ "$_arjarg" = 3 ]; then
    echo "  ok    argRoundJ JIT argument column = 7 at all three depths -- agrees with the interpreted oracle"; green=$((green+1))
else
    echo "  FAIL  argRoundJ JIT argument column moved -- $_arjarg of 3 rows read 7"
    echo "          got:  $(grep -m1 'sees argument' "$T/arj" | sed 's/^ *//')"
    echo "          want: argument = 7, as incant/argRoundT reads it interpreted"
    fail=1
fi

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
#  ⚠ chanT -- THE ARGUMENT CHANNEL'S DAILY ROW. Added 2026-09-02, SEQ 132 item 2.
#
#  WHY IT EXISTS: every SAMEFIELD reading taken during the channel campaign
#  needed a TEMPORARY CAMERA under the flip, and a camera is not a fleet
#  instrument. chanReport prints a counter pair incremented at ALL FOUR bind
#  sites -- both arms of both roads -- so the same row reads bare and flipped
#  with no rebuild, and pop.sh runs bare.
#
#  ⚠ SAME MUST EQUAL BINDS. A gap is a bind that did not store the field it was
#  handed: a copy, or a write that did not happen, which is F-46's shape.
#
#  ⚠ AND THE TOTAL MUST BE NON-ZERO, asserted separately. `0 of 0` is agreement
#  between two absences and is exactly what a channel that never ran would
#  print -- H4's other half. The value rows are the second discriminator: a bind
#  that stores the WRONG field passes the counter and fails them.
#
#  ⚠ RE-PINNED 3 -> 4 ON 2026-09-05, WITH THE CAUSE AND NOT A GREEN DIFF. The
#  fixture is unchanged: ctRun calls ctSeen three times. The FOURTH bind is
#  ctRun ITSELF. It declares no `argument`, so the old runAction -- which bound
#  only `if (ruleArg = field->get("argument"))` -- skipped it entirely. Item 3
#  makes runAction MINT the slot when there is none, so every call binds and
#  the population grew by exactly the actions that never declared one.
#  THAT IS THE ITEM'S WHOLE POINT ARRIVING IN THE COUNTER, not drift.
#  ⚠ AND `same` TRACKED TO 4 TOO, which is the half that makes the re-pin safe:
#  the invariant being asserted is SAME == BINDS, and it held across the change.
#  A 4/3 would have been the F-46 shape and would NOT have been re-pinned.
run2 chanT "$T/chan" "$T/chane"; check "chanT runs" 0 $?
sentinel "chanT sentinel (no truncation)" "$T/chan" "CHANT SENTINEL"
chanline=$(grep -m1 '^=== ARGCHANNEL binds' "$T/chane")
chanwant="=== ARGCHANNEL binds = 4 same = 4 ==="
if [ "$chanline" = "$chanwant" ]; then
    echo "  ok    chanT ARGCHANNEL binds = 3 same = 3 -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  chanT ARGCHANNEL pair moved -- a bind did not store the field it was handed"
    echo "          actual:   $chanline"
    echo "          expected: $chanwant"
    fail=1
fi
chanbinds=$(printf '%s' "$chanline" | sed -n 's/.*binds = \([0-9]*\) .*/\1/p')
if [ -n "$chanbinds" ] && [ "$chanbinds" -gt 0 ]; then
    echo "  ok    chanT anti-vacuity: binds is NON-ZERO ($chanbinds)"; green=$((green+1))
else
    echo "  FAIL  chanT anti-vacuity: binds is 0 or unreadable -- the pair above"
    echo "        compares two absences and asserts nothing"
    fail=1
fi
chanseen=$(grep -c "CHANT sees ORIG" "$T/chan")
if [ "$chanseen" = "3" ]; then
    echo "  ok    chanT value rows: 3 of 3 read ORIG through the channel"; green=$((green+1))
else
    echo "  FAIL  chanT value rows -- wanted 3 reading ORIG, got $chanseen"; fail=1
fi

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
#  ⚠⚠ RE-PINNED 2026-09-02, AND THE SENTENCE IS THAT IT ARRIVED AT gNoUnwrap 0.
#  Row 3 read `argument` from 2026-08-29 until the embedRule stroke and now reads
#  htWindow, the value it always wanted. THE TRIGGER WAS setGroup'S COPY, NOT THE
#  FLIP -- the pin above predicted the flip and named the wrong cause. runAction
#  binds `ruleArg.group = argument`; the old setGroup COPIED a parented source and
#  reparented the copy onto the holder, so .parenT read the holder. setGroup no
#  longer copies, so it reaches the real parent. The flip is still off.
#
#  CAPABILITY: the argument channel, read through .parenT. This row is now the
#  fleet's daily assertion that an action reaches its argument's real parent and
#  not a carrier's.
run1 holderT "$T/hold"; check "holderT runs" 0 $?
if grep -q "HOLDERT SENTINEL" "$T/hold"; then
    echo "  ok    holderT sentinel (no truncation)"; green=$((green+1))
else
    echo "  FAIL  holderT sentinel MISSING -- the run truncated"; fail=1
fi
for _arm in "holderT 1 direct    .parenT = htWindow" \
            "holderT 2 identity  .taG    = htInside" \
            "holderT 3 holder    .parenT = htWindow"; do
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
#  ⚠⚠ S3a IS GRADED AS OF 2026-09-01 (C19), AND THIS COMMENT REPLACES THE ONE
#  SAYING IT WAS UNRESOLVED. The blocker was identity and addrOf removed it. The
#  suspicion -- a fixpoint -- was FALSIFIED, and something larger was found:
#
#      ONLY ONE STAR IS EVER APPLIED. N stars behave as exactly one.
#
#  Measured under gNoUnwrap=1 by addrOf's body column. R4 is the discriminator and
#  R2 alone never could have been: a fixpoint AND a working composition both
#  predict `**s3Two` reaches the LEAF; it reaches the MIDDLE. The reading that
#  looked like a fixpoint was a one-deep coincidence.
#  ⚠ AND IT RELOCATES THE ROW THAT MATTERS TO S2b, NOT S3a. S2b is `**x` on a
#  TWO-deep pointer wanting the LEAF and getting the MIDDLE, so when this fixture
#  re-pins at the flip S2b must go RED and stay red until composition works.
#  S3a will read the leaf at the flip and be RIGHT to -- FOR THE WRONG REASON.
#  ⚠ NONE OF THAT IS PINNED BY THE ROWS BELOW, AND SAYING SO IS THE POINT. The
#  grading ran under the FLIP; the fleet runs flip-OFF, where every star refuses
#  for the auto-unwrap's reasons rather than the law's. So these rows pin the
#  flip-OFF baseline and nothing more, and S4 remains the only row asserting
#  something the law uniquely predicts TODAY. The grading lives in starT's dead
#  region and re-pins here when the flip lands.
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
#  ⚠⚠ LAW 2 IS CERTIFIED AS OF 2026-09-01 BY ROW L4, and this comment replaces
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
#  ⚠⚠ L6 -- IS `<-` CARRIER-STABLE? YES, AND THIS IS THE ONE PLACE THE FIELD
#  COLUMN IS PINNED ON PURPOSE. Everywhere else in this block the field column is
#  deliberately NOT pinned, because it reports the carrier and the carrier moves
#  for reasons that say nothing about the laws (H3). HERE THE CARRIER IS THE
#  SUBJECT, so the field number is the measurement and the body column is the one
#  that would say nothing.
#  ⚠ L6a AND L6b ARE THE CLAIM AND L6d IS WHAT KEEPS IT FROM BEING VACUOUS. A
#  numbering scheme that simply never advanced would satisfy "the field repeats";
#  L6d asks the define-block field again in the same run and gets a FRESH carrier
#  (#11, after #1/#3/#8/#9), so the scheme demonstrably does advance and L6b's
#  repeat is a real identity rather than a stalled counter.
#  ⚠ WHY IT MATTERS BEYOND THIS FIXTURE: a bare mention of a defined field mints
#  a fresh carrier on EVERY ask, and a `<-` capture does not -- so one road
#  already reaches a stable field by name. That is a candidate for what step 4 is
#  building by hand, and it is noted in incant/fixits/carrierNode as the first
#  named read measured to reach a stable field.
#  ⚠ L6c shows the property is not special to capturing a name: a capture of a
#  SUBSCRIPT is stable too, reading #6 here and at L4d and L5b -- three asks, one
#  field, across the whole run.
#  ⚠ L5's NEGATIVE CONTROL, run the same way and recorded here with L4's: L5b was
#  aimed at a NAMED field instead of the element, and it went RED (isCopy 0 -> 1)
#  while L5a stayed green, which is exactly the split the two rows claim.
#  ⚠⚠ NEGATIVE CONTROL RECORDED, 2026-09-01 (rule H7 -- a rung certifies only what
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
            "pointerT R  rebind       = ptOther" \
            "pointerT L  three ptrs   = 3" \
            "pointerT L1 prints values = CHANGED OTHER" \
            "pointerT L2 name-then-star = CHANGED" \
            "pointerT L3 assign-then-star = 0" \
            "pointerT D  depth        = 0" \
            "pointerT X  star binds tightest = 0" \
            "pointerT L5c flag road   = ptFlagRead" \
            "pointerT F2 null operand = 0"; do
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
#  ⚠ F2's REFUSAL ASSERTED BY ITS TEXT (H4, and the same argument as X and L3): a
#  listLengtH of 0 is also what an operator that did nothing at all produces, so
#  the zero alone cannot tell a refusal from a no-op. This names WHICH operand was
#  refused, and it is the row that goes red if F-43 ever regresses -- that guard
#  printed a null field's tag and CRASHED at exit 139 until 2026-09-01, and it
#  survived because nothing in the fleet could reach it (F1 mints a local rather
#  than a null, bear-trap #39).
if grep -qF "ERROR Operator +* failed on ptBagN and a refused operand" "$T/ptr"; then
    echo "  ok    pointerT F2 witness: +* refused BY NAME (F-43 fixed)"; green=$((green+1))
else
    echo "  FAIL  pointerT F2 witness MISSING -- +* no longer names its refused operand"; fail=1
fi
#  ⚠⚠ L5 -- THE isCopy COLUMN, PROMOTED FROM C20's FOOTNOTE TO ROWS (SEQ 115).
#  A NAMED read arrives through the argument carrier, which mints a COPY (isCopy
#  true, body shared -- Tony's definition); a SUBSCRIPT reaches the element, which
#  nobody copied. So L5b's 0 is the ABSENCE of the carrier's copy and is the same
#  fact law 2 certifies, seen through a second column. Both roads are pinned so
#  the fleet trips if EITHER changes, and L5a is the row that fires if a named
#  read of a defined field ever comes back isCopy=0.
#  ⚠ L5c PINS AN ABSENCE BY ITS VALUE, ON PURPOSE. The flag road does not exist:
#  `.isCopY` echoes its own tag (bear-trap #26) on a named field AND on an
#  element -- MEASURED in minionWork/probeIsCopy, not assumed. isCopy lives in
#  GroupItem's options (groups.ext:202), not GroupBody's flags. So the row pins
#  the tag-echo, and the day the spelling starts reading, L5c goes RED and the
#  by-flag half gets built. Omitting it instead is how a gap becomes permanent --
#  nothing trips when the road opens (H4).
for _l4 in "L4a source asked once:|body=#2|source body, first ask" \
           "L4b SAME source again|body=#2|source body REPEATS -- column is stable" \
           "L4c a DIFFERENT field|body=#5|other body DIFFERS -- column discriminates" \
           "L4d the SUBSCRIPT RESULT|body=#7|the subscript STOPPED (law 2, certified)" \
           "L4e that capture STARRED|body=#2|the star REACHED the source (law 4)" \
           "L5a a NAMED field|isCopy=1|a NAMED read is a COPY (the carrier mints one)" \
           "L5b the SUBSCRIPT ELEMENT|isCopy=0|the ELEMENT is nobody's copy" \
           "L6a a <- capture OF A NAME, first ask|field=#10|a <- capture of a NAME" \
           "L6b the SAME capture, second ask|field=#10|SAME FIELD -- <- is carrier-stable" \
           "L6c a <- capture OF A SUBSCRIPT|field=#6|a <- capture of a SUBSCRIPT, also stable" \
           "L6d the DEFINE-BLOCK field|field=#11|a FRESH carrier -- the control"; do
    _lbl=${_l4%%|*}; _rest=${_l4#*|}; _want=${_rest%%|*}; _why=${_rest##*|}
    if grep -A1 -F "$_lbl" "$T/ptr" | grep -qE "ADDROF .*[ ]$_want([ ]|\$)"; then
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

#  ============================================================================
#  ⚠⚠ roundTripT -- JOINS THE FLEET 2026-09-01 (SEQ 116), AND IT HAD NEVER BEEN
#  IN IT. Born 2026-08-31, it carries the founding measurement of the mechanism
#  table -- which twinning road SHARES a body and which COPIES one -- and nothing
#  pinned it, so it could have gone silently wrong at any point since.
#  ⚠ WHAT IT READS TODAY, and the pre-registration is CONFIRMED: a body flag
#  crosses between two names EXACTLY WHEN THE BODY IS SHARED.
#      ARM A   one node, write then read       1          round trip works
#      ARM C   never written                   noPrinT    tag echo, NOT 1
#      ARM B1  copyOf twin, write twin         noPrinT    does NOT cross
#      ARM B2  addGroup twin, write twin       1          DOES cross
#  ⚠ B1 IS NOT A COUNTEREXAMPLE, IT IS THE SAME RULE. copyOf makes its OWN body
#  (which is why Tony's ruling says copyOf is not a "copy of a field" at all), so
#  there is no shared body for the flag to cross through. B1 and B2 differ in the
#  road, not in the law.
#  ⚠ ARM C READS A TAG ECHO, NOT 0, and its own want-text still says "MUST be 0".
#  An unset flag has no data and returns its own tag (bear-trap #26) -- that is
#  the honest answer, the same one faceT's F0 gives. What the control actually
#  asserts is that it is NOT 1, and the row below pins the echo by value.
#  ⚠⚠ AND ARM 0 -- THE FIXTURE'S OWN VOIDING CONTROL -- IS FAILING, PINNED HERE
#  AT THE DEFECT ON PURPOSE. It probes one field twice with nothing between and
#  says "the two node= above MUST match, or every address below is void." THEY DO
#  NOT MATCH. The cause is now measured rather than suspected: a bare mention of a
#  defined field mints a FRESH CARRIER on every ask (pointerT L6d), so probeNode
#  receives a different field each call.
#  ⚠ THE VOIDING IS REAL BUT NARROW, AND SAYING WHICH IS THE POINT. It voids the
#  probeNode ADDRESS lines. It does NOT void ARM A, B1 or B2, because those read
#  the flag through a BARE MENTION and never through probeNode -- so the four rows
#  above stand on their own evidence. Pinned MISMATCH: when the carrier lands,
#  this row goes RED and gets re-pinned to MATCH, which is how the fix cannot land
#  silently.
run1 roundTripT "$T/rt"; check "roundTripT runs" 0 $?
if grep -q "ROUNDTRIP SENTINEL" "$T/rt"; then
    echo "  ok    roundTripT sentinel (no truncation)"; green=$((green+1))
else
    echo "  FAIL  roundTripT sentinel MISSING"; fail=1
fi
for _arm in "ARM A   r = 1" \
            "ARM C   r = noPrinT" \
            "ARM B1  original reads noPrinT" \
            "ARM B2  original reads 1"; do
    if grep -qF "$_arm" "$T/rt"; then
        echo "  ok    roundTripT $_arm -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  roundTripT $_arm -- moved"; fail=1
    fi
done
#  The two ARM 0 node addresses, compared by value rather than pinned by text --
#  the raw %p moves every run (H3), so only their AGREEMENT is assertable.
_rt0a=$(grep -m2 "^PN rtA node=" "$T/rt" | sed -n '1s/.*node=\([^ ]*\).*/\1/p')
_rt0b=$(grep -m2 "^PN rtA node=" "$T/rt" | sed -n '2s/.*node=\([^ ]*\).*/\1/p')
if [ -z "$_rt0a" ] || [ -z "$_rt0b" ]; then
    echo "  FAIL  roundTripT ARM 0 -- could not read either node address (vacuity guard)"; fail=1
elif [ "$_rt0a" != "$_rt0b" ]; then
    echo "  ok    roundTripT ARM 0 MISMATCH -- pinned at the DEFECT (carrier mints fresh)"; green=$((green+1))
else
    echo "  FAIL  roundTripT ARM 0 now MATCHES -- the carrier landed; re-pin this row"; fail=1
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
#  ⚠⚠ THE ANSWER RE-PINNED 2026-09-02, 1 -> the LABEL, AND THE OLD VALUE COULD
#  NEVER HAVE WITNESSED WHAT IT WAS ASKED TO. `1` was `trueResult`, reached
#  because the invocation arrived at a COPY of the field that had been parsed
#  against -- measured, minionWork/anyOrNumCam: install field #1, invoke field
#  #23, one body #2. A copy's rStuff carries no label, and runRuleAction has
#  exactly two returns, `ruleStuff->label` or `trueResult`. So the row read the
#  fallback and called it an answer.
#
#  ⚠ AND trueResult IS ALSO THE NO-rStuff FALLBACK -- `if (!ruleStuff) return
#  trueResult` on the line above -- so `1` cannot distinguish "the body ran and
#  produced nothing" from "there was no rStuff to run against". IT IS AN H4
#  ABSENCE WEARING A VALUE. The label is a real captured span and can only be
#  returned by a body that ran and matched, so it witnesses what the row exists
#  for. THE BODY RAN UNDER BOTH BUILDS -- verified with a marker emitted into all
#  four generated bodies -- so the failure this row was minted to catch was never
#  occurring and the old pin was recording the carrier defect instead.
#
#  CAPABILITY: the argument channel, read through generated-parse EXECUTION. The
#  sibling of holderT row 3 above -- same defect, opposite end: that row asks what
#  an action sees of its argument, this one asks what an invocation reaches.
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
#  ⚠⚠ RE-PINNED 10/4 ON 2026-09-01, AND THE ROW NOW COUNTS SOMETHING ELSE THAN
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
    echo "  FAIL  bare-master population MOVED (row pinned 2026-09-01, NOT a defect count):"
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
#  ⚠ RE-PINNED 2026-09-05 TO THE refuse() TEXT. Same refusal, same count --
#  the message moved into the one funnel and now reads
#  `REFUSED <src> -- iterate: the source has no list [line N]`. A refusal is
#  still announced once per leaf; only its spelling is uniform now.
n=$(grep -c "iterate: the source has no list" "$T/iterT1m.e")
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
#  starIdiomT -- THE STAR IDIOM THROUGH A COMMAND RETURN. SEQ 152 B2.
#  `iterate cur on *field` is the going-forward spelling and the field is
#  usually whatever a command just handed back, so this drives that shape four
#  ways: a command returning a walkable field, one returning NULL, one returning
#  a listless field, and F-22's own subject (a := capture of compile's return).
#  ⚠ ROWS 2 AND 3 ARE A PAIR AND NEITHER STANDS ALONE: they pin WHICH mechanism
#  declines -- the STAR on a null, the ITERATE on a listless field -- and a
#  fixture carrying only one of them cannot tell the two refusals apart.
#  ⚠ EXIT 0 IS THE F-22 ASSERTION. A 139 here is F-22 reopening and this fixture
#  is its reproducer.
run1 starIdiomT "$T/sid";    check "starIdiomT runs (star idiom through a command return)" 0 $?
sentinel "starIdiomT sentinel" "$T/sid" "IDIOM SENTINEL"
if grep -q "^ROW1 member fifth" "$T/sid"; then
    echo "  ok    star reaches a command-returned field and the walk completes"; green=$((green+1))
else
    echo "  FAIL  starIdiomT row 1 -- the walk did not reach its last member, so the"
    echo "        star did not reach the command's field or the walk stopped short."; fail=1
fi
if grep -q "^ERROR unary \* on idN -- it holds no group" "$T/sid"; then
    echo "  ok    a NULL command return refuses AT THE STAR -- PINNED BY TEXT"; green=$((green+1))
else
    echo "  FAIL  starIdiomT row 2 -- the star did not refuse a null by name. Either the"
    echo "        refusal stopped naming its operand, or something downstream reached a"
    echo "        null first: unWrap has no null guard and the iterate's refusal arm reads"
    echo "        the source's tag, and both segfault on one (exit 139, SEQ 152)."; fail=1
fi
#  ⚠ RE-PINNED 2026-09-05 to refuse()'s uniform line; the pair still
#  distinguishes a star refusal from an iterate refusal.
if grep -q "^REFUSED idLeaf -- iterate: the source has no list" "$T/sid"; then
    echo "  ok    a LISTLESS command return refuses AT THE ITERATE -- PINNED BY TEXT"; green=$((green+1))
else
    echo "  FAIL  starIdiomT row 3 -- the iterate did not refuse a listless source by name."
    echo "        Row 2 now asserts nothing either: the pair is what distinguishes a star"
    echo "        refusal from an iterate refusal."; fail=1
fi
if grep -q "^ROW4 survived the capture" "$T/sid"; then
    echo "  ok    F-22 stays closed: := on a command return does not crash"; green=$((green+1))
else
    echo "  FAIL  F-22 HAS REOPENED -- capturing a command's return with := killed the"
    echo "        process. See docs/fixIts.md F-22; this row is its reproducer."; fail=1
fi

#  ---------------------------------------------------------------------------
#  A3 -- OPTIONAL LABELLED TERMS THAT ARE UNGUARDED. PINNED AT ZERO, SEQ 152.
#
#  ⚠ THE INVERSION SENTENCE, and it is the whole reason this row exists: a
#  reader that asks `if label` on an optional term is asking "did it match", and
#  what actually answers is THE GUARD, not the match. RuleStuff's checkInput
#  mints the label BEFORE the term is matched, gated on its own sukcess, and the
#  TOKEN is stamped much later under `counter && counter >= min`. So a term that
#  matched zero times CAN own a label node that was never tokenised -- present,
#  no data, and bear-trap #26 then makes .text return its own tag.
#  What prevents that today is that checkInput's sukcess needs `unGuarded` or
#  `guardSet.contains(*atRuleMark)`: a literal whose first character is absent
#  fails the guard and the label is never minted at all. Missing stays missing.
#  THE DAY AN OPTIONAL LABELLED TERM ACQUIRES `_` OR `{`, EVERY PRESENCE TEST ON
#  IT SILENTLY INVERTS -- and aCTionFOR's `reversE ? prior : next` means every
#  for loop in the system would run BACKWARDS. Nothing else in the fleet can see
#  that, because a backwards walk is still a walk.
#  ============================================================================
#  ⚠ sentinelT -- THE SENTINEL-AS-DATA PROMOTIONS, one section per site.
#  A sentinel-as-data site announced a failure and then handed its caller a
#  VALUE THAT LOOKED LIKE A SUCCESSFUL ANSWER -- so the failure reached a human
#  on stderr and was CONCEALED FROM THE PROGRAM. Tony ruled them promoted one at
#  a time, each with two rows: the caller's read, and the F-41-style row that
#  the statement after does not run.
#
#  ⚠ ST-1's CALLER ROW IS A FINDING RATHER THAN A FORMALITY. It was predicted to
#  read 111 -- a refusal returns null, so surely nothing is written. It does not:
#  stRead comes back as its own TAG, bear-trap #26's signature for no data. THE
#  ASSIGNMENT TOOK AND WROTE THE NULL. A refusal inside an expression BLANKS ITS
#  ASSIGNMENT TARGET, which is a consequence of the ruling nobody stated. Pinned
#  by value so it cannot change quietly.
run1 sentinelT "$T/snt"; check "sentinelT runs" 0 $?
sentinel "sentinelT sentinel (no truncation)" "$T/snt" "SENTINELT SENTINEL"
if grep -qF "ST-1 caller read       = 111" "$T/snt"; then
    echo "  ok    sentinelT ST-1 opAddPointer: an armed statement STORES NOTHING (111 stands)"; green=$((green+1))
else
    echo "  FAIL  sentinelT ST-1 caller read moved -- the store ruling broke -- a refused rhs is blanking its target again"; fail=1
fi
if grep -qF "ST-1 statement after   = 0" "$T/snt"; then
    echo "  ok    sentinelT ST-1 the statement after the refusal did NOT run"; green=$((green+1))
else
    echo "  FAIL  sentinelT ST-1 the statement after the refusal RAN -- not terminal"; fail=1
fi

#  ============================================================================
#  ⚠ THE `ERROR` CENSUS -- Tony's ruling 2026-09-05, part of B.
#  A refusal now speaks through refuse(), which prints REFUSED. So the word
#  ERROR belongs at NO refusal site: the routed ones cannot say it, and the
#  PLANNER family never should have, because a planner refusing a rule it cannot
#  plan is a NORMAL ANSWER ITS CALLER HANDLES rather than a failure.
#
#  ⚠ THE PLANNER ROW IS PINNED AT ZERO AND IS THE ONE THAT MATTERS. genParse's
#  odometer is 46 refusals of 64 rules, RED BY DESIGN, all in ONE walk. Calling
#  those ERROR is what made "route the remaining 92" look reasonable, and
#  routing them would have armed on the first unplannable rule and destroyed the
#  odometer. The word is the guard against repeating that reading.
#
#  The TOTAL is a RATCHET, not a pin: it may only fall as B routes the
#  candidate-TERMINAL bucket. Asserted BY VALUE (H4), never by absence.
plannerErr=$(python3 -c "
import re
chain=['Commands.rtn','GroupActions.rtn','ruleActions.rtn','Debug.rtn','Instruct.rtn','jitEmitters.rtn','genParse.rtn','Generate.rtn']
P={'planRule','planTerm','emitPlan','emitLeaf','emitMany','genKant','kantLeaf','kantDoor','activateAll','activateBody','compileStored','storeBody','actK','setParseMethod','parseRuleMethod','parseTermCount'}
f_=re.compile(r'^extern\s+[A-Za-z_][A-Za-z0-9_ *]*\s+\**([A-Za-z_][A-Za-z0-9_]*)\s*\(')
n=0
for f in chain:
    cur=''
    for l in open(f,errors='ignore'):
        m=f_.match(l)
        if m: cur=m.group(1)
        if cur in P and 'ERROR' in l and ('cerr' in l or 'fprintf' in l): n+=1
print(n)")
totalErr=$(python3 -c "
chain=['Commands.rtn','GroupActions.rtn','ruleActions.rtn','Debug.rtn','Instruct.rtn','jitEmitters.rtn','genParse.rtn','Generate.rtn']
print(sum(1 for f in chain for l in open(f,errors='ignore') if ('cerr' in l or 'fprintf' in l) and 'ERROR' in l))")
if [ "$plannerErr" = 0 ]; then
    echo "  ok    ERROR census: ZERO planner sites say ERROR -- PINNED AT ZERO"; green=$((green+1))
else
    echo "  FAIL  ERROR census: $plannerErr planner site(s) say ERROR. A planner refusing a rule"
    echo "        it cannot plan is a NORMAL ANSWER its caller handles, not a failure --"
    echo "        and calling it ERROR is what makes routing it look reasonable."; fail=1
fi
if [ "$totalErr" -le 23 ]; then
    echo "  ok    ERROR census ratchet: $totalErr of 23 remain (falls as B routes; may not rise)"; green=$((green+1))
else
    echo "  FAIL  ERROR census ratchet ROSE to $totalErr, was 23. A new refusal site should"
    echo "        speak through refuse(), which prints REFUSED and never ERROR."; fail=1
fi

#  ============================================================================
#  ⚠ groups.ext MIRROR ARITY -- A DRIFT THAT tok CANNOT SEE, BY DESIGN.
#  Added 2026-09-05, Tony's explanation + Clay's ruling, after two instances.
#
#  TONY: "tok does not worry about parameters -- it finds jitInlinePop by name
#  and is satisfied." So a groups.ext line is a ROUTING declaration -- which
#  external <Header>.h block, therefore which #include tok emits -- and NOT a
#  signature contract. The parameter list is documentation the toolchain never
#  checks: tok reads the name, and the C++ compiler only ever sees the REAL
#  prototype, because the whole .rtn chain is one TU with GroupRules.h in scope.
#  MEASURED THE SAME DAY: correcting jitInlinePop's mirror and running a full
#  bare tokall produced ZERO codegen change. That byte-identity IS the proof.
#
#  ⚠ WHICH MAKES IT SILENT BY CONSTRUCTION, and puts it in bear-trap #45's
#  family: a name that resolves but means less than it reads. Nothing in any
#  build, canary or fleet row could ever have caught either instance -- the
#  extern canary read 350 throughout both.
#
#  Two found, two fixed: jitInlinePop (mirrored 0, real 1) and opDivEQ (mirrored
#  1, real 2 -- its own siblings opPlusEQ/opMinusEQ were already right).
#  ⚠ WHY A ROW AND NOT A LINT: the census IS the lint and costs nothing here. A
#  separate script would be a second population for one subject.
#  Compared by ARITY, not by type text: the mirror writes `GroupItem` where the
#  header writes `GroupItem *`, and that difference is not drift.
mirrordrift=$(python3 -c "
import os,re,glob
ext=os.path.expanduser('~/Dropbox/data/InProcess/Include/groups.ext')
mirror={}
for line in open(ext):
    m=re.match(r'\s*extern\s+[A-Za-z_][A-Za-z0-9_]*\s+([A-Za-z_][A-Za-z0-9_]*)\s*\((.*?)\)\s*;',line)
    if m:
        a=m.group(2).strip()
        mirror[m.group(1)]=0 if a=='' else len([x for x in a.split(',') if x.strip()])
real={}
for h in glob.glob('*.h'):
    for line in open(h,errors='ignore'):
        m=re.match(r'extern\s+.C.\s+[A-Za-z_][A-Za-z0-9_ *]*?\s*\*?\s*([A-Za-z_][A-Za-z0-9_]*)\s*\((.*?)\)\s*;',line)
        if m:
            a=m.group(2).strip()
            real[m.group(1)]=0 if a in ('','void') else len([x for x in a.split(',') if x.strip()])
both=set(mirror)&set(real)
d=[k for k in sorted(both) if mirror[k]!=real[k]]
print('%d %d %s' % (len(d), len(both), ' '.join(d)))
")
mdn=$(echo "$mirrordrift" | cut -d' ' -f1)
mdcmp=$(echo "$mirrordrift" | cut -d' ' -f2)
mdnames=$(echo "$mirrordrift" | cut -d' ' -f3-)
#  ⚠ ANTI-VACUITY: the comparable count must be large, or a regex that matched
#  nothing would report zero drift and read as green (H4's other half).
if [ "$mdcmp" -lt 250 ]; then
    echo "  FAIL  groups.ext mirror census compared only $mdcmp names -- the census is broken, not the mirrors"; fail=1
elif [ "$mdn" = 0 ]; then
    echo "  ok    groups.ext mirror arity: 0 drift over $mdcmp comparable names -- PINNED AT ZERO"; green=$((green+1))
else
    echo "  FAIL  groups.ext mirror arity: $mdn of $mdcmp drift -- $mdnames"
    echo "        tok resolves by NAME, so nothing else in the fleet can see this."
    fail=1
fi

#  Censused 2026-09-03 (SEQ 149 recon): the set is EMPTY. This row keeps it so.
#  ⚠ THE CHECK STRIPS CHARACTER CLASSES FIRST, and that is not a detail: `_` and
#  `{` are ordinary MEMBERS of two character sets in this grammar (modifySet and
#  Modifier, lines 30 and 60), so a plain regex reads them as modifiers and the
#  row fails on two false positives. A modifier is what follows the term body,
#  never what sits inside [ ].
unguarded=$(python3 -c "
import re,sys
n=0
for l in open('incant/grammar'):
    if l.lstrip().startswith('//'): continue
    b=re.sub(r'\[[^]]*\]','',l)          # drop character classes
    for m in re.finditer(r'[A-Za-z_][A-Za-z0-9_]*\??=\S+', b):
        t=m.group(0)
        if ('?' in t or '*' in t) and ('_' in t.split('=',1)[1] or '{' in t.split('=',1)[1]): n+=1
print(n)")
if [ "$unguarded" = "0" ]; then
    echo "  ok    no optional labelled term is unguarded -- PINNED AT ZERO (presence tests hold)"; green=$((green+1))
else
    echo "  FAIL  $unguarded optional labelled term(s) carry _ or { and are therefore UNGUARDED."
    echo "        checkInput will mint their label even when they do not match, so every"
    echo "        presence test on them inverts -- aCTionFOR's reversE would send every for"
    echo "        loop backwards. Give the term a guard, or stop presence-testing its label."; fail=1
fi

#  ---------------------------------------------------------------------------
#  A4 -- THE isContinue CENSUS. SEQ 152, from SEQ 151's finding.
#
#  ⚠ THERE ARE THREE IDENTICAL GUARD BODIES, NOT TWO, and the third is why this
#  is pinned. aCTionDO, aCTionFOR and aCTionWhilE each carry the same seven
#  lines (md5-identical with comments stripped). A comment on two of them read
#  "SITE-SPECIFIC READ, not a paste", which was true about the RATIONALE and
#  false about the code -- and reading it as a barrier is what kept aCTionWhilE's
#  copy unnoticed by two separate passes, because it was never named as part of
#  "the pair". A count is the only thing that would have said so.
#  The guard is NOT extractable: its arms are continue/return/break over the
#  CALLER'S loop, so a callee cannot carry them. So the three copies are
#  permanent, and what this row protects is that a fourth does not appear
#  unnoticed, and that one of the three does not quietly go missing.
cont=$(grep -c "^ *if isContinue {" ruleActions.rtn | tr -d " ")
setr=$(grep -c "isContinue  = true;" ruleActions.rtn | tr -d " ")
if [ "$cont" = "3" ] && [ "$setr" = "1" ]; then
    echo "  ok    isContinue: 3 guard arms, 1 setter -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  isContinue census moved: $cont guard arms (want 3), $setr setter (want 1)."
    echo "        A fourth arm is a fourth copy of a body that cannot be extracted -- give it"
    echo "        the ruleActions.trailingContinueGuard pointer. A missing arm is a loop form"
    echo "        that no longer consumes its trailing continue; incant/trailingContinueT"
    echo "        covers all three and will say which."; fail=1
fi

#  ---------------------------------------------------------------------------
#  THE ITERATE DRIFT ROW, SEQ 148. The modifier now precedes `on`:
#  the modifier keyword goes BEFORE `on`, never after the source.
#  The old form does not fail -- it PARSES, binds the source, and leaves the
#  modifier behind as a stray statement, so the walk silently loses its filter.
#  A fixture written the old way therefore goes GREEN on a wrong population, or
#  hangs, and NOTHING in the fleet can see it: there is no row for a filter that
#  quietly stopped filtering. Hence a text pin at zero.
#
#  ⚠ REPO-WIDE, NOT `incant/`, AND THAT SCOPE IS THE WHOLE VALUE OF THIS ROW.
#  The SEQ 148 respell was written against `incant/` and MISSED FOUR LIVE
#  HARNESS FIXTURES IN `genLadder/` -- countPopulation, odoPopulation,
#  breakSpecimen, breakFire. They unfiltered two census walks and moved three
#  pinned counts by +15 and +19, which read exactly like a grammar disaster and
#  was a scope error in the sweep. A drift row scoped to the same directory the
#  sweep used would have gone green through all of it.
#  docs/, ipc/ and .trace files are excluded because they are PROSE and dated
#  records: the old form appears there as quotation and rewriting it would
#  falsify the record.
#  IncantForms/ is excluded because it is Tony's, and its live count is
#  reported in the seal rather than swept.
drift=$(grep -rn "iterate  *[A-Za-z_][A-Za-z0-9_]*  *on  *[A-Za-z_][A-Za-z0-9_]*  *\(attributes\|members\) *;" . 2>/dev/null \
        | grep -v "^\./docs/" | grep -v "^\./\.git/" | grep -v "^\./ipc/" | grep -v "^\./IncantForms/" | grep -v "^\./BeforeSave/" | grep -v "^\./Aside/" | grep -v "^\./BackupIncant/" | wc -l | tr -d " ")
if [ "$drift" = "0" ]; then
    echo "  ok    iterate drift: zero old-form \`on X attributes;\` sites -- PINNED AT ZERO"; green=$((green+1))
else
    echo "  FAIL  iterate drift: $drift site(s) still write the OLD form \`on X attributes;\`."
    echo "        That form still PARSES -- it binds the source and drops the modifier as a"
    echo "        stray statement -- so the walk silently loses its filter and the fixture"
    echo "        goes green on the wrong population. Respell to \`attributes on X;\`:"
    grep -rn "iterate  *[A-Za-z_][A-Za-z0-9_]*  *on  *[A-Za-z_][A-Za-z0-9_]*  *\(attributes\|members\) *;" . 2>/dev/null \
        | grep -v "^\./docs/" | grep -v "^\./\.git/" | grep -v "^\./ipc/" | grep -v "^\./IncantForms/" | grep -v "^\./BeforeSave/" | grep -v "^\./Aside/" | grep -v "^\./BackupIncant/" | sed "s|^|          |"
    fail=1
fi

#  ---------------------------------------------------------------------------
#  A REFUSED ITERATE MUST REFUSE AND RETURN, NOT RUN AWAY. Added 2026-09-03,
#  SEQ 147 item 0, and it is a CERTIFICATION of standing behaviour rather than
#  a regression test for a repair -- the mechanism was measured correct on main
#  and nothing was changed.
#
#  WHY IT EARNED A ROW ANYWAY. Nothing in the fleet covered it, and the poison
#  aCTionIterate writes on refusal is the only thing between a refused iterate
#  and an unbounded loop: the advance on a non-iterator sets a count to one and
#  increments it forever, and every value it yields is true. Measured at over
#  eleven million iterations in fifteen seconds, with no output to be
#  suspicious of. SEQ 146 showed the poison is one wrong operand away from
#  landing on the parse wrapper instead of the cursor, at which point this
#  hangs -- so the behaviour is fragile as well as uncovered.
#
#  ⚠ THE NEGATIVE CONTROL WAS RUN, per rule H7, and it is why this row is a
#  certification and not a decoration. With the poison write removed from
#  aCTionIterate's refusal arm and the binary rebuilt, row R HANGS: exit 137
#  under the cap, 7,559,089 lines of the line that must never print. Restored,
#  it refuses and returns. This row fails when the mechanism is removed.
#
#  ⚠ THE TIMEOUT IS THE POINT, so read a cap here as the defect and never as a
#  slow machine. Every other row's cap is a safety net; this one's is the
#  assertion.
#
#  ROW W IS THE ANTI-VACUITY SIBLING AND IT ASSERTS BY NAME. Row R expects a
#  walk of length zero and a dead fixture would produce zero too. W walks a
#  real eight member group and the fleet greps its LAST member, because a walk
#  that stops early agrees with a walk that works about everything except how
#  far it got. Counting was tried first and abandoned on a measurement: an
#  undeclared counter incremented in an iterate body reads back zero while the
#  same walk demonstrably prints all eight members. Separate finding, reported;
#  this row does not depend on it.
run1 iterRefuseT "$T/irf";   check "iterRefuseT runs (a refused iterate returns)" 0 $?
sentinel "iterRefuseT sentinel" "$T/irf" "ITERREFUSET SENTINEL"
#  ⚠ RE-PINNED 2026-09-05 to refuse()'s uniform line.
if grep -q "^REFUSED irLeaf -- iterate: the source has no list" "$T/irf"; then
    echo "  ok    refused iterate ANNOUNCES BY NAME -- PINNED BY TEXT (H4)"; green=$((green+1))
else
    echo "  FAIL  the refusal line is GONE. Either the refusal stopped naming its"
    echo "        source, or the iterate stopped refusing a listless leaf. An"
    echo "        absence here is not 'nothing went wrong' -- it is the only"
    echo "        warning a refused iterate ever gives."; fail=1
fi
#  ⚠⚠ THIS ROW IS INVERTED, 2026-09-05, AND THE INVERSION IS THE RULING LANDING.
#  It used to assert `R ok` -- the statement AFTER the refused loop -- was
#  REACHED, because the old law was "a refusal announces and the action carries
#  on". Tony ruled the opposite on f31's 2,808,029 lines: A REFUSAL ENDS THE
#  ACTIVATION THAT RAISED IT. So the statement after a refused loop MUST NOT
#  RUN, and `R ok` must now be ABSENT.
#  ⚠ AN ABSENCE CANNOT STAND ALONE (H4), so it is paired with the SENTINEL: the
#  run must have reached its foot. Sentinel present plus `R ok` absent means the
#  statement was SKIPPED; sentinel absent would mean the run died, which is a
#  different fact and is caught as a different row. Without the pairing this
#  would pass on any truncated run.
if grep -q "ITERREFUSET SENTINEL" "$T/irf" && ! grep -q "^R ok" "$T/irf"; then
    echo "  ok    refusal is TERMINAL: the statement after a refused loop did NOT run"; green=$((green+1))
elif ! grep -q "ITERREFUSET SENTINEL" "$T/irf"; then
    echo "  FAIL  iterRefuseT truncated -- the absence of R ok below asserts nothing"; fail=1
else
    echo "  FAIL  iterRefuseT row R -- `R ok` STILL PRINTS, so the statement after"
    echo "        a refused loop still runs. The refusal did not arm, or"
    echo "        aCTionBlocK is not checking the arm."; fail=1
fi
if grep -q "^R BAD" "$T/irf"; then
    echo "  FAIL  iterRefuseT row R -- the advance MOVED on a refused iterate."
    echo "        The cursor was not poisoned; the walk is running on a node that"
    echo "        has no list."; fail=1
else
    echo "  ok    refused iterate did not move the cursor"; green=$((green+1))
fi
if grep -q "^W member fifth" "$T/irf"; then
    echo "  ok    row W reached its LAST member -- row R's zero means refusal"; green=$((green+1))
else
    echo "  FAIL  iterRefuseT row W -- the walk did not reach 'fifth', so the"
    echo "        iterate machinery is dead or short and ROW R ASSERTS NOTHING."
    echo "        Fix this before reading row R at all."; fail=1
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
#  ⚠ THE EMPTINESS CHECK CARRIES ITS OWN ROW-COUNT GUARD, and it is NOT a
#  duplicate of the non-vacuity row above. Measured 2026-09-04 (C-156 group 1):
#  under the flip the unstarred walk returned ZERO rows, so this row read
#  "data-plus-members set is EMPTY -- no exceptions" and went GREEN while the
#  row above correctly went red. One green and one red on the same empty walk,
#  and the green one is the claim a reader believes. An assertion must not
#  outsource its own precondition to a neighbouring row: the neighbour can be
#  read as a separate failure, re-pinned, or moved, and this row would go on
#  passing for want of rows rather than for want of exceptions. That is rule
#  H4's absence-versus-value applied to a SET, and the third member of the
#  "a constant the default could also produce asserts nothing" family.
if [ "$scrows" -gt 0 ] && [ -z "$schybrid" ]; then
    echo "  ok    pick-one: data-plus-members set is EMPTY over $scrows rows -- no exceptions"; green=$((green+1))
elif [ "$scrows" -eq 0 ]; then
    echo "  FAIL  pick-one is VACUOUS -- the walk returned ZERO rows, so the empty"
    echo "        set says nothing about the partition. This row asserts its own"
    echo "        precondition; it does not borrow the row above's."; fail=1
else
    echo "  FAIL  pick-one partition MOVED: data-plus-members set is { $schybrid}"
    echo "        Expected EMPTY over $scrows rows. A container's derived set is"
    echo "        exempt by binTypE; anything appearing here is a rule that was"
    echo "        genuinely written as both, which is what pick-one forbids."; fail=1
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
#  ⚠ RE-PINNED 2026-09-01, AND THE SENTENCE IS: `tokenize` RETIRED BY RULING.
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
#  ⚠ RE-PINNED 45/63 -> 46/64, 2026-09-03, SEQ 148, and the sentence is that the
#  grammar gained EXACTLY ONE RULE by Tony's ruling. The whole delta is one new
#  row -- `IterSource  REFUSE ANYtoken -- inline group / structural data isGROUP`
#  -- so the ratchet's GREEN count is UNMOVED at 18 and the red went up by the
#  one rule that was added. A new rule arriving un-emittable is the expected
#  state for this odometer, not a regression: nothing has taught genParse about
#  IterSource and nothing claimed to.
diffcheck "genParse odometer (18 green / 46 red of 64 -- RED BY DESIGN, pinned; ratchet monotone)" \
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
#  ⚠ RE-PINNED 39 -> 40, 2026-09-03, SEQ 148, AND THE SENTENCE IS THE POINT:
#  the grammar gained EXACTLY ONE RULE, `IterSource`, by Tony's ruling. The
#  delta is +1 here, +1 in the odometer's qualifying population (63 -> 64) and
#  +1 in shadowCensus's walk (83 -> 84) -- three independent rule counts moving
#  by one, which is what a single added rule looks like and is not what
#  anything else looks like. `0 missing, 0 parse-failed` HELD ACROSS THE MOVE,
#  so the new rule compiles clean rather than merely being counted.
#  A first attempt at this stroke moved these numbers by +15 and +19 instead.
#  That was NOT the ruling: it was an incomplete respell -- `genLadder/`
#  carries four incant files (countPopulation, odoPopulation, breakSpecimen,
#  breakFire) that the respell's `incant/` glob never saw, and their stale
#  `on X members;` left `members` behind as a stray statement, unfiltering the
#  census walk. Named here because +19 and +1 have the same shape in a diff and
#  only one of them is the ruling.
if [ "$cntline" = "THE COUNT: 40 compiled clean, 0 parse-failed, 0 crashed/truncated, 0 missing, of 40 attempted" ]; then
    echo "  ok    countPop headline (40/40 clean, 0 missing) -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  countPop headline moved"; echo "          actual:   $cntline"
    echo "          expected: THE COUNT: 40 compiled clean, 0 parse-failed, 0 crashed/truncated, 0 missing, of 40 attempted"
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
#  ⚠ THE FILE LIST WAS A HARDCODED SIX AND IS NOW `*.mm`, 2026-09-04. The cleanup
#  arc moved fourteen methods out of the GroupRules chain into a new measure.twk,
#  and SIXTEEN of the thirty reads went with them -- so the row read 14 and cried
#  drift when nothing had drifted. The accounting is exact and was checked before
#  the re-pin, not after: 14 in the old six + 16 in measure.mm = 30, none of them
#  comment text (designDocs carries zero `-`+`>rStuff` after the move). `*.mm` over
#  the top level gives 30, the same number the six-file list gave before the move,
#  and it now matches what `rawlines` below already globs. Bear-trap #47: a census
#  population is every file that can carry the thing, not a list someone maintains.
rawreads=$(grep -o -- "->rStuff" *.mm 2>/dev/null | grep -vc "getRStuff\|setRStuff")
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

#  ⚑ walkRefT -- THE WALK-WRITER ROW, AND ROW 3 IS A TRIPWIRE FOR THE FLIP
#  LANDING. A bare accessor DIRECTLY inside a ++ walk with NO intervening call,
#  so only the walk writer can have aimed lastREF at the read. Rows 1 and 2 are
#  the invariant and hold on both arms. ROW 3 IS PINNED TO THE ARM THE FLEET RUNS
#  ON, NOT TO THE ANSWER THAT WILL SURVIVE: wrHeld is a member that is itself a
#  holder, bare reads `wrTarget` because the bare road auto-unwraps, and the flip
#  reads `wrHeld`. WHEN THE FLIP LANDS THIS ROW GOES RED AND THAT IS IT WORKING --
#  re-pin to wrHeld THEN, with a sentence (H6), and not before.
#  R2 retired on this fixture's evidence 2026-09-04: the walk writers store the
#  HELD at all four sites, so there was nothing for R2 to change and following a
#  holder level at the write would have regressed row 3 under the flip.
run1 walkRefT "$T/wrt"; check "walkRefT runs" 0 $?
sentinel "walkRefT sentinel" "$T/wrt" "WALKREFT SENTINEL"
wrn=$(grep -c "^W bare taG = " "$T/wrt")
if [ "$wrn" = "3" ]; then
    echo "  ok    walkRefT walked 3 members (anti-vacuity: an empty walk pins nothing)"; green=$((green+1))
else
    echo "  FAIL  walkRefT walked '$wrn' members, want 3 -- the pins below mean nothing"; fail=1
fi
for _wr in "W bare taG = aa" "W bare taG = bb"; do
    if grep -qF "$_wr" "$T/wrt"; then
        echo "  ok    ${_wr} -- PINNED BY VALUE (invariant, both arms)"; green=$((green+1))
    else
        echo "  FAIL  $_wr -- moved"; fail=1
    fi
done
if grep -qF "W bare taG = wrTarget" "$T/wrt"; then
    echo "  ok    walkRefT row 3 = wrTarget -- BARE PIN, the flip tripwire"; green=$((green+1))
elif grep -qF "W bare taG = wrHeld" "$T/wrt"; then
    echo "  FAIL  walkRefT row 3 = wrHeld -- THE FLIP HAS LANDED, or the binary is"
    echo "        flipped. This row is DOING ITS JOB. Re-pin to wrHeld with a"
    echo "        sentence (H6); do not re-pin to silence it."; fail=1
else
    echo "  FAIL  walkRefT row 3 is neither wrTarget nor wrHeld -- a third answer"
    echo "        means the walk writer changed, which is not what either arm does."; fail=1
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
