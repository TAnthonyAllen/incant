# Bind-by-Body: the Build Plan

**Build-recon stroke, 2026-08-30. Footage first, plan second, no corpus edits and no flip.**
The probe that produced the footage was installed, filmed, and reverted; the tree is at
`589229c` with the fleet at 80 green.

> **ACCEPTANCE LINE, VERBATIM: when the flip lands, `parser(Start)` receives `Start`.**

---

## 1. THE FOOTAGE

Probe at three sites — the interpreted bind in `runAction`, and the argument's treatment
in `saveLocalFields` / `restoreLocalFields`. Format strings deliberately carry **no `%-`
width specifiers**: a `%-` inside a `-%` block *is* the passthrough terminator, and the
first cut of this probe wiped the extern block to **zero** proving it again.

```
ARGBIND action=wfRead  | ruleArg node=0x…1a00 body=0x…2b90 data=6 | BOUND-TO wfCaller node=0x…3080 body=0x…0230 data=5 text=7
ARGBIND action=wfWrite | ruleArg node=0x…1600 body=0x…2780 data=6 | BOUND-TO wfCaller node=0x…7280 body=0x…0230 data=5 text=7
ARGSAVE action=wfDeep  arg=argument node=0x…1200 body=0x…2370 data=6 -- SAVED, NOT BLANKED
ARGSAVE action=wfDeep  arg=argument node=0x…1200 body=0x…2370 data=6 -- SAVED, NOT BLANKED
ARGREST action=wfDeep  arg=argument node=0x…1200 body=0x…2370 data=6 -> popped body written back
ARGREST action=wfDeep  arg=argument node=0x…1200 body=0x…2370 data=6 -> popped body written back
```

**Five facts, each read off the film rather than the source:**

1. **The wrapper is ONE persistent node per action, re-pointed per call.** `wfRead`'s
   `ruleArg` is the same node and the same body on two different invocations with two
   different callers. It is a slot, not a value.
2. **The wrapper's data type is 6 (isGROUP)** while the caller's is 5 — the extra hop, on
   camera.
3. ⚠ **THE CALLER'S NODE IS NOT STABLE ACROSS CALLS; ITS BODY IS.** Two invocations
   passing the same source field `wfCaller` arrive as **different nodes over the same
   body** (`0x…3080` and `0x…7280`, both `body=0x…0230`). That is `aliasTwinT`'s R3
   reappearing in the argument path. **Binding by body binds to the thing that is already
   invariant** — a structural argument for the ruling that nobody had before the film.
4. **A literal argument arrives as a `Token` node** (`wfDeep(2)` → `BOUND-TO Token … text=2`),
   so bind-by-body must have an answer for literals: sharing a Token's body means a write
   through the argument writes the literal's storage. **Named as a build question below.**
5. **The bracket saves and restores the argument and never blanks it**, correctly nested —
   two saves then two restores at depth 2.

### ⚠⚠ THE HEADLINE, AND IT INVERTS ONE CLAUSE OF THE RULING

The ruling stamps as an *eyes-open consequence* that actions will mutate their caller's
field through the argument. **They already do.** Measured:

```
== 2. WRITE through the argument ==
   WRITE argument set to 5
   caller wfCaller after write =  5      (7 = COPY today; 5 = reference)
```

**Reference semantics are not a consequence the flip introduces; they are a property the
flip must PRESERVE.** No corpus can have been written against copy-semantics, because
copy-semantics were never there. That materially lowers the flip's risk.

**And the mechanism is the thing being removed.** Plain `'='` carries no `assign` flag
(`incant/setup:163`), so `runOP`'s `!op.isAssign` is TRUE and the target **is** unwrapped
to the caller. **Today the auto-unwrap is what makes the wrapper transparent.** Retire the
unwrap alone and `argument = 5` silently starts writing the wrapper instead of the caller —
a plausible-wrong-value, exactly the pre-registered failure shape.

**That is the two-half law, measured rather than argued.**

---

## 2. THE EDIT SHAPE

### 2.1 Where the body-share lands

`runAction` (`GroupActions.rtn:1159-1161`) and `jitBindArgRT` (`:372`). Both currently:

```
    if ruleArg = field["argument"]      ruleArg.group = arg;      <- point at
```
become a body-share — the argument node adopts the caller's `groupBody` — with the
**old body pointer preserved for the bracket**, per 2.2.

### 2.2 ⚠ WHAT THE BRACKET MUST CARRY — AND IT IS NOT WHAT IT CARRIES TODAY

Today `saveLocalFields` does `*body = *grup.groupBody` and restore does
`*groupBody = *body` — it copies body **CONTENTS**. That is harmless while the argument
has a body of its own. **Under body-sharing it becomes destructive in both directions:**

- the saved body is now the **caller's** body, and
- restore writes it back at return, **undoing every write the action made through the
  argument** — which is the reference semantics of §1 destroyed at the exit.

**So the bracket must carry the argument's body POINTER, not its body CONTENTS.** The
schema splits:

| population | what the bracket does |
|---|---|
| `isLocal` | unchanged — save and blank contents, restore contents |
| `isArgument` | save and restore the **`groupBody` pointer**, so each activation re-points the argument and none writes another's storage |

**This is the one place the flip touches settled K5/K6/K7 law, so it is where the
certification bites.** `K2` — *recursive, returns its ARGUMENT* — is the row that moves if
this is got wrong, and it is pinned at **7**.

### 2.3 Readers of `isArgument` outside the four exemptions — YES, SEVEN, in three classes

The ruling asked. The census answers, and the answer is not "none":

| class | sites | disposition |
|---|---|---|
| **the four unwrap exemptions** | `GroupActions.rtn:371` · `ruleActions.rtn:1018, 1562, 1633` | **RETIRE with the flip** |
| **the frame-bracket schema** | `GroupActions.rtn:1061, 1611` (the `(isArgument \|\| isLocal)` walks) · `:1631` (`if !grup.isArgument` — the do-not-blank clause) · `jitEmitters.rtn:218` + `jitContext.h:295` (the jit's inherited copy) | **SURVIVE, and 1631 is already correct for bind-by-body** — it is the clause that stops an argument being blanked, which body-sharing makes mandatory rather than merely right |
| **writer, guard, accessor** | `ruleActions.rtn:446` (the flag's only setter) · `ruleActions.rtn:897` · `Instruct.rtn:340` case 10 (an `isArgument` property exposed to incant) | **SURVIVE untouched** |

**So `isArgument` does not retire with the exemptions.** It stops being an unwrap
discriminator and remains a frame-population discriminator, which is a narrowing of
meaning — the same shape as the `*` ruling narrowing the bracket's scope rather than
removing it.

---

## 3. ⚠ THE ONE OPEN QUESTION THE FOOTAGE RAISES — `:=` THROUGH THE ARGUMENT

The ruling says *"`:=` through the argument re-points the argument's holder only."*
**Body-sharing alone does not deliver that**, and the reason is one line:

```
extern GroupItem opSetGroup(GroupItem argument,GroupItem target)
    target.gGroup  = argument;      <- writes the target's BODY
```

If the argument's body IS the caller's body, `:=` through the argument writes the caller's
`gGroup` and the caller sees it. Two ways out, and the choice is a ruling:

- **(a) Amend the clause — `:=` reaches the caller too.** Consistent with uniform reference
  semantics: every channel reaches caller storage, no exceptions to remember. **Recommended**,
  because carving `:=` out reintroduces exactly the kind-keyed arm the ruling abolished.
- **(b) Special-case `:=` on an argument** to rebind the argument node's body pointer rather
  than write body contents. Delivers the clause as written, at the cost of one arm keyed on
  `isArgument` — which is the shape 2.3 was pleased to be narrowing.

**Nothing is built either way. This is the question the flip's charter needs closed.**

Second, smaller: **literals.** `wfDeep(2)` binds a `Token`. Under body-share a write through
the argument writes the token's storage. Today's unwrap has the same exposure, so this is
**not a regression** — but it is newly *visible*, and it deserves a stated position.

---

## 4. PRE-REGISTERED CERTIFICATION SET FOR THE FLIP

Registered now, before the build, so the flip is graded against something it cannot edit.

**Baselines captured BEFORE the first edit**, byte-for-byte, and diffed after:
`pop.sh` full output · `oneTest` · `jsonTest` · `baselineTests` · `kant8T` · `kant8M1o` ·
`incant/frontier` · `decodePop` · `ddPop` · `countPop`.

| # | certification | pass condition |
|---|---|---|
| 1 | **`parser(Start)` receives `Start`** | the acceptance line, verbatim. A wrapper returns a carrier; the two are distinguishable **by `showBody` pointer, never by text** |
| 2 | **the 26 ledger edits, by site** | each of `docs/unwrapRecon.md`'s predicted edits either lands or is explicitly withdrawn **with a reason** — the ledger is the checklist |
| 3 | **the 11 no-consequence sites** | predicted no motion; **any motion is an ESCAPE**, chased before the stroke closes |
| 4 | **K-family byte-identical** | K1 42 · **K2 7** (the argument row — §2.2's guard) · K3 42 · K4 42 · K5 42/42 · K6a 3 · K6b 3 · K6c k6small · K6d 3 · K6e 1/1 · K6f 4 · **K7a/b/c 46** · M1o 42. **Any K-row motion is a STOP, not a note** |
| 5 | **full seal per H12** | `pop.sh` · `decodePop` · `ddPop` · `countPop` · `frontier` · extern canary · `groups.ext` · both repos. **Not fleet-alone** — this touches machinery most fleet rows cannot see |
| 6 | **`incant/derefT` re-pins to R1 ≠ R2** | today they agree and agreement is the defect. This is the row that proves `*` became real |
| 7 | **migration ledger** | every moved row classified **intended flip** or **ESCAPE**, with the ledger's prediction beside it |
| 8 | **degrade/refusal counters** | unchanged — a fallback that starts firing is a silent substitution |

⚠ **THE FAILURE SHAPE IS PRE-REGISTERED AND IT IS NOT A CRASH.** `opDot` already lives
under no-unwrap and produced `Braced 11` where the answer was `3`. **"Ran and looked right"
is inadmissible.** Every certification above is presence-with-value; none is
absence-of-message.

⚠ **AND THE ESCAPE THAT WOULD BE HARDEST TO SEE, named now so it is looked for:** a write
through an argument silently ceasing to reach the caller (§1). It produces no error, moves
no K-row, and the fleet's coverage of it is `wfWrite`-shaped — i.e. **nothing today**. A
fixture for it is owed **before** the flip, not after.

---

## 5. WHAT THIS STROKE DID NOT DO

No corpus edits. No flip. `*` stays quarantined to fixtures. Out of scope and untouched:
clusters 2/3/4 of `goldenDrift`, the J-arm, `lastREF`'s channel redesign.
