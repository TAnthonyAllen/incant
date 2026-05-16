# TODO.md — PLG/TAWK/Incant Ecosystem

*Read this first every session. Keep it current.*

---

## Tomorrow's wake-up

**Current state (end of 2026-05-16):**
- Incant unit-test suite passes clean. Overnight victory; the work bucket Tony has been grinding on is closed.
- Phase Integrate Tonto recon 2 in progress (or complete pending whatever state at sign-off — check Clod's last report). Recon 1 categorized 22 active Tokf/ files; recon 2 produces the migration shape for the hand-written non-plg-bound .twk files (SymbolType, Types, Tawk).
- Strategy for Phase Integrate locked: clear non-plg-bound hand-written .twk files first, concentrate the actual plg integration tar in the .g/.act pairs (handled in later recons). Tony's design preference is "make the hard thing be the only hard thing left."

**First work options after wake-up read:**

- **Phase Integrate migration on the leaf-like files.** If recon 2 came back clean and migration shape is mechanical, SymbolType.twk and Types.twk are the natural first migration targets. Small, bounded, builds confidence. Migration is Clod-mode work with Tony watching for any surprises.

- **Phase Integrate recon 3.** If recon 2 surfaced anything that warrants more recon before migration (Tawk.twk surface map suggesting dependency analysis, new surfaces flagged in Category 4, etc.), scope a third recon.

- **Phase Bytecode start.** Unit-test gate is cleared. Filling in gIF and gExpressioN as incant generators producing bytecodE attributes is now Clod-workable. Twin POP target: testByteCode runs end-to-end AND generator dispatch demonstrated for the bytecode case. Tony's "BYU and see" preference applies — incant-first emission, C++ fallback only on demonstrated infeasibility.

- **HWF/TODO refresh (if not done end-of-2026-05-16).** If yesterday's session closed with documentation drift still present, refresh first. The bible v2 is current; HWF.md and this file should match.

- **Cha cha session work** — Session 1 (isCLAUDE plus the wake-up scripts thread, plus the operational patterns accumulating). Whenever appetite supports it.

**Reading targets:**
- `Parse/` — plg repo root. All plg source lives here directly.
- `Parse/Backup/` — parked legacy plg material (gitignored)
- `Parse/plgDirectives` — active debugging-directive file (untracked, kept in place)
- `Parse/HWFattic/` — graduated HWF session trims. As of 2026-05-16 end-of-session: Sessions 4 and 5 land here.
- `support/Frame/PLGset.{twk,C,h}` and `support/Frame/CharSet.{twk,C,h}` — sister classes, source of truth
- `Tokf/` — TAWK source, active Phase Integrate target. See bible's TAWK Runtime Replacement section.

**Standing wake-up practice:**
Clod runs `git diff --stat HEAD` in each repo after reading docs. Tony fills context for anything significant.

**Out of scope:** `Groups/GUI/`, `Parse/BeforeRefactor/`, `Parse/Backup/`, archive directories.

**Known current state:**
- Bible v2 mirrored across all four repos (2026-05-15). Phase naming: Phase Generate Tawk, Phase Integrate, Phase Bytecode, Phase JIT.
- jit.md mirrored across all four repos as sibling to bible (2026-05-15).
- Incant POP fully working as of 2026-05-16: runs to completion, test action fires end-to-end, full unit-test suite passes.
- Phase Triage FormatC.twk still uncommitted in tawk (waits on Phase Integrate to produce a working binary).
- Tonto recon 2 results pending or reviewed (whichever applies at wake-up).

---

## 🔥 Immediate (current sprint)

### Phase Integrate — Tokf migration to new plg (ACTIVE)

*The big arc. Incant unit-test suite passing as of 2026-05-16 cleared the precondition. Tonto recon 1 complete; recon 2 in progress on hand-written .twk files.*

*Strategy: clear non-plg-bound hand-written .twk files (SymbolType, Types, Tawk) first via mechanical migrations against known surfaces. Then the .g/.act pairs (Tawk.g/.act, generate.g/.act, parts.g/.act, declare.g/.act, expression.g/.act) — the actual plg integration tar — get their own coordinated arc. Concentrate the hard work in one place.*

*Tony's framing: once Tawk + new plg compiles (even buggy), Tony's Xcode debugger comes online and Tony chips in directly, same shape as overnight unit-test work. Goal is compile, not cleanliness. Bugs after compile are features.*

- [x] Recon 1: surface count and categorization across Tokf/
- [ ] Recon 2: per-file migration shape for SymbolType.twk, Types.twk, Tawk.twk (structured surface map)
- [ ] Recon 3+ as needed: scope per findings
- [ ] Migration: SymbolType.twk (leaf candidate)
- [ ] Migration: Types.twk (leaf candidate, includes PLGset declaration update)
- [ ] Migration: Tawk.twk (mega-cluster, sequenced from surface map)
- [ ] Migration: .g/.act pairs (separate coordinated arc, scoped later)
- [ ] Reach clean compile against new plg
- [ ] Build ~/bin/tokTemp
- [ ] Tony Xcode debug work on integrated build
- [ ] Smoke test (Phase Sandbox)
- [ ] Phase Triage runtime validation
- [ ] Phase Promotion: ~/bin/tok ← tokTemp

### Phase Bytecode — incant bytecode emitter and interpreter (UNBLOCKED 2026-05-16)

*Unit-test precondition cleared. Phase Bytecode Clod work is now safe to begin — failing testByteCode runs can be attributed cleanly to emitter bugs rather than phantom interpreter bugs.*

*Plan: fill in gIF and gExpressioN as incant generators producing bytecodE attributes. Incant-first emission per Tony's design preference. C++ emitter fallback only on demonstrated infeasibility.*

*Twin POP: testByteCode runs end-to-end with `maximus = 26` AND generator dispatch demonstrated for the bytecode case.*

- [ ] Bytecode.mm → Xcode target (manual: drag into incantGUI)
- [ ] Fill in gIF in Generate.rtn — produce bytecodE attributes
- [ ] Fill in gExpressioN in Generate.rtn — produce bytecodE attributes
- [ ] Verify gBlocK, gFOR, gWhilE, gDO interact correctly with new gIF/gExpressioN output
- [ ] Run testByteCode end-to-end
- [ ] Capture bytecode emission shape in jit.md once settled

### CLAUDE.md drift fix (PROMOTED from Housekeeping 2026-05-16)

*Bible v2's resurrection-reader standard applies to all .md files. Incant CLAUDE.md still has pre-flatten Parse/Revision/ paths and old "Phase 2" framing for bytecode work. Primary-standard violation, not housekeeping.*

*Scope: all four repos' CLAUDE.md files. Bring each into agreement with bible v2's directory map, phase naming, and current state.*

*Open design: when this lands, also consider wake-up script structure (per cha cha discussion — session-by-session tailored scripts, not generic templates). Don't over-engineer; minimal fix first.*

- [ ] Audit incant CLAUDE.md against bible v2
- [ ] Audit plg CLAUDE.md against bible v2
- [ ] Audit support CLAUDE.md against bible v2
- [ ] Audit tawk CLAUDE.md against bible v2
- [ ] Add `InProcess/InProcess.xcworkspace` to all CLAUDE.md files (was on Housekeeping)
- [ ] Mirror updates across four repos

### HWF.md graduation ritual — Sessions 4 and 5 to attic (2026-05-16)

*First real test of the graduation ritual. Session 4 (indentation as structure) and Session 5 (PLGset/CharSet split) both substantially settled. Decisions in bible. Definitions earned. Open questions resolved or transferred. Time for the boundary compression.*

- [ ] Verify graduation conditions for Session 4 (all decisions in bible, open questions resolved or transferred)
- [ ] Verify graduation conditions for Session 5 (placement landed, captured in bible Architecture section)
- [ ] Check `Parse/HWFattic/` — anything older that should retire? (Likely empty currently.)
- [ ] Create `session4indentation.md` in HWFattic with Session 4's final trim
- [ ] Create `session5plgsetcharset.md` in HWFattic with Session 5's final trim
- [ ] Remove Session 4 and 5 from HWF.md active sessions
- [ ] Update HWF.md Sessions index — Active section, Graduated section
- [ ] Mirror HWF.md update across four repos

---

## 📋 Next Up

### Bible refresh — minor sync passes (after major arcs settle)

*The bible v2 from 2026-05-15 is substantially current. Small drift items accumulate:*

- [ ] Session 6 (parse error handling) — add to bible's HWF Sessions Pending Work index when refresh happens
- [ ] Session 9 status — Session 9 (wake-up scripts) was originally queued as a separate session; per 2026-05-16 cha cha discussion, folded into Session 1 as a sub-thread rather than separate session. Bible's HWF index needs to reflect this (no Session 9; Session 1 expanded to cover wake-up scripts thread).
- [ ] PLG self-host status — currently hedged "unknown until next attempt." A future Tonto run could confirm cheaply. Worth doing during a low-stakes Tonto window.
- [ ] PLG Next items status pass — happens when Phase Integrate brings us back deep into plg work

### PLG — Self-hosting

- [ ] Action blocks feature
- [ ] Grammar reorganization
- [ ] **Paren-alt decomposition for incant** — port BlockplgAct from PLG. Reference design is the PLG implementation. Low priority.

### Phase Integrate — extended

- [ ] TAWK autopsy remainder (after Phase Integrate completes)
- [ ] Scoped TAWK autopsy (independent): GC inheritance fix, include guard fix — go into legacy Tokf/Tawk.twk directly

### TOK Xcode project — yaml it (+ rename Groups → incant)

*Lives outside all four GitHub repos. No project.yml. Reverse-engineering from existing .pbxproj is the work. May also include renaming target. Housekeeping for whenever.*

### plg xcode link cleanup + yaml refresh

*Post-flatten cosmetic work. Tony manually cleans navigator, then yaml-regen. Build is fine without it.*

### Incant — beyond Phase Bytecode

- [ ] `gPrinT`, `gXpress`, `gDeclare` — fill in remaining stubs once Phase Bytecode shape settles
- [ ] `genPrint` in Generate.rtn — replace with bytecode equivalent
- [ ] `runCall` handler
- [ ] JSON rule — find in attic, POP
- [ ] Bot messaging project
- [ ] Distributed GroupItem messaging design

### Incant documentation conversation

*Tony's WIP on documentation.md surfaces in upcoming session. Untracked in plg repo working tree. Conversation-worthy. Tony "needs a wee bit more time to get ready for it" — postponed 2026-05-16.*

### Cluster D — Bytecode gating hook (LANDED, hook in GroupRules.mm:786)

### Cluster E — DEFINing flag / indent-as-structure ✅ EFFECTIVELY COMPLETE

*Both halves resolved: CodE/DatA atomic parseAction (2026-05-14) and checkSkip double-define fix (2026-05-15). Full unit-test pass (2026-05-16) confirms no regressions.*

### GUI exploration recon (DEFERRED)

### Maps → move to support source

### TOK build machinery lives outside all four GitHub repos

---

## 🔭 Longer Term (HPDL)

- [ ] Claude as native GroupItem field type (`isCLAUDE`) — Session 1 design work pending
- [ ] Incant as distributed virtual OS
- [ ] Go-style channel messaging
- [ ] ZFS-flavored storage
- [ ] Incant display/layout field
- [ ] File system as GroupItems
- [ ] PLG written in Incant
- [ ] Incant self-hosting via JIT — Phase JIT, design pending Session 8
- [ ] Xcode-like development environment written in incant

---

## 🗂️ Housekeeping

- [ ] plg.g `%%` assumption — document/fix
- [ ] doNotGuard accumulation
- [ ] +1000 offset reporting quirk
- [ ] ~/bin/plg dated Nov 2024 — verify or rebuild
- [ ] Support repo update process — needs a look
- [ ] Move Groups/GUI/ to a Reference/ sibling directory
- [ ] Move Groups/Maps/ to support source
- [ ] Accumulated working-tree drift sort: GroupDraw (parked, 76 lines), GroupControl (2), GroupItem (3), Stylish (2), KeyTable May 8 bulk-touch
- [ ] **Xcode-update discipline:** Clean Build Folder before debugging weird runtime behavior after Xcode update.
- [ ] **Visibility-gap discipline:** source-of-truth files MUST live in tracked locations. PLGrgx and PLGset resolutions exemplify the fix.
- [ ] **Tests/ just-in-case stash** — Parse/Tests/ contents are mostly dangling symlinks post-flatten. Tony may want a copy stashed somewhere just-in-case before fully forgetting about it.

---

## ✅ Done

### Recent (2026-05)

- [x] **Incant unit-test suite passing (2026-05-16)** — overnight victory. Closed precondition for Phase Integrate execution and Phase Bytecode Clod work. POP confirms the May 15 checkSkip fix didn't regress anything else.
- [x] **Phase Integrate Tonto recon 1 (2026-05-16)** — surface count and categorization across 22 active Tokf/ files. 9 Cat 1 (already clean, includes FormatC.twk after second-triage), 2 Cat 2 (leaf-like: SymbolType, Types), 10 Cat 3 (entangled: Tawk.twk and the .g/.act cluster), 0 Cat 4. Strategy locked: clear non-plg-bound .twk first, concentrate tar in .g/.act pairs.
- [x] **Bible v2 + jit.md mirrored across four repos (2026-05-15)** — Phase naming convention extended (Phase Generate Tawk, Phase Integrate, Phase Bytecode, Phase JIT), bare-include framing retired, HWFattic and Generators glossary entries added, Incant Core Concept paragraph added, GroupItem prose line added, HWF Sessions 6 and 8 queued.
- [x] **checkSkip double-define bug fixed (2026-05-15)** — testCodE no longer rewinds after aCTionCodE. The `;;` runtogether and `:`/`>` non-user-facing rules earned as residual user-facing constraints. checkSkip indent-mode hardened.
- [x] **PLGmain split from PLGparse (2026-05-15)** — class wrapper owns main(), PLGparse is library citizen only. Linking against PLGparse no longer drags PLGparse's old main() in.
- [x] **plg directory flatten (2026-05-14)** — Parse/Revision/ → Parse/, legacy material to Parse/Backup/, .git relocated. Flatten commit ae06990. PLGrgx tracked into plg repo (139064b).
- [x] **CodE/DatA parseAction approach (2026-05-14, commit a15471c)** — grammar change to handle `{ ... }` field values atomically, bypassing checkSkip indent-state issues.
- [x] **PLGset migrated to support/Frame (2026-05-14, commit 8223af6)** — resolved months of source-of-truth confusion. Sister to CharSet.
- [x] **CharSet rewrite committed (2026-05-14)** — landed with PLGset migration.
- [x] **Buffer migration to constructors (2026-05-13)** — bufferFactory{1,2,3,4} → three real C++ constructors.
- [x] **Phase Triage promoted to live source (2026-05-13)** — Tokf/Tests/FormatC.twk → Tokf/FormatC.twk.
- [x] **Include/changes restore (commit 17982d2, 2026-05-13)**
- [x] **TODO mirror push (2026-05-13)**
- [x] **PLGset / CharSet representation rewrite (2026-05-12)**
- [x] **Phase Triage staged & approved (2026-05-12)**
- [x] **checkSkip comment-in-define-block fix (commit a219689, 2026-05-11)**
- [x] Xcode dev loop working (2026-05-11)
- [x] PLGset.addTest() removed (2026-05-11)
- [x] RuleStuff fix (commit 0835c34, 2026-05-10)
- [x] Cluster B regen + revert (commit 6398920, 2026-05-10)
- [x] Move five working files (commit fec9358, 2026-05-10)
- [x] Buffer source-of-truth verified (2026-05-10)
- [x] Phase Splice complete (commit ef2730d, 2026-05-09)
- [x] PLG `process()` CWD-relative path contract (commit da51193)
- [x] Bible May 7 polishes
- [x] Bible mirror sweep across all four repos
- [x] Incant repo cleanup commit (b5375e8)
- [x] HWF.md trim ritual added
- [x] Verification protocol added

### Earlier

[unchanged]
