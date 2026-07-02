# jsonTest Google-Fonts Probe (M3, 2026-07-02)

*Fearless marching orders M3: "update jsonTest to feed the Google fonts JSON; report
where the parser chokes, if it chokes. Output = choke report or clean bill. Pure Welk;
no fixing in this task." No grammar changes made — recon only.*

## Headline: partial clean bill, one real choke

- **A single Google-Fonts-shaped font entry parses clean.** `docs/json.md`'s "green
  end-to-end" claim holds for the shape of one entry: `{"family":..., "variants":[...],
  "files":{...}}` — nested object as a field value, array of strings — all `ok`.
- **The real API's top-level shape does NOT parse.** `webfonts/v1/webfonts` wraps every
  entry in a top-level `"items"` **array of objects**:
  `{"kind":"...","items":[{...},{...}]}`. That specific shape — object literals as
  *array elements* — chokes.

## Root cause (static, confirmed by the run)

`incant/utilities`'s JSON grammar: `JSONarray`'s elements are `JSONitem -> JSONtoken@`,
and `JSONtoken`'s option list is only `"false" / "true" / GrouP / NumbeR` — **no
`JSONblock` option**. Arrays can hold strings/numbers/bools, not nested objects. This is
visible from the grammar alone, no run needed to predict it — the run below confirms it
behaves exactly as the grammar shape predicts.

## Two different observed behaviors for the identical failing input (the interesting part)

1. **In isolation** (`items`-array test as the only/first `testJSON` call in a run):
   clean, reported failure. Parser prints `Rule JSONblock / Failed at: [{"family":...`
   and `testJSON` correctly reports **`FAIL:`**. No crash, no hang. This is the good
   outcome — a controlled failure.
2. **After several prior successful `testJSON` calls in the same run** (i.e. run the
   whole extended `incant/jsonTest` file straight through, arrays/nested-objects/single-
   entry cases first): the *exact same* `items`-array string still logs the internal
   `Rule JSONblock / Failed at: ...` diagnostic, but `testJSON` then reports **`ok`**
   instead of `FAIL`. `field = JSONblock(argument)` came back non-null despite the
   parser having hit that failure — i.e. **the failure is silently swallowed and
   something (partial/stale) gets returned as if it succeeded**, only in the
   sequential-multi-parse context. This is worse than the isolated case: a caller
   checking `if field` would wrongly believe the parse succeeded.
   - Didn't chase the mechanism (out of scope — "no fixing in this task"), but the
     shape strongly resembles `docs/json.md`'s "Sequential-parse rule-clobber" /
     `isRule` findings — worth a look there first when this gets picked up. The `fail`
     modifier prefix on `JSONblock`'s rule declaration (`JSONblock isRule fail "{"-
     JSONfield* "}"-`) is also a candidate — its recovery semantics on repeated use
     are exactly the kind of thing that could produce "reports failure internally, but
     returns non-null anyway."
   - Output ordering was also confusing in the combined run (the `stop: ending input
     divert` cerr line appeared to print *before* the `ok:` line for the last case) —
     almost certainly a stdout/stderr buffering artifact (`print`/`cout` block-buffer,
     `cerr` doesn't — CLAUDE.md's standing note), not a sequencing bug. Flagging so a
     future reader doesn't misread literal output order as literal execution order.

## What was fed it

Local fixtures only (no live fetch attempted — not needed for the shape stress-test,
and the quick-POP win was higher priority than plumbing a network call today). An API
key does exist at `~/data/support/incantConfig.json` (`googleFontsApiKey`) if someone
wants to follow up with a real fetch.
- Re-ran every case already documented in `incant/jsonTest` past its first `stop()`
  (arrays, nested objects) — all now pass; the file's own "currently fail" / "currently
  segfault" comments were **stale** (fixed 2026-06-22 per `docs/json.md`, comments never
  updated). Fixed the comments in the tracked file as part of this update (that's
  documentation, not a grammar fix).
- Added: a single realistic multi-key font-entry object (already existed, kept).
- Added: a 2-entry `{"kind":...,"items":[{...},{...}]}` fixture matching the real
  `webfonts#webfontList` response shape, with nested `files` objects and string arrays
  inside each item — this is the one that chokes.

## incant/jsonTest changes

Tracked file updated (not a scratch file, per Tony's ask to "update jsonTest to drive
that"):
- Stale bug comments corrected to reflect current (green) reality.
- New case + comment block documenting the array-of-objects choke, placed after the
  file's first `stop()` (so the quick 2-case POP check is unchanged) with a clear
  `KNOWN TO FAIL` label so nobody mistakes it for an expected-green case.
- Quick-POP path (`<binary> incant/jsonTest`, default) still prints exactly `ok / ok`
  as before — unregressed.
- `oneTest` re-verified unaffected (`maximus = 26`) — jsonTest and oneTest are separate
  invocations, no shared-state contamination.

## Most useful next step

Add `JSONblock` as a `JSONtoken` option (so array elements can be objects) — that's the
whole fix for the top-level shape, going by the grammar read. But **before** that fix,
resolve the silent-success-on-failure behavior above — a grammar fix that makes the
first-parse-of-the-session case work is not verified safe until it's confirmed the
sequential-context masking isn't independently returning bogus non-null results for
still-broken inputs.
