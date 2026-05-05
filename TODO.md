# TODO.md — Incant
*Read this first every session. Keep it current.*

---

## 🔥 Immediate (current sprint)

### Bytecode Generation — the JIT foundation
- [ ] **Refocus** — re-read `generate`, `Generate.rtn`, `testByteCode` and related files. Get the incant mindset back after PLG work. Clay + Clod assist with orientation.
- [ ] **Define bytecode format** — what does one bytecode look like as a GroupItem? Design decisions:
  - Stack-based (Forth-like) vs register-based
  - Opcode representation — GroupItem with tag = opcode name?
  - Operand representation — field references, literals, labels
  - Branch targets — how does conditional jump work?
- [ ] **Implement `gIF`** — conditional branch bytecode generation. Test case: `if righty > 0;`
- [ ] **Implement `gExpressioN`** — arithmetic and comparison. Test case: `maximus = righty * 2;`
- [ ] **Write `interpret()`** — bytecode executor written in incant. Walks bytecode stream, fires each instruction.
- [ ] **Run `testByteCode` end-to-end** — POP. `if righty > 0; maximus = righty * 2;` produces correct result.

---

## 📋 Next Up

### Bytecode Generation — expand
- [ ] `gPrinT` — implement print statement bytecode generation (currently stub, calls `genPrint()` C++ which is old-style printf generator)
- [ ] `gXpress` — expression bytecodes beyond arithmetic (currently just prints "Saw xpress")
- [ ] `gDeclare` — verify field declaration generation is correct
- [ ] More test cases — expand beyond `testByteCode` to cover more statement types
- [ ] `genPrint` in Generate.rtn — old C++ printf generator, replace with bytecode equivalent

### Generator cleanup
- [ ] `gBlocK`, `gFOR`, `gWhilE`, `gDO` — currently working but may be emitting old-style output. Verify they're generating bytecodes not C++ strings.
- [ ] `runGenerated` — verify dispatcher correctly handles all statement types
- [ ] `generateAction` — the `interpret(generated)` call needs `interpret()` to exist first

### Clod assessment (do before touching anything)
- [ ] Read `generate`, `Generate.rtn`, and related incant source files
- [ ] Map: which generator actions are complete, which are stubs, which are old-style
- [ ] Identify any other files involved in bytecode generation
- [ ] Report findings — don't change anything, just assess

---

## 🔭 Longer Term (HPDL — Hard Part Do Later)

- [ ] **JIT compilation** — compiling incant actions to native code. Bytecode interpretation is the step before this.
- [ ] **Threading** — designed but not implemented. Needs JIT first.
- [ ] **Go-style channel messaging** — async GroupItem communication across platforms. HPDL. Ken Thompson would approve.
- [ ] **Claude as native field type** (`isCLAUDE`) — AI as a GroupItem alongside `isSTRING`, `isGROUP` etc. HPDL.
- [ ] **Distributed GroupItem OS** — fields deployable anywhere, messaging across platforms. HPDL.
- [ ] **Display/layout** — GroupItem that handles typesetting and rendering. In early design.
- [ ] **File system as GroupItems** — incant represents the file system natively. HPDL.
- [ ] **Incant self-hosting via JIT** — close the loop, shrink the C++ bootstrap layer. HPDL.
- [ ] **Xcode-like development environment written in incant**. Very HPDL.

---

## 🗂️ Housekeeping

- [ ] Update `CLAUDE.md` to reflect current bytecode generation state
- [ ] Update "What Is Incant?" wiki with any design decisions made during bytecode work
- [ ] Bible end-of-session update (Clay drafts, Clod pushes to all 4 repos)

---

## ✅ Done

- [x] Four repos created and public (plg, incant, support, tawk)
- [x] CLAUDE.md in incant repo
- [x] "What Is Incant?" wiki page
- [x] projectBible.md mirrored to incant repo
- [x] Incant parses and interprets itself
- [x] `generate` file with generator actions (`gBlocK`, `gFOR`, `gWhilE`, `gDO` working)
- [x] `generateCode()` C++ method wired to incant `generatE` action
- [x] `testByteCode` test case defined (not yet passing end-to-end)

---

## Key Files

| File | Location | Purpose |
|------|----------|---------|
| `generate` | Groups/ | Generator actions — gIF, gFOR, gBlocK etc. |
| `Generate.rtn` | Groups/ | C++ bridge — generateCode(), genPrint(), getType() |
| `grammar` | Groups/ | Bootstrap rules — 32 seed rules |
| `GroupRules.twk` | Groups/ | Main incant parser and runtime |
| `testByteCode` | Groups/ | Test case for bytecode generation |

---

## Sub-goal: Get Clod Fluent in Incant

Clod has everything he needs to start writing incant: the grammar, the wiki, working examples in `generate`, and `testByteCode` as a concrete target. Damn the torpedoes — just start.

Suggested onboarding path:
1. Read `grammar`, `generate`, `Generate.rtn`, `testByteCode` — orient, don't touch
2. Write a simple test action using `for` and `print` — something known to work
3. Fix `gIF` — first real bytecode task, guided by Clay's design decisions
4. Fix `gExpressioN` — second task
5. Write `interpret()` in incant — the demon test

First attempts being slightly off is fine. Clod corrects fast. The goal is fluency through doing.

---

## Notes

**The bytecode design question** is the current design frontier. The instruction set hasn't been fully defined. The `testByteCode` test drives the minimum viable bytecode set: load, store, compare, branch, arithmetic.

**Stack-based feels right** — aligns with Forth's minimalism and incant's field-as-everything philosophy. A bytecode is a GroupItem. An instruction stream is a list of GroupItems. `interpret()` walks the list.

**gIF and gExpressioN are the blockers** — everything else in `testByteCode` builds on these. Design these two first, implement, test, then expand.
