#!/bin/sh
#  =========================================================================
#  mixed.sh — SEQ 41 STEP 2. THE PARSE-ARM DISPATCH FIXTURE.
#
#  THE QUESTION TONY'S MIGRATION-UNIT RULING WAITS ON. jitXmutual proved
#  dispatch uniformity for ACTION calls; the fork inside parse() is the
#  uncovered leg:
#
#      definer  = definingRule();
#      defStuff = definer.rStuff;
#      if defStuff && defStuff.parseMethod { ... generated ... }
#      ... interpretive ...
#
#  Structurally the caller never sees that fork -- parseR does
#  `bridge.label = into; term.parse(bridge)` and parse() picks its OWN arm.
#  But this project's standing asymmetry says structural claims survive and
#  causal ones are a coin flip, and "the caller cannot tell" is a causal
#  claim about OBSERVABLE BEHAVIOUR, not about the branch. So it gets run.
#
#  ⚠⚠ WHY THIS IS A DECOMPOSITION AND NOT A MIXED-CONFIG SMOKE TEST.
#  "Does a mixed config parse?" is nearly vacuous -- it would pass on a
#  system where installing one rule silently corrupted its neighbour's
#  subtree, because SOMETHING would still come out. The real question is
#  whether a rule's install perturbs ONLY ITSELF:
#
#      diff(ALL installed, NONE installed)
#          ==  diff(A only) + diff(ALT only) + diff(OUT only)   ?
#
#  EQUAL     -> divergence is LOCAL AND COMPOSABLE. No interaction term.
#               A rule can cross alone; the mixed-shape world is safe;
#               IA-0's migration unit can shrink from the ALTERNATION to
#               the RULE, and IA-1's gate loses its premise.
#  NOT EQUAL -> there is an INTERACTION TERM. Installs are entangled,
#               IA-0 stands as written, and the residue names the seam.
#
#  Either answer is a finding. That is the point of running it.
#
#  ⚠ THE KNOWN DIVERGENCE IS NOT A FAILURE HERE. genLadder/tree.divergence
#  records that the generated arm does not promote (PC-1 passes promote=0)
#  while the interpretive arm does, so the inner node reads ScafA/ScafI
#  generated and ScafALT interpretive. That is the §2.4 retag question,
#  OPEN and the director's. This fixture asks a DIFFERENT question about
#  the same divergence: not "is it right" but "is it LOCAL".
#
#  H1: echoes the binary. H2: a summary line reachable only through the
#  last comparison. H5: every run under a wall-clock cap.
#  =========================================================================
B=${INCANT:-$HOME/bin/incant}
T=${TMPDIR:-/tmp}/genmixed.$$
CAP=${POPCAP:-90}
mkdir -p "$T"
fail=0
green=0

if [ ! -x "$B" ]; then echo "  FAIL  binary not executable: $B"; exit 1; fi
echo "  bin   $B"
echo "  bin   $(ls -lL "$B" | awk '{print $5" bytes  "$6" "$7" "$8}')"
echo ""

#  run <variant-file> <outfile> -- capped, exit status taken from the binary
#  itself and never through a pipe (${PIPESTATUS[0]} is silently empty in zsh
#  and reports every run as passing; that one bit two agents in a day).
run () {
    $B "$1" > "$2.raw" 2>&1 &
    _p=$!
    { ( sleep "$CAP"; kill -9 $_p 2>/dev/null ) >/dev/null 2>&1 & } 2>/dev/null
    _w=$!
    wait $_p; _ec=$?
    { kill $_w 2>/dev/null; wait $_w 2>/dev/null; } 2>/dev/null
    sed -n '/^TREE /,$p' "$2.raw" | grep -vE "^Search list:|^stop:" > "$2"
    return $_ec
}

#  strip <rule-suffix> -- remove ONE rule's install binding.
#  ⚠ THE TRAILING SEMICOLON IN THE MATCH IS LOAD-BEARING: `parseScafA` is a
#  PREFIX of `parseScafALT`, so a bare name would disable both and the
#  "ScafA only" variant would silently be "ScafA and ScafALT". That is the
#  kind of instrument error this project keeps paying for -- an overcount
#  reads as a bigger problem, never as a broken instrument (RULE H9).
strip () {                      # strip <file> <methodname>
    sed -e "/parseMethod=$2;/ s/ parseTerms=[0-9]*//" \
        -e "/parseMethod=$2;/ s/ parseMethod=$2//" "$1"
}

SRC=incant/treeScratch

#  ---- the four variants -------------------------------------------------
#  NONE: every install stripped. The interpretive baseline.
strip "$SRC" parseScafA   > "$T/s1"
strip "$T/s1" parseScafI  > "$T/s2"
strip "$T/s2" parseScafALT > "$T/s3"
strip "$T/s3" parseScafOUT > "$T/v_none"

#  ALLGEN: the file as committed, every rule installed.
cp "$SRC" "$T/v_all"

#  LEAF: only ScafA/ScafI installed (ALT and OUT interpretive).
strip "$SRC" parseScafALT  > "$T/s4"
strip "$T/s4" parseScafOUT > "$T/v_leaf"

#  ALT: only ScafALT installed.
strip "$SRC" parseScafA    > "$T/s5"
strip "$T/s5" parseScafI   > "$T/s6"
strip "$T/s6" parseScafOUT > "$T/v_alt"

#  OUT: only ScafOUT installed.
strip "$SRC" parseScafA    > "$T/s7"
strip "$T/s7" parseScafI   > "$T/s8"
strip "$T/s8" parseScafALT > "$T/v_out"

#  ⚠ ANTI-VACUITY GUARD ON THE STRIPPER ITSELF. If `strip` silently matched
#  nothing, every variant would be the committed file and all five diffs
#  would be empty -- and an all-empty result reads as "perfectly composable",
#  the strongest possible PASS, produced by an instrument that did nothing.
#  That is this project's signature failure and it gets a guard, not a hope.
#  ⚠ THE PATTERN IS `parseMethod=parse`, NOT `parseMethod=`, AND THE FIRST
#  VERSION GOT THIS WRONG -- it counted 5 because treeScratch's own header
#  COMMENT says "`parseMethod=` on an alternation's own line runs BEFORE its
#  members exist". A census that matches PROSE is RULE H9's exact failure, and
#  the guard caught its own instrument rather than the thing it was guarding.
#  Left recorded because the lesson is the value: the census matches the IDIOM
#  FAMILY (a binding is `=parse<Something>`), never the surface form.
nAll=$(grep -c 'parseMethod=parse' "$T/v_all")
nNone=$(grep -c 'parseMethod=parse' "$T/v_none")
if [ "$nAll" = "4" ] && [ "$nNone" = "0" ]; then
    echo "  ok    stripper works: ALL has 4 bindings, NONE has 0"; green=$((green+1))
else
    echo "  FAIL  STRIPPER BROKEN -- ALL has $nAll bindings (want 4), NONE has $nNone (want 0)."
    echo "        Every diff below would be vacuous. Refusing to report them."
    rm -rf "$T"; exit 1
fi

#  ---- run them ----------------------------------------------------------
for v in none all leaf alt out; do
    run "$T/v_$v" "$T/t_$v"; ec=$?
    if [ $ec = 137 ]; then
        echo "  FAIL  variant '$v' TIMED OUT after ${CAP}s -- KILLED, not failed."
        echo "        Its capture is truncated; no diff below it names the right row."
        fail=1
    elif [ $ec != 0 ]; then
        echo "  FAIL  variant '$v' exited $ec"
        echo "        ⚠ A CRASH IN A MIXED VARIANT IS ITSELF THE ANSWER: it would mean"
        echo "        installs are not independently safe, which is IA-0's premise"
        echo "        holding. Read the capture before treating this as harness noise."
        fail=1
    else
        echo "  ok    variant '$v' ran clean (exit 0)"; green=$((green+1))
    fi
    if [ ! -s "$T/t_$v" ]; then
        echo "  FAIL  variant '$v' produced NO TREE OUTPUT -- a diff against it would"
        echo "        compare nothing to nothing and pass. (H4's other half.)"
        fail=1
    fi
done

if [ $fail != 0 ]; then
    echo ""
    echo "MIXED FIXTURE FAILED before the decomposition -- see the rows above."
    rm -rf "$T"; exit 1
fi

#  ---- the decomposition -------------------------------------------------
#  ⚠⚠ THE FIRST VERSION OF THIS SECTION COMPARED A SUM OF DIFFS AGAINST THE
#  ALL-INSTALLED DIFF, AND ITS ANSWER WAS RIGHT WHILE ITS OUTPUT WAS USELESS:
#  a diff-of-diffs residue is not readable by a human, and an instrument whose
#  verdict cannot be read is one step from an instrument that is not believed.
#  The finding was plain in the TREES the whole time. So the assertion moved to
#  where the evidence is: THE CHILD NODE UNDER ScafOUT, BY NAME.
#
#  This is RULE H4 in its strongest form -- presence WITH VALUE. "Is there a
#  child" and "which child" are one question here, and the failure mode this
#  catches is a node that VANISHES, which an absence-based check would have
#  scored as agreement between two empty subtrees.

childOf () {                    # childOf <treefile> <input>  -> the child tag, or NONE
    awk -v want="TREE $2" '
        $0 == want         { inb = 1; next }
        inb && /^TREE /    { exit }
        inb && /ScafOUT/   { seen = 1; next }
        inb && seen && NF  { gsub(/^[ \t]+/, ""); print; exit }
    ' "$1" | head -1
}

echo ""
echo "  --- trees ---"
for v in none leaf alt out all; do
    echo "  [$v]"
    sed 's/^/      /' "$T/t_$v"
done

echo ""
echo "  --- THE CHILD UNDER ScafOUT, per variant and per input ---"
echo "      variant   installed rules              '(a)'      '(i)'"
lost=""
for v in none leaf alt out all; do
    ca=$(childOf "$T/t_$v" "(a)"); [ -z "$ca" ] && ca="NONE"
    ci=$(childOf "$T/t_$v" "(i)"); [ -z "$ci" ] && ci="NONE"
    case $v in
      none) who="(interpretive baseline)";;
      leaf) who="ScafA ScafI            ";;
      alt)  who="ScafALT                ";;
      out)  who="ScafOUT                ";;
      all)  who="ScafA ScafI ScafALT OUT";;
    esac
    printf "      %-9s %s  %-9s %-9s\n" "$v" "$who" "$ca" "$ci"
    if [ "$ca" = "NONE" ] || [ "$ci" = "NONE" ]; then lost="$lost $v"; fi
done

echo ""
#  THE UNIFORMITY ASSERTION. Every variant must produce a child; WHICH child it
#  is remains the OPEN S2.4 retag question and is deliberately NOT asserted here
#  (tree.divergence owns that, and pinning it twice would make one of the two
#  pins a liar the day the question is ruled).
#  ⚠⚠ THIS FIXTURE IS PINNED TO THE DEFECT, NOT TO THE FIX (RULE H6).
#  The measured answer on 2026-08-08 is that `leaf` and `alt` lose the child.
#  Pinning that keeps the fleet INTERPRETABLE -- a permanently-red harness is
#  one nobody reads, and an unread harness is worse than none. The pin goes RED
#  the day the behaviour changes IN EITHER DIRECTION, which is the whole point:
#  good news must arrive as a red, or it arrives as nothing.
PINNED_LOST=" leaf alt"

if [ "$lost" = "$PINNED_LOST" ]; then
    echo "  ok    PINNED: partial installs 'leaf' and 'alt' LOSE THE CHILD NODE."
    echo "        ⚠ THIS IS A GREEN ROW REPORTING A DEFECT. SEQ 41 step 2's answer"
    echo "        is NO -- parse-arm dispatch is NOT uniform, and IA-0 STANDS."
    echo "        Both PURE configurations keep the child (interpretive ScafALT,"
    echo "        all-generated ScafA/ScafI per tree.divergence); a MIXED one drops"
    echo "        it, at exit 0, with no diagnostic."
    echo "        LEAD, not a ruling: IA-2's silent return generalised -- the"
    echo "        generated arm's promote=0 meets a label-transparent parent whose"
    echo "        label is null, and the promote case that rescues it"
    echo "        interpretively sits on the OTHER arm."
    echo "        ⚠ jitXmutual's ACTION-dispatch uniformity is real and does NOT"
    echo "        extend here. Two forks, two answers -- which is exactly why the"
    echo "        migration-unit ruling was fenced behind this fixture."
    green=$((green+1))
elif [ -z "$lost" ]; then
    echo "  FAIL  ⚠ WOKE -- NO VARIANT LOSES THE CHILD ANY MORE."
    echo "        Good news arriving as a red, which is this pin working. Parse-arm"
    echo "        dispatch now looks uniform, so SEQ 41 step 2 is LIVE AGAIN and"
    echo "        Tony's migration-unit ruling is unblocked. GRADUATE this row to a"
    echo "        positive assertion (H6) and re-pin with a sentence naming the"
    echo "        cause -- a target that moved is a claim that the world changed."
    fail=1
else
    echo "  FAIL  PIN MOVED -- variants losing the child are '$lost', pinned"
    echo "        '$PINNED_LOST'. The defect changed SHAPE rather than going away."
    echo "        Re-measure all five variants before re-pinning; a partial change"
    echo "        here means the seam moved, not that it closed."
    fail=1
fi


#  ⚠ H2 TURNED ON THE HARNESS ITSELF: a summary reachable with zero green
#  checks recorded cannot certify anything, and a vanished helper set is
#  exactly how that happens (three occurrences in this project's ledger).
echo ""
if [ "$green" -lt 1 ]; then
    echo "MIXED FIXTURE FAILED -- FOOT REACHED WITH NO GREEN CHECKS RECORDED."
    fail=1
fi
#  ⚠ THE BANNER SAYS WHAT WAS MEASURED, NOT WHAT WAS HOPED FOR. Its first
#  wording read "dispatch uniform, divergence local" -- inherited from the
#  version written before the answer came back, and the exact opposite of this
#  fixture's finding. A harness whose SUMMARY LINE contradicts its own verdict
#  is the worst instrument failure available, because the banner is the only
#  line most readers see. Caught on the first pinned run; recorded because a
#  green banner is not evidence about the rows above it.
if [ $fail = 0 ]; then echo "MIXED FIXTURE PASSED ($green checks) -- PIN HOLDS: parse-arm dispatch is NOT uniform (SEQ 41 step 2 answered NO; IA-0 stands)."
else echo "MIXED FIXTURE FAILED ($green green before the verdict) -- see the verdict above."; fi
rm -rf "$T"
exit $fail
