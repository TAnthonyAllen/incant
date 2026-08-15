#!/bin/bash
#   alphaLint.sh -- HYGIENE TIER. Reports methods that are out of alphabetical
#   order within their file. REPORT ONLY: it never reorders anything, and it is
#   deliberately NOT wired into pop.sh -- a style drift must never be able to
#   fail the correctness gate.
#
#   Standing rule (Tony, 2026-08-15): new methods go into existing code in
#   alphabetical order.
#
#   Usage:  ./genLadder/alphaLint.sh [file ...]      (default: every top-level
#                                                     .rtn plus Generate.rtn)
#   Exit:   0 always for the default sweep (report tier).
#           Pass -q to exit 1 when any file is out of order.

cd "$(dirname "$0")/.." || exit 2

QUIET=0
[ "$1" = "-q" ] && { QUIET=1; shift; }

FILES="$*"
[ -z "$FILES" ] && FILES=$(ls *.rtn 2>/dev/null)

TOTALFILES=0
TOTALBREAKS=0
CHECKED=0

for f in $FILES; do
    [ -f "$f" ] || continue
    CHECKED=$((CHECKED + 1))

    #  Definitions only: column-0 `extern <Type> <name>(`. Prototypes end in `;`
    #  on the same line and are excluded; comment text is excluded by column 0.
    names=$(grep -n '^extern[ 	]' "$f" | grep -v ';[ 	]*$' \
            | sed -E 's/^([0-9]+):extern[ 	]+[A-Za-z_][A-Za-z_0-9]*[ 	]*\*?[ 	]*([A-Za-z_][A-Za-z_0-9]*)[ 	]*\(.*/\1 \2/' \
            | grep -E '^[0-9]+ [A-Za-z_]')

    count=$(printf '%s\n' "$names" | grep -c .)
    [ "$count" -lt 2 ] && continue

    breaks=$(printf '%s\n' "$names" | awk '
        NR > 1 && tolower($2) < tolower(prev) { print "    " $1 "\t" $2 "\tafter " prev }
        { prev = tolower($2) }')

    n=$(printf '%s\n' "$breaks" | grep -c .)
    TOTALFILES=$((TOTALFILES + 1))
    if [ "$n" -eq 0 ]; then
        printf '  ok    %-20s %3d methods, in order\n' "$f" "$count"
    else
        printf '  OUT   %-20s %3d methods, %d out of order\n' "$f" "$count" "$n"
        printf '%s\n' "$breaks"
        TOTALBREAKS=$((TOTALBREAKS + n))
    fi
done

#   SELF-CERTIFICATION (H2 turned on the harness): a run that examined nothing
#   must not print a clean banner. A vanished extractor reports zero files, and
#   zero files is a failure, not a pass.
if [ "$TOTALFILES" -eq 0 ]; then
    echo "ALPHALINT BROKEN -- examined $CHECKED file(s) and extracted NO method lists."
    exit 2
fi

echo "alphaLint -- $TOTALFILES file(s) examined, $TOTALBREAKS out-of-order method(s)"
[ "$QUIET" = 1 ] && [ "$TOTALBREAKS" -gt 0 ] && exit 1
exit 0
