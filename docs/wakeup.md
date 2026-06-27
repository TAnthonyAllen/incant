# Incant — Status & Handoff (2026-06-27: Phase 2 JIT — gIF scaffolding)
*Written by Clod for a fresh Clay/Clod tomorrow. Assumes no memory of today. Self-contained.*

## What this is
**Phase 2 JIT = control flow (`gIF`).** Today the gIF **scaffolding** landed and is wired
end-to-end — the JIT walk + LLVM block topology + then-arm store are **proven by running**.
One seam is open: emitting the **condition compare** under jitting, which intersects the
compare-operator design Tony + Clay are settling. Three clean commits, all pushed, tree green.

## The lens (hold these to reason about the JIT)
- **Two independent lowerings of the same parsed tree.** Bytecode (`generateCode` → `generatE`
  walk → `gIF`/`gXpress` emit bytecode) and JIT (LLVM IR) are *parallel*, not a pipeline.
- **How straight-line JIT runs:** `testing(action)` → `jitRunAction` (`jitEmitters.rtn`) sets
  `jitting=1`, calls `processCode` which **parses the body and emits LLVM IR *during the
  parse*** — each opMethod (`opPlus`/`opLT`/`opAssign`/…) has an `if jitting { … }` gate that
  emits straight into `gJitBuilder`. Caps with `CreateRet(gJitResult)`, ORC-compiles, runs.
  This emit-during-parse model is proven (25 straight-line POPs) and is NOT touched.
- **Why control flow is different:** an `if` is **deferred** — it never executes during the
  parse, so it can't emit during parse. Control flow needs a **walk** over the cached BlocK
  *after* processCode. That walk is what landed today.
- **PromotePass is wired** (`jitRunAction` runs `llvm::PromotePass` before `addIRModule`) — so a
  value-producing if's merge phis come from LLVM, never hand-written. (No-op on today's IR.)

## Current state — commits on `main` (newest last)
- `33206bb` — **Kitchen clean**: Tony's offline ANYorNum parse + setFrame + new Stylish class +
  `incant/baselineTests.golden` refresh. POP verified green before commit.
- `2e5cff9` — **`jitRunIfTest`** control-flow branch smoke test (the `jitRunAddTwo` analog).
- `99a8313` — **gIF walk + block-management scaffolding** (this session's main work).

## DONE — proven by actual run output (not shape-read)
- **Multi-block branch + store-to-field-slot** (`jitRunIfTest`, the first multi-basic-block IR in
  the JIT layer). Hand-builds `i32 f(){ if (fld<0) fld=99; return fld; }` against the field's
  baked `gCount` slot. Verified: `maximus=-7 → 99` (then taken, field mutated), `maximus=5 → 5`
  (not taken). Drive via `testing(<count field>)` — `testing()` now routes a **non-coded** arg
  to `jitRunIfTest`, a coded action still to `jitRunAction` (25 POPs preserved).
- **The gIF walk + block topology + then-arm store.** `jitWalkBlock → jitGeneratE →
  jitRunGenerated → jitEmitGIF` dispatches correctly (confirmed via crash backtrace AND clean
  run), and the then-arm `CreateStore` lands in the field slot through the branch:
  `jitGifScratch` taken → `maximus=99`. The pieces:
  - `jitIfBegin`/`jitIfEnd` (`jitEmitters.rtn`, LLVM-native): create then/endif blocks,
    `CreateCondBr` on the condition i1 (`gJitResult`; coerces `!=0` defensively),
    `SetInsertPoint(then)`; then `CreateBr(endif)` + resume at endif. Shared endif-block stack
    `gIfEndBlocks` in `jitContext.h` (inline, nests for future nested ifs).
  - `jitEmitGIF` (`jitEmitters.rtn`, tok-native, the `aCTionIF` mirror): re-enter condition
    gMethod → `jitIfBegin` → re-enter then-arm gMethod (store-back) → `jitIfEnd`.
  - `jitGeneratE`/`jitRunGenerated`/`jitWalkBlock` (`jitEmitters.rtn`): walk the cached BlocK,
    dispatch a node carrying a `StatemenT` child (control flow) to `jitEmitGIF`; straight-line
    members already emitted during parse → no-op.
  - `jitRunAction` drives `jitWalkBlock(action)` after `processCode`, still under `jitting`.
- **No regressions:** `jitscratch` 25/25 (`jitNeg → -13`), `oneTest → 26`, `jsonTest` ok.

## OPEN — the Phase-2 frontier (one seam, intersects compare design)
**`jitEmitGIF`'s condition does not yet emit a compare `i1`.** Root-caused (empirical, 3 attempts,
binary-verified):
- The `if`-condition `ExpressioN` is **wrapped** (listLength 1). Re-entering its gMethod hits
  `aCTionExpressioN`'s jitting **`listLength==1` short-circuit** (lines ~277-292, `ruleActions.rtn`)
  which seeds the single operand and returns *before any compare emits*. So `gJitResult` ends up
  the operand value (e.g. `righty`'s load), not the compare `i1` — and `jitIfBegin`'s `!=0`
  coercion makes **both** branches "taken" (`jitGifScratch` not-taken wrongly → 99).
- **`unWrap` over-descends**: it follows `.group` while `isGROUP`, landing on a leaf token (null
  `groupList`). `aCTionExpressioN` dereferences `groupList->listLength` unconditionally → **fault**.
  (The bytecode `gXpress` tolerates a leaf; the jitting gate does not.) Don't hand `aCTionExpressioN`
  a leaf.
- **The fix = the correct descent**: feed the **multi-token compare list** (`righty < 0`, listLength
  3) through the jitting gate so it runs the while-loop → `jitEmitCompare` → `i1` into `gJitResult`.
  That descent (and whether `aCTionExpressioN`'s `listLength==1` branch should *recurse* on a wrapped
  sub-expression instead of seeding) is exactly the compare-emission shape Tony + Clay are settling.
  **`jitIfBegin` already consumes whatever `i1` `gJitResult` holds — once the condition emits a real
  compare, the branch gates correctly with ZERO change to the scaffolding.**

## To resume — next actions in order
1. **Wire the condition emission** with the compare shape Tony + Clay land. The crux is the descent
   from the wrapped `if`-ExpressioN to the multi-token compare list, run through the jitting gate.
   Candidate approaches: (a) the right node access + descent inside `jitEmitGIF` (not `unWrap` —
   it over-descends; not raw gMethod — it short-circuits); (b) make `aCTionExpressioN`'s jitting
   `listLength==1` branch recurse into a wrapped sub-expression (touches the proven gate — guard the
   25 POPs). **Verify by running:** `jitGifScratch` not-taken must become `maximus=11` (taken stays 99).
2. **else-arm** (a second block + `CreateBr` past it), then **nesting** (the `gIfEndBlocks` stack
   already supports it), then **compound conditions** (`a<0 and b>0` — the chained-operand bear in
   `jit.md`).
3. **Refactor** `jitRunGenerated`'s StatemenT-child test into a real `jitGenerator[node]` lookup
   (the `generator[]` parallel) once a second handler (gWhile/gFor) lands — one kind needs no registry.

## Run recipe (verify green before starting)
```
~/bin/incant incant/oneTest        # -> "maximus = 26"
~/bin/incant incant/jsonTest       # -> ok : {"a":[]} / ok : {"a":["x","y"]}
~/bin/incant incant/jitscratch     # 25 JIT POPs, incl. jitNeg -> -13
~/bin/incant incant/jitIfScratch   # smoke: maximus=-7 -> 99 ; maximus=5 -> 5
~/bin/incant incant/jitGifScratch  # gIF: taken -> 99 (proven); not-taken -> 99 (OPEN seam)
```
(Boot noise `getRStuff:` is normal. For a crash backtrace run under `script -q /dev/null …` —
segfaults otherwise lose buffered stdout. The full Swift frames + source lines print.)

## Gotchas (durable — will bite again)
- **`aCTionExpressioN` dereferences `groupList->listLength` unconditionally** — never hand it a leaf
  (null list). `unWrap` over-descends to a leaf; the wrapped condition needs the multi-token list.
- **`testing(<coded action>)` → `jitRunAction`; `testing(<non-coded field>)` → `jitRunIfTest`** (the
  branch smoke test). Don't repurpose `testing()` without preserving both routes.
- **`ruleActions.rtn` / `Instruct.rtn` / `jitEmitters.rtn` / `Commands.rtn` are `include`d INTO
  `GroupRules.twk`** (L286-294) and tok-processed into `GroupRules.mm`. Editing them needs
  **`tok GroupRules.twk` THEN `xcodebuild`** (Groups scheme of `../TOK/TOK.xcodeproj`) — `xcodebuild`
  alone silently recompiles the stale `.mm`. Sanity-check `grep -c extern GroupRules.h` ≈ 152 (a
  wipe to 0 means a parse error cascaded — usually a missing `groups.ext` proto, bear trap #10/#11).
- **`groups.ext` is the prototype home and lives OUTSIDE the repo**
  (`~/Dropbox/data/InProcess/Include/groups.ext`). A tok-native call from an *earlier*-included
  file to a *later*-defined extern needs its proto there. Intra-file forward calls do NOT (today's
  new jit externs all resolve in-file, so no `groups.ext` edits were needed this session).
- **`gMethod` is a function pointer on `groupBody`** — in raw C++ (`-% %-`) call it
  `x->groupBody->gMethod(x)`; tok does NOT translate `.gMethod` inside passthrough. It can be null.
- **`nm`, not `strings`**, to confirm a symbol compiled in; binary mtime is unreliable; interpreted
  `incant/*` runs fresh. `~/bin/incant` symlinks to the DerivedData `Groups` product.

## DEFERRED — not this arc; whose call
- **GUI content dispatch** (text/image/cell/path off `Layout.drawRect`) — the other big active
  thread. Platform is solid; content handlers are **Clay's design conversation**
  (`docs/gui-brief.md`, `docs/font-recon.md`). Also parked: drop the `printf` in `guiHost.mm`;
  `viewDidEndLiveResize` re-layout.
- **gIF beyond the condition seam:** else-arm, nesting, compound conditions, return-real-GroupItem
  epilogue, slot-array calling convention (`jit.md`).
