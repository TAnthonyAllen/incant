# A refusal's scope is the statement

**Ruled by Tony, 2026-09-17.** This file is the argument; the code carries one-line stump
markers pointing here.

## The rule

`aCTionStatemenT` clears `ruler.refused` on the way out of **every** statement — whether or not
a method ran, because the refusal may have been raised during the **match** and never reached a
method at all.

`clearRefusal` is the **single writer of the 0**, as `refuse()` is the single writer of the 1.
`aCTionDefinE`'s `refusalBoundary` and `runAction`'s refusalArm both route through it.

**`stop()` and `bail()` work as intended, always. Not working is not an option.**

## What it replaced, and why the replacement was needed

Before it, the only clearers were `aCTionDefinE`'s boundary and `runAction`. A refusal raised at
statement level reached neither, so it stood — and an outstanding refusal **silences action and
command dispatch**. `stop()` is a command. It was never entered, the parse never terminated, and
the region below it was parsed as ordinary source. `incant/pop/trigDO` sat that way with 425
lines of prose under its `stop()`, reporting `RunRulE: expected a method not THE / NEW / PARSE /
FIRES` — words out of that prose — at exit 0.

⚠ **The failure was the opposite of what "parse-dead" protects against: MORE was parsed, not
less.** Every unmatched brace and unterminated literal in a dead region was live source the
moment a refusal stood.

## What the ruling retired

A precondition on the parse-dead guarantee, written into `CLAUDE.md` on 2026-09-17 and **taken
back out the same day**. Tony's words: *a precondition that no longer holds is a stump marker for
a stump that has been pulled.* It is recorded here and nowhere else, because a live doctrine file
should not carry a caveat that is false.

## Two things measurement changed about the diagnosis

**1. `reportRunAbandoned` has no reachable case left.** It was built the day before to name the
silent abandonment. Five shapes were tried after the boundary landed — refusal mid-file, as the
final statement, inside a define as the final statement, in the last field of the last define,
and `abandonT`'s original shape — and **every one is cleared at a statement boundary, reading
`refused=0` at main's tail.** It stands as a **net**, not a live path. `abandonT` AB-5 pins it at
zero and is never read without AB-4, because a zero is exactly what a removed reporter produces.

**2. The define-case truncation was never the flag.** A refusal inside a `define` block still
truncates the file — and with the boundary in place **the run reaches main reading `refused=0`
and truncates anyway.** So it is the failed **match** abandoning the parse: ordinary
parse-failure truncation, which is its own documented behaviour. `docs/fixIts.md` F-79 carries
it. ⚠ **This corrects F-76's own diagnosis**, which read the two as one mechanism because before
the boundary both were true at once.

## The fixtures

| fixture | pins |
|---|---|
| `incant/pop/abandonT` | the scope itself — AB-1's count **flipped 1 → 2**, which is the whole assertion. It uses a **bare statement, never a define**, so it cannot accidentally measure F-79 instead. |
| `incant/pop/stopPreT` | `stop()` fires with a refusal standing. SP-2 flipped from a red-shaped pin to an absence, read with **two** positives: SP-1 (execution continued at all) and SP-3 (the stop actually fired rather than the file merely ending). |
| `incant/pop/argRetiredT` | unmoved — the define boundary still reports and removes, and `AR BEFORE`/`AR AFTER` still run. |
