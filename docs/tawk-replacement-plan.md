# Tawk replacement-binary recon + plan (2026-06-10, Tonto)

*Read-only archaeology of where the "replace `~/bin/tok`" arc stands and what it
would take to finish. Synthesizes: `Tokf/CLAUDE.md`, `Tokf/TODO.md`,
`Groups/docs/tawk-tok-compile-frontier.md` (2026-05-31, the live frontier),
`Tokf/docs/fieldResolutionRecon.md` (2026-05-20, Tawk internals), and
`projectBible.md` (TAWK Runtime Replacement / TAWK Current State / Kind Enum).
Findings only — nothing here was edited in source. Filed in `Groups/docs/`
beside its companion `tawk-tok-compile-frontier.md`; arguably belongs in
`Tokf/docs/` (both do — see Finding F1-loc).*

---

## TL;DR

`~/bin/tok` is the **prebuilt, working** TAWK binary built from the **legacy**
`Tokf/Tawk.twk` (7325 lines, old PLGparse API). The replacement is a binary built
from the **new-PLG-generated** Tawk source. The generation step is clean; the
**tok-compile of that generated source is not** — it crashes partway through stale
action bodies. The remaining work to a *working* replacement is a mechanical
**action-body grind**, then a Tests/-sandbox build → `~/bin/tokTemp` → equivalence
check → promote to `~/bin/tok`. The hard architectural blocker (per-alternative
"named options") is **already solved**. Improvements (autopsy, resolution-layer
refactors) are strictly separate and must not touch the working binary.

---

## Q1 — `Tawk.twk` vs `Tawk.regen.twk`: two things, meant to converge

**Two different files, one target state.**

| | Legacy `Tokf/Tawk.twk` | Regen Tawk source |
|---|---|---|
| Origin | hand-maintained | `plg Tawk.g` (new PLG) |
| Size | 7325 lines | ~1851 lines, 177 rules |
| API | **legacy** PLGparse (kind=5/7, `void*` casts, `*TawkNow` callbacks) | **new** PLG (kind=6 bare strings) |
| Status | **toks with `~/bin/tok`; this is what the working binary is built from** | toks **partway then crashes** on stale action bodies |
| Role | the safety-net source (commit `89a3abc`, old format) | the target for Phase Integrate |

They **converge** when the regen-derived source compiles to a `Tawk.C`/`Tawk.h`
that builds a working tok. They are **not converged today**: `plg Tawk.g` →
clean (exit 0), but `tok <regen>` → does not complete `Tawk.C` (it has produced a
real 156-line `Tawk.h` up to the crash point).

**Finding F1 — the regen file's name is documented two ways (stale).** The bible's
*TAWK Current State* and *Runtime Replacement Phase A* still call it
`Tokf/Tawk.regen.twk`. But the `.regen` suffix was **removed ~May 19** — `PLG.process()`
now writes `<base>.twk` directly to the invocation directory (CWD). So `plg Tawk.g`
run from `Tokf/` would **overwrite the legacy `Tokf/Tawk.twk`** — which is exactly
why the live frontier work runs from **`Tokf/Tests/`**. Net: "Tawk.regen.twk" in the
bible is a stale name; the real regen output is `Tawk.twk` produced under `Tokf/Tests/`.
(The Tests/ sandbox is now the *only* thing standing between a regen run and the
legacy source — see Risk R2.)

---

## Q2 — Steps to build a new tok binary from current Tokf source

Composite ladder from `Tokf/TODO.md` (Phase Integrate list), bible *Runtime
Replacement* Phases A–E, and the `tawk-tok-compile-frontier.md` loop:

1. **Generate** — `cd Tokf/Tests; plg Tawk.g` → `Tawk.twk` (regen). **DONE / clean (exit 0).**
2. **Tok-compile the regen** — `tok Tawk.twk` → `Tawk.C` + `Tawk.h`. **IN PROGRESS — the grind.**
   The architectural blocker (actions belong to one *alternative* of a rule, not the
   whole rule — "named options") is **SOLVED + committed** (Alternative carries
   immediate/defer action; PLGparse.generateRules distributes numbered shells onto
   alternatives; PLGrule.match fires per-alternative; PLGitem gained `deferAlt`).
   Parse is now 100% clean (0 FAILs, 0 `ERROR Inheritance`) up to a **codegen crash**.
   Remaining: **method-by-method reconciliation of the action bodies to the new
   PLGitem surface** in the 5 Tokf `.act` files. Mappings already applied:
   `iTEM.testParser`→bare `X`; `iTEM.test.*`→gone; `X.amount`→`getAmount()`/settable
   `amount`; `X.run()`→`X.runDeferred(this)`; `plgStart`→`cursor`; `hash[PLGitem]`→
   `hash[plgitem.toString()]` (raw PLGitem key **segfaults** tok codegen); old `.`-
   separated option bodies split. **Still owed (Tony listing offline):** `type.flag4`
   (+ sibling `flagN`?) and the removed-field set `currentTest`, `saveTest`, `guardSet`,
   `processUpTo`, `leftBalance`/`rightBalance`, `skipOverMatch`, `isIgnored`,
   `errorMessage` (these were the 121 unresolved fields when the old tool-source was regenerated).
3. **Callback port (bible Phase B)** — ~50+ `*TawkNow`/`*TawkAct` callbacks: signatures
   change to `(PLGparse state, PLGitem iTEM)`, children reached via `iTEM.children["label"]`.
   (Overlaps with the .act grind — the named-options work is the structural half of this.)
4. **TOK Xcode reconfig** — point the TOK Xcode target at the `Tests/`-derived sources (Tony's seat).
5. **Clean compile against new plg** (bible Phase C) → **build `~/bin/tokTemp`** (the candidate binary).
6. **Tony Xcode debug on the integrated build** — Tony's framing: *goal is compile, not
   cleanliness; once it compiles even buggy, the Xcode debugger comes online and bugs-after-
   compile are features.*
7. **Phase Sandbox smoke test** → **Phase Triage runtime validation** (Tests/, vs `~/bin/tok`).
8. **Phase Promotion** — `~/bin/tok ← tokTemp`. The only point `~/bin/tok` changes.

**Finding F2 — two migration routes coexist without an explicit "which is live."**
(a) the **regen route** above (`plg Tawk.g` → grind the `.act` bodies → tok), which the
2026-05-31 frontier doc treats as active; and (b) a **legacy-source hand-migration** —
`Tokf/TODO`'s "Tawk.twk invalid-surface migration: ~587 sites across 5 surface types,
next major work item." These are two paths to the same new-API Tawk. **Settled (Clay, 2026-06-10): the `.act`-grind /
regen route is the committed path; the legacy 587-site hand-migration is retired** — it predates
the regen being clean.

---

## Q3 — Test gate: how we know `tokTemp` ≡ `~/bin/tok`

Named in the docs, **not fully specified** (Finding F3):

- **Bible Phase D**: *"Tests/ sandbox verification vs `~/bin/tok`."* The `Tokf/Tests/`
  directory is the mandatory proving ground.
- **TODO**: *"Smoke test (Phase Sandbox)"* then *"Phase Triage runtime validation."*
- **Determinism precedent**: `plg Tawk.g` is **MD5-bit-identical across runs** — so the
  *input* to tok is reproducible. The natural equivalence test is therefore: **run both
  `tokTemp` and `~/bin/tok` over the same `.twk` corpus and diff the generated `.C`/`.h`.**
- **Known-working anchors** to seed that corpus (bible "Known Working Tests"):
  `,678→Max`, `Grammar/Testing.g` (90/91 bytes), `Grammar/plg.g` (39 rules),
  `Tokf/Tawk.g` (200 rules, 177 populated, 5 includes 100%).

**F3 — settled (Clay, 2026-06-10).** Byte-identity is the **wrong** bar: the new API means
emitted text differs by design. **The gate is functional: re-tok the whole ecosystem with
`tokTemp` and confirm everything still builds and runs.** Seed corpus = the files we tok
regularly — **`plg.g`, `Tawk.g`, `GroupItem.twk`, `GroupRules.twk`**. That is the
functional-equivalence bar.

---

## Q4 — Known risks

- **R1 — `~/bin/tok` is the bootstrap safety net; broken TAWK can't fix itself.** TAWK is
  written in TAWK. If `~/bin/tok` is replaced by a bad `tokTemp`, you can't re-tok your way
  out. **Promotion (step 8) is the single dangerous moment** and must be gated on a real
  equivalence pass + a kept backup of the old `~/bin/tok`.
- **R2 — Tests/ sandbox rule + the `.regen`-suffix removal makes overwrite easy.** Bible:
  *"never touch `Tokf/Tawk.twk` before Tests/ proves it."* Because `plg` now writes
  `<base>.twk` to CWD (no `.regen` suffix), **running `plg Tawk.g` from `Tokf/` overwrites
  the legacy source.** All regen work MUST stay in `Tokf/Tests/`. (`Tokf/Tests/` is gitignored
  per TODO — working-tree state is the deliverable; nothing to recover from git if clobbered.)
- **R3 — Phase Integrate precondition (incant unit-test cleanup).** Bible: execution "waits
  on incant unit-test cleanup completing first." **Possibly stale framing** (F4) — that
  precondition was written for the legacy-Tokf-migration approach and the incant-as-baseline
  story; it's unclear it gates the regen/`.act`-grind path, which is pure plg+tok mechanics.
  Don't assume it blocks; confirm.
- **R4 — debugging the grind is constrained.** From the frontier doc: **lldb can't open files
  in this sandbox**, and a **debug-tok build is itself blocked** (the tool-source `Tokf/Tawk.C`
  has 121 stale-field errors). So you can't easily get a tok backtrace for a codegen segfault
  in-sandbox — the working method is **bisect the regen `Tawk.twk` to the crashing method**,
  isolate it in a minimal `class Tawk extends PLGparse { <body> }`, find the construct, fix
  the `.act`. Slow but the only road until tok itself debug-builds.
- **R5 — two crash classes to keep distinct.** Parse FAILs (stale field/method → cascades to
  `ERROR Inheritance` from field decls escaping the class) vs codegen SEGFAULT (exit 139, often
  no FAILs — tok dies generating C++ for an unresolvable construct, e.g. `hash[PLGitem]`).
- **R6 — latent resolution-layer tar babies** (`fieldResolutionRecon.md` §5) that will surface
  once the new Tawk *runs*: `findSymbol` likely-bug (§5.4 — three branches `return symbol`/null
  where they look like `return field.symbol`); `foundAncestor` shared-mutable non-reentrant
  state (§5.1); `fillComponentFields` `nullInstance` negative cache with no invalidation (§5.3);
  `checkOverload` 170-line goto-heavy in-place mutation (§5.7); method dual-registration (§5.5).
  None block compile; all are Track-B refactor candidates that could bite at runtime.
- **R7 — kind-enum / API mismatch is the substance of the port.** legacy kind=5 (kRuleRef,
  void*) → new kind=6 (bare string); legacy kind=7 (kLit, void*) → new kind=1 (kLit, bare
  string); legacy kind=3 still kSet but **spec semantics differ**; new kinds kAny=4/kEof=5/
  kKeyTable=7/kCondition=8/kVariable=9/kUpTo=10/kBalanced=11. The semantics-differ cases (kind=3)
  are where subtle behavioral bugs hide vs pure surface renames.

---

## Q5 — Minimal staged plan

### Track A — get a working replacement binary (do this, in order)

> Single objective: **`tok` rebuilt from new-PLG-generated Tawk, promoted to `~/bin/tok`,
> producing equivalent results.** Compile-first; cleanliness is Track B.

1. **Finish the `.act` action-body grind** in `Tokf/Tests/` until `tok Tawk.twk` completes
   `Tawk.C` + `Tawk.h` with no FAIL/segfault. Drive with the bisect loop (R4). Close the
   owed mappings (`type.flag4` + the removed-field set) as Tony supplies them.
2. **(F2 settled — Clay, 2026-06-10.)** The `.act`-grind / regen route **is** the committed
   path; the legacy 587-site hand-migration is **retired** (it predates the regen being clean).
   No re-decision needed — proceed on the grind.
3. **TOK Xcode reconfig** to the `Tests/`-derived sources; reach **clean compile against new
   plg**; build **`~/bin/tokTemp`** (NOT over `~/bin/tok`).
4. **Tony Xcode debug pass** on the integrated build (bugs-after-compile are features).
5. **Run the functional equivalence gate** (F3 settled — Clay, 2026-06-10): **re-tok the
   regular corpus with `tokTemp` — `plg.g`, `Tawk.g`, `GroupItem.twk`, `GroupRules.twk` —
   and confirm everything still builds and runs.** Byte-identity is NOT the bar (new API →
   emitted text differs by design). Then Phase Sandbox smoke → Phase Triage runtime
   validation, in `Tokf/Tests/`.
6. **Back up `~/bin/tok`** — copy the working binary aside (e.g. `~/bin/tok.bak-<date>`)
   **before touching it**. Named step on purpose: this is the bootstrap safety net (R1) —
   a bad promote can't re-tok its way out.
7. **Promote** — `~/bin/tok ← tokTemp`. Only after step 5 is green **and** step 6's backup exists.

### Track B — improvements, separate, slow, no disruption to the working binary

> Never on the critical path; never touches the to-be-promoted binary mid-flight.

- **Scoped TAWK autopsy** (GC-inheritance fix, include-guard fix) — bible says these go
  **directly into legacy `Tokf/Tawk.twk`**, explicitly *independent of Phase Integrate*.
- **Resolution-layer tar babies** (R6 / recon §5–6): `findSymbol` fix, `foundAncestor`
  return-struct refactor, `nullInstance` invalidation, `checkOverload` split,
  `#searchForField-` macro → method. All "after a working binary," all behind tests.
- **Durable named-options design** — move the uncommitted `IncludeplgNow` stopgap (PLG.twk,
  routes `.act`→`attachActions`) into the real `plg.g`/`action.g` named-options design pass
  (pending — see `plg-wakeup.md §11`).
- **Hardcoded include paths** in generated output, plg modifier-coverage audit, etc. (TODO).

---

## Findings index (Tonto — flagged, not chased)

- **F1** — `Tawk.regen.twk` is a stale name in the bible; real regen output is `Tawk.twk`
  under `Tokf/Tests/` (the `.regen` suffix was dropped ~May 19).
- **F1-loc** — TAWK docs are split across repos: this plan + `tawk-tok-compile-frontier.md`
  live in `Groups/docs/`, but `fieldResolutionRecon.md`/`CLAUDE.md`/`TODO.md` are in `Tokf/`.
  A future cleanup could consolidate TAWK docs under `Tokf/docs/`.
- **F2 — RESOLVED (Clay, 2026-06-10)**: the `.act`-grind / regen route is the committed path;
  the legacy 587-site hand-migration is retired (predates the regen being clean).
- **F3 — RESOLVED (Clay, 2026-06-10)**: functional gate, not byte-identity — re-tok the
  ecosystem (`plg.g`, `Tawk.g`, `GroupItem.twk`, `GroupRules.twk`) with `tokTemp`; everything
  must still build and run.
- **F4** — the "incant unit-test cleanup" precondition may be stale relative to the regen path.
- **F5** — **the bible is ~1 day behind the frontier doc.** Bible *Phase Generate Tawk* (2026-05-30,
  recently folded in from Parse's bible) still calls the `generateRules` class-body/extern split
  (`ERROR Inheritance`) *the* blocker; the frontier doc (2026-05-31) shows that **solved** via
  named-options, with the live blocker now the action-body grind. (Self-note: the just-completed
  md-sweep propagated that one-day-stale blocker text into the Groups bible — worth a touch-up at
  the next bible refresh, which the TODO already tracks.)
