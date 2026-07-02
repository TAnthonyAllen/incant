# webChannel Step 0 — Runloop Recon + VERIFY Items

*2026-07-02, recon fork. Verifies `~/Downloads/webchannelAttack.md`'s VERIFY-tagged
assumptions against the actual codebase. Recon only — no `setSocketOp` code written.*

## 1. Runloop recon (Step 0) — verdict: no persistent runloop by default

`main()` (`groups.mm:20-31`) is a plain CLI entry point: parse `argv[1]`, run
`bootstrapper()`, `boot.parse(0)`, return. **No `NSApplication`, no runloop.** This is
why `oneTest`/`jsonTest`/`jitGifScratch` run top-to-bottom and exit — there is nothing
pumping after the parse finishes.

A GUI runloop only exists **on demand**, via `openWindow(field)` (`guiHost.mm:26-69`,
registered `openWindow immediateAction=openWindow;` in `incant/setup`). It creates
`NSApplication`, builds a window with a `Layout` content view, and calls `[app run]` —
a real, blocking Cocoa event loop that only starts if/when incant code calls
`openWindow`. Closing the window calls `[NSApp terminate:nil]` (via an
`NSWindowWillCloseNotification` observer), ending the process.

**Recommendation for webChannel:** don't assume "the existing runloop" — for a headless
pilot (no GUI window open, matching Step 1/2's `curl`-only POPs) there is no runloop to
hook into. Two options:
- **CFSocket + `CFRunLoopRun()`** directly — lightweight, no `NSApplication`/AppKit
  needed at all. This is probably right for the pilot: add a `CFSocket` as a run-loop
  source on `CFRunLoopGetCurrent()`, then call `CFRunLoopRun()` to block and pump.
- If a GUI window is *also* open (`openWindow` was called), the CFSocket source can be
  added to the **same** run loop `[app run]` is already pumping (`CFRunLoopGetMain()` /
  `CFRunLoopGetCurrent()` from the main thread are the same loop) — no second loop needed.
- **NSTimer tick** is viable but adds latency (poll interval) for no benefit once CFSocket
  is available; skip it unless CFSocket proves awkward under tok/guiHost constraints.

**Verdict: CFSocket-on-CFRunLoop, not NSTimer.** Whether it's `CFRunLoopRun()` standalone
(headless) or shared with `[app run]` (GUI-open case) is a Step-1 decision, not a Step-0
blocker — the mechanism is the same either way.

## 2. `setFileOp`'s exact shape — PUSHBACK: not a general-command registry

Found: `Instruct.rtn:812-822` (also `GroupRules.mm:4464-4479`, prototype `GroupRules.h:226`):
```c
extern GroupItem setFileOp(GroupItem argument, GroupItem target)
{
    if target.isBUFFER  target.buffer.setFile(argument.text);
    return target;
}
```
It is bound via `incant/setup:87`: `modedOP operateMethod=setFileOp;` — this rebinds the
**gOp function-pointer slot of the `modedOP` operator** (via `setOperat(dlsym(...))`,
per `docs/modedOP-taG-recon.md`), not a named-command dispatch table entry. It's invoked
with **operator syntax**: `doc modedOP "path"` calls `setFileOp(argument="path",
target=doc)` — the `(argument, target)` shape shared by `opAssign` and the other binary
op methods, not a normal `funcName(args)` call.

Two real constraints this surfaces:
- **`modedOP` is a single global slot**, currently pre-bound to `setFileOp`. Per
  `incant/changeWiki`'s own commentary, runtime rebinding of that slot isn't built yet —
  it's fixed at startup. `setSocketOp` can't just "also" bind to `modedOP` without
  colliding with the file-write path.
- **Operator semantics don't fit a socket listener anyway** — `setFileOp` makes sense as
  an operator because "point this buffer at that file" reads naturally as `buffer OP
  path`. "Start listening on a port" isn't a binary operation on two GroupItems.

**Recommendation:** don't mirror `setFileOp`'s *operator* mechanism. Mirror `openWindow`
instead — a plain `extern "C"` function registered via `funcName immediateAction=funcName;`
in `incant/setup`, called directly as `setSocketOp(port)` or similar. Simpler, no operator
slot contention, and it's the exact precedent guiHost.mm already establishes (see §4).
Amend webchannelAttack.md D3's "analogous to setFileOp" to mean "an extern living outside
tok, registered the same way" — not "goes through the modedOP operator path."

## 3. BotClient's text→GroupItem entry — PUSHBACK: it doesn't exist, it's a TODO

`docs/bot-recon.md` (already thorough) says this directly, in its own words (lines
189-219): **`BotClient.run(String text)` does NOT parse its argument.** It returns a
hardcoded literal (`"BotClient test string"`, `BotClient.twk:15`) — "no GroupItem, no
incant" crosses the wire today. The recon doc explicitly flags this as unfinished, with
a TODO comment in the source itself.

The one candidate the recon doc mentions as the *real* text→GroupItem primitive —
`parseString` (`BotClient.twk:27`'s comment) — **does not exist in the active build.**
Grepped the whole tree: `parseString` only appears in `Aside/BeforeSimple/ParseXML.*` and
`Aside/WithJIT/ParseXML.*` — both gitignored legacy backup directories (per CLAUDE.md,
`Aside/` is explicitly not part of the live source), attached to an old `ParseXML` class,
not anything BotClient could currently call.

**So "the BotClient shape" is not reusable working code — it's a comment describing an
intent that was never wired up.** webchannelAttack.md's mission statement ("The ONE
reusable idea is BotClient's shape") should be corrected: there is no proven text→GroupItem
entry point salvageable from Bot/ at all.

**What actually IS proven, live, and reusable today:** the JSON parser's string-divert
mechanism (`docs/json.md`, verified green 2026-06-22). `JSONblock("...")` is a **rule**,
not a plain function — calling it routes through `runRule(field, rule)`
(`GroupRules.mm`/`GroupActions.rtn`), which `pushInput`s the string so the parser
**diverts its input stream** to it, runs `rule.parse(0)`, then `popInput`s. This is a
real, tested, currently-working "text in → GroupItem tree out" mechanism — closer to what
`/eval` actually needs than anything in Bot/. Recommend `/eval`'s text→GroupItem step
model itself on this divert mechanism (possibly reusing `runRule`/`pushInput`/`popInput`
directly against a top-level parse rule, not `JSONblock` specifically) rather than chasing
BotClient's stub.

## 4. tok-vs-socket-headers — guiHost.mm pattern CONFIRMED, with a live precedent

`guiHost.mm` (repo root) is exactly the pattern webchannelAttack.md guesses at: a
hand-written `.mm` file, compiled directly by the Xcode target, **never passed through
tok** ("tok can't parse inline `[bracket]` message sends" — file's own header comment).
It defines `extern "C" GroupItem *openWindow(GroupItem *input)` doing full `Cocoa`/
`NSApplication`/`NSWindow`/`NSNotificationCenter` work with block-based callbacks, then
gets bound into incant purely via `incant/setup`'s `openWindow immediateAction=openWindow;`
— no tok involvement at any point, just a normal `dlsym`-style extern-name bind.

This confirms the trick works and is already load-bearing for exactly this class of
problem (Apple API surface tok can't parse — bracket sends, blocks). CFSocket's C API
(`CFSocketCreate`, `CFSocketSetSocketFlags`, callback function pointers) is actually
**more tok-friendly** than AppKit's bracket-heavy surface — but CFRunLoop source
attachment and any NSNotificationCenter/block-based glue would hit the same wall. **Plan
on a `guiHost.mm`-style host function for the CFSocket setup + callback, same as
`openWindow`,** registered the same `immediateAction=` way. Also worth noting: `guiHost.mm`
already imports `Cocoa/Cocoa.h`, `GroupControl.h`, `GroupDraw.h`, `Layout.h` and does the
`GC_add_roots`/`GC_set_no_dls` dance for AppKit's root-set storm — a socket-only host file
that never touches AppKit probably does NOT need that GC dance (it's specifically an
AppKit-framework-load issue, not a general Foundation/CoreFoundation one) — worth a quick
sanity check at Step 1 rather than copy-pasting the GC workaround unconditionally.

## Pushback summary (vs. webchannelAttack.md)

1. **D2 "pumped from the existing runloop"** — there usually *isn't* one; the pilot needs
   to start its own (`CFRunLoopRun()`), not assume `[app run]` is already active. Not
   wrong in spirit, just needs the "no window open" case spelled out.
2. **D3 "setSocketOp, analogous to setFileOp"** — `setFileOp` is bound to a single
   operator slot (`modedOP`) via special binary-operator syntax, not a generally-callable
   named extern. `setSocketOp` should mirror `openWindow`'s plain-extern +
   `immediateAction=` registration instead — simpler and a better fit for imperative
   "start listening" semantics.
3. **D4 "the BotClient salvage"** — BotClient's text→GroupItem path is an unfinished TODO
   with no working code behind it, and its cited helper (`parseString`) doesn't exist
   outside gitignored legacy backups. Use the proven JSON push/pop-input-diversion
   mechanism (`docs/json.md`) as the real model for `/eval`'s text→GroupItem step instead.

Everything else in webchannelAttack.md (HTTP/1.1 subset scope, 127.0.0.1-only bind,
rOUTEs registry idea, the step ladder itself) held up under this recon — no objection.

## Biggest open question for Step 1

Given `/eval` doesn't get a free ride from BotClient, **what exactly does the
push/pop-input-diversion path need in order to parse a *statement* (not a JSON value)
from an arbitrary string and hand back a live GroupItem result** — i.e. is there already
a rule/entry point equivalent to "whatever `incant <file>` uses to parse top-level text,
minus the file read" (webchannelAttack.md D4's own phrasing), or does `/eval` need a new
tiny top-level-statement rule built the same way `JSONblock` was? This determines whether
Step 4 (`/eval`) is a thin wire-up or its own small parser-rule task. Recommend recon'ing
`GroupMain.mm`'s `boot.parse(0)` call chain against `runRule`'s divert mechanism before
starting Step 1, since Step 4 is the pilot's actual victory condition.
