# Compare-family null-data guard recon (2026-06-30)

Assessment-only recon parked by Fearless. No code was changed; nothing was
built or run. Scope: `Instruct.rtn`'s compare-family operator methods
(opEQ, opNE/opNotEQ, opGE, opGT, opLE, opLT, opIN), auditing each for parity
with opEQ's two null-data guards.

## TL;DR

- **4 of 6 numeric compare ops need the guard**: opGE, opGT, opLE, opLT have
  **zero** null-data guards. Only opEQ and opNotEQ (`!=`) have them.
- **opNE already has the guard** — it was done alongside opEQ, not left
  behind. `opNotEQ` (Instruct.rtn:452-465) mirrors opEQ's two-branch guard
  exactly (inverted sense: `gCount != 0` instead of `== 0`).
- The failure mode for the unguarded four is **not a crash** — `compareValues`
  (GroupItem.mm:93) has its own internal null-safety for `GroupItem*` being
  null, and `getText()`/`getCount()` degrade gracefully (tag-string fallback,
  or 0) rather than dereferencing null. The real bug is **silently wrong
  compare results**: when an operand has no `data` set, `compareValues`
  either hardcodes `-1` (treats the no-data side as unconditionally "less
  than", regardless of the other operand's actual value) or falls back to a
  meaningless text/tag-string compare. This means opLT/opLE can silently
  return **true** and opGT/opGE can silently return **false** for a
  null-data operand regardless of what the other operand's real value is —
  the answer doesn't depend on the value at all, which is the "garbage
  compare" failure mode.

## Background: how opEQ's guard actually works

```
Instruct.rtn:155-168
extern GroupItem opEQ(GroupItem argument,GroupItem target)
{
    if jitting {
        -% return jitEmitCompare(argument, target, jitEQ); %-
    }
    if target && !data {
        if argument.isCOUNT || argument.isNUMBER
            if argument.gCount == 0     return trueResult; }
    or argument && !argument.data {
        if isCOUNT || isNUMBER
            if gCount == 0              return trueResult; }
    or !compareValues(target,argument)  return trueResult;
    return null;
}
```

Two things matter about the control flow, established by reading the
surrounding `if/or` idiom as an if/else-if chain (confirmed by the fact that
the three branches are mutually exclusive conditions over the same two
operands):

1. **Bare unqualified fields in the method body resolve to `target`** (the
   second parameter). So `!data` in branch 1 means `!target.data`, and the
   bare `isCOUNT || isNUMBER` / `gCount == 0` in branch 2 mean
   `target.isCOUNT || target.isNUMBER` / `target.gCount == 0`.
2. **The chain short-circuits like else-if.** If branch 1's condition
   (`target && !data`) is true, only branch 1 runs — branches 2 and 3 (the
   `compareValues` fallback) are **skipped entirely**, even if branch 1's
   inner `if` doesn't fire a `return`. So whenever either operand lacks
   `data`, `compareValues` is **never called** — it's fully bypassed in
   favor of the explicit zero-as-null semantics. `compareValues` (and its
   buggy no-data fallback behavior, see below) only ever runs when **both**
   operands actually have `data`.

This is the key structural fact the audit turns on: opEQ/opNotEQ don't just
patch a wrong answer after the fact — they preempt the call to
`compareValues` altogether when a guard condition matches. opGE/opGT/opLE/
opLT have no such preemption, so they fall straight into `compareValues`'s
no-data fallback path.

### Why `compareValues`'s no-data fallback is wrong, mechanically

`compareValues` (GroupItem.mm:93-134):

```cpp
int compareValues(GroupItem *group1, GroupItem *group2)
{
int 	result = -1;
	if ( group1 && !group2 )          result = 1;
	else if ( group2 && !group1 )      result = -1;
	else if ( group1->groupBody == group2->groupBody )  result = 0;
	else if ( group1->groupBody->flags.data )
		switch (group1->groupBody->flags.data) { ... }
	else if ( group2->groupBody->flags.data )
		result = -1;
	else	result = ::compare(group1->getText(),group2->getText());
	return result;
}
```

- If `target` (group1) has **no** `data` and `argument` (group2) **does**:
  falls to `else if (group2->...flags.data) result = -1;` — a **hardcoded**
  -1, independent of argument's actual value. `getCount()`/`getText()` are
  never consulted on this path.
- If `target` **has** data and `argument` has **none**: the switch runs on
  `group1`'s type; most cases guard on `isCOUNT(group2)||isNUMBER(group2)`
  before using `group2`'s value, and that guard is false when `argument` has
  no data — so most numeric cases (9, 5) fall through with `result`
  unchanged from the initial `-1`. The string/token cases (4/13/14) instead
  do `::compare(group1->getText(), group2->getText())`, and `getText()`
  (GroupItem.mm:923-977) on a no-data item falls back to returning
  `groupBody->tag` (the field's name) — so this is a **string compare of
  target's real value against argument's tag name**, semantically
  meaningless.
- If **both** lack data: falls to the final `::compare(getText(),getText())`
  — i.e. a tag-name vs tag-name string compare, also meaningless as a value
  comparison.

In every one of these no-data paths, `getCount()` (GroupItem.mm:623-637) —
which *would* safely return 0 for a no-data item — is never reached, because
the dispatch never gets that far. So the bug isn't a null-deref; it's that
the codepaths these four ops fall into don't implement the "no data == count
0" convention at all. They implement something else (a hardcoded "first
operand without data sorts first" rule, or a tag-name string compare),
which happens to agree with the count-0 convention only by accident.

## Verdict table

| op | has guard? (Instruct.rtn:line) | failure mode if missing | correct null-data semantic (null treated as count 0, per opEQ's convention) | verdict |
|---|---|---|---|---|
| **opEQ** (`==`) | **Yes**, both branches — Instruct.rtn:160-165 (`target && !data` → `argument.gCount==0` ⇒ true; `argument && !argument.data` → `gCount==0` ⇒ true) | N/A — reference implementation | target-or-argument-null ⇒ true iff the other side's count is 0 | already covered |
| **opNE** (`!=`, fn name `opNotEQ`) | **Yes**, both branches — Instruct.rtn:457-462 (mirrors opEQ inverted: `argument.gCount!=0` ⇒ true; `gCount!=0` ⇒ true) | N/A | target-or-argument-null ⇒ true iff the other side's count is **non**-0 | already covered |
| **opLT** (`<`) | **No** — Instruct.rtn:293-300, only `if compareValues(target,argument) < 0 return trueResult;`, no `!data` checks anywhere | Falls into `compareValues`'s no-data path (see mechanism above): if `target` lacks data, result is hardcoded `-1` ⇒ `opLT` **silently returns true regardless of argument's actual value** (even if argument is 0 or negative, where null=0 is *not* `<` it). If `argument` lacks data, numeric cases fall through with `result` left at -1 too ⇒ same silent-true bug; only the string/token cases do a meaningless tag-name compare instead. | `target` null ⇒ true iff `argument` (numeric) `> 0`; `argument` null ⇒ true iff `target` (numeric) `< 0` | needs guard |
| **opGT** (`>`) | **No** — Instruct.rtn:231-238 | Same `compareValues` fallback hardcodes/leaves `result=-1`, which never satisfies `> 0` ⇒ `opGT` **silently returns false (null) regardless of actual value** whenever an operand lacks data — including cases where null=0 genuinely *is* greater than the other (e.g. argument negative). | `target` null ⇒ true iff `argument < 0`; `argument` null ⇒ true iff `target > 0` | needs guard |
| **opLE** (`<=`) | **No** — Instruct.rtn:281-288 | Same fallback: result effectively `-1` (or meaningless text compare) which always satisfies `<= 0` for the hardcoded-`-1` paths ⇒ `opLE` **silently returns true regardless of actual value** whenever target lacks data — wrong whenever argument is negative (where null=0 is *not* `<=` a negative number). | `target` null ⇒ true iff `argument >= 0`; `argument` null ⇒ true iff `target <= 0` | needs guard |
| **opGE** (`>=`) | **No** — Instruct.rtn:219-226 | Same fallback never satisfies `>= 0` from a bare `-1` ⇒ `opGE` **silently returns false (null) regardless of actual value** whenever an operand lacks data — wrong whenever the null side's "true" 0 value should compare `>=`. | `target` null ⇒ true iff `argument <= 0`; `argument` null ⇒ true iff `target >= 0` | needs guard |
| **opIN** (`IN`, Instruct.rtn:249-267) | N/A | N/A — opIN is set-membership / substring-find (`PLGset.foundIn`/`.contains`, buffer substring search, or `groupList[tag]` lookup), not a numeric ordering compare. No `compareValues` call, no shared failure mode with the others. | N/A | N/A (not a numeric compare) |

No other compare-family ops were found in `Instruct.rtn` (no spaceship/`<=>`
operator, no differently-spelled LT/GT). `opAND` (Instruct.rtn:18-22) and
`opOR` (Instruct.rtn:470-476) are boolean logic ops, not value comparisons,
and were excluded as out of scope.

## Judgment calls / flagged ambiguity

- The per-op "correct null-data semantic" column above is a direct arithmetic
  reflection of the **established convention** opEQ/opNotEQ already encode
  (absent `data` ⇒ treated as count 0). Given that convention, the LT/GT/LE/GE
  answers are not themselves ambiguous — they're forced by the convention.
  The judgment call is accepting the convention itself (that "no data" should
  mean "count 0" rather than some "incomparable" sentinel); that judgment was
  already made for opEQ/opNotEQ, so this recon treats it as settled rather
  than re-litigating it.
- **Flagged existing gap, inherited by any new guard that mirrors opEQ's
  shape:** when **both** operands lack `data`, opEQ's branch-1 condition
  (`target && !data`) matches first, but its inner check
  (`argument.isCOUNT || argument.isNUMBER`) is false (argument has no data
  either) — so nothing returns from branch 1, and because the chain is
  else-if-shaped, branches 2/3 never run either. Control falls through to the
  final `return null;`. That means **two null operands currently compare as
  not-equal under opEQ, and also not-not-equal under opNotEQ** (both say
  "false") — a coherent but slightly odd "incomparable" stance rather than
  "equal." If new guards for LT/GT/LE/GE are written to mirror opEQ's
  structure exactly, they will inherit the same both-null behavior: all four
  would also fall through to `null` (false) for a both-null pair. This is
  *consistent* with the existing opEQ/opNotEQ behavior, but it's worth
  surfacing explicitly since "two nulls are < / > / <= / >= each other: all
  false" is a judgment call nobody has stated out loud yet. It does not
  block writing parity guards — it just means the both-null case should be
  decided (or explicitly left as the existing implicit "false" pattern)
  before/while writing them.

## Files touched (read-only)

- `/Users/anthony/Library/CloudStorage/Dropbox/data/InProcess/Groups/Instruct.rtn` (lines 155-300, 449-465 read in detail; full file scanned for `!data` and `compareValues` occurrences)
- `/Users/anthony/Library/CloudStorage/Dropbox/data/InProcess/Groups/GroupItem.mm` (`compareValues` GroupItem.mm:93-134, `getText()` GroupItem.mm:923-977, `getCount()` GroupItem.mm:623-637)

No edits were made to any file. No build or run was performed.
