# genParse — Build Ladder & isGROUP Retag (Clod pickup)

```
KIND:       brief
STATUS:     live
DATE:       2026-07-27
COMPANION:  genParseSpec.md — refines §9 Step 3 into staged rungs, and adds
            one row-behaviour to §4.2 (isGROUP leaf: transparent-rule retag)
ANSWERS:    In what order does Clod grow genParse, and what does the leaf
            emitter emit when a rule references a label-transparent rule?
READ-WITH:  genParseSpec §2.4 (label transparency), §2.7 (what genParse
            deletes), §4.2 (leaf emitter), §5.1 (the seven methods), §9 (order)
            wakeup.md Thread 2 (retag bug #2; ruleSTUFF still-open)
GATES:      rungs 9–10 wait on the Xcode resolution of the ruleSTUFF-layer
            fork (which layer the fix lives in). rungs 1–8 do not.
OPEN:       bare-ref-to-alternation: auto-promote, or require explicit `@`?
            → Tony (§8-class)
```

---

## 0. Release note — reconciles clay-to-clod SEQ 14

SEQ 14 held this pending Step 2 going green. Releasing now for two reasons: the
retag half (§2) is bug #2 generalized, so it informs the JSON trace already in
flight; and rungs 1–2 run on a **synthetic scaffold rule**, not the seven JSON
methods, so they are decoupled from the target still being settled. The gating
that mattered is preserved *inside the rungs* — the top rungs (9–10, and "emit
exactly the seven methods") still wait for the target. Nothing here asks anyone
to emit a generator against a method that is still moving.

---

## 1. The ladder

Simplest-first. POP at each rung is a text diff of genParse's emission against a
hand-written target method (§9 Step 3's methodology), so the generator is only
ever trusted against code a human already proved.

| # | rule shape | exercises | emits | gated |
|---|---|---|---|---|
| 1 | single-literal sequence | emitSequence, frame (`label`+`from`), one leaf, `leaveRule` | `leaveRule(into,label,from, lit("x"))` | no |
| 2 | two-literal sequence | the `&&` join | `lit("{") && lit("}")` | no |
| 3 | labelled literal | `litTo`, slot naming | `litTo(label,slot,"x")` | no |
| 4 | group-ref to a **sequence** rule | isGROUP leaf → bare call | `parseR(label)` | no |
| 5 | pure-literal alternation | emitAlternation, `leaveAlt`, `‖` join, no label (§2.4) | `leaveAlt(from, lit("false") ‖ lit("true"))` | no |
| 6 | iteration `*` / `+` | modifier match axis, `many…` helper, mark saved **once** (§2.5, §5.1) | `manyRTerm(label)` helper | no |
| 7 | optional `?` | inline, no helper | `((term) ‖ 1)` | no |
| 8 | guarded member options | guard baked as a literal | `inGuard("{",*atRuleMark) && parseR(into)` | no |
| 9 | group-ref to a **transparent** (alternation) rule | the §2 retag addition below | `promoteR(into)` (retag to slot) | **yes — retag ruling** |
| 10 | tail `code={}` action | `act` tail emission | `&& act(name,label)` | **yes — ruleSTUFF layer** |

**Start:** rung 1 on a synthetic scaffold rule (`Scaf isRule "x"-` or similar),
so the first diff is trivial and the emitter spine is proven before any real
rule. Graduate rungs 2–8 onto JSONblock's already-settled terms (its literals,
`JSONfield*`, the guards) as each lands.

**Top of ladder** = the seven methods of §5.1, POP = the §6.5 tree-diff on
**passing** cases = §9 Step 3. That waits for Step 2 green — i.e. for
`{"a":"b"}` to parse clean.

### Why rungs 9 and 10 are gated

**9 — the retag ruling (Tony).** Bare `parseR` vs `promoteR` for an
alternation callee turns on the open question in §2. Emit rung 9 only once that
is ruled; until then the isGROUP leaf for a transparent callee is the one thing
genParse should not bake.

**10 — the ruleSTUFF layer (Xcode gate).** If the still-open
`ruleSTUFF`-before-the-label-method fix lives in **`act()`** (support library),
rung 10 emits nothing new and the target is settled. If it must live in the
**emitted method body**, rung 10's tail emission grows a line. Same fix,
opposite consequence for the generator — which is exactly what the breakpoint in
`parseJSONfield` on `{"a":"b"}` determines. Do not finalize rung 10 before that.

---

## 2. §4.2 addition — the isGROUP leaf retags a transparent callee

The leaf emitter's isGROUP row branches on the **callee's** shape, which
genParse knows statically at emit time:

- callee is a **sequence** rule → it builds a label tagged with its own name and
  attaches correctly → emit a bare `parseR(...)`.
- callee is an **alternation** rule (label-transparent, §2.4) → the winning
  option's label carries *that option's* tag, not the reference's slot name → to
  be found by slot name it must be retagged → emit `promoteR(...)`.

This is wakeup bug #2 generalized, not a JSONfield special case: `JSONfield`
references `JSONtoken`/`JSONvalue` (both alternations) and needs the retag;
`JSONblock` references `JSONfield` (a sequence) and does not. §2.7 already lists
"retag-to-parent's-ruleName" among the questions genParse answers at generate
time — this pins *when*: **exactly when the callee is label-transparent.**

**Open, Tony's ruling (§8-class).** Should a *bare* reference to an alternation
auto-promote, or should the grammar require an explicit `@`? `JSONitem` writes
`JSONtoken@`; `JSONfield` writes bare `JSONtoken` yet needs identical behaviour.
Until ruled, the safe emission that matches observed-correct behaviour is: retag
whenever the callee is an alternation, and treat an explicit `@` as forcing
promote regardless of callee shape.

---

## 3. Immediate actions

1. **NEXT-0 first — commit Group B before any new code.** Isolate
   `RuleStuff.twk`/`.mm`/`.h` (no Tony content, low-risk), then
   `Commands.rtn`/`GroupRules.h`/`.mm` via the stash-and-splice 0a/0b used.
   Re-verify baseline: `grep -c extern GroupRules.h` = 155, `oneTest` → 26,
   `jsonTest` byte-identical. This protects the invocation-blocker and retag
   fixes from tangling with ladder edits.
2. **Then parallel.** Clod → rungs 1–2 on a synthetic scaffold on the clean
   HEAD. Tony → the Xcode gate (`parseJSONfield` on `{"a":"b"}`), reporting the
   split from SEQ 14 (does `parseJSONtoken(label)` return success with a
   correctly-tagged child, or false?).
3. **Release 9–10** when the §6.5 tree-diff is green on passing cases and the
   ruleSTUFF layer is known.

Deliberately not here: kant emission for the jit target. Unchanged from
genParseSpec §9/§10 — a change of emission, not design, waiting on the JIT
ladder.

— Clay, 2026-07-27
