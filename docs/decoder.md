# The decoder — the project glossary as kant data

**Status:** ✅ **BUILT AND GREEN, 2026-08-09.** Brief ratified in principle (Tony) ·
dispatched 2026-08-09 (Clay via Tony) · built the same day · **`parked` is HELD**, awaiting
Tony (see §8).

```
incant/decoder            the corpus (34 terms) + the print verb.  Registry file.
incant/decode             the runner. EDIT THE DECODE LINE AT THE FOOT and run.
incant/decodeT            the POP fixture -- produces the quantities.
genLadder/decodePop.sh    the instrument -- compares them.  22 checks, exit 0.
incant/setup              one line added: `decoder File='incant/decoder';`
```

⚠ **WHY THIS FILE EXISTS AT ALL, and it is the brief's own diagnosis landing on the brief.**
The dispatch was relayed in chat, acknowledged in chat, and **written down nowhere** — discovered
when Tony asked whether it had been recorded and the repo answered no. The decoder exists because
the project's vocabulary lives outside the system; **its own brief was living outside the system**,
which is Amendment A's citation-rot risk in the same shape Tony ruled on for the vigram files
one hour earlier. Transcribed against Tony's sticky as the authority — **if the two disagree, the
sticky wins and this file is corrected.**

---

## 1. WHAT IT IS

The project's working vocabulary — **H-numbers, campaign nouns, doctrine shorthands, fixture
names** — used to live in seals, `CLAUDE.md`, and the humans' memory. That was **the vigram's
diagnosis pointed at our own discourse: claims about the system living outside the system.**

**Tony's design, ratified in principle and now built:**
- A **term** is a GroupItem carrying a **name** and a **one-line definition**.
- The **corpus** is a group (`decodeCorpus`, registry `Decoder`).
- A **shortcut rule action** prints definitions on demand (`decodE`, `decodeAll`).

## 2. THE USAGE SHAPE, WHICH IS THE POINT

A dispatch may open with a **decode line**:

```
decode: H4 H7 blastRadius
```

**As built, that is one call with N names** — measured, not assumed:

```
decodE(H4 H7 blastRadius);
```

An action takes one argument, so a multi-name call arrives as a synthesised node whose **members**
carry the names; `decodE` walks them (reversed, so they print in the order written). A single-name
call arrives with **no member list at all**, which is why `decodE` guards on `listLengtH` before
iterating. The runner `incant/decode` is nothing but the invocation, so serving a decode line is a
one-line edit and never a copy of the machinery.

**Purpose, stated plainly:** Tony's seat is where every ruling routes, and compressed vocabulary
was making him **the least-supported reader of the sentences his signature makes binding.**
Rulings 1–3 (the T-0 adjudication) **needed translation after the ask.** This inverts that
permanently.

## 3. HOW IT WAS BUILT — and it stayed inside the campaign-hours test

Implemented as a **plain kant group with a print verb**, not a corpus file: the jigcorpus
apparatus (confidence grades, provenance, searched-space, an acceptance test) exists to stop an
agent serving a falsehood about a *moving tree*, and a glossary entry is a definition, not a claim
about behaviour. **The verb lives WITH the corpus** rather than in the runner, so a caller cannot
reach the table without the discipline.

⚠ **ONE OUT-OF-FILE DEPENDENCY, and it is the kind that bites silently.** `include(X)` does **not**
search a path — `getFile` opens the name relative to the working directory, and every includable
file is registered by hand in `incant/setup`'s `fILEs` registry (`grammar`, `utilities`,
`unitTests`, `jigcorpus`, …). A new corpus file that is not registered there fails with
`getFile: could not open file: <name>` **and the run continues to exit 0**. One line was added:
`decoder File='incant/decoder';`.

## 4. THREE DISCIPLINES THAT RIDE WITH IT — channel-rule grade

1. **SAME-DAY MINTING.** A term appearing in a seal or a SEQ gets its one-line entry **that day**,
   minted by whoever coined it, **transcribed by Clod either way**. Cost is near zero at mint time
   and **unpayable six weeks later**.
2. ✅ **RATIFICATION DISPATCHES NAME THEIR TERMS — this is now `WT-14`**, registered in
   `docs/walkieTalkie.md`. Anything headed for Tony's signature carries a **decode line** covering
   its shorthand. **An undefined term in a decode line FAILS LOUD and mints the missing entry on
   the spot** — a missing definition is **a finding, not a shrug**. Enforced in code, not
   documented: `decodeOne`'s else-arm prints `decode UNDEFINED TERM <name> -- FAILS LOUD, mint the
   entry now (WT14)`, and `decodePop.sh` asserts that line **by name** with the arm-removed run
   recorded as its negative control.
3. **BACKFILL IS A CENSUS, NOT AN ESSAY.** Done — 34 terms, one sentence each. Where a term's
   meaning has drifted across seals, the entry records **the current binding and nothing else**;
   history stays in the seals, and **the decoder is present-tense only.**

## 5. THE SEED CENSUS — 34 terms

```
  H1 .. H9                  9   the standing harness rules
  campaign nouns            5   firstLight gapB vigram endGoalCycle blastRadius
  doctrine one-liners       3   degradeAssertsOccurrence citationLosesToMeasurement
                                structuralVsCausal
  WT1 .. WT14              14   minted from docs/walkieTalkie.md; WT14 is new today
  earned by the V0 pass     1   ownedRed
  HELD                      1   parked          <- unratified slot, §8
  RESERVED                  1   byteIdentical   <- waits on vigram O4, §9
```

## 6. ⚠ THREE PULLS CAME BACK CORRECTED — the artifact justifying itself on its first run

The dispatch split its entries: **unmarked** sentences are the binding as dictated; **⚠ PULL**
entries were flagged by Clay as citations rather than measurements, to be transcribed from the
**minting seal**, seal winning on disagreement. Three disagreed, and the two-class discipline is
the only reason they were caught.

| term | the dispatch's draft | what the seal says | verdict |
|---|---|---|---|
| **H4** | "the campaign's ruling numbers are printed as scalars by an instrument" | *"Assert presence-with-value, never absence-of-message."* | the draft is **rung 1's DISCHARGE of H4**, not H4 |
| **H9** | held: "a refusal census reports frontiers, not blocker sets" | primary is *"a census matches the idiom family, not the surface form"*; the held sentence is filed as the **corollary** | corollary promoted in the draft; primary restored |
| **degradeAssertsOccurrence** | "a degrade count asserts that jit execution occurred… degrade 0 claims the compiled path ran" | *"A degrade line asserts that a fallback OCCURRED, never that the fallback was SOUND"* | **materially different fact** — the seal is about fallback soundness, the draft about jit occurrence |

**The third is the expensive one**, because the seal's version carries an obligation the draft
does not: soundness is **per-construct**, E2 is the counterexample, and the degrade-zero rule
cannot distinguish a handled fallback from an unhandled one. A decoder serving the draft would
have retired that warning by definition.

⚠ **AND ONE DIVERGENCE LEFT STANDING AS DICTATED, flagged rather than silently resolved.** **H6**
was unmarked, so its dictated sentence is the binding: *"a row pinned green-while-defective goes
red on repair and graduates with a re-pin sentence; pins assert values, never counters."*
`CLAUDE.md`'s headline is **wider** — *"a parked pin that starts passing must graduate"* — and
covers the parked case the dictated sentence does not name. **Tony's call**, and it is entangled
with §8: if `parked` sorts into three terms, H6's wording has to say which of them it governs.

## 7. WHAT THE INSTRUMENT ASSERTS — and what it cannot

`genLadder/decodePop.sh`, **22 checks, exit 0**, H1 binary echo, H5 wall-clock cap, `$?` taken
directly. Three negative controls **measured 2026-08-09**, each reddening its own rows while every
other row stays green:

| mechanism removed | green | rows that go RED |
|---|---|---|
| `ownedRed`'s `definition=` line | 18/22 | TALLY definitions 34→33, every-term-defined, decodeT's self-cert 5→4 |
| `decodeOne`'s fail-loud `else` arm | 21/22 | the UNDEFINED TERM line is absent |
| `ownedRed` written `definition=(#)` | 21/22 | the dataless-echo row, 0→1 |

⚠ **THE FIRST DRAFT OF THE LOAD-BEARING CHECK WAS VACUOUS AND WENT GREEN**, and the control is
what said so. It tested `grup.definition == grup.taG`, copied from `jiquery`'s section 0; deleting
a definition outright **left it green**. Measured, three shapes side by side:

```
  definition="real text"   -> reads the text          truthy
  no definition at all     -> reads 0                 FALSY    <- caught by counting
  definition=(#)           -> reads the string "definition"    truthy, and compares
                                                       equal to NOTHING
```

So the **absent** case is caught in-language by counting truthiness; the **present-but-dataless**
case is caught by neither count — it **prints** as the attribute's own name and does **not compare
equal to it** — and is asserted only by a grep on the printed line. That asymmetry is the whole
reason a shell POP exists beside the fixture.

⚠ **AND THE FINDING THAT TRAVELS: `jiquery`'s own section-0 content check cannot fire.** It
compares a claim's value against **the CLAIM's tag**, while a dataless value echoes **the
ATTRIBUTE's name** — `"content"` is never equal to `"corpusDecayMeasured"`. The check that exists
because *"the corpus silently lost its own content and nothing noticed for a month"* is, on the
identical shape, measured not to detect it. **Reported, not fixed here** — it is jigcorpus's
instrument, not the decoder's.

⚠ **A SECOND VACUOUS ROW, caught inside this build:** the slot check first grepped for
`RESERVED SLOT` and matched **the fixture's own section header** (`=== E. UNRATIFIED / RESERVED
SLOTS ===`) rather than the entry — a check satisfied by the label above the thing it was
checking. Both slot rows now assert a phrase that occurs only inside the definition.

## 8. ⚠ `parked` IS HELD — TONY RULES, WITH BOTH SENTENCES ON THE TABLE

Clay held his own candidate pin on 2026-08-09, before ratification, on a collision he found by
reading a backed-up `clod-to-clay` SEQ 44 **after** drafting the dispatch — *"the citation pattern
with my own name on it, caught by one day of channel lag."* The entry is therefore a **slot, not a
definition**, and says so in its own text so a decode of it cannot be misread as a ruling.

```
  candidateA  (decoder dispatch, item 7)
      Deliberately not worked now, with a named owner and a recorded reason --
      a scheduling state, not a verdict.

  candidateB  (clod-to-clay SEQ 44, PINCH 6 -- written FIRST, verbatim)
      Parked means nobody has ruled; pinned means we ruled it wrong and are watching.
```

**They are not compatible.** A implies an owner and a decision to defer; B makes `parked`
precisely **the absence of a ruling**. ⚠ **If B wins, the three circulating framings sort into
THREE terms, not two** — `pop.sh`'s `parkdiff` designations, the banner's `1 parked-WIP`, and the
seals' `3 owned reds` — and **whatever is pinned is what a registration schema inherits**, which
is why the pin comes before the schema rather than after it.

## 9. RESERVED, NOT FILLED

`byteIdentical` vs `byteIdentant` waits on **vigram O4 at the V1 gate** — Tony's ruling, not
pre-empted here. The loser's entry reads *"former spelling of —"* per the brief.

## 10. WHAT THIS IS NOT

**Not a runner. Not vigram infrastructure. Not a documentation project.**
It is **a lookup table with a print verb.**

The censusable property — *"which doctrine terms lack entries"* as a grep-class question — is
**a happy consequence to note, not a feature to build toward.**

## 11. THE SYMMETRY, NOW THAT IT HAS LANDED

The first campaign artifact written **in kant for the humans rather than for the parser** is
**the dictionary the humans needed to talk about the campaign.**

---

## OPEN / OWED

- ⚠ **`parked` — Tony's ruling**, §8. Nothing else in the decoder waits on it; the registration
  schema does.
- ⚠ **H6's wording — Tony's call**, §6. The dictated sentence is narrower than `CLAUDE.md`'s
  headline, and the gap is the parked case, which §8 is about to re-cut.
- **`jiquery`'s section-0 content check is vacuous** (§7). Measured on the identical shape.
  Belongs to whoever owns jigcorpus; the fix is to compare against the attribute name, and even
  that only detects the dataless form, not an absent attribute.
- **The `decode: A B C` literal spelling** is served as `decodE(A B C);`. If Tony wants the bare
  colon form as real syntax it is a grammar question, not a decoder one.
- **Three candidate incant traps found while building** and recorded in the file headers — a
  group indexed by `argument.text` exits **139 with zero output** where `argument.taG` works;
  `if !x.attribute;` exits **139 with zero output**; `print "":;` prints the string `quoteBody`.
  All three are **symptoms, reproduced and bisected; none is diagnosed.**
