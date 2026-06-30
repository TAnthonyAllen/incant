# Next Step — Specification (for Tony, Clay, Clod to share)

*2026-06-28. Synthesizes Fearless's "ready for your chew" framing + Clod's proposed first build move.
One page so all three seats are working from the same plan.*

## Where we agree (Fearless's points, ratified)
- **"Ready for Igor" was premature.** Igor (the minion) doesn't exist yet as a built thing. The honest
  state is **"ready for Tony's chew."** That chew gates what becomes real.
- Pass 2 absorbed everything Clod flagged; the only bones-level error (JIT/bytecode pipeline) is fixed —
  now correctly "parallel lowerings from one front end."
- What an Igor *would* do once the architecture exists: **consume** a corpus (answer "what is incant for"
  accurately), **maintain** it (absorb new material with provenance), **challenge** claims against it.
  Those are the four operations from the vision doc, applied to a domain.

## The thing we keep almost-saying out loud, now said plainly
There isn't one "next step" — there are **two independent tracks** plus **one gate**. Conflating them is
the trap the vision doc itself warns about (two-products split). Keep them separate:

- **GATE — Tony's chew on Pass 2.** Nothing about *Vision Igor* proceeds until the vision doc is settled,
  because the doc IS that corpus. But the chew does NOT gate the format work or FileBoss below.
- **TRACK A — the Minion Corpus Format (design, then proof).** The real first concrete artifact.
- **TRACK B — FileBoss MVP (deterministic build).** Parallel, independent, no LLM, proves the substrate.

## TRACK A — the next concrete move Clod proposes to own
**Author "Minion Corpus Format v0" and prove it by instantiating it twice.**

Step A1 — *Format spec* (design-writing, no build, can start now regardless of the chew).
Define the GroupItem-shaped structure a minion corpus is. Field skeleton (refining the vision doc's
draft anatomy):
```
minion        — the corpus root (a GroupItem)
  name        — "JIT Igor"
  domain      — one-line scope
  claims[]    — the knowledge, as discrete entries, each carrying:
      text        — the claim
      provenance  — where it came from (scout id / run / "IR dump" / "inferred from shape")
      confidence  — verified | inferred | stale-suspect
      asOf        — when last confirmed (absolute date)
  openItems[] — unresolved questions the minion is tracking
  scouts[]    — pending/completed recon feeding this corpus
  lastBaked   — when the corpus was last distilled
```
The non-negotiables (the integrity layer, from the poisoned-pie lesson): **every claim carries
provenance + confidence**, and `confidence: verified` must mean *bones-verified* (trace/IR), not
shape-read. The format is markdown-as-bootstrap now, GroupItem-tree as destination — the field names
above are chosen so the md and the eventual GroupItem are the same shape.

Step A2 — *Instantiate JIT Igor* by retrofitting `docs/jit.md` (+ `wakeup.md`) into the format. This
both **creates the first real corpus** and **tests the format against dense technical material.**

Step A3 — *Instantiate Vision Igor* by retrofitting the (chewed) `vision.md` into the same format. Same
format, second domain → proves it generalizes. **A3 waits on the gate; A1/A2 do not.**

**Acceptance criteria:** a fresh agent handed the JIT Igor corpus answers "what phase is the JIT in, and
what's proven vs. inferred?" correctly and *distinguishes verified from shape-read* — i.e., it would NOT
have repeated the gIF "taken→99" falsehood, because that claim would carry `confidence: inferred` /
`stale-suspect`, not `verified`. That single test is the whole point of the format.

## TRACK B — FileBoss MVP (parallel, independent)
Three-copy rule (local primary, local backup, cloud/network), checksum-on-write, transparent reroute.
Deterministic incant/code, no LLM. Build proves the headline contract ("your stuff is always there")
cheaply. Does not wait on Track A or the chew. Owner TBD — flag if Clod should scope it.

## Housekeeping decision needed (Fearless raised it): where does vision.md live?
It's marked "private, not repo material yet." Clod's recommendation: keep the working copies in
`Groups/docs/` for now (where this whole vision correspondence already lives and syncs across Tony's
machines) — the "not repo material" concern is about *promotion to the bible*, not about Dropbox sync.
Revisit a dedicated home only if/when it graduates. (Also pending from recon: `Parse/HWFattic/` doesn't
exist and a Session-9 graduation reference dangles — minor cleanup, not blocking.)

## Proposed immediate action
Clod starts **A1 (format spec) + A2 (JIT Igor instantiation)** now — pure design/doc work, low-risk,
doesn't wait on the chew. Tony chews Pass 2 in parallel. Once chewed, A3 (Vision Igor) follows. FileBoss
(Track B) scopes whenever a hand is free. **Same page?**
