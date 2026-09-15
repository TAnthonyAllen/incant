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

    #  ⚠ CLASS FILES HAVE NO `extern` AND USED TO REPORT "BROKEN". Added 2026-09-15
    #  with the GroupItem.twk sweep. A class method is a column-0 signature whose
    #  NEXT line is a bare `{`, which is tok's house style and is what makes the
    #  one-line lookahead exact rather than a guess.
    #
    #  ⚠⚠ TWO CARVE-OUTS, BOTH DELIBERATE AND BOTH NAMED IN THE OUTPUT SO NOBODY
    #  READS THEM AS A BUG. A CONSTRUCTOR IS NOT ALPHABETISED -- it shares the
    #  class's name, so sorting it would bury GroupItem() in the g's; constructors
    #  lead the file and are skipped here. AND THE FILE-SCOPE REGION IS ITS OWN RUN:
    #  functions after the class close are a separate alphabetical sequence, so the
    #  first one must not be reported as "after" the class's last method. Depth is
    #  counted on lines that are EXACTLY `{` or `}` -- tok's body style -- so the
    #  class close is the one that takes depth 1 to 0, and a `-- group --` marker
    #  resets the comparison there.
    if [ -z "$names" ]; then
        cls=$(basename "$f" | sed 's/\..*//')
        names=$(awk -v cls="$cls" '
            /^class[ \t]/ { inclass = 1 }
            $0 == "{" { depth++ ; next }
            $0 == "}" { depth-- ; if (inclass && depth == 0) { print "0 -- group --"; inclass = 0 } ; next }
            /^[A-Za-z_~][A-Za-z0-9_ \*&]*\(.*\)[ \t]*$/ {
                sig = $0; ln = NR
                if ((getline nxt) > 0) {
                    if (nxt == "{") {
                        if (match(sig, /[A-Za-z_][A-Za-z0-9_]*[ \t]*\(/)) {
                            nm = substr(sig, RSTART, RLENGTH)
                            sub(/[ \t]*\($/, "", nm)
                            if (nm != cls) print ln " " nm
                        }
                    }
                    if (nxt == "{") depth++
                    else if (nxt == "}") depth--
                }
                next
            }
        ' "$f")
    fi

    count=$(printf '%s\n' "$names" | grep -c '^[0-9]* [A-Za-z_]')
    [ "$count" -lt 2 ] && continue

    breaks=$(printf '%s\n' "$names" | awk '
        $2 == "--" { prev = "" ; next }
        prev != "" && tolower($2) < tolower(prev) { print "    " $1 "\t" $2 "\tafter " prev }
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

#   ⚠ UNIT SHAPE (Tony's ruling, 2026-09-07). THE UNIT IS header + declaration,
#   and A BLANK LINE IS THE ONLY BOUNDARY. A comment block separated from its
#   declaration by a blank line is NOT part of the method, so the next sort
#   leaves it behind -- which is exactly how genParse.rtn came to have TEN
#   headers documenting the wrong function, four of them sitting AFTER their
#   own method. This is checked HERE because alphaLint is what runs before a
#   sort, and a header with a blank line under it is the state in which sorting
#   orphans it. Zero on every future sort is the certificate that the rule holds.
UNITBREAKS=0
for f in $FILES; do
    [ -f "$f" ] || continue
    _u=$(awk '
        /^extern [A-Za-z]/ {
            if (prev == "" && prev2 ~ /(\*\/|^[[:space:]]*\/\/)/) {
                name=$0; sub(/\(.*/,"",name); n=split(name,a," "); print FILENAME": "a[n]
            }
        }
        { prev2=prev; prev=$0 }
    ' "$f")
    if [ -n "$_u" ]; then
        echo "$_u" | while read -r r; do echo "  UNIT BROKEN (blank line between header and declaration): $r"; done
        UNITBREAKS=$(( UNITBREAKS + $(echo "$_u" | wc -l | tr -d ' ') ))
    fi
done

echo "alphaLint -- $TOTALFILES file(s) examined, $TOTALBREAKS out-of-order method(s), $UNITBREAKS broken unit(s)"
[ "$QUIET" = 1 ] && [ "$TOTALBREAKS" -gt 0 ] && exit 1
[ "$UNITBREAKS" -gt 0 ] && exit 1
exit 0
