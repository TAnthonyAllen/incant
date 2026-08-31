## SEQ <next> — THE ROUND-TRIP FIXTURE, THE SPLIT ONE FLAG AT A TIME, THE FLIP'S THIRD ASKING
STATUS: verdict
FROM: Clay   TO: Clod   DATE: 2026-08-31   VIA: Tony (WT-9, dictated/transcribed)
SUPERSEDES: nothing. Extends the 08-31 seal's NEXT STATIONS 1–3.
CHARTER: interpreted only. No `*` outside fixtures. No flip re-arm until C5's gate is met.

### C0 — Why this brief exists
Three whole-split attempts, three reverts, and the mechanism was named only on the third:
`broadcastT` ARM 3 fails under the split — `x :. noPrinT` then `x.noPrinT` does not round-trip
on the same node. Every prior arm was read through that void control. The unit of change (whole
split) was larger than the unit of measurement (one arm). This brief inverts that.

### C1 — Fixture `incant/roundTripT`: four lines, not three, and it must not be able to return VOID
Build it to NAME the mechanism, not to fail.
```
x :. noPrinT                 ; write
<print node address of x>    ; address at the WRITE site
r = x.noPrinT                ; read
<print node address of x>    ; address at the READ site, and r
```
Run all three in ONE process, in this order:
- **R1 BARE** — legacy layout, no split.
- **R2 SPLIT** — flag relocated to `GroupItem`.
- **R3 SPLIT + COPY** — same as R2, but the write goes through a `copyOf` twin and the read is on
  the original.
Each run prints: write-addr, read-addr, r. Anti-vacuity control: a run that prints nothing, or
prints only r, is VOID and the fixture has failed to build — say so, do not score it.

### C2 — Pre-registration (write this into the fixture header BEFORE the first build)
Clay's prediction, for the record: **R1 addresses DIFFER and r reads 1; R2 addresses DIFFER and
r reads 0; R3 r reads 0.** Mechanism: the copy constructor shares `groupBody` while everything
else is per-node, and incant accessors are snapshot-by-value. A body-resident flag survives a
write made through a copy because copy and original share the body. Relocate the flag and the
same write lands on the copy's own struct and is invisible to the original. Same family as
`<-` hands-back-a-copy.
⚠ ATTRIBUTION CHECK (standing rule — take the distinction, check the tree claim): whether `:.`'s
write path actually runs through a copy is a claim about the tree. Verify at the site before
scoring; do not take it from this brief.

### C3 — The truth table routes the repair. Score, then route; do not repair before scoring.
| R1 addr | R2 addr | R2 r | Verdict | Route |
|---|---|---|---|---|
| same | same | 0 | split itself wrong — a reader still aimed at `groupBody`, or the copy ctor didn't carry the moved flag | layout repair in `GroupItem.twk`; TWO-HALF change, sweep every READER site not just the write |
| differ | differ | 0 | write path goes through a copy; body was covering | repair at the WRITE path (`:.` / accessor). Split is innocent, stays in shape |
| differ | — | 1 in R1 | covering mechanism confirmed directly | this is a CENSUS trigger — every relocated flag will break this way; run C4's census before moving flag #2 |
| same | differ | any | copy ctor behaviour changed under the split | split repair, but at the ctor, not the readers |
Any row not in this table → OPEN, filed as a NEXT block, not guessed.

### C4 — Split one flag at a time, fixture-gated per flag
Order: `noPrint` first (already caught). Then the rest, one per stroke. Per flag:
1. `roundTripT` green under the split for THAT flag (R2 r == 1, addresses as R1).
2. Fleet at baseline (red set byte-identical to stroke-open). Canary unchanged or delta named.
3. `broadcastT` ARM 3 no longer void.
4. Commit. One flag, one commit, one line in the register.
A flag that fails the gate STAYS in the body and gets a register row naming which truth-table
row it hit. No whole-split commit, no whole-split revert.
If C3 lands on the census row: before flag #2, grep every `groupBody->flags.<name>` write site
for each candidate flag and record the count in `minionWork/` with a pre-registered prediction —
the `isRule` census predicted ONE site and found EIGHT.

### C5 — Flip re-arm gate, stated so it can be checked without judgement
Re-arm the flip only when ALL of: every relocated flag has passed C4 · the audit number comes
clean · `broadcastT` ARM 3 reads non-void. Then ask the acceptance line a third time:
`parser(Start)` receives Start. `acceptStartT` and `derefT` un-park at that moment and not
before; `derefT` re-pins to R1 ≠ R2.
If the audit will not come clean after C4 is complete, that is its own fixit citizen with a
NEXT block at OPEN — not a reason to leave the flip parked indefinitely.

### C6 — Housekeeping, first, because it protects everything above
1. **Write the three-attempt history into the register before building C1.** Per attempt: what
   moved, what went red, what the revert restored, which commit. The 08-31 seal carries it as one
   line and there is no 08-30 seal at all; "unchanged in shape" for the re-attempt presumes the
   three reverts taught nothing about shape, and nothing on file says whether that is true.
2. **Fixit hour FIRST**, before the fixture. Queue 8, `kantGenPath` since 08-24. The hour retired
   `parentStamp` yesterday, so it works; it fails only when it runs after the day's build.
3. `groups.ext` committed every pass (standing rule 08-25). Support repo checked, not just Groups.

### C7 — What Clay wants back
The three-run printout of `roundTripT` verbatim, the truth-table row it landed on, and the
attribution check on C2's tree claim. Nothing else until those three are on file.

STATUS on read: `working`. STATUS on C1 scored: `verdict`. Tony's window: `grep -H '^STATUS:' ipc/*.md`.
