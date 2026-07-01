# Incant — Status & Handoff (2026-06-30 LATE: JIT PIVOT LANDED, webChannel unblocked)
*Written by Clod for a fresh Clay/Clod. Assumes no memory of today. Self-contained.*

## What just happened
**Phase 2 JIT is done for the gIF checkpoint.** The unified emit-on-walk pivot (Option A) landed
and was independently verified. `jitGifScratch` now shows **real two-way runtime gating**
(taken→`maximus=99`, not-taken→`maximus=11`) via a live `br i1 %cmp` — not the `br i1 false`
false-green that held the webChannel pilot all day. **The webChannel hold is LIFTED.**

### Today's commits (branch `jit-unified-emit-wip`, on top of `095bcb1`)
- `b1a63a4` — Step 1: collapse `aCTionExpressioN` dispatcher, delete `jitXP`
- `5d4c987` — docs: webChannel recon pair (wiki toe-dip + Bot subsystem teardown)
- `8948867` — docs: compare-op null-guard parity recon (assessment only)
- `7850a9e` — **JIT Phase 2 pivot COMPLETE (Option A)** — ride `interpretXP`/`runOP`, delete `jitXpress` path
- `25dfca3` — docs(CLAUDE): narrow bear-trap #4 to its real trigger (`//` mid-if-parse)

## The architecture now (so you don't re-derive it)
**JIT emits LLVM by RUNNING the interpret/runOP walk under a `jitting` gate** — no parallel
flat-list reconstruction. The pieces:
- **`jitRunAction`** (`jitEmitters.rtn`): raises `jitting=1`, keeps `generating=0`. So
  `aCTionExpressioN`'s dispatcher (`if generating return generateXP; return interpretXP`) routes JIT
  to **`interpretXP`** (runOP trees), NOT `generateXP` (flat revisedLists).
- **`jitExecBlock`** (`jitEmitters.rtn`, replaced `jitWalkBlock`): runs the parsed BlocK's `gMethod`,
  so the runOP trees execute under jitting and each opMethod's `jitting` gate emits IR in place.
- **`aCTionIF`** (`ruleActions.rtn`): a `jitting` gate → `jitEmitGIF` (same shape as every opMethod
  gate in `Instruct.rtn`).
- **`jitEmitGIF`** (`jitEmitters.rtn`): reworked off `jitXpress` onto the interpret walk — condition
  and arms reach `runOP` via `gMethod` (live GroupItem pointers), bracketed by
  `jitIfBegin`/`jitIfEnd`.
- **`runOP` leaf-seeding gate** (`GroupActions.rtn`, before `op.operat`): seeds leaf operands —
  `jitSeedField` (live field, bakes `jitSlot`) or `jitSeedLiteral` (constant), guarded by
  "already has `jitData`" = **bear-trap #9** (don't re-seed an inner op-result as a field).
- **DELETED**: `jitXpress`, `jitRunGenerated`, `jitGeneratE` (zero call sites). This removes the
  by-reference operand-stack re-parenting that produced `br i1 false`.

### Load-bearing details — DO NOT lose
- **`gJitResult`** threads LLVM `Value*`s between recursive jitting-gated opMethod calls. Each gate
  stashes its result there; the parent `runOP` reads it as the next operand. The runOP seeding gate
  writes NOTHING to `gJitResult` (it's strictly before `op.operat`); in `jitEmitGIF` the condition's
  `gMethod` leaves the i1 in `gJitResult` and `jitIfBegin` reads it immediately (no statement
  between). If clobbered, the whole thing fails **silently**.
- **Per-run `jitData` reset** (`jitRunAction`, via `gJitSeeded` in `jitContext.h`): `jitData`
  persists on BDWGC field nodes across runs, but its `Value*` dies with each run's LLVMContext.
  Without the reset, run 2 reads a dangling `Value*`. This is why the seeding gate's `!jitData`
  guard needs the reset to be correct.
- **Why the pivot is structurally cleaner:** the interpret walk OWNS its traversal and never
  re-parents live nodes — so the re-parent hang class (`addMember`/`push` rewriting `nextInParent`)
  that produced both the `095bcb1` hang and the by-reference stack corruption is gone by
  construction, not routed around.

## Verified checkpoint (independently rebuilt by Clod, not trusting the agent)
- `<binary> incant/oneTest` → `maximus = 26` (bytecode path intact).
- `<binary> incant/jitGifScratch` → exit 0; **taken (righty=−7) → `maximus=99`**, **not-taken
  (righty=13) → `maximus=11`**. Same compiled IR, value-dependent result = real runtime gating (a
  constant fold would give 11/11 or 99/99). IR: `%unbox = load righty` · `%cmp = icmp slt` ·
  `br i1 %cmp` · `store i32 99` inside `then:`. extern count 155→152.

## NEXT
1. ✅ **DONE — Null-guard parity (opLT/opGT/opLE/opGE)** — `e6405fb`. opEQ-style guards added to the
   four ordering ops in `Instruct.rtn`; both-null returns false (verified); flip directions match
   `docs/compare-null-guard-recon.md`; extern 152, oneTest→26, no pivot regression.
2. **webChannel pilot** — now unblocked, and the next WORK item. The Bot recon (`docs/bot-recon.md`) verdict: the old `Bot/`
   subsystem is **Distributed Objects RPC** (NSConnection, Mach-port), NOT the socket skeleton it
   was remembered as — wrong layer for a browser-facing channel. So **build a minimal socket
   listener from scratch** (`setSocketOp`, analogous to `setFileOp`), per `docs/wiki-recon.md`. The
   one reusable idea is `BotClient`'s text→GroupItem→return-result shape.

## Run recipe / reproduce
- Binary = `~/Library/Developer/Xcode/DerivedData/InProcess-ezzmcllcsvijqmbipricnduikqfp/Build/Products/Debug/Groups`.
- `<binary> incant/oneTest` → `maximus = 26`. `<binary> incant/jitGifScratch` → 99 (taken) / 11 (not-taken).
- **No `timeout` on this shell.** If a change re-introduces a hang: background + kill, or cap a loop.
  `cout`/`dumpContents` are block-buffered and lost on hang/SIGTERM; for pre-hang diagnostics use
  `cerr`/`fprintf(stderr,…)` (unbuffered) + redirect to a file (not a pipe — the pipe re-buffers).

## Build + debug mechanics (durable)
- **`tok GroupRules.twk` THEN build.** The `.rtn` files (`jitEmitters.rtn`, `ruleActions.rtn`,
  `Instruct.rtn`, `GroupActions.rtn`, `Commands.rtn`) are `include`d INTO `GroupRules.twk`.
  Sanity: `grep -c extern GroupRules.h` ≈ **152** now (a wipe to 0 = a parse error cascaded —
  bear-traps #10/#11; `groups.ext` lives OUTSIDE the repo at
  `~/Dropbox/data/InProcess/Include/groups.ext`).
- **Build via the WORKSPACE:** `xcodebuild -workspace ../InProcess.xcworkspace -scheme Groups` lands
  in the `InProcess-ezzmcllc…` DerivedData (Tony's path). `-project ../TOK/TOK.xcodeproj` lands
  elsewhere (`TOK-dunath…`). Confirm freshest by mtime.
- **Passthrough idiom:** opMethod jitting gates wrap LLVM calls in `-% … %-` passthrough (the
  `jitEmit*` signatures are header-clean; `llvm::` types live in the passthrough body).
- **Note:** `jitRunAction` still has stdout diagnostics (`=== jitRunAction: entering/result ===`) —
  pre-existing, harmless, could be cleaned later.

## Bear-trap refinement landed today (fold into muscle memory)
**#4 is narrower than it read:** `//` comments are FINE in a block, inside `-% … %-` passthrough, or
outside a method. The parse failure is positional — a `//` wedged between an `if`'s condition and its
statement (tok parses `//` into a statement slot → it gets consumed as the if's governed statement,
orphaning the real one). **Rule of thumb: put `//` only where a statement is allowed.** (CLAUDE.md
#4 updated, `25dfca3`.)

## DEFERRED — not this arc; whose call
- **GUI content dispatch** (text/image/cell/path off `Layout.drawRect`) — Clay's design thread
  (`docs/gui-brief.md`, `docs/font-recon.md`).
- **Clay design review** of the pivot (`7850a9e`) — WIP-branch commit, fully reviewable/revertable.
