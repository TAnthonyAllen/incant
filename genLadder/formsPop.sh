#!/bin/sh
export INCANT_NOVIEW=1   # SEQ 686: show never opens a viewer from a script of Clod's
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
pixel   "no fill -> nothing drawn" "$T/f.o" 1 dsNoFill "r0 g0 b0 a0"
#  RE-PINNED 2026-11-14 (SEQ 657, F-156): the wording, with the floor's style read gone
hasmark "no fill -> REFUSES BY NAME" "$T/f.e" \
        "displayFill: REFUSING dsNoFill -- it names no fill"

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
pixel "fire 1 -- compiled, fill from djStyle"  "$T/j.o" 2 djCanvas "r255 g0 b0 a255"
#  ⚠ THE PROOF. Under jitting the interpreter runs the body FOR REAL at emit
#  time, so a correct pixel after one fire proves nothing -- the emit-time pass
#  could have painted it. Fire 2 recompiles NOTHING and the STYLE NODE was
#  swapped after emission. If the pixel tracks it, the fill ran from compiled
#  code. The two fires want DIFFERENT ANSWERS, not merely different inputs.
pixel "fire 2 -- NO recompile, fill rewritten" "$T/j.o" 3 djCanvas "r0 g128 b128 a255"
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
#  RE-AIM SEQ 684 (Tony's settled forms, 2026-11-17): firstLight is 500x600 with inside 60%, so words ends at y=204 (was 164),
#  bar spans y 205..239 (was 165..199) and ok x 440..499 (was 340..399). Rows below that read firstLight's frames are re-aimed by
#  those offsets; the question each asks and its intended value are unchanged unless the row says so.
fdRow "fillPageT FP-4 just below words, page (5,206), reads wall" "$(_fpp bar)" "" "r247 g232 b170 a255/"
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
fdRow "drawWalkT DW-1 heading has no fill: the top's wall shows, page (450,15)" "$(_dwp heading)" "r0 g0 b0 a0/" "r247 g232 b170 a255/"
fdRow "drawWalkT DW-2 words, depth 1, white, page (5,100)" "$(_dwp words)" "r0 g0 b0 a0/" "r255 g255 b255 a255/"
fdRow "drawWalkT DW-3 space, depth 2, no fill: wall, page (100,220)" "$(_dwp space)" "r0 g0 b0 a0/" "r247 g232 b170 a255/"
fdRow "drawWalkT DW-4 ok, depth 2, lightGreen, page (490,230)" "$(_dwp ok)" "r0 g0 b0 a0/" "r175 g211 b120 a255/"
#  forms step 2 R2 (2026-11-08): the right way up, each side of an edge; a flipped child lands 5 points off and fails a pair
#  BORDERS REGISTERED (forms step 3, before the build): DW-5 and DW-6 move with the border by design -- (5,29) is heading's bottom row,
#  (399,199) and (341,165) lie on ok's edges. Width sits inside the frame (Tony), so nothing outside a field's frame is painted.
#  SEQ 583 (heading 43, colour in firstLight), REGISTERED BEFORE THE FORM CHANGE: DW-5, DW-8, DW-9 (both), PD-3, PD-4 re-aimed to heading's new
#  bottom edge y=42 (they keep asking about heading's border and words' top); DW-6, DW-7, PD-2 move as ok's border turns red (strokeColor:=red).
fdRow "drawWalkT DW-5 words' edges (5,42) (5,44) (5,204) (5,206): heading's bottomBorder, white, white, wall" "$(_dwpr words 2 5)" "r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r247 g232 b170 a255/" "r0 g0 b0 a255/r255 g255 b255 a255/r255 g255 b255 a255/r247 g232 b170 a255/"
fdRow "drawWalkT DW-6 ok's edges (439,230) (441,230) (499,239) (441,205) (441,204); (499,239) and (441,205) are ok's border, red" "$(_dwpr ok 2 6)" "r247 g232 b170 a255/r175 g211 b120 a255/r0 g0 b0 a255/r0 g0 b0 a255/r255 g255 b255 a255/" "r247 g232 b170 a255/r175 g211 b120 a255/r239 g43 b45 a255/r239 g43 b45 a255/r255 g255 b255 a255/"
_dwcnt () { grep -h '^=== pixelAt '"$1"' ' "$T/dw.o" "$T/dw.e" 2>/dev/null | sed -n "$2,$3p" | grep -c "$4"; }
fdRow "drawWalkT DW-7 ok's plain border, inside / outside: left (440,220) (439,220), top (460,205) (460,204), right (499,220) (498,220), bottom (460,239) (460,238); inside red" "$(_dwpr ok 7 14)" "r0 g0 b0 a255/r247 g232 b170 a255/r0 g0 b0 a255/r255 g255 b255 a255/r0 g0 b0 a255/r175 g211 b120 a255/r0 g0 b0 a255/r175 g211 b120 a255/" "r239 g43 b45 a255/r247 g232 b170 a255/r239 g43 b45 a255/r255 g255 b255 a255/r239 g43 b45 a255/r175 g211 b120 a255/r239 g43 b45 a255/r175 g211 b120 a255/"
fdRow "drawWalkT DW-8 heading's bottomBorder: inside (5,42) black, outside (5,43) white" "$(_dwpr heading 2 3)" "r255 g255 b255 a255/r255 g255 b255 a255/" "r0 g0 b0 a255/r255 g255 b255 a255/"
#  DW-9 RE-AIMED SEQ 684 though it stayed green: its right column and its rows stopped at x=399, inside a heading 500 wide, so the
#  row no longer read heading's right side. Now x 0..499 and x=499: 500 + 42 + 42 = 584 pixels, then 500 on the bottom row.
fdRow "drawWalkT DW-9 heading's other three sides unpainted: pixels not wall / pixels read (top row, left and right columns y 0..41)" "$(_dwcnt heading 4 587 'r247 g232 b170 a255' | awk '{print 584-$1}')/$(grep -h '^=== pixelAt heading ' "$T/dw.o" | sed -n '4,587p' | wc -l | tr -d ' ')" "26/584" "0/584"
fdRow "drawWalkT DW-9 heading's bottom row painted: black pixels / pixels read (y=42, x 0..499)" "$(_dwcnt heading 588 1087 'r0 g0 b0 a255')/$(grep -h '^=== pixelAt heading ' "$T/dw.o" | sed -n '588,1087p' | wc -l | tr -d ' ')" "27/500" "500/500"
fdRow "drawWalkT DW-10 width 3, own strokeColor=blue: left (0..3,10), top (10,0..3) -- three painted, the fourth not" "$(_dwpr dwThick 1 8)" "r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/r255 g255 b255 a255/" "r0 g81 b186 a255/r0 g81 b186 a255/r0 g81 b186 a255/r255 g255 b255 a255/r0 g81 b186 a255/r0 g81 b186 a255/r0 g81 b186 a255/r255 g255 b255 a255/"
fdRow "drawWalkT DW-11 colour from the style (dwSt strokeColor red): (0,5) painted, (1,5) not" "$(_dwpr dwStyled 1 2)" "r255 g255 b255 a255/r255 g255 b255 a255/" "r239 g43 b45 a255/r255 g255 b255 a255/"
_ofeq "drawWalkT DW-12 x past the width refuses by name, and no pixel line for it (ok's reads stay 14)" "$(grep -c '^pixelAt: ok (500,220) OUT OF RANGE' "$T/dw.e") $(grep -h '^=== pixelAt ok ' "$T/dw.o" | wc -l | tr -d ' ')" "1 14"
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
    echo "$(_txInk $(_txs "$1" "$2" 4 495 18 18 "$_txWall" count)) $(_txInk $(_txs "$1" "$2" 4 203 55 55 "$_txWhite" count)) $(_txInk $(_txs "$1" "$2" 4 203 70 70 "$_txWhite" count)) $(_txFlush $(_txs "$1" "$2" 0 29 49 58 "$_txWhite" minx) $(_txs "$1" "$2" 0 29 64 73 "$_txWhite" minx)) $(_txOrient $(_txs "$1" "$2" 3 12 49 51 "$_txWhite" count) $(_txs "$1" "$2" 3 12 55 57 "$_txWhite" count)) $(_txInk $(_txs "$1" "$2" 442 497 220 220 "$_txGreen" count))"
}
#  _txTrace <tag> <field>: a field of drawSpans's line for that field (font / color / lines / next)
_txTrace () { grep -h "^=== drawSpans $1 " "$T/tx.o" "$T/tx.e" 2>/dev/null | head -1 | sed "s/^=== drawSpans $1 //; s/ ===\$//" | awk -v want="$2" '
    { for (i = 1; i <= NF; i++) { if ($i == "font") f = $(i+1) " " $(i+2) " " $(i+3); if ($i == "color") c = $(i+1) " " $(i+2) " " $(i+3)
      if ($i == "lines") l = $(i+1); if ($i == "next") nx = $(i+1) } }
    END { if (want == "font") print f; else if (want == "color") print c; else if (want == "lines") print l " " nx }'; }
_ofeq "textT exit / sentinel" "$_txx $(grep -c '^TEXTT SENTINEL' "$T/tx.e")" "0 1"
fdRow "textT TX-1 heading's text inks its line: y=18, x 4..495, not wall" "$(_txInk $(_txs "$T/tx.o" firstLight 4 495 18 18 "$_txWall" count))" "none" "ink"
fdRow "textT TX-2 words' first line inks: y=55, x 4..203, not white" "$(_txInk $(_txs "$T/tx.o" firstLight 4 203 55 55 "$_txWhite" count))" "ink" "ink"
fdRow "textT TX-3 WRAP: words' second line inks: y=70, x 4..203" "$(_txInk $(_txs "$T/tx.o" firstLight 4 203 70 70 "$_txWhite" count))" "ink" "ink"
fdRow "textT TX-4 WRAP, no indent: first ink of line 1 (y 49..58) and line 2 (y 64..73) at the same x, within 2, at most 7" "$(_txFlush $(_txs "$T/tx.o" firstLight 0 29 49 58 "$_txWhite" minx) $(_txs "$T/tx.o" firstLight 0 29 64 73 "$_txWhite" minx))" "flush" "flush"
fdRow "textT TX-5 ORIENTATION: the T of This, bar rows y 49..51 outweigh stem rows y 55..57, x 3..12" "$(_txOrient $(_txs "$T/tx.o" firstLight 3 12 49 51 "$_txWhite" count) $(_txs "$T/tx.o" firstLight 3 12 55 57 "$_txWhite" count))" "flipped" "upright"
#  RE-AIM (SEQ 605, step 5b): ok is centred top to bottom, so its letters sit about 6 lower. TX-6, TX-K3 and the ok point of _txClasses ask
#  about ink and colour, not position, so their row moves from y=176 to y=180, inside the letters at the top and at the centre alike; pinned
#  values unchanged. firstPdfT reads y=180 from its PD-9 band.
fdRow "textT TX-6 ok's text inks: y=220, x 442..497, not lightGreen" "$(_txInk $(_txs "$T/tx.o" firstLight 442 497 220 220 "$_txGreen" count))" "none" "ink"
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
fdRow "textT TX-K1 heading's ink is green: its darkest ink pixel's strongest channel (y=18, x 4..495)" "$(_txHue "$T/tx.o" firstLight 4 495 18 18 "$_txWall")" "none" "g"
fdRow "textT TX-K2 words' ink is blue, inherited (y=55, x 4..203)" "$(_txHue "$T/tx.o" firstLight 4 203 55 55 "$_txWhite")" "k" "b"
fdRow "textT TX-K3 ok's ink is blue, inherited through bar (y=220, x 442..497)" "$(_txHue "$T/tx.o" firstLight 442 497 220 220 "$_txGreen")" "k" "b"
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
#  _alClasses <file> <tag>: heading centred, words line 1, line 2, paragraph 2's line (justify, SEQ 684: edge short short -- at 500 wide
#  paragraph 1 is two lines, so line 2 is its last and stops short)
_alClasses () { echo "$(_txCentre "$1" "$2" 0 499 10 28 "$_txWall" 0 499) $(_txEdge "$1" "$2" 400 499 49 60 "$_txWhite" 495) $(_txEdge "$1" "$2" 400 499 64 75 "$_txWhite" 495) $(_txEdge "$1" "$2" 0 499 93 108 "$_txWhite" 495)"; }
fdRow "textT AL-1 CENTER: heading's ink centred in its frame (x 0..499, y 10..28)" "$(_txCentre "$T/tx.o" firstLight 0 499 10 28 "$_txWall" 0 499)" "off 4 282" "centred"
#  AL-2, TX-6, VA-1 RE-AIMED SEQ 684 though they stayed green: their boxes (x 342..397) now lie on words' white, which is not ok's
#  lightGreen background, so a full-width box of "ink" read as centred. Moved to ok's frame, x 440..499, y 205..239.
fdRow "textT AL-2 CENTER: ok's ink centred in its frame (x 440..499; scanned 442..497, y 208..236)" "$(_txCentre "$T/tx.o" firstLight 442 497 208 236 "$_txGreen" 440 499)" "off 4 34" "centred"
#  AL-3 RE-AIMED SEQ 684, AND ITS EXPECTED SHAPE MOVES WITH THE WIDTH: at 500 wide paragraph 1 wraps in two lines, not three, so the
#  justified line is line 1 only; line 2 is the paragraph's last and stops short, as does paragraph 2's one line. Edge 495 = 500 - 4 - 1.
fdRow "textT AL-3 JUSTIFY: words' line 1 ends at x 495 (496 less a pixel); line 2, paragraph 1's last, does not; nor paragraph 2's line" "$(_txEdge "$T/tx.o" firstLight 400 499 49 60 "$_txWhite" 495) $(_txEdge "$T/tx.o" firstLight 400 499 64 75 "$_txWhite" 495) $(_txEdge "$T/tx.o" firstLight 0 499 93 108 "$_txWhite" 495)" "short short short" "edge short short"
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
fdRow "textT VA-1 CENTER: ok's ink centred top to bottom in its frame (y 205..239; scanned inside the border, 207..237, x 442..497)" "$(_tyCentre "$T/tx.o" firstLight 442 497 207 237 "$_txGreen" 205 239)" "off 5 18" "centred"
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
_pdO=/tmp/incantTest.pdf
rm -f "$_pdO"
perl -e 'alarm 20; exec @ARGV' "$B" "$_pdF" > "$T/pd.o" 2> "$T/pd.e"; _pdx=$?
_pdp () { grep -h '^=== pixelAt pdfRead ' "$T/pd.o" "$T/pd.e" 2>/dev/null | sed -n "$1,$2p" | sed 's/.*= \(r[0-9]* g[0-9]* b[0-9]* a[0-9]*\) ===.*/\1/' | tr '\n' '/'; }
_ofeq "firstPdfT exit / sentinel" "$_pdx $(grep -c '^FIRSTPDF SENTINEL' "$T/pd.e")" "0 1"
fdRow "firstPdfT the file exists and begins %PDF" "$([ -s "$_pdO" ] && head -c 4 "$_pdO" || echo none)" "none" "%PDF"
#  RE-PINNED 2026-11-13 (G2 stroke 1b): firstLight is 400x400, its lower half holding the descriptions form.
#  RE-PINNED SEQ 684: firstLight is 500x600 (Tony's settled edit); PD-1, PD-2, PD-4 re-aimed by the same offsets as drawWalkT.
fdRow "firstPdfT readPDF: one page, firstLight's frame (500 x 600 points)" "$(grep '^=== readPDF pdfRead' "$T/pd.o" "$T/pd.e" 2>/dev/null | sed 's/.*pdfRead //; s/ ===.*//')" "" "pages 1 size 500x600"
#  RE-AIM (SEQ 582, forms step 5, 2026-11-09): text now draws in heading and ok, over (5,15) and (360,180). These rows ask about FILL, so the point
#  moves off the text, to (300,15) and (390,190), where the same fill shows; pinned values unchanged.
fdRow "firstPdfT PD-1 read back: heading (450,15) wall, words (5,100) white, space (100,220) wall, ok (490,230) lightGreen" "$(_pdp 1 4)" "" "r247 g232 b170 a255/r255 g255 b255 a255/r247 g232 b170 a255/r175 g211 b120 a255/"
fdRow "firstPdfT PD-2 read back: ok's border left (440,220) red / (439,220) wall, top (460,205) red / (460,204) white" "$(_pdp 5 8)" "r0 g0 b0 a255/r247 g232 b170 a255/r0 g0 b0 a255/r255 g255 b255 a255/" "r239 g43 b45 a255/r247 g232 b170 a255/r239 g43 b45 a255/r255 g255 b255 a255/"
fdRow "firstPdfT PD-3 read back: heading's bottom line (5,42) black, (5,43) white" "$(_pdp 9 10)" "r255 g255 b255 a255/r255 g255 b255 a255/" "r0 g0 b0 a255/r255 g255 b255 a255/"
fdRow "firstPdfT PD-4 read back, the right way up: (5,44) white, (5,206) wall" "$(_pdp 11 12)" "r255 g255 b255 a255/r247 g232 b170 a255/" "r255 g255 b255 a255/r247 g232 b170 a255/"
#  PD-5 RE-PINNED (SEQ 583): its words scans moved 13 down with heading, so today (heading 30) the shifted scans read line 2 and words's edge;
#  intended unchanged.
#  PD-5 (forms step 5, SEQ 582): the text read back at textT's firstLight points, classified as textT's bitmap is; the PDF agrees with the bitmap.
fdRow "firstPdfT PD-5 the text read back: heading, words line 1, line 2, no indent, orientation, ok" "$(_txClasses "$T/pd.o" pdfRead)" "none ink ink flush flipped ink" "ink ink ink flush upright ink"
_ofeq "firstPdfT PD-6 the PDF agrees with the bitmap on the same points (textT's classes)" "$(_txClasses "$T/pd.o" pdfRead)" "$(_txClasses "$T/tx.o" firstLight)"
#  PD-7 / PD-8 (step 5a, SEQ 584): heading centred and words justified, read back from the PDF at textT's AL points; the PDF agrees with the bitmap.
fdRow "firstPdfT PD-7 the read-back: heading centred, words line 1 at the edge, line 2 and paragraph 2's line short (SEQ 684, as AL-3)" "$(_alClasses "$T/pd.o" pdfRead)" "off 4 282 short short short" "centred edge short short"
_ofeq "firstPdfT PD-8 the PDF agrees with the bitmap on the centre and justify points" "$(_alClasses "$T/pd.o" pdfRead)" "$(_alClasses "$T/tx.o" firstLight)"
#  PD-9 / PD-10 (step 5b, SEQ 605): ok centred top to bottom, read back from the PDF inside ok's border; the PDF agrees with the bitmap.
fdRow "firstPdfT PD-9 the read-back: ok's ink centred top to bottom in its frame" "$(_tyCentre "$T/pd.o" pdfRead 442 497 207 237 "$_txGreen" 205 239)" "off 5 18" "centred"
_ofeq "firstPdfT PD-10 the PDF agrees with the bitmap on ok's first and last ink rows, within 1" "$(_p=$(( $(_tys "$T/pd.o" pdfRead 442 497 207 237 "$_txGreen" miny) - $(_tys "$T/tx.o" firstLight 442 497 207 237 "$_txGreen" miny) )); _q=$(( $(_tys "$T/pd.o" pdfRead 442 497 207 237 "$_txGreen" maxy) - $(_tys "$T/tx.o" firstLight 442 497 207 237 "$_txGreen" maxy) )); [ ${_p#-} -le 1 ] && [ ${_q#-} -le 1 ] && echo agree || echo "differ $_p $_q")" "agree"

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
#  RE-PINNED SEQ 684 (Tony's settled edit: describeHelp height=20%): describeHelp is 120 high, y 480..599, so second (and saber and
#  trees beside each other in it) is 430 high, not 275. DE-4's describeHelp-top point and DE-10's moved with it, (100,325) -> (100,480).
fdRow "descT DE-1 ACROSS: saber and trees side by side, each half of second (flex is gone, across is written)" "$(_deFr saber) / $(_deFr trees)" "500x138 at 500,250 / 500x137 at 500,388" "250x430 at 500,250 / 250x430 at 750,250"
fdRow "descT DE-2 the heading's text: titleFont, white, centred both ways (font:= color:= align valign)" "$(_det describeHead)" "font Helvetica 12 0 color r0 g0 b0 valign top align left" "font Palatino 24 1 color r255 g255 b255 valign center align center"
#  RE-AIM (SEQ 609): saber's and trees' points sit under their images once images draw, so DE-3 keeps the two fills nothing covers; pinned at
#  the values those two points read already. The image fields' points are DE-9's.
fdRow "descT DE-3 FILLS (fill:=): first lightGreen (10,10), describeHelp lightGreen (100,550)" "$(_dep 10,10)/$(_dep 100,550)" "r175 g211 b120 a255/r175 g211 b120 a255" "r175 g211 b120 a255/r175 g211 b120 a255"
fdRow "descT DE-4 BORDERS (bordered -> border): saber's left (0,300), trees' left (250,300), describeHelp's top (100,480), black" "$(_dep 0,300)/$(_dep 250,300)/$(_dep 100,480)" "r0 g0 b0 a0/r0 g0 b0 a0/r0 g0 b0 a0" "r0 g0 b0 a255/r0 g0 b0 a255/r0 g0 b0 a255"
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
_ofeq "descT DE-10 THE PDF: one page written, 500x600; its fills and borders agree with the bitmap (first, describeHelp; saber's left, trees' left, describeHelp's top)" "$(grep -h '^=== readPDF pdfRead' "$T/de.o" | sed 's/^=== readPDF pdfRead //; s/ ===$//' | xargs) / $(_depp 10,10) $(_depp 100,550) $(_depp 0,300) $(_depp 250,300) $(_depp 100,480)" "pages 1 size 500x600 / $(_dep 10,10) $(_dep 100,550) $(_dep 0,300) $(_dep 250,300) $(_dep 100,480)"
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
_ofeq "formNestT NF-5 firstLight holds descriptions in its lower half: heading's wall (450,15), the held form's lightGreen heading field (10,250), ok's green (490,230) (re-aimed SEQ 684)" "$(_nfp light)" "r247 g232 b170 a255 / r175 g211 b120 a255 / r175 g211 b120 a255"

echo "-- the swap: G2 stroke 2 (swapT)."
#  ⚑ swapT -- the swap (Tony, 2026-11-13): firstLight's inside names insideForm, a field of its own holding the form to show; one write to it tells
#  its listener, which redraws, and a different form appears in the field. Controls: the swapped page beside the before page at the same point;
#  heading and ok unmoved on every page.
_swF=$(ip swapT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_swF" > "$T/sw.o" 2> "$T/sw.e"; _swx=$?
_swp () { awk -v want="$1" '/^SW PAGE/{b=$3} /pixelAt pdfRead/ && b==want { s=$0; sub(/.*= /,"",s); sub(/ ===.*/,"",s); printf "%s%s", sep, s; sep=" / " }' "$T/sw.o"; }
_swt () { awk -v want="$1" '/^SW PAGE/{b=$3} /^=== drawSpans/ && b==want { printf "%s%s", sep, $3; sep=" " }' "$T/sw.o"; }
_swr () { grep "^$1" "$T/sw.e" | sed 's/.*: //' | xargs; }
_ofeq "swapT exit / sentinel" "$_swx $(grep -c '^SWAPT SENTINEL' "$T/sw.e")" "0 1"
_ofeq "swapT SW-1 before: no listener run; heading's wall, the descriptions form's lightGreen (200,580), ok's green; its two text fields drawn" "$(_swr SW-1) / $(_swp before) / $(_swt before)" "runs 0 / r247 g232 b170 a255 / r175 g211 b120 a255 / r175 g211 b120 a255 / heading words ok describeHead describeHelp"
_ofeq "swapT SW-2 ONE WRITE SWAPS: one listener run; (200,580) is the other form's red and its text is drawn, descriptions' is not; heading and ok as before" "$(_swr SW-2) / $(_swp swapped) / $(_swt swapped)" "runs 1 / r247 g232 b170 a255 / r239 g43 b45 a255 / r175 g211 b120 a255 / heading words ok swOtherText"
_ofeq "swapT SW-3 written back: a second run, and the page and text calls are SW-1's by value" "$(_swr SW-3) / $(_swp back) / $(_swt back)" "runs 2 / $(_swp before) / $(_swt before)"
_ofeq "swapT SW-4 the definition is not written by a swap: firstLight's inside still names insideForm" "$(awk '/^SW PAGE/{b=$3} b=="definition" && /inside form=/ {print $2}' "$T/sw.o")" "form=insideForm"

echo "-- the mock click: G2 stroke 3, goal G1 (clickT)."
#  ⚑ clickT -- the mock click (Tony, 2026-11-13): click(request) names a form and a field, selects the field, fires its own action and then its
#  attribute actions left to right. firstLight's ok holds onClick:=okClick, which writes insideForm; insideForm's listener redraws.
#  Controls: CK-4 a field with no action (selected, nothing fired, no run); CK-6's plain attribute between two that hold actions.
_ckF=$(ip clickT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_ckF" > "$T/ck.o" 2> "$T/ck.e"; _ckx=$?
_ckp () { awk -v want="$1" '/^CK PAGE/{b=$3} /pixelAt pdfRead/ && b==want { s=$0; sub(/.*= /,"",s); sub(/ ===.*/,"",s); printf "%s%s", sep, s; sep=" / " }' "$T/ck.o"; }
_ckt () { awk -v want="$1" '/^CK PAGE/{b=$3} /^=== drawSpans/ && b==want { printf "%s%s", sep, $3; sep=" " }' "$T/ck.o"; }
_ckc () { awk -v want="$1" '/^CK PAGE/{b=$3} /^=== click/ && b==want { s=$0; sub(/^=== click /,"",s); sub(/ ===.*/,"",s); printf "%s%s", sep, s; sep=" / " }' "$T/ck.o"; }
_ckr () { grep "^$1 " "$T/ck.e" | sed "s/^$1 //" | xargs; }
_ofeq "clickT exit / sentinel" "$_ckx $(grep -c '^CLICKT SENTINEL' "$T/ck.e")" "0 1"
_ofeq "clickT CK-1 before: no listener run; (200,580) is the descriptions form's lightGreen" "$(_ckr CK-1 | cut -d' ' -f1-2) / $(_ckp before)" "runs 0 / r247 g232 b170 a255 / r175 g211 b120 a255 / r175 g211 b120 a255"
#  CK-2 / CK-3 RE-PINNED 2026-11-22 (SEQ 750; Tony: defaultLook gets selectFill:=lightBlue): the clicked field, ok, is the selection, so every layout after the
#  click fills it with the look's selectFill -- lightBlue (r206 g255 b255) where it read its own lightGreen. Nothing else on either page moved; CK-3 compared the
#  whole page with CK-1's by value and now names ok's point as the one that differs, because ok stays selected after the second click.
#  CK-2 / CK-3 RE-PINNED AGAIN 2026-11-23 (SEQ 757; Tony: selection is an OUTLINE, not a fill): ok, selected, keeps its own lightGreen in the middle, where these
#  rows read it -- the value they held before SEQ 750. The outline itself is pinned by windowClickT's WS rows and windowOutlineT. CK-3 is CK-1's page by value again.
_ofeq "clickT CK-2 THE CLICK: ok selected, its onClick fired okClick, one listener run; (200,580) is the note form's white and its text is drawn; heading unmoved; ok, selected, keeps its own lightGreen inside its outline" "$(_ckr CK-2 | cut -d' ' -f1-4) / $(_ckc clicked) / $(_ckp clicked) / $(_ckt clicked)" "runs 1 selected ok / firstLight ok selected / firstLight ok fired onClick okClick / r247 g232 b170 a255 / r255 g255 b255 a255 / r175 g211 b120 a255 / heading words ok okNoteText"
_ofeq "clickT CK-3 a second click brings descriptions back: two runs; the page and text calls are CK-1's by value (ok, still selected, reads its own fill at its middle)" "$(_ckr CK-3 | cut -d' ' -f1-2) / $(_ckp again) / $(_ckt again)" "runs 2 / $(_ckp before) / $(_ckt before)"
_ofeq "clickT CK-4 a field with no action: heading is selected, nothing fired, no listener run" "$(_ckr CK-4 | cut -d' ' -f1-4) / $(_ckc heading)" "runs 2 selected heading / firstLight heading selected"
_ofeq "clickT CK-5 a name the form lacks and a request with no field name: each refused by name; no click line, no run, the selection as it was" "$(grep -c '^click: REFUSING ckNoField -- the form firstLight has no field named nosuch' "$T/ck.e") $(grep -c '^click: REFUSING ckNoName -- its request needs form:=theForm and field=theName' "$T/ck.e") / [$(_ckc refused)] / $(_ckr CK-5 | cut -d' ' -f1-4)" "1 1 / [] / runs 2 selected heading"
_ofeq "clickT CK-6 ORDER: the field's own action, then its attribute actions left to right (a plain attribute between them fires nothing): 123" "$(_ckr CK-6 | sed 's/.*order //') / $(_ckc order)" "123 / ckBoth ckOwn selected / ckBoth ckOwn fired its own action / ckBoth ckOwn fired first ckFirst / ckBoth ckOwn fired second ckSecond"

echo "-- the viewer: show opens what it wrote (viewerT, SEQ 686)."
#  ⚑ viewerT -- the show dispatch, stroke 1 (Clay, 2026-11-17): show opens its output path's PDF in the system's default viewer
#  (open -g) when viewer (pROPERTIEs) is 1 and the shell's INCANT_NOVIEW is not set; never another path. This script exports
#  INCANT_NOVIEW=1 (1d). The fixture never writes output.pdf (it points showPath at test.pdf). viewer on is checked by Tony's eye.
#  H7 (SEQ 686, on the committed file, open -g respelled true so nothing pops up): without the INCANT_NOVIEW test VT-2 reads
#  "opened"; with open respelled false, VT-2 says "could not open ... the PDF is written" (the errant line, not a refusal).
_vtF=$(ip viewerT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_vtF" > "$T/vt.o" 2> "$T/vt.e"; _vtx=$?
_vtb () { awk -v want="$1" '/^VT-/{b=$1} /^VT END/{b=""} b==want && /=== show (viewer off|opened)/{ sub(/^=== show /,""); sub(/ ===.*/,""); printf "%s;", $0 }' "$T/vt.o"; printf '%s' "$(grep -c "could not open" "$T/vt.e")"; }
_ofeq "viewerT exit / sentinel" "$_vtx $(grep -c '^VIEWERT SENTINEL' "$T/vt.e")" "0 1"
_ofeq "viewerT VT-1 viewer = 0: viewer off, no open attempted (viewer lines / could-not-open lines)" "$(_vtb VT-1)" "viewer off;0"
_ofeq "viewerT VT-2 viewer = 1 but INCANT_NOVIEW set: viewer off, no open attempted" "$(_vtb VT-2)" "viewer off;0"
_ofeq "viewerT VT-3 a form with its own path, not the output path: no viewer line at all" "$(_vtb VT-3)" "0"
_ofeq "viewerT output.pdf untouched by the fleet: three shows, every one to test.pdf" "$(grep -c '^=== show .* to /tmp/incantTest.pdf ===' "$T/vt.o") $(grep -c 'output.pdf' "$T/vt.o")" "3 0"

echo "-- the stash: show finds a form by name (stashT, showBootT; SEQ 688)."
#  ⚑ stashT -- the stash dispatch (Tony, 2026-11-17): sTASh, a registry of its own loaded at Start() from incant/stash, which
#  genLadder/stash.sh generates from the hand-kept list incant/stashList. Reached only by qualified name. ST-1 is the 2b guard.
#  H7 (SEQ 688, committed file): incant/stash's entries written into fILEs instead -> ST-1 reads bare firstLight 1 (red).
_stF=$(ip stashT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_stF" > "$T/st.o" 2> "$T/st.e"; _stx=$?
_ofeq "stashT exit / sentinel" "$_stx $(grep -c '^STASHT SENTINEL' "$T/st.e")" "0 1"
_ofeq "stashT ST-1 THE 2b GUARD: after Start(), the bare names read nothing and the stash entries read their File" "$(grep '^ST-1 ' "$T/st.e" | sed 's/ *$//')" "ST-1 bare firstLight 0 bare descriptions 0 sTASh[firstLight] 1 sTASh[descriptions] 1"
_ofeq "stashT ST-2 a file on disk not on the list: refused not in the stash, nothing loaded (refusals / deferred lines before ST-4)" "$(grep -c '^REFUSED show simple -- not in the stash' "$T/st.e") $(awk '/^=== show .* deferred/{n++} END{print n+0}' "$T/st.o")" "1 1"
_ofeq "stashT ST-3 no file and no entry: refused the same way" "$(grep -c '^REFUSED show zzNoSuchForm -- not in the stash' "$T/st.e")" "1"
#  re-pinned SEQ 723 (looks by name): firstLight gained looks:=firstLightLooks, one attribute, so its list length is 13 where it was 12.
_ofeq "stashT ST-4 through the stash: drawn to test.pdf; the form in FORMs, the bare name the form, the entry File + text as fILEs' is" "$(grep -c '^=== show firstLight to /tmp/incantTest.pdf ===' "$T/st.o") / $(grep '^ST-4 FORMs' "$T/st.e" | sed 's/ *$//')" "1 / ST-4 FORMs[firstLight] 13 bare firstLight 13 sTASh[firstLight] 2 fILEs[utilities] 2 FORMs[simple] 0"
#  ⚑ showBootT -- show(firstLight) after Start(); alone writes output.pdf, which is Tony's: set aside here and put back.
#  H7 (SEQ 688, committed file): showFinish calling showForm by its bare name -> SB-1 has no draw line (the name binds when the
#  body is first built, with the search list of that moment, and Utilities is not on it).
_sbF=$(ip showBootT)
_sbOut=IncantForms/PDF/output.pdf
rm -f "$T/sb.keep"; [ -f "$_sbOut" ] && mv "$_sbOut" "$T/sb.keep"
perl -e 'alarm 60; exec @ARGV' "$B" "$_sbF" > "$T/sb.o" 2> "$T/sb.e"; _sbx=$?
_sbNew=0; [ -s "$_sbOut" ] && _sbNew=1
rm -f "$_sbOut"; [ -f "$T/sb.keep" ] && mv "$T/sb.keep" "$_sbOut"
_ofeq "showBootT exit / sentinel" "$_sbx $(grep -c '^SHOWBOOTT SENTINEL' "$T/sb.e")" "0 1"
_ofeq "showBootT SB-1 deferred, then drawn to output.pdf by the continuation" "$(grep '^=== show firstLight' "$T/sb.o" | sed 's/ *$//' | tr '\n' '|')" "=== show firstLight deferred: what it needs loads after this statement, then it draws ===|=== show firstLight to IncantForms/PDF/output.pdf ===|"
_ofeq "showBootT SB-2 a new output.pdf was written (Tony's put back)" "$_sbNew" "1"

echo "-- the tabs form, respelled as tabForm: definitions only, placeholders only (tabFormT; SEQ 700)."
#  ⚑ tabFormT -- tabs stroke 1 (Clay's dispatch, Tony's rulings of 2026-11-18): tabForm draws today's picture under defaultLook,
#  every colour and font a placeholder (tabFill tabFont cardOneFill cardTwoFill cardThreeFill, IncantForms/Controls/styles).
#  The tabs are labelled by their value; cards, tabs= and selectFill are not read yet (strokes 2-4, docs/tabsRecon.md).
#  H7 (SEQ 700, committed file, measured): tabFill out of defaultLook -> TF-3 reads the tab and the help white (r255 g255 b255).
_tfF=$(ip tabFormT)
rm -f /tmp/incantTest.pdf
perl -e 'alarm 60; exec @ARGV' "$B" "$_tfF" > "$T/tf.o" 2> "$T/tf.e"; _tfx=$?
_tfp () { awk '/^TF-4 /{exit} {print}' "$T/tf.o" | grep -A1 "^TF-AT $1 *$" | grep 'pixelAt' | sed 's/.*= //; s/ ===.*//'; }
_tf4 () { awk '/^TF-4 /{on=1} on' "$T/tf.o" | grep -A1 "^TF-AT $1 *$" | grep 'pixelAt' | sed 's/.*= //; s/ ===.*//'; }
_ofeq "tabFormT exit / sentinel / no refusal" "$_tfx $(grep -c '^TABFORMT SENTINEL' "$T/tf.e") $(grep -c '^REFUSED\|^REMOVED' "$T/tf.e")" "0 1 0"
_ofeq "tabFormT TF-1 drawn by show to test.pdf (twice, TF-4 the second); the tabs labelled by their value, in tabFont (headerFont)" "$(grep -c '^=== show tabForm to /tmp/incantTest.pdf ===' "$T/tf.o") / $(awk '/^TF-4 /{exit} $2=="drawSpans" && $3 ~ /^tab/ {printf "%s %s %s %s %s;", $3, $5, $6, $15, $17}' "$T/tf.o")" "2 / tabOne Palatino 14 3 3;tabTwo Palatino 14 3 3;tabThree Palatino 14 5 5;"
#  RE-PINNED SEQ 701 (tabs stroke 2): only the selected card is drawn, in the cards field's whole box; nothing selected is the
#  first tab, so TF-2 draws firstCard alone and TF-3's three card pixels all read cardOneFill.
_ofeq "tabFormT TF-2 the heading in headingFont (titleFont); nothing selected, so only the first card is drawn" "$(awk '/^TF-4 /{exit} $2=="drawSpans" && ($3=="heading" || $3 ~ /Card$/) {printf "%s %s %s;", $3, $5, $6}' "$T/tf.o")" "heading Palatino 24;firstCard Helvetica 12;"
#  RE-PINNED SEQ 703 (tabs stroke 3): the selected tab takes its selectFill, so TF-3's tab One reads cardOneFill; tab Three tabFill.
_ofeq "tabFormT TF-3 one pixel a region: intro pageFill, tab One (selected) cardOneFill, tab Three tabFill, the cards box all cardOneFill, help tabFill" "$(_tfp tfIntro) | $(_tfp tfTabOne) | $(_tfp tfTabThree) | $(_tfp tfCardOne) | $(_tfp tfCardTwo) | $(_tfp tfCardThree) | $(_tfp tfHelp)" "r255 g255 b255 a255 | r0 g158 b15 a255 | r175 g211 b120 a255 | r0 g158 b15 a255 | r0 g158 b15 a255 | r0 g158 b15 a255 | r175 g211 b120 a255"
_ofeq "tabFormT TF-4 tabSelected := tabThree by hand: only thirdCard drawn, and it fills the box (top and bottom pixels cardThreeFill)" "$(awk '/^TF-4 /{on=1} on && $2=="drawSpans" && $3 ~ /Card$/ {printf "%s;", $3}' "$T/tf.o") $(_tf4 tfCardOne) | $(_tf4 tfCardThree)" "thirdCard; r239 g43 b45 a255 | r239 g43 b45 a255"

#  ⚑ TF-5 -- tabs stroke 3 (Clay's dispatch, 2026-11-18): the selected tab is filled with what its selectFill holds, on the copy.
#  H7 (SEQ 703, committed file, cardsPick's rebind of the tab's fill taken out by hand): both tabs read tabFill on both pages.
_ofeq "tabFormT TF-5 the selected tab takes its card's colour, the others tabFill, and the first page's colour does not stay: page 1 One / Three, page 2 One / Three" "$(_tfp tfTabOne) $(_tfp tfTabThree) | $(_tf4 tfTabOne) $(_tf4 tfTabThree)" "r0 g158 b15 a255 r175 g211 b120 a255 | r175 g211 b120 a255 r239 g43 b45 a255"

echo "-- cards: one card shown, picked by the selected tab (cardsT; SEQ 701)."
#  ⚑ cardsT -- tabs stroke 2 (Tony's rulings, 2026-11-18): setFrame's cardsPick, on the laid-out copy. A cards field shows one member;
#  the bar's tabs:= holds a field outside the form that holds the selected tab (0: the first tab); the tab's card:= names the card.
#  H7 (SEQ 701, committed file, cardsPick's call taken out of setFrame by hand): every run draws both cards of each cards field.
_ctF=$(ip cardsT)
rm -f /tmp/incantTest.pdf
perl -e 'alarm 60; exec @ARGV' "$B" "$_ctF" > "$T/ct.o" 2> "$T/ct.e"; _ctx=$?
_ctr () { awk -v r="$1" '/^CT RUN/{n=$3} n==r && $2=="drawSpans" && $3 ~ /^ct(One|Two|X|Y)$/ {printf "%s ", $3}' "$T/ct.o"; }
_ofeq "cardsT exit / sentinel / no list errors" "$_ctx $(grep -c '^CARDST SENTINEL' "$T/ct.e") $(grep -c 'nextGroup: ERROR' "$T/ct.e")" "0 1 0"
_ofeq "cardsT CT-1 nothing selected (ctSel 0): the bar's first tab's card, and a cards field no tab points into shows its first" "$(_ctr 1)" "ctOne ctX "
_ofeq "cardsT CT-2 ctSel := ctB: ctB's card" "$(_ctr 2)" "ctTwo ctX "
_ofeq "cardsT CT-3 a tab with no card: refused naming it, the first shown" "$(grep -c '^setFrame: REFUSING the tab ctC -- it names no card' "$T/ct.e") $(_ctr 3)" "1 ctOne ctX "
_ofeq "cardsT CT-4 a card in no cards field: refused naming the tab and the card, the first shown" "$(grep -c '^setFrame: REFUSING the tab ctD -- its card ctStray is in no cards field' "$T/ct.e") $(_ctr 4)" "1 ctOne ctX "
_ofeq "cardsT CT-5 a selection that is no tab of the bar: refused naming it, the first shown" "$(grep -c '^setFrame: REFUSING the tab ctLone -- the tab bar ctBar has no tab by that name' "$T/ct.e") $(_ctr 5)" "1 ctOne ctX "
_ofeq "cardsT CT-6 the definition is never written: its ctTwo is not hidden after five layouts" "$(grep '^CT-6 ' "$T/ct.e" | sed 's/ *$//')" "CT-6 the definition's ctTwo isHidden 0"

echo "-- the tab click: selectTab and clickShow (tabClickT; SEQ 737)."
#  ⚑ tabClickT -- tabs stroke 4 (docs/tabsRecon.md): each tab's onClick:=tabClick (the form's own action) calls utilities' selectTab, which writes
#  the field the bar's tabs:= names (tabSelected, outside the form) to hold the clicked tab; clickShow(request) is click, then showForm.
#  H7 (SEQ 737, committed file, fixture alone): selectTab's write taken out -> tabSelected none after every click, every page TK-0's (TK-1..3 red);
#  clickShow's showForm taken out -> tabSelected moves, one draw in all, every page TK-0's (TK-1, TK-2, TK-4 red).
#  Pixels: tab One, Two, Three at y=62, the cards box top and low. green r0 g158 b15, blue r0 g81 b186, red r239 g43 b45, tabFill r175 g211 b120.
_tkF=$(ip tabClickT)
rm -f /tmp/incantTest.pdf
perl -e 'alarm 60; exec @ARGV' "$B" "$_tkF" > "$T/tk.o" 2> "$T/tk.e"; _tkx=$?
_tkp () { awk -v p="$1" '/^TK-PAGE/{on=($2==p)} on && /pixelAt/ {s=$0; sub(/.* = /,"",s); sub(/ a255 ===.*/,"",s); printf "%s%s", sep, s; sep=" | "}' "$T/tk.o"; }
_tks () { grep "^$1 tabSelected" "$T/tk.e" | sed 's/ *$//; s/.*tabSelected //'; }
_tkG="r0 g158 b15"; _tkB="r0 g81 b186"; _tkR="r239 g43 b45"; _tkF0="r175 g211 b120"
_ofeq "tabClickT exit / sentinel / no refusal at define" "$_tkx $(grep -c '^TABCLICKT SENTINEL' "$T/tk.e") $(grep -c '^REFUSED\|^REMOVED' "$T/tk.e")" "0 1 0"
_ofeq "tabClickT TK-0 show alone: nothing selected, tab One and the box green" "$(_tks TK-0) / $(_tkp TK-0)" "none / $_tkG | $_tkF0 | $_tkF0 | $_tkG | $_tkG"
_ofeq "tabClickT TK-1 clickShow tabThree: one call fires tabClick, selectTab, and draws; tab Three and the whole box red, tab One tabFill" "$(grep -c '^=== click tabForm tabThree fired onClick tabClick' "$T/tk.o") $(grep -c '^=== selectTab tabThree ===' "$T/tk.o") $(_tks TK-1) / $(_tkp TK-1)" "1 1 tabThree / $_tkF0 | $_tkF0 | $_tkR | $_tkR | $_tkR"
_ofeq "tabClickT TK-2 tabTwo: blue" "$(_tks TK-2) / $(_tkp TK-2)" "tabTwo / $_tkF0 | $_tkB | $_tkF0 | $_tkB | $_tkB"
_ofeq "tabClickT TK-3 tabOne: green again" "$(_tks TK-3) / $(_tkp TK-3)" "tabOne / $_tkG | $_tkF0 | $_tkF0 | $_tkG | $_tkG"
_ofeq "tabClickT TK-4 a name the form lacks: click refuses by name, clickShow draws nothing; four draws of tabForm in all; selection kept" "$(grep -c '^click: REFUSING tkNoSuch -- the form tabForm has no field named nosuch' "$T/tk.e") $(grep -c '^clickShow: nothing drawn for tkNoSuch -- the click refused' "$T/tk.e") $(grep -c '^=== show tabForm to /tmp/incantTest.pdf ===' "$T/tk.o") $(_tks TK-4)" "1 1 4 tabOne"
_ofeq "tabClickT TK-5 selectTab under a parent with no tabs:= refuses naming the field and the parent; tabSelected unchanged" "$(grep -c '^selectTab: REFUSING tkOrphan -- its parent tkNotBar is no tab bar (tabs:=)' "$T/tk.e") $(_tks TK-5)" "1 tabOne"
_ofeq "tabClickT TK-6 the definition is never written: its thirdCard is not hidden after the clicks" "$(grep '^TK-6 ' "$T/tk.e" | sed 's/ *$//')" "TK-6 the definition's thirdCard isHidden 0"

echo "-- pour: data poured into a form (pourT; SEQ 741)."
#  ⚑ pourT -- pour:=, each, color:=contrast (Tony's first draft, 2026-11-22; Clay's dispatch). A down="*" pour:=aRegistry field's one template row
#  is copied once a member on the laid-out copy and each copy is marked with its member (fillDownAcross, pourStamp); under a copy each stands for
#  the member ({each}, {each.taG}, fill:=each, {aRegistry.each}); color:=contrast is black or white from the field's own fill, black at 17.9% or more.
#  H7 (SEQ 741, committed file, fixture alone, each undone from git with an md5 check): pour's count out -> 31 rows, what fits; the mark out ->
#  14 rows with no member (no white swatch, 14 third cells, 68 refusals); the threshold out -> every swatch white and ptLight white.
_ptF=$(ip pourT)
rm -f /tmp/incantTest.pdf
perl -e 'alarm 60; exec @ARGV' "$B" "$_ptF" > "$T/pt.o" 2> "$T/pt.e"; _ptx=$?
_ptr () { awk -v r="$1" '/^PT RUN/{on=($3==r)} on' "$T/pt.o"; }
_ptc () { _ptr "$1" | awk -v f="$2" '$2=="drawSpans" && $3==f {c=$9" "$10" "$11; n[c]++} END{for (k in n) printf "%s x%d;", k, n[k]}' | tr ';' '\n' | sort | tr '\n' ';'; }
_ptp () { _ptr ptColors | grep -A1 "^PT-AT $1 *$" | grep pixelAt | sed 's/.*= //; s/ a255 ===.*//'; }
_ofeq "pourT exit / sentinel" "$_ptx $(grep -c '^POURT SENTINEL' "$T/pt.e")" "0 1"
#  RE-PINNED 2026-11-23 (SEQ 758): cOLOr gained one entry, midBlue (IncantForms/Controls/styles; Tony: the default selection colour, r0 g120 b215), so every row
#  that pours cOLOr reads 15 where it read 14: pourT PT-1..3 (PT-3's last three points moved down one row, 24 points, in the fixture), colorListT CL-2, CL-3, CL-5
#  (the page 28 taller: one row and one gap), pourDeriveT PD-1, PD-2. midBlue's swatch text is black by the contrast rule. Nothing else in these rows moved.
_ofeq "pourT PT-1 cOLOr poured: 15 rows whatever fits, names in cOLOr's order by their length (black blue darkBrown ... wall white)" "$(_ptr ptColors | awk '$2=="drawSpans" && $3=="ptName" {printf "%s ", $15}')" "5 4 9 10 4 5 9 10 7 8 11 3 10 4 5 "
_ofeq "pourT PT-2 the swatch text is the value (7 characters, 15 times) and its colour is contrast's: white on 3 (black, blue, darkBrown), black on 12" "$(_ptr ptColors | awk '$2=="drawSpans" && $3=="ptSwatch" && $15==7' | wc -l | tr -d ' ') / $(_ptc ptColors ptSwatch)" "15 / r0 g0 b0 x12;r255 g255 b255 x3;"
_ofeq "pourT PT-3 the swatch pixels are the members' colours: rows 1, 2, 14, 15; below row 15 is the page" "$(_ptp ptBlack) | $(_ptp ptBlue) | $(_ptp ptWall) | $(_ptp ptWhite) | $(_ptp ptPastEnd)" "r0 g0 b0 | r0 g81 b186 | r247 g232 b170 | r255 g255 b255 | r255 g255 b255"
_ofeq "pourT PT-4 a member with no entry in the qualified registry shows NOTHING: two third cells drawn (black 11, wall 13 characters), no warning, no tag" "$(_ptr ptColors | awk '$2=="drawSpans" && $3=="ptWhat" {printf "%s ", $15}')/ $(grep -c 'ptWhat.*no such entry\|ptWhat.*left as written' "$T/pt.e")" "11 13 / 0"
_ofeq "pourT PT-5 a registry of three in room for two: three rows; black fill white text, wall and red (#ef2b2d, 20.9%) black text" "$(_ptr ptThree | awk '$2=="drawSpans" && $3=="ptCell3" {printf "%s %s;", $15, $9}')" "5 r255;4 r0;5 r0;"
_ofeq "pourT PT-6 contrast with no pour: a blue fill white, a literal #ffffff black, no fill the text colour in effect (red)" "$(_ptr ptPlain | awk '$2=="drawSpans" {printf "%s %s %s %s;", $3, $9, $10, $11}')" "ptDark r255 g255 b255;ptLight r0 g0 b0;ptBare r239 g43 b45;"
_ofeq "pourT PT-7 refused by name: pour on a plain down; an empty registry (one row, not repeated to fit); each outside a poured field, a fill and two inserts" "$(grep -c '^setFrame: REFUSING ptBadRows -- it names pour and is not down=' "$T/pt.e") $(grep -c '^setFrame: REFUSING ptEmptyRows -- its pour registry PourEmpty has no members' "$T/pt.e") $(_ptr ptBadEmpty | grep -c drawSpans) $(grep -c '^setFrame: REFUSING ptLoose -- its fill names each outside a poured field' "$T/pt.e") $(grep -c '^drawSpans: REFUSING ptLoose.* -- its text names each outside a poured field' "$T/pt.e")" "1 1 1 1 2"
_ofeq "pourT PT-8 a registry not on the search list is refused at define, as any := is" "$(grep -c '^REFUSED NoSuchRegistry -- a := in a define names a field' "$T/pt.e")" "1"
_ofeq "pourT PT-9 the definition is never written: one row, no each" "$(grep '^PT-9 ' "$T/pt.e" | sed 's/ *$//')" "PT-9 the definition's ptRows holds 1 row; its each attribute: 0"

#  ⚑ colorListT -- IncantForms/Windows/colorList (Tony's and Clay's form; SEQ 741), shown through the stash: tester's final shape,
#  Start(); show(colorList); with showPath pointed at test.pdf. These pin the form and that loading it leaves cOLOr alone.
#  H7 (SEQ 741, on a copy of the form with its two search lines out, the fixture pointed at it): CL-4 reads black [the darkest; ...] and
#  CL-3's swatches lose their fills (14 displayFill refusals).
#  SEQ 744: the form's two search lines are OUT (a definition found in another registry gets its own entry now), and CL-4 holds without
#  them; its H7 moves to the engine (pop.sh, registryHomeT).
#  RE-PINNED SEQ 742 (pour stage 2): colorList is the derived form now -- no template row, so the cells are pour's own (pourName, pourShow,
#  pourWhat), its descriptions are in dESCRIPTIONs, and CL-5 is new: height=fit, the page 452 high.
_clF=${CL_FILE:-$(ip colorListT)}
rm -f /tmp/incantTest.pdf
perl -e 'alarm 60; exec @ARGV' "$B" "$_clF" > "$T/cl.o" 2> "$T/cl.e"; _clx=$?
_ofeq "colorListT exit / sentinel / no refusal" "$_clx $(grep -c '^COLORLISTT SENTINEL' "$T/cl.e") $(grep -c 'REFUS\|^REMOVED' "$T/cl.e")" "0 1 0"
#  SEQ 745: tester's shape prints nothing on stderr but this fixture's own two lines (the 16 compare warnings a run are cured at their source).
_ofeq "colorListT CL-0 stderr holds this fixture's CL-4 line and its sentinel and nothing else" "$(grep -c . "$T/cl.e") $(grep -c '^CL-4 \|^COLORLISTT SENTINEL' "$T/cl.e")" "2 2"
_ofeq "colorListT CL-1 found in the stash (deferred), drawn to test.pdf" "$(grep -c '^=== show colorList deferred' "$T/cl.o") $(grep -c '^=== show colorList to /tmp/incantTest.pdf ===' "$T/cl.o")" "1 1"
_ofeq "colorListT CL-2 15 rows, the names in cOLOr's order (by length: black blue darkBrown ... wall white)" "$(awk '$2=="drawSpans" && $3=="pourName"{printf "%s ", $15}' "$T/cl.o")" "5 4 9 10 4 5 9 10 7 8 11 3 10 4 5 "
_ofeq "colorListT CL-3 15 swatches printing their value, white text on 3 and black on 12; 14 descriptions (midBlue has none)" "$(awk '$2=="drawSpans"{n[$3]++; if($3=="pourShow"){c[$9]++; if($15==7)v++}} END{print n["pourShow"], v, c["r255"], c["r0"], n["pourWhat"]}' "$T/cl.o")" "15 15 3 12 14"
_ofeq "colorListT CL-4 loading the form leaves cOLOr as it was; black's description is words, not a colour (its wording is the form's to change)" "$(grep '^CL-4 ' "$T/cl.e" | sed 's/ its description.*//') / $(grep '^CL-4 ' "$T/cl.e" | grep -c 'its description \[ [a-zA-Z]')" "CL-4 cOLOr black [ #000000 ] white [ #ffffff ] / 1"
_ofeq "colorListT CL-5 height=fit: the page is as tall as its rows need, 40 + 15 x 24 + 14 x 4 + 2 x 12" "$(grep '^=== readPDF' "$T/cl.o" | sed 's/.*size //; s/ ===.*//')" "490x480"

echo "-- pour stage 2: rows derived from what is poured; margin, gap, height=fit (pourDeriveT; SEQ 742)."
#  ⚑ pourDeriveT -- Tony ruled D1-D6, 2026-11-22 (Clay's dispatch), and with the build: kind by value; descriptions from dESCRIPTIONs by the
#  entry's name, no attribute. A down="*" pour:= field with no row has one built a member (pourPlan, before the styles are merged).
#  H7 (SEQ 742, committed file, fixture alone, each undone from git with an md5 check): the derive out -> no rows, the top 116 high; kind by
#  value out -> every show is plain text (no white, one font sample); margin out -> the title at x=- 490 wide; gap out -> rows 24 apart;
#  the fit sum out -> the top 792.
_pdF=$(ip pourDeriveT)
rm -f /tmp/incantTest.pdf
perl -e 'alarm 90; exec @ARGV' "$B" "$_pdF" > "$T/pd.o" 2> "$T/pd.e"; _pdx=$?
_pdr () { awk -v r="$1" '/^PD RUN/{on=($3==r)} on' "$T/pd.o"; }
_pdn () { _pdr "$1" | awk -v f="$2" '$2=="drawSpans" && $3==f{n++} END{print n+0}'; }
_ofeq "pourDeriveT exit / sentinel / no refusal" "$_pdx $(grep -c '^POURDERIVET SENTINEL' "$T/pd.e") $(grep -c 'REFUS\|^REMOVED' "$T/pd.e")" "0 1 0"
_ofeq "pourDeriveT PD-1 cOLOr derived: 15 names, 15 swatches printing their value (white text 3, black 12), 2 descriptions (black, wall)" "$(_pdn pdColors pourName) $(_pdr pdColors | awk '$2=="drawSpans" && $3=="pourShow"{c[$9]++; if($15==7)v++} END{print v, c["r255"], c["r0"]}') $(_pdr pdColors | awk '$2=="drawSpans" && $3=="pourWhat"{printf "%s ", $15}')" "15 15 3 12 11 13 "
_ofeq "pourDeriveT PD-2 margin, gap, fit by frame: title 12 in and 466 wide; rows 1 and 2 at y 52 and 80 (24 + 4); the top 480 high" "$(_pdr pdColors | grep 'pdTitle x=' | xargs) / $(_pdr pdColors | grep 'pourRow x=' | head -2 | awk '{printf "%s ", $3}')/ $(_pdr pdColors | grep '^pdColors x=' | awk '{print $5}')" "pdTitle x=12 y=12 w=466 h=40 / y=52 y=80 / h=480"
_ofeq "pourDeriveT PD-3 fONTs: seven samples, each in its own font; a row as tall as its sample needs" "$(_pdr pdFonts | awk '$2=="drawSpans" && $3=="pourShow"{printf "%s %s %s|", $5,$6,$7}') / $(_pdr pdFonts | grep 'pourRow x=' | awk '{printf "%s ", $5}')" ".AppleSystemUIFont 18 0|Copperplate 12 0|Courier New 24|Helvetica 10 0|Palatino 14 1|Palatino 14 0|Palatino 24 1| / h=30 h=24 h=36 h=24 h=26 h=26 h=36 "
#  PD-4 RE-PINNED 2026-11-22 (SEQ 750): 16 rows -> 17. sTYLEs gained one entry, the placeholder selectFill (IncantForms/Controls/styles), and the form pours one row per entry.
_ofeq "pourDeriveT PD-4 sTYLEs: 17 rows; emphasis's sample is red (the style applied, one r239); accent, a placeholder, is defaultLook's red swatch (black text)" "$(_pdn pdStyles pourName) $(_pdr pdStyles | awk '$2=="drawSpans" && $3=="pourShow" && $9=="r239"{n++} END{print n+0}') $(_pdr pdStyles | awk '$2=="drawSpans" && $3=="pourShow"{print $9; exit}')" "17 1 r0"
_ofeq "pourDeriveT PD-5 the same pour under a look of its own (accent blue, pageFill black): accent's swatch reads white text; one more white than by day" "$(_pdr pdStylesNight | awk '$2=="drawSpans" && $3=="pourShow"{print $9; exit}') $(_pdr pdStyles | awk '$2=="drawSpans" && $3=="pourShow" && $9=="r255"{n++} END{print n+0}') $(_pdr pdStylesNight | awk '$2=="drawSpans" && $3=="pourShow" && $9=="r255"{n++} END{print n+0}')" "r255 2 4"
_ofeq "pourDeriveT PD-6 mixed things: a # value a swatch (white on blue), plain words their own text (10 characters), no value nothing" "$(_pdr pdMixed | awk '$2=="drawSpans"{printf "%s:%s:%s ", $3,$9,$15}')" "pourName:r0:5 pourName:r0:7 pourShow:r255:7 pourName:r0:5 pourShow:r0:10 "
_ofeq "pourDeriveT PD-7 cOMMANDs: no command fired or read (no show text); capped at 792, the names of the 33 rows that fit are drawn and no row is left unframed" "$(_pdn pdCmds pourShow) $(_pdr pdCmds | grep '^pdCmds x=' | awk '{print $5}') $(_pdn pdCmds pourName) $(_pdr pdCmds | grep -c 'pourRow x=- y=- w=- h=24')" "0 h=792 33 0"
_ofeq "pourDeriveT PD-8 height=fit with a member of no height: the cap, said by name" "$(grep -c '^setFrame: pdOpen names height=fit and 1 of its members name no height of their own; it takes the cap, 792' "$T/pd.e") $(_pdr pdOpen | grep '^pdOpen x=' | awk '{print $5}')" "1 h=792"
_ofeq "pourDeriveT PD-9 the definition is never written: no rows on it, pour still there" "$(grep '^PD-9 ' "$T/pd.e" | sed 's/ *$//')" "PD-9 the definition's pdRows holds 0 rows; pour still on it: 1"
#  ⚑ describedTwice -- a name described in two places is named, never silently overwritten (Tony, 2026-11-22): genLadder/describedTwice.sh.
mkdir -p "$T/dt"; printf 'register(dESCRIPTIONs);\ndefine\n    black="one";\n    ;\nbail();\n' > "$T/dt/a"; printf 'register(dESCRIPTIONs);\ndefine\n    black="two";\n    white="w";\n    ;\nregister(FORMs);\ndefine\n    black="not a description";\n    ;\n' > "$T/dt/b"
_dtOut=$(bash genLadder/describedTwice.sh 2>&1); _dtx=$?
_dtBad=$(bash genLadder/describedTwice.sh "$T/dt" 2>&1); _dtbx=$?
_ofeq "describedTwice the form files: none described twice (exit / line)" "$_dtx $(echo "$_dtOut" | sed 's/^ *//; s/: [0-9]* descriptions/: N descriptions/')" "0 ok    describedTwice: N descriptions, none described twice"
_ofeq "describedTwice control, two files describing black (a third black under FORMs is not a description): named once, white not named (exit / named / lines)" "$_dtbx $(echo "$_dtBad" | grep -c 'DESCRIBED TWICE black -- .*dt/a:3 .*dt/b:3') $(echo "$_dtBad" | wc -l | tr -d ' ')" "1 1 1"

echo "-- the IBkant skeleton: the kant wiki as a kant form (ibkantT)."
#  ⚑ ibkantT -- IBkant's skeleton (Tony, 2026-11-13): one window, three page forms held in one field, a contents column whose clicks write the
#  holding field, and page bodies poured by name from IncantForms/IBkant/text. IB-5's expected counts are computed here from the text file.
_ibF=$(ip ibkantT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_ibF" > "$T/ib.o" 2> "$T/ib.e"; _ibx=$?
_ibt () { awk -v want="$1" '/^IB PAGE/{b=$3} /^=== drawSpans/ && b==want { printf "%s%s", sep, $3; sep=" " }' "$T/ib.o"; }
_ibc () { awk -v want="$1" '/^IB PAGE/{b=$3} /^=== click/ && b==want { s=$0; sub(/^=== click /,"",s); sub(/ ===.*/,"",s); printf "%s%s", sep, s; sep=" / " }' "$T/ib.o"; }
_ibb () { awk -v want="$1" -v f="$2" '/^IB PAGE/{b=$3} /^=== drawSpans/ && b==want && $3==f { s=$0; sub(/.* drawn /,"drawn ",s); sub(/ next .* paragraphs/," paragraphs",s); sub(/ runs.*/,"",s); print s }' "$T/ib.o"; }
#  _ibn <page>: the characters that page's passage should draw, counted from the text file itself: marks taken out, each paragraph's white space
#  runs made one space, the paragraphs' lengths added. RE-PINNED 2026-11-13 (gap 1): a page is ONE passage holding its own paragraphs and runs.
_ibn () { perl -0777 -e '$n=shift; $_=<>; /^    \Q$n\E=\((.*?)#\);/ms or do { print "nopassage"; exit }; $t=$1; $t=~s/\{[A-Za-z0-9]+:\s*//g; $t=~s/\}//g; $c=0; for (split /\n\s*\n/, $t){ s/\s+/ /g; s/^ | $//g; $c+=length } print $c' "$1" IncantForms/IBkant/text; }
_ibu () { awk -v want="$1" -v f="$2" '/^IB PAGE/{b=$3} /^=== drawSpans/ && b==want && $3==f { s=$0; sub(/.* runs /,"runs ",s); sub(/ ===.*/,"",s); print s }' "$T/ib.o"; }
_ibr () { grep "^$1 " "$T/ib.e" | sed "s/^$1 //" | xargs; }
_ofeq "ibkantT exit / sentinel" "$_ibx $(grep -c '^IBKANTT SENTINEL' "$T/ib.e")" "0 1"
_ofeq "ibkantT IB-1 the first page is Welcome: title, the three contents entries, then the page's head and body; no listener run" "$(_ibr IB-1) / $(_ibt first)" "runs 0 / ibTitle toWelcome toFields toForms ibWelcomeHead ibWelcomeBody"
_ofeq "ibkantT IB-2 a click on toFields: selected, onClick fired showFields, one run, and the page is Fields" "$(_ibr IB-2) / $(_ibc fields) / $(_ibt fields)" "runs 1 selected toFields / IBkant toFields selected / IBkant toFields fired onClick showFields / ibTitle toWelcome toFields toForms ibFieldsHead ibFieldsBody"
_ofeq "ibkantT IB-3 a click on toForms: two runs, the page is Forms" "$(_ibr IB-3) / $(_ibt forms)" "runs 2 selected toForms / ibTitle toWelcome toFields toForms ibFormsHead ibFormsBody"
_ofeq "ibkantT IB-4 a click on toWelcome: three runs, and the body reads as on the first page" "$(_ibr IB-4) / $(_ibb welcome ibWelcomeBody)" "runs 3 selected toWelcome / $(_ibb first ibWelcomeBody)"
_ofeq "ibkantT IB-5 THE WORDS COME FROM THE TEXT FILE: each body draws all of its ONE passage (length counted from the file, marks out), in the passage's own two paragraphs; nothing left as written" "$(_ibb first ibWelcomeBody) / $(_ibb fields ibFieldsBody) / $(_ibb forms ibFormsBody) / $(grep -c 'left as written' "$T/ib.e")" "drawn $(_ibn welcome) of $(_ibn welcome) paragraphs 2 of 2 / drawn $(_ibn fields) of $(_ibn fields) paragraphs 2 of 2 / drawn $(_ibn forms) of $(_ibn forms) paragraphs 2 of 2 / 0"
_ofeq "ibkantT IB-6 (gap 1) THE PASSAGE'S OWN RUNS: welcome 1, fields 2, forms 1; and the counts above are numbers, not a missing passage" "$(_ibu first ibWelcomeBody) / $(_ibu fields ibFieldsBody) / $(_ibu forms ibFormsBody) / $(_ibn welcome) $(_ibn fields) $(_ibn forms)" "runs 1 / runs 2 / runs 1 / 438 460 416"

echo ""
echo "-- a passage carries its own paragraphs and runs: IBkant gap 1 (passageT)."
#  ⚑ passageT -- IBkant gap 1 (Tony, 2026-11-13): an insert's text is read as text, by typeset's own grammar. Its blank lines split paragraphs and its
#  marks open and close runs. BORN RED, read on the tree before the build: PG-1 "drawn 27 of 27" (one paragraph), PG-2 "drawn 33 of 33" (the marks
#  printed), PG-4 18, PG-7 17, PG-8 31 / 23, PG-9 32 in 2 paragraphs, PG-6's warning 0. PG-3's and PG-5's counts read the same before and after; PG-5 is
#  the guard on a wrong build (a passage's brace closing the holder's run reads 10). H7 is in the seal.
_pgF=$(ip passageT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_pgF" > "$T/pg.o" 2> "$T/pg.e"; _pgx=$?
_pgl () { grep -h "^=== drawSpans $1 " "$T/pg.o" | sed 's/.* drawn /drawn /; s/ next end//; s/ valign.*align [a-z]*//; s/ ===//' | xargs; }
_ofeq "passageT exit / sentinel / nothing clipped" "$_pgx $(grep -c '^PASSAGE SENTINEL' "$T/pg.e") $(grep -c 'does not fit' "$T/pg.e")" "0 1 0"
_ofeq "passageT PG-1 a passage's blank line splits paragraphs: 15 and 11 characters, two paragraphs" "$(_pgl pgTwo)" "drawn 26 of 26 paragraphs 2 of 2 runs 0"
_ofeq "passageT PG-2 a passage's run is a run: 21 characters (the marks take no room), one run" "$(_pgl pgRun)" "drawn 21 of 21 paragraphs 1 of 1 runs 1"
_ofeq "passageT PG-3 a run open at the insert ends at the passage's paragraph break; its closing brace is then text: 17 and 14" "$(_pgl pgHost)" "drawn 31 of 31 paragraphs 2 of 2 runs 1"
_ofeq "passageT PG-4 a run the passage leaves open ends with the passage: a b c d, one run; and a closing brace after it is text, 10 characters (9 if the run were still open; H7 2026-11-13)" "$(_pgl pgOpen) / $(_pgl pgEnded)" "drawn 7 of 7 paragraphs 1 of 1 runs 1 / drawn 10 of 10 paragraphs 1 of 1 runs 1"
_ofeq "passageT PG-5 a passage's closing brace never closes the holder's run: it is text, 11 characters" "$(_pgl pgBrace)" "drawn 11 of 11 paragraphs 1 of 1 runs 1"
_ofeq "passageT PG-6 an insert inside a passage is left as written (17, not the 16 of alpha beta) and warned by name, once" "$(_pgl pgNest) / $(grep -c '^drawSpans: WARNING pgNest -- inserted text holds an insert of its own; left as written' "$T/pg.e") $(grep -c 'holds an insert of its own' "$T/pg.e")" "drawn 17 of 17 / 1 1"
_ofeq "passageT PG-7 a form field's text is read the same way ({name}): m n o with one run; the control, a plain passage, is unchanged at 14" "$(_pgl pgField) / $(_pgl pgPlain)" "drawn 5 of 5 paragraphs 1 of 1 runs 1 / drawn 14 of 14"
_ofeq "passageT PG-8 text around a passage joins its first and last paragraphs (17 and 13); a (...#) literal's real blank line splits (13 and 9)" "$(_pgl pgGap) / $(_pgl pgLit)" "drawn 30 of 30 paragraphs 2 of 2 runs 0 / drawn 22 of 22 paragraphs 2 of 2 runs 0"
_ofeq "passageT PG-9 the insert's own blank line still ends the paragraph after it: three paragraphs" "$(_pgl pgAfter)" "drawn 31 of 31 paragraphs 3 of 3 runs 0"

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
#  RE-AIMED 2026-11-21 (G3 item 2, stroke 3b, SEQ 729; the include dropped at the buy, SEQ 730): resizeT included the cheat (IncantForms/WorkingOn/cheat) and resizes through formFrames
#  (redrawWindow) instead of a request's frame:=. Every value below is unchanged; RZ-2 and RZ-3 are re-worded for what they now claim.
#  The cheat row is a guard: a run where no cheat copy fired measured utilities, not the cheat. It retires at the buy (3c), with the include.
#  RETIRED AT THE BUY (3c, SEQ 730): "resizeT the cheat was reached" -- a guard for the cheat include, which is gone; nothing to map.
_ofeq "resizeT RZ-1 as declared, 400x200: wrap (98,70), two (150,70), three's leftBorder at 50% (200,70), three (300,70), fourth (200,170)" "$(grep -h '^=== readPDF pdfRead' "$T/rz.o" | sed -n 1p | sed 's/.*size //; s/ ===//') $(_rzp 1 5)" "400x200 white red black white green"
_ofeq "resizeT RZ-2 resized to 600x300 through the store (redrawWindow): the page follows, and the percent: wrap (148,100), two (225,100), three's leftBorder (300,100), three (450,100), fourth (300,270); (200,100), the old border, is two's red" "$(grep -h '^=== readPDF pdfRead' "$T/rz.o" | sed -n 2p | sed 's/.*size //; s/ ===//') $(_rzp 6 11)" "600x300 white red black white green red"
_ofeq "resizeT RZ-3 a plain redraw after the resize: the resize read and cleared its entry, so the run reads exactly as the first" "$(grep -h '^=== readPDF pdfRead' "$T/rz.o" | sed -n 3p | sed 's/.*size //; s/ ===//') $(_rzp 12 16)" "400x200 white red black white green"
_ofeq "resizeT RZ-4 the text re-flows in the wider frame: characters of one drawn at 400, at 600, at 400 again, at 600" "$(grep -h '^=== drawSpans one ' "$T/rz.o" | sed 's/.*drawn \([0-9]*\) of.*/\1/' | tr '\n' ' ' | sed 's/ $//')" "181 266 181 266"
_ofeq "resizeT RZ-5 the definition after two resizes: simple still declares 400x200, and its deepest field (stuff, three levels down) holds no frame" "$(sed -n '/^simple x=300/,/fourth/p' "$T/rz.o" | head -1 | xargs) / $(sed -n '/^simple x=300/,/fourth/p' "$T/rz.o" | grep 'stuff' | xargs)" "simple x=300 y=450 width=400 height=200 down rounded / stuff text=one;"

#  ⚑ resizeListenT -- RETIRED BY MAPPING at the G3 buy (3c, SEQ 730; Tony ruled 2026-11-21, 12:20, R4): layoutFrame and its listener are gone,
#  replaced by redrawWindow and keepFrame (formFrames). The fixture is in incant/attic. Its assertions and their homes:
#    exit / sentinel                                   -> each successor's own exit / sentinel row
#    RL-1 writing parts of a field notifies nobody     -> pop.sh notifyT NT-2 (an attach fires nothing)
#    RL-2 a resize to 600x300, the page and five points -> resizeT RZ-2 (the same points, through the store)
#    RL-3 back to 400x200, reading as the first run    -> resizeT RZ-3
#    RL-4 the text re-flows; simple still declares 400  -> resizeT RZ-4 and RZ-5
#    (the whole-write listener fact)                   -> pop.sh listenT LN-6

#  ⚑ resizeLightT -- forms step 6, stroke 4's last piece (Tony, 2026-11-12; since G3 3b-3c the resize is redrawWindow, not layoutFrame): Layout wrote layoutFrame as ONE WHOLE WRITE (layoutFrame = a field holding
#  x y width height), on firstLight: PDF before, resize, PDF after. A resize must read like a fresh run, so RG-3 lays the same frame out by a plain call
#  and is compared with RG-2 by value. Control (measured 2026-11-12, before GroupItem.setContent kept and told the listeners on a whole-list write):
#  the one write fired nothing (runs 0) and removed layoutFrame's listener list.
echo ""
echo "-- firstLight resized through formFrames (resizeLightT)."
_rgF=$(ip resizeLightT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_rgF" > "$T/rg.o" 2> "$T/rg.e"; _rgx=$?
_rgc () { sed -e 's/r255 g255 b255 a255/white/g' -e 's/r247 g232 b170 a255/wall/g' -e 's/r175 g211 b120 a255/green/g'; }
#  one block per PDF read: the page size, its points, and the words field's line count drawn just before it
_rgb () { awk -v n="$1" '/drawSpans words /{w=$0} /readPDF pdfRead/{k++; if(k==n){sub(/.*size /,""); sub(/ ===.*/,""); printf "%s ", $0; sub(/.*lines /,"",w); sub(/ drawn.*/,"",w); printf "lines %s ", w}} /pixelAt pdfRead/ && k==n {sub(/.*= /,""); sub(/ ===.*/,""); printf "%s ", $0}' "$T/rg.o" | _rgc | xargs; }
_ofeq "resizeLightT exit / sentinel" "$_rgx $(grep -c '^RESIZELIGHT SENTINEL' "$T/rg.e")" "0 1"
#  RE-AIMED 2026-11-21 (G3 item 2, stroke 3b, SEQ 729; the include dropped at the buy, SEQ 730): the resize no longer arrives by listening to layoutFrame. resizeLightT included the cheat and
#  resizes through formFrames (redrawWindow); RG-2 and RG-4 read the window's width and height where they read a listener's run count. Pages,
#  points and line counts are unchanged. The cheat row is a guard and retires at the buy (3c), with the include.
#  RETIRED AT THE BUY (3c, SEQ 730): "resizeLightT the cheat was reached" -- a guard for the cheat include, which is gone; nothing to map.
#  RG-1 / RG-2 RE-PINNED 2026-11-12 (the typesetting slice): words holds a second paragraph of one line, so it draws 4 lines at 400 wide and 3 at 600, where it drew 3 and 2
#  RG-2 RE-PINNED SEQ 685 (stroke 0): the big frame is 1200x600, so words re-flows again, 3 lines at 500 to 2 at 1200; the big points
#  are heading (900,15) and ok (1190,230). Its comment below, "the re-flow RG-2 showed is gone", held only from 684 to 685.
#  RG-1 / RG-2 / RG-4 / RG-5 RE-PINNED SEQ 684 (Tony's settled edit: firstLight declared 500x600, inside 60%): the small frame is the
#  declared 500x600. Both sizes are 600 high, so only x moves: words draws 3 lines at 500 and at 600 (the re-flow RG-2 showed is gone
#  with the narrower step), and where ok was at 500, (490,230), reads space's wall at 600. The resize still shows in the page size
#  and in ok: green at (590,230) on the big page, wall at (490,230).
_ofeq "resizeLightT RG-1 before, as declared: 500x600, words in 3 lines; heading wall, words white, space wall, ok green" "$(_rgb 1)" "500x600 lines 3 wall white wall green"
_ofeq "resizeLightT RG-2 the resize through the store: the window at 1200x600; the page 1200x600, words re-flows to 2 lines; the four fields at their new places; where ok was is space's wall" "$(grep '^RG-2' "$T/rg.e" | sed 's/.*: //' | xargs) / $(_rgb 2)" "width 1200 height 600 / 1200x600 lines 2 wall white wall green wall"
_ofeq "resizeLightT RG-3 the store's page = the same frame named in a request (frame:=), by value" "$(_rgb 3)" "$(_rgb 2)"
_ofeq "resizeLightT RG-4 resized back through the store: the window at 500x600; the page = RG-1's, by value" "$(grep '^RG-4' "$T/rg.e" | sed 's/.*: //' | xargs) / $(_rgb 4)" "width 500 height 600 / $(_rgb 1)"
_ofeq "resizeLightT RG-5 four pages were read, and firstLight still declares 500x600" "$(grep -c 'readPDF pdfRead' "$T/rg.o") / $(grep '^firstLight x=300' "$T/rg.o" | head -1 | cut -d' ' -f1-5)" "4 / firstLight x=300 y=450 width=500 height=600"

#  ⚑ windowGcT -- windows stroke 0 (SEQ 747, 2026-11-22), F-153: an open window does not hide our globals from the collector. resizeLightT's two
#  resizes run under an open OFFSCREEN window (windowOffscreen: never shown, no run loop) at GCSTRESS=1000, with one compiled action alive across
#  them. windowRootProbe is the witness: a block held only by a global of ours, beside a known-bad end (hidden pointer: COLLECTED) and a known-good
#  end (uncollectable cell: kept). CONTROL, run here on every pass: WINDOW_CLEAR_ROOTS=1 drops every static root at the open (the state F-153
#  described) and the probe reads COLLECTED. Measured 2026-11-22: under that control the relayout rows below still read right, so they say a window
#  run survives and only the probe rows say the globals are scanned. No window appears and no focus is taken.
echo ""
echo "-- a relayout under an open offscreen window, collections forced (windowGcT)."
_wgF=$(ip windowGcT)
GCSTRESS=1000 perl -e 'alarm 120; exec @ARGV' "$B" "$_wgF" > "$T/wg.o" 2> "$T/wg.e"; _wgx=$?
#  one probe line as four words: the two global sets and the good end exactly; the bad end as "some" (fewer than 8 kept) or "all". The collector is
#  conservative: a stray stack word can keep a block nothing holds, so an unheld set reads "fewer than 8", never a pinned count; a held set reads 8, always.
_wgp () { grep '^=== rootProbe' "$1" | sed -n "$2p" | awk '{gsub(/;/,""); bad=($21 < 8) ? "collected" : "ALL-KEPT"; print "no_dls " $4 " bss " $13 " data " $17 " bad-end " bad " good-end " $(NF-1)}'; }
_wgc () { grep '^=== rootProbe' "$1" | sed -n "$2p" | awk '{gsub(/;/,""); print "no_dls " $4 " globals " (($13 < 8 && $17 < 8) ? "COLLECTED" : "kept")}'; }
_ofeq "windowGcT exit / sentinel / window opened, not shown" "$_wgx $(grep -c '^WINDOWGC SENTINEL' "$T/wg.e") $(grep -c '^=== windowOffscreen: a window 500 x 600, not shown' "$T/wg.e")" "0 1 1"
_ofeq "windowGcT WG-1 before any window: of 8 blocks each, globals of ours keep all 8; the hidden end is collected, the uncollectable end keeps 8" "$(_wgp "$T/wg.e" 1)" "no_dls 0 bss 8 data 8 bad-end collected good-end 8"
_ofeq "windowGcT WG-2 UNDER THE OPEN WINDOW (no_dls 1) blocks held only by globals of ours are still kept, 8 of 8" "$(_wgp "$T/wg.e" 2)" "no_dls 1 bss 8 data 8 bad-end collected good-end 8"
_ofeq "windowGcT WG-3 / WG-4 compiled code fired under the window, and again after two relayouts: 3 then 6" "$(sed -n 's/^WG-[34] .*wgN \[ \([0-9]*\) \].*/\1/p' "$T/wg.e" | xargs)" "3 6"
grep 'readPDF pdfRead\|pixelAt pdfRead' "$T/rg.o" > "$T/wg.want"; grep 'readPDF pdfRead\|pixelAt pdfRead' "$T/wg.o" > "$T/wg.got"
_ofeq "windowGcT the four pages and their points under the window = resizeLightT's own, by value (22 lines, no refusal)" "$(cmp -s "$T/wg.want" "$T/wg.got" && echo same || echo differ) $(wc -l < "$T/wg.got" | xargs) $(grep -c 'REFUS' "$T/wg.e")" "same 22 0"
_ofeq "windowGcT WG-5 after the relayouts and one more collection: still 8 of 8" "$(_wgp "$T/wg.e" 3)" "no_dls 1 bss 8 data 8 bad-end collected good-end 8"
WINDOW_CLEAR_ROOTS=1 GCSTRESS=1000 perl -e 'alarm 120; exec @ARGV' "$B" "$_wgF" > "$T/wgc.o" 2> "$T/wgc.e"
_ofeq "windowGcT CONTROL, every static root dropped at the open: the probe reads the globals' blocks COLLECTED (before the window, kept)" "$(_wgc "$T/wgc.e" 1) / $(_wgc "$T/wgc.e" 2)" "no_dls 0 globals kept / no_dls 1 globals COLLECTED"

#  ⚑ windowDrawT -- windows stroke 1 (SEQ 748, 2026-11-22): the window draws the form. Layout.drawRect is the third opener beside makeDisplay and openPDF
#  (windowDrawForm, guiHost.mm): AppKit's context in the top's pointer slot, the floor's three transforms, kant's drawWalk. readWindow has AppKit draw the
#  view into a bitmap with nothing shown. THE CLAIM IS EQUALITY WITH THE PLAIN BITMAP, pixel for pixel; the PDF differs from both alike (its own rasterising).
#  Control (H7, 2026-11-22, one build): windowDrawForm's origin translate removed -> WD-3 reads differing > 0 and WD-4's red point moves. Run at GCSTRESS=1000.
echo ""
echo "-- the window draws the form, read offscreen (windowDrawT)."
_wdF=$(ip windowDrawT)
GCSTRESS=1000 perl -e 'alarm 120; exec @ARGV' "$B" "$_wdF" > "$T/wd.o" 2> "$T/wd.e"; _wdx=$?
_wdpts () { grep "^=== pixelAt $1 " "$T/wd.o" | sed -n "$2" | sed 's/.*= //; s/ ===//' | _rgc | xargs; }
_wddiff () { grep "^=== displayDiff $1 " "$T/wd.o" | sed 's/^=== displayDiff [A-Za-z]* //; s/ ===$//'; }
_ofeq "windowDrawT exit / sentinel" "$_wdx $(grep -c '^WINDOWDRAW SENTINEL' "$T/wd.e")" "0 1"
_ofeq "windowDrawT WD-1 the PDF's four points: heading wall, words white, space wall, ok green" "$(_wdpts pdfRead 1,4p)" "wall white wall green"
_ofeq "windowDrawT WD-2 THE WINDOW'S four points = the PDF's, by value; the view is the form's size" "$(_wdpts wdRead 1,4p) / $(grep -c '^=== readWindow wdRead title \[incant\] size 500x600' "$T/wd.o")" "$(_wdpts pdfRead 1,4p) / 2"
_ofeq "windowDrawT WD-3 THE WINDOW'S BITMAP = THE PLAIN BITMAP'S, every pixel: 0 of 300000 differ, and the page is not blank" "$(_wddiff wdSame | sed 's/unlike the first.s corner \([0-9]*\)/inked \1/' | awk '{print $2, $4, ($6 > 1000 ? "inked" : "BLANK"), "differing", $8}' | tr -d ';,')" "500x600 300000 inked differing 0"
_ofeq "windowDrawT WD-3 the PDF differs from the window exactly as it differs from the plain bitmap (the PDF's own rasterising)" "$(_wddiff wdDiff)" "$(_wddiff wdPdfBit)"
_ofeq "windowDrawT WD-4 TITLE: a form naming title= titles its window; the second window is its form's size" "$(grep '^=== readWindow wdTitledRead' "$T/wd.o" | sed 's/^=== readWindow wdTitledRead //; s/ ===$//')" "title [A titled form] size 120x80"
_ofeq "windowDrawT WD-4 two windows, each draws its own form: red at (60,40) in the titled one, firstLight's wall at (450,15)" "$(grep '^=== pixelAt wdTitledRead (60,40)' "$T/wd.o" | sed 's/.*= //; s/ ===//') / $(_wdpts wdRead 5p)" "r239 g43 b45 a255 / wall"
_ofeq "windowDrawT WD-5 / WD-6 refused by name, once each: a form no window holds; a field with no frame" "$(grep -c '^readWindow: REFUSING wdTitledRead -- needs form:= a top field that a window holds' "$T/wd.e") $(grep -c '^windowOffscreen: REFUSING wdBare -- frame is 0x0' "$T/wd.e")" "1 1"

#  ⚑ windowClickT -- windows stroke 2 (SEQ 749, 2026-11-22): a click from a point (W2) and selection shown with selectFill (W3). The window turns a
#  point into the field under it on the laid-out copy (guiHost.mm windowClickAt: blockContaining) and hands kant the field: utilities' clickField selects
#  it and fires, climbing the copy's parents until a level fires. setFrame's selectionPick fills the selected field, matched by name, with its own
#  selectFill, else the look's; none anywhere, drawn as it was. windowClick sends a real mouse-up event to the view's mouseUp. Run at GCSTRESS=1000.
#  Controls (H7, 2026-11-22): selectionPick's call removed from setFrame -> WS-1, WS-2, WS-3 and WS-5 red; the form's origin not added in
#  windowClickAt -> the WS hits name other fields; clickField's climb cut to one level -> WS-1 fires nothing.
echo ""
echo "-- a click from a point, bubbling, and selectFill (windowClickT)."
_wcF=$(ip windowClickT)
GCSTRESS=1000 perl -e 'alarm 120; exec @ARGV' "$B" "$_wcF" > "$T/wc.o" 2> "$T/wc.e"; _wcx=$?
_wccol () { sed -e 's/r255 g255 b255 a255/white/g' -e 's/r239 g43 b45 a255/red/g' -e 's/r0 g158 b15 a255/green/g' -e 's/r0 g81 b186 a255/blue/g' -e 's/r247 g232 b170 a255/wall/g' -e 's/r175 g211 b120 a255/tabFill/g'; }
_wcp () { awk -v t="$1 $2" '$0 ~ "^"t"$" || $0 ~ "^"t" *$" {on=1; next} /^W[CS]-PAGE/ {on=0} on && /^=== pixelAt/ {sub(/.*= /,""); sub(/ ===.*/,""); printf "%s | ", $0}' "$T/wc.o" | _wccol | sed 's/ | $//'; }
_wcb () { awk -v t="$1" '/^W[CS]-PAGE/ {on = ($2 == t)} on && /^=== (windowClick|click|selectTab) |^WC-SAY/' "$T/wc.o" | sed 's/^=== //; s/ *=== *$//; s/ *$//' | tr '\n' ';' | sed 's/;$//'; }
_ofeq "windowClickT exit / sentinel / no refusal" "$_wcx $(grep -c '^WINDOWCLICK SENTINEL' "$T/wc.e") $(grep -c 'REFUS\|REMOVED' "$T/wc.e")" "0 1 0"
_ofeq "windowClickT WC-0 tabForm in a window, nothing selected: tab One and the card green" "$(_wcp WC-PAGE WC-0)" "green | tabFill | tabFill | green | green"
_ofeq "windowClickT WC-1 A POINT INSIDE TAB THREE: the hit is tabThree, selected, its onClick fired, selectTab ran" "$(_wcb WC-0)" "windowClick tabForm at (300,62): tabThree;click tabForm tabThree selected;click tabForm tabThree fired onClick tabClick;selectTab tabThree"
_ofeq "windowClickT WC-1 redrawn in the window: tab Three and the whole card red, tab One tabFill (tabClickT's TK-1, from a point)" "$(_wcp WC-PAGE WC-1)" "tabFill | tabFill | red | red | red"
_ofeq "windowClickT WC-2 a point in the card: the shown card is hit, not a hidden one; nothing fires on the way up, said with the count of fields tried" "$(_wcb WC-1)" "windowClick tabForm at (300,260): thirdCard;click tabForm thirdCard selected;click tabForm thirdCard fired nothing, on the way up through 4 fields"
_ofeq "windowClickT WC-3 a point outside the form: no field, nothing fired, said so; no click line follows" "$(_wcb WC-2)" "windowClick tabForm at (500,500): no field, nothing fired"
#  WS-0 .. WS-5 RE-AIMED 2026-11-23 (SEQ 757; Tony: selection is an OUTLINE, not a fill). Each page now reads six points: the three fields' middles, then a
#  point on each one's left edge (x 1). A selected field's middle keeps its own fill and its edge reads the selection colour. Before, the middle read the colour.
_ofeq "windowClickT WS-0 the second form as declared: inner red, plain the page's white, lower green; the edges the same" "$(_wcp WS-PAGE WS-0)" "red | white | green | red | white | green"
#  WS-1 RE-PINNED 2026-11-23 (SEQ 764; Tony: an only-room field is not selectable): wcInner has a fill and nothing else, so it is only room; the selection
#  climbs to wcOuter, its parent, selectable by its onClick. The click line names wcOuter and the outline is wcOuter's, round both its members: wcInner's red
#  fill is drawn over it, so wcInner's edge reads red again; wcPlain names no fill, so the outline shows at its edge, blue. Until SEQ 764 wcInner itself was
#  selected and its own edge was blue. WS-2 and WS-4 click wcPlain, also only room: they read as before, but because wcOuter is outlined, not wcPlain.
_ofeq "windowClickT WS-1 BUBBLING: a point in wcInner (only room, no action) selects and fires its parent wcOuter, handed wcOuter" "$(_wcb WS-0)" "windowClick wcForm at (100,25): wcInner;click wcForm wcOuter selected;click wcForm wcOuter fired onClick wcSay;WC-SAY handed wcOuter"
_ofeq "windowClickT WS-1 SELECTION: wcOuter, the selected field, is outlined in the look's selectFill, blue; wcInner keeps its red; lower as it was" "$(_wcp WS-PAGE WS-1)" "red | white | green | red | blue | green"
_ofeq "windowClickT WS-2 a point in wcPlain, only room: wcOuter is selected again; plain's middle still the page's white, the outline showing at its edge, blue; inner's edge red" "$(_wcp WS-PAGE WS-2)" "red | white | green | red | blue | green"
_ofeq "windowClickT WS-3 a field naming ITS OWN selectFill wins over the look's: lower's edge wall, not blue, its middle still green; nothing fires on the way up" "$(_wcp WS-PAGE WS-3) / $(_wcb WS-2 | sed 's/.*;//')" "red | white | green | red | white | wall / click wcForm wcLower fired nothing, on the way up through 3 fields"
#  WS-4 RE-AIMED 2026-11-22 (SEQ 750): it asked "a look with no selectFill: drawn as it was". defaultLook holds one now (lightBlue), and defaultLook is the second
#  place every layout looks, so with styles loaded no layout is without one. The row now pins the fallback: a request naming no look shows defaultLook's lightBlue.
#  The none-anywhere arm of selectionPick is still there (a run without styles' defaultLook) and has no row; said in the seal.
_ofeq "windowClickT WS-4 a request naming NO look: the selected field is outlined in defaultLook's selectFill, midBlue since 2026-11-23 (the request's look's was blue)" "$(_wcp WS-PAGE WS-4 | sed 's/r0 g120 b215 a255/midBlue/')" "red | white | green | red | midBlue | green"
_ofeq "windowClickT WS-5 the mock click by name still selects, does not climb, and shows the same way: inner's edge blue" "$(_wcb WS-4 | sed 's/^[^;]*;[^;]*;[^;]*;[^;]*;//') / $(_wcp WS-PAGE WS-5)" "click wcForm wcInner selected / red | white | green | blue | white | green"

#  ⚑ windowResizeT -- windows stroke 3 (SEQ 750, 2026-11-22): resize and close. A window opened with a request keeps it; a resize, a click and a close each go
#  back through kant with the window's frame now (guiHost.mm windowRelay / windowClosed -> utilities windowLay / keepFrame): the frame into formFrames, the layout
#  from there, as redrawWindow does, with no PDF. windowResize resizes the window and calls the view's own viewDidEndLiveResize; windowClose closes it as its
#  button does. Compared BY VALUE with resizeLightT's own pages from this run. Run at GCSTRESS=1000.
#  Controls (H7, 2026-11-22, one build each): windowRelay made to do nothing -> big, click and small red; windowClosed's keepFrame removed -> close and reopen red.
echo ""
echo "-- a window resized, clicked, closed and reopened (windowResizeT)."
_wrF=$(ip windowResizeT)
GCSTRESS=1000 perl -e 'alarm 120; exec @ARGV' "$B" "$_wrF" > "$T/wr.o" 2> "$T/wr.e"; _wrx=$?
_wrp () { awk -v t="$1" '/^WR-PAGE/ {on = ($2 == t)} on && /^=== readWindow/ {sub(/.*size /,""); sub(/ ===.*/,""); printf "%s ", $0} on && /^=== pixelAt/ {sub(/.*= /,""); sub(/ ===.*/,""); printf "%s ", $0}' "$T/wr.o" | sed 's/r206 g255 b255 a255/lightBlue/g' | _rgc | xargs; }
_wrl () { awk -v t="$1" '/^WR-PAGE/ {on = ($2 == t)} on && /^=== (window |windowClick|click )|^WR-STORE/' "$T/wr.o" | sed 's/^=== //; s/ *=== *$//; s/ *$//' | tr '\n' ';' | sed 's/;$//'; }
_rgpts () { _rgb "$1" | awk '{printf "%s", $1; for (i = 4; i <= NF; i++) printf " %s", $i; print ""}'; }
_ofeq "windowResizeT exit / sentinel" "$_wrx $(grep -c '^WINDOWRESIZE SENTINEL' "$T/wr.e")" "0 1"
_ofeq "windowResizeT open: a window opened with a REQUEST lays the form out itself; the page = resizeLightT's RG-1 by value" "$(_wrp open)" "$(_rgpts 1)"
_ofeq "windowResizeT big: A RESIZE to 1200x600 -- the frame it reports, and the page = resizeLightT's RG-2 by value (the mock resize, same size)" "$(_wrl big | sed 's/;.*//') / $(_wrp big)" "window resized: firstLight now 1200x600 at (300,450) / $(_rgpts 2)"
_ofeq "windowResizeT big: the store's entry was read and cleared by the layout, as redrawWindow leaves it" "$(_wrl big | sed 's/.*;//')" "WR-STORE after-resize entry 0"
#  click / small RE-PINNED 2026-11-23 (SEQ 757; selection is an OUTLINE): ok's middle reads its own green, selected or not. The click row still shows the window laid
#  out again by itself: its last point is the lower panel, wall once okClick has swapped the held form (it is not wall before the click).
_ofeq "windowResizeT click: at the big size the window LAYS OUT AGAIN BY ITSELF after a click -- still 1200x600, the held form swapped; ok, selected, keeps its green inside" "$(_wrl click) / $(_wrp click)" "windowClick firstLight at (1190,230): ok;click firstLight ok selected;click firstLight ok fired onClick okClick / 1200x600 wall white wall green wall"
_ofeq "windowResizeT small: resized back, the page is 500x600 with resizeLightT's small points, ok still selected (its middle its own green)" "$(_wrp small)" "500x600 wall white wall green"
_ofeq "windowResizeT close: A CLOSE keeps the window's frame for its form (keepFrame alone), and the window is forgotten: reading it refuses by name" "$(_wrl close | sed 's/^[^;]*;//') / $(grep -c '^readWindow: REFUSING wrRead -- needs form:= a top field that a window holds' "$T/wr.e")" "window closed: firstLight kept 1200x600 at (300,450);WR-STORE after-close entry 1 / 1"
_ofeq "windowResizeT reopen: THE REOPENED WINDOW READS THE KEPT FRAME -- 1200x600, where the form declares 500x600 -- and the entry is cleared" "$(_wrp reopen) / $(_wrl reopen)" "1200x600 / WR-STORE after-reopen entry 0"
_ofeq "windowResizeT errant: a resize and a close for a form no window shows are refused by name; firstLight still declares 500x600" "$(grep -c '^windowResize: REFUSING wrNoWindow -- needs form:= a form a window shows' "$T/wr.e") $(grep -c '^windowClose: REFUSING wrNoWindow -- needs form:= a form a window shows' "$T/wr.e") / $(grep '^firstLight x=300' "$T/wr.o" | head -1 | cut -d' ' -f1-5)" "1 1 / firstLight x=300 y=450 width=500 height=600"

#  ⚑ windowLoopT -- windows stroke 4 (SEQ 751, 2026-11-22): the loop (W1), the display's size, show deciding. openWindow returns at once; where a script ends
#  (stop's exit, main's foot) windowsRun runs the event loop while a window is shown. For the fleet, a windowClick / windowResize / windowClose whose request
#  carries `later` is kept and done INSIDE the loop, and kept requests start it: the real loop runs with nothing on the screen. show opens a window for a form
#  written window when windows is switched on (incant/setup; 2 = made, not shown), else its PDF. displaySize is the display less menu bar and dock; its
#  values are the machine's, so the rows compare and never pin them. Run at GCSTRESS=1000.
#  Controls (H7, 2026-11-22): windowsRun made to return at once (one build) -> the loop rows red, the kept click and closes never done; windowLay's
#  cap line removed -> WL-TALL reads 792. The show rows carry their own: the same show at windows 0 goes to the PDF.
echo ""
echo "-- two windows, the loop, the display's size, show deciding (windowLoopT)."
_wlF=$(ip windowLoopT)
INCANT_NOVIEW=1 GCSTRESS=1000 perl -e 'alarm 120; exec @ARGV' "$B" "$_wlF" > "$T/wl.o" 2> "$T/wl.e"; _wlx=$?
_wls () { grep "^WL-SIZE $1 " "$T/wl.o" | awk '{print (($4 > 0 && $6 > 0) ? "sized" : "0x0"), "fitCap", $8}'; }
_wlblock () { awk -v a="$1" -v b="$2" '$0 ~ a {on=1; next} b != "" && $0 ~ b {on=0} on && /^===/ && !/drawSpans|show viewer off/' "$T/wl.o" | sed 's/^=== //; s/ *=== *$//; s/ *$//' | tr '\n' ';' | sed 's/;$//'; }
_ofeq "windowLoopT exit / sentinel / nothing refused" "$_wlx $(grep -c '^WINDOWLOOP SENTINEL' "$T/wl.e") $(grep -c 'REFUS' "$T/wl.e")" "0 1 0"
_ofeq "windowLoopT WL-SIZE before any window: the display's size is not yet published; fitCap is a page" "$(_wls before)" "0x0 fitCap 792"
_ofeq "windowLoopT WL-TWO two windows open at once, each drawn: tabForm's card green under its title, wlSmall red under its own" "$(_wlblock '^WL-TWO' '^WL-SIZE')" "readWindow wlReadTab title [Using Tabs] size 360x400;pixelAt wlReadTab (300,260) = r0 g158 b15 a255;readWindow wlReadSmall title [Second] size 120x80;pixelAt wlReadSmall (60,40) = r239 g43 b45 a255"
_ofeq "windowLoopT WL-SIZE after: displaySize is published (both parts more than 0) and fitCap is put back" "$(_wls after)" "sized fitCap 792"
_wlTall=$(grep '^=== readWindow wlReadTall' "$T/wl.o" | sed 's/.*size 200x//; s/ ===.*//'); _wlHigh=$(grep '^WL-SIZE tall ' "$T/wl.o" | awk '{print $6}')
_ofeq "windowLoopT WL-TALL a height=fit form needing 6000: IN A WINDOW it is capped at the display's usable height, not at a page's 792; fitCap put back" "$([ -n "$_wlTall" ] && [ "$_wlTall" = "$_wlHigh" ] && echo same || echo "differ $_wlTall $_wlHigh") $([ "${_wlTall:-792}" != 792 ] && echo not-792 || echo IS-792) $(_wls tall)" "same not-792 sized fitCap 792"
_ofeq "windowLoopT WL-SHOW SHOW DECIDES: windows 0, a form written window goes to its PDF; windows 2, the same show makes a window and no PDF; a form not written window still goes to its PDF" "$(_wlblock '^WL-SHOW' '^WL-LAST')" "show tkLoose to /tmp/incantTest.pdf;show tkLoose in a window, not shown;readWindow wlReadLoose title [incant] size 100x100;show wlSmall to /tmp/incantTest.pdf"
_ofeq "windowLoopT WL-LAST the script's last line printed, and before the loop started: every opening returned at once" "$(grep -n '^WL-LAST\|^=== window loop: started' "$T/wl.o" | sed 's/^[0-9]*://; s/ the script.*//; s/,.*//' | tr '\n' ' ' | xargs)" "WL-LAST === window loop: started"
_ofeq "windowLoopT THE LOOP: started after stop with 3 open and 4 kept; the kept click runs kant inside it; three closes keep their frames; it ends with none open" "$(_wlblock '^WL-LAST' '')" "window loop: started, 3 open, 0 shown, 4 kept for later;windowClick tabForm at (300,62): tabThree;click tabForm tabThree selected;click tabForm tabThree fired onClick tabClick;selectTab tabThree;window closed: tabForm kept 360x400 at (400,400);window closed: wlSmall kept 120x80 at (40,60);window closed: tkLoose kept 100x100 at (0,0);window loop: ended, 0 open"

#  ⚑ windowSearchT -- fix stroke W5-1 (SEQ 754, 2026-11-23): the first shown window was blank, REFUSED drawFill. show puts the search list back, so a
#  window's later calls into kant ran with no Utilities on the list and drawWalk bound drawFill to a fresh local. The fixture is tester's shape (the
#  bootstrap show, no include of utilities), which no other window fixture is. H7: runUnder made to ignore the kept list, WS-1 and WS-2 both red.
echo ""
echo "-- a window's calls into kant run under the search list it was opened with (windowSearchT)."
_wsF=$(ip windowSearchT)
INCANT_NOVIEW=1 GCSTRESS=1000 perl -e 'alarm 120; exec @ARGV' "$B" "$_wsF" > "$T/ws.o" 2> "$T/ws.e"; _wsx=$?
_wsblock () { awk -v a="$1" -v b="$2" '$0 ~ a {on=1; next} b != "" && $0 ~ b {on=0} on && /^===/ && !/drawSpans|show viewer off/' "$T/ws.o" | sed 's/^=== //; s/ *=== *$//; s/ *$//' | tr '\n' ';' | sed 's/;$//'; }
_ofeq "windowSearchT exit / sentinel / nothing refused on either stream" "$_wsx $(grep -c '^WS END' "$T/ws.o") $(cat "$T/ws.o" "$T/ws.e" | grep -c 'REFUS')" "0 1 0"
_ofeq "windowSearchT WS-1 the window show made, drawn with Utilities off the search list, paints: the first card's green and tab One's selected green" "$(_wsblock '^WS-1' '^WS END')" "readWindow wsRead title [Using Tabs] size 360x400;pixelAt wsRead (180,200) = r0 g158 b15 a255;pixelAt wsRead (20,62) = r0 g128 b12 a255"
_ofeq "windowSearchT WS-2 inside the loop, the script ended: the click fires tabClick, the resize lays out, the close keeps the frame, the loop ends" "$(_wsblock '^WS END' '')" "window loop: started, 1 open, 0 shown, 3 kept for later;windowClick tabForm at (180,62): tabTwo;click tabForm tabTwo selected;click tabForm tabTwo fired onClick tabClick;selectTab tabTwo;window resized: tabForm now 500x500 at (400,400);window closed: tabForm kept 500x500 at (400,400);window loop: ended, 0 open"

#  ⚑ windowOutlineT -- windows stroke A (SEQ 757, 2026-11-23; Tony's rulings after the watched runs). SELECTION IS AN OUTLINE: a scan across firstLight's held
#  heading (white text on green), before and after it is selected, reads the same green and the same white, and only the line's two ends turn the selection
#  colour (defaultLook's midBlue since SEQ 758; lightBlue was too faint on white). When selection was a fill the scan read no green (the H7: spPaint's old body, WO-1 red). A SECOND SHOW of an open form makes no second window; a form
#  closed and shown again opens at the kept frame. THE DEFAULT: windows is 1 as incant/setup leaves it (WO-D, printed before the fixture sets 2); INCANT_NOVIEW still winning is every show row here that draws a window form to its PDF.
echo ""
echo "-- selection as an outline, the second show, the windows default (windowOutlineT)."
_woF=$(ip windowOutlineT)
INCANT_NOVIEW=1 GCSTRESS=1000 perl -e 'alarm 120; exec @ARGV' "$B" "$_woF" > "$T/wo.o" 2> "$T/wo.e"; _wox=$?
_wosc () { awk -v a="^$1" '$0 ~ a {on=1; next} /^WO-/ {on=0} on && /pixelAt/' "$T/wo.o" | sed 's/.*= //; s/ ===.*//' | awk '{k = ($0 == "r175 g211 b120 a255") ? "green" : ($0 == "r255 g255 b255 a255") ? "white" : ($0 == "r0 g120 b215 a255") ? "midBlue" : "edge"; n[k]++} END {printf "green %d white %d midBlue %d", n["green"], n["white"], n["midBlue"]}'; }
_woends () { awk -v a="^$1" '$0 ~ a {on=1; next} /^WO-/ {on=0} on && /pixelAt .*\((1|498),265\)/' "$T/wo.o" | sed 's/.*= //; s/ ===.*//; s/r175 g211 b120 a255/green/; s/r0 g120 b215 a255/midBlue/' | tr '\n' ' ' | xargs; }
_wol () { awk -v a="^$1" -v b="$2" '$0 ~ a {on=1; next} b != "" && $0 ~ b {on=0} on && /^=== (show|window|openWindow|windowOffscreen)/' "$T/wo.o" | sed 's/^=== //; s/ *=== *$//; s/ *$//' | tr '\n' ';' | sed 's/;$//'; }
_ofeq "windowOutlineT exit / sentinel / nothing refused" "$_wox $(grep -c '^WO END' "$T/wo.o") $(cat "$T/wo.o" "$T/wo.e" | grep -c 'REFUS')" "0 1 0"
_ofeq "windowOutlineT WO-D THE DEFAULT: windows reads 1 before the fixture sets it" "$(grep '^WO-D' "$T/wo.o" | xargs)" "WO-D windows as setup leaves it 1"
_ofeq "windowOutlineT WO-0 nothing selected: the scan across the heading reads its green and its white text; both ends green" "$(_wosc WO-0) / $(_woends WO-0)" "green 86 white 18 midBlue 0 / green green"
_ofeq "windowOutlineT WO-1 THE HEADING SELECTED: the white text is still on green (the same 18 white; green less only the two ends), and the two ends are the selection colour" "$(_wosc WO-1) / $(_woends WO-1)" "green 84 white 18 midBlue 2 / midBlue midBlue"
_ofeq "windowOutlineT WO-2 A SECOND SHOW of the open form: said by name, no second window made (one windowOffscreen line so far); the one window resizes" "$(_wol WO-2 '^WO-3') / made $(grep -c '^=== windowOffscreen: a window' "$T/wo.e")" "show firstLight in a window, not shown;windowOffscreen: firstLight is already open in a window; no second window;window resized: firstLight now 640x700 at (300,450) / made 2"
_ofeq "windowOutlineT WO-3 closed, then shown again: a window is made anew at the frame the close kept" "$(_wol WO-3 '') / $(grep '^=== windowOffscreen: a window' "$T/wo.e" | tail -1 | sed 's/=== //; s/ ===//')" "window closed: firstLight kept 640x700 at (300,450);show firstLight in a window, not shown / windowOffscreen: a window 640 x 700, not shown"

#  ⚑ windowDescribeT -- windows stroke B (SEQ 758, 2026-11-23; Tony's ruling 4): DESCRIBE ON SELECT. Selecting a field puts dESCRIPTIONs' entry of its name in the
#  form's help box (the first field carrying describe), on the laid-out copy. Read from the floor's trace: characters the help box drew, of how many it held.
#  H7: describePick's call removed from setFrame -> WD-1..WD-5 red (every box reads its own text).
echo ""
echo "-- describe on select (windowDescribeT)."
_wdF=$(ip windowDescribeT)
INCANT_NOVIEW=1 GCSTRESS=1000 perl -e 'alarm 120; exec @ARGV' "$B" "$_wdF" > "$T/wd.o" 2> "$T/wd.e"; _wdx=$?
_wdr () { awk -v t="$1" '/^WD-/ {on = ($1 == t)} on && /^=== describe / {sub(/^=== describe /,""); sub(/ *===.*/,""); d=$0} on && $0 ~ "drawSpans ('"$2"') " {sub(/.*drawn /,""); sub(/ next.*/,""); n=$0} END {print (d == "" ? "no describe line" : d) " / " (n == "" ? "not drawn" : n)}' "$T/wd.o"; }
_ofeq "windowDescribeT exit / sentinel / nothing refused" "$_wdx $(grep -c '^WD END' "$T/wd.o") $(cat "$T/wd.o" "$T/wd.e" | grep -c 'REFUS')" "0 1 0"
_ofeq "windowDescribeT WD-0 nothing selected: each help box shows its own text" "$(_wdr WD-0 describeHelp) ; $(_wdr WD-0 wdBox)" "no describe line / 61 of 61 ; no describe line / 8 of 8"
_ofeq "windowDescribeT WD-1 firstLight's heading selected: the help box holds describeHead's description and draws what fits" "$(_wdr WD-1 describeHelp)" "describeHelp shows the description of describeHead / 311 of 2008"
_ofeq "windowDescribeT WD-2 a picture selected: saber's description; WD-3 the help box itself selected: nothing changes, still saber's" "$(_wdr WD-2 describeHelp) ; $(_wdr WD-3 describeHelp)" "describeHelp shows the description of saber / 111 of 111 ; describeHelp shows the description of saber / 111 of 111"
_ofeq "windowDescribeT WD-4 a second form: A's description in its own help box; WD-5 the box itself: still A's" "$(_wdr WD-4 wdBox) ; $(_wdr WD-5 wdBox)" "wdBox shows the description of wdA / 49 of 49 ; wdBox shows the description of wdA / 49 of 49"
_ofeq "windowDescribeT WD-6 ERRANT a field with no description: the help box is back to its own text (so the definition was never written)" "$(_wdr WD-6 wdBox)" "no describe line / 8 of 8"
_ofeq "windowDescribeT WD-7 ERRANT a form with no help box: the described field is selected and nothing else happens" "$(awk '/^WD-7/ {on=1} on && /^=== (click|describe)/' "$T/wd.o" | sed 's/^=== //; s/ *=== *$//' | tr '\n' ';' | sed 's/;$//')" "click wdNoBox wdC selected;click wdNoBox wdC fired nothing, on the way up through 2 fields"

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
#  TY-1 / TY-2 / TY-3 RE-PINNED SEQ 684 (Tony's settled edit: firstLight 500 wide): paragraph 1 wraps in two lines at 500, so words draws
#  3 lines, the blank line is y 78..92 and paragraph 2 (the run's line) y 93..108; the bands moved with it (incant/pop/typesetT says so).
_ofeq "typesetT TY-1 firstLight's words: two paragraphs, one run, every character drawn in three lines" "$(_tyl words)" "lines 3 drawn 205 of 205 next end paragraphs 2 of 2 runs 1"
_ofeq "typesetT TY-2 THE BLANK LINE: no ink across the field between the paragraphs (y 80..90); the line below it has ink" "$(_tyb gap) / $(_tyb before)" "none nored noblue / ink nored blue"
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
#  RE-PINNED SEQ 741: pour joined the form attributes (Topics/forms, above its bail), 28 -> 29, so FORMs holds 74.
#  RE-PINNED SEQ 742: margin and gap joined them (pour stage 2, D3 and D4), 29 -> 31, so 76.
_ofeq "drawFieldsT DF-1 FORMs holds 35 drawing fields, 31 form attributes, 7 unparked drawing entries and this file's three" "$(grep '^DF-1' "$T/df.e" | sed 's/.*holds *//' | xargs)" "76"
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

echo "-- the parent chain after layout (climbT)."
#  ⚑ climbT -- SEQ 652: a field three levels down climbs to its own laid-out parents. H7: with fillDownAcross's onlyWhenRepeating guard
#  removed, CL-1 and CL-2 read "cd2 newStuff acA" and "ca2 newStuff acA". CL-0 is the definition, never laid out. CL-3 to CL-5 (SEQ 653): under a
#  repeating parent; H7 with seal 485's fillDownAcross: CL-3 and CL-4 climb to newStuff, and CL-5's kids all read y 200.
_clF=$(ip climbT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_clF" > "$T/cl.o" 2> "$T/cl.e"; _clx=$?
_clr () { sed -n "s/^$1 *//p" "$T/cl.o" | xargs; }
_ofeq "climbT exit / sentinel" "$_clx $(grep -c '^CLIMBT SENTINEL' "$T/cl.e")" "0 1"
_ofeq "climbT CL-0 control, the definition: cd3 climbs cd2, cd, clDown" "$(_clr CL-0)" "cd3 cd2 cd clDown"
_ofeq "climbT CL-1 after layout under a down parent the climb is the same" "$(_clr CL-1)" "cd3 cd2 cd clDown"
_ofeq "climbT CL-2 after layout under an across parent: ca3 climbs ca2, ca, clAcross" "$(_clr CL-2)" "ca3 ca2 ca clAcross"
_clp () { awk -v pg="$1" '/^CL PAGE/{b=$3; next} b==pg' "$T/cl.o"; }
_ofeq "climbT CL-3 UNDER A REPEAT, down=3: each of the three kids climbs crCell, crRep, clNum" "$(_clp num | sed -n 's/^CL-3 *//p' | xargs)" "crKid crCell crRep clNum crKid crCell crRep clNum crKid crCell crRep clNum"
_ofeq "climbT CL-4 under down=\"*\": three rows fit, each leaf climbs crRow, crAll, clStar" "$(_clp star | sed -n 's/^CL-4 *//p' | xargs)" "crLeaf crRow crAll clStar crLeaf crRow crAll clStar crLeaf crRow crAll clStar"
_ofeq "climbT CL-5 each repeat owns its child: the kids' y are 0 100 200 (down=3) and the leaves' the same (down=*); the parent's style font and colour reach all three kids" "$(_clp num | grep 'crKid=' | sed 's/.* y=\([0-9]*\) .*/\1/' | xargs) / $(_clp star | grep 'crLeaf=' | sed 's/.* y=\([0-9]*\) .*/\1/' | xargs) / $(_clp num | grep -c '^=== drawSpans crKid font Palatino 24 1 color r239 g43 b45 ')" "0 100 200 / 0 100 200 / 3"
#  CL-6 RETIRED BY MAPPING (G3 item 1, SEQ 727, 2026-11-21): one direction per field; bothDirections and the F-157 warning are gone.
#    "clBoth is warned by name, once"  -> gone with the warning; a field naming both is now REFUSED by name: pop.sh reframeT RF-15 (pBoth).
#    "no other form here is warned"     -> carried below: no setFrame WARNING or REFUSING line in climbT at all.
#  clBoth is respelled as a row level (down="*" holding clRow across=2 height=50 holding clCross) with a leaf under each cell,
#  so the row also asks F-157's question: a field three levels down under a grid climbs to its own parents, once per copy.
_ofeq "climbT CL-6 a grid written as rows: each of the eight leaves climbs clCross, clRow, clBoth; no setFrame warning or refusal in climbT" "$(_clp both | sed -n 's/^CL-6 *//p' | sort | uniq -c | xargs) $(grep -c '^setFrame: \(WARNING\|REFUSING\)' "$T/cl.e")" "8 clLeaf clCross clRow clBoth 0"

echo "-- styles by merge at layout (styleMergeT)."
#  ⚑ styleMergeT -- SEQ 652 R1 (Tony, 2026-11-14): setFrame's mergeStyles merges a deep copy of every style:= into its field on the copy; own
#  attributes win on either side of style:=, of two styles the earlier wins. H7: with the mergeStyles call removed from setFrame, SM-1 to SM-5 go red.
_smF=$(ip styleMergeT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_smF" > "$T/sm.o" 2> "$T/sm.e"; _smx=$?
_smt () { awk -v pg="$1" -v f="$2" '/^SM PAGE/{b=$3} b==pg && $1=="===" && $2=="drawSpans" && $3==f' "$T/sm.o" | sed 's/.*font \(.*\) color \(r[0-9]* g[0-9]* b[0-9]*\) .*valign \([a-z]*\) align \([a-z]*\) ===/\1 \2 \3 \4/'; }
_smb () { awk -v pg="$1" '/^SM PAGE/{b=$3; next} b==pg && !/^=== /' "$T/sm.o"; }
_ofeq "styleMergeT exit / sentinel / nothing clipped" "$_smx $(grep -c '^STYLEMERGE SENTINEL' "$T/sm.e") $(grep -c 'does not fit' "$T/sm.e")" "0 1 0"
_ofeq "styleMergeT SM-1 a style gives its field font, color and align: smA" "$(_smt run1 smA)" "Palatino 24 1 r239 g43 b45 top center"
_ofeq "styleMergeT SM-2 OWN WINS ON EITHER SIDE: color:=green left of style:= (smB) and right of it (smC) both draw green in the style's font" "$(_smt run1 smB) / $(_smt run1 smC)" "Palatino 24 1 r0 g158 b15 top center / Palatino 24 1 r0 g158 b15 top center"
_ofeq "styleMergeT SM-3 of two styles the earlier wins: smT is the first's red and the second's bottom" "$(_smt run1 smT)" "Palatino 24 1 r239 g43 b45 bottom center"
_ofeq "styleMergeT SM-4 a style's text properties reach three levels down, and a nearer own colour wins: smD1, smD3 (black from smD2); smE has no style" "$(_smt run1 smD1) / $(_smt run1 smD3) / $(_smt run1 smE)" "Palatino 24 1 r239 g43 b45 top center / Palatino 24 1 r0 g0 b0 top center / Palatino 14 0 r0 g81 b186 top left"
_ofeq "styleMergeT SM-5 no name lands twice on the laid-out copy: smC holds one color and one font" "$(_smb run1 | grep 'smC=' | grep -o 'color=' | wc -l | tr -d ' ') $(_smb run1 | grep 'smC=' | grep -o 'font=' | wc -l | tr -d ' ')" "1 1"
_ofeq "styleMergeT SM-6 the form's definition and the style print the same after two runs as before (11 lines)" "$(_smb after | md5 -q) $(_smb after | grep -c .)" "$(_smb before | md5 -q) 11"
_ofeq "styleMergeT SM-7 a second run prints and draws as the first" "$(awk '/^SM PAGE/{b=$3; next} b=="run2"' "$T/sm.o" | md5 -q)" "$(awk '/^SM PAGE/{b=$3; next} b=="run1"' "$T/sm.o" | md5 -q)"

echo "-- placeholders and looks (lookT)."
#  ⚑ lookT -- SEQ 652 R2, R3 (Tony, 2026-11-14), built SEQ 654: a placeholder resolves through the request's look, else defaultLook; one in no look
#  is refused by name. H7: with the setLook call removed from setFrame no look is known, so LK-1 to LK-4 and LK-6 go red (LK-4 on lkB's font, inherited from the form's unresolved bodyFont; its fill and colour stay). LK-5 and LK-7 stay green.
_lkF=$(ip lookT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_lkF" > "$T/lk.o" 2> "$T/lk.e"; _lkx=$?
_lkb () { awk -v pg="$1" '/^LK PAGE/{b=$3; next} b==pg' "$T/lk.o"; }
_lkt () { _lkb "$1" | awk -v f="$2" '$1=="===" && $2=="drawSpans" && $3==f' | sed 's/.*font \(.*\) color \(r[0-9]* g[0-9]* b[0-9]*\) .*/\1 \2/'; }
_lkp () { _lkb "$1" | grep 'pixelAt pdfRead' | sed 's/.*= //; s/ ===.*//'; }
_ofeq "lookT exit / sentinel" "$_lkx $(grep -c '^LOOKT SENTINEL' "$T/lk.e")" "0 1"
_ofeq "lookT LK-1 NO LOOK IN THE REQUEST, defaultLook: the page white, lkA in headingFont and textColor, lkC (through a style) in headingFont and accent" "$(_lkp none) / $(_lkt none lkA) / $(_lkt none lkC)" "r255 g255 b255 a255 / Palatino 24 1 r0 g0 b0 / Palatino 24 1 r239 g43 b45"
_ofeq "lookT LK-2 THE SAME FORM UNDER look:=lkNight: the page black, lkA Courier white, lkC Courier lightBlue" "$(_lkp night) / $(_lkt night lkA) / $(_lkt night lkC)" "r0 g0 b0 a255 / Courier New 24 1 r255 g255 b255 / Courier New 24 1 r206 g255 b255"
_ofeq "lookT LK-3 a look that merges defaultLook and writes accent: only lkC's colour changes (green)" "$(_lkp green) / $(_lkt green lkA) / $(_lkt green lkC)" "r255 g255 b255 a255 / Palatino 24 1 r0 g0 b0 / Palatino 24 1 r0 g158 b15"
_ofeq "lookT LK-4 an ordinary name falls through under every look: lkB's fill:=wall and color:=blue, four pages" "$(for _p in none night green none2; do printf '%s %s / ' "$(_lkb $_p | grep 'lkB=' | grep -o 'fill=[a-zA-Z]*')" "$(_lkt $_p lkB)"; done)" "fill=wall Palatino 14 0 r0 g81 b186 / fill=wall Palatino 14 0 r0 g81 b186 / fill=wall Palatino 14 0 r0 g81 b186 / fill=wall Palatino 14 0 r0 g81 b186 / "
_ofeq "lookT LK-5 the form, its style, defaultLook and lkNight print the same after five layouts as before (7 lines)" "$(_lkb after | md5 -q) $(_lkb after | grep -c .)" "$(_lkb before | md5 -q) 7"
_ofeq "lookT LK-6 with no look again the page reads as LK-1 (9 lines each)" "$(_lkb none2 | md5 -q) $(_lkb none2 | grep -c .)" "$(_lkb none | md5 -q) 9"
_ofeq "lookT LK-7 A PLACEHOLDER IN NO LOOK is refused by name, once, and left as written" "$(grep -c '^setFrame: REFUSING lkBad -- its fill names the placeholder orphan and no look holds it' "$T/lk.e") $(_lkb bad | grep -c 'fill=orphan')" "1 1"
_ofeq "lookT LK-8 A STYLE WITH NO FILL DRAWS WITH NO REFUSAL (F-156): lkC, whose style holds font and colour only, 0 displayFill refusals on four pages; the one refusal in the run is lkBad's unresolved fill" "$(grep -c '^displayFill: REFUSING lkC ' "$T/lk.e") $(grep -c '^displayFill: REFUSING lkBad ' "$T/lk.e") $(grep -c '^displayFill: REFUSING' "$T/lk.e")" "0 1 1"

echo "-- a run's style through the look; the look goes down to a held form; the box warning (runLookT)."
#  ⚑ runLookT -- stroke 4 (SEQ 655): a run's style is its own deep copy with its placeholders resolved through the look its form was laid out under (the last layout's until SEQ 762; lookCopyT); a form held
#  in a field is laid out under its host's look; a run whose style holds a box attribute is warned by name. H7, one variable each: with resolveLook
#  removed from typeset RL-1, RL-2, RL-5, RL-6 (the colour) and RL-7 go red; with placeForm's look line removed RL-4 and RL-5 go red (the held form stays white and red under the night look).
_rlF=$(ip runLookT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_rlF" > "$T/rl.o" 2> "$T/rl.e"; _rlx=$?
_rlb () { awk -v pg="$1" '/^RL PAGE/{b=$3; next} b==pg' "$T/rl.o"; }
_rls () { _rlb "$1" | sed -n 's/^SPAN //p' | xargs; }
_ofeq "runLookT exit / sentinel" "$_rlx $(grep -c '^RUNLOOKT SENTINEL' "$T/rl.e")" "0 1"
_ofeq "runLookT RL-1 a run's style naming a placeholder (color:=accent), no look: the run's span holds defaultLook's red; the spans beside it hold none of their own" "$(_rls plain)" "plain field run red end field"
_ofeq "runLookT RL-2 the same text under look:=rnNight: the run holds lightBlue; and with no look again, red" "$(_rls night) / $(_rls plain2)" "plain field run lightBlue end field / plain field run red end field"
_ofeq "runLookT RL-3 the style and the form print the same after seven layouts as before (3 lines)" "$(_rlb after | md5 -q) $(_rlb after | grep -c .)" "$(_rlb before | md5 -q) 3"
_ofeq "runLookT RL-4 THE LOOK GOES DOWN: a form held in a field is white under no look and black under its host's look:=rnNight" "$(_rlb host | grep 'rnForm down' | grep -o 'fill=[a-zA-Z]* font=[a-zA-Z]* color=[a-zA-Z]*') / $(_rlb hostnight | grep 'rnForm down' | grep -o 'fill=[a-zA-Z]* font=[a-zA-Z]* color=[a-zA-Z]*')" "fill=white font=normalFont color=black / fill=black font=normalFont color=white"
_ofeq "runLookT RL-5 the held form's run follows the host's look too: red, then lightBlue" "$(_rls host) / $(_rls hostnight)" "plain field run red end field / plain field run lightBlue end field"
_ofeq "runLookT RL-6 THE BOX WARNING: a run whose style holds fill and rounded is warned once for each, by name, and still takes its colour" "$(grep -c '^drawSpans: WARNING rnBoxText -- its text names the style rnBoxy which holds the box attribute fill ' "$T/rl.e") $(grep -c '^drawSpans: WARNING rnBoxText -- its text names the style rnBoxy which holds the box attribute rounded ' "$T/rl.e") $(grep -c 'holds the box attribute' "$T/rl.e") / $(_rls box)" "1 1 2 / a field boxy red run field"
_ofeq "runLookT RL-7 a run's style naming a placeholder no look holds is refused by name, by drawSpans, once" "$(grep -c '^drawSpans: REFUSING rnLost -- its color names the placeholder rnOrphan and no look holds it' "$T/rl.e") $(grep -c 'REFUSING' "$T/rl.e")" "1 1"

echo "-- show(form): a form fired by one call (showT)."
#  ⚑ showT -- the show dispatch R2 (Tony, 2026-11-14), SEQ 660: show(form) builds its own request; the path is the form's own path=, else
#  IncantForms/PDF/output.pdf; a form naming look:= is laid out under it. SH-4 writes output.pdf, which is Tony's: it is moved aside here and put back.
#  H7 (SEQ 660): the look lines out of show -> SH-2 red (white page, Palatino); the own-path arm out -> SH-1 to SH-3 and SH-5 name output.pdf.
_shF=$(ip showT)
_shOut=IncantForms/PDF/output.pdf
rm -f "$T/sh.keep"; [ -f "$_shOut" ] && mv "$_shOut" "$T/sh.keep"
rm -f /tmp/incantTest.pdf
perl -e 'alarm 60; exec @ARGV' "$B" "$_shF" > "$T/sh.o" 2> "$T/sh.e"; _shx=$?
_shNew=0; [ -s "$_shOut" ] && _shNew=1
[ -f "$T/sh.keep" ] && mv "$T/sh.keep" "$_shOut"
_shb () { awk -v pg="$1" '/^SH PAGE/{b=$3; next} b==pg' "$T/sh.o"; }
#  _shs reads the "=== show <form> to <path> ===" line only: since SEQ 686 show also says "viewer off" or "opened" after it
_shs () { _shb "$1" | grep '^=== show .* to ' | sed 's/^=== show //; s/ ===.*//'; }
_sht () { _shb "$1" | awk '$1=="===" && $2=="drawSpans"' | sed 's/.*drawSpans \([A-Za-z]*\) font \(.*\) color \(r[0-9]* g[0-9]* b[0-9]*\) .*/\1 \2 \3/'; }
_shp () { _shb "$1" | grep 'pixelAt pdfRead' | sed 's/.*= //; s/ ===.*//'; }
_ofeq "showT exit / sentinel" "$_shx $(grep -c '^SHOWT SENTINEL' "$T/sh.e")" "0 1"
_ofeq "showT SH-1 A FORM WITH path=: show names the form and its path, and the page is drawn there under defaultLook" "$(_shs plain) / $(_shp plain) / $(_sht plain)" "shPlain to /tmp/incantTest.pdf / r255 g255 b255 a255 / shA Palatino 24 1 r0 g0 b0"
_ofeq "showT SH-2 A FORM NAMING look:=shNight is laid out under it: black page, Courier white" "$(_shs dark) / $(_shp dark) / $(_sht dark)" "shDark to /tmp/incantTest.pdf / r0 g0 b0 a255 / shB Courier New 24 1 r255 g255 b255"
_ofeq "showT SH-3 the look does not stay in show's request: shPlain again reads as SH-1" "$(_shp plain2) / $(_sht plain2)" "$(_shp plain) / $(_sht plain)"
_ofeq "showT SH-4 A FORM WITH NO path is written to IncantForms/PDF/output.pdf (line / a new file written)" "$(_shs home) / $_shNew" "shHome to IncantForms/PDF/output.pdf / 1"
#  SH-5 re-pinned 10 -> 11 (SEQ 762, popups stroke 0): the laid-out copy's top carries one attribute more, laidLook, the look it was laid out under.
#  SH-5 re-pinned 11 -> 12 (SEQ 763, popups stroke 1): and one more, laidForm, the name of the form the layout was for.
_ofeq "showT SH-5 show returns the laid-out copy: a list of 12 (its attributes, laidLook and laidForm among them, and its one member), width 400" "$(grep '^SH-5 ' "$T/sh.e" | xargs)" "SH-5 list 12 width 400"
_ofeq "ibkantT IB-7 IBkant's OWN listener calls show(IBkant): four show lines (the first page and three clicks), each to the path the fixture put on the form" "$(grep -c '^=== show IBkant to /tmp/incantTest.pdf ===' "$T/ib.o") $(grep -c '^=== show ' "$T/ib.o")" "4 4"

echo "-- selection is per form: two plain windows side by side (windowSelectT)."
#  ⚑ windowSelectT -- popups stroke 1 (SEQ 763, 2026-11-23; Tony's ruling 6, docs/popupsRecon.md): SELECTION IS PER FORM. utilities' selections keeps, by the
#  name of the form a window shows, the name of the field selected there; describedNames the same for what its help box described last. A layout reads its own
#  form's entry (slTop); a click knows its form from laidForm on the copy's top. Two offscreen windows, both laid out again before every read. Each row reads
#  four left-edge pixels (A's first field, A's wsShared, B's first field, B's wsShared; BLUE is the outline, midBlue) and each help box's characters drawn.
#  Control (H7, 2026-11-23, on the committed file, no build): one key for every form (slTop = "one" in setFrame, skF = "one" in selectKeep), which is the
#  one selection for the run that stood until this stroke -> S-2 to S-6 all move: A's outline and help text go when B is clicked, A's box shows B's words
#  at S-3, wsShared is outlined in both at S-4, unselect(wsA) at S-5 leaves B's wsShared outlined.
_wsF=$(ip windowSelectT)
GCSTRESS=1000 perl -e 'alarm 120; exec @ARGV' "$B" "$_wsF" > "$T/ws.o" 2> "$T/ws.e"; _wsx=$?
_wsr() { awk -v p="WS-PAGE $1 " '$0 == p {f=1; next} /^WS-PAGE /{f=0} f' "$T/ws.o" > "$T/ws.page"
         printf '%s / A %s / B %s' "$(grep '^=== pixelAt' "$T/ws.page" | sed 's/.*= //; s/ ===//; s/r0 g120 b215 a255/BLUE/; s/r0 g158 b15 a255/green/; s/r255 g255 b255 a255/white/' | xargs)" \
            "$(grep '^=== drawSpans wsBoxA ' "$T/ws.page" | tail -1 | sed 's/.* drawn \([0-9]*\) of.*/\1/')" "$(grep '^=== drawSpans wsBoxB ' "$T/ws.page" | tail -1 | sed 's/.* drawn \([0-9]*\) of.*/\1/')"; }
_ofeq "windowSelectT exit / sentinel / nothing refused" "$_wsx $(grep -c '^WINDOWSELECT SENTINEL' "$T/ws.e") $(cat "$T/ws.o" "$T/ws.e" | grep -c 'REFUS')" "0 1 0"
_ofeq "windowSelectT S-0 nothing selected: no outline in either window, each help box its own text" "$(_wsr S-0)" "green white green white / A 5 / B 13"
_ofeq "windowSelectT S-1 wsOne clicked in A: outlined, A's box shows its description; B untouched" "$(_wsr S-1)" "BLUE white green white / A 19 / B 13"
_ofeq "windowSelectT S-2 wsTwo clicked in B: B outlines it and describes it; A STILL OUTLINES wsOne AND STILL SHOWS ITS WORDS (both gone until SEQ 763)" "$(_wsr S-2)" "BLUE white BLUE white / A 19 / B 37"
_ofeq "windowSelectT S-3 A's help box itself clicked: A's box still shows what A described last (19), not B's (37)" "$(_wsr S-3)" "green white BLUE white / A 19 / B 37"
_ofeq "windowSelectT S-4 wsShared clicked in A: outlined in A only; B's wsShared plain, B still outlines wsTwo" "$(_wsr S-4)" "green BLUE BLUE white / A 5 / B 37"
_ofeq "windowSelectT S-5 unselect(wsA): A has no outline; B keeps its own" "$(_wsr S-5)" "green white BLUE white / A 5 / B 37"
_ofeq "windowSelectT S-6 the mock click by name is kept under the same form: wsOne outlined and described in A at the next layout" "$(_wsr S-6)" "BLUE white BLUE white / A 19 / B 37"

echo "-- the climb: only room is not selectable, a held form is crossed into its host, a close clears the selection (windowClimbT)."
#  ⚑ windowClimbT -- SEQ 764 (2026-11-23; Tony's rulings via Clay). utilities' selectable: a field is selectable when it has text, an image, an action or an
#  attribute holding one, a describe, a selectFill of its own, or a dESCRIPTIONs entry; else it is only room. clickField selects the first selectable field at or
#  above the one hit, and fires from the one hit; both climbs cross a held form's top into its host through heldIn, which a held form's setFrame writes on its
#  copy's top. A window's close goes to windowShut: keepFrame, then unselect. Run at GCSTRESS=1000; no window shown.
#  Controls (H7, 2026-11-23, on the committed file, no build), one each: clickUp never crossing -> C-2 reads 5 fields, C-3 "selected nothing" and nothing fired;
#  selectable answering 1 for every field -> C-1 selects space, the heading's outline goes, 4040 pixels differ; windowShut not calling unselect -> C-5's
#  reopened heading is still outlined.
_ccF=$(ip windowClimbT)
GCSTRESS=1000 perl -e 'alarm 120; exec @ARGV' "$B" "$_ccF" > "$T/cc.o" 2> "$T/cc.e"; _ccx=$?
_ccb() { awk -v p="CC-PAGE $1 " '$0 == p {f=1; next} /^CC-PAGE /{f=0} f' "$T/cc.o"; }
_ccl() { _ccb "$1" | grep '^=== click\|^=== describe\|^CC-SAY' | sed 's/^=== //; s/ *=== *$//; s/ *$//' | tr '\n' ';' | sed 's/;$//'; }
_ccp() { _ccb "$1" | grep '^=== pixelAt' | sed 's/.*= //; s/ ===//; s/r0 g120 b215 a255/BLUE/; s/r247 g232 b170 a255/wall/; s/r0 g158 b15 a255/green/' | xargs; }
_ofeq "windowClimbT exit / sentinel / nothing refused" "$_ccx $(grep -c '^WINDOWCLIMB SENTINEL' "$T/cc.e") $(cat "$T/cc.o" "$T/cc.e" | grep -c 'REFUS')" "0 1 0"
_ofeq "windowClimbT C-1 THE EMPTY FIELD LEFT OF OK: only room all the way up, nothing selected; the heading keeps its outline before and after; the window the same pixel for pixel" "$(_ccl C-1 | sed 's/^[^;]*;[^;]*;//') / $(_ccp C-1) / $(_ccb C-1 | grep '^=== displayDiff' | sed 's/.*differing \([0-9]*\),.*/\1/')" "click firstLight space selected nothing: only room, on the way up through 3 fields;click firstLight space fired nothing, on the way up through 3 fields / BLUE BLUE / 0"
_ofeq "windowClimbT C-2 A CLICK IN A HELD FORM BUBBLES ON INTO ITS HOST: describeHead in descriptions in firstLight, 7 fields on the way up (5 until SEQ 764)" "$(_ccl C-2)" "click descriptions describeHead selected;click descriptions describeHead fired nothing, on the way up through 7 fields;describe describeHelp shows the description of describeHead"
_ofeq "windowClimbT C-3 ROOM INSIDE A HELD FORM lands on the host's field that holds it: selected, its onClick fired and handed it, described in the host's help box" "$(_ccl C-3)" "click ccHeld ccIn selected;click ccHeld ccIn fired onClick ccSay;CC-SAY handed ccIn;describe ccBox shows the description of ccIn"
#  C-3o (SEQ 765, 2026-11-23; Tony: a selected field that holds a form shows its outline OVER the held form). spPaint marks such a field outlineOver on the
#  copy and drawKids draws its border once more after its members (drawOver). Control (H7, on the committed file, no build): the drawOver line removed ->
#  ccIn's edge after the click reads the held form's white, as it did until SEQ 765.
_ofeq "windowClimbT C-3o THE OUTLINE IS OVER THE HELD FORM: ccIn's edge white before the click; after it ccTop's edge green (not selected), ccIn's edge BLUE, the held form's middle still white" "$(_ccp C-3 | sed 's/r255 g255 b255 a255/white/g')" "white green BLUE white"
_ofeq "windowClimbT C-4 ERRANT a form that is only room: a click on its field and on the form itself select nothing and fire nothing" "$(_ccl C-4)" "click ccBare ccGap selected nothing: only room, on the way up through 2 fields;click ccBare ccGap fired nothing, on the way up through 2 fields;click ccBare ccBare selected nothing: only room, on the way up through 1 fields;click ccBare ccBare fired nothing, on the way up through 1 fields"
_ofeq "windowClimbT C-5 A CLOSED WINDOW'S FORM LOSES ITS SELECTION: the heading outlined, then closed and reopened: the page's wall; the other window, laid out again, still describes its own" "$(_ccp C-5) / $(_ccb C-5 | grep -c '^=== window closed: firstLight') $(_ccb C-5 | grep '^=== describe' | sed 's/^=== //; s/ *=== *$//')" "BLUE wall green / 1 describe ccBox shows the description of ccIn"

echo "-- the look rides on the laid-out copy (lookCopyT)."
#  ⚑ lookCopyT -- popups stroke 0 (SEQ 762, 2026-11-23; F-158): setFrame leaves the look it resolved through on the copy's top (laidLook), a held form's
#  top too, and typeset resolves a run through the nearest one above the field it draws, not through the look of the last layout. Run at GCSTRESS=1000.
#  Control (H7, 2026-11-23, on the committed file, no build): typeset's tsLookFind call replaced by tsLkHit = 0 -> LC-1 reads green and 470 differing,
#  LC-2 470 twice, LC-3 the held run green. LC-4 to LC-6 do not move under it (the stamp is still written; they pin the stamp and the unchanged roads).
_lcF=$(ip lookCopyT)
GCSTRESS=1000 perl -e 'alarm 120; exec @ARGV' "$B" "$_lcF" > "$T/lc.o" 2> "$T/lc.e"; _lcx=$?
_lcb() { awk -v p="LC PAGE $1 " '$0 == p {f=1; next} /^LC PAGE /{f=0} f' "$T/lc.o"; }
_lcpx() { _lcb "$1" | grep '^=== pixelAt' | sed 's/.*= //; s/ ===//' | xargs; }
_lcdf() { _lcb "$1" | grep '^=== displayDiff' | sed 's/.*differing \([0-9]*\),.*/\1/' | xargs; }
_lcsp() { _lcb "$1" | grep '^SPAN' | awk '{print $2, $3}' | xargs; }
_lcst() { _lcb "$1" | grep '^LC-STAMP' | awk '{print $2, $3}' | xargs; }
_ofeq "lookCopyT exit / sentinel / no refusal" "$_lcx $(grep -c '^LOOKCOPYT SENTINEL' "$T/lc.e") $(grep -c 'REFUS' "$T/lc.e")" "0 1 0"
_ofeq "lookCopyT LC-0 two windows under two looks: the night window's run red, the day window's green" "$(_lcpx night) / $(_lcpx day)" "r239 g43 b45 a255 / r0 g158 b15 a255"
_ofeq "lookCopyT LC-1 THE NIGHT WINDOW READ AGAIN AFTER THE DAY WINDOW'S LAYOUT: its run still red, 0 of 30000 pixels differ (470 and green until SEQ 762)" "$(_lcpx 'night again') / $(_lcdf 'night again')" "r239 g43 b45 a255 / 0"
_ofeq "lookCopyT LC-2 a click in a third window, then a resize and a click there: the day window unchanged both times, its run still green" "$(_lcdf third) / $(_lcpx third)" "0 0 / r0 g158 b15 a255"
_ofeq "lookCopyT LC-3 A HELD FORM THAT FELL BACK to its own look: its run is its own blue; the host's run, drawn last in hostB, the host's green" "$(_lcsp hostA) / $(_lcsp hostB)" "held field run blue end field / host field run green end field"
_ofeq "lookCopyT LC-4 the copy's top says which look: by name from a list, none, a look field" "$(_lcst hostA) / $(_lcst plain) / $(_lcst nightPdf)" "lcHostA dark / lcPlain none / lcFormN lcNight"
_ofeq "lookCopyT LC-5 no look and a look field on the PDF road, as before: defaultLook's red; lcNight's red on every run word" "$(_lcsp plain) / $(_lcsp nightPdf)" "plain field run red end field / plain field run red run red run red run red end field"
_ofeq "lookCopyT LC-6 the definitions carry no laidLook" "$(_lcb definition | grep -c laidLook) $(_lcb definition | grep -c 'lcFormN x=0')" "0 1"

echo "-- looks by name (looksByNameT)."
#  ⚑ looksByNameT -- SEQ 723 R1-R4 (Tony, 2026-11-20): firstLight carries looks:=firstLightLooks (standard, dark); the first is the default; a
#  request asks by name, look="dark"; a name the list lacks is refused by name and nothing is laid out; the held descriptions form, with no list,
#  uses defaultLook silently; lbHeld, whose list lacks dark, uses its own default with a trace line (ruled 2026-11-20). (450,15) is the heading: the page fill. (200,580) is in the held
#  form, its explicit lightGreen: the control, the same on every page. H7 (run SEQ 723): with setLook's call to setLookByName removed, LB-1, LB-3, LB-4 and LB-5 go red (page white throughout, no refusal, no trace); LB-2 stays green, as it compares to LB-1. H7 (run at the buy fix): with setLookByName's lookFirst call removed, LB-8 goes red (lbHeld white, no trace).
_lbF=$(ip looksByNameT)
perl -e 'alarm 60; exec @ARGV' "$B" "$_lbF" > "$T/lb.o" 2> "$T/lb.e"; _lbx=$?
_lbb () { awk -v pg="$1" '/^LB PAGE/{b=$3; next} b==pg' "$T/lb.o"; }
_lbp () { _lbb "$1" | grep 'pixelAt pdfRead' | sed 's/.*= //; s/ ===.*//' | xargs | sed 's/ a255 / a255 \/ /'; }
_ofeq "looksByNameT exit / sentinel" "$_lbx $(grep -c '^LOOKSBYNAMET SENTINEL' "$T/lb.e")" "0 1"
_ofeq "looksByNameT LB-1 NO LOOK ASKED: the list's first member, standard, gives the page wall; the held form's lightGreen" "$(_lbp none)" "r247 g232 b170 a255 / r175 g211 b120 a255"
_ofeq "looksByNameT LB-2 look=\"standard\" reads as LB-1" "$(_lbp standard)" "$(_lbp none)"
_ofeq "looksByNameT LB-3 look=\"dark\": the page black; the held form's lightGreen unmoved" "$(_lbp dark)" "r0 g0 b0 a255 / r175 g211 b120 a255"
_ofeq "looksByNameT LB-4 A NAME NOT IN THE LIST is refused by name, once, and nothing is laid out or written" "$(grep -c '^setFrame: REFUSING firstLight -- the request asks for the look print and its looks list holds no look by that name' "$T/lb.e") $(grep -c '^redrawForm: nothing laid out for rqPrint' "$T/lb.e") $(_lbb print | grep -c drawSpans)" "1 1 0"
_ofeq "looksByNameT LB-5 THE HELD FORM WITH NO LIST uses defaultLook silently (R1, ruled 2026-11-20): no trace line and no refusal naming descriptions" "$(grep -c 'descriptions is held under' "$T/lb.o") $(grep -c 'REFUSING descriptions' "$T/lb.e")" "0 0"
_ofeq "looksByNameT LB-7 A HELD FORM WHOSE LIST HAS THE NAME takes it, no trace: lbHost under standard, host page wall, lbHeld's own standard red" "$(_lbp hostStd) / $(_lbb hostStd | grep -c 'held under')" "r247 g232 b170 a255 / r239 g43 b45 a255 / 0"
_ofeq "looksByNameT LB-8 A HELD FORM WHOSE LIST LACKS THE NAME uses its own default with one trace line: lbHost under dark, host black, lbHeld red (standard)" "$(_lbp hostDark) / $(_lbb hostDark | grep -c '^setFrame: lbHeld is held under the look dark and its looks list has none by that name; it uses its own default, standard')" "r0 g0 b0 a255 / r239 g43 b45 a255 / 1"
_ofeq "looksByNameT LB-6 the list prints after four draws as defined" "$(_lbb after | grep -v '^\s*$' | xargs)" "firstLightLooks standard pageFill=wall; dark pageFill=black;"

echo "-- the kant environment, first piece (envT)."
#  ⚑ envT -- SEQ 724 R1-R4 (ruled 2026-11-20): environment (incant/setup) holds root, paths and forShow (searchNames, fileNames, stageNames);
#  show reads only from it, and a request's searchNames:= or fileNames:= replaces that member for one call; one list of loaded files; showPath
#  derives from environment.root. Run after Start() alone; every draw writes output.pdf, Tony's, set aside here and put back.
#  H7 (run SEQ 724): with the request's fileNames:= ignored in show, EN-1 goes red (unitTests loads too).
_enF=$(ip envT)
_enOut=IncantForms/PDF/output.pdf
rm -f "$T/en.keep"; [ -f "$_enOut" ] && mv "$_enOut" "$T/en.keep"
perl -e 'alarm 60; exec @ARGV' "$B" "$_enF" > "$T/en.o" 2> "$T/en.e"; _enx=$?
rm -f "$_enOut"; [ -f "$T/en.keep" ] && mv "$T/en.keep" "$_enOut"
_enb () { awk -v pg="$1" '/^EN PAGE/{b=$3; next} b==pg' "$T/en.o"; }
_ens () { _enb "$1" | grep -E '^=== show firstLight (deferred|to)' | sed 's/ *$//; s/=== show firstLight //; s/ ===$//; s/:.*//' | tr '\n' '|'; }
_ofeq "envT exit / sentinel" "$_enx $(grep -c '^ENVT SENTINEL' "$T/en.e")" "0 1"
#  LOOSENED SEQ 726 (Tony, 2026-11-21): EN-1 and EN-6 check MEMBERSHIP, not load order -- each list is sorted before the compare.
#  The order is the order the files finish loading (only a file's foot writes loadedFiles), which is not the claim; each once is.
_ofeq "envT EN-1 fileNames:= IN PLACE OF environment's: firstLight from the stash, styles and utilities loaded once each though styles is named twice, unitTests not at all; drawn" "$(_ens files) / $(_enb loaded | awk '/^loaded/{print $2}' | sort | xargs)" "deferred|to IncantForms/PDF/output.pdf| / styles utilities"
_ofeq "envT EN-2 showPath derives from environment.root: root . gives the relative path" "$(_enb path | grep '^showPath' | awk '{print $2}')" "IncantForms/PDF/output.pdf"
_ofeq "envT EN-3 searchNames:= FORMs Utilities: drawn; fileNames not named, so environment's stand and unitTests loads first (deferred)" "$(_ens short)" "deferred|to IncantForms/PDF/output.pdf|"
_ofeq "envT EN-4 searchNames:= naming noSuchRegistry: refused by name, once, and nothing drawn" "$(grep -c '^REFUSED show -- its search list names noSuchRegistry -- not a registry; nothing drawn' "$T/en.e") $(_enb noreg | grep -c '^=== show firstLight')" "1 0"
_ofeq "envT EN-5 a request naming only form:= keeps every default: drawn with nothing to load" "$(_ens plain)" "to IncantForms/PDF/output.pdf|"
_ofeq "envT EN-6 EACH FILE ONCE: after four shows the loaded list holds styles, unitTests and utilities, once each (sorted)" "$(_enb again | awk '/^loaded/{print $2}' | sort | xargs)" "styles unitTests utilities"
_ofeq "envT EN-7 THE DERIVATION IS REAL: root elsewhere gives elsewhere/IncantForms/PDF/output.pdf; root . back gives the relative path" "$(_enb root | awk '/^showPath/{print $2}' | xargs)" "elsewhere/IncantForms/PDF/output.pdf IncantForms/PDF/output.pdf"

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
