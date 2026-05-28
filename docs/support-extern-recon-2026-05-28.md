# Support-class extern recon for incant — 2026-05-28

*Tonto scout. Goal: identify C++ methods in `support/Frame/` that would earn their keep wrapped as incant-callable externs (e.g. `extern void setMark(GroupItem field)`). Listed per file. Most don't qualify — listed below are the ones that might.*

**Disqualifying signatures (filtered out):** raw `void*` / `HashLink*` / `DoubleLink*` params (incant doesn't reify these), function-pointer params (`void ^block()`, `void &method(void*)`), `NSString`/`NSError`/`Data`/`URLresponse`/`Dtime` (Objective-C or opaque time types), C++ overloads where incant has no way to disambiguate.

**Disqualifying semantics (filtered out):** constructors (incant uses `new("name")`), internal memory mgmt (`extend`, `reSize`, `resize`), file-descriptor I/O without an obvious incant-side use case, methods already reachable via existing operators (`+=`, `cout`).

**Already incant-visible:** `StringRoutines.twk` — all functions are already declared `extern` in tawk and surfaced through `Include/frame`'s external block; `compare`, `head`, `concat`, `containsString`, etc. work from incant directly (just used `head` + `compare` for the DiR dispatch hook today).

---

## Strong candidates (clean shape, obvious value)

### Buffer.twk — the headliner

This is Tony's primary target. Listed in priority order for the buffer-span vocabulary held-arc work.

| Method | Signature sketch | Notes |
|---|---|---|
| `setMark()` | `extern void setMark(GroupItem bufField)` — with optional offset per Tony's sketch | The mark-establishment primitive. Take an int param for offset; zero/missing means "current". |
| `getMarkedString()` | `extern String getMarkedString(GroupItem bufField)` | Read what's between mark and current. Foundation for find/extract. |
| `backupToMark()` | `extern void backupToMark(GroupItem bufField)` | Rewind to mark. Complements setMark. |
| `unMark()` | `extern void unMark(GroupItem bufField)` | Clear the mark. |
| `insertIntoBuffer(String, int)` | `extern void insertAtMark(GroupItem bufField, GroupItem stringField)` per Tony's naming | The insert primitive. Tony's sketch named `insertAtMark(GroupItem field)` — uses the mark instead of an explicit offset, which is the cleaner incant shape. |
| `deleteFromBuffer(int)` | `extern void deleteAtMark(GroupItem bufField, int count)` or take a span | Companion to insert. Could pair with mark+span for the delete-span case. |
| `tail(int offset)` | `extern String tail(GroupItem bufField, int offset)` | Tony flagged for revision on bogus-offset handling. |

**Find-string-in-buffer** is the missing primitive in Tony's sketch — Buffer doesn't have it natively. Either (a) add to Buffer as a new method, (b) compose from `setMark` + a scan loop on `current`/`end`, or (c) lean on `StringRoutines.headToString` against `buffer.toString()` and convert offset back to mark. Choice probably wants a design moment.

### Stak.twk

| Method | Signature sketch | Notes |
|---|---|---|
| `clear()` | `extern void stakClear(GroupItem stakField)` | Useful if incant ever wants to reset a stak without re-creating. |
| `popOff(int)` | `extern void popOff(GroupItem stakField, int n)` | Drop N items at once. Companion to existing `.pop()`. |

`push`/`pop`/`top` already reachable via tawk's `gStak.push(...)` / `gStak.pop()` idiom (used in `Instruct.rtn:336, 440`). The Stak[] by-index accessor from Tony's session-9 follow-up TODO is a **new method**, not a wrap — separate work.

### CharSet.twk / PLGset.twk (parallel surfaces)

| Method | Signature sketch | Notes |
|---|---|---|
| `contains(char)` / `contains(String)` | `extern int contains(GroupItem setField, GroupItem arg)` | Set membership query. Already used via `set.contains(...)` in tawk (`GroupItem.twk:711+`); incant access would let parse-side code do membership tests on dynamically-built sets. |
| `foundIn(String)` | `extern int foundIn(GroupItem setField, GroupItem stringField)` | Inverse — "does any char of the string fall in the set". Used by aCTionTokenXP and friends. |
| `isEmpty()` | `extern int isEmpty(GroupItem setField)` | Trivial wrap; useful if incant code builds sets dynamically. |
| `skip(String)` | `extern String skip(GroupItem setField, GroupItem stringField)` | Returns the tail of the input after skipping leading chars that are in the set. The most useful one for tokenizer-flavored incant code. |

CharSet and PLGset have near-identical interfaces (mirror class pair). One set of externs each, or — if the underlying type tagging lets incant treat them uniformly — one set of externs that dispatch by `field.data` type.

### OCroutines.twk

| Method | Signature sketch | Notes |
|---|---|---|
| `getURLintoBuffer(String url, Buffer buf)` | `extern int getURL(GroupItem urlField, GroupItem bufField)` | Side-effecting HTTP fetch into a buffer. Genuinely incant-useful — would let incant code pull network data. |

---

## Plausible (useful but design call needed)

### Buffer.twk

- `length()` → `extern int bufferLength(GroupItem bufField)`. May already be reachable as `bufField.length` accessor depending on tok's field-accessor generation. Verify before wrapping.
- `reset()` → trivial; possibly redundant with operator-level clear.
- `flush()` / `setFile(String)` / `closeFile()` — the file-I/O group. Only worth wrapping if incant code is going to write files (which Phase JIT might, eventually).

### URLservice.twk

- `send(String url)` → `extern void urlSend(GroupItem urlField)`. Fire-and-forget HTTP send. Limited value without callback access, but callbacks are exactly the disqualifying shape.

### Bot.twk

- `registerAs(String name)` → only one method on Bot. If incant ever needs to identify itself to the bot integration layer, this is the entry point. Hold until there's a use case.

### SearchTree.twk

- `search(char *atChar)` returns `SearchItem`. If wrapped to return a GroupItem (or just a found/not-found int), could expose the prefix-tree to incant code. Speculative — no current use case I can see.

---

## Not candidates (listed so we don't re-recon them)

- **`StringRoutines.twk`** — all already incant-visible.
- **`DoubleLink.twk` / `DoubleLinkList.twk`** — internal list infrastructure; methods take `void*` or `DoubleLink*`. Incant uses these implicitly via GroupItem's groupList; no direct wrap needed.
- **`Hasher.twk` / `HashLink.twk` / `HashList.twk` / `BaseHash.twk` / `BaseEntry.twk`** — internal hash plumbing. Methods take `void*` or `HashLink*`. Incant uses these via the registry layer (`Operators`, `bcOPs`, `groupFields`), not directly.
- **`Tape.twk` / `TapeSegment.twk`** — memory pool plumbing. No incant-side use.
- **`DispatchQ.twk`** — every method takes function-pointer / block params. Disqualified.
- **`SimpleList.twk`** — `push(void*)` only. Internal.
- **`SearchItem.twk` / `SearchNode.twk`** — internal tree nodes, no public method surface to wrap.

---

## Pattern observations

- **The Session-9 mirror.** "Teach support classes what an incant field is" applied plg-side to PLGset/CharSet during Session 9 (via the `external` blocks in `Include/frame`). Applying it to Buffer/Stak/etc. for incant access is the same shape, one layer down. Prior-art, not handwave.
- **Two-layer access already exists for some classes.** Buffer methods are reachable from tawk code via `buffer.method()` because of the `external Buffer { ... }` block in `Include/frame`. What's missing is the incant-callable wrappers — the `extern void setMark(GroupItem)` shape — that incant's `runAction` dispatch can find. Could land as new `Buffer.rtn` or extend existing `.rtn` files.
- **Mark-state lives on the buffer.** No design question about who owns the mark; it's a `String mark` field on Buffer per `Include/frame:51`. setMark/insertAtMark/etc. all dispatch via the buffer field. The interesting question Tony raised — `setMark(findStringInBuffer(field))` — is the implied-receiver question, which is a parse-time shape decision (lastREF chain vs. attribute-as-method pattern), not a wrapping concern.

---

## What I'd actually wrap, if asked to pick five

If the goal is the buffer-span-vocabulary for development directives (the held arc), the minimal useful set:

1. `setMark(GroupItem buf, int offset)` — with offset 0 default
2. `getMarkedString(GroupItem buf)` → String
3. `insertAtMark(GroupItem buf, GroupItem stringField)`
4. `deleteAtMark(GroupItem buf, int count)` *or* a span variant once span addressing settles
5. A `findInBuffer(GroupItem buf, GroupItem needle)` that sets mark and returns 0/1 — this one's NEW (not wrapping an existing method)

Those five plus the existing append-via-`+=` give incant the full insert/replace/delete vocabulary the directive arc needs.
