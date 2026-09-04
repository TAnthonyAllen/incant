# C-156 — ITEM 4: THE `*argument` RESPELL — STEP 0 + STEP 1

**Branch `flip-argument`, cut 2026-09-04. Step 1 landed; C-156a applied.**
**Every number below states its arm in its section heading, never per row.**

---

## §1 SURPRISES FIRST

### ⚠⚠ S1 — THE RESPELL IS ARM-INDEPENDENT. THE DISPATCH'S PREMISE FOR CLASS (a) IS FALSIFIED.

C-156 says the respell *"is byte-identical under the flip and refuses bare, so it rides
with the flip and does not land on main from this stroke."* **It is byte-identical under the
flip AND byte-identical bare.**

```
  arm FLIP ON   before 128 green / 67 red      after 128 / 67        moved-set EMPTY
  arm BARE      before 191 / 1 parked / 3 red  after 191 / 1 / 3     moved-set EMPTY
  arm BARE, targeted run of the site under a 60s alarm:
                exit 0, prints all three members, sentinel present
```

The pre-registration said *"silent is the failure, refusal is the expectation."* **Neither
happened — it worked.** The mechanism is the 09-03 two-wraps split, already written down and
not re-derived: the parse hop is peeled **unconditionally**, and only the holder-follow is
gated on `gNoUnwrap`, so an iterate source's star is handled by `aCTionIterate` rather than by
the generic unary star that refuses on an already-unwrapped operand. **That is why this class
does not behave like C-154's `*x` in assign position**, and it is the whole reason the two
strokes read differently.

**Consequence, reported and not acted on: the (a)/iterate class may be landable on `main`,
which would remove the need for a flip branch for that class entirely.** Claimed for the one
site measured, not for all 113.

### ⚠⚠ S2 — THE SCOPE WAS UNDERSTATED BY 55%: CLASS (a) IS 113 SITES, NOT 73.

The 09-03 census was scoped to `incant/`. Over C-156's scope it is half again as large, and
the extra sites are exactly the ones the dispatch warned about (*"the first iterate respell
missed four"*).

| scope | class (a) `on argument` | class (d) other name |
|---|---|---|
| `incant/` | 74 | 26 |
| `minionWork/` | **35** | **17** |
| `genLadder/` | **4** | **1** |
| **total** | **113** | **44** |

### ⚠ S3 — MY FIRST CENSUS PATTERN OVERCOUNTED, AND THE CONTROL CAUGHT IT (H9)

A loose `iterate .* on ` gave **101** sites at `1932aaa` where that commit reports **98**.
The three extras are **prose mentioning the idiom**, not code. Requiring the line's first
non-whitespace token to be `iterate` reproduces **98 / 73 / 25 / 40** exactly, including the
26 plain / 27 members / 20 attributes split. **A delta computed with a different instrument
than its baseline is not a delta**, so the count below is on the corrected pattern for both
dates.

### ⚠⚠ S4 — `main` IS 648 COMMITS AND TWO MONTHS STALE, AND MY OWN RULING POINTED AT IT

C-156 says *"fresh branch from main."* **`main`'s tip is `b411ffa`, dated 2026-06-30, 648
commits behind HEAD, and it carries no `gNoUnwrap` at all** — so a branch cut there cannot
host step 1's flip-on before-capture. The branch was cut from the working trunk
`jit-unified-emit-wip` instead.

⚠ **And this falsified a ruling I had committed one commit earlier**, from C-154's closeout:
*"future try-and-buy branches are cut from `main` per stroke, so a branch is never older than
the question it is answering."* Cutting from `main` today yields a branch **two months older**
than its question — the ruling committing the exact failure it was written to prevent.
Corrected in both registers to name the working trunk. **The check was one
`git rev-list --count`, and nobody had run it** — the same family as bear-trap #3 and the
`ipc/` gitignore row.

---

## §2 THE CENSUS — corrected pattern, both dates, arm-independent (a static read)

| | 09-03 `1932aaa` | 09-04 HEAD | delta |
|---|---|---|---|
| total iterate-on sites, `incant/` | 98 | 100 | +2 |
| on bare `argument` (class a) | 73 | 74 | +1 |
| on another bare name (class d) | 25 | 26 | +1 |
| files | 40 | 41 | +1 |

**The entire delta is one file: `incant/iterRefuseT`**, minted 2026-09-03 with the iterate
re-rule and joined to the fleet in that seal. Per-file counts are otherwise identical.
H11 control declared before reading and satisfied: `incant/utilities:132` appears, exactly
where the 09-03 census said it would.

## §3 THE FOUR CLASSES, over the full C-156 scope

| class | what it is | count | disposition |
|---|---|---|---|
| **(a)** reaches the source | `iterate … on argument` | **113** | respell — 1 done, 112 owed |
| **(b)** asks the holder about itself | `argument.<prop>`, presence tests | **162** | READ AND LISTED, none respelled |
| **(c)** writes and binds | `:=` 30, `<-` 12, `argument =` 10 | **52** | listed with operator, none respelled |
| **(d)** other-name sites | `iterate … on <local>` | **44** | READ AND LISTED, none respelled |

### §3a Class (b) — the reads nobody has done, by property

```
  argument.taG          53      <- the big one; under the flip a holder answers with
                                   its OWN tag, so every one of these changes meaning
  argument.listLengtH   14
  argument.claims       11
  argument.datA          8
  argument.hasAttributeS 7
  argument.texT          3
  argument.isRulE        3
```

⚠ **These are not a respell population and must not be treated as one.** Each one has to be
read for what it is actually asking — *the holder* or *the source* — and grep cannot answer
that, which is the same refusal the 09-03 census made about class (d) and for the same reason.

## §4 STEP 1 — `incant/utilities`, landed as `53b107d`

**Arm: both, stated once — the sub-stroke was measured on the flip and on bare.**

One site, and it is the whole blast radius because every fixture includes utilities:
`incant/utilities:132`, `iterate grup on argument;` → `on *argument;`.

Also present in that file and **deliberately untouched**: 4 class-(b) sites
(`:10` `if argument.listLengtH;` · `:67` `argument.taG` · `:184` `.dIRECTion` · `:185`
`.tARGET`) and 4 class-(c) sites (`:184`/`:185` `:=`, `:386`/`:432` `<-`). No class-(d) sites.

Certificate: moved-set **empty on both arms**; canary **332**; no extern, no `groups.ext`
edit; `gNoUnwrap` 0 in the commit and verified **down behaviourally**, not by mtime.

## §5 C-156a APPLIED

Branch renamed **`flip-argument`**. `gNoUnwrap = 1` committed in source as its own one-line
commit `69f8148`; binary rebuilt to match and **verified up behaviourally** (a two-deep chain
prints `fcSrc`, a tag, where bare prints `SRC`, a value). `main` untouched at 0.

⚠ **Tony: an Xcode build from this branch produces a flipped binary**, so the parser runs
flipped while it is checked out. The shipped binary is whichever was built last — check
behaviourally.

**C-156a's buy criteria are unaffected by S1** — they grade a *reporting practice* (arm
attribution), not whether the respell needs the flip. Counter so far: **0 arm-attribution
errors, 0 voided controls, 1 scheduled bare run** (step 1's, taken under the original rule
before the amendment took effect).

## §6 WHAT IS OWED

- **112 class-(a) sites**, in file groups, one commit each — and S1 means the flip may not be
  needed for them at all. **That is a ruling worth taking before the next sub-stroke**, since
  it decides whether this work lands on `main` or waits on the flip.
- **Classes (b), (c), (d) are read-and-report and none has been read yet** beyond the counts
  above and utilities' own eight sites. The dispatch says this is where the stroke earns its
  keep, and it is untouched work.
- The repo-wide drift row (old-form class-(a) sites at 0) is **not yet buildable** — 112 sites
  remain, so it would pin 112 and fail by design.

---

# C-156 REVISED — STEPS 2, 3, 4. CLASS (a) CLOSED AND LANDED ON THE TRUNK.

**Run 2026-09-04 under the revised charter. Every section states its arm in its heading.**

## §7 SURPRISES FIRST

### ⚠⚠ S5 — 3b INVERTS ITS PREDICTION: `lastREF` HOLDS THE **SOURCE**, AND IT IS THE **EXPLICIT** SPELLING THAT READS THE HOLDER

**Arm: FLIP ON.** At action entry, one probe, both spellings side by side:

```
3b bare taG at entry     = lrSource      <- the SOURCE
3b explicit argument.taG = argument      <- the HOLDER
```

The dispatch predicted *"lastREF holds the holder."* It holds the source. **And the
consequence runs the other way from the obvious reading of class (b): the 53 explicit
`argument.taG` sites are the ones that changed meaning under the flip** — they now answer
`argument`, the holder's own tag — **while bare accessors at action entry are correct.**

### ⚠⚠ S6 — 3c: `*argument;` DOES **NOT** RE-AIM `lastREF`. SO (b) IS A `lastREF` RULING, NOT A RESPELL.

**Arm: FLIP ON.** `*argument;` as a bare statement, bare `taG` either side:

```
3c BEFORE bare taG = lrSource
3c AFTER  bare taG = lrSource      unchanged
```

The dispatch's own fork: *"Re-aims → a one-line-per-action fix is on the table. Doesn't →
(b) is a lastREF ruling, not a respell."* **It does not re-aim. (b) is a ruling.**

### ⚠⚠ S7 — THE PICK-ONE RED WAS THE FLIP'S DEFECT, NOT THE RESPELL'S, AND ONLY A CONTROL COULD TELL

Group 1 moved three rows on the flip arm — two green, **one red**, which is the stop clause.
Star and flip were confounded, so the mechanism was measured rather than named from the
symptom:

```
arm BARE, starred:  row - - D - quoteBody ANYtoken     correct rule tags
arm FLIP, starred:  row - - D - quoteBody scCur        the CURSOR
```

**The star is innocent.** Inside an `iterate`/`while ++` walk the flip aims `lastREF` at the
**cursor node itself** rather than at the walked member, so `~taG` prints `scCur`. On bare
the same starred source prints the member's tag.

**And the row had been passing vacuously**: under the flip the *unstarred* walk returned zero
rows, so the hybrid set was empty for want of rows, not for want of exceptions. That is the
exact H4 hole `pop.sh`'s own comment predicts two lines above the check. **The respell made
the walk non-empty and the hole visible.** Nothing regressed.

### ⚠ S8 — CLASS (d) IS NOT THE SILENT CLASS IT WAS FEARED TO BE

Of the 24 distinct source names behind the 44 sites, **21 have no `:=` or `<-` binding at
all** — they are action parameters or define-block fields, so they are not captures of
`argument` and nothing is owed. Two are bound `<- Grokking` (a registry subscript), one
`:= blok`. Asked directly — *is any (d) source name bound from `argument` anywhere in
scope?* — the answer is **one site**, `incant/generate:57  lines = argument[1];`, which is a
**subscript with `=`**, not a holder capture.

### ⚠ S9 — THE (b) POPULATION IS ~5× LARGER THAN THE (b) COUNT, AND IN A DIFFERENT PLACE

Step 3a's split, scope `incant/ genLadder/ minionWork/`:

| | count |
|---|---|
| explicit `argument.<accessor>` | **108** |
| bare accessor, `lastREF`-resolved | **787** |
| — of which explicit `argument.taG` | **53** |
| — of which bare `taG` | **190** |

**The 53 get their true home: they are the EXPLICIT column**, and by S5 they are the sites
the flip changes. The 190 bare `taG` sites are a separate and much larger population that
the earlier count of 162 never saw.

## §8 STEP 2 — CLASS (a), 113 SITES, CLOSED

**Census line, the charter's first ask: class-(a) sites that are NOT statement-initial
`iterate` = ZERO.** The single grep hit is prose in a comment block (`incant/genEmit:84`).
**So the arm-independence claim widens to the whole class.**

| group | sites | files | commit (branch → trunk) |
|---|---|---|---|
| `incant/utilities` (step 1) | 1 | 1 | `53b107d` → `8fb627e` |
| `incant/` core | 67 | 29 | `226db1c` → `1857134` |
| `genLadder/` | 4 | 4 | `394b5c1` → `40f5627` |
| `minionWork/` | 35 | 21 | `53b86a6` → `92f172a` |
| `incant/attic/` | 6 | 4 | `1cf8838` → `999eeac` |
| **total** | **113** | **71** | 5 commits, cherry-picked in order |

**Per-commit certificate, arm BARE (the landing arm):** moved-set **empty** every time, fleet
191 green / 1 parked / 3 pinned red, canary **332**, no extern, no `groups.ext` edit.
`countPop` 40/40 and `decodePop` run clean after the `genLadder/` group, since two of those
four feed them.

**Drift row, whole tree: 5 hits, ZERO in scope**, each accounted for by name —
`docs/kantCorpus.md:1465` and `ipc/clay-to-clod.md:1607` are prose and historical record and
are **deliberately not rewritten**, and `IncantForms/WorkingOn/parser:25/50/63` is Tony's WIP,
excluded by the charter.

**Trunk certificate:** binary verified **bare behaviourally** (`ARM = SRC`); bare fleet
**row-for-row identical** to pre-stroke at 191/1/3; canary 332; **no generated file touched
at all** — no `.twk` or `.rtn` was edited, so the `.mm`/`.h` set is untouched rather than
merely unchanged.

**Branch after rebase: `flip-argument` is exactly ONE commit** — `fd0d300`, *"branch carries
the flip from here."* There is no flip-dependent respell work, so the prediction *"one plus
anything flip-dependent"* resolves to one.

## §9 STEP 4 — (c) BY SHAPE. Nothing respelled.

| operator | count | shape |
|---|---|---|
| `:= argument` | 19 | 19 plain, plus 7 through an accessor (`.claims` ×6, `.firsT`, `.firstMembeR`, `.tARGET`, `.dIRECTion`) |
| `<- argument` | 12 | 10 plain, 2 `.parenT` |
| `argument =` | 14 | plus `argument.byRef =` ×1 |

By C-154's ruling the `:=` sites take `*argument`; `<-` mints a copy and is a separate
question; `argument =` on a holder RHS refuses by name. **None was touched.**

## §10 COUNTER, C-156a

**0 arm-attribution errors · 0 controls voided by arm confusion · 2 scheduled bare runs.**

⚠ The second bare run was **not** a toggle-and-back inside a sub-stroke: it was the group-1
red row's discriminator, taken with a heading because it decided whether the class could land
on the trunk at all. It answered that it could, and it produced S7. Counted honestly against
the criterion all the same.

## §11 WHAT IS OWED

- **Class (b) is a `lastREF` ruling** (S6), and it is Tony's. The evidence pile is C-158.
- **Class (c) and (d) are read and reported**; no ruling requested here.
- ⚠ **`shadowCensus`'s pick-one row is red on the flip arm and green on the trunk.** It is
  not a regression and it is not re-pinned; under the flip it is reporting the `lastREF`
  cursor behaviour faithfully. It goes green again when (b) is ruled.

---

## §12 STEP 4 (c) — THE OPERATOR AT EVERY SITE (C-158 addition 3)

**Arm-independent: a static read.** Prose and comment lines filtered out, which removes
three that the aggregate in §9 had counted — `:=` 29 → **26**, `=` 14 → **12**, `<-`
unchanged at 12. **§9's aggregate was the looser number; these are the code sites.**

By C-154's ruling the `:=` sites take `*argument`; `<-` mints a copy and is a separate
question; `=` on a holder RHS refuses by name. **None was touched.**

**`:=` — 26 code sites**

| site | line |
|---|---|
| `incant/genEmit:111` | `wrapped := argument.firstMembeR;` |
| `incant/generate:68` | `st  := argument[1];` |
| `incant/generate:69` | `xp  := argument["ExpressioN"];` |
| `incant/generate:100` | `looper   := argument["Looper"];` |
| `incant/generate:101` | `xp       := argument["ExpressioN"];` |
| `incant/generate:102` | `restrict := argument["LoopRestrict"];` |
| `incant/generate:103` | `st       := argument["StatemenT"];` |
| `incant/generate:140` | `xp  := argument["ExpressioN"];` |
| `incant/generate:142` | `st  := argument[2];` |
| `incant/generate:143` | `el  := argument[3];` |
| `incant/generate:197` | `xp  := argument["ExpressioN"];` |
| `incant/generate:199` | `st  := argument[2];` |
| `incant/iterT3:51` | `grup := argument;` |
| `incant/jiabsorb:28` | `cg := argument.claims;` |
| `incant/jiabsorb:33` | `cg     := argument.claims;` |
| `incant/jidirect:25` | `cg := argument.claims;` |
| `incant/jidirect:36` | `cg := argument.claims;` |
| `incant/jidirect:45` | `cg := argument.claims;` |
| `incant/jidirect:55` | `cg := argument.claims;` |
| `incant/jitDrive:31` | `blok := argument["BlocK"];` |
| `incant/setGroupInit:20` | `if dTarget := argument;` |
| `incant/setGroupInit:32` | `fTarget := argument;` |
| `incant/utilities:184` | `direct  := argument.dIRECTion;` |
| `incant/utilities:185` | `target  := argument.tARGET;` |
| `minionWork/anyOrNumCam:80` | `camDirect := argument(ruleText);` |
| `minionWork/f31StoreActivate:39` | `BlockerRouteA="ROUTE A, := on the rule. piShell := argument th` |

**`<-` — 12 code sites**

| site | line |
|---|---|
| `incant/attic/parentUnreachable:15` | `fpP <- argument.parenT;` |
| `incant/decoder:361` | `for grup in <- argument;` |
| `incant/holderT:49` | `htP <- argument.parenT;` |
| `incant/lookup:74` | `for grup in <- argument;` |
| `incant/utilities:386` | `band <- argument :+ new(bandName);` |
| `incant/utilities:432` | `rowBlock <- argument :+ new(rowName);` |
| `minionWork/probeActionHome:10` | `ahN <- argument;` |
| `minionWork/probeC3:7` | `c3E <- argument;` |
| `minionWork/probeC4:11` | `c4N <- argument;` |
| `minionWork/probeD2:10` | `d2N <- argument;` |
| `minionWork/probeM3:25` | `fbN <- argument;` |
| `minionWork/probeNameFlip:12` | `nfN <- argument;` |

**`=` — 12 code sites**

| site | line |
|---|---|
| `incant/argWriteT:15` | `awWrite argument code={ argument = 5; return argument; };` |
| `incant/attic/jitIso3:26` | `i3Act.argument = i3Root;` |
| `incant/designDocs:235` | `parseSelfRecursion gloss="generated parse re-enters itself" sy` |
| `incant/designDocs:1620` | `argumentHasData=(THE CLAIM, from the site: an argument attribu` |
| `incant/scopeUnits:186` | `argument = lineIn + 4;` |
| `incant/unitTests:169` | `argument = lineIn + 4;` |
| `minionWork/f31StoreActivate:47` | `SubFive="Passing the cell into a helper action as argument doe` |
| `minionWork/probeStep4:15` | `print "  S4-E0 argument  =" argument:;` |
| `minionWork/probeStep4:16` | `print "  S4-E1 *argument =" *argument "  want ORIG if the chan` |
| `minionWork/tripwireNeg:10` | `print "TN-A plain action, argument =" argument:;` |
| `minionWork/tripwireNeg:12` | `tnLoaded argument=42 code={` |
| `minionWork/tripwireNeg:13` | `print "TN-B loaded action, argument =" argument:;` |

---

## §13 ITEM 4 CLOSED — 2026-09-04, Tony

**Class (a) is landed on the trunk; classes (b), (c) and (d) are read and reported.** Item 4 is
closed.

**C-156a BUYS, at 0 / 0 / 2.** Zero arm-attribution errors, zero controls voided by arm confusion,
two scheduled bare runs — neither a toggle-and-back inside a sub-stroke: one was step 1's, taken
under the original rule before the amendment took effect, and one was the group-1 red row's
discriminator, taken with a heading because it decided whether the class could land on the trunk
at all. The practice is bought on its own terms: **every number in this report states its arm, and
no control was lost to arm confusion.**

**`flip-argument` stays up**, at one commit — `gNoUnwrap = 1` in source. ⚠ An Xcode build from
that branch still produces a flipped binary.

⚠ **`shadowCensus`'s pick-one row is GREEN on the trunk and RED on the flip arm, and it is NOT
re-pinned.** After the capture-then-call respell (R1) the tag column is correct on both arms, but
the D column diverges — **23 on bare, 84 on the flip, with the M column agreeing exactly at 13** —
because `scDcol`'s own bare `datA` reads the cursor holder. **That is R2's residue**, the walk
writer storing the cursor rather than the member, and R2 is open pending C-158a.

---

## §14 R3 — THE 108→124 EXPLICIT-ACCESSOR READ (landed 2026-09-04)

**Read only. Arm-independent: a static read.** Every `argument.<accessor>` code site in
`incant/ genLadder/ minionWork/`, with comment and prose lines excluded — including
`incant/designDocs`' own `(…#)` prose, which the first pass counted (2 sites) and which is not code.

**124 sites. Source-meant 122 · holder-meant 2.**

| family | n |
|---|---|
| identity — `taG`, `texT` | 48 |
| shape — `listLengtH`, `hasAttributeS`, `hasMemberS`, `hasTraitS`, `hasActioN`, `firstMembeR` | 25 |
| record fields + one-offs — `description`, `status`, `reviewed`, `symptom`, `finding`, … | 23 |
| data — `datA`, `claims` | 16 |
| kind — `isRulE`, `isActioN`, `isMethoD`, `actionTypE`, `hasNewParsE` | 10 |

⚠ **HALF THE PRE-REGISTRATION HELD AND HALF INVERTED.** *Source-meant is the large majority* —
yes, 122 of 124. *Holder-meant is the `taG`/presence-test family* — **no.** The `taG` family reads
as *the name of the thing passed in* at every site (`cerr "generating parse for " argument.taG`,
`decodeCorpus[argument.taG]`, `kind = argument.taG`), and the presence tests ask whether **the
thing passed** has attributes or a list. **Both are source-meant, and they are precisely the sites
that break under the flip** — so the 47 `taG` sites are the respell's centre of gravity, not its
exception.

**Holder-meant is two sites, both `parenT`, both in holder-specific fixtures by construction:**

```
incant/holderT:49                  htP <- argument.parenT;
incant/attic/parentUnreachable:15  fpP <- argument.parenT;
```

**Both are untouched by C-161 and named there.**

### §14a The per-site table

| accessor | site | line |
|---|---|---|
| `actionTypE` | `minionWork/probeBind:55` | `if argument.actionTypE;     pbB = 1;` |
| `actionTypE` | `minionWork/probeRefReach:57` | `if argument.actionTypE;     pbB = 1;` |
| `beartraps` | `incant/lookup:46` | `print "  bear traps " argument.beartraps:;` |
| `binTypE` | `minionWork/probeBreakShape:8` | `cerr "  " argument.taG "  isRulE " argument.isRulE "  binTypE " argument.binTy` |
| `blocked` | `incant/jiquery:95` | `blockList = argument.blocked;` |
| `claims` | `incant/jiabsorb:28` | `cg := argument.claims;` |
| `claims` | `incant/jiabsorb:33` | `cg     := argument.claims;` |
| `claims` | `incant/jidirect:25` | `cg := argument.claims;` |
| `claims` | `incant/jidirect:36` | `cg := argument.claims;` |
| `claims` | `incant/jidirect:45` | `cg := argument.claims;` |
| `claims` | `incant/jidirect:55` | `cg := argument.claims;` |
| `claims` | `incant/jiquery:129` | `claimList = argument.claims;` |
| `claims` | `incant/jiquery:47` | `claimList = argument.claims;` |
| `claims` | `incant/jiquery:57` | `claimList = argument.claims;` |
| `claims` | `incant/jiquery:69` | `claimList = argument.claims;` |
| `claims` | `incant/jiquery:77` | `claimList = argument.claims;` |
| `dIRECTion` | `incant/utilities:184` | `direct  := argument.dIRECTion;` |
| `datA` | `incant/ddProbe2:13` | `print "  children " argument.listLengtH " datA " argument.datA:;` |
| `datA` | `incant/tableProbe:38` | `slot = argument.datA;` |
| `datA` | `minionWork/probeChannels:10` | `cerr "     datA       " argument.datA:;` |
| `datA` | `minionWork/probeNumAnat:12` | `if argument.datA != 0;      rnD = 1;` |
| `datA` | `minionWork/probeNumAnat:30` | `if argument.datA != 0;      rnD = 1;` |
| `description` | `incant/ddGate:36` | `if argument.description;     ddDesc = 1;` |
| `description` | `incant/lookup:52` | `print argument.description:;` |
| `finding` | `incant/lookup:37` | `print "  finding    " argument.finding:;` |
| `firstMembeR` | `incant/genEmit:111` | `wrapped := argument.firstMembeR;` |
| `hasActioN` | `minionWork/probeBind:59` | `if argument.hasActioN;      pbD = 1;` |
| `hasActioN` | `minionWork/probeRefReach:61` | `if argument.hasActioN;      pbD = 1;` |
| `hasAttributeS` | `incant/bothControl:20` | `if argument.hasAttributeS;  print "A";` |
| `hasAttributeS` | `incant/connectiveT:123` | `same spelling against an explicit argument.hasAttributeS on the same node and` |
| `hasAttributeS` | `incant/connectiveT:24` | `if argument.hasAttributeS;  cdHa = 1;` |
| `hasAttributeS` | `minionWork/probeChannels:11` | `cerr "     hasAttrs   " argument.hasAttributeS:;` |
| `hasAttributeS` | `minionWork/probeHasTraits:11` | `if argument.hasAttributeS;  phA = 1;` |
| `hasAttributeS` | `minionWork/probeHasTraits:17` | `if argument.hasAttributeS;  phA = 1;` |
| `hasMemberS` | `incant/bothControl:22` | `if argument.hasMemberS;     print "M";` |
| `hasMemberS` | `minionWork/probeChannels:12` | `cerr "     hasMembs   " argument.hasMemberS:;` |
| `hasNewParsE` | `incant/anyOrNumT:68` | `if argument.hasNewParsE;     compiledHere = 1;` |
| `hasNewParsE` | `minionWork/anyOrNumCam:71` | `if argument.hasNewParsE;     compiledHere = 1;` |
| `hasTraitS` | `incant/connectiveT:25` | `if argument.hasTraitS;      cdHt = 1;` |
| `hasTraitS` | `minionWork/probeHasTraits:12` | `if argument.hasTraitS;      phT = 1;` |
| `hasTraitS` | `minionWork/probeHasTraits:18` | `if argument.hasTraitS;      phT = 1;` |
| `isActioN` | `minionWork/probeBind:53` | `if argument.isActioN;       pbA = 1;` |
| `isActioN` | `minionWork/probeRefReach:55` | `if argument.isActioN;       pbA = 1;` |
| `isMembeR` | `minionWork/probeBreakShape:8` | `cerr "  " argument.taG "  isRulE " argument.isRulE "  binTypE " argument.binTy` |
| `isMethoD` | `minionWork/probeBind:57` | `if argument.isMethoD;       pbC = 1;` |
| `isMethoD` | `minionWork/probeRefReach:59` | `if argument.isMethoD;       pbC = 1;` |
| `isRulE` | `incant/flagProbe:27` | `if argument.isRulE;     print + "    if .isRulE  TOOK THE TRUE BRANCH":;` |
| `isRulE` | `minionWork/probeBreakShape:8` | `cerr "  " argument.taG "  isRulE " argument.isRulE "  binTypE " argument.binTy` |
| `listLengtH` | `incant/attic/parentUnreachable:14` | `cerr "    3 .listLengtH = " argument.listLengtH "   want 4          property":` |
| `listLengtH` | `incant/ddProbe2:13` | `print "  children " argument.listLengtH " datA " argument.datA:;` |
| `listLengtH` | `incant/ddProbe:13` | `print "entry " ~taG " children " argument.listLengtH:;` |
| `listLengtH` | `incant/decoder:360` | `if argument.listLengtH;` |
| `listLengtH` | `incant/genCount:105` | `if argument.listLengtH;` |
| `listLengtH` | `incant/generate:251` | `if argument.listLengtH;` |
| `listLengtH` | `incant/lookup:73` | `if argument.listLengtH;` |
| `listLengtH` | `incant/utilities:10` | `if argument.listLengtH;` |
| `listLengtH` | `minionWork/probeChannels:9` | `cerr "     listLengtH " argument.listLengtH:;` |
| `listLengtH` | `minionWork/probeNumAnat:10` | `rnL = argument.listLengtH;` |
| `listLengtH` | `minionWork/probeNumAnat:28` | `rnL = argument.listLengtH;` |
| `nextStep` | `incant/jiquery:107` | `stepList = argument.nextStep;` |
| `openItems` | `incant/jiquery:87` | `openList = argument.openItems;` |
| `parenT` | `incant/attic/parentUnreachable:15` | `fpP <- argument.parenT;` |
| `parenT` | `incant/holderT:49` | `htP <- argument.parenT;` |
| `reviewed` | `incant/ddGate:37` | `print "GATE|" argument.taG "|" ddDesc "|" argument.status "|" argument.reviewe` |
| `reviewed` | `incant/lookup:42` | `print "  reviewed   " argument.reviewed:;` |
| `sink` | `incant/genEmit:15` | `argument.sink       an attribute, "label" or "into" -- the FOLD's` |
| `site` | `incant/lookup:45` | `print "  site       " argument.site:;` |
| `solution` | `incant/lookup:39` | `print "  solution   " argument.solution:;` |
| `station` | `incant/lookup:43` | `print "  station    " argument.station:;` |
| `status` | `incant/ddGate:37` | `print "GATE|" argument.taG "|" ddDesc "|" argument.status "|" argument.reviewe` |
| `status` | `incant/lookup:40` | `print "  status     " argument.status:;` |
| `symptom` | `incant/lookup:36` | `print "  symptom    " argument.symptom:;` |
| `tARGET` | `incant/utilities:185` | `target  := argument.tARGET;` |
| `taG` | `genLadder/countPopulation:19` | `print "COUNTPOP" argument.taG:;` |
| `taG` | `genLadder/odoPopulation:17` | `print "ODOPOP" argument.taG:;` |
| `taG` | `incant/anyOrNumT:16` | `cerr "generating parse for " argument.taG:;` |
| `taG` | `incant/anyOrNumT:71` | `print ~"PARSE " argument.taG " <- " ruleText:;` |
| `taG` | `incant/attic/argTrampleOrder:19` | `return argument.taG;` |
| `taG` | `incant/attic/argTrampleOrder:23` | `return argument.taG;` |
| `taG` | `incant/attic/argTrampleOrder:34` | `return argument.taG;` |
| `taG` | `incant/attic/parentUnreachable:12` | `cerr "    1 .taG        = " argument.taG "   want fpInside   property":;` |
| `taG` | `incant/bothControl:24` | `print " " argument.taG:;` |
| `taG` | `incant/connectiveT:19` | `cerr "   rule " argument.taG " attributes " cdA " members " cdM:;` |
| `taG` | `incant/connectiveT:26` | `cerr "   rule " argument.taG "  hasAttributeS " cdHa "   hasTraitS " cdHt:;` |
| `taG` | `incant/countScratch:140` | `cerr $"KOUNT " argument.taG "=" n:;` |
| `taG` | `incant/ddGate:37` | `print "GATE|" argument.taG "|" ddDesc "|" argument.status "|" argument.reviewe` |
| `taG` | `incant/decoder:346` | `hit = decodeCorpus[argument.taG];` |
| `taG` | `incant/decoder:348` | `print argument.taG " -- " hit.definition:;` |
| `taG` | `incant/decoder:350` | `print "decode UNDEFINED TERM " argument.taG " -- FAILS LOUD, mint the entry no` |
| `taG` | `incant/fixits/carrierNode:74` | `k1(argument)) and never for a property read like argument.taG.` |
| `taG` | `incant/genEmit:109` | `kind = argument.taG;` |
| `taG` | `incant/jitDrive:42` | `print "BlocK found on" argument.taG:;` |
| `taG` | `incant/jitDrive:44` | `print "REFUSE no BlocK on" argument.taG:;` |
| `taG` | `incant/kant8T:116` | `return argument.taG;` |
| `taG` | `incant/kant8T:119` | `return argument.taG;` |
| `taG` | `incant/kant8T:220` | `return argument.taG;` |
| `taG` | `incant/lookup:58` | `luD = decodeCorpus[argument.taG];` |
| `taG` | `incant/lookup:60` | `print "=== " argument.taG " -- " luD.definition:;` |
| `taG` | `incant/lookup:62` | `luP = ProblemRecords[argument.taG];` |
| `taG` | `incant/lookup:68` | `print "=== " argument.taG " -- IN NEITHER POPULATION. Not yet an id: a name is` |
| `taG` | `incant/lookup:81` | `luP = ProblemRecords[argument.taG];` |
| `taG` | `incant/lookup:83` | `print "=== " argument.taG " AS A TOMBSTONE, prose shed ===":;` |
| `taG` | `incant/lookup:87` | `print "=== " argument.taG " -- no problem record ===":;` |
| `taG` | `incant/nestT:38` | `return argument.taG;` |
| `taG` | `incant/utilities:67` | `if goodToGo; print "OK to display" argument.taG; };` |
| `taG` | `minionWork/anyOrNumCam:16` | `cerr "generating parse for " argument.taG:;` |
| `taG` | `minionWork/anyOrNumCam:83` | `print ~"PARSE " argument.taG " <- " ruleText:;` |
| `taG` | `minionWork/f31StoreActivate:43` | `SubOne="group[argument.taG] lookup on a runtime-built group WORKS. Two hits, b` |
| `taG` | `minionWork/kant8Tstar.candidate:116` | `return argument.taG;` |
| `taG` | `minionWork/kant8Tstar.candidate:119` | `return argument.taG;` |
| `taG` | `minionWork/kant8Tstar.candidate:220` | `return argument.taG;` |
| `taG` | `minionWork/probeBreakShape:8` | `cerr "  " argument.taG "  isRulE " argument.isRulE "  binTypE " argument.binTy` |
| `taG` | `minionWork/probeCopyQ:11` | `cqSink argument code={ return argument.taG; };` |
| `taG` | `minionWork/probeDualFlag:12` | `cerr "  BOTH " argument.taG:;` |
| `taG` | `minionWork/probeHasTraits:13` | `cerr "    rule " argument.taG " PRISTINE  hasAttributeS " phA "  hasTraitS " p` |
| `taG` | `minionWork/probeHasTraits:19` | `cerr "    rule " argument.taG " SETPARSE  hasAttributeS " phA "  hasTraitS " p` |
| `taG` | `minionWork/probeK2vacuity:19` | `return argument.taG;` |
| `taG` | `minionWork/probeK2vacuity:23` | `return argument.taG;` |
| `taG` | `minionWork/probeK2vacuity:67` | `inner activation a DIFFERENT node and reads argument.taG rather than the node` |
| `texT` | `incant/attic/parentUnreachable:13` | `cerr "    2 .texT       = " argument.texT "   want fpInside   property":;` |
| `texT` | `minionWork/probeChannels:13` | `cerr "     texT       " argument.texT:;` |
| `verdict` | `incant/lookup:41` | `print "  verdict    " argument.verdict:;` |
| `vintage` | `incant/lookup:44` | `print "  vintage    " argument.vintage:;` |
| `workaround` | `incant/lookup:38` | `print "  workaround " argument.workaround:;` |

---

## §15 C-162 SETTLED, AND THE C-161 PRE-FLIGHT SAYS **HOLD**

### §15a C-162's flip arm — moved-set NOT empty, and better than predicted

Pre-registered: *moved-set empty against the pre-C-162 flip capture; zero refusals.*

**Zero refusals — held.** **Moved-set empty — missed:** six rows moved, **every one red → green.**

⚠ **No pre-C-162 flip capture existed** — the last was C-156-era and confounded by everything
since. One was built retroactively by running the fleet from a worktree at `ca604b0` **on the same
flipped binary**, so only the incant sources differ. That is the comparison below.

```
ARM FLIP   pre-C-162  135 green / 66 red
ARM FLIP   post       141 green / 60 red      six rows, all red -> green
```

| row | fixture | starred sites now |
|---|---|---|
| `fires=NEVER roster` | `parseClass` | 7 |
| `anti-vacuity: parseRule parked actions` (0 → 59) | `parseClass` | 7 |
| `iterT1` | `iterT1` | 1 |
| `iterT1m` | `iterT1m` | 2 |
| `iterT1m refusal count` (0 → 4) | `iterT1m` | 2 |
| `displayForm baseline` | `displayFormT` | 1 |

**All four backing fixtures were respelled by C-162**, and the mechanism is the class's own: under
the flip a cursor passed to an action arrived as the **cursor holder**, so the callee walked or
found nothing; `*cursor` delivers the member and the callee works. Bare unmoved throughout, canary
**333**, flip lowered and verified behaviourally.

### §15b ⚠ C-161 PRE-FLIGHT: THE PROPOSED SPELLING DOES NOT PARSE AS INTENDED. HOLD.

One `*argument.taG` site, both arms, `addrOf` on the read. **No prediction was made; here is what
it measured.**

```
                            ARM BARE                    ARM FLIP
A  argument.taG             pfSource   (correct)        argument   (the defect)
B  *argument.taG            0  + ERROR unary * on taG   0  + ERROR unary * on taG
C  pfCap := *argument
   then pfCap.taG           pfCap  + ERROR on pfSource  pfCap
D  addrOf(argument)         #1 / body #2                #1 / body #2
E  addrOf(pfCap)            #3 / body #4                #3 / body #4
```

⚠⚠ **ROW B IS THE FINDING: THE STAR BINDS TO `taG`, NOT TO `argument`.** `*argument.taG` parses as
`*(argument.taG)` — the error names **`taG`** — so it reads **0 on both arms**. **C-161's spelling
is not flip-only and not trunk-bound; it is wrong.** Same family as `pointerT`'s law 3, where a
star written directly on a subscript binds to the bag.

⚠ **And row C shows the obvious repair does not work either.** `pfCap := *argument` makes `pfCap` a
**holder**, so `pfCap.taG` answers with the holder's own name — `pfCap` — under the flip, and on
bare the star refuses first because `argument` is already unwrapped.

**So the class cannot move on either arm until a spelling is chosen, and the pre-flight has done
its job by stopping it before 122 sites did.**

**THE CANDIDATE, and it is only a candidate: DROP `argument.` ENTIRELY and use the BARE accessor.**
C-158 step 3b measured bare `taG` at action entry reading **the source on the flip** — `lrSource` —
while the explicit spelling read `argument`. So for the 48-site identity family the fix may be a
**deletion, not a star**. ⚠ **Not a blind substitution:** a bare accessor is `lastREF`-resolved and
therefore position-sensitive, correct at entry and wrong after any intervening call (the clobber,
R1). Every site would need reading for what sits above it. **Tony's ruling, before anything moves.**

---

## §16 C-161 PRE-FLIGHT PART 2 — NO SPELLING MEASURED YET REPAIRS IT

Read-only, both arms, binary bare at close and verified behaviourally.

### §16a Rows D and E

```
                                  ARM BARE                  ARM FLIP
A  argument.taG   (control)       pfSource                  argument      <- the defect
D  (*argument).taG                PARSE FAILED              PARSE FAILED
E  @*argument; then bare taG      pfSource (star refused)   pfSource
E-ctl  bare taG, no @             pfSource                  pfSource
```

**Row D: literal parens do not parse.** `ERROR processCode: pfAct parse failed`, on both arms.
`(*argument).taG` is not a spelling this grammar has.

**Row E does not discriminate at entry**, and that is itself the finding: **bare `taG` already
reads the source on both arms with or without `@`**, confirming C-158 step 3b. At action entry the
`@` is redundant.

### §16b Where `@` would earn its place — after a call — it does not

`@` matters only where `lastREF` has been clobbered, so the mid-body case was measured. **ARM FLIP:**

```
F1  entry, bare taG                = pfSource     correct
F2  after a call, bare taG         = pfOther      the clobber (the callee's argument)
F3  after `@argument;`  bare taG   = argument     re-aimed to the HOLDER -- wrong answer
F4  after `@*argument;` bare taG   = pfOther      DID NOT RE-AIM AT ALL
```

⚠ **Neither form is a repair.** `@argument` re-aims `lastREF` to the **holder**, so the bare read
answers `argument`. `@*argument` leaves the aim **unchanged** — the read still returns the previous
callee's argument — which is row B's binding problem again: the star is not reaching `@` as its
operand.

### §16c Census — the blast radius of a `UnaryOPS` placement change is ~ZERO

```
  *<name>.<accessor> :  4 sites, 2 files      3  *argument.taG      1  *grup.tag
  *<name>[...]       :  2 sites, 2 files      1  *ptBagP[           1  *SENTINEL[
```

⚠ **Every dot site is in `IncantForms/`** — `WorkingOn/incant++` (Tony's WIP) and
`Notions/fonting`. **Not one is in the live incant corpus, the fleet, or the harnesses.** The two
subscript sites are `pointerT`'s law-3 tripwire and a harness marker, both deliberate.

**So if the road is a grammar change to where `UnaryOPS` may sit, it breaks nothing that runs.**
That is the cheapest of the remaining options by a wide margin, and the census is the reason to say
so rather than the intuition.

### §16d What is left, for Tony's ruling

| candidate | standing |
|---|---|
| `*argument.<acc>` | **dead** — the star binds to the accessor (part 1, row B) |
| `(*argument).<acc>` | **dead** — does not parse (row D) |
| `capture := *argument` then `.acc` | **dead** — the capture is a holder, `.acc` answers with its name |
| `@` re-aim | **dead as measured** — holder, or no re-aim at all (F3/F4) |
| **drop `argument.`, use the bare accessor** | **live** — correct at entry on both arms; position-sensitive, soevery site needs reading for what sits above it |
| **grammar: `UnaryOPS` placement** | **live and cheap** — §16c says the live-corpus blast radius is zero |

**Nothing moves until the spelling is ruled.**

