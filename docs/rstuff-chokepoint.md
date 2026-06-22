# rStuff get/set chokepoint — brief for Clay

**Date:** 2026-06-20 · **Author:** Clod (for Clay) · **Status:** instrumentation refactor in flight

## Why this exists

JSON rules (`JSONarray`/`JSONlist`/`JSONitem` and friends) now pass **every**
`jsonTest` case when run **individually**. Running them **in sequence** buggers
the parse. Tony's hypothesis: stale `rStuff` state leaking between runs — "rStuff
setting is doing the pooching."

We are **not** fixing the bug yet. We are routing all `rStuff` field access through
a getter/setter pair so there is **one observable chokepoint**: when rStuff goes
sideways, set a breakpoint/log in `getRStuff`/`setRStuff` and walk back to the wrong
turn. Behavior-neutral, fully reversible (`getStuff` is **kept**, not deleted).

## Where the sequential run falls off the cliff (located 2026-06-20)

With the chokepoint in and the build green, all 10 JSON cases pass **individually**
(`ok`), including nested objects and the combined Google-Fonts shape — i.e. the
chokepoint did no harm. The **sequential** run, however, falls off a cliff, and the
cliff is **not JSON content**:

- Minimal repro: define `testJSON` (an action with locals `argument`, `field`), then
  call it **twice on the same trivial input**:
  ```
  testJSON('{"a":"b"}');   ->  ok
  testJSON('{"a":"b"}');   ->  ok
  <next statement>         ->  parser SILENT-SPINS forever
  ```
- **Both invocations succeed** (both print `ok`). The infinite loop is on whatever is
  parsed **after the 2nd invocation** (a `print`, the next `testJSON`, or `stop()` —
  doesn't matter). Output is static during the spin (silent loop, not a runaway print).
- **Content-independent** — two identical `{"a":"b"}` calls reproduce it. So the trigger
  is **re-invocation of a define'd action**, not anything about multi-key objects, arrays,
  or nesting.
- The spin emits **no `getRStuff` warnings** — the loop is in the action/parse machinery,
  **not** in the chokepoint.

**This almost certainly unifies both open symptoms:** the jsonTest sequential hang and the
`baselineTests` `list` regression (`nextGroup: ... does not contain a list` on the **2nd**
invocation of the `list` rule action) are the same shape — *second invocation of a
define'd/rule action corrupts state*. That points straight at **`processActions`
re-invocation / rule-action local-field handling** — the engine Tony rewrote offline
(`GroupActions.rtn`), which my re-tok compiled into the binary **for the first time** (the
committed `.mm` was stale: it still contained the old `processActions` and the deleted
directive suite). So the sequential bug Tony reported is reproduced and now precisely
located; the chokepoint did not fix it (it was never meant to — it's the tracing tool).

**Candidate lead (for Clay to confirm, not assumed):** a rule's `rStuff` state left dirty
after the 1st action run — e.g. `inProcess` not reset — would make the *next* parse of that
rule mis-detect recursion and loop. That's exactly the kind of wrong turn the `setRStuff`
chokepoint exists to catch: breakpoint `setRStuff`/`getRStuff`, run the two-identical-call
repro, and watch which write leaves `inProcess`/`parentStuff` live across the boundary.

## The mechanism, as reverse-engineered from the codegen

`parse(pStuff)` does not run against the node's `rStuff` field directly. It runs
against the **local** `ruleStuff` that `getStuff` returns:

```
RuleStuff *GroupItem::getStuff(RuleStuff *pStuff) {
    if (!rStuff) rStuff = new RuleStuff(this);
    if (rStuff->rule != this || rStuff->inProcess) {
        stuff = new RuleStuff(rStuff);   // CLONE — kept in a local, NOT written back to rStuff
        stuff->rule = this; }
    else stuff = rStuff;
    stuff->parentStuff = pStuff;         // parent linkage stamped on the local
    if (!stuff->followed) stuff->getWhatFollows();
    return stuff;
}
```

`parse` then mutates `kount`/`isOK`/`inProcess`/`sukcess`/`parentStuff` **on that
local**. The node's `rStuff` field is left as a template.

**This clone-kept-in-a-local is THE isolation mechanism.** It is what lets the same
rule node be mid-parse at two nesting depths at once (recursive rules) without the
inner invocation stomping the outer's `kount`/`parentStuff`.

## The landmine (why a naive no-arg parse would break)

Tony's original sketch was to drop the `parse` argument and have parse read the
`rStuff` **field** (`ruleStuff = rStuff`). That throws away the isolation:

- The nested cases — `{"a":["x","y"]}`, `{"a":{"b":"c"}}` — are **same-node re-entry**:
  `JSONarray`/`JSONlist` appears inside itself, so the *same rule node* is parsing at
  depth 2 while still live at depth 1. That is exactly Bug A/B in `jsonTest`.
- If parse reads the field, the inner invocation overwrites the `rStuff` the outer
  is still walking → wrong `parentStuff` → wrong `parentLabel` → poochification.

`parentLabel` matters because (per Tony) the parse gets confused by rule *instances*
when recursive rules are involved; it must be set right or it's "lots and lots of
trouble." So the no-arg path was **descoped**. We are keeping `getStuff` and its
local-carried clone, and only inserting the chokepoint underneath.

## What is actually being changed

Add to `GroupItem`:

```
RuleStuff getRStuff()              // ensure-and-fetch; warns if it had to create (diagnostic)
{ if !rStuff { cerr "getRStuff:",tag,"no rStuff - creating":; setRStuff(new(this)); } return rStuff; }

void setRStuff(RuleStuff stuff)    // the one writer
{ rStuff = stuff; }
```

Route **every** writer of the `rStuff` field through `setRStuff`, and `getStuff`'s
ensure-and-fetch through `getRStuff`. Existence-check *reads* (`if !rStuff`) stay raw
so we don't get warn-spam from probes.

### Writer inventory (source files; `.mm` is tok-generated)

| Site | Current | Receiver | Note |
|---|---|---|---|
| `GroupItem.twk:45` | `rStuff = new(this)` | `this` | copy ctor; `grup` is last-mentioned → resolution hazard |
| `GroupItem.twk:609` | `if !rStuff rStuff = new(this)` | `this` | becomes `getRStuff()` |
| `GroupItem.twk:1309` | `if !rStuff rStuff = new(this)` | `this` | `setRuleStuff` |
| `GroupItem.twk:1311` | `rStuff = new(rStuff)` | `this` | `setRuleStuff` clone-on-`rule != this` |
| `RuleStuff.twk:122` | `label.rStuff = this` | `label` | `checkInput` |
| `ruleActions.rtn:162` | `rStuff = new(NewGroup)` | `NewGroup` | |
| `ruleActions.rtn:192` | `grup.rStuff = item.rStuff` | `grup` | **alias** — prime pooch suspect |
| `ruleActions.rtn:224` | `rStuff = new(newMember)` | `newMember` | guard reads `newMember.rStuff.max/min` |
| `Commands.rtn:392` | `rStuff = new(target)` | `target` | `isRule` command |

### Resolution hazard (the tok wrinkle)

`setRStuff` is a `GroupItem` method. A **bare** `setRStuff(...)` dispatches on the
last-mentioned `GroupItem` field, else `this` — so a bare call where `grup`/`item`/
`NewGroup` is last-mentioned would silently set the **wrong** node's rStuff. Every
converted site uses an **explicit receiver** and is verified by diffing the
regenerated `.mm` against the original (the only delta should be `X->rStuff = Y`
becoming `X->setRStuff(Y)` with the **same X**).

## Open questions for Clay

1. **The real fix** (the sword-fight). The cliff is located: the **2nd invocation of a
   define'd action** silently spins on the *next* statement (repro in the section above;
   content-independent). Breakpoint `setRStuff`/`getRStuff`, run the two-identical-call
   repro, find which write leaves stale `inProcess`/`parentStuff` across the boundary —
   then decide the reset discipline (reset on parse entry? after action return? on
   `stop()`?). Confirm whether the `baselineTests` `list` `nextGroup` error shares this
   root cause (very likely the same `processActions` re-invocation bug).
2. **If we ever do go no-arg** (Tony's original idea), where should per-invocation
   isolation live — local-carried (today), or field + save/restore around parse?
   The same-node re-entry landmine above is the constraint.
3. `getStuff`'s `JSONarray`/`JSONlist`/`JSONitem` breakpoint stubs are still in
   place — Tony's been circling this exact spot. Worth keeping as live probes?
