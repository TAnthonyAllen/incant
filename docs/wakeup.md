# Incant — Status & Handoff (2026-06-30 LATE: Phase 2 JIT gIF — HANG FIXED; gIF-emit bugs are next)
*Written by Clod for a fresh Clay/Clod. Assumes no memory of today. Self-contained.*

## What this is
**Phase 2 JIT = control flow (`gIF`).** This session, on `main`: landed field directives + the
`opIN` dedup fix (`b411ffa`), kitchen-cleaning (`cfb2bcc`), design docs (`a4216a5`). On
`jit-unified-emit-wip` (rebased byte-clean onto `main`, `git range-diff` verified `28347a7 =
3cce6d8`): refactored `aCTionExpressioN` into a dispatcher + `generateXP`/`jitXP`/`interpretXP`, and
**FIXED the long-standing `gIF` hang.** `jitGifScratch` now runs to completion (`exit=0`, was an
infinite loop); **not-taken → maximus=11**. The IR then revealed the *actual* gIF-emit is still
wrong — that's the **next task** (see "gIF-emit bugs"). `oneTest`→26 (bytecode unaffected by the
split). Both branches clean/green.

## HANG FIXED — root cause + the cure
Root cause (bones): **`stack.push(child)` re-parents the member.** Pushing a revisedList member onto
`jitXpress`'s operand stack calls `addMember`, which **rewrites `child.nextInParent`** to point into
the stack — so reading `child.nextInParent` AFTER the body strands the walk (observed: `righty`,
then `Token` forever once Token is pushed). **Cure = the gXpress idiom:** capture
`next = child.nextInParent` BEFORE the body, advance to `next` after. The up-front capture is
load-bearing (gXpress does `nextChild = child.nexT` for exactly this).

Two earlier hypotheses were *steps*, both superseded — kept so they aren't re-attempted:
- **"jitXpress iterator is the bug"** (next/nextMember/nextInParent) — symptom, not cause. Every
  node-pointer walk looped because the body re-parented mid-walk, not because of the primitive.
- **"by-reference members need flattening"** — drove the `aCTionExpressioN` split + `jitXP`'s
  `copyOf`-at-append, which DOES produce clean owned "ducks in a row" (proven by an in-`jitXP`
  link-walk: `righty→Token→<→END`). But the copy was **not** the cure — capture-next was. FOLLOW-UP:
  try the walk against the by-ref list with **no `copyOf`** — if still green, `jitXP`'s copy
  machinery can likely be dropped (pairs with the generateXP/jitXP unification below).

## Landed this session (refactor + hang fix) — its own commit
- `aCTionExpressioN` → thin dispatcher → `generateXP` / `jitXP` / `interpretXP`. Routing is **Clay's
  (b)**: dispatcher checks `jitting` FIRST; `jitRunAction` still raises BOTH `jitting`+`generating`
  (unchanged) — the divergence is only that `jitXP` `copyOf`s each operand at append. Names are
  NOT `aCTionXxx` (reserved for grammar-rule entry points). `listLength==1` triplication left as-is.
- `jitXpress`: the capture-next walk (the hang fix).

## gIF-emit bugs — THE NEXT TASK (IR now visible; the hang was masking these)
IR of `jitGIF` (taken, righty=-7) after the hang fix:
```
entry: %unbox = load righty ; br i1 false, label %then, label %endif   (X) constant, not the compare
then:  %unbox1 = load maximus ; br label %endif                        (X) loads but never stores 99
endif: ret i32 0
```
1. **`br i1 false`** — `jitIfBegin` isn't wiring the condition's compare (`gJitResult` from `<`)
   into the branch.
2. **Missing store** — the then-arm loads `maximus` but emits no `store i32 99`
   (`jitEmitAssign`/`bcStoreField` store not landing).
**Likely ONE shared cause (Fearless):** the consumers (`jitIfBegin`, `jitEmitAssign`) may still read
state from the OLD inline-emit model, not from where `jitXpress`'s post-fix walk now deposits it.
**Check the DATA first** — is `gJitResult` set at the right point in the new walk before assuming
`jitIfBegin` is wrong? Check whether fixing #1 surfaces/fixes #2 before treating them as two.
Checkpoint to hit: `jitGifScratch` not-taken→11 **with `br i1 %cmp` and the store INSIDE `then:`**.
Then: `jitInc`/`jitDec` regression, `jitscratch` parity, else-arm / nesting / compound conditions.

## HELD: webChannel pilot
Trigger was "not-taken=11 **with gating confirmed**." Numerically 11, but `br i1 false` ≠ gating —
held until the emit bugs land. (Tonight is the case for why the trigger said "gating confirmed", not
just "11": the number was right for unsound reasons.)

## Run recipe / reproduce
- Binary = `~/Library/Developer/Xcode/DerivedData/InProcess-ezzmcllcsvijqmbipricnduikqfp/Build/Products/Debug/Groups` (Tony's workspace path).
- `<binary> incant/oneTest` → `maximus = 26` (bytecode, green).
- `<binary> incant/jitGifScratch` → now **`exit=0`** (no hang); not-taken→`maximus=11`. To see the
  emitted IR, add `fn->print(llvm::errs())` after `B.CreateRet` in `jitRunAction` (`jitEmitters.rtn`).
- **No `timeout` on this shell.** If a future change re-introduces a hang: run in background + kill,
  or cap a loop. `cout`/`dumpContents` are **block-buffered and lost on hang/SIGTERM**; for pre-hang
  diagnostics use `cerr` (unbuffered) + redirect to a file (not a pipe — the pipe re-buffers).

## Build + debug mechanics (durable)
- **`tok GroupRules.twk` THEN build.** The `.rtn` files (`jitEmitters.rtn`, `ruleActions.rtn`,
  `Instruct.rtn`, `GroupActions.rtn`, `Commands.rtn`) are `include`d INTO `GroupRules.twk`.
  Sanity: `grep -c extern GroupRules.h` ≈ **153** (a wipe to 0 = a parse error cascaded —
  bear-traps #10/#11).
- **Build path matters (footgun).** `xcodebuild -workspace ../InProcess.xcworkspace -scheme Groups`
  lands in the **`InProcess-ezzmcllc…`** DerivedData (Tony's path). `xcodebuild -project
  ../TOK/TOK.xcodeproj -scheme Groups` lands in a **different** path (`TOK-dunath…`). Build via the
  **workspace** so runs hit the binary Tony's Xcode also produces. Confirm freshest by mtime.
- **`aCTionExpressioN` (`ruleActions.rtn:269`)** has three mode-branches today: `generating`
  (builds the revisedList, `if generating` returns first), the dead `jitting` inline-emit block,
  and the interpret fallthrough (`finishXP`). `jitRunAction` (`jitEmitters.rtn`) currently raises
  generating+jitting, so the **generating** branch builds the JIT's revisedList — this is exactly
  what the refactor + routing change will repoint at `jitXP`.

## Bear-trap to add to CLAUDE.md (Clay flagged — pattern-worthy, 2nd of its class)
**Node-pointer walks are not list walks.** `next()` has a shared cursor that operator dispatch can
re-enter mid-walk; and `nextInParent`/`nextMember` on a **by-reference shared member** follow the
member's HOME parent, not the list it was added to. A function that comments itself "safe because
it doesn't mutate `argument`" accounts for neither. To iterate a list whose members may be shared,
walk the list itself (index `argument[i]`, or the groupList DoubleLink `link->next`) — or, better,
don't put shared members in the list (own them). First instance of this class: the `getLabelGroup`
tag-collision hang (gIF work). This is the second.

## FOLLOW-UP — once jitXP flatten is verified (not urgent, do NOT lose this)
Once `jitXP`'s owned-copy flatten is verified (`jitGifScratch` not-taken→11, gated, committed),
**unify `generateXP` and `jitXP` back into one builder.** Rationale: `jitXP`'s `copyOf()`-at-append
proves owned-copy-at-construction is strictly safer at no real cost — at that point `generateXP`'s
by-reference-share construction has no remaining justification (it was never a deliberate choice,
just nothing forced the issue before JIT hit it). Unifying also lets `gXpress` retire its own
copy-at-emit laundering, since the list it receives would already be owned — collapsing two
laundering points into one, upstream of both consumers. **Sequencing:** after the `jitXP`/`jitXpress`
fix is independently green and committed — NOT folded in now (same discipline as keeping the
`aCTionExpressioN` split separate from the iterator fix). `jitGifScratch` + the existing suite are
the regression test when this lands. (Pairs with the already-flagged "duplicate now, maybe unify
later" items: the `generateXP`/`jitXP` twin state machines and the triplicated `listLength==1`.)

## DEFERRED — not this arc; whose call
- **GUI content dispatch** (text/image/cell/path off `Layout.drawRect`) — Clay's design thread
  (`docs/gui-brief.md`, `docs/font-recon.md`).
- **webChannel pilot** — the subagent/FrankenClod orchestration trial; trigger was the
  `jitGifScratch` not-taken=11 checkpoint, NOT yet reached. Clay+Tony discussing the orchestration
  model (subagent vs agent-teams) + the corpus-currency gate. Parked until the gIF fix lands.
