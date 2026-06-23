# Incant — Status & Handoff (2026-06-23)
*Written by Clod for a fresh Clay/Clod tomorrow. Assumes no memory of today. Self-contained.*

## Headline
Two-day run that started as "wire up the bigify cell builder" and turned into **language
archaeology**: revived a dead subsystem and added **two new operators**, then used them to
build the bigify grid. The **build half is done and proven**; the **painter is one bounded
setFrame fix away** from pixels on glass.

All four commits below are **pushed to `main`**. The `drawRect` painter is staged in
`Layout.twk` but **uncommitted** (unverified GUI code — needs an Xcode build).

## Verify it still works (do this first)
```
~/bin/incant incant/oneTest      # bytecode battery -> final "maximus = 26"
~/bin/incant incant/jitscratch   # JIT POPs -> 8 green readbacks
~/bin/incant incant/jsonTest     # -> ok : {"a":[]} / ok : {"a":["x","y"]}
~/bin/incant Tests/bigifyFrame   # bigify: BEFORE = clean percent grid; AFTER = setFrame bug
```
(Boot noise: `getRStuff:` and `aCTionDefinE:` lines are normal — a debug directive prints the
latter per define. `setGroup: cannot add ... to itself` is benign listRules/`:+` noise.)

---

## TODAY'S COMMITS (all on `main`)
- `290af9c` — **Merge subsystem**: two-sided opt-in contract, action-callable processFlags, `:.`
- `1b31126` — **`<-`/opRebind**: clean slot-rebind operator + bigify regular-grid builder
- `06e9c9b` — **Band-splitter + percents**: arbitrary clamped big slot, percent sizing
- `f2a27d5` — gui.md bigify status note

## The language primitives that landed (the durable wins)
1. **Merge revived + two-sided contract.** `merge` was orphaned — `aCTionDefinE` never invoked
   `GroupItem.merge`. Now `addAttribute` merges **only when BOTH source and target carry
   `mergeOn`** (`if grup.mergeOn && mergeOn { merge(grup); return this; }`, GroupItem.twk).
   Default-off; keeps `processCode`'s frame-binding from self-merging templates an action names.
   The `merge` command (and the whole flag-command family) is now callable in **actions** too:
   `processFlags` is `fLAG`-aware (`target = item.fLAG ? item.parent : item`).
2. **`:.` / opSetFlag** (Instruct.rtn) — toggle a GroupField flag on a target:
   `cell :. mergeON`. Cases: `isPercenT`(21) `isVirtuaL`(25) `mergeON`(26) `noPrinT`(29)
   `byReF`(31). Extend by adding a `gCount` case. **Gotcha: GroupFields must be EXPLICIT
   `=N`** in `incant/setup` — implicit entries get gCount 0 and `:.` no-ops on them.
3. **`<-` / opRebind** (Instruct.rtn) — the missing "rebind a local to a fresh node":
   `cell <- argument :+ new(nm)`. `:=` is byRef-sticky, `=` content-copies-keeps-tag; `<-`
   does `local.group = node` with **no byRef**, the clean pointer-set `aCTionScopeXP:705`
   already uses. Works because `<-` carries the `assign` flag (moved off `=`/`=%`, which were
   dormant), and `runOP`'s group-deref is gated `!op.isAssign` so opRebind gets the RAW slot.
   `:+` (opReplaceMember) now **returns the added node** (was the container) so the rebind has
   something to bind to. Already JIT-shaped (locals → stack-slot pointers).

## Active thread: BIGIFY (the band-splitter that out-slicks Bwana's C++)
Reimplementing old Bwana `bigify` (object pool + by-ref counter + `goto`) as pure incant —
the layout is two nested `while`s and a clamp. Full detail in **`docs/gui.md`** ("BIGIFY in
incant" section).

**Build half — DONE & proven (`bigifyLayout` in `incant/utilities`).** Clamp `selRow`/`selCol`
(block state) → `bOR`/`bOC`; split intersecting rows into left-strip `bigColumn`s / big cell /
right strip; non-intersecting rows full-width. Each cell **merges** its template
(`regularItem`/`bigItem`) and is **stamped** `row`/`col`. **Percent** sizes via `:. isPercenT`;
stamps wrapped in **`copyOf`** (else `+%` aliases the reused local). Verified at a non-corner
slot (4×3, big 2×2 @ (1,1)): correct three-band tree, per-cell stamps, heights 25/50/25,
widths 33/33/33 + strip 33 / big 67.

**Painter — staged, uncommitted.** `Layout.twk` `drawRect` (was a stub) now walks `base`
depth-first via **`GroupItem.walk`** (no recursion, no `nextMember` clobbering), gets a `Frame`
per node via **`getFrame`** (GroupDraw.twk:162 — already reads x/y/width/height), and strokes a
`rectangle`. ~15 lines, all on existing primitives. **Tony's Xcode pass:** set `strokeColor`,
tune the y-flip, wire `base` to the bigify block, and build. Then commit once borders paint.

## IMMEDIATE NEXT (in order)
1. **setFrame fill-path fix (Tony, offline/Xcode).** `Tests/bigifyFrame` is the repro: BEFORE =
   clean grid, AFTER = `setFrame` **`fillAcross` fires on the `across=1` rows and duplicates
   cells ~17×**, and `x`/`y` come out empty. Breakpoint `setFrame` (`incant/utilities:183`) +
   the fill check (`if across == "*"`, ~:192) — the `*`-fill path shouldn't run on already-
   populated blocks. Likely a "skip fill if members present" guard or a non-`*` across marker.
   **Plan B if it fights:** tabs (setFrame already handles them) to prove `drawRect` independently
   — borders painting is the milestone either way.
2. **Build the `drawRect` painter** (Layout.twk) → first real paint: a window of bordered cells.
3. **`displayImage`** — oldGUI Layout's is **native** (`image.drawIn`, NOT HTML — that's only
   the newer `GUI/Layout.twk`). Salvage it, swapping `detail.frame`/`detail.*` for `getFrame`/
   the cell's attributes. Need to locate the `Image` NSImage-wrapper class + the load path.
4. **`seq`** — covered-before reading-order stamp (so source-fill order survives a moved slot).
5. **`reBigify`** — selection → block `selRow`/`selCol` + rebuild. Makes it live.

## Key files / test targets
- `incant/utilities` — `bigifyLayout` (the builder), `setFrame` (:183), `getFrame` is GroupDraw.
- `Instruct.rtn` — opRebind (`<-`), opSetFlag (`:.`), opReplaceMember (`:+`), opSetGroup (`:=`).
- `incant/setup` — operator registrations (`<-`, `:.`), GroupFields gCounts (make them explicit!).
- `Layout.twk` — the `drawRect` painter (staged, uncommitted).
- `Tests/bigifyFrame` — setFrame test target (self-contained, builds grid + drives setFrame).
- `docs/gui.md` — full bigify + GUI design/recon (read first for GUI work).

## Idioms banked today (hard-won)
- **`new(name)` is the only way to mint a uniquely-tagged node in a loop** — `:+` tags a member
  after the *operand's local tag* (can't be dynamic); juxtaposition doesn't concat. Use `<-` to
  rebind the handle each pass.
- **Name-build: `string $"prefix" counter`** — the `$` (= `useDefaultSpace` off, print-style)
  suppresses the space; without it you get `"prefix 0"`.
- **Stamp with `copyOf`** — `cell +% copyOf(width)`; bare `+%` aliases the reused local so every
  cell ends up sharing the final value (setFrame does `:% copyOf(...)` for the same reason).
- **Never `locate` in an action** — references resolve at *parse time*; a bare name in scope IS
  the located node. Templates ride in as block fields and are scoped via `:argument`.
- **Fixtures must live in `define`** to build a member list; a bare top-level block never defines.
- **Comments aren't inert** (no lexer) — tokens inside `/* */` get parsed; keep test files lean
  and fixtures single-line.

## Parked threads (not today's work — see prior docs)
JIT Phase 2 (control flow / IF-FOR) is the next JIT frontier (`docs/jit.md`). JSON parser is
green; Google-Fonts two-step (`getFile`→`JSONblock`) needs a `getURLintoBuffer` extern decl.
Fonts/colors (Option A, model-first) is on Clay's design plate (`docs/gui.md`). None blocked by
today's work.
