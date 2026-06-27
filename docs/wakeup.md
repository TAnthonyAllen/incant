# Incant — Status & Handoff (2026-06-27 PM: Phase 2 JIT — wrapped-condition root cause + unified-emit WIP parked)
*Written by Clod for a fresh Clay/Clod tomorrow. Assumes no memory of today. Self-contained.*

## What this is
**Phase 2 JIT = control flow (`gIF`).** Today's session: a deep dive root-caused why the gIF
branch wasn't really branching, chose the **unified emit-on-walk model** (Fearless + Haps), built
its scaffolding, hit one clean blocker, and **parked it on a branch** so `main` stays green.
The blocker is a known design seam with an agreed fix (a runOP clone). Main is baseline green;
WIP is on `jit-unified-emit-wip`.

## CORRECTION to the prior handoff (important — the old wakeup was wrong)
The previous wakeup claimed the gIF "then-arm store is **proven through the branch**" (taken→99).
**That was a shape-read, not true.** Hard IR evidence (dumped this session, `jitGIF`, righty=-7):
```llvm
entry:
  %unbox = load i32 ... (righty)
  %cmp   = icmp slt i32 %unbox, 0      ; compare emits ✓
  %unbox1 = load i32 ... (maximus)
  store i32 99, ptr ... (maximus)      ; ✗ UNCONDITIONAL store, in the entry block
  br i1 true, label %then, label %endif ; ✗ branches on constant true, not %cmp
then: br label %endif                   ; ✗ then-block EMPTY
endif: ret i32 99
```
So "taken→99" was just an **unconditional parse-time store**; the branch was dead (the compare
emitted but `gJitResult` got overwritten by the assign before `jitIfBegin` read it). Root cause:
the **emit-during-parse** model fundamentally conflicts with **deferred control flow** — an `if`'s
condition + body emit inline into the entry block during the straight-line parse, ungated.

## The decision: unified emit-on-walk model (Fearless + Haps, 2026-06-27)
Stop emitting during parse. Mirror the **bytecode generate route** (which already solves this):
during parse, `aCTionExpressioN`'s `generating` branch builds a flat-RPN **`revisedList`** and
emits nothing; *after* parse, a walk emits from the revisedLists, in block context. So both
straight-line and control-flow share one path, and the then-arm store lands INSIDE the then-block.
- bytecode side: `generatE` → `gIF`/`gXpress` walk the revisedList, emit bytecode ops.
- JIT side (new): `jitWalkBlock` → `jitGeneratE`/`jitRunGenerated` → `jitEmitGIF` + **`jitXpress`**
  (the gXpress analog) walk the revisedList, emit LLVM.

## What was built (on branch `jit-unified-emit-wip`, commit 28347a7)
- **`jitXpress`** (jitEmitters.rtn): walks a statement's revisedList against an operand stack
  (`stack.push`/`stack.pop` on a `new("jitStack")` — the bytecode opStack idiom), emits LLVM per
  member: field→`jitSeedField`, literal→`jitSeedLiteral`, operator→`op.operat` (runOP's operator
  branch → `jitEmitBinary`/`jitEmitCompare`), `bcStoreField`→`jitEmitAssign`, `uxp`→unary.
  Iterates with `while child = argument.next(child)` (the safe iterator; `child` null going in).
- **`jitEmitGIF`** rewritten to the `aCTionIF` idiom: colon-decls `ExpressioN:`/`StatemenT:`
  (NOT `getLabelGroup` — the if-node, its body, AND the grammar rule are all tagged `StatemenT`,
  so a tag-search collides and **hangs**); `unWrap` to the revisedList; `jitXpress(cond)` →
  `jitIfBegin` → `jitXpress(then)` → `jitIfEnd`. Block topology reused unchanged.
- **`jitRunGenerated`**: straight-line → `jitXpress(unWrap(input))`; control flow → `jitEmitGIF`.
- **`ruleActions.rtn`**: the `jitting` inline-emit block **moved AFTER** the `generating` branch.
- **`jitRunAction`**: raises `generating` alongside `jitting` so parse builds revisedLists and emits
  nothing; the walk does all emission.

## THE BLOCKER (and the agreed fix)
**gIF hangs** in `jitXpress(condition)`. Traced concretely: the condition revisedList walks
`righty → Token → Token → ∞`. The if-condition `righty < 0` is **wrapped (listLength 1)**, so
`aCTionExpressioN`'s `listLength==1` path stuffs the *whole wrapped runOP-tree* into the
revisedList instead of flattening it to clean RPN `[righty, 0, <]`. The wrapper's next-chain cycles
through raw parse `Token`s, so `jitXpress` loops. (Also regressed in the WIP: `jitInc`/`jitDec`
in-place store-back lost — `righty` stayed 13, baseline 12 — the unary path through the revisedList
isn't at parity yet.)

**This is general, not if-specific.** Any *nested* sub-expression produces the same wrapper:
while-condition, for-iterable, parenthesized `(a+b)*c`, chained `a+b+c` (bear-trap #9). `if` is just
where JIT hit it first. So the fix belongs at the `aCTionExpressioN` level.

**Agreed fix — a runOP clone (Fearless brief):** Don't touch `aCTionExpressioN`'s structure. Write a
short **runOP clone** (`jitBuildList` or similar) that does the same structural walk as `runOP`
(GroupActions.rtn:441 — the universal invoker: unwrap groups, identify op/target/arg, handle
virtuals) but, instead of firing opMethods, **accumulates a flat ordered RPN list**. The
`listLength==1` path (likely the `generating` branch's — reconcile the exact call site against the
code; the brief says "jitting gate", but under the unified model it's the generating branch that
builds the revisedList, and fixing it there also retires the bytecode `gIF`'s `unWrap` paper-over)
calls the clone, gets a well-formed list, hands it to `jitXpress`/`gXpress`. Same list shape both
already consume. No monster growth in `aCTionExpressioN`, existing machinery untouched.

## To resume — next actions in order
1. **`git checkout jit-unified-emit-wip`** (the scaffolding is the foundation; build the clone on it).
2. **Build the runOP clone** `jitBuildList` (model on `runOP`, GroupActions.rtn:441). Wire it into the
   `listLength==1` path so a wrapped sub-expression flattens to RPN. **Verify by running:**
   `jitGifScratch` not-taken must become `maximus=11` (taken stays 99 — but now *gated*: check the IR
   shows `br i1 %cmp` and the store inside `then:`, not the entry block).
3. **Fix the `jitInc`/`jitDec` regression** (unary store-back through the revisedList path).
4. **Re-verify straight-line parity**: all `jitscratch` POPs match baseline values (not just
   non-hang). Then else-arm, nesting, compound conditions.
5. Only after green: fast-forward `main` (or PR the branch).

## Run recipe (verify green before starting — these pass on `main` today)
```
~/bin/incant incant/oneTest        # -> "maximus = 26"
~/bin/incant incant/jsonTest       # -> ok : {"a":[]} / ok : {"a":["x","y"]}
~/bin/incant incant/jitscratch     # 25 JIT POPs; jitDec readback -> righty = 12 ; jitNeg -> -13
~/bin/incant incant/jitIfScratch   # smoke (hand-built IR): maximus=-7 -> 99 ; maximus=5 -> 5
~/bin/incant incant/jitGifScratch  # gIF: taken -> 99 (UNCONDITIONAL today, not a real branch)
```
(Boot noise `getRStuff:` is normal. Crash backtrace: run under `script -q /dev/null …`.)

## Build + debug mechanics (durable)
- **`ruleActions.rtn` / `Instruct.rtn` / `jitEmitters.rtn` / `Commands.rtn` are `include`d INTO
  `GroupRules.twk`** — edit them then **`tok GroupRules.twk` THEN `xcodebuild`** (Groups scheme of
  `../TOK/TOK.xcodeproj`); xcodebuild alone recompiles the stale `.mm`. Sanity: `grep -c extern
  GroupRules.h` ≈ 152 (a wipe to 0 = a parse error cascaded — bear trap #10/#11).
- **No `%-` inside a passthrough `-% %-` string literal** — tok has no lexer, so `%-12s` reads as the
  passthrough END marker, terminates the block early, and cascades to wipe the extern block (cost an
  hour today). Use `%s`, not `%-12s`.
- **`.isGROUP`/`.isOperator` are data-type macros, not printable bool members** — can't `cerr` them
  directly (`no member named isGROUP in bools`); test with `if`. `.isLiteral`/`.isArgument` are real
  bools. For a C++ structural dump: `node->groupBody->groupList->firstInList` + `nextInParent`
  (DoubleLink-safe), and `node->getGroup()` for an isGROUP node whose content hangs off `.group`
  (not the member list). Tag via `node->groupBody->tag`.
- **`getLabelGroup` tag-collision hazard** — it searches by tag and the if-node + body + rule all
  share the tag `StatemenT`; it hung. Use colon-decls (bind to a child, never self) — the `aCTionIF`
  idiom. There are lighter locate alternatives than `getLabelGroup` generally.
- **Safe iterator**: `while grup = next(grup)` with `grup` null going in (declared → tok zero-inits) —
  see `aCTionBlocK` (ruleActions.rtn:17). It does NOT clobber under nesting. To steer iteration from
  *within* the loop there's a separate idiom (go hunting if needed — jitXpress doesn't need it; it
  never mutates the list it walks).
- **`runOP` (GroupActions.rtn:441) is the universal invoker** — operator/method/rule/action dispatch
  off `field[1]`(op)/`field[2]`(target)/`field[3]`(arg). The clone mirrors its walk but builds a list.

## Gotchas (durable)
- **`aCTionExpressioN` dereferences `groupList->listLength` unconditionally** — never hand it a leaf.
- **The condition revisedList is malformed only because it's wrapped** — top-level statements arrive
  flat. The clone makes the wrapped case produce the same flat shape.

## DEFERRED — not this arc; whose call
- **GUI content dispatch** (text/image/cell/path off `Layout.drawRect`) — Clay's design conversation
  (`docs/gui-brief.md`, `docs/font-recon.md`). Also parked: drop the `printf` in `guiHost.mm`;
  `viewDidEndLiveResize` re-layout.
- **gIF beyond the wrapped-condition fix:** else-arm, nesting, compound conditions, return-real-
  GroupItem epilogue, slot-array calling convention (`jit.md`).
