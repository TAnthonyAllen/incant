#!/bin/bash
#  kantGrammarNames.sh -- SEQ 436 R3 (2026-10-27): the new grammar's names against the RUNNING registries, not a source grep.
#  incant/probes/kantGrammarNames dumps every registry's members (the `registries` registry walked, kantGrammar NOT loaded);
#  incant/probes/kantGrammarLoad loads incant/kantGrammar and lists what it registered. Population: the top-level members
#  of every registry the runtime keeps -- GroupFields, Keywords, cOMMANDs, Operators among them. Controls first (H16):
#  TOKENize and if MUST be found, If must NOT be (the convention depends on case). Exit 1 on a control or a collision.
cd "$(dirname "$0")/.." || exit 2
B=${INCANT:-$HOME/bin/incant}
echo "  bin   $B  $(ls -laL "$B" | awk '{print $5" bytes  "$6" "$7" "$8}')"
T=${TMPDIR:-/tmp}/kgnames.$$; mkdir -p "$T"
"$B" incant/probes/kantGrammarNames > "$T/dump" 2>&1; xd=$?
"$B" incant/probes/kantGrammarLoad > "$T/load" 2>&1; xl=$?
fail=0
[ $xd = 0 ] && grep -q '^KG SENTINEL' "$T/dump" || { echo "  FAIL  dump run: exit $xd, sentinel $(grep -c '^KG SENTINEL' "$T/dump")"; fail=1; }
[ $xl = 0 ] && grep -q '^KGLOAD SENTINEL' "$T/load" || { echo "  FAIL  load run: exit $xl, sentinel $(grep -c '^KGLOAD SENTINEL' "$T/load")"; fail=1; }
#  registry <TAB> member, from the dump
awk '$1=="KGR"{r=$2} $1=="KGM"{print r"\t"$2}' "$T/dump" > "$T/pairs"
nreg=$(grep -c '^KGR' "$T/dump"); nmem=$(wc -l < "$T/pairs" | tr -d ' ')
echo "  population: $nreg registries, $nmem members (kantGrammar not loaded)"
where () { awk -F'\t' -v n="$1" '$2==n{printf "%s%s", s, $1; s=","}' "$T/pairs"; }
ctl () { w=$(where "$1"); if [ "$2" = found ] && [ -n "$w" ]; then echo "  ok    control $1 found ($w)"
         elif [ "$2" = absent ] && [ -z "$w" ]; then echo "  ok    control $1 not found"
         else echo "  FAIL  control $1 wanted $2, got [${w:-none}] -- STOP"; fail=1; fi; }
ctl TOKENize found; ctl if found; ctl If absent
#  the renamed rules + the registry's own name: none may be found
NEW="EXPRESSIOn STATEMENt ELSe SHORTCUt ANYSTRINg BLOCk BRANCHEs PRECISIOn FORMAt PRINTXp PRINTFIELd ITERSOURCe INVOKEARg
BRACEd PARENs ANYORNUm TOKEn STRINGXp SCOPEFIELd LOOPEr LOOPRESTRICt BASICELSe ELSEIf WARDEd DEBUg DEf Do If FOr WHILe
PRINt CERr COUt SEARCh BRANCh SCOPEXp XPRESs ITERATe STARt KantGrammar"
nn=0; nc=0
for n in $NEW; do nn=$((nn+1)); w=$(where "$n"); [ -n "$w" ] && { echo "  FAIL  COLLISION $n in $w"; nc=$((nc+1)); fail=1; }
    grep -qE "^(KGNEW|KGKID) +$n *$" "$T/load" || [ "$n" = KantGrammar ] || { echo "  FAIL  $n not registered by the load"; fail=1; }; done
echo "  new names: $nn looked up, $nc collisions"
#  copied with their spellings unchanged, and referenced shared names: found, each a known choice
for n in break continue return loopOnAttributes loopOnMembers; do echo "  known  copied unrenamed: $n in [$(where $n)]"; done
for n in TOKENize DEFINing PRINTing ANYtoken followedBy NamE NumbeR QuotE SemI GrouP define counter Operators; do
    echo "  known  shared: $n in [$(where $n)]"; done
#  informational: a new name whose spelling differs from a live name only in case -- by design under R0, not a failure
for n in $NEW; do l=$(echo "$n" | tr A-Z a-z); awk -F'\t' -v l="$l" -v n="$n" 'tolower($2)==l && $2!=n{printf "  case   %s ~ %s (%s)\n", n, $2, $1}' "$T/pairs"; done
rm -rf "$T"
[ $fail = 0 ] && echo "KANTGRAMMAR NAMES PASSED" || echo "KANTGRAMMAR NAMES FAILED"
exit $fail
