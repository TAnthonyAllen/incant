# ⚠⚠ UPDATED 2026-07-30 — READ THE 07-30 SECTION FIRST. It is directly below this line.
# Everything from `# ⚠ UPDATED 2026-07-29` down is 07-29 vintage and still accurate; it is
# just no longer the top of the story. CLEAN STOP, tree clean, both POPs green.

# ═══════════════════════════════════════════════════════════════════════════
# 2026-07-30 — TWO MINIONS RAN, THE JIT GOT ITS FIRST INSTRUMENTS, AND
#              "EXIT 0" STOPPED MEANING SUCCESS
# ═══════════════════════════════════════════════════════════════════════════

## THE ONE THING MOST EXPENSIVE TO LOSE, if you read nothing else

**AN INCANT PARSE FAILURE ABANDONS THE REST OF THE FILE AND STILL EXITS 0.** No `stop:`
line, prior output still flushed, every assertion before the bad line still passing. It is
indistinguishable from a short, complete, successful run — and it is **worse than the
SIGSEGV case**, because 139 is at least visible.

```
A: before the bad line     <- printed
x = $"a" _ "b";            <- RunRulE: expected a method not x   (stderr)
B: AFTER the bad line      <- NEVER PRINTED
EXIT=0, no stop: line
```

**Mitigation, and every new fixture must carry it: a SENTINEL** — a known marker as the
file's last statement, asserted FIRST and by name. Absent sentinel ⇒ the run truncated ⇒
every other "ok" in it is *uninterpretable*, not merely incomplete. `genLadder/printPop.sh`
implements it and negative-controls it. Written into `CLAUDE.md`'s testing doctrine as a
third corollary.

**Its shell-level twin: `${PIPESTATUS[0]}` is silently EMPTY in zsh** (bash spelling; zsh
uses `$pipestatus`) and reports every run as passing. Take `$?` directly from the binary,
never through a pipe. **It bit three separate agents in one day**, including this one.

## WHERE WORK STOPPED, AND WHY — 35b is PARKED ON A DESIGN DECISION, not on effort

**Tony took it offline on 2026-07-30.** *"The issue here is shortcuts, I want them in; now
have to figure out how best to make that happen."* **Do not start 35b until that lands.**

The blocker, measured: **no print shortcut parses in an `ExpressioN` position.** `$`, `_`
and `,+` all fail (`ERROR processCode: <action> parse failed`). Cause, per Tony:
**ExpressioN does not deal with shortcuts — PrintXP does**, and the right-hand side of an
assignment is an ExpressioN. A design boundary, not an accident.

Why that blocks 35b specifically: its briefed oracle is "the 24 `string` call sites,
byte-identical under the omitted form." **There are 30, and 25 of them carry a shortcut**
(overwhelmingly `$` — `local = string $"t" at;`, `cellName = string $"c" r "x" c;`). Those
25 **cannot be written in the omitted form at all**, so the oracle as briefed covers 5
sites, and the 5 least representative ones.

**Three questions are open and were put to Tony** (see `ipc/clay-to-clod.md`, foot):
1. **BLOCKING** — is 35b's oracle the ~5 shortcut-free sites; or should the omitted form
   reach shortcuts (which routes `=`'s RHS through PrintXP — much bigger than "add list
   handling"); or is the oracle a *fixture* mirroring the shapes rather than converting
   live sites?
2. Does `=` want the same append/assign rule `+=` got, or does `=` always assign? *(Do not
   infer it — the amendment's own root cause was reading `=` and `+=` as one operation with
   a modifier.)*
3. `=` with a list on a non-string target: leave it (today it yields `xlInSet`, an
   **uninitialised read** — broken, not merely absent) or make it a loud refusal?

## 35a IS DONE AND IN THE PRODUCT

`field += this that and the other` concatenates. The arm sits above `opPlusEQ`'s
`isLIST → copyListTo` short-circuit and routes through `appendGroup` + `opString` — **one
call, not a loop**, because appendGroup already walks a list and an expression list answers
`isLIST`. Fixture `incant/concatT`.

- **Oracle answered empirically: there are NO `+=`-with-a-list call sites in the tree.**
  Instrumented the copyListTo arm and ran 17 named fixtures — **zero hits**. That arm is
  dead in-tree; there was no behaviour to preserve. Absence scoped to those 17 by name.
- **Append if the target has data, assign if it does not** (Tony's ruling). The guard is
  `data`, **not** "text is non-empty" — **a field with no data returns its TAG from
  `.text`**, so an unguarded pre-load would concatenate onto the field's own name.
- Trailing space under default spacing is **the user's to deal with** (Tony). A shortcut
  that backs up over one is a noted maybe, not scheduled.

## THE RULING TONY OWES, AND IT IS BIGGER THAN THE ITEM THAT SURFACED IT

**`CLAIM KANT-22` — KANT HAS NO STATEFUL RECURSION.** Both routes barred, different reasons:

| route | state across the recursive call |
|---|---|
| named self-call | **does not compile** (KANT-6, exit 139, re-tested 07-30 and it holds) |
| `this(...)` | compiles, **locals SHARED** — inner overwrites outer's (KANT-7) |

Neither claim is new. **The conjunction is**, and it was missed for a whole round because
each was filed as a fact about `spellLeaf` rather than about the language. **It bars
`emitPlan`** — which accumulates text across a walk and reads its accumulator after each
recursive call — so it **bars step 3 of the minion arc**, which nobody knew when the arc was
planned.

**Three exits: fix the self-name bar; make `this()` per-frame; or adopt the CARRIER
DISCIPLINE** — *anything that must survive a recursive call lives on a carrier node, never
in a local*. Sharing can't reach a carrier and neither can a restore. **Exit 3 costs
nothing, works today, needs no runtime change**, and under it `emitPlan` is writable in kant
right now. The warm-up workaround was considered and **rejected** by Clay: it manufactures a
configuration nothing in the product will be in.

## THE JIT HAS INSTRUMENTS FOR THE FIRST TIME

Nothing in the live tree had ever called `verifyFunction`, and no IR had ever been dumped.

- **The verifier REFUSES** (`-5`), placed *before* mem2reg so it catches the emitter's own
  output. **It is SILENT on the gIF fixtures** — and that is the finding: a branch with a
  missing merge is *valid* IR that computes the wrong thing. Validity and correctness are
  different questions.
- **`INCANT_JIT_DUMP=1` dumps the module.** Env var, not a GroupBody flag, so no bitfield
  shift and no `tokall`. **This is what produced bones:**

```
endif:                        ; preds = %then, %entry
  ret i32 99                  ; ⚠ A CONSTANT — taken and not-taken IR are IDENTICAL
```

  The **store is properly conditional** (`maximus` correctly stays 11 on the not-taken
  path); the **return value is not merged**. So the defect is precisely a missing
  return-value merge. ⚠ **This CORRECTS the record** — the stored note "IR: unconditional
  store + `br i1 true`" describes the OLD state; unified emit-on-walk fixed the branch.
  Second finding read off the dump: **field slots are `inttoptr` absolute addresses, not
  allocas, so mem2reg has nothing to promote** — the "mem2reg is the foundation" comment
  does not hold for baked field addresses.
- **`jitDegrade` lifted** — §0's "degrade to the oracle LOUDLY", which existed exactly once
  and was **inside `if result.isIterator`, a gate §0 schedules for deletion**. It carries a
  counter, which is the point: ~53 silent fallbacks become countable. ⚠ **It has NO
  behavioural coverage** — its two call sites are unreachable by any fixture, blocked by an
  open question (see below). `incant/jitDegradeT` is committed reaching its sentinel and
  **not** its target, and says so in its own header.

## TWO MINIONS RAN. Both held their sandbox; leak-checked mechanically, not on trust.

**Grammar minion (new, its own corpus `docs/grammarCorpus.md`, no frozen brief).**
- Round 1: `cout` **built** via runtime graft; `cerr` **REFUSED** with evidence (`opPrint`
  is a two-arm if). The refusal was the better half and was accepted as success.
- Round 2: the **print-family POP** (`sh genLadder/printPop.sh`, 9 checks, exit 0, its own
  script — it correctly refused to touch `pop.sh`). `cerr` rows **pinned RED on purpose**,
  `iterT1m`-style; they flip when the C++ lands.
- ⚠ **It corrected its own predecessor**: GRAM-3's byte-identical oracle was captured
  **entirely with the diversion unarmed** — the one condition under which correct and broken
  are indistinguishable. **`cout` under an armed diversion goes into the buffer.**

**Minion A round 2 is HELD**, and not on judgement: **every remaining emitter in genParse
writes its PRODUCT via `cerr`** (`emitMany` 11, `printPlan` 6, `emitPlan` 14, `planTerm` 11)
and **kant has no stderr**. Targets are captured from stderr, so a kant version cannot
reproduce its own target. `emitLeaf` was convertible only because it *returns* a String.
Pre-registration is in `docs/minionAledger.md`, difficulty confound named **before** the
round. Softened but not cleared by GRAM-6 (below).

## DOCTRINE ADDED TODAY — all of it paid for the same day

- **`CLAUDE.md`** — the exit-0 third corollary + sentinel discipline (above).
- **An ABSENCE claim must name where it looked.** `CLAIM KANT-17` said no member-filtered
  accessor existed; foreman added one an hour later, falsifying the corpus.
- **OPEN is a third shape** beside CLAIM and BLOCKED. `KANT-20`'s own scope had to call
  itself "an open item wearing a claim's clothes."
- **AN ORACLE IS ONLY EVIDENCE OVER THE CONDITIONS IT WAS CAPTURED UNDER.** A fixture that
  does not vary the discriminating condition is **silent, not green**. Three of today's
  failures are instances: GRAM-3 never armed the diversion; `spell.target` never crosses a
  renamed sink; the four baselines never reached a recursive action with a list-carrying
  local.
- **A status table is a claim with an `asOf` nobody wrote down.** `jit.md`'s Phase-1 unary
  rows say DONE; all three exit 139. **Left standing with the contradiction beside them** —
  they were TRUE when written and were falsified by the 06-30 pivot that folded out `jitXP`.
- **THE PROPAGATION FAILURE, logged in `grammarCorpus.md`:** the minion read `opPrint`
  correctly; foreman verified the *reading* and carried the *inference* further; Clay checked
  the inference against the reading. **Nobody re-derived the `'p'` test from source.** It
  took Tony opening the file. *"I verified X" and "I verified someone's reading of X" are
  different acts and read identically in a report.*

## OPEN, and whose

**Tony's:** the KANT-22 stateful-recursion ruling (three exits) · the shortcuts-in-
ExpressioN design (parked, offline, gates 35b) · the JIT seam ruling — whether the JIT gets
rung 3's walk-decides/emitter-writes shape, which is what turns ~53 undeclared fallbacks
into a countable artifact · the `sink=` proposal (GRAM-P1) replacing the `'p'` character
test · whether `=` gets append/assign · the upload bundle (`docs/jit.md`,
`docs/jit-recon-2026-07-30.md`, TODO's JIT sections).

**Clod's, unblocked:** the `isCoded` question — a `define` in an **included** file yields a
coded field, the identical define in a **top-level script file** does not (`jitAdd` works,
`walkBag` does not). Plausibly bear-trap #15's family, **not established**. It is what
blocks coverage for `jitDegrade`.

**Still open from before, untouched:** everything in the 07-29 and 07-28 sections below.

## RUN RECIPE — what is new today
```
sh genLadder/pop.sh                      # 22 checks, exit 0 (unchanged)
sh genLadder/printPop.sh                 # 9 checks, exit 0, moving half pinned WRONG
INCANT_JIT_DUMP=1 <binary> incant/jitGifScratch 2>&1     # the IR, first time visible
<binary> incant/concatT                  # 35a, 5 rows + sentinel
<binary> incant/nameRecurse              # per-frame locals + .firsT affiliation + 403/404
<binary> incant/jitDegradeT              # ⚠ reaches its sentinel, NOT its target
```
New this day: `.firstMembeR` (opDot case 405) · `.firsT`/`.lasT` no longer segfault on a
leaf · `jitDegrade` · the verifier · the dump. **`groups.ext` was NOT touched today.**
Extern canary **203 → 204** (jitDegrade), the one addition accounted for.

# ═══════════════════════════════════════════════════════════════════════════

# ⚠ UPDATED 2026-07-29 — read the 07-29 section FIRST (it is directly below this header block).
# THE JIT REPLACES THE INTERPRETER, and 07-29 was the ITERATOR + Minion-A-harness day. The
# genParse ladder narrative that follows is 07-28 vintage and still accurate; it is just no
# longer the whole story.
#
# Incant — Status & Handoff (2026-07-28: SHAPE (SEQ 25), RUNG 4, the SEAM (SEQ 26), and RUNG 5
# (SEQ 27), RUNG 6 (SEQ 28) and RUNG 7 (SEQ 29) all landed. The walk DECIDES into a plan of
# GroupItems, the emitter WRITES from it, and SEQ/ALT/LIT/LITTO/CALL/MANY/OPT all emit. THE WHOLE
# JSON FAMILY NOW PLANS. ⚠ RUNG 7's TREE POP FOUND A REAL PRE-EXISTING §2.4 GAP — read it before
# trusting an alternation. `sh genLadder/pop.sh` is the one-command POP.
# Everything RUN with exit status checked. CLEAN STOP — see "WHERE THIS STOPPED" below.)
*Written by Clod for a fresh Clay/Clod with ZERO memory of today. Self-contained. Read fully before
touching code. Everything is on branch `jit-unified-emit-wip`; main is untouched.*

## READ THIS FIRST IF YOU ARE COLD — the one thing most expensive to lose

**A generated parse method now looks like this, and it RUNS:**
```
extern GroupItem parseScaf2(GroupItem rule)
{
GroupItem   into  = rule.rStuff.parentLabel;
GroupItem   label = new("Scaf2");
GroupItem   t1 = rule[1];
GroupItem   t2 = rule[2];
String      from  = atRuleMark;
    return leaveRule(rule,into,label,from, lit(t1,"{") && lit(t2,"}") );
}
```
One argument and it is the rule (§1.1 — kant methods take one argument). `into` is DERIVED from the
new `RuleStuff.parentLabel`, not passed (§1.2). Leaves take the TERM, not the rule (§1.4). No
`locate` anywhere (§1.3). No entry wrapper — invocation is `Scaf('x')`, exactly as `Start()` (§1.7).

**Invocation is bound in incant, and this is §4.1 ANSWERED:**
```
registry(cOMMANDs);
define parseMethod immediateAction=parseRuleMethod noPrint; ;   <-- noPrint IS LOAD-BEARING
register(Ladder);
define  Scaf  isRule "x"- parseMethod=parseScaf;  ;
```
The `noPrint` is not decoration. Without it the binding attribute lands in the rule's **own term
list** as a bogus second term, and the emitter writes a term local for it. That is §1.5's hazard
arriving from a direction nobody predicted, and it is what the first run crashed on.

## ⚠ 2026-07-29 — THE JIT REPLACES THE INTERPRETER (and everything below is 07-28)
**Tony's plan is that the JIT BECOMES the interpreter — not an accelerator beside one.** One
execution path, and in the end it is the compiled one. This was undocumented anywhere until
07-29; a cold reader derives "accelerator" from the `jitting` gate in the source and then
misreads every JIT decision downstream (Clay did exactly that on 07-29 and argued for repairing
the interpreter's frames on the strength of it). **The statement, its two consequences and its one
open ruling now live in `docs/jit.md` §0 — read that before touching JIT work.** Headlines:
- **`saveLocalFields` gets DELETED, not repaired.** Locals-as-frames lands ONCE, in the JIT. The
  07-29 per-frame fix below is a deliberate **bridge**; its fixtures outlive it.
- The iterator becomes **two stack slots** (source, current) — no heap handle, no `isIterator`
  gate. Tony's usage already reads as pointer semantics, so no language design changes.
- **OPEN, Tony's:** during crossover, what happens to a construct the JIT cannot emit yet?
  Falling back to the interpreter *is* divergence, arriving as a schedule artifact. Candidate
  answer (the one that made mixed mode safe): **degrade to the oracle LOUDLY.**
- The whole class of *"will jitted and interpreted paths diverge?"* worries is **retired** —
  there is only ever one path.

### 2026-07-29's other work, in commits (details in each commit message, not repeated here)
```
77750cd  B0: claim format + tok-claim sweep
aabf7c7  Minion A harness: spawn rule, frozen brief, empty corpus, ledger
a4b72bb  Minion A harness: SEQ 30d rulings -- deferred baseline, claim-surface closer, abort
1bf80a0  Tony's Group-A work (GUI, Debug.rtn, docs, JSON fixtures)
552d60c  Tony's runtime work: rStuff-at-define rework + the iterator source (PRE-TOK)
3a8611f  Iterator Stages 1+2: flags tok'd, Iterate rule live, aCTionIterate compiles
60b237a  GroupMain: setRuleStuff on Limit's min and max -- POP back to GREEN
8a4e94a  auditRegistry: the verifier, presence-based -- found 3 more on first run
61b2487  B0: claims name their verifier
90f6366  audit: user-driven command, both directions, populations split and PINNED
6bd1928  Stage 3 WIP: ++/-- dispatch to iterAdvance -- reached, correct operand, then HANGS
015e9e8  incant/iterScratch: the iterator hang fixture
23df1b0  Iterator WORKS: runOP must not unwrap a handle. FWD a,b,c / BCK c,b,a
6abfd86  T1 PASSES: PER-FRAME. Cause was saveLocalFields
2401b61  T1 DEEP: coexisting cursors, exact order
80e5873  T1m: recursion coverage is DIRECT-ONLY. Mutual recursion loses locals
6bd642b  := is the iterator's only reset. T3 x4 GREEN. Sweep came back EMPTY
cc8eba6  Iterators FINISHED: runaway tripwire, the gate PROVEN, T1/T3 in pop.sh
```
### ⚠ TWO LIVE OPEN ITEMS FROM 07-29, and the first is a BUG in a hot-path function
1. **`runAction` empties a returned local when `recursive` is set** (corpus `CLAIM KANT-8`).
   `restoreLocalFields` runs **after** `processAction` and before the return, so an action that
   returns one of its own locals hands the caller that local **reverted to its pre-call state**.
   Measured three ways: return a **local** → emptied; return the **argument** → survives (that
   is the idiom until it is fixed); **mint a node into a local** → emptied. So it is about *which
   slot the returned pointer is*, not node identity — and `restoreLocalFields` is not itself
   wrong, restoring the caller's frame is its job; the defect is that `result` points into the
   frame being restored. **Same function whose `saveLocalFields` was fixed the same morning** —
   a second, independent hole in the same frame machinery. `emitPlan` recurses and must return
   text, so Minion A's step 3 inherits it. **THE FIX IS TONY'S** — both candidates touch the
   interpreter's hot path. Repro: two identical action bodies differing only by an *unreached*
   self-mention.
2. **A kant action cannot return NULL across `runAction`** (`BLOCKED KANT-B1`, IDIOM-GAP, five
   attempts with output pasted). Live consequence: the kant `spellLeaf` is *loud* on an unknown
   kind but does not *refuse*, so `emitPlan` would take junk text as a spelling. Suggested first
   move, untried: return the argument with a flag stamped via `:.` and test the flag C++-side.

### MINION A ROUND 1 IS IN, AND GREEN — `emitLeaf` is kant
`incant/genEmit` holds it (registry `Spellers`, action `spellLeaf`). `emitLeaf` **forks**: with a
`spellLeaf` registered it runs, without one the C++ body runs unchanged — so absent the kant file
every target still holds. **A registered speller's answer is authoritative INCLUDING NULL**, on
purpose: a fallback would let a kant defect silently produce the right text.
- `genLadder/spell.target` is its oracle — **the C++ `emitLeaf`'s own answer**, captured before
  anything moved: 5 plan kinds × both sinks. It reaches **`LITTO`**, which no ladder rung does,
  so `litTo`/`litOption` are gated only there. **`emitLeaf`'s own refusal arm is NOT covered** —
  the walk refuses anything the emitter would, so no plan node of an unknown kind ever exists.
- `spellMode` + `pop.sh`'s **speller pin** answer "which implementation produced this", because
  the fork is silent and the target is green either way. **Pinned at `kant`** — if it ever reads
  `c++` again the kant speller stopped being found.
- **The pick's decoupling argument was half wrong, worth knowing:** `emitLeaf` was chosen partly
  as "a table, not a walk — needs no iterator." True of the table, **false of the round** — `OPT`
  wraps a term and reaching it took `iterate inner on argument members`.
- Ledger `docs/minionAledger.md` (round 1's number entered; format held). Leak check is now
  mechanical: `sh docs/minions/roundTrace.sh <transcript>`, **read its WRITE SURFACE first**.

**THE ONE BUG WORTH NOT RE-DERIVING:** `saveLocalFields` copied the locals struct *including the
list pointer* and then cleared the shared object in place, so **no local carrying a list survived
recursion — since the initial commit.** Iterators were merely the first thing to notice.
Coverage is **DIRECT-ONLY**: `field.recursive` is inferred by identity against `currentMETHOD`
(`ruleActions.rtn`), so in `A → B → A` neither action names itself, neither gets flagged, and
locals are lost. `incant/iterT1m` is that hole, committed as a **pinned wrong answer** in
`pop.sh`. The sweep for live victims came back **EMPTY** — the bug was latent.

**`pop.sh` now has 22 checks** including `iterT1`/`iterT3`/`iterT1m`, `spell.target` and the
speller pin. The four old baselines came back byte-identical across the `saveLocalFields` fix,
because nothing in them reaches a recursive action with a list-carrying local — **baseline parity
was not evidence the fix was safe.**

### CLEAN STOP, 2026-07-29 — nothing in flight, nothing half-applied
```
sh genLadder/pop.sh    -> POP PASSED, 22 checks, exit 0
sh genLadder/tree.sh   -> exit 0 (§2.4 divergence unchanged — OPEN, not broken)
```
Working tree clean; everything on `jit-unified-emit-wip`. **Tony is reading round 1's kant code
offline** (`incant/genEmit`, ~30 lines) and rules on style — the ledger's correction count for
round 1 is marked PROVISIONAL until he does.

**`groups.ext` moved today and has NO COMMIT TRAIL** (bear-trap #11, it lives outside the repo).
Added: `iterSpins`, `dumpSpellings`, `locateSpeller`, `spellMode`, `spellKant` — plus a real fix,
`emitLeaf` was declared there with **two** parameters against a three-parameter definition, stale
since the `sink` argument was added. Extern canary 198 → 203, every addition accounted for.

**genParse's recursion shape, measured 07-29 (it decides Minion A's step 3, not today's work):**
`emitPlan` does **not** recurse at all — a flat two-pass walk that calls `emitLeaf`/`emitMany`.
`emitLeaf` **already self-recurses**, directly, for `OPT`'s wrapped term. `planRule → planTerm` is
one level; `planTerm` never calls `planRule`. All are C++ externs today, so recursion is free
stack frames — the coverage question bites only once they are **converted to kant**, and the
recursion that exists is the **direct** kind, which is covered. **A nesting rung must route
recursion through `emitPlan` itself, never `emitPlan → emitLeaf → emitPlan`** — that shape is
mutual, and mutual is the uncovered one.

⚠ **NAMING:** the spec (`genParseSpec.md` §4.2) and Clay's briefs say **`emitTerm`**. The live
function is **`emitLeaf`** (`genParse.rtn`) — renamed at the rung-3 seam. There is no `emitTerm`
in the source. Minion A round 1's target is `emitLeaf`.

## 2026-07-28's commits (branch `jit-unified-emit-wip`, in order)
```
da698e8  genParseShape steps 1-2: RuleStuff.parentLabel + one-argument parseMethod fnptr
e261e5d  genParseShape steps 3-7: term-first library, parseR, indexed emit, binding, POP
5c71db4  wakeup.md reseal + import Clay's SEQ 25 brief
ec34f59  RUNG 4 GREEN: a generated rule reached through another rule's reference term
a21e8ed  wakeup.md reseal for rung 4
30b7cd6  §1 census + FIX: `!rStuff` was never a classifier, and it dropped real terms
41a3831  rung 3a: plan vocabulary + walk builds plans, emission untouched (no-op)
835b5fc  rung 3b: emitter consumes the plan; old interleaved path deleted
092f96c  wakeup.md reseal for rung 3 + import SEQ 26 seam brief
4deaa6e  scope genParse's own lookup to rule registries (§1.3 second half)
af7e43d  genParseSpec §2.2a: Invariant R′, with its provenance checked
f6c599a  RUNG 5 GREEN: MANY + Invariant R′ demonstrated
502e7d0  wakeup.md reseal for rung 5
0463d51  RUNG 6 GREEN: OPT, the inline ((term) || 1) form
15712d1  wakeup.md reseal for rung 6
0ae2923  isGROUP ordering: reference wins; inline group a named future kind
3eb8398  RUNG 7: ALT emission — and §2.4's tree POP found a real gap
a5d541a  wakeup.md reseal for rung 7
168195b  rStuff at define time: late materialisation now fires ZERO times
```
(Session tip on arrival was `23d6888`.)

## POP LEDGER — every line RUN, exit status checked (the doctrine from 2026-07-27 holds)
| check | result |
|---|---|
| `oneTest` / `jsonTest` after **every** step | exit 0, **BYTE-IDENTICAL** (11 then 26 ×4 · 13 `ok`) |
| `genScratch` | **exit 0** — emission plus all four runtime cases |
| `Scaf('x')` · `Scaf('y')` | **WIN** · **FAIL, mark UNMOVED** |
| `Scaf2('{}')` · `Scaf2('{')` | **WIN** · **FAIL, mark REWOUND** — Invariant R both directions |
| `ScafB('ab')` · `ScafB('ax')` | **WIN through a reference term** · **FAIL, mark REWOUND across a nested generated call** |
| binder count guard, deliberately mismatched | **REFUSED**, and ScafA degraded to the interpretive walk |
| emitted text vs the compiled-in methods | **byte-for-byte identical** (rungs 1-2 and rung 4) |
| `grep -c extern GroupRules.h` | **166** (was 161; every addition accounted for — canary intact) |
| `genLadder/rung12.target` | regenerated **deliberately** — every line of the frame moved |
| `genLadder/rung4.target` | new |
| `genLadder/census.target` | 30 rules, plan-level, stable across runs |
| `genLadder/rung5.target` | repetition helper + method |
| `genLadder/rung6.target` | optional reference + optional literal |
| `genLadder/rung7.target` | new — alternation + its enclosing sequence |
| `ScafOUT('(a)')`/`('(i)')`/`('(x)')` | WIN · WIN · **FAIL, mark REWOUND** |
| census after ALT emission | **moved by ZERO lines** — nothing leaked across the seam |
| `ScafE`/`ScafF` × 3 each | optional present · absent · **failing mandatory neighbour, mark REWOUND** |
| `ScafC('ac')` · `('aaac')` | **WIN** · **WIN** (three passes) |
| `ScafC('aax')` · `('c')` | **FAIL, mark REWOUND** (R across a generated LOOP) · **FAIL, mark unmoved** |
| emission after the seam vs before it | **IDENTICAL**, whole genScratch run |

Note what the runtime rows now prove that they could not before: the wrapper is gone, so a green run
means **emission + the fork + binding + dispatch** all work. The old wrapper called `parseScaf`
directly and could have passed with the binding wholly unbuilt.

## THE MEASUREMENT THAT SETTLED THREE QUESTIONS — `dumpRuleTerms`, and it is kept
§1.5 says genParse must traverse with the same accessor the emitted code reads with. Whether a
`fail` modifier or a `code={}` tail occupies a slot is a question about the **tree**, so it was
measured (`incant/termScratch`, one run) rather than reasoned about. Findings, all load-bearing:

1. `rule[i]` is source order, 1-based. **`fail` occupies NO slot.**
2. **A `code={}` tail occupies FOUR slots, not one** — `CodE`, `this`, `tempField`, and a cached
   `BlocK` that appears **only after the rule has been parsed once**. The tail of `rule[]` is not
   even stable across a run. §1.5's hazard is real and bigger than the brief supposed.
3. **All four are `noPrint`; no real term is.** So the classifier is `noPrint` — and that is not an
   invention, it is the test `testAttributes` already uses (`if noPrint continue`). Model-not-oracle
   applied to classification itself: take the oracle's own test rather than a parallel one that can
   drift from it.
4. Sequence terms are `isAttribute`; alternation options are `isMember`. One list, distinguished by
   affiliation.
5. A rule-reference term (JSONblock's `JSONfield`) is a **DISTINCT NODE** from the registry rule of
   the same name — different parent — but the two **SHARE a child list**. `rStuff`, however, is
   **per node**.
6. **No rule-reference term is `isGROUP`, and none has `onGroup` set**, before or after a parse.

Re-measuring is one command: `<binary> incant/termScratch`.

## TWO CORRECTIONS TO THE BRIEF, both made against the tree
- **§1.6's `t2.onGroup` does not exist to be written to** (finding 6). A reference term is a node
  carrying `isRule` and sharing the referenced rule's list, so it **parses directly** — which is
  exactly what the interpretive walk does (`testAttributes` calls `grup.parse(stuff)` on the term
  itself, never on a dereferenced target). `parseR` was written for parity with the oracle rather
  than as a parallel mechanism.
- **§2's `rule.parentLabel` cannot compile as written.** `parentLabel` is a `RuleStuff` field and
  `GroupItem` does not forward to it, so the emitted line is `rule.rStuff.parentLabel`. Only
  deviation from §2's literal text.

## ⚠ ONE NEW THING THAT WAS NOT IN THE BRIEF, and it is load-bearing
**`leaveRule` must tolerate a NULL `into`.** Retiring the entry wrappers (§1.7) makes a generated
rule reachable from a top-level incant call, and `runRule` invokes `rule.parse(0)` — no parent
stuff, so `parentLabel`, and therefore `into`, is **null**. The interpretive path has always guarded
this (`parse()`'s attachment block is `if label && pStuff`); the guard is now also in `leaveRule`,
one implementer down. **Without it `Scaf('x')` dereferences null on its FIRST success.** Any future
exit primitive inherits this obligation.







## WHERE THIS STOPPED (2026-07-28, end of day) — clean kitchen
**Both POPs pass. Nothing in flight. Nothing half-applied.**
```
sh genLadder/pop.sh    -> POP PASSED   (7 rung targets + census + both baselines, exit 0 each)
sh genLadder/tree.sh   -> fixture ok   (§2.4 divergence unchanged — it is OPEN, not broken)
```
Landed today: **rung 3** (the walk/emission seam, plan-as-GroupItem), **rung 4**
(`definingRule()`, resolve-at-use-time binding), **rung 5** (MANY, Invariant R′), **rung 6** (OPT),
**rung 7** (ALT emission), and **rStuff at define time** — six rungs and one structural change,
every one with the baselines accounted for and exit 0.

Fixtures that did not exist this morning: the **census** (30 rules, plan-level), **tree.divergence**,
**pop.sh** as one command, and **rung4–rung7 targets**. Two of the three defects caught this week
came from rules nobody was working on — that is the census earning its place, and the argument for
growing it as rungs land rather than treating it as done.

**Tony is reading the day's work offline.** Design changes are possible but not expected. **If any
turn up, check them against the census** — it is the only artifact that speaks for the rules you are
not looking at.

**Uncommitted and NOT ours:** Tony's Group-A files (`Debug.rtn`, `Stylish.*`, `Layout.*`, `TODO.md`,
`docs/guiDesign.md`, `CLAUDE.md`, `incant/utilities`, `incant/jsonTest`, and the `.mm` regenerated
alongside them). Left exactly as found. **Do not run `tokall`** without checking with him first —
it would regenerate `Layout.twk`/`Stylish.twk` over his uncommitted work.

## rStuff IS MATERIALISED AT DEFINE TIME — late materialisation fires ZERO times
`getRStuff`'s `no rStuff - creating` warning fired **8 times in oneTest and 6 in jsonTest**. It now
fires **zero times, in all four fixtures**. The warning stays in place as the instrument: **if it
ever fires again, WHICH rule is the interesting part.**

**Measured first, and it moved the target.** Terms defined *from incant source* already materialised
at definition — `modify` calls `setRuleStuff`, and even an unmodified term comes back with rStuff.
The real gap was **the bootstrapper**, which hand-builds rules in C++: `GroupMain`'s `Limit` adds
`"["` and `"]"` with **no `modify()` call at all**, and applies its `+`/`*` to `item.group` (the
shared `counter` rule) rather than to the `min`/`max` terms.

Two call sites, both at a **completion point** rather than per-attribute — the ordering lesson rung 7
paid for:
- `aCTionDefinE`, just before `input.clear()`, where attributes *and* members are both in
- the bootstrapper, over `grok`, before setup is parsed (setup's own rules go through `aCTionDefinE`)

It materialises the **rule node as well as its terms**. Terms alone left exactly two late sites,
`define` and `InitiatE`, both rule nodes — which is how that was found.

**Uses `setRuleStuff`, per Tony's ruling: it only ever applies to rules anyway**, so the `isRule`
propagation is correct rather than a side effect to work around, and it keeps this to one
implementer. That propagation is **load-bearing, not cosmetic**: a reference term shares the
referenced rule's member list, so `isRule && hasMembers` is precisely how `parse()` dispatches into
a referenced alternation (`GroupItem.twk:1062`) and how `checkInput` suppresses its label
(`RuleStuff.twk:139`).

### The three deliberate moves
| moved | to what |
|---|---|
| `oneTest.base` | the 8 `getRStuff` lines removed, **nothing else**. 11 then 26 ×4, exit 0 |
| `jsonTest.base` | the 6 `getRStuff` lines removed, nothing else. 13 `ok`, exit 0 |
| `census.target` | exactly two rules, both bootstrap-built (below) |

- **`CodE`** — REFUSE (2 unmaterialised) → **plans**, as SEQ with two **LITTO** terms. LITTO and not
  LIT is **correct**: `incant/grammar:42` lists `CodE "{" "}" parseAction;` with no modifiers.
- **`Limit`** — REFUSE (3 unmaterialised) → refusal **moved** to `min` being isGROUP, the named
  inline-group kind. It now refuses on honest, named grounds rather than on "cannot tell".

### ⚠ FINDING: `Limit`'s `']'-` never had its modifier applied
`incant/grammar:52` lists `Limit '['- min=[0-9]+ max?=[0-9]+ ']'- noPrint;` — with the `-`. The
bootstrapper adds `"["` and `"]"` **bare**. A real divergence between the documented grammar and the
built one, invisible until materialisation made it readable. **`CodE` is NOT such a case** — do not
"fix" it to match a modifier its listing does not have.

This also **closes open item 2 by dissolving it**: there is no longer a window in which a term is
defined but unclassifiable, so the walk's unmaterialised-term refusal is now unreachable. Left in
place deliberately — it is a guard, not dead code to mourn.

## ⚠ RUNG 7 — ALT EMITS, BUT §2.4 IS OPEN. Read this before trusting an alternation.
```
extern GroupItem parseScafALT(GroupItem rule)
{
GroupItem   into  = rule.rStuff.parentLabel;      <- NO `label` local: §2.4, an ALT builds none
GroupItem   t1 = rule[1];
GroupItem   t2 = rule[2];
String      from  = atRuleMark;
    return leaveAlt(rule,from, parseR(t1,into) || parseR(t2,into) );
}
```
The fold decides the **sink** (`into` for ALT, `label` for SEQ) and the **joiner** (`||` vs `&&`),
both emitter-side. `litOption` is the ALT spelling of a labelled literal — re-read 2026-07-28: its
first parameter is **already** the term and unused exactly as `lit`'s is, so term-first was
satisfied; only the reasoning needed checking.

**The sharp POP held: the census moved by ZERO lines.** Emission changed no planning, so nothing
leaked across the seam rung 3 closed.

### THE TREE POP FAILED, and that is the result — not a regression
```
generated     ScafOUT -> ScafA        (winner keeps its OWN tag)
interpretive  ScafOUT -> ScafALT      (winner RETAGGED to the ALT's name)
```
Cause, read off `parse()`: an alternation member is `isTarget`, and the attach block does
`pStuff.label = label; label.tag = pStuff.ruleName`. **Right language, wrong tree** — every WIN/FAIL
check passes on it, which is exactly why §2.4 was told to use a tree comparison.

**Not new and not introduced here.** `RuleStuff.twk`'s RETAGGING NOTE (2026-07-25) records the same
divergence, found when a tail action received two children both tagged `GrouP` and silently
discarded the field. It was patched **by hand** in `parseJSONfield` and called *"a gap in
genParseSpec's sub(R) semantics generally"*. The seam now makes it fixable in one place.

**And the interpretive path is not self-consistent about it:** `isTarget` is set on only **11 of 16**
measured alternation members — `JSONvalue`'s `JSONblock`/`JSONarray`, `JSONtoken`'s
`JSONblock`/`NumbeR` and `DatA`'s `DelimText` do **not** have it. So it retags some winners and not
others, *within the same rule*.

**NOT GUESSED AT.** Which tag is correct — and whether `leaveAlt` should take `into` and retag — is
a semantics decision for Tony/Clay. The divergence is recorded in `genLadder/tree.divergence`, and
`sh genLadder/tree.sh` asserts it is **unchanged**: a fixture on an open item rather than a broken
gate. Settle it and the fixture moves, and whoever moves it accounts for the move.

### GUARDS — scoped, and the recommendation is SPLIT THEM OUT, well past rung 8
`getGuard` is ~70 lines of recursive first-set computation: cycle detection (`guardInProcess`), a
stop-at-first-mandatory-attribute rule tied to `min`, member union, set/data/registry special cases.
Reproducing it at generate time is an **arc, not a rung**. Two concrete blockers beyond size, both
read off the source:
- `if isMember && parent.guardSet  parent.guardSet += guardSet` — **getGuard MUTATES ITS PARENT**
- `setRuleStuff()` on entry — **it MATERIALISES rStuff**

So calling it from the walk **re-introduces tree mutation during generation**, precisely what rung 3
established the walk must not do, and it collides with the open rStuff-materialisation item too.
Unguarded ordered `||` is correct and merely slower — the ALT above has no guards and passes — so
guards are an **optimization**. §4.3's `_` already means "emit unguarded", so the plan has a place
for the distinction whenever it lands.

### Fixture note: an alternation must be bound in a SECOND define block
A definition attribute fires **when it is parsed**, so `parseMethod=` on an alternation's own line
runs *before its members exist*; the §3 count guard then sees 0 terms and refuses — correctly. A
second `define` re-opens the rule. Sequence rules are unaffected (terms on the same line).
**The count guard caught this itself.**

## isGROUP ORDERING — reference wins; "inline group" is a named future kind
Content-is-a-group and is-a-reference are **orthogonal**; two terms are both (`JSONtoken[5]`,
`DatA[2]`, both `NumbeR`). `data` used to be tested first so the overlap refused — right while the
precedence was unsettled. Settled now: **a term that names another rule is a call, whatever its
content**. What is left over is `isGROUP` *without* a reference — a group inlined at the term rather
than named — which is a **named future kind** and keeps refusing.

`JSONtoken` planning was the last gap, so **the JSON family is complete: all seven rules plan**
(14 of 30 census rules). `DatA` is *not* "likewise" — its refusal **moved** from `NumbeR` to `CodE`,
which is both a reference and `parseACTION`, and parseACTION is tested before the reference test.

## RUNG 6 — OPT. The label question was settled from `parse()` BEFORE anything was emitted.
```
ScafE isRule "e"- ScafA? "f"-;   ->  lit(t1,"e") && (parseR(t2,label) || 1) && lit(t3,"f")
ScafF isRule "f"- ","?- "g"-;    ->  lit(t1,"f") && (lit(t2,",")       || 1) && lit(t3,"g")
```
**What the interpretive path does with a non-matching optional, read off the source:** it takes the
min-0 rescue — `matchFailed` sets `sukcess = true` on `kount >= min` **before** `debugHere`, so
`debugHere` is skipped (label not zeroed, mark not rewound) and `generatedExit` returns the label
`checkInput` built. **But the attach lives inside the loop's success block** (`pStuff.label +%
label`), which a non-match never reaches. **So nothing is attached** — and the inline form agrees
exactly, because the callee's `leaveRule` attaches on success and not on failure. Non-match and
match-with-nothing stay distinguishable in the tree (nothing vs an empty child), which is what the
`code={}` actions read.

One divergence, recorded rather than relied on, and **generated is the tighter**: the interpretive
non-match skips the rewind and can leave the mark advanced by `checkInput`'s skip pass; the
generated callee rewinds to its own `from`. Both re-skip before the next term, so it is not
observable.

### One rung, not two — measured
Of the **12** optionals in the census, **4 are character-level** (`data` set) and already refuse
*above* the min/max test, alongside the accumulators. So `?` on a character-level term **never
reaches OPT by construction**, and §2.5's conflation warning cannot bite here. The other 8 are
**6 references** and **2 noLabel literals** — exactly the two shapes OPT wraps. A *labelled* literal
optional does not occur, so it refuses rather than being designed for.

### The POP case that matters
The optional sits **between two mandatory terms** deliberately. *An optional that swallows a
following failure is optional-as-mandatory inverted*, and only a mandatory neighbour catches it:
```
ScafE('ef')  absent  -> ScafA FAIL (mark unmoved), ScafE WIN
ScafE('eaf') present -> ScafA WIN,  ScafE WIN
ScafE('ex')  absent  -> ScafE FAIL, mark REWOUND      <- NOT swallowed
ScafF('fg') WIN · ScafF('f,g') WIN · ScafF('fx') FAIL, mark REWOUND
```

## RUNG 5 — MANY. One kind, iteration only.
```
ScafC isRule ScafA+ "c"-;
    extern int manyScafC1(GroupItem label, GroupItem term)
    {
    String      from = atRuleMark;          <- captured ONCE, at entry
    int         kount;
        while parseR(term,label)    kount++;
        if kount >= 1   return true;        <- min baked
        atRuleMark = from;
        return false;
    }
    ... leaveRule(rule,into,label,from, manyScafC1(label,t1) && lit(t2,"c") );
```
The helper is emitted by **emitPlan's first pass** — which is what the two-pass shape was built
for. **R′ is structural here, not promised:** `from` once at entry (mark clause); every pass goes
through `parseR`→`parse()` and builds a fresh label, with no `fLAG` anywhere (label clause). **R and
R′ compose** — a failing pass rewinds *itself* via the callee's `leaveRule`, so the helper only ever
gives back the whole run.

### ⚠ OPTIONAL IS NOW REFUSED, and that is the finding of the rung
An optional term (min 0, max 1) was planning as a **plain conjunct** — so it would have emitted as
**mandatory**: `lit(t4,",")` where the hand-written model wrote `(lit(rule,",") || true)`. Four
census rules were affected (`JSONfield`, `JSONitem`, `JSONarray`, `InvokE`) — they were planning a
parser that **accepts too little**. They refuse until optionality gets its own kind. One kind per
rung.

Measured min/max shapes: **40** terms plain (1,1) · **12** optional (0,1) · **4** star
(0,unbounded) · **5** plus (1,unbounded). Unbounded sentinel is **268435457**.

### ⚠ min ≥ 2 IS UNREACHABLE THROUGH THE GRAMMAR — pre-existing, and it is not just latent
- `X[2]` → **rejected outright**: `ERROR Operator - failed on isRule and Token`
- `X[2 9]` → parses, prints `nextGroup: ERROR max does not contain a list`, and **leaves min/max at
  1/1** — the limit is **silently not applied**
- `setLimits` itself reads correctly (`ruleStuff.min = minimum.count`), so the fault is **upstream
  of it**

genParseSpec §2.2 says R′'s mark clause is "latent until someone writes `X[2]`". It is stronger than
that: you *cannot* write it. This is why the mark clause is demonstrated as a **controlled
comparison** rather than as a ladder rule.

### Invariant R′ DEMONSTRATED — a passing run proves neither clause
```
MARK,  input "a" against a term needing 2:
  entry-saved (emitted) : matched 1 of 2 -- REWOUND to loop entry
  per-pass  (parse())   : matched 1 of 2 -- rewound only to the FAILED PASS, input STRANDED
LABEL, input "aa":
  2 passes attached 2 FRESH labels          (a recycling loop would show one)
```
`demoRprime` in `genParse.rtn`. A first cut reported "STRANDED" on a **successful** run, because it
compared the mark to loop entry without first asking whether a rewind was due. Fixed before landing
— **a POP that reports a false signal is worse than no POP.**

## genParse's OWN lookup is now scoped (§1.3's second half)
Emitted text has carried no `locate` since the shape brief; **the emitter still ran one**, and a
bare `locate()` resolves down the *general* search stack — search registries, then base registries
(`pROPERTIEs`, `Operators`, `cOMMANDs`, `fILEs`, `Keywords`, `GroupFields`). Any rule sharing a name
with a keyword or command was a **silent mis-target**.

`locateRule` walks the search list and accepts **only `isRule` hits**. `ruleOrRefuse` names which
problem it is — "no rule of that name" and "that name is a keyword, here is its registry" are
different.

**Correcting `41a3831`'s guess:** `debug` resolves to a **not-isRule node in Keywords**
(`incant/setup:196` defines it as a bare keyword), *not* cOMMANDs. The real grammar rule is
**`DEBUG`** — isRule, Grokking, four terms. So there is no lowercase `debug` rule and it now refuses,
correctly. **Why it could not wait:** the mis-target was visible only because that node happened to
carry no terms. A collision with a node that *has* terms would have produced a plausible-looking
plan and nothing would have complained.

## RUNG 3 — THE SEAM IS CLOSED. Read this before touching genParse.
`planRule` **decides**, `emitPlan` **writes**. The artifact between them is a **plan tree of
GroupItems** — resolved decisions, baked literals, **no target syntax anywhere**. It is the bytecode
move one level up.

**Five kinds, and that is the whole vocabulary** for rungs 1, 2 and 4:

| kind | carries |
|---|---|
| `SEQ` | rule tag, `label`, ordered conjuncts (members, in order) |
| `ALT` | rule tag, ordered disjuncts, no label |
| `LIT` | literal text (noLabel) + `at` = baked `rule[]` index |
| `LITTO` | literal text + `slot` + `at` |
| `CALL` | the term to parse through + `at` |

It grows **one kind at a time as a rung demands it** — `MANY` with rung 5, `GUARD` with the
alternation rung, `ACT` when actions land. **If the vocabulary ever comes back complete, it is too
big** — that is the tell this rung went wrong.

### THE RULING THAT MATTERS MOST — positive tests only
**Every plan node comes from a positive test, and an unclassified term is a REFUSAL, never a
default.** This is the one place genParse must **not** copy `setTestMatch`: there, references are
classified by **fall-through** — "no row matches" *is* the answer, and `parse()` collects them on
the `hasAttributes` arm. Inherit that residual and every future unmatched kind becomes a **silent
bogus CALL** — and the census says the unmatched group is the **largest one**, so that failure would
be easy to write and hard to see. `definingRule() != term` is what turns the residual into a
positive, pointer-based property.

**Loud refusal over quiet skip, everywhere in the walk.** Both defects found today were quiet skips.

### What sits on each side (do not let these drift back together)
- **Walk** — fold selection, the `noPrint` gate, classification, baked indices, and **all
  refusals**. A refusal is a validity question about the *rule*, so it reads the same whichever
  emitter is downstream.
- **Emitter** — the frame preamble, joining conjuncts with `&&`, quoting, and **which support
  function spells a decision the walk already made**. `LIT`/`LITTO` carries "does this attach a
  label"; that a `LITTO` in a `SEQ` is spelled `litTo` (and in an `ALT` would be `litOption`) is
  emitter work.

`emitPlan` walks the plan **twice**, once to validate and once to write. Deliberate: §3.3's helper
functions are discovered mid-walk, and with text already going out you must buffer or emit out of
order. With a plan you walk it again.

**ALT is now REFUSED, not emitted.** The old interleaved path would have written a `SEQ` frame with
`&&` joins for an alternation — simply wrong, and invisible until there was an artifact to look at.

## GROW THE CENSUS AS RUNGS LAND — it is not a finished artifact
**Two of the three defects the ladder has caught came from rules nobody was working on, both via
the census** (`debug`'s empty fold; the four rules planning optionals as mandatory). The ladder
targets test the rung you are on; the census tests the rules you are not looking at. Add to it when
a rung lands, and treat a census move as something to *account for*, never to regenerate green.

## THE CENSUS FIXTURE — the classifier's own POP
`genLadder/census.target`, 29 rules, produced by `<binary> incant/censusScratch`. The ladder targets
**cannot** test the classifier: Scaf/Scaf2/ScafA/ScafB reach two kinds out of five and never carry
an unmaterialised term. This asserts a plan **or a named refusal** for every term, **at plan level**,
so it is target-independent and survives the kant emitter unchanged.

**It found a bug on its first run:** `debug` planned as a `SEQ` with **zero conjuncts** — same shape
as the `CodE` `(null)` defect, different cause (`locate('debug')` resolves to something carrying no
terms; the cOMMANDs entry, not the grammar rule). An empty fold is now a refusal.

### The plans, the day the seam was introduced (SEQ 26 §6)
```
PLAN Scaf                PLAN Scaf2               PLAN ScafB
  SEQ Scaf                 SEQ Scaf2                SEQ ScafB
    label=Scaf               label=Scaf2              label=ScafB
    LIT x                    LIT {                    CALL ScafA
      at=1                     at=1                     at=1
                             LIT }                    LIT b
                               at=2                     at=2
```
This is the first artifact in the project that a C++ emitter and a kant emitter would both have to
agree on.

## §1 CENSUS — §4.2's table vs the tree. VERDICT: several rows wrong.
27 rules / 73 terms; the JSON family **plus** a spread of the real bootstrap grammar (restricting to
JSON would have flattered the table).

| §4.2 row | count |
|---|---|
| **NO ROW MATCHES** | **24** |
| default `lit`/`litTo` | 19 |
| `isSET` | 11 |
| (no rStuff yet) | 5 |
| `isGROUP` | 4 |
| `upToOver` · `parseACTION` · `isCHAR` | 1 each |
| `upTo` · `isBIN/isREGISTRY` · `isANY` · `isMacro` · `isCondition` | **0** |

- **The largest group falls in no row, and all 24 are rule-reference terms.** They fail every branch
  and `!contents()` is false (they carry the shared list), so `setTestMatch` leaves `testMatch` null
  and `parse()` reaches them on the `hasAttributes` arm. **References are handled by fall-through,
  not by `onGroup`.**
- **The `isGROUP` row exists but means something else** — *content-is-a-group* (`min=[0-9]+`,
  `NumbeR`→`numberSet`), not "a rule reference". Orthogonal properties, conflated by the table.
- **§4.1's `if rule.onGroup` is dead** — 13 of 13 reporting rules NONE, zero positives anywhere.
- **§4.1's `if rule.data` is live and unimplemented** — 6 rules carry rule-level data
  (`FloaT` isCHAR, `PoweR` isSET, `Modifier` isSET are accumulator cases). The walk **refuses** them
  until rung 5.
- §4.1's **fold test itself held**: ALT 4 / SEQ 23.

So the walk is a **fresh classifier written against the tree**, not a transcription of
`setTestMatch` — which makes the seam a *correctness* argument rather than a tidiness one: it is new
code you would otherwise write twice.

## NAMED OPEN ITEMS from the census (not unnoticed ones)
1. **`isGROUP` + reference is a real overlap with no precedence rule.** Two terms are both
   (`JSONtoken[5]`, `DatA[2]`, both `NumbeR`). `planTerm` tests `data` **before** the reference test
   so the both-case **refuses** rather than silently becoming a CALL. What it means semantically is
   unsettled and no ladder rule reaches it.
2. **Where do modifiers live before rStuff exists?** `Limit`'s `']'-` has a source modifier and no
   rStuff to hold it. Unknown, and it is why eager materialisation would **fabricate** a
   classification rather than discover one.
3. **`locate('debug')` finds a term-less node** — a name collision between the `debug` command and
   the `debug` grammar rule. Surfaced by the fixture; nobody has looked at it.

## MEASURED, because it was flagged as a hazard to check rather than assert
**Eager materialisation via `getRStuff` CANNOT reach `getWhatFollows`'s `parent.rStuff.min = 0`** —
the §7.1 write. `getRStuff` constructs and `setRStuff`s, nothing more; `getWhatFollows` has exactly
**one** caller, `getStuff`, gated on `!followed`. The hazard is real but **bounded to `getStuff`**.
Refusing is still right, for a second and independent reason — see open item 2 above.

## RUNG 4 — SOLVED. The route exists, and it is a pointer walk.
The question that gated it: `parseMethod` lives on `rStuff`, `rStuff` is PER NODE, so a reference
term has its own and was never bound. Binding a rule therefore looked like it could not reach the
terms that reference it — which is exactly what mixed mode needs.

**Measured, not reasoned (the same `termScratch` method):** a reference term shares the defining
rule's child list, and **the children are parented to the DEFINER** — so `term[1].parent` **IS the
defining rule, by pointer.** Verified against what `locate()` returns for the same name on
`JSONblock→JSONfield`, `JSONfield→JSONtoken`, `JSONfield→JSONvalue`.

`GroupItem.definingRule()` is that walk. **It needs no guard because the test discriminates:** a
node that OWNS its children (a defining rule, and also `CodE`/`BlocK`) routes back to ITSELF, and a
leaf term has no children at all — both fall through to `return this`. Only genuine references
resolve elsewhere.

**The ruling: resolve at USE time.** `parse()`'s fork reads `parseMethod` from `definingRule()`, so
binding a rule once reaches every reference to it **including references created later**. No
registry sweep (would miss late references), no `locate` (§1.3 forbids it).

### The shape/frame split, and why the two fields go to DIFFERENT nodes
- **`parseMethod` is SHAPE** — one answer, always the same for a rule → read from the **definer**.
- **`parentLabel` is FRAME** — it varies per invocation and is the field that carries the variation
  → stays on **`this`**, the node actually being parsed. Routing it to the definer would make every
  reference to a recursive rule write the **same slot**, which is correct-looking right up until the
  recursion is live.

**The general tell, worth more than this instance: a field that looks like it belongs with the rule
because it is usually the same is exactly the dangerous case.** (Clay corrected his own near-miss on
this twice in one session, on Tony's lesson.)

`this` is what gets passed to the generated method, not the definer — the two share a child list so
`rule[n]` reads the same terms from either, while `rule.rStuff.parentLabel` must be this
invocation's.

## THE COUNT GUARD — and it has been made to fire
Every emitted `rule[n]` bets the list only ever mutates BEHIND the real terms. The cached `BlocK`
appearing after a rule's first parse proves the list *does* mutate at runtime, and nothing enforced
the bet. Now: `RuleStuff.termCount`, recorded by a **`parseTerms=N`** binding attribute, checked by
**`parseMethod=`** before it installs anything.

`countRuleTerms` is the **ONE implementer** of "real term" — the emitter bakes indices with it and
the binder re-checks with it. A check using its own private notion of the classifier would be worth
nothing.

**Negative test, RUN:**
```
parseMethod: REFUSING to bind parseScafA to ScafA
             emitted against 9 terms, rule now has 1
```
and note the behaviour on refusal: ScafA fell back to the **interpretive walk** while ScafB still
ran generated and still WON. **A refused binding degrades to the oracle rather than breaking** —
mixed mode doing exactly its job. Reproduce with:
`sed 's/ScafA isRule "a"- parseTerms=1/ScafA isRule "a"- parseTerms=9/' incant/genScratch > /tmp/g && <binary> /tmp/g`

`termCount` 0 means unrecorded, which **binds with a warning** rather than refusing — a silent trap
would be worse than an unguarded one.

## RUNG-4 POP (all RUN, exit 0)
```
ScafA isRule "a"-;                  ScafB isRule ScafA "b"-;      both generated, both bound
emitted:  return leaveRule(rule,into,label,from, parseR(t1,label) && lit(t2,"b") );
ScafB('ab')  ->  HIT/WIN ScafA nested inside HIT/WIN ScafB
                 ScafA's GENERATED method ran, reached through a reference term
ScafB('ax')  ->  ScafA WINs, lit "b" fails, FAIL ScafB with mark REWOUND
                 Invariant R across a NESTED generated call
emitted text == compiled-in source, byte-for-byte   (genLadder/rung4.target, new)
```
Reading the trace: `HIT` prints at the top of **leaveRule**, which is the rule's EXIT (§1.8 moved
instrumentation into the library, so there is no entry hook). One HIT per invocation, so §6.1's
attempt count is right; only the ORDER reads oddly — a callee's HIT appears before its caller's.

## Also landed, worth not re-deriving
- **§1.8 instrumentation is in the library, gated.** HIT/WIN and Invariant R live in
  `leaveRule`/`leaveAlt` behind `GroupRules.parseTrace` (off by default, so baselines cannot move;
  `traceParse('on')` turns it on). One implementation, every rule, no emitted lines, survives the
  kant handover. This is what replaces `runScaf`'s R-inner/R-outer prints — R is a property of the
  **failure path**, so `Scaf()` alone could never show it.
- **`runScaf`/`runScaf2`/`runJSONblock` are RETIRED.** Do not re-emit an entry wrapper.
- **JSON models converted** to the same shape using the **measured** indices. They stay dormant
  (nothing invokes them; JSON is last by ruling). `parseGeneric` survives with no callers —
  `parseR` subsumes it.
- **`setParseMethod`** does the `void*` → typed-fnptr cast in `-% %-` passthrough, because tok has
  no syntax for it. Its body is entirely passthrough and everything arrives as a **parameter**
  (bear-trap #13: an incant-level local referenced only inside a passthrough is pruned as unused).
- **Latent, flagged not carried:** `emitTerm`'s labelled branch emits `litTo`, which has **no
  implementation** in the support library. Never fires for rungs 1-2/4 (all terms `noLabel`).
- **`emitTerm` now classifies**: a term whose `definingRule()` differs from itself emits
  `parseR(tN,label)`; literals still emit `lit`/`litTo`.
- **A `noPrint` definition attribute does NOT persist in the rule's list** — "fire and forget" is
  literal. Measured: `Scaf isRule "x"- parseMethod=parseScaf;` leaves `Scaf` with exactly one entry.
  That is why the term count needed a real field and could not ride on a sibling attribute.
- **tok note, and it has bitten twice now:** juxtaposed concat does not work in **return position**
  (`return "a" b;` -> `FAIL Block`/`ERROR Inheritance`, taking the whole extern with it) **or in
  argument position** (`f(x, pad "  ")` silently generated a THREE-argument call, caught only by
  the C++ compiler). Concat into a local first, always. Assignment position is fine.

## NEXT — Clay's standing order (SEQ 27 §5), each waiting on the one before it
0. **Recon owed before B can be briefed** — read-only, perturbs nothing. TWO greps:
   *(a)* what do rule actions actually return, and how do they locate a child? Tag-locating actions
   survive B; position-locating ones may not. *(b)* which bootstrap-built rules add terms with no
   `modify()` call — i.e. confirm `Limit` is the only one, or find the others.
1. **B — drop the automatic `isTarget` stamp on members.** Tony's ruling: `isTarget` becomes `@` and
   nothing else. `genLadder/tree.divergence` flips from asserting the divergence to asserting
   AGREEMENT — that flip is the acceptance test. Expect quiet fallout, not loud: a wrong result, not
   a failed parse. This is §2.4's retag question below, and it gates the JSON family end-to-end. The whole family plans and
   emits, but the trees diverge, and the hand-patched RETAGGING NOTE in `parseJSONfield` is the
   same bug. Decide whether `leaveAlt` takes `into` and retags. Note the interpretive path is not
   self-consistent, so "match the oracle" does not fully determine the answer.
2. **Accumulators** — `data`-carrying repetition (`FloaT`/`PoweR`/`Modifier`/`NamE`), still refused.
   §2.5: star and plus mean something different for character-level terms than for references, and
   conflating them yields a parser that accepts correctly and BUILDS WRONGLY.
3. **D — the guard arc**: genParse's own NON-mutating first set. Not a call into `getGuard` — see the
   scoping above. An arc, not a rung.
4. **Inline group** — `isGROUP` without a reference, the named future kind. `Limit` refuses on it.
5. Standing tripwire: the interpretive path does `kount++` on success, the generated path does not.
4. **Rung 9 is TONY'S RULING and gates only rung 9** — bare reference to an alternation:
   auto-`promoteR`, or require explicit `@`?
5. **§4.2 / §4.3 fixes, after shape**: make `lit`'s skip pass non-destructive (then `leaveAlt` drops
   to `(rule, ok)`); end-of-input normalization beside `checkSkip`.
6. **§7.5's result-discard is LOCATED but UNFIXED**, and it is on the path to a working POP, not
   behind one: until it is fixed no test on failing input reads honestly. Narrowing from 07-27: the
   discard sits **above `runOP`, or in the script-level invocation**; `parse()`, `runRule`, `runOP`
   and `matchFailed` are all exonerated.
7. JSON LAST, and only once `jsonTest` is a clean oracle again.

## STILL OPEN from 2026-07-27 — none of it closed today
- **DIVERSION BOUNDARY NOT RESPECTED DURING MATCH.** A failing parse reads past the end of its
  diverted buffer into the enclosing script text *while matching*; the tell is a `Failed at:` window
  containing the script's own source. Process exits 0 (crash fixed 07-27) but following statements
  are swallowed. **Consequence: `jsonTest` still cannot run multiple failing cases in one process**,
  so §7.1's inverted-ordering fixture stays REQUIRED (well-formed to arm, malformed to read, nothing
  after, ONE process).
- `jsonTest`'s last case is annotated `KNOWN TO FAIL` while printing `ok` — **when the
  invocation-layer bug is fixed it flips to a real failure, which terminates the run, so jsonTest
  will appear to break at the moment the bug is fixed.**
- **`ruleSTUFF` is a WRITE-ONLY GLOBAL** (Tony's ruling 07-27). Exactly one reader,
  `GroupActions.rtn:269`, and that local is never referenced again; inert since the initial commit.
  Leave `parse()`'s own write and the global's declaration alone — `parse()` is the parity anchor.

## FINDING — pre-existing, surfaced not caused (report, do not chase)
`Commands.rtn`'s `testing()` had been **hijacked** to call `runScaf` twice. Since `runScaf` retired
it had to change, and it was restored to what its own doc comment describes (`jitRunAction` for a
coded argument, `jitRunIfTest` otherwise). **`incant/jitscratch` therefore exercises the JIT for the
first time in a while, and it crashes (139) on the `jitInc` fixture:**
```
0  jitEmitUnary  GroupRules.mm:2424   <- crash
1  opPlusPlus    GroupRules.mm:3904
2  runOP · aCTionBlocK · jitExecBlock · jitRunAction · testing
```
Squarely in the JIT arc (`++`'s emit path), nothing to do with genParse. `jitscratch` is not a
baseline and was not passing before in any meaningful sense — the old body never called
`jitRunAction` at all.

## Open, Tony's (carried forward, none touched today)
- **TODO.md cause-1 entry** — annotate as dead-since-`875b936`, don't strike. His file.
- **Bear-trap #18's ATTRIBUTION** — split into a confirmed OBSERVATION (keep as doctrine) and an
  OPEN attribution with four candidates, one of them Clay's own spec error. Tony signs off.
- **`GUI/Layout.twk` and `GUI/Stylish.twk`** share basenames with the top-level files he edits, and
  `tokall` only ever sweeps top level.
- His Group-A work (Debug.rtn, Stylish, Layout, TODO, guiDesign, incant/utilities+jsonTest) is still
  uncommitted.

## THE POP IS ONE COMMAND NOW
```
sh genLadder/pop.sh     # every ladder target + census + both baselines, exit status checked
sh genLadder/tree.sh    # §2.4 tree fixture — asserts the OPEN divergence is unchanged
```
`pop.sh` prints one line per check and the diff when something moves. Baselines live in
`genLadder/` so it is self-contained. I hand-rolled these checks every rung and got the escaping
wrong once; this exists so nobody does that again.

## Run recipe / reproduce
- Binary: `~/Library/Developer/Xcode/DerivedData/InProcess-ezzmcllcsvijqmbipricnduikqfp/Build/Products/Debug/Groups`.
- Build: `cd ~/Library/CloudStorage/Dropbox/data/InProcess && xcodebuild -workspace
  InProcess.xcworkspace -scheme Groups -configuration Debug build`.
- `.rtn` (genParse.rtn, Commands.rtn, GroupActions.rtn, ruleActions.rtn) are `include`d into
  GroupRules.twk → edit one, then **`tok GroupRules.twk`** (NOT a standalone retok). Standalone
  class files (`RuleStuff.twk`, `GroupItem.twk`…) → `tok <File>.twk` directly.
- **`tokall` is a shell FUNCTION** — `for item in *.twk; do tok $item; done`. Top-level only (13
  files); misses 14 below (`GUI/`, `GUI/Stuff/`, `Tests/`). After a layout change, grep those
  generated files for the class you shifted. Today: only `GUI/Bwana.mm`, and it merely `#include`s
  `GroupRules.h` without touching a field — nothing owed.
- **`groups.ext` lives OUTSIDE the repo** at `~/Dropbox/data/InProcess/Include/groups.ext`
  (bear-trap #11). It now carries `parentLabel`, the one-arg `parseMethod`, `parseTrace`, `parseR`,
  `parseRuleMethod`, `traceParse`, `dumpRuleTerms`, the renamed `leaveRule`/`leaveAlt` params and
  the one-arg JSON parse decls — and `runScaf`/`runScaf2`/`runJSONblock` removed. Rung 4 added
  `termCount`, `definingRule`, `countRuleTerms`, `parseTermCount`, `parseScafA`/`parseScafB`.
  **No commit trail exists for any of it.**
- genParse ladder: `<binary> incant/genScratch` → emits parseScaf/parseScaf2, then runs
  `Scaf('x')`/`('y')`/`Scaf2('{}')`/`('{')` with the leaveRule R report. POP:
  `sed -n '/^extern GroupItem parseScaf(/,/^}/p;/^extern GroupItem parseScaf2(/,/^}/p'` of the
  output vs `genLadder/rung12.target` (empty diff = PASS).
- Term measurement: `<binary> incant/termScratch`.
- Baselines: `<binary> incant/oneTest` → `maximus = 11` then `26` ×4; `<binary> incant/jsonTest` →
  13 `ok` — **13, not 14**; the briefs carried 14 and Clay has corrected it. **Capture BEFORE
  changing anything and `diff` after.**
- Census POP: `<binary> incant/censusScratch 2>&1 | grep -v "^getRStuff" | sed -n '/^PLAN /,$p' |
  grep -v "^Search list:" | grep -v "^stop:" | grep -v "^$"` vs `genLadder/census.target`.
- Crash frames without Xcode: run under `script -q /dev/null` (segfaults lose buffered stdout).
- No `timeout` on this shell — background + kill anything that might hang.

## HOW TO WEIGHT A CLAY BRIEF (earned 2026-07-27, held again today)
The split is **structural vs causal**, not design-vs-tree. Today's structural claims all held (one
argument, derived `into`, term-first, no locate, no wrapper, instrumentation in the library,
through-the-fork). The two that needed correcting were both **claims about what is in the tree**
(`t2.onGroup`, `rule.parentLabel`) — same family as the five that failed on 07-27.
**Take the distinctions, check the attributions.** Cost of checking: one measurement run.

## PARKED by Clay (SEQ 26), neither blocks the ladder
`jitEmitUnary`←`opPlusPlus` (see the finding above), and the LLVM-IR-for-inlining question raised by
routing `parseR` through the fork. Both are JIT-ladder work.

## THE WALKIE-TALKIE HAS ITS OWN DOC NOW — `docs/walkieTalkie.md`
One pointer, by that file's own instruction: its content stays there, not here. It is Clay's
2026-07-29 rulings on the Clay↔Clod channel, in the B0 claim format. **Read it before writing
anything into `ipc/`.** The three that bite hardest:
- **WT-11 — NO SILENT OVERWRITE.** A write carries the whole file, prior history included.
  Downloading or rewriting atop a file *replaces* it, and an unread turn vanishes with nothing
  saying so. **Broken once already, by Clod, on 2026-07-29** — `clod-to-clay.md`'s SEQ 17 was
  still `fresh` when SEQ 18 went over it (erratum + reconstruction are in that file's header
  and foot). The rule binds both directions.
- **WT-9 — direct write is proven, so route deliberately:** a brief Clod will act on gets
  dictated and transcribed, because *the transcription step was a second close reader*;
  reference docs get downloaded straight in.
- **WT-10 / WT-13 — the channel is ASYMMETRIC.** Clod polls `ipc/clay-to-clod.md` for an
  on-disk change; Clay cannot poll anything and reads only when Tony prompts him.

**Open and assigned to Clod in that file's PLAN step 1** (untouched, and it wants Tony's nod
first because it puts repo files into a sync path): expose `ipc/` to Clay read-only via the
Drive connector. Step 2 says **measure before building** — if removing the paste step only
saves typing, MCP is not worth a build.

## Working relationship (unchanged)
Tony (Haps) = architect/final authority. Clay (claude.ai) = design/reasoning. Clod (Claude Code) =
execution/edits/build. Standing permission: change source freely, commit/push routine work at
discretion.
**Walkie-talkie transport is SETTLED: Clay has NO filesystem reach — read-only uploads only. CLAY
DICTATES, CLOD TRANSCRIBES; Clod owns every `ipc/` write in both directions.** SEQ 25
(genParseShape) arrived as a file in `~/Downloads`, imported to `docs/genParseShape.md`.
SEQ 26 (rung 4) arrived in chat; SEQ 26's seam brief as `docs/genParseSeam.md`.
`grep -H '^STATUS:' ipc/*.md` is Tony's window.
