# Minion-day pilot — protocol verdict

*Prose by instruction. Written after the report, from doing it rather than from designing it.
Subject: the protocol, not the jit arc.*

## The headline

**The mechanical pass paid for itself inside one task, and it paid by catching me.**
`JitLocalsAsFrames` was one command away from shipping as *"the deletion is done"* — a filtered
grep returned zero `saveLocalFields` hits outside comments. The unfiltered command found **11 in
`GroupActions.rtn`**. That grade would have been confident, coherent, and wrong, and nothing else in
the pipeline would have caught it, because a wrong *grade* reads exactly like a right one.

That is the whole argument for claims-must-carry-commands, and it is stronger than the one I gave
before running the pilot: **the command does not just make review cheap, it makes the AUTHOR's error
visible to the author.** I found this myself, before Clay ever saw it, because the format made me
write the command down next to the claim.

## Which fields earned their cost

**`Vintage` + sha — the load-bearing one.** Six of nineteen grades are *superseded*, and every one
of those is meaningless without a stated "superseded as of what". A vintage without a sha is a date,
and a date cannot be diffed. It earned its cost the moment the first supersession was written.

**`Touched` — and specifically the sub-entry I did not expect to matter.** `TouchedNotPulled` names
the two cross-referenced docs I deliberately *did not* read and why. That single line converts an
omission into a decision, and it is the line I would most want as a reviewer. **Recommend the
charter make not-pulled mandatory, not optional** — a `Touched` listing only what was read is a
half-answer that looks whole.

**`Unverified` — earned it, and grew under the writing.** It started as three rows and ended as six,
because the act of grading kept surfacing things adjacent to the grade. That is the section doing
its job: unknowns are cheap when enumerated and expensive when discovered.

**`Controls` — earned it, but not in the way the protocol expected.** See below.

**`Status` — near-free and worth keeping.** One word, and it is what makes the pile triageable.

## Where the none-possible clause chafed

**Four of six control rows are `none possible`, and for a while that looked like the section
failing.** On a read-only doc-grading task most claims are *rulings*, and a ruling has no red run —
it can only be superseded by another ruling. I nearly wrote "not applicable to this charter."

**What saved it was being forced to say *why*.** Writing the reason out produced a distinction I
would not otherwise have articulated: **the control for a ruling-grade is the SEARCH for a
superseding ruling**, and that search is a real, describable, auditable act that lives in `Vintage`.
Once that was written, `ControlAbsentWhereItMatters` fell out of it — the admission that my search
covered *one* vintage and would miss a superseding ruling filed in an older seal or a thread. **That
is the largest weakness in the report and the none-possible clause is what surfaced it.**

**Recommendation: keep the clause, and add one sentence to the charter** — *on a read-only task the
expected shape is mostly none-possible, and that is not a deficiency; the required work is the
categorical reason, not the run.* Without that sentence a minion will either pad the section or
apologise for it.

## What the charter should have said

1. **⚠ SHIP A SKELETON FILE, NOT A DESCRIPTION OF ONE.** I lost a cycle to a parse failure:
   **a blank line inside a `define` block ends the block.** The report truncated after its first
   entry, at exit 0, with `RunRulE: expected a method not Vintage` on stderr — the documented
   silent-truncation signature. A charter that says "DesignDocs format" hands the minion a format it
   must re-derive; a charter that ships `minionWork/_skeleton` that already runs hands it a format it
   can fill in. **This is the single highest-value change to the protocol.**
   *(That blank-line fact is not in the trap table. I did not file it — writes were fenced to
   `minionWork/` and the IPC file — so it is flagged here for someone with the write.)*

2. **ONE GRADE VOCABULARY.** The charter gave me *current / superseded-by-named-ruling /
   unverifiable-from-docs-alone*. The signed protocol gives *RUN / MEASURED / READ / REASONED /
   ASSUMED*. I used the charter's, because a charter is closer to the work — but the report now
   speaks a different language from the corpus it will sit beside, and the challenge queue has to be
   translated by hand. **Pick one, and if the task needs a second axis make it a second field, not a
   second vocabulary.**

3. **"MANY-TO-MANY" WAS NOT ACHIEVABLE READ-ONLY, and the charter did not notice.** I can propose
   entry names; I cannot say which *existing* DesignDocs entries these attach to, because attachment
   is an installation decision and installation was out of scope. The mapping is therefore
   one-directional by construction. Recorded in `UnverifiedManyToMany`. **A charter should check
   that its operations are reachable from its boundaries.**

4. **THE DISCLOSED ROW NEEDED A SCOPE INSTRUCTION AND DID NOT GET ONE.** I found the planted
   supersession easily — and then nearly over-claimed it. R-2 and Ruling 1 were ruled on the *parse*
   replacement, not on the JIT crossover; they were *derived from* the very section they supersede.
   The defensible grade is narrower than the obvious one, and `JitCrossoverFallbackScope` says so.
   **A calibration row should come with "state the scope of the supersession", because the failure
   mode of a planted answer is not missing it — it is finding it and taking too much.**

## What the skeleton is missing

**A `Corrections` field.** I made one error mid-pass and caught it, and there was no structural home
for that, so it is buried inside a `Why`. A report that lists its own near-misses is worth more than
one that looks clean, and burying them means the next reader cannot tell a report that made no
errors from one that hid them. One field, same shape as `Unverified`: what I got wrong, what caught
it, what it would have cost.

**Nothing else.** `Claims / Unverified / Controls / Vintage+sha / Touched / Status` plus
`Corrections` is a complete skeleton for a read-only task. I would not add a confidence field on top
of the grade field — see item 2.

## Sizing, revisited from having done one

**One charter was the right size and I would not have split it.** The two documents cross-reference
each other and share a vintage; grading them separately would have meant reading the same seal twice
and reconciling two reports. **But it was near the ceiling**: 19 claims, and the last four were
noticeably thinner than the first four — I was pattern-matching by then rather than reading. **The
diminishing return starts around 15 claims**, which is a better sizing unit than "one document" or
"one arc".

## The queue for challenge

The claims resting on **reasoning rather than a command** — my `none possible` set, plus the two
whose grade depends on the scope of a ruling rather than on a measurement:

| claim | why it is in the queue |
|---|---|
| `JitCrossoverFallback` | the supersession's SCOPE is a judgement, and I narrowed it myself |
| `JitReplacesInterpreter` | graded current on the absence of a superseding ruling in one vintage |
| `AndOrRuling` | ditto, and its implementation was not fired |
| `AndOrPlacementDoctrine` | ditto |
| `AndOrTierTwoCaveat` | graded current on its own self-description |
| `JitStatementCensus` | the number is measured; the emit-versus-degrade SPLIT is not, and I said so |

Everything else in the report carries a command and should be reviewed by running it, not by reading
it.
