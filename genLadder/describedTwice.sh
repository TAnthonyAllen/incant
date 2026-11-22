#!/bin/bash
#  describedTwice.sh -- SEQ 742 (Tony, 2026-11-22): a poured row's description is dESCRIPTIONs' entry of the entry's name, and a define
#  under one registry reopens a name it finds, so two files describing one name would overwrite each other silently. This names every
#  name described more than once. It reads the form files (IncantForms/Windows, or the directories given): in each, the lines between a
#  register(dESCRIPTIONs); or registry(dESCRIPTIONs); line and the next register( / registry( line, and of those the entries at the
#  define's own indent, four spaces then name= . Exit 1 and one line a name when any is described twice; exit 0 and a count when none.
cd "$(dirname "$0")/.." || exit 1
DIRS="${@:-IncantForms/Windows}"
T=$(mktemp)
for d in $DIRS; do
    for f in "$d"/*; do
        [ -f "$f" ] || continue
        awk -v f="$f" '
            /^regist(er|ry)\(dESCRIPTIONs\);/ { on=1; next }
            /^regist(er|ry)\(/               { on=0 }
            /^bail\(\);|^stop\(\);/          { on=0 }
            on && match($0, /^    [A-Za-z][A-Za-z0-9]*=/) { n=substr($0, 5, RLENGTH-5); print n "\t" f ":" NR }
        ' "$f"
    done
done > "$T"
total=$(wc -l < "$T" | tr -d ' ')
dups=$(cut -f1 "$T" | sort | uniq -d)
if [ -n "$dups" ]; then
    for n in $dups; do echo "  DESCRIBED TWICE $n -- $(awk -F'\t' -v n="$n" '$1==n{printf "%s ", $2}' "$T")"; done
    rm -f "$T"; exit 1
fi
echo "  ok    describedTwice: $total descriptions, none described twice"
rm -f "$T"; exit 0
