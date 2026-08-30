# The No-Unwrap Migration Ledger

**Stroke 3, run 2026-08-30, against the FINISHED rulings table.** Pre-registered
ledger, not a list: every site carries *location · classification · predicted edit ·
predicted observable consequence*, and sites predicted to have **no consequence say so
explicitly**, because a prediction that names its own gap outranks one that passes.

> **ACCEPTANCE LINE, PINNED VERBATIM: when the flip lands, `parser(Start)` receives `Start`.**

---

## 0. The table this ledger is written against

| construct | ruling |
|---|---|
| `argument` binding | **RULED bind-the-field** |
| `return` boundary | **OPEN-GATED behind K5/K6** — census read-only, **excluded from this charter** |
| `=` | **shared body** — measured, `incant/aliasTwinT` R1–R3 |
| `:=` | **sole rebind channel**, and it does **not** propagate — measured, R4/R4c |
| `*` | one step, null-as-testable-nothing — built, `incant/derefT` |
| condition position | rides `isInitialized` |

---

## 1. Headline numbers

| | count |
|---|---|
| raw `isGROUP` hits in the `.rtn`/`.twk` layer | **80** |
| — writers (`isGROUP = true`) | 9 |
| — switch cases (type dispatch) | 6 |
| — prose / comments | 15 |
| — a test with no unwrap, and one write | 2 |
| **unwrap-decision SITES SURVEYED** | **37** |
| **edits predicted** | **26** |
| **no-consequence, stated** | **11** |

**H11 control, pre-registered and satisfied:** the census must return `runOP`'s two
unwrap lines and `runShortCircuit`'s two, or it is void. All four returned
(`GroupActions.rtn:1253, 1254, 1503, 1514`).

⚠ **The strict grep found 34 and was WRONG BY FIVE IN BOTH DIRECTIONS.** It swept in
three comments, one write and one bare test; it missed five follow-me loops and five
accessor descents whose `.group` is not on the same line as their `isGROUP`. That is
rule H9 exactly — a census matches the idiom family, not the surface form — and the
hits were read by eye because 80 is small enough to.

---

## 2. The four switch sites — the flip itself

| # | location | classification | predicted edit | predicted observable consequence |
|---|---|---|---|---|
| 1 | `GroupActions.rtn:1253` | runOP target | delete, behind the switch | **2,483 measured unwraps stop.** Every operand that today arrives dereferenced arrives as the field |
| 2 | `GroupActions.rtn:1254` | runOP arg | delete, behind the switch | **2,964 measured unwraps stop** |
| 3 | `GroupActions.rtn:1503` | runShortCircuit target | delete, behind the switch | **NO OBSERVABLE CONSEQUENCE IN THIS CORPUS.** 31 entries, **zero** isGROUP arrivals — measured. It goes behind the switch anyway: the asymmetry is real the day someone writes `if a.group && b`, and a divergence between `&&` and `+` is exactly the class nothing is aimed at |
| 4 | `GroupActions.rtn:1514` | runShortCircuit arg | delete, behind the switch | same — **no consequence, stated** |

**Retiring in the same stroke:** the four dead `!isPointer` clauses (measured **zero**
suppressions against a 5,447-unwrap positive control), and the switch's own obituary,
pre-registered as the migration's closing stroke.

---

## 3. The follow-me loops — five sites, and they are the sharpest class

A `while … isGROUP … = group` chases an arbitrary number of hops. Under the ruling each
becomes **at most one explicit, bounded step**, or the subject arrives already
dereferenced by a `*` in source.

| # | location | what it walks | predicted edit | predicted consequence |
|---|---|---|---|---|
| 5 | `ruleActions.rtn:700` | `while LoopOn.isGROUP {` — aCTionFOR's subject | one bounded step, or `*` at the call | **iterate/for subjects change arity of descent.** The class Clay's amendment 4 named; closes the two-meanings filing |
| 6 | `ruleActions.rtn:1592` | `while grup.isGROUP` — aCTionExpressioN | one bounded step | nested sub-expressions stop collapsing silently |
| 7 | `Commands.rtn:1337` | `while isGROUP grup = group;` | one bounded step | affects the command layer's subject resolution |
| 8 | `Bytecode.twk:158` | `while loopOn.isGROUP` | one bounded step | bytecode loop subject |
| 9 | `GroupItem.twk:389` | `while block && block.isGROUP && !isMethod && !isRule` | **KEEP — no consequence** | it is a *typed* descent to a block, already guarded on two flags; it is structure, not implicit read-through |

---

## 4. The `!isArgument` exemptions — four sites, and they are the wrapper's fingerprints

`GroupActions.rtn:371` · `ruleActions.rtn:1018` · `ruleActions.rtn:1562` ·
`ruleActions.rtn:1633`

Each reads *"unwrap this, unless it is the argument."* **They exist because the argument
is a wrapper**, and they are the clearest existing evidence for the bind-the-field
ruling: four separate authors have already had to special-case the formal.

**Predicted edit: all four clauses become vacuous and retire with the wrapper.**
**Predicted consequence: none while the wrapper stands — they are already doing nothing
to non-arguments that the flip will not do to everything.** This is a *no-consequence
until the two-half change lands* row, and it is stated rather than left silent.

---

## 5. The accessor layer — six sites, all KEEP

`GroupItem.twk:466 · 484 · 582 · 592 · 600 · 673` — `getCount` / `getGroup` /
`getItem` / `getNumber` / `getObject` / `getText` each descending one hop through a
group.

**Classification: KEEP, and this is the ledger's most load-bearing "no consequence".**
These are not implicit read-through in an expression; they are the *definition* of what
a typed accessor returns, and `*` is implemented in terms of exactly this hop
(`opDeref` returns `result.group`). Deleting them deletes the operator too.

⚠ **The discriminator, so nobody re-litigates it site by site:** a hop is IMPLICIT
READ-THROUGH when it happens because a value reached an operator, and STRUCTURE when it
happens because a caller asked for a specific typed thing by name. The 37 sites split on
that line and nothing else.

---

## 6. The per-action unwraps — 22 sites, edits predicted

`Instruct.rtn:199` (opDebug — already an explicit `unWrap`, becomes `*` at the call
site) · `GroupActions.rtn:615` · `ruleActions.rtn:8, 90, 375, 693, 1139, 1172, 1275,
1279, 1334, 1339, 1354, 1355, 1376, 1418` · `Commands.rtn:96` ·
`GroupItem.twk:1802` · `Debug.rtn:46` (display read — **no consequence**, it prints a
tag) · `Commands.rtn:502` (a *test*, not an unwrap — **no consequence**) ·
`ruleActions.rtn:1185` (a *write* — **no consequence**).

`Instruct.rtn:1259` is **`opDeref` itself** and is the successor, not a customer.

---

## 7. The pre-registered FAILURE SHAPE, and the instrument rule that follows

⚠ **Bear-trap #35's class: a PLAUSIBLE WRONG VALUE, not a refusal.** `opDot` already
lives under no-unwrap and what it produced was not a crash — it was `Braced 11` where the
answer was `3`. So the migration's expected failure is a reading that *answers*.

**Therefore: "ran and looked right" is INADMISSIBLE for every site-class in this ledger.**
Each class needs an instrument that would catch a plausible-wrong:

| class | instrument that would catch a plausible-wrong |
|---|---|
| the four switch sites | `incant/derefT` re-pinned to **R1 ≠ R2** — today they agree, and agreement is the defect |
| follow-me loops | a fixture asserting descent **DEPTH by name**, not just a value — a walk that stops early agrees with itself |
| `!isArgument` / wrapper | the acceptance line: **`parser(Start)` receives `Start`** — a wrapper returns a carrier, and the two are distinguishable by `showBody` pointer, never by text |
| accessor layer | negative control: remove the hop, the operator itself must go red |
| per-action unwraps | each needs a value that a one-hop-short read would get *wrong*, not merely *empty* |

⚠ **H12 — WHICH FLEET ROWS READ EACH REGION, because the fleet is necessary and not
sufficient.** `ruleActions.rtn` and `GroupActions.rtn` are read by essentially every row
(`oneTest`, `jsonTest`, `parseClass`, `anyOrNumT`, `census`, the genParse odometer,
`countPop`). **`GroupItem.twk`'s accessor layer and `Bytecode.twk` are thinner**, and
`incant/baselineTests`'s content is read by **NOTHING** — see citizen `goldenDrift`,
whose clause 3 exists to close exactly that hole **before** the flip needs it.

---

## 8. Charter item: the `ruleArg.group = argument` wrapper — FINDING

**The mechanism, with its address.** `GroupActions.rtn:1150-1152` (and `:372` for the
coded-rule path):

```
    if ruleArg = field["argument"]
        if argument ruleArg.group = result = argument;
        else        ruleArg.group = result = field;
```

The formal `argument` is a **real field on the action node**, whose `group` is pointed at
the caller's node. So an action's `argument` is *a field pointing at* the caller's field —
which is precisely why implicit read-through exists: every use must go one hop.

**Is name-map binding reachable with existing `saveLocalFields` machinery?**

**FINDING: NO — IT WANTS A REBUILD, and the reason is scope, not enumeration.**

Two facts, both read rather than assumed:

1. **Enumeration would survive.** `saveLocalFields`/`restoreLocalFields`
   (`GroupActions.rtn:1534, 1051`) walk `(isArgument || isLocal) && !noPrint` and restore
   **positionally** off a stak. Dropping arguments from that population changes both
   sides symmetrically, so the frame walk itself does not break.
2. **Scope would not.** Today there is exactly **one** `argument` node per action, and
   recursion is handled by **copying its body onto a stack** — `if !grup.isArgument` is
   the clause that deliberately does *not* blank it. A name map resolving the formal
   directly to the caller's field needs **per-activation resolution**, and the only
   per-activation mechanism in the tree is that body stak. There is no scope chain to
   hang a name map on.

**So the two-half change stands as ruled: the wrapper and the unwrap retire in the same
stroke or not at all** — and the wrapper half is a build, not a rewire. The flip is not
this stroke; this is the finding.

⚠ **The corroboration is already in the tree and it is four-fold:** the four
`!isArgument` exemptions in §4. Four separate sites had to special-case the formal to
stop it being dereferenced. **A construct that every unwrap site must exempt is not a
value — it is a wrapper wearing one**, and that is the argument for bind-the-field made
by the code rather than by anybody's reasoning.

---

## 9. Controls, measured not assumed

| control | measured | status |
|---|---|---|
| `isIterator` suppressions | **2,815** | live, genuine exemption — the nothing-owed column |
| `isAssign` suppressions | **8** — `incant/frontier` ×6, `incant/mintT` ×2 | ✅ **VERIFIED BY HAND, 1:1** — see below |
| `isPointer` suppressions | **0**, both sites | dead — clauses retire with the flip |
| positive control | 5,447 unwraps fired | the probe was live, so the zero is a measurement |

### 9a. The `isAssign` eight, accounted one for one

The only `assign`-flagged operators are `'=/'` (`opGetMember`) and `'<-'` (`opRebind`),
`incant/setup:149` and `:168`. Counting **re-assignments onto an already-bound target**
in the two fixtures:

| fixture | targets | re-assignments |
|---|---|---|
| `incant/frontier` | `frLive` ×7, five others ×1 | **6** |
| `incant/mintT` | `fresh` ×2, `codeCopy` ×2 | **2** |

**6 + 2 = 8, matching the measured suppressions exactly.** So all eight are `<-`
writing onto a holder that already carries a group, and the clause is doing precisely
its job: **a rebind must write the holder's slot, not reach through it.** The first
`<-` onto a fresh target does not fire it, because the target is not yet `isGROUP` —
which is why `frLive`'s seven uses yield six suppressions and not seven.

⚠ **THE CLAUSE IS LIVE AND CORRECT, AND IT STILL RETIRES — WHICH IS A DIFFERENT
DISPOSITION FROM `!isPointer` AND MUST NOT BE FILED WITH IT.** `!isPointer` retires
because it never fired. `!op.isAssign` retires because **the line it guards goes away**,
and the behaviour it was protecting — do not reach through an assignment target —
becomes the unconditional default. **Nothing is lost; the exemption becomes the rule.**
That is the whole no-unwrap ruling visible in one clause.

## 10. Standing constraints carried into the next stroke

- `*` stays **quarantined to fixtures** until the flip. `incant/derefT` filmed why.
- The four unwrap lines **and** `runShortCircuit`'s pair go behind **one** switch.
- The switch's obituary is **pre-registered as the migration's closing stroke**, with the
  dead `!isPointer` clauses.
- The two `lastREF` lines in `opPlusPlus` **stay reverted**.
- `lastREF`'s channel redesign is a **named ledger row OUTSIDE the charter** — adjacency
  is not scope.
- The `return` boundary stays **OPEN-GATED behind K5/K6**, censused read-only, excluded.
