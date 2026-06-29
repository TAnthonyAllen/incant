# JIT Igor — Corpus

> **RENDER — not canonical.** The source of truth is now `incant/jigcorpus` (the
> live incant corpus), which round-tripped a clean POP load on 2026-06-29. This
> markdown is the human-readable render of that file; update `jigcorpus` first.

*A minion corpus in the v0 format (`docs/minion-corpus-format.md`). First instantiation.
The corpse Igor reanimates each session. Load this; you ARE the JIT authority for one task.*

```
minion:    JIT Igor
domain:    The incant JIT — frame/slot model, the opMethod-gate emit path, Phase 1
           straight-line (done) and Phase 2 control flow (gIF, open).
lastBaked: 2026-06-28
sources:   docs/jit.md · docs/wakeup.md (2026-06-27 PM) · CLAUDE.md (Phase Bytecode/JIT) ·
           docs/branch-dispatch-findings.md · git (branch state, 2026-06-28)
```

---

## claims — VERIFIED (bones: trace / IR / readback / run)

- **id:** phase1-complete
  **text:** JIT Phase 1 (straight-line) is complete — 24 POPs proven end-to-end in one pass via
  `jitRunAction`: arithmetic, compare, assign, unary, division, string `+=`.
  **confidence:** verified · **provenance:** jit.md:172–309 (POP tables), driver `incant/jitscratch`
  · **asOf:** 2026-06-22

- **id:** plan-a-gate
  **text:** The emit path is **Plan A** — the `jitting` gate lives *inside* each opMethod
  (`opPlus` grows `if jitting { … }`); `aCTionExpressioN`'s jitting branch dispatches the
  operator's own `operat`, which self-gates. At endgame the interpret body strips and the opMethod
  *is* the emitter. (Plan B — emitter on a `jit` child — abandoned.)
  **confidence:** verified · **provenance:** jit.md:174–180 · **asOf:** 2026-06-22

- **id:** unary-minus-done
  **text:** Unary minus (`jitNeg`) is done and is **value-producing with NO store-back** (`-righty`
  → `CreateNeg`/`CreateFNeg`, result -13). The grammar half: prefix `-` via `ANYorNum^` operand +
  `negate`→`opUnaryMinus`; spaced ` - ` stays binary `opMinus` via no-skip adjacency. This was the
  Phase 2 prerequisite.
  **confidence:** verified · **provenance:** jit.md:217–234, 320–327 · **asOf:** 2026-06-25

- **id:** bytecode-gif-works
  **text:** The **bytecode** gIF works via the **C++ `interpretBC`** dispatch loop:
  `testByteCode` false→11, `testIfElse` true→26 (init `maximus=11`; only correct two-way branching
  yields 11/26). Note: this is the *bytecode* lowering, **separate from the JIT** (parallel
  lowerings, not a pipeline).
  **confidence:** verified · **provenance:** CLAUDE.md (Phase Bytecode Status), docs/branch-dispatch-findings.md
  · **asOf:** 2026-06-11

- **id:** main-baseline-green
  **text:** `main` is baseline green. Run recipe results: `oneTest`→`maximus=26`; `jsonTest` ok;
  `jitscratch` 25 POPs (`jitDec`→12, `jitNeg`→-13); `jitIfScratch` (hand-built IR smoke) -7→99 / 5→5;
  `jitGifScratch` taken→99 **but UNCONDITIONAL** (see refuted: jit-gif-branches).
  **confidence:** verified · **provenance:** wakeup.md:87–94 (run 2026-06-27) · **asOf:** 2026-06-27
  *(bones from the 2026-06-27 handoff run, not re-run 2026-06-28 — aging; re-verify if it matters)*

- **id:** wip-branch-state
  **text:** Phase 2 JIT WIP is parked on branch `jit-unified-emit-wip` (commit `28347a7`); `main`
  is clean. Confirmed by git this session.
  **confidence:** verified · **provenance:** git branch/log, 2026-06-28 · **asOf:** 2026-06-28

- **id:** gif-blocker-hang
  **text:** The unified-emit gIF **hangs** in `jitXpress(condition)`. Root cause traced: the
  if-condition `righty < 0` is **wrapped (listLength 1)**, so `aCTionExpressioN`'s `listLength==1`
  path stuffs the whole wrapped runOP-tree into the revisedList instead of flattening to RPN
  `[righty, 0, <]`; the wrapper's next-chain cycles raw parse `Token`s → infinite loop.
  **confidence:** verified · **provenance:** wakeup.md:53–64 (traced 2026-06-27) · **asOf:** 2026-06-27

- **id:** wip-unary-regression
  **text:** The WIP regressed `jitInc`/`jitDec`: in-place store-back lost (`righty` stayed 13 vs
  baseline 12). The unary path through the revisedList isn't at parity yet.
  **confidence:** verified · **provenance:** wakeup.md:58–60 · **asOf:** 2026-06-27

---

## claims — REFUTED (kept, not deleted — the trail is the point)

- **id:** jit-gif-branches  ⭐ *the poisoned-pie demonstrator*
  **text:** ~~The JIT gIF then-arm store is proven through the branch (taken→99).~~ **FALSE.**
  Hard IR (righty=-7, this run) shows an **unconditional store in the entry block**, `br i1 true`
  (not `%cmp`), and an **empty then-block** — a dead branch. "taken→99" was a parse-time
  unconditional store, not a taken branch. The prior wakeup's "proven through the branch" was a
  **shape-read**, not bones.
  **confidence:** refuted · **provenance:** IR dump 2026-06-27 (wakeup.md:11–27) · **asOf:** 2026-06-27
  **supersedes:** the prior wakeup.md claim
  > Lesson: this is exactly the failure the corpus format exists to prevent. A `verified`-looking
  > claim that was only ever shape-read. Recorded `refuted`, never silently dropped.

- **id:** incant-interpretbc-branches
  **text:** ~~The incant `interpretBC` took the branch (2026-06-10).~~ **FALSE** — a shape-read;
  under a clean run it fell straight through. The branch works only via the **C++** `interpretBC`
  (see verified: bytecode-gif-works). The incant `interpretBC` is retired.
  **confidence:** refuted · **provenance:** CLAUDE.md (2026-06-11 resolution) · **asOf:** 2026-06-11

---

## claims — INFERRED (design/decided, not yet run — do NOT serve as fact)

- **id:** frame-slot-model
  **text:** Design (jit.md): action definition = read-only **frame schema** (its field list);
  each call allocates a **fresh native-typed slot array** (prologue unboxes GroupItem→native,
  epilogue reboxes). Recursion falls out because each call owns its array. Native slots
  (`isCOUNT`→i32, `isNUMBER`→double) are Phase 1's choice over GroupItem* slots.
  **confidence:** inferred · **provenance:** jit.md:29–139 (design) · **asOf:** 2026-06-10
  *(design intent; the slot-array calling convention itself is NOT yet built — see open: slot-abi)*

- **id:** unified-emit-model
  **text:** Decision (Fearless+Haps): stop emitting during parse; mirror the bytecode generate
  route — parse builds a flat-RPN `revisedList` and emits nothing, then a post-parse walk
  (`jitWalkBlock`→`jitGeneratE`→`jitEmitGIF`+`jitXpress`) emits LLVM in block context. Scaffolding
  built on the WIP branch; not yet proven (blocked by gif-blocker-hang).
  **confidence:** inferred · **provenance:** wakeup.md:29–52 · **asOf:** 2026-06-27

- **id:** jitbuildlist-fix
  **text:** Agreed fix for gif-blocker-hang: a short **runOP clone** (`jitBuildList`, model on
  `runOP` at GroupActions.rtn:441) that walks structurally like runOP but **accumulates a flat RPN
  list** instead of firing opMethods; wire into the `listLength==1` path so wrapped sub-expressions
  flatten. Same list shape `jitXpress`/`gXpress` already consume.
  **confidence:** inferred · **provenance:** wakeup.md:66–74 (agreed, unbuilt) · **asOf:** 2026-06-27

---

## openItems

- **id:** open-gif  **text:** Build `jitBuildList`, wire to `listLength==1`; verify `jitGifScratch`
  not-taken → `maximus=11` **gated** (IR must show `br i1 %cmp` and the store inside `then:`, not the
  entry block). **why:** this is THE Phase 2 frontier; gated branch is the proof.
- **id:** open-unary-regression  **text:** Restore `jitInc`/`jitDec` store-back through the
  revisedList path. **why:** straight-line parity must hold before declaring gIF green.
- **id:** open-epilogue  **text:** Return a real `GroupItem*` via the full epilogue (driver
  currently caps native `i32`). **why:** the frame model's calling convention isn't real until this.
- **id:** open-slot-abi  **text:** Slot-array calling convention for non-stable fields +
  recompile-on-edit (current unbox bakes a *stable* address). **why:** generality beyond folded fields.
- **id:** open-chained-operand  **text:** Gate guard for chained operands — `a+b+c` mis-routes the
  inner result to `jitSeedField` (assumes non-literal = real field). **why:** latent; bites when
  chaining lands (bear-trap #9, CLAUDE.md).
- **id:** open-jitemitcall  **text:** `jitEmitCall` — method calls on the list. **PARKED for
  Clay+Tony design before Clod touches `runOP`.** Gate point: `runOP`'s `or op.isMethod` branch.
  Open design: a one-arg `concatenate` primitive as the durable shape. **why:** generalizes the
  proven string-`+=` `CreateCall`.
- **id:** open-byref-escape  **text:** Can a `:=` pointer-to-slot escape its frame? Answer
  determines stack vs heap slot allocation. **why:** working lean is heap (BDWGC); stack is a later
  non-escape-analysis optimization.

## scouts

*(none yet — this corpus was baked from docs, not scout recon. First absorb/challenge cycle will
populate this when Tonto next reports on a JIT question.)*

---

*Baked 2026-06-28 by Clod from the sources above. To resume JIT work, the live operational handoff
is still `docs/wakeup.md` — this corpus is the queryable knowledge layer over it, not a replacement.*
