# fixIts — the capture queue

**Created 2026-08-16, Tony's call.** *"Measurement generates these, but then we stop what we are
doing when it makes more sense to stash them on a fixit list and maybe sic a minion at it."*

## WHY THIS FILE EXISTS, AND WHY THE OTHER TWO DID NOT COVER IT

| file | what it is | why a fixit does not fit |
|---|---|---|
| `docs/knownErrors.md` | the **deep-defect register** — KE-1..KE-6, long-form, each with measurement, discrimination and a ruling owed | too heavy. A KE entry is an investigation; most fixits are two lines and a file reference |
| `TODO.md` | the **roadmap** — 699 lines organised by arc and phase | organised by *design intent*, not by *what is broken now*. A fixit has no arc |
| commit messages | where fixits have actually been living | ⚠ **unreadable as a queue.** A finding in a commit message is recorded and simultaneously lost |

**THE RULE THIS FILE ENCODES: CAPTURE, DO NOT CHASE.** A measurement taken for one purpose
routinely turns up a defect belonging to another. Stopping to fix it derails the task that found
it; mentioning it in prose loses it. **It comes here, with enough evidence that nobody has to
re-derive it, and the finder goes back to what they were doing.**

**A ROW IS MINION-READY OR IT IS NOT A ROW.** Every entry carries: what is wrong, WHERE (file:line),
the EVIDENCE that it is real, and what "done" means. If a row cannot be handed to someone with no
context, it is not finished being written.

**Status vocabulary:** `open` · `parked <by whom>` · `closed <how>`. A closed row stays for one
cycle so the trail survives, then moves out.

---

## OPEN

### F-4 — `docs/gui.md` cites files a fresh clone no longer receives
**Where:** `docs/gui.md:729` and `:818`, citing `Aside/WithJIT/ParseXML.rtn` as the verified
track-builder to "bring in before porting". Also `docs/plg-*-recon-2026-05-29.md` citing
`Aside/BeforeSimple/ParseXML.*`.
**What:** `Aside/` and `BackupIncant/` were ignored and untracked 2026-08-16 (`b1482ff`, `2364b05`).
Files remain on disk here and in history everywhere, but not in a bare clone's working tree.
**Done when:** those citations say how to recover the file
(`git show <ref>:Aside/WithJIT/ParseXML.rtn`) instead of naming a path.
**Owner:** unassigned. **Size:** doc edit, three references. **Good minion candidate.**

### F-6 — the correction owed to commit `6212a71` (folds into the next landing)
**Where:** the message of `6212a71`.
**What:** it flags `Generate.rtn`'s removal of `parseRule`'s jitting gate as a running-code change.
**That is wrong.** `jitting` is raised only inside `jitRunAction`, so during parse it is false, and
`if jitting && jitRunAction(field); else result = processAction(field);` is behaviourally identical
to `result = processAction(field);`. The removal is inert in every reachable configuration.
**Done when:** recorded in a later commit message (history is pushed; the fix is a record, not a
rewrite).
**Owner:** Clod. **Size:** one paragraph.

### F-9 — census the conditional clears: which are true-conditional, which are safe only by vacancy
**Where:** tree-wide, `.rtn` and `.twk`. The pattern is `if <something> { ... clear() ... }`.
**Why:** F-1's defect was exactly this shape. `aCTionParens` cleared its node **only when an
ExpressioN was present**. That was correct for years — not because the condition was right, but
because the unclear path happened to leave an EMPTY node. The labelled-literals change put
attributes on that node, the vacancy ended, and the conditional clear became a live bug three
files away in `audit()`.
**The classification wanted, one row per site:**
  - **true-conditional** — the clear genuinely should not happen on the other path. Safe.
  - **safe-by-vacancy** — the other path is only harmless because the node happens to carry
    nothing. ⚠ **These are the live ones.** Any change that gives the node content arms them, and
    the failure surfaces somewhere else entirely.
**Model for the fix when one is found:** `aCTionBraced`, which has always cleared unconditionally
and was never exposed. The repair for `aCTionParens` was to match it — two lines.
**Done when:** every site is classified and the safe-by-vacancy ones are either made
unconditional or annotated with what keeps them vacant.
**Owner:** unassigned. **Size:** census first, then per-site. **Good minion candidate** — the
classification is mechanical once the pattern is stated.

### F-26 — what the 2026-08-19 `Generate.rtn` template audit did NOT touch, and why each one is Tony's
**Context:** Tony's finding — `parseSet` was derived from `RuleStuff`'s `testSet` and kept half of
it — generalised into a walk of every method in the file against its template. The transcription
omissions were repaired in the same pass (see the block above `parseAny`). **These five are the
residue: divergences that are real but that I cannot tell from deliberate adaptation, so nothing was
changed.** ⚠ **All READ-grade.** Nothing in this file is reachable until a walk calls `setParse`, so
none of it has been run; the template diff is the control.

**1. The rule action fires TWICE on the generated path.** `setParse` parks `actionMethod = method`;
`parseSetLabel` and `runRuleAction` each fire it. But `parse()`'s generated fork
(`GroupItem.twk:1334-1337`) then calls `fireLabelMethod(ruleStuff)`, which fires the **same**
`method` on the **same** label. Two calls, one label — and `fireLabelMethod`'s own header claims to
be *"THE RULE ACTION, and the ONLY site that fires one"*, which is false while `actionMethod`
exists. Same shape for the attach: `parseSetLabel` does `parentLabel +% label` and the fork then
calls `attachLabel`. **Either the `actionMethod` channel or the fork's two calls is the one that
should go, and that is a design call.**

**2. `setParse`'s dispatch order is not `setTestMatch`'s.** Three differences: (a) the `data` switch
is the **`else`** arm, not `or data`, so a rule with `data == 0` that reaches it is bound
`parseString`; the template's last arm is `or !contents() if !isMethod testMatch = testString;` and
**both** guards are absent. (b) `isCondition` / `parseACTION` / `groupList` are tested **before**
data, where the template tests data third — so a rule carrying data **and** one of those flags gets
a different executor from the one the interpretive path would pick. (c) no `isMacro →
setMacroValue` arm; that one is documented in the header (*"For now does not handle macros"*) and is
listed only so the set is complete.

**3. Four parse methods never call `checkInput()`** — `parseAction`, `parseCondition`, `parseRule`
(`parseUpTo` was the fourth and was repaired, because it reads the input stream directly). On the
interpretive path `parse()` called it before `testMatch`; on the generated path **nothing does**,
and `checkInput` is what mints `rStuff.label`, sets `hereAt`, runs the skip pass and evaluates the
guard. **`parseRule` is the one that matters** — every walked grammar rule binds it, and its tail
reads a `label` and a `hereAt` that nothing on that path has written. Not repaired here because
minting a label inside `parseRule` changes the generated-path contract: what `runRuleAction(this)`
hands back, and what the fork's `sukcess = label != 0` then reads.

**4. `parseRule`'s local-clear guard differs from `processAction`'s in three places.** Template
(`GroupActions.rtn:667-669`): `isLocal && !isLabel && !noPrint && groupBody != action.groupBody`,
with `action = code` set immediately above it. `parseRule`: `isLocal && !isRule && groupBody !=
field.groupBody`. So `!isLabel` became `!isRule`, `!noPrint` is gone, and the self-comparison is
against the **rule** where the template compares against the **CodE**. The template's fill-down loop
(label → locals, which is what sets `isLabel`) has no counterpart at all — and that part is almost
certainly deliberate, since `parseRule` runs at parse time when there is no label to fill down from.
**Which is exactly why the other three are listed rather than guessed at.**

**5. A `*` term matching zero occurrences FAILS on the generated path.** `testMacro`'s
`if counter && counter >= min` cannot succeed at counter 0; interpretively `parse()`'s `matchFailed`
block rescues it (`if !sukcess && kount >= min sukcess = true`). The generated fork `goto
generatedExit`s **past** that block. Restoring `testMacro`'s loop this pass inherits the gap rather
than creating it. Same family as the rung-6 repetition tripwire already noted at `GroupItem.twk:1256`.

### ⚠ THE SITES, ADDED 2026-08-20 so Tony reads rather than hunts — one line each, all re-grepped today

| # | the divergence | read here | against this template |
|---|---|---|---|
| 1 | rule action fires twice | `Generate.rtn:351` parks `actionMethod`; `:249` (`parseSetLabel`) and `:294` (`runRuleAction`) each fire it | `GroupItem.twk:1335-1337` — the fork then calls `fireLabelMethod` (defined `:1000`) **and** `attachLabel` (`:1087`) on the same label. The false claim is the header at `:969` |
| 2 | dispatch order | `Generate.rtn:345` `setParse`'s arms | `RuleStuff.twk:238` `setTestMatch` |
| 3 | no `checkInput()` | `Generate.rtn:5` `parseAction`, `:128` `parseCondition`, `:168` `parseRule` — **`parseRule` is the one that matters** | `GroupItem.twk:1342`, where the interpretive path calls it before `testMatch` |
| 4 | local-clear guard | `Generate.rtn:205` — `isLocal && !isRule && groupBody != field.groupBody` | `GroupActions.rtn:672` — `isLocal && !isLabel && !noPrint && groupBody != action.groupBody` |
| 5 | `*` at zero fails | `RuleStuff.twk:312` — `if counter && counter >= min`, unsatisfiable at 0 | `GroupItem.twk:1395` — the rescue `if !sukcess && kount >= min sukcess = true`, which `GroupItem.twk:1338`'s `goto generatedExit` jumps **past** |

### ⚠ AND 1 AND 5 ARE NOT MINTABLE AS FIXIT INCANTATIONS YET — measured 2026-08-20, and this is the finding, not an excuse

Both are **generated-path run-time** claims, so demonstrating either needs a parse that actually
executes through a bound `parseRule`. **There is no command that drives one.** `incant/setup`'s
registry exposes `setParse`, `parseMethod` (`parseRuleMethod`) and `parseTerms` (`parseTermCount`);
the only thing that drives a real parse is a **file include**, so a fixture would have to carry its
own corpus file — which must be registered in `incant/setup`'s `fILEs` registry (bear-trap #28's
fourth row), in Tony's live-read file. **That is a build, not a mint**, and it plausibly belongs
behind F-31's ruling since the whole generated path is gated there.

**⚠ AND `walkPhase`'S HEADER IS STALE ON THE PREMISE THAT WOULD HAVE STOPPED THIS.** It states that
it *"does not call `setParse`"* because *"`setParse` binds `parseRule`, and `parseRule`'s
not-an-action arm dereferences a null, so the first rule that is reached through it takes the process
down."* **Re-measured: it does not.** `incant/parseClass` binds all 239 fields and is a green fleet
row, and a fresh probe bound the same 239 and then ran an `include` **at exit 0**. Binding is safe;
what is untested is a parse *through* the bound methods. Dated-fact rot, same shape as the
`ipc/`-gitignored row — the header should be corrected by whoever next touches that file.

**⚠ THREE VOID CONTROLS WERE BUILT AND DISCARDED GETTING TO THAT SENTENCE**, reported rather than
graded: an `if "$arm" eq "bind";` guard inside the driver **did not discriminate** and both arms
bound 239; `showBody(Utilities["flatten"])` printed `BODY showBody`, the lookup echoing its own tag
(bear-trap #26's family); and `include(utilities)` after binding **returns without anything
observably arriving**, so "survived" is not "parsed". None of the three is evidence about F-26.

**Done when:** each of the five has a ruling — repair, or a line in `Generate.rtn` saying the
divergence is intended and why. **Owner: Tony** (his file, his intent). **Size:** rulings, then small
edits. **For 1 and 5 the ruling can be read off the sites above; the runnable demonstration is owed
an instrument first.**

### F-35 — ✅ CLOSED 2026-09-01 by discriminator 2 — it was CODEGEN DRIFT FROM ONE OUT-OF-REPO LINE
**Verdict:** SEQ 100 C1. Discriminator 1 (same binary?) answered SAME — `pop.sh` resolves
`${INCANT:-$HOME/bin/incant}` and the md5 matched the scratch board's byte for byte, so not a
tooling row. **Discriminator 2 (same codegen?) answered DIFFERENT, and closed it:**

| build | `auditMissingRules`, GroupRules.mm:2217 |
|---|---|
| incumbent `b0fca3d` | `if ( entry->groupBody->flags.isRule && !entry->rStuff )` — **RAW field, IMMUNE** |
| current | `if ( ... && !entry->getRStuff() )` — accessor |

⚠⚠ **AND IT CORRECTS THE R3 COMMIT, WHICH GOT THE STORY BACKWARDS.** R3 claimed *"the audit was
constructing an rStuff for every node it reported as missing one"*. **False for the incumbent** —
the audit read the raw field and never constructed. That became true only *after* `getRStuff` was
added to `groups.ext`'s external `GroupItem` mirror, in the same commit. **The claim was measured on
one build and cited as a timeless fact about another**, which is precisely the re-measure-before-you-
cite failure this project already keeps a ledger for.

**What actually produced the 0/801 reading:** on the incumbent, `auditMissingRules` was immune but
the **~137 accessor sites around it were not**. A heavy preamble parses a great deal before `audit()`
runs, and every `if !x.rStuff` existence test along the way silently constructed — so the audit read
a tree that everything else had been mutating. **The corruption was upstream of the audit, never
inside it.** Confirmed by preamble-dependence: on the pure binary, light and heavy preambles both
report **10 missing / 4 loose**; on the incumbent, heavy reported **0 / 801**.

⚠ **THE MIRROR LINE'S REACH, MEASURED: 8 `getRStuff()` call sites before, 137 after.** One line in a
file outside this repo moved ~129 reads from the raw field onto the accessor. Harmless while the
getter is pure; a tree-wide mutation the day anyone puts work back into it. **A standing fleet row
now pins the raw-read count at 30 so this drift goes RED at the next retok** instead of being
rediscovered as an audit mystery. H7 control: under the incumbent mirror the row reads 136.

**Status:** closed. Stays one cycle for the trail.

---

### F-35 (superseded) — the original open row, kept for the reasoning trail
**Where:** `Commands.rtn` `auditRStuff` (the `audit` command) and `GroupActions.rtn`
`auditMissingRules`. Surfaced 2026-08-31 while measuring the `getRStuff` purity ruling.

**What:** the same command, on the same binary, reports two different boards depending on the
preamble it is run under — and the *incumbent* constructing getter made the difference enormous.

| binary | scratch (`include unitTests/utilities`, `search reset stack Grokking UnitTests Utilities`) | `pop.sh`'s audit row |
|---|---|---|
| incumbent (getter constructs) | **0 missing, 801 loose** | **10 missing, 4 loose** |
| pure getter (shipped) | **10 missing, 4 loose** | **10 missing, 4 loose** |

**Read the incumbent's scratch row.** `0 missing / 801 loose` is exactly the signature of an
audit that repairs as it counts: `auditMissingRules`' test is `if entry.isRule && !entry.rStuff`,
which tok renders `!entry->getRStuff()` — so on the old getter **asking created one**, no rule
could ever read as missing, and every non-rule it had touched then read as *loose*. Mechanism and
numbers agree in both columns.

⚠ **BUT `pop.sh`'S ROW DID NOT MOVE, ON EITHER BINARY, AND THAT IS THE UNEXPLAINED PART.** If the
corruption were simply "asking creates", it should have zeroed the missing count on *any* board.
It did not zero `pop.sh`'s. So the two runs are walking different boards, or the two audit
functions differ in how they read (one may use a raw passthrough and be immune) — **both are
guesses and neither has been checked.** Recorded as an open discrepancy rather than explained.

**Why it matters even though the shipped number is unmoved:** the campaign's certification gate is
an audit number. A number produced by an instrument whose reading depends on which preamble ran
first is not a gate. The purity ruling closes the repairs-while-counting half; **it does not
establish that the remaining number means what the gate assumes.**

**Evidence:** exhibit is four runs — two binaries × two boards — reproducible from the table above;
`genParse.rtn`'s `unresolvedTerms` header independently records the old getter being *caught in the
act* corrupting a term census.

⚠⚠ **A STRONG CANDIDATE MECHANISM, FOUND AFTER THE ROW WAS WRITTEN AND GRADED AS A CANDIDATE, NOT A
CONCLUSION: WHETHER A `.rStuff` READ WENT THROUGH THE CONSTRUCTING GETTER WAS FILE-DEPENDENT.**

Adding `getRStuff` to `groups.ext`'s external `GroupItem` mirror on 2026-08-31 **changed codegen in
`RuleStuff.mm` at 26 lines** — `term->rStuff` became `term->getRStuff()`. So before that commit,
those sites read the **raw field** and were **immune** to the construction, while `GroupRules.mm`'s
sites went through the accessor and were not. Bear-trap #11 exactly: `groups.ext` affects codegen,
is out of repo, and can never appear in a Groups `git status`.

**A residual immune population still exists — 21 hand-written passthrough sites that bypass the
accessor entirely** (`GroupRules.mm` 19, `GroupItem.mm` 1, `RuleStuff.mm` 1, counted 2026-08-31
after a full sweep). **So "does this read construct?" had at least three different answers depending
on which file the line lived in and what the out-of-repo mirror said that week.**

⚠ **This is a candidate for the discrepancy and is NOT established as its cause.** It would explain
two audit paths disagreeing, and it is one grep from being checked — find which rendering
`auditRStuff` and `auditMissingRules` each compiled to on the incumbent binary. **Check it before
building on it**: the ledger for reasoning on top of an unmeasured premise in this codebase is
four rulings dead in one day.

**Done when:** one process runs both audits on both boards with the population printed per registry,
and the discrepancy is either explained or one of the two audits is retired. ⚠ **Pair it with a
control that must NOT move** — a board with no non-rules, where "loose" is 0 either way — so a fix
that merely changes both numbers together cannot pass.
**Owner:** unassigned. **Size:** one fixture, no build. **Minion-ready.**

### F-37 — ✅ CLOSED 2026-09-02 — RETIRED IN FULL on the zero branch. `tokened`/`captureSpan` is the live road.
**Where:** `GroupActions.rtn:1772` `extern GroupItem tokenize(GroupItem label)` — the glom that
flattens a parent label's components into a token. Bound at `GroupMain.twk:172-173`
(`strap = new("tokenize"); method = tokenize;`), mirrored inertly at `incant/grammar:34`.

**THE MEASUREMENT (2026-09-02, ephemeral counter, reverted and rebuilt bare before certification):**

| run | probe installed | `tokenize` firings |
|---|---|---|
| the whole fleet | ✅ | **0** |
| a names+numbers-heavy fixture | ✅ | **0** |
| `incant/oneTest` | ✅ | **0** |
| `incant/parseClass` (237-row census) | ✅ | **0** |
| a fixture DEFINING a rule with a literal `tokenize` term | ✅ | **0** |

The `PROBE INSTALLED` marker printed unconditionally from `stopParsingInput` on every run, so a zero
reading is distinguishable from a missing instrument (rule H4).

**⚠ THE MECHANISM, AND IT IS STRONGER THAN THE COUNTER.** `NamE` and `NumbeR` are built in
`GroupMain.twk:228-258` with **`tokened = true`** — a *flag* — and **no `tokenize` term**. Their
grammar lines are inert mirrors and say so. The flag's live consumer is `GroupItem.twk:1142`,
`if tokened captureSpan(stuff);`, whose own comment reads *"the tokened bit, which TOKENize sets
once at definition. It writes the span…"*. **`captureSpan` is the replacement road and `tokenize` is
its predecessor.** `HeX`, the one rule whose definition still spelled a `tokenize` term, is parked
inside a comment block, and the parking note says it *"removes one of tokenize's reads-through"*.

**And the grammar mirror line is provably inert:** deleting `incant/grammar:34` left Grokking at 84
members, `tokenize`'s presence unchanged, and the fleet byte-identical. `GroupMain` governs.

⚠ **WHAT IS MISSING, STATED RATHER THAN GLOSSED: THERE IS NO KNOWN-POSITIVE CONTROL.** Rule H11 says
a census without one is not a measurement. I could not make `tokenize` fire on purpose — defining a
rule carrying the term did not do it, and driving a parse through that rule needs `parser`, which is
an incant driver rather than a registered command. **So the counter alone cannot exclude "the
instrument sits on a function nothing calls by that name"** — though it is installed on the exact
extern `GroupMain:173` binds. **The conclusion rests on the MECHANISM above, with the counter as
corroboration; it does not rest on the counter alone.**

**Done when:** Tony rules how far the retirement goes. Clay's two branches, with this measurement the
counter-reads-zero branch is live: *method, extern, binding, entry, and the `tokenize` attribute
stripped from `NumbeR` and any sibling still spelling it.* Tony's alternative on the table is to
**keep it as a command so kant can find it** rather than delete it. ⚠ **Either branch ends with
F-31's fourth customer struck and nothing ever installing over `tokenize` — that part is settled
regardless and does not wait on this row.**
**Owner:** Tony (ruling), then Clod (sweep). **Size:** the sweep touches GroupMain's bootstrap, so it
is not minion-sized.

### F-36 — ⚠ `* *x` (two space-separated unary stars) CRASHES THE PROCESS AT 139
**Where:** unary `*` composition. `ruleActions.rtn`'s `handleUnary` re-points prefix `*` to the
named `deref` op (`opDeref`, `Instruct.rtn`); the failure is in composing two of them, not in
`opDeref` itself.

**What:**
```
    daWrap := daLeaf;
    cerr "x =" * *daWrap:;
        ERROR Operator * failed on Token and xl1
        <exit 139, no sentinel>
```
A single `*` on the same field is fine — it errors cleanly (`unary * on daLeaf -- it holds no
group`), returns `0`, and the run continues. **It is the second star that kills it.**

**Why it matters beyond the crash:** Clay's ruling for the new `**` fixpoint operator states the
spelling law as *"one token, one meaning — a space means two single unwraps"*. **Measured, a space
means a crash**, so that half of the ruling has no behaviour to name. `**x` versus `* *x` cannot be
a spelling distinction until this is fixed.

**Evidence:** found 2026-09-01 while building `incant/derefAllT`. ⚠ **And the first probe that
established the fixpoint died the same way and was read as a clean run** — the error line printed,
the sentinel did not, and nobody checked. That is the project's own truncation doctrine walked into
by the seat applying it; the fixture now uses a single `*` for its differ-row precisely so it cannot
take the suite down (rule H5).

**Done when:** `* *x` either composes (two unwraps, an error on the second if the first yields a
non-group) or refuses by name. ⚠ **Pair the fix with `***x`**, which today errors from the inner
star and yields empty rather than refusing — Clay ruled it should refuse, and that clause is
currently unimplemented. **Anti-vacuity: keep a row for single `*`, which must stay a clean error
and NOT become a crash or a silent pass.**
**Owner:** unassigned. **Size:** one tokeniser/handleUnary question plus a fixture row. **Not
minion-sized — the refusal semantics are a ruling.**

### F-34 — the kant shim and the C++ emitter bake DIFFERENT literal text for a data-carrying term
**Where:** `genParse.rtn`, `litK` (and now its twin `litToK`) versus `emitLeaf`'s `LIT`/`LITTO` arms.

**What:** the two generators derive a literal term's match text from different places.

| generator | spelling | source of the text |
|---|---|---|
| C++ `emitLeaf` | `lit(tN,"x")` | bakes `node.text`, which `planTerm` sets to **`term.text`** when `term.data && term.isSTRING`, and to `term.tag` otherwise |
| kant `litK` | `litK(N)` | resolves the term from the frame and matches **`term.tag`**, always |

So for a term that carries string data the two paths match different strings. For every other term
they agree, which is why the ladder has never seen it: `litK`'s own header states the rule it relies
on — *for a noLabel literal term the TERM'S OWN TAG IS the literal* — and that rule holds for the
`!term.contents()` shape but **not** for the `term.data && term.isSTRING` shape one arm above it in
`planTerm`.

**Evidence:** `planTerm` has two LIT/LITTO mints. The data-carrying one sets `node.text = term.text`;
the contents-less one sets `node.text = term.tag`. `litK` reads neither — it reads `term.tag` off the
live term. Found 2026-08-31 while building `litToK`, which **deliberately copies `litK` rather than
`emitLeaf`** so the twin agrees with its sibling instead of introducing a third spelling.

**Why it is a capture and not a fix:** it predates `litToK`, the two engines are compared by
`kantRatchet.sh` on rules where they agree, and picking a winner is a decision about which generator
is authoritative — not a repair. **Naming the wrong winner would make two engines disagree silently
on a shape neither has been driven on yet.**

**Done when:** a specimen with a data-carrying literal term is driven through BOTH generators and
the divergence is either measured to be unreachable (in which case say so, with the census) or one
spelling is ruled authoritative and the other repaired to match. ⚠ **Pair it with a control on a
tag-only literal term, which must stay byte-identical either way** — an anti-vacuity row, because a
change that moved both shapes would pass a test that only looked at the divergent one.
**Owner:** unassigned. **Size:** one census plus one ruling. **Not minion-sized — the ruling is not.**

### F-30 — `Operators` reaches `setParse` as a term and has no `rStuff`
**Where:** found by `incant/parseClass`, 2026-08-19 — the one surviving `NO-rSTUFF` row out of 239
once the census was aligned with `walkPhase`'s skips.
**What:** the `Operators` registry is reachable as a member of `Grokking`, so a walk that binds parse
methods calls `setParse` on it and gets `setParse: ERROR field passed in Operators has no rStuff`.
Same symptom Tony hit on the pick-one terms (`e`), different node.
**Why it is only one row now:** the first draft of the census descended INTO `Operators` and produced
**54** such rows for `+`, `==`, `AND` and their siblings. Those were the fixture's own artifact — the
real walk does not descend into a container — and were removed by copying `walkPhase`'s skips. **The
container itself is still reached, and that row is real.**
**✅ RULED AND CLOSED (Tony, 2026-08-19): registries are infrastructure, not grammar.** `setParse`
skips `isREGISTRY` at its own **entry**, so a registry never reaches arming and never reaches the
rStuff complaint — the difference between a clean skip and a swallowed error. `parseClassify` reports
it as `skipped-registry`, and `parseClass.target` was re-pinned on exactly one moved row
(`PC NO-rSTUFF Operators` → `PC skipped-registry Operators`, 239 rows both sides).
**⚠ THE SKIP IS `isREGISTRY` ONLY, NEVER `isBIN`.** A bin is a grammar TERM whose entries are the
alternatives — `BrancheS` and `UnaryOPS` are bins and both legitimately bind `parseContainer`,
measured. Widening the test to `binType` would silently delete four `parseContainer` rows.

### F-32 — the generator emits `else()` for a keyword term, so `BasicElse`'s body cannot parse
**Where:** `walkPhase`/`fixBisect`'s generated body for `BasicElse`, surfaced 2026-08-19 as the
constant-failure background of F-31's bisect.
**What:** the emitted body is `if else() AND followedBy() AND StatemenT(...)`. `else` is a keyword, so
the statement cannot parse, and `BasicElse` fails to compile at **every** install count — the error
reads `failed at "else() AND followedBy()"`, i.e. the text is read and rejected.
**Why it is worth its own row:** it is a *different* defect from F-31 and it nearly hid it. Counting
`ERROR processCode` to detect F-31's poisoning reports a failure at N=1 and conceals the transition
entirely; only the `reached end of input` signature moves. **A constant failure is camouflage for a
variable one.**
**Done when:** the term emitter either quotes or renames a keyword-named term, and `BasicElse`
compiles. **Owner:** unassigned. **Good minion candidate** — the failing text is in hand.

### F-33 — the generator emits a MALFORMED body for a zero-term rule, silently
**Where:** the body generator's term loop — `incant/fixBisect`/`incant/f31`'s `fbGen` reproduces it
verbatim from `walkPhase`'s. Emits `if `, loops the rule's terms, then emits
`return runRuleAction(this);`.
**What:** for a rule with **zero terms** the loop emits nothing, so the body comes out as

```
{
    if  return runRuleAction(this);
}
```

**an `if` with no condition** — malformed, and emitted **silently**: no warning, no refusal, clean
install.
**How it was found:** F-31's **Arm A trace**, 2026-08-20, dumped from the install buffer. **Capture,
not chase** — **it gates nothing in F-31's arc**, whose mechanism (installing over live machinery) is
measured and whose fix is ruled and released independently of this.
**Why it matters beyond `tokenize`:** `tokenize` is the zero-term rule that happens to also be a
hook, so its malformed body was *catastrophic*. **Any other termless rule gets the same malformed
body with no hook to make the damage loud** — which is the silent-failure shape this register exists
to catch.
**NEXT: BEST GUESS — candidate remedy, Tony ratifies before build.** Emit the **minimal well-formed
body** for a termless rule: **no `if` at all, straight to `return runRuleAction(this);`**.
⚠ **NOT "refuse to generate."** Refusal was the shape that fell out of the trace first and it is
**rejected on trajectory, the same way `defer-the-hook` was**: it would leave termless rules
**permanently outside self-hosting**, which cuts against the north star **for no gain** — the minimal
body costs the same to emit and keeps them inside.
**Done when:** a termless rule generates a well-formed body, and something in the fleet covers it.
**Owner:** Tony ratifies the shape; then whoever builds.

### F-31 — ✅ **CONFIRMED, RATIFIED BY TONY, 2026-08-20 — THE CAMPAIGN GATE IS OPEN**

**Everything queued behind "parse generation closes" is unblocked.** The verdict was chartered as
**prior to and independent of the mechanism**, and it held that way through four amendments, a
refuted prediction, a rechartered census and a selected fix — which is the chartering working, not a
delay.

**⚠⚠ ARM A RAN 2026-08-20 AND CAME BACK POSITIVE — THE MECHANISM IS PROMOTED AND THE BUILD IS
RELEASED.** Method: a temporary `cerr` on the C++ `tokenize` (`GroupActions.rtn:1545`, the function
that gloms parent label components into the label string), counting calls; then a **bare revert and
rebuild**, verified — canary 308, zero `TOKZ` in the `.mm`, fleet back to 53 green. Both arms install
**42** bodies and differ only in whether `tokenize` is among them:

| arm | `tokenize` in | calls, whole run | **calls DURING the compile** | compile |
|---|---|---|---|---|
| 0 | no | 1163 | **2** | CONTENT read |
| 1 | **yes** | 1170 | **0** | end-of-input |

**⚠ THE TWO COLUMNS MUST BE READ TOGETHER.** The whole-run totals are effectively equal (1163 vs
1170), so the C++ tokenizer is **alive and called throughout both runs** and the install does **not**
kill it globally — that is the anti-vacuity control, and it is what makes the second column mean
anything. **During the compile the count goes 2 → 0.** Two calls then a content failure is a reader
that got tokens and choked on them; **zero calls then end-of-input is a reader that never got a
token.**

**⚠ AND THE TRACE BOUGHT A REFINEMENT — THE BODY INSTALLED OVER `tokenize` IS DEGENERATE:**

```
{
    if  return runRuleAction(this);
}
```

**An `if` with no condition.** `tokenize` is declared `tokenize^@;` (`grammar:34`) — a bare hook with
**zero terms** — so the generator emits `if `, loops the terms and emits nothing, then emits the
return. **The dual-role collision bites here and not on the other 42 precisely because the hook is
TERMLESS.**
**⚠ WHAT REMAINS INFERENCE**, stated so it is not read as measured: that the read *executes this
body* rather than merely being diverted by `isCodeD` into some other empty path. **The distinction no
longer changes the fix** — both readings are *"the install displaced the hook"*, which is what the
selected shape addresses.
**⚠ THE DEGENERATE BODY IS ITS OWN DEFECT AND HAS LEFT THIS TABLE — see F-33.** It was briefly
listed here as a third fix shape; **it is not one.** It gates nothing in this arc, and the fix ruled
here stands on trajectory regardless of what the body looks like. Charted separately per
capture-not-chase.

**The sequence from here:**
1. ~~**Arm A**~~ — ✅ done, positive.
2. ✅ **Mechanism promoted, build released** — the invariant fix (off-rule storage plus explicit
   activation).
3. **BUILD STEP ONE, chartered 2026-08-20 and NOT conditional on when the build starts: write
   `incant/f31`'s expected taken-signature down BEFORE touching code.** Otherwise the harness gets
   regenerated green around whatever the change happened to do — *a target that is regenerated green
   is not a target.*
   ⚠ **AND THE HARNESS'S SCOPE IS NARROWER THAN THE BUILD'S:** f31 **oracles the `tokenize` symptom,
   not the mechanism.** A green f31 certifies that `tokenize` survives installation; it says **nothing**
   about off-rule-storage-plus-explicit-activation being right for the ruling's **other three
   customers** (the napalm, the `BlocK` re-poison, mid-walk `setParse` binding), none of which is
   exercised here. **The verification surface for the build is wider than the fixit that gated it.**
4. **`incant/f31` re-enters the queue when the build lands**, wearing a `REMEDY` block, for one last
   run: bless the taken signature. **One citizen, two tours.** It was **discharged by ruling** on
   ratification and now lives at `incant/f31` — off the queue, still runnable.

⚠ **ONE DISCREPANCY, FLAGGED RATHER THAN SILENTLY RECONCILED.** The relay describes `tokenize` as the
**fifth** customer of off-rule-storage-plus-explicit-activation; everything recorded here and in
`docs/hookRules.md` says **fourth**, enumerating three predecessors — the napalm, the `BlocK`
re-poison, and mid-walk `setParse` binding. **Either a fifth customer was added somewhere outside
this record, or the number slipped in relay.** Left as *fourth* here because that is the count whose
members are named; **the ordinal is worth one check by whoever knows the fifth.**

### F-31 — the investigation, as it stood before ratification
**Where:** `incant/walkPhase`, measured 2026-08-19 on the current tree.
**The partition:** entered **139** · generated **56** · leaf **60** · refused **23** (9 distinct rules:
`ExpressioN` ×8, `StatemenT` ×7, `PRINTing` ×2, and one each of `while`, `tokenize`, `QuotE`,
`NumbeR`, `ElsE`, `DEFINing`). Then phase 2: **compiled 0, rejected 56.**
**⚠ THE REJECTED COUNT IS CORROBORATED, not taken from the counter.** `walkPhase` captures
`compile`'s return with `:=`, which F-22 records as unreliable, so the count alone would be suspect.
The independent signal is **56 `ERROR processCode: <rule> parse failed` lines**, one per body, each
reading `failed at :reached end of input / on line 1`.
**⚠ AND IT IS A PHASE INTERACTION, NOT A PER-BODY DEFECT — this is the discriminating measurement.**
`incant/compileProbe` compiles a single body on the same binary and passes every row (A, B, D green,
subject marker printed). Tony's `runNamE` likewise compiled `NamE` successfully in Xcode — and `NamE`
is among the 56 that fail here. So a body that compiles alone fails after phase 1 has installed the
others.
**Consistent with `walkPhase`'s own header** (*"once enough generated methods install, the parser can
no longer read the source that FOLLOWS"*), and note it does **not** call `setParse` — so whatever
poisons phase 2 is not parse-method binding.
**⚠ BISECTED 2026-08-19. ONE INSTALL FLIPS IT, AND IT IS NOT A COUNT.** `incant/fixBisect` installs
the first N bodies and then compiles the FIRST one, the one known good alone:

| N | last installed | compiling `BasicElse` |
|---|---|---|
| 1 … 42 | … `break` | fails on **CONTENT** — `failed at "else() AND followedBy()"`, so the body text **is read** |
| **43** | **`tokenize`** | fails at **`reached end of input`**, line 1 |

Same first body, same compile, **one extra install between them**. So it is not accumulation: a
single install turns a readable body into an empty read, which is the signature all 56 of
`walkPhase`'s failures carry. **Individually perfect, collectively unreadable** — the shape the
aliasing family predicts.
**⚠ AND THE DETECTOR HAD TO BE THE SIGNATURE, NOT THE ERROR.** `BasicElse` fails to compile at EVERY
N, because its generated body calls `else()` and `else` is a keyword — a real defect but a different
one. Counting `ERROR processCode` reports failure at N=1 and **hides the transition completely**.
Only *"reached end of input"* moves.
**⚠ THE NAME-SKIP CONTROL IS VOID, NOT NEGATIVE.** Two spellings meant to skip the suspect by name —
`taG eq "tokenize"` and `fbCur.taG eq "tokenize"` — **both matched every member and installed
nothing at all**, so they cannot say whether skipping it mattered. Reported as void per the
do-not-grade-a-voided-control rule. What stands is the A/B, which isolates the same single install
without naming it. *(The string comparison behaviour is itself a candidate trap: an `eq` against a
tag in an `iterate` body matching universally.)*
**CANDIDATE MECHANISM, NOT ESTABLISHED:** `tokenize` is the tokenizer hook (`incant/grammar:34`,
method set to `tokenize()`), used by `NamE`, `NumbeR`, `HeX` and `FormaT`. Installing a generated
body over it — `clear(CodE)`, then `isCodeD` — plausibly displaces the method every later read
depends on, so the reader tokenizes nothing and every subsequent body compiles as empty. **Structural
support only; the control that would confirm it is the void one above.**
**⚠⚠ CONFIRMED 2026-08-20 BY A SAME-COUNT SWAP — IT IS `tokenize`'S IDENTITY, NOT THE NUMBER OF
INSTALLS.** `incant/fixits/f31`. The void name-skip is replaced by an **ordinal** skip, and the
confound is broken by holding the count fixed and exchanging one member for another:

| arm | installs | `tokenize` among them | last install | compiling `BasicElse` |
|---|---|---|---|---|
| 0 — control | **42** | no | `break` | **CONTENT** — `failed at "else() AND followedBy() AND StatemenT("` |
| 1 — measurement | **42** | **yes** (`BlocK` dropped instead) | `tokenize` | **EMPTY** — `reached end of input`, line 1 |

**Same count. One member swapped. Opposite answers.** The A/B alone could not say this, because 42
vs 43 moves the count and the membership together.

**⚠ AND THE SWAP HAD TO BE A SWAP, WHICH IS WORTH RECORDING BECAUSE THE OBVIOUS CONTROL IS
UNBUILDABLE.** The first attempt was *"install 43 with the suspect left out"*. **The eligible
population is exactly 43 bodies and `tokenize` is the LAST of them**, so 43-without-`tokenize` does
not exist — a skip at that limit silently yields 42 installs, which is just the existing N=42 arm
wearing a different name. It reproduced the CONTENT read and would have read as a clean refutation.
**A control that collapses into an arm you already have is void in the same way the name-skip was,
and it does not announce itself.** Hence both arms at 42, and hence both counts printed on every
run.
**⚠ A SECOND VOID WAS CAUGHT THE SAME WAY:** an ordinal skip placed after `fbGen`'s `datA` gate
still skipped the wrong node — `continue` reaches `fbGen` and is dropped there silently, so it
consumed the skip without ever being an install. **The skip must sit at the LAST point before the
install work**, and the fixture prints the name it skipped for exactly this reason. Both misfires
were caught by the printed name, not by reasoning.

**⚠ THE `WHY tokenize` STORY IS A DUAL-ROLE COLLISION, CANDIDATE-GRADE — and it is NOT
double-compilation**, a reading the evidence permits and which would aim the fix at nothing.
`tokenize` wears two hats: **citizen #43** of the population, so the campaign generates and installs
a parse body for it like any other rule; and the **tokenizer HOOK** (`incant/grammar:34`), the live
machinery the reading side calls. The install does not break `tokenize`-the-rule — it breaks
`tokenize`-the-**hook**: after #43, a read routes through a body whose `CodE` says *how to parse the
`tokenize` rule* instead of *how to tokenize*, yields no tokens, and reports end of input at line 1.
**That is the signature double-compilation cannot produce** — not `tokenize` failing, but everything
after the install becoming unreadable while each body stays perfect. *Individually perfect,
collectively unreadable — because the collective's reading channel was one of the individuals.*
**⚠ GRADE: the A/B isolates the install and the pointers show the in-place overwrite, but NOBODY HAS
WATCHED A READ ENTER THE OVERWRITTEN BODY.** The whole causal chain rests on that step.
**The one measurement that promotes it:** trace a single read after install #43 and watch it enter
`tokenize`'s overwritten body. **Fourth customer of off-rule-storage-plus-explicit-activation** (with
the napalm, the `BlocK` re-poison, and mid-walk `setParse` binding) — two fix *shapes* follow
(store off-rule and activate late; or exempt the hook from installation, which is a ruling on whether
`tokenize` should self-host its own parse) and **neither is recommended, because the mechanism is not
established.** Both live in `incant/fixits/f31`'s terminal **`NEXT: BEST GUESS`** block (Addendum 4) with their
grade and their kill conditions attached — **no `REMEDY:` block, because nothing is established
enough to recommend.** That block also charters the order: **ratifying CONFIRMED is decision one and
commits nothing about mechanism**; **step zero has TWO ARMS of equal rank**; both fix shapes ride
behind them.

**⚠ ARM B IS RUN, AND DISPATCH IS LIVE — NOT FROZEN AT BIND** (2026-08-20). Two compiles of the
**same body** in **one process** with one install between:

| | installs | compiling `BasicElse` |
|---|---|---|
| COMPILE-1 | 42, `tokenize` left out | **CONTENT** — `failed at "else() AND followedBy() AND StatemenT("` |
| COMPILE-2 | 43, `tokenize` just installed | **EMPTY** — `reached end of input` |

The frozen-at-bind prediction was that a reader which had already resolved the tokenizer would go on
reading cleanly. **It does not.** Reading re-consults something the install changed.
**⚠ WHAT IT DOES NOT SETTLE:** the failure is **temporally** tied to the install; it is **not** shown
to route through `tokenize`'s body specifically — any state the install touches yields this. **Arm A
(the trace) is still owed and is still the promoter.** ⚠ **And the count moves between the two
compiles (42→43), which is the original confound deliberately reintroduced** — so this does *not*
replace the same-count swap: **the swap holds count fixed and settles IDENTITY, this holds population
fixed and settles TIME.** Neither substitutes for the other.
**⚠ THE HOOK CENSUS (step zero item 3) IS RUN, AND THE COUNT IS ONE — BUT NOT FOR THE REASON THAT
WOULD MAKE THE SPECIAL CASE SAFE.** Measured 2026-08-20 off the walk's own ENTER/INSTALL trace: **59
entered `fbGen`, 43 installed, 16 dropped at the `datA` gate** (`ANYtoken Any Attributes InitiatE
Looper Modifier NewGroup ShortcuT Start continue followedBy loopOnAttributes loopOnMembers nameSet
numberSet return`).

**`tokenize` is the only bootstrap-constructed machinery rule that REACHES installation.** The
siblings exist — `nameSet`, `numberSet`, `counter`, `delimiter`, `Modifier`, `Limit`, `MEMBERs`,
`Any`, `ruleSkipSet` are all built in `GroupMain.twk` the same way — but **every one carries data**,
because they are character sets, so the `datA` gate drops them. `tokenize` carries none: it is a
**method hook**, which is exactly why it is the one that gets a body written over it.

**⚠ SO THE SIBLINGS' IMMUNITY IS INCIDENTAL, NOT DESIGNED**: the count is one *by accident of what
those rules happen to hold*, and the first machinery rule that is a hook rather than a character set
becomes a second customer with nothing in the tree to stop it.

**⚠⚠ AND THE CENSUS WAS RECHARTERED THE SAME DAY IT WAS RUN — IT DOES NOT DECIDE THE FIX. Tony ruled
the HOOK CLASS OPEN**, and *now* is the operative word: `tokenize` may be the only member today, but
**self-hosting structurally mints dual-role rules over time**, because moving machinery into rules is
what self-hosting *is*. So **`defer-the-hook` is REFUTED as a class fix regardless of the count** —
correct for today's grammar, **silently wrong for tomorrow's**, which is the worst shape available: a
right answer with an expiry date and no alarm on it. **The count never got to vote.**
**SELECTED: off-rule storage plus explicit activation**, the invariant fix, **on trajectory
grounds** — fourth customer of that ruling (with the napalm, the `BlocK` re-poison, and mid-walk
`setParse` binding), self-hosting preserved. **⚠ GATED: Arm A's mechanism promotion comes BEFORE the
build.** A negative Arm A would *not* restore the refuted shape — that was refuted on trajectory, not
on evidence, and a trace cannot un-refute it; it would reopen *what the install actually breaks*,
leaving the selected shape aimed at an unestablished target.
**The census survives as a STANDING REGISTRY — `docs/hookRules.md`**, row one `tokenize`/`grammar:34`,
appended whenever machinery migrates into a rule.
⚠ **Second time this campaign a fix was chosen by asking what the PROJECT IS rather than what the BUG
DOES** — the pick-one constraint went the same way. A bug-shaped question here returns *"one member,
take the cheap special case"*: the correct answer to the wrong question.
**⚠ SEARCH SPACE NAMED:** this censused **one surface** — rules the bootstrap constructs by name in
`GroupMain.twk`, cross-read against the walk's ENTER/INSTALL trace. **A rule declared in the grammar
that the reader nonetheless invokes would not appear in it, and whether that class is empty is not
measured.**

**Consequence:** a live dispatch means sequencing does not rescue a read that comes *after* the
install, so *"compile everyone else first, install `tokenize` last"* is a **real candidate fix** and
not a re-ordering of the same failure — the fourth-customer shape with self-hosting preserved, now
the better-supported of the two.

**⚠ THE POINTER HALF, and the answer is NOT what "displaces the method" predicted.** `showBody` on
`Grokking["tokenize"]` before and after the installs prints **identical** lines — same `node`, same
`groupBody`. **The install does not re-point the field.** It overwrites `CodE` and sets `isCodeD`
**inside the one body every reader already shares** (the walked member and `Grokking["tokenize"]`
were measured sharing one `groupBody` while holding different node pointers). So the field the
install clobbers is `Grokking["tokenize"]` itself, **in place** — which is why every later read
tokenizes nothing.

**Done when:** ✅ confirmed by a working control, ✅ the clobbered field named. **Remaining: the
architect's word on the ruling**, since everything gated on "parse generation closes" sits behind
it. **Owner:** Tony — run `incant/fixits/f31`. **⚠ This is the last blocker's address.**

### F-28 — ✅ CLOSED 2026-08-19 — the split landed: `maxLimit` is the token limit, `repeatLimit` the repetition limit
**Where:** `RuleStuff.twk`'s `testMacro` loop and `GroupItem.twk:1339`'s `while !isOK && kount < max`.
**What:** one field, two populations — **how many characters one match may span**, and **how many
times a rule may repeat**. Measured 2026-08-19 over 181 fixtures they are three orders of magnitude
apart in kind, not just in value:

| population | fleet ceiling | is it a real bound? |
|---|---|---|
| characters in one match | **79** (`NotA`, `grammarOnTheFly`) | **yes** — no name or number gets much longer |
| repetitions of one rule | **171** (`StatemenT`, `phaseA`) | **no** — that is the length of one file, and the next may have a thousand statements |

⚠ **AND THE ASYMMETRY THAT MAKES IT URGENT: the character loop REFUSES LOUDLY through
`reportMaxLimit`; the repetition loop has no report at all.** A rule cut short at `:1339` just
stops, and every statement after the cut is simply not parsed — silently, at exit 0. That is the
`parse-succeeded-with-wrong-content` genre with no instrument pointing at it, which is exactly what
F-27's ruling refused to allow at the write site.
**The consequence today:** the default has to be chosen for the population that cannot be bounded,
so it is **100000** and the character limit is along for the ride. Tony's 100 — a good number for a
token — is unusable while the two share a field.
**RULED AND LANDED (Tony, 2026-08-19).** Two `GroupRules` fields, two stamped `RuleStuff` ints, and
the repetition loop joins refuse-loud:

| knob | bounds | fleet ceiling | default | on a hit |
|---|---|---|---|---|
| `maxLimit` | characters in one match | **79** | **100** | `reportMaxLimit`, **match fails** |
| `repeatLimit` | times a rule repeats | **171** | **100000** | `reportRepeatLimit`, **reports only** |

**⚠ THE TWO HITS DO DIFFERENT THINGS AND THAT IS THE RULING, not an oversight.** A truncated TOKEN is
wrong content, so it refuses. A rule that repeated to its ceiling matched everything it matched
correctly — what is wrong is that there may be more — so failing it would discard correct work and
change parse outcomes wholesale. It names the fact and leaves `kount >= min` alone.
`modify()` stamps both; `setLimits` stamps both from an explicit `[min max]` so a declared limit still
bounds repetition; F-27's write guard covers both fields with the same union hazard.
**Anti-vacuity, measured:** across 182 fixtures **exactly one** reaches either ceiling
(`sinkProbe`, repetition) and **nothing reaches the token ceiling of 100** — so the new default has
headroom over the whole corpus, and the sweep is what says so rather than the 79 alone.
**Control: `incant/limitT`, ten rows** — both boot defaults, a silent legitimate re-pin on each knob
(the H7 negative control), zero and string writes refused on each with the prior value surviving, and
a final row asserting the two knobs are **independent**.

### F-29 — `incant/sinkProbe` drives `StatemenT` to the repetition ceiling: a rule succeeding without advancing
**Where:** `incant/sinkProbe`, found by the F-27 high-water sweep rather than looked for.
**What:** its `StatemenT` `kount` reaches **268435457 — the ceiling EXACTLY**, so the rule was
matching without consuming input and only the bound stopped it. It cost **17.02s of CPU on every
run**; at the pinned 100000 the identical run takes **0.037s** and its output is **byte-identical**,
which is what proves the iterations were doing no work.
**Why it matters beyond the fixture:** this is the succeed-without-advancing family — the same shape
as the `parseSet` defect repaired in `654a180` — live in the corpus today, on the interpretive path,
and invisible because the ceiling silently absorbed it. **A runaway sets no floor for the limit**, so
it is excluded from F-28's table rather than allowed to pin the default at 268 million forever.
**⚠ HUNTED 2026-08-19. THE RULE IS NAMED; THE MECHANISM IS CANDIDATE-GRADE AND SAYS SO.**
The rule is **`StatemenT`**, named by `reportRepeatLimit` the first time it fired, which also printed
the input position — an instrument built that morning answering the question the same afternoon.

**Measured, five facts:**
1. The runaway rule is `StatemenT`, repeating to the ceiling.
2. The spin sits at **the first statement of the run that fails to resolve to a method**. Inserting a
   failing statement (`debug ALL;`) 40 lines earlier **moved the spin to it**; without the insertion it
   sits at `dumpContents(WardeD);` (`sinkProbe:60`). Two positions, two runs, deterministic.
3. **The retries are silent** — two `nextGroup: ERROR stuff does not contain a list` lines and then
   100000 quiet repetitions, so the repeats are not re-running the statement's actions.
4. `sinkProbe` **truncates**: stdout stops at `S5`, PARTs 2 and 3 never run, **exit 0**.
5. **It is the only citizen.** 182 fixtures swept; exactly one reaches either ceiling.

**CANDIDATE MECHANISM, NOT ESTABLISHED:** `StatemenT` re-attempts at an unmoved mark once a statement
fails to resolve, and the ceiling is the only thing that ends it.
**⚠ AND THE CONTROL THAT FAILED IS THE INTERESTING PART.** Three minimal reproductions — a bad
statement in a clean context, with an unresolvable name, and with `sinkProbe`'s own search list — **all
parsed fine and none spun.** So a failing statement is NOT sufficient; the trigger needs `sinkProbe`'s
accumulated state, which is its own GRAM-1 graft (a bare reference to a method-bearing field invoking
the method). **Do not write "a failed statement spins the parser" into doctrine — it is falsified by
its own control as stated.**
**Done when:** the spin is reproduced in a fixture that does not depend on sinkProbe's history, and
the option of `StatemenT` that keeps succeeding is named. **Owner:** unassigned.

### F-27 — ✅ CLOSED 2026-08-19 — `maxLimit` landed, refuse-loud at the write, default MEASURED at 100000
**Where:** `GroupControl.twk`, `setBaseRegistries` — `maxLimit.count = 268435457;`.
**What:** the maxLimit brief (2026-08-19) replaces `modify()`'s inline `-0xefffffff` with a
user-settable `maxLimit` property and specifies a default of **100**. Everything landed **except the
default**, which is sitting at the exact value `-0xefffffff` evaluated to (proved by compiler, not
assumed) so the change is **behaviour-neutral by construction**. The brief's own item 4 forbids
pinning 100 before a measurement, and the measurement needs a build.
**The re-pin, when the number is known:** one line, the one named above.

⚠ **AND THE MEASUREMENT IS WIDER THAN THE BRIEF ASSUMED — THIS IS THE FINDING THAT MAKES IT
LOAD-BEARING RATHER THAN PRUDENT.** The brief scopes the high-water count to "per modifier site
(`*`, `+`, and the upTo scans if they share the bound)". Measured against the code:

| site | bounded by `max`? | what a ceiling of 100 would cap |
|---|---|---|
| `testMacro`'s character loop (`testAny`/`testCharacter`/`testSet`) | **yes** | how many CHARACTERS one token may span |
| `Generate.rtn`'s `parseAny`/`parseCharacter`/`parseSet` | **yes** | same, on the generated path |
| **`parse()`'s repetition loop, `GroupItem.twk:1339`** | **YES — and the brief does not mention it** | how many TIMES a rule may repeat |
| `testUpTo` | **no** — it counts with `count`/`matchLength`, never reads `max` | nothing |

**The third row is the risk.** `while !isOK && kount < max` is the same `max`, so a ceiling of 100
caps **list length**, not only token length — any `X*` or `X+` construct with more than 100 elements
would silently stop at 100. A source file with 101 statements at one level is not exotic. **The
high-water run must record `kount` as well as `counter`**, and the headroom has to clear the larger
of the two.
**And the fourth row is a small win:** `testUpTo` does **not** share the bound, so whitespace runs,
comment bodies and string scans — the brief's named suspects — are not in the population at all.

**Done when:** an instrumented fleet run reports high-water `counter` (per tester) and high-water
`kount` (per rule), the default is set above the larger with headroom, and a before/after fleet
capture is byte-identical. **⚠ Any movement means the measurement missed a site — stop and report,
do not re-pin** (the brief's item 5, and H6's re-pin-needs-a-sentence rule).
**Owner:** measurement + re-pin unassigned; the two rulings below are **Tony's**.

**⚠ TWO THINGS THAT WANT A NOD, both outside the brief's stated boundary and both landed because
item 3 is not implementable without them:**
1. **`setLimits` now writes `limitsSet`** (`GroupActions.rtn`). The flag was already declared in
   `RuleStuff.twk`, already mirrored in `groups.ext`, and **never written by anything** — so this
   costs no layout change, no `groups.ext` field edit and no `tokall`. It is read as
   `max > 1 && !limitsSet`, which is true only for the ceiling `modify()` stamps.
2. **The report is gated, and ungated it would be catastrophic.** `max` is **1 by default**, so
   `counter >= max` is reached on the ordinary correct match of every single-character rule whose
   next character also matches — `NamE`'s `first-=[a-zA-Z]` would refuse every name longer than one
   letter. The gate is what confines the report to the unbounded ceiling. **A `max > 1` test alone
   would be safe only by vacancy** (no numeric `[min max]` Limit exists anywhere in the grammar or
   corpus — checked), which is exactly the shape F-9 exists to stop; hence the flag.

**⚠ THE HAZARD IS RULED AND CLOSED.** Tony, 2026-08-19: a write to `maxLimit` yielding a zero or
non-numeric count **reports at the write and does not take** — `maxLimit` keeps its prior value.
Rationale on the record: catching a bad limit at its one write site is cheaper than diagnosing a
million silent zero-matches at parse time, and a stamped `max = 0` is the succeed-without-advancing
family wearing a configuration costume. Implemented as `limitWriteGuard`/`limitWriteCheck` around
`opAssign`'s body — **the site is the ruling**, since by the time `modify()` reads a poisoned count
the write has already got away.
**⚠ AND THE TEST IS ON THE DATA TYPE, NOT ONLY THE COUNT.** `maxLimit = "big"` leaves an `isSTRING`,
and `getCount` reads `count` straight out of the union for one — which overlaps the text pointer, so
it comes back **large and non-zero**, not 0. A count-only test would have waved it through.
**Control: `incant/limitT`, five rows, all measured.** Boot default `100000` · legitimate re-pin to
250 **silent** (the H7 negative control — if every write reported, the refusal rows would go green on
an instrument that always fires) · `= 0` refused, 250 survives · `= "big"` refused, 250 survives ·
a further legitimate re-pin to 300 still takes.

**THE MEASURED DEFAULT: 100000, and 100 was NOT safe.** 181-fixture sweep, both populations
instrumented. Characters ceiling **79**; repetitions ceiling **171** — so `incant/phaseA`, a
171-statement file, **would have been truncated by Tony's proposed 100**. See F-28 for why the
headroom is asymmetric and F-29 for the runaway the sweep turned up.
**Fleet at the pinned default: 48 green / 1 parked, reds `iterT1m` ×2 + `jsonTest baseline` — the
recorded pre-existing set, byte-identical to the pre-pin capture** on every assertion row (the only
diff is `pop.sh`'s own H1 binary-echo header).

---

## PARKED

### F-2 — generator autopsy: the walk visits the new literal attributes
**Reclassified 2026-08-16** from *"ruling owed before the seal"* to **entry task of the resumed
generator campaign**. It is no longer a blocker on anything.
**Where:** the generator walk; visible in `incant/generating` (quarantined).
**What:** `BlocK` reads `length 3` where it read `length 1`, and the walk emits
`runGenerated:  { ;` and `runGenerated:  } ;` — the punctuation reaches the generator as material.
**⚠ THE ANSWERS ARE NOT AFFECTED, and this is the finding that sizes the job:** the five fixtures
still produce `maximus` 11, 26, 26, 26, 26 — byte-identical to the sequence the retired
`oneTest.base` recorded. **Right answers, noisier walk.** So this is a tidiness-and-design question
about what the generator should skip, not a correctness bug.
**Evidence:** `docs/emitted/generating-exhibit-2026-08-16.txt` — the specimen photographed at
admission. An EXHIBIT, not a pin; nothing compares against it.
**Why it stopped being urgent:** Tony's ruling quarantined the generator out of the POP roster
entirely, so no baseline pins it and no grammar change re-attributes rows on it.
**Done when:** the autopsy rules whether the generator skips label-only literal attributes.
**Owner:** the resumed campaign. **Status:** `parked` — deliberately, with a specimen.

### F-3 — `JSONarray`'s guard is an existence test, not a has-a-list test
**Where:** `incant/utilities:74-76`.
**What:** `JSONlist?` is OPTIONAL; the guard is `if JSONlist;`. After a populated array parses, the
node stays truthy while its list does not survive, so a later empty array walks a leaf.
**Evidence:** minimal reproducer is TWO parses and order matters —
`[x,y]` then `[]` **fires**; `[]`, `[] []`, `[x,y]`, `[]` then `[x,y]`, `[x,y] [x,y]` all clean.
Symptom `nextGroup: ERROR JSONlist does not contain a list`. One `pop.sh` red (`jsonTest baseline`).
**Narrowed:** `ruleActions.rtn` is **NOT** the owner — reverted, rebuilt, error persisted. Remaining
space: `Instruct.rtn`, `GroupActions.rtn`, `RuleStuff.twk`, `GroupItem.twk`, `incant/grammar`, HEAD.
⚠ **May be latent-and-newly-exposed rather than new** — the guard has always been existence-only.
Settle that before "fixing" `utilities`.
**Owner:** unassigned. **Status:** `parked Tony` 2026-08-16 — *"not something I want to worry about
now."* **Size:** small if the guard is the fix; unknown if the exposure is.

### F-7 — `opPlusPlus` carries the poisoned-iterator guard twice
**Where:** `Instruct.rtn:887` and `:923`.
**What:** the 2026-08-05 run-time-flag census intended to MOVE `if result.fLAG return 0;` below the
jitting gate. It was **copied**, not moved. `:887` dominates, so `:923` is unreachable, and the
emit-time condition the note calls the danger is still constructable.
**Evidence:** structural, checkable by pointer — nothing between the two lines mutates `fLAG`.
⚠ Whether a poisoned node actually reaches `opPlusPlus` during an emit walk is **causal and unrun**.
**Status:** `parked Tony` — carried in Clay's step-2 brief as a logged candidate, explicitly not to
be chased. **Owner:** Tony.

### F-8 — `aCTionDebuG`'s three stacked directives
**Where:** `groupDirectives`, the three `aCTionDebuG` entries.
**What:** all three are disarmed, so harmless today. Arming **two** would silently fire only the
first — bear-trap #30. Nobody has ever found this out because nobody has armed two.
**Done when:** annotated at the site, or collapsed to one. **Owner:** unassigned. **Size:** comment.

### F-11 — ⚠ TESTING A `BlocK` NODE IN A CONDITION **EXECUTES IT**
**Where:** language-level. Found in `incant/compileProbe`, 2026-08-17.
**What:** `if x;` on an ordinary field is an existence test, which is the documented idiom
(bear-trap #26 exists to push people toward it). **On a `BlocK` node it is not a test — it runs the
block.** So the natural way to ask *"did compile leave a BlocK behind"* answers the question by
performing the action, silently, and a fixture written the obvious way reports success while doing
the one thing the command under test is supposed not to do.
**Evidence, isolated by bracketing every statement with a print (2026-08-17):**
```
  r := compile(codedFour);   print "1 compiled"          -> no marker
  if r;                      print "2 after if r;"       -> no marker   (field: SAFE)
  b := codedFour["BlocK"];   print "3 after subscript"   -> no marker
  if b;                      print "4 after if b;"       -> MARKER FIRES between 3 and 4
```
⚠ **Three earlier controls came back clean and were each MISLEADING for a different reason** —
an uncompiled subject has no BlocK to run, and a sequence with no `if` never reaches the trigger.
The cause was found only by bracketing *every* step. Do not re-derive from the negative runs.
**Why it matters beyond the probe:** this is the one-channel-one-meaning family — `if x;` carries
*does this exist* and *run this and use the result*, chosen by the operand's type, with no marker at
the call site. Anything walking cached bodies (the generator, the jit driver, a DesignDocs walker)
can trip it.
**The workaround, and it is the better assertion anyway:** read a property instead —
`if b.listLengtH;` — which does not execute and yields a **value** rather than a bare truth
(H4). `compileProbe` row B does this and reports `statement count = 3`.
## ✅ RULED 2026-08-17 (Tony): **`if` on a BlocK answers PRESENCE and never executes**, consistent
with every other field. The fix rides any convenient landing; the ruling is what monty-era code
writes against.

### THE CENSUS, run 2026-08-17 — **expected zero customers, found ONE**
**What it matched, stated because a census is an instrument (H9):** every site in **incant source**
(`incant/`, `IncantForms/`) that *obtains* a BlocK node — `["BlocK"]`, `[.BlocK.]`, `.BlocK` — then
each hit read by eye for condition position. **Scope limit, named honestly:** `.rtn`/`.twk` are out
of scope, because `if x` on a `GroupItem*` there is a plain C++ pointer test with no dispatch; and a
BlocK reaching a condition *without* being named (via `argument[1]`, an iterate) would not be caught
by this grep.

| hit | verdict |
|---|---|
| **`incant/jitDrive:32`** `if blok;` | ⚠ **THE CUSTOMER.** Wants existence, gets execution |
| `incant/compileProbe:70` | safe — already uses the `listLengtH` workaround |
| `incant/retProbe:14` | prose quoting `GroupActions.rtn:447`; that site is C++, out of scope |
| `IncantForms/BackupXML/oneTest:57` | assignment not condition, and in a gitignored backup |

**MEASURED, not read:** `jdTarget` is called **once** at the foot of `jitDrive` and prints
**twice** — the second firing is the existence test. Annotated at its post so the next reader does
not hunt a phantom `jitDrive` bug. ⚠ **Deliberately NOT rewritten to the workaround** — it becomes
correct as written when the fix lands, and churn reverted a week later is worse than a comment.

### THE MECHANISM, and the fork it opens
`ruleActions.rtn:717`, in `aCTionIF`: **`if isMethod  result = result.gMethod(result);`** — a
condition value that `isMethod` is *invoked*. A BlocK carries a method, so it fires.

⚠ **BRANCH B IS DEAD, MEASURED RATHER THAN ARGUED.** Removing the invoke entirely (the reading that
matches the ruling's *"consistent with every other field"* rationale) was built and run:
**fleet 40 → 33 green**, `rung5.target` emitted **nothing at all**, `spellScratch` **SIGSEGV 139**.
The invoke is load-bearing for the kant emission path. `ruleActions.rtn` restored byte-exact
(md5 verified), rebuilt, fleet back to baseline.
**So the fix must be BlocK-specific.** How to spell "is a BlocK" at that line is the open question —
registered in `docs/knownErrors.md`'s carry-over payload.
**Owner:** fix is Clod's on any convenient landing, behind the payload row's ruling.

### F-13 — ⚠⚠ THE GENERATED PARSE BODIES ALL ALIAS ONE groupBody
**Where:** `IncantForms/WorkingOn/parser`, `generateParse` — `CodE = codeBuffer;` then
`argument +% CodE;`. **Owner: Tony** (his file, and the fix is his edit).
**What:** the 54-rule `walkRules(Start)` run **certified GENERATION, not INSTALLATION.** Every body
was correct at the moment it printed; every install after the first **overwrote its predecessor's
content through a shared `groupBody`**. The generated text is real. The installed population is
**54 aliases of the last rule written.**
**Evidence (`incant/bodyT`, the exhibit):** two hosts, two distinct nodes, **one** groupBody —
```
BODY  CodE  node=0x102d3b5c0  groupBody=0x102d2a690
BODY  CodE  node=0x102d3b580  groupBody=0x102d2a690
hostA CodE reads: BBBB      hostB CodE reads: BBBB      <- A's content gone
```
**THE MECHANISM, and it is a family not a one-off:** a bare name in an action body reaches **the
search list before any local scope**, so `CodE` is not a local — it resolves to the language's own
persistent `CodE` node. Measured: **identical node address across three separate calls**, no
assignment between them. `CodE = codeBuffer` was never writing a local; it writes through a resolved
name into a shared persistent node, once per call, forever.
⚠ **`+%` IS INNOCENT, also measured** — it *shares* the body, which is correct, and sharing does
exactly what sharing does. The defect is that what gets attached was never a fresh body per rule.
**THE FIX, SPELLING CERTIFIED 2026-08-17 (Tony) — USE `copyOf`, THE HOUSE IDIOM:**
```
        codeCopy <- copyOf(CodE);
        argument +% codeCopy;
```
Copied verbatim from `fillDownAcross` (`incant/utilities:174`), which does this exact job for this
exact reason — one source, many destinations — and from `setFrame`. Then the alias class is
**unconstructable**, not avoided.
**Measured against four spellings** (`incant/mintT`, pointer evidence per row): write-through-the-name
**aliases**; `= new(...)` **aliases AND returns a node tagged with a command name reading 0**;
`<- new(...)` works but hand-rebuilds `copyOf`; **`<- copyOf(...)` is one call, distinct bodies,
correct content.**
⚠ **AND THE UNCOMFORTABLE PART, kept because it is the point:** `copyOf` was already the house idiom
in two places **and was already written in Clod's own project notes as "copyOf stamps (else `+%`
aliases)"**. Documented, in use twice, and the drill still re-derived it from pointers over a full
session. **That is R-3's thesis: when the semantics are unruled, documented knowledge does not reach
the fingers at write time, because the natural spelling does not look wrong.**
**Done when:** `incant/bodyT` **inverts** — differing groupBody addresses and `AAAA`/`BBBB` — and a
re-run of the monty reports **54 DISTINCT bodies installed**, not 54 generated. ⚠ Do not "repair"
`bodyT` when its verdict flips; update the expectation and say which state was measured (H6).
⚠ **GATE EVERY EARLIER "INSTALLED AND RAN" READING THROUGH THIS.** The eleven-rule run's parses
worked because each rule was exercised **near its generation**. Population-scale parsing through the
installed set is **not yet true**.

### F-18 — ✅ CLOSED 2026-08-18 — `parseRule`'s bail arm refuses loudly. ⚠ AND ITS NAPALM CLAIM IS RETRACTED
**Where:** `Generate.rtn:107` — the whole line is `else result = parse(ruleStuff);`, and `result` is
declared `GroupItem code = field[CodE], grup, result;` and **never assigned on that path**. tok's
bare-field resolution bound the call to the last-mentioned field, which is `result`, so the generated
code is:
```
	else	result = result->parse(ruleStuff);       // GroupRules.mm, parseRule
```
`result` is `0` there. **Project memory calls this exact hazard by name** — *"tok bare-field
resolution: last-mentioned wins"* — and `result` became last-mentioned two lines up, at
`if result = field["BlocK"] result = result.gMethod(result);`. The intent is plainly
`field.parse(ruleStuff)`.

**Why it has never fired:** the arm is reached only when a rule has `parseRule` in its `parseMethod`
slot and is **not** yet `isAction`. Nothing in an ordinary run installs a `parseMethod` at all
(F-17b), so the line is unreachable — until a parse walk calls `setParse`.

⚠⚠ **THE NAPALM CLAIM MADE HERE ON 2026-08-18 IS RETRACTED, SAME DAY, BY THE REPAIR ITSELF.** This
row originally read *"this is what the napalm is"*. **It is not, or at least it is not only.** With
the null dereference repaired and `setParse` restored to the walk, the run **still died** — and the
backtrace named a different function, `parseString` (F-19). `parseRule` was **never entered at all**:
zero refusal lines, and no `parseRule` frame in a sample of the hung process.

**The defect on this line is real and is fixed. The mechanism story built on top of it was not
tested before it was written.** Bear-trap #19's corollary in its expensive direction — the
hypothesis survived narrowing and was still wrong, because the search space never contained
`parseString`. What was actually measured, and all that was measured:

| phase 1 calls `setParse`? | before the repairs | after F-18 + F-19 |
|---|---|---|
| yes | **exit 139** in `parseString` | **no crash — a non-terminating parse** |
| no  | walk completes, sweep runs, **sentinel, exit 0** | unchanged |

One thing the original row got right and it stands: an action's body is parsed on its **first
invocation** (`processAction` → `if isCoded && !processCode(action)`), which is why the first action
called after a walk is the first thing to re-enter the parser. `incant/walkPhase`'s phase 0 exists
for that reason and it works.

**⚠ AND THE OBVIOUS FIX IS NOT A FIX.** Writing `field.parse(ruleStuff)` re-enters `GroupItem::parse`,
which forks on `defStuff.parseMethod` and calls `parseRule` again — a crash traded for infinite
recursion. **There is no path back to the interpretive walk once `parseRule` is bound**, which means
the bail arm this line was written to provide **cannot exist**. That is R-2's *"no fallback arm at
all — refuse loudly"* arriving as a mechanical fact rather than a preference.
**RULED AND LANDED 2026-08-18 (Tony): refuse loudly.** The arm is now `reportNoBody(field);` — no
parse call, no fallback — and the rule falls through to the ordinary failure return already at the
foot of the function. `reportNoBody` is a **sibling of `reportCodeFail`, not a reuse of it**: the two
state different facts (*a body failed to parse* versus *there is no body*), and calling the wrong one
would print `ERROR processCode:` for a rule `processCode` never touched, which is an instrument
naming the wrong mechanism. Extern set 302 → 303, one line.
**The comment was rewritten in the same edit, deliberately.** The old one said *"bail to the existing
field parse if no parse code provided"* — the opposite of the doctrine — and a comment that
contradicts its code is how a repair gets undone years later. Intent and mechanics now agree on the
line.
⚠ **The scheduling consequence stands regardless of the retraction above:** binding a parse method
anywhere near a generation walk is gated until the activation phase exists. Off-rule storage
inherits it — **activation is complete, and it is last.**

### F-19 — ✅ CLOSED 2026-08-18 — three of the four `parse*` helpers wrote through a null `label`
**Where:** `Generate.rtn` — `parseAny`, `parseCharacter`, `parseString`. **`parseSet`, four functions
away in the same file, already had the guard** (`if label label.setToken(...)`), so the correct
spelling was sitting beside the wrong one the whole time.
**What:** each wrote the match result into `label` on the SUCCESS path with no null test —
`label.setToken(hereAt,counter)` in two, `label.text = matchedString` in `parseString`. A rule matched
with no label in its frame stores into a null.
**Evidence — a backtrace, not an inference:**
```
stop reason = EXC_BAD_ACCESS (code=1, address=0x0)
frame #0: GroupItem::setText(this=0x0000000000000000, s="if") at GroupItem.mm:2232
```
`s="if"` — the keyword being matched when it died.
**Why it never fired:** same reason as F-18. Nothing in an ordinary run binds a `parseMethod`
(F-17b), so these are reached only after a generation walk calls `setParse`.
**How it was found, and it is the lesson:** by re-running the F-18 negative control **after** the
F-18 repair and finding the crash still there. A repair that does not move the symptom is evidence,
and it was the only thing that took `parseString` out of the blind spot.
**Fixed:** three `if label` guards, copied from the working sibling rather than spelled a fifth way.
Fleet body unmoved (48 green / 1 parked; jitLadder 205 ok / stderr 0 / one owned red).

### F-20 — ⚠ `setParse` WRITES THE RAW `rStuff` ON THE NODE IT WAS PASSED; `parse()` READS `definingRule().rStuff`
**Where:** write side `Generate.rtn`, `setParse` — `RuleStuff ruleStuff = rStuff;`, generated as
`field->rStuff`. Read side `GroupItem.twk:1290-1291` — `definer = definingRule(); defStuff = definer.rStuff;`.
**What:** the two ends of the `parseMethod` slot do not name the same object, on **two** axes — raw
field versus materialised stuff, and the passed node versus the defining rule. So a `setParse` bind
can land somewhere the fork never looks.
⚠ **THIS EXACT DEFECT HAS BEEN PAID FOR ONCE ALREADY, and the receipt is in the tree.**
`genParse.rtn:858` carries it verbatim: *"getRStuff(), NEVER THE RAW rStuff FIELD. The first cut used
`if !rStuff rStuff = new(rule)` and the bind SILENTLY DID NOT TAKE: parse() forks on
definingRule().rStuff.parseMethod, and the raw field is not necessarily the materialised stuff that
fork reads."* `setParse` does both of the things that comment forbids.
**Evidence it is not taking today (indirect but consistent):** with `setParse` in the walk and F-18
repaired, a sample of the hung process shows the **interpretive** walk only —
`parse → testOptions/testAttributes → parse` — with **no `parseRule` frame anywhere**, and
`reportNoBody` never prints. If the bind had taken, one or the other would show.
⚠ **Structural claim, not yet a direct measurement.** The two spellings are read off the source and
the generated code; that the bind fails *for this reason* is inferred. On this project that grading
matters — one probe printing the two pointers settles it, and `genParse.rtn`'s SEAM probe is already
the shape to copy.
**Done when:** the bind is measured, and if it is failing, `setParse` uses `getRStuff()` on the
defining rule like `parseRuleMethod` already does. **Blocks:** any claim about what a walk-bound
parse method does, including the remaining half of F-18's own story.

### F-17 — CAPTURE REGISTER FROM THE F-15 LANDING, 2026-08-18
Eight items, none chased. Four are Clay's from the ruling brief, four were found doing the work.
Each is a row in its own right; grouped only because they were captured in one pass.

**F-17a — `setParse` binding mid-walk changes live routing.** The moment `generateParse` calls
`setParse`, `parse()` starts dispatching that rule through `defStuff.parseMethod` instead of the arm
chain. That is **activation happening during generation**, and it is the napalm's sibling. **Third
customer for off-rule storage + an explicit activation phase.** *Done when:* generation cannot
change routing. **Owner:** with the activation work.

**F-17b — `parseMethod` is dead infrastructure in ordinary runs.** `setParse` has exactly one caller
in the tree (`generateParse`); `setParseMethod` is reachable only through the kant door
(`genParse.rtn:868`) and the `parseMethod=` binding (`:1456`). So `defStuff.parseMethod` is null in
every ordinary run and every rule takes the arm chain — which is what made the F-15 gate a routing
decision rather than a container-parser decision. Goes live with activation work. **Not a defect;
recorded so nobody re-derives it.**

**F-17c — `BrancheS` conformance: is `testOptions` over `break`/`continue`/`return` equivalent to
today's `testMatch`?** One measurement, owed when its turn comes in the pick-one pass. Until then
the F-15 gate keeps `BrancheS` on arm one, so nothing is broken and nothing is proved.

⚠ **F-17c ADDENDUM, MEASURED 2026-08-19 — THE `bin`-IS-AN-ATTRIBUTE PREMISE IS FALSIFIED.**
Instrument: `incant/branchProbe`, which prints the four census columns for a rule and then walks its
attribute list and its member list, printing one line each. The fork as posed was: *`bin` is a
noPrint ATTRIBUTE the census should be ignoring, so the repair is a classifier filter.* **There is no
attribute to ignore.**

| rule | columns | attributes | members |
|---|---|---|---|
| `BrancheS` | `-MD-`, `datA = 3` | **zero** | 3 — `break` `continue` `return`, all `isRulE` |
| `Operators` | `-MD-`, `datA = 3` | **zero** | 57, none `isRulE` |
| `NumbeR` (control) | `A---`, `datA = 0` | 3 — `numberSet` `FloaT` `tokenize` | zero |

**The control is what makes the two zeros mean something** (H4/vacuity): the same loop that printed
nothing for `BrancheS` printed three rows for `NumbeR` in the same run. So the attribute walk is
live and the answer is genuinely empty — `bin` is consumed by `processFlags` at define time and
leaves no attribute behind. **No child trips the classifier. The `D` is on the rule node itself.**

**AND THE STRUCTURAL READING THAT REPLACES IT, measured across all 13 members-shaped rules: the
`-MD-` pair is exactly the two CONTAINERS.** `BrancheS` is a `bin` (`incant/grammar:96`), `Operators`
is a `registry` (`incant/setup:100`); the other **eleven** members-shaped rules carry no data at all.
So the datum is a container property, not a rule-shape choice — which is the same thing the
pre-flight census said from the other side when it warned that routing `Operators` onto `testOptions`
would discard `parseContainer`'s longest-match discipline.
⚠ **NOT MEASURED, and deliberately not inferred:** *what* that `isSET` datum is, and whether
`processFlags` derives it from the members. One probe printing the set settles it; until then the
causal story is unwritten. **The fork's remaining live question is therefore not "filter the census"
but "does pick-one apply to a container at all" — Tony's.**

**F-17d — the false-by-vacancy family.** F-15's shape was: a loop that skips every candidate returns
its initialised `false`, and the caller cannot tell "tested and failed" from "nothing to test".
`testAttributes` (`RuleStuff.twk:336`) was the instance. **Census owed:** other `hasAttributes`-gated
or skip-looping sites with the same shape. **Good minion candidate.**

**F-17e — ✅ CLOSED 2026-08-19, Tony's ruling. `compile` reports and refuses; it no longer exits.**
`Commands.rtn` — `if !processCode(field) exit(1);` became `if !processCode(field) return null;`.
`processCode` had already reported through `reportCodeFail` by the time control reached that line, so
the exit added nothing but the end of the process, and a refusal is now a **value a caller can
tally**. *Verified:* a `runParse(Start)` used to die at the first `ERROR processCode`; it now reports
**six** refusals and keeps going. And the measurement the exit was suppressing is finally
takeable — see the full-population count below. Fleet UNMOVED across the change, canary 303 → 303.

**F-17f — ⚠ A BRACED `else { }` BLOCK IN AN ACTION BODY ENDS THE `define` BLOCK EARLY.** Candidate
bear trap, reproduced and bisected 2026-08-18, **not diagnosed**. Symptom: `RunRulE: expected a
method not <firstActionName>` for every token after the offending action, i.e. the rest of the
define is read as top-level statements. Bisected to the braces alone — the same body with the arm
hoisted into its own action parses clean. Same family as `incant/bothCensus`'s header note
*"no braced block in a body (KANT-40)"*, which records the fact without a cause. **The workaround
that works:** hoist the arm into its own action, or use `if <negated>;` plus an indented block and a
`return`. `incant/walkPhase` is built that way and says why.

**F-17g — the census fixtures print a stray field name in front of every `cerr` row.** `incant/
bothCensus` prints `row  A - quoteBody BlocK`; `incant/walkPhase` prints `quoteBody COMPILING
quoteBody TokenXP`. The columns and counts are unaffected, and both fixtures tally over their own
printed lines, so no measurement is wrong. Cosmetic, but it makes a census log hard to read and it
is almost certainly the sticky-print-default family (project memory: *"tok `print` default is sticky
across externs and files"*). *Done when:* a census row prints its tag and nothing else.

**F-17h — `~/data/support/Include/groups.ext` has been dirty since 2026-08-18 09:57 and is
SUBSTRATE.** 16 added lines: `compile`, `showBody`, `gJitEmitter`/`setJitEmitter`, and ten
`jitEmit*` prototypes — the extern declarations for commands landed over the past week. It is a real
build dependency living **outside this repo** (bear-trap #11), so `git status` here never shows it,
and `pop.sh`'s two-repo tree line is the only thing that does. Every build today, including the F-15
certification, depended on it. Per the kitchen law it stopped being live-task WIP the moment a
baseline was captured over it. **Owner: Tony** (his working copy, support repo).

### F-16 — ⚠ `walkRules(NumbeR)` NEVER WALKS `NumbeR` — a bare name at top level DEREFERENCES through `isGROUP`
**Where:** `IncantForms/WorkingOn/parser:89-95`, the driver calls. Applies to any rule whose data is
a group — `NumbeR` and `ANYtoken` are the two measured.
**What:** a **bare rule name written at top level** resolves through the group indirection and hands
the action the rule's TARGET, not the rule. Measured 2026-08-18, both halves in one run:
```
who(NumbeR)                      arrived as numberSet   hasData          <- a LEAF, no list
ANYorNum["NumbeR"] then who(n)   arrived as NumbeR      hasData len 2    <- the real rule
```
`ANYtoken` behaves the same way and arrives as `NamE`.
**Why it matters, and it is the direct explanation of the 08-18 offline report:** `walkRules(NumbeR)`
printed `numberSet=... CENSUS leaf-install : numberSet` and NumbeR "never got compiled" — because
**NumbeR was never the argument.** The leaf-install was `numberSet` doing exactly the right thing.
The read *"generateParse early-outs because NumbeR has data"* is true of the node that arrived and
says nothing about NumbeR.
⚠ **Scope, so this is not over-claimed:** the deref is at **name resolution**, so descent is
UNAFFECTED — `iterate` and `[]` both hand back the real node (measured above). Only rules named
directly in a driver line are hit. The `walkRules(Start)` census is therefore sound for everything
it reached by descent.
**Consequence for the "pick one" ruling:** the real `NumbeR` carries **data AND a 2-long list**, so
`generateParse`'s own both-present warning is correct and has simply never been reachable from a
bare-name driver call. Whatever way the hybrid bootstrap rules are ruled, the partition assertion
has to run over the walked population, not over hand-typed names.
**Done when:** the driver reaches the real node — e.g. a `walkRules` entry point that takes the
rule by subscript from its registry — and `walkRules(NumbeR)` reports on `NumbeR`.
**Owner:** Tony (his file). **Size:** one call-shape change plus a decision on the hybrid rules.

### F-15 — ⚠⚠ `hasAttributes` SHADOWS `hasMembers` IN `parse()`, SO AN ALTERNATION RULE DIES THE MOMENT IT IS HANDED A BODY
**Where:** `GroupItem.twk:1347-1352` (`GroupItem::parse`) —
```
        if testMatch || onGroup || hasAttributes {
            ...
            if sukcess && hasAttributes                 sukcess = testAttributes(ruleStuff); }
        or isRule && hasMembers                         sukcess = testOptions(ruleStuff);
```
`or` chains the two arms, so **a rule that owns any attribute never reaches `testOptions`.** And
`testAttributes` (`RuleStuff.twk:336`) **skips every `noPrint` attribute** and returns its
`result` local, which stays false when every attribute was skipped. So an alternation rule holding
nothing but noPrint attributes **matches nothing at all**.

**Why the parse walk trips it:** `generateParse` attaches its generated `CodE` with `+%`
(add-attribute) and marks it `noPrinT`; `processCode` attaches the resulting `BlocK` the same way
(`GroupActions.rtn` — `field +% result; result.noPrint = true`). Either one is enough. The rule
stops matching, the parse that was reading the body runs off the end of its input, and the report
is `ERROR processCode: <rule> parse failed / failed at :reached end of input`.

**Evidence, measured 2026-08-18 on Tony's 10:14 binary.** Eleven rules, **an EMPTY body**
(`{ return runRuleAction(this); }`) so the body text cannot be the variable, one process each:

| shape | rules | outcome |
|---|---|---|
| attributes | `QuotE` `StringXP` `TokenXP` `Braced` `BlocK` `Iterate` `Xpress` | **ok 7/7** |
| members | `ANYorNum` `StatemenT` `WardeD` `InvokeArg` | **FAIL 4/4** |

⚠ **Two attractive causes were tested and FALSIFIED first**, and neither is the mechanism:
`OR`-vs-`AND` (forcing the conjunct to `AND` on `ANYorNum` fails identically), and `compile`'s
`code +% grup` stealing or re-affiliating the shared member nodes (dumped before and after — the
members are untouched).

**Negative control (H7), and it is the row that makes this a finding rather than a correlation:**
`IncantForms/WorkingOn/altShadowT`. It hangs **one noPrint attribute** on `ANYorNum` — no body, no
`compile`, no `isCodeD` — and the very next *invocation* in the file cannot be parsed:
```
A  poisoned ANYorNum with one noPrint attribute -- row B must now fail to parse
RunRulE: expected a method not rowB
```
⚠ Its row B must be an **action call with an argument**, not a `cerr`. A first draft used `cerr`
and **parsed clean under the poison**, which would have read as the defect being absent —
`ANYorNum` sits under `TokenXP` and is reached only when a name is followed by an invocation
argument. Match the probe to the path.

**Why this is bigger than one defect:** it means **no generated body can be attached to any
member-shaped grammar rule** by the current spelling, and a successful `processCode` re-poisons the
rule with its `BlocK` even if the `CodE` problem is dodged. **Phase 1 of a generate-then-compile
split would therefore poison every alternation rule in the grammar before phase 2 ran.**

**Done when:** Tony rules on where a generated body lives for an alternation rule, and
`altShadowT` **inverts** — row B parses and the sentinel prints. Candidates, his call:
(a) make the alternation arm reachable — test `isRule && hasMembers` first, or teach the guard to
mean *has a non-noPrint attribute*; (b) hold `CodE`/`BlocK` off the live rule until an explicit
activation phase (this is the loader-separation item, and it now has a second paying customer);
(c) rule that a rule is sequence-or-alternation and never both, and store the body somewhere the
parse never walks.
⚠ **(a) has grammar-wide blast radius** — it changes the match order for every rule that owns both
attributes and members — so it wants a fleet-unmoved capture before and after, not a spot check.
**Owner:** Tony (ruling), then whoever implements. **Evidence is complete; no re-derivation owed.**

#### ⚠ PRE-FLIGHT CENSUS FOR THE GUARD REORDER — RUN 2026-08-18, AND IT IS **NONZERO**
Instrument: `incant/shadowCensus` (extends `incant/bothCensus` with a data and a group column,
because the reorder bypasses **testMatch and onGroup**, not only `testAttributes` — a census of
attributes alone would have cleared the edit on incomplete grounds). 79 rules, Grokking:

| A M D G | count | reorder impact |
|---|---|---|
| `A---` attributes only | 40 | none |
| `--D-` data only | 17 | none |
| `-M--` members only | 11 | **this is what the reorder repairs** |
| `----` | 6 | none |
| `A-D-` attributes + data | 3 | none — no members |
| **`-MD-` members + data** | **2** | ⚠ **AT RISK** |

**Zero rules own both attributes and members** (confirms `bothCensus`). The two at-risk rules are
**`BrancheS`** (`grammar:96`, `bin`, members `break`/`continue`/`return`) and **`Operators`**
(`grammar:119`, the operator registry used as an alternative of `Token`).

**Why they are genuinely at risk rather than nominally.** Both carry data and NO attributes and are
not groups, so `testMatch` is the only thing in arm 1 that can make either succeed — and both
demonstrably do succeed today (`pop.sh`'s `loopBranchT` parses `break`/`continue`; every expression
in the fleet parses an operator). After the reorder, a members-shaped rule takes `testOptions` and
**never reaches `testMatch`**, so both would be re-routed onto an alternation walk over their
members. For `Operators` that also discards the registry's documented **longest-match** discipline,
which `parseContainer` implements and `testOptions` does not.

⚠ **AND THE ROUTE THAT WOULD HAVE SAVED THEM IS NOT INSTALLED.** `setParse` — which is what would
give a bin or registry `parseContainer` — has **exactly one caller in the whole tree**, and it is
`generateParse` in `IncantForms/WorkingOn/parser`. The other door, `setParseMethod`, is reached only
through the explicit kant/`parseMethod=` binding (`genParse.rtn:868`, `:1456`). So in an ordinary
run `defStuff.parseMethod` is null and **every rule takes the arm chain**, exactly as `parse()`'s
own comment says. Containers are not protected by having a container parser; they are protected
today **by the very ordering the reorder inverts**.

**What this hands back to Tony (order-of-operations step 4 says list, do not edit):**
1. The reorder as spelled needs an exclusion for containers — `isRule && hasMembers && !binTypE`
   and something for `isREGISTRY` — or
2. the narrower repair of the same defect: leave the arm order alone and make the guard mean **has
   a non-noPrint attribute**. That is the false-by-vacancy repair in its own terms, and it moves
   **nothing** in this census — both at-risk rules have no attributes at all, so their guard value
   is unchanged — while still letting a poisoned alternation rule reach `testOptions`. Or
3. rule 2 (pick-one) FIRST: `BrancheS` and `Operators` are themselves data-plus-structure hybrids,
   so splitting them removes the ambiguity rather than working around it. On this reading the
   pick-one conformance pass is a **prerequisite** for the reorder, not a follow-on.

**Baselines banked on the bare binary before any edit** (`tok GroupRules.twk` with no directives
file, canary `302 -> 302`, rebuilt 11:31): fleet **40 green / 1 parked**, reds `iterT1m` x2 +
`jsonTest baseline`; jitLadder **205 ok, stderr 0, one owned red (JV/F-12)**. Both match the
2026-08-17 seal exactly.

#### ⚠⚠ PHASE-ONE SHADOW CENSUS — RUN 2026-08-19, AND IT PRICES THE (b) PULL-FORWARD AT **ALL OF IT**
Instrument: `incant/phaseProbe` (Tony's ruled next measurement, banked 2026-08-18). Same four
columns as the pick-one census, read **twice in one process** — once on the clean tree, once after
the two-phase walk — so a rule whose shape changed is a printed difference rather than an argument.
Run on the 2026-08-19 09:09 bare binary. Exit 0, sentinel present, **56 bodies generated**.

**INSTRUMENT CHECK FIRST, and it is the reason the numbers below are readable.** The probe emits a
warm-up S2 block while the tree is still clean; it must agree with S1 row for row, or the two shape
readers do not read the same thing and every conclusion is about the readers. **79 rows, AGREE.**

**THE FLIPPED SET — 11 of 79 rules are reclassified by phase one:**

| flip | count | rules |
|---|---|---|
| `-M--` → `AM--` | **8** | `ANYorNum` `ElsE` `GrouP` `InvokeArg` `LoopRestrict` `StatemenT` `Token` `WardeD` |
| `----` → `A---` | 3 | `DEFINing` `PRINTing` `tokenize` |

⚠ **The eight are F-15's poisoned shape exactly** — a members-only alternation rule acquiring an
attribute, which is the thing that stops it matching. Zero rules owned both before the walk, so
**every one of the eight is a hybrid CREATED by generation**, not one that was already there. The
three `----` rules are harmless: no members to shadow.

**AND THE HALF THAT PRICES IT. The intersection with the rules the parser needs in order to read a
code body is TOTAL: 11 of 11 flipped rules are reachable from `BlocK`; ZERO fall outside.** The term
graph is emitted from the clean tree (275 edges over 79 rules) and the reachability is computed in
the shell where it can be checked by eye.

**What that settles:** there is no subset of the grammar that phase one damages harmlessly. Deferring
off-rule storage behind phase two is not available, because phase one reclassifies rules phase two
needs — all of them. **This is the measurement F-15 option (b) was waiting on, and it comes back
in favour of (b) being done FIRST, not last.** *Done when:* Tony rules. **Owner:** Tony.

### F-23 — `NamE` HANGS UNDER A ONE-PHASE COMPILE AND REFUSES CLEANLY UNDER A TWO-PHASE ONE
**Where:** reproducer installed as `runNamE` in `IncantForms/WorkingOn/parser` — swap the driver line
at the foot to `runNamE(NamE);`. It hangs at a labelled `cerr`, so the last line printed names the
statement.
**Measured 2026-08-19**, five configurations, bare `compile` throughout (no `:=`, per F-22):

| configuration | NamE |
|---|---|
| standalone, no prefix, driver frame | **137 hang** |
| standalone, no prefix, walk's own call path | **137 hang** |
| after an 18-rule TokenXP prefix, either frame | **137 hang** |
| after the FULL 30-rule TokenXP prefix | **137 hang** |
| inside `incant/walkPhase`'s **two-phase** run | **refuses cleanly** — `ERROR processCode: NamE parse failed`, run completes exit 0 |

⚠⚠ **THE PHASE READING ABOVE IS RETRACTED, SAME DAY, 2026-08-19. THE DISCRIMINATOR IS `setParse`.**
The table's last row differs from the other four by **one call**, and it is not the phase split: the
parser's `genParseTest` calls `setParse`; `walkPhase`'s `wpGen` **does not**. Two controls, run as a
pair:

| run | result |
|---|---|
| `runNamE(NamE)` — genParseTest **with** setParse | **137 hang** |
| `runNamEnoParse(NamE)` — identical, setParse **suppressed** | **exit 0, completes** |
| `walkPhase` as committed (no setParse) | 56 clean refusals, sweep finishes |
| `walkPhase` with setParse **added** to `wpGen` | ⚠ **HANGS ON ITS FIRST SWEPT ITEM** (`StatemenT`), zero refusals reported |

**So it is not NamE, and it is not the population.** I attributed the difference to Ruling 4's
two-phase split; the two-phase arm simply never armed the rules. **Structural claims on this project
hold and causal ones fail — this was a causal one, and it is the sixth.**

⚠⚠ **THE HANG NO LONGER REPRODUCES — MEASURED 2026-08-26, AND THE SENTENCE IS THE LABEL SEAM.**
A full walk over `Start` with activation ON now **completes at exit 0 with its sentinel reached**:
42 refusals, 68 leaf-installs, 22 already-coded. The crib this row was written against predicted six
refusals and then a hang. The change it follows is the label seam closing on 2026-08-25 (`d28cd7d`);
nothing in the parser form was touched between the two measurements except the rename.

**The tables above are NOT rewritten** — they record what was run, under the names it was run under.
`genParseTest` is now **`generateParse`**, and the two reproducers named in the second table
(`runNamE`, `runNamEnoParse`) **retired 2026-08-26**; their provenance is in DesignDocs under
`KantParser` → `KantParserHangHistory`.

⚠ **`setParse` SURVIVES AS A GATE, FOR A DIFFERENT REASON THAN THE ONE THAT MINTED IT.** The toggle
is now `activating` and it is **not** a hang control any more. Re-measured 2026-08-26, both arms
completing:

| activation | refusals | leaf-installs | refusal positions |
|---|---|---|---|
| **OFF** | 37 | 60 | every refusal names where it stopped |
| **ON** | 42 | 68 | **36 of 42 collapse to `reached end of input`** |

So it changes the population reached **and** the legibility of every refusal. It is kept as a
measurement-quality gate of the `compiling` family. *Status:* **the hang is discharged; the gate is
retained on new grounds.* **Owner:** Tony, on review.

⚠ **AND THE MECHANISM WAS IN WRITING BEFORE IT WAS MEASURED**, which is the only reason a reading is
offered at all. `setParse` binds `parseMethod = parseRule` (`GroupRules.mm:12200`, one-shot behind
`if (!parseMethod)`), and `parseRule` reads the rule's own `CodE` (`:9949`). So compiling an armed
rule's body re-enters that rule through its own generated parse. **F-17a** already called setParse
during generation *"activation happening during generation"*, and **F-18**'s ruling already recorded
that `field.parse(...)` *"trades crash for infinite recursion through the parseMethod fork"*. A hang
is what that predicts. ⚠ **NOT MEASURED and not claimed: the recursion itself.** Breakpoints B9/B10
in the parser crib are aimed at exactly that — the same tag repeating in `parseRule` is the loop.
**Done when:** ruled. **Owner: Tony**, in Xcode — and the texture differs from F-22's: a hang gives no
crash frame, so the question is what is *cycling* when the process is interrupted.

### F-25 — the provenance exhibit came back NEGATIVE: hand-defined and walk-installed BOTH compile
**Where:** `IncantForms/WorkingOn/parser` — `runTokenHand(tokenHandSubject)` and
`runTokenWalked(Token)`, built 2026-08-19 to the brief.
**Expected:** hand compiles, walked refuses — provenance as the discriminator behind the 56/56.
**Measured: both compile, exit 0, both sentinels.** So **provenance is not the discriminator**, and
the confound the pair carried (hand side a plain field, walked side the live grammar rule) never had
to be resolved. ⚠ Note what it does NOT say: `Token` **does** refuse inside `walkPhase`'s sweep. Same
rule, same install path, opposite verdict — and the difference between those two runs is `setParse`
again (see F-23), not how the body was authored.
**Kept in the file** as a negative exhibit and as the control for the setParse pair.
**Owner:** none — this row is a result, not a task.

### F-24 — `compile` returns the FIELD for an UNCODED subject, so a sweep cannot tell compiled from never-coded
**Where:** `Commands.rtn` — `if !field.isCoded goto endCompile;` and `endCompile: return field;`.
**Evidence:** `incant/compileProbe`'s own negative control, row **C**, prints
`C ???? compile returned a field on an UNCODED subject -- rows A and B discriminate nothing`. It has
been saying so on every run; it is not in `pop.sh`, so nothing was watching.
**Why it matters more after F-17e than before:** the return value now carries a verdict — `null`
means *refused* — so a third meaning (*there was nothing to compile*) is riding on the same channel
as *compiled fine*. One channel, two meanings.
⚠ **Scope, so the count below is not over-doubted:** it does **not** touch the 56/56 figure. Every one
of those 56 was marked `isCoded` by phase one, so none took the uncoded path.
**Done when:** an uncoded subject returns null, and compileProbe row C goes green.
**Owner:** unassigned. **Size:** one line plus a comment. **Good minion candidate.**

### F-22 — ⚠⚠ CAPTURING `compile`'s RETURN WITH `:=` CRASHES THE PROCESS, AND IT FAKED AN ENTIRE INVESTIGATION
**Where:** any fixture writing `x := compile(field);`. Was in `incant/row8T` and in `incant/bisectQ`'s
driver-frame arm; both now use the bare `compile(field);` that `walkRules` has always used.
**The measurement, one variable, 2026-08-19:**

| statement | QuotE, no prefix |
|---|---|
| `bqTarget := compile(argument);` | **exit 139** |
| `compile(argument);` | **exit 0, sentinel** |

Same rule, same generated body, same stack frame, same binary, nothing else changed.

⚠ **WHAT IT COST, AND THIS IS WHY IT IS A ROW RATHER THAN A NOTE.** It produced a complete, coherent,
entirely false finding. `row8T` reported `QuotE` 139 (2/2), `NamE` 137, `tokenize` 139, `GrouP` clean
— read as *"members-shaped rules compile, attribute-shaped rules crash"*, which is plausible, matches
the project's known fault line, and is **wrong**. Re-run with the bare call: **`QuotE` exit 0,
`tokenize` exit 0, `GrouP` exit 0.** Two of the three crashes were the capture.
**The `GrouP` row is what made it convincing** — one green row in the matrix reads as proof the
instrument discriminates, when it only proved this defect is not universal.

**RETRACTED BY THIS ROW:** row8T's crash matrix, and with it the "QuotE compiles inside the walk but
crashes alone" order-dependence lead. **There is no order dependence.** Measured: `QuotE` compiled
through the walk's own call path with a **zero-rule prefix** passes, and with the full 18-compile
prefix from the driver frame crashes — the prefix was never the variable. The walk passed because
`walkRules` calls `compile(argument);` bare; every crashing probe captured the result.

**STANDING:** `NamE` still **hangs (137)** with the bare call, killed at 45s and at 150s. That one is
real and survives the correction. **Not investigated further** — it is the offline walk's territory.
**Candidate bear trap, symptoms only, NOT diagnosed** — same family as #3 (`:=` stamps `byRef`
permanently on its argument), but that a `:=` capture of a **command return value** segfaults is a
symptom and no mechanism is claimed here.
**THE TREE-WIDE SWEEP, 2026-08-19 — four other sites, LISTED AND UNTOUCHED per the brief:**
`incant/enumT:53` · `incant/walkPhase:129` · `incant/compileProbe:65` · `incant/compileProbe:75`,
all of the form `x := compile(...)`. ⚠ **None of them currently crashes** — all three files run to
exit 0 today — so this is a latent list, not a breakage list. `walkPhase` was cross-checked directly:
re-run with `=` instead of `:=` it returns the **identical** verdict (56/56), so its census figure is
not an artifact of the capture.
⚠ **Deliberately NOT on this list: `:= new(...)` and `:= copyOf(...)`.** Those are the sanctioned mint
idiom — `:=` exists so the argument's tag survives (bear-trap #1) — and there are ten of them in
`incant/generate` alone. The suspect shape is a **command return**, not `:=` itself.
**Done when:** either the mechanism is ruled, or a trap entry says do not capture a command's return
with `:=`. **Owner:** unassigned.

### ⚠ PRE-FLIGHT FOR THE CONTAINER RESHAPE — RUN 2026-08-19, AND THE READER COUNT IS WRONG
**Direction (Tony's, pre-work only, no edit authorized):** the bins' `D` is the character set read
through `inSet`; make it a labelled attribute on the NumbeR-reshape pattern, `-MD-` goes 2 → 0, and
pick-one holds without amendment.

**THE GREP WAS ASKED FOR TWO READERS AND FOUND FIVE, AND THE FIFTH IS A WRITER.**

| # | site | what it does with the set |
|---|---|---|
| 1 | `parseContainer` — `Generate.rtn:85` | reads (named in the direction) |
| 2 | `testContainer` — `RuleStuff.twk:386` | reads (named in the direction) |
| 3 | **`containerTo`** — `RuleStuff.twk:577` | reads — the LABELLED-container road added for genParse (IA-0/CT). **Not named.** |
| 4 | **`setGuard`** — `GroupItem.twk:500` | `if isSET { guardSet = characterSet; guarded = true; }` — **a bin's GUARD IS its set** |
| 5 | ⚠⚠ **`addGroup`** — `GroupItem.twk:80-86` | **WRITES it.** `if binType { PLGset binGuard = guardSet; set((int)*group.tag); binGuard = characterSet; setSimple(group.tag); }` |

⚠ **ROW 5 CHANGES THE SHAPE OF THE JOB, and it also answers a question left open on 2026-08-19
morning** (*what IS that isSET datum, and does `processFlags` derive it from the members?*).
**The set is not authored anywhere. It is DERIVED, incrementally, at add-member time** — every
`addGroup` onto a bin folds that member's first character into the set. So "move the set to a
labelled attribute" is not a data-placement edit:
- either **`addGroup` must be taught to write into the attribute** — and `addGroup` is core
  bootstrap machinery on every add in the system, so that is blast-radius work, not a reshape; or
- the set stops being maintained and becomes **hand-authored**, in which case it goes stale the
  first time a member is added to a bin and nothing says so.
**Neither is what the direction assumed.** Row 4 compounds it: the same set is the rule's guard, so
moving it moves guarding too.

**THE POSITIVE CONTROL — and the premise "the fleet won't certify this either" is HALF WRONG,
measured over the 19 fixtures `pop.sh` runs.** Unlike the float reshape, where fleet coverage was
genuinely **zero**, container membership is covered by value:

| what | fleet coverage |
|---|---|
| `BrancheS` membership | **covered** — `loopBranchT`, presence-with-value: break → **3**, continue → **12** |
| `Operators` symbol longest-match | **covered** — `==` ×13, `++` ×20, `:=` ×6, `&&` ×5, `+=` ×3, `!=` ×2, `>=` ×1. Each is a multi-char operator whose first character is itself a registered operator, so a longest-match regression goes red in 13 places at once |
| `Operators` word forms | partial — `AND` ×12, `IN` ×4, `OR` ×1, `GO` **0** |
| **the documented failure mode** | ⚠ **NOT COVERED** |

**What a new control must add, and it is the `--g` disease `testContainer`'s own header describes:**
*"any container holding both a symbol and a word can produce it"* — the scan builds a set-based span,
finds no entry, and the whole match fails rather than backing off.
1. **zero-coverage prefix pairs:** `||`, `<=`, `>>`, `<<`, `:+` — all **0** occurrences in the fleet.
2. **word-beside-symbol:** `AND`/`OR`/`IN`/`GO` adjacent to `&`/`|`, which is the exact stated flaw.
3. **a `BrancheS` member as the prefix of a real identifier** — a *code* identifier named e.g.
   `returnValue` or `breaker`. The fleet has none; the six hits for that pattern are all prose in
   fixture headers.
**Done when:** those three rows exist, green, BEFORE any edit — and row 5's decision is made, because
it decides whether this is a reshape or a change to `addGroup`. **Owner:** Tony (ruling), then whoever
implements. **No edit made.**

### F-21 — `walkRules` prints a null through `appendString` on the five new `FloaT`/`PoweR` terms
**Where:** `IncantForms/WorkingOn/parser`, `walkRules`' `print ~$taG "=" argument;` line. The message
comes from the SUPPORT repo, `Frame/Buffer.C:202` (`Buffer: ERROR no text passed into
appendString`), so it is out of this repo (bear-trap #11) and will not appear in any grep here.
**What:** four copies on every `TokenXP`/`Braced` walk, one immediately after each of
`CENSUS leaf-install : point | decimals | e | sign`. The five terms of `FloaT` and `PoweR` are the
only leaves that do it — `numberSet`, `tik`, `quoteBody`, `leftBrace`, `pound`, `stuff`,
`rightBrace`, `leftParen`, `rightParen` and `ANYtoken` all leaf-install silently.
**Evidence it is NEW, with the control:** zero occurrences on the pre-pick-one binary
(`git checkout 1f39bac -- GroupMain.{twk,mm}`, rebuilt, same driver file — `grep -c` returns 0 for
both the `Braced` and `TokenXP` walks). It appears because pick-one made `FloaT` and `PoweR`
WALKABLE: they used to carry rule-level data, so `generateParse` leaf-installed them and never
descended, and their terms were never reached at all.
⚠ **Cosmetic as measured, and that is a claim about today only.** The walk completes, the sentinel
fires, and `FloaTCodE`/`PoweRCodE` come out correct. It is stderr noise, not a failed generation.
**Done when:** a leaf whose data is an inline character or character-set prints its data or prints
nothing, rather than handing a null to `appendString`.
**Owner:** unassigned. **Size:** one print site. **Good minion candidate.**

### F-14 — the walk has four SILENT exits; there is no skipped-rules list
**Where:** `parser` — three `continue` gates in `walkRules`, plus `generateParse`'s `datA != 0`
early return.
**What:** the `Start` run shows **147 ENTERs, 54 generated, 21 refused-by-name — and 72 unaccounted.**
Nothing failed to compile (zero `ERROR processCode`), and the refusals ARE named, but the 72 that
entered and produced nothing say nothing about why.
**Why it matters:** this is the constraint already ratified for Ruling 3 — *a walk that prunes must
say what it skipped* — and it is what stands between a subtraction and an actual coverage census.
**Done when:** each of the four exits emits one `cerr` naming the rule and the reason.
**Size:** four lines. **Good minion candidate**, and it yields a trustworthy empty-condition list as
a side effect (the current one cannot be extracted — interleaved `printToBuffer` output defeats
line-tracking).

### F-12 — the jit ladder is RED at rung JV, and has been
**Where:** `jitLadder/ladder.sh`, rung **JV**.
**What:** `FAIL JV VACUITY GUARD: a value was not captured at all (jitted='0' oracle='')`. The
oracle capture comes back **empty**, so the guard fires — correctly. The guard is doing its job;
what it is reporting has not been diagnosed.
**Evidence:** measured 2026-08-17 against **`HEAD`'s own copy** of the ladder (`git show
HEAD:jitLadder/ladder.sh`), so it is **not** introduced by the step-2 rungs — those add ok rows
and no failures (181 → 191 ok on wiring, failure set identical).
**VINTAGE, bounded 2026-08-17 by one look rather than a dig** — and it is older than it looked:
  - the vacuity guard itself was introduced **`1698377`, 2026-08-04** (*"Rung JC wired, the ladder's
    four evaporated checks restored, JV closes a candidate"*)
  - checked out and run at **`3483167`, 2026-08-11** — the previous commit to touch this file before
    today — **JV was ALREADY RED with the byte-identical message.**
  ⚠ So the red has been standing **at least since 2026-08-11**, across every seal since, unnoticed
  because the ladder was not on the seal roster. That is the argument for putting it there, which
  happened the same day.
⚠ **Note what JV is for**, because it makes the red more interesting rather than less: JV's rows A
and B expect `0`, which a result slot that merely defaults to zero also yields, and row C wants **4**
so the rung cannot pass vacuously. The vacuity guard exists so the rung cannot compare nothing to
nothing. **It is currently the thing firing.**
**Done when:** the empty oracle capture is explained — either the fixture stopped printing the line
the regex reads, or the interpreted leg genuinely produced nothing — and JV is green or pinned with
a sentence.
**Owner:** unassigned. **Size:** one fixture read plus one run. **Good minion candidate.**

### F-10 — in `Parse`, a bare retok SILENTLY DELETES committed debug support (found closing F-5)
**Where:** `InProcess/Parse` — `plgDirectives`, and the committed `PLGrule.C`, `Alternative.C`,
`Element.C`.
**What:** `plgDirectives` is **not** purely ephemeral instrumentation the way `groupDirectives` is.
Some of its entries generate **flag-gated** debug support — `if ( state->debugRulePLG || debug )` —
and **that generated code is what is committed**. A bare `tok PLGrule.twk` therefore deletes it.
**Evidence, measured 2026-08-17:**
  - `plgDirectives`' `#PLGrule match return before active` entry emits
    `cout "PLGrule: " name " GUARD-REJECTED at offset " ...`, and that is `PLGrule.C:143-145`.
  - `grep -c GUARD-REJECTED` → **PLGrule.twk: 0 · PLGrule.C: 1.** Same shape in `Alternative`
    (`elem[` → twk 0 / .C 2, at `:98` and `:113`) and `Element.C:26,40,438`.
  - All three files are **clean against HEAD**, so the instrumented form IS the committed baseline.
⚠ **THE TRAP IS THAT THE CORRECT INVOCATION IS PER-FILE AND THE FILE DOES NOT SAY WHICH.** Closing
F-5 needed the *opposite* answer for `PLG.C`: its injections were ~13 **unconditional** `::printf`
floods, so bare was right and regenerating stripped them. For `PLGrule.C` bare would be a silent
loss. **One repo, one directives file, opposite correct commands, no marker at either target.**
**Why this is not just Groups bear-trap #23 again:** #23's cross-annotation discriminates *normal
build* from *hunting*. Here both files are normal builds and the discriminator is **which file**.
**Done when:** either (a) Parse's `CLAUDE.md` states which `.twk` are tok'd WITH `plgDirectives` and
which bare — the `#PLGrule` / `#Alternative` / `#Element` sections vs the rest — or (b) the gated
trace is promoted into the `.twk` sources so every retok is lossless and `plgDirectives` goes back
to being purely ephemeral. **(b) is the structural fix**; (a) is a discipline, and disciplines get
audited.
**Owner:** unassigned. **Size:** (a) doc paragraph. (b) move ~11 gated blocks into 3 `.twk`, then
verify by a bare retok producing a byte-identical `.C`. **Good minion candidate** — (b) has a
built-in verification: if the retok diff is empty, the move was complete.

---

## CLOSED — kept one cycle for the trail

### F-5 — ✅ CLOSED 2026-08-17 — all three hunks disposed, both repos clean
**Verdicts ratified by Tony**: the May-31 dirt was old work needing closure, not fresh intent.
| hunk | verdict | outcome |
|---|---|---|
| `Parse/PLG.twk` — `.act` bodies → `state.attachActions(content)` | **commit** | `1e4c738`, pushed |
| `Parse/PLG.C` | **regenerate bare, don't commit as found** | it carried ~13 unconditional `::printf` traces, all directive-injected |
| `Tokf/Name.h` | **delete** | 0 bytes, `file` reports *empty*, zero references anywhere |
**The `PLG.C` half is the part worth keeping.** The working copy was an **instrumented artifact
left behind a measurement** — every trace line mapped to an `active` entry in `plgDirectives`
(`BlockplgAct`, `ElementTypeplgAct`, `ForwardDeclplgNow`, `IncludeplgNow`, `RuleplgNow`,
`RuleOptionplgAct`, `AlternativeplgAct`, `ElementplgAct`, plus the `#PLG process` block dumping the
rules table after every parse). Committing it would have put an unconditional debug flood into the
normal build.
**Three predictions registered before the regen ran, all held exactly:** regen vs the instrumented
copy = pure deletion of the 13, **no `+` side at all**; regen vs HEAD = exactly the `attachActions`
hunk (branch swap · `char *tail` pruned · two trailing tok-warning lines); `PLG.h` byte-identical
(bear-trap #5 watch — no `#include`s lost). `tok` is dated **Nov 10 2024**, the same binary that
produced the working copy, so no tok drift was in the test.
**The change resolves:** `attachActions` declared `PLGparse.h:63`, defined `PLGparse.C:188`, and
tok's own warning block is the witness — `parseActDeclarations(char*)` dropped off *"referenced but
not declared"*. Not built, not run; nothing downstream waits on PLG.
⚠ **It also turned up F-10 above**, which is the general form of the same hazard.

### F-1 — ✅ CLOSED 2026-08-16 — and the fix was NOT where the row said
**The row blamed `auditRStuff`'s guard. The guard was innocent.** `aCTionParens` only cleared its
node when an ExpressioN was present, so an empty `()` returned the Parens node untouched — which
after the labelled-literals change carries `leftParen`/`rightParen` as attributes where it
previously carried nothing. What reached `audit()` was therefore the `rightParen` literal
(`data=13`, isSTRING) instead of the `InvokeArg` node the guard tests for.
**Fix:** `ruleActions.rtn`, `aCTionParens` clears unconditionally, mirroring `aCTionBraced` which
always did. Two lines. `auditRStuff` unchanged.
**Verified:** `AUDITPROBE arg= InvokeArg argdata= 0` — the shape the guard expects — and the
all-registries line returns. Fleet 38 → 39 green.
**And it answered the question that opened it:** the rStuff populations were unmeasured, not
moved — and once measurable, **missing terms went 12 → 0**. Tony's `aCTionDefinE` change closed
that population by construction. Re-pinned with the twelve named in `pop.sh`.
⚠ **Blast radius accepted knowingly:** every `()` in the language goes through `aCTionParens`, so
this touches every no-argument command call. Fleet unmoved apart from the intended row.
⚠ **The class survives the instance and is worth keeping:** a **tag comparison used as a sentinel**
is fragile against grammar edits. This one happened to be repairable upstream, so the guard stays.
The next one may not be.

- **`jitMethod` name collision** — the op-node slot would have collided with `rStuff.jitMethod`
  (compiled body of a field's method). **Closed by Clay's ruling: the slot is `jitEmitter`.**
- **Unary ops unreachable from an `operateMethod`-adjacent slot** — every unary op installs via
  `ruleMethod=` into `method`/`isMethod`. **Closed by Clay's ruling: the slot sits beside the
  BINDING, both families carry it.**
- **`Aside/` and `BackupIncant/` generating permanent untracked noise** — CLAUDE.md claimed they
  were gitignored and they were not. **Closed `b1482ff`, `2364b05`; the claim is now true.**
