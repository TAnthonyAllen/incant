# Bare-Lookup Census — a sorting exhibit for Tony

*2026-08-03, Clod. Step 4 deliverable of Clay's register-pivot brief. **Nothing on this list gets
an attribute or an edit ahead of Tony's pass.** The dispositions are proposals.*

> **This is the first explicit record of which deep names are public.** It feeds the Layer-1
> question-3 law (`docs/searchMinion.md`) and, per Clay, the taxonomy ruling from below.

---

## The rule this census is measured against — CORRECTED, and the correction matters

**Not** *"members are not added to the currentRegistry"* as a vague statement — measured precisely
on 2026-08-03 by walking the lists directly (`incant/listWalk`, no `[]`, no `get()`):

```
Generating's own list   49 entries — `generator` is one of them, gXpress is NOT
generator's own list    10 entries — gXpress, emitBC, dumpBC, generatE and the six g* handlers
```

So a **member is on its parent's list and not on the registry's**. Bare lookup searches registries,
therefore:

| reach | works? |
|---|---|
| bare `generator` (attribute depth, on the registry list) | ✅ |
| `generator["gXpress"]` (parent index) | ✅ |
| bare `gXpress` (member depth) | ❌ **silently nothing, at exit 0** |

⚠ **`get()` does not descend** (Tony, confirmed by measurement — `Generating["gXpress"]` returns
nothing). An earlier claim that it did was an artifact of testing existence with `if x.taG;`, which
returns a fresh temporary and is **always truthy**. No list corruption is involved.

---

## THE HEADLINE, and it is a question for Tony rather than a finding

**`register` on TWO names would retire all 31 hoists.** The POP is green (`incant/regProbe`, three
legs), so the mechanism is proven: a member carrying `register` becomes bare-findable; its
unregistered sibling stays dark.

- **as it stands:** 31 call sites rewritten to reach siblings through the table
- **under `register`:** `gXpress` and `emitBC` each take **one attribute**, all 31 sites revert to
  bare calls and self-heal

Clay's Step 3 forbids registering further names, so this is **filed, not done**. The trade is
**two declarations vs thirty-one rewrites** — but it is a visibility decision, not a tidiness one,
which is exactly why it is Tony's.

---

## THE CENSUS

### Group 1 — done by hoist, and revertible if `register` is chosen

*All inside `generator` member bodies in `incant/generate`. Subsystem: bytecode generator.*

| site (member body) | member reached | count | disposition |
|---|---|---|---|
| `gDO` | `gXpress` 2 · `emitBC` 4 | 6 | **register** — sibling reach looks intended |
| `gFOR` | `gXpress` 1 · `emitBC` 5 | 6 | **register** |
| `gIF` | `gXpress` 3 · `emitBC` 5 | 8 | **register** |
| `gPrinT` | `emitBC` 1 | 1 | **register** |
| `gWhilE` | `gXpress` 2 · `emitBC` 4 | 6 | **register** |
| `gXpress` | `emitBC` 4 | 4 | **register** |
| | | **31** | |

**Why "register" and not "fix the call site":** every one of these is a **handler reaching its own
sibling** in a dispatch table it belongs to. The reach is structural and repeated, not incidental —
`emitBC` is the emitter's *output primitive*; every handler calls it. A name that every sibling
must call is a name that wants to be public.

### Group 2 — outside the `generator` block, still bare, UNFIXED

| site | member reached | subsystem | disposition |
|---|---|---|---|
| `incant/generate:408` `emitBC(op)` | `emitBC` | `testBRZEmit` fixture | **unsure** |
| `incant/generate:414` `emitBC(endLabel)` | `emitBC` | `testBRZEmit` fixture | **unsure** |
| `incant/generate:511` `emitBC(bcPushField=argument)` | `emitBC` | doc-block example | **doc only — no edit** |

`testBRZEmit` is a scratch fixture driven by `testing()`. If `emitBC` is registered these heal for
free; if not, they want the hoist. **Not touched** — they are not on the `oneTest` path and fixing
them ahead of the ruling would be the per-site repair Step 1 paused.

### Group 3 — ⚠ SILENTLY DEAD RIGHT NOW, and this one is not cosmetic

| site | member reached | subsystem | disposition |
|---|---|---|---|
| `incant/oneTest:38` `dumpBC(testPrint.bcLIST)` | `dumpBC` | top-level script | **unsure** |
| `incant/oneTest:44` `dumpBC(testByteCode.bcLIST)` | `dumpBC` | top-level script | **unsure** |
| `incant/oneTest:51` `dumpBC(testGXLeaf.bcLIST)` | `dumpBC` | top-level script | **unsure** |
| `incant/oneTest:54` `dumpBC(testIfElse.bcLIST)` | `dumpBC` | top-level script | **unsure** |

**`dumpBC for` appears ZERO times in a full `oneTest` run.** Four diagnostic calls in the project's
primary baseline fixture are doing nothing, silently, and the baseline still passes — because what
they would have printed was never in `oneTest.base` to begin with.

⚠ **So the baseline was captured with these already dead.** Registering `dumpBC` would make four
new blocks of output appear and **move `oneTest.base`** — which is a re-pin needing a sentence, and
the sentence would be *"restored diagnostic output that had been silently absent since the members
gate."* Worth deciding deliberately rather than discovering as a diff.

---

## What is NOT on this list, and why

**`generatE`.** The wakeup names it as the dark name; it is not. C++ reaches it via
`generator["generatE"]`, a parent index, and always did. Registering it would publish a name
nothing was failing to find. *(This is why Step 3 was reported as a no-op rather than performed.)*

**Anything outside `incant/`.** The grep covered `incant/*` for all ten `generator` members. C++
call sites use the parent-index form throughout and are unaffected by the gate.

---

## Provenance

```
incant/listWalk    walks Generating's and generator's own lists directly
incant/sweepProbe  attribute-reachable / member-dark, three checks
incant/regProbe    the register POP, three legs, cross-registry topology
incant/regEnum     get() does not descend
python3 census over incant/generate member bodies (counts above)
grep -n "dumpBC(" incant/oneTest
```

Fleet at time of writing: jitLadder **83** exit 0 · `pop.sh` 32 green / 2 documented reds ·
`oneTest` exit 0, **0** `generateCode failed`.
