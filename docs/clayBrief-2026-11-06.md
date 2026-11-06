# Morning summary for Clay, 2026-11-06 (Tony and Clod, before waking you)

**One plain line: kant has a new value scope, `=:`, and a number compared with a string no longer compares against the string's length; both are on trunk, nothing is broken, and the morning docket is unchanged and ready.**

Seal 347. Trunk `jit-unified-emit-wip` = main, merge `b57ae3d7`. These rulings carry no SEQ number; assign them if you want them on the ledger.

## Why this came up

Tony's offline work on `setFrame` hit a pain: `:grup width;` makes the local a holder of grup's width when it exists and clears the local when it does not, so every use needed `isGrouP` tests and stars. He proposed changing `aCTionScopeXP` to give locals values. A census showed 14 of the 26 live scope statements outside `tester` need the holder: all 11 in `kantGrammar`, which read a label's children through it, and all 3 in `directives`, whose `source -= *fromThis` must edit the real source. So the value form became a second spelling.

## Rulings (Tony, 2026-11-06)

1. **A separate spelling for a value scope; `:` stays the holder form, untouched.** Spelled `=:grup width height;` (`:=` holds, `=` copies).
2. **A bare flag reads as 1 under `=:`, implicitly, so a bare `across` is `across=1` and no form needs editing.** This is inside `=:` only; the define parse is unchanged.
3. **`=:` on a field holding a group warns by name and leaves the local empty.** Tony's concern: a user may not know which scope to choose. The warning reads `WARNING =: height in svHeld holds a group -- use : for this field`.
4. **A number against a non-numeric string has no order: `==`, `<`, `<=`, `>`, `>=` read false, `!=` reads true, and it warns.**
5. **A string that is a number in full compares by value, and it warns.** Tony: a string as a number "should not happen often (or never intentionally if I am writing the code)".
6. **Rulings 4 and 5 narrow SEQ 347 R3 and SEQ 417 for compares only.** Arithmetic and `getNumber` still read a string as its length.
7. **`SCOPEVAl`, a first-cut rule in `kantGrammar`, came out before the merge.** Action bodies parse on the old grammar, so nothing had reached it.

## New on the macros feature list (`IncantForms/WorkingOn/macros`)

The list is now split into MORNING SESSION and AFTERNOON SESSION, FORMS, as Tony asked. A third section, ADDED 2026-11-06, ON NO ORDER, holds these:

- **WARNINGS NEED AN ON/OFF SWITCH. YOURS TO WEIGH IN ON, Tony's request.** The question is granularity: all warnings, or only those on some methods or actions. Two warnings exist now and neither can be turned off. A worked example: a form with a bare `across` warns on every `setFrame`, because `fillDownAcross` asks `direct == "*"` on purpose.
- **A CAST. FOR YOU.** To keep a string's length as its number useful, Tony wants kant to have an equivalent of a C++ cast, so the reading is asked for. No design yet. SEQ 347's "cast rule" is about storing into a typed target, which is not this, and `macros` records "no cast operator" today.
- **Kant compares are a continuing issue.** Tony's example: `!across` is not the same as `across.datA == 1` in an if statement. His words, not measured here.
- **`printDefinition` is due for a rewrite.** Measured: after `down=3` each member holds its frame (`dumpContents` length 4) and `printDefinition` prints it bare.
- `=:` and the compare are listed there as done.

Parked last night and still on the list: `fillDownAcross` with both `down` and `across` (hard part, do later), and errors pointing better at their line (another day).

## State of setFrame

The `tester` draft is on `=:`. Its `isGrouP` branches are gone and Tony's `somple` output is unchanged line for line. Driven on scratch copies of `tester`:

| shape | holder version | `=:` version |
|---|---|---|
| `down=*` | right | identical |
| `across=*` | not run | right |
| nested `down=2` holding `across=*` | not run | right |
| bare `across`, two members | both at x=100, plus errors | x=100 and x=200, right |
| `down=3` | exit 139 | runs; frames are there, `printDefinition` hides them |

Not done: it is not copied back to `utilities` (Tony's draft is unfinished, and the unblessed `testSetFrame` row reads the old one). Tony's two `isPercenT` lines are out of the draft, because a local copy does not carry that bit; they return with the % stroke, which is still open and waiting on his ruling.

## What a future reader should not trip on

- **`processCode` always parses an action body with `grokking/BlocK`, the old grammar**, whatever the search list says. So `=:` exists on the old road only (`ScopeValue` in `incant/grammar`). When bodies move to the new road, `kantGrammar` needs the rule back, and its `STATEMENt` guard has not been shown to admit it.
- **`=:` copies, so writing the local writes only the local.** Writing back is `*grup :% copyOf(width);`, as `setFrame` does.
- **A present field with no data and a bare flag both read 1**, including a member that merely has children.

## Certificate

New fixtures: `incant/pop/scopeValueT`, `compareMixT`, `compareMixCompT`, 27 new rows. Each mechanism's H7 went red with restore md5-identical. Before building, a temporary tap over pop.sh, jitLadder, printPop, decodePop, ddPop, frontier and `tester` logged one mixed compare, in `kantGrammar`, which reads the same before and after. Unread: 229 compares against quoted non-digit strings in actions no fixture runs. Fourteen rule-count rows re-pinned on one sentence: `ScopeValue` is one more grammar rule.

On merged trunk: pop.sh exit 1, 2628 green, the same 63 FAIL rows by name · jitLadder 224 / 0 · printPop 0 · decodePop = capture but its binary echo · ddPop 5 / 1 (standing) · frontier = capture · bare tokall = committed · canary 435 · all repos clean and pushed.

## The morning docket, unchanged

1. R1's cure: after a refusal the new road ends the action. 2. S6 (call). 3. M3: no colour cache, the held-field reader, the 32 bytes. 4. The unknown-flag refusal, recon first.

## What Tony asks of you

The granularity of the warning switch, and the shape of the cast.
