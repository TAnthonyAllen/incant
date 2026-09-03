# `iterate ... on *field` — the measurement, the blocker, and the respell list

**SEQ 145 items 1 and 4, measured 2026-09-03 on a bare build (`gNoUnwrap = 0`), canary 332, fleet 176/1/3.**
Read-only. Nothing was respelled and no fix was applied.

---

## 1. THE HEADLINE: R1's RULED SPELLING DOES NOT PARSE YET

`iterate grup on *argument;` **never reaches `aCTionIterate`.** The `Iterate` rule takes
`ANYtoken` in both slots and `ANYtoken=NamE` is a bare name, so a starred operand is not
admissible there. The statement falls through to `Xpress` and is parsed as an expression.

```
incant/grammar:181   Iterate   iterate- ANYtoken on- ANYtoken attributes? members? defer;
incant/grammar:116   ANYtoken=NamE;
incant/grammar:129   UnaryXP   UnaryOPS ANYtoken;      <- where *field lives, and it is not
                                                          reachable from the Iterate slots
```

**MEASURED, one run, one binary, one field, two rows one character apart** — and the marker is
shown PRESENT before its absence is read as evidence (bear-trap #44):

| row | statement | stderr |
|---|---|---|
| **A** | `iterate g on leafy;` | `aCTionIterate: source leafy has no list` — **marker fires, the action is entered** |
| **B** | `iterate g on *leafy;` | **silence — the action is never entered** |

`leafy` is a leaf with no list, chosen so that entering `aCTionIterate` *must* produce its
by-name refusal. Row A is the positive control; without it row B's silence would assert
nothing. Fixture: `minionWork/starParse2` shape, reproduced in one command.

⚠ **AND THE FALL-THROUGH IS UNBOUNDED, NOT MERELY WRONG.** With a following `while ++grup`
the mis-parsed statement runs away: `grup` never becomes an iterator, `++` takes opPlusPlus's
DATA arm (`if !data count = 1;` returns the node, which is truthy), and the loop never ends.
Measured: **219 MB of stdout in 20 seconds, no error, no exit** — killed by a wall-clock cap.
This is rule H5's class, and it is the scheduling hazard for item 4: **a respelled fixture run
against a bare binary is a hang, not a red row.** The respell and the grammar change cannot be
separated by even one commit.

---

## 2. THE WRAP DEPTHS — WHY THE FIX IS ONE-PEEL, NOT A GATE

`aCTionIterate` opens with `unWrap(input[1])` and `unWrap(input[2])`, and `unWrap` peels an
**unbounded** chain (`if isGROUP while isGROUP grup = group;`). `unWrap` was instrumented with a
hop counter, built bare, run against `IncantForms/WorkingOn/tester` unmodified, and reverted in
the same stroke (`Commands.rtn` md5 restored, canary 332 both sides).

| call | from | to | hops |
|---|---|---|---|
| input[1] iterator — **all three rows** | `ANYtoken` | `grup` | **1** |
| input[2] source — test1 `arg := argument` | `ANYtoken` | `sample` | **2** |
| input[2] source — test2 `arg = *argument` | `ANYtoken` | `arg` | **1** |
| input[2] source — test3 `argument` | `ANYtoken` | `sample` | **2** |

**input[1] is always exactly 1, and it is always the `ANYtoken` parse wrap — never a holder.**
**input[2] is 1 parse wrap plus N holder hops**, N measured at 1 (tests 1 and 3) and 0 (test 2).

⚠ **SO GATING THE `unWrap` CALLS OFF WOULD BREAK EVERY ITERATE, STARRED OR BARE**, because the
parse wrap must come off in all cases and it is indistinguishable from a holder to `unWrap` —
both are `isGROUP`. The shape R1 needs is **peel exactly one level unconditionally, and stop**,
rather than `while`. The `unWrap` call is not the thing to gate; its loop is the thing to
replace at these two call sites.

⚠ **AND THE REFUSAL MUST DISCRIMINATE.** R1 retires *the bare form on a holder*, not the bare
form. `iterate grup on sample` — a real field with its own list — stays correct and must keep
working. A refusal that fires on "bare" rather than on "bare **and** the operand is a holder"
would take out 25 of the 98 sites below that are not holders at all.

---

## 3. A BY-PRODUCT: `tester`'s THREE ROWS WORK FOR THREE DIFFERENT REASONS, AND ONLY ON THE FLIP

Tony's offline note reported all three `iteratorTest`s working. That is a **flipped-binary**
observation. On a bare build, measured the same run:

| row | mechanism | bare | flipped |
|---|---|---|---|
| 1 `arg := argument` | `unWrap` follows the whole chain, `arg` → `sample` | **works** | works |
| 2 `arg = *argument` | `setContent`'s `copyListFrom` gives `arg` its own COPY of the list | **FAILS** | works |
| 3 `iterate on argument` | `unWrap` follows one holder hop | **works** | works |

Row 2's bare failure, in its own words: `ERROR unary * on sample -- it holds no group`, then
`aCTionIterate: source arg has no list`. Under auto-unwrap, `runOP` has already resolved
`argument` to `sample` before `opDeref` sees it, so the star has nothing left to dereference and
`arg` is cleared. **The star and auto-unwrap are mutually exclusive, and row 2 is the row that
discriminates them.** Two of the three mechanisms are ones the campaign is deleting: row 1
depends on transitive following, row 2 on a content copy.

---

## 4. THE RESPELL LIST — 98 SITES, 40 FILES

Every `iterate <cursor> on <bare name>` under `incant/`. **Read-only. Nothing respelled.**

**H11 controls, declared before the count was read and both satisfied:** `incant/utilities` must
appear (it does, line 132), and the pattern must miss nothing — 98 lines match
`iterate X on`, 98 match with a trailing `;`, so there is no unmatched idiom hiding behind a
different surface form (rule H9).

|  | sites |
|---|---|
| **total** | **98** in 40 files (6 of them in `incant/attic/`, 0 in `incant/fixits/`) |
| on bare **`argument`** | **73** — 26 plain, 27 `members`, 20 `attributes` |
| on some **other bare name** | **25** |

**The 73 respell.** An action's `argument` is the holder by construction, so every one of these
is exactly the spelling R1 retires.

⚠ **THE 25 ARE A PER-SITE READ AND ARE NOT CLAIMED HERE.** They iterate bare locals — `trunk`,
`itTrunk`, `jpTrunk`, `holdR`, `fbFirst`, `k6big`, `k6small`, `sample`, `bag`, `pair`, `shape`,
`lines`, `npOut`, `btCur`, `juiTrunk`. Whether each needs the star depends on whether that local
is a holder or a field carrying its own list, and **no grep can answer that** — asserting
otherwise would be the census overclaim rule H9 exists to forbid. `incant/scopeProbe:60`
(`iterate spIter on sample`) is a known member of the stay-bare set.

### Per file

```
phaseProbe    7  (7 arg)     jitDfProbe     2  (2)      row8T        1  (1)
sixShapeT     6  (6)         iterT1m        2  (2)      jitJUi       1  (0)
kant8T        6  (2)         iterScratch    2  (2)      jitDrive     1  (0)
iterReuse     6  (6)         displayFormT   2  (2)      jitDegradeT  1  (0)
jitIterTwice  5  (0)         connectiveT    2  (2)      iterT1       1  (1)
iterT3        5  (4)         branchProbe    2  (2)      familyT      1  (0)
npAll         4  (2)         braceT         2  (1)      ddProbe      1  (1)
walkPhase     3  (3)         bothCensus     2  (2)      atypeT       1  (1)
parseClass    3  (3)         bisectQ        2  (2)      altShadowT   1  (1)
nameRecurse   3  (1)         anyOrNumT      2  (2)      scopeProbe   1  (0)
juiProbe      3  (0)         utilities      1  (1)
fixBisect     3  (2)         attic/jitDfIso2 2 (2)   attic/iterT2 2 (2)
f31           3  (2)         attic/npProbe   1 (1)   attic/jitIso3 1 (1)
shadowCensus  2  (2)         ruleCount       2 (2)
```

---

## 5. WHAT IS OWED, AND IN WHAT ORDER

1. **Grammar first.** The `Iterate` rule's two slots must admit a starred term before anything
   else in this arc means anything. Until then R1's spelling is inert and its `while ++` form is
   a hang.
2. **Then the one-peel in `aCTionIterate`**, per §2 — replace `unWrap`'s loop at those two call
   sites, do not gate the calls.
3. **Then the refusal**, discriminating holder from real field, per §2's last note.
4. **Then the respell**, utilities first, in the same commit as the grammar and the peel —
   never separated, per §1's hang.
5. **Item 4a's documentation** lands with step 2, naming the bare-on-holder form as retired.
