#!/bin/sh
#  fixitNag.sh -- the seal's standing line about Tony's fixit queue.
#
#  GENERATED, NOT REMEMBERED, which is the whole point. A seal line that has to
#  be typed from memory is a seal line that goes stale the first busy day. This
#  reads the directory and nothing else, so the number cannot disagree with the
#  queue.
#
#  Tony's words for the record: forgetting is not an excuse once the seal
#  reminds him to get off the pot.
#
#  Run from the repo root. Paste its one line into the kitchen-pass seal.
D=incant/fixits
if [ ! -d "$D" ]; then echo "Tony's fixit incantations waiting: 0"; exit 0; fi
n=$(ls -1 "$D" 2>/dev/null | wc -l | tr -d ' ')
if [ "$n" = 0 ]; then echo "Tony's fixit incantations waiting: 0"; exit 0; fi
#  ⚠ OLDEST IS BY WHEN THE FILE ENTERED THE QUEUE, NOT BY mtime. An ls -1tr
#  sort reported the NEWEST citizen as the oldest the first day there were two
#  of them, because editing a file makes it look young. The queue-entry date is
#  the ADD commit; a file with no add commit yet is brand new, so it sorts last
#  under the 9999 sentinel and can never be named oldest while a committed one
#  exists.
row=$(for f in "$D"/*; do
    [ -e "$f" ] || continue
    d=$(git log --diff-filter=A -1 --format=%ad --date=short -- "$f" 2>/dev/null)
    [ -z "$d" ] && d="9999-99-99"
    echo "$d $(basename "$f")"
done | sort | head -1)
since=${row%% *}
oldest=${row#* }
[ "$since" = "9999-99-99" ] && since="uncommitted"
echo "Tony's fixit incantations waiting: $n (oldest: $oldest, since $since)"
#  ⚠ THE LANE LINE, added 2026-08-30. It exists so the queue can be ROUTED at a
#  glance instead of read file by file, and it is GENERATED for the same reason
#  the count is: a routing table maintained by hand disagrees with the queue the
#  first time somebody mints a citizen in a hurry.
#
#  ⚠ AND UNSTAMPED IS PRINTED LOUDLY, NEVER SILENTLY OMITTED. A citizen with no
#  LANE would otherwise just be absent from the tally -- the vanished-check
#  failure this project has paid for three times, where the number goes down and
#  nothing says so. If `unstamped` is non-zero the stamps are owed, and the line
#  says which files.
lanes=""; blasts=""; unstamped=""
for f in "$D"/*; do
    [ -e "$f" ] || continue
    l=$(grep -m1 '^LANE:'  "$f" 2>/dev/null | sed 's/^LANE:[ \t]*//')
    b=$(grep -m1 '^BLAST:' "$f" 2>/dev/null | sed 's/^BLAST:[ \t]*//')
    if [ -z "$l" ] || [ -z "$b" ]; then unstamped="$unstamped $(basename "$f")"; continue; fi
    lanes="$lanes$l\n"; blasts="$blasts$b\n"
done
lanerow=$(printf "$lanes" | sort | uniq -c | sort -rn | awk '{c=$1; $1=""; sub(/^ /,""); printf "%s%s %s", (NR>1 ? " . " : ""), $0, c}')
blastrow=$(printf "$blasts" | sort | uniq -c | sort -rn | awk '{c=$1; $1=""; sub(/^ /,""); printf "%s%s %s", (NR>1 ? " . " : ""), $0, c}')
echo "  lanes: $lanerow   |   blast: $blastrow"
if [ -n "$unstamped" ]; then
    echo "  ⚠ UNSTAMPED (lane/blast owed):$unstamped"
fi
echo "  routing: OVERLAPS lands before the recon or rides the migration ledger; DISJOINT holds for the pledged hour"
