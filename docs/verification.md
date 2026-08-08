# VI — Verification Practice Inventory

**Status:** stage-1 durable · asOf 2026-08-07 · candidate terms, not prose · the language is NOT named (VI-0 bet stands)
**Purpose:** raw material for Tony's grammar-making. Each entry is written the way a kant rule term would be written, because the test is mechanical shoehorning into rule shape. Footnotes the shoehorn requires are findings, not failures (VI-7).
**Ruled shape, restated once (VI-5, do not re-derive):** a check is a rule — pretensions only, no target term; input arrives at fire time (`Scaf('x')`). The harness owns command/buffer/pairing (produce, divert, fire, collect); that layer already lives in harnessCensus, and fixtures register in two lines. The claim is action residue — minted on the label when the check-rule matches, asOf stamped; matching stays pure recognition. GM-6 isolation (parse divergence vs action divergence distinguishable) applies to this language too.

Entry shape used throughout: **candidate term** · fires on (arguments at invocation) · matches when (pretension) · absence/silence semantics · strength or ordering notes.

---

## 1. Oracle kinds (VI-2)

Written target-free. These are every comparison the fleet is known to use from this seat.

**byteIdentical** · fires on (producedCapture, baselineName) · matches when the capture equals the named baseline byte-for-byte · a missing baseline is a loud error, never a pass · strongest oracle in the fleet; carries the same-run-vs-stale-target obligation (§4.5) — the term must state which generation of the baseline it reads.

**assertsLine** (value-assertion-by-name) · fires on (capture, assertionName, expectedValue) · matches when the named line appears bearing the expected value · the named line's absence is the failure signal, and its presence with the value is the only green — silence never means two things · medium strength; its virtue is that failure localizes to a name.

**fixpoint** · fires on (write₁, write₂) · matches when write₁ == write₂ AND both are non-empty · REQUIRES a must-fail control against vacuity: a deliberately perturbed third write must break the match, or the check is not believed · guards persistence and round-trip claims; also the ruled china test for the (now-retired) boilerplate spec — "finished when render-plus-print reproduces a working file."

**degradeZero** · fires on (degradeCount) · matches when count == 0 after the exercised path · numeric, machine-checkable; the bake-claim oracle (compile once, fire twice, degrade 0).

**exitStatus** · fires on (status) · matches when status == 0 · weakest oracle; NEVER sufficient alone; grammatically conjunct-only (§4.3).

**roundTripIdentical** (structural identity) · fires on (structure, reparse(spell(structure))) · matches when tree shape is equal after the round trip · distinct from byteIdentical: tolerates exactly the spelling variance the grammar declares insignificant, and nothing else.

**SURVEY ROW — OPEN.** VI-2 directs a sweep of pop.sh, recordPop.sh, ladder.sh, printPop, containerPop for kinds this list misses. The scripts were not in reach this session; the coverage claim above grades ASSUMED. Known fleet footprint for the sweep to reconcile against: pop.sh 33 green / 1 parked, ladder 150, recordPop 48, printPop/containerPop/tree exit 0 (asOf 2026-08-06). Candidate suspects for missed kinds, from seat memory only: the WOKE alarm on parked pins (an oracle over the *harness's own state*, not over program output — if real, it is a new kind: a meta-check whose subject is the check registry), and any count-assertion in ladder.sh that is neither byte-identity nor named-line (e.g. "21/27" style ratios — possibly assertsLine, possibly a distinct **countRatio** kind). First shoehorn pass should burn this row down.

---

## 2. Control shapes (VI-3)

**negativeControl** · a companion rule asserting a named path is NOT reached · exists so the paired positive check cannot go green on pre-existing behavior · exemplar NC-1 (assert jitJ1 never reaches jitFieldMethod, so the JiT section can't pass on old behavior) · grammar note: a positive check without its negative twin should remain sayable but conspicuous — absence of the twin is a visible property, not an error.

**inertWhenUnarmed** (armed-vs-unarmed byte identity) · fires on (unarmedRunBytes, preInstrumentationBaseline) · matches when instrumentation gated OFF leaves output byte-identical to the world before the instrument existed · this is what licenses leaving a probe (parseTrace) in production; it is byteIdentical with a specific *provenance pretension* on its baseline.

**twoArmToggle** · single site, one variable, ARM A vs ARM B (Parens exemplar) · matches when the two arms differ only in the predicted way · the isolation guarantee is the entire point; a toggle spanning two sites is a different (and weaker) thing and should not share the term.

**discriminatingControlFirst** (H7) · not a comparison — an ORDERING pretension between checks: the control that could distinguish the hypothesis must fire before a green localizer is believed · paid three times in one day, 2026-08-06 · shoehorn note: this is a check whose belief-license depends on another check having fired; if rules can state pretensions over other rules' fire-state, it's a term; if not, it's harness sequencing. Flagged as the second-most-likely holdout after structural-vs-causal.

**cleanOracle** · a provenance pretension on the oracle's own input: the term states where its observed value came from · exemplar of dirt: post-jit interpreted calls are dirty oracles for returned values (bear-trap #25, isCoded routing) · the language should make an unsourced observation unsayable or loud.

---

## 3. Claim lifecycle (VI-4)

Four stages, each a candidate term; promotion between stages is the practice's action layer.

**prediction** · argued site, ungraded · may be pre-registered before its measurement exists (Parens was queued as a pre-registered prediction of the same red as Braced — and paid off).

**measurement** · file:line or run output · the only stage that touches the world · everything downstream cites it.

**claim** · B0 form: provenance, confidence grade (RUN / MEASURED / READ / REASONED / ASSUMED), asOf stamp · per the ruled shape, minted on the label when a check-rule matches — a claim IS a check in past tense.

**doctrine** · a claim promoted after surviving reuse: bear-trap number or corpus entry · doctrine is what §4 then compiles back into grammar.

**Grading rider — structural-vs-causal.** Structural claims from this seat held; causal/tree claims went five-for-five wrong on 07-27 and kept failing after. Sealed wager, restated for the record: this grade is the shoehorn's likely holdout, because it grades claim *provenance*, not match — it may belong to the corpus as a constraint on claims, not to the language as a rule term. If the shoehorn confirms that, it's a finding.

---

## 4. Traps as grammar constraints (VI-6)

Each restated as "the language makes this unsayable or loud."

**4.1 No oracle, no parse.** A check with no oracle term does not parse. The oracle is mandatory, never defaulted.

**4.2 tagEcho** (bear-trap #26 family; four payments as of 2026-08-06: the "JiT" non-empty trap · the pmOut localizer · genParse(gsRule) returning silent nothing · showGen's field-name attempt). An empty field returns its own tag, so every non-empty test passes vacuously. Constraint: any oracle reading a field must distinguish value from echo — equality-with-own-tag is loud by construction, and a bare non-empty test on a field is unsayable.

**4.3 exit-0-with-lost-stdout.** exitStatus may never appear as a check's sole oracle. Conjunct-only, enforced by grammar, not by memory.

**4.4 Zero-byte capture exiting clean** (the cerr/rdbuf lesson). A capture carries a non-empty pretension by default; a check that genuinely asserts emptiness must NAME emptiness as its assertion (which makes it assertsLine-shaped, not silence-shaped).

**4.5 Same-run emission vs stale target.** Every byteIdentical check states which oracle generation it reads. "The file that happens to be there" is unsayable.

**4.6 Silence meaning two things — global.** No term anywhere in the language may have an absence that means pass in one ambient state and fail in another. Live in-language payment, already made in the wild: the GX action-firing helper deliberately returns nothing, because "return the label, null means failure" is wrong — RuleStuff.twk:181 sets label = 0 on success for a noLabel rule, so null would carry two meanings. The practice enforced this constraint on kant itself before the checking language existed. That is the strongest available evidence that these constraints are grammar-shaped and not just habits.

---

## Fence (VI-7, restated)

Inventory only. No runner, no compiler, no syntax proposal, no name, no Clod time. The substrate observation stands ready but unbuilt: a check is a GroupItem; a ladder is a registry of checks; the shell scripts are an emit target the way parse methods are; B0 and this language are one thing at two tenses. Tony does the grammar-making. Delivery complete on handback.

---

# Appendix — the handback (Tony, via Clay, 2026-08-08)

**Status:** stage-1 addendum · asOf 2026-08-08 · grades READ/REASONED from the record, NOT measured against the scripts · appended on Tony's H8 verdict (accept-with-addendum); the VI sections above are Clod's and unedited.
**Why this exists:** grammar-making needs what VI's target-free format deliberately stripped — for each term, WHAT method implements it, WHO invokes it, WHEN it fires. This appendix states the flow and strata as understood from the record, and commissions the binding table that replaces its grades with file:line.

## A1. The three strata (where methods live)

**Stratum A — in-fixture, kant.** The fixture emits the evidence: sentinel prints (H2), tick counters, degrade prints, `recordParse()`/`showParse` record doors. These make output assertable; they run inside produce.

**Stratum B — harness, shell.** The verbs around the fixture: run binary against fixture · capture (redirect + `script -q /dev/null`, because segfaults eat buffered stdout — the wrapper IS part of divert) · filter (sed/grep pipelines, e.g. the census POP's) · compare (diff-vs-target = byteIdentical, grep-named-line = assertsLine, `$?` = exitStatus) · aggregate (pop.sh's line-per-check + exit roll-up = collect).

**Stratum C — baseline management.** Targets in `genLadder/`, capture-before-change, §4.5's which-generation obligation. ⚠ NO METHOD OWNS THIS STRATUM. It is pure discipline, which is why it keeps costing.

## A2. The firing order, as actually run (one check's lifetime)

1. **Build gate** — binary freshness vs session (H1). Manual, per session.
2. **Produce** — `<binary> incant/<fixture>`, wall-clock capped (H5), background-and-kill (no `timeout` on this shell).
3. **Divert** — redirect + script wrapper + filter. §4.4's zero-byte pretension is checked here or never.
4. **Recognize** — against Stratum C. Ordering rules INSIDE this step: jitted-half-first, oracle-last (bear-trap #25); H7's discriminating-control-first is an ordering pretension BETWEEN recognitions, enforced today by nobody but the script's author.
5. **Collect** — pop.sh aggregates.
6. **Mint** — ⚠ MANUAL. The harness stops at collect; claims become B0 rows because Clod types them. "Claim minted on the label as action residue" describes a step that exists as discipline, not as a method. This is the largest gap between the flow as ruled (VI-5) and the flow as run, and it is finding #1 of this appendix.

## A3. What this gives the grammar (Tony's two passes)

**Pass 1 — grammar over existing methods.** Strata A/B bind cleanly: byteIdentical = diff-vs-named-target · assertsLine = grep-name-with-value · degradeZero = Stratum A print + Stratum B grep · exitStatus = `$?` (conjunct-only per §4.3).

**Pass 2 — the unbound list IS the agenda.** Terms with no implementing method: the mint step (A2.6) · H7's ordering pretension · fixpoint's mandatory must-fail control · §4.5's baseline-generation statement · all of Stratum C. Not implementation debts — the places the grammar earns its existence: a grammar is how discipline becomes mechanical ("no oracle, no parse" turns a rule someone must remember into a sentence that cannot be said wrong).

**Standing note (genParse lesson, restated for this campaign):** the plan layer was the intellectual mass; the emitter was 200 lines of spelling. The grammar is the spec of the practice. Whether an emitter ever consumes it is a second-order problem, downstream and severable.

## A4. COMMISSION — the VI binding table (Clod, one session)

For EACH candidate term in the VI sections above, one row:

| slot | content |
|---|---|
| term | VI's name |
| binding | implementing method / script fragment, **file:line** |
| invoker | fixture · harness script · human |
| position | step 1–6 of A2 |
| consumes | its input |
| consumed-by | who reads its output (⚠ a check nothing reads is a ritual — mark it) |

Rules of engagement:
- Terms with no binding are marked **UNBOUND**, never omitted. The UNBOUND list is pass-2's agenda and the point of the exercise.
- Fold in VI-2's SURVEY ROW: sweep pop.sh · recordPop.sh · ladder.sh · printPop · containerPop for oracle kinds the list misses (WOKE alarm as meta-check candidate; countRatio as possible distinct kind). This burns down VI's one ASSUMED grade in the same walk.
- Mark each binding **structural** (wired into a script, impossible to forget) or **disciplinary** (someone must remember). The disciplinary column is where this project has historically paid.
- **Read-only against the scripts. No runner, no compiler, no syntax. VI-7's fence stands unamended.** This table is ingredients for Tony's grammar-making, in the order they fire.

Delivery: rows appended below this appendix or as `docs/viBinding.md` with a pointer here — Clod's call, one writer per fact either way.

---

*Delivery pointer (Clod, 2026-08-08), added below the appendix rather than inside it so the
appendix body stays verbatim: A4's binding table lands as **`docs/viBinding.md`**. It is
**STARTED, NOT DELIVERED** — one row, **A2.6**, answered early because Tony flagged it by name.
The walk confirms Clay's READ-grade claim (minting is manual: no harness script writes any repo
file) and sharpens it — evidence has an automatic door via the record gates, verdicts have none.
Remaining terms are **UNWALKED**, which is not A4's **UNBOUND**.*
