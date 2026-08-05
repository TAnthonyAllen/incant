# GRAMMAR MINION — CHARTER
**REFERENCE until fired. Fires sequentially on Clod's seat, queued behind current main-line traffic (item 2, K5/K6). Nothing here acts before Tony fires it.**
*Drafted by Clay at Tony's direction, 2026-08-05. All rulings herein are Tony's, made this date unless marked otherwise.*

## MISSION, in weight order
1. **PRIMARY — GENERATION.** genParse produces a `parseMethod` for every rule it can. Generation is the hard part and the mission; the summer's five rungs of design work were spent making genParse able to *say* methods at all. Deliverable per rule: a generated method, installed, recorded as a corpus row.
2. **SECONDARY — VERIFICATION, decoupled.** Per-rule fire against the interpretive oracle. Runnable by the minion at increment end or as a separate pass later (Tony's call at firing time). A rule may stand *generated-unverified* without blocking the next rule's generation.
3. **TERTIARY — REFUSAL TRIAGE.** Rules genParse won't plan, sorted three ways: **grammar defect** (rule wrong as written — proposed edit to Tony's gauntlet) · **planner gap** (rule fine, generator can't say it yet — worklist for the main line) · **deliberate** (refusal is intended — recorded with rationale). The planner-gap column is the map of what makes generation more capable.

**The success metric is a fraction:** rules-with-generated-method / rules-in-population. It does not currently exist. Making it exist and then moving it is the campaign.

## OPERATING RHYTHM — one rule at a time (ruled)
The ladder discipline in grammar clothes: **prove genParse on ONE rule, extend rule by rule.** Each increment: pick the next rule → classify → generate → install → (verify) → corpus row → POP the fleet → next. Every increment Clod-sized; every failure one rule's blast radius; coverage monotone. Scaf/Scaf2 were rule one in effect; this charter is rungs two through N. **No big-bang conversion, ever.**

## ARCHITECTURE FACTS THE CHARTER STANDS ON (Tony, this session)
- **Install is ADDITIVE.** The generated method lands in the rule's own `rStuff.parseMethod` — its own slot, beside `field.method`, overwriting nothing. `parse()` forks: generated when present, interpretive fallback otherwise. Remove the pointer and the interpretive path stands untouched.
- **The testing IS the POP.** Run the installed `parseMethod`; the interpretive rule is the oracle, same grammar, same input, same process. Match = works, proven by fire. Mismatch = bug hunt, with both engines' behavior on the same input as the captured specimen. This is the fork doing the job it was built for — no sandbox needed, no text-diff theater.
- **Additive is not inert.** While installed, the fork routes that rule's parses through the generated method. Verification runs are dedicated runs; capture the interpretive baseline BEFORE install, diff after — the standing capture-first rhythm, which also answers a hunt's first question (which engine moved) before it is asked.

## BOUNDARY (ruled)
- The minion owns: the rule population, classification, generation, install-through-the-front-door, verification fires, refusal triage.
- The minion does NOT touch: `getRStuff` / materialisation machinery / the fork itself / define-time paths / anything that RENOVATES the door rather than walking through it. **rStuff internals are bear country; install-and-test uses the front door only.**
- Generator emission-correctness machinery (the genLadder) stays with the main line. The minion USES generation; it does not maintain the generator.
- Recon first; **design deferred** — what the grammar SHOULD be is a separate design-minion firing, judged at Tony's gauntlet, inheriting this minion's triaged population instead of a blank grammar.

## PHASES
**TASK ZERO — establish the population.** The census fixture asserts 30 rules; Tony states the grammar carries MORE. Walk the defined rules, count, diff against 30. The gap is the corpus's first claim (with provenance) and the census fixture's coverage becomes a known fraction rather than an assumed whole — the evaporated-checks lesson, applied to grammar before it bites.

**PHASE A — classify the full population.** The rung-3 seam split means classification runs WITHOUT emission (plan-as-GroupItem). Every rule gets a row: plans / refuses; plan shape if plans; refusal point with file:line if refuses. No emission, no installs, no dispatch movement — pure measurement. Output: the partition table, the corpus's spine.

**PHASE B — generate and install, rule by rule, per the rhythm above.** Emit for the next plannable rule, install to its `rStuff.parseMethod`, corpus row, fleet POP. Verification per the decoupling ruling. A red verification is a work item with a specimen, not a stall.

**Pause-and-ask gates:** end of task zero (population number to Tony) · end of Phase A (partition table to Tony) · any refusal whose triage is ambiguous · any verification red whose hunt wants a ruling · before touching any rule whose interpretive behavior is itself suspect.

## CORPUS
- Loaded via `incant jigcorpus;` per the standing minion architecture; claims carry provenance / confidence / asOf per B0; operations per `docs/minionfire.md` (query / absorb / bake / challenge).
- **Inherits, through adversarial re-absorption:** the 30-rule census fixture and `census.target` (including the known 9-line audit movement and the `MemberS` tangle) · genParseShape / genParseSeam briefs · Invariant R′ · the §2.4 tree-fixture pinned divergence. ⚠ Several inherited claims predate the rStuff-at-define refactor; **their asOf is presumed expired until re-measured.** Absorption is adversarial by doctrine — each inherited claim is challenged against HEAD before it becomes corpus.
- The `MemberS` regression-vs-grammar-change separation (open since 08-03) is Phase A's first natural triage specimen — it is the taxonomy's founding case, generalized to the population.

## OPENING PROBE (Clod, read-and-report, before firing)
- **P-G1:** install persistence — is a `parseMethod` install per-run-transient (rStuff rematerialises each incantation, next run starts clean) or does anything persist wanting explicit removal? Structural, grep-shaped. Decides whether Phase B needs teardown discipline or gets isolation free. (Expected: transient, per the additive-install model; measure anyway.)
- **P-G2:** the true rule count, cheap preview of task zero — if it is a one-liner, report the number with the walk that produced it.

## NOT IN SCOPE
Generator internals beyond using them · rStuff/materialisation edits · the fork · grammar redesign (the deferred design minion's) · the genLadder · anything mid-flight on the main line at firing time.

## SEQUENCING (ruled)
Sequential on Clod's seat, queued behind current traffic, **assess as we go** — the standing rhythm, unchanged. A minion brief does not go over the wall while a main-line brief is mid-flight; it queues behind, K5/K6-style. The 08-03 stagger warning concerned simultaneous minions; sequential-with-assessment dissolves it.
