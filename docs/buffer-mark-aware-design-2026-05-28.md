# Buffer mark-aware design — 2026-05-28

Design settled at end of 2026-05-28 session (Tony + Clod, Clay parked). Buffer
gets the smarts; incant inherits a natural operator-flavored API for text-
substrate directive support. Companion to `incant-directive-replace-sketch-
2026-05-28.md` (the AST-substrate engine that landed today and passed POP).

This doc captures what to build, not how. Implementation is Tony's offline
work for the Buffer side; the Instruct.rtn opIN extension and the three thin
incant-extern wrappers are Clod-track when Tony's Buffer changes land.

---

## The substrate question, resolved

The 2026-05-28 morning held finding ("Development directives need replace/
delete — buffer span vocabulary is the substrate") named two layers. Layer
one was the AST-substrate engine for replace/delete on code-action targets —
that's working as of this afternoon. Layer two is the text-substrate path
for editing text-bearing buffer fields (load a .twk file, do find-and-
replace, write it back). That's the substrate Buffer.twk needs to provide.

The Read 2 framing from earlier in the session held: incant directives need
to operate on text-buffer targets, not just AST targets. The right substrate
is Buffer's existing span machinery (setMark, getMarkedString, insertInto
Buffer, deleteFromBuffer), with mark-awareness added so the existing append/
delete operators do the right thing on text-bearing targets.

---

## The five primitives, the incant-side ergonomics they produce

The text-substrate find/replace/delete vocabulary in incant becomes:

```
setMark(buf)               # arm the mark machinery
unMark(buf)                # disarm — back to append-at-current
closeFile(buf)             # explicit write-back, never automatic
buf += stringField         # insert at mark (if armed); else append at current
buf -= count               # delete count chars at mark (or fromText.count)
stringField IN buf         # find — returns matched string or null, sets mark on success
```

Single-occurrence find-and-replace:

```
if fromText IN buf {
    buf -= fromText.count;
    buf += toText;
};
```

Global sweep:

```
setMark(buf);
while fromText IN buf {
    buf -= fromText.count;
    buf += toText;
    /* mark is past the inserted toText, next find starts there */
};
unMark(buf);
closeFile(buf);
```

The mark threading is implicit — opIN sets it on success, the operators
advance it past their work, the loop continues from where it left off.

---

## Mark behavior — the contract

The mark is a Buffer-side cursor, set explicitly or as a side-effect of find.
Behavior of each operation:

- **setMark(buf, offset)** — Sets mark to absolute offset and marks markIsSet
  true. Mostly used as `setMark(buf)` (offset 0 implicit, or via overload).

- **unMark(buf)** — Clears markIsSet. Subsequent appends go back to current
  (append-at-end) behavior. Subsequent deletes go back to existing delete-
  from-current behavior.

- **`IN` operator (opIN extension for BUFFER target)** — Scans from current
  mark forward (or from start if unset). If found, sets mark to start of
  match and returns the argument (matched string field). If not found,
  leaves mark unchanged, returns null.

- **append operators (`+=`) with markIsSet true** — Insert at mark, advance
  mark past the inserted bytes. So after find+insert, mark is positioned
  for the next find to scan forward without re-firing on the inserted text.

- **delete operators (`-=`) with markIsSet true** — Delete count chars at
  mark. Mark stays at the same absolute position (what was at mark+count
  is now at mark). So after delete, an immediate insertAtMark lands where
  the deletion was.

A failed find leaves mark unchanged — that's the only no-op among the
operations.

---

## Buffer-side implementation

Three additions to Buffer (C++ side, Tony's offline work):

1. **`markIsSet` boolean flag.** False by default. Toggled true by setMark,
   false by unMark.

2. **Mark-awareness in append and delete methods.** At the top of
   appendString, appendChar, appendInt, appendDouble, appendFloat,
   appendLong, and deleteFromBuffer — check markIsSet. If true, operate at
   mark (with appropriate semantics per the contract above). Else fall
   through to existing current-based behavior.

3. **`findInBuffer(String needle)` method.** Scans from mark (if markIsSet)
   or buffer start forward. strncmp loop. On match: sets mark to start of
   match, sets markIsSet true (if not already), returns 1. On no-match:
   leaves state unchanged, returns 0.

Wrinkle worth thinking about during implementation: when the buffer needs
to grow (insertIntoBuffer pushes past allocated size), Buffer.extend() may
relocate the underlying memory. The existing code presumably fixes up
`current` and `mark` post-relocation; verify both are handled. If mark
relocation isn't there, add it.

---

## Incant-side: the three extern wrappers

Three thin one-liners. Best home is Instruct.rtn (alongside the AST directive
infrastructure) or a new dedicated file — Tony's preference at landing time:

```tawk
extern void setMark(GroupItem bufField)
{
    bufField.buffer.setMark();
}

extern void unMark(GroupItem bufField)
{
    bufField.buffer.unMark();
}

extern int closeFile(GroupItem bufField)
{
    return bufField.buffer.closeFile();
}
```

Plus extern decls in `Include/groups.ext`.

---

## Incant-side: the opIN extension

One new branch in `opIN` (Instruct.rtn):

```tawk
extern GroupItem opIN(GroupItem argument,GroupItem target)
{
PLGset      set;
GroupItem   result;
    if argument.isSET {
        if set = argument.characterSet
            if set.foundIn(target.text)     result = trueResult; }
    or target.isSET {
        if set = target.characterSet
            if set.contains(argument.text)  result = trueResult; }
    or target.isBUFFER {
        if target.buffer.findInBuffer(argument.text)  result = argument; }
    return result;
}
```

The BUFFER case returns `argument` (the matched-string field) on success,
not trueResult. argument carries its `.count` (the string length, courtesy
of incant's count-tracking on string fields), so callers can use it directly
in delete-by-count operations without a separate strlen extern:

```
buf -= fromText.count;
```

Or `-=` could be overloaded to accept a String GroupItem directly and use
its count internally (`buf -= fromText`) — minor ergonomics call, easy to
add either way.

The asymmetry — set cases return trueResult (sentinel), buffer case returns
the matched string — is mildly inconsistent. Both are truthy on success and
null on failure, so callers using `if X IN Y` work either way. Backporting
"return argument on success" to the set cases is a v2 nicety, not required.

---

## What the directive engine looks like on top

The text-substrate directive orchestrator parallels ReplaceDirective but
operates via the buffer primitives:

```tawk
extern GroupItem applyTextDirective(GroupItem argument,GroupItem target)
{
GroupItem   fromText;
GroupItem   toText;
    fromText = argument.firstInList;
    if !fromText {
        cerr "Text directive needs 'from' as first child:",argument.tag:;
        return target; }
    toText = fromText.nextInParent;     // may be null for delete
    setMark(target);
    while fromText IN target {
        target -= fromText.count;
        if toText   target += toText;
    };
    unMark(target);
    return target;
}
```

Dispatch hook: opPlusEQ already dispatches DiR-tagged arguments to
applyDirectives (today's AST path). Add a branch for buffer-target case
that routes to applyTextDirective instead:

```tawk
extern GroupItem opPlusEQ(GroupItem argument,GroupItem target)
{
GroupItem   grup;
    if !compare(head(argument.tag,3),"DiR")
        if target.isBUFFER  return applyTextDirective(argument,target);
        else                return applyDirectives(argument,target);
    ...rest unchanged...
}
```

Same shape as the existing DiR-hook, just a sub-branch on target type. The
directive author writes the same syntax — `targetField += DiRsomething` —
and the engine routes by what target is.

The :+ operator (opReplace) similarly gets a buffer-target branch routing
to applyTextDirective if needed, though for text substrate += and :+ might
be functionally identical (both do find-and-replace). One operator might
be enough; tbd at landing time.

---

## Directive declaration shape for text substrate

For AST directives we settled on positional: `DiRReplaceFoo fromBody toBody;`
where fromBody and toBody are code-bearing action definitions. For text
substrate, from/to are string fields, not actions. The same positional
shape works:

```
fromText = "int dummy;";
swapText = "int REPLACED;";
DiRReplaceTxt fromText swapText;

/* apply */
fileField += DiRReplaceTxt;   /* fileField is a buffer field loaded from disk */
```

Where fromText and swapText are string-bearing fields. The engine reads
argument.firstInList (fromText), argument.firstInList.nextInParent (swap
Text), and operates on the buffer target.

---

## Sequencing — what lands when

Buffer-side work (Tony, offline):

1. Add markIsSet flag to Buffer
2. Add mark-awareness to append and delete methods
3. Add findInBuffer method
4. Verify mark relocates correctly during Buffer.extend()
5. Re-tok Buffer.twk

Incant-side work (Clod, after Buffer lands):

1. Add three extern wrappers (setMark, unMark, closeFile) to Instruct.rtn
2. Add externs to Include/groups.ext
3. Extend opIN with the BUFFER branch
4. Write applyTextDirective in Instruct.rtn
5. Add the buffer-target branch to opPlusEQ's DiR-dispatch hook
6. Write the test fixture in unitTests (load groups.twk, apply DiRReplaceTxt,
   verify buffer content changed)
7. Wire into oneTest
8. Re-tok GroupRules.twk with groupDirectives

When all of that lands, the text-substrate POP becomes:

```
fileField = new("/path/to/groups.twk");
getFile(fileField);
fromText = "int dummy;";
swapText = "int REPLACED;";
DiRSwap fromText swapText;
fileField += DiRSwap;
closeFile(fileField);
/* file on disk should now contain "int REPLACED;" in place of "int dummy;" */
```

Verify with cat on the file after run.

---

## Open question parked for landing

The composite-vs-atomic question for delete (whether `-=` should take a
count int or a GroupItem string-field, or both): keep separate (atomic)
per Tony's call this session. The override `buf -= stringField` (deletes
strlen worth) is ergonomically nice but adds shape-overloading. Decide at
landing time based on how the directive engine reads.

The find-iterator vs first-match-only question: v1 is first-match-only
(opIN returns first match, sets mark there). Repeated calls find next
match because mark advanced past the previous one. That IS the iterator,
implicitly. No separate findNext primitive needed.

---

## Related material

- `incant-directive-replace-sketch-2026-05-28.md` — the AST-substrate engine
  that landed and passed POP this afternoon
- `tok-directives-mechanism-recon-2026-05-28.md` — the recon that confirmed
  tok directives are insert-only and motivated the incant-directives-for-
  development arc
- `support-extern-recon-2026-05-28.md` — earlier scout of support-class
  methods that could be wrapped as incant externs; superseded for this
  arc by the focused 3-wrapper design here
- `incant-directives-v1-status.md` — the splice-only v1 directive status
  from 2026-05-27; today's work extends with replace/delete on AST and
  the design above for text substrate
