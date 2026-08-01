# genParse C++→kant — DISPOSITIONS AND ORDER

*minionA's map (round: census, 2026-08-01), **grounded by Clod**. Adversarial pass below.
**Nothing is converted. Awaiting Tony's nod on the order.***

**Ruling 2 (Tony) governs every disposition:** conversion is **re-expression, not transcription**.
The first question per method is whether it should exist in kant at all. Kant code that has a
rule's name already has the rule; residual paranoia is one `isRule` test.

⚠ **THAT LICENSED FALLBACK DOES NOT EXIST TODAY — see BLOCKER 1. It is the single most
consequential thing on this page and it is a prerequisite, not a round.**

---

## FOREMAN'S GROUNDING — what I re-derived independently

*A claim validated by whoever wrote it is not validated (spawn rule). These were checked against
the tree by the foreman, not taken from the minion's report.*

| minion claim | verdict | how |
|---|---|---|
| `emitPlan` does **not** self-recurse; `printPlan` does | ✅ **CONFIRMED** | independent self-call count: `emitPlan` 0, `printPlan` 1 |
| `ruleOrRefuse`'s 3 sites all pass `argument.text` | ✅ **CONFIRMED** | greped before the minion was spawned, independently |
| `locateRule`'s other 2 sites are literals | ✅ **CONFIRMED** | `"ScafOUT"`, `"ScafC"` |
| `foldOf` has one caller, an instrument | ✅ **CONFIRMED** | whole-repo grep: `genParse.rtn:182`, inside `dumpRuleTerms` |
| ~14 flags declared in `setup` have no `opDot` case | ✅ **CONFIRMED** | cases present are 1-12, 17, 19, 20, 24, 28, 29, 401-405 |
| **INFERENCE I** — `if x.isRulE` is always true | ✅ **CONFIRMED BY RUN**, and it is worse than inferred | `incant/flagProbe` |

**The minion marked I as an inference and refused to present it as a finding. That was correct
and it is the behaviour to keep.** It has now been run, and it holds.

---

## ⚠ BLOCKER 1 — `isRulE` AND ~13 SIBLINGS ARE SILENTLY INERT. Foreman/Tony, not a round.

Measured, `incant/flagProbe`, exit 0, sentinel present:

```
a REAL rule   NamE.isRulE     -> [access to isRulE not supported yet]   if -> TRUE
NOT a rule    notARule.isRulE -> [access to isRulE not supported yet]   if -> TRUE
```

`opDot`'s `default` arm sets `product.text = "access to " tag " not supported yet"`, and a
non-empty string is truthy — so **`if x.isRulE` takes the true branch for everything**, rule or
not. It is not a loud failure; the diagnostic is only visible if you *print* the accessor.

Affected, declared in `incant/setup` with no case: `isRulE`, `isBiN`, `isMacrO`, `isConditioN`,
`isFilE`, `isIndexeD`, `isInitializeD`, `isPointeR`, `isVirtuaL`, `noSkiP`, `negatE`, `isLisT`,
`isPercenT`, `mergeON`, `byReF`.

⚠ **THE CONTROL SAYS THE FIX IS SMALL, and this is the part that stops it being alarming.**
An *existing* case works correctly in **both** directions — `notARule.noPrinT` → false,
`hushed.noPrinT` → true (case 29). So the machinery is sound and the missing cases are one line
each on case 29's model. This is accessor debt, not a design fault.

⚠ **A PROBE BUG WAS CAUGHT HERE AND IS WORTH THE LINE.** The first control run reported case 29
false for a `noPrint` field, which reads as "case 29 is broken". It was the probe: `hushed
noPrint;` written *inside* `code={}` does not set the flag; declared in the `define` block it
does. **Nearly a false causal claim about working code** — exactly the coin-flip class
`CLAUDE.md` warns about, caught only because the control had a known-good direction to compare
against.

**Blocks:** the `ruleOrRefuse` dissolve, order positions 6 and 7. **Does not block positions 1-4.**

---

## DISPOSITIONS

| method | disposition | why |
|---|---|---|
| `locateRule` | **dissolve** | string→node lookup; kant has the node by writing the name. Only in-arc consumer is `ruleOrRefuse` |
| `ruleOrRefuse` | **dissolve — but it is a CONVENTION change, not a method change** | see below |
| `dataName` | **dissolve** | kant already has the table, index-aligned and RUN: `dataNames[datA]` |
| `row42` | **retire from the arc** | sole caller is `dumpRuleTerms`, which declares itself *"MEASUREMENT TOOL, not part of the emitter"* |
| `foldOf` | **retire from the arc** | zero in-scope callers; `planRule` re-implements its test inline rather than calling it |
| `countRuleTerms` | convert | real walk work, zero accessor debt |
| `unresolvedTerms` | convert (blocked) | needs `!term.rStuff`; no kant accessor exists |
| `planTerm` | convert (last) | 141 lines, 11 refusals, largest accessor debt |
| `planRule` | convert | needs `isRule` + `binType` |
| `printPlan` | convert | was blocked on cerr alone |
| `emitMany` | convert | was blocked on cerr alone |
| `emitLeaf` | **done** (round 1) | the proven shape — convertible *because it returns a String* |
| `emitPlan` | convert | emitter-side, no new accessors |

**Five of thirteen do not convert.** That is Ruling 2 paying off, and `dataName` is the worked
example to cite when accessor debt tempts someone toward transcription: a fifteen-arm C++
cascade becomes `dataNames[datA]`, index-aligned, RUN. **Kant is strictly better equipped than
C++ there.**

### `ruleOrRefuse` — the odd sites, surfaced rather than smoothed

All three sites pass `argument.text` — a **runtime string**. **Ruling 2's premise is not
satisfied at any of them as they stand.** But the string's origin is a literal every time:
`genParse('Scaf')`, `dumpRulePlans('Scaf')`, `dumpSpellings('Scaf')`.

**So the runtime-ness is manufactured by the `cmd('Name')` fixture convention.** The dissolve is
real, but its unit of work is: change 3 call sites + ~39 fixture lines from string to bare name,
**measure `aCTionNamE`'s behaviour at top level and inside `code={}` first** (a bare rule name
inside `code={}` may yield an `addGroup` *copy*, and a copy loses `instructType`), decide what
replaces the registry-naming refusal, and **move `census.target`**.

⚠ **That is a foreman/Tony change with a target move in it — NOT a round.** Handing an amnesiac
agent a convention change, an unmeasured hazard, and a moving oracle at once is three variables
where the harness allows one.

**Two things the dissolve destroys; rule on them rather than discover them:** the discriminating
refusal (*"REFUSING X — not a rule; locate finds a non-rule in registry Keywords"*, which caught
a real mis-target), and the `census.target` lines that carry it.

---

## PROPOSED ORDER

| # | method | why here |
|---|---|---|
| 1 | `emitMany` | cerr's arrival is the **entire** unblock; nothing else owed. Byte-exact oracle already pinned (`rung5.target`). Pre-registered in the ledger as preferred |
| 2 | `countRuleTerms` | first walk-side conversion, last with **zero** accessor debt |
| 3 | `printPlan` | **KANT-22 forces this placement** — see the defeated claim |
| 4 | `emitPlan` | after `emitMany` (which it calls) and after recursion is settled. Its refusal is **live on the census**, so KANT-B1 gets forced with a target behind it |
| 5 | `unresolvedTerms` | first rung past the accessor work |
| 6 | `planRule` | needs `isRule` + `binType` |
| 7 | `planTerm` | last by a distance |

**Difficulty cadence:** the measurement ended at round 2 **by choice** (reorder-for-cerr approved
by Tony). Instrument considered proven. Recorded so the ledger's rising-floor argument is not
read as still running. ⚠ **`emitMany` is strictly simpler than `emitLeaf`, so a better score at
position 1 is consistent with the corpus hypothesis and is NOT evidence for it** — the ledger
pre-registered this confound and it stands.

### Two constraints on position 3 that are worth carrying

- **KANT-22's barred shape is `printPlan`'s**, exactly: `deeper` and `kid` are locals read
  *after* a self-call returns. **KANT-8 does not bite** there, because nothing reads the return
  value — which makes it the one safe place to find out whether KANT-6's `EXIT=139` still fires
  at the `runAction` seam.
- **A kant `printPlan` must use `iterate`, never `for`.** `aCTionFOR` advances via
  `GroupItem::next()`, whose shared `entry` state nested calls clobber (`CLAUDE.md`, List
  Navigation). The C++ version uses `nextMember` for precisely this reason. An `iterate` handle
  carries its own cursor.

---

## ⚠ DEFEATED CLAIM — `CLAIM KANT-22`'s scope names the wrong method

KANT-22's scope reads: *"It bars `emitPlan` — which accumulates text across a walk and reads its
accumulator after each recursive call … so it bars STEP 3 OF THE MINION ARC."*

**`emitPlan` has no recursive call.** Two flat `while node = plan.nextMember(node)` loops.
Independently counted by the foreman: `emitPlan` 0 self-calls, `printPlan` 1.
`terms = terms joiner piece` accumulates across a **loop**, which nothing in KANT-5/6/7/8/22
touches.

**The claim is right about the language and wrong about the method.** The barred shape is real
and it lives in `printPlan`, which KANT-22 never mentions. Logged as **defeated** per corpus
rules. Consequence: the carrier discipline is **not owed by `emitPlan`**, and building it there
would be speculative design.

---

## ADVERSARIAL PASS — foreman, against the minion's map

*What I tried to break, and what survived.*

1. **"Is `emitMany` really unblocked?"** — the minion's cerr claim is per-method and I spot-checked
   it: `opCerr` never consults `toBUFFER`, so KANT-12's ordering-across-the-flush hazard genuinely
   does not apply. **Survives.**
2. **"Is the `emitMany` oracle actually safe?"** — the minion flagged its own risk J: `pop.sh`
   captures `genScratch` with `2>&1` and `sed`-extracts a contiguous body, so a stray stdout line
   *inside* the emitted function breaks `rung5.target`. **This is the real risk of position 1 and
   it is an instrument risk, not a language one.** It survives as an open item, and it is cheap to
   check before the round rather than during it.
3. **"Does the `dataName` dissolve actually drop coverage?"** — yes, partially, and the minion said
   so: the kant table has no `d == 0 → "none"` / `d > 14 → "unknown"` sentinels. Both in-scope
   sites are guarded by `if data`, so it is unreachable *there* — but the sentinels are in
   `census.target` via the instrument sites. **Correctly scoped; it is another reason
   `dumpRuleTerms` stays C++.**
4. **"Is retiring `row42`/`foldOf` too aggressive?"** — I checked `foldOf` myself. One caller, an
   instrument, and `planRule` duplicates the test inline instead of calling it. **Survives, and
   it shrinks the accessor debt from blocking five methods to blocking three.**
5. **Where I did NOT take the minion's word:** every row of the grounding table above. The
   `emitPlan` recursion claim in particular was the one most likely to misroute the arc, so it was
   counted independently rather than read.

---

## OPEN, AND WHOSE

**Tony's:** the order (this page's purpose) · whether the `ruleOrRefuse` convention change is
scheduled at all, and what replaces its discriminating refusal · whether `row42`/`foldOf` are
struck from the arc.

**Foreman's, unblocked:** BLOCKER 1's accessor cases (one line each on case 29's model) ·
measuring `aCTionNamE`'s bare-name behaviour inside `code={}` before the convention change is
scheduled · checking `emitMany`'s oracle-capture risk (adversarial item 2).

**Stale record found in passing:** `ruleActions.rtn`'s `aCTionIterate` comment says
*"attributes and members flagged here but not used yet."* They **are** used — `Instruct.rtn`'s
iterate advance reads them. Anyone trusting that comment re-derives KANT-17 the hard way.
