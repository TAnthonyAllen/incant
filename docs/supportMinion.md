# Support Minion — Charter

**STATUS: CHARTER, NOT A TASK.** This minion does not exist yet and must not be spawned
until the fire condition below is met and Tony says the word.

> **AMENDED 2026-08-03** (Clay, **countersigned Tony** — "if word from me needed, consider word
> given") — amendments applied inline
> and marked *(amended)*, answering margin notes M1–M4: fire-condition clause **(c)**, the census
> boundary, the `jigcorpus` naming correction, and the NON-GOALS rewritten in WANTED form. Applied
> to the body rather than appended so the charter stays **one** authoritative document — a frozen
> brief must not require its reader to mentally apply a diff.

*Dictated by Clay 2026-08-03, countersigned Tony. Second amendment round (TASK 0, NO GRINDING)
landed 2026-08-03 with Tony's word given. Transcribed by Clod per WT-9 (a brief Clod
will act on gets dictated and transcribed, because the transcription step is a second close
reader). The charter body below is Clay's text. Clod's reader-notes are quarantined in the
TRANSCRIPTION MARGIN at the foot — they are **not** part of the charter and carry no
authority.*

---

# SUPPORT MINION CHARTER — 2026-08-03, Clay, countersigned Tony

## FIRE CONDITION

This minion does not fire until:

**(a)** the `jitEmitUnary` ← `opPlusPlus` crash is fixed and the jitLadder is green over it — ✅
**MET 2026-08-03** (commit `ffb4812`; ladder 83 checks, exit 0), and
**(b)** the bare-lookup sweep has closed `oneTest baseline` — ✅ **MET 2026-08-03** (`generateCode
failed` 5 → 0; `maximus = 11` then `26 ×4`).

✅ **FIRED 2026-08-03. TASK 0 and TASK 1 complete and accepted** (floor snapshot `690dc59`; corpus
`b9aae1a`, 22 claims + 5 opens; leak check passed). **TASK 2 AUTHORIZED 2026-08-03 by Tony**, with
the `Buffer.rvsd` ambiguity ruled away first so the Buffer base is unambiguous: *what is in the tree
is the truth.*

*(Clause (c), "the support repo tree is clean", is **superseded** — it became **TASK 0** below, which
is stronger: a snapshot commit makes the floor reproducible whether or not the tree was tidy first.)*

**Tony's word fires it.** Until then this file is a charter, not a task.

## TASK 0 — SNAPSHOT THE FLOOR *(amended 2026-08-03)*

**First act on firing: commit the support tree verbatim as a floor snapshot.** The commit message
marks the content **unreviewed**; **no edits are permitted in the same commit**. **All census
provenance keys to that commit.**

*Why this replaces "land the dirty files first": an `asOf` against an uncommitted tree is an `asOf`
against nothing reproducible, and the recon would launder uncommitted work into "the floor" with
provenance that looks clean. A verbatim snapshot fixes the reference point without requiring anyone
to tidy 37 files first — and without pretending they were reviewed.*

## PREMISE

The support files predate most of the current discipline. They are about to grow (Buffer
registry, Display) and nobody holds a measured picture of what is in them or what still calls
them. **Build on a measured floor, not a remembered one.**

## TASK 1 — RECON, and the recon is the whole first life

Full census of the support files. Per file: what it contains, where each entry point is used —
**grep-counted with the command recorded as provenance, never recalled** — and which entries
have zero callers.

Output is a corpus file in the standard claim format (provenance, confidence, `asOf`) — *(amended)*
**a sibling corpus to the JIT's, with its own querier — not loaded into `jigcorpus`.**

**Census unit** *(amended)*: the **21 `Frame/*.twk`** plus **`BaseEntry.C`** as a C-only entry.
*(`Stack.C` was in this list and is **deleted as of 2026-08-03** — Tony ruled it a spent temporary;
`Stack.C`/`Stack.h` and its four `pbxproj` Sources entries are gone, so the `Stack.C`/`Stak.twk`
near-collision this list was warning about no longer exists. `CLAIM SUP-8` keeps the trail.)* **`SimpleList.twk` is in**, its
zero-caller status a **pre-registered hypothesis that still owes its grep** — a candidate excused
from measurement is exactly how a breakage gets frozen in as truth. **`BeforeRefactor/` is out of
the census proper**, in as **one claim** recording that it exists, is not gitignored, and awaits
Tony's word on whether it is archaeology like `Aside/` — the minion **records the ambiguity rather
than resolving it**.

**Deliverables:**
- a dead / park-aside **candidate** list — candidates only, **parking is Tony's signature**
- an answer to the open question *should any of kant migrate into the support domain* — the
  recon **informs** this, it does not decide it

**No source edits during recon.** Zero-caller claims are grep results, **not deletion
licenses**; the arc-that-was-deleted taught us *"unused"* and *"safe to remove"* are different
claims.

## TASK 2 — BUFFER: COMPRESS + REGISTRY

**Scope:** compress/decompress as a **self-inverse pair** on Buffer, POP'd in isolation
(compress→decompress→byte-identical · empty buffer · large buffer).

Then the registry: `getFile()` into a buffer field, fields collected in a registry list, a print
action rendering the registry in a format that reads back in.

**The load-bearing POP is the round trip:** write registry → read registry → every buffer
byte-identical.

**Format choice surfaces to Tony before implementation** — it is a wire-format decision with a
future web channel behind it.

⚠ **THE REGISTRY PRINT ACTION MUST PRINT THE *FIDELITY* FORM, NOT THE DISPLAY FORM**
*(ruled 2026-08-03, Tony; recorded here so the flag is waiting at the site when the action gets
built — nothing builds today).*

**Two print forms come off one walk:**

| form | behaviour | for |
|---|---|---|
| **display** | today's behaviour, unchanged — `noPrint` attributes elide | **eyes** (less clutter); the default |
| **fidelity** | **`noPrint` attributes SURVIVE** | **the archive**, and the round-trip oracle |

**The law line:** *a form meant to be **re-read as definition** must be **fidelity**; a form meant
for **eyes** may elide.*

**Why this task specifically owns it:** the archive **persists entities through the print form**,
and **re-reading a printed definition is defining**. So a `noPrint` `register` that vanished at print
**never fires on re-read, and a lit member comes back dark** — byte-identical storage, different
citizen. The registry round-trip POP (write → read → every buffer byte-identical) would pass while
silently changing what the restored tree *means*.

✅ **This also closes the `printDefinition` oracle blind spot by construction** (`docs/formsMinion.md`
margin M2 — `register` is consumed silently and does not echo, so a round-trip POP is blind to it):
**the archive prints what survives, because fidelity is *defined as* what survives.**

⚠ **KNOWN PREREQUISITE, Tony's, not this minion's:** `aCTionDefinE` currently **deletes a `noPrint`
attribute that has a method, after running that method**. Fidelity print needs those attributes to
still be there, so that behaviour has to change before the fidelity form can round-trip. **Named
here so it is not discovered at build time; the change itself is a runtime edit and is Tony's.**

**OUT OF SCOPE: encryption.** HPDL, coupled to key management, waits for a channel that makes
it real.

⚠ **Bear note:** Buffer sits in the tokenizer's blast path (`shorten` feeds `testContainer`).
Additions are **new methods only**, and any layout change pays the `groups.ext` + `tokall` toll
in full.

## TASK 3 — DISPLAY

Per `docs/guiDesign.md` (CGBitmapContext, kant draws into bitmap, Apple blits).

**Explicitly design-as-we-go with Tony; the charter grants no license to run ahead of the
conversation.** Follows Task 2 because the registry work will have warmed Buffer idioms Display
should mirror.

## STANDING DISCIPLINE

- Sandbox held and **leak-checked mechanically**, as the two prior minions did.
- Baselines captured before anything changes, diffed after.
- All instrumentation to `cerr`, **never stdout**.
- Every fixture under a wall-clock cap (**RULE H5**).
- Best-practice review of support code is **observations into the corpus, not drive-by edits** —
  fixes get proposed, signed, then made.
- ⚠ **NO SUSPICIOUS TEMPORARIES LEFT AMBIENT** *(standing discipline, all charters — Tony's
  ruling 2026-08-03)*. **Delete when spent · manifest when kept · attic when uncertain.**

  *Earned the day it was written: `Frame/BeforeRefactor/` (24 files mirroring the entire census
  unit, silently doubling every grep), `Frame/Buffer.rvsd` (an unreviewed alternate of the file
  TASK 2 was about to build on) and `Frame/Stack.C` (a dead class one letter from a live one, and
  still in a Sources build phase). None was a secret; each was a temporary nobody had swept.
  ⚠ **The three dispositions are not interchangeable** — attic-ing something ruled **spent**
  overstates its status, and deleting something merely **uncertain** destroys evidence. Say which
  of the three a file is, then act.*
- ⚠ **A CENSUS CLAIM THAT RESTS ON A PROBE REPORTS THE PROBE, NOT JUST THE CONCLUSION**
  *(amended 2026-08-03, Tony's signature, verbatim)*. **A readable command in the corpus is
  falsifiable where a confident sentence is just prose.**

  *Why it was signed the day it was proposed: on 2026-08-03 four confident claims died on
  measurements, and **three of the four came from instruments rather than from code** — a `.taG`
  existence test that is always truthy, an exit status taken through a pipe, a grep pattern that
  did not match the fixture's own output. A minion doing mechanical recon **is nothing but
  instruments**. NO GRINDING covers going slowly; this covers going fast and wrong.*
- ⚠ **NO GRINDING** *(amended 2026-08-03)*. On encountering trouble — ambiguity, a surprising
  measurement, a file that resists the census format, **anything that would tempt an extended solo
  struggle** — **pause and ask for direction**. *A paused minion costs a relay turn; a grinding
  minion costs its sandbox's credibility.* **Questions are the cheap path.**

## NON-GOALS

*(amended — rewritten in WANTED-not-deferred form; see M4)*

- **No md-structure work here — WANTED elsewhere:** it is a genParse-customer design with its own
  future brief.
- **No kant-file-system beyond the registry round trip — sequencing:** the round trip is the step
  that makes the next step visible.
- **No virtual-OS tasking — but the direction stands as Tony framed it:** *"maybe that is where the
  little steps for little feet is leading."* **Direction, not destination**; no brief until the
  steps make one real.

## CLAY'S FLAG TO TONY — OPEN, needs Tony's word

Task 1's corpus needs a **name for the support-file set** — *"support files"* has meant slightly
different things across months. If Tony names the exact file list (or the directory that defines
it), the census boundary is **pinned by him rather than inferred by the minion**.

*(Clod has measured a candidate boundary for Tony to sign or amend — see the margin below. The
measurement is an aid to the signature, not the signature.)*

---

# TRANSCRIPTION MARGIN — Clod, 2026-08-03

*Not part of the charter. Three notes, in the order they would bite.*

## M1 — The census boundary, measured so Tony can pin it in one word

Provenance — run 2026-08-03 against `~/data/support` @ `5030148` (working tree **dirty**, see M2):

```
ls Frame | sed 's/.*\.//' | sort | uniq -c | sort -rn
ls Frame/*.twk Frame/*.rtn Include KeyTable Maps
for f in Frame/*.C;   do b=$(basename "$f" .C);   [ -f "Frame/$b.twk" ] || echo "$b.C"; done
for f in Frame/*.twk; do b=$(basename "$f" .twk); { [ -f "Frame/$b.C" ] || [ -f "Frame/$b.mm" ]; } || echo "$b.twk"; done
```

`~/data/support` is **its own git repo** (own `CLAUDE.md`, own `TODO.md`, branch `main`).
Four content directories:

| dir | contents |
|---|---|
| `Frame/` | 21 `.twk` · 19 `.C` · 22 `.h` · 3 `.rtn` · 3 `.mm` + `frameIncludes`, `devDirectives`, `BeforeRefactor/` |
| `Include/` | 13 manifests/externs — incl. **`groups.ext`** |
| `KeyTable/` | `KeyMap` · `KeyTable` · `KeyTableItem` (3 classes) |
| `Maps/` | `BitMAP` · `Segment` · `perfect.c` · `maps` |

**The 21 `Frame/*.twk` are the natural census unit** — they are the source-of-truth set, and
each has its generated `.C`/`.h` beside it:

> BaseHash · Bot · **Buffer** · CharSet · DispatchQ · DoubleLink · DoubleLinkList · Hasher ·
> HashLink · HashList · OCroutines · PLGset · SearchItem · SearchNode · SearchTree · SimpleList ·
> Stak · StringRoutines · Tape · TapeSegment · URLservice

**Three edge cases the boundary has to rule on explicitly** — each is a different question, and
a boundary that doesn't name them leaves the minion to guess:

1. **`BaseEntry.C` and `Stack.C` have no `.twk`.** Hand-written, no source of truth. In or out?
   (Note `Stack.C` vs `Stak.twk` — two different things, one letter apart.)
2. **`SimpleList.twk` has no generated `.C`/`.mm`.** Either never built or built elsewhere —
   a zero-caller candidate before the census even starts.
3. **`Frame/BeforeRefactor/`** — 5 `.twk` and currently **modified in the working tree**. Is it
   archaeology (out, like `Aside/`) or live (in)? It is not gitignored, which is the argument
   for asking rather than assuming.

Also for the ruling: `Include/` holds `groups.ext`, whose blast radius is the *Groups* build.
Censusing it is useful; **editing** it is the `tokall` toll (bear-trap #10). Worth stating which.

## M2 — The support repo is 37 files dirty right now

`StringRoutines.{C,h,twk}` · `PLGset.{C,twk}` · `OCroutines.{twk,mm}` · `CharSet.twk` ·
`Include/{OCframe,frame,globals,GUIexternals,groups.ext}` · 5 files under `BeforeRefactor/` ·
and **four deletions** (`Include/BOT.ext`, `Include/IOSframe`, `Include/UIjit.ext`).

A minion whose first act is "measure the floor" would measure **uncommitted work** and bake it
into the corpus as the baseline. Two of the files it most needs to read (`StringRoutines`,
`OCframe`) are the exact pair behind bear-trap #17. **Whether this lands before the minion fires
is Tony's call** — but the charter's own "build on a measured floor" is the argument for it
landing first, since an `asOf` against a dirty tree is an `asOf` against nothing reproducible.

## M3 — Naming: `jigcorpus` is a corpus, not a loader

The charter says the output is *"loadable via `jigcorpus`"*. Measured: `incant/jigcorpus` is the
**JIT minion's corpus data**; `incant/jiquery` is the **query harness** that reads it. So the
support corpus would be a **sibling of `jigcorpus` with its own querier**, not something loaded
by it.

Almost certainly what was meant — flagged only because this project has been bitten by exactly
this shape before (`emitTerm` vs the live `emitLeaf`, wakeup 07-29), and a minion working from a
frozen brief cannot ask.

## M4 — The NON-GOALS are parks, and by the standard adopted the same day two of them are
## written in the wrong voice

Clay's ruling of 2026-08-03: *a park carries Tony's intent, not just Clay's sequencing —* **WANTED**
*rather than deferred, because a park in one voice says "later, maybe" and a countersigned one says
"later, certainly."* The three NON-GOALS above are the first items written after it, so they are its
first test:

| NON-GOAL | voice it is in |
|---|---|
| no md-structure work | **WANTED-shaped already** — it names a destination (*"likely a genParse customer"*), so a later reader knows where it is going |
| no kant-file-system beyond the round trip | **sequencing only** — says where it stops, not what it is stopping short *of* |
| no virtual-OS anything | **sequencing only**, and this is the one that matters — Tony's own framing was *"do not want to make too much of that, but maybe that is where the little steps for little feet is leading"* |

The third is the live case: **the charter's flat refusal is stricter than Tony's own words.** He
parked it *with* a direction; the transcription kept the park and dropped the direction. That is
exactly the difference the WANTED/deferred distinction was invented to prevent — and it happened in
the same document, on the same day, which is the argument for the distinction rather than against it.

**Not amended here** — the charter body is Clay's text and countersigned, so a rewrite is his and
Tony's, not the transcriber's. Flagged so the countersignature can be made deliberate. One sentence
in each of the two rows fixes it.

## Not a flag, just noted

**Fire condition (a)'s crash is on record with a backtrace** — `jitEmitUnary` (`GroupRules.mm:2424`)
← `opPlusPlus` ← `runOP`/`aCTionBlocK`/`jitExecBlock`/`jitRunAction`/`testing`, reproduced via
`incant/jitscratch`. Wakeup 07-28 records it as parked by Clay. Nothing owed here; it just means
(a) starts from a stack frame rather than from a search.
