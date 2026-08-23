#!/bin/bash
# countPop.sh -- THE MINIMAL SURVIVING HARNESS.
# PER-TARGET ISOLATION AND NOTHING FANCIER: one process per installed rule, so a
# single 139 costs one row instead of the whole count. The previous
# compile-everything run died at 12 of 43 and the number was unobtainable.
# H1: the binary is echoed. H2: every row is printed, pass or fail, by name.
INCANT="${INCANT:-$HOME/bin/incant}"
echo "binary: $INCANT"; ls -l "$(readlink "$INCANT" || echo "$INCANT")" | awk '{print "        size "$5"  mtime "$6" "$7" "$8}'
ok=0; bad=0; crash=0
while read -r rule; do
  python3 /tmp/b2/mk.py "$rule"
  out=$("$INCANT" incant/../minionWork/probeOne 2>&1); st=$?
  if [ $st -ne 0 ]; then echo "  CRASH   $rule (exit $st)"; crash=$((crash+1))
  elif echo "$out" | grep -q "ERROR processCode"; then
       echo "  FAIL    $rule -- $(echo "$out" | grep -A1 'ERROR processCode' | tail -1 | sed 's/^ *//')"; bad=$((bad+1))
  elif echo "$out" | grep -q "TARGETDONE $rule"; then echo "  ok      $rule"; ok=$((ok+1))
  else echo "  TRUNC   $rule -- no TARGETDONE, run did not reach it"; crash=$((crash+1)); fi
done < /tmp/b2/rules.txt
echo
echo "THE COUNT: $ok compiled clean, $bad parse-failed, $crash crashed/truncated, of $((ok+bad+crash)) attempted"
