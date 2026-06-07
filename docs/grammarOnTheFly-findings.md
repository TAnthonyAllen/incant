# grammarOnTheFly — Findings (2026-06-07)

**POP landed.** The `grammarOnTheFly` demo runs end to end: a field (`doc`)
captures its **own documentation comment** through a grammar rule (`DelimText`)
grafted into the live `DatA` bootstrap rule *at runtime*, accumulates it into a
buffer, and writes it to disk through a brand-new writable operator. Verified by
artifact — `incant/grammarOnTheFly.out`, 3654 bytes — not by shape-reading.

The locomotive changed its own track while running and wrote the proof to disk.

## The chain that works

1. `DelimText isRule '('- dtext^}=delimiter;` — define the capture rule.
2. `DatA += DelimText; guard(DatA);` — graft it into the live bootstrap rule and
   reset the cached guard set so the parser re-derives it (now seeing `(`).
3. `doc = (/* … */#)` — the next definition routes its data through the
   just-grafted alternative; `DelimText` captures the comment into `doc.dtext`.
4. `printTO(doc); print doc.dtext:; printTO(null);` — move the captured text into
   `doc`'s buffer (see "printTO mechanism" below).
5. `doc modedOP "…/grammarOnTheFly.out";` — the new writable operator points
   `doc`'s buffer at a file.
6. `closeFile(doc);` — flush the buffer to disk.

---

## Landmine 1 — noSkip goes BEFORE the `}`: `^}`, not `}^`

The `}` upToOver capture invokes `checkSkip` per step while scanning for the
delimiter. With skip on, `checkSkip` **eats `/* */` comments** before the capture
sees them. So the capture needs noSkip — but placement is load-bearing:

- `dtext}^=delimiter` (`^` **after** `}`) — kills delimiter matching too. The
  scan never matches `#)`, **overruns to EOF**, the `define` never closes, parse
  craps out.
- `dtext^}=delimiter` (`^` **before** `}`) — correct. Suppresses comment/skip
  across the capture while the `#)` delimiter match still fires. Full raw capture.

The two failure modes bracket the knot: skip-on → `#)` matches but comment eaten;
skip-off-wholesale → comment survives but `#)` never matches. `^}` threads it.

## Landmine 2 — `checkSkip` strips `/* */` during a raw capture

`delimTest` only ever captured `"hello world"` — plain text, no comment markers —
so comment-capture was **never actually exercised** until `grammarOnTheFly`. The
"swallows comments too" claim in the demo prose was untested and initially false:
without `^}`, `dtext` came back holding only the trailing `\n` between the
comment's `*/` and the `#)`. Diagnosed via `opPrint` (`printText = "> \n"`).

## Landmine 3 — a self-describing payload cannot contain its own delimiter

The raw scan stops at the **first** occurrence of `#)`. The comment that *describes*
the delimiter quoted it literally (`the string "#)"`, original line 24), so the
capture truncated there (~409 chars) and the parser choked on the orphaned tail.
Fix: reword the prose to describe the closer without spelling it ("the closing
delimiter"). **Permanent constraint:** any final prose for this self-referential
demo must never contain a literal `#)` — or switch to a delimiter that won't occur
in natural text.

## Landmine 4 — a single duplicate/colliding extern fails the WHOLE build

Two separate symbol problems, both silent-ish (build "did not work", run uses the
stale binary, `setCompiledMethod: ERROR no method found X` at startup):

- **`closeFile` duplicate.** `closeFile(GroupItem)` already existed at
  `GroupActions.rtn:132` (from the directives work — it even has a tag-fallback
  filename default). A second copy added to `Instruct.rtn` was a duplicate symbol
  → **link error → entire build aborts** → every *other* new symbol (`setFileOp`,
  `flush`) silently absent → `modedOP` got a null gOp → `runOP` face-plant. One
  collision took down everything. Fix: don't redefine; reuse the existing one.
- **`flush` name collision.** A global `void flush();` prototype lives in the Frame
  headers (`~/data/support/Include/frame:70,390`), so the compiler gave my
  `extern void flush(GroupItem)` **C++ linkage (mangled)** and `dlsym("flush")`
  couldn't find it — while `closeFile`/`setFileOp` (no prior prototype) linked as
  clean C symbols. Fix: rename to `flushBuffer`.

**Lesson:** before adding an `extern` wrapper, grep for an existing definition AND
an existing prototype. Generic names (`flush`, `closeFile`, `setFile`) are
dangerous — a duplicate fails the build; a prototype-only clash fails the dlsym.

---

## Feature — `modedOP`: an operator whose gOp is writable

New incant primitive (Tony + Clay design). An operator field with an exposed,
settable gOp slot, so the same infix operator can be re-pointed at different
methods:

```
doc modedOP "path";          # target = doc, argument = "path"
```

Wiring:
- **Shim** (`Instruct.rtn`) in the binary-op signature `(argument, &target)` —
  same shape as `opAssign`, NOT `(&target, &argument)`:
  ```
  extern GroupItem setFileOp(GroupItem argument, GroupItem &target)
  {  if target.isBUFFER  target.buffer.setFile(argument.text);  return target; }
  ```
- **Registration** (`incant/setup`, `Operators` registry):
  `modedOP operateMethod=setFileOp;` — `operateMethod` binds the gOp slot via
  `setOperat(dlsym(name))` (the shared `ruleMethod` C binder, tag-gated:
  `operateMethod` → gOp/`isOperator`; `ruleMethod` → gMethod/`isMethod` for unary).

Current build pre-binds in `setup`. True runtime rebinding from incant
(`modedOP operateMethod=…` as a statement) is the next proof — deferred so
"operator works" and "operator is rebindable" don't entangle in one build.

## Mechanism — `printTO` / `opPrint` buffer diversion (needs a unit test)

`printTO(doc)` runs `printToBuffer`, which sets the global `toBUFFER` to the
field's buffer (and `reset()`s it). `opPrint` (the incant `print` rule handler)
checks `toBUFFER`: set → `toBUFFER += printText`, else → `cout`. So incant-level
`print` statements divert into the buffer; the **C++ tok-`print`** inside
`printToBuffer` ("diverting…" / "stopping…") is compiled output that goes to
**stdout**, NOT the buffer — they are two different print paths. `printTO(null)`
clears the divert. **No unit test covers this yet — add one** (Tony confirmed it
works; there was an assumed test that doesn't exist).

## Open question (parked) — write-2: sourcing a file's own text

The demo's real second write is grammarOnTheFly's **own** text (prepend the
captured comment to the file = `insertBefore`). But `getFile` reads AND parses
(`pushInput`) what it loads, so loading the file re-executes it. Sourcing a file's
raw text without parsing it is its own problem — needs a load-without-parse path
(see the `getFile` suppress-parse TODO). Parked as a named open question.
