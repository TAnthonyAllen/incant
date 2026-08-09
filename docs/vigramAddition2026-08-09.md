# vigram.md ADDITION — 2026-08-09 (dance session, Clay via Tony)
# Import below the existing content. Supersedes the byteIdentical stub's first
# two lines (correction noted in §2). Everything here is paper; VI-7's fence
# holds. The walker is DESCRIBED, not commissioned — see §7 for what is and
# is not authorized.

## §1 — TAXONOMY CORRECTION (Tony, tonight): the vigram is three populations, not one

What the stubs called "rules" splits into three different things:

- **ORACLE ACTIONS** — the comparison engines. Few, written once, boring on
  purpose. Tonight: `byteIdentical` (footed), `invariant` (defined earlier,
  footing NOT yet done — see §6 ordering). These are verbs.
- **REGISTRATIONS** — one per check. Each names its oracle and describes what
  to feed it. These are the sentences of the verification language. THE CENSUS
  COUNTS REGISTRATIONS.
- **CLAIM SCHEMAS** — the residue shapes (`correctness`; `divergence` if ruling
  O2 lands that way). Durable data minted by oracles.

The grammar is the shape of a registration plus the claim schemas. The walk is
their interpreter. Same three-part architecture as the language itself:
grammar as data, interpreter as walk, residue as corpus.

## §2 — byteIdentical, corrected footing (supersedes the stub's header)

- **NOT a parse rule. An oracle action, invoked with an argument.** There is no
  text anywhere in its story; input arrives as tree (a group built by a
  registration), read by field access. "Fires on" in the stub was parse
  vocabulary and is retracted.
- **No rule attributes.** The stub's `generation=` was wrong twice: it sat in
  attribute position, and it belonged to the input. The rule is timeless; the
  CAPTURE carries provenance.
- **Input (the argument group):**
  - `capture` — the carved bytes of one generation event, stamped with a
    generation identity BY THE WALKER at carve time (ruling O1 for
    representation). The oracle copies it through; it never computes it.
  - `baseline` — a name resolving through the registry to stored bytes, or a
    literal. Names are re-capturable on intended change; literals are frozen.
  - `parked designation` — present only if the registration carries one: the
    exact expected diff D.
- **Guard, at the top of the action: malformed argument FAILS LOUD.** Nobody
  "tries" this action against ambient input — a registration chose to invoke
  it and built its argument. A missing field means the registration is broken;
  silent decline would be a green-shaped hole one layer above C7's.
- **Comparison is byte-for-byte, no tolerance, no flags.** Any forgiveness is
  a DIFFERENT oracle kind with its own name and half-life, never an option on
  this one.
- **Verdict map (nothing silent anywhere in the action):**
  - malformed argument → LOUD (registry bug)
  - baseline name unresolvable → LOUD (missing oracle, C7 — never skip)
  - bytes equal → `matched`; mint `correctness(...)`, attach; return verdict
  - bytes differ → `failed` (durability of failure = ruling O2)
  - actual diff byte-equal to designated D → `parked` — ONLY when the
    registration pre-declared D. Never inferred: a diff that resembles D but
    is not byte-equal to it is `failed`, because the defect MOVED, which is
    news. (pop.sh's owned-red discipline, imported.)
- The only silent path left in the whole story is a registration that never
  invokes at all — and that absence is the census layer's job to catch. Clean
  division: the oracle cannot be silent; the census catches the missing.

## §3 — the correctness claim schema

A claim is not a call. It is a GroupItem the action constructs: label
`correctness`, five children. Minting is group construction with existing
primitives; a constructor helper (so a malformed claim is unconstructable) is
implementation weather, noted for V1.

| field      | answers                                                        |
|------------|----------------------------------------------------------------|
| kind       | which oracle family judged this (`byteIdentical`) — carries the kind's half-life |
| fixture    | what was judged                                                |
| baseline   | judged against what, BY NAME, so a later reader can check whether it has since moved |
| generation | provenance of the bytes — the hook that makes staleness computable |
| asOf       | when the verdict fired — "when did we last actually know this" |

Attachment target (fixture node vs. registration node) is a schema detail to
pin at V1, not a tonight ruling.

## §4 — THE WALK (seven steps, one registration)

Present tense: this walk already runs — spelled as shell, in pop.sh. The
description below must stay checkably true of pop.sh until a walker exists.

1. **Read the sentence** — fixture, carve recipe, oracle name, baseline name,
   parked designation if any. Malformed registration: LOUD, walk continues to
   the next entry — one broken sentence does not silence the census.
2. **Execute the fixture AS A SUBPROCESS**; harvest output and exit status.
   (See INVARIANT W-A below — this is not an optimization choice.)
3. **Carve the capture** per the recipe; stamp its generation here — the
   walker owns provenance (see INVARIANT W-B).
4. **Build the argument group**: capture, baseline name, parked designation if
   registered. The designation travels IN the argument so the parked verdict
   is attributable to the check, not to walker bookkeeping.
5. **Resolve oracle name → action, invoke** with the argument, via the
   settled interpreted channel (jitRunAction path). Resolution failure is
   LOUD, C7-grade — a sentence citing an oracle that doesn't resolve is
   broken, never skipped.
6. **Two channels return.** Verdict up to the walker: tallied, one line
   printed per check (pop.sh's own format), exit folded at the end. Claim
   attached by the oracle before returning: durable, accumulating into the
   corpus across runs. Today's fleet has only the first channel; the second
   is what the vigram adds to the world.
7. **Next registration.** At the end: banner, counts, exit — the banner is
   DERIVED FROM THE TALLY, never written independently. A summary
   contradicting its own rows is the mixed.sh failure; this design makes it
   unconstructable.

## §5 — TWO INVARIANTS (architecture, not procedure — H7-stated)

- **W-A: THE WALK ORCHESTRATES; FIXTURES STAY SUBPROCESSES.** Remove this and
  the first 139 kills the run and every check behind it; jsonTest structurally
  cannot run two failing cases in one process (diversion boundary); crash
  fixtures eat buffered stdout (`script -q` lore). In-process fixture
  execution is a violation of the paper, not a deviation from it.
- **W-B: WALKER OWNS PROVENANCE AND TALLY; ORACLES OWN JUDGMENT AND CLAIMS;
  THE WALKER NEVER TOUCHES CLAIMS.** Remove the first half and comparison
  inherits extraction's bug population (the eight slips lived in the
  carve-and-count layer). Remove the second half and the runner can corrupt
  the corpus. The two channels have different consumers at different times:
  verdicts answer "did it pass, right now, to the runner"; claims answer
  "what do we know, and since when, to any future reader." Neither
  substitutes for the other.

## §6 — REGISTRATION SCHEMA, and the goal restated as a TRANSLATION CENSUS

A registration carries: **fixture · carve recipe · oracle name · baseline
name · parked designation (with its exact diff D) — optional, explicit.**

The goal is NOT "write the registry." The registrations already exist —
smeared across pop.sh, mixed.sh, completePop, tree.sh as fixture names, sed
ranges, target paths, and parked designations. The work is a TRANSLATION
CENSUS: read each shell-spelled check, re-spell it as a registration
sentence, count as you go.

- **Two-number metric, free:** the fleet already reports its check population
  every run. *N checks in shell, M translated.* Same honesty discipline as
  the campaign metric.
- **Ordering by oracle-kind readiness, not script age:** pop.sh first — its
  checks are the cleanest byteIdentical population (carve, target, diff,
  three parked). mixed.sh's conservation relation is DEFERRED — it is
  invariant-kind and that oracle's footing has not had tonight's treatment.
- **Prediction, on record:** at least one shell check will have no coherent
  registration spelling. That check is either a fifth oracle kind or a bug
  wearing a harness. Either way it is a finding, not friction.

## §7 — FIRST-CUT IMPLEMENTATION PLAN (the cut IS the plan)

Three phases. Each names its entry condition and what it deliberately does
not do. Only V0 is authorized by this document.

**V0 — PAPER (now; VI-7-legal; no Clod keyboard time beyond transcription):**
- Ratify the registration schema (§6) and the correctness schema (§3).
- Run the translation census on pop.sh's checks; record N/M.
- Rule the opens (below).
- Does NOT: build anything, touch the fleet, define invariant's footing
  (separate dance).
- Exit criterion: pop.sh's population fully spelled as registrations on
  paper, with the predicted misfit either found or its absence noted.

**V1 — RESIDUE ON THE SETTLED FLOOR (entry: V0 exit + Tony's go):**
- `byteIdentical` implemented as a classic rule action (interpreted channel —
  the checking layer stands on the settled floor, never on the campaign's
  unverified mechanism; migration to folded CodE happens only after that
  mechanism is itself certified, and by then the oracle population is
  censusable data, so the migration is enumerable).
- The correctness constructor helper; registry as kant data seeded from V0's
  census.
- Smallest honest proof: ONE pop.sh check runs both ways — shell and
  oracle-invocation — and the two verdicts agree on the same capture. That
  is the parity anchor pattern, reused.
- Does NOT: build the walker, retire any shell check, touch mixed.sh.
- pop.sh remains the fleet of record throughout; V1 output is corroboration.

**V2 — THE WALKER (entry: campaign demand, stated in writing):**
- The demand signal is already visible and already has a shape: the
  blast-radius rider on installs is the walker's job description written in
  shell. When carrying that rider by hand across installs costs more than
  building the walk — and someone writes that sentence down — V2 opens.
- Walker per §4, invariants per §5, banner-from-tally per step 7.
- Parity gate before pop.sh retires: full-population agreement, both
  runners, same captures, N for N.
- Does NOT: open before its demand sentence exists. Interesting is not an
  entry criterion; the fence held precisely because it wasn't.

## §8 — OPEN RULINGS (Tony's), consolidated

- **O1 — generation representation:** counter, timestamp, or content-hash of
  the emitted bytes. Clay's argued vote: HASH — makes "same generation" a
  checkable fact rather than a bookkeeping claim, house style.
- **O2 — failure durability:** verdict-only (stub as written) or mint a
  `divergence` artifact on mismatch (diff + same five provenance fields), so
  "what failed, against what, when" is corpus data rather than scrollback.
  Distinct label either way — never a null `correctness`; a claim labeled
  correctness whose content is "not actually" is a lie shaped like a fact.
- **O3 — baseline recapture semantics:** on intended change, does recapture
  retire old claims (eager) or do claims' by-name baseline references simply
  let a later staleness pass find them (lazy)? Clay's lean: LAZY — matches
  how everything else here treats history.
- **O4 — naming:** `byteIdentical` vs `byteIdentant` — both spellings are in
  circulation from day one, which is the decoder's disease in miniature.
  This document uses `byteIdentical` (Tony's paste). Settle it; the loser
  gets a decoder entry reading "former spelling of —".

## §9 — PROVENANCE

Dictated by Clay 2026-08-09 evening (dance session, parallel to Clod's rung 1
— nothing here crosses to Clod mid-install; routes as a written doc per WT-9,
import via ~/Downloads, SEQ-25-style). The footing that produced §2 came from
Tony's questions forcing two retractions: `generation=` out of attribute
position, and "fires on" retracted as parse vocabulary. The taxonomy in §1 is
Tony's. Doubt-the-instrument applies to this document as to any sealed text:
every present-tense claim about pop.sh's mechanics is checkable against
pop.sh and should be, once, before V0 exits.
