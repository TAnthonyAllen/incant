# gIF Bytecode Emission — Status & Handoff (2026-05-30)

*Written by Clod for a fresh Clay. Assumes no memory of today. Read top-to-bottom; it is self-contained.*

---

## What this is

Phase Bytecode. We are implementing the `gIF` emitter in `incant/generate` — the generator
method that turns an `if/else` source statement into a bytecode `bcLIST`. Clay wrote the
implementing brief ("Brief — gIF bytecode emission"); Clod executed it. This doc is the
current ground truth, replacing the brief where they differ.

**The runtime is interpreted.** `incant/generate` is incant source loaded at run time, *not*
compiled into the binary. Editing it takes effect on the next run — no rebuild needed.

---

## The lens (one paragraph)

A bytecode instruction is a GroupItem: its **tag** is the opcode, its operands are named
**sub-attribute** fields (`target`, `op1`, …), and its `interpret` handler is inherited from
the registry entry by tag (not stamped per instance). `gIF` does not run a VM — it constructs
branch instructions and bare label sentinels and appends them, in order, to the action's
`bcLIST` via `emitBC`. Labels are bare GroupItems with **no** `interpret` method, so the
interpret member-walk steps over them.

---

## Current `gIF` (committed, clean — `incant/generate`)

```
gIF argument code={
    print `"gIF: tag=" argument.taG "text=" argument.texT:;
    xp  := argument[1];
    st  := argument[2];
    el  := argument[3];
    endLabel = new("bcLabel");
    gXpress(xp);
    if el.listLengtH;                 // structural guard — does NOT evaluate el (see crash note)
        elseLabel = new("bcLabel");
        target := elseLabel;
    else
        target := endLabel;
    emitBC(bcBRZ +% target);          // inline bare opcode → correct tag= bcBRZ
    runGenerated(st);
    if el.listLengtH;                 // else / else-if path — has open findings A & B
        target := endLabel;
        emitBC(bcBR +% target);
        emitBC(elseLabel);
        runGenerated(el);
    emitBC(endLabel);
    print `"End of gIF":;
    };
```

Diagnostic `[gIF.N]` prints have been stripped and the temp fixtures pulled (the no-else win is
committed). The else-path code is left in but is **not yet correct** — findings A (label
aliasing) and B (else-if doesn't recurse) below. To reproduce A/B, re-add the fixtures from the
"Reproducing A/B" section and run the recipe.

---

## DONE — bones-confirmed by actual dump (not shape-read)

1. **Emit construction idiom solved.** Branch instructions are emitted as
   `emitBC(bcBRZ +% target)` — the bare opcode name inline gives the instruction the correct
   **tag** (`tag= bcBRZ`). The earlier `brz = new("bcBRZ"); emitBC(brz)` form was wrong:
   `=`/`setContent` routes the string to the node's *text*, leaving tag = the local var name.
   Passing the freshly-tagged field directly to `emitBC` (no content-copying local) is the fix.
   Bare `bcBRZ` produces a *fresh* field per emit (NOT the shared `bcOPs` registry entry — it's
   not bare-findable today), so no registry pollution; two ifs get two independent `bcBRZ`.

2. **No-else** (`testByteCode`, `testGXLeaf`): `cond / bcBRZ / then / endLabel`. Correct,
   collapses correctly, two ifs each get their own label.

3. **The crash is fixed** (see below). `exit=0`, all five tests complete.

---

## THE CRASH — root cause & fix (durable lesson)

Adding else-bearing fixtures (`testIfElse`, `testIfElseIf`) segfaulted (SIGSEGV) **inside
`gIF` execution**, not in parsing. Localized with per-statement prints under a pty
(`script` — see run recipe). Backtrace:

```
aCTionIF  GroupRules.mm:665
  663  GroupItem *result = ExpressioN;                          // evaluate the if-condition
  664  if ( isMethod(result->groupBody->flags.instructType) )
  665      result = result->groupBody->gMethod(result);         // null gMethod → deref 0x0
```

**`if el;` does not test `el` — `aCTionIF` evaluates `el` as the condition expression.**
For a basic-else, `el` is the else *body* (a non-method) → harmless but it secretly *executes*
the body at generation time. For an **`or` / else-if**, `el` carries `ruleMethod=aCTionIF` →
`instructType` is a method → line 665 *calls* it, re-entering the IF machinery during
generation, and dies on a null gMethod.

**Fix:** guard on structure, not by evaluation: `if el.listLengtH;` resolves to a count
(never a method), so `aCTionIF` can't try to call it. Both `if el;` sites changed.
*This means the brief's suggested `if el;` guard was unsafe for exactly the `or`-case it was
meant to recurse on.*

---

## OPEN — two findings, root-caused (diagnosis done; fixes are design/machinery = your seat)

**A. `elseLabel` gets clobbered to `endLabel` by reusing one `target` local with `:=`.**
Pinpointed by probe (see `/tmp/gif4.log`): `elseLabel.taG` is `elseLabel` at creation AND
still `elseLabel` after `runGenerated(st)` (so the save/restore stack is NOT the cause), then
flips to `endLabel` at the single statement **`target := endLabel`** in the second block.
Cause: block 1 does `target := elseLabel`, block 2 does `target := endLabel`; `:=` *binds*
(shared storage per the foundational incant field semantics), so rebinding the reused `target`
writes `endLabel`'s identity into the still-shared `elseLabel` body. Not save/restore, not a
parser bug — a `:=`-aliasing-through-a-reused-local bug. The constraint that makes this awkward:
`runBRZ`/`runBR` read the operand by the attribute name `target` (`instr->getAttribute("target")`),
so the field *must* be named `target` — which is exactly why I reused the one local. A fix needs
a way to give each branch its own `target`-named operand without `:=`-aliasing them (distinct
locals can't both be named `target`; or stop binding labels with `:=`). Foundational-semantics
call → your seat. Cosmetic for the no-else POP. Compounding interpret-time issue: `emitBC` does
`bcLIST +% arg` = `addAttribute`, which **copies a parented node before adding**
(`GroupItem.mm:211-215`), so a branch's bound `target` node and the emitted label sentinel are
already distinct nodes — node-identity for interpret isn't clean yet regardless of A.

**B. else-if (`or`) does not route to `gIF`; the nested if-body is silently dropped.**
`testIfElseIf` (`if righty > 99; maximus = 1; or righty > 0; maximus = 2; else maximus = 3;`)
completes without crashing, but its `bcLIST` is only
`cond / bcBRZ / then / bcBR / <label> / <label>` — no nested if content. Trace: for a basic
else, `runGenerated(el)` prints `action is: gXpress` and emits; for the `or`-clause it prints
`action is: action` and emits **nothing** — `generator[el]` did NOT resolve to `gIF`. So the
brief's premise "ElseIf → gIF recurses" does not hold: `generator[]` keys on the statement's
*generator identity* (text `gIF` for a real if), but the `or`-clause carries
`ruleMethod=aCTionIF` — that is the *runtime* handler (the very thing that crashed `if el;`),
NOT the generator dispatch key. Design question: how should the generator recognize an else-if
clause and route it to `gIF`? → your/Clay's seat.

---

## Files touched this session

- `incant/generate` — gIF rewrite. **Committed** (clean, no scaffolding).
- `incant/unitTests`, `incant/oneTest` — temp fixtures `testIfElse`/`testIfElseIf` were added to
  exercise the else path, then **pulled** for the clean commit. Repro block below.
- `GroupRules.mm` / `GroupRules.h` — **regenerated** via `tok GroupRules.twk groupDirectives`
  (positional 2nd arg required, else directives silently don't apply). This is the
  debug-instrumented build — a local build artifact, **not committed** (would bake debug code
  into source). Regenerate clean (`tok GroupRules.twk`) before any commit that includes them.

The no-else gIF win is committed. A and B remain open (see above). The else-path code stays in
`gIF` but is unexercised by the committed suite and known-imperfect.

---

## Reproducing A / B (fixtures were pulled — re-add to reproduce)

Add to `incant/unitTests` after `testGXLeaf` (keep inline — multi-line `else` breaks checkSkip):

```
    testIfElse code={ if righty > 0; maximus = righty * 2; else maximus = 7; };
    testIfElseIf code={ if righty > 99; maximus = 1; or righty > 0; maximus = 2; else maximus = 3; };
```

Add to `incant/oneTest` before the `generateCode(testEmitBC)` block:

```
generateCode(testIfElse);
dumpBC(testIfElse.bcLIST);

generateCode(testIfElseIf);
dumpBC(testIfElseIf.bcLIST);
```

Then run the recipe below. `testIfElse` shows finding A (label tag stomp); `testIfElseIf` shows
finding B (no nested if content). To re-localize A, re-add a probe print of `elseLabel.taG`
before and after `target := endLabel` in the second `if el.listLengtH;` block.

---

## Run recipe (defeats crash-time buffer loss)

```
cd /Users/anthony/Library/CloudStorage/Dropbox/data/InProcess/Groups
script -q /tmp/gif.log  ~/bin/incant  <abs-path>/incant/oneTest
```

`script` runs the binary under a pty → stdout is line-buffered → output survives a segfault
(a plain `| grep` is block-buffered and loses everything after the last buffer flush, which
reads as "stopped early" when it actually crashed later). `exit=11` = SIGSEGV; `exit=0` = clean.
Grep the log for `running on`, `gIF.`, `emit tag=`, `dumpBC for bcLIST`, `Program crashed`.

---

## Next actions

No-else win is committed; scaffolding stripped; fixtures pulled. Remaining work is **held for
Clay's design direction** (Clay's call, 2026-05-30):

1. **B (held):** Clay is deciding between retagging the `or`-clause before it reaches the
   generator vs. a generator-dispatch fallback that keys on `ruleMethod`. Do not touch the
   dispatch routing until he gives direction.
2. **A (fix identified, not yet applied):** two distinct target locals (`elseTarget`/`endTarget`)
   is almost certainly right, but the operand attribute must still be named `target` for
   `runBRZ`/`runBR` — so the fix needs a construction that yields a `target`-named attribute per
   branch without `:=`-aliasing. Clay wanted the probe output first (now in this doc) and will
   bless the exact shape. Do not touch the target local until then.

---

## Session update — later 2026-05-30 (DIRECTION CHANGED)

Supersedes stale bits above. The gIF no-else commit (`19e6b5b`) was **made then undone**
(`git reset --soft`) — Clay chose to hold off. Work preserved, staged, uncommitted.

**Bigger pivot: the bytecode contract is moving from three-address to STACK-FORM.** Driven by
the runBRZ recon — `Bytecode.mm` handlers read named operands (`op1/op2/cond/target/dst`) while
`gXpress` already emits stack-push form; the two never met. Decision (Clay): rewrite
`Bytecode.mm` → `Bytecode.twk` with stack-form handlers (operands on a LIFO operand stack, only
the branch label stays on the instruction under `dst`). This **reframes findings A & B** above —
the named-`target` problem dissolves (operands come off the stack; branch label is `dst`), and
the op-shims become "pop two, materialize a stable result, push."

State of the stack-form rewrite:
- ✅ **`GroupItem.twk` push fix** — `push` now self-inits a null list (mirrors `addGroup`);
  toked `tok GroupItem.twk groupDirectives`, diff is the 3-line guard only, **built clean in
  Xcode**. Removes the need to seed `opStack`'s list.
- 📋 **`Bytecode.twk`** — written (stack-form handlers: `runPushLit/runPushField/runStoreField`,
  `runGT/runMultiply` materialize fresh result nodes off the shared `tempField`/`trueResult`,
  `runBRZ/runBR/runRET`). Awaiting Clay's review before landing the next two files.
- ⏸️ **`incant/setup`** (register `bcPushLit/bcPushField/bcStoreField` with `interpret=`) and
  **`incant/bytecode`** (`interpret()` creates/clears `opStack` on the bcLIST; assert empty at
  `runRET`) — held until `Bytecode.twk` is okayed.

**TOK LESSON (reburned):** instrumented `.twk` files must be toked `tok X.twk groupDirectives` —
bare `tok X.twk` silently strips the directive-injected debug code (52 lines vanished from
`GroupItem.mm` before I caught it). Always the positional arg.

## Side task — DEFERRED (do not do now; Clay's call)

**Buffer-family command wiring.** `setMark`/`unMark`/`setFile`/`closeFile`/`applyTextDirective`
are defined in `GroupRules.mm` (+ `.h` decls) but **not** registered in `incant/setup`'s
`cOMMANDs` and **not** in `Commands.rtn` → unreachable from incant (`setMark`/`unMark`: 0 incant
refs). To wire them: a `cOMMANDs` entry + a home in `Commands.rtn`; note `setFile(buf, char*)`
takes 2 args, so it may belong as a buffer-field method rather than a `command(arg)`. Also
flagged: `Commands.rtn` (the new home for command externs) is **not yet in `groupIncludes`**, and
24 externs are duplicated between it and `GroupRules.mm` — adding it to the build without
deleting the GroupRules.mm originals = duplicate-symbol link error. Migration is staged, inactive.

---

## FINAL STATE — end of 2026-05-30 session (stack-form landed + gXpress operator fix)

The whole stack-form rewrite landed and **oneTest is green** (exit 0, no crash, no parse fails,
no "no handler"; all of testByteCode/testGXLeaf/testIfElse/testEmitBC run, operators read `>`
everywhere — the `xl` aliasing is gone).

**Architecture as built (supersedes the bcOPs-fold note above):**
- The bcOPs→Operators **fold was tried and reverted** — putting bc-op names in `Operators` makes
  them operator-TOKENS, which breaks the emitter source (`emitBC(bcPushLit=tmp)` etc. won't
  parse). Proven by run: bc ops out of Operators → oneTest green.
- Instead: **`bcOPs` is a separate registry** (in `incant/setup`) **added to the search list**
  via `search reset … bcOPs;` in `incant/oneTest` (the driver / emit-time context — NOT in
  `incant/generate`, which broke Generating's own definition). Bare bc-op names resolve there as
  names; the emitted op inherits its `interpret=` handler; `interpret()` dispatches via plain
  `grup.interpret` (incant/bytecode), no special-case lookup.
- `Bytecode.mm` is tok-generated from **`Bytecode.twk`** (stack-form handlers). Tok lessons:
  (1) the class name sets the output filename — dummy `class Bytecode { void run(){} }` needed;
  (2) extern method decls go in `groups.ext` under an `external Bytecode.h { … }` block (alpha
  order) + an `external Bytecode` forward-decl up top; (3) **`include` must be line 1** — a `//`
  comment block before it makes tok bail at the top (the "Inheritance"/last-function red herring);
  (4) a `//`-block immediately before a `/* */` block before the class corrupts the `.h` (dropped
  `*/`); (5) instrumented files must be toked `tok X.twk groupDirectives` or injections vanish.

**Emit fixes landed (Clay's sequence):**
- **#1 gIF branch operand `target`→`dst`** — done; `runBRZ`/`runBR` read `getAttribute("dst")`.
- **#2 operator identity (the `xl` bug)** — FIXED. `gXpress` now **walks `tmp` for the
  `isOperatoR=1` member** (operator position varies / assignment has none) and emits it directly;
  cond `righty > 0` → `bcPushField 13, bcPushLit 0, >`. Correct stack-form, no aliasing.
- **#3 `bcStoreField` for assignment** — landed in source: `gXpress` assignment branch
  (`gXpress(rhs); emitBC(bcStoreField +% target)`), `runStoreField` reads `getAttribute("target")`.
  **PENDING: a rebuild + the #4/#5 unblock to verify** (the then-body duplication masks it today).

**THREE incant-machinery gotchas hit writing gXpress (durable — will bite again):**
1. **`!field.isOperatoR` crashes** — a GroupField accessor returns NULL (not a 0-count) when the
   flag is unset, and `opNOT` (GroupRules.mm:2661) derefs without a null-check. Use positive
   tests (`if field.isOperatoR; … else …`), never `!field.accessor`. Same family as `if el;`.
2. **Recursive `next()` clobber** — `for child in tmp; … gXpress(child)` dies after one iteration:
   the recursive call's own for-loops clobber the shared `next()` iterator state (CLAUDE.md's
   "shared entry state"). Don't recurse inside a list-walk; capture by index instead.
3. **Shared `tmp` clobber in a recursive arg** — `gXpress(tmp[2])` reassigns the shared `tmp`
   local inside the call, so `gXpress(tmp[3])` reads garbage. Capture operands into locals first
   (`tgt := tmp[2]; rhs := tmp[3];`) before recursing.

**DEFERRED (#4/#5 — not Clod's lane; design question for Clay/Haps):** the then-body duplicates
the cond and values are constant-folded at parse (`bcPushLit 0` not `2`, `bcPushField 13` not a
live `righty` ref). Pre-existing (was `[13,0,xl,…,13,0,xl]` before the operator fix). It masks
the assignment branch. Root: how `gXpress`/the parse tree handle live field refs vs folded
values. Also flagged upstream: **`=` is structural, not an operator node** — the right long-term
fix is "expressions as a list of fields" (so `=` sits in the list beside `>`/`*` and gXpress
collapses to a single uniform walk instead of the 3-way branch).

**To resume:** rebuild incant in Xcode (Bytecode.mm now stack-form) → run oneTest → with #4/#5
addressed, exercise `interpret(testByteCode.bcLIST)` to verify the handlers execute end-to-end.
