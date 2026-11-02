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

## 2a. MEASURED 2026-09-18 — THE DEFINITION'S BLOCKER IS `"//"`, NOT `"/*"`, AND IT IS NOT A CATCH-22

Tony's offline report: *"It shits the bed and cannot get past the BlockCommenT definition,
probably because the definition involves comment delimiters like `/*`. If that is the cause,
we have a Catch 22 condition."* **Half right: it is a comment delimiter, and it is the other
one.** `"/*"` and `"*/"` are both innocent, measured.

**What the run says, verbatim** (`IncantForms/WorkingOn/tester`, stderr, exit 0):

```
ABANDONED IncantForms/WorkingOn/tester -- the parse STOPPED with input left over. A statement
failed to match, which ends Start's StatemenT+ repetition, so everything from here on was
NEVER PARSED. The exit status is still 0. It resumes at:
    =[ \#\	]+;#    BlockCommenT    "/*" EmbeddedCommenT-* commen
```

⚠ **THE RESUME TEXT NAMES `IndenT`, TWO LINES ABOVE THE OFFENDER.** Reading it as the failing
line is what sends you at the set definition, which is fine in isolation. Same misdirection
family as bear-trap #32 and #53 — bisect by REMOVING LATER LINES, never by staring at the
named one. It is the `reportRunAbandoned` mark item already standing on Tony's list.

**THE BISECT, one variable per run, on a `cp` of the tester patched two lines (bear-trap #43):**

| run | change | result |
|---|---|---|
| parent | none | **ABANDONED** at the define |
| **A** | `"/" "*"^` **and** `"/" "/"^` | **PASSES** — the whole file parses, `skipTester()` fires |
| **B** | `"/" "/"^` only (LineCommenT) | **PASSES** |
| **C** | `"/" "*"^` only (BlockCommenT) | **ABANDONED**, unchanged |
| **D** | `"/" "/"` — no `^` | **PASSES** |

**So the sole blocker is the two-character literal `"//"` in `LineCommenT`.** Run B is the
minimal fix and run C is the control that proves `"/*"` was never the problem. `"*/"` was left
alone throughout and never needed changing — the (b) half of the dispatch is answered by not
having to act on it.

**Reduced further, outside the tester:** `LineCommenT "//" ...` fails **alone**, in a
three-line define, with `RunRulE: expected a method not LineCommenT`. `"XX"` passes, `"/"`
passes. It is the adjacency, not the character and not the position.

**Three spellings get past it** — `"/" "/"`, `"/\/"`, `"\/\/"`. **Prefer `"/" "/"^`**: two
one-character literals are unambiguous about what they match, where an escape inside a literal
is a second question about how the escape is stored. The `^` is **not needed to parse** (run D)
and is kept because it is the noSkip that stops the skipper eating between the two slashes —
**which is a match-time claim and is NOT measured here.**

⚠ **WHAT IS STILL OPEN, and it is the real question: getting past the DEFINITION is not the
rule WORKING.** Nothing above drives `LineCommenT` against an actual `//`; the tester's
`skipInput` carries `/* */` and no `//` at all. The next stroke is a fixture that feeds it one.

⚠ **AND THE OUTPUT ON A PASSING RUN IS ITSELF A FINDING TO CHASE LATER, NOT A WIN:**

```
Did the definnition work?   "what" /* has /* embedded */ comment*/ NotSkipable
```

The value comes back **whole, comment text included**. That is `(...#)` doing its job and says
nothing yet about whether `checkSKIP` would have skipped it — the rules are defined in
`Grokking` but nothing has routed a skip through them.

## 2b. LANDED 2026-09-18 — the escape form, and the wall behind it

**THE SPELLING IS `"/\\/"`, AND THE ONE LINE OF WHY: it escapes only the character that has to
stop being adjacent, and it yields a SINGLE literal term matching both characters — where two
one-character literals yield TWO terms, and a term boundary is a skip point.**

**MEASURED, not chosen** (`incant/pop/skipT`, rows SK-1 and SK-2, driven on a real line comment):

| spelling | terms the rule carries |
|---|---|
| `"/\\/"` | **one**, reading `//` |
| `"\\/\\/"` | one, reading `//` — identical, and escapes a character that needs no escaping |
| `"/" "/"` | **two**, each reading `/` |

**The two-literal form is not a synonym, it is a different rule.** Terms are where the skipper is
entitled to run, so that spelling would accept a slash, a space and a slash. Nothing in the run
distinguishes them until it does, and then it does so silently — which is why the contrast is
pinned rather than noted.

**Tony's `IncantForms/WorkingOn/tester` now runs**, with the respell on `LineCommenT` alone and
the reasoning in its dead region.

### ⚠⚠ WHAT THE DRIVE COULD NOT PIN, AND IT IS STATION 6's WALL

The dispatch asked for the rule to be driven against a real `//` and **pinned on what it
consumes**. It was driven. **What it consumes is not readable today**, and the run says why in
its own words:

```
checkInput: no enclosing activation to take the label
```

A rule driven standalone mints a label with nowhere to go, so afterwards **its terms still read
their own DEFINITIONS** — `commentBody` comes back as `commentBody=` plus the newline it was
defined with, not as the comment text. **That is fixIts F-83 arriving through a second door.**
SK-5 pins the wall: the term dump is byte-identical before and after the drive.

⚠ **AND FOUR ROUTES TO AN OBSERVABLE WERE TRIED AND ALL FAILED, recorded so nobody re-walks
them:** reading `commentBody` after the call; moving the `}` from the data to the label
(`commentBody}="\n"` — no change, so the modifier's placement is not the issue); adding `^` to
the literal and to the body (no change); and giving the rule a `code=` action so a match would
announce itself — **which does not fire even after `compile` and `setParse`**, because a rule
fired standalone never reaches the arm that runs it.

⚠ **AND THE SECOND HALF OF THE WALL, which matters more for the campaign than the first: NOTHING
ROUTES A SKIP THROUGH THESE RULES.** The live skipper is the C++ `checkSkip`; `sKIP` and
`checkSKIP` are Grokking rules that no machinery calls. So what this fixture certifies is that
the rule can now be **written and driven** — the step that was blocked — and not that it works.
**No C++ `checkSkip` was touched, as ruled.**

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

## 8. RECON 2026-11-02 (SEQ 511 R1, Clod, read only) -- what checkSkip does today and what SKIp would carry

Context since this card was drafted: the 2026-11-01 ruling (macros, standing rulings) -- on the NEW road checkSkip becomes a
kant rule SKIp whose action keeps the indent stack and hands up INDENT / DEDENT; kantGrammar spells BLOCk as `{ }` or
INDENT ... DEDENT; **the old road's checkSkip stays untouched.** And the 2026-10-29 rule: no meaning carried in C++ flags.

**Method.** The jobs below are read from `GroupRules.twk` checkSkip (:139-249) and its one call site, `RuleStuff::inputAt`
(RuleStuff.twk:61, :64: before every term that does not carry `^`). "Who relies on it" is MEASURED: an env-gated tap in the
generated `GroupRules.mm` switched each job off by name (one build), pop.sh ran once per job against an untapped run that
read row for row with the bought trunk (2420), and the tap was then reverted and the binary checked byte-identical. Rows
are pop.sh's.

| # | job | where | rows that rely on it (tap off) |
|---|---|---|---|
| J1 | skip space, tab, newline, CR (`skipSet` = ` \n\r\t/`, GroupMain.twk:86); count `sourceLINE` | :152-158 | everything (not tapped -- the parse) |
| J2 | `//` line comment, to end of line | :163-167 | **the whole fleet: 2420 -> 132** (setup, grammar and utilities carry `//`) |
| J3 | `/* */` block comment, NESTED (a count) | :168-200 | **the whole fleet: 2420 -> 132** |
| J4 | `/#` ... `#` | :172-176 | **none -- row for row.** (It also stops ON the closing `#`, which is not in skipSet.) cleanupList |
| J5 | track indentation: `lastINDENT`, the `stacked` nodes on `blockSTAK` | :206-237 | carried by J6-J8 |
| J6a | indentation -> `{` / `}` rewrite IN THE INPUT BUFFER, gate `inCompile()` (old-road compile) | :222-224, :232-235 | **none alone -- masked:** processCode sets the name owner too (SEQ 502), so J6b's half carries every old-road body. See J6a+b |
| J6b | the same rewrite, gate `floorNameOwner()` (new-road body build, SEQ 504) | same | **6 rows:** whileT WH-8, newLocalT ML-1, newReturnT RT-4 and RT-6, newReturnSelfT RT-7, newCallBindT CB-4 |
| J6a+b | both halves off | same | **2420 -> 1971; 460 rows changed** -- the old road's multi-line action bodies; three fixtures TIMED OUT (loopBranchT, ctlStampT, ruleReturnT) and ifSeedT's interpreted twin HUNG uncapped (pop.sh:7197 runs it with no cap; killed by PID after 8 min). So J6a is load-bearing for the old road; it hid behind J6b because processCode raises both |
| J7 | indentation -> `:` / `>` rewrite, gate `defining` (every `define` block's members) | :215-219, :228-231 | **1979 rows** -- the fleet's defines |
| J8 | bookkeeping: `lastIndent` (read by drives, processCode, the `411` property, jit), `beforeSkip`, `lastSkip`, `noSkipping` | :243-248 | lastIndent: many readers; the other three: **0 readers** (cleanupList) |

The two parked anchors are directive entries on checkSkip (`Directives/groupDirectives:343, :347`, `stacked` and
`"if stacked"`), both disarmed (`ctive`); their bodies read `blocking`, which no `.twk` / `.rtn` declares any more, so
armed they would not compile -- dirCheck would name them DARK (bookkeeping, not a finding).

### What a kant SKIp can carry, and what stays C++

**Carry (new road only):** J2, J3 and J5/J6b's meaning. SKIp's alternatives consume `//` and nested `/* */` and hand up
nothing; its indentation alternative reads the run's column against an indent stack that is SKIp's own data (a list of
counts on a kant field, not `blockSTAK`) and hands up INDENT, DEDENT (one per level closed -- several at once is a list),
or nothing. **The gates go away:** whether an INDENT opens a block is the grammar's -- BLOCk takes `{ }` or INDENT
STATEMENt+ DEDENT, and a rule that does not name INDENT never meets one (FILe at the top level = ML-3's answer: no road
rewrites there). That is the 10-29 rule satisfied: no `inCompile()`, no `floorNameOwner()`, no text written into the
buffer.

**Stays C++:** the old road's checkSkip whole (ruled) -- so J6a and J7 (defines are always the old road's) and J4 stay
where they are; the bootstrap (kantGrammar itself is loaded through the C++ skip -- §3's bootstrap fact); the character
scan primitives SKIp's rules are made of; `sourceLINE` (a count the error reports read, not a meaning). **And one seam
needs a ruling, because it is where SKIp runs:** (a) the engine's `inputAt` calls SKIp for a kant-grammar term instead of
checkSkip -- one C++ seat, the term's grammar decides, `^` still means "no skip"; or (b) SKIp is an explicit term in the
grammar wherever whitespace may fall -- no C++ seat, but every rule spells it. Option (b) is the purer reading of 10-29
and much the larger grammar change; (a) is a dispatch, not a meaning, and is Clod's recommendation.

### KANT-40 / F-86 and braceInCode are NOT checkSkip, and fall outside SKIp's reach

They are one mechanism, and it is `aCTionCodE` (ruleActions.rtn:187-192): a `code={ }` body is captured from its `{` to
the FIRST `}` -- no nesting count, no quote or comment awareness. Measured today, three arms, one define each:
`print 7:;` -> fine; `print "}":; print 7:;` -> the define dies (`RunRulE: expected a method not bqA`, the define's first
healthy action -- bear-trap 32's misdirection) and the file is ABANDONED; `print "{":; print 7:;` -> fine. So a `}` in a
comment (F-86), in a string, or closing a braced block (braceInCode) all end the body. checkSkip never runs inside the
capture. **The cure is aCTionCodE's scan** -- count nesting, step over quotes and comments -- an old-road C++ change of
its own, independent of SKIp. SKIp reaches it only under §3's "second customer" design (aCTionCodE routing through the
same primitive), which the kant rule cannot serve at bootstrap, because aCTionCodE captures the kant rules themselves.

### Proposed shape (unbuilt)

```
SKIp            SKIPPEd+;                        -- new road; called at inputAt for a kantGrammar term (seam (a))
SKIPPEd
    LINECOMMENt     "//" lineBody="\n"};          -- hands up nothing
    BLOCKCOMMENt    "/*" ... "*/"                 -- nests; card §2's EmbeddedCommenT shape
    LAYOUt          [ \t\n]+                      -- action: column vs SKIp's stack -> INDENT | DEDENT list | nothing
BLOCk           leftCurly="{"- STATEMENt+ rightCurly="}"-  |  INDENT STATEMENt+ DEDENT
```
Open, carried from the 11-01 ruling: blank and comment-only lines (no layout change -- the C++ resets on a block
comment's close), tabs = 4, end of input closing every open level.

### Certificate rows (unbuilt) -- `incant/pop/newSkipT`, the old road the control where one exists

| row | text | intended |
|---|---|---|
| SK-1 | a `//` line between two statements of a new-road body | both run |
| SK-2 | a nested `/* /* */ */` between two statements | both run |
| SK-3 | ML-1: a two-line indented arm under a false if | only the line after it |
| SK-4 | two levels closed at once (RT-4's loop-in-loop, then a statement at the body's level) | runs once, after both loops |
| SK-5 | a blank line and a comment line inside an indented arm | the arm does not end there |
| SK-6 | ML-3: the top level | no block made, as today on both roads |
| SK-7 | a `{ }` block inside an indented arm | both spellings close where written |
| SK-8 | a tab-indented arm against a 4-space one | the same blocks |
| SK-H7 | SKIp's INDENT removed; then J6b's checkSkip half removed with SKIp in place | the first takes SK-3/SK-4 and the six J6b rows red by value; the second leaves them green (SKIp, not checkSkip, carries them) |
