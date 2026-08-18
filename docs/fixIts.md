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
**Where:** `IncantForms/WorkingOn/parser`, `genParseTest` — `CodE = codeBuffer;` then
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

### F-18 — ⚠⚠ `parseRule`'s BAIL ARM DEREFERENCES A NULL, AND IT IS THE NAPALM'S MECHANISM
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

**⚠ THIS IS WHAT "THE NAPALM" IS.** The standing description — *"once the generated methods install,
the parser can no longer read the source that follows; not `cerr`, not a registered action, not
`stop()`"* — has been carried as a mystery since 2026-08-17. It is this line. Measured 2026-08-18
with `incant/walkPhase`:

| phase 1 calls `setParse`? | outcome |
|---|---|
| yes | **exit 139** at the first action invoked after the walk, with no output from inside it |
| no  | walk completes, census reports, sweep runs, **sentinel reached, exit 0** |

The reason the failure looks like "the loader was eaten" is that an action's body is parsed on its
**first invocation** (`processAction` → `if isCoded && !processCode(action)`), so the first action
called after the walk is the first thing to re-enter the parser and die. Nothing was eaten; one
pointer was null.

**⚠ AND THE OBVIOUS FIX IS NOT A FIX.** Writing `field.parse(ruleStuff)` re-enters `GroupItem::parse`,
which forks on `defStuff.parseMethod` and calls `parseRule` again — a crash traded for infinite
recursion. **There is no path back to the interpretive walk once `parseRule` is bound**, which means
the bail arm this line was written to provide **cannot exist**. That is R-2's *"no fallback arm at
all — refuse loudly"* arriving as a mechanical fact rather than a preference.
**Done when:** Tony rules what the arm does. The standing ruling points at refuse-loudly — report
through `reportCodeFail` and return 0 — but it is his call, and the comment above the line
(*"bail to the existing field parse if no parse code provided"*) records an intention that the
architecture has since removed. **Owner: Tony** (ruling), then a one-line change.
⚠ **Whatever it becomes, it is a precondition for `setParse` running anywhere near a walk**, so it
gates the activation phase and therefore option (b).

### F-17 — CAPTURE REGISTER FROM THE F-15 LANDING, 2026-08-18
Eight items, none chased. Four are Clay's from the ruling brief, four were found doing the work.
Each is a row in its own right; grouped only because they were captured in one pass.

**F-17a — `setParse` binding mid-walk changes live routing.** The moment `genParseTest` calls
`setParse`, `parse()` starts dispatching that rule through `defStuff.parseMethod` instead of the arm
chain. That is **activation happening during generation**, and it is the napalm's sibling. **Third
customer for off-rule storage + an explicit activation phase.** *Done when:* generation cannot
change routing. **Owner:** with the activation work.

**F-17b — `parseMethod` is dead infrastructure in ordinary runs.** `setParse` has exactly one caller
in the tree (`genParseTest`); `setParseMethod` is reachable only through the kant door
(`genParse.rtn:868`) and the `parseMethod=` binding (`:1456`). So `defStuff.parseMethod` is null in
every ordinary run and every rule takes the arm chain — which is what made the F-15 gate a routing
decision rather than a container-parser decision. Goes live with activation work. **Not a defect;
recorded so nobody re-derives it.**

**F-17c — `BrancheS` conformance: is `testOptions` over `break`/`continue`/`return` equivalent to
today's `testMatch`?** One measurement, owed when its turn comes in the pick-one pass. Until then
the F-15 gate keeps `BrancheS` on arm one, so nothing is broken and nothing is proved.

**F-17d — the false-by-vacancy family.** F-15's shape was: a loop that skips every candidate returns
its initialised `false`, and the caller cannot tell "tested and failed" from "nothing to test".
`testAttributes` (`RuleStuff.twk:336`) was the instance. **Census owed:** other `hasAttributes`-gated
or skip-looping sites with the same shape. **Good minion candidate.**

**F-17e — ⚠ `compile` EXITS THE PROCESS on a refused parse, so a flat sweep can never report more
than its first refusal.** `Commands.rtn` — `if !processCode(field) exit(1);` (it was `return 0;`
before 2026-08-18). Ruling 4 asks for per-rule failure reporting via `reportCodeFail`, which already
prints; the exit is what stops the census. `incant/walkPhase` names this in its own header and its
sentinel is what tells you whether the sweep finished. *Done when:* the sweep can report every
refusal in one run. **Owner: Tony** — it is his file and his deliberate edit.

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
The read *"genParseTest early-outs because NumbeR has data"* is true of the node that arrived and
says nothing about NumbeR.
⚠ **Scope, so this is not over-claimed:** the deref is at **name resolution**, so descent is
UNAFFECTED — `iterate` and `[]` both hand back the real node (measured above). Only rules named
directly in a driver line are hit. The `walkRules(Start)` census is therefore sound for everything
it reached by descent.
**Consequence for the "pick one" ruling:** the real `NumbeR` carries **data AND a 2-long list**, so
`genParseTest`'s own both-present warning is correct and has simply never been reachable from a
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

**Why the parse walk trips it:** `genParseTest` attaches its generated `CodE` with `+%`
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
`genParseTest` in `IncantForms/WorkingOn/parser`. The other door, `setParseMethod`, is reached only
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

### F-14 — the walk has four SILENT exits; there is no skipped-rules list
**Where:** `parser` — three `continue` gates in `walkRules`, plus `genParseTest`'s `datA != 0`
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
