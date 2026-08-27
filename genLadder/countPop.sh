#!/bin/bash
# countPop.sh -- THE MINIMAL SURVIVING HARNESS.
# PER-TARGET ISOLATION AND NOTHING FANCIER: one process per rule, so a single
# 139 costs one row instead of the whole count. The previous
# compile-everything run died at 12 of 43 and the number was unobtainable.
# H1: the binary is echoed. H2: every row is printed, pass or fail, by name.
INCANT="${INCANT:-$HOME/bin/incant}"
echo "binary: $INCANT"; ls -l "$(readlink "$INCANT" || echo "$INCANT")" | awk '{print "        size "$5"  mtime "$6" "$7" "$8}'

#  ---- THE POPULATION IS DERIVED, NEVER READ FROM A FILE --------------------
#  It used to live in /tmp/b2/rules.txt. When that vanished on 2026-08-24 the
#  list was rebuilt by scraping rule names out of the PREVIOUS RUN'S OWN LOG --
#  circular, so it could only ever return what the last run happened to attempt.
#  Measured 2026-08-28: the 42-name file was byte-identical to the names in
#  /tmp/b2/count.out, and it had already drifted, carrying `CodE` (renamed out
#  of existence) and missing `CodeBody`. There is now no file to go stale,
#  because the list IS the population. genLadder/countPopulation computes it.
#  Denominator ruled by Tony 2026-08-28: the odometer's four filters plus one --
#  a rule must HAVE A LIST to be worth compiling a parse body for.
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
"$INCANT" genLadder/countPopulation > "$T/pop.raw" 2>&1
grep '^COUNTPOP ' "$T/pop.raw" | awk '{print $2}' > "$T/rules"
nrules=$(grep -c . "$T/rules")

#  H2 turned on the harness: the population emitter must have reached its own
#  foot. A truncated walk yields a SHORTER list and a smaller, confident
#  headline -- the exact failure this file exists to end.
if ! grep -q 'COUNTPOP-END' "$T/pop.raw"; then
  echo "  FAIL  the population walk did not reach its end marker -- list is truncated"; exit 1
fi
#  Anti-vacuity: zero rules would make every assertion below pass over nothing.
if [ "$nrules" -eq 0 ]; then
  echo "  FAIL  the population is EMPTY -- the harness has no input"; exit 1
fi
echo "rules:  $nrules (derived live from Grokking)"

ok=0; bad=0; crash=0; ghost=0
while read -r rule; do
  python3 genLadder/mkProbeOne.py "$rule"
  out=$("$INCANT" incant/../minionWork/probeOne 2>&1); st=$?
  #  ⚠ `ok` IS SCORED ON THE COMPILE CENSUS, NOT ON TARGETDONE, and that is the
  #  difference between an assertion and a decoration. Measured 2026-08-28 with
  #  a name that never existed: compile prints "REFUSING compile -- no compiled
  #  body" (naming *compile*, not the rule), TARGETDONE prints anyway, the run
  #  exits 0, and the row scored `ok`. A ghost is now its own row instead.
  census=$(echo "$out" | grep -m1 'compile census:')
  if [ $st -ne 0 ]; then echo "  CRASH   $rule (exit $st)"; crash=$((crash+1))
  elif [ -z "$census" ]; then
       echo "  MISSING $rule -- no compile census; compile never took the rule"; ghost=$((ghost+1))
  elif echo "$out" | grep -q "ERROR processCode"; then
       echo "  FAIL    $rule -- $(echo "$out" | grep -A1 'ERROR processCode' | tail -1 | sed 's/^ *//')"; bad=$((bad+1))
  elif echo "$census" | grep -qv '0 refused'; then
       echo "  FAIL    $rule -- $census"; bad=$((bad+1))
  elif echo "$out" | grep -q "TARGETDONE $rule"; then echo "  ok      $rule"; ok=$((ok+1))
  else echo "  TRUNC   $rule -- no TARGETDONE, run did not reach it"; crash=$((crash+1)); fi
done < "$T/rules"

echo
attempted=$((ok+bad+crash+ghost))
echo "THE COUNT: $ok compiled clean, $bad parse-failed, $crash crashed/truncated, $ghost missing, of $attempted attempted"
#  ⚠ A MISSING ROW FAILS THE RUN; A FAIL OR CRASH ROW DOES NOT. That asymmetry
#  is the point, not an oversight. FAIL and CRASH are the FRONTIER -- rules
#  genParse cannot emit yet -- and this harness is red-by-design about them the
#  way the odometer is. MISSING is different in kind: it says a name the
#  POPULATION handed us is one compile never took, so the instrument disagrees
#  with itself. That is never a fact about genParse and must not be reported as
#  one quietly.
if [ "$ghost" -ne 0 ]; then
  echo "  FAIL  $ghost name(s) in the population that compile never took -- the"
  echo "        population and the compiler disagree. This is an instrument"
  echo "        fault, not a frontier row."
  exit 1
fi
if [ "$attempted" -ne "$nrules" ]; then
  echo "  FAIL  attempted $attempted but the population is $nrules -- the run did not cover its input"
  exit 1
fi
echo "COUNTPOP SENTINEL -- $attempted of $nrules attempted, foot reached"
