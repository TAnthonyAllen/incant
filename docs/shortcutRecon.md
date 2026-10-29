# SHORTCUt recon (SEQ 460, 2026-10-29, read-only)

kantGrammar's `SHORTCUt=[-+~`$_:,]+ ruleMethod=aCTionShortcuT;` borrows the old road's C++ action. This records what that
action does, when it runs under kantGrammar's PRINt, and what reaches `opPrintList`. Measured on trunk `a63041a5`'s binary
with lldb only (no taps, nothing to revert).

## 1. What aCTionShortcuT does (`ruleActions.rtn:948`)

```
// Process string shortcuts.
extern GroupItem aCTionShortcuT(GroupItem group)
{
    if gCount == 2 && opFields[text]    return null;
    isShortcut = true;
    return group;
}
```

It writes **nothing to a buffer**. It refuses a two-character match that names an operator, and otherwise marks the matched
node `isShortcut` and hands it back. **The work happens at print time in `appendGroup`** (`GroupActions.rtn:66-82`), one
character at a time:

| char | effect in appendGroup |
|---|---|
| `~` | marks the item for indenting (`tabRight(inDENT.gCount)` after the loop) |
| `$` | toggles `useDefaultSpace` (a GroupRules global) |
| `_` | `append(' ')` |
| `:` | `append('\n')` |
| `+` / `-` | `inDENT.gCount` up / down (a global, so it outlives the print) |
| `` ` `` | `append('\t')` |
| `,` | nothing |

## 2. When it runs under PRINt, and what reaches opPrintList (lldb, `print qa _ qb:;`)

- **Parse time, during PRINt's drive:** `GroupItem::parse -> fireLabelMethod -> aCTionShortcuT`, once per shortcut. It only
  marks.
- **Run time:** `testOP -> opPrintList -> appendGroup` meets both items with `isShortcut` set. The mark survives PRINt's
  `printItems +% *cur` and its `copyOf(printItems)` (the flag is on the shared body).
- PRINt's action does nothing special with a SHORTCUt item; opPrintList's only test is `isShortcut`, in `implicitFormat`
  (a shortcut takes no format) and in appendGroup.

## 3. Old road against the new grammar's PRINt

Both through `printFormatT`'s prelude (`qa=2 qb=3 qc=4`), stdout less noise, newlines as `|`, tabs as `^I`.

| statement | old road | new PRINt | |
|---|---|---|---|
| `print qa ~ qb:;` | `2 3 \|` | `2 3 \|` | agree |
| `print qa $ qb:;` | `2 3\|` | `2 3\|` | agree |
| `print qa _ qb:;` | `2  3 \|` | `2  3 \|` | agree |
| `print qa : qb:;` | `2 \|3 \|` | `2 \|3 \|` | agree |
| `print + qa:;` (`qa + qb` is addition on both) | `2 \|` | `2 \|` | agree |
| `print - qa:;` (`qa - qb` is subtraction on both) | `2 \|` | `2 \|` | agree |
| ``print qa ` qb:;`` | `2 ^I3 \|` | `2 ^I3 \|` | agree |
| `print qa , qb:;` | `2 3 \|` | `2 3 \|` | agree |
| `print + ~ qa:;` | `^I2 \|` | `^I2 \|` | agree |
| `print + + ~ qa:;` | `^I^I2 \|` | `^I^I2 \|` | agree |
| `print + - ~ qa:;` | `2 \|` | `2 \|` | agree |
| `print qa $ qb $ qc:;` | `2 34 \|` | `2 34 \|` | agree |
| `print qa __ qb:;` | `2   3 \|` | `2   3 \|` | agree |
| `print qa _: qb:;` | `2  \|3 \|` | `2  \|3 \|` | agree |

**Context, not SHORTCUt's:** with a shortcut first and then two adjacent expressions, `print ~ qa qb:;`, the new road
prints `2` where the old prints `2 3`. The control `print qa qb:;` with no shortcut does the same (`2` against `2 3`):
kantGrammar's `EXPRESSIOn lizted=TOKEn+` takes `qa qb` as one expression and prints its first value. With a shortcut
between the items the roads agree.

## 4. Proposal (Tony's note, 2026-10-29: the shortcut handling in appendGroup should go into the SHORTCUt action)

Today SHORTCUt **works by borrowing**: the C++ action runs at parse but only marks, and the effect happens when opPrintList
runs. Every row above agrees. It is not build-only in kant's sense, though: it leans on a flag that has no kant write case,
and on appendGroup knowing about shortcuts.

**Shape S (proposed, not built):** SHORTCUt gets its own kant action, which **only builds**, as PRINt's does: an instruct with
op `printShortcut` and the matched text as its operand. opPrintList already runs any item that is an instruct
(`Instruct.rtn:1021`, `value = testOP(value)`), so no new arm is needed there.
- **The per-character switch moves out of appendGroup** into one C++ function, `runShortcuts(text, buffer)`. `opPrintShortcut`
  calls it on the new road, and appendGroup's old-road arm calls the same function, so there is one copy of the switch, not two.
- **The buffer:** opPrintList holds the buffer as a local. The op needs it, so opPrintList passes it on: it pushes the
  buffer for the op to pop, as opPrintList itself pops `bufferSTAK`. Alternatively the op returns its text and the globals it
  changed; pushing is simpler and keeps `~`'s `tabRight` (which needs the buffer) in the op.
- **No kant write case is needed for isShortcut:** on the new road the item is an instruct, not a marked label, and `implicitFormat`
  reads a format only for COUNT / NUMBER / STRING / TOKEN, so an instruct item takes none. isShortcut stays the old road's
  flag, set by aCTionShortcuT.
- **The operator refusal** (`gCount == 2 && opFields[text]`, so `++` and `--` are not shortcuts) moves into the kant action.

## 5. Certificate rows, pre-registered for Shape S

One row per statement in section 3's table: the new road equal to the old road, by value. Today every row agrees, so the
rows are GREEN on trunk and must STAY green: a regression certificate, not a born-red one. Add:
- **The cut:** the new road no longer reaches aCTionShortcuT. A count of parse-time aCTionShortcuT calls inside the PRINt drive
  reads 0 (today 2 for `print qa _ qb:;`).
- **The anti-vacuity sibling:** `print + + ~ qa:;` = `^I^I2` (two tabs), which an op that did nothing would fail.
- **H7:** empty `opPrintShortcut`'s body. Every row carrying `_ : `` ` `` `~` goes red by value; `,` and the bare `$ / + / -` rows stay
  green, because they print nothing visible alone, which is why the combination rows are there.
