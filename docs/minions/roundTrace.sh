#!/bin/sh
#  roundTrace.sh -- capture a Minion round's ACTIONS into a ledger-ready block.
#
#      sh docs/minions/roundTrace.sh <agent-transcript.jsonl>
#
#  WHY THIS EXISTS, and it is not for the narrative. docs/minionAHarness.md S1
#  makes the leak check the FIRST thing that matters -- "did the agent see
#  anything outside {corpus, brief, target}?" -- and S2's whole instrument
#  depends on that answer, because a leaked round's number is uninterpretable
#  whichever way it comes back. Until this script there was NO WAY TO ANSWER IT.
#  Foreman watched a scroll go past and then reconstructed from the round's own
#  report, which is the round reporting on its own compliance.
#
#  So the INPUT SURFACE section below is the point. The action trace is context.
#
#  IT IS A FOREMAN INSTRUMENT, and it is deliberately mechanical: the same
#  argument pop.sh earns its place on. Hand-rolling this per round is how the
#  escaping gets wrong once and nobody notices.
#
#  ⚠ ONE HONEST EXPOSURE: this file lives in the repo, and the repo is background
#  the round may read while orienting. A round that reads it learns it is being
#  traced, which is an observer effect on the very compliance being measured. It
#  carries no round-learning, so it is not a Leak-3 laundering path -- but it is
#  not sealed either. Named rather than claimed away, same as the ledger's
#  git-history residual.
set -e
T="$1"
if [ -z "$T" ] || [ ! -r "$T" ]; then
    echo "usage: sh docs/minions/roundTrace.sh <agent-transcript.jsonl>" >&2
    exit 2
fi

echo "#### ROUND TRACE -- \`$(basename "$T")\`"
echo ""
echo '```'
printf 'entries      %s\n' "$(wc -l < "$T" | tr -d ' ')"
printf 'first        %s\n' "$(jq -r 'select(.timestamp)|.timestamp' "$T" | head -1)"
printf 'last         %s\n' "$(jq -r 'select(.timestamp)|.timestamp' "$T" | tail -1)"
echo '```'
echo ""

#  THE LEAK CHECK. Every path the round opened, however it opened it -- Read,
#  and the file arguments of Bash lines too, since `cat X` reads X exactly as
#  Read does and a check that only counted Read would be trivially evadable.
echo "**INPUT SURFACE — every path the round opened.** Harness §1: inputs are the corpus,"
echo "the brief, and the rung target. Anything else here is background-orientation at best"
echo "and a leak at worst; it is foreman's call, made against this list rather than against"
echo "the round's own account of itself."
echo ""
echo '```'
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") |
       if .name=="Read" then .input.file_path
       elif .name=="Bash" then .input.command
       else empty end' "$T" 2>/dev/null |
  tr ' ;|&()' '\n' |
  grep -oE '(docs|incant|genLadder|GUI|Tests)/[A-Za-z0-9_.-]+|[A-Za-z0-9_-]+\.(twk|rtn|mm|h|md|ext|target|base|sh)' |
  sed 's|^/*||' | sort -u
echo '```'
echo ""

#  THE WRITE SURFACE. Leak 3: the corpus is the only writable surface besides the
#  method. This is the one that must come back SHORT.
echo "**WRITE SURFACE — Leak 3 says the corpus and the method, nothing else.**"
echo ""
echo '```'
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") |
       select(.name=="Write" or .name=="Edit" or .name=="NotebookEdit") |
       "\(.name)  \(.input.file_path)"' "$T" 2>/dev/null | sort | uniq -c | sed 's/^ *//'
echo '```'
echo ""

echo "**ACTION TRACE**, in order. Truncated to 150 columns; the point is the shape of the"
echo "round, not a replayable log."
echo ""
echo '```'
jq -r 'select(.type=="assistant") | .message.content[]? |
       if .type=="tool_use" then
         "\(.name)  \(.input.description // .input.file_path // .input.command // .input.pattern // "")"
       elif .type=="text" then ("say   " + (.text|gsub("\n";" ")))
       else empty end' "$T" 2>/dev/null | cut -c1-150
echo '```'
