# TODO.md — Incant
*Read this first every session. Keep it current.*

---

## 🔥 Immediate (current sprint)

### testByteCode POP — get it green
- [ ] Drag `Bytecode.mm` into the incantGUI Xcode target (manual)
- [ ] Rewrite `gIF` emitter — produce a `bytecodE` attribute on the IF GroupItem (currently a stub: `print "generate if statement"`)
- [ ] Rewrite `gExpressioN` emitter — emit comparison + arithmetic bytecode (currently a stub: `print "Need to work out how to generate an expression"`)
- [ ] Run `testByteCode` end-to-end. Target: `if righty > 0; maximus = righty * 2;` produces `runGT, runBRZ, runMultiply, runAssign, runRET` and `maximus = 26`

### Generator audit (pre-rewrite)
- [ ] Verify `gBlocK`, `gFOR`, `gWhilE`, `gDO` — are they emitting bytecode GroupItems or still old-style C++ source strings? Fix where they're old-style.
- [ ] Verify `runGenerated` dispatcher routes all statement kinds correctly
- [ ] Verify `gDeclare` field-declaration generation

---

## 📋 Next Up

### Bytecode emitter — expand
- [ ] `gPrinT` — implement proper bytecode emit (currently delegates to old `genPrint()` C++ printf generator in `Generate.rtn`)
- [ ] `gXpress` — beyond the "Saw xpress" stub
- [ ] `genPrint` in `Generate.rtn` — replace with bytecode equivalent once `gPrinT` lands
- [ ] `runCall` handler — implement when first test case needs cross-method calls
- [ ] More test cases — expand beyond `testByteCode` to cover statement kinds incrementally

### Other incant work
- [ ] JSON rule — find in attic, get running, POP
- [ ] Bot messaging project — assess what's salvageable in InProcess/Bot
- [ ] Distributed GroupItem messaging — design conversation with Tony + Clay

---

## 🔭 Longer Term (HPDL — Hard Part Do Later)

- [ ] **JIT compilation** — bytecode → LLVM IR → native. Phase 3.
- [ ] **Threading** — designed but not implemented. Needs JIT first.
- [ ] **Go-style channel messaging** — async GroupItem communication across platforms.
- [ ] **Claude as native field type** (`isCLAUDE`) — AI as a GroupItem alongside `isSTRING`, `isGROUP` etc. HWF Session 1 is unpacking this.
- [ ] **Distributed GroupItem OS** — fields deployable anywhere, location transparent messaging.
- [ ] **Display/layout field** — GroupItem that handles typesetting and rendering. GUI arc material in `XML/`.
- [ ] **File system as GroupItems** — incant represents the file system natively.
- [ ] **Incant self-hosting via JIT** — close the loop, shrink the C++ bootstrap.
- [ ] **Xcode-like development environment written in incant.**

---

## 🗂️ Housekeeping

- [ ] XML directory recon — formalize what's in the 11 non-WorkingOn subdirs (per Tonto's day-3 recon, captured in HWF context). Most are foundational GUI material; a few have stale path references that will need updating before reactivation.

---

## ✅ Done (recent)

### Phase 2 design decisions — settled
- [x] Bytecodes are GroupItems (no separate vreg objects — "a virtual register is just a GroupItem field")
- [x] Op identity: instruction's tag IS the op GroupItem itself, drawn from `Operators` (for `>`, `*`, `=`) plus `bcOPs` (for `bcBR`, `bcBRZ`, `bcRET`)
- [x] Two registries — `Operators` and `bcOPs` separate; user code walking `Operators` should not see control-flow ops
- [x] Implicit-next dispatch — instructions are members in execution order; branches reassign `grup` mid-loop

### Phase 2 implementation — built
- [x] `interpret()` written in incant (in `XML/WorkingOn/bytecode`)
- [x] C++ handlers in `Bytecode.{h,mm}` — `runBR`, `runBRZ`, `runRET`, plus shims
- [x] `bcOPs` registry defined in `setup`
- [x] Gating hook at `GroupRules.mm:786` — `bytecodE` attribute → bytecode interpret path; falls through to `gMethod` when no bytecode (safe no-op until emitter produces bytecodE attributes)

### Earlier
- [x] Phase 0 — BDWGC integration
- [x] Phase 1 — `generateCode` repurposed as bytecode emitter entry point (placeholder C++-source emit path being abandoned, not preserved)
- [x] Incant parses and interprets itself
- [x] `generate` file with generator actions (`gBlocK`, `gFOR`, `gWhilE`, `gDO` working in spirit; bytecode-emit verification pending)
- [x] `testByteCode` test case defined (not yet passing end-to-end)
- [x] CLAUDE.md, TODO.md, projectBible.md in incant repo
- [x] "What Is Incant?" wiki page
- [x] Repo cleanup (2026-05-07) — Maps/ symlink to support, BackupXML/ removed, .DS_Store untracked, Tests/ added to .gitignore

---

## Key Files

| File | Location | Purpose |
|------|----------|---------|
| `generate` | `XML/WorkingOn/` | Generator actions — `gIF`, `gFOR`, `gBlocK` etc. |
| `bytecode` | `XML/WorkingOn/` | `interpret()` written in incant |
| `Generate.rtn` | `Groups/` | C++ bridge — `generateCode()`, `genPrint()`, `getType()` |
| `Bytecode.{h,mm}` | `Groups/` | C++ bytecode op handlers |
| `grammar` | `Groups/` | Bootstrap rules — 32 seed rules |
| `GroupRules.{twk,mm}` | `Groups/` | Main parser/runtime; bytecode gating hook at line 786 |
| `unitTests` | `XML/WorkingOn/` | `testByteCode` lives here at line 116 |

---

## Notes

**Stack-based feels right** — aligns with Forth's minimalism and incant's
field-as-everything philosophy. A bytecode is a GroupItem. An instruction
stream is a list of GroupItems. `interpret()` walks the list.

**`gIF` and `gExpressioN` are the blockers** — everything else in
`testByteCode` builds on these. The design is settled (see Done).
Implementation is the remaining gap.
