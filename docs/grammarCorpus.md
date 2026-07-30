# The grammar corpus

*What a round of the GRAMMAR MINION knows about incant's grammar and surface syntax.
**This is the only surface the grammar loop may write to.*** It is a sibling of, and
deliberately separate from, `docs/kantCorpus.md` — that file is minion A's instrument and
writing to it would contaminate a measurement.

**If you are a round of the grammar minion:** read this first, then your brief. Everything
here was drafted by an earlier round that has no way to tell you anything except through
this file. If you need something that is not here, **that is the finding** — record it, do
not work around it silently.

Format and confidence vocabulary are `docs/kantCorpus.md`'s, unchanged, so the two corpora
read the same way. Grade on your **own** provenance, never on a neighbour's — adjacency is
not provenance.

| confidence | a reader should |
|---|---|
| **RUN** | act on it |
| **MEASURED** | act, but respect `asOf` — the tree moves |
| **READ** | act with care |
| **REASONED** | **do not act — check first** |
| **ASSUMED** | treat as an open item |

**A corpus whose claims drift downward over time is rotting**, and that is visible at a
glance. REASONED and ASSUMED are the challenge queue.

---

## ROUND 1 — 2026-07-30. Task: add `cout` and `cerr` to incant's surface

**Verdict, up front, because half of it is a refusal and the refusal is the more valuable
half:**

| | verdict | one-line evidence |
|---|---|---|
| **`cout`** | **BUILT, sandbox-safe, oracle byte-identical** | `incant/sinkGraft` grafts a new rule into the live `WardeD` at runtime; six PrintXP shapes under `print` and under `cout` `cmp` clean, exit 0 |
| **`cerr`** | **REFUSED — not sandbox work** | there is no stderr branch anywhere in the print path; adding one is an edit to `Instruct.rtn`/`ruleActions.rtn`, which is row 3 of the brief's table |
| **stderr generally** | **reachable today, no C++ change** | but NOT as a per-statement sink — see GRAM-6, which qualifies `kantCorpus` CLAIM KANT-12 |

**Classification against the brief's three rows.** `cout` is row 1: it parallels `PrinT`
term-for-term and `print` is its oracle. `cerr` is row 3 *as a proper sink*: reaching stderr
requires changing `opPrint`'s two-way `if`, which is an existing shared rule. It is also
row 2 *as a design* — the clean spelling (a keyword field genuinely named `cerr`) has no
oracle because nothing in the tree selects a sink by anything other than the hack GRAM-2
documents.

**Files this round produced, all new, none shared:**

| file | what it is |
|---|---|
| `incant/sinkGraft` | the deliverable — `cout` grafted at runtime, plus the byte-identical oracle and the `cerr` counterexample |
| `incant/sinkProbe` | the evidence fixture for GRAM-1 (bisect + control + fix), one exit-0 run |
| `incant/sinkStderr` | the GRAM-6 probe — stderr via a `/dev/stderr`-backed buffer |
| `incant/sinkGuard` | the GRAM-5 probe — is `guard()` load-bearing for a `WardeD` graft? |

**Regression net, before and after, all byte-identical:**

```
$BINARY incant/oneTest    EXIT=0   diff vs baseline: identical  (maximus = 11, then 26 x4)
$BINARY incant/jsonTest   EXIT=0   diff vs baseline: identical  (13 ok)
sh genLadder/pop.sh       EXIT=0   diff vs baseline: identical  (22 ok, POP PASSED)
```

Captured **before** any file was written and re-run after. Per the brief: those 22 are a
regression net, not evidence — the evidence that `cout` exists is the oracle in GRAM-3.

---

## CLAIMS

### CLAIM GRAM-1 — a bare reference to a METHOD-BEARING field INVOKES it, so `+=` cannot graft a rule that already carries `ruleMethod=`
```
statement:   In an expression, a bare name that resolves to a field carrying a
             method is CALLED, and the expression sees the call's RESULT, not
             the field. So `WardeD += CoutXP;` where CoutXP was defined with
             `ruleMethod=aCTionPrinT` does not graft CoutXP: it invokes
             aCTionPrinT and adds the returned trueResult ARITHMETICALLY.
             The graft fails SILENTLY -- exit 0, no diagnostic on the graft
             itself, and the only tell is that the member count did not move.
             THE FIX: define the rule PLAIN, graft it, then RE-OPEN the name in
             a second `define` to attach `ruleMethod=` and `defer`.
confidence:  RUN
provenance:  incant/sinkProbe, one run, EXIT=0, 2026-07-30. Additive bisect of
             seven rules differing by one feature each:
                 S1  pCout="cout"                                    grafted
                 S2  + followedBy                                    grafted
                 S3  + PRINTing-                                     grafted
                 S4  + stuff=PrintXP+                                grafted
                 S5  + SemI-                                         grafted
                 S6  + ruleMethod=aCTionPrinT                    NOT grafted
                 S7  + defer                                     NOT grafted
             WardeD went 10 -> 15 members and came back carrying `WardeD=2 int`
             -- two invocations, two trueResults, added as numbers. Controls
             that separate "the define failed" from "the += failed":
               - dumpContents(S6) and dumpContents(S5) dump IDENTICAL five-
                 attribute structures, so S6 is a real, well-formed rule.
               - stderr carries EXACTLY ONE `nextGroup: ERROR stuff does not
                 contain a list` per method-bearing bare reference -- that is
                 aCTionPrinT running against an empty `stuff`, i.e. proof the
                 method really was entered. Two references, two errors.
               - PART 3: the same rule shape grafted plain and then given its
                 method in a second define lands cleanly (WardeD -> 16, S8 at
                 the tail) with NO extra stderr line.
asOf:        2026-07-30
scope:       Established for `+=` (opAddGroup) and, separately, for ARGUMENT
             position: `dumpContents(S6)` after S6 had already been invoked
             once dumped `true` (trueResult) rather than the rule. ⚠ AND THAT
             LAST ONE IS ORDER-DEPENDENT IN A WAY THIS ROUND DID NOT EXPLAIN:
             in an earlier probe the SAME `dumpContents(S6)` call, placed
             BEFORE any other reference to S6, dumped the rule correctly. The
             reproducible fact is the `+=` failure (three separate files, three
             times). The dumpContents variance is recorded as an OPEN
             OBSERVATION -- do not build on it, and do not assume the first
             reference is safe.
             Says nothing about `:=`, `<-` or `+%` as graft operators; only
             `+=` was tried.
```
**This is the claim that decides whether the round is possible at all**, and it is the kind
of failure bear-trap #19's corollary exists for: the natural theory was "`WardeD` is a
grammar-file rule, not a bootstrap rule, so it cannot be grafted." That theory survives
casual narrowing and is **false** — `WardeD += DelimText2;` and `WardeD += Simple;` both
graft fine. The cause was in the ARGUMENT, never in the target, and one additive bisect
found it where an hour of reasoning about bootstrap-vs-loaded rules would not have.

### CLAIM GRAM-2 — the print SINK is chosen by the FIRST CHARACTER of the first label's TAG
```
statement:   aCTionPrinT selects its sink with a single-character test on the
             tag of the rule's FIRST LABEL. Not on the keyword the user typed,
             not on the rule name, not on a flag -- on the first byte of a
             field NAME. Any print-shaped rule whose first term is named
             something starting with lowercase 'p' goes to opPrint (stdout or
             the diverted buffer); EVERYTHING ELSE goes to opString and builds
             a value. The failure mode is SILENT: the statement parses, matches,
             consumes its text, exits 0, and produces no output on any stream.
confidence:  RUN
provenance:  Source, ruleActions.rtn:665 --
                 if command.tag == 'p'   return opPrint(input,buffer);
                 else                    return opString(command,buffer);
             with `command = input.firstInList` (ruleActions.rtn:628). What
             that compiles to, GroupRules.mm:709, is unambiguous:
                 if ( *command->groupBody->tag == 'p' )
             -- a dereference of the tag pointer, i.e. char zero. Both halves
             RUN in incant/sinkGraft, one file, EXIT=0:
               POSITIVE  a rule whose first term is `pCout="cout"` (tag pCout,
                         'p') prints, and matches `print` byte for byte.
               NEGATIVE  a rule whose first term is `cerr="cerr"` (tag cerr,
                         'c') produces NOTHING -- nothing on stdout, nothing on
                         stderr, and no diagnostic anywhere.
             The negative is a MIS-SINK and not a parse failure, and the two are
             discriminated: an unmatched keyword produces `RunRulE: expected a
             method not cout` on stderr (observed on this round's first run,
             before the graft worked). The `cerr` statement produced no such
             line, so the rule matched and the text went to opString.
asOf:        2026-07-30
scope:       Explains why the existing pair works: PrinT's first term is the
             Keywords field `print` and StringXP's is `string`. Predicts that
             ANY future print-family keyword not beginning with 'p' silently
             becomes a value-builder, and that any NON-print rule whose first
             term happens to start with 'p' would print if routed here. Neither
             prediction was tested beyond the two cases above.
             Read with kantCorpus CLAIM KANT-13 (Tony's ruling: the keyword
             selects only the sink). The ruling is right and the implementation
             agrees with it -- but it encodes the choice in a field NAME rather
             than in anything the language can see, which is why a third sink
             cannot be added without touching the fork.
```
**PROPOSAL, ROW 2, NOT BUILT — for Tony.** The fork wants to be a lookup, not a character
test. The shape that costs least and changes no existing behaviour: give the print-family
rules a `sink=` attribute (`sink=stdout` / `sink=stderr` / `sink=value`), have aCTionPrinT
read it, and keep the `'p'` test as the default when no `sink=` is present. That is a
`ruleActions.rtn` change and therefore **out of the sandbox by construction** — which is
exactly why it is written here as a proposal and not attempted.

### CLAIM GRAM-3 — `cout` IS sandbox-reachable, and its output is byte-identical to `print`
```
statement:   A new print-family statement keyword can be added to incant with
             ZERO edits to any shared file -- not incant/grammar, not
             incant/setup, not any .twk or .rtn. Define the rule in your own
             file, graft it into the live WardeD at runtime, attach the method
             in a second define. `print` is the oracle and the bytes match.
confidence:  RUN
provenance:  incant/sinkGraft, EXIT=0, 2026-07-30. The rule is PrinT
             term-for-term with one substitution:
                 CoutXP isRule pCout="cout" followedBy PRINTing-
                        stuff=PrintXP+ SemI-;
                 WardeD += CoutXP;
                 CoutXP ruleMethod=aCTionPrinT defer;      (second define)
             Oracle: six PrintXP shapes emitted once under `print` and once
             under `cout`, delimited by markers, extracted and compared --
                 "alpha" 1 2 3               plain terms + numbers
                 $"tight" _ "spaced"         the $ no-space mode and _ (KANT-11)
                 ``"backtick literal" ...    a bunched shortcut pair
                 "num" 42 " end"             interior spacing
                 ,+"bunched ..."             `,+` reaching shortcut + (KANT-14)
                 "trailing colon newline"    the : newline shortcut
                 cmp -> BYTE-IDENTICAL, 6 lines
             Regression: oneTest, jsonTest and `sh genLadder/pop.sh` (22 checks)
             all re-run after, all EXIT=0, all diff-identical to the baselines
             captured before any file was written.
asOf:        2026-07-30
scope:       ⚠ THE KEYWORD FIELD IS NAMED `pCout`, NOT `cout`, AND THAT IS NOT
             COSMETIC -- it is GRAM-2's hack, and it is the price of staying in
             the sandbox. The USER still types `cout` (the field carries the
             surface text via the `loopOnAttributes="attributes"` shape,
             incant/grammar:135). A shippable `cout` would name the field
             `cout` and fix the fork instead, which is out of sandbox.
             Demonstrated for a WardeD-level (statement) rule. Says nothing
             about grafting a Token-level alternative such as StringXP's slot.
             The new rule lands at the TAIL of WardeD, so it is tried LAST --
             not tested whether that matters for a keyword that is a prefix of
             an existing one.
```

### CLAIM GRAM-4 — `cerr` as a per-statement sink is REFUSED: there is no stderr branch to select
```
statement:   REFUSAL, and it is the round's correct output for this half.
             `cerr` cannot be added in the sandbox, because the thing it needs
             does not exist to be selected. opPrint's body is a two-way choice
             between the diverted buffer and stdout; there is no third arm.
             Adding one is an edit to Instruct.rtn, and pointing a keyword at
             it is an edit to ruleActions.rtn's fork. Both are shared files
             loaded by every fixture in the project -- row 3 of the brief's
             table, NOT sandbox work.
confidence:  RUN (for the refusal's premise) / READ (for the source shape)
provenance:  Instruct.rtn:775-787, opPrint, complete --
                 if printText
                     if toBUFFER toBUFFER += printText;
                     else        cout printText;
                 else cerr "print: recieved no print text":;
             -- two arms. The only `cerr` in it is the C++-level empty-text
             diagnostic, not a sink. Corroborated by grep: `printTO` is the
             only diversion command in incant/setup's cOMMANDs registry and it
             takes a buffer. RUN half: a rule named CerrXP, grafted exactly
             like CoutXP and identical to it in every other respect, parses and
             matches `cerr "this line asked for stderr":;` and emits nothing on
             either stream (incant/sinkGraft, EXIT=0, stderr empty).
asOf:        2026-07-30
scope:       This refuses `cerr` AS A KEYWORD SELECTING A STDERR SINK. It does
             NOT say stderr is unreachable from incant -- see GRAM-6, which is
             the same day's run and points the other way. The two are
             consistent: the bytes can be got onto fd 2 today, but not by a
             statement keyword and not without buffering.
             Confirms and does not extend kantCorpus CLAIM KANT-12.
```
**Why this is a success and not a dead round.** The refusal is *specific*: it names the two
files, the eleven lines, and the one `if` that would have to grow a third arm. That is
enough for Tony to decide in one reading, and it is more than a built-but-out-of-spec
`cerr` would have given him. The failure mode this avoids is the one the sandbox exists to
prevent — a minion editing `Instruct.rtn` because it was asked to build `cerr`, and moving
a baseline that belongs to somebody else's arc.

### CLAIM GRAM-5 — live grammar mutation is NOT bootstrap-only, and `guard()` was not needed for `WardeD`
```
statement:   The grammarOnTheFly graft mechanism works on rules defined in
             incant/grammar, not just on the 32 hard-coded bootstrap rules.
             `WardeD += <rule>;` lands. FURTHER, and unlike the DatA case: the
             `guard(WardeD)` cache reset was NOT required -- a WardeD graft
             with the guard() call removed still parses the new keyword.
confidence:  RUN
provenance:  incant/sinkProbe (WardeD 10 -> 15 -> 16 members, EXIT=0) and an
             intermediate probe in which `WardeD += DelimText2;` and
             `WardeD += Simple;` both landed, alongside the grammarOnTheFly
             control `DatA += DelimText2;` in the same run. The guard question:
             incant/sinkGuard is incant/sinkGraft with `guard(WardeD);` deleted
             and NOTHING else changed -- `cout without guard(WardeD)` printed,
             EXIT=0.
asOf:        2026-07-30
scope:       ⚠ DO NOT GENERALISE THE GUARD HALF, AND KEEP CALLING guard()
             ANYWAY -- it is free. grammarOnTheFly's finding that guard(DatA)
             is MANDATORY stands unchallenged; this round did not re-test it
             and has no mechanism to offer for the asymmetry. StatemenT carries
             an explicit `guard=[{A-Za-z0-9+-;(]` (incant/grammar:82) that
             already admits 'c', which is a candidate explanation and is
             UNTESTED. Treat "guard() is optional" as a fact about ONE graft,
             not about WardeD, and certainly not about grafting.
             Also untested: whether `StatemenT += <rule>` works. The one attempt
             used a rule that GRAM-1 had already broken, so it proves nothing.
```

### CLAIM GRAM-6 — stderr IS reachable from incant TODAY, with no C++ change, via a `/dev/stderr`-backed buffer
```
statement:   `printTO(buf); print ...; printTO(null); buf modedOP
             "/dev/stderr"; closeFile(buf);` puts incant print output on fd 2.
             Ordering within the buffer is preserved. No new primitive, no
             .rtn edit, exit 0. This QUALIFIES kantCorpus CLAIM KANT-12: that
             claim is correct that `print` itself reaches only stdout or a
             buffer, but the corollary a reader will draw from it -- that
             incant cannot put bytes on stderr -- is FALSE.
confidence:  RUN
provenance:  incant/sinkStderr, EXIT=0, 2026-07-30. Three lines printed into a
             diverted buffer, buffer pointed at /dev/stderr with modedOP
             (the operator from docs/grammarOnTheFly-findings.md), flushed
             with closeFile. Streams captured separately:
                 stdout:  S1 stdout before / S3 stdout after
                 stderr:  S2a / S2b / S2c, in order
             The two `printToBuffer: diverting...` lines are the C++-level tok
             print inside printToBuffer and land on stdout, exactly as
             grammarOnTheFly-findings describes.
asOf:        2026-07-30
scope:       IT IS NOT A SINK AND MUST NOT BE SOLD AS ONE. It is buffered and
             flushed at closeFile, so interleaving with stdout is NOT preserved
             and per-statement ordering across the two streams is lost. It also
             costs three statements around the print rather than one keyword.
             So it does not make GRAM-4 wrong -- `cerr` as a statement keyword
             is still refused.
             ⚠ BUT IT IS LIVE FOR A DIFFERENT ARC, AND SOMEBODY SHOULD BE TOLD:
             KANT-12's stated consequence is that "a kant emitPlan cannot put
             its output where the ladder targets read it without either a new
             stderr primitive or moving the capture." There is a THIRD option
             and this is it. genLadder/pop.sh captures stdout and stderr
             separately, and ordering WITHIN stderr is preserved, which is the
             only ordering those targets depend on. Not tested against an
             actual ladder target -- that is the next probe, and it belongs to
             whoever owns genParse, not to this corpus.
             Untested: whether a second closeFile appends or truncates, and
             whether /dev/stderr survives being opened when fd 2 is a file
             rather than a pipe.
```

### CLAIM GRAM-7 — `cout` and `cerr` are FREE at the incant level and heavily taken at the tok level
```
statement:   Neither `cout` nor `cerr` exists as an incant field, rule, keyword
             or registry entry anywhere in the loaded incant sources. Both are
             extremely common at the tok/C++ level -- `cerr` alone appears in
             60+ files, including 112 times in genParse.rtn. Those two facts
             DO NOT INTERACT for this round's work, because nothing here is
             written in tok, but they would the moment a `cout`/`cerr` keyword
             is promoted into a .twk or .rtn.
confidence:  RUN (the greps) / REASONED (the non-interaction)
provenance:  grep over incant/setup, incant/utilities, incant/unitTests,
             incant/grammar, incant/directives for `cout|cerr` -- ZERO hits.
             grep over incant/ -- one hit, a prose comment in incant/genEmit.
             Registry check: the Keywords registry (incant/setup:192) holds
             break/code/continue/debug/define/do/else/for/if/new/next/or/print/
             return/scope/search/string/this/while -- no cout, no cerr.
             Against the tree: `grep -rc cerr` returns 112 in genParse.rtn, 29
             in Instruct.rtn, 28 in GroupActions.rtn, and non-zero in ~60 more.
asOf:        2026-07-30
scope:       Done BEFORE defining anything, per the brief's name-collision
             prophylactic and the `debug`-rule scar it comes from. The
             REASONED half is the part to check: the tok-level uses are a
             print-target KEYWORD in tok's own grammar, and bear-traps #12 and
             #17 are about tok-level and linker-level collisions that no single
             parse pass can see. This round never wrote tok, so it never
             exposed itself to either. ⚠ A FUTURE ROUND THAT PROMOTES cout/cerr
             INTO A .twk OR .rtn IS IN A DIFFERENT AND MUCH MORE DANGEROUS
             POSITION, and should re-read #12 and #17 before touching a line.
             Specifically unchecked: whether `cout`/`cerr` appear in
             ~/data/support/Include/OCframe, the cross-project TAWK alias table
             bear-trap #17 names. That file is outside the repo and was not in
             this round's search space.
```

---

## PROPOSALS — written up, deliberately NOT built

### PROPOSAL GRAM-P1 — replace the `'p'` character test with a `sink=` attribute
Row 2 of the brief's table: genuinely novel, no oracle, so it stays a proposal. Detail is in
GRAM-2's addendum. One sentence of design: `sink=` is an ordinary rule attribute, so it
costs nothing at parse time and it makes the sink a thing the language can *see* — which is
the actual defect GRAM-2 documents, more than the hack that works around it. It also makes
Tony's ruling (KANT-13: "the keyword selects only the sink") true *in the implementation*
rather than only in the design.

### PROPOSAL GRAM-P2 — a `cerr` sink is three lines, once somebody owns the fork
Given GRAM-P1 or any equivalent, opPrint grows one arm. It is small precisely because
KANT-13 is right: `PrintXP+` is already fixed and shared, so nothing about spacing,
shortcuts, formats or parsing has to be touched. **Do not bundle these** — GRAM-P1 changes
how a sink is chosen and GRAM-P2 adds one, and landing them together makes a bisect
impossible if the bytes move.

---

## OPEN ITEMS — the challenge queue

1. **GRAM-1's order-dependence.** `dumpContents(S6)` dumped the rule when it was the first
   reference and dumped `trueResult` when it was the second. Unexplained. Recorded as an
   observation, not a mechanism.
2. **GRAM-5's guard asymmetry.** `guard(DatA)` is mandatory; `guard(WardeD)` was not needed.
   The `StatemenT guard=` candidate explanation is untested.
3. **GRAM-6 against a real ladder target.** The stderr route works; nobody has pointed a
   kant emitter at it.
4. **`StatemenT += <rule>`.** Never validly tested — the one attempt was poisoned by GRAM-1.
5. **Tail-of-WardeD ordering.** A grafted rule is tried last. Untested whether a keyword
   that is a prefix of an existing one is shadowed.
6. **OCframe.** Not searched for `cout`/`cerr`; outside the repo (bear-trap #17).

---

## RELATED, AND NOT PART OF THIS CORPUS

- **`docs/kantCorpus.md`** — minion A's corpus. **Input, not corpus, and NOT writable from
  here.** KANT-11 through KANT-15 were this round's intake; GRAM-6 qualifies KANT-12 and
  GRAM-2 corroborates KANT-13's mechanism while showing how it is actually implemented.
- **`CLAUDE.md` bear traps** — best-evidenced claims in the tree; they carry real error
  output. Bear-trap #19's corollary earned its keep twice this round (GRAM-1).
- **`docs/grammarOnTheFly-findings.md`** — the graft mechanism this round reused. GRAM-5
  extends its reach; nothing in it was contradicted.
