# gOp pass-by-reference — Tonto recon

*Read-only recon, 2026-06-05. No edits made. Question: assess the blast radius of
changing `gOp`'s second parameter (`target`) from pass-by-value to pass-by-reference.*

Proposed change:
```
GroupBody.twk:14   GroupItem   &gOp(GroupItem,GroupItem);     // now
GroupBody.twk:14   GroupItem   &gOp(GroupItem,GroupItem&);    // proposed
```

---

## TL;DR

- The mechanism is sound and Tony's `groups.twk` proof is valid (by-ref preserves the op's
  structural work on `target`; by-value drops it).
- **The blast radius is NOT the call site — it is the function-pointer assignment.** `gOp` is
  a C++ function pointer; *every* operator bound to it must share the pointer's signature.
- **All operators are bound via `dlsym` by name — UNTYPED.** The compiler will **not** catch a
  signature mismatch. A missed op method = silent runtime ABI corruption, not a build error.
  This is the single most dangerous fact in this recon.
- Tony's count "7 / 2 / 11" mixes two different mechanisms. Only the **7** (Instruct.rtn) are
  `gOp` operators. The **2 + 11** are non-operator `return target` methods that have the same
  disease but are *not* reached through `gOp` and are *not* fixed by this change.

---

## Counts: bones vs actual

| File | Tony's bones | `return target` statements | Distinct functions | gOp operators among them |
|---|---|---|---|---|
| `Instruct.rtn` | 7 | 8 | 8 | **7** |
| `Commands.rtn` | 2 | 2 | 2 | **0** |
| `GroupActions.rtn` | 11 | 11 | **4** | **0** |

### Instruct.rtn — 7 gOp operators return target (matches Tony's 7)
`opAddAttribute`, `opAssign`, `opCopyList`, `opEnd`, `opPlusEQ`, `opReplace`, `opSetGroup`.
All seven are confirmed `operateMethod=` entries in the `Operators` registry (`incant/setup`).

The 8th `return target` in Instruct.rtn is **`opString`** (line 536) — *not* an operator
(absent from the registry; signature is `opString(GroupItem target, Buffer buffer)` with
target as the **first** param). Out of `gOp` scope. This is the off-by-one in Tony's "7".

### Commands.rtn — 2 non-operator methods
`loadDirectory` (373), `setInternalType` (539). Bound via `immediateAction=` / called as direct
externs. Not operators.

### GroupActions.rtn — 11 statements = 4 functions
`applyDirectives` (1 return), `applyTextDirective` (4 early returns), `makeDataType` (1),
`replaceDirective` (5 early returns). The "11" is statement-count; the **function** count is 4.
None are operators.

**So "2 + 11" = 13 `return target` statements across 6 non-operator functions.** They suffer the
identical pass-by-value loss but are reached via `gMethod`/direct-extern, not `gOp` — this change
does not touch them. (See "gOp vs gMethod" below.)

---

## The real blast radius: the function pointer

`gOp` is a C++ **function pointer**, not a method:
```
GroupBody.twk:14   GroupItem   &gOp(GroupItem,GroupItem);              // source
GroupBody.h:104    GroupItem *(*gOp)(GroupItem *, GroupItem *);        // generated typedef
GroupItem.twk:1229 void setOperat(GroupItem &m(GroupItem,GroupItem))  // typed setter (see note)
```

Changing the pointer's signature means **every function assignable to that slot must match the
new signature** — `GroupItem* opX(GroupItem*, GroupItem*&)`. That is **all 29 `operateMethod=`
operators**, not just the 7 that return target. The other 22 don't benefit but must change
anyway to remain pointer-compatible; they can ignore the reference.

The 29 `operateMethod=` operators (all in Instruct.rtn):
`opMatch opOR opIN opAND opGE opGT opEQ opGet opEnd opGetMember opGetAttribute opAssign opLE
opLT opSetGroup opReplace opSlashEQ opSlash opDot opMinusEQ opMinus opPlusEQ opCopyList
opAddAttribute opPlus opMultiplyEQ opMultiply opDiv opNotEQ`.

**Out of scope:** the 6 `unary ruleMethod=` operators (`opPointer opMinusMinus opDebug
opPlusPlus opLastREF opNOT`) bind to `gMethod`, not `gOp`. Untouched.

### ⚠️ Binding is untyped (dlsym) — no compiler safety net
`operateMethod=opGT` is a setter-attribute. Its dispatch chain:
```
GroupMain.twk:49   operateMethod command  ->  method = ruleMethod
GroupActions.rtn:577  ruleMethod():  operat = dlsym(RTLD_SELF, name);  isOperator = true;
```
`dlsym` returns `void*` — **the operator's address is bound with zero signature checking.**
The typed path (`setOperat`, GroupItem.twk:1229) is *not* used by registry operators.

Consequence: if you change `gOp` to by-ref but miss an op method's `.rtn` signature, **nothing
fails to compile.** The call `op->groupBody->gOp(arg, target)` pushes a `GroupItem*&` (i.e. a
`GroupItem**`) where the stale callee reads a `GroupItem*` value → silent ABI corruption at
runtime. The only defense is exhaustive runtime testing across all 29 operators. The
all-or-nothing edit has no compiler backstop.

---

## Call sites (Q3)

Live dispatch into the operator — **two substrates of the same `runOP`**:
- incant source: `GroupActions.rtn:622` — `if op.isOperator result = op.operat(arg,target);`
- generated C++: `GroupRules.mm:3487` — `result = op->groupBody->gOp(arg,target);`
  (inside `extern "C" GroupItem *runOP` at GroupRules.mm:3466)

`.twk`/`.rtn` is source of truth; the `.mm` is tok output. The brief's "only call site in
Instruct.rtn" is stale on two points: runOP now lives in **GroupActions.rtn** (post-reorg), and
the C++ form in GroupRules.mm is a second site to keep in sync.

At both sites `target` is a named lvalue local (`GroupActions.rtn:611` `target = field[2]`;
`GroupRules.mm:3471` `GroupItem *target = field->get(2)`), so it binds to `GroupItem*&` cleanly —
the brief is correct here. Note target is *reassigned* before the call (group-unbox,
method-invoke, `copyOf` for virtuals), so the reference would expose runOP's post-massage local;
fine, since runOP returns the op's `result`, not `target`.

Dead site: `Aside/tokenTests.rtn:29` `result = operat(field,argument)` — gitignored backup, not
built. Flagged so it doesn't surprise anyone.

---

## Delegation coupling: gOp operators reach into the GroupActions set

The two operators that the generator most cares about delegate *out* to the directive machinery:
```
Instruct.rtn:394  opPlusEQ:  if target.isBUFFER  return applyTextDirective(argument,target);
Instruct.rtn:395  opPlusEQ:  else                return applyDirectives(argument,target);
Instruct.rtn:475  opReplace: return replaceDirective(argument,target);
```
`applyTextDirective`, `applyDirectives`, `replaceDirective` are 3 of the "11 in GroupActions.rtn".
They `return target`. So a *correct* by-ref fix for `opPlusEQ`/`opReplace` must flow through these
delegates — they must become by-ref too, or the directive branch silently reverts to value
semantics. **This is the bridge between the "7 gOp" set and the "11 GroupActions" set: they are
one return-target chain, not two unrelated piles.**

---

## gOp vs gMethod — reconciling the two briefs

- **Part-one wakeup** (to Clay) proposed changing **`gMethod`** (aliased `method`).
- **Part-two Fearless** proposed changing **`gOp`** (aliased `operat`).

These are **two separate function pointers** in GroupBody. The `groups.twk` proof used a
`gMethod`-style 2-arg alias (`refer = byRef`), so it proves the *language mechanism* transfers,
but it exercised a private single-purpose pointer — not the shared, dlsym-bound, 29-assignee
`gOp` slot. The proof does not, by itself, exercise the blast radius.

Fully curing "return target loses mutations" plausibly needs **both** pointers by-ref'd:
- `gOp` by-ref → fixes the 7 operators (this recon).
- `gMethod` by-ref (or per-function direct fixes) → fixes the 6 non-operator methods
  (`loadDirectory`, `setInternalType`, `applyDirectives`, `applyTextDirective`, `makeDataType`,
  `replaceDirective`). Three of these are already pulled in by the opPlusEQ/opReplace delegation
  chain above.

`makeDataType` (and the non-operator `opString`/`opPrint`) take `target` as the **first**
parameter — if brought into a by-ref pass, the `&` goes on param 1, not param 2.

---

## Edit-set if the change proceeds (for planning, not done here)

1. `GroupBody.twk:14` — `gOp` second param → `GroupItem&`.
2. `GroupItem.twk:1229` — `setOperat` pointer-param signature → matching `&` (typed path; keep
   it in sync even though registry uses dlsym).
3. All **29** `operateMethod=` operator definitions in `Instruct.rtn` — second param → `GroupItem&`.
4. The 3 directive delegates (`applyTextDirective`, `applyDirectives`, `replaceDirective`) if
   `opPlusEQ`/`opReplace` are to preserve mutations through their DiR branch.
5. Re-tok the affected `.twk` → `.mm` (GroupBody, GroupItem, GroupRules), then Xcode rebuild.
6. **Runtime regression sweep across all 29 operators** — the dlsym binding gives no compile-time
   coverage. This is the real cost.

Open question for the change (not the recon): is `gOp` worth doing alone, or should `gOp` and
`gMethod` go together since the directive delegation chain straddles both?

---

## Sources touched (all read-only)

`GroupBody.twk:14`, `GroupBody.h:104`, `GroupItem.twk:1229`, `GroupItem.mm:1629`,
`GroupActions.rtn:566-622`, `GroupRules.mm:3466-3491`, `GroupRules.h:196`, `Instruct.rtn`
(op defs + 388-475), `Commands.rtn` (return-target sites), `incant/setup:60-130` (Operators
registry), `GroupMain.twk:38-52`, `projectBible.md:142`.

---

## Implemented — 2026-06-05

Shipped. Gates A+B+C, single commit, full unit-test sweep clean (byte-identical across two runs).

**What landed (final shape):**
- `gOp` second param → `GroupItem&` (`GroupBody.twk:14`).
- All **29** `operateMethod` operators → `GroupItem &target` (`Instruct.rtn`).
- 3 directive delegates `applyDirectives`/`applyTextDirective`/`replaceDirective` → `GroupItem &target` (`GroupActions.rtn`), completing the `opPlusEQ`/`opReplace` DiR chain.
- `setOperat` reshaped to `void setOperat(void *m)` — body hand-casts the dlsym `void*` to the by-ref fnptr via a `-% … %-` **CodePass** block; dlsym binding rewired from `operat = dlsym(name)` to an explicit `setOperat(dlsym(name))` call (`GroupActions.rtn` ruleMethod). `groups.ext` updated to match (the externs file in `data/support/Include/`, committed separately).

**The tok obstacle (worked around, real fix deferred):** tok **cannot render a function-pointer cast that has a reference parameter** — it drops the ref param, emitting malformed `(GroupItem*(*)(GroupItem*,))`. It renders `GroupItem*&` fine in *declarations*; only *cast expressions* break. Two consequences chased down:
1. `operat = X` derives its cast from the **field** type (`gOp`, by-ref fnptr) → always mangles. Sidestepped by binding through an explicit `setOperat()` call, and by typing `setOperat`'s param as `void*` so the call needs no cast.
2. The single unavoidable cast (dlsym `void*` → by-ref fnptr) lives in one `-% … %-` passthrough inside `setOperat`, marked for revision to typed `operat = m` once tok is fixed.

**Deferred (the real fix, "B"):** teach `FormatC.twk` to render reference params in function-pointer cast expressions. Tracked in TODO. Until then the CodePass in `setOperat` is the stopgap.

**Not addressed (separate arc):** `gMethod` was left alone — the non-operator `return target` methods in `Commands.rtn`/`GroupActions.rtn` (`loadDirectory`, `setInternalType`, `makeDataType`) still pass `target` by value. They weren't on the `gOp` path and didn't block anything; revisit if they bite.
