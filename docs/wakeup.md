# Incant — Status & Handoff (2026-07-27: genParse SPINE IS LIVE — rungs 1-2 emit + POP green,
# rung-1 runnable floor green with Invariant R proven. runScaf2 dispatch OPEN (invocation-blocker
# class). JSON hand-parse bug STILL open. Rung 3 = the walk/emission seam split, next.)
*Written by Clod for a fresh Clay/Clod with ZERO memory of today. Self-contained. Read fully before
touching code. Everything below `a855bdc` is on branch `jit-unified-emit-wip`; main is untouched.*

## Headline — genParse went from design to a running emitter today
Yesterday's session ended mid-investigation on the hand-written JSON parse. Today pivoted to the
GENERATOR: Clay green-lit a staged build ladder (`docs/genParseLadder.md`), and Clod built the
genParse emitter spine from nothing to a **live, compiling, running** C++ command that emits parse
methods and — for rung 1 — those emitted methods actually PARSE. Four commits landed (below). The
one open blocker is a fresh instance of the invocation-blocker class (runScaf2 won't dispatch), and
the older JSON hand-parse bug is still unresolved (deliberately deferred — see Thread 3).

## Today's commits (branch `jit-unified-emit-wip`)
```
dacee77  genParse rung-1 runnable floor: parseScaf runs, Invariant R holds
7f10181  genParse ladder rungs 1-2: emitSequence spine (single + two-literal), POP-passing
04f90e0  docs: import Clay design/companion docs from Downloads
8ea2419  genParse S9 step 2 (cont): retag + ruleSTUFF fixes in RuleStuff; add genParseSpec
```
(Prior session tip was `19d0b58`. `8ea2419` banked yesterday's uncommitted RuleStuff retag/ruleSTUFF
fixes + the untracked genParseSpec.md — see Thread 3.)

## What genParse IS now (the spine)
`genParse.rtn` (NEW file, included into `GroupRules.twk`) — a C++ command, `genParse('RuleName')`,
that locates a rule and emits a C++ parse method mirroring the hand-written RuleStuff.twk methods
(genParseSpec §4). "C++ first, kant second" per Tony: the emitter is C++ now; a kant rewrite comes
once the JIT can compile the emitted action in-memory (no file). Wired the proven `runJSONblock`
way (groups.ext decl + include). POP = text-diff vs a hand-written target (`genLadder/rung12.target`).

### Where we are on Clay's ladder (docs/genParseLadder.md, rungs 1-10)
- **Rung 1** (single-literal seq, `Scaf isRule "x"-` → `lit("x")`): emit ✅ + POP ✅ + **runs** ✅.
- **Rung 2** (two-literal seq, `Scaf2 isRule "{"- "}"-` → `lit("{") && lit("}")`): emit ✅ + POP ✅.
  Runtime (runScaf2) is wired but BLOCKED — see Thread 1.
- **Rung 3** = the WALK/EMISSION SEAM SPLIT (see "Rung 3" below). NOT started. This is the next move.
- Rungs 4-8: text-emit, mechanical (group-ref, alternation, iteration, optional, guarded options),
  with a runtime re-check after rung 4 (first cross-method call / forward-decl discipline).
- Rungs 9 (transparent-callee retag → `promoteR`) and 10 (tail `code={}` action) are GATED — see NEXT.
- JSON family is the TOP of the ladder, done LAST (Thread 3 explains why jsonTest can't be the oracle yet).

### The rung-1 runnable floor (GREEN) — why it mattered
Clay's insistence, and it paid off: text-diff proves genParse emits what a human wrote, but is BLIND
to whether the emitted code compiles/links/binds/RUNS — the exact failure class that cost this project
5 attempts (Step 1/2 invocation blocker). So rung 1's emission was hand-placed + compiled in, with a
`runScaf` wrapper:
```
runScaf('x') -> PARSED           parseScaf consumes "x"
runScaf('y') -> FAIL, mark UNMOVED   <- Invariant R (§2.2): a failing method leaves atRuleMark
                                        exactly where it found it (leaveRule's rewind). Every
                                        downstream alternation/optional depends on this.
```
On a 4-line method a failure is unambiguously plumbing, not emitter logic. That's the floor doing its
job — trust propagates up from a runnable base, not a merely-readable one.

### Rung 3 — the seam split, with Clay's TWO refinements (do this FIRST, before climbing)
Honest current state: the walk and emission are INTERLEAVED — C++ syntax is baked into the traversal
(`cerr "extern int parse" rule.tag ...`), so a kant rewrite is a rewrite, not an emitter swap —
**genParseSpec §0 does not hold yet.** The fix is rung 3's first move. Clay's two refinements on how
to draw the seam (banked here so they survive):
1. **SEAM AT INTENT, NOT PUNCTUATION.** Don't emit `joinAnd`/`returnLine` (already assumes the target
   HAS an AND operator + short-circuits). The walk says "conjunctive fold over these terms" / "optional
   term, succeeds regardless"; the EMITTER decides C++ spells those `&&` and `((t)||1)`. **Litmus:**
   could the emission layer target a BYTECODE emitter (no expression grammar) without touching the
   walk? If not, the walk is still C++-shaped.
2. **WALK RETURNS A VALUE, NOT A CALL SEQUENCE.** A classified structure (sequence; these terms, each
   classified; this one's a transparent-callee group-ref → retag), consumed by emission as a SECOND
   pass. Payoff beyond kant: it's what §6 instrumentation reads AND the only way §8's position-zero
   cycle check can inspect the whole rule graph before emitting (an as-you-go emitter structurally
   can't). This is what makes Step 4 ("point it at any rule") safe.
3. **KEEP IT THIN.** 3 rungs is a weak basis for a general IR. Cover what rungs 1-8 need; grow with the
   leaf classifier. Sketch the shape, don't design the taxonomy.

## Thread-by-thread status

### 1. runScaf2 won't dispatch — OPEN, a fresh invocation-blocker instance (STOPPED per discipline)
Symptom: `runScaf2('x')` produces NOTHING — never entered, clean exit, no error. `runScaf` (identical
pattern, same file) works. **Ruled out** (don't re-test these): missing symbol (`nm <binary> | grep
runScaf2` shows `_runScaf2` live), wrong codegen (GroupRules.mm:4595 is structurally identical to
runScaf at 4573), multi-entry registration block (single-entry `registry(cOMMANDs); define runScaf2
immediateAction=runScaf2; ;` also fails), input braces (`runScaf2('x')` non-brace also fails).
**Digit-in-name (`runScaf2` tokenizing as `runScaf`+`2`) is the leading UNCONFIRMED hypothesis** — the
`runScafB` alias test was CONFOUNDED (no `runScafB` symbol exists for the `=value` bind to resolve, so
its failure is independently explained and proves nothing about digits). **Cleanest next test (needs a
rebuild):** rename the extern `runScaf2`→`runScafTwo` (no digit) in genParse.rtn + groups.ext, rebuild,
register+call `runScafTwo('x')`. If it dispatches, digit-in-command-name is the bug (high-value
bear-trap: incant command names can't carry trailing digits). Corpus-worthy either way (Clay). This
does NOT block the ladder — rung 1's floor is green; runScaf2 is only needed for rung-2's rewind test.

### 2. genParse emitter spine — LIVE, rungs 1-2 done
`genParse.rtn` holds: `emitTerm` (leaf → `lit`/`litTo`), `genParse` (emitSequence: frame + leaveRule +
` && ` join over the attribute walk), plus the runtime-loop plumbing (`parseScaf`/`parseScaf2` =
verbatim emissions, `runScaf`/`runScaf2` wrappers). Emission idioms NAILED and banked in the file
header — read them before extending:
- **JUXTAPOSITION concatenates with NO space** (`"parse" rule.tag` → `parseScaf`), like parse()'s
  `label.text = "g" tag`. **Comma in `cerr` INSERTS a space** (`rule= Scaf`) — commas are diagnostics
  ONLY, never emitted code.
- **`char dq = 34;` for every emitted double-quote** — no quote literal in the source, so tok's quote
  handling is never exercised. (Single-quoted strings inside a C++ extern's `cerr` parse the inner `:`
  as an inheritance colon and cascade the WHOLE file into `ERROR Inheritance` — cost real time, banked.)
- **`cerr` bodies are C++** (extern bodies): DOUBLE-quoted strings only.
- Recon-first confirmed the shape empirically before trusting the emit: a bare literal lands as an
  ATTRIBUTE with `data=0` (default/`testString`/literal row), NOT the rule's own data — `setTestMatch()`
  (RuleStuff.twk:164) is the classifier the §4.2 leaf emitter mirrors case-for-case.

### 3. JSON hand-parse bug — STILL OPEN, deliberately deferred; jsonTest is NOT a clean oracle
`parseJSONfield` still doesn't succeed on `"a":"b"` (`manyJSONblockFields` returns kount=0). Yesterday's
retag fix + ruleSTUFF/rStuff fix are committed (`8ea2419`, RuleStuff.twk). This is WHY the JSON rules go
LAST on the ladder: if emitted JSON methods failed jsonTest you couldn't tell "genParse emitted wrong"
from "genParse faithfully reproduced the known-broken hand-written behavior" — two unknowns, one signal.
**Tony's Xcode breakpoint in `parseJSONfield` (RuleStuff.twk:571) on `'{"a":"b"}'` is still the fastest
way in.** The one observation that splits it (Clay SEQ 14): does `parseJSONtoken(label)` (line 581)
return SUCCESS with a correctly-tagged child, or FALSE? false → token-level bug; success-but-field-fails
→ field-level (retag or the act tail). That fork also decides rung 10 (see NEXT).

### 4. Walkie-talkie mechanism — RESOLVED (was a live question all session)
Question: how did Clay's messages get into `ipc/clay-to-clod.md`? It "worked Friday," broke today
(Tony relayed Clay's side via chat all session). Archaeology: CLAUDE.md + the ipc headers document the
PROTOCOL (SEQ/states/one-way ownership) but are SILENT on the physical transport — and a Clay-side
filesystem connector would leave zero repo trace (it's desktop-app client config). Checked the actual
config: `~/Library/Application Support/Claude/claude_desktop_config.json` has **NO `mcpServers` block —
no filesystem connector to re-enable**. But **Cowork IS enabled** (`coworkUserFilesPath:
/Users/anthony/Claude`, cowork tasks/web-search on). Clay's read + the evidence: **Friday was very
likely a Cowork session** (files native, nothing Google), not this desktop-chat surface. Wrinkle:
Cowork's files path is `~/Claude`, not the Dropbox repo where `ipc/` lives — so if that's it, something
bridged them. Actionable: no connector to toggle; check whether Friday was Cowork. Meanwhile Tony keeps
relaying and Clod owns the ipc file writes. ipc SEQ: clod-to-clay SEQ 10 (fresh), clay-to-clod SEQ 14
(delivered via chat, acted on).

## Bear-traps / idioms banked today (fold into CLAUDE.md when convenient)
- Single-quoted strings in a C++ extern's `cerr` → the inner `:` parses as an inheritance colon →
  whole-file `ERROR Inheritance` cascade. Extern bodies are C++: double quotes only. Emit a `"` via
  `char dq = 34;`.
- Juxtaposition concatenates no-space; comma in cerr/print inserts a space.
- **`incant/genScratch` (and any run-script) is RUNTIME DATA, not compiled** — registration/dispatch
  hypotheses can be tested by editing the script and re-running, NO rebuild. Only extern
  source/signature changes (genParse.rtn) need `tok GroupRules.twk` + build.
- `include(<newfile>)` for a brand-new file in `incant/` did NOT resolve (looked in cwd); the
  older `include(utilities)` works. Resolution mechanism not chased — inlining the scaffold into the
  run-script sidesteps it.
- bear-trap #18 (tok macro facility) is still banked on an UNCONFIRMED cause — Tony's sign-off owed
  before it hardens into doctrine.

## NEXT — prioritized for whoever resumes (cold)
1. **Rung 3 = the walk/emission seam split FIRST** (Thread "Rung 3"), with Clay's two refinements
   (intent-not-punctuation; walk-returns-a-value). Land it before climbing — mid-refactor is the
   expensive place to stop. Keep the IR thin (cover rungs 1-8, grow with the classifier).
2. **Climb rungs 4-8** text-diffed on scaffolds, with a runtime re-check after rung 4 (first group
   ref = first cross-method call + forward-decl discipline).
3. **Root-cause runScaf2** (Thread 1) when convenient — the clean rename-to-no-digit rebuild test.
   Not blocking; needed for rung-2's Invariant-R rewind check.
4. **GATED rungs, unblock when their gate clears:**
   - Rung 9 (bare-ref-to-alternation → auto-`promoteR` or require explicit `@`?) — **Tony's ruling**
     (genParseSpec §8-class open item). Until ruled, emit: retag whenever the callee is an alternation,
     treat explicit `@` as forcing promote regardless.
   - Rung 10 (tail `code={}` action) — gated on the **ruleSTUFF-layer fork** from Thread 3's Xcode
     walk: if the fix lives in support-lib `act()`, rung 10 emits nothing new (target settled); if in
     the emitted method body, rung 10's tail grows a line. Same fix, opposite consequence for genParse.
5. **JSON hand-parse bug** (Thread 3) — Tony's Xcode gate; unblocks the top of the ladder.
6. **JSON LAST**: once genParse emits the seven methods, drop them in place and run jsonTest as the
   runtime POP — but only after Thread 3 makes jsonTest a clean oracle again.
7. Deferred housekeeping (not blocking): `GroupRules.{h,mm}` are uncommitted (env drift makes them
   non-pure-B — bear-trap #17 + Stylish.h auto-include); `groups.ext` (out-of-repo, bear-trap #11)
   carries genParse/runScaf/runScaf2 decls with no commit trail. Tony's Group-A pre-vacation work
   (Debug.rtn, Stylish, Layout, GroupItem runNotified, incant/utilities+jsonTest, TODO, guiDesign) is
   still uncommitted — his call.

## Run recipe / reproduce
- Binary: `~/Library/Developer/Xcode/DerivedData/InProcess-ezzmcllcsvijqmbipricnduikqfp/Build/Products/Debug/Groups`.
- Build: `cd ~/Library/CloudStorage/Dropbox/data/InProcess && xcodebuild -workspace
  InProcess.xcworkspace -scheme Groups -configuration Debug build`.
- `.rtn` (incl. genParse.rtn, Commands.rtn) are `include`d into GroupRules.twk → edit one, then
  `tok GroupRules.twk` (NOT a standalone retok), then build. Standalone class files (`RuleStuff.twk`,
  `GroupItem.twk`, `Stylish.twk`…) → `tok <File>.twk` directly.
- genParse ladder: `<binary> incant/genScratch` → emits parseScaf/parseScaf2, runs runScaf('x')/('y')
  with Invariant-R report. POP: `sed -n '/extern int parseScaf(/,/^}/p;/extern int parseScaf2(/,/^}/p'`
  of the output vs `genLadder/rung12.target` (diff = empty = PASS).
- Baselines still green: `<binary> incant/oneTest` → `maximus = 11` then `26`; `<binary> incant/jsonTest`
  → all `ok` (the GENERIC path; the hand-written parseJSON* path is Thread 3's open bug).
- Sanity: `grep -c extern GroupRules.h` = **161** (155 pre-genParse + emitTerm/genParse/parseScaf/
  runScaf/parseScaf2/runScaf2). No `timeout` on this shell — background+kill anything that might hang.

## Working relationship (unchanged)
Tony (Haps) = architect/final authority. Clay (claude.ai) = design/reasoning; relayed via chat today.
Clod (Claude Code) = execution/edits/build. Standing permission: change source freely, commit/push
routine work at discretion. Clay↔Clod walkie-talkie: `ipc/*.md`, three states (fresh/working/cleared),
`grep -H '^STATUS:' ipc/*.md` is Tony's window — see CLAUDE.md's walkie-talkie section + Thread 4.
