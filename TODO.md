# TODO.md — PLG/TAWK/Incant Ecosystem

*Read this first every session. Keep it current.*

---

## Phase Generate Tawk — BLOCKER + today's state (2026-05-30)

**🚧 generateRules class-body/extern split (THE blocker).** `plg Tawk.g → Tawk.twk`
runs and is clean of PLGtester, but the output **does not tok**: generateRules
dumps Tawk's class field declarations at file scope (above the `class Tawk
extends PLGparse` wrapper, alongside the extern action bodies). tok →
`ERROR Inheritance` on the first field → empty `Tawk.h`, stale `Tawk.C`. Fix:
split class-body material (fields → inside the class) from extern bodies. Design
work / woodshed session. Full writeup in projectBible.md "Phase Generate Tawk".

**Done today (keep, don't redo):**
- **plg outputs `Tawk.twk` directly** (no `.regen`). `~/bin/plg` → symlink to
  `Parse/build/Debug/plg` (old binary at `~/bin/plg.may17.bak`). Release config
  broken (`support` can't find `PLGparse.h`); Debug used.
- **Two-arg `divertInput` reinstated** in PLGparse (`divertInput(s,rule)` /
  `(s,ruleName)`) + declared in `PLGrevision`. Was dropped in the refactor;
  unblocked Instance/Directive/etc.
- **FAIL handlers relocated** `Tawk.g %%` → `Tok.twk` as file-scope externals
  using a new `static Tawk Tok::testParser` (set in main). Tawk.g epilogue
  stripped. NOTE: new regen emits **zero** `currentRule.fail` wiring (separate
  plg FAIL-codegen gap) — handlers are defined but **dormant** until that lands.
- **PLGset.C phantom-include hand-prune.** `support/Frame/PLGset.C` had spurious
  `#include "PLGparse.h"` + `"PLGitem.h"` (tok auto-include bug); pruned to let
  plg rebuild. ⚠️ Re-added on any `tok PLGset.twk` — durable fix is the tok
  auto-include bug (FormatC.twk).
- **Tawk.twk for now = legacy commit `89a3abc`** (old format, toks). Avoid HEAD
  `ef2730d` (broken Phase Splice) and fresh regen overwrites.

---

## Tomorrow's wake-up — 2026-06-03

**Current state (end of 2026-06-03, Phase Bytecode arc + checkSkip fix + Layer B delimiter test):**

### checkSkip — CLOSED 2026-06-03
Year-old flakiness finally fixed. Root cause: the indent-adopt in checkSkip grabbed
inter-token whitespace as an indent level because `indenting` counts any whitespace,
not just post-newline whitespace. One gate — `sawNewLine && !lastINDENT` — is the
entire fix. Gate on the commit (`blocking||defining`) was over-engineering and caused
a regression; pulled back. Full suite validated: delim repro, oneTest, directives,
full testUnitTests POP. All green. checkSkip now actually right for the first time.
NOTE: checkSkip runs on every parse — validate full suite on any change.

### Phase Bytecode — current gate
`generateCode(testByteCode)` producing correct bcLIST (9-op stream, structurally
right for `if righty > 0; maximus = righty * 2;`). The gate: bcLIST accumulator not
populating `testByteCode.bcLIST`. Instructions land on `generator.bcLIST` but not
the action's own slot.

Root cause fully traced:
- `new("bcLIST")` with no data means `+=` in `opPlusEQ` hits the `copyData` path
  (target has no data → copies first instruction's data INTO bcLIST) rather than
  list-append. Every subsequent emit then does arithmetic on the scalar, not append.
- Fix: mark bcLIST list-typed at creation in `Commands.rtn` (candidate 1) so `+=`
  routes to the `target.groupList` list-append branch in `opPlusEQ`. Targeted, no
  blast radius.
- `opPlusEQ` global fix (copyData→+=) was tried and caused SIGTERM blast radius —
  reverted. Do not retry that approach.
- `Commands.rtn` copy-back (accumulated→fieldList after `runAction`) still in place,
  harmless, may become load-bearing or redundant once accumulator fills.

**Next move on Phase Bytecode:**
1. Mark `bcLIST.groupList = true` (or equivalent) in `Commands.rtn` after
   `new("bcLIST")`, before `generator.replace(bcLIST)`. Re-tok, Tony rebuilds.
2. Verify `interpretBC` walks the 9-op stream.
3. Slot-name reconciliation pass: `target`/`field`/`dst` convention across
   `ruleActions.rtn` + `gXpress` + `Bytecode.twk` in one pass (Clod offered to
   draft this brief). Sub-findings pending gate open:
   - `runStoreField` reads `getAttribute("target")` but `ruleActions.rtn:307`
     keys destination under target's tag ("maximus") not "target". Fix in
     `ruleActions.rtn` (Tony's seat).
   - `bcPushField` handler needs `getAttribute("field")` to resolve current value;
     currently `setContent(instr)` copies empty content. Fix both sides together.

**Brief 5 pass — 2026-06-04 (Clod, committed `413ab2a`):** ran the gate
empirically; the root cause above is confirmed (dumpBC → "single field xp",
opPlusEQ trace at Instruct.rtn:437-451). Outcomes:
- **Fix 1 (members vs attributes) = STALE.** emitBC already uses `+=`; the
  blocker is the bcLIST-not-a-list bootstrap above, not the walk side. Stale
  notes in `incant/generate` + `incant/bytecode` corrected.
- **Fix 2 (gXpress `=` asymmetry) = MOOT.** Verified across testByteCode,
  testIfElse, testGXLeaf: the assignment target is never pushed (ruleActions
  pre-transforms `=`→bcStoreField; gXpress sees `[rhs..., bcStoreField]`).
  Adding an `=` branch to gXpress would be dead code — NOT implemented.
- **Fix 3 = DONE.** Stale `testEmitBC` (called unregistered `bcMul`) retired
  from `generate` + `oneTest`.
- **New gap:** `testIfElse` else-branch (`maximus = 7`) emits NOTHING —
  `runGenerated(el)` at gIF (generate:274) produces no instructions. Separate
  from the gate; worth a look once bcLIST is walkable.
- Emit stream is structurally correct (9 ops). Remaining path to maximus=26 is
  all Tony's seat: (1) bcLIST list-typing, then (2) the slot-name reconciliation
  above. interpretBC isn't even called by oneTest yet (generateAction calls it).

**gExpressioN — DEAD, DO NOT RESURRECT.**
ExpressioN is not a deferred rule. The label feeding `generatE` is `gXpress`,
set as an exception in the `StatemenT` rule action. There is no `gExpressioN`
and there never will be. Remove any reference to it on sight.

### Delimiter / DatA grammar test — Layer B banked, Layer C is next
Self-contained file: `incant/delimTest`.

**Layer A (virtual delimiter)** — deferred. Virtual field earns its own test when
it demonstrates something a plain field doesn't. Not this test.

**Layer B** — DONE AND PROVEN. `DelimOver` rule (`body}=delimiter`, `}` = upToOver,
consumes delimiter) defined and driven standalone. `DelimOver("hello world #>")`
captured `body: hello world` cleanly. Modifier mapping confirmed from `parse.rtn`:
`}` = upToOver (consume), `{` = upTo (leave). Multi-char terminator confirmed
working (`#>` two-char match via `compareToStream`). Rule lives in `incant/delimTest`.

**Layer C — DONE AND PROVEN 2026-06-03. VERDICT: incant's grammar IS
live-mutable post-bootstrap.** A new alternative (`DelimText`) was grafted into
the bootstrap `DatA` rule at runtime, and a subsequent field definition routed
its data through that brand-new alternative. Output: `doc = (hello world#)`
yields `doc.dtext = "hello world"` via DelimText, a rule that did not exist at
bootstrap. The locomotive changed while the train stayed on schedule.

The three moves, as they actually played out:
1. **Directive-on-rule probe (1b)** — `DatA += DiRProbe` (a DiR-tagged arg) →
   `applyDirectives`/`spliceDirectives` only splices BlocK *Lines* (code bodies);
   DatA has no BlocK, so it just registered a `DiRs` bookkeeping sub-registry and
   grafted nothing (`ERROR processCode: DatA parse failed`). Directives CANNOT
   graft a rule alternative. So the graft goes in raw.
2. **In-place graft** — `DatA += DelimText` (a non-DiR arg falls past the
   directive branch in `opPlusEQ` to `target += argument` = raw member append).
   Structure mutated: DatA went 5→6 members. But the parser still rejected the
   new opener, because **DatA's cached `guardSet` is computed at bootstrap and a
   raw append does NOT re-wire it.** Fix: a new language primitive — `guard(DatA)`
   run as a COMMAND (new `!fLAG` branch in `Commands.rtn`: clears `guardSet` AND
   resets `guarding=0`) forces the parser to re-derive the guard on next parse,
   now seeing DelimText's opener. So: structure is live-mutable; guard-dispatch
   is wired at definition-time, but `guard()`-as-command re-wires it.
3. **The verdict** — proven live-mutable (see above).

**Findings banked (Layer C):**
- **`guard()` is now a reset command.** Run as an attribute it SETS a guard (old
  behavior, unchanged); run as a command on a rule it CLEARS guardSet + resets
  guarding so the parser re-derives. `Commands.rtn` → `GroupRules.mm` (tokked).
- **Opener char must clear two gates.** It must be excluded from `NotA` (else
  NotA's catch-all eats it before DelimText's guard is consulted) AND be
  checkSkip-neutral. `>` clears NotA but FAILS checkSkip (it's in
  `endDefine=[;>]`; a `>` right after `=` is eaten at the define level). Switched
  to `(`: `NotA=[^ \t\r\n;(]+` (GroupMain bootstrap) + `delimiter="#)"`
  (setup:150). Closer is DelimText's own `delimParen="#)"` field.
- **upToOver leaves shared parser state.** Running Layer B's `DelimOver`
  (successful `upToOver`) BEFORE the move-3 graft corrupts the live parse —
  move-3 drops out of Start. Deferring `runDelim()` to AFTER move-3 fixes it.
  Order-of-execution coupling in the upToOver mark/stream global — open finding,
  worth a closer look.
- **Bare graft only.** DelimText must carry NO inline `code={}` action: an inline
  code body is a CodE instance, and grafting a CodE-bearing rule into DatA (which
  holds the CodE rule as a member) trips addGroup's self-add guard ("add CodE to
  itself"). Real DatA alternatives (SetBrackets/NotA) carry no inline code.

**Open polish (next session):** the capture lands in `doc.dtext`, not `doc`'s own
data — DelimText captures into its named `dtext` field, whereas NotA-style
alternatives set the field content directly via `aCTionTraiTdata`. If we want
`doc` itself to carry the text, DelimText should capture into self, not a subfield.

### unitTests comment rewrite — DONE 2026-06-03
Inline per-action comments scrubbed. Leading block added with four sections:
registry description, concentrated incant-vs-C++ divergences, POP table, known
broken note (callMyself). File replaced at `Groups/incant/unitTests`.
NOTE: `unitTests` now lives at
`/Users/anthony/Library/CloudStorage/Dropbox/data/InProcess/Groups/incant/`
(post-reorganization). Update projectBible.md directory map to reflect this.

### Git state (end of 2026-06-03)
- **checkSkip win — COMMITTED + PUSHED as `fe9612d`** on `origin/main`
  (`GroupRules.twk` + regenerated `GroupRules.mm`, checkSkip sawNewLine gate).
  `incant/delimTest` (Layer B rule + driver) and `Commands.rtn` (bcLIST
  copy-back) rode along in the same commit — see commit body.
- **Layer C live-grammar-mutation win — COMMITTED 2026-06-03.** Files:
  `Commands.rtn` (guard-reset command) + regenerated `GroupRules.mm`;
  `GroupMain.twk`/`GroupMain.mm` (`NotA` excludes `(`); `incant/setup`
  (`delimiter="#)"`); `incant/delimTest` (Layer C graft + verdict). Only these
  six files staged — the parked WIP below was deliberately left out.
- **Parked WIP (still uncommitted, leave separate):** `incant/generate` +
  `incant/bytecode` (Fix 1 `+%→+=` + Fix 4 comment corrections).
- **Tony's review needed (uncommitted):** `groupDirectives` + `GroupItem.mm`
  (debug scaffolding from the checkSkip hunt — revert when done), pre-existing
  comment drift (`unitTests`, `utilities`, `ruleActions.rtn`, `oneTest`,
  `XML/WorkingOn/parser`).

---

## Aisle 3 cleanup — 2026-06-04 (delimTest + directives distilled)

First-pass distillation of `incant/delimTest` + `incant/directives` from WIP
into legible, headed files (committed `5e98bb2`; Clay to polish headers/structure).

- **delimTest** — comment-only; header leads with the Layer C headline, the
  load-bearing run-order constraint is now a documented finding. Output verified
  identical to baseline.
- **directives** — reorganized per-deliverable + unitTests-style header; POP
  table documents ACTUAL behavior. Two bugs surfaced and documented (not fixed):

  1. **Directive replace/delete content-match broken.** `testDirectiveReplace`
     and `testDirectiveDelete` drop the target block's FIRST line regardless of
     content — "replaced line" never appears, fromBody/toBody don't drive the
     match. Suspected non-functional content-match in `statementMatches` /
     `matchSpanInLines` (positional drop, not content-driven splice). Next-pass
     bug hunt for Tony + Clod. The text-substrate path (DiRSwapInt) DOES
     content-match, so the break is specific to the BlocK-line path.
  2. **getFile pushInput parses loaded files** (Tony chasing in Xcode).
     `testTextDirective` exits 2 with `getFile: ... include: Is a directory`.
     `getFile` (Commands.rtn:235) does `pushInput(filing)` — it reads the file
     AND queues it as incant input to parse. Loading real TAWK source
     (groups.twk) then parses its unquoted `include <path>` first line, which
     can't bind an arg → `getFile("include")` → the include/ dir. Replace
     itself still lands. A parse-inert fixture would sidestep it.

---

## Phase Bytecode — full plan (active)

### Design (locked)
- bytecodes are GroupItems in a bcLIST, dispatched via `interpret=` sub-attribute
- two registries: `bcOPs` (incant-defined control/data-movement ops) and
  `Operators` (C++-defined arithmetic/compare ops, carry `interpret=` directly)
- `gXpress` walks the RPN revisedList and emits one push/op per child
- `interpretBC` walks bcLIST members, dispatches via `grup.interpret`

### Active code (incant/generate + Commands.rtn + Bytecode.twk)
- [x] Fix 1: `emitBC` `+%→+=` (instructions land as members)
- [x] Fix 4: comment rot in `generate` header §2(a), §2(c) and `bytecode` header
- [ ] **NEXT: mark `bcLIST.groupList = true` at creation in `Commands.rtn`**
- [ ] Verify `interpretBC` walks 9-op stream after above fix
- [ ] Slot-name reconciliation: `target`/`field`/`dst` across
      `ruleActions.rtn` + `gXpress` + `Bytecode.twk`
- [ ] Run remaining bytecode tests: `testGXLeaf`, `testEmitBC`, `testIfElse`
- [ ] `testEmitBC` bcMul stale — replace with `*` operator token
- [ ] interpret() build-out: handlers for bcPushField/bcPushLit/bcStoreField
      (registered at setup:137-139; handlers in Bytecode.twk need fixing)
- [ ] `testByteCode` POP: `maximus = 26`

### Findings / decisions banked
- `bcMul` does not exist and never will — multiply handler is `runMultiply` on
  the `*` operator (setup:113); `gXpress` emits `*` token directly.
- Tar 3 (constant folding of `righty * 2`) is moot — `righty` is a runtime field,
  can't fold a variable operand. The multiply reaches the emitter correctly.
- `bcBRZ dst` linkage: `+%` keys attribute as "dst" (field name), matches
  `runBRZ`'s `getAttribute("dst")`. Display artifact in dump — dst is attached.
  Node-identity question (branch target = copy or original?) verify-by-running.
- `bcStoreField` emit is handled in `ruleActions.rtn` generating branch (lines
  304-308), NOT in `gXpress`. `gXpress` sees `bcStoreField` already transformed
  and emits it via `child.registrY == "bcOPs"` branch. Do NOT add `=` branch to
  `gXpress` — dead code.

---

## Tests to be written (Tony's offline list — not a priority queue)

- **assert action** à la groovy — define and test. Low friction, high value.
- **implied field / lastDEF test** — lastDEF in dot-op expression; in FOR loop;
  explicit @field unaryOP to set implied field source. Note: `aCTionNamE()` does
  not currently look in `lastREF` when locate fails and `lastREF` is set — may
  need fixing. `lastREF` scoped within FOR loop, resets on exit — demonstrate that.
- **buffer test** — setMark/unMark interaction; stdout to buffer via `printTO`;
  `printTO` diversion persists across subsequent actions until explicitly undone —
  that persistence is the surprising-to-new-users semantic that needs an example.
- **document text / delimiter test** — see Layer C above. This IS that test.
- **directive test** — probably exists in directives file; verify and polish.
- **delimiter rule / `}{` modifier test** — Layer B is this test, now banked.
- **bin as a switch test** à la generator/runGenerator.

---

## Comment/code shape — iteration 2 (pending, not today)

Scrub inline per-action comments from `generate` file. Lift gist into header
section at top, à la the bytecode explanation. Preserve teaching bits. Treat as
evolving iteration — comment and reality diverge is a first-class smell.
`unitTests` done (2026-06-03). `generate` is next when Phase Bytecode has a
natural pause.

---

## Phase Bytecode findings (2026-05-25 through 2026-06-03)

- [x] **checkSkip sawNewLine gate (2026-06-03, Clod+Tony work)** — year-old
  flakiness: adopt grabbed inter-token whitespace as indent level. One gate
  (`sawNewLine && !lastINDENT`) fixes it. Validated: delim repro, oneTest,
  directives, full testUnitTests POP all green.
- [x] **emitBC `+%→+=` Fix 1 (2026-06-03)** — instructions now land as members
  in bcLIST so `interpretBC`'s `for grup in body; members` loop can walk them.
- [x] **Comment rot Fix 4 (2026-06-03)** — `generate` header §2(a)/(c) and
  `bytecode` header updated to match reality (three data-movement ops now
  registered; bcOPs→Operators fold reverted; `interpretBC` dispatches via
  `grup.interpret` directly).
- [x] **bcLIST copy-back in generateCode (2026-06-03)** — after `runAction`
  completes, copy accumulated instructions from `generator.bcLIST` back to
  `field.bcLIST`. In `Commands.rtn`. Currently inert (source list empty);
  becomes load-bearing or redundant once accumulator fills.
- [x] **gExpressioN killed (2026-06-03)** — not a real thing. `gXpress` is the
  label for ExpressioN nodes, set as exception in `StatemenT` rule action.
  All TODO references removed.
- [x] **members vs attributes gate identified (2026-06-03)** — `emitBC` used
  `+%` (attribute); `interpretBC` walks members. Fix 1 corrects emit side.
- [x] **bcStoreField emit location clarified (2026-06-03)** — built in
  `ruleActions.rtn` generating branch (304-308), not `gXpress`. `gXpress`
  receives already-transformed `bcStoreField` and emits via `bcOPs` branch.
- [x] **Tar 3 moot (2026-06-03)** — `righty` is a runtime field; `righty * 2`
  cannot constant-fold. Multiply reaches emitter correctly. Tar 3 closed.
- [x] **bcOPs registry complete (2026-06-03)** — `bcPushLit`, `bcPushField`,
  `bcStoreField` now registered at `setup:137-139`. `bcMul` intentionally absent
  (multiply is `*` operator via `runMultiply`).
- [x] **Brief 3 verification closed (2026-05-26)** — both root causes of
  cross-test bleed identified and fixed. Full writeup in prior TODO entries.

---

## Closed phases (unchanged)

- [x] Phase Integrate migrations 1+2 (2026-05-16)
- [x] Phase Splice complete (commit ef2730d, 2026-05-09)
- [x] All earlier items

### Earlier

[unchanged]
