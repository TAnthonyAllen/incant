# Directives

A directive applies a targeted change to a file or text buffer without modifying the original source. The model is simple:

```
source text  →  apply directives  →  modified text
```

The original is untouched. The result is the original with your changes layered on top.

The change can be as small as a single inserted line or as large as a block spanning multiple methods — minor surgery to, if needed, something approaching a full autopsy.

---

## Why Directives

The primary use case is development and debugging. You want to test a change — a new function, a modified block, an inserted comment — without touching the working codebase the change is being applied to. Directives let you apply the change to a copy or an in-memory buffer, verify the result, and discard it cleanly. When you're confident, you make the real edit. Until then, your working base stays clean.

---

## The Commands

### `replaceAt`

Replaces a matched block of text with replacement text.

```
replaceAt(target, matchText, replacementText)
```

### `insertAt`

Inserts text before or after a matched line.

```
insertAt(target, matchText, insertionText, before|after)
```

### `setMark`

Sets the position in the buffer where the next directive will begin its search.

```
setMark(target, position)
```

### `getMarkLineAt`

Returns the line at the current mark position. Useful for confirming you're positioned where you expect before applying a change.

```
line = getMarkLineAt(target)
```

### `reset`

Resets the mark to the beginning of the buffer. Directives search forward from the mark and never retreat; `reset` starts a fresh pass from the top.

```
reset(target)
```

---

## How Directives Can Be Used

**Source file patching.** Load a source file into a buffer, apply a set of directives, write the result back. The original file on disk is not touched until you explicitly close the buffer.

**In-memory text transformation.** Directives work on any buffer field, not just files. Generated text, assembled strings, or any content loaded into a buffer can be transformed the same way.

**Grammar text.** Directives can be applied to grammar source before it is parsed. This is an advanced use — modifying grammar text is not the same as modifying live parse rules — but the mechanism is identical.

---

## Mark Discipline

All directive operations search forward from the current mark. Two rules follow from this:

- **Apply directives in document order** — top to bottom. A directive targeting earlier text than the current mark will not find its match.
- **Call `reset` between passes** if a second pass needs to target text near the top of the buffer.

