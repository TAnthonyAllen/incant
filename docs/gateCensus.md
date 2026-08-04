# The Gate Census — which methods emit, which execute at emit time

**Written 2026-08-04** as the rider on Clay's degrade-by-default proposal. The proposal:
flip the polarity at the dispatch spine so that under jitting an action **without** an emitter
degrades loudly (counted) instead of executing silently — gates become a whitelist. One change,
and every latent case converts from silent-wrong to counted-visible.

**The caution that kept it a proposal:** some of the effectful column may be the **emit walk's
own machinery**, and degrading those breaks emission itself. This pass decides which.

---

## ⚠ CORRECTION TO THE FIRST COUNT, recorded because the number was reported before it was right

The first pass reported **262 methods, 38 gated, 224 ungated**. Those numbers are **wrong**.
They came from a `sed` extraction that matched prototypes and text inside comments as if they
were definitions, and a gate-detector that only looked 40 lines past each `extern` — so a gate
deeper in a long body read as absent.

Re-derived by splitting each `.rtn` on column-0 `extern` and searching **whole function bodies**:

| | count |
|---|---|
| `aCTion*` / `op*` definitions | **78** |
| gated (`if jitting` anywhere in the body) | **26** |
| ungated | **52** |

The correction matters beyond arithmetic: under the 40-line detector `aCTionTraiTdata` read as
gated and is not, and the ungated list was inflated with names that do not exist as definitions.
**A census is an instrument; this one lied on its first run.**

---

## THE ANSWER: the ungated column is NOT one population

Of the 27 ungated `aCTion*` methods, the large majority are **walk machinery** — they run
*during* emission and are how the IR gets built. Degrading them does not make a latent bug
visible; it stops the compiler.

### A. WALK MACHINERY — ungated BY DESIGN. Name them so, do not degrade them.

**The decisive case, and it is checkable rather than argued: `aCTionExpressioN`.** Its own
header calls it a *"thin dispatcher over two mode-handlers"*, and under jitting it **falls
through to `interpretXP`** — the emission happens one level BELOW it, in `runOP`'s seed gate
(`GroupActions.rtn:729`, `if jitting && (op.isOperator || op.isUnary)`) and in each op-method's
own `if jitting`. So `aCTionExpressioN` is not an un-jitted action; **it is the walk**. That is
exactly the failure mode Clay's caution predicted, confirmed by pointer.

| method | why it is machinery |
|---|---|
| `aCTionExpressioN` | dispatcher; emission happens below it in runOP + op gates |
| `aCTionStatemenT` | the statement walker itself |
| `aCTionXpress`, `aCTionScopeXP`, `aCTionParens`, `aCTionBraced`, `aCTionTokenXP` | expression-tree plumbing that feeds runOP |
| `aCTionNamE` | **builds the frame** — `jitRunAction`'s prologue comment records that a local is *born by being parsed* here |
| `aCTionNumbeR`, `aCTionANYtoken`, `aCTionQuotE`, `aCTionShortcuT`, `aCTionSetBrackets` | leaf/token construction |
| `aCTionDefinE`, `aCTionNewGroup`, `aCTionTraiT`, `aCTionTraiTdata`, `aCTionCodE` | definition-time; they run at parse, not at body execution |
| `aCTionRunRulE`, `aCTionFailed` | parse machinery |
| `aCTionCheckFor`, `aCTionDEBUG` | debug tooling, parse-time by construction |

### B. BODY-REACHABLE CONTENT — degrade by default. This is the real population.

| method | the disease |
|---|---|
| **`aCTionFOR`** | ⚠ **first against the wall.** It is `iterate`'s disease with a different keyword: a loop whose setup runs at emit time. `aCTionIterate` has just been fixed the same way and the fix is a template. |
| `aCTionCouT` | a sink. Same family as `print`, which fired at compile time until today. |
| `aCTionCerR` | ditto — and it is the one genParse's emitters write their product through, so it is not hypothetical. |
| `aCTionSearch` | mutates the search stack; at emit time that mutation lands once, in the wrong era. |
| `aCTionStringXP` | ⚠ **borderline, wants a look before it is degraded.** It produces a VALUE like an expression (machinery-ish) but reaches `appendPrintXP` and `opString` (content-ish). Classify it properly rather than by its neighbours. |

**So the degrade-by-default flip is worth doing, and its blast radius is five methods, not
fifty-two.** That is a much smaller and much more tractable change than the raw census
suggested — and the reason the raw census suggested otherwise is that it counted the compiler
as if it were the program.

---

## THE MECHANISM, and why the whitelist should be explicit

Clay's shape — gates become a whitelist — is right, but the whitelist should be **written down
as a list of names**, not inferred from the presence of `if jitting`. Two reasons:

1. **Presence of a gate is not evidence of coverage.** `aCTionBrancH` is now "gated", but its
   break and return arms only call `jitDegrade` — the gate is a *refusal*, not an emitter.
   A whitelist derived by grepping for gates would count it as covered.
2. **Absence of a gate is not evidence of a bug**, per section A above. A method that is
   machinery needs to say so in one line, at the site, so the next census does not re-litigate
   it and the next flip does not break emission.

**Recommended shape:** machinery methods carry a one-line marker naming them as walk machinery;
everything else degrades by default. The marker is what makes the census cheap to re-run and
impossible to get wrong twice.
