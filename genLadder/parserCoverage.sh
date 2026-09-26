#!/bin/sh
#  parserCoverage.sh -- HOW MUCH OF THE GRAMMAR DOES parser() GENERATE, AND HOW MUCH COMPILES?
#  Run from the Groups directory:   sh genLadder/parserCoverage.sh
#
#  The kant road's coverage row (SEQ 191 stroke 1, 2026-09-26). It replaces the C++ emitter's
#  odometer, which asked how many grammar rules genParse could EMIT. This asks the generator that
#  is alive: for every rule in the grammar, one process runs parser(<rule>) and reads
#    GEN      a "<rule> = CodE {" line -- the generator wrote a body for it
#    COMPILE  "compile succeeded for <rule>"
#    LEAF     "Generating parse code for <rule>" and no body -- a data-bearing leaf, which the
#             generator hands to the leaf executors on purpose (not a failure)
#  and any REFUSED / ERROR line naming the rule. THE RULE IS REACHED BY SUBSCRIPT, parser(Grokking["x"]),
#  never by bare name: break, continue and return are keywords, so `parser(break)` never reached them
#  on trunk (read as "no body") and REFUSED on parse-then-fire's fire-time keyword check -- the
#  harness's own spelling, not coverage (found 2026-09-26 at the branch merge).
#  ONE PROCESS PER RULE because parser() is one-way:
#  a rule already carrying a parse is skipped, so a second root in the same process would hide it.
#
#  THE POPULATION is recomputed from the live registry every run, never read from a file: Grokking
#  members that are not noPrint, not a bin, are rules, and have actionType 0 (the odometer's four
#  filters). A crash or a missing sentinel in any per-rule run is reported BY NAME.
#  H1: echoes the binary. H2: the summary line is reachable only after the last rule.

B=${INCANT:-$HOME/bin/incant}
echo "  bin   $B -> $(ls -l "$B" 2>/dev/null | sed 's/.*-> //')"
T=${TMPDIR:-/tmp}/pcov.$$
mkdir -p "$T"
cat > "$T/pop" <<'KANT'
Start();
include(unitTests);
include(utilities);
search reset stack Grokking UnitTests Utilities list;
register(PcovPop);
define
    pcWalk code={
        iterate pcCur members on *argument;
        while ++pcCur;
            if noPrinT;             continue;
            if binTypE;             continue;
            if !isRulE;             continue;
            if actionTypE != 0;     continue;
            pcEmit(*pcCur);
        };
    pcEmit code={
        print "PCOVPOP" argument.taG:;
        };
    ;
pcWalk(Grokking);
print "PCOVPOP-END":;
stop();
KANT
"$B" "$T/pop" > "$T/pop.o" 2>&1
if ! grep -q "PCOVPOP-END" "$T/pop.o"; then echo "PARSER COVERAGE BROKEN -- the population walk did not finish"; exit 2; fi
RULES=$(grep '^PCOVPOP ' "$T/pop.o" | awk '{print $2}')
n=0; gen=0; comp=0; leaf=0; bad=0
for r in $RULES; do
    n=$((n+1))
    cat > "$T/d" <<KANT
Start();
include(unitTests);
include(utilities);
search reset stack Grokking UnitTests Utilities list;
parser(Grokking["$r"]);
cerr "PCOV SENTINEL":;
stop();
KANT
    perl -e 'alarm 30; exec @ARGV' "$B" "$T/d" > "$T/o" 2> "$T/e"; x=$?
    if [ $x != 0 ] || ! grep -q "PCOV SENTINEL" "$T/e"; then
        echo "  CRASH $r (exit $x, sentinel $(grep -c 'PCOV SENTINEL' "$T/e"))"; bad=$((bad+1)); continue; fi
    g=$(grep -c "^$r = CodE {" "$T/o"); c=$(grep -c "^compile succeeded for $r\$" "$T/o")
    why=$(cat "$T/o" "$T/e" | grep -E "(REFUSED|ERROR)" | grep -F "$r" | head -1 | sed -e 's/  */ /g' -e 's/ *\[line [0-9]*\]//')
    if [ "$g" -gt 0 ] && [ "$c" -gt 0 ]; then gen=$((gen+1)); comp=$((comp+1)); echo "  COMPILES  $r"
    elif [ "$g" -gt 0 ]; then gen=$((gen+1)); echo "  NOCOMPILE $r -- ${why:-no compile line and no refusal naming it}"
    elif grep -q "^Generating parse code for $r" "$T/o" && [ -z "$why" ]; then leaf=$((leaf+1)); echo "  LEAF      $r"
    else echo "  NOBODY    $r -- ${why:-no body and no refusal naming it}"; fi
done
echo "PARSER COVERAGE -- $n rules: $gen generate a body, $comp of them compile; $leaf leaves; $bad crashed"
rm -rf "$T"
