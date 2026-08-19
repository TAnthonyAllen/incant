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
oldest=$(ls -1tr "$D" | head -1)
since=$(git log -1 --format=%ad --date=short -- "$D/$oldest" 2>/dev/null)
[ -z "$since" ] && since="uncommitted"
echo "Tony's fixit incantations waiting: $n (oldest: $oldest, since $since)"
