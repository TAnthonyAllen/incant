#!/bin/bash

#  ip <name> -- resolve a fixture NAME to its path, so the incant/ layout can change
#  without touching a single row label. Falls back to incant/<name> so an unknown name
#  still produces the old error rather than an empty path.
ip () {
    for _d in incant incant/pop incant/pop/jit incant/fixits; do
        [ -f "$_d/$1" ] && { printf '%s\n' "$_d/$1"; return; }
    done
    printf '%s\n' "incant/$1"
}
# ddPop.sh -- THE TRIM GATE, ASSERTED.
#
# THE GATE (ruled 2026-08-23): no designDocs problem record has shed its
# description unless its status is terminal -- remedy or retired-unreproduced
# -- AND its reviewed attribute is past the placeholder token.
#
# The gate is STRUCTURAL, not remembered. incant/ddGate prints the three
# quantities for every record unconditionally; this file compares them.
#
# H1: the binary is echoed before anything is measured.
# H2: a sentinel that only the final section can print, checked by name.
# H7: a negative control -- the gate is shown to go RED when a description is
#     stripped from a non-terminal record, then the file is restored and its
#     md5 is verified byte-identical.

INCANT="${INCANT:-$HOME/bin/incant}"
DD="$(ip designDocs)"
PLACEHOLDER="-- unreviewed --"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
fail=0
green=0
red=0

#  ⚠ THE RED COUNT IS NOT DECORATION, AND IT IS WHAT MAKES THE GREEN COUNT MEAN
#  ANYTHING. This harness has been red for weeks on pre-existing trim-gate
#  violations, and a banner reading only "N green, at least one row red" cannot
#  tell 5-of-5-with-one-known-red from 5-of-10. It went 5 -> 3 on 2026-09-15
#  under a designDocs edit that would not load at all, and said FAILED both
#  times, so the signal arrived and was invisible -- H12's lesson that a red row
#  absorbs new breakage silently. Printing both numbers makes a drop legible
#  without anyone reading the rows underneath it.
#  ⚠ AND IT IS H2 TURNED ON THE HARNESS: green + red is the count of checks that
#  RAN, so a check that EVAPORATES -- the missing-helper family this project has
#  paid for three times -- moves the total, where it used to move nothing a
#  reader could see.
ok ()   { echo "  ok   $1"; green=$((green+1)); }
bad ()  { echo "  FAIL $1"; fail=1; red=$((red+1)); }

echo "=== ddPop.sh -- designDocs trim gate ==="
echo "binary: $INCANT"
ls -l "$(readlink "$INCANT" || echo "$INCANT")" | awk '{print "        size "$5"  mtime "$6" "$7" "$8}'
echo

# ---- gate evaluator: reads GATE lines on stdin, prints violation count ----
gate_violations () {
  awk -F'|' -v ph="$PLACEHOLDER" '
    /^GATE\|/ {
      name=$2; desc=$3; status=$4; reviewed=$5
      gsub(/^[ \t]+|[ \t]+$/,"",name)
      gsub(/^[ \t]+|[ \t]+$/,"",desc)
      gsub(/^[ \t]+|[ \t]+$/,"",status)
      gsub(/^[ \t]+|[ \t]+$/,"",reviewed)
      if (desc == "0") {
        terminal = (status == "remedy" || status == "retired-unreproduced")
        ruled    = (reviewed != ph && reviewed != "0")
        if (!terminal || !ruled) { print "VIOLATION " name " status="status" reviewed="reviewed > "/dev/stderr"; v++ }
      }
    }
    END { print v+0 }'
}

# ---------------- measurement: the tree as it stands ----------------
"$INCANT" "$(ip ddGate)" > "$T/g.out" 2>"$T/g.err"; st=$?
[ $st -eq 0 ] && ok "ddGate exit 0" || bad "ddGate exit $st"
grep -q "DDGATE SENTINEL" "$T/g.out" && ok "ddGate sentinel (no truncation)" || bad "ddGate sentinel MISSING -- run truncated, every row below is uninterpretable"

walked=$(grep "GATECOUNT" "$T/g.out" | awk '{print $NF}')
[ -n "$walked" ] && [ "$walked" -gt 0 ] 2>/dev/null \
  && ok "records walked $walked (anti-vacuity: a gate over zero records asserts nothing)" \
  || bad "records walked reads '$walked' -- the walk found nothing"

v=$(gate_violations < "$T/g.out" 2>"$T/v.err")
if [ "$v" = "0" ]; then ok "trim gate violations 0"
else bad "trim gate violations $v"; cat "$T/v.err"; fi

# ---------------- H7 negative control ----------------
# Strip the description from bt35, whose status is `open` -- non-terminal, so
# the gate MUST catch it. Restore and prove the restore was byte-identical.
echo
echo "  -- H7 negative control: strip a non-terminal record's description --"
before=$(md5 -q "$DD")
cp "$DD" "$T/dd.bak"
python3 - "$DD" <<'PY'
import sys,re
p=sys.argv[1]; s=open(p).read()
i=s.index('        bt35 gloss=')
j=s.index(' description="',i)
k=s.index('";\n',j)
open(p,'w').write(s[:j]+s[k+1:])
PY
"$INCANT" "$(ip ddGate)" > "$T/n.out" 2>/dev/null
nv=$(gate_violations < "$T/n.out" 2>/dev/null)
cp "$T/dd.bak" "$DD"
after=$(md5 -q "$DD")

[ "$nv" != "0" ] && [ -n "$nv" ] \
  && ok "negative control RED as required (violations $nv) -- the gate can fail" \
  || bad "negative control stayed GREEN -- the gate certifies nothing"
[ "$before" = "$after" ] && ok "designDocs restored byte-identical ($before)" \
  || bad "designDocs NOT restored -- was $before now $after"

# ---------------- foot: H2 turned on the harness itself ----------------
echo
if [ "$green" -eq 0 ]; then
  echo "DDPOP FAILED -- zero green checks recorded, so the checks did not run at all"
  exit 1
fi
if [ "$fail" -eq 0 ]; then
  echo "DDPOP PASSED -- $green green, $red red, $((green+red)) checks ran"
  exit 0
fi
echo "DDPOP FAILED -- $green green, $red red, $((green+red)) checks ran"
exit 1
