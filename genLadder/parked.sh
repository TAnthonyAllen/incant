#!/bin/sh
#  parked.sh -- STAGE TWO OF RETIREMENT. Run from the Groups directory:
#      sh genLadder/parked.sh
#
#  ===========================================================================
#  THE CHARTER CLAUSE, verbatim (Tony, 2026-08-13, SEQ 63):
#
#     Retirement is two-stage. Stage one: move the check to parked.sh with
#     date, reason, and origin slot. Stage two: after the frontier has moved
#     past it a few times, run parked.sh -- red rows reinstate or file as
#     findings; green and unrunnable rows flush. The incident record keeps the
#     reason; only the mechanism is discarded.
#  ===========================================================================
#
#  ⚠ THE GRADING IS ASYMMETRIC, AND THAT IS THE WHOLE DESIGN. Disposal is a
#  MEASUREMENT, not a tidy-up, so the two outcomes are not worth the same:
#
#      GREEN is WEAK evidence. These rows were parked precisely BECAUSE they
#      only ever ran green -- a green here says nothing that was not already
#      true when the row was parked. Flush it.
#
#      RED is DECISIVE. A parked row going red means the thing it guarded has
#      moved while nobody was watching. Reinstate it into smoke.sh, or file it
#      as a finding. NEVER flush a red row: that is deleting the only evidence
#      of a regression at the exact moment it appears.
#
#  ⚠ UNRUNNABLE IS ITS OWN OUTCOME AND IS NEVER A PASS (H4 on the whole lot).
#  A row whose fixture has vanished has not been checked. It reports ???? and
#  still counts as a recorded check, so this harness's own self-certification
#  cannot be satisfied by rows quietly evaporating -- which is the failure mode
#  that has now bitten this project four times.
#
#  ⚠ EXEMPT FROM THE SCREEN RULE, deliberately. smoke.sh must fit one screen
#  because it runs every iteration; this runs at FLUSH MOMENTS only, so it may
#  be as long as the parked list is and should print each row's date, reason
#  and origin. A parked row you cannot read the provenance of is a parked row
#  nobody can dispose of honestly.
#
#  HELPERS ARE SOURCED FROM smokelib.sh, NEVER COPIED. A lot visited only at
#  flush moments is exactly where a stale copy rots longest and is noticed
#  last -- see that file's header for the four-instance ledger behind the rule.

B=${INCANT:-$HOME/bin/incant}
T=${TMPDIR:-/tmp}/parked.$$
CAP=${POPCAP:-30}
mkdir -p "$T"
fail=0
checks=0
red=0
green=0
dead=0

. genLadder/smokelib.sh

if [ ! -x "$B" ]; then echo "  FAIL  binary not executable: $B"; exit 1; fi
echobin
echo ""
echo "  PARKED CHECKS -- stage two. Green flushes, RED reinstates or files."
echo ""

#  ---------------------------------------------------------------------------
#  parkrow <fixture> <sentinel|-> <want|-> <parked-date> <origin> <reason>
#  ---------------------------------------------------------------------------
parkrow () {
    pk_f=$1; pk_s=$2; pk_w=$3; pk_d=$4; pk_o=$5
    shift 5
    echo "  ---- $pk_f"
    echo "       parked $pk_d   from $pk_o"
    echo "       reason $*"
    row "$pk_f" "$pk_s" "$pk_w" "     $pk_f"
    case $? in
      0) green=$((green+1)); echo "       verdict FLUSH -- green is weak evidence; it was parked for running green." ;;
      1) red=$((red+1));     echo "       verdict ⚠ RED -- REINSTATE into smoke.sh or file as a finding. DO NOT FLUSH." ;;
      2) dead=$((dead+1));   echo "       verdict FLUSH -- fixture gone, nothing left to guard." ;;
    esac
    echo ""
}

#  ===========================  THE PARKED LIST  =============================
#
#  FIRST RESIDENTS, 2026-08-13 (SEQ 63). bindSeamB held smoke.sh slot 1 from
#  SEQ 60 until SEQ 61 pinned it in pop.sh. A fixture pinned in the fleet is
#  fleet business; holding it in the bell as well was duplication, not
#  coverage. Both its value row and its ARM row come here together, because
#  parking the value without the arm would park half a check -- 251 alone can
#  pass for the wrong reason, which is the whole lesson of that pin.
#
#  NOTE the arm row is not expressible through parkrow's value test, so it is
#  written out below rather than faked into one. A parked check that changed
#  shape on the way in is not the check that was parked.

parkrow bindSeamB "BINDSEAMB SENTINEL" "sumple width is now 251" \
        2026-08-13 "smoke.sh slot 1" \
        "promoted to pop.sh pin, SEQ 61"

echo "  ---- bindSeamB ARM (generated arm, promote=0)"
echo "       parked 2026-08-13   from smoke.sh slot 1"
echo "       reason promoted to pop.sh pin, SEQ 61 -- rides with the value row above"
if [ ! -f incant/bindSeamB ]; then
    unrunnable "     bindSeamB arm"; dead=$((dead+1))
    echo "       verdict FLUSH -- fixture gone, nothing left to guard."
elif grep -q "attachLabel lab=Braced promote=0" "$T/bindSeamB" 2>/dev/null; then
    pass "     bindSeamB arm (promote=0, generated)"; green=$((green+1))
    echo "       verdict FLUSH -- green is weak evidence; it was parked for running green."
else
    bad "     bindSeamB arm -- no promote=0 Braced attach; the cross-file bind is NOT being read"
    red=$((red+1))
    echo "       verdict ⚠ RED -- REINSTATE into smoke.sh or file as a finding. DO NOT FLUSH."
fi
echo ""

#  ===========================================================================
echo "  green $green   RED $red   unrunnable $dead   (checks recorded: $checks)"
echo ""

#  ⚠ H2 TURNED ON THIS HARNESS. A vanished helper set cannot satisfy this.
if [ "$checks" -lt 3 ]; then
    echo "PARKED INVALID -- only $checks checks recorded, expected at least 3."
    echo "                  A check that evaporates is invisible in a count of checks."
    rm -rf "$T"; exit 1
fi

if [ $red != 0 ]; then
    echo "PARKED HAS RED ROWS -- $red of them. Reinstate or file BEFORE flushing anything."
    echo "                       A red parked row is a regression nobody was watching for."
else
    echo "PARKED ALL CLEAR -- $green green, $dead unrunnable, nothing to reinstate."
    echo "                    These rows are flushable. Green is weak evidence and that is"
    echo "                    the point: they were parked for only ever running green."
fi
rm -rf "$T"
exit $fail
