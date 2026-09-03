-------------------------------------------------------------------
  WALKIE-TALKIE  -  CLOD -> SKIP MINION
  Clod writes this file. The Skip minion reads it, acts, then clears it.
  The minion's replies go in ipc/skip-to-clod.md  (never write here, minion).
-------------------------------------------------------------------
SEQ:      1
STATUS:   fresh          # fresh = parked/unread | working = picked up, in progress | cleared = done
WRITTEN:  2026-09-03  -  Clay (SEQ 152b charter, dictated via Tony; transcribed
          by Clod at pickup, WT-9/WT-15)
          ⚠ CHANNEL OPENED FOR THIS CHARTER. It runs when Clod says the fence
          is ready; it DOES NOT GATE item 4 and nothing about it is started.
-------------------------------------------------------------------

===================================================================
SEQ 1  --  MINION CHARTER: Skip -- a kant rule for what checkSkip does
===================================================================

STATUS: fresh -- transcribed AT PICKUP per WT-15, NOT DISPATCHED. The fence is
        not declared ready and the minion has not been fired.

------------------------- BEGIN VERBATIM -------------------------

MINION CHARTER — Skip: a kant rule for what checkSkip does
Issued 2026-09-03. Read-only outside the fence. Nothing installs.

THE QUESTION, two halves graded separately:
  (a) can a kant grammar rule express the parser's inter-term skip —
      whitespace, comments, and stopping at a quote — matching the C++
      checkSkip on the whole corpus, cursor for cursor;
  (b) what did you have to route around in kant to write it.
  Half (b) is not a side note. Every workaround is a deliverable.

THE ORACLE: the C++ checkSkip. Read it first; it is the spec for
whitespace and for whether /* */ nests. Do not improve on it — a
divergence is a finding to classify, not a bug to fix.

THE RULE: `Skip`, a grammar rule that consumes whitespace, `//` to end
of line, and `/* ... */` per the oracle, and STOPS at a quote without
entering it (a string is a token, not skip material). It returns the
cursor. It MUST NOT itself invoke skipping between its own terms — say
in the report how you prevented that, or that you could not.

THE FIXTURE: incant/skipT, two arms over the corpus. For every call
site the oracle would service, record where the mark lands after the
C++ arm and after the Skip arm. Diff. The report's first table is that
diff, every divergence with: the input bytes at the mark, old-arm
result, new-arm result, and a grade — OLD-ARM BUG / NEW-ARM BUG /
UNDECIDED. Comments and quotes are where the arms are expected to
disagree; that table is the point.
The cursor is the instrument, never the verdict (2026-08-11). A
fixture that reports SUCCESS/FAIL per call is void.

THE CLAIMS: every place you wanted to write X and wrote Y instead, in
the pilot's CLAIM format: what you wanted, what you wrote, a one-line
reproducer of the limitation, and whether you think it is a defect or
a design. Numbered. This list is graded against docs/fixIts.md by
someone else; do not consult that file.

THE FENCE: writes to minionWork/skipRule/ and incant/skipT only. No
edit to grammar, setup, any .twk/.rtn, or the hook. No build. The
rule is exercised as a fixture rule, never installed.

KANT FACTS YOU WILL TRIP ON: `Start();` is the first line or nothing
runs (#27); prose headers go in a comment block, not bare; a blank
line inside a define block ends the block silently; a bare undeclared
name in an action body is a local cleared on entry (#39); `if x;`
tests presence, `x == 0` tests value, and they disagree; `:=` binds a
pointer, `=` copies a value, `<-` copies a field.

OUT OF SCOPE: performance, the hook, replacing anything. Those are
Clod's after the count of checkSkip calls per fleet run exists.

REPORT: the diff table; the claims list; the rule's text; what you
could not do and stopped on, named. Say nothing about whether it
should ship.

-------------------------- END VERBATIM --------------------------

  ⚠ CLOD'S NOTE AT PICKUP, for whoever fires this: the oracle is
  `checkSkip` in GroupRules.twk (the .twk is the source of truth; the
  generated .mm is the same code and easier to read for the nesting
  question). Note the fence forbids a build, so the minion works against
  whatever binary is installed -- and bear-trap #31 applies in its runtime
  form: `incant/setup` is read at RUN time, so a registration added there
  goes live against a binary that may not carry its extern. The fence
  forbids touching setup, which closes that hazard by construction.

  END SEQ 1
