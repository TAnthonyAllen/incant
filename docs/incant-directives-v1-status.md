# Incant Directives — v1 status — 2026-05-27 (Clod/Tony/Clay session)

Companion to `docs/incant-directives-HWF.md` (the design). This records what
shipped, where it lives, how to reproduce it, and the decisions left open.

---

## What's green

The v1 directive mechanism works end-to-end. Three-state POP **passed**, plus two
things beyond the v1 ask:

- **active** → `dirTarget += DiRgreeting` then `dirTarget()` prints the directive's
  line at the top of the body, then the body.
- **inactive** → `dirTarget()` with nothing applied is silent (clean body only).
- **idempotent** → re-applying the same directive does not stack (one fire, not two).
- **`at=ending`** → directive lands at the bottom of the body (verified).
- **composition** → two directives (`DiRgreeting` start + `DiRfarewell` end) coexist
  on one target. (Emergent from the `DiRs`-list design; not required for v1.)

No regression: `oneTest` runs clean to completion.

## How it works (mechanism)

- A **directive** is a `DiR`-prefixed coded field carrying its snippet as CodE, e.g.
  `DiRgreeting at=starting code={ print "...":; };`. `at=starting` → top of body
  (default), `at=ending` → bottom.
- `target += DiRfoo` → `opPlusEQ` sees the `DiR` prefix → `applyDirectives`.
- `applyDirectives` registers the directive in the target's `DiRs` list (idempotent,
  lookup-by-tag) and, when newly registered, calls `spliceDirectives` once.
- `spliceDirectives` builds the target/directive BlocKs if needed and **moves** the
  directive's `Lines` statements into the target's `Lines` (front/back per `at`).
- The splice happens **once** because the executed BlocK is built once and cached
  (`get("BlocK")` is stable across runs — confirmed by address). No processCode hook.

## How to reproduce

```
xcodebuild -scheme Groups -configuration Debug build   # (from TOK/)
incant <driver>                                         # driver includes unitTests
```
Driver runs `testDirective();` (defined in `XML/WorkingOn/unitTests`, "Working On"
section). Fixtures there: `dirTarget`, `DiRgreeting` (at=starting), `DiRfarewell`
(at=ending), `testDirective`.

## ⚠️ WHERE THE CODE LIVES — and the clobber hazard

The feature is **hand-applied in `GroupRules.mm` + `GroupRules.h`**, NOT in the
`.rtn` sources. Methods:

- `opPlusEQ` — added the `DiR`-prefix dispatch (would back-port to `Instruct.rtn`).
- `applyDirectives` — NEW (would back-port to `Instruct.rtn`).
- `spliceDirectives` — NEW (would back-port to `Instruct.rtn`).
- `GroupRules.h` — 2 hand-added decls (tok regenerates these on back-port).
- `XML/WorkingOn/unitTests` — fixtures added; old incant `applyDirectives` rule
  removed (per Tony).

**Re-toking `tok GroupRules.twk groupDirectives` WILL WIPE all of the above** — it
regenerates `GroupRules.mm` from the `.rtn` sources, which do not contain the
feature. Verified: a re-tok strips anything not in source. **Do not re-tok
`GroupRules.twk` until the durability decision below is made.** Proven working copies
are backed up at `BeforeSave/*.directives-proven`.

## Durability decision — DEFERRED (the open fork)

How to make the feature survive re-tok. Two routes, newly forked by Tony's emerging
"dev directives for development, idempotent" working model:

1. **Fold into `.rtn` source** (post-POP graduation). Edits repoed `Instruct.rtn` +
   `ruleActions.rtn`; re-tok then reproduces the feature. **Blocker/risk:**
   `spliceDirectives` does low-level node surgery — `stmt.parent = 0`,
   `nextInParent`/`priorInParent` walks, `groupList.firstInList`/`lastInList`,
   `insertGroup`. Unknown whether those node fields are expressible in `.rtn`/tok.
   Needs an empirical tok probe.
2. **Express as a dev directive** (Tony's model). Keep `.rtn` source clean; the
   feature lives in a directive file that tok re-applies idempotently → not clobbered.
   Dogfoods the very idempotency idea this feature came from. **Unknowns:** can a
   directive add whole new functions *and* inject into multiple existing methods, and
   how do two directive files (`groupDirectives` + a dev file) both apply given
   `tok sourceFile directivesFile` takes one?

## Deferred feature work

- **`DiR`-prefix ⟺ no-method invariant** (`aCTionDefinE` / `ruleActions.rtn`) — not
  yet added. Fail-loud guard at registration.
- **Multi-target directives.** Statements are *moved*, not deep-copied (the copy ctor
  `GroupItem(GroupItem*)` drops `instructType`, and `aCTionBlocK` skips non-methods),
  so a directive's BlocK is gutted on first splice → currently single-target. Fix:
  deep-clone preserving `instructType`, or fix the copy ctor.
- **Named-hook v1.1** — `// <label>` text scan for mid-body insertion (HWF reserved).
- **Incant-native port** — gated on incant being able to express the node moves.

## Key runtime findings (also in Clod memory)

- Executed BlocK is built once and cached; `get("BlocK")` stable across runs.
  processCode fires every run but its fresh results go unused.
- `getLabelGroup("Lines")` dereferences (`getGroup()`) to the real statement group;
  `get("Lines")` returns the undereferenced field. `aCTionBlocK` iterates the former.
- `addGroup` copies a node that still has a parent (`new GroupItem`), and the copy
  loses `instructType` → silently skipped by `aCTionBlocK`. Clear `parent` to move an
  executable node intact.
