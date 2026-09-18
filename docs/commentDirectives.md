# commentDirectives — long comments leave the `.twk` and live in a directives store

**A docket card, 2026-09-18. Tony's proposal, Clay's key, Clod's sizing. NOTHING IS BUILT.**
Where a claim here was measured, it says so and names the run; everything else is design.

---

## 1. What Tony asked for

> *"And code keeps accumulating long comments. That has to stop. Comments are basically an
> insertion into code. That is something a Tok directive can do. Can we have a
> commentDirectives file that Clod can add comments to as directives that insert the comments
> idempotently. Clod can then choose to apply the directives selectively when working as a
> prior step before running. The comments will then only go into the .mm file, which Clod has
> no trouble dealing with. The Tok file that I deal with then stays pristine. That is the
> goal."* — offline status, 2026-09-18

**The goal is the last sentence.** Everything below is in service of *the file Tony reads stays
pristine*, and any design choice that costs him a clean `.twk` is the wrong one however elegant.

---

## 2. Clay's key, and it is the whole design

> *"The `// slug` markers can serve double duty: as a link to DesignDocs and as a directive
> target to match against."*

**A slug is the only thing in a `.twk` with all three properties an anchor needs:**

| property | why it matters | why the slug has it |
|---|---|---|
| **unique** | two matches is a coin flip about which one gets the comment | it has to resolve against DesignDocs, so uniqueness is already enforced by the register |
| **stable under edits** | an anchor made of code text orphans the moment the code changes | a comment directive never names code at all |
| **stable under the alpha sort** | `GroupItem.twk`'s 2026-09-15 sweep moved 69 of 103 methods | the slug travels with its method |

**Two consequences, and Clod builds to them.**

1. **The directive is `insertAt` after the slug line, never `fromThis`/`toThis` around code.**
   A comment directive names no code text whatever. That is what makes it inert when the code
   under it changes — the anchor is not part of the thing being edited.
2. **A method with no slug cannot take a comment, and that is the feature.** It forces the
   DesignDocs entry to exist before the prose does, which is the argument-versus-description
   split enforced mechanically instead of by review. **Clod's first move on any method is mint
   the slug, then write the directive.**

⚠ **THE EDGE CLAY NAMED: MATCH THE SLUG TOKEN ALONE, NOT THE WHOLE LINE.** The sentence half of
`// slug sentence?` is optional and Clod edits it. Matching the whole line means a sentence
tweak orphans every comment under it.

---

## 3. Which format the store is in — and the answer is NOT a Tok directives file

**Tony's instinct was a Tok directives file, and the ruling is Tony's. The measurement says the
kant format does this job and the Tok format does not, for three reasons that are about
addressing rather than taste.**

| | **Tok directives** (`groupDirectives`) | **kant directives** (`incant/directives`) |
|---|---|---|
| entry shape | `<function> <anchor> [before] active` · body · `#;` | `name source fromThis="…" toThis="…" where=before;` |
| addresses by | **function name** + an anchor phrase **inside that function** | **file** + match text + before/after |
| applied by | `tok File.twk groupDirectives` — bare `tok` applies **none** | a kant run: `getFile`, the three verbs, `closeFile` |
| writes to | the generated `.mm` | **whatever file `source` names** — including a `.mm` |
| arity | ⚠ at most one per **matching statement point**; two armed entries on the same anchor contest one slot and the first latches (bear-trap #30 as amended 2026-09-04) | one per call, and a `fromThis` occurring N times fires N times, taking the next occurrence each fire |

**Three reasons the Tok road is the wrong one here.**

1. **It cannot address a slug without also knowing the function.** A Tok entry's first token is
   the target function. A slug does not carry one — deliberately, since the 2026-09-16 ruling
   that the dotted path is never inline, precisely because a path names a parent nobody checks.
   Reintroducing the function name at the directive end reintroduces exactly that failure.
2. **The arity rule bites.** One directive per matching statement point is fine for one comment
   per site and is a wall the day a method wants two.
3. **It is unnecessary.** `insertAt`'s `source` is any file the run can open, and a generated
   `.mm` is a file. The kant road reaches Tony's goal with machinery that already exists and is
   already certified (`genLadder/batches/slugDirectives`, 2026-09-16, on production source).

⚠ **AND THE CONVERSION TONY ANTICIPATES IS A DIFFERENT CONVERSION.** He wrote: *"once we are at
a stage where kant directives can replace Tok directives, we will have a conversion to do."*
**That conversion is real and it is about `groupDirectives`** — the instrumentation store, which
injects *executable* code at statement points and genuinely needs the Tok road until checkSKIP
lands. **The comment store does not join that queue.** It can be kant from its first line,
because a comment is text and its target is a text file.

### The one-paragraph sizing Tony asked for: is a kant → Tok emitter a small script?

**No, and the reason is a parse rather than a volume.** A kant entry carries *(file, match text,
before/after, payload)*. A Tok entry needs *(function name, anchor phrase within that function,
position, payload)*. The payload and the position map across for free; **the function name does
not exist in the kant entry and cannot be derived by substitution** — you have to read the
source and work out which function encloses the matched line, which is a parse of `.twk` and
not a text transform. On top of that the anchor must be re-expressed as a phrase Tok's own
matcher will find at a *statement point*, and the arity rule means the emitter has to detect
collisions between two entries landing on one point and refuse, since a silent loser is the
documented failure mode. **So: a day's work with a real correctness question in it, not a small
script.** The cheap direction is the other one — Tok → kant, where the function name is
discarded — and that is the direction the eventual `groupDirectives` migration runs in anyway.

---

## 4. Idempotency — measured, and it does NOT come from the directive

⚠⚠ **`insertAt` HAS NO ALREADY-PRESENT CHECK. READ, NOT ASSUMED** (`incant/directives:26-45`,
2026-09-18). It finds the line, repositions the mark, and appends. Run it twice on one buffer
and the comment lands twice. **The `\n` end-anchor that makes `replaceAt` self-limiting does not
transfer**: `replaceAt` consumes its own `fromThis`, so a second run finds nothing, while
`insertAt` leaves the anchor exactly where it was.

**So the store is idempotent for a structural reason instead, and it is the better reason: the
target is a GENERATED file.**

```
tok File.twk          ->  bare .mm, no comments
apply commentDirectives  ->  commented .mm, for reading and debugging
tok File.twk          ->  bare .mm again, the comments discarded
apply commentDirectives  ->  BYTE-IDENTICAL to the first commented .mm
```

**The retok is the reset.** That is Clay's certificate row — *apply, retok, apply again; second
`.mm` byte-identical to the first* — and it passes **by construction** rather than by care,
which is this project's stated preference: prefer a structure that makes the failure
unconstructable over a discipline that avoids it.

⚠ **THE FAILURE TO NAME LOUDLY, because it is the one a tired operator will hit: APPLY TWICE
WITHOUT A RETOK BETWEEN.** Every comment doubles. The harness must therefore **retok first,
unconditionally**, and never apply to a `.mm` it did not just generate.

⚠ **A SECOND CONSTRAINT, AND IT IS SHARP: `fromThis` MUST NOT CONTAIN `//` OR A QUOTE.**
`checkSkip` swallows anything comment-shaped even inside a quoted value — that is G03's blocker,
and `genLadder/batches/slugDirectives` already lives under it. **Which is exactly why the anchor
is the SLUG TOKEN and not the `// slug` line**: Clay's edge and this constraint want the same
thing for two independent reasons, and that agreement is worth more than either reason alone.
⚠ **It also means the payload cannot be written as `// text` today.** Until checkSKIP lands, a
comment directive's `toThis` has to reach the file without a literal `//` in kant source — an
open spelling question (a `/* */` payload avoids `//` and is the obvious first try, unmeasured)
and the single thing most likely to decide whether this store is buildable now or after
checkSKIP.

---

## 5. What stays in the `.twk`

**Unchanged, and this is not negotiable by the store:**

- the **`// slug sentence?`** line itself — it is the anchor, and it is the claim a reader at
  the edit site must not miss (the 2026-09-15 too-short test still governs the sentence);
- **DesignDocs pointers**, which is to say the slugs, since the path is never inline;
- **block comments that describe** — the argument-versus-description split is unchanged. The
  store is for what ARGUES, which is the same population the DesignDocs convention already
  claims.

⚠ **SO THE STORE OVERLAPS DesignDocs AND DOES NOT REPLACE IT, and the difference is the
audience.** DesignDocs is for the reader who stops to ask *why*; the store is for the reader —
Clod, at the `.mm` — who wants the argument **at the edit site while working**. If a future pass
finds the store carrying prose nobody reads in the `.mm` and DesignDocs carrying the same prose,
that is a finding about duplication, and the DesignDocs copy is the one that survives.

---

## 6. The certificate this store owes when it is built

Not a proposal — this is the list, and rows 1 to 3 are Clay's addendum verbatim.

1. **apply · retok · apply again — the second `.mm` byte-identical to the first** (md5 both).
2. **second-run-inert in the ruled sense**: run the batch twice against ONE buffer and the
   doubling is visible, so the harness asserts the retok happened rather than asserting the
   batch is self-limiting. ⚠ **This row is a DEPARTURE from the batch certificate in
   `incant/directives` and it says so out loud**, because that certificate assumes `replaceAt`
   semantics and this store does not have them.
3. **every slug in the store resolves** to a `// slug` line present in the target `.twk`, and
   every target method has a DesignDocs entry. A store entry for a slug that does not exist is
   a silent no-op, which is the one failure this design can still produce.
4. **`codeOnly.py` on the commented `.mm` is byte-identical to the bare one.** This is the row
   that proves the store inserted comments and nothing else, and the instrument already exists.
5. **the committed `.mm` is BARE** — `git status` clean after the retok, per the 2026-09-17
   standing rule that bare is the default state.
6. **the fleet unmoved row for row**, because a commented `.mm` must never be measured.

---

## 7. Where it sits, and what is owed before it starts

**Owed first, and it may gate the whole thing:** the `toThis` payload spelling. A comment
directive whose payload cannot contain `//` is a comment directive that cannot write a line
comment. **Measure that before anything is built** — one batch, one `/* */` payload, one scratch
copy of a `.mm`. If the block form works the store is buildable today; if it does not, this card
parks behind checkSKIP and says so.

**Then, in order:** the store file and its layout · the apply harness (retok first, always) ·
rows 1 to 6 above · one real method converted end to end as the acceptance case.

**Tony rules on §3 — the format question — after reading this.** Everything else follows from
that answer.
