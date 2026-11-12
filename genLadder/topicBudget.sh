#!/bin/sh
#  TOPIC BUDGET -- one line per topic file: name, lines, budget, and OVER by how many.
#  Run from the Groups directory:  sh genLadder/topicBudget.sh
#  Ruled 2026-11-11 (Tony, SEQ 621 R1; Topics/cleanup, Plan 1). Report tier: a size never fails a seal, so this
#  always exits 0. PROSE LINES ONLY (Tony, 2026-11-12): a topic file that is also an incantation (Topics/forms) is counted from
#  the line after its first bail(); or stop();, so the code above that line is not charged to the budget. A file with neither is counted whole.
#  It still exits 0. A file that is over is trimmed at the next session on its topic. The budgets are Tony's to change.
row () {
    if [ -f "$1" ]; then _n=$(awk '/^(bail|stop)\(\);/ && !c { c = NR } END { print NR - c }' "$1")
    else echo "  MISSING  $1"; return; fi
    if [ "$_n" -gt "$2" ]; then echo "  $1  $_n / $2  OVER by $((_n - $2))"
    else echo "  $1  $_n / $2"; fi
}
row docs/wakeup.md        60
row Topics/forms          280
row Topics/drawing        160
row Topics/kant           200
row Topics/typesetting    120
row Topics/cleanup        120
row Topics/documentation  120
row Topics/features       80
exit 0
