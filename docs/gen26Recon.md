# gen26 recon -- why 11 of 26 disagree (SEQ 416, 2026-10-25, seal 215's binary)

Read-only. Nothing built, no fixture or source changed; every measurement is a scratch copy of a gen26 file or a
scratch repro, run on `~/bin/incant` at seal 215. Raw run: `jitLadder/jitterCensus/results/gen26.seal215.txt`.

**What gen26 compares.** For each of the 26 files in `results/genlist2` it writes two twins: `jitter;` (jitted) and
`jitterOff;` (plain, a no-op) on the line after the first top-level `Start();`. Both run under a 60 s alarm:

    INCANT_KLFILE=$n.plain perl -e 'alarm 60; exec @ARGV' $B $O/plain/$n > $n.o0 2> $n.e0
    INCANT_KLFILE=$n.gjit INCANT_JITTER_ERR=$O/$n.cerr perl -e 'alarm 60; exec @ARGV' $B $O/jit/$n > $n.o1 2> $n.e1raw

The `=== jitter: ` lines are dropped from the jitted stderr. Both stdout and stderr are masked (paths, `0x...`,
`i64 N`) and diffed. The file agrees if the masked diff is zero lines. The `.cerr` side file (what the jitter's
silenced first-call compile writes to stderr, `jitterReady`, jitEmitters.rtn:3802) is NOT compared. Today:
**agree 15 / DISAGREE 11, all 26 exit 0 on both roads.**

## The table

| file | class | first divergence (plain / jitted) | mechanism | evidence |
|---|---|---|---|---|
| opLenT | W | `=== jitDegrade count = 0 ===` / `= 152` (then compile 1/2, slot 0/32) | W1 | diff is counter lines only; `.cerr` = 152 degrades from `parser`'s build |
| probeDoorT | W | same, x6 | W1 | counter lines only |
| site1RoadsT | W | same, x8 | W1 | counter lines only |
| sweepT | W | same | W1 | counter lines only |
| tokJitT | W | same | W1 | counter lines only |
| baselineTestsNew | W | `callee testRecurF built as jit_testRecurF` / `REUSED as` (then counters 0/287) | W1 | `.jit`: jitter built `testRecursion` on its first call, so `testing()`'s later compile hits the cache |
| paReachT | W | `CAPFIRE fireLabelMethod first tokened=0` (stderr :129) / absent | W2 | stdout identical; PARSECLASS (the row's product) identical, 123 lines; of 11,553 plain-only lines 7,511 are in `.cerr`, 4,042 are run-time seat lines; 0 jitted-only lines |
| parserTest | W | `RULEDISPATCH walkRules ... arm=runAction` (stderr :479) / absent | W2 | stdout identical; 3,897 plain-only, all run-time seats (RULEDISPATCH, PPWRITE, BLOCKRESULT); 0 jitted-only |
| zeroWidthT | W, O | `BLOCKRESULT items=5 ... refused=0` (stderr :1912) / absent | W2 | stdout identical; 11,557 plain-only, 7,511 in `.cerr`, 4,046 seats; the jitted-only diff lines are the same lines reordered (multiset 0) |
| ruleOfT | W | `RULEOF nodes=1064` / `nodes=1065` (and `parser terms=6` / `7`) | W3 | `dumpField` on scratch copies: the extra node is a `JiT=` IR record attribute, on `roParse` after its jitted run and on `parser` after `parser(Start)`; plain has none |
| halfLessT | **V** (plain wrong) | `HL old 0.5<1 0 ... 1.5<2 0` / `0.5<1 1 ... 1.5<2 1` | V1 (NEW) | scratch repro, below |

No R row: the NOT JITTABLE announcements are `=== jitter: ` lines, which gen26 drops. No PI-1 symptom.

## The mechanisms

**W1 -- the jit counters are process-global, and the jitter's compiles bump them.** `jitRunAction` prints
`jitDegrade / jitCompile / jitSlot count` as running totals. Under `jitter;`, the first call of an action compiles it
(silenced) and adds to those totals: `parser`'s build alone is 152 degrades, +1 compile, 32 slots. Every later
`jitRunAction` print (from `testing()` or `parser`'s own `builtinParseR` run) shows the inflated totals, and the plain
twin doesn't. No value moves. baselineTestsNew's built/REUSED line is the same fact: the jitter already compiled the callee.

**W2 -- trace witnesses live on the interpreter road.** The armed callouts (`traceParse()`, measureRuleDispatch,
PPWRITE, BLOCKRESULT, CAPFIRE ...) fire in processCode, runOP and aCTionBlocK. On the jitted road, (i) the callee
bodies (`generateParse`, `walkRules`, `compileRules`) are parsed during the silenced first-call compile, so their
trace goes to `.cerr`, which gen26 doesn't compare. Measured with `traceParse()` moved first in scratch copies: plain
has 3 processCode pushes (`generateParse`, `cout "Gene...`, `compile(ar...`) that the jitted road lacks. (ii) Inlined
calls never pass runOP, so no RULEDISPATCH (generateParse 156 / 0). The work itself is the same: 156 "Generating parse
code" lines and 64 "compile succeeded" lines on both roads, and stdout is byte-identical.

**W3 -- the census counts the JIT's own record.** `ruleOfCensus` walks the tree, and a jitted action carries a `JiT=`
attribute holding its IR.

**V1 (NEW) -- `compareValues`' number arm truncates the difference toward zero.** `GroupItem.twk:2129`:
`result = (int)(gNumber - group2.number);`. Any two numbers less than 1 apart compare EQUAL on the interpreted road.
The jitted road compares doubles (`jitEmitCompare`) and is right. Predictions written before the run, scratch repro
`hlRepro`:

| expression | predicted by the cast | read |
|---|---|---|
| `0.5 < 1.4` | 0 (diff -0.9 -> 0) | 0 |
| `0.5 < 1.6` | 1 (diff -1.1 -> -1) | 1 |
| `0.2 < 0.9` | 0 | 0 |
| `2.5 > 2` | 0 | 0 |
| `0.5 == 1` | **1** | **1** |
| `1 < 1.5` | 0 (count arm: 1 - 1) | **1 -- unexplained, not chased** |

So the defect is wider than `halfLessFalse` says: `==` and `>` on fractional numbers are wrong too. This is the fixit
`halfLessFalse`'s mechanism (its `where:` read "unknown").

**Checked and absent.** (b), an inlined callee's argument write (testPrecedence): testPrecedence is not in genlist2,
and no V here is an argument write. (a), the if-arm-to-join seed: no file shows it. PI-1: no print-buffer
difference. A build-time read of a run-time value: none.

## Tally

| mechanism | files | agree if cured alone | what the cure is |
|---|---|---|---|
| W1 global jit counters | 6 (opLenT, probeDoorT, site1RoadsT, sweepT, tokJitT, baselineTestsNew) | 21 / 26 | instrument: reset or exclude the jitter's own compiles from the printed totals, or mask the counter lines in gen26 |
| W2 trace seats | 3 (paReachT, parserTest, zeroWidthT) | 18 / 26 | instrument: compare with traces disarmed, or compare stdout only for armed-trace files |
| W3 JiT record in the census | 1 (ruleOfT) | 16 / 26 | instrument: the census skips `JiT` |
| V1 compareValues truncation | 1 (halfLessT) | 16 / 26 | engine: compare doubles without the (int) cast |

10 of the 11 are instrument text. The one value defect is on the plain road.

## SEQ 418 (2026-10-25): gen26 masks its own instrument text -- 26 / 26

gen26.sh now runs every captured stream through `nmask`: three named, exact patterns, one per class above, each with
a line count per road in gen26's output. W1 keeps the counter and callee lines and masks only the number
(degrade / compile / slot) or the word (built / REUSED). W2 deletes lines by exact leading token: RULEDISPATCH PPWRITE
DEFERABOVE OLDFIREFLAG fireLabelMethod CAPFIRE BLOCKRESULT attachLabel fireLabel LABELKIDS ACTFIRE DOTOPERANDS
ATTACHREPEAT MARKPT MARKARM FRAMEPROBE, `CAPTURE ORACLE-ABSENT` and `runRule DOOR`. Every one is printed only by a
parseTrace-gated or measure.twk callout. Not masked: a CAPTURE DIVERGE verdict, or a `runRule:` refusal. W3 masks
`nodes=` on RULEOF nodes lines and `terms=` on RULEOF XREG lines. The census's other fields stay compared.

**Known blind spot (W3):** a node-count change on ruleOfT's jitted road is no longer visible to gen26. pop.sh's
ruleOfT rows still read the plain road's counts.

Result (`results/gen26.seq418.txt`): **agree 26 / 26.** zeroWidthT's reordering lay entirely inside W2's lines.
No order difference remains once they are masked.

**H7.**
- A value changed on the jitted side only is reported with every mask in place:
  - halfLessT's `hlB = 7`: DISAGREE, diff 4.
  - `cerr "H7VAL" 1 / 2` before `stop()` in zeroWidthT, paReachT, ruleOfT and sweepT (the most heavily masked files):
    each DISAGREE, diff 2.
- Each mask removed alone puts its files back, with SEQ 416's diff sizes:
  - no W1: the six W1 files (28, 6, 36, 48, 282, 6).
  - no W2: paReachT 11913, parserTest 3897, zeroWidthT 12843.
  - no W3: ruleOfT 6.
