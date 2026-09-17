# checkSKIP — the skip/scan primitive as a kant rule

Drafted by Clay 2026-09-17 from Tony's offline status. Rules are Tony's; actions are Clay's
draft. **Weight it the usual way: take the distinctions, check every claim about what is in
the tree** — Clay has not read `checkSkip`, `aCTionCodE` or the DelimitText capture, and the
action bodies are kant-shaped, not kant-verified. Clod transcribes the spellings.

## 1. Why it exists

- **The blocker (2026-09-17).** grisyDirectives G03 fails because `checkSkip` runs inside a
  fromThis value and `//` eats to end of line, so no fromThis can contain `//`. A second defect
  rides beside it: `fromThis=(G03\n"#)` comes out as `G03\\n\"` — the escape is doubled
  somewhere between capture and store (or only at print — not measured which).
- **The ruling it lives under (Tony, 2026-08-02).** One skip/consume primitive that understands
  quoted strings and comments, with BOTH `checkSkip` and `aCTionCodE` routing through it. Not a
  callback. **C++ now, kant at self-hosting.** It retires KANT-40 (a `}` in a comment ends an
  action body) by construction.
- **The experiment (Tony, 2026-09-17).** Write the primitive as a kant rule. Not efficient until
  the jitter can make it so; interesting regardless. This file is the experiment's docket card.

## 2. The rules (Tony's, spellings normalized — two edits flagged)

```
IndenT          [ \n\t]+;                                   -- see Q1: run, not char
CommenT
    BlockCommenT    "/*" EmbeddedCommenT-* commentBody="*/"};   -- nests; see below
    LineCommenT     "//" commentBody="\n"};                      -- the whole line; Q3: EOF
EmbeddedCommenT     commentBrace{ BlockCommenT;                  -- scan to a brace, dispatch
commentBrace
    OpenCommenT     "/*";                                        -- back up to hereAt, succeed
    CloseCommenT    "*/";                                        -- back up to hereAt, FAIL
sKIP
    DelimitText;
    QuotE;
    IndenT;
    CommenT;
checkSKIP       sKIP+;                                      -- `skipping=` label dropped, as Tony said
```

**`}` and `{` are modifiers, not typos** (Tony, 2026-09-17). `commentBody="\n"}` is the whole
line up to and including the terminator; `commentBrace{` scans to whichever brace comes first.
The only respell from the status text is `BlockComment` / `Comment` → `BlockCommenT` / `CommenT`.

**Nesting (Tony's design, 2026-09-17).** Tok nests `/* */` and kant follows. The first sketch
(`"/*" BlockCommenT? commentBody`) nested only when the inner `/*` sat immediately after the
outer one; `EmbeddedCommenT` fixes that by scanning to the next brace first. If it is `/*` the
cursor backs up to `hereAt` and `BlockCommenT` runs on it; if it is `*/` the cursor backs up to
`hereAt` and `EmbeddedCommenT` fails, which is the `-*` loop's exit, and `commentBody` then
captures the tail from where the scan began. Two Clay additions to Tony's shape: the `-*` (one
`?` handles one nested comment; two siblings need the loop) and the two labelled alternatives in
place of an action asking which spelling hit (09-10 doctrine). `BlockCommenT` after
`OpenCommenT` is required, not `?`, so an unterminated inner comment refuses with a patient.
The back-up-on-failure is doable and **needs testing** — every non-nested block comment tests
it, because `EmbeddedCommenT` fails on the first `*/` before `commentBody` ever runs.

## 3. The model — what a matched alternative DOES

Two customers, one loop. The customers differ in which alternatives are armed and what happens
between matches; the loop is the same rule.

| alternative   | between tokens (checkSkip)                 | inside a CodE body (aCTionCodE)                 | inside DelimitText / QuotE           |
|---------------|--------------------------------------------|--------------------------------------------------|--------------------------------------|
| CommenT       | consume, discard → labelNO                 | consume, keep verbatim; its `}` is INVISIBLE      | not armed — text is opaque           |
| IndenT        | consume; layout gate may emit `{` `}` `:>` | consume, keep verbatim; no layout                 | not armed                            |
| QuotE         | STOP — the quote is the parse's token      | consume as one unit; its `}` is invisible         | not armed (Q4: escapes only)         |
| DelimitText   | STOP — the parse's                         | consume as one unit                               | —                                    |

Two consequences worth saying once:

- **Between tokens the loop stops at a quote; inside a body it steps over one.** Same rule,
  different arm result: labelNO means "skipped, keep going", a non-null result means "this is
  yours, stop". The `sKIP+` loop ends on the first non-labelNO result or on a miss.
- **Inside DelimitText nothing is interpreted but the close delimiter and the escape.**
  ⚠ **TRUE FOR `( )` AS OF 2026-09-17 — F-81, one modifier character at the delimiter's mint
  site, so the scan target inherits the `^` its driver already carried.** Measured opaque in seven
  positions: `//` mid, leading, after a space, trailing; `/*` mid and leading; a leading `*/`.
  ⚠ **NOT YET TRUE FOR A QUOTED STRING.** `a="// x";` still breaks — `quoteBody` is a scan target
  whose driver carries no modifier, so there is nothing for it to inherit and it needs its own
  decision. `incant/pop/slashValT` carries the controls, `incant/pop/slashLeadT` the flip.
  As it stands: `(G03 // anything)` and `(G03\n"#)` are opaque. A `//` inside a `{ }` body
  IS a comment (KANT-40 wants that); a `//` inside `( )` is text (directives want that). The
  delimiter kind decides, not the content.

Bootstrap fact, so nobody trips on it: the C++ primitive stays the loader's. `aCTionCodE`
captures the checkSKIP actions themselves, so the kant rule cannot be the primitive that loads
the kant rule. It is a second implementation with the C++ one as its oracle (§5), until
self-hosting says otherwise.

## 4. Drafted actions

Conventions assumed and to be checked: an action returns NULL = failed, labelNO = succeeded and
yields nothing; the matched span is reachable from the action; `input` is the stream with a
position that can be read and set. **No `}` appears in any body.** The one place a close brace
must be produced, it comes from a define-line trait, the emitters' idiom: `closeBrace="}"`.

### aCTionLineCommenT
```
{
    // lineComment consumed through the newline; nothing kept between tokens
    input.pos = commentBody.end;
    return labelNO;
}
```
In a CodE body the same arm keeps the span (the customer decides — see §4 tail).

### aCTionBlockCommenT
```
{
    // blockComment consumed through the close; nesting was handled by the terms
    input.pos = commentBody.end;
    return labelNO;
}
```

### aCTionOpenCommenT / aCTionCloseCommenT  (the `commentBrace{` dispatch)
```
{
    // openComment leave the cursor ON the brace so BlockCommenT can take it
    input.pos = hereAt;
    return labelNO;
}
```
```
{
    // closeComment nothing embedded before the close; restore and fail
    input.pos = hereAt;
    return NULL;
}
```
`hereAt` is the position `EmbeddedCommenT` started scanning from — whatever the C++ names it.
The failure arm restoring the cursor is the part that needs testing (§2).

### aCTionQuotE / aCTionDelimitText  (pass-through)
```
{
    // passThru the unit belongs to the parse; return it and the loop stops
    return argument;
}
```
Inside a CodE body the customer asks for "step over" instead: `input.pos = argument.end;
return labelNO;` — one flag on the customer, two arms, no spelling test.

### aCTionIndenT  (the layout engine)
Only the shape. **The decision table for `{` / `}` / `:>` is transcribed from the C++
`checkSkip`, not re-derived.** Gates are the existing `defining` / `processingCode` reads.
```
{
    // layout only after a newline, only when a gate is up; else plain skip
    input.pos = argument.end;
    if !defining && !processingCode return labelNO;
    if !argument.sawNewline return labelNO;
    col = argument.column;                      // column after the run
    if col > indentTop   layoutOpen(col);       // push, insert "{"
    while col < indentTop  layoutClose();       // pop, insert closeBrace
    if col == indentTop  input.insert(":>");
    return labelNO;
}
```
`layoutOpen` / `layoutClose` are two one-line actions rather than braced arms, because a
braced arm would need the KANT-40 character to close it; `closeBrace="}"` rides
`layoutClose`'s define line. `indentTop` is the indent stack — global today, the argument
channel if that reads better; Clod's call. `insert`/`column`/`sawNewline` are placeholders for
whatever the C++ exposes; if the C++ does not use a stack, neither does this.

### aCTioncheckSKIP  (the loop's return)
```
{
    // checkSkip the loop already ran; report how far it got
    return input.pos - startPos;
}
```
Returning the count skipped is what makes it testable from an action (§5). `startPos` is
captured on entry — same channel question as `indentTop`.

## 5. The fixture — `incant/checkSkipT`, and the oracle

**The oracle is the C++ `checkSkip`.** Every row runs the same text through both and diffs
what came out: position reached, tokens inserted, text left for the parse. A row that agrees
is green; a row that disagrees names which side is wrong before anything moves.

```
CS-1   "  // x\n  y"            skips to y                          both
CS-2   "/* a } b */ y"          skips to y; the } was invisible     both      <- KANT-40's row
CS-3   "(G03 // x)"             DelimitText opaque; // kept         both      <- G03's row
CS-4   "\"//\" y"               stops at the quote                  both
CS-5   "/* a\n*/ y"             close on a later line               both
CS-6   "// x"  (no newline)     skips to end, no refusal            both      <- Q3
CS-7a  "/* /* */ x */ y"        nested at start                     both
CS-7b  "/* a /* b */ c */ y"    nested mid-body                     both      <- the first sketch failed this
CS-7c  "/* /* b */ c /* d */ e */ y"  two siblings                  both      <- needs the -* loop
CS-8   "a\n    b\n  c\nd"       layout emits, gates up              diff of the two token streams
CS-9   same text, gates down    no emits                            diff
CS-10  "(G03\n\"#)"             stored value read back, once        the \\n defect, whichever side owns it
```
CS-8 is the row that certifies the experiment; the rest certify the primitive. CS-10 is a
separate defect and is measured, not fixed, by this file.

## 6. Rulings wanted from Tony

- **Q1** `IndenT` as a run (`+`) or one character with the loop doing the run? Layout needs the
  column, which wants the run.
- **Q2** ANSWERED 2026-09-17: block comments nest, as in Tok. The design is in §2; the
  back-up-on-failure needs testing.
- **Q3** Line comment at end of input with no newline: succeed (labelNO) or refuse? Draft says
  succeed.
- **Q4** Inside DelimitText, is `\` the only escape, and does `"` count for nothing? G03's lone
  `"` says yes to the second.
- **Q5** Placement — §7 is a proposal.

## 7. Where it sits on the docket (proposal)

**WHO DOES WHAT (Tony, 2026-09-17).** Tony writes the **first cut** of the incantation from this
card; Clod comes in afterwards to help finish. ⚠ **The first cut deliberately does NOT address
item 4** — generating a parse for a rule that already carries an action — so a first cut that
stalls on exactly that is the plan working, not a defect. Recorded here rather than left in
chat, because a division of labour that lives in a conversation is one nobody can check against.


1. ~~F-72, its own stroke.~~ ✅ **CLOSED 2026-09-17**, `258a5ff`. Worth one line here
   because it touched this card's own machinery: the refusal sits in `interpretXP`, not in
   `opDot`, because opDot's `!argument` test cannot tell *"no right operand was written"* from
   *"the right operand evaluated to null"* and its `lastREF` fixup destroys both operands before
   anything can ask. Any rule here spelling a unary to the right of a dot now gets told.
2. `a.b.c.d`, the backward walk's stack (unchanged).
3. **DelimitText opaque scan, C++, one stroke.** Unblocks grisyDirectives without waiting for
   anything below; it is the 2026-08-02 ruling's "C++ now" half. CS-3 and CS-10 are its rows.
4. **builtinParseR** (Tony's question, own card) — checkSKIP's alternatives carry actions AND
   need a generated parse, so this file depends on it. Clod's read 2026-09-17: the gap is one
   arm upstream of `setParse` — `setActions`'s `isCoded` arm sets `method = processAction` and
   publishes no `builtinActoR`, where the other two arms publish. The card is a `setActions`
   card first. ⚠ **AND THAT READ IS STRUCTURAL, NOT RUN** — three sites read (`setActions`'s
   three arms, `fireLabelMethod`'s lazy fill, `setParseWalk`'s tail) and no fixture driven. It
   is **one fixture from being measured**: a kant rule that is `isCoded` AND carries members,
   put through `setParse`, and ask whether its action survives. In this project a mechanism you
   can point at is usually right and one inferred from a symptom is a coin flip, so this is the
   better half of that — but it is still owed a run before anyone builds on it.
5. **checkSKIP in kant, interpreted, CS-1..CS-9 against the C++ oracle.** Correctness only.
6. Efficiency: waits on the jitter, by Tony's own estimate. Not this card's claim.
