# Branch Dispatch — Findings for Design Assessment

*Drafted 2026-06-11 (Clod), for Clay. Resurrection-reader standard: this reads
cold, no memory of the session that produced it.*

---

## ✅ RESOLVED 2026-06-11 — C++ dispatch loop

Clay's design call: replace the incant `interpretBC` with a small **C++ dispatch
loop** in `GroupActions.rtn`. A plain C++ cursor sidesteps **both** blockers below —
no `:=`/byRef weld (it's a C++ local), and it isn't bound by `aCTionFOR`'s
non-steerable advance. `runByteFn` returns the branch-target stream-member on a taken
branch (null otherwise); the loop relocates the cursor to it by tag (`getFromList`),
else advances with `nextMember`. `nextGroup` is stateless (reads `nextInParent` off the
node), so relocating to an arbitrary branch target works cleanly. opStack is hung off
the bcLIST as a fresh attribute per call (also kills the `opStack not empty` leftover).

A second bug was fixed alongside: `runBR` (Bytecode.twk) was a dead `getFromList("dst")`;
it now mirrors `runBRZ`'s attribute-walk so `bcBR`'s unconditional jump resolves.

**Verified** (init `maximus=11`, `righty=13`): `testByteCode` (`if righty <= 0`, false) →
**11** (BRZ branches past the then); `testIfElse` (`if righty > 0`, true) → **26** (then
runs, BR jumps to end, else skipped). Only correct branching in both directions yields
11/26 (no-op→11/11, straight-through→26/7). The incant `interpretBC` is retired;
`branch-mechanism.md`'s C++-dispatch conclusion is vindicated.

The original findings below are kept as the reasoning trail.

---

## What this is

Phase Bytecode's conditional branch does **not** execute. `testByteCode` and
`testIfElse` both emit correct bytecode and resolve their branch targets
correctly, but the interpreter walks the instruction stream straight through —
the branch is never taken. This doc consolidates the run-verified evidence and
isolates the cause to **two entangled blockers in the dispatch loop**, both of
which are design-level (the `:=`/`byRef` semantics and the `for`-loop's
non-steerability), not execution bugs to be patched in place.

**Bottom line:** the 2026-06-10 "branch execution works in incant" claim in
CLAUDE.md / projectBible.md was a shape-read, not bones. Under a clean run the
branch falls through. `docs/branch-mechanism.md`'s original (2026-06-09)
conclusion — that the dispatch loop needs to move to C++ — is looking correct
after all. The design question is below.

## The fixtures (incant/generate, unitTests init at unitTests:82-83)

Initial state: `maximus = 11`, `righty = 13`.

| Fixture | Code | Condition | Correct result | Actual |
|---|---|---|---|---|
| `testByteCode` | `if righty <= 0; maximus = righty * 2;` | `13 <= 0` → **false** | branch past then → `maximus = 11` | **`maximus = 26`** |
| `testIfElse` | `if righty > 0; maximus = righty*2; else maximus = 7;` | `13 > 0` → **true** | then runs, BR skips else → `maximus = 26` | **`maximus = 7`** |

Both wrong results are explained by one behavior: **the bcLIST runs top to
bottom with no branch taken.** testByteCode runs the then unconditionally (26);
testIfElse runs then *and* else, last store wins (7).

## What is working (verified)

- **Emit is correct.** `testByteCode` produces a 9-op bcLIST:
  `bcPushField 13 · bcPushLit 0 · <= · bcBRZ · bcPushField 13 · bcPushLit 2 · * · bcStoreField · bcLabel1`.
  Labels are uniquely minted (`bcLabel1`, `bcLabel2` …) via `labelIndex` in the
  `pROPERTIEs` base registry, and the tag is clean (`bcLabel1`, no embedded
  space — see "Cleanups" below).
- **`runBRZ` is correct** (Bytecode.mm:36). The interpret trace (below) shows
  that at the `bcBRZ` op it returns the `bcLabel1` target node — i.e. it
  correctly read the false condition and resolved the branch destination.
- **Target resolution is correct.** Both the branch op's `dst` attribute and the
  stream's label member are minted from the same expression, so `getFromList`
  by tag matches.

So the failure is localized entirely to the **dispatch loop**: `interpretBC`
(incant/generate:338-345).

```
interpretBC argument code={
    argument +% opStack;
    for grup in argument; members
        result = runByteFn(grup);
        if result;  grup := result;
    if opStack.listLengtH;  print "interpret: opStack not empty at end:" opStack.listLengtH:;
    };
```

Intended mechanism: `runByteFn(grup)` returns a target label when a branch op
wants to jump (else null); `if result; grup := result;` is meant to relocate the
loop cursor to that target so the walk continues from the branch destination.

## Trace evidence

A `print result.taG:` was inserted after `result = runByteFn(grup)`. Running
`testByteCode` (false condition; 9 ops):

```
About to run interpretBC
result        ← op1 bcPushField   }
result        ← op2 bcPushLit      } result's own (empty) tag — runByteFn returned null. CLEAN.
result        ← op3 <=            }
bcLabel1      ← op4 bcBRZ          ← runBRZ returns the target; the FIRST `grup := result` fires here
bcLabel1      ← op5 bcPushField   }
bcLabel1      ← op6 bcPushLit      } STUCK — result never changes again
bcLabel1      ← op7 *             }
bcLabel1      ← op8 bcStoreField  }
bcLabel1      ← op9 bcLabel1      }
interpret: opStack not empty at end: 1
maximus = 26
```

Two facts from this trace:
1. `runBRZ` correctly returns `bcLabel1` at op4 (branch decision + resolution OK).
2. `result` goes **sticky** to `bcLabel1` from op4 onward, and stays stuck even
   after an explicit `result = 0;` was added at the top of the loop body (tried;
   no effect — `result` still printed `bcLabel1` every iteration).

## Blocker A — `:=` welds the test variable to the branch target

`:=` (opSetGroup) binds by reference and stamps a **sticky `byRef`** flag (CLAUDE.md
bear-trap #3). In `grup := result`, the *argument* is `result`. The trace shows
the effect is stronger than a flag: after the first `grup := result`, **`result`
is aliased to the `bcLabel1` node itself**. Thereafter:

- `result.taG` reads `bcLabel1` forever, because `result` *is* that node.
- `=` is `setContent`, which mutates a node's content but **never its tag**. So
  `result = 0` and the next `result = runByteFn(grup)` write *through* the alias
  (into bcLabel1's content) and cannot rebind `result` to a different node. Only
  another `:=` could rebind it.

Consequence: using `result` as the `:=` argument **poisons the very variable the
`if` tests**. After the first branch, `if result;` is true on every subsequent
op (result is the truthy `bcLabel1`), so `grup := result` keeps firing.

### Why this can't be untangled in incant as written

The obvious fix — redirect through a temp instead of `result` — runs into
bear-trap #1: `temp = result` (`=`) re-tags `temp` to `"temp"` and **loses the
`bcLabel1` tag**, so the redirect target is destroyed. Preserving the target tag
*requires* `:=` — which welds whatever field carries it. So no rearrangement of
`if result; grup := result;` can both (a) test a clean condition and (b) carry a
tag-preserving target into the cursor. The two requirements collide on the
`=`/`:=` tag semantics.

## Blocker B — the `for` loop cannot be steered from its body

Even with a clean redirect, `grup := result` would not divert the walk. The
runtime for-loop is `aCTionFOR` (ruleActions.rtn:409-443). Its advance:

```
while grup = reversE ? LoopOn.prior(grup) : LoopOn.next(grup) {   // 430  advances its OWN C++ cursor
    Looper.group = grup;                                          // 431  re-stamps the incant loop var each pass
    if restrict && grup.affiliation != restrict   continue;       // 432  members-filter
    ...
    result = StatemenT.gMethod(StatemenT);                        // body runs here
```

The loop advances via its **own C++ local `grup`** (`LoopOn.next(grup)`), and
copies it into the incant loop variable `Looper` at the top of every iteration.
The body's `grup` *is* `Looper`. So when the body does `grup := result`, it
rebinds `Looper` — which line 431 overwrites on the next pass from the
C++-advanced cursor. The reassignment is discarded before it can take effect.
This matches the parked finding `project_interpret_loop_branch_not_expressible`:
the loop's advance cursor is structurally independent of the body's loop
variable, so no in-body reassignment can redirect iteration.

(Side note: `interpretBC` appends `opStack` to the bcLIST as a trailing
*attribute* via `argument +% opStack` (`+%` = `opAddAttribute`). The members
filter at line 432 skips it, but it is reached by the `next()` walk and left
permanently hanging on the bcLIST. Benign for correctness, noted for tidiness.
It is also the source of the persistent `opStack not empty at end: 1` line.)

## The design question for Clay

The interpreter needs a dispatch shape that:
1. **tests the branch result without welding** the test variable (avoids Blocker
   A — the `:=`/bear-trap-#1 knot), and
2. **actually redirects the walk** to the branch target (avoids Blocker B — the
   non-steerable `for` advance).

Options on the table:

- **(i) Redirectable `while` with an explicit cursor, in incant.** Drive the walk
  off a cursor field the body owns and updates (e.g. `cursor := nextOf(cursor)`
  by default, `cursor := target` on branch), rather than a `for … members`
  whose advance the body can't touch. Open risks: the same `:=`/`byRef` weld
  semantics still govern any cursor rebind; needs a tag-preserving rebind that
  doesn't poison the test path. Keeps the interpreter in incant.
- **(ii) C++ dispatch loop** (the `branch-mechanism.md` 2026-06-09 prescription).
  A small C++ loop over the bcLIST that honors a returned target by relocating
  its own cursor — sidesteps both blockers because cursor management lives where
  pointer-rebind is unambiguous. Cost: moves the dispatch loop out of incant,
  against the "interpreter in incant" preference; but the C++-floor doc already
  reserves "a small set of primitive operations" for C++, and dispatch may
  qualify.

The trade is essentially: can the `=`/`:=` semantics be made to express a
steerable cursor cleanly in incant (option i), or is cursor relocation one of
the primitives that belongs on the C++ floor (option ii)?

## Cleanups landed today (2026-06-11) — not part of the blocker

These were done while diagnosing; they're correct regardless of the dispatch
outcome, and are uncommitted in the working tree:

- **`$` label fix.** `string "bcLabel" labelIndex` produced `"bcLabel 1"` (the
  string expression space-separates tokens). `$` toggles `useDefaultSpace`;
  `string $"bcLabel" labelIndex` now yields the clean `bcLabel1`. (generate, both
  label sites.)
- **`labelIndex` promoted to `pROPERTIEs`.** Was a C++ int in GroupRules
  (unreachable from incant; `gIF` treated it as a method-local cleared per entry
  → always `bcLabel1`). Now a real incant field in the base registry → unique
  labels across multiple ifs. (Tony's fix; verified `bcLabel1`/`bcLabel2`.)
- **Dead C++-codegen removed.** `generateSignature` (C++ method-signature emitter)
  and `genPrint` (printf-string builder) deleted — we emit bytecode, not C++.
  `gDeclare` removed (no `Declare` rule, never dispatched). genPrint's removal
  also retired the relic `case ',': useDefaultSpace = !useDefaultSpace;` — the
  half-finished migration where the runtime path (GroupActions.rtn) moved the
  space-toggle to `$` and repurposed `,` to `grup = 0`, but the codegen path
  never followed. Commands.rtn now has zero `useDefaultSpace` references.

  *Note:* the genPrint/generateSignature deletions touch Commands.rtn → require
  a `tok GroupRules.twk` + rebuild to drop them from `GroupRules.mm`/`.h`. The
  setup unregistration and the incant-side edits are already live.

## References

- `interpretBC` — incant/generate:338-345
- `aCTionFOR` — ruleActions.rtn:409-443 (advance 430-431, filter 432)
- `aCTionIF` — ruleActions.rtn:449-461 (gate at 457: `if result && isInitialized`)
- `runBRZ` / `runBR` — Bytecode.mm:36 / :26
- `runByteFn` — GroupActions.rtn:632
- bear-trap #1 (`=` re-tags), #3 (`:=` sticky byRef) — CLAUDE.md
- `project_interpret_loop_branch_not_expressible` — parked finding (memory)
- `docs/branch-mechanism.md` — 2026-06-09 reasoning (superseded label now in
  question; its C++-dispatch conclusion is back on the table)
