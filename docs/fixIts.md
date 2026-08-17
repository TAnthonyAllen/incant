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
**Done when:** ruled — either `if` on a BlocK is defined to be an existence test like every other
field, or the executing behaviour is deliberate and gets named at the sites that rely on it.
**Owner:** unassigned; needs a ruling before anyone "fixes" it. **Size:** ruling first, then small.

### F-12 — the jit ladder is RED at rung JV, and has been
**Where:** `jitLadder/ladder.sh`, rung **JV**.
**What:** `FAIL JV VACUITY GUARD: a value was not captured at all (jitted='0' oracle='')`. The
oracle capture comes back **empty**, so the guard fires — correctly. The guard is doing its job;
what it is reporting has not been diagnosed.
**Evidence:** measured 2026-08-17 against **`HEAD`'s own copy** of the ladder (`git show
HEAD:jitLadder/ladder.sh`), so it is **not** introduced by the step-2 rungs — those add 10 ok rows
and no failures (181 → 191 ok, failure set identical).
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
