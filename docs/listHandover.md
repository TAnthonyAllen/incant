# S6 hands over -- branch jit-list-handover (SEQ 392 R1)

Ruled (Tony, 2026-10-21, SEQ 392): R1 the build-time-read class in three strokes -- S6, then termCountT's argument, then
PI-1's print buffer. R2 S6's list arm hands its statement to run time through SEQ 384's machinery (jitHandOver, the
rollback, the jitStmtRT call) rather than degrading to nothing: a degrade that says "running INTERPRETED" must be true.
Recon: docs/jitter.md, "SEQ 391" and "SEQ 392".

## The cure, as designed (written before the build)

jitEmitBareRead's list arm (jitEmitters.rtn, the `token->groupBody->groupList` guard) calls `jitHandOver` instead of
`jitDegrade` and returns 0. The statement is marked handed: jitStmtEnd rolls back what it emitted and emits one jitStmtRT
call, which flushes the frame, runs the statement interpreted as its owner's, and reloads the frame (SEQ 384). The
follow-on degrades in the same statement (jitPrintList's "print operand part", aCTionBrancH's "return operand produced no
value") then fold into the hand-over -- jitDegrade returns early once gJitHandOver is set. Nothing else changes; no extern
added (canary 365 stays); no groups.ext change.

## Pre-registered movers (all under `jitter;`)

1. **jitArgListT** (new, born red at the branch point): the three calls `[ ] [ ] [ ]` -> `hasGroup 35 57` = the twin.
2. **jitPrintInlineT PI-0**: empty -> 46 (its row, pinned at today's empty, re-pinned with its sentence). **PI-1 unmoved**
   (the print buffer is a separate mechanism, stroke 3): still 0 lines.
3. **gen26 baselineTestsNew** (the generator files, `jitter;` after Start()): testARG prints its argument (three calls);
   printDefinition prints its argument (`sumple=...`, `wrap=...`); printTest's lefty `0` -> `46` -- so the 40-line diff
   SHRINKS (what remains is named). Agreement stays at least 14 / 26; any file that moves is named.
4. **pop.sh** otherwise row for row with the branch-point run; **jitLadder** row for row. Degrade counts: a statement that
   degraded twice (the bare read, then the part) now hands over once -- any row that prints a degrade count where a list
   read occurs is named if it moves.
5. **SEQ 388's 239-local classification**, rerun on the cure: predicted unchanged.

## H7 (cure committed first)

The degrade-only arm back: jitArgListT, PI-0, testARG, printDefinition and lefty return to their old values; restored
md5 = the cure.

## The certificate (branch: b7d376fe pre-registration, f299e40a cure; clone, 2026-10-21)

Built bare in the clone. Canary **365, unchanged**; the generated diff is the one call (jitDegrade -> jitHandOver) and its
comment. Branch-point binary: ~/bin/incant (the branch point's engine; the clone's own older builds predate SEQ 391).

| pre-registered | measured |
|---|---|
| jitArgListT `[ ] [ ] [ ]` -> `hasGroup 35 57` | **as registered** |
| PI-0 empty -> 46; PI-1 unmoved | **as registered** (PI-0's row re-pinned at 46 with its sentence; PI-1 still 0 lines) |
| pop.sh otherwise row for row; jitLadder row for row | **1611 green, only those two rows moved; jitLadder identical** |
| testARG and printDefinition print their argument | **true where they run** -- the W1 and W5 witnesses (printDefinition(sample) = the twin). In baselineTestsNew they are **never reached** (below) |
| **lefty 0 -> 46** | **FALSIFIED: still 0.** The list read now hands over, and `return lefty` runs interpreted -- but the compiled function's value is its result slot, which the interpreted return does not write |
| **baselineTestsNew's 40-line diff shrinks** | **FALSIFIED: 40 -> 94 lines.** The jitted run's stdout stops after printTest's line: testUnitTests (refused by the net, interpreted) **runs no statement after printTest()** -- simpleIF, testOR, testARG, ... printDefinition never run. Exit 0, its SENTINEL printed |
| gen26 >= 14 / 26 | **14 / 26**; baselineTestsNew is the only file that moved (above) |
| the 239-local classification unchanged | **unchanged** (84 / 155 / 0 / 0; `results/listHandover.raw` / `.table`) |

**THE UNFORESEEN MECHANISM, pinned on trunk as incant/pop/jitReturnListT (717c72f3) -- lefty's shape under an INTERPRETED
caller.** rlOuter (interpreted) calls the compiled rlT, which calls the compiled rlY, whose `return rlY` is a bare read of
a field carrying a list. **Trunk: exit 139** after "RL outer before". **This branch: exit 0, but rlOuter's block stops
after rlT() -- no RL-2 line -- and RL-1 is absent**; RL-3 (top level) prints. Twin: RL-1 46, both RL-2, RL-3. So S6's
hand-over turns a crash into a SILENT TRUNCATION of the interpreted caller: once the `return` statement is handed to run
time, its interpreted run (inferred, NOT traced) leaves the return's branch signal set past the compiled call -- the
interpreted block above it then stops as though it had returned -- and delivers no value into the result slot. **A
handed-over `return` is a statement SEQ 384's road does not carry yet.** This is the reason the branch should not be
bought as it stands, and it is named for Tony rather than chased (R3).

**H7 (cure committed first):** the degrade-only arm back -> jitArgListT empty on all three calls, PI-0 empty,
printDefinition(sample)'s `wrap=` empty, jitReturnListT exit 139 -- every witness back; restored md5 = the cure.

## SEQ 393 A -- the handed-over `return` (pre-registration, written before the build)

Ruled (Tony, SEQ 393): R0 the branch is not bought as it stands; R1 a handed-over `return` behaves as it does
interpreted -- it delivers its value as the action's result AND ends the compiled function.

**The shape holds (measured, tap in jitStmtRT, reverted md5-identical).** jitReturnListT on this branch: after
`statement.gMethod(statement)` for the handed-over `return rlY`, `ruler.branchKind` reads **3** and the call hands back
the **rlY node, count 46**. So the control slot IS written on this road, and the value IS reachable at the call -- it is
simply discarded ("Its value is not used"), and branchKind 3 is left set past the compiled call, which is what truncates
the interpreted caller's block. The earlier "(inferred, NOT traced)" above is now traced.

**The cure, as designed.** jitStmtRT keeps the statement's value. When the interpreted run left branchKind 3, it consumes
the slot (branchKind 0 -- the compiled function is the action's frame, as processAction's is), parks the value for the
emitted code, and returns **2** (0 = ran, 1 = refused, as SEQ 370). jitEmitStmtRT, after the reload: on 2 it loads the
value's count (followed through a holder, as aCTionBlocK does) into the result slot and branches to the exit -- an inlined
callee's exitBB, else the epilogue -- the same target selection its refusal exit and jitEmitReturn use. A bare `return;`
(the keyword node) stores nothing, so the slot keeps the prior statement's value, as aCTionBlocK's `result = prior`.
break / continue (branchKind 1 / 2) are NOT in this stroke and are left as they are. One extern added (the value read);
no groups.ext change.

**Pre-registered movers** (branch pre-cure binary, clone ddA0, 7493608f: pop.sh 1612 green, jitLadder PASSED,
gen26 14 / 26):
1. **jitReturnListT** (carried from trunk, rows born red here): exit 0 (stays 0), **RL-1 absent -> 46**, **RL-2 0 -> 2**
   = the twin. Three red rows -> green.
2. **gen26 baselineTestsNew**: printTest's **lefty `It returns 0` -> `It returns 46`**, and testUnitTests runs past
   printTest() -- simpleIF, testOR, testARG (three calls), testIndentBlock, stringTest, list, testInterpret, testUnary,
   testList, testGet, the testRecur* runs. **diff 94 -> 40 or fewer**, each remaining line named.
3. gen26 agreement stays >= 14 / 26; any other file that moves is named.
4. pop.sh otherwise row for row with the pre-cure run; jitLadder row for row. Anything else that moves is a finding,
   reported and not re-pinned.

**H7 (cure committed first):** the return's exit branch removed (the value stored, no branch) -> jitReturnListT red by
value; restored md5 = the cure.

## SEQ 393 A -- measured, and STOPPED (2026-10-22; clone; pre-cure ddA0 = 128f13bc's engine, cure ddA1 = a1c24b08)

Built bare; canary **365 -> 366** (jitStmtRTValueRT); the generated diff is the cure alone. pop.sh pre-cure 1616 green
(with the carried rows), cure **1615**; jitLadder PASSED, identical; gen26 **14 / 26** both.

| pre-registered | measured |
|---|---|
| jitReturnListT exit stays 0 | **MOVED 0 -> 139 -- the STOP.** Not the return: rlOuter now runs past rlT(), reaches its `rlLoc;` and crashes in aCTionXpress (a null ExpressioN label). That is a SEPARATE, PRE-EXISTING defect: an action the net refuses (-8) whose body has a bare local statement crashes when it runs interpreted -- probe `xpLoc` (below) exits 139 on ddA0, ddA1 AND trunk's ~/bin/incant; its interpreted twin is clean. jitReturnListT's own refusal device is that crasher, so trunk's 139 on this fixture is very likely this, not the return |
| RL-2 0 -> 2 | **as designed, but unreadable in the row**: under a tty both RL-2 lines print; the 139 loses the buffered stdout, so the row still reads 0 |
| RL-1 absent -> 46 | **FALSIFIED, and the pre-registration was wrong**: RL-1 is PI-1 (gJitPrintBuf one slot, R4), not the return -- rlY's own print runs inside rlT's print line. With that print removed, RL-1 = 46 on the cure; with it present, RL-1 drops on BOTH binaries (variant rlNoLoc, rlOuter compiled whole) |
| lefty 0 -> 46 | **as registered** |
| baselineTestsNew diff 94 -> 40 or fewer | **as registered: 28**; testUnitTests runs past printTest() (simpleIF ... testARG `hasGroup 35 57` ... testGet). All 28 are the testRecur* runs' witness lines: `REUSED` for `built` (the jitter built them first) and the cumulative jitDegrade / jitCompile / jitSlot counts; their `jitRunAction result` lines agree |
| nothing else moves | **true**: pop.sh's only mover is jitReturnListT's exit; gen26's only mover is baselineTestsNew |

**Variants (probes, not fleet):** `rlSilentNoLoc` (no RL-0 print, no rlLoc): pre-cure RL-1 46, RL-2 **0**; cure RL-1 46,
RL-2 **2** = the twin -- the cure's own witness. `rlSilent` (no RL-0 print, rlLoc kept): pre-cure exit 0, RL-2 0; cure 139.

**The registered H7 was NOT run: it cannot go red.** `return rlY;` is the callee's LAST statement, so removing the exit
branch changes nothing (H17). A real control needs a handed-over return MID-BODY, with a statement after it whose effect
shows; and the consumption of branchKind is the other half (removed -> rlSilentNoLoc's RL-2 back to 0).

**Open for Tony:** (1) the refused-action bare-local crash (`xpLoc`) -- a fleet row or a fixit, and whether
jitReturnListT keeps rlLoc as its refusal device; (2) RL-1 re-registered as PI-1's; (3) a mid-body-return fixture for
the H7.

## SEQ 394 -- Stroke A finished (pre-registration, written before the certificate run)

Ruled (Tony, SEQ 394): R0 the refused-action crash checked against F-129; R1 jitReturnListT's refusal respelled; R2 RL-1
re-registered as PI-1's, parked; R3 a mid-body fixture carries the H7. Stroke B waits on the buy (R4).

**R0 -- it IS F-129** (measured on trunk's ~/bin/incant): the same site (aCTionXpress, a null ExpressioN label, address
0x0) and the same trigger, a bare-name statement on its SECOND run: the interpreted twin of `xpLoc` calling xT() twice
exits 139. Under `jitter;` one call suffices because the net's refused compile walk is the first run; the same body with
`xLoc = 1;` compiles and runs clean. xpLoc becomes F-129's fleet row on trunk (xpLocT), pinned at 139.

**R1 -- a clean spelling exists.** rlOuter's `rlLoc;` becomes `print "RL-4 ... [" rlLoc "]":;` -- kindlessNetT's -8
refusal (a local read, never written), with no bare-name statement. Probe on both binaries: rlOuter still NOT JITTABLE
(-8) and interpreted; pre-cure exit 0, RL-2 0 (truncated); cure exit 0, both RL-2, RL-4.

**Pre-registered movers** (pre-cure ddA0 = 128f13bc's engine, cure ddA1 = a1c24b08; the binaries are unchanged):
1. jitReturnListT: exit 0 both; **RL-2 0 -> 2**, **RL-4 0 -> 1** (born red); RL-1 0 lines both, parked as PI-1's.
2. jitReturnMidT (new): **RM-1 99 -> 46**, **RM-2 99 -> 0** (born red); twin 46 0.
3. Everything else row for row; jitLadder identical; gen26 as SEQ 393 (14 / 26) -- the binaries are the same.

**H7 (on jitReturnMidT):** the return's exit branch removed (the value stored, then on to the next statement) -> RM-1 and
RM-2 back to 99; restored md5 = the cure.

## SEQ 394 -- the certificate (b8afc998 pre-registration; cure a1c24b08 unchanged; clone)

| pre-registered | measured |
|---|---|
| jitReturnListT exit 0 both | **as registered** |
| RL-2 0 -> 2, RL-4 0 -> 1 | **as registered** |
| RL-1 parked as PI-1's, 0 lines both | **as registered** |
| jitReturnMidT RM-1 99 -> 46, RM-2 99 -> 0 | **as registered**; twin 46 0 |
| everything else row for row | **true**: pop.sh 1624 -> 1628, the four rows above and nothing else |
| jitLadder identical; gen26 as SEQ 393 | the binaries are SEQ 393's (ddA0, ddA1), so SEQ 393's runs stand: jitLadder identical, gen26 14 / 26 |

Canary 366. **H7** (cure committed first): the exit branch removed (`CreateBr(exit)` -> `CreateBr(cont)` in the
stmtReturned block), rebuilt -> **jitReturnMidT RM-1 99, RM-2 99** -- red by value; restored md5 = the cure, bare retok =
the committed .mm. The buy is Tony's.
