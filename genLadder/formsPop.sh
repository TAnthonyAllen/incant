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
#  RE-PIN (SEQ 584, an unregistered mover caught at the certificate): R2 gives words align=justify, one more attribute, so its list
#  length is 7, not 6; the row's question -- unchanged across makeDisplay -- still reads equal both sides (7 7).
fdRow "fillPageT FP-7 the handed-down display is a property: words and bar keep their list length across makeDisplay" "$(_fpl words) / $(_fpl bar)" "6 7 / 7 8" "7 7 / 7 7"
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
#  RE-AIM (SEQ 582, forms step 5, 2026-11-09): text now draws in heading and ok, over (5,15) and (360,180). These rows ask about FILL, so the point
#  moves off the text, to (300,15) and (390,190), where the same fill shows; pinned values unchanged.
fdRow "drawWalkT DW-1 heading has no fill: the top's wall shows, page (300,15)" "$(_dwp heading)" "r0 g0 b0 a0/" "r247 g232 b170 a255/"
fdRow "drawWalkT DW-2 words, depth 1, white, page (5,100)" "$(_dwp words)" "r0 g0 b0 a0/" "r255 g255 b255 a255/"
fdRow "drawWalkT DW-3 space, depth 2, no fill: wall, page (100,180)" "$(_dwp space)" "r0 g0 b0 a0/" "r247 g232 b170 a255/"
fdRow "drawWalkT DW-4 ok, depth 2, lightGreen, page (390,190)" "$(_dwp ok)" "r0 g0 b0 a0/" "r175 g211 b120 a255/"
#  forms step 2 R2 (2026-11-08): the right way up, each side of an edge; a flipped child lands 5 points off and fails a pair
#  BORDERS REGISTERED (forms step 3, before the build): DW-5 and DW-6 move with the border by design -- (5,29) is heading's bottom row,
#  (399,199) and (341,165) lie on ok's edges. Width sits inside the frame (Tony), so nothing outside a field's frame is painted.
#  SEQ 583 (heading 43, colour in firstLight), REGISTERED BEFORE THE FORM CHANGE: DW-5, DW-8, DW-9 (both), PD-3, PD-4 re-aimed to heading's new
#  bottom edge y=42 (they keep asking about heading's border and words' top); DW-6, DW-7, PD-2 move as ok's border turns red (strokeColor:=red).
fdRow "drawWalkT DW-5 words' edges (5,42) (5,44) (5,164) (5,166): heading's bottomBorder, white, white, wall" "$(_dwpr words 2 5)" "r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r247 g232 b170 a255/" "r0 g0 b0 a255/r255 g255 b255 a255/r255 g255 b255 a255/r247 g232 b170 a255/"
fdRow "drawWalkT DW-6 ok's edges (339,190) (341,190) (399,199) (341,165) (341,164); (399,199) and (341,165) are ok's border, red" "$(_dwpr ok 2 6)" "r247 g232 b170 a255/r175 g211 b120 a255/r0 g0 b0 a255/r0 g0 b0 a255/r255 g255 b255 a255/" "r247 g232 b170 a255/r175 g211 b120 a255/r239 g43 b45 a255/r239 g43 b45 a255/r255 g255 b255 a255/"
_dwcnt () { grep -h '^=== pixelAt '"$1"' ' "$T/dw.o" "$T/dw.e" 2>/dev/null | sed -n "$2,$3p" | grep -c "$4"; }
fdRow "drawWalkT DW-7 ok's plain border, inside / outside: left (340,180) (339,180), top (360,165) (360,164), right (399,180) (398,180), bottom (360,199) (360,198); inside red" "$(_dwpr ok 7 14)" "r0 g0 b0 a255/r247 g232 b170 a255/r0 g0 b0 a255/r255 g255 b255 a255/r0 g0 b0 a255/r175 g211 b120 a255/r0 g0 b0 a255/r175 g211 b120 a255/" "r239 g43 b45 a255/r247 g232 b170 a255/r239 g43 b45 a255/r255 g255 b255 a255/r239 g43 b45 a255/r175 g211 b120 a255/r239 g43 b45 a255/r175 g211 b120 a255/"
fdRow "drawWalkT DW-8 heading's bottomBorder: inside (5,42) black, outside (5,43) white" "$(_dwpr heading 2 3)" "r255 g255 b255 a255/r255 g255 b255 a255/" "r0 g0 b0 a255/r255 g255 b255 a255/"
fdRow "drawWalkT DW-9 heading's other three sides unpainted: pixels not wall / pixels read (top row, left and right columns y 0..41)" "$(_dwcnt heading 4 487 'r247 g232 b170 a255' | awk '{print 484-$1}')/$(grep -h '^=== pixelAt heading ' "$T/dw.o" | sed -n '4,487p' | wc -l | tr -d ' ')" "26/484" "0/484"
fdRow "drawWalkT DW-9 heading's bottom row painted: black pixels / pixels read (y=42, x 0..399)" "$(_dwcnt heading 488 887 'r0 g0 b0 a255')/$(grep -h '^=== pixelAt heading ' "$T/dw.o" | sed -n '488,887p' | wc -l | tr -d ' ')" "27/400" "400/400"
fdRow "drawWalkT DW-10 width 3, own strokeColor=blue: left (0..3,10), top (10,0..3) -- three painted, the fourth not" "$(_dwpr dwThick 1 8)" "r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/" "r0 g81 b186 a255/r0 g81 b186 a255/r0 g81 b186 a255/r255 g255 b255 a255/r0 g81 b186 a255/r0 g81 b186 a255/r0 g81 b186 a255/r255 g255 b255 a255/"
fdRow "drawWalkT DW-11 colour from the style (dwSt strokeColor red): (0,5) painted, (1,5) not" "$(_dwpr dwStyled 1 2)" "r255 g255 b255 a255/r255 g255 b255 a255/" "r239 g43 b45 a255/r255 g255 b255 a255/"
_ofeq "drawWalkT DW-12 x past the width refuses by name, and no pixel line for it (ok's reads stay 14)" "$(grep -c '^pixelAt: ok (400,180) OUT OF RANGE' "$T/dw.e") $(grep -h '^=== pixelAt ok ' "$T/dw.o" | wc -l | tr -d ' ')" "1 14"
fdRow "drawWalkT a field with no fill is skipped, not refused: refusals during the walk, beside words' pixel (anti-vacuity)" "$(sed -n '/^DW walk begins/,/^DW walk ends/p' "$T/dw.e" | grep -c 'REFUS') $(_dwp words)" "0 r0 g0 b0 a0/" "0 r255 g255 b255 a255/"

echo "-- the text: forms step 5."
#  ⚑ textT -- forms step 5 (Tony, 2026-11-09, SEQ 582): drawSpans draws a field's own string in its frame, wrapped at word
#  boundaries, not indented, a line that does not fit not drawn, a too-wide word clipped at the frame; font and color resolved
#  in kant (own, style, enclosing field; color falls back to black). REGISTERED ON TRUNK BEFORE THE BUILD: each row pinned at
#  today's value (no text is drawn), the intended beside it. Pixels are read BY COORDINATE (the first read of each point).
_txF=$(ip textT)
perl -e 'alarm 30; exec @ARGV' "$B" "$_txF" > "$T/tx.o" 2> "$T/tx.e"; _txx=$?
#  _txs <file> <tag> <x0> <x1> <y0> <y1> <background "rN gN bN aN"> <count|minx|maxx>: pixels in the box (inclusive) that are not the background
_txs () {
    awk -v tag="$2" -v x0="$3" -v x1="$4" -v y0="$5" -v y1="$6" -v bg="$7" -v mode="$8" '
        $1 == "===" && $2 == "pixelAt" && $3 == tag {
            split($4, c, /[(,)]/); x = c[2] + 0; y = c[3] + 0; k = x "," y
            if (k in seen) next; seen[k] = 1
            if (x < x0 || x > x1 || y < y0 || y > y1) next
            if ($6 " " $7 " " $8 " " $9 == bg) next
            n++; if (mn == "" || x < mn) mn = x; if (mx == "" || x > mx) mx = x }
        END { if (mode == "count") print n + 0; else if (mode == "minx") print (mn == "" ? "none" : mn); else print (mx == "" ? "none" : mx) }' "$1"
}
_txWall="r247 g232 b170 a255"; _txWhite="r255 g255 b255 a255"; _txGreen="r175 g211 b120 a255"; _txBlue="r206 g255 b255 a255"
_txInk () { [ "$1" -gt 0 ] && echo ink || echo none; }
_txClean () { [ "$1" -eq 0 ] && echo clean || echo "ink $1"; }
#  _txHue <file> <tag> <box> <background>: the darkest non-background pixel's strongest channel (r g b), k when its channels are within 40 (grey or black)
_txHue () {
    awk -v tag="$2" -v x0="$3" -v x1="$4" -v y0="$5" -v y1="$6" -v bg="$7" '
        $1 == "===" && $2 == "pixelAt" && $3 == tag {
            split($4, c, /[(,)]/); x = c[2] + 0; y = c[3] + 0; k = x "," y
            if (k in seen) next; seen[k] = 1
            if (x < x0 || x > x1 || y < y0 || y > y1) next
            if ($6 " " $7 " " $8 " " $9 == bg) next
            r = substr($6, 2) + 0; g = substr($7, 2) + 0; b = substr($8, 2) + 0
            if (best == "" || r + g + b < best) { best = r + g + b; R = r; G = g; B = b } }
        END { if (best == "") { print "none"; exit }
              mx = R; if (G > mx) mx = G; if (B > mx) mx = B; mn = R; if (G < mn) mn = G; if (B < mn) mn = B
              if (mx - mn < 40) print "k"; else if (mx == R) print "r"; else if (mx == G) print "g"; else print "b" }' "$1"
}
#  _txFlush <minx line 1> <minx line 2>: both within 2 of each other and at most 7 (the 4-point inset plus a glyph's bearing)
_txFlush () { if [ "$1" = none ] || [ "$2" = none ]; then echo none
    elif [ $(( $1 > $2 ? $1 - $2 : $2 - $1 )) -le 2 ] && [ "$1" -le 7 ] && [ "$2" -le 7 ]; then echo flush; else echo "indent $1 $2"; fi; }
#  _txOrient <top count> <bottom count>: the T of This is upright when its bar (top rows) outweighs its stem (bottom rows)
_txOrient () { if [ "$1" -eq 0 ] && [ "$2" -eq 0 ]; then echo none; elif [ "$1" -gt "$2" ]; then echo upright; elif [ "$1" -lt "$2" ]; then echo flipped; else echo level; fi; }
#  _txClasses <file> <tag>: the six firstLight classes -- heading, words line 1, words line 2, no indent, orientation, ok
_txClasses () {
    echo "$(_txInk $(_txs "$1" "$2" 4 203 18 18 "$_txWall" count)) $(_txInk $(_txs "$1" "$2" 4 203 55 55 "$_txWhite" count)) $(_txInk $(_txs "$1" "$2" 4 203 70 70 "$_txWhite" count)) $(_txFlush $(_txs "$1" "$2" 0 29 49 58 "$_txWhite" minx) $(_txs "$1" "$2" 0 29 64 73 "$_txWhite" minx)) $(_txOrient $(_txs "$1" "$2" 3 12 49 51 "$_txWhite" count) $(_txs "$1" "$2" 3 12 55 57 "$_txWhite" count)) $(_txInk $(_txs "$1" "$2" 342 397 180 180 "$_txGreen" count))"
}
#  _txTrace <tag> <field>: a field of drawSpans's line for that field (font / color / lines / next)
_txTrace () { grep -h "^=== drawSpans $1 " "$T/tx.o" "$T/tx.e" 2>/dev/null | head -1 | sed "s/^=== drawSpans $1 //; s/ ===\$//" | awk -v want="$2" '
    { for (i = 1; i <= NF; i++) { if ($i == "font") f = $(i+1) " " $(i+2) " " $(i+3); if ($i == "color") c = $(i+1) " " $(i+2) " " $(i+3)
      if ($i == "lines") l = $(i+1); if ($i == "next") nx = $(i+1) } }
    END { if (want == "font") print f; else if (want == "color") print c; else if (want == "lines") print l " " nx }'; }
_ofeq "textT exit / sentinel" "$_txx $(grep -c '^TEXTT SENTINEL' "$T/tx.e")" "0 1"
fdRow "textT TX-1 heading's text inks its line: y=18, x 4..203, not wall" "$(_txInk $(_txs "$T/tx.o" firstLight 4 203 18 18 "$_txWall" count))" "none" "ink"
fdRow "textT TX-2 words' first line inks: y=55, x 4..203, not white" "$(_txInk $(_txs "$T/tx.o" firstLight 4 203 55 55 "$_txWhite" count))" "ink" "ink"
fdRow "textT TX-3 WRAP: words' second line inks: y=70, x 4..203" "$(_txInk $(_txs "$T/tx.o" firstLight 4 203 70 70 "$_txWhite" count))" "ink" "ink"
fdRow "textT TX-4 WRAP, no indent: first ink of line 1 (y 49..58) and line 2 (y 64..73) at the same x, within 2, at most 7" "$(_txFlush $(_txs "$T/tx.o" firstLight 0 29 49 58 "$_txWhite" minx) $(_txs "$T/tx.o" firstLight 0 29 64 73 "$_txWhite" minx))" "flush" "flush"
fdRow "textT TX-5 ORIENTATION: the T of This, bar rows y 49..51 outweigh stem rows y 55..57, x 3..12" "$(_txOrient $(_txs "$T/tx.o" firstLight 3 12 49 51 "$_txWhite" count) $(_txs "$T/tx.o" firstLight 3 12 55 57 "$_txWhite" count))" "flipped" "upright"
#  RE-AIM (SEQ 605, step 5b): ok is centred top to bottom, so its letters sit about 6 lower. TX-6, TX-K3 and the ok point of _txClasses ask
#  about ink and colour, not position, so their row moves from y=176 to y=180, inside the letters at the top and at the centre alike; pinned
#  values unchanged. firstPdfT reads y=180 from its PD-9 band.
fdRow "textT TX-6 ok's text inks: y=180, x 342..397, not lightGreen" "$(_txInk $(_txs "$T/tx.o" firstLight 342 397 180 180 "$_txGreen" count))" "none" "ink"
fdRow "textT TX-7 tOver's second line inks: y=37, x 14..125" "$(_txInk $(_txs "$T/tx.o" tForm 14 125 37 37 "$_txBlue" count))" "none" "ink"
fdRow "textT TX-8 a line that does not fit is not drawn: below tOver's second line, y 46..49, x 14..125, clean (pair: TX-7)" "$(_txClean $(_txs "$T/tx.o" tForm 14 125 46 49 "$_txBlue" count))" "clean" "clean"
fdRow "textT TX-9 SPACE-CLIP: tOver's second line ends inside the inset, last ink x at most 125 (y 31..44, x 100..129)" "$(_m=$(_txs "$T/tx.o" tForm 100 129 31 44 "$_txBlue" maxx); [ "$_m" = none ] && echo none || { [ "$_m" -le 125 ] && echo inside || echo "past $_m"; })" "none" "inside"
fdRow "textT TX-10 a too-wide word runs to its frame's edge: tLong y 66..75, x 66..69 inked" "$(_txInk $(_txs "$T/tx.o" tForm 66 69 66 75 "$_txBlue" count))" "none" "ink"
fdRow "textT TX-11 and is clipped there: past tLong's edge, y 62..89, x 70..79, clean (pair: TX-10)" "$(_txClean $(_txs "$T/tx.o" tForm 70 79 62 89 "$_txWhite" count))" "clean" "clean"
fdRow "textT TX-F1 words' font, inherited from firstLight (font:=normalFont): family size bold" "$(_txTrace words font)" "" "Palatino 14 0"
fdRow "textT TX-F2 heading's font, its own (font:=titleFont)" "$(_txTrace heading font)" "" "Palatino 24 1"
fdRow "textT TX-C0 tPlain names no color, nor does anything above it: black (SEQ 583, moved from words)" "$(_txTrace tPlain color)" "r0 g0 b0" "r0 g0 b0"
fdRow "textT TX-F0 tPlain names no font, nor does anything above it: Helvetica 12 (R1)" "$(_txTrace tPlain font)" "Helvetica 12 0" "Helvetica 12 0"
fdRow "textT TX-C1 words inherits firstLight's color:=blue" "$(_txTrace words color)" "r0 g0 b0" "r0 g81 b186"
fdRow "textT TX-C4 heading's own color:=green wins over firstLight's blue" "$(_txTrace heading color)" "r0 g0 b0" "r0 g158 b15"
fdRow "textT TX-K1 heading's ink is green: its darkest ink pixel's strongest channel (y=18, x 4..203)" "$(_txHue "$T/tx.o" firstLight 4 203 18 18 "$_txWall")" "none" "g"
fdRow "textT TX-K2 words' ink is blue, inherited (y=55, x 4..203)" "$(_txHue "$T/tx.o" firstLight 4 203 55 55 "$_txWhite")" "k" "b"
fdRow "textT TX-K3 ok's ink is blue, inherited through bar (y=180, x 342..397)" "$(_txHue "$T/tx.o" firstLight 342 397 180 180 "$_txGreen")" "k" "b"
fdRow "textT TX-C2 tOver's own color:=blue (pair: TX-C1)" "$(_txTrace tOver color)" "" "r0 g81 b186"
fdRow "textT TX-C3 tLong inherits tForm's color:=red" "$(_txTrace tLong color)" "" "r239 g43 b45"
fdRow "textT TX-ST tStyled takes font and color from its style tsStyle (titleFont, green)" "$(_txTrace tStyled font) $(_txTrace tStyled color)" " " "Palatino 24 1 r0 g158 b15"
fdRow "textT TX-L tOver: 2 lines drawn, the next character a space; tLong: 1 line, the word ran on (next end)" "$(_txTrace tOver lines) / $(_txTrace tLong lines)" "  /  " "2 space / 1 end"
#  RE-PIN (SEQ 584): textT gained tRight, tKid, tKidL, tBad for step 5a, so the call list grows by those four; nothing else changed.
#  RE-PIN (SEQ 605): textT gained tVTop's six children for step 5b, so the call list grows by those six; nothing else changed.
#  RE-PINNED 2026-11-13 (G2 stroke 1b): firstLight holds the descriptions form, so its two text fields are drawn after ok.
fdRow "textT TX-N drawSpans calls: heading words ok (and the held form's describeHead describeHelp), then tOver tLong tStyled tRight, tCenterTop's three, tVTop's six, then tPlain (no call for a field with no text)" "$(grep -h '^=== drawSpans ' "$T/tx.o" | awk '{print $3}' | xargs)" "heading words ok tOver tLong tStyled tRight tKid tKidL tBad tVKid tVBot tVSty tVBad tVTwo tVOwn tPlain" "heading words ok describeHead describeHelp tOver tLong tStyled tRight tKid tKidL tBad tVKid tVBot tVSty tVBad tVTwo tVOwn tPlain"
fdRow "textT TX-W a text that does not fit warns naming its field: tOver and tLong, nothing else" "$(grep -h '^drawSpans: WARNING ' "$T/tx.e" | awk '{print $3}' | xargs)" "heading tOver tLong" "tOver tLong"
#  ⚑ STEP 5a, ALIGNMENT (Tony, 2026-11-09, SEQ 584). REGISTERED ON TRUNK BEFORE THE BUILD: each row pinned at today's value (everything
#  draws left), the intended beside it. TOLERANCES: centred = the ink's distances to the frame's two edges differ by at most 2 px; at the
#  edge = the last ink within 2 px of the frame edge less the 4-point inset; left = the first ink at most 6 px inside the frame edge.
#  _txCentre <file> <tag> <box x0 x1 y0 y1> <bg> <frame left> <frame right>
_txCentre () { _l=$(_txs "$1" "$2" $3 $4 $5 $6 "$7" minx); _r=$(_txs "$1" "$2" $3 $4 $5 $6 "$7" maxx)
    if [ "$_l" = none ]; then echo none; return; fi
    _dl=$(( _l - $8 )); _dr=$(( $9 - _r )); _d=$(( _dl > _dr ? _dl - _dr : _dr - _dl ))
    [ $_d -le 2 ] && echo centred || echo "off $_dl $_dr"; }
#  _txEdge <file> <tag> <box> <bg> <edge less inset>: the last ink within 2 px of it
_txEdge () { _r=$(_txs "$1" "$2" $3 $4 $5 $6 "$7" maxx); if [ "$_r" = none ]; then echo none; elif [ $_r -ge $(( $8 - 2 )) ] && [ $_r -le $8 ]; then echo edge; else echo short; fi; }
#  _txLeft <file> <tag> <box> <bg> <frame left>: the first ink at most 6 px in
_txLeft () { _l=$(_txs "$1" "$2" $3 $4 $5 $6 "$7" minx); if [ "$_l" = none ]; then echo none; elif [ $_l -le $(( $8 + 6 )) ]; then echo left; else echo "in $(( _l - $8 ))"; fi; }
#  _alClasses <file> <tag>: heading centred, words line 1, line 2, line 3 (justify: edge edge short)
_alClasses () { echo "$(_txCentre "$1" "$2" 0 399 10 28 "$_txWall" 0 399) $(_txEdge "$1" "$2" 300 399 49 60 "$_txWhite" 395) $(_txEdge "$1" "$2" 300 399 64 75 "$_txWhite" 395) $(_txEdge "$1" "$2" 0 399 80 90 "$_txWhite" 395)"; }
fdRow "textT AL-1 CENTER: heading's ink centred in its frame (x 0..399, y 10..28)" "$(_txCentre "$T/tx.o" firstLight 0 399 10 28 "$_txWall" 0 399)" "off 4 282" "centred"
fdRow "textT AL-2 CENTER: ok's ink centred in its frame (x 340..399; scanned 342..397, y 168..196)" "$(_txCentre "$T/tx.o" firstLight 342 397 168 196 "$_txGreen" 340 399)" "off 4 34" "centred"
fdRow "textT AL-3 JUSTIFY: words' lines 1 and 2 end at x 395 (396 less a pixel), line 3, the last, does not" "$(_txEdge "$T/tx.o" firstLight 300 399 49 60 "$_txWhite" 395) $(_txEdge "$T/tx.o" firstLight 300 399 64 75 "$_txWhite" 395) $(_txEdge "$T/tx.o" firstLight 0 399 80 90 "$_txWhite" 395)" "short short short" "edge edge short"
fdRow "textT AL-4 RIGHT: tRight's last ink at its frame edge less the inset, x 185 (190 - 4, less a pixel)" "$(_txEdge "$T/tx.o" tForm 140 189 64 85 "$_txBlue" 185)" "short" "edge"
fdRow "textT AL-5 LEFT: tOver, no align, draws as before -- first ink within 6 of x 10" "$(_txLeft "$T/tx.o" tForm 10 40 15 28 "$_txBlue" 10)" "left" "left"
fdRow "textT AL-6 INHERIT: tKid (no align) centred under tCenterTop; tKidL (style align=left) left; tBad (align=leftl) left" "$(_txCentre "$T/tx.o" tCenterTop 0 119 5 26 "$_txWhite" 0 119) $(_txLeft "$T/tx.o" tCenterTop 0 119 35 56 "$_txWhite" 0) $(_txLeft "$T/tx.o" tCenterTop 0 119 65 86 "$_txWhite" 0)" "off 4 99 left left" "centred left left"
fdRow "textT AL-7 REFUSAL: tBad's align=leftl refused by name, drawn left" "$(grep -c "^drawSpans: REFUSING tBad's align=leftl" "$T/tx.e")" "0" "1"
#  AL-8's reader takes the word after align whether or not the typesetting suffix follows it (words carries one since 2026-11-12: paragraphs 2 of 2 runs 1)
fdRow "textT AL-8 the alignment each field drew with: heading words ok tRight tKid tKidL tBad" "$(for _f in heading words ok tRight tKid tKidL tBad; do grep -h "^=== drawSpans $_f " "$T/tx.o" | head -1 | sed -n 's/.* align \([a-z]*\)\( paragraphs .*\)\{0,1\} ===$/\1/p'; done | xargs)" "" "center justify center right center left left"
#  "no refusal" counts every refusal but AL-7's, which is expected (SEQ 584): the row's question is unchanged
_ofeq "textT no refusal" "$(grep 'REFUS' "$T/tx.e" | grep -vc "align=leftl\|valign=middle")" "0"
#  ⚑ STEP 5b, VERTICAL ALIGNMENT (Tony, 2026-11-10, SEQ 605). REGISTERED ON TRUNK BEFORE THE BUILD: each row pinned at today's value
#  (everything draws at the top), the intended beside it. TOLERANCES, as align's turned on their side: centred = the ink's distances to
#  the frame's top and bottom differ by at most 2 px; at the bottom = the last ink within 2 px of the frame's bottom less the 4-point
#  inset; top = the first ink at most 6 px inside the frame's top. The words carry an ascender and a descender (Edgy) so the ink spans
#  the line; OK has neither and its capitals still centre within the tolerance.
#  _tys <file> <tag> <x0> <x1> <y0> <y1> <background> <miny|maxy>: the first or last row holding a pixel that is not the background
_tys () {
    awk -v tag="$2" -v x0="$3" -v x1="$4" -v y0="$5" -v y1="$6" -v bg="$7" -v mode="$8" '
        $1 == "===" && $2 == "pixelAt" && $3 == tag {
            split($4, c, /[(,)]/); x = c[2] + 0; y = c[3] + 0; k = x "," y
            if (k in seen) next; seen[k] = 1
            if (x < x0 || x > x1 || y < y0 || y > y1) next
            if ($6 " " $7 " " $8 " " $9 == bg) next
            if (mn == "" || y < mn) mn = y; if (mx == "" || y > mx) mx = y }
        END { if (mode == "miny") print (mn == "" ? "none" : mn); else print (mx == "" ? "none" : mx) }' "$1"
}
#  _tyCentre <file> <tag> <box x0 x1 y0 y1> <bg> <frame top> <frame bottom>
_tyCentre () { _t=$(_tys "$1" "$2" $3 $4 $5 $6 "$7" miny); _b=$(_tys "$1" "$2" $3 $4 $5 $6 "$7" maxy)
    if [ "$_t" = none ]; then echo none; return; fi
    _dt=$(( _t - $8 )); _db=$(( $9 - _b )); _d=$(( _dt > _db ? _dt - _db : _db - _dt ))
    [ $_d -le 2 ] && echo centred || echo "off $_dt $_db"; }
#  _tyBottom <file> <tag> <box> <bg> <frame bottom less inset>: the last ink within 2 px of it
_tyBottom () { _b=$(_tys "$1" "$2" $3 $4 $5 $6 "$7" maxy); if [ "$_b" = none ]; then echo none; elif [ $_b -ge $(( $8 - 2 )) ] && [ $_b -le $(( $8 + 2 )) ]; then echo bottom; else echo "short $_b"; fi; }
#  _tyTop <file> <tag> <box> <bg> <frame top>: the first ink at most 6 px down
_tyTop () { _t=$(_tys "$1" "$2" $3 $4 $5 $6 "$7" miny); if [ "$_t" = none ]; then echo none; elif [ $_t -le $(( $8 + 6 )) ]; then echo top; else echo "down $(( _t - $8 ))"; fi; }
_vaOf () { grep -h "^=== drawSpans $1 " "$T/tx.o" | head -1 | sed -n 's/.* valign \([a-z]*\) align [a-z]* ===$/\1/p'; }
fdRow "textT VA-1 CENTER: ok's ink centred top to bottom in its frame (y 165..199; scanned inside the border, 167..197, x 342..397)" "$(_tyCentre "$T/tx.o" firstLight 342 397 167 197 "$_txGreen" 165 199)" "off 5 18" "centred"
fdRow "textT VA-2 CENTER: tVOwn (its own valign=center) centred in its frame (y 60..119)" "$(_tyCentre "$T/tx.o" tVTop 0 59 60 119 "$_txWhite" 60 119)" "off 4 43" "centred"
fdRow "textT VA-3 BOTTOM: tVBot's last ink at its frame's bottom less the inset (y 55); tVTwo's three lines end at y 115, the first starts below the middle" "$(_tyBottom "$T/tx.o" tVTop 60 119 0 59 "$_txWhite" 55) $(_tyBottom "$T/tx.o" tVTop 240 299 0 119 "$_txWhite" 115) $([ "$(_tys "$T/tx.o" tVTop 240 299 0 119 "$_txWhite" miny)" -ge 60 ] && echo low || echo high)" "short 16 short 40 high" "bottom bottom low"
fdRow "textT VA-4 INHERIT: tVKid (no valign) centred under tVTop's valign=center; tVSty (style valign=top) at the top" "$(_tyCentre "$T/tx.o" tVTop 0 59 0 59 "$_txWhite" 0 59) $(_tyTop "$T/tx.o" tVTop 120 179 0 59 "$_txWhite" 0)" "off 4 43 top" "centred top"
fdRow "textT VA-5 REFUSAL: tVBad's valign=middle refused by name, drawn at the top (not the inherited centre)" "$(grep -c "^drawSpans: REFUSING tVBad's valign=middle" "$T/tx.e") $(_tyTop "$T/tx.o" tVTop 180 239 0 59 "$_txWhite" 0)" "0 top" "1 top"
fdRow "textT VA-6 the valign each field drew with: heading ok tVKid tVBot tVSty tVBad tVTwo tVOwn" "$(for _f in heading ok tVKid tVBot tVSty tVBad tVTwo tVOwn; do _vaOf $_f; done | xargs)" "" "top center center bottom top top bottom center"
#  ⚑ textTopT (SEQ 583): a top's text slot holds its display (the pointer / text union), so a top's own text is not drawable; drawSpans
#  read the context's bytes as text and threw (exit 134). Pinned: refused by name, exit 0.
_ttF=$(ip textTopT)
perl -e 'alarm 20; exec @ARGV' "$B" "$_ttF" > "$T/tt.o" 2> "$T/tt.e"; _ttx=$?
fdRow "textTopT a top with its own text: exit / sentinel" "$_ttx $(grep -c '^TEXTTOPT SENTINEL' "$T/tt.e")" "134 0" "0 1"
fdRow "textTopT ... refused by name, its text slot holds the display" "$(grep -c '^drawSpans: REFUSING ttTop -- a top keeps its display in its text slot' "$T/tt.e")" "0" "1"

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
#  RE-PINNED 2026-11-13 (G2 stroke 1b): firstLight is 400x400, its lower half holding the descriptions form.
fdRow "firstPdfT readPDF: one page, firstLight's frame (400 x 400 points)" "$(grep '^=== readPDF pdfRead' "$T/pd.o" "$T/pd.e" 2>/dev/null | sed 's/.*pdfRead //; s/ ===.*//')" "" "pages 1 size 400x400"
#  RE-AIM (SEQ 582, forms step 5, 2026-11-09): text now draws in heading and ok, over (5,15) and (360,180). These rows ask about FILL, so the point
#  moves off the text, to (300,15) and (390,190), where the same fill shows; pinned values unchanged.
fdRow "firstPdfT PD-1 read back: heading (300,15) wall, words (5,100) white, space (100,180) wall, ok (390,190) lightGreen" "$(_pdp 1 4)" "" "r247 g232 b170 a255/r255 g255 b255 a255/r247 g232 b170 a255/r175 g211 b120 a255/"
fdRow "firstPdfT PD-2 read back: ok's border left (340,180) red / (339,180) wall, top (360,165) red / (360,164) white" "$(_pdp 5 8)" "r0 g0 b0 a255/r247 g232 b170 a255/r0 g0 b0 a255/r255 g255 b255 a255/" "r239 g43 b45 a255/r247 g232 b170 a255/r239 g43 b45 a255/r255 g255 b255 a255/"
fdRow "firstPdfT PD-3 read back: heading's bottom line (5,42) black, (5,43) white" "$(_pdp 9 10)" "r255 g255 b255 a255/r255 g255 b255 a255/" "r0 g0 b0 a255/r255 g255 b255 a255/"
fdRow "firstPdfT PD-4 read back, the right way up: (5,44) white, (5,166) wall" "$(_pdp 11 12)" "r255 g255 b255 a255/r247 g232 b170 a255/" "r255 g255 b255 a255/r247 g232 b170 a255/"
#  PD-5 RE-PINNED (SEQ 583): its words scans moved 13 down with heading, so today (heading 30) the shifted scans read line 2 and words's edge;
#  intended unchanged.
#  PD-5 (forms step 5, SEQ 582): the text read back at textT's firstLight points, classified as textT's bitmap is; the PDF agrees with the bitmap.
fdRow "firstPdfT PD-5 the text read back: heading, words line 1, line 2, no indent, orientation, ok" "$(_txClasses "$T/pd.o" pdfRead)" "none ink ink flush flipped ink" "ink ink ink flush upright ink"
_ofeq "firstPdfT PD-6 the PDF agrees with the bitmap on the same points (textT's classes)" "$(_txClasses "$T/pd.o" pdfRead)" "$(_txClasses "$T/tx.o" firstLight)"
#  PD-7 / PD-8 (step 5a, SEQ 584): heading centred and words justified, read back from the PDF at textT's AL points; the PDF agrees with the bitmap.
fdRow "firstPdfT PD-7 the read-back: heading centred, words lines 1 and 2 at the edge, line 3 short" "$(_alClasses "$T/pd.o" pdfRead)" "off 4 282 short short short" "centred edge edge short"
_ofeq "firstPdfT PD-8 the PDF agrees with the bitmap on the centre and justify points" "$(_alClasses "$T/pd.o" pdfRead)" "$(_alClasses "$T/tx.o" firstLight)"
#  PD-9 / PD-10 (step 5b, SEQ 605): ok centred top to bottom, read back from the PDF inside ok's border; the PDF agrees with the bitmap.
fdRow "firstPdfT PD-9 the read-back: ok's ink centred top to bottom in its frame" "$(_tyCentre "$T/pd.o" pdfRead 342 397 167 197 "$_txGreen" 165 199)" "off 5 18" "centred"
_ofeq "firstPdfT PD-10 the PDF agrees with the bitmap on ok's first and last ink rows, within 1" "$(_p=$(( $(_tys "$T/pd.o" pdfRead 342 397 167 197 "$_txGreen" miny) - $(_tys "$T/tx.o" firstLight 342 397 167 197 "$_txGreen" miny) )); _q=$(( $(_tys "$T/pd.o" pdfRead 342 397 167 197 "$_txGreen" maxy) - $(_tys "$T/tx.o" firstLight 342 397 167 197 "$_txGreen" maxy) )); [ ${_p#-} -le 1 ] && [ ${_q#-} -le 1 ] && echo agree || echo "differ $_p $_q")" "agree"

echo "-- the descriptions form: forms step 8, baby steps."
#  ⚑ descT -- the descriptions form (Tony, 2026-11-10, SEQ 607): IncantForms/Windows/descriptions is a whole incantation, so the run file is
#  the form up to its stop() joined to the driver incant/pop/descT. REGISTERED BEFORE THE FORM CHANGE: each row pinned at the old form's
#  value, the intended beside it. Pixels are page coordinates.
_deF=$(ip descT)
#  2026-11-13 (G2 stroke 1a): the form is definitions only and named descriptions, so descT includes it and is run as it stands (the join is gone).
perl -e 'alarm 30; exec @ARGV' "$B" "$_deF" > "$T/de.o" 2> "$T/de.e"; _dex=$?
_dep () { grep -h "^=== pixelAt descriptions ($1) " "$T/de.o" | head -1 | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/'; }
#  _deFr <field>: the field's frame from the definition printed after setFrame, as "WxH at X,Y"
_deFr () { grep -h "^[[:space:]]*$1=" "$T/de.o" | tail -1 | awk '{ for (i = 1; i <= NF; i++) { split($i, kv, "="); gsub(/;/, "", kv[2]); if (kv[1] == "width") w = kv[2]; if (kv[1] == "height") h = kv[2]; if (kv[1] == "x") x = kv[2]; if (kv[1] == "y") y = kv[2] } } END { print w "x" h " at " x "," y }'; }
_det () { grep -h "^=== drawSpans $1 " "$T/de.o" | head -1 | sed "s/^=== drawSpans $1 //; s/ lines .* next [a-z]*//; s/ ===\$//"; }
_ofeq "descT exit / sentinel" "$_dex $(grep -c '^DESCT SENTINEL' "$T/de.e")" "0 1"
fdRow "descT DE-1 ACROSS: saber and trees side by side, each half of second (flex is gone, across is written)" "$(_deFr saber) / $(_deFr trees)" "500x138 at 500,250 / 500x137 at 500,388" "250x275 at 500,250 / 250x275 at 750,250"
fdRow "descT DE-2 the heading's text: titleFont, white, centred both ways (font:= color:= align valign)" "$(_det describeHead)" "font Helvetica 12 0 color r0 g0 b0 valign top align left" "font Palatino 24 1 color r255 g255 b255 valign center align center"
#  RE-AIM (SEQ 609): saber's and trees' points sit under their images once images draw, so DE-3 keeps the two fills nothing covers; pinned at
#  the values those two points read already. The image fields' points are DE-9's.
fdRow "descT DE-3 FILLS (fill:=): first lightGreen (10,10), describeHelp lightGreen (100,550)" "$(_dep 10,10)/$(_dep 100,550)" "r175 g211 b120 a255/r175 g211 b120 a255" "r175 g211 b120 a255/r175 g211 b120 a255"
fdRow "descT DE-4 BORDERS (bordered -> border): saber's left (0,300), trees' left (250,300), describeHelp's top (100,325), black" "$(_dep 0,300)/$(_dep 250,300)/$(_dep 100,325)" "r0 g0 b0 a0/r0 g0 b0 a0/r0 g0 b0 a0" "r0 g0 b0 a255/r0 g0 b0 a255/r0 g0 b0 a255"
fdRow "descT DE-5 no refusal and no colour error (the form includes styles itself)" "$(grep -c 'REFUS\|ERROR' "$T/de.e")" "11" "0"
#  DE-6 MEASURED, NOT CHOSEN: with dESCRIPTIONs on the search list during the form's define (R1), the form's saber IS the registry's saber, so
#  the registry entry's text becomes the form field's text. R2 reads the same way (an image field's text is its description).
#  CURED 2026-11-13 (Tony's fix): the captions are defined on their own in FORMs before the search line, and the form names them with no text.
#  The current registry is searched first (GroupControl locate), so the form's saber is the caption and the registry's saber keeps its long text.
_ofeq "descT DE-12 THE FORM'S saber and describeHead read their captions (the laid-out definition), while DE-6 has the registry's long text" "$(grep -h '^[[:space:]]*saber=' "$T/de.o" | head -1 | sed 's/^[[:space:]]*//; s/ image=.*//') / $(grep -h '^[[:space:]]*describeHead=' "$T/de.o" | head -1 | sed 's/^[[:space:]]*//; s/ font=.*//')" "saber=Saber from Fate Stay Night / describeHead=Using Descriptions"
_ofeq "descT DE-6 the registry's saber after the form's define keeps its long text (it read the form's caption until 2026-11-13)" "$(sed -n 's/^DED saber \[ \(.*\) \]/\1/p' "$T/de.e" | cut -c1-26)" "Fate Stay Night is a favor"
#  ⚑ SEQ 608 (R2, R6): describeHelp shows its describe attribute's text; an image field's text is its description and is not drawn; the
#  describe action moved from tester to incant/utilities. REGISTERED BEFORE THE BUILD.
fdRow "descT DE-7 DESCRIBE: describeHelp draws its describe attribute's 61 characters, not its own text" "$(grep -h '^=== drawSpans describeHelp ' "$T/de.o" | head -1 | sed -n 's/.* drawn \([0-9]* of [0-9]*\) .*/\1/p')" "179 of 179" "61 of 61"
fdRow "descT DE-8 IMAGE TEXT: drawSpans is called for describeHead and describeHelp, never for saber or trees (twice since 2026-11-13: the bitmap, then the PDF)" "$(grep -h '^=== drawSpans ' "$T/de.o" | awk '{print $3}' | xargs)" "describeHead saber trees describeHelp" "describeHead describeHelp describeHead describeHelp"
#  The describe action's six lines. Until 2026-11-12 this row ran Tony's tester; he parked its describe driver below stop() that day, so the
#  driver lives in incant/pop/describeT, verbatim (retired by mapping: one assertion, same md5, same count).
perl -e 'alarm 30; exec @ARGV' "$B" "$(ip describeT)" > "$T/tsd.o" 2> "$T/tsd.e"; _tsx=$?
_ofeq "describeT exit / sentinel" "$_tsx $(grep -c '^DESCRIBET SENTINEL' "$T/tsd.e")" "0 1"
_ofeq "describeT: describe's six lines (was tester's, across the move to utilities, R6), md5" "$(grep 'initial description\|mock ' "$T/tsd.o" | md5 -q) $(grep -c 'initial description\|mock ' "$T/tsd.o")" "556d248688d4ae5418d9c134712a5f6a 6"
#  ⚑ SEQ 609: the form's two images draw (the files are Tony's own pictures, named by absolute path, so the row pins that each drew with
#  fit fill and that its point is no longer the field's paleGray; the pixel values are imageT's business).
#  RE-PINNED 2026-11-13 (stroke 1a): descT draws the form twice, the bitmap and then the PDF, so displayImage runs for each image twice.
fdRow "descT DE-9 IMAGES: displayImage drew saber and trees, fit fill; their points (100,300) (350,300) are not paleGray" "$(grep -h '^=== displayImage ' "$T/de.o" | awk '{print $3, $8, $9}' | xargs) / $([ "$(_dep 100,300)" != "r241 g241 b241 a255" ] && echo image || echo fill) $([ "$(_dep 350,300)" != "r241 g241 b241 a255" ] && echo image || echo fill)" " / fill fill" "saber fit fill trees fit fill saber fit fill trees fit fill / image image"
#  ⚑ G2 stroke 1a (Tony, 2026-11-13): descriptions drawn to a PDF on its own, layout only. The same points read back from the page.
_depp () { grep -h "^=== pixelAt pdfRead ($1) " "$T/de.o" | head -1 | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/'; }
_ofeq "descT DE-10 THE PDF: one page written, 500x600; its fills and borders agree with the bitmap (first, describeHelp; saber's left, trees' left, describeHelp's top)" "$(grep -h '^=== readPDF pdfRead' "$T/de.o" | sed 's/^=== readPDF pdfRead //; s/ ===$//' | xargs) / $(_depp 10,10) $(_depp 100,550) $(_depp 0,300) $(_depp 250,300) $(_depp 100,325)" "pages 1 size 500x600 / $(_dep 10,10) $(_dep 100,550) $(_dep 0,300) $(_dep 250,300) $(_dep 100,325)"
_ofeq "descT DE-11 THE IMAGES IN THE PDF: saber's and trees' points (100,300) (350,300) are not the field's paleGray" "$([ -n "$(_depp 100,300)" ] && [ "$(_depp 100,300)" != "r241 g241 b241 a255" ] && echo image || echo fill) $([ -n "$(_depp 350,300)" ] && [ "$(_depp 350,300)" != "r241 g241 b241 a255" ] && echo image || echo fill)" "image image"

echo "-- a form inside a field: G2 stroke 1b (formNestT)."
#  ⚑ formNestT -- a form inside a field (Tony, 2026-11-13): a field written form:=other is the frame for that form. Pages are read back from the PDF.
#  Controls: NF-3's two fields holding one form (one shared copy could be in only one place); NF-4's page still drawn beside its refusal.
_nfF=$(ip formNestT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_nfF" > "$T/nf.o" 2> "$T/nf.e"; _nfx=$?
_nfp () { awk -v want="$1" '/^NF PAGE/{b=$3} /pixelAt pdfRead/ && b==want { s=$0; sub(/.*= /,"",s); sub(/ ===.*/,"",s); printf "%s%s", sep, s; sep=" / " }' "$T/nf.o"; }
_nff () { awk -v want="$1" '/^NF PAGE/{b=$3} /descriptions closable/ && b==want { for (i = 1; i <= NF; i++) { split($i, kv, "="); if (kv[1]=="x") x=kv[2]; if (kv[1]=="y") y=kv[2]; if (kv[1]=="width") w=kv[2]; if (kv[1]=="height") h=kv[2] } printf "%s%sx%s at %s,%s", sep, w, h, x, y; sep=" / " }' "$T/nf.o"; }
_ofeq "formNestT exit / sentinel" "$_nfx $(grep -c '^NESTT SENTINEL' "$T/nf.e")" "0 1"
_ofeq "formNestT NF-1 the held form takes its field's frame (400x320 at 0,40, between a 40-point head and foot); on the page its lightGreen heading field (10,50), the foot's white (10,380)" "$(_nff outer) / $(_nfp outer)" "400x320 at 0,40 / r175 g211 b120 a255 / r255 g255 b255 a255"
_ofeq "formNestT NF-2 a second run reads as the first" "$(_nff outer2)" "$(_nff outer)"
_ofeq "formNestT NF-3 TWO FIELDS, ONE FORM: each holds its own copy, 200 wide at x 0 and x 200, and both draw (10,10) (210,10)" "$(_nff two) / $(_nfp two)" "200x300 at 0,0 / 200x300 at 200,0 / r175 g211 b120 a255 / r175 g211 b120 a255"
_ofeq "formNestT NF-4 A FORM THAT HOLDS ITSELF is refused by name, once; its page is still drawn (wall at (10,10)); no form is left on the list of forms being laid out" "$(grep -c '^setFrame: REFUSING placeReq -- the form npSelf holds itself' "$T/nf.e") / $(_nfp self) / $(sed -n 's/^NF chain left \([0-9]*\).*/\1/p' "$T/nf.e")" "1 / r247 g232 b170 a255 / 0"
_ofeq "formNestT NF-5 firstLight holds descriptions in its lower half: heading's wall (300,15), the held form's lightGreen heading field (10,210), ok's green (390,190)" "$(_nfp light)" "r247 g232 b170 a255 / r175 g211 b120 a255 / r175 g211 b120 a255"

echo "-- the first image: forms step 8."
#  ⚑ imageT -- displayImage (Tony, 2026-11-10, SEQ 609): one argument, fit fill (cover, centred, cropped), refusals by name. The test image is
#  IncantForms/Images/bands.png, 40 x 20: 5 white rows, then green red blue green bands 10 wide. REGISTERED BEFORE THE BUILD.
_imF=$(ip imageT)
perl -e 'alarm 30; exec @ARGV' "$B" "$_imF" > "$T/im.o" 2> "$T/im.e"; _imx=$?
_imp () { for _pt in "$@"; do grep -h "^=== pixelAt imTop ($_pt) " "$T/im.o" | head -1 | sed 's/.*= r\([0-9]*\) g\([0-9]*\) b\([0-9]*\) a.*/\1,\2,\3/' | awk -F, '{ if ($1 > 200 && $2 > 200 && $3 > 200) print "white"; else if ($1 > 200 && $2 < 80) print "red"; else if ($3 > 200 && $1 < 80) print "blue"; else if ($2 > 120 && $1 < 80 && $3 < 80) print "green"; else if ($1 < 40 && $2 < 40 && $3 < 40) print "black"; else print "other" }'; done | xargs; }
fdRow "imageT exit / sentinel" "$_imx $(grep -c '^IMAGET SENTINEL' "$T/im.e")" "0 1" "0 1"
fdRow "imageT IM-1 FILL: imSquare shows the image's middle -- red (30,60), blue (90,60), and no green at its edges (12,60) (107,60)" "$(_imp 30,60 90,60 12,60 107,60)" "white white white white" "red blue red blue"
fdRow "imageT IM-2 UPRIGHT: the image's white rows at the top (60,20), colour at the bottom (30,100)" "$(_imp 60,20 30,100)" "white white" "white red"
fdRow "imageT IM-3 CLIPPED at the frame: (5,60) and (60,112) read the top's white" "$(_imp 5,60 60,112)" "white white" "white white"
fdRow "imageT IM-4 a wide frame crops top and bottom: green red blue green at y=22; the border drawn over the image (170,10)" "$(_imp 125,22 155,22 185,22 215,22 170,10)" "white white white white black" "green red blue green black"
fdRow "imageT IM-5 the trace: imSquare 40x20 drawn 200x100 at -40,10; imWide drawn 100x50 at 120,-2.5" "$(grep -h '^=== displayImage ' "$T/im.o" | sed 's/^=== displayImage //; s/ file [^ ]*//; s/ ===$//' | tr '\n' ';')" "" "imSquare pixels 40x20 fit fill drawn 200x100 at -40,10;imWide pixels 40x20 fit fill drawn 100x50 at 120,-2.5;"
fdRow "imageT IM-6 REFUSALS by name: an unreadable file, an unknown fit, no display (count of each), and imMissing's own fill still drawn" "$(grep -c '^displayImage: REFUSING imMissing -- cannot read an image from' "$T/im.e") $(grep -c "^displayImage: REFUSING imSquare's fit=stretch" "$T/im.e") $(grep -c '^displayImage: REFUSING imNoShow -- no display' "$T/im.e") $(grep -h '^=== pixelAt imTop (280,60) ' "$T/im.o" | head -1 | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]*\) .*/\1/')" "0 0 0 r241 g241 b241" "1 1 1 r241 g241 b241"
fdRow "imageT IM-7 an image field's text is not drawn: drawSpans calls" "$(grep -c '^=== drawSpans ' "$T/im.o")" "0" "0"

#  ⚑ roundedT -- forms step 9 (Tony, 2026-11-11, SEQ 621 R2): rounded on displayFillRT and displayBorder. rounded is the corner radius in
#  points, on a field or its style; a bare rounded takes defaultStyle's (5). A pixel on a curve is anti-aliased, so every pixel is read
#  as a CLASS (H3: an exact value there would move with the rasteriser, not with the answer). Each white corner sits beside a painted
#  pixel of the same field. H7 (run 2026-11-11): the fixture with every rounded removed reads RD-1 "red red red red" -- the corner fills.
echo ""
echo "-- rounded (roundedT)."
_rdF=$(ip roundedT)
perl -e 'alarm 20; exec @ARGV' "$B" "$_rdF" > "$T/rd.o" 2> "$T/rd.e"; _rdx=$?
#  _rdc <node> <from> <to>: the classes of that node's pixelAt lines from..to, in order
_rdc () { grep -h "^=== pixelAt $1 " "$T/rd.o" | sed -n "$2,$3p" | sed 's/.*= r\([0-9]*\) g\([0-9]*\) b\([0-9]*\) a\([0-9]*\) ===.*/\1 \2 \3 \4/' | awk '
    { c = "other"
      if ($4 == 0) c = "clear"
      else if ($1 >= 250 && $2 >= 250 && $3 >= 250) c = "white"
      else if ($1 >= 200 && $2 <= 80 && $3 <= 80) c = "red"
      else if ($1 <= 40 && $2 <= 110 && $3 >= 150) c = "blue"
      else if ($1 == 175 && $2 == 211 && $3 == 120) c = "green"
      else if ($1 == 0 && $2 == 158 && $3 == 15) c = "green2"
      else if ($1 == 0 && $2 == 0 && $3 == 0) c = "black"
      else if ($1 == $2 && $2 == $3 && $1 >= 150) c = "shade"
      printf "%s%s", (NR > 1 ? " " : ""), c } END { print "" }'; }
_ofeq "roundedT exit / sentinel" "$_rdx $(grep -c '^ROUNDED SENTINEL' "$T/rd.e")" "0 1"
_ofeq "roundedT RD-1 bare rounded, the default radius 5: corner (0,0), then (2,2), edge middle (20,0), centre (20,10)" "$(_rdc rdPlain 1 4)" "white red red red"
_ofeq "roundedT RD-2 rounded=10.0: (2,22) white where radius 5 paints, (3,23) red, the four corners white" "$(_rdc rdPlain 5 10)" "white red white white white white"
_ofeq "roundedT RD-3 a plain border on a rounded field follows the corner: (0,0), edge (20,0), inside (20,2), on the arc (3,3), inside it (6,6)" "$(_rdc rdEdge 1 5)" "white blue green blue green"
_ofeq "roundedT RD-4 rounded from the style (rounded=8): (0,0), (1,1), (4,4), centre (20,10)" "$(_rdc rdMore 1 4)" "white white blue blue"
_ofeq "roundedT RD-5 no rounded stays square: corner (0,20)" "$(_rdc rdMore 5 5)" "red"
_ofeq "roundedT RD-6 a radius past half the side draws at half: (0,0), (2,2), centre (10,10), edge middle (10,0)" "$(_rdc rdBigTop 1 4)" "white white red red"
_ofeq "roundedT RD-7 a value that is not a number refuses by name (count) and draws square: corner (0,0)" "$(grep -c "^roundedOf: REFUSING rdBad -- rounded's value is not a radius" "$T/rd.e") $(_rdc rdBadTop 1 1)" "1 red"
#  RE-PIN (SEQ 622 R0, R1, 2026-11-11): simple's width=50% and its second text field restored, so the points moved: was "wrap (100,135), two (220,70)"
#  reading "clear green green white red". three is 50% of 400, so its leftBorder sits at x=200: that pixel is the percent row.
_ofeq "roundedT RD-8 the simple form as a PDF, read back: fourth's corner (0,140), (2,142), centre (200,170), wrap (98,70), two (150,70), three's leftBorder at 50% (200,70), three (300,70)" "$(_rdc pdfRead 1 7)" "clear green green white red black white"
_ofeq "roundedT RD-8 the PDF is one page, simple's frame" "$(grep -h '^=== readPDF pdfRead' "$T/rd.o" | sed 's/.*pdfRead //; s/ ===.*//')" "pages 1 size 400x200"

#  ⚑ shadowT -- shadow, a field attribute (Tony, 2026-11-11, SEQ 622 R3): one part of the field is drawn with a shadow -- its fill, else its
#  border, else its text -- 2 right, 2 down, blur 3, black at 30%. A shaded pixel is a CLASS (an even grey, not white): its exact value is the
#  rasteriser's. SH-2 is the control beside SH-1: the same box with no shadow reads white at the same three points.
echo ""
echo "-- shadow (shadowT)."
_shF=$(ip shadowT)
perl -e 'alarm 30; exec @ARGV' "$B" "$_shF" > "$T/sh.o" 2> "$T/sh.e"; _shx=$?
_shc () { grep -h "^=== pixelAt $1 " "$T/sh.o" | sed -n "$2,$3p" | sed 's/.*= r\([0-9]*\) g\([0-9]*\) b\([0-9]*\) a\([0-9]*\) ===.*/\1 \2 \3 \4/' | awk '
    { c = "other"
      if ($4 == 0) c = "clear"
      else if ($1 >= 250 && $2 >= 250 && $3 >= 250) c = "white"
      else if ($1 >= 200 && $2 <= 80 && $3 <= 80) c = "red"
      else if ($1 == 0 && $2 == 0 && $3 == 0) c = "black"
      else if ($1 == 247 && $2 == 232 && $3 == 170) c = "wall"
      else if ($1 == $2 && $2 == $3 && $1 >= 150) c = "shade"
      else if ($1 < 247 && $1 >= 200 && $2 < 232 && $2 >= 190 && $3 <= 170 && $3 >= 130) c = "shadedWall"
      printf "%s%s", (NR > 1 ? " " : ""), c } END { print "" }'; }
_shn () { grep -h "^=== pixelAt $1 " "$T/sh.o" | grep -vc 'r255 g255 b255 a255'; }
_ofeq "shadowT exit / sentinel" "$_shx $(grep -c '^SHADOW SENTINEL' "$T/sh.e")" "0 1"
_ofeq "shadowT SH-1 a fill's shadow falls right and down: inside (20,20), below right (41,41), right (42,25), below (25,42), then above left (7,7), left (7,25), above (25,7)" "$(_shc shBoxTop 1 7)" "red shade shade shade white white white"
_ofeq "shadowT SH-2 the same box with no shadow: (41,41) (42,25) (25,42)" "$(_shc shPlainTop 1 3)" "white white white"
_ofeq "shadowT SH-3 a border with no fill carries the shadow: the line (10,25), outside right (42,25), inside the left line (13,25), outside left (7,25)" "$(_shc shLineTop 1 4)" "black shade shade white"
_ofeq "shadowT SH-4 text with no fill and no border carries the shadow: more non-white pixels than the same word with none (4800 read of each)" "$([ "$(_shn shWordTop)" -gt "$(_shn shBareTop)" ] && [ "$(_shn shBareTop)" -gt 0 ] && echo more || echo "not more: $(_shn shWordTop) $(_shn shBareTop)") $(grep -hc '^=== pixelAt shWordTop ' "$T/sh.o") $(grep -hc '^=== pixelAt shBareTop ' "$T/sh.o")" "more 4800 4800"
_ofeq "shadowT SH-6 a shadow does not reach a child (SEQ 623 R1): the parent's shadow (42,25), the child (20,20), then beside the child (26,26) (27,20) the parent's own red, exact" "$(_shc shKidTop 1 1) $(grep -h '^=== pixelAt shKidTop ' "$T/sh.o" | sed -n '2,4p' | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/' | tr '\n' '/')" "shade r0 g81 b186 a255/r239 g43 b45 a255/r239 g43 b45 a255/"
_ofeq "shadowT SH-5 shForm as a PDF, read back: the card (60,100), its shadow on the wall (142,162), the ring's border (180,115), the wall (20,100)" "$(_shc pdfRead 1 4)" "white shadedWall black wall"

#  ⚑ styleScopeT -- the style ruling (Tony, 2026-11-11, SEQ 622 R2): the style applies as the leftmost attribute; an attribute after it applies to
#  the field only and does not reach its children. SS-1 to SS-3 hold today. SS-4 pins what does NOT: text's font, colour and align still come
#  from the enclosing field's own attributes (drawText's climb). Pinned as it reads, to be re-pinned when ruled; firstLight relies on it.
echo ""
echo "-- style scope (styleScopeT)."
_ssF=$(ip styleScopeT)
perl -e 'alarm 20; exec @ARGV' "$B" "$_ssF" > "$T/ss.o" 2> "$T/ss.e"; _ssx=$?
_ssc () { grep -h "^=== pixelAt $1 " "$T/ss.o" | sed -n "$2,$3p" | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/' | sed -e 's/r239 g43 b45 a255/red/' -e 's/r0 g81 b186 a255/blue/' -e 's/r0 g158 b15 a255/green/' -e 's/r0 g0 b0 a255/black/' -e 's/r255 g255 b255 a255/white/' | tr '\n' ' ' | sed 's/ $//'; }
_ofeq "styleScopeT exit / sentinel" "$_ssx $(grep -c '^STYLESCOPE SENTINEL' "$T/ss.e")" "0 1"
_ofeq "styleScopeT SS-1 a field's fill, border and rounded do not reach its child: the kid's edges (30,10) (10,30) show the parent's fill" "$(_ssc ssA 1 2)" "red red"
_ofeq "styleScopeT SS-2 a field's style does not reach its child: the leaf's border (11,30), its square corner (10,10), its inside (30,30)" "$(_ssc ssB 1 3)" "black black blue"
_ofeq "styleScopeT SS-3 an attribute after the style overrides it on that field: fill (30,30), border (1,30), square corner (0,0)" "$(_ssc ssC 1 3)" "red green green"
_sst () { grep -h "^=== drawSpans $1 " "$T/ss.o" | sed 's/.*font \(.*\) color \(r[0-9]* g[0-9]* b[0-9]*\) .*valign \([a-z]*\) align \([a-z]*\) ===/\1 \2 \3 \4/'; }
#  SEQ 623 R0 (Tony, 2026-11-11): text properties inherit, box properties do not, whether set as an attribute or in a style. SS-4 is therefore AS RULED
#  (its label was "TODAY, not as ruled" at seal 452; the value is unchanged). SS-5 and SS-7: a held style's (style:=) text properties reach the children.
#  SS-6 (SEQ 624 R0, 2026-11-11): style="name" is RETIRED; style:= is the only spelling. The quoted form is refused by name and the field has no
#  style: no fill, and nothing for its children. The row that pinned the old gap (the quoted style filled its field, blue) went with the ruling.
_ofeq "styleScopeT SS-5 a held style's font, color, valign and align reach a child two levels down; its fillColor paints the field itself (1,1)" "$(_sst ssDkid) $(_ssc ssD 1 1)" "Palatino 24 1 r0 g158 b15 bottom center blue"
_ofeq "styleScopeT SS-6 a quoted style name is refused by name (at least once) and gives the field no style: its child's text is the default, its own (1,1) unpainted" "$([ "$(grep -c '^styleOf: REFUSING ssE -- its style is not held; write style:=name' "$T/ss.e")" -gt 0 ] && echo refused || echo silent) $(_sst ssEkid) $(grep -h '^=== pixelAt ssE ' "$T/ss.o" | sed 's/.*= //; s/ ===.*//')" "refused Helvetica 12 0 r0 g0 b0 top left r0 g0 b0 a0"
_ofeq "styleScopeT SS-7 a child's own color wins over the inherited style's; the style's font, valign and align still arrive" "$(_sst ssFkid)" "Palatino 24 1 r239 g43 b45 bottom center"
_ofeq "styleScopeT SS-4 text properties inherit (SEQ 623 R0): the kid's text takes the parent's own font, color and align" "$(grep -h '^=== drawSpans ssKid ' "$T/ss.o" | sed 's/.*font \(.*\) color \(r[0-9]* g[0-9]* b[0-9]*\) .*align \([a-z]*\) ===/\1 \2 \3/')" "Palatino 24 1 r0 g158 b15 center"

#  ⚑ opacityT -- opacity, a box property (Tony, 2026-11-11, SEQ 623): a number 0..1 on a field or its style; the field's own fill, border and text
#  are drawn at it (CGContextSetAlpha inside each floor method's saved state); it does not reach a child. Black at 0.5 on white is r127, exact
#  arithmetic, so the bitmap rows pin values. The PDF row compares its four points with each other, not with numbers (the read-back is rasterised).
echo ""
echo "-- opacity (opacityT)."
_opF=$(ip opacityT)
perl -e 'alarm 30; exec @ARGV' "$B" "$_opF" > "$T/op.o" 2> "$T/op.e"; _opx=$?
_opp () { grep -h "^=== pixelAt $1 " "$T/op.o" | sed -n "$2,$3p" | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/' | sed -e 's/r127 g127 b127 a255/grey/' -e 's/r0 g0 b0 a255/black/' -e 's/r255 g255 b255 a255/white/' -e 's/r0 g81 b186 a255/blue/' -e 's/r127 g168 b220 a255/halfBlue/' | tr '\n' ' ' | sed 's/ $//'; }
_opd () { grep -h "^=== pixelAt $1 " "$T/op.o" | sed 's/.*= r\([0-9]*\) .*/\1/' | sort -n | head -1; }
_ofeq "opacityT exit / sentinel" "$_opx $(grep -c '^OPACITY SENTINEL' "$T/op.e")" "0 1"
_ofeq "opacityT OP-1 a fill at 0.5 (15,15), the same fill with none (45,15), a border at 0.5 (1,45), a fill at 0 (45,45)" "$(_opp opA 1 4)" "grey black grey white"
_ofeq "opacityT OP-2 opacity does not reach a child: the parent at 0.5 (45,45); its child with none of its own (20,20)" "$(_opp opB 1 2)" "grey black"
_ofeq "opacityT OP-3 opacity from the style (15,15); the field's own opacity=1 over the style's (45,15); opacity=3 refused by name (count) and drawn opaque (15,45)" "$(_opp opC 1 3) $(grep -c "^opacityOf: REFUSING opBad -- opacity's value is not a number from 0 to 1" "$T/op.e")" "halfBlue blue black 1"
_ofeq "opacityT OP-4 text at 0.5: the darkest pixel on row y=18 is r127 where the same text with none reaches r0 (120 read of each)" "$(_opd opWordTop) $(_opd opBareTop) $(grep -hc '^=== pixelAt opWordTop ' "$T/op.o") $(grep -hc '^=== pixelAt opBareTop ' "$T/op.o")" "127 0 120 120"
#  OP-6 (SEQ 625 C1, 2026-11-11): opacity=0 must draw CLEAR, not read as absent and draw opaque. The floor asks whether the attribute exists
#  (get), never whether its value is true, so a 0 is a value. The fourth pixel is the control: the same fill with no opacity is black.
_ofeq "opacityT OP-6 opacity=0 is fully clear: a fill (15,15), from a style (45,15), a border (1,45); the same fill with none (45,45)" "$(_opp opZ 1 4)" "white white white black"
_ofeq "opacityT OP-6 text at opacity=0 leaves no ink: the darkest pixel on row y=18 (120 read), beside the plain word's r0" "$(_opd opZwordTop) $(grep -hc '^=== pixelAt opZwordTop ' "$T/op.o") $(_opd opBareTop)" "255 120 0"
_ofeq "opacityT OP-5 opForm as a PDF, read back: red alone, blue alone, their overlap and the wall are four different colours; red alone is not full red; the wall is the wall" "$(grep -h '^=== pixelAt pdfRead ' "$T/op.o" | sed 's/.*= //; s/ ===.*//' | sort -u | wc -l | tr -d ' ') $(grep -h '^=== pixelAt pdfRead ' "$T/op.o" | sed -n 1p | grep -c 'r239 g43 b45') $(grep -h '^=== pixelAt pdfRead ' "$T/op.o" | sed -n 4p | sed 's/.*= //; s/ ===.*//')" "4 0 r247 g232 b170 a255"

#  ⚑ italicT -- italic, a text property (Tony, 2026-11-11, SEQ 624 W1): bare italic on a field or in its held style draws the font's italic face
#  (by trait); it inherits as font and color do; italic=off turns it off below. The trace line ends " italic" only when the face DRAWN has the
#  trait, so a row reads the font that was used, not the request. IT-1 also compares the pixels of the slanted and the upright word.
echo ""
echo "-- italic (italicT)."
_itF=$(ip italicT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_itF" > "$T/it.o" 2> "$T/it.e"; _itx=$?
_itt () { for _n in "$@"; do _l=$(grep -h "^=== drawSpans $_n " "$T/it.o"); case "$_l" in "") printf 'missing ';; *" italic ===") printf 'italic ';; *) printf 'upright ';; esac; done | sed 's/ $//'; }
_itp () { grep -h "^=== pixelAt $1 " "$T/it.o" | sed 's/.*= //'; }
_ofeq "italicT exit / sentinel" "$_itx $(grep -c '^ITALIC SENTINEL' "$T/it.e")" "0 1"
_ofeq "italicT IT-1 a field's own italic, beside the same text with none: the faces drawn" "$(_itt itOwn itPlain)" "italic upright"
_itp itOwnTop > "$T/it.a"; _itp itPlainTop > "$T/it.b"
_ofeq "italicT IT-1 the two words do not paint the same pixels (4800 read of each; some differ, and each has ink)" "$(wc -l < "$T/it.a" | tr -d ' ') $(wc -l < "$T/it.b" | tr -d ' ') $([ "$(paste "$T/it.a" "$T/it.b" | awk -F'\t' '$1 != $2' | wc -l)" -gt 0 ] && echo differ || echo same) $([ "$(grep -vc 'r255 g255 b255' "$T/it.a")" -gt 0 ] && [ "$(grep -vc 'r255 g255 b255' "$T/it.b")" -gt 0 ] && echo ink || echo blank)" "4800 4800 differ ink"
_ofeq "italicT IT-2 italic inherits from an enclosing field's attribute, two levels down; IT-3 from a held style" "$(_itt itKid itStKid)" "italic italic"
_ofeq "italicT IT-4 a child's italic=off turns it off under an italic parent" "$(_itt itOff)" "upright"
_ofeq "italicT IT-5 a font with no italic face warns by name (count) and draws upright" "$(grep -c '^drawSpans: WARNING itNone -- its font has no italic face; drawn upright' "$T/it.e") $(_itt itNone)" "1 upright"
_ofeq "italicT IT-6 itForm as a PDF: one page, and the faces of its heading, upright line, italic line and the italic field's child" "$(grep -h '^=== readPDF pdfRead' "$T/it.o" | sed 's/.*pdfRead //; s/ ===.*//') $(_itt itHead itUp itSl itIn)" "pages 1 size 300x150 upright upright italic italic"

#  ⚑ resizeT -- forms step 6, stroke 2 (SEQ 626 W2, 2026-11-11): the first resize, as a plain call. redrawForm(request) lays the form out afresh
#  through setFrame and writes the PDF; frame:= in the request is the resize. The form is Windows/simple, whose three is width=50%: its leftBorder
#  sits at x=200 of 400 and at x=300 of 600. RZ-3 reads the declared size again after the resize: a rerun must read like a fresh run.
echo ""
echo "-- the mock resize (resizeT)."
_rzF=$(ip resizeT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_rzF" > "$T/rz.o" 2> "$T/rz.e"; _rzx=$?
_rzp () { grep -h '^=== pixelAt pdfRead ' "$T/rz.o" | sed -n "$1,$2p" | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/' | sed -e 's/r255 g255 b255 a255/white/' -e 's/r239 g43 b45 a255/red/' -e 's/r0 g0 b0 a255/black/' -e 's/r175 g211 b120 a255/green/' | tr '\n' ' ' | sed 's/ $//'; }
_ofeq "resizeT exit / sentinel" "$_rzx $(grep -c '^RESIZE SENTINEL' "$T/rz.e")" "0 1"
_ofeq "resizeT RZ-1 as declared, 400x200: wrap (98,70), two (150,70), three's leftBorder at 50% (200,70), three (300,70), fourth (200,170)" "$(grep -h '^=== readPDF pdfRead' "$T/rz.o" | sed -n 1p | sed 's/.*size //; s/ ===//') $(_rzp 1 5)" "400x200 white red black white green"
_ofeq "resizeT RZ-2 resized by a frame to 600x300: the page follows, and the percent: wrap (148,100), two (225,100), three's leftBorder (300,100), three (450,100), fourth (300,270); (200,100), the old border, is two's red" "$(grep -h '^=== readPDF pdfRead' "$T/rz.o" | sed -n 2p | sed 's/.*size //; s/ ===//') $(_rzp 6 11)" "600x300 white red black white green red"
_ofeq "resizeT RZ-3 back with no frame: the run after a resize reads exactly as the first" "$(grep -h '^=== readPDF pdfRead' "$T/rz.o" | sed -n 3p | sed 's/.*size //; s/ ===//') $(_rzp 12 16)" "400x200 white red black white green"
_ofeq "resizeT RZ-4 the text re-flows in the wider frame: characters of one drawn at 400, at 600, at 400 again, at 600" "$(grep -h '^=== drawSpans one ' "$T/rz.o" | sed 's/.*drawn \([0-9]*\) of.*/\1/' | tr '\n' ' ' | sed 's/ $//')" "181 266 181 266"
_ofeq "resizeT RZ-5 the definition after two resizes: simple still declares 400x200, and its deepest field (stuff, three levels down) holds no frame" "$(sed -n '/^simple x=300/,/fourth/p' "$T/rz.o" | head -1 | xargs) / $(sed -n '/^simple x=300/,/fourth/p' "$T/rz.o" | grep 'stuff' | xargs)" "simple x=300 y=450 width=400 height=200 down rounded / stuff text=one;"

#  ⚑ resizeListenT -- forms step 6, stroke 4 (2026-11-12): the resize arriving by listening. layoutFrame is the request's frame:=; onResize
#  listens to it and its action calls redrawForm. Writing the frame's width and height fires nothing; one write to layoutFrame itself fires
#  once. The points and values are resizeT's. H7 (run 2026-11-12): listenTo:= taken off onResize reads RL-2 "runs 0" and no page.
echo ""
echo "-- the resize by listening (resizeListenT)."
_rlF=$(ip resizeListenT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_rlF" > "$T/rl.o" 2> "$T/rl.e"; _rlx=$?
_rlp () { grep -h '^=== pixelAt pdfRead ' "$T/rl.o" | sed -n "$1,$2p" | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/' | sed -e 's/r255 g255 b255 a255/white/' -e 's/r239 g43 b45 a255/red/' -e 's/r0 g0 b0 a255/black/' -e 's/r175 g211 b120 a255/green/' | tr '\n' ' ' | sed 's/ $//'; }
_ofeq "resizeListenT exit / sentinel" "$_rlx $(grep -c '^RESIZELISTEN SENTINEL' "$T/rl.e")" "0 1"
_ofeq "resizeListenT RL-1 writing the frame's width and height lays nothing out (the values did land: 600, 300)" "$(grep '^RL-1 after' "$T/rl.e" | sed 's/.*: //' | xargs)" "runs 0 width 600 height 300"
_ofeq "resizeListenT RL-2 one write to layoutFrame fires one layout; the page and resizeT's five points at 600x300" "$(grep '^RL-2' "$T/rl.e" | sed 's/.*: //' | xargs) $(grep -h '^=== readPDF pdfRead' "$T/rl.o" | sed -n 1p | sed 's/.*size //; s/ ===//') $(_rlp 1 5)" "runs 1 600x300 white red black white green"
_ofeq "resizeListenT RL-3 back to 400x200 by the same road: a second layout, reading as resizeT's first run" "$(grep '^RL-3' "$T/rl.e" | sed 's/.*: //' | xargs) $(grep -h '^=== readPDF pdfRead' "$T/rl.o" | sed -n 2p | sed 's/.*size //; s/ ===//') $(_rlp 6 10)" "runs 2 400x200 white red black white green"
_ofeq "resizeListenT RL-4 the text re-flows each time (characters of one drawn at 600, at 400), and simple still declares 400x200" "$(grep -h '^=== drawSpans one ' "$T/rl.o" | sed 's/.*drawn \([0-9]*\) of.*/\1/' | xargs) / $(grep '^simple x=300' "$T/rl.o" | head -1 | xargs)" "266 181 / simple x=300 y=450 width=400 height=200 down rounded"

#  ⚑ resizeLightT -- forms step 6, stroke 4's last piece (Tony, 2026-11-12): Layout writes layoutFrame as ONE WHOLE WRITE (layoutFrame = a field holding
#  x y width height), on firstLight: PDF before, resize, PDF after. A resize must read like a fresh run, so RG-3 lays the same frame out by a plain call
#  and is compared with RG-2 by value. Control (measured 2026-11-12, before GroupItem.setContent kept and told the listeners on a whole-list write):
#  the one write fired nothing (runs 0) and removed layoutFrame's listener list.
echo ""
echo "-- firstLight resized by one whole write to layoutFrame (resizeLightT)."
_rgF=$(ip resizeLightT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_rgF" > "$T/rg.o" 2> "$T/rg.e"; _rgx=$?
_rgc () { sed -e 's/r255 g255 b255 a255/white/g' -e 's/r247 g232 b170 a255/wall/g' -e 's/r175 g211 b120 a255/green/g'; }
#  one block per PDF read: the page size, its points, and the words field's line count drawn just before it
_rgb () { awk -v n="$1" '/drawSpans words /{w=$0} /readPDF pdfRead/{k++; if(k==n){sub(/.*size /,""); sub(/ ===.*/,""); printf "%s ", $0; sub(/.*lines /,"",w); sub(/ drawn.*/,"",w); printf "lines %s ", w}} /pixelAt pdfRead/ && k==n {sub(/.*= /,""); sub(/ ===.*/,""); printf "%s ", $0}' "$T/rg.o" | _rgc | xargs; }
_ofeq "resizeLightT exit / sentinel" "$_rgx $(grep -c '^RESIZELIGHT SENTINEL' "$T/rg.e")" "0 1"
#  RG-1 / RG-2 RE-PINNED 2026-11-12 (the typesetting slice): words holds a second paragraph of one line, so it draws 4 lines at 400 wide and 3 at 600, where it drew 3 and 2
_ofeq "resizeLightT RG-1 before, as declared: no listener run; 400x400, words in 4 lines; heading wall, words white, space wall, ok green" "$(grep '^RG-1' "$T/rg.e" | sed 's/.*: //' | xargs) / $(_rgb 1)" "runs 0 / 400x400 lines 4 wall white wall green"
_ofeq "resizeLightT RG-2 one whole write resizes: one run, all four values arrived; 600x600, words in 3 lines; the four fields at their new places; where ok was is words' white" "$(grep '^RG-2' "$T/rg.e" | sed 's/.*: //' | xargs) / $(_rgb 2)" "runs 1 width 600 height 600 / 600x600 lines 3 wall white wall green white"
_ofeq "resizeLightT RG-3 A RESIZE READS LIKE A FRESH RUN: the same frame by a plain call (no listener run) = RG-2's page, by value" "$(grep '^RG-3' "$T/rg.e" | sed 's/.*: //' | xargs) / $(_rgb 3)" "runs 1 / $(_rgb 2)"
_ofeq "resizeLightT RG-4 resized back by the same road: a second run; the page = RG-1's, by value" "$(grep '^RG-4' "$T/rg.e" | sed 's/.*: //' | xargs) / $(_rgb 4)" "runs 2 width 400 height 400 / $(_rgb 1)"
_ofeq "resizeLightT RG-5 four pages were read, and firstLight still declares 400x400" "$(grep -c 'readPDF pdfRead' "$T/rg.o") / $(grep '^firstLight x=300' "$T/rg.o" | head -1 | cut -d' ' -f1-5)" "4 / firstLight x=300 y=450 width=400 height=400"

#  ⚑ typesetT -- typesetting's first slice (Tony, 2026-11-12), in firstLight: two paragraphs in one field separated by a blank line, wrapping in its
#  frame, and one {styleName: text} run in the second. The bands are read from the PDF. Controls: the gap band beside the before band (ink there, none
#  in the gap); the run band beside the before and after bands (red and no blue, against blue and no red). Before the slice the same text drew as one
#  paragraph with the braces printed.
echo ""
echo "-- paragraphs and one run in firstLight (typesetT)."
_tyF=$(ip typesetT)
perl -e 'alarm 120; exec @ARGV' "$B" "$_tyF" > "$T/ty.o" 2> "$T/ty.e"; _tyx=$?
_tyb () { awk -v want="$1" '/^TY BAND/{b=$3} /pixelAt pdfRead/ && b==want { s=$0; sub(/.*= r/,"",s); split(s,a,/[ rgba=]+/); if(a[1]>180&&a[2]<140&&a[3]<140) red++; if(a[3]>120&&a[1]<120) blue++; if(!(a[1]>240&&a[2]>240&&a[3]>240)) ink++; n++ } END{ printf "%s %s %s", (ink?"ink":"none"), (red?"red":"nored"), (blue?"blue":"noblue") }' "$T/ty.o"; }
_tyl () { grep -h "^=== drawSpans $1 " "$T/ty.o" | sed 's/.* lines /lines /; s/ valign.*align [a-z]*//; s/ ===//' | xargs; }
_ofeq "typesetT exit / sentinel" "$_tyx $(grep -c '^TYPESET SENTINEL' "$T/ty.e")" "0 1"
_ofeq "typesetT TY-1 firstLight's words: two paragraphs, one run, every character drawn in four lines" "$(_tyl words)" "lines 4 drawn 205 of 205 next end paragraphs 2 of 2 runs 1"
_ofeq "typesetT TY-2 THE BLANK LINE: no ink across the field between the paragraphs (y 98..102); the line below it has ink" "$(_tyb gap) / $(_tyb before)" "none nored noblue / ink nored blue"
_ofeq "typesetT TY-3 THE RUN: its band is red with no blue; before it and after it the ink is blue with no red" "$(_tyb run) / $(_tyb before) / $(_tyb after)" "ink red noblue / ink nored blue / ink nored blue"
_ofeq "typesetT TY-4 {{ is a literal brace: five characters, no run" "$(_tyl tsLit)" "lines 1 drawn 5 of 5 next end"
_ofeq "typesetT TY-5 an unknown style warns by name and prints plain" "$(_tyl tsBad) / $(grep -c '^drawSpans: WARNING tsBad -- its text names the style nosuch -- not a style' "$T/ty.e")" "lines 1 drawn 5 of 5 next end paragraphs 1 of 1 runs 1 / 1"
_ofeq "typesetT TY-6 a run with no closing mark ends at its paragraph's end: two paragraphs, one run, no warning for it" "$(_tyl tsOpen) / $(grep -c 'WARNING tsOpen' "$T/ty.e")" "lines 2 drawn 8 of 8 next end paragraphs 2 of 2 runs 1 / 0"
_ofeq "typesetT TY-7 runs nest; TY-8 an insertion naming no field is left as written; TY-10 a single line end is a space" "$(_tyl tsNest) / $(_tyl tsIns) / $(_tyl tsWrapped)" "lines 1 drawn 9 of 9 next end paragraphs 1 of 1 runs 2 / lines 1 drawn 15 of 15 next end / lines 1 drawn 25 of 25 next end"
_ofeq "typesetT TY-9 three paragraphs in a field with room for one line: one drawn, the stop is at a paragraph, and the field is named" "$(_tyl tsThree) / $(grep -c '^drawSpans: WARNING tsThree -- its text does not fit its frame; 3 of 11 characters drawn' "$T/ty.e")" "lines 1 drawn 3 of 11 next paragraph paragraphs 1 of 3 runs 0 / 1"
_ofeq "typesetT TY-11 a run of spaces is one gap (T1): a, four spaces, b draws three characters" "$(_tyl tsCollapse)" "lines 1 drawn 3 of 3 next end"
_ofeq "typesetT TY-12 a mark takes no room: xyz; the space by a closing mark is one gap after the span before it" "$(_tyl tsGlue) / $(_tyl tsAfter)" "lines 1 drawn 3 of 3 next end paragraphs 1 of 1 runs 1 / lines 1 drawn 7 of 7 next end paragraphs 1 of 1 runs 2"
_ofeq "typesetT TY-13 the gap's width is the style's space: space=280 wraps at each gap, the same text in a style with none is one line" "$(_tyl tsWide) / $(_tyl tsNarrow)" "lines 3 drawn 5 of 5 next end paragraphs 1 of 1 runs 1 / lines 1 drawn 5 of 5 next end paragraphs 1 of 1 runs 1"
_ofeq "typesetT TY-14 space=N% is a percent of the font's own space: 20000% wraps at each gap, 300% is one line (as points it would wrap)" "$(_tyl tsPct) / $(_tyl tsSame)" "lines 3 drawn 5 of 5 next end paragraphs 1 of 1 runs 1 / lines 1 drawn 5 of 5 next end paragraphs 1 of 1 runs 1"
_ofeq "typesetT TY-15 a run's style holding a colour by value (color=#ef2b2d): its band has red ink beside the field's blue" "$(_tyb hex)" "ink red blue"
_ofeq "typesetT TY-8b (T3) an insert naming no field of the form warns by name, once" "$(grep -c '^drawSpans: WARNING tsIns -- its text inserts name -- no field of that name in the form; left as written' "$T/ty.e")" "1"
_ofeq "typesetT TY-16 (T3) {name} inserts a field's text, twice in one text: see alpha beta and alpha beta here, 34 characters; the source field draws its own 10" "$(_tyl tsGot) / $(_tyl tsSrc)" "lines 1 drawn 34 of 34 next end / lines 1 drawn 10 of 10 next end"
_ofeq "typesetT TY-17 (T3) an insert inside a run takes the run's style: 14 characters, one run, and its band has red ink beside the field's blue" "$(_tyl tsRunIns) / $(_tyb insrun)" "lines 1 drawn 14 of 14 next end paragraphs 1 of 1 runs 1 / ink red blue"
_ofeq "typesetT TY-18 {registry.name} looks in that registry only and {name} in the form only: two fields named tsSrc with different texts, 28 and 19 characters" "$(_tyl tsQ) / $(_tyl tsQform)" "lines 1 drawn 28 of 28 next end / lines 1 drawn 19 of 19 next end"
_ofeq "typesetT TY-19 a name that is not a registry, and an entry the registry lacks: each left as written (21, 25) and each warned by name" "$(_tyl tsQnoReg) / $(_tyl tsQnoEnt) / $(grep -c '^drawSpans: WARNING tsQnoReg -- its text inserts from nosuchReg -- not a registry; left as written' "$T/ty.e") $(grep -c '^drawSpans: WARNING tsQnoEnt -- its text inserts nosuch from dESCRIPTIONs -- that registry has no such entry; left as written' "$T/ty.e")" "lines 1 drawn 21 of 21 next end / lines 1 drawn 25 of 25 next end / 1 1"

#  ⚑ drawFieldsT -- SEQ 629 (2026-11-12): the drawing fields, spelled capital first and last, defined in FORMs at the top of Topics/forms.
#  DF-3 is why the spelling: an attribute spelled exactly like a FORMs field is the registry's one field. H7 (run 2026-11-12): without
#  include(forms) DF-1 reads 2 and DF-3's second half reads 100 300.
echo ""
echo "-- the drawing fields in FORMs (drawFieldsT)."
perl -e 'alarm 30; exec @ARGV' "$B" "$(ip drawFieldsT)" > "$T/df.o" 2> "$T/df.e"; _dfx=$?
_ofeq "drawFieldsT exit / sentinel" "$_dfx $(grep -c '^DRAWFIELDS SENTINEL' "$T/df.e")" "0 1"
_ofeq "drawFieldsT DF-1 FORMs holds 35 drawing fields, 28 form attributes, 7 unparked drawing entries and this file's three" "$(grep '^DF-1' "$T/df.e" | sed 's/.*holds *//' | xargs)" "73"
_ofeq "drawFieldsT DF-2 LinE carries its Core Graphics call, once; X is defined" "$(grep -c '^	LinE function=CGContextAddLineToPoint signature=v:pdY;' "$T/df.o") $(grep -c '^	X;' "$T/df.o")" "1 1"
#  DF-3 / DF-4 (Tony, 2026-11-12, rulings 1 and then 3 of the next dispatch): every FORMs field a form writes is virtual, the drawing fields included, so each
#  write is the writing field's own copy and the registry's definition keeps no value. The control is dfShared, defined in the fixture and NOT virtual: the same
#  three writes all land in the registry's one field (300 300). The cure's own control: with every fixture loading these definitions and resolveName's
#  virtualInCode lines absent, this script read 128 green (2026-11-12, and seal 460-461's recon).
_ofeq "drawFieldsT DF-3 width= and WidtH= are each field's own (100, 300); dfShared=, not virtual, is the registry's one field (300, 300)" "$(grep '^DF-3' "$T/df.e" | sed 's/.*: //' | xargs)" "dfA width 100 dfB width 300 dfA WidtH 100 dfB WidtH 300 dfA dfShared 300 dfB dfShared 300"
_ofeq "drawFieldsT DF-4 the registry's width, fill and WidtH keep no value; dfShared holds the last write" "$(grep -c '^	width;' "$T/df.o") $(grep -c '^	fill;' "$T/df.o") $(grep -c '^	WidtH function=CGContextSetLineWidth signature=v:pd;' "$T/df.o") $(grep -c '^	dfShared=300;' "$T/df.o")" "1 1 1 1"
#  DF-5 the unparked perforation templates: a template naming one field several times keeps each value (before virtual each write landed in the one definition)
_ofeq "drawFieldsT DF-5 PerfRighT keeps its two DowN apart; PerforatioN's PerfLefT=5 is its own and the registry's PerfLefT keeps no value" "$(grep -c '^	PerfRighT DowN=GaP LefT=DeptH DowN=StridE RighT=DeptH;' "$T/df.o") $(grep '^DF-5' "$T/df.e" | awk '{print $NF}') $(grep -c '^	PerfLefT RighT=DeptH UP=StridE LefT=DeptH UP=GaP;' "$T/df.o") $(grep -c '^	DowN;' "$T/df.o")" "1 5 1 1"
_ofeq "drawFieldsT DF-6 PoinT, ArC and CurvE are defined as rule shapes" "$(grep -c '^	PoinT toX toY;' "$T/df.o") $(grep -c '^	ArC from to RadiuS;' "$T/df.o") $(grep -c '^	CurvE function=CGContextAddCurveToPoint signature=? target control1 control2;' "$T/df.o")" "1 1 1"

#  ⚑ noRoomT -- forms step 6, the rest (SEQ 627 W1, 2026-11-11): what is DRAWN under isHidden and noRoom. The layout rows are in pop.sh. nrForm is
#  200 by 100. H7 (run 2026-11-11): with drawKids' skip removed, (165,20) reads red (nOut is drawn) and NP-1 goes red.
echo ""
echo "-- isHidden and noRoom, drawn (noRoomT)."
_npF=$(ip noRoomT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_npF" > "$T/np.o" 2> "$T/np.e"; _npx=$?
_npp () { grep -h '^=== pixelAt pdfRead ' "$T/np.o" | sed -n "$1,$2p" | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/' | sed -e 's/r255 g255 b255 a255/white/' -e 's/r239 g43 b45 a255/red/' -e 's/r0 g0 b0 a255/black/' -e 's/r175 g211 b120 a255/green/' | tr '\n' ' ' | sed 's/ $//'; }
_ofeq "noRoomT exit / sentinel / page" "$_npx $(grep -c '^NOROOM SENTINEL' "$T/np.e") $(grep -h '^=== readPDF pdfRead' "$T/np.o" | sed 's/.*size //; s/ ===//')" "0 1 200x100"
_ofeq "noRoomT NP-1 a noRoom field is not drawn: where nOut (red) would be, (165,20), is the form's white; beside it nIn (25,20) is drawn red" "$(_npp 3 3) $(_npp 1 1)" "white red"
_ofeq "noRoomT NP-2 partly outside is drawn: nPart past nBox's edge (110,20) green; nC running off the foot (100,90) red" "$(_npp 2 2) $(_npp 5 5)" "green red"
_ofeq "noRoomT NP-3 a hidden field is not drawn and takes no room: (100,55) is nB's green, where the hidden nH would have left nRow's white or its own red" "$(_npp 4 4)" "green"

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
