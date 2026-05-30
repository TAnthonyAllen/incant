# Tok/plg arc — Status & Handoff (2026-05-30)

*Written by Clod for a fresh Clay tomorrow. Assumes no memory of today. Self-contained — this doc
is your memory across the gap, not the transcript.*

## What this is

We spent today migrating the TAWK toolchain (`Tokf/`) off a dead type (`PLGtester`) and onto the
current PLGitem surface — the file-by-file **Phase Integrate** work that gets us to a rebuilt
`~/bin/tokTemp`. We did not expect to touch Tawk at all today; we ended up deep in it. The arc
surfaced **one real blocker** that is your seat for next session: plg cannot yet generate a
Tawk.twk that tok can parse. Everything else from today is done and confirmed.

## The lens (hold these five facts and you can reason about the whole thing)

1. **The pipeline is `Tawk.g → (plg) → Tawk.twk → (tok) → Tawk.C`.** plg reads the grammar
   `Tawk.g` and emits `Tawk.twk` (TAWK source); tok compiles `Tawk.twk` to C++. Both steps must
   succeed for TOK (the `~/bin/tokTemp` target) to build.
2. **`Tawk.twk` is one class plus free functions.** It is `class Tawk extends PLGparse { …fields…
   setRules() …action-method bodies… }`, preceded by an `external { }` block and the includes.
   The parser's *state* lives in **class fields** (`SymbolType currentClass, …`); the rule
   *actions* are **free functions** (externs) that reach the parser via the item.
3. **plg's `generateRules` assembles `Tawk.twk` by splicing.** It writes the includes, an extern
   block, then a verbatim "splice" of the `.act/.rtn` files, then the `class Tawk { setRules() }`
   wrapper. Its design assumption: everything in the splice is a top-level extern.
4. **That assumption is half-wrong — and that's the blocker.** The splice also carries the **class
   field declarations**. They land at file scope, *above* the class. tok cannot parse
   `SymbolType currentClass,` outside a class → it dies with `ERROR Inheritance`, writes an empty
   `Tawk.h` and leaves `Tawk.C` stale. So the freshly-generated `Tawk.twk` is **not buildable**.
5. **Today we proved the migration bones are sound by going around the blocker** — the legacy
   hand-maintained `Tawk.twk` still toks. The blocker is purely in plg's *generation*, not in the
   migrated source.

## OPEN — the blocker, root-caused (your seat next session)

**`generateRules` (in `PLGparse.twk`) must split class-body material from extern bodies.**
- Symptom: `plg Tawk.g` → `Tawk.twk`; `tok Tawk.twk` fails immediately —
  `ERROR Inheritance: at ==>SymbolType` / `==>currentClass,` …, empty `Tawk.h`, stale `Tawk.C`.
- Root cause: the splice flush dumps the `.act/.rtn` content (which mixes **class field
  declarations** and **extern action bodies**) entirely at top level, before the
  `class Tawk extends PLGparse { … }` wrapper. Extern bodies at top level is correct. Class
  fields at top level is not — tok only accepts field declarations *inside* a class.
- The fix is a design call (yours): teach `generateRules` to route class-body material (the
  `#autoGetSet` block + field declarations like `SymbolType currentClass, …`) **inside** the
  class wrapper, while keeping the free-function action bodies at top level. The hard part is that
  the splice is currently one undifferentiated blob; the split needs a principled seam (e.g. the
  `.rtn`/`.act` files declaring what is class-body vs extern, or generateRules recognizing field
  declarations). That seam is the design conversation.

## DONE today — bones-confirmed (verification level noted per item)

- **PLGitem surface migration**: `Symbol.twk`, `SymbolType.twk`, `Instance.twk`, `Directive.twk`,
  `FormatC.twk` — all migrated off `PLGtester`/old accessors. **Tony confirmed Symbol, SymbolType,
  Instance, Directive building clean in Xcode; FormatC confirmed via tok exit 0 only — not yet
  exercised in a full build.** (The rule set was: `iTEM.get(s)` and `iTEM[s]` →
  `iTEM.children[s]`; `.string()`/`.unString()` → `.toString()`.)
- **Two-arg `divertInput` reinstated** in `PLGparse.twk` and declared in the `PLGrevision`
  externals: `PLGitem divertInput(String s, PLGrule rule)` and `(String s, String ruleName)`.
  They were dropped in the refactor; their absence was breaking every caller. Thin wrappers over
  the surviving `divertInput(s)` / `parse(rule)` / `revertInput()` primitives.
- **FAIL handlers relocated.** The four rule FAIL handlers (`assignFailed`, `caseLabelFail`,
  `expressPartFailed`, `instanceTailFail`) were free functions in `Tawk.g`'s `%%` epilogue, which
  plg's regen does not carry. Moved to `Tok.twk` as file-scope externals reaching the parser via a
  new `static Tawk Tok::testParser` (set once in `main`). They compile, **but are dormant** — see
  DEFERRED. `Tawk.g`'s epilogue was stripped of them.
- **plg now writes `Tawk.twk` directly** — the `Tawk.regen.twk` name is retired. (The source did
  this since ~2026-05-19; the installed binary was a stale 2026-05-17 build still emitting
  `.regen`. Rebuilt today.) `~/bin/plg` is now a symlink → `Parse/build/Debug/plg`.

## DEFERRED — not now; whose call

- **FAIL-handler wiring in plg's new format** (plg's seat, after the blocker). The new regen emits
  **zero** `currentRule.fail = …` wirings. So even once the blocker is fixed, the relocated FAIL
  handlers stay *defined but never called* until plg learns to emit FAIL wiring. Dormant by
  design for now.
- **tok auto-include bug** (a known tok defect; fix lives in `FormatC.twk`). tok emits an
  `#include` for every external declaration in scope, used or not. This injected phantom
  `#include "PLGparse.h"` and `"PLGitem.h"` into `support/Frame/PLGset.C`, which broke the plg
  rebuild. We hand-pruned them — **but they return on any `tok PLGset.twk`.** Durable fix is the
  tok bug itself.

## Files touched / state

- Clean & toked: `Symbol.twk`, `SymbolType.twk`, `Instance.twk`, `Directive.twk`, `FormatC.twk`,
  `Tok.twk` (+ the `Tok::testParser` static), `PLGparse.twk`, `PLGrevision`, `Tawk.g` (epilogue
  stripped), `support/Frame/PLGset.C` (phantom includes pruned).
- **`Tawk.twk` is currently the legacy old-format version (git commit `89a3abc`), which toks** —
  it is the working baseline. **Do NOT use** HEAD `ef2730d` (the "Phase Splice" intermediate —
  new-format setRules with C++ `elem->` arrows tok can't parse) or a fresh `plg Tawk.g` overwrite
  (fields-outside-class). Both are broken; both recoverable from git.

## To resume — next actions in order

1. Open the **generateRules woodshed**: design the class-body / extern split in `generateRules`.
2. Decide the seam: does `generateRules` learn to recognize field declarations, or do the
   `.rtn`/`.act` files mark class-body vs extern content explicitly? That's the core design call.
3. Clod executes the chosen split, regenerates `Tawk.twk`, and confirms `tok Tawk.twk` produces a
   non-empty `Tawk.h` + fresh `Tawk.C` with no `ERROR Inheritance`. Then the FAIL-wiring item
   (DEFERRED) is the next plg step.

**Tony — to brief Clay, upload these:** `Parse/PLGparse.twk` (the `generateRules` method is the
subject), `Tokf/Tawk.g` (the grammar plg reads), and a freshly-generated `Tokf/Tawk.twk` showing
the breakage (the field block sitting above `class Tawk extends PLGparse` near the end). That trio
is enough to design the split cold.

## Gotchas (durable — will bite again)

- **tok won't concatenate juxtaposed strings inside a method-call argument** — it flattens them to
  comma-separated args. `foo("a" x "b", 0)` becomes a 6-arg call. Hoist the concatenation into a
  `String` declaration first, then pass the variable. (Hit in `FormatC.twk`'s `close()`.)
- **plg's Release config is broken** — the `support` dependency can't find `PLGparse.h`. Use the
  **Debug** config to build plg.
- **`Tawk.twk` is generated** — hand-edits to it are temporary until the plg-generation fix lands.
  The durable source is `Tawk.g` (+ the `.act/.rtn` splice files).
- **`tok X.twk` without `groupDirectives` silently strips directive-injected code** — 52 lines
  vanished from `GroupItem.mm` before Clod caught it today. Always run `tok X.twk groupDirectives`
  for any instrumented file.
