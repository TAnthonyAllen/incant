#!/bin/bash
# countPop.sh -- THE MINIMAL SURVIVING HARNESS.
# PER-TARGET ISOLATION AND NOTHING FANCIER: one process per installed rule, so a
# single 139 costs one row instead of the whole count. The previous
# compile-everything run died at 12 of 43 and the number was unobtainable.
# H1: the binary is echoed. H2: every row is printed, pass or fail, by name.
INCANT="${INCANT:-$HOME/bin/incant}"
echo "binary: $INCANT"; ls -l "$(readlink "$INCANT" || echo "$INCANT")" | awk '{print "        size "$5"  mtime "$6" "$7" "$8}'
#  H4 -- THE HARNESS ASSERTS ITS OWN INPUT, WITH ITS VALUE, UNCONDITIONALLY.
#  Both inputs used to live in /tmp/b2 and neither was in the repository, so a
#  reboot turned this harness into one that reads a short or empty list, runs
#  the rows it was handed, and prints a SMALLER headline in the same confident
#  wording -- and a smaller number of failures reads as progress. There was no
#  row in the output saying how many rules there ARE, so a run over three rules
#  and a run over forty-two were typographically identical.
#  Relocating the files makes that less likely; only the assertion makes it
#  VISIBLE. Print the list length by name, then refuse to call the run complete
#  unless the attempted total equals it.
#  ⚠ THE OTHER HALF IS NOT BUILT AND IS NAMED RATHER THAN IMPLIED: this checks
#  the list against what was ATTEMPTED, never against the LIVE POPULATION. A
#  list that is complete-but-stale still passes. incant/fixits/countInputInTmp
#  prints the live count and is the instrument for that question.
RULES="${RULES:-genLadder/countRules.txt}"
if [ ! -s "$RULES" ]; then
  echo "  FAIL  rule list $RULES is missing or empty -- the harness has no input"; exit 1
fi
nrules=$(grep -c . "$RULES")
echo "rules:  $nrules (from $RULES)"
ok=0; bad=0; crash=0
while read -r rule; do
  python3 genLadder/mkProbeOne.py "$rule"
  out=$("$INCANT" incant/../minionWork/probeOne 2>&1); st=$?
  if [ $st -ne 0 ]; then echo "  CRASH   $rule (exit $st)"; crash=$((crash+1))
  elif echo "$out" | grep -q "ERROR processCode"; then
       echo "  FAIL    $rule -- $(echo "$out" | grep -A1 'ERROR processCode' | tail -1 | sed 's/^ *//')"; bad=$((bad+1))
  elif echo "$out" | grep -q "TARGETDONE $rule"; then echo "  ok      $rule"; ok=$((ok+1))
  else echo "  TRUNC   $rule -- no TARGETDONE, run did not reach it"; crash=$((crash+1)); fi
done < "$RULES"
echo
attempted=$((ok+bad+crash))
echo "THE COUNT: $ok compiled clean, $bad parse-failed, $crash crashed/truncated, of $attempted attempted"
if [ "$attempted" -ne "$nrules" ]; then
  echo "  FAIL  attempted $attempted but the rule list holds $nrules -- the run did not cover its input"
  exit 1
fi
echo "COUNTPOP SENTINEL -- $attempted of $nrules attempted, foot reached"
