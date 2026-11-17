#!/bin/bash
export INCANT_NOVIEW=1   # SEQ 686: show never opens a viewer from a script of Clod's
#  pdfCaptures.sh -- SEQ 684 (Clay's forms dispatch, ruled by Tony, 2026-11-17): writes docs/sealCaptures/firstLight.pdf and
#  descriptions.pdf, each form fired by Topics/forms' firing lines through a request whose path= is the capture, so
#  IncantForms/PDF/output.pdf (Tony's) is never written. A capture to compare a drawing against; not a row and on no checklist.
#  The captures embed Tony's pictures: they stay on disk and gitignored (Tony, 2026-11-17: no pictures in the repo).
#  Run it when a form's look is settled. Each capture is checked to exist, begin %PDF and read back one page.
cd "$(dirname "$0")/.." || exit 1
B="${INCANT:-$HOME/bin/incant}"
T=$(mktemp -d); fail=0
echo "  bin   $B"; echo "  bin   $(stat -L -f '%z bytes  %Sm' "$B")"
for form in firstLight descriptions; do
    out="docs/sealCaptures/$form.pdf"; rm -f "$out"
    cat > "$T/$form" <<HEAD
Start();
include(unitTests);
include(utilities);
search reset stack Grokking;
registry(fILEs);
define
    formFile File='IncantForms/Windows/$form';
    ;
include(styles);
search cOLOr fONTs sTYLEs;
include(formFile);
search FORMs UnitTests Utilities cOLOr fONTs sTYLEs list;
define
    capReq path="$out" form:=$form;
    capRead path="$out";
    ;
redrawForm(capReq);
readPDF(capRead);
cerr "PDFCAPTURE SENTINEL":;
stop();
HEAD
    perl -e 'alarm 60; exec @ARGV' "$B" "$T/$form" > "$T/$form.o" 2> "$T/$form.e"; x=$?
    pages=$(grep -h '^=== readPDF capRead' "$T/$form.o" "$T/$form.e" | sed 's/.*capRead //; s/ ===.*//')
    if [ $x = 0 ] && grep -q '^PDFCAPTURE SENTINEL' "$T/$form.e" && [ "$(head -c 4 "$out" 2>/dev/null)" = "%PDF" ]; then
        echo "  ok    $out  ($pages)"
    else echo "  FAIL  $out  exit $x, read [$pages]"; fail=1; fi
done
rm -rf "$T"; exit $fail
