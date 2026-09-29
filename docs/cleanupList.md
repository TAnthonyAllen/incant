# Cleanup list

A standing list of cruft spotted mid-stroke (Tony, 2026-09-28). **When you spot cruft, add an entry and keep going; don't act on it in flight.** Tony decides the cuts, one cleanup pass at a time. A cut that lands moves its entry to **Done**, with the commit.

Each entry: **what and where** (file:line) · **why it looks deletable** · **the census or measurement that would confirm it** · **seen** (date).

## Open

### `labelMinters`
- **What/where:** `measure.twk:279` (`extern int labelMinters(GroupItem rule)`), declared in `measure.h`; also a DesignDocs slug (`TokFiles -> Generate -> labelMinters`).
- **Why deletable:** no caller. Only its definition and declaration reference it in tok, C++ or incant, and `incant/setup` does not register it as a command.
- **Confirm:** a `grep -rn 'labelMinters('` over `*.twk *.rtn *.mm` (definition only) plus a check that no incant file calls it. F-O35's skip census found its 0 skips were vacuous: empty population, not measurement (`objectModel.md` F-O35). **Canary cost:** `measure.h` 42 -> 41.
- **Seen:** 2026-09-28.

### `allAttributesOptional()`
- **What/where:** `GroupItem.twk:184`, declared in `GroupItem.h:46`.
- **Why deletable:** no caller. Its only caller was the parent-`min` promotion, retired 2026-09-03 by measurement (SEQ 152). DesignDocs `promotionRetired` records that it was "left callerless, deliberately".
- **Confirm:** a `grep -rn 'allAttributesOptional()'` over `*.twk *.rtn *.mm` (definition only), then a retok with a byte-identical diff apart from the method, and the fleet unmoved. Its DesignDocs entry and the CLAUDE.md census example (comment convention) cite it and would need a note.
- **Seen:** 2026-09-28 (first noted callerless in the 2026-09-03 wakeup).

### `testAttributes`' artifact skip
- **What/where:** `RuleStuff.twk:269`, `if noPrint continue;` in `testAttributes` (old road).
- **Why deletable:** after stroke 3, artifacts should not be on term lists.
- **Blocked on F-O38.** Measured 2026-09-28: it still skips `pendingParseR` 29,260 times across the fleet, because the kant generator attaches the pending carrier with `+%` (among the terms), and `compile` only moves it when it reaches that rule.
- **Confirm:** once F-O38 is fixed, re-run the F-O35 skip log. This site must read 0 skips with arrivals present, and the fleet must be unmoved.
- **Seen:** 2026-09-28.
- **Re-measured 2026-09-29 (SEQ 224, F-O38 closed by `+<`):** pendingParseR 30,208 -> **0**. But the site still skips **120 locals** -- `this` 60 and `tempField` 60, on coded rules (JSONfield 42+42, JSONarray 9+9, ScafA 4+4, list 3+3, ask 2+2). **So it is NOT deletable as it stands:** it has become a LOCAL skipper, the same class as `setParseWalk`, `compile` x2 and `dupTermRefusal`, which stay by ruling. Leave the entry for Tony to strike or keep.

### `compile`'s pending-carrier re-filing block
- **What/where:** `Commands.rtn:56-68` (`pendingToProperties`): moves a `pendingParseR` carrier found among a rule's terms to its property list, and its `CodE` likewise.
- **Why deletable:** the only writer of the carrier, `IncantForms/WorkingOn/parser:43-44`, now files both with `+<` (SEQ 224), so the carrier should always arrive on the property list and neither move should fire.
- **Confirm:** a temporary log on each move's body across the full checklist (pop.sh, jitLadder, printPop, decodePop, ddPop, countPop, frontier) must read 0 with the enclosing `if pending` arrivals present, then removal with the fleet row for row. **Not measured yet.**
- **Seen:** 2026-09-29.

## Seeded, already gone

Seeded 2026-09-28 from the dispatch. A source census shows each was already deleted, so there is nothing to cut.

| item | deleted in | census |
|---|---|---|
| F-56's `fireNewParse` (`Commands.rtn`) | `1dd73d6` -- Tier 1 of the parseMethod= deletion (SEQ 188) | 0 references in `*.twk *.rtn *.h`; only docs and the channel mention it |
| `parseGeneric` (`RuleStuff.twk`) | `2bfa808` -- Task 2 (SEQ 192) | 0 references in `*.twk *.rtn *.h` |

## Done

*(none yet)*
