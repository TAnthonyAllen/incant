# TRIM CENSUS — PHASE ONE, READ-ONLY

**Run 2026-08-27.** Clay brief via Tony. **Razor holstered: nothing cut, moved or renamed.**
This file is a set of lists for review. Disposition is Tony's.

⚠ **NO FILE WAS RUN.** `~/bin/incant` is a dangling symlink — the Time Machine restore did not
carry `~/Library/Developer/Xcode/DerivedData/`, which does not exist at all. Every disposition
below rests on **citation and on text the files carry about themselves**, never on a measurement
taken today. Where a disposition would turn on running a file, the stop clause applied and the
file is parked in MAYBE with that note.

## ⚠⚠ THIS CENSUS WAS RUN TWICE. THE FIRST RUN WAS AGAINST A STALE TREE.

**Recorded rather than silently renumbered, because the episode is the finding.** The first sweep
ran against the restored working copy, which was **seven commits behind `origin`** — the restore
brought back a tree predating a whole session, including the **2026-08-28 seal**. Nothing was
lost: `origin` held all of it, and the only local-only commit was this document. The push was
rejected, which is how it surfaced. **No force was used; the census commit was rebased onto the
true head and the entire sweep re-run.**

**The delta, measured rather than assumed:**

| | stale run | true head | effect |
|---|---|---|---|
| denominator | 189 | **190** | `incant/trailingContinueT` added (`7a94fa3`) |
| KEEP | 140 | **141** | the new file is driven by `pop.sh` |
| MAYBE | 35 | **35** | unchanged |
| CUT-CANDIDATE | 14 | **14** | unchanged — **all 14 re-checked, none gained a citation** |
| fixit queue | 9, oldest `countInputInTmp` | **7, oldest `kantGenPath`** | two retired |

**Citation sources that moved under me:** `pop.sh` (+55 lines), `docs/wakeup.md` (+105),
`genLadder/countPop.sh` rewritten, `genLadder/countPopulation` and `minionWork/isRuleCensus` new.
Every one was re-swept. **No MAYBE row was promoted by the new citations and no CUT row was
rescued by them**, so the lists below are the true-head lists, not patched stale ones.

⚠ **THE LESSON IS THE ONE THE PROJECT ALREADY OWNS, ARRIVING THROUGH A NEW DOOR: re-measure
before you cite.** A census is an instrument, and this one was pointed at a tree that had moved.
It reported plausible, quotable numbers — 189/140 — and the only thing that caught it was a push
rejection. **After a restore, reconcile against the remote BEFORE measuring anything**, which is
rule H8's reconciliation law with the machine, rather than the working copy, as the thing out of
date.

## THE CORRECTIONS, AS APPLIED

**Correction A — the ghost fixture.** `censusScratch` **does not exist** and is not carried.
Confirmed by direct check (`ls incant/censusScratch` → No such file). `popScratch` is carried on
the NEVER-CUT list and resolves; `pop.sh:187` drives it (`run1 popScratch "$T/cen"`). This is the
third instance of cite-from-a-sealed-document-without-checking.

**Correction B — the missing citation source.** `jitLadder/ladder.sh` is in the sweep.
**Measured here: 41 `incant/` files are named by it and by nothing in `pop.sh`; 20 are protected
by it and by no other source whatsoever.** Without it those 20 would have defaulted to
CUT-CANDIDATE wrongly. (The brief's figure was 40; mine is 41 on the "jitLadder but not pop.sh"
reading. The one-file difference is a boundary-definition difference, not a contradiction — both
readings agree the population is ~40 and non-empty, which is the load-bearing claim.)

## DENOMINATOR RECONCILIATION — remainder zero

```
  incant/ entries on disk, depth 1            192
    less  incant/fixits/ (a directory)         -1   Tony's queue, 7 citizens, out of scope
    less  .DS_Store (gitignored, not a subject) -1
  ------------------------------------------------
  CENSUS DENOMINATOR                          190   = git ls-files, exactly; 0 untracked
                                              ===
  KEEP                                        141
  MAYBE                                        35
  CUT-CANDIDATE                                14
  ------------------------------------------------
  SUM                                         190   remainder ZERO
```

⚠ **One correction to the 08-27 seal's flag H**, which reads "all 190 files plus the 8 fixits are
tracked". At the 08-28 head the true figures are **190 tracked files + 1 gitignored `.DS_Store`**,
and **7 fixits, not 8** — `jsonListNotAList` was minted after that seal, then `countInputInTmp`
and `trailingContinue` retired in `ec7422a`/`7a94fa3`. The seal's substantive point stands: **the
untracked population in `incant/` is zero, so every cut is a commit.**

## METHOD

For each of the 189 files, whole-word match of the filename against every citation source. Bare
tokens as well as `incant/<name>` paths, because `jitLadder/ladder.sh` drives fixtures through a
variable (`$B "incant/$f"`) rather than through literals — the exact defect that made the seal's
first jitLadder comparison return 0.

**Citation sources, complete:** `genLadder/pop.sh` · `jitLadder/ladder.sh` · `genLadder/tree.sh` ·
`incant/frontier` · `minionWork/*` · `docs/wakeup.md` run recipes · the `.target` baselines ·
`incant/setup`'s `fILEs` registry · the remaining `genLadder/*.sh` instruments, recorded by name so
a protection resting only on a non-briefed source is visible rather than silent.

## CONTROLS FIRED — per H11, pre-registered before the sweep ran

| control | expectation | result |
|---|---|---|
| `popScratch` appears, cited by pop.sh | must hit | **PASS** — `pop.sh:187` |
| `censusScratch` resolves | must MISS | **PASS** — absent, Correction A confirmed |
| jitLadder protects a large population none of pop.sh's rows drive | must be ~40, non-empty | **PASS** — 41 / 20 sole |
| every NEVER-CUT name resolves against the tree | must all hit | **ONE MISS — see below** |

## ⚠ STOP CLAUSE: ONE NAME DID NOT RESOLVE — reported, not substituted

**`incant/bytecode` does not exist.** It is registered in `incant/setup`'s `fILEs` registry
(`bytecode File='incant/bytecode';`, `incant/setup:327`) and was deleted from the tree at
`cc2fd2d`. **Nothing calls `include(bytecode)`**, so the row is inert today rather than broken —
but it is a live registry entry pointing at a corpse, and per bear-trap #28's fourth row a missing
registered include fails **at exit 0** with nothing downstream saying why.

⚠ **This is NOT a Correction-A-class stop.** `bytecode` is not on the briefed NEVER-CUT list — I
added it to the roll call myself, from the `setup` registry, because a registered includable is
infrastructure by construction. So the brief's stop clause is not tripped and I proceeded. **It is
reported here as the brief's owed INVERSE FINDING, and it wants a one-line fix that is Tony's
call: strike the row, or restore the file.**

## INVERSE FINDING — instruments citing files that do not exist

Full sweep of every `incant/<name>` path named by any instrument: **57 distinct names, 2 misses.**

| miss | named by | verdict |
|---|---|---|
| `incant/bytecode` | `incant/setup` fILEs registry | **real stale citation** — see stop clause above |
| `incant/probe2` | `genLadder/kantCensus.sh:30`, inside a comment | **not a defect** — historical provenance, and provenance stands. Recorded so nobody re-reports it |

## ⚠ FINDINGS THE REVIEW SHOULD SEE BEFORE IT READS THE LISTS

**1. THIRTY-EIGHT KEEP ROWS ARE PROTECTED BY A WAKEUP RUN RECIPE, AND FIVE MORE WERE PROTECTED BY
NOTHING BUT PROSE.** I split them, because they are not the same claim. A recipe written
`incant/<name>` is a command somebody can run; a bare mention inside a narrative sentence is not.
**The five prose-only files were demoted from KEEP to MAYBE** — `compileProbe`, `delimTest`,
`enumT`, `lessProbe`, `sinkProbe`. Each appears in `docs/wakeup.md` only as narrative (e.g.
`enumT` in an "F-22 sweep, listed and untouched" list, `lessProbe` inside a parenthetical count).
**No runner drives any of the five.** This is the brief's own warning applied literally: a
citation that cannot be executed is a mention, not a protection.

**2. `jitJC` IS A NAME COLLISION AND MUST NOT BE READ AS PROTECTED BY LADDER RUNG JC.**
`jitLadder/ladder.sh` has a rung whose output file is `$T/jc` — and the fixture it drives is
**`incant/jitDfProbe`**, not `incant/jitJC`. `incant/jitJC` is a separate, uncited 08-01
measurement file. A reviewer who matches the rung letter to the filename will protect the wrong
file and cut the live one. Both are listed, in different partitions, deliberately.

**3. `scopeUnits` IS A ONE-LINE-DIFFERING COPY OF `unitTests`, AND IT ROTS SILENTLY.** Its own
header states the contract: `diff incant/unitTests incant/scopeUnits` must show exactly one hunk
at `:153` and no other. `unitTests` is live and edited; nothing checks that invariant. It is in
MAYBE, but the real question for review is not keep-or-cut — it is **whether that diff still holds
today**, which cannot be asked before the rebuild.

**4. `genCount` AND `countScratch` ARE COUPLED, AND I HAVE GRADED THEM DIFFERENTLY ON PURPOSE.**
`countScratch` is the **only** consumer of `genCount` (`include(genCount)`, one site in the whole
tree). `countScratch` carries a documentary citation and so lands in MAYBE; `genCount` carries
none and so lands in CUT-CANDIDATE. **That inconsistency is real and is flagged rather than
smoothed over: cutting `genCount` alone breaks `countScratch`.** They are one decision, not two.
Note also that `genLadder/countPop.sh` does **not** drive `countScratch` — it drives
`minionWork/probeOne`.

---

# KEEP — 141

Named by at least one citation source, or on the NEVER-CUT list. Source column is what actually
matched; `wakeup` here means a recipe-shaped `incant/<name>`, never bare prose.

| file | cited by |
|---|---|
| `actionLocalT` | pop.sh |
| `altShadowT` | pop.sh, minionWork |
| `andProbe` | wakeup |
| `baselineTests` | pop.sh |
| `baselineTests.golden` | pop.sh |
| `bindSeamA` | pop.sh, smoke.sh |
| `bindSeamB` | pop.sh, wakeup, parked.sh smoke.sh |
| `bisectQ` | pop.sh, minionWork, wakeup |
| `bodyT` | wakeup |
| `bothCensus` | wakeup |
| `bothControl` | wakeup |
| `bracedK` | wakeup, smoke.sh kantRatchet.sh |
| `branchProbe` | wakeup |
| `concatT` | wakeup |
| `connectiveT` | pop.sh, decodePop.sh |
| `containerT` | containerPop.sh |
| `dblProbe` | wakeup |
| `ddGate` | ddPop.sh |
| `ddProbe` | wakeup |
| `ddProbe2` | wakeup |
| `decode` | minionWork, wakeup, decodePop.sh |
| `decoder` | frontier, wakeup, decodePop.sh, setupREG |
| `decodeT` | wakeup, decodePop.sh |
| `designDocs` | frontier, minionWork, wakeup, ddPop.sh decodePop.sh, setupREG |
| `directives` | minionWork, wakeup, setupREG |
| `displayFormT` | pop.sh |
| `divT` | wakeup |
| `dsFill` | formsPop.sh |
| `dsFillJ` | formsPop.sh |
| `emitAll` | wakeup |
| `f31` | pop.sh, minionWork, wakeup, odometer.sh |
| `fixBisect` | minionWork, wakeup |
| `flagT` | wakeup |
| `frontier` | frontier, minionWork, wakeup, decodePop.sh parked.sh odometer.sh smoke.sh |
| `genEmit` | wakeup |
| `generate` | frontier, minionWork, wakeup, kantRatchet.sh, setupREG |
| `generating` | wakeup, printPop.sh |
| `genMany` | wakeup |
| `genScratch` | pop.sh, wakeup, setupREG |
| `grammar` | pop.sh, minionWork, wakeup, printPop.sh, setupREG |
| `grammarOnTheFly` | wakeup, harnessCensus.sh |
| `hashProbe` | wakeup |
| `inlineSelfT` | jitLadder |
| `iterReuse` | wakeup |
| `iterScratch` | wakeup |
| `iterT1` | pop.sh, wakeup, TARGET |
| `iterT1m` | pop.sh, wakeup, smoke.sh printPop.sh, TARGET |
| `iterT3` | pop.sh, wakeup, TARGET |
| `jigcorpus` | wakeup, setupREG |
| `jiquery` | pop.sh, jitLadder, wakeup, harnessCensus.sh recordPop.sh smokelib.sh |
| `jitAttrPop` | jitLadder, wakeup |
| `jitDegradeT` | wakeup |
| `jitDfProbe` | jitLadder, wakeup |
| `jitDrive` | wakeup |
| `jitFalseT` | jitLadder, wakeup |
| `jitGifScratch` | wakeup |
| `jitIterTwice` | jitLadder, wakeup |
| `jitJ1` | jitLadder, wakeup, recordPop.sh |
| `jitJ2` | jitLadder, recordPop.sh |
| `jitJ3` | jitLadder |
| `jitJ4` | jitLadder |
| `jitJ5` | jitLadder |
| `jitJ6` | jitLadder |
| `jitJ7` | jitLadder, wakeup |
| `jitJE` | jitLadder, wakeup |
| `jitJF` | jitLadder |
| `jitJP` | jitLadder |
| `jitJPd` | jitLadder |
| `jitJPl` | jitLadder |
| `jitJR` | jitLadder |
| `jitJRL` | jitLadder, wakeup |
| `jitJRt1` | jitLadder |
| `jitJRt2` | jitLadder |
| `jitJRt2o` | jitLadder |
| `jitJRt3` | jitLadder |
| `jitJRt3o` | jitLadder |
| `jitJRt4` | jitLadder |
| `jitJU` | jitLadder |
| `jitJUi` | jitLadder, wakeup |
| `jitPrintT` | jitLadder, wakeup |
| `jitscratch` | wakeup |
| `jitSelfFn` | jitLadder, wakeup |
| `jitSlotT` | jitLadder, wakeup |
| `jitSlotT2` | jitLadder |
| `jitSlotT3` | jitLadder |
| `jitSlotT4` | jitLadder |
| `jitXand` | jitLadder, minionWork, wakeup |
| `jitXand2` | jitLadder, minionWork, wakeup |
| `jitXe2` | jitLadder, wakeup |
| `jitXmutual` | wakeup, mixed.sh |
| `jitXnest` | jitLadder, wakeup |
| `jitXor` | jitLadder, minionWork, wakeup |
| `jitXtemplate` | jitLadder, wakeup |
| `jsonTest` | pop.sh, minionWork, wakeup, smoke.sh |
| `juiProbe` | jitLadder, wakeup |
| `kant8M1` | wakeup |
| `kant8M1o` | wakeup |
| `kant8N` | wakeup |
| `kant8T` | wakeup, completePop.sh decodePop.sh |
| `kantLoop` | wakeup |
| `kantParse1` | wakeup, kantRatchet.sh smoke.sh |
| `kantRuleA` | wakeup |
| `kantRuleS` | wakeup |
| `litFlagProbe` | wakeup |
| `litProbe` | wakeup |
| `lookup` | frontier, minionWork, wakeup, decodePop.sh |
| `loopBranchT` | pop.sh, wakeup |
| `manyScratch` | pop.sh, wakeup, TARGET |
| `mintT` | wakeup |
| `nameRecurse` | wakeup |
| `oneTest` | pop.sh, minionWork, wakeup, completePop.sh smoke.sh, setupREG |
| `orProbe` | wakeup |
| `parseClass` | pop.sh, minionWork, wakeup, TARGET |
| `parseCode` | wakeup, kantRatchet.sh |
| `phaseA` | wakeup, gapB.sh |
| `phaseProbe` | minionWork, wakeup |
| `popScratch` | pop.sh, wakeup, kantCensus.sh |
| `printFamily` | wakeup, printPop.sh recordPop.sh, TARGET |
| `printFamilyNew` | wakeup, printPop.sh |
| `recordPT` | wakeup, recordPop.sh |
| `recordPT2` | recordPop.sh |
| `recordPT3` | recordPop.sh |
| `recordPT4` | recordPop.sh |
| `regProbe` | wakeup |
| `retProbe` | pop.sh, wakeup |
| `row8T` | minionWork |
| `ruleCount` | wakeup, kantCensus.sh |
| `setGroupInit` | wakeup |
| `setup` | jitLadder, minionWork, wakeup |
| `shadowCensus` | pop.sh, minionWork, wakeup |
| `showGen` | wakeup |
| `sinkT` | wakeup, printPop.sh |
| `spellScratch` | pop.sh, wakeup |
| `stringT` | wakeup |
| `termScratch` | wakeup |
| `trailingContinueT` | pop.sh, wakeup recipe (NEW at the 08-28 head — `7a94fa3`, promoted from the retired `trailingContinue` fixit) |
| `treeScratch` | tree.sh, wakeup, mixed.sh |
| `unitTests` | pop.sh, frontier, minionWork, wakeup, odometer.sh, setupREG |
| `utilities` | frontier, minionWork, wakeup, odometer.sh, setupREG |
| `vantage2x2` | wakeup |
| `walkPhase` | minionWork, wakeup |

---

# MAYBE — 35

⚠ **THIS IS THE REVIEW'S REAL AGENDA.** Not named by any runner, but carrying a claim to life.
Each row states the specific doubt.

## 35a — carried by a documentary citation (30)

The doubt these share: a `docs/` citation records that the file *was* used. It does not establish
that anything still needs it. Where the citing document is a live register the claim is strong;
where it is a finished recon the claim is provenance.

| file | what it exercises | the specific doubt |
|---|---|---|
| `limitT` | control for F-27, Tony's 08-19 ruling — a `maxLimit` write yielding zero/non-numeric is refused at the write | **strongest claim in this list.** Cited by `docs/fixIts.md`, a LIVE register. Looks like an uncertified regression test that should be in the fleet, not a trim candidate |
| `parensMin` | Parens localizer minimal specimen; argument printed from inside the action | **cited by CLAUDE.md itself** — bear-trap #26's fourth payment. Cutting it orphans a doctrine exhibit |
| `scopeUnits` | A/B oracle for the define-time name-search escape: `unitTests` ± one line at `:153` | see finding 3 — the question is whether the one-hunk invariant still holds, unaskable pre-build |
| `scopeProbe` | containment measurement for that same escape | recon complete; is the escape itself still open? |
| `jitXret` | E2 isolator — one value-returning callee, no conjunction | **E2 is a live known error** with rungs JE2/JXN asserting values because the degrade counter cannot distinguish sound from unsound fallback |
| `jitXseq` | two sequential value-returning callees — the deciding leg | same campaign; deciding legs are usually worth keeping until the campaign closes |
| `jitXcall` | action-invokes-another-action under JIT; genKantParse item 4 | same campaign, two docs |
| `jitXnot` | negation of a zero-valued field, interpreted only | header records a **corrected** finding (its first version asserted a fixture defect as a JIT finding) — the correction is the value |
| `jitJC` | jitted action calling another kant action, before `jitEmitCall` exists | see finding 2 — **name collides with ladder rung JC, which drives `jitDfProbe`** |
| `familyT` | ground check for the seven list-taking ops as the two-pointer write-back family | cited by `docs/jitDesign.md`; is the table arc still open? |
| `tableProbe` | does jitDesign premise 3's `dataNames[datA]` foundation actually execute | premise 3 is a settled premise that had **never been run**; that is a live question or a closed one, and the file cannot say which |
| `npAll` | R-1 noPrint census across the 78-rule population, registry-walking | R-1 measurement; superseded only if R-1 closed |
| `npFlag` | R-1 closing measurement, with its positive control first | carries an H4-shaped instrument worth copying even if the answer is banked |
| `invokeEprobe` | IA-3 anti-vacuity: does the `InvokE` rule ever fire | the install left the fleet byte-identical, which a never-firing rule also produces |
| `invokeMix` | IA-2 mixed alternation: generated `Parens` beside interpretive `Braced`/`UnaryXP` | IA-0's migration-unit question; alternation migration is live campaign ground |
| `liveProbe` | IA-4 census carrier — deliberately does nothing, proves the process reached the sentinel | a vacuity guard, cheap to keep, useless if IA-4 is closed |
| `flagProbe` | minionA INFERENCE I — flags declared in `setup` with no `opDot` case | is that inference still open |
| `bracedT` | minimal `Braced` firing fixture for an `aCTionBraced` breakpoint | a **debugging aid** for the live parse-generation arc, not an assertion |
| `braceT` | does a literal brace in a defining string body close the block early (Clay item 5b, 08-19) | recent, and it gates the minion report skeleton |
| `jiabsorb` | jigcorpus absorb POP — insert + persistence + dedup, working end to end | `jigcorpus` is still registered in `setup`; is the corpus arc live |
| `jidirect` | raw member operators (`+=`, `-=`, `IN`) against the live jigcorpus | same doubt |
| `countScratch` | sole consumer of `genCount` | see finding 4 — **coupled to a CUT-CANDIDATE**; not driven by `countPop.sh` |
| `listWalk` | cited by `bareLookupCensus` and `searchMinion` | two censuses, both finished |
| `sweepProbe` | same two censuses | same doubt |
| `regEnum` | cited by `bareLookupCensus` | same doubt |
| `sinkStderr` | is stderr reachable from incant with no C++ change (07-30) | **answered — `cerr` landed and is everywhere.** Kept in MAYBE only because `docs/kantCorpus.md` cites it; on the evidence this is a CUT that a citation is holding up |
| `json1` | early JSON fixture, 06-22 | two docs, both old; `jsonTest` is the live one |
| `jitIfScratch` | jit `if` scratch, 06-27 | cited by `docs/jit.md`; almost certainly superseded by the ladder's if/else rungs |
| `dirSample` | sample file, 06-15 | cited by `TODO.md` — a roadmap mention, so possibly future work rather than past |
| `changeWiki` | drafted wiki additions, 06-14 | **not a fixture at all** — prose. Cited by two recon docs. Doubt: did the wiki work absorb it, or is it still the draft |

## 35b — protected only by narrative prose, demoted from KEEP (5)

⚠ **No runner drives any of these.** They reached KEEP on a bare-token match inside `docs/wakeup.md`
and were demoted when the match was measured to be prose rather than a recipe. Listed separately
because the demotion is a judgment I made, not a fact the sweep produced.

| file | its only mention | the doubt |
|---|---|---|
| `enumT` | wakeup: "F-22 sweep, listed and untouched: `enumT`…" | listed as *untouched*, which is close to being told it is dormant |
| `compileProbe` | wakeup: a site list, `compileProbe` beside `walkPhase:129` | line-number citation, so it was read recently; nothing runs it |
| `delimTest` | wakeup: "exit 0, none session-caused: `delimTest`…" | named in a clean-run list, which protects nothing |
| `lessProbe` | wakeup: inside a parenthetical count beside `genEmit` | weakest claim of the five |
| `sinkProbe` | wakeup: "named `StatemenT` as the sinkProbe…" | narrative only; sibling `sinkStderr`/`sinkGraft`/`sinkGuard` are all in MAYBE or CUT |

---

# CUT-CANDIDATE — 14

Not cited by any runner, any document, `CLAUDE.md`, or `TODO.md`. Each row says what it was for and
why it is done. **`firstCallerNullList` is the doctrinal cover: deleting dormant machinery is the
safe direction, no eulogies owed.**

| file | what it was for | why it is done |
|---|---|---|
| `jitDfIso` | isolation probe: which compare in `displayForm` trips LLVM's "both operands to ICmp are not of the same type" | **its own header records the answer** — "RESULT: NEITHER OF THESE. Two candidates ruled out at no rebuild cost." Answered in place |
| `jitDfIso2` | follow-up leg: is the ICmp mismatch in the print path or the iterate/compare walk | same campaign, same day, answered |
| `jitIso3` | third isolation leg | same campaign |
| `npProbe` | first R-1 noPrint probe — attribute tags + `noPrinT` verdict on named rules | **superseded twice over** by `npAll` (whole 78-rule population, walks the registry instead of naming rules) and `npFlag` (adds the positive control). Both doc-cited; this one is the first draft |
| `sinkGraft` | grammar-minion round 1: add `cout` to incant's surface without touching a shared file | the sink question was answered and `cerr` landed; `sinkStderr` is the doc-cited survivor of the round |
| `sinkGuard` | same round: is `guard(WardeD)` load-bearing for a WardeD graft | same round, same closure |
| `affProbe` | one-shot: is `generator["gXpress"]` / `holder["hDark"]` `isMember` | answered at the time, **result recorded nowhere**, cited nowhere. 648 bytes |
| `dblProbe2` | 164-byte float-parse probe (`print + 3.5`) | sibling `dblProbe` is a live wakeup recipe; this is the offcut |
| `emitOne` | Phase B: run genParse on one rule, capture the emitted text | superseded by `emitAll`, which is a live wakeup recipe |
| `bracedMin` | `Braced` localizer minimal specimen, "gate OPEN" | superseded by `bracedT` (breakpoint fixture) and `parensMin` (the localizer exhibit CLAUDE.md cites); both doc-cited, this one is not |
| `cerrT` | fixture for the `cerr` statement keyword, 08-01 | **`cerr` landed and is used throughout the tree.** Uncited and uncertified — note the shape: the feature shipped and its fixture never joined the fleet |
| `jitPJ8` | PJ-8 survival fixture: the `JiT` record cleared at compile, written at capture, staleness detected | PJ-8 was ruled; nothing drives the fixture |
| `iterT2` | two actions, one calling the other, both naming `grup` — is the name per-instance or effectively global | siblings `iterT1`/`iterT3` carry `.target` baselines and `iterT1m` **retired by mapping**; T2 alone has no target and no citation |
| `genCount` | genParse's real-term counter in kant (minionA round 3) | ⚠ **PAIRED — see finding 4.** Its only consumer is `countScratch`, which sits in MAYBE. Cut them together or not at all |

---

## WHAT PHASE TWO INHERITS

- **Every cut is a commit.** Untracked population in `incant/` is zero.
- **Two rows are one decision:** `genCount` + `countScratch`.
- **Two rows want promotion, not deletion:** `limitT` (a control for a live `fixIts` row) and
  `cerrT` (a shipped feature whose fixture never joined the fleet) — opposite directions, same
  observation, which is that the fleet's membership and this directory's contents were never
  reconciled.
- **One stale registry row is owed a one-line ruling:** `incant/setup:327`, `bytecode`.
- **Nothing here can be confirmed until the rebuild.** Dispositions rest on citation and on what
  the files say about themselves.
