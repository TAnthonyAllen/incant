# Incant — Status & Handoff (2026-07-27 PM: genParseRuleAccess steps 1-3 LANDED and green.
# runScaf2 CLOSED. JSON causes 3 → 1, and the survivor is LOCATED. Step 4 LANDED (eedd0b7),
# with a PRE-EXISTING entry-wrapper crash found and fixed along the way. TWO CORRECTIONS TO
# THIS SEAL'S OWN LEDGER — read "POP LEDGER CORRECTION" before trusting the table.)
*Written by Clod for a fresh Clay/Clod with ZERO memory of today. Self-contained. Read fully before
touching code. Everything below `af6b873` is on branch `jit-unified-emit-wip`; main is untouched.*

## READ THIS FIRST IF YOU ARE COLD — the one thing most expensive to lose

**Step 4's ruling (Clay SEQ 23), stated here because reconstructing it from the docs alone costs an
afternoon:**

> **The generated parse must return `GroupItem`, NOT `int`.** `GroupItem::parse()` has a **three-way
> exit**: `0` on failure, **the label** on success-with-a-label, **`trueResult`** on
> success-without-one (`GroupItem.twk`, the `if !sukcess && notifyFail` / `if sukcess && !label
> label = trueResult` / `return label` tail, plus `if label label = 0` on the `debugHere` failure
> path). **An `int` cannot carry three outcomes.** With an `int` fnptr the §1.3 fork can recover
> success/failure but never the label, and its only route to the label would be reconstruction from
> `into` — which is the exact thing genParseRuleAccess §1.1 exists to prevent, in its own words:
> *no dereference chain to walk, no reconstruction from `into` and `label`.* With a `GroupItem`
> return the fork is a **pure pass-through**: correct by inspection, not by argument.
>
> `leaveRule`/`leaveAlt` become the **sole implementers** of that three-way exit. **The emitted
> expression text does not change** — they already receive everything they need. Only return types
> change (theirs, the parse methods', and the fnptr member's).
>
> **This re-touches step 1's commit** (`527e971`) — the fnptr member's type is part of `RuleStuff`'s
> layout, so it is a **layout change**: `groups.ext` sync + `tokall` + rebuild + baseline
> re-verify, not an edit. That is expected, not drift. Pay it now; it only grows.
>
> **Scope cap — do NOT build all of `parse()`'s exit now.** Its attachment block has three branches:
> `isTarget` (assign + retag to `pStuff.ruleName`), `isGROUP && max > 1` (the `+% label.group` /
> `clear()` / `fLAG = true` recycling path), and the plain `else pStuff.label +% label`.
> **Rungs 1-2 need only the plain branch.** The middle one is rung 6's — and it is precisely the
> `fLAG` recycling the emitter was already ruled MUST NOT reproduce (Invariant R′). The `isTarget`
> branch is rung-9-adjacent. Grow them with the ladder.

Note the irony worth keeping: bear-trap #20 celebrated the fnptr member for turning a signature
*convention* into a compiler-enforced *type*. It did exactly that — and enforced a shape the design
had specified wrong. The type held the line on the error. That is the system working.

## Today's commits (branch `jit-unified-emit-wip`, in order)
```
a16b3b8  CLAUDE.md: #10 tokall correction; #19 regen-staleness; #20 multi-arg fnptr
ac7383d  genParseSpec §7.5: ANSWERED YES and LOCATED — invocation layer, parse() exonerated
a85f2de  genParse §1.1 step 3: rule-first across the support library (17 call sites)
014f0f6  genParse §1.3 step 2: parse() forks on rStuff.parseMethod (+ Tony's runNotified)
a8e3078  genParseSpec §7.1: 0b falsified as a CURE, vindicated as a FIX
8751a7c  genParseSpec §7.1: attribution moves off min-zeroing
4a3da10  genParseSpec §7.1/§9: 0b tested against a live fixture
527e971  genParse §1.2 step 1: RuleStuff.parseMethod fnptr member + tokall
```
(Session tip on arrival was `af6b873`.)

## SETTLED TODAY — none of this is contingent on step 4

### 1. genParseRuleAccess steps 1-3 are LANDED and verified by RUNNING
The brief (`docs/genParseRuleAccess.md`, imported to the repo today) revises genParseSpec §4.2/§5
and lands **before** rung 3's seam split. Its §3 order, with one correction Clod made and Clay
ratified — **step 1.5 must precede step 1**, because you cannot fork `parse()` on a field that does
not exist yet:

- **Step 1** (`527e971`) — `int &parseMethod(GroupItem, GroupItem)` added to `RuleStuff`. Additive,
  nothing reads it. Modelled on the existing `testMatch` fnptr one line above.
- **Step 2** (`014f0f6`) — `parse()` forks on `rStuff.parseMethod`, placed **before any frame state
  is set** so the generated path has nothing to unwind. No-op by construction.
- **Step 3** (`a85f2de`) — rule-first across the support library, **17 call sites, 2 files**:
  `lit` · `litOption` · `inGuard` · `leaveRule` · `leaveAlt`. Every parse method that lacked one
  acquired `GroupItem rule = locate("X")`. That is what satisfies POP §4 — a rule live in every
  frame, no dereference chain.

### ⚠ POP LEDGER CORRECTION — read before trusting the table below
The ladder rows were **green against a process exiting 139 (SIGSEGV)**. They were verified by
grepping for expected strings, and **"run" never included checking the exit status.** Corrected:
- **Baselines (`oneTest`/`jsonTest`) — VALID exactly as recorded.** Exit 0, byte-identical. A crash
  truncates output, so a full matching capture cannot come from a process that died early. Scope
  this hole; do NOT discard the ledger.
- **Ladder rows — NOT valid as originally sealed.** They became true only at `eedd0b7`, which is
  when `genScratch` first exited 0.
Doctrine now in CLAUDE.md's Testing section: **a POP is not passed unless the process exited 0.**

**POP ledger — every line RUN, and as of `eedd0b7` exit-status checked:**
| check | result |
|---|---|
| `oneTest` / `jsonTest` after **every** step | **BYTE-IDENTICAL** to the pre-change capture |
| rungs 1-2 text POP vs `genLadder/rung12.target` | diff **empty** |
| runnable floor | `runScaf('x')` PARSED · `runScaf('y')` FAIL, mark UNMOVED |
| **rung 2 runtime (NEW)** | `runScaf2('{')` FAIL, **mark REWOUND** — Invariant R both directions |
| `grep -c extern GroupRules.h` | **161**, held through six retoks (bear-trap #10's canary) |
| `rung12.target` | regenerated **deliberately**; diff is exactly the 4 intended lines |

Held back deliberately in step 3, and it is step 4's business: **the parse methods' own signatures
stay `(into)`.** Migrating to §1.4's `(field, into)` needs a cross-method-call decision — a callee
needs ITS OWN rule, not the caller's — which is `parseR`/`promoteR` territory.
`manyJSONblockFields`/`manyJSONlistItems` untouched for the same reason: they are *emitted* helpers,
so rung 6 owns their shape.

### 2. runScaf2 — CLOSED. It was regen staleness, and the digit theory was FALSE
`runScaf2` dispatches. No change to its name, registration, or call site — an unrelated `groups.ext`
sync plus a full `tokall` cleared it. **Strike the digit-in-name hypothesis on sight: incant command
names CAN carry trailing digits.** It was one bad session from hardening into a rule that would have
cost someone a pointless rename.

This is the **fourth** instance of the class and the fourth to resolve as environment, **zero** as
language. It should stop being called "the invocation blocker" and be called what it is: **regen
staleness**. First diagnostic step, before any hypothesis: **sync `groups.ext`, full `tokall`,
rebuild, re-test.** Four for four says the hypothesis phase is wasted motion. Written up as
**bear-trap #19**.

Worth recording as process: the two-failure stop rule *worked*. The prior session stopped, declined
to theorise further, and the environment sync cleared it with nobody spending a day.

### 3. The JSON thread: three documented causes → two dead, one LOCATED
- **Cause 1 (`setLabel` writing to the wrong RuleStuff) — DEAD.** The function was **deleted
  entirely** on 2026-06-22 (`875b936`) and exists nowhere live. Its job — retag — was **taken over
  by `<:`** in a rewritten JSONfield action, on the rule's own frame, which is Tony's validated
  direction reached by rewrite rather than by the literal one-line fix. TODO.md still carries this
  as an open cause; **annotate, do not strike** (Clay) — that entry is the only surviving
  description of what the function was for.
- **Cause 2 (§7.1 min-zeroing) — EXONERATED, and 0b is BOTH falsified and vindicated.** Instrumented
  print inside the taken branch never fires: **`parent.min = 0` never executes**. So 0b is
  **falsified as a CURE** for the JSON symptom and **vindicated as a FIX** for the defect — the
  record needs both claims or it misleads. The gate correctly declines because `JSONblock`'s `"{"-`
  and `"}"-` are mandatory. §7.1's "nearly every rule loses failure reporting" is a claim about the
  **pre-0b tree**; post-0b scope is unmeasured.
- **Cause 3 (§7.5 result-discard) — LOCATED.** The capped boundary test:
  ```
  DIAG runRule : JSONblock parse() -> NON-NULL    well-formed  — correct
  DIAG runRule : JSONblock parse() -> NULL        malformed '{' — CORRECT FAILURE
  ...and testJSON still prints   ok : {
  ```
  **`parse()` is honest and the caller sees non-null anyway.** The bug is entirely in the
  **invocation layer**; `matchFailed`'s `kount >= min` is exonerated too (min 1, kount 0 — it cannot
  fire). **Not fixed — locating it was the assignment.**
  Narrowing for whoever picks it up: JSONblock reaches `runRule` via `GroupActions.rtn`'s
  `or isRule result = runRule(arg,target)` dispatch, **not** through `aCTionRunRulE` — so the
  discard at `ruleActions.rtn:666` (TODO cause 2) is **not** the one on this path. Neither `runRule`
  nor `runOP` discards. The discard sits **above `runOP`, or in the script-level invocation**.
  §7.5's own earlier reading ("no JSON-family rule reaches `parse()`") is **WRONG** — it shipped
  with three self-issued caveats saying it might be a bad measurement, and it was. Marked superseded
  in place rather than deleted.

**Consequence for the ladder: JSON stays LAST, and the argument is stronger than it was.** `jsonTest`
is still not a clean oracle. Two extra hazards found today: a failing JSONblock **runs off the end of
its argument and consumes the enclosing script**, terminating the run (this is a **third restoration
axis** beside R (the mark) and R′ (the tree) — the **input stack**; generated code gets it
structurally from §5.3's wrapper popping the diversion on *both* paths). And `jsonTest`'s last case
is annotated `KNOWN TO FAIL` while printing `ok` — **when the invocation-layer bug is fixed it flips
to a real failure, which terminates the run, so jsonTest will appear to break at the moment the bug
is fixed.**

## OPEN ITEM — DIVERSION BOUNDARY NOT RESPECTED DURING MATCH (new; no other write-up exists)
A failing parse **reads past the end of its diverted buffer into the enclosing script text while
matching.** Distinct layer from the wrapper defect fixed in `eedd0b7`: that one was what the
wrapper does *after* the parse returns; this is the boundary the parse respects *while running*. A
correct unwind cannot help a mark that already walked out of the buffer.

**Reproducer** — `jsonTest`-style preamble, then:
```
testJSON('{');      <- malformed
testJSON('{');      <- NEVER RUNS
print "control";    <- NEVER RUNS
```
The tell is that the `Failed at:` window contains **the script's own source text**:
```
Rule JSONblock
	Failed at:	('{');#print "=== control: well-formed,
	on Line:	9
FAIL: {
```
The process now exits **0** (crash fixed); the following statements are still swallowed.

**Consequence: jsonTest is NOT half-restored.** It still cannot run multiple failing cases in one
process, so §7.1's **inverted-ordering fixture stays REQUIRED** (well-formed to arm, malformed to
read, nothing after). Third open item on the JSON thread, beside §7.5 and the oracle problem.

## HOW TO WEIGHT A CLAY BRIEF (earned 2026-07-27)
Five causal claims were checked against the tree in one day and **five failed**; every structural
claim held. The split is not design-vs-tree, it is **structural vs causal**.
- **Held — take these:** model-not-oracle · R-inner vs R-outer · one-implementer-each · the
  restorations as a family · seam-at-intent-not-punctuation · the three-way exit.
- **Failed — check these:** the ruleSTUFF clobber window · setLabel-orphaned · min-zeroing as the
  JSON cause · `matchFailed` on the Scaf path · one-bug-two-symptoms / jsonTest half-restored.

**Take the distinctions, check the attributions.** Cost of checking: one grep. Cost of not: hours,
five times over. The rule applies to this seal too.

## STEP 4 — LANDED (`eedd0b7`). Kept for the reasoning trail.
Ruling is at the top of this file. Sequence:
1. Change the fnptr member to return `GroupItem`; `groups.ext` in lockstep; `tokall`; rebuild.
2. `leaveRule`/`leaveAlt` return `GroupItem` (three-way exit); parse methods' return type follows.
   `runJSONblock` in `Commands.rtn` consumes `parseJSONblock`'s result — it needs updating with them.
3. §1.3's fork becomes a pure pass-through.
4. Regenerate `genLadder/rung12.target` **deliberately** (the emitted signature line changes).
5. Re-verify: baselines byte-identical, rungs 1-2 POP empty, runnable floor + Invariant R.

**If you arrive cold and the build is red, this is the most likely place.** Bear-trap #10's full
apparatus applies — a `groups.ext` mismatch silently wipes the whole extern block (canary:
`grep -c extern GroupRules.h` must read **161**, not 0).

## NEXT, after step 4
1. **Rung 3 = the walk/emission seam split.** Walk and emission are still INTERLEAVED (C++ baked
   into the traversal), so genParseSpec §0 does not hold yet. Clay's two refinements stand:
   **seam at INTENT, not punctuation** (walk says "conjunctive fold"; the emitter decides C++
   spells it `&&` — litmus: could emission target a bytecode emitter untouched?) and **the walk
   RETURNS a classified value**, consumed by emission as a second pass. Keep the IR thin.
   Write **Invariant R′** beside R in the spec while there.
2. Climb rungs 4-8, runtime re-check after rung 4 (first cross-method call).
3. **Rung 9 is TONY'S RULING and gates only rung 9** — bare reference to an alternation:
   auto-`promoteR`, or require explicit `@`? One data point, weak and adjacent: JSONfield spells its
   retag out explicitly with `<:`, so the system's disposition is "retag where it's wanted."
4. **Rung 10 is UNGATED** (was gated on where the ruleSTUFF fix lived; grep dissolved the fork —
   nothing reads `ruleSTUFF`). Tripwire: if §7.5's fix requires the emitted method to propagate
   something it doesn't, rung 10 comes back.
5. JSON LAST, and only once `jsonTest` is a clean oracle again.

## Open, Tony's
- **TODO.md cause-1 entry** — annotate as dead-since-`875b936`, don't strike. His file, currently
  modified in his tree.
- **Bear-trap #18's ATTRIBUTION** — the entry was split today into a confirmed OBSERVATION (the
  macro facility wouldn't support genParse's shapes, so §3 was rewritten against plain externs —
  doctrine, keep) and an OPEN attribution (four candidates, one of them Clay's own spec error). The
  old causal headline is **falsified by shipping code**: `testSet` has a declaration before its
  `testMacro(...)` call and works. Tony signs off on which candidate, if any.
- **`GUI/Layout.twk` and `GUI/Stylish.twk`** share basenames with the top-level files he edits, and
  `tokall` only ever sweeps top level. Two cheap determinants: which path the Xcode target
  references, and the mtimes.
- His Group-A work (Debug.rtn, Stylish, Layout, TODO, guiDesign, incant/utilities+jsonTest) is still
  uncommitted. `GroupRules.{h,mm}` now carry regenerated output from his uncommitted `Debug.rtn` —
  committed under his 2026-07-27 ruling ("commit GroupItem with my runNotified stuff and all
  subsequent changes. They do not overlap ... yet"). Note the "yet".

## `ruleSTUFF` is a WRITE-ONLY GLOBAL — Tony's ruling, 2026-07-27
Full-tree sweep (including the extensionless `incant/` sources — a `*.twk`/`*.rtn` filter misses
them) found **exactly one reader**: `GroupActions.rtn:269`, `RuleStuff ruleStuff = ruleSTUFF;` in
`processAction` — and that local is **never referenced again**. `git blame` dates it to the
**initial commit**, 2026-04-09: inert from birth. Tony: *"if you cannot find it being used then it
is no use... I just did not do a complete job of cleaning it out."*
Consequence: genParseRuleAccess §1.5 keeps `act(field, label)`'s **tail call** — its load-bearing
half — and the `ruleSTUFF` line survives only as a **single line marked parity-with-`parse()`**,
commented "zero live readers", removable once a rule's generated path is its only path. Leave
`parse()`'s own write and the global's declaration alone; `parse()` is the parity anchor.

## Run recipe / reproduce
- Binary: `~/Library/Developer/Xcode/DerivedData/InProcess-ezzmcllcsvijqmbipricnduikqfp/Build/Products/Debug/Groups`.
- Build: `cd ~/Library/CloudStorage/Dropbox/data/InProcess && xcodebuild -workspace
  InProcess.xcworkspace -scheme Groups -configuration Debug build`.
- `.rtn` (genParse.rtn, Commands.rtn, GroupActions.rtn, ruleActions.rtn) are `include`d into
  GroupRules.twk → edit one, then **`tok GroupRules.twk`** (NOT a standalone retok). Standalone
  class files (`RuleStuff.twk`, `GroupItem.twk`…) → `tok <File>.twk` directly.
- **`tokall` is a shell FUNCTION, not a script** — `for item in *.twk; do tok $item; done`. It
  sweeps **only top-level `*.twk` in the cwd** (13 files) and misses **14 below top level**
  (`GUI/`, `GUI/Stuff/`, `Tests/`). After any layout change, grep those generated files for the
  class you shifted. For `parseMethod` it was zero hits — nothing owed. (bear-trap #10, corrected.)
- **`groups.ext` lives OUTSIDE the repo** at `~/Dropbox/data/InProcess/Include/groups.ext`
  (bear-trap #11). It now carries `parseMethod` **and** the five rule-first decls. **No commit trail
  exists for any of it.**
- genParse ladder: `<binary> incant/genScratch` → emits parseScaf/parseScaf2, runs
  `runScaf('x')`/`('y')` and `runScaf2('{')` with the Invariant-R report. POP:
  `sed -n '/extern int parseScaf(/,/^}/p;/extern int parseScaf2(/,/^}/p'` of the output vs
  `genLadder/rung12.target` (empty diff = PASS).
- Baselines: `<binary> incant/oneTest` → `maximus = 11` then `26` ×4; `<binary> incant/jsonTest` →
  14 `ok`. **Capture these BEFORE changing anything and `diff` after** — "byte-identical" is the
  acceptance test for every additive step, and it caught nothing today only because nothing broke.
- The §7.1 fixture that actually discriminates (the "twice in a row" one does NOT — memoization
  predicts a first-call FAIL under both hypotheses, so both calls arm and neither reads): **invert
  it** — well-formed to arm, malformed to read, nothing after, ONE process.
- No `timeout` on this shell — background + kill anything that might hang.

## Working relationship (unchanged)
Tony (Haps) = architect/final authority. Clay (claude.ai) = design/reasoning. Clod (Claude Code) =
execution/edits/build. Standing permission: change source freely, commit/push routine work at
discretion.
**Walkie-talkie transport is SETTLED (SEQ 15 §0): Clay has NO filesystem reach — read-only uploads
only. CLAY DICTATES, CLOD TRANSCRIBES; Clod owns every `ipc/` write in both directions.** This is
the mode, not a degraded mode — the "restore Clay-side writes" ask is retired. `ipc` state:
clay-to-clod SEQ 24, clod-to-clay SEQ 14. `grep -H '^STATUS:' ipc/*.md` is Tony's window.
