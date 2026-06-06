# Bytecode dispatch — build plan (2026-06-05, dinner-break checkpoint)

## Goal
Make `interpretBC` actually invoke its per-op handlers (`runPushField`, `runGT`,
`runStoreField`, …) so the bytecode interpreter runs end-to-end. POP target:
`testByteCode` → **`maximus = 26`**.

## What already works (committed earlier today: gOp by-ref `f23e0f3`/`5f3ac6e`; rest uncommitted)
- `interpretMethod=` is registered as a bootCommand (GroupMain) and its binder lives
  in `GroupActions.rtn` (alpha-slotted between `fAIL` and `loadRegistryFromString`).
- The binder runs at definition time, creates a persistent `interpret` child on the op,
  `setMethod`s the dlsym'd handler onto it. **Confirmed working** — `bcPushField` etc.
  carry a method-bound `interpret` child.
- Registry flipped: bcOPs/Operators use `interpretMethod=runX` (in `incant/setup`).
- The store slot-fix (`tgt.group=target` + `runStoreField` derefs `target->getGroup()`),
  the operator-skip guard, and `dumpField` (in `Utilities`) are all in.

## The blocker
`interpretBC` can't *invoke* the bound child's method from incant:
- `handler = grup.interpret; handler(grup)` (two-step) → `=`→`setContent` copies
  data/lists but **NOT** `gMethod`/`gOp` → handler is method-less → no dispatch. **(the poochifier)**
- `grup.interpret(grup)` (chained) → parse error (can't invoke a dot-access of a *named child*).
- `handler := grup.interpret; handler(grup)` → runOP unboxes target/arg, not the op → no dispatch.

`grup.method(grup)` *would* invoke (known accessor → direct `grup->gMethod(grup)` pointer call,
no runOP, no copy) — but `gMethod` shares a union with `gOp`, so it clobbers operators' `opGT`.

---

## Path A — `gByteFn` slot (targeted, the safe fallback)
A dedicated method-pointer on the op, outside the gMethod/gOp union; dispatched by a one-line
C++ primitive so incant never invokes a raw pointer and runOP never gets a vote (so no
`isOperator` shadowing).

**Gate A1 (rebuild):**
- `GroupBody.twk`: new field `GroupItem &gByteFn(GroupItem);` — its own storage, NOT in the
  gMethod/gOp union (so operators keep `opGT`).
- `groups.ext`: alias `byteFn → gByteFn`; decl `setByteFn`, decl `runByteFn`.
- `GroupItem.twk`: `void setByteFn(GroupItem &m(GroupItem)){ byteFn = m; }`.
- `GroupActions.rtn` (alpha-slot near `runAction`): the primitive
  `runByteFn(GroupItem instr){ if instr.byteFn return instr.byteFn(instr); return null; }`.
- Rewire the `interpretMethod` binder: drop the `interpret`-child / `addString`, instead
  `setByteFn(dlsym(RTLD_SELF,name))` on the op (grup). 1-arg cast → tok renders clean.

**Gate A2 (interpreted, run):**
- `interpretBC`: `result = runByteFn(grup)` per op (labels with null `gByteFn` → no-op → fall through).
- Run → expect `maximus = 26`. Verify on first run that `runByteFn(grup)` fires (it's the spot
  the child form died, but a plain extern call is the safe shape).

Cost: one GroupBody field + setter + primitive + binder rewire. Rebuild-gated. No general
blast radius. Leaves the poochifier unfixed (just routed around).

---

## Path B — fix the poochifier (root cure; **obviates Path A if it lands**)
If `setContent` carried the method binding, the two-step `handler = grup.interpret; handler(grup)`
we already have would just work — no new slot, no primitive, and **every** incant idiom that
copies a method-bearing field stops silently dropping the method.

**Tony's constraints (2026-06-05):**
- `setContent` has a *huge* blast radius (every `=`). There may be an old reason method-copy
  was excluded — possibly stale after many incarnations, but treat with respect.
- `contents()` is the safe lever: parameterize it (overload / default arg) so existing
  `item.contents()` callers are untouched (zero blast radius). New mode(s) can ask about
  data / list / method / registry / combos:
  `contents() = DATA|LIST|REGISTRY (today)`, `contents(WITH_METHOD) = …|METHOD`.

**Open fork — where the binding *copy* lives:**
- **(a)** guarded branch inside `setContent`, gated by `contents(WITH_METHOD)`. Small effective
  blast (only method-bearing copies, which today lose the method = arguably already a bug),
  but still inside setContent.
- **(b)** a separate method-aware copy used only by the dispatch (and opt-in callers). Zero
  general blast radius; setContent untouched. (This is nearly Path A in spirit — a targeted copy.)

**The copy itself** (when a binding is present): carry the union slot + its type flag, which
`copyData`/`copyListFrom` never touch:
```
if ( item->groupBody->flags.instructType ) {
    groupBody->gMethod = item->groupBody->gMethod;          // the union slot (method OR operator)
    groupBody->flags.instructType = item->groupBody->flags.instructType;
}
```
Placement note: a method-*only* field (no data/list) hits setContent's `!contents()` branch
(`text = item.tag`) today, so a copy added to the *else* branch alone is skipped — hence the
`contents(WITH_METHOD)` detection, or an end-of-function guarded copy.

**Blast-radius gate:** whichever variant — full `oneTest` + bootstrap sweep required, because
it changes (or can change) method-copy semantics. Watch for code that *relied* on `=` dropping
a method.

---

## Recommendation / sequencing
1. Decide the (a)/(b) fork for Path B with Clay.
2. Try **Path B** first — it's the root cure and the shortcut to `maximus = 26` (the dispatch
   code already exists; only `setContent`/`contents` changes). If the sweep is clean and
   `maximus = 26` falls out, **Path A is unnecessary** — delete the `interpretMethod` binder's
   child-creation is the only cleanup.
3. If Path B's blast radius bites (something relied on the drop), fall back to **Path A** — fully
   specified above, low-risk, no general semantics change.

## Scratch state to clean up either way
- `interpretBC` debug scaffolding already stripped; it's the clean two-step now.
- Dead `incant/bytecode` copy still present (salvage its doc header, then delete).
- `righty`×4 registry-mutation bug still open (bare `bcPushField += child` mutating the shared
  virtual op) — independent of dispatch, revisit after.
