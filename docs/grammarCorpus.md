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
DEMOTED:     2026-07-30, Tony (SEQ 33). ⚠ THE FACTS ABOVE ALL STAND AND ARE
             RUN. What is withdrawn is an inference that WAS NOT IN THIS CLAIM
             AND WAS ADDED IN RELAY BY FOREMAN: "Tony's KANT-13 ruling is right
             in design but NOT EXPRESSIBLE in the implementation."
             THAT IS FALSE. `command.tag == 'p'` is simply an ABBREVIATION for
             `command.tag eq "print"` that got away with one character because
             two arms was all it ever had to discriminate. Widen the test to
             name the keyword and the constraint evaporates entirely. VERIFIED
             by foreman against source, 2026-07-30: `eq` string comparison is
             available and already used twice in the SAME FILE
             (ruleActions.rtn:349 `op.tag eq "="`, :907 `UnaryOPS.tag eq "-"`).
             ⇒ CONSEQUENCE FOR ANYONE ACTING ON THIS: do NOT write a mitigating
             comment warning that a print keyword must begin with 'p', and do
             NOT preserve `pCout`'s name as load-bearing. REMOVE THE FRAGILITY.
             pCout's load-bearing-ness dies with the fix, and a comment
             documenting a hazard that is being deleted is worse than nothing --
             it teaches the next reader to design around something gone.
```

> ### ⚠ THE PROPAGATION, LOGGED — three readers, one unchecked tree claim
>
> Worth more than the correction itself, and it is the day's pattern one level up.
>
> | who | what they did | what they did not do |
> |---|---|---|
> | the minion | read `opPrint`'s two arms correctly, inferred a structural bar | — |
> | foreman | verified the *reading*, then carried the inference further to "not expressible" | never re-derived the `'p'` test's **meaning** from source |
> | Clay | checked the inference against the reading | never checked the reading against the tree |
>
> **Nobody re-derived the test from source. Everybody re-derived it from the previous
> reader.** It took Tony opening the file. This is worse than an ordinary bad tree claim,
> because each of the three had grounds to believe someone else had checked — verification
> was *performed at every step* and still never touched the tree at the one point that
> mattered.
>
> **The tell, and it generalises:** when a claim passes through readers, ask what each one
> actually re-derived. "I verified X" and "I verified someone's reading of X" are different
> acts and read identically in a report. Related to bear-trap #19's corollary but distinct:
> there the search space was wrong; here the *chain* was intact and the *ground* was never
> touched.
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
> ⚠⚠ **SUPERSEDED 2026-08-01 — THE REFUSAL WAS CORRECT AND HAS BEEN ACTED ON. `cerr` IS NOW
> NATIVE, AND SO IS `cout`.** Do not re-derive this refusal; the thing it said did not exist
> now exists. Rule `CerR`/`CouT` (`incant/grammar`), actions `aCTionCerR`/`aCTionCouT`
> (`ruleActions.rtn`), sinks `opCerr`/`opCout` (`Instruct.rtn`).
>
> **The claim is left standing verbatim below because it was RIGHT, and right in the way that
> mattered:** it refused to edit shared files from inside a sandbox and instead named the exact
> edit — two files, eleven lines, one `if` that needed a third arm. The foreman made that edit,
> and the refusal is what made it a ten-minute job. This is the model for a minion refusal.
>
> **One correction to its reasoning, found while acting on it:** the fix was NOT a third arm in
> `opPrint`. It is a SIBLING rule with its own action and its own sink op — Tony's own
> `aCTionStringXP` precedent. That matters because it means `sink=`/GRAM-P1 was never a
> prerequisite: a sibling needs no discriminator. GRAM-P1 remains open and remains Tony's, but
> it is no longer blocking anything.
>
> Fixtures: `incant/sinkT` (all three sinks under an ARMED diversion — the only condition that
> tells them apart), `incant/cerrT`, and `genLadder/printPop.sh`, now 9/9 green.
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

---

## ROUND 2 — 2026-07-30. Task: the POP for the print-family C++ change (BEFORE the change)

**Verdict, up front:** the fixture is built, it runs, it goes red for the right reasons, and
**the load-bearing row is RED today and cannot be made green by anything in the sandbox** —
which is the round's most useful single fact, because it means the row was never covered and
round 1's green `cout` did not cover it.

| | verdict | one-line evidence |
|---|---|---|
| **stable half** (`print`, `string`) | **GREEN, byte-exact, 2 targets** | `incant/printFamily`; must stay green through the change — it is the regression net |
| **moving half** (`cout`, `cerr`, omitted `string`) | **RED on purpose, pinned** | `incant/printFamilyNew`; targets are `.divergence` files, `iterT1m` shape |
| **`cout` under an ARMED diversion** | **WRONG TODAY, and unfixable in the sandbox** | grafted `cout` IS `print`, so the diversion swallows it — GRAM-10 |
| **native-vs-graft transition** | **SOLVED, and the fixture needs no edit to survive it** | an earlier `WardeD` alternative wins, so a tail graft goes inert — GRAM-11 |

**Files this round produced, all new, none shared. `genLadder/pop.sh` was NOT touched.**

| file | what it is |
|---|---|
| `incant/printFamily` | stable half — `print`/`string` × diversion × `$` × `_`. No graft. |
| `incant/printFamilyNew` | moving half — `cout`/`cerr` × same matrix, + omitted `string`. Pinned wrong. |
| `genLadder/printFamily.target` | stdout, byte-exact, green now and after |
| `genLadder/printFamily.captured` | stderr — the diverted buffer, flushed |
| `genLadder/printFamilyNew.divergence` | stdout, **wrong answer, pinned** |
| `genLadder/printFamilyNew.err.divergence` | stderr, **wrong answer, pinned** |
| `genLadder/printPop.sh` | the runner. `sh genLadder/printPop.sh` → 9 checks, exit 0. |

**Regression net, before and after, all byte-identical:**

```
$BINARY incant/oneTest    EXIT=0   diff vs baseline: identical
$BINARY incant/jsonTest   EXIT=0   diff vs baseline: identical
sh genLadder/pop.sh       EXIT=0   diff vs baseline: identical  (22 ok, POP PASSED)
sh genLadder/printPop.sh  EXIT=0   9 ok   (new)
```

**The POP was negative-controlled three ways, because a check that cannot go red is worth
nothing.** (1) perturbing the stable target → RED, exit 1. (2) deleting the `PN-C-A-*` rows
from the stderr divergence — *which is exactly the diff Tony's change will produce* → RED,
exit 1, and the diff printed is the acceptance criterion in bytes. (3) injecting a truncating
row → the sentinel check RED **while `printFamily runs` still reported `ok`**. That third one
is CLAUDE.md's "exited 0 is not passed" doctrine demonstrated live inside the instrument.

---

### ⚠ TWO THINGS THIS CORPUS SHOULD HAVE CARRIED AND DID NOT

Per the brief: needing something the corpus should have had **is the finding**. Both are the
GRAM-2 propagation pattern again — *a true RUN claim whose most consequential reading was
never taken* — and neither is round 1 being careless. Round 1 had the evidence on screen.

1. **GRAM-2's provenance quotes `RunRulE: expected a method not cout` and uses it only as a
   discriminator** between a mis-sink and a parse failure. That is correct and it is not the
   dangerous half. The dangerous half is that this diagnostic **abandons the rest of the file
   and still exits 0** (GRAM-8). Round 1 printed the line, reasoned about it correctly for its
   own purpose, and did not ask what it does to everything downstream of it.

2. **GRAM-3 proves `cout` byte-identical to `print` — and every byte of that oracle was
   captured with the diversion UNARMED.** The claim is true. The reading a reader takes from it
   — "so `cout` works" — is false, because byte-identity-with-`print` is *precisely the defect*
   for the one row that justifies `cout` existing at all (KANT-23). A stronger claim would have
   been *weaker-sounding*: "cout is print, and that is the problem." The oracle's own success
   concealed the gap.

**The general form, and it is the round's most transferable output:** when a claim's evidence
is an *equality*, ask what the equality would look like if the thing were broken. Here, broken
and correct produce the same bytes under the only condition anyone tested.

---

### CLAIM GRAM-8 — an incant parse failure ABANDONS THE REST OF THE FILE and STILL EXITS 0
```
statement:   A statement whose keyword does not match any rule emits
             `RunRulE: expected a method not <tok>` on stderr and TERMINATES
             THE RUN AT THAT POINT. Every statement after it is silently not
             executed. THE PROCESS EXITS 0. There is no `stop: ending input
             divert` line, and buffered stdout written before the failure is
             still flushed -- so the capture looks like a complete, correct,
             successful run that happens to be short.
confidence:  RUN
provenance:  Two runs, 2026-07-30. (a) A three-line file
                 print "P1a"; / cout "P1b"; / print "P1c";
             with `cout` UNGRAFTED: stdout carried P1a only, P1c absent, no
             `stop:` line, stderr carried exactly the one RunRulE line,
             EXIT=0. (b) The negative control on this round's own POP: a
             truncating row injected into incant/printFamily before its
             sentinel produced `ok  printFamily runs` (exit 0) alongside
             `FAIL printFamily sentinel`. Same run, both true.
asOf:        2026-07-30
scope:       THIS IS THE REASON BOTH ROUND-2 FIXTURES END IN A NAMED SENTINEL
             LINE, and any fixture that uses a keyword which might not parse
             needs one. A byte-exact diff DOES catch the truncation, but it
             blames the first missing row rather than the row that stopped
             parsing, which sends the reader to the wrong place.
             Instrument-level instance of CLAUDE.md's Testing doctrine, and
             the same family as the genScratch/SIGSEGV case -- except this one
             is worse, because 139 is at least visible and this is a literal 0.
             ⚠ CONSEQUENCE FOR ANY FUTURE ROUND WRITING A FIXTURE IN THE
             LANGUAGE AS SPECIFIED RATHER THAN AS IMPLEMENTED: you cannot.
             One not-yet-existing keyword deletes everything below it. That is
             why round 2's matrix is SPLIT rather than written once against
             Tony's four-keyword table.
             Untested: whether every parse failure behaves this way, or only
             an unmatched leading keyword. Only the RunRulE shape was run.
```

### CLAIM GRAM-9 — a buffer flushed to `/dev/stdout` lands at the TOP of the capture; flush to `/dev/stderr`
```
statement:   GRAM-6's `buf modedOP "/dev/stdout"; closeFile(buf);` route works
             but SCRAMBLES ORDER catastrophically: the flush is an unbuffered
             write while incant `print` goes through block-buffered tok `cout`,
             so the ENTIRE flushed buffer appears BEFORE every line that
             logically preceded it -- including lines printed before the
             diversion was ever armed. /dev/stderr does not have this problem
             because both paths are unbuffered, so stderr carries true event
             order.
confidence:  RUN
provenance:  One run, 2026-07-30. Six markers P4-1..P4-6; P4-2/P4-3 diverted
             into a buffer, flushed to /dev/stdout between P4-4 and P4-5.
             Captured stdout began:
                 P4-2 into buffer / P4-3 into buffer / Search list: Grokking
                 / P4-1 stdout before / ... / P4-4 ... / P4-5 ... / P4-6
             -- the flush ahead of even the `Search list:` banner. EXIT=0.
             Contrast: the same shape flushed to /dev/stderr, captured
             separately, is in order (incant/printFamily, this round, and
             incant/sinkStderr, round 1).
asOf:        2026-07-30
scope:       SETTLES HALF OF kantCorpus KANT-12's UPDATE, which recorded
             "ORDERING ACROSS THE FLUSH" as not settled and named
             flush-per-invocation as the obvious untested fix. For
             /dev/stdout it is now settled and it is WRONG -- not subtly
             mistimed, inverted. For /dev/stderr, with the two streams
             captured SEPARATELY, order holds.
             ⚠ SAYS NOTHING ABOUT KANT-12's ACTUAL QUESTION, which is
             ordering between a kant emitter's buffered output and a C++
             caller's already-written stderr line. Both on fd 2 is a
             DIFFERENT configuration from the one measured here and the
             flush-at-close hazard is still live there.
             Also unmeasured: flush-per-invocation, still the obvious fix.
             Spelling note, cost a minute: the command is `printTO` (capital
             TO), incant/setup:53. `printTo` appears in briefs and prose and
             is not the surface spelling.
```

### CLAIM GRAM-10 — ⚠ THE LOAD-BEARING ROW: grafted `cout` IS DIVERTIBLE, so the sandbox CANNOT demonstrate the case that justifies the change
```
statement:   With a `printTO` diversion armed, round 1's grafted `cout` goes
             INTO THE BUFFER, exactly like `print`, and reaches no terminal.
             This is not a defect in the graft -- it is the graft working. The
             graft routes to aCTionPrinT, whose 'p' arm is opPrint, whose FIRST
             ACT is `if toBUFFER`. Grafted `cout` is `print` wearing a
             different keyword, and DIVERTIBILITY IS EXACTLY THE PROPERTY
             `cout` MUST NOT HAVE (kantCorpus KANT-23). Therefore NO runtime
             graft, however written, can make this row green: reaching the
             stdout arm past the diversion check is a change to opPrint's body,
             which is Instruct.rtn and out of sandbox by construction.
confidence:  RUN
provenance:  Two runs, 2026-07-30. Probe: graft CoutXP exactly per GRAM-3,
             then
                 print "P2-1"; cout "P2-2";        (unarmed -- BOTH visible)
                 printTO(capBuf);
                 print "P2-3"; cout "P2-4";        (armed -- NEITHER visible)
                 printTO(null); print "P2-5";      (visible again)
             EXIT=0, sentinel reached. P2-4 is the row. Restated in the
             shipped fixture: incant/printFamilyNew section 3, whose stderr
             flush (genLadder/printFamilyNew.err.divergence) reads
                 PN-P-A-def ...    <- print, CORRECTLY captured
                 PN-C-A-def ...    <- cout, WRONGLY captured
                 PN-C-A-dol...     <- cout, WRONGLY captured
                 PN-C-A-und ...    <- cout, WRONGLY captured
             Mechanism READ and unambiguous: Instruct.rtn:775-787, opPrint --
                 if toBUFFER  toBUFFER += printText;
                 else         cout printText;
             with toBUFFER set by printToBuffer (Commands.rtn:444).
asOf:        2026-07-30
scope:       ⚠ THIS QUALIFIES GRAM-3 AND IS THE MOST IMPORTANT THING IN THIS
             CORPUS FOR ANYONE READING IT AS "cout IS DONE". GRAM-3 is RUN and
             true -- its six-shape oracle really is byte-identical. But every
             byte of it was captured with the diversion UNARMED, and under an
             armed diversion the two keywords must DIFFER. So the oracle that
             proved the graft correct is measuring the one condition under
             which correct and broken are indistinguishable.
             THE ACCEPTANCE TEST for Tony's change is exactly this row moving:
             the three PN-C-A-* lines must leave the stderr flush and appear on
             STDOUT between the ARMING and RELEASED markers, while PN-P-A-def
             stays in the flush ALONE. Both halves must move together -- if
             only the cout half moves, the diversion gate was widened rather
             than bypassed, and `print` stopped being divertible too.
             Says nothing about `cerr` under a diversion; that row is pinned in
             the same file but is silent today for the unrelated GRAM-2 reason
             (mis-sink to opString), so it is not evidence about divertibility.
```

### CLAIM GRAM-11 — an EARLIER `WardeD` alternative WINS, so a tail graft goes inert when the native rule lands
```
statement:   `WardeD += <rule>` appends at the TAIL, and when two WardeD
             alternatives match the same keyword THE EARLIER ONE WINS. A rule
             grafted at runtime is therefore SHADOWED by any rule already in
             WardeD -- including every rule defined in incant/grammar.
             CONSEQUENCE, and it is the answer to the native-vs-graft
             transition: once `cout`/`cerr` are native they sit inside WardeD
             ahead of any graft, THE NATIVE RULES ANSWER, and a leftover graft
             is inert dead weight rather than a collision or a shadow.
confidence:  RUN
provenance:  One run, 2026-07-30, discriminating by SINK rather than by text.
             Graft CoutA with label `pCout` (tag 'p' -> opPrint -> VISIBLE).
             Then graft CoutB, same keyword "cout", label `cout` (tag 'c' ->
             opString -> SILENT, per GRAM-2). Both in WardeD, CoutB later.
             `cout "P3-5";` printed VISIBLY => CoutA, the EARLIER rule, won.
             Same run also re-confirmed GRAM-2's negative: `cerr` with a 'c'
             label emitted nothing on either stream. EXIT=0, sentinel reached.
asOf:        2026-07-30
scope:       ⚠ THE INERTNESS IS ABOUT MATCHING, NOT ABOUT DEFINING. A graft
             whose RULE NAME collides with the native rule's is a different and
             worse problem: `define CoutXP ...` would RE-OPEN the native rule
             rather than create a new one, and could clobber its ruleMethod.
             That is why incant/printFamilyNew names its rules `PfCoutGraft`
             and `PfCerrGraft`. Anyone grafting a rule that may later go native
             must pick a name the native one will not take.
             Settles round 1's OPEN ITEM 5 ("tail-of-WardeD ordering:
             untested whether a keyword that is a prefix of an existing one is
             shadowed") for the EXACT-DUPLICATE case. The PREFIX case -- a
             grafted keyword that is a prefix of an existing one -- is still
             untested; only identical keywords were run.
             Untested: whether the same precedence holds for `StatemenT` or
             `DatA` (round 1's OPEN ITEM 4 is still open).
```

### CLAIM GRAM-12 — the OMITTED `string` form is not the spelled form today: one term differs, two terms is GARBAGE, shortcuts do not parse
```
statement:   kantCorpus KANT-13's table closes the family at four and
             parenthesises `string (and its omitted form)`; KANT-15 rules that
             an omitted keyword MUST NOT change semantics. MEASURED, today it
             is neither of those things:
               ONE term    `x = "a";`            -> "a"      (spelled gives
                                                  "a " -- a TRAILING SPACE the
                                                  omitted form lacks)
               TWO terms   `x = "a" "b";`        -> GARBAGE. Not mis-spaced,
                                                  not truncated: the token
                                                  `xlInSet` plus a newline,
                                                  and `xlInSet` appears
                                                  NOWHERE in the tree. An
                                                  uninitialised read.
               SHORTCUTS   `x = $"a" _ "b";`     -> DOES NOT PARSE. RunRulE,
                                                  and it abandons the rest of
                                                  the file at exit 0 (GRAM-8).
             The omitted form is not a print-family form at all today; it is
             plain assignment, which happens to work for one token.
confidence:  RUN
provenance:  Two runs, 2026-07-30, EXIT=0. Controls in the SAME run:
                 o3 = string "alpha";        -> "alpha "   CORRECT
                 o4 = string "alpha" "beta"; -> "alpha beta " CORRECT
                 o1 = "alpha";               -> "alpha"    no trailing space
                 o2 = "alpha" "beta";        -> "xlInSet\n"
             so the spelled path is healthy in the same process that produces
             the garbage. `grep -rn xlInSet` over the repo: ZERO hits.
             Pinned in genLadder/printFamilyNew.divergence, section 6.
asOf:        2026-07-30
scope:       ⚠ REPORTED AS A FINDING, NOT FIXED -- it is a C++-level defect on
             a path nobody asked this round to touch, and the fix is out of
             sandbox. But it is load-bearing on Tony's design: KANT-15 is the
             LEAST RECOVERABLE claim in the kant corpus and this is the first
             MEASUREMENT against it, and the measurement disagrees. If the
             omitted form is to be a real member of the closed family, this is
             work, not documentation.
             The two-term garbage is the part to take seriously: an
             uninitialised read is a live bug independent of the print family
             and could equally be reached from elsewhere. NOT NARROWED --
             which shape of expression triggers it, and whether three terms
             behave like two, were not run.
             The shortcut row is deliberately ABSENT from the fixture: it
             truncates, and a truncating row before a sentinel deletes the
             sentinel. It lives here instead.
```

### CLAIM GRAM-13 — `print` and `cout` are BYTE-IDENTICAL across the spacing modes, and this must survive the change
```
statement:   Fed character-identical PrintXP, `print` and `cout` emit
             character-identical bytes in all three spacing modes (default,
             `$`, `$` with `_`). ONE mechanism, the keyword selecting only the
             sink -- kantCorpus KANT-13, confirmed by run rather than by read.
confidence:  RUN
provenance:  genLadder/printPop.sh's last check, 2026-07-30: the `PF-P-U-*`
             rows from incant/printFamily and the `PN-C-U-*` rows from
             incant/printFamilyNew, row-name normalised away, `diff` clean --
                 ROW-def 1 2 3 / ROW-doljoined / ROW-und spaced
             Independently corroborates round 1's GRAM-3 oracle (six shapes,
             same result) with a different set of shapes and a different file.
asOf:        2026-07-30
scope:       ⚠ IT IS A CHECK THAT SPANS THE CHANGE, WHICH IS WHY IT IS WORTH
             HAVING: today the `cout` side is a runtime graft, afterwards it is
             the native rule, and the bytes must not move either time. If it
             ever differs, a PER-DESTINATION SPACING DEFAULT has crept in --
             the exact thing KANT-13's COMPLETED block records Tony CUTTING
             from the design, and the first crack "one mechanism" would show.
             It is the only check in the print POP that is meaningful on BOTH
             sides of the transition; every other check is either stable-only
             or pinned-wrong.
             Covers three spacing modes, not the shortcut family -- GRAM-3's
             oracle covers backticks, `,+` and the `:` newline, and the two
             claims should be read together rather than either alone.
```

### CLAIM GRAM-14 — classify a task by WHAT IT MUST TOUCH, not by what it RESEMBLES
```
statement:   The rule that mis-classified round 1 was "parallels an existing
             rule => sandbox-safe". It put `cout` and `cerr` in the same row
             because they look identical in the grammar -- same PrintXP, same
             action, one keyword apart -- and they are NOT in the same row:
             `cout` is a new SPELLING of an existing behaviour, `cerr` is a new
             BEHAVIOUR. The corrected rule: ask WHAT ARM OF WHAT FORK THE
             OUTPUT HAS TO LEAVE BY, and check that arm EXISTS, before
             accepting. Surface resemblance predicts the PARSE side and says
             nothing about the ACTION side, and the action side is where the
             sandbox boundary runs.
confidence:  REASONED
provenance:  Round 1's own misprediction, and it cost real work. Applied
             forward this round it is CHEAP AND IT PAID: `cout` under an armed
             diversion looks like row 1 (it is `print` with a different
             keyword) and is actually row 3, because the arm it must leave by
             is the `else` of `if toBUFFER` inside opPrint -- reachable only by
             editing Instruct.rtn. ONE GREP of opPrint's body answers it. That
             is GRAM-10, and finding it BEFORE building rather than after is
             the difference between a fixture and a wasted round.
asOf:        2026-07-30
scope:       REASONED, NOT RUN, and it is a heuristic about process rather than
             a fact about the tree -- do not treat it as evidence for anything.
             One corroborating instance and one avoided failure is thin.
             It is bear-trap #19's corollary aimed at INTAKE rather than at
             debugging: there, a hypothesis survives narrowing because the
             search space was wrong; here, a task looks safe because the
             classification looked at the grammar and the boundary was in the
             .rtn. Both are "you searched the wrong file", moved one step
             earlier.
```

---

## ROUND 2 — DESIGN DECISION, WRITTEN DOWN BECAUSE THE BRIEF ASKED FOR IT

**How the fixture survives `cout` going from graft to native — and why it is SPLIT IN TWO.**

The obvious single-file design fails, and it fails for a measured reason rather than an
aesthetic one. A fixture written against the language *as specified* cannot run today at all:
the first `cout` truncates it and takes the whole matrix with it, at exit 0 (GRAM-8). A
fixture written against the language *as implemented* needs the graft, and the graft is
`print` — so it can never exercise the one row that justifies the change (GRAM-10).

So the matrix is split by **whether a row is expected to move**:

- **`incant/printFamily` — the rows that must NOT move.** `print` and `string` only. No graft,
  no keyword that does not exist, therefore no before-state and no after-state. **The half
  that most needs to survive survives by not participating.** It is a pure regression net
  around the fork being widened: if broadening sink selection disturbs `print`'s diversion,
  `string`'s value path, or any spacing mode, this goes red and names the row.
- **`incant/printFamilyNew` — the rows that MUST move.** `cout`, `cerr`, omitted `string`.
  Targets are `.divergence` files on the `iterT1m` / `tree.divergence` pattern: today's wrong
  answer, asserted UNCHANGED, with each section header stating in bytes what it must become.
  It carries the graft **solely as a parse-enabler** so the file reaches its sentinel — never
  as the thing under test.

**And the transition needs no edit to either file**, because GRAM-11 measured that an earlier
`WardeD` alternative wins: when the native rules land they shadow the graft, the native
implementation answers, and the divergence files flip *because the implementation changed*.
The graft should still be **deleted in the flipping commit** — it is inert, not
harmless-forever, and it names `pCout`, which GRAM-2's DEMOTED block says must not survive the
fix or be designed around.

**What would have to be true for one file to work:** either (a) incant grows a way to ask
whether a keyword parses without dying — a conditional graft — or (b) a parse failure stops
being fatal-and-silent (GRAM-8). Neither exists, and (b) is the more valuable of the two well
beyond this fixture.

---

## OPEN ITEMS ADDED BY ROUND 2

7. **The `xlInSet` uninitialised read** (GRAM-12). A live bug, not narrowed, reachable from a
   two-term bare assignment. Nobody has asked whether it is reachable from elsewhere.
8. **`cerr` under a diversion is pinned but not evidenced** (GRAM-10 scope). It is silent today
   for the GRAM-2 mis-sink reason, so the fixture pins it without proving anything about
   divertibility. Only the change itself can settle it.
9. **Flush-per-invocation** (GRAM-9). Still the obvious fix for KANT-12's real ordering
   question and still unmeasured. GRAM-9 settled only the /dev/stdout half.
10. **The PREFIX case of `WardeD` precedence** (GRAM-11). Exact duplicates are settled; a
    grafted keyword that is a PREFIX of an existing one is not.
11. **Whether every incant parse failure truncates** (GRAM-8), or only an unmatched leading
    keyword. Only the `RunRulE` shape was run.

---

## ROUND 3 INTAKE — 2026-07-31, from the `#` string-expression change (foreman, not a round)

*Two claims and one proposal, landed while replacing the `string` keyword. Recorded here
rather than in a round's section because no grammar-minion round ran — this is intake.*

### CLAIM GRAM-13 — `,` COULD NOT BE THE STRING-EXPRESSION OPENER, and the reason is the shortcut set
```
statement:   `,` is ALREADY a member of the print shortcut character set --
             `ShortcuT=[-+~`$_:,]+` (incant/grammar:92) -- and the `+` means
             adjacent shortcut characters MERGE INTO ONE TOKEN. So `,` in a
             print had two readings once StringXP opened on it, and the
             collision was not theoretical: `print "it is", maximus + 3,
             "done":;` -- LIVE at incant/unitTests:113 -- produced a garbage
             operand and SEGFAULTED. `#` is NOT in the shortcut set, so it
             cannot be absorbed into a merged run and has exactly one reading
             in Token position.
confidence:  RUN
provenance:  incant/commaProbe (since folded into incant/hashProbe), 2026-07-31.
             Row A (`,` between two literals) survived; row B (`,` then
             arithmetic) gave `ERROR Operator + failed on maximus and xl` then
             SIGSEGV. Crash chain: appendGroup <- aCTionStringXP <- printField
             <- appendGroup <- aCTionPrinT -- a nested StringXP inside a print
             whose operand evaluated NULL, handed to an appendGroup with no
             null guard.
scope:       The crash is reachable only via incant/baselineTests, which is in
             NO pop script -- all three POPs stayed green while it crashed.
             That coverage hole is now a smoke check in pop.sh.
```

### CLAIM GRAM-14 — the FormaT rule DOES NOT FIRE (Fearless, parked HPDL)
```
statement:   FormaT (`FormaT="#" flags=[-# 0+']* ... tokenize;`,
             incant/grammar:102) does not bind. `print x #5d` prints `11 5 d`
             -- the format spec passes through as ORDINARY PRINT ITEMS.
confidence:  MEASURED -- and measured as a CONTROLLED COMPARISON, which is the
             load-bearing part: the same row was run under the `,` grammar and
             under the `#` grammar and printed `11 5 d` UNDER BOTH. So this is
             PRE-EXISTING and is NOT a consequence of `#` becoming the StringXP
             opener.
provenance:  incant/fmtProbe, run under both grammars, 2026-07-31.
history:     worked previously; unused recently; BREAK POINT UNKNOWN.
note:        ⚠ WHEN FIXED, THE LEAD CHARACTER SHOULD BE `%`, NOT `#`. `#` is now
             owned by the StringXP gate, and `%` carries printf symmetry.
status:      PARKED, HPDL. Tony's.
consequence: this is the one real cost of choosing `#`. It shadows FormaT's
             opener -- but it shadows something that does not currently work,
             so the cost is to the FUTURE fix, not to today. Whoever repairs
             FormaT cannot use `#` while StringXP owns it, which is why the
             `%` note above is part of the claim rather than a suggestion.
```

### PROPOSAL GRAM-P1 — STATUS CHANGED, and it is now the ONLY candidate
`GRAM-P1` proposed replacing the `'p'` first-character sink test with a `sink=` attribute.
**THE `'p'` TEST NO LONGER EXISTS.** `aCTionPrinT`'s two-arm dispatch was removed on
2026-07-31 when `string` moved out to its own rule with its own action, so aCTionPrinT ends
`return opPrint(input,buffer);` unconditionally. Consequences:
- `cerr` stopped being routed to opString-and-discarded and now **prints on stdout** —
  still wrong, wrong in a smaller way. `printFamilyNew`'s divergence files were re-pinned,
  exactly six lines, all `cerr`.
- **`sink=` is no longer an improvement on a hack; it is the only thing that can tell the
  three stream keywords apart.** That raises its priority and does not change its design.
- **Clay approved it 2026-07-31.** ⚠ Not built: the define-time half is cheap
  (`sink immediateAction=setSink noPrint;`, the same load-bearing `noPrint` `parseMethod=`
  needed), but the RUN-time half is open — `aCTionPrinT` receives the parsed INSTANCE, and
  `definingRule()` cannot reach the rule from one (it walks to the first child's parent, and
  an instance OWNS its children, so it routes back to itself). Two candidates, one a
  RuleStuff layout change, one a name lookup that reproduces GRAM-2's defect a layer up.
  Parked in `ipc/clod-to-clay.md` SEQ 36 pending a measurement probe.
