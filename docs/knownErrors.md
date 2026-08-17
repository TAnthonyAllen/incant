# Known Errors — recorded now, ruled later

*Started 2026-07-31.*

**What this file is, and why it is not CLAUDE.md's bear traps.** A bear trap is
**settled**: the behaviour is understood, the workaround is known, and the entry exists so
nobody pays for it twice. An entry here is **unruled** — the behaviour is measured and
reproducible, but whether it is a defect, a design consequence, or a missing diagnostic has
**not been decided, and deciding it is not this file's job.**

The distinction is load-bearing. Filing an unruled behaviour as a bear trap hardens a guess
into doctrine, which is precisely the failure `CLAUDE.md` bear-trap #18 was split apart to
undo. Filing it nowhere loses it. So: **record now, rule later**, and an entry graduates to a
bear trap (or to a fix) when someone with the authority to rule does.

**Each entry carries:** what was measured · what is genuinely unclear · the composition that
makes it bite · who rules.

---

# ⚠ OPEN RULINGS — CARRY-OVER PAYLOAD

**Adopted 2026-08-17, for the joint full-monty front.** This block is an **INDEX, one line per
item**, pointing at wherever the detail lives — a KE entry below, a `docs/fixIts.md` row, or the
item itself if it is two lines. **Clod maintains it. Tony never curates it.** When a carry-over is
wanted, this block *is* the payload: copy from the heading to the rule below it, nothing to collect.

**WHY IT EXISTS.** Clay is out of the loop between carry-overs by design, so a question that needs
a *ruling* rather than a *fix* has to survive the session that found it. The failure this guards
against is not forgetting — it is **settling a contract at the keyboard**, which produces something
that gets built on and surfaces rungs later with no line pointing back.

**THE TEST, and it is one line because it is applied mid-debug or not at all:**

> **Does the fix require writing a NEW sentence into a doc to justify it?**
> **No** — it only makes code obey a rule that already exists → **BUG.** Tony and Clod, settled in
> the fire. **Yes** — someone must *choose* between two defensible behaviours → **CONTRACT.** It
> comes here and goes to Clay.

*Worked example: a rule carrying attributes AND members violates a **ratified** contract, so it is a
bug. What a template should emit for a rule with **neither** has no ratified answer, so it is a
ruling.*

**THE BACKSTOP, for when the test gets skipped — and it will.** If a commit message starts
**justifying** a behaviour ("we do X because Y is better"), a contract is being set in the fire.
That sentence belongs in a ruling. Mechanical, and auditable the same day.

**COST ASYMMETRY: WHEN UNSURE, ESCALATE.** Escalating a bug wastes one carry-over round. Settling a
contract in the fire is the expensive one.

**AN OPEN RULING DOES NOT BLOCK THE WORK.** Record it, then **proceed under a named assumption**
stated at the code site, **prefer the reversible branch** where two options are close, and **flag in
the commit** which code was written against an unruled assumption — so applying the ruling is a grep,
not an archaeology. ⚠ **ONE NAMED EXCEPTION THAT DOES BLOCK: frame semantics.** It is load-bearing
for the JIT and a guess there surfaces far from its cause.

**EACH ROW PRE-REGISTERS BOTH BRANCHES**, not just the question — it makes the ruling a one-liner
instead of an investigation, and on 2026-08-10 that discipline twice **dissolved** a fork before
anyone had to rule on it.

| # | the question | branch A | branch B | detail | proceeding under |
|---|---|---|---|---|---|
| **R-1** | F-11's fix: how does `aCTionIF` recognise a BlocK so it tests presence instead of invoking? | **exclude BlocK by a flag/tag test at `ruleActions.rtn:717`** — narrow, safe, but leaves `if <any other method-bearing field>` still executing, which the ruling's *"consistent with every other field"* rationale arguably contradicts | **drop the invoke in condition position generally** — matches the rationale | `docs/fixIts.md` F-11 | nothing yet; no fix written |

| **R-2** | **HOW DOES GENERATED PARSE FIRE?** Tony, 2026-08-17: *"I do not think having parse fire it is a good idea unless we get to the point that we can shitcan the old parse and replace it in new shoes."* | **old `parse()` fires it** via `definingRule().rStuff.parseMethod` — the existing `parseRuleMethod` door. Migration-friendly, one rule at a time | **generated parse is its own entry** — old `parse()` fires only at the ROOT, or is replaced outright | this section | nothing; no firing mechanism is being built |

## ✅ R-2 RULED 2026-08-17 (Clay, ratified by Tony) — REPLACEMENT, NOT COEXISTENCE

**Verbatim transfer from `docs/jit.md` §0.** *Generated parse **is** the parser; old `parse()` is the
**specification** and the **transitional fallback**, and it retires by attrition as the population
lands.* Two live paths means every divergence is a schedule artifact, every green is ambiguous about
who answered, and *"which arm ran"* haunts every fixture forever. **The parse campaign has already
paid this tuition once** — the PC campaign existed because `parse()`'s two arms never had a shared
contract.

**Mixed mode: accepted transitionally, COUNTED mandatorily — and GATED.**
⚠ **THE GATE IS NOT THE COUNTER.** On 2026-08-08 `genLadder/mixed.sh` measured the *old* install-path
mixing and found something worse than divergence: **a mixed configuration silently DROPPED A CHILD
NODE** — both pure configurations kept it, the mixed one lost it, **at exit 0 with no diagnostic**.
That is why IA-0 ruled the migration unit was the alternation. The new self-dispatch mechanism is a
different animal and **may** not carry that defect — *may not is not does not*. **So the entry gate
for mixed mode is re-running mixed.sh's question against the NEW mechanism**, before eighty rules
are in flight. Its shape is a **decomposition, not a smoke test**:
`diff(ALL installed, NONE) == diff(A only) + diff(ALT only) + diff(OUT only)` — equal means
divergence is **local and composable**.

**Root dispatch: a seam owned by the existing frame convention**, not an architecture. An emitted
body never sees parser internals; position, label and invariant belong to the C++ frame around the
dispatch.

**STILL OPEN, and it is Tony's** — the same one `jit.md` §0 holds open: **what a rule the generator
cannot emit yet does during the transition.** Precedent is one-sided: **refuse-and-count has beaten
fold-and-be-quiet every time it has been measured.**

### ⚠ THE SEAM ALREADY EXISTS IN CODE — found 2026-08-17, and it answers "who calls the door"

There is **nothing to build for the root**. The dispatch is already two nested forks:

1. `parse()` forks on `definingRule().rStuff.parseMethod` — `mixed.sh`'s original subject.
2. `setParse` installs **`parseRule`** into that slot for any rule with a `groupList`
   (`Generate.rtn`, `or groupList parseMethod = parseRule`).
3. **`parseRule` forks AGAIN** — `if field.isAction` runs the generated `BlocK`,
   **`else result = parse(ruleStuff)`** falls back to old parse.

**Fork 3 is the new mixed-mode seam.** So: **the counter goes there, in one place**, and the crossing
fixture is constructible in both directions off the same fork. `Start()` needs no kick — the door is
already wired.

⚠ **AND THE NAPALM SMELL IS REAL, CORRECTLY IDENTIFIED, AND ALREADY THE BEHAVIOUR.** `walkRules`
compiles rule by rule, so a rule's generated method goes live for the **remainder of the same
process** the moment it lands — the parser changes **under the walk that is building it**. Two
mitigations worth noting before it bites: the installs are **in-memory and per-process**, so a bad
generation is undone by not running the script rather than by repair; and **generation and
activation are separable in principle** but are not separated today.
**FIRST MEASUREMENT OWED:** does a rule carrying freshly-generated `CodE` actually take `parseRule`'s
`isAction` arm? `walkRules` gates on `actionTypE == 0` while `parseRule` tests `isAction`
specifically, and `actionType` is a 2-value enum (`isAction`, `isCoded`) — **so it is not obvious
that the arm the walk creates is the arm the parser reads.** One probe, and it is the crossing
fixture's first row.

**R-2 — THE SCOPE IS SMALLER THAN IT LOOKS, and this is the finding to carry into the ruling.**
The emitted body is **already self-dispatching**: `if leftBrace() AND ExpressioN() AND rightBrace();
return runRuleAction(this);` calls its terms **directly**, and `runRuleAction` is a registered incant
command. A generated rule therefore **descends by itself** and never asks old `parse()` to walk its
children. **So the only open question is what fires the ROOT — one node, not eighty.**

⚠ **AND IT DEFLATES R-1'S NEIGHBOUR.** `rStuff.parseMethod` is **old parse's** dispatch channel. If
generated parse self-dispatches, that channel matters only at the entry point — so **do not spend
effort repairing satellite `setParse` writes into a channel that may be abandoned.** That is the
demolition-arc trap run backwards: repairing the condemned.

⚠ **THE SAME RULING ALREADY EXISTS ONE DOMAIN OVER.** `docs/jit.md` §0: *the JIT REPLACES the
interpreter, it is not an accelerator running beside an interpreter that stays* — and its one open
ruling is *what happens to a construct the JIT cannot emit yet, because falling back to the
interpreter IS divergence.* **Tony's parse position is the identical shape**, so the ruling may be
mostly pre-made; the value of asking is consistency, not novelty.

⚠ **THE HAZARD IN TODAY'S BEHAVIOUR, unmeasured but structural: THE MIXING IS ALREADY HAPPENING AND
IT IS SILENT.** `ExpressioN()` invokes whatever `ExpressioN` currently is — generated if it has been
compiled, old-parse if it has not. That is convenient and it is exactly the silent-divergence shape
the JIT ruling names. **If mixed mode is accepted transitionally it must be COUNTED, not silent** —
the same instrument shape as `gJitSlotCount` and the degrade counter, for the same reason: a fallback
nobody counts is a fallback nobody can assert is absent.

⚠ **AND THE DEMOLITION DOCTRINE CUTS BOTH WAYS.** Old `parse()` is the only written specification of
what the generated parser must reproduce, so **read it before deleting it, and do not delete until
the replacement is green** — while equally not repairing it where the repair only serves the path
being retired.

**R-1 — WHY IT IS A CONTRACT AND NOT A BUG**, by the test above: branch B changes what `if x;` means
for *every* method-bearing field, so justifying either branch needs a **new sentence** in a doc.

⚠ **BRANCH B IS ALREADY MEASURED AND IT IS DEAD.** Built and run 2026-08-17: **fleet 40 → 33 green**,
`rung5.target` emitted **nothing**, `spellScratch` **SIGSEGV 139** — the invoke is load-bearing for
the kant emission path. Source restored byte-exact, rebuilt, fleet back to baseline.
**So the ruling is not "A or B" — it is: A is forced, and the question is how narrowly to spell it,
and whether the residual inconsistency (other method-bearing fields still execute in condition
position) is accepted or filed.** That is a one-sentence ruling, which is the point of measuring
first.

---

## KE-1 — an empty attribute reads back as its own TAG

**Measured 2026-07-31.** A value written in the delimited-literal form parses cleanly, stores,
and produces an attribute **with no data**:

```
content=(some text here#);      ->  attribute exists, carries NO DATA
content="some text here";       ->  attribute exists, carries the data
```

A field with no data returns its **tag** from `.text` — so `content` read back as the literal
string `content`. Not an error, not a warning, not a null. **A plausible-looking value that
happens to be the field's own name.**

**Scope, measured as a controlled comparison rather than assumed:** the same probe was run
under the pre-2026-07-31 `,` grammar and the current `#` grammar and behaved **identically**,
so this is **pre-existing** and not a consequence of the StringXP change.

**What is genuinely unclear, and why this is not filed as a bug:**
- The tag-for-empty readback is very likely **deliberate** — it is the same rule that
  `CLAIM KANT-10` records, and the 35a concatenation work depended on knowing it
  (`empty += "a" "b"` would otherwise concatenate onto the field's own name).
- Whether `(text#)` *should* assign in a define-attribute value slot at all is a separate
  question nobody has asked. It may simply be the wrong construct for that position.

**So both halves may be individually correct. The trap is the COMPOSITION** — a value form
that silently stores nothing, meeting a readback rule that returns something plausible instead
of nothing. Either alone is survivable; together they produce a data structure that reads as
populated while holding nothing.

**Where it bit:** 32 values in `incant/jigcorpus`. The corpus looked full and every claim it
held was empty, for roughly a month.

**Mitigation in place, not a fix:** `incant/jiquery` section 0 walks every claim and reports
any whose `content` equals its own tag.

**Rules:** Tony.

---

## KE-2 — an undeclared attribute name reads back as 0

**Measured 2026-07-31.** In a registry-style define file, an attribute name that is **not
declared `virtual`** at the top parses fine, stores fine, and **reads back as `0`** from a
query. No error, no warning, exit 0.

The comparison is inside one file in one run, which is what makes it clean:

| name | declared `virtual`? | reads back |
|---|---|---|
| `content`, `confidence` | yes | correctly |
| `action`, `test`, `blocker` | no | `0` |

**What is genuinely unclear:**
- Requiring declaration is **plausibly by design** — it is how the field-name universe stays
  closed, and closure is load-bearing elsewhere (the JIT frame schema depends on exactly this
  property).
- The **silence** is the questionable half, not the requirement. An undeclared name could
  refuse loudly at define time at no cost to the design.

**Again the trap is the composition, not either half:** a name that is legal to write, legal
to store, and returns a falsy value on read. The write side gives no signal and the read side
gives a value that looks like "absent" — so the natural conclusion is *"the data was never
written"*, and the search goes to the wrong file.

**Where it bit:** `incant/jigcorpus`'s `nextStep` block. Cost two wrong hypotheses
(`=` vs `:=`; attribute-vs-member structure) before the actual difference — declared vs not —
was visible, and it was only visible because a declared name and an undeclared name sat side
by side in the same record.

**Rules:** Tony.

---

## The pair, and why they are filed together

KE-1 and KE-2 have the **same shape**: a write that stores nothing or stores unreachably,
meeting a read that returns something plausible rather than nothing. Both produce
**structures that read as knowledge while holding nothing**, at exit 0, with no diagnostic.

That is the same family as `CLAUDE.md`'s testing doctrine — *exit 0 is necessary and not
sufficient* — arriving one layer down, in the data rather than in the run. **A ruling on
either should probably consider both**, because a fix that makes one loud and leaves the
other silent leaves the composition intact.

---

# KE-3 — REMOVING `case 'M'` FROM processFlags KILLS THE MEMBERs GATE
## ✅ CLOSED 2026-08-05 — RULED: **KEEP**. The restore stands.

**Tony's ruling, via Clay:** the diff was a **stale Dropbox base**, not one third of an
intended removal. The reasoning is the one this entry asked for and it cuts the other way from
the "unfinished removal" reading below: **a deliberate removal leaves footprints** — across the
grammar term, the bootstrap, the gate and the comment — and Tony's edit touched **none of
them**, while the removal silently kills his own 2026-08-02 attribute-pollution fix.
`addingMembers` and its whole footprint stay live. `census.target`'s separation remains Tony's
and is unchanged by this.

**Kept in full below** rather than deleted, because the measurement is the reason the ruling
could be made quickly, and because the alternative reading was live enough to be worth
recording as considered-and-rejected.

---

## The original filing — PARKED WORRY, 2026-08-04, at Tony's invitation.

**The ask, and why it is parked rather than done.** Tony's word, 2026-08-04:
*"wrt M case; pretty sure it was intentional and did not break anything. You can restore it
to as I had it. Park a worry if you have one."* I have one, it is measured rather than
suspected, and it contradicts the "did not break anything" half — so the removal is **held
pending his ruling** and the tree is left green. One word settles it either way; the cost of
guessing wrong is a silently dead gate, which is the expensive direction.

**THE MACHINERY IS FULLY WIRED AND `case 'M'` IS ITS ONLY CONSUMER.** Every other piece is
present in the tree today:

| piece | where | role |
|---|---|---|
| `MemberS ':'- MEMBERs- Mlist=DefinE+;` | `incant/grammar:53` | fires the MEMBERs term |
| `member = new("MEMBERs"); member.method = processFlags;` | `GroupMain.twk:90-94` | routes it |
| `case 'M': … currentDefine.addingMembers = true;` | `Commands.rtn:535` | **the only writer** |
| `… \|\| !currentDefine.addingMembers` | `ruleActions.rtn:225` | `aCTionDefinE` gates on it |
| `if addingMembers  addingMembers = false;` | `ruleActions.rtn:328` | clears it |
| `addingMembers` | `GroupBody.twk:53` | the flag itself |

`ruleActions.rtn:707` says it outright in a comment: *"that the MEMBERs case in processFlags
can find it to set its addingMembers flag"*.

**TWO CONSEQUENCES, and the second is the one that matters.**
1. **LOUD:** every `MEMBERs` token reaches processFlags' default arm, so a run prints
   `processFlag: invalid argument MEMBERs` — **23 times**, prepended to four baselines
   (`displayForm`, `jsonTest`, `manyScratch`, `printPop`). Measured: those four went red on
   the removal and green again on restore, which is what attributes the damage rather than
   the file's mtime.
2. **SILENT, and this is the worry:** with no writer, `addingMembers` is **never set**, so
   `aCTionDefinE`'s gate always takes the not-adding-members path — and **the
   attribute-pollution fix Tony landed on 2026-08-02 stops working**. Nothing prints. Nothing
   fails. It is the exact composition KE-1 and KE-2 are filed under: a structure that reads as
   working while doing nothing.

**WHAT WOULD MAKE THE REMOVAL COHERENT**, and it is a real possibility rather than a rhetorical
one: if the reshuffle also intended to drop `MEMBERs-` from the `MemberS` rule and the
`GroupMain` bootstrap, then removing the case is one third of a landed change and the other two
thirds are still in the tree. That reading fits the evidence better than "it broke nothing",
and it is Tony's to confirm — he was working the MemberS rule and the name-escape issue at the
time. **If so the fix is to finish the removal, not to re-add the case.**

**Related, and unresolved from before this:** `pop.sh`'s `census.target` red is *already* about
this rule — genParse refuses to plan `MemberS` since the `MEMBERs-` term was added. So the
grammar half of this question is open on two fronts at once, which is an argument for settling
them together.

---

# KE-4 — A **TEXT** LOCAL IN A JITTED ACTION COMES BACK AS ITS **LENGTH**, silently, degrade 0

**Measured 2026-08-10**, `incant/kant8M1` (jitted) against `incant/kant8M1o` (interpreted, own
process), on the shipping gated binary with **no source change**. Found while running M1, the
KANT-8 return-channel probe; it is not what M1 went looking for.

An action-local assigned a string prints, from **inside** the jitted action, as an integer:

| the source line | interpreted | **jitted** |
|---|---|---|
| `m1text = "alive";` | `alive` | **`5`** |
| `m1text = "xy";` | `xy` | **`2`** |

**Two points, so it is a discrimination and not a reading:** the number tracks the string's
**length**. The count local beside it (`m1count`) is correct on both arms, at every depth, in
both directions — so this is not a general frame failure.

```
  M1 int  before  : m1count = 42 m1text = alive
  M1 jit  before  : m1count = 42 m1text = 5
  === jitDegrade count = 0 ===        <- the fallback counter never fires
  === jitCompile count = 1 ===
```

**WHAT IS GENUINELY UNCLEAR — and this is why it is filed here and not as a bear trap.** The JIT's
frame is **scoped to i32 counts by declared design**: the prologue allocates an integer slot per
frame member and the epilogue stores each slot back to the field's own storage
(`GroupRules.mm`, FRAME PROLOGUE / FRAME EPILOGUE, Increment 1, 2026-08-01), and
`appendGroupValue`'s header states the same scope in as many words — *"PHASE SCOPE: i32 counts,
matching what the emitters produce today. A double or string entry is the same shape with a
different setter and wants a rung before it is written."* So a text local landing in an integer
slot may be **the declared scope behaving exactly as declared**. What is not decided is whether a
construct outside the declared scope should be allowed to **compile silently**.

**THE COMPOSITION THAT MAKES IT BITE**, and it is the one the fleet doctrine is built around: a
**wrong answer at exit 0 with the degrade counter at zero**. `jitDegrade` exists to say *"this
construct fell through to interpretation"*; it says nothing when a construct is emitted **wrongly**
rather than declined. So every rung's degrade-zero assertion passes, and the H4-shaped instrument
that would normally catch a fallback is structurally unable to see this. Same family as the
already-ruled *"a degrade line asserts that a fallback OCCURRED, never that it was SOUND"* — one
step worse, because here no fallback occurred at all.

⚠ **WHY NOTHING CAUGHT IT: THE CERTIFIED TEMPLATE NEVER PUTS TEXT IN A LOCAL.**
`incant/jitXtemplate` — rung JXT, the SEQUENCE template, green and jitted — carries `xtSuk`,
`xtTicks`, `xtOK1`, `xtOK2`, all counts, all **declared in the `define` block** rather than born in
a body. The jitted population to date is integers by construction, so the fence was never tested
from the other side.

✅ **RULED 2026-08-10 (Tony): REFUSE AT EMIT, on the `jitPrintItem` precedent.** A body-born text
local **refuses at emit** rather than substituting an integer — silent-wrong becomes a **loud
degrade**, and every degrade-zero assertion on a text-bearing fixture regains its meaning for one
line of emitter code. **The REPAIR — real text returns from jitted actions — is deferred to its own
rung, unscheduled**, and is this entry's second half.

**THE REFUSAL OWES ITS H7**, and the rung is specified so it starts at the fixtures: one fixture
that **would have printed the length** now degrading loudly, **plus a count-bearing negative
control that stays green and degrade-clean** — so the check discriminates rather than reddening on
any input. `incant/kant8M1` is the first of those two by construction; the second is a one-line
variant of it.

⚠ **AND THE POPULATION IS NOT HYPOTHETICAL — MEASURED BY THE NODE-RETURN CENSUS, 2026-08-10.**
Six body-born **text** locals are returned from live actions, and **two of them sit on the genParse
kant seam, which goes through `runAction`**: `incant/genEmit`'s `leaf` (the speller, consumed at
`genParse.rtn:964` as `result.text`) and `incant/genMany`'s `answer` (the manier, consumed at
`:847` as `result.text eq "1"`). **So the kant speller and manier are KE-4's customers the moment
they are jitted** — which is what makes refuse-at-emit worth its one line now rather than later.

**Fence in force meanwhile:** `docs/attributesTemplate.md` §6 carries the rule, frozen with the
template shapes — **template locals are `i32` by rule, not by habit, until this is repaired rather
than refused.**

**WHO RULED THE REFUSAL:** Tony, above. **WHO RULES THE REPAIR:** Tony. **It is First Light's floor** and the M1 dispatch said so: if parse templates
may hold text in a body-born local, this is on the critical path; if they may not, that is a
constraint the template spec has to state, because today nothing enforces it and nothing reports
it. The cheap middle option — **refuse rather than substitute**, i.e. call `jitDegrade` on a
non-count local instead of emitting an integer slot for it — is the standing precedent from
`jitPrintItem` and would convert this from a silent wrong answer into a counted fallback.

**Fixtures:** `incant/kant8M1`, `incant/kant8M1o`. Neither is wired into a harness yet —
deliberately, since the expected values are exactly what this entry asks Tony to rule.

---

# KE-5 — `&&` ANSWERS `true && true` AS **false**. The symbol form of AND is not a truth table.

**Filed 2026-08-11**, during the AND/OR rung, on Clay's SEQ 32 instruction to file rather than
widen. **Deliberately NOT repaired** — the rung is scoped to the **word** forms, and widening
tier 3 to the symbols is a ruling, not a rung.

**MEASURED — `incant/andProbe` §2, values not counters:**
```
    true  && true   ->  false        <-- want TRUE
    true  && false  ->  false
    false && true   ->  false
```
All three rows answer false. The first is the one that makes this a defect rather than a
semantics: **there is no reading of `&&` under which `true && true` is false.**

**MECHANISM — STRUCTURAL AND POINTABLE, not inferred from the symptom.** `incant/setup:162`
registers `'&';` **bare — no `operateMethod`**. There is no `'&&'` entry at all, and the Operators
matcher returns the **longest match**, so `&&` matches the inert single-character `'&'` and fails
the body. **This is the exact state `'|'` was in before 2026-08-01**, and `setup:100-111`'s own
comment describes the failure mode in those words: *"`'|'` above is registered BARE, with no
operateMethod, so `||` matched an inert operator and failed the body."*

⚠ **THE REPAIR IS BELIEVED TO BE ONE LINE — `'&&' operateMethod=opAND;` beside the existing
`'||' operateMethod=opOR;` — AND IT WAS NOT RUN.** `incant/setup` is read at runtime, so testing it
costs no rebuild; it was left untested because *applying* it is the repair, and the repair is out
of this rung's scope. **Stated as a structural read, not a measurement**, per the standing rule
that reproduction proves the symptom and never the cause.

**Contrast with the word form, same run:** `AND` answers all three rows correctly and
short-circuits. So a reader who tests `AND` and assumes `&&` is a spelling of it gets a silently
different operator.

**Instrument:** `incant/andProbe` (§2 and §3, which sit adjacent on purpose).

## ⚠⚠ AMENDED 2026-08-11 (SEQ 49) — **IT IS WORSE THAN A WRONG ANSWER OVER CALLS: `&&` KILLS THE PARSE.**

The rows above use **bare field** operands. Over **CALLS** — which is the shape a generated parse
method has, and therefore the shape that matters — `&&` does not answer wrongly. It exits **139
with ZERO BYTES of output**, before the `Search list:` line, so it reads as a broken binary rather
than a broken spelling. Same family as bear-traps #27/#28: the failure points at the wrong thing.

**BISECTED, one operator at a time, on one file** (`incant/kantRuleS`, whose header carries this):

| the body | result |
|---|---|
| `t1() AND alt() AND t3();` with `a1() \|\| a2()` | **exit 0**, all rows print |
| `t1() && alt() && t3();` with `a1() OR a2()` | **exit 139, zero bytes** |

So the conjunction is the killer and the disjunction is not. **A second, independent
reproduction on PLAIN FIELDS — no calls — under the JIT also exits 139**, with the `testing()`
call entered and the process dying before any row printed and **before any degrade line**, so
nothing counts it. That fixture is **not kept**: a crasher in the swept population costs
`completePop` its zero-missing-sentinels baseline, and a fixture that dies before its first row is
an absence rather than a control. **The recipe is the reproducer** — take `incant/jitXand2`, change
`AND` to `&&`, run it.

⚠ **WHAT THIS CHANGES ABOUT THE REPAIR.** The believed one-line fix
(`'&&' operateMethod=opAND;`) is now believed to fix **the wrong half**: it would give `&&` a
strict handler and a correct truth table on fields, and would leave it **eager**, which for a
parse term is the over-consumption harm KE-6's amendment measures. **The symbols rung should aim
at tier 3 (`runShortCircuit`), not at `operateMethod`.** Still **not run**, and still a ruling
rather than a rung.

---

# KE-6 — `OR` and `||` DIVERGE ON EVALUATION: one short-circuits, one does not, **on one handler**

**Filed 2026-08-11**, created by the AND/OR rung and **named rather than hidden**.

`OR` is bound at tree build to `runShortCircuit` (tier 3) and skips its right arm on a true left
arm. `'||'` is registered `operateMethod=opOR` and stays a strict operator, so it evaluates both.
**Both ultimately answer through the same `truthOf` contract, so their VALUES agree** — it is only
the **evaluation** that differs.

**MEASURED — `incant/orProbe` §3 vs `incant/andProbe` §3b:**
```
    true || loudZero()   ->  [RIGHT ARM EVALUATED]   then TRUE     strict
    false AND loudOne()  ->  (no marker)             then false    short-circuit
```

**WHY IT IS NOT AN OVERSIGHT:** SEQ 32 scoped the rung to the word forms and ruled the symbol
forms filed-not-widened. Recorded because **two spellings of one operator with different
evaluation semantics is a trap in waiting** — a right arm with a side effect behaves differently
depending on which spelling the author reached for, and nothing announces it.

**Repair rung:** drawer item, unscheduled, wants its own charter — and it should be taken
**together with KE-5**, since both are the same question (do the symbol forms join tier 3) asked
about the two different words.

## ⚠⚠ AMENDED 2026-08-11 (SEQ 49) — **THE DIVERGENCE IS NOT COSMETIC. `||` CONSUMES INPUT NO OPTION MATCHED.**

Filed above as *"only the evaluation differs, the values agree"*, which is true of **field**
operands and **false of the shape this actually matters in.** Measured on a rule-shaped parse
method whose terms advance a cursor — `incant/kantRuleA` (word forms) against `incant/kantRuleS`
(the same rule, alternation spelled `||`), interpreted:

| row | `OR` | `\|\|` |
|---|---|---|
| all terms pass | ticks 3, **cursor 3** | ticks 4, **cursor 4** |
| alternation's option 1 passes | ticks 3, option 2 **skipped** | ticks 2, **cursor 2** |

**Option one succeeds; option two runs anyway and advances the cursor.** The rule reports SUCCESS
having eaten one more token than it matched. ⚠ **Both spellings return the same verdict on both
rows** — they differ only in how much input they consumed, so **a harness asserting the rule's
verdict would certify the eager spelling as correct.** Only the cursor tells them apart.

**This is the harm `docs/genKantParse.md` §1 refused the AND spelling over** (*"a parse term
consumes input, so an eagerly-evaluated right arm advances the mark past text the rule never
matched"*). That refusal was right about eager operators and is **retired for the word forms**,
which now short-circuit; it **stands, and is now measured rather than argued, for the symbols.**

**So the symbols rung's target is tier 3, not `operateMethod`** — see KE-5's amendment, which
reaches the same conclusion from the other word.

---

## KE-3 — `jitRunAction` **exits 139 on the degrade path** for a body whose operand is a command invocation

*Measured 2026-08-13 (SEQ 65 rung 0 / SEQ 66-r1 phase 1.0). Repair scheduled as SEQ 67 part C.1 —
safety net before capability. Filed here rather than as a bear trap because the MECHANISM is not
ruled; the SYMPTOM and its discriminating control are.*

### What was measured

```
r0body code={ return litK(1) AND litK(2); };      testing(r0body);

=== jitRunAction: entering on r0body ===
=== JIT DEGRADE #1: AND/OR LEFT operand produced no value
    -- not JIT-supported yet, running INTERPRETED: Token ===
exit 139
```

**The discriminating control, and it is what makes this a finding rather than a probe artifact:**

| run | exit |
|---|---|
| the body **jitted** | **139** |
| the **identical** body interpreted (`r0body()`) | **0**, sentinel present |

So it is not that `litK` outside a parse frame is unsurvivable — interpreted, it survives.

**Top frames** (`script -q /dev/null`, per the standing backtrace recipe):

```
0  aCTionBrancH      GroupRules.mm:167     <- the `return`
1  aCTionBlocK       GroupRules.mm:85
2  jitExecBlock      GroupRules.mm:5495
3  jitBuildFunction  GroupRules.mm:4055
4  jitRunAction      GroupRules.mm:6366
```

It dies **during the EMIT walk**, in the `return`, *after* the degrade announced that nothing was
in flight.

### ⚠ Discrimination from the parked `jitscratch` crash — recorded so the two are never merged

| | `incant/jitscratch` (parked) | **this** |
|---|---|---|
| reaches `jitRunAction`? | **NO** — `docs/jit.md` records it *"did not reach `jitRunAction` at all"* | **YES**, and dies four frames deeper |
| dies on | `jitInc` — the `++` emit path | `aCTionBrancH` — the `return`, on the degrade path |
| in scope? | parked; adjacency is not scope | **repair target** |

`++` is **structurally absent** from every kant parse body (grepped; the only hits are comment
prose), so `jitEmitUnary` is out of scope here by construction, not by assumption.

### What is genuinely unclear

**The causal story is INFERENCE FROM THE FRAME, not measurement** — that the degrade returns null,
leaving nothing in flight, and the `return` then dereferences the absent value. It is labelled as a
lead in `docs/jit.md`'s census and is labelled as a lead here. ⚠ **This project's standing
asymmetry says structural claims hold and causal ones are roughly a coin flip until run**, and four
rulings died in one day to four cheap measurements. **Verify at the site before repairing.**

### Why it bites harder than its size suggests

**Every future jit probe walks across the degrade path.** A fallback that exits 139 makes the engine
unsafe to point at unproven code — which is exactly what a probe is for. The degrade path is the
safety net, and a safety net that kills the run is worse than none, because it converts *"this
construct is not supported yet"* into *"the binary is broken."*

### ⚠ REPAIRED 2026-08-13 (SEQ 67 C.1) — AND THE INFERENCE ABOVE WAS **WRONG**

**Read this before trusting any causal line in this file.** The lead recorded above — *degrade
returns null, nothing in flight, the `return` dereferences the absent value* — sent the search at
`jitEmitReturn` and `gJitResult`. **The site says something else**, and it is three lines earlier
than the frame's top:

```
    if !arg         arg = BrancheS;
    or isMethod     arg = arg.gMethod(arg);      <-- arg is OVERWRITTEN by the method's return
    switch(*BrancheS.tag) {
        case 'r':   isReturn = true;             <-- stamps arg. arg is null. 139.
```

Under jitting the method **is the emitter**, and `jitEmitShortCircuit` ends its degrade path with a
bare `return nullptr`. So `arg` became null and **the STAMP dereferenced it** — not the
return-emission, which never ran. The dispatch's instruction to *verify at the site before
repairing* is what caught it; the inference would have produced a correct-looking repair **in the
wrong file**.

**Fifth entry in the standing causal-claim ledger.** Structural claims here hold; causal ones are
roughly a coin flip until run. Cost of the check: one function, read.

### ⚠ AND THE MECHANISM IS THE ONE-CHANNEL-ONE-MEANING FAMILY, in its sharpest form yet

A method's return value means **THE NODE** at run time and means **WHETHER EMISSION SUCCEEDED** at
emit time. **One channel, one reader, two ERAS** — not two facts. That is the fourth row of
`CLAUDE.md`'s standing table exactly, and it is the same shape as `isBranch` read by `aCTionBlocK`.

**The repair is the cheap half of the standing cure** — stop treating "no node" as a node:

```
    if !arg         arg = BrancheS;      /* re-establish; same node the no-expression path uses */
```

**The structural half — a separate emitted/refused channel — is deliberately NOT in this repair.**
It belongs to the invokable mechanism, which is gated behind the jittability census (C.2) and must
not be pre-built.

### The grading, against the done-condition as written

| leg | before | after |
|---|---|---|
| exit status of the census body | **139** | **0**, `=== survived ===`, sentinel |
| degrade still announced | — | **yes, count 1** — not removed to satisfy the check (H4) |
| returns the interpreted answer | — | **0 = 0** |

⚠ **AND A ZERO-AGREEING-WITH-ZERO IS THE WEAKEST POSSIBLE ROW**, so it was paired with a non-zero
sibling per the standing rule — a body that degrades **mid-body** and then returns a constant:

```
r0nbody code={ litK(1) AND litK(2);  return 42; };
     jitted 42   ·   interpreted 42   ·   degrade count 1   ·   both exit 0
```

**42 ≠ 0, so the agreement is real** — and the row asserts something the zero row could not: **a
degrade in the middle of a body does not poison the statements after it.** That is the difference
between *the fallback occurred* and *the fallback was sound*, which the standing rule says a
degrade counter can never tell you.

**Blast radius:** `aCTionBrancH` is on every `return`, `break` and `continue`. `oneTest`/`jsonTest`
byte-identical on both streams; **jit ladder exit 0, 184 green**; `pop.sh` unmoved; canary 274.

### Who rules — DISCHARGED

The repair is chartered (SEQ 67 C.1). **Done means:** the exact census body above degrades to
interpreted, **returns the interpreted answer**, and exits **0**. ⚠ **The census run is the fixture
— it is already in hand**, so the repair cannot be graded against a fixture written to suit it.

---

## KE-4 — the three `pop.sh` targets were **ALREADY STALE AT THE SEQ 55 SEAL**. Verdicts and evidence

*Measured 2026-08-13 (SEQ 70). Three binaries built and run against the SAME targets; only the
binary varied. Report only — every re-pin sentence comes back for ruling.*

### METHOD, stated before the numbers

pop.sh's own recipes were replicated verbatim into one probe, then run against three binaries:

| binary | commit | canary |
|---|---|---|
| HEAD | `9ffeb94` | 276 |
| **the revert point** — parent of SEQ 56 | `87196a2` | 273 |
| **the SEQ 55 seal** — the last clean-kitchen mark | `7decd8b` | 273 |

Only `GroupItem.mm`, `GroupRules.h` and `GroupRules.mm` differ across that range, so each binary is
a clean build of that commit's generated sources against unchanged fixtures and unchanged targets.

⚠ **THE CONTROL RAN FIRST AND IS WHAT MAKES THE REST READABLE.** At HEAD the probe reproduced all
three known reds exactly — 12, 7, refusals 4-want-7, 9. A replication that could not reproduce the
failures would have made every later row noise.

### THE RESULT — identical at all three points

| target | HEAD | revert point | SEQ 55 seal |
|---|---|---|---|
| `census.target` | DIFFERS, 12 lines | **DIFFERS, 12** | **DIFFERS, 12** |
| `iterT1m.divergence` | DIFFERS, 7 lines | **DIFFERS, 7** | **DIFFERS, 7** |
| `iterT1m` refusal count | **4**, want 7 | **4** | **4** |
| `oneTest.base` | DIFFERS, 9 lines | **DIFFERS, 9** | **DIFFERS, 9** |

⚠ **AND THE DIFFS ARE BYTE-IDENTICAL, NOT MERELY THE SAME SIZE.** Each binary's diff was diffed
against HEAD's: all three come back identical at both older points. Same failure, not three
coincidentally-sized ones — the check that separates *"agrees"* from *"agrees for the same reason"*.

### VERDICT — all three: **WORLD-MOVED, AND IT MOVED BEFORE THE SEAL**

The dispatch offered two verdicts. Both were framed around the 08-12 window, and **neither fits**:
the revert-point binary does not merely also disagree — **the SEQ 55 seal binary disagrees the same
way.** So these targets were **already stale when the seal was written**, and nothing in SEQ 56-68
is implicated in any of them.

**The sentences these buy, one per target, offered for ruling and not applied:**

- **`census.target`** — `MemberS` now **REFUSES** (`term MEMBERs unclassified`, `parseAction tail
  position only`) where the target holds a 10-line `SEQ MemberS` plan. The target records a
  *plannable* `MemberS`; the tree has not planned it at any of the three points. **The refusal is
  the newer truth and the target is the older claim.**
- **`iterT1m`** — the pinned divergence *and* its refusal count moved together, 7 → 4. The count
  check's own comment names all three things it is built to catch: the announcement deleted, the
  poison not taking, or *mutual recursion silently starting to work.* **Which of those it is has not
  been established here and should not be guessed** — it is the one row of this report that names a
  question rather than answering it.
- **`oneTest.base`** — three `AUDIT MISSTERM` rows for `JSONtoken`/`JSONvalue` are **gone**, two
  `AUDIT LOOSE` index numbers moved (`[9]→[1]`, `[14]→[6]`), and the summary gained a **new column**
  (`0 unconsumed`) while missing-terms went 15 → 12. The new column is `auditUnconsumed`, which
  post-dates the baseline. **The 15 → 12 is exactly the three vanished rows**, which is the
  reconciliation the standing re-pin rule asks for — the three terms are *named* rather than
  waved at.

### ⚠ AN INSTRUMENT FAULT INSIDE THIS RUN, RECORDED BECAUSE IT NEARLY LANDED A THIRD DATA POINT

The seal measurement was **run once and was VOID**, reporting `DIFFERS (0 changed lines)` and
`refusals 0` for all three targets. Cause: the build command chained `cd` into the Xcode project
directory, so the probe that followed **in the same invocation** ran from `TOK/` and every relative
path missed — `getFile: could not open file: incant/setup`.

**It was caught because the number was INCOHERENT ON ITS FACE**: a diff cannot *differ* with zero
changed lines. Had the probe reported a bare pass/fail, `DIFFERS` would have read as a real result
and *"the targets fail at the seal too"* would have been reported off a run that never opened a
fixture. **Print the quantity, not the verdict** — H4, paying for itself inside the one session that
wrote it down.

### ⚠ RULED 2026-08-13 (SEQ 70 follow-up). **THREE REDS, THREE DIFFERENT VERDICTS** — and the split is the point

Tony's ruling, and it deliberately refused a single verdict for all three.

**1. `oneTest.base` — RE-PINNED.** The world moved *legitimately* and the pin missed the boat. The
sentence is the reconciliation: three `AUDIT MISSTERM` rows (`JSONtoken` ×1, `JSONvalue` ×2)
vanished, **and 15 → 12 missing terms is exactly those three** — the terms are named, not waved at.
The summary also gained a `0 unconsumed` column from `auditUnconsumed`, which **post-dates the
baseline**. Re-pinned.

**2. `census.target` — RE-PINNED, AND THE OFFERED SENTENCE WAS FALSIFIED BY THE GLANCE THAT WAS
ASKED FOR.** The ruling proposed *"pin corrected, never valid"* — the target holding a plannable
`MemberS` the tree has never planned. ⚠ **The archaeology says otherwise, and the distinction
matters because the two sentences teach opposite lessons:**

| what was checked | what it says |
|---|---|
| target born `41a3831`, **2026-07-28** | already carried `PLAN MemberS / SEQ MemberS / LIT : / CALL DefinE` |
| re-pinned across five more commits **the same day** | the block **grew** `CALL` → `MANY DefinE` at the RUNG 5 (MANY) landing |
| last touched `168195b`, 2026-07-28 | **byte-identical to the version at HEAD** — untouched for sixteen days |

**So the target was captured from a real planning run and was maintained as the planner changed.
It was VALID AT BIRTH.** The tree stopped planning `MemberS` some time **after 2026-07-28 and before
2026-08-11**, which is earlier than any binary this campaign measured — hence "never planned at any
measured point" was true and **still did not mean invalid-at-birth.** ⚠ **The sentence is
WORLD-MOVED, in a window this investigation did not cover**, not pin-invalid. Re-pinned on that
sentence.

**3. `iterT1m` — NOT RE-PINNED. Stays red, pending cause.** 7 → 4 on the divergence *and* the
refusal count. The count check's own comment names three causes — the announcement deleted, the
poison not taking, or **mutual recursion silently starting to work** — and **none is established.**
Re-pinning an unexplained number is laundering with extra steps. It stays red-with-a-named-question
until one of the three is shown; that is bounded archaeology and a good short-session item, but the
pin waits on the answer.

**`pop.sh` after the two re-pins: 39 → 41 green, and the only remaining reds are `iterT1m`'s two
rows** — which is now a fleet whose red *means something specific*.

### ⚠ AND AN INSTRUMENT OF MY OWN LIED DURING THIS ERRAND, SAME SIGNATURE AS THE LAST ONE

A loop written to check six historical versions of `census.target` for `SEQ MemberS` reported **0 in
all six**. The direct read shows it present at line 103 of the very first one. **A uniform,
unsurprising zero across every row** — the same shape as the void seal run earlier the same day
(`DIFFERS (0 changed lines)`), and the same lesson: **the second measurement is what caught it, not
care.** Had the loop been trusted, the "never valid" sentence would have been written and would have
been wrong.

### Who rules

Tony — ruled above. `iterT1m` is the one still open, and it is open on purpose.
