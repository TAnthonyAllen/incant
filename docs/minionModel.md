# THE MINION MODEL — a minion's deliverable is a DIRECTIVES FILE, not a diff

**For Clay. Written 2026-09-15, twentieth session, mid-session and against an uncommitted tree.**
Tony's design, Clod's build and measurement. Nothing here is sealed; the fleet numbers below are
live readings, not a seal.

---

## THE ONE-LINE STATE

**A comment minion ran end to end on `runOP` and the result is proven comment-only.**
191 lines to 170, three argument-blocks collapsed to three one-line pointers, and the code bytes
came back byte-identical by md5 through `genLadder/codeOnly.py`.
The whole change was expressed as **one kant directives file the minion owned outright** — it
never touched the tree. Integration is one command.

Fleet **302 green**, canary **329**. The arc this session: 294 (working-tree baseline) to 298
(bail) to 301 (directives repaired) to 302 (the split below).

---

## 1. THE MODEL, AND WHY IT BEATS THE ALTERNATIVES

Tony's proposal, and it is better than the two things Clod proposed before it.

A minion does **not** edit the tree and does **not** hand back a patch. It writes a **directives
file** — a small kant file of `fromThis`/`toThis` edits — which it clears first and fills as it
works, and which nothing else in the world touches. Integration is running it.

**What that buys, in order of importance.**
There is **no conflict surface at all**, because the minion never opens a tracked file for
writing. The `designDocs` nesting problem **dissolves**, and this is the part worth pausing on: a
problem record is a child of `ProblemRecords` and a comment entry is a child of `TokFiles`, so
there is no appendable fragment and a whole-file copy is the only drop-in — which is exactly the
clobber. A *text* insertion at an anchor does not care about nesting. And the artifact is
**readable before it is applied**, which a patch is not, and reviewable by Tony without running
anything.

⚠ **Two earlier proposals are superseded and should not be revived.** A `git diff` patch from a
worktree works and fails loudly on conflict, but it needs a worktree per run and it is opaque
until applied. A copy-out-and-overwrite of `designDocs` is the silent-clobber case above.

---

## 2. THE PROVEN RUN

Specimen: `runOP` from `GroupActions.rtn`, 191 lines, ten comment blocks, copied to
`Tests/runOPsample`. Three blocks picked, all of which **argue** rather than describe, so all
three moved under the ruled split.

| block | lines | key |
|---|---|---|
| seed gate | 10 | `GroupActions.runOP.seedGate` |
| passthrough why | 6 | `GroupActions.runOP.passthroughWhy` |
| slot count seat | 8 | `GroupActions.runOP.slotCountSeat` |

Result, and the inline form is the ruled one — claim first, key last:

```
-   /*  The seed gate must cover BOTH dispatch arms below, not just the
-       isOperator one. Unary operators are registered `unary ruleMethod=`
-       ... ten lines ...
+   /*  the seed gate spans isOperator AND isUnary -- widening it to isMethod
+       seeds an operand for every rule method   GroupActions.runOP.seedGate  */
```

**The proof is `codeOnly.py`, not an eyeball:**

```
code-only BEFORE:  79 lines  md5 70904ca2d8397c83055ddf75fbe6815c
code-only AFTER:   79 lines  md5 70904ca2d8397c83055ddf75fbe6815c
```

The whole generated artifact, which is the shape Tony asked for:

```
Start();
include(directives);

register(Directives);
define
    source="Tests/runOPsample";
    mv1 source fromThis="..." toThis="...   GroupActions.runOP.seedGate";
    mv2 ...
    mv3 ...
    ;

getFile(source);
replaceAt(mv1);
replaceAt(mv2);
replaceAt(mv3);
closeFile(source);
stop();
```

One command, from the repo root: `incant Tests/moveDirectives`.

⚠ **Running it twice is inert, and that is new.** On a second run every `fromThis` is gone, all
three refuse, and the file comes back md5-identical. Before this session a second run wrote three
payloads at the buffer head, silently.

---

## 3. WHAT HAD TO BE REPAIRED FIRST

`incant/directives` was written as a proof of concept with minimal testing, by Tony's own account.
It could not deliver a payload. Three defects, each fixed and each now carrying a fleet row.

**a. `toThis` inserted the literal string `toThis`.** The `:argument` hoist makes a **holder**, and
`+=` read the holder rather than what it holds — bear-trap #26's tag echo. Fix: `source += *toThis`.
This is not a workaround; bear-trap #50 already rules that a holder's later reads spell `*name`.
The file predates that ruling.

**b. `replaceAt` never found its match.** Same cause, same read: `if fromThis IN source` was
searching the buffer for the literal string `"fromThis"`. Fix: `if *fromThis IN source`.

**c. A miss WROTE ITS PAYLOAD AT THE BUFFER HEAD.** This is the one that mattered for generated
batches — one stale `fromThis` silently corrupted the top of the file, and in a probe it corrupted
mid-word. `getMarkLineAt` returned the testable nothing but never **armed**, so the caller carried
on. Its own header comment said exactly that and nobody had acted on it. Fix: a refusal on the
no-match arm, in `Instruct.rtn`. Blast radius is one caller, measured.

⚠ **THE FLEET WAS PINNING TWO OF THESE AS PROOF OF LIFE.** `pop.sh` pinned
`Did not find matchOnThis: in source` as a known defect and `toThis        print x:;` as its
anti-vacuity sibling — and that second pinned value **was** the tag echo. Both rows graduated
under H6 with the sentence, replaced by five that pin what the fixture's own header promises, plus
a miss pair. H7 control run: removing one star turns the replace row red.

---

## 4. FOUR CONSTRAINTS A GENERATOR MUST OBEY

None of these were written down anywhere. All four cost real time and all four fail silently or
misleadingly. They are now in `incant/pop/dirT`'s header.

**a. THE SOURCE FIELD MUST LITERALLY BE NAMED `source`.** The actions hoist it by that name
(`:argument source fromThis toThis`), so naming it `moveSrc` gives the hoist nothing and **every
directive misses**. This one cost four wrong hypotheses — ordering, needle length, comment versus
code, file size — and what killed them all was one A/B: the committed fixture with only the source
swapped, which matched immediately.

**b. `getFile` IS ONCE PER FIELD.** A second call reads the buffer **contents** back as a
filename: `getFile: could not open file: extern GroupItem runOP(...) : File name too long`. One
source field, one `getFile`, per run.

**c. `fromThis` MATCHES THE COMMENT'S INTERIOR, NEVER `/*`.** A `/*` inside a directive value is
**exit 138 with zero bytes of output** — bear-trap #27. Matching the interior and leaving the
delimiters in place is what *produces* the one-line pointer, so the constraint is the feature.
Multi-line `fromThis` works: a ten-line block is one directive, not ten.

**d. DIRECTIVE NAMES ARE `[a-zA-Z0-9]`.** An underscore breaks the define block and reports
`expected a method not replaceAt`, naming a healthy action — bear-trap #32's misdirection.

---

## 5. THE SPLIT, AND WHY `bail()` IS LOAD-BEARING

Tony's call: the generated file should carry the directives and nothing else, with the actions
coming from an include. Done.

`incant/directives` is now **definitions only** — `replaceAt` and `insertAt`, no driver, no
`Start()` — and includable exactly like `unitTests`. `incant/pop/dirT` is new, includes it, owns
the sample directives and the driver, and carries the sentinel. The fleet drives `dirT`.

⚠ **`bail()` is what makes this possible, and that was not the plan.** A definitions-only include
file cannot use `stop()`, which would exit the process of whoever included it. But
`incant/directives` carries a seventy-line usage guide that must stay unparsed. `bail()` ends the
file, keeps the prose dead, and hands control back to the includer. The verb was built this
morning for form files and turned out to be the thing that lets a library file exist at all.

**`bail` in one line for Clay:** registered in `incant/setup` against the **same** extern as
`stop`, told apart by the node handed in, which only works because an empty `()` stopped handing
on the `InvokeArg` wrapper. Fleet fixture `incant/pop/bailT`, four rows.

---

## 6. WHAT IS OWED, AND WHAT IS CLAY'S TO RULE

**F-67 — `where=before` inserts AFTER the matched line.** ⚠ **This is the one blocking real
batches**, because `insertAt` is how the DesignDocs half of a comment move arrives and its
placement is currently off by a line. Measured twice independently. There is a graded candidate
cause in the fixIts row — `getMarkLineAt`'s `if lineStart >= start lineStart++` is always true, so
the first line of a buffer is off by one — but it does **not** explain a mid-buffer match landing a
whole line late, so something else is in play and it is one measurement away.

**F-66 — delete is not expressible, and the shape is a ruling.** `replaceAt` documents that no
`toThis` means delete. It cannot, today: present versus absent `toThis` is undiscriminable —
`.data`, `.isGROUP`, deref-then-`.data` and a direct subscript all read identically, and only the
printed value differs, which is bear-trap #26's explicitly untestable case. Kant has no empty
string, so the options are an explicit `deleting` flag, a sentinel, or a separate `deleteAt` verb.
**Not urgent for comment moves**, where every removal legitimately carries a pointer as its
replacement.

**The designDocs half is unbuilt.** The run above did the `.rtn` side only. The second half is a
second directives run against a copy of `incant/designDocs`, using `insertAt` at an anchor — and it
is gated on F-67.

**The script Tony endorsed is unbuilt and is deliberately left for a ruling.** The shape discussed
was `genLadder/minion.sh <file> <method>`: echo the binary (H1), bank a pre-capture, fire
`claude -p` with the commentMinion charter scoped to that file and method, then retok, prove
comment-only via `codeOnly.py`, require fleet-unmoved, and report. **The open question is whether
it needs the worktree isolation at all**, and Clod's reading is that it does not: the minion now
writes a directives file and touches nothing, so the isolation that a worktree buys is already
bought by the model. A worktree would only be needed if the minion also *verified* by building,
which is a separate decision.

**⚠ Also unresolved and not Clod's call: the tree is uncommitted**, and this session's work is
entangled with Tony's in-flight comment sweep in `Commands.rtn` and `GroupRules.mm`. Tony chose
"commit everything together, naming both" and then held it for his own `stopParsingInput` edit,
which has since landed and is verified. The commit has not been made.

---

## 6b. THE UNCOMMITTED LEDGER — written 2026-09-15 so tomorrow reads it instead of deriving it

Tony's call: the commit waits for tomorrow's status report and a clean-kitchen pass.
**This table is what that pass needs.** Ownership is by hunk, not by file, and two files carry
both authors — which is why the commit cannot be split along file lines.

| file | whose | what |
|---|---|---|
| `Commands.rtn` | **BOTH** | Tony: comment shortened in `stopParsingInput`. Clod: the `bail` arm, in the SAME hunk |
| `GroupRules.mm` | **BOTH** | generated — the retok of both authors' `.rtn`/`.twk` edits |
| `Generate.rtn`, `RuleStuff.twk`, `incant/designDocs` | Tony | the comment sweep |
| `IncantForms/Windows/tree`, `wraplist` | Tony | form work. `tree` also carries the `bail()` test case |
| `ruleActions.rtn` | Clod | `handleCall` drops an empty `InvokeArg` |
| `incant/setup` | Clod | `bail` registered |
| `measure.twk` / `.mm` / `.h` | Clod | `measureStopCaller` |
| `Instruct.rtn` | Clod | `getMarkLineAt`'s no-match arm |
| `incant/directives` | Clod | definitions-only split, three operator fixes |
| `genLadder/pop.sh` | Clod | bail rows, directives rows, two graduated pins |
| `docs/fixIts.md`, `docs/commentTrial.md`, `docs/minionModel.md` | Clod | capture |
| `incant/pop/bailT`, `bailInc`, `dirT` | Clod | new fixtures, untracked |
| **support repo** `groups.ext` | Clod | `measureStopCaller` mirror line |
| **TOK repo** `project.pbxproj`, `Groups.xcscheme` | Tony | Xcode navigator and scheme toggles |

⚠ **`incant/designDocs` IS DIRTY AND BREAKS TWO INSTRUMENTS, AND IT IS NOT CLOD'S WORK.**
`ddPop.sh` reads **3 green / 3 red** against the working copy — sentinel missing, the walk finding
**zero records**, and its H7 negative control reporting that the gate certifies nothing. Against
`HEAD`'s copy of the same file it reads **5 green / 1 red** with the control working. So something
in the in-flight edit stops the file parsing. `include(designDocs)` fails outright, dying at
`DisplayDesignHTML` — which is bear-trap #32's misdirection naming the file's first and healthiest
entry, not the offender. **Not bisected; Clod was told to leave it.**

⚠ **`inArmsT` is the second instrument saying the same thing** — six rows green at HEAD and red on
the working tree, led by `inArmsT sentinel -- THE RUN TRUNCATED`. Also pre-dates this session's
edits. **Two independent instruments, one uncommitted change.**

⚠ **`decodePop.sh` and `countPop.sh` are RED and are NOT from either author.** Both were proven
pre-existing by measurement rather than assumed: `countPop`'s headline is byte-identical to the
session's opening baseline, and `decodePop` was re-run against a binary built **without** this
session's changes and failed identically at 14 green. Do not spend the clean-kitchen pass on them.

⚠ **`trigDO` flakes.** Its exit-138 appeared once in an opening baseline capture and not in 60
subsequent runs across two different binaries. It is intermittent, it is not this session's, and a
fleet count taken on the unlucky run reads two rows low.

---

## 7. WHERE THINGS LIVE

| file | what |
|---|---|
| `incant/directives` | definitions only — `replaceAt`, `insertAt`, then `bail()`, then the usage guide |
| `incant/pop/dirT` | the fixture: samples, driver, sentinel, and the four constraints in its header |
| `incant/pop/bailT`, `incant/pop/bailInc` | the bail fixture and its included companion |
| `Instruct.rtn` | `getMarkLineAt`'s new no-match arm |
| `genLadder/pop.sh` | seven directives rows, four bail rows, two graduated pins |
| `docs/fixIts.md` | F-65 (a mutating command called as `cmd()`), F-66, F-67 |
| `Tests/moveDirectives`, `Tests/runOPsample` | the worked run, gitignored, left in place to read |

**Worktree isolation, measured and then cleaned up.** Both repos worktree cleanly, `xcodebuild
-derivedDataPath` builds in isolation, and every harness already honours `${INCANT:-...}`, so a
fully parallel fleet run is available if it is ever wanted. The one wrinkle: the build needs
sibling support dirs — `Parse/`, `Frame/`, `KeyTable/`, `Include/` — symlinked beside the
worktree. `groups.ext` is the one surface that cannot be isolated.
