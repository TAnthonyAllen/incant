# JIT opMethod + Rule-Action Coverage Recon (M5)

*2026-07-02. Written for Clay's JIT full-monty plan (`jitFullmontyPlan.md` §3 placeholder).
All entries verified by reading `Instruct.rtn`, `jitEmitters.rtn`, `ruleActions.rtn` directly —
file:line cited throughout. This is inventory only; no code changed.*

## Headline findings (read this before the tables)

1. **`aCTionFOR` is NOT a C-style counting loop.** It's a **list/tree iteration** construct —
   walks `LoopOn.next(grup)`/`.prior(grup)` (a GroupItem member/attribute list, optionally
   reversed via `reversE`, optionally restricted to attributes-only/members-only), not an
   init/cond/increment numeric loop (`ruleActions.rtn:430-470`). **This contradicts
   `jitFullmontyPlan.md` §1.3's assumption** ("FOR = WHILE plus init + latch"). A numeric
   preheader/cond/body/latch topology doesn't apply — FOR either needs a fundamentally
   different JIT design (a loop that CALLs back into interpreted `next()`/`prior()` each
   iteration, since jitting GroupItem list traversal itself is out of scope) or should be the
   **first candidate for `jitBail` whole-action fallback** (§2.1) rather than the third rung
   of the loop ladder. Recommend Clay resequence: WHILE → DO → **FOR deferred to
   jitBail-covered, revisit post-testJits** — DO and WHILE are both clean condition/body
   shapes; FOR is a different animal entirely.

2. **Compare-op null-guard parity is REFUTED, not just unverified.** `jitFullmontyPlan.md`
   §2.3 lists this as something M5 "must flag." Checked directly: `jitEmitCompare`
   (`jitEmitters.rtn:146-187`) does pure ICmp/FCmp with **zero null/data checks** — no
   mirror of the interpreter's `if target && !data {...} or argument && !argument.data
   {...}` guard block that `opEQ`/`opGE`/`opGT`/`opLE`/`opLT`/`opNotEQ` all carry
   (`Instruct.rtn`, e.g. :160-165 for opEQ). Worse: because each opMethod's `if jitting {
   return jitEmitCompare(...) }` gate **returns immediately** (e.g. `Instruct.rtn:157-159`
   for opEQ), the interpreter's null-guard code below it **never runs while jitting** — it's
   not "not yet ported," it's **structurally bypassed**. The e6405fb null-guard parity work
   (`docs/compare-null-guard-recon.md`) has **no jitted counterpart**. A jitted compare on
   two null/no-data operands will crash or read garbage `jitValue` rather than returning
   false. **This needs a null-check block prepended inside `jitEmitCompare`** (or a bail) —
   flagging as the single highest-priority NEEDS-MODIFICATION item.

3. **Most compound-assign/unary jit gates skip target's type check that the interpreter
   does** — a systematic pattern gap, not one-off bugs. `opPlusEQ` (`Instruct.rtn:525-533`)
   is the ONE correct example: its jitting gate branches on `target.isSTRING||isTOKEN` vs
   `target.isCOUNT||isNUMBER` before emitting, matching the interpreted body's own dispatch.
   `opMinusEQ` (:376-382), `opDivEQ` (:83-89), `opMultiplyEQ` (:445-451), `opMinusMinus`
   (:404-408), `opPlusPlus` (:557-561), `opPlus` (:505-509), `opMinus` (:338-342) **do not** —
   their `if jitting {...}` fires unconditionally and calls `jitEmitBinary`/`jitEmitUnary`
   assuming a numeric target, even though the interpreted body below handles groupList,
   buffer, string, isSTAK, and list-recursion (`isLIST`) cases the numeric-only jit path
   silently ignores if reached with jitting=1 and a non-numeric target. In practice this is
   probably latent (jitted code paths are presumably only reached with numeric operands
   today, by construction of the test fixtures) but it's a real correctness gap the moment a
   jitted region contains e.g. `someString -= x` or `someList += item`. Recommend: either
   add the same type-check branch `opPlusEQ` uses to the other four, or make `jitEmitBinary`/
   `jitEmitUnary` themselves refuse (jitBail) on a non-numeric target's `jitData`.

4. **`switch` is not a rule action at all.** No `aCTionSwitch` exists in `ruleActions.rtn`.
   The `switch(...) { case ... }` seen in `Layout.twk`/`Stylish.twk` is native TAWK syntax
   compiling straight to a C++ `switch` — it's host-language control flow inside a method
   body, orthogonal to the incant interpret/jit dispatch system entirely. Nothing to jit;
   drop it from any "deferred rule action" list — it was never in-system to begin with.

---

## Part 1 — opMethod coverage (`Instruct.rtn`, 42 op-dispatch functions)

**HAS jitting gate — 18** (all verified: `if jitting { ... }` present, reached via the
`(argument, target)` or unary `(result)` operator-dispatch signature):

| opMethod | operator | line | jit emitter | note |
|---|---|---|---|---|
| opAssign | `=` | 30 | jitEmitAssign | byRef branch (`argument.byRef → group=argument`) is NOT distinguished by the gate — gate fires before the byRef check; unverified whether jitEmitAssign handles a byRef argument correctly or silently mis-stores it |
| opDiv | `/` | 66 | jitEmitBinary(jitSDiv) | fp path exists in jitEmitBinary (CreateFDiv when either operand double) — OK |
| opDivEQ | `/=` | 83 | jitEmitBinary+jitEmitAssign | **type-check gap, finding 3** |
| opEQ | `==` | 155 | jitEmitCompare(jitEQ) | **null-guard gap, finding 2** |
| opGE | `>=` | 219 | jitEmitCompare(jitGE) | **null-guard gap, finding 2**; interpreter guard added e6405fb |
| opGT | `>` | 237 | jitEmitCompare(jitGT) | **null-guard gap, finding 2**; interpreter guard added e6405fb |
| opLE | `<=` | 293 | jitEmitCompare(jitLE) | **null-guard gap, finding 2**; interpreter guard added e6405fb |
| opLT | `<` | 311 | jitEmitCompare(jitLT) | **null-guard gap, finding 2**; interpreter guard added e6405fb |
| opMinus | `-` | 338 | jitEmitBinary(jitSub) | **type-check gap** — interpreted body also handles isSTRING/isTOKEN truncation (headToCount), jit path is numeric-only, unconditional gate |
| opUnaryMinus | prefix `-` | 360 | jitEmitUnary(jitNeg) | numeric-only in interpreter too — clean parity, proven (jit.md "unary-minus-done") |
| opMinusEQ | `-=` | 376 | jitEmitBinary+jitEmitAssign | **type-check gap, finding 3** |
| opMinusMinus | `--` | 404 | jitEmitUnary(jitDec) | **type-check gap, finding 3** — interpreter also handles string/isSTAK/groupList |
| opMultiply | `*` | 428 | jitEmitBinary(jitMul) | numeric-only in interpreter too — clean parity |
| opMultiplyEQ | `*=` | 445 | jitEmitBinary+jitEmitAssign | **type-check gap, finding 3** |
| opNotEQ | `!=` | 476 | jitEmitCompare(jitNE) | **null-guard gap, finding 2** |
| opPlus | `+` | 505 | jitEmitBinary(jitAdd) | **type-check gap** — interpreted body also has a string pointer-advance branch, jit is numeric-only, unconditional gate |
| opPlusEQ | `+=` | 525 | jitEmitStringPlusEQ / jitEmitBinary+jitEmitAssign | **the correct pattern** — type-checks target before dispatch (see finding 3); falls through un-gated (silently, no bail) for isLIST/buffer/isSTAK targets while jitting=1 |
| opPlusPlus | `++` | 557 | jitEmitUnary(jitInc) | **type-check gap, finding 3** — interpreter also handles !data, string advance |

**NEEDS gate — 4** (mechanical: numeric/boolean, same shape as an already-gated sibling,
no new machinery required):

| opMethod | operator | line | model to copy |
|---|---|---|---|
| opAND | `AND` | 18 | boolean logic, shape mirrors opOR below |
| opOR | `OR` | 494 | boolean logic — note: currently has NO jitting gate at all, not even a stub |
| opRem | `%` | 623 | pure numeric, same shape as opDiv/opMultiply — needs a `jitSRem`/`jitFRem` case added to jitEmitBinary's op switch |
| opNOT | `!` | 467 | simple negation of `contents()` — mechanical IF `contents()` has (or gets) a jit-visible value; otherwise reclassify as NEEDS-modification |

**NEEDS modification — 20** (structural/GroupItem-tree mutation, helper-call-worthy I/O or
string ops, registry/introspection lookups, or global/singleton state — none are the
mechanical "one line onto jitEmitBinary" pattern):

| opMethod | operator | line | why |
|---|---|---|---|
| opAddAttribute | `+%` | 5 | tree mutation (`target +% grup`) |
| opCopyList | `+*` | 45 | tree mutation (`copyListTo`) |
| opDebug | `**` | 55 | debug/reflective (`currentMETHOD` lookup) — low priority, likely never appears in a hot jitted path |
| opDot | `.` | 108 | GroupItem introspection — large switch over parent/registry/hasMembers/isMethod/etc.; the most structurally complex op in the file |
| opEnd | `=]` | 174 | list navigation (`lastInList`) |
| opGet | `[...]` | 186 | attribute/member lookup by name or index |
| opGetAttribute | `=%` | 201 | registry lookup (`getAttribute`) |
| opGetMember | `=/` | 210 | registry lookup (`getMember`) |
| opIN | `IN` | 261 | PLGset/buffer membership — string/buffer helper calls |
| opLastREF | `@` | 284 | mutates the **global** `lastREF` singleton — unclear how this interacts with jit's per-frame slot model |
| opMatch | `~=` | 329 | string compare — helper call (`compare(text,argument.text)`) |
| opPointer | `=*` | 577 | sets `isPointer` flag; per its own comment this is a **definition-time** marker ("Fired as a noPrint definition attribute"), likely out of runtime-jit scope entirely |
| opPrint | print rule | 591 | I/O — `cout`/buffer write, needs a runtime helper call |
| opRebind | `<-` | 614 | pointer/group structural set (`target.group = argument`), byRef-adjacent |
| opReplaceAttribute | `:%` | 634 | tree mutation (`target.replace`) |
| opReplaceMember | `:+` | 651 | tree mutation (`target.replace`) |
| opSetGroup | `:=` | 672 | byRef pointer set — ties into bear-trap #3's sticky-byRef semantics, live-pointer/GC discipline |
| opSetFlag | `:.` | 686 | GroupItem internal boolean-flag mutation (fLAG/isPercent/isVirtual/mergeOn/noPrint/byRef/isLIST/isBIN) |
| opSetTag | `<:` | 706 | string/tag mutation (`target.tag = argument.text`) |
| opString | string rule | 715 | I/O/buffer (`toString()`) — helper call |

**Non-operator utility externs present in `Instruct.rtn` — out of scope for op-method
coverage** (not reached via the `(argument, target)` operator dispatch; buffer/file-support
plumbing): `flushBuffer` (:730), `getMarkLineAt` (:745), `setMark` (:777), `setFile` (:791),
`unMark` (:796), `resetField` (:806), `setFileOp` (:818 — the exact extern the webChannel
`setSocketOp` plan is modeled on, per `webchannel-attack.md`).

**Count check:** 18 HAS + 4 NEEDS-gate + 20 NEEDS-modification = 42 total op-dispatch
functions in `Instruct.rtn`. (jit.md's "24 POPs" figure is test-case count from Phase 1
fixtures, not a function count — don't conflate the two numbers.)

---

## Part 2 — IF / FOR / DO / WHILE rule-action jit status (`ruleActions.rtn`)

| rule action | line | jit status | structural shape |
|---|---|---|---|
| **aCTionIF** | 476 | **HAS gate** — `if jitting { return jitEmitGIF(input); }` (:482-484), unconditional first line, done/verified per wakeup.md | `ExpressioN:` condition, `StatemenT:` then-body, `ElsE:` optional else-body — all local GroupItem sub-fields dispatched via `.gMethod()` |
| **aCTionWhilE** | 917 | NO gate | `while ExpressioN.gMethod(ExpressioN) if result = StatemenT.gMethod(StatemenT) {...} else break;` (:922-928) — clean condition-then-body shape, directly matches `jitFullmontyPlan.md` §1.1's WHILE topology sketch. Handles `isBranch`/`isContinue`/`isReturn` inside the body (:924-927) — loop topology plan needs continue→latch/cond jump and return→function-exit block, not just the happy path |
| **aCTionDO** | 248 | NO gate | `do { result = StatemenT.gMethod(StatemenT); if isBranch {...} } while ExpressioN.gMethod(ExpressioN);` (:253-259) — body-then-condition, matches §1.2's "body runs once even if condition false" DO topology. Same isBranch/isContinue/isReturn handling as WHILE |
| **aCTionFOR** | 430 | NO gate | **See headline finding 1 — NOT a numeric loop.** `Looper`/`ExpressioN`/`reversE`/`LoopRestrict` inputs; walks `LoopOn.next(grup)` or `.prior(grup)` (GroupItem member/attribute list traversal) (:454); `restrict` filters to `affiliation` attributes(1)/members(2) (:457); `lastREF`/`byRef` bookkeeping around the loop var (:453,458,460,466-468) is a live-pointer discipline, not an induction variable. `LoopOn` itself is resolved from `ExpressioN` by unwrapping `.isGROUP` until a `groupList` is found (:448-452) — the "list" being iterated isn't even statically known without walking the parse tree. This is fundamentally a **tree-walk primitive**, not arithmetic loop control flow. |

**Continue/break/return note (applies to WHILE, DO, and — if ever built — FOR):** none of
`jitFullmontyPlan.md`'s loop-topology sketch (§1.0b) mentions `isBranch`/`isContinue`/
`isReturn` explicitly. All three loop rule actions check `isBranch` inside the body and
`continue`/`break`/`return result` in the C++ sense (not incant control flow — this is the
rule action's own C++ body reacting to a branch signal bubbling up from `StatemenT.gMethod`).
The jit loop-topology helper (`jitLoopBegin/jitLoopBody/jitLoopEnd`) will need explicit
continue→br-latch and break→br-exit block wiring, and a decision on what `isReturn` means
inside a jitted loop (bail to interpreter, or a function-exit block via the epilogue). Flagging
as an addendum to §1.0b, not a blocker.

---

## Part 3 — other rule actions present (§1.5 deferred-list inventory, names only)

Beyond `aCTionIF`/`aCTionFOR`/`aCTionDO`/`aCTionWhilE`, `ruleActions.rtn` defines:
`aCTionANYtoken`, `aCTionBlocK`, `aCTionBraced`, `aCTionBrancH`, `aCTionCheckFor`,
`aCTionCodE`, `aCTionDEBUG`, `aCTionDefinE`, `aCTionExpressioN` (+ `generateXP`/
`interpretXP` mode-handlers — this one is core jit plumbing already, not a deferred
candidate), `aCTionFailed`, `aCTionNamE`, `aCTionNumbeR`, `aCTionParens`, `aCTionPrinT`,
`aCTionQuotE`, `aCTionRunRulE`, `aCTionScopeXP`, `aCTionSearch`, `aCTionSetBrackets`,
`aCTionShortcuT`, `aCTionStatemenT` (also core dispatch plumbing, not deferred), `aCTionTokenXP`,
`aCTionTraiT`, `aCTionTraiTdata`, `aCTionXpress`. Most of these are parser/grammar-level or
token-handling actions, not control-flow constructs analogous to IF/FOR/DO/WHILE — no attempt
made here to sort them further; that's a separate recon if/when the full-monty plan needs it.
`switch` is explicitly NOT in this list — see headline finding 4.
