# Bytecode branch mechanism — investigation + decision (2026-06-09)

> **⚠️ SUPERSEDED (2026-06-10).** The conclusion below — "the branch isn't expressible in
> interpreted incant, move the dispatch loop to C++" — was **overtaken by events.** After the
> unique-label emit (`bcLabel<n>` via `:=`) and the `byRef`/`:=` pointer-semantics work landed,
> the cleaned-up **incant** `interpretBC` (`incant/generate`) takes the branch correctly:
> `testByteCode` false→11, `testIfElse`→26/7. **The C++ dispatch loop was never built and is
> not needed** — the interpreter stays in incant. Kept as the historical reasoning; the
> "Confirmed working" findings (byRef, opDot unwrap, runBRZ retrieval) all still stand.

*Why conditional branches (`bcBRZ`/`bcBR`) couldn't be made to work from
interpreted incant, what got fixed along the way, and the decision: **move the
bytecode dispatch loop to C++** while the IR stays homoiconic.*

## The goal

`testByteCode` (`if righty > 0; maximus = righty * 2;`) → `maximus = 11` on the
false path (`righty ≤ 0`), `26` on the true path; `testIfElse`
(`…; else maximus = 7;`) → `26`/`7`. The true path always passed by *fall-through*
coincidence; the false/`else` paths require the branch to actually redirect.

## Confirmed working (keep)

- **`gIF` emit** (then + else): direct label emit (no shared `dst`), else arm
  gets the `revisedList` descent. `testIfElse` emits a correct 13-op `bcLIST`.
- **`runGT`/`opGT` cond**: `cond=0` false / `cond=1` true. *Not* the bug.
- **`runBRZ` retrieval**: returns the real `endLabel` member.
- **`byRef` flag + `:=` pointer semantics** (2026-06-09): new GroupBody flag
  `byRef`; `opSetGroup` stamps it (sticky), `setGroup` + `opAssign` honor it
  (store by reference, no `setContent` copy). See `opSetGroup`/`opAssign`
  (Instruct.rtn), `setGroup` (GroupItem.twk). (Audit TODO: sticky `byRef` aliasing.)
- **`opDot` reference unwrap** (Instruct.rtn): `.nexT`/`.prioR`/`.firsT`/`.lasT`
  use `target.<link>` directly (case 401-404), and the deref loop stops at the
  referenced node: `while target && target.isGROUP && target.group` — peels
  *every* reference level, stops *at* the member (whose `.group` is 0), instead
  of over-derefing to 0.

These all stay. They were necessary; they just weren't sufficient.

## Why the branch can't be done in interpreted incant (the wall)

The design premise was "branch ops override by reassigning `grup` mid-loop."
That is **not expressible** with incant's loop + local-variable semantics. Every
variant was tried and failed:

1. **for-loop + `grup = result`** (copy): the for-loop re-binds `grup` via
   `nextGroup` each iteration, *ignoring* the body's reassignment. Branch never
   taken (true→26 by fall-through, false→26).
2. **for-loop + `grup := result`** (byRef reference): still ignored —
   `grup := result` makes `grup` *reference* the target (`grup.group = target`),
   but the for-loop's `grup = nextGroup(grup)` advance operates on `grup`'s **own**
   links, not the referenced target's. false→26 (verified in a full rebuild).
3. **explicit `while` cursor**: can't terminate. `grup` is a persistent local
   node; `while grup != 0` is always true because incant's `=`/`:=` **cannot set
   a local to null** (both skip on a null argument). Same for `result` — when a
   handler returns null, `result = runByteFn(grup)` leaves `result` stale, so
   `if result` is unreliable. Endless loop.

Root, in one line: **`grup` can never *become* the target node** (assignment
only makes it *reference* the target), and **a local can't be nulled** to
terminate — both of which a branch fundamentally needs.

## Decision: C++ dispatch loop, IR stays homoiconic

Representation vs walker are two different things; conflating them burned the
time. The bytecodes **stay GroupItems** — inspectable and constructable from
incant; the IR's homoiconicity is intact. Only the **walker** moves to C++:

- The op handlers are **already C++** (`runGT`, `runBRZ`, `runStoreField`, …), so
  a C++ dispatch loop calling them is *more* consistent, not a deviation.
- In C++ the branch is trivial: `grup = target` is a pointer assignment, `null`
  terminates — every wall above evaporates.
- The interpreted walk is temporary scaffolding anyway; the **JIT** supersedes
  the loop. The IR (the durable artifact) is unaffected.

## C++ dispatch loop — spec

Replaces the interpreted `interpretBC` (incant/generate). Lives with the
handlers (Bytecode.twk), as a C++ extern. ~15 lines:

```
extern GroupItem interpretBC(GroupItem body)
{
GroupItem   grup, result, next;
    body +% opStack;                 // hang the operand stack as the incant
                                     // version did (handlers reach it via
                                     // opStackOf -> body.getAttribute("opStack"))
    grup = <first member of body>;   // e.g. body.firstInList / body.nextGroup(0)
    while grup {
        next   = <successor of grup>;    // capture BEFORE dispatch (handlers walk
                                         // lists; avoid shared-cursor clobber).
                                         // node-based (grup.nextInParent / nextGroup)
                                         // OR the DoubleLink safe-pattern.
        result = runByteFn(grup);        // run the op's interpret handler
        if result   grup = result;       // BRANCH: jump to the returned target member
        else        grup = next;         // fall through to the successor
    }
    // (optional) if opStack not empty -> warn
    return body;
}
```

Notes for the Xcode session:
- **Member walk**: the for-loop used `nextGroup` (walks `nextInParent`); the
  members are `nextInParent`-linked. Either reuse `nextGroup`, or walk the
  `groupList` DoubleLink directly (CLAUDE.md "safe pattern") to dodge any
  nested-call clobber on shared `next()` state. Capturing `next` before
  `runByteFn` matters either way.
- **`result` is the branch signal**: a handler returns the target *member* node
  to branch, or null to fall through. In C++ the null test is honest (unlike the
  incant local). `runBRZ`/`runBR` already return the label member via the
  retrieval logic; with the opDot unwrap in place that resolves to the real node.
- **Swap-in**: remove/disable the interpreted `interpretBC` in `incant/generate`
  (and the dormant one in `incant/bytecode`) so `generateAction`'s
  `interpretBC(generated)` call resolves to the C++ extern (register it the way
  the other Bytecode externs are).

## Tree state (2026-06-09) + scaffolding to clear

- `byRef` machinery + `opDot` unwrap: in source (and tok'd into the build).
- `interpretBC` (incant/generate): currently the for-loop — gives `maximus = 26`
  on the true path, terminates; **does not branch** (to be replaced by the C++ loop).
- `testByteCode`: restored to `if righty > 0`.
- **Debug scaffolding still in:** `runByteFn` capture-into-`result` in
  `GroupActions.rtn` (behaviorally identical; revert when convenient), and
  `oneTest:21` `stop()` commented out so `testByteCode` runs. Restore both when
  the arc closes.
