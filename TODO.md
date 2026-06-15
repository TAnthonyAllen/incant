# TODO.md — PLG/TAWK/Incant Ecosystem

*Read this first every session. Keep it current.*

*On wakeup: flag any Pre-Session Tasks below that are pending. They are designed for quiet reading/design work before Clod is active — do not let them get buried.*

---

## 🌅 Pre-Session Tasks (Tonto recon / morning design — no build risk)

- [ ] **incant setup command reference** — document the commands registered at startup: what each does, calling convention, where it lives. Wiki candidate. Clay's task. **Now more urgent:** `setMark` and `getMarkLineAt` added 2026-06-15 and need entries.
- [x] **`modedOP.taG` recon** — done. See `docs/modedOP-taG-recon.md`. Bottom line: `.taG` is the parser match key, not a free slot. Alias must live in a sub-attribute (`modedOP.boundTo`), set via `interpret`-child pattern. Runtime rebinding must route through `operateMethod/setOperat` — `=` won't rebind `gOp` (poochifier). Three tar babies documented.
- [ ] **`modedOP.boundTo` alias design** — morning Clay+Tony design pass. Read `docs/modedOP-taG-recon.md` first. Three open questions: is `gText` free on operators; which "alias" we mean (second-name vs current-binding-label); incant syntax for setting `boundTo` at rebind time. Output: a spec for Clod to implement.
- [ ] **`modedOP.boundTo` implementation** — Clod execution task, follows the design pass above. Thin C++ + setup registration, same pattern as `interpret` child on bytecode ops.

---

## Phase Bytecode — current state (2026-06-06)

**🎯🎉 POP LANDED — `testByteCode` → `maximus = 26`.** The bytecode interpreter
runs end to end: parse → emit (clean 9-op bcLIST) → dispatch → handlers → store.
Verified by run, not shape: `maximus = 26`, opStack empty, zero errors.

How it landed (Track A — dispatch in place, NOT via `=`):
- **`runByteFn` primitive** (`GroupActions.rtn`) fetches an op's method-bound
  `interpret` child and invokes its `gMethod` with the op — no copy, sidesteps the
  `=`/setContent method-drop entirely. Registered as command in `incant/setup` (MUST be
  `runByteFn immediateAction=runByteFn;` — the bare no-value form silently fails to bind;
  setRuleAction reads the method name from `item.text`). `interpretBC` (`incant/generate`)
  now does `result = runByteFn(grup)`.
- **`righty`×4 emit bug fixed** (`incant/generate` gXpress): `bcPushField += child; emitBC(
  bcPushField)` mutated the shared registry op and emitted it by reference (all instructions
  aliased one growing list). Replaced with `emitBC(bcPushField=child)` — snapshots the
  field's value as data, mirroring bcPushLit. Each bcPushField now carries its own `=13`.
- **Handlers** (`Bytecode.twk`): runPushField/runPushLit/runMultiply use `copyData` (lift the
  value, not the instruction's structure); runStoreField uses `dest.copyData(value)` directly
  (a bytecode store is a clean data copy — decoupled from opAssign/`=`, immune to the
  empty-source-copies-tag pitfall that produced `maximus = "prod"`).
- The `interpret` child DOES survive the `+=` into bcLIST (the 06-04 "doesn't survive" worry
  was wrong). `dumpField()` added to `GroupItem.twk` as a reusable debug dump (keeper).

### ✅ RESOLVED (2026-06-10): branch execution works in incant — no C++ loop needed

**The 2026-06-09 decision to move the dispatch loop to C++ was overtaken.** After the
unique-label emit (`bcLabel<n>` via `:=` + `labelIndex`) and the `byRef`/`:=` pointer
semantics landed, the cleaned-up **incant** `interpretBC` (`incant/generate`) takes the
branch: `testByteCode` true→26 / **false→11**, `testIfElse`→26/7. The C++ `interpretBC` in
`Bytecode.twk` was **never written and is not needed** — the interpreter stays in incant.
`docs/branch-mechanism.md` is superseded (kept as historical reasoning).

Still done + in the build (keep): `byRef` flag + `:=` pointer semantics (opSetGroup/opAssign/
setGroup), `opDot` reference unwrap (case 401-404 + deref-loop `&& target.group` stop), `gIF`
emit (then+else, **unique labels** `bcLabel<n>`), cond, `runBRZ` retrieval — all verified.

**Next — broaden the bytecode-generation POP:** more statement forms, real field refs vs
folded values, `gPrinT` proper emit (currently a thunk), `gDeclare` verification, test cases
beyond testByteCode/testIfElse.

Remaining cleanup: revert `runByteFn` capture-into-`result` (GroupActions.rtn, behaviorally
identical debug scaffolding). (`oneTest:21` `stop()` already restored.)
- [x] **Move `replaceAt` / `insertAt` + docs into `incant/directives`** — done 2026-06-15.
  Old BlocK-line `:+ DiRFoo` drop-first-line path replaced wholesale. Actions moved verbatim
  (proven), self-contained read-only POP against committed `incant/dirSample`, full usage
  guide + KNOWN LIMITS (non-idempotent; comment-match needs `checkSkip()` change) after stop().
  Runs clean; baseline still 77/77.
- [ ] **Rip obsolete C++ directive methods** — previous directive infrastructure in C++ is
  dead; Clod confirmed benign. Remove in cleanup pass. **DEFERRED per Clay** — hold until the
  new incant directives are fully bedded in.
- [x] **`incant/directives` POP pattern** — done 2026-06-15. Documented in the directives
  file: copy target into `Groups/Tests/` (real copy, not symlink — Tests/ is gitignored
  scratch), getFile/apply/closeFile, diff copy against original. The in-file POP is read-only
  (no closeFile) so it never touches the committed sample.
- [ ] **AUDIT (after bytecode stabilizes) — sticky `byRef` aliasing** — `byRef` is left set
  and never cleared, so any field ever passed as the argument of `:=` references-on-`=`
  forever (opAssign honors it). Fine while nothing else reads the flag, but audit existing
  `:=` sites for fields that later get legitimately `=`-copied — those would now alias.
  Clay's flag, not today's problem; don't let it get buried.

**Next (post-POP):**
- **Track B — `=` semantics / divineIntent.** `opAssign`/`setContent` redesign: `=` means
  data copy; explicit operators for structure/reference/clone-with-method. Design-first
  (Clay + Tony). See divineIntent summary. opAssign untouched pending the vocabulary spec.
- Bytecode handlers beyond the POP path (other ops, real field references vs folded values).
- Dead `incant/bytecode` copy — salvage doc header, then delete.

**Earlier plan (for history): `docs/bytecode-dispatch-plan.md`.**

---

## Parse error handling + divineIntent prep (2026-06-06 PM)

**Committed (dormant infrastructure — prep for divineIntent):**
- `aCTionFailed` (`ruleActions.rtn`) upgraded from a one-line text dump to a structured
  report: line, 40-char offending-text window, last-parsed hint. **Still dormant** — no
  `Failed` catch-all rule is wired, so it never fires yet. Recon finding: the parser
  *backtracks silently* and the top-level `strap.parse(0)` result is unchecked, so parse
  errors currently produce NOTHING. Wiring a `Failed` catch-all as the last `StatemenT`
  alternative is the hook — bear-trap caveat: its guard must exclude `}` / `;` / EOF or it
  false-positives at every block close. (NOTE: a `Failed`-in-StatemenT catches incant
  statement errors but NOT JSON failures — JSON parses via a different path.)
- `lastStatement` marker (`GroupRules` field, set in `aCTionStatemenT`'s `!processingCode`
  branch on confirmed top-level statement execution; read by `aCTionFailed`). Survives
  backtracking, unlike `ruleSTUFF.label`. Top-level granularity only; in-block is a future
  refinement. Commits: `d2e69fa`, `d17b26b` (Groups) + `e783750` (Include/groups.ext).

## JSON grammar — diagnosis done, fold pending (2026-06-06 PM, Tony's WIP)

Goal: make `JSONlist` return a usable data tree (the isCLAUDE response-parser bridge).
**Capture bug fully diagnosed — two causes:**
1. **setLabel wrote to the wrong RuleStuff.** `code={ ...; setLabel(QuotE); }` runs inside a
   BlocK frame, so global `ruleSTUFF` is the BlocK's, not QuotE's. Fix (validated in Xcode):
   `RuleStuff ruleStuff = rStuff;` (QuotE's own) instead of `= ruleSTUFF`. After this,
   `JSONfield succeeded label: QuotE=main` — field keying works.
2. **`aCTionRunRulE` drops the rule result.** On the isRule path it does
   `rule = runRule(argument, rule); return input;` — `input` was `clear()`'d, so the JSONlist
   result (which DOES hold the field list) is thrown away. The comment says "returns the rule
   result" but it only does so on the `!isRule` branch.

**Plan (Tony doing the fold at own pace):** rather than fix the hot `aCTionRunRulE` return,
fold the JSON rules (JSONarray/JSONlist/JSONvalue/JSONfield) from `incant/utilities` (Utilities
registry) back into `incant/grammar` (Grokking) and parse JSON **under Start** — Start's
`parse()` accumulates onto `parentLabel` correctly and never hits the leaky invocation path.
Open question: the entry trigger (how a oneTest line gets parsed as JSON vs incant — `{...}`
collides with BlocK). Then the test is a oneTest line + `dumpField`/`dumpContents` on the result.
**Also still open (recon):** JSON coverage gaps — numbers (`JSONvalue → GrouP = NamE|QuotE`, no
NumbeR), array element commas (`JSONarray` has no separator), string escapes (`QuotE` `upTo`
truncates at `\"` — needs a JSONstring rule: grammar `(escape|normal)*` for delimiting + action
to resolve). Empty `{}` is valid/expected (keep `*` not `+`).

**Uncommitted WIP (Tony's):** `Commands.rtn` (setLabel `rStuff`), `GroupRules.mm` (regen),
`incant/utilities` (JSONlist field-label dropped), `incant/jsonTest` (untracked scratch repro).

Today's arc (resolved the 06-04 blocker, then dug to the real one):
- **06-04 blocker resolved.** `bcPushField` had an empty groupList because gXpress did
  `bcPushField = bcPushField += child` — the `=` ran self-`setContent` and clobbered the list.
  Dropped the `=` → list retained → "no handler" gone. (Not addMember; the copy-ctor *shares*
  the body. The addMember chase was a wrong lead.)
- **Real blocker found.** `interpret=runX` never bound the handler — `interpret` was not a
  registered command, so the bare token was stored as a **string** → all 9 ops `method=0`,
  nothing ever dispatched. The bytecode interpreter had never executed an op. Not a regression,
  unfinished wiring.
- **Binder built and WORKING.** `interpretMethod` command (GroupMain bootCommands, below
  operateMethod) + binder in `GroupActions.rtn` (alpha-slot fAIL↔loadRegistryFromString).
  It creates a persistent `interpret` child on the op and `setMethod`s the dlsym'd handler.
  Registry flipped to `interpretMethod=runX` (`incant/setup`). Confirmed: ops carry a
  method-bound `interpret` child.
- **Final blocker (the poochifier).** interpretBC can't *invoke* the bound child from incant:
  `handler = grup.interpret` → `=`/`setContent` copies data+lists but **not the method**;
  chained `grup.interpret(grup)` parse-fails; `:=` wrapper doesn't dispatch.

**Resume tomorrow** (per the plan doc): two paths, lean toward **Path B (fix the poochifier)** —
make `setContent` carry the method binding (Tony's constraint: don't bloat setContent's hot
path; parameterize `contents()` default-preserving; decide the **(a) gated-in-setContent vs
(b) separate method-aware copy** fork). If B sweeps clean, `maximus = 26` falls out and the
wart's gone. **Path A (gByteFn slot)** is the targeted fallback. Both fully spec'd in the doc.

**Other open threads (parked):**
- **The poochifier itself** — `setContent`/`=` silently drop `gMethod`/`gOp`. The root wart;
  Path B fixes it. See [[setcontent-ignores-methods]] memory.
- **`righty`×4 on bcPushField** — bare `bcPushField += child` mutates the *shared* virtual
  registry op, accumulating the operand across emits. Independent of dispatch; fix after.
- **`Token=0`/`Token=2` literals Token-wrapped in revisedList** — `child.isLiteraL` in gXpress
  isn't catching them. Fix after dispatch.
- **`testIfElse` else branch emits nothing** (gIF:274). Parked.
- **`generateSignature` not closing** — cosmetic, parked.
- Dead `incant/bytecode` copy — salvage its doc header, then delete. `dumpField` shipped to
  `Utilities` (keeper). interpretBC debug scaffolding stripped.

**What landed today (2026-06-04):**
- Aisle 3 clean: `delimTest` and `directives` reorganized with unitTests-style headers.
  Two bugs surfaced and documented honestly (directive content-match broken on BlocK-line
  path; `getFile` parses what it loads — `pushInput` cascade). Tony owns debugging in Xcode.
- `opPlusEQ` list-append fix: promoted `or target.binType || target.groupList` branch above
  `or argument.data` so list-shaped targets take the append path immediately.
- `setPointer` / `opPointer` chain: `bcPushField` now carries `isPointer` at definition via
  `setPointer immediateAction=opPointer noPrint` in setup bcOPs block. `copyOf` carries it
  through virtual copies via `*groupBody = *grup.groupBody`.
- `copyOf` revised: skips `copyListTo` for virtual sources (shared list by pointer is correct;
  deep copy was overwriting with empty list). Load-bearing design constraint documented:
  virtual instance lists are read-only shared references, never modify at runtime.
  `isVirtual` cleared on copy (`isVirtual = false` after `*groupBody` copy).
- `aCTionTokenXP` bare-field-ref fix: generating branch now sets `xpress.group = ANYtoken`
  for simple field operands, mirroring non-generating path. Operator guard added:
  `if grup.isGROUP && !grup.isOperator` prevents dismembering operators (their `length 1`
  is `interpret=runGT` etc. — load-bearing, not a wrapper).
- `generateCode` bcLIST groupList allocation: `new GroupList(bcLIST)` before `+%` / replace
  so first `+=` takes the list-append branch not copyData.
- `generateCode` copy-back removed: `accumulated` and `fieldList` were the same slot after
  `replace()`; `copyListTo` was walking a list into itself (walkabout). Copy-back block
  removed; `generateCode` returns `fieldList`.
- `generateAction` argument naming fix: incant action parameters must be named `argument`;
  `action` was silently empty. Fixed throughout `generateAction`.
- `interpretBC` wired into `generate` for testing (copied from `bytecode` file, `code=` added).
- `generateAction(testByteCode)` wired into `oneTest`.
- `testEmitBC` retired (called unregistered `bcMul`).
- `=*` / `opPointer` landed as new unary-style operator for isPointer marking.
  `setPointer` command is the cleaner definition-time path; `=*` remains available for
  use-time marking when needed.
- New `GroupList()` constructor added (was missing; existing constructor only created list
  on attribute-add).

**Uncommitted working tree (ready to commit — debug directives cleared from GroupRules.mm/GroupItem.mm via no-directive re-tok):**
- `Commands.rtn` — copyOf clears isVirtual on copy
- `Instruct.rtn` — opPointer fLAG-redirect (=* and setPointer)
- `incant/setup` — setPointer command + bcPushField setPointer
- `incant/generate` — gXpress cleanup, interpretBC, generateAction fixes
- `incant/bytecode` — Brief-5 comment de-staling + interpretBC
- `incant/oneTest` — generateAction(testByteCode) wired in
- `ruleActions.rtn` — bare-field-ref fix (operand baring + operator-skip guard)
- `GroupRules.mm` / `GroupRules.h` — re-tok'd clean (no directives) from the .rtn changes above
- `GroupItem.twk` / `GroupItem.mm` — copyOf revision
- `GroupList.twk` / `GroupList.mm` — default constructor added

**Language design findings banked today:**
- `opPlusEQ` branches on target state, not argument type — list-shaped target must be
  checked before data-copy branches or GroupItem arguments with no data fall through to
  the error case.
- Virtual copies share groupList by pointer via `*groupBody = *grup.groupBody`. `copyListTo`
  after this overwrites with empty list — skip for virtuals.
- `setPointer` / `opPointer` / `fLAG` pattern is the canonical way to set a flag at field
  definition time (noPrint + immediateAction, fLAG redirects to parent field).
- `:=` passes by value; changes to the left-hand side inside the op don't persist to caller.
  `=*` / isPointer is the mechanism to prevent runOP unwrapping.
- incant action parameters must literally be named `argument` — any other name silently
  receives empty values (cousin of the emitBC `operand` bug from 2026-05-26).

**Directive bugs (Tony's Xcode seat, not blocking bytecode):**
- BlocK-line path content-match broken: `statementMatches` / `matchSpanInLines` suspected.
  Both replace and delete directives drop the target block's first line regardless of content.
  Text-substrate path (DiRSwapInt) does content-match correctly — break is specific to
  BlocK-line path.
- `getFile` parses what it loads: `pushInput(filing)` at Commands.rtn `getFile` queues loaded
  file as incant input, triggering parse of `include <path>` first line → directory error.
  Fix likely needs a load-without-parse variant or a suppress-parse flag on `getFile`.

---

## Tomorrow's wake-up

**State:** bcLIST is a clean 9-op list. `interpretBC` runs but dispatch is silent because
`interpret=runPushField` doesn't survive the `+=` copy into bcLIST. First move: breakpoint
in `addMember`, trace the copy path, find where the groupList gets lost.

**After dispatch unblocked:** slot-name reconciliation in handlers.
- `runPushField` calls `value.setContent(instr)` — needs to find `righty` on the instruction.
  The instruction currently shows `content= bcPushField` (tag name, not field reference).
- `runStoreField` calls `instr.getAttribute("target")` — destination key may not match
  what `gXpress` emits.
These are Xcode-debugger findings — break in each handler, see what's on `instr`.

**POP sequence for testByteCode:**
1. `addMember` copy fix → `interpret=runPushField` survives into bcLIST
2. Run → `runPushField` fires
3. Slot-name reconciliation (what `righty` is on the instruction; what `runStoreField` reads)
4. `maximus = 26`, `opStack` empty at end — POP

**Reading targets (upload at session start):**
- `Groups/incant/generate`
- `Groups/incant/oneTest`
- `Groups/incant/bytecode`
- `Groups/incant/setup`
- `Groups/Commands.rtn`
- `Groups/Instruct.rtn`
- `Groups/ruleActions.rtn`
- `Groups/Bytecode.twk`

---

## Directive work — parked pending Xcode debug

Per offline status report 2026-06-04: directives and delimTest reorganized (aisle 3 clean).
Two bugs documented in `directives` header. Tony debugs in Xcode at own pace; not blocking
bytecode arc.

**getFile bug:** `new(path)` vs plain assignment was investigated and ruled out as root cause.
Same error either way. `pushInput` in `getFile` is the likely root — loads file and queues as
incant input unconditionally. Fix: load-without-parse variant or suppress-parse flag.

**Directive content-match bug:** BlocK-line path drops first line positionally; from/to refs
don't drive match. Text-substrate path works. `statementMatches` / `matchSpanInLines` in
`Instruct.rtn` are the suspects.

---

## Phase Generate Tawk — BLOCKER (parked, not current arc)

**🚧 generateRules class-body/extern split.** `plg Tawk.g → Tawk.twk` runs clean but output
does not tok: generateRules dumps class field declarations at file scope. tok → `ERROR
Inheritance`. Fix: split class-body material from extern bodies. Full writeup in
projectBible.md "Phase Generate Tawk".

---

## Reentrancy arc — three layers

- [x] **Layer 1: Sequential generateCode calls.** Cleared 2026-05-26.
- [ ] **Layer 2: Mutual recursion (A→B→A).** Stak-based call-stack design sketched, not implemented.
- [ ] **Layer 3: Hot-patching currently-running actions.** Gates directive feature B. HPDL.

---

## Pending (not current arc)

- [ ] **Sticky `isPRINTING` root-cause fix (Option B)** — `isPRINTING` is set true at
  `Commands.rtn:398` (`case 'P'`) and only reset in `aCTionPrinT`'s non-generating loop
  (`ruleActions.rtn:554`), so on a print-less generate it stays true and bled into condition
  generation. Today's fix (2026-06-14) removed the `&& !isPRINTING` guard from
  `aCTionExpressioN:280` (the `aCTionTokenXP:743` guard alone protects the print thunk —
  verified via the unit-test golden). Proper fix: scope `isPRINTING` to the print emission
  (clear before / set local), then re-evaluate whether any gate is needed. Also revisit the
  one remaining un-guarded `if generating` at `aCTionPrinT:537`.
- [ ] **Dead `nextChild` in `gXpress`** — `incant/generate` gXpress computes
  `nextChild = child.nexT;` and never uses it (present since c632421, never an active reorder;
  the reorder lives in `aCTionExpressioN`'s generating branch). Remove in cleanup.
- [ ] **Print: real operand compilation (Track B)** — emit operands as push ops via `gXpress`
  so print is true bytecode, not the current thunk. Needs the operand revisedLists populated in
  gen mode (the no-op `aCTionExpressioN` case currently leaves them intact for interpretation).
- [ ] **Print: FormaT survival + operand count on `bcPrint`** — for the real-bytecode path,
  FormaT must ride to the consumer (`copyData` drops it) and `bcPrint` needs an operand count.
  The thunk sidesteps both (fires `aCTionPrinT`, which walks `stuff` directly).
- [ ] **Print: complex print lines** — operators+operands mixed, formats, shortcuts interleaved,
  multiple `PrintXP`: order/handling UNVERIFIED. `reversePrint`-forward only covers bare operand seqs.
- [ ] **Print: `runString` fixture** — wire a StringXP test; verify the value lands on opStack.
- [ ] **Dead `aCTionPrinT` gen branch** — kept only so codegen keeps `stuff:`→`input`; remove in cleanup.
- [ ] **grammarOnTheFly write-2: source a file's own text without re-parsing it** —
  OPEN QUESTION (named, parked 2026-06-07). The demo's real second write is
  grammarOnTheFly's *own* text (prepend the captured comment to the file =
  `insertBefore`). But `getFile` reads AND parses (`pushInput`) what it loads, so
  loading the file re-executes it. Needs a load-without-parse path (cf. the
  `getFile` suppress-parse item under Directive work). Full context:
  `docs/grammarOnTheFly-findings.md`.
- [ ] **grammarOnTheFly cleanup (next session)** — strip scaffolding (M1/M2/M3,
  WRITE-2 placeholder, `dumpContents`) back to clean `oneTest` shape; rewrite the
  payload comments to match reality (keeping the no-literal-`#)` constraint); slot
  what was built into the wiki piece. One clean rebuild pending to bind
  `flushBuffer` (zero-error startup). See `docs/grammarOnTheFly-findings.md`.
- [ ] **printTO / opPrint buffer-diversion unit test** — confirmed working, no test
  exists. Add one (`docs/grammarOnTheFly-findings.md`).
- [ ] **Tar 5: gXpress operator-asymmetry** — moot per 2026-06-04 verification. ruleActions
  pre-transforms `=` → `bcStoreField`; gXpress never sees `=` or tgt token. Dead code if added.
  TODO entry closed.
- [ ] **testIfElse else branch** — `runGenerated(el)` at gIF:274 emits nothing. Parked.
- [ ] **generateSignature closing paren** — cosmetic, parked.
- [ ] **tok: fnptr cast with reference param (`FormatC.twk`)** — tok drops the `&` when rendering a
  function-pointer type inside a *cast expression*, emitting malformed `(GroupItem*(*)(GroupItem*,))`.
  Renders `GroupItem*&` fine in *declarations*; only casts break. Surfaced by the gOp by-ref change
  (2026-06-05), worked around with a `-% … %-` CodePass inside `setOperat`. Real fix: teach
  `FormatC.twk` to render reference params in fnptr casts — then revise `setOperat` back to typed
  `void setOperat(GroupItem &m(GroupItem,GroupItem&)){ operat = m; }` and drop the passthrough.
  Latent: resurfaces for any by-ref fnptr field.
- [ ] **incant-idioms.md v0** — substantial accumulation now. Draft when bytecode arc closes.
- [ ] **Bytecode.mm rewrite into tok** — after Phase Bytecode current arc closes.
- [ ] **bcOPs-fold-into-opFields** — deferred, design at `Groups/docs/bcOPs-fold-design.md`.
- [ ] **Print bytecode plan document** — `Groups/docs/printGenerationPlan.md`.
- [ ] **`=:` operator grammar-change design** — parked.
- [ ] **Wiki weekly refinement.**
- [ ] **Tawk.twk migration arc** — 587 sites.
- [ ] **Bible refresh** — minor sync passes after major arcs settle.
- [ ] **argument[N] on +=-stored children** — Q3 of Brief 3 findings. Parked.
- [ ] **emitBC parameter naming convention** — CLAUDE.md note pending.
- [ ] **Brief 2 verification lesson** — bible Working Relationship entry pending.
- [ ] **Three-way if/or/or chain test** — durable regression test pending in unitTests.
- [ ] **incant field semantics bible entry** — `=` vs `:=`, pointer-storage vs value-semantics.
- [ ] **Clay/Clod lane division** — Xcode debugger is Tony's seat. Bible note pending.
- [ ] **HWF graduation ritual for Sessions 4 and 5** — pending.
- [ ] **Session 9 follow-up items** — small, interleave.

---

## Phase Integrate — extended (parked)

- [ ] TAWK autopsy remainder
- [ ] Scoped TAWK autopsy: GC inheritance fix, include guard fix

---

## 🔭 Longer Term (HPDL)

- [ ] Claude as native GroupItem field type (`isCLAUDE`)
- [ ] Incant as distributed virtual OS
- [ ] Go-style channel messaging
- [ ] ZFS-flavored storage
- [ ] Incant display/layout field
- [ ] File system as GroupItems
- [ ] PLG written in Incant
- [ ] Incant self-hosting via JIT — Phase JIT
- [ ] Xcode-like development environment written in incant

---

## 🗂️ Housekeeping

- [ ] **`string` keyword is on the chopping block — gIF's label mint depends on it.** `gIF` mints unique bytecode labels with `string "bcLabel" labelIndex` (`incant/generate`), works today (2026-06-10). The bible flags wanting to *eliminate* the `string` keyword (declaration-context concat — `String x = "a" var "b";` lowering to `concat(...)` — is the target model). If/when `string` goes, that mint site must move to the no-keyword concat form. Future flag, not urgent.
- [ ] plg.g `%%` assumption — document/fix
- [ ] doNotGuard accumulation
- [ ] +1000 offset reporting quirk
- [ ] ~/bin/plg dated Nov 2024 — verify or rebuild
- [ ] Support repo update process — needs a look
- [ ] Move Groups/GUI/ to Reference/ sibling
- [ ] Move Groups/Maps/ to support source
- [ ] Accumulated working-tree drift sort: GroupDraw (76 lines), GroupControl (2), GroupItem (3), Stylish (2)
- [ ] **Xcode-update discipline:** Clean Build Folder before debugging weird runtime behavior.
- [ ] **Visibility-gap discipline:** source-of-truth files MUST live in tracked locations.
- [ ] **Tests/ just-in-case stash** — Parse/Tests/ mostly dangling symlinks post-flatten.
- [ ] **PLGset.init() stub** — dead code, retained for API compatibility. Remove in cleanup pass.
- [ ] **TOK Xcode project yaml** — no project.yml. Reverse-engineer from .pbxproj. Rename target incantGUI → incant.
- [ ] **plg xcode link cleanup + yaml refresh** — post-flatten cosmetic work.
- [ ] **projectBible.md directory map** — update to reflect unitTests relocation.


---

## ✅ Done

### 2026-06-15

- [x] **`replaceAt` / `insertAt` directive actions** — text replace and before/after line
  insert. Better than tok directives: mid-line match, arbitrary block size, large block
  replace/insert. Non-idempotent (see Bear Traps). Tested via `dIRECTive1/2/3` fixtures in
  `IncantForms/Windows/tabs`. POP: verified working during offline development.
- [x] **`NamE` rule `^` noSkip fix** — missing `^` modifier in `nameSet` was silently
  consuming two-word names (`x code` parsed as one name). Fix: `NamE first-=[a-zA-Z] nameSet-^* tokenize;`
- [x] **`getFile` / `atLINE` fix** — `getFile` was setting `atLINE` on non-action files.
  Removed from `getFile`; `atLINE` now set correctly in `processCode` as a `noPrint`
  attribute of an action. `pushInput` also removed from `getFile`; `loadInputFromFile`
  adjusted accordingly.
- [x] **`setMark` promoted to accessible incant command; `getMarkLineAt` added** — returns
  the line containing the buffer mark. Both in `Instruct.rtn`.
- [x] **`Buffer.twk`** — `appendString` / `appendChar` formatted variants + new
  `shiftAtMark`. Hammered hard during directive development; held up well.
- [x] **Full-monty POP clean** — 77/77 unit tests match golden; `testByteCode`→11,
  `testIfElse`→26 (both branch directions); `replaceAt`/`insertAt` trace verified. Committed
  `101fb5c`.

### 2026-06-08

- [x] **Print POP — `testPrint` → `hello world` through the bytecode path.** Verified by run.
  Pragmatic "thunk" (Clay+Tony agreed): print is *interpreted*, not compiled to operand
  bytecode — `runPrint` fires `aCTionPrinT` on the statement; operands NOT emitted as push
  ops. Slightly slower print; does NOT disturb the JIT's IR shape — real operand compilation
  deferred. How it landed:
  - **`gPrinT`** (`incant/generate`) — passthrough: `op = copyOf(bcOPs["bcPrint"]); op +%
    argument; emitBC(op)`. One `bcPrint` carrying the print statement at `[2]`.
  - **`runPrint`** (`Bytecode.twk`) — `aCTionPrinT(instr[2])` (runOP unwrapping pooched it;
    `runString` parallel passthrough, UNTESTED).
  - **`aCTionExpressioN` no-op fix** (`ruleActions.rtn`) — the RPN gen-walk emitted nothing for
    operator-less expressions (`"hello" name`), then `clear()` destroyed the tokens → empty
    revisedList. Now: no-operator → leave `xpList` intact, set `isLIST` + `reversePrint`, return.
  - **`reversePrint` flag** (GroupBody, NEW) — `appendGroup` walks the flagged list forward
    (`next`) vs its default reverse (`prior`). `fLAG` crashes `addGroup` on a parse node;
    `generating` pooches `aCTionExpressioN`'s gen guard. Dedicated flag was the clean answer.
  - **tok caveat (cost hours):** `//` comments in `.rtn` method bodies cascade field-resolution
    bleed across following functions (`stuff:`→`tgt`/`targetLines`, undefined-symbol errors).
    Keep them out of method bodies. Also: changing GroupBody flags requires re-tok'ing every class.

### 2026-06-05

- [x] **gOp pass-by-reference — operator `target` now by-ref.** Op methods that do structural work on
  `target` and `return target` no longer lose it to the value-copy (the bug that kept poking the
  generator work). Gates A+B+C, one commit, full unit-test sweep clean (byte-identical across runs):
  `gOp` pointer + all 29 `operateMethod` operators (`Instruct.rtn`) + 3 directive delegates
  (`applyDirectives`/`applyTextDirective`/`replaceDirective`, `GroupActions.rtn`) all take
  `GroupItem &target`. `setOperat` reshaped to `void setOperat(void *m)`; dlsym binding goes through an
  explicit `setOperat(dlsym(name))` call with the one unavoidable cast in a `-% … %-` CodePass inside
  the body (tok can't render the by-ref fnptr cast — see Pending/`FormatC.twk`). Recon + full writeup:
  `docs/gOp-byref-recon.md`. `groups.ext` (in `support/Include/`) committed separately. `gMethod` and
  the non-operator return-target methods (`loadDirectory`/`setInternalType`/`makeDataType`) left for a
  later pass — not on the gOp path.

### 2026-06-04

- [x] **Aisle 3 clean** — `delimTest` and `directives` reorganized with unitTests-style headers.
  Two bugs surfaced and documented: directive content-match broken on BlocK-line path;
  getFile parses what it loads. delimTest: comment-only cleanup, output verified identical
  to baseline. Layer C headline (live DatA mutation) and run-order constraint documented.
- [x] **`opPlusEQ` list-append fix** — promoted `or target.binType || target.groupList` branch
  above `or argument.data`. List-shaped targets now take append path regardless of argument type.
- [x] **`setPointer` / `opPointer` chain** — `bcPushField` carries `isPointer` at definition.
  `copyOf` carries it through virtual copies. `=*` available as use-time operator.
- [x] **`copyOf` virtual-copy revision** — skips `copyListTo` for virtual sources; clears
  `isVirtual` on copy. Load-bearing constraint: virtual instance lists are read-only shared
  references.
- [x] **`aCTionTokenXP` bare-field-ref fix** — operand baring + explicit operator-skip guard
  (`!isOperator`) in generating branch.
- [x] **`generateCode` bcLIST groupList allocation** — `new GroupList(bcLIST)` before first `+=`.
- [x] **`generateCode` copy-back removed** — `accumulated` and `fieldList` were same slot;
  `copyListTo` was walking list into itself.
- [x] **`generateAction` argument naming fix** — parameter renamed from `action` to `argument`.
- [x] **`interpretBC` wired into `generate`** — copied from bytecode file, `code=` added.
- [x] **`generateAction(testByteCode)` wired into `oneTest`.**
- [x] **`testEmitBC` retired** — called unregistered `bcMul`.
- [x] **New `GroupList()` constructor added.**

### 2026-05-28 through 2026-06-03

- [x] **Incant directives: replace + delete on AST substrate (2026-05-28 PM)**
- [x] **Text-substrate directive design landed (2026-05-28 PM)**
- [x] **GroupRules.twk restored as source of truth (2026-05-28)**
- [x] **DatA live grammar mutation (Layer C) complete and passing** — `DatA += DelimText;
  guard(DatA)` grafts new alternative at runtime; live parser picks it up immediately.
  guardSet scrub + guarding flag reset both required. `>#` → `)#` delimiter fix (checkSkip
  interaction). Run-order constraint documented: Layer B deferred after Layer C move 3.
- [x] **checkSkip `indenting` fix (2026-06-03)** — was counting inter-token whitespace instead
  of only post-newline whitespace. `sawNewLine && !lastINDENT` gate resolved it.

### Earlier 2026-05

- [x] **Brief 3 verification closed (2026-05-26)**
- [x] **runOP isPointer guard (2026-05-26)**
- [x] **Per-action tempField via aCTionDefinE + pointer redirect (2026-05-26)**
- [x] **getText Stak handling + dumpText polish (2026-05-26)**
- [x] **replace() actual-swap fix (2026-05-26)**
- [x] **`&` modifier on gXpress signature parameters (2026-05-26)**
- [x] **Phase Bytecode major progress 2026-05-24/25 evening** (five findings)
- [x] **gXpress simplified and tested (2026-05-24)**
- [x] **ElsE forward-reference grammar fix (2026-05-22)**
- [x] **opDot late-binding unwrap removed (2026-05-22)**
- [x] **Three incant-machinery investigations resolved (2026-05-22)**
- [x] **Incant unit-test suite passing (2026-05-16)**
- [x] **Phase Generate Tawk done items (2026-05-30)**
- [x] **Phase Integrate migrations 1 and 2 (2026-05-16)**
- [x] **checkSkip double-define bug fixed (2026-05-15)**
- [x] **Bible v2 + jit.md mirrored (2026-05-15)**
- [x] **PLGmain split from PLGparse (2026-05-15)**
- [x] **plg directory flatten (2026-05-14)**
- [x] **CodE/DatA parseAction approach (2026-05-14)**
- [x] **PLGset migrated to support/Frame (2026-05-14)**

### Earlier

[unchanged]
