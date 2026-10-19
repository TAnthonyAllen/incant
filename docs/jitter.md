# The `jitter;` command, first cut -- SEQ 386 (2026-10-19), branch jit-jitter

**The rulings** are in `docs/jit.md` §0 (SEQ 386 R1): `jitter;` turns on jit at first call from that point in the run
onward; actions only; no off switch, no `jitter(name)`, no `if jitter;`; a compile that fails, refuses or is
verifier-rejected marks the action NOT JITTABLE (announced once, by name, interpreted from then on, never retried);
top-level statements stay interpreted; parse bodies keep their road (`probeDrive`); an action already compiled is reused
from the cache (SEQ 385).

## R2 recon (trunk 3edc07f; taps in the clone only, each reverted md5-identical)

### (a) The call roads

Measured, not read alone: a tap in `processAction` naming its caller (`dladdr` of the return address) across every
`incant/pop` and `incant/pop/jit` fixture.

| caller of processAction | calls | what it is |
|---|---|---|
| `runAction`, interpreted arm (`GroupActions.rtn:1165`) | 8,915 | every action call by name -- `opCall`'s action case (`:596`), from both the accumulator road (`runOPaccum`, `:1240`) and the slot road (`runOPslots`, `:1290`); `opCallTest` (`Instruct.rtn:206`); and a statement a compiled body handed to run time (`jitStmtRT` runs it interpreted, so its calls arrive here too) |
| `runAction`, jitting arm (`:1149`) | 113 | an INLINED callee walked at emit time -- it never runs as a call; its code is baked into its caller |
| `GroupItem::fireLabelMethod` (`GroupItem.twk:711`) | 74 | RULE actions fired on a label during an old-road parse (JSONfield 42, JSONarray 9, list 7, ...) -- not action calls; outside R1's scope |

The roads that do not reach processAction at all: a compiled body's **call-through** (`jitEmitSelfCall` emits a direct
call to the callee's own function), **`jitRefire`** (`gJitLastFn`), **`jitFieldMethod`** (`gJitMethod`), and the probe
door. **So the one intercept is runAction's interpreted arm**, inside its save / bind / restore bracket: every first
call by name passes it, wherever it comes from. The emit-time arm must NOT be intercepted (it is a build).

### (b) The parse generator crash

Measured on the 26 files that call `parser()` (`results/genlist2`), jit at first call from the process start (the SEQ 383
tap): **26 / 26 exit 139, every one at the first fire of `generateParse`.** Not a compile crash: a stack overflow
(`EXC_BAD_ACCESS` code 2 at a stack address, in `cout`'s `__sfvwrite`), after the generator regenerates
BlocK -> leftCurly -> StatemenT -> SemI -> BlocK without end.

The mechanism, as far as it is measured:
- the compiled generateParse leaves through its **data exit** (`if datA != 0; ... uncompiled +% argument; return;`,
  `IncantForms/WorkingOn/parser:17-21`) for rules that have NO data. lldb on `opAddAttribute` with target `uncompiled`:
  interpreted, it files only data-kind rules (followedBy 3, SemI 13, leftCurly 13, ...); jitted it also files DO, do,
  StatemenT, BlocK -- all data kind 0. Warnings: interpreted 1 in 156 generations; jitted 7,061 in 14,027.
- so the generator never reaches `argument +< *bprCopy` (lldb: `opAddProperty` is not called once in the jitted run;
  interpreted it is called for every generated rule), no rule gets its `pendingParseR` carrier, and walkRules' cycle
  guard (`if *grup["pendingParseR"]; continue;`) never fires. walkRules itself is verifier-refused and runs interpreted.
- **What makes the compiled `datA != 0` read true is NOT isolated.** The same compare in a scratch action agreed on both
  roads in every shape tried (a count and a field; grammar rules as the argument; after cout / reset / printTO / print /
  dupTermRefusal; called from an iterate walk). A copy of the real generateParse did not reproduce its interpreted end
  (H16) and was discarded. It is the symptom foldAndT already pins (a jitted `x.datA != 0` reads true).

**Not cheap and local** -- the misread is not found. **The proposed predicate**, on a property of the action rather than
a list of names: *an action whose body reads a GroupFields accessor (`datA`, `listLengtH`, `hasTraitS`, ... -- the
accessor road) in a condition is not jittable* until the misread is understood. It keeps generateParse interpreted, and
foldAndT's action with it. Graded a GUESS: it is the spelling both failures share, not a measured mechanism, and its
cost (how many actions it would exclude) is unmeasured. Not built.

### (c) The switch

**A global, `gJitter`, in `jitContext.h`, beside the cache.** Its single writer is the `jitter` command
(`jitEmitters.rtn`); its single reader is the intercept, in passthrough. A ruler slot would be a field tok source
references, which owes a `.twk` declaration and a `groups.ext` mirror (SEQ 218 R1) for a value no incant code reads.
Precedent: `gJitCompileOnly`, `gJitLastFn`.

### (d) The 13 build-time-read sites against the forced census (context only)

A tap at each site (clone, reverted md5-identical) logged, per compile, every time the site read its value AT BUILD in
the class's signature: a node with no kind (data 0), no group, or not an iterator where the site decides on it. Classes
are SEQ 385's. **These are co-occurrences, not attribution** -- a site can hit its signature in a fixture that agrees,
and one disagreeing fixture usually hits several sites. The agree column is the anti-vacuity side.

| site | old road: DISAGREE / agree fixtures hit | new road |
|---|---|---|
| S1 aCTionIterate's source (`ruleActions.rtn:593-611`) | 3 / 0 | 2 / 0 |
| S2 `++` / `--` isIterator (`Instruct.rtn:904`, `:634`) | 30 / 5 | 51 / 5 |
| S3 opDeref's fall-through (`Instruct.rtn:258`) | 44 / 14 | 63 / 13 |
| S4 jitEmitDot's target | 23 / 9 | 19 / 9 |
| S5 followArgument, no slot and no group (`GroupActions.rtn:328-333`) | 20 / 0 | 44 / 0 |
| S6 jitEmitBareRead, kindless token | 43 / 13 | 61 / 13 |
| S7 jitSeedField, kindless (i32 by default) | 75 / 57 | 88 / 54 |
| S8 the frame prologue, kindless local | 62 / 47 | 77 / 44 |
| S9 the argument slot, nothing bound at build | 55 / 47 | 53 / 43 |
| S10 jitEmitAssign, kindless target | 58 / 33 | 75 / 32 |
| S11 jitEmitAdd string-or-int | 0 / 0 | 0 / 0 |
| S12 jitEmitSelfCall's argument | 33 / 10 | 55 / 10 |
| S13 jitPrintList, kindless part | 44 / 6 | 62 / 6 |

DISAGREE fixtures with no site signature at all: 1 on each road (jitCmpOperandT). DISAGREE fixtures whose only
signature is one site: S9 only (6 old, 5 new). **S1 and S5 are the only sites that never hit an agreeing fixture**; S7,
S8, S9 hit nearly as many agreeing fixtures as disagreeing ones, so their columns say little. S11 never fires.

## Pre-registered movers (written before the build)

- pop.sh: the new `jitterT` rows (born red on trunk: `jitter;` is not a command there, so the file truncates at it).
  H3: an address, the fixture-name count. Nothing else -- no fixture counts or prints `cOMMANDs` (five register into it).
- jitLadder: none.
