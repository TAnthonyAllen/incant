# BRIEF — the `jitter` command

**QUEUED BEHIND STEP 2'S PATHFINDER. ⚠ DO NOT START BEFORE `processJit(field)` EXISTS.**
Relayed by Tony via Fearless, 2026-08-17. Deliberately thin: `processJit`'s real shape belongs to
step 2, and this brief must not pre-decide it.

## WHAT IT IS

The exact twin of `compile`, one door over.

| command | runs |
|---|---|
| `compile(field)` | `processCode(field)` — landed `62deb33` |
| `jitter(field)` | `processJit(field)` — this brief |

It falls out of the jit separation nearly for free, which is the whole reason it is worth writing.

## THE TWO EDITS, mirroring the `compile` trio

1. **`Commands.rtn`** — `extern GroupItem jitter(GroupItem field)` → `processJit(field)`.
2. **`incant/setup`** — `jitter immediateAction;` in `cOMMANDs`, **beside `compile`**.

⚠ **Check the return type against `processJit`'s actual signature before writing the body.**
`compile` shipped with exactly this bug: `processCode` returns `int`, the command was written
`return processCode(field);`, and it would not compile (`cannot initialize return object of type
'GroupItem *' with an rvalue of type 'int'`). The landed shape preserves the failure signal and
returns the field:

```
    if !processCode(field)  return 0;
    return field;
```

If `processJit` also returns a flag, **copy that shape**. It matches `cLEAR` and `cOPY` either
side of it in the same file.

## ⚠ CONTRACT — EMIT WITHOUT RUN

`jitter(field)` **emits and installs** the compiled body on the field's slot. **It does not fire
the action.**

Emit-without-run is the command's entire reason to exist. **If it fires the body as a side effect
it is just a slower run.**

⚠ **If step 2's landed shape makes emit-without-run awkward, STOP AND SAY SO** rather than bending
the contract. That would be **a finding about the separation**, not about this command.

## REFUSAL POSTURE — inherited, not invented

A field whose body contains a non-emittable construct **refuses by name at emit**, per the KE-4
ruling and the standing rule: **refusal, never fold, never a silent delegate.** The degrade counter
is where it shows up.

## POP — fire-twice discipline, as everywhere

**Fixture:**
1. `jitter` the field.
2. **Change the input after**, then fire; assert the value **tracks the change** — that proves
   compiled code answered, not an emit-time side effect.
3. Second leg: fire again on a **second** input change, **with no re-jitter**.

**Negative control (H7):** jitter a field carrying a **known-refused** construct and assert the
refusal line **by name**.

**Sentinel as the last line, asserted first** (H2).

## NOT IN SCOPE

No sweep of other ops. No changes to the fork. No touching `compile`.
**One command, two files, one fixture.**

## AMENDMENT RULE

If the pathfinder changes `processJit`'s signature, **this brief amends in one line** rather than
being rewritten. That is why it is thin.
