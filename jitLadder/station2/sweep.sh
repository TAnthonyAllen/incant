#!/bin/bash
# sweep.sh cal <index>          -- calibrate one carrier over the pool (restarts past a crash)
# sweep.sh cert <index> <file>  -- certify one carrier on the inputs in <file>
cd "$(dirname "$0")/../.." || exit 1
D=jitLadder/station2
BIN=${INCANT:-$HOME/bin/incant}
T=${T:-$(mktemp -d)}
L=$T/probe.lldb
cat > $L <<L
command script import $PWD/$D/probe.py
breakpoint set -n stopParsingInput -c 'GroupControl::groupController->getRegistry((char*)"Grokking")->get((char*)"DO")->get((char*)"builtinParseR") != 0'
run
probe
kill
quit
L
drive() { PICK=$1 MODE=$2 INPUTS=$3 lldb -b -s $L -- "$BIN" jitLadder/station2/driveS2 2>&1 | grep -E '^(ROW|CARRIERS)'; }
case "$1" in
  cal)
    cp $D/pairs $T/rest.$2; : > $T/cal.$2
    for try in $(seq 1 40); do
        drive $2 cal $T/rest.$2 > $T/out.$2
        grep '^ROW CAL\|^CARRIERS' $T/out.$2 | sed "s/^/try$try /" >> $T/cal.$2
        if grep -q '^ROW CALDONE' $T/out.$2; then break; fi
        k=$(sed -n 's/^ROW CRASH \([0-9]*\) .*/\1/p' $T/out.$2)
        if [ -z "$k" ]; then echo "try$try ROW ABORTED (no CALDONE, no CRASH)" >> $T/cal.$2; break; fi
        grep '^ROW CRASH' $T/out.$2 | sed "s/^/try$try /" >> $T/cal.$2
        tail -n +$((k+2)) $T/rest.$2 > $T/r2 && mv $T/r2 $T/rest.$2
        [ -s $T/rest.$2 ] || break
    done
    cat $T/cal.$2 ;;
  cert) drive $2 cert $3 ;;
esac
