# JIT — Full-Monty Plan (from the pivot to final victory)
*Clay, 2026-07-02. Draft v1 — §3 coverage table AWAITS docs/jit-coverage-recon.md
(minion M5); everything else stands on the proven pivot (`7850a9e`) and wakeup.md.
Self-contained; written to survive the month.*

---
## RATIFIED AMENDMENTS (2026-07-02, post-M5 — Tony-ratified; supersede the body where they conflict)
*`docs/jit-coverage-recon.md` (M5) landed and filled §3's placeholder; two of its findings
change this plan. Read this block first; the body below is otherwise intact.*

**§3 coverage table — RESOLVED by `docs/jit-coverage-recon.md`.** 42 op-dispatch functions in
`Instruct.rtn`: 18 already jitting-gated, 4 need mechanical gates (`opAND`/`opOR`/`opRem`/`opNOT`),
20 need real modification (tree mutation, I/O, registry lookups). Sequence gates-only in bulk, then
fp, then helper-call ops, per §3's own rule. Full table lives in the recon doc.

**A. FOR is NOT a counting loop — defer it to jitBail, do not build it as ladder rung 4.**
`aCTionFOR` is a GroupItem list/tree walk (`next()`/`prior()` over a member/attribute list, with
byRef/lastREF bookkeeping), not init/cond/increment. §1.3's "FOR = WHILE plus init+latch" is void.
Jitting it would mean emitting a helper-call loop back into interpreted `next()`/`prior()` each
iteration — high complexity, ~zero payoff (tree-walk cost dominates). FOR becomes the poster child
for jitBail (§2.1). Native-FOR-jit is revisited post-`testJits` ONLY if profiling ever demands it.

**B. Ladder resequenced (supersedes §4):** 0 nesting-safety/stack check → 1 loop-mechanism POP
(trip count driven through `jitSeedField`, NOT a literal — else mem2reg/unroll constant-folds it and
the value-dependent check goes vacuous) → 2 WHILE → 3 DO → **4 jitBail / whole-action fallback
(MOVED UP from rung 6)** → 5 FOR verified to *bail cleanly* (a bail POP, not a native-jit POP) →
6 nesting → 7 bulk gate completion → 8 helper-call ops → 9 `testJits` full monty. jitBail moves
early because it's what covers FOR and non-numeric-target ops; from rung 4 on, ANY incant runs
correctly under jitRunAction whether jitted or not.

**C. Null-guard is REFUTED, not just unverified — concrete must-fix, elevated from §2.3.**
`jitEmitCompare` does raw ICmp/FCmp with zero null/data checks, and each compare op's gate returns
before the interpreter's guard runs — so the e6405fb parity work (opEQ/GE/GT/LE/LT/NotEQ) is
**structurally bypassed** while jitting; a jitted compare on null operands crashes or reads garbage.
Fix: prepend a null/data-check block INSIDE `jitEmitCompare` mirroring e6405fb's both-null→false
semantics, and add null-operand POP pairs for every compare op to `testJits` (these are now
load-bearing, not optional). Does NOT block starting WHILE/DO — loop conditions run on non-null
induction values — but it gates `testJits` victory.

**D. Compound-assign/unary type gaps (M5 finding 3) — ONE guard, not seven.** `opMinusEQ`,
`opDivEQ`, `opMultiplyEQ`, `opMinusMinus`, `opPlusPlus`, `opPlus`, `opMinus` fire their jit gate
unconditionally assuming numeric (only `opPlusEQ` type-checks first). Fix in ONE place: make
`jitEmitBinary`/`jitEmitUnary` bail (jitBail) on a non-numeric target `jitData` — DRY, composes
with the early jitBail, don't replicate opPlusEQ's branch seven times. Latent today (fixtures are
numeric-only) but real the moment a jitted region hits `someString -= x` / `someList += item`.

**E. `switch` DROPPED from §1.5's deferred list.** No `aCTionSwitch` exists; the `switch(){}` in
the class files is native TAWK compiling straight to C++ — host control flow, never in the
interpret/jit system. Nothing to defer; remove it from the list entirely.

**F. Loop continue/break/return (addendum to §1.0b).** WHILE and DO bodies already handle
`isBranch`/`isContinue`/`isReturn`. `jitLoopBegin/Body/End` need explicit continue→br-latch and
break→br-exit wiring; v1 decision: `isReturn` inside a jitted loop → jitBail (simplest correct);
revisit function-exit-block via epilogue post-`testJits`.

---

## Where we stand (don't re-derive)
The unified emit-on-walk architecture is PROVEN: JIT emits LLVM by running the
interpret/runOP walk under the `jitting` gate. Load-bearing pieces (wakeup.md
has full detail): `jitRunAction` (jitting=1, generating=0 → dispatcher routes to
interpretXP), `jitExecBlock` (runs the BlocK's gMethod), per-opMethod jitting
gates in Instruct.rtn, `aCTionIF` gate → `jitEmitGIF` (jitIfBegin/jitIfEnd
bracketing), runOP leaf-seeding gate (jitSeedField/jitSeedLiteral, bear-trap #9),
`gJitResult` threading Value*s between gates (clobber = SILENT failure),
per-run jitData reset (dangling Value* across LLVMContexts).
Verified: jitGifScratch two-way `br i1 %cmp` (99/11), oneTest=26, extern 152.

## Final victory, defined
**`testJits()` — a full-monty POP method akin to testUnitTests():** one incant
file, one run, every jitted construct exercised with value-dependent results
(the 99/11 discipline — constant-fold-proof), every check self-reporting
green/red, exit code = red count. Plus the standing pair: oneTest=26,
jitGifScratch 99/11. When testJits is green, JIT Phase 2 is DONE.

## The strategy in one line
**aCTionIF is the template. Every control-flow rule action becomes: a jitting
gate → a jitEmit* bracketing emitter that runs sub-walks via gMethod between
basic-block brackets.** The pivot already paid for the hard part (emission
rides the walk); loops add only block topology.

---

## 1. Control-flow conversions (the design half — recon-independent)

### 1.0 Two shared mechanisms loops need (build ONCE, before any loop)
**(a) Re-walk semantics.** gIF walks condition and each arm at most once while
emitting. Loops emit the body ONCE but the emitted IR runs many times — same
as gIF, no change needed to emission. BUT the *condition* of a loop is walked
once to emit into a block that executes repeatedly — verify nothing in the
walk (seeding, jitData caching) assumes walk-once-run-once. The per-run
jitData reset is per-RUN, not per-block — expected fine, POP it explicitly
with a two-iteration loop before building all three loop kinds.
**(b) Loop block topology helper — `jitLoopBegin/jitLoopBody/jitLoopEnd`**
(jitEmitters.rtn), the loop analog of jitIfBegin/jitIfEnd:
```
preheader:  br cond
cond:       <condition sub-walk emits here> ; br i1 %c, body, exit
body:       <body sub-walk emits here>      ; br latch
latch:      <increment sub-walk, if any>    ; br cond
exit:       (continue emission here)
```
gJitResult discipline identical to jitEmitGIF: condition's gMethod leaves the
i1, jitLoopBody reads it immediately, NO statement between (the silent-failure
rule). PromotePass/mem2reg already in the pipeline handles the loop-carried
variables once loads/stores hit the same slots — expected free; POP confirms.

### 1.1 WHILE — first (minimal topology: no latch work)
aCTionWHILE gets the gate → `jitEmitWHILE`: preheader → cond(sub-walk) →
body(sub-walk) → br cond → exit. POP: countdown loop, value-dependent trip
count (start=5 → result X, start=0 → body never runs → result Y). The 99/11
discipline for loops = trip-count-dependent results.

### 1.2 DO — second (WHILE with the branch moved)
entry → body → cond → br i1 back-to-body/exit. Key semantic POP: body runs
ONCE even when condition is initially false (the do/while contract) — that IS
the value-dependent check.

### 1.3 FOR — third (WHILE plus init + latch)
init sub-walk in preheader; increment sub-walk in latch. VERIFY against the
FOR rule action's actual shape (M5 notes this): how init/cond/increment/body
hang off the parsed GroupItem tree determines the four sub-walk call sites.
POP: for i=0..N accumulate; two different Ns, two different sums.

### 1.4 Nesting — the structural payoff check
gIF-in-WHILE and WHILE-in-WHILE. The recursive walk should make nesting free
(each bracketing emitter is re-entrant if block bookkeeping is stack-shaped,
not global). If jitIfBegin/End state is currently global-single, fix to a
stack BEFORE the loop work — cheaper now than mid-FOR. **Clod: check this
first; it's the one plausible re-architecture item in the whole plan.**
POP: nested loop computing something trip-dependent both levels.

### 1.5 Deferred rules — named so they don't creep
switch, and any rule actions beyond IF/FOR/DO/WHILE (M5 lists what exists).
Interpreter handles them; a jitted region containing one falls back whole (see
§2.3). Do-later, post-victory.

## 2. Cross-cutting design decisions

### 2.1 Mixed-mode boundary (decide BEFORE testJits shapes it)
What happens when a jitted block contains a not-yet-jittable construct?
- **v1 policy (recommend): whole-action fallback.** jitRunAction detects an
  unjittable node during the emit walk (a `jitBail` flag any gate can raise),
  discards the module, runs interpretXP normally. Correct by construction,
  zero partial-mode bugs. Cost: unjitted hot paths stay interpreted — fine.
- v2 (deferred): region splitting / call-outs to interpreter. Not this arc.

### 2.2 Calls, and the runtime ABI question
Any opMethod whose jitted form needs runtime help (string ops, GroupItem
mutation, boxing) emits a CALL to a C helper rather than inline IR — the
standard escape hatch. Needs once: a declared-in-module helper registry
(name → function type → address via ORC absolute symbols). Build when the
first opMethod needs it (M5's NEEDS-modification column will say which).

### 2.3 Value model boundaries
Phase-1 ops proved i32/i64 arithmetic+compare on unboxed slots. M5 must flag
ops touching: doubles (fp types — straightforward), strings/GroupItems
(helper calls per 2.2), null-guard semantics (the e6405fb parity work — jitted
compares must match interpreter null semantics: both-null-false etc. POP pairs
must include null operands for every compare op).

## 3. opMethod completion — TABLE PENDING M5 (docs/jit-coverage-recon.md)
```
   FILL IN ON ARRIVAL:
   - opMethods with gates (expect ~24 Phase-1 POPs' worth)
   - NEEDS gate (simple: follow the Instruct.rtn gate pattern)
   - NEEDS modification (helper calls, fp, null semantics) — sequence LAST
   - rule actions present beyond IF/FOR/DO/WHILE (feeds §1.5 deferred list)
```
Sequencing rule once the table lands: gates-only ops in bulk (mechanical,
minion-friendly, POP each), then fp ops, then helper-call ops. Interleave with
§1 freely — ops and control flow don't block each other.

## 4. Ladder to victory (each rung: build → POP → commit)
0. Nesting-safety check on jitIfBegin/End state (§1.4) — fix to stack if global
1. Loop mechanisms POP (§1.0): two-iteration hand-rolled loop via WHILE
   emitter prototype; confirms re-walk + mem2reg assumptions
2. WHILE green (trip-dependent pair)
3. DO green (runs-once-when-false pair)
4. FOR green (two-N pair) — needs M5's FOR-shape note
5. Nesting green (§1.4 POP)
6. jitBail / whole-action fallback (§2.1) — from here, ANY incant runs
   correctly under jitRunAction, jitted or not. Big safety milestone.
7. Bulk gate completion per §3 table (parallelizable across minions, POP each)
8. Helper-call ops (§2.2 registry first, then ops)
9. **testJits() full monty** — assembles every POP pair above into one file;
   green = Phase 2 DONE. (Write testJits incrementally from rung 2 onward —
   each rung ADDS its pair to the file; rung 9 is then just a review, not a
   build. Steal testUnitTests' reporting shape.)

## 5. Bear watch (JIT-specific, beyond CLAUDE.md standings)
- gJitResult clobber = SILENT failure — the no-statement-between rule applies
  to every new emitter (loop cond→body especially)
- bear-trap #9 (re-seeding inner op-results as fields) — loop latches are new
  territory for it; increment sub-walks re-visit the induction variable
- per-run jitData reset is per-run, NOT per-iteration — correct, but don't
  "fix" it when a loop POP confuses someone
- `//` placement (#4) in all new .rtn emitter code
- LLVMContext lifetime: loop emitters create more blocks/values — same
  context, same run, no new lifetime rules; don't invent any
