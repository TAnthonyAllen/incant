# Incant — Status & Handoff (2026-07-02: kitchen clean, 5 recons landed, Tony on hibernation for ~1 month)
*Written by Clod for a fresh Clay/Clod with ZERO memory of today. Self-contained. Tony leaves for
~a month starting 2026-07-03 — assume nothing survives except this file, the commits, and the docs
it points to. Read this fully before touching code.*

## What happened today (headline)
Tony rewrote `Layout.twk`/`Stylish.twk` as a simplification pass, then a three-way exchange (Tony's
offline status report → Clay's `guiDesign.md`/`jitFullmontyPlan.md`/`webchannelAttack.md` design docs
→ Fearless marching orders) drove a full day of parallel execution: kitchen-clean, 3 real bug fixes,
5 minion recon docs, and this refresh. **Nothing is fully "done" — everything below is a thread at a
specific point, most with an explicit next step.** Read the per-thread status before assuming.

## Today's commits (branch `jit-unified-emit-wip`, on top of `c2aa18e`)
```
b8e47a2  Preserve today's design docs + recon into the repo
4532414  M2 steps 2-4: setFont on the NSFontDescriptor path, smallCaps, getFont
1dc4f7c  M3: jsonTest Google-Fonts probe - array-of-objects chokes, plus a masking bug
0136028  M1: fix setColor white-render bug (rgbColor needs 0.0-1.0, was getting 0-255)
0e091ac  Fold in 4 localized guiDesign.md review fixes (kitchen-clean §1)
dae8ec9  Layout/Stylish simplification pass + dedup blockContaining/indent link collision
```
All verified against the same baseline before each commit: full workspace build succeeds,
`oneTest` → `maximus = 26`, `jitGifScratch` → taken=99/not-taken=11. No regressions across the day.

## Doc map — READ THESE, don't re-derive
Design docs (Clay, copied from `~/Downloads` into the repo today so they survive the month):
- **`docs/guiDesign.md`** — Layout/Stylish review, fonts/colors transition design, event cha-cha +
  display cha-cha design. The big one. §0 amendment (below) supersedes its §1.
- **`docs/jitFullmontyPlan.md`** — JIT plan from the gIF-done pivot to full control-flow coverage.
  Its §3 coverage table was a placeholder pending `docs/jit-coverage-recon.md` — **that recon landed
  today and contradicts one of this plan's assumptions** (see JIT thread below).
- **`docs/webchannelAttack.md`** — webChannel plan of attack (HTTP subset, single-threaded pump,
  `setSocketOp`/BotClient-shape). **Partially contradicted by today's recon** (see webChannel thread).

Recon docs (Clod/minions, written today):
- **`docs/jit-coverage-recon.md`** — every opMethod in `Instruct.rtn` categorized HAS-gate/NEEDS-gate/
  NEEDS-modification, plus the FOR/DO/WHILE structural finding. **Highest-value unread doc if you
  only read one** — Clay was explicitly blocked on this.
- **`docs/setWindow-plan.md`** — oldGUI window/panel/popup recon + try-and-buy plan for the
  `GroupDraw.twk` `setWindow` stub.
- **`docs/webchannel-step0-recon.md`** — runloop recon + pushback on `webchannelAttack.md`'s
  assumptions (setFileOp analogy, BotClient salvage, runloop hookup).
- **`docs/jsonTest-googlefonts-probe.md`** — where the JSON parser chokes on real Google-Fonts shape.

## Thread-by-thread status

### 1. Layout/Stylish kitchen-clean — GREEN, baseline for everything else
Tony's rewrite + today's fixes are committed and build clean (`dae8ec9`, `0e091ac`). Fixed:
duplicate-symbol link collisions (`blockContaining` in both `GroupDraw.twk`/`Stylish.twk` — kept
Stylish's; `indent`/`indentWH` renamed to `indentFrame`/`indentFrameWH`, collided with shared support
`StringRoutines.C`'s unrelated debug `indent()` at `extern "C"` linkage — see new bear-trap #12);
`Stylish.mm` was stale vs `Stylish.twk` (setFont's old mask init) — retok fixed it; `getColor`
null-guard; `displayText`'s never-constructed editor (was caching a permanent nil); `setColor`'s
confusingly-swapped variable names (value was already correct, now the code reads correctly too);
`viewDidEndLiveResize` now calls `mustDisplay(true)` instead of `drawRect(frame)` directly.
**Not done**: `displayPath()`, event handling (design exists now — `guiDesign.md` §7 — not built),
font handling was partially done today (see fonts thread). P1/P2/P3 tok-semantics questions (switch
fallthrough, bare `x`/`y`/`selectable` resolution) all answered clean from generated code — **no bugs
found, no fixes needed** (details below, "tok-semantics POPs").

### 2. Bear #1 (Stylish shared-vs-per-field state) — RESOLVED, not yet implemented
Tony's amendment to `guiDesign.md` §1 (relayed via Fearless): option A, smaller footprint than the
brief proposed. `subbed` → **DELETE** (reconcile pass + non-null object slot makes it redundant).
`selected` → becomes a plain attribute on the field's GroupItem (event handler sets/clears it,
reconcile reads it). `editable`/`selectable`/`shadow`/`shadowField` **stay on Stylish** (genuinely
style-like, not per-instance). Zero GroupBody changes needed. **This unblocks `resolveStyle`
(`guiDesign.md` §2) — nobody has built it yet.** Next concrete step for whoever picks this up: build
`resolveStyle` per §2's walk-the-styleDef-attributes spec, now that the shared/per-field split is
decided.

### 3. Colors (M1) — fix landed, live-render POP NOT completed
`setColor` was rendering everything near-white: `rgbColor(...)` is a raw **tok compiler keyword**
(not an editable wrapper — confirmed by reading the generated `[NSColor colorWithCalibratedRed:...]`
call) that takes 0.0–1.0 components; `setColor` was passing raw 0–255 hex bytes, which clamp to 1.0.
Fixed at the one live call site (`0136028`): each channel now divides by `255.0`. Verified via
generated code (`Stylish.mm` now reads `.../255.0` in the right order) — **not verified via an actual
rendered color**, because a hand-built `dumpColorRGB` POP segfaulted on a global `properties["hexSet"]`
dependency inside `setColor` that a minimal test bootstrap didn't satisfy (bear-trap territory, not
chased — see bear-trap #15). `dumpColorRGB(GroupItem)` extern exists in `Stylish.twk` as a ready POP
tool once someone wires a properly-registry-sourced field. **Next**: complete the live POP (should be
~10 min for someone who knows the top-level script/action idiom — see bear-trap #15), then colors are
DONE pending `resolveStyle` wiring (thread #2).

### 4. Fonts (M2) — steps 2-4 done, live-render POP NOT completed, steps 5-6 not started
`setFont` was a **confirmed triple no-op** on bold/italic (mask computed via `&=` against a
zero-initialized int, then never applied to the font at all — `titleFont ... bold` rendered as
regular Palatino). Rewritten (`4532414`) on the `NSFontDescriptor` path per `guiDesign.md` §5.2-5.3:
family + symbolic bold/italic traits + smallCaps via font-feature-settings (not a trait — a separate
Apple mechanism, confirmed the old approach could never have handled it) + fallback chain
(descriptor→fontWithName→systemFontOfSize, logs each failure, never returns null) + size defaults to
12.0. Added `getFont(GroupItem)` lazy/symmetric to `getColor`. Added `dumpFontInfo(GroupItem)` POP
tool. **Same as colors**: code-level verified (compiles clean, textbook Apple API usage), live POP not
completed — three attempts at hand-building a test GroupItem from a bare top-level script hit
"`RunRulE: expected a method not <name>`" (bear-trap #15, unresolved invocation-grammar question).
**Next**: complete the live POP (steps 1/2's actual visual confirmation), then steps 5-6
(`registerFontFile(path)` extern + `fONTs` directory-define wiring) per `guiDesign.md` §5.3-5.4 — this
is the one piece Google Fonts font-*loading* needs (independent of the JSON-parsing track, per M3).

### 5. JIT — full-monty plan exists, coverage recon landed, ONE assumption contradicted
`docs/jitFullmontyPlan.md` (Clay) lays out the ladder from the proven gIF pivot to a `testJits()`
full-monty POP. `docs/jit-coverage-recon.md` (Clod, today) fills the plan's §3 placeholder: **42
op-dispatch functions in `Instruct.rtn`** — 18 already jitting-gated, 4 need mechanical gates
(`opAND`/`opOR`/`opRem`/`opNOT`), 20 need real modification (tree mutation, I/O, registry lookups).
**Two findings that need Clay's attention before building loops:**
1. **`aCTionFOR` is NOT a C-style counting loop** — it's a GroupItem list/tree-traversal construct
   (`next()`/`prior()` over a member/attribute list, reverse/restrict flags). This contradicts
   `jitFullmontyPlan.md` §1.3's "FOR = WHILE plus init+latch" assumption. Recommend deferring FOR to
   the `jitBail` whole-action fallback (§2.1) rather than building it third in the loop ladder as
   planned — WHILE and DO don't have this problem.
2. **The null-guard parity fix (`e6405fb`, opLT/opGT/opLE/opGE) has NO jitted counterpart, and it's
   not just unported — it's structurally bypassed.** `jitEmitCompare` does raw ICmp/FCmp with zero
   null checks, and the jitting gate returns *before* the interpreter's guard code ever runs. Any
   jitted compare on null operands will silently diverge from interpreted semantics.
3. Also: `opPlusEQ` correctly type-checks before jitting; `opMinusEQ`/`opDivEQ`/`opMultiplyEQ`/
   `opMinusMinus`/`opPlusPlus`/`opPlus`/`opMinus` all fire their jit gate unconditionally assuming
   numeric — latent until a jitted region hits a string/list/buffer target.
**Next**: Clay reviews the recon, decides FOR's fate and whether the null-guard bypass blocks starting
WHILE/DO, then the ladder in `jitFullmontyPlan.md` §4 proceeds (rung 0: nesting-safety check on
`jitIfBegin/End` state; rung 1: loop mechanism POP via WHILE).

### 6. webChannel — plan of attack exists, step-0 recon done, THREE pushback items
`docs/webchannelAttack.md` (Clay) proposes HTTP/1.1 subset, single-threaded pump off the existing
runloop, `setSocketOp` mirroring `setFileOp`, BotClient-shape for `/eval`. `docs/webchannel-step0-recon.md`
(today) found the runloop assumption doesn't hold as stated, plus two more:
1. **No persistent runloop by default.** `main()` (`groups.mm`) is CLI-only; a Cocoa runloop only
   spins up on-demand via `openWindow()` (`guiHost.mm`) calling `[app run]`. Recommend CFSocket +
   `CFRunLoopRun()` directly for the pilot (no NSApplication needed) rather than assuming an existing
   loop to "hook into."
2. **`setFileOp` isn't a general callable extern** — it's bound to a single global operator slot
   (`modedOP`, via `operateMethod=`), invoked with special binary-operator syntax. `setSocketOp`
   should instead mirror `openWindow`'s plain-extern + `immediateAction=` registration pattern.
3. **BotClient offers no free ride.** `docs/bot-recon.md`'s own text says `BotClient.run()` never
   actually parses text (hardcoded stub, TODO); the cited `parseString` helper only exists in
   gitignored `Aside/` legacy backups, not the live build. The real proven text→GroupItem mechanism
   is the JSON parser's push/pop-input-diversion path (`docs/json.md`) — `/eval` should model itself
   on that instead.
The `guiHost.mm` tok-bypass pattern (for CoreFoundation/socket headers `tok` can't parse) is confirmed
and has a working precedent (`openWindow`) to copy directly.
**Open question for Step 1** (biggest one): does a top-level-statement parse entry for arbitrary
incant code already exist (analogous to `JSONblock`'s divert mechanism), or does `/eval` need its own
small parser rule built from scratch? This determines whether `/eval` is a thin wire-up or a real
parser task — recon before Step 1 starts. **Steps 1-2 (echo, static HTTP 200) not attempted today** —
time-boxed out; step-0 recon surfaced enough open questions that building felt premature.

### 7. Google Fonts / JSON (M3) — real choke point found, NOT fixed (by design — recon only)
`docs/json.md`'s "green end-to-end" claim holds for a single Google-Fonts-shaped entry, but the real
API's actual top-level shape — `{"items": [{...}, {...}]}`, an array of objects — **does not parse**:
`JSONtoken` (what `JSONarray`/`JSONitem` resolve array elements to, in `incant/utilities`) has no
`JSONblock` option. Fails cleanly in isolation (reports `FAIL`, no crash/hang). **More concerning**: in
sequential-parse context (after several prior successful `testJSON` calls in the same run), the
identical failing input logs the internal failure but `testJSON` reports `ok` anyway — a silent
success-on-failure masking bug, not yet root-caused (suspected relation to the prior `isRule`/rule-
clobber findings in `docs/json.md`, or `JSONblock`'s `fail`-modifier recovery semantics). `incant/jsonTest`
updated and committed (`1dc4f7c`) with a fresh case demonstrating this; also fixed two stale
"known-bug" comments in that file that no longer matched reality (both bugs were fixed 2026-06-22,
comments never updated). **Next**: (a) resolve the silent-masking behavior FIRST — a grammar fix isn't
safe to verify until sequential-context masking is understood; (b) then add `JSONblock` as a
`JSONtoken` option so array-of-objects parses.

### 8. Window recon (M4) — plan exists, first step identified, not built
`docs/setWindow-plan.md`. OldGUI's `wINDOW` (`GUI/Map.rtn:1320`) built windows/panels from a
`closable`/`title`/`resize` mask, reused a single root window (`bwana.window`), attached each block's
pre-existing per-item `Layout` as content view, cached popups by name in a `windows` hash on the
`Bwana` singleton, and wired the window delegate as a **separate hand-rolled object** on the root
window (`Control::start`) — NOT the content view / Layout itself, despite today's `Layout implements
WindowDelegate` + `windowWillClose`. Current `GroupDraw.twk` `setWindow` stub's biggest gap: the
`layout = new(framed); layout.base = block;` wiring is commented out — no per-window `Layout` is ever
created or attached, so nothing would display. **First concrete step for a minion**: wire a fresh
`Layout` per window (`layout = new(); layout.init(block); view.add(layout);`), verify by building and
confirming a single-window test fixture actually shows content. Everything else (delegate wiring,
root-window reuse, window registry, popups, close-policy per `guiDesign.md` 4.8) stacks on top — see
the plan's 5 numbered steps and open decisions D1-D4.

### 9. tok-semantics POPs (P1/P2/P3) — all answered clean, no fixes needed
Answered directly from tok's already-generated C++ (not scratch files — faster, and arguably more
bones than a fresh POP since it's the literal code that runs):
- **P1** (switch fallthrough): tok auto-inserts `break;` after every `case` (confirmed in
  `Layout.mm`'s align switches). No fallthrough risk. `guiDesign.md` 4.3's concern is moot.
- **P2** (bare `x`/`y` in `contains()`): resolved correctly to the `Point p` argument
  (`p.y > frame.origin.y`), not to `frame.x`/`frame.y`. No `use p` needed.
- **P3** (bare `selectable` in `blockContaining()`): resolved correctly to `style->selectable` (the
  local `Stylish*` set two lines above). No `use style` needed.

## New bear traps banked to CLAUDE.md (read there for full text — #12-15)
12. `extern "C"` name collisions between unrelated `.twk` files link-fail silently until `Ld`, with no
    hint which incant files collided. Grep before adding a short/common extern name.
13. `-% … %-` passthrough drops incant-level locals only referenced inside the passthrough (tok's
    "unused declaration" pruning — the `Declarations ignored because not used: N` warning is
    load-bearing). Do the whole computation inside the passthrough, using raw Apple/C++ types.
14. `printf`/stdout inside a passthrough is lost if the run ends via `stop()` (block-buffered, no
    flush before `exit()`). POP-tool debug output must use `fprintf(stderr, …)`.
15. Bare top-level incant scripts don't support `identifier = new(...)` for a fresh identifier
    ("`RunRulE: expected a method not <name>`") — the correct ad hoc top-level construction idiom is
    **unresolved**. Check `incant/unitTests`'s predefined-action pattern first.

## Run recipe / reproduce
- Binary = `~/Library/Developer/Xcode/DerivedData/InProcess-ezzmcllcsvijqmbipricnduikqfp/Build/Products/Debug/Groups`.
- `<binary> incant/oneTest` → `maximus = 26`. `<binary> incant/jitGifScratch` → 99 (taken) / 11 (not-taken).
- `<binary> incant/jsonTest` → all cases `ok` except the deliberate Google-Fonts array-of-objects
  case (reports `FAIL` cleanly, or `ok` if hit by the sequential-masking bug — see thread #7).
- **No `timeout` on this shell.** If a change re-introduces a hang: background + kill, or cap a loop.
  `cout`/`dumpContents`/`printf` are block-buffered and lost on hang/SIGTERM/`stop()`'s `exit()`; for
  pre-hang or POP-tool diagnostics use `cerr`/`fprintf(stderr,…)` (unbuffered) — see bear-trap #14.

## Build + debug mechanics (durable, unchanged from before today)
- **`tok GroupRules.twk` THEN build** for `.rtn`-file changes (`jitEmitters.rtn`, `ruleActions.rtn`,
  `Instruct.rtn`, `GroupActions.rtn`, `Commands.rtn` are `include`d INTO `GroupRules.twk`). For
  standalone class files (`Layout.twk`, `Stylish.twk`, `GroupDraw.twk`, etc.) just `tok <File>.twk`
  directly. Sanity: `grep -c extern GroupRules.h` ≈ **152**. A wipe to 0 = a parse error cascaded
  (bear-traps #10/#11; `groups.ext` lives OUTSIDE the repo).
- **Build via the WORKSPACE:** `cd /Users/anthony/Library/CloudStorage/Dropbox/data/InProcess &&
  xcodebuild -workspace InProcess.xcworkspace -scheme Groups -configuration Debug build` lands in the
  `InProcess-ezzmcllc…` DerivedData (Tony's path). `-project ../TOK/TOK.xcodeproj` lands elsewhere
  (`TOK-dunath…`) — don't use the stale one.
- **Passthrough idiom:** `-% … %-` wraps raw Apple/C++ calls; header stays incant-typed and
  clean. See new bear-traps #13/#14 for passthrough pitfalls hit today.

## NEXT — prioritized for whoever resumes (cold, no memory of today)
1. **Read `docs/jit-coverage-recon.md`** if picking up JIT — Clay was blocked on it, it's landed, and
   it changes the loop-ladder plan (FOR isn't what was assumed).
2. **Complete the colors + fonts live-render POPs** (bear-trap #15 blocks both) — likely quick once
   the top-level script idiom is found; `dumpColorRGB`/`dumpFontInfo` are ready and waiting.
3. **Build `resolveStyle`** (`guiDesign.md` §2) — unblocked by the bear-#1 resolution (thread #2),
   nothing populates a Stylish from its definition yet.
4. **JSON**: resolve the sequential-masking bug before touching `JSONtoken`'s grammar (thread #7).
5. **webChannel Step 1**: resolve the `/eval` parser-entry open question first (thread #6), then
   build the echo listener.
6. **Window recon → build**: wire a fresh `Layout` per window in `GroupDraw.twk`'s `setWindow` stub
   (thread #8's first concrete step).
7. Fonts steps 5-6 (`registerFontFile`, directory wiring) — feeds Google Fonts once JSON's
   array-of-objects parses.

## Reactions/pushback sent back to Clay (via Tony) — don't re-litigate without new evidence
- JIT: FOR isn't a counting loop; null-guard parity is structurally bypassed in jitted compares, not
  just unported (see thread #5).
- webChannel: no persistent runloop by default; `setFileOp` analogy is misleading (it's an operator
  slot, not a general extern); BotClient's text→GroupItem entry is a stub, not a salvageable path
  (see thread #6).
- Colors: `rgbColor` is a raw tok keyword, not an editable "wrapper" as `guiDesign.md` 3.2 phrased it
  — the fix landed at the one live call site instead (thread #3).

## DEFERRED — not this arc; whose call
- **GUI content dispatch** (text/image/cell/path off `Layout.drawRect`) — needs `resolveStyle` +
  reconcile/draw split (`guiDesign.md` §6) built first.
- Switch, and any rule actions beyond IF/FOR/DO/WHILE — JIT's explicitly-deferred list
  (`jitFullmontyPlan.md` §1.5), unaffected by today's FOR finding.
- webChannel steps 2+ (HTTP subset, /eval, /wiki) — blocked on Step 1's open question.
