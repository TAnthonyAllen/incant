#  smokelib.sh -- SHARED HELPERS FOR smoke.sh AND parked.sh. Not runnable on
#  its own; it is sourced.
#
#  ⚠ THIS FILE EXISTS SO THERE IS ONE COPY, AND THAT IS NOT TIDINESS. This
#  project has now recorded FOUR instances of copy-the-idiom-lose-the-helper:
#  incant/jiquery's three stop() calls, pop.sh's missing `sentinel`, the JIT
#  ladder calling `check` and `sentinel` without defining them, and the shell
#  collision inside smoke.sh's own first cut. A lot that is visited only at
#  FLUSH MOMENTS -- which is exactly what parked.sh is -- is where a stale copy
#  rots longest and is noticed last. So parked.sh sources this; it never
#  copies it.
#
#  CALLER CONTRACT. These functions read the caller's variables at call time:
#      $B      the binary            $T      a scratch dir the caller made
#      $CAP    wall-clock cap        $fail   set to 1 on failure
#      $checks incremented per recorded check
#  A caller that does not set them will fail loudly rather than silently, which
#  is the point.

#  ⚠ THE cap_ PREFIX IS LOAD-BEARING. sh has NO function scope. The first cut
#  used _p/_w/_rc here and _s/_w/_l in the caller, and the watchdog PID
#  silently overwrote the wanted STRING -- so rows compared their output against
#  a five-digit process id and reported FAIL with `want: 80340`. Caught in one
#  run only because the row prints the value it wanted (H4); a bare pass/fail
#  would have read as three real reds. Do not shorten these names.
runcap () {                       # runcap <fixture> <outfile>
    $B "incant/$1" > "$2" 2>&1 &
    cap_pid=$!
    { ( sleep "$CAP"; kill -9 $cap_pid 2>/dev/null ) >/dev/null 2>&1 & } 2>/dev/null
    cap_wd=$!
    wait $cap_pid; cap_st=$?
    { kill $cap_wd 2>/dev/null; wait $cap_wd 2>/dev/null; } 2>/dev/null
    [ $cap_st = 137 ] && cap_st=124
    return $cap_st
}

pass () { echo "  ok    $1"; checks=$((checks+1)); }
bad  () { echo "  FAIL  $1"; shift; [ -n "$1" ] && echo "        $*"; fail=1; checks=$((checks+1)); }

#  ⚠ UNRUNNABLE IS NOT A PASS (H4 on the whole lot). A row whose fixture has
#  vanished has not been checked; reporting it as ok would be an absence check
#  wearing a diff's clothes. It counts as a recorded check so the caller's
#  self-certification cannot be satisfied by rows evaporating.
unrunnable () { echo "  ????  $1 -- FIXTURE MISSING, not checked"; checks=$((checks+1)); return 0; }

#  The shared row shape: ran, did not truncate, said the right thing.
#  Pass "-" for sentinel or want to skip that leg.
row () {                          # row <fixture> <sentinel|-> <want|-> <label>
    row_f=$1; row_s=$2; row_w=$3; row_l=$4
    if [ ! -f "incant/$row_f" ]; then unrunnable "$row_l"; return 2; fi
    runcap "$row_f" "$T/$row_f"; row_rc=$?
    if [ $row_rc = 124 ]; then bad "$row_l -- TIMEOUT after ${CAP}s (a hang is not a wrong answer)"; return 1; fi
    if [ $row_rc != 0 ];  then bad "$row_l -- exit $row_rc"; return 1; fi
    if [ "$row_s" != "-" ] && ! grep -qF "$row_s" "$T/$row_f"; then
        bad "$row_l -- sentinel absent, run TRUNCATED; every other ok in it is uninterpretable"; return 1; fi
    if [ "$row_w" != "-" ] && ! grep -q "$row_w" "$T/$row_f"; then
        bad "$row_l" "want: $row_w"
        grep -o 'sumple width is now [0-9]*' "$T/$row_f" | sed 's/^/        got:  /'; return 1; fi
    pass "$row_l"
    return 0
}

#  ⚠ H1+ THE STALENESS GUARD. Size is NOT proof -- two rebuilds in one week
#  came back byte-identical in size. A stale binary does not fail as a diff, it
#  fails as a hang or a phantom.
echobin () {
    echo "  bin   $B"
    echo "  bin   $(ls -lL "$B" | awk '{print $5" bytes  "$6" "$7" "$8}')"
    bin_newest=$(ls -t *.mm 2>/dev/null | head -1)
    if [ -n "$bin_newest" ] && [ "$bin_newest" -nt "$B" ]; then
        bad "STALE BINARY -- $bin_newest is newer than $B. Rebuild before reading anything below."
        return 1
    fi
    pass "binary is newer than the newest generated .mm"
    return 0
}
