# C-154 — TRY-AND-BUY: `:=` POINTER-COPY — **STOPPED AT P5, NOTHING EDITED**

**Dispatched by Clay via Tony, run 2026-09-04. Verdict: NO BUY, and no edit was ever made
to the `:=` road.** The stop is not a failure of the proposal — it is the proposal's own
honesty row firing exactly as Clay said it would.

> *"One line for you: P5 is the row that keeps this honest. Without the before-capture, P1
> reading 'source' could be a fixture that was never asking the holder in the first place."*

**P5 fired. On a bare build the fixture was never asking the holder, because on a bare
build there is no holder to ask.**

---

## §1 SURPRISES FIRST

### ⚠⚠ S1 — ON BARE, `:=` ALREADY IS POINTER-COPY. THE EDIT IS A NO-OP THERE.

`opSetGroup` never receives a holder on a bare build. The operand road dereferences one
level *before* the operator is entered, so the semantics C-154 proposes to introduce are
already the semantics bare has — delivered by the auto-unwrap rather than by `opSetGroup`.

Measured directly, by a one-entry directive on `opSetGroup` printing its two operands:

```
bare (gNoUnwrap = 0)
  call  spelling               arg          argBody      argGroup   tgt          tgtBody
  1     pcMid := pcSource      0x1046fafc0  0x1046f5b40  0x3        0x1046f7000  0x1046f5820
  2     pcTop := pcMid         0x1046fafc0  0x1046f5b40  0x3        0x1046fa600  0x1046f56e0
  3     pcArg := argument      0x1046fdb80  0x1046f5b40  0x3        0x1046fd540  0x1046f55a0
```

**Call 2 is the whole finding.** Its RHS is written `pcMid` — the node call 1 had just made
a holder, whose own body is `0x1046f5820`. It arrives at `opSetGroup` with
`argBody = 0x1046f5b40`, which is **`pcSource`'s body**, and with the very same node pointer
as call 1's argument. The holder was unwrapped before the operator saw it.

**All three calls carry the same `argBody`.** There is no reading of any of them in which a
holder reached `opSetGroup`.

So step 2's precondition — *"when the RHS is a holder (isGROUP set, gGroup non-null)"* — is
**unreachable on bare**, and steps 3–5 are vacuous by construction: P1 would read `source`
before the edit and `source` after it, which is not a delta but a description.

### ⚠⚠ S2 — THE STROKE'S ARMS ARE INVERTED. THE HOLDER EXISTS ONLY UNDER THE FLIP.

Same probe, same instrument, one build apart:

```
flip (gNoUnwrap = 1)
  call  spelling               arg          argBody      argGroup      tgt          tgtBody
  1     pcMid := pcSource      0x1031aafc0  0x1031a5b40  0x3           0x1031a7000  0x1031a5820
  2     pcTop := pcMid         0x1031aa5c0  0x1031a5820  0x1031aafc0   0x1031aa600  0x1031a56e0
  3     pcArg := argument      0x1031ad500  0x1031a5370  0x1031adb80   0x1031ad540  0x1031a55a0
```

**Call 2 now carries `argBody = 0x1031a5820` — `pcMid`'s own body — and
`argGroup = 0x1031aafc0`, which is call 1's argument, i.e. `pcSource`.** The holder arrives
intact, one level of indirection visible in the operand itself. That is precisely the
condition C-154's edit is written against.

**So the edit belongs in Arm B, not on bare.** The charter puts the rows and the fleet on
bare and the flip last; the mechanism is the other way round. This is a sequencing finding,
not a refutation of the proposal — the proposal is coherent, it is simply aimed at a state
that only the flip produces.

⚠ **This also re-reads the 09-03 citation the dispatch rests on.** *"Measured 09-03: field
#5, body #4"* is a **flip-ON** measurement — `docs/wakeup.md:279-280` records it inside a
block that opens *"In `runAction` under `gNoUnwrap`"*, and the seal's own §2 states the
identity convention as *"under `gNoUnwrap=1`, identity by `addrOf`'s **body** column."* The
citation is accurate; what travelled without its arm label was the **conditions**, and the
dispatch then assigned the rows to the arm where the phenomenon does not exist.

### ⚠⚠ S3 — `gGroup` READS `0x3` ON A NON-HOLDER. STEP 2's GUARD AS WRITTEN WOULD CRASH.

Every bare call above shows `argGroup = 0x3`. That is not a pointer — `GroupBody` is a
union, and on a field whose data is not a group the slot reads back as a small integer.

**Step 2 specifies the guard as `isGROUP set, gGroup non-null`. The conjunction is right and
either half alone is fatal:** `gGroup non-null` is TRUE on every plain string field in the
system, and following it dereferences `0x3`.

**This was not reasoned — it was paid for.** The first two instrumented builds printed
`argument->groupBody->gGroup->groupBody->tag` behind a `gGroup` null-check and died at
**exit 139 with no output**, twice. The third, reduced to raw pointers, ran clean and showed
why. **Any future build of this edit must test `data == isGROUP`, never the pointer.**

### S4 — THE IDENTITY CURRENCY: THE FIELD COLUMN IS NOT STABLE ON BARE

The dispatch says *"read the field column, the body column cannot discriminate a holder from
what it holds (C18)."* On bare, `addrOf` on one field, twice in a row, reads **`field=#1`
then `field=#3`** over a stable `body=#2` — a fresh wrapper node per read, which is incant
field semantics working as designed. `pointerT`'s own row L4 says the opposite of the
dispatch in as many words: *"Read the BODY column only … body must REPEAT (column is
stable)."*

Both are right about their own arm. **C18's warning holds where a holder and its target
share a body; it does not hold here, because a holder has its own body** — which is exactly
what makes `argBody` the discriminator in S1 and S2. The disagreement is worth settling
before the next identity row is written, because two seats currently have opposite rules.

### S5 — AN UNEXPLAINED READING, RECORDED WITHOUT A MECHANISM

Under the flip, `print pcTop` after `pcTop := pcMid` prints **`pcSource`**, where
print-does-not-follow (F-49) predicts the tag of what `pcTop` holds, i.e. `pcMid`. The
sibling row B2 fits the law perfectly (`print pcArg` after `pcArg := argument` prints
`pcSource`, which is the callee argument's tag). **A2 does not.** Reproduction proves the
symptom, never the cause; no mechanism is offered and none was guessed at.

---

## §2 THE FIVE ROWS

| row | spelling | predicted | read | verdict |
|---|---|---|---|---|
| **P5** control, HEAD | `arg := argument` in an action | reads the **holder** | **reads the SOURCE.** `argBody` = `pcSource`'s body on all three `:=` calls; the RHS is unwrapped before `opSetGroup` | ⚠ **OFF PREDICTION — stop clause** |
| **P1** | same, after the edit | field column reads the source, not the holder | **not run** — P5 voided it. The treatment's precondition is unreachable on bare, so P1 and P5 would read identically and the row could not be a delta | **VOID, not failed** |
| **P2** control | `x := y`, `y` bare | byte-identical to HEAD | **not run** (no edit) | not reached |
| **P3** anti-vacuity | holder-of-a-holder | reaches the middle | **not run.** The two-deep chain WAS built (`pcSource` ← `pcMid` ← `pcTop`) and is what proved S1 | not reached |
| **P4** negative | refused operand | refuses as HEAD | **not run** (no edit) | not reached |

⚠ **P1 is recorded VOID rather than FAILED, per the standing third-outcome rule** (2026-08-10:
*"the treatment voids the control"*). Its discriminator does not exist in the arm it was
scheduled in. A two-outcome row has nowhere to put that, which is the pressure the rule
exists to name.

## §3 STEP 4 — RECORDED, NOT GRADED

`*x` on a holder, bare: **`ERROR unary * on pcSource -- it holds no group`**, and `addrOf` of
the star's result yields a fresh node (`field=#4 body=#5`). The star refuses because its
operand was already unwrapped — 09-03 seal (b), reproduced here independently.

`print` of a two-deep chain: bare `SRC` (the value); flip `pcSource` (a tag). No verdict.

## §4 STEP 5 — FLEET

Not applicable as a treatment measurement: **no edit was made**, so there is no moved-row
set. Run anyway as the revert's certificate — see §5.

## §5 STEP 6 / ARM B — WHAT WAS AND WAS NOT MEASURED

**Arm B was built and run, for the PREMISE only.** Its exact operand readings are the flip
table in S2. That is the measurement that told us where the holder lives.

**The asking was NOT re-run, and its stderr line is not in this report.** Step 6's prediction
— that `setParse: ERROR field passed in argument has no rStuff` goes away — is a prediction
about **the edit's effect**. There is no edit. Re-running the asking would have reproduced
the known 09-02 state and nothing more, at the cost of another build, and reporting it under
a step-6 heading would have dressed an unchanged reading as a result. **`carrierNode` does
not discharge here, exactly as the dispatch said.**

## §6 THE REVERT, md5-VERIFIED

```
jitContext.h:619   static int gNoUnwrap = 0;      restored
groupDirectives    md5 7ae5e649ebdcf8276fc89b6ba186637a   restored to the C-155 culled state
incant/probeA      removed
bare retok x4      canary 332
md5 of all 8 generated files vs pre-stroke   IDENTICAL
bare rebuild       BUILD SUCCEEDED
flip down          verified BEHAVIOURALLY, not by mtime: two-deep chain prints SRC
probe strings      strings ~/bin/incant | grep -c OPSETGROUP  =  0
pop.sh             191 green / 1 parked / 3 pinned red -- row-for-row BYTE-IDENTICAL to the
                   pre-stroke capture
frontier           exit 0, 10 PASS
git status         clean but for IncantForms/WorkingOn/parser
```

## §7 ⚠ ONE DEVIATION, FLAGGED BEFORE ANY WORK

The dispatch names branch `tryAndBuy-gNoUnwrap`. **That branch is 19 commits stale** (base
`96cff77`, 2026-09-02) **and its single commit `e27c407` sets `gNoUnwrap = 1`.** Steps 1–5
require a bare base at today's numbers — canary 332, fleet 191/1/3 — which it is neither.
Bringing it current would mean rewriting or merging a branch the 09-02 seal cites, which is
not Clod's to do on its own judgment (bear-trap #21). **No branch was cut in the end, because
no edit was made.** The branch question returns to Tony with the stroke.

## §8 WHAT THIS LEAVES, AND THE SHAPE THE NEXT ATTEMPT WANTS

The proposal is **not refuted**. It is aimed at a state that only the flip produces, and it
was scheduled against the arm where that state is absent. A re-run wants three changes:

1. **Rows and fleet in Arm B**, with bare as the control that must NOT move — the inverse of
   the current assignment. On bare the edit is provably inert, which makes "bare unmoved" a
   real and cheap negative control rather than a vacuous one.
2. **The guard is `data == isGROUP`, never `gGroup != 0`** (S3). Two crashes bought this.
3. **Identity by the BODY column** on both arms (S4), with the field column recorded but not
   graded, because it mints a fresh node per read.

⚠ **And one question that must be answered before any edit, because it may dissolve the
stroke:** if bare already delivers pointer-copy through the auto-unwrap, and the flip's whole
purpose is to retire the auto-unwrap, then **is `opSetGroup` the right place at all — or is
the flip simply owed the one-level deref that the auto-unwrap used to provide, at the
operand road, for every operator rather than for `:=` alone?** S1 says the two roads
currently disagree about `:=`; it does not say which one is right.

---

## §9 CLOSEOUT — RULED 2026-09-04 (Tony, on Clay's rulings 1 and 3)

**`:=` DOES NOT DEREF.** The operator keeps the semantics it has: it stores what it is
handed, through `setGroup`, one spelling, and it does not reach through a holder to what the
holder points at. The one-level deref proposed by C-154 is **not** added to `opSetGroup`.

**THE SPELLING UNDER THE FLIP IS STAR EVERY USE.** Where a holder must be reached, the star
says so at the site that means it, rather than an operator doing it silently on the reader's
behalf. This is the same ruling as the 09-02 respell (*"`<-` MINTS A COPY AND IS NOT AN
ALIAS"*) arriving at `:=` — and it keeps the one-star law S3a intact instead of minting a
second, invisible dereference with different rules.

**C-154 IS CLOSED: REFUSED BY MEASUREMENT.** Not abandoned, not parked, not deferred to a
better day — the stroke ran, the premise was measured, and the measurement refused it. §1's
three surprises are the record of why, and they stand as findings whatever anyone later
decides about the flip.

⚠ **AND THE STROKE PAID FOR ITSELF TWICE OVER, WHICH IS THE ARGUMENT FOR RUNNING RECON
BEFORE EDITS RATHER THAN ALONGSIDE THEM.** A stroke that edited first would have landed a
crash (§1 S3's `gGroup == 0x3`) behind rows that could not have caught it (§1 S1: P1 and P5
read identically on bare), and would have reported a green fleet while asserting nothing.
**The two outputs that outlived the proposal are `RULE H13` — an identity row names its
question before it names its column — and the ruling above.**

**Branch:** `tryAndBuy-gNoUnwrap` retired the same day, dated in the 09-02 seal's own line
and **not deleted**. Future try-and-buy branches are cut from `main` per stroke, so a branch
is never older than the question it answers.
