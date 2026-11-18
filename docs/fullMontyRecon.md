# The full monty: recon (2026-11-18, measure only)

**Goal (Tony, 2026-11-18):** tester (`Start(); show(firstLight);`) runs every action body on kantGrammar, with the kant
jitter on. A mix of native and testOP statements is the first cut; full native coverage comes later. The plan of record is
in `Topics/kant`, Plan. This file is the recon's evidence; nothing in it was built.

## Ten items between today and the goal (as measured)

1. **A body reader for the new road.** `processCode` reads every body through `driveStep` on `grokking/BlocK`, the old
   grammar's BlocK, by a fixed path, on the action's first run. The only new-road door is `compileIn` with
   `rule := KantGrammar["STARt"]`, called by hand per action (fixtures' `nlNew`). Choices named: a per-action mark; a
   per-registry or per-file mark; a global switch with no fallback; a global switch falling back to the old road
   (divergence). RULED: a per-action mark, no fallback (plan step 2).
2. **`string $...$`** does not parse on kantGrammar; the whole body is lost. Fixit `newRoadStringJoin`.
3. **The scope statement `=:argument a b c;`** (old grammar ScopeValue) does not parse on kantGrammar; the whole body is
   lost. Fixit `newRoadScopeStatement`.
4. **`for x in y; attributes / members`** is refused on the new road ("not built on the new road yet"); the statement is
   dropped. Fixit `newRoadForFilter`.
5. **A dotted read after another print item** (`cerr "a" x.taG "b":;`) is refused ("a list of adjacent operands is not built
   on the new road yet"); a lone dotted item prints. Fixit `newRoadPrintDotItem`.
6. **A file's top level on kantGrammar.** `search reset stack KantGrammar ...` does not change how a file's own statements
   parse (a road-proof print read `[     7 ]`, the old grammar, before and after show). The new road's top level is only
   `FILe("<text>")`. setup, utilities, styles, the form files and show's continuation all parse on the old file driver.
   A campaign; partly Topics/features 36.
7. **`jitter;` crashes tester.** Fixit `jitterCrashTester`, pinned not cured (ruled).
8. **The kant jitter on for every action.** `jitter;` sets `gJitter`, the old C++ JIT. The kant jitter is `kwCompile`
   (incant/kantJitter), called by hand on a new-road action. Turning it on means calling `krResolve` and `kwCompile` at
   the reader's door (plan step 4).
9. **Native coverage**: 16 of 125 top-level statements native on the 17 bodies that build (table below).
10. **New-road bodies answering as the old ones**: unmeasured; the bodies were built and compiled, never run on the new
    road. Plan step 3 does it per body.

## Step 1: tester on the new road

Through `FILe("print \"RP [\" 7 #5d \"]\":; show(firstLight); print \"RP2 [\" 7 #5d \"]\":;")`: both road proofs read
`[ 7 ]` (the new road), show deferred, loaded and drew, nothing refused, exit 0. The PDF equals the old road's byte for
byte once the two things that change every run are blanked: `/CreationDate` and `/ModDate` (to the second) and the
trailer `/ID`. Only that statement ran on the new road; every body and every included file parsed on the old grammar.

## Step 2: the 22 actions tester reaches, and whether each body builds on kantGrammar

Counted with a one-line trace directive in processAction (a directives build, retokked bare after, byte-identical):
22 distinct actions, 134 calls. Each body was driven through `compileIn` with `STARt`, one process each, with a control
(a name with no code refuses).

| action | calls | on kantGrammar | kant jitter, top-level statements native / testOP |
|---|---|---|---|
| resolveLook | 17 | builds; loses 2 (for-filter, dotted print) | 0 / 1 |
| mergeStyles | 16 | builds; loses 3 (2 for-filter, 1 dotted print) | 0 / 3 |
| drawText | 16 | builds clean | 7 / 18 |
| drawImage | 16 | builds clean | 0 / 2 |
| drawFill | 16 | builds clean | 0 / 1 |
| drawBorder | 16 | builds clean | 0 / 1 |
| drawKids | 8 | builds; loses 1 (for-filter) | 0 / 1 |
| frameMembers | 7 | FAILS whole body (=: scope) | -- |
| typeset | 5 | builds clean | 4 / 6 |
| fillDownAcross | 3 | builds; loses 2 (for-filter) | 1 / 5 |
| setLook | 2 | builds clean | 0 / 8 |
| setFrame | 2 | builds; loses 3 (dotted print) | 2 / 17 |
| tsBoxWarn | 1 | builds; loses 1 (for-filter) | 0 / 1 |
| showStage | 1 | builds clean | 0 / 6 |
| showSearch | 1 | builds clean | 0 / 8 |
| showForm | 1 | FAILS whole body (string $...$) | -- |
| showFinish | 1 | FAILS whole body (string $...$) | -- |
| show | 1 | FAILS whole body (string $...$) | -- |
| redrawForm | 1 | builds; loses 1 (dotted print) | 1 / 12 |
| placeForm | 1 | builds clean | 1 / 12 |
| frameWhole | 1 | FAILS whole body (=: scope) | -- |
| drawWalk | 1 | builds clean | 0 / 7 |

By cause: string $...$ 3 bodies; =: scope 2 bodies; for-filter 7 statements in 5 bodies; dotted print item 6 statements
in 4 bodies. A whole-body failure reports only the body's start, so each cause was confirmed on one-statement bodies:
`:%`, `**holder`, `cout`, `:= x["path"]`, `return;` and a lone dotted print item all build.

The native column: each body moved to the new road (`nlNew`'s recipe), then `krResolve` and `kwCompile`, and each
top-level statement's `KnaT` mark read (kantSlotT's `slMarks`). Compiled, not run. Totals: 16 native, 109 testOP.

## Step 4: the jitter today

`jitter;` then tester: show, showFinish, showSearch and showForm report NOT JITTABLE (compile returned -8) and run
interpreted; then the run dies at exit 139, `EXC_BAD_ACCESS` at `opAssign`'s `target->groupBody` with a null target. lldb
shows one frame (its caller is compiled code). The action trace's last entry is showForm, so the dying action is a
compiled one below it, entered without passing the interpreter's door. With utilities included first the run does not
crash (redrawForm, frameMembers, fillDownAcross and placeForm are then not jittable too): the crash is on the bootstrap
path. No statement ran native.
