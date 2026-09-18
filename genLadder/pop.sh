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

#  ip <name> -- resolve a fixture NAME to its path, so the incant/ layout can change
#  without touching a single row label. Falls back to incant/<name> so an unknown name
#  still produces the old error rather than an empty path.
ip () {
    for _d in incant incant/pop incant/pop/jit incant/fixits; do
        [ -f "$_d/$1" ] && { printf '%s\n' "$_d/$1"; return; }
    done
    printf '%s\n' "incant/$1"
}

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
#  ⚠ PAID FOR ON 2026-09-05, and the switch it was paid for is now GONE while
#  the check outlives it -- which is the point. jitContext.h read
#  `gNoUnwrap = 0` while the installed binary had been built at 1: flipped,
#  tested, the SOURCE flipped back, no rebuild. The fleet read 141 green against
#  a sealed 197 and looked like a catastrophic regression. It was THE OTHER
#  PROGRAM, and nothing in the tree could say so -- the source was right about
#  itself, the binary was right about itself, and only the PAIR was wrong.
#  ⚠ THE LESSON GENERALISES PAST THAT ONE FLAG: when a switch lives in SOURCE
#  and its effect lives in a BUILD, reading the switch is not reading the
#  system. Bear-trap #49.
newest=$(ls -t *.rtn *.twk *.h 2>/dev/null | head -1)
if [ -n "$newest" ] && [ "$newest" -nt "$(readlink "$B" 2>/dev/null || echo "$B")" ]; then
    echo "  ⚠ STALE  $newest is NEWER than the binary -- REBUILD BEFORE BELIEVING ANY ROW BELOW."
    echo "           Every number in this run is about a program that is not the source on disk."
else
    echo "  bin   built no earlier than the newest source ($newest)"
fi

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
run1 () { $B "$(ip "$1")" > "$2" 2>&1      & _cap "$1"; }   # merged
run2 () { $B "$(ip "$1")" > "$2" 2> "$3"   & _cap "$1"; }   # split

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
if [ -s "$T/base" ] && tail -1 "$(ip baselineTests.golden)" | grep -qFf - "$T/base"; then
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

#  ⚠ noPrintFrameT -- FLAGGING AN ACTION LOCAL `noPrint` DURING THE BODY SHIFTS
#  THE NEXT ACTIVATION'S FRAME RESTORE BY ONE SLOT. saveLocalFields
#  (GroupActions.rtn:1196) walks FORWARD and pushes; restoreLocalFields (:747)
#  walks BACKWARD and pops; the pairing is positional and `noPrint` is IN THE
#  FILTER. So a flag the body sets between the two walks drops that field from
#  the restore set only, and every field below it gets the wrong body back --
#  tag included, because `*groupBody = *body` copies the struct.
#
#  The two arms differ by ONE statement, `npM2 :. noPrinT;`. Rows 1-2 are the
#  control and they are NOT decoration: they are what says the shift is the
#  flag and not the minting, and N2 is the anti-vacuity sibling that fails if
#  a second activation stops binding its argument at all.
#
#  ⚠ N4 GRADUATED 2026-09-06 (H6). It was born pinned RED against the correct
#  answer while the shift was live; the identity pairing + frame floor fixed
#  it in the same session and it is now an ordinary value pin. Row 3 is clean
#  on BOTH arms because the flag is not set until the first body has already
#  run, which is what makes row 4 the discriminator.
#
#  Found 2026-09-06 under IncantForms/WorkingOn/parser, where generateParse's
#  `codeCopy :. noPrinT;` shifted `argument` onto `conjunct` and every call
#  after the first refused inside setParse.
run1 noPrintFrameT "$T/npf"; check "noPrintFrameT runs" 0 $?
sentinel "noPrintFrameT sentinel (no truncation)" "$T/npf" "NOPRINTFRAME SENTINEL"
for _n in "N 1 control  arg  npAlpha local1  npC1" \
          "N 2 control  arg  npBeta local1  npC1" \
          "N 3 treated  arg  npAlpha local1  npM1" \
          "N 4 treated  arg  npBeta local1  npM1"; do
    if grep -qF "$_n" "$T/npf"; then
        echo "  ok    noPrintFrameT row ${_n:2:1} -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  noPrintFrameT row ${_n:2:1} -- wanted: $_n"; fail=1
    fi
done

#  argRoundT -- A->B->A, a LOCAL and an ARGUMENT each carried across the nested
#  call. The intervening arB is passed 41 and every arA is passed 7, ON PURPOSE:
#  had both been 7, a channel that handed every callee the same node would print
#  7 three times and pass. INTERPRETED ARM ONLY -- the JIT arm is argRoundJ.
run1 argRoundT "$T/art"; check "argRoundT runs" 0 $?
sentinel "argRoundT sentinel (no truncation)" "$T/art" "ARGROUND SENTINEL"
#  ⚠ THESE THREE ROWS ARE THE RECURSION-BOUND WITNESS, and 2026-09-06 is when
#  they earned that name. The frame-floor stroke landed an identity-keyed
#  restore whose first cut had NO per-activation bound: the innermost return
#  drained every frame below it, and depths 2 and 1 came back as TAG ECHOES
#  (`argument = argument local = arMine`, bear-trap #26's signature for "no
#  data") while depth 3 stayed correct. These rows caught it. The pins were
#  already by-value and needed no change.
#  ⚠ WHAT DID GO WRONG IS WORTH THE LINE: the same fixture was checked ad hoc
#  ON ITS EXIT STATUS, read as exit 0, and used to declare the recursion
#  hypothesis FALSIFIED -- which sent the hunt away from the real cause for a
#  round. argRoundT exits 0 with every row wrong. NEVER grade a value fixture
#  on its exit code; that is the third corollary in CLAUDE.md's testing block,
#  and this is it walked into head-first.
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
#  ⚠ THE BOUNDARY'S OWN VOICE, 2026-09-17 (Tony's ruling). Until today aCTionDefinE's
#  refusalBoundary deleted a definition in PERFECT SILENCE and the only symptom was
#  that nothing later could find the field. It now names what it removes WHEN it
#  removes it, and this is the row that pins the message. The pairing with the
#  REFUSED row above is guaranteed rather than hoped for: refuse() is the SOLE writer
#  of ruler.refused, so this line cannot print without that one above it.
if grep -q "REMOVED arBad from ArgRetired -- a refusal fired while it was being defined" "$T/art2"; then
    echo "  ok    argRetiredT THE BOUNDARY NAMES WHAT IT REMOVES -- arBad, by name, from its registry"; green=$((green+1))
else
    echo "  FAIL  argRetiredT the boundary removed arBad SILENTLY. Actual:"
    grep -F "REMOVED" "$T/art2" | sed 's/^/          /'; fail=1
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
    echo "          want: argument = 7, as "$(ip argRoundT)" reads it interpreted"
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
#  ⚠ K5 AND K6 PINNED 2026-09-06 -- THE FRAME-FLOOR GATE, discharged after the
#  fact. Both were chartered 08-05 and neither was ever on the fleet, so the
#  frame arc's two sharpest questions were answered in a seal and then left
#  unguarded. K5 asks whether INVOCATION HISTORY changes the answer (call 1 vs
#  call 2 of one shape); K6a asks whether A->B->A carries a node-resident local
#  across, which `recursive` can NEVER cover because it is set at parse time by
#  identity.
#  ⚠ K6e's FIRST walk is the anti-vacuity sibling and is pinned with the second:
#  a restart row over a walk that never ran asserts nothing. K6f is AMBIGUOUS BY
#  DESIGN since 08-10 (4 means trample+restart OR fully bracketed) and is read
#  with K6a, so it is pinned as a liveness value and never as a verdict.
for _k in "K5 call 1 returned = 42" \
          "K5 call 2 returned = 42" \
          "K6a outer returned = 3" \
          "K6b outer returned = 3" \
          "K6d second walk counted = 3" \
          "K6e first walk counted = 1" \
          "K6e second walk counted = 1" \
          "K6f outer returned = 4"; do
    if grep -qF "$_k" "$T/k8"; then
        echo "  ok    $_k -- PINNED BY VALUE (frame-floor gate)"; green=$((green+1))
    else
        echo "  FAIL  ${_k%%=*}-- wanted: $_k"; fail=1
    fi
done
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
#  ⚠ S5-S10 ADDED 2026-09-07 -- THE STAR/DOT PRECEDENCE ROTATION. `*a.b` now means
#  `(*a).b` and `*a[k]` means `(*a)[k]`, rotated in aCTionTokenXP's postfix arms.
#  S5 and S6 are S7's control pair: S5 reads the length off the target DIRECTLY (3)
#  and S6 reads the holder's OWN list, which is empty -- so a rotation that did
#  nothing cannot pass S7 by accident.
#  ⚠⚠ S10 IS NOT DECORATION, IT IS THE ROW THAT MADE S9 MEAN ANYTHING. Before the
#  subscript half of the rotation, `*a[k]` read a tag echo for a PRESENT key and
#  for a MISSING one alike -- the subscript was being DROPPED, not applied to the
#  dereferenced target. Pinning S9 alone would have gone green on that the moment
#  it read BB, with nothing asserting the subscript had actually run. S9 and S10
#  must disagree; if they ever agree again, the subscript is being discarded.
for _arm in "starT S1  *x   one-deep   = stA" \
            "starT S3a **x  ONE-deep   = stD" \
            "starT S4  *x   on a LEAF  = stF" \
            "starT S5  a.b     direct   = 3" \
            "starT S6  a.b     holder   = stH" \
            "starT S7  *a.b    holder   = 3" \
            "starT S8  a[k]    holder   = stL" \
            "starT S9  *a[k]   holder   = BB" \
            "starT S10 *a[miss] holder   = stN"; do
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
            "pointerT D  depth        = ptOther" \
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
#  ⚠⚠ F0 AND F4 GRADUATED 2026-09-08 (H6), tag echo -> 0. Both had been PASSING on
#  a bear-trap #26 echo: an unwritten flag carried no data, so the read returned
#  the field's own NAME and the control could not distinguish "unset" from
#  "unreadable". F0's own want-text says "must NOT read 1" and F4's says "NOT
#  READABLE" -- 0 satisfies both honestly where the echo only appeared to. Tony's
#  opDot change supplies the value, bareIfTruth makes `if` read it. Re-pinned onto
#  what the rows already claimed, not onto whatever the run happened to print.
#  ⚠⚠ WHY F2 AND F3 ARE RED, AND WHY THAT IS THE FIXTURE WORKING. Diagnosed by
#  incant/fixits/faceFlagsNoCross, retired to incant/attic/faceFlagsNoCross
#  2026-09-15 with its verdict intact. The face is a COPY OF A COPY: `+%`
#  attaches a copy and stamps isAttribute, then `<-` MINTS A COPY rather than
#  aliasing (a ruled defect, Tony 2026-08-23, not the design). So the two names
#  do not share a body -- F1's second ADDROF row reads body=#4 against #2 and is
#  red for exactly that reason -- and a flag written through one is not visible
#  through the other. F2 and F3 cannot pass until copy-on-rebind is fixed, and
#  when it is, F0 must STAY 0; if F0 moves to 1 the fix has over-shared.
#
#  ⚠⚠ DO NOT "FIX" F2 BY ADDING A STAR. `*faFace.noPrinT` reads 1 where
#  `faFace.noPrinT` reads 0, and the starred form is NOT A FLAG READ: measured
#  2026-09-15, it returns no data at all on the SOURCE field the flag was just
#  written to, and no data on the never-written control. It answers 1 in one
#  position out of three. A row pinned on it would go green and assert nothing
#  -- a target regenerated green, which the retired citizen's NEXT block said
#  must not happen, arriving through a door it did not anticipate. Bear-trap #26
#  payment seven, cross-referenced to #48's `*a.b` association.
run1 faceT "$T/face"; check "faceT runs" 0 $?
if grep -q "FACET SENTINEL" "$T/face"; then
    echo "  ok    faceT sentinel (no truncation)"; green=$((green+1))
else
    echo "  FAIL  faceT sentinel MISSING"; fail=1
fi
for _arm in "ADDROF faSrc field=#1 body=#2" \
            "ADDROF faSrc field=#3 body=#2" \
            "faceT F2 flags FORWARD  = 1" \
            "faceT F0 anti-vacuity   = 0" \
            "faceT F3 flags REVERSE  = 1" \
            "faceT F4 parent read    = 0"; do
    if grep -qF "$_arm" "$T/face"; then
        echo "  ok    ${_arm} -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  $_arm -- moved"; fail=1
    fi
done

#  ============================================================================

#  ============================================================================
#  ⚠⚠ starFlagT -- JOINS THE FLEET 2026-09-15 AS THE ACCEPTANCE FIXTURE FOR THE
#  CHAINED-DOT CHANGE (`.` as a binary left-associative operator). Tony's ruling.
#  Its rows are what FLIP when that lands; until then they pin what the language
#  does today, which is not what anyone reading `*x.flag` expects.
#
#  ⚠ IT WAS MINTED BY A NEAR-MISS. incant/fixits/faceFlagsNoCross spelt its
#  forward row `*fcFace.noPrinT` and read 1 where faceT's `faFace.noPrinT` reads
#  0, and the citizen was one commit from retiring as "fixed" on that 1.
#
#  ⚠⚠ SF-6 IS THE ROW THAT SETTLES IT. SF-1 against SF-2 is only a disagreement
#  -- it says one of them is wrong, not which. SF-5 and SF-6 ask the SAME
#  question of the SOURCE field the flag was just written to, where the answer is
#  not in doubt: plain says 1, starred returns the local's own TAG. A spelling
#  that cannot read a flag off the field carrying it is not reading flags at all.
#
#  ⚠ THE TAG ECHOES ARE PINNED BY VALUE ON PURPOSE AND THIS IS NOT A BEAR-TRAP
#  #26 RE-OFFENCE. Pinning an echo AS IF IT WERE DATA is the trap; pinning it as
#  the evidence that there IS no data is the assertion, and it is
#  presence-with-value rather than absence-of-message (H4). The day the starred
#  read returns a number these two rows go red and somebody re-reads.
#
#  ⚠ SF-0 IS LOAD-BEARING: if the two bodies were ONE body, SF-1's 0 would be a
#  defect instead of the right answer. `+%` attaches a copy and `<-` mints one,
#  so the face is a copy of a copy. Mechanism for the star is bear-trap #48's
#  second half -- `.` is in the UnaryOPS bin, so `*a.b` is two terms and
#  right-to-left association gives `*(a.b)`, a star on a flag's VALUE.
#
#  ⚠⚠ WHEN THE FOLD LANDS, READ THE FIXTURE'S OWN HEADER BEFORE GRADING IT. It
#  ⚠⚠ THE PRE-REGISTERED PREDICTION IS RESOLVED 2026-09-16 AND IT FAILED, WITH THE
#  CONTROL INTACT. It said SF-2 1->0, SF-4 echo->0, SF-6 echo->1 once the dot
#  folded. The fold landed (incant/pop/dotChainT) and NONE of the three moved --
#  and SF-1/SF-3/SF-5 did not move either, which is the clause that matters: the
#  treatment never reached the read machinery, so this is a genuine NEGATIVE
#  RESULT and not a voided control. The prediction was built on SF-0's wrong pair.
#  WHAT THE ROWS MEAN NOW: SF-2's 1 is the flag crossing LAWFULLY between two
#  fields over one body. SF-4 and SF-6 are NULL BY RULING -- Tony's star ruling of
#  2026-09-05, re-affirmed 2026-09-16, at Instruct.opDeref.starRuling: `*x` on a
#  field that holds no group yields NULL and does NOT refuse, and the CONSUMER of
#  the null refuses. Those two rows are the language behaving as ruled.
#  The old third-outcome clause is kept below because it is still how to read a
#  move in SF-1 or SF-5:
#  the treatment touches
#  controls and every row below them is uninterpretable rather than wrong.
#  Report a voided control; do not grade it.
run1 starFlagT "$T/sf"; check "starFlagT runs" 0 $?
sentinel "starFlagT sentinel (no truncation)" "$T/sf" "STARFLAG SENTINEL"
for _arm in "SF-1 face   NO star   =  0" \
            "SF-2 face   WITH star =  1" \
            "SF-3 MISS control never written  NO star   =  0" \
            "SF-4 MISS control never written  WITH star =  sfCtlS" \
            "SF-5 HIT control the SOURCE      NO star   =  1" \
            "SF-6 HIT control the SOURCE      WITH star =  sfSrcS"; do
    if grep -qF "$_arm" "$T/sf"; then
        echo "  ok    starFlagT ${_arm} -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  starFlagT $_arm -- MOVED. If the chained-dot fold has landed"
        echo "        this is the EXPECTED flip: read starFlagT's own prediction"
        echo "        block, and check SF-1/SF-3/SF-5 first -- a move there voids"
        echo "        the controls and the other rows cannot be graded at all."
        grep -F "$(echo "$_arm" | cut -c1-4)" "$T/sf" | sed 's/^/          actual:   /'
        fail=1
    fi
done
#  ⚠⚠ SF-0 REWRITTEN 2026-09-16, AND THE OLD ONE COMPARED THE WRONG PAIR. It read
#  the ORIGINAL against the HOLDER -- `addrOf(sfSrc)` against `addrOf(sfFace)` --
#  and concluded from their different bodies that a flag must not cross. But the
#  holder is not the face: the FACE is what the holder POINTS AT, `*sfFace`, and
#  it shares the original's body outright because `+%` attached a copy over it.
#  Rule H13 question 1 -- "is this the same thing, reached through a carrier?" --
#  reads the BODY column, and read correctly it says #2 on both sides.
#  ⚠ THAT WRONG PAIR IS HOW THE PRE-REGISTERED PREDICTION GOT MADE. SF-2 = 1 is
#  the flag crossing LAWFULLY, not noise. F-71's headline was withdrawn on it.
if grep -qE 'ADDROF sfSrc field=#1 body=#2' "$T/sf" \
   && grep -qE 'ADDROF sfFace field=#3 body=#4' "$T/sf" \
   && grep -qE 'ADDROF sfSrc field=#5 body=#2' "$T/sf"; then
    echo "  ok    starFlagT SF-0 original and FACE share body #2; the holder does not -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  starFlagT SF-0 moved. The three rows are the ORIGINAL (#1/#2), the"
    echo "        HOLDER \`<-\` minted (#3/#4), and THE FACE \`*sfFace\` (#5/#2). If the"
    echo "        original and the face STOP sharing a body, SF-2 should stop reading 1"
    echo "        and faceT F2/F3 move with it; neither re-pins without the other."
    grep 'ADDROF sf' "$T/sf" | sed 's/^/          actual:   /'
    fail=1
fi

#  ⚠⚠ roundTripT -- JOINS THE FLEET 2026-09-01 (SEQ 116), AND IT HAD NEVER BEEN
#  IN IT. Born 2026-08-31, it carries the founding measurement of the mechanism
#  table -- which twinning road SHARES a body and which COPIES one -- and nothing
#  pinned it, so it could have gone silently wrong at any point since.
#  ⚠ WHAT IT READS TODAY, and the pre-registration is CONFIRMED: a body flag
#  crosses between two names EXACTLY WHEN THE BODY IS SHARED.
#      ARM A   one node, write then read       1          round trip works
#      ARM C   never written                   0          NOT 1
#      ARM B1  copyOf twin, write twin         0          does NOT cross
#      ARM B2  addGroup twin, write twin       1          DOES cross
#  ⚠ B1 IS NOT A COUNTEREXAMPLE, IT IS THE SAME RULE. copyOf makes its OWN body
#  (which is why Tony's ruling says copyOf is not a "copy of a field" at all), so
#  there is no shared body for the flag to cross through. B1 and B2 differ in the
#  road, not in the law.
#  ⚠⚠ ARM C AND B1 GRADUATED 2026-09-08 (H6), tag echo -> 0, AND THE SENTENCE IS
#  THAT THE FIXTURE ALWAYS SAID SO. Its own want-text reads "MUST be 0, else ARM A
#  asserts nothing", and it had been PASSING on `noPrinT` -- an unset flag had no
#  data and returned its own tag (bear-trap #26). So the anti-vacuity control was
#  VOID: it could not tell "unset" from "unreadable", which is exactly what it
#  exists to tell. Tony's opDot change gives a data-less flag read a real count of
#  0 and bareIfTruth makes aCTionIF answer by truthOf, so the row now reads the 0
#  it always wanted. THIS IS A RE-PIN ONTO THE FIXTURE'S OWN STATED TARGET, not a
#  target moved to chase an output.
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
            "ARM C   r = 0" \
            "ARM B1  original reads 0" \
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
#  ⚠ RE-PINNED 2026-09-07 and the sentence is the ruling: NEWGROUP NO LONGER
#  CARRIES isGROUP. GroupMain.twk:353 adds TraiT as a term with `@` instead of
#  embedding it, so genParse stops refusing NewGroup and PLANS it -- the row goes
#  from `REFUSE rule NewGroup -- rule-level data isGROUP` to a real `SEQ NewGroup
#  / CALL TraiT`. The second hunk is DefinE's blocker moving NewGroup -> Attributes,
#  which is H9's corollary and not a regression: a refusal census names the FIRST
#  blocker, so fixing one reveals the next. Two hunks, both explained; anything
#  else in this diff would have been a finding.
#  ⚠ RE-PINNED 2026-09-10 BY RULING, one line: `LITTO {` becomes `CALL leftCurly`. The
#  modifier two-class ruling gives BlocK's leftCurly its noLabel dash, so it stops being a
#  rule-level literal with no rStuff and becomes a term genParse can CALL. This is the
#  same fact the odometer's 24 -> 28 records, seen in the plan rather than in the count --
#  one line moved, and it moved from a literal-emit to a call.
#  ⚠ RE-PINNED 2026-09-14, ONE LINE: NewGroup's `CALL TraiT` moved `at=1` -> `at=2`.
#  planRule walks `while term = rule[i]` and skips noPrint terms from the PLAN but NOT
#  from the INDEX, and NewGroup now carries the noPrint `builtinActoR` at slot [1] --
#  confirmed against oneTest.base's own audit -- so every later term shifts by one.
#  The planner is right about the tree it is looking at; the tree gained an attribute.
#  ⚠ The LATENT hazard this exposes is banked as fixIts F-59: baked `rule[n]` on the
#  live road (ruleActions.rtn aCTionCodE, RuleStuff.twk's seven parseJSON*) shifts the
#  same way, and `GroupItem::get(int)` does not skip noPrint. Not bitten -- no CodE or
#  JSON* rule carries a builtinActoR -- which is also why jsonTest never moved.
#  ⚠⚠ RE-PINNED 2026-09-15 BY RULING, AND IT IS THE 09-10 ROW GOING BACK THE OTHER WAY.
#  `CALL leftCurly` / `CALL rightCurly` become `LITTO { slot=leftCurly` / `LITTO }
#  slot=rightCurly`. The TraiT transport packet came off aCTionTraiT, so leftCurly and
#  rightCurly stop carrying a spent Modifier attribute -- and that attribute was the ONLY
#  reason planTerm's arm 2 (`definer != term` -> CALL) fired on them. Without it they fall
#  to arm 3 and emit a literal.
#  ⚠ THIS IS THE CORRECT ANSWER AND THE PRIOR PIN WAS THE WRONG ONE. `CALL leftCurly`
#  aimed parseR at the phantom master a0524c8 named, which has NO rStuff; a literal is what
#  a literal should emit. The 09-10 note above records the opposite move and is kept as the
#  trail -- read the two together, they are one predicate doing two jobs.
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
#  ⚠⚠ DELIBERATELY NOT RE-PINNED, 2026-09-08, AND THIS IS THE SENTENCE. The row
#  reads [] today and the 09-07 seal expected to re-pin it to [NewGroup]. BOTH
#  ANYtoken AND NewGroup have measurably left the category -- each now classifies
#  `fires=body`, i.e. rStuff->parseMethod == parseRule. That part is real.
#
#  ⚠ BUT THE CENSUS UNDER THIS ROW DOES NOT COVER ITS OWN POPULATION, so [] is
#  not a finding, it is a gap. Measured: Grokking has 66 members and 22 of them
#  produce NO PC and NO PA line at all -- break, continue, return, Operators,
#  Parens, PrinT, PrintField, QuotE, ScopeXP, Search, ShortcuT, Start, StringXP,
#  TokenXP, TraiTdata, UnaryXP, WardeD, WhilE, Xpress, nameSet, loopOnAttributes,
#  loopOnMembers. parseClassify is never CALLED for them.
#
#  ⚠ ONE OF THE MISSING IS ShortcuT, WHICH IS A MEMBER OF THIS VERY PIN. Probed
#  directly from inside an action with := on the member: noPrinT 0, isRulE 1,
#  binTypE 0 -- an ordinary rule that pcWalk's own gates should not skip. So the
#  category could contain ShortcuT and this census would still print [].
#
#  Re-pinning to [] would freeze "no rule is NEVER" over a population that
#  excludes a third of the grammar including a named member of the pin. That is
#  rule H3's regenerated-green failure exactly. The row stays RED and carries its
#  reason; it graduates when the census covers its population.
#  Related and already known: `parseClass.target` is red and the seal recorded
#  its census silently falling 239 -> 66 rows. Same instrument, same disease.
#  ⚠ ALSO NOTED, NOT FIXED: pcWalk gates with `if !isRulE; continue;`, and `!` on
#  a zero-holding field answers false, so that filter skips NOTHING (see the
#  artifactSkipByFlag block above and andProbe AP-5b). It is not the cause of the
#  22 -- noPrinT is the only working gate and ShortcuT reads 0 there -- but it is
#  a filter asserting nothing and it sits in this walk.
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


#  ============================================================================
#  ⚠ traitFlagsT -- JOINS THE FLEET 2026-09-15, carrying incant/fixits/hasTraits
#  out by mapping. It is the BEFORE half of the hasAttributeS/hasTraitS pair:
#  the raw grammar, walked before anything primes it. connectiveT above is the
#  AFTER half. One instrument each, and neither duplicates the other.
#
#  ⚠⚠ RE-PINNED 2026-09-15, 5 -> 2, AND THE PACKET QUESTION IS CLOSED. Tony ruled
#  the TraiT transport packet off aCTionTraiT the same day this row was minted.
#  TF-2 52 -> 49 and TF-6 34 -> 37: ANYstring, leftCurly and rightCurly carried
#  the packet as their ONLY attribute, so removing it leaves them with no
#  attributes at all and both flags read 0 -- agreement.
#
#  ⚠⚠ THE TWO SURVIVORS ARE A DIFFERENT CAUSE AND WERE NAMED BEFORE THE BUILD.
#  ShortcuT and StatemenT disagree because their only attribute is `builtinActoR`,
#  which setActions publishes noPrint on every rule with a dlsym-able action.
#  A rule whose attributes are ALL noPrint reads hasAttributeS 1 / hasTraitS 0
#  whatever the packet does -- measured per attribute, with affiliation:
#      ShortcuT    builtinActoR/nP=1/attr=1
#      StatemenT   builtinActoR/nP=1/attr=1, then SemI BlocK WardeD Iterate
#                  Xpress -- all attr=0, MEMBERS, which cannot carry a trait
#  ⚠ SO ShortcuT CARRIED THE PACKET AND NEVER DISAGREED BECAUSE OF IT: it had two
#  noPrint attributes and now has one. Four rules carried the packet; only three
#  ever disagreed because of it.
#
#  ⚠ TF-5 MOVING IS STILL NEWS EITHER WAY. Down to 0 means something took
#  builtinActoR off, or hasTraits learned to ignore it. Up means a new population
#  joined. Re-pin only with a sentence saying which (rule H6).
#
#  ⚠ TF-4 IS THE ANTI-VACUITY SIBLING and is not decoration -- a walk that read
#  nothing prints a count too. TF-4 at 47 is non-zero on the same walk, so the
#  pair tells "they disagree on two" from "nothing was measured" (rule H4).
#
#  ⚠ TF-7 PINS THE NAMES, not just the count, and it is the row that survives a
#  renumbering: a count says something moved, the names say WHAT.
run1 traitFlagsT "$T/tf"; check "traitFlagsT runs" 0 $?
sentinel "traitFlagsT sentinel (no truncation)" "$T/tf" "TRAITFLAGS SENTINEL"
for _arm in "TF-1 rules seen                   =  86" \
            "TF-2 carrying hasAttributeS       =  49" \
            "TF-3 carrying hasTraitS           =  47" \
            "TF-4 carrying BOTH                =  47" \
            "TF-6 no attributes                =  37" \
            "TF-5 the two flags DISAGREE on    =  2"; do
    if grep -qF "$_arm" "$T/tf"; then
        echo "  ok    traitFlagsT ${_arm} -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  traitFlagsT $_arm -- MOVED. TF-5 is the TraiT packet"
        echo "        population and moving is news either way; re-pin with a"
        echo "        sentence saying which direction and why (H6)."
        grep -F "$(echo "$_arm" | cut -c1-4)" "$T/tf" | sed 's/^/          actual:   /'
        fail=1
    fi
done
for _rule in ShortcuT StatemenT; do
    if grep -qE "^	${_rule}  " "$T/tf"; then
        echo "  ok    traitFlagsT TF-7 names ${_rule} -- PRESENCE WITH VALUE"; green=$((green+1))
    else
        echo "  FAIL  traitFlagsT TF-7 no longer names ${_rule}"; fail=1
    fi
done

#  ============================================================================
#  ⚠ danglingE -- JOINS THE FLEET 2026-09-15, carrying incant/fixits/danglingElse
#  out by mapping. KANT parses an unbraced multi-statement if-arm followed by an
#  else, and the else FIRES.
#
#  ⚠⚠ IT PINS THE OPPOSITE OF WHAT BEAR-TRAP 32 SAYS, ON PURPOSE. The trap names
#  this shape as fatal, and on the TOK road it is -- canary 0 against a braced
#  control's 319, measured 2026-09-10. On the KANT road the discriminator is
#  BACKWARDS: the brace is the trigger, not the cure. The trap carries that
#  amendment; this is the standing measurement underneath it, so an inversion
#  back is visible rather than argued about.
#
#  ⚠ NEITHER ROW ALONE CAN SEE THE DEFECT. A parse that swallowed the else would
#  print no error and leave a plausible number -- deN keeping its initialiser. So
#  DE-1 takes the then-arm and DE-2 takes the else, and a 5 in DE-2 is the
#  initialiser showing through, which is exactly what a dropped else looks like.
run1 danglingE "$T/de"; check "danglingE runs" 0 $?
sentinel "danglingE sentinel (no truncation)" "$T/de" "DANGLINGE SENTINEL"
for _arm in "DE-1 unbraced arm, flag TRUE   deN =  2" \
            "DE-2 unbraced arm, flag FALSE  deN =  9"; do
    if grep -qF "$_arm" "$T/de"; then
        echo "  ok    danglingE ${_arm} -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  danglingE $_arm -- MOVED. A 5 in DE-2 is the else being"
        echo "        DROPPED; anything else means kant's if/else shape changed."
        grep -F "$(echo "$_arm" | cut -c1-4)" "$T/de" | sed 's/^/          actual:   /'
        fail=1
    fi
done

#  ⚠ debugAllT -- `debug ALL <rule>` MARKS THE RULE'S WHOLE SUBTREE, AND THE MARK
#  IS PER-WALK. New 2026-09-18 with GroupItem::setDebug(). `ALL` is TEXT matched
#  inside aCTionDEBUG exactly as GUARD is; the grammar has never heard of either.
#
#  ⚠ THE ROWS READ A COUNT, NOT THE FLAGS, AND THAT IS THE BETTER INSTRUMENT.
#  There is no kant accessor for `debugged` -- it is a GroupBody flag with no
#  GroupFields entry -- so the marks cannot be read directly. setDebug returns
#  how many nodes it marked and aCTionDEBUG prints that unconditionally (H4), so
#  the number moves only when the WALK moves. A flag read would say one node was
#  marked; the count says the whole walk happened.
#
#  ⚠⚠ H7 CONTROL, RUN 2026-09-18, TWO BUILDS: setDebug with its clearDebug() call
#  REMOVED -- which is how the method was first written -- takes FIVE of the six
#  rows red:
#        row    with the clear pass    without
#        DB-1          2                  2
#        DB-2          4                  1
#        DB-3          6                  1
#        DB-4          6                  0
#        DB-5          6                  0
#  Using `debugged` as its own visited mark is per-PROCESS, so a component marked
#  by an EARLIER command stops the next walk dead at that node. It bites across
#  two consecutive commands, not merely across two sessions -- DB-2 is already
#  wrong on its first use, because DB-1 marked the shared body one line earlier.
#  That is parseWalked's own over-refusal at a new seat, and the clear pass is
#  what makes every walk start from the same place.
#
#  ⚠ DB-1..DB-3 ARE A LADDER, NOT THREE SAMPLES. dbgLeaf is flat, dbgMid holds a
#  reference to dbgLeaf, dbgTop one to dbgMid, so the counts MUST increase -- a
#  walk that stopped at depth 1 reads the same number three times and a
#  presence-only check could not tell the difference.
_dbcount () {                   # _dbcount <row-label> -> the count that row printed
    awk -v r="=== $1 " 'index($0,r){f=1;next} f&&/debug ALL marked/{print $4; exit}' "$T/dba"
}
run1 debugAllT "$T/dba"; check "debugAllT runs" 0 $?
sentinel "debugAllT sentinel (no truncation)" "$T/dba" "DEBUGALLT SENTINEL"
for _row in "DB-1 2 flat rule" "DB-2 4 one level down" "DB-3 6 two levels down" \
            "DB-4 6 an OUTSIDE mark must not truncate" \
            "DB-5 6 the walk's own leftovers must not either"; do
    _lbl=${_row%% *}; _rest=${_row#* }; _want=${_rest%% *}; _what=${_rest#* }
    _got=$(_dbcount "$_lbl")
    if [ "$_got" = "$_want" ]; then
        echo "  ok    debugAllT $_lbl marked $_got -- $_what"; green=$((green+1))
    else
        echo "  FAIL  debugAllT $_lbl marked '$_got', wants $_want -- $_what"
        echo "        A SMALLER number is the walk truncating: setDebug's clear pass"
        echo "        is gone or an earlier mark survived into this walk. An EMPTY"
        echo "        value means the row printed no count at all."
        fail=1
    fi
done
if grep -qF "debug ALL names no rules" "$T/dba"; then
    echo "  ok    debugAllT DB-6 \`debug ALL;\` naming no rules REFUSES by name"; green=$((green+1))
else
    echo "  FAIL  debugAllT DB-6 -- \`debug ALL;\` no longer refuses. A spelling that"
    echo "        parses and does nothing is the failure this refusal exists to prevent."
    fail=1
fi

#  ⚠⚠ searchNewParseT -- TONY'S 2026-09-14 ACCEPTANCE AS A ROW, and the graduation
#  of F-90. `parser(Search)` then `Search("search list;")` under traceParse must
#  show the GENERATED body dispatching its terms. It passed at 5f24cf3 and read
#  ZERO term dispatches from 9785324 until the repair landed 2026-09-18.
#
#  ⚠ THE MARKER'S POSITION IS THE INSTRUMENT. The bisect's first probe counted
#  from AHEAD of parser(Search), so the GENERATION walk's own dispatches fell in
#  the window and it reported PASS AT BOTH ENDS -- it would have ended the bisect
#  before it began. The fixture prints its marker after generation and immediately
#  before the drive, and these rows count only what follows it.
#
#  ⚠ SNP-0 IS THE KNOWN-GOOD END (rule H16) AND IS GREEN IN BOTH STATES ON PURPOSE.
#  `Search` dispatches whether or not its generated body runs, so it separates "the
#  trace is silent" from "the terms did not fire" -- without it, a dead instrument
#  and a broken parse are the same reading.
#
#  ⚠ FOUR TERMS, NOT THREE. `Search  search- followedBy GrouP+ SemI-` has four, and
#  `followedBy` is one of them. F-90's certificate says three; that number came from
#  a differently-filtered probe and is not re-cited here.
_snprow () {                    # _snprow <tag> -> the RULEDISPATCH line for it, after the marker
    awk -v t=" $1 " '/SNP MARKER/{f=1;next} f&&/RULEDISPATCH/&&index($0,"RULEDISPATCH"t){print;exit}' "$T/snp"
}
run1 searchNewParseT "$T/snp"; check "searchNewParseT runs" 0 $?
sentinel "searchNewParseT sentinel (no truncation)" "$T/snp" "SEARCHNEWPARSET SENTINEL"
if _snprow Search | grep -q "isRule=1"; then
    echo "  ok    searchNewParseT SNP-0 the drive itself dispatched -- the known-good end"; green=$((green+1))
else
    echo "  FAIL  searchNewParseT SNP-0 -- Search itself never dispatched, so the trace is"
    echo "        DEAD and every row below it is uninterpretable, not merely red."
    fail=1
fi
for _t in search followedBy GrouP SemI; do
    if _snprow "$_t" | grep -q "isRule=1"; then
        echo "  ok    searchNewParseT SNP term \`$_t\` dispatched, isRule=1"; green=$((green+1))
    else
        echo "  FAIL  searchNewParseT SNP term \`$_t\` did NOT dispatch -- F-90 is back."
        echo "        The generated body is not running: setParse installed nothing, or"
        echo "        something raised hasNewParse before the walk reached it."
        _snprow "$_t" | sed 's/^/          actual:   /'
        fail=1
    fi
done

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
#  ⚠ RE-PINNED 10 -> 12, 2026-09-08, and the sentence is that the grammar gained
#  EXACTLY TWO PUNCTUATION FIELDS by Tony's ruling: ColoN and EquaL, minted in
#  GroupMain's bootstrap so that literal attributes carry a LABEL for parse
#  generation. Both are isRule with no rStuff -- the lawful bare-master signature
#  this row exists to count -- and they join six siblings of identical shape
#  (leftBrace, leftCurly, leftParen, rightBrace, rightCurly, rightParen) that were
#  already there. TWO ENTERED, NONE LEFT, and the two are named in oneTest's own
#  AUDIT MISSRULE lines, so the arithmetic is checkable rather than asserted.
#  â  RE-PINNED 12 -> 8, 2026-09-10, and the sentence is that FOUR PHANTOM
#  BARE MASTERS LEFT THE POPULATION when the noLabel dash was respelled onto the
#  TRAIT rather than onto its DATA -- `leftBrace-="["` in place of
#  `leftBrace="["-`. In the old spelling the dash reached aCTionTraiTdata, which
#  modifies the DatA node, and aCTionTraiT then setContent's that node onto the
#  trait -- and setContent does not carry flags (bear-trap #1/#2), so the dash was
#  silently dropped and the term was minted as a labelled rule with no rStuff.
#  The four that left are leftBrace, leftParen, rightBrace, rightParen, from the
#  Braced and Parens lines of incant/grammar. FOUR LEFT, NONE ENTERED, and the
#  four are named by their vanished oneTest AUDIT MISSRULE lines, so the
#  arithmetic is checkable here too.
#  â  leftCurly and rightCurly are STILL IN THE COUNT ON PURPOSE. BlocK carries
#  the same respell and it is HELD -- it alone regresses iterT1/iterT1m (7 visits
#  -> 5). When BlocK lands this row goes 8 -> 6 and that will be its own sentence.
#  ⚠ RE-PINNED 2026-09-10 BY RULING: leftCurly and rightCurly LEAVE. The modifier
#  two-class ruling makes BlocK's noLabel dash reach the trait, so the two curlies stop
#  being minted as labelled rules with no rStuff. Tony's words: "leftCurly and rightCurly
#  must not appear as attributes in the new parse, and the hand-up made the grammar say
#  so." TWO LEFT, NONE ENTERED, and they are named by their vanished MISSRULE lines.
AUDITLINE="AUDIT all registries: 6 missing rules, 0 missing terms, 4 loose, 0 unconsumed"
if grep -qF "$AUDITLINE" "$T/one"; then
    echo "  ok    bare-master population AT PIN (isRule without rStuff = 6, loose = 4)"; green=$((green+1))
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
    echo "        not a repair: "$(ip bisectQ)" and every emitter copy depend on it."; fail=1
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
#  ⚠ storeT -- THE WRITERS CENSUS. AN ARMED STATEMENT STORES NOTHING.
#  Tony ruled it 2026-09-05; opAssign was the first writer taught to consult the
#  arm and this is the census that found the other thirteen. Eleven are
#  certified here, one row each, same shape: a target holding a DISTINCT value
#  and one statement whose right-hand side refuses before the write.
#
#  ⚠ THE ELEVEN STARTING VALUES ARE ALL DIFFERENT (101..111) AND THAT IS THE
#  ANTI-VACUITY. A row wanting 0, or wanting its neighbour's number, could be
#  satisfied by a field never written or by a write that landed on the wrong
#  field. A distinct non-zero value can only be there because THAT field was
#  left alone.
#
#  ⚠ H7 CONTROL RUN, NOT CLAIMED: opSetGroup's consult removed and rebuilt makes
#  the `:=` row read `swSetGroup` -- the tag echo of a BLANKED field -- and
#  restoring it returns 102. So these rows are not vacuous: without the consult
#  the writer genuinely destroys its target.
#
#  ⚠ ++ AND -- ARE NOT CERTIFIED AND THE REASON IS STRUCTURAL. They are UNARY:
#  nothing to their left in a statement can arm before they write, so one
#  statement cannot both raise a refusal and reach them. They carry the consult
#  in source; this file cannot exercise it, and saying so beats a row that looks
#  like a test and is not.
#  ⚠ THE ip LOOKUP MUST NEVER BE THE THING THAT PICKS A FILE. Fixtures live in four
#  directories now and the harnesses resolve a NAME, trying incant, incant/pop,
#  incant/pop/jit, incant/fixits in that order. That is only safe while the name is
#  UNIQUE: two files sharing one name would make the ORDER load-bearing, and the row
#  would silently start certifying whichever copy happened to sort first. This row
#  asserts the precondition rather than trusting the layout to stay tidy.
_dup=$(for _d in incant incant/pop incant/pop/jit incant/fixits; do
           [ -d "$_d" ] && ls -p "$_d" 2>/dev/null | grep -v / ; done | sort | uniq -d)
_names=$(for _d in incant incant/pop incant/pop/jit incant/fixits; do
           [ -d "$_d" ] && ls -p "$_d" 2>/dev/null | grep -v / ; done | sort -u | wc -l | tr -d ' ')
if [ -z "$_dup" ]; then
    echo "  ok    fixture names unique across the four incant directories ($_names names)"; green=$((green+1))
else
    echo "  FAIL  fixture name collision -- ip's lookup ORDER is picking the file:"
    printf '        %s\n' $_dup
    echo "        Rename one, or the row above it is certifying an unknown copy."; fail=1
fi

#  ⚠ memberLitT -- +/ REFUSES A LITERAL RIGHT SIDE, by presence rather than by kind.
#  ML-1 is the anti-vacuity control: the same operator with a FIELD on the right must
#  still attach, or the refusal is equally consistent with +/ being broken. ML-3 reads
#  the length from a LATER action, because a refusal is terminal for the action and the
#  line after the refused statement never runs.
run2 memberLitT "$T/ml.o" "$T/ml.e"; check "memberLitT runs" 0 $?
sentinel "memberLitT sentinel (no truncation)" "$T/ml.e" "MEMBERLIT SENTINEL"
if grep -qF "ML-1 length =  1" "$T/ml.e"; then
    echo "  ok    memberLitT ML-1 +/ a FIELD still attaches -- 1 (anti-vacuity control)"; green=$((green+1))
else
    echo "  FAIL  memberLitT ML-1 -- +/ stopped attaching a field; the refusal is over-firing"; fail=1
fi
if grep -qF "Operator +/ -- the right side is a literal" "$T/ml.e"; then
    echo "  ok    memberLitT ML-2 a literal right side refuses BY NAME"; green=$((green+1))
else
    echo "  FAIL  memberLitT ML-2 -- a literal was accepted as a member, or the refusal lost its name"; fail=1
fi
if grep -qF "ML-3 length AFTER the refusal =  1" "$T/ml.e"; then
    echo "  ok    memberLitT ML-3 nothing was attached -- read from a later action"; green=$((green+1))
else
    echo "  FAIL  memberLitT ML-3 -- the list moved despite the refusal"; fail=1
fi

#  ⚠ testPrecedence -- THE PRECEDENCE MAP, and its row is a RATCHET rather than a pin.
#  Thirty-six rows: six target shapes x six operators. The tracked number is the count of
#  rows NOT YET TRUE, and it is meant to go DOWN -- a stroke that makes a spelling work
#  lowers it. So this row goes red only if the count RISES, and prints the number either
#  way (rule H4: the quantity is printed unconditionally and compared, never asserted by
#  the absence of a line). When it falls, lower TPWANT in the same commit with a sentence
#  naming which rows graduated -- that is rule H6, and a ratchet that is never tightened
#  is just a pin that stopped meaning anything.
#  ⚠⚠ RE-BASELINED 12 -> 8 ON 2026-09-15, AND IT IS NOT FOUR GRADUATIONS. The fixture's
#  per-row marker had collapsed into ONE shared latch, so every row after the first success
#  counted true and tpTrue outran tpRows: the printed number was -8 of 27 against 35 real
#  rows. Repairing it changed BOTH the numerator and the denominator -- rows counted went
#  33 -> 35 when the two inverted rows started minting a marker of their own -- so 8 is a
#  reading on a repaired instrument and NOT a distance travelled from 12. Nothing graduated.
#  The eight still pending, named so the next move is checkable: addAttrDot, addAttrStarsub,
#  addAttrSub, addMemberDot, addMemberSub, minusMinusStar, plusPlusStar, plusPlusStarsub.
#  ⚠ THE TWO CHANNELS NOW AGREE -- eight markers printed and eight counted. They did not
#  before: the two INVERTED rows (absentBump, absentStep) count themselves true on a refusal
#  and never set their own marker, so they showed as pending while counting as true. They
#  now mark their slot where they bump the counter, and marker-count and counter say 8 each.
TPWANT=8
run2 testPrecedence "$T/tp.o" "$T/tp.e"; check "testPrecedence runs" 0 $?
sentinel "testPrecedence sentinel (no truncation)" "$T/tp.e" "PRECEDENCE SENTINEL"
#  ⚠ THE EXTRACTOR READS A LEADING MINUS, AND A NEGATIVE COUNT IS LOUD. It used to strip
#  with `s/[^0-9].*//`, which CANNOT PARSE A MINUS SIGN: a `-8` came back as the EMPTY
#  STRING, so the row reported "the map ran but said nothing" -- an instrument reporting
#  SILENCE for the one reading that most needed saying. The count went negative because the
#  fixture's per-row marker had collapsed into a shared latch, so tpTrue outran tpRows; that
#  is fixed in the fixture, and this is the half that makes the next occurrence audible.
_tpn=$(sed -n 's/.*PRECEDENCE ROWS NOT YET TRUE = *//p' "$T/tp.e" | sed 's/[^-0-9].*//' | head -1)
#  the TOTAL is read from the fixture too -- a hardcoded one goes stale the first time a
#  row is added, and then the row reports a true count against a false denominator
_tpt=$(sed -n 's/.*PRECEDENCE ROWS NOT YET TRUE = *-*[0-9]* of *//p' "$T/tp.e" | sed 's/[^-0-9].*//' | head -1)
if [ -z "$_tpn" ]; then
    echo "  FAIL  testPrecedence reported no count -- the map ran but said nothing"; fail=1
elif [ "$_tpn" -lt 0 ]; then
    echo "  FAIL  testPrecedence reported a NEGATIVE count: $_tpn of $_tpt"
    echo "        tpTrue has outrun tpRows, which means the per-row markers are sharing a"
    echo "        slot again -- the number is printed rather than swallowed, on purpose."; fail=1
elif [ "$_tpn" -le "$TPWANT" ]; then
    echo "  ok    testPrecedence $_tpn of $_tpt rows not yet true (ratchet: $TPWANT)"; green=$((green+1))
    if [ "$_tpn" -lt "$TPWANT" ]; then
        echo "        ^ it went DOWN. Lower TPWANT to $_tpn and name the rows that graduated (H6)."
    fi
else
    echo "  FAIL  testPrecedence $_tpn of $_tpt not yet true, was $TPWANT -- a spelling that worked"
    echo "        has stopped working. The pending slugs are listed above the count."; fail=1
fi

#  ⚠ opRoadT -- THE UNKNOWN-OPERATOR REFUSAL. A token registered in Operators with
#  no operateMethod fell through every arm of runOP's chain and returned null: the
#  statement parsed, changed nothing, said nothing. Four measured casualties before
#  the gate landed 2026-09-11 (eq, &&, AND, +/), ten tokens in that state.
#
#  THE ROWS ARE ORDERED BY WHAT THEY DISCRIMINATE, not by what they assert.
#  ROAD-A is the anti-vacuity sibling: a registered operator in the identical shape
#  must still move the length to 1, or the refusal below is equally consistent with a
#  broken fixture. The refusal row greps the TOKEN NAME, never the bare word REFUSED --
#  a gate that refused everything would satisfy a bare check and would be catastrophic.
#  ROAD-C asserts an ABSENCE on purpose and is the one place here that may: a refusal is
#  terminal for the unit, and if the statement after a refused one ever runs, the refusal
#  has silently become a warning. It is paired with ROAD-B's presence so it cannot pass
#  by the fixture failing to reach the subject.
#
#  `<<` IS THE STANDING NEGATIVE CONTROL and must stay methodless. `+/` gains a road in
#  the store-operator fold and stops refusing by design; this row is what keeps the gate
#  honest afterwards. Re-pointing it at another methodless token wants a sentence (H6).
run1 opRoadT "$T/ord"; check "opRoadT runs" 0 $?
if grep -qF "ROAD-A registered +% len =  1" "$T/ord"; then
    echo "  ok    opRoadT ROAD-A registered +% still stores -- 1 (anti-vacuity sibling)"; green=$((green+1))
else
    echo "  FAIL  opRoadT ROAD-A -- a REGISTERED operator stopped storing; the gate is over-firing"; fail=1
fi
if grep -qF "ROAD-B reached" "$T/ord"; then
    echo "  ok    opRoadT ROAD-B the methodless token was reached"; green=$((green+1))
else
    echo "  FAIL  opRoadT ROAD-B missing -- the fixture never reached its subject"; fail=1
fi
if grep -qF "operator '<<' has no road" "$T/ord"; then
    echo "  ok    opRoadT '<<' refuses BY NAME -- a methodless operator cannot be silent"; green=$((green+1))
else
    echo "  FAIL  opRoadT '<<' did not refuse by name -- the unknown-operator gate is GONE,"
    echo "        and every methodless token is silently changing nothing again."; fail=1
fi
if grep -qF "ROAD-C" "$T/ord"; then
    echo "  FAIL  opRoadT ROAD-C ran -- the refusal is no longer TERMINAL for the unit"; fail=1
else
    echo "  ok    opRoadT ROAD-C absent -- the refusal is terminal (paired with ROAD-B)"; green=$((green+1))
fi

run1 storeT "$T/stw"; check "storeT runs" 0 $?
sentinel "storeT sentinel (no truncation)" "$T/stw" "STORET SENTINEL"
_swn=0
for _w in "=  101" ":=  102" "<-  103" "<:  104" "+=  105" "-=  106" "*=  107" "/=  108" "+%  109" ":+  110" ":%  111"; do
    if grep -qF "SW $_w (want" "$T/stw"; then _swn=$((_swn+1)); fi
done
if [ "$_swn" = 11 ]; then
    echo "  ok    storeT all 11 writers consult the arm -- targets UNCHANGED -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  storeT $_swn of 11 writers left their target alone -- a writer stopped"
    echo "        consulting the arm and is blanking its target on a refused rhs."; fail=1
fi

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
#  ---- opIN's three arms, and the directives buffer arm ----------------------
#  Minted 2026-09-08 with the opIN reorder (groupList arm moved to the FRONT).
#  `X IN Y` calls opIN with argument=Y (CONTAINER) and target=X (NEEDLE); the arms
#  are tried in order and FIRST MATCH WINS, so the order is load-bearing and two
#  of the three arms had no cover at all until now.
#
#  ⚠ IA-G3 IS THE ROW THIS BLOCK EXISTS FOR. Before the reorder it read 1: a
#  registry carries BOTH a character set and a group list, the isSET arm matched
#  first, and `set.foundIn(target.text)` on a data-less field gets that field's
#  own TAG back (bear-trap #26) -- so a character-set test was being handed a
#  name and answered true for everything, including a field declared in the
#  fixture's own define block. Any census built on IN was unmeasurable.
#
#  ⚠ EVERY ZERO ROW HERE HAS A NON-ZERO SIBLING. S2 pairs with S1, G3 with G1/G2.
#  A row that only ever wants 0 cannot tell "answered false" from "answered
#  nothing".
run1 inArmsT "$T/ia"; check "inArmsT runs (opIN arms)" 0 $?
sentinel "inArmsT sentinel (no truncation)" "$T/ia" "INARMST SENTINEL"
for _r in "IA-S1 set arm, valid name   = 1|IA-S1 setArm  plain-name  =  1" \
          "IA-S2 set arm, has spaces   = 0|IA-S2 setArm  has-spaces  =  0" \
          "IA-G1 list arm, top level   = 1|IA-G1 listArm top-level   =  1" \
          "IA-G2 list arm, DESCENDS    = 1|IA-G2 listArm deep        =  1" \
          "IA-G3 list arm, absent      = 0|IA-G3 listArm absent      =  0"; do
    _lbl=${_r%%|*}; _want=${_r##*|}
    if grep -qF "$_want" "$T/ia"; then
        echo "  ok    inArmsT $_lbl -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  inArmsT $_lbl -- MOVED. opIN's arm order or firstComponent"
        echo "        changed. G3 back to 1 means the isSET arm is shadowing the"
        echo "        lookup again and every IN answer is true."; fail=1
    fi
done

#  THE BUFFER ARM, gated through incant/directives, which is the only live
#  customer of it (replaceAt: `if fromThis IN source;` where source is a buffer).
#  ⚠ IT IS GATED HERE BECAUSE THE FLEET COULD NOT SEE IT. directives is not a
#  fleet citizen and has no sentinel of its own, so the opIN reorder was checked
#  against it BY HAND. This row makes that hand-check standing (H12: a green
#  fleet is evidence only about what the fleet reads).
#  ⚠ SAFE TO RUN: measured 2026-09-08 -- it mutates no tracked file and its
#  output is byte-identical across consecutive runs.
#  ⚠⚠ ROWS 2 AND 3 GRADUATED 2026-09-15 (H6), AND THEIR OLD PINS ARE THE
#  SENTENCE THIS RULE ASKS FOR. Row 2 pinned "Did not find matchOnThis: in
#  source" as a pre-existing defect; row 3 pinned "toThis        print x:;" as
#  its anti-vacuity sibling -- and that pinned value WAS the bug, because the
#  literal string `toThis` is what got written instead of toThis's value
#  (bear-trap #26's tag echo). Both had ONE cause: replaceAt and insertAt read
#  the hoisted local directly, and the `:argument` hoist makes a HOLDER, whose
#  later reads spell `*name` (bear-trap #50). Three stars fixed both.
#  The rows now pin the edits the fixture's own header promises.
#  ⚠ ROW 5 IS THE ONE THAT MATTERS FOR GENERATED BATCHES: a directive whose
#  fromThis is absent must write NOTHING. It used to write its toThis at the
#  buffer head, so one stale fromThis silently corrupted the top of the file.
#  getMarkLineAt now ARMS on no-match -- which its own comment said it did not
#  -- and insertAt's activation ends. Asserted BY VALUE (the refusal names
#  itself) and paired with row 6, its anti-vacuity sibling.
#  ⚠ DRIVES incant/pop/dirT, NOT incant/directives. Split 2026-09-15: the
#  actions moved to a DEFINITIONS-ONLY incant/directives that ends in bail(),
#  so it can be include()d by a generated directive file instead of being
#  copy-pasted into one. dirT includes it and owns the samples and the driver.
#  neighbour <file> <payload> <offset> <expected> -- assert the line <offset>
#  away from the one carrying <payload>. This is how "before" and "after" are
#  told apart AT ALL: every row here used to grep only that the payload was
#  PRESENT, and presence is satisfied identically by a payload on either side of
#  its anchor. F-67 sat undetected behind exactly that for as long as the rows
#  existed -- where=before wrote its value, so the row was green, and it wrote it
#  in the wrong place.
#  ⚠ IT PRINTS THE LINE IT FOUND ON A FAILURE, because "not where it should be"
#  without saying where it IS costs the next reader a run.
neighbour () {
    local _f=$1 _pay=$2 _off=$3 _want=$4 _lbl=$5
    local _n=$(grep -n -F -- "$_pay" "$_f" | head -1 | cut -d: -f1)
    if [ -z "$_n" ]; then
        echo "  FAIL  directives $_lbl -- the payload '$_pay' is not in the capture"; fail=1; return
    fi
    local _got=$(sed -n "$((_n+_off))p" "$_f")
    if [ "$_got" = "$_want" ]; then
        echo "  ok    directives $_lbl -- PLACEMENT PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  directives $_lbl -- want the neighbour to read"
        echo "          $_want"
        echo "        got"
        echo "          $_got"; fail=1
    fi
}

run1 dirT "$T/dirv"; check "directives runs (opIN buffer arm)" 0 $?
sentinel "directives sentinel" "$T/dirv" "DIRT SENTINEL"
for _r in "buffer arm reached (replaceAt ran)|Running replaceAt" \
          "replaceAt REPLACED its match|	Stick this in instead" \
          "insertAt where=before DID write its VALUE|print \"Stuck this in before\":;" \
          "insertAt where=after DID write its VALUE|print \"Stuck this in after\":;"; do
    _lbl=${_r%%|*}; _want=${_r##*|}
    if grep -qF "$_want" "$T/dirv"; then
        echo "  ok    directives $_lbl -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  directives $_lbl -- MOVED. The buffer arm of opIN is the"
        echo "        suspect; it is the arm the 2026-09-08 reorder moved past."; fail=1
    fi
done
#  THE MISS PAIR. Row A is presence-with-value on the REFUSAL (H4: the miss
#  announces itself by name, so deleting the guard cannot satisfy this row).
#  Row B is its anti-vacuity sibling -- a mechanism that inserted nothing at all
#  would pass row A for the wrong reason.
if grep -qF "getLine: no line in the buffer contains the match text" "$T/dirv"; then
    echo "  ok    directives a MISS refuses BY NAME -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  directives a miss no longer refuses by name. getMarkLineAt's"
    echo "        no-match arm is the suspect; without it a stale fromThis"
    echo "        writes at the buffer head instead of doing nothing."; fail=1
fi
if grep -qF "MISS-MUST-NOT-APPEAR" "$T/dirv"; then
    echo "  FAIL  directives a MISS WROTE ITS PAYLOAD -- the buffer was corrupted"
    echo "        at the head. This is the 2026-09-15 defect returning."; fail=1
else
    echo "  ok    directives a miss wrote nothing (paired with the row above)"; green=$((green+1))
fi

#  ---- dotChainT: what each dot spelling reads --------------------------------
#  Built 2026-09-16 with the chain fold. The tree is seeded with REAL VALUES --
#  dcMid=MIDVAL, dcLeaf=LEAFVAL -- so a row that reaches its node answers with a
#  VALUE while a row that merely reaches a data-less node answers with a TAG, and
#  the two are told apart on sight rather than by trust.
#  ⚠ DC-2 AND DC-4 ARE THE FOLD. Before it they read `xl1` -- interpretXP's
#  juxtaposition accumulator -- because the trailing `.c` parsed as a whole second
#  TokenXP that produced no dot call and simply sat next to the term on its left.
#  ⚠ DC-7 AND DC-8 ARE THE ROWS THAT PROVE THE BARE FORM SURVIVED. They are tag
#  echoes, pinned AS echoes: a leading dot with nothing to its left is unchanged
#  by the fold, and if either ever answers with a value the fold has reached a
#  seam it was ruled to leave alone.
run2 dotChainT "$T/dc.o" "$T/dc.e"; check "dotChainT runs" 0 $?
sentinel "dotChainT sentinel" "$T/dc.o" "DOTCHAIN SENTINEL"
for _r in "DC-1 a.b        = MIDVAL|DC-1 a.b        =  MIDVAL" \
          "DC-2 a.b.c      = LEAFVAL  (THE FOLD)|DC-2 a.b.c      =  LEAFVAL" \
          "DC-3 a[b]       = MIDVAL|DC-3 a[b]       =  MIDVAL" \
          "DC-4 a[b].c     = LEAFVAL  (THE FOLD)|DC-4 a[b].c     =  LEAFVAL" \
          "DC-5 *a.b       = MIDVAL|DC-5 *a.b     =  MIDVAL" \
          "DC-7 .b afterCall stays an ECHO|DC-7 .b afterCall =  dcG" \
          "DC-8 .b noLastREF stays an ECHO|DC-8 .b noLastREF =  dcI"; do
    _lbl=${_r%%|*}; _want=${_r##*|}
    if grep -qF "$_want" "$T/dc.e"; then
        echo "  ok    dotChain $_lbl -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  dotChain $_lbl -- MOVED. Actual:"
        grep -F "${_lbl%% *}" "$T/dc.e" | sed 's/^/          /'; fail=1
    fi
done

#  ---- the CHAIN: four names fold, and the seed is proven first ---------------
#  Built 2026-09-17. `a.b.c.d` read MIDVAL -- depth 2 -- until the fold learned to
#  SPLICE. ⚠ THE PARSE GROUPS DOTS IN PAIRS and that is the whole finding: TokenXP takes
#  ONE leading unary and ONE postfix, so `a.b.c.d` is TWO terms (`a.b` and `.c.d`), not
#  four. The orphan is therefore `.`(c.d), and the old fold WRAPPED it, building
#  `(a.b).(c.d)` and handing opDot a dot node as its right operand. foldDot now pushes the
#  left operand into the INNERMOST-LEFT position instead. docs/dotChain.md has the arms.
#
#  ⚠ DC-S IS THE ROW THAT MAKES DC-A AND DC-B MEAN ANYTHING. The old wrong answer was
#  MIDVAL, which is ALSO what an unseeded dcTwig produces -- so the seed is read stepwise
#  through subscripts, where the answer is not in doubt, before either chain row is read.
if grep -qF "DC-S seed: mid= MIDVAL leaf= LEAFVAL twig= TWIGVAL" "$T/dc.e"; then
    echo "  ok    dotChain DC-S the tree really is four deep -- DC-A/DC-B are not vacuous"; green=$((green+1))
else
    echo "  FAIL  dotChain DC-S seed is wrong, so the two rows below assert NOTHING. Actual:"
    grep -F "DC-S" "$T/dc.e" | sed 's/^/          /'; fail=1
fi
for _r in "DC-A a.b.c.d  = TWIGVAL  (FOUR names)|DC-A a.b.c.d    =  TWIGVAL" \
          "DC-B a[b].c.d = TWIGVAL  (subscript then chain)|DC-B a[b].c.d   =  TWIGVAL"; do
    _lbl=${_r%%|*}; _want=${_r##*|}
    if grep -qF "$_want" "$T/dc.e"; then
        echo "  ok    dotChain $_lbl -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  dotChain $_lbl -- MOVED. A MIDVAL here is the pre-fold answer. Actual:"
        grep -F "${_lbl%% *}" "$T/dc.e" | sed 's/^/          /'; fail=1
    fi
done

#  ---- F-72: a.*b is REFUSED, once, and its value is unchanged ----------------
#  Built 2026-09-17. `a.*b` never reaches opDot as a unary: it parses as TWO
#  terms -- `a` bare and `*b` unary-only, no dot-COMPOSED arm -- and opDot then
#  arrives with a NULL right operand because `*b` on a non-group field yields
#  null by the 09-05 star ruling. opDot's lastREF fixup cannot tell that null
#  from a LEADING dot, so it rewrites BOTH operands and the expression silently
#  becomes `.a`. The refusal therefore sits in interpretXP, where the uxp still
#  carries its operator, and NOT in opDot where the ruling first sited it.
#
#  ⚠ THREE ROWS, AND THE COUNT IS ONE OF THEM. The refusal fires on the
#  EXPRESSION BUILD, not per execution, so a fixture calling dcR9 twice still
#  sees one line. And it must be exactly ONE: the backward walk reaches the arg
#  block once with `op` set and again with `target` set, so a seat placed above
#  the target guard fires TWICE on one expression. That was the first cut, and
#  the count row is what would catch it coming back.
#
#  ⚠ THE VALUE ROW IS NOT REDUNDANT WITH THE REFUSAL ROW. This landing is a
#  DIAGNOSTIC and deliberately changes no value -- `refuse()` proper was NOT used
#  because it raises ruler.refused, which aCTionDefinE's refusalBoundary reads to
#  REMOVE THE DEFINITION FROM THE REGISTRY. Whether a.*b should kill its
#  enclosing define is a ruling nobody has made. The echo row is what will go red
#  the day someone escalates, which is exactly when a human should look.
if grep -qF "REFUSED . -- unary deref on the right of a dot is never seen by opDot" "$T/dc.e"; then
    echo "  ok    dotChain DC-9 a.*b is REFUSED, by message not by absence"; green=$((green+1))
else
    echo "  FAIL  dotChain DC-9 a.*b -- NO REFUSAL. Actual:"
    grep -F "REFUSED" "$T/dc.e" | sed 's/^/          /'; fail=1
fi
_dcn=$(grep -cF "REFUSED . -- unary deref on the right of a dot" "$T/dc.e")
if [ "$_dcn" = 1 ]; then
    echo "  ok    dotChain DC-9 refuses EXACTLY ONCE (seat is inside the target guard)"; green=$((green+1))
else
    echo "  FAIL  dotChain DC-9 refused $_dcn times, want exactly 1 -- a count of 2 means"
    echo "        the seat drifted ABOVE interpretXP's target guard and fires on both"
    echo "        passes of the backward walk"; fail=1
fi
#  ⚠ RE-PINNED 2026-09-17 WITH A SENTENCE (H6), NOT SILENCED. The echo row above
#  predicted its own death -- "the row that goes red the day someone escalates" -- and
#  Tony ruled the escalation the same day. DC-9 no longer prints a value AT ALL:
#  refuse() ends the action, aCTionBlocK breaks, and dcR9's cerr never runs.
#  ⚠ THE COUNT IS HOW THAT IS PINNED, BECAUSE "the line is gone" IS AN ABSENCE AND H4
#  FORBIDS ONE. Eight DC value lines is a VALUE: DC-0,1,2,3,4,5,7,8 present and DC-9
#  absent. Nine would mean the escalation was reverted; seven would mean something
#  ELSE stopped printing, which is a different fact and gets looked at.
_dcv=$(grep -cE "^DC-[0-9]" "$T/dc.e")
if [ "$_dcv" = 8 ]; then
    echo "  ok    dotChain DC-9 ABORTS -- 8 value lines, DC-9 among the missing (escalated)"; green=$((green+1))
else
    echo "  FAIL  dotChain expected 8 DC value lines, got $_dcv -- 9 means the F-72"
    echo "        escalation to refuse() was reverted; fewer means a DIFFERENT row died"
    grep -E "^DC-[0-9]" "$T/dc.e" | sed 's/^/          /'; fail=1
fi

#  ---- parserTest: the LIVE parser incantation's own POP -----------------------
#  Tony, ruled 2026-09-17. IncantForms/WorkingOn/parser became definitions-only so utilities
#  could include it; this is where those definitions are measured, across FOUR roots.
#  ⚠ IT DOES NOT GATHER anyOrNumT's OR trigDO's CALLS, and that is a CORRECTION rather than
#  a shortfall. Those two carry their own COMPLETE FROZEN COPIES of the incantation --
#  generateParse, walkRules, compileRules, parser -- by design; anyOrNumT's header says so
#  in terms. They never called the shared definitions, so there was nothing of theirs to
#  gather. What they needed was for their frozen names to stop COLLIDING with the live
#  ones, which is a rename (aon*/td*), not a move. Their roots are covered here against the
#  LIVE copy, which is NEW coverage rather than relocated coverage.
#  ⚠⚠ NO ROW PINS AN ANSWER, DELIBERATELY. Two of these roots have never run at all -- CASE
#  2 was dead code behind a second stop() in the source file, and the live parser has never
#  been driven at ANYorNum. Pinning a number never produced is inventing a target. What is
#  asserted is that the run REACHES ITS FOOT, by counting markers against the sentinel.
#  ⚠⚠ PT-4 ADDED 2026-09-18 -- STATION 4's ROOT, AND IT COULD NOT BE DRIVEN BEFORE. `list`
#  lives in UnitTests, not Grokking, and `parser` read its root as Grokking[argument.taG],
#  so parser(list) looked up a name absent from that registry and generated for a node called
#  `argument`. The root is now taken BARE. parser(list) generates and compiles.
#  ⚠ PT-4 DOES NOT FIRE `list`, DELIBERATELY: parser(list) followed by testList() SPINS in a
#  file where it is the only case -- 100% CPU, RSS flat, reproduced twice. It completes HERE,
#  after PT-1..PT-3, so the outcome depends on what was generated before it. fixIts F-87.
#  Rule H5: a fixture must not be able to take the suite hostage.
run2 parserTest "$T/ptst.o" "$T/ptst.e"; check "parserTest runs" 0 $?
sentinel "parserTest sentinel" "$T/ptst.e" "PARSERTEST SENTINEL"
_ptn=$(grep -cE "^PT-[0-9]" "$T/ptst.e")
if [ "$_ptn" = 4 ]; then
    echo "  ok    parserTest all 4 roots reached -- Search, DO, ANYorNum, list (no answers pinned)"; green=$((green+1))
else
    echo "  FAIL  parserTest reached $_ptn of 4 roots -- a case died before the next marker."
    echo "        Read WITH the sentinel: a missing sentinel means the last one hung or died."
    grep -E "^PT-" "$T/ptst.e" | sed 's/^/          /'; fail=1
fi

#  ---- skipT: the line-comment rule can be WRITTEN; what it consumes cannot be READ ---
#  The blocker (docs/checkSKIP.md 2a): the two-character line-comment literal kills the define
#  it is written in -- no lexer, so the parser reads it as a comment in its own source and eats
#  the rest of the line, closing quote and semicolon included. The block delimiters are innocent.
#  ⚠ SK-1/SK-2 ARE WHY THE ESCAPE FORM IS PREFERRED AND THEY ARE A MEASUREMENT, NOT A TASTE.
#  The escaped spelling yields ONE term matching both characters; the two-literal spelling yields
#  TWO one-character terms -- and terms are skip points, so a skipper may run between them. That
#  is a DIFFERENT rule wearing the same intent, and it is the one that accepts slash-space-slash.
#  ⚠ SK-5 IS THE WALL: a rule driven standalone has no enclosing activation to take its label, so
#  its terms still read their DEFINITIONS afterwards. fixIts F-83 through a second door; station 6.
run2 skipT "$T/sk.o" "$T/sk.e"; check "skipT runs (SK-4)" 0 $?
sentinel "skipT sentinel" "$T/sk.e" "SKIPT SENTINEL"
if grep -qF "skIn=// a real line comment" "$T/sk.o"; then
    echo "  ok    skipT SK-3 the input really carries a line comment -- anti-vacuity for SK-4"; green=$((green+1))
else
    echo "  FAIL  skipT SK-3 the input lost its comment, so SK-4 asserts nothing"; fail=1
fi
_sk1=$(grep -cF "GrouP=// string" "$T/sk.o")
_sk2=$(grep -cF "GrouP=/ string" "$T/sk.o")
if [ "$_sk1" = 2 ]; then
    echo "  ok    skipT SK-1 escaped spelling = ONE term reading // (twice: before and after)"; green=$((green+1))
else
    echo "  FAIL  skipT SK-1 wanted 2 sightings of a single // term, read $_sk1"; fail=1
fi
if [ "$_sk2" = 2 ]; then
    echo "  ok    skipT SK-2 two-literal spelling = TWO terms of ONE character -- a different rule"; green=$((green+1))
else
    echo "  FAIL  skipT SK-2 wanted 2 single-slash terms in one rule, read $_sk2"; fail=1
fi
#  ⚠ SK-5 IS PINNED AT THE WALL, not at a value we want. The dump of lcEsc is IDENTICAL before
#  and after the drive -- which is what SK-1's count of 2 says -- because the matched data never
#  reaches the terms. When label population lands this row moves and THAT IS THE WIN.
if [ "$(grep -cF "commentBody=" "$T/sk.o")" = 3 ]; then
    echo "  ok    skipT SK-5 terms unchanged across the drive -- PINNED AT THE WALL (F-83)"; green=$((green+1))
else
    echo "  FAIL  skipT SK-5 the term dump MOVED. If matched data now lands, that is the win:"
    echo "        re-pin with a sentence (H6) and take it to F-83."; fail=1
fi

#  ---- carrierT: the parse parks in builtinParseR, the rule keeps its action ---
#  Station 4's landing, 2026-09-18. generateParse used to write the generated parse into the
#  rule's own CodE -- where a rule with a code body keeps its ACTION -- so generating a parse
#  DELETED the action (fixIts F-87). A rule that already carries an action body now gets its
#  parse parked in a noPrint builtinParseR attribute, builtinActoR's shape, CodE untouched.
#  ⚠ TWO OTHER CHANGES LANDED WITH IT, each a one-variable A/B, each load-bearing:
#    walkRules skips noPrint -- CodE reads isRulE=1 AND noPrinT=1, so the isRulE test alone let
#      the walk descend INTO THE ACTION BODY and generate a parse for it.
#    hasNewParse is WITHHELD when the parse parks -- that flag says A PARSE IS INSTALLED AND
#      FIRABLE, not merely that one was generated. Raised over a parked carrier it is a promise
#      nothing keeps: runRule takes the gMethod arm and SPINS. fixIts F-88, closed here.
#      A/B: withheld -> exit 0 and the action fires; raised -> exit 142 on a 45s alarm, no output.
run2 carrierT "$T/ct.o" "$T/ct.e"; check "carrierT runs (CT-6 -- no spin)" 0 $?
sentinel "carrierT sentinel" "$T/ct.e" "CARRIER SENTINEL"
if grep -qF "Processing testList action that runs list rule" "$T/ct.o"; then
    echo "  ok    carrierT CT-1 the driver ran -- anti-vacuity sibling for every row below"; green=$((green+1))
else
    echo "  FAIL  carrierT CT-1 testList did not run, so nothing below asserts anything"; fail=1
fi
for _r in "CT-2 THE ACTION FIRES after parser(list) -- F-87 closed|list tests the for statement:|o" \
          "CT-3 sumGrup still in list CodE -- the action BODY survived, by its own local|sumGrup|o" \
          "CT-4 builtinParseR is ON the rule -- the parse was parked, not discarded|builtinParseR        attribute  noPrint|o"; do
    _lbl=${_r%%|*}; _rest=${_r#*|}; _want=${_rest%|*}
    if grep -qF "$_want" "$T/ct.o"; then
        echo "  ok    carrierT $_lbl"; green=$((green+1))
    else
        echo "  FAIL  carrierT $_lbl -- MOVED. Wanted: $_want"; fail=1
    fi
done
#  ⚠ CT-5 IS PINNED WRONG ON PURPOSE (H7's other half) -- fixIts F-83, STATION 6's target and
#  UNRULED. The body runs and CANNOT SEE WHAT WAS PARSED: `entries` still holds its term
#  definition, so the for loop dies. When label population lands this row goes red and THAT IS
#  THE WIN. ⚠ It is also what proves CT-2 reached the loop rather than stopping at statement one.
if grep -qF "nextGroup: ERROR DatA does not contain a list" "$T/ct.e"; then
    echo "  ok    carrierT CT-5 the body still cannot see its terms -- PINNED WRONG (F-83)"; green=$((green+1))
else
    echo "  FAIL  carrierT CT-5 the label gap is GONE. If label population landed, that is"
    echo "        the win: re-pin with a sentence (H6) and close F-83."; fail=1
fi

#  ---- firstUseT: runRule GATES on hasNewParse and never installs --------------
#  ⚠⚠ RE-PINNED 2026-09-18 AS A WITHDRAWAL, NOT A REGRESSION. Tony withdrew the 2026-09-17
#  first-use install: runRule was compiling and installing a rule's parse on first use, and
#  that is GENERATION HAPPENING INSIDE THE GATE. Generation is explicit, through `parser`;
#  runRule only asks whether it already happened. docs/fixIts.md F-83 ruling 2.
#  ⚠ THE ROWS ASSERT THE CELL THE WITHDRAWN INSTALL USED TO FORK ON, by value and never by
#  absence (H4): after driving `list`, isCodeD reads 1 and hasNewParsE reads 0.
#  FU-2 is the NON-ZERO SIBLING for FU-2b's zero and FU-2c is the miss control, so neither
#  zero can be a lookup that quietly found nothing.
#  ⚠ FU-3 RETIRED WITH ITS SUBJECT. It pinned F-83's label gap, reachable only after the
#  rule's body fires; with the install withdrawn the body does not fire. F-83's second half
#  is unchanged in docs/fixIts.md and the row returns when explicit generation reaches list.
#  ⚠ THE READS NAME UnitTests BECAUSE THAT IS WHERE `list` LIVES -- Grokking["list"] reads
#  0 and UnitTests["list"] reads 1, measured 2026-09-18. Tony's seal-day suspicion, confirmed.
run2 firstUseT "$T/fu.o" "$T/fu.e"; check "firstUseT runs" 0 $?
sentinel "firstUseT sentinel" "$T/fu.e" "FIRSTUSE SENTINEL"
if grep -qF "Processing testList action that runs list rule" "$T/fu.o"; then
    echo "  ok    firstUseT FU-1 the driver ran -- the anti-vacuity sibling for every row below"; green=$((green+1))
else
    echo "  FAIL  firstUseT FU-1 testList did not run, so nothing below asserts anything"; fail=1
fi
for _r in "FU-2  isCodeD 1 -- the flag read reaches a real node (non-zero sibling)|FU-2  list isCodeD        =  1" \
          "FU-2b hasNewParsE 0 -- DRIVING THE RULE INSTALLED NO PARSE|FU-2b list hasNewParsE    =  0" \
          "FU-2c miss control 0 -- FU-2b's zero is not a lookup that found nothing|FU-2c miss control isCodeD=  0"; do
    _lbl=${_r%%|*}; _want=${_r##*|}
    if grep -qF "$_want" "$T/fu.e"; then
        echo "  ok    firstUseT $_lbl"; green=$((green+1))
    else
        echo "  FAIL  firstUseT $_lbl -- MOVED. Actual:"
        grep -E "^FU-" "$T/fu.e" | sed 's/^/          /'; fail=1
    fi
done

#  ---- slashValT / slashLeadT: a leading // kills the value -------------------
#  G03's blocker, measured 2026-09-17. A `//` at the START of a define's value breaks the
#  parse; mid-value is fine. ⚠ IN BOTH SPELLINGS -- the `(...#)` delimited form is NOT
#  opaque to a leading `//`, which is the thing a reader will get wrong, because the first
#  workaround anyone reaches for is the other quoting style. A leading space does not help.
#  ⚠ THE TWO FILES ARE SPLIT BECAUSE THE FAILURE IS NOT LOCAL: a leading-// define kills
#  the WHOLE block, so the defect arm would delete its own controls. slashValT carries the
#  controls WITH VALUES (a run where nothing parses cannot pass them); slashLeadT asserts
#  the failure by PRESENCE of the RunRulE line, never by absence of a value.
#  ⚠ SYMPTOM ONLY. The mechanism is not recorded -- bear-trap #18. docs/fixIts.md F-81.
run2 slashValT "$T/sv.o" "$T/sv.e"; check "slashValT runs" 0 $?
sentinel "slashValT sentinel" "$T/sv.e" "SLASHVAL SENTINEL"
for _r in "SV-1 delimited, // mid-value|SV-1 delimited, // mid-value  =  has // a comment" \
          "SV-2 quoted,    // mid-value|SV-2 quoted,    // mid-value  =  has // a comment"; do
    _lbl=${_r%%|*}; _want=${_r##*|}
    if grep -qF "$_want" "$T/sv.e"; then
        echo "  ok    slashValT $_lbl reads back INTACT -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  slashValT $_lbl -- MOVED. Actual:"
        grep -F "${_lbl%% *}" "$T/sv.e" | sed 's/^/          /'; fail=1
    fi
done
run2 slashLeadT "$T/sl.o" "$T/sl.e"; check "slashLeadT runs" 0 $?
#  ⚠ RE-PINNED 2026-09-17 WITH A SENTENCE (H6). This row used to assert the FAILURE, red-
#  shaped on purpose, with its own note saying "when the opaque scan lands this row goes red
#  -- that is the signal, not a regression." It landed the same day and the row said so.
#  The fix is one modifier character at the delimiter's MINT SITE (GroupMain's hand-built
#  bootstrap, modify(item,"}^")): the scan target inherits the `^` its driver already had.
#  ⚠ PRESENCE-WITH-VALUE, and the SENTINEL is what makes it non-vacuous: SL-NEVER alone
#  would also be absent from a run that died before reaching it.
sentinel "slashLeadT sentinel" "$T/sl.e" "SLASHLEAD SENTINEL"
if grep -qF "SL-NEVER the define survived" "$T/sl.e"; then
    echo "  ok    slashLeadT a LEADING // NO LONGER kills the define -- G03's blocker is gone"; green=$((green+1))
else
    echo "  FAIL  slashLeadT the leading-// define is failing again -- the delimiter stopped"
    echo "        inheriting its driver's noSkip. Actual:"
    grep -E "RunRulE|^SL-" "$T/sl.e" | sed 's/^/          /'; fail=1
fi

#  ---- truncT / truncLitT: a failed MATCH ends the file, and now says so ------
#  F-79, 2026-09-17. `Start` is `StatemenT+`, so a statement that fails to MATCH ends that
#  repetition and every byte after it is never parsed -- no error, no stop: line, exit 0.
#  The report sits in main() after boot.parse(0) returns and reads LEFTOVER INPUT.
#  ⚠ IT DOES NOT READ ruler.refused, AND truncLitT IS WHY. Four shapes measured: a refusing
#  define AND an unterminated literal both truncate; `x = @@@` and a bad operator both run
#  clean. HALF THE TRUNCATING CASES RAISE NO REFUSAL, so the flag was the wrong channel.
#  ⚠ BOTH FILES TRUNCATE BY DESIGN and have no reachable stop(). Safe under H5: a
#  truncating run is not a HANGING run. Their terminal marker is the ABANDONED line, which
#  main emits AFTER the parse returns, so a truncation cannot fake it.
#  ⚠ EACH -2 ROW IS A COUNT OF 0 AND IS READ WITH ITS -1 SIBLING, never alone: without the
#  sibling, "the later statement did not run" is also true of a file that died at line one.
for _f in truncT truncLitT; do
    pfx=TR; if [ "$_f" = truncLitT ]; then pfx=TL; fi
    run2 "$_f" "$T/$_f.o" "$T/$_f.e"; check "$_f runs (exit 0 -- truncation is SILENT to the shell)" 0 $?
    if grep -q "^$pfx-1 the statement before the bad define RAN" "$T/$_f.e"; then
        echo "  ok    $_f $pfx-1 ran -- the run got as far as the bad define"; green=$((green+1))
    else
        echo "  FAIL  $_f $pfx-1 did not run, so $pfx-2's zero asserts nothing"; fail=1
    fi
    _n=$(grep -c "^$pfx-2 " "$T/$_f.e")
    if [ "$_n" = 0 ]; then
        echo "  ok    $_f $pfx-2 the statement AFTER did not run (0) -- read with $pfx-1"; green=$((green+1))
    else
        echo "  FAIL  $_f $pfx-2 ran $_n times -- the file was NOT truncated, so this fixture"
        echo "        is measuring nothing and the report below is about something else"; fail=1
    fi
    if grep -qF "ABANDONED incant/pop/$_f -- the parse STOPPED with input left over" "$T/$_f.e"; then
        echo "  ok    $_f $pfx-3 the abandonment is NAMED, with the file"; green=$((green+1))
    else
        echo "  FAIL  $_f $pfx-3 the file was abandoned SILENTLY. Actual:"
        grep -F "ABANDONED" "$T/$_f.e" | sed 's/^/          /'; fail=1
    fi
done
#  ⚠ THE RESUME ROWS ARE WHAT MAKE THIS A DIAGNOSIS RATHER THAN AN ALARM. truncT's quotes
#  the first statement that was never parsed; truncLitT's quotes THE OFFENDING LINE ITSELF,
#  because the scanner is still standing inside the unterminated literal.
if grep -qF 'cerr "TR-2 the statement after it RAN' "$T/truncT.e"; then
    echo "  ok    truncT TR-4 the resume point quotes the first UNPARSED statement"; green=$((green+1))
else
    echo "  FAIL  truncT TR-4 no resume text -- the report names no place"; fail=1
fi
if grep -qF '= "unterminated ;' "$T/truncLitT.e"; then
    echo "  ok    truncLitT TL-4 the resume point quotes THE OFFENDING LINE"; green=$((green+1))
else
    echo "  FAIL  truncLitT TL-4 the resume text does not reach the bad line"; fail=1
fi
_tlr=$(grep -c "^REFUSED" "$T/truncLitT.e")
if [ "$_tlr" = 0 ]; then
    echo "  ok    truncLitT TL-5 NO refusal raised (0) -- read with TL-4; this arm proves"
    echo "        the report is not built on ruler.refused"; green=$((green+1))
else
    echo "  FAIL  truncLitT TL-5 raised $_tlr refusals -- this arm has stopped being the"
    echo "        no-refusal case and no longer discriminates the channel"; fail=1
fi

#  ---- abandonT: A REFUSAL'S SCOPE IS THE STATEMENT ---------------------------
#  Tony, ruled 2026-09-17. aCTionStatemenT clears ruler.refused on the way out of every
#  statement, whether or not a method ran, because the refusal may have been raised
#  during the MATCH and never reached a method. clearRefusal is the SINGLE WRITER of the
#  0, as refuse() is of the 1, and the define boundary and runAction both route through
#  it. docs/refusalScope.md carries the argument.
#
#  ⚠ AB-1's COUNT FLIPPED FROM 1 TO 2 AND THAT IS THE WHOLE ASSERTION. One meant the file
#  was abandoned at the refusal; two means execution carried straight past it. A 1 here
#  is the old behaviour returning.
#  ⚠ AB-5 IS PINNED AT ZERO AND IS NEVER READ ALONE -- a zero is exactly what a REMOVED
#  reporter produces. AB-4 is its non-zero sibling. And the honest state of that reporter
#  is RECORDED, not asserted: reportRunAbandoned has NO REACHABLE CASE LEFT, five shapes
#  tried, every one cleared at a statement boundary with refused=0 at main's tail.
#  ⚠ THE FIXTURE DELIBERATELY USES A BARE STATEMENT, NOT A DEFINE. A refusal inside a
#  define still truncates -- and that is NOT the flag: with the boundary in place the run
#  reaches main reading refused=0 and truncates anyway, so it is the failed MATCH
#  abandoning the parse. Using a define here would measure that instead.
run2 abandonT "$T/ab.o" "$T/ab.e"; check "abandonT runs" 0 $?
_abn=$(grep -c "^AB-1 marker ran" "$T/ab.e")
if [ "$_abn" = 2 ]; then
    echo "  ok    abandonT AB-1 ran TWICE -- the refusal is scoped to its statement"; green=$((green+1))
else
    echo "  FAIL  abandonT AB-1 ran $_abn times, want exactly 2 -- a 1 means the refusal"
    echo "        escaped its statement again and the file was abandoned"; fail=1
fi
if grep -qF "AB-2 a plain statement after the refusal RAN" "$T/ab.e"; then
    echo "  ok    abandonT AB-2 a plain statement after the refusal RAN"; green=$((green+1))
else
    echo "  FAIL  abandonT AB-2 did not run -- execution did not survive the refusal"; fail=1
fi
if grep -qF "REFUSED . -- unary deref on the right of a dot" "$T/ab.e"; then
    echo "  ok    abandonT AB-3 the refusal fired -- without it AB-1 and AB-2 are vacuous"; green=$((green+1))
else
    echo "  FAIL  abandonT AB-3 NO REFUSAL -- every row above passes trivially now"; fail=1
fi
if grep -q "stop: end parsing" "$T/ab.o"; then
    echo "  ok    abandonT AB-4 the run ended properly -- stop() fired with a refusal behind it"; green=$((green+1))
else
    echo "  FAIL  abandonT AB-4 stop() did not fire"; fail=1
fi
_aba=$(grep -c "^ABANDONED" "$T/ab.e")
if [ "$_aba" = 0 ]; then
    echo "  ok    abandonT AB-5 not abandoned (0) -- read WITH AB-4, never alone"; green=$((green+1))
else
    echo "  FAIL  abandonT AB-5 ABANDONED $_aba times -- a refusal reached end of file"; fail=1
fi

#  ---- stopPreT: stop() WORKS WITH A REFUSAL STANDING -------------------------
#  Tony, ruled 2026-09-17: stop() and bail() work as intended, ALWAYS. Not working is not
#  an option.
#  ⚠ SP-2 FLIPPED FROM A RED-SHAPED PIN TO AN ABSENCE, AND THE ROW SAYS SO. It used to
#  pin the WRONG behaviour on purpose -- a statement below stop() that ran, because an
#  outstanding refusal silenced command dispatch and stop() was never entered. The
#  statement boundary retired that, so the day arrived and this is the row saying so.
#  ⚠ AN ABSENCE ASSERTS NOTHING ALONE (H4), so SP-2 is read with TWO positives: SP-1 says
#  execution continued at all, and SP-3 says the stop actually FIRED rather than the file
#  merely ending. Without SP-3, SP-2 would pass on any run that died early.
run2 stopPreT "$T/sp.o" "$T/sp.e"; check "stopPreT runs" 0 $?
if grep -qF "SP-1 a plain statement after the refusal STILL RAN" "$T/sp.e"; then
    echo "  ok    stopPreT SP-1 execution is NOT halted by a refusal"; green=$((green+1))
else
    echo "  FAIL  stopPreT SP-1 did not run -- the refusal halted execution"; fail=1
fi
_sp2=$(grep -c "^SP-2" "$T/sp.e")
if [ "$_sp2" = 0 ]; then
    echo "  ok    stopPreT SP-2 the statement below stop() did NOT run (0) -- stop() STOPS"; green=$((green+1))
else
    echo "  FAIL  stopPreT SP-2 ran $_sp2 times -- stop() was not entered, which is the"
    echo "        2026-09-17 ruling broken: stop() works as intended, ALWAYS"; fail=1
fi
if grep -q "stop: end parsing" "$T/sp.o"; then
    echo "  ok    stopPreT SP-3 stop() FIRED -- the positive that makes SP-2 readable"; green=$((green+1))
else
    echo "  FAIL  stopPreT SP-3 stop() never fired, so SP-2's zero means nothing"; fail=1
fi
if grep -qF "REFUSED . -- unary deref on the right of a dot" "$T/sp.e"; then
    echo "  ok    stopPreT SP-4 the refusal was standing -- without it the fixture is vacuous"; green=$((green+1))
else
    echo "  FAIL  stopPreT SP-4 NO REFUSAL -- nothing here is being tested"; fail=1
fi

#  ---- opPrefixT: every operator with a prefix sibling reads as ONE term ------
#  Built 2026-09-16. Twenty-three registered operators have another registered
#  operator as a strict prefix. If one were ever read as its shorter sibling the
#  rest of the token would be swallowed into the next term, and for the pairs
#  whose prefix HAS a road that would be silent -- `3 +/ 4` would simply answer 7.
#
#  ⚠ THIS DOES NOT PIN THE ROW ORDER IN incant/setup, DELIBERATELY. Order was
#  measured on 2026-09-16 and does NOT drive the match: the vertical-bar pair was
#  registered short-first for months and `||` still read correctly, and `+/` read
#  correctly from BELOW `+`. A row-order pin would go red for a reason unrelated
#  to correctness, which rule H3 forbids. These rows pin THE ANSWER, so they
#  survive a reorder and fail the day longest-match does.
#
#  EVERY ROW DISCRIMINATES: the long read and the prefix read give DIFFERENT
#  answers. 3>=3 is 1 where 3>3 is 0; 1+=2 is 3 where 1+2 leaves 1; 3+/4 is 3
#  where 3+4 is 7. A row both reads could satisfy would pin nothing.
run2 opPrefixT "$T/opp.o" "$T/opp.e"; check "opPrefixT runs" 0 $?
sentinel "opPrefixT sentinel" "$T/opp.o" "OPPREFIXT SENTINEL"
for _r in "ge     3>=3 (prefix > answers 0)|OPP ge     3>=3   =  1" \
          "le     3<=3 (prefix < answers 0)|OPP le     3<=3   =  1" \
          "eq     3==3 (prefix = would assign)|OPP eq     3==3   =  1" \
          "ne     3!=4 (prefix ! is unary)|OPP ne     3!=4   =  1" \
          "lt     3<4  anti-vacuity sibling|OPP lt     3<4    =  1" \
          "pluseq  1+=2 (prefix + leaves 1)|OPP pluseq  1+=2  =  3" \
          "minuseq 5-=2 (prefix - leaves 5)|OPP minuseq 5-=2  =  3" \
          "diveq   6/=2 (prefix / leaves 6)|OPP diveq   6/=2  =  3" \
          "muleq   3*=2 (prefix * leaves 3)|OPP muleq   3*=2  =  6" \
          "addptr  3+*4 (prefix + answers 7)|OPP addptr  3+*4  =  3" \
          "addattr 3+%4 (prefix + answers 7)|OPP addattr 3+%4  =  3" \
          "addmem  3+/4 (prefix + answers 7)|OPP addmem  3+/4  =  3" \
          "rebind  <-   (prefix < leaves it empty)|OPP rebind  <-    =  4" \
          "settag  <:   (prefix < leaves the tag)|OPP settag  <:    =  opRenamed" \
          "oror    3||0 (prefix | would refuse)|OPP oror    3||0  =  1" \
          "oror    0||0 non-vacuity sibling|OPP oror    0||0  =  0" \
          "andand  3&&0 (prefix & would refuse)|OPP andand  3&&0  =  0" \
          "andand  3&&4 non-vacuity sibling|OPP andand  3&&4  =  1"; do
    _lbl=${_r%%|*}; _want=${_r##*|}
    if grep -qF "$_want" "$T/opp.o"; then
        echo "  ok    opPrefix $_lbl -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  opPrefix $_lbl -- MOVED. The operator was read as its PREFIX,"
        echo "        or its road changed. Actual:"
        grep -F "${_want%% =*}" "$T/opp.o" | sed 's/^/          /'; fail=1
    fi
done
#  ⚠ THE TWO ROADLESS LONG FORMS ARE ASSERTED THE OTHER WAY ROUND, AND IT IS THE
#  STRONGER WAY. A token registered with no operateMethod refuses BY NAME and
#  prints the tag it ACTUALLY READ. Read as `>` or `<` these would find a road, do
#  a comparison, and refuse NOTHING -- so the row fails by the value's ABSENCE
#  instead of passing by it, which is H4 satisfied by the mechanism not by care.
#  The three one-character rows below are the anti-vacuity half: they prove the
#  refusal channel is live and reports the token it read. Without them, a build
#  where refusals had stopped printing would pass the two rows above in silence.
for _op in '>>' '<<' '|' '&' '^'; do
    if grep -qF "operator '$_op' has no road" "$T/opp.e"; then
        echo "  ok    opPrefix roadless '$_op' refuses BY ITS OWN NAME"; green=$((green+1))
    else
        echo "  FAIL  opPrefix roadless '$_op' did not refuse by name. Either the"
        echo "        token was read as something else, or the roadless refusal"
        echo "        stopped naming its operator."; fail=1
    fi
done

#  ---- deleteAt (F-66), ruled 2026-09-16: a separate verb, not an absent field --
#  Three rows. The HIT is pinned by the buffer line it produces, not by the
#  verb's own chatter, so a deleteAt that announced itself and removed nothing
#  cannot pass it. The MISS is presence-with-value on the refusal text (H4).
#  ⚠ THE THIRD ROW IS THE ONE THAT CERTIFIES THE RULING rather than the code:
#  dIRECTive5 is fired TWICE and the buffer after both fires must read exactly
#  the SAME line as after one. That is what "absent toThis is undiscriminable"
#  cost us -- a verb that decided by reading what was missing could not tell a
#  second fire from a first. Pinning the line rather than counting the fires is
#  also its anti-vacuity half: a delete that took the whole line out would
#  satisfy "it is gone" and fail this.
if grep -qF 'y = "Thats all ": };' "$T/dirv"; then
    echo "  ok    directives deleteAt HIT removed exactly its span -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  directives deleteAt HIT -- want the sample's last line to read"
    echo '        y = "Thats all ": };  -- either the delete missed, or it took'
    echo "        more than the matched span. Actual line:"
    grep -F 'Thats all' "$T/dirv" | sed 's/^/          /'; fail=1
fi
if grep -qF "Did not find zzzNotInTheSampleEither in source" "$T/dirv"; then
    echo "  ok    directives deleteAt MISS refuses BY NAME -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  directives deleteAt a miss no longer names itself. An absence-"
    echo "        based check here would pass by having the arm deleted; this"
    echo "        one cannot."; fail=1
fi
#  ⚠ THE COUNT IS OF THE POST-DELETE LINE, NEVER OF 'Thats all' -- the fixture
#  prints the buffer BEFORE and AFTER, so the shorter substring is in the capture
#  TWICE by design and a count of it reads 2 on a perfectly good run. Cost one
#  red row on 2026-09-16; the tell was the refusal text being present anyway.
if grep -qF "Did not find she wrote in source" "$T/dirv" \
   && [ "$(grep -cF 'y = "Thats all ": };' "$T/dirv")" = "1" ] \
   && [ "$(grep -cF 'Thats all she wrote' "$T/dirv")" = "1" ]; then
    echo "  ok    directives deleteAt SECOND FIRE is inert and says so"; green=$((green+1))
else
    echo "  FAIL  directives deleteAt second fire is NOT inert. It must take the"
    echo "        miss arm -- the text is already gone -- and leave the buffer"
    echo "        untouched. This row is F-66's ruling, not its code."; fail=1
fi

#  ---- F-67: where=before/after PLACEMENT at middle and tail ------------------
#  Landed 2026-09-16. `where == "before"` was never true -- a hoisted local is a
#  HOLDER and every other read in incant/directives already starred it, so this
#  one line was the file's only unstarred read and where=before silently became
#  where=after. Measured 5 spellings x 2 with a control before the star went in.
#  ⚠ THESE ARE RE-PINS AND THEY NEED THIS SENTENCE (H6): the middle rows moved
#  because the BEHAVIOUR moved, and it moved toward what the fixture always said
#  it did. They are not re-pinned to silence anything.
neighbour "$T/dirv" 'print "Stuck this in before":;'  1 '        x = "hi";' \
    "where=before lands AHEAD of its line (middle)"
neighbour "$T/dirv" 'print "Stuck this in after":;'  -1 '        print x:;' \
    "where=after lands BEHIND its line (middle)"
#  The two tail rows BRACKET the same neighbour, so a payload on the wrong side
#  of the last line cannot satisfy either of them.
neighbour "$T/dirv" 'TAIL-BEFORE'  1 '        y = "Thats all ": };' \
    "where=before lands AHEAD of its line (tail)"
neighbour "$T/dirv" 'TAIL-AFTER'  -1 '        y = "Thats all ": };' \
    "where=after lands BEHIND its line (tail)"

#  ---- where=before on the FIRST line of a buffer -----------------------------
#  ⚠ GRADUATED 2026-09-16, SAME DAY IT WAS MINTED, and H6 is why the label moved
#  with it: a pin that starts passing must stop calling itself a pin. It was born
#  RED ON PURPOSE (H7's other half) -- the payload landed ONE CHARACTER INTO line
#  one, `hHEAD-PAYLOAD` then `eadLine alpha` -- and it was pinned to the RIGHT
#  answer precisely so that the repair would turn it green without anyone having
#  to notice. It did.
#  THE REPAIR, one line in Instruct.rtn getMarkLineAt: `if lineStart >= start
#  lineStart++;` became `if lineStart == '\n' lineStart++;`. lineStart can never
#  be BELOW start, so the old test always fired -- right when the walk stopped at
#  a newline, one character too far when it stopped at the buffer head. The new
#  test asks what the walk actually stopped ON.
#  ⚠ IT HAS ITS OWN RUN because getFile is once per FIELD and the mark only
#  advances -- a head case cannot share a buffer with anything.
run1 dirHeadT "$T/dirh"; check "dirHeadT runs" 0 $?
sentinel "dirHeadT sentinel" "$T/dirh" "DIRHEADT SENTINEL"
neighbour "$T/dirh" 'HEAD-PAYLOAD'  1 'headLine alpha' \
    "where=before at the HEAD leaves line one intact"

#  ---- artifactSkipByFlag: the skip reads the STRUCTURAL fact ----------------
#  Retired citizen, 2026-09-08, retirement BY MAPPING: this is where its census
#  now lives. walkRules used to skip a generated artifact by reading `noPrinT`,
#  so noPrint carried two meanings -- "do not print me" AND "I am an artifact".
#  It gates on `isRulE == 0` now. Terms are rules; minted artifacts are not.
#
#  ⚠ THE GATE IS `== 0` AND NOT `!isRulE`, AND THAT IS NOT A STYLE CHOICE. The
#  bang form was MEASURED and it skips NOTHING -- both artifacts read VISITED --
#  because `!` on a zero-holding field answers false (andProbe AP-5b, a
#  pre-existing defect). Writing the obvious spelling would have produced a
#  walker that silently visits every artifact at exit 0. Do not "tidy" this.
#
#  ⚠ ASSERTABILITY, NOT BEHAVIOUR: the two gates agree on today's data (parser
#  walks 21 either way, WITNESS 1 either way) because no node is a noPrint rule
#  or a printing artifact. That agreement is exactly why noPrint appeared to
#  work. The rows below pin the FACT each child answers, so the day those two
#  populations diverge the fleet says so instead of guessing.
run1 artifactSkipT "$T/ask"; check "artifactSkipT runs (promoted citizen; census carried here)" 0 $?
sentinel "artifactSkipT sentinel (no truncation)" "$T/ask" "ARTIFACTSKIP SENTINEL"
#  ⚠ THE builtinParsE ROW RETIRED 2026-09-14, BY MAPPING RATHER THAN BY DELETION.
#  builtinParsE HAS NO WRITER ANY MORE: setParse minted it at Generate.rtn:414 as of
#  1947e59 and the parser rework dropped that line, so the attribute is never created
#  and the string could not match on any tree. It is not a regression in the SKIP --
#  it is the absence of the thing being skipped.
#  WHAT IT ASSERTED AND WHERE THAT LIVES NOW: "a minted artifact reads isRulE 0 and
#  noPrinT 1, so the walker skips it structurally". Its surviving sibling below,
#  builtinActoR, asserts exactly that fact on the artifact that IS still minted, so
#  the structural claim keeps a live witness and the census is 1 1 0 rather than 1 1 0 0.
for _r in "term numberSet    is a rule|child  numberSet isRulE  1 noPrinT  0" \
          "term FloaT        is a rule|child  FloaT isRulE  1 noPrinT  0" \
          "artifact builtinActoR is NOT|child  builtinActoR isRulE  0 noPrinT  1"; do
    _lbl=${_r%%|*}; _want=${_r##*|}
    if grep -qF "$_want" "$T/ask"; then
        echo "  ok    artifactSkip $_lbl -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  artifactSkip $_lbl -- MOVED. The 1 1 0 0 census is the"
        echo "        certificate the citizen retired on; if it moved, the skip's"
        echo "        structural fact moved with it."; fail=1
    fi
done

#  ---- bareIfTruth: aCTionIF answers by truthOf ------------------------------
#  Tony's ruling, 2026-09-08. `if noPrinT;` must work as spelled. aCTionIF used
#  to test `result && isInitialized`, and setCount RAISES isInitialized -- so the
#  moment opDot gave a data-less flag read a real `count = 0`, every FALSE flag
#  started testing TRUE. It filtered odoPopulation from 64 rules to 0 at exit 0.
#
#  ⚠ THESE ROWS ARE PINNED BY VALUE AND EACH ONE HAS A NON-ZERO SIBLING, because
#  a row that only ever wants "false" cannot tell ANSWERED-BY-VALUE from
#  ANSWERED-BY-NOTHING -- the two look identical from outside. AP-5 pairs aFalse
#  with aTrue; AP-6 pairs an empty list with a 3-member one.
#
#  ⚠ AND AP-5b IS PINNED AT A DEFECT ON PURPOSE (H7's other half): `if !aFalse;`
#  reads false when aFalse holds 0, which is wrong. It was measured false on BOTH
#  arms of bareIfTruth's own control, so it did not move and is not this ruling's
#  doing. Pinned wrong with a sentence rather than left uncovered, so the day it
#  changes -- in either direction -- the fleet says so.
run1 andProbe "$T/apr"; check "andProbe runs (bareIfTruth driver)" 0 $?
sentinel "andProbe sentinel (no truncation)" "$T/apr" "AP SENTINEL"
for _r in "AP-4  a 0-holding conjunction result|and if andOut; reads it false" \
          "AP-5  if aFalse; on a 0-holding field|if aFalse; -> false" \
          "AP-5s anti-vacuity sibling: if aTrue;|if aTrue;  -> TRUE" \
          "AP-6  if length; on an EMPTY list|if length; on an EMPTY list -> false" \
          "AP-6s anti-vacuity sibling: 3 members|if length; on a 3-MEMBER list -> TRUE"; do
    _lbl=${_r%%|*}; _want=${_r##*|}
    if grep -qF "$_want" "$T/apr"; then
        echo "  ok    andProbe $_lbl -- PINNED BY VALUE"; green=$((green+1))
    else
        echo "  FAIL  andProbe $_lbl -- MOVED. bareIfTruth is the ruling; aCTionIF"
        echo "        must answer by truthOf (absent false, numeric by value, else"
        echo "        true by presence). Do not re-pin to silence it."; fail=1
    fi
done
#  ⚠ GRADUATED 2026-09-10, and the sentence is that `!` NOW ANSWERS BY truthOf.
#  This row was pinned at a PRE-EXISTING DEFECT and its own failure message asked for
#  exactly this re-pin. opNOT read `!contents()` -- the PRESENCE question -- so `!0`
#  came back false, because a node holding zero HAS contents. It now reads
#  `!truthOf(result)`, which is the layered contract this file already governs for the
#  word forms: absent is false, a numeric node answers BY ITS VALUE, a node with no
#  numeric value is true by presence. So `if !aFalse;` reads TRUE, which is what a
#  0-holding field should give.
#  ⚠ THE GAP THE truthOf HEADER NAMED IS NOW HALF CLOSED, and the half that remains is
#  named rather than left to be rediscovered: that header records `if <field>` and
#  `<field> AND ...` disagreeing in the shipping language, and says closing it is a
#  separate ruling. `!` has crossed to the operator side; bare `if aFalse;` (AP-5) has
#  NOT and is still pinned reading TRUE. Two spellings, one contract, one still owed.
if grep -qF "if !aFalse; -> TRUE" "$T/apr"; then
    echo "  ok    andProbe AP-5b if !aFalse; -> TRUE -- ! answers by truthOf (graduated)"; green=$((green+1))
else
    echo "  FAIL  andProbe AP-5b if !aFalse; MOVED -- it was graduated to TRUE on 2026-09-10"
    echo "        when opNOT stopped asking !contents() and started asking !truthOf."
    echo "        Reading `false` again means opNOT went back to the presence question."; fail=1
fi

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
#  ST-2 opRem returned `tempField`, which at the refusal point HAS NO DATA -- so
#  the caller got a field that looks like an answer and reads back as its own tag.
if grep -qF "ST-2 caller read       = 222" "$T/snt"; then
    echo "  ok    sentinelT ST-2 opRem: the caller keeps 222 -- no dataless tempField handed back"; green=$((green+1))
else
    echo "  FAIL  sentinelT ST-2 opRem is handing back a value again, or the store ruling broke"; fail=1
fi
if grep -qF "ST-2 statement after   = 0" "$T/snt"; then
    echo "  ok    sentinelT ST-2 the statement after the refusal did NOT run"; green=$((green+1))
else
    echo "  FAIL  sentinelT ST-2 the statement after the refusal RAN -- not terminal"; fail=1
fi
#  ⚠ ST-3 IS THE STAR RULING AND IT PULLS THE OTHER WAY FROM ST-1 AND ST-2.
#  `*x` on a field holding no group yields the TESTABLE NOTHING and does NOT
#  refuse: refusal is for CATEGORY errors, and asking a field what it holds is a
#  legitimate question with a legitimate empty answer. So `if *x` takes its else
#  arm and THE ACTIVATION CARRIES ON -- the opposite of every other row here,
#  which is why both halves are asserted.
if grep -qF "ST-3 if *x else arm    = 2" "$T/snt"; then
    echo "  ok    sentinelT ST-3 \`*x\` on an empty holder yields NULL -- the else arm ran"; green=$((green+1))
else
    echo "  FAIL  sentinelT ST-3 \`*x\` on an empty holder did not take the else arm"; fail=1
fi
if grep -qF "ST-3 statement after   = 1" "$T/snt"; then
    echo "  ok    sentinelT ST-3 the activation was NOT ended -- a star is not a refusal"; green=$((green+1))
else
    echo "  FAIL  sentinelT ST-3 a star ENDED the activation -- the star ruling regressed"; fail=1
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
for l in open('"$(ip grammar)"'):
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
    echo "        that no longer consumes its trailing continue; "$(ip trailingContinueT)""
    echo "        covers all three and will say which."; fail=1
fi

#  ---------------------------------------------------------------------------
#  A9 -- THE `||` TRUTH TABLE AND ITS SHORT-CIRCUIT. Banked 2026-09-10, and it is
#  banked because a REAL `||` REGRESSION WAS INVISIBLE TO THIS FLEET.
#
#  ⚠ WHAT HAPPENED. A try at giving `||` the tier-3 short-circuit binding made
#  `true || false` read FALSE. incant/orProbe caught it in one line; THE FLEET DID NOT
#  MOVE AT ALL -- 261 green before and after -- because no row read orProbe's operator
#  table. The change was reverted, and this row exists so the next try cannot be silent.
#
#  ⚠ IT PINS BOTH HALVES, and they are different questions. The TABLE is what `||`
#  ANSWERS; the SHORT-CIRCUIT row is what it EVALUATES. The measured state on
#  2026-09-10 is that the table is correct and the short-circuit is NOT -- `OR` does not
#  evaluate its right operand when the left decides, and `||` does. THAT ROW IS PINNED
#  AT THE DEFECT ON PURPOSE, the way andProbe's AP-5b was: it is a known gap with a
#  ruling owed, and pinning it means the day it closes, the fleet says so.
run2 orProbe "$T/orp.o" "$T/orp.e"; check "orProbe runs" 0 $?
_orfail=0
for _r in "true  || false -> TRUE" "false || false -> false" "false || true  -> TRUE"; do
    grep -qF "$_r" "$T/orp.o" || _orfail=1
done
if [ "$_orfail" = 0 ]; then
    echo "  ok    orProbe: the || truth table holds (T|F, F|F, F|T) -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  orProbe: the || TRUTH TABLE moved. This is the row that a short-circuit"
    echo "        change breaks first -- `true || false` reading false is the measured"
    echo "        signature of the tier-3 binding being given to the symbol form."
    grep -E '\-> ' "$T/orp.o" | sed 's/^/          actual:   /'; fail=1
fi
#  ⚠ GRADUATED 2026-09-10, AND IT MOVED HOUSE. The row above pinned `||` AT THE DEFECT
#  and asked, in its own failure text, to be re-pinned when the gap closed. IT HAS CLOSED
#  -- two spelling lists became registrations -- so the pin does not merely flip, it moves
#  to incant/shortCircuitT, which COUNTS FIRES IN PAIRS. orProbe cannot host it: it has a
#  single loudZero case, so post-fix its marker count is 0 with NO NON-ZERO SIBLING, and a
#  lone zero is what a right arm that never ran at all would also print. The table row
#  above stays here; the evaluation rows go where they can be paired.
run2 shortCircuitT "$T/sq.o" "$T/sq.e"; check "shortCircuitT runs" 0 $?
sentinel "shortCircuitT sentinel (no truncation)" "$T/sq.o" "SHORTCIRCUIT SENTINEL"
_sqfail=0
#  ⚠ FOUR ROWS SINCE THE WORD FORMS RETIRED. The AND/OR rows went when `AND` and `OR`
#  left incant/setup: the 2c scrub respelled their operators and left their labels, so
#  they printed "AND" while testing `&&` -- green, duplicated, and lying.
for _r in "SC-5 false &&  loud  fires =  0" "SC-6 true  &&  loud  fires =  1" \
          "SC-7 true  ||  loud  fires =  0" "SC-8 false ||  loud  fires =  1"; do
    grep -qF "$_r" "$T/sq.e" || _sqfail=1
done
if [ "$_sqfail" = 0 ]; then
    echo "  ok    short-circuit: && and || skip and evaluate correctly, in pairs -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  the short-circuit table moved:"
    grep "^SC-" "$T/sq.e" | sed 's/^/          actual:   /'
    echo "          Each row is paired: the 0 rows are the SKIP, the 1 rows are their"
    echo "          non-zero siblings. SC-7 going to 1 means \`||\` stopped short-circuiting --"
    echo "          check that `shortCircuit` and `isOR` are still on '\''||'\'' in "$(ip setup)";"
    echo "          BOTH are needed, one for the tier-3 binding and one for the skip direction."; fail=1
fi

#  ---------------------------------------------------------------------------
#  A8 -- THE DOT'S RIGHT OPERAND IS A NAME, NEVER A VALUE. Landed 2026-09-10.
#
#  BEFORE IT, `A.B` on a member name read 0. The right operand arrived RESOLVED, and a
#  resolved node WITH DATA returns its DATA from .text (bear-trap #26), so the lookup
#  key was the member's whole contents instead of its name -- `DesignDocs.TokFiles`
#  looked up TokFiles' entire description paragraph and missed. handleDot now hands
#  opDot a fresh DATA-LESS node carrying the name as its tag: #26 working deliberately
#  instead of by accident.
#
#  ⚠ THE FOUR ROWS ARE NOT SEPARABLE. DN-1 is the capability. DN-2 is the MISS and it
#  must stay EMPTY -- a fix that minted a node for every right-hand name would pass DN-1
#  and be wrong. DN-3/DN-4 are the ACCESSOR EXEMPTION, and they are a PAIR because DN-3
#  wants 0 and a DEAD accessor reads 0 too: DN-4 writes the flag and wants 1, so only a
#  live accessor produces both. DN-0 is the anti-vacuity control on the walk itself.
#
#  ⚠ WHY THE EXEMPTION EXISTS AT ALL: a groupFields entry is selected by REGISTRY
#  MEMBERSHIP, and re-minting strips the registry -- which would take the WHOLE accessor
#  family off its road. Measured the expensive way on the first cut of this change, which
#  left the operand unwrapped instead and sent `ANYtoken` to opDot as the key: FC-3,
#  cursorRead and the unary buy row all moved at once.
run2 dotNameT "$T/dn.o" "$T/dn.e"; check "dotNameT runs" 0 $?
sentinel "dotNameT sentinel (no truncation)" "$T/dn.o" "DOTNAME SENTINEL"
if grep -q "DN-0 control  dnBag.listLengtH        =  2 " "$T/dn.e" \
   && grep -q "DN-1 member   dnBag.dnKid       taG   =  dnKid " "$T/dn.e" \
   && grep -q "DN-2 miss     dnBag.zzNoSuchMember    =  0 " "$T/dn.e" \
   && grep -q "DN-3 accessor dnBag.noPrinT  BEFORE   =  0 " "$T/dn.e" \
   && grep -q "DN-4 accessor dnBag.noPrinT  AFTER    =  1 " "$T/dn.e"; then
    echo "  ok    dot right-operand is a NAME: member resolves, miss stays empty, accessor road live -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  the dot's right-operand rows moved:"
    grep "^DN-" "$T/dn.e" | sed 's/^/          actual:   /'
    echo "          expected: DN-0 2, DN-1 dnKid, DN-2 0, DN-3 0, DN-4 1."
    echo "          DN-1 falling back to 0 means the operand is being EVALUATED again."
    echo "          DN-4 falling to 0 means the accessor exemption was lost -- a re-minted"
    echo "          groupFields entry loses its registry and the whole accessor family goes dark."; fail=1
fi

#  ---------------------------------------------------------------------------
#  A7 -- THE UNARY CLASS SPLIT, the BUY ROW for a try-and-buy ruling. 2026-09-10.
#
#  THE RULING: a prefix unary is ACCESS class, binding to the PRIMARY before the
#  postfix chain, or VALUE class, binding to the chain's RESULT. `*A.B` is `(*A).B`;
#  `!A.B` is `!(A.B)`. The class is a REGISTRATION -- `accessClass` on the operator
#  in incant/setup -- and the dispatch asks one predicate, so there is no list in the
#  action and adding a class member is an edit to setup.
#
#  ⚠ THE PAIR UC-1/UC-2 IS THE WHOLE ASSERTION AND NEITHER ROW STANDS ALONE. `ucH` is
#  a holder over a three-member bag: reading THROUGH it gives the holder's own length,
#  dereferencing FIRST gives the bag's. So UC-1 wants 3 and UC-2 wants 0, and the two
#  differing is what says the star bound to the primary. H7 control run: deleting
#  `accessClass` from the registration takes UC-1 from 3 to 0 -- it collapses onto UC-2
#  and the two become indistinguishable, which is exactly the failure the pair exists
#  to catch. The registration is load-bearing, not decoration.
#
#  ⚠ UC-0 IS THE ANTI-VACUITY CONTROL. A run that read nothing would print 0 for both
#  UC-1 and UC-2; UC-0 at 3 says the bag really does have three members.
run2 unaryClassT "$T/uc.o" "$T/uc.e"; check "unaryClassT runs" 0 $?
sentinel "unaryClassT sentinel (no truncation)" "$T/uc.o" "UNARYCLASS SENTINEL"
if grep -q "UC-0 control  ucBag.listLengtH  bare  =  3 " "$T/uc.e" \
   && grep -q "UC-1 access   \*ucH.listLengtH         =  3 " "$T/uc.e" \
   && grep -q "UC-2 holder    ucH.listLengtH         =  0 " "$T/uc.e"; then
    echo "  ok    unary class: deref binds to the PRIMARY (3), the bare read to the holder (0) -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  unary class split moved:"
    grep "^UC-" "$T/uc.e" | sed 's/^/          actual:   /'
    echo "          expected: UC-0 = 3, UC-1 = 3, UC-2 = 0."
    echo "          UC-1 falling to 0 means the star stopped binding to the primary -- check that"
    echo "          `accessClass` is still on '\''*'\'' in "$(ip setup)"; the predicate is presence-based"
    echo "          and a missing registration silently demotes the star to value class."; fail=1
fi

#  ---------------------------------------------------------------------------
#  A6 -- HOW A MEMBER'S TAG IS READ FROM INSIDE AN ITERATE BODY. 2026-09-10,
#  stroke 6b's PRE-MEASURE, banked as a row rather than as prose.
#
#  ⚠ WHAT IT PROTECTS, and it is a RULING'S PRECONDITION rather than a defect.
#  The `.`-is-binary ruling retires the leading/bare accessor form and says a
#  collision between a bare name and a member is spelled explicitly, `btCur.taG`.
#  MEASURED BEFORE ANY OF THAT IS BUILT, two arms, because a ruling that retires
#  the working spelling in favour of a broken one is a ruling that goes dark:
#
#      ARM A, no collision      bare taG -> crAlpha / crBeta   CORRECT
#                               crCur.taG -> `crCur`           THE CURSOR, not the member
#      ARM B, a field named taG bare taG -> 0
#      declared in the define   crCur.taG -> 1
#
#  So TODAY the bare form is the one that works, the explicit form the ruling
#  names as the escape hatch reads the CURSOR (bear-trap #35's chained-read
#  family), and a declared same-named field shadows BOTH. Two independent
#  fixtures agree on the explicit form: incant/attic/branchTagTruth's table has
#  `if btCur.taG eq "return"` at 3 of 3 and `*btCur.taG == "return"` at 0.
#
#  ⚠ BOTH ARMS ARE REQUIRED. A alone cannot see the shadowing; B alone cannot
#  show that bare is the working spelling when nothing shadows it. Each carries
#  its own walked-count control at 2, so a row that read nothing cannot pass.
run2 cursorReadT "$T/cra.o" "$T/cra.e"; check "cursorReadT runs" 0 $?
sentinel "cursorReadT sentinel (no truncation)" "$T/cra.o" "CURSORREAD SENTINEL"
if grep -q "CR-A 1 bare= crAlpha explicit= crCur" "$T/cra.e" && grep -q "CR-A walked =  2 " "$T/cra.e"; then
    echo "  ok    cursorRead A: bare reads the MEMBER, explicit reads the CURSOR -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  cursorRead A moved -- the two spellings no longer read what they read on 2026-09-10:"
    grep "^CR-A" "$T/cra.e" | sed 's/^/          actual:   /'
    echo "          expected: CR-A 1 bare= crAlpha explicit= crCur   (and walked = 2)"
    echo "          If `explicit` now reads the member, the .-is-binary ruling's escape"
    echo "          hatch has started working and this row is a RE-PIN owed a sentence."; fail=1
fi
run2 cursorReadTb "$T/crb.o" "$T/crb.e"; check "cursorReadTb runs" 0 $?
sentinel "cursorReadTb sentinel (no truncation)" "$T/crb.o" "CURSORREADB SENTINEL"
if grep -q "CR-B 1 bare= 0 explicit= 1" "$T/crb.e" && grep -q "CR-B walked =  2 " "$T/crb.e"; then
    echo "  ok    cursorRead B: a declared same-named field SHADOWS both spellings -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  cursorRead B moved -- the shadowing changed:"
    grep "^CR-B" "$T/crb.e" | sed 's/^/          actual:   /'
    echo "          expected: CR-B 1 bare= 0 explicit= 1   (and walked = 2)"; fail=1
fi

#  ---------------------------------------------------------------------------
#  A5 -- aCTionBrancH's TWO JIT ARMS BOTH DISCRIMINATE BY CONTENT. 2026-09-10.
#  This is the coverage incant/fixits/branchTagTruth carried out with it when it
#  retired; the citizen is in incant/attic/ and this row is where BT-3 now lives.
#
#  WHAT IT PROTECTS. The arm used to read `or BrancheS.tag {` -- a bare presence
#  test on a char*, which is non-null for every tag -- so break fell into the
#  RETURN emitter and the jitDegrade below it was unreachable for anything at all.
#  ⚠ AND THE READING THAT SETTLED IT WAS THE GENERATED .mm, NOT THE SOURCE: the
#  surviving 'c' arm looked equally suspect, because tok's `==` is numeric and
#  `.tag` is a char*. It is NOT broken -- tok renders `BrancheS.tag == 'c'` as
#  `*BrancheS->groupBody->tag == 'c'`, a real first-character compare. So the fix
#  owed ONE arm, not both, and reading the source alone would have owed two.
#
#  ⚠ H4-SHAPED ON PURPOSE. It counts a PRESENT construct rather than asserting the
#  absence of a bad one: a presence test cannot pass by someone deleting the line,
#  because deleting it drops the count. Both arms are in ONE grep so that reverting
#  either is visible.
arms=$(grep -c "\*BrancheS->groupBody->tag == " GroupRules.mm | tr -d " ")
if [ "$arms" = "2" ]; then
    echo "  ok    aCTionBrancH: $arms jit arms discriminate by content -- PINNED BY VALUE"; green=$((green+1))
else
    echo "  FAIL  aCTionBrancH content-test arms = $arms, want 2."
    echo "        One arm has gone back to a bare presence test on the tag. `or BrancheS.tag {`"
    echo "        is true for EVERY tag, so break walks into the return emitter and the"
    echo "        jitDegrade below becomes unreachable. Spell it `BrancheS.tag == 'r'`;"
    echo "        tok renders that as a first-character compare, same as the 'c' arm."; fail=1
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

#  ⚠ BOTH RE-BASED 2026-09-08, and each cluster of the delta is NAMED -- a target
#  that moved is a claim that the world changed, and the claim needs a cause. Both
#  bases dated 2026-07-29 and had absorbed drift silently ever since, which is what a
#  long-red row does.
#
#  oneTest, five clusters, and the arithmetic closes:
#    - SIX punctuation MISSRULE lines (leftBrace, leftCurly, leftParen, rightBrace,
#      rightCurly, rightParen) that PREDATE this session -- measured present on a
#      HEAD build -- plus ColoN and EquaL, Tony's two new ones. 4 + 8 = 12, which is
#      exactly what the AUDIT summary line now reads and what the row above pins.
#    - AUDIT TERM IterSource [1] UnaryOPS arrives with the 09-03 iterate re-rule.
#    - AUDIT TERM Limit [4] ] LEAVES, because Limit's bare "]" literal became a
#      labelled reference to grok/rightBrace. That is the whole point of the
#      punctuation conversion: the term stops being an unlabelled rule-level literal.
#    - "stop: end parsing", emitted by stopParsingInput and present at HEAD.
#
#  jsonTest, and 38 of its 40 error lines were FIXED rather than banked:
#    - "ERROR = on JSONtoken -- holds a group; say *" x38 was a PRE-FLIP SPELLING in
#      the fixture's own grammar. JSONfield's body said `token = JSONvalue;` and under
#      the landed ruling an `=` whose source holds a group refuses and tells you to
#      say `*`. Respelt to `token = *JSONvalue;` (incant/utilities:97) and all 38 go.
#      The base predates the flip, so it never saw them.
#    - "nextGroup: ERROR JSONlist does not contain a list" x2 REMAINS, attributed and
#      not yet fixed: it is the EMPTY-ARRAY case. JSONarray guards with `if JSONlist;`
#      and, when the optional term did not match, that name falls back to the RULE --
#      which exists, so the guard passes and the walk reads a rule that carries no
#      list. Two `{"a":[]}` calls, two lines. Bear-traps #26/#34. The fixture still
#      answers ok on both, so this is noise and not a wrong answer; two guard
#      respellings were tried and both failed, so it is banked ATTRIBUTED and owed.
#      docs/fixIts.md carries the row.
#    - "stop: end parsing", same as above.
#  ⚠ oneTest RE-BASED 2026-09-10, four lines only, and the sentence is the noLabel
#  dash moving onto the TRAIT rather than onto its DATA -- `leftBrace-="["` in place
#  of `leftBrace="["-`. Both spellings parse: TraiT is `NamE Modifier* Limit?
#  TraiTdata?` and TraiTdata is `'=' DatA Modifier* Limit?`, so the dash lands in one
#  Modifier* or the other. In the OLD spelling it reached aCTionTraiTdata, which
#  modifies the DatA node -- and aCTionTraiT then setContent's that node onto the
#  trait, which does not carry flags (bear-trap #1/#2). So the dash was applied to a
#  node whose flags were about to be discarded, and the term was minted as a labelled
#  rule with no rStuff. In the NEW spelling it reaches aCTionTraiT, which modifies the
#  trait itself, and the trait survives.
#  THE WHOLE DELTA IS FOUR VANISHED MISSRULE LINES -- leftBrace, leftParen,
#  rightBrace, rightParen -- and the summary going 12 -> 8. Measured additively, one
#  respelled grammar line at a time: Braced removes its pair, Parens removes its pair,
#  StringXP and ScopeXP remove none. Nothing else in the capture moved.
#  ⚠ leftCurly and rightCurly SURVIVE ON PURPOSE. BlocK carries the same respell and
#  is HELD: it alone takes iterT1/iterT1m from 7 visits to 5, a nested walk losing the
#  second member of each leaf after the first refuses. That is a fixit citizen, not an
#  attribution. When it lands, this base loses two more lines and 8 -> 6.
#  ⚠ BOTH BASES RE-PINNED 2026-09-14, and each gets its sentence (rule H6 -- a
#  re-pin is a claim that the world changed, and the claim needs a cause).
#
#  oneTest: +37 lines, ALL of them `AUDIT TERM <rule> builtinActoR -- rule TERM,
#  not isRule, has rStuff`, zero removals and zero other additions. Tony's
#  builtinActoR relocation became visible to the audit block: rule actions moved
#  off gMethod into a published builtinActoR attribute, and the audit reports
#  every TERM now carrying one. One of the 37 is ElseIf, added by the stroke-1
#  fix that made `or` arms fire at all. The audit is reporting a real new state,
#  not drifting.
#
#  jsonTest: -2 lines, EXACTLY the two `nextGroup: ERROR JSONlist does not
#  contain a list`. Measured at HEAD under lldb rather than inferred: the emitter
#  is aCTionFOR, i.e. `for grup in JSONlist;` at incant/utilities:104, guarded
#  only by `if JSONlist;`. An unmatched optional `JSONlist?` used to leave a
#  truthy empty label behind, so the guard passed and the for walked a listless
#  node; it no longer does. The populated case still parses, so the for still
#  runs when there IS a list. A spurious error stopped firing -- this base moved
#  in the good direction. (The fixture's own guard is still an existence test
#  where project memory wants `if JSONlist.listLengtH;`; that is unfixed and is
#  not what moved.)
#  ⚠ RE-PINNED 2026-09-15, ONE LINE, AND IT IS THE PACKET REMOVAL SHOWING ITS WORK:
#  `AUDIT TERM ShortcuT [2] builtinActoR` -> `[1]`. ShortcuT carried TWO attributes, the
#  spent Modifier packet and builtinActoR; the packet came off aCTionTraiT, so the audit's
#  slot index drops by one. Nothing else in the baseline moved, which is the useful half --
#  the removal is visible here and invisible everywhere it should be.
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
#
#  ⚠ RE-PINNED 18/46 -> 19/45, 2026-09-07, ATCH, and the sentence is the ruling:
#  START NO LONGER CARRIES isGROUP; THE §4.1 RULE-AS-DATA REFUSAL ON IT IS
#  REMOVED AT THE GRAMMAR, NOT THE GENERATOR. `Start=StatemenT+` became
#  `Start StatemenT-+`, so the terms live in the list like every other rule's
#  and there is no embedded group left to refuse. THIS RE-PIN MOVES THE RATCHET
#  THE OTHER WAY -- it is the first one that is an IMPROVEMENT rather than a
#  removal or an addition, and the arithmetic is the check: green 18 -> 19, red
#  46 -> 45, POPULATION UNMOVED AT 64. One rule crossed from red to green and
#  none entered or left. Green rising while the population held is what makes
#  this a rule becoming emittable rather than a rule disappearing, which is the
#  shape the 09-01 tokenize re-pin had; any other split would have been a
#  finding. genParse itself was not touched.
#  ⚠ RE-PINNED 19/45 -> 22/45 -> 22/42, 2026-09-07, and the sentence is the ruling
#  applied to its KEYSTONE: ANYTOKEN NO LONGER CARRIES isGROUP. `ANYtoken=NamE`
#  became `ANYtoken NamE@` -- the @ modifier, which already meant "this term wears
#  my label" (attachLabel's isTarget arm sets pStuff.label = lab and
#  lab.tag = pStuff.ruleName). No action changed; no C++ changed.
#  ⚠⚠ THIS RE-PIN IS THE FIRST WHERE ONE RULE CARRIED THREE, and that is the whole
#  reason the reason column is read and not just the verdicts. ANYtoken was the
#  INLINE blocker for four other rules, so fixing one rule-level refusal cleared
#  four rows: ANYtoken, IterSource and UnaryXP go GREEN, and Iterate stays RED
#  with a NEW REASON -- `REFUSE attributes -- optional labelled literal` -- which
#  is its next blocker, not a regression. Green 19 -> 22, red 45 -> 42, POPULATION
#  UNMOVED AT 64: three crossed, none entered or left.
#  ⚠ AND A VERDICT-ONLY DIFF WOULD HAVE MISREAD IT. Iterate's row is present
#  before and after and red both times; only its reason moved. H9's corollary --
#  a refusal census reports the FIRST blocker, never the blocker set -- so a rule
#  that stays red after its blocker is fixed has simply revealed the next one.
#  ⚠ RE-PINNED 22/42 -> 23/41, 2026-09-07, and the sentence is the ruling reaching
#  the BOOTSTRAP: InitiatE no longer carries isGROUP. GroupMain.twk:435 stopped
#  embedding RunRulE as a group and adds it as a term with `+@` instead. Green
#  22 -> 23, red 42 -> 41, POPULATION UNMOVED AT 64, and InitiatE's row is the only
#  one that moved -- no other rule was blocked on it, unlike ANYtoken which carried
#  three. First stroke of this ruling in C++ rather than the grammar; the inert
#  grammar mirror at incant/grammar:68 was updated in the same commit so the file
#  stops describing a shape the bootstrap no longer builds.
#  ⚠ RE-PINNED 23/41 -> 24/40, 2026-09-07, same stroke and same sentence as the
#  census.target re-pin above: NewGroup loses its group at GroupMain.twk:353.
#  Green 23 -> 24, red 41 -> 40, POPULATION UNMOVED AT 64. DefinE stays red with a
#  NEW REASON (term NewGroup -> term Attributes), which is the blocker behind the
#  one just fixed.
#  ⚠ RE-PINNED 24/40 of 64 -> 24/42 of 66, 2026-09-08, and the sentence is the same
#  ruling as the bare-master row above: ColoN and EquaL join the grammar as labelled
#  punctuation. Both arrive un-emittable and say so by name -- "REFUSE rule ColoN --
#  rule-level literal but no rStuff, so LIT vs LITTO is undecidable" -- which is the
#  expected state for a new rule, not a regression: nothing has taught genParse about
#  them and nothing claimed to. GREEN IS UNMOVED AT 24 and the population rose by
#  exactly two. Two rules entered the population, neither entered the green set, and
#  no existing row moved in either direction; any other split would have been a finding.
#  ⚠ RE-PINNED 24/42 of 66 -> 24/38 of 62, 2026-09-10, and the sentence is the same
#  ruling as the bare-master row above: FOUR PHANTOM RULES LEAVE THE POPULATION when
#  the noLabel dash is respelled onto the TRAIT rather than onto its DATA. leftBrace,
#  leftParen, rightBrace and rightParen were minted as labelled rules with no rStuff
#  because aCTionTraiT setContent's the modified DatA node onto the trait and
#  setContent does not carry flags (bear-trap #1/#2). Each was refusing by name --
#  "rule-level literal but no rStuff, so LIT vs LITTO is undecidable" -- so they were
#  four rows of the FRONTIER that were never rules at all.
#  ⚠ GREEN IS UNMOVED AT 24 and genLadder/odometer.green is BYTE-UNCHANGED at its
#  18 names, which is what makes this a population correction and not a capability
#  claim: four rules left the population, NONE left the green set, and no surviving
#  row moved in either direction. Any other split would have been a finding.
#  ⚠ leftCurly and rightCurly are STILL IN THE POPULATION ON PURPOSE -- BlocK carries
#  the same respell and is HELD, because it alone regresses iterT1/iterT1m. When BlocK
#  lands this row goes 62 -> 60 with green still 24, and that will be its own sentence.
#  ⚠ RE-PINNED 24/38 -> 28/34 of 62, 2026-09-10, and the sentence is that the modifier
#  two-class ruling made FOUR RULES EMITTABLE. POPULATION UNMOVED AT 62 and green went UP
#  by four -- ScopeXP, StringXP, leftCurly, rightCurly. The two respelled grammar lines'
#  flags now reach their traits, so genParse can plan them. A ratchet moving in the GREEN
#  direction with the population still is the one motion that needs no apology; any other
#  split would have been a finding.
#  ⚠⚠ RE-PINNED 2026-09-15, 28 -> 26, AND THE LOSS IS ACCEPTED BY RULING RATHER THAN
#  ABSORBED. ScopeXP and StringXP stop emitting when the TraiT packet comes off -- each
#  falls to `REFUSE ... inline group / structural data isGROUP`, named, not silent. Tony
#  gated the removal on one grep: are those two rows genParse-only, or does anything live
#  read them. THEY ARE genParse-ONLY. The odometer installs nothing and fires nothing -- it
#  greps genParse's own printed `extern GroupItem parse<rule>(` in a fresh process -- and no
#  fixture that installs a parse method names either rule. They retire with genParse.
#  ⚠ AND THE RATCHET DID NOT FIRE, which is the distinction that makes this a re-pin rather
#  than a stop-the-line: `ratchet 0 previously-green rules regressed`. Neither rule is on
#  genLadder/odometer.green's 18-rule protected list.
diffcheck "genParse odometer (26 green / 36 red of 62 -- RED BY DESIGN, pinned; ratchet monotone)" \
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

#  ⚑ trigDO -- THE NEW PARSE ROAD'S FIRST STANDING COVERAGE. Until 2026-09-09
#  NO FLEET FIXTURE REACHED parseRule AT ALL: the 09-08 H7 control forced
#  ruleAsLabel to 1, refusing EVERY generated parse, and the fleet stayed at 243
#  green, UNMOVED. A green fleet was evidence about nothing on this road.
#  ⚠ THE TWO ARMS ARE EACH OTHER'S ANTI-VACUITY PARTNER, in ONE run and ONE
#  compile. Arm 1 is the good input; arm 2 breaks the `while` term against
#  `xyzzy` and must FAIL. Both print the same generated line with different
#  values, so a road that stopped discriminating fails arm 2 while arm 1 still
#  passes -- which is exactly the failure a single-arm row could not see.
#  ⚠ mintedLen IS THE PARSING-vs-MATCHING LINE. Before ruling B the terms
#  attached into the argument HOLDER and this read 0 on both arms while every
#  other signal looked healthy. A zero here is the road matching and not parsing.
#  ⚠ THE ATTACH COUNT IS PINNED AT EXACTLY 1, NOT "at least 1": arm 2 must not
#  attach. A road that attached on failure would pass every row above this one.
#  H7 CONTROL, RUN 2026-09-09 and recorded rather than run here (it needs a
#  source edit and a rebuild, which pop.sh cannot do). Forcing ruleAsLabel to 1
#  prints `REFUSED DO -- parseRule: the generated body returned a RULE where the
#  chain's truth was owed`, arm 1 reads `chainTrue=1 yielded=0`, the attach count
#  goes to 0, and ALL THREE value rows below go red -- fleet 248/49 -> 245/52.
#  The rows are not vacuous, measured rather than asserted.
#  The all-39 companion that exits 139 by design is incant/trigDO39, and it is
#  DELIBERATELY NOT HERE -- rule H5, a fixture that cannot return deletes the
#  rest of the suite.
run1 trigDO "$T/tdo"; check "trigDO runs" 0 $?
#  ⚠ TWO ROWS ADDED 2026-09-17 WITH THE STATEMENT-BOUNDARY RULING, AND THEY ARE ABOUT
#  THIS FILE'S DEAD REGION RATHER THAN ITS ARMS. trigDO has stop() at line 95 and 425
#  lines of prose below it. While an outstanding refusal silenced command dispatch, that
#  stop() was NEVER ENTERED and the prose was parsed as source -- `RunRulE: expected a
#  method not THE / NEW / PARSE / FIRES`, words out of the prose, at exit 0.
#  ⚠ THE ZERO IS READ WITH THE POSITIVE, NEVER ALONE: a file that died before reaching
#  its dead region also parses none of it. `stop: end parsing` is what says the stop
#  actually fired. docs/refusalScope.md carries the argument.
#  ⚠ AND THIS FIXTURE'S OTHER ROWS ARE RED BY CHOICE (F-62/F-63 family). A red row absorbs
#  new breakage silently, which is why the dead-region facts get their OWN rows here
#  instead of being read off the arms.
if grep -q "stop: end parsing" "$T/tdo"; then
    echo "  ok    trigDO stop() FIRED -- the positive that makes the next row readable"; green=$((green+1))
else
    echo "  FAIL  trigDO stop() never fired -- a refusal is silencing command dispatch again"; fail=1
fi
_tdp=$(grep -cE "RunRulE: expected a method not (THE|NEW|PARSE|FIRES)" "$T/tdo")
if [ "$_tdp" = 0 ]; then
    echo "  ok    trigDO its 425 lines of dead prose are NOT parsed (0) -- read WITH the row above"; green=$((green+1))
else
    echo "  FAIL  trigDO parsed $_tdp lines of its own dead prose as source -- stop() was"
    echo "        not entered and the parse-dead region is live again"; fail=1
fi
sentinel "trigDO sentinel" "$T/tdo" "TRIG SENTINEL -- reached the foot"
if grep -qF "LABELPROBE DO minted=DO mintedLen=2 into=Token chainTrue=1 yielded=1" "$T/tdo"; then
    echo "  ok    trigDO arm 1 GOOD: mintedLen=2 chainTrue=1 yielded=1 -- PINNED BY VALUE (the road PARSES)"; green=$((green+1))
else
    echo "  FAIL  trigDO arm 1 -- the good input did not parse and attach. Actual:"; fail=1
    grep -F "LABELPROBE" "$T/tdo" | sed -n '1p' | sed 's/^/          /'
fi
if grep -qF "LABELPROBE DO minted=DO mintedLen=1 into=Token chainTrue=0 yielded=0" "$T/tdo"; then
    echo "  ok    trigDO arm 2 BROKEN: chainTrue=0 yielded=0 -- the anti-vacuity partner"; green=$((green+1))
else
    echo "  FAIL  trigDO arm 2 -- a broken term did NOT fail the parse. Actual:"; fail=1
    grep -F "LABELPROBE" "$T/tdo" | sed -n '2p' | sed 's/^/          /'
fi
tdoAttach=$(grep -c "attachLabel lab=DO " "$T/tdo")
if [ "$tdoAttach" = "1" ]; then
    echo "  ok    trigDO attached under DO exactly once -- arm 2 did NOT attach"; green=$((green+1))
else
    echo "  FAIL  trigDO attached under DO $tdoAttach times, want exactly 1"; fail=1
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

#  ⚑ bailT -- BAIL LEAVES THE FILE, STOP LEAVES THE PROCESS. Minted 2026-09-15
#  with the verb. bail is registered against the SAME extern as stop
#  (stopParsingInput); the two are told apart by the node handed in, which only
#  works because an empty () stopped handing on the InvokeArg wrapper --
#  ruleActions.handleCall.emptyParens. So these rows cover the TokenXP change
#  as much as the verb.
#  ALL THREE ROWS ARE PRESENCE-WITH-VALUE (H4). The poison below bailInc's bail
#  is never asserted by its ABSENCE from stderr: if it were parsed, the parse
#  failure would abandon the rest of the input and rows A and the sentinel would
#  not print at all. That is the H7 negative control, measured 2026-09-15 on the
#  fixture alone -- bail() deleted gives `RunRulE: expected a method not ANTI`,
#  BAILINC ALIVE still printing, and A and the sentinel GONE, at exit 0.
#  ⚠ BAILINC ALIVE IS THE ANTI-VACUITY ROW AND IS NOT THE ASSERTION: it prints
#  in the control too. It is here so that an include which silently loaded
#  nothing cannot pass row A by default.
run1 bailT "$T/bail"; check "bailT runs" 0 $?
sentinel "bailT sentinel" "$T/bail" "BAILT SENTINEL"
if grep -qF "BAILINC ALIVE" "$T/bail"; then
    echo "  ok    bailT anti-vacuity: the included file really parsed"; green=$((green+1))
else
    echo "  FAIL  bailT anti-vacuity: the include loaded nothing -- rows below mean nothing"; fail=1
fi
if grep -qF "BAILT A: control RETURNED" "$T/bail"; then
    echo "  ok    bail RETURNED to the includer -- bail is not stop"; green=$((green+1))
else
    echo "  FAIL  bail did NOT return to the includer. Either bail exited the"
    echo "        process (it is behaving as stop), or the text below the bail"
    echo "        was parsed and its failure abandoned the run."; fail=1
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
