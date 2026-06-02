# Wake-up — Bytecode Generation Session
*Written by Clay (claude.ai) for a fresh Clay/Clod. Reviewed by Clod before commit. Self-contained orientation for Phase Bytecode work.*

*Tony will provide local copies of projectBible.md, TODO.md, PLGrevision, and any other needed files at session start. Repo links are below for reference but load from local sources — GitHub fetch has a stale cache problem that bites every session.*

*Deep plg/Tawk internals (for when that work reopens — the //dealWith markers, the pending generated-file banner task, the action-format/attachActions machinery) live in the companion `docs/plg-wakeup.md`. This doc is "where we are + what's next."*

---

## Repos
- PLG: https://github.com/TAnthonyAllen/plg (`~/data/InProcess/Parse/`)
- Tawk: https://github.com/TAnthonyAllen/tawk (`~/data/InProcess/Tokf/`)
- Incant: https://github.com/TAnthonyAllen/incant (`~/data/InProcess/Groups/`)
- Support: https://github.com/TAnthonyAllen/support (`~/data/support/`)

---

## What closed today — do not redo

The `plg Tawk.g → Tawk.twk → tok → Tawk.C` pipeline is fully working and committed for the first time ever. Six blockers cleared:

- `flag1`/`flag4` reinstated on PLGitem; `dummy.ext` retired
- Debug flood killed (`debugRulePLG` stray flag removed; 4M → 4.9k log lines)
- `writeCaptures` alignment fixed — action-less alternatives (Commands) now skipped in the action-distribution loop (in `generateRules`; `writeCaptures` itself was already per-alternative); discriminator = labeled element AND shell exists
- Externals surface restored: `valueItem→itemValue` alias, `%` overload on PLGitem, `flag1`/`flag4` in PLGrevision
- `firstComponent` → `parts["other"]` (PLGtester artifact removed)
- kKeyTable/kCondition elements now emit native Tawk, not raw C++

**Committed state:**
- `tawk.git`: `040d84e` (.act migration), `42c9494` (Tawk.twk + Tawk.C POP artifact)
- `plg.git`: `81510dd` (fields/debug/writeCaptures), `a3c0bab` (native Tawk emission)
- `support.git`: `9c3cc76` (PLGrevision externals surface)

Tony is running and testing Tawk offline. Do not reopen Tawk work unless he brings it back.

---

## Open //dealWith markers (12 total, in the .act files)

These are Tony's annotations from his offline migration pass. They mark spots needing follow-up:
- `operate.next` dead reads in `UnaryExpression:2` / `ExpressPart` — structurally always null (single-match operate); harmless but cleanup candidates
- `&` not in UnaryOperator charset yet `UnaryExpression:2` tests `operate eq "&"` for reference — either `&` belongs in the charset or that branch is dead. Tony's call.
- `ExpressType` — action with no grammar rule, used as optional in `ExpressPart`. Old PLG handled gracefully (fails as rule, action fires anyway). New PLG behavior unverified. Not blocking.
- Remaining `next`/`flag1`/`flag4` usage sites — fields now exist, but some bodies may need logic review

These are not blockers for Phase Bytecode. Leave them until Tony brings them up.

---

## Phase Bytecode — where we are

**The active work is in `Groups/` (incant repo).** Key files:
- `incant/generate` — the generator, including `gIF`, `gExpressioN`/`gXpress`, `gBlocK`, `gFOR` etc.
- `incant/bytecode` — the bytecode interpreter (`interpret()`)
- `Bytecode.mm` — C++ bcOPs registry and handlers
- `Generate.rtn` — `generateCode()` entry point

(The active incant source was promoted from `XML/WorkingOn/` to top-level `incant/` on 2026-05-29.)

**Pipeline:** `generateCode(action)` → `generatE` → `runGenerated` → per-statement handlers → bytecode GroupItems → `interpret(bytecode)`

**The interpreter is deliberate.** bcOPs dispatch is the correct-first step before JIT. Same bytecode stream survives into JIT — the executor changes, not the ops. Don't second-guess the interpreter; get the emit side right.

**POP target — `testByteCode`** (`incant/unitTests:159`):
`if righty > 0; maximus = righty * 2;` → expected emit `runGT, runBRZ, runMultiply, runAssign, runRET`; expected outcome `maximus = 26`.

**Status as of last verified session:** `gIF` and `gExpressioN` are stubs. They are what stand between us and the POP test. Everything else in the pipeline was verified working (Brief 3 closed 2026-05-26 — both cross-test bleed root causes fixed).

---

## The list approach for gExpressioN — and the action changes it needs

**`gXpress` and `gExpressioN` are the same thing.** Not two separate handlers.

**The approach (Clay knows the list notion):** `ExpressioN` hands `gExpressioN` a **flat list of fields** — operands and operators — not an instruction tree. gExpressioN walks the list and emits: operand → push, operator → emit op. Trivially simple, *because* the hard part moved upstream into the unwrap.

**Why it's genuinely flat (settled this session):**
- **incant has no parenthesized sub-expressions.** No `(B + C)`. So there is no nesting and no precedence story for gExpressioN to handle — the list is flat, leaf-level, one pass. (The `(...)` incant *does* have is a rule-argument *input stream* — see below — not arithmetic grouping.)
- **`rule(argument)` resolves at parse time.** The rule consumes its argument stream during parsing and leaves a plain result field on the list. By the time gExpressioN sees it, it's just another field — gExpressioN doesn't care what's inside.

**The two action changes this needs** (these are *rule-action* edits — new ground for Clay; read the "Rule actions" section next):

1. **`aCTionTokenXP`** currently wraps `rule(arglist)` / method calls `A(B)` / dot-access `A.B` into an **instruction** that `runOP` handles at runtime. Add an `if generating` branch so that **when generating it emits plain fields, not instructions.** That's what makes the xpList uniform.
2. **`aCTionExpressioN`** (`extern GroupItem aCTionExpressioN(GroupItem xpList)`) — add an `if generating` branch that **walks `xpList`, unwrapping any still-wrapped fields → a clean flat list** for gExpressioN.

**The linchpin: the `generating` flag.** Set it in `generateCode`; both `aCTionExpressioN` and `aCTionTokenXP` branch on it. One switch, two sites. When it's on, the xpList reaching gExpressioN is a **throwaway** — so gExpressioN may iterate it however it likes (non-destructive `<-` reverse walk, or a destructive `xp.pop()` drain) without mutating the live program tree.

**The one bytecode special case (NOT in the POP path):** a *rule invocation* can't be two bare operand fields — gExpressioN must recognize it and emit a `bcCall`-shaped op. Recognition lives in **interpret**, not gExpressioN: the `bcCall` handler inspects the callee and branches *callee is a rule → `runRule()`* (the clean template in `GroupActions.rtn`, **not** runOP's swamp) *else method dispatch*. gExpressioN stays uniform. `testByteCode` has **zero** calls, so this is a few-lines follow-on *after* `maximus = 26` lands — don't bloat the POP with it.

**FIFO vs LIFO is empirical.** You'll probably want right-to-left, but with the `<-` FOR modifier now built (below), you don't have to be right on theory — point gExpressioN at `testByteCode` and let `maximus = 26` tell you which way the list wants walked. If reverse flips a non-commutative operand order, you'll see it in the output and flip the flag.

---

## Rule actions — how they work (orientation; new ground for Clay)

The model: **the parser wields the hammer, the action IS the hammer.**

- **`GroupItem.parse` (`GroupItem.twk:879`) is the parser.** Recursive-descent: literal/rule match, optional via `min`/`max`, labeling via `parentLabel +% label`. **Do NOT touch it** — changing the parser is a yak-shaving trap. New grammar features ride the *existing* parse machinery.
- **The grammar (`incant/grammar`) defines a rule.** Parsing it produces a **result label** — a GroupItem whose sub-fields are the rule's labeled elements.
- **The action (`ruleActions.rtn`, `extern GroupItem aCTion<RuleName>(GroupItem input)`) does NO parsing.** It reads the result: `input["Looper"]`, `input["ExpressioN"]`, etc. An **optional** element (`X?`) yields a label **present iff matched**, so the action checks `if X`.

Two local-declaration idioms: explicit `field = input["field"]`, and the `:` shorthand `field:` (auto-binds the local from the like-named label; common for optionals, e.g. `LoopRestrict:`). The grammar `?` placement matters only when combined with a quantifier (`field?=stuff+` = "optionally capture one-or-more"); for a bare optional it's positionally moot.

### Worked example — the FOR `<-` LIFO modifier (done this session, in the working tree)

incant for-loops only walked FIFO. Added an optional `<-` after `in` to walk LIFO (tail→head) — the same mechanism Tony wants for `LoopRestrict`'s LIFO, so reverse gets **one spelling**. This is the exact grammar-tweak + action-branch pattern the `aCTionExpressioN`/`aCTionTokenXP` changes will follow — study it first.

- **Grammar** (`incant/grammar:139`): `… in- reversE="<-"? ExpressioN …` — a labeled optional literal; rides existing parse machinery, zero parser change.
- **Action** (`aCTionFOR`, `ruleActions.rtn`): read `reversE = input["reversE"]`; loop steps `while grup = reversE ? LoopOn.prior(grup) : LoopOn.next(grup)`. `prior()` already exists (`GroupItem.twk:979`); substrate is doubly-linked (`nextInParent`/`priorInParent`, `firstInList`/`lastInList`), and `prior(null)` returns `lastInList` so reverse starts at the tail for free.
- Usage: `for field in <- xp;`.
- **Open review points** (Tony reviewing in Xcode, pre-build, both self-revealing on first run): the `=` vs `?:` precedence in the ternary (incant has no grouping parens, so it relies on assignment binding loosest — restructure to `if/else` step if it doesn't); and whether `input["reversE"]` reads falsy-when-absent or needs the `:` form.

---

## Bytecode design (settled — recap)

- An instruction's tag IS the op GroupItem
- Two registries: `Operators` (expression ops) vs `bcOPs` (bytecode handlers)
- Implicit-next dispatch with branch ops reassigning `grup`
- Bytecodes are GroupItems
- **Dispatch idiom (don't chain):** `handler = field.attribute;` then `handler(argument);` — one method per field, sub-attribute pattern for a second invokable behaviour

**Bytecodes for reference:**
- `A = B + C` → `bcPushField B`, `bcPushField C`, `bcAdd`, `bcStoreField A`
- `A = B(C) + D` → `bcPushField C`, `bcCall B`, `bcPushField D`, `bcAdd`, `bcStoreField A`
- Unary prefix `++C` emits before operand is consumed; postfix `B++` emits after. Grammar constraint and stack order are consistent — no conflict.

---

## LoopRestrict (on the radar, not blocking)

Tony wants `LoopRestrict` bin-like with a LIFO option, to solve incant for-loops only walking FIFO. The LIFO **glyph now exists** — the `<-` reverse modifier built into the FOR rule this session (see Rule actions above). LoopRestrict's LIFO should **reuse `<-`** so "reverse" has one spelling across the loop constructs. Don't design around it, don't design against it.

---

## Standing rules for this codebase

- **Never touch `.C`, `.mm`, or `.h` files directly** — tok generates them from `.twk` (hand-edit a generated `.h` only with a stated good reason, e.g. no `.twk` exists or tok is broken)
- **PLGrevision is the externals surface** — missing fields/aliases/overloads go there, not in ad-hoc `.ext` files
- **Native Tawk over C++ escape** — prefer tok-parseable Tawk syntax; C++ escape (`-% … %-`) is last resort
- **Verify by running, not shape-reading** — "verified" means output captured from a run
- **Dispatch idiom: don't chain** — one method per field
- **Build plg Debug only** — Release config broken (support can't find PLGparse.h); `xcodebuild -project plg.xcodeproj -target plg -configuration Debug` (→ build/Debug/plg, which ~/bin/plg symlinks)
- **Always `tok X.twk plgDirectives`** for plg's own `.twk`

---

## What to do at session start

1. Read this file
2. Load projectBible.md and TODO.md from local sources (Tony provides)
3. Ask Tony if there's any offline work since this wakeup was written
4. Orient on `incant/generate` — specifically `gIF` and `gExpressioN`
5. Confirm current test state: does `testByteCode` still fail as expected?
6. Then proceed

---

*Reviewed by Clod 2026-06-01: accepted with four factual corrections — Phase Bytecode paths `XML/WorkingOn/` → `incant/` (2026-05-29 promotion); `testByteCode` line `:124` → `:159`; added the `plg-wakeup.md` companion pointer; clarified the writeCaptures fix lives in the distribution loop. Everything in "What closed today" verified against the commits.*

*Revised by Clod 2026-06-01 (post-POP, for Clay's follow-up): expanded the gExpressioN section into the full list→action plan (the `generating`-flag-gated `aCTionExpressioN` unwrap + `aCTionTokenXP` plain-fields branch, plus the settled facts — flat incant expressions, parse-time `rule(arg)` resolution, rule-call→`bcCall`/`runRule`); added a "Rule actions" orientation section (new ground for Clay) with the FOR `<-` LIFO change as the worked example; noted `<-` as the now-existing shared LIFO glyph for LoopRestrict.*
