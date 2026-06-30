# Local Wiki / webChannel — Recon (toe-dip 2026-06-30)
*Clod recon. The goal Tony named: a **local-hosted, editable wiki for documentation**. Clay leans
quick-fix + defer the Go-style channel architecture; Tony wants to dive into the channels because
they're cool. This recon's finding: **you don't have to choose — both share the same first step.***

## Asset inventory (what already exists vs. the one real gap)

**Content already exists** — this is NOT greenfield on the wiki side:
- `wiki/` dir: `WhatIsIncant.md`, `MemoryManagement`, `BootstrapRules`, `directiveWiki.md`.
- `incant/changeWiki` — authored wiki page content ("Grammar on the fly", "modedOP — a writable
  operator"), prose about incant features.
- `docs/` — the whole markdown corpus (design docs, recons, this file).
- bible:525 notes a wiki restructure landed 2026-05-24 (What-Is-Incant, Appendices A/B).

**incant already has file I/O** — proven in `incant/grammarOnTheFly`:
- `modedOP operateMethod=setFileOp;` rebinds an operator to a file-writer shim.
- `doc modedOP "path.out"; … ; closeFile(doc);` — attach a buffer to a path, fill, flush to disk.
- So incant reads/captures its own content and writes files. Buffers + `printTO` are in hand.

**GUI exists but is the wrong path for a *browser* wiki:** `GUI/` is a full Cocoa app framework
(`GroupUIAppDelegate`, `Groups.g` grammar, Control/Layout/Source/Details/Stylish). Heavy, native,
and on the deferred GUI arc — not how you'd serve a browser-accessible wiki.

**THE GAP — local serving.** No HTTP / socket / server / listen code anywhere in the tree
(grepped). incant can write a file and mutate its own grammar live, but it cannot yet **listen on a
port and answer a request.** That single missing capability is the whole job.

## The reconciliation: quick-fix and channels share ONE first step

- **Clay's quick-fix** = serve the existing `wiki/`+`docs/` markdown locally so a browser can read
  (and ideally edit) it.
- **Tony's Go-style channels** = incant gains goroutine/channel messaging and serves the wiki via
  its *own* network substrate (the distributed-OS long game, bible:401–407, HPDL).

These look like a fork, but the **first concrete step is identical for both**: *get incant to
listen on a socket and serve a wiki page.* A minimal socket listener is simultaneously the core of
the quick wiki AND the first real brick of the channel architecture (incant doing network I/O is
the substrate channels are built on). So the dive-in doesn't commit to the full channel build, and
it isn't a throwaway either — it's the shared root.

## Recommended first step (the reconvene dive-in)

**Add a minimal incant socket listener — a `setSocketOp` extern, the direct analog of `setFileOp`.**
Just as `setFileOp` wraps a file fd behind an operator, `setSocketOp` wraps a listening TCP socket:
incant binds `localhost:<port>`, accepts a connection, reads the HTTP request line (the path),
maps the path to a `wiki/<name>.md`, and writes back an HTTP response carrying that file's content.
Proof-of-life target: browse to `http://localhost:8080/WhatIsIncant` and see the page.

Mechanically it's a small C++ `-% %-` block (socket/bind/listen/accept/recv/send) behind an incant
operator, reusing the buffer/file machinery already proven in `grammarOnTheFly`. It is to the
network what `setFileOp` is to the disk — and it's the same "an operator is a writable field"
idiom, so it sits naturally in incant rather than bolting on a foreign server.

### Open questions for the dive-in
1. **Render**: serve raw `.md`, do a minimal incant markdown→HTML pass, or render browser-side
   (a tiny JS markdown lib in the served HTML). Cheapest-first: serve raw, prettify later.
2. **Edit**: read-only first (serve), then editable (accept a POST → write the file via the
   existing `setFileOp`/buffer path — the write half already exists).
3. **Scope guard**: a bare blocking accept-loop is enough for a single-user local wiki. Do NOT let
   it grow into the full goroutine/channel scheduler in step one — that's the HPDL long game, and
   the socket listener is deliberately the *minimum* shared with it.

## Status
Recon only — no build. The hang-fix JIT work is committed (`095bcb1`); JIT's next task (the
gIF-emit bugs) is in `wakeup.md`. This wiki dive-in is a parallel, design-fresh thread for
reconvene. Clay owns the broader channel-architecture design; this is the pragmatic on-ramp.
