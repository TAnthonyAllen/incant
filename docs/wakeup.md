# Incant — Status & Handoff (2026-07-28: genParseShape (Clay SEQ 25) LANDED WHOLE, then RUNG 4
# (SEQ 26) GREEN — a generated rule reached through another rule's REFERENCE TERM, not only by
# name. Mixed mode works. The rungs 1-2 POP runs with NO ENTRY WRAPPER. §4.1's binding question is
# ANSWERED and the emitted indices now have a guard that has been made to fire.
# Everything RUN with exit status checked.)
*Written by Clod for a fresh Clay/Clod with ZERO memory of today. Self-contained. Read fully before
touching code. Everything is on branch `jit-unified-emit-wip`; main is untouched.*

## READ THIS FIRST IF YOU ARE COLD — the one thing most expensive to lose

**A generated parse method now looks like this, and it RUNS:**
```
extern GroupItem parseScaf2(GroupItem rule)
{
GroupItem   into  = rule.rStuff.parentLabel;
GroupItem   label = new("Scaf2");
GroupItem   t1 = rule[1];
GroupItem   t2 = rule[2];
String      from  = atRuleMark;
    return leaveRule(rule,into,label,from, lit(t1,"{") && lit(t2,"}") );
}
```
One argument and it is the rule (§1.1 — kant methods take one argument). `into` is DERIVED from the
new `RuleStuff.parentLabel`, not passed (§1.2). Leaves take the TERM, not the rule (§1.4). No
`locate` anywhere (§1.3). No entry wrapper — invocation is `Scaf('x')`, exactly as `Start()` (§1.7).

**Invocation is bound in incant, and this is §4.1 ANSWERED:**
```
registry(cOMMANDs);
define parseMethod immediateAction=parseRuleMethod noPrint; ;   <-- noPrint IS LOAD-BEARING
register(Ladder);
define  Scaf  isRule "x"- parseMethod=parseScaf;  ;
```
The `noPrint` is not decoration. Without it the binding attribute lands in the rule's **own term
list** as a bogus second term, and the emitter writes a term local for it. That is §1.5's hazard
arriving from a direction nobody predicted, and it is what the first run crashed on.

## Today's commits (branch `jit-unified-emit-wip`, in order)
```
da698e8  genParseShape steps 1-2: RuleStuff.parentLabel + one-argument parseMethod fnptr
e261e5d  genParseShape steps 3-7: term-first library, parseR, indexed emit, binding, POP
5c71db4  wakeup.md reseal + import Clay's SEQ 25 brief
ec34f59  RUNG 4 GREEN: a generated rule reached through another rule's reference term
```
(Session tip on arrival was `23d6888`.)

## POP LEDGER — every line RUN, exit status checked (the doctrine from 2026-07-27 holds)
| check | result |
|---|---|
| `oneTest` / `jsonTest` after **every** step | exit 0, **BYTE-IDENTICAL** (11 then 26 ×4 · 13 `ok`) |
| `genScratch` | **exit 0** — emission plus all four runtime cases |
| `Scaf('x')` · `Scaf('y')` | **WIN** · **FAIL, mark UNMOVED** |
| `Scaf2('{}')` · `Scaf2('{')` | **WIN** · **FAIL, mark REWOUND** — Invariant R both directions |
| `ScafB('ab')` · `ScafB('ax')` | **WIN through a reference term** · **FAIL, mark REWOUND across a nested generated call** |
| binder count guard, deliberately mismatched | **REFUSED**, and ScafA degraded to the interpretive walk |
| emitted text vs the compiled-in methods | **byte-for-byte identical** (rungs 1-2 and rung 4) |
| `grep -c extern GroupRules.h` | **166** (was 161; every addition accounted for — canary intact) |
| `genLadder/rung12.target` | regenerated **deliberately** — every line of the frame moved |
| `genLadder/rung4.target` | new |

Note what the runtime rows now prove that they could not before: the wrapper is gone, so a green run
means **emission + the fork + binding + dispatch** all work. The old wrapper called `parseScaf`
directly and could have passed with the binding wholly unbuilt.

## THE MEASUREMENT THAT SETTLED THREE QUESTIONS — `dumpRuleTerms`, and it is kept
§1.5 says genParse must traverse with the same accessor the emitted code reads with. Whether a
`fail` modifier or a `code={}` tail occupies a slot is a question about the **tree**, so it was
measured (`incant/termScratch`, one run) rather than reasoned about. Findings, all load-bearing:

1. `rule[i]` is source order, 1-based. **`fail` occupies NO slot.**
2. **A `code={}` tail occupies FOUR slots, not one** — `CodE`, `this`, `tempField`, and a cached
   `BlocK` that appears **only after the rule has been parsed once**. The tail of `rule[]` is not
   even stable across a run. §1.5's hazard is real and bigger than the brief supposed.
3. **All four are `noPrint`; no real term is.** So the classifier is `noPrint` — and that is not an
   invention, it is the test `testAttributes` already uses (`if noPrint continue`). Model-not-oracle
   applied to classification itself: take the oracle's own test rather than a parallel one that can
   drift from it.
4. Sequence terms are `isAttribute`; alternation options are `isMember`. One list, distinguished by
   affiliation.
5. A rule-reference term (JSONblock's `JSONfield`) is a **DISTINCT NODE** from the registry rule of
   the same name — different parent — but the two **SHARE a child list**. `rStuff`, however, is
   **per node**.
6. **No rule-reference term is `isGROUP`, and none has `onGroup` set**, before or after a parse.

Re-measuring is one command: `<binary> incant/termScratch`.

## TWO CORRECTIONS TO THE BRIEF, both made against the tree
- **§1.6's `t2.onGroup` does not exist to be written to** (finding 6). A reference term is a node
  carrying `isRule` and sharing the referenced rule's list, so it **parses directly** — which is
  exactly what the interpretive walk does (`testAttributes` calls `grup.parse(stuff)` on the term
  itself, never on a dereferenced target). `parseR` was written for parity with the oracle rather
  than as a parallel mechanism.
- **§2's `rule.parentLabel` cannot compile as written.** `parentLabel` is a `RuleStuff` field and
  `GroupItem` does not forward to it, so the emitted line is `rule.rStuff.parentLabel`. Only
  deviation from §2's literal text.

## ⚠ ONE NEW THING THAT WAS NOT IN THE BRIEF, and it is load-bearing
**`leaveRule` must tolerate a NULL `into`.** Retiring the entry wrappers (§1.7) makes a generated
rule reachable from a top-level incant call, and `runRule` invokes `rule.parse(0)` — no parent
stuff, so `parentLabel`, and therefore `into`, is **null**. The interpretive path has always guarded
this (`parse()`'s attachment block is `if label && pStuff`); the guard is now also in `leaveRule`,
one implementer down. **Without it `Scaf('x')` dereferences null on its FIRST success.** Any future
exit primitive inherits this obligation.

## RUNG 4 — SOLVED. The route exists, and it is a pointer walk.
The question that gated it: `parseMethod` lives on `rStuff`, `rStuff` is PER NODE, so a reference
term has its own and was never bound. Binding a rule therefore looked like it could not reach the
terms that reference it — which is exactly what mixed mode needs.

**Measured, not reasoned (the same `termScratch` method):** a reference term shares the defining
rule's child list, and **the children are parented to the DEFINER** — so `term[1].parent` **IS the
defining rule, by pointer.** Verified against what `locate()` returns for the same name on
`JSONblock→JSONfield`, `JSONfield→JSONtoken`, `JSONfield→JSONvalue`.

`GroupItem.definingRule()` is that walk. **It needs no guard because the test discriminates:** a
node that OWNS its children (a defining rule, and also `CodE`/`BlocK`) routes back to ITSELF, and a
leaf term has no children at all — both fall through to `return this`. Only genuine references
resolve elsewhere.

**The ruling: resolve at USE time.** `parse()`'s fork reads `parseMethod` from `definingRule()`, so
binding a rule once reaches every reference to it **including references created later**. No
registry sweep (would miss late references), no `locate` (§1.3 forbids it).

### The shape/frame split, and why the two fields go to DIFFERENT nodes
- **`parseMethod` is SHAPE** — one answer, always the same for a rule → read from the **definer**.
- **`parentLabel` is FRAME** — it varies per invocation and is the field that carries the variation
  → stays on **`this`**, the node actually being parsed. Routing it to the definer would make every
  reference to a recursive rule write the **same slot**, which is correct-looking right up until the
  recursion is live.

**The general tell, worth more than this instance: a field that looks like it belongs with the rule
because it is usually the same is exactly the dangerous case.** (Clay corrected his own near-miss on
this twice in one session, on Tony's lesson.)

`this` is what gets passed to the generated method, not the definer — the two share a child list so
`rule[n]` reads the same terms from either, while `rule.rStuff.parentLabel` must be this
invocation's.

## THE COUNT GUARD — and it has been made to fire
Every emitted `rule[n]` bets the list only ever mutates BEHIND the real terms. The cached `BlocK`
appearing after a rule's first parse proves the list *does* mutate at runtime, and nothing enforced
the bet. Now: `RuleStuff.termCount`, recorded by a **`parseTerms=N`** binding attribute, checked by
**`parseMethod=`** before it installs anything.

`countRuleTerms` is the **ONE implementer** of "real term" — the emitter bakes indices with it and
the binder re-checks with it. A check using its own private notion of the classifier would be worth
nothing.

**Negative test, RUN:**
```
parseMethod: REFUSING to bind parseScafA to ScafA
             emitted against 9 terms, rule now has 1
```
and note the behaviour on refusal: ScafA fell back to the **interpretive walk** while ScafB still
ran generated and still WON. **A refused binding degrades to the oracle rather than breaking** —
mixed mode doing exactly its job. Reproduce with:
`sed 's/ScafA isRule "a"- parseTerms=1/ScafA isRule "a"- parseTerms=9/' incant/genScratch > /tmp/g && <binary> /tmp/g`

`termCount` 0 means unrecorded, which **binds with a warning** rather than refusing — a silent trap
would be worse than an unguarded one.

## RUNG-4 POP (all RUN, exit 0)
```
ScafA isRule "a"-;                  ScafB isRule ScafA "b"-;      both generated, both bound
emitted:  return leaveRule(rule,into,label,from, parseR(t1,label) && lit(t2,"b") );
ScafB('ab')  ->  HIT/WIN ScafA nested inside HIT/WIN ScafB
                 ScafA's GENERATED method ran, reached through a reference term
ScafB('ax')  ->  ScafA WINs, lit "b" fails, FAIL ScafB with mark REWOUND
                 Invariant R across a NESTED generated call
emitted text == compiled-in source, byte-for-byte   (genLadder/rung4.target, new)
```
Reading the trace: `HIT` prints at the top of **leaveRule**, which is the rule's EXIT (§1.8 moved
instrumentation into the library, so there is no entry hook). One HIT per invocation, so §6.1's
attempt count is right; only the ORDER reads oddly — a callee's HIT appears before its caller's.

## Also landed, worth not re-deriving
- **§1.8 instrumentation is in the library, gated.** HIT/WIN and Invariant R live in
  `leaveRule`/`leaveAlt` behind `GroupRules.parseTrace` (off by default, so baselines cannot move;
  `traceParse('on')` turns it on). One implementation, every rule, no emitted lines, survives the
  kant handover. This is what replaces `runScaf`'s R-inner/R-outer prints — R is a property of the
  **failure path**, so `Scaf()` alone could never show it.
- **`runScaf`/`runScaf2`/`runJSONblock` are RETIRED.** Do not re-emit an entry wrapper.
- **JSON models converted** to the same shape using the **measured** indices. They stay dormant
  (nothing invokes them; JSON is last by ruling). `parseGeneric` survives with no callers —
  `parseR` subsumes it.
- **`setParseMethod`** does the `void*` → typed-fnptr cast in `-% %-` passthrough, because tok has
  no syntax for it. Its body is entirely passthrough and everything arrives as a **parameter**
  (bear-trap #13: an incant-level local referenced only inside a passthrough is pruned as unused).
- **Latent, flagged not carried:** `emitTerm`'s labelled branch emits `litTo`, which has **no
  implementation** in the support library. Never fires for rungs 1-2/4 (all terms `noLabel`).
- **`emitTerm` now classifies**: a term whose `definingRule()` differs from itself emits
  `parseR(tN,label)`; literals still emit `lit`/`litTo`.
- **A `noPrint` definition attribute does NOT persist in the rule's list** — "fire and forget" is
  literal. Measured: `Scaf isRule "x"- parseMethod=parseScaf;` leaves `Scaf` with exactly one entry.
  That is why the term count needed a real field and could not ride on a sibling attribute.
- **tok note:** `if <cond> return <juxtaposed concat>;` does not parse — `FAIL Block` /
  `ERROR Inheritance`, and it takes the whole extern with it. Assign to a local and return that, or
  use the `or`/`else` chain, which is what the shipping code does.

## NEXT
0. **Rung 3 is now the only thing between here and rung 5+** (rung 4 landed ahead of it, because
   SEQ 26 targeted it directly). The seam split is unchanged in scope.
1. **Rung 3 = the walk/emission seam split.** Walk and emission are still INTERLEAVED, so
   genParseSpec §0 does not hold yet. Clay's two refinements stand: **seam at INTENT, not
   punctuation** (litmus: could emission target a bytecode emitter untouched?) and the walk
   **RETURNS a classified value**, consumed by emission as a second pass. Write **Invariant R′**
   beside R in the spec while there. `dumpRuleTerms`'s classification is the natural seed for the
   walk's classifier.
2. Rungs 5-8. Rung 4's cross-method call is proven; the runtime re-check it was gating is DONE.
4. **Rung 9 is TONY'S RULING and gates only rung 9** — bare reference to an alternation:
   auto-`promoteR`, or require explicit `@`?
5. **§4.2 / §4.3 fixes, after shape**: make `lit`'s skip pass non-destructive (then `leaveAlt` drops
   to `(rule, ok)`); end-of-input normalization beside `checkSkip`.
6. **§7.5's result-discard is LOCATED but UNFIXED**, and it is on the path to a working POP, not
   behind one: until it is fixed no test on failing input reads honestly. Narrowing from 07-27: the
   discard sits **above `runOP`, or in the script-level invocation**; `parse()`, `runRule`, `runOP`
   and `matchFailed` are all exonerated.
7. JSON LAST, and only once `jsonTest` is a clean oracle again.

## STILL OPEN from 2026-07-27 — none of it closed today
- **DIVERSION BOUNDARY NOT RESPECTED DURING MATCH.** A failing parse reads past the end of its
  diverted buffer into the enclosing script text *while matching*; the tell is a `Failed at:` window
  containing the script's own source. Process exits 0 (crash fixed 07-27) but following statements
  are swallowed. **Consequence: `jsonTest` still cannot run multiple failing cases in one process**,
  so §7.1's inverted-ordering fixture stays REQUIRED (well-formed to arm, malformed to read, nothing
  after, ONE process).
- `jsonTest`'s last case is annotated `KNOWN TO FAIL` while printing `ok` — **when the
  invocation-layer bug is fixed it flips to a real failure, which terminates the run, so jsonTest
  will appear to break at the moment the bug is fixed.**
- **`ruleSTUFF` is a WRITE-ONLY GLOBAL** (Tony's ruling 07-27). Exactly one reader,
  `GroupActions.rtn:269`, and that local is never referenced again; inert since the initial commit.
  Leave `parse()`'s own write and the global's declaration alone — `parse()` is the parity anchor.

## FINDING — pre-existing, surfaced not caused (report, do not chase)
`Commands.rtn`'s `testing()` had been **hijacked** to call `runScaf` twice. Since `runScaf` retired
it had to change, and it was restored to what its own doc comment describes (`jitRunAction` for a
coded argument, `jitRunIfTest` otherwise). **`incant/jitscratch` therefore exercises the JIT for the
first time in a while, and it crashes (139) on the `jitInc` fixture:**
```
0  jitEmitUnary  GroupRules.mm:2424   <- crash
1  opPlusPlus    GroupRules.mm:3904
2  runOP · aCTionBlocK · jitExecBlock · jitRunAction · testing
```
Squarely in the JIT arc (`++`'s emit path), nothing to do with genParse. `jitscratch` is not a
baseline and was not passing before in any meaningful sense — the old body never called
`jitRunAction` at all.

## Open, Tony's (carried forward, none touched today)
- **TODO.md cause-1 entry** — annotate as dead-since-`875b936`, don't strike. His file.
- **Bear-trap #18's ATTRIBUTION** — split into a confirmed OBSERVATION (keep as doctrine) and an
  OPEN attribution with four candidates, one of them Clay's own spec error. Tony signs off.
- **`GUI/Layout.twk` and `GUI/Stylish.twk`** share basenames with the top-level files he edits, and
  `tokall` only ever sweeps top level.
- His Group-A work (Debug.rtn, Stylish, Layout, TODO, guiDesign, incant/utilities+jsonTest) is still
  uncommitted.

## Run recipe / reproduce
- Binary: `~/Library/Developer/Xcode/DerivedData/InProcess-ezzmcllcsvijqmbipricnduikqfp/Build/Products/Debug/Groups`.
- Build: `cd ~/Library/CloudStorage/Dropbox/data/InProcess && xcodebuild -workspace
  InProcess.xcworkspace -scheme Groups -configuration Debug build`.
- `.rtn` (genParse.rtn, Commands.rtn, GroupActions.rtn, ruleActions.rtn) are `include`d into
  GroupRules.twk → edit one, then **`tok GroupRules.twk`** (NOT a standalone retok). Standalone
  class files (`RuleStuff.twk`, `GroupItem.twk`…) → `tok <File>.twk` directly.
- **`tokall` is a shell FUNCTION** — `for item in *.twk; do tok $item; done`. Top-level only (13
  files); misses 14 below (`GUI/`, `GUI/Stuff/`, `Tests/`). After a layout change, grep those
  generated files for the class you shifted. Today: only `GUI/Bwana.mm`, and it merely `#include`s
  `GroupRules.h` without touching a field — nothing owed.
- **`groups.ext` lives OUTSIDE the repo** at `~/Dropbox/data/InProcess/Include/groups.ext`
  (bear-trap #11). It now carries `parentLabel`, the one-arg `parseMethod`, `parseTrace`, `parseR`,
  `parseRuleMethod`, `traceParse`, `dumpRuleTerms`, the renamed `leaveRule`/`leaveAlt` params and
  the one-arg JSON parse decls — and `runScaf`/`runScaf2`/`runJSONblock` removed. Rung 4 added
  `termCount`, `definingRule`, `countRuleTerms`, `parseTermCount`, `parseScafA`/`parseScafB`.
  **No commit trail exists for any of it.**
- genParse ladder: `<binary> incant/genScratch` → emits parseScaf/parseScaf2, then runs
  `Scaf('x')`/`('y')`/`Scaf2('{}')`/`('{')` with the leaveRule R report. POP:
  `sed -n '/^extern GroupItem parseScaf(/,/^}/p;/^extern GroupItem parseScaf2(/,/^}/p'` of the
  output vs `genLadder/rung12.target` (empty diff = PASS).
- Term measurement: `<binary> incant/termScratch`.
- Baselines: `<binary> incant/oneTest` → `maximus = 11` then `26` ×4; `<binary> incant/jsonTest` →
  13 `ok`. **Capture BEFORE changing anything and `diff` after.**
- Crash frames without Xcode: run under `script -q /dev/null` (segfaults lose buffered stdout).
- No `timeout` on this shell — background + kill anything that might hang.

## HOW TO WEIGHT A CLAY BRIEF (earned 2026-07-27, held again today)
The split is **structural vs causal**, not design-vs-tree. Today's structural claims all held (one
argument, derived `into`, term-first, no locate, no wrapper, instrumentation in the library,
through-the-fork). The two that needed correcting were both **claims about what is in the tree**
(`t2.onGroup`, `rule.parentLabel`) — same family as the five that failed on 07-27.
**Take the distinctions, check the attributions.** Cost of checking: one measurement run.

## PARKED by Clay (SEQ 26), neither blocks the ladder
`jitEmitUnary`←`opPlusPlus` (see the finding above), and the LLVM-IR-for-inlining question raised by
routing `parseR` through the fork. Both are JIT-ladder work.

## Working relationship (unchanged)
Tony (Haps) = architect/final authority. Clay (claude.ai) = design/reasoning. Clod (Claude Code) =
execution/edits/build. Standing permission: change source freely, commit/push routine work at
discretion.
**Walkie-talkie transport is SETTLED: Clay has NO filesystem reach — read-only uploads only. CLAY
DICTATES, CLOD TRANSCRIBES; Clod owns every `ipc/` write in both directions.** SEQ 25
(genParseShape) arrived as a file in `~/Downloads`, imported to `docs/genParseShape.md`.
SEQ 26 (rung 4) arrived in chat.
`grep -H '^STATUS:' ipc/*.md` is Tony's window.
