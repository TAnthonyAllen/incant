# gFOR Design Bones (recon for Clay, 2026-06-12)

Feeds the gFOR design conversation. gIF, gWhilE, and gDO are **done** — all three
lowered to the existing op set (`bcBRZ` / `bcBR` / `gXpress` + label minting),
zero new bytecodes. gFOR is the first emitter that **can't** do that: it walks a
list, and there is no iterate-a-cursor op. This doc lays out the verified shape,
the runtime semantics gFOR must reproduce, the op gap, and a strawman lowering —
the design decision is Clay's.

---

## 1. What gFOR is today

`incant/generate:69` — still the **old C++-source-text emitter** (the only loop
left on the text path now that gWhilE/gDO converted):

```
gFOR argument code={
    print "generate for":;
    lp  = argument[1];               // Looper
    xp  = argument[2];               // ExpressioN (iterable)
    lr  = argument["LoopRestrict"];
    st  = argument["StatemenT"];
    print ~"while" lp;
    if lr
        if lr == "attributes";  print,_"= " xp ".nextAttribute(" lp ")";
        or lr == "members";     print,_"= " xp ".nextMember(" lp ")";
    else
        print,_"= " xp ".next(" lp ")";
        if lr   print ~+"if (" lr ")",+:;
    runGenerated(st);
    print ,-; };
```

Note the text lowering is already a **while-with-iterator-advance** — that's the
shape the bytecode needs too.

## 2. Parse-tree shape (verified by dump, 2026-06-12)

Grammar: `FOR  for- followedBy Looper in- reversE?="<-" ExpressioN SemI- LoopRestrict? StatemenT defer;`

`dumpContents` of the parsed `for grup in sumple; attributes maximus += 22;`:

```
StatemenT  (tag=gFOR)         length 4
  Looper        attribute  grup            Looper=grup        group
  ExpressioN    attribute  revisedList     ExpressioN=revisedList group
  LoopRestrict  attribute                  LoopRestrict=attributes string
  StatemenT     attribute  (tag=gXpress)   the body
```

Four **named** slots — use names, not positions (gWhilE/gDO settled on named
`ExpressioN`; gFOR's current positional `argument[1]`/`[2]` works but reads worse):

| slot | is | notes |
|---|---|---|
| `Looper` | the loop variable (`grup`), a group | bound fresh each iteration |
| `ExpressioN` | the iterable, a **revisedList** | single field ref (`sumple`) → one `bcPushField`; `unWrap` as gIF does |
| `LoopRestrict` | `"attributes"` \| `"members"` \| absent | affiliation filter |
| `StatemenT` | the body (here `gXpress`) | descend its `revisedList` like gWhilE's body |

`reversE` (the `<-` flag) is absent in this sample; present it would flip
`next`→`prior`.

## 3. Runtime semantics to reproduce (`aCTionFOR`, `ruleActions.rtn:430`)

This is the contract the emitted bytecode must match:

```c
LoopOn = ExpressioN (dereferenced to its .group);
while (grup = reversE ? LoopOn.prior(grup) : LoopOn.next(grup)) {   // advance cursor; null ends
    Looper.group = grup;                                           // bind loop var
    if (restrict && grup.affiliation != restrict)  continue;       // attributes/members filter
    result = StatemenT.gMethod(StatemenT);                         // body
    if (result.byRef)  grup = result;                              // body MAY steer the cursor
    ... continue / return / break ...
}
```

Five behaviors: (a) cursor advance over `LoopOn`'s list, (b) null = exit, (c) bind
`Looper.group`, (d) affiliation filter, (e) `reversE` direction. The `byRef`
cursor-steering at the end is the same family as the interpretBC bear-trap
(`aCTionFOR advances its own C++ cursor`) — flag for the design but a v1 gFOR can
likely defer it.

## 3b. Looper / LoopOn cursor semantics (the "not so intuitive" part)

Clay's design says "the cursor lives on `Looper.group`." Confirmed — but `aCTionFOR`
hides a distinction that `runForNext` has to collapse, and the answer to *"which
level does `runForNext` read the cursor from"* falls out of it.

**Two things that track each other in `aCTionFOR`, not one:**

| | what | where |
|---|---|---|
| **cursor** | `grup`, advanced by `LoopOn.next(grup)` | a **C++ local** — persists across the while-loop |
| **binding** | `Looper.group = grup` each pass | copies the cursor into the loop var so the body reads it |

`runForNext` has **no persistent C++ local** — the `bcBR` back-edge re-enters it
fresh every iteration through `interpretBC`. So it must **collapse cursor and
binding into one field**: `loopVar.group` becomes *both*. Safe, because
`aCTionFOR` already keeps them mirrored every pass.

**Which level — `Looper` or `Looper.group`?** The `Looper` slot on the instruction
is a **wrapper**: a group whose `.group` is the real loop-variable field `grup`
(dump: `Looper attribute grup  Looper=grup group`, data type = group).
`aCTionFOR` descends one level (`if Looper.isGROUP Looper = Looper.group`) to reach
`grup`, then sets `grup.group` each pass. The body's `grup` reference (a
`bcPushField`) reads that **same registered field** — which is why the binding is
visible. So **`runForNext` must descend one level first**, then read/write the
cursor on the descended field:

```
loopVar = Looper.isGROUP ? Looper.group : Looper   // descend wrapper -> grup
current = loopVar.group                            // recover cursor (null on 1st pass)
loop:
    next = reversE ? LoopOn.prior(current) : LoopOn.next(current)
    if !next:        push 0; return                // exhausted -> bcBRZ exits
    if restrict && next.affiliation != restrict:   // filter: skip non-matching...
        current = next; goto loop                  //   ...by advancing INTERNALLY
    loopVar.group = next                           // bind + store cursor in one field
    push 1; return                                 // -> bcBRZ falls through to body
```

**Three subtleties this exposes — flag for Clay, none fatal:**

1. **The affiliation filter is an inner loop *inside* `runForNext`, not a bytecode
   `continue`.** `aCTionFOR` `continue`s to skip a non-matching item and advance
   again. The flat bytecode stream has no per-pass continue, so `runForNext` must
   keep advancing internally until it finds a match or hits null. This *confirms*
   the fat-op call (answer #1) — the skip loop belongs in C++.

2. **Cursor reset — RESOLVED via self-clean on exhaustion (2026-06-12).**
   `aCTionFOR` does `Looper.clear()` **once** so the first `next(null)` yields the
   first element. `runForNext` is re-entered every pass and must **not** clear each
   time (infinite loop on element 1); and `grup.group` is **stale across runs**, so
   a pre-loop clear was the first instinct. But `bcStoreField` **can't** do that
   clear — it pops the stack (assumes a value) and uses `copyData`, which
   *"copies data but not lists"* (`GroupItem.twk:189`); the cursor is the `.group`
   **list** pointer, which needs `clearList()` (`GroupItem.twk:169`), a different
   operation at a different level. **Resolution:** don't emit any pre-loop clear at
   all — `runForNext` **clears `loopVar` on the exhaustion branch** (when
   `next()==null`, `loopVar.clearList()` then push 0). Every completed loop leaves
   the cursor null for the next run — more robust than a pre-loop clear (which only
   covered the first run), and adds **zero ops** (skeleton stays the gWhilE shape).
   First-ever entry relies on the dedicated loop var's group being null (true for a
   fresh var — another reason the fixture needs its own loop var). Residual: a loop
   aborted by `break`/`return` before exhaustion leaves the cursor mid-list — same
   bucket as the deferred `byRef` steering (#3); note and defer.

3. **`LoopOn` extraction is *not* gIF's `unWrap`.** `unWrap`
   (`Commands.rtn:548`) descends **one** level; `aCTionFOR` uses a **multi-level**
   `while LoopOn.isGROUP LoopOn = LoopOn.group` to reach the list-bearing field.
   For a bare-field iterable (`sumple`) one level happens to suffice, but the
   robust path is to mirror `aCTionFOR`'s full descent — either in the emitter
   before `+%`, or in `runForNext` at dispatch (preferred: reads the live field).

## 4. Op inventory — the gap

`bcOPs` registry (`incant/setup:139`): **`bcBR`, `bcBRZ`, `bcRET`, `bcPushLit`,
`bcPushField`, `bcStoreField`, `bcPrint`** — seven ops, **none iterate**. gIF /
gWhilE / gDO never needed more because a scalar condition is just `gXpress` +
`bcBRZ`. A for-loop's "advance cursor over a list and test for end" has no
existing primitive. **gFOR needs at least one new bcOP.**

The model already exists in C++: `interpretBC` itself walks its instruction
stream with `nextMember`, and a for-loop's data cursor is the **same idea on a
different list** — the iterable, not the bcLIST.

## 5. Confirmed lowering (Clay, 2026-06-12)

One new op, `bcForNext`, carrying `Looper` + the iterable `+%`-by-reference,
slotted into the gWhilE skeleton **unchanged** — no pre-loop clear op; the cursor
reset is folded into `runForNext`'s exhaustion branch (subtlety #2):

```
topLabel
bcForNext +% Looper +% LoopOn [restrict] [reversE]
                                               ; loopVar.group = next/prior(loopVar.group)
                                               ; skip until affiliation matches restrict
                                               ; push 1 if advanced; on exhaustion clearList + push 0
bcBRZ → exitLabel                              ; exit when exhausted
<body via gXpress / runGenerated>              ; reads loop var through bcPushField like any field
bcBR → topLabel
exitLabel
```

`runForNext` handler logic (descent done in the C++ generating branch per
Finding 2, so `Looper`/`LoopOn` arrive already-resolved):

```
current = loopVar.group
loop:
    next = reversE ? LoopOn.prior(current) : LoopOn.next(current)
    if !next:        loopVar.clearList(); push 0; return    // self-clean -> bcBRZ exits
    if restrict && next.affiliation != restrict:
                     current = next; continue                // skip non-matching, advance internally
    loopVar.group = next; push 1; return                     // bind + store cursor -> body runs
```

Why this shape works:
- **State survives the back-edge.** `interpretBC` re-enters `bcForNext` each loop
  via `bcBR`. The cursor lives on `Looper.group` (exactly as `aCTionFOR` keeps it),
  so `bcForNext` is stateless-per-op: read current `Looper.group`, advance, store.
  No separate iterator object, no `:=`/byRef weld.
- **Reuses the proven skeleton.** Same `topLabel`/`bcBRZ`→exit/`bcBR`→top frame as
  gWhilE — only the condition op changes (scalar test → `bcForNext`).
- **Body reads the loop var for free.** gXpress already emits field refs as
  `bcPushField +% field` (by reference), so the body picking up `grup` needs no
  special handling.
- **restrict + reversE fold into `bcForNext`** — its advance picks
  `next`/`prior` and skips on affiliation mismatch, so the stream stays flat.

## 6. Resolved — Clay's answers (2026-06-12)

1. **Fat op.** `bcForNext` owns advance+filter+test in one handler, like
   `bcPrint`'s passthrough. The `affiliation`/`reversE`/`next()`/`prior()` logic
   belongs in C++; keep the stream short. (Subtlety #1 forces this anyway — the
   filter is an inner loop.)
2. **Iterable & cursor.** `+%`-attach both `Looper` and `LoopOn` by reference
   (like `bcBRZ` carries its label). The cursor lives on `loopVar.group` between
   passes — `bcForNext` reads it, advances, stores back, pushes 0/1. Stateless
   per-op, no weld. (`runForNext` descends `Looper` one level first — subtlety in §3b.)
3. **`byRef` body-steering — defer.** Document the gap in a comment on the
   handler. Not blocking v1.
4. **`restrict` empty.** Plain `next()` over everything when `LoopRestrict` is
   absent — matches `aCTionFOR`'s `restrict==0` branch exactly.
5. **Test fixture.** Iterate `sumple` (already a known list), with its **own**
   loop var (`loopCount`/`counter`, **not** `righty` — the while/do fixtures
   consume `righty`; see today's gDO carryover note). Body increments the counter
   per matching element.
6. **POP target — `sumple` boned (dump, 2026-06-12):** 6 children — **5
   attributes** (`height`, `width`, `x`, `y`, `down`) + **1 member** (`crossing`).
   So:
   - `for grup in sumple; attributes` → counter == **5**  ← recommended fixture
   - `for grup in sumple; members`    → counter == 1
   - `for grup in sumple` (no restrict) → counter == 6

## 7b. Implementation reality — what DONE looks like (2026-06-12)

gFOR works end-to-end: `testFor` (`for grup in sumple; attributes counter = counter
+ 1;`) emits a clean 9-op `bcLIST` (`bcLabel · bcForNext · bcBRZ · bcPushField ·
bcPushLit 1 · + · bcStoreField · bcBR · bcLabel`) and runs to **counter = 5**
through `interpretBC`. The emit is exactly the gWhilE skeleton (§5), as designed.
But **three things diverged** from the design once it hit the runtime — each a real
finding:

1. **Loop var is tagged `ANYtoken`, not `"Looper"`.** Grammar `Looper=ANYtoken`
   makes the parse node's tag `ANYtoken` (the role is "Looper", reached by
   `aCTionFOR`'s `input["Looper"]` role-lookup, but `getAttribute` matches by tag).
   `runForNext` reads `getAttribute("ANYtoken")`. `ExpressioN`/`LoopRestrict` tags
   are as expected.

2. **Iterable descent needs a revisedList unwrap.** The `isGROUP` while-descent was
   supposed to reach the list-bearing field (§3b). It doesn't in *generating* mode:
   `aCTionExpressioN` wraps the iterable in a `revisedList`, which is NOT
   isGROUP-typed, so the descent stops there (the executor reaches `sumple`
   directly only because non-gen mode doesn't wrap). Fix: after the descent, if
   `loopOn.tag eq "revisedList"`, take `loopOn.firstInList` to reach `sumple`.

3. **Cursor is an integer match-index, NOT `loopVar.group`.** This is the big one.
   The design (and §3b) had the cursor living on `loopVar.group`, advanced by
   `next()` and stored back. **That can't work**: storing a live list member via
   `setGroup` **re-parents it out of the iterable**, so `next(stored_member)`
   returns null (`aCTionFOR` avoids this by keeping its cursor in a C++ local — a
   re-entrant op has none). So `runForNext` instead carries a `cursor` child holding
   an integer match-index (`setCount`/`getCount` — pure data, no re-parenting), and
   **re-walks the iterable from the start each pass**, skipping `index` matches.
   O(n²) over the loop. Self-clean = reset the index to 0 on exhaustion. The
   re-parenting discovery also **defers the loop-var VALUE binding** (the body
   can't read the current element yet — same root cause; the counter-body POP
   doesn't need it).

**Open for Clay (follow-ups):** a re-parent-safe live cursor (kills the O(n²) AND
unlocks loop-var value binding) — probably a non-owning reference set, the same
`byRef` family already in play; then `reversE`; then nested/compound iterables
(the firstInList unwrap assumes a bare-field iterable).

## 7. Implementation checklist (Clod, when greenlit)  — ✅ DONE 2026-06-12

1. Add `bcForNext` to `bcOPs` in `incant/setup` with `interpret=runForNext`.
2. Write `runForNext` in `Bytecode.twk` — read `loopVar.group` as cursor;
   `next()`/`prior()`; inner-loop the affiliation filter; on a match store back to
   `loopVar.group` + push 1; **on exhaustion `loopVar.clearList()` + push 0**
   (self-clean, subtlety #2). `Looper`/`LoopOn` arrive already-descended (step 3),
   so no descent in the handler. Comment the deferred `byRef`/`break` gap.
3. Emit path (Finding 2) — the **C++ `aCTionFOR` generating branch** does the full
   `Looper` + `LoopOn` while-descent (`unWrap` is single-level, won't do — subtlety
   #3) and resolves `restrict`, then emits the §5 skeleton (`topLabel`, `bcForNext`
   `+%` the resolved fields, `bcBRZ`→exit, body via the existing generator descent,
   `bcBR`→top, `exitLabel`). **No pre-loop clear op.**
4. Add `testFor` — iterate `sumple` with its **own** loop var (not `righty`); body
   increments a counter per pass. POP target **5** (`attributes` restrict).
5. Wire into `oneTest`.
6. POP — run, confirm counter == 5 (not shape-read).

## Pointers

- Emitters: `incant/generate` — gIF `:84`, gPrinT `:127`, gWhilE `:136`, gDO `:62`, gXpress `:163`, emitBC `:178`
- Runtime FOR: `ruleActions.rtn:409` (`aCTionFOR`)
- Ops: `incant/setup:139` (`bcOPs`), handlers in `Bytecode.twk` / `incant/bytecode`
- Dispatch loop: `interpretBC` in `GroupActions.rtn:176`
- Grammar: `incant/grammar:126` (Looper/LoopRestrict), `:138` (FOR rule)
