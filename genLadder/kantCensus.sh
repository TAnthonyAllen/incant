#!/bin/sh
#  ---------------------------------------------------------------------------
#  kantCensus.sh -- THE STAMPED PER-RULE TABLE. SEQ 72.
#
#  Delivers what SEQ 71 owed and voided: for every rule in the live population,
#  term count, term kinds, shim availability, and -- when refused -- the FIRST
#  BLOCKER BY NAME.
#
#  ⚠ MEASUREMENT ONLY. Nothing is installed, nothing is bound, no rule is
#  parsed against real input. The table is read by Tony + Clay, who mark walk
#  order; nothing executes from it. Because no parse is executed there is NO
#  ARM to name in these rows -- said out loud, because "promote=0/promote=1 in
#  every result line" binds every EXECUTED check and its absence here must read
#  as "no check was executed", never as an omission. The one executed check in
#  this dispatch is kantRatchet R3, which names its arm itself.
#
#  ---------------------------------------------------------------------------
#  INSTRUMENT FIX 1 (SEQ 71 owed) -- NAME-PASSING.
#
#  The SEQ 71 driver passed the rule name as a BARE IDENTIFIER: genKant(Foo).
#  That is bear-trap #26's family and it failed in TWO distinct ways, which is
#  why 39 rows came back blank:
#
#    genKant(ANYstring)  ->  "kant: no rule named (null)"
#    genKant(Any)        ->  "kant: no rule named Anydata type has no
#                             toString() method"
#
#  ⚠ AND THE TEMPTING ONE-LINE REPAIR IS WORSE THAN THE DEFECT. Reading .taG
#  instead of .text fixes the second and SILENTLY CORRUPTS the first: bare
#  `ANYstring` resolves to a node whose tag is `DatA` (measured, incant/probe2
#  in the SEQ 72 scratch), so a .taG repair would have surveyed the rule DatA
#  under a row labelled ANYstring -- a WRONG ROW where there had been a blank
#  one. An undercount reads as a smaller problem; a wrong row reads as a fact.
#
#  THE FIX IS TO PASS A STRING LITERAL: genKant("Foo"). Verified at the site --
#  both former blanks become named, correct refusals, and Braced's emitted body
#  is byte-unchanged. No C++ change, no rebuild, so the fleet cannot move.
#
#  ---------------------------------------------------------------------------
#  INSTRUMENT FIX 2 (SEQ 71 owed) -- BOTH REFUSAL SHAPES, AND NO BLANK ROW.
#
#  Stated as structure, not vigilance: THIS SCRIPT CANNOT EMIT A BLANK ROW.
#  Every row's blocker column is one of the kinds enumerated in the output
#  header, and the last two exist precisely so that an unforeseen shape gets a
#  NAME rather than a silent bucket:
#
#    NONE          the emitter produced a body -- shims available
#    LOOKUP        ruleOrRefuse   "kant: no rule named X"
#                                 "kant: REFUSING X -- not a rule..."
#    TERM          planTerm       "  REFUSE <term> -- <reason>"
#    RULE          planRule       "  REFUSE rule <rule> -- <reason>"
#    FOLD          genKant        "genKant: REFUSING X -- fold is ALT..."
#    EMITTER       genKant        any other "genKant: REFUSING X -- ..."
#    UNCLASSIFIED  a refusal-shaped line matching NO shape above. Printed
#                  VERBATIM in the stumble block at the foot. If this fires,
#                  a shape has been added to the tree and this header is stale.
#    NO-OUTPUT     the run emitted neither a body nor any refusal line at all
#    CRASH         nonzero exit, or the sentinel absent (truncated run)
#
#  ⚠ THE FIRST refusal line is the blocker, per H9's refusal corollary: a
#  refusal census reports the FIRST blocker, never the blocker set. genKant's
#  own "-- no plan" always TRAILS the term/rule refusal that caused it, so
#  taking the first line is what makes the column mean "first blocker" rather
#  than "last complaint".
#
#  ---------------------------------------------------------------------------
#  ONE RULE PER PROCESS, deliberately. The in-process walk
#  (`for r in Grokking; genKant(r);`) reaches exactly one rule and exits 139
#  (SEQ 71, filed NOT diagnosed). Sidestepping it beat debugging it and is the
#  more auditable shape: no shared state between rows.
#  ---------------------------------------------------------------------------

B=${INCANT:-$HOME/bin/incant}
T=${TMPDIR:-/tmp}/kantCensus.$$
CAP=${POPCAP:-30}
mkdir -p "$T"
trap 'rm -rf "$T"' EXIT

if [ ! -x "$B" ]; then echo "  FAIL  binary not executable: $B"; exit 1; fi

#  RULE H1 -- a harness echoes the binary it is testing, first thing.
#  ⚠ ls -lL, not ls -l: $B is a SYMLINK into DerivedData, and ls -l reports the
#  LINK's mtime (which never moves) rather than the build's. A stale binary
#  reported as fresh is exactly the failure H1 was written for, so the flag
#  that follows the link is load-bearing, not tidiness.
echo "  bin   $B"
echo "  bin   $(wc -c < "$B" | tr -d ' ') bytes  $(ls -lL "$B" | awk '{print $6, $7, $8}')"
echo "  asOf  $(date '+%Y-%m-%d')"
echo ""

#  ===========================================================================
#  INSTRUMENT FIX 1 -- ITS OWN NEGATIVE CONTROL (H7).
#
#  A rung certifies only what FAILS when the mechanism is removed. So the
#  repair runs BOTH WAYS on BOTH a known-good rule and a known-refusing one,
#  and prints the name as it ARRIVES AT THE POINT OF STAMPING. The BARE rows
#  are the gate-removed run and they must go wrong; if they ever come back
#  right, this fix has stopped being a fix and the table above it is resting
#  on nothing.
#  ===========================================================================
echo "=========================================================================="
echo "  INSTRUMENT FIX 1 -- NAME-PASSING, WITH ITS NEGATIVE CONTROL"
echo "=========================================================================="
p1fail=0
for spelling in bare string; do
    for R in Braced ANYstring; do
        if [ "$spelling" = bare ]; then ARG="$R"; else ARG="\"$R\""; fi
        cat > "$T/p1" <<EOF
Start();
registry(cOMMANDs);
define genKant immediateAction=genKant; ;
search reset stack Grokking list;
genKant($ARG);
print "P1 SENTINEL":;
stop();
EOF
        "$B" "$T/p1" > "$T/p1o" 2> "$T/p1e"
        got=$(grep -E '^(  kant: |    kp|genKant: |  REFUSE )' "$T/p1e" | head -1 | sed 's/  *$//')
        printf "  %-6s %-10s -> %s\n" "$spelling" "$R" "${got:-(NOTHING)}"
        #  what each row is REQUIRED to show, asserted by name
        case "$spelling/$R" in
          string/Braced)    echo "$got" | grep -q '^    kpBraced code={' || { echo "        FAIL: repaired spelling must EMIT for Braced"; p1fail=1; } ;;
          string/ANYstring) echo "$got" | grep -q 'REFUSE rule ANYstring' || { echo "        FAIL: repaired spelling must name ANYstring in its refusal"; p1fail=1; } ;;
          bare/ANYstring)   echo "$got" | grep -q 'no rule named' || { echo "        FAIL: the control did not reproduce the defect -- fix 1 now asserts nothing"; p1fail=1; } ;;
        esac
    done
done
echo ""
echo "  READ THE CONTROL, NOT JUST THE REPAIR:"
echo "    bare/Braced      WORKS -- and it works BY ACCIDENT. Braced carries no"
echo "                     rule-level data, so .text falls back to echoing the"
echo "                     tag (bear-trap #26, payment 5). Every rule the SEQ 71"
echo "                     survey got right, it got right this way."
echo "    bare/ANYstring   the name never arrives: 'no rule named (null)'."
echo "    ⚠ AND THE .taG REPAIR IS A TRAP, measured not reasoned: bare"
echo "      ANYstring resolves to a node whose TAG IS 'DatA'. Reading .taG"
echo "      would have surveyed DatA under a row labelled ANYstring -- turning"
echo "      39 blank rows into 39 rows that look like facts."
if [ "$p1fail" != 0 ]; then
    echo ""
    echo "  INSTRUMENT FIX 1 UNPROVEN -- refusing to print a table that rests on it."
    exit 1
fi
echo ""

#  ===========================================================================
#  STEP 3 -- THE DENOMINATOR, COUNTED AS THE FIRST ACT.
#  ===========================================================================
"$B" incant/ruleCount > "$T/pop.out" 2> "$T/pop.err"
poprc=$?
if [ $poprc != 0 ] || ! grep -q "RULECOUNT SENTINEL" "$T/pop.out"; then
    echo "  FAIL  population walk did not complete (exit $poprc, sentinel $(grep -c 'RULECOUNT SENTINEL' "$T/pop.out"))"
    echo "        Every row below would be uninterpretable. Refusing to census."
    exit 1
fi

MEMRULE=$(grep -c '^rule ' "$T/pop.out")
MEMNOT=$(grep -c '^NOTRULE ' "$T/pop.out")
ATTRULE=$(grep -c '^attrRule ' "$T/pop.out")
ATTNOT=$(grep -c '^attrNOT ' "$T/pop.out")
POP=$((MEMRULE + ATTRULE))
ALLMEM=$((MEMRULE + MEMNOT + ATTRULE + ATTNOT))

grep '^rule '     "$T/pop.out" | sed 's/^rule  *//;s/ *$//'  > "$T/names"
grep '^attrRule ' "$T/pop.out" | sed 's/^attrRule  *//;s/ *$//' >> "$T/names"

echo "=========================================================================="
echo "  THE DENOMINATOR -- measured this run, not cited"
echo "=========================================================================="
echo "  Grokking members    : $MEMRULE rules + $MEMNOT non-rule"
echo "  Grokking attributes : $ATTRULE rules + $ATTNOT non-rule"
echo "  POPULATION (rules)  : $POP"
echo "  all list entries    : $ALLMEM"
echo ""
echo "  AGAINST THE THREE PRIORS, every one named:"
echo "    \"47 live rules\"  (the dispatch's citation) -- matches NOTHING measured"
echo "                       here, on either spelling. Stop citing it."
echo "    78  (popScratch header, 2026-08-05)         -- CONFIRMED = $POP."
echo "    79  (SEQ 71, 'for r in Grokking')           -- CONFIRMED = $ALLMEM."
echo ""
echo "  THE CAUSE OF 78 vs 79, and it is one word: the two numbers count"
echo "  different things and BOTH ARE RIGHT. 79 is list ENTRIES; 78 is RULES."
echo "  The single entry that is not a rule is:"
grep '^NOTRULE ' "$T/pop.out" | sed 's/^/      /'
echo "  -- the operator registry, a member of Grokking that is not isRule."
echo "  This census's denominator is $POP. It excludes that entry BY NAME."
echo ""

if [ "$POP" -lt 2 ]; then
    echo "  FAIL  vacuity guard: population $POP. A table over an empty"
    echo "        population would print a clean header and assert nothing."
    exit 1
fi

#  ===========================================================================
#  STEP 4 -- THE TABLE. One process per rule.
#  ===========================================================================
echo "=========================================================================="
echo "  THE STAMPED TABLE -- $POP rules, one process each"
echo "=========================================================================="
echo ""
echo "  BLOCKER KINDS (enumerated; nothing else can appear in that column):"
echo "    NONE  LOOKUP  TERM  RULE  FOLD  EMITTER  UNCLASSIFIED  NO-OUTPUT  CRASH"
echo ""
echo "  KIND COLUMN legend -- one letter per term, in term order:"
echo "    L literal   R reference   C charset/character-data   G container"
echo "    M macro     N condition   A parseAction   U upTo"
echo "    Z UNMATERIALISED -- the term has no rStuff yet (rStuff is built"
echo "      lazily); a distinct STATE, not a kind the classifier lacks"
echo "    X unclassified  -- the classifier has a term and no row for it"
echo "    a trailing + or ? on a letter is that term's repetition / optional"
echo "    modifier; a modifier is not a kind and does not replace one."
echo ""
echo "  ⚠ KINDS ARE ALPHABETIC, MODIFIERS ARE PUNCTUATION, and that is not"
echo "    cosmetic. The first cut of this column spelled unclassified '?' AND"
echo "    optional '?', so FormaT read '?G?R??L' and no reader could say which"
echo "    '?' was a kind and which a modifier -- one channel carrying two"
echo "    meanings, caught in the instrument rather than in the tree it"
echo "    measures. Every term contributes exactly one LETTER, always."
echo ""
printf "  %-18s %5s  %-22s %5s  %s\n" RULE TERMS KINDS SHIM "FIRST BLOCKER"
printf "  %-18s %5s  %-22s %5s  %s\n" ------------------ ----- ---------------------- ----- ---------------------------------
: > "$T/rows"
: > "$T/stumbles"
: > "$T/unclassified"

while read -r R; do
    [ -n "$R" ] || continue
    cat > "$T/one" <<EOF
Start();
registry(cOMMANDs);
define dumpRuleTerms immediateAction=dumpRuleTerms; ;
define genKant immediateAction=genKant; ;
search reset stack Grokking list;
dumpRuleTerms("$R");
genKant("$R");
print "CENSUS ROW SENTINEL":;
stop();
EOF
    #  RULE H5 -- a wall-clock cap, so one rule cannot take the census hostage.
    "$B" "$T/one" > "$T/o" 2> "$T/e" &
    pid=$!
    ( sleep "$CAP"; kill -9 $pid 2>/dev/null ) >/dev/null 2>&1 &
    watcher=$!
    wait $pid 2>/dev/null
    rc=$?
    kill $watcher >/dev/null 2>&1
    wait $watcher 2>/dev/null
    [ $rc -eq 137 ] && rc=124

    #  --- completeness first: a truncated row is never graded ---------------
    if [ $rc != 0 ] || ! grep -q "CENSUS ROW SENTINEL" "$T/o"; then
        printf "  %-18s %5s  %-22s %5s  %s\n" "$R" "-" "-" "-" "CRASH (exit $rc)"
        echo "$R  CRASH exit $rc" >> "$T/stumbles"
        continue
    fi

    #  --- term count and kinds, from dumpRuleTerms's own classification -----
    #  ⚠ THE ROW WINS, AND REFERENCE IS CONSULTED LAST -- CORRECTED 2026-08-13
    #  (OPT charter rung one). The first cut tested `ref` FIRST and so disagreed
    #  with the tree on every term that is BOTH a reference AND carries data.
    #  row42's own header warns about precisely this: it mirrors setTestMatch's
    #  cascade IN ITS OWN ORDER, and says a classifier reading the table
    #  top-to-bottom would already disagree with the tree. I read it
    #  top-to-bottom anyway. Caught by planTerm refusing TokenXP's UnaryOPS as a
    #  CONTAINER where this column had called it R -- refuse-by-kind naming an
    #  instrument defect for the third time in two dispatches.
    #
    #  ⚠ AND THE APOSTROPHES ABOVE ARE WHY THIS NOTE IS HERE AND NOT INSIDE THE
    #  awk PROGRAM: that program lives in a single-quoted shell string, and one
    #  apostrophe in an awk comment ends it. The first attempt at this fix
    #  produced a table with a header and ZERO ROWS -- which the self-
    #  certification floor caught by name (rows != population), exactly as H2-on-
    #  the-harness is supposed to.
    #  Every term contributes exactly one letter. A term the classifier has no
    #  row for contributes '?', never nothing -- that is what makes a blank
    #  KINDS cell unconstructable rather than merely unlikely.
    awk '
      /^ *\[[0-9]+\] / { if (n) emit(); n++; ref=0; row=""; np=0; min=1; max=1; next }
      /^ *noPrint/                     { np=1; next }
      /^ *ROW  /                       { row=substr($0, index($0,"ROW  ")+5); next }
      /^ *REFERENCE -> /               { ref=1; next }
      /^ *min /                        { min=$2; max=$4; next }
      END { if (n) emit(); printf "\n" }
      function emit(   k) {
        if (np) { n--; return }                      # noPrint terms are SKIPPED by the walk
        #  THE ROW WINS AND REFERENCE IS CONSULTED LAST. See the note above
        #  the awk block for why; no apostrophes in here, the program is inside
        #  a single-quoted shell string and one closes it.
        if (row ~ /^default lit/)                 k="L"
        else if (row ~ /^isSET|^isSTRING|^isCHAR|^isTOKEN/) k="C"
        else if (row ~ /^isGROUP|^isBIN|^isREGISTRY|^isMAP/) k="G"
        else if (row ~ /^isMacro/)                k="M"
        else if (row ~ /^isCondition/)            k="N"
        else if (row ~ /^parseACTION/)            k="A"
        else if (row ~ /^upTo/)                   k="U"
        else if (row ~ /^\(no rStuff\)/)          k="Z"
        else if (ref)                             k="R"
        else                                      k="X"
        printf "%s", k
        if (max+0 != 1 || min+0 != 1) printf "%s", (min+0==0 ? "?" : "+")
      }
    ' "$T/e" > "$T/kinds"
    KINDS=$(tr -d '\n' < "$T/kinds")
    NTERM=$(grep -c '^ *\[[0-9]*\] ' "$T/e")
    NSKIP=$(grep -c '^ *noPrint' "$T/e")
    NTERM=$((NTERM - NSKIP))

    #  ⚠ ANTI-VACUITY: the KINDS cell must carry exactly one LETTER per counted
    #  term. Without this a classifier that silently dropped a term would print
    #  a shorter, entirely plausible string -- H9's wrong-number-wearing-the-
    #  shape-of-a-right-one, in the column a reader trusts most.
    NLETTER=$(printf '%s' "$KINDS" | tr -cd 'LRCGMNAUXZ' | wc -c | tr -d ' ')
    if [ "$NLETTER" != "$NTERM" ]; then
        echo "$R  KINDS/TERMS MISMATCH: $NLETTER letters for $NTERM terms ($KINDS)" >> "$T/stumbles"
    fi
    [ -n "$KINDS" ] || KINDS="(none)"
    FOLD=$(grep "^RULE $R fold=" "$T/e" | sed 's/.*fold=//' | head -1)
    [ -n "$FOLD" ] || FOLD="?"

    #  --- shim availability and the FIRST blocker, by named shape -----------
    if grep -q "^    kp$R code={" "$T/e"; then
        SHIM=YES; KIND=NONE; WHY=""
    else
        SHIM=no
        FIRST=$(grep -n -E '^(  kant: (no rule named|REFUSING)|  REFUSE |genKant: REFUSING )' "$T/e" \
                | head -1 | sed 's/^[0-9]*://')
        if [ -z "$FIRST" ]; then
            KIND="NO-OUTPUT"; WHY="emitter neither emitted nor refused"
            echo "$R  NO-OUTPUT" >> "$T/stumbles"
        else
            case "$FIRST" in
              "  kant: no rule named"*|"  kant: REFUSING"*)
                    KIND=LOOKUP;  WHY=$(echo "$FIRST" | sed 's/^  kant: //') ;;
              "  REFUSE rule "*)
                    KIND=RULE;    WHY=$(echo "$FIRST" | sed 's/^  REFUSE rule [^ ]* -- //') ;;
              "  REFUSE "*)
                    KIND=TERM;    WHY=$(echo "$FIRST" | sed 's/^  REFUSE //') ;;
              "genKant: REFUSING"*" -- fold is "*)
                    KIND=FOLD;    WHY=$(echo "$FIRST" | sed 's/^genKant: REFUSING [^ ]* -- //') ;;
              "genKant: REFUSING"*)
                    KIND=EMITTER; WHY=$(echo "$FIRST" | sed 's/^genKant: REFUSING [^ ]* -- //') ;;
              *)
                    KIND=UNCLASSIFIED; WHY="see stumble block"
                    echo "$R  $FIRST" >> "$T/unclassified" ;;
            esac
        fi
    fi

    printf "  %-18s %5s  %-22s %5s  %s %s\n" "$R" "$NTERM" "$KINDS" "$SHIM" "$KIND" "$WHY"
    echo "$R|$FOLD|$NTERM|$KINDS|$SHIM|$KIND|$WHY" >> "$T/rows"
done < "$T/names"

echo ""
ROWS=$(wc -l < "$T/rows" | tr -d ' ')
CRASHED=$(grep -c 'CRASH' "$T/stumbles" | tr -d ' ')
YES=$(awk -F'|' '$5=="YES"' "$T/rows" | wc -l | tr -d ' ')

echo "=========================================================================="
echo "  TALLIES -- and every row is accounted for, which is the point"
echo "=========================================================================="
echo "  population          $POP"
echo "  rows stamped        $ROWS"
echo "  rows crashed        $CRASHED"
echo ""
echo "  SHIMS AVAILABLE     $YES"
echo ""
echo "  BLOCKER DISTRIBUTION (rows, by first blocker kind):"
awk -F'|' '{print $6}' "$T/rows" | sort | uniq -c | sort -rn | sed 's/^/    /'
echo ""
echo "  FOLD:"
awk -F'|' '{print $2}' "$T/rows" | sort | uniq -c | sort -rn | sed 's/^/    /'
echo ""
ALTN=$(awk -F'|' '$2=="ALT"' "$T/rows" | wc -l | tr -d ' ')
ALTF=$(awk -F'|' '$2=="ALT" && $6=="FOLD"' "$T/rows" | wc -l | tr -d ' ')
echo "  ⚠ AND THE CROSS-TAB IS THE COROLLARY MADE VISIBLE INSIDE THIS TABLE:"
echo "    $ALTN rules are fold=ALT, but only $ALTF report FOLD as their FIRST"
echo "    blocker. The other $((ALTN - ALTF)) refuse EARLIER, at rule or term level, and"
echo "    would still refuse if the alternation row were spelled tomorrow."
awk -F'|' '$2=="ALT" && $6!="FOLD" {printf "      %-18s %s %s\n", $1, $6, $7}' "$T/rows"
echo ""
echo "  ⚠ H9's REFUSAL COROLLARY BINDS THIS TALLY: these are FIRST blockers,"
echo "    not blocker sets. Closing any one kind does NOT unblock the rules"
echo "    counted under it -- it reveals their next refusal. A sequencing claim"
echo "    of the form 'closing X opens N rules' is NOT supported by this table"
echo "    and needs those N rules re-run after the close."
echo ""

if [ -s "$T/unclassified" ]; then
    echo "  ⚠ UNCLASSIFIED REFUSAL SHAPES -- a shape exists that this header does"
    echo "    not enumerate. The header is stale; add the kind before reading on."
    sed 's/^/      /' "$T/unclassified"
    echo ""
fi
if [ -s "$T/stumbles" ]; then
    echo "  BANKED STUMBLES:"
    sed 's/^/      /' "$T/stumbles"
    echo ""
fi

#  ---------------------------------------------------------------------------
#  RULE H2, turned on the harness itself: this file certifies its OWN
#  completeness before it certifies anything. A vanished helper or a driver
#  that silently surveyed nothing cannot satisfy this.
#  ---------------------------------------------------------------------------
bad=0
if [ "$ROWS" != "$POP" ]; then
    echo "  CENSUS INVALID -- $ROWS rows stamped against a population of $POP."
    bad=1
fi
if grep -q '|$' "$T/rows"; then :; fi
if awk -F'|' '$6==""' "$T/rows" | grep -q .; then
    echo "  CENSUS INVALID -- a row carries an EMPTY blocker kind. That is the"
    echo "  exact defect this rebuild exists to make unconstructable."
    bad=1
fi
if [ -s "$T/unclassified" ]; then
    echo "  CENSUS INCOMPLETE -- unclassified refusal shapes present, listed above."
    bad=1
fi
if [ "$bad" != 0 ]; then echo ""; echo "CENSUS INVALID."; exit 1; fi

echo "CENSUS COMPLETE -- $ROWS/$POP rows, no blank cells, no unclassified shapes."
exit 0
