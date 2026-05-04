# TODO.md — Incant
*Read this first every session. Keep it current. `incant.md` is the canonical
state document for design decisions; this file is the live task list.*

---

## 🔥 Immediate (current sprint)

### Bytecode Generation — close the round-trip on `testByteCode`

**Three design questions — DECIDED** (move from open to settled):
1. **Handler identity** — instruction's tag is the **op GroupItem itself**, drawn from existing `Operators` registry + new `bcOPs` registry. Op GroupItem carries the handler reference; interpreter dispatches `runOP`-style.
2. **Registry split** — `Operators` and `bcOPs` are **separate** registries. User-level ops stay in `Operators`; control-flow lives in `bcOPs`.
3. **Successor representation** — **implicit-next** (sibling member). Branches override by returning their target. Operands materialize into vregs directly (skip the `tempField` step-2a intermediate).

**Open assessment (do this first this sprint):**
- [ ] **Can `interpret()` be written in incant today?** — design question. The C++ plan was ~200-300 lines (`Bytecode.{h,mm}`). Per the reflectivity rule, the loop should live in incant if possible; only the per-op handlers stay in C++ as thin shims over existing op machinery. Assess feasibility, draft the incant `interpret` if green-light.

**Implementation chain:**
- [ ] **On-paper walkthrough** of what `generateCode(testByteCode)` should produce, instruction by instruction, validated against the 5-instruction expected emit in `incant.md` §"Expected emit for testByteCode (step 2a)"
- [ ] **Add `bcOPs` registry to `setup`** (XML/WorkingOn/setup) — `bcBR`, `bcBRZ`, `bcRET` entries, each carrying its handler reference
- [ ] **Stub C++ handlers** at repo root — depending on `interpret()` placement: full `Bytecode.{h,mm}` if interpreter is C++; just the per-op handlers if `interpret()` lives in incant. Includes `runBR`, `runBRZ`, `runRET`, plus shims `runGT` / `runMultiply` / `runAssign` wrapping existing `opGT` / `opMultiply` / `opAssign`
- [ ] **Wire the gating hook** — find action-dispatch site in `GroupRules.mm` (or wherever `aCTionStatemenT` calls action bodies). Add a `bytecodE` attribute check; route through `interpret()` when present
- [ ] **Rewrite `gIF`** — currently a 2-line stub at `XML/WorkingOn/generate:102-105`. First real bytecode emitter. Emit `bcBRZ` + body + backpatched target
- [ ] **Rewrite `gXpress`** — currently 1-line stub at `:115-116`. Lower a single expression to its bytecode triple; for `testByteCode`'s `righty > 0` and `righty * 2`, emit instructions whose tags are the `>` and `*` op GroupItems (from `Operators`)
- [ ] **Rewrite `gExpressioN`** — currently 1-line stub at `:85-86`. Likely a thin wrapper over `gXpress`; reconfirm scope when `gXpress` lands
- [ ] **Emit explicit `bcRET`** at end of every emitted action body (so the interpreter's halt condition is explicit, not "fell off the end")
- [ ] **Run `testByteCode()` end-to-end** — POP. Verify `maximus = 26` after `righty=13` (default in `setup`)

### Sub-goal: Get Clod fluent in incant
- [ ] Read `grammar`, `generate`, `Generate.rtn`, `unitTests` end-to-end (oriented, don't touch)
- [ ] Write a simple test action using `for` and `print` (something known to work) as a fluency exercise
- [ ] Then proceed with the bytecode tasks above

---

## 📋 Next Up

### Bytecode Generation — expand once round-trip closes
- [ ] `gPrinT` rewrite — replace stub (currently delegates to old printf-style `genPrint()` at `Generate.rtn:45-93`) with bytecode equivalent. Decide print-as-bytecode-instruction vs print-as-builtin-call
- [ ] `gBlocK`, `gFOR`, `gWhilE`, `gDO` rewrite — they currently emit C++ source. Replace with bytecode emission. Each becomes simple: linearize sub-statements, emit branches at boundaries
- [ ] `gDeclare` — verify field-declaration emission semantics in bytecode model (does it become a runtime no-op? a slot allocation?)
- [ ] `runGenerated` dispatcher — verify it still works when handlers no longer print but emit — likely it does
- [ ] **Add the next test case** — pick one that exercises `runCall` (composite operand `A(B)`). Builds the `runCall` handler. Per `incant.md`'s "build handlers as tests force them" rule
- [ ] Old `genPrint` in `Generate.rtn` — once `gPrinT` is bytecode, retire `genPrint()` from `Generate.rtn`

### Generator C++ bridge cleanup
- [ ] `Generate.rtn` — `dataType()`, `getType()` are kept (still needed for non-emit paths). `genPrint()` gets retired with `gPrinT` rewrite. `generateCode()` itself stays as the user-facing entry point per `incant.md`
- [ ] `Debug.rtn`, `Instruct.rtn`, `parse.rtn`, `ruleActions.rtn`, `GroupActions.rtn` — audit for any lingering references to the abandoned C++-source emit path

---

## 🔭 Longer Term (HPDL — Hard Part Do Later)

- [ ] **Phase 3: LLVM JIT** — ORC v2 API, alloca + mem2reg pass. Bytecode → LLVM IR → machine code. Bytecode remains canonical IR
- [ ] **Threading** — designed but not implemented. Needs JIT first
- [ ] **Go-style channel messaging** — async GroupItem communication across platforms
- [ ] **Claude as native field type** (`isCLAUDE`) — AI as a GroupItem alongside `isSTRING`, `isGROUP`
- [ ] **Distributed GroupItem OS** — fields deployable anywhere, messaging across platforms
- [ ] **Display/layout** — GroupItem that handles typesetting and rendering (early design)
- [ ] **File system as GroupItems** — incant represents the file system natively
- [ ] **Incant self-hosting via JIT** — close the loop, shrink the C++ bootstrap layer
- [ ] **Xcode-like development environment written in incant** (very HPDL)

---

## 🗂️ Housekeeping

- [ ] **Working tree cleanup** — `git status` shows `Maps/` deletion uncommitted, `XML/.DS_Store` and `XML/Notions/flags` modified, plus untracked `Tests/` files (recent reorg). Decide what's keep vs drop, commit.
- [ ] **CLAUDE.md ↔ incant.md alignment** — CLAUDE.md now points at incant.md as canonical; keep them in step when bytecode work lands. Old "GUI components" file-org section may need a reread once bytecode is real
- [ ] Update "What Is Incant?" wiki with any design decisions made during bytecode work
- [ ] Bible end-of-session update across all 4 repos

---

## ✅ Done

- [x] Four repos created and public (plg, incant, support, tawk)
- [x] CLAUDE.md in incant repo
- [x] "What Is Incant?" wiki page
- [x] projectBible.md mirrored to incant repo
- [x] Incant parses and interprets itself
- [x] **Phase 0 — BDWGC integration.** `GroupItem` allocation switched from manual `new`/`malloc` to `GC_malloc`. itemFactory replaced with constructor. GC stats added to `stopParsingInput`
- [x] **Phase 1 — `generateCode()` repurposed** as bytecode emitter entry point. Old C++-source emit path being abandoned, not preserved
- [x] **`sourceLine` promoted** from int to GroupItem on `RuleStuff`. `aCTionStatemenT` snapshots line + file. Bytecode emitter will copy onto each instruction
- [x] **Operand-resolution rule decided (option β)** — operands are values or slots; subexpressions linearize into prior instructions
- [x] **Branch target representation decided** — direct GroupItem refs (not offsets), backpatched
- [x] **Phase 2 staging decided** — going straight to vregs (skipping `tempField` step 2a; operands materialize into vregs from the start)
- [x] **Three design questions decided** — handler-as-op-GroupItem (from `Operators` + new `bcOPs`); separate `bcOPs` registry; implicit-next successor (sibling member, branches override)
- [x] **`testByteCode` test case defined** in `XML/WorkingOn/unitTests:116-117` (not yet running end-to-end)
- [x] **`generate` file with old-style emitters** — `gBlocK`, `gFOR`, `gWhilE`, `gDO`, `gDeclare` work in C++-source form (to be rewritten as bytecode emitters)

---

## Key Files

| File | Location | Purpose |
|------|----------|---------|
| `incant.md` | `Groups/` root | Canonical state and design doc — read first |
| `generate` | `XML/WorkingOn/` | Bytecode emitter (in transition from C++-source emit) — `gBlocK`/`gIF`/`gFOR`/etc. dispatch table |
| `setup` | `XML/WorkingOn/` | Registries — cOMMANDs / Operators / pROPERTIEs / Keywords / GroupFields / fILEs. **Bytecode registry to be added here** |
| `grammar` | `XML/WorkingOn/` | incant grammar rules in Grokking registry, plus 32-rule bootstrap shown in header comment |
| `unitTests` | `XML/WorkingOn/` | Test fixtures including `testByteCode` (Phase 2 round-trip target) |
| `Generate.rtn` | `Groups/` root | C++ bridge — `generateCode()`, `genPrint()` (old, will retire), `getType()`, `dataType()` |
| `GroupRules.twk` | `Groups/` root | Main parser + action dispatch — gating hook for bytecode lands here |
| `Bytecode.{h,mm}` | `Groups/` root | **Planned** — interpreter and gating hook |

---

## Notes

**Bytecode is a GroupItem.** Forced by self-hosting goal — incant code must construct, inspect, modify its own IR. Opaque LLVM IR can't fill that role.

**The five-handler minimum** for `testByteCode`: `runGT`, `runMultiply`, `runAssign`, `runBRZ`, `runRET`. New handlers are added only when a test forces them.

**Polymorphism dissolves at emit time.** runOP currently dispatches across five cases at runtime; the bytecode emitter sees the op GroupItem and selects the right specialized handler once, so handlers can stay simple.

**Three open questions block writing the first instruction.** Resolve them on paper before implementing — the answers shape the registry shape, the handler dispatch line, and every instruction's member layout.
