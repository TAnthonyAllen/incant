# Form files — conventions for `IncantForms/`

*The spec for the XML→incant form corpus. `IncantForms/Windows/tabs` is the
first conversion and the worked reference; ~100 more follow. This doc captures
the conventions a converted form relies on so each new conversion has something
to copy rather than reverse-engineer. Bones, with file:line pointers to the
source of truth — not a re-explanation of the GroupItem/rule core (see
`CLAUDE.md`).*

A form is a window-definition: a `define` block describing a tree of fields
(window → body → panels/controls) plus its help text, run through `incant` so
`printDefinition` can round-trip it. The original DSL was XML
(`XML/Windows/*.xml`); these are the indentation-block incant equivalents.

---

## 1. The per-form preamble and `initFORMs`

Every form needs the runtime bootstrapped, the registries on the search list,
and the `(…#)` literal enabled (§2) before its `define` block parses. That
boilerplate collapses to **four top-level lines**:

```
Start();
include(unitTests);
include(utilities);
initFORMs();
```

`initFORMs` (an action in `incant/utilities`) wraps the part that *can* be
wrapped:

```
initFORMs code={
    search reset stack Grokking;
    search UnitTests Utilities list;
    changeDatA(); };
```

### What stays top-level, and why (the include-deferral finding)

The first three lines **cannot** move into `initFORMs`. This is not style —
it's how `include` and `Start` behave:

- **`Start();`** is the parser entry rule (`Start = StatemenT+`, incant/grammar).
  Called from inside an action body it *re-enters* the top-level statement
  parser and consumes the rest of the input stream within the call — control
  flow scrambles (the statement after it runs dead-last, after `stop()`). It
  has to be the outermost call.

- **`include(...)`** is an `immediateAction` bound to `loadInputFromFile`
  (incant/setup:18). It loads via **`pushInput` — a deferred parse**: the file
  is queued and only parsed when control returns to the *outer* parse loop, not
  synchronously at the point of call. So a registry an `include` brings in is
  **not visible to later statements in the same action body**. Concretely:
  `include(unitTests)` followed by `search UnitTests` *in one body* fails —
  `WARNING: UnitTests must be a registry to add to searchlist` — because the
  search runs before the pushed input is parsed. The includes therefore have to
  happen at top level, before `initFORMs()` is called.

- **`include(utilities)`** additionally can't self-wrap: it's what makes
  `initFORMs` exist in the first place.

`printDefinition` lives in the **UnitTests** registry (incant/unitTests:213), so
forms genuinely need `unitTests` loaded — the include isn't optional.

Inside the body, `search` and `changeDatA()` run synchronously and are safe to
wrap. (Verified empirically 2026-06-09; see the comment block at the `initFORMs`
definition in `incant/utilities`.)

> **Known cosmetic wart:** running `initFORMs()` prints the `Search list: …`
> status line **twice**. The `Search` rule lacks `defer`, so its handler
> double-executes inside an action body. It is harmless — the `reset` clears
> between the two runs, so the final search list is correct — just noisy. A
> `defer` on the `Search` rule removes it; that change is **parked pending
> Haps's own investigation**, not applied. Don't "fix" it without checking
> with him.

---

## 2. The `(…#)` delimited-text literal

A field value can be a block of free prose:

```
tabFORM=(In this example, there are two key components … set as the FORMs registry).#);
```

**What it is.** `(` opens a text literal; the prose runs until a closing
delimiter; the opening `(` and the delimiter are **not** included in the stored
string. Source: `DelimText isRule '('- dtext^}=delimiter;` (incant/utilities:232).
It's added as an alternative to the `DatA` value rule (incant/grammar:43) by
`changeDatA()` — `DatA += DelimText; guard(DatA);` (utilities:233). The change
is **not permanent**: the `DatA` rule reverts when `incant` hits `stop()`
(utilities:225–230). This is why `initFORMs()` (which calls `changeDatA()`) must
run before any form text that uses the literal.

**Why it exists.** Quoted strings (`"…"`) force escaping and choke on the
punctuation real help text contains. The `(…#)` form lets prose with commas,
periods, and **embedded parentheses** be a value verbatim. The close is marked
by the delimiter (`#`) rather than the bare `)`, so an ordinary `)` inside the
text does *not* terminate it — verified: `(… a ) paren inside#)` parses with the
embedded `)` intact.

**Close-delimiter flexibility.** The closing marker is *captured by the rule*
(`=delimiter`), not hardcoded to one character — so it can be chosen to avoid
whatever the prose contains. The corpus convention is **`#)`** (delimiter `#`
immediately before the closing paren). Stick to `#)` unless a body genuinely
contains `#)`, in which case pick another delimiter; document it inline if you
do.

---

## 3. `dESCRIPTIONs` + `describe=` — the help mechanism

Forms carry their own help text as data, registered separately from the layout:

```
register(dESCRIPTIONs);
define
    tabFORM=(… description of the tabFORM …#);
    tabBAR=(… description of the tabBAR …#);
    ;
register(FORMs);
define
    tabFORM window … 
        …
        help describe=tabFORM bordered height=100 fill=lightGreen;
    ;
```

The pattern:
1. `register(dESCRIPTIONs)` makes the descriptions registry current.
2. A `define` block of `name=(prose#)` entries — one per documented field,
   keyed by the field's tag (`tabFORM`, `tabBAR`).
3. `register(FORMs)` switches to the forms registry for the layout itself.
4. A `help` panel with **`describe=<tag>`** binds to the matching description
   entry — that's how a panel surfaces its help text at runtime.

Keep description tags identical to the field tags they document, so `describe=`
resolves by name.

---

## 4. Trailing free prose after `stop()`

The parser exits at `stop()` (`stop = stopParsingInput immediateAction`,
incant/setup:62), so **anything after `stop()` is never parsed** and needs no
comment delimiters. The convention for form-file footnotes — design notes,
rationale, conversion caveats — is plain prose below `stop()`:

```
printDefinition(tabFORM);
stop();

    *****************************************************************************

Note the value of the tabs attribute … this text is not wrapped in a comment;
the incant parser stops at stop() so there is no need to.
```

A separator line of `*` is the visual cue. This is the right home for the kind
of explanation that in the XML original was dangling text after the last tag.

---

## 5. `printDefinition(…); stop();` — the conversion-POP pattern

End a converted form with:

```
printDefinition(tabFORM);
stop();
```

`printDefinition` re-emits the field tree in incant definition format. For a
faithful conversion the output is the form you wrote, proving the XML→incant
round-trips. It's the proof-of-progress (POP) check for each conversion — run
`incant IncantForms/Windows/<form>` and eyeball that the printed definition
matches the `define` block. Once a form is in production this line can be
dropped, but during the conversion sweep it's the per-file acceptance test.

---

## Conversion checklist (per form)

1. Four-line preamble (§1).
2. `register(dESCRIPTIONs)` + `name=(prose#)` entries (§2, §3).
3. `register(FORMs)` + the `define` layout; `help describe=<tag>` panels (§3).
4. `printDefinition(<formTag>); stop();` (§5).
5. Footnotes as free prose after `stop()` (§4).
6. Run `incant IncantForms/Windows/<form>`; confirm the round-trip and that any
   `register`-attributed panels resolve (the `register` keyword is consumed
   silently and won't echo in `printDefinition` — that's expected, not a loss).
