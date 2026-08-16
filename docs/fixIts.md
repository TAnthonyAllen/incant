# fixIts — the capture queue

**Created 2026-08-16, Tony's call.** *"Measurement generates these, but then we stop what we are
doing when it makes more sense to stash them on a fixit list and maybe sic a minion at it."*

## WHY THIS FILE EXISTS, AND WHY THE OTHER TWO DID NOT COVER IT

| file | what it is | why a fixit does not fit |
|---|---|---|
| `docs/knownErrors.md` | the **deep-defect register** — KE-1..KE-6, long-form, each with measurement, discrimination and a ruling owed | too heavy. A KE entry is an investigation; most fixits are two lines and a file reference |
| `TODO.md` | the **roadmap** — 699 lines organised by arc and phase | organised by *design intent*, not by *what is broken now*. A fixit has no arc |
| commit messages | where fixits have actually been living | ⚠ **unreadable as a queue.** A finding in a commit message is recorded and simultaneously lost |

**THE RULE THIS FILE ENCODES: CAPTURE, DO NOT CHASE.** A measurement taken for one purpose
routinely turns up a defect belonging to another. Stopping to fix it derails the task that found
it; mentioning it in prose loses it. **It comes here, with enough evidence that nobody has to
re-derive it, and the finder goes back to what they were doing.**

**A ROW IS MINION-READY OR IT IS NOT A ROW.** Every entry carries: what is wrong, WHERE (file:line),
the EVIDENCE that it is real, and what "done" means. If a row cannot be handed to someone with no
context, it is not finished being written.

**Status vocabulary:** `open` · `parked <by whom>` · `closed <how>`. A closed row stays for one
cycle so the trail survives, then moves out.

---

## OPEN

### F-2 — the generator now walks the new literal attributes
**Where:** visible in `incant/oneTest` output; origin is the labelled-literals grammar change.
**What:** `BlocK` went from `length 1` to `length 3`, and the codegen path now emits
`runGenerated:  { ;` and `runGenerated:  } ;` — the punctuation is reaching the generator as
material.
**Evidence:** `oneTest` diff vs `genLadder/oneTest.base`, the non-audit half; three repetitions.
**Status:** benign today because nothing consumes it. **Flagged by Tony as affecting generator
work**, so it wants a decision before the generator arc moves, not after.
**Done when:** ruled — either the generator skips label-only literal attributes, or the emission is
declared correct and the baseline absorbs it.
**Owner:** Tony. **Size:** unknown, wants assessment first.
⚠ **BLOCKS A RE-PIN:** `genLadder/oneTest.base` cannot be re-pinned until this is ruled — the
baseline carries these lines, so capturing over it would silently bless the behaviour. That is
why `oneTest baseline` is still red at 39 green with everything else in it accounted for.

### F-3 — `JSONarray`'s guard is an existence test, not a has-a-list test
**Where:** `incant/utilities:74-76`.
**What:** `JSONlist?` is OPTIONAL; the guard is `if JSONlist;`. After a populated array parses, the
node stays truthy while its list does not survive, so a later empty array walks a leaf.
**Evidence:** minimal reproducer is TWO parses and order matters —
`[x,y]` then `[]` **fires**; `[]`, `[] []`, `[x,y]`, `[]` then `[x,y]`, `[x,y] [x,y]` all clean.
Symptom `nextGroup: ERROR JSONlist does not contain a list`. One `pop.sh` red (`jsonTest baseline`).
**Narrowed:** `ruleActions.rtn` is **NOT** the owner — reverted, rebuilt, error persisted. Remaining
space: `Instruct.rtn`, `GroupActions.rtn`, `RuleStuff.twk`, `GroupItem.twk`, `incant/grammar`, HEAD.
⚠ **May be latent-and-newly-exposed rather than new** — the guard has always been existence-only.
Settle that before "fixing" `utilities`.
**Owner:** unassigned. **Status:** `parked Tony` 2026-08-16 — *"not something I want to worry about
now."* **Size:** small if the guard is the fix; unknown if the exposure is.

### F-4 — `docs/gui.md` cites files a fresh clone no longer receives
**Where:** `docs/gui.md:729` and `:818`, citing `Aside/WithJIT/ParseXML.rtn` as the verified
track-builder to "bring in before porting". Also `docs/plg-*-recon-2026-05-29.md` citing
`Aside/BeforeSimple/ParseXML.*`.
**What:** `Aside/` and `BackupIncant/` were ignored and untracked 2026-08-16 (`b1482ff`, `2364b05`).
Files remain on disk here and in history everywhere, but not in a bare clone's working tree.
**Done when:** those citations say how to recover the file
(`git show <ref>:Aside/WithJIT/ParseXML.rtn`) instead of naming a path.
**Owner:** unassigned. **Size:** doc edit, three references. **Good minion candidate.**

### F-5 — two repos carry uncommitted work nobody has accounted for
**Where:** `InProcess/Parse` — `PLG.C`, `PLG.twk` modified. `InProcess/Tokf` — `Name.h` untracked.
**What:** neither was mentioned in the 2026-08-16 reconciliation; both predate it.
**Done when:** each hunk gets H8's verdict — commit, revert, or named-WIP with an owner.
**Owner:** Tony. **Size:** one look each.

### F-6 — the correction owed to commit `6212a71`
**Where:** the message of `6212a71`.
**What:** it flags `Generate.rtn`'s removal of `parseRule`'s jitting gate as a running-code change.
**That is wrong.** `jitting` is raised only inside `jitRunAction`, so during parse it is false, and
`if jitting && jitRunAction(field); else result = processAction(field);` is behaviourally identical
to `result = processAction(field);`. The removal is inert in every reachable configuration.
**Done when:** recorded in a later commit message (history is pushed; the fix is a record, not a
rewrite).
**Owner:** Clod. **Size:** one paragraph.

---

## PARKED

### F-7 — `opPlusPlus` carries the poisoned-iterator guard twice
**Where:** `Instruct.rtn:887` and `:923`.
**What:** the 2026-08-05 run-time-flag census intended to MOVE `if result.fLAG return 0;` below the
jitting gate. It was **copied**, not moved. `:887` dominates, so `:923` is unreachable, and the
emit-time condition the note calls the danger is still constructable.
**Evidence:** structural, checkable by pointer — nothing between the two lines mutates `fLAG`.
⚠ Whether a poisoned node actually reaches `opPlusPlus` during an emit walk is **causal and unrun**.
**Status:** `parked Tony` — carried in Clay's step-2 brief as a logged candidate, explicitly not to
be chased. **Owner:** Tony.

### F-8 — `aCTionDebuG`'s three stacked directives
**Where:** `groupDirectives`, the three `aCTionDebuG` entries.
**What:** all three are disarmed, so harmless today. Arming **two** would silently fire only the
first — bear-trap #30. Nobody has ever found this out because nobody has armed two.
**Done when:** annotated at the site, or collapsed to one. **Owner:** unassigned. **Size:** comment.

---

## CLOSED — kept one cycle for the trail

### F-1 — ✅ CLOSED 2026-08-16 — and the fix was NOT where the row said
**The row blamed `auditRStuff`'s guard. The guard was innocent.** `aCTionParens` only cleared its
node when an ExpressioN was present, so an empty `()` returned the Parens node untouched — which
after the labelled-literals change carries `leftParen`/`rightParen` as attributes where it
previously carried nothing. What reached `audit()` was therefore the `rightParen` literal
(`data=13`, isSTRING) instead of the `InvokeArg` node the guard tests for.
**Fix:** `ruleActions.rtn`, `aCTionParens` clears unconditionally, mirroring `aCTionBraced` which
always did. Two lines. `auditRStuff` unchanged.
**Verified:** `AUDITPROBE arg= InvokeArg argdata= 0` — the shape the guard expects — and the
all-registries line returns. Fleet 38 → 39 green.
**And it answered the question that opened it:** the rStuff populations were unmeasured, not
moved — and once measurable, **missing terms went 12 → 0**. Tony's `aCTionDefinE` change closed
that population by construction. Re-pinned with the twelve named in `pop.sh`.
⚠ **Blast radius accepted knowingly:** every `()` in the language goes through `aCTionParens`, so
this touches every no-argument command call. Fleet unmoved apart from the intended row.
⚠ **The class survives the instance and is worth keeping:** a **tag comparison used as a sentinel**
is fragile against grammar edits. This one happened to be repairable upstream, so the guard stays.
The next one may not be.

- **`jitMethod` name collision** — the op-node slot would have collided with `rStuff.jitMethod`
  (compiled body of a field's method). **Closed by Clay's ruling: the slot is `jitEmitter`.**
- **Unary ops unreachable from an `operateMethod`-adjacent slot** — every unary op installs via
  `ruleMethod=` into `method`/`isMethod`. **Closed by Clay's ruling: the slot sits beside the
  BINDING, both families carry it.**
- **`Aside/` and `BackupIncant/` generating permanent untracked noise** — CLAUDE.md claimed they
  were gitignored and they were not. **Closed `b1482ff`, `2364b05`; the claim is now true.**
