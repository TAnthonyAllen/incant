#!/bin/sh
#  FORMS POP -- the drawing surface.  Run from the Groups directory:
#      sh genLadder/formsPop.sh
#
#  WHY THIS EXISTS, and it is not tidiness. dsFill/dsFillJ were fixtures with NO
#  HARNESS -- forms was the only arc without a pop.sh. Nothing regression-checked
#  `displayFill` when the next drawing command landed, which is the difference
#  between adding a command and adding one WITHOUT SILENTLY BREAKING THE LAST
#  ONE. Every later command adds its rows here; that is the deal.
#
#  ⚠ ASSERTS PIXELS, NOT EXIT STATUS. A drawing POP that checks exit 0 checks
#  that nothing crashed, which is not the same as anything being drawn. Every
#  row below compares an RGBA quadruple read back out of the bitmap.
#
#  ⚠ AND EVERY ZERO-EXPECTING ROW HAS A NON-ZERO SIBLING. `r0 g0 b0 a0` is what
#  an undrawn bitmap gives, so a before-row alone distinguishes nothing; it earns
#  its place only against the after-row beside it.
#
#  ⚠ $? IS TAKEN DIRECTLY, NEVER THROUGH A PIPE -- ${PIPESTATUS[0]} is silently
#  empty in zsh and reports every run as passing.
#
#  ⚠ EVERY HELPER THIS FILE CALLS IS DEFINED IN THIS FILE, and the foot
#  certifies ITSELF: a run that records zero green checks FAILS, because a
#  vanished helper set cannot satisfy it. Third instance of copy-the-idiom-lose-
#  the-helper in this tree; the structural answer is a harness that checks its
#  own pulse.

B=${INCANT:-$HOME/bin/incant}

#  ip <name> -- resolve a fixture NAME to its path, so the incant/ layout can change
#  without touching a single row label. Falls back to incant/<name> so an unknown name
#  still produces the old error rather than an empty path.
ip () {
    for _d in incant incant/pop incant/pop/jit incant/fixits; do
        [ -f "$_d/$1" ] && { printf '%s\n' "$_d/$1"; return; }
    done
    #  missingFixtureLoud (joined the seal 2026-11-07): a name that resolves nowhere FAILS BY NAME, as pop.sh's does
    printf '  FAIL  fixture MISSING: %s -- not in incant, incant/pop, incant/pop/jit, incant/fixits\n' "$1" >&2
    mkdir -p "$T" && : > "$T/.missingFixture.$1"
    printf '%s\n' "incant/$1"
}

T=${TMPDIR:-/tmp}/formspop.$$
mkdir -p "$T"
fail=0
green=0

check () {                      # check <name> <expected-exit> <actual-exit>
    if [ "$2" = "$3" ]; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 (exit $3)"; fail=1; fi
}
sentinel () {                   # sentinel <name> <file> <text>
    if grep -qF "$3" "$2"; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 -- THE RUN TRUNCATED. A statement stopped parsing and"
         echo "        every statement after it was silently dropped, at exit 0."; fail=1; fi
}
#  pixel <name> <file> <occurrence> <node> <expected "r# g# b# a#">
#  Reads the Nth pixelAt line for that node and compares the whole quadruple.
pixel () {
    _got=$(grep -F "=== pixelAt $4 " "$2" | sed -n "$3p" | sed 's/.*= //; s/ ===.*//')
    if [ -z "$_got" ]; then
        echo "  FAIL  $1 -- NO pixelAt line $3 for $4 at all (the read never ran)"; fail=1
    elif [ "$_got" = "$5" ]; then echo "  ok    $1 ($_got)"; green=$((green+1))
    else echo "  FAIL  $1 -- got [$_got] want [$5]"; fail=1; fi
}
#  _ofeq / fdRow -- pop.sh's two row helpers, carried with the drawing rows that moved here (2026-11-07). fdRow pins today's
#  value beside the intended one: green when they agree, "born red" while today still reads the pinned value.
_ofeq () { if [ "$2" = "$3" ]; then echo "  ok    $1 = [$3]"; green=$((green+1)); else echo "  FAIL  $1 -- got [$2] want [$3]"; fail=1; fi; }
fdRow () {
    if [ "$2" = "$4" ]; then echo "  ok    $1 = [$2]"; green=$((green+1))
    elif [ "$2" = "$3" ]; then echo "  FAIL  $1 born red (SEQ 345): today [$2], intended [$4]"; fail=1
    else echo "  FAIL  $1 MOVED: reads [$2], pinned today [$3], intended [$4]"; fail=1; fi
}
hasmark () {                    # hasmark <name> <file> <text>
    if grep -qF "$3" "$2"; then echo "  ok    $1"; green=$((green+1))
    else echo "  FAIL  $1 -- marker '$3' absent"; fail=1; fi
}

POPCAP=${POPCAP:-90}
_cap () {
    _p=$!
    { ( sleep "$POPCAP"; kill -9 $_p 2>/dev/null ) >/dev/null 2>&1 & } 2>/dev/null
    _w=$!
    wait $_p; _ec=$?
    { kill $_w 2>/dev/null; wait $_w 2>/dev/null; } 2>/dev/null
    if [ $_ec = 137 ]; then
        echo "  FAIL  $1 TIMED OUT after ${POPCAP}s -- KILLED, not failed. Its"
        echo "        capture is TRUNCATED, so every row below would name the"
        echo "        wrong thing. Fix the hang first."
        fail=1; return 124
    fi
    return $_ec
}
run2 () { $B "$(ip "$1")" > "$2" 2> "$3" & _cap "$1"; }

#  RULE H1 -- a harness echoes the binary it is testing, FIRST. A stale binary
#  does not fail as a diff, it hangs.
echo "  bin   $B"
if [ -e "$B" ]; then
    echo "  bin   $(wc -c < "$B" | tr -d ' ') bytes  $(date -r "$B" '+%b %e %H:%M')"
else echo "  FAIL  binary $B DOES NOT EXIST"; fail=1; fi
echo ""

echo "-- displayFill, INTERPRETED (dsFill)."
run2 dsFill "$T/f.o" "$T/f.e"
check    "dsFill runs" 0 $?
sentinel "dsFill sentinel (no truncation)" "$T/f.o" "DSFILL SENTINEL"
pixel "before the fill -- an undrawn bitmap"   "$T/f.o" 1 dsCanvas "r0 g0 b0 a0"
pixel "after the fill -- red through the style" "$T/f.o" 2 dsCanvas "r255 g0 b0 a255"

echo "-- SEAM 3 IS A NAMED-COMPONENT READ (SG). The H7 control."
#  A style carrying strokeColor and NO fillColor. If seam 3 read the style's own
#  text -- the degenerate slot this replaced -- or took whatever component it
#  found, this would fill anyway and the conversion would be asserted by nothing.
pixel   "no fillColor -> nothing drawn" "$T/f.o" 1 dsNoFill "r0 g0 b0 a0"
hasmark "no fillColor -> REFUSES BY NAME" "$T/f.e" \
        "displayFill: REFUSING dsNoFill -- its style names no fillColor component"

echo "-- displayFill, JITTED (dsFillJ). Compiled once, fired twice."
run2 dsFillJ "$T/j.o" "$T/j.e"
check    "dsFillJ runs" 0 $?
sentinel "dsFillJ sentinel (no truncation)" "$T/j.o" "DSFILLJ SENTINEL"
#  ROUTING FIRST (bear-trap #25): testing() routes by isCoded, and an interpreted
#  run consumes it -- after which testing() silently falls to jitRunIfTest, the
#  control-flow smoke test, and measures THE WRONG ENGINE at exit 0.
hasmark "entered jitRunAction, not jitRunIfTest" "$T/j.o" \
        "=== jitRunAction: entering on djFill ==="
pixel "before any fill"                        "$T/j.o" 1 djCanvas "r0 g0 b0 a0"
pixel "fire 1 -- compiled, style djStyle"      "$T/j.o" 2 djCanvas "r255 g0 b0 a255"
#  ⚠ THE PROOF. Under jitting the interpreter runs the body FOR REAL at emit
#  time, so a correct pixel after one fire proves nothing -- the emit-time pass
#  could have painted it. Fire 2 recompiles NOTHING and the STYLE NODE was
#  swapped after emission. If the pixel tracks it, the fill ran from compiled
#  code. The two fires want DIFFERENT ANSWERS, not merely different inputs.
pixel "fire 2 -- NO recompile, style swapped" "$T/j.o" 3 djCanvas "r0 g128 b128 a255"
#  H4: presence-with-value. Asserting "no degrade message appeared" would go
#  green the day the message is deleted.
#  RED SINCE 2026-10-19, KNOWN REGRESSION, docs/fixIts.md F-149: SEQ 384's jitOpEmits admits only jitTrace among
#  commands, so displayFill's own emitter is never reached and the call runs at run time (degrade count 1).
hasmark "degrade count 0 (nothing fell through to emit-time)" "$T/j.o" \
        "jitDegrade count = 0"
hasmark "exactly one compile across both fires" "$T/j.o" "jitCompile count = 1"

echo ""
echo "-- the page: step 1 toward the first PDF (moved from pop.sh, 2026-11-07, Tony: drawing rows live here)."
#  ⚑ fillPageT -- step 1 toward the first PDF (Tony, 2026-11-07, SEQ ___ R1): the top field opens one context; fill draws into it at
#  page coordinates for the top and every child; the y flip is set once, on the top context. PINNED BEFORE THE BUILD, born red.
#  FP-5 and FP-6 are a pair on one field: with the flip removed they swap. The refusal count sits beside the child pixels.
_fpF=$(ip fillPageT)
perl -e 'alarm 20; exec @ARGV' "$B" "$_fpF" > "$T/fp.o" 2> "$T/fp.e"; _fpx=$?
_fpp () { grep -h '^=== pixelAt '"$1"' ' "$T/fp.o" "$T/fp.e" 2>/dev/null | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/' | tr '\n' '/'; }
_ofeq "fillPageT exit / sentinel" "$_fpx $(grep -c '^FILLPAGE SENTINEL' "$T/fp.e")" "0 1"
fdRow "fillPageT FP-1 firstLight at (300,450) paints wall at its own top-left, page (5,5)" "$(_fpp firstLight)" "r0 g0 b0 a0/" "r247 g232 b170 a255/"
fdRow "fillPageT FP-2 a child, words, paints white inside its frame, page (5,100)" "$(_fpp words)" "" "r255 g255 b255 a255/"
fdRow "fillPageT FP-3 just above words, page (5,29), reads wall: the child's fill stays inside" "$(_fpp heading)" "" "r247 g232 b170 a255/"
fdRow "fillPageT FP-4 just below words, page (5,166), reads wall" "$(_fpp bar)" "" "r247 g232 b170 a255/"
fdRow "fillPageT FP-5 the flip: the band at the top of the form paints the top of the bitmap, page (5,2)" "$(_fpp fpBand)" "" "r175 g211 b120 a255/"
fdRow "fillPageT FP-6 the flip's pair: the bottom of the form reads wall, page (5,97)" "$(_fpp fpRest)" "" "r247 g232 b170 a255/"
#  FP-7 (SEQ ___ R0 rider 2): the display is handed down as a property (+<), so the form's definition is unchanged: a child's list length before and after makeDisplay.
_fpl () { grep "^FP LEN $1 " "$T/fp.e" | sed "s/^FP LEN $1 *//" | xargs; }
fdRow "fillPageT FP-7 the handed-down display is a property: words and bar keep their list length across makeDisplay" "$(_fpl words) / $(_fpl bar)" "6 7 / 7 8" "6 6 / 7 7"
fdRow "fillPageT a child takes the top's context: no child refuses no display" "$(grep -c 'REFUSING .* no display' "$T/fp.e")" "2" "0"

echo "-- the draw walk: step 2 toward the first PDF."
#  ⚑ drawWalkT -- step 2 toward the first PDF (Tony, 2026-11-07): utilities' drawWalk, parent before child, fills each field
#  that names a fill and skips the rest. PINNED BEFORE THE BUILD, born red. DW-4 is the depth row; the refusal count is paired with DW-2 and DW-4.
_dwF=$(ip drawWalkT)
perl -e 'alarm 20; exec @ARGV' "$B" "$_dwF" > "$T/dw.o" 2> "$T/dw.e"; _dwx=$?
#  _dwp the FIRST read of a field (DW-1 to DW-4); _dwpr reads N to M of the same field (DW-5, DW-6 read edges after them)
_dwp () { grep -h '^=== pixelAt '"$1"' ' "$T/dw.o" "$T/dw.e" 2>/dev/null | head -1 | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/' | tr '\n' '/'; }
_dwpr () { grep -h '^=== pixelAt '"$1"' ' "$T/dw.o" "$T/dw.e" 2>/dev/null | sed -n "$2,$3p" | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/' | tr '\n' '/'; }
_ofeq "drawWalkT exit / sentinel" "$_dwx $(grep -c '^DRAWWALK SENTINEL' "$T/dw.e")" "0 1"
#  RE-PIN (SEQ ___ R1, 2026-11-08): "today" was "" because drawWalkT registered neither makeDisplay nor pixelAt, so no pixel was read at all;
#  with both in incant/setup the display opens and reads empty until drawWalk exists. Intended values unchanged.
fdRow "drawWalkT DW-1 heading has no fill: the top's wall shows, page (5,15)" "$(_dwp heading)" "r0 g0 b0 a0/" "r247 g232 b170 a255/"
fdRow "drawWalkT DW-2 words, depth 1, white, page (5,100)" "$(_dwp words)" "r0 g0 b0 a0/" "r255 g255 b255 a255/"
fdRow "drawWalkT DW-3 space, depth 2, no fill: wall, page (100,180)" "$(_dwp space)" "r0 g0 b0 a0/" "r247 g232 b170 a255/"
fdRow "drawWalkT DW-4 ok, depth 2, lightGreen, page (360,180)" "$(_dwp ok)" "r0 g0 b0 a0/" "r175 g211 b120 a255/"
#  forms step 2 R2 (2026-11-08): the right way up, each side of an edge; a flipped child lands 5 points off and fails a pair
#  BORDERS REGISTERED (forms step 3, before the build): DW-5 and DW-6 move with the border by design -- (5,29) is heading's bottom row,
#  (399,199) and (341,165) lie on ok's edges. Width sits inside the frame (Tony), so nothing outside a field's frame is painted.
fdRow "drawWalkT DW-5 words' edges (5,29) (5,31) (5,164) (5,166): wall white white wall; (5,29) becomes heading's bottomBorder" "$(_dwpr words 2 5)" "r247 g232 b170 a255/r255 g255 b255 a255/r255 g255 b255 a255/r247 g232 b170 a255/" "r0 g0 b0 a255/r255 g255 b255 a255/r255 g255 b255 a255/r247 g232 b170 a255/"
fdRow "drawWalkT DW-6 ok's edges (339,190) (341,190) (399,199) (341,165) (341,164); (399,199) and (341,165) become ok's border" "$(_dwpr ok 2 6)" "r247 g232 b170 a255/r175 g211 b120 a255/r175 g211 b120 a255/r175 g211 b120 a255/r255 g255 b255 a255/" "r247 g232 b170 a255/r175 g211 b120 a255/r0 g0 b0 a255/r0 g0 b0 a255/r255 g255 b255 a255/"
_dwcnt () { grep -h '^=== pixelAt '"$1"' ' "$T/dw.o" "$T/dw.e" 2>/dev/null | sed -n "$2,$3p" | grep -c "$4"; }
fdRow "drawWalkT DW-7 ok's plain border, inside / outside: left (340,180) (339,180), top (360,165) (360,164), right (399,180) (398,180), bottom (360,199) (360,198)" "$(_dwpr ok 7 14)" "r175 g211 b120 a255/r247 g232 b170 a255/r175 g211 b120 a255/r255 g255 b255 a255/r175 g211 b120 a255/r175 g211 b120 a255/r175 g211 b120 a255/r175 g211 b120 a255/" "r0 g0 b0 a255/r247 g232 b170 a255/r0 g0 b0 a255/r255 g255 b255 a255/r0 g0 b0 a255/r175 g211 b120 a255/r0 g0 b0 a255/r175 g211 b120 a255/"
fdRow "drawWalkT DW-8 heading's bottomBorder: inside (5,29) black, outside (5,30) white" "$(_dwpr heading 2 3)" "r247 g232 b170 a255/r255 g255 b255 a255/" "r0 g0 b0 a255/r255 g255 b255 a255/"
_ofeq "drawWalkT DW-9 heading's other three sides unpainted: pixels not wall / pixels read (top row, left and right columns above the bottom row)" "$(_dwcnt heading 4 461 'r247 g232 b170 a255' | awk '{print 458-$1}')/$(grep -h '^=== pixelAt heading ' "$T/dw.o" | sed -n '4,461p' | wc -l | tr -d ' ')" "0/458"
fdRow "drawWalkT DW-9 heading's bottom row painted: black pixels / pixels read (y=29, x 0..399)" "$(_dwcnt heading 462 861 'r0 g0 b0 a255')/$(grep -h '^=== pixelAt heading ' "$T/dw.o" | sed -n '462,861p' | wc -l | tr -d ' ')" "0/400" "400/400"
fdRow "drawWalkT DW-10 width 3, own strokeColor=blue: left (0..3,10), top (10,0..3) -- three painted, the fourth not" "$(_dwpr dwThick 1 8)" "r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/" "r0 g81 b186 a255/r0 g81 b186 a255/r0 g81 b186 a255/r255 g255 b255 a255/r0 g81 b186 a255/r0 g81 b186 a255/r0 g81 b186 a255/r255 g255 b255 a255/"
fdRow "drawWalkT DW-11 colour from the style (dwSt strokeColor red): (0,5) painted, (1,5) not" "$(_dwpr dwStyled 1 2)" "r255 g255 b255 a255/r255 g255 b255 a255/" "r239 g43 b45 a255/r255 g255 b255 a255/"
_ofeq "drawWalkT DW-12 x past the width refuses by name, and no pixel line for it (ok's reads stay 14)" "$(grep -c '^pixelAt: ok (400,180) OUT OF RANGE' "$T/dw.e") $(grep -h '^=== pixelAt ok ' "$T/dw.o" | wc -l | tr -d ' ')" "1 14"
fdRow "drawWalkT a field with no fill is skipped, not refused: refusals during the walk, beside words' pixel (anti-vacuity)" "$(sed -n '/^DW walk begins/,/^DW walk ends/p' "$T/dw.e" | grep -c 'REFUS') $(_dwp words)" "0 r0 g0 b0 a0/" "0 r255 g255 b255 a255/"

echo "-- the first PDF: step 4."
#  ⚑ firstPdfT -- forms step 4 (Tony, 2026-11-08): openPDF / drawWalk / closePDF, then readPDF draws page 1 into a bitmap
#  for pixelAt. REGISTERED ON TRUNK BEFORE THE BUILD: each row pinned at today's value, the intended beside it. The file is
#  deleted first, so a stale one cannot pass. H7 (the walk skipped): the file rows hold, the page reads blank.
_pdF=$(ip firstPdfT)
_pdO=IncantForms/PDF/output.pdf
rm -f "$_pdO"
perl -e 'alarm 20; exec @ARGV' "$B" "$_pdF" > "$T/pd.o" 2> "$T/pd.e"; _pdx=$?
_pdp () { grep -h '^=== pixelAt pdfRead ' "$T/pd.o" "$T/pd.e" 2>/dev/null | sed -n "$1,$2p" | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/' | tr '\n' '/'; }
_ofeq "firstPdfT exit / sentinel" "$_pdx $(grep -c '^FIRSTPDF SENTINEL' "$T/pd.e")" "0 1"
fdRow "firstPdfT the file exists and begins %PDF" "$([ -s "$_pdO" ] && head -c 4 "$_pdO" || echo none)" "none" "%PDF"
fdRow "firstPdfT readPDF: one page, firstLight's frame (400 x 200 points)" "$(grep '^=== readPDF pdfRead' "$T/pd.o" "$T/pd.e" 2>/dev/null | sed 's/.*pdfRead //; s/ ===.*//')" "" "pages 1 size 400x200"
fdRow "firstPdfT PD-1 read back: heading (5,15) wall, words (5,100) white, space (100,180) wall, ok (360,180) lightGreen" "$(_pdp 1 4)" "" "r247 g232 b170 a255/r255 g255 b255 a255/r247 g232 b170 a255/r175 g211 b120 a255/"
fdRow "firstPdfT PD-2 read back: ok's border left (340,180) black / (339,180) wall, top (360,165) black / (360,164) white" "$(_pdp 5 8)" "" "r0 g0 b0 a255/r247 g232 b170 a255/r0 g0 b0 a255/r255 g255 b255 a255/"
fdRow "firstPdfT PD-3 read back: heading's bottom line (5,29) black, (5,30) white" "$(_pdp 9 10)" "" "r0 g0 b0 a255/r255 g255 b255 a255/"
fdRow "firstPdfT PD-4 read back, the right way up: (5,31) white, (5,166) wall" "$(_pdp 11 12)" "" "r255 g255 b255 a255/r247 g232 b170 a255/"

#  missingFixtureFoot every fixture a row ran must have existed
for _mf in "$T"/.missingFixture.*; do
    [ -e "$_mf" ] || continue
    echo "  FAIL  fixture MISSING: ${_mf##*.missingFixture.} -- every row that ran it measured nothing"; fail=1
done
echo ""
#  RULE H2 TURNED ON THE HARNESS ITSELF. A green count is a tally of the checks
#  that RAN; a check that evaporates because a helper went missing is INVISIBLE
#  in it, since nobody knows what the number should have been.
if [ "$green" -lt 1 ]; then
    echo "FORMS POP FAILED -- ZERO green checks were recorded."
    echo "  That is not 'everything failed'. It is almost certainly a HELPER that"
    echo "  does not exist: the shell prints 'command not found' to stderr and"
    echo "  carries on, so the checks did not pass and did not fail -- they"
    echo "  ceased to exist. Check check/sentinel/pixel/hasmark are all defined."
    fail=1
fi
if [ $fail = 0 ]; then echo "FORMS POP PASSED -- $green checks, displayFill interpreted + jitted"
else echo "FORMS POP FAILED -- $green green, see above"; fi
rm -rf "$T"
exit $fail
