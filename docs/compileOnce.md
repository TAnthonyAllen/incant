# Compile once -- SEQ 385 R1 (2026-10-19), branch jit-compile-once

**The ruling:** a compiled action is reused, never rebuilt, so a later `testing()`, `jitRefire` or forced compile
answers from the cache. STOP if reuse needs a decision about invalidation.

## Recon (trunk f2eb312, file:line)

**Where a second compile collides.**

| what | where |
|---|---|
| the symbol: `jit_<tag>` (a carrier: `jit_<holder>_<tag>`), from the action's identity on purpose (persistence premise) | `jitEmitters.rtn:220-232` |
| in-module collision check, -9 (unreachable by design: one module per compile) | `jitEmitters.rtn:247` |
| the JIT session: ONE `LLJIT`, a function-local static, alive for the process; every module goes into its main dylib | `jitEmitters.rtn:2592` |
| a fresh `LLVMContext` + `Module` per `jitRunAction` | `jitEmitters.rtn:3494` |
| **the collision**: `addIRModule` refuses a module that defines a name the dylib already holds -- `duplicate definition of symbol '_jit_coF'`, rc -3 | `jitEmitters.rtn:3681-3688` |
| the per-compile callee map, cleared at entry and after the add -- so a callee built in an earlier compile is NOT found, and is rebuilt | `jitEmitters.rtn:3515`, `:3698`; `jitContext.h:508` |
| `testing()` routes by `isCoded`; the first parse turns `isCoded` into `isAction` (one 2-bit field), so a second `testing(x)` goes to `jitRunIfTest` and never reaches the compiler | `Commands.rtn:570`; `GroupActions.rtn:764` |

**Where a compiled function is stored and looked up today.**

| store | written | read |
|---|---|---|
| `gJitLastFn` / `gJitLastAction` -- ONE slot, the last compile | `jitEmitters.rtn:3707-3708` (after `jit->lookup(fnName)`, `:3703`) | `jitRefire` (`:3444`), `jitProbeDrive` (`:1009`) |
| `groupBody->gJitMethod` -- per body | `jitFieldMethod` only (`:2666`) | `jitFieldMethod` only (`:2637`) |
| `pcFn[256]` -- a static table of probe carriers | `jitProbeDrive` (`:999-1009`) | `jitProbeDrive` |
| `gJitFnMap` -- callees of THIS compile, `llvm::Function*` | the build loop (`:3552`) | the self-call emitter (`:2093`) |

No store is keyed for reuse across compiles, and a normal call (`runAction`) reads none of them.

**Invalidation: none needed, measured** (scratch `lifeT`, trunk binary, 2026-10-19). After `testing(lfA)` and
`testing(lfB)` (lfB calls lfC), a second `define` of lfA and lfC, then interpreted calls: lfA reads 1 (the OLD body),
lfB reads 3 (the OLD callee), lfC reads 3 (old); a NEW action in the same second `define` runs (5), so the define
itself took. That agrees with `docs/jitterRecon.md` (d). The population searched for other roads that change a
compiled body: redefinition (measured above) and the directive splice (`applyDirectives` / `spliceDirectives` /
`DiR`: no occurrence in any `.rtn` or `.twk` today). No STOP.

## The cure (branch)

`gJitCache` (`jitContext.h`): every function the JIT accepted, `{GroupBody*, name, pointer}`, written once by
`jitRunAction` after its lookup -- the driver and every callee the module DEFINED. Three readers:
- `jitRunAction`, at entry: a cached driver is fired from the cache (`=== jitRunAction: X REUSED as jit_X ===`),
  `gJitLastFn` / `gJitLastAction` set as a compile would, the same count lines printed; no module is built, so the
  compile count does not move and the `JiT` record stays as built.
- the build loop: a callee the JIT already holds is DECLARED in the new module by name (`callee X REUSED as jit_X`)
  and the JIT links the call to the existing function.
- `testing()`: an action in the cache goes to `jitRunAction` even though `isCoded` is spent.

`jitFieldMethod` and `jitProbeDrive` keep their own slots; both compile through `jitRunAction`, so both now hit the
cache instead of the duplicate refusal. Canary 359, unchanged; no `groups.ext` line.

## Pre-registered movers (written before the cure was built)

Census on trunk: every fixture under `incant/`, `incant/pop/`, `incant/pop/jit/`, `jitLadder/` that calls
`testing(`, `jitFieldMethod`, `probeDrive` or `jitRefire` (93 files), run once, grepped for a duplicate-symbol
refusal, for a `jitRunIfTest` on a name compiled earlier in the same run, for a `jitFieldMethod` first fire of a name
compiled earlier, and for any action compiled twice in one run. Hits: **jitCompileOnceT only** (born red for this).
The two `builtinParseR` names compiled twice (probeDoorT, site1RoadsT) are distinct carriers with distinct holders
(`jit_<holder>_builtinParseR`), distinct bodies, so the cache does not join them.

- pop.sh: the 6 born-red jitCompileOnceT rows go green (CO-2, CO-3, no duplicate, counts `1 2 2`, the REUSED
  lines, the IR's define/declare). H3: an address, the fixture-name count.
- jitLadder: none.
- The forced-jit census: cluster C (duplicate symbol, 49 fixtures, 114 compiles) leaves.
