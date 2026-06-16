# Incant — Status & Handoff (2026-06-16)
*Written by Clod for a fresh Clay/Clod. Assumes no memory of today. Self-contained.*

## What this is
End-of-session wake-up doc covering the full active work surface as of 2026-06-16:
(1) a committed crash fix in the scope-expression rule action, (2) a new committed
`wiki/` directory in the repo plus a pushed live-wiki update, and (3) an in-progress
bulk conversion of the `IncantForms/` XML window-definition files to incant `define`
format. Plus a note on the loop-emitter thread (Clay's domain).

## The lens
The big in-flight task is the **IncantForms conversion**. `IncantForms/` holds ~100
**copies** of XML window-definition files (the originals are safe under `XML/`). Each
copy is being rewritten in place from XML angle-bracket form into incant `define`
format. This is a deliberately **rough first structural pass** — Tony has said every
file will get a deeper per-file conversion + design pass later, so the goal now is a
**consistent, faithful structural translation**, not perfection. The canonical worked
examples are `XML/Windows/tabs.xml → IncantForms/Windows/tabs` and
`XML/Windows/simple.xml → IncantForms/Windows/simple`. Names and text are kept
**verbatim** (Tony's standing rule: "change the xml to incant definition format and
add nothing"). The hard semantic constructs (command expressions, matrix/spreadsheet
wiring, jit/event code, raw includes) are **carried through as-is and flagged**, to be
designed later.

## Conversion pattern (LOCKED — agreed with Tony this session)
Header boilerplate replaces the entire `#include`/`#registry` header block, verbatim:
```
Start();
include(unitTests);
include(generate);
include(utilities);
initFORMs();
search Generating bcOPs list;
```
Then, per the rules below:
1. **Registries.** The main window registry (whatever it was called — `Tabs`, `cARDS`,
   `GUI`, `SHeeT`, `GUIcomponents`, …) becomes `register(FORMs);`. Other data
   registries keep their own names: `register(dESCRIPTIONs);`, `register(forest);`,
   `register(tEMPLATEs);`, `register(genre);`, `register(KeyStrokes);`, etc.
2. **Block shape.** `register(X); define <members> ;` — the closing `;` on its own
   line, dedented, after the last member.
3. **Nesting.** XML nesting → indentation. Leaf nodes (no children) end in `;`.
4. **Names & text verbatim.** No renaming, no rewording. (The `tabs` example renamed
   things — do NOT emulate that; it predates the verbatim rule.)
5. **Text values → quoted strings**, one-line *and* multi-line (incant handles embedded
   newlines in quotes). Use the doc-block form `field=(text#)` **only** when the text
   contains embedded quotes you can't quote around.
6. **Anonymous text members.** Block text appearing as an unidentified member is really
   the parent field's long text → fold it in as the field's data and delete the bogus
   member.
7. **Multiple top-level elements** → multiple members of one `define` block.
8. **Inline event/action code** (`onLayout`, `jit`, named action blocks) → `code={ … }`
   attribute on the owning node. E.g. `fourth … onLayout code={ print "…":; };`.
9. **Raw include/external content** (e.g. a `<jitInclude>include … external GroupItem
   {…}</jitInclude>`) → carried **verbatim** as the field value, flagged as a deferred
   hard bit (it's directives, not an action body).
10. **Commented-out XML template** (`<!form …!>`) → kept, wrapped in incant `/* … */`.
11. **Draw-path content** (`%@-40 -85 u~ …`) → carried verbatim as the field value.
12. **Macros** (`$pull`, `$"…"`) → verbatim.
13. **Leading prose** (free text before any definition) → moved **below `stop()`**,
    verbatim (it can't sit above `Start()` or it parses). Trailing prose stays below.
14. **Footer:** `printDefinition(<top-level window>);` then `stop();`.
15. Output: same filename, **no suffix**.

## DONE — committed
- **Scope fix** — `commit e942cf8`. `aCTionScopeXP` (`ruleActions.rtn`) segfaulted when
  a scoped field was absent from the argument (e.g. a delete directive with no
  `toThis`): both `new(field.tag)` and the trailing `group=field` dereferenced a null
  `field`. Fix: capture the scope name into a `String name`, look up / create the local
  by `name`, and guard the bind (`if field grup.group = field;`). A missing field now
  yields a fresh empty local read as "not there." Bones-confirmed by running
  `~/bin/incant` against three directive cases — missing `toThis`, present-but-empty
  `toThis`, and the original 3-directive found-field POP — all pass (clean delete, no
  spurious insert, no regression).
- **Wiki directory** — `commits 0074065` (create) and `d0a418a` (link). New `wiki/` at
  repo root: `wiki/WhatIsIncant.md` (fetched raw from the GitHub wiki) and
  `wiki/BootstrapRules` (Clay's deep-dive page, no suffix). Then a one-line link to
  `BootstrapRules` was added at the end of the Bootstrap section of `wiki/WhatIsIncant.md`
  **and pushed to the live GitHub wiki** (`incant.wiki.git`, `cf9efa6..68d7636 master`).

## OPEN — IncantForms conversion (in progress, UNCOMMITTED)
`Windows/` converted this session (9 files, uncommitted — `git status` shows them as
`M`): `cards`, `descriptions`, `fit`, `keyStroke`, `scroll`, `sheet`, `simple`,
`toggles`, `tree`. (`tabs` was already converted/committed before this session.)

`Windows/` still to convert (10): `bigify`, `db`, `drag`, `draw`, `inspector`,
`keyAction`, `layout`, `list`, `menu`, `wraplist`. (`drag` is a near-empty stub — only
two `#include` lines, no definition; treat as a puzzle.)

Other `IncantForms/` subdirs not started (~60 files): `Controls`, `Notions`, `NotGUI`,
`HTML`, `LLVM`, `Groups`, `Generating`, `Stash`, `WorkingOn`.

**`sheet` carries first-pass calls on its hard bits, flagged for the deep pass:** the
`<:Alternative genre>` command expressions were rendered as plain group defs (loses the
`<:>` compute-from-source semantics); `#registry SHeeT` → `register(FORMs)` but
`#search SHeeT …` was left as `search SHeeT …` (not renamed to FORMs).

## DEFERRED — whose call
- **`date`, `accounts` — set aside (Tony's call).** Neither is a form: `date` is pure
  command-expression/regex data registries (`year`, `month`), `accounts` is a non-XML
  incant taxonomy (`AccountType`) that Tony may scrap. Both left untouched.
- **Deep per-file conversion + design** of all IncantForms files (semantics of command
  expressions, matrix/sheet, jit, includes) — later, after the structural pass. Tony +
  Clay.
- **Loop-emitter thread (gWhilE / gDO / gFOR)** — Tony's session note says commit
  boundaries are his to draw. NOTE (Clod, checked against the tree): the current working
  tree shows **no** gWhilE/gDO/gFOR changes — only the 9 IncantForms files and the
  pre-existing `XML/WorkingOn/parser`. If that loop work is pending it's elsewhere
  (already committed, or Clay's context) — **verify before assuming it's uncommitted here.**

## Files touched / run recipe
- Committed: `ruleActions.rtn` + `GroupRules.mm` (e942cf8); `wiki/*` (0074065, d0a418a).
- Uncommitted: the 9 `IncantForms/Windows/*` conversions; plus pre-existing
  `XML/WorkingOn/parser` (not ours — leave it).
- **Build after a `.rtn` edit:** `tok GroupRules.twk` (regenerates `GroupRules.mm`),
  then `xcodebuild -project ~/data/InProcess/TOK/TOK.xcodeproj -scheme Groups
  -configuration Debug build`. Product is `~/bin/incant` → `DerivedData/TOK-…/Debug/Groups`.
- **Run a form/directive file:** `~/bin/incant <path>` (e.g. `~/bin/incant Tests/dirtest`).

## To resume — next actions in order
1. **Commit the 9 converted `Windows/` files** (held pending review):
   `IncantForms: convert Windows forms to incant define format`. Exclude
   `XML/WorkingOn/parser`.
2. **Continue the conversion via approach B (agreed with Tony): fan out parallel
   conversion subagents.** Each agent gets the LOCKED pattern above + the
   `tabs`/`simple` reference pairs, converts a batch, and Clod reviews every file before
   commit; genuine puzzles get flagged to Tony. Finish `Windows/` (10 files) first, then
   the other subdirs.
3. After the structural pass completes: **Tonto recon pass** — Clay reads the converted
   files and flags constructs needing explanation/design.
- For Clay's wiki thread: he reviews `wiki/BootstrapRules` with Tony and designs the
  next wiki page. Files to upload to Clay: `wiki/WhatIsIncant.md`, `wiki/BootstrapRules`.

## First-dive candidates (the eventual one-by-one deep pass)
Tony will soon dive into these files one at a time for the real conversion + design
work. **Be advised: each dive will likely require substantial recon into prior GUI
and/or ParseXML work — possibly both.** As the structural pass proceeds, log good
first-dive candidates here.
- Initial read (Clod, 2026-06-16): `simple` is a strong first candidate — the smallest
  converted form, with a single `onLayout` event body, so it exercises the event/code
  wiring path without multi-panel or command-expression baggage. `toggles` (toggle
  mechanism, no descriptions) is a close second. `sheet`, `menu`, `inspector` are the
  deep end (command expressions, multiple panels, matrix/inspector wiring) — not first.

## Gotchas (durable — will bite again)
- **Buffered stdout is lost on segfault.** A crashing incant run can show *no* output
  even though earlier `print`s executed — don't read "no output" as "crashed at the
  top." (This masked the `aCTionScopeXP` crash as a parse error until proven otherwise.)
- **`.rtn` files are not standalone** — they're `include`d into `GroupRules.twk`
  (lines ~286-291). Editing one requires re-`tok`-ing `GroupRules.twk`, then rebuilding.
- **Bare `group = field`** in a `.rtn` resolves to the last declared field that *has* a
  group (here `grup`) and generates `grup->setGroup(field)` — so guarding with
  `if field` is enough; no need to write `grup.group` explicitly (though it's clearer).
- **No `tok` build phase in the Xcode project** — `tok` is a manual step before
  `xcodebuild`.
