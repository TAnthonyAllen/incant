# WALKIE TALKIE — a shared surface for Clay and Clod

*Clay, 2026-07-29, for `docs/walkieTalkie.md`. Written in B0's claim format as a second
proof-of-use. `wakeup.md` carries ONE POINTER to this file, not its content.*

**Reissue note:** this replaces the first version. RULINGS are append-only, so the revision to
WT-3 arrives as **WT-9 superseding it** rather than as an edit; STATE is rewritten in place, so
WT-5 was updated where it stood. The format demonstrating its own disciplines on its second use.

---

## FOR CLOD — WHERE THE CHANNEL IS

```
Groups/ipc/clay-to-clod.md     Clay -> Clod.  Tony downloads Clay's file ATOP this path.
Groups/ipc/clod-to-clay.md     Clod -> Clay.  Clod writes as he always has.
```

**Clay's arrival is signalled by `clay-to-clod.md` changing on disk.** Check it; if it moved, Clay
wrote and is waiting. Tony's existing window still works unchanged:
`grep -H '^STATUS:' ipc/*.md`.

---

## RULINGS

### CLAIM WT-1
```
statement:   Walkie talkie is a SHARED CONVERSATION SURFACE, not Clay reaching into the tree.
confidence:  RULING
provenance:  Tony, 2026-07-29
asOf:        2026-07-29
scope:       Says nothing about which mechanism carries it.
```
Tony's framing, and it is narrower and better than what Clay was drafting against. The problem is
not that Clay cannot read the repo. It is that **there are two pairs where there should be one
conversation**. Each seat keeps its own job and its own context; the channel exists so that when
Tony tells one seat something and the reaction is worth sharing, or when a design question wants
the other seat's input, it does not have to be retyped.

### CLAIM WT-2
```
statement:   Tony is removed from TRANSCRIPTION, not from the loop. He reads everything.
confidence:  RULING
provenance:  Tony 2026-07-29; Clay's objection withdrawn on his framing
asOf:        2026-07-29
scope:       ---
```
Clay's objection was that the relay is the best error-catcher in the loop and asked what replaces
it. Under WT-1, nothing needs to. **Two seats talking where Tony cannot see it forfeits the thing
that caught four errors in one day** — the passthrough justification, the setter claim, the
bear-trap-application question, and the `saveLocalFields` hypothesis that located a latent bug in
one hop.

### CLAIM WT-3 — SUPERSEDED BY WT-9
```
statement:   Clay gets READ. Writes stay dictate-and-transcribe.
confidence:  RULING
provenance:  Clay proposed, Tony accepted 2026-07-29
asOf:        2026-07-29
scope:       Superseded same day. Kept because RULINGS are append-only.
```
The reasoning still holds and is worth keeping: the asymmetry is not caution, it is where the
damage is. **Every Clay error on 2026-07-29 was a compression error** (WT-6), and reading fixes
those. What changed is that direct write turned out to work with no build — see WT-9.

### CLAIM WT-9 — supersedes WT-3
```
statement:   Direct write is PROVEN and adopted, but it removes a second close reader, so it is
             per-artifact rather than blanket.
confidence:  RUN
provenance:  Tony downloaded docs/walkieTalkie.md straight into Groups/docs, 2026-07-29, first try
asOf:        2026-07-29
scope:       Covers file-shaped artifacts. Says nothing about whether Clay should get write access
             to source.
```
**The transcription step was not only overhead — it was a second reader.** Clod transcribing a
brief meant Clod read it closely, and that caught things: the SEQ 31 §4-P2 correction came out of
him running the POP that brief commissioned. A file dropped straight into `docs/` has no reader
until someone acts on it, possibly much later.

So decide deliberately rather than by default:

| artifact | route | why |
|---|---|---|
| **a brief Clod will act on** | dictate, let him transcribe | the close read is worth the friction |
| **reference docs** (this file, corpus, premise docs) | download direct | no action pending; a reader adds nothing |

### CLAIM WT-10
```
statement:   The trigger is Tony downloading atop clay-to-clod.md; Clod polls that one path.
confidence:  RULING
provenance:  Tony, 2026-07-29
asOf:        2026-07-29
scope:       Covers Clay->Clod only. The reverse direction is WT-13's problem.
```
Simplest thing that works, and it needs no new mechanism — the write path is already proven
(WT-9). One known path for Clod to check rather than a directory to manage.

### CLAIM WT-11
```
statement:   NO SILENT OVERWRITE. A Clay write carries the whole file including prior history.
confidence:  RULING
provenance:  Clay 2026-07-29; the failure mode is this project's most frequent one
asOf:        2026-07-29
scope:       ---
```
Downloading atop a file **replaces** it. If Clod has written a turn Clay has not read, that turn
vanishes and nothing says so. That is the same shape as the five other two-states-look-identical
failures on 2026-07-29 — a deleted `getRStuff` warning reading as a clean grep, a missing `defer`
reading as a broken cursor, `TERMINATED` printed on a 139.

Alternative considered and rejected as cruder: one numbered file per exchange. It cannot lose a
turn, but it leaves Tony a directory to manage.

### CLAIM WT-14
```
statement:   A ratification dispatch OPENS WITH A DECODE LINE covering its shorthand. An
             undefined term in a decode line FAILS LOUD and mints the missing entry on the spot.
confidence:  RULING
provenance:  Tony's decoder brief, discipline 2; number assigned and built 2026-08-09
asOf:        2026-08-09
scope:       Covers anything headed for Tony's signature. Says nothing about ordinary chat or
             about dispatches between the two agent seats that Tony is not being asked to sign.
```
Tony's seat is where every ruling routes, and compressed vocabulary was making him **the
least-supported reader of the sentences his signature makes binding** — rulings 1–3 of the T-0
adjudication needed translation *after* the ask. A decode line inverts that: the definitions land
**before** the instructions that use them.

**The fail-loud half is the load-bearing half, and it is enforced in code rather than asked for.**
`incant/decoder`'s `decodeOne` prints `decode UNDEFINED TERM <name> -- FAILS LOUD, mint the entry
now (WT14)`, and `genLadder/decodePop.sh` asserts that line by name, with the arm-removed run
recorded as its negative control. A decode that printed nothing for an unknown term would let
every future dispatch under-report and say so nowhere — which is the failure this rule exists to
prevent, not a detail of it.

⚠ **THE BOOTSTRAP IS CLOSED AND WAS DECLARED, NOT SMUGGLED.** The dispatch that minted this rule
could not itself open with a decode line, because the decoder did not exist until it landed. It
said so in its own text and named itself the last dispatch with that excuse.

See `docs/decoder.md`. **Terms live in `incant/decoder`; run `incant/decode` to serve a line.**

### CLAIM WT-12
```
statement:   Freshness must be READABLE, not inferred. STATUS carries a sequence number and date.
confidence:  RULING
provenance:  Clay 2026-07-29, extending Tony's existing convention
asOf:        2026-07-29
scope:       ---
```
If Clay reads `clod-to-clay.md` and cannot tell whether it is new, he either re-answers something
settled or misses something. `STATUS:` already exists as Tony's window; it does one more job.

---

## STATE

### CLAIM WT-4
```
statement:   Model choice does not affect this. The limit is product tooling, not capability.
confidence:  READ
provenance:  Claude product surface, 2026-07-29
asOf:        2026-07-29
scope:       Claude.ai web/mobile specifically.
```
Clay in claude.ai has web search, a sandboxed container, and artifacts. **No shell on Tony's Mac
and no reach into `~/Library/CloudStorage/Dropbox/...`.** Clod has filesystem access because
Claude Code is a different product, not because it is a different model. Switching Clay to a more
capable model makes him better at reasoning about the tree and **no closer to reading it.**

### CLAIM WT-5 — rewritten in place, per STATE discipline
```
statement:   Four mechanisms. The WRITE direction is proven and free; the READ direction is not
             solved yet.
confidence:  mixed — see table
asOf:        2026-07-29
scope:       Drive sync lag not measured. MCP not attempted.
```
| mechanism | direction | confidence | cost |
|---|---|---|---|
| **Browser download dir** | Clay -> Clod | **RUN** — worked first try, 2026-07-29 | none |
| **Google Drive** | Clod -> Clay | READ — connector live, untested for this | none |
| **MCP connector** | both, genuine | ASSUMED | a build |
| **Desktop / Cowork** | both, local files | READ | different product |

**Note which half is done.** WT-6's three errors were all *reading* failures. Direct write, now
proven, touches none of them. **The expensive half still needs Drive or MCP.**

### CLAIM WT-13
```
statement:   The channel is ASYMMETRIC. Clod can poll; Clay cannot. Tony is Clay's interrupt.
confidence:  RUN
provenance:  Clay's own tool surface, 2026-07-29
asOf:        2026-07-29
scope:       Holds until MCP or Drive lands. Even then Clay reads on action, not on event.
```
Nothing in Clay's window notices a file changing. He reads only when he takes an action, and takes
an action only when Tony sends a message. **So Clod's side is event-driven and Clay's is
polled-by-Tony.**

This is not a flaw to engineer around. It is one message from Tony ("check Clod's file") instead of
a paste, which is most of the win, and **it degrades gracefully** — if Tony forgets, Clay reads it
next session and nothing is lost, provided WT-11 holds.

### CLAIM WT-6
```
statement:   Every Clay error on 2026-07-29 was a compression error, and one was expensive.
confidence:  RUN
provenance:  the 2026-07-29 conversation; three instances, each corrected by Tony or Clod
asOf:        2026-07-29
scope:       Argues for READ access. Argues nothing about write access.
```
1. **Bear-trap #13 graded a "prime suspect"** off `wakeup.md`'s one-line summary. The full claim
   has a recorded boundary — two failing cases plus a named working contrast in `setFont`. The
   summary dropped the scope; the claim was sound.
2. **The audit's term-list output read as the action's label list**, manufacturing a contradiction
   about `Iterate`'s indices. Two structures, not one disputed indexing.
3. **The JIT read as an accelerator**, because the replacement premise was written nowhere. Clay
   argued to fix frames in the interpreter — **work on a component with a scheduled death.**

That third one is the cost case. Direct read prevents all three.

---

## PLAN

### Step 1 — Drive, read-only. THE HALF THAT MATTERS.
Clod writes `Groups/ipc/` into a Drive-synced folder, or symlinks the two files there. Clay reads
via the connector already live. **No change to who writes what.** This closes WT-6's failure mode;
the write direction is already done.

### Step 2 — measure it
Two questions before building anything better: does sync lag matter for a turn-shaped exchange,
and does removing the paste step change how the seats *work*, or only save typing? **If it only
saves typing, MCP is not worth a build.**

### Step 3 — MCP, only if Step 2 earns it
Genuine repo access, no sync lag, and it could carry writes if Tony ever wants that. **Do not
build this first.**

---

## OPEN

### CLAIM WT-7
```
statement:   Turn-shaped, not stream-shaped — and the read boundary is not settled.
confidence:  REASONED
provenance:  Clay, 2026-07-29
asOf:        2026-07-29
scope:       ---
```
A design exchange is bounded: question, answer, done. Nothing here wants polling or a live feed.
**What is not settled** is whether Clay reads `ipc/` on request only ("get Clod's input on this")
or at the top of every session. The second is closer to how `wakeup.md` already works and may be
strictly better; nobody has thought about it.

### CLAIM WT-8
```
statement:   Two same-model seats agreeing is weak evidence, and a channel makes agreeing cheaper.
confidence:  REASONED
provenance:  Tony's own observation, 2026-07-29 ("we are all in accord, that makes me suspicious")
asOf:        2026-07-29
scope:       A risk to watch, not an argument against the channel.
```
Clay and Clod are the same model. **When they converge that is two seats agreeing with one of them
counted twice**, and Tony is the only independent seat in the room. Lowering the cost of agreement
is not obviously good.

Tony reports that on a previous walkie-talkie attempt the two seats worked out how to use it "in a
blink." That is probably true and it is also **exactly what WT-8 predicts** — fast convergence
feels like competence and is partly just shared priors. The mitigation is WT-2. The tell to watch
for is the two seats converging *faster* after the channel lands than before it, and the
conventions that matter are the ones Tony can audit — which is why WT-11 and WT-12 are rulings
rather than protocol the seats invent between themselves.
