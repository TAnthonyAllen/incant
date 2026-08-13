# The generator respell onto `AND`/`OR` — the charter, and the ruling in front of it

**Status:** ⚠⚠ **STOPPED AT §3.0, 2026-08-11 — NOT BUILT, AND WAITING ON A RESTATEMENT OF §1 BY
TONY.** The rung fired on SEQ 48 item 4, took §3.0's measurement first as instructed, and **§3.0
answered NO**: the goto scaffolding is not the cause of the Braced red, the cause it *was* has been
repaired since 2026-08-06, and **no emitted method has ever contained a goto**, so §3.5's exhibit is
not producible. **Read §6's Braced block before anything else in this file.** The §1 ruling is
**not withdrawn** — what moved is the description of what it buys.

**Prior status, kept:** AUTHORIZED AND FIRING — NOT BUILT. Prerequisite satisfied 2026-08-11 (the
AND/OR rung sealed clean: ladder **184 / exit 0**, byte-agreement certified, rider filed).
**§1's ruling is GRANTED** — Tony, 2026-08-11. Deferred to the next session by Clod's
recommendation and Tony's agreement; see §0.

⚠ **THIS FILE EXISTS BECAUSE THE CHARTER WAS DICTATED IN CHAT.** Same reason `docs/andOrRung.md`
exists, and its §0 states the rule this file inherits: **a ruling whose only home is a thread is
an unmeasured citation waiting to be made.** Transcribed against the dictating text; **if the
thread and this file disagree, the thread wins and this file is corrected.**

---

## 0. WHY IT IS NOT BEING BUILT THE MOMENT IT WAS AUTHORIZED

Recorded because "authorized but not started" reads as drift unless the reason is written down.

**The rung's failure mode is quiet.** §3.3 regenerates **every installed rule** through an amended
template; a subtly wrong template produces subtly wrong emission across the whole population, and
it surfaces as byte-diffs that have to be read carefully. §6 requires the amended template to be
read against the known-defect ledger *before first emission*. That is the work that degrades late
in a session — **match the task's failure loudness to the seat's mechanical state** — and it was
authorized at the end of a full build campaign that had already produced one mechanical slip.

**Nothing is blocking it.** The prerequisite is met, the ruling is granted, and the fleet is green
and committed. It opens cold at the top of the next session.

---

## 1. THE RULING — ✅ **GRANTED, Tony, 2026-08-11**

> ⚠ **DISPOSITION 2026-08-13 (SEQ 61 riding item). THE GRANT STANDS; ITS DESCRIPTIVE PARAGRAPH IS
> RETIRED AS DESCRIPTION.** The conditional was: grep for citers, keep it descriptive if cited,
> retire it if not. **Grepped: nothing outside this file's own thread cites §1.** The only hits are
> `:12` and `:188` here and three notes in `docs/wakeup.md` that exist solely to say §1 needs
> restating. **So the restatement Tony was owed is discharged by retirement rather than rewriting**
> — nobody is reading it, and a description falsified by the same document three sections later is
> a liability, not a debt.
>
> **What is retired is ONLY the "goto scaffolding out, operator chains in" account** in the
> paragraph below, which §3 falsified by measurement: **no emitted method has ever contained a
> goto**, so there is nothing to take out. **What STANDS, untouched, is the two-clause grant** —
> the template amendment and the named widening of `AND`/`OR` to the generated-code population.
> **The grant never depended on the description.** The real delta is `&&`/`||` → `AND`/`OR`, and
> §2's customer-population case argues it on its own feet.

Both clauses, as put:

1. **Template amendment.** `docs/attributesTemplate.md`'s **frozen section may be edited** to emit
   `AND`/`OR` chains. **The edit is dated and the old form stays legible in the doc's history** —
   the same discipline as every retired ruling in this tree.
2. **Named widening.** The landed consumer respell (`a7fcb34`) was scoped **ALTERNATION-only**.
   **Generated-code use of `AND`/`OR` is a NEW population**, named as such, and **this charter is
   the widening request**. Tony's GO **is** the ruling that grants it. **Nothing slips in
   unscoped.**

⚠ **THE AUTHORIZATION CAME WITH AN HONEST CAVEAT AND IT IS KEPT VERBATIM, because it is a
standing instruction about how to run this rung:** *"Honestly not 100% sure what I just
authorized but authorizing anyway."*

**So what it authorizes, in one paragraph, is recorded here for the resurrection reader.** Today
an installed rule's generated parse method is built from **`goto generatedExit`** scaffolding
(`GroupItem.twk:1232` and `:1269`): each term is tried, and on failure control jumps to a common
exit that rewinds the rule mark. **The respell replaces that scaffolding with operator chains** —
a sequence of terms becomes `t1() AND t2() AND t3()`, an alternation becomes an `OR` chain. **It
is only sound because of what landed on 2026-08-11**: short-circuit means a failed term stops the
chain, and **the convention puts the mark-restore INSIDE each term**, so stopping early cannot
strand the mark. **The cost** is a template edit whose blast radius includes two frozen fences
(§6 below) and a regeneration of the whole installed population.

---

## 2. WHY — recorded so the seal can cite it

- **Customer population.** Nothing certifies a new operator like the grammar population firing
  through it on both engines. **The 47** is the target census: every installed rule becomes an
  `AND`/`OR` customer, and every future install inherits the form.
- **The north star.** `genParse` → installed method → IR stored → rebuilt from IR → green is
  cleaner when the generated body is composed of **already-certified constructs** instead of
  bespoke gotos.
- **GM-6 pressure relieved by construction.** Action-firing becomes **the consequent of a
  successful `AND`-chain** rather than code a `goto` must be careful not to skip — the Braced
  red's failure shape **ceases to be expressible**.

---

## 3. THE WORK, IN ORDER

0. ✅ **MEASURED 2026-08-11, AND IT STOPPED THE RUNG RATHER THAN GATING §3.5. THE ANSWER IS NO.**
   Full record in §6's Braced row, which is rewritten below. Headline: **GM-13's lead was already
   dead**, the goto **was** a cause and was **repaired on 2026-08-06**, and **no emitted method has
   ever contained a goto** — so §3.5's promised exhibit is not producible from any rule.
   ⚠ **§§1-5 below are LEFT AS WRITTEN**, per the legibility rule. Read §6 first.
1. **Baseline capture** — full fleet per the standing rider, **plus the genParse ladder
   specifically**: `parseScaf`/`parseScaf2` emission vs `genLadder/rung12.target`, and the current
   installed-rule population fired and captured **byte-for-byte**. **The old emission text is the
   baseline artifact; keep it diffable.**
2. **Template amendment** per §1, ruling in hand.
3. **Regenerate the installed population.** Every rule installed to date is re-emitted through the
   amended template. ⚠ **None is hand-edited — a hand edit means the template is wrong; fix the
   template and regenerate.**
4. **Fire twice, byte-agreement, per rule.** Interpreted vs jitted. **The convention's
   postcondition is the per-term assertion:** failure restores `atRuleMark`; short-circuit leaves
   **no partial consumption**. **Report VALUES, not counters.**
5. **One structural diff as deliverable** — old emission vs new for one representative rule,
   showing the goto scaffolding out and the chains in. **The seal's exhibit.**
6. **Post capture + rider.**

---

## 4. SCOPE FENCES

- **Plannability does not move.** This rung changes the **FORM** of what the generator emits for
  rules it can **already** plan. **Gap B's 21, the REFUSE population, and the denominator are
  untouched** — if a rule was REFUSE before, it is REFUSE after, **for the same reason**.
- **Not KE-4.** The text-local population (`genEmit` 7, `lessProbe` 4, `genMany` 2) keeps its own
  rung. If the respell walks past a text local, **note the sighting; do not repair**.
- **Not the `jitEmitUnary` ← `opPlusPlus` crash.** Still parked. **Adjacency is not scope**, even
  though this rung lives in the JIT arc.
- **The phase rule holds in the emitted code:** emit time never enters a runtime handler for its
  value; run time never enters an emitter. **The respell must not create a new crossing in either
  direction.**
- **No new vocabulary.** `parseMethod=` / `parseTerms=` install verbs unchanged; `incant/setup`
  untouched.

---

## 5. CONTROLS

- **The AND/OR rung's own fixtures, fresh from its seal, are the operator-side control** —
  `incant/andProbe` and `incant/orProbe`, now kept instruments in `docs/genKantParse.md` §5. They
  pin operator semantics so **any movement here is respell-caused, not operator-caused.**
- **Ladder at 184 / exit 0** — any row movement is a finding, **named by row**, H6 re-pin sentence
  if a pinned row graduates. ⚠ **There are currently NO inverted rows on the ladder**, so any red
  is a real red.
- **`parseTrace`** is the standing red-response localizer if a regenerated rule verifies red.
- **The audited zero-text-local status of the seam controls carries over**; a new fixture with a
  text local **leaves the audited set and says so**.

---

## 6. RISK REGISTER — named now so the seal isn't surprised

- **The template fence.** The 08-10 fence line and §6's **`i32`-by-rule** fence are **inside the
  blast radius** of a template edit. ⚠ **The amendment must re-state both fences as preserved,
  explicitly, in the dated edit.**
- **GM-17/PC-4 family.** Template changes have previously **nearly reproduced a known defect
  before anything ran** (H1, save/restore logic). Same vigilance: **read the amended template
  against the known-defect ledger BEFORE first emission.**
### ⚠⚠ BRACED — **§3.0 RAN 2026-08-11. THE ANSWER IS NO, AND IT IS BIGGER THAN THE EXHIBIT SLOT.**

**Fired on Clay's SEQ 48 item 4, on Tony's GO. Original row kept verbatim below this block.**

**FOUR MEASUREMENTS, in the order they were taken. None needed an install.**

1. **GM-13's lead was already dead, and had been since the day after it was written.**
   `docs/grammarCorpus.md` **GM-16** (2026-08-05) is titled *"the localizer worked, and it
   falsified the lead it was built to test"* — `parseR term= ExpressioN -> attached as ExpressioN
   under Braced`. **The attachment is correctly named.** GM-13's lead paragraph sits seventy lines
   above its own refutation in the same file. ⚠ **This charter cited the lead, not the file.** A
   forward pointer has been added at GM-13 so the next reader cannot repeat it.

2. **The goto WAS a cause — and it was REPAIRED on 2026-08-06.** GM-16/GM-17 measured it on two
   rules: `parse()`'s generated arm ended `goto generatedExit`, and the rule-action fire sat inside
   the match loop, so the `goto` jumped over it. **GX-1 extracted `fireLabelMethod` and both arms
   now call it** (GM-18). ⚠ **Verified in TODAY's source, not cited:** `GroupItem.twk:1231-1232`
   reads `if sukcess { fireLabelMethod(ruleStuff); attachLabel(ruleStuff,pStuff,0); }` and *then*
   `goto generatedExit`. **The fire is before the jump. That defect is closed.**

3. ⚠⚠ **AND THE PREMISE UNDER §1 IS FALSIFIED BY THE EMITTED TEXT: NO GENERATED METHOD HAS EVER
   CONTAINED A GOTO.** Measured today by regenerating rather than citing —
   `INCANT_PARSE_RECORD=<path> incant incant/recordPT`:

   ```
   extern GroupItem parseBraced(GroupItem rule)
   {
   GroupItem   into  = rule.rStuff.parentLabel;
   GroupItem   label = new("Braced");
   ...
       return leaveRule(rule,into,label,from, lit(t1,"[") && parseR(t2,label) && lit(t3,"]") );
   }
   ```

   **Byte-identical to the 2026-08-05 banking** in `docs/emitted/phaseB-twelve-emitted.txt`, so the
   emitter has not drifted. **It is ALREADY an operator chain.** The `goto generatedExit` at
   `GroupItem.twk:1232`/`:1269` lives in `parse()`'s **hand-written** generated arm, which the
   respell does not emit and which every generated method reaches through `leaveRule` either way.

   ⚠ **THE CONSEQUENCE FOR THE RUNG, AND IT IS THE REASON THIS STOPPED RATHER THAN RE-AIMED:**
   §3.5 promises *"old emission vs new for one representative rule, showing the goto scaffolding
   out and the chains in"* — **that exhibit is not producible from ANY rule**, because no emitted
   method has ever had a goto in it to take out. **The real delta is `&&`/`||` → `AND`/`OR`**: C++
   operators in the emitted C++ becoming the incant words. That is a real change with a real
   argument behind it (§2's customer-population case stands on its own feet), **but it is not the
   change §1 describes**, and a seal built on §1's sentence would have claimed a structural repair
   that had already happened five days earlier for an unrelated reason.

4. **The red that survives has a different mechanism, and it is named to one line.** GM-29
   (2026-08-07): `attachLabel`'s no-label guard, **`GroupItem.twk:1101`** — verified at the site in
   today's source, comment and all. `Braced` is an **option of the alternation `InvokeArg`**
   (`incant/grammar:105-109`); an alternation is label-transparent so `pStuff.label` is null, and
   the generated arm passes `promote=0` per PC-1, so the option's label is **dropped on the floor,
   silently, at exit 0**. GM-29's own probe shows the `isTarget=1 pLabel=0` signature throughout an
   ordinary parse. **Not a `Braced` defect — the general case of an option under an alternation.**

**HONEST LIMIT, STATED RATHER THAN GLOSSED: `Braced` ITSELF HAS NOT BEEN RE-RUN SINCE 2026-08-05.**
GM-29's post-GX-1 reproduction is on **`Parens`**. That `Braced` is *still* red today rests on
shared shape and shared alternation parent — **structural, pointable, and not measured.** Measuring
it is an install (emit, `genParse.rtn`, an out-of-repo `groups.ext` extern, the grammar line,
`tokall`, rebuild), which is a rung and not §3.0's one before/after. **It was not taken.**

**DISPOSITION: STOPPED, per the dispatch's own terms** — *"if the goto scaffolding is not the
cause, say so and stop; a flagship that goes green for an unrelated reason is worse than no
flagship."* It is not the cause. ⚠ **And the failure mode the dispatch feared was live: had Braced
been installed as the exhibit and come back green, GX-1 — landed five days ago, for a different
defect — would have been read as the respell's proof.**

**WHAT IS OWED BEFORE THIS RUNG CAN FIRE, and it is Tony's call, not a task anyone should start:**
**§1 needs restating in terms of the real delta**, and with §1 restated, §2's third bullet (*"the
Braced red's failure shape ceases to be expressible"*) needs re-deciding — **that shape ceased to
be expressible via GX-1, not via anything this rung does.** The `&&`→`AND` widening may still be
worth doing on §2's first two bullets alone. **Nothing about the ruling in §1 is withdrawn; what
moved is the description of what it buys.**

---

**ORIGINAL ROW, KEPT VERBATIM:**

- ⚠ **BRACED — AND THE CHARTER'S PREMISE HERE IS UNMEASURED, WHICH IS WHY §3.0 EXISTS.** The
  charter nominates `Braced` as §3.5's representative because *"first install went red on the goto
  structure."* **`GM-13` (`docs/grammarCorpus.md:268`) confirms the RED and PARKS it, but names
  its cause as** — verbatim — **"LEAD, at the usual odds, UNMEASURED and NOT HARDENED."**

  So *"the goto structure is why Braced is red"* is a **causal claim resting on a lead its own
  entry declines to harden**, and it carries the `MECHANISM-UNVERIFIED` tag minted the same
  morning. **This matters practically, not tidily:** if the goto structure is not the cause, then
  the flagship exhibit either **stays red** (and the seal has no exhibit) or **goes green for an
  unrelated reason and is read as proof**. ⚠ **Measure GM-13's lead before committing Braced to
  the exhibit slot** — one before/after against `docs/emitted/braced-red-specimen.txt`, which
  already exists. **Cheap now, expensive as a seal correction later.**

---

## 7. RETURN CHANNEL

`ipc/clod-to-clay.md`, WT-11 honored (whole file, no silent overwrite; check the prior turn's
STATUS before writing). **Rider attached, values not counters, and §3.5's structural diff included
inline.**
