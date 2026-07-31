# Incant JIT — WHAT IS TRUE TODAY

*Consolidated 2026-07-31 from eight separate JIT documents. This file holds **current truth**:
what exists, what runs, what is measured-broken, and the facts a decision can stand on.
**Design that is not yet built lives in `docs/jitDesign.md`** — do not add plans here.*

**Every factual claim in this file carries an `asOf`.** That is not decoration, it is the
lesson this document was reorganised around — see §7.

---

## §0 — THE JIT REPLACES THE INTERPRETER. Read this before any other JIT decision.

**Tony's plan is that the JIT BECOMES the interpreter.** It is not an accelerator running
beside an interpreter that stays. There is one execution path, and in the end it is the
compiled one.

This was written down on 2026-07-29 because it was **nowhere**. A reader with no memory of the
design conversations derives "accelerator" from the code — a `jitting` gate beside an
interpretive path reads exactly like one — and then misreads every JIT decision downstream.
That has now happened twice to two different reasoners (§4.2).

**What it explains that "accelerator" does not:**
- Why `jitXP`/`jitXpress` were retired and the **unified emit-on-walk** cut was built instead
  of a second, parallel emitter.
- Why the whole class of *"will the jitted and interpreted paths diverge?"* worries is
  **retired**: there is only ever one path to diverge from.

### Consequence 1 — locals-as-frames lands ONCE, in the JIT
`saveLocalFields` gets **DELETED, not repaired.** The frame schema and per-call slot array
(now in `jitDesign.md`) are the replacement, and they land in the JIT and nowhere else. Do not
spend effort making the interpreter's activation record correct; it is a component with a
scheduled death.

Corollary for the iterator: under frames it becomes **two stack slots, source and current** —
no heap handle, no `isIterator` gate, because there is no heap node to accidentally unwrap.
Tony's own usage already reads as pointer semantics, so **nothing about the language design
changes**; only the implementation does. The interpreter's per-frame `saveLocalFields` fix of
2026-07-29 is therefore a **bridge**, deliberately, and its fixtures (`iterT1`/`iterT3` in
`pop.sh`) outlive it as language-level POPs. **Deleting the function must not delete the
fixtures.**

### Consequence 3 — A CLASS OF DEFECT THAT IS RETIRED AT CROSSOVER, NOT FIXED
*Added 2026-07-31. This is a register of things NOT to spend effort repairing, and it now has
two members — both found in the same week, which is why it is worth naming as a class.*

An interpreter defect belongs here when the compiled form **cannot express it**, so the JIT
does not fix it — the JIT makes it impossible.

| member | the defect | why the compiled form retires it |
|---|---|---|
| **`saveLocalFields`** (§0 Consequence 1) | locals are attributes on a shared action node, so recursion works by convention | under frames, each call owns a slot array. There is no shared list to stomp |
| **VALUE/SIGNAL CONFLATION** (new) | a statement's **value** and its **branch signal** (`isBranch`) ride the *same GroupItem*, so anything that changes the value drops the signal | **in IR a branch and a stored value are separate by construction.** A `br` carries no value; a `store` carries no control flow. There is nothing to conflate |

**The second member is the structural root of BOTH branch defects ruled on 2026-07-31** — the
bare-return tag leak and the break over-propagation. **One design decision, two expressions**,
which is why fixing them separately in the interpreter needed care in three loop handlers plus
the block, and why the emitter's half of each was *free*: bare return is branch-to-exit with no
store, `break` is branch-to-exit, and neither has a signal to consume.

⚠ **What this register is FOR, and the discipline it encodes:** when a defect is in this class,
the interpreter fix is a **bridge** and should be scoped like one — correct, minimal, and
covered by fixtures that **outlive the code they were written against**. `incant/retProbe` and
`incant/loopBranchT` are language-level POPs: they describe what incant *means*, not how this
interpreter happens to work, so they survive into the compiled world unchanged. Do not
generalise a bridge fix, and do not skip its fixture.

### Consequence 2 — THE OPEN RULING, and it is Tony's
**During the crossover, what happens to a construct the JIT cannot emit yet?**

Falling back to the interpreter *is* the divergence — reappearing as a **schedule** artifact
rather than a design one, which is worse because nobody wrote it down as a decision.

**It was unrulable until 2026-07-30 because nobody had enumerated the boundary. §2 is that
enumeration, so it is rulable now**, and every day it stays open the silent-fallback count
grows. The candidate answer — **degrade to the oracle LOUDLY** — already exists in the tree
(§2.3) and has since been lifted into a reusable primitive (§1.3).

### Why textual IR gets MORE important under replacement, not less
A JIT that **is** the interpreter must cover the **whole language**, and diff-against-golden is
the only QA discipline that scales to that surface. A `.ll` file is a byte-exact target exactly
as `genLadder/rung4.target` is — it gives the JIT a **census**, which it did not have until
2026-07-30. And a **text** emitter can be kant; an `IRBuilder` one never can.

---

## §1 — WHAT EXISTS AND RUNS

### 1.1 The emit layer — six emitters and their support
All in `jitEmitters.rtn` (included at `GroupRules.twk:293`, generated into `GroupRules.mm`).
*asOf 2026-07-30, re-verified 2026-07-31.*

| # | function | covers | does NOT cover |
|---|---|---|---|
| 1 | `jitEmitBinary(arg,target,op)` | `+ - * /` on count/number, with SIToFP promotion | `%` (no `jitSRem`/`jitFRem` case); string `+`; **clobbers target's `jitValue`** |
| 2 | `jitEmitCompare(arg,target,op)` | `== != < <= > >=`, ICmp/FCmp, i1 result | **zero null/no-data guards**; same `jitValue` clobber |
| 3 | `jitEmitAssign(arg,target)` | plain `=` store into `jitSlot` | byRef (`:=`) — the gate fires *before* opAssign's byRef check; a literal target is silently a null store destination |
| 4 | `jitEmitUnary(target,op)` | `++ --` (in-place, store-back), prefix `-` (value-producing) | **unreachable without a null deref — §3.1**; `!` (opNOT) not routed here at all |
| 5 | `jitEmitStringPlusEQ(arg,target)` | string/token `+=` via one `CreateCall` to `concatEQ` | anything else string-shaped; it is the **only** `CreateCall` in the layer |
| 6 | `jitEmitGIF(input)` | `if/else` — condition, `CreateCondBr`, **both arms**, merge. Else arm landed 2026-07-31 (§3.2) | nesting (untested); the **return value** (§3.4) |

Supporting cast: `jitSeedLiteral` (literal → `ConstantInt`/`ConstantFP`, no `jitSlot`, correctly
— a literal is not assignable) · `jitSeedField` (bakes the field's *stable* `gCount`/`gNumber`
address, `CreateLoad`s it, stashes the address as `jitSlot`) · `jitIfBegin`/`jitIfElse`/`jitIfEnd` (block
topology — always three blocks; `gIfEndBlocks`/`gIfElseBlocks` are stacks popped in
lockstep, so nesting is *structurally provided for*) ·
`jitExecBlock` (**runs the action's `BlocK` through the interpret walk** — §2.2 hangs off this)
· `jitRunAction` (the driver) · `concatEQ` (the runtime helper string-`+=` lands on) ·
`jitRunIfTest`/`jitRunAddTwo` (**hand-built scaffolds, NOT emit-path code** — they are the two
green things in `jitIfScratch`, and anyone reading "JIT smoke tests pass" should know they
bypass the emitters entirely) · `jitInitOnce`/`jitEngine` (one-time LLVM + ORCv2 setup).

**There is no `jitEmitCall`.** The gate point would be `runOP`'s `or op.isMethod` branch —
*the same branch §3.1's bug lives on.* Anyone fixing §3.1 is standing on the `jitEmitCall` seam.

### 1.2 The instruments — new on 2026-07-30, and the JIT had none before
Nothing in the live tree had ever called `verifyFunction`, and no IR had ever been dumped.

- **`llvm::verifyFunction`** (`jitEmitters.rtn:529`) — placed *before* mem2reg, so it catches
  the emitter's own output rather than the optimiser's. It returns **true when the function is
  broken**, which is the API's own inversion and is easy to get backwards.
- **`INCANT_JIT_DUMP`** dumps the module. An **environment variable, not a GroupBody flag** —
  deliberately, so it costs no bitfield shift and no `tokall` (bear-trap #10). **Two modes, and
  `=2` is the one to reach for:**

  | mode | dumps | answers |
  |---|---|---|
  | `=1` | post-mem2reg | what will actually run |
  | **`=2`** | **PRE-mem2reg — the emitter's own output** | ***did the emitter emit this, or did the optimiser produce it?*** |

  ⚠ **`=2` is ratified as THE ATTRIBUTION INSTRUMENT and is the default for ladder debugging.**
  The post-pass dump cannot separate emitter from optimiser, and that is the *first* question
  any emitter failure raises. It is not hypothetical: the result-slot clobber — two stray
  `store i32 7` in the merge block — was **invisible** at `=1` because folding hid it, and
  obvious at `=2`.

### 1.3 `jitDegrade` — the crossover primitive
`jitEmitters.rtn:61`, lifted 2026-07-30 from the one place the pattern already existed
(§2.3). It carries a **counter**, which is the point: it turns ~53 silent fallbacks into
countable ones.

⚠ **It has NO behavioural coverage.** Its two call sites (`Instruct.rtn:585`, `:747`) are
unreachable by any fixture, blocked by an open question. `incant/jitDegradeT` is committed
reaching its sentinel and **not** its target, and says so in its own header.

### 1.4 What actually runs — measured
*asOf 2026-07-30. Exit status taken directly from `$?` on the binary, never through a pipe.*

| run | exit | outcome |
|---|---|---|
| `incant/jitscratch` | **139** | 22 POPs green through `jitStrEQ`, then dies on `jitInc` |
| `incant/jitIfScratch` | 0 | hand-built IR smoke: -7→99, 5→5 — **scaffolds, not emitters** |
| `incant/jitGifScratch` | 0 | `jitGIF` taken→99, `jitGIFb` not-taken→11 |
| `incant/oneTest` | 0 | bytecode path, unaffected by all JIT work |
| `testing(testWhilE)` / `(testDo)` | **134** | LLVM assert: ICmp operand type mismatch |
| `testing(testGXLeaf)` | **139** | two sequential `if`s in one body |
| `incant/jitThenT` (righty=13) | 0 | `maximus = 26` ✅ — *was* correct by luck; now the regression net |
| `incant/jitElseT` (righty=-7) | 0 | `maximus = 7` ✅ — **was 11 + garbage at exit 0**, fixed 2026-07-31 |
| `sh genLadder/jitPop.sh` | 0 | values both directions + four-block IR shape |
| `testing(testPrint)` | 0 | printed `hello world` **at emit time** |

---

## §2 — THE CROSSOVER BOUNDARY, ENUMERATED

This is what §0's open ruling is *about*, and it did not exist in enumerated form before
2026-07-30.

### 2.1 The census
*asOf 2026-07-30. Classifications independently confirmed twice (2026-07-02 and 2026-07-30).*

**Operators — `Instruct.rtn`, 42 op-dispatch functions: 18 gated, 24 not.**

*Gated (18):* `opAssign` · `opDiv` · `opDivEQ` · `opEQ` · `opGE` · `opGT` · `opLE` · `opLT` ·
`opMinus` · `opUnaryMinus` · `opMinusEQ` · `opMinusMinus` · `opMultiply` · `opMultiplyEQ` ·
`opNotEQ` · `opPlus` · `opPlusEQ` · `opPlusPlus`.

*Not gated (24):* `opAddAttribute` · `opAND` · `opCopyList` · `opDebug` · `opDot` · `opEnd` ·
`opGet` · `opGetAttribute` · `opGetMember` · `opIN` · `opLastREF` · `opMatch` · `opNOT` ·
`opOR` · `opPointer` · `opPrint` · `opRebind` · `opRem` · `opReplaceAttribute` ·
`opReplaceMember` · `opSetGroup` · `opSetFlag` · `opSetTag` · `opString`.

**Statement handlers — `ruleActions.rtn`, 30 `aCTion*` functions: exactly 1 gated.**
Only `aCTionIF` carries `if jitting { return jitEmitGIF(input); }`. Ungated and therefore
interpreted-at-emit-time: `aCTionDO` · `aCTionFOR` · `aCTionWhilE` · `aCTionPrinT` ·
`aCTionIterate` · `aCTionRunRulE` · `aCTionSearch` · `aCTionDefinE` · `aCTionBrancH` ·
`aCTionBlocK` · `aCTionStatemenT` · `aCTionExpressioN` · plus 17 parser/token-plumbing
handlers (`aCTionANYtoken`, `aCTionBraced`, `aCTionCheckFor`, `aCTionCodE`, `aCTionDEBUG`,
`aCTionFailed`, `aCTionNamE`, `aCTionNumbeR`, `aCTionParens`, `aCTionQuotE`, `aCTionScopeXP`,
`aCTionSetBrackets`, `aCTionShortcuT`, `aCTionTokenXP`, `aCTionTraiT`, `aCTionTraiTdata`,
`aCTionXpress`). *Several of that last group are parser plumbing rather than executable
constructs, and that distinction matters for the ruling.*

⚠ **Line numbers move.** The iterator work shifted `Instruct.rtn` (`opEQ` 155→174, `opPlusPlus`
557→738) and the 2026-07-31 print work shifted it again. **Re-grep rather than trusting a
cited line.**

### 2.2 Today the jitted path IS the interpreter, running for real
**Verdict: the question "is the interpreter reachable from a jitted path" understates it.**
*Confidence: run result, not a reading. asOf 2026-07-30.*

`jitRunAction` raises `jitting=1`, then calls `jitExecBlock`, whose entire body is:
```
extern GroupItem jitExecBlock(GroupItem input)
{
GroupItem   BlocK:;
    if BlocK    BlocK.gMethod(BlocK);
    return input;
}
```
That is the *interpreter's own* `aCTionBlocK` walk. Every statement executes. A gated op
returns early after emitting IR; an **ungated op or statement handler does its real work, with
real side effects, at emit time.** Proven by `testing(testPrint)` printing `hello world`
during compilation.

So under `jitting=1`: all 24 ungated operators **mutate the live GroupItem tree while
"compiling"** (`opPrint`, `opString`, `opSetGroup`, `opSetTag`, `opAddAttribute`,
`opReplaceMember`). All 29 ungated statement handlers execute. `runOP`'s three non-operator
arms mean **a call from inside a jitted body runs the callee interpreted, entirely.**
`opPlusEQ`'s gate type-checks and then **falls through to the interpreted body silently** for
`isLIST`/buffer/`isSTAK` — the one op that type-checks *and* the one that silently degrades.

### 2.3 The one LOUD refusal that already existed
`Instruct.rtn` `opPlusPlus`/`opMinusMinus`, written during the 2026-07-29 iterator work:
```
if result.isIterator {
    if jitting  cerr "ERROR ++ on an iterator is not JIT-supported yet:",result.tag:;
    return iterAdvance(result,1); }
```
**This is §0's candidate answer — "degrade to the oracle LOUDLY" — arrived at independently
and implemented once.** The other ~52 degradation sites say nothing. It has since been lifted
into `jitDegrade` (§1.3).

⚠ **Irony worth recording:** those two arms are also scheduled for deletion (§0 Consequence 1
removes the iterator handle entirely). The pattern was lifted out first, which is why
`jitDegrade` exists as a free-standing primitive.

---

## §3 — WHAT IS MEASURED-BROKEN

*All asOf 2026-07-30 unless noted. Each has independent confirmation; the causes differ.*

### 3.1 The unary seed gap — one cause, three crashes, VERIFIED
All three unary POPs (`jitInc`, `jitDec`, `jitNeg`) die SIGSEGV in `jitEmitUnary` on a null
`target->jitData`. Cause: `runOP`'s seed gate reads `if jitting && op.isOperator`, but **every
unary operator is registered `ruleMethod=` — isMethod, not isOperator** (`incant/setup:89, 99,
120, 122, 125, 131, 135`) — so dispatch takes `runOP`'s `op.isMethod` arm and no operand is
ever seeded.

Three independent confirmations: the crash frame lands on the isMethod branch, not the
isOperator one; the registrations say `ruleMethod=`; all three POPs die identically in separate
processes.

**It is a regression, dated (inferred, no bisect).** `jitXP` held `aCTionExpressioN`'s `uxp`
seeding branch and **was folded out on 2026-06-30** in the unified-emit pivot. Its seeding job
moved to `runOP`'s new gate, which was written for the binary/isOperator shape only. It went
unnoticed because `testing()` was hijacked to the since-retired `runScaf` in that window, so
`jitscratch` did not reach `jitRunAction` at all.

**The gap was already documented at the crash site** (`jitEmitters.rtn:227-229`: *"not wired
yet"*) while §5's Phase-1 table two documents away said DONE. The two statements coexisted for
a month.

**Scope, honestly: an afternoon to stop the crash, an arc to make the JIT trustworthy.** The
fix is local and testable by three existing POPs. It does **not** move the frontier — treat it
as *unblocking fixture capture*, not as progress.

### 3.2 `jitEmitGIF` had no else arm — ✅ **FIXED 2026-07-31**
**Was** the only *wrong answer at exit 0* in the JIT: `jitEmitGIF` declared only
`ExpressioN:` and `StatemenT:` — no `ElsE:` — while `aCTionIF` declared all three, so the else
statement was never visited by anything. Neither emitted nor interpreted; it vanished.

| setup | correct | before | after |
|---|---|---|---|
| `righty = 13` | `maximus = 26` | 26 — **correct by luck** | **26** ✅ |
| `righty = -7` | `maximus = 7` | **11**, returns 83623936, **exit 0** | **7** ✅ |

**The fix is one topology, not a branch on `hasElse` — ⚠ RATIFIED 2026-07-31 on principle:
branching on `hasElse` would rebuild the divergence.** `jitIfBegin` now always creates three
blocks (then/else/endif) and branches the condition to then/else; the new `jitIfElse` closes
the then arm and opens the else; `jitIfEnd` closes whichever arm is current. With no `else` in
the source the block is simply left empty and branches straight to endif — valid IR, one
branch LLVM folds. **Deliberate: the missing arm was never a hard bug, it was a SECOND
TOPOLOGY nobody exercised, and branching on `hasElse` would recreate the two paths that
diverged.**

Emitted IR, `righty = -7`:
```
entry:  %cmp = icmp sgt i32 %unbox, 0
        br i1 %cmp, label %then, label %else
then:   %mul = mul i32 %unbox1, 2
        store i32 %mul, ptr inttoptr (…)     ; maximus
        br label %endif
else:   store i32 7, ptr inttoptr (…)        ; maximus — same address
        br label %endif
endif:  ret i32 7                            ; ⚠ still a constant — see §3.4
```

### 3.2a THE RESULT SLOT — ✅ landed 2026-07-31, and the return value is now path-correct
`jitRunAction` used to cap with `CreateRet(gJitResult)` — whatever the walk emitted **last**,
which on a two-armed if was the last arm *emitted* regardless of which one *ran*, and was a
constant in every fixture dumped. Now: an `i32` **alloca** in the entry block, every statement
stores to it, the exit **loads** it.

**The merge is the memory location.** Each arm stores inside its own block; the exit load reads
whichever ran. That is the same reasoning that makes field stores need no merge, applied to
results — and it is why no phi is written by hand:

```
PRE-mem2reg  (what the emitter wrote)     POST-mem2reg  (what LLVM made of it)
  then:  store i32 %mul, ptr %result        endif:
  else:  store i32 7,    ptr %result          %result.0 = phi i32 [ %mul, %then ], [ 7, %else ]
  endif: %retval = load i32, ptr %result      ret i32 %result.0
         ret i32 %retval
```

⚠ **This is the FIRST alloca this emitter has ever produced, so `PromotePass` finally has
something to promote** — and it inserted the phi itself, which is the "never write a phi"
design working for the first time rather than merely being asserted. §3.4's note that mem2reg
had nothing to do remains true of *field* slots (baked absolute addresses) and is no longer
true of the function as a whole.

**Two things it cost, both found by dumping rather than reasoning:**
- **A bracketing emitter must leave NOTHING in flight.** `jitEmitGIF` commits both arms and
  then clears `gJitResult`; without that the enclosing walk re-committed the stale else-value
  in the merge block and every path returned 7. Visible as two extra `store i32 7` in `endif`.
  **This is a rule for every bracketing emitter, not a gIF quirk — the loop emitters need it.**
- **`if (!gJitResult)` as the "did anything emit" test was falsified** by that clear: an action
  ending in control flow legitimately has nothing in flight, and the old guard read it as "the
  gate never fired" and bailed *before emitting the return*, silently un-jitting every if/else.
  Replaced with an explicit `gJitEmitted` flag set by the store.

⚠ **`INCANT_JIT_DUMP=2` is new and is the more useful mode:** it dumps the **emitter's own
output, before mem2reg**. The post-pass dump alone cannot answer *"did the emitter emit this,
or did the optimiser produce it"* — which is exactly the question a slot or a phi raises, and
the clobber above was invisible in the post-pass dump because folding hid it.

POP: `sh genLadder/jitPop.sh`, fixtures `incant/jitElseT` (the POP) and `incant/jitThenT`
(the regression net). ⚠ **Two files and not one, because a second `testing()` on the same
action in one run hits the sequential-state-corruption tar baby** — the first draft ran both
directions in one process and reported a regression that did not exist.

### 3.3 The `jitData` single-value clobber — INFERRED, blocks everything past Phase 1
`testWhilE` and `testDo` both abort (134) on *"Both operands to ICmp instruction are not of the
same type!"*. Likely mechanism: `jitEmitBinary` and `jitEmitCompare` both end
`target->jitData->setJitter(res)` — **overwriting the target operand's stored SSA value with
the result**. A field compared once holds an **i1** afterward; compared again it is
`icmp i1, i32`.

**Structural, not incidental:** `jitData` hangs off the GroupItem, so a node can hold exactly
one SSA value at a time. Fine for one-shot straight-line expressions; fatal for **any** operand
reuse — which is loops *and* multi-statement bodies.

⚠ **This is `inferred` and it reads convincingly, which per bear-trap #19's corollary is
exactly when to distrust it.** The search space was `jitEmitters.rtn` and `Instruct.rtn` only.
An IR dump answers it immediately — the invalid `icmp` is visible in the text — and the dump
now exists (§1.2), so this is cheap to settle and has not been settled.

### 3.4 What the IR dump showed — and it CORRECTS the record
*asOf 2026-07-30, the first IR ever dumped from this tree.*

```
endif:                        ; preds = %then, %entry
  ret i32 99                  ; ⚠ A CONSTANT — taken and not-taken IR are IDENTICAL
```

- **The store IS properly conditional** — `maximus` correctly stays 11 on the not-taken path.
  ⚠ **This corrects the stored claim "IR: unconditional store + `br i1 true`"**, which
  described the pre-pivot state. Unified emit-on-walk fixed the branch.
- **The return value is not merged.** `jitRunAction` caps with `CreateRet(gJitResult)`, and
  `gJitResult` is a plain C++ global holding one `llvm::Value*` — so the return is *whatever
  the walk emitted last*, regardless of which path runs.

  ⚠ **CORRECTION, 2026-07-31 — the recorded explanation was WRONG and this is the fifth
  causal claim in this domain to fail.** The record said `gJitResult` is "an SSA value defined
  inside the then block — a dominance violation that compiled and ran because nothing verified
  it." **It is not a dominance violation.** The dumps show `ret i32 99` and `ret i32 7` — a
  **constant**, which dominates everything, which is why the IR is valid and why the verifier
  is correctly silent. The defect is that the return has **no defined source**, not that its
  source is unreachable. Same symptom, different mechanism, and the difference matters: a
  dominance violation is fixed by moving a definition, a missing source is fixed by *deciding
  what an action returns* — which is a frame-model question (§`jitDesign.md` O4), not an SSA
  one.
- **Field slots are `inttoptr` absolute addresses, not `alloca`s, so mem2reg has nothing to
  promote.** ⚠ **The "mem2reg is the foundation" position does not hold for baked field
  addresses.** See `jitDesign.md` — this is the sharpest open contradiction in the design.
- **The verifier is SILENT on the gIF fixtures**, and that is itself the finding: *a branch with
  a missing merge is valid IR that computes the wrong thing.* **Validity and correctness are
  different questions**, and only one of them now has an instrument.

### 3.5 Known gaps that are not crashes
- **Compare ops have no null/no-data guards, and the interpreter's are structurally bypassed**
  — each gate `return`s before the guard block below it. A jitted compare on null operands
  crashes or reads garbage rather than returning false. *asOf 2026-07-02, re-confirmed
  2026-07-30.*
- **Seven ops fire their gate assuming a numeric target.** `opPlusEQ` is the ONE that
  type-checks first; `opMinusEQ`, `opDivEQ`, `opMultiplyEQ`, `opMinusMinus`, `opPlusPlus`,
  `opPlus`, `opMinus` do not. Latent while fixtures are numeric-only; real the moment a jitted
  region hits `someString -= x`.
- **`opAssign` with a byRef (`:=`) argument** — the gate returns before opAssign's own byRef
  branch. Never exercised; unknown whether it mis-stores.
- **`jitEmitGIF` nesting** — `gIfEndBlocks` is a stack so it is *provided for*, but
  `testGXLeaf` (two *sequential* `if`s) segfaults before nesting can be reached.
- **Everything downstream of the first failure in a body.** Failures are crashes and aborts, so
  later constructs are never reached — **absence of a report is not evidence of health.**

---

## §4 — THE DOCUMENTATION STATE (it is part of the truth)

### 4.1 `aCTionFOR` is a tree-walk, not a counting loop
*Verified 2026-07-02 by reading `ruleActions.rtn`.* It walks `next()`/`prior()` over a
GroupItem member/attribute list, optionally reversed, optionally restricted — **not**
init/cond/increment. The list being walked is not statically known without walking the parse
tree.

Under "accelerator" the obvious answer was "defer it to a whole-action bail." **Under §0 that
answer is the divergence §0 names**, and the question becomes *"the JIT must be able to walk a
GroupItem list"* — a much larger claim. Unresolved; see `jitDesign.md`.

### 4.2 The cold-reader gap — the source says "accelerator" at every altitude
*Confidence: high; this is a checkable documentation-state question.*

A reader who has not read §0 encounters: `jitting` as a **one-bit mode flag** in `GroupRules`
beside `generating` and `debugGuards` (a mode you can be in reads as a mode you can be out of);
18 gates each sitting **directly above a fully intact interpreted body** in the same function
("fast path above, real path below"); a gate **raised and lowered around a region** in
`jitRunAction`; and a sole entry point named **`testing`**.

§0's ruling appears in exactly **two** places, both docs, and at **zero** of the 20 gate sites.
**That gap has now bitten twice** — once on 2026-07-29 (a reasoner argued for repairing the
interpreter's frame handling, work §0 says explicitly not to do) and once earlier in a doc that
recommended whole-action bail as the *design answer*.

The cheap in-character fix, **not yet applied**: one comment line where `jitting` is declared
(`GroupRules.twk:77`), since that is the definition every gate resolves against.

### 4.3 Stale comment, load-bearing
`ruleActions.rtn:286-291` states *"jitRunAction still raises generating alongside jitting, so
generating is checked first."* **`jitRunAction` sets `generating = 0`.** The comment describes
the pre-pivot world and will mislead the next reader about which XP handler the JIT uses. (It
is `interpretXP`.)

---

## §5 — TOOLCHAIN AND BUILD FACTS

**LLVM 22.1.7**, arm64, `/opt/homebrew/opt/llvm`. Link `-lLLVM-22` (one monolithic shared lib).
`gnu++17` + `libc++`. Proven by a standalone LLJIT smoke test. *asOf 2026-06-17, still the
linked version 2026-07-31 (`-lLLVM-22` in the Groups link line).*

API shapes correct for this version: ORCv2 `LLJITBuilder().create()` /
`addIRModule(ThreadSafeModule(...))` / `lookup()` / `sym->getAddress().toPtr<FnType>()`; own an
`LLVMContext` per action, no `getGlobalContext()`; **opaque pointers** —
`PointerType::getUnqual(Ctx)`, and the type argument on `CreateLoad`/`CreateCall` is
**mandatory**; new `PassManager` + `PassBuilder`, mem2reg = `PromotePass`.

### 5.1 Phase 1 straight-line — the POP table, and READ §7 BEFORE TRUSTING IT
*asOf 2026-06-22 for the arithmetic/compare/assign rows; **the three unary rows are FALSIFIED
as of 2026-07-30** — see §3.1.*

Arithmetic (`jitEmitBinary`): `3+5`→8 · `3.0+5.0`→8 · `3+5.0`→8 (SIToFP promotion) ·
`righty+5`→18 (field unbox) · `8-3`→5 · `3*5`→15 · `7/2`→3 · `10/3`→3 · `-7/2`→-3.
Compare (`jitEmitCompare`, i1 ZExt'd to i32): all six operators correct.
Assign (`jitEmitAssign`, store-back writes through to the GroupItem, verified by readback):
`= 8`→8 · `+= 5`→15 · `*= 3`→12 · `-= 5`→25 · `/= 4`→7.
String `+=` (`jitEmitStringPlusEQ`, the **first and only `CreateCall`**): `name += "!"` →
`world!` by readback.
**Unary — `jitInc` 14, `jitDec` 12, `jitNeg` -13: ⚠ ALL THREE NOW EXIT 139 (§3.1).**

**Division semantics are settled: C-style signed truncation toward zero** (`7/2=3`,
`-7/2=-3`), which **diverges by design** from the interpreter's round-to-nearest (`7/2=4`).
Div-by-zero is deferred/unguarded, matching the interpreter's own unguarded path.

---

## §6 — TOK CONSTRAINTS ON JIT CODE (they cost a day each)

These are the ones specific to writing emitters; the general set is in `CLAUDE.md`.

- **No `llvm::` types in tok-extern signatures.** tok emits a prototype into `GroupRules.h`,
  which only forward-declares classes and drops includes on regen → `undeclared identifier
  'llvm'`. Emitters take/return plain types (`GroupItem*`/`int`) and carry `llvm::Value` in
  `JitData`.
- **Top-level `-% … %-` passthrough is DROPPED** — it only emits *inside a method body*. LLVM
  C++ cannot be poured into a `.rtn` as one passthrough block.
- **`external IRBuilder` dummy is required** beside `external IRBuilder<>` for the template.
- **`/* … */` comment interiors are not inert** — tok has no lexer, so `-% %-` markers and
  *declared* type-names inside a comment get parsed as code (`ERROR Inheritance`, mislocated
  onto the next file's comment). Keep passthrough markers and known type-names out of comments.
- **`JitData` is hung on the node, not held in a C++ side table.** The side-table design was
  tried and fought tok two ways. See `jitDesign.md` — the design doc was never updated to
  match, and that contradiction is live.

---

## §7 — THE DOCTRINE THIS FILE IS ORGANISED AROUND

**A STATUS TABLE IS A CLAIM WITH AN `asOf` THAT NOBODY WROTE DOWN.**

§5.1's three unary rows said DONE for a month while the source comment at the crash site said
"not wired yet" and the binary exited 139. **The rows were TRUE when written** and were
falsified later by a refactor in a file nobody re-ran. They are kept, with the contradiction
recorded beside them, rather than corrected — the reconciliation is worth more than the
correction, and editing them away would destroy the evidence that produces it.

Three rules follow, and they are why every section above carries a date:

1. **Treat a DONE table as `MEASURED`, respect its date, and re-run before building on it.**
2. **An outcome that looks right is not proof.** `jitGifScratch`'s taken→99 / not-taken→11 is
   *suggestive* that the branch is genuinely gated. It was declined as proven until an IR dump
   existed, because the 2026-06-27 disaster was exactly an outcome that looked right.
3. **Exit 0 is necessary and not sufficient** — §3.2 is a wrong answer at exit 0, and it is the
   worst thing on this list precisely because nothing complains.

---

*Consolidated 2026-07-31. Superseded and deleted in the same commit: `jit-recon-2026-07-30.md`,
`jit-coverage-recon.md`, `llvm-jit-recon.md`, `jitFullmontyPlan.md`, `gif-jit-recon.md`,
`jit-phase1-walk.md`. Their reasoning trails are in git; their conclusions are here and in
`jitDesign.md`.*
