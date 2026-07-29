# SEQ 30 — MINION B, TASK B0: the claim format, and the tok-claim sweep that proves it

*Clay brief, 2026-07-29. For Clod to transcribe to `docs/mdReorgB0.md`. Tony ruled every item
below; where I am proposing rather than relaying, it says so.*

---

## WHAT B0 IS

B0 settles **the format every reorganised md file is written in**, and proves it by grading a
real class of claims rather than an invented one.

B0 is **not** the JIT collapse. It is the only gate on firing minion A, so it is deliberately
small.

| task | contents | blocks |
|---|---|---|
| **B0** | claim format + confidence scale + attic manifest + the tok-claim sweep | **minion A** |
| B1 | collapse the JIT md files into `docs/jit.md` | nothing |
| B2 | cut `wakeup.md` to 40–60 lines; durable content to `docs/`; `docs/runbook.md` | nothing |
| B3 | the remaining md corpus | nothing |

**A fires when B0 lands.** Not when B lands. B1–B3 run alongside A indefinitely.

---

## 1. THE ORGANISING PRINCIPLE — sort by decay rate, not by topic

The test for which section a claim belongs in is **what would falsify it**.

| section | falsified by | write discipline |
|---|---|---|
| **RULINGS** | Tony reversing it | append-only, dated, never edited in place |
| **STATE** | a POP run | rewritten in place; every claim names its POP command |
| **PLAN** | landing | deleted when it lands, never archived |
| **OPEN** | someone measuring it | carries the measurement **command**, not a description of it |

This is not a new invention. It is how `wakeup.md` is already organised in practice; B0 only
makes it explicit and consistent so a harness can read it.

---

## 2. THE CLAIM RECORD

```
### CLAIM <id>
statement:   one sentence, falsifiable
confidence:  RUN | MEASURED | READ | REASONED | ASSUMED
provenance:  the command, or file:line, or the person who ruled it
asOf:        YYYY-MM-DD
scope:       what this claim does NOT cover
```

`provenance`, `confidence` and `asOf` are the corpus fields — **the same three a task corpus
carries.** That is the point: a file written this way is already corpus-shaped and a
`jiquery`-style harness reads it with no converter.

**`scope` is Clay's addition, and it is load-bearing.** It came out of the setter-dispatch
question on 07-29: a claim that holds *conditionally* and does not carry its condition is worse
than no claim, because it passes review and traps later. If a claim cannot state what it does not
cover, it is not ready to be written down.

### The confidence scale — how the claim was established, not how sure anyone feels

| value | means | what a reader does |
|---|---|---|
| **RUN** | a POP proves it; command attached | act on it |
| **MEASURED** | read off the live tree once (`termScratch`-style) | act, but respect `asOf` — the tree moves |
| **READ** | read off source, not executed | act with care |
| **REASONED** | argued, never checked | **do not act — check first** |
| **ASSUMED** | inherited from a brief, or a guess | treat as an open item |

### ⚠ A CLAIM NAMES ITS VERIFIER — and deleting a verifier DEMOTES the claim
*Added 2026-07-29, Clay's ruling, on the first instance of it. This is a sixth
field in practice, and it earned its place the same day the scale shipped.*

```
verifier:    the thing that would go red — command, fixture, or assertion
```

> **A RUN claim whose verifier has been deleted is not RUN anymore.** Not false —
> *no longer provable*. Deleting a verifier demotes every claim standing on it,
> and the demotion is the point: `asOf` says when it was true, `verifier` says
> whether anyone would still notice if it stopped being true.

**The first instance, and it is exact.** *"rStuff is materialised at define time;
late materialisation fires ZERO times"* was **RUN** as of `168195b`, verified by
`getRStuff`'s `no rStuff - creating` cerr. That cerr was removed on 2026-07-29.
Grepping the fixtures for it now returns zero **in two indistinguishable cases** —
nothing fired late, and the instrument is gone. The second was true. The claim
had quietly stopped being checkable while continuing to read as green.

**The general rule this yields, which is bigger than the field:**

> **An ABSENCE-based check passes just as well when the check itself has been
> deleted. A PRESENCE-based one cannot.**

So a verifier should assert *something is there*, not that a warning is missing.
That is why `auditRegistry` prints its count unconditionally and `pop.sh` asserts
the line is present with a zero count — delete the auditor and the POP goes red,
which is precisely what the cerr could never do. Restoring the cerr would have
been the weaker fix: it only fires on the path that goes wrong, so it still
cannot tell you the instrument is alive.

**Third instance of one shape in a single day** — and the shape is now named:
*fresh vs exhausted* in the iterator, *thin method vs absorption* in the minion-A
harness (§3(c)), and *nothing fired late vs the instrument is gone* here. **Two
states that look identical from outside, with the benign one masking the other.**
When a check can pass for two reasons, say which one you are seeing.

---

Two consequences, and they are the reason for the scale rather than a freeform one:

- **REASONED and ASSUMED are the challenge queue.** `absorb`/`challenge` finally has a finite,
  named worklist instead of re-reading everything.
- **A file whose claims drift downward over time is rotting**, and that is now visible at a
  glance. Cheap health check at every reseal.

**Adjacency is not provenance.** The tok-passthrough claim (see §4) read as RUN because it sat
beside bear-trap #13, which *is* evidenced. It was ASSUMED. Grade each claim on its own
provenance, never on its neighbour's.

---

## 3. THE BLOCKED RECORD — for minion A, specified here because it is a format question

```
### BLOCKED <id>
wanted:      what was being expressed
source:      the C++ being converted
attempts:    at least two, with the actual output pasted
category:    IDIOM-GAP | TOK-BUG | KANT-GAP
```

**Assume in this order. This ordering is the whole mechanism.**

| assume first | | assume last |
|---|---|---|
| **IDIOM-GAP** — the minion does not know the idiom | **TOK-BUG** — kant expresses it, tok will not compile it | **KANT-GAP** — kant cannot express it |

**A KANT-GAP claim requires the failing tok run pasted in — actual error output, not an
assertion.** ~~That makes it land as RUN instead of REASONED.~~ Cheap to meet when the gap is real;
impossible when it is not.

> **⚠ PROVISIONAL — PENDING SEQ 30a.** Clay withdrew the struck sentence on 2026-07-29: a failing
> run proves **the text did not compile**, not that kant cannot express it. A KANT-GAP claim is a
> *negative* claim, and a negative claim is never established by one failing example — it needs
> exhaustion or authority. The requirement to paste the run **stands**; only the grade it earns is
> in question. Do not absorb the struck sentence while SEQ 30a is open. Everything else in this
> brief stands. See `docs/tokClaims.md` "Open — the `signed:` field".

**`query` is step one on every BLOCKED candidate — grep the tree for the construct before
writing any failing test.** A limitation claim dies to a working counterexample faster than to a
new test, and the counterexample carries more: it shows the idiom, not merely that one exists.
The 07-29 disproof was three functions away and nobody looked, because looking was nobody's
step one.

**The risk is inverted from the obvious one.** A real gap announces itself every time it is hit.
A false gap is *self-sealing*: the workaround works, nobody returns, and the belief is now
documented as fact.

---

## 4. B0's OPENING TASK — the tok-limitation sweep

Tok-limitation claims are a class, and the class has already returned hits before being
commissioned. Grade every one in the tree. Any that cannot produce a failing run is demoted to
ASSUMED and queued for challenge.

### The four known entries, and their grades on arrival

**These are graded from Tony's 07-29 pastes and from `wakeup.md`. Clay has no filesystem reach;
every one is `READ` or worse until Clod runs it.**

1. **`setParseMethod`'s justification — "tok has no syntax for it" — is FALSE.**
   Disproof: `ruleMethod()` contains `method = dlsym(RTLD_SELF,name);` as a bare tok line,
   assignment position, no passthrough, and it ships. → **attic**, with what was believed, what
   disproved it, and the commit still holding the old text.

2. **`dlsym` in argument position works.** `ruleMethod` has
   `setOperat(dlsym(RTLD_SELF,name));`. Currently READ; running it makes it RUN.
   **`scope` matters here:** this does *not* generalise to argument position broadly —
   bear-trap #13's cousin (juxtaposed concat in argument position) is a different construct and
   is still believed broken. Two constructs, same position, opposite results. That distinction
   is itself a claim.

3. **Assignment dispatches through the setter.** Tony, 07-29: `operat = dlsym(RTLD_SELF,name);`
   would run the setter. Currently **ASSUMED — his word, and the scale applies to him too.**
   If true, **every explicit `setX(...)` call in the tree is optional**, which is a class and
   not a case.

4. **Bear-trap #13 SURVIVES.** The correction kills the *justification* and probably the
   *instance*; it does not touch the general claim that an incant-level local referenced only
   inside a passthrough is pruned as unused. It has bitten twice with real error output.
   **Take the distinctions, check the attributions** — do not let a good correction take a
   sound neighbour down with it.

### POPs owed, smallest first

- **P1** — `parseMethod = dlsym(RTLD_SELF,name);` in `setParseMethod`'s context. Promotes 1 to RUN.
- **P2 — setter dispatch, three scopes, and the claim names which it covers:**
  - assignment under `use`, as `ruleMethod` actually has it
  - assignment on a plain qualified field (`x.operat = ...`)
  - bare assignment in a method's own scope

  ~~Both `ruleMethod` lines sit inside `use input`, so `method =` resolves against `input`, not
  `this`. **A POP written outside a `use` block tests a different construct** and can come back
  green while the in-context case differs.~~

  > **DISSOLVED by the POP it commissioned — CLAIM TOK-5, `docs/tokClaims.md`.** `method =` binds
  > to **`grup`**, not `input`: tok resolves a bare field against the **most recently mentioned**
  > field, and `GroupItem grup = parent;` sits between the `use input` and the assignment. `use` is
  > not what binds here, so an outside-a-`use` POP tests the **same** construct. Confirmed against
  > `GroupRules.mm:5632`, which reads `grup->setMethod(...)`.

  Second question, and it decides whether the claim is usable: **does it hold for all
  setter-bearing fields, or only ones declared some particular way?** *"Sometimes dispatches the
  setter"* is worse than *"never does"* — it is a trap that passes review. Conditional answer →
  the condition goes in `scope`, or the claim is not written.
- **P3** — run 2 as written.

### The finding underneath all of it, and it is bigger than the cast

`ruleMethod` is not a sibling that happens to cast. Read what gates it — `if input.fLAG`, the
error path *"should be invoked as an attribute when its parent is defined"*, and
`grup.immediateACTION = true`. **It is the same mechanism as `parseMethod=`**: a definition
attribute resolving a name to a symbol and binding it to a fnptr field on a rule.

So a working implementation of this exact task already existed, and `parseRuleMethod` /
`setParseMethod` was written from scratch in passthrough beside it.

**Not a drop-in** — `parseMethod` is a `RuleStuff` field with a different signature (one
argument, returns `GroupItem`) than `method`. But the rewrite mirrors `ruleMethod`'s shape rather
than inventing a second one. Tony ruled 07-29 that `setOperat` is a plain setter call and the
method/operator asymmetry is **historical, not a signature difference** — so the rewrite takes
the direct-assignment path.

**This rewrite is NOT part of B0.** B0 grades the claims and records the finding. The rewrite is
its own work, after P1 and P2.

---

## 5. THE ATTIC — a manifest, not a pile

Tony ruled that deletions must be recoverable. **Git already holds every deleted line
permanently**, so a pile holding *content* is a second and worse copy, and it recreates the
accretion the reorg exists to end.

What git does not give is **discoverability** — you cannot grep for "things that used to be in
docs." So the attic is one line per removal:

```
what · when · why removed · commit that still holds it
```

Recovery stays one `git show <commit>:<path>`. The attic stays small enough that it never becomes
the thing needing reorganisation.

**Delete authority is granted, scoped:** the minion may not delete anything whose landing commit
it cannot name. Same discipline as accounting for a census move rather than regenerating it
green.

**The shutdown task is therefore a review, not a purge.** Content never leaves git; "final
delete" means closing the review window — walk the manifest, confirm nothing is wanted, Tony
signs, clear it.

---

## 6. ACCEPTANCE TEST FOR B0

**B0 is done when the four §4 entries are written as claim records and the format did not have to
be bent for any of them.**

Proof by use, not by review. If a real claim will not fit the fields, the format is wrong and
moves — and whoever moves it accounts for the move. An invented example proves nothing; that is
the same argument the census earns its place on.

Also required to land:
- the attic manifest exists and carries entry 1
- P1, P2, P3 run, exit status checked, and each claim's confidence updated to what the run
  actually supports

---

## 7. WHAT B0 MUST NOT DO

- **Must not touch the JIT files.** That is B1.
- **Must not touch `wakeup.md`.** That is B2, and it is the largest single edit in the reorg.
- **Must not "fix" anything the sweep finds.** Grade, record, queue. The `setParseMethod`
  rewrite and the `setX` sweep are consequences, not B0.
- **Must not grade a claim by its neighbour's provenance.** See §2.
- **Must not run `tokall`** — Tony's Group-A files are still uncommitted. Standing constraint
  from `wakeup.md`, unchanged.

---

## 8. STILL OPEN, AND NOT B0's

- **The iterator.** It lands hard in genParse — `emitPlan` walks the plan twice by design, the
  walk walks the term list, the census walks 30 rules, `manyScafC1` is a hand-rolled `while`.
  **Clay does not have the design** and will not brief a minion against a guess. Minion A's
  cadence is table → string assembly → control flow; **only the third step needs it**, so A
  fires on steps 1–2 while the iterator settles, and it arrives exactly when first load-bearing.
  No rework, no waiting.
  If the iterator is still a sketch, steps 1–2 file every wanted-an-iterator site as a
  BLOCKED-adjacent record — a requirements document written by use rather than by speculation.
- **Tony's `setRuleStuff` change** — per-insertion rather than Clod's two completion points.
  Owes: does `setRuleStuff` derive anything from the member list; `getRStuff`'s
  `no rStuff - creating` warning firing **zero** times across all four fixtures (that, not
  commented-out-and-still-green, is the proof `materialiseTerms`/`materialiseRegistry` are dead);
  every census line that moves named; and the `Limit ']'-` bare-modifier trap watched
  specifically, since earlier materialisation risks fabricating a classification rather than
  discovering one.
- **NEXT-0 recon**, unchanged from `wakeup.md` — two read-only greps, gates NEXT-1.
