# THE OWED REGISTRY — one queue per seat

**Chartered 2026-08-20 (Clay's ruling, Tony's proposal).** The generalisation of the fixit register
to items that **do not run**.

## What transferred, and what did not

The **runnable file** — the part that named the fixit register — is the piece that **does not
generalise**. Reviews and rulings do not execute. What transfers is everything underneath, which is
what was load-bearing anyway:

- the queue lives **on disk, not in memory**
- the count line is **generated, never typed**
- it is placed **where the owing party actually looks**
- **ageing rides in it**
- **discharge is by ruling**

**Fixits remain the runnable subspecies**, with their own file anatomy in `incant/fixits/`. Nothing
about them changes.

## ⚠ THE FIELD THAT IS GENUINELY NEW: `delivered`

**A fixit cannot separate the reminder from the work** — the file *is* both. **An owed review can.**
The reminder can reach a seat while the artifact never does, and **that state is worse than
forgetting**, because it produces a seat confidently re-deriving what it was meant to review.

So `delivered` tracks *"has the text crossed the relay"* separately from *"is the item owed"*. **The
founding scar is exactly this state:** the charter review sat **seven days** — 2026-08-13 to
2026-08-20 — on a list, while the artifact never travelled. A line reading
`Clay: 1 owed (charter review, since 08-13, artifact NOT delivered)` would have said, in one glance
on day one, that the next move was an upload.

⚠ **AND THE CENSUS FOUND THE FAILURE RUNS BOTH WAYS**, which the founding scar alone would not have
predicted — see the two `clod-to-clay` rows below. Replies were written **for** Clay and left
`fresh`. Whether they crossed by another route is **not knowable from the channel**, which is the
finding: **`STATUS:` in the walkie-talkie files is a pickup record, not a delivery record.**

---

## THE QUEUE

**Scope rule, so the count stays honest: an item belongs here only when a SEAT OWES IT.** Open work
with no named owner is a **docket** entry (`docs/fixIts.md`), not a queue entry. `fixIts.md` carries
~30 open rows; most are `unassigned` and are deliberately **not** counted here.

### Tony

| since | item | delivered |
|---|---|---|
| 2026-08-20 | **the F-31 build** — released-and-untasked by ruling. Step one is pre-registering `incant/f31`'s taken-signature | y |
| 2026-08-20 | **F-33** — ratify the shape (minimal well-formed body for a termless rule) | y |
| 2026-08-20 | **S1** — nod the quote convention (`'` substitution + `[quotes substituted]`), measured | y |
| 2026-08-19 | **F-26's five** — sites now in the docket, file:line | y |
| 2026-08-19 | **`groupDirectives`** — the `compile`-entry `debugAllRules` line, not regenerable | y |
| earlier | **`IncantForms/WorkingOn` reconciliation** (H8) · DesignDocs `KantParser` authored-not-installed | y |

### Clay

| since | item | delivered |
|---|---|---|
| — | *(none open — the charter review discharged 2026-08-20)* | — |

### Clod

| since | item | delivered |
|---|---|---|
| 2026-08-20 | **the owed-nag script** — extend `fixitNag.sh` to sweep all seats. **Deliberately not built the night it was chartered**; the census is prior, and an instrument invented at hour N is the mechanical-state hazard this project has a ruling about | y |
| 2026-08-20 | **the pointer census** as a fleet row (every `see DesignDocs:` resolves; every `CodeSite` resolves; broken-pointer negative control) | y |
| — | **F-6** — the correction owed to commit `6212a71`, folds into the next landing | y |

### ⚠ The walkie-talkie channel — STALLED, and nobody was looking

| since | item | delivered |
|---|---|---|
| **2026-08-10** | `clay-to-clod` **SEQ 41** (KANT-8 unconditional bracket fix) sits **`WORKING`** — picked up **ten days ago**, never cleared. ⚠ The protocol's own header says `grep -H '^STATUS:' ipc/*.md` is **Tony's only window into whether anything is stalled.** It was not run | y |
| **2026-08-10** | `clod-to-clay` **SEQ 49** (the bracket fix is blocked, and the blocker is CLAIM KANT-8 itself) sits **`fresh`** | **n** |
| **2026-08-10** | `clod-to-clay` **SEQ 50** (M1 and M2 both run; M2 says stop, the detach pick is off) sits **`fresh`** | **n** |

*(`clod-to-support.md` is also `fresh` since 2026-08-03 — but it is **"channel opened, empty"**, and
an empty channel is **not an owed item**. Counted as zero on purpose: a census that inflates itself
with vacancies is the anti-vacuity failure one level up.)*

---

## DISCHARGED — kept, not deleted

| entered | closed | item |
|---|---|---|
| 2026-08-13 | 2026-08-20 | **Clay's review of `docs/commentMinion.md`** — seven days. **The register's founding scar**, kept as rationale the way Addendum 3 clause 3's corpse was kept. The item was on a list; the artifact never travelled |

---

## HOW IT REACHES EACH SEAT

**Tony:** the seal line at shutdown and the peas pass at session open — already live via
`genLadder/fixitNag.sh`.
**Clay:** the wakeup brief opens every session in front of Clay, so **Tony pasting the brief is
Clay's peas pass**, and Clay's first turn answers the same question — *take an item now, or name what
goes ahead of it.* **"The new thing is hotter" is legitimate and must be said, not defaulted into.**
**Clod:** the same brief, same rule.

⚠ **WHAT THIS MECHANISM DOES NOT REACH.** A `STATUS:` sweep catches what somebody **wrote down**. It
would **not** have caught the 2026-08-20 relay drop, where an amendment arrived and its parent ruling
never did — nothing was ever written anywhere. **Some forgetting is a channel problem, not a register
problem**, and what saved that one was a seat refusing to reconstruct a parent it had not seen.
