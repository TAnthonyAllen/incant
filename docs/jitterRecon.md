# The jitter command -- recon (SEQ 383 R2, 2026-10-19)

Read-only. Nothing built, no command registered. A set of options for Tony; no ruling assumed.
Every number below was measured on 2026-10-19 against trunk 425f5b0 (jit-parse-unjitted bought), in the clone,
with a tap that is now reverted (md5 of GroupActions.rtn / GroupRules.mm / GroupRules.h = before the tap).


> ⚠⚠ **RULED 2026-10-19 (Tony, SEQ 384 R0), recorded in `docs/jit.md` §0 too.** Compiling has no side effects: a
> statement the jit cannot emit becomes a run-time call that runs it interpreted, and nothing executes at build time.
> Compile once: a compiled action is reused, never rebuilt (SEQ 385). Scope: actions only for the first cut; parse
> bodies are the next rung. Spelling: `jitter;` alone, jit at first call from then on -- no off switch, no
> `jitter(name)` for now; `if jitter;` is unsupported (bear-trap #34) and nothing is designed around it.

## (a) What exists today

**One place turns jitting on: `jitBuildFunction`** (`jitEmitters.rtn:290`, off again at `:399`). Since SEQ 382,
`processCode` turns it off around its parse (`GroupActions.rtn:756-758`). Every road below reaches it through
`jitRunAction` (`jitEmitters.rtn:3285`).

| road | registered | compiles | when | where the function is kept | fired by |
|---|---|---|---|---|---|
| `testing(x)` | `incant/setup:82`, bare `immediateAction` | the action x, plus each self-calling callee as its own function | when called; only if `x.isCoded`, else it runs `jitRunIfTest` (bear-trap #25) | `gJitLastFn` / `gJitLastAction` (`jitContext.h:149,153`) -- ONE slot, overwritten by the next compile | itself, once, at the foot of `jitRunAction` (`:3513`) |
| `jitRefire()` | `setup:52` | nothing | -- | reads `gJitLastFn` | calls the last compiled function directly (`jitEmitters.rtn:3243`), NO frame bracket |
| `jitFieldMethod(f)` | `setup:55` | f's definer, on its first fire | first fire | `definer->groupBody->gJitMethod` (`:2475`) -- a per-body slot | itself; later fires go through the slot (`:2446`) |
| `probeDrive(...)` / `jitProbeDrive` | `setup:53` | one rule's `builtinParseR` carrier, compile-only (`gJitCompileOnly`) | when called | a static 256-entry table inside `jitProbeDrive` (`:877`) | the probe door in `parseRule` (`Generate.rtn:309`), for that drive only |

Env switches change no road: `INCANT_JIT_DUMP` (IR dump), `INCANT_JIT_RECORD` (IR to the `JiT` attribute),
`INCANT_SLOT_PROBE`, `INCANT_PRINT_PROBE`, `INCANT_KIND_PROBE` -- all instruments.

**A normal run never consults a compiled function.** `runAction` (`GroupActions.rtn:1125`) reads no slot; only
`jitFieldMethod` reads `gJitMethod`. So an action compiled by `testing()` is interpreted the next time it is called
by name. And `testing()` compiles an action at most once per process: the first parse clears `isCoded`, so a second
`testing(x)` runs `jitRunIfTest` instead (measured: L4 / L8 below).

## (b) The forced-jit census

**The tap.** In `runAction`'s interpreted arm, gated by `INCANT_JIT_ALL=<tally file>`: at an action's FIRST call,
compile it (`gJitCompileOnly`, compile output silenced, stderr to `<tally>.err`); if it compiled, fire the compiled
function in place of `processAction` on this and every later call, inside `runAction`'s own save/restore bracket,
its i32 boxed as the result (`jitBoxCountRT`). A refused compile runs interpreted and is not retried.
`INCANT_JIT_ALL_AFTER=parser` arms it only after the first `parser(...)` returns, so the generator is not jitted.
`gJitLastFn` is saved and restored around the tap's compile so `jitRefire` is not disturbed.

**Population.** Every file in `incant/pop` and `incant/pop/jit`, each run three times, each run capped at 60 s: tap
off, tap off again (a noise check), and tap on. stdout and stderr are kept separate and compared with addresses
masked. **Old road** = the file as it is. **New road** = a scratch twin with `parser(Start);` after its last top-level
`search` line, with the tap armed after it (5 files have no `search` line and were skipped). The 26 old-road files
that call `parser()` themselves crashed in the jitted generator, so they were re-run with the generator excluded,
and those re-runs are the rows counted here. The generator result gets its own cluster (D below).
The fixit citizens are not in the population; `refireSkipsDegraded` and `jitSetFlagTemp` call no action by name, so
the tap never reaches them.

**pop.sh with the tap on (old road):** 1505 green -> **784 green, 763 FAIL**, no timeout. That number is what pop.sh
reads; the breakdown below is per fixture.

| per fixture | old road | new road |
|---|---|---|
| agree (tap compiled something; output identical) | 68 | 67 |
| DISAGREE | 98 | 110 |
| exits during the compile (exit 0, run truncated) | 8 | 6 |
| crash during the compile | 7 | 5 |
| crash after compiling | 3 | 2 |
| hang (60 s cap) | 0 | 0 |
| untouched (no action called by name; includes .target / .golden files) | 47 | 36 |
| compiles / refused / with a degrade | 562 / 201 / 282 | 582 / 199 / 278 |

Noise check: every tap-off pair matched with addresses masked, so no DISAGREE row is a noisy fixture.

### The clusters, by mechanism

**A. A statement with no emitter runs at EMIT time, once, and never at fire** (`refireSkipsDegraded`). The 
degrade lines, counted over every compile: `cerr` sink 810, `cout` sink 372, print parts 20, FOR 9-11, and others
in single digits. 95 old / 92 new fixtures carry a sink degrade; of the 98 old-road DISAGREE rows, 57 carry one.
The output of a body's `cerr` happens during the compile, where the tap silenced it, and never on any later call.
Without the silence it would print once, at compile, out of order. This is the largest cluster and it is the whole
oldest fixit, at scale.

**B. `IF condition produced no value -- the whole IF runs INTERPRETED`** at emit time (627 / 622 lines, 50 / 48
fixtures). The same class as A: the IF's effect happens once, at the compile, and not again.

**C. A second compile of any action whose name is already in the JIT fails: `duplicate definition of symbol`,
rc -3** (114 compiles, 49 fixtures on each road). Measured on jitRecurSaveT: `testing(rsDrive)` built `jit_rsF`;
the tap's compile of rsDrive at the interpreted call built `jit_rsF` again, and `addIRModule` refused it
(`jitEmitters.rtn:3495`). Names are `jit_<tag>` and the JIT dylib lives for the process, so **every function is
compile-once per process**. A refused compile falls back to the interpreter, which is why many of these files AGREE.

**D. The parse generator, jitted** (old road, the files that call `parser()`; first-call jitting from process start
on the new road too). `parser` and `walkRules` are refused by the verifier (rc -5, degrade 22 / 11, in 37 files).
`generateParse` compiles (degrade 3) and its fires crash the run: 25 crashes, all of them this one.

**E. A command in the body runs at emit time and ends the process**: 8 old / 6 new, every one an action whose
body holds `stop();` (alRun, aonParser, bqRun, cdRun, fbRun, opRun, pcRun, tkRun). The run exits 0 inside the
compile, its output truncated.

**F. Crashes in the compile:** (i) the action calls `testing()` itself (testUnitTests -> testRecursion; ctlStampT's
ctEmitLeak), so the emit-time `testing()` starts a NESTED `jitRunAction` that resets the builder globals of the
build in flight. It dies at the foot's `B.CreateBr(gJitEpilogueBB)` (`GroupRules.mm:3708` in the clone).
(ii) An emit-time interpreted statement derefs null: spacingT spRun in `opDeref` (null), foldAndT K1 in
`opAddAttribute` (null argument) under `jitEmitGIF`.

**G. Value disagreements with no degrade** (22 old / 16 new). These are the interesting ones and are not one
mechanism: halfLessT (the jitted compare is RIGHT -- below); jitCmpOperandT `store` (jitted 0 where interpreted is
the tag); chanT (runAction's argument-channel counters: binds 4 -> 1); jsonTest, starDotNullT, iterRefuseT,
ruleCount (a refusal that interpreted does not raise); retProbe and argRetiredT (print lines missing: a print that
ran at emit); displayFormT / jitDfProbe (a tag read back as `displayForm`). Not chased.

## (c) Known hazards on that path

| hazard | shows up in (b)? | how often |
|---|---|---|
| refireSkipsDegraded | **yes, it is cluster A+B** | 282 degraded compiles; 95 / 92 fixtures with a sink degrade |
| kindSRT, a jitted local keeping its value across fires | **no** -- kindSRT AGREES on both roads (srRunI compiled once, fired twice, empty 2 / 2). The tap fires through runAction's save/restore bracket, which clears the local; `jitRefire` fires with no bracket, and that is where kindSRT pins 2 4 | 0 |
| the argument slot is i32 only (parked, SEQ 382 R0) | **not reached** -- jitArgNumberT's tap compiles were both rc -3 (cluster C), so it ran interpreted and agrees | 0 measured |
| halfLessFalse | **yes, and the jit is right**: halfLessT's new-road line reads `0.5<1 1  1<2 1  1<0.5 0  1.5<2 1` jitted (= intended) against `0 1 0 0` interpreted | 1 fixture |

## (d) Lifecycle

Measured on trunk with a scratch fixture (`life`, `life2`):

- **A second `define` of an existing action does NOT replace its code**, even before any call (M1: redefined
  before first call, still runs the first body; M3: interpreted after a redefine, the old body). So "redefine"
  has no road today, and compiled code cannot go stale through one. Mechanism not chased.
- **Compiled action, then a redefine**: `jitRefire` runs the old function (L2), the interpreted call runs the old
  body (L3), and a second `testing()` does not compile at all -- `isCoded` was consumed, so it routes to `jitRunIfTest` (L4).
- **Compiled driver, then its callee redefined**: the same (L6, L7, L8): an inlined callee is baked into the driver.
- **Invalidation today: none.** `gJitLastFn` is overwritten only by the next compile; `gJitMethod` is never
  cleared; the JIT dylib keeps every `jit_<tag>` for the life of the process, and a re-compile of the same name
  refuses (cluster C).

## (e) Scope: actions only, or rule parse bodies too

**What jits today for parse bodies:** a `builtinParseR` carrier compiles through `jitProbeDrive` / `probeDrive`,
one armed carrier at a time, compile-only, fired by the probe door inside `parseRule` for that drive. `probeDoorT`
certifies jitted = interpreted on ExpressioN, StatemenT, PrinT, DO, IF and WhilE. Nothing installs a compiled
carrier for a normal parse; no road jits every carrier.

**A first cut covering ACTIONS only would need:** a compiled-function cache that a normal call reads (runAction has
none; per body, as `gJitMethod` already is); compile-once naming, or a module per action (cluster C); a decision for
every construct that degrades (A, B: either refuse the compile and interpret, or give them emitters -- `cerr` and
`cout` are 1182 of the degrades); a guard so a body that calls `testing()` or `stop()` is not compiled (E, F-i); a
fallback rule (the open ruling in `docs/jit.md` §0: falling back is divergence); and the generator excluded (D).

**Covering parse bodies too adds:** a dispatch from `parseRule` to a compiled carrier for every drive (the probe
door is one-carrier, one-drive); a cache keyed on carrier rather than on action; and the parse's own conventions:
the one-bit return (`runRule`, `GroupActions.rtn:1322`), the floor and labels, `refused` across terms (see R1's
jitParseRefuseT paragraph). The census here measured actions only, so what a parse-body jitter would meet is
unmeasured beyond probeDoorT's six rules.

## (f) Spelling options, not a design

All three register like every other command: an entry in `incant/setup`'s cOMMANDs block with
`immediateAction=<extern>` (cOMMANDs is the registry; immediateAction is how an entry binds). The extern returns
`GroupItem` (bear-trap #33), and needs a `groups.ext` line only if it is called across files.

| shape | what it would cost |
|---|---|
| `jitter;` -- jit-at-first-call from this point on | a process-wide flag read in runAction's interpreted arm (where the tap sat), plus everything (e) lists for actions. Measured: a bare command name as a statement FIRES it (`jitRefire;` printed its line), so the bare spelling works today |
| `jitter(name);` -- compile one action | is `testing()` without the fire, plus the cache that makes later calls use it. Smallest; it meets clusters A, B, C, E and F for that one action only |
| an off switch | "off" has three readings: stop compiling new actions (compiled ones still fire); stop firing compiled ones too (the cache stays, and runAction ignores it); or drop the cache (the JIT keeps the symbols, so a later "on" cannot recompile them -- cluster C). Only the first two are possible without compile-once naming |

**Bear-trap #34's exposure:** measured on `jitRefire`: `if jitRefire;` FIRES the command and reads false. So
`if jitter;` would turn jitting on as a side effect of a test. A command meant to be tested needs a separate query
spelling, or none.
