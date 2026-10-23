<!-- Delegated read-only census (SEQ 404 R0), written by a sub-agent of the session and spot-checked by it: the dot triplet's two clear sites (J:927, J:749) and its absence from jitFlushTransient; gJitInlineFrames / gScSlots / gScEndBlocks cleared nowhere; jitFlushTransient's two call sites (J:299, J:829). Line numbers are trunk 61fb455c. -->

# Census 404: JIT state that can outlive one function build

Read-only. Tree: branch jit-unified-emit-wip at 61fb455c, measured 2026-10-23. Nothing was edited, built or run.
J = jitEmitters.rtn, GA = GroupActions.rtn, RA = ruleActions.rtn, H = jitContext.h.

## The two boundaries, as the code has them

- **Per function build** means jitBuildFunction (J:175). Its head does these, in order:
  1. `gJitComputedVal = nullptr` (J:189) and `gJitRTCursors.clear()` (J:191).
  2. It sets gJitBuilder, gJitCurrentAction, gJitCurrentFn, gJitBuiltFn, gJitBuiltName, gJitResult=null, gJitEmitted=false and gJitResultSlot (J:265-278).
  3. **`jitFlushTransient()` at J:299.** Its body is J:2825-2853. It nulls every node in gJitSeeded (jitData = nullptr), then clears gJitSeeded, gJitFrame, gJitFrameAssigned, gJitResult, gJitResultNode, gJitPrintBuf, gIfEndBlocks, gIfElseBlocks, gLoopCondBlocks, gLoopExitBlocks, gLoopBodyBlocks, gJitInlining, gJitArgBody, gJitArgSlot, gJitArgOrigin, gJitStmtMarks, gJitHandOver and gJitEpilogueBB.
  4. gJitEpilogueBB is created after the flush (J:311).
- **jitDiscardPartial** (J:822): erases gJitBuiltFn, calls jitFlushTransient again, and nulls gJitBuilder, gJitResultSlot and gJitEmitted.
- **Per compile** means jitRunAction (J:3763).
  - At entry, before the build loop: it sets gJitCtx and gJitModule (J:3793-3794) and clears gJitFnMap, gJitNeedOwnFn, gJitLocalKind and gJitKindRestarts (J:3812-3815).
  - At exit, after addIRModule: it nulls gJitCtx, gJitModule and gJitBuiltFn, clears gJitFnMap and gJitNeedOwnFn (J:4011-4014), and nulls gJitBuilder (J:4016, 4046) and gJitResult (J:4047).
  - The early returns (-7, cr<0, built<0, -8, -3) null gJitCtx, gJitModule, gJitBuilder and gJitResult only. They do not flush.
- A successful jitBuildFunction returns at J:560 **without nulling anything**. The -5 and -8 returns (J:413-415, J:528-530) null only gJitBuilder, gJitResult and gJitResultSlot.

## Population covered

1. **jitContext.h**: all 79 lines that start `inline` or `static`.
   - Six of them are helper functions, not state: jitLocalNonScalar :305, jitFnMapFind :526, jitCacheFind :544, jitterTallyFind :559, jitPendingHas :569 and jitFrameFind :646.
   - Lines :165, :174 and :175 each declare several ints.
   - The 7 `static` gChan* lines (:744-750) are at the foot.
   - The `class JitContext` (H, after :290) is declared and used by nothing.
2. **`static` in the .rtn files**: every hit of the grep `^\s*static|[;{]\s*static` over all `*.rtn`. That is J:572, 581, 1099-1101, 2716, 2941, 3590, 3603-3606 and 4075, plus GA:972. There are no other hits in RA, Instruct.rtn, Commands.rtn, Generate.rtn, genParse.rtn or Debug.rtn.
3. **`ruler->` / `groupRules->` writes in J**: all of them, from the grep `(ruler|groupRules)->X (=|++|--|+=)`.
   - GA's jitting arms (runAction :1160-1171, the runOP gate :1288-1312) write no ruler slot except `ruleArg.group`.
   - Instruct.rtn has no gJit* references.
   - groups.ext's GroupRules, GroupBody and RuleStuff externals declare no llvm type. The only JIT slots on GroupBody are the fnptrs gJitEmitter and gJitMethod.
4. **Maps, vectors and sets**: all of them in H.
5. **Every `jitData =` / `new JitData`** in all .rtn and .twk files.
6. **Every gJit*, gIf*, gLoop* and gSc* name**, grepped across all `*.rtn` (comment lines excluded).

## Rows

Columns: name | declared | writers | readers | cleared when | can hold an IR value?

### Core build state

| name | decl | writers | readers | cleared | IR? |
|---|---|---|---|---|---|
| gJitBuilder | H:36 | J:265 (=&B, B is jitBuildFunction's stack local); nulled J:413, 528, 833, 3831, 3858, 3879, 3903, 4016, 4046 | about 60 emitters in J (124 … 4361) | **set per build.** Not nulled on a successful build's return, so it dangles at the dead B until the next build or the compile's end. Nulled per compile. | YES (IRBuilder*) |
| gJitResult | H:42 | about 45 assignments in J (273, 689, 756, 1445, 1679, 2322, 4167, 4216 …), plus RA:116 | J:1782-1819 (GIF), 2528-2550 (SC), 4154, 4192, 4360, RA:138, 142 … | per build (J:273, flush J:2832); also per statement (jitStmtEnd J:756, jitPrintArm J:3219, many "clear before") | YES |
| gJitResultSlot | H:130 | J:277 (alloca); nulled J:415, 530, 834 | J:278, 485, 2469-2474, 2985-2988, 4360-4367 | **reassigned per build (J:277).** Not in the flush. Not nulled after a successful build. | YES |
| gJitEmitted | H:139 | J:276 (false), about 28 `= true` sites, J:835 | J:425 | per build | NO |
| gJitCurrentAction | H:471 | J:266 | J:2215-2216, 2422 | **reassigned per build. Never cleared.** | NO (GroupItem*) |
| gJitCurrentFn | H:472 | J:267 | J:2189, 2232, 2260 (jitEmitSelfCall) | **reassigned per build. Never nulled**, so it dangles into a dead module between compiles. | YES (Function*) |
| gJitBuiltFn | H:496 | J:271; nulled J:826, 4014 | J:825, 3860 | reassigned per build; nulled on discard and per compile. Not nulled on the -5/-8 returns. | YES (Function*) |
| gJitBuiltName | H:497 | J:272, 827 | J:3863, 3896 | per build (overwritten) | NO |
| gJitCtx / gJitModule | H:488-489 | J:3793-3794; nulled J:3830, 3857, 3878, 3902, 4001, 4011 | J:178-181, 249, 261, 514, 3846-3847 | per compile | YES (context/module) |
| gJitEpilogueBB | H:593 | J:311; flush J:2851 | J:447-449, 736, 2059, 2120, 2155, 2460 | per build (flush, then recreated at J:311) | YES (BB*) |
| gJitComputedVal | H:282 | J:189 (null), 1447, 2656; jitStmtEnd clearIf J:749 | GA:833 (refuseValueTarget) | per build (J:189) | YES |
| gJitRTCursors | H:622 | J:191 (clear), 1916 | J:1921 | per build | NO (GroupBody* keys) |
| gJitRestartNeeded | H:641 | J:633, 672, 2259 (true); 3853, 3869 (false before each build) | J:406, 3855, 3871 | per build (the caller resets it before each jitBuildFunction) | NO |
| gJitEmitWalk | H:633 | J:398-401 (save/set/restore); GA:771/775 (suspend/restore) | GA:802 | saved and restored around the walk | NO |

### Flushed per build

| name | decl | writers | readers | cleared | IR? |
|---|---|---|---|---|---|
| gIfEndBlocks / gIfElseBlocks | H:49 / H:63 | J:2895-2896 (push), 2929-2931 (pop) | J:729-730, 2911-2912, 2929 | per build (flush J:2835-2836); balanced stack | YES (BB*) |
| gLoopCondBlocks / gLoopExitBlocks / gLoopBodyBlocks | H:79 / 80 / 84 | J:860-862 (do push), 884-887 (pop), 3148-3149 (loop push), 3186-3189 (pop) | J:731-733, 871, 883, 1530, 1536, 3173 | per build (flush J:2837-2839) | YES (BB*) |
| gJitPrintBuf | H:239 | J:3485 (set), 3255 (null), flush J:2834, clearIf J:748 | J:3242-3251, 3282-3347, 3436-3445 | per build; also per print statement | YES |
| gJitResultNode | H:257 | J:1293, 1558, 1586, 1663 (set); 3219, 3446 (null); flush J:2833; clearIf J:748 | J:938-977, 1247, 1255, 3021, 3200, 3321-3327, 3392, 3416, 3436-3445 | per build; also per print item | YES |
| gJitFrame (JitFrameSlot.slot/ty) | H:386 | J:372 (push) | J:406, 477, 2433, 2442, jitFrameFind (J:351, 4238) | per build (flush J:2830) | YES (alloca, Type*) |
| gJitFrameAssigned | H:298 | J:1043-1044, 1229 | J:2435 | per build (flush J:2831) | NO (void* homes) |
| gJitArgBody / gJitArgSlot / gJitArgOrigin | H:393-395 | J:388-390 (prologue) | J:124-130 (jitArgSlotRead) | per build (flush J:2841-2843) | gJitArgSlot YES; the other two NO |
| gJitInlining | H:437 | J:3116 (push), 3005 (pop) | J:2071, 2132, 2219, 2422, 2455 | per build (flush J:2840) | NO (GroupBody*) |
| gJitStmtMarks (bb, last Instruction*) | H:629 | J:707 (push), 719-720 (pop) | J:718-760 | per build (flush J:2844); balanced per statement | YES (BB*, Instruction*) |
| gJitHandOver | H:620 | J:687, 706, 722, flush J:2845; RA:43 | J:686, 721, 781, 1009, 1792; GA:1288 | per build and per statement (saved in each mark) | NO |
| **JitData on nodes** (`->jitData`: jitValue, jitSlot, jitType; H JitData class after :290) | GroupItem.twk:15 (member). The copy constructor zeroes it: GroupItem.mm:151, 171, 193. | **Every** writer pushes the node onto gJitSeeded: GA:426-428 (jitCarryCopy); J:127-131, 1442-1444, 1503-1505, 1672-1674, 2044-2046, 2327-2329, 2651-2653, 2992-2994, 4212-4214, 4248-4249, 4268-4269, 4289-4290. setJitter on an already-seeded node: J:2666. | runOP gate (GA:413-415 `!arg->jitData`), J:925, 951, 1442ff, 3027-3031, GA:833, … | per build (flush J:2828 nulls every node in gJitSeeded); a rolled-back statement nulls its own (J:745-746). **After the final build of a compile the nodes keep their jitData until the next build's flush.** No reader outside a build was found. The header comment H:313-318 says "reset at the top of jitRunAction"; the code does it at each jitBuildFunction head, and jitRunAction has no clear of its own. | YES |
| gJitSeeded | H:320 | the push sites listed above | J:745, 2828 | per build (flush J:2829) | NO (node list; its nodes' JitData is the IR) |

### Stacks and slots NOT in the flush

| name | decl | writers | readers | cleared | IR? |
|---|---|---|---|---|---|
| gScSlots | H:113 | J:4165 (push, an entry-block alloca), 4189 (pop) | J:4187 | **never cleared.** A balanced push/pop inside jitEmitShortCircuitSlots (J:2545 Begin, 2555 End), with no return between them. | YES (alloca) |
| gScEndBlocks | H:112 | J:4166 (push), 4190 (pop) | J:734 (keep set), 4188 | **never cleared.** Balanced, as gScSlots. | YES (BB*) |
| gJitInlineFrames (exitBB, used, chanPushed) | H:469 | J:3124 (push in jitInlinePush), 2968 (pop in jitInlinePop), 3105, plus `used` set at J:2087/2137/2457 | J:735, 2077, 2087, 2133-2137, 2456-2460, 2966-2967, 3098 | **never cleared, by the flush or by a compile.** Balanced only by GA:1166/1170 (push, processAction, pop, all synchronous). The flush clears its parallel stack gJitInlining (J:2840) but not this one. | YES (BB*) |
| gJitBoundArg | H:468 | J:3018 (null at jitEmitArgBind entry), 3052 | J:2288 (jitEmitSelfCall, right after the jitEmitArgBind call at J:2287) | **never cleared** except at each jitEmitArgBind entry. Its one reader is always preceded by that reset. | YES |
| gJitDotSeeded | H:272 | J:1676; nulled J:927 | J:924 | **never cleared per build or per compile.** Cleared only when J:924's test matches and J:927 runs. Not in jitStmtEnd's clearIf. | NO (GroupItem*), but it is the key for the next two |
| gJitDotSeededVal | H:273 | J:1677; nulled J:927; clearIf J:749 | J:925 | **never cleared per build or per compile.** Only consumption (J:927) and rollback when gone (J:749) clear it. | YES |
| gJitDotProduct | H:274 | J:1678; nulled J:927; clearIf J:749 | J:924, 926 (then used in IR at J:943, 953) | same as gJitDotSeededVal | YES |
| gJitLastIsNode | H:263 | J:930, 939, 945, 967, 1278, 1343, 1559, 1587, 1669, 1771, 2450, 2514, 3023, 3219, 3322, jitStmtEnd J:757 | J:938, 966, 1247, 1255, 3021, 3321; GA:1299 | **not in the flush.** Per statement (J:757, 3219) and per consumer. | NO (bool), but J pairs it with the flushed gJitResultNode; GA:1299 reads it alone |
| gJitStmtCanRefuse | H:606 | J:688, 758, 1282, 3317, 3325; RA:49 | J:2076 | per statement; not in the flush | NO |
| gJitStmt / gJitStmtRTDone | H:611 / 612 | RA:27, 31, 66 (save, set, restore around each statement); J:2516 | RA:43; J:2516 | per statement (saved and restored) | NO |
| gJitStmtRTValue | H:615 | J:2356 (run time) | J:2366-2367 (consumed) | per read | NO |
| gJitFieldResident | H:290 | J:978, 1291 (insert) | J:3312 (decides the print path) | **never cleared, for the whole process** | NO (GroupBody* keys) |

### Per compile

| name | decl | writers | readers | cleared | IR? |
|---|---|---|---|---|---|
| gJitFnMap (body, action, fn) | H:524 | J:3849, 3861 (push) | J:526 jitFnMapFind (2184, 3825), 3875, 3991 | per compile (J:3812, 4012). Holds Function* of this compile's module **across builds on purpose** (callee targets). | YES (Function*) |
| gJitNeedOwnFn | H:567 | J:2248 | J:569, 3825-3841 | per compile (J:3813, 4013) | NO |
| gJitLocalKind / gJitKindRestarts | H:303 / 304 | J:627-631, 667-673 | J:409, 305, 3825 | per compile (J:3814-3815) | NO |

### Process-lifetime state

| name | decl | writers | readers | cleared | IR? |
|---|---|---|---|---|---|
| gJitCache | H:542 | J:4027 | jitCacheFind J:3768, 3842, 4026, 3715 | never (process) | NO (native fnptr + name) |
| gJitter / gJitterFn / gJitterTally | H:554 / 555 / 557 | J:3693, 3699, 3738, 3712 | GA:1187, J:3695 | never (process) | NO |
| gJitLastFn / gJitLastAction | H:150 / 154 | J:1110 area, 3728, 3771-3772, 4021-4022 | J:1109-1110, 2790, 3672-3676, 3717 | overwritten per compile; saved and restored by jitterReady | NO (native fnptr) |
| gJitProbeCarrier / gJitProbeFn | H:160 / 161 | J:1132-1133, 1139 | Generate.rtn:314-316 | per probe | NO |
| gProbeRuleFires, gProbeRuleTrue, gTermCallCount, gProbeVerdict, gProbeConsumed, gProbeLength, gProbeTerms, gProbeFires, gProbeTrue | H:165, 172, 174, 175 | J:1134-1149; GA:604; Generate.rtn:315, 318 | J:3571, 3633, 3655 | per probe | NO |
| gJitCompileOnly | H:168 | J:1106/1108, 3723/3725 | J:3773, 4028 | bracketed around each call | NO |
| gJitDegradeCount, gJitSlotCount, gJitSlotUnaryRefused, gJitCompileCount | H:182, 195, 210, 219 | J:782, GA:447, GA:439, J:3988 | prints | never (process counters) | NO |
| gJitLastIR | H:229 | J:3958 | J:2807, 3965, 3967 | overwritten per compile | NO (text) |
| gChanPendBody/Group/Data, gChanStkBody/Group/Data, gChanStkTop | H:744-750 | J:105 area (bind), 3066-3072, 3079-3083 — **at run time** | the same | never; a run-time stack | NO |
| GroupBody gJitMethod / gJitEmitter | GroupBody.twk:29 | J:2790 (gJitMethod = gJitLastFn) | J:2756-2762; GA:437, 1307, 1312 | never | NO (native fnptr) |

### Statics in the .rtn files

| name | site | holds | cleared | IR? |
|---|---|---|---|---|
| `gated[]` (two arrays) | J:572, 581 | operator fnptr tables, constant | never | NO |
| pcCarrier / pcFn / pcN | J:1099-1101 (jitProbeDrive) | carrier to native fnptr, process | never | NO |
| theJIT | J:2716 (jitEngine) | the LLJIT, which owns every compiled module | never (process) | it owns the IR moved into it; nothing reads it as Value* |
| done | J:2941 (jitInitOnce) | bool | never | NO |
| pRoot / pMsg / cNode / seen / cSeen / stk | J:3590, 3603-3606 (probeSweep) | char*/GroupItem* scratch; counts are reset per call | per call | NO |
| ifSeq | J:4075 (jitRunIfTest) | name counter; own module and own builder | never | NO |
| seen / bodyKey / bodyRoot / cap | GA:972 (ruleOfCensus, not JIT) | census scratch | per call (memset) | NO |

### ruler / groupRules slots written by the JIT

None of these holds an IR value:
- `branchKind` and `jitting`: J:291-292, 403-404, saved and restored around the walk.
- jitProbeDrive's `divertToRule`, `gParseActive` (pointer to the stack struct probeFloor), `branchKind`, `inputFloor`, `refused`, `lastIndent`, `defining`: J:1116-1155, restored before it returns.
- `refused`: J:3729.
- `chanBinds` / `chanSame`: J:109-110 (counters).
- GA's jitting arm writes `ruleArg.group = argument` (GA:1164), a GroupItem binding.

## SUSPECTS: hold an IR value, NOT cleared per function build

| # | row | the clear that does exist | can a value from function F be read while building G? |
|---|---|---|---|
| 1 | **gJitDotSeededVal + gJitDotProduct** (keyed by gJitDotSeeded) | consumed at J:927; rollback clearIf J:749 (only when the value was in the rolled-back tail). Nothing per build, nothing per compile. | **Yes, conditionally.** A dot whose product no `=` consumes (any `x.name` read) leaves all three set into G. J:924-925 then requires target == gJitDotSeeded **and** the target's jitValue == gJitDotSeededVal. The target's jitData was nulled by the flush and re-seeded with a new Value, so it can match only if LLVM reuses a freed Value's address: after jitDiscardPartial erases F, or across compiles once the old context is destroyed. That is the address-reuse hazard SEQ 365 named for gJitComputedVal. On a match, J:943 or J:953 emits a call using **F's gJitDotProduct** inside G. |
| 2 | **gJitInlineFrames** (exitBB) | none. jitInlinePop pops it (J:2968). jitFlushTransient clears its twin gJitInlining (J:2840) but not this. | Only if the GA:1166/1170 push/pop ever goes out of balance. Then J:2133-2137 (jitEmitReturn), 2456-2460 (jitEmitStmtRT) or 2077-2087 (jitEmitRefusedCheck) would branch G into F's exitBB. No unbalancing path was found; the pair is synchronous. |
| 3 | **gScSlots / gScEndBlocks** | none; a balanced pop at J:4189-4190 | Only if jitScBegin/jitScEnd go out of balance. Then J:4187-4188 would store into F's scSlot alloca and branch to F's scEnd. jitEmitShortCircuitSlots (J:2522-2557) has no return between the two. None found. |
| 4 | **gJitBoundArg** | reset to null at each jitEmitArgBind entry (J:3018) | No, as written. Its one reader (J:2288) runs right after that reset-and-set. It does keep F's last bound Value after every build. |
| 5 | **gJitResultSlot** | reassigned per build at J:277; nulled on -5/-8/discard | No, as written. No reader runs before J:277 in a build. It does hold F's alloca after a successful build. |
| 6 | **gJitBuilder** | reassigned per build at J:265; nulled per compile and on discard | No, as written. After a successful build it points at F's destroyed stack builder until the next build. No emitter runs between builds in the loop (J:3836-3870). |
| 7 | **gJitCurrentFn** | reassigned per build at J:267; never nulled | No, within a compile. Its readers are emit-time and come after J:267. Between compiles it points into a moved or dead module. |
| 8 | **gJitBuiltFn** | reassigned at J:271; nulled at J:826 and J:4014 | No. It is read only by discard (J:825) and by the loop right after a build (J:3860). It dangles after a -5/-8 return until the next compile. |
| 9 | **gJitFnMap** (fn) | per compile (J:3812, 4012) | **By design**, yes: G emits `call` to F's Function* (J:2184 → J:2286). Same module, so that is legal as a call target. It is not an instruction operand. |
| 10 | **gJitCtx / gJitModule** | per compile | By design: shared by every function in the compile. |
| 11 | **JitData on nodes** | per build, through gJitSeeded (J:2828) | No, provided every jitData writer pushes to gJitSeeded. All 13 writer sites found push. The copy constructor zeroes the member. The hazard is a writer that does not push; none was found. |

Not suspects, for the record:
- These hold IR but are cleared per build: gJitComputedVal, gJitResult, gJitResultNode, gJitPrintBuf, gJitEpilogueBB, gJitFrame, gJitArgSlot, gJitStmtMarks, and the gIf*/gLoop* stacks.
- gJitLastIsNode and gJitStmtCanRefuse survive the build but are bools. GA:1299 reads gJitLastIsNode without its flushed partner gJitResultNode, so a stale `true` from F changes a decision in G (behaviour, not an IR read).
- gJitFieldResident is never cleared, but its keys are GroupBody*.

## Could not resolve

- **Whether any path unbalances gJitInlineFrames or gScSlots/gScEndBlocks.** For example, a non-local exit (`stop()`/exit, a longjmp, or a refusal that unwinds) between GA:1166 and GA:1170, or between J:2545 and J:2555. No such path was found in the code read. No run was made to confirm it.
- **Whether jitRunAction can be re-entered while a build is in progress.** Its callers are testing() (Commands.rtn:575/577), jitProbeDrive (J:1107), jitFieldMethod (J:2780) and jitterReady (J:3724, run-time interpreted arm only, GA:1187). None was found running under `ruler->jitting` during a walk, but processCode at J:313 was not traced end to end. A nested compile would flush and overwrite every per-build global under the outer build.
- **gJitDotSeeded* address reuse** is possible in principle (freed Values after eraseFromParent or context destruction). Whether it happens in practice needs a run.
