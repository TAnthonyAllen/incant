#!/bin/bash
# Jit the generated parse bodies (builtinParseR carriers) reachable from DO.
#   recon.sh list        -- enumerate carriers, index and rule name
#   recon.sh one <n>     -- jit carrier n in its own process (IR dumped)
#   recon.sh each        -- every carrier, one process each, one summary line per rule
#   recon.sh all         -- every carrier in ONE process (exposes name collisions)
# Stops at stopParsingInput once DO has its carrier, then drives jitRunAction from
# lldb -- testing() cannot reach a carrier, which is not isCoded.
# ⚠ Read DEGRADE lines from "jitRunAction: entering" on, never from lldb's
# PICK line: the Python print lands AFTER the process's own stderr.
cd "$(dirname "$0")/../.." || exit 1
D=jitLadder/carrierRecon
BIN=${INCANT:-$HOME/bin/incant}
ls -lL "$BIN" | awk '{print "binary:", $NF, $5, $6, $7, $8}'
T=$(mktemp -d)
cat > $T/r.lldb <<L
command script import $PWD/$D/walk.py
breakpoint set -n stopParsingInput -c 'GroupControl::groupController->getRegistry((char*)"Grokking")->get((char*)"DO")->get((char*)"builtinParseR") != 0'
run
carriers
kill
quit
L
run() { lldb -b -s $T/r.lldb -- "$BIN" $D/driveDO; }
case "$1" in
  list) run 2>&1 | grep '^CARRIER' ;;
  one)  JIT_PICK=$2 INCANT_JIT_DUMP=1 run 2>&1 | sed -n '/jitRunAction: entering/,$p' ;;
  all)  JIT_ALL=1 run 2>&1 | grep 'ALLRESULT\|addIRModule failed' ;;
  each) n=$(run 2>&1 | grep '^CARRIERS' | awk '{print $2}')
        for i in $(seq 0 $((n-1))); do JIT_PICK=$i run > $T/$i.out 2>&1 & 
            (( (i+1) % 8 == 0 )) && wait; done; wait
        for i in $(seq 0 $((n-1))); do f=$T/$i.out
            t=$(grep -o 'PICKRESULT [0-9]* "[^"]*"' $f | cut -d' ' -f3)
            k=$(sed -n '/jitRunAction: entering/,$p' $f | grep -o 'DEGRADE #[0-9]*: [^-]*' | sed 's/DEGRADE #[0-9]*: //; s/ *$//' | paste -sd'|' -)
            echo "$i $t :: ${k:-none}"; done
        echo "RECON SENTINEL $n carriers" ;;
  *) echo "usage: recon.sh list|one <n>|each|all"; exit 2 ;;
esac
rm -rf $T
